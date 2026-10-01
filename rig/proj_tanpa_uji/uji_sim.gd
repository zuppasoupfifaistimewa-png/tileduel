extends Node3D
# SIMULASI PERMAINAN PENUH (solo) yang DETERMINISTIK -- jalankan dengan
# --fixed-fps supaya setiap kejadian jatuh di frame yang sama di setiap run.
# Dipakai untuk membandingkan kode lama & kode baru pada permainan 1v1: jejak
# (keadaan tiap pergantian giliran + urutan teks) harus identik.
#   argumen (setelah --): pemain=2 manusia=1 seed=7 giliran=80 jejak=/path.txt
# manusia=1 : slot 0 dimainkan "robot" lewat tombol-tombol UI asli.
# manusia=0 : semua slot AI (khusus kode baru).
const JUMLAH_PETAK = 16

var n_pemain = 2
var n_manusia = 1
var benih = 7
var batas_giliran = 80
var berkas_jejak = ""
var p
var ui
var papan = []
var jejak = []
var teks_terakhir = ""
var giliran_terakhir = ""
var jumlah_giliran = 0
var hitung_aksi = 0
var periksa_terakhir = -1
var selesai = false
var detik_diam = 0.0
var detik_total = 0.0
var mulai = false
var uang_awal = 2500
var mode_quick_uji = false # Fase 1: quick=1 -> aturan Quick Match (ronde, kekayaan, dadu 2-12)
var uji_giliran_slot = [0, 0, 0, 0] # Fase 2 (T5): awal giliran per slot, dihitung robot sendiri

func _ready():
	for a in OS.get_cmdline_user_args():
		if a.begins_with("pemain="): n_pemain = int(a.substr(7))
		if a.begins_with("manusia="): n_manusia = int(a.substr(8))
		if a.begins_with("seed="): benih = int(a.substr(5))
		if a.begins_with("giliran="): batas_giliran = int(a.substr(8))
		if a.begins_with("jejak="): berkas_jejak = a.substr(6)
		if a.begins_with("uang="): uang_awal = int(a.substr(5))
		if a == "quick=1": mode_quick_uji = true
	Engine.time_scale = 4.0
	StatusJaringan.peran_multiplayer = ""
	seed(benih)
	_bangun()
	if mode_quick_uji:
		p.mode_quick = true
		p.batas_ronde = StatusJaringan.BATAS_RONDE_QUICK[n_pemain]
		p.ronde_sekarang = 1
		p.jumlah_permata_peta = 2
		p.target_permata_menang = 1
		p.mode_rolet_double = true
	await get_tree().process_frame
	await get_tree().process_frame
	# Semua sumber acak dipatok (setelah _ready milik ui_elemen memanggil randomize).
	seed(benih * 7919 + 13)
	p.mesin_acak.seed = benih * 31 + 1
	ui.rng.seed = benih * 17 + 3
	ui.rng_visual.seed = 5
	# Fase 4 A7: papan uji dibangun sendiri (tanpa _siapkan_peta_dan_mulai, lihat
	# komentar _bangun di atas), jadi role/jebakan_dibawa/build TIDAK PERNAH
	# terisi kalau tidak dipanggil manual di sini -- AiJebakan.pertimbangkan
	# (ai_jebakan.gd) tidak pernah punya apa pun untuk dipertimbangkan tanpa ini
	# (loopnya atas data.jebakan_dibawa), jadi AI tidak akan pernah memasang
	# jebakan sama sekali di uji ini. Dipanggil SESUDAH mesin_acak diberi benih
	# di atas supaya role yang terpilih tetap deterministik per seed. has_method
	# dijaga supaya rig lama (sebelum Fase 4) tetap jalan tanpa fungsi ini.
	if p.has_method("_siapkan_role_semua"):
		p._siapkan_role_semua()
	jejak.append("MULAI pemain=%d manusia=%d seed=%d" % [n_pemain, n_manusia, benih])
	p.fase_giliran = "awal"
	p.giliran_sekarang = "pemain"
	mulai = true
	if n_manusia >= 1:
		p.teks_dadu.text = "YOUR TURN! Choose Action or Roll Dice."
		p.periksa_status_petak(0)
	else:
		var skrip_ai = load("res://ai_musuh.gd")
		skrip_ai.logika_ai_fase_awal(p, 0)

