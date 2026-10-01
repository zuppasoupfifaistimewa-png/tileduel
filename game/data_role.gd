class_name DataRole
## Fase 4: Role elemen & skill tree -- SATU-SATUNYA tempat menyetel angka
## role/jebakan/ketahanan. Hanya konstanta & fungsi STATIC MURNI (tidak
## menyimpan state pertandingan apa pun) -- aman dipanggil dari file mana pun
## di rantai pemain_*.gd, termasuk yang paling bawah (pemain_dasar.gd).
##
## Langkah A (aktif dipakai kode sekarang): ROLE, NAMA, WARNA, NODE_JEBAKAN,
## TAHAN, NODE_TAHAN, TAHAN_ROLE, DASAR, potongan ketahanan Lv1, rumus Rock
## Breaker, slot jebakan, jebakan_bawaan_ai.
## Langkah B (dipakai host sejak B-b/B-c/B-d/B-e): tabel NODE per level, XP
## Role, biaya/pembukaan node, build_sah, PRESET (14.4) + build_dari_preset,
## tabel GROUNDED_LV/ROCK_BREAKER_LV (K13/K14, dibaca pemain_role.gd/
## pemain_duel.gd/ai_musuh.gd), build_arena (B-c), build_solo + teks_node (B-e).

# ============================================================
# ROLE DASAR
# ============================================================

const ROLE := ["api", "air", "tanah", "petir", "angin"]

const NAMA := {
	"api": "FIRE",
	"air": "WATER",
	"tanah": "EARTH",
	"petir": "LIGHTNING",
	"angin": "WIND",
}

# HARUS sama persis dengan warna elemen di ui_elemen.gd (DATA_ELEMEN) --
# disalin di sini karena ui_elemen.gd bukan class_name statis (scene node),
# jadi tidak bisa dipanggil dari file rantai pemain_*.gd.
const WARNA := {
	"api": Color(0.9, 0.2, 0.2),
	"air": Color(0.2, 0.5, 0.9),
	"tanah": Color(0.6, 0.4, 0.2),
	"petir": Color(0.9, 0.8, 0.1),
	"angin": Color(0.5, 0.9, 0.7),
}

# Nama node jebakan (dipakai dengan NODE_JEBAKAN[elemen] + ".tscn" oleh kode
# yang sudah ada) -- SAMA dengan nama class jebakan yang sudah ada di proyek.
const NODE_JEBAKAN := {
	"api": "JebakanApi",
	"air": "JebakanAir",
	"tanah": "JebakanTanah",
	"petir": "JebakanPetir",
	"angin": "JebakanAngin",
}

# Elemen jebakan yang DITAHAN (dimenangkan dalam duel) oleh tiap role.
# Rig U1 memeriksa ini SAMA (sebagai himpunan) dengan DATA_ELEMEN["menang_lawan"]
# di ui_elemen.gd -- satu-satunya sumber lain untuk hubungan menang-kalah.
const TAHAN := {
	"tanah": ["petir", "angin"],
	"petir": ["api", "air"],
	"angin": ["petir", "air"],
	"api": ["tanah", "angin"],
	"air": ["api", "tanah"],
}

# Node ketahanan yang menahan tiap ELEMEN JEBAKAN (kunci = elemen jebakannya,
# bukan role). Contoh: jebakan "api" ditahan oleh siapa pun yang punya node
# "heat_skin".
const NODE_TAHAN := {
	"api": "heat_skin",
	"air": "steady_feet",
	"angin": "heavy_pockets",
	"petir": "grounded",
	"tanah": "rock_breaker",
}

# 2 node ketahanan yang DIMILIKI tiap role -- diturunkan langsung dari TAHAN:
# role X tahan jebakan elemen Y kalau X mengalahkan Y dalam duel elemen.
const TAHAN_ROLE := {
	"tanah": ["grounded", "heavy_pockets"],
	"petir": ["heat_skin", "steady_feet"],
	"angin": ["grounded", "steady_feet"],
	"api": ["rock_breaker", "heavy_pockets"],
	"air": ["heat_skin", "rock_breaker"],
}

# Teks singkat "Tough against: X and Y traps" untuk layar pilih role (A6).
const TEKS_TAHAN := {
	"heat_skin": "Fire",
	"steady_feet": "Water",
	"heavy_pockets": "Wind",
	"grounded": "Lightning",
	"rock_breaker": "Earth",
}

# ============================================================
# ANGKA DASAR (tanpa node Langkah B -- perilaku jebakan sekarang)
# ============================================================

const DASAR := {
	"bakar_per_giliran": 60, # U3: 50 -> 60
	"bakar_giliran": 3,
	"rampas_angin": 0.10, # U3: 0,15 -> 0,10
	"gelembung": 2,
	"paralisis": 2,
	"pengali_kalah_duel": 1.2,
	"tanah_hp_tambahan": 1,
	"tanah_hp_duel": 1,
	"biaya_jebakan": 1,
}

