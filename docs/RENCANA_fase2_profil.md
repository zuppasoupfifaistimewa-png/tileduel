# RENCANA FASE 2: Profil & meta dasar

Disusun Opus, 24-09. Semua keputusan K1-K7 disetujui user 24-09 ("oke semua").
Dasar kode: set Fase 1 versi perbaikan (15 file, 24-09 malam). Mulai MENULIS KODE setelah uji HP Fase 1 (A7)
lolos -- Fase 2 mengubah bagian akhir pertandingan yang sama.

Aturan kerja (dari user): ubah hanya baris/bagian yang relevan (Edit), JANGAN menulis ulang file utuh.
Teks untuk pemain: bahasa Inggris sederhana. Saklar UJI_* di file produksi tetap false.

## 0. Yang didapat pemain

- Kepala profil di main menu: Level, nama, bar XP, Crowns. Ketuk -> panel PROFILE (ganti nama, statistik).
- Setiap pertandingan TUNTAS memberi XP & Crowns (solo & multiplayer), plus penghargaan akhir
  (DUEL KING, TRAP MASTER, LANDLORD, LUCKY ROLLER). Naik level memberi Crowns.
- Papan peringkat akhir punya kolom REWARDS + tombol WATCH AD: DOUBLE REWARDS.
- Interstisial pindah ke tombol EXIT TO MAIN MENU (setelah pemain melihat hadiahnya).
- 3 misi harian (MISSIONS, kanan atas menu) + hadiah login 7 hari (DAILY REWARD saat membuka menu).

Tidak ada yang mengubah aturan permainan: pemenang, dadu, koin, AI tetap sama (dijaga uji T1).

## 1. Keputusan

### 1a. Disetujui user (24-09)
| No | Keputusan | Angka / isi |
|---|---|---|
| K1 | Nama mata uang | **Crowns** |
| K2 | Nama pemain | diketik bebas, 3-12 huruf/angka/spasi, filter kata kasar sederhana (Inggris + Indonesia). Tanpa layar wajib: nama otomatis `Player1234`, bisa diganti kapan saja. Fase 2: nama hanya tampil di HP sendiri (HP teman: Fase 6) |
| K3 | Kurva level | Lv1->2 butuh 100 XP, tiap level berikutnya +25 XP (Lv2->3 = 125, Lv3->4 = 150, ...). Tanpa batas. Naik level = +10 x level baru Crowns. Fase 4 memakai level ini untuk jumlah jenis jebakan yang boleh dibawa |
| K4 | Crowns | 2 per giliran sendiri x pengali mode (+50% kalau menang), + penghargaan, misi, login, naik level. Belum bisa dibelanjakan sampai Fase 7-8; tertulis "Crowns will unlock items soon." |
| K5 | Urutan akhir match | animasi menang/kalah -> papan peringkat + REWARDS + tombol DOUBLE -> interstisial saat tombol EXIT ditekan (otomatis terlewat oleh jeda 3 menit kalau baru menonton Double). Double juga di multiplayer (pertandingan sudah selesai) |
| K6 | Penghargaan akhir | DUEL KING = menang duel terbanyak; TRAP MASTER = jebakan paling sering kena lawan (lihat koreksi di bawah); LANDLORD = petak terbanyak di akhir; LUCKY ROLLER = rata-rata dadu tertinggi. Seri = semua yang seri dapat. AI boleh dapat (tampil), hadiah (+15 XP, +10 Crowns per penghargaan) hanya untuk manusia di HP-nya sendiri. Pemenang match tidak berubah |
| K7 | Misi & login | 3 misi/hari (mudah + sedang + sulit) dari 12 jenis, semua bisa selesai di solo; CHANGE gratis 1x/hari; reset tengah malam jam HP. Login 7 hari: hari terlewat tidak mengulang ke Hari 1; Hari 7 terbesar lalu kembali ke Hari 1 |

Sudah diputuskan sebelumnya (dokumen desain): XP = 5 per giliran sendiri x pengali mode (Quick 1,0;
Classic 1,6), +50% kalau menang. Crowns memakai pengali yang sama.

**Koreksi kecil K6 (usul Opus, beri tahu user):** usulan awal TRAP MASTER memakai "koin lawan yang hilang
karena jebakan". Di kode, hanya jebakan Angin (15% koin) dan Api (50/giliran) yang mengambil koin; Air,
Petir dan Tanah tidak. Maka pemakai Air/Petir/Tanah tidak akan pernah jadi TRAP MASTER, dan role Fase 4
ikut timpang. Diganti: **jumlah kali jebakannya kena lawan** (Air, Angin, Api, Petir saat lawan menginjak;
Tanah saat aktif menahan serangan).

### 1b. Keputusan teknis (Opus)
- T-a **File baru `profil_pemain.gd`, autoload `ProfilPemain`** (data + simpan). UI menu di `main_menu.gd`,
  UI akhir pertandingan di `ui_dinamis.gd`. User mendaftarkan autoload (bagian 9).
- T-b **Statistik dihitung HANYA di device yang menjalankan logika** (solo / host) lewat `_catat_stat`.
  Client menerima salinannya lewat siaran state tiap giliran (untuk migrasi host) dan lewat papan skor akhir.
- T-c **Data akhir menumpang di papan skor**: tiap baris `_susun_papan_skor` mendapat `"stat"` dan
  `"penghargaan"`. Tanda tangan `rpc_permainan_selesai` TIDAK berubah; kiriman ulang setelah migrasi
  (`mulai_sekarang_migrasi`) otomatis ikut membawa datanya.
- T-d **Hadiah diberikan SEKALI per pertandingan per HP**, di `_tampilkan_akhir_permainan`, untuk
  `slot_lokal`, hanya pertandingan tuntas. Keluar di tengah jalan = tidak dapat apa-apa.
- T-e **Misi maju hanya di akhir pertandingan tuntas**, dari baris papan milik pemain HP ini (solo & multiplayer
  sama caranya, client tidak perlu menghitung apa pun sendiri).
- T-f **Simpan**: ConfigFile `user://profil.cfg` + cadangan `user://profil_cadangan.cfg` (disalin dari berkas
  utama yang sah sebelum menulis). Muat: utama -> cadangan -> profil baru.
- T-g **Tanpa acak global**: ProfilPemain memakai RandomNumberGenerator sendiri. Statistik hanya penghitung.
  Jadi jejak uji Classic/Quick tetap identik (T1).
- T-h **Tanggal = jam HP** (zona waktu HP). Pengait uji `_geser_hari`. Pemain yang mengubah tanggal HP bisa
  "memanen" misi/login: diterima (data lokal).
- T-i **Batasan diketahui**: statistik giliran yang sedang berjalan saat host pindah bisa hilang (paling
  banyak satu giliran). Profil lokal bisa diubah pemain yang sangat niat.
- T-j **Autoload tanpa `static func`** untuk fungsi yang dipanggil lewat `ProfilPemain.xxx()` (pelajaran
  perbaikan 24-09: STATIC_CALLED_ON_INSTANCE).

## 2. Angka (contoh)

Hadiah pertandingan (tanpa penghargaan):
| Pertandingan | Giliran sendiri | Kalah | Menang |
|---|---|---|---|
| Quick 2 pemain | 8 | 40 XP, 16 Crowns | 60 XP, 24 Crowns |
| Quick 4 pemain | 5 | 25 XP, 10 Crowns | 38 XP, 15 Crowns |
| Classic (mis. 12 giliran) | 12 | 96 XP, 38 Crowns | 144 XP, 58 Crowns |
Penghargaan: +15 XP, +10 Crowns masing-masing. DOUBLE REWARDS: semua angka pertandingan di atas x2.

Level: Lv2 = 100 XP total (+20 Crowns), Lv3 = 225 (+30), Lv4 = 375 (+40), Lv5 = 550 (+50), Lv10 = 1.800.
Login: Hari 1-7 = 20, 30, 40, 50, 60, 80, 150 Crowns.
Misi: mudah +20 Crowns +15 XP; sedang +30 Crowns +25 XP; sulit +50 Crowns +40 XP.

Kumpulan misi (teks = yang dilihat pemain):
| Tingkat | id | Teks | Target | Dihitung dari |
|---|---|---|---|---|
| mudah | main_2 | Play 2 matches | 2 | tiap pertandingan tuntas |
| mudah | start_3 | Pass START 3 times | 3 | stat `lewat_start` |
| mudah | beli_3 | Buy 3 tiles | 3 | stat `petak_beli` |
| sedang | duel_2 | Win 2 duels | 2 | stat `duel_menang` |
| sedang | jebakan_3 | Set 3 traps | 3 | stat `jebakan_pasang` |
| sedang | permata_3 | Collect 3 gems | 3 | stat `permata` |
| sedang | kartu_2 | Use 2 cards | 2 | stat `kartu_pakai` |
| sulit | menang_1 | Win a match | 1 | menang |
| sulit | elemen_1 | Win a duel with FIRE (elemen acak) | 1 | stat `duel_menang_<elemen>` |
| sulit | menara_2 | Build 2 towers | 2 | stat `menara` (Lv1 & Lv2 dihitung) |
| sulit | kena_2 | Catch rivals in your traps 2 times | 2 | stat `jebakan_kena` |
| sulit | award_1 | Win an award | 1 | dapat penghargaan apa pun |
Kemajuan misi dijumlahkan lintas pertandingan di hari yang sama. Misi yang sudah selesai tapi belum diklaim
saat hari berganti diberikan otomatis (tidak hilang).

