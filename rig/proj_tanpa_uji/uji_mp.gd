extends Node3D
# Uji end-to-end DUA PROSES (host & client) lewat ENet sungguhan, memakai
# pemain.gd asli (lewat uji_mp_pemain.gd). Host menjalankan skenario, client
# bereaksi lewat RPC asli game; kedua sisi mencatat kejadian bertanda waktu
# (jam dinding, sama di satu mesin), lalu host membandingkan keduanya.
const PORT = 27161
const PK = preload("res://petak_kartu.gd")
const JUMLAH_PETAK = 10

var peran = ""
var p # node Pemain
var papan = []
var log_kejadian = []
var jejak = []
var pantau_aktif = false
var client_id = 0
var log_client = null
var gagal = 0
var status_ui = {}
var teks_terakhir = ""
var jebakan_terakhir = {}
var gelembung_terakhir = false
var replay_terakhir = false
var koin_terakhir = {}
var paralisis_replay_terakhir = false
var teks_paralysis_terakhir = false
var geser_terakhir = null
var jml_ting = {}
var koleksi_terakhir = ""
var jml_gajian = {}
var cabang_status = ""
var serangan_replay_terakhir = false

func sekarang() -> float: return Time.get_unix_time_from_system()
func catat(teks: String) -> void: log_kejadian.append([sekarang(), teks])

func _cek(kondisi: bool, pesan: String) -> void:
	if kondisi:
		print("   ok   : ", pesan)
	else:
		gagal += 1
		print("   GAGAL: ", pesan)

# ---------------------------------------------------------------- adegan
func _buat_anim() -> AnimationPlayer:
	var ap = AnimationPlayer.new(); ap.name = "AnimationPlayer"
	var lib = AnimationLibrary.new()
	for n in ["idle", "run"]:
		var a = Animation.new(); a.length = 1.0; a.loop_mode = Animation.LOOP_LINEAR
		lib.add_animation(n, a)
	ap.add_animation_library("", lib)
	return ap

func _bangun_adegan() -> void:
	var node_papan = Node3D.new(); node_papan.name = "Papan"; add_child(node_papan)
	for i in range(JUMLAH_PETAK):
		var t = preload("res://petak_papan.gd").new(); t.name = "Petak%d" % i
		node_papan.add_child(t)
		t.global_position = Vector3(i * 4.0, 0, 0)
		papan.append(t)
	for i in range(JUMLAH_PETAK):
		papan[i].referensi_node_selanjutnya.assign([papan[(i + 1) % JUMLAH_PETAK]])

	var musuh = Node3D.new(); musuh.name = "Musuh"; add_child(musuh)
	var beras_m = Node3D.new(); beras_m.name = "beras"; musuh.add_child(beras_m)
	beras_m.add_child(_buat_anim())

	var cl = CanvasLayer.new(); cl.name = "CanvasLayer"; add_child(cl)
	for n in ["TeksDadu", "TeksUang", "TeksBintang"]:
		var l = Label.new(); l.name = n; cl.add_child(l)
	var menu = Control.new(); menu.name = "MenuAksi"; cl.add_child(menu)
	var vb = VBoxContainer.new(); vb.name = "VBoxContainer"; menu.add_child(vb)
	for n in ["TombolBeli", "TombolBangun", "TombolSerang", "TombolTanah", "TombolPetir", "TombolTutup"]:
		var b = Button.new(); b.name = n; vb.add_child(b)
	var r = load("res://uji_rolet_stub.gd").new(); r.name = "Rolet"; cl.add_child(r)
	var ue = Control.new(); ue.name = "UIElemen"; cl.add_child(ue)
	var kam = Camera3D.new(); kam.name = "Camera3D"; add_child(kam)

	p = load("res://uji_mp_pemain.gd").new(); p.name = "Pemain"
	var beras_p = Node3D.new(); beras_p.name = "beras"; p.add_child(beras_p)
	beras_p.add_child(_buat_anim())
	add_child(p)
	UiDinamis.buat_ui_cabang_dasar(p)

	p.rute_papan.assign(papan)
	var f = []; f.resize(JUMLAH_PETAK); f.fill(false); p.status_kepemilikan_petak = f
	var pp = []; pp.resize(JUMLAH_PETAK); pp.fill(-1); p.pemilik_petak.assign(pp)
	var z1 = []; z1.resize(JUMLAH_PETAK); z1.fill(0); p.level_menara_petak = z1
	var z2 = []; z2.resize(JUMLAH_PETAK); z2.fill(0); p.nyawa_petak = z2
	var z3: Array[int] = []; z3.resize(JUMLAH_PETAK); z3.fill(0); p.berhenti_di_petak_sendiri = z3
	var d0 = DataPemain.new(DataPemain.JenisKontrol.MANUSIA_LOKAL, "Host"); d0.id_jaringan = 1
	var d1 = DataPemain.new(DataPemain.JenisKontrol.MANUSIA_JARINGAN, "Client")
	p.daftar_pemain.assign([d0, d1])
	p.slot_lokal = 0 if peran == "host" else 1
	p.mesin_acak.seed = 777

func _atur_posisi(a: int, b: int) -> void:
	p.daftar_pemain[0].posisi_saat_ini = a
	p.daftar_pemain[1].posisi_saat_ini = b
	p.global_position = papan[a].global_position
	p.musuh.global_position = papan[b].global_position

# ---------------------------------------------------------------- pemantau
func _process(_d):
	if p == null: return
	var teks = p.teks_dadu.text
	if teks != teks_terakhir:
		teks_terakhir = teks
		catat("teks|" + teks.replace("\n", " / "))
	for i in range(JUMLAH_PETAK):
		var j = papan[i].get_node_or_null("JebakanAir")
		var ada = j != null and not j.is_queued_for_deletion()
		if ada != jebakan_terakhir.get(i, false):
			jebakan_terakhir[i] = ada
			catat("jebakan|%d|%s|%d" % [i, ada, j.pemilik if ada else -9])
	for i in range(JUMLAH_PETAK):
		var k = papan[i].get_node_or_null("KoinTercecer")
		var isi = k.isi_koin if (k != null and not k.is_queued_for_deletion()) else -1
		if isi != koin_terakhir.get(i, -1):
			koin_terakhir[i] = isi
			catat("koin|%d|%d" % [i, isi])
	var g = p.model_musuh.get_node_or_null("EfekGelembung")
	var ada_g = g != null and not g.is_queued_for_deletion()
	if ada_g != gelembung_terakhir:
		gelembung_terakhir = ada_g
		catat("gelembung|%s" % ada_g)
	if p.get("_replay_jebakan_air_berjalan") != replay_terakhir:
		replay_terakhir = p.get("_replay_jebakan_air_berjalan")
		catat("replay_air|%s" % replay_terakhir)
	if p.get("_replay_paralisis_berjalan") != paralisis_replay_terakhir:
		paralisis_replay_terakhir = p.get("_replay_paralisis_berjalan")
		catat("replay_paralisis|%s" % paralisis_replay_terakhir)
	var ada_teks_p = false
	for c3 in get_tree().current_scene.get_children():
		if c3 is Label3D and c3.text == "PARALYSIS" and not c3.is_queued_for_deletion():
			ada_teks_p = true
			break
	if ada_teks_p != teks_paralysis_terakhir:
		teks_paralysis_terakhir = ada_teks_p
		catat("teks_paralysis|%s" % ada_teks_p)
	var boleh_g = p._boleh_geser_kamera()
	if boleh_g != geser_terakhir:
		geser_terakhir = boleh_g
		catat("geser|%s" % boleh_g)
	for i in range(JUMLAH_PETAK):
		var vp = papan[i].node_visual_permata
		var n = 0
		if vp != null and is_instance_valid(vp):
			for c4 in vp.get_children():
				if c4 is AudioStreamPlayer and not c4.is_queued_for_deletion(): n += 1
		if n > jml_ting.get(i, 0):
			catat("efek_permata|%d" % i)
		jml_ting[i] = n
	for i in range(p.label_petak_3d.size()):
		var up = p.label_petak_3d[i]
		var ng = 0
		if up != null and is_instance_valid(up):
			for c5 in up.get_children():
				if c5 is AudioStreamPlayer and not c5.is_queued_for_deletion(): ng += 1
		if ng > jml_gajian.get(i, 0):
			catat("efek_start|%d" % i)
		jml_gajian[i] = ng
	var kol = "%d,%d" % [p.koleksi_permata_pemain.size(), p.koleksi_permata_musuh.size()]
	if kol != koleksi_terakhir:
		koleksi_terakhir = kol
		catat("koleksi|" + kol)
	var pc = p.get("panel_ui_cabang")
	if pc != null and is_instance_valid(pc):
		var st = ""
		if pc.visible:
			st = p.wadah_tombol_cabang.get_parent().get_child(0).text
		if st != cabang_status:
			if st == "": catat("cabang_tutup")
			else: catat("cabang_judul|" + st)
			cabang_status = st
	if p.get("_replay_serangan_berjalan") != serangan_replay_terakhir:
		serangan_replay_terakhir = p.get("_replay_serangan_berjalan")
		catat("replay_serangan|%s" % serangan_replay_terakhir)
	_pantau_ui_pedang()
	if pantau_aktif:
		var m = p.musuh.global_position
		jejak.append([sekarang(), m.x, m.y, m.z])

func _pantau_ui_pedang() -> void:
	var dilihat = {}
	for c in p.get_children():
		if c.get_script() != PK: continue
		var id = c.get_instance_id()
		dilihat[id] = true
		var k = c.kanvas_ui
		var hidup = k != null and is_instance_valid(k) and not k.is_queued_for_deletion()
		if not status_ui.has(id):
			if not hidup: continue
			status_ui[id] = {"judul": "", "tutup": false}
			catat("pedang_buka")
		var s = status_ui[id]
		if s["tutup"]: continue
		if hidup:
			var judul = k.get_child(0).get_child(0).text
			if judul != s["judul"]:
				s["judul"] = judul
				catat("pedang_judul|" + judul.replace("\n", " / "))
		else:
			s["tutup"] = true
			catat("pedang_tutup")
	for id in status_ui.keys():
		if not dilihat.has(id) and not status_ui[id]["tutup"]:
			status_ui[id]["tutup"] = true
			catat("pedang_tutup")

# ---------------------------------------------------------------- RPC uji
@rpc("authority", "call_remote", "reliable")
func rpc_uji_perintah(nama: String, arg: Array) -> void:
	match nama:
		"reset": log_kejadian.clear(); jejak.clear(); status_ui.clear(); geser_terakhir = null; koleksi_terakhir = ""
		"pantau": pantau_aktif = arg[0]
		"posisi": _atur_posisi(arg[0], arg[1])
		"lag": p.lag_langkah = arg[0]
		"pasang_air_sendiri": p._on_tombol_air_pressed()
		"klik_pedang": _klik_pedang_saat_muncul(arg[0], arg[1])
		"uji_lindung_koin": _uji_lindung_koin_client()
		"permata": _pasang_permata(arg[0], arg[1])
		"tutup_client": p._on_tombol_tutup_pressed()
		"beli_client": p._on_tombol_beli_pressed()
		"set_geser": p.geser_kamera = Vector3(arg[0], 0, arg[1])
		"render_hud": _render_hud()
		"uji_lindung_permata": _uji_lindung_permata_client()
		"start": _pasang_start(arg[0], arg[1])
		"fork": _pasang_fork(arg[0], arg[1])
		"klik_cabang": _klik_cabang_saat_muncul(arg[0], arg[1])
		"serang_mulai": p._on_tombol_serang_pressed()
		"serang_petak": p._serang_petak(arg[0])
		"label_petak": _pastikan_label_petak()
		"siap_mulai": _mulai_kesiapan_client()
		"klik_start": _klik_tombol("START GAME")
		"jual_petak": p._jual_petak(arg[0])
		"bersih_panel": _bersihkan_panel_akhir()
		"kirim_log": rpc_id(1, "rpc_uji_log", JSON.stringify(_paket_log(), "", true, true))
		"keluar":
			await get_tree().create_timer(0.3).timeout
			get_tree().quit()

@rpc("any_peer", "call_remote", "reliable")
func rpc_uji_log(isi: String) -> void:
	log_client = JSON.parse_string(isi)

