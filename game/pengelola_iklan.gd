extends Node

signal iklan_ditutup(dapat_hadiah: bool)

# --- KUMPULAN ID IKLAN ---
# Di build debug (development), otomatis pakai ID test resmi Google.
# ID asli (produksi) hanya dipakai di build rilis. Lihat CLAUDE.md.
var id_rewarded = "ca-app-pub-3940256099942544/5224354917" if OS.is_debug_build() else "ca-app-pub-5633983261353937/8874486809"
var id_banner = "ca-app-pub-3940256099942544/6300978111" if OS.is_debug_build() else "ca-app-pub-5633983261353937/5262544854"
var id_app_open = "ca-app-pub-3940256099942544/9257395921" if OS.is_debug_build() else "ca-app-pub-5633983261353937/9333300157"
# Interstisial (Fase 1). Selama ID_INTERSTISIAL_ASLI kosong, build rilis pun memakai ID uji
# Google -- iklan uji TIDAK menghasilkan uang. Isi ID asli sebelum rilis ke Play Store.
const ID_INTERSTISIAL_UJI := "ca-app-pub-3940256099942544/1033173712"
const ID_INTERSTISIAL_ASLI := "" # contoh: "ca-app-pub-5633983261353937/xxxxxxxxxx"
var id_interstisial = ID_INTERSTISIAL_UJI if OS.is_debug_build() or ID_INTERSTISIAL_ASLI == "" else ID_INTERSTISIAL_ASLI

var status_hadiah = false
var timer_timeout: SceneTreeTimer

var rewarded_ad_loader
var rewarded_ad
var banner_view

# Variabel untuk App Open Ad
var app_open_ad_loader
var app_open_ad
var sedang_tampil_app_open = false

# ==========================================
# VAR BARU: PENAHAN CRASH & KEAMANAN BOOT
# ==========================================
var sdk_sudah_siap = false
var boot_awal = true
var abaikan_resume = false # <--- TAMBAHKAN BARIS INI

# ==========================================
# FASE 1: ATURAN TAYANG (angkanya cukup diubah di sini)
# ==========================================
const JEDA_MIN_LAYAR_PENUH := 180.0  # dtk minimal antar iklan layar penuh (interstisial, app open, berhadiah)
const MATCH_TANPA_IKLAN := 1         # pertandingan pertama setelah instal: tanpa interstisial & app open
const MAKS_REWARDED_PER_HARI := 8
const UMUR_MAKS_IKLAN := 3300.0      # dtk; interstisial & berhadiah kedaluwarsa 1 jam setelah dimuat (Google)
const UMUR_MAKS_APP_OPEN := 14000.0  # dtk; app open kedaluwarsa setelah 4 jam (Google)
const MIN_DI_LATAR_APP_OPEN := 30.0  # app open hanya kalau aplikasi ditinggal >= 30 dtk
const BERKAS_CATATAN := "user://iklan.cfg"
var bebas_iklan := false             # Remove Ads (Fase 7): diatur PengelolaPembelian; true = tanpa interstisial, app open, banner (berhadiah tetap)

var _catatan := ConfigFile.new()
var _geser_jam := 0.0                # HANYA uji: memajukan jam tanpa menunggu
var _jam_layar_penuh_terakhir := -100000.0
var _jam_mulai_latar := -1.0
var _jam_muat_app_open := 0.0

var interstisial_ad = null
var _pemuat_interstisial
var _jam_muat_interstisial := 0.0
var _sedang_muat_interstisial := false
var _sedang_tampil_interstisial := false
var _jeda_coba_interstisial := 30.0

var rewarded_siap = null             # iklan berhadiah yang sudah dimuat duluan (tombol WATCH AD)
var _pemuat_rewarded_duluan
var _jam_muat_rewarded := 0.0
var _sedang_muat_rewarded := false

