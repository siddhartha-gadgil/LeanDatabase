#!/usr/bin/env python3
"""Dump the FULL Lean output for every elaboration failure into elab_failures.json.

Unlike status.json (which keeps only the one-line category message), this captures the complete,
uncut compiler error block for each failing (id, variant) so failures can be worked on offline
without re-running Lean. Reads the failed list from status.json; emits one combined Lean file (only
the failing records), runs it once, and slices each job's full error block by line range.

Usage: python3 dump_failures.py
"""
import json, re, os, sys, subprocess
from transpile import to_postgres

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
recs = {r['instance_id']: r for r in
        (json.loads(l) for l in open(os.path.join(HERE, "crossskill_equivalent_sql.jsonl")) if l.strip())}

def maptype(t):
    t = t.upper()
    if any(t.startswith(x) for x in ("VARCHAR","CHAR","TEXT","STRING")): return "STRING"
    if any(t.startswith(x) for x in ("FLOAT","DOUBLE","REAL","DECIMAL","NUMERIC")): return "FLOAT"
    if t.startswith("BOOL"): return "BOOL"
    if any(t.startswith(x) for x in ("DATE","TIMESTAMP","DATETIME","TIME")): return "STRING"
    if any(t.startswith(x) for x in ("INT","NUMBER","BIGINT","SMALLINT","TINYINT")): return "INT"
    return "STRING"

def split_top(s):
    parts, d, cur = [], 0, ''
    for ch in s:
        if ch == '(': d += 1
        elif ch == ')': d -= 1
        if ch == ',' and d == 0: parts.append(cur); cur = ''
        else: cur += ch
    if cur.strip(): parts.append(cur)
    return parts

def parse_ddl(ddl):
    out = []
    for m in re.finditer(r'create\s+(?:or\s+replace\s+)?(?:transient\s+|temporary\s+|temp\s+)?table\s+([^\s(]+)\s*\(', ddl, re.I):
        name = m.group(1).replace('"','').split('.')[-1]
        i, depth = m.end()-1, 0
        while i < len(ddl):
            if ddl[i] == '(': depth += 1
            elif ddl[i] == ')':
                depth -= 1
                if depth == 0: break
            i += 1
        cols = []
        for line in split_top(ddl[m.end():i]):
            line = line.strip()
            if not line or re.match(r'(PRIMARY|FOREIGN|UNIQUE|CONSTRAINT|CHECK)\b', line, re.I): continue
            mm = re.match(r'"?([A-Za-z_][A-Za-z0-9_]*)"?\s+(\w+)', line)
            if mm: cols.append((mm.group(1), maptype(mm.group(2))))
        if cols: out.append((name, cols))
    return out

def esc(q): return q.replace('\\','\\\\').replace('"','\\"').replace('\n','\\n')
def pg(s):
    r = to_postgres(s); return (r[0] if isinstance(r, tuple) else r) or ''

# Default: re-check the records status.json currently lists as failed. `all`: isolate-check EVERY
# record's variant[0] (authoritative — the combined-file census mis-attributes when one record hits
# maxErrors). Each record runs in its own Lean file so its output is unambiguously its own.
ALL = 'all' in sys.argv
if ALL:
    failed = [{'id': r['instance_id'], 'variant': 0, 'category': '?'} for r in recs.values()]
else:
    st = json.load(open(os.path.join(HERE, "status.json")))
    failed = st["failed"]
gendir = os.path.join(ROOT, '.gen'); os.makedirs(gendir, exist_ok=True)

def run_one(job):
    """One isolated Lean file per failing record, so all output is unambiguously its own."""
    idx, e = job
    r = recs.get(e['id'])
    if not r: return None
    v = e['variant']
    q = pg(r['equivalent_sqls'][v]['sql'])
    tables = parse_ddl(r.get('ddl', ''))
    seen = {}
    for name, cols in tables:
        if name not in seen: seen[name] = cols
    ql = q.lower()
    seen = {n: c for n, c in seen.items() if re.search(r'\b'+re.escape(n.lower())+r'\b', ql)} or seen
    hdr = ['import LeanDatabase.Parser', 'import LeanDatabase.SQLSyntax',
           'open LeanDatabase Lean', 'set_option maxHeartbeats 1000000',
           'set_option maxRecDepth 8000', 'set_option maxErrors 100000']
    for name, cols in seen.items():
        hdr.append(f'CREATE TABLE {name} ({", ".join(f"«{c}» {t}" for c,t in cols)})')
    schemas = ', '.join(f'{name}_schema' for name in seen)
    hdr.append(f'def probed := sql%([{schemas}]) "{esc(q)}"')
    fpath = os.path.join(gendir, f'_fail_{idx}.lean')
    open(fpath, 'w').write('\n'.join(hdr) + '\n')
    proc = subprocess.run(['lake', 'env', 'lean', fpath], cwd=ROOT, capture_output=True, text=True)
    output = ((proc.stdout or '') + (proc.stderr or '')).strip()
    has_err = ' error' in ('\n' + output) or output.startswith('error')
    return {'id': e['id'], 'variant': v, 'category': e['category'],
            'converted_sql': q, 'lean_output': output or '(no output)',
            'ok': not has_err}

from concurrent.futures import ThreadPoolExecutor
print(f"running lean on {len(failed)} records (isolated, parallel)...", file=sys.stderr)
with ThreadPoolExecutor(max_workers=6) as ex:
    res = [r for r in ex.map(run_one, list(enumerate(failed))) if r]
out = [r for r in res if not r.get('ok')]        # keep only genuine failures in the JSON
n_ok = sum(1 for r in res if r.get('ok'))
json.dump({'count': len(out),
           'checked': len(res), 'elaborates': (n_ok if ALL else None),
           'note': 'Full Lean output per elaboration failure (isolated per-record run — authoritative, '
                   'unlike the combined-file census which mis-attributes on maxErrors). converted_sql = '
                   'the PostgreSQL sqlglot output the parser receives; lean_output = the complete, uncut '
                   'compiler message(s). Regenerate: dump_failures.py [all].',
           'failures': out},
          open(os.path.join(HERE, 'elab_failures.json'), 'w'), indent=2)
if ALL:
    print(f"ISOLATED CENSUS: {n_ok}/{len(res)} elaborate, {len(out)} fail")
print(f"wrote elab_failures.json: {len(out)} genuine failures")
