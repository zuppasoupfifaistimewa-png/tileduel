import f3_kelompok as k, json
from collections import defaultdict
K=k.K
for n in ["_warnai_karakter","_teks_kartu_dadu","_teruskan_aksi_ke_host","_teks_gaji_gagal","_tunggu_langkah_ke_petak","_antrian_berisi_petak"]: K[n]="dasar"
for n,g in list(K.items()):
    if g=="migrasi": K[n]="jaringan"
for n in ["_tunggu_kesiapan_mulai","_tunggu_penanda","rpc_client_siap_mulai","rpc_mulai_permainan"]: K[n]="pokok"
URUTAN=["dasar","tampilan","papan","kartu","duel","jaringan","pokok"]
lap={g:i for i,g in enumerate(URUTAN)}
item=k.item; per=k.per_nama
dekl=[it for it in item if it["jenis"]!="func"]
# lapis deklarasi = lapis terendah pemakainya
L={}
pemakai=defaultdict(set)
for it in item:
    for r in it["ref"]:
        pemakai[r].add(it["nama"])
for d in dekl:
    fs=[lap[K[u]] for u in pemakai[d["nama"]] if u in K]
    n=d["nama"]
    if d["jenis"]=="signal" or n.startswith("_"):
        L[n]=min(fs) if fs else 0
    elif d["jenis"]=="const" and d["i"]>400:
        L[n]=min(fs) if fs else 0
    else:
        L[n]=0
# titik tetap: yang dirujuk deklarasi harus di lapis <= deklarasi itu
ubah=True
while ubah:
    ubah=False
    for d in dekl:
        for r in d["ref"]:
            if r in L and L[r]>L[d["nama"]]:
                L[r]=L[d["nama"]]; ubah=True
            if r in K and lap[K[r]]>L[d["nama"]]:
                print("PERINGATAN: deklarasi",d["nama"],"memakai fungsi",r,"dari lapis atas")
# cek: variabel/sinyal privat harus dipakai FUNGSI di lapisnya sendiri
for d in dekl:
    n=d["nama"]
    if d["jenis"]=="signal" or n.startswith("_"):
        pakai_lapis=[u for u in pemakai[n] if (u in K and lap[K[u]]==L[n]) or (u in L and L[u]==L[n])]
        if not pakai_lapis:
            print("TIDAK DIPAKAI DI LAPISNYA:",n,L[n],sorted(pemakai[n]))
per_lapis=defaultdict(list)
for d in dekl: per_lapis[URUTAN[L[d["nama"]]]].append(d["nama"])
bar=defaultdict(int)
for d in dekl: bar[URUTAN[L[d["nama"]]]]+=d["panjang"]
for f in k.fungsi: bar[K[f["nama"]]]+=f["panjang"]
for g in URUTAN:
    print(f"{g:9s} baris~{bar[g]:5d} deklarasi={len(per_lapis[g]):3d}: "+" ".join(per_lapis[g]))
n,t,a,naik,na=k.evaluasi(URUTAN)
print("DEKLARASI FUNGSI NAIK:", {f:(K[f],sorted(v)) for f,v in naik.items()})
print("AWAIT NAIK:", dict(na))
json.dump({"K":K,"L":{n:URUTAN[v] for n,v in L.items()},"urutan":URUTAN}, open("f3_rancangan.json","w"), indent=0)