func _pos_ring(i: int) -> Vector3:
	# 16 petak mengelilingi persegi 5x5 (jarak antar petak 4.0).
	if i < 4: return Vector3(i * 4.0, 0, 0)
	if i < 8: return Vector3(16.0, 0, (i - 4) * 4.0)
	if i < 12: return Vector3(16.0 - (i - 8) * 4.0, 0, 16.0)
	return Vector3(0, 0, 16.0 - (i - 12) * 4.0)

func _buat_anim() -> AnimationPlayer:
	var ap = AnimationPlayer.new(); ap.name = "AnimationPlayer"
	var lib = AnimationLibrary.new()
	for n in ["idle", "run"]:
		var a = Animation.new(); a.length = 1.0; a.loop_mode = Animation.LOOP_LINEAR
		lib.add_animation(n, a)
	ap.add_animation_library("", lib)
	return ap

func _bangun() -> void:
	var node_papan = Node3D.new(); node_papan.name = "Papan"; add_child(node_papan)
	for i in range(JUMLAH_PETAK):
		var t = preload("res://petak_papan.gd").new(); t.name = "Petak%d" % i
		if i == 0: t.is_start_point = true
		if i == 4 or i == 13:
			t.is_petak_permata = true
			t.pilihan_warna_permata = 0 if i == 4 else 1
		if i == 2 or i == 9: t.is_petak_kartu = true
		var lantai = CSGBox3D.new(); lantai.name = "Lantai"; lantai.size = Vector3(3.6, 0.2, 3.6)
		t.add_child(lantai)
		node_papan.add_child(t)
		t.global_position = _pos_ring(i)
		papan.append(t)
	for i in range(JUMLAH_PETAK):
		papan[i].referensi_node_selanjutnya.assign([papan[(i + 1) % JUMLAH_PETAK]])
	# Persimpangan di petak 6: KANAN -> 7, PINTAS -> 11
	papan[6].referensi_node_selanjutnya.assign([papan[7], papan[11]])
	papan[6].nama_arah.assign(["KANAN", "PINTAS"])

	var musuh = Node3D.new(); musuh.name = "Musuh"; add_child(musuh)
	var beras_m = Node3D.new(); beras_m.name = "beras"; musuh.add_child(beras_m)
	beras_m.add_child(_buat_anim())

	var cl = CanvasLayer.new(); cl.name = "CanvasLayer"; add_child(cl)
	for n in ["TeksDadu", "TeksUang", "TeksBintang"]:
		var l = Label.new(); l.name = n; cl.add_child(l)
	var menu = Control.new(); menu.name = "MenuAksi"; menu.visible = false; cl.add_child(menu)
	var vb = VBoxContainer.new(); vb.name = "VBoxContainer"; menu.add_child(vb)
	for n in ["TombolBeli", "TombolBangun", "TombolSerang", "TombolTanah", "TombolPetir", "TombolTutup"]:
		var b = Button.new(); b.name = n; vb.add_child(b)
	var r = load("res://uji_rolet_stub.gd").new(); r.name = "Rolet"; cl.add_child(r)
	ui = load("res://ui_elemen.gd").new(); ui.name = "UIElemen"; ui.size = Vector2(1280, 720)
	ui.visible = false
	cl.add_child(ui)
	var kam = Camera3D.new(); kam.name = "Camera3D"; add_child(kam)

	p = load("res://uji_sim_pemain.gd").new(); p.name = "Pemain"
	var beras_p = Node3D.new(); beras_p.name = "beras"; p.add_child(beras_p)
	beras_p.add_child(_buat_anim())
	add_child(p)

	vb.get_node("TombolBeli").pressed.connect(p._on_tombol_beli_pressed)
	vb.get_node("TombolBangun").pressed.connect(p._on_tombol_bangun_pressed)
	vb.get_node("TombolSerang").pressed.connect(p._on_tombol_serang_pressed)
	vb.get_node("TombolTutup").pressed.connect(p._on_tombol_tutup_pressed)
	UiDinamis.buat_tombol_jebakan_via_kode(p)
	UiDinamis.buat_ui_cabang_dasar(p)

	p.rute_papan.assign(papan)
	var f = []; f.resize(JUMLAH_PETAK); f.fill(false); p.status_kepemilikan_petak = f
	var pp = []; pp.resize(JUMLAH_PETAK); pp.fill(-1); p.pemilik_petak.assign(pp)
	var z1 = []; z1.resize(JUMLAH_PETAK); z1.fill(0); p.level_menara_petak = z1
	var z2 = []; z2.resize(JUMLAH_PETAK); z2.fill(0); p.nyawa_petak = z2
	var z3: Array[int] = []; z3.resize(JUMLAH_PETAK); z3.fill(0); p.berhenti_di_petak_sendiri = z3
	var daftar = []
	for s in range(n_pemain):
		var jenis = DataPemain.JenisKontrol.AI
		if s == 0 and n_manusia >= 1: jenis = DataPemain.JenisKontrol.MANUSIA_LOKAL
		var d = DataPemain.new(jenis, "P%d" % (s + 1))
		d.bintang = 4
		d.uang = uang_awal
		daftar.append(d)
	p.daftar_pemain.assign(daftar)
	p.slot_lokal = 0
	p.target_permata_menang = 2
	p.batas_kamera_min = Vector2(-15, -15)
	p.batas_kamera_max = Vector2(31, 31)
	for i in range(JUMLAH_PETAK):
		var up = UIPetak.new()
		papan[i].add_child(up)
		p.label_petak_3d.append(up)
		if i == 0: up.jadikan_petak_start()
		if papan[i].referensi_node_selanjutnya.size() > 1:
			up.jadikan_petak_cabang(papan[i].nama_arah)
	if p.has_method("_siapkan_slot_pemain"):
		p._siapkan_slot_pemain()
	# Fase 2: papan uji dibangun sendiri (tanpa _siapkan_peta_dan_mulai) -> statistik di-reset di sini.
	if p.has_method("_reset_statistik"):
		p._reset_statistik()
	p.anim_pemain.play("idle")
	p.anim_musuh.play("idle")
	p.target_kamera = p.model_pemain
	p.update_semua_label_petak()
	p.update_ui_status()

