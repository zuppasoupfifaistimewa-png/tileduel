extends Node3D
class_name LingkunganPantai

var radius_maksimal = 60.0 
var jumlah_objek = 40 
var level_tanah = -0.6        
var batas_aman_x = 10.0
var batas_aman_z = 8.0
var daftar_posisi_petak: Array[Vector2] = []
var posisi_x_pantai: float = 8.0

# --- MATERIAL GLOBAL ---
var mat_batang_kelapa = StandardMaterial3D.new()
var mat_daun_kelapa = StandardMaterial3D.new()
var mat_batu_global = StandardMaterial3D.new()
var mat_tiang_obor = StandardMaterial3D.new()
var mat_api_obor = StandardMaterial3D.new()
# --- ANIMASI OMBAK KECIL LAUT ---
var mat_ombak_kecil: StandardMaterial3D
var jumlah_ombak_kecil: int = 3
var mat_glow: StandardMaterial3D
var mat_ombak: StandardMaterial3D
var node_ombak: MeshInstance3D

var tingkat_grafis_saat_ini = "sedang"

# Layer render khusus laut. Di Low & Very Low lampu obor tidak menyinari layer ini
# (lihat _sebar_obor_sekitar_papan & _setup_laut_pasir).
const LAYER_LAUT := 2
# Medium: jangkauan bayangan bulan dari kamera (meter). Di mode satu peta bayangan,
# 40/60/80 m terukur sama beratnya; 80 m menjaga pohon di ujung layar tetap berbayang.
const JARAK_BAYANGAN_SEDANG := 80.0

func _ready():
	add_to_group("grup_lingkungan")
	seed("PantaiMalam".hash())
	
	var config = ConfigFile.new()
	if config.load("user://seting_grafis.cfg") == OK:
		tingkat_grafis_saat_ini = config.get_value("Pengaturan", "kualitas_grafik", "sedang")
		
	mat_batang_kelapa.albedo_color = Color(0.3, 0.2, 0.15) 
	mat_batang_kelapa.roughness = 0.9
	mat_daun_kelapa.albedo_color = Color(0.1, 0.35, 0.15) 
	mat_daun_kelapa.roughness = 1.0
	
	mat_batu_global.albedo_color = Color(0.65, 0.6, 0.55)
	mat_batu_global.roughness = 0.8
	
	mat_tiang_obor.albedo_color = Color(0.2, 0.1, 0.05)
	mat_tiang_obor.roughness = 0.9
	
	mat_api_obor.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat_api_obor.albedo_color = Color(1.0, 0.6, 0.1)
	
	_setup_langit_malam()
	# _setup_laut_pasir() <--- BARIS INI HARUS DIHAPUS ATAU DIBERI KOMENTAR
	_setup_cahaya_kejauhan()
	call_deferred("_mulai_sebar_pantai")

func _mulai_sebar_pantai():
	daftar_posisi_petak.clear() 
	posisi_x_pantai = 9999.0
	
	var papan = get_parent().get_node_or_null("PapanPermainan")
	if papan == null:
		papan = get_tree().current_scene.find_child("PapanPermainan", true, false)
		
	if papan != null:
		_daftarkan_semua_petak_rekursif(papan)
		_bangun_dermaga_rekursif(papan)
		
		# Pelacakan dinamis batas X
		for petak in papan.get_children():
			if "is_di_atas_air" in petak and petak.is_di_atas_air:
				if petak.global_position.x < posisi_x_pantai:
					posisi_x_pantai = petak.global_position.x
					
	if daftar_posisi_petak.is_empty():
		push_error("GAGAL MEMUAT LINGKUNGAN: Node 'PapanPermainan' tidak ditemukan!")
		return
		
	if posisi_x_pantai == 9999.0:
		posisi_x_pantai = 8.0 
		
	# Fungsi di bawah tidak perlu lagi menerima parameter
	_setup_laut_pasir()
	_buat_bioluminescence()
		
	_sebar_pohon_kelapa()
	_sebar_batu_karang()
	_sebar_obor_sekitar_papan()

# ========================================================
# FUNGSI BARU: PELACAK REKURSIF (BONGKAR SEMUA LAPISAN NODE)
# ========================================================
func _daftarkan_semua_petak_rekursif(node_induk: Node):
	for anak in node_induk.get_children():
		# Deteksi mutlak dari nama awal
		if anak.name.begins_with("Petak") or "is_di_atas_air" in anak:
			daftar_posisi_petak.append(Vector2(anak.global_position.x, anak.global_position.z))
		
		# Jika anak ini punya anak lagi (Petak bersarang), bongkar terus ke dalam!
		if anak.get_child_count() > 0:
			_daftarkan_semua_petak_rekursif(anak)

func _bangun_dermaga_rekursif(node_induk: Node):
	for anak in node_induk.get_children():
		if "is_di_atas_air" in anak and anak.is_di_atas_air:
			_bangun_dermaga(anak)
			
		if anak.get_child_count() > 0:
			_bangun_dermaga_rekursif(anak)

func _apakah_di_luar_zona_aman(pos_global_2d: Vector2, jarak_aman: float = 4.0) -> bool:
	# PERBAIKAN 2: Mengunci pusat pencarian berdasarkan titik global sebenarnya
	var pusat_global = Vector2(self.global_position.x, self.global_position.z)
	
	if abs(pos_global_2d.x - pusat_global.x) < batas_aman_x and abs(pos_global_2d.y - pusat_global.y) < batas_aman_z:
		return false
		
	for pos_petak in daftar_posisi_petak:
		if pos_global_2d.distance_to(pos_petak) < jarak_aman:
			return false
	return true

