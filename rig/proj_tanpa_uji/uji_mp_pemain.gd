extends "res://pemain.gd"
# pemain.gd ASLI untuk uji dua proses. Hanya bagian yang butuh adegan game
# lengkap (inisialisasi _ready, kamera _process, menu periksa_status_petak,
# label 3D) yang diganti; semua RPC & logika jebakan/pedang tetap kode asli.

var lag_langkah: float = 0.0 # simulasi device lambat di client

func _ready(): pass
func _process(_delta): pass
func _unhandled_input(_event): pass
func update_semua_label_petak(): pass
func update_ui_status(): pass

func periksa_status_petak(slot_index: int = 0):
	# Versi ringkas: siaran state (kode asli) + pembukuan slot giliran.
	if StatusJaringan.peran_multiplayer == "host":
		_siarkan_state_giliran(slot_index)
	slot_giliran_ui = slot_index
	aktor_giliran_ui = "pemain" if slot_index == 0 else "musuh"
	slot_lawan_ui = 1 - slot_index
	# Catat juga: apakah lemparan jebakan air masih berjalan SAAT state diterapkan
	# (harus false), dan posisi korban saat itu (harus sudah di tanah).
	get_parent().catat("periksa|%d|replay=%s|y=%.2f" % [slot_index, get("_replay_jebakan_air_berjalan"), musuh.global_position.y])

func _langkah_satu_petak(index_petak: int, aktor: String) -> void:
	if lag_langkah > 0.0:
		await get_tree().create_timer(lag_langkah).timeout
	get_parent().catat("langkah|%d" % index_petak)
	await super._langkah_satu_petak(index_petak, aktor)
