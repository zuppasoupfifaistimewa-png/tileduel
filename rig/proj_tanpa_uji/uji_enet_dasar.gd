extends Node
@rpc("authority", "call_remote", "reliable")
func rpc_ping(n: int) -> void:
	print("[%s] rpc_ping diterima: %d (dasar)" % [StatusJaringan.peran_multiplayer, n])
	rpc_id(1, "rpc_pong", n + 1)
@rpc("any_peer", "call_remote", "reliable")
func rpc_pong(n: int) -> void:
	print("[%s] rpc_pong diterima: %d dari %d" % [StatusJaringan.peran_multiplayer, n, multiplayer.get_remote_sender_id()])
	get_parent().selesai = true