# Pengurangan ketahanan Langkah A (setiap role selalu Lv1 di kedua node-nya,
# gratis). Langkah B menambah Lv2/Lv3 lewat SP -- potongannya tetap sama
# besarnya (lihat potongan_tahan di bawah), Lv3 menambah Guard (belum ada).
const TAHAN_LV1_POTONGAN := 0.25 # -25%
const TAHAN_LV_MAKS_POTONGAN := 0.50 # -50% (Lv2 & Lv3, Langkah B)

# Rock Breaker: memotong TAMBAHAN denda kalah duel di atas x1,0, bukan denda
# itu sendiri -- supaya Fight tidak pernah lebih murah daripada Give Up.
# pengali = 1 + (p - 1) x (1 - r). K14 (B-b): r per level ada di ROCK_BREAKER_LV
# (Lv1 = 0, TIDAK memotong lagi -- efek Lv1 sekarang "bonus tanah gagal" 50%,
# dipakai pemain_duel.gd; Lv2/3 = TAHAN_LV_MAKS_POTONGAN).

# ============================================================
# SLOT JEBAKAN (jumlah JENIS jebakan yang dibawa satu pemain)
# ============================================================

# [level_pemain_minimal, jumlah_jenis] -- urut dari syarat tertinggi (dicek
# dari atas ke bawah, ambil yang pertama terpenuhi).
const SLOT_JEBAKAN_SOLO := [[10, 5], [6, 4], [3, 3], [1, 2]]
const SLOT_JEBAKAN_MP := 3

static func slot_jebakan_solo(level_pemain: int) -> int:
	for pasangan in SLOT_JEBAKAN_SOLO:
		if level_pemain >= pasangan[0]:
			return pasangan[1]
	return 2

# ============================================================
# FUNGSI STATIC -- LANGKAH A
# ============================================================

static func nama_role(role: String) -> String:
	return NAMA.get(role, role.to_upper())

static func warna_role(role: String) -> Color:
	return WARNA.get(role, Color.WHITE)

static func node_tahan_untuk_elemen(elemen: String) -> String:
	# Node ketahanan (id) yang menahan JEBAKAN elemen ini. "" kalau elemen
	# tidak dikenal.
	return NODE_TAHAN.get(elemen, "")

static func role_tahan_elemen(role: String, elemen: String) -> bool:
	# True kalau role ini (lewat 2 node ketahanan Lv1 gratisnya) menahan
	# jebakan elemen tsb.
	if not TAHAN_ROLE.has(role):
		return false
	var id_node = NODE_TAHAN.get(elemen, "")
	return id_node != "" and TAHAN_ROLE[role].has(id_node)

static func teks_tahan_role(role: String) -> String:
	# "Earth and Wind traps" -- dipakai keterangan layar pilih role (A6).
	if not TAHAN_ROLE.has(role):
		return ""
	var nama_elemen: Array = []
	for id_node in TAHAN_ROLE[role]:
		for elemen in NODE_TAHAN:
			if NODE_TAHAN[elemen] == id_node:
				nama_elemen.append(TEKS_TAHAN.get(id_node, elemen.capitalize()))
	if nama_elemen.size() >= 2:
		return "%s and %s traps" % [nama_elemen[0], nama_elemen[1]]
	elif nama_elemen.size() == 1:
		return nama_elemen[0] + " traps"
	return ""

static func potongan_tahan(level_node: int) -> float:
	# level_node: 0 = tidak punya node, 1 = Lv1 (Langkah A, selalu ini untuk
	# sekarang), 2/3 = Langkah B.
	if level_node <= 0:
		return 0.0
	elif level_node == 1:
		return TAHAN_LV1_POTONGAN
	return TAHAN_LV_MAKS_POTONGAN

static func pengali_kalah_duel(level_rock_breaker: int, ada_jebakan_tanah_musuh: bool, stone_thorns_p: float = DASAR["pengali_kalah_duel"]) -> float:
	# p = pengali dasar (1,2 di Langkah A; Stone Thorns B4 menaikkannya jadi
	# 1,3/1,4/1,5 kalau jebakan tanah itu milik pemain role Tanah dengan node
	# itu -- ada di NODE_LV["stone_thorns"], dibaca pemain_role.gd B4).
	# K14 (B-b): potongan TAMBAHAN dari ROCK_BREAKER_LV[level] -- Lv1 = 0,0
	# (efeknya sekarang "bonus tanah gagal" 50%, diundi pemain_duel.gd, BUKAN
	# di sini); Lv2/3 = TAHAN_LV_MAKS_POTONGAN. HANYA berlaku kalau petak yang
	# diperebutkan memang punya jebakan tanah saat duel dimulai.
	if level_rock_breaker >= 1 and ada_jebakan_tanah_musuh:
		var r = float(ROCK_BREAKER_LV[clampi(level_rock_breaker, 1, 3)]["potongan_kalah_duel"])
		if r > 0.0:
			return 1.0 + (stone_thorns_p - 1.0) * (1.0 - r)
	return stone_thorns_p

