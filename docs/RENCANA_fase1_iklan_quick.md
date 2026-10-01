# RENCANA FASE 1: Iklan & Quick Match

Disusun Opus (24-09) setelah membaca pengelola_iklan.gd ASLI (kiriman user 24-09), main_menu.gd,
layar_local_play.gd, status_jaringan.gd, ui_dinamis.gd, pemain.gd (giliran, gaji, menang, dadu, akhir
permainan, siaran state, migrasi), uji_robot_mp.gd, uji_sim.gd, dan kebijakan AdMob.
Dikerjakan Sonnet SETELAH user menyetujui bagian 1.

ATURAN USER: edit hanya baris/bagian yang relevan (jangan tulis ulang file); balas dalam Bahasa
Indonesia; teks untuk pemain = bahasa Inggris SEDERHANA; setelah selesai & lolos uji kirim SET LENGKAP
terbaru sekaligus dalam SATU pesan dan minta unduhan lama dibuang. File produksi: UJI_DUEL, UJI_SERI,
UJI_SELALU_PEDANG WAJIB tetap false. Salinan uji:
/tmp/claude-0/-home-claude/bc2a37a6-77d5-5593-942f-124ebd210f19/scratchpad/proj (sinkron lewat
sinkron_uji.sh; bedanya hanya saklar UJI_* dan pengelola_iklan.gd yang di rig berupa STUB).

## 0. Kenapa

- Sekarang: SINGLE PLAYER -> pilih peta -> iklan berhadiah WAJIB ditonton sampai habis
  (`main_menu.gd` `_proses_tombol_peta`). Tanpa internet solo tidak bisa dimainkan; pesan gagalnya
  berbahasa Indonesia ("GAGAL! PASTIKAN INTERNET NYALA..."). Local Play tidak punya iklan penuh sama sekali.
- User (24-09): iklan wajib ini sumber pendapatan utama sekarang -> transisinya harus hati-hati.
- Kebijakan AdMob untuk iklan berhadiah (support.google.com/admob/answer/7313578):
  "must only be served after a user affirmatively and unambiguously opts in" dan "Skipping the Rewarded
  Ad ... must not impede or interfere with the normal usage of the ... app". Gerbang sekarang
  menghalangi pemakaian normal -> berisiko dibatasi AdMob ("Ads restricted: Rewards implementation --
  User choice"), yang membuat pendapatan jadi nol.
- Maka: gerbang dilepas DAN penggantinya dipasang di rilis yang sama (bagian A). Quick Match (bagian B)
  mengikuti keputusan yang sudah ada di dokumen desain.

## 1. Keputusan (SEMUA DISETUJUI user 24-09)

K1. Interstisial setelah SETIAP pertandingan tuntas (ada pemenangnya), kecuali pertandingan pertama
    setelah instal. Tampil sesudah animasi menang/kalah, SEBELUM papan peringkat (anjuran Google: sebelum
    tombol lanjut). Jeda minimal 3 menit antar iklan layar penuh. Tidak pernah menahan permainan kalau
    offline / iklan belum siap. (Catatan awal di dokumen: "tiap 2-3 match" -- diubah supaya jumlah
    tayangan per match sama seperti sekarang: 1 iklan layar penuh per match solo, plus match Local Play.)
K2. Dua iklan berhadiah PILIHAN pemain, hanya di solo: tombol "WATCH AD: FREE CARD" di panel HOW TO WIN,
    dan "+300 COINS" saat hutang (sekali per pertandingan). Maks 8 per hari. Menonton iklan berhadiah
    juga dihitung dalam jeda 3 menit (pemain yang memilih iklan tidak langsung disusul interstisial).
    Putar ulang rolet setelah kalah duel DITUNDA ke Fase 5 (menyentuh alur duel yang rumit).
K3. App Open dirapikan: tidak pernah tampil di multiplayer atau lobby Local Play (iklan layar penuh
    menghentikan aplikasi sementara -> koneksi bisa putus; pemain juga keluar-masuk untuk menyalakan
    hotspot/WiFi); hanya kalau aplikasi ditinggal >= 30 detik (bukan saat menarik layar notifikasi);
    tidak sebelum pertandingan pertama selesai; ikut jeda 3 menit; dibuang kalau lebih dari 4 jam.
K4. Kecepatan 1,5x Quick Match = kecepatan mesin (Engine.time_scale): jalan, rolet, animasi, jeda teks,
    "berpikir" AI ikut 1,5x. Kembali 1x selama panel migrasi / CONNECTION LOST / OPPONENT LEFT / akhir
    permainan. Tidak ada batas waktu keputusan pemain di game ini, jadi pemain tidak jadi terburu-buru.
K5. Syarat permata Quick = separuh, dibulatkan ke atas: Grassland tetap 1 (petanya cuma punya 1 petak
    permata), Night Beach 2 -> 1.
K6. Perbaikan kecil yang ikut: papan peringkat selalu menaruh pemenang di baris 1 (juga Classic -- dulu
    pemenang bisa tercantum di baris 2 karena urutannya menurut koin), dan teks tunggal
    "Collect the gem" / "Need 1 gem!" (dulu "Collect all 1 gems", "Need 1 unique gems!").

Yang perlu disiapkan USER:
- Unit iklan **Interstitial** di AdMob: user memilih memakai ID uji Google DULU (24-09). Kode dibuat supaya
  nanti cukup mengisi satu konstanta `ID_INTERSTISIAL_ASLI` (A2a). JANGAN rilis Fase 1 ke Play Store sebelum
  konstanta itu terisi: iklan wajib (pendapatan utama) sudah hilang dan interstisial uji tidak dibayar.
- Sebelum rilis: catat angka AdMob 14 hari terakhir (tayangan & pendapatan per format) untuk dibandingkan
  14 hari sesudah rilis.

## 2. Bagian A: Iklan

### A1. main_menu.gd: lepas gerbang
Var baru `var _sudah_mulai: bool = false`. `_proses_tombol_peta(pilihan)` -> isinya cukup:
```gdscript
	# Penjaga ketuk dua kali: mouse_filter panel TIDAK menghalangi tombol anaknya, dan
	# tanpa jeda iklan ketukan kedua selama fade 1 dtk memulai permainan dua kali.
	if _sudah_mulai:
		return
	_sudah_mulai = true
	panel_map.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel_map.get_child(0).text = "- STARTING... -"
	sfx_player.stream = suara_hover
	sfx_player.play()
	_mulai_terjun_ke_game(pilihan)
```
(tween "MEMUAT IKLAN", `mulai_proses_iklan()`, teks GAGAL dihapus). `panel_map.get_child(0)` harus tetap
label judul -- lihat B2.

### A2. pengelola_iklan.gd ASLI (file user; tidak bisa diuji di rig -> uji T5 dengan plugin tiruan)
Salinan kerja: /home/claude/pengelola_iklan.gd. JANGAN disalin ke proj (rig memakai stub, lihat A6).
API plugin (Poing Studios) yang dipakai: `InterstitialAdLoader`, `InterstitialAdLoadCallback`,
`FullScreenContentCallback`, `RewardedAdLoader`, `RewardedAdLoadCallback`, `OnUserEarnedRewardListener`
-- pola sama dengan kode yang sudah jalan di HP (pemuat disimpan sebagai variabel anggota).

a) Di bawah `var id_app_open = ...` (keputusan user 24-09: SEMENTARA ID uji Google, juga di build rilis):
```gdscript
# Interstisial (Fase 1). Selama ID_INTERSTISIAL_ASLI kosong, build rilis pun memakai ID uji
# Google -- iklan uji TIDAK menghasilkan uang. Isi ID asli sebelum rilis ke Play Store.
const ID_INTERSTISIAL_UJI := "ca-app-pub-3940256099942544/1033173712"
const ID_INTERSTISIAL_ASLI := "" # contoh: "ca-app-pub-5633983261353937/xxxxxxxxxx"
var id_interstisial = ID_INTERSTISIAL_UJI if OS.is_debug_build() or ID_INTERSTISIAL_ASLI == "" else ID_INTERSTISIAL_ASLI
```
b) Di bawah blok `var abaikan_resume = false`:
```gdscript
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
var bebas_iklan := false             # untuk Remove Ads (Fase 7); selalu false sekarang

var _catatan := ConfigFile.new()
var _geser_jam := 0.0                # HANYA uji T5: memajukan jam tanpa menunggu
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
```
c) `_ready()`: baris pertama `_catatan.load(BERKAS_CATATAN)` (belum ada = kosong, tidak apa-apa); setelah
`muat_iklan_app_open()` tambah `muat_interstisial()` dan `muat_rewarded_duluan()`.

