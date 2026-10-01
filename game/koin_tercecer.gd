extends Node3D

var isi_koin: int = 0
var mesh_inst: MeshInstance3D # Dideklarasikan di sini agar bisa dianimasikan dari fungsi lain

func _ready():
	mesh_inst = MeshInstance3D.new()
	var silinder = CylinderMesh.new()
	silinder.height = 0.15
	silinder.top_radius = 0.4
	silinder.bottom_radius = 0.4
	mesh_inst.mesh = silinder
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.85, 0.1) # Warna Emas
	mat.metallic = 1.0
	mat.roughness = 0.3
	mesh_inst.material_override = mat
	
	# Miringkan koin agar menghadap kamera
	mesh_inst.rotation_degrees.x = 45 
	mesh_inst.position.y = 0.8
	add_child(mesh_inst)

func _process(delta):
	# Animasi putar koin
	rotation_degrees.y += 180 * delta

# =======================================================
# FUNGSI LAMA: MENGGABUNGKAN NILAI KOIN JIKA BERTUMPUK
# =======================================================
func tambah_koin(tambahan: int):
	isi_koin += tambahan
	
	# Beri animasi berdenyut sesaat agar pemain sadar koinnya bertambah banyak!
	if mesh_inst:
		var tw = create_tween()
		tw.tween_property(mesh_inst, "scale", Vector3(1.5, 1.5, 1.5), 0.2).set_trans(Tween.TRANS_BOUNCE)
		tw.tween_property(mesh_inst, "scale", Vector3(1.0, 1.0, 1.0), 0.2)

# =======================================================
# FUNGSI BARU: EFEK ANIMASI & SUARA SAAT KOIN DIAMBIL
# =======================================================
func munculkan_efek_dapat_koin(target_model: Node3D):
	# Kita pasang efek di "current_scene" agar tidak ikut hancur saat koin ini di-queue_free()
	var scene_utama = target_model.get_tree().current_scene
	
	# 1. BUAT TEKS EMAS MELAYANG
	var teks_untung = Label3D.new()
	teks_untung.text = "+" + str(isi_koin)
	teks_untung.font_size = 250
	teks_untung.outline_size = 50
	teks_untung.modulate = Color(1.0, 0.85, 0.1) # Warna Emas Koin
	teks_untung.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	
	scene_utama.add_child(teks_untung)
	
	# Posisikan teks tepat di atas kepala karakter
	teks_untung.global_position = target_model.global_position + Vector3(0, 1.5, 0)
	
	# Animasi melayang ke atas sambil memudar
	var tw = scene_utama.create_tween().set_parallel(true)
	tw.tween_property(teks_untung, "global_position:y", target_model.global_position.y + 4.5, 1.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(teks_untung, "modulate:a", 0.0, 1.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	
	# Bersihkan teks memori setelah animasi selesai
	tw.chain().tween_callback(teks_untung.queue_free)
	
	# 2. BUAT SUARA "CLING" SINTETIS ALA GAME 8-BIT
	var pemutar = AudioStreamPlayer3D.new()
	var stream_koin = AudioStreamWAV.new()
	stream_koin.format = AudioStreamWAV.FORMAT_8_BITS
	stream_koin.mix_rate = 11025
	
	var durasi = 0.3 # Suara sangat singkat
	var jumlah_sampel = int(stream_koin.mix_rate * durasi)
	var data_suara = PackedByteArray()
	data_suara.resize(jumlah_sampel)
	
	for i in range(jumlah_sampel):
		# SOLUSI EROR 1: Mengubah angka 2 menjadi 2.0 (float) untuk mencegah peringatan integer division
		var frekuensi = 1200.0 if i < jumlah_sampel / 2.0 else 1600.0 
		var waktu = float(i) / stream_koin.mix_rate
		var gelombang = 1 if sin(waktu * frekuensi * 2.0 * PI) > 0 else -1
		var envelope = 1.0 - (float(i) / jumlah_sampel) # Fade out
		data_suara[i] = int(gelombang * envelope * 60) + 128
		
	stream_koin.data = data_suara
	pemutar.stream = stream_koin
	
	# SOLUSI EROR 2: WAJIB memanggil add_child DULU sebelum mengatur letak global_position
	scene_utama.add_child(pemutar)
	pemutar.global_position = target_model.global_position
	
	pemutar.play()
	# Bersihkan pemutar suara setelah selesai berbunyi
	scene_utama.get_tree().create_timer(1.0).timeout.connect(pemutar.queue_free)
