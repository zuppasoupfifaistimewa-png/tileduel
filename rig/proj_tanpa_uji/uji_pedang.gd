extends Node
# Tawaran pedang di client memakai daftar dari host; jawabannya berupa indeks.
func _ready():
	var PK = preload("res://petak_kartu.gd")
	var db = PK.new().database_efek
	var inventaris_host = [db[5], db[8], db[3], db[10], db[9]]   # campuran kartu, termasuk 3 pedang
	var daftar_pedang = []
	for k in inventaris_host:
		if k["id"].begins_with("pedang"): daftar_pedang.append(k)
	var diterima_client = daftar_pedang.map(func(d): return d.duplicate())   # salinan hasil RPC
	for uji in [["klik pedang ke-1", 1], ["NO, SAVE IT", -1]]:
		var ui = PK.new(); ui.is_petak_kartu = false; add_child(ui)
		var hasil = {}
		var jalan = func(): hasil["r"] = await ui.munculkan_ui_pedang_penyerang(diterima_client)
		jalan.call()
		await get_tree().process_frame
		var overlay = ui.kanvas_ui.get_child(0)
		if uji[1] >= 0:
			var wadah = overlay.get_child(1)
			wadah.get_child(uji[1]).pressed.emit()
		else:
			overlay.get_child(2).pressed.emit()
		while not hasil.has("r"): await get_tree().process_frame
		var indeks = -1 if hasil["r"] == null else diterima_client.find(hasil["r"])
		var di_host = null if indeks < 0 else daftar_pedang[indeks]
		print("%-18s -> indeks %d -> host memakai: %s" % [uji[0], indeks, "tidak ada" if di_host == null else di_host["id"]])
		if di_host != null:
			var i_inv = inventaris_host.find(di_host)
			inventaris_host.remove_at(i_inv)
			print("   inventaris host sesudahnya: ", inventaris_host.map(func(d): return d["id"]))
		ui.queue_free()
	get_tree().quit()