func _sebar_obor_sekitar_papan():
	var jumlah_petak = daftar_posisi_petak.size()
	var pusat_global = Vector2(self.global_position.x, self.global_position.z)
	
	for i in range(0, jumlah_petak, 4):
		var pos_petak = daftar_posisi_petak[i]
		
		var arah_keluar = (pos_petak - pusat_global).normalized()
		if arah_keluar == Vector2.ZERO: 
			arah_keluar = Vector2(1, 0)
			
		var pos_obor_2d = pos_petak + (arah_keluar * 6.0)
		var percobaan = 0
		
		while not _apakah_di_luar_zona_aman(pos_obor_2d, 5.0) and percobaan < 20:
			pos_obor_2d += arah_keluar * 1.5
			percobaan += 1
			
		if not _apakah_di_luar_zona_aman(pos_obor_2d, 5.0):
			continue
			
		var obor = Node3D.new()
		add_child(obor)
		obor.global_position = Vector3(pos_obor_2d.x, self.global_position.y + level_tanah, pos_obor_2d.y)
		
		var tiang = MeshInstance3D.new()
		var mesh_tiang = CylinderMesh.new()
		mesh_tiang.top_radius = 0.12
		mesh_tiang.bottom_radius = 0.08
		mesh_tiang.height = 3.0 
		mesh_tiang.radial_segments = 6 
		tiang.mesh = mesh_tiang
		tiang.material_override = mat_tiang_obor
		tiang.position.y = 1.5
		obor.add_child(tiang)
		
		var api = MeshInstance3D.new()
		var mesh_api = SphereMesh.new()
		mesh_api.radius = 0.3
		mesh_api.height = 0.6
		mesh_api.radial_segments = 6
		mesh_api.rings = 3
		api.mesh = mesh_api
		api.material_override = mat_api_obor
		api.position.y = 3.2
		obor.add_child(api)
		
		var lampu = OmniLight3D.new()
		lampu.light_color = Color(1.0, 0.7, 0.2)
		lampu.light_energy = 2.0
		lampu.omni_range = 10.0 
		lampu.shadow_enabled = false 
		lampu.position.y = 3.3
		if tingkat_grafis_saat_ini in ["rendah", "sangat_rendah"]:
			# Laut adalah satu objek raksasa, jadi SEMUA lampu obor dihitung di setiap
			# piksel laut — padahal lautnya nyaris hitam dan pantulan obor di sana
			# hampir tidak terlihat. Pasir & papan tetap disinari seperti biasa.
			lampu.light_cull_mask &= ~(1 << (LAYER_LAUT - 1))
		obor.add_child(lampu)
		
		# Animasi nyala api (Kedip) hanya dieksekusi jika performa mencukupi
		if tingkat_grafis_saat_ini != "sangat_rendah":
			var tw_lampu = obor.create_tween().set_loops()
			var jeda_acak = randf_range(0.0, 0.2)
			tw_lampu.tween_property(lampu, "light_energy", 1.5, 0.1).set_delay(jeda_acak)
			tw_lampu.tween_property(lampu, "light_energy", 2.5, 0.15)
			tw_lampu.tween_property(lampu, "light_energy", 2.0, 0.1)
			
			var tw_api = obor.create_tween().set_loops()
			tw_api.tween_property(api, "scale", Vector3(1.2, 1.4, 1.2), 0.15).set_delay(jeda_acak)
			tw_api.tween_property(api, "scale", Vector3(0.8, 0.9, 0.8), 0.1)
			tw_api.tween_property(api, "scale", Vector3(1.0, 1.0, 1.0), 0.1)

func _setup_langit_malam():
	var env_node = WorldEnvironment.new()
	var env = Environment.new()
	var sky = Sky.new()
	var sky_mat = ProceduralSkyMaterial.new()
	
	sky_mat.sky_top_color = Color(0.02, 0.03, 0.08)
	sky_mat.sky_horizon_color = Color(0.05, 0.08, 0.15)
	sky_mat.ground_bottom_color = Color(0.01, 0.02, 0.05)
	sky_mat.ground_horizon_color = Color(0.03, 0.05, 0.1)
	
	if tingkat_grafis_saat_ini == "sangat_rendah":
		# Dengan langit prosedural, SETIAP piksel (pasir, laut, papan) ikut mengambil
		# pantulan langit — terukur ±13% waktu frame di Very Low. Langit malamnya
		# nyaris hitam, jadi warna polos hampir tidak bisa dibedakan.
		env.background_mode = Environment.BG_COLOR
		env.background_color = Color(0.03, 0.05, 0.11)
	else:
		sky.sky_material = sky_mat
		env.background_mode = Environment.BG_SKY
		env.sky = sky
	
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.2, 0.25, 0.4) 
	env.ambient_light_energy = 1.0 
	
	# Glow = efek layar penuh berlapis blur; di Low terukur ±19% waktu frame.
	if tingkat_grafis_saat_ini in ["rendah", "sangat_rendah"]:
		env.glow_enabled = false
		if tingkat_grafis_saat_ini == "rendah":
			# Dengan glow_bloom, glow ikut menerangkan SELURUH layar. Tanpa glow, Low
			# jadi jauh lebih gelap dari sebelumnya; exposure mengembalikan terangnya
			# (hampir tanpa biaya). Very Low memang sejak dulu tanpa glow — tidak diubah.
			env.tonemap_exposure = 1.8
	else:
		env.glow_enabled = true
		env.glow_intensity = 1.5
		env.glow_strength = 1.2
		env.glow_bloom = 0.2
		env.glow_blend_mode = Environment.GLOW_BLEND_MODE_ADDITIVE
	
	var bulan = DirectionalLight3D.new()
	bulan.light_color = Color(0.5, 0.7, 1.0) 
	bulan.light_energy = 0.6
	bulan.rotation_degrees = Vector3(-45, 120, 0)
	
	# PERBAIKAN: Gunakan bias presisi rendah agar tidak memicu garis shadow acne
	if tingkat_grafis_saat_ini == "tinggi":
		bulan.shadow_enabled = true
		bulan.shadow_normal_bias = 2.0
		bulan.shadow_bias = 0.03
	elif tingkat_grafis_saat_ini == "sedang":
		bulan.shadow_enabled = true
		bulan.shadow_normal_bias = 2.5
		bulan.shadow_bias = 0.04
		# Bawaan Godot: 4 irisan bayangan = semua objek digambar ulang 4x ke peta
		# bayangan. Satu peta saja (ORTHOGONAL) sudah cukup untuk kamera papan yang
		# menunduk ini (hemat ±22% waktu frame).
		bulan.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
		bulan.directional_shadow_max_distance = JARAK_BAYANGAN_SEDANG
	else:
		# Low & Very Low: tanpa bayangan bulan (sama seperti matahari di peta
		# Grassland). Di Low atlas bayangannya cuma 512 px — kotak-kotak, padahal
		# memakan ±31% waktu frame.
		bulan.shadow_enabled = false
		
	add_child(bulan)
	
	env_node.environment = env
	add_child(env_node)

