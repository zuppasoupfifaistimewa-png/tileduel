class_name UiToko
# ============================================================
# UI TOKO CROWNS (Fase 7 G2): layar SHOP -- tab Pawn / Title / Frame, harga, BUY / EQUIP, pratinjau.
# Semua fungsi static, dipanggil lewat nama kelas (UiToko.xxx). Data dari DataKosmetik + autoload ProfilPemain
# (beli/pakai/alasan_tolak_beli). Pola UiProfil. Teks untuk pemain: bahasa Inggris sederhana.
# ============================================================

const EMAS := Color(1.0, 0.85, 0.2)
const ABU := Color(0.75, 0.75, 0.8)
const HIJAU := Color(0.45, 0.95, 0.5)
const MERAH := Color(1.0, 0.45, 0.4)
const NAMA_TAB := {"pawn": "PAWN", "title": "TITLE", "frame": "FRAME", "event": "EVENT"}
const TAB := ["pawn", "title", "frame", "event"] # Fase 8: tab EVENT = barang event yang sedang berjalan (token)
const KETERANGAN := {
	"pawn": "Pawn colors tint your gloves and boots.",
	"title": "Titles show under your name.",
	"frame": "Frames decorate your profile card.",
	"event": "Buy with Event Tokens. Items return when the event comes back.",
}

static func buka_toko(induk: Node, tab: String = "pawn") -> void:
	if not is_instance_valid(induk) or not induk.is_inside_tree():
		return
	ProfilPemain.segarkan_event()
	var kanvas = UiProfil._layar_gelap(induk, 12)
	kanvas.name = "PanelToko"
	var isi = UiProfil._kartu_tengah(kanvas, true)
	isi.add_theme_constant_override("separation", 8)
	isi.add_child(UiProfil._label("SHOP", 32, EMAS))
	var lbl_crowns = UiProfil._label("", 24, EMAS)
	isi.add_child(lbl_crowns)
	var baris_tab = HBoxContainer.new()
	baris_tab.alignment = BoxContainer.ALIGNMENT_CENTER
	baris_tab.add_theme_constant_override("separation", 8)
	isi.add_child(baris_tab)
	var lbl_ket = UiProfil._label("", 16, ABU)
	isi.add_child(lbl_ket)
	var gulir = ScrollContainer.new()
	gulir.custom_minimum_size = Vector2(560, 260)
	gulir.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	isi.add_child(gulir)
	var daftar = VBoxContainer.new()
	daftar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	daftar.add_theme_constant_override("separation", 8)
	gulir.add_child(daftar)
	var kotak_iklan = VBoxContainer.new() # Fase 7 G4: baris Remove Ads (diisi ulang tiap segarkan)
	isi.add_child(kotak_iklan)
	var lbl_pesan = UiProfil._label("", 18, MERAH)
	isi.add_child(lbl_pesan)
	var tutup = UiProfil._tombol("CLOSE", Color(0.6, 0.2, 0.2), Vector2(200, 52), 20)
	tutup.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	tutup.pressed.connect(kanvas.queue_free)
	isi.add_child(tutup)
	var keadaan = {"tab": tab if TAB.has(tab) else "pawn"}
	# Lambda menangkap variabel per NILAI -> rujukan ke dirinya lewat Dictionary (keadaan["segarkan"]).
	keadaan["segarkan"] = func():
		lbl_pesan.add_theme_color_override("font_color", HIJAU if bool(lbl_pesan.get_meta("ok", false)) else MERAH) # pesan sukses (Remove Ads) hijau, sisanya merah
		lbl_pesan.set_meta("ok", false)
		lbl_crowns.text = "CROWNS %d   |   Lv %d" % [ProfilPemain.crowns, ProfilPemain.level_sekarang()]
		if keadaan["tab"] == "event":
			lbl_crowns.text = "TOKENS %d" % ProfilPemain.token_event
		lbl_ket.text = str(KETERANGAN[keadaan["tab"]])
		if keadaan["tab"] == "event":
			lbl_ket.text = "%s: %s" % [str(ProfilPemain.event_sekarang()["nama"]), "Event paused: check your date" if ProfilPemain.tanggal_mundur() else UiEvent.teks_sisa_sekarang()]
		for t in baris_tab.get_children():
			t.queue_free()
		for jenis in TAB:
			var aktif = jenis == keadaan["tab"]
			var tb = UiProfil._tombol(str(NAMA_TAB[jenis]), Color(0.75, 0.55, 0.1) if aktif else Color(0.25, 0.25, 0.32), Vector2(120, 48), 20)
			tb.pressed.connect(func():
				keadaan["tab"] = jenis
				lbl_pesan.text = ""
				keadaan["segarkan"].call()
			)
			baris_tab.add_child(tb)
		for b in daftar.get_children():
			b.queue_free()
		for id_barang in _isi_tab(str(keadaan["tab"])):
			daftar.add_child(_baris_barang(str(id_barang), lbl_pesan, keadaan["segarkan"], keadaan["tab"] == "event"))
		for b in kotak_iklan.get_children():
			b.queue_free()
		var baris_iklan = _baris_remove_ads(kanvas, lbl_pesan, keadaan["segarkan"])
		if baris_iklan != null:
			kotak_iklan.add_child(baris_iklan)
	keadaan["segarkan"].call()
	var pp = _pengelola_pembelian()
	if pp != null: # status berubah dari luar (restore selesai, refund) -> gambar ulang selagi panel terbuka
		var saat_berubah = func(_punya):
			if is_instance_valid(kanvas):
				keadaan["segarkan"].call()
		pp.status_berubah.connect(saat_berubah)
		kanvas.tree_exiting.connect(func():
			if pp.status_berubah.is_connected(saat_berubah):
				pp.status_berubah.disconnect(saat_berubah)
		)

