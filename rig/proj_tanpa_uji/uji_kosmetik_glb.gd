extends Node
# Fase 7 G3 (rig-only): trim pada model ASLI (beras_asli_uji.glb = kiriman pemilik): badan merah, tangan putih, sepatu hitam.
func _ready() -> void:
	var gagal := 0
	var pd = load("res://pemain_dasar.gd").new()
	var daftar := []
	var model = load("res://beras_asli_uji.glb").instantiate()
	add_child(model)
	for m in model.find_children("*", "MeshInstance3D", true, false):
		for i in range((m as MeshInstance3D).mesh.get_surface_count()):
			daftar.append(m.get_active_material(i).albedo_color)
	print("bahan asli (albedo Godot): ", daftar)
	var biru := Color(0.2, 0.5, 1.0)
	pd._warnai_karakter(model, biru, "pawn_gold")
	var hasil := []
	for m in model.find_children("*", "MeshInstance3D", true, false):
		for i in range((m as MeshInstance3D).mesh.get_surface_count()):
			hasil.append(m.get_active_material(i).albedo_color)
	print("sesudah pawn_gold: ", hasil)
	var n_biru := 0
	var n_emas := 0
	for c in hasil:
		if c.is_equal_approx(biru): n_biru += 1
		if c.is_equal_approx(Color("FFCC33")): n_emas += 1
	gagal += _cek("badan = warna slot (1 bahan)", n_biru == 1)
	gagal += _cek("tangan + sepatu = trim Gold (2 bahan)", n_emas == 2)
	# salinan slot 3 dari musuh ber-trim Lava -> Shadow
	var musuh = load("res://beras_asli_uji.glb").instantiate()
	add_child(musuh)
	pd._warnai_karakter(musuh, Color(1.0, 0.2, 0.2), "pawn_lava")
	var salinan = musuh.duplicate()
	add_child(salinan)
	pd._warnai_karakter(salinan, Color(0.2, 0.8, 0.2), "pawn_shadow")
	var s_gelap := 0
	var s_hijau := 0
	for m in salinan.find_children("*", "MeshInstance3D", true, false):
		for i in range((m as MeshInstance3D).mesh.get_surface_count()):
			var c: Color = m.get_active_material(i).albedo_color
			if c.is_equal_approx(Color("262626")): s_gelap += 1
			if c.is_equal_approx(Color(0.2, 0.8, 0.2)): s_hijau += 1
	gagal += _cek("salinan: trim Shadow 2 bahan, badan hijau 1 bahan", s_gelap == 2 and s_hijau == 1)
	# classic = bahan asli persis
	var m3 = load("res://beras_asli_uji.glb").instantiate()
	add_child(m3)
	pd._warnai_karakter(m3, biru, "pawn_classic")
	var sama := 0
	var asli = load("res://beras_asli_uji.glb").instantiate()
	var a_list := []
	for m in asli.find_children("*", "MeshInstance3D", true, false):
		for i in range((m as MeshInstance3D).mesh.get_surface_count()):
			a_list.append(m.get_active_material(i).albedo_color)
	var k := 0
	for m in m3.find_children("*", "MeshInstance3D", true, false):
		for i in range((m as MeshInstance3D).mesh.get_surface_count()):
			if m.get_active_material(i).albedo_color.is_equal_approx(a_list[k]): sama += 1
			k += 1
	gagal += _cek("classic: tangan & sepatu = bahan asli (badan = slot)", sama == 2)
	print("UJI_KOSMETIK_GLB gagal: ", gagal)
	get_tree().quit(1 if gagal > 0 else 0)

func _cek(nama: String, ok: bool) -> int:
	print(("OK    " if ok else "GAGAL ") + nama)
	return 0 if ok else 1