func _setup_cahaya_kejauhan():
	# Lompat dan batalkan pembuatan lampu belakang pada mode Low & Very Low.
	# Jangkauannya 80 m, jadi hampir semua objek ikut menghitung ketiganya.
	if tingkat_grafis_saat_ini in ["rendah", "sangat_rendah"]:
		return 
		
	var posisi_lampu = [Vector3(-80, 2, -60), Vector3(-60, 2, -80), Vector3(-100, 2, -40)]
	for pos in posisi_lampu:
		var lampu_jauh = OmniLight3D.new()
		lampu_jauh.light_color = Color(1.0, 0.8, 0.4) 
		lampu_jauh.light_energy = 3.0
		lampu_jauh.omni_range = 80.0
		lampu_jauh.position = pos
		lampu_jauh.shadow_enabled = false 
		add_child(lampu_jauh)

# ========================================================
# FUNGSI BARU: RUMUS MATEMATIKA LENGKUNGAN PANTAI
# ========================================================
func _dapatkan_x_pantai_di_z(z: float) -> float:
	return posisi_x_pantai + (sin(z * 0.05) * 14.0) + (sin(z * 0.015) * 10.0)

func _dapatkan_y_pasir(x: float, z: float) -> float:
	var batas_air = _dapatkan_x_pantai_di_z(z)
	var jarak = batas_air - x
	if jarak < 0: return 0.0 
	
	var rasio = clamp(jarak / 15.0, 0.0, 1.0)
	
	# PERBAIKAN 1: Mengganti abs() dengan gelombang kurva halus.
	# Ini akan membasmi tekstur "waffle" bergaris secara permanen!
	var gelombang1 = sin(x * 0.15) * cos(z * 0.15)
	var bukit1 = ((gelombang1 + 1.0) / 2.0) * 0.15
	
	var gelombang2 = sin(x * 0.05) * cos(z * 0.05)
	var bukit2 = ((gelombang2 + 1.0) / 2.0) * 0.25
	
	return (bukit1 + bukit2) * rasio + (jarak * 0.005)

func _buat_mesh_daratan_solid() -> ArrayMesh:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_smooth_group(1) 
	
	var z_start = -250.0 
	var z_end = 250.0    
	var step_z = 2.5 
	
	var jumlah_z = int((z_end - z_start) / step_z)
	var batas_kiri = posisi_x_pantai - 120.0
	
	var jumlah_x = 45 
	if tingkat_grafis_saat_ini == "sangat_rendah":
		# Very Low menghitung cahaya pasir per-VERTEX (lihat _setup_laut_pasir), jadi
		# butuh titik yang cukup rapat (±3 m) agar lingkaran cahaya obor tetap bulat.
		# Menambah titik di sini jauh lebih murah daripada cahaya per-piksel.
		jumlah_x = 40
	elif tingkat_grafis_saat_ini == "rendah":
		jumlah_x = 25
	elif tingkat_grafis_saat_ini == "sedang":
		jumlah_x = 40
	elif tingkat_grafis_saat_ini == "tinggi":
		jumlah_x = 60
	
	var grid_indeks: Array = []
	var indeks_vertex_sekarang = 0 
	
	for zi in range(jumlah_z + 1):
		var baris_indeks: Array[int] = []
		var current_z = z_start + (zi * step_z)
		var batas_air = _dapatkan_x_pantai_di_z(current_z)
		
		for xi in range(jumlah_x + 1):
			var t = float(xi) / float(jumlah_x)
			var x_pos = lerp(batas_kiri, batas_air, t)
			var y_pos = _dapatkan_y_pasir(x_pos, current_z)
			
			st.set_uv(Vector2(t, float(zi) / float(jumlah_z)))
			st.add_vertex(Vector3(x_pos, y_pos, current_z))
			
			baris_indeks.append(indeks_vertex_sekarang)
			indeks_vertex_sekarang += 1 
			
		grid_indeks.append(baris_indeks)
		
	for zi in range(jumlah_z):
		for xi in range(jumlah_x):
			var idx_kiri_atas = grid_indeks[zi][xi]
			var idx_kanan_atas = grid_indeks[zi][xi + 1]
			var idx_kiri_bawah = grid_indeks[zi + 1][xi]
			var idx_kanan_bawah = grid_indeks[zi + 1][xi + 1]
			
			# URUTAN DIBALIK SEARAH JARUM JAM AGAR DARATAN KEMBALI MUNCUL
			st.add_index(idx_kiri_atas)
			st.add_index(idx_kanan_atas)
			st.add_index(idx_kiri_bawah)
			
			st.add_index(idx_kiri_bawah)
			st.add_index(idx_kanan_atas)
			st.add_index(idx_kanan_bawah)
				
	st.generate_normals()
	return st.commit()

