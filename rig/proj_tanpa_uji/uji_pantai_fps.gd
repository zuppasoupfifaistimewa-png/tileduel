extends Node3D
# Mengukur biaya render peta pantai per tingkat grafis (renderer Compatibility).
# Argumen: tingkat=sangat_rendah|rendah|sedang|tinggi   foto=nama   n=90
# Keluaran: waktu frame rata-rata & terlama per sudut kamera, draw call, primitif,
# objek, jumlah lampu omni aktif, tween aktif, node.
var label_fps = null # dibutuhkan AudioGrafis.muat_seting_grafis
var tingkat = "sedang"
var foto = ""
var n_frame = 90
var kam: Camera3D

const TITIK = [0, 5, 9, 12, 16, 22, 25, 28, 33]
const TITIK_FOTO = [0, 9, 25]

func _ready():
	for a in OS.get_cmdline_user_args():
		if a.begins_with("tingkat="): tingkat = a.substr(8)
		if a.begins_with("foto="): foto = a.substr(5)
		if a.begins_with("n="): n_frame = int(a.substr(2))
	AudioGrafis.simpan_tingkat(tingkat)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	await AudioGrafis.muat_seting_grafis(self)

	kam = Camera3D.new()
	add_child(kam)
	kam.transform = str_to_var("Transform3D(0.84357536, -0.31031597, 0.43827486, 1.2907847e-08, 0.81613755, 0.5778577, -0.53701097, -0.48746642, 0.68847346, 4.141835, 3.8164215, 13.839577)")
	kam.current = true

	var t0 = Time.get_ticks_usec()
	var peta = load("res://PetaPantai.tscn").instantiate()
	peta.name = "PetaPantai"
	add_child(peta)
	await get_tree().process_frame
	await get_tree().process_frame
	var t_bangun = (Time.get_ticks_usec() - t0) / 1000.0

	var papan = peta.get_node("PapanPermainan")
	_terapkan_ablasi(peta)
	var omni = 0
	var omni_bayangan = 0
	for l in peta.find_children("*", "OmniLight3D", true, false):
		if l.visible: omni += 1
	for l in peta.find_children("*", "Light3D", true, false):
		if l.shadow_enabled: omni_bayangan += 1
	var csg = peta.find_children("*", "CSGShape3D", true, false).size()
	var mesh = peta.find_children("*", "MeshInstance3D", true, false).size()
	print("INFO tingkat=%s skala=%.2f bangun=%.0fms lampu_omni=%d lampu_berbayang=%d csg=%d mesh=%d node=%d tween=%d" % [
		tingkat, get_viewport().scaling_3d_scale, t_bangun, omni, omni_bayangan, csg, mesh,
		get_tree().get_node_count(), get_tree().get_processed_tweens().size()])

	var semua = 0.0
	var jml = 0
	var ringkas = []
	for idx in TITIK:
		var petak = papan.get_node("Petak_%d" % idx)
		kam.global_position = petak.global_position + kam.global_transform.basis.z * 30.0
		for i in 15: await get_tree().process_frame
		var total = 0.0
		var terlama = 0.0
		var t_prev = Time.get_ticks_usec()
		var proses = 0.0
		for i in n_frame:
			await get_tree().process_frame
			var t = Time.get_ticks_usec()
			var d = (t - t_prev) / 1000.0
			t_prev = t
			total += d
			terlama = max(terlama, d)
			proses += Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
		var dc = RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
		var prim = RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)
		var obj = RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME)
		var rata = total / n_frame
		semua += total
		jml += n_frame
		ringkas.append("%.1f" % rata)
		print("TITIK petak=%2d  rata=%6.2fms  terlama=%6.2fms  proses=%5.2fms  drawcall=%4d  primitif=%7d  objek=%4d" % [
			idx, rata, terlama, proses / n_frame, dc, prim, obj])
		if foto != "" and idx in TITIK_FOTO:
			await RenderingServer.frame_post_draw
			var img = get_viewport().get_texture().get_image()
			img.save_png("res://foto_pantai_%s_%s_%d.png" % [foto, tingkat, idx])
	print("HASIL tingkat=%s matikan=%s rata_semua=%.2fms (%.1f FPS) per_titik=%s" % [tingkat, ",".join(matikan), semua / jml, 1000.0 / (semua / jml), ", ".join(ringkas)])
	get_tree().quit()

