extends Node
# Fase 7 G2 (rig-only): layar SHOP -- dibuka, ganti tab, BUY ditolak (Crowns/level), BUY berhasil, EQUIP, tombol di panel Profile & menu.
func _ready() -> void:
	var gagal := 0
	var P = ProfilPemain
	P.crowns = 200
	P.xp_total = 0
	P.kosmetik_dimiliki = []
	P.kosmetik_dipakai = {}
	UiToko.buka_toko(self)
	await get_tree().process_frame
	var kv = get_node_or_null("PanelToko")
	gagal += _cek("panel SHOP terbuka", kv != null)
	gagal += _cek("tab PAWN/TITLE/FRAME ada", _tombol(kv, "PAWN") != null and _tombol(kv, "TITLE") != null and _tombol(kv, "FRAME") != null)
	gagal += _cek("8 baris pawn (1 EQUIPPED)", _hitung(kv, "BUY") + _hitung(kv, "EQUIP") + _hitung(kv, "EQUIPPED") == 8 and _hitung(kv, "EQUIPPED") == 1)
	gagal += _cek("label Crowns/Lv", _ada_teks(kv, "CROWNS 200   |   Lv 1"))
	gagal += _cek("alasan 'Need 100 more Crowns' (Ocean 300)", _ada_teks(kv, "Need 100 more Crowns"))
	gagal += _cek("alasan 'Reach Lv 5' (Violet)", _ada_teks(kv, "Reach Lv 5"))
	# BUY pertama pada urutan = Shadow 150 (Crowns cukup)
	var buy = _tombol(kv, "BUY")
	buy.pressed.emit()
	await get_tree().process_frame
	await get_tree().process_frame
	gagal += _cek("beli Shadow: Crowns 50 & dipakai", P.crowns == 50 and P.kosmetik_pakai("pawn") == "pawn_shadow")
	gagal += _cek("label Crowns diperbarui", _ada_teks(kv, "CROWNS 50   |   Lv 1"))
	gagal += _cek("Shadow = EQUIPPED, Classic = EQUIP", _hitung(kv, "EQUIPPED") == 1 and _hitung(kv, "EQUIP") == 1)
	# EQUIP Classic
	_tombol(kv, "EQUIP").pressed.emit()
	await get_tree().process_frame
	await get_tree().process_frame
	gagal += _cek("EQUIP Classic -> bawaan", P.kosmetik_pakai("pawn") == "pawn_classic" and not P.kosmetik_dipakai.has("pawn"))
	# BUY terkunci (Ocean 300, Crowns 50): ditolak, pesan tampil
	var c0 = P.crowns
	_tombol(kv, "BUY").pressed.emit() # Shadow sudah dimiliki -> BUY pertama sekarang Ocean
	await get_tree().process_frame
	await get_tree().process_frame
	gagal += _cek("BUY kurang Crowns ditolak, Crowns tetap", P.crowns == c0 and P.kosmetik_dimiliki == ["pawn_shadow"])
	gagal += _cek("pesan penolakan tampil", _ada_teks(kv, "Need 250 more Crowns"))
	# tab TITLE & FRAME
	_tombol(kv, "TITLE").pressed.emit()
	await get_tree().process_frame
	await get_tree().process_frame
	gagal += _cek("tab TITLE 10 baris", _hitung(kv, "BUY") + _hitung(kv, "EQUIP") + _hitung(kv, "EQUIPPED") == 10 and _ada_teks(kv, "Tile Legend"))
	_tombol(kv, "FRAME").pressed.emit()
	await get_tree().process_frame
	await get_tree().process_frame
	gagal += _cek("tab FRAME 6 baris", _hitung(kv, "BUY") + _hitung(kv, "EQUIP") + _hitung(kv, "EQUIPPED") == 6 and _ada_teks(kv, "Royal"))
	# CLOSE
	_tombol(kv, "CLOSE").pressed.emit()
	await get_tree().process_frame
	await get_tree().process_frame
	gagal += _cek("CLOSE menutup panel", get_node_or_null("PanelToko") == null)
	# pratinjau semua barang dibuat tanpa error
	var ok_pratinjau := true
	for id_barang in DataKosmetik.KATALOG:
		if UiToko._pratinjau(id_barang) == null:
			ok_pratinjau = false
	gagal += _cek("pratinjau 24 barang", ok_pratinjau)
	# panel Profile punya tombol SHOP -> membuka toko
	var stub = GDScript.new()
	stub.source_code = "extends Control\nvar bar_profil = null\nvar tombol_misi = null\nvar tombol_toko = null\n"
	stub.reload()
	var menu = Control.new()
	menu.set_script(stub)
	add_child(menu)
	UiProfil.pasang_di_menu(menu)
	gagal += _cek("pasang_di_menu: tombol SHOP di menu", menu.tombol_toko != null and menu.tombol_toko.text == "SHOP")
	menu.tombol_toko.pressed.emit()
	await get_tree().process_frame
	gagal += _cek("tombol SHOP menu membuka toko", menu.get_node_or_null("PanelToko") != null)
	menu.get_node("PanelToko").free()
	UiProfil.buka_panel_profil(self)
	await get_tree().process_frame
	var tombol_shop: Button = null
	for k in get_children():
		if k is CanvasLayer and k.name != "PanelToko":
			tombol_shop = _tombol(k, "SHOP")
	gagal += _cek("panel Profile punya tombol SHOP", tombol_shop != null)
	if tombol_shop != null:
		tombol_shop.pressed.emit()
		await get_tree().process_frame
		gagal += _cek("SHOP dari Profile membuka toko", get_node_or_null("PanelToko") != null)
	gagal += _cek("teks lama 'unlock items soon' hilang", not _ada_teks(self, "Crowns will unlock items soon."))
	print("TOKO gagal=", gagal)
	get_tree().quit()

func _semua(n: Node, hasil: Array) -> Array:
	hasil.append(n)
	for k in n.get_children():
		if not k.is_queued_for_deletion():
			_semua(k, hasil)
	return hasil

func _tombol(akar: Node, teks: String) -> Button:
	for n in _semua(akar, []):
		if n is Button and n.text == teks:
			return n
	return null

func _hitung(akar: Node, teks: String) -> int:
	var j := 0
	for n in _semua(akar, []):
		if n is Button and n.text == teks:
			j += 1
	return j

func _ada_teks(akar: Node, teks: String) -> bool:
	for n in _semua(akar, []):
		if n is Label and n.text == teks:
			return true
	return false

func _cek(nama: String, ok: bool) -> int:
	print("TOKO ", "OK   " if ok else "GAGAL", " ", nama)
	return 0 if ok else 1
