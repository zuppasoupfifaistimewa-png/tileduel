extends Node3D
class_name LingkunganAlam

# --- PARAMETER ---
var radius_maksimal = 60.0 # Turun drastis dari 250.0
var jumlah_rumput = 3000 # Disesuaikan dengan area yang menyusut
var jumlah_objek = 40 # Turun dari 80 agar jarak antar pohon tetap natural
var level_tanah = -0.6       

# MENGATUR AREA PONDASI PAPAN (KOTAK ZONA AMAN)
var batas_aman_x = 10.0
var batas_aman_z = 8.0

# --- TAMBAHAN: MEMORI POSISI PETAK ---
var daftar_posisi_petak: Array[Vector2] = []

# --- VARIABEL AWAN DINAMIS ---
var daftar_awan_bebas: Array[Node3D] = []
var daftar_awan_kawal: Array[Node3D] = []
# Kecepatan awan sedikit diturunkan agar lebih rileks
var kecepatan_angin = Vector3(1.5, 0.0, 1.0) 
var daftar_pohon: Array[Node3D] = []
var mat_batang_global = StandardMaterial3D.new()
var mat_daun_global = StandardMaterial3D.new()
var mat_batu_global = StandardMaterial3D.new()
var tingkat_grafis_saat_ini = "sedang"

func _ready():
	add_to_group("grup_lingkungan")
	seed("JintoriPeta1".hash())
	
	var config = ConfigFile.new()
	if config.load("user://seting_grafis.cfg") == OK:
		tingkat_grafis_saat_ini = config.get_value("Pengaturan", "kualitas_grafik", "sedang")
		
	# SETING MATERIAL GLOBAL SEKALI SAJA UNTUK MODE LOW
	mat_batang_global.albedo_color = Color(0.4, 0.25, 0.1)
	mat_daun_global.albedo_color = Color(0.3, 0.65, 0.15)
	mat_daun_global.roughness = 1.0
	mat_batu_global.albedo_color = Color(0.5, 0.5, 0.5)
	mat_batu_global.roughness = 0.9
	
	# MENGATUR JUMLAH RUMPUT
	if tingkat_grafis_saat_ini == "sangat_rendah":
		jumlah_rumput = 0
	elif tingkat_grafis_saat_ini == "rendah":
		jumlah_rumput = 800
	elif tingkat_grafis_saat_ini == "sedang":
		jumlah_rumput = 2500
	else:
		jumlah_rumput = 15000
	
	_aktifkan_bayangan_global()
	_setup_langit()
	_setup_tanah_dasar()
	
	# Tunda penyebaran alam agar script Pemain selesai memuat rute_papan
	call_deferred("_mulai_sebar_alam")

func _mulai_sebar_alam():
	# Ambil data posisi semua petak dari Node Pemain (yang ada di grup_pemain)
	var grup_pemain = get_tree().get_nodes_in_group("grup_pemain")
	if grup_pemain.size() > 0 and "rute_papan" in grup_pemain[0]:
		for petak in grup_pemain[0].rute_papan:
			if is_instance_valid(petak):
				# Simpan posisi X dan Z dari setiap petak
				daftar_posisi_petak.append(Vector2(petak.global_position.x, petak.global_position.z))

	_sebar_objek_alam()
	
	if tingkat_grafis_saat_ini != "sangat_rendah":
		_buat_padang_rumput()
		_spawn_burung_acak()
	
	if not tingkat_grafis_saat_ini in ["rendah", "sangat_rendah"]:
		_buat_awan_kawal_tengah(2)
		_buat_awan_bebas(6 if tingkat_grafis_saat_ini == "sedang" else 15)
	else:
		set_process(false)
	
	_terapkan_efek_lingkungan_saat_boot()       

