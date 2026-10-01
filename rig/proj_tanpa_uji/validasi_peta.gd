class_name ValidasiPeta
extends RefCounted
## Dipindah dari pemain.gd (Fase 2 - pemecahan file).
## Isinya persis sama, cuma dipanggil dengan main_node sebagai parameter,
## mengikuti pola yang sama seperti jebakan_*.gd dan ui_petak.gd.

static func cek(main_node: Node) -> String:
	for petak in main_node.rute_papan:
		# CEK 1: Mencegah Dead End
		if petak.petak_selanjutnya.size() == 0:
			return "EROR FATAL: Dead End terdeteksi pada node " + petak.name

		# CEK 2: Mencegah tombol tidak memiliki nama / array timpang
		if petak.petak_selanjutnya.size() > 1 and petak.petak_selanjutnya.size() != petak.nama_arah.size():
			return "EROR FATAL: Jumlah arah dan label teks tidak sama pada cabang " + petak.name

		petak.referensi_node_selanjutnya.clear()
		for path in petak.petak_selanjutnya:
			var node_tujuan = petak.get_node(path)
			if node_tujuan == null or not main_node.rute_papan.has(node_tujuan):
				return "EROR FATAL: NodePath putus atau mengarah ke objek salah pada " + petak.name
			petak.referensi_node_selanjutnya.append(node_tujuan)
	return "OK"

static func tampilkan_error(main_node: Node, pesan: String) -> void:
	var panel_err = ColorRect.new()
	panel_err.color = Color(0.8, 0.0, 0.0, 1.0)
	panel_err.set_anchors_preset(Control.PRESET_FULL_RECT)
	var lbl = Label.new()
	lbl.text = pesan
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.set_anchors_preset(Control.PRESET_CENTER)
	lbl.add_theme_font_size_override("font_size", 30)
	panel_err.add_child(lbl)
	main_node.teks_dadu.get_parent().add_child(panel_err)