# ---------------------------------------------------------------- jejak
func _snap() -> String:
	var s = "G%d|%s|%s|" % [jumlah_giliran, p.giliran_sekarang, p.fase_giliran]
	for d in p.daftar_pemain:
		s += "[%d,%d,%d,g%d,p%d,b%d,k%d]" % [d.posisi_saat_ini, d.uang, d.bintang, d.sisa_gelembung, d.sisa_paralisis, d.sisa_bakar, d.inventaris_kartu.size()]
	var own = []
	var lv = []
	var hp = []
	for i in range(JUMLAH_PETAK):
		own.append(str(p.pemilik_petak[i]))
		lv.append(str(p.level_menara_petak[i]))
		hp.append(str(p.nyawa_petak[i]))
	s += "|o:" + ",".join(own) + "|l:" + ",".join(lv) + "|h:" + ",".join(hp)
	if mode_quick_uji:
		s += "|r%d" % p.ronde_sekarang
	var jb = []
	for i in range(JUMLAH_PETAK):
		for nm in ["JebakanAir", "JebakanApi", "JebakanAngin", "JebakanPetir", "JebakanTanah", "KoinTercecer"]:
			var n = papan[i].get_node_or_null(nm)
			if n and not n.is_queued_for_deletion():
				jb.append("%d%s" % [i, nm.substr(7, 3) if nm != "KoinTercecer" else "Koi"])
	s += "|j:" + ",".join(jb)
	return s

func _tulis_dan_keluar(alasan: String) -> void:
	if selesai: return
	selesai = true
	jejak.append("SELESAI|" + alasan + "|" + _snap())
	if mode_quick_uji and p.get("_permainan_selesai"):
		# Periksa ulang pemenang dari keadaan akhir (hitungan terpisah dari pemain.gd).
		var kaya = []
		var petak = []
		for sl in range(p.jumlah_pemain()):
			var k = p.daftar_pemain[sl].uang
			var n = 0
			for i in range(p.rute_papan.size()):
				if p.status_kepemilikan_petak[i] and p.pemilik_petak[i] == sl:
					n += 1
					k += 300 + (500 if p.level_menara_petak[i] >= 1 else 0) + (800 if p.level_menara_petak[i] == 2 else 0)
			kaya.append(k)
			petak.append(n)
		var pm = p._slot_pemenang_akhir
		var cek = "OK"
		if p._alasan_akhir.begins_with("ronde"):
			for sl in range(kaya.size()):
				if kaya[sl] > kaya[pm] or (kaya[sl] == kaya[pm] and petak[sl] > petak[pm]):
					cek = "SALAH"
			if p.ronde_sekarang != p.batas_ronde:
				cek = "SALAH_RONDE"
		var giliran_harus = p.batas_ronde * p.jumlah_pemain()
		jejak.append("AKHIR|alasan=%s|pemenang=%d|ronde=%d/%d|kaya=%s|petak=%s|cek=%s|giliran=%d/%d" % [p._alasan_akhir, pm, p.ronde_sekarang, p.batas_ronde, str(kaya), str(petak), cek, jumlah_giliran, giliran_harus])
		print("AKHIR alasan=%s pemenang=%d ronde=%d/%d kaya=%s cek=%s giliran=%d/%d" % [p._alasan_akhir, pm, p.ronde_sekarang, p.batas_ronde, str(kaya), cek, jumlah_giliran, giliran_harus])
	_cek_statistik()
	if berkas_jejak != "":
		var f = FileAccess.open(berkas_jejak, FileAccess.WRITE)
		f.store_string("\n".join(jejak) + "\n")
		f.close()
	print("SIM %s giliran=%d detik=%.0f" % [alasan, jumlah_giliran, detik_total])
	get_tree().quit()

