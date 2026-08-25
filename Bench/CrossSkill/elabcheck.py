#!/usr/bin/env python3
"""End-to-end elaboration checker for the crossskill corpus.

For each record it shows the SQL -> normalized conversion and whether the query
*elaborates* into a TypedRelation (the real "is the Lean correct" bar), reporting
OK or COMPILE ERROR with the exact Lean message.

Usage:
    python3 elabcheck.py                # all non-window records, variant[0]
    python3 elabcheck.py 40             # first 40 records
    python3 elabcheck.py --id sf_bq030  # a single record by instance_id
    python3 elabcheck.py --all-variants # check every variant, not just [0]
    python3 elabcheck.py -q             # summary only (no per-record conversion dump)

Exit code is the number of COMPILE ERRORs (0 = all elaborate).
"""
import json, re, os, sys, subprocess

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
# Canonical corpus is PostgreSQL (transpiled from Snowflake by to_postgres_corpus.py); fall back
# to the raw Snowflake corpus if the Postgres one has not been generated yet.
_PG = os.path.join(HERE, "crossskill_equivalent_postgres.jsonl")
_CORPUS = _PG if os.path.exists(_PG) else os.path.join(HERE, "crossskill_equivalent_sql.jsonl")
recs = [json.loads(l) for l in open(_CORPUS) if l.strip()]

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
    # Only RECURSIVE CTE / LATERAL / FLATTEN are still unsupported; plain window functions and
    # non-recursive CTEs now elaborate, so check them too (a failure is a real one to fix).
    u = q.upper()
    return 'WITH RECURSIVE' in u or 'LATERAL' in u or 'FLATTEN' in u

# ---- argument parsing ----
args = sys.argv[1:]
quiet = '-q' in args;                 args = [a for a in args if a != '-q']
all_variants = '--all-variants' in args; args = [a for a in args if a != '--all-variants']
only_id = None
if '--id' in args:
    only_id = args[args.index('--id')+1]
    args = [a for a in args if a not in ('--id', only_id)]
log_path = None
if '--log' in args:
    log_path = args[args.index('--log')+1]
    args = [a for a in args if a not in ('--log', log_path)]
postgres = '--postgres' in args; args = [a for a in args if a != '--postgres']
to_postgres = None
if postgres:
    from transpile import to_postgres      # transpile Snowflake → PostgreSQL before elaborating
N = int(args[0]) if args else 10**9

# ---- select (record-index, variant-index, sql) triples ----
jobs = []
skipped = []   # (iid, k, sql, construct) — not attempted (parser can't yet handle the construct)
def unsupported_construct(q):
    u = q.upper()
    if 'WITH RECURSIVE' in u: return 'WITH RECURSIVE'
    if 'LATERAL' in u: return 'LATERAL'
    if 'FLATTEN' in u: return 'FLATTEN'
    return None
for i, r in enumerate(recs):
    if only_id and r.get('instance_id') != only_id: continue
    variants = r['equivalent_sqls']
    idxs = range(len(variants)) if all_variants else [0]
    picked = False
    for k in idxs:
        q = variants[k]['sql']
        if to_postgres is not None:
            q, _terr = to_postgres(q)          # canonicalise to PostgreSQL; check constructs post-transpile
        c = unsupported_construct(q)
        if c: skipped.append((r.get('instance_id','?'), k, q, c)); continue
        tables = parse_ddl(r.get('ddl',''))
        if not tables: continue
        jobs.append((i, k, q, tables, r.get('instance_id','?')))
        picked = True
    if picked and len(jobs) >= N and not only_id: break

if not jobs:
    print("no matching records"); sys.exit(0)

# ---- emit one Lean file; #eval prints the conversion, def probed elaborates ----
lines = ['import LeanDatabase.Parser', 'import LeanDatabase.SQLSyntax',
         'open LeanDatabase Lean', 'set_option maxHeartbeats 1000000',
         'set_option maxRecDepth 8000', 'set_option maxErrors 100000']
tag = {}  # def-line -> job index (filled after we know line numbers)
job_lineinfo = []
for j, (i, k, q, tables, iid) in enumerate(jobs):
    seen = {}
    for name, cols in tables:
        if name not in seen: seen[name] = cols
    lines.append(f'namespace R{i}_{k}')
    for name, cols in seen.items():
        lines.append(f'CREATE TABLE {name} ({", ".join(f"«{c}» {t}" for c,t in cols)})')
    schemas = ', '.join(f'{name}_schema' for name in seen)
    lines.append(f'#eval IO.println s!"@@CONV {j}: " *> IO.println (LeanDatabase.normalizeSqlLiterals "{esc(q)}")')
    defline = len(lines) + 1                      # 1-indexed line of the def
    job_lineinfo.append((j, defline))
    lines.append(f'def probed := sql%([{schemas}]) "{esc(q)}"')
    lines.append(f'end R{i}_{k}')

src = '\n'.join(lines) + '\n'
gendir = os.path.join(ROOT, '.gen'); os.makedirs(gendir, exist_ok=True)  # outside the lake glob
path = os.path.join(gendir, '_elabcheck_gen.lean')
open(path, 'w').write(src)

# ---- run lean ----
print(f"elaborating {len(jobs)} queries (this can take a few minutes)...", file=sys.stderr)
proc = subprocess.run(['lake', 'env', 'lean', path], cwd=ROOT,
                      capture_output=True, text=True)
out, err = proc.stdout, proc.stderr

