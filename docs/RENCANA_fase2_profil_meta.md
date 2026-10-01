# RENCANA FASE 2: Profil & meta dasar

Disusun Opus (24-09) setelah membaca pemain.gd (giliran, dadu, langkah & jebakan, duel, beli/bangun,
kartu, akhir permainan, siaran state, migrasi), ui_dinamis.gd (HOW TO WIN, papan peringkat, akhir
permainan), ui_elemen.gd (hasil duel), ai_musuh.gd, main_menu.gd, pengelola_iklan.gd, dan dokumen desain.
Semua keputusan K1-K7 DISETUJUI user 24-09 ("oke semua").

MULAI MENULIS KODE SETELAH uji HP Fase 1 (A7 di RENCANA_fase1) lolos: Fase 2 mengubah alur akhir
pertandingan & iklan yang sama. Kalau A7 menemukan masalah, perbaiki dulu di Fase 1.

ATURAN USER: edit hanya baris/bagian yang relevan (jangan tulis ulang file); balas dalam Bahasa Indonesia;
teks untuk pemain = bahasa Inggris SEDERHANA; setelah lolos uji kirim SET LENGKAP terbaru sekaligus dalam
SATU pesan dan minta unduhan lama dibuang. File produksi: UJI_DUEL, UJI_SERI, UJI_SELALU_PEDANG WAJIB
tetap false. Rig: /tmp/claude-0/-home-claude/bc2a37a6-77d5-5593-942f-124ebd210f19/scratchpad/proj (lihat
sinkron_uji.sh & sinkron_tanpa_uji.sh). Warning GDScript wajib 0: cek dengan cek_peringatan.sh (warning
hanya tercetak kalau debugger aktif -- pelajaran dari Fase 1).

## 0. Isi Fase 2 (dokumen desain, tabel Tahapan)

File baru `profil_pemain.gd` (autoload): nama, Level Pemain, XP, Crowns, statistik seumur main.
Layar hasil + penghargaan akhir. 3 misi harian + hadiah login 7 hari. Iklan berhadiah Double XP/Crowns.
Syarat lolos: XP/Crowns tetap ada setelah aplikasi ditutup; regresi rig lolos.
Fase 2 TIDAK mengubah jalannya permainan: jejak simulasi Classic DAN Quick harus identik dengan sebelum
Fase 2 (uji T1). Satu-satunya perubahan perilaku: bug ketuk ganda Buy/Build (B5) ditutup.

## 1. Keputusan (DISETUJUI user 24-09)

K1. Mata uang meta: **Crowns**.
K2. Nama pemain diketik bebas: 3-12 karakter (huruf, angka, spasi), filter kata kasar sederhana (Inggris +
    Indonesia). Tidak ada layar wajib di awal: nama otomatis "Player" + 4 angka acak, bisa diganti kapan saja
    di layar PROFILE. Di Fase 2 nama hanya tampil di HP sendiri (tampil di HP teman = Fase 6).
K3. Level: naik dari Lv L ke L+1 butuh 100 + 25 x (L-1) XP. Tanpa batas level. Naik level memberi
    10 x (level baru) Crowns. Fase 4 memakai level ini untuk jumlah jenis jebakan yang boleh dibawa.
K4. Crowns didapat dari pertandingan, penghargaan, misi, login, naik level. BELUM bisa dibelanjakan
    sampai toko/kerajaan (Fase 7-8); layar PROFILE menulis "Crowns will unlock items soon."
K5. Akhir pertandingan: animasi menang/kalah -> papan peringkat + kartu hadiah (XP, Crowns, penghargaan,
    misi, naik level) dengan tombol WATCH AD: DOUBLE REWARDS -> interstisial PINDAH ke saat pemain menekan
    EXIT TO MAIN MENU. Kalau baru menonton Double, interstisial otomatis terlewat oleh jeda 3 menit yang
    sudah ada (iklan berhadiah ikut dihitung). Double juga ditawarkan di multiplayer (pertandingan sudah
    selesai).
K6. Penghargaan akhir untuk semua slot (AI juga, tampil di layar); XP/Crowns hanya untuk pemain manusia di
    HP-nya sendiri; tidak mengubah pemenang. Tiap penghargaan +15 XP & +10 Crowns. Seri: semua yang seri
    dapat.
    PENYESUAIAN (ditemukan saat membaca kode, perlu diberitahukan ke user): Trap Master dihitung dari
    JUMLAH lawan yang kena jebakannya, bukan koin -- jebakan Air (dilempar) dan Petir (lumpuh) tidak
    mengambil koin sama sekali, jadi ukuran koin selalu mengalahkan pemakai kedua jebakan itu. Koin yang
    hilang karena jebakannya dipakai sebagai penentu kalau jumlahnya seri.
K7. 3 misi per hari (1 mudah, 1 sedang, 1 sulit) dari 12 jenis, semuanya bisa selesai di solo; 1x ganti
    misi gratis per hari; ganti hari = tengah malam jam HP. Login 7 hari: hari yang terlewat TIDAK mengulang
    ke Hari 1; Hari 7 hadiah terbesar, lalu kembali ke Hari 1.

Keputusan teknis Opus (tidak perlu persetujuan): di multiplayer tiap HP hanya mencatat pemainnya sendiri;
slot yang diambil alih AI tidak dapat apa-apa (HP-nya sudah keluar); penghargaan dihitung host dan ikut
data akhir ke semua HP (tetap benar setelah migrasi host); file profil punya cadangan & ditulis lewat file
sementara; hanya pertandingan TUNTAS (ada layar akhir) yang dihitung.

## 2. Angka (semua konstanta di profil_pemain.gd, mudah disetel)

### 2a. XP & Crowns per pertandingan
```
giliran  = jumlah giliran SENDIRI (statistik "giliran" slot lokal)
pengali  = 1.0 (Quick) atau 1.6 (Classic)
menang   = 1.5 kalau menang, 1.0 kalau kalah
xp_match     = roundi(5 * giliran * pengali * menang)
crowns_match = roundi(2 * giliran * pengali * menang)
penghargaan  = +15 XP & +10 Crowns per penghargaan milik slot lokal
```
Contoh: Quick 2 pemain (8 giliran) menang = 60 XP / 24 Crowns, kalah = 40 / 16. Quick 4 pemain (5 giliran)
menang = 38 / 15. Classic 12 giliran menang = 144 XP / 58 Crowns.

