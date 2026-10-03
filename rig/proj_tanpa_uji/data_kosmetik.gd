extends RefCounted
class_name DataKosmetik
# ============================================================
# KATALOG KOSMETIK TOKO CROWNS (Fase 7 G1) -- konstanta saja, tanpa aset baru.
# Harga & syarat level FINAL dari Opus (docs/RENCANA_fase6_9.md bagian 2.1). Harga boleh disetel (konstanta);
# barang yang sudah dibeli tidak pernah dicabut. Urutan = urutan tab toko (Pawn / Title / Frame).
# Data tampilan (dipakai G2/G3): pawn "warna" = warna trim (sarung tangan + sepatu; badan tetap warna slot),
# opsional "emisi" (pengali), "logam", "kasar"; title = teks "nama"; frame "border"/"lebar"/"bayangan"/"radius_tambah".
# Barang AWAL (harga 0) selalu dimiliki dan tidak disimpan.
# ============================================================

const JENIS := ["pawn", "title", "frame"]
const AWAL := {"pawn": "pawn_classic", "title": "title_rookie", "frame": "frame_plain"}
const KATALOG := {
	"pawn_classic": {"jenis": "pawn", "nama": "Classic", "harga": 0, "lv": 0},
	"pawn_shadow": {"jenis": "pawn", "nama": "Shadow", "harga": 150, "lv": 0, "warna": Color("262626")},
	"pawn_ocean": {"jenis": "pawn", "nama": "Ocean", "harga": 300, "lv": 0, "warna": Color("1FB5AD")},
	"pawn_rose": {"jenis": "pawn", "nama": "Rose", "harga": 500, "lv": 0, "warna": Color("FF6FAE")},
	"pawn_violet": {"jenis": "pawn", "nama": "Violet", "harga": 800, "lv": 5, "warna": Color("7A3CFF")},
	"pawn_lava": {"jenis": "pawn", "nama": "Lava", "harga": 1200, "lv": 8, "warna": Color("FF5A00"), "emisi": 0.6},
	"pawn_gold": {"jenis": "pawn", "nama": "Gold", "harga": 2000, "lv": 12, "warna": Color("FFCC33"), "logam": 0.8, "kasar": 0.3},
	"pawn_diamond": {"jenis": "pawn", "nama": "Diamond", "harga": 3500, "lv": 15, "warna": Color("BFF4FF"), "logam": 0.6, "kasar": 0.1, "emisi": 0.4},
	"title_rookie": {"jenis": "title", "nama": "Rookie", "harga": 0, "lv": 0},
	"title_tile_hunter": {"jenis": "title", "nama": "Tile Hunter", "harga": 150, "lv": 0},
	"title_trap_setter": {"jenis": "title", "nama": "Trap Setter", "harga": 300, "lv": 0},
	"title_coin_collector": {"jenis": "title", "nama": "Coin Collector", "harga": 400, "lv": 0},
	"title_duelist": {"jenis": "title", "nama": "Duelist", "harga": 600, "lv": 0},
	"title_storm_caller": {"jenis": "title", "nama": "Storm Caller", "harga": 900, "lv": 5},
	"title_tower_builder": {"jenis": "title", "nama": "Tower Builder", "harga": 1200, "lv": 8},
	"title_grand_strategist": {"jenis": "title", "nama": "Grand Strategist", "harga": 1800, "lv": 10},
	"title_elemental_lord": {"jenis": "title", "nama": "Elemental Lord", "harga": 2600, "lv": 12},
	"title_tile_legend": {"jenis": "title", "nama": "Tile Legend", "harga": 3500, "lv": 15},
	"frame_plain": {"jenis": "frame", "nama": "Plain", "harga": 0, "lv": 0},
	"frame_bronze": {"jenis": "frame", "nama": "Bronze", "harga": 250, "lv": 0, "border": Color("CD7F32"), "lebar": 3},
	"frame_silver": {"jenis": "frame", "nama": "Silver", "harga": 700, "lv": 0, "border": Color("C9D1D9"), "lebar": 3},
	"frame_emerald": {"jenis": "frame", "nama": "Emerald", "harga": 1200, "lv": 6, "border": Color("2ECC71"), "lebar": 4},
	"frame_gold": {"jenis": "frame", "nama": "Gold", "harga": 2200, "lv": 10, "border": Color("FFCC33"), "lebar": 5, "bayangan": Color("FFCC33", 0.5), "bayangan_ukuran": 6, "radius_tambah": 0},
	"frame_royal": {"jenis": "frame", "nama": "Royal", "harga": 3500, "lv": 15, "border": Color("9B59FF"), "lebar": 5, "bayangan": Color("FFCC33", 0.6), "bayangan_ukuran": 8, "radius_tambah": 4},
	# --- Fase 8 G0: barang TOKO EVENT (dibeli dgn Event Tokens, hanya saat event-nya berjalan; kembali tiap 6 minggu).
	# "harga" Crowns 0 & "sumber" != "" -> TIDAK dijual di toko Crowns (daftar() hanya sumber ""). Harga token: RENCANA 3.1.
	"pawn_ember": {"jenis": "pawn", "nama": "Ember", "harga": 0, "lv": 0, "sumber": "event", "event": "fire", "token": 60, "warna": Color("FF3B1F"), "emisi": 0.5},
	"title_flame_heart": {"jenis": "title", "nama": "Flame Heart", "harga": 0, "lv": 0, "sumber": "event", "event": "fire", "token": 40},
	"frame_ember": {"jenis": "frame", "nama": "Ember", "harga": 0, "lv": 0, "sumber": "event", "event": "fire", "token": 80, "border": Color("FF5A1F"), "lebar": 4, "bayangan": Color("FF3B1F", 0.5), "bayangan_ukuran": 6},
	"pawn_tide": {"jenis": "pawn", "nama": "Tide", "harga": 0, "lv": 0, "sumber": "event", "event": "water", "token": 60, "warna": Color("2E7DFF")},
	"title_wave_rider": {"jenis": "title", "nama": "Wave Rider", "harga": 0, "lv": 0, "sumber": "event", "event": "water", "token": 40},
	"frame_tide": {"jenis": "frame", "nama": "Tide", "harga": 0, "lv": 0, "sumber": "event", "event": "water", "token": 80, "border": Color("2E9BFF"), "lebar": 4, "bayangan": Color("2E7DFF", 0.5), "bayangan_ukuran": 6},
	"pawn_breeze": {"jenis": "pawn", "nama": "Breeze", "harga": 0, "lv": 0, "sumber": "event", "event": "wind", "token": 60, "warna": Color("A8F0C8")},
	"title_sky_dancer": {"jenis": "title", "nama": "Sky Dancer", "harga": 0, "lv": 0, "sumber": "event", "event": "wind", "token": 40},
	"frame_gale": {"jenis": "frame", "nama": "Gale", "harga": 0, "lv": 0, "sumber": "event", "event": "wind", "token": 80, "border": Color("8FE3BE"), "lebar": 4, "radius_tambah": 6},
	"pawn_spark": {"jenis": "pawn", "nama": "Spark", "harga": 0, "lv": 0, "sumber": "event", "event": "lightning", "token": 60, "warna": Color("FFE14D"), "emisi": 0.6},
	"title_thunder_born": {"jenis": "title", "nama": "Thunder Born", "harga": 0, "lv": 0, "sumber": "event", "event": "lightning", "token": 40},
	"frame_volt": {"jenis": "frame", "nama": "Volt", "harga": 0, "lv": 0, "sumber": "event", "event": "lightning", "token": 80, "border": Color("FFE14D"), "lebar": 4, "bayangan": Color("FFE14D", 0.6), "bayangan_ukuran": 8},
	"pawn_stone": {"jenis": "pawn", "nama": "Stone", "harga": 0, "lv": 0, "sumber": "event", "event": "earth", "token": 60, "warna": Color("8B6B4A"), "kasar": 0.9},
	"title_rock_solid": {"jenis": "title", "nama": "Rock Solid", "harga": 0, "lv": 0, "sumber": "event", "event": "earth", "token": 40},
	"frame_granite": {"jenis": "frame", "nama": "Granite", "harga": 0, "lv": 0, "sumber": "event", "event": "earth", "token": 80, "border": Color("8B6B4A"), "lebar": 6},
	"pawn_champion": {"jenis": "pawn", "nama": "Champion", "harga": 0, "lv": 0, "sumber": "event", "event": "duel", "token": 60, "warna": Color("E8E8E8"), "logam": 0.9, "kasar": 0.2},
	"title_duel_champion": {"jenis": "title", "nama": "Duel Champion", "harga": 0, "lv": 0, "sumber": "event", "event": "duel", "token": 40},
	"frame_arena": {"jenis": "frame", "nama": "Arena", "harga": 0, "lv": 0, "sumber": "event", "event": "duel", "token": 80, "border": Color("E03C3C"), "lebar": 5, "bayangan": Color("E03C3C", 0.5), "bayangan_ukuran": 6},
	# --- Fase 8 G0: gelar MASTERY (tidak dijual; diberikan saat mastery elemen mencapai Lv 10, DataEvent.GELAR_MASTERY).
	"title_fire_master": {"jenis": "title", "nama": "Fire Master", "harga": 0, "lv": 0, "sumber": "mastery", "elemen": "api"},
	"title_water_master": {"jenis": "title", "nama": "Water Master", "harga": 0, "lv": 0, "sumber": "mastery", "elemen": "air"},
	"title_earth_master": {"jenis": "title", "nama": "Earth Master", "harga": 0, "lv": 0, "sumber": "mastery", "elemen": "tanah"},
	"title_lightning_master": {"jenis": "title", "nama": "Lightning Master", "harga": 0, "lv": 0, "sumber": "mastery", "elemen": "petir"},
	"title_wind_master": {"jenis": "title", "nama": "Wind Master", "harga": 0, "lv": 0, "sumber": "mastery", "elemen": "angin"},
}