func _ready():
	_catatan.load(BERKAS_CATATAN) # belum ada = kosong, tidak apa-apa
	MobileAds.initialize()

	# 1. Tunda pemuatan selama 1.5 detik agar mesin Android tidak kaget
	await get_tree().create_timer(1.5).timeout
	sdk_sudah_siap = true
	muat_iklan_app_open()
	muat_interstisial()
	muat_rewarded_duluan()
	
	# 2. Matikan pelindung boot awal setelah 3.5 detik (Melewati fase loading screen)
	await get_tree().create_timer(3.5).timeout
	boot_awal = false

# ==========================================
# 1. SISTEM DETEKSI APLIKASI (WARM START)
# ==========================================
func _notification(what):
	# Catat kapan aplikasi ditinggal. Iklan layar penuh milik kita sendiri juga
	# membuat aplikasi "ditinggal" -- itu tidak dihitung.
	if what == NOTIFICATION_APPLICATION_PAUSED:
		if not abaikan_resume and not sedang_tampil_app_open and not _sedang_tampil_interstisial:
			_jam_mulai_latar = _jam()
		return
	if what != NOTIFICATION_APPLICATION_RESUMED and what != NOTIFICATION_WM_WINDOW_FOCUS_IN:
		return
	var lama_di_latar = (_jam() - _jam_mulai_latar) if _jam_mulai_latar >= 0.0 else 0.0
	_jam_mulai_latar = -1.0
	if not sdk_sudah_siap or boot_awal or abaikan_resume:
		return
	# Menarik layar notifikasi / pindah aplikasi sebentar: tanpa iklan.
	if lama_di_latar < MIN_DI_LATAR_APP_OPEN or not _boleh_app_open():
		return
	tampilkan_app_open()

func _jam() -> float:
	# Jam dinding: tetap berjalan saat HP tidur (ticks berhenti), tidak ikut Engine.time_scale.
	return Time.get_unix_time_from_system() + _geser_jam

func _jeda_cukup() -> bool:
	return _jam() - _jam_layar_penuh_terakhir >= JEDA_MIN_LAYAR_PENUH

func jumlah_match_tuntas() -> int:
	return int(_catatan.get_value("iklan", "match_tuntas", 0))

func catat_match_tuntas() -> void:
	# Dipanggil pemain.gd tiap pertandingan selesai dengan pemenang.
	_catatan.set_value("iklan", "match_tuntas", jumlah_match_tuntas() + 1)
	_catatan.save(BERKAS_CATATAN)

func _boleh_app_open() -> bool:
	if bebas_iklan or jumlah_match_tuntas() < MATCH_TANPA_IKLAN or not _jeda_cukup():
		return false
	# Multiplayer & lobby Local Play: iklan layar penuh menghentikan aplikasi
	# sementara -- koneksi bisa putus, dan pemain sering keluar-masuk untuk
	# menyalakan hotspot/WiFi.
	if StatusJaringan.peran_multiplayer != "":
		return false
	var adegan = get_tree().current_scene
	if adegan != null and adegan.scene_file_path == "res://LocalPlay.tscn":
		return false
	return true

# ==========================================
# 2. SISTEM IKLAN APP OPEN
# ==========================================
func muat_iklan_app_open():
	if app_open_ad:
		return 
		
	var ad_request = AdRequest.new()
	var load_callback = AppOpenAdLoadCallback.new()
	load_callback.on_ad_loaded = _pada_app_open_dimuat
	load_callback.on_ad_failed_to_load = _pada_app_open_gagal_dimuat
	
	app_open_ad_loader = AppOpenAdLoader.new()
	app_open_ad_loader.load(id_app_open, ad_request, load_callback)

func _pada_app_open_dimuat(ad):
	app_open_ad = ad
	_jam_muat_app_open = _jam()

func _pada_app_open_gagal_dimuat(_err):
	push_warning("Gagal memuat App Open Ad.")

