extends Node
# Fase 5 G7 (rig-only): hadiah profil Tebak Duel -- 5 XP / 3 Crowns per tebakan benar, maks 5 per pertandingan,
# stat seumur memakai angka penuh, TIDAK ikut DOUBLE, tersimpan di berkas, bisa dimuat ulang.
# Jalankan: Godot --headless --path rig/proj_tanpa_uji res://uji_hadiah_tebak.tscn  (HOME sementara!)

var total := 0
var ok := 0
var gagal := 0

func cek(nama: String, syarat: bool, rinci: String = "") -> void:
	total += 1
	if syarat:
		ok += 1
	else:
		gagal += 1
	print("HADIAH_TEBAK_CEK %s status=%s %s" % [nama, "OK" if syarat else "GAGAL", rinci])

func _match(pp: Node, giliran: int, tebak: int, menang: bool = false, quick: bool = true) -> Dictionary:
	var st: Dictionary = pp.statistik_kosong()
	st["giliran"] = giliran
	st["tebak_benar"] = tebak
	return pp.catat_akhir_match({"menang": menang, "quick": quick, "multiplayer": false, "stat": st, "penghargaan": [], "role": ""})

func _ready() -> void:
	var pp = load("res://profil_pemain.gd").new()
	pp._ready() # profil baru (HOME sementara) -> id acak, simpan()
	cek("konstanta", pp.XP_PER_TEBAKAN == 5 and pp.CROWNS_PER_TEBAKAN == 3 and pp.TEBAK_MAKS_HADIAH == 5 and pp.STAT_SEUMUR.has("tebak_benar"))
	var seumur_total := 0
	# N tebakan benar -> (xp, crowns) yang diharapkan; 7 dibatasi 5, stat seumur tetap penuh (7).
	for kasus in [[0, 0, 0], [1, 5, 3], [3, 15, 9], [5, 25, 15], [7, 25, 15]]:
		var n: int = kasus[0]
		var xp_a = pp.xp_total
		var cr_a = pp.crowns
		var r: Dictionary = _match(pp, 10, n)
		seumur_total += n
		var xp_naik = pp.xp_total - xp_a
		var cr_naik = pp.crowns - cr_a
		var xp_harus = int(r["xp_match"]) + int(r["xp_penghargaan"]) + int(r["xp_misi"]) + int(r["xp_tebak"])
		var cr_harus = int(r["crowns_match"]) + int(r["crowns_penghargaan"]) + int(r["crowns_misi"]) + int(r["crowns_tebak"]) + int(r["crowns_naik_level"])
		cek("hadiah_n%d" % n, int(r["xp_tebak"]) == kasus[1] and int(r["crowns_tebak"]) == kasus[2] and int(r["tebak_benar"]) == n and int(r["tebak_dihitung"]) == mini(n, 5),
			"xp_tebak=%d crowns_tebak=%d dihitung=%d" % [int(r["xp_tebak"]), int(r["crowns_tebak"]), int(r["tebak_dihitung"])])
		cek("profil_naik_n%d" % n, xp_naik == xp_harus and cr_naik == cr_harus, "xp %d==%d cr %d==%d" % [xp_naik, xp_harus, cr_naik, cr_harus])
		cek("stat_seumur_n%d" % n, int(pp.statistik.get("tebak_benar", 0)) == seumur_total, "seumur=%d" % int(pp.statistik.get("tebak_benar", 0)))
	# DOUBLE: hanya xp_match + xp_penghargaan (+ crowns padanannya); tebakan TIDAK digandakan.
	var r2: Dictionary = _match(pp, 10, 4)
	var xp_b = pp.xp_total
	var cr_b = pp.crowns
	var berhasil = pp.tambah_double(r2)
	var xp_dobel_harus = int(r2["xp_match"]) + int(r2["xp_penghargaan"])
	cek("double_tanpa_tebak", berhasil and pp.xp_total - xp_b == xp_dobel_harus and int(r2["xp_double"]) == xp_dobel_harus and int(r2["xp_tebak"]) == 20 \
		and pp.crowns - cr_b >= int(r2["crowns_match"]) + int(r2["crowns_penghargaan"]) and int(r2["crowns_double"]) == int(r2["crowns_match"]) + int(r2["crowns_penghargaan"]),
		"xp_double=%d xp_tebak=%d" % [int(r2.get("xp_double", -1)), int(r2["xp_tebak"])])
	# Tanpa giliran (xp_match=0) tebakan benar tetap berhadiah tapi DOUBLE tidak ditawarkan.
	var r3: Dictionary = _match(pp, 0, 2)
	cek("bisa_double_tanpa_giliran", int(r3["xp_tebak"]) == 10 and not bool(r3["bisa_double"]), "bisa_double=%s" % str(r3["bisa_double"]))
	# Berkas: nilai tersimpan & bisa dimuat ulang.
	seumur_total += 4 + 2
	var baru = load("res://profil_pemain.gd").new()
	baru.muat()
	cek("muat_ulang", baru.xp_total == pp.xp_total and baru.crowns == pp.crowns and int(baru.statistik.get("tebak_benar", 0)) == seumur_total, "seumur=%d" % int(baru.statistik.get("tebak_benar", 0)))
	# Berkas LAMA (tanpa kunci tebak_benar di statistik) tetap bisa dihitung.
	var lama = load("res://profil_pemain.gd").new()
	lama._ready()
	lama.statistik.erase("tebak_benar")
	var r4: Dictionary = _match(lama, 5, 1)
	cek("berkas_lama", int(lama.statistik.get("tebak_benar", 0)) == 1 and int(r4["xp_tebak"]) == 5)
	# Statistik pertandingan TANPA kunci tebak_benar (pemain.gd lama / uji lama) -> 0 hadiah, tanpa error.
	var st_tanpa: Dictionary = pp.statistik_kosong()
	st_tanpa.erase("tebak_benar")
	st_tanpa["giliran"] = 3
	var r5: Dictionary = pp.catat_akhir_match({"menang": true, "quick": false, "stat": st_tanpa, "penghargaan": []})
	cek("stat_tanpa_kunci", int(r5["xp_tebak"]) == 0 and int(r5["crowns_tebak"]) == 0 and int(r5["tebak_benar"]) == 0)
	print("HADIAH_TEBAK_SELESAI total=%d ok=%d gagal=%d" % [total, ok, gagal])
	get_tree().quit()