func _process(delta):
	# 1. Gerakkan Awan Kawal (Khusus untuk melintasi tengah)
	for awan in daftar_awan_kawal:
		awan.position += kecepatan_angin * delta
		
		if awan.position.x > 40.0 or awan.position.z > 40.0:
			awan.position.x = randf_range(-50.0, -30.0)
			awan.position.z = randf_range(-50.0, -30.0)

	# 2. Gerakkan Awan Bebas (Lebih dekat ke jangkauan pandang)
	for awan in daftar_awan_bebas:
		awan.position += kecepatan_angin * delta
		if awan.position.x > 70.0 or awan.position.z > 70.0:
			awan.position.x = randf_range(-70.0, -40.0)
			awan.position.z = randf_range(-70.0, -40.0)

func _aktifkan_bayangan_global():
	var lampu_matahari = null
	for node in get_parent().get_children():
		if node is DirectionalLight3D:
			lampu_matahari = node
			break
			
	if lampu_matahari:
		lampu_matahari.shadow_enabled = true
		lampu_matahari.shadow_blur = 0.1
				
		# --- MENGATUR SUDUT MATAHARI ---
		lampu_matahari.rotation_degrees = Vector3(-60, 45, 0)

func _racik_bentuk_awan_realistis() -> Node3D:
	var awan = Node3D.new()
	var skala = randf_range(0.5, 1.0) 
	var jumlah_gelembung = randi_range(4, 8)
	
	for j in range(jumlah_gelembung):
		var gumpalan = MeshInstance3D.new()
		var mesh_g = SphereMesh.new()
		mesh_g.radius = randf_range(1.5, 3.0) * skala
		mesh_g.height = mesh_g.radius * 2.0
		
		# PANGKAS POLIGON AWAN BERDASARKAN KUALITAS STATIS
		if tingkat_grafis_saat_ini in ["rendah", "sangat_rendah"]:
			mesh_g.radial_segments = 6
			mesh_g.rings = 3
		elif tingkat_grafis_saat_ini == "sedang":
			mesh_g.radial_segments = 12
			mesh_g.rings = 6
		else:
			mesh_g.radial_segments = 32
			mesh_g.rings = 16
			
		gumpalan.mesh = mesh_g
		var pos_x = randf_range(-3.0, 3.0) * skala
		var pos_z = randf_range(-2.0, 2.0) * skala
		var pos_y = randf_range(0.0, 1.0) * skala 
		
		gumpalan.position = Vector3(pos_x, pos_y, pos_z)
		gumpalan.scale = Vector3(1.0, 0.5, 1.0) 
		# SHADOWS_ONLY = awannya sendiri TIDAK digambar, hanya bayangannya yang
		# jatuh ke tanah. Ini memang desain yang disengaja untuk peta Grassland —
		# jangan diganti jadi OFF, karena itu justru menampilkan gumpalan awannya.
		gumpalan.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
		awan.add_child(gumpalan)
		
	return awan

func _buat_awan_kawal_tengah(jumlah: int):
	for i in range(jumlah):
		var awan = _racik_bentuk_awan_realistis()
		# Diletakkan lebih tinggi agar pergerakannya lebih luas
		# Posisi X dan Z dikasih selisih berdasarkan index 'i' agar tidak menumpuk saat start
		awan.position = Vector3(-20.0 - (i * 20.0), randf_range(18, 22), -20.0 - (i * 15.0))
		add_child(awan)
		daftar_awan_kawal.append(awan)

func _buat_awan_bebas(jumlah: int):
	for i in range(jumlah):
		var awan = _racik_bentuk_awan_realistis()
		# Muncul di koordinat -60 hingga 60 saja (bukan -100 ke 100)
		awan.position = Vector3(randf_range(-60, 60), randf_range(18, 25), randf_range(-60, 60))
		add_child(awan)
		daftar_awan_bebas.append(awan)

func _apakah_di_luar_zona_aman(pos: Vector3, jarak_tambahan: float = 0.0) -> bool:
	# 1. Cek benturan dengan kotak pusat (Zona Aman Start Lama)
	var batas_x = batas_aman_x + jarak_tambahan
	var batas_z = batas_aman_z + jarak_tambahan
	if abs(pos.x) < batas_x and abs(pos.z) < batas_z:
		return false

	# 2. Cek benturan dengan seluruh rentetan petak (Jalanan)
	# Jarak 2.5 meter + jarak tambahan biasanya pas agar pohon & batu tidak menembus petak
	var jarak_aman_petak = 2.5 + (jarak_tambahan * 0.5) 
	var pos_2d = Vector2(pos.x, pos.z)
	
	for pos_petak in daftar_posisi_petak:
		if pos_2d.distance_to(pos_petak) < jarak_aman_petak:
			return false # Terlalu dekat dengan petak, batalkan taruh objek di sini!
			
	return true