## 3. Bagian A: `profil_pemain.gd` (FILE BARU, autoload `ProfilPemain`)

Kode lengkap di bawah SUDAH diuji Opus di rig (uji_profil.gd: 39/39 cek, tanpa warning). Salin apa adanya.

```gdscript
extends Node
# ============================================================
# PROFIL PEMAIN (Fase 2) -- autoload "ProfilPemain".
# Profil di HP ini: nama, XP (-> Level Pemain), Crowns, statistik seumur profil,
# misi harian, dan hadiah login 7 hari. Semua angka aturan ada di KONSTANTA.
# Data lokal: pemain yang sangat niat masih bisa mengubah berkasnya (diterima).
# PENTING: autoload -> JANGAN pakai "static func" untuk fungsi yang dipanggil lewat
# ProfilPemain.xxx() (Godot memberi peringatan STATIC_CALLED_ON_INSTANCE).
# ============================================================

signal profil_berubah

const BERKAS := "user://profil.cfg"
const BERKAS_CADANGAN := "user://profil_cadangan.cfg"
const VERSI := 1

# --- XP & Crowns per pertandingan (keputusan 24-09) ---
const XP_PER_GILIRAN := 5
const CROWNS_PER_GILIRAN := 2
const PENGALI_QUICK := 1.0
const PENGALI_CLASSIC := 1.6
const BONUS_MENANG := 1.5
const XP_PENGHARGAAN := 15
const CROWNS_PENGHARGAAN := 10
# --- Level: Lv1->2 butuh 100 XP, tiap level berikutnya +25 XP. Tanpa batas. ---
const XP_LEVEL_AWAL := 100
const XP_TAMBAH_PER_LEVEL := 25
const CROWNS_NAIK_LEVEL := 10 # x level baru (naik ke Lv 3 = +30 Crowns)
# --- Login 7 hari: hari terlewat TIDAK mengulang ke Hari 1 ---
const HADIAH_LOGIN := [20, 30, 40, 50, 60, 80, 150]
# --- Penghargaan akhir (dihitung host: pemain.gd _isi_penghargaan) ---
const NAMA_PENGHARGAAN := {
	"duel_king": "DUEL KING",
	"trap_master": "TRAP MASTER",
	"landlord": "LANDLORD",
	"lucky_roller": "LUCKY ROLLER",
}
# --- Misi harian: 1 mudah + 1 sedang + 1 sulit per hari; semua bisa selesai di solo ---
# "stat" = kunci statistik pertandingan (pemain.gd KUNCI_STATISTIK), atau khusus:
# "_match" tiap pertandingan tuntas, "_menang", "_penghargaan", "_elemen".
const MISI := {
	"main_2": {"tingkat": 0, "teks": "Play 2 matches", "target": 2, "stat": "_match"},
	"start_3": {"tingkat": 0, "teks": "Pass START 3 times", "target": 3, "stat": "lewat_start"},
	"beli_3": {"tingkat": 0, "teks": "Buy 3 tiles", "target": 3, "stat": "petak_beli"},
	"duel_2": {"tingkat": 1, "teks": "Win 2 duels", "target": 2, "stat": "duel_menang"},
	"jebakan_3": {"tingkat": 1, "teks": "Set 3 traps", "target": 3, "stat": "jebakan_pasang"},
	"permata_3": {"tingkat": 1, "teks": "Collect 3 gems", "target": 3, "stat": "permata"},
	"kartu_2": {"tingkat": 1, "teks": "Use 2 cards", "target": 2, "stat": "kartu_pakai"},
	"menang_1": {"tingkat": 2, "teks": "Win a match", "target": 1, "stat": "_menang"},
	"elemen_1": {"tingkat": 2, "teks": "Win a duel with %s", "target": 1, "stat": "_elemen"},
	"menara_2": {"tingkat": 2, "teks": "Build 2 towers", "target": 2, "stat": "menara"},
	"kena_2": {"tingkat": 2, "teks": "Catch rivals in your traps 2 times", "target": 2, "stat": "jebakan_kena"},
	"award_1": {"tingkat": 2, "teks": "Win an award", "target": 1, "stat": "_penghargaan"},
}
const HADIAH_MISI := [{"crowns": 20, "xp": 15}, {"crowns": 30, "xp": 25}, {"crowns": 50, "xp": 40}]
const NAMA_ELEMEN := {"api": "FIRE", "air": "WATER", "tanah": "EARTH", "petir": "LIGHTNING", "angin": "WIND"}
# Statistik pertandingan yang dijumlahkan ke statistik seumur profil.
const STAT_SEUMUR := ["giliran", "duel_menang", "jebakan_pasang", "jebakan_kena", "petak_beli", "menara", "permata", "kartu_pakai", "lewat_start"]
# Filter nama sederhana (boleh ditambah). KATA_KASAR dicari di mana saja (setelah
# angka mirip huruf diganti: 0->o 1->i 3->e 4->a 5->s 7->t); KATA_KASAR_PENDEK hanya
# sebagai kata utuh (supaya "Asuka", "Colin", "Hancock" tetap boleh).
const KATA_KASAR := ["fuck", "shit", "bitch", "cunt", "pussy", "asshole", "bastard", "whore", "slut",
	"nigger", "nigga", "faggot", "retard", "hitler", "penis", "vagina",
	"anjing", "anjeng", "bangsat", "kontol", "memek", "ngentot", "ngewe", "jancok", "jancuk",
	"goblok", "goblog", "tolol", "kampret", "pepek", "peler", "titit", "pantek", "bajingan",
	"keparat", "lonte", "pelacur", "bokep", "colmek", "jembut", "kimak", "sundal"]
const KATA_KASAR_PENDEK := ["ass", "sex", "fck", "fuk", "sht", "dick", "cock", "nazi", "rape", "porn",
	"boob", "tits", "cok", "asu", "tai", "anj", "bgst", "kntl", "mmk", "babi", "coli", "itil",
	"puki", "perek", "sange", "ngentd"]

var id := ""
var nama := ""
var xp_total := 0
var crowns := 0
var statistik := {}
var misi: Array = []             # 3 x {"id", "progres", "diklaim", "elemen"}
var tanggal_misi := ""
var ganti_misi_dipakai := false  # CHANGE gratis 1x per hari
var hari_login := 1              # hadiah login berikutnya: Hari 1..7
var tanggal_login := ""          # tanggal klaim login terakhir ("" = belum pernah)
var _geser_hari := 0             # HANYA uji: memajukan tanggal tanpa menunggu
# Pengacak SENDIRI: acak global & mesin_acak dipakai permainan (jejak uji tetap sama).
var _acak := RandomNumberGenerator.new()

func _ready() -> void:
	_acak.randomize()
	muat()

# ============================================================
# SIMPAN / MUAT (berkas utama + cadangan)
# ============================================================
func muat() -> void:
	var c = _baca_berkas(BERKAS)
	if c == null:
		c = _baca_berkas(BERKAS_CADANGAN)
	if c == null:
		_profil_baru()
		return
	id = str(c.get_value("profil", "id", ""))
	nama = str(c.get_value("profil", "nama", ""))
	xp_total = maxi(0, int(c.get_value("profil", "xp_total", 0)))
	crowns = maxi(0, int(c.get_value("profil", "crowns", 0)))
	var s = c.get_value("profil", "statistik", {})
	statistik = s if s is Dictionary else {}
	var m = c.get_value("misi", "daftar", [])
	misi = m if m is Array else []
	tanggal_misi = str(c.get_value("misi", "tanggal", ""))
	ganti_misi_dipakai = bool(c.get_value("misi", "ganti_dipakai", false))
	hari_login = clampi(int(c.get_value("login", "hari", 1)), 1, 7)
	tanggal_login = str(c.get_value("login", "tanggal", ""))
	if cek_nama(nama) != "":
		nama = _nama_bawaan()

func _baca_berkas(jalur: String):
	# ConfigFile yang sah (terbaca & punya id), atau null.
	var c = ConfigFile.new()
	if c.load(jalur) != OK or str(c.get_value("profil", "id", "")) == "":
		return null
	return c

func simpan() -> void:
	var c = ConfigFile.new()
	c.set_value("profil", "versi", VERSI)
	c.set_value("profil", "id", id)
	c.set_value("profil", "nama", nama)
	c.set_value("profil", "xp_total", xp_total)
	c.set_value("profil", "crowns", crowns)
	c.set_value("profil", "statistik", statistik)
	c.set_value("misi", "daftar", misi)
	c.set_value("misi", "tanggal", tanggal_misi)
	c.set_value("misi", "ganti_dipakai", ganti_misi_dipakai)
	c.set_value("login", "hari", hari_login)
	c.set_value("login", "tanggal", tanggal_login)
	# Cadangan dulu -- hanya dari berkas utama yang SAH. Kalau HP mati saat menulis
	# berkas utama, muat() memakai cadangan ini.
	if _baca_berkas(BERKAS) != null:
		DirAccess.copy_absolute(BERKAS, BERKAS_CADANGAN)
	var err = c.save(BERKAS)
	if err != OK:
		push_warning("Profil gagal disimpan (kode %d)." % err)
	profil_berubah.emit()

func _profil_baru() -> void:
	id = "%08x%08x" % [_acak.randi(), _acak.randi()]
	nama = _nama_bawaan()
	xp_total = 0
	crowns = 0
	statistik = {}
	misi = []
	tanggal_misi = ""
	ganti_misi_dipakai = false
	hari_login = 1
	tanggal_login = ""
	simpan()

func _nama_bawaan() -> String:
	return "Player%d" % _acak.randi_range(1000, 9999)

# ============================================================
# LEVEL
# ============================================================
func xp_dibutuhkan(lv: int) -> int:
	# XP untuk naik dari level lv ke lv+1.
	return XP_LEVEL_AWAL + XP_TAMBAH_PER_LEVEL * (lv - 1)

func info_level() -> Dictionary:
	# {"level", "xp_dalam_level", "xp_naik"} -- untuk label & bar XP.
	var lv = 1
	var sisa = xp_total
	while sisa >= xp_dibutuhkan(lv):
		sisa -= xp_dibutuhkan(lv)
		lv += 1
	return {"level": lv, "xp_dalam_level": sisa, "xp_naik": xp_dibutuhkan(lv)}

func level() -> int:
	return int(info_level()["level"])

func _tambah_xp(n: int) -> Dictionary:
	# XP bertambah; tiap level baru memberi Crowns (10 x level baru).
	var lama = level()
	xp_total += maxi(0, n)
	var baru = level()
	var bonus = 0
	for lv in range(lama + 1, baru + 1):
		bonus += CROWNS_NAIK_LEVEL * lv
	crowns += bonus
	return {"level_lama": lama, "level_baru": baru, "crowns_level": bonus}

# ============================================================
# HADIAH PERTANDINGAN
# baris = baris papan skor milik pemain HP ini: {"slot", ..., "stat": {...},
# "penghargaan": [...]} (disusun host di pemain.gd _susun_papan_skor).
# ============================================================
func hitung_hadiah_match(baris: Dictionary, menang: bool, quick: bool) -> Dictionary:
	var stat: Dictionary = baris.get("stat", {})
	var giliran = int(stat.get("giliran", 0))
	var pengali = (PENGALI_QUICK if quick else PENGALI_CLASSIC) * (BONUS_MENANG if menang else 1.0)
	var penghargaan: Array = baris.get("penghargaan", [])
	var xp = roundi(XP_PER_GILIRAN * giliran * pengali) + penghargaan.size() * XP_PENGHARGAAN
	var cr = roundi(CROWNS_PER_GILIRAN * giliran * pengali) + penghargaan.size() * CROWNS_PENGHARGAAN
	return {"xp": xp, "crowns": cr, "penghargaan": penghargaan.duplicate()}

func catat_match(baris: Dictionary, menang: bool, quick: bool) -> Dictionary:
	# Dipanggil pemain.gd SEKALI per pertandingan tuntas, untuk pemain di HP ini.
	# Hasil = ringkasan untuk layar hasil: xp, crowns, penghargaan, level_lama,
	# level_baru, crowns_level, misi_selesai (teks), digandakan.
	pastikan_misi_hari_ini()
	var h = hitung_hadiah_match(baris, menang, quick)
	crowns += int(h["crowns"])
	var lv = _tambah_xp(int(h["xp"]))
	var stat: Dictionary = baris.get("stat", {})
	for k in STAT_SEUMUR:
		statistik[k] = int(statistik.get(k, 0)) + int(stat.get(k, 0))
	_tambah_stat("match_main")
	if menang:
		_tambah_stat("match_menang")
	_tambah_stat("match_quick" if quick else "match_classic")
	for p in h["penghargaan"]:
		_tambah_stat("penghargaan")
		_tambah_stat("penghargaan_" + str(p))
	var selesai = _majukan_misi(baris, menang)
	simpan()
	h.merge(lv)
	h["misi_selesai"] = selesai
	h["digandakan"] = false
	return h

func gandakan_hadiah(r: Dictionary) -> Dictionary:
	# Iklan DOUBLE REWARDS: XP & Crowns pertandingan (termasuk penghargaan) diberikan
	# sekali lagi. Bonus naik level ikut dihitung; hadiah misi TIDAK digandakan.
	if r.is_empty() or r.get("digandakan", false):
		return r
	r["digandakan"] = true
	crowns += int(r["crowns"])
	var lv = _tambah_xp(int(r["xp"]))
	r["xp"] = int(r["xp"]) * 2
	r["crowns"] = int(r["crowns"]) * 2
	r["level_baru"] = lv["level_baru"]
	r["crowns_level"] = int(r.get("crowns_level", 0)) + int(lv["crowns_level"])
	simpan()
	return r

func _tambah_stat(kunci: String, n: int = 1) -> void:
	statistik[kunci] = int(statistik.get(kunci, 0)) + n

# ============================================================
# MISI HARIAN
# ============================================================
func _hari_ini() -> String:
	# Tanggal menurut jam HP (zona waktu HP), + _geser_hari untuk uji.
	var t = Time.get_unix_time_from_system() + int(Time.get_time_zone_from_system()["bias"]) * 60 + _geser_hari * 86400
	return Time.get_date_string_from_unix_time(int(t))

func detik_sampai_besok() -> int:
	var t = int(Time.get_unix_time_from_system()) + int(Time.get_time_zone_from_system()["bias"]) * 60
	return 86400 - posmod(t, 86400)

func pastikan_misi_hari_ini() -> Dictionary:
	# Hari berganti: misi yang sudah selesai tapi belum diklaim diberikan otomatis,
	# lalu 3 misi baru. Hasil: {"crowns", "xp", ...} yang diberikan otomatis ({} = tidak ada).
	var hari = _hari_ini()
	if tanggal_misi == hari and misi.size() == 3:
		return {}
	var otomatis = {"crowns": 0, "xp": 0}
	for m in misi:
		if m is Dictionary and not m.get("diklaim", false) and misi_selesai(m):
			var hd = hadiah_misi(m)
			otomatis["crowns"] += int(hd["crowns"])
			otomatis["xp"] += int(hd["xp"])
	crowns += int(otomatis["crowns"])
	otomatis.merge(_tambah_xp(int(otomatis["xp"])))
	misi = []
	for tingkat in range(3):
		misi.append(_misi_baru(tingkat, []))
	tanggal_misi = hari
	ganti_misi_dipakai = false
	simpan()
	return otomatis if int(otomatis["crowns"]) > 0 else {}

func _misi_baru(tingkat: int, kecuali: Array) -> Dictionary:
	var calon = []
	for k in MISI:
		if int(MISI[k]["tingkat"]) == tingkat and not kecuali.has(k):
			calon.append(k)
	if calon.is_empty():
		for k in MISI:
			if int(MISI[k]["tingkat"]) == tingkat:
				calon.append(k)
	var id_misi = calon[_acak.randi_range(0, calon.size() - 1)]
	var el = ""
	if MISI[id_misi]["stat"] == "_elemen":
		var semua = NAMA_ELEMEN.keys()
		el = semua[_acak.randi_range(0, semua.size() - 1)]
	return {"id": id_misi, "progres": 0, "diklaim": false, "elemen": el}

func _definisi(m: Dictionary) -> Dictionary:
	return MISI.get(str(m.get("id", "")), {})

func target_misi(m: Dictionary) -> int:
	return int(_definisi(m).get("target", 1))

func hadiah_misi(m: Dictionary) -> Dictionary:
	return HADIAH_MISI[clampi(int(_definisi(m).get("tingkat", 0)), 0, 2)]

func misi_selesai(m: Dictionary) -> bool:
	return int(m.get("progres", 0)) >= target_misi(m)

func teks_misi(m: Dictionary) -> String:
	var d = _definisi(m)
	if d.is_empty():
		return ""
	if d["stat"] == "_elemen":
		return d["teks"] % NAMA_ELEMEN.get(str(m.get("elemen", "api")), "FIRE")
	return d["teks"]

func jumlah_misi_bisa_diklaim() -> int:
	var n = 0
	for m in misi:
		if m is Dictionary and not m.get("diklaim", false) and misi_selesai(m):
			n += 1
	return n

func _majukan_misi(baris: Dictionary, menang: bool) -> Array:
	# Kemajuan misi dari SATU pertandingan tuntas. Hasil: teks misi yang baru selesai.
	var stat: Dictionary = baris.get("stat", {})
	var selesai = []
	for m in misi:
		if not (m is Dictionary) or m.get("diklaim", false) or misi_selesai(m):
			continue
		var tambah = 0
		match str(_definisi(m).get("stat", "")):
			"_match":
				tambah = 1
			"_menang":
				tambah = 1 if menang else 0
			"_penghargaan":
				tambah = 0 if (baris.get("penghargaan", []) as Array).is_empty() else 1
			"_elemen":
				tambah = int(stat.get("duel_menang_" + str(m.get("elemen", "")), 0))
			var kunci:
				tambah = int(stat.get(kunci, 0))
		if tambah <= 0:
			continue
		m["progres"] = mini(target_misi(m), int(m.get("progres", 0)) + tambah)
		if misi_selesai(m):
			selesai.append(teks_misi(m))
	return selesai

func klaim_misi(i: int) -> Dictionary:
	# Tombol CLAIM. Hasil: {"crowns", "xp", "level_lama", "level_baru", "crowns_level"} atau {}.
	if i < 0 or i >= misi.size():
		return {}
	var m = misi[i]
	if m.get("diklaim", false) or not misi_selesai(m):
		return {}
	m["diklaim"] = true
	var hd = hadiah_misi(m)
	crowns += int(hd["crowns"])
	var hasil = _tambah_xp(int(hd["xp"]))
	hasil["crowns"] = int(hd["crowns"])
	hasil["xp"] = int(hd["xp"])
	simpan()
	return hasil

func bisa_ganti_misi(i: int) -> bool:
	return not ganti_misi_dipakai and i >= 0 and i < misi.size() and not misi[i].get("diklaim", false) and not misi_selesai(misi[i])

func ganti_misi(i: int) -> bool:
	# Tombol CHANGE: gratis sekali per hari, hanya untuk misi yang belum selesai.
	if not bisa_ganti_misi(i):
		return false
	var kecuali = []
	for m in misi:
		kecuali.append(str(m.get("id", "")))
	misi[i] = _misi_baru(int(_definisi(misi[i]).get("tingkat", 0)), kecuali)
	ganti_misi_dipakai = true
	simpan()
	return true

# ============================================================
# HADIAH LOGIN 7 HARI
# ============================================================
func login_bisa_diklaim() -> bool:
	return tanggal_login != _hari_ini()

func klaim_login() -> Dictionary:
	# Hasil: {"hari", "crowns"} atau {} kalau hari ini sudah diklaim.
	if not login_bisa_diklaim():
		return {}
	var hari = hari_login
	var jumlah = int(HADIAH_LOGIN[hari - 1])
	crowns += jumlah
	hari_login = hari % 7 + 1
	tanggal_login = _hari_ini()
	simpan()
	return {"hari": hari, "crowns": jumlah}

# ============================================================
# NAMA
# ============================================================
func ganti_nama(baru: String) -> String:
	# "" = berhasil; selain itu pesan untuk pemain.
	var salah = cek_nama(baru)
	if salah != "":
		return salah
	nama = _rapikan_nama(baru)
	simpan()
	return ""

func _rapikan_nama(n: String) -> String:
	var b = n.strip_edges()
	while b.contains("  "):
		b = b.replace("  ", " ")
	return b

func cek_nama(n: String) -> String:
	var b = _rapikan_nama(n)
	var pola = RegEx.new()
	pola.compile("^[A-Za-z0-9 ]{3,12}$")
	if pola.search(b) == null:
		return "Name: 3-12 letters or numbers."
	if _nama_kasar(b):
		return "Please choose another name."
	return ""

func _nama_kasar(n: String) -> bool:
	var kecil = n.to_lower()
	var leet = kecil
	for p in [["0", "o"], ["1", "i"], ["3", "e"], ["4", "a"], ["5", "s"], ["7", "t"]]:
		leet = leet.replace(p[0], p[1])
	var rapat = leet.replace(" ", "")
	for k in KATA_KASAR:
		if rapat.contains(k):
			return true
	# Kata pendek: kata utuh saja, dicek dua cara (angka dibuang / angka jadi huruf).
	var calon = [kecil.replace(" ", ""), rapat]
	for kata in kecil.split(" ", false):
		calon.append(kata)
	for kata in leet.split(" ", false):
		calon.append(kata)
	for c in calon:
		var huruf = ""
		for ch in c:
			if ch >= "a" and ch <= "z":
				huruf += ch
		if KATA_KASAR_PENDEK.has(huruf) or KATA_KASAR_PENDEK.has(c):
			return true
	return false
```

