#!/usr/bin/env python3
"""End-to-end discovery: for each 'simple' record, emit schemas + a theorem proving variant[0]=variant[k]
via sql_equiv, one namespace per (record,k). Build the output to see which corpus equivalences prove."""
import json, re, os, sys
HERE=os.path.dirname(os.path.abspath(__file__))
recs=[json.loads(l) for l in open(os.path.join(HERE,"crossskill_equivalent_sql.jsonl")) if l.strip()]
def maptype(t):
    t=t.upper()
    if any(t.startswith(x) for x in ("VARCHAR","CHAR","TEXT","STRING")): return "STRING"
    if any(t.startswith(x) for x in ("FLOAT","DOUBLE","REAL","DECIMAL","NUMERIC")): return "FLOAT"
    if t.startswith("BOOL"): return "BOOL"
    if any(t.startswith(x) for x in ("DATE","TIMESTAMP","DATETIME","TIME")): return "STRING"
    if any(t.startswith(x) for x in ("INT","NUMBER","BIGINT","SMALLINT","TINYINT")): return "INT"
    return "STRING"
def split_top(s):
    parts,d,cur=[],0,''
    for ch in s:
        if ch=='(':d+=1
        elif ch==')':d-=1
        if ch==',' and d==0:parts.append(cur);cur=''
        else:cur+=ch
    if cur.strip():parts.append(cur)
    return parts
def parse_ddl(ddl):
    out=[]
    for m in re.finditer(r'create\s+(?:or\s+replace\s+)?(?:transient\s+|temporary\s+|temp\s+)?table\s+([^\s(]+)\s*\(',ddl,re.I):
        name=m.group(1).replace('"','').split('.')[-1]
        i,depth=m.end()-1,0
        while i<len(ddl):
            if ddl[i]=='(':depth+=1
            elif ddl[i]==')':
                depth-=1
                if depth==0:break
            i+=1
        cols=[]
        for line in split_top(ddl[m.end():i]):
            line=line.strip()
            if not line or re.match(r'(PRIMARY|FOREIGN|UNIQUE|CONSTRAINT|CHECK)\b',line,re.I):continue
            mm=re.match(r'"?([A-Za-z_][A-Za-z0-9_]*)"?\s+(\w+)',line)
            if mm:cols.append((mm.group(1),maptype(mm.group(2))))
        if cols:out.append((name,cols))
    return out
def esc(q): return q.replace('\\','\\\\').replace('"','\\"').replace('\n','\\n')
def simple(q):
    u=q.upper()
    if 'OVER(' in u.replace(' ','') or 'ROW_NUMBER' in u or 'RECURSIVE' in u: return False
    if 'WITH ' in u or 'GROUP BY' in u or 'LATERAL' in u or 'UNION' in u: return False
    return True
print('import LeanDatabase.Parser'); print('import LeanDatabase.SQLSyntax')
print('open LeanDatabase Lean'); print('set_option maxHeartbeats 800000')
for i,r in enumerate(recs):
    sqls=[e['sql'] for e in r['equivalent_sqls']]
    if not all(simple(s) for s in sqls): continue
    if len(set(sqls))<2: continue
    tables=parse_ddl(r.get('ddl',''))
    if not tables: continue
    seen={}
    for name,cols in tables:
        if name not in seen: seen[name]=cols
    print(f'\nnamespace R{i}')
    for name,cols in seen.items():
        print(f'CREATE TABLE {name} ({", ".join(f"«{c}» {t}" for c,t in cols)})')
    schemas=', '.join(f'{name}_schema' for name in seen)
    v0=sqls[0]
    for k in range(1,len(sqls)):
        if sqls[k]==v0: continue
        print(f'theorem eq{k} : sql%([{schemas}]) "{esc(v0)}" = sql%([{schemas}]) "{esc(sqls[k])}" := by sql_equiv')
    print(f'end R{i}')