func tampilkan_app_open():
	if app_open_ad and not sedang_tampil_app_open:
		# Iklan app open kedaluwarsa 4 jam setelah dimuat (Google): muat ulang saja.
		if _jam() - _jam_muat_app_open > UMUR_MAKS_APP_OPEN:
			app_open_ad.destroy()
			app_open_ad = null
			muat_iklan_app_open()
			return
		sedang_tampil_app_open = true

		var full_screen_callback = FullScreenContentCallback.new()
		full_screen_callback.on_ad_dismissed_full_screen_content = _pada_app_open_ditutup
		full_screen_callback.on_ad_failed_to_show_full_screen_content = _pada_app_open_gagal_tampil_layar
		app_open_ad.full_screen_content_callback = full_screen_callback

		# Dicatat saat TAMPIL supaya iklan lain yang diminta di frame yang sama tidak ikut tampil.
		_jam_layar_penuh_terakhir = _jam()
		app_open_ad.show()
	elif not app_open_ad and not sedang_tampil_app_open:
		muat_iklan_app_open() 

func _pada_app_open_ditutup():
	sedang_tampil_app_open = false
	_jam_layar_penuh_terakhir = _jam()
	if app_open_ad:
		app_open_ad.destroy()
		app_open_ad = null
	muat_iklan_app_open()

func _pada_app_open_gagal_tampil_layar(_err):
	push_warning("App Open Ad gagal tampil.")
	_pada_app_open_ditutup()

# ==========================================
# 3. SISTEM IKLAN BANNER
# ==========================================
func tampilkan_banner():
	if bebas_iklan:
		return
	if banner_view:
		banner_view.destroy()
		
	var posisi_banner = AdPosition.new(AdPosition.Values.BOTTOM)
	banner_view = AdView.new(id_banner, AdSize.BANNER, posisi_banner)
	var ad_request = AdRequest.new()
	banner_view.load_ad(ad_request)

func sembunyikan_banner():
	if banner_view:
		banner_view.destroy()
		banner_view = null

# ==========================================
# 4. SISTEM IKLAN REWARDED
# ==========================================
func mulai_proses_iklan():
	status_hadiah = false
	
	if rewarded_ad:
		rewarded_ad.destroy()
		rewarded_ad = null
		
	var ad_request = AdRequest.new()
	var load_callback = RewardedAdLoadCallback.new()
	load_callback.on_ad_loaded = _pada_iklan_dimuat
	load_callback.on_ad_failed_to_load = _pada_iklan_gagal_dimuat
	
	rewarded_ad_loader = RewardedAdLoader.new()
	rewarded_ad_loader.load(id_rewarded, ad_request, load_callback)
	
	timer_timeout = get_tree().create_timer(10.0)
	timer_timeout.timeout.connect(_pada_iklan_timeout)

func _pada_iklan_timeout():
	if not status_hadiah and not rewarded_ad:
		push_warning("Waktu tunggu iklan habis (Timeout).")
		iklan_ditutup.emit(false)

func _pada_iklan_dimuat(ad):
	if timer_timeout and timer_timeout.timeout.is_connected(_pada_iklan_timeout):
		timer_timeout.timeout.disconnect(_pada_iklan_timeout)

	rewarded_ad = ad
	var full_screen_callback = FullScreenContentCallback.new()
	full_screen_callback.on_ad_dismissed_full_screen_content = _pada_iklan_ditutup
	full_screen_callback.on_ad_failed_to_show_full_screen_content = _pada_iklan_gagal_tampil
	rewarded_ad.full_screen_content_callback = full_screen_callback

	var reward_listener = OnUserEarnedRewardListener.new()
	reward_listener.on_user_earned_reward = _pada_hadiah_diterima

	abaikan_resume = true # <--- TAMBAHKAN INI: Kunci sistem App Open
	rewarded_ad.show(reward_listener)

func _pada_iklan_gagal_dimuat(_load_ad_error):
	push_warning("Gagal memuat iklan dari server Google.")
	if timer_timeout and timer_timeout.timeout.is_connected(_pada_iklan_timeout):
		timer_timeout.timeout.disconnect(_pada_iklan_timeout)
	iklan_ditutup.emit(false)

func _pada_iklan_gagal_tampil(_err):
	push_warning("Iklan gagal ditampilkan di layar.")
	_pada_iklan_ditutup()

func _pada_hadiah_diterima(_reward_item):
	status_hadiah = true

