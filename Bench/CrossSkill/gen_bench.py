#!/usr/bin/env python3
"""Generate the full crossskill bench: one committed Lean file per record under Problems/, holding all
its variant-pair equivalence theorems. Each theorem is `by first | sql_equiv | sorry` — `sql_equiv`
where it closes, `sorry` otherwise. Data-dependent differences become explicit `HYPOTHESIS` antecedents
(sound: the theorem is conditional). Reuses `provehyp.py`'s inference. These files are NOT in the lake
build glob (many don't elaborate yet), so they are a worklist to open and run interactively.

Usage: python3 gen_bench.py [--limit N]
"""
import json, re, os, sys, itertools
HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
OUT  = os.path.join(HERE, "Problems")
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
    parts, d, cur, inq = [], 0, '', False
    for ch in s:
        if ch == "'": inq = not inq
        if not inq and ch == '(': d += 1
        elif not inq and ch == ')': d -= 1
        if not inq and ch in seps and d == 0: parts.append(cur); cur = ''
        else: cur += ch
    if cur.strip(): parts.append(cur)
    return parts
def parse_ddl(ddl):
    out = []
    for m in re.finditer(r'create\s+(?:or\s+replace\s+)?(?:transient\s+|temporary\s+|temp\s+)?table\s+([^\s(]+)\s*\(', ddl, re.I):
        name = m.group(1).replace('"','').split('.')[-1]; i, depth = m.end()-1, 0
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
    u = q.upper()
    return 'WITH RECURSIVE' in u or 'LATERAL' in u or 'FLATTEN' in u
def split_and(s):
    out, cur, depth, i, inq = [], '', 0, 0, False
    while i < len(s):
        ch = s[i]
        if ch == "'": inq = not inq; cur += ch; i += 1; continue
        if not inq and ch == '(': depth += 1
        elif not inq and ch == ')': depth -= 1
        if not inq and depth == 0 and s[i:i+3].upper() == 'AND' and \
           (i == 0 or not s[i-1].isalnum()) and (i+3 >= len(s) or not s[i+3].isalnum()):
            out.append(cur); cur = ''; i += 3; continue
        cur += ch; i += 1
    if cur.strip(): out.append(cur)
    return [c.strip() for c in out if c.strip()]
def where_of(q):
    m = re.search(r'\bwhere\b(.*?)(\bgroup\s+by\b|\border\s+by\b|\bhaving\b|\blimit\b|$)', q, re.I|re.S)
    return split_and(m.group(1)) if m else []
def select_items(q):
    m = re.search(r'\bselect\b\s+(?:distinct\s+)?(.*?)\bfrom\b', q, re.I|re.S)
    if not m: return {}
    out = {}
    for it in split_top(m.group(1)):
        it = ' '.join(it.split())
        am = re.search(r'\s+as\s+"?([A-Za-z_][A-Za-z0-9_]*)"?\s*$', it, re.I)
        if am: alias, expr = am.group(1), it[:am.start()].strip()
        else: expr = it; alias = re.sub(r'[^A-Za-z0-9_]', '', it.split('.')[-1])
        out[alias.lower()] = expr
    return out

limit = int(sys.argv[sys.argv.index('--limit')+1]) if '--limit' in sys.argv else 10**9
os.makedirs(OUT, exist_ok=True)
for f in os.listdir(OUT):
    if f.endswith('.lean'): os.remove(os.path.join(OUT, f))