func _buat_mesh_pita(lebar_ke_kiri: float, lebar_ke_kanan: float) -> ArrayMesh:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_smooth_group(1) 
	
	var z_start = -250.0 
	var z_end = 250.0    
	var step_z = 2.5
	var jumlah_z = int((z_end - z_start) / step_z)
	
	var grid_indeks: Array = []
	var indeks_vertex_sekarang = 0
	
	for zi in range(jumlah_z + 1):
		var baris: Array[int] = []
		var current_z = z_start + (zi * step_z)
		var batas_air = _dapatkan_x_pantai_di_z(current_z)
		
		var kiri = batas_air - lebar_ke_kiri
		var kanan = batas_air + lebar_ke_kanan
		
		var y_kiri = _dapatkan_y_pasir(kiri, current_z)
		var y_kanan = _dapatkan_y_pasir(kanan, current_z)
		
		st.set_uv(Vector2(0.0, float(zi) / float(jumlah_z)))
		st.add_vertex(Vector3(kiri, y_kiri, current_z))
		baris.append(indeks_vertex_sekarang)
		indeks_vertex_sekarang += 1
		
		st.set_uv(Vector2(1.0, float(zi) / float(jumlah_z)))
		st.add_vertex(Vector3(kanan, y_kanan, current_z))
		baris.append(indeks_vertex_sekarang)
		indeks_vertex_sekarang += 1
		
		grid_indeks.append(baris)
		
	for zi in range(jumlah_z):
		var idx_kiri1 = grid_indeks[zi][0]
		var idx_kanan1 = grid_indeks[zi][1]
		var idx_kiri2 = grid_indeks[zi + 1][0]
		var idx_kanan2 = grid_indeks[zi + 1][1]
		
		# URUTAN DIBALIK SEARAH JARUM JAM
		st.add_index(idx_kiri1)
		st.add_index(idx_kanan1)
		st.add_index(idx_kiri2)
		
		st.add_index(idx_kiri2)
		st.add_index(idx_kanan1)
		st.add_index(idx_kanan2)
		
	st.generate_normals()
	return st.commit()

# ========================================================
# PERBAIKAN FUNGSI PEMBANGUNAN LAUT, PASIR, DAN OMBAK
# ========================================================
var node_pasir_basah: MeshInstance3D
var mat_pasir_basah: StandardMaterial3D

func _setup_laut_pasir():
	var laut = MeshInstance3D.new()
	var mesh_laut = BoxMesh.new()
	mesh_laut.size = Vector3(800, 1, 1000) 
	laut.mesh = mesh_laut
	laut.position = Vector3(posisi_x_pantai + 200, level_tanah - 1.2, 0)
	
	var mat_laut = StandardMaterial3D.new()
	mat_laut.albedo_color = Color(0.05, 0.15, 0.35) 
	mat_laut.roughness = 0.1 
	mat_laut.metallic = 0.8
	laut.material_override = mat_laut
	if tingkat_grafis_saat_ini in ["rendah", "sangat_rendah"]:
		laut.layers = 1 << (LAYER_LAUT - 1) # tidak disinari obor, lihat _sebar_obor_sekitar_papan
	if tingkat_grafis_saat_ini != "tinggi":
		# Laut & pasir hanyalah alas: bayangan yang mereka jatuhkan tidak kelihatan,
		# tapi tetap ikut digambar ke peta bayangan bulan (Medium).
		laut.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(laut)
	
	var pasir = MeshInstance3D.new()
	pasir.mesh = _buat_mesh_daratan_solid()
	pasir.position = Vector3(0, level_tanah - 0.6, 0) 
	
	var mat_pasir = StandardMaterial3D.new()
	mat_pasir.albedo_color = Color(0.42, 0.36, 0.28) 
	mat_pasir.roughness = 0.95
	mat_pasir.cull_mode = BaseMaterial3D.CULL_BACK
	if tingkat_grafis_saat_ini == "sangat_rendah":
		# Pasir menutupi hampir seluruh layar dan disinari semua lampu obor. Cahaya
		# dihitung per titik mesh (±8 ribu) alih-alih per piksel layar.
		mat_pasir.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
	pasir.material_override = mat_pasir
	if tingkat_grafis_saat_ini != "tinggi":
		pasir.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(pasir)

	node_pasir_basah = MeshInstance3D.new()
	node_pasir_basah.mesh = _buat_mesh_pita(3.0, 0.0) 
	node_pasir_basah.position = Vector3(0, level_tanah - 0.59, 0) 
	
	mat_pasir_basah = StandardMaterial3D.new()
	mat_pasir_basah.albedo_color = Color(0.2, 0.16, 0.12) 
	mat_pasir_basah.roughness = 0.15 
	mat_pasir_basah.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_pasir_basah.albedo_color.a = 0.0 
	mat_pasir_basah.cull_mode = BaseMaterial3D.CULL_BACK
	node_pasir_basah.material_override = mat_pasir_basah
	add_child(node_pasir_basah)

	if not is_instance_valid(node_ombak):
		node_ombak = MeshInstance3D.new()
		
	node_ombak.mesh = _buat_mesh_pita(3.5, 3.5) 
	node_ombak.position = Vector3(0, level_tanah - 0.58, 0) 

	mat_ombak = StandardMaterial3D.new()
	mat_ombak.albedo_color = Color(0.0, 0.6, 1.0, 0.0) 
	mat_ombak.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_ombak.emission_enabled = true
	mat_ombak.emission = Color(0.0, 0.6, 1.0)
	mat_ombak.cull_mode = BaseMaterial3D.CULL_BACK
	node_ombak.material_override = mat_ombak
	
	if node_ombak.get_parent() == null:
		add_child(node_ombak)

	# PEMPANGGILAN FUNGSI BARU OMBAK KECIL LAUT
	_setup_ombak_kecil_laut()

