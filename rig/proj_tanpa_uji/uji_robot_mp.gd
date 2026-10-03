extends Node
# ROBOT UJI MULTIPLAYER N DEVICE (autoload). Tidak melakukan apa pun kecuali
# proses dijalankan dengan argumen robot=host|client.
#   host  : robot=host mode=3 peta=alam giliran=40 log=/x.txt skenario=...
#   client: robot=client urut=1 log=/y.txt
# Alur: LocalPlay.tscn (lobby asli) -> host pilih mode & peta lewat tombol ->
# START -> panggung_utama.tscn (adegan permainan asli dgn model pengganti) ->
# tiap device memainkan slot-nya sendiri lewat tombol UI. Setiap awal giliran
# pemain host, host meminta "potret" keadaan logis dari semua client lalu
# membandingkannya dengan keadaannya sendiri.
# skenario: "" | "client_keluar" (client urut=2 keluar di giliran K) |
#           "host_keluar" (host keluar di giliran K, client lanjut sendiri-sendiri)
# MIGRASI HOST (host keluar -> pemain lain lanjut bersama):
#   "host_keluar_migrasi"  host keluar giliran K; client dgn slot terkecil menekan
#                          BECOME HOST 1 dtk setelah panel muncul, lainnya menunggu;
#                          host baru menekan START NOW begitu semua kembali / 20 dtk
#   "host_keluar_duel_migrasi" sama, host keluar saat pilih elemen duel
#   "migrasi_sendiri"      seperti host_keluar_migrasi, client urut=3 PLAY ALONE
#   "migrasi_rebutan"      client urut 1 & 2 menekan BECOME HOST bersamaan
#   "migrasi_dua_kali"     host baru juga keluar 8 giliran setelah migrasi
#   "host_hotspot_mati"    host memutus semua client (jaringan host hilang) di giliran
#                          K; 5 dtk kemudian WAIT FOR PLAYERS; client menunggu
#   "host_hotspot_telat"   sama, tapi client menekan BECOME HOST; host baru WAIT
#                          FOR PLAYERS setelah 15 dtk -> "already the new host"
var peran = ""
var urut = 1
var mode_uji = 0
var peta_uji = "alam"
var batas_giliran = 40
var berkas_log = ""
var benih = 7
var skenario = ""
var giliran_keluar = 8
var urut_keluar = 2
var respect_awal_uji = 0
var panjang_uji = "classic" # Fase 1: "quick" | "classic" (bawaan classic: skenario lama tidak berubah)
# C2 (B-c, 26-09): "" (bawaan, ProfilPemain.arena kosong -> host jatuh balik ke
# Balanced, K16) | "attack" | "defense" (preset sungguhan lewat build_dari_preset)
# | "custom_ilegal" (semua node Lv3 + Ultimate, JAUH di atas 12 SP -> HARUS
# ditolak build_sah & jatuh balik ke Balanced -- bukti validasi ulang host).
var arena_uji = ""
# D6 (B-d, rig-only, TIDAK ikut ZIP): role_ai=<r>[,<r>...] -- role[0] dipakai
# host, role[indeks urut] dipakai client urut itu (indeks sama seperti pemilihan
# bawaan _pilih_role_lobby: host=0, client=urut) -- kosong/indeks di luar
# jangkauan = jatuh balik ke pemilihan bawaan (variasi per device), TIDAK error.
var role_ai_uji: Array = []
var _akhir_dicatat = false
var _nama_dicatat := false # Fase 6
var _xp0 = 0   # Fase 2: profil di awal (HOME tiap proses terpisah -> biasanya 0)
var _cr0 = 0

var p = null
var ui = null
var tahap = "awal"
var jumlah_giliran = 0
var _sig_event = "" # Fase 5 G1: log EVENT tiap perubahan (ronde_event/aktif/terakhir)
var _sig_bounty = "" # Fase 5 G2: log BOUNTY tiap perubahan (aktif/terakhir/bintang tiap slot)
var _sig_bantuan = "" # Fase 5 G3: log KARTU_BANTUAN tiap perubahan (stat kartu_bantuan + isi inventaris per slot)
# Fase 5 G6 (rig-only): ai_cepat=1 -> profil dihidupkan; di multiplayer tombol >> TIDAK boleh muncul dan Engine.time_scale TIDAK boleh 2x (6.0 = 3.0 x 2).
var ai_cepat_uji = false
var _acmp_frame = 0
var _acmp_2x = 0
var _acmp_tombol = 0
var kaya_awal = false # Fase 5 G3 (rig-only): host mulai +3000 koin -> pemain lain tertinggal >= 1000 -> kartu bantuan muncul saat lewat START
var hutang_habis_slot := -1 # Fase 5 G8 (rig-only): hutang_habis=SLOT -> paksa jalur "petak terakhir terjual, masih minus"
var _hb_teks_terakhir := ""
var _hb_bawa := 0
var _hb_pasang := 0
var _hb_giliran_bawa := -1
var _kaya_diberikan = false
# --- Fase 5 G4 (rig-only): tebak=1 -> robot penonton menebak tiap duel yang ditonton (selang-seling penyerang/pembela)
# dan mencocokkan stat tebak_benar + teks "Good guess!"/"Wrong guess." dengan pemenang duel sebenarnya (log TEBAK_*).
# tebak_telat=1 -> robot dengan urut GENAP (client2, client4) sengaja mengetuk SESUDAH jendela tutup -> host harus menjawab "Too late!".
var tebak_uji = false
var tebak_telat_uji = false
var _tebak_sejak = -1.0
var _tebak_n = 0
var _tebak_menunggu = -1
var _tebak_ui_hasil = ""
var _tebak_menang_prev: Array = []
var _tebak_benar_prev = 0
var _tebak_total = 0
var _tebak_benar_total = 0
var _tebak_cek_ok = 0
var _tebak_cek_gagal = 0
var _tebak_telat_nomor = -2     # nomor duel yang sudah diketuk telat (jangan dobel)
var _tebak_telat_kirim = 0
var _tebak_telat_ditolak = 0
var _sig_tebak_ui = ""
var _sig_tebak_stat = ""
var bounty_pilih = false # Fase 5 G2 (rig-only): robot memilih elemen bounty yang sedang aktif -> klaim pasti terjadi
var giliran_terakhir = ""
var teks_terakhir = ""
var periksa_terakhir = -1
var hitung_aksi = 0
var detik_diam = 0.0
var detik_total = 0.0
var jejak = []
var cek_ok = 0
var cek_gagal = 0
var nomor_cek = 0
var menunggu_cek = false
var potret_host = {}
var balasan = {}
var waktu_cek = 0.0
var selesai = false
var lobby_diproses = false
var giliran_setelah_putus = 0
var sudah_putus = false
var periksa_dicek = -1
var kartu_beda = 0
var kartu_awal = false
var kartu_diberikan = false
# --- PENGAMAT DUEL (diagnostik tampilan per device) ---
var pedang_awal = false
var _sig_duel = ""
var _pilih_elemen_sejak = -1.0 # jeda "berpikir" ala manusia sebelum robot memilih
var _koin_sejak = -1.0
# --- migrasi host ---
const SKENARIO_HOST_KELUAR = ["host_keluar", "host_keluar_migrasi", "migrasi_sendiri", "migrasi_rebutan", "migrasi_dua_kali"]
const SKENARIO_MIGRASI = ["host_keluar_migrasi", "host_keluar_duel_migrasi", "migrasi_sendiri", "migrasi_rebutan", "migrasi_dua_kali", "host_hotspot_telat"]
var migrasi_selesai = 0       # berapa kali panel migrasi tertutup (lanjut bersama / sendiri)
var cek_ok_migrasi = 0        # cek sinkron yang lolos SETELAH migrasi
var panel_migrasi_sejak = -1.0
var host_migrasi_sejak = -1.0
var giliran_saat_migrasi = -1
var _sig_migrasi = ""
var _sudah_tekan_host = false