# U3: pemecah seri jenis tambahan AI = urutan kekuatan jebakan hasil uji
# keseimbangan (dulu urutan ROLE -> AI selalu membawa api/tanah yang lemah dan
# angin paling akhir; role Air kalah ~70% melawan Angin karenanya).
const URUTAN_BAWAAN_AI := ["angin", "petir", "air", "api", "tanah"]
# U3: seberapa besar node ketahanan Lv1 benar-benar mengurangi jebakan itu (0-1),
# dipakai AI (jenis bawaan & nilai pasang). Grounded hanya membuka Fight saat
# lumpuh (berhenti + lewat giliran tetap penuh), Rock Breaker hanya memotong
# tambahan x1,2 -- dulu keduanya dianggap ketahanan penuh, jadi AI tidak pernah
# membawa petir/tanah melawan pemiliknya (Tanah & Angin menang ~57%).
# D1 (B-c/K17, 26-09): petir 0,1->0,5 dan tanah 0,05->0,5 -- angka lama disetel
# SEBELUM K13/K14 (14.1/14.3): Grounded Lv1 sekarang = giliran lumpuh 2->1 (bukan
# cuma buka Fight saat lumpuh), Rock Breaker Lv1 sekarang = 50% bonus HP tanah
# gagal (bukan cuma potongan x1,2->x1,15). Api/angin/air TIDAK diubah.
const BOBOT_TAHAN_AI := {"api": 0.25, "angin": 0.25, "air": 0.5, "petir": 0.5, "tanah": 0.5}

static func bobot_tahan_ai(elemen: String, level: int) -> float:
	# D1 (K17): bobot KASAR per level, dipakai HANYA di jenis bawaan (jebakan_bawaan_ai/
	# _jumlah_menahan) -- bukan keputusan pasang (itu pakai mekanik asli, ai_jebakan.gd).
	# Guard DIABAIKAN di sini (cuma menahan 1 jebakan sepanjang pertandingan).
	if level <= 0:
		return 0.0
	var b1 := float(BOBOT_TAHAN_AI.get(elemen, 0.4))
	if level == 1:
		return b1
	return minf(b1 * 2.0, TAHAN_LV_MAKS_POTONGAN)

static func jebakan_bawaan_ai(role: String, role_lawan: Array, jumlah: int = SLOT_JEBAKAN_MP, build_lawan: Array = []) -> Array:
	# Jebakan yang dibawa AI: role-nya sendiri (wajib) + (jumlah-1) jenis
	# tambahan yang PALING SEDIKIT ditahan oleh role_lawan (array String role
	# lawan, boleh berisi "" untuk slot yang belum tahu). TANPA acak -- hasil
	# sama persis kalau susunan lawan sama, dipakai solo maupun lobby.
	# D1 (T9/P5, 26-09): build_lawan opsional (bawaan [] -- 3 pemanggil lama tetap
	# sah) -- kalau ada, level node ketahanan lawan yang SUNGGUHAN dibaca (bukan
	# cuma tebakan Lv1 dari role_tahan_elemen).
	var dibawa: Array = [role]
	var kandidat: Array = []
	for e in ROLE:
		if e != role:
			kandidat.append(e)
	kandidat.sort_custom(func(a, b):
		var na = _jumlah_menahan(a, role_lawan, build_lawan)
		var nb = _jumlah_menahan(b, role_lawan, build_lawan)
		if na != nb:
			return na < nb
		return URUTAN_BAWAAN_AI.find(a) < URUTAN_BAWAAN_AI.find(b)
	)
	var sisa = maxi(0, jumlah - 1)
	for i in range(mini(sisa, kandidat.size())):
		dibawa.append(kandidat[i])
	return dibawa

static func _jumlah_menahan(elemen: String, role_lawan: Array, build_lawan: Array = []) -> float:
	# U3: jumlah lawan yang menahan, DIBOBOT kekuatan ketahanannya (bobot_tahan_ai).
	# D1 (T9/P5): kalau build_lawan[i] tersedia (Dictionary) -> baca level node
	# ketahanan SUNGGUHAN lawan ke-i; kalau tidak -> fallback tebakan Lv1 lama
	# (role_tahan_elemen), supaya pemanggil tanpa build_lawan tidak berubah.
	var n := 0.0
	var id_node: String = NODE_TAHAN.get(elemen, "") # D1: tipe eksplisit -- .get() Dictionary = Variant, ":=" polos kena warning-as-error
	for i in range(role_lawan.size()):
		var rl = role_lawan[i]
		if typeof(rl) != TYPE_STRING or rl == "":
			continue
		var lv := 0
		if i < build_lawan.size() and build_lawan[i] is Dictionary:
			lv = int(build_lawan[i].get(id_node, 0))
		elif role_tahan_elemen(rl, elemen):
			lv = 1
		n += bobot_tahan_ai(elemen, lv)
	return n

