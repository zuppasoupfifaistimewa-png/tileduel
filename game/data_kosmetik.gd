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
}

static func ada(id_barang: String) -> bool:
	return KATALOG.has(id_barang)

static func jenis_dari(id_barang: String) -> String:
	return str(KATALOG[id_barang]["jenis"]) if KATALOG.has(id_barang) else ""

static func daftar(jenis: String) -> Array:
	# id barang satu jenis, urutan katalog.
	var hasil: Array = []
	for k in KATALOG:
		if str(KATALOG[k]["jenis"]) == jenis:
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