## 4. Bagian B: statistik pertandingan (`pemain.gd` + `ai_musuh.gd`)

### B1. Variabel & fungsi baru (pemain.gd)
Sesudah baris `var _iklan_hutang_terpakai: bool = false ...` (bagian IKLAN BERHADIAH):
```gdscript
# --- PROFIL & META (Fase 2) ---
# Statistik pertandingan per slot. Dihitung HANYA di device yang menjalankan logika
# (solo / host); client menerimanya lewat siaran state & papan skor akhir.
const KUNCI_STATISTIK = ["giliran", "dadu_jumlah", "dadu_kali", "duel_menang", "duel_kalah",
	"duel_menang_api", "duel_menang_air", "duel_menang_tanah", "duel_menang_petir", "duel_menang_angin",
	"jebakan_pasang", "jebakan_kena", "petak_beli", "menara", "permata", "lewat_start", "kartu_pakai"]
var statistik_slot: Array = []
var _hadiah_profil_diberikan: bool = false # hadiah pertandingan ini sudah dicatat di profil
var _ringkasan_profil: Dictionary = {}     # hasil ProfilPemain.catat_match, dibaca layar hasil
```
Blok fungsi baru, taruh sesudah `_tawarkan_iklan_hutang` (sebelum `update_ui_status`):
```gdscript
# ========================================================
# STATISTIK PERTANDINGAN & PENGHARGAAN AKHIR (Fase 2)
# ========================================================
func _statistik_kosong() -> Dictionary:
	var s = {}
	for k in KUNCI_STATISTIK:
		s[k] = 0
	return s

func _pastikan_statistik() -> void:
	# Diisi malas: rig uji & jalur migrasi tidak selalu lewat _siapkan_peta_dan_mulai.
	while statistik_slot.size() < jumlah_pemain():
		statistik_slot.append(_statistik_kosong())

func _catat_stat(slot: int, kunci: String, n: int = 1) -> void:
	# Hanya device yang menjalankan logika (solo / host). Client: lewat siaran state.
	if StatusJaringan.peran_multiplayer == "client" or _permainan_selesai:
		return
	_pastikan_statistik()
	if slot < 0 or slot >= statistik_slot.size():
		return
	statistik_slot[slot][kunci] = int(statistik_slot[slot].get(kunci, 0)) + n

func _isi_penghargaan(papan: Array) -> void:
	# Penghargaan akhir untuk SEMUA slot (AI juga). Seri = semua yang seri dapat.
	# Nilai 0 = tidak ada yang layak (mis. tidak ada duel yang dimenangkan).
	for b in papan:
		b["penghargaan"] = []
	for kunci in ["duel_king", "trap_master", "landlord", "lucky_roller"]:
		var terbaik = 0.0
		for b in papan:
			terbaik = maxf(terbaik, _nilai_penghargaan(b, kunci))
		if terbaik <= 0.0:
			continue
		for b in papan:
			if is_equal_approx(_nilai_penghargaan(b, kunci), terbaik):
				b["penghargaan"].append(kunci)

func _nilai_penghargaan(b: Dictionary, kunci: String) -> float:
	var s: Dictionary = b.get("stat", {})
	match kunci:
		"duel_king":
			return float(s.get("duel_menang", 0))
		"trap_master":
			return float(s.get("jebakan_kena", 0))
		"landlord":
			return float(b.get("petak", 0))
		"lucky_roller":
			# Rata-rata lemparan BIASA (tanpa kartu LOW/HIGH ROLL), minimal 3 lemparan.
			var kali = int(s.get("dadu_kali", 0))
			if kali < 3:
				return 0.0
			return snappedf(float(s.get("dadu_jumlah", 0)) / kali, 0.01)
	return 0.0
```