# ============================================================
# TABEL NODE (Langkah B -- dibaca ai_jebakan.gd/ai_musuh.gd/pemain_role.gd
# untuk nilai efek, dan teks_node di bawah untuk teks layar pohon B-e).
# Kunci = id node; nilai = {1: <Lv1>, 2: <Lv2>, 3: <Lv3>}. Node persen disimpan
# sebagai pecahan (0,25 = 25%). Node yang bukan angka murni (mis. long_burn
# menambah larangan pasang jebakan di Lv2/Lv3) dicatat sebagai catatan di
# komentar -- efeknya ditentukan lagi saat kode langkah B ditulis.
# ============================================================

const NODE_JEBAKAN_ID := {
	"api": ["hot_flames", "fire_tax", "long_burn"],
	"air": ["rapid_current", "high_tide", "frozen_bubble"],
	"tanah": ["hard_rock", "stone_thorns", "fortress"],
	"petir": ["shock", "chain_lightning", "card_magnet"],
	"angin": ["strong_wind", "homing_wind", "whirlwind"],
}

const NODE_ULTIMATE_ID := {
	"api": "phoenix",
	"air": "tsunami",
	"tanah": "sacred_ground",
	"petir": "stealth_charge",
	"angin": "tornado",
}

const NODE_LV := {
	# api
	"hot_flames": {1: 70, 2: 80, 3: 90}, # bakar koin/giliran (14.1: dasar api 60 -> Lv1 60 tidak berpengaruh)
	"fire_tax": {1: 0.25, 2: 0.5, 3: 0.75}, # bagian bakaran -> pemasang
	"long_burn": {1: 4, 2: 4, 3: 5}, # giliran bakar (Lv2/3 juga larang korban pasang jebakan)
	# air
	"rapid_current": {1: 3, 2: 6, 3: 9}, # petak mundur MINIMAL dari START berikut
	"high_tide": {1: 0.5, 2: 1.0, 3: 1.0}, # peluang +1 bintang (Lv3 juga +100 koin)
	"frozen_bubble": {1: 1, 2: 2, 3: 2}, # giliran kartu terkunci sesudah gelembung pecah (Lv3 + LOW ROLL sekali)
	# tanah
	"hard_rock": {1: 2, 2: 3, 3: 3}, # jumlah duel jebakan bertahan (Lv3 duel pertama +2 HP)
	"stone_thorns": {1: 1.3, 2: 1.4, 3: 1.5}, # pengali kalah duel penyerang di petak ini
	"fortress": {1: 1, 2: 2, 3: 999}, # jumlah serangan jarak jauh ditahan (999 = selama jebakan ada)
	# petir
	"shock": {1: 50, 2: 100, 3: 150}, # koin hilang korban
	"chain_lightning": {1: 0, 2: 1, 3: 2}, # jarak petak lawan lain kena LOW ROLL
	"card_magnet": {1: 0.25, 2: 0.5, 3: 0.75}, # peluang curi 1 kartu korban
	# angin
	"strong_wind": {1: 0.12, 2: 0.14, 3: 0.16}, # persen rampas (14.1: dasar angin 10% -> 18% Lv1 terlalu melompat)
	"homing_wind": {1: 0.25, 2: 0.5, 3: 0.75}, # bagian rampasan -> pemasang langsung
	"whirlwind": {1: 1, 2: 2, 3: 3}, # langkah dadu hilang
}

# K13/K14 (26-09, DISETUJUI user): grounded & rock_breaker TIDAK mengikuti pola
# potongan_tahan() generik (heat_skin/steady_feet/heavy_pockets) karena efeknya
# beda JENIS per tingkat, bukan cuma beda BESAR. BELUM dipanggil kode host
# mana pun (B4/B-b menyambungkannya) -- Langkah A tetap pakai perilaku lama
# (ROCK_BREAKER_R_LV1 & sisa_paralisis DASAR["paralisis"]) sampai saat itu.
#
# Grounded (tahan petir): Lv1 Langkah A lama ("boleh Fight saat lumpuh") nyaris
# tidak berefek karena efek petir = berhenti + LEWAT giliran, bukan soal Fight.
# Baru: Lv1 = giliran berikut TIDAK terlewat (tetap berhenti giliran ini,
# tetap tidak boleh Fight saat mendarat); Lv2 = + boleh Fight saat lumpuh
# (perilaku Lv1 lama, pindah ke sini); Lv3 = + Guard.
const GROUNDED_LV := {
	1: {"sisa_paralisis": 1, "boleh_fight_lumpuh": false},
	2: {"sisa_paralisis": 1, "boleh_fight_lumpuh": true},
	3: {"sisa_paralisis": 1, "boleh_fight_lumpuh": true, "guard": true},
}