func _ready():
	for a in OS.get_cmdline_user_args():
		if a.begins_with("robot="): peran = a.substr(6)
		if a.begins_with("urut="): urut = int(a.substr(5))
		if a.begins_with("mode="): mode_uji = int(a.substr(5))
		if a.begins_with("peta="): peta_uji = a.substr(5)
		if a.begins_with("giliran="): batas_giliran = int(a.substr(8))
		if a.begins_with("log="): berkas_log = a.substr(4)
		if a.begins_with("seed="): benih = int(a.substr(5))
		if a.begins_with("skenario="): skenario = a.substr(9)
		if a.begins_with("keluar="): giliran_keluar = int(a.substr(7))
		if a.begins_with("keluar_urut="): urut_keluar = int(a.substr(12))
		if a.begins_with("panjang="): panjang_uji = a.substr(8)
		if a == "bounty_pilih=1": bounty_pilih = true
		if a == "tebak=1": tebak_uji = true # Fase 5 G4
		if a == "tebak_telat=1": tebak_telat_uji = true; tebak_uji = true # Fase 5 G4
		if a == "kaya_awal=1": kaya_awal = true
		if a.begins_with("hutang_habis="): hutang_habis_slot = int(a.substr(13)) # Fase 5 G8
		if a == "ai_cepat=1": ai_cepat_uji = true # Fase 5 G6
		if a.begins_with("arena="): arena_uji = a.substr(6)
		if a == "arena_palsu=1": arena_uji = "custom_ilegal" # F0 (B-f, 14.19, U10): alias -- mekanisme SAMA "custom_ilegal" (B-c/C2) yang sudah menguji rpc_role_lobby/build_arena K16, cuma nama argumen sesuai rencana
		if a.begins_with("role_ai="): role_ai_uji = a.substr(8).split(",") # D6 (B-d, rig-only)
		if a == "kartu_awal=1": kartu_awal = true
		if a == "pedang_awal=1": pedang_awal = true
	if peran == "":
		set_process(false)
		return
	process_mode = Node.PROCESS_MODE_ALWAYS
	Engine.max_fps = 60
	Engine.time_scale = 3.0
	if ai_cepat_uji:
		ProfilPemain.atur_ai_cepat(true) # Fase 5 G6
	# Fase 6 (rig-only): identitas berbeda per robot -> lobby/papan harus menampilkan nama + level yang benar.
	ProfilPemain.nama = "Bot %s%d" % [peran, urut]
	ProfilPemain.xp_total = 150 * (urut + 1) # level 2-3 (100 + 20 per level)
	ProfilPemain.respect = urut + 1
	respect_awal_uji = ProfilPemain.respect # G2: baseline Respect sebelum laga (Respect bisa tiba sebelum _respect_uji mulai)
	ProfilPemain.mvp_total = urut
	# Fase 7 G3 (rig-only): kosmetik berbeda per robot; client3 sengaja mengirim id RUSAK -> host harus menjadikannya AWAL.
	var kos_uji = {"host1": {"pawn": "pawn_gold", "title": "title_duelist", "frame": "frame_royal"},
		"client1": {"pawn": "pawn_lava", "title": "title_tile_legend", "frame": "frame_bronze"},
		"client2": {"pawn": "pawn_shadow", "title": "title_storm_caller", "frame": "frame_gold"},
		"client3": {"pawn": "zzz", "title": "pawn_rose", "frame": "frame_silver"}}
	if kos_uji.has("%s%d" % [peran, urut]):
		ProfilPemain.kosmetik_dipakai = kos_uji["%s%d" % [peran, urut]]
	seed(benih * 101 + urut)
	_xp0 = ProfilPemain.xp_total
	_cr0 = ProfilPemain.crowns
	_catat("ROBOT %s urut=%d mode=%d peta=%s skenario=%s" % [peran, urut, mode_uji, peta_uji, skenario])

func _catat(t: String) -> void:
	jejak.append(t)
	print(t)

func _tulis_log() -> void:
	if berkas_log == "": return
	var f = FileAccess.open(berkas_log, FileAccess.WRITE)
	if f:
		f.store_string("\n".join(jejak) + "\n")
		f.close()

func _akhiri(alasan: String) -> void:
	if selesai: return
	selesai = true
	# U3/U4 ulang: role + jebakan dibawa tiap slot di device ini (harus sama di semua HP, tidak kosong).
	# C2 (B-c, 26-09): + build (dict node_id->level/ULT_<role>->bool) -- harus SAMA
	# di semua HP & TIDAK KOSONG di multiplayer (minimal preset Balanced, K16).
	var cetak_role = []
	if p != null:
		for d in p.daftar_pemain:
			cetak_role.append("%s:%s:%s" % [d.role, "+".join(d.jebakan_dibawa), str(d.build)])
	# D6 (B-d, rig-only): satu baris per slot AI, mudah di-grep -- buktikan
	# jebakan_dibawa slot AI itu (D2/D3, _siapkan_role_solo/_bangun_role_slot 2
	# putaran) memang beda kalau build_lawan lawan-lawannya beda (bandingkan
	# manual antar-run, TIDAK ada nilai target "benar" tunggal di sini).
	if p != null:
		for s in range(p.daftar_pemain.size()):
			var d = p.daftar_pemain[s]
			_catat("CEK_BD_JEBAKAN_AI s=%d role=%s jebakan=%s build=%s" % [s, d.role, "+".join(d.jebakan_dibawa), str(d.build)])
	# C8 (B-c, 26-09) SEMENTARA -- jumlahkan counter _tambah_stat sementara di
	# pemain.gd/pemain_duel.gd (cek_c5_guard/tornado/phoenix/rockbreaker0) lewat
	# semua slot, supaya baris CEK_C5 di bawah membuktikan jalur itu BENAR-BENAR
	# terlewati di match MP ini (bukan cuma "tidak error"). HAPUS baris ini +
	# 8 counter _tambah_stat terkait sebelum ZIP dikirim (pelajaran 14.12).
	if p != null:
		var totc5 = {}
		for kunci_c5 in ["cek_c5_guard", "cek_c5_tornado", "cek_c5_phoenix", "cek_c5_rockbreaker0"]:
			var total_c5 = 0
			for st in p.statistik_slot:
				total_c5 += int(st.get(kunci_c5, 0))
			totc5[kunci_c5] = total_c5
		_catat("CEK_C5 %s" % str(totc5))
	# D6 (B-d, rig-only) SEMENTARA -- jumlahkan 5 counter _tambah_stat sementara
	# di ai_jebakan.gd/ai_musuh.gd, buktikan jalur K17/K18/K19/P3 BENAR-BENAR
	# terlewati (bukan cuma "tidak error"). cek_bd_benteng_tahan_ai 0 BUKAN
	# kegagalan (lihat komentar di titik panggilnya, ai_musuh.gd) -- yang lain
	# diharapkan >0 di skenario yang relevan (Sacred/Guard/tanah/Fortress).
	# HAPUS baris ini + 5 counter terkait di produksi sebelum ZIP (pelajaran 14.12).
	if p != null:
		var totbd = {}
		for kunci_bd in ["cek_bd_sacred", "cek_bd_guard_nol", "cek_bd_fight_faktor", "cek_bd_benteng_lewati", "cek_bd_benteng_tahan_ai"]:
			var total_bd = 0
			for st in p.statistik_slot:
				total_bd += int(st.get(kunci_bd, 0))
			totbd[kunci_bd] = total_bd
		_catat("CEK_BD %s" % str(totbd))
	if tebak_uji and p != null:
		_catat("TEBAK_RINGKAS slot=%d tebakan=%d benar=%d telat_kirim=%d telat_ditolak=%d cek_ok=%d cek_gagal=%d tebak_benar_per_slot=%s" % [p.slot_lokal, _tebak_total, _tebak_benar_total, _tebak_telat_kirim, _tebak_telat_ditolak, _tebak_cek_ok, _tebak_cek_gagal, str(p.statistik_slot.map(func(st): return int(st.get("tebak_benar", 0))))])
	if ai_cepat_uji:
		_catat("AI_CEPAT_MP_RINGKAS peran=%s profil=%s frame=%d frame_2x=%d frame_tombol_terlihat=%d" % [peran, str(ProfilPemain.ai_cepat), _acmp_frame, _acmp_2x, _acmp_tombol])
	if p != null and is_instance_valid(p) and migrasi_selesai > 0:
		_catat_profil_nama("sesudah_migrasi") # Fase 6: nama tetap benar sesudah host pindah
	_catat("SELESAI %s peran=%s giliran=%d cek_ok=%d cek_gagal=%d kartu_beda=%d detik=%.0f migrasi=%d cek_ok_migrasi=%d jaringan=%s role=%s" % [alasan, peran, jumlah_giliran, cek_ok, cek_gagal, kartu_beda, detik_total, migrasi_selesai, cek_ok_migrasi, StatusJaringan.peran_multiplayer, ",".join(cetak_role)])
	_tulis_log()
	get_tree().quit()

# ---------------------------------------------------------------- utilitas UI
func _semua_tombol() -> Array:
	return get_tree().root.find_children("*", "Button", true, false)

func _pengecek() -> bool:
	# Device yang membandingkan potret & mengakhiri uji: siapa pun host-nya SAAT INI
	# (host baru setelah migrasi ikut mengecek), atau robot host yang lanjut sendiri.
	return StatusJaringan.peran_multiplayer == "host" or (peran == "host" and StatusJaringan.peran_multiplayer == "")

func _atur_rig_migrasi() -> void:
	# Satu mesin: tiap proses butuh port UDP & port game sendiri.
	if p.get("migrasi") == null:
		return
	var i = 0 if peran == "host" else urut
	p.migrasi.port_dengar = 7790 + i
	p.migrasi.port_tujuan = [7790, 7791, 7792, 7793]
	p.migrasi.alamat_tambahan = ["127.0.0.1"]
	p.migrasi.port_game = 7800 + i
	if skenario.begins_with("host_hotspot"):
		p.uji_paksa_jaringan_putus = true

func _klik_teks(teks: String) -> bool:
	for b in _semua_tombol():
		if b.text == teks and b.is_visible_in_tree() and not b.disabled:
			b.pressed.emit()
			return true
	return false

func _klik_awalan(awalan: String) -> bool:
	# Sama seperti _klik_teks tapi cocok AWALAN teks -- dipakai untuk tombol
	# "MY ROLE: —" / "MY ROLE: FIRE" dst. (Fase 4 A6) yang teksnya berubah-ubah.
	for b in _semua_tombol():
		if b.text.begins_with(awalan) and b.is_visible_in_tree() and not b.disabled:
			b.pressed.emit()
			return true
	return false