### B2. Titik hitung (pemain.gd) -- semua memanggil `_catat_stat` (aman dipanggil di client: diabaikan)
| Di mana | Tambahkan | Catatan |
|---|---|---|
| `_mulai_giliran`, tepat sesudah `_dijeda_di_awal_giliran = false` | `_catat_stat(slot, "giliran")` | tiap giliran (lumpuh pun tetap giliran) |
| `_mulai_transisi_game`, tepat sebelum `fase_giliran = "awal"` (jalur normal, sesudah pemeriksaan generasi) | `_catat_stat(_slot_dari_aktor(giliran_sekarang), "giliran")` | giliran pertama tidak lewat `_mulai_giliran` |
| `lempar_dadu`, sesudah blok `if UJI_DUEL:` | `if tipe_dadu != "rendah" and tipe_dadu != "tinggi":` lalu `_catat_stat(slot_pelempar, "dadu_jumlah", hasil_dadu)` dan `_catat_stat(slot_pelempar, "dadu_kali")` | LUCKY ROLLER tanpa kartu dadu |
| `bergerak_maju`, sesudah `lewati_start = true` | `_catat_stat(slot, "lewat_start")` | tiap lewat START (gaji berhasil atau tidak) |
| `bergerak_maju`, baris pertama di dalam `if cek_jebakan and cek_jebakan.aktif ...` (Air) | `_catat_stat(cek_jebakan.pemilik, "jebakan_kena")` | |
| idem blok `cek_angin` (Angin) | `_catat_stat(cek_angin.pemilik, "jebakan_kena")` | |
| idem blok `cek_api` (Api) | `_catat_stat(cek_api.pemilik, "jebakan_kena")` | |
| idem blok `cek_petir` (Petir) | `_catat_stat(cek_petir.pemilik, "jebakan_kena")` | |
| `bergerak_maju`, di dalam `if not koleksi_aktif.has(kode_gambar_permata):` | `_catat_stat(slot, "permata")` | permata BARU saja |
| `_ambil_permata_setelah_paralisis`, di dalam `if not koleksi_aktif.has(...)` | `_catat_stat(slot, "permata")` | |
| `_mulai_duel`, baris pertama di dalam `if cek_tanah and cek_tanah.aktif:` | `_catat_stat(cek_tanah.pemilik, "jebakan_kena")` | Tanah menahan serangan |
| `_mulai_duel`, tepat sebelum `AudioGrafis.mulai_musik_duel(self)` | `if poin_bonus_pedang > 0: _catat_stat(slot_a, "kartu_pakai")` | kartu pedang (manusia & AI) |
| `eksekusi_dadu_pertarungan`, awal fungsi | blok B3 | duel |
| 5 fungsi pasang jebakan (`_on_tombol_air_pressed`, `_on_tombol_angin_pressed`, `_on_tombol_api_pressed`, `_on_tombol_trap_petir_pressed`, `_on_tombol_trap_tanah_pressed`), tepat sesudah `jebakan.pemilik = slot_giliran_ui` | `_catat_stat(slot_giliran_ui, "jebakan_pasang")` | AI belum memasang jebakan (Fase 4) |
| `_on_tombol_beli_pressed`, sesudah `nyawa_petak[...] = 3` (jalur beli, bukan konfrontasi) | `_catat_stat(slot_giliran_ui, "petak_beli")` | |
| `_on_tombol_bangun_pressed`, di kedua cabang Lv1 & Lv2 sesudah `nyawa_petak[...] += 1` | `_catat_stat(slot_giliran_ui, "menara")` | |
| `_eksekusi_kartu_simpan`, sesudah `var slot = _slot_dari_aktor(aktor)` | `_catat_stat(slot, "kartu_pakai")` | Use Card (manusia & AI) |

