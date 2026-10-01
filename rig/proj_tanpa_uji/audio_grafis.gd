class_name AudioGrafis
extends RefCounted
## Dipindah dari pemain.gd (Fase 2 - pemecahan file).
## pemutar_bgm & pemutar_bgm_duel TETAP jadi variabel milik pemain.gd (bukan di sini),
## karena keduanya AudioStreamPlayer yang harus nempel di scene tree lewat add_child().
## File ini cuma isi LOGIKA-nya, datanya tetap di main_node.

static func setup_sistem_audio(main_node: Node) -> void:
	# 1. Pastikan Master Bus memiliki konfigurasi dasar
	var _master_bus = AudioServer.get_bus_index("Master")

	# 2. Buat Bus khusus untuk Musik (BGM)
	var bgm_bus_name = "BusMusik"
	var bgm_bus_index = AudioServer.get_bus_index(bgm_bus_name)
	if bgm_bus_index == -1:
		AudioServer.add_bus()
		bgm_bus_index = AudioServer.bus_count - 1
		AudioServer.set_bus_name(bgm_bus_index, bgm_bus_name)

	# 3. Buat Bus khusus untuk Efek Suara (SFX)
	var sfx_bus_name = "BusSFX"
	var sfx_bus_index = AudioServer.get_bus_index(sfx_bus_name)
	if sfx_bus_index == -1:
		AudioServer.add_bus()
		sfx_bus_index = AudioServer.bus_count - 1
		AudioServer.set_bus_name(sfx_bus_index, sfx_bus_name)

	# =======================================================
	# 4. TERAPKAN AUDIO DUCKING (VOLUME MUSIK NAIK-TURUN OTOMATIS)
	# =======================================================
	var ducking_fx = AudioEffectCompressor.new()
	ducking_fx.threshold = -25.0
	ducking_fx.ratio = 10.0
	ducking_fx.attack_us = 15000
	ducking_fx.release_ms = 800
	ducking_fx.sidechain = sfx_bus_name

	AudioServer.add_bus_effect(bgm_bus_index, ducking_fx)

	# 5. Pasang Pemutar Musik
	main_node.pemutar_bgm = AudioStreamPlayer.new()
	main_node.pemutar_bgm.bus = bgm_bus_name

	var file_bgm = load("res://Mellow Shore.ogg")
	if file_bgm:
		main_node.pemutar_bgm.stream = file_bgm
		main_node.pemutar_bgm.volume_db = -6.0
		main_node.add_child(main_node.pemutar_bgm)
		main_node.pemutar_bgm.play()
	else:
		push_error("File 'Mellow Shore.ogg' tidak ditemukan. Pastikan sudah dimasukkan ke Godot.")

	# ========================================================
	# 6. PASANG PEMUTAR MUSIK KHUSUS PERTARUNGAN (DUEL)
	# ========================================================
	main_node.pemutar_bgm_duel = AudioStreamPlayer.new()
	main_node.pemutar_bgm_duel.bus = bgm_bus_name

	var file_duel = load("res://Iron Onslaught.ogg")
	if file_duel:
		main_node.pemutar_bgm_duel.stream = file_duel
		main_node.pemutar_bgm_duel.volume_db = -4.0
		main_node.add_child(main_node.pemutar_bgm_duel)
	else:
		push_error("File 'Iron Onslaught.ogg' tidak ditemukan di Godot.")

static func mulai_musik_duel(main_node: Node) -> void:
	if main_node.pemutar_bgm and main_node.pemutar_bgm.playing:
		main_node.pemutar_bgm.stream_paused = true
	if main_node.pemutar_bgm_duel:
		main_node.pemutar_bgm_duel.play()

static func kembali_ke_musik_normal(main_node: Node) -> void:
	if main_node.pemutar_bgm_duel and main_node.pemutar_bgm_duel.playing:
		main_node.pemutar_bgm_duel.stop()
	if main_node.pemutar_bgm:
		main_node.pemutar_bgm.stream_paused = false

static func muat_seting_grafis(main_node: Node) -> void:
	await main_node.get_tree().process_frame

	var config = ConfigFile.new()
	var err = config.load("user://seting_grafis.cfg")
	var tingkat = "sedang"
	var tampilkan_fps = false

	if err == OK:
		tingkat = config.get_value("Pengaturan", "kualitas_grafik", "sedang")
		tampilkan_fps = config.get_value("Pengaturan", "tampilkan_fps", false)

	var vp = main_node.get_tree().root.get_viewport()

	vp.use_hdr_2d = true
	vp.scaling_3d_scale = hitung_skala_render(tingkat)

	if tingkat == "sangat_rendah":
		vp.use_hdr_2d = false
		vp.msaa_3d = Viewport.MSAA_DISABLED
		RenderingServer.directional_shadow_atlas_set_size(256, true)
	elif tingkat == "rendah":
		vp.msaa_3d = Viewport.MSAA_DISABLED
		RenderingServer.directional_shadow_atlas_set_size(512, true)
	elif tingkat == "sedang":
		vp.msaa_3d = Viewport.MSAA_DISABLED
		# Jangan diturunkan: bayangan awan berbentuk melengkung organik, jadi paling
		# cepat terlihat bergerigi kalau atlasnya dipangkas. Ini juga tidak membebani
		# perangkat lemah, karena di Low & Very Low bayangan matahari sudah dimatikan.
		RenderingServer.directional_shadow_atlas_set_size(2048, true)
	elif tingkat == "tinggi":
		vp.msaa_3d = Viewport.MSAA_4X
		RenderingServer.directional_shadow_atlas_set_size(4096, true)

	atur_visibilitas_fps(main_node, tampilkan_fps)