### 2b. Level (K3)
| Level | XP total untuk mencapainya |
|---|---|
| 2 | 100 |
| 3 | 225 |
| 4 | 375 |
| 5 | 550 |
| 10 | 1800 |
| 20 | 6175 |
Lv 2 kira-kira 2 pertandingan Quick. Naik ke Lv N memberi 10 x N Crowns (naik 2 level sekaligus = dua
hadiah).

### 2c. Penghargaan akhir (K6) -- dihitung dari baris papan skor di host/solo
| id | Teks | Syarat (maks di antara SEMUA slot) | Minimal |
|---|---|---|---|
| duel_king | DUEL KING | duel_menang terbanyak | 1 |
| trap_master | TRAP MASTER | jebakan_kena terbanyak; seri -> koin_jebakan terbanyak | 1 |
| landlord | LANDLORD | petak di akhir terbanyak (kolom "petak" papan skor) | 1 |
| lucky_roller | LUCKY ROLLER | rata-rata dadu tertinggi: `snappedf(float(dadu_total) / float(dadu_kali), 0.01)` | 3 lemparan |
Seri setelah penentu = semua yang seri mendapatkannya. Catatan: AI belum memasang jebakan (ai_musuh.gd),
jadi Trap Master sekarang hanya bisa jatuh ke manusia -- wajar, AI berjebakan menyusul di Fase 4.

### 2d. Misi harian (K7) -- progres dihitung di akhir pertandingan TUNTAS dari statistik slot lokal
| id | Teks untuk pemain | Target | Tingkat | Progres ditambah |
|---|---|---|---|---|
| main_match | Finish 2 matches | 2 | mudah | 1 per pertandingan tuntas |
| pasang_jebakan | Set 3 traps | 3 | mudah | jebakan_pasang |
| beli_petak | Buy 5 tiles | 5 | mudah | petak_beli |
| lewat_start | Pass START 3 times | 3 | mudah | lewat_start |
| menang_match | Win 1 match | 1 | sedang | 1 kalau menang |
| menang_duel | Win 2 duels | 2 | sedang | duel_menang |
| permata | Collect 2 gems | 2 | sedang | permata |
| pakai_kartu | Use 2 cards | 2 | sedang | kartu_pakai |
| penghargaan | Earn 1 award | 1 | sedang | jumlah penghargaan slot lokal |
| duel_elemen | Win a duel with FIRE (elemen diacak saat misi dibuat) | 1 | sulit | menang_elemen[elemen] |
| kena_jebakan | Catch rivals with your traps 2 times | 2 | sulit | jebakan_kena |
| menara_lv2 | Build a Lv 2 tower | 1 | sulit | menara_lv2 |
Hadiah: mudah 20 Crowns + 15 XP, sedang 30 + 25, sulit 45 + 35. Hadiah langsung masuk saat misi selesai
(tanpa tombol klaim) dan disebut di kartu hadiah layar akhir. Nama elemen: konstanta sendiri di
profil_pemain.gd `NAMA_ELEMEN := {"api": "FIRE", "air": "WATER", "tanah": "EARTH", "petir": "LIGHTNING",
"angin": "WIND"}` (ui_elemen.gd tidak punya class_name; memuatnya ikut memuat 5 berkas suara).

### 2e. Login 7 hari (K7)
Hari 1-7: 20, 30, 40, 50, 60, 80, 150 Crowns; Hari 7 juga +50 XP. Satu klaim per tanggal HP. Hari yang
terlewat tidak mengulang (klaim berikutnya = hari selanjutnya). Setelah Hari 7 kembali ke Hari 1.

## 3. Bagian A: profil_pemain.gd (FILE BARU, autoload `ProfilPemain`)

WAJIB:
- TANPA `class_name` (nama kelas yang sama dengan autoload = error "hides an autoload singleton").
- SEMUA fungsi yang dipanggil lewat `ProfilPemain.xxx()` adalah fungsi INSTANCE, BUKAN `static`
  (static yang dipanggil lewat autoload = warning STATIC_CALLED_ON_INSTANCE -- persis bug Fase 1).
- Pengacak sendiri `var _rng := RandomNumberGenerator.new()` + `_rng.randomize()` di `_ready`, dan HANYA
  metode `_rng` yang dipakai (`_rng.randi_range`, dst). DILARANG di file baru: `randi()`/`randf()`/
  `randi_range()` global, `Array.pick_random()`, `Array.shuffle()` (semuanya memakai pengacak GLOBAL yang
  juga dipakai permainan -- mis. ui_elemen.gd pemilihan elemen AI, petak_kartu.gd) dan `mesin_acak`
  pemain.gd. Jejak uji T1 harus tetap identik; lingkungan_pantai.gd juga mengunci benih global.
- Tidak boleh ada variabel lokal yang namanya sama dengan variabel anggota atau fungsi (warning
  SHADOWED_VARIABLE / "shadowing an already-declared function"). Rata-rata dadu: `float(a) / float(b)`
  (int / int = warning INTEGER_DIVISION).
- Draf dari percobaan sebelumnya ada di scratchpad `fase2/profil_pemain.gd` + `proj_profil/uji_profil.gd`
  (dibuat 24-09 20:27, sebelum rencana ini). Boleh dipakai sebagai bahan (mis. daftar kata kasar,
  struktur simpan/muat), tapi ISI & ANGKA WAJIB mengikuti rencana ini. Bedanya dengan rencana: daftar &
  target misi (2d), hadiah misi sulit (2d: 45/35), misi dengan tombol klaim (rencana: hadiah langsung masuk),
  nama berkas cadangan (A2), `_geser_hari` (rencana: `_tanggal_uji`).
- User memasang autoload: Project Settings -> Autoload -> `res://profil_pemain.gd`, nama `ProfilPemain`,
  setelah StatusJaringan (tulis langkah ini di pesan pengiriman). Rig: tambahkan baris yang sama ke
  project.godot proj/proj_tanpa_uji.

### A1. Data (variabel anggota; dibaca UI langsung, mis. `ProfilPemain.crowns`; DIUBAH hanya lewat fungsi)
```
var id := ""            # 16 hex acak, untuk Fase 6 (kartu profil/Respect); tidak ada data pribadi
var nama := ""          # "Player4821"
var xp_total := 0
var crowns := 0
var statistik := {}     # "match","menang","match_quick","match_classic","duel_menang","jebakan_pasang",
                        # "jebakan_kena","petak_beli","menara_lv2","permata","kartu_pakai","penghargaan","double"
var misi: Array = []    # 3 x {"id","teks","target","progres","tingkat","crowns","xp","selesai":bool,"elemen":""}
var tanggal_misi := ""
var ganti_misi_dipakai := false
var hari_login := 1         # hari yang akan diklaim berikutnya, 1..7
var tanggal_login := ""     # tanggal klaim terakhir ("" = belum pernah)
var _double_terpakai := false  # Double untuk pertandingan TERAKHIR sudah dipakai (di-reset catat_akhir_match)
```
ConfigFile: bagian "profil" (versi, id, nama, xp, crowns), "statistik", "misi", "login".

