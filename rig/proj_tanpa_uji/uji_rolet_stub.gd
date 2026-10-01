extends Control
# Pengganti rolet.gd khusus harness uji: cukup berputar sebentar supaya jalur
# ASLI lempar_dadu (host) & rpc_mainkan_rolet (client) bisa dijalankan.
var is_double = false

func putar_rolet(_hasil, _tipe) -> void:
	await get_tree().create_timer(0.3).timeout