func _pilih_role_lobby(label: String) -> void:
	# Fase 4 A6: tombol START lobby baru aktif kalau SEMUA slot manusia yang
	# terisi sudah punya role (lihat _segarkan_lobby/semua_role_terisi di
	# layar_local_play.gd) -- robot host & tiap robot client HARUS membuka
	# "MY ROLE" dan memilih sebelum lobby bisa lanjut, kalau tidak START GAME
	# akan macet (disabled) selamanya dan uji berakhir TIMEOUT.
	# Role dibedakan per device (host=api, client urut=1 -> air, dst) sekadar
	# variasi -- role kembar antar pemain tetap sah, tidak dilarang.
	var indeks = 0 if label == "host" else urut
	var pilihan = DataRole.ROLE[indeks % DataRole.ROLE.size()]
	# D6 (B-d, rig-only): role_ai= menimpa pilihan bawaan kalau device ini punya
	# entri yang sah di indeks yang sama (host=0, client urut=N).
	if indeks < role_ai_uji.size() and DataRole.ROLE.has(String(role_ai_uji[indeks])):
		pilihan = String(role_ai_uji[indeks])
	var nama = DataRole.nama_role(pilihan)
	# C2 (B-c, 26-09): arena= mengisi ProfilPemain.arena[pilihan] SEBELUM MY ROLE
	# dibuka -- _buka_role_lobby (layar_local_play.gd) membaca simpanan ini
	# lewat DataRole.build_arena persis seperti pemain sungguhan.
	if arena_uji != "":
		ProfilPemain.arena[pilihan] = _build_arena_uji(pilihan)
	if skenario == "ganti_role_2x" and label == "client1":
		# U4 (skenario baru role): client ganti role DUA KALI sebelum START --
		# buka MY ROLE, pilih role LAIN dulu, OK, lalu ulangi dengan pilihan
		# biasa (di bawah) -- role AKHIR yang harus dipakai (dan disinkronkan
		# ke host lewat rpc_role_lobby kedua, menimpa yang pertama) adalah
		# pilihan KEDUA ini, bukan yang pertama.
		var pilihan_pertama = DataRole.ROLE[(indeks + 1) % DataRole.ROLE.size()]
		var nama_pertama = DataRole.nama_role(pilihan_pertama)
		_catat("LOBBY %s: klik MY ROLE (ganti-1) = %s" % [label, str(_klik_awalan("MY ROLE"))])
		await get_tree().process_frame
		_catat("LOBBY %s: klik role %s (ganti-1) = %s" % [label, nama_pertama, str(_klik_teks(nama_pertama))])
		await get_tree().process_frame
		_catat("LOBBY %s: klik OK (ganti-1) = %s" % [label, str(_klik_teks("OK"))])
		await get_tree().process_frame
	_catat("LOBBY %s: klik MY ROLE = %s" % [label, str(_klik_awalan("MY ROLE"))])
	await get_tree().process_frame
	_catat("LOBBY %s: klik role %s = %s" % [label, nama, str(_klik_teks(nama))])
	await get_tree().process_frame
	_catat("LOBBY %s: klik OK = %s" % [label, str(_klik_teks("OK"))])
	await get_tree().process_frame

func _build_arena_uji(role: String) -> Dictionary:
	# C2 (B-c, 26-09): simpanan ProfilPemain.arena[role] palsu dipakai uji --
	# "custom_ilegal" SENGAJA jauh di atas SP_ARENA (12) supaya build_sah host
	# HARUS menolaknya & jatuh balik ke preset Balanced (K16, bukti validasi).
	match arena_uji:
		"attack":
			return {"preset": "attack", "node": DataRole.build_dari_preset(role, "attack", DataRole.SP_ARENA, DataRole.LEVEL_ROLE_MAKS)}
		"defense":
			return {"preset": "defense", "node": DataRole.build_dari_preset(role, "defense", DataRole.SP_ARENA, DataRole.LEVEL_ROLE_MAKS)}
		"custom_guard":
			# C8 (B-c, 26-09) SEMENTARA -- node ketahanan PERTAMA role ini Lv3
			# (cost 6, PASTI >= ambang Guard) + Ultimate (cost 4, supaya
			# Tornado/Phoenix ikut bisa diuji di run yang sama) + node
			# ketahanan KEDUA Lv1 + 1 node jebakan Lv1 (sisa 2 SP) = 12 SP
			# pas, LEGAL. Untuk membuktikan rpc_efek_role "guard"/"tornado" +
			# Phoenix (tetap) benar2 terlewati di match MP nyata. HAPUS
			# cabang ini sebelum ZIP dikirim (pelajaran 14.12, sekali pakai).
			var bg := {}
			var tahan_g: Array = DataRole.TAHAN_ROLE.get(role, [])
			if tahan_g.size() > 0: bg[tahan_g[0]] = 3
			bg["ULT_" + role] = true
			if tahan_g.size() > 1: bg[tahan_g[1]] = 1
			var jeb_g: Array = DataRole.PRESET_URUTAN_JEBAKAN.get(role, [])
			if jeb_g.size() > 0: bg[jeb_g[0]] = 1
			return {"preset": "custom", "node": bg}
		"custom_ilegal":
			var b := {}
			for id_node in DataRole.NODE_JEBAKAN_ID.get(role, []):
				b[id_node] = 3
			for id_node in DataRole.TAHAN_ROLE.get(role, []):
				b[id_node] = 3
			b["ULT_" + role] = true
			return {"preset": "custom", "node": b}
	return {}

func _process(delta):
	if selesai: return
	detik_total += delta
	var adegan = get_tree().current_scene
	if adegan == null: return
	if ai_cepat_uji and p != null:
		_acmp_frame += 1
		if is_equal_approx(Engine.time_scale, 6.0): _acmp_2x += 1
		if p.tombol_ai_cepat != null and p.tombol_ai_cepat.visible: _acmp_tombol += 1
	if tahap == "awal":
		if adegan.get_script() != null and adegan.get_script().resource_path.ends_with("layar_local_play.gd"):
			tahap = "lobby"
			_jalankan_lobby(adegan)
		return
	if tahap == "lobby":
		var pm = adegan.get_node_or_null("Pemain")
		if pm != null and pm.has_method("periksa_status_petak"):
			p = pm
			ui = p.ui_elemen
			tahap = "siap"
			_catat("MASUK_GAME slot_lokal=%d pemain=%d peran_jaringan=%s" % [p.slot_lokal, p.jumlah_pemain(), StatusJaringan.peran_multiplayer])
			_atur_rig_migrasi()
		elif detik_total > 90.0:
			_akhiri("LOBBY_MACET")
		return
	if tahap == "siap":
		if peran == "host" and (kartu_awal or pedang_awal) and not kartu_diberikan:
			# Semua slot mulai dengan kartu simpanan (sampai ke client lewat siaran
			# state pertama). Diberikan SEBELUM START ditekan: kalau client sudah siap
			# duluan, siaran pertama terjadi di dalam klik START itu sendiri.
			# kartu_awal & pedang_awal BISA dipakai sekaligus (satu penjaga saja,
			# supaya tidak diberikan dua kali).
			kartu_diberikan = true
			for d in p.daftar_pemain:
				if kartu_awal:
					d.inventaris_kartu.append({"id": "dadu_rendah", "tipe_eksekusi": "simpan", "teks": "LOW ROLL\n(1-3)\n3 Turns"})
					d.inventaris_kartu.append({"id": "pelindung", "tipe_eksekusi": "simpan", "teks": "SHIELD\n(Keep)"})
					d.inventaris_kartu.append({"id": "dadu_tinggi", "tipe_eksekusi": "simpan", "teks": "HIGH ROLL\n(10-12)\n3 Turns"})
				if pedang_awal:
					for _i in 3:
						d.inventaris_kartu.append({"id": "pedang_3", "tipe_eksekusi": "simpan", "teks": "SWORD LV 3\n+3 ATK\n(Attacker)"})
		if peran == "host" and kaya_awal and not _kaya_diberikan:
			_kaya_diberikan = true
			p.daftar_pemain[0].uang += 3000
		if _klik_teks("START GAME"):
			tahap = "main"
			if peran == "host":
				p.mesin_acak.seed = benih * 31 + 1
			_catat("START_DITEKAN")
		elif detik_total > 150.0:
			_akhiri("START_TIDAK_MUNCUL")
		return
	if tahap == "main":
		_langkah_main(delta)

