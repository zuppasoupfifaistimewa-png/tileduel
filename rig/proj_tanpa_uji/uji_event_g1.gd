extends Node
# Fase 8 G1 (rig-only): progres misi event + mastery dari catat_akhir_match, beli_event dgn token, tanggal mundur.
# Minggu 2026-09-28..10-04 = Wind Week (angin), 2026-09-14 = Fire Week (api), 2026-10-19 = Duel Week. HOME = folder uji.
func _ready() -> void:
	var gagal := 0
	var P = ProfilPemain
	var D = DataEvent
	_bersih()
	# 1) Fire Week: laga solo menang dgn role api, 2 duel menang dgn api
	P._tanggal_uji = "2026-09-14"
	P.segarkan_event()
	gagal += _cek("Fire Week: event fire, 3 misi", str(P.event_sekarang()["id"]) == "fire" and P.misi_event.size() == 3)
	var r = P.catat_akhir_match({"menang": true, "quick": true, "role": "api", "stat": {"giliran": 20, "duel_menang": 2, "menang_elemen": {"api": 2, "air": 0, "tanah": 0, "petir": 0, "angin": 0}}})
	gagal += _cek("laga 1: finish 1/5, duel 2/4, menang 1/2", int(P.misi_event[0]["progres"]) == 1 and int(P.misi_event[1]["progres"]) == 2 and int(P.misi_event[2]["progres"]) == 1 and P.token_event == 0)
	gagal += _cek("mastery api = 1 + 2 + 2 = 5 (Lv 2 +30 Crowns), elemen lain 0", P.xp_mastery("api") == 5 and P.xp_mastery("air") == 0 and r["mastery_naik"].size() == 1 and r["mastery_naik"][0]["elemen"] == "api" and int(r["mastery_naik"][0]["level"]) == 2 and int(r["mastery_naik"][0]["crowns"]) == 30)
	gagal += _cek("ringkasan kosong utk misi event belum selesai", r["misi_event_selesai"].is_empty() and int(r["token_event_didapat"]) == 0)
	r = P.catat_akhir_match({"menang": true, "quick": true, "role": "api", "stat": {"giliran": 20, "menang_elemen": {"api": 2}}})
	gagal += _cek("laga 2: duel 4/4 selesai +30 token, menang 2/2 selesai +40", P.token_event == 70 and bool(P.misi_event[1]["selesai"]) and bool(P.misi_event[2]["selesai"]) and not bool(P.misi_event[0]["selesai"]) and int(r["token_event_didapat"]) == 70 and r["misi_event_selesai"].size() == 2)
	gagal += _cek("progres dibatasi target", int(P.misi_event[1]["progres"]) == 4 and int(P.misi_event[2]["progres"]) == 2)
	for i in range(3):
		P.catat_akhir_match({"menang": false, "quick": true, "role": "api", "stat": {"giliran": 10}})
	gagal += _cek("laga ke-5 role api kalah: finish 5/5 +30 -> 100 token", bool(P.misi_event[0]["selesai"]) and P.token_event == 100)
	r = P.catat_akhir_match({"menang": true, "quick": true, "role": "api", "stat": {"giliran": 10, "menang_elemen": {"api": 1}}})
	gagal += _cek("misi sudah selesai tidak memberi token lagi", P.token_event == 100 and int(r["token_event_didapat"]) == 0)
	# 2) laga dgn role lain & elemen lain tidak memajukan misi Fire tapi memajukan mastery
	var tk = P.token_event
	var p0 = int(P.misi_event[0]["progres"])
	P.catat_akhir_match({"menang": true, "quick": false, "role": "air", "stat": {"giliran": 10, "menang_elemen": {"air": 1, "petir": 2}}})
	gagal += _cek("role air: misi Fire tidak maju", int(P.misi_event[0]["progres"]) == p0 and P.token_event == tk)
	gagal += _cek("mastery air = 1+2+1 = 4, petir = 2 (duel), api tetap", P.xp_mastery("air") == 4 and P.xp_mastery("petir") == 2)
	P.catat_akhir_match({"menang": true, "quick": true, "role": "", "stat": {"giliran": 5, "menang_elemen": {"tanah": 1}}})
	gagal += _cek("tanpa role: hanya XP duel (tanah 1)", P.xp_mastery("tanah") == 1)
	P.catat_akhir_match({"menang": true, "quick": true, "role": "zzz", "stat": {"giliran": 5}})
	gagal += _cek("role tidak dikenal: mastery tidak berubah, tidak error", not P.mastery.has("zzz"))
	# 3) tambah_double tidak menggandakan token/mastery
	var r2 = P.catat_akhir_match({"menang": true, "quick": true, "role": "api", "stat": {"giliran": 10}})
	var tk2 = P.token_event
	var ma2 = P.xp_mastery("api")
	P.tambah_double(r2)
	gagal += _cek("DOUBLE tidak mengubah token & mastery", P.token_event == tk2 and P.xp_mastery("api") == ma2)
	# 4) Toko event: beli_event
	P._tanggal_uji = "2026-09-14"
	P.token_event = 50
	gagal += _cek("token kurang: 'Need 10 more tokens'", P.beli_event("pawn_ember") == "Need 10 more tokens" and P.token_event == 50 and not P.punya_kosmetik("pawn_ember"))
	P.token_event = 130
	gagal += _cek("beli pawn_ember (60): token 70, dimiliki, langsung dipakai", P.beli_event("pawn_ember") == "" and P.token_event == 70 and P.punya_kosmetik("pawn_ember") and P.kosmetik_pakai("pawn") == "pawn_ember")
	gagal += _cek("beli lagi ditolak", P.beli_event("pawn_ember") == "You already own this." and P.token_event == 70)
	gagal += _cek("barang event minggu lain ditolak", P.beli_event("pawn_tide") == "Not in this event" and P.token_event == 70)
	gagal += _cek("barang toko Crowns / mastery / tak dikenal ditolak", P.beli_event("pawn_rose") == "Unknown item." and P.beli_event("title_fire_master") == "Unknown item." and P.beli_event("xxx") == "Unknown item.")
	P.crowns = 9999
	gagal += _cek("beli Crowns utk barang event tetap ditolak", P.beli("title_flame_heart") == "Event item")
	P.muat()
	gagal += _cek("simpan-muat: token & barang event utuh", P.token_event == 70 and P.punya_kosmetik("pawn_ember"))
	# 5) beda minggu: misi baru, barang Fire tidak bisa dibeli di Wind Week; barang Wind bisa
	P._tanggal_uji = "2026-09-28"
	P.segarkan_event()
	gagal += _cek("Wind Week: misi baru, token tetap", str(P.event_sekarang()["id"]) == "wind" and int(P.misi_event[0]["progres"]) == 0 and P.token_event == 70)
	gagal += _cek("Wind Week: barang Fire ditolak, barang Wind (40) dibeli", P.beli_event("title_flame_heart") == "Not in this event" and P.beli_event("title_sky_dancer") == "" and P.token_event == 30)
	P.catat_akhir_match({"menang": true, "quick": true, "role": "angin", "stat": {"giliran": 10, "menang_elemen": {"angin": 1}}})
	gagal += _cek("Wind Week: role angin memajukan misi 1, 2 & 3", int(P.misi_event[0]["progres"]) == 1 and int(P.misi_event[1]["progres"]) == 1 and int(P.misi_event[2]["progres"]) == 1)
	# 6) tanggal mundur: misi event tidak maju & toko event dikunci, mastery tetap maju
	var tk3 = P.token_event
	var xa = P.xp_mastery("angin")
	var pr0 = int(P.misi_event[0]["progres"])
	P._tanggal_uji = "2026-09-20"
	gagal += _cek("tanggal mundur", P.tanggal_mundur())
	var r3 = P.catat_akhir_match({"menang": true, "quick": true, "role": "angin", "stat": {"giliran": 10, "menang_elemen": {"angin": 1}}})
	gagal += _cek("mundur: misi event & minggu tidak berubah", int(P.misi_event[0]["progres"]) == pr0 and P.token_event == tk3 and str(P.event_sekarang()["id"]) == "wind" and r3["misi_event_selesai"].is_empty())
	gagal += _cek("mundur: mastery tetap maju (+1+2+1)", P.xp_mastery("angin") == xa + 4)
	P.token_event = 500
	gagal += _cek("mundur: toko event dikunci", P.beli_event("pawn_breeze") == "Event paused: check your date" and P.token_event == 500)
	P._tanggal_uji = "2026-09-28"
	gagal += _cek("tanggal kembali: toko terbuka", P.beli_event("pawn_breeze") == "")
	# 7) Duel Week: stat tebak_benar, bounty, duel_menang
	P._tanggal_uji = "2026-10-19"
	P.segarkan_event()
	gagal += _cek("Duel Week", str(P.event_sekarang()["id"]) == "duel")
	P.catat_akhir_match({"menang": true, "quick": true, "role": "api", "stat": {"giliran": 10, "tebak_benar": 3, "bounty": 1, "duel_menang": 5, "menang_elemen": {"api": 5}}})
	gagal += _cek("Duel: tebak 3/5, bounty 1/2, duel menang 5/8", int(P.misi_event[0]["progres"]) == 3 and int(P.misi_event[1]["progres"]) == 1 and int(P.misi_event[2]["progres"]) == 5)
	var r4 = P.catat_akhir_match({"menang": false, "quick": true, "role": "", "stat": {"giliran": 10, "tebak_benar": 4, "bounty": 1, "duel_menang": 4}})
	gagal += _cek("Duel: semua selesai = 100 token (+ dari sebelumnya)", r4["misi_event_selesai"].size() == 3 and int(r4["token_event_didapat"]) == 100)
	gagal += _cek("Duel: role apa pun (misi tak butuh role) -- misi 'role' tidak muncul", D.daftar_misi(P.minggu_event).size() == 3)
	# 8) mastery sampai Lv 10: Crowns total 1555 + gelar masuk dimiliki (tidak otomatis dipakai)
	_bersih()
	P._tanggal_uji = "2026-09-14"
	P.segarkan_event()
	P.crowns = 0
	P.xp_total = 0
	var cr_naik = 0
	var lv_terlihat := []
	P.mastery = {"api": 215}
	var rr = P.catat_akhir_match({"menang": true, "quick": true, "role": "api", "stat": {"giliran": 0}})
	for n in rr["mastery_naik"]:
		cr_naik += int(n["crowns"])
		lv_terlihat.append(int(n["level"]))
	gagal += _cek("215 -> 218: tidak naik; 5 XP lagi", P.xp_mastery("api") == 218 and rr["mastery_naik"].is_empty())
	rr = P.catat_akhir_match({"menang": true, "quick": true, "role": "api", "stat": {"giliran": 0}})
	gagal += _cek("Lv 10 dicapai: Crowns 400 + gelar Fire Master, tidak otomatis dipakai", rr["mastery_naik"].size() == 1 and int(rr["mastery_naik"][0]["level"]) == 10 and int(rr["mastery_naik"][0]["crowns"]) == 400 and rr["mastery_naik"][0]["gelar"] == "title_fire_master" and P.punya_kosmetik("title_fire_master") and P.kosmetik_pakai("title") != "title_fire_master")
	gagal += _cek("pakai gelar mastery", P.pakai("title_fire_master") and P.kosmetik_pakai("title") == "title_fire_master")
	rr = P.catat_akhir_match({"menang": true, "quick": true, "role": "api", "stat": {"giliran": 0}})
	gagal += _cek("sudah maks: tidak ada hadiah lagi, gelar tidak dobel", rr["mastery_naik"].is_empty() and P.kosmetik_dimiliki.count("title_fire_master") == 1)
	# loncat banyak level sekaligus (data uji): 0 -> 220 lewat satu laga tidak mungkin, uji lewat _tambah_xp_mastery
	var nk := []
	P.mastery = {}
	P.crowns = 0
	P._tambah_xp_mastery("air", 300, nk)
	gagal += _cek("loncat Lv1 -> Lv10: 9 hadiah, Crowns 1555, gelar Water Master", nk.size() == 9 and P.crowns == 1555 and P.punya_kosmetik("title_water_master"))
	P.simpan()
	P.muat()
	gagal += _cek("simpan-muat: gelar & mastery utuh", P.punya_kosmetik("title_water_master") and P.xp_mastery("air") == 300)
	# 9) tanpa tanggal sah (jam HP rusak): misi event tidak crash, mastery jalan
	P._tanggal_uji = "zzz"
	_bersih()
	var r5 = P.catat_akhir_match({"menang": true, "quick": true, "role": "air", "stat": {"giliran": 5, "menang_elemen": {"air": 1}}})
	gagal += _cek("tanggal rusak: tidak error, mastery air = 4", P.xp_mastery("air") == 4 and r5["misi_event_selesai"].is_empty())
	P._tanggal_uji = ""
	_bersih()
	print("EVENT_G1 gagal=", gagal)
	get_tree().quit()

func _bersih() -> void:
	var P = ProfilPemain
	P._tanggal_uji = ""
	DirAccess.remove_absolute(P.BERKAS)
	DirAccess.remove_absolute(P.BERKAS_SEMENTARA)
	DirAccess.remove_absolute(P.BERKAS_CADANGAN)
	P.muat()

func _cek(nama: String, ok: bool) -> int:
	print("EVENT_G1 ", "OK   " if ok else "GAGAL", " ", nama)
	return 0 if ok else 1