d) `_notification(what)` diganti:
```gdscript
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
```
e) Pembantu baru (letakkan setelah `_notification`):
```gdscript
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
	# sementara -- koneksi bisa putus.
	if StatusJaringan.peran_multiplayer != "":
		return false
	var adegan = get_tree().current_scene
	if adegan != null and adegan.scene_file_path == "res://LocalPlay.tscn":
		return false
	return true
```
f) App Open: `_pada_app_open_dimuat(ad)` tambah `_jam_muat_app_open = _jam()`. `tampilkan_app_open()`: di awal
cabang `if app_open_ad and not sedang_tampil_app_open:` tambah
```gdscript
		if _jam() - _jam_muat_app_open > UMUR_MAKS_APP_OPEN:
			app_open_ad.destroy()
			app_open_ad = null
			muat_iklan_app_open()
			return
```
Tepat sebelum `app_open_ad.show()` tambah `_jam_layar_penuh_terakhir = _jam()` (dicatat saat TAMPIL, supaya
iklan lain yang diminta di frame yang sama tidak ikut tampil). `_pada_app_open_ditutup()`: tambah juga
`_jam_layar_penuh_terakhir = _jam()`.

g) `_pada_iklan_ditutup()`: timer 1 dtk jadi `get_tree().create_timer(1.0, true, false, true)` (jam nyata --
Quick Match mempercepat jam permainan).

h) Bagian baru "5. SISTEM IKLAN INTERSTISIAL" dan "6. IKLAN BERHADIAH PILIHAN PEMAIN" (di akhir file):
```gdscript
# ==========================================
# 5. SISTEM IKLAN INTERSTISIAL (FASE 1)
# Jeda alami: setelah animasi menang/kalah, SEBELUM papan peringkat.
# Tidak pernah menahan permainan.
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
# (mulai_proses_iklan() lama tidak dipakai lagi -- dibiarkan.)
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
```

### A3. Akhir pertandingan (pemain.gd + ui_dinamis.gd)
- pemain.gd `_tampilkan_akhir_permainan(...)`: setelah `_permainan_selesai = true` panggil
  `PengelolaIklan.catat_match_tuntas()` (jalan sekali di tiap device per pertandingan tuntas).
- ui_dinamis.gd `tampilkan_akhir_permainan(...)`: setelah `await ... create_timer(DURASI_ANIMASI_AKHIR)`
  dan `canvas.queue_free()`, SEBELUM `_panel_papan_skor(...)`:
```gdscript
	# Tombol ⚙ -> EXIT selama animasi memuat ulang adegan: jangan tampilkan iklan /
	# papan peringkat untuk adegan yang sudah dibuang.
	if not is_instance_valid(main_node) or not main_node.is_inside_tree():
		return
	await PengelolaIklan.tampilkan_interstisial_akhir_match()
	if not is_instance_valid(main_node) or not main_node.is_inside_tree():
		return
```
- Keluar lewat menu jeda, OPPONENT LEFT, PLAY ALONE: tidak dihitung tuntas, tanpa interstisial.

### A4. Tawaran FREE CARD (solo, panel HOW TO WIN)
- pemain.gd `_tunggu_kesiapan_mulai()`:
  `var tawarkan = StatusJaringan.peran_multiplayer == "" and PengelolaIklan.rewarded_tersedia()` lalu
  `UiDinamis.tampilkan_panel_syarat_menang(self, _baris_syarat_menang(), tawarkan)`.
- ui_dinamis.gd `tampilkan_panel_syarat_menang(main_node, baris, tawaran_iklan := false)`: kalau true,
  tombol "WATCH AD: FREE CARD" (350x60, font 22, `_gaya_tombol(..., Color(0.75, 0.55, 0.1))`) tepat di atas
  START GAME. Ditekan -> tombolnya disembunyikan, lalu `main_node._tonton_iklan_kartu_awal(canvas)`.
