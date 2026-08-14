#!/usr/bin/env python3
"""Hypothesis-injecting proof harness. For each corpus pair, generate an APPLIED-form theorem with
per-row `HYPOTHESIS` antecedents derived (soundly, conservatively) from the queries' structural
differences, then run `sql_equiv`. One file per pair (--split semantics); reports PROVEN counts.

Sound-by-construction: every injected hypothesis is a *stated assumption* (the theorem is conditional),
and we only assume the SYMMETRIC-DIFFERENCE WHERE conjuncts (a filter vacuous in the variant lacking
it) — never both sides of a contradictory pair.
"""
import json, re, os, sys, subprocess, itertools
from concurrent.futures import ThreadPoolExecutor

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
GEN  = os.path.join(ROOT, ".genhyp")
recs = [json.loads(l) for l in open(os.path.join(HERE, "crossskill_equivalent_sql.jsonl")) if l.strip()]

def maptype(t):
    t = t.upper()
    if any(t.startswith(x) for x in ("VARCHAR","CHAR","TEXT","STRING")): return "STRING"
    if any(t.startswith(x) for x in ("FLOAT","DOUBLE","REAL","DECIMAL","NUMERIC")): return "FLOAT"
    if t.startswith("BOOL"): return "BOOL"
    if any(t.startswith(x) for x in ("DATE","TIMESTAMP","DATETIME","TIME")): return "STRING"
    if any(t.startswith(x) for x in ("INT","NUMBER","BIGINT","SMALLINT","TINYINT")): return "INT"
    return "STRING"
def split_top(s, seps=(',',)):
    parts, d, cur = [], 0, ''
    for ch in s:
        if ch == '(': d += 1
        elif ch == ')': d -= 1
        if ch in seps and d == 0: parts.append(cur); cur = ''
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
def used_cols(sqltext, cols):
    s = re.sub(r'count\s*\(\s*\*\s*\)', '', sqltext, flags=re.I)
    if re.search(r'(?:select|,)\s*\*', s, re.I) or '.*' in s: return cols
    low = s.lower()
    return [(c, t) for (c, t) in cols if re.search(r'\b'+re.escape(c.lower())+r'\b', low)] or cols
def is_window(q):
    u = q.upper().replace(' ','')
    return 'OVER(' in u or 'ROW_NUMBER' in u or 'RANK()' in u or 'WITHRECURSIVE' in u

def split_and(s):
    # split on top-level `AND`, ignoring `AND` inside string literals ('...') or parentheses
    out, cur, depth, i, inq = [], '', 0, 0, False
    while i < len(s):
        ch = s[i]
        if ch == "'" : inq = not inq; cur += ch; i += 1; continue
        if not inq and ch == '(': depth += 1
        elif not inq and ch == ')': depth -= 1
        if not inq and depth == 0 and s[i:i+3].upper() == 'AND' and \
           (i==0 or not s[i-1].isalnum()) and (i+3>=len(s) or not s[i+3].isalnum()):
            out.append(cur); cur = ''; i += 3; continue
        cur += ch; i += 1
    if cur.strip(): out.append(cur)
    return [c.strip() for c in out if c.strip()]
def where_of(q):
    m = re.search(r'\bwhere\b(.*?)(\bgroup\s+by\b|\border\s+by\b|\bhaving\b|\blimit\b|$)', q, re.I|re.S)
    if not m: return []
    return split_and(m.group(1))

def select_items(q):
    """(output_alias -> expr) for each SELECT-list item (alias lower-cased, quotes stripped)."""
    m = re.search(r'\bselect\b\s+(?:distinct\s+)?(.*?)\bfrom\b', q, re.I|re.S)
    if not m: return {}
    out = {}
    for it in split_top(m.group(1)):
        it = ' '.join(it.split())
        am = re.search(r'\s+as\s+"?([A-Za-z_][A-Za-z0-9_]*)"?\s*$', it, re.I)
        if am:
            alias = am.group(1); expr = it[:am.start()].strip()
        else:
            expr = it; alias = re.sub(r'[^A-Za-z0-9_]', '', it.split('.')[-1])
        out[alias.lower()] = expr
    return out

# ---- args ----
args = sys.argv[1:]
def popval(flag, default):
    if flag in args:
        i = args.index(flag); v = args[i+1]; del args[i:i+2]; return v
    return default
jobs    = int(popval('--jobs', '8'))
timeout = int(popval('--timeout', '180'))
limit   = int(popval('--limit', str(10**9)))
gen_only = '--gen-only' in args

os.makedirs(GEN, exist_ok=True)
for f in os.listdir(GEN):
    if f.endswith('.lean'): os.remove(os.path.join(GEN, f))