# ---------------------------------------------------------------- lobby
func _jalankan_lobby(lobby) -> void:
	if lobby_diproses: return
	lobby_diproses = true
	# Pencarian UDP dimatikan: di satu mesin ketiga proses tidak bisa bersama-sama
	# memakai port 7778. Host/client ditentukan langsung oleh robot.
	lobby.mode_saat_ini = ""
	await get_tree().create_timer(0.3).timeout
	if peran == "host":
		lobby._bersihkan_semua()
		lobby._jadi_host()
		await get_tree().create_timer(0.5).timeout
		var nama_mode = lobby.MODE_LOBBY[mode_uji]["nama"]
		_catat("LOBBY host: klik mode '%s' = %s" % [nama_mode, str(_klik_teks(nama_mode))])
		var nama_peta = "Grassland" if peta_uji == "alam" else "Night Beach"
		_catat("LOBBY host: klik peta '%s' = %s" % [nama_peta, str(_klik_teks(nama_peta))])
		var nama_panjang = "QUICK" if panjang_uji == "quick" else "CLASSIC"
		_catat("LOBBY host: klik panjang '%s' = %s" % [nama_panjang, str(_klik_teks(nama_panjang))])
		await _pilih_role_lobby("host")
		if skenario == "host_ganti_mode_role":
			# U4 (skenario baru role): host ganti MODE setelah semua client
			# (dan host sendiri) sudah memilih role -- role_peer TIDAK dibuang
			# oleh _pilih_mode_lobby (cuma role_ai_lobby yang diundi ulang),
			# jadi role yang sudah dipilih harus tetap terpakai & tombol START
			# harus tetap aktif tanpa perlu pilih ulang. Dipanggil dari mode
			# "3 PLAYERS" (3 slot manusia) -> "3 PLAYERS + 1 AI" (3 slot
			# manusia YANG SAMA + 1 AI tambahan) supaya tidak ada client yang
			# kehilangan slotnya (uji pergantian slot manusia sudah dicakup
			# skenario migrasi/keluar lain, bukan fokus di sini).
			var t0 = 0.0
			while lobby != null and is_instance_valid(lobby) and lobby.tombol_mulai_lobby.disabled and t0 < 60.0:
				await get_tree().process_frame
				t0 += get_process_delta_time()
			if is_instance_valid(lobby):
				_catat("LOBBY host: START aktif sebelum ganti mode = %s" % str(not lobby.tombol_mulai_lobby.disabled))
				_catat("LOBBY host: ganti mode '3 PLAYERS + 1 AI' = %s" % str(_klik_teks("3 PLAYERS + 1 AI")))
				await get_tree().process_frame
				_catat("LOBBY host: role_peer setelah ganti mode = %s | START masih aktif = %s" % [str(lobby.role_peer), str(not lobby.tombol_mulai_lobby.disabled)])
		var t = 0.0
		while lobby != null and is_instance_valid(lobby) and lobby.tombol_mulai_lobby.disabled and t < 60.0:
			await get_tree().process_frame
			t += get_process_delta_time()
		if not is_instance_valid(lobby):
			return
		_catat("LOBBY host: pemain = %s" % lobby.label_pemain_lobby.text.replace("\n", " | "))
		_catat("LOBBY host: info = %s" % lobby.label_info_lobby.text.replace("\n", " "))
		await get_tree().create_timer(1.0).timeout
		_catat("LOBBY host: START = %s" % str(_klik_teks("START GAME")))
	else:
		await get_tree().create_timer(0.8 + 1.2 * urut).timeout
		lobby._bersihkan_semua()
		lobby._jadi_client("127.0.0.1")
		var t = 0.0
		while is_instance_valid(lobby) and not lobby.panel_lobby.visible and t < 30.0:
			await get_tree().process_frame
			t += get_process_delta_time()
		if is_instance_valid(lobby):
			await get_tree().create_timer(1.0).timeout
			if is_instance_valid(lobby):
				_catat("LOBBY client%d: pemain = %s" % [urut, lobby.label_pemain_lobby.text.replace("\n", " | ")])
				_catat("LOBBY client%d: info = %s" % [urut, lobby.label_info_lobby.text.replace("\n", " ")])
				await _pilih_role_lobby("client%d" % urut)

# ---------------------------------------------------------------- permainan
func _urus_hutang_habis(cetak: Callable) -> void:
	# Fase 5 G8 (rig-only, hutang_habis=SLOT): begitu SLOT punya >= 2 petak dan uang >= 0, uangnya dibuat
	# minus melebihi nilai jual semua petaknya -> denda berikutnya = bangkrut, petak terakhir terjual, masih
	# minus -> harus "No more tiles! ... carry the debt." dan giliran lanjut (dulu macet). Dipasang ulang
	# sampai jalur itu terjadi sekali. Host/solo saja yang memasang; semua device mencatat.
	var s = hutang_habis_slot
	if s < 0 or s >= p.jumlah_pemain():
		return
	var teks = p.teks_dadu.text
	if teks.begins_with("No more tiles!") and not _hb_teks_terakhir.begins_with("No more tiles!"):
		_hb_bawa += 1
		_hb_giliran_bawa = jumlah_giliran
		cetak.call("HUTANG_BAWA ke-%d teks='%s' giliran=%d uang=%s mode_jual=%s membidik=%s petak_slot=%d" % [_hb_bawa, teks, jumlah_giliran,
			str(p.daftar_pemain.map(func(d): return d.uang)), str(p.mode_jual_aset), str(p.mode_membidik), _hb_jumlah_petak(s)])
	_hb_teks_terakhir = teks
	if _hb_giliran_bawa >= 0 and jumlah_giliran >= _hb_giliran_bawa + 2:
		cetak.call("HUTANG_LANJUT giliran=%d mode_jual=%s uang=%s" % [jumlah_giliran, str(p.mode_jual_aset), str(p.daftar_pemain.map(func(d): return d.uang))])
		_hb_giliran_bawa = -1
	if _hb_bawa > 0 or StatusJaringan.peran_multiplayer == "client":
		return
	if p.mode_jual_aset or p.daftar_pemain[s].uang < 0 or _hb_jumlah_petak(s) < 2:
		return
	var nilai = 0
	for i in range(p.rute_papan.size()):
		if p.pemilik_petak[i] == s:
			var lv = p.level_menara_petak[i]
			var n = p.harga_tanah
			if lv >= 1: n += p.harga_menara_lv1
			if lv == 2: n += p.harga_menara_lv2
			nilai += int(n * 0.7)
	p.daftar_pemain[s].uang = -nilai - 1000
	p.update_ui_status()
	_hb_pasang += 1
	cetak.call("HUTANG_PASANG ke-%d slot=%d petak=%d nilai_jual=%d uang=%d giliran=%d" % [_hb_pasang, s, _hb_jumlah_petak(s), nilai, p.daftar_pemain[s].uang, jumlah_giliran])

func _hb_jumlah_petak(s: int) -> int:
	var n = 0
	for i in range(p.rute_papan.size()):
		if p.pemilik_petak[i] == s: n += 1
	return n

func _langkah_main(delta) -> void:
	detik_diam += delta
	var teks = p.teks_dadu.text
	if teks != teks_terakhir:
		teks_terakhir = teks
		jejak.append("T|" + teks.replace("\n", " / "))
		detik_diam = 0.0
	if not _nama_dicatat:
		_nama_dicatat = true
		_catat_profil_nama("awal")
	var sig_event = "%d|%s|%s" % [p.ronde_event, p.event_aktif, p.event_terakhir]
	if sig_event != _sig_event:
		_sig_event = sig_event
		_catat("EVENT ronde=%d aktif=%s terakhir=%s" % [p.ronde_event, p.event_aktif, p.event_terakhir])
	var sig_bantuan = "%s|%s" % [str(p.statistik_slot.map(func(st): return int(st.get("kartu_bantuan", 0)))), str(p.daftar_pemain.map(func(d): return d.inventaris_kartu.map(func(c): return str(c.get("id", "?")))))]
	if sig_bantuan != _sig_bantuan:
		_sig_bantuan = sig_bantuan
		_catat("KARTU_BANTUAN stat=%s inv=%s" % [str(p.statistik_slot.map(func(st): return int(st.get("kartu_bantuan", 0)))), str(p.daftar_pemain.map(func(d): return d.inventaris_kartu.map(func(c): return str(c.get("id", "?")))))])
	var sig_bounty = "%s|%s|%s" % [p.bounty_elemen, p.bounty_terakhir, str(p.daftar_pemain.map(func(d): return d.bintang))]
	if sig_bounty != _sig_bounty:
		_sig_bounty = sig_bounty
		_catat("BOUNTY aktif=%s terakhir=%s bintang=%s stat_bounty=%s" % [p.bounty_elemen, p.bounty_terakhir,
			str(p.daftar_pemain.map(func(d): return d.bintang)), str(p.statistik_slot.map(func(st): return int(st.get("bounty", 0))))])
	_urus_hutang_habis(func(t): _catat(t))
	if p.giliran_sekarang != giliran_terakhir:
		giliran_terakhir = p.giliran_sekarang
		jumlah_giliran += 1
		detik_diam = 0.0
		jejak.append("G%d|%s|%s" % [jumlah_giliran, p.giliran_sekarang, _ringkas()])
		if sudah_putus:
			giliran_setelah_putus += 1
		_mungkin_keluar()
		if selesai: return
		if _pengecek() and jumlah_giliran > batas_giliran and not menunggu_cek and panel_migrasi_sejak < 0:
			tahap = "akhir"
			if StatusJaringan.peran_multiplayer == "host":
				rpc("rpc_uji_selesai")
			await get_tree().create_timer(1.0).timeout
			_akhiri("BATAS_GILIRAN")
			return
		if peran != "host" and sudah_putus and giliran_setelah_putus > 12:
			_akhiri("LANJUT_SETELAH_HOST_KELUAR")
			return
	if p.get("_permainan_selesai"):
		tahap = "akhir"
		_catat_akhir()
		if StatusJaringan.peran_multiplayer == "host":
			# Beri waktu client menampilkan layar akhirnya sendiri (replay, iklan stub).
			await get_tree().create_timer(6.0).timeout
			rpc("rpc_uji_selesai")
		await get_tree().create_timer(10.0 if skenario == "respect" else 2.0).timeout
		_akhiri("MENANG")
		return
	if detik_diam > 150.0:
		_catat("MACET: teks='%s' giliran=%s fase=%s menu=%s slot_ui=%d" % [p.teks_dadu.text, p.giliran_sekarang, p.fase_giliran, str(p.menu_aksi.visible), p.slot_giliran_ui])
		_akhiri("MACET")
		return
	# Panel migrasi host (HOST LEFT / host baru / CONNECTION LOST)
	if p._migrasi_berjalan or p._mode_jaringan_putus:
		_urus_panel_migrasi()
		return
	if panel_migrasi_sejak >= 0:
		panel_migrasi_sejak = -1.0
		host_migrasi_sejak = -1.0
		_sudah_tekan_host = false
		migrasi_selesai += 1
		giliran_saat_migrasi = jumlah_giliran
		var kontrol = []
		for d in p.daftar_pemain:
			kontrol.append(DataPemain.JenisKontrol.keys()[d.jenis_kontrol])
		_catat("MIGRASI_SELESAI jaringan=%s slot_lokal=%d kontrol=%s teks='%s'" % [StatusJaringan.peran_multiplayer, p.slot_lokal, str(kontrol), p.teks_dadu.text])
	# Panel OPPONENT LEFT (skenario host keluar / client keluar terakhir)
	if _klik_teks("CONTINUE VS AI"):
		_catat("KLIK CONTINUE VS AI")
		sudah_putus = true
		return
	_amati_duel()
	if tebak_uji:
		_urus_tebak()
	# Skenario keluar TEPAT saat device ini (peserta duel) sedang memilih elemen --
	# sebelum sempat mengklik (robot baru mengklik setelah "berpikir" 3 dtk).
	var keluar_duel = (skenario == "client_keluar_duel" and peran == "client" and urut == urut_keluar) or ((skenario == "host_keluar_duel" or skenario == "host_keluar_duel_migrasi") and peran == "host")
	if keluar_duel and jumlah_giliran >= 2 and ui.visible and ui.fase_duel == "PILIH_PEMAIN" and not ui.mode_tonton:
		_catat("SKENARIO: %s%s keluar paksa saat PILIH ELEMEN duel (giliran %d)" % [peran, str(urut) if peran == "client" else "", jumlah_giliran])
		_keluar_paksa()
		return
	if menunggu_cek:
		_proses_cek(delta)
		return
	_robot()