- pemain.gd:
```gdscript
const KARTU_HADIAH_IKLAN = ["dadu_rendah", "dadu_tinggi", "pelindung", "pedang_1"]

func _tonton_iklan_kartu_awal(panel: CanvasLayer) -> void:
	var dapat = await PengelolaIklan.tonton_rewarded()
	var teks = "No ad right now. Try again later."
	if dapat:
		var kartu = _kartu_hadiah_acak()
		if not kartu.is_empty():
			daftar_pemain[slot_lokal].inventaris_kartu.append(kartu)
			var nama = str(kartu["teks"]).split("\n")[0]
			# Pedang tidak bisa lewat Use Card (petak_kartu.gd: "Swords can only be used when attacking!").
			if str(kartu["id"]).begins_with("pedang"):
				teks = "You got %s! It helps when you attack." % nama
			else:
				teks = "You got %s! Tap Use Card in your turn." % nama
	UiDinamis.tandai_menunggu_lawan(panel, teks) # mengisi label status panel

func _kartu_hadiah_acak() -> Dictionary:
	# Data kartu diambil dari petak kartu di papan (satu sumber dengan petak_kartu.gd).
	# randi() global, BUKAN mesin_acak -- urutan acak permainan tidak bergeser.
	for petak in rute_papan:
		if petak.get("is_petak_kartu") and petak.node_sistem_kartu != null:
			var pilihan = []
			for k in petak.node_sistem_kartu.database_efek:
				if KARTU_HADIAH_IKLAN.has(k["id"]):
					pilihan.append(k)
			if not pilihan.is_empty():
				return pilihan[randi() % pilihan.size()].duplicate(true)
	return {}
```

### A5. Tawaran +300 COINS saat hutang (solo)
- pemain.gd var baru `var _iklan_hutang_terpakai: bool = false` (reset di `_siapkan_peta_dan_mulai`).
- `sita_aset_untuk_hutang(aktor)`: setelah `await get_tree().create_timer(2.0).timeout` dan SEBELUM
  `if _is_ai(slot_hutang):` sisipkan
  `var lunas_iklan = await _tawarkan_iklan_hutang(slot_hutang)` lalu `if lunas_iklan: return`.
```gdscript
func _tawarkan_iklan_hutang(slot: int) -> bool:
	# SOLO: +300 koin dari iklan berhadiah, sekali per pertandingan. true = hutang
	# lunas dan giliran sudah diteruskan (pemanggil berhenti). Tanpa tawaran fungsi
	# ini kembali tanpa menunggu satu frame pun (jejak uji Classic tetap identik).
	if StatusJaringan.peran_multiplayer != "" or slot != slot_lokal or _is_ai(slot):
		return false
	if _iklan_hutang_terpakai or not PengelolaIklan.rewarded_tersedia():
		return false
	var mau = await UiDinamis.tanya_iklan_hutang(self)
	if not mau:
		return false
	var dapat = await PengelolaIklan.tonton_rewarded()
	if not dapat:
		teks_dadu.text = "No ad right now."
		await get_tree().create_timer(1.5).timeout
		return false
	_iklan_hutang_terpakai = true
	daftar_pemain[slot].uang += 300
	update_ui_status()
	teks_dadu.text = "+300 Coins!"
	await get_tree().create_timer(1.5).timeout
	if daftar_pemain[slot].uang >= 0:
		teks_dadu.text = "Debt cleared!"
		await get_tree().create_timer(1.5).timeout
		if not cek_game_over(): ganti_giliran()
		return true
	teks_dadu.text = "Still in minus. Sell a tile."
	await get_tree().create_timer(1.5).timeout
	return false
```
- ui_dinamis.gd `static func tanya_iklan_hutang(main_node) -> bool`: CanvasLayer layer 107, latar hitam
  0.85, judul "IN DEBT!" (font 44, oranye), teks "Watch an ad to get +300 coins?" (font 24), tombol
  "WATCH AD: +300 COINS" (emas, sama dengan A4) dan "NO THANKS" (abu-abu). Hasil ditampung di Array satu
  elemen (`var hasil = [null]`, lambda tombol mengisinya), lalu
  `while hasil[0] == null: await main_node.get_tree().process_frame`; hapus canvas; kembalikan hasil.

### A6. Stub rig (proj/pengelola_iklan.gd -- TIDAK dikirim)
Tambah: `var jumlah_interstisial := 0`, `var jumlah_match_tuntas := 0`, `var jumlah_rewarded := 0`,
`var uji_rewarded := false`, `var uji_jeda_interstisial := 0.0`;
`func catat_match_tuntas(): jumlah_match_tuntas += 1`;
`func tampilkan_interstisial_akhir_match()`: `jumlah_interstisial += 1`, lalu
`if uji_jeda_interstisial > 0.0: await get_tree().create_timer(uji_jeda_interstisial).timeout`;
`func rewarded_tersedia() -> bool: return uji_rewarded`;
`func tonton_rewarded() -> bool`: `jumlah_rewarded += 1`, tunggu 0.2 dtk, `return uji_rewarded`.
`sinkron_uji.sh` TIDAK menyalin pengelola_iklan.gd (tetap 13 file).

### A7. Uji di HP (user, build debug = iklan uji Google)
1. Mode pesawat: SINGLE PLAYER -> peta -> langsung main. Selesaikan match: tidak ada iklan, papan
   peringkat langsung muncul.
2. Internet nyala: match pertama setelah instal tanpa interstisial; match kedua -> interstisial setelah
   animasi menang/kalah, lalu papan peringkat.
3. Panel HOW TO WIN solo: tombol WATCH AD: FREE CARD -> tonton -> "You got ...!", kartu ada di Use Card.
4. Buat hutang (kalah bayar denda): panel IN DEBT! -> tonton -> +300 koin; di match yang sama tidak
   ditawarkan lagi.
5. App Open: tarik layar notifikasi -> tanpa iklan. Tinggalkan aplikasi >= 30 dtk di menu utama -> app
   open (setelah minimal 1 match tuntas). Di lobby Local Play / match multiplayer -> tidak pernah.

## 3. Bagian B: Quick Match

Aturan (dokumen desain): batas 8 ronde (2 pemain) / 6 (3) / 5 (4); menang lebih awal tetap boleh dengan
syarat biasa; dadu 2-12; syarat permata separuh (K5); animasi 1,5x (K4); setelah ronde terakhir pemenang =
kekayaan terbesar = koin + 300 per petak + 500 menara Lv1 + 800 tambahan Lv2 (= harga beli, jadi membeli
tidak mengubah kekayaan); seri -> petak terbanyak -> lempar koin. Bawaan Quick untuk semua; pilihan
terakhir diingat. Satu ronde = setiap slot mendapat satu giliran (giliran yang dilewati karena paralisis
tetap dihitung).

