#!/usr/bin/env python3
"""Generate one Lean file per corpus record under generated/ (gitignored), each proving equivalence
between ALL pairs of that record's variant SQLs via `sql_equiv`, then run every file and report:
  - ELABORATES : the file's queries all form well-typed TypedRelations (no parse/elab error)
  - PROVEN     : every pair theorem in the file closed (lean exit 0)

Usage:
    python3 provefiles.py                 # all non-window records
    python3 provefiles.py --limit 20      # first 20
    python3 provefiles.py --jobs 6 --timeout 90
    python3 provefiles.py --gen-only      # just write the files, don't run
"""
import json, re, os, sys, subprocess, itertools
from concurrent.futures import ThreadPoolExecutor, as_completed

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
# Repo-root, OUTSIDE the `Examples.+` lake glob — so `lake build` never tries to compile these
# experimental (often-failing) files. Run them individually via `lake env lean`.
GEN  = os.path.join(ROOT, ".gen")
recs = [json.loads(l) for l in open(os.path.join(HERE, "crossskill_equivalent_sql.jsonl")) if l.strip()]

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
def is_window(q):
    u = q.upper().replace(' ','')
    return 'OVER(' in u or 'ROW_NUMBER' in u or 'RANK()' in u or 'WITHRECURSIVE' in u

# ---- args ----
args = sys.argv[1:]
def popval(flag, default):
    if flag in args:
        i = args.index(flag); v = args[i+1]; del args[i:i+2]; return v
    return default
jobs    = int(popval('--jobs', '6'))
timeout = int(popval('--timeout', '90'))
limit   = int(popval('--limit', str(10**9)))
gen_only = '--gen-only' in args
split   = '--split' in args   # one file PER PAIR: reliable exit-code count, no line-attribution guessing

# ---- select records (non-window first variant, has ddl) ----
selected = []
for i, r in enumerate(recs):
    if is_window(r['equivalent_sqls'][0]['sql']): continue
    tables = parse_ddl(r.get('ddl',''))
    if not tables: continue
    selected.append((i, r, tables))
    if len(selected) >= limit: break

os.makedirs(GEN, exist_ok=True)
# clear stale
for f in os.listdir(GEN):
    if f.startswith('R') and f.endswith('.lean'): os.remove(os.path.join(GEN, f))

files = []
for i, r, tables in selected:
    seen = {}
    for name, cols in tables:
        if name not in seen: seen[name] = cols
    variants = [e['sql'] for e in r['equivalent_sqls']]
    # Keep only tables the queries actually reference — a record's DDL can carry hundreds of unused
    # tables (e.g. quarterly BLS tables), and passing them all makes `sql%` elaboration crawl.
    allsql = ' '.join(variants).lower()
    refd = {n: c for n, c in seen.items() if re.search(r'\b'+re.escape(n.lower())+r'\b', allsql)}
    if not refd: refd = seen
    schemas = ', '.join(f'{name}_schema' for name in refd)
    L = ['import LeanDatabase.Parser', 'import LeanDatabase.SQLSyntax',
         'open LeanDatabase Lean', 'set_option maxHeartbeats 1000000', 'set_option maxRecDepth 8000',
         f'namespace R{i}']
    for name, cols in refd.items():
        L.append(f'CREATE TABLE {name} ({", ".join(f"«{c}» {t}" for c,t in cols)})')
    pairs = [(a, b) for a, b in itertools.combinations(range(len(variants)), 2)
             if variants[a] != variants[b]]
    if split:
        # one file per pair — the file's exit code IS that pair's verdict (no attribution guessing)
        for a, b in pairs:
            body = L + [f'theorem eq_{a}_{b} : sql%([{schemas}]) "{esc(variants[a])}" '
                        f'= sql%([{schemas}]) "{esc(variants[b])}" := by sql_equiv', f'end R{i}']
            path = os.path.join(GEN, f'R{i}_eq_{a}_{b}.lean')
            open(path, 'w').write('\n'.join(body) + '\n')
            files.append((i, path, [(f'eq_{a}_{b}', 0)], r.get('instance_id','?')))
    else:
        thm_lines = []
        for a, b in pairs:
            thm_lines.append((f'eq_{a}_{b}', len(L) + 1))
            L.append(f'theorem eq_{a}_{b} : sql%([{schemas}]) "{esc(variants[a])}" '
                     f'= sql%([{schemas}]) "{esc(variants[b])}" := by sql_equiv')
        L.append(f'end R{i}')
        path = os.path.join(GEN, f'R{i}.lean')
        open(path, 'w').write('\n'.join(L) + '\n')
        files.append((i, path, thm_lines, r.get('instance_id','?')))

