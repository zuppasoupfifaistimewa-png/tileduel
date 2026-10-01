extends Node3D
class_name PetakPermata

var nama_warna: String = "Biru"
# Warna biru cerah khas kartun/vektor
var warna_permata: Color = Color(0.48, 0.83, 0.88) 

var poros_animasi: Node3D
var permata_utama: MeshInstance3D
var permata_kiri: MeshInstance3D
var permata_kanan: MeshInstance3D

var waktu_kilauan: float = 0.0

# =======================================================
# TAMBAHAN: VARIABEL CACHE UNTUK MENCEGAH FREEZE (LAG)
# =======================================================
var cache_mat_permata: StandardMaterial3D
var cache_mat_partikel: StandardMaterial3D
var cache_mesh_mahkota: CylinderMesh
var cache_mesh_badan: CylinderMesh
var cache_mesh_partikel: SphereMesh

# Mode ringan khusus setelan grafis "Very Low" (dibaca sekali di _ready). Versi
# penuh TIDAK diubah -- perangkat kelas menengah ke atas tetap dapat efek biasa.
var grafis_ringan: bool = false
var cache_mat_mahkota_ringan: StandardMaterial3D
var cache_mat_badan_ringan: StandardMaterial3D
var cache_mesh_partikel_ringan: SphereMesh