### B1. status_jaringan.gd
```gdscript
# Quick Match (Fase 1). Jumlah ronde menurut jumlah pemain.
const BATAS_RONDE_QUICK = {2: 8, 3: 6, 4: 5}
const BERKAS_PILIHAN := "user://pilihan_main.cfg"
var mode_quick: bool = false        # dipilih host di lobby (multiplayer)
# Engine.time_scale sebelum Quick Match mempercepatnya (-1 = tidak sedang diubah).
# TIDAK di-reset reset_susunan().
var skala_waktu_dasar: float = -1.0

static func baca_pilihan_quick() -> bool:
	var c = ConfigFile.new()
	if c.load(BERKAS_PILIHAN) != OK:
		return true # bawaan: Quick
	return bool(c.get_value("main", "quick", true))

static func simpan_pilihan_quick(nilai: bool) -> void:
	var c = ConfigFile.new()
	c.load(BERKAS_PILIHAN)
	c.set_value("main", "quick", nilai)
	c.save(BERKAS_PILIHAN)
```
`reset_susunan()`: tambah `mode_quick = false`.

### B2. main_menu.gd: sakelar solo
- `signal mulai_game(nama_peta, jumlah_ai, quick)`; `var quick_dipilih: bool = true`,
  `var tombol_quick: Button`, `var tombol_classic: Button`, `var label_ket_mode: Label`.
- `_ready()`: `quick_dipilih = StatusJaringan.baca_pilihan_quick()`. Setelah `panel_map.add_child(label_map)`
  (label tetap anak ke-0) tambah HBoxContainer (tengah, separation 10) berisi "QUICK MATCH"
  (Color(0.85, 0.5, 0.1)) dan "CLASSIC" (Color(0.35, 0.35, 0.6)) dari `_buat_tombol_menu`, lalu ubah
  `custom_minimum_size` jadi (170, 56) dan font 20; di bawahnya `label_ket_mode` (font 18, tengah, outline 5).
- `_pilih_panjang_match(quick)`: set, `StatusJaringan.simpan_pilihan_quick(quick)`, bunyi hover,
  `_segarkan_pilihan_mode()`.
- `_segarkan_pilihan_mode()` (dipanggil juga dari `_ke_menu_map()` karena jumlah lawan sudah diketahui):
  gaya terpilih = warna penuh + bingkai emas 3 px, lainnya warna.darkened(0.5) (tiru `_gaya_tombol_lobby`);
  teks keterangan: Quick -> "%d rounds. The richest player wins." dengan
  `StatusJaringan.BATAS_RONDE_QUICK[jumlah_ai_dipilih + 1]`; Classic -> "No round limit. Reach START with
  3000 coins."
- `_mulai_terjun_ke_game`: `mulai_game.emit(pilihan, jumlah_ai_dipilih, quick_dipilih)`.
- Foto panel SELECT STAGE di layar kecil (T6); kalau sesak, kecilkan tinggi tombol peta 70 -> 60 saja.

### B3. layar_local_play.gd: sakelar lobby
- `var quick_lobby: bool = true`, `var tombol_panjang_lobby: Array = []`; `_ready()`:
  `quick_lobby = StatusJaringan.baca_pilihan_quick()`.
- `_buat_panel_lobby()`: kolom KANAN, tepat sebelum `tombol_mulai_lobby = _tombol_lobby("START GAME", ...)`:
  label "MATCH" (20) + HBoxContainer (separation 10) dengan tombol "QUICK" dan "CLASSIC" (175x48) ->
  `_pilih_panjang_lobby.bind(true/false)`.
- `_segarkan_lobby()`: gaya kedua tombol (warna sama dengan B2; terpilih = `quick_lobby`),
  `disabled = not host`.
- `_pilih_panjang_lobby(quick)`: hanya host; set, simpan, `_segarkan_lobby()`, `_kirim_info_lobby()`.
- RPC: `rpc_info_lobby(indeks_mode, peta, urutan, quick)` (client menyimpan ke `quick_lobby`);
  `rpc_mulai_dari_lobby(jenis, peer_slot, peta, id_sesi, quick)`;
  `_masuk_permainan(peran, jenis, peer_slot, peta, id_sesi, quick)` -> `StatusJaringan.mode_quick = quick`.
  Semua HP wajib versi yang sama (sudah berlaku sejak TAHAP 1).

### B4. pemain.gd: aturan
Variabel baru (dekat `SYARAT_KOIN_MENANG`):
```gdscript
# --- QUICK MATCH (Fase 1) ---
const KECEPATAN_QUICK := 1.5
var mode_quick: bool = false
var batas_ronde: int = 0             # 0 = tanpa batas (Classic)
var ronde_sekarang: int = 1
var jumlah_permata_peta: int = 0     # permata di peta (target Quick = separuh)
var _giliran_berjalan: bool = false  # sejak START ditekan semua (kecepatan 1,5x)
var label_ronde: RichTextLabel = null
var _ronde_spanduk: int = -1         # ronde yang spanduk FINAL ROUND-nya sudah tampil
# Hasil akhir -- dipakai robot uji sekarang, XP di Fase 2.
var _alasan_akhir: String = "start"  # "start" | "ronde" | "ronde_koin"
var _slot_pemenang_akhir: int = -1
var _papan_skor_akhir: Array = []
var _akhir_diterima: bool = false    # client: kabar akhir dari host sudah tiba (lihat rpc_permainan_selesai)
```
- `_ready()`: jalur multiplayer ->
  `_siapkan_peta_dan_mulai.call_deferred(peta_mp, daftar_pemain.size() - 1, StatusJaringan.mode_quick)`.
- `_siapkan_peta_dan_mulai(pilihan_peta: String, jumlah_ai: int = 1, quick: bool = false)`:
  - awal: `mode_quick = quick`, `ronde_sekarang = 1`, `_ronde_spanduk = -1`, `_iklan_hutang_terpakai = false`.
  - setelah slot siap (sesudah blok `_siapkan_slot_pemain` / HUD banyak pemain):
    `batas_ronde = StatusJaringan.BATAS_RONDE_QUICK.get(jumlah_pemain(), 8) if mode_quick else 0`.
  - setelah blok pilih peta (mode_rolet_double diset per peta):
    `if mode_quick: mode_rolet_double = true; rolet.is_double = true` (dua baris).
  - setelah hitung `target_permata_menang`: `jumlah_permata_peta = target_permata_menang`, lalu
    `if mode_quick and target_permata_menang > 1: target_permata_menang = ceili(target_permata_menang / 2.0)`.
  - kalau `mode_quick`: `label_ronde = UiDinamis.buat_label_ronde(self)` + `_perbarui_label_ronde()`.
