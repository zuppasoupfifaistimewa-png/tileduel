extends Node
# Foto layar pengumuman kartu pedang (kondisi asli, dirender GPU via Xvfb).
const PK = preload("res://petak_kartu.gd")
func _foto(nama):
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://foto_pedang_%s.png" % nama)

func _ready():
	var tmp = PK.new(); var db = tmp.database_efek.duplicate(); tmp.free()
	var inv = [db[8], db[6], db[10]] # pedang_1, dadu_tinggi, pedang_3
	for kasus in [["1_penyerang_sebelum", "", -2], ["2_penyerang_pakai", "", 1], ["3_pembela_menonton", "tonton", -2], ["4_pembela_pakai", "tonton", 1], ["5_penyerang_simpan", "", -1], ["6_pembela_simpan", "tonton", -1]]:
		var ui = PK.new(); ui.is_petak_kartu = false; add_child(ui)
		var jalan = func(): await ui.munculkan_ui_pedang_penyerang(inv, kasus[1])
		jalan.call()
		await get_tree().create_timer(0.3).timeout
		if kasus[2] != -2:
			if kasus[1] == "tonton": ui.pedang_jaringan(kasus[2])
			elif kasus[2] >= 0: ui._pedang_tombol[kasus[2]].pressed.emit()
			else: ui._pedang_tombol_batal.pressed.emit()
			await get_tree().create_timer(0.5).timeout # setelah "denyut" selesai
		await _foto(kasus[0])
		if kasus[2] == -2: ui.pedang_jaringan(-1)
		await get_tree().create_timer(1.6).timeout
		ui.queue_free()
	get_tree().quit()