### A2. Simpan & muat (aman dari HP mati saat menyimpan)
```
const BERKAS := "user://profil.cfg"
const BERKAS_CADANGAN := "user://profil.cfg.bak"
const BERKAS_SEMENTARA := "user://profil.cfg.tmp"
simpan(): tulis semua bagian ke ConfigFile -> save(BERKAS_SEMENTARA); kalau gagal push_warning & berhenti.
          DirAccess "user://": hapus .bak lama, rename profil.cfg -> profil.cfg.bak, rename .tmp -> profil.cfg.
muat():   coba BERKAS; sah = load OK dan punya "profil/id". Tidak sah -> coba BERKAS_CADANGAN. Keduanya
          gagal -> profil baru (nama & id acak) lalu simpan(). Kunci yang belum ada diisi nilai bawaan
          (profil lama tetap terbaca kalau nanti ada kunci baru).
```
Simpan dipanggil setelah: akhir pertandingan, Double, klaim login, ganti misi, ganti nama, profil baru.

### A3. Tanggal (sama dengan PengelolaIklan._hari_ini)
```
var _tanggal_uji := ""   # HANYA uji: memaksa tanggal
func _hari_ini() -> String:
	return _tanggal_uji if _tanggal_uji != "" else Time.get_date_string_from_system()
func segarkan_hari() -> void   # tanggal misi != hari ini -> 3 misi baru (1 per tingkat) + ganti_terpakai=false + simpan
```
Dipanggil di `_ready`, di `main_menu._ready`, dan di awal `catat_akhir_match` (hari bisa berganti saat main).
Batasan (dicatat, tidak ditangani): jam HP bisa dimajukan untuk memanen misi/login -- data lokal, sama
seperti catatan Popularity di dokumen desain.

### A4. API (semua instance)
```
signal profil_berubah                      # bar menu & panel menyegarkan diri
func ganti_nama(baru: String) -> String    # "" = berhasil; selain itu pesan untuk pemain (Inggris)
func info_level(xp: int = -1) -> Dictionary   # {"level", "xp_dalam", "xp_butuh"} dari XP total (-1 = xp_total)
func xp_untuk_naik(level: int) -> int         # 100 + 25 * (level - 1)
func statistik_kosong() -> Dictionary         # dipakai pemain.gd per slot (B1)
func hitung_penghargaan(papan: Array) -> Dictionary   # slot -> Array[String] id penghargaan (2c)
func catat_akhir_match(d: Dictionary) -> Dictionary   # A5
func tambah_double(r: Dictionary) -> bool             # A6 -- mengubah r DI TEMPAT
func daftar_misi() -> Array
func boleh_ganti_misi(indeks: int) -> bool     # belum dipakai hari ini & misi itu belum selesai
func ganti_misi(indeks: int) -> bool           # ganti dengan misi lain SETINGKAT yang belum ada di daftar
func login_bisa_diklaim() -> bool
func hari_login() -> int                       # 1-7, hari yang akan diklaim
func klaim_login() -> Dictionary               # {"hari","crowns","xp","naik_level":[...]}
```
Nama (K2): `strip_edges()`, spasi ganda jadi satu, 3-12 karakter, hanya A-Z a-z 0-9 spasi -> kalau tidak:
"Use 3-12 letters or numbers." Filter: huruf kecil, buang spasi, ganti 0->o 1->i 3->e 4->a 5->s 7->t
@->a $->s; kata >= 4 huruf dicari sebagai BAGIAN nama, kata pendek (<= 3 huruf, mis. "asu", "tai") hanya kalau
SAMA dengan satu kata di nama (hindari "Taiga", "Asuka"). Kena -> "Please choose another name." Daftar
KATA_TERLARANG ditulis sebagai konstanta (+-40 kata umum Inggris & Indonesia, termasuk singkatan populer).

### A5. catat_akhir_match(d) -> ringkasan
Masukan dari pemain.gd (C2): `{"menang": bool, "quick": bool, "multiplayer": bool, "stat": Dictionary,
"penghargaan": Array}`. Langkah:
1. `segarkan_hari()`; `_double_terpakai = false`.
2. xp_match & crowns_match (2a), xp/crowns penghargaan (2c).
3. Statistik seumur main ditambah (match, menang, match_quick/classic, duel_menang, jebakan_pasang,
   jebakan_kena, petak_beli, menara_lv2, permata, kartu_pakai, penghargaan).
4. Progres misi (2d); misi yang baru selesai -> "selesai": true, hadiahnya ditambahkan.
5. XP & Crowns masuk; naik level dihitung (hadiah 10 x level baru per level).
6. simpan(); emit profil_berubah.
Kembalian (dipakai kartu hadiah, C3):
```
{"xp_match", "crowns_match", "xp_penghargaan", "crowns_penghargaan", "penghargaan": [id...],
 "misi_selesai": [{"teks","xp","crowns"}...], "level_awal", "level_akhir", "crowns_naik_level",
 "xp_total_awal", "xp_total", "bisa_double": (xp_match + xp_penghargaan) > 0, "sudah_double": false}
```

### A6. tambah_double(r) -> bool
Mengubah Dictionary `r` DI TEMPAT (Dictionary dioper sebagai referensi) -- JANGAN `r = ...` di dalam lambda
tombol: menugaskan ulang variabel tangkapan lambda = warning "Reassigning lambda capture does not modify the
outer local variable" dan variabel luarnya tidak berubah. Kalau `r["sudah_double"]` atau `_double_terpakai`
-> false. Kalau tidak: tambah LAGI xp_match + xp_penghargaan dan crowns_match + crowns_penghargaan (misi,
login & hadiah naik level TIDAK digandakan; naik level baru karena tambahan XP tetap memberi hadiahnya),
statistik "double" +1, `_double_terpakai = true`, simpan, emit; perbarui r (`sudah_double` = true,
level_akhir, crowns_naik_level, xp_total) -> true. `_double_terpakai` di-reset di awal `catat_akhir_match`,
jadi panel akhir yang (karena bug lain) muncul dua kali tetap hanya bisa menggandakan sekali.

