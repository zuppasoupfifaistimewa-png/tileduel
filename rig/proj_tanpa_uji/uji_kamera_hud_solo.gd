extends Node
# Mode SOLO harus 100% sama seperti dulu:
#  1) aturan geser kamera baru == ekspresi lama (peran ""), untuk semua kombinasi
#  2) _render_uang_tampil baru == versi lama (disalin apa adanya) untuk slot_lokal 0
# Multiplayer: host = sama dengan solo di panel, client = panelnya ditukar.
const PemainScript = preload("res://pemain.gd")
var gagal = 0

func _cek(k: bool, pesan: String) -> void:
	if k: print("   ok   : ", pesan)
	else:
		gagal += 1
		print("   GAGAL: ", pesan)

# --- SALINAN APA ADANYA _render_uang_tampil versi lama (sebelum ronde ini) ---
func _render_lama(p, nilai: int, target: String, lbl_kiri, lbl_kanan):
	if target == "pemain":
		var baris_u_p = "Your Coins: [color=" + p.warna_pemain_hex + "]" + str(nilai) + "[/color]"
		var baris_b_p = "Your Stars: ⭐ x " + str(p.daftar_pemain[0].bintang)
		var str_permata_p = ""
		for x in p.koleksi_permata_pemain: str_permata_p += x + " "
		var baris_p_p = "Gems: " + (str_permata_p if str_permata_p != "" else "0")
		lbl_kiri.text = "[center]" + baris_u_p + "\n" + baris_b_p + "\n[font_size=18][color=#00ffff]" + baris_p_p + "[/color][/font_size][/center]"
	if target == "musuh":
		var baris_u_m = "Enemy Coins: [color=" + p.warna_musuh_hex + "]" + str(nilai) + "[/color]"
		var baris_b_m = "Enemy Stars: ⭐ x " + str(p.daftar_pemain[1].bintang)
		var str_permata_m = ""
		for x in p.koleksi_permata_musuh: str_permata_m += x + " "
		var baris_p_m = "Gems: " + (str_permata_m if str_permata_m != "" else "0")
		lbl_kanan.text = "[center]" + baris_u_m + "\n" + baris_b_m + "\n[font_size=18][color=#00ffff]" + baris_p_m + "[/color][/font_size][/center]"

func _ready():
	var p = PemainScript.new()

	print("== S1 aturan geser kamera")
	var total = 0; var cocok_solo = 0; var total_solo = 0; var cocok = 0
	for peran in ["", "host", "client"]:
		StatusJaringan.peran_multiplayer = peran
		for gil in ["pemain", "musuh"]:
			for fase in ["awal", "akhir", "konfrontasi", "duel_berlangsung"]:
				for gerak in [false, true]:
					for bidik in [false, true]:
						p.giliran_sekarang = gil; p.fase_giliran = fase
						p.sedang_bergerak = gerak; p.mode_membidik = bidik
						var lama = (gil == "pemain" and fase == "awal" and not gerak) or bidik
						var harap = lama if peran == "" else ((fase == "awal" and not gerak) or bidik)
						total += 1
						var hasil = p._boleh_geser_kamera()
						if hasil == harap: cocok += 1
						else: print("      beda: peran=%s giliran=%s fase=%s gerak=%s bidik=%s -> %s" % [peran, gil, fase, gerak, bidik, hasil])
						if peran == "":
							total_solo += 1
							if hasil == lama: cocok_solo += 1
	_cek(cocok_solo == total_solo, "SOLO: sama persis dengan ekspresi lama di %d/%d kombinasi" % [cocok_solo, total_solo])
	_cek(cocok == total, "semua peran sesuai aturan (%d/%d)" % [cocok, total])
	StatusJaringan.peran_multiplayer = ""

	print("== S2 panel koin/bintang/permata")
	p.teks_uang = RichTextLabel.new(); p.teks_bintang = RichTextLabel.new()
	var lama_kiri = RichTextLabel.new(); var lama_kanan = RichTextLabel.new()
	p.daftar_pemain.assign([DataPemain.new(DataPemain.JenisKontrol.MANUSIA_LOKAL, "A"), DataPemain.new(DataPemain.JenisKontrol.AI, "B")])
	var rng = RandomNumberGenerator.new(); rng.seed = 42
	var sama = 0; var n = 0; var tukar_ok = 0
	for i in 60:
		p.daftar_pemain[0].uang = rng.randi_range(0, 6000); p.daftar_pemain[1].uang = rng.randi_range(0, 6000)
		p.daftar_pemain[0].bintang = rng.randi_range(0, 10); p.daftar_pemain[1].bintang = rng.randi_range(0, 10)
		p.koleksi_permata_pemain.assign(["[img=28]h[/img]", "[img=28]k[/img]"].slice(0, rng.randi_range(0, 2)))
		p.koleksi_permata_musuh.assign(["[img=28]b[/img]"].slice(0, rng.randi_range(0, 1)))
		p.warna_pemain_hex = ["#ffffff", "#44ff44", "#ff4444"][rng.randi_range(0, 2)]
		p.warna_musuh_hex = ["#ffffff", "#44ff44", "#ff4444"][rng.randi_range(0, 2)]
		var nilai0 = rng.randi_range(0, 6000); var nilai1 = rng.randi_range(0, 6000) # nilai animasi tween
		# versi lama
		_render_lama(p, nilai0, "pemain", lama_kiri, lama_kanan)
		_render_lama(p, nilai1, "musuh", lama_kiri, lama_kanan)
		# solo / host (slot_lokal 0) -> harus identik
		p.slot_lokal = 0
		p._render_uang_tampil(nilai0, "pemain"); p._render_uang_tampil(nilai1, "musuh")
		n += 1
		if p.teks_uang.text == lama_kiri.text and p.teks_bintang.text == lama_kanan.text: sama += 1
		# client (slot_lokal 1) -> panel kiri = slot 1 sebagai "Your", kanan = slot 0 sebagai "Enemy"
		p.slot_lokal = 1
		p._render_uang_tampil(nilai0, "pemain"); p._render_uang_tampil(nilai1, "musuh")
		var harap_kiri = lama_kanan.text.replace("Enemy Coins", "Your Coins").replace("Enemy Stars", "Your Stars")
		var harap_kanan = lama_kiri.text.replace("Your Coins", "Enemy Coins").replace("Your Stars", "Enemy Stars")
		if p.teks_uang.text == harap_kiri and p.teks_bintang.text == harap_kanan: tukar_ok += 1
		if not p.uang_pemain_tampil == nilai0 or not p.uang_musuh_tampil == nilai1: tukar_ok -= 1000
	_cek(sama == n, "SOLO/HOST: teks panel identik dengan versi lama (%d/%d keadaan acak)" % [sama, n])
	_cek(tukar_ok == n, "CLIENT: panel kiri 'Your' = slot 1, kanan 'Enemy' = slot 0; angka animasi tetap per slot (%d/%d)" % [tukar_ok, n])

	for x in [p.teks_uang, p.teks_bintang, lama_kiri, lama_kanan]: x.free()
	p.free()
	print("\nUJI SOLO KAMERA/HUD SELESAI -- gagal: ", gagal)
	get_tree().quit()