# ---- collect the conversions printed by #eval ----
conv = {}
cur = None; buf = []
for line in out.splitlines():
    m = re.match(r'@@CONV (\d+): ?$', line)
    if m:
        if cur is not None: conv[cur] = '\n'.join(buf)
        cur = int(m.group(1)); buf = []
    elif cur is not None:
        buf.append(line)
if cur is not None: conv[cur] = '\n'.join(buf)

# ---- map errors (by line number) to the def they belong to ----
# an error at line L belongs to the job whose def is the greatest defline <= L
deflines = sorted(job_lineinfo, key=lambda t: t[1])
def job_of_line(L):
    owner = None
    for j, dl in deflines:
        if dl <= L: owner = j
        else: break
    return owner

errs = {}   # job -> first error message
combined = err if err else out
for m in re.finditer(r'_elabcheck_gen\.lean:(\d+):\d+: error: (.*)', combined):
    L = int(m.group(1)); msg = m.group(2).strip()
    j = job_of_line(L)
    if j is not None and j not in errs:
        errs[j] = msg

# ---- report ----
ok = 0
for j, (i, k, q, tables, iid) in enumerate(jobs):
    status = "COMPILE ERROR" if j in errs else "OK"
    if status == "OK": ok += 1
    if not quiet:
        print(f"\n=== R{i} variant[{k}]  ({iid}) ===")
        print(f"SQL:       {re.sub(chr(10),' ',q)[:200]}")
        print(f"CONVERTED: {conv.get(j,'<not captured>')[:200]}")
        print(f"RESULT:    {status}" + (f": {errs[j]}" if j in errs else ""))

print(f"\n{'='*60}")
print(f"ELABORATES OK: {ok}/{len(jobs)}   COMPILE ERRORS: {len(jobs)-ok}")
from collections import Counter, defaultdict
def kind(msg):
    # bucket an error by ROOT CAUSE (coarse), so failures group for fixing one class at a time
    m = ' '.join(msg.split())
    if m.startswith('Failed to parse type in AS clause'): return 'parse: AS-clause alias/expression'
    if re.match(r'Failed to parse SQL query:\s*WITH', m):  return 'parse: WITH / CTE'
    if re.match(r'Failed to parse SQL query:\s*SELECT', m): return 'parse: SELECT body'
    if m.startswith('Failed to parse SQL query'):          return 'parse: other (empty/unknown)'
    if 'timeout at' in m or 'heartbeats' in m:             return 'elaboration timeout (heartbeats)'
    # fall back to a normalised head (strip quoted names + numbers)
    return re.sub(r"'[^']*'", "'X'", re.sub(r'[0-9]+', 'N', m))[:90]
c = Counter(kind(m) for m in errs.values())
print("error kinds:", dict(c.most_common(15)))

# ---- verbose grouped failures log ----
if log_path:
    groups = defaultdict(list)          # error-kind -> [(iid, k, q, msg)]
    for j, (i, k, q, tables, iid) in enumerate(jobs):
        if j in errs: groups[kind(errs[j])].append((iid, k, q, errs[j], j))
    subc = Counter(c for _, _, _, c in skipped)   # unsupported-construct breakdown
    total = ok + (len(jobs) - ok) + len(skipped)
    L = []
    bar = '=' * 70
    L += [bar, f" crossskill elaboration census — {total} queries ({len(recs)} records)", bar, '']
    L += [f"[*] ELABORATES OK: {ok}/{total}",
          f"[*] COMPILE ERRORS (attempted, failed): {len(jobs)-ok}",
          f"[*] UNSUPPORTED (not attempted — RECURSIVE/LATERAL/FLATTEN): {len(skipped)}",
          f"    ( {ok} + {len(jobs)-ok} + {len(skipped)} = {total} )", '',
          "[*] Failure categories (root cause, most common first):"]
    for kd, cnt in sorted(((k, len(v)) for k, v in groups.items()), key=lambda x: -x[1]):
        L.append(f"    {cnt:4d}x  {kd}")
    for cst, cnt in subc.most_common():
        L.append(f"    {cnt:4d}x  unsupported: {cst} (not attempted)")
    L += ['', bar, ' FAILURES BY CATEGORY (attempted)', bar]
    for kd, cnt in sorted(((k, len(v)) for k, v in groups.items()), key=lambda x: -x[1]):
        L += ['', f"### [{cnt}x]  {kd}", '']
        for iid, k, q, msg, j in groups[kd]:
            L.append(f"[compile_fail] {iid} variant[{k}]")
            L.append(f"    SQL:       {re.sub(chr(10),' ',q)[:220]}")
            L.append(f"    CONVERTED: {conv.get(j,'<not captured>')[:220]}")
            L.append(f"    ERROR:     {msg[:400]}")
    L += ['', bar, ' UNSUPPORTED CONSTRUCTS (not attempted)', bar]
    for cst, _ in subc.most_common():
        L += ['', f"### [{subc[cst]}x]  unsupported: {cst}", '']
        for iid, k, q, c in [s for s in skipped if s[3] == cst]:
            L.append(f"[unsupported] {iid} variant[{k}]  ({c})")
            L.append(f"    SQL:       {re.sub(chr(10),' ',q)[:220]}")
    open(log_path, 'w').write('\n'.join(L) + '\n')
    print(f"[*] verbose grouped census -> {log_path}  ({ok} ok, {len(jobs)-ok} fail, {len(skipped)} unsupported)")

os.remove(path)
sys.exit(len(jobs) - ok)