## 4. Bagian B: statistik pertandingan (pemain.gd)

### B1. Data per slot
Var baru di dekat blok QUICK MATCH:
```
# --- FASE 2: statistik pertandingan per slot (untuk XP, penghargaan, misi) ---
# Dihitung di device yang menjalankan logika (solo / host), ikut siaran state ke client,
# ikut baris papan skor di akhir pertandingan.
var statistik_slot: Array = []
var _hadiah_akhir_diproses := false
var _ringkasan_hadiah: Dictionary = {}
```
Isi `statistik_kosong()` (A4):
```
{"giliran": 0, "dadu_total": 0, "dadu_kali": 0, "duel_menang": 0, "duel_kalah": 0,
 "menang_elemen": {"api": 0, "air": 0, "tanah": 0, "petir": 0, "angin": 0}, "petak_rebut": 0,
 "jebakan_pasang": 0, "jebakan_kena": 0, "koin_jebakan": 0, "petak_beli": 0, "menara_bangun": 0,
 "menara_lv2": 0, "permata": 0, "lewat_start": 0, "kartu_pakai": 0}
```
Fungsi baru, dipanggil di `_siapkan_peta_dan_mulai` tepat setelah baris `batas_ronde = ...` (rig: juga
dari `uji_sim.gd _bangun()`, yang membangun papan sendiri tanpa `_siapkan_peta_dan_mulai` -- tanpa itu
`statistik_slot` kosong dan semua hitungan diam-diam hilang di uji sim):
```
func _reset_statistik() -> void:
	statistik_slot = []
	for s in range(jumlah_pemain()):
		statistik_slot.append(ProfilPemain.statistik_kosong())
	if statistik_slot.size() > 0:
		statistik_slot[0]["giliran"] = 1 # giliran pertama P1 tidak lewat ganti_giliran
	_hadiah_akhir_diproses = false
	_ringkasan_hadiah = {}
```
Pembantu (sinkron, tanpa await, tanpa RNG):
```
func _tambah_stat(slot: int, kunci: String, n: int = 1) -> void:
	# Hanya device yang menjalankan logika (solo / host). Client menerima lewat siaran state.
	if StatusJaringan.peran_multiplayer == "client" or slot < 0 or slot >= statistik_slot.size():
		return
	statistik_slot[slot][kunci] = int(statistik_slot[slot].get(kunci, 0)) + n

func _tambah_stat_elemen(slot: int, elemen: String) -> void:
	if StatusJaringan.peran_multiplayer == "client" or slot < 0 or slot >= statistik_slot.size():
		return
	var m: Dictionary = statistik_slot[slot]["menang_elemen"]
	if m.has(elemen):
		m[elemen] = int(m[elemen]) + 1
```

### B2. Titik hitung (semua dijalankan solo/host; client meneruskan aksinya ke host lewat
`_teruskan_aksi_ke_host`, jadi slot client juga terhitung di host)
| Kejadian | Fungsi | Baris tambahan |
|---|---|---|
| giliran baru | `ganti_giliran`, tepat sebelum `giliran_sekarang = _aktor_dari_slot(slot)` (SETELAH blok akhir ronde Quick) | `_tambah_stat(slot, "giliran")` |
| lempar dadu | `lempar_dadu`, setelah blok `if UJI_DUEL` | `_tambah_stat(slot_pelempar, "dadu_total", hasil_dadu)` + `_tambah_stat(slot_pelempar, "dadu_kali")` |
| lewat START | `bergerak_maju`, di awal `if tujuan_node.is_start_point and not gelembung_aktif:` | `_tambah_stat(slot, "lewat_start")` |
| permata baru | `bergerak_maju` (cabang `not koleksi_aktif.has`) dan `_ambil_permata_setelah_paralisis` (cabang yang sama) | `_tambah_stat(slot, "permata")` |
| kena jebakan Air | `bergerak_maju`, di awal blok `cek_jebakan` | `_tambah_stat(cek_jebakan.pemilik, "jebakan_kena")` |
| kena jebakan Angin | blok `cek_angin`, setelah `koin_hilang` dihitung | `jebakan_kena` +1 dan `koin_jebakan` + koin_hilang untuk `cek_angin.pemilik` |
| kena jebakan Api | blok `cek_api`, SEBELUM `sisa_bakar = 3` | `jebakan_kena` +1 dan `koin_jebakan` + 50 x (3 - sisa_bakar lama) untuk `cek_api.pemilik` (korban yang masih terbakar hanya diperpanjang) |
| kena jebakan Petir | blok `cek_petir` | `jebakan_kena` +1 untuk `cek_petir.pemilik` |
| jebakan Tanah aktif | `_mulai_duel`, di dalam `if cek_tanah and cek_tanah.aktif:` | `jebakan_kena` +1 untuk `cek_tanah.pemilik`, HANYA kalau `cek_tanah.pemilik != slot_a` (jebakan tanah bisa dipasang di petak lawan -- penyerangnya sendiri jangan dihitung) |
| pasang jebakan | `_on_tombol_air_pressed`, `_on_tombol_angin_pressed`, `_on_tombol_api_pressed`, `_on_tombol_trap_petir_pressed`, `_on_tombol_trap_tanah_pressed`, setelah `bintang -= 1` | `_tambah_stat(slot_giliran_ui, "jebakan_pasang")` |
| beli petak | `_on_tombol_beli_pressed`, jalur BUKAN konfrontasi, setelah `uang -= harga_tanah` | `_tambah_stat(slot_giliran_ui, "petak_beli")` |
| bangun menara | `_on_tombol_bangun_pressed`: Lv1 -> `menara_bangun`; Lv2 -> `menara_bangun` + `menara_lv2` (tepat setelah `level_menara_petak[...] = 1/2`, SEBELUM `await ...mainkan_efek_bangun`) | |
| pakai kartu simpanan | `_eksekusi_kartu_simpan`, setelah `var slot = ...` | `_tambah_stat(slot, "kartu_pakai")` |
| pakai pedang | `_mulai_duel`, setelah `poin_bonus_pedang` ditentukan: `if poin_bonus_pedang > 0:` | `_tambah_stat(slot_a, "kartu_pakai")` |
| hasil duel | `eksekusi_dadu_pertarungan`, di awal | pemenang `duel_menang`, yang kalah `duel_kalah`, `_tambah_stat_elemen(pemenang, hasil_duel.get("elemen_pemenang", ""))`, kalau pemenang = penyerang juga `petak_rebut` |
AI membeli/membangun langsung di ai_musuh.gd (tidak lewat tombol): TIDAK ditambah -- statistik beli/bangun
hanya dipakai misi manusia; penghargaan memakai dadu, duel, jebakan, dan petak AKHIR (semuanya lewat jalur
bersama di atas). ai_musuh.gd tidak disentuh.