func _urus_panel_migrasi() -> void:
	# Menekan tombol panel migrasi seperti pemain sungguhan (lihat daftar skenario).
	if panel_migrasi_sejak < 0:
		panel_migrasi_sejak = detik_total
		menunggu_cek = false # cek yang sedang berjalan batal: jaringannya berganti
		_catat("PANEL_MIGRASI giliran=%d peran_migrasi=%s putus=%s" % [jumlah_giliran, p._peran_migrasi, str(p._mode_jaringan_putus)])
	var lama = detik_total - panel_migrasi_sejak
	var pm = p._peran_migrasi
	var sig = "%s|%s|%s" % [pm, str(p._mode_jaringan_putus), p._status_migrasi_khusus]
	if sig != _sig_migrasi:
		_sig_migrasi = sig
		_catat("MIGRASI %s t=%.1f" % [sig, lama])
	if pm == "host" or pm == "host_lama":
		if host_migrasi_sejak < 0:
			host_migrasi_sejak = detik_total
		var semua_kembali = true
		for s in range(p.jumlah_pemain()):
			var d = p.daftar_pemain[s]
			if s != p.slot_lokal and s != p._slot_host_lama and d.jenis_kontrol == DataPemain.JenisKontrol.MANUSIA_JARINGAN and not multiplayer.get_peers().has(d.id_jaringan):
				semua_kembali = false
		if (semua_kembali and detik_total - host_migrasi_sejak >= 1.0) or detik_total - host_migrasi_sejak >= 20.0:
			var peers_saat_ini = str(multiplayer.get_peers())
			if _klik_teks("START NOW"):
				_catat("KLIK START NOW (semua_kembali=%s peer=%s)" % [str(semua_kembali), peers_saat_ini])
		return
	host_migrasi_sejak = -1.0
	if pm == "tamat":
		if lama >= 1.0 and _klik_teks("PLAY ALONE VS AI"):
			_catat("KLIK PLAY ALONE VS AI (tamat)")
			sudah_putus = true
		return
	if p._mode_jaringan_putus:
		# P1: CONNECTION LOST
		var tunggu = 5.0 if skenario == "host_hotspot_mati" else (15.0 if skenario == "host_hotspot_telat" else -1.0)
		if tunggu < 0.0:
			if _klik_teks("PLAY ALONE VS AI"):
				_catat("KLIK PLAY ALONE VS AI (putus)")
				sudah_putus = true
		elif lama >= tunggu and _klik_teks("WAIT FOR PLAYERS"):
			_catat("KLIK WAIT FOR PLAYERS")
		return
	# CLIENT di panel HOST LEFT
	var tekan_host = false
	var main_sendiri = false
	if SKENARIO_MIGRASI.has(skenario):
		var calon = [p.slot_lokal]
		for s in range(p.jumlah_pemain()):
			if s != p.slot_lokal and s != p._slot_host_lama and p.daftar_pemain[s].jenis_kontrol == DataPemain.JenisKontrol.MANUSIA_JARINGAN:
				calon.append(s)
		if skenario == "migrasi_rebutan":
			tekan_host = urut <= 2
		elif skenario == "migrasi_sendiri" and urut == 3:
			main_sendiri = true
		else:
			tekan_host = p.slot_lokal == calon.min()
	elif skenario != "host_hotspot_mati":
		main_sendiri = true # skenario lama: perilaku lama (lanjut sendiri)
	if main_sendiri and lama >= (1.0 if SKENARIO_MIGRASI.has(skenario) else 0.0):
		if _klik_teks("PLAY ALONE VS AI"):
			_catat("KLIK PLAY ALONE VS AI")
			sudah_putus = true
		return
	# Rebutan: tekan juga saat sudah mulai menyambung -- supaya dua host benar-benar
	# berdiri bersamaan dan aturan mengalah (migrasi_host.gd) teruji.
	if tekan_host and (pm == "cari" or (pm == "gabung" and skenario == "migrasi_rebutan")) and lama >= 1.0 and not _sudah_tekan_host:
		_sudah_tekan_host = true
		if _klik_teks("BECOME HOST"):
			_catat("KLIK BECOME HOST")
		return
	if lama > 90.0 and _klik_teks("PLAY ALONE VS AI"):
		_catat("KLIK PLAY ALONE VS AI (terlalu lama menunggu)")
		sudah_putus = true

func _amati_duel() -> void:
	# Mencatat APA YANG TAMPIL di layar device ini selama duel / kartu, hanya
	# saat berubah: layar duel (fase, segel LOCKED musuh/pemain, judul), UI kartu
	# (pedang dll.), dan teks_dadu yang terkait duel/kartu.
	var bag = []
	if ui.visible:
		var judul = ui.teks_judul.text.replace("\n", " / ") if ui.teks_judul.visible else "-"
		bag.append("DUEL fase=%s segelM=%d segelP=%d tonton=%d judul='%s'" % [ui.fase_duel, int(ui.musuh_siap), int(ui.pemain_siap), int(ui.mode_tonton), judul])
	for pk in _semua_ui_kartu():
		if is_instance_valid(pk.kanvas_ui) and pk.kanvas_ui.is_inside_tree():
			var lbl = pk.kanvas_ui.find_children("*", "Label", true, false)
			var j = lbl[0].text.replace("\n", " / ") if lbl.size() > 0 else "?"
			var ada_pedang = pk._pedang_tombol.size() > 0 or is_instance_valid(pk._pedang_tombol_batal)
			if ada_pedang:
				bag.append("KARTU_UI pedang=%d judul='%s'" % [pk._pedang_tombol.size(), j])
			else:
				# Bukan tawaran pedang -- ini animasi putar_animasi_pakai_kartu
				# (label ke-2 = teks target, kalau sudah dibalik ke muka kartu).
				var t = lbl[1].text.replace("\n", " / ") if lbl.size() > 1 else "?"
				var tombol = pk.kanvas_ui.find_children("*", "Button", true, false)
				var isi = []
				for b in tombol:
					if b.is_queued_for_deletion() or b.scale.x < 0.05: continue
					var gs = b.get_theme_stylebox("disabled")
					var emas = gs is StyleBoxFlat and gs.bg_color.r > 0.85
					isi.append(b.text.get_slice("\n", 0) + ("*" if emas else ""))
				var cam = p._slot_dari_model(p.target_kamera) if p.target_kamera is Node3D else -1
				bag.append("ANIMASI_KARTU judul='%s' target='%s' a_target=%.1f a_latar=%.2f kartu=%s kamera=P%d" % [j, t, lbl[1].modulate.a if lbl.size() > 1 else 0.0, pk._pakai_overlay.color.a if is_instance_valid(pk._pakai_overlay) else -1.0, ",".join(isi), cam + 1])
	var teks = p.teks_dadu.text
	var terkait = false
	for kata in ["Sword", "SWORD", "DUEL", "card", "Card", "LOW ROLL", "HIGH ROLL", "Shield", "COIN", "coin", "TIE"]:
		if kata in teks: terkait = true
	if p.teks_dadu.visible and terkait:
		bag.append("TEKS='%s'" % teks.replace("\n", " / "))
	var sig = " | ".join(bag)
	if sig != _sig_duel:
		_sig_duel = sig
		jejak.append("D|%.1f|%s" % [detik_total, sig if sig != "" else "(kosong)"])

