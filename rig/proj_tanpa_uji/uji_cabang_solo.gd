extends "res://uji_mp.gd"
# SOLO: AI (musuh) di persimpangan harus memakai urutan mesin_acak yang sama
# seperti sebelum perubahan sinkronisasi cabang. Satu seed per proses (seed=N):
# begitu karakter tiba di petak akhir (4 lewat KANAN / 7 lewat ATAS), catat
# petaknya & state RNG, lalu keluar.
func _ready():
	var s = 1
	for a in OS.get_cmdline_user_args():
		if a.begins_with("seed="): s = int(a.substr(5))
	Engine.max_fps = 60
	Engine.time_scale = 4.0
	peran = ""
	StatusJaringan.peran_multiplayer = ""
	_bangun_adegan()
	# Slot 1 = AI (seperti di game solo): di persimpangan AI memilih acak lewat mesin_acak.
	p.daftar_pemain[1].jenis_kontrol = DataPemain.JenisKontrol.AI
	p.slot_lokal = 0
	papan[2].referensi_node_selanjutnya.assign([papan[3], papan[6]])
	papan[2].nama_arah.assign(["KANAN", "ATAS"])
	_atur_posisi(8, 0)
	await get_tree().process_frame
	p.mesin_acak.seed = s
	p.bergerak_maju(4, "musuh")
	var batas = 0
	var jejak = []
	while batas < 2000:
		batas += 1
		await get_tree().process_frame
		var pos = p.daftar_pemain[1].posisi_saat_ini
		if jejak.is_empty() or jejak[-1] != pos: jejak.append(pos)
		if pos == 4 or pos == 7: break
	printerr("CABANG seed=%d -> petak %d | jejak=%s | rng=%s" % [s, p.daftar_pemain[1].posisi_saat_ini, str(jejak), str(p.mesin_acak.state)])
	get_tree().quit()