func _process(delta):
	if p == null or selesai or not mulai: return
	detik_total += delta
	detik_diam += delta
	var teks = p.teks_dadu.text
	if teks != teks_terakhir:
		teks_terakhir = teks
		jejak.append("T|" + teks.replace("\n", " / "))
		detik_diam = 0.0
	if p.giliran_sekarang != giliran_terakhir:
		giliran_terakhir = p.giliran_sekarang
		jumlah_giliran += 1
		var sl_giliran = p._slot_dari_aktor(p.giliran_sekarang)
		if sl_giliran >= 0 and sl_giliran < uji_giliran_slot.size():
			uji_giliran_slot[sl_giliran] += 1
		jejak.append(_snap())
		detik_diam = 0.0
		if jumlah_giliran > batas_giliran:
			_tulis_dan_keluar("BATAS_GILIRAN")
			return
	if p.get("_permainan_selesai"):
		_tulis_dan_keluar("MENANG")
		return
	if detik_diam > 240.0:
		_tulis_dan_keluar("MACET")
		return
	_robot()

# ---------------------------------------------------------------- robot pemain manusia (slot 0)
func _semua_ui_kartu() -> Array:
	var hasil = []
	for n in find_children("*", "Node3D", true, false):
		if n.get_script() == preload("res://petak_kartu.gd"):
			hasil.append(n)
	return hasil

