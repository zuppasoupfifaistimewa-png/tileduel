extends "res://uji_sim.gd"
# PERMAINAN SOLO LEWAT ADEGAN ASLI (salinan panggung_utama.tscn + PetaAlam/PetaPantai).
# Robot menekan tombol menu asli: SINGLE PLAYER -> "N AI ENEMIES" -> peta,
# lalu START GAME di panel HOW TO WIN, lalu memainkan slot 0 lewat tombol UI.
#   argumen: lawan=3 peta=alam seed=7 giliran=60 jejak=/path.txt foto=res://x
var n_lawan = 1
var nama_peta = "alam"
var awalan_foto = ""
var foto_diambil = 0
var tahap = "menu"
var _sig_duel = ""
var _uji_duel_ai = false
var _escala_diag = 4.0 # DIAGNOSTIK SAJA -- naikkan lewat argumen escala= untuk uji cepat
# --- Fase 1 ---
var panjang_uji = "classic"   # panjang=quick|classic -> tombol QUICK MATCH / CLASSIC di menu
var iklan_uji = false         # iklan=1 -> stub iklan berhadiah "tersedia"; robot menonton FREE CARD & +300
var klik_iklan_hutang = 0
var uang0_uji = -1 # uang0=N -> uang slot 0 diset N setelah START (memancing hutang)
var _spanduk_dicatat = false
var _teks_ronde_terakhir = ""
var _foto_akhir = false
var _foto_hutang = false
# --- Fase 2 (T4): profil=1 -> periksa hadiah profil di layar akhir, DOUBLE, EXIT ---
var cek_profil = false
var _profil_dicek = false
var xp0 = -1
var cr0 = -1
# --- Fase 4 U3 (keseimbangan): semua_ai=1 -> slot 0 juga AI; role=api,air,.. per
# slot (dipasang langsung ke DataPemain sesudah START, tidak diundi); jenis=N jumlah
# jenis jebakan dibawa tiap slot (bawaan 3 = SLOT_JEBAKAN_MP).
var semua_ai = false
var role_uji: Array = []
var jenis_uji = DataRole.SLOT_JEBAKAN_MP
# ALAT UJI SEMENTARA (bagian dari #121/U8, bukan file produksi): maks_node=1 ->
# semua node role dipaksa Lv3 + Ultimate dibeli, supaya Guard/Rock Breaker/
# fortress/sacred_ground/dll BENAR-BENAR teruji rig (bukan cuma Lv0 fallback).
var maks_node_uji = false
var maks_lv_uji = 3 # U8/#121: maks_lv=1|2|3 -> level dipaksakan _build_maks (bawaan 3)
# D0 (B-d, rig pembanding, bukan file produksi): preset=balanced|attack|defense (+sp=N,
# bawaan 12) -> build_dari_preset, dipakai di role_uji supaya build AI = Balanced/dll
# sungguhan (Ultimate + node level nyata), bukan cuma _build_lv1/_build_maks.
# F0 (B-f, 14.19): preset= sekarang terima DAFTAR per slot (preset=attack,balanced
# -> slot 0 attack, slot 1 balanced, dst, diulang lewat modulo kalau slot > daftar);
# SATU nilai (tanpa koma) = semua slot, PERSIS perilaku lama.
var preset_uji: Array = []
var sp_uji: int = 12
# F0 (B-f, 14.19, U9 S3/S4): lv_semua=N -> SEMUA slot Balanced penuh Level Role N
# (cermin uji solo K1), mengalahkan preset_uji/maks_node_uji/build_solo slot 0.
var lv_semua_uji: int = -1
# F0 (B-f, 14.19): dicetak di baris SEIMBANG (presets=..); "-" = slot tidak lewat
# preset_uji/lv_semua (pakai build_solo/_build_maks/balanced-cermin-level biasa).
var _presets_dipakai: Array = []
# F0 (B-f, 14.19): XP Role slot 0 SEBELUM pertandingan (HOME baru tiap run, jadi
# awalnya selalu apa adanya dari argumen level_role= kalau ada) -- dipakai hitung
# selisih xprole0 di baris SEIMBANG.
var _xprole0_awal: int = 0
var _jejak_jebakan_ai: Dictionary = {} # D0: "petak|nama" -> true, sudah pernah dicetak
const _ELEMEN_DARI_NODE_UJI := {"JebakanApi": "api", "JebakanAir": "air", "JebakanAngin": "angin", "JebakanPetir": "petir", "JebakanTanah": "tanah"}
# D6 (B-d, rig-only, TIDAK ikut ZIP): cek_nilai=1 -> jalankan kasus tabel D7
# langsung ke fungsi murni AiJebakan/AiMusuh (bukan main loop), cetak OK/GAGAL,
# lalu keluar. Angka target CEK_FAKTOR_* SAMA PERSIS 3 contoh hitungan K19
# (14.16) -- independen, bukan dihitung ulang dari kode yang sedang diuji.
# CEK_NILAI_* (Guard/potongan_tahan) memverifikasi RUMUS HARFIAH K17(a) yang
# juga independen dari implementasi (Guard->0 & 0/25/50/50% tertulis persis).
var cek_nilai_uji: bool = false
# E0 (B-e, rig-only, TIDAK ikut ZIP): level_role=N -> tulis ProfilPemain.xp_role
# [role_uji[0]] = total XP Level N SEBELUM menu (HOME rig baru tiap run, jadi
# profil selalu kosong di awal) + mode_build=balanced|attack|defense|custom:<json>
# -> tulis ProfilPemain.build_solo[role_uji[0]]. Dipakai BERSAMA role= (perlu
# tahu role slot 0 lebih dulu) -- lihat rencana 14.18 P8/E0.
var level_role_uji: int = -1
var mode_build_uji: String = ""

