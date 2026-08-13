#!/usr/bin/env python3
"""Turn the PROVEN pairs found by `provefiles.py --split` (in .gen/_results.tsv) into polished,
committed example files under Examples/Proven/ — each a real `sql_equiv` proof of a corpus equivalence,
with the natural-language question and both SQL variants as documentation.

Usage: python3 gen_proven.py [N]        # up to N examples (default 40), one per distinct problem
"""
import json, re, os, sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
GEN  = os.path.join(ROOT, ".gen")
OUT  = os.path.join(ROOT, "Examples", "Proven")
recs = [json.loads(l) for l in open(os.path.join(HERE, "crossskill_equivalent_sql.jsonl")) if l.strip()]

# --- ddl -> schema (same rules as provefiles.py) ---
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
def used_cols(sqltext, cols):
    s = re.sub(r'count\s*\(\s*\*\s*\)', '', sqltext, flags=re.I)
    if '*' in s: return cols
    low = s.lower()
    return [(c, t) for (c, t) in cols if re.search(r'\b'+re.escape(c.lower())+r'\b', low)] or cols

N = int(sys.argv[1]) if len(sys.argv) > 1 else 40

# --- read proven pairs from the discovery TSV ---
tsv = os.path.join(GEN, '_results.tsv')
if not os.path.exists(tsv):
    print(f"no {tsv}; run `provefiles.py --split` first", file=sys.stderr); sys.exit(1)
proven = []   # (record_i, a, b)
for line in open(tsv):
    f = line.rstrip('\n').split('\t')
    if len(f) < 5 or f[4] != 'PROVEN': continue
    m = re.match(r'R(\d+)_eq_(\d+)_(\d+)$', f[0])
    if m: proven.append((int(m.group(1)), int(m.group(2)), int(m.group(3))))

# one example per distinct problem (record), in record order
seen_rec, picked = set(), []
for i, a, b in sorted(proven):
    if i in seen_rec: continue
    seen_rec.add(i); picked.append((i, a, b))
    if len(picked) >= N: break

os.makedirs(OUT, exist_ok=True)
made = []
for i, a, b in picked:
    r = recs[i]
    iid = r.get('instance_id', f'r{i}')
    variants = [e['sql'] for e in r['equivalent_sqls']]
    tables = parse_ddl(r.get('ddl',''))
    seen = {}
    for name, cols in tables:
        if name not in seen: seen[name] = cols
    allsql = ' '.join(variants).lower()
    refd = {n: c for n, c in seen.items() if re.search(r'\b'+re.escape(n.lower())+r'\b', allsql)} or seen
    schemas = ', '.join(f'{name}_schema' for name in refd)
    mod = 'P_' + re.sub(r'[^A-Za-z0-9_]', '_', iid)          # valid, capitalised module name
    nlq = ' '.join((r.get('natural_language_question') or '').split())
    va, vb = variants[a], variants[b]
    L = []
    L.append('import LeanDatabase.Parser')
    L.append('import LeanDatabase.SQLSyntax')
    L.append('open LeanDatabase Lean')
    L.append('set_option maxHeartbeats 1000000')
    L.append('set_option maxRecDepth 8000')
    L.append('')
    L.append('/-!')
    L.append(f'# {iid} — a proven cross-skill equivalence')
    L.append('')
    if nlq: L.append(f'Question: {nlq}')
    L.append('')
    L.append('Two independently-written SQL answers to the same question, proved equivalent for *all*')
    L.append('table contents by `sql_equiv` (not just on one instance).')
    L.append('-/')
    L.append('')
    L.append(f'namespace {mod}')
    L.append('')
    for name, cols in refd.items():
        pruned = used_cols(va + ' ' + vb, cols)   # columns this pair touches (small, fast to check)
        L.append(f'CREATE TABLE {name} ({", ".join(f"«{c}» {t}" for c,t in pruned)})')
    L.append('')
    L.append(f'/-- Variant A:  {" ".join(va.split())[:160]}')
    L.append(f'    Variant B:  {" ".join(vb.split())[:160]} -/')
    L.append(f'theorem equivalent :')
    L.append(f'    sql%([{schemas}]) "{esc(va)}"')
    L.append(f'      = sql%([{schemas}]) "{esc(vb)}" := by sql_equiv')
    L.append('')
    L.append(f'end {mod}')
    open(os.path.join(OUT, mod + '.lean'), 'w').write('\n'.join(L) + '\n')
    made.append((mod, iid))

# index / README
idx = [f"# Proven cross-skill equivalences ({len(made)})", "",
       "Each file proves, via the `sql_equiv` tactic, that two independently-written SQL queries",
       "answering the same question denote the *same* relation for all table contents. Generated from",
       "the crossskill corpus by `Examples/CrossSkill/gen_proven.py`; all are checked by `lake build`.",
       ""]
for mod, iid in made:
    idx.append(f"- `{mod}.lean` — {iid}")
open(os.path.join(OUT, 'README.md'), 'w').write('\n'.join(idx) + '\n')
print(f"wrote {len(made)} example files to {OUT}")
for mod, iid in made: print(f"  {mod}  ({iid})")
