extends Node3D
# Dua salinan petak_kartu.gd ASLI: "host" dan "client". Relay meniru handler
# baru di pemain.gd (_saat_kartu_*_diklik -> rpc_* -> buka/buang_kartu_jaringan).
var PK = preload("res://petak_kartu.gd")
var host_k; var client_k
var latensi = 0.12
var gagal = 0

func _ready():
	Engine.time_scale = 4.0
	host_k = PK.new(); host_k.is_petak_kartu = false; add_child(host_k)
	client_k = PK.new(); client_k.is_petak_kartu = false; add_child(client_k)
	host_k.kartu_gacha_diklik.connect(func(i): _kirim(func(): client_k.buka_kartu_jaringan(i)))
	client_k.kartu_gacha_diklik.connect(func(i): _kirim(func(): host_k.buka_kartu_jaringan(i)))
	host_k.kartu_buang_diklik.connect(func(i): _kirim(func(): client_k.buang_kartu_jaringan(i)))
	client_k.kartu_buang_diklik.connect(func(i): _kirim(func(): host_k.buang_kartu_jaringan(i)))
	await _gacha("G1 host yang lewat, pilih kartu ke-2", "host", 2, 0.4, latensi)
	await _gacha("G2 client yang lewat, pilih kartu ke-0", "client", 0, 0.4, latensi)
	await _gacha("G3 host pilih INSTAN, layar client telat 1.5 dtk", "host", 1, 0.0, 1.5)
	await _macet()
	await _buang("D1 client yang membuang kartu ke-1", "client", 1, false)
	await _buang("D2 host membuang ke-3, UI buang muncul SAAT UI kartu client belum tertutup", "host", 3, true)
	await _solo()
	print("\nUJI KARTU SELESAI -- gagal: ", gagal)
	get_tree().quit()

func _kirim(f): get_tree().create_timer(latensi).timeout.connect(f)
func _cek(k, pesan):
	if not k:
		gagal += 1
		print("   GAGAL: ", pesan)
func _kanvas_tersisa(n) -> int:
	var c = 0
	for a in n.get_children():
		if a is CanvasLayer and not a.is_queued_for_deletion(): c += 1
	return c
func _klik(k, i, jeda):
	while k._gacha_tombol.is_empty(): await get_tree().process_frame
	await get_tree().create_timer(max(jeda, 0.001)).timeout
	var t = k._gacha_tombol
	print("   [%s] klik kartu %d (tombol aktif: %s)" % ["host" if k == host_k else "client", i, not t[i].disabled])
	t[i].pressed.emit()

func _gacha(nama, aktor, pilih, jeda_klik, jeda_client):
	print("\n== ", nama)
	var tiga = host_k.ambil_tiga_kartu()
	host_k.siapkan_sesi_gacha()
	var hasil = {}
	var mode_h = "lokal" if aktor == "host" else "tonton"
	var mode_c = "lokal" if aktor == "client" else "tonton"
	var jalan_h = func():
		await host_k.mainkan_efek_kartu()
		hasil["host"] = await host_k.mulai_gacha_kartu("pemain" if aktor == "host" else "musuh", tiga, mode_h)
	jalan_h.call()
	var jalan_c = func():
		await get_tree().create_timer(latensi).timeout   # rpc_kartu_mulai tiba
		client_k.siapkan_sesi_gacha()                        # reset saat pesan diterima
		await get_tree().create_timer(jeda_client).timeout   # layar client macet/lambat
		await client_k.mainkan_efek_kartu()
		var pilihan_c = []   # client menerima salinan data lewat RPC
		for d in tiga: pilihan_c.append(d.duplicate())
		hasil["client"] = await client_k.mulai_gacha_kartu("pemain" if aktor == "client" else "musuh", pilihan_c, mode_c)
	jalan_c.call()
	if aktor == "host": _klik(host_k, pilih, jeda_klik)
	else: _klik(client_k, pilih, jeda_klik)
	while not (hasil.has("host") and hasil.has("client")): await get_tree().process_frame
	await get_tree().process_frame
	print("   host   dapat: ", hasil["host"]["id"], "   | client lihat: ", hasil["client"]["id"], "   | seharusnya: ", tiga[pilih]["id"])
	_cek(hasil["host"]["id"] == tiga[pilih]["id"], "host mendapat kartu yang salah")
	_cek(hasil["client"]["id"] == tiga[pilih]["id"], "client melihat kartu yang berbeda")
	_cek(_kanvas_tersisa(host_k) == 0 and _kanvas_tersisa(client_k) == 0, "masih ada layar kartu yang tidak tertutup")

