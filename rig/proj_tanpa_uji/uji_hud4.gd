extends "res://uji_sim.gd"
# Foto HUD 2/3/4 pemain dengan tata letak label persis panggung_utama.tscn.
#   argumen: pemain=4 lokal=0 lebar=1280 berkas=res://foto_hud.png
var slot_lokal_uji = 0
var berkas_foto = "res://foto_hud.png"

func _ready():
	for a in OS.get_cmdline_user_args():
		if a.begins_with("pemain="): n_pemain = int(a.substr(7))
		if a.begins_with("lokal="): slot_lokal_uji = int(a.substr(6))
		if a.begins_with("berkas="): berkas_foto = a.substr(7)
	StatusJaringan.peran_multiplayer = ""
	_bangun()
	var cl = get_node("CanvasLayer")
	# Tata letak asli (panggung_utama.tscn)
	var td_lama = cl.get_node("TeksDadu")
	var td = RichTextLabel.new(); td.name = "TeksDadu2"; td.bbcode_enabled = true
	td.offset_left = 457; td.offset_top = 40; td.offset_right = 815; td.offset_bottom = 70
	cl.add_child(td); td_lama.hide(); p.teks_dadu = td
	var tu = cl.get_node("TeksUang")
	tu.offset_left = 39; tu.offset_top = 90; tu.offset_right = 125; tu.offset_bottom = 113
	var tb = cl.get_node("TeksBintang")
	tb.offset_left = 946; tb.offset_top = 90; tb.offset_right = 1032; tb.offset_bottom = 113
	var kam = get_node("Camera3D")
	kam.position = Vector3(8, 18, 26); kam.rotation_degrees = Vector3(-45, 0, 0); kam.current = true
	var sun = DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-50, 30, 0); add_child(sun)
	UiDinamis.setup_ui_elegan(p)
	p.tombol_seting.show()
	p.slot_lokal = slot_lokal_uji
	var uang = [2500, 1840, 3120, 960]
	var bin = [4, 7, 2, 11]
	for s in range(n_pemain):
		p.daftar_pemain[s].uang = uang[s]
		p.daftar_pemain[s].bintang = bin[s]
	p.koleksi_permata_slot[0].assign(["Red"])
	if n_pemain > 2: p.koleksi_permata_slot[2].assign(["Blue", "Green"])
	if n_pemain > 2:
		UiDinamis.atur_hud_banyak_pemain(p)
	p.giliran_sekarang = p._aktor_dari_slot(2 if n_pemain > 2 else 1)
	p.teks_dadu.text = "[center]P3 rolled a 5![/center]" if n_pemain > 2 else "[center]Enemy rolled a 5![/center]"
	p.update_ui_status()
	for i in 20: await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(berkas_foto)
	print("FOTO ", berkas_foto, " kanan=", tb.get_global_rect() if not is_instance_valid(p.teks_bintang) else p.teks_bintang.get_global_rect(), " kiri=", p.teks_uang.get_global_rect())
	get_tree().quit()

func _process(_delta): pass
