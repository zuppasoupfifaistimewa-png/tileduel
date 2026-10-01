extends Node
# U7 (Fase 4 Langkah A): foto layar ROLE -- SOLO (main_menu.gd, sesudah SELECT
# STAGE, lihat _proses_tombol_peta/_buka_layar_role) dan LOBBY (layar_local_play.gd,
# tombol MY ROLE, lihat _buka_role_lobby). Dua ukuran layar dijalankan lewat
# foto_role.sh (xvfb + opengl3 + --resolution) yang memanggil adegan ini dua
# kali -- skrip ini sendiri tidak tahu/tidak perlu tahu ukurannya.
#   argumen: foto=/path/awalan (tanpa akhiran _xxx.png)
var awalan_foto := "res://role"
var foto_diambil := 0
var pohon_uji := false # E0 (B-e, rig-only): pohon=1 -> juga foto UiRole.buka_pohon

func _ready():
	for a in OS.get_cmdline_user_args():
		if a.begins_with("foto="): awalan_foto = a.substr(5)
		if a == "pohon=1": pohon_uji = true
	Engine.time_scale = 2.0
	StatusJaringan.peran_multiplayer = ""
	await _foto_solo()
	await _foto_lobby()
	if pohon_uji:
		await _foto_pohon()
	print("FOTO_ROLE_SELESAI ", foto_diambil)
	get_tree().quit()

func _foto_solo() -> void:
	# Sama seperti uji_nyata.gd: adegan asli (panggung_utama via uji_panggung.tscn)
	# + klik tombol menu sungguhan sampai layar ROLE (SINGLE PLAYER -> 1 AI ENEMY
	# -> CLASSIC -> SELECT STAGE).
	var adegan = load("res://uji_panggung.tscn").instantiate()
	add_child(adegan)
	var p = adegan.get_node("Pemain")
	for i in 10: await get_tree().process_frame
	var menu = null
	for anak in p.get_children():
		if anak.get_script() == preload("res://main_menu.gd"):
			menu = anak
	if menu == null:
		print("GAGAL solo: main menu tidak ditemukan")
		adegan.queue_free()
		return
	# Profil baru (HOME sementara) selalu bisa klaim hadiah Day 1 -> popup
	# DAILY REWARD muncul call_deferred sesudah _ready, di lapisan LEBIH
	# TINGGI dari layar ROLE (11) -- tutup dulu supaya tidak menutupi foto.
	for i in 5: await get_tree().process_frame
	_klik_teks("LATER")
	await get_tree().process_frame
	_klik_teks("SINGLE PLAYER")
	await get_tree().process_frame
	_klik_teks("1 AI ENEMY")
	await get_tree().process_frame
	_klik_teks("CLASSIC")
	await get_tree().process_frame
	_klik_teks("Grassland")
	var t := 0.0
	while _cari_label("CHOOSE YOUR ROLE").is_empty() and t < 20.0:
		await get_tree().process_frame
		t += get_process_delta_time()
	if _cari_label("CHOOSE YOUR ROLE").is_empty():
		print("GAGAL solo: layar ROLE tidak muncul")
		adegan.queue_free()
		return
	for i in 10: await get_tree().process_frame
	await _foto("solo_kosong") # belum pernah pilih role -> START mati, "Pick a role..."
	_klik_teks("FIRE")
	for i in 5: await get_tree().process_frame
	await _foto("solo_dipilih") # role terpilih -> grid jebakan + START aktif
	adegan.queue_free()
	for i in 5: await get_tree().process_frame