static func ada(id_barang: String) -> bool:
	return KATALOG.has(id_barang)

static func jenis_dari(id_barang: String) -> String:
	return str(KATALOG[id_barang]["jenis"]) if KATALOG.has(id_barang) else ""

static func daftar(jenis: String, sumber: String = "") -> Array:
	# id barang satu jenis, urutan katalog. Fase 8: sumber "" = toko Crowns, "event", "mastery".
	var hasil: Array = []
	for k in KATALOG:
		if str(KATALOG[k]["jenis"]) == jenis and str(KATALOG[k].get("sumber", "")) == sumber:
			hasil.append(k)
	return hasil

static func sumber_dari(id_barang: String) -> String:
	# Fase 8: "" = toko Crowns, "event" = toko event (token), "mastery" = hadiah mastery Lv 10.
	return str(KATALOG[id_barang].get("sumber", "")) if KATALOG.has(id_barang) else ""

static func daftar_event(id_event: String) -> Array:
	# Fase 8: 3 barang toko event untuk satu event (urutan pawn, title, frame).
	var hasil: Array = []
	for k in KATALOG:
		if str(KATALOG[k].get("event", "")) == id_event:
			hasil.append(k)
	return hasil

static func sah_untuk_jenis(id_barang: String, jenis: String) -> String:
	# Dipakai host (F7.4): id tak dikenal / jenis tidak cocok -> barang AWAL jenis itu.
	if KATALOG.has(id_barang) and str(KATALOG[id_barang]["jenis"]) == jenis:
		return id_barang
	return str(AWAL.get(jenis, ""))

static func sah_semua(v) -> Dictionary:
	# Fase 7 G3: {pawn, title, frame} sah dari data apa pun (client bisa mengirim apa saja) -- tiap jenis lewat
	# sah_untuk_jenis, jadi id tak dikenal / jenis salah / bukan dictionary = barang AWAL.
	var hasil := {}
	for j in JENIS:
		var id_barang := ""
		if v is Dictionary and typeof((v as Dictionary).get(j, "")) == TYPE_STRING:
			id_barang = (v as Dictionary).get(j, "")
		hasil[j] = sah_untuk_jenis(id_barang, j)
	return hasil

static func nama_barang(id_barang: String) -> String:
	return str(KATALOG[id_barang]["nama"]) if KATALOG.has(id_barang) else ""