func _pada_iklan_ditutup():
	iklan_ditutup.emit(status_hadiah)
	status_hadiah = false
	if rewarded_ad:
		rewarded_ad.destroy()
		rewarded_ad = null
		
	# <--- TAMBAHKAN 2 BARIS INI DI PALING BAWAH --->
	# Jeda mutlak menunggu OS Android selesai melakukan transisi layar penuh
	# (jam nyata -- Quick Match mempercepat jam permainan)
	await get_tree().create_timer(1.0, true, false, true).timeout
	abaikan_resume = false # Buka kembali sistem App Open

# ==========================================
# 5. SISTEM IKLAN INTERSTISIAL (FASE 1)
# Jeda alami: setelah animasi menang/kalah, SEBELUM papan peringkat (anjuran
# Google: sebelum tombol lanjut). Tidak pernah menahan permainan.
# ==========================================
func muat_interstisial() -> void:
	if bebas_iklan or not sdk_sudah_siap or interstisial_ad != null or _sedang_muat_interstisial:
		return
	_sedang_muat_interstisial = true
	var cb = InterstitialAdLoadCallback.new()
	cb.on_ad_loaded = _pada_interstisial_dimuat
	cb.on_ad_failed_to_load = _pada_interstisial_gagal_dimuat
	_pemuat_interstisial = InterstitialAdLoader.new()
	_pemuat_interstisial.load(id_interstisial, AdRequest.new(), cb)

func _pada_interstisial_dimuat(ad) -> void:
	_sedang_muat_interstisial = false
	interstisial_ad = ad
	_jam_muat_interstisial = _jam()
	_jeda_coba_interstisial = 30.0

func _pada_interstisial_gagal_dimuat(_err) -> void:
	_sedang_muat_interstisial = false
	push_warning("Gagal memuat interstisial.")
	# Coba lagi nanti: 30 dtk, 60, 120, ... paling lama 10 menit sekali.
	var jeda = _jeda_coba_interstisial
	_jeda_coba_interstisial = minf(_jeda_coba_interstisial * 2.0, 600.0)
	get_tree().create_timer(jeda, true, false, true).timeout.connect(muat_interstisial)

func tampilkan_interstisial_akhir_match() -> void:
	# Selalu kembali. Belum waktunya / belum siap / offline: langsung kembali.
	if bebas_iklan or not sdk_sudah_siap or _sedang_tampil_interstisial or sedang_tampil_app_open:
		return
	if jumlah_match_tuntas() <= MATCH_TANPA_IKLAN or not _jeda_cukup() or interstisial_ad == null:
		muat_interstisial()
		return
	if _jam() - _jam_muat_interstisial > UMUR_MAKS_IKLAN:
		interstisial_ad.destroy()
		interstisial_ad = null
		muat_interstisial()
		return
	_sedang_tampil_interstisial = true
	abaikan_resume = true
	var wadah = {"selesai": false}
	var cb = FullScreenContentCallback.new()
	cb.on_ad_dismissed_full_screen_content = func(): wadah["selesai"] = true
	cb.on_ad_failed_to_show_full_screen_content = func(_err): wadah["selesai"] = true
	interstisial_ad.full_screen_content_callback = cb
	_jam_layar_penuh_terakhir = _jam()
	interstisial_ad.show()
	# Batas aman dihitung dalam FRAME: selama iklan tampil aplikasi dijeda (frame
	# berhenti), jadi batas ini hanya berjalan kalau plugin tidak pernah mengabari.
	var frame = 0
	while not wadah["selesai"] and frame < 1800:
		await get_tree().process_frame
		frame += 1
	_sedang_tampil_interstisial = false
	_jam_layar_penuh_terakhir = _jam()
	if interstisial_ad:
		interstisial_ad.destroy()
		interstisial_ad = null
	muat_interstisial()
	await get_tree().create_timer(1.0, true, false, true).timeout
	abaikan_resume = false

