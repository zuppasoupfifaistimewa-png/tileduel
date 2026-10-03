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
const NAMA_TAB := {"pawn": "PAWN", "title": "TITLE", "frame": "FRAME"}
const KETERANGAN := {
	"pawn": "Pawn colors tint your gloves and boots.",
	"title": "Titles show under your name.",
	"frame": "Frames decorate your profile card.",
}

static func buka_toko(induk: Node, tab: String = "pawn") -> void:
	if not is_instance_valid(induk) or not induk.is_inside_tree():
		return
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
	gulir.custom_minimum_size = Vector2(560, 330)
	gulir.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	isi.add_child(gulir)
	var daftar = VBoxContainer.new()
	daftar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	daftar.add_theme_constant_override("separation", 8)
	gulir.add_child(daftar)
	var lbl_pesan = UiProfil._label("", 18, MERAH)
	isi.add_child(lbl_pesan)
	var tutup = UiProfil._tombol("CLOSE", Color(0.6, 0.2, 0.2), Vector2(200, 52), 20)
	tutup.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	tutup.pressed.connect(kanvas.queue_free)
	isi.add_child(tutup)
	var keadaan = {"tab": tab if DataKosmetik.JENIS.has(tab) else "pawn"}
	# Lambda menangkap variabel per NILAI -> rujukan ke dirinya lewat Dictionary (keadaan["segarkan"]).
	keadaan["segarkan"] = func():
		lbl_crowns.text = "CROWNS %d   |   Lv %d" % [ProfilPemain.crowns, ProfilPemain.level_sekarang()]
		lbl_ket.text = str(KETERANGAN[keadaan["tab"]])
		for t in baris_tab.get_children():
			t.queue_free()
		for jenis in DataKosmetik.JENIS:
			var aktif = jenis == keadaan["tab"]
			var tb = UiProfil._tombol(str(NAMA_TAB[jenis]), Color(0.75, 0.55, 0.1) if aktif else Color(0.25, 0.25, 0.32), Vector2(150, 48), 20)
			tb.pressed.connect(func():
				keadaan["tab"] = jenis
				lbl_pesan.text = ""
				keadaan["segarkan"].call()
			)
			baris_tab.add_child(tb)
		for b in daftar.get_children():
			b.queue_free()
		for id_barang in DataKosmetik.daftar(str(keadaan["tab"])):
			daftar.add_child(_baris_barang(str(id_barang), lbl_pesan, keadaan["segarkan"]))
	keadaan["segarkan"].call()

static func _baris_barang(id_barang: String, lbl_pesan: Label, segarkan: Callable) -> Control:
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
	var alasan = "" if punya else ProfilPemain.alasan_tolak_beli(id_barang)
	var teks_info = "Owned" if punya else "%d Crowns" % int(b["harga"])
	if not punya and int(b["lv"]) > 0:
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
			var pesan = ProfilPemain.beli(id_barang)
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
