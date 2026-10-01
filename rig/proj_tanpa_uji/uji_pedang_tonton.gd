extends Node
# Menguji UI "tonton" kartu pedang (munculkan_ui_pedang_penyerang(mode="tonton")
# + pedang_jaringan) dan saklar pengujian UJI_SELALU_PEDANG.
var PK = preload("res://petak_kartu.gd")
var gagal = 0
var latensi = 0.1

func _cek(k, pesan):
	if not k:
		gagal += 1
		print("   GAGAL: ", pesan)

func _kanvas_tersisa(n) -> int:
	var c = 0
	for a in n.get_children():
		if a is CanvasLayer and not a.is_queued_for_deletion(): c += 1
	return c

func _ready():
	Engine.time_scale = 4.0
	await _uji_normal("T1 penyerang pilih kartu ke-1, pembela menonton", 1, false)
	await _uji_normal("T2 penyerang tekan NO SAVE IT, pembela menonton", -1, false)
	await _uji_normal("T3 balasan jaringan tiba SEBELUM UI tonton selesai dibangun (device lambat)", 1, true)
	await _uji_saklar()
	print("\nUJI PEDANG TONTON SELESAI -- gagal: ", gagal)
	get_tree().quit()

func _uji_normal(nama: String, pilih: int, duluan: bool):
	print("\n== ", nama)
	var db = PK.new().database_efek
	var inventaris = [db[5], db[8], db[3], db[10], db[9]]   # campuran, termasuk 3 pedang
	var daftar_pedang = []
	for k in inventaris:
		if k["id"].begins_with("pedang"): daftar_pedang.append(k)
	var diterima_penonton = daftar_pedang.map(func(d): return d.duplicate())

	var ui_aktor = PK.new(); ui_aktor.is_petak_kartu = false; add_child(ui_aktor)
	var ui_tonton = PK.new(); ui_tonton.is_petak_kartu = false; add_child(ui_tonton)

	var hasil = {}
	var jalan_aktor = func(): hasil["aktor"] = await ui_aktor.munculkan_ui_pedang_penyerang(inventaris)
	jalan_aktor.call()
	await get_tree().process_frame
	var overlay = ui_aktor.kanvas_ui.get_child(0)
	if pilih >= 0:
		overlay.get_child(1).get_child(pilih).pressed.emit()
	else:
		overlay.get_child(2).pressed.emit()
	while not hasil.has("aktor"): await get_tree().process_frame
	var indeks_asli = -1 if hasil["aktor"] == null else daftar_pedang.find(hasil["aktor"])

	# Sisi PENONTON: kalau "duluan" true, jawaban jaringan sudah tiba SEBELUM
	# UI-nya sempat dibangun (device lambat) -- pedang_jaringan dipanggil dulu,
	# harus ditampung lewat _ada_pedang_tertunda/_indeks_pedang_tertunda.
	if duluan:
		ui_tonton.pedang_jaringan(indeks_asli)
		await get_tree().create_timer(latensi).timeout
	var hasil_tonton = {}
	var jalan_tonton = func(): hasil_tonton["r"] = await ui_tonton.munculkan_ui_pedang_penyerang(diterima_penonton, "tonton")
	jalan_tonton.call()
	if not duluan:
		await get_tree().create_timer(latensi).timeout   # meniru jeda RPC hasil
		ui_tonton.pedang_jaringan(indeks_asli)
	while not hasil_tonton.has("r"): await get_tree().process_frame
	await get_tree().process_frame

	var teks_asli = "tidak ada" if hasil["aktor"] == null else hasil["aktor"]["id"]
	var teks_tonton = "tidak ada" if hasil_tonton["r"] == null else hasil_tonton["r"]["id"]
	print("   aktor pilih: %s   | penonton lihat: %s" % [teks_asli, teks_tonton])
	_cek(teks_asli == teks_tonton, "UI tonton menampilkan hasil yang berbeda dari aktor")
	_cek(_kanvas_tersisa(ui_aktor) == 0 and _kanvas_tersisa(ui_tonton) == 0, "masih ada layar pedang yang tidak tertutup")
	ui_aktor.queue_free(); ui_tonton.queue_free()