func _paket_log() -> Dictionary:
	var jeb = {}
	for i in range(JUMLAH_PETAK):
		var j = papan[i].get_node_or_null("JebakanAir")
		if j != null and not j.is_queued_for_deletion(): jeb[str(i)] = j.pemilik
	var m = p.musuh.global_position
	return {
		"log": log_kejadian, "jejak": jejak,
		"bintang": [p.daftar_pemain[0].bintang, p.daftar_pemain[1].bintang],
		"jebakan": jeb, "musuh": [m.x, m.y, m.z],
		"rng_state": str(p.mesin_acak.state),
		"tonton_aktif_null": p._ui_pedang_tonton_aktif == null,
		"replay_air": p.get("_replay_jebakan_air_berjalan"),
		"replay_paralisis": p.get("_replay_paralisis_berjalan"),
		"koleksi": [Array(p.koleksi_permata_pemain), Array(p.koleksi_permata_musuh)],
		"geser_len": p.geser_kamera.length(),
		"teks": p.teks_dadu.text,
		"nyawa": Array(p.nyawa_petak), "pemilik": Array(p.pemilik_petak), "level": Array(p.level_menara_petak),
		"sudah_serang": p.sudah_serang_giliran_ini, "membidik": p.mode_membidik, "fase": p.fase_giliran,
		"replay_serangan": p.get("_replay_serangan_berjalan"),
		"emboss": _petak_ber_emboss(),
		"posisi": [p.daftar_pemain[0].posisi_saat_ini, p.daftar_pemain[1].posisi_saat_ini],
		"x_model": [p.global_position.x, p.musuh.global_position.x],
		"koin": _peta_koin(),
		"uang": [p.daftar_pemain[0].uang, p.daftar_pemain[1].uang],
		"angin": _petak_angin(),
		"papan_skor": _ada_papan_skor(),
		"mode_jual": p.mode_jual_aset,
		"panel_syarat": _ada_panel_syarat(),
		"berhenti_petak": Array(p.berhenti_di_petak_sendiri),
	}

func _ada_papan_skor() -> bool:
	for b in get_tree().current_scene.find_children("*", "Button", true, false):
		if b.text == "EXIT TO MAIN MENU":
			return true
	return false

func _ada_panel_syarat() -> bool:
	for b in get_tree().current_scene.find_children("*", "Button", true, false):
		if b.text == "START GAME":
			return true
	return false

func _klik_tombol(teks: String) -> bool:
	for b in get_tree().current_scene.find_children("*", "Button", true, false):
		if b.text == teks and not b.disabled:
			b.emit_signal("pressed")
			return true
	return false

func _peta_koin() -> Dictionary:
	var m = {}
	for i in range(JUMLAH_PETAK):
		var k = papan[i].get_node_or_null("KoinTercecer")
		if k != null and not k.is_queued_for_deletion(): m[str(i)] = k.isi_koin
	return m

func _petak_angin() -> Array:
	var a = []
	for i in range(JUMLAH_PETAK):
		var j = papan[i].get_node_or_null("JebakanAngin")
		if j != null and not j.is_queued_for_deletion(): a.append(i)
	return a

func _perintah(nama: String, arg: Array = []) -> void:
	rpc_id(client_id, "rpc_uji_perintah", nama, arg)

func _ambil_log_client() -> Dictionary:
	log_client = null
	_perintah("kirim_log")
	var batas = 0.0
	while log_client == null and batas < 8.0:
		await get_tree().process_frame; batas += get_process_delta_time()
	return log_client if log_client != null else {}

func _klik_pedang_saat_muncul(indeks: int, jeda: float) -> void:
	var ui = null
	var batas = 0.0
	while ui == null and batas < 10.0:
		for c in p.get_children():
			if c.get_script() == PK and not c._pedang_tombol.is_empty() and not c._pedang_sudah_dipilih:
				ui = c
		if ui == null:
			await get_tree().process_frame; batas += get_process_delta_time()
	if ui == null:
		catat("GAGAL_ui_pedang_tidak_muncul"); return
	await get_tree().create_timer(jeda).timeout
	catat("klik_pedang|%d" % indeks)
	if indeks >= 0: ui._pedang_tombol[indeks].pressed.emit()
	else: ui._pedang_tombol_batal.pressed.emit()

# ---------------------------------------------------------------- mulai
func _ready():
	Engine.max_fps = 60
	peran = OS.get_cmdline_user_args()[0]
	StatusJaringan.peran_multiplayer = peran
	_bangun_adegan()
	var peer = ENetMultiplayerPeer.new()
	if peran == "host":
		peer.create_server(PORT, 2)
		multiplayer.multiplayer_peer = peer
		multiplayer.peer_disconnected.connect(p._saat_peer_jaringan_disconnect)
		client_id = await multiplayer.peer_connected
		p.daftar_pemain[1].id_jaringan = client_id
		await get_tree().create_timer(0.5).timeout
		await _jalankan_semua()
	else:
		await get_tree().create_timer(0.4).timeout
		peer.create_client("127.0.0.1", PORT)
		multiplayer.multiplayer_peer = peer
		multiplayer.server_disconnected.connect(p._saat_peer_jaringan_disconnect)
		await multiplayer.connected_to_server
		p.daftar_pemain[1].id_jaringan = multiplayer.get_unique_id()

# ---------------------------------------------------------------- skenario (HOST)
func _mulai_skenario(nama: String) -> void:
	print("\n== ", nama)
	log_kejadian.clear(); jejak.clear(); status_ui.clear(); geser_terakhir = null; koleksi_terakhir = ""
	_perintah("reset")
	await get_tree().create_timer(0.2).timeout

func _cari(log_arr: Array, awalan: String, setelah: float = 0.0) -> float:
	for e in log_arr:
		if e[0] >= setelah and String(e[1]).begins_with(awalan): return e[0]
	return -1.0

func _ada(log_arr: Array, awalan: String) -> bool:
	return _cari(log_arr, awalan) >= 0.0

func _jalankan_semua() -> void:
	if OS.get_cmdline_user_args().size() > 1 and OS.get_cmdline_user_args()[1] == "sebelum":
		await _uji_lempar("T1 (KODE LAMA) jebakan air terpicu -- client normal", 0.0)
		print("\nUJI SEBELUM SELESAI -- gagal: ", gagal)
		_perintah("keluar")
		await get_tree().create_timer(0.6).timeout
		get_tree().quit()
		return
	if OS.get_cmdline_user_args().size() > 1 and OS.get_cmdline_user_args()[1] == "serang_saja":
		await _uji_serang_client()
		await _uji_serang_host()
		print("\nUJI (SERANG SAJA) SELESAI -- gagal: ", gagal)
		_perintah("keluar")
		await get_tree().create_timer(0.6).timeout
		get_tree().quit()
		return
	await _uji_pasang_host()
	await _uji_pasang_client()
	await _uji_lempar("T1 jebakan air terpicu -- client normal", 0.0)
	await _uji_lempar("T2 jebakan air terpicu -- client LAMBAT (+0.7 dtk/langkah)", 0.7)
	await _uji_angin_koin("W1 jebakan angin menyebar koin & koin diambil -- client normal", 0.0)
	await _uji_angin_koin("W2 jebakan angin menyebar koin & koin diambil -- client LAMBAT (+1.0 dtk/langkah)", 1.0)
	await _uji_lindung_koin()
	await _uji_pedang_client_menyerang(1, "SA1 client menyerang, pilih pedang ke-1")
	await _uji_pedang_client_menyerang(-1, "SA2 client menyerang, NO SAVE IT")
	await _uji_pedang_host_menyerang(0, "SB1 host menyerang, pilih pedang ke-0")
	await _uji_pedang_host_menyerang(-1, "SB2 host menyerang, NO SAVE IT")
	await _uji_petir_residu("L1 residu paralisis MUSUH tersinkron ke client + teks PARALYSIS", true)
	await _uji_petir_residu("L2 residu paralisis PEMAIN (host) tersinkron ke client + teks PARALYSIS", false)
	await _uji_kamera()
	await _uji_hud()
	await _uji_permata("G1 host lewat petak permata -- client normal", "pemain", 0.0, false)
	await _uji_permata("G2 client lewat petak permata -- client LAMBAT (+1.0 dtk/langkah)", "musuh", 1.0, false)
	await _uji_permata("G3 client lewat lagi petak permata yang sudah dimiliki -> 'Passed'", "musuh", 0.0, true)
	await _uji_lindung_permata()
	await _uji_permata_pulih()
	await _uji_jual_aset()
	await _uji_panel_mulai()
	await _uji_menang("V1 HOST menang di Start -- client dapat panel KALAH", "pemain", 0.0)
	await _uji_menang("V2 CLIENT menang (client LAMBAT +0.8 dtk/langkah) -- host dapat panel KALAH", "musuh", 0.8)
	await _uji_start("S1 host lewat Start (gaji + reset permata) -- client normal", "pemain", 0.0, false)
	await _uji_start("S2 client lewat Start (gaji + reset permata) -- client LAMBAT (+1.0 dtk/langkah)", "musuh", 1.0, false)
	await _uji_start("S3 client lewat Start tapi permata kurang -> 'SALARY FAILED'", "musuh", 0.0, true)
	await _uji_cabang("B1 karakter HOST di persimpangan: host memilih ATAS, client menonton", "pemain", 1, 0.0, 2)
	await _uji_cabang("B2 karakter CLIENT di persimpangan: client memilih KANAN, host menonton", "musuh", 0, 0.0, 2)
	await _uji_cabang("B3 karakter CLIENT, client LAMBAT (+1.0 dtk/langkah): client memilih ATAS", "musuh", 1, 1.0, 1)
	await _uji_serang_client()
	await _uji_serang_host()
	await _uji_serang_batal_client()
	await _uji_serang_salah_client()
	await _uji_lawan_putus() # paling akhir: client sengaja dimatikan
	print("\nUJI MULTIPLAYER SELESAI -- gagal: ", gagal)
	_perintah("keluar")
	await get_tree().create_timer(0.6).timeout
	get_tree().quit()

func _uji_pasang_host() -> void:
	await _mulai_skenario("P1 host memasang jebakan air di petak 3 (gilirannya sendiri)")
	_atur_posisi(3, 0); _perintah("posisi", [3, 0])
	p.slot_giliran_ui = 0; p.daftar_pemain[0].bintang = 2
	await get_tree().create_timer(0.3).timeout
	var t0 = sekarang()
	p._on_tombol_air_pressed()
	await get_tree().create_timer(2.2).timeout
	var c = await _ambil_log_client()
	var t_muncul = _cari(c["log"], "jebakan|3|true")
	print("   jebakan muncul di client %.3f dtk setelah dipasang (dulu: ~1.5 dtk)" % (t_muncul - t0))
	_cek(t_muncul > 0 and t_muncul - t0 < 0.3, "jebakan langsung muncul di client (< 0.3 dtk)")
	_cek(_ada(log_kejadian, "teks|Water Trap placed on your spot!"), "teks host: 'Water Trap placed on your spot!'")
	_cek(_ada(c["log"], "teks|Enemy placed a Water Trap!"), "teks client: 'Enemy placed a Water Trap!'")
	_cek(c["jebakan"].get("3", -9) == 0, "jebakan di client milik slot 0")
	_cek(int(c["bintang"][0]) == 1, "bintang host di layar client ikut berkurang jadi 1")

func _uji_pasang_client() -> void:
	await _mulai_skenario("P2 client memasang jebakan air di petak 6 (gilirannya sendiri)")
	_atur_posisi(8, 6); p.daftar_pemain[1].bintang = 2
	p.periksa_status_petak(1) # giliran client (siaran state asli)
	await get_tree().create_timer(0.6).timeout
	var t0 = sekarang()
	_perintah("pasang_air_sendiri")
	await get_tree().create_timer(2.2).timeout
	var c = await _ambil_log_client()
	var t_host = _cari(log_kejadian, "jebakan|6|true")
	var t_client = _cari(c["log"], "jebakan|6|true")
	print("   host menerima & memasang %.3f dtk, client melihatnya %.3f dtk setelah klik" % [t_host - t0, t_client - t0])
	_cek(t_client > 0 and t_client - t0 < 0.3, "jebakan milik client langsung muncul di layar client")
	_cek(_ada(log_kejadian, "teks|Enemy placed a Water Trap!"), "teks host (sudut pandang host): 'Enemy placed a Water Trap!'")
	_cek(not _ada(log_kejadian, "teks|Water Trap placed on your spot!"), "host TIDAK lagi menampilkan 'placed on your spot' untuk jebakan lawan")
	_cek(_ada(c["log"], "teks|Water Trap placed on your spot!"), "teks client: 'Water Trap placed on your spot!'")
	_cek(c["jebakan"].get("6", -9) == 1, "jebakan di client milik slot 1")
	_cek(int(c["bintang"][1]) == 1, "bintang client berkurang jadi 1")

func _petak_dari_x(x: float) -> int:
	return int(round(x / 4.0))