func _ready():
	var config = ConfigFile.new()
	if config.load("user://seting_grafis.cfg") == OK:
		grafis_ringan = (config.get_value("Pengaturan", "kualitas_grafik", "sedang") == "sangat_rendah")

	# =======================================================
	# 1. POROS UTAMA STIKER
	# =======================================================
	poros_animasi = Node3D.new()
	# Diberi jarak sedikit dari lantai (0.05) agar tidak berkedip (Z-fighting)
	poros_animasi.position.y = 0.05 
	add_child(poros_animasi)

	# =======================================================
	# 2. MEMBUAT 3 STIKER PERMATA (Tengah, Kiri, Kanan)
	# =======================================================
	var material_permata = _buat_material_permata()
	
	# Permata Utama (Besar di Tengah)
	permata_utama = MeshInstance3D.new()
	var kanvas_utama = QuadMesh.new()
	kanvas_utama.size = Vector2(3.8, 3.8) # Ukuran diperbesar
	permata_utama.mesh = kanvas_utama
	permata_utama.material_override = material_permata
	permata_utama.rotation_degrees.x = -90 # Ditebahkan/Datar menempel lantai
	poros_animasi.add_child(permata_utama)
	
	# Permata Kiri (Kecil di Kiri Atas)
	permata_kiri = MeshInstance3D.new()
	var kanvas_kecil = QuadMesh.new()
	kanvas_kecil.size = Vector2(2.3, 2.3) # Ukuran diperbesar
	permata_kiri.mesh = kanvas_kecil
	permata_kiri.material_override = material_permata
	permata_kiri.rotation_degrees.x = -90
	permata_kiri.position = Vector3(-3.0, 0.0, -0.8) 
	poros_animasi.add_child(permata_kiri)
	
	# Permata Kanan (Kecil di Kanan Atas)
	permata_kanan = MeshInstance3D.new()
	permata_kanan.mesh = kanvas_kecil
	permata_kanan.material_override = material_permata
	permata_kanan.rotation_degrees.x = -90
	permata_kanan.position = Vector3(3.0, 0.0, -0.8)
	poros_animasi.add_child(permata_kanan)

	# =======================================================
	# 3. ANIMASI MELAYANG (2D BOBBING)
	# =======================================================
	var tw_utama = create_tween().set_loops()
	tw_utama.tween_property(permata_utama, "position:z", -0.15, 1.2).as_relative().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw_utama.tween_property(permata_utama, "position:z", 0.15, 1.2).as_relative().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	var tw_kiri = create_tween().set_loops()
	tw_kiri.tween_property(permata_kiri, "position:z", 0.1, 1.0).as_relative().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw_kiri.tween_property(permata_kiri, "position:z", -0.1, 1.0).as_relative().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	var tw_kanan = create_tween().set_loops()
	tw_kanan.tween_property(permata_kanan, "position:z", -0.12, 1.3).as_relative().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw_kanan.tween_property(permata_kanan, "position:z", 0.12, 1.3).as_relative().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	# =======================================================
	# 4. PRE-LOAD MATERIAL & MESH (MENCEGAH LAG SAAT DIINJAK)
	# =======================================================
	cache_mat_permata = StandardMaterial3D.new()
	cache_mat_permata.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	cache_mat_permata.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	cache_mat_permata.albedo_color = warna_permata 
	cache_mat_permata.albedo_color.a = 0.35 
	cache_mat_permata.metallic = 1.0 
	cache_mat_permata.roughness = 0.0 
	cache_mat_permata.metallic_specular = 1.0 
	cache_mat_permata.clearcoat_enabled = true
	cache_mat_permata.clearcoat_roughness = 0.0
	cache_mat_permata.refraction_enabled = true
	cache_mat_permata.refraction_scale = 0.05
	cache_mat_permata.emission_enabled = true 
	cache_mat_permata.emission = warna_permata
	cache_mat_permata.emission_energy_multiplier = 0.8 
	
	cache_mesh_mahkota = CylinderMesh.new()
	cache_mesh_mahkota.top_radius = 0.4
	cache_mesh_mahkota.bottom_radius = 0.8
	cache_mesh_mahkota.height = 0.3
	cache_mesh_mahkota.radial_segments = 10 
	cache_mesh_mahkota.rings = 1
	
	cache_mesh_badan = CylinderMesh.new()
	cache_mesh_badan.top_radius = 0.8
	cache_mesh_badan.bottom_radius = 0.0 
	cache_mesh_badan.height = 0.8
	cache_mesh_badan.radial_segments = 10
	cache_mesh_badan.rings = 1
	
	cache_mesh_partikel = SphereMesh.new()
	cache_mesh_partikel.radius = 0.2
	cache_mesh_partikel.height = 0.4
	
	cache_mat_partikel = StandardMaterial3D.new()
	cache_mat_partikel.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	cache_mat_partikel.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	cache_mat_partikel.albedo_color = warna_permata

	# VERSI RINGAN (Very Low): permata yang melompat memakai material unshaded +
	# alpha (jenis shader yang sama dengan partikelnya), bukan material kaca
	# (clearcoat + refraction + emission) yang sangat mahal disusun di GPU HP.
	# Dua warna -- mahkota lebih terang, badan warna asli -- supaya tetap
	# kelihatan bersegi seperti stiker permatanya.
	if grafis_ringan:
		cache_mat_mahkota_ringan = StandardMaterial3D.new()
		cache_mat_mahkota_ringan.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		cache_mat_mahkota_ringan.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		cache_mat_mahkota_ringan.albedo_color = Color(warna_permata.lightened(0.45), 0.9)
		cache_mat_badan_ringan = StandardMaterial3D.new()
		cache_mat_badan_ringan.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		cache_mat_badan_ringan.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		cache_mat_badan_ringan.albedo_color = Color(warna_permata, 0.9)
		cache_mesh_partikel_ringan = SphereMesh.new() # low-poly (bawaan 64x32 segi)
		cache_mesh_partikel_ringan.radius = 0.2
		cache_mesh_partikel_ringan.height = 0.4
		cache_mesh_partikel_ringan.radial_segments = 8
		cache_mesh_partikel_ringan.rings = 4

	# Suara "ting" disintesis sekarang (saat peta dimuat), bukan saat permata
	# pertama diambil. Hasilnya statis, jadi cuma petak pertama yang menghitungnya.
	_buat_suara_ting()

