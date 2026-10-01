#!/usr/bin/env python3
"""F0 (B-f, 14.19): pembuat berkas tugas U9 (S1-S5) untuk f4/uji_seimbang.sh.
Pakai: buat_tugas_u9.py <dir_keluaran>
Menulis 5 berkas: s1.tugas .. s5.tugas, format satu baris per pertandingan:
  "<tag> <lawan> <peta> <seed> <panjang> <role,role,..|-> [ekstra..]"
(persis format uji_seimbang.sh -- lihat komentar berkas itu).

Benih mulai 5000 (K24), NAIK 1 per baris LINTAS S1-S5 (jadi tiap baris punya benih
unik walau lain S -- gampang lacak). Peta bergantian alam/pantai per indeks baris
(bukan per pertandingan acak) -- deterministik & seimbang jumlah tiap peta. Preset
per slot DIUNDI DI SINI (Python, bukan di game) dari random.Random(seed) supaya
apa adanya diulang (rig lain, atau ulang skrip ini, hasil SAMA untuk seed sama).

S1 Arena 2P: 10 pasangan role (kombinasi 5 role, tanpa berulang) x 60 benih x 2
kursi (dibalik) = 1200. preset 3 pilihan (attack/balanced/defense), sp=12 (12 SP),
panjang=quick (P14 "Quick 2P").
S2 Arena 4P: 400 baris, role & preset per slot diundi bebas (4 kursi), sp=12.
S3 solo Lv20 2P (cermin K1): SAMA seperti S1 tapi lv_semua=20 (bukan preset_uji
manual -- lv_semua MENGALAHKAN preset_uji di uji_nyata.gd, jadi preset TIDAK
dikirim di sini, biar tidak membingungkan pembaca berkas tugas).
S4 solo Lv1 2P: sama S3 tapi lv_semua=1, 400 baris (4 pasangan pertama x 100? --
TIDAK, ikut rencana: 10 pasangan x 40 benih x 1 kursi = 400, kursi TIDAK dibalik
dua kali (bedanya dgn S1/S3 -- 400 vs 1200) supaya jumlah PERSIS 400 per K24).
S5 panjang: robot slot 0 (SEPERTI PATOKAN D7/K1 -- bukan semua_ai) TAPI build
Balanced Lv20 (Ultimate aktif) semua slot, lewat level_role=20 mode_build=balanced
+ role= paksa (bukan "role acak" lama) -- role_uji HARUS diisi, lain dari format
biasa "-" karena level_role= disyaratkan uji_nyata.gd (role_uji tidak boleh
kosong). Makanya kolom RL diisi "-" (supaya uji_seimbang.sh TIDAK memaksa
semua_ai=1) dan role=.. ditulis manual di kolom ekstra -- robot slot 0 (n_manusia
tetap 1, klik UI seperti biasa) TAPI ProfilPemain.xp_role/build_solo sudah
ditulis duluan (E0), jadi build slot 0 = build_solo(role0, {preset:balanced},20)
= Balanced Lv20 juga (build_solo baca simpanan preset, bukan _build_lv1). 80
pertandingan per jumlah pemain (2P/3P/4P) = 240 baris.
"""
import sys, random, itertools, os

ROLE = ["api", "air", "angin", "petir", "tanah"]
PRESET = ["attack", "balanced", "defense"]
MAPS = ["alam", "pantai"]

def tulis(path, baris):
    with open(path, "w") as f:
        f.write("\n".join(baris) + "\n")
    print(f"{path}: {len(baris)} baris")

