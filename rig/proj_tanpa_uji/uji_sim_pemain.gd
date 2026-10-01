extends "res://pemain.gd"
# pemain.gd ASLI untuk simulasi permainan penuh. Hanya _ready (butuh adegan
# game lengkap), kamera (_process) dan input layar yang dimatikan.
var jumlah_periksa = 0

func _ready(): pass
func _process(_delta): pass
func _unhandled_input(_event): pass

# Fase 2 (T5): hitungan sendiri untuk dibandingkan dengan statistik_slot.
var uji_dadu = [0, 0, 0, 0]
var uji_duel = 0

func lempar_dadu(aktor):
	var sl = _slot_dari_aktor(aktor)
	if sl >= 0 and sl < uji_dadu.size():
		uji_dadu[sl] += 1
	await super(aktor)

func eksekusi_dadu_pertarungan(hasil_duel: Dictionary, slot_penyerang: int, slot_pembela: int):
	uji_duel += 1
	super(hasil_duel, slot_penyerang, slot_pembela)

func periksa_status_petak(slot_index: int = 0):
	jumlah_periksa += 1
	super(slot_index)