func _pasang_tanah_cek(petak: int, pemilik: int, build_pemilik: Dictionary) -> Node:
	# D6 (B-d, rig-only): pasang JebakanTanah SUNGGUHAN (pola sama _pasang_jebakan,
	# pemain_papan.gd) untuk kasus cek_nilai -- hapus dulu kalau sudah ada.
	var lama = p.rute_papan[petak].get_node_or_null("JebakanTanah")
	if lama != null:
		p.rute_papan[petak].remove_child(lama)
		lama.queue_free()
	p.pemilik_petak[petak] = pemilik
	p.daftar_pemain[pemilik].build = build_pemilik
	p.daftar_pemain[pemilik].guard_terpakai = {}
	var jebakan = load("res://jebakan_tanah.gd").new()
	jebakan.name = "JebakanTanah"
	jebakan.pemilik = pemilik
	jebakan.sisa_duel = int(p._angka_jebakan(pemilik, "tanah")["sisa_duel"])
	jebakan.sisa_tahan_serangan = int(p._angka_jebakan(pemilik, "tanah")["tahan_serangan"])
	p.rute_papan[petak].add_child(jebakan)
	return jebakan

func _cek1(nama: String, hasil: float, harapan: float, toleransi: float = 0.005) -> bool:
	var ok = absf(hasil - harapan) <= toleransi
	print("CEK_NILAI %s hasil=%.4f harapan=%.4f status=%s" % [nama, hasil, harapan, "OK" if ok else "GAGAL"])
	return ok

func _jalankan_cek_nilai() -> void:
	# D6 (B-d, rig-only, TIDAK ikut ZIP): lihat komentar var cek_nilai_uji.
	if p.jumlah_pemain() < 2:
		print("CEK_NILAI_SELESAI total=0 ok=0 gagal=0 catatan=butuh_min_2_pemain")
		return
	var total = 0
	var ok_n = 0
	var petak_uji = 5
	p.daftar_pemain[0].role = "tanah" # penyerang (rock_breaker dibaca dari build, bukan role)
	p.daftar_pemain[1].role = "api" # pemilik petak -- BUKAN "tanah" utk kasus 1&2 (K19 dasar)

	# K19(a), contoh 1: "Dasar (+1 HP, tanpa Rock Breaker)" -> faktor 0,5.
	_pasang_tanah_cek(petak_uji, 1, {})
	p.daftar_pemain[0].build = {}
	total += 1; ok_n += 1 if _cek1("faktor_fight_tanah_dasar", AiMusuh._faktor_fight_tanah(p, 0, petak_uji), 0.5) else 0

	# K19(a), contoh 2: "Rock Breaker Lv1" (penyerang) -> faktor ~0,71 (0,7071).
	_pasang_tanah_cek(petak_uji, 1, {})
	p.daftar_pemain[0].build = {"rock_breaker": 1}
	total += 1; ok_n += 1 if _cek1("faktor_fight_tanah_rb_lv1", AiMusuh._faktor_fight_tanah(p, 0, petak_uji), sqrt(0.5)) else 0

	# K19(a), contoh 3: "hard_rock Lv3 + stone_thorns Lv3" (pemilik petak,
	# role HARUS "tanah" -- syarat _stone_thorns_p_di/K2), penyerang tanpa
	# Rock Breaker -> faktor 0,10.
	p.daftar_pemain[1].role = "tanah"
	_pasang_tanah_cek(petak_uji, 1, {"hard_rock": 3, "stone_thorns": 3})
	p.daftar_pemain[0].build = {}
	total += 1; ok_n += 1 if _cek1("faktor_fight_tanah_hardrock3_stonethorns3", AiMusuh._faktor_fight_tanah(p, 0, petak_uji), 0.10) else 0
	var jebakan_c3 = p.rute_papan[petak_uji].get_node_or_null("JebakanTanah")
	if jebakan_c3 != null:
		p.rute_papan[petak_uji].remove_child(jebakan_c3)
		jebakan_c3.queue_free()

	# K17(a) harfiah: "Guard belum terpakai -> nilai korban 0 (kebal)" -- SAMA
	# untuk semua elemen. Korban slot 1, heat_skin Lv3 (Guard api), belum
	# terpakai (guard_terpakai dikosongkan _pasang_tanah_cek di atas -- panggil
	# lagi di sini langsung tanpa jebakan tanah, cukup build+guard_terpakai).
	p.daftar_pemain[1].build = {"heat_skin": 3}
	p.daftar_pemain[1].guard_terpakai = {}
	p.daftar_pemain[0].build = {} # angka pemasang DASAR (Lv0) utk 2 kasus K17(a) di bawah
	var angka_api_dasar = p._angka_jebakan(0, "api")
	total += 1; ok_n += 1 if _cek1("nilai_korban_guard_kebal_api", AiJebakan._nilai_korban(p, 0, 1, "api", petak_uji, angka_api_dasar), 0.0) else 0

	# K17(a) harfiah: "api/angin -> x(1 - potongan_tahan), 0/25/50/50%" -- Lv1
	# = -25%, dibaca DataRole.potongan_tahan (TAHAN_LV1_POTONGAN). Nilai dasar
	# api = DASAR.bakar_per_giliran x DASAR.bakar_giliran (60x3=180 di kode
	# 26-09) x 0,75 = 135.
	p.daftar_pemain[1].build = {"heat_skin": 1}
	p.daftar_pemain[1].guard_terpakai = {}
	var nilai_dasar_api = float(DataRole.DASAR["bakar_per_giliran"] * DataRole.DASAR["bakar_giliran"])
	total += 1; ok_n += 1 if _cek1("nilai_korban_api_potongan_lv1", AiJebakan._nilai_korban(p, 0, 1, "api", petak_uji, angka_api_dasar), nilai_dasar_api * 0.75) else 0

	# F1 (B-f, 14.19/P13, T16): 3 kasus BARU -- AI membaca build SUNGGUHAN
	# pemasangnya (bukan DASAR lagi). Angka target dihitung TANGAN (independen
	# dari kode yang diuji, sama pola K17/K19 di atas), lihat 14.19/14.20.
	# Kasus 1: hot_flames Lv3 (90 koin/giliran, tabel NODE_LV data_role.gd) +
	# long_burn Lv2 (4 giliran) vs korban heat_skin Lv1 (potongan 25%) ->
	# 90 x 4 x 0,75 x (1+0 fire_tax) = 270.
	p.daftar_pemain[0].role = "api"
	p.daftar_pemain[0].build = {"hot_flames": 3, "long_burn": 2}
	p.daftar_pemain[1].build = {"heat_skin": 1}
	p.daftar_pemain[1].guard_terpakai = {}
	var angka_api_p13 = p._angka_jebakan(0, "api")
	total += 1; ok_n += 1 if _cek1("nilai_korban_api_hotflames3_longburn2_vs_heatskin1", AiJebakan._nilai_korban(p, 0, 1, "api", petak_uji, angka_api_p13), 270.0) else 0

	# Kasus 2: angin homing_wind Lv2 (bagian_homing 0,5) + strong_wind Lv0 (pakai
	# DASAR rampas_angin 0,10) vs korban tanpa ketahanan angin, uang=1000 ->
	# 0,10 x 1000 x (1-0) x (1+0,5) = 150 (langkah_hilang=0 -> suku ke-2 nol).
	p.daftar_pemain[0].role = "angin"
	p.daftar_pemain[0].build = {"homing_wind": 2}
	p.daftar_pemain[1].build = {}
	p.daftar_pemain[1].guard_terpakai = {}
	p.daftar_pemain[1].uang = 1000
	var angka_angin_p13 = p._angka_jebakan(0, "angin")
	total += 1; ok_n += 1 if _cek1("nilai_korban_angin_homingwind2_uang1000", AiJebakan._nilai_korban(p, 0, 1, "angin", petak_uji, angka_angin_p13), 150.0) else 0

	# Kasus 3: Phoenix x1,5 -- hot_flames Lv1 (70 koin/giliran) + long_burn Lv0
	# (DASAR 3 giliran) + Ultimate api (ULT_api=true, role HARUS "api" ->
	# _punya_ultimate), korban tanpa heat_skin -> 70 x 3 x 1 x 1 = 210,
	# x FAKTOR_ULANG_ULTIMATE (1,5) = 315.
	p.daftar_pemain[0].role = "api"
	p.daftar_pemain[0].build = {"hot_flames": 1, "ULT_api": true}
	p.daftar_pemain[1].build = {}
	p.daftar_pemain[1].guard_terpakai = {}
	var angka_api_phoenix = p._angka_jebakan(0, "api")
	total += 1; ok_n += 1 if _cek1("nilai_korban_api_phoenix_x1_5", AiJebakan._nilai_korban(p, 0, 1, "api", petak_uji, angka_api_phoenix), 315.0) else 0

	print("CEK_NILAI_SELESAI total=%d ok=%d gagal=%d" % [total, ok_n, total - ok_n])