`_jalankan_duel` mengembalikan elemen pemenang. Setelah `var sisi_m = ...`:
```
	# Fase 2: elemen yang dipakai tiap sisi (ui_elemen menyimpannya sampai duel berikutnya).
	var elemen_sisi = {sisi_p: ui_elemen.elemen_pilihan_pemain, sisi_m: ui_elemen.elemen_pilihan_musuh}
	var slot_menang = sisi_p if hasil_ui["pemenang_final"] == "pemain" else sisi_m
	return {
		"slot_pemenang": slot_menang,
		"poin_sisa": selisih if selisih > 0 else 999,
		"elemen_pemenang": str(elemen_sisi.get(slot_menang, "")),
	}
```
(`elemen_pilihan_pemain/musuh` di-reset hanya di awal duel berikutnya dan di `siapkan_pilih_elemen` --
sudah dicek.)

### B3. Siaran state & migrasi
`_siarkan_state_giliran`: `"statistik": statistik_slot.duplicate(true),` di Dictionary `data`.
`rpc_terima_state_giliran`, di dekat blok `"ronde"`:
```
	if data.has("statistik"):
		statistik_slot = data["statistik"].duplicate(true)
```
Host baru (migrasi) / lanjut sendiri meneruskan hitungan dari siaran terakhir. Selisih kecil mungkin
terjadi kalau host keluar di tengah giliran (kejadian sejak siaran terakhir hilang) -- diterima; pemenang &
permainan tidak terpengaruh.

### B4. Papan skor membawa statistik & penghargaan
`_susun_papan_skor`: tiap baris ditambah `"stat": (statistik_slot[slot].duplicate(true) if slot <
statistik_slot.size() else ProfilPemain.statistik_kosong())`. Setelah urutan final (pemenang di baris 1):
```
	var peng = ProfilPemain.hitung_penghargaan(hasil)
	for baris in hasil:
		baris["penghargaan"] = peng.get(int(baris["slot"]), [])
```
Tanda tangan `rpc_permainan_selesai` TIDAK berubah: data baru ikut di dalam `papan_skor`, termasuk kiriman
ulang di `mulai_sekarang_migrasi` (`_papan_skor_akhir`). Baris AKHIR robot uji (uji_robot_mp.gd
`_catat_akhir`) sudah mencetak `_papan_skor_akhir` -> otomatis membandingkan statistik & penghargaan di
semua HP.

### B5. Perbaikan bug lama yang ikut (ditemukan saat meninjau rencana)
`_on_tombol_beli_pressed` dan `_on_tombol_bangun_pressed` (jalur BUKAN konfrontasi) menunggu 0,8 dtk (bangun:
juga animasi menara) TANPA menyembunyikan menu. Di solo/host pemain bisa mengetuk tombol lagi di jeda itu:
- Build Tower dua kali -> Lv1 lalu Lv2 dalam satu pemberhentian (dua kali bayar; aturan "satu bangunan per
  pemberhentian" jebol), lalu dua kali `ganti_giliran` -> giliran pemain berikutnya terlewat.
- Buy dua kali -> harga petak terbayar dua kali untuk petak yang sama.
- Buy lalu End Turn/Roll -> aksi ganda; di Quick bisa memicu akhir pertandingan dua kali.
Perbaikan: `menu_aksi.hide()` tepat setelah blok konfrontasi di kedua fungsi (sebelum uang dikurangi).
Menu muncul lagi lewat `periksa_status_petak` seperti biasa. Client tidak terdampak (menunya sudah
disembunyikan `_teruskan_aksi_ke_host`). Robot uji tidak pernah mengetuk dua kali, jadi jejak T1 tetap identik.

## 5. Bagian C: akhir pertandingan

### C1. Urutan baru (K5)
animasi menang/kalah (3 dtk) -> papan peringkat + kartu hadiah (+ tombol DOUBLE) -> pemain menekan
EXIT TO MAIN MENU -> interstisial (kalau waktunya) -> main menu.

### C2. pemain.gd: hadiah dicatat SEGERA, sekali per pertandingan
```
func _proses_hadiah_akhir(slot_pemenang: int, papan_skor: Array) -> void:
	# Fase 2: hadiah profil untuk pemain di HP ini, sekali per pertandingan.
	if _hadiah_akhir_diproses:
		return
	_hadiah_akhir_diproses = true
	_ringkasan_hadiah = ProfilPemain.catat_akhir_match(_data_akhir_profil(slot_pemenang, papan_skor))
```
Dipanggil di DUA tempat (yang kedua jadi tidak berbuat apa-apa):
- `rpc_permainan_selesai` (client), tepat setelah `_akhir_diterima = true` -- SEBELUM menunggu langkah/replay
  (bisa sampai 20 dtk); kalau tidak, HP client yang ditutup dalam jeda itu kehilangan hadiahnya.
- `_tampilkan_akhir_permainan` (semua device), setelah `PengelolaIklan.catat_match_tuntas()`.
Panggilan UI jadi `await UiDinamis.tampilkan_akhir_permainan(self, menang, papan_skor, _ringkasan_hadiah)`.
```
func _data_akhir_profil(slot_pemenang: int, papan_skor: Array) -> Dictionary:
	var stat = {}
	var peng = []
	for baris in papan_skor:
		if int(baris["slot"]) == slot_lokal:
			stat = baris.get("stat", {})
			peng = baris.get("penghargaan", [])
	return {"menang": slot_pemenang == slot_lokal, "quick": mode_quick,
		"multiplayer": StatusJaringan.peran_multiplayer != "", "stat": stat, "penghargaan": peng}
```
Hadiah langsung disimpan SEBELUM animasi, jadi aplikasi yang ditutup di layar akhir tidak kehilangan hadiah.
Catatan: sebelum B5, `_tampilkan_akhir_permainan` bisa berjalan dua kali di satu HP (ketuk ganda di Quick).
Penjaga `_hadiah_akhir_diproses` & `_double_terpakai` tetap dipasang sebagai pengaman: hadiah tercatat sekali.

### C3. ui_dinamis.gd
- `tampilkan_akhir_permainan(main_node, menang, papan_skor, ringkasan: Dictionary = {})`: HAPUS
  `await PengelolaIklan.tampilkan_interstisial_akhir_match()` (dan pengecekan valid setelahnya);
  `_panel_papan_skor(main_node, menang, papan_skor, ringkasan)`.
- `_panel_papan_skor(..., ringkasan := {})`: judul + FINAL STANDINGS di atas; di bawahnya HBoxContainer dua
  kolom: kiri = baris peringkat yang ada sekarang + nama penghargaan milik baris itu di ujung baris detail
  (mis. "tiles 5  stars 3  gems 1   DUEL KING"); kanan = `UiProfil.buat_kartu_hadiah(main_node, ringkasan,
  canvas)` (kalau ringkasan kosong, kolom kanan tidak dibuat).
- Tombol EXIT DIKELUARKAN dari VBox: anak langsung `canvas`, jangkar bawah-tengah (offset bawah -24), supaya
  selalu terlihat. Papan 4 pemain Quick sekarang saja sudah memakai y 50-676 dari 720 (foto rig
  foto_f1/q4_1280x720_papan_skor.png), dan latar penuh panel menutupi tombol ⚙ -- EXIT yang terdorong keluar
  layar = pemain terkunci. Tombol EXIT:
```
	btn_exit.pressed.connect(func():
		btn_exit.disabled = true
		# Fase 2: interstisial pindah ke sini (sebelum kembali ke menu). Panel turun ke bawah
		# layer 100 selama iklan -- iklan TIRUAN plugin <= 5.1 di editor ada di layer 100.
		canvas.layer = 99
		await PengelolaIklan.tampilkan_interstisial_akhir_match()
		if is_instance_valid(main_node) and main_node.is_inside_tree():
			keluar_ke_main_menu(main_node)
	)
```
- Ukuran: kolom kiri memakai ukuran huruf sekarang untuk 2-3 pemain; 4 pemain -> baris 28 & detail 18 supaya
  muat 720 px. Wajib difoto 1280x720 & 1600x720 (T7).

### C4. ui_profil.gd (FILE BARU, `class_name UiProfil`, semua `static func` -- dipanggil lewat nama kelas,
bukan autoload, jadi tidak kena warning static)
`buat_kartu_hadiah(main_node, r, canvas) -> Control` (PanelContainer gelap, bingkai emas), TINGGI MAKS
+-430 px:
- "YOUR REWARDS" (24) + nama & "Lv N" (18)
- "+{xp} XP     +{crowns} CROWNS" (30, emas); xp = xp_match + xp_penghargaan + XP misi, crowns sama +
  crowns_naik_level.