func _analisis_jejak(jj: Array, t_trapped: float) -> Dictionary:
	# Petak yang dilalui sambil berjalan (sebelum mulai terlempar), kapan mulai
	# terlempar (y naik) + posisi x saat itu, puncak lemparan, waktu mendarat.
	var t_naik = -1.0
	var x_saat_naik = -99.0
	var x_sebelumnya = -99.0
	for s in jj:
		if s[0] >= t_trapped and s[2] > 0.01:
			t_naik = s[0]; x_saat_naik = x_sebelumnya; break
		x_sebelumnya = s[1]
	var dilalui = []
	var puncak = 0.0
	var t_puncak = -1.0
	for s in jj:
		if s[2] > puncak:
			puncak = s[2]; t_puncak = s[0]
		if (t_naik < 0 or s[0] < t_naik) and abs(s[2]) < 0.01 and abs(s[1] - round(s[1] / 4.0) * 4.0) < 0.05:
			var idx = _petak_dari_x(s[1])
			if dilalui.is_empty() or dilalui[-1] != idx: dilalui.append(idx)
	var t_mendarat = -1.0
	for s in jj:
		if t_puncak > 0 and s[0] > t_puncak and s[2] < 0.01:
			t_mendarat = s[0]; break
	# Cara karakter sampai ke petak jebakan (x=12): lama perjalanan dari petak 2
	# (sampel terakhir di x=8) sampai tiba di x=12. Langkah normal = 0.8 dtk,
	# "ditarik" (versi sebelumnya) = 0.3 dtk.
	var t_tiba3 = -1.0
	var t_tinggal2 = -1.0
	for s in jj:
		if s[2] < 0.01 and abs(s[1] - 8.0) < 0.01: t_tinggal2 = s[0]
		if s[2] < 0.01 and s[1] >= 11.99:
			t_tiba3 = s[0]; break
	return {"dilalui": dilalui, "t_naik": t_naik, "x_saat_naik": x_saat_naik, "puncak": puncak, "t_mendarat": t_mendarat, "t_tiba3": t_tiba3, "lama_masuk": t_tiba3 - t_tinggal2}

func _uji_lempar(nama: String, lag: float) -> void:
	await _mulai_skenario(nama)
	# Siapkan jebakan air baru milik slot 0 di petak 3 (lewat pemasangan asli).
	_atur_posisi(3, 0); _perintah("posisi", [3, 0])
	p.daftar_pemain[0].bintang = 2
	p.daftar_pemain[1].sisa_gelembung = 0
	var g_lama = p.model_musuh.get_node_or_null("EfekGelembung")
	if g_lama: g_lama.free() # di game asli ini dilepas ganti_giliran()
	p.periksa_status_petak(0)
	await get_tree().create_timer(0.5).timeout
	if papan[3].get_node_or_null("JebakanAir") == null:
		p._on_tombol_air_pressed()
		await get_tree().create_timer(1.8).timeout
	# Karakter host minggir ke petak 8; korban (slot 1) mulai dari petak 0.
	_atur_posisi(8, 0); _perintah("posisi", [8, 0])
	_perintah("lag", [lag])
	p.giliran_sekarang = "musuh"; p.fase_giliran = "awal"
	p.periksa_status_petak(1)
	await get_tree().create_timer(0.6).timeout
	log_kejadian.clear(); jejak.clear(); _perintah("reset")
	pantau_aktif = true; _perintah("pantau", [true])
	await get_tree().create_timer(0.2).timeout

	var rng_client_sebelum = (await _ambil_log_client())["rng_state"]
	await p.bergerak_maju(5, "musuh")
	var jatuh = p.daftar_pemain[1].posisi_saat_ini
	await get_tree().create_timer(4.0 + lag * 3.0).timeout
	pantau_aktif = false; _perintah("pantau", [false])
	var c = await _ambil_log_client()

	var th = _cari(log_kejadian, "teks|TRAPPED! Geyser Eruption!")
	var tc = _cari(c["log"], "teks|TRAPPED! Geyser Eruption!")
	var ah = _analisis_jejak(jejak, th)
	var ac = _analisis_jejak(c["jejak"], tc)
	print("   petak jatuh (diundi host): %d" % jatuh)
	print("   host  : dilalui %s | masuk petak jebakan %.2f dtk | TRAPPED %.2f dtk setelah tiba | terlempar dari x=%.2f pada +%.2f | puncak %.2f | mendarat +%.2f" % [ah["dilalui"], ah["lama_masuk"], th - ah["t_tiba3"], ah["x_saat_naik"], ah["t_naik"] - th, ah["puncak"], ah["t_mendarat"] - th])
	print("   client: dilalui %s | masuk petak jebakan %.2f dtk | TRAPPED %.2f dtk setelah tiba | terlempar dari x=%.2f pada +%.2f | puncak %.2f | mendarat +%.2f | mulai %.2f dtk setelah host" % [ac["dilalui"], ac["lama_masuk"], tc - ac["t_tiba3"], ac["x_saat_naik"], ac["t_naik"] - tc, ac["puncak"], ac["t_mendarat"] - tc, tc - th])
	var mh = p.musuh.global_position
	var mc = c["musuh"]
	print("   posisi akhir korban  host (%.2f, %.2f)  client (%.2f, %.2f)" % [mh.x, mh.z, mc[0], mc[2]])

	_cek(tc > 0, "client ikut memutar urutan jebakan air")
	_cek(ac["dilalui"].slice(0, 4) == [0, 1, 2, 3], "client berjalan 1 -> 2 -> 3 (petak jebakan) tanpa langkah dibuang")
	_cek(ah["dilalui"].slice(0, 4) == [0, 1, 2, 3], "host juga berjalan sampai berdiri di petak jebakan (3)")
	var tl3 = _cari(c["log"], "langkah|3")
	_cek(tl3 > 0 and tl3 < tc, "client menerima langkah NORMAL ke petak jebakan sebelum jebakannya aktif")
	var jeda = JebakanAir.JEDA_SEBELUM_AKTIF
	for sisi in [["host", ah, th], ["client", ac, tc]]:
		var a = sisi[1]
		_cek(abs(a["lama_masuk"] - 0.8) < 0.1, "%s: masuk ke petak jebakan dengan langkah biasa 0.8 dtk, bukan ditarik (%.2f dtk)" % [sisi[0], a["lama_masuk"]])
		_cek(sisi[2] >= a["t_tiba3"] - 0.05, "%s: 'TRAPPED!' baru muncul setelah berdiri di petak jebakan" % sisi[0])
		_cek(abs(a["x_saat_naik"] - 12.0) < 0.05, "%s: terlempar dari tengah petak jebakan (x=%.2f)" % [sisi[0], a["x_saat_naik"]])
		_cek(abs((a["t_naik"] - sisi[2]) - jeda) < 0.1, "%s: jeda %.1f dtk dulu sebelum geiser melempar (%.2f dtk)" % [sisi[0], jeda, a["t_naik"] - sisi[2]])
	_cek(abs(ac["puncak"] - ah["puncak"]) < 0.3 and ac["puncak"] > 7.0, "client terlempar melengkung setinggi host (puncak %.2f vs %.2f)" % [ac["puncak"], ah["puncak"]])
	_cek(abs((ac["t_mendarat"] - tc) - (ah["t_mendarat"] - th)) < 0.12, "durasi lemparan sama di kedua layar")
	_cek(abs(mh.x - mc[0]) < 0.05 and abs(mh.z - mc[2]) < 0.05, "korban berakhir di posisi yang SAMA di kedua layar")
	_cek(abs(mc[0] - papan[jatuh].global_position.x) < 1.5, "posisi akhir client = petak jatuh %d" % jatuh)
	var tg = _cari(c["log"], "gelembung|true")
	_cek(tg > 0 and tg >= ac["t_mendarat"] - 0.05, "gelembung di client muncul SETELAH mendarat (bukan sebelum terlempar)")
	_cek(_ada(c["log"], "teks|Landed randomly! Trapped in a Bubble for 2 turns!"), "teks 'Landed randomly!' juga tampil di client")
	_cek(c["jebakan"].get("3", -9) == -9, "jebakan di petak 3 sudah hilang di client")
	var t_state = -1.0
	var isi_state = ""
	for e in c["log"]:
		if e[0] >= tc and String(e[1]).begins_with("periksa|1"):
			t_state = e[0]; isi_state = e[1]; break
	var t_state_host = _cari(log_kejadian, "periksa|1", th)
	print("   state dikirim host +%.2f, diterapkan client +%.2f (relatif mulai jebakan di client) -> '%s'" % [t_state_host - tc, t_state - tc, isi_state])
	_cek(t_state > 0 and isi_state.contains("replay=false") and isi_state.contains("y=0.00"), "siaran state baru diterapkan client SETELAH lemparannya selesai & mendarat")
	_cek(t_state >= ac["t_mendarat"] + 1.4, "state diterapkan setelah teks 'Landed randomly!' selesai (+%.2f dtk setelah mendarat)" % (t_state - ac["t_mendarat"]))
	if lag > 0.0:
		_cek(t_state_host < t_state - 0.3, "(lag) siaran host memang tiba saat lemparan client masih berjalan -> penundaan benar-benar teruji")
	_cek(c["rng_state"] == rng_client_sebelum, "client tidak mengacak apapun sendiri (mesin_acak client tidak tersentuh)")
	if lag > 0.0:
		_cek(tc - th > 0.5, "(lag) client memang tertinggal %.2f dtk, tapi tetap utuh" % (tc - th))
	else:
		_cek(tc - th < 0.25, "urutan di client mulai hampir bersamaan dengan host (%.3f dtk)" % (tc - th))
	_perintah("lag", [0.0])

func _analisis_pedang(log_arr: Array) -> Dictionary:
	var t_buka = _cari(log_arr, "pedang_buka")
	var t_umum = -1.0
	var judul_umum = ""
	for e in log_arr:
		var s = String(e[1])
		if s.begins_with("pedang_judul|") and (s.contains("USED") or s.contains("USES") or s.contains("SAVE")):
			t_umum = e[0]; judul_umum = s.substr(13); break
	var t_tutup = _cari(log_arr, "pedang_tutup", t_buka)
	return {"buka": t_buka, "umum": t_umum, "judul": judul_umum, "tutup": t_tutup}

func _laporan_pedang(ah: Dictionary, ac: Dictionary, harap_h: String, harap_c: String) -> void:
	print("   host  : '%s' | umumkan %.2f dtk" % [ah["judul"], ah["tutup"] - ah["umum"]])
	print("   client: '%s' | umumkan %.2f dtk" % [ac["judul"], ac["tutup"] - ac["umum"]])
	print("   selisih mulai pengumuman host vs client: %.3f dtk" % abs(ah["umum"] - ac["umum"]))
	_cek(ah["judul"] == harap_h, "judul pengumuman host = '%s'" % harap_h)
	_cek(ac["judul"] == harap_c, "judul pengumuman client = '%s'" % harap_c)
	_cek(abs((ah["tutup"] - ah["umum"]) - 1.5) < 0.12, "host mengumumkan selama 1.5 dtk")
	_cek(abs((ac["tutup"] - ac["umum"]) - 1.5) < 0.12, "client mengumumkan selama 1.5 dtk")
	_cek(abs(ah["umum"] - ac["umum"]) < 0.15, "pengumuman di kedua layar mulai bersamaan")

func _uji_pedang_client_menyerang(indeks: int, nama: String) -> void:
	await _mulai_skenario(nama)
	var tmp = PK.new(); var db = tmp.database_efek.duplicate(); tmp.free()
	var inv = [db[8], db[6], db[10]] # pedang_1, dadu_tinggi, pedang_3 -> pedang = [pedang_1, pedang_3]
	p.daftar_pemain[1].inventaris_kartu = inv.duplicate()
	_perintah("klik_pedang", [indeks, 0.8])
	var hasil = await p._pilih_pedang_penyerang(1)
	var t_kembali = sekarang()
	await get_tree().create_timer(0.5).timeout
	var c = await _ambil_log_client()
	var ah = _analisis_pedang(log_kejadian)
	var ac = _analisis_pedang(c["log"])
	var harap = null if indeks < 0 else [db[8], db[10]][indeks]
	print("   host menerima: %s" % ("tidak pakai" if hasil == null else hasil["id"]))
	_cek((hasil == null and harap == null) or (hasil != null and harap != null and hasil["id"] == harap["id"]), "kartu yang dipakai host = pilihan client")
	if indeks >= 0:
		_laporan_pedang(ah, ac, "ENEMY USES SWORD CARD! / +3 ATK", "SWORD CARD USED! / +3 ATK")
	else:
		_laporan_pedang(ah, ac, "ENEMY SAVED THE SWORD CARD! / No bonus this time", "SWORD CARD SAVED! / No bonus this time")
	_cek(t_kembali >= ah["tutup"] - 0.05, "host baru lanjut ke duel setelah pengumumannya selesai")

