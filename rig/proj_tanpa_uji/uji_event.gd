extends Node
# Fase 8 G0 (rig-only): DataEvent (minggu, putaran 6 event, sisa waktu, mastery), katalog event/mastery, profil VERSI 5
# (migrasi v4, ganti minggu, Minggu->Senin, tahun baru, tanggal mundur, data rusak). HOME diarahkan ke folder uji.
func _ready() -> void:
	var gagal := 0
	var P = ProfilPemain
	var D = DataEvent
	var K = DataKosmetik
	# 0) data & hitungan tanggal
	gagal += _cek("6 event, 3 misi tiap jenis", D.EVENT.size() == 6 and D.MISI_ELEMEN.size() == 3 and D.MISI_DUEL.size() == 3)
	gagal += _cek("tanggal_sah", D.tanggal_sah("2026-10-03") and not D.tanggal_sah("") and not D.tanggal_sah("2026-13-01") and not D.tanggal_sah("abc") and not D.tanggal_sah("2026-1-3"))
	var w = D.minggu_dari_tanggal("2026-10-03")
	print("EVENT info: minggu 2026-10-03 = ", w, " -> ", D.event_minggu(w)["nama"], "; minggu depan -> ", D.event_minggu(w + 1)["nama"])
	gagal += _cek("Sabtu & Minggu satu minggu; Senin minggu baru", D.minggu_dari_tanggal("2026-09-28") == w and D.minggu_dari_tanggal("2026-10-04") == w and D.minggu_dari_tanggal("2026-10-05") == w + 1)
	gagal += _cek("tanggal < 2000 / rusak -> minggu -1", D.minggu_dari_tanggal("1999-12-31") == -1 and D.minggu_dari_tanggal("zzz") == -1)
	var tb = D.minggu_dari_tanggal("2026-12-28")
	gagal += _cek("tahun baru 2026->2027 (Kamis 1 Jan): satu minggu", D.minggu_dari_tanggal("2027-01-01") == tb and D.minggu_dari_tanggal("2027-01-03") == tb and D.minggu_dari_tanggal("2027-01-04") == tb + 1)
	var t20 = D.minggu_dari_tanggal("2020-12-28") # 2020 = 53 minggu ISO
	gagal += _cek("tahun 53 minggu (2020->2021) & 2021-01-04 = +1", D.minggu_dari_tanggal("2021-01-03") == t20 and D.minggu_dari_tanggal("2021-01-04") == t20 + 1)
	gagal += _cek("putaran event +1 tiap minggu (lintas tahun)", D.indeks_event(tb + 1) == (D.indeks_event(tb) + 1) % 6 and D.indeks_event(t20 + 1) == (D.indeks_event(t20) + 1) % 6)
	gagal += _cek("kabisat 2028-02-29 sah, minggu benar", D.minggu_dari_tanggal("2028-02-28") == D.minggu_dari_tanggal("2028-02-29") or D.minggu_dari_tanggal("2028-02-29") == D.minggu_dari_tanggal("2028-02-28") + 1)
	gagal += _cek("sisa: Sabtu 10:00 -> 1d 14h", D.teks_sisa(D.detik_sampai_minggu_baru({"weekday": 6, "hour": 10, "minute": 0, "second": 0})) == "Ends in 1d 14h")
	gagal += _cek("sisa: Senin 00:00 -> 7d 0h", D.teks_sisa(D.detik_sampai_minggu_baru({"weekday": 1, "hour": 0, "minute": 0, "second": 0})) == "Ends in 7d 0h")
	gagal += _cek("sisa: Minggu 23:00 -> 1h 0m", D.teks_sisa(D.detik_sampai_minggu_baru({"weekday": 0, "hour": 23, "minute": 0, "second": 0})) == "Ends in 1h 0m")
	gagal += _cek("mastery level 0->1, 4->1, 5->2, 219->9, 220->10, 9999->10", D.level_mastery(0) == 1 and D.level_mastery(4) == 1 and D.level_mastery(5) == 2 and D.level_mastery(219) == 9 and D.level_mastery(220) == 10 and D.level_mastery(9999) == 10)
	gagal += _cek("info_mastery Lv2 & maks", D.info_mastery(7) == {"level": 2, "xp_di_level": 2, "xp_untuk_naik": 7} and int(D.info_mastery(300)["xp_untuk_naik"]) == 0)
	var cr_total = 0
	for lv in D.CROWNS_LEVEL:
		cr_total += int(D.CROWNS_LEVEL[lv])
	print("EVENT info: Crowns mastery per elemen = ", cr_total, ", semua elemen = ", cr_total * 5)
	gagal += _cek("Crowns mastery Lv2-10 = 1555/elemen", cr_total == 1555 and D.CROWNS_LEVEL.size() == 9)
	gagal += _cek("teks misi Fire & Duel", D.teks_misi(D.EVENT.size() * 100 + 0, 0) != "" and _teks_event(D, "fire", 0) == "Finish 5 matches as FIRE" and _teks_event(D, "duel", 0) == "Guess 5 duels right")
	# katalog event/mastery
	var ok_kat = true
	var tok_total = 0
	for e in D.EVENT:
		var b = K.daftar_event(str(e["id"]))
		ok_kat = ok_kat and b.size() == 3 and K.jenis_dari(b[0]) == "pawn" and K.jenis_dari(b[1]) == "title" and K.jenis_dari(b[2]) == "frame"
		for k in b:
			ok_kat = ok_kat and K.sumber_dari(k) == "event" and int(K.KATALOG[k]["token"]) > 0
			tok_total += int(K.KATALOG[k]["token"])
	gagal += _cek("3 barang (pawn/title/frame) tiap event, harga token 180/event", ok_kat and tok_total == 1080)
	gagal += _cek("gelar mastery ada di katalog (title, sumber mastery)", D.GELAR_MASTERY.values().all(func(k): return K.jenis_dari(k) == "title" and K.sumber_dari(k) == "mastery") and D.GELAR_MASTERY.size() == 5)
	gagal += _cek("toko Crowns tetap 8/10/6", K.daftar("pawn").size() == 8 and K.daftar("title").size() == 10 and K.daftar("frame").size() == 6 and K.daftar("title", "mastery").size() == 5 and K.daftar("pawn", "event").size() == 6)
	gagal += _cek("barang event lolos validasi host", K.sah_untuk_jenis("pawn_ember", "pawn") == "pawn_ember" and K.sah_untuk_jenis("title_fire_master", "title") == "title_fire_master")
	# 1) berkas VERSI 4 (tanpa "event"/"mastery") -> nilai awal, data lama utuh
	var c = ConfigFile.new()
	c.set_value("profil", "versi", 4)
	c.set_value("profil", "id", "abcdef0123456789")
	c.set_value("profil", "nama", "Lama Okay")
	c.set_value("profil", "xp", 777)
	c.set_value("profil", "crowns", 321)
	c.set_value("kosmetik", "dimiliki", ["pawn_rose"])
	c.set_value("kosmetik", "dipakai", {"pawn": "pawn_rose"})
	c.set_value("pembelian", "remove_ads", true)
	c.save(P.BERKAS)
	P._tanggal_uji = ""
	P.muat()
	gagal += _cek("v4 data lama utuh", P.xp_total == 777 and P.crowns == 321 and P.nama == "Lama Okay" and P.kosmetik_pakai("pawn") == "pawn_rose" and P.remove_ads)
	gagal += _cek("v4 -> event/mastery awal", P.token_event == 0 and P.misi_event.is_empty() and P.minggu_event == -1 and P.tanggal_maks == "" and P.mastery.is_empty())
	P._tanggal_uji = "2026-10-03"
	P.segarkan_event()
	gagal += _cek("segarkan: 3 misi, minggu & tanggal_maks diisi", P.misi_event.size() == 3 and P.minggu_event == w and P.tanggal_maks == "2026-10-03")
	var c2 = ConfigFile.new()
	c2.load(P.BERKAS)
	gagal += _cek("tersimpan VERSI 5", int(c2.get_value("profil", "versi", 0)) == 5 and P.VERSI == 5 and int(c2.get_value("event", "minggu", -9)) == w)
	# 2) minggu sama: progres tetap; Minggu -> Senin: misi baru
	P.misi_event[0]["progres"] = 2
	P.token_event = 70
	P.mastery = {"api": 12}
	P.simpan()
	P._tanggal_uji = "2026-10-04"
	P.segarkan_event()
	gagal += _cek("Sabtu -> Minggu: progres tetap", int(P.misi_event[0]["progres"]) == 2 and P.minggu_event == w and P.tanggal_maks == "2026-10-04")
	P.muat()
	gagal += _cek("simpan-muat: token, mastery, progres", P.token_event == 70 and P.xp_mastery("api") == 12 and int(P.misi_event[0]["progres"]) == 2)
	P._tanggal_uji = "2026-10-05"
	P.segarkan_event()
	gagal += _cek("Minggu -> Senin: misi baru, token tidak hangus", int(P.misi_event[0]["progres"]) == 0 and P.minggu_event == w + 1 and P.token_event == 70)
	# 3) tahun baru
	P._tanggal_uji = "2026-12-31"
	P.segarkan_event()
	P.misi_event[1]["progres"] = 3
	P._tanggal_uji = "2027-01-02"
	P.segarkan_event()
	gagal += _cek("31 Des -> 2 Jan (minggu sama): progres tetap", int(P.misi_event[1]["progres"]) == 3 and P.minggu_event == tb)
	P._tanggal_uji = "2027-01-04"
	P.segarkan_event()
	gagal += _cek("-> Senin 4 Jan: misi baru, event berikutnya", int(P.misi_event[1]["progres"]) == 0 and P.minggu_event == tb + 1)
	# 4) tanggal mundur -> berhenti; kembali -> jalan lagi (misi tidak di-reset)
	P.misi_event[2]["progres"] = 1
	P._tanggal_uji = "2026-12-20"
	gagal += _cek("tanggal mundur terdeteksi", P.tanggal_mundur())
	P.segarkan_event()
	gagal += _cek("mundur: misi/minggu/tanggal_maks tidak berubah", P.minggu_event == tb + 1 and int(P.misi_event[2]["progres"]) == 1 and P.tanggal_maks == "2027-01-04")
	P._tanggal_uji = "2027-01-04"
	gagal += _cek("tanggal kembali: tidak mundur lagi", not P.tanggal_mundur())
	P.segarkan_event()
	gagal += _cek("kembali: progres masih ada", int(P.misi_event[2]["progres"]) == 1)
	P._tanggal_uji = "2027-01-11"
	P.segarkan_event()
	gagal += _cek("maju seminggu: misi baru", int(P.misi_event[2]["progres"]) == 0 and P.minggu_event == tb + 2 and P.tanggal_maks == "2027-01-11")
	# 5) data rusak
	var c3 = ConfigFile.new()
	c3.set_value("profil", "versi", 5)
	c3.set_value("profil", "id", "abcdef0123456789")
	c3.set_value("profil", "nama", "Lama Okay")
	c3.set_value("event", "token", -5)
	c3.set_value("event", "misi", "abc")
	c3.set_value("event", "minggu", 3)
	c3.set_value("event", "tanggal_maks", "zzz")
	c3.set_value("mastery", "xp", {"api": -3, "zzz": 5, "air": 7})
	c3.save(P.BERKAS)
	P.muat()
	gagal += _cek("rusak: token 0, tanggal_maks '', mastery disaring", P.token_event == 0 and P.tanggal_maks == "" and P.mastery == {"api": 0, "air": 7} and P.misi_event.is_empty())
	P.segarkan_event()
	gagal += _cek("rusak: segarkan membuat misi ulang", P.misi_event.size() == 3 and P.minggu_event == tb + 2)
	# 6) barang event/mastery tidak bisa dibeli dgn Crowns
	P.crowns = 9999
	gagal += _cek("barang event ditolak di toko Crowns", P.beli("pawn_ember") == "Event item" and P.crowns == 9999 and not P.punya_kosmetik("pawn_ember"))
	gagal += _cek("gelar mastery ditolak", P.beli("title_fire_master") == "Reach Mastery Lv 10" and P.crowns == 9999)
	# 7) profil baru
	P._tanggal_uji = ""
	DirAccess.remove_absolute(P.BERKAS)
	DirAccess.remove_absolute(P.BERKAS_SEMENTARA)
	DirAccess.remove_absolute(P.BERKAS_CADANGAN)
	P.muat()
	gagal += _cek("profil baru: event/mastery awal", P.token_event == 0 and P.misi_event.is_empty() and P.mastery.is_empty() and P.tanggal_maks == "")
	print("EVENT gagal=", gagal)
	get_tree().quit()

func _teks_event(D, id_event: String, i: int) -> String:
	for w in range(6):
		if str(D.event_minggu(w)["id"]) == id_event:
			return D.teks_misi(w, i)
	return ""

func _cek(nama: String, ok: bool) -> int:
	print("EVENT ", "OK   " if ok else "GAGAL", " ", nama)
	return 0 if ok else 1