static func _isi_tab(tab: String) -> Array:
	# Tab Pawn/Title/Frame: barang toko Crowns + barang event/mastery yang SUDAH dimiliki (supaya bisa dipakai).
	# Tab Event: 3 barang event yang sedang berjalan.
	if tab == "event":
		return DataKosmetik.daftar_event(str(ProfilPemain.event_sekarang()["id"]))
	var hasil = DataKosmetik.daftar(tab)
	for sumber in ["event", "mastery"]:
		for id_barang in DataKosmetik.daftar(tab, sumber):
			if ProfilPemain.punya_kosmetik(str(id_barang)):
				hasil.append(id_barang)
	return hasil

static func _pengelola_pembelian() -> Node:
	# Lewat pohon (bukan nama autoload) supaya layar toko tetap termuat walau autoload belum didaftarkan -> baris Remove Ads hilang saja.
	var pohon = Engine.get_main_loop() as SceneTree
	return pohon.root.get_node_or_null("PengelolaPembelian") if pohon != null else null

static func _baris_remove_ads(kanvas: Node, lbl_pesan: Label, segarkan: Callable) -> Control:
	var pp = _pengelola_pembelian()
	if pp == null:
		return null
	var punya: bool = pp.punya_remove_ads()
	var kartu = PanelContainer.new()
	kartu.name = "BarisRemoveAds"
	kartu.add_theme_stylebox_override("panel", _gaya_baris(punya))
	var baris = HBoxContainer.new()
	baris.add_theme_constant_override("separation", 10)
	kartu.add_child(baris)
	var kiri = VBoxContainer.new()
	kiri.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	kiri.alignment = BoxContainer.ALIGNMENT_CENTER
	baris.add_child(kiri)
	var l_nama = UiProfil._label("REMOVE ADS", 20, EMAS if punya else Color.WHITE)
	l_nama.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	kiri.add_child(l_nama)
	var l_info = UiProfil._label("Ads removed. Thank you!" if punya else "No banners or match-end ads. +500 Crowns!", 14, HIJAU if punya else ABU)
	l_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	kiri.add_child(l_info)
	if punya:
		return kartu
	var harga: String = pp.harga_remove_ads()
	var beli = UiProfil._tombol("BUY " + harga if harga != "" else "BUY", Color(0.15, 0.55, 0.25), Vector2(150, 50), 18)
	beli.pressed.connect(func():
		lbl_pesan.text = ""
		beli.disabled = true
		var saat_selesai = func(ok, pesan):
			if is_instance_valid(kanvas):
				lbl_pesan.text = str(pesan)
				lbl_pesan.set_meta("ok", ok)
				segarkan.call()
		pp.pembelian_selesai.connect(saat_selesai, CONNECT_ONE_SHOT)
		pp.beli_remove_ads()
	)
	baris.add_child(beli)
	var pulih = UiProfil._tombol("RESTORE", Color(0.25, 0.25, 0.32), Vector2(110, 50), 16)
	pulih.pressed.connect(func():
		lbl_pesan.text = ""
		pp.restore()
	)
	baris.add_child(pulih)
	return kartu