# ---- ablasi: matikan satu fitur SETELAH lingkungan terbangun, untuk mengukur biayanya
var matikan = []
func _terapkan_ablasi(peta: Node) -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("matikan="): matikan = a.substr(8).split(",", false)
	if matikan.is_empty(): return
	var lp = peta.get_node("LingkunganPantai")
	var env: Environment = null
	for c in lp.get_children():
		if c is WorldEnvironment: env = c.environment
	for f in matikan:
		match f:
			"lampu_obor":
				for l in peta.find_children("*", "OmniLight3D", true, false):
					if is_equal_approx(l.omni_range, 10.0): l.visible = false
			"lampu_jauh":
				for l in peta.find_children("*", "OmniLight3D", true, false):
					if is_equal_approx(l.omni_range, 80.0): l.visible = false
			"glow": env.glow_enabled = false
			"bayangan":
				for l in peta.find_children("*", "DirectionalLight3D", true, false): l.shadow_enabled = false
			"langit":
				env.background_mode = Environment.BG_COLOR
				env.background_color = Color(0.03, 0.05, 0.1)
			"bayangan_2split":
				for l in peta.find_children("*", "DirectionalLight3D", true, false):
					l.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
					l.directional_shadow_max_distance = 40.0
			"bayangan_ortho":
				for l in peta.find_children("*", "DirectionalLight3D", true, false):
					l.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
					l.directional_shadow_max_distance = 40.0
			"bayangan_jarak":
				for l in peta.find_children("*", "DirectionalLight3D", true, false):
					l.directional_shadow_max_distance = 40.0
			"pasir_vertex":
				for m in lp.get_children():
					if m is MeshInstance3D and m.material_override is StandardMaterial3D \
							and m.material_override.albedo_color.is_equal_approx(Color(0.42, 0.36, 0.28)):
						m.material_override.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
			"terang":
				env.ambient_light_energy *= 1.5
				for l in peta.find_children("*", "Light3D", true, false):
					l.light_energy *= 1.5
			"terang_exp":
				env.tonemap_exposure = 1.5
			"exp18": env.tonemap_exposure = 1.8
			"ortho60":
				for l in peta.find_children("*", "DirectionalLight3D", true, false):
					l.directional_shadow_max_distance = 60.0
			"ortho80":
				for l in peta.find_children("*", "DirectionalLight3D", true, false):
					l.directional_shadow_max_distance = 80.0
			"exp20": env.tonemap_exposure = 2.0
			"pasir_pixel":
				for m in lp.get_children():
					if m is MeshInstance3D and m.material_override is StandardMaterial3D \
							and m.material_override.albedo_color.is_equal_approx(Color(0.42, 0.36, 0.28)):
						m.material_override.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
			"pasir_padat":
				for m in lp.get_children():
					if m is MeshInstance3D and m.material_override is StandardMaterial3D \
							and m.material_override.albedo_color.is_equal_approx(Color(0.42, 0.36, 0.28)):
						var asli = lp.tingkat_grafis_saat_ini
						lp.tingkat_grafis_saat_ini = "sedang"
						m.mesh = lp._buat_mesh_daratan_solid()
						lp.tingkat_grafis_saat_ini = asli
			"glow_ringan":
				env.glow_bloom = 0.0
			"langit_q": env.sky.process_mode = Sky.PROCESS_MODE_QUALITY
			"langit_rt": env.sky.process_mode = Sky.PROCESS_MODE_REALTIME
			"langit_r32": env.sky.radiance_size = Sky.RADIANCE_SIZE_32
			"refleksi": env.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED
			"obor_separuh":
				var k = 0
				for l in peta.find_children("*", "OmniLight3D", true, false):
					if is_equal_approx(l.omni_range, 10.0):
						if k % 2 == 1: l.visible = false
						k += 1
			"obor_laut":
				for m in lp.get_children():
					if m is MeshInstance3D and m.mesh is BoxMesh and m.mesh.size.x > 500: m.layers = 2
				for l in peta.find_children("*", "OmniLight3D", true, false):
					if is_equal_approx(l.omni_range, 10.0): l.light_cull_mask = 1
			"tween":
				for t in get_tree().get_processed_tweens(): t.kill()
			"dermaga":
				for d in peta.find_children("DermagaKayu*", "", true, false): d.visible = false
			"batu":
				for m in lp.get_children():
					if m is MeshInstance3D and m.material_override == lp.mat_batu_global: m.visible = false
			"pohon":
				for n in lp.get_children():
					if n.get_class() == "Node3D" and n.get_child_count() == 1 and n.get_child(0).get_child_count() == 1 \
							and n.get_child(0).get_child(0) is MeshInstance3D and n.get_child(0).get_child(0).material_override == lp.mat_batang_kelapa:
						n.visible = false
			"ombak": lp.get_node("GrupOmbakKecil").visible = false
			"pita":
				lp.node_ombak.visible = false
				lp.node_pasir_basah.visible = false
			"laut":
				for m in lp.get_children():
					if m is MeshInstance3D and m.mesh is BoxMesh and m.mesh.size.x > 500:
						m.material_override.metallic = 0.0
						m.material_override.roughness = 1.0
			"bayangan_tanah":
				for m in lp.get_children():
					if m is MeshInstance3D and m.material_override != lp.mat_batu_global:
						m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			_: print("ABLASI TIDAK DIKENAL: ", f)