# Rock Breaker (tahan tanah): Lv1 Langkah A lama (potong tambahan denda kalah
# duel x1,2 -> x1,15) nyaris nol, sementara efek utama jebakan tanah (+1 HP
# petak di duel) tidak disentuh sama sekali. Baru: Lv1 = 50% peluang (diundi
# host) meniadakan bonus +1 HP tanah itu; Lv2 = + potongan tambahan denda
# kalah duel -50% (x1,2 -> x1,1; Stone Thorns x1,5 -> x1,25 -- pakai
# TAHAN_LV_MAKS_POTONGAN, sama besar dengan node tahan lain di Lv2/3, GANTI
# ROCK_BREAKER_R_LV1 yang lama); Lv3 = + Guard.
const ROCK_BREAKER_LV := {
	1: {"peluang_gagal_hp": 0.5, "potongan_kalah_duel": 0.0},
	2: {"peluang_gagal_hp": 0.5, "potongan_kalah_duel": TAHAN_LV_MAKS_POTONGAN},
	3: {"peluang_gagal_hp": 0.5, "potongan_kalah_duel": TAHAN_LV_MAKS_POTONGAN, "guard": true},
}

# Biaya SP untuk MEMBELI tingkat itu (bukan kumulatif): Lv1=1, Lv2=2, Lv3=3
# (total memaksimalkan satu node = 6 SP). Ultimate = biaya tetap terpisah.
const BIAYA_NODE := [1, 2, 3]
const BIAYA_ULTIMATE := 4
# Level Role minimal supaya TINGKAT itu (Lv1/Lv2/Lv3) boleh dibeli di node
# MANA PUN; Ultimate baru terbuka di BUKA_ULTIMATE. Di Arena semua tingkat
# terbuka tanpa syarat Level Role (lihat bagian 8 rencana).
const BUKA_TINGKAT := [1, 5, 10]
const BUKA_ULTIMATE := 15
const LEVEL_ROLE_MAKS := 20
const SP_ARENA := 12
# K20 (a, DISETUJUI user 26-09, saran Opus): SP = Level Role + SP_AWAL --
# Lv1 = 3 SP, Lv20 = 22 SP. Build Balanced Lv1 = J1 Lv1 + kedua ketahanan Lv1
# (setara Langkah A + 1 node jebakan), jadi teks "Tough against: X and Y"
# di layar pilih role sudah benar sejak Level Role 1.
const SP_AWAL := 2

static func sp_dari_level(level_role: int) -> int:
	# K20(a): Level Role L memberi L + SP_AWAL SP (Lv1 = 3 SP ... Lv20 = 22 SP
	# maksimal). Arena TIDAK memakai fungsi ini (SP_ARENA tetap 12 tetap).
	return clampi(level_role, 0, LEVEL_ROLE_MAKS) + SP_AWAL

static func biaya_node_ke_level(level_node: int) -> int:
	# Biaya KUMULATIF untuk mencapai level_node (1-3) dari 0.
	var total := 0
	for i in range(1, clampi(level_node, 0, 3) + 1):
		total += BIAYA_NODE[i - 1]
	return total

static func biaya_build(build: Dictionary) -> int:
	# build: {id_node: level (1-3)} atau {"ULT_<role>": true/false}.
	var total := 0
	for id_node in build:
		var nilai = build[id_node]
		if typeof(id_node) == TYPE_STRING and id_node.begins_with("ULT_"):
			if nilai:
				total += BIAYA_ULTIMATE
		else:
			total += biaya_node_ke_level(int(nilai))
	return total

static func _daftar_node_id(role: String) -> Array:
	var hasil: Array = []
	hasil.append_array(NODE_JEBAKAN_ID.get(role, []))
	hasil.append_array(TAHAN_ROLE.get(role, []))
	if NODE_ULTIMATE_ID.has(role):
		hasil.append("ULT_" + role)
	return hasil

static func build_sah(build: Dictionary, role: String, sp: int, level_role: int) -> bool:
	# Dipakai host untuk memvalidasi build Arena kiriman client (Langkah B).
	if biaya_build(build) > sp:
		return false
	var id_sah = _daftar_node_id(role)
	for id_node in build:
		if not id_sah.has(id_node):
			return false
		var nilai = build[id_node]
		if typeof(id_node) == TYPE_STRING and id_node.begins_with("ULT_"):
			if nilai and level_role < BUKA_ULTIMATE:
				return false
		else:
			var lv = int(nilai)
			if lv < 0 or lv > 3:
				return false
			if lv >= 1 and level_role < BUKA_TINGKAT[0]:
				return false
			if lv >= 2 and level_role < BUKA_TINGKAT[1]:
				return false
			if lv >= 3 and level_role < BUKA_TINGKAT[2]:
				return false
	return true

# ============================================================
# TEKS NODE (P10/E1, B-e) -- nama & penjelasan tiap node untuk layar pohon
# (B2). Angka DIAMBIL dari NODE_LV/GROUNDED_LV/ROCK_BREAKER_LV lewat teks_node
# (bukan dikarang ulang) supaya penyetelan keseimbangan B-f otomatis ikut
# benar. Ultimate (lv selalu 1) & Lv3 ketahanan (selalu + Guard) ditulis
# apa adanya sesuai rencana 14.18 (P10) -- JANGAN diubah tanpa Opus.
# ============================================================