func _foto_lobby() -> void:
	# Sama seperti uji_foto_fase1.gd: lobby dibangun langsung lewat properti
	# (tanpa ENet sungguhan), host 4P Quick di peta alam.
	var lobby = load("res://LocalPlay.tscn").instantiate()
	add_child(lobby)
	for i in 5: await get_tree().process_frame
	lobby._bersihkan_semua()
	lobby.mode_saat_ini = "host"
	lobby.indeks_mode_lobby = 5
	lobby.peta_lobby = "alam"
	lobby.quick_lobby = true
	lobby.urutan_client = [555, 556, 557]
	lobby._tampilkan_lobby()
	for i in 10: await get_tree().process_frame
	await _foto("lobby_lobi") # baris pemain + tombol MY ROLE: —
	# Tombol MY ROLE sungguhan (_buka_role_lobby) butuh id_saya>0, yaitu
	# peer_jaringan ENet sungguhan yang tidak dibangun uji foto ini -- jadi
	# UiRole dipanggil LANGSUNG di sini dengan konteks YANG SAMA PERSIS
	# dengan _buka_role_lobby (teks_tombol OK, petunjuk_level false,
	# jumlah_jenis SLOT_JEBAKAN_MP, lapisan 15), supaya layarnya identik
	# dengan yang device sungguhan akan tampilkan.
	var konteks := {
		"role": "",
		"jebakan": [],
		"jumlah_jenis": DataRole.SLOT_JEBAKAN_MP,
		"teks_tombol": "OK",
		"petunjuk_level": false,
		"boleh_batal": true,
		"batal": func(): pass,
		"lapisan": 15,
	}
	UiRole.buka_pilih_role(lobby, konteks, func(_role, _jebakan): pass)
	for i in 10: await get_tree().process_frame
	await _foto("lobby_kosong")
	_klik_teks("WATER")
	for i in 5: await get_tree().process_frame
	await _foto("lobby_dipilih")
	lobby.queue_free()
	for i in 5: await get_tree().process_frame

func _foto_pohon() -> void:
	# E0 (B-e, rig-only): UiRole.buka_pohon dipanggil LANGSUNG (pola sama
	# _foto_lobby memanggil buka_pilih_role langsung) -- tab ROLE TREE (role
	# api, profil baru = Level Role 1), kartu konfirmasi node pertama, lalu
	# tab ARENA + baris ARENA BUILD lobby (P11).
	var adegan = load("res://uji_panggung.tscn").instantiate()
	add_child(adegan)
	var p = adegan.get_node("Pemain")
	for i in 10: await get_tree().process_frame
	# Popup DAILY REWARD (profil baru) di lapisan 12 -- tutup dulu (pola sama _foto_solo).
	_klik_teks("LATER")
	await get_tree().process_frame
	ProfilPemain.role_terakhir = "api"
	UiRole.buka_pohon(p, {"role": "api", "tab": "tree", "lapisan": 11, "tutup": func(): pass})
	for i in 10: await get_tree().process_frame
	await _foto("pohon_tree")
	_klik_awalan("Hot Flames")
	for i in 5: await get_tree().process_frame
	await _foto("pohon_konfirmasi")
	_klik_teks("CANCEL")
	for i in 5: await get_tree().process_frame
	_klik_teks("ARENA")
	for i in 5: await get_tree().process_frame
	await _foto("pohon_arena")
	adegan.queue_free()
	for i in 5: await get_tree().process_frame

	var lobby = load("res://LocalPlay.tscn").instantiate()
	add_child(lobby)
	for i in 5: await get_tree().process_frame
	lobby._bersihkan_semua()
	lobby.mode_saat_ini = "host"
	lobby.indeks_mode_lobby = 5
	lobby.peta_lobby = "alam"
	lobby.quick_lobby = true
	lobby.urutan_client = [555, 556, 557]
	lobby._tampilkan_lobby()
	for i in 10: await get_tree().process_frame
	var konteks := {
		"role": "api", "jebakan": [], "jumlah_jenis": DataRole.SLOT_JEBAKAN_MP,
		"teks_tombol": "OK", "petunjuk_level": false, "boleh_batal": true,
		"batal": func(): pass, "lapisan": 15, "arena": true,
	}
	UiRole.buka_pilih_role(lobby, konteks, func(_role, _jebakan): pass)
	for i in 10: await get_tree().process_frame
	await _foto("lobby_arena_build")
	lobby.queue_free()
	for i in 5: await get_tree().process_frame

func _klik_awalan(awalan: String) -> bool:
	# Sama seperti _klik_teks, tapi cocok AWALAN teks -- dipakai tombol node
	# (teks dua baris "Nama\nLv X/3", angkanya berubah-ubah).
	for b in find_children("*", "Button", true, false):
		if b.text.begins_with(awalan) and b.is_visible_in_tree() and not b.disabled:
			b.pressed.emit()
			return true
	return false

func _cari_label(teks: String) -> Array:
	var hasil = []
	for l in find_children("*", "Label", true, false):
		if l.text == teks and l.is_visible_in_tree():
			hasil.append(l)
	return hasil

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