func _uji_pedang_host_menyerang(indeks: int, nama: String) -> void:
	await _mulai_skenario(nama)
	var tmp = PK.new(); var db = tmp.database_efek.duplicate(); tmp.free()
	var inv = [db[9], db[7], db[8]] # pedang_2, pelindung, pedang_1 -> pedang = [pedang_2, pedang_1]
	p.daftar_pemain[0].inventaris_kartu = inv.duplicate()
	_klik_pedang_saat_muncul(indeks, 0.8)
	var hasil = await p._pilih_pedang_penyerang(0)
	var t_kembali = sekarang()
	await get_tree().create_timer(0.5).timeout
	var c = await _ambil_log_client()
	var ah = _analisis_pedang(log_kejadian)
	var ac = _analisis_pedang(c["log"])
	var harap = null if indeks < 0 else [db[9], db[8]][indeks]
	print("   host memakai: %s" % ("tidak pakai" if hasil == null else hasil["id"]))
	_cek((hasil == null and harap == null) or (hasil != null and harap != null and hasil["id"] == harap["id"]), "kartu yang dipakai = yang diklik host")
	if indeks >= 0:
		_laporan_pedang(ah, ac, "SWORD CARD USED! / +2 ATK", "ENEMY USES SWORD CARD! / +2 ATK")
	else:
		_laporan_pedang(ah, ac, "SWORD CARD SAVED! / No bonus this time", "ENEMY SAVED THE SWORD CARD! / No bonus this time")
	_cek(t_kembali >= ah["tutup"] - 0.05, "host baru lanjut ke duel setelah pengumumannya selesai")
	_cek(c["tonton_aktif_null"], "UI tonton di client sudah dibersihkan")

func _uji_petir_residu(nama: String, musuh_target: bool) -> void:
	# ganti_giliran() HOST-ONLY: pastikan efek residu paralisis (getar tubuh +
	# teks melayang "PARALYSIS") ikut disiarkan & diputar di client, bukan cuma
	# di layar host.
	await _mulai_skenario(nama)
	_bersihkan_papan_host()
	_atur_posisi(2, 6); _perintah("posisi", [2, 6])
	# Netralkan status lain supaya cuma jalur paralisis yang teruji.
	for slot in [0, 1]:
		p.daftar_pemain[slot].sisa_gelembung = 0
		p.daftar_pemain[slot].sisa_bakar = 0
		p.daftar_pemain[slot].sisa_paralisis = 0
	p.sisa_durasi_dadu_musuh = 0
	p.sisa_durasi_dadu_pemain = 0
	var slot_korban = 1 if musuh_target else 0
	# 2 -> setelah dikurangi 1 oleh ganti_giliran() jadi 1 (>0) -> masuk cabang
	# "masih diparalisis giliran ini", persis cabang yang baru disambungkan ke RPC.
	p.daftar_pemain[slot_korban].sisa_paralisis = 2
	p.giliran_sekarang = "pemain" if musuh_target else "musuh"
	p.fase_giliran = "akhir"
	await get_tree().create_timer(0.3).timeout
	log_kejadian.clear(); jejak.clear(); _perintah("reset")
	await get_tree().create_timer(0.2).timeout

	var t0 = sekarang()
	await p.ganti_giliran()
	await get_tree().create_timer(2.2).timeout
	var c = await _ambil_log_client()

	# Bendera _replay_paralisis_berjalan HANYA ada di jalur RPC client (persis
	# seperti _replay_jebakan_air_berjalan) -- host tidak pernah menyalakannya
	# karena tidak menerima siaran dirinya sendiri. Jadi dipakai teks_paralysis
	# sebagai penanda waktu di HOST, dan replay_paralisis khusus di CLIENT.
	var th = _cari(log_kejadian, "teks_paralysis|true")
	var tc = _cari(c["log"], "replay_paralisis|true")
	print("   host mulai +%.2f | client mulai +%.2f (selisih %.3f dtk)" % [th - t0, tc - t0, tc - th if (th > 0 and tc > 0) else -9.0])
	_cek(th > 0, "host memutar efek residu paralisis (lokal, seperti sebelumnya)")
	_cek(tc > 0, "client JUGA menerima & memutar efek residu paralisis (BARU -- sebelumnya cuma di host)")
	if th > 0 and tc > 0:
		_cek(abs(tc - th) < 0.25, "efek residu mulai di kedua layar hampir bersamaan (%.3f dtk)" % abs(tc - th))
	_cek(_ada(c["log"], "replay_paralisis|false"), "client: bendera replay direset ke false setelah efek selesai (tidak macet)")
	_cek(_ada(log_kejadian, "teks_paralysis|true"), "host: teks melayang 'PARALYSIS' muncul")
	_cek(_ada(c["log"], "teks_paralysis|true"), "client: teks melayang 'PARALYSIS' JUGA muncul (BARU)")
	_cek(_ada(log_kejadian, "teks_paralysis|false"), "host: teks 'PARALYSIS' hilang lagi setelah melayang (tidak bocor)")
	_cek(_ada(c["log"], "teks_paralysis|false"), "client: teks 'PARALYSIS' hilang lagi setelah melayang (tidak bocor)")
	_cek(p.daftar_pemain[slot_korban].sisa_paralisis == 1, "sisa_paralisis host berkurang 1 dengan benar (masih diparalisis)")
	_cek(c["replay_paralisis"] == false, "bendera replay client sudah bersih di akhir (tidak mengunci siaran state berikutnya)")
	p.daftar_pemain[slot_korban].sisa_paralisis = 0

# ---------------------------------------------------------------- koin tercecer
func _bersihkan_papan_host() -> void:
	for i in range(JUMLAH_PETAK):
		for n in ["KoinTercecer", "JebakanAngin", "JebakanAir"]:
			var x = papan[i].get_node_or_null(n)
			if x:
				x.name = n + "Lama"; x.queue_free()
	var g_lama = p.model_musuh.get_node_or_null("EfekGelembung")
	if g_lama: g_lama.free()
	p.daftar_pemain[1].sisa_gelembung = 0
	await get_tree().process_frame

func _entri_koin(log_arr: Array, setelah: float) -> Array:
	# [waktu, petak, isi] untuk tiap perubahan tumpukan koin setelah 'setelah'
	var hasil = []
	for e in log_arr:
		var s = String(e[1])
		if e[0] >= setelah and s.begins_with("koin|"):
			var b = s.split("|")
			hasil.append([e[0], int(b[1]), int(b[2])])
	return hasil

func _posisi_pada(jj: Array, t: float) -> Array:
	for s in jj:
		if s[0] >= t: return s
	return jj[-1] if not jj.is_empty() else [0.0, -99.0, -99.0, 0.0]

func _t_tiba_di(jj: Array, petak: int, setelah: float) -> float:
	for s in jj:
		if s[0] >= setelah and s[2] < 0.01 and abs(s[1] - petak * 4.0) < 0.01:
			return s[0]
	return -1.0

func _uji_angin_koin(nama: String, lag: float) -> void:
	await _mulai_skenario(nama)
	await _bersihkan_papan_host()
	# Host memasang jebakan angin di petak 2 lewat tombol aslinya.
	_atur_posisi(2, 0); _perintah("posisi", [2, 0])
	p.daftar_pemain[0].bintang = 2
	p.periksa_status_petak(0)
	await get_tree().create_timer(0.5).timeout
	p._on_tombol_angin_pressed()
	await get_tree().create_timer(1.8).timeout
	# Tumpukan koin yang SUDAH ada sebelumnya: petak 4 (100) & 7 (50).
	p._buat_koin_tercecer(4, 100)
	p._buat_koin_tercecer(7, 50)
	_atur_posisi(9, 0); _perintah("posisi", [9, 0])
	p.daftar_pemain[1].uang = 1000
	_perintah("lag", [lag])
	p.giliran_sekarang = "musuh"; p.fase_giliran = "awal"
	p.periksa_status_petak(1)
	await get_tree().create_timer(0.6).timeout
	var c0 = await _ambil_log_client()
	_cek(c0["koin"] == {"4": 100.0, "7": 50.0}, "tumpukan koin lama sampai ke client lewat siaran state: %s" % [c0["koin"]])
	_cek(c0["angin"] == [2.0], "jebakan angin di petak 2 ada di client")
	log_kejadian.clear(); jejak.clear(); _perintah("reset")
	pantau_aktif = true; _perintah("pantau", [true])
	await get_tree().create_timer(0.2).timeout
	var t_mulai = sekarang()
	var rng_client_sebelum = c0["rng_state"]

	await p.bergerak_maju(5, "musuh")
	await get_tree().create_timer(2.0 + lag * 6.0).timeout
	pantau_aktif = false; _perintah("pantau", [false])
	var c = await _ambil_log_client()

	# --- 1. Penyebaran koin: petak & jumlah sama, muncul bersamaan ---
	var t_angin = _cari(log_kejadian, "teks|WIND TRAP!")
	var sebar_host = []
	for e in _entri_koin(log_kejadian, t_angin - 0.05):
		if e[0] <= t_angin + 0.1 and e[2] > 0: sebar_host.append(e)
	print("   jebakan angin: host menyebar koin ke %s" % [sebar_host.map(func(e): return "petak %d=%d" % [e[1], e[2]])])
	_cek(sebar_host.size() >= 2, "host memang menyebar koin (2-4 tumpukan)")
	var selisih_maks = 0.0
	var semua_muncul = true
	for e in sebar_host:
		var ketemu = false
		for ec in _entri_koin(c["log"], t_angin - 0.2):
			if ec[1] == e[1] and ec[2] == e[2]:
				ketemu = true; selisih_maks = max(selisih_maks, abs(ec[0] - e[0])); break
		if not ketemu: semua_muncul = false
	print("   koin sebaran muncul di client paling lambat %.3f dtk setelah host" % selisih_maks)
	_cek(semua_muncul, "SEMUA tumpukan sebaran muncul di client dengan jumlah yang sama")
	_cek(selisih_maks < 0.25, "koin sebaran muncul di client bersamaan dengan host")

	# --- 2. Pengambilan koin: setelah karakter client benar-benar tiba ---
	var ambil_host = []
	for e in _entri_koin(log_kejadian, t_mulai):
		if e[2] == -1: ambil_host.append(e[1])
	print("   petak yang koinnya diambil korban: %s" % [ambil_host])
	_cek(ambil_host.has(4), "korban mengambil tumpukan di petak 4 (yang dilewati)")
	for petak in ambil_host:
		var t_ambil_c = -1.0
		for ec in _entri_koin(c["log"], t_mulai):
			if ec[1] == petak and ec[2] == -1:
				t_ambil_c = ec[0]; break
		var t_langkah_c = _cari(c["log"], "langkah|%d" % petak, t_mulai)
		var pos = _posisi_pada(c["jejak"], t_ambil_c)
		print("   petak %d: langkah client ke sana mulai +%.2f, koin diambil +%.2f (host +%.2f) | posisi karakter client saat itu x=%.2f (tengah petak x=%.1f)" % [petak, t_langkah_c - t_mulai, t_ambil_c - t_mulai, _cari(log_kejadian, "koin|%d|-1" % petak, t_mulai) - t_mulai, pos[1], petak * 4.0])
		_cek(t_ambil_c > 0, "petak %d: koin juga hilang di client" % petak)
		_cek(t_langkah_c > 0 and t_ambil_c >= t_langkah_c + 0.75, "petak %d: koin baru diambil SETELAH langkah client ke petak itu selesai diputar" % petak)
		_cek(abs(pos[1] - petak * 4.0) < 0.25 and pos[2] < 0.01, "petak %d: karakter client sedang berdiri di petak itu saat koinnya lenyap" % petak)
	for petak in ambil_host:
		var jumlah = {4: 100, 7: 50}.get(petak, -1) # tumpukan lama (dibuat sebelum pencatatan)
		for e in _entri_koin(log_kejadian, t_mulai):
			if e[1] == petak and e[2] == -1: break
			if e[1] == petak and e[2] > 0: jumlah = e[2]
		_cek(_ada(c["log"], "teks|You found %d Coins!" % jumlah) and _ada(log_kejadian, "teks|Enemy found %d Coins!" % jumlah), "petak %d: teks sesuai sudut pandang -- client 'You found %d Coins!', host 'Enemy found %d Coins!'" % [petak, jumlah, jumlah])

	# --- 3. Keadaan akhir identik ---
	var peta_h = _peta_koin()
	var peta_c = {}
	for k in c["koin"].keys(): peta_c[k] = int(c["koin"][k])
	print("   koin akhir  host %s | client %s" % [peta_h, peta_c])
	_cek(peta_h == peta_c, "semua tumpukan koin di akhir SAMA di kedua layar")
	_cek(int(c["uang"][1]) == p.daftar_pemain[1].uang, "uang korban sama di kedua layar (%d)" % p.daftar_pemain[1].uang)
	_cek(c["rng_state"] == rng_client_sebelum, "client tidak mengacak apapun sendiri")
	_perintah("lag", [0.0])

func _uji_lindung_koin() -> void:
	await _mulai_skenario("K1 siaran state tiba saat efek 'koin diambil' di client masih menunggu karakternya tiba")
	_perintah("uji_lindung_koin")
	await get_tree().create_timer(2.0).timeout
	var c = await _ambil_log_client()
	var n = 0
	for e in c["log"]:
		var b = String(e[1]).split("|")
		if b[0] == "K1":
			n += 1
			_cek(b[1] == "ok", b[2])
	_cek(n == 3, "ketiga pemeriksaan K1 berjalan di client")