func _urus_tebak() -> void:
	# Fase 5 G4 (rig-only): robot penonton. Pada device yang menonton, menebak ~0.6 dtk
	# setelah tombol muncul (atau, mode telat, mengetuk sesudah jendela tutup), lalu
	# saat duel selesai (duel_menang slot mana pun naik di state device INI) mencocokkan
	# stat tebak_benar & teks hasil dengan pemenang sebenarnya.
	var telat_robot = tebak_telat_uji and (urut % 2 == 0) and peran == "client"
	var tb = ui.tombol_tebak_p
	if not telat_robot and tb.is_visible_in_tree():
		if _tebak_sejak < 0.0:
			_tebak_sejak = detik_total
		if detik_total - _tebak_sejak >= 0.6:
			_tebak_sejak = -1.0
			var pakai_p = (_tebak_n % 2 == 0)
			_tebak_n += 1
			_tebak_menunggu = p._duel_slot_penyerang if pakai_p else p._duel_slot_pembela
			_tebak_total += 1
			_catat("TEBAK_PILIH slot=%d tebak=%d penyerang=%d pembela=%d nomor=%d" % [p.slot_lokal, _tebak_menunggu, p._duel_slot_penyerang, p._duel_slot_pembela, p._tebak_nomor_lokal])
			(ui.tombol_tebak_p if pakai_p else ui.tombol_tebak_m).pressed.emit()
	elif not tb.is_visible_in_tree():
		_tebak_sejak = -1.0
	if telat_robot and p._tebak_nomor_lokal >= 0 and p._tebak_nomor_lokal != _tebak_telat_nomor and ui.visible and ui.tebak_sisi == "" \
			and ui.fase_duel not in ["PILIH_PEMAIN", "MENUNGGU_MUSUH"] and not tb.is_visible_in_tree():
		# Jendela sudah tutup (jalankan_duel berjalan di layar ini): ketukan "dalam perjalanan".
		_tebak_telat_nomor = p._tebak_nomor_lokal
		_tebak_telat_kirim += 1
		_tebak_menunggu = -1
		_catat("TEBAK_TELAT_KIRIM slot=%d nomor=%d fase=%s" % [p.slot_lokal, _tebak_telat_nomor, ui.fase_duel])
		ui._on_tombol_tebak_ditekan("pemain")
	var sig_ui = "%d|%s" % [int(ui.teks_tebak.visible), ui.teks_tebak.text]
	if sig_ui != _sig_tebak_ui:
		_sig_tebak_ui = sig_ui
		if ui.teks_tebak.visible:
			_catat("TEBAK_UI '%s'" % ui.teks_tebak.text)
			if ui.teks_tebak.text.begins_with("Good") or ui.teks_tebak.text.begins_with("Wrong"):
				_tebak_ui_hasil = ui.teks_tebak.text
			elif ui.teks_tebak.text == "Too late!":
				_tebak_menunggu = -1
				_tebak_telat_ditolak += 1
	var benar_per_slot: Array = p.statistik_slot.map(func(st): return int(st.get("tebak_benar", 0)))
	var sig_stat = str(benar_per_slot)
	if sig_stat != _sig_tebak_stat:
		_sig_tebak_stat = sig_stat
		_catat("TEBAK_STAT tebak_benar_per_slot=%s" % sig_stat)
	var menang_kini: Array = p.statistik_slot.map(func(st): return int(st.get("duel_menang", 0)))
	var benar_kini = int(benar_per_slot[p.slot_lokal])
	if _tebak_menang_prev.size() == menang_kini.size():
		for s in range(menang_kini.size()):
			if menang_kini[s] > _tebak_menang_prev[s]:
				if _tebak_menunggu >= 0:
					var benar_harap = (s == _tebak_menunggu)
					var ui_harap = "Good guess!" if benar_harap else "Wrong guess."
					var cek = (benar_kini - _tebak_benar_prev == (1 if benar_harap else 0)) and _tebak_ui_hasil == ui_harap
					if cek: _tebak_cek_ok += 1
					else: _tebak_cek_gagal += 1
					if benar_harap: _tebak_benar_total += 1
					_catat("TEBAK_CEK slot=%d tebak=%d menang=%d benar_diharap=%s stat_naik=%d ui='%s' cek=%s" % [p.slot_lokal, _tebak_menunggu, s, str(benar_harap), benar_kini - _tebak_benar_prev, _tebak_ui_hasil, "OK" if cek else "GAGAL"])
				elif benar_kini > _tebak_benar_prev:
					_tebak_cek_gagal += 1
					_catat("TEBAK_CEK slot=%d tanpa tebakan tapi stat naik GAGAL" % p.slot_lokal)
				_tebak_menunggu = -1
				_tebak_ui_hasil = ""
	_tebak_menang_prev = menang_kini
	_tebak_benar_prev = benar_kini

func _ringkas() -> String:
	var s = ""
	for d in p.daftar_pemain:
		s += "[%d,%d,%d]" % [d.posisi_saat_ini, d.uang, d.bintang]
	return s

func _mungkin_keluar() -> void:
	if skenario == "client_keluar" and peran == "client" and urut == urut_keluar and jumlah_giliran == giliran_keluar:
		_catat("SKENARIO: client%d keluar paksa di giliran %d" % [urut, jumlah_giliran])
		_keluar_paksa()
	if SKENARIO_HOST_KELUAR.has(skenario) and peran == "host" and jumlah_giliran == giliran_keluar:
		_catat("SKENARIO: host keluar paksa di giliran %d" % jumlah_giliran)
		_keluar_paksa()
	if skenario.begins_with("host_hotspot") and peran == "host" and jumlah_giliran == giliran_keluar:
		# Jaringan host hilang: semua client diputus, proses host TETAP hidup.
		_catat("SKENARIO: jaringan host putus di giliran %d (peer=%s)" % [jumlah_giliran, str(multiplayer.get_peers())])
		for id in multiplayer.get_peers():
			multiplayer.multiplayer_peer.disconnect_peer(id)
	if skenario == "migrasi_dua_kali" and peran == "client" and StatusJaringan.peran_multiplayer == "host" and migrasi_selesai == 1 and giliran_saat_migrasi >= 0 and jumlah_giliran - giliran_saat_migrasi == 8:
		_catat("SKENARIO: host baru (client%d) keluar paksa di giliran %d" % [urut, jumlah_giliran])
		_keluar_paksa()

func _keluar_paksa() -> void:
	# Seperti aplikasi ditutup: koneksi diputus lalu proses berhenti.
	tahap = "akhir"
	selesai = true
	_tulis_log()
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
	await get_tree().create_timer(0.3).timeout
	get_tree().quit()

# ---------------------------------------------------------------- potret & cek sinkron
func _potret() -> Dictionary:
	var s = {}
	var pem = []
	for d in p.daftar_pemain:
		# Fase 4 A7: role ikut dibandingkan -- role_slot dikirim SEKALI saat START
		# (layar_local_play.gd _bangun_role_slot), jadi kalau beda di sini berarti
		# ada device yang salah membaca StatusJaringan.role_slot-nya sendiri.
		# C8 (B-c, 26-09): + build (C2) + 7 field C3 (guard_terpakai dkk) --
		# supaya cek_gagal juga menangkap kalau salah satu device gagal
		# menyiarkan/menerapkan salah satu dari itu (bukan cuma 7 field lama).
		pem.append([d.posisi_saat_ini, d.uang, d.bintang, d.sisa_gelembung, d.sisa_paralisis, d.sisa_bakar, d.role,
			d.build, d.guard_terpakai, d.sacred_terpakai, d.bakar_per_giliran, d.bakar_pemilik,
			d.bakar_larang_jebakan, d.kunci_kartu, d.low_roll_bubble])
	s["pemain"] = pem
	var kartu = []
	for d in p.daftar_pemain:
		var ids = []
		for k in d.inventaris_kartu:
			ids.append(str(k.get("id", "?")))
		kartu.append(ids)
	s["kartu"] = kartu
	var gems = []
	for i in range(p.jumlah_pemain()):
		var g = Array(p.koleksi_permata_slot[i])
		g.sort()
		gems.append(g)
	s["permata"] = gems
	s["pemilik"] = Array(p.pemilik_petak)
	s["milik"] = Array(p.status_kepemilikan_petak)
	s["menara"] = Array(p.level_menara_petak)
	s["nyawa"] = Array(p.nyawa_petak)
	var jb = []
	for i in range(p.rute_papan.size()):
		for anak in p.rute_papan[i].get_children():
			var nm = String(anak.name)
			if (nm.begins_with("Jebakan") or nm.begins_with("KoinTercecer")) and not anak.is_queued_for_deletion():
				# C8 (B-c, 26-09): + ambil_info() (C4) -- KoinTercecer tidak punya
				# metode ini (has_method dijaga), 5 jenis jebakan semua punya.
				var info_jb = anak.ambil_info() if anak.has_method("ambil_info") else {}
				jb.append("%d:%s:%s:%s" % [i, nm, str(anak.get("pemilik")), str(info_jb)])
	jb.sort()
	s["jebakan"] = jb
	s["giliran"] = p.giliran_sekarang
	s["ronde"] = p.get("ronde_sekarang")
	s["event"] = [p.ronde_event, p.event_aktif, p.event_terakhir]
	s["bounty"] = [p.bounty_elemen, p.bounty_terakhir]
	s["dadu"] = [p.tipe_dadu_slot.slice(0, p.jumlah_pemain()), p.sisa_durasi_dadu_slot.slice(0, p.jumlah_pemain())]
	s["kontrol"] = []
	for d in p.daftar_pemain:
		s["kontrol"].append(1 if d.jenis_kontrol == DataPemain.JenisKontrol.AI else 0)
	return s

func _mulai_cek() -> void:
	nomor_cek += 1
	menunggu_cek = true
	waktu_cek = 0.0
	balasan.clear()
	potret_host = _potret()
	rpc("rpc_minta_potret", nomor_cek)

func _proses_cek(delta) -> void:
	waktu_cek += delta
	var peers = p._peer_client_aktif()
	var lengkap = true
	for id in peers:
		if not balasan.has(id):
			lengkap = false
	if not lengkap and waktu_cek < 25.0:
		return
	menunggu_cek = false
	for id in peers:
		if not balasan.has(id):
			cek_gagal += 1
			_catat("CEK#%d GAGAL: client %d tidak membalas" % [nomor_cek, id])
			continue
		var beda = []
		for k in potret_host.keys():
			var nilai_c = balasan[id].get(k)
			if k == "kontrol":
				continue
			if k == "kartu" and str(potret_host[k]) != str(nilai_c):
				kartu_beda += 1
			if str(potret_host[k]) != str(nilai_c):
				beda.append("%s host=%s client=%s" % [k, str(potret_host[k]), str(nilai_c)])
		if beda.is_empty():
			cek_ok += 1
			if migrasi_selesai > 0:
				cek_ok_migrasi += 1
		else:
			cek_gagal += 1
			_catat("CEK#%d BEDA dgn client %d (slot %d): %s" % [nomor_cek, id, p._slot_dari_peer(id), " || ".join(beda)])

