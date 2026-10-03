extends Node
# Fase 8 G2 (rig-only): bangun layar EVENT, tab EVENT di SHOP, MASTERY, kartu hadiah; hitung isi + tangkapan layar
# (perlu renderer: xvfb + opengl3) ke user://event_*.png. Tanpa renderer tetap jalan (cek isi saja).
func _ready() -> void:
	var gagal := 0
	var P = ProfilPemain
	P._tanggal_uji = "2026-09-14" # Fire Week
	P.crowns = 900
	P.xp_total = 600
	P.token_event = 70
	P.mastery = {"api": 40, "air": 5, "petir": 300}
	P.tanggal_maks = "" # autoload sudah memakai tanggal sistem saat start
	P.minggu_event = -1
	P.segarkan_event()
	P.misi_event[0]["progres"] = 3
	P.misi_event[1]["progres"] = 4
	P.misi_event[1]["selesai"] = true
	P.kosmetik_dimiliki = ["title_fire_master"]
	# EVENT
	UiEvent.buka_event(self)
	await _tunggu()
	var pe = get_node_or_null("PanelEvent")
	gagal += _cek("layar EVENT terbuka", pe != null)
	gagal += _cek("teks: nama event, TOKENS 70, EVENT SHOP", _ada_teks(pe, "FIRE WEEK") and _ada_teks(pe, "TOKENS 70") and _ada_teks(pe, "EVENT SHOP") and _ada_teks(pe, "Finish 5 matches as FIRE") and _ada_teks(pe, "3/5") and _ada_teks(pe, "DONE"))
	_foto("event")
	# tombol EVENT SHOP -> toko di tab EVENT
	_tekan(pe, "EVENT SHOP")
	await _tunggu()
	var pt = get_node_or_null("PanelToko")
	gagal += _cek("EVENT SHOP membuka toko tab EVENT (3 barang Fire)", pt != null and _ada_teks(pt, "Ember") and _ada_teks(pt, "Flame Heart") and _ada_teks(pt, "60 tokens") and _ada_teks(pt, "TOKENS 70") and not _ada_teks(pt, "Tide"))
	_foto("toko_event")
	# beli pawn_ember (60 token) lewat tombol BUY pertama
	_tekan(pt, "BUY")
	await _tunggu()
	gagal += _cek("beli lewat tombol: token 10, pawn_ember dipakai", P.token_event == 10 and P.kosmetik_pakai("pawn") == "pawn_ember")
	pt = get_node_or_null("PanelToko")
	gagal += _cek("barang jadi EQUIPPED, sisa BUY menampilkan alasan token", _ada_teks(pt, "EQUIPPED") and _ada_teks(pt, "Need 30 more tokens"))
	_foto("toko_event_beli")
	# tab TITLE: gelar mastery yang dimiliki tampil; tab PAWN: pawn_ember (event, dimiliki) tampil
	_tekan(pt, "TITLE")
	await _tunggu()
	pt = get_node_or_null("PanelToko")
	gagal += _cek("tab TITLE memuat gelar mastery yang dimiliki", _ada_teks(pt, "Fire Master") and _ada_teks(pt, "Owned (mastery)"))
	_tekan(pt, "PAWN")
	await _tunggu()
	pt = get_node_or_null("PanelToko")
	gagal += _cek("tab PAWN memuat pawn event yang dimiliki", _ada_teks(pt, "Ember") and _ada_teks(pt, "Owned (event)"))
	pt.free()
	# tanggal mundur
	P._tanggal_uji = "2026-09-01"
	UiToko.buka_toko(self, "event")
	await _tunggu()
	pt = get_node_or_null("PanelToko")
	gagal += _cek("tanggal mundur: tab EVENT menampilkan 'Event paused'", _ada_teks(pt, "Event paused: check your date"))
	pt.free()
	P._tanggal_uji = "2026-09-14"
	# MASTERY
	UiEvent.buka_mastery(self)
	await _tunggu()
	var pm = get_node_or_null("PanelMastery")
	gagal += _cek("layar MASTERY: 5 elemen, Lv api 5 (40 XP), petir MASTER", pm != null and _ada_teks(pm, "FIRE") and _ada_teks(pm, "WATER") and _ada_teks(pm, "LIGHTNING") and _ada_teks(pm, "Lv 5") and _ada_teks(pm, "MASTER"))
	_foto("mastery")
	pm.free()
	# kartu hadiah
	var r = {"level_awal": 1, "level_akhir": 1, "misi_selesai": [], "penghargaan": [], "tebak_dihitung": 0,
		"misi_event_selesai": [{"teks": "Win 2 matches as FIRE", "token": 40}],
		"mastery_naik": [{"elemen": "api", "level": 6, "crowns": 150, "gelar": ""}, {"elemen": "air", "level": 10, "crowns": 400, "gelar": "title_water_master"}]}
	var kotak = VBoxContainer.new()
	add_child(kotak)
	UiProfil._isi_baris_hadiah(kotak, r)
	await _tunggu()
	var teks_kartu = ""
	for l in kotak.get_children():
		teks_kartu += (l as Label).text + " | "
	print("EVENT_UI kartu: ", teks_kartu)
	gagal += _cek("kartu hadiah: misi event + mastery (maks 3 baris)", kotak.get_child_count() == 3 and teks_kartu.contains("EVENT MISSION DONE") and teks_kartu.contains("FIRE MASTERY Lv 6"))
	# menu: tombol EVENT lewat pasang_di_menu butuh main_menu penuh -> diuji lewat uji lain (cek_muat + solo smoke)
	P._tanggal_uji = ""
	print("EVENT_UI gagal=", gagal)
	get_tree().quit()

func _tunggu() -> void:
	for i in range(3):
		await get_tree().process_frame

func _foto(nama: String) -> void:
	var tex = get_viewport().get_texture()
	if tex != null and tex.get_image() != null:
		tex.get_image().save_png("user://event_%s.png" % nama)

func _semua(n: Node, hasil: Array) -> void:
	hasil.append(n)
	for a in n.get_children():
		_semua(a, hasil)

func _ada_teks(akar: Node, teks: String) -> bool:
	if akar == null:
		return false
	var ds = []
	_semua(akar, ds)
	for n in ds:
		if (n is Label or n is Button) and str(n.text).contains(teks):
			return true
	return false

func _tekan(akar: Node, teks: String) -> void:
	var ds = []
	_semua(akar, ds)
	for n in ds:
		if n is Button and str(n.text) == teks and not n.disabled:
			n.pressed.emit()
			return
	print("EVENT_UI tombol tidak ditemukan: ", teks)

func _cek(nama: String, ok: bool) -> int:
	print("EVENT_UI ", "OK   " if ok else "GAGAL", " ", nama)
	return 0 if ok else 1
