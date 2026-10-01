extends ColorRect

var is_double = false
var rotasi_roda = 0.0
var sudut_terakhir_suara = 0.0
var pemutar_suara: AudioStreamPlayer
var efek_filter: AudioEffectLowPassFilter

var tipe_dadu_aktif = "normal" 
# --- TAMBAHAN VARIABEL BARU UNTUK MENYIMPAN SUSUNAN ACAK ---
var susunan_angka_khusus: Array[int] = [] 

func _ready():
	var nama_bus = "RoletBus"
	var index_bus = AudioServer.get_bus_index(nama_bus)
	if index_bus == -1:
		AudioServer.add_bus()
		index_bus = AudioServer.bus_count - 1
		AudioServer.set_bus_name(index_bus, nama_bus)
		efek_filter = AudioEffectLowPassFilter.new()
		efek_filter.cutoff_hz = 1800.0
		AudioServer.add_bus_effect(index_bus, efek_filter)

	pemutar_suara = AudioStreamPlayer.new()
	pemutar_suara.bus = nama_bus
	add_child(pemutar_suara)
	
	var suara_ketukan = AudioStreamWAV.new()
	suara_ketukan.format = AudioStreamWAV.FORMAT_16_BITS
	suara_ketukan.mix_rate = 44100
	var data_suara = PackedByteArray()
	var durasi_detik = 0.035
	var total_sampel = int(44100 * durasi_detik)
	
	for i in range(total_sampel):
		var t = float(i) / 44100.0
		var progress = float(i) / total_sampel
		var envelope = exp(-progress * 6.0) * (1.0 - progress)
		var frekuensi_dasar = 320.0
		var gelombang_tonal = sin(2.0 * PI * frekuensi_dasar * t) * 0.6
		var gelombang_klik = sin(2.0 * PI * (frekuensi_dasar * 2.5) * t) * 0.3
		var acak_noise = randf_range(-1.0, 1.0) * 0.15
		var sampel_gabungan = (gelombang_tonal + gelombang_klik + acak_noise) * envelope
		var nilai_pcm = int(clamp(sampel_gabungan, -1.0, 1.0) * 32767.0)
		data_suara.append(nilai_pcm & 0xFF)
		data_suara.append((nilai_pcm >> 8) & 0xFF)
		
	suara_ketukan.data = data_suara
	pemutar_suara.stream = suara_ketukan
	pemutar_suara.volume_db = -3.0

func _get_jumlah_irisan() -> int:
	# --- PERBAIKAN: PAKSA 6 IRISAN UNTUK KARTU KHUSUS ---
	if tipe_dadu_aktif != "normal":
		return 6
	return 11 if is_double else 6

func _process(_delta):
	if visible:
		queue_redraw()
		
		var jumlah_irisan = float(_get_jumlah_irisan())
		var derajat_per_irisan = 360.0 / jumlah_irisan
		var sudut_sekarang = rad_to_deg(rotasi_roda)
		var indeks_irisan_sekarang = floor(sudut_sekarang / derajat_per_irisan)
		var indeks_irisan_sebelumnya = floor(sudut_terakhir_suara / derajat_per_irisan)
		
		if indeks_irisan_sekarang != indeks_irisan_sebelumnya:
			pemutar_suara.pitch_scale = randf_range(0.92, 1.08)
			pemutar_suara.play()
			sudut_terakhir_suara = sudut_sekarang

func _draw():
	var tengah = size / 2.0
	var radius = 220.0 

	draw_circle(tengah + Vector2(15, 15), radius + 5, Color(0, 0, 0, 0.4))
	draw_circle(tengah, radius + 15, Color(0.85, 0.65, 0.15)) 
	draw_circle(tengah, radius + 5, Color(0.1, 0.1, 0.1)) 

	var jumlah_irisan = _get_jumlah_irisan()
	var derajat_per_irisan = 360.0 / float(jumlah_irisan)
	var setengah_irisan = derajat_per_irisan / 2.0

	for i in range(jumlah_irisan):
		var sudut_tengah_asli = deg_to_rad(i * derajat_per_irisan)
		var sudut_awal = sudut_tengah_asli - deg_to_rad(setengah_irisan)
		var sudut_akhir = sudut_tengah_asli + deg_to_rad(setengah_irisan)
		
		var warna: Color
		if tipe_dadu_aktif != "normal":
			# --- PERBAIKAN: GUNAKAN 2 WARNA BERGANTIAN UNTUK 6 IRISAN ---
			warna = Color(0.8, 0.15, 0.15) if i % 2 == 0 else Color(0.15, 0.15, 0.15)
		else:
			if is_double and i == 10: warna = Color(0.15, 0.6, 0.15)
			else: warna = Color(0.8, 0.15, 0.15) if i % 2 == 0 else Color(0.15, 0.15, 0.15)
		
		draw_set_transform(tengah, rotasi_roda, Vector2.ONE)
		_gambar_potongan_kue(Vector2.ZERO, radius, sudut_awal, sudut_akhir, warna)
		var titik_luar = Vector2(cos(sudut_awal), sin(sudut_awal)) * radius
		draw_line(Vector2.ZERO, titik_luar, Color.WHITE, 4.0)

	for i in range(jumlah_irisan):
		var angka = 0
		# --- PERBAIKAN: MENGGAMBAR ANGKA BERDASARKAN SUSUNAN ACAK ---
		if tipe_dadu_aktif != "normal" and susunan_angka_khusus.size() == 6:
			angka = susunan_angka_khusus[i]
		else:
			angka = (i + 2) if is_double else (i + 1)
		
		var sudut_tengah_asli = deg_to_rad(i * derajat_per_irisan)
		var jarak_teks = radius * 0.65
		var sudut_global = rotasi_roda + sudut_tengah_asli
		var pos_teks_pusat = tengah + Vector2(cos(sudut_global), sin(sudut_global)) * jarak_teks
		
		draw_set_transform(pos_teks_pusat, sudut_global, Vector2.ONE)
		var font = ThemeDB.fallback_font
		var ukuran_font = 35 if (is_double and tipe_dadu_aktif == "normal") else 45
		draw_string(font, Vector2(-12, 12), str(angka), HORIZONTAL_ALIGNMENT_CENTER, -1, ukuran_font, Color.WHITE)

	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_circle(tengah + Vector2(3, 5), 25.0, Color(0, 0, 0, 0.4)) 
	draw_circle(tengah, 25.0, Color(0.85, 0.65, 0.15)) 
	draw_circle(tengah, 12.0, Color(0.2, 0.2, 0.2)) 

	var titik_jarum = PackedVector2Array([
		tengah + Vector2(radius + 35, -20),
		tengah + Vector2(radius + 35, 20),
		tengah + Vector2(radius - 5, 0)
	])
	var bayangan_jarum = PackedVector2Array([
		tengah + Vector2(radius + 38, -15),
		tengah + Vector2(radius + 38, 25),
		tengah + Vector2(radius - 2, 5)
	])
	
	draw_polygon(bayangan_jarum, PackedColorArray([Color(0, 0, 0, 0.5)]))
	draw_polygon(titik_jarum, PackedColorArray([Color.YELLOW]))
	
	var tepi_jarum = titik_jarum
	tepi_jarum.append(titik_jarum[0])
	draw_polyline(tepi_jarum, Color(0.6, 0.5, 0), 3.0)

