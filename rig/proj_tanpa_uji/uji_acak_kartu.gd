extends Node
func _ready():
	var pk = load("res://petak_kartu.gd").new()
	var ids = []
	for k in pk.database_efek: ids.append(k["id"])
	print("DB ", ids)
	var hasil = {}
	for sd in [71, 72, 81, 82, 83, 84, 1, 2, 3]:
		seed(sd)
		var r = randi()
		hasil[sd] = [r % 4, r]
	print("ACAK ", hasil)
	get_tree().quit()