`ai_musuh.gd` (`logika_ai_musuh_setelah_jalan`):
- beli: sesudah `main_node.nyawa_petak[posisi] = 3` -> `main_node._catat_stat(slot, "petak_beli")`
- bangun Lv1 & upgrade Lv2: sesudah masing-masing `main_node.nyawa_petak[posisi] += 1` -> `main_node._catat_stat(slot, "menara")`

### B3. Duel: elemen pemenang
`_jalankan_duel`: kamus hasilnya ditambah satu kunci (ui_elemen menyimpan pilihan kedua sisi layar ini):
```gdscript
	return {
		"slot_pemenang": sisi_p if hasil_ui["pemenang_final"] == "pemain" else sisi_m,
		"poin_sisa": selisih if selisih > 0 else 999,
		# Fase 2: misi "Win a duel with FIRE" (dan mastery elemen nanti).
		"elemen_pemenang": ui_elemen.elemen_pilihan_pemain if hasil_ui["pemenang_final"] == "pemain" else ui_elemen.elemen_pilihan_musuh,
	}
```
`eksekusi_dadu_pertarungan`, awal fungsi (sebelum `teks_uang.show()`):
```gdscript
	# Fase 2: statistik duel (DUEL KING, misi duel).
	var slot_menang = int(hasil_duel["slot_pemenang"])
	_catat_stat(slot_menang, "duel_menang")
	_catat_stat(slot_pembela if slot_menang == slot_penyerang else slot_penyerang, "duel_kalah")
	var el_menang = str(hasil_duel.get("elemen_pemenang", ""))
	if el_menang != "":
		_catat_stat(slot_menang, "duel_menang_" + el_menang)
```

### B4. Sinkron multiplayer
- `_siarkan_state_giliran`: baris pertama fungsi `_pastikan_statistik()`, lalu di kamus `data` (sesudah `"ronde": ronde_sekarang,`):
  `"statistik": statistik_slot.duplicate(true),` dengan komentar "Fase 2: statistik ikut (migrasi host / lanjut sendiri)".
- `rpc_terima_state_giliran`: sesudah blok `if data.has("kartu"): ...`:
```gdscript
	if data.has("statistik"):
		# Fase 2: device ini bisa jadi host baru (migrasi) -- lanjutkan dari angka host.
		_pastikan_statistik()
		for i in range(mini(statistik_slot.size(), data["statistik"].size())):
			statistik_slot[i] = (data["statistik"][i] as Dictionary).duplicate()
```

## 5. Bagian C: akhir pertandingan

### C1. Papan skor membawa statistik & penghargaan (pemain.gd `_susun_papan_skor`)
- Baris pertama fungsi: `_pastikan_statistik()`.
- Di kamus tiap slot (sesudah `"kekayaan": _kekayaan_slot(slot),`): `"stat": (statistik_slot[slot] as Dictionary).duplicate(),`
- Tepat sebelum `return hasil`: `_isi_penghargaan(hasil)` (komentar: "Fase 2: dihitung host, sama di semua HP").
Urutan & pemenang TIDAK berubah.

### C2. Hadiah profil (pemain.gd `_tampilkan_akhir_permainan`)
Sesudah baris `var menang = (slot_pemenang == slot_lokal)`:
```gdscript
	# Fase 2: XP, Crowns, statistik & misi untuk pemain di HP ini -- SEKALI per
	# pertandingan tuntas (kabar akhir bisa dikirim ulang setelah migrasi host).
	if not _hadiah_profil_diberikan:
		_hadiah_profil_diberikan = true
		for b in papan_skor:
			if int(b.get("slot", -1)) == slot_lokal:
				_ringkasan_profil = ProfilPemain.catat_match(b, menang, mode_quick)
```

### C3. Interstisial pindah (ui_dinamis.gd `tampilkan_akhir_permainan`)
Hapus blok interstisial (komentar "Fase 1: jeda alami ..." + `await PengelolaIklan.tampilkan_interstisial_akhir_match()`
+ pemeriksaan `is_instance_valid` kedua). Akhir fungsi menjadi:
```gdscript
	if not is_instance_valid(main_node) or not main_node.is_inside_tree():
		return
	# Fase 2: interstisial pindah ke tombol EXIT di papan peringkat (pemain sempat
	# melihat hadiahnya & memilih DOUBLE REWARDS dulu).
	_panel_papan_skor(main_node, menang, papan_skor)
```

### C4. Papan peringkat + kolom REWARDS (ui_dinamis.gd `_panel_papan_skor`)
Susunan baru: `luar` (VBox di tengah) = [`kolom` (HBox: `vbox` peringkat lama | kotak REWARDS), tombol EXIT].
1. Ganti pembuatan `vbox` (4 baris anchor/grow + add_child ke canvas) dengan:
```gdscript
	var luar = VBoxContainer.new()
	luar.set_anchors_preset(Control.PRESET_CENTER)
	luar.grow_horizontal = Control.GROW_DIRECTION_BOTH
	luar.grow_vertical = Control.GROW_DIRECTION_BOTH
	luar.add_theme_constant_override("separation", 18)
	canvas.add_child(luar)
	var kolom = HBoxContainer.new()
	kolom.alignment = BoxContainer.ALIGNMENT_CENTER
	kolom.add_theme_constant_override("separation", 48)
	luar.add_child(kolom)
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	kolom.add_child(vbox)
```
2. Sesudah loop baris peringkat (sebelum tombol EXIT), baris penghargaan SEMUA pemain + kotak REWARDS:
```gdscript
	# Fase 2: penghargaan akhir semua pemain (papan dari host -- sama di semua HP).
	for kunci in ProfilPemain.NAMA_PENGHARGAAN:
		var pemilik = []
		for baris_papan in papan_skor:
			if (baris_papan.get("penghargaan", []) as Array).has(kunci):
				pemilik.append(_nama_pendek(main_node, int(baris_papan["slot"])))
		if not pemilik.is_empty():
			vbox.add_child(_label_hasil("%s:  %s" % [ProfilPemain.NAMA_PENGHARGAAN[kunci], ", ".join(pemilik)], 18, Color(1.0, 0.85, 0.2)))
	var ringkasan = main_node.get("_ringkasan_profil")
	if ringkasan is Dictionary and not ringkasan.is_empty():
		kolom.add_child(_kotak_hadiah(ringkasan))
```
3. Tombol EXIT: tambah `btn_exit.size_flags_horizontal = Control.SIZE_SHRINK_CENTER`, masukkan ke `luar`
   (bukan `vbox`), dan ganti isi handler-nya:
