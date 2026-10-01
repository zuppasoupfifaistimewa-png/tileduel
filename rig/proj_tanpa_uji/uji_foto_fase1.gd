extends Node
# T6 (Fase 1): foto lobby (baris MATCH) host & client, dan panel IN DEBT!.
func _ready():
	var awalan = "res://f1"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("foto="): awalan = a.substr(5)
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
	await _foto(awalan + "_lobby_host.png")
	lobby.mode_saat_ini = "lobby_client"
	lobby.indeks_mode_lobby = 3
	lobby.peta_lobby = "pantai"
	lobby.quick_lobby = false
	lobby.urutan_client = [555, 0]
	lobby._segarkan_lobby()
	for i in 10: await get_tree().process_frame
	await _foto(awalan + "_lobby_client.png")
	lobby.queue_free()
	for i in 3: await get_tree().process_frame
	# Panel IN DEBT! (butuh node dengan get_tree(); current_scene = node ini)
	UiDinamis.tanya_iklan_hutang(self)
	for i in 10: await get_tree().process_frame
	await _foto(awalan + "_hutang.png")
	get_tree().quit()

func _foto(berkas: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(berkas)
	print("FOTO ", berkas)