- `lempar_dadu`: `if get_parent().get_node_or_null("PetaPantai") == null:` ->
  `if get_parent().get_node_or_null("PetaPantai") == null and not mode_quick:` (Grassland Quick tetap 2-12).
- `_mulai_transisi_game`: tepat setelah `await _tunggu_kesiapan_mulai()` dan SEBELUM pemeriksaan
  `generasi` (supaya device yang meneruskan permainan setelah host keluar di panel HOW TO WIN tetap 1,5x):
  `_giliran_berjalan = true`; di tempat `teks_uang.show()` dst: `if label_ronde: label_ronde.show()`.
- `ganti_giliran()`: ganti baris `var slot = _slot_berikutnya(...)` + sesudahnya menjadi:
```gdscript
	var slot = _slot_berikutnya(_slot_dari_aktor(giliran_sekarang))
	# QUICK MATCH: giliran kembali ke P1 = satu ronde selesai.
	if batas_ronde > 0 and slot == 0:
		# CONNECTION LOST (P1 menunggu pemain kembali): hitung ronde SETELAH mereka
		# kembali. Kalau ronde terakhir diakhiri di sini, HP lain tidak pernah tahu.
		# Keputusan putus yang masih tertunda 3 dtk (_putuskan_setelah_jeda) ditunggu
		# dulu -- giliran AI bisa selesai lebih cepat daripada keputusan itu. Lalu pola
		# yang sama dengan awal _mulai_giliran (sinyal & penanda yang sama).
		while not _putus_tertunda.is_empty():
			await get_tree().process_frame
		while _menunggu_pemain_kembali:
			_dijeda_di_awal_giliran = true
			await pemain_kembali_selesai
		_dijeda_di_awal_giliran = false
		if ronde_sekarang + 1 > batas_ronde:
			await _akhiri_karena_ronde_habis()
			return
		ronde_sekarang += 1
		_perbarui_label_ronde()
	giliran_sekarang = _aktor_dari_slot(slot)
```
  (Classic: `batas_ronde == 0` -> tidak ada yang berubah, urutan acak pun tidak.)
- Fungsi baru:
```gdscript
func _jumlah_petak_slot(slot: int) -> int:
	var n = 0
	for i in range(rute_papan.size()):
		if status_kepemilikan_petak[i] and pemilik_petak[i] == slot:
			n += 1
	return n

func _kekayaan_slot(slot: int) -> int:
	# Koin + nilai beli semua petak & menara (Quick Match).
	var total = daftar_pemain[slot].uang
	for i in range(rute_papan.size()):
		if status_kepemilikan_petak[i] and pemilik_petak[i] == slot:
			total += harga_tanah
			if level_menara_petak[i] >= 1: total += harga_menara_lv1
			if level_menara_petak[i] == 2: total += harga_menara_lv2
	return total

func _pemenang_kekayaan() -> Dictionary:
	# Kekayaan terbesar -> petak terbanyak -> lempar koin (mesin_acak; hanya host/solo).
	var calon = []
	var terbaik = -2147483648
	for s in range(jumlah_pemain()):
		var k = _kekayaan_slot(s)
		if k > terbaik:
			terbaik = k
			calon = [s]
		elif k == terbaik:
			calon.append(s)
	if calon.size() > 1:
		var paling = -1
		var sisa = []
		for s in calon:
			var n = _jumlah_petak_slot(s)
			if n > paling:
				paling = n
				sisa = [s]
			elif n == paling:
				sisa.append(s)
		calon = sisa
	if calon.size() > 1:
		return {"slot": calon[mesin_acak.randi_range(0, calon.size() - 1)], "koin": true}
	return {"slot": calon[0], "koin": false}

func _akhiri_karena_ronde_habis() -> void:
	var hasil = _pemenang_kekayaan()
	_alasan_akhir = "ronde_koin" if hasil["koin"] else "ronde"
	await _akhiri_permainan(hasil["slot"])
```
- `_akhiri_permainan(slot_pemenang)`: `_susun_papan_skor(slot_pemenang)`; RPC ditambah argumen
  `_alasan_akhir`; `await _tampilkan_akhir_permainan(slot_pemenang, papan_skor, _alasan_akhir)`.
- `_susun_papan_skor(slot_pemenang: int = -1)`: tiap baris tambah `"kekayaan": _kekayaan_slot(slot)` (hitung
  petak lewat `_jumlah_petak_slot`). Urutan: Quick -> kekayaan menurun, seri -> petak menurun; Classic ->
  koin menurun (lama). Lalu pemenang dipindah ke baris pertama (K6):
  `hasil.push_front(hasil.pop_at(i))`.
- `rpc_permainan_selesai(slot_pemenang, posisi_pemenang, papan_skor, alasan: String = "start")`:
  baris pertama `_akhir_diterima = true` (var baru, bool false). `alasan == "start"` ->
  `await _tunggu_langkah_ke_petak(posisi_pemenang)` (lama); selain itu `await _selesaikan_replay_lokal()`
  (menunggu langkah, duel, geiser, paralisis & serangan yang masih diputar, maks 20 dtk). Penantian
  `replay_serangan_selesai` yang sudah ada TETAP. Teruskan `alasan` ke `_tampilkan_akhir_permainan`.
- `_saat_peer_jaringan_disconnect`: `if _permainan_selesai:` -> `if _permainan_selesai or _akhir_diterima:`
  (host keluar / iklan di HP host membuatnya terputus saat client masih menunggu replay -> panel HOST LEFT
  atau OPPONENT LEFT jangan menutupi layar akhir).
- `mulai_sekarang_migrasi()`: setelah `rpc("rpc_lanjut_setelah_migrasi", ...)`, kalau `_permainan_selesai`
  (permainan sempat berakhir selama CONNECTION LOST, mis. menang di START): kirim
  `rpc("rpc_permainan_selesai", _slot_pemenang_akhir, -1, _papan_skor_akhir, _alasan_akhir)`, set
  `_mode_jaringan_putus = false` dan `_menunggu_pemain_kembali = false`, lalu `return` (jangan
  `_lanjutkan_setelah_pemain_kembali` / `_lanjutkan_dari_state_terakhir`). Posisi -1 = tidak ada langkah
  yang ditunggu.