total_pairs = sum(len(f[2]) for f in files)
print(f"generated {len(files)} files in {GEN} (total {total_pairs} pair-theorems)")
if gen_only: sys.exit(0)

ELAB_MARK = ('Failed to parse','unexpected token','Type mismatch','Invalid field',
             'does not contain','failed to synthesize','unknown identifier')

# ---- run each file; classify the file AND each pair-theorem ----
def run(item):
    i, path, thm_lines, iid = item
    npairs = len(thm_lines)
    try:
        p = subprocess.run(['lake','env','lean',path], cwd=ROOT, capture_output=True,
                           text=True, timeout=timeout)
        out = (p.stdout or '') + (p.stderr or '')
        if p.returncode == 0:
            # exit 0 = no errors at all = every theorem in the file closed (exact truth).
            proven_pairs = len(thm_lines)
            file_status = 'PROVEN'
        else:
            # some theorem failed; attribute by line as a best-effort per-pair count (approximate for
            # multi-theorem files, exact for --split where each file is one pair).
            err_lines = [int(m.group(1)) for m in re.finditer(r'\.lean:(\d+):\d+: error:', out)]
            bounds = [ln for _, ln in thm_lines] + [10**9]
            proven_pairs = sum(1 for idx, (nm, ln) in enumerate(thm_lines)
                               if err_lines and not any(ln <= e < bounds[idx+1] for e in err_lines)
                               and ln > 0)
            is_elab = any(m in out for m in ELAB_MARK)
            file_status = 'ELAB_FAIL' if is_elab else 'PROOF_FAIL'
        return (i, iid, npairs, proven_pairs, file_status)
    except subprocess.TimeoutExpired:
        return (i, iid, npairs, 0, 'TIMEOUT')

print(f"running {len(files)} files (jobs={jobs}, timeout={timeout}s)...", file=sys.stderr)
results = []
with ThreadPoolExecutor(max_workers=jobs) as ex:
    futs = {ex.submit(run, f): f for f in files}
    done = 0
    for fut in as_completed(futs):
        results.append(fut.result()); done += 1
        if done % 20 == 0: print(f"  ...{done}/{len(files)}", file=sys.stderr)

# ---- report ----
from collections import Counter
by = Counter(r[4] for r in results)
proven_files = by['PROVEN']
elaborated   = proven_files + by['PROOF_FAIL'] + by['TIMEOUT']
proven_pairs = sum(r[3] for r in results)
print(f"\n{'='*64}")
print(f"FILES:          {len(results)}   (one per record)")
print(f"ELABORATE:      {elaborated}/{len(results)}  (file has no parse/elab error)")
print(f"FULLY PROVEN:   {proven_files}/{len(results)}  (every pair-theorem in the file closed)")
print(f"PAIRS PROVEN:   {proven_pairs}/{total_pairs}  (individual equivalence theorems closed)")
print(f"file breakdown: {dict(by)}")
with open(os.path.join(GEN, '_results.tsv'), 'w') as f:
    f.write("record\tinstance\tpairs\tproven_pairs\tstatus\n")
    for i, iid, np_, pp, st in sorted(results):
        f.write(f"R{i}\t{iid}\t{np_}\t{pp}\t{st}\n")
print(f"per-file results -> {os.path.join(GEN,'_results.tsv')}")
