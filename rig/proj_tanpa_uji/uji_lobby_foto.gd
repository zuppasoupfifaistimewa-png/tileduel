extends Node
# Foto tampilan lobby (tanpa jaringan): host & client.
func _ready():
	var lobby = load("res://LocalPlay.tscn").instantiate()
	add_child(lobby)
	for i in 5: await get_tree().process_frame
	lobby._bersihkan_semua()
	# HOST, mode 3P+1AI, 1 client sudah gabung (kurang 1)
	lobby.mode_saat_ini = "host"
	lobby.indeks_mode_lobby = 4
	lobby.peta_lobby = "pantai"
	lobby.urutan_client = [555]
	lobby._tampilkan_lobby()
	for i in 10: await get_tree().process_frame
	await _foto("res://foto_lobby_host.png")
	# HOST siap START (2P+1AI, 1 client)
	lobby.indeks_mode_lobby = 1
	lobby.peta_lobby = "alam"
	lobby._segarkan_lobby()
	for i in 10: await get_tree().process_frame
	await _foto("res://foto_lobby_host_siap.png")
	# CLIENT (urutan kedua), mode 3P
	lobby.mode_saat_ini = "lobby_client"
	lobby.indeks_mode_lobby = 3
	lobby.urutan_client = [555, 0]
	lobby._segarkan_lobby()
	for i in 10: await get_tree().process_frame
	await _foto("res://foto_lobby_client.png")
	get_tree().quit()

func _foto(berkas: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(berkas)
	print("FOTO ", berkas)
