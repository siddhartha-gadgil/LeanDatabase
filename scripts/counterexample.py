#!/usr/bin/env python3
"""Counterexample finder + validator for a claimed-NON-equivalent SQL pair.

Given a Bench problem `.lean` file, extract its `CREATE TABLE` schema and the two
`sql%(...) "<SQL>"` queries, ask the LLM for a MINIMAL counterexample (rows only, no prose),
then run BOTH queries on that data in sqlite3 and compare result *sets* (the repo's set
semantics). If the sets differ, the counterexample is VALID → the pair is genuinely
non-equivalent as stated. Usage: counterexample.py <problem.lean>
"""
import json, os, re, sqlite3, subprocess, sys, urllib.request

TYPE_MAP = {"INT": "INTEGER", "STRING": "TEXT", "BOOL": "INTEGER", "FLOAT": "REAL",
            "TIMESTAMP": "TEXT", "DATE": "TEXT"}

def parse_file(path):
    text = open(path).read()
    # CREATE TABLE NAME («col» TYPE, «col» TYPE, ...)
    tables = {}
    for m in re.finditer(r'CREATE TABLE\s+(\w+)\s*\((.*?)\)', text):
        name, cols = m.group(1), m.group(2)
        collist = []
        for cm in re.finditer(r'«(\w+)»\s+(\w+)', cols):
            collist.append((cm.group(1), cm.group(2).upper()))
        tables[name] = collist
    # the two SQL query strings, in order
    queries = re.findall(r'sql%\([^)]*\)\s*"((?:[^"\\]|\\.)*)"', text)
    return tables, queries

PROMPT = (
    "You are given a database schema and TWO SQL queries claimed to be NON-equivalent.\n"
    "Give the SMALLEST counterexample: concrete rows for each table such that the two "
    "queries return DIFFERENT result SETS (set semantics: order and duplicates ignored).\n"
    "IMPORTANT: base tables are SETS — every row within a table must be DISTINCT; two identical "
    "rows collapse to one. So to make a COUNT/GROUP BY differ, rows sharing a group key must still "
    "differ in at least one OTHER column.\n"
    "Output ONLY a JSON object mapping each table name to a list of rows; each row is a list "
    "of column values in schema order (use null for NULL, true/false for BOOL, numbers for INT, "
    "strings for STRING). Include only tables the queries read. NO text, NO markdown, NO fences.")

def ask_llm(schema_txt, q1, q2, feedback=""):
    content = f"{PROMPT}\n\nSCHEMA:\n{schema_txt}\n\nQUERY 1:\n{q1}\n\nQUERY 2:\n{q2}\n{feedback}"
    body = json.dumps({"model": "gpt-5.6",
                       "messages": [{"role": "user", "content": content}],
                       "reasoning_effort": "high", "max_completion_tokens": 8000}).encode()
    req = urllib.request.Request("https://api.openai.com/v1/chat/completions", data=body,
        headers={"Authorization": f"Bearer {os.environ['OPENAI_API_KEY']}", "Content-Type": "application/json"})
    resp = json.load(urllib.request.urlopen(req))
    return resp["choices"][0]["message"]["content"]

def build_and_run(tables, rows, query):
    con = sqlite3.connect(":memory:")
    for name, cols in tables.items():
        coldefs = ", ".join(f'"{c}" {TYPE_MAP.get(t, "TEXT")}' for c, t in cols)
        con.execute(f'CREATE TABLE {name} ({coldefs})')
        # Base tables are Finsets: dedup rows so identical rows count once (repo set semantics).
        seen = set()
        for r in rows.get(name, []):
            vals = tuple(1 if v is True else 0 if v is False else v for v in r)
            if vals in seen:
                continue
            seen.add(vals)
            con.execute(f'INSERT INTO {name} VALUES ({",".join("?" * len(vals))})', vals)
    cur = con.execute(query)
    # compare as a SET of value-tuples (ignore column labels + duplicates + order)
    return frozenset(tuple(row) for row in cur.fetchall())

def main():
    path = sys.argv[1]
    tables, queries = parse_file(path)
    if len(queries) < 2:
        print("could not extract two queries"); return 2
    q1, q2 = queries[0], queries[1]
    schema_txt = "\n".join(f'{n}(' + ", ".join(f'{c} {t}' for c, t in cs) + ')' for n, cs in tables.items())
    print(f"Q1: {q1}\nQ2: {q2}\n")
    feedback = ""
    for attempt in range(1, 4):
        raw = re.sub(r'^```\w*|```$', '', ask_llm(schema_txt, q1, q2, feedback).strip()).strip()
        print(f"[attempt {attempt}] LLM counterexample (rows only):\n{raw}")
        try:
            rows = json.loads(raw)
            r1, r2 = build_and_run(tables, rows, q1), build_and_run(tables, rows, q2)
        except Exception as e:
            print(f"  → could not use it ({e}); retrying"); feedback = f"\nYour previous reply failed: {e}. Reply with ONLY valid JSON."; continue
        print(f"  Q1 result set (deduped, set semantics): {sorted(r1)}")
        print(f"  Q2 result set (deduped, set semantics): {sorted(r2)}")
        if r1 != r2:
            print("\n✅ VALID COUNTEREXAMPLE — the queries differ on this data → NON-equivalent as stated.")
            return 0
        feedback = ("\nThat counterexample is INVALID: after collapsing identical base-table rows (set "
                    "semantics) the two queries returned the SAME set. Give rows that differ in a "
                    "non-key column so they stay distinct, or a genuinely different counterexample.")
        print("  → INVALID (queries agree after dedup); asking again\n")
    print("\n❌ No valid counterexample found — the pair may actually be equivalent (e.g. it needs a "
          "constraint that also happens to hold on all small instances).")
    return 1

if __name__ == "__main__":
    sys.exit(main())
