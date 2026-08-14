#!/usr/bin/env python3
"""Package PROVEN hypothesis-conditioned pairs (from /tmp/proven_all.txt, names like R138_eq_0_1) into
polished Examples/Proven/ files — one file per record, holding all its proven pair-theorems, with the
NL question and any injected HYPOTHESIS documented. Reuses provehyp.py's generation logic.
Usage: python3 gen_proven_hyp.py /tmp/proven_all.txt"""
import json, re, os, sys, collections
HERE=os.path.dirname(os.path.abspath(__file__)); ROOT=os.path.abspath(os.path.join(HERE,'..','..'))
OUT=os.path.join(ROOT,'Examples','Proven')
recs=[json.loads(l) for l in open(f'{HERE}/crossskill_equivalent_sql.jsonl') if l.strip()]
def maptype(t):
    t=t.upper()
    if any(t.startswith(x) for x in("VARCHAR","CHAR","TEXT","STRING")):return"STRING"
    if any(t.startswith(x) for x in("FLOAT","DOUBLE","REAL","DECIMAL","NUMERIC")):return"FLOAT"
    if t.startswith("BOOL"):return"BOOL"
    if any(t.startswith(x) for x in("DATE","TIMESTAMP","DATETIME","TIME")):return"STRING"
    if any(t.startswith(x) for x in("INT","NUMBER","BIGINT","SMALLINT","TINYINT")):return"INT"
    return"STRING"
def split_top(s):
    p,d,c=[],0,''
    for ch in s:
        if ch=='(':d+=1
        elif ch==')':d-=1
        if ch==',' and d==0:p.append(c);c=''
        else:c+=ch
    if c.strip():p.append(c)
    return p
def parse_ddl(ddl):
    out=[]
    for m in re.finditer(r'create\s+(?:or\s+replace\s+)?(?:transient\s+|temporary\s+|temp\s+)?table\s+([^\s(]+)\s*\(',ddl,re.I):
        name=m.group(1).replace('"','').split('.')[-1];i,depth=m.end()-1,0
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
def esc(q):return q.replace('\\','\\\\').replace('"','\\"').replace('\n','\\n')
def split_and(s):
    out,cur,depth,i,inq=[],'',0,0,False
    while i<len(s):
        ch=s[i]
        if ch=="'":inq=not inq;cur+=ch;i+=1;continue
        if not inq and ch=='(':depth+=1
        elif not inq and ch==')':depth-=1
        if not inq and depth==0 and s[i:i+3].upper()=='AND' and (i==0 or not s[i-1].isalnum()) and (i+3>=len(s) or not s[i+3].isalnum()):
            out.append(cur);cur='';i+=3;continue
        cur+=ch;i+=1
    if cur.strip():out.append(cur)
    return [c.strip() for c in out if c.strip()]
def where_of(q):
    m=re.search(r'\bwhere\b(.*?)(\bgroup\s+by\b|\border\s+by\b|\bhaving\b|\blimit\b|$)',q,re.I|re.S)
    return split_and(m.group(1)) if m else []
def clean(c):
    c=re.sub(r'\b[A-Za-z_]\w*\."','"',c).strip();return c.rstrip(';').strip()

proven=[l.strip() for l in open(sys.argv[1]) if l.strip()]
byrec=collections.defaultdict(list)
for name in proven:
    m=re.match(r'R(\d+)_eq_(\d+)_(\d+)$',name)
    if m: byrec[int(m.group(1))].append((int(m.group(2)),int(m.group(3))))
made=[]
for ri,pairs in sorted(byrec.items()):
    r=recs[ri]; iid=r['instance_id']; variants=[e['sql'] for e in r['equivalent_sqls']]
    seen={}
    for n,c in parse_ddl(r.get('ddl','')):
        if n not in seen:seen[n]=c
    allsql=' '.join(variants).lower()
    refd={n:c for n,c in seen.items() if re.search(r'\b'+re.escape(n.lower())+r'\b',allsql)} or seen
    if len(refd)!=1: continue
    tname=next(iter(refd)); tcols=refd[tname]; schema=f'{tname}_schema'; colnames=[c for c,_ in tcols]
    mod='P_'+re.sub(r'[^A-Za-z0-9_]','_',iid); nlq=' '.join((r.get('natural_language_question') or '').split())
    L=['import LeanDatabase.Hypothesis','import LeanDatabase.SQLSyntax','open LeanDatabase Lean',
       'set_option maxHeartbeats 1000000','set_option maxRecDepth 8000','','/-!',
       f'# {iid} — proven cross-skill equivalence(s)','',f'Question: {nlq}','',
       'Independently-written SQL variants proved equal for all table contents by `sql_equiv`; where',
       'they differ by a `WHERE` conjunct, that data assumption is an explicit `HYPOTHESIS` antecedent.',
       '-/','',f'namespace {mod}','',f'CREATE TABLE {tname} ({", ".join(f"«{c}» {t}" for c,t in tcols)})','']
    hypmap={}
    def usable(c):
        low=c.lower()
        if any(x in low for x in('between','lateral','select','::',' value:','flatten','case ',' over(','(select')):return False
        return any(re.search(r'\b'+re.escape(cn.lower())+r'\b',low) for cn in colnames)
    for a,b in pairs:
        diff=[c for c in where_of(variants[a]) if c not in where_of(variants[b])]+[c for c in where_of(variants[b]) if c not in where_of(variants[a])]
        for c in diff:
            if usable(c):
                cc=clean(c)
                if cc and cc not in hypmap: hypmap[cc]=f'h{len(hypmap)}'
    for conj,hn in hypmap.items(): L.append(f'HYPOTHESIS {hn} : {tname} "{esc(conj)}"')
    if hypmap: L.append('')
    for a,b in sorted(pairs):
        diff=[c for c in where_of(variants[a]) if c not in where_of(variants[b])]+[c for c in where_of(variants[b]) if c not in where_of(variants[a])]
        used=[]
        for c in diff:
            cc=clean(c)
            if cc in hypmap and hypmap[cc] not in used: used.append(hypmap[cc])
        binders=' '.join([f'(t : TableRel {schema})']+[f'(a{k} : {hn} t)' for k,hn in enumerate(used)])
        L.append(f'theorem eq_{a}_{b} {binders} :')
        L.append(f'    (sql%([{schema}]) "{esc(variants[a])}") t = (sql%([{schema}]) "{esc(variants[b])}") t := by sql_equiv')
    L.append(f'\nend {mod}')
    open(f'{OUT}/{mod}.lean','w').write('\n'.join(L)+'\n')
    made.append((mod,iid,len(pairs)))
for m,i,n in made: print(f"wrote {m}.lean ({i}, {n} pairs)")
print(f"\n{len(made)} files, {sum(n for _,_,n in made)} proven pairs")
