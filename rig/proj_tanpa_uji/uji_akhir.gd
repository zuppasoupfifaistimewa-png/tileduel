extends Node3D
# Pratinjau panel syarat menang & animasi akhir permainan per tingkat grafis.
#   tingkat=sangat_rendah|rendah|sedang|tinggi   mode=menang|kalah|syarat
var tingkat = "sedang"
var mode = "menang"
var p = null

func _ready():
	for a in OS.get_cmdline_user_args():
		if a.begins_with("tingkat="): tingkat = a.substr(8)
		if a.begins_with("mode="): mode = a.substr(5)
	AudioGrafis.simpan_tingkat(tingkat)

	var kam = Camera3D.new(); kam.name = "Camera3D"
	kam.position = Vector3(0, 6, 9); kam.rotation_degrees = Vector3(-30, 0, 0)
	add_child(kam); kam.current = true
	var sun = DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-50, 30, 0); add_child(sun)
	var lantai = MeshInstance3D.new(); lantai.mesh = PlaneMesh.new(); lantai.mesh.size = Vector2(60, 60)
	var m = StandardMaterial3D.new(); m.albedo_color = Color(0.25, 0.45, 0.25); lantai.material_override = m
	add_child(lantai)
	for i in 5:
		var k = MeshInstance3D.new(); k.mesh = BoxMesh.new()
		var mm = StandardMaterial3D.new(); mm.albedo_color = Color.from_hsv(i / 5.0, 0.6, 0.9)
		k.material_override = mm; k.position = Vector3(i * 2.4 - 4.8, 0.5, -3.0); add_child(k)

	p = load("res://uji_efek_lag_pemain.gd").new(); p.name = "Pemain"; add_child(p)
	for i in 5: await get_tree().process_frame

	var skor = [
		{"slot": 0, "uang": 3250, "bintang": 7, "petak": 9, "permata": 3},
		{"slot": 1, "uang": 1480, "bintang": 4, "petak": 5, "permata": 2},
	]

	if mode == "putus":
		UiDinamis.tampilkan_panel_lawan_keluar(p)
		for i in 25: await get_tree().process_frame
		await _foto("putus")
		get_tree().quit()
		return

	if mode == "syarat":
		UiDinamis.tampilkan_panel_syarat_menang(p, [
			"Collect all 3 gems on the board",
			"Pass START with the gems complete to get your salary",
			"Reach START with 3000+ coins to win",
			"Salary at START: +500, +10 per tile you own, +3 stars",
			"Buy a tile, then STOP on it again to build a tower",
		])
		for i in 25: await get_tree().process_frame
		await _foto("syarat")
		get_tree().quit()
		return

	for pasang in [[0.6, "a"], [1.5, "b"], [2.6, "c"]]:
		get_tree().create_timer(pasang[0]).timeout.connect(func(): await _foto(mode + "_" + pasang[1]))
	await UiDinamis.tampilkan_akhir_permainan(p, mode == "menang", skor)
	for i in 25: await get_tree().process_frame
	await _foto(mode + "_papan")
	get_tree().quit()

func _foto(nama: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://foto_akhir_%s_%s.png" % [tingkat, nama])