func _dapat_posisi_acak() -> Vector3:
	var sudut = randf_range(0, TAU)
	var jarak = randf_range(0.0, radius_maksimal)
	return Vector3(cos(sudut) * jarak, level_tanah, sin(sudut) * jarak)

func _setup_langit():
	var env_node = WorldEnvironment.new()
	var env = Environment.new()
	var sky = Sky.new()
	var sky_mat = ProceduralSkyMaterial.new()
	
	sky_mat.sky_top_color = Color(0.3, 0.6, 1.0)
	sky_mat.sky_horizon_color = Color(0.75, 0.85, 0.95)
	sky_mat.ground_bottom_color = Color(0.15, 0.3, 0.15)
	sky_mat.ground_horizon_color = Color(0.5, 0.65, 0.5)
	
	if tingkat_grafis_saat_ini == "sangat_rendah":
		# Langit prosedural dihitung ulang tiap frame. Di perangkat lemah, warna
		# polos jauh lebih murah dan bedanya hampir tidak terlihat di game papan
		# yang kameranya menunduk ke bawah.
		env.background_mode = Environment.BG_COLOR
		env.background_color = Color(0.55, 0.75, 0.95)
	else:
		sky.sky_material = sky_mat
		env.background_mode = Environment.BG_SKY
		env.sky = sky

	# Kabut menambah biaya per-piksel di seluruh layar. Dulu SELALU menyala —
	# termasuk di Very Low, padahal justru di situ yang paling butuh hemat.
	if tingkat_grafis_saat_ini in ["sedang", "tinggi"]:
		env.fog_enabled = true
		env.fog_density = 0.005
		env.fog_light_color = Color(0.75, 0.85, 0.95)
	else:
		env.fog_enabled = false
	
	env_node.environment = env
	add_child(env_node)

func _setup_tanah_dasar():
	var tanah = MeshInstance3D.new()
	var mesh_tanah = BoxMesh.new()
	mesh_tanah.size = Vector3(150, 2, 250) # Dipotong drastis dari 600x600
	tanah.mesh = mesh_tanah
	tanah.position.y = level_tanah - 1.0 
	
	var mat_tanah = StandardMaterial3D.new()
	mat_tanah.albedo_color = Color(0.2, 0.45, 0.15) 
	mat_tanah.roughness = 0.9
	tanah.material_override = mat_tanah
	add_child(tanah)

func _sebar_objek_alam():
	var objek_terbuat = 0
	var batas_loop = jumlah_objek * 10 
	
	while objek_terbuat < jumlah_objek and batas_loop > 0:
		batas_loop -= 1
		var pos = _dapat_posisi_acak()
		
		if _apakah_di_luar_zona_aman(pos, 4.0):
			if randf() > 0.4: _buat_pohon(pos)
			else: _buat_batu(pos)
			objek_terbuat += 1