@rpc("authority", "call_remote", "reliable")
func rpc_minta_potret(nomor: int) -> void:
	# CLIENT: tunggu sebentar supaya animasi/replay yang masih berjalan selesai.
	await get_tree().create_timer(3.0).timeout
	if p == null or selesai: return
	if StatusJaringan.peran_multiplayer != "client" or p._migrasi_berjalan: return
	rpc_id(1, "rpc_kirim_potret", nomor, _potret())

@rpc("any_peer", "call_remote", "reliable")
func rpc_kirim_potret(nomor: int, data: Dictionary) -> void:
	if nomor != nomor_cek: return
	balasan[multiplayer.get_remote_sender_id()] = data

@rpc("authority", "call_remote", "reliable")
func rpc_uji_selesai() -> void:
	# Kabar akhir sudah tiba tapi layar akhir belum tampil (replay masih diputar):
	# tunggu dulu supaya baris AKHIR tercatat (maks 20 dtk).
	var t = 0.0
	while p != null and p.get("_akhir_diterima") and not p.get("_permainan_selesai") and t < 20.0:
		await get_tree().process_frame
		t += get_process_delta_time()
	if p != null and p.get("_permainan_selesai"):
		_catat_akhir()
	await get_tree().create_timer(0.5).timeout
	_akhiri("HOST_SELESAI")

func _catat_akhir() -> void:
	# Satu baris yang HARUS sama persis di semua HP satu permainan.
	if _akhir_dicatat or p == null:
		return
	_akhir_dicatat = true
	_catat_profil_nama("akhir")
	_catat("AKHIR alasan=%s pemenang=%d ronde=%d/%d papan=%s" % [p._alasan_akhir, p._slot_pemenang_akhir, p.ronde_sekarang, p.batas_ronde, str(p._papan_skor_akhir)])
	_cek_profil_mp()
	_catat("MVP_UJI slot_mvp=%d saya=%s mvp_total=%d" % [ProfilPemain.hitung_mvp(p._papan_skor_akhir), str(ProfilPemain.hitung_mvp(p._papan_skor_akhir) == p.slot_lokal), ProfilPemain.mvp_total])
	if skenario == "respect":
		_respect_uji()

func _respect_uji() -> void:
	# Fase 6 G2 (rig-only, skenario "respect"): tiap HP memberi Respect SEKALI ke tiap lawan MANUSIA, lalu mencoba kirim ganda
	# (penjaga lokal + paksa lewat RPC / _host_proses_respect). Harapan: respect saya naik TEPAT sebanyak lawan manusia (1 per lawan),
	# AI / diri sendiri ditolak.
	var awal = respect_awal_uji
	var manusia = []
	var ditolak_benar = true
	for s in range(p.jumlah_pemain()):
		if s == p.slot_lokal:
			continue
		if p.bisa_beri_respect(s):
			manusia.append(s)
		elif p.kirim_respect(s):
			ditolak_benar = false # AI / bukan manusia tidak boleh bisa dikirimi
	var rinci = []
	for s in manusia:
		var pertama = p.kirim_respect(s)
		var kedua_lokal = p.kirim_respect(s)
		if StatusJaringan.peran_multiplayer == "host":
			var kedua_host = p._host_proses_respect(p.slot_lokal, s)
			rinci.append("%d:%s/%s/%s" % [s, str(pertama), str(kedua_lokal), str(kedua_host)])
		else:
			p.rpc_id(1, "rpc_zrespect_kirim", s) # kirim ganda PAKSA (melewati penjaga lokal) -- host harus menolak
			rinci.append("%d:%s/%s/paksa" % [s, str(pertama), str(kedua_lokal)])
	var diri = p.kirim_respect(p.slot_lokal)
	if StatusJaringan.peran_multiplayer == "host":
		diri = diri or p._host_proses_respect(p.slot_lokal, p.slot_lokal)
	# Client lain bisa mencapai layar akhirnya beberapa detik lebih lambat -> tunggu sampai semua Respect tiba (maks 7 dtk).
	var t = 0.0
	while t < 7.0 and ProfilPemain.respect - awal < manusia.size():
		await get_tree().create_timer(0.25).timeout
		t += 0.25
	await get_tree().create_timer(1.0).timeout # sisa waktu: kiriman berlebih (kalau ada) sempat tiba
	var akhir = ProfilPemain.respect
	var ok = (akhir - awal == manusia.size()) and ditolak_benar and not diri
	_catat("RESPECT_UJI slot=%d lawan_manusia=%s kirim=%s diri_ditolak=%s ai_ditolak=%s respect %d->%d diharapkan=+%d cek=%s" % [p.slot_lokal, str(manusia), str(rinci), str(not diri), str(ditolak_benar), awal, akhir, manusia.size(), "OK" if ok else "GAGAL"])

func _catat_profil_nama(kapan: String) -> void:
	# Fase 6: nama/level tiap slot menurut HP ini -- HARUS sama di semua HP (dan tetap sama sesudah migrasi host).
	var nm = []
	for s in range(p.jumlah_pemain()):
		nm.append("%s/%s/%s" % [p._nama_manusia(s), p._nama_manusia(s, true), UiProfil.nama_slot_papan(p, s)])
	_catat("PROFIL_NAMA %s slot_lokal=%d profil_slot=%s tampil=%s" % [kapan, p.slot_lokal, str(StatusJaringan.profil_slot), str(nm)])
	# Fase 7 G3: kosmetik tiap slot menurut HP ini (HARUS sama di semua HP, juga sesudah migrasi) + warna trim/badan model nyata.
	var ko = []
	for s in range(p.jumlah_pemain()):
		var k: Dictionary = p._kosmetik_slot(s)
		var trim = "-"
		var badan = "-"
		if s < p.daftar_model.size():
			for m in (p.daftar_model[s] as Node).find_children("*", "MeshInstance3D", true, false):
				var c: Color = (m as MeshInstance3D).get_active_material(0).albedo_color
				if m.name == "Kaki": # model uji beras_uji.tscn: Kaki = sepatu (trim), Badan = badan
					trim = c.to_html(false)
				elif m.name == "Badan":
					badan = c.to_html(false)
		ko.append("%s/%s/%s/gelar=%s/trim=%s/badan=%s" % [k["pawn"], k["title"], k["frame"], p._gelar_manusia(s), trim, badan])
	_catat("KOSMETIK_UJI %s slot_lokal=%d %s" % [kapan, p.slot_lokal, str(ko)])

func _cek_profil_mp() -> void:
	# Fase 2: tiap HP mencatat hadiah untuk slot_lokal-nya sendiri, TEPAT sekali (juga sesudah migrasi).
	var r: Dictionary = p._ringkasan_hadiah
	var baris_lokal = {}
	for b in p._papan_skor_akhir:
		if int(b["slot"]) == p.slot_lokal:
			baris_lokal = b
	var st = baris_lokal.get("stat", {})
	var peng = baris_lokal.get("penghargaan", [])
	var menang = p._slot_pemenang_akhir == p.slot_lokal
	var pengali = (1.0 if p.mode_quick else 1.6) * (1.5 if menang else 1.0)
	var ok_rumus = not r.is_empty() and r["xp_match"] == roundi(5 * int(st.get("giliran", 0)) * pengali) and r["crowns_match"] == roundi(2 * int(st.get("giliran", 0)) * pengali) and r["xp_penghargaan"] == 15 * peng.size() and r["crowns_penghargaan"] == 10 * peng.size()
	var xp_tambah = int(r.get("xp_match", 0)) + int(r.get("xp_penghargaan", 0)) + int(r.get("xp_misi", 0)) + int(r.get("xp_tebak", 0))
	var cr_tambah = int(r.get("crowns_match", 0)) + int(r.get("crowns_penghargaan", 0)) + int(r.get("crowns_misi", 0)) + int(r.get("crowns_tebak", 0)) + int(r.get("crowns_naik_level", 0))
	var ok_sekali = ProfilPemain.xp_total == _xp0 + xp_tambah and ProfilPemain.crowns == _cr0 + cr_tambah
	# Fase 5 G7: hadiah Tebak Duel = 5 XP / 3 Crowns per tebakan benar (maks 5) dari stat tebak_benar slot ini (identik di semua HP).
	var tebak_stat = int(st.get("tebak_benar", 0))
	var ok_tebak = int(r.get("xp_tebak", -1)) == 5 * mini(tebak_stat, 5) and int(r.get("crowns_tebak", -1)) == 3 * mini(tebak_stat, 5) and int(ProfilPemain.statistik.get("tebak_benar", 0)) == tebak_stat
	_catat("TEBAK_HADIAH_MP slot=%d tebak_benar_stat=%d xp_tebak=%d crowns_tebak=%d stat_seumur=%d cek=%s" % [p.slot_lokal, tebak_stat, int(r.get("xp_tebak", -1)), int(r.get("crowns_tebak", -1)), int(ProfilPemain.statistik.get("tebak_benar", 0)), "OK" if ok_tebak else "GAGAL"])
	var c = ConfigFile.new()
	var ok_berkas = c.load(ProfilPemain.BERKAS) == OK and int(c.get_value("profil", "xp", -1)) == ProfilPemain.xp_total
	var ok = ok_rumus and ok_sekali and ok_berkas and int(st.get("giliran", 0)) > 0
	_catat("PROFIL_MP slot=%d menang=%s giliran=%d xp %d->%d crowns %d->%d penghargaan=%s rumus=%s sekali=%s berkas=%s cek=%s" % [p.slot_lokal, str(menang), int(st.get("giliran", 0)), _xp0, ProfilPemain.xp_total, _cr0, ProfilPemain.crowns, str(peng), str(ok_rumus), str(ok_sekali), str(ok_berkas), "OK" if ok else "GAGAL"])