func _robot() -> void:
	if n_manusia < 1: return
	# 1. Duel: pilih elemen (ketuk dua kali = konfirmasi)
	if ui.visible and ui.fase_duel == "PILIH_PEMAIN":
		var el = ["api", "air", "angin", "tanah", "petir"][hitung_aksi % 5]
		var t = ui.tombol_elemen[el]
		if not t.disabled:
			hitung_aksi += 1
			jejak.append("R|elemen|" + el)
			t.pressed.emit(); t.pressed.emit()
			return
	# 2. Lempar koin penentu seri
	if ui.tombol_kepala.visible:
		var b = ui.tombol_kepala if not ui.tombol_kepala.disabled else ui.tombol_ekor
		if not b.disabled:
			hitung_aksi += 1
			jejak.append("R|koin")
			b.pressed.emit()
			return
	# 3. Layar kartu (gacha / buang / pedang) yang bisa diklik
	for pk in _semua_ui_kartu():
		if pk._gacha_tombol.size() > 0 and not pk._kartu_sudah_dibuka and not pk._gacha_tombol[0].disabled:
			hitung_aksi += 1
			jejak.append("R|gacha|%d" % (hitung_aksi % 3))
			pk._gacha_tombol[hitung_aksi % 3].pressed.emit()
			return
		if pk._buang_tombol.size() > 0 and not pk._buang_sudah_dipilih and not pk._buang_tombol[0].disabled:
			hitung_aksi += 1
			jejak.append("R|buang")
			pk._buang_tombol[0].pressed.emit()
			return
		if pk._pedang_tombol.size() > 0 and not pk._pedang_sudah_dipilih and not pk._pedang_tombol[0].disabled:
			hitung_aksi += 1
			if hitung_aksi % 2 == 0:
				jejak.append("R|pedang|0")
				pk._pedang_tombol[0].pressed.emit()
			else:
				jejak.append("R|pedang|simpan")
				pk._pedang_tombol_batal.pressed.emit()
			return
	# 4. Persimpangan
	if p.panel_ui_cabang.visible:
		var tombol = []
		for t in p.wadah_tombol_cabang.get_children():
			if t is Button and not t.disabled and not t.is_queued_for_deletion(): tombol.append(t)
		if tombol.size() > 0:
			hitung_aksi += 1
			jejak.append("R|cabang|%d" % (hitung_aksi % tombol.size()))
			tombol[hitung_aksi % tombol.size()].pressed.emit()
		return
	# 5. Jual aset karena hutang
	if p.mode_jual_aset and p.mode_membidik:
		# Semua petak papan (peta asli > 16 petak; papan sim = 16 -> sama seperti dulu).
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
		if p.tombol_serang.visible and not p.tombol_serang.disabled and hitung_aksi % 3 == 0:
			for i in range(JUMLAH_PETAK):
				if p.pemilik_petak[i] >= 0 and p.pemilik_petak[i] != p.slot_lokal:
					jejak.append("R|serang|%d" % i)
					p.tombol_serang.pressed.emit()
					p._serang_petak(i)
					return
		jejak.append("R|dadu")
		p.tombol_tutup.pressed.emit()
		return
	# fase akhir
	if p.tombol_set_trap.visible and not p.tombol_set_trap.disabled and d.bintang >= 2 and hitung_aksi % 4 == 1:
		p.tombol_set_trap.pressed.emit()
		# Fase 4 A3: tombol jebakan yang tidak dibawa role/roster sekarang
		# disembunyikan (.visible = _jebakan_boleh(...)), bukan cuma disabled --
		# robot HARUS ikut menyaring .visible juga, jangan lagi menekan tombol
		# tersembunyi secara bergiliran seperti sebelum Fase 4.
		var kandidat = []
		for b in [p.tombol_trap_air, p.tombol_trap_api, p.tombol_trap_angin, p.tombol_trap_petir]:
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

# ---------------------------------------------------------------- T5 (Fase 2)
func _cek_statistik() -> void:
	# Statistik pemain.gd dibandingkan dengan hitungan robot sendiri. Dicetak ke log saja
	# (TIDAK masuk jejak -- jejak dibandingkan dengan kode lama di T1).
	var st = p.get("statistik_slot")
	if st == null or st.is_empty():
		return
	var salah = []
	var dadu_robot = p.get("uji_dadu")
	var duel_robot = p.get("uji_duel")
	var jum_menang = 0
	var jum_kalah = 0
	var jum_kena = 0
	for sl in range(p.jumlah_pemain()):
		var s = st[sl]
		if int(s["giliran"]) != uji_giliran_slot[sl]:
			salah.append("giliran%d=%d/%d" % [sl, int(s["giliran"]), uji_giliran_slot[sl]])
		if dadu_robot != null and int(s["dadu_kali"]) != int(dadu_robot[sl]):
			salah.append("dadu%d=%d/%d" % [sl, int(s["dadu_kali"]), int(dadu_robot[sl])])
		jum_menang += int(s["duel_menang"])
		jum_kalah += int(s["duel_kalah"])
		jum_kena += int(s["jebakan_kena"])
	if duel_robot != null and (jum_menang != int(duel_robot) or jum_kalah != int(duel_robot)):
		salah.append("duel=%d/%d/%d" % [jum_menang, jum_kalah, int(duel_robot)])
	var teks_jebakan = 0
	for baris in jejak:
		for kunci in ["TRAPPED! Geyser", "WIND TRAP!", "FIRE TRAP!", "LIGHTNING TRAP!", "EARTH TRAP ACTIVATED"]:
			if baris.begins_with("T|") and baris.contains(kunci):
				teks_jebakan += 1
	var ringkas = []
	for sl in range(p.jumlah_pemain()):
		ringkas.append("g%d d%d m%d k%d j%d" % [int(st[sl]["giliran"]), int(st[sl]["dadu_kali"]), int(st[sl]["duel_menang"]), int(st[sl]["jebakan_kena"]), int(st[sl]["jebakan_pasang"])])
	print("STAT_CEK %s duel=%s kena=%d teks_jebakan=%d | %s %s" % ["OK" if salah.is_empty() else "SALAH", str(duel_robot), jum_kena, teks_jebakan, " ; ".join(ringkas), " ".join(salah)])