func _buang(nama, aktor, pilih, tumpang_tindih):
	print("\n== ", nama)
	var db = host_k.database_efek
	var inv_asli = [db[0], db[1], db[2], db[3]]   # inventaris ASLI di host
	var ids_awal = inv_asli.map(func(d): return d["id"])
	var inv_client = inv_asli.map(func(d): return d.duplicate())
	var hasil = {}
	if tumpang_tindih:
		# UI kartu client sengaja masih terbuka (belum lewat 2.5 dtk) saat UI buang muncul
		var tiga = host_k.ambil_tiga_kartu()
		var g = func(): hasil["gacha_c"] = await client_k.mulai_gacha_kartu("musuh", tiga, "tonton")
		g.call()
		await get_tree().process_frame
		client_k.buka_kartu_jaringan(0)
		await get_tree().create_timer(1.0).timeout
	var mode_h = "lokal" if aktor == "host" else "tonton"
	var mode_c = "lokal" if aktor == "client" else "tonton"
	host_k.siapkan_sesi_buang(); client_k.siapkan_sesi_buang()
	var bh = func():
		await host_k.munculkan_ui_buang_kartu("pemain" if aktor == "host" else "musuh", inv_asli, mode_h)
		hasil["host"] = true
	bh.call()
	var bc = func():
		await get_tree().create_timer(latensi).timeout
		await client_k.munculkan_ui_buang_kartu("pemain" if aktor == "client" else "musuh", inv_client, mode_c)
		hasil["client"] = true
	bc.call()
	var k = host_k if aktor == "host" else client_k
	while k._buang_tombol.is_empty(): await get_tree().process_frame
	await get_tree().create_timer(0.3).timeout
	print("   [%s] buang kartu ke-%d (%s)" % [aktor, pilih, ids_awal[pilih]])
	k._buang_tombol[pilih].pressed.emit()
	var batas = 0.0
	while not (hasil.has("host") and hasil.has("client")) and batas < 20.0:
		await get_tree().process_frame; batas += get_process_delta_time()
	if tumpang_tindih:
		while not hasil.has("gacha_c"): await get_tree().process_frame
	await get_tree().create_timer(0.2).timeout
	var harap = ids_awal.duplicate(); harap.remove_at(pilih)
	var sisa = inv_asli.map(func(d): return d["id"])
	print("   inventaris ASLI di host sekarang: ", sisa, "   (harus ", harap, ")")
	_cek(hasil.has("host") and hasil.has("client"), "UI buang kartu membeku")
	_cek(sisa == harap, "kartu yang terbuang di host salah")
	_cek(_kanvas_tersisa(host_k) == 0 and _kanvas_tersisa(client_k) == 0, "masih ada layar yang tidak tertutup (kanvas tertukar)")

func _solo():
	print("\n== SOLO: AI (musuh) memilih sendiri & membuang sendiri, pemain memilih biasa")
	var s = PK.new(); s.is_petak_kartu = false; add_child(s)
	var t0 = Time.get_ticks_msec()
	var r = await s.mulai_gacha_kartu("musuh")
	print("   AI dapat: ", r["id"], " setelah %.1f dtk (waktu game)" % ((Time.get_ticks_msec() - t0) / 1000.0 * 4.0))
	var klik = func():
		while s._gacha_tombol.is_empty(): await get_tree().process_frame
		s._gacha_tombol[1].pressed.emit()
	klik.call()
	var r2 = await s.mulai_gacha_kartu("pemain")
	print("   pemain dapat: ", r2["id"])
	var inv = [s.database_efek[0], s.database_efek[1], s.database_efek[2], s.database_efek[3]]
	await s.munculkan_ui_buang_kartu("musuh", inv)
	print("   AI membuang 1 kartu -> sisa ", inv.size(), " kartu")
	_cek(inv.size() == 3, "AI solo tidak membuang kartu")
	_cek(_kanvas_tersisa(s) == 0, "layar solo tidak tertutup")

func _macet():
	print("\n== G4 client MACET 4 dtk saat animasi; pilihan host + perintah buang kartu tiba duluan")
	var tiga = host_k.ambil_tiga_kartu()
	var hasil = {}
	client_k.siapkan_sesi_gacha()                  # rpc_kartu_mulai diterima
	var g = func():
		await get_tree().create_timer(4.0).timeout # macet (mis. shader pertama kali disusun)
		await client_k.mainkan_efek_kartu()
		hasil["gacha"] = await client_k.mulai_gacha_kartu("musuh", tiga, "tonton")
	g.call()
	await get_tree().create_timer(0.3).timeout
	client_k.buka_kartu_jaringan(2)                # pilihan host tiba -> dititipkan
	await get_tree().create_timer(0.3).timeout
	client_k.siapkan_sesi_buang()                  # rpc_buang_kartu_mulai tiba
	var inv = [host_k.database_efek[0], host_k.database_efek[1], host_k.database_efek[2], host_k.database_efek[3]]
	var b = func():
		await client_k.munculkan_ui_buang_kartu("musuh", inv.map(func(d): return d.duplicate()), "tonton")
		hasil["buang"] = true
	b.call()
	await get_tree().create_timer(0.3).timeout
	client_k.buang_kartu_jaringan(0)               # pilihan buang host tiba
	var batas = 0.0
	while not (hasil.has("gacha") and hasil.has("buang")) and batas < 30.0:
		await get_tree().process_frame; batas += get_process_delta_time()
	await get_tree().create_timer(0.2).timeout
	_cek(hasil.has("gacha"), "layar kartu client TERTAHAN (titipan pilihan hilang)")
	_cek(hasil.has("buang"), "layar buang kartu client tertahan")
	if hasil.has("gacha"):
		print("   client akhirnya membuka: ", hasil["gacha"]["id"], "   (harus ", tiga[2]["id"], ")")
		_cek(hasil["gacha"]["id"] == tiga[2]["id"], "client membuka kartu yang salah")
	_cek(_kanvas_tersisa(client_k) == 0, "masih ada layar client yang tidak tertutup")
