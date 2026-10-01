extends Node
# E5/E7 (B-e, rig-only, TIDAK ikut ZIP): uji LANGSUNG _tayang_role untuk SEMUA
# 7 "jenis" (termasuk yang jarang terpicu lewat RNG pertandingan sungguhan:
# tornado/chain_lightning multi-sasaran/card_magnet/sacred/guard) + hitung
# jumlah node kolam yang DIBUAT (harus <= 6 sepanjang berjalan, U11).

func _ready():
	var adegan = load("res://uji_panggung.tscn").instantiate()
	add_child(adegan)
	var p = adegan.get_node("Pemain")
	for i in 10: await get_tree().process_frame

	# Panggil ketujuh jenis, termasuk chain_lightning dgn 4 sasaran (maks kolam label).
	p._tayang_role("guard", {"elemen": "api", "slot": 0})
	p._tayang_role("phoenix", {"petak": 3})
	p._tayang_role("tsunami", {"petak": 5})
	p._tayang_role("tornado", {"ke": 7})
	p._tayang_role("sacred", {"petak": 9})
	p._tayang_role("card_magnet", {"pencuri": 1, "korban": 0})
	p._tayang_role("chain_lightning", {"sasaran": [0, 1, 2, 3]})
	# jenis tidak dikenal -> harus AMAN (tidak crash, tidak menambah node).
	p._tayang_role("tidak_ada", {"apa": "saja"})

	for i in 30: await get_tree().process_frame

	# Hitung total node kolam yang benar-benar dibuat (U11: harus <= 6).
	var jumlah_kolam = p._tr_label.size() + (1 if p._tr_cincin != null else 0) + (1 if p._tr_bola != null else 0)
	print("KOLAM_JUMLAH ", jumlah_kolam)
	print("KOLAM_LABEL ", p._tr_label.size(), " CINCIN ", p._tr_cincin != null, " BOLA ", p._tr_bola != null, " VERY_LOW ", p._tr_very_low)

	# Panggil SEKALI LAGI ketujuh jenis (pastikan node DIPAKAI ULANG, bukan
	# bertambah -- kolam tetap sama setelah panggilan kedua).
	p._tayang_role("guard", {"elemen": "air", "slot": 1})
	p._tayang_role("phoenix", {"petak": 4})
	p._tayang_role("tsunami", {"petak": 6})
	p._tayang_role("tornado", {"ke": 8})
	p._tayang_role("sacred", {"petak": 10})
	p._tayang_role("card_magnet", {"pencuri": 2, "korban": 3})
	p._tayang_role("chain_lightning", {"sasaran": [1, 2]})
	for i in 100: await get_tree().process_frame
	var jumlah_kolam2 = p._tr_label.size() + (1 if p._tr_cincin != null else 0) + (1 if p._tr_bola != null else 0)
	print("KOLAM_JUMLAH_2 ", jumlah_kolam2, " (harus SAMA dgn KOLAM_JUMLAH)")

	print("UJI_TAYANG_ROLE_SELESAI")
	get_tree().quit()