func _uji_saklar():
	print("\n== T4 saklar UJI_SELALU_PEDANG: 3 kartu tawaran harus selalu ada pedang")
	var pk = PK.new()
	var default_off = pk.UJI_SELALU_PEDANG
	_cek(default_off == false, "UJI_SELALU_PEDANG harus default false sebelum dikirim ke pengguna")

	# Uji langsung fungsi jaminannya (_ambil_tiga_kartu_uji_pedang), lepas dari
	# nilai saklar saat ini, supaya tidak perlu mengubah file asli. Harus
	# SELALU ketiga-tiganya kartu pedang (bukan cuma minimal 1).
	var jumlah_gagal_pedang = 0
	for i in range(200):
		var tiga = pk._ambil_tiga_kartu_uji_pedang()
		var jumlah_pedang = 0
		var id_terlihat = {}
		for k in tiga:
			if k["id"].begins_with("pedang"): jumlah_pedang += 1
			id_terlihat[k["id"]] = true
		if jumlah_pedang != 3: jumlah_gagal_pedang += 1
		_cek(tiga.size() == 3, "hasil bukan 3 kartu")
		_cek(id_terlihat.size() == tiga.size(), "ada kartu duplikat di 3 pilihan")
	print("   200x _ambil_tiga_kartu_uji_pedang() -> gagal semuanya pedang: ", jumlah_gagal_pedang, " (harus 0)")
	_cek(jumlah_gagal_pedang == 0, "saklar tidak menjamin KETIGA kartu pedang selalu muncul")

	# Sanity check: fungsi acak biasa TIDAK selalu menjamin pedang (harus ada
	# setidaknya satu kali yang tanpa pedang dari 200x, membuktikan saklar itu
	# memang mengubah perilaku, bukan kebetulan database_efek-nya selalu pedang).
	var pernah_tanpa_pedang = false
	for i in range(200):
		var tiga = pk.ambil_tiga_kartu()   # UJI_SELALU_PEDANG saat ini false
		var ada_pedang = false
		for k in tiga:
			if k["id"].begins_with("pedang"): ada_pedang = true
		if not ada_pedang: pernah_tanpa_pedang = true
	print("   200x ambil_tiga_kartu() biasa -> pernah tanpa pedang: ", pernah_tanpa_pedang, " (harus true)")
	_cek(pernah_tanpa_pedang, "ambil_tiga_kartu() biasa (saklar off) sudah selalu pedang -- test tidak berarti")

	# Uji end-to-end: salinan file dengan saklar dipaksa true, load sebagai
	# script terpisah, pastikan ambil_tiga_kartu() (jalur multiplayer) DAN
	# fallback solo di _bangun_ui_layar_kartu ikut selalu menyertakan pedang.
	var isi = FileAccess.get_file_as_string("res://petak_kartu.gd")
	_cek(isi.find("const UJI_SELALU_PEDANG := false") != -1, "tidak menemukan baris saklar UJI_SELALU_PEDANG di file asli")
	var isi_nyala = isi.replace("const UJI_SELALU_PEDANG := false", "const UJI_SELALU_PEDANG := true")
	# Hapus class_name (dan anotasi tipe yang memakainya) supaya tidak bentrok
	# dengan PetakKartu asli yang sudah terdaftar secara global (kelas duplikat
	# ini cuma dipakai untuk uji ini).
	isi_nyala = isi_nyala.replace("class_name PetakKartu", "")
	isi_nyala = isi_nyala.replace("var node_sistem_kartu: PetakKartu", "var node_sistem_kartu")
	var f = FileAccess.open("res://_uji_petak_kartu_saklar_nyala.gd", FileAccess.WRITE)
	f.store_string(isi_nyala)
	f.close()
	var PK2 = load("res://_uji_petak_kartu_saklar_nyala.gd")
	var pk2 = PK2.new()
	var jumlah_gagal2 = 0
	for i in range(100):
		var tiga = pk2.ambil_tiga_kartu()
		var jumlah_pedang = 0
		for k in tiga:
			if k["id"].begins_with("pedang"): jumlah_pedang += 1
		if jumlah_pedang != 3: jumlah_gagal2 += 1
	print("   100x ambil_tiga_kartu() dgn saklar=true -> gagal semuanya pedang: ", jumlah_gagal2, " (harus 0)")
	_cek(jumlah_gagal2 == 0, "ambil_tiga_kartu() tidak ikut menjamin KETIGA pedang saat saklar true")

	# Fallback solo (pilihan_host kosong) di _bangun_ui_layar_kartu.
	var jumlah_gagal3 = 0
	for i in range(20):
		var ui = PK2.new(); ui.is_petak_kartu = false; add_child(ui)
		ui._bangun_ui_layar_kartu("pemain", [], "")
		await get_tree().process_frame
		var jumlah_pedang = 0
		for k in ui._gacha_efek:
			if k["id"].begins_with("pedang"): jumlah_pedang += 1
		if jumlah_pedang != 3: jumlah_gagal3 += 1
		ui.queue_free()
	print("   20x fallback solo _bangun_ui_layar_kartu() dgn saklar=true -> gagal semuanya pedang: ", jumlah_gagal3, " (harus 0)")
	_cek(jumlah_gagal3 == 0, "fallback solo tidak ikut menjamin KETIGA pedang saat saklar true")

	DirAccess.remove_absolute(ProjectSettings.globalize_path("res://_uji_petak_kartu_saklar_nyala.gd"))