func _buat_pohon(pos: Vector3):
	var pohon = Node3D.new()
	pohon.position = pos
	
	var batang = MeshInstance3D.new()
	var mesh_batang = CylinderMesh.new()
	mesh_batang.top_radius = randf_range(0.3, 0.6)
	mesh_batang.bottom_radius = mesh_batang.top_radius
	mesh_batang.height = randf_range(3.0, 6.0)
	
	if tingkat_grafis_saat_ini == "rendah":
		mesh_batang.radial_segments = 6
		batang.material_override = mat_batang_global
	else:
		var mat_batang = StandardMaterial3D.new()
		mat_batang.albedo_color = Color(0.4, 0.25, 0.1)
		batang.material_override = mat_batang
		
	batang.mesh = mesh_batang
	batang.position.y = mesh_batang.height / 2.0
	pohon.add_child(batang)
	
	var daun = MeshInstance3D.new()
	var mesh_daun = SphereMesh.new()
	mesh_daun.radius = randf_range(1.5, 3.5)
	mesh_daun.height = mesh_daun.radius * 2.0
	
	if tingkat_grafis_saat_ini in ["rendah", "sangat_rendah"]:
		mesh_daun.radial_segments = 6
		mesh_daun.rings = 3
		daun.material_override = mat_daun_global
	else:
		mesh_daun.radial_segments = randi_range(6, 12)
		mesh_daun.rings = randi_range(4, 8)
		var mat_daun = StandardMaterial3D.new()
		mat_daun.albedo_color = Color(randf_range(0.2, 0.4), randf_range(0.5, 0.8), 0.15)
		mat_daun.roughness = 1.0
		daun.material_override = mat_daun
		
	daun.mesh = mesh_daun
	daun.position.y = mesh_batang.height + (mesh_daun.radius * 0.4)
	daun.scale = Vector3(1.0, randf_range(0.7, 1.2), 1.0)
	pohon.add_child(daun)
	add_child(pohon)
	daftar_pohon.append(pohon)

func _buat_batu(pos: Vector3):
	var batu = MeshInstance3D.new()
	var mesh_batu = SphereMesh.new()
	mesh_batu.radius = randf_range(1.0, 3.5)
	mesh_batu.height = mesh_batu.radius * 2.0
	
	if tingkat_grafis_saat_ini in ["rendah", "sangat_rendah"]:
		mesh_batu.radial_segments = 5
		mesh_batu.rings = 3
		batu.material_override = mat_batu_global
	else:
		mesh_batu.radial_segments = randi_range(5, 8)
		mesh_batu.rings = randi_range(4, 6)
		var mat_batu = StandardMaterial3D.new()
		var kelabu = randf_range(0.4, 0.6)
		mat_batu.albedo_color = Color(kelabu, kelabu, kelabu)
		mat_batu.roughness = 0.9
		batu.material_override = mat_batu
		
	batu.mesh = mesh_batu
	var scale_x = randf_range(0.6, 1.5)
	var scale_y = randf_range(0.3, 0.8) 
	var scale_z = randf_range(0.6, 1.5)
	batu.scale = Vector3(scale_x, scale_y, scale_z)
	batu.position = pos
	batu.position.y = pos.y + ((mesh_batu.radius * scale_y) * 0.3) - 0.2
	add_child(batu)

func _buat_padang_rumput():
	if tingkat_grafis_saat_ini == "sangat_rendah": return
		
	var mmi = MultiMeshInstance3D.new()
	var mm = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.instance_count = jumlah_rumput
	
	var mesh_rumput = QuadMesh.new()
	mesh_rumput.size = Vector2(0.3, 0.6)
	mesh_rumput.center_offset = Vector3(0, 0.3, 0) 
	
	var kode_shader = """
	shader_type spatial;
	render_mode cull_disabled; 

	uniform vec3 warna_atas = vec3(0.4, 0.8, 0.2);
	uniform vec3 warna_bawah = vec3(0.15, 0.4, 0.15);
	uniform float kecepatan_angin = 2.5;
	uniform float kekuatan_angin = 0.4;

	void vertex() {
		float ketinggian = 1.0 - UV.y; 
		vec3 posisi_dunia = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
		float gelombang = sin(TIME * kecepatan_angin + posisi_dunia.x * 0.8 + posisi_dunia.z * 0.8);
		
		VERTEX.x += gelombang * kekuatan_angin * ketinggian;
		VERTEX.z += gelombang * kekuatan_angin * 0.5 * ketinggian;
	}

	void fragment() {
		ALBEDO = mix(warna_atas, warna_bawah, UV.y);
		ROUGHNESS = 0.9;
	}
	"""
	
	var shader_mat = ShaderMaterial.new()
	var shader = Shader.new()
	shader.code = kode_shader
	shader_mat.shader = shader
	mesh_rumput.material = shader_mat
	
	mm.mesh = mesh_rumput
	
	var indeks = 0
	var batas_loop_rumput = jumlah_rumput * 10
	
	while indeks < mm.instance_count and batas_loop_rumput > 0:
		batas_loop_rumput -= 1
		var pos = _dapat_posisi_acak()
		
		if _apakah_di_luar_zona_aman(pos):
			var t = Transform3D()
			t = t.translated(pos)
			t = t.rotated(Vector3.UP, randf_range(0, TAU))
			var s = randf_range(0.6, 1.4)
			t = t.scaled(Vector3(s, s, s))
			
			mm.set_instance_transform(indeks, t)
			indeks += 1
			
		# --- KUNCI ANTI-FREEZE UNTUK HP ---
		# Beri jeda 1 frame setiap 100 loop agar CPU HP sempat bernapas
		if batas_loop_rumput % 100 == 0:
			# PENGAMAN: kalau scene sudah diganti (mis. pemain menekan LOCAL PLAY),
			# node ini sudah dihapus dari tree. Tanpa cek ini, loop terus berjalan
			# lalu memanggil get_tree() yang sudah null — error berulang tanpa henti.
			if not is_inside_tree():
				return
			await get_tree().process_frame
			if not is_inside_tree():
				return
			
	mmi.multimesh = mm
	if tingkat_grafis_saat_ini in ["rendah", "sangat_rendah"]:
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF 
	else:
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	add_child(mmi)

