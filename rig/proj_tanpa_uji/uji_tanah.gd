extends Node3D
# Tiruan minimal "main_node": hanya yang dipakai jebakan_tanah.gd
var nyawa_petak = [0, 3]
var pemilik_petak = [-1, 1]
func update_semua_label_petak(): pass

func _ready():
	var ui = ColorRect.new(); ui.visible = false; add_child(ui)   # sama seperti UIElemen di panggung_utama.tscn
	var jebakan = preload("res://jebakan_tanah.gd").new(); jebakan.pemilik = 1; add_child(jebakan)
	print("HP petak sebelum jebakan      : ", nyawa_petak[1])
	# C5 (B-c, 26-09): aktifkan_pelindung_sementara sekarang menerima bonus_hp
	# (pola sama dengan pemanggil produksinya, pemain_duel.gd).
	var bonus_hp_tes = jebakan.hitung_bonus_hp(self)
	await jebakan.aktifkan_pelindung_sementara(self, 1, ui, bonus_hp_tes)
	print("HP saat duel akan dimulai     : ", nyawa_petak[1], "   <- seharusnya 4 (3 + 1)")
	get_tree().quit()
