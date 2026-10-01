import sys, collections as C
a,b=sys.argv[2],sys.argv[3]
t=C.defaultdict(lambda:[0,0]); pk=C.defaultdict(list)
for ln in open(sys.argv[1]):
    d=dict(x.split('=',1) for x in ln.split() if '=' in x)
    R=d['roles'].split(',');
    if sorted(R)!=sorted([a,b]) or len(R)!=2: continue
    P=d['presets'].split(','); w=int(d['pemenang']); K=list(map(int,d['kena'].split(','))); S=list(map(int,d['pasang'].split(',')))
    ia=R.index(a); ib=1-ia
    k=(P[ia],P[ib]); t[k][1]+=1; t[k][0]+=(w==ia)
    pk[a].append((S[ia],K[ia])); pk[b].append((S[ib],K[ib]))
for k in sorted(t): print(f"{a} {k[0]:9} vs {b} {k[1]:9}: {t[k][0]}/{t[k][1]}")
for r in pk: print(r,"pasang %.2f kena %.2f"%(sum(x for x,_ in pk[r])/len(pk[r]),sum(y for _,y in pk[r])/len(pk[r])))