func _jalankan_siklus_ombak():
	if not is_instance_valid(node_ombak): return
	
	var tw = node_ombak.create_tween()
	node_ombak.position.x = 2.0 

	# FASE 1: Ombak Naik
	tw.tween_property(node_ombak, "position:x", -2.0, 3.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(mat_ombak, "albedo_color:a", 0.7, 3.5)
	tw.parallel().tween_property(mat_ombak, "emission_energy_multiplier", 3.0, 3.5)
	tw.parallel().tween_property(mat_pasir_basah, "albedo_color:a", 1.0, 2.5).set_delay(1.0) 

	# FASE 2: Ombak Turun
	tw.tween_property(node_ombak, "position:x", 2.0, 4.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.parallel().tween_property(mat_ombak, "albedo_color:a", 0.0, 4.5)
	tw.parallel().tween_property(mat_pasir_basah, "albedo_color:a", 0.0, 3.5).set_delay(1.0) 

	# Panggilan ulang tanpa parameter suara
	tw.tween_callback(Callable(self, "_jalankan_siklus_ombak"))

func _sebar_pohon_kelapa():
	var jumlah_pohon = 40 if tingkat_grafis_saat_ini != "sangat_rendah" else 15
	var pohon_terbuat = 0
	var batas_loop = jumlah_pohon * 30 
	
	while pohon_terbuat < jumlah_pohon and batas_loop > 0:
		batas_loop -= 1
		
		var pos_x = 0.0
		var pos_z = 0.0
		var isValid = false
		
		if randf() < 0.25:
			pos_z = randf_range(-150.0, 150.0)
			var batas_air_x = _dapatkan_x_pantai_di_z(pos_z) 
			pos_x = batas_air_x - randf_range(3.0, 15.0) 
			isValid = true
		else:
			if daftar_posisi_petak.size() > 0:
				var petak_acak = daftar_posisi_petak.pick_random()
				var sudut = randf_range(0, TAU)
				var jarak = randf_range(10.0, 45.0) 
				
				pos_x = petak_acak.x + (cos(sudut) * jarak)
				pos_z = petak_acak.y + (sin(sudut) * jarak)
				
				var batas_air_x = _dapatkan_x_pantai_di_z(pos_z)
				if pos_x < batas_air_x - 4.0:
					isValid = true
			else:
				pos_z = randf_range(-150.0, 150.0)
				var batas_air_x = _dapatkan_x_pantai_di_z(pos_z) 
				pos_x = randf_range(posisi_x_pantai - 80.0, batas_air_x - 4.0)
				isValid = true
				
		if not isValid:
			continue
		
		var pos_global_2d = Vector2(pos_x, pos_z)
		
		if _apakah_di_luar_zona_aman(pos_global_2d, 6.5):
			var pohon = Node3D.new()
			add_child(pohon) 
			
			var elevasi_pasir = _dapatkan_y_pasir(pos_global_2d.x, pos_global_2d.y)
			var y_pasir_asli = self.global_position.y + (level_tanah - 0.6) + elevasi_pasir
			pohon.global_position = Vector3(pos_global_2d.x, y_pasir_asli - 0.3, pos_global_2d.y)
			
			var engsel_batang = Node3D.new()
			
			var awal_rot_x = randf_range(-15.0, 15.0)
			var awal_rot_z = randf_range(-5.0, 20.0) 
			
			engsel_batang.rotation_degrees.x = awal_rot_x
			engsel_batang.rotation_degrees.z = awal_rot_z
			pohon.add_child(engsel_batang)
			
			var batang = MeshInstance3D.new()
			var m_batang = CylinderMesh.new()
			m_batang.top_radius = 0.2
			m_batang.bottom_radius = 0.4
			m_batang.height = randf_range(7.0, 10.0)
			
			# Mengubah resolusi lengkungan tabung secara efisien
			if tingkat_grafis_saat_ini == "sangat_rendah":
				m_batang.radial_segments = 4
			elif tingkat_grafis_saat_ini == "rendah":
				m_batang.radial_segments = 5
			elif tingkat_grafis_saat_ini == "tinggi":
				m_batang.radial_segments = 12
			else:
				m_batang.radial_segments = 8
				
			batang.mesh = m_batang
			batang.material_override = mat_batang_kelapa
			batang.position.y = m_batang.height / 2.0
			engsel_batang.add_child(batang)
			
			var puncak_batang = Vector3(0, m_batang.height / 2.0, 0)
			
			var durasi_ayun = randf_range(2.5, 4.5)
			var jeda_angin = randf_range(3.0, 7.0) 
			var waktu_batang_aktif = durasi_ayun + (durasi_ayun * 0.9)
			var custom_start_acak = randf_range(0.0, 2.0)
			
			for j in range(5):
				var engsel_daun = Node3D.new()
				engsel_daun.position = puncak_batang
				
				var awal_rot_daun_y = (360.0 / 5) * j + randf_range(-15, 15)
				var awal_rot_daun_z = randf_range(-25, -45)
				var awal_rot_daun_x = randf_range(-5.0, 5.0)
				
				engsel_daun.rotation_degrees = Vector3(awal_rot_daun_x, awal_rot_daun_y, awal_rot_daun_z)
				batang.add_child(engsel_daun)
				
				var daun = MeshInstance3D.new()
				var m_daun = BoxMesh.new()
				m_daun.size = Vector3(3.5, 0.05, 1.2)
				daun.mesh = m_daun
				daun.material_override = mat_daun_kelapa
				daun.position = Vector3(1.5, 0, 0) 
				engsel_daun.add_child(daun)
				
				# Daun hanya bergerak tertiup angin jika mode grafis mampu menahan ratusan Tween memory.
				# Low: daun diam (5 tween per pohon), tapi tetap ikut bergoyang bersama batangnya.
				if tingkat_grafis_saat_ini in ["tinggi", "sedang"]:
					var tw_daun = engsel_daun.create_tween().set_loops()
					var durasi_daun = randf_range(0.9, 1.4)
					
					var target_rot_daun_z = awal_rot_daun_z + randf_range(8.0, 18.0)
					var target_rot_daun_x = awal_rot_daun_x + randf_range(-6.0, 6.0)
					
					tw_daun.tween_property(engsel_daun, "rotation_degrees", Vector3(target_rot_daun_x, awal_rot_daun_y, target_rot_daun_z), durasi_daun).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
					tw_daun.tween_property(engsel_daun, "rotation_degrees", Vector3(awal_rot_daun_x, awal_rot_daun_y, awal_rot_daun_z), durasi_daun * 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
					tw_daun.tween_property(engsel_daun, "rotation_degrees", Vector3(target_rot_daun_x, awal_rot_daun_y, target_rot_daun_z), durasi_daun * 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
					tw_daun.tween_property(engsel_daun, "rotation_degrees", Vector3(awal_rot_daun_x, awal_rot_daun_y, awal_rot_daun_z), durasi_daun * 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
					
					var waktu_daun_aktif = durasi_daun + (durasi_daun * 0.8) + (durasi_daun * 0.9) + (durasi_daun * 0.8)
					var sisa_waktu = max(0.0, waktu_batang_aktif - waktu_daun_aktif)
					
					tw_daun.tween_interval(sisa_waktu + jeda_angin)
					tw_daun.custom_step(custom_start_acak)
				
			# Batang juga menjadi kaku seperti patung khusus untuk Very Low 
			if tingkat_grafis_saat_ini != "sangat_rendah":
				var tw_angin = engsel_batang.create_tween().set_loops()
				var target_rot_z = awal_rot_z + randf_range(4.0, 7.0)
				var target_rot_x = awal_rot_x + randf_range(-2.0, 2.0) 
				
				tw_angin.tween_property(engsel_batang, "rotation_degrees", Vector3(target_rot_x, 0, target_rot_z), durasi_ayun).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
				tw_angin.tween_property(engsel_batang, "rotation_degrees", Vector3(awal_rot_x, 0, awal_rot_z), durasi_ayun * 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
				
				tw_angin.tween_interval(jeda_angin)
				tw_angin.custom_step(custom_start_acak)
				
			pohon_terbuat += 1

func _buat_bioluminescence():
	# Kode partikel kotak dihapus. Memanggil efek ombak bercahaya langsung.
	_animasi_ombak_dan_glow()

func _sebar_batu_karang():
	var batu_terbuat = 0
	var batas_loop = 150
	var pusat_global = Vector2(self.global_position.x, self.global_position.z)
	
	# SphereMesh bawaan = 64x32 segmen (±4 ribu segitiga) per batu kecil. Di bawah
	# "tinggi" semua batu memakai SATU mesh bersama yang jauh lebih ringan.
	var mesh_batu_ringan: SphereMesh = null
	if tingkat_grafis_saat_ini != "tinggi":
		mesh_batu_ringan = SphereMesh.new()
		match tingkat_grafis_saat_ini:
			"sangat_rendah":
				mesh_batu_ringan.radial_segments = 8
				mesh_batu_ringan.rings = 4
			"rendah":
				mesh_batu_ringan.radial_segments = 10
				mesh_batu_ringan.rings = 5
			_:
				mesh_batu_ringan.radial_segments = 16
				mesh_batu_ringan.rings = 8

	while batu_terbuat < 15 and batas_loop > 0:
		batas_loop -= 1
		# DIKUNCI DI SISI KIRI HINGGA TEPIAN AIR
		var pos_z = randf_range(-60.0, 60.0)
		var batas_air_x = _dapatkan_x_pantai_di_z(pos_z)
		var pos_x = randf_range(-50.0, batas_air_x)
		var pos_global_2d = pusat_global + Vector2(pos_x, pos_z)
		
		if _apakah_di_luar_zona_aman(pos_global_2d, 5.0):
			var batu = MeshInstance3D.new()
			batu.mesh = mesh_batu_ringan if mesh_batu_ringan else SphereMesh.new()
			batu.scale = Vector3(randf_range(1,2.5), randf_range(0.8, 1.5), randf_range(1,2.5))
			batu.material_override = mat_batu_global
			add_child(batu)
			batu.global_position = Vector3(pos_global_2d.x, self.global_position.y + level_tanah, pos_global_2d.y)
			batu_terbuat += 1

func _animasi_ombak_dan_glow():
	if not is_instance_valid(node_ombak):
		return

	# Pembuat suara ombak telah dihapus
	_jalankan_siklus_ombak()

# ========================================================
# PEMBUATAN DERMAGA 3D OTOMATIS + PAGAR TALI
# ========================================================
func _bangun_dermaga(petak: Node3D):
	var ukuran_x = 2.0
	var ukuran_z = 2.0
	var node_lantai = petak.get_child(0) if petak.get_child_count() > 0 else null

	if node_lantai:
		if "size" in node_lantai:
			ukuran_x = node_lantai.size.x
			ukuran_z = node_lantai.size.z
		elif node_lantai is MeshInstance3D and node_lantai.mesh:
			var aabb = node_lantai.mesh.get_aabb()
			ukuran_x = aabb.size.x
			ukuran_z = aabb.size.z

	var grup_dermaga: Node3D
	if tingkat_grafis_saat_ini == "tinggi":
		grup_dermaga = Node3D.new()
	else:
		# Setiap potongan CSG yang berdiri sendiri = mesh & draw call sendiri (±18 per
		# dermaga, ±200 untuk seluruh dermaga). Di bawah satu CSGCombiner3D semuanya
		# dilebur jadi SATU mesh: 3 draw call per dermaga (satu per material).
		# Bentuk & warnanya sama persis.
		grup_dermaga = CSGCombiner3D.new()
	grup_dermaga.name = "DermagaKayu"
	
	var mat_kayu = StandardMaterial3D.new()
	mat_kayu.albedo_color = Color(0.25, 0.15, 0.08) 
	mat_kayu.roughness = 0.95
	
	var mat_beton = StandardMaterial3D.new()
	mat_beton.albedo_color = Color(0.65, 0.65, 0.6) 
	mat_beton.roughness = 0.9
	
	var mat_tali = StandardMaterial3D.new()
	mat_tali.albedo_color = Color(0.75, 0.6, 0.4) 
	mat_tali.roughness = 1.0

	# 1. Alas Kayu (Dipertebal Sedikit)
	var alas = CSGBox3D.new()
	alas.size = Vector3(ukuran_x * 0.98, 0.20, ukuran_z * 0.98) # size x dan z dari 0.96 jadi 0.98, tebal y dari 0.15 jadi 0.20
	alas.position.y = -0.15 # Diturunkan sedikit dari -0.08 ke -0.10 agar sejajar proporsi ketebalan baru
	alas.material_override = mat_kayu
	grup_dermaga.add_child(alas)
	
	# 2. Tiang Penyangga dan Pembatas (Diperbesar Ekstra)
	var radius_tiang = 0.5 # Diperbesar dari 0.16
	var panjang_tiang_bawah = 9.0 
	var offset_x = (ukuran_x / 2.0) - radius_tiang - 0.05
	var offset_z = (ukuran_z / 2.0) - radius_tiang - 0.05
	
	var C1 = Vector3(-offset_x, 0, -offset_z)
	var C2 = Vector3(offset_x, 0, -offset_z)
	var C3 = Vector3(offset_x, 0, offset_z)
	var C4 = Vector3(-offset_x, 0, offset_z)
	
	var posisi_sudut = [C1, C2, C3, C4]
	
	for pos in posisi_sudut:
		# Tiang Bawah (Penyangga)
		var tiang_bawah = CSGCylinder3D.new()
		tiang_bawah.radius = radius_tiang # 0.22
		tiang_bawah.height = panjang_tiang_bawah
		tiang_bawah.position = pos + Vector3(0, -panjang_tiang_bawah / 2.0, 0)
		tiang_bawah.material_override = mat_beton 
		tiang_bawah.smooth_faces = true
		grup_dermaga.add_child(tiang_bawah)
		
		# Tiang Atas (Pembatas)
		var tiang_atas = CSGCylinder3D.new()
		tiang_atas.radius = 0.4 # Diperbesar dari 0.12
		tiang_atas.height = 2.5 # Ditinggikan proporsional
		tiang_atas.position = pos + Vector3(0, 0.375, 0)
		tiang_atas.material_override = mat_beton
		tiang_atas.smooth_faces = true
		grup_dermaga.add_child(tiang_atas)
		
		# Tutup Kepala Tiang Atas
		var tutup = CSGSphere3D.new()
		tutup.radius = 0.4 # Menyesuaikan radius tiang atas baru
		tutup.position = Vector3(0, 0.375, 0)
		tutup.material_override = mat_beton
		tiang_atas.add_child(tutup)

	# 3. Logika Deteksi Tetangga Matematis (Tetap)
	var pos_global_2d = Vector2(petak.global_position.x, petak.global_position.z)
	var skala_global = petak.global_transform.basis.get_scale()
	var toleransi_jarak = max(ukuran_x * skala_global.x, ukuran_z * skala_global.z) * 1.5 
	
	var cek_tetangga = func(arah_x: float, arah_z: float) -> bool:
		var arah_cek = Vector2(arah_x, arah_z).normalized()
		for p in daftar_posisi_petak:
			var jarak = pos_global_2d.distance_to(p)
			if jarak > 0.1 and jarak <= toleransi_jarak:
				var arah_ke_p = (p - pos_global_2d).normalized()
				if arah_ke_p.dot(arah_cek) > 0.85:
					return true
		return false

	# 4. Tali Tambang (Dipertebal Menyesuaikan Tiang)
	var buat_pagar_tali = func(pos1: Vector3, pos2: Vector3):
		var p1 = pos1 + Vector3(0, 1.5, 0) # Titik ikat dinaikkan ke 0.60 mengikuti tinggi tiang
		var p4 = pos2 + Vector3(0, 1.5, 0)
		
		var p2 = p1.lerp(p4, 0.33)
		p2.y -= 0.18 
		var p3 = p1.lerp(p4, 0.66)
		p3.y -= 0.18 

		var titik_tali = [p1, p2, p3, p4]
		for i in range(3):
			var awal = titik_tali[i]
			var akhir = titik_tali[i+1]
			var jarak = awal.distance_to(akhir)
			
			var segmen = CSGCylinder3D.new()
			segmen.radius = 0.05 # Tali dipertebal dari 0.04 menjadi 0.05
			segmen.height = jarak
			segmen.material_override = mat_tali
			segmen.smooth_faces = true
			
			var arah = (akhir - awal).normalized()
			var up_vec = Vector3.UP
			if abs(arah.y) > 0.99: up_vec = Vector3.RIGHT
			
			# Ganti 'basis' menjadi 'basis_tali'
			var basis_tali = Basis.looking_at(arah, up_vec)
			basis_tali = basis_tali * Basis.from_euler(Vector3(PI / 2.0, 0, 0))
			
			segmen.transform = Transform3D(basis_tali, (awal + akhir) / 2.0)
			grup_dermaga.add_child(segmen)

	# 5. Eksekusi Pemasangan (Tetap)
	if not cek_tetangga.call(0, -1): buat_pagar_tali.call(C1, C2) # Utara
	if not cek_tetangga.call(1, 0):  buat_pagar_tali.call(C2, C3) # Timur
	if not cek_tetangga.call(0, 1):  buat_pagar_tali.call(C3, C4) # Selatan
	if not cek_tetangga.call(-1, 0): buat_pagar_tali.call(C4, C1) # Barat

	if grup_dermaga is CSGCombiner3D:
		# Di dalam combiner hanya node akar yang menggambar, jadi material_override
		# milik tiap potongan diabaikan Godot. Warnanya dibawa lewat 'material'.
		for potongan in grup_dermaga.find_children("*", "CSGPrimitive3D", true, false):
			potongan.material = potongan.material_override
	
	petak.call_deferred("add_child", grup_dermaga)

# ========================================================
# 1. PEMBUAT MESH BUIH OMBAK 3D
# ========================================================
func _buat_mesh_patch_ombak(panjang_z: float, radius: float) -> ArrayMesh:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_smooth_group(1)

	var segmen_z = 10
	var segmen_rad = 8

	var grid_indeks: Array = []
	var indeks_sekarang = 0

	for r in range(segmen_rad + 1):
		var baris: Array[int] = []
		var sudut = (float(r) / float(segmen_rad)) * TAU
		var cos_s = cos(sudut)
		var sin_s = sin(sudut)

		for zi in range(segmen_z + 1):
			var tz = float(zi) / float(segmen_z)
			var rel_z = (tz - 0.5) * panjang_z

			var skala_ujung = sin(tz * PI)
			var rad_aktual = radius * skala_ujung

			var distorsi = 1.0 + (sin(tz * PI * 4.0 + sudut * 3.0) * 0.25)
			rad_aktual *= distorsi

			var pos_x = cos_s * rad_aktual
			var pos_y = sin_s * rad_aktual

			var kelengkungan = sin(tz * PI) * 0.8
			pos_x -= kelengkungan

			st.set_uv(Vector2(float(r)/segmen_rad, tz))
			st.add_vertex(Vector3(pos_x, pos_y, rel_z))

			baris.append(indeks_sekarang)
			indeks_sekarang += 1

		grid_indeks.append(baris)

	for r in range(segmen_rad):
		for zi in range(segmen_z):
			var i_ka = grid_indeks[r][zi]
			var i_kna = grid_indeks[r + 1][zi]
			var i_kb = grid_indeks[r][zi + 1]
			var i_knb = grid_indeks[r + 1][zi + 1]

			st.add_index(i_ka)
			st.add_index(i_kna)
			st.add_index(i_kb)

			st.add_index(i_kb)
			st.add_index(i_kna)
			st.add_index(i_knb)

	st.generate_normals()
	return st.commit()

# ========================================================
# 2. PENGATUR PENYEBARAN OMBAK INDIVIDUAL SEPANJANG PANTAI
# ========================================================
func _setup_ombak_kecil_laut():
	var ombak_lama = get_node_or_null("GrupOmbakKecil")
	if ombak_lama:
		ombak_lama.queue_free()

	var grup_ombak = Node3D.new()
	grup_ombak.name = "GrupOmbakKecil"
	add_child(grup_ombak)

	var jumlah_ombak_pantai = 25
	if tingkat_grafis_saat_ini == "sangat_rendah":
		jumlah_ombak_pantai = 8
	elif tingkat_grafis_saat_ini == "rendah":
		jumlah_ombak_pantai = 15

	var mesh_patch = _buat_mesh_patch_ombak(3.5, 0.35)

	# 1. Sebar ombak secara acak di sepanjang garis pantai (Z: -200 hingga 200)
	for i in range(jumlah_ombak_pantai):
		var z_pos = randf_range(-190.0, 190.0)
		_buat_satu_ombak(grup_ombak, mesh_patch, z_pos)

	# 2. Sebar ombak ekstra secara spesifik di area dermaga
	if daftar_posisi_petak.size() > 0:
		var jumlah_ombak_dermaga = 12 if tingkat_grafis_saat_ini != "sangat_rendah" else 4
		for i in range(jumlah_ombak_dermaga):
			var petak_acak = daftar_posisi_petak.pick_random()
			# Z di sekitar petak dermaga
			var z_pos = petak_acak.y + randf_range(-8.0, 8.0) 
			_buat_satu_ombak(grup_ombak, mesh_patch, z_pos)

# ========================================================
# 3. PEMBUAT INSTANCE SATU OMBAK DENGAN PIVOT
# ========================================================
func _buat_satu_ombak(grup: Node3D, mesh: Mesh, z_pos: float):
	var pivot = Node3D.new() 
	
	# PERBAIKAN: Ubah nama variabel agar tidak membentur variabel global
	var instance_ombak = MeshInstance3D.new()
	instance_ombak.mesh = mesh
	
	var skala_acak = randf_range(0.7, 1.2)
	instance_ombak.set_meta("skala_asli", Vector3(skala_acak, skala_acak, skala_acak))
	instance_ombak.scale = Vector3.ZERO
	
	var mat_k = StandardMaterial3D.new()
	mat_k.albedo_color = Color(0.85, 0.9, 0.95, 0.0)
	mat_k.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_k.roughness = 1.0
	mat_k.emission_enabled = false
	mat_k.cull_mode = BaseMaterial3D.CULL_BACK
	instance_ombak.material_override = mat_k
	
	pivot.add_child(instance_ombak)
	grup.add_child(pivot)
	
	var jeda_awal = randf_range(0.0, 12.0)
	_animasi_ombak_individual(pivot, instance_ombak, mat_k, z_pos, jeda_awal)

# ========================================================
# 4. ANIMASI GULUNGAN DAN PECAHAN OMBAK INDIVIDUAL
# ========================================================
func _animasi_ombak_individual(pivot: Node3D, instance_ombak: MeshInstance3D, mat_k: StandardMaterial3D, z_pos: float, jeda: float):
	var durasi_siklus = randf_range(7.0, 10.0)
	var tw_loop = pivot.create_tween().set_loops()
	
	if jeda > 0.0:
		tw_loop.tween_interval(jeda)
		
	var x_pantai = _dapatkan_x_pantai_di_z(z_pos)
	var x_start = x_pantai + randf_range(30.0, 50.0) 
	var x_pudar = x_pantai + randf_range(4.0, 8.0)                  
	var skala_asli = instance_ombak.get_meta("skala_asli")

	tw_loop.tween_callback(func():
		pivot.position = Vector3(x_start, level_tanah - 0.55, z_pos)
		instance_ombak.rotation_degrees = Vector3.ZERO
		instance_ombak.scale = Vector3.ZERO
		mat_k.albedo_color.a = 0.0
	)

	var durasi_muncul = durasi_siklus * 0.3
	var durasi_jalan = durasi_siklus * 0.4
	var durasi_pecah = durasi_siklus * 0.3
	
	var total_durasi_jalan = durasi_muncul + durasi_jalan

	tw_loop.tween_property(pivot, "position:x", x_pudar + 8.0, total_durasi_jalan).set_trans(Tween.TRANS_LINEAR)
	tw_loop.parallel().tween_property(instance_ombak, "rotation_degrees:z", 1080.0, total_durasi_jalan)
	
	tw_loop.parallel().tween_property(instance_ombak, "scale", skala_asli, durasi_muncul)
	tw_loop.parallel().tween_property(mat_k, "albedo_color:a", randf_range(0.65, 0.85), durasi_muncul)

	var skala_pecah = Vector3(skala_asli.x * 1.5, skala_asli.y * 0.1, skala_asli.z * 1.2)
	tw_loop.tween_property(pivot, "position:x", x_pudar, durasi_pecah).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw_loop.parallel().tween_property(instance_ombak, "scale", skala_pecah, durasi_pecah)
	tw_loop.parallel().tween_property(mat_k, "albedo_color:a", 0.0, durasi_pecah)

	tw_loop.tween_interval(randf_range(3.0, 6.0))
