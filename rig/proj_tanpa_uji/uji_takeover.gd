extends "res://uji_mp.gd"
# CLIENT mengambil alih permainan setelah host keluar (lanjut lawan AI).
# ATURAN BARU: TIDAK ada tukar slot. Pemain di device ini tetap di slotnya
# sendiri (slot 1 = merah), petak & jebakan miliknya tetap warnanya, dan AI
# meneruskan slot yang ditinggalkan (slot 0 = biru) dengan seluruh asetnya.
var gagal_uji := 0
var siap_selesai := false

func _cek2(syarat: bool, pesan: String) -> void:
	if syarat:
		print("   ok   : ", pesan)
	else:
		gagal_uji += 1
		print("   GAGAL: ", pesan)

func _ready():
	Engine.max_fps = 60
	peran = ""
	StatusJaringan.peran_multiplayer = ""
	_bangun_adegan()
	# Device ini = CLIENT: pemain lokal di slot 1, host (slot 0) lewat jaringan.
	p.slot_lokal = 1
	p.daftar_pemain[0].jenis_kontrol = DataPemain.JenisKontrol.MANUSIA_JARINGAN
	p.daftar_pemain[0].id_jaringan = 1
	p.daftar_pemain[1].jenis_kontrol = DataPemain.JenisKontrol.MANUSIA_LOKAL
	StatusJaringan.peran_multiplayer = "client"

	p.daftar_pemain[0].uang = 1500; p.daftar_pemain[1].uang = 2600
	p.daftar_pemain[0].bintang = 3; p.daftar_pemain[1].bintang = 6
	p.koleksi_permata_pemain.assign(["A"])
	p.koleksi_permata_musuh.assign(["B", "C"])
	p.putaran_pemain = 2; p.putaran_musuh = 1
	for idx in [3, 4]:
		p.status_kepemilikan_petak[idx] = true; p.pemilik_petak[idx] = 0; p.nyawa_petak[idx] = 3
	for idx in [6, 7]:
		p.status_kepemilikan_petak[idx] = true; p.pemilik_petak[idx] = 1; p.nyawa_petak[idx] = 3
	p.level_menara_petak[6] = 1
	p.berhenti_di_petak_sendiri[6] = 1
	_atur_posisi(3, 6)
	p.giliran_sekarang = "musuh" # giliran pemain lokal (slot 1)
	p.fase_giliran = "awal"

	var j = preload("res://jebakan_air.gd").new(); j.name = "JebakanAir"; j.pemilik = 1
	papan[8].add_child(j)
	var j2 = preload("res://jebakan_air.gd").new(); j2.name = "JebakanAir"; j2.pemilik = 0
	papan[5].add_child(j2)
	await get_tree().process_frame

	print("\n== T1 host keluar: pemain lokal TETAP slot 1, AI meneruskan slot 0")
	log_kejadian.clear()
	await p.lanjutkan_dengan_ai()
	await get_tree().create_timer(1.0).timeout

	_cek2(p.slot_lokal == 1, "slot_lokal TETAP 1 (tidak ditukar)")
	_cek2(p.daftar_pemain[1].jenis_kontrol == DataPemain.JenisKontrol.MANUSIA_LOKAL, "slot 1 tetap pemain manusia di device ini")
	_cek2(p.daftar_pemain[0].jenis_kontrol == DataPemain.JenisKontrol.AI, "slot 0 (yang keluar) diambil alih AI")
	_cek2(StatusJaringan.peran_multiplayer == "", "sesi jaringan ditutup")
	_cek2(p.daftar_pemain[1].uang == 2600 and p.daftar_pemain[0].uang == 1500, "koin tiap slot tidak berpindah")
	_cek2(p.daftar_pemain[1].bintang == 6 and p.daftar_pemain[0].bintang == 3, "bintang tiap slot tidak berpindah")
	_cek2(Array(p.koleksi_permata_musuh) == ["B", "C"], "permata pemain lokal tetap di slot 1")
	_cek2(Array(p.koleksi_permata_pemain) == ["A"], "permata lawan tetap di slot 0")
	_cek2(p.putaran_musuh == 1 and p.putaran_pemain == 2, "hitungan putaran tidak berpindah")
	_cek2(p.pemilik_petak[6] == 1 and p.pemilik_petak[7] == 1, "petak pemain lokal TETAP milik slot 1 (warna asli)")
	_cek2(p.pemilik_petak[3] == 0 and p.pemilik_petak[4] == 0, "petak lawan TETAP milik slot 0 (warna asli)")
	_cek2(p.level_menara_petak[6] == 1, "menara di petak 6 tetap ada")
	_cek2(p.berhenti_di_petak_sendiri[6] == 1, "catatan berhenti di petak sendiri tidak hilang")
	_cek2(p.daftar_pemain[1].posisi_saat_ini == 6 and p.daftar_pemain[0].posisi_saat_ini == 3, "posisi karakter tiap slot tidak berpindah")
	_cek2(p.giliran_sekarang == "musuh", "giliran yang sedang berjalan tidak berubah (tetap pemain lokal)")
	var jb = papan[8].get_node_or_null("JebakanAir")
	var jb2 = papan[5].get_node_or_null("JebakanAir")
	_cek2(jb != null and jb.pemilik == 1, "jebakan pemain lokal tetap miliknya (pemilik 1)")
	_cek2(jb2 != null and jb2.pemilik == 0, "jebakan lawan tetap milik slot 0")
	# (periksa_status_petak versi harness mencatat "periksa|slot" -- menu aslinya tidak digambar di sini)
	_cek2(_ada(log_kejadian, "periksa|1"), "menu giliran pemain lokal (slot 1) disiapkan lagi -- permainan lanjut")

	await _uji_ai_slot_nol()
	await _uji_panel_solo()
	await _uji_menang_solo()

	print("\nUJI TAKEOVER/SOLO SELESAI -- gagal: ", gagal_uji)
	get_tree().quit()

