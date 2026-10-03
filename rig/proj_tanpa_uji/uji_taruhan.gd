extends Node
# Fase 9 G0 (rig-only): misi harian Tebak Duel + taruhan Crowns. Jalankan: Godot --headless --path rig/proj_tanpa_uji res://uji_taruhan.tscn (HOME sementara!)
var total := 0
var ok := 0
var gagal := 0

func cek(nama: String, syarat: bool, rinci: String = "") -> void:
	total += 1
	if syarat:
		ok += 1
	else:
		gagal += 1
	print("TARUHAN_CEK %s status=%s %s" % [nama, "OK" if syarat else "GAGAL", rinci])

func _ready() -> void:
	var P = load("res://profil_pemain.gd").new()
	P._ready()
	P._tanggal_uji = "2026-09-14"
	cek("versi", P.VERSI == 6 and P.MISI.has("tebak_tiga") and P.MISI.has("tebak_beruntun"))
	# --- taruhan ---
	P.crowns = 100
	cek("ditolak_nominal", P.pasang_taruhan(7) != "" and P.crowns == 100)
	cek("pasang_benar", P.pasang_taruhan(25) == "" and P.crowns == 75 and P.taruhan_hari_ini() == 1)
	cek("ditolak_ganda", P.pasang_taruhan(10) != "" and P.crowns == 75)
	cek("selesai_benar", P.selesai_taruhan(true) == 25 and P.crowns == 125)
	cek("pasang_salah", P.pasang_taruhan(50) == "" and P.selesai_taruhan(false) == -50 and P.crowns == 75)
	cek("tanpa_taruhan_nol", P.selesai_taruhan(true) == 0 and P.crowns == 75)
	P.pasang_taruhan(10)
	P.batal_taruhan()
	cek("batal_penuh", P.crowns == 75 and P.taruhan_hari_ini() == 2)
	# saldo tidak pernah negatif / kurang saldo
	P.crowns = 9
	cek("kurang_saldo", P.pasang_taruhan(10) != "" and P.crowns == 9)
	P.crowns = 50
	cek("pas_saldo", P.pasang_taruhan(50) == "" and P.crowns == 0)
	P.selesai_taruhan(false)
	cek("saldo_nol_ok", P.crowns == 0 and P.pasang_taruhan(10) != "")
	# batas harian 10
	P.crowns = 1000
	P.taruhan_jumlah = 0
	var berhasil := 0
	for i in range(14):
		if P.pasang_taruhan(10) == "":
			berhasil += 1
			P.selesai_taruhan(false)
		if P.crowns < 0:
			cek("tidak_negatif", false)
	cek("batas_harian_10", berhasil == 10 and P.crowns == 900, "berhasil=%d crowns=%d" % [berhasil, P.crowns])
	P._tanggal_uji = "2026-09-15"
	cek("hari_baru_reset", P.taruhan_hari_ini() == 0 and P.pasang_taruhan(10) == "" and P.taruhan_jumlah == 1)
	P.selesai_taruhan(true)
	# simpan-muat
	var P2 = load("res://profil_pemain.gd").new()
	P2._tanggal_uji = "2026-09-15"
	P2.muat()
	cek("muat_ulang", P2.taruhan_jumlah == 1 and P2.taruhan_hari == "2026-09-15" and P2.crowns == P.crowns, "%d/%d" % [P2.crowns, P.crowns])
	# --- misi ---
	var st: Dictionary = P.statistik_kosong()
	cek("stat_kunci", st.has("tebak_beruntun") and st["tebak_beruntun"] == 0)
	P.tanggal_misi = P._hari_ini() # supaya segarkan_hari tidak mengganti misi uji
	P.misi = [{"id": "tebak_tiga", "progres": 0, "selesai": false, "elemen": ""}, {"id": "tebak_beruntun", "progres": 0, "selesai": false, "elemen": ""}, {"id": "main_match", "progres": 0, "selesai": false, "elemen": ""}]
	st["giliran"] = 5
	st["tebak_benar"] = 2
	st["tebak_beruntun"] = 1
	P.catat_akhir_match({"menang": false, "quick": true, "stat": st, "penghargaan": [], "role": ""})
	cek("misi_tebak3_2", int(P.misi[0]["progres"]) == 2 and not bool(P.misi[0]["selesai"]))
	cek("beruntun_1_belum", int(P.misi[1]["progres"]) == 1 and not bool(P.misi[1]["selesai"]))
	st["tebak_benar"] = 1
	st["tebak_beruntun"] = 1
	var cr0 = P.crowns
	var r = P.catat_akhir_match({"menang": false, "quick": true, "stat": st, "penghargaan": [], "role": ""})
	cek("tebak3_selesai", bool(P.misi[0]["selesai"]) and r["misi_selesai"].size() >= 1)
	cek("beruntun_bukan_jumlah", int(P.misi[1]["progres"]) == 1 and not bool(P.misi[1]["selesai"]), "dua laga streak 1 tidak boleh = 2")
	st["tebak_beruntun"] = 2
	P.catat_akhir_match({"menang": false, "quick": true, "stat": st, "penghargaan": [], "role": ""})
	cek("beruntun_2_selesai", bool(P.misi[1]["selesai"]))
	# bobot: misi tebak jarang muncul, pool tidak merusak tingkat
	var hitung := {"tebak_tiga": 0, "tebak_beruntun": 0}
	var tebak_t1 := 0
	var tebak_t2 := 0
	for i in range(600):
		var m1 = P._misi_baru(1, [])
		var m2 = P._misi_baru(2, [])
		if m1["id"] == "tebak_tiga": tebak_t1 += 1
		if m2["id"] == "tebak_beruntun": tebak_t2 += 1
	cek("bobot_rendah", tebak_t1 > 20 and tebak_t1 < 120 and tebak_t2 > 20 and tebak_t2 < 150, "t1=%d/600 t2=%d/600" % [tebak_t1, tebak_t2])
	# berkas VERSI 5 lama (tanpa bagian tebak) dimuat -> taruhan 0
	var c := ConfigFile.new()
	c.load(P.BERKAS)
	if c.has_section("tebak"):
		c.erase_section("tebak")
	c.save(P.BERKAS)
	var P3 = load("res://profil_pemain.gd").new()
	P3.muat()
	cek("berkas_lama", P3.taruhan_jumlah == 0 and P3.taruhan_hari == "" and P3.crowns == P.crowns)
	print("TARUHAN_SELESAI total=%d ok=%d gagal=%d" % [total, ok, gagal])
	get_tree().quit()