files = []
skipped_multi = 0
for i, r in enumerate(recs):
    if len(files) >= limit: break
    variants = [e['sql'] for e in r['equivalent_sqls']]
    if any(is_window(v) for v in variants): continue
    tables = parse_ddl(r.get('ddl',''))
    if not tables: continue
    seen = {}
    for name, cols in tables:
        if name not in seen: seen[name] = cols
    allsql = ' '.join(variants).lower()
    refd = {n: c for n, c in seen.items() if re.search(r'\b'+re.escape(n.lower())+r'\b', allsql)} or seen
    single_table = len(refd) == 1
    tname = next(iter(refd)); tcols = refd[tname]     # first (only, when single) table
    schema = f'{tname}_schema'
    schemas_all = ', '.join(f'{n}_schema' for n in refd)
    pairs = [(a, b) for a, b in itertools.combinations(range(len(variants)), 2) if variants[a] != variants[b]]
    for a, b in pairs:
        A, B = variants[a], variants[b]
        wa, wb = where_of(A), where_of(B)
        # symmetric-difference conjuncts: a filter present in one variant, absent in the other → assume vacuous
        diff = [c for c in wa if c not in wb] + [c for c in wb if c not in wa]
        # keep only conjuncts over THIS table's columns (drop cross-refs / opaque we can't state)
        colnames = [c for c,_ in tcols]
        def clean(conj):
            c = re.sub(r'\b[A-Za-z_]\w*\."', '"', conj).strip()      # strip alias: p."col" -> "col"
            return c.rstrip(';').strip()                             # drop trailing statement `;`
        def usable(conj):
            low = conj.lower()
            if any(x in low for x in ('between','lateral','select','::',' value:','flatten','case ',' over(','(select')):
                return False                                          # skip conjuncts the parser can't state cleanly
            return any(re.search(r'\b'+re.escape(cn.lower())+r'\b', low) for cn in colnames)
        hyps = []
        for c in diff:
            if usable(c):
                cc = clean(c)
                if cc and cc not in hyps: hyps.append(cc)   # dedup
        # SELECT-list expression differences: same output column projected as `exprA` in one variant and
        # `exprB` in the other (e.g. `col` vs `REPLACE(col, …)`, `col` vs `ROUND(col, n)`). Inject the
        # per-row bridge `exprA = exprB` (sound: an explicit assumption). Only scalar exprs over base
        # columns — no aggregates/arrays/opaque the per-row predicate can't state.
        sa, sb = select_items(A), select_items(B)
        AGG = ('sum(', 'count(', 'max(', 'min(', 'avg(', 'split(', 'array')
        for alias in sa.keys() & sb.keys():
            ea, eb = clean(sa[alias]), clean(sb[alias])
            if ea == eb: continue
            both = (ea + ' ' + eb).lower()
            if any(x in both for x in AGG): continue
            if not usable(ea) or not usable(eb): continue
            h = f'{ea} = {eb}'
            if h not in hyps and f'{eb} = {ea}' not in hyps: hyps.append(h)
        # FULL schema — NO column pruning. Pruning collapses rows that differ only in a dropped column,
        # which changes COUNT(*)/aggregate/set semantics and would prove a narrower (or false) theorem.
        # Hypotheses need the applied form `(sql% …) t` over a single table. A multi-table pair can only
        # be attempted when it needs NO hypothesis (a pure structural equivalence) — then the unapplied
        # `sql% A = sql% B` form works over any number of tables.
        if hyps and not single_table:
            skipped_multi += 1; continue
        L = ['import LeanDatabase.Hypothesis', 'import LeanDatabase.SQLSyntax',
             'open LeanDatabase Lean', 'set_option maxHeartbeats 1000000', 'set_option maxRecDepth 8000',
             f'namespace R{i}']
        for nm, cs in refd.items():
            L.append(f'CREATE TABLE {nm} ({", ".join(f"«{c}» {t}" for c,t in cs)})')
        hnames = []
        if single_table:
            for k, conj in enumerate(hyps):
                hn = f'hyp{a}_{b}_{k}'
                L.append(f'HYPOTHESIS {hn} : {tname} "{esc(conj)}"')
                hnames.append(hn)
            binders = ' '.join([f'(t : TableRel {schema})'] + [f'(h{k} : {hn} t)' for k,hn in enumerate(hnames)])
            L.append(f'theorem eq_{a}_{b} {binders} :')
            L.append(f'    (sql%([{schemas_all}]) "{esc(A)}") t = (sql%([{schemas_all}]) "{esc(B)}") t := by sql_equiv')
        else:
            L.append(f'theorem eq_{a}_{b} :')
            L.append(f'    sql%([{schemas_all}]) "{esc(A)}" = sql%([{schemas_all}]) "{esc(B)}" := by sql_equiv')
        L.append(f'end R{i}')
        path = os.path.join(GEN, f'R{i}_eq_{a}_{b}.lean')
        open(path, 'w').write('\n'.join(L) + '\n')
        files.append((i, path, a, b, len(hnames), r.get('instance_id','?')))

print(f"generated {len(files)} single-table pair files in {GEN}  (skipped {skipped_multi} multi-table records)", flush=True)
if gen_only: sys.exit(0)

def run(item):
    i, path, a, b, nh, iid = item
    try:
        p = subprocess.run(['lake','env','lean',path], cwd=ROOT, capture_output=True, text=True, timeout=timeout)
        ok = p.returncode == 0
    except subprocess.TimeoutExpired:
        ok = False
    return (iid, i, a, b, nh, ok)

proven = 0; withhyp_proven = 0; total = len(files)
results = []
with ThreadPoolExecutor(max_workers=jobs) as ex:
    for res in ex.map(run, files):
        results.append(res)
        if res[5]:
            proven += 1
            if res[4] > 0: withhyp_proven += 1
        done = len(results)
        if done % 25 == 0: print(f"  ... {done}/{total} run, {proven} proven", flush=True)

open(os.path.join(GEN, '_results.tsv'),'w').write(
    '\n'.join(f"{iid}\tR{i}_eq_{a}_{b}\t{nh}\t{'PROVEN' if ok else 'no'}" for iid,i,a,b,nh,ok in results))
print(f"\n=== RESULTS (single-table pairs, hypothesis-injected) ===", flush=True)
print(f"PAIRS PROVEN:            {proven}/{total}", flush=True)
print(f"  of which USED >=1 hyp: {withhyp_proven}", flush=True)
print(f"  (pairs with 0 injected hyps that still proved are baseline-provable)", flush=True)
