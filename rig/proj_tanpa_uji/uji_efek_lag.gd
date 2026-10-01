extends Node3D
# Frame terlama saat efek diputar pertama & kedua kali, renderer Compatibility,
# cache shader dingin. Pemanasan = _pemanasan_shader() ASLI dari pemain.gd yang terpasang.
#   efek=permata | start | suara      varian=tanpa | asli     tingkat=sangat_rendah | sedang
var kam: Camera3D
var efek = "permata"
var varian = "asli"
var tingkat = "sangat_rendah"
var t_prev = 0
var catat = false
var frame_max = 0.0
var catat_warm = false
var frame_max_warm = 0.0
var deret = []
var permata = []
var start = []
var opsi = []
var api_list = []
var korban_list = []
var ui_koin = null
var p_node = null
var td_koin = null

func _ready():
	for a in OS.get_cmdline_user_args():
		if a.begins_with("efek="): efek = a.substr(5)
		if a.begins_with("varian="): varian = a.substr(7)
		if a.begins_with("tingkat="): tingkat = a.substr(8)
		if a.begins_with("opsi="): opsi = a.substr(5).split(",")
	AudioGrafis.simpan_tingkat(tingkat)

	if efek == "suara":
		var t = Time.get_ticks_usec()
		var pp = PetakPermata.new(); pp._buat_suara_ting(); pp.free()
		var d1 = (Time.get_ticks_usec() - t) / 1000.0
		t = Time.get_ticks_usec()
		var up = UIPetak.new(); up._buat_suara_sintetis("gajian"); up.free()
		var d2 = (Time.get_ticks_usec() - t) / 1000.0
		print("UKUR SUARA (CPU laptop): ting %.1f ms | gajian %.1f ms" % [d1, d2])
		get_tree().quit()
		return

	kam = Camera3D.new(); kam.name = "Camera3D"; kam.position = Vector3(0, 7, 8); kam.rotation_degrees = Vector3(-40, 0, 0)
	if "foto" in opsi: kam.position = Vector3(-2.5, 5.5, 7.5); kam.rotation_degrees = Vector3(-28, 0, 0)
	add_child(kam); kam.current = true
	var sun = DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-50, 30, 0); add_child(sun)
	var lantai = MeshInstance3D.new(); lantai.mesh = PlaneMesh.new(); lantai.mesh.size = Vector2(30, 30)
	var ml = StandardMaterial3D.new(); ml.albedo_color = Color(0.3, 0.55, 0.25); lantai.material_override = ml
	add_child(lantai)
	for i in 6:
		var k = MeshInstance3D.new(); k.mesh = BoxMesh.new()
		var m = StandardMaterial3D.new(); m.albedo_color = Color.from_hsv(i / 6.0, 0.6, 0.9)
		k.material_override = m; k.position = Vector3(i * 2.2 - 5.5, 0.5, -5.0); add_child(k)
	# Dua petak permata & dua petak Start, tampil sejak awal seperti papan asli
	for i in 2:
		var pt = Node3D.new(); pt.position = Vector3(-2.5 + i * 5.0, 0, 1.0); add_child(pt)
		var vp = PetakPermata.new(); vp.warna_permata = Color(0.2, 0.9, 0.4); pt.add_child(vp)
		permata.append(vp)
		var ps = Node3D.new(); ps.position = Vector3(-2.5 + i * 5.0, 0, -2.0); add_child(ps)
		var lp = CSGBox3D.new(); lp.size = Vector3(2, 0.1, 2); ps.add_child(lp)
		var ui = UIPetak.new(); ps.add_child(ui)
		ui.jadikan_petak_start()
		start.append(ui)

	if "kilau_mati" in opsi:
		for vp in permata: vp.set_process(false)
	if efek == "api":
		for i in 2:
			var pa = Node3D.new(); pa.position = Vector3(-1.5 + i * 3.0, 0, 3.0); add_child(pa)
			var j = preload("res://jebakan_api.gd").new(); j.name = "JebakanApi"; pa.add_child(j); api_list.append(j)
			var mdl = MeshInstance3D.new(); mdl.mesh = CapsuleMesh.new(); var mm = StandardMaterial3D.new(); mm.albedo_color = Color(0.2, 0.5, 1.0)
			mdl.material_override = mm; mdl.position = pa.position + Vector3(0.6, 1.0, 0); add_child(mdl); korban_list.append(mdl)
	if efek == "koin":
		var cl = CanvasLayer.new(); add_child(cl)
		ui_koin = preload("res://ui_elemen.gd").new(); ui_koin.color = Color(0.05, 0.05, 0.1, 0.85); ui_koin.size = Vector2(1280, 720); cl.add_child(ui_koin)
		td_koin = RichTextLabel.new(); td_koin.position = Vector2(390, 640); td_koin.size = Vector2(600, 60); cl.add_child(td_koin)
		td_koin.text = "You guessed HEADS TAILS. Flipping coin... RESULT: HEADS TAILS! RIGHT WRONG Guess!"
	for i in 30: await get_tree().process_frame
	if varian != "tanpa":
		var p = load("res://uji_efek_lag_pemain.gd").new(); p.name = "Pemain"; add_child(p); p_node = p
		p.kamera = kam
		t_prev = Time.get_ticks_usec(); catat_warm = true
		await p._pemanasan_shader()
		catat_warm = false
	if "suara_siap" in opsi:
		permata[0]._buat_suara_ting(); start[0]._buat_suara_sintetis("gajian")
	if "mat_ringan" in opsi:
		for vp in permata:
			var m = StandardMaterial3D.new(); m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA; m.albedo_color = vp.warna_permata
			vp.cache_mat_permata = m
	if "teks_siap" in opsi:
		var w = Node3D.new(); add_child(w)
		w.global_position = kam.global_position - kam.global_transform.basis.z * 1.2; w.look_at(kam.global_position, Vector3.UP)
		var l = Label3D.new(); l.text = "+0123456789 KOIN"; l.font_size = 250; l.outline_size = 50
		l.modulate = Color(1.0, 0.84, 0.0); l.billboard = BaseMaterial3D.BILLBOARD_ENABLED; w.add_child(l)
		for i in 5: await get_tree().process_frame
		w.queue_free()
	for i in 60: await get_tree().process_frame

	var hasil = []
	for putaran in 2:
		deret.append([]); frame_max = 0.0; t_prev = Time.get_ticks_usec(); catat = true
		if efek == "permata":
			if putaran == 0 and "foto" in opsi: _jadwal_foto()
			permata[putaran].mainkan_efek_koleksi()
		elif efek == "api":
			api_list[putaran].tempel_efek_terbakar(korban_list[putaran]); api_list[putaran].mainkan_efek_bakar()
		elif efek == "koin":
			ui_koin.show(); ui_koin.fase_duel = "PENGUMUMAN_FINAL"; ui_koin.teks_judul.hide(); ui_koin.lubang_koin_progress = 1.0; ui_koin.color = Color.TRANSPARENT
			await ui_koin._eksekusi_flip_koin("kepala", kam, td_koin, "ekor")
			ui_koin.lubang_koin_progress = 0.0
		elif efek == "serang":
			if putaran == 0 and "foto" in opsi: _jadwal_foto_serang()
			await start[putaran].mainkan_efek_serangan(Vector3(0.0, 0.0, 6.0), "pemain", p_node)
		else: start[putaran].mainkan_efek_lewat_start(500)
		for i in 70: await get_tree().process_frame
		catat = false
		hasil.append(frame_max)
		for i in 30: await get_tree().process_frame
	print("UKUR efek=%s tingkat=%s varian=%s opsi=%s | pemanasan %.0f ms | PUTAR-1 %.0f ms | putar-2 %.0f ms" % [efek, tingkat, varian, ",".join(opsi), frame_max_warm, hasil[0], hasil[1]])
	for n in 2:
		var jml = 0.0
		for k in deret[n].size(): jml += deret[n][k]
		if deret[n].size() > 0:
			print("   putar-%d rata-rata frame: %.1f ms (%d frame)" % [n + 1, jml / deret[n].size(), deret[n].size()])
		var besar = []
		for k in deret[n].size():
			if deret[n][k] > 60: besar.append("f%d=%dms" % [k, deret[n][k]])
		print("   putar-%d frame >60ms: %s" % [n + 1, besar])
	get_tree().quit()

func _process(_d):
	var now = Time.get_ticks_usec()
	var dt = (now - t_prev) / 1000.0
	if catat:
		frame_max = max(frame_max, dt)
		if deret.size() > 0: deret[-1].append(int(dt))
	if catat_warm: frame_max_warm = max(frame_max_warm, dt)
	t_prev = now

func _jadwal_foto():
	for pasang in [[0.25, "a"], [0.55, "b"], [0.85, "c"], [1.2, "d"]]:
		get_tree().create_timer(pasang[0]).timeout.connect(func():
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("res://foto_permata_%s_%s.png" % [tingkat, pasang[1]]))

func _jadwal_foto_serang():
	for pasang in [[0.6, "a"], [1.25, "b"], [1.75, "c"], [2.1, "d"]]:
		get_tree().create_timer(pasang[0]).timeout.connect(func():
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("res://foto_serang_%s_%s.png" % [tingkat, pasang[1]]))
