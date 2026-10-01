extends Node
var UiElemen = preload("res://ui_elemen.gd")
var ui
var gagal = 0
func _ready():
	Engine.time_scale = 6.0
	ui = UiElemen.new(); ui.size = Vector2(1280, 720); add_child(ui)
	# koin_lokal_dikunci TIDAK boleh pernah terpancar di solo
	ui.koin_lokal_dikunci.connect(func(_p): gagal += 1; print("   GAGAL: sinyal jaringan terpancar di solo"))
	ui.paksa_seri = true
	await _solo("SOLO pemain menyerang + seri", "pemain", 3, 0)
	await _solo("SOLO AI menyerang + seri + pedang AI 1", "musuh", 4, 1)
	ui.paksa_seri = false
	var seri_tanpa_saklar = 0
	for i in 6:
		var r = await _solo("SOLO tanpa saklar #%d" % i, ["pemain", "musuh"][i % 2], 3, 0, true)
		if r["skor_akhir_pemain"] == r["skor_akhir_musuh"]: seri_tanpa_saklar += 1
	print("seri tanpa saklar: %d dari 6 (acak, wajar kalau kecil)" % seri_tanpa_saklar)
	print("UJI SOLO SELESAI -- gagal: ", gagal)
	get_tree().quit()

func _solo(nama, penyerang, nyawa, pedang, diam = false):
	if not diam: print("\n== ", nama)
	var kam = Camera3D.new(); add_child(kam)
	var td = RichTextLabel.new(); add_child(td)
	var hasil = {}
	var jalan = func(): hasil["r"] = await ui.jalankan_duel(penyerang, nyawa, kam, td, pedang)
	jalan.call()
	while ui.fase_duel != "PILIH_PEMAIN": await get_tree().process_frame
	var el = ["api","air","angin","tanah","petir"].pick_random()
	ui.tombol_elemen[el].pressed.emit(); ui.tombol_elemen[el].pressed.emit()  # ketuk 2x = konfirmasi
	var t = 0.0
	while not hasil.has("r") and t < 90.0:
		if ui.tombol_kepala.visible:
			if not diam: print("   tombol koin: HEADS %s, TAILS %s | judul: %s" % ["TERKUNCI" if ui.tombol_kepala.disabled else "aktif", "TERKUNCI" if ui.tombol_ekor.disabled else "aktif", ui.teks_judul.text])
			if ui.tombol_kepala.disabled or ui.tombol_ekor.disabled: gagal += 1; print("   GAGAL: tombol terkunci di solo")
			ui.tombol_kepala.pressed.emit()
		await get_tree().process_frame
		t += get_process_delta_time()
	if not hasil.has("r"): gagal += 1; print("   GAGAL: membeku"); return {}
	var r = hasil["r"]
	if not diam:
		print("   skor pemain=%s musuh=%s pemenang=%s | teks_dadu='%s'" % [r["skor_akhir_pemain"], r["skor_akhir_musuh"], r["pemenang_final"], td.text])
		if r["skor_akhir_pemain"] != r["skor_akhir_musuh"]: gagal += 1; print("   GAGAL: saklar aktif tapi tidak seri")
	kam.queue_free(); td.queue_free()
	return r
