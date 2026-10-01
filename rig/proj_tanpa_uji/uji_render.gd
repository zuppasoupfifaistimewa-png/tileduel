extends Node3D
# Uji visual + ukur jeda: jalankan _eksekusi_flip_koin asli dua kali berturut-turut
# di renderer Compatibility, catat frame terlama di sekitar kemunculan koin.
var UiElemen = preload("res://ui_elemen.gd")
var ui
var kam: Camera3D
var td: RichTextLabel
var mode = "2d"
var t_prev = 0
var frame_max = 0.0
var catat = false
var t_mulai = 0.0

func _ready():
	for a in OS.get_cmdline_user_args():
		if a.begins_with("mode="): mode = a.substr(5)
	AudioGrafis.simpan_tingkat("sangat_rendah" if mode == "2d" else "sedang")
	# "Papan" tiruan: beberapa kotak & bidang ber-material, seperti petak di layar duel
	kam = Camera3D.new(); kam.position = Vector3(0, 6, 8); kam.rotation_degrees = Vector3(-35, 0, 0); add_child(kam); kam.current = true
	var sun = DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-50, 30, 0); add_child(sun)
	var lantai = MeshInstance3D.new(); lantai.mesh = PlaneMesh.new(); lantai.mesh.size = Vector2(30, 30)
	var ml = StandardMaterial3D.new(); ml.albedo_color = Color(0.3, 0.55, 0.25); lantai.material_override = ml; add_child(lantai)
	for i in 12:
		var k = MeshInstance3D.new(); k.mesh = BoxMesh.new()
		var m = StandardMaterial3D.new(); m.albedo_color = Color.from_hsv(i / 12.0, 0.6, 0.9); m.roughness = 0.6
		k.material_override = m; k.position = Vector3((i % 4) * 2.2 - 3.3, 0.5, floor(i / 4) * 2.2 - 3.0); add_child(k)
	var cl = CanvasLayer.new(); add_child(cl)
	ui = UiElemen.new(); ui.color = Color(0.05, 0.05, 0.1, 0.85); ui.size = Vector2(1280, 720); cl.add_child(ui)
	td = RichTextLabel.new(); td.position = Vector2(390, 640); td.size = Vector2(600, 60); td.add_theme_font_size_override("normal_font_size", 28); cl.add_child(td)
	if "prewarm" in OS.get_cmdline_user_args(): ThemeDB.fallback_font.get_string_size("HEADSTAIL", HORIZONTAL_ALIGNMENT_LEFT, -1, 64)
	if "prefill" in OS.get_cmdline_user_args(): td.text = "You guessed HEADS TAILS. Flipping coin... RESULT: HEADS TAILS! RIGHT WRONG Guess!"
	if "predraw" in OS.get_cmdline_user_args():
		ui.koin_ringan_tampil = true; ui.koin_ringan_skala = 0.01
		for j in 5: await get_tree().process_frame
		ui.koin_ringan_tampil = false
	for i in 90: await get_tree().process_frame
	var hasil = []
	for putaran in 2:
		ui.show(); ui.color = Color(0.05, 0.05, 0.1, 0.85); ui.fase_duel = "PENGUMUMAN_FINAL"
		ui.teks_judul.hide(); ui.lubang_koin_progress = 0.001; ui.color = Color.TRANSPARENT
		var tw = create_tween(); tw.tween_property(ui, "lubang_koin_progress", 1.0, 0.6); await tw.finished
		frame_max = 0.0; t_prev = Time.get_ticks_usec(); catat = true; t_mulai = Time.get_ticks_msec()
		if putaran == 0 and mode == "2d" and not ("nofoto" in OS.get_cmdline_user_args()): _jadwal_foto()
		await ui._eksekusi_flip_koin("kepala", kam, td, "ekor")
		catat = false
		hasil.append(frame_max)
		ui.lubang_koin_progress = 0.0
		for i in 30: await get_tree().process_frame
	print("UKUR mode=%s  frame terlama: flip-1 = %.0f ms, flip-2 = %.0f ms" % [mode, hasil[0], hasil[1]])
	get_tree().quit()

func _process(_d):
	var now = Time.get_ticks_usec()
	if catat: frame_max = max(frame_max, (now - t_prev) / 1000.0)
	t_prev = now

func _jadwal_foto():
	for pasang in [[1.00,"s0"],[1.08,"s1"],[1.16,"s2"],[1.24,"s3"],[1.32,"s4"],[1.40,"s5"],[1.48,"s6"],[1.56,"s7"]]:
		get_tree().create_timer(pasang[0]).timeout.connect(func():
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("res://foto_%s.png" % pasang[1]))