# Material & mesh yang dipakai efek koleksi -- satu sumber untuk
# mainkan_efek_koleksi dan buat_contoh_efek (pemanasan), supaya tidak bisa beda.
func _mat_mahkota() -> StandardMaterial3D:
	return cache_mat_mahkota_ringan if grafis_ringan else cache_mat_permata

func _mat_badan() -> StandardMaterial3D:
	return cache_mat_badan_ringan if grafis_ringan else cache_mat_permata

func _mesh_partikel() -> SphereMesh:
	return cache_mesh_partikel_ringan if grafis_ringan else cache_mesh_partikel

func buat_contoh_efek(induk: Node3D) -> void:
	# Dipanggil _pemanasan_shader (pemain.gd): bentuk & material yang PERSIS sama
	# dengan mainkan_efek_koleksi, digambar sekali saat loading supaya shader-nya
	# sudah tersusun sebelum permata pertama diambil. Tanpa suara, tanpa animasi.
	var contoh = [
		[cache_mesh_mahkota, _mat_mahkota(), Vector3(-0.3, 0.1, 0.0)],
		[cache_mesh_badan, _mat_badan(), Vector3(-0.3, -0.25, 0.0)],
		[_mesh_partikel(), cache_mat_partikel, Vector3(0.3, 0.0, 0.0)],
	]
	for c in contoh:
		var m = MeshInstance3D.new()
		m.mesh = c[0]
		m.material_override = c[1]
		m.position = c[2]
		m.scale = Vector3(0.5, 0.5, 0.5)
		induk.add_child(m)

func _process(delta):
	# Memunculkan Bintang Kilauan secara berkala
	waktu_kilauan += delta
	if waktu_kilauan > 0.6: 
		waktu_kilauan = 0.0
		# Acak muncul di permata utama atau yang kecil
		var target = [permata_utama, permata_kiri, permata_kanan].pick_random()
		_munculkan_kilauan(target)

# =======================================================
# FUNGSI SHADER: MENGGAMBAR PERMATA 2D MURNI DENGAN ROTASI
# =======================================================
static var cache_shader_stiker: Shader = null