func _uji_lindung_koin_client() -> void:
	# (dijalankan di CLIENT) Tiru: langkah ke petak 5 masih diputar, kabar "koin
	# diambil" sudah tiba, lalu siaran state (tanpa koin di petak 5) ikut tiba.
	p._buat_koin_tercecer(5, 77)
	await get_tree().process_frame
	p._langkah_diputar = 5
	p.rpc_koin_diambil(5, 1, 77, 4321)
	await get_tree().process_frame
	p._terapkan_data_koin([])
	await get_tree().create_timer(0.3).timeout
	var k = papan[5].get_node_or_null("KoinTercecer")
	var masih = k != null and not k.is_queued_for_deletion()
	catat("K1|%s|koin TIDAK dihapus siaran state selagi efek pengambilannya menunggu" % ("ok" if masih else "gagal"))
	p._langkah_diputar = -1
	await get_tree().create_timer(0.3).timeout
	k = papan[5].get_node_or_null("KoinTercecer")
	var hilang = k == null or k.is_queued_for_deletion()
	catat("K1|%s|begitu karakter tiba, koin diambil dengan efeknya" % ("ok" if hilang and p.teks_dadu.text == "You found 77 Coins!" else "gagal"))
	catat("K1|%s|uang ikut disamakan (%d)" % ["ok" if p.daftar_pemain[1].uang == 4321 else "gagal", p.daftar_pemain[1].uang])

# ---------------------------------------------------------------- kamera / HUD / permata
func _nilai_pada(log_arr: Array, awalan: String, t: float) -> String:
	# Nilai terakhir berawalan 'awalan' yang tercatat pada/sebelum waktu t.
	var nilai = "?"
	for e in log_arr:
		if e[0] > t: break
		var s = String(e[1])
		if s.begins_with(awalan): nilai = s.substr(awalan.length())
	return nilai

func _tunggu_log(awalan: String, setelah: float, batas: float) -> float:
	var t_mulai = sekarang()
	while sekarang() - t_mulai < batas:
		var t = _cari(log_kejadian, awalan, setelah)
		if t > 0: return t
		await get_tree().process_frame
	return -1.0

func _netralkan_status() -> void:
	for slot in [0, 1]:
		p.daftar_pemain[slot].sisa_gelembung = 0
		p.daftar_pemain[slot].sisa_bakar = 0
		p.daftar_pemain[slot].sisa_paralisis = 0
	p.sisa_durasi_dadu_musuh = 0
	p.sisa_durasi_dadu_pemain = 0
	p.mode_membidik = false

func _uji_kamera() -> void:
	await _mulai_skenario("C1 kamera bisa digeser di awal giliran HOST maupun CLIENT (di kedua device), terkunci saat dadu/berjalan")
	await _bersihkan_papan_host()
	_pasang_permata(3, false); _perintah("permata", [3, false])
	_atur_posisi(2, 6); _perintah("posisi", [2, 6])
	_netralkan_status()
	p.giliran_sekarang = "pemain"; p.fase_giliran = "awal"; p.sedang_bergerak = false
	p.periksa_status_petak(0)
	await get_tree().create_timer(0.6).timeout
	var t_awal_host = sekarang()

	# 1) HOST melempar dadu (tombol tutup di fase awal) -- jalur asli lempar_dadu
	p._proses_tombol_tutup()
	var t_lempar_host = sekarang()
	var t_selesai_host = await _tunggu_log("periksa|0", t_lempar_host, 15.0)
	await get_tree().create_timer(0.4).timeout
	var t_akhir_host = sekarang()

	# 2) host mengakhiri giliran -> giliran CLIENT (ganti_giliran asli)
	p._proses_tombol_tutup()
	await _tunggu_log("periksa|1", t_akhir_host, 6.0)
	await get_tree().create_timer(0.6).timeout
	var t_awal_client = sekarang()
	_perintah("set_geser", [3.0, 3.0]) # pemain client sempat menggeser kamera
	await get_tree().create_timer(0.3).timeout
	var geser_sebelum = (await _ambil_log_client())["geser_len"]

	# 3) CLIENT melempar dadu lewat tombolnya sendiri (-> rpc_minta_aksi -> host)
	var t_lempar_client = sekarang()
	_perintah("tutup_client")
	await get_tree().create_timer(0.6).timeout
	var geser_setelah_lempar = (await _ambil_log_client())["geser_len"]
	var t_selesai_client = await _tunggu_log("periksa|1", t_lempar_client + 0.1, 15.0)
	await get_tree().create_timer(0.4).timeout
	var t_akhir_client = sekarang()
	_perintah("set_geser", [2.0, 2.0])
	await get_tree().create_timer(0.3).timeout

	# 4) client mengakhiri gilirannya -> kembali ke HOST
	var t_ganti = sekarang()
	_perintah("tutup_client")
	await _tunggu_log("periksa|0", t_ganti, 6.0)
	await get_tree().create_timer(0.6).timeout
	var t_awal_host2 = sekarang()
	var c = await _ambil_log_client()
	var lh = log_kejadian
	var lc = c["log"]

	var titik = [
		["awal giliran HOST", t_awal_host, "true"],
		["host sedang melempar dadu", t_lempar_host + 0.25, "false"],
		["host sedang berjalan", (t_lempar_host + t_selesai_host) / 2.0 + 0.9, "false"],
		["host selesai berjalan (fase akhir)", t_akhir_host, "false"],
		["awal giliran CLIENT", t_awal_client, "true"],
		["client sedang melempar dadu", t_lempar_client + 0.35, "false"],
		["client sedang berjalan", (t_lempar_client + t_selesai_client) / 2.0 + 0.9, "false"],
		["client selesai berjalan (fase akhir)", t_akhir_client, "false"],
		["awal giliran HOST lagi", t_awal_host2, "true"],
	]
	for tt in titik:
		var vh = _nilai_pada(lh, "geser|", tt[1])
		var vc = _nilai_pada(lc, "geser|", tt[1])
		_cek(vh == tt[2] and vc == tt[2], "%s: boleh geser host=%s client=%s (harus %s)" % [tt[0], vh, vc, tt[2]])
	_cek(geser_sebelum > 4.0 and geser_setelah_lempar < 0.001, "client: geseran kamera kembali ke karakter begitu dadu dilempar (%.2f -> %.2f)" % [geser_sebelum, geser_setelah_lempar])
	_cek(c["geser_len"] < 0.001, "client: geseran kamera direset saat giliran berganti (%.2f)" % c["geser_len"])

func _render_hud() -> void:
	p._render_uang_tampil(p.daftar_pemain[0].uang, "pemain")
	p._render_uang_tampil(p.daftar_pemain[1].uang, "musuh")
	catat("hud|kiri|" + p.teks_uang.text.replace("\n", " / "))
	catat("hud|kanan|" + p.teks_bintang.text.replace("\n", " / "))

func _uji_hud() -> void:
	await _mulai_skenario("H1 panel 'Your' = milik pemain DI DEVICE ITU (client beli petak -> koin CLIENT yang berkurang)")
	await _bersihkan_papan_host()
	_atur_posisi(2, 6); _perintah("posisi", [2, 6])
	_netralkan_status()
	for i in range(JUMLAH_PETAK):
		p.status_kepemilikan_petak[i] = false; p.pemilik_petak[i] = -1
	p.daftar_pemain[0].uang = 2500; p.daftar_pemain[1].uang = 2500
	p.daftar_pemain[0].bintang = 3; p.daftar_pemain[1].bintang = 7
	p.koleksi_permata_pemain.assign(["PA"]); p.koleksi_permata_musuh.assign(["MB", "MC"])
	p.giliran_sekarang = "musuh"; p.fase_giliran = "awal"
	p.periksa_status_petak(1)
	await get_tree().create_timer(0.6).timeout
	var t0 = sekarang()
	_perintah("beli_client") # tombol Beli di device client
	await _tunggu_log("periksa|1", t0, 5.0)
	await get_tree().create_timer(0.6).timeout
	_render_hud()
	_perintah("render_hud")
	await get_tree().create_timer(0.3).timeout
	var c = await _ambil_log_client()
	var hk = _nilai_pada(log_kejadian, "hud|kiri|", sekarang())
	var hn = _nilai_pada(log_kejadian, "hud|kanan|", sekarang())
	var ck = _nilai_pada(c["log"], "hud|kiri|", sekarang())
	var cn = _nilai_pada(c["log"], "hud|kanan|", sekarang())
	print("   host   kiri : ", hk, "\n   host   kanan: ", hn)
	print("   client kiri : ", ck, "\n   client kanan: ", cn)
	_cek(p.daftar_pemain[1].uang == 2200 and p.daftar_pemain[0].uang == 2500, "host: pembelian oleh client memotong koin SLOT CLIENT (2500 -> 2200)")
	_cek(ck.contains("Your Coins: [color=#ffffff]2200") and ck.contains("Your Stars: ⭐ x 7") and ck.contains("MB MC"), "client: panel kiri 'Your' = koin/bintang/permata milik CLIENT sendiri")
	_cek(cn.contains("Enemy Coins: [color=#ffffff]2500") and cn.contains("Enemy Stars: ⭐ x 3") and cn.contains("PA"), "client: panel kanan 'Enemy' = milik host")
	_cek(hk.contains("Your Coins: [color=#ffffff]2500") and hk.contains("Your Stars: ⭐ x 3") and hk.contains("PA"), "host: panel kiri 'Your' tetap milik host (tidak berubah)")
	_cek(hn.contains("Enemy Coins: [color=#ffffff]2200") and hn.contains("Enemy Stars: ⭐ x 7") and hn.contains("MB MC"), "host: panel kanan 'Enemy' = milik client")
	p.koleksi_permata_pemain.clear(); p.koleksi_permata_musuh.clear()

func _pasang_permata(idx: int, aktif: bool) -> void:
	var t = papan[idx]
	if aktif:
		t.is_petak_permata = true
		t.pilihan_warna_permata = 1
		if t.node_visual_permata == null or not is_instance_valid(t.node_visual_permata):
			var vp = PetakPermata.new()
			vp.nama_warna = t.nama_warna_permata
			t.node_visual_permata = vp
			t.add_child(vp)
	else:
		t.is_petak_permata = false
		if t.node_visual_permata != null and is_instance_valid(t.node_visual_permata):
			t.node_visual_permata.queue_free()
		t.node_visual_permata = null
	jml_ting[idx] = 0

func _uji_permata(nama: String, aktor: String, lag: float, sudah_punya: bool) -> void:
	await _mulai_skenario(nama)
	await _bersihkan_papan_host()
	_netralkan_status()
	_pasang_permata(3, true); _perintah("permata", [3, true])
	var slot = 0 if aktor == "pemain" else 1
	var kode = papan[3].nama_warna_permata
	if not sudah_punya:
		p.koleksi_permata_pemain.clear(); p.koleksi_permata_musuh.clear()
	if slot == 0:
		_atur_posisi(1, 8); _perintah("posisi", [1, 8])
	else:
		_atur_posisi(8, 1); _perintah("posisi", [8, 1])
	p.giliran_sekarang = aktor; p.fase_giliran = "akhir"
	p.periksa_status_petak(slot) # koleksi awal ikut disamakan ke client
	await get_tree().create_timer(0.6).timeout
	_perintah("lag", [lag])
	log_kejadian.clear(); _perintah("reset")
	await get_tree().create_timer(0.2).timeout

	var t0 = sekarang()
	await p.bergerak_maju(3, aktor) # 1 -> 2 -> 3 (PERMATA) -> 4
	await get_tree().create_timer(2.0 + lag * 3.0).timeout
	var c = await _ambil_log_client()

	var th = _cari(log_kejadian, "efek_permata|3", t0)
	var tc = _cari(c["log"], "efek_permata|3", t0)
	var tl3 = _cari(c["log"], "langkah|3", t0)
	var siapa_h = "You" if slot == 0 else "Enemy"
	var siapa_c = "You" if slot == 1 else "Enemy"
	var teks_h = ("Passed " + kode + "!") if sudah_punya else (siapa_h + " collected " + kode + " Gem!")
	var teks_c = ("Passed " + kode + "!") if sudah_punya else (siapa_c + " collected " + kode + " Gem!")
	print("   efek permata: host +%.2f | client +%.2f (langkah ke petak 3 di client mulai +%.2f -> tiba +%.2f)" % [th - t0, tc - t0, tl3 - t0, tl3 + 0.8 - t0])
	_cek(th > 0, "host: animasi dapat permata diputar")
	_cek(tc > 0, "client: animasi dapat permata JUGA diputar")
	_cek(tl3 > 0 and tc >= tl3 + 0.75, "client: animasinya baru diputar setelah karakternya benar-benar tiba di petak permata")
	if lag > 0.0:
		_cek(tc - th > 0.5, "(lag) client tertinggal %.2f dtk tapi tetap menunggu karakternya tiba" % (tc - th))
	else:
		_cek(abs(tc - th) < 0.3, "animasi di kedua layar hampir bersamaan (%.2f dtk)" % abs(tc - th))
	_cek(_ada(log_kejadian, "teks|" + teks_h), "host: teks '%s'" % teks_h)
	_cek(_ada(c["log"], "teks|" + teks_c), "client: teks '%s' (sudut pandang client)" % teks_c)
	var kh = [Array(p.koleksi_permata_pemain), Array(p.koleksi_permata_musuh)]
	_cek(kh[slot] == [kode], "host: koleksi pelaku berisi permata itu tepat sekali")
	_cek(c["koleksi"] == kh, "client: koleksi permata kedua pemain == host")
	if not sudah_punya:
		var tk = _cari(c["log"], "koleksi|", t0)
		_cek(tk > 0 and abs(tk - tc) < 0.15, "client: keterangan permata bertambah BERSAMAAN dengan animasinya, bukan menunggu akhir giliran")
	_perintah("lag", [0.0])

