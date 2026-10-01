#!/usr/bin/env python3
"""U3 (Fase 4): ringkas hasil uji_seimbang.sh.
Pakai: ringkas_seimbang.py <berkas_hasil> [tag_awalan]
- Persentase menang per role (gabungan semua lawan) + rentang keyakinan 95% (Wilson).
- 2 pemain: per pasangan role (role A vs B, dua arah kursi digabung); pasangan "terlalu
  kuat" kalau batas BAWAH rentang keyakinan menang > 55% (rencana bagian 9).
- Jebakan dipasang per AI per pertandingan (rata2, median, sebaran, % dalam 2-6).
- Detik dalam-permainan rata2 per jumlah pemain (untuk dibanding patokan +15%).
- F0 (B-f, 14.19): baris SEIMBANG sekarang (opsional) punya presets=/sacred=/xprole0=
  (uji_nyata.gd F0) -> sel role x preset (P14 "wajib"/"mati" per sel), rata2 sacred,
  rata2 xprole0 (dilewati baris yang xprole0=-1, tidak tersedia).
"""
import sys, re, math, statistics
from collections import defaultdict

def wilson(k, n, z=1.96):
    if n == 0:
        return (0.0, 0.0, 0.0)
    p = k / n
    d = 1 + z * z / n
    c = (p + z * z / (2 * n)) / d
    h = z * math.sqrt(p * (1 - p) / n + z * z / (4 * n * n)) / d
    return (p, c - h, c + h)

def baca(berkas, awalan):
    baris = []
    for l in open(berkas):
        m = dict(re.findall(r"(\w+)=(\S+)", l))
        if not m.get("tag", "").startswith(awalan):
            continue
        m["_mentah"] = l.strip()
        baris.append(m)
    return baris

def main():
    berkas = sys.argv[1]
    awalan = sys.argv[2] if len(sys.argv) > 2 else ""
    data = baca(berkas, awalan)
    gagal = [d for d in data if "GAGAL_TANPA_BARIS" in d["_mentah"] or d.get("cara") in ("MACET",) or int(d.get("err", "0")) > 0 or d.get("stat") not in ("OK", None)]
    sah = [d for d in data if d not in gagal and "roles" in d and int(d.get("pemenang", "-1")) >= 0]
    print(f"== {awalan or 'semua'}: {len(data)} baris, {len(sah)} sah, {len(gagal)} gagal/macet/error")
    for d in gagal[:10]:
        print("   GAGAL:", d["_mentah"][:200])
    if not sah:
        return
    menang = defaultdict(int)
    tampil = defaultdict(int)
    pas_menang = defaultdict(int)
    pas_n = defaultdict(int)
    pasang_ai = []
    detik = defaultdict(list)
    cara = defaultdict(int)
    # F0 (B-f, 14.19): sel role x preset (P14) + sacred + xprole0.
    sel_tampil = defaultdict(int)
    sel_menang = defaultdict(int)
    sacred_semua = []
    xprole0_semua = []
    xprole0_lewat = 0
    for d in sah:
        roles = d["roles"].split(",")
        pm = int(d["pemenang"])
        np_ = len(roles)
        detik[np_].append(float(d["detik"]))
        cara[d["cara"]] += 1
        presets = d.get("presets", "").split(",") if d.get("presets") else []
        for s, r in enumerate(roles):
            tampil[r] += 1
            if s == pm:
                menang[r] += 1
            if s < len(presets) and presets[s] != "-":
                kunci_sel = (r, presets[s])
                sel_tampil[kunci_sel] += 1
                if s == pm:
                    sel_menang[kunci_sel] += 1
        if np_ == 2 and roles[0] != roles[1]:
            for a, b in ((0, 1), (1, 0)):
                kunci = (roles[a], roles[b])
                pas_n[kunci] += 1
                if pm == a:
                    pas_menang[kunci] += 1
        pasang_ai += [int(x) for x in d["pasang"].split(",")]
        if "sacred" in d:
            sacred_semua.append(int(d["sacred"]))
        if "xprole0" in d:
            xp0 = int(d["xprole0"])
            if xp0 < 0:
                xprole0_lewat += 1
            else:
                xprole0_semua.append(xp0)
    print("  per role (menang / tampil, 95% CI):")
    for r in sorted(tampil):
        p, lo, hi = wilson(menang[r], tampil[r])
        print(f"    {r:6s} {menang[r]:4d}/{tampil[r]:4d} = {p*100:5.1f}%  [{lo*100:5.1f} - {hi*100:5.1f}]")
    if pas_n:
        print("  per pasangan (baris menang lawan kolom), tanda ! = batas bawah CI > 55%:")
        for (a, b) in sorted(pas_n):
            if a < b or (b, a) not in pas_n:
                p, lo, hi = wilson(pas_menang[(a, b)], pas_n[(a, b)])
                tanda = "!" if lo > 0.55 or hi < 0.45 else " "
                print(f"   {tanda}{a:6s} vs {b:6s} {pas_menang[(a,b)]:3d}/{pas_n[(a,b)]:3d} = {p*100:5.1f}% [{lo*100:5.1f}-{hi*100:5.1f}]")
    if pasang_ai:
        dalam = sum(1 for x in pasang_ai if 2 <= x <= 6)
        sebar = {k: pasang_ai.count(k) for k in sorted(set(pasang_ai))}
        print(f"  jebakan/AI/pertandingan: rata2 {statistics.mean(pasang_ai):.2f} median {statistics.median(pasang_ai)} "
              f"dalam 2-6: {dalam}/{len(pasang_ai)} ({100*dalam/len(pasang_ai):.0f}%)  sebaran {sebar}")
    for np_ in sorted(detik):
        xs = detik[np_]
        sd = statistics.stdev(xs) if len(xs) > 1 else 0
        print(f"  detik {np_} pemain: n={len(xs)} rata2 {statistics.mean(xs):.1f} (+-{1.96*sd/math.sqrt(len(xs)):.1f} CI95)")
    print("  cara berakhir:", dict(cara))
    if sel_tampil:
        print("  sel role x preset (P14 TAMBAHAN B-f: ! wajib batas bawah CI>55%, x mati batas atas CI<42%):")
        for (r, pr) in sorted(sel_tampil):
            p, lo, hi = wilson(sel_menang[(r, pr)], sel_tampil[(r, pr)])
            tanda = "!" if lo > 0.55 else ("x" if hi < 0.42 else " ")
            print(f"   {tanda}{r:6s} x {pr:10s} {sel_menang[(r,pr)]:4d}/{sel_tampil[(r,pr)]:4d} = {p*100:5.1f}%  [{lo*100:5.1f} - {hi*100:5.1f}]")
    if sacred_semua:
        print(f"  sacred/pertandingan: rata2 {statistics.mean(sacred_semua):.2f} (n={len(sacred_semua)}, dari {len(sah)} baris sah)")
    if xprole0_semua or xprole0_lewat:
        if xprole0_semua:
            print(f"  xprole0 slot 0: rata2 {statistics.mean(xprole0_semua):.1f} (n={len(xprole0_semua)}) -- {xprole0_lewat} baris dilewati (tidak tersedia)")
        else:
            print(f"  xprole0 slot 0: semua {xprole0_lewat} baris tidak tersedia")

if __name__ == "__main__":
    main()