```gdscript
	btn_exit.pressed.connect(func():
		btn_exit.disabled = true
		# Fase 2: interstisial di jeda alami ini (sebelum tombol lanjut). Langsung kembali
		# kalau belum waktunya: pertandingan pertama, jeda 3 menit (mis. baru menonton
		# DOUBLE REWARDS), atau offline.
		await PengelolaIklan.tampilkan_interstisial_akhir_match()
		if is_instance_valid(main_node) and main_node.is_inside_tree():
			keluar_ke_main_menu(main_node)
	)
	luar.add_child(btn_exit)
```
4. Fungsi baru (sesudah `_panel_papan_skor`):
```gdscript
static func _nama_pendek(main_node: Node, slot: int) -> String:
	if slot == main_node.slot_lokal:
		return "YOU"
	if main_node.daftar_pemain.size() <= 2:
		return "ENEMY"
	return "P%d" % (slot + 1)

static func _label_hasil(teks: String, ukuran: int, warna: Color) -> Label:
	var l = Label.new()
	l.text = teks
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", ukuran)
	l.add_theme_color_override("font_color", warna)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 5)
	return l

static func _kotak_hadiah(r: Dictionary) -> VBoxContainer:
	# Kolom kanan papan peringkat: hadiah pemain HP ini + tombol DOUBLE REWARDS.
	var kotak = VBoxContainer.new()
	kotak.custom_minimum_size = Vector2(380, 0)
	kotak.alignment = BoxContainer.ALIGNMENT_CENTER
	kotak.add_theme_constant_override("separation", 10)
	kotak.add_child(_label_hasil("REWARDS", 28, Color(1.0, 0.85, 0.2)))
	var dapat = _label_hasil("", 26, Color.WHITE)
	kotak.add_child(dapat)
	for k in r.get("penghargaan", []):
		kotak.add_child(_label_hasil("%s  +%d XP" % [ProfilPemain.NAMA_PENGHARGAAN.get(k, str(k)), ProfilPemain.XP_PENGHARGAAN], 18, Color(1.0, 0.85, 0.2)))
	var level = _label_hasil("", 22, Color.WHITE)
	kotak.add_child(level)
	var bar = ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(340, 18)
	bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	kotak.add_child(bar)
	var naik = _label_hasil("", 24, Color(1.0, 0.85, 0.2))
	kotak.add_child(naik)
	var selesai: Array = r.get("misi_selesai", [])
	for t in selesai:
		kotak.add_child(_label_hasil("Mission done: " + str(t), 18, Color(0.5, 1.0, 0.5)))
	if not selesai.is_empty():
		kotak.add_child(_label_hasil("Claim it in MISSIONS.", 16, Color(0.75, 0.75, 0.8)))
	var segarkan = func():
		dapat.text = "+%d XP   +%d CROWNS" % [int(r["xp"]), int(r["crowns"])] + ("   (DOUBLED)" if r.get("digandakan", false) else "")
		var info = ProfilPemain.info_level()
		level.text = "Lv %d   %d / %d XP" % [info["level"], info["xp_dalam_level"], info["xp_naik"]]
		bar.max_value = info["xp_naik"]
		bar.value = info["xp_dalam_level"]
		naik.visible = int(r["level_baru"]) > int(r["level_lama"])
		naik.text = "LEVEL UP! Lv %d   +%d CROWNS" % [int(r["level_baru"]), int(r["crowns_level"])]
	segarkan.call()
	# Iklan berhadiah PILIHAN pemain (solo & multiplayer -- pertandingan sudah selesai).
	if int(r.get("xp", 0)) > 0 and not r.get("digandakan", false) and PengelolaIklan.rewarded_tersedia():
		var btn = Button.new()
		btn.text = "WATCH AD: DOUBLE REWARDS"
		btn.custom_minimum_size = Vector2(350, 60)
		btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		btn.add_theme_font_size_override("font_size", 20)
		_gaya_tombol(btn, Color(0.75, 0.55, 0.1))
		btn.pressed.connect(func():
			btn.disabled = true
			var berhasil = await PengelolaIklan.tonton_rewarded()
			if not is_instance_valid(kotak):
				return
			if berhasil:
				ProfilPemain.gandakan_hadiah(r)
				segarkan.call()
				btn.hide()
			else:
				btn.text = "No ad right now."
		)
		kotak.add_child(btn)
	return kotak
```
Tinggi: 4 pemain + 4 baris penghargaan + tombol EXIT harus muat di 720 px (cek foto T8). Kalau terpotong:
turunkan `separation` `vbox` 14 -> 10 dan font baris detail 20 -> 18, jangan mengubah hal lain.

## 6. Bagian D: main menu (`main_menu.gd`)

### D1. Variabel baru (sesudah `var suara_boom`)
```gdscript
# --- PROFIL, MISI & HADIAH LOGIN (Fase 2) ---
var tombol_profil: Button
var label_level: Label
var label_nama: Label
var bar_xp: ProgressBar
var label_crowns: Label
var tombol_misi: Button
var _panel_terbuka: Control = null
```

### D2. Akhir `_ready()` (sesudah panel multiplayer; DITAMBAH PALING AKHIR supaya di atas judul)
```gdscript
	# 5. Fase 2: kepala profil (kiri atas), MISSIONS (kanan atas), hadiah login harian.
	_buat_kepala_profil()
	_buat_tombol_misi()
	ProfilPemain.profil_berubah.connect(_segarkan_kepala_profil)
	var otomatis = ProfilPemain.pastikan_misi_hari_ini()
	_segarkan_kepala_profil()
	if not otomatis.is_empty():
		_spanduk_menu("MISSION REWARDS  +%d CROWNS" % int(otomatis["crowns"]))
	_cek_hadiah_login.call_deferred()
```