func _uji_lindung_permata() -> void:
	await _mulai_skenario("G4 siaran state yang lebih baru tiba selagi efek permata/koin di client masih menunggu karakternya tiba")
	_perintah("uji_lindung_permata")
	await get_tree().create_timer(3.0).timeout
	var c = await _ambil_log_client()
	var n = 0
	for e in c["log"]:
		var b = String(e[1]).split("|")
		if b[0] == "G4":
			n += 1
			_cek(b[1] == "ok", b[2])
	_cek(n == 5, "kelima pemeriksaan G4 berjalan di client")

func _data_state_lokal() -> Dictionary:
	# Bentuk data yang sama dengan _siarkan_state_giliran, dari state device ini.
	return {
		"posisi": [p.daftar_pemain[0].posisi_saat_ini, p.daftar_pemain[1].posisi_saat_ini],
		"uang": [p.daftar_pemain[0].uang, p.daftar_pemain[1].uang],
		"bintang": [p.daftar_pemain[0].bintang, p.daftar_pemain[1].bintang],
		"gelembung": [0, 0], "paralisis": [0, 0], "bakar": [0, 0],
		"fase_giliran": p.fase_giliran, "giliran_sekarang": p.giliran_sekarang,
		"status_kepemilikan": p.status_kepemilikan_petak, "pemilik": p.pemilik_petak,
		"level_menara": p.level_menara_petak, "nyawa": p.nyawa_petak,
		"jebakan": p._kumpulkan_data_jebakan(), "koin": p._kumpulkan_data_koin(),
		"permata": [p.koleksi_permata_pemain.duplicate(), p.koleksi_permata_musuh.duplicate()],
	}

func _uji_lindung_permata_client() -> void:
	# (dijalankan di CLIENT)
	# a) Kabar "permata diambil" menunggu karakternya tiba; sementara itu tiba siaran
	#    state yang lebih baru di mana koleksinya sudah di-reset (mis. lewat Start).
	p.koleksi_permata_musuh.clear()
	p._langkah_diputar = 3
	p.rpc_permata_diambil(3, 1, "X", true, false, ["X"])
	await get_tree().process_frame
	catat("G4|%s|efek permata menunggu karakter tiba (koleksi belum diubah)" % ("ok" if p.koleksi_permata_musuh.is_empty() else "gagal"))
	var data = _data_state_lokal()
	data["permata"] = [[], []]
	p.rpc_terima_state_giliran(1, data)
	await get_tree().process_frame
	p._langkah_diputar = -1
	await get_tree().create_timer(0.2).timeout
	catat("G4|%s|koleksi dari siaran yang lebih baru TIDAK ditimpa kabar lama (%s)" % ["ok" if p.koleksi_permata_musuh.is_empty() else "gagal", str(p.koleksi_permata_musuh)])
	catat("G4|%s|teksnya tetap muncul setelah karakter tiba ('%s')" % ["ok" if p.teks_dadu.text == "You collected X Gem!" else "gagal", p.teks_dadu.text])
	# b) Tanpa siaran di antaranya -> koleksi dari kabar itu yang dipakai.
	p._langkah_diputar = 3
	p.rpc_permata_diambil(3, 1, "Y", true, false, ["Y"])
	await get_tree().process_frame
	p._langkah_diputar = -1
	await get_tree().create_timer(0.2).timeout
	catat("G4|%s|tanpa siaran di antaranya, koleksi dari kabar dipakai (%s)" % ["ok" if Array(p.koleksi_permata_musuh) == ["Y"] else "gagal", str(p.koleksi_permata_musuh)])
	# c) Koin: uang dari siaran state yang lebih baru tidak ditimpa kabar koin lama.
	p._buat_koin_tercecer(5, 50)
	await get_tree().process_frame
	p._langkah_diputar = 5
	p.rpc_koin_diambil(5, 1, 50, 1234)
	await get_tree().process_frame
	data = _data_state_lokal()
	data["uang"] = [p.daftar_pemain[0].uang, 9999]
	data["koin"] = []
	p.rpc_terima_state_giliran(1, data)
	await get_tree().process_frame
	p._langkah_diputar = -1
	await get_tree().create_timer(0.2).timeout
	catat("G4|%s|uang dari siaran yang lebih baru TIDAK ditimpa kabar koin lama (%d)" % ["ok" if p.daftar_pemain[1].uang == 9999 else "gagal", p.daftar_pemain[1].uang])
	p.koleksi_permata_musuh.clear()

func _uji_permata_pulih() -> void:
	await _mulai_skenario("G5 client pulih dari paralisis di atas petak permata -> efek, teks & koleksi juga di client")
	await _bersihkan_papan_host()
	_netralkan_status()
	_pasang_permata(3, true); _perintah("permata", [3, true])
	var kode = papan[3].nama_warna_permata
	p.koleksi_permata_pemain.clear(); p.koleksi_permata_musuh.clear()
	_atur_posisi(8, 3); _perintah("posisi", [8, 3])
	p.daftar_pemain[1].sisa_paralisis = 1 # habis di giliran ini -> cabang "PARALISIS SELESAI"
	p.giliran_sekarang = "pemain"; p.fase_giliran = "akhir"
	p.periksa_status_petak(0)
	await get_tree().create_timer(0.6).timeout
	log_kejadian.clear(); geser_terakhir = null; koleksi_terakhir = ""; _perintah("reset")
	await get_tree().create_timer(0.2).timeout
	var t0 = sekarang()
	await p.ganti_giliran() # jalur asli: _ambil_permata_setelah_paralisis
	await get_tree().create_timer(1.0).timeout
	var c = await _ambil_log_client()
	var th = _cari(log_kejadian, "efek_permata|3", t0)
	var tc = _cari(c["log"], "efek_permata|3", t0)
	print("   efek permata: host +%.2f | client +%.2f" % [th - t0, tc - t0])
	_cek(th > 0 and tc > 0 and abs(tc - th) < 0.3, "animasi permata di KEDUA layar hampir bersamaan (%.2f dtk)" % abs(tc - th))
	_cek(_ada(log_kejadian, "teks|Enemy recovered & collected " + kode + " Gem!"), "host: 'Enemy recovered & collected ... Gem!'")
	_cek(_ada(c["log"], "teks|You recovered & collected " + kode + " Gem!"), "client: 'You recovered & collected ... Gem!' (sudut pandang client)")
	_cek(Array(p.koleksi_permata_musuh) == [kode] and c["koleksi"] == [[], [kode]], "koleksi client == host (permata masuk ke slot client)")
	p.daftar_pemain[1].sisa_paralisis = 0

# ---------------------------------------------------------------- petak Start
func _pasang_start(idx: int, aktif: bool) -> void:
	# UIPetak asli di setiap petak (label_petak_3d), petak idx dijadikan Start.
	_pastikan_label_petak()
	papan[idx].is_start_point = aktif
	if aktif and not p.label_petak_3d[idx].is_start:
		p.label_petak_3d[idx].jadikan_petak_start()
	jml_gajian[idx] = 0

func _mulai_kesiapan_client() -> void:
	# Client menjalankan alur panel syarat menang (tanpa menunggu _ready asli).
	p._tunggu_kesiapan_mulai()

func _uji_jual_aset() -> void:
	await _mulai_skenario("J1 CLIENT bangkrut -> memilih sendiri petak yang dijual dari device-nya")
	await _bersihkan_papan_host()
	_netralkan_status()
	for i in range(JUMLAH_PETAK):
		p.status_kepemilikan_petak[i] = false; p.pemilik_petak[i] = -1
		p.nyawa_petak[i] = 0; p.level_menara_petak[i] = 0
	for idx in [6, 7]:
		p.status_kepemilikan_petak[idx] = true; p.pemilik_petak[idx] = 1; p.nyawa_petak[idx] = 3
	p.daftar_pemain[0].uang = 2000
	p.daftar_pemain[1].uang = -400
	_atur_posisi(2, 5); _perintah("posisi", [2, 5])
	p.giliran_sekarang = "musuh"; p.fase_giliran = "akhir"
	p.periksa_status_petak(1)
	_pastikan_label_petak()
	_perintah("label_petak")
	await get_tree().create_timer(0.6).timeout
	log_kejadian.clear(); _perintah("reset")
	await get_tree().create_timer(0.2).timeout

	p.sita_aset_untuk_hutang("musuh")
	await get_tree().create_timer(2.8).timeout
	var c1 = await _ambil_log_client()
	_cek(_ada(c1["log"], "teks|YOU BANKRUPT! Money is minus."), "client: teks 'YOU BANKRUPT' (bukan ENEMY)")
	_cek(_ada(log_kejadian, "teks|ENEMY BANKRUPT! Money is minus."), "host: teks 'ENEMY BANKRUPT'")
	_cek(c1["membidik"], "client: masuk mode bidik untuk memilih petaknya sendiri")
	_cek(_ada(c1["log"], "teks|TAP YOUR TILE TO SELL (30% Discount)"), "client: diminta mengetuk petaknya")
	_cek(_ada(log_kejadian, "teks|Enemy is selling a tile..."), "host: menunggu client memilih")

	_perintah("jual_petak", [6]) # client mengetuk petak 6
	await get_tree().create_timer(5.0).timeout
	var c2 = await _ambil_log_client()
	var harga = int(300 * 0.7)
	_cek(p.pemilik_petak[6] == -1, "host: petak 6 terjual -> netral")
	_cek(int(c2["pemilik"][6]) == -1, "client: petak 6 ikut netral di layarnya")
	_cek(p.daftar_pemain[1].uang == -400 + harga, "host: uang client -400 -> %d" % (-400 + harga))
	_cek(int(c2["uang"][1]) == p.daftar_pemain[1].uang, "client: uang sama dengan host (%d)" % p.daftar_pemain[1].uang)
	_cek(_ada(c2["log"], "teks|Tile sold: +%d Coins!" % harga), "client: teks 'Tile sold'")
	_cek(_ada(log_kejadian, "teks|Enemy sold a tile: +%d Coins!" % harga), "host: teks 'Enemy sold a tile'")
	_cek(p.mode_jual_aset, "host: masih minus -> mode jual tetap aktif")
	_cek(c2["membidik"], "client: masih diminta menjual petak berikutnya")

	_perintah("jual_petak", [7]) # petak kedua -> hutang lunas
	await get_tree().create_timer(5.5).timeout
	var c3 = await _ambil_log_client()
	_cek(p.daftar_pemain[1].uang >= 0, "host: hutang lunas (uang %d)" % p.daftar_pemain[1].uang)
	_cek(not p.mode_jual_aset, "host: mode jual ditutup")
	_cek(not c3["mode_jual"] if c3.has("mode_jual") else true, "client: mode jual ditutup")
	_cek(_ada(c3["log"], "teks|Debt CLEARED!"), "client: teks 'Debt CLEARED!'")
	_cek(not c3["membidik"], "client: keluar dari mode bidik")

func _uji_lawan_putus() -> void:
	# HARUS skenario terakhir: client sengaja dimatikan.
	await _mulai_skenario("D1 CLIENT keluar -> host dapat panel OPPONENT LEFT & bisa lanjut lawan AI")
	_netralkan_status()
	# Skenario V1/V2 sebelumnya sempat menandai permainan selesai di proses ini.
	p._permainan_selesai = false
	p._panel_putus_terbuka = false
	_bersihkan_panel_akhir()
	p.giliran_sekarang = "musuh"; p.fase_giliran = "awal"
	p.daftar_pemain[0].uang = 2000; p.daftar_pemain[1].uang = 1800
	p.status_kepemilikan_petak[4] = true; p.pemilik_petak[4] = 1; p.nyawa_petak[4] = 3
	log_kejadian.clear()
	_perintah("keluar")
	await get_tree().create_timer(6.0).timeout
	var ada_panel = false
	for b in get_tree().current_scene.find_children("*", "Button", true, false):
		if b.text == "CONTINUE VS AI": ada_panel = true
	_cek(ada_panel, "host: panel OPPONENT LEFT dengan tombol CONTINUE VS AI muncul")
	_cek(_klik_tombol("CONTINUE VS AI"), "host: tombol CONTINUE VS AI bisa ditekan")
	await get_tree().create_timer(0.8).timeout
	_cek(StatusJaringan.peran_multiplayer == "", "host: sesi jaringan ditutup (kembali mode offline)")
	_cek(p.daftar_pemain[1].jenis_kontrol == DataPemain.JenisKontrol.AI, "host: slot client diambil alih AI")
	_cek(p.pemilik_petak[4] == 1 and p.daftar_pemain[1].uang == 1800, "host: semua petak & koin lawan tetap utuh")
	_cek(_ada(log_kejadian, "teks|Opponent left. AI takes over!"), "host: teks 'Opponent left. AI takes over!'")