- Batang level (ProgressBar 260x14) "Lv N  x/y XP".
- Baris kecil (18), PALING BANYAK 3, urutan prioritas: "LEVEL UP! Lv 4  +40 Crowns" (hijau), misi selesai
  ("MISSION DONE: Win 2 duels"), penghargaan sendiri ("DUEL KING +15 XP"); lebih dari 3 -> baris ke-3 jadi
  "+2 more rewards". (Pemilik tiap penghargaan sudah tampil di kolom kiri.)
- Satu slot tombol/label di bawah: tombol "WATCH AD: DOUBLE REWARDS" (emas Color(0.75,0.55,0.1), 330x56)
  hanya kalau `r["bisa_double"]` dan
  `PengelolaIklan.rewarded_tersedia()`. Ditekan: disabled + hide; simpan `var layer_semula = canvas.layer`,
  `canvas.layer = 99`; `var dapat = await PengelolaIklan.tonton_rewarded()`; kalau canvas masih ada kembalikan
  `canvas.layer = layer_semula`; dapat -> `ProfilPemain.tambah_double(r)` (mengubah r di tempat, A6), angka
  XP/Crowns diperbarui dan label hijau "DOUBLED!" MENGGANTIKAN tombol di slot yang sama (misi tidak ikut
  digandakan, jadi jangan tulis "x2" di angka total), batang & baris naik level diperbarui; tidak dapat ->
  label "No ad right now." di slot itu. Setelah await, SETIAP node yang disentuh dicek `is_instance_valid`
  dulu, dan node tidak dioper ke fungsi berparameter bertipe sebelum dicek (pelajaran error
  "previously freed" Fase 1).
- Batang level beranimasi dari `r["xp_total_awal"]` ke `r["xp_total"]` dengan SATU Tween berantai
  (`tween_property` ... `tween_callback` untuk ganti label level ... `tween_property`), tanpa `await`; kalau
  naik level, isi penuh dulu lalu mulai dari 0 di level baru. Tween dibuat dari node batang itu sendiri
  (`batang.create_tween()`) supaya ikut mati kalau panel dibuang.

## 6. Bagian D: menu (ui_profil.gd + main_menu.gd)

### D1. main_menu.gd (edit kecil)
Di akhir `_ready`: `ProfilPemain.segarkan_hari()`, lalu `UiProfil.pasang_di_menu(self)` yang membuat:
- Bar profil kiri atas (Button datar, offset 16,16): nama (20), "Lv N" + batang XP 140x10 + "x/y", "CROWNS n"
  (20, emas). Ditekan -> panel PROFILE (D2).
- Tombol "MISSIONS" kanan atas (170x56; teks "MISSIONS 1/3"; tanda "!" kalau hadiah login belum diambil).
  Ditekan -> panel MISI (D3).
- Popup login (D4) otomatis kalau `login_bisa_diklaim()`, `call_deferred` setelah menu tampil.
Keduanya ikut memudar di `_mulai_terjun_ke_game` (tambahkan ke tween yang sama) -- simpan referensinya di
var menu `var bar_profil: Control` & `var tombol_misi: Button` -- dan DINONAKTIFKAN di `_proses_tombol_peta`
(di sebelah `_sudah_mulai = true`): selama pudar 1 dtk tombol anak tetap bisa diketuk (komentar
main_menu.gd di `_proses_tombol_peta`: mouse_filter panel tidak menghalangi tombol anaknya). Panel PROFILE,
MISI, dan popup login (CanvasLayer 11/12) dipasang sebagai ANAK main_menu, jadi ikut terbuang bersama menu.
Bar & tombol menyegarkan diri lewat sinyal `ProfilPemain.profil_berubah` yang dihubungkan ke METODE milik
main_menu (`_segarkan_profil_menu`), bukan lambda: Godot memutus sambungan ke metode itu otomatis saat menu
dibuang (lambda tidak).

