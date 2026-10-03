extends Node
# Fase 7 G1 (rig-only): katalog, profil VERSI 4, beli/pakai. HOME diarahkan ke folder uji supaya profil sungguhan tidak tersentuh.
func _ready() -> void:
	var gagal := 0
	var P = ProfilPemain
	var K = DataKosmetik
	# 0) katalog sesuai RENCANA 2.1
	var total := 0
	var toko = K.KATALOG.keys().filter(func(k): return K.sumber_dari(k) == "") # Fase 8: + barang event/mastery di luar toko Crowns
	for k in toko:
		total += int(K.KATALOG[k]["harga"])
	gagal += _cek("katalog 24 barang", toko.size() == 24)
	gagal += _cek("8 pawn / 10 title / 6 frame", K.daftar("pawn").size() == 8 and K.daftar("title").size() == 10 and K.daftar("frame").size() == 6)
	gagal += _cek("total harga 27750", total == 27750)
	gagal += _cek("AWAL harga 0 & jenis cocok", K.AWAL.size() == 3 and K.AWAL.keys().all(func(j): return int(K.KATALOG[K.AWAL[j]]["harga"]) == 0 and K.jenis_dari(K.AWAL[j]) == j))
	gagal += _cek("hanya 3 barang harga 0", toko.filter(func(k): return int(K.KATALOG[k]["harga"]) == 0).size() == 3)
	gagal += _cek("sah_untuk_jenis: id salah/jenis salah -> AWAL", K.sah_untuk_jenis("zzz", "pawn") == "pawn_classic" and K.sah_untuk_jenis("title_duelist", "pawn") == "pawn_classic" and K.sah_untuk_jenis("pawn_rose", "pawn") == "pawn_rose")
	# 1) berkas VERSI 3 (tanpa bagian "kosmetik") -> kosong, data lama utuh
	var c = ConfigFile.new()
	c.set_value("profil", "versi", 3)
	c.set_value("profil", "id", "abcdef0123456789")
	c.set_value("profil", "nama", "Lama Okay")
	c.set_value("profil", "xp", 777)
	c.set_value("profil", "crowns", 321)
	c.set_value("sosial", "respect", 4)
	c.set_value("sosial", "mvp_total", 2)
	c.save(P.BERKAS)
	P.muat()
	gagal += _cek("v3 data lama utuh", P.xp_total == 777 and P.crowns == 321 and P.nama == "Lama Okay" and P.respect == 4 and P.mvp_total == 2)
	gagal += _cek("v3 -> kosmetik kosong, AWAL dimiliki & dipakai", P.kosmetik_dimiliki.is_empty() and P.kosmetik_dipakai.is_empty() and P.punya_kosmetik("pawn_classic") and P.kosmetik_pakai("title") == "title_rookie" and P.kosmetik_pakai("frame") == "frame_plain")
	gagal += _cek("VERSI >= 4", P.VERSI >= 4)
	# 2) beli ditolak
	P.crowns = 100
	P.xp_total = 0
	gagal += _cek("beli kurang Crowns ditolak", P.beli("pawn_shadow") == "Need 50 more Crowns" and P.crowns == 100 and P.kosmetik_dimiliki.is_empty())
	P.crowns = 5000
	gagal += _cek("beli level kurang ditolak (Lv1 < 5)", P.beli("pawn_violet") == "Reach Lv 5" and P.crowns == 5000)
	gagal += _cek("beli id tak dikenal ditolak", P.beli("pawn_nope") != "" and P.crowns == 5000)
	gagal += _cek("beli barang AWAL ditolak (sudah dimiliki)", P.beli("pawn_classic") != "" and P.crowns == 5000)
	# 3) beli berhasil: Crowns berkurang, langsung dipakai, tersimpan
	gagal += _cek("beli pawn_shadow ok", P.beli("pawn_shadow") == "" and P.crowns == 4850)
	gagal += _cek("langsung dipakai", P.kosmetik_pakai("pawn") == "pawn_shadow" and P.kosmetik_dimiliki == ["pawn_shadow"])
	gagal += _cek("beli ganda ditolak, Crowns tetap", P.beli("pawn_shadow") != "" and P.crowns == 4850 and P.kosmetik_dimiliki.size() == 1)
	var c2 = ConfigFile.new()
	c2.load(P.BERKAS)
	gagal += _cek("simpan versi=VERSI + bagian kosmetik", int(c2.get_value("profil", "versi", 0)) == P.VERSI and c2.get_value("kosmetik", "dimiliki", []) == ["pawn_shadow"] and c2.get_value("kosmetik", "dipakai", {}).get("pawn", "") == "pawn_shadow")
	gagal += _cek("simpan Crowns 4850", int(c2.get_value("profil", "crowns", 0)) == 4850)
	# 4) syarat level terpenuhi
	P.xp_total = 1000 # Lv 5+ (100+125+150+175=550 -> Lv5; 1000 -> Lv7)
	gagal += _cek("Lv >= 5", P.level_sekarang() >= 5)
	gagal += _cek("beli pawn_violet (Lv5) ok", P.beli("pawn_violet") == "" and P.crowns == 4050 and P.kosmetik_pakai("pawn") == "pawn_violet")
	gagal += _cek("beli title_tile_hunter ok (jenis lain tak mengganggu)", P.beli("title_tile_hunter") == "" and P.kosmetik_pakai("title") == "title_tile_hunter" and P.kosmetik_pakai("pawn") == "pawn_violet")
	# 5) pakai
	gagal += _cek("pakai pawn_shadow (dimiliki)", P.pakai("pawn_shadow") and P.kosmetik_pakai("pawn") == "pawn_shadow")
	gagal += _cek("pakai barang belum dimiliki ditolak", not P.pakai("pawn_gold") and P.kosmetik_pakai("pawn") == "pawn_shadow")
	gagal += _cek("pakai id tak dikenal ditolak", not P.pakai("xxx"))
	gagal += _cek("pakai AWAL = kembali bawaan", P.pakai("pawn_classic") and P.kosmetik_pakai("pawn") == "pawn_classic" and not P.kosmetik_dipakai.has("pawn"))
	# 6) simpan -> muat
	P.pakai("pawn_violet")
	var cr = P.crowns
	P.kosmetik_dimiliki = []
	P.kosmetik_dipakai = {}
	P.muat()
	gagal += _cek("muat ulang v4 dimiliki", P.kosmetik_dimiliki == ["pawn_shadow", "pawn_violet", "title_tile_hunter"])
	gagal += _cek("muat ulang v4 dipakai", P.kosmetik_pakai("pawn") == "pawn_violet" and P.kosmetik_pakai("title") == "title_tile_hunter" and P.kosmetik_pakai("frame") == "frame_plain")
	gagal += _cek("muat ulang Crowns & data lama utuh", P.crowns == cr and P.nama == "Lama Okay" and P.respect == 4 and P.mvp_total == 2)
	# 7) data rusak
	var c3 = ConfigFile.new()
	c3.load(P.BERKAS)
	c3.set_value("kosmetik", "dimiliki", ["pawn_rose", "pawn_rose", "nope", 5, "pawn_classic", "title_duelist"])
	c3.set_value("kosmetik", "dipakai", {"pawn": "pawn_gold", "title": "pawn_rose", "frame": "frame_gold"}) # gold tak dimiliki; title salah jenis; frame tak dimiliki
	c3.save(P.BERKAS)
	P.muat()
	gagal += _cek("rusak: duplikat/tak dikenal/AWAL dibuang", P.kosmetik_dimiliki == ["pawn_rose", "title_duelist"])
	gagal += _cek("rusak: dipakai tak sah -> bawaan", P.kosmetik_pakai("pawn") == "pawn_classic" and P.kosmetik_pakai("title") == "title_rookie" and P.kosmetik_pakai("frame") == "frame_plain")
	var c4 = ConfigFile.new()
	c4.load(P.BERKAS)
	c4.set_value("kosmetik", "dimiliki", "bukan array")
	c4.set_value("kosmetik", "dipakai", 7)
	c4.save(P.BERKAS)
	P.muat()
	gagal += _cek("tipe salah -> kosong tanpa crash", P.kosmetik_dimiliki.is_empty() and P.kosmetik_dipakai.is_empty())
	# 8) Crowns tidak pernah negatif; profil baru
	P.crowns = 150
	P.xp_total = 0
	gagal += _cek("harga pas Crowns -> 0, tidak negatif", P.beli("title_tile_hunter") == "" and P.crowns == 0)
	DirAccess.remove_absolute(P.BERKAS)
	DirAccess.remove_absolute(P.BERKAS_SEMENTARA)
	DirAccess.remove_absolute(P.BERKAS_CADANGAN)
	P.muat()
	gagal += _cek("profil baru: kosmetik kosong, AWAL", P.kosmetik_dimiliki.is_empty() and P.kosmetik_pakai("pawn") == "pawn_classic")
	print("KOSMETIK gagal=", gagal)
	get_tree().quit()

func _cek(nama: String, ok: bool) -> int:
	print("KOSMETIK ", "OK   " if ok else "GAGAL", " ", nama)
	return 0 if ok else 1
