extends RefCounted
class_name DataEvent
# ============================================================
# EVENT MINGGUAN OFFLINE + MASTERY ELEMEN (Fase 8 G0) -- konstanta & hitungan tanggal saja.
# Angka dari Opus (docs/RENCANA_fase6_9.md bagian 3.1). Aturan main TIDAK berubah (K9=a): hanya misi & hadiah.
# Minggu = Senin 00:00 jam HP s/d Minggu 23:59. Nomor minggu = jumlah minggu sejak Senin 1970-01-05 (bukan
# nomor minggu ISO yang kembali ke 1 tiap tahun -> putaran 6 event tetap rapi di pergantian tahun 52/53 -> 1).
# Barang toko event ada di DataKosmetik.KATALOG ("sumber": "event"); gelar mastery juga ("sumber": "mastery").
# ============================================================

const JUMLAH_EVENT := 6
const HARI_SENIN_PERTAMA := 4 # 1970-01-01 = Kamis -> Senin pertama = hari ke-4 sejak epoch
# "stat" misi event: kunci statistik pertandingan (pemain.gd statistik_slot), atau khusus:
# "_match_role" laga tuntas dgn role = elemen event, "_menang_role" menang dgn role itu,
# "_duel_elemen" duel menang memakai elemen event (stat "menang_elemen").
const EVENT := [
	{"id": "fire", "nama": "Fire Week", "elemen": "api"},
	{"id": "water", "nama": "Water Week", "elemen": "air"},
	{"id": "wind", "nama": "Wind Week", "elemen": "angin"},
	{"id": "lightning", "nama": "Lightning Week", "elemen": "petir"},
	{"id": "earth", "nama": "Earth Week", "elemen": "tanah"},
	{"id": "duel", "nama": "Duel Week", "elemen": ""},
]
const MISI_ELEMEN := [
	{"teks": "Finish 5 matches as %s", "target": 5, "stat": "_match_role", "token": 30},
	{"teks": "Win 4 duels with %s", "target": 4, "stat": "_duel_elemen", "token": 30},
	{"teks": "Win 2 matches as %s", "target": 2, "stat": "_menang_role", "token": 40},
]
const MISI_DUEL := [
	{"teks": "Guess 5 duels right", "target": 5, "stat": "tebak_benar", "token": 30},
	{"teks": "Claim 2 bounties", "target": 2, "stat": "bounty", "token": 30},
	{"teks": "Win 8 duels", "target": 8, "stat": "duel_menang", "token": 40},
]
const NAMA_ELEMEN := {"api": "FIRE", "air": "WATER", "tanah": "EARTH", "petir": "LIGHTNING", "angin": "WIND"}

# --- Mastery elemen (K11=a: Crowns + gelar saja, TANPA bonus statistik) ---
# XP per elemen dari tiap laga tuntas: role = elemen itu -> +1 main, +2 lagi kalau menang;
# tiap duel menang memakai elemen itu -> +1 (role apa pun).
const XP_MASTERY := {"main": 1, "menang": 2, "duel": 1}
const LEVEL_MAKS := 10
const XP_LEVEL := [0, 5, 12, 22, 35, 55, 80, 115, 160, 220] # XP total untuk MENCAPAI Lv 1..10
const CROWNS_LEVEL := {2: 30, 3: 50, 4: 75, 5: 100, 6: 150, 7: 200, 8: 250, 9: 300, 10: 400} # saat mencapai level itu
const GELAR_MASTERY := {"api": "title_fire_master", "air": "title_water_master", "tanah": "title_earth_master",
	"petir": "title_lightning_master", "angin": "title_wind_master"} # diberikan saat Lv 10

# ------------------------------------------------------------
# Tanggal & minggu
# ------------------------------------------------------------
static func tanggal_sah(t: String) -> bool:
	var b = t.split("-")
	if t.length() != 10 or b.size() != 3 or not (b[0].is_valid_int() and b[1].is_valid_int() and b[2].is_valid_int()):
		return false
	return int(b[0]) >= 2000 and int(b[1]) >= 1 and int(b[1]) <= 12 and int(b[2]) >= 1 and int(b[2]) <= 31

static func hari_epoch(t: String) -> int:
	# Jumlah hari sejak 1970-01-01 untuk "YYYY-MM-DD" (-1 bila tidak sah).
	if not tanggal_sah(t):
		return -1
	var b = t.split("-")
	return floori(Time.get_unix_time_from_datetime_dict({"year": int(b[0]), "month": int(b[1]), "day": int(b[2]),
		"hour": 0, "minute": 0, "second": 0}) / 86400.0)

static func minggu_dari_tanggal(t: String) -> int:
	# Nomor minggu (Senin awal); -1 bila tanggal tidak sah.
	var h = hari_epoch(t)
	return -1 if h < 0 else floori((h - HARI_SENIN_PERTAMA) / 7.0)

static func indeks_event(minggu: int) -> int:
	return posmod(minggu, JUMLAH_EVENT)

static func event_minggu(minggu: int) -> Dictionary:
	return EVENT[indeks_event(minggu)]

static func daftar_misi(minggu: int) -> Array:
	return MISI_DUEL if str(event_minggu(minggu)["elemen"]) == "" else MISI_ELEMEN

static func teks_misi(minggu: int, i: int) -> String:
	var ms: Array = daftar_misi(minggu)
	if i < 0 or i >= ms.size():
		return ""
	var el = str(event_minggu(minggu)["elemen"])
	return str(ms[i]["teks"]) % NAMA_ELEMEN[el] if el != "" else str(ms[i]["teks"])

static func detik_sampai_minggu_baru(dt: Dictionary) -> int:
	# dt = Time.get_datetime_dict_from_system() (jam HP; weekday 0 = Minggu). Sisa detik sampai Senin 00:00 berikutnya.
	var hari_lagi = posmod(8 - int(dt.get("weekday", 1)), 7)
	if hari_lagi == 0:
		hari_lagi = 7
	return hari_lagi * 86400 - (int(dt.get("hour", 0)) * 3600 + int(dt.get("minute", 0)) * 60 + int(dt.get("second", 0)))

static func teks_sisa(detik: int) -> String:
	detik = maxi(0, detik)
	var h = detik / 86400
	var j = (detik % 86400) / 3600
	if h > 0:
		return "Ends in %dd %dh" % [h, j]
	return "Ends in %dh %dm" % [j, (detik % 3600) / 60]

# ------------------------------------------------------------
# Mastery
# ------------------------------------------------------------
static func level_mastery(xp: int) -> int:
	var lv = 1
	for i in range(XP_LEVEL.size()):
		if xp >= int(XP_LEVEL[i]):
			lv = i + 1
	return lv

static func info_mastery(xp: int) -> Dictionary:
	# {level, xp_di_level, xp_untuk_naik (0 = maks)} untuk bilah di layar PROFILE.
	var lv = level_mastery(xp)
	if lv >= LEVEL_MAKS:
		return {"level": lv, "xp_di_level": xp - int(XP_LEVEL[LEVEL_MAKS - 1]), "xp_untuk_naik": 0}
	return {"level": lv, "xp_di_level": xp - int(XP_LEVEL[lv - 1]), "xp_untuk_naik": int(XP_LEVEL[lv]) - int(XP_LEVEL[lv - 1])}
