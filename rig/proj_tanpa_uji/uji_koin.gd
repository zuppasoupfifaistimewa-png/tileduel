extends Node
# Simulasi 2 device dalam 1 proses: host_ui & client_ui = dua salinan ui_elemen.gd
# asli. Relay di bawah meniru persis handler baru di pemain.gd (+ latensi jaringan).
var UiElemen = preload("res://ui_elemen.gd")
var host_ui
var client_ui
var mesin = RandomNumberGenerator.new()
var koin_host = ""
var koin_client = ""
var latensi = 0.15
var gagal_total = 0

func _ready():
	Engine.time_scale = 6.0
	host_ui = UiElemen.new(); host_ui.size = Vector2(1280, 720); add_child(host_ui)
	client_ui = UiElemen.new(); client_ui.size = Vector2(1280, 720); add_child(client_ui)
	host_ui.koin_lokal_dikunci.connect(_host_lokal_dipilih)
	client_ui.koin_lokal_dikunci.connect(_client_lokal_dipilih)
	_uji_cari_angka_seri()
	# nama, penyerang (kacamata host), jeda mulai client, jeda klik host, jeda klik client
	await _duel_penuh("A host MENYERANG, normal", "pemain", latensi, 0.4, 0.6)
	await _duel_penuh("B host BERTAHAN, klik host instan & client telat 3 dtk (titipan tiba duluan)", "musuh", 3.0, 0.0, 0.3)
	await _duel_penuh("C host MENYERANG, client telat 3 dtk", "pemain", 3.0, 0.2, 0.0)
	await _duel_penuh("D host BERTAHAN, normal (duel berturut-turut)", "musuh", latensi, 0.5, 0.2)
	await _duel_penuh("E host MENYERANG + pedang +2 (duel berturut-turut)", "pemain", latensi, 0.1, 0.1, 2)
	print("UJI SELESAI -- total gagal: ", gagal_total)
	get_tree().quit()

# ---- relay: cermin _saat_koin_seri_lokal_dipilih / rpc_* / _undi_koin_seri_jika_lengkap ----
func _host_lokal_dipilih(p):
	koin_host = p
	_ke_client(func(): client_ui.terima_pilihan_koin_lawan(p))
	_undi()
func _client_lokal_dipilih(p):
	_ke_host(func():
		koin_client = p
		host_ui.terima_pilihan_koin_lawan(p)
		_undi())
func _undi():
	if koin_host == "" or koin_client == "": return
	koin_host = ""; koin_client = ""
	var hasil = "kepala" if mesin.randi_range(0, 1) == 0 else "ekor"
	_ke_client(func(): client_ui.terima_hasil_koin(hasil))
	host_ui.terima_hasil_koin(hasil)
func _ke_client(f): get_tree().create_timer(latensi).timeout.connect(f)
func _ke_host(f): get_tree().create_timer(latensi).timeout.connect(f)

func _cek(kondisi, pesan):
	if not kondisi:
		gagal_total += 1
		print("   GAGAL: ", pesan)

func _klik_otomatis(ui, jeda, pilihan_pembela, label):
	while not (ui.tombol_kepala.visible or ui.tombol_ekor.visible):
		await get_tree().process_frame
	await get_tree().create_timer(max(jeda, 0.001)).timeout
	var k = ui.tombol_kepala; var e = ui.tombol_ekor
	print("   [%s] tombol: HEADS %s, TAILS %s | judul: %s" % [label, "TERKUNCI" if k.disabled else "aktif", "TERKUNCI" if e.disabled else "aktif", ui.teks_judul.text])
	if not k.disabled and not e.disabled:
		(k if pilihan_pembela == "kepala" else e).pressed.emit()
	elif not k.disabled: k.pressed.emit()
	else: e.pressed.emit()
	return [k.disabled, e.disabled]