### D3. Fungsi baru (taruh sesudah `_proses_tombol_peta`)
```gdscript
# ========================================================
# FASE 2: PROFIL, MISI HARIAN & HADIAH LOGIN
# ========================================================
func _label_kepala(ukuran: int, warna: Color) -> Label:
	var l = Label.new()
	l.add_theme_font_size_override("font_size", ukuran)
	l.add_theme_color_override("font_color", warna)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 5)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

func _buat_kepala_profil() -> void:
	# Kiri atas: [Lv 3 | nama + bar XP | CROWNS]. Ketuk -> panel PROFILE.
	tombol_profil = Button.new()
	tombol_profil.position = Vector2(16, 16)
	tombol_profil.custom_minimum_size = Vector2(440, 76)
	var g = StyleBoxFlat.new()
	g.bg_color = Color(0.05, 0.05, 0.1, 0.85)
	g.set_corner_radius_all(12)
	g.set_border_width_all(2)
	g.border_color = Color(1.0, 0.85, 0.2)
	var gh = g.duplicate()
	gh.bg_color = Color(0.12, 0.12, 0.2, 0.9)
	tombol_profil.add_theme_stylebox_override("normal", g)
	tombol_profil.add_theme_stylebox_override("hover", gh)
	tombol_profil.add_theme_stylebox_override("pressed", g)
	tombol_profil.pressed.connect(_buka_profil)
	add_child(tombol_profil)
	var baris = HBoxContainer.new()
	baris.set_anchors_preset(Control.PRESET_FULL_RECT)
	baris.offset_left = 14
	baris.offset_right = -14
	baris.add_theme_constant_override("separation", 14)
	baris.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tombol_profil.add_child(baris)
	label_level = _label_kepala(30, Color(1.0, 0.85, 0.2))
	baris.add_child(label_level)
	var tengah = VBoxContainer.new()
	tengah.alignment = BoxContainer.ALIGNMENT_CENTER
	tengah.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tengah.mouse_filter = Control.MOUSE_FILTER_IGNORE
	baris.add_child(tengah)
	label_nama = _label_kepala(20, Color.WHITE)
	tengah.add_child(label_nama)
	bar_xp = ProgressBar.new()
	bar_xp.show_percentage = false
	bar_xp.custom_minimum_size = Vector2(0, 12)
	bar_xp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tengah.add_child(bar_xp)
	label_crowns = _label_kepala(18, Color(1.0, 0.85, 0.2))
	label_crowns.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	baris.add_child(label_crowns)

func _buat_tombol_misi() -> void:
	tombol_misi = _buat_tombol_menu("MISSIONS", Color(0.55, 0.35, 0.1))
	tombol_misi.custom_minimum_size = Vector2(240, 60)
	tombol_misi.add_theme_font_size_override("font_size", 22)
	tombol_misi.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	tombol_misi.offset_left = -256
	tombol_misi.offset_right = -16
	tombol_misi.offset_top = 16
	tombol_misi.offset_bottom = 76
	tombol_misi.pressed.connect(_buka_misi)
	add_child(tombol_misi)

func _segarkan_kepala_profil() -> void:
	if label_level == null:
		return
	var info = ProfilPemain.info_level()
	label_level.text = "Lv %d" % info["level"]
	label_nama.text = ProfilPemain.nama
	bar_xp.max_value = info["xp_naik"]
	bar_xp.value = info["xp_dalam_level"]
	label_crowns.text = "CROWNS\n%d" % ProfilPemain.crowns
	var n = ProfilPemain.jumlah_misi_bisa_diklaim()
	tombol_misi.text = ("MISSIONS (%d)" % n) if n > 0 else "MISSIONS"

func _spanduk_menu(teks: String) -> void:
	# Tulisan besar sebentar di tengah menu (naik level, hadiah otomatis).
	var l = _label_kepala(40, Color(1.0, 0.85, 0.2))
	l.text = teks
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.set_anchors_preset(Control.PRESET_CENTER)
	l.grow_horizontal = Control.GROW_DIRECTION_BOTH
	l.grow_vertical = Control.GROW_DIRECTION_BOTH
	l.modulate.a = 0.0
	add_child(l)
	var tw = l.create_tween()
	tw.tween_property(l, "modulate:a", 1.0, 0.25)
	tw.tween_interval(1.5)
	tw.tween_property(l, "modulate:a", 0.0, 0.4)
	tw.tween_callback(l.queue_free)

func _buka_panel(judul_panel: String) -> VBoxContainer:
	# Panel di atas menu: latar gelap (menahan ketukan) + isi di tengah.
	_tutup_panel()
	var lapis = Control.new()
	lapis.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(lapis)
	_panel_terbuka = lapis
	var gelap = ColorRect.new()
	gelap.color = Color(0, 0, 0, 0.85)
	gelap.set_anchors_preset(Control.PRESET_FULL_RECT)
	lapis.add_child(gelap)
	var isi = VBoxContainer.new()
	isi.set_anchors_preset(Control.PRESET_CENTER)
	isi.grow_horizontal = Control.GROW_DIRECTION_BOTH
	isi.grow_vertical = Control.GROW_DIRECTION_BOTH
	isi.add_theme_constant_override("separation", 14)
	lapis.add_child(isi)
	var l = _label_kepala(38, Color(1.0, 0.85, 0.2))
	l.text = judul_panel
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	isi.add_child(l)
	return isi

func _tutup_panel() -> void:
	if is_instance_valid(_panel_terbuka):
		_panel_terbuka.queue_free()
	_panel_terbuka = null

func _tombol_tutup_panel(isi: VBoxContainer) -> void:
	var btn = _buat_tombol_menu("CLOSE", Color(0.6, 0.2, 0.2))
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.pressed.connect(_tutup_panel)
	isi.add_child(btn)

# --- DAILY REWARD (login 7 hari) ---
func _cek_hadiah_login() -> void:
	if ProfilPemain.login_bisa_diklaim() and not _sudah_mulai:
		_buka_hadiah_login()

func _buka_hadiah_login() -> void:
	var isi = _buka_panel("DAILY REWARD")
	var baris = HBoxContainer.new()
	baris.alignment = BoxContainer.ALIGNMENT_CENTER
	baris.add_theme_constant_override("separation", 10)
	isi.add_child(baris)
	var hari_ini = ProfilPemain.hari_login
	for h in range(1, 8):
		var kotak = PanelContainer.new()
		kotak.custom_minimum_size = Vector2(92, 92)
		var g = StyleBoxFlat.new()
		g.set_corner_radius_all(10)
		g.bg_color = Color(0.2, 0.2, 0.25) if h < hari_ini else Color(0.1, 0.1, 0.18)
		if h == hari_ini:
			g.set_border_width_all(3)
			g.border_color = Color(1.0, 0.85, 0.2)
		kotak.add_theme_stylebox_override("panel", g)
		var l = _label_kepala(18, Color(1, 1, 1, 0.45) if h < hari_ini else Color.WHITE)
		l.text = "Day %d\n%d" % [h, ProfilPemain.HADIAH_LOGIN[h - 1]]
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		kotak.add_child(l)
		baris.add_child(kotak)
	var ket = _label_kepala(18, Color(0.75, 0.75, 0.8))
	ket.text = "Crowns will unlock items soon."
	ket.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	isi.add_child(ket)
	var btn = _buat_tombol_menu("CLAIM +%d CROWNS" % ProfilPemain.HADIAH_LOGIN[hari_ini - 1], Color(0.75, 0.55, 0.1))
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.pressed.connect(func():
		ProfilPemain.klaim_login()
		_tutup_panel()
	)
	isi.add_child(btn)

# --- DAILY MISSIONS ---
func _buka_misi() -> void:
	sfx_player.stream = suara_hover
	sfx_player.pitch_scale = 1.2
	sfx_player.play()
	ProfilPemain.pastikan_misi_hari_ini()
	var isi = _buka_panel("DAILY MISSIONS")
	var sisa = ProfilPemain.detik_sampai_besok()
	var ket = _label_kepala(18, Color(0.75, 0.75, 0.8))
	ket.text = "New missions in %dh %dm" % [floori(sisa / 3600.0), floori(posmod(sisa, 3600) / 60.0)]
	ket.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	isi.add_child(ket)
	for i in range(ProfilPemain.misi.size()):
		var m: Dictionary = ProfilPemain.misi[i]
		var baris = HBoxContainer.new()
		baris.alignment = BoxContainer.ALIGNMENT_CENTER
		baris.add_theme_constant_override("separation", 12)
		isi.add_child(baris)
		var teks = _label_kepala(22, Color.WHITE)
		teks.text = ProfilPemain.teks_misi(m)
		teks.custom_minimum_size = Vector2(390, 52)
		baris.add_child(teks)
		var progres = _label_kepala(22, Color.WHITE)
		progres.text = "%d/%d" % [int(m.get("progres", 0)), ProfilPemain.target_misi(m)]
		progres.custom_minimum_size = Vector2(60, 52)
		baris.add_child(progres)
		var hd = ProfilPemain.hadiah_misi(m)
		var hadiah = _label_kepala(18, Color(1.0, 0.85, 0.2))
		hadiah.text = "+%d CROWNS\n+%d XP" % [hd["crowns"], hd["xp"]]
		hadiah.custom_minimum_size = Vector2(130, 52)
		baris.add_child(hadiah)
		var klaim = _buat_tombol_menu("CLAIM", Color(0.2, 0.6, 0.3))
		klaim.custom_minimum_size = Vector2(140, 52)
		klaim.add_theme_font_size_override("font_size", 20)
		if m.get("diklaim", false):
			klaim.text = "DONE"
			klaim.disabled = true
		elif not ProfilPemain.misi_selesai(m):
			klaim.disabled = true
		klaim.pressed.connect(func():
			var h = ProfilPemain.klaim_misi(i)
			_buka_misi()
			if not h.is_empty() and int(h["level_baru"]) > int(h["level_lama"]):
				_spanduk_menu("LEVEL UP! Lv %d" % int(h["level_baru"]))
		)
		baris.add_child(klaim)
		if ProfilPemain.bisa_ganti_misi(i):
			var ganti = _buat_tombol_menu("CHANGE", Color(0.35, 0.35, 0.6))
			ganti.custom_minimum_size = Vector2(140, 52)
			ganti.add_theme_font_size_override("font_size", 20)
			ganti.pressed.connect(func():
				ProfilPemain.ganti_misi(i)
				_buka_misi()
			)
			baris.add_child(ganti)
	if not ProfilPemain.ganti_misi_dipakai:
		var ket_ganti = _label_kepala(16, Color(0.75, 0.75, 0.8))
		ket_ganti.text = "You can change 1 mission per day."
		ket_ganti.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		isi.add_child(ket_ganti)
	_tombol_tutup_panel(isi)

# --- PROFILE ---
func _buka_profil() -> void:
	sfx_player.stream = suara_hover
	sfx_player.pitch_scale = 1.2
	sfx_player.play()
	var isi = _buka_panel("PROFILE")
	var baris_nama = HBoxContainer.new()
	baris_nama.alignment = BoxContainer.ALIGNMENT_CENTER
	baris_nama.add_theme_constant_override("separation", 14)
	isi.add_child(baris_nama)
	var nama_profil = _label_kepala(30, Color.WHITE)
	nama_profil.text = ProfilPemain.nama
	baris_nama.add_child(nama_profil)
	var btn_edit = _buat_tombol_menu("EDIT NAME", Color(0.35, 0.35, 0.6))
	btn_edit.custom_minimum_size = Vector2(200, 52)
	btn_edit.add_theme_font_size_override("font_size", 20)
	baris_nama.add_child(btn_edit)
	var baris_edit = HBoxContainer.new()
	baris_edit.alignment = BoxContainer.ALIGNMENT_CENTER
	baris_edit.add_theme_constant_override("separation", 12)
	baris_edit.hide()
	isi.add_child(baris_edit)
	var kolom_nama = LineEdit.new()
	kolom_nama.max_length = 12
	kolom_nama.placeholder_text = "New name"
	kolom_nama.custom_minimum_size = Vector2(280, 52)
	kolom_nama.add_theme_font_size_override("font_size", 24)
	baris_edit.add_child(kolom_nama)
	var btn_simpan = _buat_tombol_menu("SAVE", Color(0.2, 0.6, 0.3))
	btn_simpan.custom_minimum_size = Vector2(140, 52)
	btn_simpan.add_theme_font_size_override("font_size", 20)
	baris_edit.add_child(btn_simpan)
	var salah = _label_kepala(18, Color(1.0, 0.45, 0.45))
	salah.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	salah.hide()
	isi.add_child(salah)
	btn_edit.pressed.connect(func():
		kolom_nama.text = ProfilPemain.nama
		baris_edit.show()
		kolom_nama.grab_focus() # keyboard HP muncul
	)
	btn_simpan.pressed.connect(func():
		var pesan = ProfilPemain.ganti_nama(kolom_nama.text)
		if pesan != "":
			salah.text = pesan
			salah.show()
			return
		nama_profil.text = ProfilPemain.nama
		baris_edit.hide()
		salah.hide()
	)
	var info = ProfilPemain.info_level()
	var level_profil = _label_kepala(24, Color(1.0, 0.85, 0.2))
	level_profil.text = "Lv %d   %d / %d XP" % [info["level"], info["xp_dalam_level"], info["xp_naik"]]
	level_profil.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	isi.add_child(level_profil)
	var bar = ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(380, 18)
	bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	bar.max_value = info["xp_naik"]
	bar.value = info["xp_dalam_level"]
	isi.add_child(bar)
	var s = ProfilPemain.statistik
	for teks in ["CROWNS %d" % ProfilPemain.crowns,
			"Matches %d   Wins %d" % [int(s.get("match_main", 0)), int(s.get("match_menang", 0))],
			"Duels won %d   Trap hits %d" % [int(s.get("duel_menang", 0)), int(s.get("jebakan_kena", 0))],
			"Tiles bought %d   Towers built %d" % [int(s.get("petak_beli", 0)), int(s.get("menara", 0))],
			"Awards %d" % int(s.get("penghargaan", 0))]:
		var l = _label_kepala(22, Color.WHITE)
		l.text = teks
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		isi.add_child(l)
	var ket = _label_kepala(16, Color(0.75, 0.75, 0.8))
	ket.text = "Crowns will unlock items soon."
	ket.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	isi.add_child(ket)
	_tombol_tutup_panel(isi)
```
Catatan: pembagian bilangan bulat ditulis dengan `/ 3600.0` + `floori` (hindari peringatan INTEGER_DIVISION).
Tidak ada `_process` baru (FPS).

