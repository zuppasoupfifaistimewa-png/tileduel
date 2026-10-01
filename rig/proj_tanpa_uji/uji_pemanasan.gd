extends Node3D
# Ukur jeda koin 3D pertama dengan 3 variasi pemanasan:
#  W0 = tanpa pemanasan koin, W1 = salinan koin + lampu mungil (jangkauan 0.1),
#  W2 = salinan koin + lampu berjangkauan luas (ikut menyinari papan).
var UiElemen = preload("res://ui_elemen.gd")
var ui; var kam: Camera3D; var td: RichTextLabel
var varian = "W0"
var t_prev = 0; var frame_max = 0.0; var catat = false; var frame_max_warm = 0.0; var catat_warm = false

func _ready():
	for a in OS.get_cmdline_user_args():
		if a.begins_with("varian="): varian = a.substr(7)
	AudioGrafis.simpan_tingkat("sedang")
	kam = Camera3D.new(); kam.position = Vector3(0, 6, 8); kam.rotation_degrees = Vector3(-35, 0, 0); add_child(kam); kam.current = true
	var sun = DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-50, 30, 0); add_child(sun)
	# Papan dengan beberapa JENIS material berbeda (= shader berbeda), seperti peta asli
	var lantai = MeshInstance3D.new(); lantai.mesh = PlaneMesh.new(); lantai.mesh.size = Vector2(30, 30)
	var ml = StandardMaterial3D.new(); ml.albedo_color = Color(0.3, 0.55, 0.25); lantai.material_override = ml; add_child(lantai)
	var img = Image.create(8, 8, false, Image.FORMAT_RGB8); img.fill(Color(0.8, 0.7, 0.5))
	var tex = ImageTexture.create_from_image(img)
	var sh = Shader.new(); sh.code = "shader_type spatial;\nuniform vec4 w : source_color = vec4(0.2,0.7,0.3,1.0);\nvoid vertex(){ VERTEX.y += sin(TIME + VERTEX.x) * 0.02; }\nvoid fragment(){ ALBEDO = w.rgb; ROUGHNESS = 0.8; }"
	for i in 12:
		var k = MeshInstance3D.new(); k.mesh = BoxMesh.new()
		var m
		match i % 4:
			0: m = StandardMaterial3D.new(); m.albedo_color = Color.from_hsv(i / 12.0, 0.6, 0.9)
			1: m = StandardMaterial3D.new(); m.albedo_texture = tex
			2: m = StandardMaterial3D.new(); m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA; m.albedo_color = Color(0.4, 0.6, 1.0, 0.7)
			3: m = ShaderMaterial.new(); m.shader = sh
		k.material_override = m; k.position = Vector3((i % 4) * 2.2 - 3.3, 0.5, floor(i / 4) * 2.2 - 3.0); add_child(k)
	var cl = CanvasLayer.new(); add_child(cl)
	ui = UiElemen.new(); ui.color = Color(0.05, 0.05, 0.1, 0.85); ui.size = Vector2(1280, 720); cl.add_child(ui)
	td = RichTextLabel.new(); td.position = Vector2(390, 640); td.size = Vector2(600, 60); cl.add_child(td)
	td.text = "You guessed HEADS TAILS. Flipping coin... RESULT: HEADS TAILS! RIGHT WRONG Guess!"
	for i in 30: await get_tree().process_frame
	if varian != "W0":
		t_prev = Time.get_ticks_usec(); catat_warm = true
		await _pemanasan_koin(varian == "W2")
		catat_warm = false
	for i in 60: await get_tree().process_frame
	var hasil = []
	for putaran in 2:
		ui.show(); ui.fase_duel = "PENGUMUMAN_FINAL"; ui.teks_judul.hide(); ui.lubang_koin_progress = 0.001; ui.color = Color.TRANSPARENT
		var tw = create_tween(); tw.tween_property(ui, "lubang_koin_progress", 1.0, 0.6); await tw.finished
		frame_max = 0.0; t_prev = Time.get_ticks_usec(); catat = true
		await ui._eksekusi_flip_koin("kepala", kam, td, "ekor")
		catat = false; hasil.append(frame_max); ui.lubang_koin_progress = 0.0
		for i in 30: await get_tree().process_frame
	print("UKUR %s: jeda saat pemanasan = %.0f ms | koin flip-1 = %.0f ms, flip-2 = %.0f ms" % [varian, frame_max_warm, hasil[0], hasil[1]])
	get_tree().quit()

func _process(_d):
	var now = Time.get_ticks_usec()
	if catat: frame_max = max(frame_max, (now - t_prev) / 1000.0)
	if catat_warm: frame_max_warm = max(frame_max_warm, (now - t_prev) / 1000.0)
	t_prev = now

func _pemanasan_koin(lampu_luas: bool):
	# Salinan PERSIS material koin 3D di _eksekusi_flip_koin, dalam wadah di depan kamera
	var wadah = Node3D.new(); add_child(wadah)
	wadah.global_position = kam.global_position - kam.global_transform.basis.z * 1.2
	wadah.look_at(kam.global_position, Vector3.UP)
	var koin = CSGCylinder3D.new(); koin.radius = 0.2; koin.height = 0.05; koin.sides = 64
	var mat = StandardMaterial3D.new(); mat.albedo_color = Color(1.0, 0.85, 0.2); mat.metallic = 1.0; mat.roughness = 0.25
	koin.material = mat; wadah.add_child(koin)
	var lbl = Label3D.new(); lbl.text = "HEADS TAILS"; lbl.font_size = 200; lbl.outline_size = 40
	lbl.modulate = Color(0.65, 0.45, 0.0); lbl.outline_modulate = Color(1.0, 0.95, 0.5); lbl.shaded = true; lbl.pixel_size = 0.0005
	wadah.add_child(lbl)
	var lampu = OmniLight3D.new(); lampu.light_energy = 0.01
	lampu.omni_range = 30.0 if lampu_luas else 0.1
	wadah.add_child(lampu)
	for i in 10:
		await get_tree().process_frame
		wadah.global_position = kam.global_position - kam.global_transform.basis.z * 1.2
	wadah.queue_free()