- `_tampilkan_akhir_permainan(slot_pemenang, papan_skor, alasan: String = "start")`: simpan
  `_alasan_akhir`, `_slot_pemenang_akhir`, `_papan_skor_akhir`; `PengelolaIklan.catat_match_tuntas()` (A3).
  Teks untuk alasan ronde:
  - "ronde": `"TIME UP! " + ("You are the richest!" if menang else _nama_slot(slot_pemenang) + " is the richest!")`
  - "ronde_koin": `"TIME UP! Tie! Coin toss winner: " + ("You!" if menang else _nama_slot(slot_pemenang) + "!")`
  - "start": teks VICTORY / GAME OVER lama.
- `_baris_syarat_menang()`: Classic tetap, kecuali baris permata memakai `_teks_syarat_permata()`. Quick:
```gdscript
	baris.append("QUICK MATCH: %d rounds, then the richest player wins" % batas_ronde)
	baris.append("Richest = coins + tiles + towers")
	if target_permata_menang > 0:
		baris.append(_teks_syarat_permata())
		baris.append("Win early: reach START with %d+ coins and %s" % [SYARAT_KOIN_MENANG, "the gem" if target_permata_menang == 1 else "the gems"])
	else:
		baris.append("Win early: reach START with %d+ coins" % SYARAT_KOIN_MENANG)
	baris.append("Salary at START: +500, +10 per tile you own, +3 stars")
	baris.append("Buy a tile, then STOP on it again to build a tower")
```
  `_teks_syarat_permata()`: 1 dari 1 -> "Collect the gem on the board"; target < jumlah_permata_peta ->
  "Collect %d of the %d gems on the board"; lainnya "Collect all %d gems on the board" (teks lama).
- Gaji gagal (`bergerak_maju` & `rpc_gaji_gagal`): target 1 -> "SALARY FAILED! Need 1 gem!"; lebih dari 1 ->
  teks lama PERSIS (jejak sim Classic memakai target 2).

### B5. Tampilan (ui_dinamis.gd + pemain.gd)
- `static func buat_label_ronde(main_node) -> RichTextLabel`: gaya papan seperti TeksDadu (latar gelap 0.85,
  bingkai emas, bawah 3 px, sudut 10, margin 16/4), font 20, `bbcode_enabled`, `fit_content`, tanpa wrap &
  scroll, `mouse_filter` IGNORE, anchor_left/right 0.5, offset_left -100, offset_right 100, offset_top 88
  (di bawah TeksDadu, di antara panel koin kiri & kanan), tersembunyi sampai `_mulai_transisi_game`; induknya
  `main_node.teks_dadu.get_parent()`.
- pemain.gd:
```gdscript
func _perbarui_label_ronde() -> void:
	if label_ronde == null or batas_ronde <= 0:
		return
	var r = mini(ronde_sekarang, batas_ronde)
	if r >= batas_ronde:
		label_ronde.text = "[center][color=#ff6644]FINAL ROUND %d/%d[/color][/center]" % [r, batas_ronde]
		if _ronde_spanduk != r:
			_ronde_spanduk = r
			UiDinamis.tampilkan_spanduk(self, "FINAL ROUND!", Color(1.0, 0.45, 0.3))
	else:
		label_ronde.text = "[center]ROUND %d/%d[/center]" % [r, batas_ronde]
```
- `static func tampilkan_spanduk(main_node, teks, warna)`: CanvasLayer layer 104, Label FULL_RECT rata
  tengah, font 72, outline 12 hitam, mouse IGNORE; tween modulate:a 0 -> 1 (0.25 dtk), diam 1.3 dtk, -> 0
  (0.4 dtk), lalu `canvas.queue_free`. Induk: `main_node.get_tree().current_scene`.
- `_panel_papan_skor`: kalau `main_node.mode_quick`: di bawah "FINAL STANDINGS" label kecil (18, abu-abu)
  "Total = coins + tiles + towers"; baris utama `"%d.  %s  —  %d total" % [i + 1, nama, kekayaan]`; detail
  `"coins %d    tiles %d    stars %d    gems %d"`. Classic tidak berubah.

### B6. Kecepatan 1,5x (pemain.gd)
```gdscript
func _atur_kecepatan_permainan() -> void:
	# QUICK MATCH: 1,5x selama giliran berjalan normal; panel yang menghentikan
	# permainan kembali 1x (batas waktu jaringan di sana memakai jam permainan).
	# Classic TIDAK PERNAH menyentuh Engine.time_scale (rig & uji lama tetap sama).
	if not mode_quick:
		return
	if StatusJaringan.skala_waktu_dasar < 0.0:
		StatusJaringan.skala_waktu_dasar = Engine.time_scale # 1 di HP, 3 di rig uji
	var cepat = _giliran_berjalan and not _permainan_selesai and not _migrasi_berjalan \
		and not _mode_jaringan_putus and not _panel_putus_terbuka
	var target = StatusJaringan.skala_waktu_dasar * (KECEPATAN_QUICK if cepat else 1.0)
	if not is_equal_approx(Engine.time_scale, target):
		Engine.time_scale = target
```
- Panggil di baris pertama `_process(delta)`.
- `_putuskan_setelah_jeda()`: `create_timer(3.0)` -> `create_timer(3.0, true, false, mode_quick)` (3 dtk nyata
  di Quick; Classic tidak berubah, termasuk di rig).
- `_ready()` baris pertama (Engine global; tidak ikut ter-reset saat adegan dimuat ulang):
```gdscript
	if StatusJaringan.skala_waktu_dasar >= 0.0:
		Engine.time_scale = StatusJaringan.skala_waktu_dasar
		StatusJaringan.skala_waktu_dasar = -1.0
```

### B7. Sinkron
- `_siarkan_state_giliran`: tambah `"ronde": ronde_sekarang` ke `data`.
- `rpc_terima_state_giliran`: di sebelah blok `if data.has("putaran"):` (DI ATAS `return` awal untuk
  migrasi): `if data.has("ronde"):` -> `ronde_sekarang = int(data["ronde"])` dan `_perbarui_label_ronde()`
  (client memunculkan spanduk FINAL ROUND sendiri saat ronde terakhir mulai).
- Host baru hasil migrasi & "lanjut sendiri" meneruskan ronde dari siaran terakhir; `mode_quick`,
  `batas_ronde` sudah dimiliki tiap HP sejak awal. Tidak ada perubahan lain di jalur migrasi.

## 4. Uji (rig)

