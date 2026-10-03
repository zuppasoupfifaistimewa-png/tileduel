import re,sys,collections as C
def baca(f):
    out=[]
    for l in open(f):
        if 'roles=' not in l or 'stat=OK' not in l and 'pemenang=' not in l: continue
        d=dict(kv.split('=',1) for kv in l.split() if '=' in kv)
        if d.get('pemenang','-1')=='-1': continue
        out.append(d)
    return out
def pair(rows,a,b):
    r=[]
    for d in rows:
        ro=d['roles'].split(',')
        if sorted(ro)!=sorted([a,b]): continue
        ia=ro.index(a); ib=1-ia
        g=lambda k: d[k].split(',')
        rin=[x.split('/') for x in g('rinci')]
        r.append(dict(win=int(d['pemenang'])==ia, ia=ia, cara=d['cara'], gil=int(d['giliran']),
          pasA=int(g('pasang')[ia]),pasB=int(g('pasang')[ib]),kenA=int(g('kena')[ia]),kenB=int(g('kena')[ib]),
          kayA=int(g('kaya')[ia]),kayB=int(g('kaya')[ib]),rA=list(map(int,rin[ia])),rB=list(map(int,rin[ib])),
          f5=list(map(int,d.get('f5','0/0/0/0/0').split('/'))),pre=d.get('presets','-').split(','),peta=d['peta']))
    return r
def lap(nama,r):
    n=len(r); w=sum(x['win'] for x in r)
    m=lambda f: sum(f(x) for x in r)/max(n,1)
    print(f"--- {nama}: n={n} api menang {w} ({100*w/max(n,1):.1f}%)")
    print(f"  pasang api {m(lambda x:x['pasA']):.2f} (role {m(lambda x:x['rA'][0]):.2f}) petir {m(lambda x:x['pasB']):.2f} (role {m(lambda x:x['rB'][0]):.2f})")
    print(f"  kena(jebakan yg dipasang X dan kena?) api {m(lambda x:x['kenA']):.2f} petir {m(lambda x:x['kenB']):.2f}")
    print(f"  koin_jebakan api {m(lambda x:x['rA'][1]):.0f} petir {m(lambda x:x['rB'][1]):.0f} | duel m/k api {m(lambda x:x['rA'][2]):.2f}/{m(lambda x:x['rA'][3]):.2f} petir {m(lambda x:x['rB'][2]):.2f}/{m(lambda x:x['rB'][3]):.2f}")
    print(f"  tahan_kurangi api {m(lambda x:x['rA'][4]):.1f} petir {m(lambda x:x['rB'][4]):.1f} | petak_beli api {m(lambda x:x['rA'][5]):.2f} petir {m(lambda x:x['rB'][5]):.2f}")
    print(f"  kaya api {m(lambda x:x['kayA']):.0f} petir {m(lambda x:x['kayB']):.0f} | giliran {m(lambda x:x['gil']):.1f} | cara {dict(C.Counter(x['cara'] for x in r))}")
    for c in ('start','ronde'):
        s=[x for x in r if x['cara']==c]
        if s: print(f"   cara={c}: n={len(s)} api menang {sum(x['win'] for x in s)}")
    print(f"  f5 rata ev/bm/bk/kb/hb: {[round(sum(x['f5'][i] for x in r)/max(n,1),2) for i in range(5)]}")
    # kursi
    for k in (0,1):
        s=[x for x in r if x['ia']==k]; print(f"   api kursi {k}: {sum(x['win'] for x in s)}/{len(s)}",end='')
    print()
    # api pasang role 0 vs >0
    for lab,f in (('api pasang role=0',lambda x:x['rA'][0]==0),('api pasang role>0',lambda x:x['rA'][0]>0),('kb>0',lambda x:x['f5'][3]>0),('bk>0',lambda x:x['f5'][2]>0)):
        s=[x for x in r if f(x)]; print(f"   {lab}: {sum(x['win'] for x in s)}/{len(s)}",end='')
    print()
files=sys.argv[1:]
for f in files:
    rows=baca(f); lap(f.split('hasil/')[-1],pair(rows,'api','petir'))
print("==== gabungan pasca-F5 (50000+80000+110000) & pra-F5 20000")
import itertools
def grup(r,key,lab):
    g=C.defaultdict(lambda:[0,0])
    for x in r: k=key(x); g[k][0]+=x['win']; g[k][1]+=1
    print(f"  {lab}: "+"  ".join(f"{k}:{v[0]}/{v[1]}={100*v[0]/v[1]:.0f}%" for k,v in sorted(g.items())))
for nama,fs in (('pra-F5',files[:1]),('pasca-F5',files[1:])):
    r=[x for f in fs for x in pair(baca(f),'api','petir')]
    print(nama,len(r),sum(x['win'] for x in r))
    grup(r,lambda x:min(x['kenB'],3),'api kena petir (jebakan petir kena) ->')
    grup(r,lambda x:min(x['kenA'],3),'petir kena jebakan api ->')
    grup(r,lambda x:min(x['pasA']-x['rA'][0],2),'api pasang non-api ->')
    grup(r,lambda x:min(x['rA'][0],3),'api pasang api ->')
    grup(r,lambda x:x['pre'][x['ia']],'preset api')
    grup(r,lambda x:x['pre'][1-x['ia']],'preset petir')
    grup(r,lambda x:x['peta'],'peta')
    grup(r,lambda x:x['cara'],'cara')
    m=lambda f: sum(f(x) for x in r)/len(r)
    print(f"  selisih kaya (api-petir) menang {sum(x['kayA']-x['kayB'] for x in r if x['win'])/max(1,sum(x['win'] for x in r)):.0f} kalah {sum(x['kayA']-x['kayB'] for x in r if not x['win'])/max(1,sum(not x['win'] for x in r)):.0f}")
    # pembanding: api vs lain & petir vs lain
    for a,b in (('api','air'),('api','angin'),('api','tanah'),('petir','air'),('petir','angin'),('petir','tanah')):
        q=[x for f in fs for x in pair(baca(f),a,b)]
        mm=lambda f: sum(f(x) for x in q)/len(q)
        print(f"   {a} vs {b}: {sum(x['win'] for x in q)}/{len(q)} pas {mm(lambda x:x['pasA']):.2f}/{mm(lambda x:x['pasB']):.2f} kenaA {mm(lambda x:x['kenA']):.2f} kenaB {mm(lambda x:x['kenB']):.2f} koinjeb {mm(lambda x:x['rA'][1]):.0f}/{mm(lambda x:x['rB'][1]):.0f} kaya {mm(lambda x:x['kayA']):.0f}/{mm(lambda x:x['kayB']):.0f}")
