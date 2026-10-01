extends Node
# Foto lobby mode "4 PLAYERS" (indeks 5, 6 tombol mode) -- cek tidak terpotong.
func _ready():
	var lobby = load("res://LocalPlay.tscn").instantiate()
	add_child(lobby)
	for i in 5: await get_tree().process_frame
	lobby._bersihkan_semua()
	# HOST, mode 4 PLAYERS, belum ada yang gabung
	lobby.mode_saat_ini = "host"
	lobby.indeks_mode_lobby = 5
	lobby.peta_lobby = "alam"
	lobby.urutan_client = []
	lobby._tampilkan_lobby()
	for i in 10: await get_tree().process_frame
	await _foto("res://foto_lobby_4p_kosong.png")
	# HOST, 4 PLAYERS, 3 client sudah gabung (siap START)
	lobby.urutan_client = [555, 556, 557]
	lobby._segarkan_lobby()
	for i in 10: await get_tree().process_frame
	await _foto("res://foto_lobby_4p_siap.png")
	get_tree().quit()

func _foto(berkas: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(berkas)
	print("FOTO ", berkas)
