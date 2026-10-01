extends "res://pemain.gd"
# pemain.gd ASLI tanpa perubahan apa pun, hanya menghitung pemanggilan menu
# supaya robot uji tahu kapan menu aksi baru disiapkan.
var jumlah_periksa = 0

func periksa_status_petak(slot_index: int = 0):
	jumlah_periksa += 1
	super(slot_index)