# ========================================================
# FITUR BARU: SISTEM BURUNG 3D DAN RUTINITAS KELUAR/MASUK POHON
# ========================================================
func _spawn_burung_acak():
	# PENGAMAN: Batalkan kemunculan burung jika grafis sangat rendah
	if tingkat_grafis_saat_ini == "sangat_rendah":
		return
		
	if daftar_pohon.size() < 2: return # Butuh minimal 2 pohon untuk terbang bolak-balik
	
	var jumlah_burung = randi_range(1, 2)
	for i in range(jumlah_burung):
		var burung = _racik_bentuk_burung()
		add_child(burung)
		
		# Sembunyikan burung di dalam daun pohon pertama (Skala 0)
		var pohon_awal = daftar_pohon.pick_random()
		burung.global_position = pohon_awal.global_position + Vector3(0, randf_range(2.5, 4.0), 0)
		burung.scale = Vector3.ZERO 
		
		# Simpan referensi pohon awal ke dalam burung
		burung.set_meta("pohon_sekarang", pohon_awal)
		
		# Jalankan rutinitas kehidupan burung
		_rutinitas_burung(burung)

func _racik_bentuk_burung() -> Node3D:
	var burung = Node3D.new()
	var warna_burung = [Color(0.2, 0.5, 0.9), Color(0.6, 0.35, 0.15), Color(0.8, 0.8, 0.8)].pick_random()
	var mat_tubuh = StandardMaterial3D.new()
	mat_tubuh.albedo_color = warna_burung
	mat_tubuh.roughness = 0.8
	var mat_paruh = StandardMaterial3D.new()
	mat_paruh.albedo_color = Color(0.9, 0.7, 0.1)
	
	# 1. Badan
	var tubuh = MeshInstance3D.new()
	var mesh_tubuh = SphereMesh.new()
	mesh_tubuh.radius = 0.45
	mesh_tubuh.height = 0.9
	tubuh.mesh = mesh_tubuh
	tubuh.scale = Vector3(0.6, 0.6, 1.0)
	tubuh.material_override = mat_tubuh
	burung.add_child(tubuh)
	
	# 2. Kepala
	var kepala = MeshInstance3D.new()
	var mesh_kepala = SphereMesh.new()
	mesh_kepala.radius = 0.25
	mesh_kepala.height = 0.5
	kepala.mesh = mesh_kepala
	kepala.position = Vector3(0, 0.15, -0.45) 
	kepala.material_override = mat_tubuh
	burung.add_child(kepala)
	
	# 3. Paruh
	var paruh = MeshInstance3D.new()
	var mesh_paruh = BoxMesh.new()
	mesh_paruh.size = Vector3(0.1, 0.1, 0.25)
	paruh.mesh = mesh_paruh
	paruh.position = Vector3(0, 0.15, -0.65)
	paruh.material_override = mat_paruh
	burung.add_child(paruh)
	
	# 4. Ekor
	var ekor = MeshInstance3D.new()
	var mesh_ekor = BoxMesh.new()
	mesh_ekor.size = Vector3(0.25, 0.1, 0.5)
	ekor.mesh = mesh_ekor
	ekor.position = Vector3(0, 0.1, 0.5)
	ekor.rotation_degrees.x = -15
	ekor.material_override = mat_tubuh
	burung.add_child(ekor)
	
	# 5. Sayap Kiri & Kanan 
	var engsel_kiri = Node3D.new()
	engsel_kiri.position = Vector3(-0.25, 0, 0)
	burung.add_child(engsel_kiri)
	
	var sayap_kiri = MeshInstance3D.new()
	var mesh_sayap = BoxMesh.new()
	mesh_sayap.size = Vector3(0.6, 0.04, 0.4)
	sayap_kiri.mesh = mesh_sayap
	sayap_kiri.position = Vector3(-0.3, 0, 0)
	sayap_kiri.material_override = mat_tubuh
	engsel_kiri.add_child(sayap_kiri)
	
	var engsel_kanan = Node3D.new()
	engsel_kanan.position = Vector3(0.25, 0, 0)
	burung.add_child(engsel_kanan)
	
	var sayap_kanan = MeshInstance3D.new()
	sayap_kanan.mesh = mesh_sayap # Bisa menggunakan mesh yang sama
	sayap_kanan.position = Vector3(0.3, 0, 0)
	sayap_kanan.material_override = mat_tubuh
	engsel_kanan.add_child(sayap_kanan)

	burung.set_meta("sayap_kiri", engsel_kiri)
	burung.set_meta("sayap_kanan", engsel_kanan)
	return burung