func _buat_material_permata() -> ShaderMaterial:
	var mat = ShaderMaterial.new()
	var kode_shader = """
	shader_type spatial;
	render_mode unshaded, blend_mix, depth_draw_opaque, cull_disabled;

	uniform vec3 warna_dasar : source_color;

	void fragment() {
		vec2 uv = UV - vec2(0.5);
		
		// 1. MENGHITUNG BENTUK LUAR (STATIC OUTLINE)
		// Lebar batas luar dikunci permanen, tidak akan pernah memipih (gepeng)
		float w = 0.0;
		bool is_out = false;
		
		if (uv.y < -0.05) {
			// Bagian atas (Mahkota)
			if (uv.y < -0.25) {
				is_out = true; 
			} else {
				float t = (uv.y + 0.05) / -0.20; 
				w = mix(0.5, 0.25, t);
			}
		} else {
			// Bagian bawah (Paviliun)
			if (uv.y > 0.4) {
				is_out = true;
			} else {
				float t = (uv.y + 0.05) / 0.45;
				w = mix(0.5, 0.0, t);
			}
		}
		
		// Buang piksel di luar bentuk permata statis
		if (is_out || abs(uv.x) > w) discard;
		
		// 2. KETEBALAN GARIS TEPI
		float outline = 0.025;
		bool is_edge = false;
		
		// Garis pinggir luar permanen
		if (abs(uv.x) > w - outline) is_edge = true;
		if (uv.y < -0.25 + outline) is_edge = true; 
		
		// Garis sabuk horizontal tengah (Girdle)
		if (abs(uv.y + 0.05) < outline * 0.7) is_edge = true;
		
		// 3. MATEMATIKA ROTASI 3D INTERNAL (Menggerakkan faset di dalam)
		float nx = uv.x / w;
		// Fungsi asin memetakan x linier datar menjadi sudut lengkung silinder 3D
		float angle = asin(clamp(nx, -1.0, 1.0)); 
		
		float waktu_acak = TIME * 2.5 + NODE_POSITION_WORLD.x * 2.0;
		float rot_angle = angle + waktu_acak;
		
		// Membagi silinder virtual menjadi 6 faset (segi enam)
		float facet_size = 3.14159265 / 3.0; 
		float phase = rot_angle / facet_size;
		
		// Menggambar garis dalam pembatas faset yang bergerak
		float angular_dist = min(fract(phase), 1.0 - fract(phase)) * facet_size;
		// cos(angle) memberi efek perspektif, garis merapat saat mendekati pinggir
		float screen_dist = angular_dist * cos(angle) * w; 
		if (screen_dist < outline * 0.6) is_edge = true;
		
		// 4. PEWARNAAN FASET DINAMIS (Pencahayaan Bereaksi Terhadap Putaran)
		float facet_id = floor(phase);
		float facet_center_angle = (facet_id + 0.5) * facet_size;
		float screen_angle = facet_center_angle - waktu_acak;
		
		// Menghitung vektor normal dari faset yang sedang menghadap layar
		vec2 facet_normal = vec2(sin(screen_angle), cos(screen_angle));
		
		// Cahaya datang dari Kiri Atas
		vec2 light_dir = normalize(vec2(-1.0, 1.0));
		float pencahayaan = dot(facet_normal, light_dir);
		
		vec3 final_color = warna_dasar;
		if (pencahayaan > 0.5) {
			final_color = mix(warna_dasar, vec3(1.0), 0.6); // Terang
		} else if (pencahayaan < -0.2) {
			final_color = mix(warna_dasar, vec3(0.0), 0.3); // Gelap
		}
		
		// 5. ANIMASI GARIS KILAUAN (SWEEP GLARE)
		float waktu_kilap = fract(waktu_acak * 0.4) * 3.0 - 0.5;
		float posisi_garis = (uv.x + uv.y); 
		if (abs(posisi_garis - waktu_kilap) < 0.08) {
			final_color = mix(final_color, vec3(1.0), 0.8);
		}

		ALBEDO = is_edge ? vec3(0.0) : final_color;
	}
	"""
	# Satu Shader untuk SEMUA petak permata (dulu satu per petak -> GPU menyusun
	# shader yang sama berkali-kali; petak yang baru pertama kali masuk layar di
	# tengah permainan pun bikin tersendat). Warna tetap per petak lewat parameter.
	if cache_shader_stiker == null:
		cache_shader_stiker = Shader.new()
		cache_shader_stiker.code = kode_shader
	mat.shader = cache_shader_stiker
	mat.set_shader_parameter("warna_dasar", warna_permata)
	return mat

# =======================================================
# FUNGSI SHADER & LOGIKA BINTANG KILAUAN (SPARKLE)
# =======================================================
# Kilauan muncul tiap 0.6 dtk di SETIAP petak permata. Dulu tiap kilauan membuat
# Shader baru, yang harus disusun ulang GPU setiap kali (terukur ~300 ms per
# kilauan di rig uji). Sekarang satu shader, material & mesh dibagi bersama.
static var cache_shader_kilauan: Shader = null
static var cache_mat_kilauan: ShaderMaterial = null
static var cache_mesh_kilauan: QuadMesh = null

func _dapatkan_shader_kilauan() -> Shader:
	if cache_shader_kilauan != null:
		return cache_shader_kilauan
	var shader = Shader.new()
	# Menggambar bentuk bintang 4 sudut (Astroid Curve) dengan garis tepi hitam
	shader.code = """
	shader_type spatial;
	render_mode unshaded, blend_mix, depth_draw_opaque;
	void fragment() {
		vec2 uv = abs(UV - 0.5) * 2.0; 
		float dist = sqrt(uv.x) + sqrt(uv.y);
		if (dist > 1.0) discard; // Transparan di luar bentuk bintang
		
		if (dist > 0.70) {
			ALBEDO = vec3(0.0); // Garis tepi bintang (hitam)
		} else {
			ALBEDO = vec3(1.0); // Inti Bintang (putih)
		}
	}
	"""
	cache_shader_kilauan = shader
	return shader

