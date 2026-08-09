#!/usr/bin/env python3
"""Fast parse-only coverage: emit a run_cmd that runParserCategory's each non-window first-query.
No schema elaboration -> fast. Prints FAIL:<idx>:<err> per failure, then a count."""
import json, os
HERE = os.path.dirname(os.path.abspath(__file__))
recs = [json.loads(l) for l in open(os.path.join(HERE,"crossskill_equivalent_sql.jsonl")) if l.strip()]
qs = []
for i, r in enumerate(recs):
    q = r['equivalent_sqls'][0]['sql']
    u = q.upper().replace(' ','')
    if 'OVER(' in u or 'ROW_NUMBER' in u or 'RANK()' in u or 'WITHRECURSIVE' in u: continue
    qs.append((i, q))
def esc(q): return q.replace('\\','\\\\').replace('"','\\"').replace('\n','\\n')
print('import LeanDatabase.Parser'); print('import LeanDatabase.SQLSyntax')
print('open LeanDatabase Lean')
print('run_cmd do')
print('  let env ← getEnv')
print('  let mut fails := 0')
print(f'  let qs : List (Nat × String) := [{", ".join(f"({i}, \"{esc(q)}\")" for i,q in qs)}]')
print('  for (i, q) in qs do')
print('    let nq := LeanDatabase.normalizeSqlLiterals q')
print('    match Lean.Parser.runParserCategory env `sql_query nq with')
print('    | .ok _ => pure ()')
print('    | .error e =>')
print('      fails := fails + 1')
print('      let parts := e.splitOn ":"')
print('      let ln := (parts.getD 1 "1").trim.toNat!')
print('      let c := (parts.getD 2 "0").trim.toNat!')
print('      let line := (nq.splitOn "\\n").getD (ln - 1) ""')
print('      let snip := (line.toList.drop (max 0 (c - 30))).take 70 |>.asString')
print('      IO.println s!"FAIL:{i}:{e}::SNIP::{snip}"')
print(f'  IO.println s!"PARSED:{{{len(qs)} - fails}}/{len(qs)}"')