func _gambar_potongan_kue(pusat, rad, s_awal, s_akhir, w):
	var titik = PackedVector2Array()
	titik.append(pusat)
	var langkah = 20
	for i in range(langkah + 1):
		var s = lerp(s_awal, s_akhir, float(i) / langkah)
		titik.append(pusat + Vector2(cos(s), sin(s)) * rad)
	draw_polygon(titik, PackedColorArray([w]))

func putar_rolet(target_angka, tipe_dadu = "normal"):
	tipe_dadu_aktif = tipe_dadu
	show()
	rotasi_roda = 0.0
	sudut_terakhir_suara = 0.0
	
	# --- PERBAIKAN 1: DEKLARASI TIPE ARRAY SECARA EKSPLISIT ---
	if tipe_dadu == "rendah":
		var set1: Array[int] = [1, 2, 3]
		set1.shuffle()
		var set2: Array[int] = [1, 2, 3]
		set2.shuffle()
		while set2[0] == set1[2] or set2[2] == set1[0]:
			set2.shuffle()
		susunan_angka_khusus = set1 + set2
	elif tipe_dadu == "tinggi":
		var set1: Array[int] = [10, 11, 12]
		set1.shuffle()
		var set2: Array[int] = [10, 11, 12]
		set2.shuffle()
		while set2[0] == set1[2] or set2[2] == set1[0]:
			set2.shuffle()
		susunan_angka_khusus = set1 + set2
	else:
		susunan_angka_khusus.clear()
	# ------------------------------------------------------------------------
	
	var jumlah_irisan = float(_get_jumlah_irisan())
	var derajat_per_irisan = 360.0 / jumlah_irisan
	
	# --- PERBAIKAN 2: MENCARI KOORDINAT TARGET SECARA ACAK UNTUK ANGKA KEMBAR ---
	var indeks_target = 0
	if tipe_dadu != "normal":
		var kemungkinan_indeks: Array[int] = []
		for i in range(susunan_angka_khusus.size()):
			if susunan_angka_khusus[i] == target_angka:
				kemungkinan_indeks.append(i)
		if kemungkinan_indeks.is_empty():
			# PERBAIKAN CRASH: seharusnya target_angka SELALU ada di susunan_angka_khusus
			# (pemain.gd menghitung hasil_dadu dari rentang yang sama dengan tipe_dadu
			# yang dikirim ke sini). Tapi kalau karena sebab apa pun (state race dsb.)
			# datanya sempat tidak sinkron, jangan sampai game force-close --
			# pick_random() pada array kosong dulu bikin crash di sini. Roda ini MURNI
			# tampilan: hasil dadu asli yang dipakai menggerakkan karakter (hasil_dadu /
			# target_angka) sudah dikirim terpisah lewat teks_dadu & bergerak_maju(),
			# jadi indeks cadangan di sini tidak memengaruhi jalannya permainan sama sekali.
			push_warning("Rolet: target_angka %s tidak cocok dengan susunan_angka_khusus %s (tipe_dadu=%s) -- pakai indeks cadangan supaya tidak crash." % [str(target_angka), str(susunan_angka_khusus), tipe_dadu])
			indeks_target = 0
		else:
			# Pilih secara acak apakah akan mendarat di angka kembaran pertama atau kedua
			indeks_target = kemungkinan_indeks.pick_random()
	else:
		indeks_target = (target_angka - 2) if is_double else (target_angka - 1)
	# ------------------------------------------------------------------------
	
	var deviasi_acak = randf_range(-(derajat_per_irisan / 2.0) + 2.0, (derajat_per_irisan / 2.0) - 2.0)
	var target_derajat = -(indeks_target * derajat_per_irisan) + deviasi_acak
	
	var total_rotasi = deg_to_rad((360 * 6) + target_derajat)
	
	var tween = get_tree().create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUART) 
	tween.tween_property(self, "rotasi_roda", total_rotasi, 3.5) 
	
	await tween.finished