# ---------------------------------------------------------------- robot pemain lokal
func _ada_kartu_pakai() -> bool:
	for k in p.daftar_pemain[p.slot_lokal].inventaris_kartu:
		if not str(k.get("id", "")).begins_with("pedang"):
			return true
	return false

func _semua_ui_kartu() -> Array:
	var hasil = []
	for n in get_tree().root.find_children("*", "Node3D", true, false):
		if n.get_script() == preload("res://petak_kartu.gd"):
			hasil.append(n)
	return hasil

func _robot() -> void:
	# 1. Duel: pilih elemen (ketuk dua kali = konfirmasi) -- setelah "berpikir" 3 dtk
	if ui.visible and ui.fase_duel == "PILIH_PEMAIN":
		if _pilih_elemen_sejak < 0.0:
			_pilih_elemen_sejak = detik_total
		var el = ["api", "air", "angin", "tanah", "petir"][hitung_aksi % 5]
		if bounty_pilih and p.bounty_elemen != "":
			el = p.bounty_elemen
		var t = ui.tombol_elemen[el]
		if not t.disabled and t.is_visible_in_tree() and detik_total - _pilih_elemen_sejak >= 3.0:
			_pilih_elemen_sejak = -1.0
			hitung_aksi += 1
			jejak.append("R|elemen|" + el)
			t.pressed.emit(); t.pressed.emit()
			return
	# 2. Lempar koin penentu seri
	if ui.tombol_kepala.is_visible_in_tree():
		if _koin_sejak < 0.0:
			_koin_sejak = detik_total
		var b = ui.tombol_kepala if not ui.tombol_kepala.disabled else ui.tombol_ekor
		if not b.disabled and detik_total - _koin_sejak >= 1.5:
			_koin_sejak = -1.0
			hitung_aksi += 1
			jejak.append("R|koin")
			b.pressed.emit()
			return
	# 3. Layar kartu (gacha / buang / pedang) yang bisa diklik
	for pk in _semua_ui_kartu():
		if pk._gacha_tombol.size() > 0 and not pk._kartu_sudah_dibuka and is_instance_valid(pk._gacha_tombol[0]) and not pk._gacha_tombol[0].disabled:
			hitung_aksi += 1
			jejak.append("R|gacha|%d" % (hitung_aksi % 3))
			pk._gacha_tombol[hitung_aksi % 3].pressed.emit()
			return
		if pk._buang_tombol.size() > 0 and not pk._buang_sudah_dipilih and is_instance_valid(pk._buang_tombol[0]) and not pk._buang_tombol[0].disabled:
			hitung_aksi += 1
			jejak.append("R|buang")
			pk._buang_tombol[0].pressed.emit()
			return
		if pk._pedang_tombol.size() > 0 and not pk._pedang_sudah_dipilih and is_instance_valid(pk._pedang_tombol[0]) and not pk._pedang_tombol[0].disabled:
			hitung_aksi += 1
			if hitung_aksi % 2 == 0:
				jejak.append("R|pedang|0")
				pk._pedang_tombol[0].pressed.emit()
			else:
				jejak.append("R|pedang|simpan")
				pk._pedang_tombol_batal.pressed.emit()
			return
	# 3b. Layar "YOUR CARDS" (Use Card) & pilih target kartu dadu
	for b in _semua_tombol():
		if not b.is_visible_in_tree() or b.disabled:
			continue
		var t = b.text
		if t.begins_with("LOW ROLL") or t.begins_with("HIGH ROLL") or t.begins_with("SHIELD"):
			hitung_aksi += 1
			jejak.append("R|pilih_kartu|" + t.get_slice("\n", 0))
			_catat("PAKAI_KARTU slot=%d kartu=%s" % [p.slot_lokal, t.get_slice("\n", 0)])
			b.pressed.emit()
			return
	var target_kartu = []
	for b in _semua_tombol():
		if b.is_visible_in_tree() and not b.disabled and b.text.begins_with("Use on "):
			target_kartu.append(b)
	if target_kartu.size() > 0:
		hitung_aksi += 1
		var pilih = target_kartu[mini(1, target_kartu.size() - 1)] # lawan pertama
		jejak.append("R|target_kartu|" + pilih.text)
		_catat("TARGET_KARTU slot=%d %s" % [p.slot_lokal, pilih.text])
		pilih.pressed.emit()
		return
	# 4. Persimpangan
	if is_instance_valid(p.panel_ui_cabang) and p.panel_ui_cabang.visible:
		var tombol = []
		for t in p.wadah_tombol_cabang.get_children():
			if t is Button and not t.disabled and t.visible and not t.is_queued_for_deletion(): tombol.append(t)
		if tombol.size() > 0:
			hitung_aksi += 1
			jejak.append("R|cabang|%d" % (hitung_aksi % tombol.size()))
			tombol[hitung_aksi % tombol.size()].pressed.emit()
		return
	# 5. Jual aset karena hutang
	if p.mode_jual_aset and p.mode_membidik and p.slot_jual_aset == p.slot_lokal:
		for i in range(p.rute_papan.size()):
			if p.pemilik_petak[i] == p.slot_lokal:
				hitung_aksi += 1
				jejak.append("R|jual|%d" % i)
				p._jual_petak(i)
				return
	# 6. Menu aksi -- satu aksi per pemanggilan periksa_status_petak
	if not p.menu_aksi.visible or p.slot_giliran_ui != p.slot_lokal:
		return
	if p.jumlah_periksa == periksa_terakhir:
		return
	# Host: cek sinkron dulu di awal giliran pemain host (papan sedang diam).
	if p.fase_giliran == "awal" and StatusJaringan.peran_multiplayer == "host" and not p._peer_client_aktif().is_empty():
		if periksa_dicek != p.jumlah_periksa:
			periksa_dicek = p.jumlah_periksa
			_mulai_cek()
			return
	periksa_terakhir = p.jumlah_periksa
	hitung_aksi += 1
	var d = p.daftar_pemain[p.slot_lokal]
	if p.fase_giliran == "konfrontasi":
		if not p.tombol_bangun.disabled and hitung_aksi % 2 == 0:
			jejak.append("R|lawan")
			p.tombol_bangun.pressed.emit()
		else:
			jejak.append("R|menyerah")
			p.tombol_beli.pressed.emit()
		return
	if p.fase_giliran == "awal":
		if p.tombol_gunakan_kartu and p.tombol_gunakan_kartu.visible and not p.tombol_gunakan_kartu.disabled and _ada_kartu_pakai() and hitung_aksi % 2 == 0:
			jejak.append("R|use_card")
			p.tombol_gunakan_kartu.pressed.emit()
			return
		if p.tombol_serang.visible and not p.tombol_serang.disabled and hitung_aksi % 3 == 0:
			for i in range(p.rute_papan.size()):
				if p.pemilik_petak[i] >= 0 and p.pemilik_petak[i] != p.slot_lokal:
					jejak.append("R|serang|%d" % i)
					p.tombol_serang.pressed.emit()
					p._serang_petak(i)
					return
		jejak.append("R|dadu")
		p.tombol_tutup.pressed.emit()
		return
	# fase akhir
	# C8 (B-c, 26-09) SEMENTARA -- gerbang frekuensi dilonggarkan (dulu hanya
	# 1 dari 4 aksi, hitung_aksi % 4 == 1) + tombol_trap_tanah ditambahkan ke
	# kandidat (dulu TIDAK PERNAH dicoba robot sama sekali) supaya match MP
	# rig menghasilkan CUKUP banyak jebakan terpasang & terpicu untuk
	# membuktikan jalur Tornado/Phoenix/Rock-Breaker-negasi (C5/C8). KEMBALIKAN
	# ke `d.bintang >= 2 and hitung_aksi % 4 == 1` + kandidat 4-elemen (tanpa
	# tanah) sebelum ZIP dikirim (pelajaran 14.12, sekali pakai).
	if p.tombol_set_trap.visible and not p.tombol_set_trap.disabled and d.bintang >= 2:
		p.tombol_set_trap.pressed.emit()
		# Fase 4 A3: tombol jebakan yang tidak dibawa role/roster sekarang
		# disembunyikan (.visible = _jebakan_boleh(...)), bukan cuma disabled --
		# robot HARUS ikut menyaring .visible juga, jangan lagi menekan tombol
		# tersembunyi secara bergiliran seperti sebelum Fase 4.
		var kandidat = []
		for b in [p.tombol_trap_air, p.tombol_trap_api, p.tombol_trap_angin, p.tombol_trap_petir, p.tombol_trap_tanah]:
			if b.visible and not b.disabled:
				kandidat.append(b)
		if not kandidat.is_empty():
			var jenis = kandidat[(hitung_aksi / 4) % kandidat.size()]
			jejak.append("R|jebakan|" + jenis.name)
			jenis.pressed.emit()
			return
		p.tombol_trap_batal.pressed.emit()
		return
	if p.tombol_beli.visible and not p.tombol_beli.disabled:
		jejak.append("R|beli")
		p.tombol_beli.pressed.emit()
		return
	if p.tombol_bangun.visible and not p.tombol_bangun.disabled:
		jejak.append("R|bangun")
		p.tombol_bangun.pressed.emit()
		return
	jejak.append("R|akhiri")
	p.tombol_tutup.pressed.emit()
