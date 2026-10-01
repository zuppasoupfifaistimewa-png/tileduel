import sys, collections as C
f=sys.argv[1]
ps=C.defaultdict(list); kn=C.defaultdict(list); kenaoleh=C.defaultdict(list); menang=C.Counter(); tampil=C.Counter()
winby=C.defaultdict(lambda:[0,0]); rinci0=0
for ln in open(f):
    d=dict(x.split('=',1) for x in ln.split() if '=' in x)
    if d.get('stat')!='OK': continue
    R=d['roles'].split(','); P=list(map(int,d['pasang'].split(','))); K=list(map(int,d['kena'].split(',')))
    w=int(d['pemenang'])
    for i,r in enumerate(R):
        ps[r].append(P[i]); kn[r].append(K[i]); tampil[r]+=1
        if i==w: menang[r]+=1
        # kena on opponents (2P only meaningful): traps of r stepped on by others
        oth=sum(K[j] for j in range(len(R)) if j!=i)
        kenaoleh[r].append(oth)
        b=min(P[i],4); winby[(r,b)][1]+=1; winby[(r,b)][0]+= (i==w)
m=lambda a: sum(a)/len(a)
print("role  pasang  kena(korban)  kena_lawan  menang%")
for r in sorted(ps): print(f"{r:6} {m(ps[r]):5.2f} {m(kn[r]):8.2f} {m(kenaoleh[r]):10.2f} {100*menang[r]/tampil[r]:6.1f}")
print("menang% per jumlah pasang (0..4+):")
for r in sorted(ps): print(r, [f"{b}:{winby[(r,b)][0]}/{winby[(r,b)][1]}" for b in range(5)])
