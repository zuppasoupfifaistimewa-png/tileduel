extends Node3D
# Ukur frame terlama saat jebakan api PERTAMA & KEDUA kali kena, di renderer
# Compatibility dengan cache shader dingin (jalankan dgn MESA_SHADER_CACHE_DISABLE
# dan folder user:// baru). Urutan saat kena = persis bergerak_maju:
# tempel_efek_terbakar(korban) lalu mainkan_efek_bakar().
#   varian=tanpa : tanpa pemanasan jebakan api sama sekali
#   varian=asli  : pemanasan SEBELUM sesi ini (instance jebakan saja)
#   varian=lama  : versi yang dikirim ronde lalu (+ node_nuklir.show, tanpa diperkecil)
#   varian=baru  : pemain.gd _pemanasan_jebakan_api (kode ASLI yang dipanggil)
const PemainScript = preload("res://pemain.gd")
var kam: Camera3D
var varian = "baru"
var tingkat = "sangat_rendah"
var t_prev = 0
var catat = false
var frame_max = 0.0
var catat_warm = false
var frame_max_warm = 0.0
var jebakan = []
var korban = []

func _ready():
	for a in OS.get_cmdline_user_args():
		if a.begins_with("varian="): varian = a.substr(7)
		if a.begins_with("tingkat="): tingkat = a.substr(8)
	AudioGrafis.simpan_tingkat(tingkat)

	kam = Camera3D.new(); kam.position = Vector3(0, 6, 8); kam.rotation_degrees = Vector3(-35, 0, 0)
	add_child(kam); kam.current = true
	var sun = DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-50, 30, 0); add_child(sun)
	var lantai = MeshInstance3D.new(); lantai.mesh = PlaneMesh.new(); lantai.mesh.size = Vector2(30, 30)
	var ml = StandardMaterial3D.new(); ml.albedo_color = Color(0.3, 0.55, 0.25); lantai.material_override = ml
	add_child(lantai)
	for i in 8:
		var k = MeshInstance3D.new(); k.mesh = BoxMesh.new()
		var m = StandardMaterial3D.new(); m.albedo_color = Color.from_hsv(i / 8.0, 0.6, 0.9)
		if i % 2 == 1: m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA; m.albedo_color.a = 0.7
		k.material_override = m; k.position = Vector3((i % 4) * 2.2 - 3.3, 0.5, -3.0 - floor(i / 4) * 2.2)
		add_child(k)

	# Dua jebakan api sudah terpasang (kotaknya tampil sejak awal, seperti di game)
	# dan dua "karakter" berdiri di dekatnya.
	for i in 2:
		var petak = Node3D.new(); petak.position = Vector3(-2.0 + i * 4.0, 0, 1.0); add_child(petak)
		var j = preload("res://jebakan_api.gd").new(); j.name = "JebakanApi"; petak.add_child(j)
		jebakan.append(j)
		var model = MeshInstance3D.new(); model.mesh = CapsuleMesh.new()
		var mm = StandardMaterial3D.new(); mm.albedo_color = Color(0.2, 0.5, 1.0) if i == 0 else Color(1.0, 0.2, 0.2)
		model.material_override = mm; model.position = petak.position + Vector3(0.6, 1.0, 0)
		add_child(model)
		korban.append(model)

	for i in 30: await get_tree().process_frame

	if varian != "tanpa":
		var wadah = Node3D.new(); add_child(wadah)
		_ikuti_kamera(wadah)
		t_prev = Time.get_ticks_usec(); catat_warm = true
		match varian:
			"asli":
				var api = preload("res://jebakan_api.gd").new(); wadah.add_child(api)
			"lama":
				var api = preload("res://jebakan_api.gd").new(); wadah.add_child(api)
				if is_instance_valid(api.node_nuklir): api.node_nuklir.show()
			"baru":
				PemainScript._pemanasan_jebakan_api(wadah)
		if tingkat != "sangat_rendah":
			# lampu umum dari _pemanasan_shader (hanya di atas Very Low)
			var lampu = OmniLight3D.new(); lampu.light_energy = 0.01; lampu.omni_range = 60.0; wadah.add_child(lampu)
		for i in 10:
			await get_tree().process_frame
			_ikuti_kamera(wadah)
		catat_warm = false
		wadah.queue_free()

	for i in 60: await get_tree().process_frame
	var hasil = []
	for putaran in 2:
		frame_max = 0.0; t_prev = Time.get_ticks_usec(); catat = true
		jebakan[putaran].tempel_efek_terbakar(korban[putaran])
		jebakan[putaran].mainkan_efek_bakar()
		for i in 70: await get_tree().process_frame
		catat = false
		hasil.append(frame_max)
		for i in 30: await get_tree().process_frame
	print("UKUR tingkat=%s varian=%s | pemanasan %.0f ms | KENA-1 %.0f ms | kena-2 %.0f ms" % [tingkat, varian, frame_max_warm, hasil[0], hasil[1]])
	get_tree().quit()

func _ikuti_kamera(w: Node3D) -> void:
	w.global_position = kam.global_position - kam.global_transform.basis.z * 1.2
	w.look_at(kam.global_position, Vector3.UP)

func _process(_d):
	var now = Time.get_ticks_usec()
	if catat: frame_max = max(frame_max, (now - t_prev) / 1000.0)
	if catat_warm: frame_max_warm = max(frame_max_warm, (now - t_prev) / 1000.0)
	t_prev = now