### D2. Panel PROFILE (CanvasLayer 11, latar gelap penuh + kartu di tengah-ATAS supaya keyboard HP tidak
menutupi kotak nama)
"PROFILE" (32); baris nama: LineEdit (max_length 12) + "SAVE"; label pesan (merah 16; hijau "Saved!");
"Level N" + batang XP + "x/y XP to Lv N+1"; "CROWNS n" + "Crowns will unlock items soon." (16, abu);
statistik 2 kolom (18): Matches, Wins, Duels won, Traps set, Tiles bought, Gems, Awards; "CLOSE".

### D3. Panel MISI (CanvasLayer 11)
"DAILY MISSIONS" (32) + "New missions every day at midnight." (16). Tiap misi satu baris: teks (20),
"1/2" (20), "+30 CROWNS  +25 XP" (16), lalu "DONE" (hijau) atau tombol "CHANGE" (kalau
`boleh_ganti_misi`; setelah dipakai semua tombol CHANGE hilang dan muncul "1 change per day").
Di bawahnya "DAILY LOGIN": 7 kotak (Day 1-7 + hadiah), yang sudah diambil bercentang, hari ini disorot +
tombol "CLAIM" kalau `login_bisa_diklaim()`. "CLOSE".

### D4. Popup login (CanvasLayer 12)
"DAILY REWARD" (36), "Day N", 7 kotak kecil, tombol besar "CLAIM +40 CROWNS", tombol kecil "LATER".
CLAIM -> `klaim_login()` -> teks "+40 CROWNS!" (+ "LEVEL UP!" kalau ada) 1 dtk lalu tutup. LATER -> tutup;
tanda "!" di MISSIONS tetap sampai diklaim. Tidak pernah menghalangi bermain (satu ketukan menutupnya).

## 7. Multiplayer & migrasi (ringkas)
- Semua hitungan di host (B2), client menerima lewat siaran (B3) dan di papan skor akhir (B4).
- Tiap HP memanggil `catat_akhir_match` untuk `slot_lokal`-nya sendiri (C2). HP yang keluar sebelum akhir
  tidak dapat apa-apa. AI tidak punya profil.
- Double ditawarkan juga di multiplayer: pertandingan sudah selesai; pemutus koneksi sesudah akhir diabaikan
  (`_saat_peer_jaringan_disconnect` sudah berhenti kalau `_permainan_selesai or _akhir_diterima`).
- Semua HP satu permainan wajib versi yang sama (sudah berlaku sejak Fase 1).

## 8. Uji (rig)
T0. Pembanding: salin proyek sekarang (sesudah perbaikan 24-09 malam) -> proj_sebelum_fase2 (+ _tanpa_uji).
T1. Permainan tidak berubah: jejak sim identik dengan pembanding -- Classic 36 (UJI nyala) + 36 (UJI mati) +
    Quick 36 (UJI mati). Hapus user://profil.cfg rig sebelum tiap batch.
T2. Regresi multiplayer: M1-M8, A0-A6, S1-S3, D1-D4, B0-B4 + Quick Q1-Q8/Q1n/Q4n: 0 MACET, scripterr 0,
    beda 0, cek_gagal 0, baris AKHIR identik di semua HP (kini berisi stat & penghargaan).
T3. Uji unit profil (proyek kecil proj_profil, uji_profil.gd): tabel level (2b), rumus 2a (Quick/Classic,
    menang/kalah, 0 giliran), penghargaan (satu pemenang, seri, minimal tidak tercapai, Lucky Roller < 3
    lemparan, Trap Master seri -> koin), misi (progres lintas pertandingan, selesai tepat target, hadiah
    sekali), ganti misi (1x, setingkat, tidak duplikat, tidak untuk misi selesai), login (7 hari, lewat hari,
    klaim dua kali sehari ditolak, Hari 7 -> Hari 1), Double (sekali saja, naik level karena Double), nama
    (valid, pendek, panjang, simbol, kata kasar, "Taiga" lolos), simpan/muat (tanpa berkas, berkas rusak ->
    .bak, keduanya rusak -> profil baru, kunci baru terisi bawaan), ganti tanggal lewat `_tanggal_uji`.
T4. Adegan asli solo (uji_nyata): 12 run (Quick/Classic x 1-3 AI x 2 peta): hadiah di profil = rumus dari
    statistik baris slot 0 (robot menghitung ulang), berkas tersimpan, profil dimuat ulang dari disk
    sama; kartu hadiah tampil; Double lewat stub -> XP/Crowns pertandingan + penghargaan bertambah sekali
    lagi (misi & naik level tidak); interstisial stub TIDAK dipanggil sebelum papan skor. EXIT memanggil
    `reload_current_scene()` yang juga memuat ulang adegan uji -> robot memasang `uji_jeda_interstisial > 0`
    di stub, menekan EXIT, membaca hitungan interstisial (+1) SELAMA jeda itu, lalu keluar.
T5. Kebenaran statistik (sim; `uji_sim.gd _bangun()` wajib memanggil `p._reset_statistik()`): dadu_kali =
    jumlah lemparan di jejak, giliran = jumlah awal giliran slot, duel_menang+duel_kalah seluruh slot =
    2 x jumlah duel, jebakan_kena = jumlah kejadian jebakan.
Catatan rig: proj, proj_tanpa_uji, proj_sebelum_* semuanya `config/name="uji"` -> berbagi SATU
user://profil.cfg, dan uji_t1.sh menjalankannya paralel. Beri tiap salinan `config/name` sendiri (seperti
proj_mock_editor) atau jalankan uji yang membaca profil satu per satu dan hapus berkasnya sebelum tiap run.
Autoload ProfilPemain juga ditambahkan ke proj_mock_editor (T8) dan proj_iklan (kalau dipakai).
T6. cek_peringatan.sh: 0 warning di file produksi.
T7. Foto 1280x720 & 1600x720: menu (bar profil, MISSIONS), PROFILE (+ pesan nama salah), MISI, popup login,
    layar akhir 2 & 4 pemain, naik level, sesudah Double, dan KASUS TERBERAT: 4 pemain Quick + naik level +
    3 misi selesai + 4 penghargaan + sesudah Double -> EXIT & seluruh kartu hadiah tetap di dalam layar.
T8. Iklan tiruan editor + klik sungguhan di layar maya (uji_mock_editor.sh, layer 100 & 1000): DOUBLE dan
    interstisial saat EXIT tampil di atas panel dan bisa ditutup; tanpa error.