static func _baris_barang(id_barang: String, lbl_pesan: Label, segarkan: Callable, event: bool = false) -> Control:
	var b: Dictionary = DataKosmetik.KATALOG[id_barang]
	var jenis = str(b["jenis"])
	var punya = ProfilPemain.punya_kosmetik(id_barang)
	var dipakai = ProfilPemain.kosmetik_pakai(jenis) == id_barang
	var kartu = PanelContainer.new()
	kartu.add_theme_stylebox_override("panel", _gaya_baris(dipakai))
	var baris = HBoxContainer.new()
	baris.add_theme_constant_override("separation", 12)
	kartu.add_child(baris)
	var prat = _pratinjau(id_barang)
	prat.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	baris.add_child(prat)
	var kiri = VBoxContainer.new()
	kiri.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	kiri.alignment = BoxContainer.ALIGNMENT_CENTER
	baris.add_child(kiri)
	var l_nama = UiProfil._label(str(b["nama"]), 22, EMAS if dipakai else Color.WHITE)
	l_nama.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	kiri.add_child(l_nama)
	var alasan = "" if punya else (ProfilPemain.alasan_tolak_beli_event(id_barang) if event else ProfilPemain.alasan_tolak_beli(id_barang))
	var teks_info = "Owned" if punya else ("%d tokens" % int(b["token"]) if event else "%d Crowns" % int(b["harga"]))
	if punya and not event and DataKosmetik.sumber_dari(id_barang) != "":
		teks_info = "Owned (%s)" % ("event" if DataKosmetik.sumber_dari(id_barang) == "event" else "mastery")
	if not punya and not event and int(b["lv"]) > 0:
		teks_info += "  (Lv %d)" % int(b["lv"])
	var l_info = UiProfil._label(teks_info, 16, HIJAU if punya else ABU)
	l_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	kiri.add_child(l_info)
	var tombol: Button
	if dipakai:
		tombol = UiProfil._tombol("EQUIPPED", Color(0.3, 0.3, 0.35), Vector2(150, 50), 18)
		tombol.disabled = true
	elif punya:
		tombol = UiProfil._tombol("EQUIP", Color(0.2, 0.45, 0.75), Vector2(150, 50), 18)
		tombol.pressed.connect(func():
			ProfilPemain.pakai(id_barang)
			lbl_pesan.text = ""
			segarkan.call()
		)
	else:
		# Terkunci (level/Crowns kurang) tetap terlihat sebagai tujuan; ketukan menampilkan alasannya.
		tombol = UiProfil._tombol("BUY", Color(0.15, 0.55, 0.25) if alasan == "" else Color(0.35, 0.35, 0.4), Vector2(150, 50), 18)
		tombol.pressed.connect(func():
			var pesan = ProfilPemain.beli_event(id_barang) if event else ProfilPemain.beli(id_barang)
			if pesan == "":
				lbl_pesan.text = ""
			else:
				lbl_pesan.text = pesan
			segarkan.call()
		)
	baris.add_child(tombol)
	if alasan != "":
		var l_alasan = UiProfil._label(alasan, 14, MERAH)
		kiri.add_child(l_alasan)
		l_alasan.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	return kartu

static func _gaya_baris(dipakai: bool) -> StyleBoxFlat:
	var g = StyleBoxFlat.new()
	g.bg_color = Color(0.12, 0.12, 0.18, 0.95)
	g.set_corner_radius_all(10)
	g.set_border_width_all(2 if dipakai else 1)
	g.border_color = EMAS if dipakai else Color(0.3, 0.3, 0.38)
	g.content_margin_left = 10
	g.content_margin_right = 10
	g.content_margin_top = 6
	g.content_margin_bottom = 6
	return g

static func _pratinjau(id_barang: String) -> Control:
	# Kotak kecil 64x64: pawn = lingkaran warna trim (+ kilau); title = ikon "T"; frame = kotak berbingkai seperti di kartu profil.
	var b: Dictionary = DataKosmetik.KATALOG[id_barang]
	var kotak = PanelContainer.new()
	kotak.custom_minimum_size = Vector2(64, 64)
	var g = StyleBoxFlat.new()
	g.bg_color = Color(0.07, 0.07, 0.11) if str(b["jenis"]) == "frame" else Color(0.45, 0.45, 0.52) # pawn gelap (Shadow) tetap terlihat
	g.set_corner_radius_all(10)
	match str(b["jenis"]):
		"pawn":
			var warna: Color = b.get("warna", Color(0.9, 0.9, 0.9))
			var bulat = StyleBoxFlat.new()
			bulat.bg_color = warna
			bulat.set_corner_radius_all(20)
			bulat.set_border_width_all(2)
			bulat.border_color = warna.lightened(0.4) if float(b.get("emisi", 0.0)) > 0.0 or float(b.get("logam", 0.0)) > 0.0 else warna.darkened(0.3)
			if float(b.get("emisi", 0.0)) > 0.0:
				bulat.shadow_color = Color(warna, 0.6)
				bulat.shadow_size = 8
			var titik = Panel.new()
			titik.custom_minimum_size = Vector2(40, 40)
			titik.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			titik.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			titik.add_theme_stylebox_override("panel", bulat)
			kotak.add_child(titik)
		"title":
			var l = UiProfil._label("Aa", 24, EMAS)
			l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			kotak.add_child(l)
		"frame":
			if b.has("border"):
				g.border_color = b["border"]
				g.set_border_width_all(int(b["lebar"]))
				g.set_corner_radius_all(10 + int(b.get("radius_tambah", 0)))
				if b.has("bayangan"):
					g.shadow_color = b["bayangan"]
					g.shadow_size = int(b["bayangan_ukuran"])
			else:
				g.set_border_width_all(2)
				g.border_color = EMAS
	kotak.add_theme_stylebox_override("panel", g)
	return kotak