const NAMA_NODE := {
	"hot_flames": "Hot Flames", "fire_tax": "Fire Tax", "long_burn": "Long Burn", "phoenix": "Phoenix",
	"rapid_current": "Rapid Current", "high_tide": "High Tide", "frozen_bubble": "Frozen Bubble", "tsunami": "Tsunami",
	"hard_rock": "Hard Rock", "stone_thorns": "Stone Thorns", "fortress": "Fortress", "sacred_ground": "Sacred Ground",
	"shock": "Shock", "chain_lightning": "Chain Lightning", "card_magnet": "Card Magnet", "stealth_charge": "Stealth Charge",
	"strong_wind": "Strong Wind", "homing_wind": "Homing Wind", "whirlwind": "Whirlwind", "tornado": "Tornado",
	"heat_skin": "Heat Skin", "heavy_pockets": "Heavy Pockets", "steady_feet": "Steady Feet",
	"grounded": "Grounded", "rock_breaker": "Rock Breaker",
}

static func nama_node(id_node: String) -> String:
	return NAMA_NODE.get(id_node, id_node.capitalize())

static func _teks_guard(id_node: String) -> String:
	# Lv3 semua node ketahanan (K13/K14): + Guard, menahan jebakan elemen yang
	# ditahan node ini (TEKS_TAHAN, sudah ada -- "Fire"/"Water"/"Wind"/
	# "Lightning"/"Earth").
	return "GUARD: blocks the first %s Trap." % TEKS_TAHAN.get(id_node, id_node.capitalize())

static func teks_node(id_node: String, lv: int) -> String:
	# lv 1-3 untuk node biasa; Ultimate selalu lv 1 (teks tetap, tanpa angka).
	match id_node:
		"hot_flames":
			return "Burns %d coins per turn." % int(NODE_LV["hot_flames"][lv])
		"fire_tax":
			return "You get %d%% of the burned coins." % roundi(float(NODE_LV["fire_tax"][lv]) * 100.0)
		"long_burn":
			var giliran_bakar = int(NODE_LV["long_burn"][lv])
			if lv == 1:
				return "Burn lasts %d turns." % giliran_bakar
			return "Burn lasts %d turns. Burned players can't set traps." % giliran_bakar
		"phoenix":
			return "Your Fire Trap comes back once after it burns someone."
		"rapid_current":
			return "Victim is thrown back at least %d tiles." % int(NODE_LV["rapid_current"][lv])
		"high_tide":
			if lv == 1:
				return "%d%% chance: you get +1 star." % roundi(float(NODE_LV["high_tide"][1]) * 100.0)
			elif lv == 2:
				return "You get +1 star."
			return "You get +1 star and +100 coins."
		"frozen_bubble":
			var giliran_kunci = int(NODE_LV["frozen_bubble"][lv])
			if lv <= 2:
				return "Victim can't use cards for %d turn(s) after the bubble." % giliran_kunci
			return "Victim can't use cards for %d turns after the bubble, and their next roll is LOW." % giliran_kunci
		"tsunami":
			return "Other players within 2 tiles are pushed back 2 tiles."
		"hard_rock":
			var duel_tahan = int(NODE_LV["hard_rock"][lv])
			if lv <= 2:
				return "Earth Trap lasts %d duels." % duel_tahan
			return "Earth Trap lasts %d duels. +2 HP in the first duel." % duel_tahan
		"stone_thorns":
			return "Attackers who lose here pay x%.1f." % float(NODE_LV["stone_thorns"][lv])
		"fortress":
			if lv <= 2:
				return "Blocks %d long-range attack(s)." % int(NODE_LV["fortress"][lv])
			return "Blocks all long-range attacks."
		"sacred_ground":
			return "Your first Earth Trap is free and stays until the tile changes owner."
		"shock":
			return "Victim loses %d coins." % int(NODE_LV["shock"][lv])
		"chain_lightning":
			if lv == 1:
				return "Other players on the same tile get a LOW roll."
			return "Other players within %d tile(s) get a LOW roll." % int(NODE_LV["chain_lightning"][lv])
		"card_magnet":
			return "%d%% chance to steal 1 card." % roundi(float(NODE_LV["card_magnet"][lv]) * 100.0)
		"stealth_charge":
			return "Your Lightning Traps are invisible to others."
		"strong_wind":
			return "Steals %d%% of the victim's coins." % roundi(float(NODE_LV["strong_wind"][lv]) * 100.0)
		"homing_wind":
			return "%d%% of the stolen coins go straight to you." % roundi(float(NODE_LV["homing_wind"][lv]) * 100.0)
		"whirlwind":
			return "Victim loses %d step(s)." % int(NODE_LV["whirlwind"][lv])
		"tornado":
			return "After hitting, your Wind Trap moves and works once more."
		"heat_skin":
			var teks_hs = "Fire burns you %d%% less." % roundi(potongan_tahan(lv) * 100.0)
			if lv >= 3:
				teks_hs += " " + _teks_guard(id_node)
			return teks_hs
		"heavy_pockets":
			var teks_hp = "Wind steals %d%% less." % roundi(potongan_tahan(lv) * 100.0)
			if lv >= 3:
				teks_hp += " " + _teks_guard(id_node)
			return teks_hp
		"steady_feet":
			var teks_sf = "Water bubble lasts 1 turn." if lv == 1 else "Bubble lasts 1 turn. You land within 6 tiles."
			if lv >= 3:
				teks_sf += " " + _teks_guard(id_node)
			return teks_sf
		"grounded":
			var teks_gr = "Lightning doesn't make you skip a turn."
			if lv >= 2:
				teks_gr += " + you can Fight while paralyzed."
			if lv >= 3:
				teks_gr += " " + _teks_guard(id_node)
			return teks_gr
		"rock_breaker":
			var teks_rb = "%d%% chance to cancel the Earth Trap's extra HP." % roundi(float(ROCK_BREAKER_LV[1]["peluang_gagal_hp"]) * 100.0)
			if lv >= 2:
				teks_rb += " + losing a duel costs %d%% less extra." % roundi(float(ROCK_BREAKER_LV[2]["potongan_kalah_duel"]) * 100.0)
			if lv >= 3:
				teks_rb += " " + _teks_guard(id_node)
			return teks_rb
		_:
			return ""