func _uji_ai_slot_nol() -> void:
	print("\n== T1b AI benar-benar bisa bermain di SLOT 0 (biru)")
	p.menu_aksi.hide()
	p.daftar_pemain[0].uang = 3000
	p.daftar_pemain[0].posisi_saat_ini = 9
	p.daftar_pemain[1].posisi_saat_ini = 6
	_atur_posisi(9, 6)
	p.fase_giliran = "akhir"
	p.giliran_sekarang = "musuh" # slot 1 selesai -> ganti ke slot 0 (AI)
	var posisi_awal = p.daftar_pemain[0].posisi_saat_ini
	log_kejadian.clear()
	p.ganti_giliran()
	# Tunggu giliran AI selesai: giliran kembali ke pemain lokal (menu slot 1 disiapkan).
	var t = 0.0
	await get_tree().create_timer(1.0).timeout
	while not (p.giliran_sekarang == "musuh" and _ada(log_kejadian, "periksa|1")) and t < 40.0:
		await get_tree().process_frame
		t += get_process_delta_time()
	_cek2(p.daftar_pemain[0].posisi_saat_ini != posisi_awal, "AI di slot 0 melempar dadu & berjalan (posisi %d -> %d)" % [posisi_awal, p.daftar_pemain[0].posisi_saat_ini])
	_cek2(p.giliran_sekarang == "musuh" and _ada(log_kejadian, "periksa|1"), "setelah giliran AI, giliran kembali ke pemain lokal (slot 1) dan menunya disiapkan")
	_cek2(not _ada(log_kejadian, "periksa|0"), "giliran AI tidak pernah membuka menu manusia untuk slot 0")
	_cek2(p.daftar_pemain[1].posisi_saat_ini == 6, "karakter pemain lokal tidak ikut berpindah")

func _ada_tombol(teks: String) -> bool:
	for b in get_tree().current_scene.find_children("*", "Button", true, false):
		if b.text == teks:
			return true
	return false

func _klik(teks: String) -> bool:
	for b in get_tree().current_scene.find_children("*", "Button", true, false):
		if b.text == teks and not b.disabled:
			b.emit_signal("pressed")
			return true
	return false

func _uji_panel_solo() -> void:
	print("\n== T2 SOLO: panel syarat menang menahan permainan sampai START ditekan")
	p.target_permata_menang = 2
	siap_selesai = false
	_jalankan_kesiapan()
	await get_tree().create_timer(0.4).timeout
	_cek2(_ada_tombol("START GAME"), "panel HOW TO WIN muncul dengan tombol START GAME")
	_cek2(not siap_selesai, "permainan menunggu tombol START ditekan")
	_cek2(_klik("START GAME"), "tombol START GAME bisa ditekan")
	await get_tree().create_timer(0.5).timeout
	_cek2(siap_selesai, "setelah START, permainan lanjut")
	_cek2(not _ada_tombol("START GAME"), "panel tertutup")

func _jalankan_kesiapan() -> void:
	await p._tunggu_kesiapan_mulai()
	siap_selesai = true

func _uji_menang_solo() -> void:
	print("\n== T3 SOLO: pemain lokal (slot 1) lewat Start dengan 3000+ koin -> animasi menang")
	_pastikan_label_petak()
	_pasang_start(5, true)
	for i in range(JUMLAH_PETAK):
		p.status_kepemilikan_petak[i] = false; p.pemilik_petak[i] = -1
		p.nyawa_petak[i] = 0; p.level_menara_petak[i] = 0
	p.target_permata_menang = 0
	p.koleksi_permata_pemain.clear(); p.koleksi_permata_musuh.clear()
	p.daftar_pemain[1].uang = 3100
	p.daftar_pemain[0].uang = 900
	_atur_posisi(9, 3)
	p.giliran_sekarang = "musuh"; p.fase_giliran = "akhir"
	p.bergerak_maju(3, "musuh") # 3 -> 4 -> 5 (START) -> 6
	var t3 = 0.0
	while not _ada_tombol("EXIT TO MAIN MENU") and t3 < 20.0:
		await get_tree().process_frame
		t3 += get_process_delta_time()
	_cek2(p.teks_dadu.text.begins_with("VICTORY!"), "teks kemenangan muncul untuk pemain slot 1: '%s'" % p.teks_dadu.text)
	_cek2(_ada_tombol("EXIT TO MAIN MENU"), "papan peringkat + tombol EXIT TO MAIN MENU muncul")