func _build_maks(role: String) -> Dictionary:
	# ALAT UJI SEMENTARA (maks_node=1[+maks_lv=1|2|3], bagian dari #121/U8): semua
	# node role ini di level itu + Ultimate dibeli -- supaya Guard/Rock Breaker/
	# fortress/sacred_ground/hard_rock/dll BENAR-BENAR teruji rig PER LEVEL (bukan
	# cuma Lv0 fallback atau selalu Lv3 -- level 1/2 punya perilaku BEDA JENIS,
	# bukan cuma beda besar, terutama Grounded & Rock Breaker, lihat data_role.gd).
	var lv = clampi(maks_lv_uji, 1, 3)
	var b = {}
	for id_node in DataRole.NODE_JEBAKAN_ID.get(role, []):
		b[id_node] = lv
	for id_node in DataRole.TAHAN_ROLE.get(role, []):
		b[id_node] = lv
	if DataRole.NODE_ULTIMATE_ID.has(role):
		b["ULT_" + role] = true
	return b

func _ready():
	for a in OS.get_cmdline_user_args():
		if a.begins_with("lawan="): n_lawan = int(a.substr(6))
		if a.begins_with("peta="): nama_peta = a.substr(5)
		if a.begins_with("seed="): benih = int(a.substr(5))
		if a.begins_with("giliran="): batas_giliran = int(a.substr(8))
		if a.begins_with("jejak="): berkas_jejak = a.substr(6)
		if a.begins_with("foto="): awalan_foto = a.substr(5)
		if a.begins_with("escala="): _escala_diag = float(a.substr(7))
		if a == "duel_ai=1": _uji_duel_ai = true
		if a.begins_with("panjang="): panjang_uji = a.substr(8)
		if a == "iklan=1": iklan_uji = true
		if a.begins_with("uang0="): uang0_uji = int(a.substr(6))
		if a == "profil=1": cek_profil = true
		if a == "semua_ai=1": semua_ai = true
		if a.begins_with("role="): role_uji = Array(a.substr(5).split(","))
		if a.begins_with("jenis="): jenis_uji = int(a.substr(6))
		if a == "maks_node=1": maks_node_uji = true
		if a.begins_with("maks_lv="): maks_lv_uji = int(a.substr(8))
		if a.begins_with("preset="): preset_uji = Array(a.substr(7).split(",")) # D0 (B-d)/F0 (B-f): daftar per slot
		if a.begins_with("sp="): sp_uji = int(a.substr(3)) # D0 (B-d)
		if a.begins_with("lv_semua="): lv_semua_uji = int(a.substr(9)) # F0 (B-f, U9 S3/S4)
		if a == "cek_nilai=1": cek_nilai_uji = true # D6 (B-d)
		if a.begins_with("level_role="): level_role_uji = int(a.substr(11)) # E0 (B-e)
		if a.begins_with("mode_build="): mode_build_uji = a.substr(11) # E0 (B-e)
	if level_role_uji >= 1 and not role_uji.is_empty():
		# E0 (B-e): role_uji sudah lengkap dari argumen di atas -- tulis profil
		# SEBELUM menu supaya _siapkan_role_solo (kalau ikut dipanggil) & rumus
		# BUILD_SLOT di bawah membaca Level Role yang sama.
		var role0_e0 = str(role_uji[0])
		var total_xp_e0 := 0
		for l in range(1, level_role_uji):
			total_xp_e0 += DataRole.xp_untuk_naik_role(l)
		ProfilPemain.xp_role[role0_e0] = total_xp_e0
		if mode_build_uji != "":
			var preset_e0 = mode_build_uji
			var node_e0 = {}
			if mode_build_uji.begins_with("custom:"):
				preset_e0 = "custom"
				var lewat_e0 = JSON.parse_string(mode_build_uji.substr(7))
				node_e0 = lewat_e0 if lewat_e0 is Dictionary else {}
			ProfilPemain.build_solo[role0_e0] = {"preset": preset_e0, "node": node_e0}
	n_manusia = 1
	n_pemain = 1 + n_lawan
	Engine.time_scale = _escala_diag if awalan_foto == "" else 2.0
	StatusJaringan.peran_multiplayer = ""
	seed(benih)
	var adegan = load("res://uji_panggung.tscn").instantiate()
	add_child(adegan)
	p = adegan.get_node("Pemain")
	ui = p.ui_elemen
	for i in 10: await get_tree().process_frame
	var menu = null
	for anak in p.get_children():
		if anak.get_script() == preload("res://main_menu.gd"):
			menu = anak
	if menu == null:
		print("GAGAL: main menu tidak ditemukan"); get_tree().quit(); return
	_klik_teks("SINGLE PLAYER")
	await get_tree().process_frame
	var teks_lawan = "1 AI ENEMY" if n_lawan == 1 else "%d AI ENEMIES" % n_lawan
	if not _klik_teks(teks_lawan):
		print("GAGAL: tombol '%s' tidak ada" % teks_lawan); get_tree().quit(); return
	await get_tree().process_frame
	print("MENU ok: jumlah_ai_dipilih=", menu.jumlah_ai_dipilih)
	# Fase 1: sakelar QUICK MATCH / CLASSIC, lalu tombol peta ASLI (tanpa iklan wajib).
	var nama_panjang = "QUICK MATCH" if panjang_uji == "quick" else "CLASSIC"
	print("MENU panjang '%s' = %s; keterangan='%s'" % [nama_panjang, str(_klik_teks(nama_panjang)), menu.label_ket_mode.text])
	if iklan_uji:
		PengelolaIklan.uji_rewarded = true
	mode_quick_uji = (panjang_uji == "quick")
	if awalan_foto != "":
		for i in 10: await get_tree().process_frame
		await _foto("menu")
	var nama_tombol_peta = "Grassland" if nama_peta == "alam" else "Night Beach"
	# Ketuk DUA KALI: permainan harus dimulai sekali saja.
	var klik1 = _klik_teks(nama_tombol_peta)
	var klik2 = _klik_teks(nama_tombol_peta)
	print("MENU peta '%s' klik1=%s klik2=%s" % [nama_tombol_peta, str(klik1), str(klik2)])
	# Fase 4 (A6/K6): SELECT STAGE sekarang membuka layar "CHOOSE YOUR ROLE"
	# (main_menu.gd _proses_tombol_peta -> _buka_layar_role) SEBELUM game
	# betulan mulai -- robot harus memilih role & menekan START di sana dulu,
	# kalau tidak "HOW TO WIN" tidak akan pernah muncul (macet 60 dtk lalu GAGAL).
	await get_tree().process_frame
	var nama_role_uji = "FIRE"
	print("MENU role klik %s = %s" % [nama_role_uji, str(_klik_teks(nama_role_uji))])
	await get_tree().process_frame
	print("MENU role START = %s" % str(_klik_teks("START")))
	await get_tree().process_frame
	tahap = "tunggu_start"
	var t = 0.0
	while _cari_label("HOW TO WIN").is_empty() and t < 60.0:
		await get_tree().process_frame
		t += get_process_delta_time()
	for i in 20: await get_tree().process_frame
	var panel_how = _cari_label("HOW TO WIN").size()
	print("PANEL_HOW_TO_WIN jumlah=%d%s" % [panel_how, "" if panel_how == 1 else "  GAGAL: harus 1"])
	var baris_syarat = []
	for l in find_children("*", "Label", true, false):
		if l.text.begins_with("•  ") and l.is_visible_in_tree():
			baris_syarat.append(l.text.substr(3))
	print("SYARAT | " + " | ".join(baris_syarat))
	print("ATURAN mode_quick=%s batas_ronde=%d target_permata=%d permata_peta=%d rolet_double=%s" % [str(p.mode_quick), p.batas_ronde, p.target_permata_menang, p.jumlah_permata_peta, str(p.mode_rolet_double)])
	if awalan_foto != "":
		await _foto("syarat")
	if iklan_uji:
		var kartu_sebelum = p.daftar_pemain[p.slot_lokal].inventaris_kartu.size()
		var klik_iklan = _klik_teks("WATCH AD: FREE CARD")
		for i in 30: await get_tree().process_frame
		var inv = p.daftar_pemain[p.slot_lokal].inventaris_kartu
		var id_baru = str(inv[inv.size() - 1].get("id", "?")) if inv.size() > kartu_sebelum else "-"
		var status_teks = ""
		for l in find_children("*", "Label", true, false):
			if l.text.begins_with("You got") or l.text.begins_with("No ad"):
				status_teks = l.text
		var cek = "OK" if klik_iklan and inv.size() == kartu_sebelum + 1 and p.KARTU_HADIAH_IKLAN.has(id_baru) and status_teks.begins_with("You got") else "GAGAL"
		print("IKLAN_KARTU klik=%s kartu=%d->%d id=%s teks='%s' cek=%s" % [str(klik_iklan), kartu_sebelum, inv.size(), id_baru, status_teks, cek])
	if semua_ai:
		# U3: slot 0 dimainkan otak AI yang sama dengan slot lain (robot tombol mati).
		n_manusia = 0
		p.daftar_pemain[0].jenis_kontrol = DataPemain.JenisKontrol.AI
	t = 0.0
	while not _klik_teks("START GAME") and t < 60.0:
		await get_tree().process_frame
		t += get_process_delta_time()
	print("START ditekan setelah %.1f dtk; pemain=%d target_permata=%d petak=%d" % [t, p.jumlah_pemain(), p.target_permata_menang, p.rute_papan.size()])
	xp0 = ProfilPemain.xp_total
	cr0 = ProfilPemain.crowns
	if uang0_uji >= 0:
		p.daftar_pemain[0].uang = uang0_uji
		p.update_ui_status()
	seed(benih * 7919 + 13)
	p.mesin_acak.seed = benih * 31 + 1
	ui.rng.seed = benih * 17 + 3
	ui.rng_visual.seed = 5
	var lv_e0 := -1 # E0 (B-e, rig-only): Level Role slot 0 dipakai BUILD_SLOT di bawah
	if not role_uji.is_empty():
		# U3: role per kursi dari argumen (bukan undian mesin_acak/profil).
		for s in range(p.jumlah_pemain()):
			p.daftar_pemain[s].role = str(role_uji[s % role_uji.size()])
		lv_e0 = lv_semua_uji if lv_semua_uji >= 0 else int(DataRole.info_level_role(int(ProfilPemain.xp_role.get(str(p.daftar_pemain[0].role), 0)))["level"])
		_xprole0_awal = int(ProfilPemain.xp_role.get(str(p.daftar_pemain[0].role), 0))
		# F0 (B-f, 14.19): urutan DIBALIK seperti produksi (D1/P5, data_role.gd) --
		# build SEMUA slot DULU, baru jebakan_bawaan_ai baca build_lawan SUNGGUHAN
		# (bukan tebakan Lv1). Sebelumnya jebakan slot s dihitung SEBELUM slot > s
		# punya build, jadi build_lawan slot itu selalu kosong.
		for s in range(p.jumlah_pemain()):
			var r = p.daftar_pemain[s].role
			var preset_s = ""
			if lv_semua_uji >= 0:
				# F0 (U9 S3/S4): cermin solo -- SEMUA slot Balanced penuh level sama.
				p.daftar_pemain[s].build = DataRole.build_dari_preset(r, "balanced", DataRole.sp_dari_level(lv_semua_uji), lv_semua_uji)
				preset_s = "balanced"
			elif not preset_uji.is_empty(): # D0 (B-d)/F0: build preset sungguhan per slot
				preset_s = str(preset_uji[s % preset_uji.size()])
				p.daftar_pemain[s].build = DataRole.build_dari_preset(r, preset_s, sp_uji, DataRole.LEVEL_ROLE_MAKS)
			elif maks_node_uji:
				p.daftar_pemain[s].build = _build_maks(r)
			elif s == 0:
				# E0 (B-e/P8, rig ikut rumus produksi persis): slot 0 = build solo
				# pemain (build_solo, bukan _build_lv1 -- dihapus B-e).
				p.daftar_pemain[s].build = DataRole.build_solo(r, ProfilPemain.build_solo.get(r, {}), lv_e0)
			else:
				# E0 (B-e/P8/K1): slot AI = Balanced PENUH sesuai Level Role
				# PEMAIN (lv_e0, slot 0), role AI SENDIRI -- bukan diundi.
				p.daftar_pemain[s].build = DataRole.build_dari_preset(r, "balanced", DataRole.sp_dari_level(lv_e0), lv_e0)
			_presets_dipakai.append(preset_s if preset_s != "" else "-")
			print("DEBUG_BUILD s=%d role=%s preset=%s maks=%s build=%s" % [s, r, preset_s, maks_node_uji, str(p.daftar_pemain[s].build)])
		for s in range(p.jumlah_pemain()):
			var lawan = []
			var build_lawan = []
			for u in range(p.jumlah_pemain()):
				if u != s:
					lawan.append(p.daftar_pemain[u].role)
					build_lawan.append(p.daftar_pemain[u].build)
			p.daftar_pemain[s].jebakan_dibawa = DataRole.jebakan_bawaan_ai(p.daftar_pemain[s].role, lawan, jenis_uji, build_lawan)
		p.update_ui_status()
	var ringkas_role = []
	for d in p.daftar_pemain:
		ringkas_role.append("%s:%s" % [d.role, "+".join(d.jebakan_dibawa)])
	print("ROLE_SLOT ", " ".join(ringkas_role))
	if lv_e0 >= 0: # E0 (B-e, rig-only): dicetak SESUDAH ROLE_SLOT, per rencana 14.18
		for s in range(p.jumlah_pemain()):
			print("BUILD_SLOT s=%d role=%s lv=%d build=%s" % [s, p.daftar_pemain[s].role, lv_e0, str(p.daftar_pemain[s].build)])
	if cek_nilai_uji:
		_jalankan_cek_nilai()
		get_tree().quit()
		return
	jejak.append("MULAI-NYATA pemain=%d seed=%d peta=%s" % [p.jumlah_pemain(), benih, nama_peta])
	for s in range(p.jumlah_pemain()):
		var node = p._node_karakter(s)
		jejak.append("KARAKTER|%d|%s|pos=%s|warna=%s" % [s, node.name, str(p._model(s).global_position.snapped(Vector3(0.01, 0.01, 0.01))), _warna_badan(p._model(s))])
	if _uji_duel_ai:
		# DIAGNOSTIK: langsung jalankan duel AI (P3) vs AI (P4) lalu keluar.
		var selesai_duel = [false]
		var dtk = [0.0]
		var catat = func():
			while not selesai_duel[0]:
				var sig = "DUEL tampil=%d fase=%s segelM=%d segelP=%d tonton=%d judul='%s'" % [int(ui.visible), ui.fase_duel, int(ui.musuh_siap), int(ui.pemain_siap), int(ui.mode_tonton), ui.teks_judul.text.replace("\n", " / ")]
				if sig != _sig_duel:
					_sig_duel = sig
					print("D|%.2f|%s" % [dtk[0], sig])
				await get_tree().process_frame
				dtk[0] += get_process_delta_time()
		catat.call()
		var hasil = await p._jalankan_duel(2, 3, 1, 0)
		selesai_duel[0] = true
		print("DUEL_AI_SELESAI ", hasil)
		get_tree().quit()
		return
	if semua_ai:
		# Giliran PERTAMA selalu dibuka lewat jalur manusia (_mulai_transisi_game ->
		# periksa_status_petak slot 0). Rig: tunggu menu itu muncul, tutup, lalu
		# serahkan ke otak AI -- giliran berikutnya ganti_giliran sudah memakai _is_ai.
		var tw = 0.0
		while not (p.get("_giliran_berjalan") and p.menu_aksi.visible) and tw < 30.0:
			await get_tree().process_frame
			tw += get_process_delta_time()
		p.menu_aksi.hide()
		AiMusuh.logika_ai_fase_awal(p, 0)
	tahap = "main"
	mulai = true
	if awalan_foto != "":
		for i in 30: await get_tree().process_frame
		await _foto("awal")

