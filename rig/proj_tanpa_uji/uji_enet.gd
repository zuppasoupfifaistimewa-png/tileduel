extends Node
var selesai = false
func _ready():
	var peran = OS.get_cmdline_user_args()[0]
	StatusJaringan.peran_multiplayer = peran
	var anak = Node.new(); anak.name = "Anak"; anak.set_script(load("res://uji_enet_anak.gd")); add_child(anak)
	var peer = ENetMultiplayerPeer.new()
	if peran == "host":
		print("create_server: ", peer.create_server(27155, 2))
		multiplayer.multiplayer_peer = peer
		var id = await multiplayer.peer_connected
		print("[host] client tersambung id=", id)
		anak.rpc("rpc_ping", 41)
		var t = 0.0
		while not selesai and t < 5.0:
			await get_tree().process_frame; t += get_process_delta_time()
		print("[host] HASIL: ", "OK" if selesai else "GAGAL (timeout)")
	else:
		await get_tree().create_timer(0.3).timeout
		print("create_client: ", peer.create_client("127.0.0.1", 27155))
		multiplayer.multiplayer_peer = peer
		await multiplayer.connected_to_server
		print("[client] tersambung, id saya=", multiplayer.get_unique_id())
		await get_tree().create_timer(2.0).timeout
	await get_tree().create_timer(0.3).timeout
	get_tree().quit()
