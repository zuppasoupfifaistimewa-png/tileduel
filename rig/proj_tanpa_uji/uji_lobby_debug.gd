extends Node
func _ready():
	print("1 mulai")
	var lobby = load("res://LocalPlay.tscn").instantiate()
	print("2 lobby loaded: ", lobby)
	add_child(lobby)
	print("3 added")
	for i in 5: await get_tree().process_frame
	print("4 frames done")
	lobby._bersihkan_semua()
	print("5 bersih")
	lobby.mode_saat_ini = "host"
	lobby.indeks_mode_lobby = 5
	lobby.peta_lobby = "alam"
	lobby.urutan_client = []
	lobby._tampilkan_lobby()
	print("6 tampil")
	for i in 10: await get_tree().process_frame
	print("7 mau foto")
	await RenderingServer.frame_post_draw
	print("8 frame_post_draw selesai")
	get_viewport().get_texture().get_image().save_png("res://foto_debug.png")
	print("9 FOTO tersimpan")
	get_tree().quit()