# ============================================================
# XP ROLE (Langkah B -- dipakai profil_pemain.gd::catat_akhir_match lewat
# info_level_role, dan _siapkan_role_solo (B-e) lewat sp_dari_level)
# ============================================================

const XP_ROLE := {"pasang": 10, "kena": 30, "tahan": 15, "duel_elemen": 20, "selesai": 50, "menang": 100}
const XP_ROLE_LV2 := 100
const XP_ROLE_TAMBAH := 50

static func xp_untuk_naik_role(level_role: int) -> int:
	# XP yang dibutuhkan untuk naik dari level_role ke level_role+1.
	if level_role < 1 or level_role >= LEVEL_ROLE_MAKS:
		return -1
	return XP_ROLE_LV2 + (level_role - 1) * XP_ROLE_TAMBAH

static func info_level_role(xp_total: int) -> Dictionary:
	# {"level": int, "xp_di_level": int, "xp_perlu": int (-1 kalau maks), "sp": int}
	var level = 1
	var sisa = maxi(0, xp_total)
	while level < LEVEL_ROLE_MAKS:
		var perlu = xp_untuk_naik_role(level)
		if perlu <= 0 or sisa < perlu:
			break
		sisa -= perlu
		level += 1
	var perlu_sekarang = xp_untuk_naik_role(level)
	return {
		"level": level,
		"xp_di_level": sisa,
		"xp_perlu": perlu_sekarang,
		"sp": sp_dari_level(level),
	}

# ============================================================
# PRESET (14.4, diisi Opus 26-09) -- urutan "beli 1 tingkat berikutnya" untuk
# AI Balanced (B-d, ai_jebakan.gd/ai_musuh.gd), tombol preset layar pohon &
# build solo pemain (B-e, build_solo di bawah), & Arena (B-c, build_arena).
# ============================================================

# Urutan J1/J2/J3 dipakai PRESET (terkuat dulu, hasil tinjauan Opus) --
# BERBEDA dari urutan tampilan/simpanan NODE_JEBAKAN_ID untuk air/tanah/petir
# (NODE_JEBAKAN_ID tidak diubah supaya build tersimpan lama tetap valid).
const PRESET_URUTAN_JEBAKAN := {
	"api": ["hot_flames", "fire_tax", "long_burn"],
	"air": ["frozen_bubble", "rapid_current", "high_tide"],
	"tanah": ["hard_rock", "fortress", "stone_thorns"],
	"petir": ["shock", "card_magnet", "chain_lightning"],
	"angin": ["strong_wind", "homing_wind", "whirlwind"],
}

# Simbol: J1/J2/J3 = PRESET_URUTAN_JEBAKAN[role], T1/T2 = TAHAN_ROLE[role], U = Ultimate.
const PRESET := {
	"attack": ["J1", "J2", "J1", "U", "J3", "J2", "J1", "J3", "T1", "T2", "J2", "J3", "T1", "T2", "T1", "T2"],
	"defense": ["T1", "T2", "T1", "T2", "J1", "U", "T1", "T2", "J2", "J1", "J3", "J2", "J1", "J3", "J2", "J3"],
	"balanced": ["J1", "T1", "T2", "J2", "J1", "U", "T1", "T2", "J3", "J2", "J1", "T1", "T2", "J3", "J2", "J3"],
}

