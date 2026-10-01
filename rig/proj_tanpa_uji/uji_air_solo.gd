extends "res://uji_mp.gd"
# SOLO: jebakan air harus berperilaku persis seperti dulu (petak jatuh sama
# untuk seed yang sama = urutan mesin_acak tidak berubah).
func _ready():
	Engine.max_fps = 60
	Engine.time_scale = 4.0
	peran = ""
	StatusJaringan.peran_multiplayer = ""
	_bangun_adegan()
	p.daftar_pemain[1].jenis_kontrol = DataPemain.JenisKontrol.MANUSIA_LOKAL
	for s in [777, 1, 42, 2026, 99999]:
		var j = preload("res://jebakan_air.gd").new(); j.name = "JebakanAir"; j.pemilik = 0
		papan[3].add_child(j)
		_atur_posisi(8, 0)
		p.daftar_pemain[1].sisa_gelembung = 0
		var g = p.model_musuh.get_node_or_null("EfekGelembung")
		if g: g.free()
		await get_tree().process_frame
		p.mesin_acak.seed = s
		await p.bergerak_maju(5, "musuh")
		var g2 = p.model_musuh.get_node_or_null("EfekGelembung")
		print("SOLO seed=%d -> jatuh di petak %d | sisa_gelembung=%d | gelembung=%s | teks='%s' | rng_setelah=%s" % [s, p.daftar_pemain[1].posisi_saat_ini, p.daftar_pemain[1].sisa_gelembung, g2 != null, p.teks_dadu.text, str(p.mesin_acak.state)])
		await get_tree().create_timer(0.5).timeout
	get_tree().quit()