func _tulis_dan_keluar(alasan: String) -> void:
	# U3: satu baris ringkas per pertandingan untuk f4/ringkas_seimbang.py.
	# Pertandingan yang berhenti di batas giliran rig (Classic) -> pemenang = terkaya
	# (_pemenang_kekayaan, aturan yang sama dengan akhir ronde Quick).
	if not selesai and p != null and mulai:
		var pm = -1
		var cara = alasan
		if p.get("_permainan_selesai"):
			pm = p._slot_pemenang_akhir
			cara = str(p._alasan_akhir)
		elif alasan == "BATAS_GILIRAN":
			pm = int(p._pemenang_kekayaan()["slot"])
			cara = "batas_kaya"
		var roles = []
		var pasang = []
		var kena = []
		var kaya = []
		var rinci = []
		for s in range(p.jumlah_pemain()):
			var st2 = p.statistik_slot[s] if s < p.statistik_slot.size() else {}
			rinci.append("%d/%d/%d/%d/%d/%d" % [int(st2.get("jebakan_role_pasang", 0)), int(st2.get("koin_jebakan", 0)), int(st2.get("duel_menang", 0)), int(st2.get("duel_kalah", 0)), int(st2.get("tahan_kurangi", 0)), int(st2.get("petak_beli", 0))])
		for s in range(p.jumlah_pemain()):
			roles.append(p.daftar_pemain[s].role)
			var st = p.statistik_slot[s] if s < p.statistik_slot.size() else {}
			pasang.append(str(int(st.get("jebakan_pasang", 0))))
			kena.append(str(int(st.get("jebakan_kena", 0))))
			kaya.append(str(p._kekayaan_slot(s)))
		# F0 (B-f, 14.19): presets= dari _presets_dipakai ("-" kalau slot itu tidak
		# lewat preset_uji/lv_semua); sacred= jumlah JebakanTanah sacred di papan
		# saat berhenti (U9 P14); xprole0= selisih XP Role slot 0 pertandingan INI,
		# -1 kalau tidak tersedia (match berhenti BATAS_GILIRAN, catat_akhir_match
		# belum sempat jalan -> ProfilPemain.xp_role tidak berubah).
		var presets_teks = ",".join(_presets_dipakai) if not _presets_dipakai.is_empty() else "-"
		var xprole0 = -1
		if p.get("_permainan_selesai") and not role_uji.is_empty():
			xprole0 = int(ProfilPemain.xp_role.get(str(role_uji[0]), 0)) - _xprole0_awal
		print("SEIMBANG peta=%s seed=%d quick=%d roles=%s pemenang=%d cara=%s giliran=%d detik=%.1f pasang=%s kena=%s kaya=%s rinci=%s presets=%s sacred=%d xprole0=%d" % [nama_peta, benih, int(p.mode_quick), ",".join(roles), pm, cara, jumlah_giliran, detik_total, ",".join(pasang), ",".join(kena), ",".join(kaya), ",".join(rinci), presets_teks, _hitung_sacred(), xprole0])
	super(alasan)

