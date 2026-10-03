extends Node
# Fase 7 G2 (rig-only): tangkapan layar SHOP (perlu renderer sungguhan, mis. xvfb + opengl3). Simpan ke user://toko_*.png
func _ready() -> void:
	var P = ProfilPemain
	P.crowns = 1000
	P.xp_total = 600
	P.kosmetik_dimiliki = ["pawn_shadow"]
	P.kosmetik_dipakai = {"pawn": "pawn_shadow"}
	for tab in ["pawn", "title", "frame"]:
		UiToko.buka_toko(self, tab)
		await get_tree().process_frame
		await get_tree().process_frame
		await get_tree().process_frame
		get_viewport().get_texture().get_image().save_png("user://toko_%s.png" % tab)
		get_node("PanelToko").free()
	get_tree().quit()