# ==========================================
# 6. IKLAN BERHADIAH PILIHAN PEMAIN (FASE 1)
# Dimuat duluan; tombol WATCH AD hanya muncul kalau rewarded_tersedia().
# (mulai_proses_iklan() lama tidak dipakai lagi sejak iklan wajib dilepas.)
# ==========================================
func muat_rewarded_duluan() -> void:
	if not sdk_sudah_siap or rewarded_siap != null or _sedang_muat_rewarded:
		return
	_sedang_muat_rewarded = true
	var cb = RewardedAdLoadCallback.new()
	cb.on_ad_loaded = _pada_rewarded_duluan_dimuat
	cb.on_ad_failed_to_load = _pada_rewarded_duluan_gagal
	_pemuat_rewarded_duluan = RewardedAdLoader.new()
	_pemuat_rewarded_duluan.load(id_rewarded, AdRequest.new(), cb)

func _pada_rewarded_duluan_dimuat(ad) -> void:
	_sedang_muat_rewarded = false
	rewarded_siap = ad
	_jam_muat_rewarded = _jam()

func _pada_rewarded_duluan_gagal(_err) -> void:
	_sedang_muat_rewarded = false
	get_tree().create_timer(60.0, true, false, true).timeout.connect(muat_rewarded_duluan)

func rewarded_tersedia() -> bool:
	# Pilihan pemain: TIDAK ikut jeda 3 menit, tapi tidak boleh menumpuk iklan lain.
	if rewarded_siap == null or _jumlah_rewarded_hari_ini() >= MAKS_REWARDED_PER_HARI:
		return false
	if sedang_tampil_app_open or _sedang_tampil_interstisial:
		return false
	if _jam() - _jam_muat_rewarded > UMUR_MAKS_IKLAN:
		rewarded_siap.destroy()
		rewarded_siap = null
		muat_rewarded_duluan()
		return false
	return true

func tonton_rewarded() -> bool:
	# Tombol WATCH AD. true = pemain menonton sampai hadiahnya diberikan.
	if not rewarded_tersedia():
		return false
	var iklan = rewarded_siap
	rewarded_siap = null
	var wadah = {"selesai": false, "dapat": false}
	var saat_ditutup = func(dapat):
		wadah["selesai"] = true
		wadah["dapat"] = dapat
	iklan_ditutup.connect(saat_ditutup, CONNECT_ONE_SHOT)
	status_hadiah = false
	abaikan_resume = true
	rewarded_ad = iklan # dibersihkan oleh _pada_iklan_ditutup (kode lama)
	var cb = FullScreenContentCallback.new()
	cb.on_ad_dismissed_full_screen_content = _pada_iklan_ditutup
	cb.on_ad_failed_to_show_full_screen_content = _pada_iklan_gagal_tampil
	iklan.full_screen_content_callback = cb
	var pendengar = OnUserEarnedRewardListener.new()
	pendengar.on_user_earned_reward = _pada_hadiah_diterima
	_jam_layar_penuh_terakhir = _jam()
	iklan.show(pendengar)
	var frame = 0 # batas aman dalam frame -- lihat interstisial
	while not wadah["selesai"] and frame < 3600:
		await get_tree().process_frame
		frame += 1
	if not wadah["selesai"]:
		if iklan_ditutup.is_connected(saat_ditutup):
			iklan_ditutup.disconnect(saat_ditutup)
		abaikan_resume = false # plugin tidak mengabari: jangan kunci app open selamanya
	if wadah["dapat"]:
		_tambah_rewarded_hari_ini()
	_jam_layar_penuh_terakhir = _jam()
	muat_rewarded_duluan()
	return wadah["dapat"]

func _hari_ini() -> String:
	return Time.get_date_string_from_system()

func _jumlah_rewarded_hari_ini() -> int:
	if str(_catatan.get_value("iklan", "rewarded_tanggal", "")) != _hari_ini():
		return 0
	return int(_catatan.get_value("iklan", "rewarded_jumlah", 0))

func _tambah_rewarded_hari_ini() -> void:
	_catatan.set_value("iklan", "rewarded_jumlah", _jumlah_rewarded_hari_ini() + 1)
	_catatan.set_value("iklan", "rewarded_tanggal", _hari_ini())
	_catatan.save(BERKAS_CATATAN)
