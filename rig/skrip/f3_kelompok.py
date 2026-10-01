#!/usr/bin/env python3
"""Kelompok fungsi pemain.gd -> file, lalu evaluasi urutan lapis."""
import json, itertools, sys
from collections import defaultdict

SP = "/tmp/claude-0/-home-claude/bc2a37a6-77d5-5593-942f-124ebd210f19/scratchpad"
item = json.load(open(SP + "/f3_item.json"))
per_nama = {it["nama"]: it for it in item}
fungsi = [it for it in item if it["jenis"] == "func"]

def rentang(a, b):
    # fungsi yang baris 'func'-nya (1-based) di [a, b]
    return [f["nama"] for f in fungsi if a <= f["i"] + 1 <= b]

K = {}
def taruh(grup, nama_list):
    for n in nama_list:
        if n not in per_nama or per_nama[n]["jenis"] != "func":
            sys.exit("tidak ada fungsi " + n)
        K[n] = grup

taruh("dasar", rentang(456, 610))                   # pembantu slot + teks sudut pandang
taruh("dasar", ["_peer_slot", "_peer_client_aktif", "_rpc_ke_klien_kecuali", "_slot_dari_peer",
                "_umumkan", "rpc_umumkan", "_teks_narasi",
                "_reset_statistik", "_tambah_stat", "_tambah_stat_elemen"])
taruh("tampilan", ["_pemanasan_shader", "_pemanasan_permata", "_pemanasan_jebakan_api",
                   "_jalankan_auto_detect_pertama", "_munculkan_teks_paralysis", "_munculkan_teks_kerugian",
                   "_bangun_fisik_menara", "update_semua_label_petak", "_atur_posisi_label_ronde",
                   "_perbarui_label_ronde", "update_ui_status", "_render_uang_tampil",
                   "_render_hud_banyak_pemain", "atur_posisi_berbagi_petak", "atur_visibilitas_fps",
                   "_warnai_karakter"])
taruh("jaringan", rentang(817, 1172))
taruh("jaringan", rentang(1783, 1828))
taruh("jaringan", ["_siarkan_state_giliran", "rpc_terima_state_giliran", "_sembunyikan_menu_giliran_lawan",
                   "_tunggu_langkah_ke_petak", "_antrian_berisi_petak", "rpc_mainkan_rolet",
                   "rpc_langkah_client", "_proses_antrian_langkah", "_langkah_satu_petak",
                   "_selaraskan_efek_menempel", "_bangun_ulang_menara_client",
                   "_teruskan_aksi_ke_host", "rpc_minta_aksi", "_siarkan_state_ai"])
for n in ["_peer_slot", "_peer_client_aktif", "_rpc_ke_klien_kecuali", "_slot_dari_peer"]:
    K[n] = "dasar"
taruh("migrasi", rentang(1173, 1653))
taruh("papan", ["_atur_berhenti_petak", "_catat_berhenti_di_petak",
                "_on_tombol_tanah_pressed", "_on_tombol_trap_tanah_pressed", "_on_tombol_petir_pressed",
                "_on_tombol_set_trap_pressed", "_on_tombol_trap_batal_pressed"])
taruh("papan", rentang(2706, 2969))                  # sinkron jebakan, koin tercecer, permata, start
taruh("papan", ["rpc_mainkan_efek_jebakan", "rpc_mainkan_efek_sisa_paralisis", "rpc_jebakan_air_aktif"])
taruh("papan", rentang(3980, 4151))                  # tombol beli/bangun/serang/jebakan
taruh("papan", rentang(4178, 4471))                  # serang jarak jauh, jual aset, reset petak
taruh("papan", ["_tawarkan_iklan_hutang", "_bayar_denda", "bayar_denda_ke_musuh", "bayar_denda_ke_pemain",
                "sita_aset_untuk_hutang", "_ai_jual_sampai_lunas", "_ambil_permata_setelah_paralisis",
                "_siarkan_pesan_denda", "rpc_pesan_denda", "_siarkan_kondisi_petak", "rpc_kondisi_petak",
                "_siarkan_teks_kerugian", "rpc_teks_kerugian"])
taruh("kartu", ["_tonton_iklan_kartu_awal", "_kartu_hadiah_acak"])
taruh("kartu", rentang(5488, 5500))
taruh("kartu", rentang(5520, 5690))
taruh("kartu", rentang(5719, 5869))
taruh("kartu", rentang(5960, 6141))
taruh("duel", rentang(3439, 3932))
taruh("duel", ["eksekusi_dadu_pertarungan", "_hasil_duel_petak", "hasil_akhir_pertarungan_pemain",
               "hasil_akhir_pertarungan_musuh", "_siarkan_jebakan_tanah_aktif", "rpc_jebakan_tanah_aktif"])
taruh("pokok", ["_ready", "_process", "_mulai_transisi_game", "_baris_syarat_menang", "_teks_syarat_permata",
                "_teks_gaji_gagal", "_unhandled_input", "_boleh_geser_kamera", "lempar_dadu", "bergerak_maju",
                "_akhiri_permainan", "_susun_papan_skor", "_tampilkan_akhir_permainan", "rpc_permainan_selesai",
                "periksa_status_petak", "_on_tombol_tutup_pressed", "_proses_tombol_tutup",
                "ganti_giliran", "_mulai_giliran", "cek_game_over", "_atur_kecepatan_permainan",
                "_jumlah_petak_slot", "_kekayaan_slot", "_pemenang_kekayaan", "_akhiri_karena_ronde_habis",
                "_proses_hadiah_akhir", "_data_akhir_profil", "_siapkan_peta_dan_mulai"])
taruh("pokok", rentang(2970, 3064))                  # cabang (pilih arah) -- bagian dari melangkah

sisa = [f["nama"] for f in fungsi if f["nama"] not in K]
if sisa:
    print("BELUM DIKELOMPOKKAN:", sisa)

def evaluasi(urutan, cetak=False):
    lapis = {g: k for k, g in enumerate(urutan)}
    naik = defaultdict(set)        # fungsi yang dirujuk dari lapis lebih rendah -> perlu deklarasi
    naik_await = defaultdict(set)
    tepi_naik = 0
    for f in fungsi:
        gf = lapis[K[f["nama"]]]
        for r in f["ref"]:
            if r in K and lapis[K[r]] > gf:
                naik[r].add(f["nama"])
                tepi_naik += 1
        for r in f["await"]:
            if r in K and lapis[K[r]] > gf:
                naik_await[r].add(f["nama"])
    return len(naik), tepi_naik, len(naik_await), naik, naik_await

if __name__ == "__main__":
    grup = ["dasar", "tampilan", "jaringan", "migrasi", "papan", "kartu", "duel", "pokok"]
    baris_grup = defaultdict(int)
    for f in fungsi:
        baris_grup[K[f["nama"]]] += f["panjang"]
    print({g: baris_grup[g] for g in grup})
    tengah = [g for g in grup if g not in ("dasar", "pokok")]
    hasil = []
    for p in itertools.permutations(tengah):
        urutan = ["dasar"] + list(p) + ["pokok"]
        n, t, a, _, _ = evaluasi(urutan)
        hasil.append((n, a, t, urutan))
    hasil.sort()
    for h in hasil[:12]:
        print(h)
    json.dump(K, open(SP + "/f3_K.json", "w"), indent=0)
