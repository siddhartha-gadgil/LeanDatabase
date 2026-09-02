#!/usr/bin/env python3
"""Certify our disproofs against a REAL SQL engine (sqlglot's bag-semantics executor).

For each Bench/<ds>/CounterExample/<n>.lean: take the counterexample rows + the pair's two queries
(from pairs.json), run BOTH on that database via sqlglot.executor, and compare results **as bags**
(multisets). Base-table rows are dedup'd first, matching the set-database our Lean disproof actually
used. If the two bags are EQUAL, the disproof is SPURIOUS — the queries agree in real SQL, so our
Lean set-model computed a difference that isn't there (an operator bug).

Usage: validate_disproofs.py [Literature|Calcite|all]
"""
import json, re, sys, glob, os, sqlite3
from collections import Counter
from sqlglot import executor, parse_one, exp, transpile

TMAP = {'INT': int, 'INTEGER': int, 'BIGINT': int, 'STRING': str, 'TEXT': str, 'VARCHAR': str,
        'BOOL': bool, 'BOOLEAN': bool, 'FLOAT': float, 'DOUBLE': float, 'REAL': float}
DIALECTS = [None, 'postgres', 'mysql', 'sqlite']

def coerce(v, ty):
    if v is None: return None
    base = TMAP.get(ty.upper().split('(')[0], None)
    try:
        if base is bool: return bool(v)
        if base is int: return int(v)
        if base is float: return float(v)
        if base is str: return str(v)
    except (TypeError, ValueError):
        return v
    return v

def build_tables(schemas, db):
    tables, schema = {}, {}
    for i, s in enumerate(schemas):
        cols = [c['name'] for c in s['columns']]
        types = [c['type'] for c in s['columns']]
        # Explicit schema so EMPTY tables still have known columns (sqlglot can't infer from no rows).
        schema[s['name']] = {c: t for c, t in zip(cols, types)}
        seen, rows = set(), []
        for r in (db[i] if i < len(db) else []):
            # Match the DB our Lean disproof actually used: the overnight checker padded short rows
            # with NULL and truncated long ones. Reproduce that exactly, or the comparison is unfaithful.
            r = (list(r) + [None] * len(cols))[:len(cols)]
            vals = tuple(coerce(v, t) for v, t in zip(r, types))
            if vals in seen:                   # base tables are sets (our model dedups)
                continue
            seen.add(vals); rows.append(dict(zip(cols, vals)))
        tables[s['name']] = rows
    return tables, schema

def run(tables, schema, q):
    """Execute q; return a Counter of value-tuples (bag). Raises on unsupported SQL.
    ORDER BY is irrelevant to a bag comparison, so strip it (it also carries the unsupported
    NULLS FIRST/LAST syntax)."""
    ast = parse_one(q)
    for o in list(ast.find_all(exp.Order)):
        o.pop()
    last = None
    for d in DIALECTS:
        try:
            res = executor.execute(ast, schema=schema, tables=tables, dialect=d) if d \
                  else executor.execute(ast, schema=schema, tables=tables)
            return Counter(tuple(row) for row in res.rows)
        except Exception as e:
            last = e
    # Fallback: sqlglot's own executor is limited (NATURAL JOIN, string HAVING, UNION ALL of VALUES…);
    # transpile to sqlite and run in the real sqlite3 engine, which handles them.
    try:
        return run_sqlite(tables, schema, ast)
    except Exception:
        raise last

def fix_values_alias(ast):
    """Rewrite `(VALUES …) AS t(c1,c2,…)` into `(SELECT … UNION ALL …) AS t` — sqlite rejects the
    column-list table alias, so express it as a SELECT of the tuples with the alias names."""
    for v in list(ast.find_all(exp.Values)):
        al = v.args.get('alias')
        if al and al.columns:
            cols = [c.name for c in al.columns]
            sels = [exp.select(*[e.as_(cols[i]) for i, e in enumerate(tup.expressions)])
                    for tup in v.expressions]
            u = sels[0]
            for s in sels[1:]:
                u = u.union(s, distinct=False)
            v.replace(exp.Subquery(this=u, alias=exp.TableAlias(this=al.this)))
    return ast

def run_sqlite(tables, schema, ast):
    ast = fix_values_alias(ast.copy())
    con = sqlite3.connect(":memory:")
    for name, cols in schema.items():
        coldefs = ", ".join('"' + c + '"' for c in cols)
        con.execute('CREATE TABLE "' + name + '" (' + coldefs + ')')
        ph = ",".join("?" * len(cols))
        for row in tables.get(name, []):
            vals = [1 if row[c] is True else 0 if row[c] is False else row[c] for c in cols]
            con.execute('INSERT INTO "' + name + '" VALUES (' + ph + ')', vals)
    sql = transpile(ast.sql(), write="sqlite")[0]
    return Counter(tuple(r) for r in con.execute(sql).fetchall())

def is_real_disproof(schemas, q1, q2, cx_json):
    """Certify a counterexample against a REAL SQL engine (bag semantics). Returns True if the two
    queries genuinely DIFFER as bags on the counterexample data (a real disproof), False if they are
    equal (SPURIOUS — our set-model bug, must be rejected), or None if sqlglot cannot execute it (so
    the caller should not gate on an inconclusive result). `cx_json` is the JSON row-data string."""
    try:
        db = json.loads(cx_json)
        tables, schema = build_tables(schemas, db)
        return run(tables, schema, q1) != run(tables, schema, q2)
    except Exception:
        return None

def validate(ds):
    pairs = {x['id'].split(':')[0]: x for x in json.load(open(f'Bench/{ds}/pairs.json'))}
    real = false = err = 0; falses = []; errs = []
    for f in sorted(glob.glob(f'Bench/{ds}/CounterExample/*.lean')):
        n = os.path.basename(f)[:-5]
        m = re.search(r'plausible_sql "(.*?)"\s*\n', open(f).read(), re.DOTALL)
        if not m or n not in pairs: continue
        cx = m.group(1).replace('\\"', '"').replace('\\\\', '\\'); p = pairs[n]
        try:
            db = json.loads(cx); tables, schema = build_tables(p['schemas'], db)
            r1, r2 = run(tables, schema, p['first']), run(tables, schema, p['second'])
            if r1 != r2: real += 1
            else: false += 1; falses.append(n)
        except Exception as e:
            err += 1; errs.append((n, type(e).__name__ + ': ' + str(e)[:60]))
    print(f"\n=== {ds}: {real} REAL-SQL-certified, {false} SPURIOUS (operator bug), {err} unsupported ===")
    if falses: print("  SPURIOUS (actually equivalent → our model has a bug here):", falses)
    if errs: print("  unsupported by sqlglot executor:", [n for n, _ in errs])
    return real, false, errs

if __name__ == "__main__":
    arg = sys.argv[1] if len(sys.argv) > 1 else "all"
    dss = ["Literature", "Calcite"] if arg == "all" else [arg]
    tot_real = tot_false = 0
    for ds in dss:
        r, fa, _ = validate(ds); tot_real += r; tot_false += fa
    print(f"\nTOTAL: {tot_real} real-SQL-certified disproofs, {tot_false} spurious")
