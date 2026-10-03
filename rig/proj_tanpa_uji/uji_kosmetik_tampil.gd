extends Node
# Fase 7 G3 (rig-only): kosmetik tampil -- validasi host (payload), trim bidak (badan tetap warna slot), gelar, bingkai kartu profil.
func _ready() -> void:
	var gagal := 0
	var K = DataKosmetik
	# 1) validasi host
	var sah = K.sah_semua({"pawn": "pawn_gold", "title": "title_duelist", "frame": "frame_royal"})
	gagal += _cek("id sah lolos", sah["pawn"] == "pawn_gold" and sah["title"] == "title_duelist" and sah["frame"] == "frame_royal")
	sah = K.sah_semua({"pawn": "tidak_ada", "title": "pawn_rose", "frame": 42})
	gagal += _cek("id tak dikenal / jenis salah / bukan string -> AWAL", sah["pawn"] == "pawn_classic" and sah["title"] == "title_rookie" and sah["frame"] == "frame_plain")
	for rusak in [null, 5, "x", [], {}, {"pawn": null}]:
		var h = K.sah_semua(rusak)
		gagal += _cek("payload rusak %s -> AWAL" % str(rusak), h["pawn"] == "pawn_classic" and h["title"] == "title_rookie" and h["frame"] == "frame_plain")
	var lobi = load("res://layar_local_play.gd").new()
	var ps: Dictionary = lobi._profil_sah({"nama": "Andi", "level": 3, "kosmetik": {"pawn": "pawn_lava", "title": "zzz", "frame": "frame_gold"}}, 123456)
	gagal += _cek("_profil_sah: kosmetik tervalidasi host", ps["kosmetik"] == {"pawn": "pawn_lava", "title": "title_rookie", "frame": "frame_gold"})
	ps = lobi._profil_sah({"nama": "Andi", "level": 3}, 123456) # HP versi lama: tanpa field kosmetik
	gagal += _cek("_profil_sah: tanpa field kosmetik -> AWAL", ps["kosmetik"] == {"pawn": "pawn_classic", "title": "title_rookie", "frame": "frame_plain"})
	lobi.free()
	# 2) profil sendiri -> payload
	ProfilPemain.crowns = 99999
	ProfilPemain.kosmetik_dimiliki = []
	ProfilPemain.kosmetik_dipakai = {}
	gagal += _cek("pakai_semua default = AWAL", ProfilPemain.kosmetik_pakai_semua() == K.AWAL)
	# 3) trim bidak
	var pd = load("res://pemain_dasar.gd").new()
	var biru := Color(0.2, 0.5, 1.0)
	var model = load("res://beras_uji.tscn").instantiate()
	var badan: MeshInstance3D = model.get_node("Badan")
	var kaki: MeshInstance3D = model.get_node("Kaki")
	add_child(model)
	pd._warnai_karakter(model, biru, "pawn_shadow")
	gagal += _cek("badan = warna slot (biru)", badan.get_active_material(0).albedo_color.is_equal_approx(biru))
	gagal += _cek("sepatu = trim Shadow #262626", kaki.get_active_material(0).albedo_color.is_equal_approx(Color("262626")))
	# slot 3-4 menyalin musuh yang trim-nya sudah diwarnai -> classic harus kembali ke bahan asli
	var musuh = load("res://beras_uji.tscn").instantiate() # seperti game: musuh sudah merah + trim, lalu diduplikat untuk slot 3-4
	add_child(musuh)
	pd._warnai_karakter(musuh, Color(1.0, 0.2, 0.2), "pawn_shadow")
	var salinan = musuh.duplicate()
	add_child(salinan)
	pd._warnai_karakter(salinan, Color(0.2, 0.8, 0.2), "pawn_classic")
	var kaki2: MeshInstance3D = salinan.get_node("Kaki")
	var badan2: MeshInstance3D = salinan.get_node("Badan")
	gagal += _cek("salinan classic: sepatu kembali abu asli", kaki2.get_active_material(0).albedo_color.is_equal_approx(Color(0.4, 0.4, 0.4)))
	gagal += _cek("salinan: badan = hijau slot", badan2.get_active_material(0).albedo_color.is_equal_approx(Color(0.2, 0.8, 0.2)))
	gagal += _cek("model asli tidak tercemar bahan bersama", (load("res://beras_uji.tscn").instantiate().get_node("Kaki") as MeshInstance3D).get_active_material(0).albedo_color.is_equal_approx(Color(0.4, 0.4, 0.4)))
	var model3 = load("res://beras_uji.tscn").instantiate()
	add_child(model3)
	pd._warnai_karakter(model3, biru, "pawn_diamond")
	var m = (model3.get_node("Kaki") as MeshInstance3D).get_active_material(0) as StandardMaterial3D
	gagal += _cek("Diamond: warna + logam + emisi", m.albedo_color.is_equal_approx(Color("BFF4FF")) and is_equal_approx(m.metallic, 0.6) and is_equal_approx(m.roughness, 0.1) and m.emission_enabled and is_equal_approx(m.emission_energy_multiplier, 0.4))
	var model4 = load("res://beras_uji.tscn").instantiate()
	add_child(model4)
	pd._warnai_karakter(model4, biru) # tanpa id -> seperti sebelum Fase 7
	gagal += _cek("tanpa id pawn: sepatu asli", (model4.get_node("Kaki") as MeshInstance3D).get_active_material(0).albedo_color.is_equal_approx(Color(0.4, 0.4, 0.4)))
	# 4) kosmetik per slot + gelar (solo vs multiplayer)
	StatusJaringan.peran_multiplayer = ""
	ProfilPemain.kosmetik_dipakai = {"pawn": "pawn_gold"}
	ProfilPemain.kosmetik_dimiliki = ["pawn_gold"]
	gagal += _cek("solo: slot 0 = profil sendiri, slot 1 (AI) = AWAL", pd._kosmetik_slot(0)["pawn"] == "pawn_gold" and pd._kosmetik_slot(1)["pawn"] == "pawn_classic")
	gagal += _cek("solo: tanpa gelar di teks", pd._gelar_manusia(0) == "")
	StatusJaringan.peran_multiplayer = "host"
	StatusJaringan.profil_slot = [
		{"nama": "A", "level": 2, "kosmetik": {"pawn": "pawn_rose", "title": "title_duelist", "frame": "frame_bronze"}},
		{"nama": "B", "level": 5, "kosmetik": {"pawn": "bukan_id", "title": "title_tile_legend", "frame": "frame_royal"}},
		{}]
	gagal += _cek("MP: kosmetik per slot dari profil_slot", pd._kosmetik_slot(0)["pawn"] == "pawn_rose" and pd._kosmetik_slot(1)["pawn"] == "pawn_classic")
	gagal += _cek("MP: gelar manusia", pd._gelar_manusia(0) == "Duelist" and pd._gelar_manusia(1) == "Tile Legend")
	gagal += _cek("MP: slot AI / di luar jangkauan aman", pd._gelar_manusia(2) == "" and pd._gelar_manusia(9) == "" and pd._kosmetik_slot(9)["frame"] == "frame_plain")
	StatusJaringan.peran_multiplayer = ""
	StatusJaringan.profil_slot = []
	# 5) kartu profil: bingkai + gelar
	for kasus in [["frame_gold", Color("FFCC33"), 5, 6, 14], ["frame_royal", Color("9B59FF"), 5, 8, 18], ["frame_plain", UiProfil.EMAS, 2, 0, 14], ["ngawur", UiProfil.EMAS, 2, 0, 14]]:
		UiProfil.tampilkan_kartu_profil(self, {"nama": "Andi", "level": 7, "respect": 1, "mvp_total": 0, "kosmetik": {"pawn": "pawn_classic", "title": "title_storm_caller", "frame": kasus[0]}})
		await get_tree().process_frame
		var kartu: PanelContainer = _cari_kartu(get_child(get_child_count() - 1))
		var g: StyleBoxFlat = kartu.get_theme_stylebox("panel")
		gagal += _cek("kartu %s: border/lebar/bayangan/radius" % kasus[0], g.border_color.is_equal_approx(kasus[1]) and g.border_width_left == kasus[2] and g.shadow_size == kasus[3] and g.corner_radius_top_left == kasus[4])
		gagal += _cek("kartu %s: gelar 'Storm Caller' tampil" % kasus[0], _ada_teks(kartu, "Storm Caller"))
		get_child(get_child_count() - 1).queue_free()
		await get_tree().process_frame
	UiProfil.tampilkan_kartu_profil(self, {"nama": "Tua", "level": 1}) # profil tanpa field kosmetik (HP lama)
	await get_tree().process_frame
	var kt = _cari_kartu(get_child(get_child_count() - 1))
	gagal += _cek("kartu tanpa kosmetik: gelar Rookie, bingkai biasa", _ada_teks(kt, "Rookie") and (kt.get_theme_stylebox("panel") as StyleBoxFlat).border_width_left == 2)
	print("UJI_KOSMETIK_TAMPIL gagal: ", gagal)
	get_tree().quit(1 if gagal > 0 else 0)

func _cari_kartu(n: Node) -> PanelContainer:
	for c in n.find_children("*", "PanelContainer", true, false):
		return c
	return null

func _ada_teks(n: Node, teks: String) -> bool:
	for l in n.find_children("*", "Label", true, false):
		if (l as Label).text == teks:
			return true
	return false

func _cek(nama: String, ok: bool) -> int:
	print(("OK    " if ok else "GAGAL ") + nama)
	return 0 if ok else 1
