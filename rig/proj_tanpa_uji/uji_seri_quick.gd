extends Node
# UJI T3b (Fase 1): pemenang Quick Match saat kekayaan seri, tanpa adegan penuh.
var gagal = 0

func _buat(uang: Array, milik: Array, level: Array) -> Node:
	# milik[i] = slot pemilik petak i (-1 = netral); level[i] = level menara.
	var p = load("res://uji_sim_pemain.gd").new() # TIDAK dimasukkan ke tree (_ready & @onready tidak jalan)
	var d = []
	for u in uang:
		var x = DataPemain.new(DataPemain.JenisKontrol.AI, "")
		x.uang = u
		d.append(x)
	p.daftar_pemain.assign(d)
	var papan: Array[Node3D] = []
	for i in milik.size():
		papan.append(Node3D.new())
	p.rute_papan = papan
	var st = []
	for m in milik: st.append(m >= 0)
	p.status_kepemilikan_petak = st
	p.pemilik_petak.assign(milik)
	p.level_menara_petak = level.duplicate()
	return p

func _cek(nama: String, ok: bool, info = "") -> void:
	print(("OK    " if ok else "GAGAL ") + nama + ("" if str(info) == "" else "  " + str(info)))
	if not ok: gagal += 1

func _ready():
	# a) dua slot, kekayaan & petak sama -> lempar koin; dua-duanya pernah menang
	var menang = {}
	var semua_koin = true
	for sd in 20:
		var p = _buat([2000, 2000], [0, 1, -1, -1], [0, 0, 0, 0])
		p.mesin_acak.seed = sd * 97 + 1
		var h = p._pemenang_kekayaan()
		menang[h["slot"]] = true
		semua_koin = semua_koin and h["koin"]
		p.free()
	_cek("a) seri penuh -> lempar koin", semua_koin and menang.size() == 2, menang.keys())
	# b) kekayaan sama, petak beda -> petak terbanyak menang tanpa koin
	var p2 = _buat([1700, 2000], [0, 0, 1, -1], [0, 0, 0, 0]) # 1700+600 = 2300 ; 2000+300 = 2300
	var h2 = p2._pemenang_kekayaan()
	_cek("b) petak terbanyak", h2["slot"] == 0 and not h2["koin"], h2)
	p2.free()
	# c) menara ikut dihitung: slot 1 punya menara Lv2 (300+500+800)
	var p3 = _buat([3000, 1500, 2900, 100], [1, -1, -1, -1], [2, 0, 0, 0])
	_cek("c) kekayaan menara Lv2", p3._kekayaan_slot(1) == 3100 and p3._pemenang_kekayaan()["slot"] == 1, [p3._kekayaan_slot(0), p3._kekayaan_slot(1)])
	p3.free()
	# d) tiga pemain seri penuh -> ketiganya pernah menang lewat koin
	var menang3 = {}
	for sd in 40:
		var p4 = _buat([1000, 1000, 1000, 500], [0, 1, 2, -1], [0, 0, 0, 0])
		p4.mesin_acak.seed = sd * 13 + 5
		var h4 = p4._pemenang_kekayaan()
		menang3[h4["slot"]] = true
		p4.free()
	_cek("d) tiga seri", menang3.size() == 3 and not menang3.has(3), menang3.keys())
	# e) papan peringkat: Quick urut kekayaan, pemenang (hasil koin) di baris 1
	var p5 = _buat([2000, 2000, 500], [0, 1, 2, 2], [0, 0, 0, 0])
	p5.mode_quick = true
	var ks = [[], [], [], []]
	p5.koleksi_permata_slot = ks
	var papan = p5._susun_papan_skor(1)
	var urut = []
	for b in papan: urut.append(int(b["slot"]))
	_cek("e) papan Quick pemenang di atas", urut == [1, 0, 2], urut)
	# f) Classic: urut koin, tapi pemenang (menang di START) tetap baris 1
	p5.mode_quick = false
	p5.daftar_pemain[2].uang = 5000
	papan = p5._susun_papan_skor(0)
	urut = []
	for b in papan: urut.append(int(b["slot"]))
	_cek("f) papan Classic pemenang di atas", urut == [0, 2, 1], urut)
	p5.free()
	print("UJI_SERI_QUICK SELESAI gagal=", gagal)
	get_tree().quit()