static func atur_visibilitas_fps(main_node: Node, nyala: bool) -> void:
	if main_node.label_fps:
		main_node.label_fps.visible = nyala

# ========================================================
# AUTO DETECT GRAFIS
# Mengukur FPS sungguhan, bukan menebak dari nama chip. Nama GPU di Android
# ada ratusan macam dan sering menyesatkan — mengukur langsung jauh lebih andal.
# ========================================================

const URUTAN_TINGKAT = ["sangat_rendah", "rendah", "sedang", "tinggi"]

static func hitung_skala_render(tingkat: String) -> float:
	# Skala tetap (mis. selalu 0.5) tidak adil antar perangkat: di layar 720p itu
	# berarti merender 0,29 juta piksel, di layar 1080p jadi 0,65 juta — beban lebih
	# dari dua kali lipat padahal setelannya sama. Jadi yang dipatok adalah JUMLAH
	# PIKSEL targetnya, lalu skalanya dihitung mundur dari resolusi layar sungguhan.
	var anggaran_piksel := 0.0
	match tingkat:
		"sangat_rendah": anggaran_piksel = 350000.0  # setara ~800x440
		"rendah": anggaran_piksel = 550000.0         # setara ~1000x550
		"sedang": anggaran_piksel = 920000.0         # setara ~1280x720
		_: return 1.0                                 # "tinggi" pakai resolusi asli

	var ukuran = DisplayServer.window_get_size()
	var piksel_layar = float(ukuran.x) * float(ukuran.y)
	if piksel_layar <= 0.0:
		return 1.0

	var skala = sqrt(anggaran_piksel / piksel_layar)
	# Jangan pernah membesarkan di atas resolusi asli, dan jangan terlalu buram
	return clamp(skala, 0.4, 1.0)

static func ada_setelan_tersimpan() -> bool:
	var config = ConfigFile.new()
	if config.load("user://seting_grafis.cfg") != OK:
		return false
	return config.get_value("Pengaturan", "kualitas_grafik", "") != ""

static func baca_tingkat() -> String:
	var config = ConfigFile.new()
	if config.load("user://seting_grafis.cfg") != OK:
		return "sedang"
	return config.get_value("Pengaturan", "kualitas_grafik", "sedang")

static func simpan_tingkat(tingkat: String) -> void:
	var config = ConfigFile.new()
	config.load("user://seting_grafis.cfg") # muat dulu agar setelan FPS tidak hilang
	config.set_value("Pengaturan", "kualitas_grafik", tingkat)
	config.save("user://seting_grafis.cfg")

static func ukur_fps(main_node: Node, durasi: float = 5.0) -> float:
	# Lewati 1 detik pertama: saat itu FPS selalu jatuh karena aset masih dimuat,
	# bukan karena perangkatnya lemah.
	await main_node.get_tree().create_timer(1.0).timeout

	var total := 0.0
	var jumlah := 0
	var sisa := durasi
	while sisa > 0.0:
		await main_node.get_tree().process_frame
		var fps := Engine.get_frames_per_second()
		if fps > 0:
			total += fps
			jumlah += 1
		sisa -= main_node.get_process_delta_time()

	if jumlah == 0:
		return 60.0
	return total / float(jumlah)

static func tentukan_tingkat(fps_terukur: float, tingkat_saat_ukur: String) -> String:
	# Naik/turun satu tingkat dari titik ukur — bukan lompat jauh, supaya hasilnya
	# tidak berayun liar kalau pengukurannya kebetulan meleset sedikit.
	var idx = URUTAN_TINGKAT.find(tingkat_saat_ukur)
	if idx == -1:
		idx = 2 # anggap "sedang"

	if fps_terukur < 35.0:
		idx = max(0, idx - 1)
	elif fps_terukur > 55.0:
		idx = min(URUTAN_TINGKAT.size() - 1, idx + 1)
	return URUTAN_TINGKAT[idx]

static func nama_tampilan(tingkat: String) -> String:
	match tingkat:
		"sangat_rendah": return "VERY LOW"
		"rendah": return "LOW"
		"sedang": return "MEDIUM"
		"tinggi": return "HIGH"
	return tingkat

static func terapkan_penuh(main_node: Node) -> void:
	# SATU-SATUNYA tempat yang memutuskan CARA setelan diberlakukan.
	# Kalau suatu saat terbukti memuat ulang scene bermasalah di perangkat tertentu,
	# cukup ganti isi fungsi ini jadi get_tree().quit() — tidak perlu menyentuh
	# bagian lain manapun.
	if StatusJaringan.peran_multiplayer != "":
		# Sedang bermain multiplayer: memuat ulang scene akan memutus koneksi dan
		# membuat lawan menunggu tanpa kepastian. Tutup aplikasi saja — pemain
		# memang sedang sengaja mengubah setelan, jadi keluarnya disengaja.
		main_node.get_tree().quit()
		return
	main_node.get_tree().reload_current_scene()
