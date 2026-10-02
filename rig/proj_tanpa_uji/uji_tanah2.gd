extends Node3D
var nyawa_petak = [0, 3]
var pemilik_petak = [-1, 1]
func update_semua_label_petak(): pass
# F7 (02-10): tiruan pemain_role._angka_jebakan -- sejak C5 hitung_bonus_hp memanggilnya.
# Pemasang tanpa build (hard_rock Lv0) -> hp_tambahan_awal 0, jadi bonus tetap +1 dasar.
func _angka_jebakan(_slot_pemasang: int, _elemen: String) -> Dictionary: return {"hp_tambahan_awal": 0}

func _ready():
	Engine.time_scale = 6.0
	var ui = preload("res://ui_elemen.gd").new(); ui.size = Vector2(1280, 720); ui.visible = false; add_child(ui)
	var kam = Camera3D.new(); add_child(kam)
	var td = RichTextLabel.new(); add_child(td)
	for putaran in 2:   # dua kali: memastikan jebakan kedua juga benar
		nyawa_petak[1] = 3
		var jebakan = preload("res://jebakan_tanah.gd").new(); jebakan.pemilik = 1; add_child(jebakan)
		print("\n[duel %d] HP sebelum jebakan  : %d" % [putaran + 1, nyawa_petak[1]])
		# C5 (B-c, 26-09): aktifkan_pelindung_sementara sekarang menerima bonus_hp
		# (bukan menghitung sendiri) -- pola SAMA dengan pemanggil produksinya
		# (pemain_duel.gd): hitung_bonus_hp(main_node) dulu, lalu oper angkanya.
		var bonus_hp_tes = jebakan.hitung_bonus_hp(self)
		await jebakan.aktifkan_pelindung_sementara(self, 1, ui, bonus_hp_tes)
		var hp_dibaca_duel = nyawa_petak[1]   # persis seperti call site: dibaca setelah jebakan
		print("[duel %d] HP dibaca duel     : %d   (harus 4)" % [putaran + 1, hp_dibaca_duel])
		var hasil = {}
		var jalan = func(): hasil["r"] = await ui.jalankan_duel("pemain", hp_dibaca_duel, kam, td, 0)
		jalan.call()
		while ui.fase_duel != "PILIH_PEMAIN": await get_tree().process_frame
		ui.tombol_elemen["api"].pressed.emit(); ui.tombol_elemen["api"].pressed.emit()
		await get_tree().create_timer(3.0).timeout
		print("[duel %d] HP di tengah duel  : %d   (harus tetap 4)" % [putaran + 1, nyawa_petak[1]])
		while not hasil.has("r"):
			if ui.tombol_kepala.visible: ui.tombol_kepala.pressed.emit()
			await get_tree().process_frame
		await get_tree().process_frame
		print("[duel %d] HP setelah duel    : %d   (harus kembali 3) | jebakan masih ada: %s" % [putaran + 1, nyawa_petak[1], is_instance_valid(jebakan) and not jebakan.is_queued_for_deletion()])
	get_tree().quit()