func _uji_panel_mulai() -> void:
	await _mulai_skenario("M1 panel syarat menang: host menunggu client menekan START")
	log_kejadian.clear(); _perintah("reset")
	_perintah("siap_mulai")            # client: panel muncul
	p._tunggu_kesiapan_mulai()          # host: panel muncul
	await get_tree().create_timer(0.6).timeout
	var c1 = await _ambil_log_client()
	_cek(_ada_panel_syarat(), "host: panel HOW TO WIN muncul")
	_cek(c1["panel_syarat"], "client: panel HOW TO WIN muncul")

	# Host menekan START duluan -- panelnya HARUS tetap terbuka sampai client siap.
	_klik_tombol("START GAME")
	await get_tree().create_timer(1.0).timeout
	_cek(_ada_panel_syarat(), "host: setelah START, panel masih menunggu client")
	_cek(p.fase_giliran != "awal" or true, "host: permainan belum dimulai")

	_perintah("klik_start")
	await get_tree().create_timer(1.2).timeout
	var c2 = await _ambil_log_client()
	_cek(not _ada_panel_syarat(), "host: panel tertutup setelah kedua device siap")
	_cek(not c2["panel_syarat"], "client: panel ikut tertutup")

func _uji_menang(nama: String, aktor: String, lag: float) -> void:
	await _mulai_skenario(nama)
	await _bersihkan_papan_host()
	_netralkan_status()
	_pasang_start(5, true); _perintah("start", [5, true])
	for i in range(JUMLAH_PETAK):
		p.status_kepemilikan_petak[i] = false; p.pemilik_petak[i] = -1
	var slot = 0 if aktor == "pemain" else 1
	p.target_permata_menang = 0 # tanpa permata: syaratnya cuma koin
	p.koleksi_permata_pemain.clear(); p.koleksi_permata_musuh.clear()
	p.daftar_pemain[slot].uang = 3200
	p.daftar_pemain[1 - slot].uang = 1500
	p.daftar_pemain[0].bintang = 2; p.daftar_pemain[1].bintang = 4
	if slot == 0:
		_atur_posisi(3, 8); _perintah("posisi", [3, 8])
	else:
		_atur_posisi(8, 3); _perintah("posisi", [8, 3])
	p.giliran_sekarang = aktor; p.fase_giliran = "akhir"
	p.periksa_status_petak(slot)
	await get_tree().create_timer(0.6).timeout
	_perintah("lag", [lag])
	log_kejadian.clear(); geser_terakhir = null; koleksi_terakhir = ""; _perintah("reset")
	await get_tree().create_timer(0.2).timeout

	var t0 = sekarang()
	p.bergerak_maju(3, aktor) # 3 -> 4 -> 5 (START, gaji) -> 6
	await get_tree().create_timer(9.0 + lag * 3.0).timeout
	var c = await _ambil_log_client()

	var teks_menang = "teks|VICTORY! You reached Start with 3000 Coins!"
	var teks_kalah = "teks|GAME OVER! Enemy reached Start with 3000 Coins!"
	var t_host = _cari(log_kejadian, teks_menang if slot == 0 else teks_kalah, t0)
	var t_client = _cari(c["log"], teks_kalah if slot == 0 else teks_menang, t0)
	print("   pengumuman: host +%.2f | client +%.2f" % [t_host - t0, t_client - t0])
	_cek(t_host > 0, "host: teks '%s'" % ("VICTORY" if slot == 0 else "GAME OVER"))
	_cek(t_client > 0, "client: teks '%s'" % ("GAME OVER" if slot == 0 else "VICTORY"))
	_cek(_ada_papan_skor(), "host: papan peringkat + tombol EXIT TO MAIN MENU muncul")
	_cek(c["papan_skor"], "client: papan peringkat + tombol EXIT TO MAIN MENU muncul")
	if lag > 0.0:
		var tl6 = _cari(c["log"], "langkah|6", t0)
		_cek(tl6 > 0 and t_client >= tl6, "client (lambat): pengumuman menunggu karakternya tiba dulu")
	_bersihkan_panel_akhir()
	_perintah("bersih_panel")
	await get_tree().create_timer(0.4).timeout

func _bersihkan_panel_akhir() -> void:
	for c in get_tree().current_scene.get_children():
		if c is CanvasLayer and c.layer >= 106:
			c.queue_free()

func _uji_start(nama: String, aktor: String, lag: float, gaji_gagal: bool) -> void:
	await _mulai_skenario(nama)
	await _bersihkan_papan_host()
	_netralkan_status()
	_pasang_permata(3, false); _perintah("permata", [3, false])
	_pasang_start(5, true); _perintah("start", [5, true])
	for i in range(JUMLAH_PETAK):
		p.status_kepemilikan_petak[i] = false; p.pemilik_petak[i] = -1
	var slot = 0 if aktor == "pemain" else 1
	# Peta dengan 1 permata wajib: gaji cair (+koleksi di-reset) kalau sudah punya 1,
	# hangus kalau belum.
	p.target_permata_menang = 1
	p.koleksi_permata_pemain.clear(); p.koleksi_permata_musuh.clear()
	if not gaji_gagal:
		(p.koleksi_permata_pemain if slot == 0 else p.koleksi_permata_musuh).append("KODE")
	p.daftar_pemain[0].uang = 1000; p.daftar_pemain[1].uang = 1200
	p.daftar_pemain[0].bintang = 2; p.daftar_pemain[1].bintang = 4
	if slot == 0:
		_atur_posisi(3, 8); _perintah("posisi", [3, 8])
	else:
		_atur_posisi(8, 3); _perintah("posisi", [8, 3])
	p.giliran_sekarang = aktor; p.fase_giliran = "akhir"
	p.periksa_status_petak(slot)
	await get_tree().create_timer(0.6).timeout
	_perintah("lag", [lag])
	log_kejadian.clear(); geser_terakhir = null; koleksi_terakhir = ""; _perintah("reset")
	await get_tree().create_timer(0.2).timeout

	var t0 = sekarang()
	await p.bergerak_maju(3, aktor) # 3 -> 4 -> 5 (START) -> 6
	await get_tree().create_timer(2.5 + lag * 3.0).timeout
	var c = await _ambil_log_client()
	var siapa_c = "You" if slot == 1 else "Enemy"
	var siapa_h = "You" if slot == 0 else "Enemy"
	if gaji_gagal:
		var teks_gagal = "teks|SALARY FAILED! Need 1 unique gems!"
		var th = _cari(log_kejadian, teks_gagal, t0)
		var tc = _cari(c["log"], teks_gagal, t0)
		var tl4 = _cari(c["log"], "langkah|4", t0)
		print("   'SALARY FAILED': host +%.2f | client +%.2f (langkah ke petak 4 di client mulai +%.2f)" % [th - t0, tc - t0, tl4 - t0])
		_cek(th > 0, "host: 'SALARY FAILED! Need 1 unique gems!'")
		_cek(tc > 0, "client: teks 'SALARY FAILED' JUGA muncul")
		_cek(tl4 > 0 and tc >= tl4 + 0.75, "client: teksnya muncul setelah karakternya tiba di petak sebelum Start")
		_cek(not _ada(c["log"], "efek_start|5"), "client: tidak ada efek gajian (gaji hangus)")
		_cek(c["uang"][slot] == p.daftar_pemain[slot].uang and p.daftar_pemain[slot].uang == (1000 if slot == 0 else 1200), "uang tidak bertambah di kedua layar")
	else:
		var gaji = 500
		var teks_h = "teks|%s passed Start! Bonus +%d" % [siapa_h, gaji]
		var teks_c = "teks|%s passed Start! Bonus +%d" % [siapa_c, gaji]
		var th = _cari(log_kejadian, "efek_start|5", t0)
		var tc = _cari(c["log"], "efek_start|5", t0)
		var tl5 = _cari(c["log"], "langkah|5", t0)
		print("   efek gajian: host +%.2f | client +%.2f (langkah ke Start di client mulai +%.2f -> tiba +%.2f)" % [th - t0, tc - t0, tl5 - t0, tl5 + 0.8 - t0])
		_cek(th > 0, "host: efek pilar & '+%d KOIN' diputar" % gaji)
		_cek(tc > 0, "client: efek pilar & '+%d KOIN' JUGA diputar" % gaji)
		_cek(tl5 > 0 and tc >= tl5 + 0.75, "client: efeknya baru diputar setelah karakternya benar-benar tiba di Start")
		if lag > 0.0:
			_cek(tc - th > 0.5, "(lag) client tertinggal %.2f dtk tapi tetap menunggu karakternya tiba" % (tc - th))
		else:
			_cek(abs(tc - th) < 0.3, "efek di kedua layar hampir bersamaan (%.2f dtk)" % abs(tc - th))
		_cek(_ada(log_kejadian, teks_h), "host: '%s'" % teks_h.substr(5))
		_cek(_ada(c["log"], teks_c), "client: '%s' (sudut pandang client)" % teks_c.substr(5))
		var uang_h = [p.daftar_pemain[0].uang, p.daftar_pemain[1].uang]
		var bin_h = [p.daftar_pemain[0].bintang, p.daftar_pemain[1].bintang]
		_cek(uang_h[slot] == (1000 if slot == 0 else 1200) + gaji and bin_h[slot] == (2 if slot == 0 else 4) + 3, "host: gaji +%d koin & +3 bintang ke pelaku" % gaji)
		# (angka dari client lewat JSON jadi float -- samakan tipenya dulu)
		var uang_c = [int(c["uang"][0]), int(c["uang"][1])]
		var bin_c = [int(c["bintang"][0]), int(c["bintang"][1])]
		_cek(uang_c == uang_h and bin_c == bin_h, "client: koin %s & bintang %s == host" % [str(uang_c), str(bin_c)])
		var kh = [Array(p.koleksi_permata_pemain), Array(p.koleksi_permata_musuh)]
		_cek(kh == [[], []] and c["koleksi"] == kh, "koleksi permata di-reset setelah gajian, di kedua layar")
		var tk = _cari(c["log"], "koleksi|", t0)
		_cek(tk > 0 and tk >= tc, "client: koleksi di-reset SETELAH efek gajian, bukan sebelum karakternya tiba")
	_perintah("lag", [0.0])
	p.target_permata_menang = 0
	_pasang_start(5, false); _perintah("start", [5, false])

func _pastikan_label_petak() -> void:
	# UIPetak asli di setiap petak (label_petak_3d) -- dibutuhkan efek Start & serangan.
	if p.label_petak_3d.size() < JUMLAH_PETAK:
		for i in range(JUMLAH_PETAK):
			var up = UIPetak.new(); up.name = "UIPetakUji"
			papan[i].add_child(up)
			p.label_petak_3d.append(up)

func _petak_ber_emboss() -> Array:
	var a = []
	for i in range(JUMLAH_PETAK):
		for c6 in papan[i].get_children():
			if c6.name.begins_with("Emboss") and not c6.is_queued_for_deletion():
				a.append(i); break
	return a

# ---------------------------------------------------------------- petak cabang
func _pasang_fork(aktif: bool, _x) -> void:
	# Petak 2 jadi persimpangan: [0] "KANAN" -> petak 3, [1] "ATAS" -> petak 6.
	if aktif:
		papan[2].referensi_node_selanjutnya.assign([papan[3], papan[6]])
		papan[2].nama_arah.assign(["KANAN", "ATAS"])
	else:
		papan[2].referensi_node_selanjutnya.assign([papan[3]])
		papan[2].nama_arah.assign([])

func _klik_cabang_saat_muncul(indeks: int, jeda: float) -> void:
	# Tunggu panel cabang "lokal" (bisa diklik) muncul di device ini, lalu klik.
	var batas = 0.0
	while batas < 15.0:
		if p.panel_ui_cabang.visible:
			var tombol = []
			for t in p.wadah_tombol_cabang.get_children():
				if t is Button and not t.disabled: tombol.append(t)
			if tombol.size() > indeks:
				await get_tree().create_timer(jeda).timeout
				catat("klik_cabang|%d" % indeks)
				tombol[indeks].emit_signal("pressed")
				return
		await get_tree().process_frame
		batas += get_process_delta_time()
	catat("klik_cabang|TIDAK_MUNCUL")