made, index = 0, []
for r in recs:
    if made >= limit: break
    iid = r.get('instance_id', f'r{made}')
    variants = [e['sql'] for e in r['equivalent_sqls']]
    tables = parse_ddl(r.get('ddl', ''))
    if not tables: continue
    seen = {}
    for name, cols in tables:
        if name not in seen: seen[name] = cols
    allsql = ' '.join(variants).lower()
    refd = {n: c for n, c in seen.items() if re.search(r'\b'+re.escape(n.lower())+r'\b', allsql)} or seen
    single_table = len(refd) == 1
    tname = next(iter(refd)); tcols = refd[tname]
    schema = f'{tname}_schema'
    schemas_all = ', '.join(f'{n}_schema' for n in refd)
    mod = 'Bench_' + re.sub(r'[^A-Za-z0-9_]', '_', iid)
    nlq = ' '.join((r.get('natural_language_question') or '').split())
    pairs = [(a, b) for a, b in itertools.combinations(range(len(variants)), 2) if variants[a] != variants[b]]
    if not pairs: continue

    L = ['import LeanDatabase.Hypothesis', 'import LeanDatabase.SQLSyntax',
         'open LeanDatabase Lean', 'set_option maxHeartbeats 1000000', 'set_option maxRecDepth 8000',
         'set_option sqlEquivLlm.provider "gemini"', 'set_option sqlEquivLlm.model "gemini-pro-latest"',
         '', '/-!', f'# {iid} — crossskill equivalence(s)']
    if nlq: L += ['', f'Question: {nlq}']
    if any(is_window(v) for v in variants):
        L += ['', 'NOTE: uses WITH RECURSIVE / LATERAL / FLATTEN — may not elaborate yet.']
    L += ['', 'Each theorem: `first | sql_equiv | sorry` — proved by `sql_equiv` where it closes, else',
          '`sorry`. Data-dependent differences are stated as explicit `HYPOTHESIS` antecedents (sound).',
          '-/', '', f'namespace {mod}', '']
    for nm, cs in refd.items():
        L.append(f'CREATE TABLE {nm} ({", ".join(f"«{c}» {t}" for c,t in cs)})')
    L.append('')

    colnames = [c for c, _ in tcols]
    colset = {c.lower() for c in colnames}
    def clean(conj):
        c = re.sub(r'\b[A-Za-z_]\w*\."', '"', conj).strip()
        return c.rstrip(';').strip()
    def usable(conj):
        low = conj.lower()
        if any(x in low for x in ('between','lateral','select','::',' value:','flatten','case ',' over(','(select')):
            return False
        return any(re.search(r'\b'+re.escape(cn.lower())+r'\b', low) for cn in colnames)
    def distinct_cols(q):
        return [m for m in re.findall(r'count\(\s*distinct\s+"?(\w+)', q, re.I) if m.lower() in colset]

    for a, b in pairs:
        A, B = variants[a], variants[b]
        wa, wb = where_of(A), where_of(B)
        diff = [c for c in wa if c not in wb] + [c for c in wb if c not in wa]
        hyps = []
        for c in diff:
            if usable(c):
                cc = clean(c)
                if cc and cc not in hyps: hyps.append(cc)
        sa, sb = select_items(A), select_items(B)
        AGG = ('sum(', 'count(', 'max(', 'min(', 'avg(', 'split(', 'array')
        for alias in sa.keys() & sb.keys():
            ea, eb = clean(sa[alias]), clean(sb[alias])
            if ea == eb: continue
            both = (ea + ' ' + eb).lower()
            if any(x in both for x in AGG) or not usable(ea) or not usable(eb): continue
            h = f'{ea} = {eb}'
            if h not in hyps and f'{eb} = {ea}' not in hyps: hyps.append(h)
        da = [c for c in distinct_cols(A) if c.lower() not in {x.lower() for x in distinct_cols(B)}]
        db = [c for c in distinct_cols(B) if c.lower() not in {x.lower() for x in distinct_cols(A)}]
        bijs = []
        for ca, cb in zip(da, db):
            if (ca, cb) not in bijs and (cb, ca) not in bijs: bijs.append((ca, cb))

        needs_hyp = bool(hyps or bijs)
        rel = '~=' if set(sa.keys()) != set(sb.keys()) else '='
        if needs_hyp and single_table:
            hnames = []
            for k, conj in enumerate(hyps):
                hn = f'hyp{a}_{b}_{k}'; L.append(f'HYPOTHESIS {hn} : {tname} "{esc(conj)}"'); hnames.append(hn)
            for k, (ca, cb) in enumerate(bijs):
                hn = f'bij{a}_{b}_{k}'; L.append(f'HYPOTHESIS {hn} : {tname} BIJECTION «{ca}» «{cb}»'); hnames.append(hn)
            binders = ' '.join([f'(t : TableRel {schema})'] + [f'(h{k} : {hn} t)' for k, hn in enumerate(hnames)])
            L.append(f'theorem eq_{a}_{b} {binders} :')
            L.append(f'    (sql%([{schemas_all}]) "{esc(A)}") t {rel} (sql%([{schemas_all}]) "{esc(B)}") t := by')
            L.append(f'  first | sql_equiv | sorry')
        else:
            if needs_hyp:  # multi-table + data-dependent: can't cleanly state per-row hyp — leave a note
                L.append(f'-- eq_{a}_{b}: needs a data hypothesis over multiple tables (not stated); likely `sorry`.')
            op = '~=' if rel == '~=' else '='
            if op == '~=':
                L.append(f'theorem eq_{a}_{b} : ∀ t,')
                L.append(f'    (sql%([{schemas_all}]) "{esc(A)}") t ~= (sql%([{schemas_all}]) "{esc(B)}") t := by')
                L.append(f'  intro t; first | sql_equiv | sorry')
            else:
                L.append(f'theorem eq_{a}_{b} :')
                L.append(f'    sql%([{schemas_all}]) "{esc(A)}" = sql%([{schemas_all}]) "{esc(B)}" := by')
                L.append(f'  first | sql_equiv | sorry')
        L.append('')
    L.append(f'end {mod}')
    open(os.path.join(OUT, mod + '.lean'), 'w').write('\n'.join(L) + '\n')
    made += 1; index.append((mod, iid, len(pairs)))

idx = [f"# Crossskill bench — {made} records", "",
       "One file per corpus record; each proves its variant-pair equivalences via",
       "`first | sql_equiv | sorry`. Data-dependent differences are explicit `HYPOTHESIS` antecedents.",
       "Not in the `lake build` glob (many don't elaborate yet) — open a file and run the tactic, or",
       "swap `sql_equiv` for `sql_equiv_llm` (needs a key in `.env`).", ""]
for mod, iid, npairs in index:
    idx.append(f"- `Problems/{mod}.lean` — {iid} ({npairs} pair{'s' if npairs != 1 else ''})")
open(os.path.join(HERE, 'Problems', 'README.md'), 'w').write('\n'.join(idx) + '\n')
print(f"wrote {made} record files to {OUT}")
