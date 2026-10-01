#!/usr/bin/env python3
"""F0 (B-f, 14.19, T18): cek fungsi yatim -- fungsi yang didefinisikan di salah satu
berkas TARGET (pemain_role.gd/data_role.gd/ai_jebakan.gd/ai_musuh.gd/ui_role.gd/
pemain_tampilan.gd) tapi TIDAK dipanggil dari berkas PRODUKSI mana pun (termasuk
dari berkas TARGET itu sendiri). Harus KOSONG -- pengecualian (Godot lifecycle,
dipanggil lewat sinyal/reflection, dsb) diberi tanda + alasan di PENGECUALIAN.
Pakai: cek_panggil.py [dir_produksi (bawaan /home/claude)]
"""
import sys, re, os, glob

TARGET = ["pemain_role.gd", "data_role.gd", "ai_jebakan.gd", "ai_musuh.gd", "ui_role.gd", "pemain_tampilan.gd"]

# Nama fungsi yang SENGAJA tidak dipanggil langsung lewat nama di GDScript --
# dipanggil MESIN Godot (lifecycle/override virtual) atau lewat jalur lain
# (get()/set() dinamis, callable lewat sinyal connect(), dsb). Format:
# nama -> alasan.
PENGECUALIAN = {
    "_ready": "lifecycle Godot (dipanggil mesin saat node masuk pohon)",
    "_process": "lifecycle Godot (dipanggil mesin tiap frame)",
    "_physics_process": "lifecycle Godot (dipanggil mesin tiap frame fisika)",
    "_init": "lifecycle Godot (dipanggil mesin saat objek dibuat / .new())",
    "_enter_tree": "lifecycle Godot",
    "_exit_tree": "lifecycle Godot",
    "_input": "lifecycle Godot (event input)",
    "_unhandled_input": "lifecycle Godot (event input)",
    "_notification": "lifecycle Godot",
    "_to_string": "lifecycle Godot (str()/print() otomatis)",
    "_get_configuration_warnings": "lifecycle editor Godot",
    "_draw": "lifecycle Godot (CanvasItem)",
}

DEF_RE = re.compile(r"^\s*(?:static\s+)?func\s+(\w+)\s*\(", re.MULTILINE)

def baca(path):
    with open(path, encoding="utf-8") as f:
        return f.read()

def main():
    dir_prod = sys.argv[1] if len(sys.argv) > 1 else "/home/claude"
    semua_gd = sorted(glob.glob(os.path.join(dir_prod, "*.gd")))
    if not semua_gd:
        print(f"CEK_PANGGIL_GAGAL: tidak ada .gd di {dir_prod}")
        sys.exit(1)
    isi = {p: baca(p) for p in semua_gd}
    gabung = "\n".join(isi.values())

    yatim = []
    diperiksa = 0
    for nama_berkas in TARGET:
        path = os.path.join(dir_prod, nama_berkas)
        if path not in isi:
            print(f"CEK_PANGGIL_GAGAL: {nama_berkas} tidak ditemukan di {dir_prod}")
            sys.exit(1)
        for m in DEF_RE.finditer(isi[path]):
            nama = m.group(1)
            diperiksa += 1
            if nama in PENGECUALIAN:
                continue
            # Hitung SEMUA kemunculan "nama(" (word boundary) di SELURUH produksi,
            # lalu kurangi jumlah baris DEFINISI (func nama( / static func nama() --
            # bisa >1 kalau nama dipakai ulang di berkas rantai pemain lain (override
            # sah, bukan yatim, tapi CUKUP salah satu punya pemanggil).
            semua = len(re.findall(r"\b" + re.escape(nama) + r"\s*\(", gabung))
            n_def = len(re.findall(r"^\s*(?:static\s+)?func\s+" + re.escape(nama) + r"\s*\(", gabung, re.MULTILINE))
            if semua - n_def <= 0:
                yatim.append((nama_berkas, nama))
    print(f"CEK_PANGGIL diperiksa={diperiksa} berkas_target={len(TARGET)} pengecualian={len(PENGECUALIAN)}")
    if yatim:
        for berkas, nama in yatim:
            print(f"  YATIM {berkas}::{nama}")
        print(f"CEK_PANGGIL_SELESAI status=GAGAL yatim={len(yatim)}")
        sys.exit(1)
    print("CEK_PANGGIL_SELESAI status=OK yatim=0")

if __name__ == "__main__":
    main()
