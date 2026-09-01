#!/usr/bin/env python3
"""Keep a dataset in sync with the upstream VeriEQL benchmark — including the records it chokes on.

The original conversion silently dropped every record `sqlglot` could not parse, which is how three
Literature benchmarks went missing without a trace. They are not exotic queries; they are *malformed
SQL* that VeriEQL's own parser accepts and standard parsers do not:

* `FROM (R UNION ALL S) X` — a set operation used directly as a FROM item (benchmarks 30, 32).
  Rewritten to the standard `FROM (SELECT * FROM R UNION ALL SELECT * FROM S) X`.
* `FROM A AS F, (…) AS X ON …` — a comma join carrying an `ON` clause (benchmark 48). `ON` belongs to
  a `JOIN`, and that is plainly what is meant, so the comma becomes `JOIN`.

Both rewrites are pure re-spellings — the same query in standard syntax — so the record keeps its
upstream index and carries the reason in a `normalized` field. That is deliberately *not* the `<n>_fix`
convention, which is reserved for a record whose **meaning** had to be repaired (Literature 11 names a
column its schema does not have); ids that match VeriEQL's indices are what make the comparison
against their published verdicts readable.

    python3 Bench/sync_verieql.py Literature <VeriEQL>/benchmarks/literature/literature.jsonlines

Reports what is missing, adds it, and leaves existing records untouched.
"""
import json
import re
import sys
from pathlib import Path

import sqlglot

ROOT = Path(__file__).resolve().parent

TYPES = {"INT": "INT", "INTEGER": "INT", "BIGINT": "INT", "SMALLINT": "INT", "TINYINT": "INT",
         "VARCHAR": "STRING", "TEXT": "STRING", "CHAR": "STRING", "STRING": "STRING",
         "DATE": "INT", "TIMESTAMP": "INT", "TIME": "INT", "DATETIME": "INT",
         "FLOAT": "FLOAT", "DECIMAL": "FLOAT", "DOUBLE": "FLOAT", "REAL": "FLOAT",
         "NUMERIC": "FLOAT", "BOOL": "BOOL", "BOOLEAN": "BOOL"}

SETOP_IN_FROM = re.compile(r"\(\s*(\w+)\s+(UNION ALL|UNION|INTERSECT|EXCEPT)\s+(\w+)\s*\)", re.I)


def repair(sql: str) -> tuple[str, str | None]:
    """→ (sql, reason-if-repaired). Both rules turn non-standard SQL into its standard equivalent."""
    reasons = []

    def setop(m: re.Match) -> str:
        return f"(SELECT * FROM {m.group(1)} {m.group(2).upper()} SELECT * FROM {m.group(3)})"

    fixed = SETOP_IN_FROM.sub(setop, sql)
    if fixed != sql:
        reasons.append("a set operation was used directly as a FROM item")
        sql = fixed

    # A comma join cannot carry `ON`; that is an inner join written with the wrong separator. The
    # comma to replace is the one separating the FROM items — at paren depth 0, before the `ON` —
    # not whichever comma happens to come last (those sit inside the subquery's own SELECT list).
    if re.search(r"\bON\b", sql, re.I) and not re.search(r"\bJOIN\b", sql, re.I):
        m_from, m_on = re.search(r"\bFROM\b", sql, re.I), re.search(r"\bON\b", sql, re.I)
        if m_from and m_on and m_from.end() < m_on.start():
            depth, cut = 0, None
            for i in range(m_from.end(), m_on.start()):
                if sql[i] == "(":
                    depth += 1
                elif sql[i] == ")":
                    depth -= 1
                elif sql[i] == "," and depth == 0:
                    cut = i
            if cut is not None:
                sql = sql[:cut] + " JOIN" + sql[cut + 1:]
                reasons.append("a comma join carried an `ON` clause")
    return sql, ("; ".join(reasons) if reasons else None)


def transpile(sql: str) -> str | None:
    for read in ("mysql", None):
        try:
            return sqlglot.transpile(sql, read=read, write="postgres")[0]
        except Exception:
            continue
    return None


def main(dataset: str, source: str) -> None:
    pairs_path, corpus_path = ROOT / dataset / "pairs.json", ROOT / dataset / "corpus_pg.json"
    pairs = json.loads(pairs_path.read_text())
    corpus = json.loads(corpus_path.read_text())
    have = {r["id"].split(":")[0].replace("_fix", "") for r in pairs}

    added, failed = [], []
    for line in open(source):
        rec = json.loads(line)
        idx = str(rec["index"])
        if idx in have or not rec.get("schema"):
            continue
        queries, reasons = [], []
        for q in rec["pair"]:
            fixed, reason = repair(q)
            out = transpile(fixed)
            if out is None:
                queries = []
                break
            queries.append(out)
            if reason:
                reasons.append(reason)
        if not queries:
            failed.append(idx)
            continue

        schemas = [{"name": t, "columns": [{"name": c, "type": TYPES.get(str(ty).upper(), "STRING")}
                                           for c, ty in cols.items()]}
                   for t, cols in rec["schema"].items()]
        rid = idx
        pair = {"id": f"{rid}:eq", "schemas": schemas,
                "first": queries[0], "second": queries[1], "dataEq": True}
        if reasons:
            pair["normalized"] = "; ".join(dict.fromkeys(reasons))
        pairs.append(pair)
        for i, q in enumerate(queries):
            corpus.append({"id": f"{rid}:q{i}", "schemas": schemas, "query": q})
        added.append(rid)

    key = lambda r: (int(re.sub(r"\D", "", r["id"].split(":")[0]) or 0), r["id"])
    pairs_path.write_text(json.dumps(sorted(pairs, key=key), indent=1) + "\n")
    corpus_path.write_text(json.dumps(sorted(corpus, key=key), indent=1) + "\n")
    print(f"{dataset}: added {len(added)} missing record(s): {added}")
    if failed:
        print(f"   still unparseable upstream: {failed}")


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