def main():
    out = sys.argv[1] if len(sys.argv) > 1 else "."
    os.makedirs(out, exist_ok=True)
    benih = 5000

    # --- S1: Arena 2P, 10 pasangan x 60 benih x 2 kursi = 1200 ---
    s1 = []
    pasangan = list(itertools.combinations(ROLE, 2))  # 10 pasangan
    assert len(pasangan) == 10
    for (ra, rb) in pasangan:
        for i in range(60):
            for kursi, (r0, r1) in enumerate(((ra, rb), (rb, ra))):
                sd = benih; benih += 1
                rng = random.Random(sd)
                pa = rng.choice(PRESET); pb = rng.choice(PRESET)
                peta = MAPS[sd % 2]
                tag = f"u9s1_{ra}_{rb}_k{kursi}_{i}"
                s1.append(f"{tag} 1 {peta} {sd} quick {r0},{r1} preset={pa},{pb} sp=12")
    tulis(os.path.join(out, "s1.tugas"), s1)

    # --- S2: Arena 4P, 400 baris, role & preset 4 slot diundi bebas ---
    s2 = []
    for i in range(400):
        sd = benih; benih += 1
        rng = random.Random(sd)
        roles4 = [rng.choice(ROLE) for _ in range(4)]
        presets4 = [rng.choice(PRESET) for _ in range(4)]
        peta = MAPS[sd % 2]
        tag = f"u9s2_{i}"
        s2.append(f"{tag} 3 {peta} {sd} quick {','.join(roles4)} preset={','.join(presets4)} sp=12")
    tulis(os.path.join(out, "s2.tugas"), s2)

    # --- S3: solo Lv20 2P (cermin K1), 10 pasangan x 60 benih x 2 kursi = 1200 ---
    s3 = []
    for (ra, rb) in pasangan:
        for i in range(60):
            for kursi, (r0, r1) in enumerate(((ra, rb), (rb, ra))):
                sd = benih; benih += 1
                peta = MAPS[sd % 2]
                tag = f"u9s3_{ra}_{rb}_k{kursi}_{i}"
                s3.append(f"{tag} 1 {peta} {sd} quick {r0},{r1} lv_semua=20")
    tulis(os.path.join(out, "s3.tugas"), s3)

    # --- S4: solo Lv1 2P, 10 pasangan x 40 benih x 1 kursi = 400 (K24) ---
    s4 = []
    for (ra, rb) in pasangan:
        for i in range(40):
            sd = benih; benih += 1
            peta = MAPS[sd % 2]
            tag = f"u9s4_{ra}_{rb}_{i}"
            s4.append(f"{tag} 1 {peta} {sd} quick {ra},{rb} lv_semua=1")
    tulis(os.path.join(out, "s4.tugas"), s4)

    # --- S5: panjang, robot slot 0 seperti patokan, Balanced Lv20 semua slot ---
    # RL="-" (LIHAT komentar atas -- supaya uji_seimbang.sh TIDAK memaksa semua_ai=1),
    # role= ditulis manual di kolom ekstra + level_role=20 mode_build=balanced.
    s5 = []
    for n_lawan, label in ((1, "2p"), (2, "3p"), (3, "4p")):
        for i in range(80):
            sd = benih; benih += 1
            rng = random.Random(sd)
            roles_n = [rng.choice(ROLE) for _ in range(n_lawan + 1)]
            peta = MAPS[sd % 2]
            tag = f"u9s5_{label}_{i}"
            s5.append(f"{tag} {n_lawan} {peta} {sd} quick - role={','.join(roles_n)} level_role=20 mode_build=balanced")
    tulis(os.path.join(out, "s5.tugas"), s5)

    total = len(s1) + len(s2) + len(s3) + len(s4) + len(s5)
    # K24 (a) menulis "~3.450" (BULAT, bukan target persis) -- 1200+400+1200+400+240=3440
    # ADALAH jumlah yang benar per rincian S1-S5 di 14.19 sendiri.
    print(f"TOTAL={total} (S1={len(s1)} S2={len(s2)} S3={len(s3)} S4={len(s4)} S5={len(s5)}, cocok rincian K24 1200+400+1200+400+240=3440) benih_terakhir={benih-1}")

if __name__ == "__main__":
    main()