static func build_dari_preset(role: String, preset: String, sp: int, level_role: int) -> Dictionary:
	# Menjalani PRESET[preset] simbol demi simbol: tiap simbol = naikkan node
	# itu 1 tingkat KALAU tingkatnya sudah terbuka (BUKA_TINGKAT/BUKA_ULTIMATE)
	# DAN SP masih cukup; kalau tidak, LEWATI simbol itu (jangan berhenti).
	# Untuk Arena, panggil dengan level_role = LEVEL_ROLE_MAKS (semua tingkat
	# terbuka) dan sp = SP_ARENA -- SP-lah yang membatasi, bukan level. Hasil
	# selalu build_sah(hasil, role, sp, level_role) == true.
	var hasil: Dictionary = {}
	if not PRESET.has(preset) or not PRESET_URUTAN_JEBAKAN.has(role):
		return hasil
	var jebakan: Array = PRESET_URUTAN_JEBAKAN[role]
	var tahan: Array = TAHAN_ROLE.get(role, [])
	var terpakai := 0
	for simbol in PRESET[preset]:
		var id_node := ""
		if simbol == "U":
			id_node = "ULT_" + role
		elif simbol.begins_with("J"):
			var i = int(simbol.substr(1)) - 1
			if i >= 0 and i < jebakan.size():
				id_node = jebakan[i]
		elif simbol.begins_with("T"):
			var i = int(simbol.substr(1)) - 1
			if i >= 0 and i < tahan.size():
				id_node = tahan[i]
		if id_node == "":
			continue
		if id_node.begins_with("ULT_"):
			if hasil.get(id_node, false) or level_role < BUKA_ULTIMATE or terpakai + BIAYA_ULTIMATE > sp:
				continue
			hasil[id_node] = true
			terpakai += BIAYA_ULTIMATE
		else:
			var lv := int(hasil.get(id_node, 0))
			if lv >= 3:
				continue # sudah maksimal
			var lv_baru := lv + 1
			if lv_baru >= 1 and level_role < BUKA_TINGKAT[0]:
				continue
			if lv_baru >= 2 and level_role < BUKA_TINGKAT[1]:
				continue
			if lv_baru >= 3 and level_role < BUKA_TINGKAT[2]:
				continue
			var biaya_tambahan: int = BIAYA_NODE[lv_baru - 1]
			if terpakai + biaya_tambahan > sp:
				continue
			hasil[id_node] = lv_baru
			terpakai += biaya_tambahan
	return hasil

# ============================================================
# C1 (B-c/jaringan, 26-09) -- SATU sumber build Arena, dipakai lobby (kirim
# & divalidasi ulang host) dan pemain_role.gd::_siapkan_role_multiplayer.
# ============================================================

static func build_arena(role: String, simpanan) -> Dictionary:
	# simpanan biasanya ProfilPemain.arena.get(role, {}) -- {"preset":...,
	# "node": {id_node: level}} -- atau {"node": build} kiriman client lobby
	# yang divalidasi ulang di sini (client bisa mengirim apa saja).
	# K16 (DISETUJUI user 26-09): simpanan.node kosong/tidak sah (gagal
	# build_sah) -> jatuh balik ke preset Balanced 12 SP. Dipakai juga untuk
	# slot AI di multiplayer (belum punya simpanan sendiri -> {} -> Balanced).
	if typeof(simpanan) == TYPE_DICTIONARY and simpanan.has("node") and typeof(simpanan["node"]) == TYPE_DICTIONARY:
		var node_build: Dictionary = simpanan["node"]
		if build_sah(node_build, role, SP_ARENA, LEVEL_ROLE_MAKS):
			return node_build.duplicate()
	return build_dari_preset(role, "balanced", SP_ARENA, LEVEL_ROLE_MAKS)

# ============================================================
# P7 (B-e, 26-09) -- SATU sumber build solo pemain, dipakai pemain_role.gd::
# _siapkan_role_solo (K1). Bentuk simpanan SAMA dengan arena di atas.
# ============================================================

static func build_solo(role: String, simpanan, level_role: int) -> Dictionary:
	# simpanan biasanya ProfilPemain.build_solo.get(role, {}) -- {"preset":
	# "balanced"|"attack"|"defense"|"custom", "node": {id_node: level}}.
	# K21 (a, DISETUJUI user 26-09): mode preset (attack/defense/balanced) ->
	# dihitung ULANG tiap panggilan dari sp_dari_level(level_role) SEKARANG,
	# jadi naik Level Role otomatis membelanjakan SP tambahan. Mode "custom"
	# (pemain sudah menyentuh satu node sendiri) -> build dibekukan apa adanya
	# selama masih sah untuk SP/Level Role sekarang; preset/kosong/rusak/tidak
	# sah -> jatuh balik ke Balanced (K16, pola sama build_arena).
	var sp = sp_dari_level(level_role)
	var preset = ""
	if typeof(simpanan) == TYPE_DICTIONARY:
		preset = str(simpanan.get("preset", ""))
	if preset == "custom":
		var node_build = simpanan.get("node", {})
		if typeof(node_build) == TYPE_DICTIONARY and build_sah(node_build, role, sp, level_role):
			return node_build.duplicate()
	elif PRESET.has(preset):
		return build_dari_preset(role, preset, sp, level_role)
	return build_dari_preset(role, "balanced", sp, level_role)
