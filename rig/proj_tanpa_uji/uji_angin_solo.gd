extends "res://uji_mp.gd"
# SOLO: jebakan angin + koin tercecer harus sama persis dengan kode lama
# (petak & jumlah sebaran, uang korban, status mesin_acak) untuk seed yang sama.
func _peta() -> Dictionary:
	var m = {}
	for i in range(JUMLAH_PETAK):
		var k = papan[i].get_node_or_null("KoinTercecer")
		if k != null and not k.is_queued_for_deletion(): m[i] = k.isi_koin
	return m

func _ready():
	Engine.max_fps = 60
	Engine.time_scale = 4.0
	peran = ""
	StatusJaringan.peran_multiplayer = ""
	_bangun_adegan()
	p.daftar_pemain[1].jenis_kontrol = DataPemain.JenisKontrol.MANUSIA_LOKAL
	for s in [777, 1, 42, 2026, 99999]:
		for i in range(JUMLAH_PETAK):
			var k = papan[i].get_node_or_null("KoinTercecer")
			if k: k.free()
		var angin = preload("res://jebakan_angin.gd").new(); angin.name = "JebakanAngin"; angin.pemilik = 0
		papan[2].add_child(angin)
		var tumpuk = preload("res://koin_tercecer.gd").new(); tumpuk.name = "KoinTercecer"; tumpuk.isi_koin = 100
		papan[4].add_child(tumpuk)
		_atur_posisi(9, 0)
		p.daftar_pemain[1].uang = 1000
		await get_tree().process_frame
		p.mesin_acak.seed = s
		await p.bergerak_maju(4, "musuh") # 1, 2 (angin + sebar), 3, 4 (ambil tumpukan)
		print("SOLO-ANGIN seed=%d -> koin tersisa %s | uang korban %d | teks='%s' | rng_setelah=%s" % [s, _peta(), p.daftar_pemain[1].uang, p.teks_dadu.text, str(p.mesin_acak.state)])
		await get_tree().create_timer(0.5).timeout
	get_tree().quit()
