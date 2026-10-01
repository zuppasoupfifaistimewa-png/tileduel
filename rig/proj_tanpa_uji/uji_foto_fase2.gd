extends Node
# T7 (Fase 2): foto menu (bar profil, MISSIONS, popup login), PROFILE, MISI, dan layar akhir
# (2 & 4 pemain, kasus terberat: naik level + 3 misi + penghargaan, sesudah DOUBLE).
var awalan = "res://f2"

class Tiruan extends Node:
	# Pengganti pemain.gd untuk _panel_papan_skor (cukup data yang dibacanya).
	var mode_quick = true
	var slot_lokal = 0
	var daftar_pemain = []

func _ready():
	for a in OS.get_cmdline_user_args():
		if a.begins_with("foto="): awalan = a.substr(5)
	StatusJaringan.peran_multiplayer = ""
	var P = ProfilPemain
	P._tanggal_uji = "2026-10-01"
	P.nama = "Budi"
	P.xp_total = 260
	P.crowns = 340
	P.hari_login = 3
	P.tanggal_login = "2026-09-30"
	P.segarkan_hari()
	P.misi = [{"id": "main_match", "progres": 1, "selesai": false, "elemen": ""},
		{"id": "menang_duel", "progres": 2, "selesai": true, "elemen": ""},
		{"id": "duel_elemen", "progres": 0, "selesai": false, "elemen": "petir"}]
	P.statistik = {"match": 12, "menang": 5, "duel_menang": 9, "jebakan_pasang": 14, "petak_beli": 31, "permata": 6, "penghargaan": 7}
	P.simpan()
	var adegan = load("res://uji_panggung.tscn").instantiate()
	add_child(adegan)
	var menu = null
	for i in 30:
		await get_tree().process_frame
		for anak in adegan.get_node("Pemain").get_children():
			if anak.get_script() == preload("res://main_menu.gd"):
				menu = anak
		if menu != null:
			break
	for i in 20: await get_tree().process_frame
	await _foto("menu_login")
	_klik("LATER")
	for i in 10: await get_tree().process_frame
	await _foto("menu")
	UiProfil.buka_panel_profil(menu)
	for i in 10: await get_tree().process_frame
	await _foto("profil")
	for le in find_children("*", "LineEdit", true, false):
		le.text = "anjing"
	_klik("SAVE")
	for i in 5: await get_tree().process_frame
	await _foto("profil_salah")
	_klik("CLOSE")
	for i in 5: await get_tree().process_frame
	UiProfil.buka_panel_misi(menu)
	for i in 10: await get_tree().process_frame
	await _foto("misi")
	adegan.queue_free()
	for i in 5: await get_tree().process_frame

	# --- layar akhir 4 pemain, kasus terberat ---
	PengelolaIklan.uji_rewarded = true
	P.xp_total = 90
	P.misi = [{"id": "main_match", "progres": 1, "selesai": false, "elemen": ""},
		{"id": "menang_duel", "progres": 1, "selesai": false, "elemen": ""},
		{"id": "kena_jebakan", "progres": 1, "selesai": false, "elemen": ""}]
	P.tanggal_misi = P._hari_ini()
	var st = P.statistik_kosong()
	st["giliran"] = 5
	st["duel_menang"] = 2
	st["jebakan_kena"] = 2
	var r = P.catat_akhir_match({"menang": true, "quick": true, "multiplayer": false, "stat": st, "penghargaan": ["duel_king", "trap_master"]})
	var tiruan = Tiruan.new()
	tiruan.daftar_pemain = [0, 1, 2, 3]
	add_child(tiruan)
	var papan = [
		_baris(0, 4100, 6, 5, 1, ["duel_king", "trap_master"]),
		_baris(2, 3650, 5, 3, 1, ["landlord"]),
		_baris(1, 3200, 4, 6, 0, ["lucky_roller"]),
		_baris(3, 2150, 2, 2, 0, []),
	]
	UiDinamis._panel_papan_skor(tiruan, true, papan, r)
	for i in 70: await get_tree().process_frame
	await _foto("akhir_4p")
	_klik("WATCH AD: DOUBLE REWARDS")
	for i in 70: await get_tree().process_frame
	await _foto("akhir_4p_double")
	for c in get_children():
		if c is CanvasLayer:
			c.queue_free()
	for i in 5: await get_tree().process_frame

	# --- layar akhir 2 pemain, kalah, Classic ---
	tiruan.mode_quick = false
	tiruan.daftar_pemain = [0, 1]
	st = P.statistik_kosong()
	st["giliran"] = 11
	r = P.catat_akhir_match({"menang": false, "quick": false, "multiplayer": false, "stat": st, "penghargaan": []})
	papan = [_baris(1, 3100, 7, 4, 2, ["landlord", "duel_king"]), _baris(0, 1800, 3, 6, 1, ["lucky_roller"])]
	UiDinamis._panel_papan_skor(tiruan, false, papan, r)
	for i in 70: await get_tree().process_frame
	await _foto("akhir_2p")
	get_tree().quit()

func _baris(slot: int, uang: int, petak: int, bintang: int, permata: int, peng: Array) -> Dictionary:
	return {"slot": slot, "uang": uang, "bintang": bintang, "petak": petak, "permata": permata,
		"kekayaan": uang + petak * 300, "stat": ProfilPemain.statistik_kosong(), "penghargaan": peng}

func _klik(teks: String) -> void:
	for b in find_children("*", "Button", true, false):
		if b.text == teks and b.is_visible_in_tree() and not b.disabled:
			b.pressed.emit()
			return
	print("TOMBOL_TIDAK_ADA ", teks)

func _foto(nama: String) -> void:
	await RenderingServer.frame_post_draw
	var berkas = "%s_%s.png" % [awalan, nama]
	get_viewport().get_texture().get_image().save_png(berkas)
	print("FOTO ", berkas)