func _hitung_sacred() -> int: # F0 (B-f, 14.19): pemindai papan, dipakai baris SEIMBANG
	var n = 0
	for i in range(p.rute_papan.size()):
		var node = p.rute_papan[i].get_node_or_null("JebakanTanah")
		if node != null and bool(node.get("sacred")):
			n += 1
	return n

func _cari_label(teks: String) -> Array:
	var hasil = []
	for l in find_children("*", "Label", true, false):
		if l.text == teks and l.is_visible_in_tree():
			hasil.append(l)
	return hasil

func _ambil_foto_akhir() -> void:
	# Tunggu animasi menang/kalah (3 dtk) + interstisial stub, lalu foto papan peringkat.
	var t = 0.0
	while _cari_label("FINAL STANDINGS").is_empty() and t < 30.0:
		await get_tree().process_frame
		t += get_process_delta_time()
	for i in 10: await get_tree().process_frame
	await _foto("papan_skor")
	_tulis_dan_keluar("MENANG")

func _warna_badan(model: Node3D) -> String:
	var m = model.get_node_or_null("Badan")
	if m == null: return "?"
	var mat = m.get_active_material(0)
	return mat.albedo_color.to_html(false) if mat else "?"

func _klik_teks(teks: String) -> bool:
	for b in find_children("*", "Button", true, false):
		if b.text == teks and b.is_visible_in_tree() and not b.disabled:
			b.pressed.emit()
			return true
	return false

