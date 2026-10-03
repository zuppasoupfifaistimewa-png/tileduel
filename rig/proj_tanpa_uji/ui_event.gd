class_name UiEvent
# ============================================================
# UI EVENT MINGGUAN + MASTERY (Fase 8 G2): layar EVENT (3 misi, token, sisa waktu, tombol EVENT SHOP) dan layar MASTERY
# (5 elemen: level, bilah XP). Semua static (UiEvent.xxx). Data dari DataEvent + autoload ProfilPemain. Pola UiToko.
# Teks untuk pemain: bahasa Inggris sederhana.
# ============================================================

const EMAS := Color(1.0, 0.85, 0.2)
const ABU := Color(0.75, 0.75, 0.8)
const HIJAU := Color(0.45, 0.95, 0.5)
const MERAH := Color(1.0, 0.45, 0.4)
const WARNA_ELEMEN := {"api": Color(1.0, 0.45, 0.25), "air": Color(0.35, 0.65, 1.0), "tanah": Color(0.7, 0.55, 0.35),
	"petir": Color(1.0, 0.9, 0.3), "angin": Color(0.55, 0.95, 0.75)}

static func teks_sisa_sekarang() -> String:
	return DataEvent.teks_sisa(DataEvent.detik_sampai_minggu_baru(Time.get_datetime_dict_from_system()))

static func jumlah_misi_event_selesai() -> int:
	var n = 0
	for m in ProfilPemain.misi_event:
		if m is Dictionary and bool(m.get("selesai", false)):
			n += 1
	return n

static func buka_event(induk: Node) -> void:
	if not is_instance_valid(induk) or not induk.is_inside_tree():
		return
	ProfilPemain.segarkan_event()
	var kanvas = UiProfil._layar_gelap(induk, 12)
	kanvas.name = "PanelEvent"
	var isi = UiProfil._kartu_tengah(kanvas, true)
	isi.add_theme_constant_override("separation", 8)
	var ev: Dictionary = ProfilPemain.event_sekarang()
	var mundur = ProfilPemain.tanggal_mundur()
	isi.add_child(UiProfil._label(str(ev["nama"]).to_upper(), 32, EMAS))
	isi.add_child(UiProfil._label("Event paused: check your date" if mundur else teks_sisa_sekarang(), 18, MERAH if mundur else ABU))
	isi.add_child(UiProfil._label("TOKENS %d" % ProfilPemain.token_event, 24, EMAS))
	isi.add_child(UiProfil._label("Finish missions to earn Event Tokens. Tokens never expire.", 15, ABU))
	var ms: Array = DataEvent.daftar_misi(ProfilPemain.minggu_event)
	for i in range(mini(ms.size(), ProfilPemain.misi_event.size())):
		var m: Dictionary = ProfilPemain.misi_event[i]
		var selesai = bool(m.get("selesai", false))
		var target = int(ms[i]["target"])
		var kartu = PanelContainer.new()
		kartu.add_theme_stylebox_override("panel", UiToko._gaya_baris(selesai))
		var kol = VBoxContainer.new()
		kartu.add_child(kol)
		var baris = HBoxContainer.new()
		kol.add_child(baris)
		var l_teks = UiProfil._label(DataEvent.teks_misi(ProfilPemain.minggu_event, i), 18, HIJAU if selesai else Color.WHITE)
		l_teks.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		l_teks.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		baris.add_child(l_teks)
		baris.add_child(UiProfil._label("DONE" if selesai else "+%d tokens" % int(ms[i]["token"]), 16, HIJAU if selesai else EMAS))
		var batang = ProgressBar.new()
		batang.custom_minimum_size = Vector2(0, 14)
		batang.show_percentage = false
		batang.max_value = float(target)
		batang.value = float(int(m.get("progres", 0)))
		kol.add_child(batang)
		kol.add_child(UiProfil._label("%d/%d" % [int(m.get("progres", 0)), target], 14, ABU))
		isi.add_child(kartu)
	var btn_toko = UiProfil._tombol("EVENT SHOP", Color(0.75, 0.55, 0.1), Vector2(240, 52), 22)
	btn_toko.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn_toko.pressed.connect(func():
		kanvas.queue_free()
		UiToko.buka_toko(induk, "event")
	)
	isi.add_child(btn_toko)
	var tutup = UiProfil._tombol("CLOSE", Color(0.6, 0.2, 0.2), Vector2(200, 52), 20)
	tutup.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	tutup.pressed.connect(kanvas.queue_free)
	isi.add_child(tutup)

static func buka_mastery(induk: Node) -> void:
	if not is_instance_valid(induk) or not induk.is_inside_tree():
		return
	var kanvas = UiProfil._layar_gelap(induk, 12)
	kanvas.name = "PanelMastery"
	var isi = UiProfil._kartu_tengah(kanvas, true)
	isi.add_theme_constant_override("separation", 8)
	isi.add_child(UiProfil._label("ELEMENT MASTERY", 32, EMAS))
	isi.add_child(UiProfil._label("Play a role and win duels with its element to level up. Lv %d = Master title." % DataEvent.LEVEL_MAKS, 15, ABU))
	for el in DataRole.ROLE:
		var xp = ProfilPemain.xp_mastery(str(el))
		var info = DataEvent.info_mastery(xp)
		var maks = int(info["xp_untuk_naik"]) == 0
		var baris = HBoxContainer.new()
		baris.add_theme_constant_override("separation", 10)
		isi.add_child(baris)
		var l_el = UiProfil._label(str(DataEvent.NAMA_ELEMEN[el]), 20, WARNA_ELEMEN[el])
		l_el.custom_minimum_size = Vector2(130, 0)
		l_el.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		baris.add_child(l_el)
		baris.add_child(UiProfil._label("Lv %d" % int(info["level"]), 20, EMAS if maks else Color.WHITE))
		var batang = ProgressBar.new()
		batang.custom_minimum_size = Vector2(200, 14)
		batang.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		batang.show_percentage = false
		batang.max_value = 1.0 if maks else float(info["xp_untuk_naik"])
		batang.value = 1.0 if maks else float(info["xp_di_level"])
		baris.add_child(batang)
		baris.add_child(UiProfil._label("MASTER" if maks else "%d/%d" % [int(info["xp_di_level"]), int(info["xp_untuk_naik"])], 16, EMAS if maks else ABU))
	var tutup = UiProfil._tombol("CLOSE", Color(0.6, 0.2, 0.2), Vector2(200, 52), 20)
	tutup.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	tutup.pressed.connect(kanvas.queue_free)
	isi.add_child(tutup)