## 9. Pengiriman
Set lengkap dalam SATU pesan (minta unduhan lama dibuang): 14 file Fase 1 + `profil_pemain.gd` +
`ui_profil.gd` (+ RENCANA ini dengan STATUS). Berubah: pemain.gd (statistik, hadiah, B5), ui_dinamis.gd,
main_menu.gd. Langkah
user: daftarkan autoload ProfilPemain (bagian 3). Uji HP (build debug):
1. Buka aplikasi: popup DAILY REWARD -> CLAIM -> Crowns bertambah di bar kiri atas.
2. Main satu Quick: layar akhir menampilkan XP, Crowns, batang level; tutup aplikasi di layar akhir, buka
   lagi -> angka tetap.
3. PROFILE: ganti nama (coba nama pendek & kata kasar -> ditolak), SAVE, tutup-buka aplikasi -> nama tetap.
4. MISSIONS: CHANGE satu misi (sekali saja), selesaikan satu misi -> tercatat DONE dan hadiahnya masuk.
5. DOUBLE di layar akhir -> XP/Crowns pertandingan bertambah dan muncul "DOUBLED!"; EXIT -> tidak ada
   interstisial langsung sesudahnya (jeda 3 menit).
6. Ubah tanggal HP ke besok -> misi baru + login Hari berikutnya.
7. Beli petak lalu cepat-cepat ketuk End Turn; bangun menara lalu ketuk Build lagi -> tidak ada aksi ganda (B5).

## 10. Di luar Fase 2
Nama & kartu profil di HP teman, Respect/MVP (Fase 6). Toko & kerajaan Crowns (Fase 7-8). Mastery elemen,
event mingguan (Fase 8). Tebak Duel (Fase 5). AI memasang jebakan (Fase 4, AI ber-role). Anti-curang /
data online (belum). Statistik beli/bangun milik AI (tidak dibutuhkan).

Model: rencana ini (Opus) -> kode & uji Sonnet. Pindah ke Opus kalau T1 tidak identik tanpa sebab jelas,
statistik/penghargaan berbeda antar-HP, atau hadiah tercatat dua kali.

## STATUS (24-09, dikerjakan Opus atas permintaan user "lanjut ke langkah berikutnya")
Bagian A-D selesai sesuai rencana (K1-K7 + B5). Uji HP Fase 1 (A7) belum dilaporkan -- set ini membawa
Fase 1 + Fase 2 sekaligus, jadi daftar uji HP keduanya bisa dijalankan bersamaan.
Penyesuaian kecil saat menulis kode / tinjauan:
1. Jebakan Tanah: pemilik jebakan yang menyerang petak itu sendiri TIDAK dihitung "kena" (Trap Master).
2. Jebakan Api: koin_jebakan = 50 x (3 - sisa_bakar lama) -- korban yang masih terbakar hanya diperpanjang,
   jadi koin yang benar-benar hilang tidak dihitung dua kali.
3. Layar akhir: penghargaan tiap pemain tampil di BARIS SENDIRI (emas, di bawah baris detail) -- lebih
   terbaca daripada ditempel di ujung baris detail. Isi layar di CenterContainer di atas tombol EXIT; papan
   4 pemain memakai huruf 28/18 (bukan 32/20) supaya kasus terberat muat di 720 px.
4. Main menu: bar profil & MISSIONS ikut memudar dan dimatikan saat peta dipilih (tidak bisa dibuka
   selama transisi).
Perbaikan rig (bukan kode game): uji_sim `_bangun()` memanggil `_reset_statistik()`; pengulang jual
petak di robot memakai `rute_papan.size()` (peta asli 37 petak, papan sim 16 -> jejak sim tidak berubah);
robot T8 berhenti menunggu kalau adegan sudah dimuat ulang; robot multiplayer mencetak PROFIL_MP (hadiah
tiap HP dicek ulang dari baris papan skor: rumus, tercatat TEPAT sekali, tersimpan di berkas).
Hasil uji:
- T1 jejak identik dengan kode sebelum Fase 2: 108/108 (36 Classic UJI nyala + 36 Classic UJI mati + 36
  Quick UJI mati; 2-4 pemain x 0-1 manusia x 6 benih), diulang dengan rig terakhir -- 0 script error.
- T2 regresi multiplayer (37 skenario: M1-M8, A0-A6, S1-S3, D1-D4, B0-B4, Q1-Q8, Q1n, Q4n; 115 log HP):
  0 MACET, scripterr 0, beda 0, cek_gagal 0, kartu_beda 0; 19 HP yang keluar memang dipaksa keluar oleh
  skenarionya. 23 skenario sampai layar akhir: 60 baris AKHIR (kini berisi stat & penghargaan) identik di
  semua HP tiap skenario; PROFIL_MP 60/60 OK -- termasuk sesudah migrasi host (M1-M3, M5-M8, Q5) dan hotspot
  host mati di giliran terakhir (Q8). Skenario Classic lain berhenti di batas giliran robot (tanpa layar
  akhir), sama seperti di Fase 1.
- T3 uji unit profil: 68/68 OK, 0 warning (tabel level, rumus, penghargaan & seri, misi, ganti misi, login
  7 hari, Double sekali, nama, simpan/muat + berkas rusak/cadangan/sementara, ganti tanggal).
- T4 adegan asli solo (12 run Quick/Classic x 1-3 AI x 2 peta): PROFIL_CEK OK di 10 run (rumus, profil,
  berkas, muat ulang dari disk, kartu hadiah, DOUBLE lewat stub, interstisial hanya sesudah EXIT). 2 run
  Classic pantai (1 & 2 AI) mencapai batas 200 giliran robot tanpa pemenang -> tidak ada layar akhir untuk
  dicek (bukan kegagalan); run Classic 3 AI pantai lolos setelah perbaikan rig di atas.
- T5 statistik vs hitungan robot: STAT_CEK OK 108/108 run sim T1 (giliran per slot, lemparan dadu, duel
  menang+kalah, jebakan kena vs teks jebakan di jejak).
- T6 cek_peringatan.sh: 0 warning di file produksi.
- T7 foto 1280x720 & 1600x720: menu (bar profil + MISSIONS), PROFILE (+ nama ditolak), MISI, popup login,
  layar akhir 2 & 4 pemain, sesudah DOUBLE (kasus terberat 4 pemain Quick) -- EXIT & kartu hadiah di dalam layar.
- T8 iklan tiruan editor + klik sungguhan (layer 100 & 1000): DOUBLE dan interstisial saat EXIT tampil di
  atas panel & bisa ditutup, XP bertambah sekali, 4/4 tanpa error.
Batasan: iklan sungguhan hanya bisa diuji di HP (build debug, iklan uji Google); `ID_INTERSTISIAL_ASLI` masih
kosong (keputusan user) -- wajib diisi sebelum rilis ke Play Store.