T0. Sebelum mengedit apa pun: `cp -r proj proj_sebelum_fase1` (pembanding T1).
PENTING: `sinkron_uji.sh` menyalakan UJI_DUEL & UJI_SERI di proj -> dadu SELALU 3 dan duel selalu seri.
Itu bagus untuk cakupan duel, tapi dadu 2-12, jarak satu putaran, dan menang di START tidak teruji. Buat
salinan kedua `proj_tanpa_uji` (sinkron yang sama, TANPA sed UJI_*) untuk T3b & T4b.
Robot (proj/uji_robot_mp.gd, TIDAK dikirim):
- argumen `panjang=quick|classic` (bawaan `classic` supaya 27 skenario lama tidak berubah); host mengklik
  "QUICK"/"CLASSIC" setelah peta.
- `_potret()`: tambah `s["ronde"] = p.get("ronde_sekarang")`.
- Saat `_permainan_selesai` (sekali): `AKHIR alasan=%s pemenang=%d ronde=%d/%d papan=%s` dari `_alasan_akhir`,
  `_slot_pemenang_akhir`, `ronde_sekarang`, `batas_ronde`, `_papan_skor_akhir`. Host menunggu 6 dtk sebelum
  `rpc_uji_selesai`; client di `rpc_uji_selesai` menunggu `_permainan_selesai` (maks 20 dtk) dan mencatat
  AKHIR dulu.
Sim (proj/uji_sim.gd): argumen `quick=1` -> setelah `_bangun()`: `p.mode_quick = true`,
`p.batas_ronde = StatusJaringan.BATAS_RONDE_QUICK[n_pemain]`, `p.ronde_sekarang = 1`,
`p.target_permata_menang = 1`, `p.mode_rolet_double = true`; berhenti saat `p._permainan_selesai` dan catat
alasan/pemenang/ronde/kekayaan tiap slot. `_snap()` menambah ronde HANYA kalau quick (jejak Classic tetap
sama). `jalankan_sim.sh`: teruskan `$EXTRA`.

T1. Classic identik: `jalankan_sim.sh` untuk pemain 2/3/4 x manusia 0/1 x seed 7/8/9, giliran 60, di
    proj_sebelum_fase1 dan proj -> jejak identik (`diff`).
T2. Regresi multiplayer Classic: `uji_final_tahap2.sh` (27 skenario) -> semua seperti sebelumnya.
T3. Quick solo.
    a) Sim (manusia=0, `EXTRA="quick=1"`): pemain 2/3/4 x seed 7..12. Berakhir karena ronde tepat setelah
       batas x jumlah pemain giliran (atau lebih awal karena menang di START); pemenang = kekayaan terbesar
       menurut hitungan ulang sim.
    b) Seri: skrip kecil yang menyiapkan keadaan dua slot dengan kekayaan & jumlah petak sama lalu memanggil
       `_pemenang_kekayaan()` dengan 20 seed `mesin_acak` -> `koin` true dan kedua slot pernah menang; satu
       kasus kekayaan sama tapi petak beda -> petak terbanyak menang, `koin` false.
    c) Adegan asli (`uji_nyata`, di proj_tanpa_uji): robot diberi argumen `panjang=quick|classic` dan
       mengklik "QUICK MATCH"/"CLASSIC" sebelum peta. Quick & Classic x lawan 1/2/3 x alam & pantai:
       target permata (alam 1, pantai 1 di Quick / 2 di Classic), dadu 2-12 di alam Quick, label ronde,
       spanduk FINAL ROUND, TIME UP. Dua run dengan stub `uji_rewarded = true`: robot mengklik
       "WATCH AD: FREE CARD" (inventaris slot 0 bertambah 1 kartu dari daftar hadiah) dan, saat panel
       IN DEBT! muncul, "WATCH AD: +300 COINS" (uang +300, tidak ditawarkan lagi di match itu).
T4. Quick multiplayer (`EXTRA="panjang=quick"`, giliran 60):
    Q1 `./jalankan_mp3.sh q_1 0 alam 1 "" 60 61`; Q2 `q_2 1 pantai 1 "" 60 62`; Q3 `q_3 3 alam 2 "" 60 63`;
    Q4 `q_4 5 alam 3 "" 60 64`; Q5 migrasi `q_5 5 alam 3 host_keluar_migrasi 60 65 8`;
    Q6 `EXTRA="panjang=quick pedang_awal=1 kartu_awal=1" ./jalankan_mp3.sh q_6 4 alam 2 "" 60 66`;
    Q7 client keluar `q_7 3 alam 2 client_keluar 60 67 8 2`;
    Q8 hotspot P1 mati di giliran TERAKHIR: `q_8 4 alam 2 host_hotspot_mati 60 68 20` (3P+1AI = 4 pemain x 5
       ronde; giliran ke-20 = giliran AI P4, yang tetap berjalan di HP P1) -> permainan baru berakhir SETELAH
       WAIT FOR PLAYERS dan START NOW, dan semua HP mencatat baris AKHIR yang sama.
    T4b: Q1 dan Q4 diulang di proj_tanpa_uji (dadu 2-12 sungguhan).
T5. Logika iklan dengan plugin tiruan: proyek kecil scratchpad/proj_iklan berisi pengelola_iklan.gd ASLI +
    status_jaringan.gd + kelas tiruan (`MobileAds`, `AdRequest`, `AdView`, `AdSize`, `AdPosition` dengan enum
    `Values`, `AppOpenAdLoader`, `AppOpenAdLoadCallback`, `InterstitialAdLoader`, `InterstitialAdLoadCallback`,
    `RewardedAdLoader`, `RewardedAdLoadCallback`, `FullScreenContentCallback`, `OnUserEarnedRewardListener`;
    iklan tiruan: `show()` memanggil callback ditutup satu frame kemudian, `destroy()`). Skenario (jam
    dimajukan lewat `_geser_jam`, notifikasi dikirim dengan `notification(...)`):
    a) match ke-1 tanpa interstisial, ke-2 tampil; b) dua match dalam 3 menit -> yang kedua tanpa;
    c) iklan dimuat > 55 menit lalu -> dibuang & dimuat ulang, tidak tampil; d) gagal muat -> fungsi kembali
    tanpa menunggu; e) berhadiah maks 8/hari, hitungan kembali 0 esok hari; f) app open: tidak saat
    `peran_multiplayer != ""`, tidak di adegan LocalPlay.tscn, tidak kalau di latar < 30 dtk, tidak sebelum
    match pertama tuntas, tidak dalam 3 menit setelah interstisial, kedaluwarsa 4 jam; g) PAUSED+RESUMED
    karena iklan kita sendiri tidak memicu app open.