func _rutinitas_burung(burung: Node3D):
	while is_instance_valid(burung):
		var pohon_awal = burung.get_meta("pohon_sekarang")
		
		# 1. HINGGAP DAN BERSEMBUNYI (Masuk ke dalam rimbunan daun pohon)
		var tw_hinggap = get_tree().create_tween()
		tw_hinggap.tween_property(burung, "scale", Vector3.ZERO, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		
		# PERBAIKAN 3b: Animasi Daun Bergoyang saat burung MASUK
		if pohon_awal and pohon_awal.get_child_count() > 1:
			var daun_awal = pohon_awal.get_child(1) # Asumsi daun adalah child ke-1 setelah batang
			var skala_asli = daun_awal.scale
			var tw_getar_masuk = get_tree().create_tween()
			tw_getar_masuk.tween_property(daun_awal, "scale", skala_asli * Vector3(1.1, 0.9, 1.1), 0.1)
			tw_getar_masuk.tween_property(daun_awal, "scale", skala_asli * Vector3(0.95, 1.05, 0.95), 0.15)
			tw_getar_masuk.tween_property(daun_awal, "scale", skala_asli, 0.2)
		
		await get_tree().create_timer(randf_range(5.0, 15.0)).timeout
		# PENGAMAN: sama seperti loop rumput — kalau scene sudah diganti, hentikan.
		if not is_inside_tree():
			return
		
		# 2. CARI POHON TUJUAN BARU
		var target_pohon = daftar_pohon.pick_random()
		while target_pohon == pohon_awal or target_pohon.global_position.distance_to(burung.global_position) < 5.0:
			target_pohon = daftar_pohon.pick_random() 
			
		var posisi_daun_target = target_pohon.global_position + Vector3(0, randf_range(4.5, 6.0), 0)
		
		var arah_lihat = posisi_daun_target
		arah_lihat.y = burung.global_position.y
		burung.look_at(arah_lihat, Vector3.UP)
		
		# 3. KELUAR DARI DAUN (Mulai terbang)
		var tw_keluar = get_tree().create_tween()
		tw_keluar.tween_property(burung, "scale", Vector3.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		
		# PERBAIKAN 3a: Animasi Daun Bergoyang saat burung KELUAR
		if pohon_awal and pohon_awal.get_child_count() > 1:
			var daun_awal = pohon_awal.get_child(1)
			var skala_asli = daun_awal.scale
			var tw_getar_keluar = get_tree().create_tween()
			tw_getar_keluar.tween_property(daun_awal, "scale", skala_asli * Vector3(1.1, 0.9, 1.1), 0.1)
			tw_getar_keluar.tween_property(daun_awal, "scale", skala_asli * Vector3(0.95, 1.05, 0.95), 0.15)
			tw_getar_keluar.tween_property(daun_awal, "scale", skala_asli, 0.2)
		
		var sayap_l = burung.get_meta("sayap_kiri")
		var sayap_r = burung.get_meta("sayap_kanan")
		var tw_kepak = burung.create_tween().set_loops()
		tw_kepak.tween_property(sayap_l, "rotation_degrees:z", -45.0, 0.15) # Kepakan sayap sedikit diperlambat
		tw_kepak.parallel().tween_property(sayap_r, "rotation_degrees:z", 45.0, 0.15)
		tw_kepak.tween_property(sayap_l, "rotation_degrees:z", 20.0, 0.15)
		tw_kepak.parallel().tween_property(sayap_r, "rotation_degrees:z", -20.0, 0.15)
		
		# 4. TERBANG LINTAS UDARA
		var jarak = burung.global_position.distance_to(posisi_daun_target)
		# PERBAIKAN 2: DURASI TERBANG DILAMBATKAN (Pembagi dikecilkan)
		var durasi_terbang = jarak / randf_range(4.0, 6.0) 
		
		var tw_terbang = get_tree().create_tween().set_parallel(true)
		tw_terbang.tween_property(burung, "global_position:x", posisi_daun_target.x, durasi_terbang)
		tw_terbang.tween_property(burung, "global_position:z", posisi_daun_target.z, durasi_terbang)
		
		var tinggi_puncak = max(burung.global_position.y, posisi_daun_target.y) + (jarak * 0.2) # Lengkungan lebih tinggi sedikit agar santai
		var tw_y = get_tree().create_tween()
		tw_y.tween_property(burung, "global_position:y", tinggi_puncak, durasi_terbang * 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tw_y.tween_property(burung, "global_position:y", posisi_daun_target.y, durasi_terbang * 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		
		await tw_terbang.finished
		
		# Matikan animasi sayap saat tiba
		tw_kepak.kill()
		sayap_l.rotation_degrees.z = 0
		sayap_r.rotation_degrees.z = 0
		
		# Update referensi pohon untuk siklus selanjutnya
		burung.set_meta("pohon_sekarang", target_pohon)

# GANTI FUNGSI terapkan_efek_lingkungan YANG LAMA DENGAN INI
func _terapkan_efek_lingkungan_saat_boot():
	var env_node = null
	for anak in get_children():
		if anak is WorldEnvironment:
			env_node = anak
			break
			
	var matahari = null
	for node in get_parent().get_children():
		if node is DirectionalLight3D:
			matahari = node
			break
			
	if env_node and env_node.environment:
		var env = env_node.environment
		
		if tingkat_grafis_saat_ini in ["rendah", "sangat_rendah"]:
			env.glow_enabled = false
			env.ssao_enabled = false
			if matahari: 
				matahari.shadow_enabled = false
				
		elif tingkat_grafis_saat_ini == "sedang":
			# Glow/bloom adalah efek layar penuh dengan beberapa lintasan blur —
			# salah satu yang paling mahal di GPU HP kelas bawah. Sekarang hanya
			# aktif di tingkat "tinggi", tidak lagi di "sedang".
			env.glow_enabled = false
			env.ssao_enabled = false
			if matahari: 
				matahari.shadow_enabled = true
				matahari.directional_shadow_max_distance = 35.0
				
		elif tingkat_grafis_saat_ini == "tinggi":
			env.glow_enabled = true
			env.glow_intensity = 1.0
			if matahari: 
				matahari.shadow_enabled = true
				matahari.directional_shadow_max_distance = 100.0