func _foto(nama: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s_%s.png" % [awalan_foto, nama])
	foto_diambil += 1

func _pindai_jebakan_ai() -> void: # D0 (B-d): cetak jebakan BARU muncul (bukan tiap frame spam)
	for i in range(p.rute_papan.size()):
		for nama in _ELEMEN_DARI_NODE_UJI:
			var node = p.rute_papan[i].get_node_or_null(nama)
			if node == null:
				continue
			var kunci = "%d|%s|%d" % [i, nama, node.get_instance_id()]
			if _jejak_jebakan_ai.has(kunci):
				continue
			_jejak_jebakan_ai[kunci] = true
			var sacred = int(bool(node.get("sacred"))) if node.get("sacred") != null else 0
			print("JEBAKAN_AI s=%d e=%s petak=%d menara=%d sacred=%d" % [int(node.pemilik), _ELEMEN_DARI_NODE_UJI[nama], i, int(p.level_menara_petak[i]), sacred])

func _process(delta):
	if not mulai: return
	_pindai_jebakan_ai()
	if cek_profil and p.get("_permainan_selesai") and not _profil_dicek:
		_profil_dicek = true
		mulai = false
		_cek_profil_akhir()
		return
	# Fase 1: label ronde, spanduk FINAL ROUND, tawaran +300 COINS, foto papan peringkat.
	if p.label_ronde != null and p.label_ronde.text != _teks_ronde_terakhir:
		_teks_ronde_terakhir = p.label_ronde.text
		jejak.append("RONDE|" + _teks_ronde_terakhir)
	if not _spanduk_dicatat and not _cari_label("FINAL ROUND!").is_empty():
		_spanduk_dicatat = true
		jejak.append("SPANDUK_FINAL_ROUND|giliran=%d|ronde=%d" % [jumlah_giliran, p.ronde_sekarang])
		print("SPANDUK_FINAL_ROUND giliran=%d ronde=%d/%d" % [jumlah_giliran, p.ronde_sekarang, p.batas_ronde])
		if awalan_foto != "":
			_foto("spanduk")
	if not _cari_label("IN DEBT!").is_empty():
		if awalan_foto != "" and not _foto_hutang:
			_foto_hutang = true
			_foto("hutang")
		var uang_sebelum = p.daftar_pemain[p.slot_lokal].uang
		if _klik_teks("WATCH AD: +300 COINS"):
			klik_iklan_hutang += 1
			print("IKLAN_HUTANG klik ke-%d uang=%d%s" % [klik_iklan_hutang, uang_sebelum, "" if klik_iklan_hutang == 1 else "  GAGAL: ditawarkan lagi"])
			jejak.append("IKLAN_HUTANG|%d|uang=%d" % [klik_iklan_hutang, uang_sebelum])
			_cek_uang_setelah_iklan(uang_sebelum)
	if awalan_foto != "" and p.get("_permainan_selesai") and not _foto_akhir:
		_foto_akhir = true
		mulai = false
		_ambil_foto_akhir()
		return
	var g_lama = jumlah_giliran
	super(delta)
	if jumlah_giliran != g_lama and jumlah_giliran % 20 == 0:
		print("DIAG_PROGRES giliran=%d detik=%.0f" % [jumlah_giliran, detik_total])
	# Pengamat layar duel (diagnostik): catat fase/segel/judul saat berubah.
	if ui != null and ui.visible:
		var sig = "DUEL fase=%s segelM=%d segelP=%d tonton=%d judul='%s'" % [ui.fase_duel, int(ui.musuh_siap), int(ui.pemain_siap), int(ui.mode_tonton), ui.teks_judul.text.replace("\n", " / ")]
		if sig != _sig_duel:
			_sig_duel = sig
			jejak.append("D|%.1f|%s" % [detik_total, sig])
	if awalan_foto != "" and jumlah_giliran != g_lama and jumlah_giliran in [4, 9]:
		_foto("giliran%d" % jumlah_giliran)

func _cek_uang_setelah_iklan(uang_sebelum: int) -> void:
	await get_tree().create_timer(0.8).timeout
	var uang = p.daftar_pemain[p.slot_lokal].uang
	print("IKLAN_HUTANG uang %d -> %d cek=%s" % [uang_sebelum, uang, "OK" if uang == uang_sebelum + 300 else "GAGAL"])

func _snap() -> String:
	var n = p.rute_papan.size()
	var s = "G%d|%s|%s|" % [jumlah_giliran, p.giliran_sekarang, p.fase_giliran]
	for d in p.daftar_pemain:
		s += "[%d,%d,%d,g%d,p%d,b%d,k%d]" % [d.posisi_saat_ini, d.uang, d.bintang, d.sisa_gelembung, d.sisa_paralisis, d.sisa_bakar, d.inventaris_kartu.size()]
	var own = []
	for i in range(n):
		own.append(str(p.pemilik_petak[i]))
	s += "|o:" + ",".join(own)
	var pos = []
	for sl in range(p.jumlah_pemain()):
		pos.append(str(p._model(sl).global_position.snapped(Vector3(0.1, 0.1, 0.1))))
	s += "|xyz:" + ";".join(pos)
	if mode_quick_uji:
		s += "|r%d" % p.ronde_sekarang
	return s

# ---------------------------------------------------------------- T4 (Fase 2)
func _cek_profil_akhir() -> void:
	var t = 0.0
	while _cari_label("FINAL STANDINGS").is_empty() and t < 40.0:
		await get_tree().process_frame
		t += get_process_delta_time()
	for i in 10: await get_tree().process_frame
	var hasil = []
	var r: Dictionary = p._ringkasan_hadiah
	var baris_lokal = {}
	for b in p._papan_skor_akhir:
		if int(b["slot"]) == p.slot_lokal:
			baris_lokal = b
	var st = baris_lokal.get("stat", {})
	var peng = baris_lokal.get("penghargaan", [])
	var menang = p._slot_pemenang_akhir == p.slot_lokal
	var pengali = (1.0 if p.mode_quick else 1.6) * (1.5 if menang else 1.0)
	var xp_harus = roundi(5 * int(st.get("giliran", 0)) * pengali)
	var cr_harus = roundi(2 * int(st.get("giliran", 0)) * pengali)
	hasil.append(["rumus", not r.is_empty() and r["xp_match"] == xp_harus and r["crowns_match"] == cr_harus and r["xp_penghargaan"] == 15 * peng.size() and r["crowns_penghargaan"] == 10 * peng.size()])
	var xp_tambah = int(r.get("xp_match", 0)) + int(r.get("xp_penghargaan", 0)) + int(r.get("xp_misi", 0))
	var cr_tambah = int(r.get("crowns_match", 0)) + int(r.get("crowns_penghargaan", 0)) + int(r.get("crowns_misi", 0)) + int(r.get("crowns_naik_level", 0))
	hasil.append(["profil", ProfilPemain.xp_total == xp0 + xp_tambah and ProfilPemain.crowns == cr0 + cr_tambah])
	var c = ConfigFile.new()
	var ok_berkas = c.load(ProfilPemain.BERKAS) == OK and int(c.get_value("profil", "xp", -1)) == ProfilPemain.xp_total and int(c.get_value("profil", "crowns", -1)) == ProfilPemain.crowns
	hasil.append(["berkas", ok_berkas])
	var baru = load("res://profil_pemain.gd").new()
	baru.muat()
	hasil.append(["muat_ulang", baru.xp_total == ProfilPemain.xp_total and baru.crowns == ProfilPemain.crowns and baru.nama == ProfilPemain.nama and baru.misi == ProfilPemain.misi])
	baru.free()
	hasil.append(["kartu", not _cari_label("YOUR REWARDS").is_empty()])
	hasil.append(["iklan_sebelum_papan", PengelolaIklan.jumlah_interstisial == 0])
	var semua_peng = []
	for b in p._papan_skor_akhir:
		semua_peng.append("%d:%s" % [int(b["slot"]), ",".join(b.get("penghargaan", []))])
	# DOUBLE (stub iklan berhadiah)
	var teks_double = "-"
	if iklan_uji:
		var xp_a = ProfilPemain.xp_total
		var cr_a = ProfilPemain.crowns
		var klik = _klik_teks("WATCH AD: DOUBLE REWARDS")
		for i in 60: await get_tree().process_frame
		var tambah_harus = int(r["xp_match"]) + int(r["xp_penghargaan"])
		var ok_double = klik and ProfilPemain.xp_total == xp_a + tambah_harus and ProfilPemain.crowns >= cr_a + int(r["crowns_match"]) + int(r["crowns_penghargaan"]) and not _cari_label("DOUBLED!").is_empty()
		if not bool(r.get("bisa_double", false)):
			ok_double = not klik
		hasil.append(["double", ok_double])
		teks_double = "klik=%s xp %d->%d" % [str(klik), xp_a, ProfilPemain.xp_total]
	if awalan_foto != "":
		await _foto("papan_hadiah")
	# EXIT -> interstisial dipanggil di sini (bukan sebelum papan skor)
	PengelolaIklan.uji_jeda_interstisial = 3.0
	var klik_exit = _klik_teks("EXIT TO MAIN MENU")
	for i in 20: await get_tree().process_frame
	hasil.append(["iklan_saat_exit", klik_exit and PengelolaIklan.jumlah_interstisial == 1])
	var gagal = []
	for h in hasil:
		if not h[1]:
			gagal.append(h[0])
	print("PROFIL_CEK %s menang=%s quick=%s giliran=%d xp=%d/%d cr=%d/%d peng=%s misi=%d lv=%d->%d double=%s semua_peng=%s %s" % ["OK" if gagal.is_empty() else "GAGAL", str(menang), str(p.mode_quick), int(st.get("giliran", 0)), int(r.get("xp_match", -1)), xp_harus, int(r.get("crowns_match", -1)), cr_harus, str(peng), r.get("misi_selesai", []).size(), int(r.get("level_awal", 0)), int(r.get("level_akhir", 0)), teks_double, " ".join(semua_peng), " ".join(gagal)])
	_tulis_dan_keluar("MENANG")