T6. Foto (headless, 1280x720 dan 854x480): SELECT STAGE (Quick & Classic), lobby host & client (baris
    MATCH), HOW TO WIN Quick dengan tombol FREE CARD, label ronde biasa & FINAL ROUND + spanduk, panel IN
    DEBT!, papan peringkat Quick 4 pemain. Periksa tidak ada yang terpotong/tumpang tindih.

Syarat lolos: semua log SELESAI normal (bukan MACET / LOBBY_MACET / START_TIDAK_MUNCUL), scripterr=0,
beda=0, cek_gagal=0, kartu_beda=0; T1 jejak identik; T3/T4 baris AKHIR sama persis di semua HP satu
permainan dan ronde akhir = batas untuk alasan ronde; T5 semua skenario benar; T6 rapi.

## 5. Pengiriman
Set lengkap 14 file dalam SATU pesan (minta unduhan lama dibuang): pemain.gd, ai_musuh.gd, petak_kartu.gd,
ui_elemen.gd, ui_dinamis.gd, ui_petak.gd, main_menu.gd, layar_local_play.gd, status_jaringan.gd,
data_pemain.gd, jebakan_air.gd, jebakan_api.gd, migrasi_host.gd, pengelola_iklan.gd.
Yang berubah: pemain.gd, ui_dinamis.gd, main_menu.gd, layar_local_play.gd, status_jaringan.gd,
pengelola_iklan.gd. Ingatkan user: `ID_INTERSTISIAL_ASLI` masih kosong (ID uji) -- wajib diisi sebelum rilis
ke Play Store; build debug untuk uji A7; catat angka AdMob sebelum rilis.

## 6. Di luar Fase 1
- Putar ulang rolet setelah kalah duel (solo) -> Fase 5. Double XP/Crowns di akhir match -> Fase 2.
- Event papan tiap 2 ronde di Quick (tiap 3 di Classic) -> Fase 5. XP Quick 1,0 / Classic 1,6 -> Fase 2.
- AI belum menyesuaikan diri dengan batas ronde (membeli tidak mengubah kekayaan, jadi tidak merugikan).
- Iklan hanya bisa diuji sungguhan di HP (rig memakai stub; T5 memakai plugin tiruan).

Model: rencana ini (Opus) -> kode & uji Sonnet. Pindah ke Opus kalau ada bug membingungkan (mis. ronde atau
pemenang berbeda antar-HP, atau T1 tidak identik tanpa sebab jelas).

## STATUS (24-09, dikerjakan Opus atas permintaan user)
Semua bagian A & B selesai sesuai rencana. Tambahan yang ditemukan saat uji:
1. Kartu hadiah FREE CARD memakai pengacak sendiri: `lingkungan_pantai.gd` mengunci benih acak GLOBAL dengan
   angka tetap (`seed("PantaiMalam".hash())`), jadi dengan `randi()` global kartu di Night Beach selalu sama.
2. Panel IN DEBT!: ketukan pertama mengunci kedua tombol (ketuk dua kali tidak dihitung lagi).
3. Label ronde mengikuti posisi TeksDadu setiap frame (`_atur_posisi_label_ronde`): di layar 1600x720 (HP user)
   TeksDadu tidak di tengah layar, jadi label yang di-anchor ke tengah tampak bergeser.
Hasil uji:
- T1 Classic identik: 36/36 jejak sim sama persis (saklar UJI nyala) + 36/36 (UJI mati), diulang setelah
  perbaikan terakhir -- tetap 36/36.
- T3a Quick sim (UJI mati, 2-4 pemain x 6 benih x uang 1000/2500): 36/36 cek pemenang OK, akhir karena ronde
  tepat batas x pemain giliran. T3b seri: 6/6. T3c adegan asli: 12 run Quick/Classic x lawan 1-3 x 2 peta +
  6 run iklan (FREE CARD, +300 COINS sekali per match, ketuk dua kali tombol peta -> tetap 1 panel HOW TO WIN).
- T4 Quick multiplayer Q1-Q8 + Q1n/Q4n (UJI mati): semua SELESAI normal, scripterr 0, beda 0, cek_gagal 0,
  baris AKHIR identik di semua HP. Q8: hotspot P1 mati di giliran terakhir -> ronde baru ditutup setelah
  WAIT FOR PLAYERS + START NOW, semua HP melihat layar akhir yang sama. (Dijalankan di network namespace
  terpisah -- unshare -rn + loopback -- supaya bisa paralel dengan T2.)
- T5 logika iklan dengan plugin tiruan (proj_iklan): 30/30.
- T6 foto 1280x720 & 1600x720: menu SELECT STAGE, lobby host/client, HOW TO WIN + FREE CARD, label ronde,
  spanduk FINAL ROUND, IN DEBT!, papan peringkat Quick 2 & 4 pemain -- rapi.
- T2 regresi multiplayer Classic (27 skenario: M1-M8, A0-A6, S1-S3, D1-D4, B0-B4; 68 log device): semua
  SELESAI normal, 0 MACET, scripterr 0, beda 0, cek_gagal 0, kartu_beda 0.
Perbaikan 24-09 malam (laporan uji user di laptop/editor):
1. Peringatan STATIC_CALLED_ON_INSTANCE (main_menu.gd & layar_local_play.gd): `baca_pilihan_quick` /
   `simpan_pilihan_quick` di status_jaringan.gd bukan `static` lagi. Rig dulu tidak menampilkan peringatan
   (hanya tercetak kalau debugger aktif); sekarang ada cek_peringatan.sh (--debug): 0 peringatan di file produksi.
2. Error "previously freed" di `_tonton_iklan_kartu_awal`: plugin AdMob 5.1 ke bawah menggambar iklan TIRUAN
   editor di CanvasLayer 100, di bawah panel HOW TO WIN (106) -> iklan tidak terlihat, pemain menekan START,
   panel dibuang, lalu hasil iklan ditulis ke panel itu. Perbaikan: panel turun ke layer 99 selama iklan; panel
   dicek dulu; kalau START sudah ditekan, kartu tetap diberikan + spanduk "FREE CARD: ...".
   Uji: tiruan Editor Mock Ads + klik sungguhan di layar maya 1280x720. Kode lama mereproduksi error yang
   persis sama; kode baru 8/8 skenario (iklan di layer 100 & 1000: START saat iklan, START sebelum iklan
   muncul, iklan gagal tampil, iklan ditutup sebelum hadiah) tanpa error.
Batasan: iklan sungguhan hanya bisa diuji di HP (build debug, iklan uji Google); `ID_INTERSTISIAL_ASLI` masih
kosong (keputusan user) -- wajib diisi sebelum rilis ke Play Store.