## 7. Bagian E: ringkasan sinkron & migrasi
- Host/solo menghitung statistik; client memegang salinan dari siaran state (dipakai kalau jadi host baru
  atau PLAY ALONE VS AI -- setelah itu `_catat_stat` di device itu aktif karena perannya bukan "client").
- Akhir: host menyusun papan (+stat +penghargaan) -> `rpc_permainan_selesai` -> tiap HP memanggil
  `ProfilPemain.catat_match` untuk `slot_lokal` sendiri. Kiriman ulang setelah migrasi aman (penjaga
  `_hadiah_profil_diberikan`).
- Tidak ada RPC baru, tidak ada tanda tangan RPC yang berubah. Semua HP tetap wajib versi yang sama.

## 8. Uji (rig)

Siapkan: `profil_pemain.gd` + autoload `ProfilPemain` di project.godot SEMUA proyek rig (proj, proj_tanpa_uji,
proj_mock_editor, cek_warn). Tambahkan `profil_pemain.gd` ke daftar file di `sinkron_uji.sh` dan
`sinkron_tanpa_uji.sh`. Proses uji paralel/multiplayer memakai `env HOME=<folder sendiri>` supaya berkas
profil tidak ditulis bersamaan.

| Uji | Isi | Lolos kalau |
|---|---|---|
| T0 | salin kode sekarang ke `proj_sebelum_fase2` (+ `_tanpa_uji`) | pembanding siap |
| T1 | 36 sim Classic UJI nyala + 36 UJI mati + 36 sim Quick (jejak dari T0) | jejak IDENTIK dengan T0 |
| T2 | invarian statistik di sim (baris AKHIR ditambah statistik per slot) | Quick yang berakhir karena ronde: `giliran` tiap slot = batas ronde; jumlah `giliran` semua slot = hitungan giliran robot (selisih <= 1); total `duel_menang` = total `duel_kalah`; `dadu_kali` <= `giliran` per slot |
| T3 | `uji_profil.gd` (sudah ada di scratchpad Opus, 39 cek) di proyek dengan profil_pemain.gd produksi | 39/39 |
| T4 | penghargaan dari papan buatan: nilai, seri, minimal (0 duel = tanpa DUEL KING; < 3 lemparan = tanpa LUCKY ROLLER), AI boleh dapat | semua cocok |
| T5 | multiplayer: 27 skenario regresi (M1-M8, A0-A6, S1-S3, D1-D4, B0-B4) + Quick Q1-Q8, Q1n, Q4n | SELESAI normal, scripterr 0, beda 0; baris AKHIR (papan kini berisi stat & penghargaan) IDENTIK di semua HP, termasuk skenario migrasi |
| T6 | adegan asli solo (uji_nyata): profil baru -> 1 pertandingan | `_ringkasan_profil.xp` = rumus dari baris papan; berkas profil: xp_total, crowns, `match_main` = 1; misi maju; kolom REWARDS tampil |
| T7 | proj_mock_editor (iklan tiruan + klik sungguhan di layar maya 1280x720): DOUBLE REWARDS; EXIT di pertandingan ke-2 | Double sekali (XP & Crowns x2, tombol hilang); iklan gagal -> "No ad right now."; EXIT: interstisial tampil lalu main menu; sesudah Double interstisial terlewat (jeda 3 menit); pertandingan pertama tanpa interstisial |
| T8 | foto 1280x720 & 1600x720: menu + kepala profil + MISSIONS, DAILY REWARD, MISSIONS (CLAIM/DONE/CHANGE), PROFILE (+ edit nama + pesan salah), papan 2 & 4 pemain + REWARDS + LEVEL UP + penghargaan + Double | rapi, tidak terpotong, tidak menumpuk judul TILE DUEL |
| T9 | `cek_peringatan.sh` (debugger aktif) | 0 peringatan di file produksi |
| T10 | menu dibuka ulang 5x, klaim login/misi, ganti nama, lalu adegan dimuat ulang | angka sama setelah dimuat ulang; tidak ada SCRIPT ERROR |

## 9. Pengiriman & langkah user
Set lengkap 15 file dalam SATU pesan (minta unduhan lama dibuang): 14 file Fase 1 + `profil_pemain.gd`, plus
RENCANA ini dengan bagian STATUS. Yang berubah: pemain.gd, ai_musuh.gd, ui_dinamis.gd, main_menu.gd,
profil_pemain.gd (baru).

**Langkah user sebelum menjalankan:** Project > Project Settings > Globals > Autoload: tambah
`res://profil_pemain.gd` dengan nama `ProfilPemain` (centang Enable). Tanpa ini Godot berhenti dengan error
"ProfilPemain not declared".

Uji di HP (build debug, iklan uji Google):
1. Buka pertama kali: DAILY REWARD Day 1 (+20). Kepala profil kiri atas: Lv 1, Player####, CROWNS 20.
2. Main 1 pertandingan sampai selesai: kolom REWARDS (XP, Crowns, bar level), penghargaan kalau dapat.
3. WATCH AD: DOUBLE REWARDS -> angka jadi x2 dan tombol hilang.
4. EXIT: pertandingan ke-2 dan seterusnya ada interstisial, kecuali baru saja menonton Double.
5. MISSIONS: progres bertambah, CLAIM memberi Crowns/XP, CHANGE hanya sekali per hari.
6. PROFILE: EDIT NAME (keyboard HP muncul), nama kasar ditolak, nama baru tampil di kiri atas.
7. Tutup aplikasi sepenuhnya, buka lagi: Level, XP, Crowns, misi tetap.
8. Majukan tanggal HP 1 hari: DAILY REWARD Day 2, misi baru, CHANGE tersedia lagi.
9. Multiplayer 2 HP: keduanya mendapat hadiah masing-masing; penghargaan sama di kedua HP.

## 10. Di luar Fase 2
- Nama & level tampil di HP teman / lobby, Respect, MVP -> Fase 6. Toko & kerajaan Crowns -> Fase 7-8.
- XP Tebak Duel, event papan -> Fase 5. XP Role & slot jebakan per level -> Fase 4. Mastery elemen -> Fase 8.
- AI memasang jebakan -> Fase 4 (AI ber-role). Sinkron profil online / anti-curang -> belum direncanakan.

## Model
Rencana ini: Opus. Kode & uji dari rencana ini: **Sonnet** (bagian A tinggal disalin; bagian lain berupa
tabel titik kait + potongan kode). Pindah ke **Opus** kalau: statistik/penghargaan berbeda antar-HP (T5),
hadiah tercatat dua kali, jejak T1 tidak identik tanpa sebab jelas, atau ada masalah migrasi host.
