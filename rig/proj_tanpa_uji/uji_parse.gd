extends Node
func _ready():
	for p in ["res://pemain.gd", "res://ui_elemen.gd", "res://petak_kartu.gd", "res://petak_papan.gd", "res://jebakan_tanah.gd", "res://jebakan_air.gd", "res://jebakan_angin.gd", "res://koin_tercecer.gd", "res://jebakan_api.gd", "res://jebakan_petir.gd", "res://petak_permata.gd", "res://ui_petak.gd", "res://ui_dinamis.gd", "res://lingkungan_pantai.gd", "res://migrasi_host.gd", "res://layar_local_play.gd", "res://status_jaringan.gd", "res://uji_robot_mp.gd", "res://main_menu.gd", "res://pengelola_iklan.gd", "res://uji_sim.gd", "res://uji_nyata.gd"]:
		var s = load(p)
		print("UJI ", p, " -> ", s != null and s.can_instantiate())
	get_tree().quit()
