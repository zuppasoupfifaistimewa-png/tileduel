#!/usr/bin/env python3
"""Analisis pemain.gd untuk Fase 3: item tingkat atas, rujukan antar-item, dan
evaluasi pembagian file berlapis (pewarisan bertingkat)."""
import re, sys, json, itertools
from collections import defaultdict

SUMBER = "/home/claude/pemain.gd"
baris = open(SUMBER, encoding="utf-8").read().split("\n")
N = len(baris)

# ---------------------------------------------------------------- 1. item tingkat atas
# Item = deklarasi (var/const/signal/@onready/@export) atau fungsi. Rentang item
# mencakup komentar & anotasi yang menempel tepat di atasnya.
re_fungsi = re.compile(r'^(static )?func ([A-Za-z_0-9]+)\s*\(')
re_var = re.compile(r'^(?:@onready |@export )?(var|const|signal) ([A-Za-z_0-9]+)')
awal = []  # (baris 0-based, jenis, nama)
for i, b in enumerate(baris):
    m = re_fungsi.match(b)
    if m:
        awal.append((i, "func", m.group(2), bool(m.group(1))))
        continue
    m = re_var.match(b)
    if m:
        awal.append((i, m.group(1), m.group(2), False))

item = []
for k, (i, jenis, nama, statis) in enumerate(awal):
    # badan: sampai sebelum item berikutnya (atau akhir file)
    akhir = awal[k + 1][0] if k + 1 < len(awal) else N
    # mundurkan akhir: komentar/anotasi/kosong yang menempel pada item berikutnya
    j = akhir - 1
    while j > i and (baris[j].startswith("#") or baris[j].startswith("@") or baris[j].strip() == ""):
        j -= 1
    akhir_badan = j  # inklusif
    item.append({"i": i, "jenis": jenis, "nama": nama, "statis": statis, "akhir": akhir_badan})
# awal rentang = setelah akhir badan item sebelumnya (komentar di antaranya ikut item ini)
for k, it in enumerate(item):
    it["mulai"] = (item[k - 1]["akhir"] + 1) if k > 0 else 0

nama_fungsi = {it["nama"] for it in item if it["jenis"] == "func"}
nama_anggota = {it["nama"] for it in item}

# ---------------------------------------------------------------- 2. rujukan
def bersihkan(teks):
    # buang string & komentar (kasar tapi cukup untuk GDScript di file ini)
    hasil = []
    for b in teks.split("\n"):
        out = []
        dalam = None
        i = 0
        while i < len(b):
            c = b[i]
            if dalam:
                if c == "\\":
                    i += 2; continue
                if c == dalam:
                    dalam = None
                out.append(" ")
            else:
                if c == "#":
                    break
                if c in "\"'":
                    dalam = c
                    out.append(" ")
                else:
                    out.append(c)
            i += 1
        hasil.append("".join(out))
    return "\n".join(hasil)

def string_di(teks):
    return set(re.findall(r'"([A-Za-z_0-9]+)"', teks))

re_id = re.compile(r'(?<![A-Za-z_0-9\.\$])([A-Za-z_][A-Za-z_0-9]*)')
for it in item:
    teks = "\n".join(baris[it["i"]:it["akhir"] + 1])
    bersih = bersihkan(teks).replace("self.", "")
    ids = set(re_id.findall(bersih))
    ids.discard(it["nama"]) if it["jenis"] != "func" else None
    it["ref"] = sorted((ids & nama_anggota) - ({it["nama"]} if it["jenis"] == "func" else set()))
    # panggilan rekursif ke diri sendiri tidak dihitung
    it["await"] = sorted(set(re.findall(r'await\s+([A-Za-z_0-9]+)\s*\(', bersih)) & nama_fungsi)
    it["string"] = sorted(string_di(teks) & nama_fungsi)
    it["rpc_ann"] = any(baris[j].startswith("@rpc") for j in range(it["mulai"], it["i"]))
    it["panjang"] = it["akhir"] - it["mulai"] + 1

if __name__ == "__main__":
    json.dump(item, open("/tmp/claude-0/-home-claude/bc2a37a6-77d5-5593-942f-124ebd210f19/scratchpad/f3_item.json", "w"), indent=0)
    print("item", len(item), "fungsi", len(nama_fungsi), "deklarasi", len(item) - len(nama_fungsi))
    print("baris tercakup", sum(it["panjang"] for it in item), "dari", N)