func _munculkan_kilauan(induk: Node3D):
	var kilauan = MeshInstance3D.new()
	if cache_mesh_kilauan == null:
		cache_mesh_kilauan = QuadMesh.new()
		cache_mesh_kilauan.size = Vector2(0.6, 0.6)
	kilauan.mesh = cache_mesh_kilauan

	if cache_mat_kilauan == null:
		cache_mat_kilauan = ShaderMaterial.new()
		cache_mat_kilauan.shader = _dapatkan_shader_kilauan()
	kilauan.material_override = cache_mat_kilauan
	
	# Posisikan sedikit melayang di atas stiker permata agar tidak bertumpuk
	kilauan.position.y = 0.02
	# Muncul acak di sekitar area permata
	kilauan.position.x = randf_range(-0.5, 0.5)
	kilauan.position.z = randf_range(-0.3, 0.3)
	induk.add_child(kilauan)
	
	# Animasi kilauan: Membesar, Berputar, lalu Mengecil hilang
	var tw = kilauan.create_tween()
	kilauan.scale = Vector3.ZERO
	# Karena stiker rebah (rot.x = -90), putaran 2D dilakukan di sumbu Y (3D)
	kilauan.rotation_degrees.y = randf_range(-30, 30) 
	
	tw.tween_property(kilauan, "scale", Vector3(1, 1, 1), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(kilauan, "rotation_degrees:y", kilauan.rotation_degrees.y + 180, 0.5)
	tw.tween_property(kilauan, "scale", Vector3.ZERO, 0.2).set_delay(0.2)
	tw.tween_callback(kilauan.queue_free) # Bersihkan node setelah animasi selesai

# =======================================================
# FUNGSI PERBAIKAN: EFEK ANIMASI BEBAS FREEZE / LAG
# =======================================================
func mainkan_efek_koleksi():

	# 1. SFX: Suara Sintetis "Ting Kristal" Matematika
	var suara_ting = AudioStreamPlayer.new()
	suara_ting.bus = "BusSFX"
	
	# PERBAIKAN: Turunkan volume dari 2.0 menjadi -8.0
	suara_ting.volume_db = -22.0 
	
	suara_ting.stream = _buat_suara_ting()
	add_child(suara_ting)
	suara_ting.play()
	
	# 2. MERAKIT MODEL 3D DARI CACHE (Sangat Ringan & Cepat)
	var permata_3d = Node3D.new() 
	
	var mahkota = MeshInstance3D.new()
	mahkota.mesh = cache_mesh_mahkota
	mahkota.material_override = _mat_mahkota() # Very Low: versi ringan
	mahkota.position.y = 0.15 
	permata_3d.add_child(mahkota)
	
	var badan = MeshInstance3D.new()
	badan.mesh = cache_mesh_badan
	badan.material_override = _mat_badan() # Very Low: versi ringan
	badan.position.y = -0.4 
	permata_3d.add_child(badan)
	
	get_tree().current_scene.add_child(permata_3d)
	permata_3d.global_position = self.global_position + Vector3(0, 0.5, 0)
	permata_3d.scale = Vector3(0.01, 0.01, 0.01) 
	
	# 3. VFX: Animasi Permata 3D Melompat
	var tw_pos_scale = create_tween()
	var posisi_puncak = self.global_position + Vector3(0, 5.0, 0) 
	tw_pos_scale.tween_property(permata_3d, "global_position", posisi_puncak, 0.8).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw_pos_scale.parallel().tween_property(permata_3d, "scale", Vector3(1.7, 1.7, 1.7), 0.8).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	
	var posisi_jatuh = self.global_position + Vector3(0, 1.5, 0)
	tw_pos_scale.tween_property(permata_3d, "global_position", posisi_jatuh, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw_pos_scale.parallel().tween_property(permata_3d, "scale", Vector3(0.01, 0.01, 0.01), 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	
	var tw_rotasi = create_tween()
	tw_rotasi.tween_property(permata_3d, "rotation_degrees:y", 1080.0, 1.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	# 4. VFX: "Particle Burst" dari Cache
	var jumlah_partikel = 5 if grafis_ringan else 10 # Very Low: separuhnya
	var list_partikel = []

	for i in range(jumlah_partikel):
		var partikel = MeshInstance3D.new()
		partikel.mesh = _mesh_partikel() # Very Low: low-poly
		partikel.material_override = cache_mat_partikel
		
		get_tree().current_scene.add_child(partikel)
		list_partikel.append(partikel)
		
		partikel.global_position = self.global_position + Vector3(0, 1.5, 0)
		
		var sudut_acak = randf_range(0, PI * 2.0)
		var jarak_sebar = randf_range(1.5, 3.5)
		var target_x = self.global_position.x + (cos(sudut_acak) * jarak_sebar)
		var target_z = self.global_position.z + (sin(sudut_acak) * jarak_sebar)
		var target_y = self.global_position.y + randf_range(2.0, 5.0)
		
		var tw_partikel = create_tween().set_parallel(true)
		tw_partikel.tween_property(partikel, "global_position", Vector3(target_x, target_y, target_z), 1.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw_partikel.tween_property(partikel, "scale", Vector3(0.01, 0.01, 0.01), 1.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		
	# 5. Pembersihan Objek (Garbage Collection)
	await tw_pos_scale.finished
	if is_instance_valid(permata_3d):
		permata_3d.queue_free()
		
	await get_tree().create_timer(0.3).timeout
	for p in list_partikel:
		if is_instance_valid(p):
			p.queue_free()
	if is_instance_valid(suara_ting):
		suara_ting.queue_free()

# ========================================================
# GENERATOR SINTESIS SUARA KRISTAL MATEMATIKA
# ========================================================
# Dibagi ke semua petak permata dalam satu sesi — dihitung sekali saja.
static var cache_suara_ting: AudioStreamWAV = null

func _buat_suara_ting() -> AudioStreamWAV:
	if cache_suara_ting != null:
		return cache_suara_ting

	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	var sample_rate = 22050
	stream.mix_rate = sample_rate
	
	var durasi = 0.5
	var panjang_data = int(sample_rate * durasi)
	var data_byte = PackedByteArray()
	data_byte.resize(panjang_data)
	
	# Array Frekuensi untuk Tangga Nada C Mayor (Kesan magis dan berharga)
	var tangga_nada = [523.25, 659.25, 783.99, 1046.50, 1318.51, 1567.98, 2093.00]
	
	var fase = 0.0
	for i in range(panjang_data):
		var waktu_t = float(i) / float(panjang_data)
		
		# Memecah waktu menjadi 7 langkah cepat (Arpeggio)
		var indeks_nada = min(int(waktu_t * 14.0), 6) 
		var frekuensi = tangga_nada[indeks_nada]
		
		fase += frekuensi * (PI * 2.0) / sample_rate
		
		# Envelope: Membuat denyutan volume di setiap lompatan nada
		var env_global = exp(-waktu_t * 3.0)
		var env_lokal = 1.0 - fmod(waktu_t * 14.0, 1.0) 
		var volume_total = env_global * env_lokal
		
		var gelombang_sinus = sin(fase)
		var gelombang_saw = 2.0 * fmod(fase / (PI * 2.0), 1.0) - 1.0
		var nilai_gelombang = ((gelombang_sinus * 0.7) + (gelombang_saw * 0.3)) * volume_total * 0.35
		
		var konversi_byte = int((nilai_gelombang + 1.0) * 127.5)
		data_byte[i] = clamp(konversi_byte, 0, 255)
		
	stream.data = data_byte
	cache_suara_ting = stream
	return stream