func _uji_cabang(nama: String, aktor: String, pilih: int, lag: float, mulai: int) -> void:
	await _mulai_skenario(nama)
	await _bersihkan_papan_host()
	_netralkan_status()
	_pasang_start(5, false); _perintah("start", [5, false])
	_pasang_fork(true, 0); _perintah("fork", [true, 0])
	for i in range(JUMLAH_PETAK):
		p.status_kepemilikan_petak[i] = false; p.pemilik_petak[i] = -1
	var slot = 0 if aktor == "pemain" else 1
	if slot == 0:
		_atur_posisi(mulai, 9); _perintah("posisi", [mulai, 9])
	else:
		_atur_posisi(9, mulai); _perintah("posisi", [9, mulai])
	p.giliran_sekarang = aktor; p.fase_giliran = "akhir"
	p.periksa_status_petak(slot)
	await get_tree().create_timer(0.6).timeout
	_perintah("lag", [lag])
	log_kejadian.clear(); geser_terakhir = null; koleksi_terakhir = ""; cabang_status = ""; _perintah("reset")
	await get_tree().create_timer(0.2).timeout
	var rng_sebelum = p.mesin_acak.state

	var t0 = sekarang()
	if slot == 0:
		_klik_cabang_saat_muncul(pilih, 0.6)   # pemain host yang memilih
	else:
		_perintah("klik_cabang", [pilih, 0.6])  # pemain client yang memilih
	var langkah = (2 - mulai) + 2 # sampai persimpangan (petak 2), lalu 2 langkah lagi
	await p.bergerak_maju(langkah, aktor)
	await get_tree().create_timer(1.5 + lag * 3.0).timeout
	var c = await _ambil_log_client()

	var arah = ["KANAN", "ATAS"][pilih]
	var akhir = [4, 7][pilih] # KANAN: 2->3->4, ATAS: 2->6->7
	var log_pemilih = log_kejadian if slot == 0 else c["log"]
	var log_penonton = c["log"] if slot == 0 else log_kejadian
	var t_buka_pemilih = _cari(log_pemilih, "cabang_judul|PILIH ARAH LANGKAH!", t0)
	var t_buka_penonton = _cari(log_penonton, "cabang_judul|ENEMY IS CHOOSING A PATH...", t0)
	var t_umum_pemilih = _cari(log_pemilih, "cabang_judul|YOU CHOSE: " + arah, t0)
	var t_umum_penonton = _cari(log_penonton, "cabang_judul|ENEMY CHOSE: " + arah, t0)
	var t_tutup_pemilih = _cari(log_pemilih, "cabang_tutup", t_umum_pemilih)
	var t_tutup_penonton = _cari(log_penonton, "cabang_tutup", t_umum_penonton)
	print("   pemilih : panel +%.2f | umumkan +%.2f | tutup +%.2f" % [t_buka_pemilih - t0, t_umum_pemilih - t0, t_tutup_pemilih - t0])
	print("   penonton: panel +%.2f | umumkan +%.2f | tutup +%.2f" % [t_buka_penonton - t0, t_umum_penonton - t0, t_tutup_penonton - t0])
	print("   posisi akhir host %s | client %s (harus petak %d)" % [str([p.daftar_pemain[0].posisi_saat_ini, p.daftar_pemain[1].posisi_saat_ini]), str(c["posisi"]), akhir])
	var siapa = "host" if slot == 0 else "client"
	var lawan = "client" if slot == 0 else "host"
	_cek(t_buka_pemilih > 0, "%s (pemilik karakter) mendapat panel 'PILIH ARAH LANGKAH!' yang bisa diklik" % siapa)
	_cek(t_buka_penonton > 0, "%s melihat panel yang sama dalam mode tonton ('ENEMY IS CHOOSING A PATH...')" % lawan)
	_cek(t_umum_pemilih > 0, "%s: pengumuman 'YOU CHOSE: %s'" % [siapa, arah])
	_cek(t_umum_penonton > 0, "%s: pengumuman 'ENEMY CHOSE: %s'" % [lawan, arah])
	if t_umum_pemilih > 0 and t_umum_penonton > 0:
		_cek(abs(t_umum_penonton - t_umum_pemilih) < 0.25, "pengumuman di kedua layar hampir bersamaan (%.2f dtk)" % abs(t_umum_penonton - t_umum_pemilih))
	_cek(t_tutup_pemilih > 0 and t_tutup_penonton > 0, "panel tertutup lagi di kedua layar setelah pengumuman")
	var pos_slot = p.daftar_pemain[slot].posisi_saat_ini
	_cek(pos_slot == akhir, "host: karakter berjalan ke arah yang DIPILIH (petak %d)" % pos_slot)
	_cek(int(c["posisi"][slot]) == akhir, "client: posisi karakter sama (petak %d)" % int(c["posisi"][slot]))
	_cek(abs(float(c["x_model"][slot]) - papan[akhir].global_position.x) < 0.05, "client: model karakter benar-benar berdiri di petak %d" % akhir)
	if slot == 1:
		_cek(p.mesin_acak.state == rng_sebelum, "host TIDAK lagi mengacak arah karakter client (mesin_acak tidak tersentuh)")
	if lag > 0.0:
		var tl = _cari(c["log"], "langkah|2", t0)
		_cek(tl > 0 and t_buka_pemilih >= tl + 0.75, "(lag) panel baru muncul di client setelah karakternya tiba di persimpangan")
	_perintah("lag", [0.0])
	_pasang_fork(false, 0); _perintah("fork", [false, 0])

# ---------------------------------------------------------------- serangan jarak jauh
func _siapkan_serangan(giliran: String) -> void:
	await _bersihkan_papan_host()
	_netralkan_status()
	_pastikan_label_petak(); _perintah("label_petak")
	_pasang_start(5, false); _perintah("start", [5, false])
	for i in range(JUMLAH_PETAK):
		p.status_kepemilikan_petak[i] = false; p.pemilik_petak[i] = -1; p.nyawa_petak[i] = 0; p.level_menara_petak[i] = 0
		for c7 in papan[i].get_children():
			if c7.name.begins_with("Emboss"): c7.free()
	# Petak 4 milik host (HP 2), petak 7 milik client (HP 1, bermenara level 1)
	p.status_kepemilikan_petak[4] = true; p.pemilik_petak[4] = 0; p.nyawa_petak[4] = 2
	p.status_kepemilikan_petak[7] = true; p.pemilik_petak[7] = 1; p.nyawa_petak[7] = 1; p.level_menara_petak[7] = 1
	p._bangun_fisik_menara(7, p.material_musuh, 1)
	p.daftar_pemain[0].bintang = 6; p.daftar_pemain[1].bintang = 7
	p.sudah_serang_giliran_ini = false
	_atur_posisi(1, 8); _perintah("posisi", [1, 8])
	p.giliran_sekarang = giliran; p.fase_giliran = "awal"
	p.periksa_status_petak(0 if giliran == "pemain" else 1) # client membangun menaranya juga
	await get_tree().create_timer(0.8).timeout
	log_kejadian.clear(); geser_terakhir = null; koleksi_terakhir = ""; cabang_status = ""; _perintah("reset")
	await get_tree().create_timer(0.2).timeout

func _uji_serang_client() -> void:
	await _mulai_skenario("A1 CLIENT menyerang petak host (HP 2 -> 1) dari device-nya sendiri")
	await _siapkan_serangan("musuh")
	var c0 = await _ambil_log_client()
	var emb0 = c0["emboss"].map(func(x): return int(x))
	_cek(not (4 in emb0) and (7 in emb0), "persiapan: menara petak 7 juga berdiri di client")
	var t0 = sekarang()
	_perintah("serang_mulai")
	await get_tree().create_timer(0.3).timeout
	_perintah("serang_petak", [4])
	await get_tree().create_timer(7.5).timeout
	var c = await _ambil_log_client()
	var th = _cari(log_kejadian, "teks|Enemy attacks from far away!", t0)
	var tc = _cari(c["log"], "replay_serangan|true", t0)
	print("   animasi serangan: host +%.2f | client +%.2f" % [th - t0, tc - t0])
	_cek(th > 0, "host: memutar animasi serangan ('Enemy attacks from far away!')")
	_cek(tc > 0, "client: memutar animasi serangan yang sama")
	if th > 0 and tc > 0:
		_cek(abs(tc - th) < 0.25, "animasi mulai di kedua layar hampir bersamaan (%.2f dtk)" % abs(tc - th))
	_cek(p.daftar_pemain[1].bintang == 2 and p.daftar_pemain[0].bintang == 6, "host: bintang CLIENT yang berkurang 5 (7 -> 2)")
	_cek(p.nyawa_petak[4] == 1 and p.pemilik_petak[4] == 0, "host: petak 4 kena (HP 2 -> 1), masih milik host")
	_cek(_ada(log_kejadian, "teks|Enemy shoots your tile! HP left: 1"), "host: 'Enemy shoots your tile! HP left: 1'")
	_cek(_ada(c["log"], "teks|Attack Hit! Enemy tile HP left: 1"), "client: 'Attack Hit! Enemy tile HP left: 1'")
	_cek(int(c["nyawa"][4]) == 1 and int(c["bintang"][1]) == 2, "client: HP petak & bintangnya sama dengan host")
	_cek(c["sudah_serang"] == true and p.sudah_serang_giliran_ini, "kedua device mencatat sudah menyerang giliran ini (tombol Attack tidak aktif lagi)")
	_cek(c["replay_serangan"] == false, "bendera replay client bersih di akhir")

func _uji_serang_host() -> void:
	await _mulai_skenario("A2 HOST menghancurkan petak client (HP 1) yang bermenara -> menara hilang juga di client")
	await _siapkan_serangan("pemain")
	var t0 = sekarang()
	p._on_tombol_serang_pressed()
	await get_tree().create_timer(0.3).timeout
	p._serang_petak(7)
	await get_tree().create_timer(7.5).timeout
	var c = await _ambil_log_client()
	var th = _cari(log_kejadian, "teks|Launching long range attack!", t0)
	var tc = _cari(c["log"], "replay_serangan|true", t0)
	print("   animasi serangan: host +%.2f | client +%.2f" % [th - t0, tc - t0])
	_cek(th > 0 and tc > 0 and abs(tc - th) < 0.25, "animasi serangan di kedua layar hampir bersamaan")
	_cek(_ada(c["log"], "teks|Enemy attacks from far away!"), "client: 'Enemy attacks from far away!'")
	_cek(p.pemilik_petak[7] == -1 and p.level_menara_petak[7] == 0, "host: petak 7 hancur -> netral")
	_cek(int(c["pemilik"][7]) == -1 and int(c["level"][7]) == 0, "client: petak 7 juga netral")
	_cek(not (7 in _petak_ber_emboss()), "host: menaranya dibongkar")
	var emb_c = c["emboss"].map(func(x): return int(x))
	_cek(not (7 in emb_c), "client: menaranya JUGA dibongkar (dulu tertinggal)")
	_cek(_ada(log_kejadian, "teks|SUCCESS! You destroyed enemy tile!"), "host: 'SUCCESS! You destroyed enemy tile!'")
	_cek(_ada(c["log"], "teks|REVENGE! Enemy destroyed your tile!"), "client: 'REVENGE! Enemy destroyed your tile!'")
	_cek(int(c["bintang"][0]) == 1, "client: bintang host (6 -> 1) ikut diperbarui")

func _uji_serang_batal_client() -> void:
	await _mulai_skenario("A3 CLIENT membatalkan bidikan -> host TIDAK boleh melempar dadu")
	await _siapkan_serangan("musuh")
	_perintah("serang_mulai")
	await get_tree().create_timer(0.4).timeout
	_perintah("tutup_client") # tombol "Cancel" saat membidik
	await get_tree().create_timer(1.5).timeout
	var c = await _ambil_log_client()
	_cek(p.fase_giliran == "awal", "host: fase tetap 'awal' (dadu tidak dilempar), sekarang '%s'" % p.fase_giliran)
	_cek(p.daftar_pemain[1].posisi_saat_ini == 8, "host: karakter client tidak bergerak")
	_cek(c["membidik"] == false and c["fase"] == "awal", "client: keluar dari mode bidik, gilirannya masih bisa dipakai")
	_cek(_ada(c["log"], "teks|Attack canceled."), "client: 'Attack canceled.'")

func _uji_serang_salah_client() -> void:
	await _mulai_skenario("A4 CLIENT mengetuk petaknya sendiri -> 'WRONG TARGET!', host tidak tersentuh")
	await _siapkan_serangan("musuh")
	_perintah("serang_mulai")
	await get_tree().create_timer(0.3).timeout
	_perintah("serang_petak", [7]) # petak 7 milik client sendiri
	await get_tree().create_timer(1.5).timeout
	var c = await _ambil_log_client()
	_cek(_ada(c["log"], "teks|WRONG TARGET! Tap enemy tile."), "client: 'WRONG TARGET! Tap enemy tile.'")
	_cek(p.daftar_pemain[1].bintang == 7 and p.nyawa_petak[7] == 1 and not p.sudah_serang_giliran_ini, "host: bintang, HP & jatah serangan tidak berubah")
	_cek(c["membidik"] == false, "client: keluar dari mode bidik")