func _duel_penuh(nama, penyerang_host, jeda_client, klik_host, klik_client, pedang = 0):
	print("\n== ", nama)
	koin_host = ""; koin_client = ""
	var nyawa = 3
	var el_h = ["api","air","angin","tanah","petir"].pick_random()
	var el_c = ["api","air","angin","tanah","petir"].pick_random()
	var seri = host_ui.cari_angka_seri(penyerang_host, el_h, el_c, nyawa, pedang)
	_cek(not seri.is_empty(), "tidak ada angka seri")
	var naskah = {"elemen_pemain": el_h, "elemen_musuh": el_c, "angka_p": seri[0], "angka_m": seri[1], "bonus_pedang": pedang}
	var naskah_c = {"elemen_pemain": naskah["elemen_musuh"], "elemen_musuh": naskah["elemen_pemain"], "angka_p": naskah["angka_m"], "angka_m": naskah["angka_p"]}
	var penyerang_client = "musuh" if penyerang_host == "pemain" else "pemain"
	var hasil = {}
	var kam1 = Camera3D.new(); add_child(kam1)
	var kam2 = Camera3D.new(); add_child(kam2)
	var td1 = RichTextLabel.new(); add_child(td1)
	var td2 = RichTextLabel.new(); add_child(td2)
	var pembela_pilih = ["kepala", "ekor"].pick_random()
	var jalan = func(ui, peny, kam, td, pd, nsk, label):
		hasil[label] = await ui.jalankan_duel(peny, nyawa, kam, td, pd, nsk)
	jalan.call(host_ui, penyerang_host, kam1, td1, pedang, naskah, "host")
	var klik_h = func(): hasil["tombol_host"] = await _klik_otomatis(host_ui, klik_host, pembela_pilih, "host")
	klik_h.call()
	await get_tree().create_timer(jeda_client).timeout
	jalan.call(client_ui, penyerang_client, kam2, td2, naskah.get("bonus_pedang", 0), naskah_c, "client")
	var klik_c = func(): hasil["tombol_client"] = await _klik_otomatis(client_ui, klik_client, pembela_pilih, "client")
	klik_c.call()
	var batas = 0.0
	while not (hasil.has("host") and hasil.has("client")) and batas < 120.0:
		await get_tree().process_frame
		batas += get_process_delta_time()
	_cek(hasil.has("host") and hasil.has("client"), "MEMBEKU (tidak selesai dalam 120 dtk)")
	if not (hasil.has("host") and hasil.has("client")): return
	var h = hasil["host"]; var c = hasil["client"]
	print("   host  : skor pemain=%s musuh=%s pemenang=%s | teks_dadu='%s'" % [h["skor_akhir_pemain"], h["skor_akhir_musuh"], h["pemenang_final"], td1.text])
	print("   client: skor pemain=%s musuh=%s pemenang=%s | teks_dadu='%s'" % [c["skor_akhir_pemain"], c["skor_akhir_musuh"], c["pemenang_final"], td2.text])
	_cek(h["skor_akhir_pemain"] == h["skor_akhir_musuh"], "skor host tidak seri")
	_cek(h["skor_akhir_pemain"] == c["skor_akhir_musuh"] and h["skor_akhir_musuh"] == c["skor_akhir_pemain"], "skor host vs client beda")
	_cek((h["pemenang_final"] == "pemain") == (c["pemenang_final"] == "musuh"), "pemenang host vs client TIDAK konsisten")
	# layar penyerang: sisi pembela harus terkunci, sisanya aktif
	var tombol_penyerang = hasil["tombol_host"] if penyerang_host == "pemain" else hasil["tombol_client"]
	var tombol_pembela = hasil["tombol_client"] if penyerang_host == "pemain" else hasil["tombol_host"]
	_cek(tombol_pembela == [false, false], "pembela seharusnya melihat 2 tombol aktif")
	var harap = [true, false] if pembela_pilih == "kepala" else [false, true]
	_cek(tombol_penyerang == harap, "penyerang: sisi pembela seharusnya terkunci")
	for n in [kam1, kam2, td1, td2]: n.queue_free()

func _uji_cari_angka_seri():
	var total = 0; var tak_mungkin = 0; var salah = 0
	var els = ["api","air","angin","tanah","petir"]
	for peny in ["pemain", "musuh"]:
		for ep in els:
			for em in els:
				for ny in range(0, 9):
					for pd in range(0, 4):
						total += 1
						var r = host_ui.cari_angka_seri(peny, ep, em, ny, pd)
						if r.is_empty():
							tak_mungkin += 1
							continue
						var bp = 0; var bm = 0
						if ep != em:
							if em in host_ui.DATA_ELEMEN[ep]["menang_lawan"]: bp = 3
							else: bm = 3
						var sp = r[0] + bp + (ny if peny == "musuh" else 0) + (pd if peny == "pemain" else 0)
						var sm = r[1] + bm + (ny if peny == "pemain" else 0) + (pd if peny == "musuh" else 0)
						var pool_p = host_ui.angka_penyerang if peny == "pemain" else host_ui.angka_pembela
						var pool_m = host_ui.angka_pembela if peny == "pemain" else host_ui.angka_penyerang
						if sp != sm or not (r[0] in pool_p) or not (r[1] in pool_m): salah += 1
	print("cari_angka_seri: %d kombinasi, %d salah, %d mustahil seri" % [total, salah, tak_mungkin])
	_cek(salah == 0, "cari_angka_seri menghasilkan pasangan yang tidak seri")
