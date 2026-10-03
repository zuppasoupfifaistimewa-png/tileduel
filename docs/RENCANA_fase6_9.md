# RENCANA FASE 6-9: identitas, toko, event, penutup (Opus, 02-10)

Status: **DISETUJUI 02-10 -- pemilik "setuju semua a" (K1-K15 = a)**. Dasar: Fase 5 SELESAI (b22f27b, uji HP b10 lancar).
Kredit cloud tersisa ~US$25 untuk SEMUA sesi sampai Fase 9 selesai -> rencana ini dibuat hemat (bagian 6).

## 0. Ringkas
Jawaban pemilik (02-10, AskUserQuestion): tujuan utama **retensi**; **Remove Ads masuk Fase 7**; event mingguan
**offline** (tanggal HP, tanpa server); Fase 6 = **sosial ringan**.

Rantai yang masuk akal (tiap fase memberi alasan untuk fase berikutnya):
| Fase | Isi | Kenapa urutan ini |
|---|---|---|
| 6 | Identitas di multiplayer: nama + level di lobby/papan/akhir, MVP, Respect, kartu profil | Pemain lain "terlihat" -> barang kosmetik Fase 7 punya penonton |
| 7 | Toko Crowns (kosmetik tanpa aset baru) + Remove Ads (beli sekali) | Crowns yang menumpuk sejak Fase 2 akhirnya bisa dibelanjakan; pemasukan pertama |
| 8 | Event mingguan offline + token & toko event + mastery elemen | Alasan kembali tiap minggu; barang event memakai sistem toko Fase 7 |
| 9 | Sisa Fase 5 yang murah (misi Tebak Duel, taruhan Crowns) + bersih-bersih + kiriman akhir | Konten kecil tanpa ubah jaringan; penutup rapi |

Prinsip hemat (berlaku semua fase):
- Perubahan JARINGAN hanya di Fase 6 & 7 (data lobby). Regresi MP 37 skenario **sekali saja, di akhir Fase 7** (K8).
  Fase 8-9 tidak menyentuh RPC/aturan main -> tanpa regresi MP penuh, tanpa U9.
- Tidak ada fitur yang mengubah angka keseimbangan (event/mastery = hadiah & kosmetik saja) -> tanpa U9 (K9, K11).
- Bukti rig per fase = uji headless kecil (profil/migrasi/tanggal) + `cek_muat` + subset MP 3-4 skenario bila perlu.
- Satu ZIP set lengkap per fase: b11 (F6), b12 (F7), b13 (F8), b14 (F9). Uji HP pemilik di akhir tiap fase.
- Profil: `VERSI` naik satu kali per fase yang menambah data (3 di F6, 4 di F7, 5 di F8, 6 di F9 kalau perlu);
  migrasi wajib membiarkan profil lama utuh (pola Fase 4). Setiap fase: uji muat profil versi lama di headless.
- Teks untuk pemain: bahasa Inggris sederhana. RNG lewat `mesin_acak`; `ProfilPemain` tetap pakai `_rng` miliknya.

## 1. Fase 6 -- Identitas multiplayer (ringan)
**Tujuan:** di multiplayer, lawan tampil sebagai orang (nama, level), ada momen pengakuan di akhir laga (MVP, Respect).

**Fitur**
- F6.1 Data profil di lobby: tiap peer mengirim `{id, nama, level, respect, mvp_total}` ke host saat bergabung
  (pola `rpc_role_lobby` di `layar_local_play.gd`: host memvalidasi -- nama disaring ulang 3-12 huruf/angka/spasi +
  filter kata kasar yang sama, level/angka dibatasi); host menyiarkan daftar ke semua. Tiap peer menyimpan salinan
  daftar -> host pengganti (`migrasi_host.gd`) sudah punya data tanpa RPC baru.
- F6.2 Tampil: nama + "Lv N" di daftar lobby, label pemain di papan skor, layar akhir (K3). Solo: nama AI tetap.
- F6.3 MVP (K1=a): pemain dengan penghargaan terbanyak di laga itu (penghargaan sudah identik di semua HP sejak Fase 2),
  seri -> pemenang, masih seri -> urutan slot. Dihitung lokal di tiap HP, TANPA RPC baru. Tampil "MVP" di layar akhir;
  `mvp_total` +1 di profil sendiri bila saya MVP (solo juga dihitung, K1).
- F6.4 Respect (K2=a): tombol "RESPECT" per lawan MANUSIA di layar akhir, 1x per lawan per laga. RPC kecil ke host,
  host meneruskan ke target (validasi: laga sudah selesai, pengirim peserta, belum pernah per pasangan). Penerima:
  `respect` +1 + toast "<name> gave you Respect!". Tanpa hadiah Crowns (hindari farming).
- F6.5 Kartu profil: ketuk nama di lobby/layar akhir -> kartu kecil (nama, level, Respect, MVP, role terakhir).
  Memakai data F6.1 saja.
- F6.6 Penjaga versi: SEBELUM menambah RPC, cek apakah sudah ada pemeriksaan versi saat bergabung. Kalau belum:
  client mengirim `VERSI_PROTOKOL`, host menolak yang beda dengan pesan "Please update the game to play together."
  (HP teman dengan versi Play lama tidak boleh menerima RPC yang tidak dikenalnya -- di Godot 4 RPC dicocokkan per
  urutan konfigurasi skrip, versi beda bisa salah panggil.)

**Langkah**
| G | Model | Isi | Bukti |
|---|---|---|---|
| G0 | Sonnet | Profil VERSI 3 (`respect`, `mvp_total`; pastikan `id` terisi) + migrasi; cek F6.6 (grep) dan catat temuan | uji headless: profil v2 dimuat -> field baru 0, data lama utuh |
| G1 | Sonnet | F6.6 (kalau perlu) + F6.1 + F6.2 lobby/papan/akhir | `cek_muat`; MP subset: 1v1, 3P client keluar, 4P migrasi host (nama tetap benar setelah migrasi) |
| G2 | Sonnet | F6.3 MVP + F6.4 Respect + F6.5 kartu | MP subset sama + 1 skenario Respect (target menerima tepat 1x, kirim ganda ditolak) |
| G3 | Sonnet | Bersih-bersih pola F7 + `kiriman/TileDuel_Fase6_b11.zip` + daftar uji HP | uji HP pemilik (2 HP: nama, level, MVP, Respect, versi beda ditolak) |
Opus hanya bila ada BEDA/MACET di subset MP atau bug membingungkan.

**Risiko:** HP teman versi lama (F6.6); nama kasar dari client yang dimodifikasi (validasi di host); migrasi host
kehilangan daftar (salinan di tiap peer); layar akhir sudah padat (kartu = popup, bukan tambahan baris).

## 2. Fase 7 -- Toko Crowns + Remove Ads
**Tujuan:** Crowns punya kegunaan (retensi) dan ada pemasukan selain iklan (Remove Ads).

**Fitur**
- F7.1 Katalog kosmetik TANPA aset baru (K4=a), di file baru `data_kosmetik.gd` (konstanta saja):
  warna bidak (~8, material albedo), gelar di bawah nama (~10 teks), bingkai kartu profil (~6, warna StyleBox).
  Tiap barang: `id, jenis, nama (Inggris), harga, syarat_level (opsional)`. Barang awal gratis: 1 per jenis.
- F7.2 Profil VERSI 4: `kosmetik_dimiliki: Array`, `kosmetik_dipakai: {jenis: id}`; API `beli(id)` (cek Crowns, tidak
  pernah negatif, simpan sekali), `pakai(id)`. Teks "Crowns will unlock items soon." diganti tombol **SHOP**.
- F7.3 Layar SHOP (`ui_toko.gd` baru, pola `ui_dinamis`): tab Pawn / Title / Frame, harga, BUY / EQUIP, pratinjau.
- F7.4 Kosmetik tampil: warna bidak & gelar & bingkai di HP sendiri dan di HP teman -> tambahkan `kosmetik_dipakai`
  ke payload F6.1 (host memvalidasi id ada di katalog; id tak dikenal -> default). Satu-satunya perubahan jaringan F7.
- F7.5 Remove Ads (K5=a, K6=a): autoload baru `pengelola_pembelian.gd` memakai plugin Google Play Billing untuk Godot
  (pemilik memasang plugin di proyek; versi cocok Godot 4.7.1 dicek di G4). Produk non-consumable `remove_ads`.
  Tanpa plugin (editor/rig/desktop) -> mode stub, tidak pernah crash (`Engine.has_singleton`). Saat start: query
  pembelian -> kalau dimiliki set `PengelolaIklan.bebas_iklan = true` (= "restore" otomatis); pembelian baru wajib
  di-acknowledge (Play mengembalikan dana bila tidak dalam 3 hari). Interstisial + app-open hilang; iklan berhadiah
  TETAP ada karena pemain sendiri yang memilihnya; bonus 500 Crowns sekali saat beli.
  Status beli disimpan juga di profil sebagai cadangan, tetapi sumber kebenaran = query Play.

**Langkah**
| G | Model | Isi | Bukti |
|---|---|---|---|
| G0 | **Opus** | Harga & isi katalog dari ekonomi Crowns: baca `catat_akhir_match`/misi/login (tanpa simulasi; pakai data hasil U9 yang sudah ada bila memuat Crowns). Target: barang pertama setelah ~3 laga, termahal ~60-80 laga. Tulis tabel final di bagian 2.1 | tabel di rencana ini |
| G1 | Sonnet | `data_kosmetik.gd` + profil v4 + API beli/pakai | uji headless: beli tanpa cukup Crowns ditolak, beli ganda ditolak, simpan/muat, migrasi v3 |
| G2 | Sonnet | Layar SHOP + tombol menu | `cek_muat`; tangkapan layar headless bila rig mendukung |
| G3 | Sonnet | F7.4 tampil di HP sendiri & teman | MP subset (1v1 + 4P migrasi host) |
| G4 | Sonnet | F7.5 `pengelola_pembelian.gd` (stub di rig, seperti stub iklan; JANGAN salin stub ke `game/`) | rig: mode stub tanpa error; `bebas_iklan` mematikan interstisial di jalur uji |
| G5 | Sonnet | **Regresi MP 37 skenario sekali (K8)** + `cek_nilai` + bersih-bersih + `kiriman/TileDuel_Fase7_b12.zip` | 37/37, 0 BEDA/MACET; uji HP pemilik (toko, kosmetik di HP teman, beli Remove Ads dengan akun penguji lisensi) |

**Tugas pemilik (di luar cloud):** pasang plugin billing di proyek Godot; buat produk `remove_ads` di Play Console
(harga K6); tambahkan akun penguji lisensi; uji di build Internal testing (pembelian tidak bisa diuji di cloud).

**Risiko:** versi plugin billing vs Godot 4.7.1 (G4 cek dulu, kalau tidak cocok -> Remove Ads mundur ke rilis
berikutnya, toko Crowns tetap jalan); harga Crowns salah -> toko terasa mustahil/terlalu murah (Opus G0);
lupa acknowledge -> dana kembali otomatis (uji HP wajib cek status setelah 5 menit & setelah buka ulang).

### 2.1 Tabel katalog & harga -- diisi Opus di G0 Fase 7

Status: **FINAL (Opus, 03-10, G0)**. Tanpa simulasi; dihitung dari `game/profil_pemain.gd` (konstanta) + panjang laga di
`hasil/g7_profil/solo_ringkas.txt` & `hasil/g8_u9_b50000/` (Quick 2P: ~5-8 giliran per pemain; Classic: ~21-27, kadang 59).

**Pendapatan Crowns (ekonomi TIDAK diubah di F7):**
| Sumber | Rumus (profil_pemain.gd) | Quick 2P (~6 giliran) | Classic (~25 giliran) |
|---|---|---|---|
| Laga | 2 x giliran x (1.0 Quick / 1.6 Classic) x 1.5 bila menang | 12 kalah / 18 menang | 80 / 120 |
| Penghargaan | 10 per penghargaan (4 jenis dibagi pemain) | ~7 | ~7 |
| Tebak Duel | 3 per tebakan benar, maks 5 | ~3 | ~15 |
| Naik level | 10 x level baru; jangka panjang ~0.4 x XP per laga | ~10-15 | ~60 |
| **Dasar per laga** | | **~40** | **~160 (waktu ~4x)** |
| Login 7 hari | 20/30/40/50/60/80/150 = 430/minggu | ~61/hari | |
| Misi harian | 20 + 30 + 45 bila 3 selesai | <=95/hari | |
| DOUBLE (iklan) | laga + penghargaan sekali lagi | +~22/laga | |
- Pemain baru, hari 1, 3 laga Quick: login 20 + misi ~50 + laga/penghargaan ~75 + naik ke Lv2 20 = **~165**.
- Pemain kasual 4 laga/hari tanpa iklan: (4 x 40 + ~156) / 4 = ~80/laga; 8 laga/hari ~60. **Basis harga = 50 Crowns per laga
  "efektif"** (sengaja konservatif: tidak semua misi selesai, tanpa iklan). Classic = ~4 laga Quick.
- Level (XP ~50/laga Quick + XP misi): Lv5 ~8 laga, Lv10 ~30, Lv12 ~40, Lv15 ~60 -> `syarat_level` dipakai sebagai "kunci
  waktu" untuk barang mahal supaya Crowns lama (tertimbun sejak Fase 2, belum ada tempat belanja) tidak langsung menghabiskan toko.

**Target cek:** termurah 150 = ~3 laga (hari 1 pemain baru ~165 Crowns); termahal 3500 = ~70 laga @50 (44 @80, 88 @40).
Seluruh katalog = 27 750 Crowns (~550 laga) -> penampung Crowns jangka panjang. Bonus Remove Ads 500 = 1-2 barang murah.

**Warna bidak (jenis `pawn`, 8).** ATURAN: warna BADAN tetap warna slot (biru/merah/hijau/kuning = identitas pemain & warna
petak milik, `WARNA_SLOT` di `pemain_dasar.gd`) -- kosmetik TIDAK menggantinya. Kosmetik mewarnai bagian BUKAN-badan
(sarung tangan putih & sepatu abu-abu: material yang dilewati `_warnai_karakter`) = "trim". G3 (Sonnet): tambahkan cabang
`else` di `_warnai_karakter` dengan warna trim slot itu; cek di model bahwa sarung tangan + sepatu memang terwarnai.
Kalau ternyata tidak ada material bukan-badan yang layak -> lapor, Opus memutuskan (jangan ganti warna badan).
| id | nama | warna trim (albedo) | efek material | harga | syarat Lv |
|---|---|---|---|---|---|
| pawn_classic | Classic | (asli, tidak diubah) | - | 0 (awal) | - |
| pawn_shadow | Shadow | #262626 | - | 150 | - |
| pawn_ocean | Ocean | #1FB5AD | - | 300 | - |
| pawn_rose | Rose | #FF6FAE | - | 500 | - |
| pawn_violet | Violet | #7A3CFF | - | 800 | 5 |
| pawn_lava | Lava | #FF5A00 | emission #FF5A00 x0.6 | 1200 | 8 |
| pawn_gold | Gold | #FFCC33 | metallic 0.8, roughness 0.3 | 2000 | 12 |
| pawn_diamond | Diamond | #BFF4FF | metallic 0.6, roughness 0.1, emission #BFF4FF x0.4 | 3500 | 15 |

**Gelar (jenis `title`, 10).** Teks kecil di bawah nama: lobby, papan skor/layar akhir (bila muat), kartu profil.
| id | teks | harga | syarat Lv |
|---|---|---|---|
| title_rookie | Rookie | 0 (awal) | - |
| title_tile_hunter | Tile Hunter | 150 | - |
| title_trap_setter | Trap Setter | 300 | - |
| title_coin_collector | Coin Collector | 400 | - |
| title_duelist | Duelist | 600 | - |
| title_storm_caller | Storm Caller | 900 | 5 |
| title_tower_builder | Tower Builder | 1200 | 8 |
| title_grand_strategist | Grand Strategist | 1800 | 10 |
| title_elemental_lord | Elemental Lord | 2600 | 12 |
| title_tile_legend | Tile Legend | 3500 | 15 |
(Nama sengaja tidak sama dengan penghargaan akhir DUEL KING / TRAP MASTER / LANDLORD / LUCKY ROLLER.)

**Bingkai kartu profil (jenis `frame`, 6).** StyleBoxFlat panel kartu profil (`UiProfil.tampilkan_kartu_profil`).
| id | nama | border_color | border lebar | tambahan | harga | syarat Lv |
|---|---|---|---|---|---|---|
| frame_plain | Plain | (gaya sekarang) | (sekarang) | - | 0 (awal) | - |
| frame_bronze | Bronze | #CD7F32 | 3 | - | 250 | - |
| frame_silver | Silver | #C9D1D9 | 3 | - | 700 | - |
| frame_emerald | Emerald | #2ECC71 | 4 | - | 1200 | 6 |
| frame_gold | Gold | #FFCC33 | 5 | shadow #FFCC33 a0.5 size 6 | 2200 | 10 |
| frame_royal | Royal | #9B59FF | 5 | shadow #FFCC33 a0.6 size 8; corner radius +4 | 3500 | 15 |

**Aturan untuk G1-G3 (Sonnet):**
- `data_kosmetik.gd`: `const KATALOG := {id: {"jenis", "nama", "harga", "lv", ...data tampilan}}` dengan urutan tabel di atas
  (= urutan tab toko); `const AWAL := {"pawn": "pawn_classic", "title": "title_rookie", "frame": "frame_plain"}`.
  Barang `AWAL` dianggap SELALU dimiliki (tidak perlu disimpan; profil v3 -> v4 otomatis punya & memakainya).
- `beli(id)`: tolak bila id tak dikenal, sudah dimiliki, `level_sekarang() < lv`, atau `crowns < harga`; kurangi Crowns,
  tambah ke `kosmetik_dimiliki`, LANGSUNG dipakai (equip otomatis), `simpan()` sekali. Tidak ada jual/refund.
- `pakai(id)`: hanya barang yang dimiliki; jenis diambil dari katalog.
- Tombol toko: harga + ikon Crowns; kurang Crowns -> "Need N more Crowns"; level kurang -> "Reach Lv N" (terkunci, tetap
  terlihat sebagai tujuan). Teks pemain bahasa Inggris sederhana.
- Jaringan (F7.4): kirim 3 id dipakai; host memvalidasi id ada di KATALOG dan jenisnya cocok, jika tidak -> `AWAL`.
  Kepemilikan TIDAK divalidasi (tidak bisa tanpa server; kosmetik saja, tidak memengaruhi permainan).
- Harga boleh disetel setelah rilis (konstanta); barang yang sudah dibeli tidak pernah dicabut.


## 3. Fase 8 -- Event mingguan offline + mastery elemen
**Tujuan:** alasan kembali tiap minggu, tanpa server dan tanpa mengubah keseimbangan.

**Fitur**
- F8.1 Event mingguan (K9=a: aturan main TIDAK berubah). Nomor minggu dari tanggal HP (minggu ISO, Senin awal) ->
  `indeks = minggu % 6`. Enam event: Fire Week, Water Week, Wind Week, Lightning Week, Earth Week, Duel Week.
  Tiap event: 3 misi event (contoh Fire Week: "Play 5 matches as Fire", "Win 2 matches as Fire", "Win 3 duels";
  Duel Week: "Guess 5 duels right", "Claim 2 bounties", "Win 4 duels"), hadiah = **Event Tokens**.
  Data di file baru `data_event.gd` (konstanta). Progres memakai jalur yang sama dengan misi harian (`_majukan_misi`).
- F8.2 Toko event: tab EVENT di SHOP (sistem Fase 7) berisi 3 kosmetik bertema event, dibeli dengan token.
  Barang kembali saat event itu berputar lagi (6 minggu, K10=a). Token tidak hangus.
- F8.3 Penjaga tanggal (K12=a): simpan tanggal terbesar yang pernah terlihat; kalau tanggal HP mundur, misi event
  tidak maju & hadiah tidak bisa diklaim sampai tanggal kembali (tanpa hukuman lain). Pakai `_tanggal_uji` untuk uji.
- F8.4 Mastery elemen (K11=a): XP per elemen dari laga (main +1, menang +2, duel menang dengan elemen itu +1), level
  1-10 per elemen. Hadiah level = Crowns + gelar mastery (mis. "Fire Master" di level 10, masuk katalog gelar Fase 7).
  TANPA bonus statistik permainan.
- F8.5 UI: tombol EVENT (atau tab di MISSIONS) dengan sisa waktu "Ends in 3d 4h"; mastery di layar PROFILE.

**Langkah**
| G | Model | Isi | Bukti |
|---|---|---|---|
| G0 | Sonnet | `data_event.gd` + profil v5 (`token_event`, `misi_event`, `minggu_event`, `tanggal_maks`, `mastery`) + migrasi | uji headless dgn `_tanggal_uji`: ganti minggu -> misi baru, Minggu->Senin, tahun baru (minggu 52/53->1), tanggal mundur |
| G1 | Sonnet | Progres misi event + mastery dari `catat_akhir_match` | uji headless: 1 laga palsu memajukan misi & mastery yang benar; solo & MP |
| G2 | Sonnet | UI EVENT + tab toko event + mastery di PROFILE | `cek_muat` |
| G3 | Opus (kecil, opsional) | Cek laju token vs harga toko event & hadiah mastery vs harga Fase 7 (baca saja, tanpa simulasi) | catatan di bagian 3.1 |
| G4 | Sonnet | Bersih-bersih + `kiriman/TileDuel_Fase8_b13.zip` + daftar uji HP (ubah tanggal HP maju/mundur) | uji HP pemilik |

**Risiko:** perhitungan minggu di batas tahun (uji G0); profil membengkak (simpan ringkas); pemain ubah tanggal maju
(dibiarkan -- offline, tidak merugikan orang lain); misi event yang mustahil untuk role/elemen tertentu (G3).

### 3.1 Angka FINAL Fase 8 (Opus G0, 03-10) -- konstanta di `game/data_event.gd` + `data_kosmetik.gd`
- **Role = elemen** (`DataRole.ROLE` = api/air/tanah/petir/angin), jadi "main sebagai Fire" = role `api` di `d["role"]`.
- **Minggu:** Senin 00:00 jam HP. Nomor minggu = minggu sejak Senin 1970-01-05 (BUKAN nomor ISO: ISO kembali ke 1 tiap
  tahun -> `% 6` meloncat di 52/53->1). Batas minggu tetap sama dgn ISO. Putaran: Fire, Water, Wind, Lightning, Earth, Duel.
  Minggu 2026-09-28..10-04 = **Wind Week**, 10-05 = Lightning (geser urutan = ubah `EVENT`, tanpa efek lain).
- **Misi event (3/minggu, hadiah token, sekali per minggu):** elemen X: "Finish 5 matches as X" 30, "Win 4 duels with X" 30
  (stat `menang_elemen[X]`, role apa pun), "Win 2 matches as X" 40. Duel Week: "Guess 5 duels right" 30 (mustahil di 1v1 ->
  perlu 3+ pemain/AI), "Claim 2 bounties" 30, "Win 8 duels" 40. **= 100 token/minggu penuh.** Token tidak hangus.
- **Toko event:** 3 barang/event (pawn 60, title 40, frame 80 token = 180); 6 event = 18 barang = 1080 token. Pemain rajin:
  2 barang di minggu event + sisanya dari tabungan; semua barang ~11 minggu (dua putaran). Barang hanya dijual saat event-nya
  berjalan (K10=a), di `DataKosmetik.KATALOG` dgn `"sumber": "event"`, `"event"`, `"token"`, `"harga": 0` (toko Crowns
  hanya menampilkan `sumber` "" lewat `daftar(jenis)`; `beli()` Crowns menolak -> "Event item").
- **Mastery (K11=a):** XP per elemen per laga tuntas: role = X -> +1, menang +2 lagi; tiap duel menang dgn elemen X +1.
  Level 1-10, XP total untuk mencapai level: 0/5/12/22/35/55/80/115/160/220 (~70-80 laga dgn role itu ke Lv 10).
  Crowns saat MENCAPAI Lv 2..10: 30/50/75/100/150/200/250/300/400 = 1555/elemen, 7775 semua (vs toko Crowns 27 750 ->
  ~+20 Crowns/laga, tidak membanjiri). Lv 10 = gelar "<Elemen> Master" (`title_fire_master` dst., `"sumber": "mastery"`,
  tidak dijual, diberikan otomatis). TANPA bonus statistik.
- **Tanggal mundur (K12=a):** `tanggal_maks` = tanggal terbesar yang pernah terlihat; `tanggal_mundur()` -> misi event tidak
  maju, token/toko event dikunci (G1/G2 wajib memeriksa), misi minggu itu TIDAK di-reset; mastery & misi harian tidak terpengaruh.
  Akibat yang diterima: tanggal dimajukan jauh lalu dikembalikan -> event berhenti sampai tanggal itu.
- **Sisa waktu:** `DataEvent.detik_sampai_minggu_baru(Time.get_datetime_dict_from_system())` + `teks_sisa` -> "Ends in 3d 4h".

## 4. Fase 9 -- Sisa Fase 5 yang murah + penutup
**Tujuan:** konten kecil tanpa sentuh jaringan/keseimbangan, lalu kiriman akhir yang rapi.

**Fitur**
- F9.1 Misi harian Tebak Duel: 2-3 misi baru di pool misi harian ("Guess 3 duels right", "Guess 2 duels in a row").
  Hanya profil.
- F9.2 Taruhan Crowns Tebak Duel (K13=a): opsional, sebelum menebak pilih taruhan 10/25/50 Crowns (tidak bisa
  melebihi saldo); benar = dapat kembali x2, salah = hilang; maks 10 taruhan per hari. Murni LOKAL di HP masing-masing
  (hasil duel sudah sama di semua HP) -> tanpa RPC baru, solo & MP.
- F9.3 Ditunda/dibatalkan (hemat kredit, K14/K15): AI menyesuaikan elemen dengan bounty (butuh U9, +~US$3-4);
  tombol AI cepat & putar ulang rolet di multiplayer (ubah jaringan + iklan di tengah giliran MP).
- F9.4 Penutup: bersih-bersih pola F7, `cek_muat`/`cek_nilai`, `kiriman/TileDuel_Fase9_b14.zip`, daftar periksa
  rilis diperbarui.

**Langkah**
| G | Model | Isi | Bukti |
|---|---|---|---|
| G0 | Sonnet | F9.1 + F9.2 (profil v6 bila perlu: hitungan taruhan harian) | uji headless: saldo tidak pernah negatif, batas harian, x2 benar |
| G1 | Sonnet | F9.4 + ZIP b14 + daftar uji HP + LOG/HANDOFF akhir | uji HP pemilik |
| (G2) | Opus | HANYA bila kredit tersisa >= US$5 setelah G1: AI bounty + U9 S1+S2 benih baru | P14 lolos |
| G2 SELESAI (03-10) | Opus | AI bounty `PELUANG_BOUNTY_AI`=50 (`ai_musuh.gd`), U9 S1+S2 benih 80000 + pembanding kode lama, ZIP b15 | P14 gagal di kode lama JUGA (api 35, angin 60) -> G2 netral, diterima; temuan di bagian 5 |

**Risiko:** taruhan terasa "judi" untuk kebijakan Play -> memakai mata uang game yang TIDAK bisa dibeli dengan uang
(Crowns tidak dijual di Fase 7 -- pertahankan begitu), jadi aman; misi baru membuat pool misi harian terlalu sering
Tebak Duel (bobot rendah).

## 5. Temuan terbuka yang dibawa
- (03-10, Fase 9 G2) Keseimbangan role di benih 80000 gagal P14 bahkan TANPA G2: S1 api 35.2% / angin 59.8%; S2 angin 33.4% / air 18.8%. U9 terakhir (Fase 5 G8, benih 50000) lolos. Belum diketahui regresi Fase 6-9 atau derau benih -> sesi Opus (cek b10 di `kontrol_api.tugas`, lihat HANDOFF 5). Data `hasil/g9_g2/`.
- BEDA jebakan Phoenix host vs client (RENCANA_fase5 10.5, s821): dipantau. Regresi MP 37 di Fase 7 G5 sekaligus
  menjadi pengamatan ulang; kalau muncul -> Opus menganalisis sebelum b12 dikirim.
- 11 `godot.log` sampah di `rig/proj_tanpa_uji/sim/home_*` (pemilik: `git rm -r rig/proj_tanpa_uji/sim`).
- `ID_INTERSTISIAL_ASLI` kosong -- keputusan rilis pemilik (berkaitan dengan Remove Ads Fase 7).
- "Kerajaan Crowns" dari rencana Fase 2 (K7=a: dibatalkan, digantikan toko) dan Sinkron profil online/anti-curang:
  di luar Fase 6-9.

## 6. Perkiraan biaya (kasar, US$ kredit cloud)
Dasar: sesi G9 Fase 5 (Sonnet, ZIP + dokumen) menghabiskan ~US$3; sesi Opus dengan simulasi lebih mahal (~US$5-8).
Menunggu simulasi di latar hampir gratis; yang mahal = membaca file besar & banyak panggilan alat.
| Bagian | Sesi | Perkiraan |
|---|---|---|
| Sesi ini (Opus, rencana) | 1 | ~2.5 |
| Fase 6 | 2 Sonnet (G0-G1, G2-G3) | ~4.5 |
| Fase 7 | 1 Opus kecil (G0) + 2-3 Sonnet (G1-G3, G4, G5 + regresi 37) | ~7 |
| Fase 8 | 2 Sonnet (+ Opus G3 opsional ~1) | ~4.5 |
| Fase 9 | 1 Sonnet | ~2.5 |
| Cadangan bug dari uji HP (Opus) | - | ~2.5 |
| **Total** | | **~23.5** (kredit ~25) |
Muat, tapi tipis. Kalau biaya melewati perkiraan, dipangkas berurutan: (1) F9.2 taruhan Crowns; (2) Opus G3 Fase 8;
(3) F6.5 kartu profil (nama & level tetap); (4) mastery elemen (F8.4) jadi Fase 10. Yang TIDAK dipangkas:
toko Crowns, Remove Ads, event mingguan (inti retensi & pemasukan). Hemat per sesi: baca hanya bagian rencana fase
itu + HANDOFF 0 & 5 + entri LOG teratas; gabungkan beberapa G dalam satu sesi seperti tabel di atas.

## 7. Keputusan pemilik (rekomendasi = a)
| K | Fase | Pertanyaan | a (rekomendasi) | b | c |
|---|---|---|---|---|---|
| K1 | 6 | Aturan MVP | penghargaan terbanyak (sudah sama di semua HP), tanpa RPC; dihitung juga di solo | host menghitung skor & kirim RPC baru | tanpa MVP |
| K2 | 6 | Respect | 1x per lawan manusia per laga, tanpa hadiah Crowns | + 5 Crowns untuk penerima (risiko farming) | tanpa Respect |
| K3 | 6 | Di mana nama+level tampil | lobby + papan skor + layar akhir | lobby + layar akhir saja | lobby saja |
| K4 | 7 | Jenis kosmetik | warna bidak + gelar + bingkai (tanpa aset baru) | + tema papan (aset dari pemilik, +biaya) | warna bidak saja |
| K5 | 7 | Cakupan Remove Ads | hapus interstisial + app-open; iklan berhadiah tetap (opsional); +500 Crowns | hapus semua, hadiah iklan diberikan langsung | hanya interstisial |
| K6 | 7 | Harga Remove Ads (diatur pemilik di Play Console) | ~US$2.99 | ~US$1.99 | ~US$4.99 |
| K7 | 7 | "Kerajaan Crowns" (rencana Fase 2) | dibatalkan, diganti toko | ditunda setelah Fase 9 | - |
| K8 | 7 | Regresi MP 37 skenario | sekali di akhir Fase 7 (semua perubahan jaringan sudah masuk) | akhir Fase 6 dan 7 (+~US$1.5) | subset saja |
| K9 | 8 | Event mengubah aturan main? | tidak, misi & hadiah saja (tanpa U9) | ya, mis. event papan lebih sering (+U9, +~US$4) | - |
| K10 | 8 | Barang toko event | kembali tiap putaran 6 minggu | eksklusif sekali | - |
| K11 | 8 | Hadiah mastery | Crowns + gelar saja | + bonus statistik kecil (+U9) | tanpa mastery |
| K12 | 8 | Tanggal HP mundur | event/hadiah berhenti sampai tanggal kembali | tanpa penjaga | - |
| K13 | 9 | Taruhan Crowns Tebak Duel | lokal opsional 10/25/50, x2, maks 10/hari | tanpa taruhan | - |
| K14 | 9 | AI menyesuaikan bounty | ditunda; dikerjakan hanya bila kredit sisa >= US$5 | dikerjakan wajib (U9) | dibatalkan |
| K15 | 9 | AI cepat & putar ulang rolet di MP | dibatalkan (jaringan + iklan di giliran MP) | ditunda | - |

## 8. Arahan model
- Sesi berikut: **Sonnet** -- Fase 7 G1 (+G2 bila sesi masih pendek). Baca: CLAUDE.md, HANDOFF 0 & 5, LOG teratas, bagian 0, 2 (termasuk 2.1), 7 rencana ini. (Fase 6 G0-G3 selesai.)
- Opus: Fase 7 G0 (harga), bug MP/BEDA yang membingungkan, Fase 8 G3 (opsional), Fase 9 G2 (bersyarat).
- Pemilik: rilis A+B+Fase 5 bisa jalan paralel; rilis berikutnya disarankan setelah b12 (toko + Remove Ads).

## 9. STATUS
- 02-10 (Opus): draf disusun dari jawaban pemilik (retensi, Remove Ads F7, event offline, sosial ringan).
- 02-10 (pemilik): **setuju semua a** (K1-K15 = a). "Kerajaan Crowns" (K7) hanya disebut sekilas di rencana Fase 2 tanpa rancangan -> dibatalkan, digantikan toko. Berikutnya: Fase 6 G0+G1 (Sonnet).
- 02-10 (Sonnet): **F6 G0 + G1 SELESAI** (bukti `hasil/g6_profil/`).
  - G0: `profil_pemain.gd` VERSI 3 (+ `respect`, `mvp_total`, bagian berkas "sosial"; `tambah_respect()`/`catat_mvp()` untuk G2). `id` sudah terisi sejak Fase 2.
    Uji headless `uji_profil_v3.gd` (rig-only) 18/18: profil v2 dimuat -> field baru 0, data lama utuh; v3 simpan/muat; nilai rusak -> 0; profil baru. `cek_muat_f3` 26/26.
  - Temuan F6.6: SEBELUMNYA TIDAK ADA penjaga versi (lobby menerima client mana pun). Dibuat: `StatusJaringan.VERSI_PROTOKOL = 2`; client kirim `rpc_sosial_profil(versi, profil)` begitu tersambung; host MENOLAK versi beda
    (`rpc_tolak_versi` + putus) dan memutus peer yang tidak mengirim profil dalam 4 dtk (= HP versi lama); host hanya mengirim info lobby/START ke client yang sudah sah; client yang tidak dapat info lobby dalam 6 dtk
    (host versi lama) atau diputus sebelum masuk lobby menampilkan "Please update the game to play together." Dua RPC baru SENGAJA bernama `rpc_s...`/`rpc_t...` (urutan abjad SESUDAH `rpc_role_lobby`) supaya nomor RPC lama tidak bergeser.
    ATURAN untuk RPC baru berikutnya di skrip yang sama: beri nama yang jatuh sesudah semua RPC lama (abjad). `rpc_info_lobby` +param profil, `rpc_mulai_dari_lobby` +param profil_slot -> perlu build sama di semua HP.
  - G1: profil sah (nama disaring ulang `cek_nama`, angka dibatasi) disalin ke semua peer lewat `rpc_info_lobby`; saat START host membangun `profil_slot` (per slot, AI = {}) -> `StatusJaringan.profil_slot` di SEMUA HP
    (jadi host pengganti saat migrasi sudah punya). Tampil: lobby ("Nama Lv3"), teks permainan (`_nama_slot`/`_nama_ui`/`_nama_layar`/label duel), papan skor & layar akhir ("Nama Lv3"); solo/AI tidak berubah ("P2", "Enemy").
  - Bukti MP subset (rig `uji_robot_mp.gd`: robot memakai nama "Bot <peran><urut>", level 3-5; log `PROFIL_NAMA`): 1v1 Quick (cek_ok=7), 3P client keluar (cek_ok=8), 4P host keluar -> migrasi (cek_ok_migrasi=14),
    semua 0 SCRIPT ERROR, 0 beda; nama+level sama di semua HP dan tetap benar sesudah migrasi. U9 & MP 37 TIDAK diulang (akhir F7).
  - Migrasi (M2 diulang dgn log `PROFIL_NAMA sesudah_migrasi`): nama/level 4 slot identik di host baru (c1), c2, c3 sebelum & sesudah migrasi, cek_ok_migrasi=16.
  - BELUM: tampilan di layar sungguhan (headless) + jalur TOLAK versi (belum ada robot yang mengirim versi salah; jalur kode sederhana, uji nyata = 2 HP beda build di G3) -> G3. Berikutnya: **G2 (Sonnet): MVP + Respect + kartu profil**.
- 03-10 (Sonnet): **F6 G2 SELESAI** (bukti `hasil/g6_mvp_respect/`).
  - F6.3 MVP: `ProfilPemain.hitung_mvp(papan)` (penghargaan terbanyak; seri -> pemenang = baris pertama papan; masih seri -> slot terkecil), tanpa RPC; `pemain.gd _proses_hadiah_akhir` -> `catat_mvp()` bila saya MVP (sekali per laga, solo juga); label "MVP" di layar akhir.
  - F6.4 Respect: tombol RESPECT di baris lawan MANUSIA (layar akhir). `kirim_respect()` (guard 1x/lawan) -> host langsung / client `rpc_zrespect_kirim(slot_target)` (any_peer) -> `_host_proses_respect` (laga selesai, keduanya manusia & beda, belum pernah "pengirim>target") -> `rpc_zrespect_terima(slot_pengirim)` (authority, hanya dari peer 1) -> `_terima_respect` (penjaga ke-2: sekali per pengirim) -> `tambah_respect()` + toast. RPC baru bernama `rpc_z*` supaya jatuh SESUDAH `rpc_umumkan` (nomor RPC lama tidak bergeser). Pengirim ditentukan host dari id peer, bukan dari kiriman.
  - F6.5 Kartu profil: `UiProfil.tampilkan_kartu_profil` (nama, level, Respect, MVP, role); dibuka dengan mengetuk nama di lobby (`[url]` pada RichTextLabel) atau baris layar akhir. Profil lobby + field `role` (`role_terakhir`, divalidasi host lewat `_role_aman`; tanpa RPC/param baru).
  - Bukti: `uji_profil_v3` 22/22; `cek_muat_f3` 26/26; MP quick Q1 / S1 / M2 0 beda 0 SCRIPT ERROR (migrasi: cek_ok_migrasi=6); R1 (skenario robot `respect`, 3P+1AI, benih 31): c1 2->4, c2 3->5, host 2->4 = +2 tepat, kirim ganda ditolak, AI/diri ditolak, MVP slot sama di semua HP (`MVP_UJI`). Catatan: run `r1`/`r1b` awal memberi GAGAL host karena tes mengambil nilai awal terlambat (Respect sudah tiba) -> tes diperbaiki (`respect_awal_uji`); `r1c` = run sah. Run `r1` Classic tidak selesai dlm 30 giliran (bukan bug), diganti quick.
  - BELUM: tampilan layar sungguhan (tata letak 4 pemain, toast) + jalur TOLAK versi -> uji 2 HP di G3. Berikutnya: **G3 (Sonnet)**.
- 03-10 (Sonnet): **F6 G3 SELESAI** (bukti `hasil/g6_bersih/G3_cek.txt`).
  - Bersih-bersih pola F7: grep debug/print/TODO = 0, saklar `UJI_*` false, `game/` 34/35 identik dgn rig (beda hanya stub iklan). Tidak ada .gd `game/` berubah di G3 -> cek_muat/uji G2 tetap berlaku (tidak diulang).
  - `kiriman/TileDuel_Fase6_b11.zip` = 29 .gd resmi dari `game/` (9 berbeda dari b10: layar_local_play, pemain, pemain_dasar, pemain_duel, pemain_kartu, profil_pemain, status_jaringan, ui_dinamis, ui_profil). Pemilik: buang unduhan lama, TIMPA ke-29 file, buka Godot, tunggu impor.
  - **DAFTAR UJI HP b11 (butuh 2 HP; HP-A = build b11, HP-B = b11 juga; satu HP lagi dgn build LAMA b10 untuk uji ke-6):**
    1. Nama: ubah nama di menu (mis. "Andi" dan "Budi"); HP-A buat room, HP-B gabung -> lobby tampil "Andi Lv N" & "Budi Lv N" di kedua HP (nama & level benar).
    2. Level: mulai laga Quick -> teks giliran, papan skor, layar akhir memakai nama + "Lv N" yang sama di kedua HP; solo/AI tetap "P2"/"Enemy".
    3. MVP: akhir laga -> tepat satu baris bertanda "MVP", sama di kedua HP; buka Profile: MVP total +1 hanya di HP pemilik MVP (solo juga dihitung).
    4. Respect: di layar akhir ketuk "RESPECT" pada baris lawan manusia -> tombol nonaktif (1x per lawan per laga); HP lawan muncul toast "<nama> gave you Respect!"; Respect di Profile lawan +1. Tidak ada tombol untuk AI/diri sendiri. Layar 4 pemain (kalau ada 3-4 HP): baris & tombol tidak terpotong.
    5. Kartu profil: ketuk nama di lobby dan di baris layar akhir -> popup nama, level, Respect, MVP, role terakhir; tutup normal, tidak menutupi tombol penting.
    6. Versi beda ditolak: HP dgn build LAMA (b10, atau versi Play) gabung ke room HP b11 (dan sebaliknya) -> muncul "Please update the game to play together." (client lama ke host baru: diputus <=4 dtk; client baru ke host lama: pesan dalam 6 dtk); host b11 tidak ikut macet, bisa membuka room lagi.
    7. Profil lama utuh: timpa di atas versi lama -> Crowns/XP/role tidak hilang, Respect & MVP mulai 0.
    Laporkan angka/teks yang aneh; bug -> Opus dulu.
- 03-10 (pemilik): **uji HP b11 LOLOS** (semua butir daftar berhasil) -> **Fase 6 SELESAI**. Berikutnya: Fase 7 G0 (OPUS: tabel harga katalog, bagian 2.1).
- 03-10 (Opus): **F7 G0 SELESAI** -- tabel katalog & harga FINAL di bagian 2.1 (tanpa simulasi). Basis 50 Crowns/laga Quick "efektif" (dasar ~40/laga + login ~61/hari + misi <=95/hari).
  24 barang: pawn 8 (0/150/300/500/800/1200/2000/3500), title 10 (0/150/300/400/600/900/1200/1800/2600/3500), frame 6 (0/250/700/1200/2200/3500); syarat Lv 5-15 pada barang mahal; total 27 750.
  Keputusan: warna bidak = TRIM (sarung tangan/sepatu), warna badan tetap warna slot (identitas pemain & petak). Barang AWAL selalu dimiliki; beli = langsung dipakai; tanpa refund; host validasi id & jenis saja.
  Berikutnya: **G1 (Sonnet)** `data_kosmetik.gd` + profil v4 + beli/pakai + uji headless.
- 03-10 (Sonnet): **F7 G1 SELESAI** (bukti `hasil/g7_kosmetik/`). `game/data_kosmetik.gd` BARU (`class_name DataKosmetik`; `KATALOG` 24 barang persis tabel 2.1, `AWAL`, `JENIS`, helper `ada/jenis_dari/daftar/sah_untuk_jenis` -- yang terakhir untuk validasi host di G3). Data tampilan: pawn `warna`(+`emisi`/`logam`/`kasar`), frame `border/lebar/bayangan/bayangan_ukuran/radius_tambah`.
  `profil_pemain.gd` VERSI 4: `kosmetik_dimiliki` (barang AWAL tidak disimpan), `kosmetik_dipakai` {jenis: id}, bagian berkas "kosmetik"; muat membuang id tak dikenal/duplikat/AWAL/salah jenis/tak dimiliki dan tipe salah. API: `punya_kosmetik`, `kosmetik_pakai(jenis)`, `alasan_tolak_beli(id)` (teks tombol G2: "Reach Lv N" / "Need N more Crowns"), `beli(id)` -> "" bila berhasil (Crowns berkurang, langsung dipakai, simpan sekali) atau alasan tolak, `pakai(id)` (AWAL = kembali bawaan).
  Bukti: `uji_kosmetik.gd` (rig-only) 33/33 (katalog 24/8-10-6/total 27 750; migrasi v3 utuh; kurang Crowns/level/id/beli ganda/barang AWAL ditolak; simpan-muat; data rusak; Crowns tidak negatif); `uji_profil_v3` 0 gagal (cek VERSI dilonggarkan jadi == P.VERSI); `cek_muat_f3` 26/26; 0 SCRIPT ERROR. TIDAK ada perubahan jaringan/RPC/aturan main. Catatan rig: setelah menambah `class_name` baru WAJIB `--import` ulang (cache kelas global) sebelum menjalankan uji.
  Berikutnya: **G2 (Sonnet)** layar SHOP (`ui_toko.gd`) + tombol menu (ganti teks "Crowns will unlock items soon.").
- 03-10 (Sonnet): **F7 G2 SELESAI** (bukti `hasil/g7_kosmetik/`: `uji_toko.txt`, `toko_pawn/title/frame.png`). `game/ui_toko.gd` BARU (`class_name UiToko`, `buka_toko(induk, tab)`): kartu di tengah-atas (layer 12, node `PanelToko`), judul SHOP, baris "CROWNS n | Lv n", tab PAWN/TITLE/FRAME, daftar bergulir (330 px; muat di 1280x720), tiap baris = pratinjau 64x64 (pawn: lingkaran warna trim + kilau; title: "Aa"; frame: kotak berbingkai) + nama + harga/"Owned"/"(Lv N)" + tombol BUY / EQUIP / EQUIPPED; barang terkunci tetap terlihat (tombol BUY abu-abu, alasan merah "Reach Lv N"/"Need N more Crowns" dari `alasan_tolak_beli`); ketuk BUY terkunci menampilkan pesan, tidak membeli.
  Pintu masuk: teks "Crowns will unlock items soon." di panel PROFILE diganti tombol **SHOP**; tombol **SHOP** juga di menu utama (kanan atas, tepat di bawah MISSIONS; `main_menu.gd` var `tombol_toko`, ikut dinonaktifkan/memudar saat START).
  Bukti: `uji_toko` 21 cek 0 gagal (buka, tab, BUY ditolak/berhasil, EQUIP, CLOSE, tombol di Profile & menu); `cek_muat_f3` 27/27 (+ui_toko.gd); `uji_kosmetik` 33/33; tangkapan layar nyata via xvfb + `--rendering-driver opengl3` (`uji_toko_foto`, rig-only) -- layout muat, pratinjau terbaca. `game/` & rig identik (beda hanya stub iklan). Tanpa jaringan/RPC.
  BELUM teruji: tampilan di HP nyata (ketuk/gulir sentuh), tombol SHOP di menu vs elemen lain di HP berlayar sempit -> uji HP G5. Berikutnya: **G3 (Sonnet)** kosmetik tampil di HP sendiri & teman (payload F6.1 + `kosmetik_dipakai`; cabang trim di `_warnai_karakter`; gelar di lobby/papan/kartu profil; bingkai di `tampilkan_kartu_profil`).
- 03-10 (Sonnet): **F7 G3 SELESAI** (bukti `hasil/g7_tampil/`: `uji_kosmetik_tampil.txt` 33/33, `cek_muat_f3.txt` 27/27, `mp/` = log Q1 & M2).
  - Jaringan: `kosmetik` ({pawn,title,frame}) ditambah ke payload profil lobby F6.1 (`_profil_saya`); host `_profil_sah` -> `DataKosmetik.sah_semua` (id tak dikenal/jenis salah/bukan string -> AWAL; HP lama tanpa field -> AWAL). Dictionary yang sudah ada -> TANPA RPC baru, `VERSI_PROTOKOL` tetap 2 (b11 & b12 tetap bisa main bersama, kosmetik b11 = AWAL). Salinan di `StatusJaringan.profil_slot` semua HP -> aman untuk migrasi host.
  - Trim bidak: `_warnai_karakter(model, warna, id_pawn)` + `_terapkan_trim` (albedo, emisi, logam/kasar sesuai katalog). Badan tetap warna slot. Penilaian pakai bahan ASLI mesh (`mesh.mesh.surface_get_material`), bukan override: temuan MP -- slot 3-4 = `musuh.duplicate()` yang sepatunya sudah ber-trim jenuh (Lava) lolos tes "badan merah" dan ikut dicat warna slot; diperbaiki + uji regresi. Trim hanya bahan putih/abu terang (s<0.2, v>0.3).
  - Tampil: gelar di lobby (baris kecil bawah nama), layar akhir/papan skor (`_gelar_manusia`), kartu profil; bingkai di `UiProfil.tampilkan_kartu_profil` (`_gaya_bingkai`: border, lebar, bayangan, radius sesuai tabel 2.1). Solo: slot 0 = profil sendiri, AI = AWAL.
  - Bukti MP (rig `uji_robot_mp.gd` +kosmetik per robot, log `KOSMETIK_UJI` per slot: id, gelar, warna sepatu/badan model): Q1 1v1 (cek_ok=10) dan M2 4P host keluar -> migrasi (cek_ok_migrasi=4): 0 beda, 0 SCRIPT ERROR; baris kosmetik identik di semua HP awal/akhir/sesudah migrasi; client3 sengaja mengirim id rusak -> AWAL di semua HP.
  - **UPDATE 03-10: pemilik mengirim `beras.glb` -> bahan asli: badan merah, tangan putih, SEPATU HITAM (bukan abu). Filter trim jadi s<0.2 saja; `uji_kosmetik_glb` 4/4 (hasil/g7_tampil/uji_kosmetik_glb.txt) membuktikan tangan+sepatu terwarnai, badan tetap warna slot. Temuan di bawah terjawab; tinggal cek visual di HP (G5).**
  - (Temuan awal:) model .glb asli TIDAK ada di repo; rig memakai stand-in (badan + sepatu abu, tanpa sarung tangan). Sarung tangan putih + sepatu abu terwarnai di model asli belum terbukti di cloud (dasar: komentar lama di kode). Cek saat uji HP G5; kalau tidak layak -> Opus memutuskan (badan TIDAK diganti).
  - BELUM: tampilan nyata di HP (gelar di lobby 4 pemain tidak terpotong, bingkai di kartu, warna trim di model asli). Berikutnya: **G4 (Sonnet)** `pengelola_pembelian.gd`.
- 03-10 (Sonnet): **F7 G4 SELESAI** (bukti `hasil/g7_pembelian/`: `uji_pembelian.txt` 27/27, `solo_bebas0_*`/`solo_bebas1_*`, `cek_muat_f3.txt`).
  - `game/pengelola_pembelian.gd` BARU (autoload `PengelolaPembelian`). Plugin dipakai lewat singleton "GodotGooglePlayBilling" (API diperiksa dari sumber godot-sdk-integrations/godot-google-play-billing: sinyal `connected`, `query_product_details_response`, `query_purchases_response`, `on_purchase_updated`, `acknowledge_purchase_response`; `purchase(id, opsi, offer, personalisasi)`; `queryPurchases(jenis, suspended)`; kunci pembelian `product_ids`, `purchase_state` (1 = dibeli, 2 = tertunda), `is_acknowledged`, `purchase_token`) -- TANPA mengacu kelas plugin, jadi tanpa plugin skrip tetap terkompilasi = mode stub (beli -> "Store is not available on this device.").
  - Alur: start -> cadangan profil (`remove_ads`) langsung diterapkan -> kalau ada plugin: sambung, query produk (harga) + query pembelian = restore otomatis (daftar kosong = dicabut/refund; query GAGAL = cadangan dipertahankan). Pembelian dibeli & belum di-acknowledge = BARU: bonus 500 Crowns sekali per profil (`ambil_bonus_remove_ads`) + `acknowledgePurchase` (dicoba lagi tiap start bila gagal; bonus tidak dobel). Pending tidak dihitung. Kode 1 = "Purchase cancelled.", kode 7 = sinkron lewat query.
  - `bebas_iklan` = true mematikan interstisial + app open (logika lama) + banner (BARU: `tampilkan_banner` return; banner yang sedang tampil disembunyikan). Iklan berhadiah tetap. (Banner TIDAK disebut eksplisit di K5; dimatikan karena pembeli "Remove Ads" tidak akan mengharapkan banner -- mudah dikembalikan, hapus 2 baris.)
  - `profil_pemain.gd`: bagian berkas "pembelian" (`remove_ads`, `bonus_diambil`), VERSI tetap 4 (berkas lama aman: default false); disalin identik ke rig.
  - Rig: stub autoload `pengelola_pembelian.gd` (rig-only), `pembelian_asli_uji.gd` = salinan file asli, `uji_pembelian` 27/27 dgn plugin TIRUAN (beli+ack+bonus sekali, restore tanpa bonus, bonus tidak dobel, query gagal tidak mencabut, refund mencabut lalu interstisial tayang lagi, batal, pending, gagal langsung, kode 7, beli saat sudah punya, putus sambungan); stub iklan +`bebas_iklan`/`jumlah_banner`; `uji_nyata` opsi `bebas_iklan=1`: solo Quick 4P x2 `interstisial=0 banner=0` + `PROFIL_CEK OK` (pembanding tanpa opsi: 1/1); solo smoke autoload baru 0 SCRIPT ERROR; `cek_muat_f3` 28/28; `uji_profil_v3`, `uji_kosmetik`, `uji_toko` 0 gagal.
  - TIDAK diuji / tugas pemilik: daftar autoload `PengelolaPembelian` di `project.godot` proyek asli (game/ tidak membawa project.godot), pasang plugin Play Billing, buat produk `remove_ads` (non-consumable) di Play Console, akun penguji lisensi, uji beli di Internal testing (cek status setelah 5 menit & setelah buka ulang). `ID_INTERSTISIAL_ASLI` masih kosong. BELUM ADA tombol beli di UI (API siap: `beli_remove_ads()`, `pembelian_selesai`, `harga_remove_ads()`, `restore()`).
  - Berikutnya: **G5 (Sonnet)** -- tombol Remove Ads (usulan: baris di `ui_toko.gd`; konfirmasi pemilik), regresi MP 37 sekali, `cek_nilai`, bersih-bersih, ZIP b12 (32 .gd resmi).
- 03-10 (Sonnet): **F7 G5 SELESAI** (bukti `hasil/g7_pembelian/`: `uji_toko_iklan` lewat rig, `mp/mp_ringkas.txt`, `cek_nilai.txt`, `toko_*_g5.png`).
  - Keputusan pemilik: banner ikut mati saat Remove Ads; tombol beli di UI. `ui_toko.gd`: baris REMOVE ADS (BUY harga dari Play + RESTORE; setelah punya = "Ads removed. Thank you!"), pesan sukses hijau; `PengelolaPembelian` dicari lewat pohon, jadi tanpa autoload toko tetap jalan tanpa baris itu. Daftar 330 -> 260 px (muat 1280x720). `uji_toko_iklan` 9/9, `uji_toko` 0 gagal (hitungan BUY dikurangi 1 baris iklan), `cek_nilai` 8/8, `cek_muat_f3` 28/28.
  - Regresi MP 37 skenario SEKALI (K8): 99 baris SELESAI, 0 MACET/scripterr/beda/cek_gagal (G8: 97; +2 di D4 & M5 = host keluar saat pilih elemen, variasi timing). Rig disiapkan di scratchpad (`/tmp/sp`: skrip A/B disalin dengan path diganti, `proj` = symlink `rig/proj_tanpa_uji`), A lalu B berurutan ~1 jam di 4 inti.
  - `kiriman/TileDuel_Fase7_b12.zip` = 33 .gd (beda dari b11: +data_kosmetik, +ui_toko, +pengelola_pembelian, +pengelola_iklan [banner], ~layar_local_play, main_menu, pemain, pemain_dasar, profil_pemain, ui_dinamis, ui_profil), byte-per-byte = `game/`.
  - **DAFTAR UJI HP b12:** (1) TOKO: menu utama & PROFILE -> SHOP terbuka; baris REMOVE ADS tidak terpotong, tombol bisa diketuk (HP layar sempit). (2) Beli barang (Crowns cukup): Crowns berkurang, langsung dipakai; barang terkunci menampilkan alasan. (3) Kosmetik di HP teman (2 HP, keduanya b12): warna sarung tangan/sepatu, gelar di lobby/layar akhir, bingkai di kartu profil; badan tetap warna slot; model asli `beras.glb` trim tampak wajar. (4) HP b11 + HP b12 main bersama: tetap bisa (VERSI_PROTOKOL sama), kosmetik b11 = bawaan. (5) REMOVE ADS di build Internal testing, akun penguji lisensi: tombol menampilkan harga; beli -> pesan "Thank you! Ads removed. +500 Crowns", banner hilang, tidak ada interstisial sesudah laga, tidak ada app open saat kembali dari latar; iklan berhadiah (WATCH AD) tetap ada. Cek lagi setelah 5 menit & setelah tutup-buka aplikasi (status tetap, tidak dobel bonus). (6) Reinstall/HP lain + tombol RESTORE: Remove Ads pulih TANPA bonus 500 lagi di pembelian yang sudah di-acknowledge. (7) Batalkan pembayaran: pesan "Purchase cancelled.", tidak ada perubahan. (8) Profil lama utuh setelah timpa. Laporkan angka/teks aneh; bug -> Opus dulu.
  - **Fase 7 selesai di sisi kode; menunggu uji HP pemilik + rilis.** Berikutnya Fase 8 (RENCANA_fase6_9 bagian 3; G0 Opus bila perlu) setelah b12 diuji.
- 03-10 (Opus): **F8 G0 SELESAI** (bukti `hasil/g8_event/`: `uji_event.txt` 0 gagal (34 cek), `cek_muat_f3.txt` 30/30, `uji_kosmetik.txt` 0 gagal; `uji_profil_v3`, `uji_toko` 0 gagal). Uji HP b12 LOLOS semua (laporan pemilik). Angka FINAL di bagian 3.1.
  - `game/data_event.gd` BARU (`class_name DataEvent`): 6 event, misi elemen/duel, minggu dari tanggal (Senin; hitung minggu sejak 1970-01-05, aman di 52/53->1), sisa waktu, tabel mastery. `data_kosmetik.gd`: +18 barang event + 5 gelar mastery (`sumber`), `daftar(jenis, sumber="")`, `sumber_dari`, `daftar_event`. `profil_pemain.gd` VERSI 5: `token_event`, `misi_event`, `minggu_event`, `tanggal_maks`, `mastery` (bagian berkas "event"/"mastery"; berkas v4 -> nilai awal, data lama utuh; data rusak disaring), `segarkan_event()` (dipanggil di `_ready`), `tanggal_mundur()`, `event_sekarang()`, `xp_mastery()`; `alasan_tolak_beli` menolak barang event/mastery di toko Crowns.
  - Rig: file di atas disalin identik; `uji_event.gd/.tscn` (rig-only); `uji_kosmetik` dihitung atas barang toko Crowns saja + cek VERSI pakai `P.VERSI`; `cek_muat_f3` +`data_event.gd`, `data_kosmetik.gd`. Tanpa jaringan/RPC/aturan main.
  - **G1 (Sonnet) -- tugas persis:** (1) `catat_akhir_match`: `segarkan_event()` di awal; kalau `not tanggal_mundur()` -> `_majukan_misi_event(st, menang, role)` (stat `_match_role`/`_menang_role` = role == elemen event; `_duel_elemen` = `st.menang_elemen[elemen]`; lainnya `st[stat]`), misi selesai -> `token_event += token`; mastery SELALU (tanpa cek tanggal): role sah -> +1 (+2 bila menang) ke `mastery[role]`, tiap elemen `menang_elemen[el]` x1; naik level -> Crowns `CROWNS_LEVEL`, Lv 10 -> gelar `GELAR_MASTERY[el]` masuk `kosmetik_dimiliki` (tidak otomatis dipakai). Kembalikan `misi_event_selesai`, `token_event_didapat`, `mastery_naik` [{elemen, level, crowns, gelar}] di ringkasan. `tambah_double` TIDAK menggandakan token/mastery. (2) `alasan_tolak_beli_event(id)` + `beli_event(id)`: hanya `sumber` "event", `event` == `event_sekarang().id`, tidak `tanggal_mundur()` ("Event paused: check your date"), token cukup ("Need N more tokens"); berhasil = token berkurang, dimiliki, langsung dipakai. (3) uji headless rig `uji_event_g1`: laga palsu solo & MP (role api, menang, menang_elemen) memajukan misi & mastery yang benar; tanggal mundur = misi tidak maju tapi mastery maju; beli event di minggu lain ditolak. Lalu G2 UI (EVENT + tab EVENT di SHOP + mastery di PROFILE).
  - **G1 SELESAI (Sonnet, 03-10; bukti `hasil/g8_event_g1/`):** `catat_akhir_match` (+`segarkan_event`, `_majukan_misi_event`, `_majukan_mastery`), `alasan_tolak_beli_event`, `beli_event` di `profil_pemain.gd` (hanya file ini berubah di `game/`, disalin identik ke rig). `uji_event_g1` (rig-only) 0 gagal; uji lama 0 gagal; `cek_muat_f3` 30/30. Catatan: stat `bounty` tidak ada di `STAT_SEUMUR` tetapi dibaca langsung dari `st` (statistik_slot) -> tidak ikut statistik seumur. Berikutnya G2 UI.
  - **G2 + G4 SELESAI (Sonnet, 03-10; bukti `hasil/g8_event_g2/`):** UI EVENT/MASTERY (`ui_event.gd` baru), tab EVENT di SHOP, tombol EVENT di menu, MASTERY di PROFILE, baris kartu hadiah. `uji_event_foto` 11/11, uji lama 0 gagal, `cek_muat_f3` 31/31, solo nyata 0 SCRIPT ERROR. `kiriman/TileDuel_Fase8_b13.zip` = 35 .gd (byte-per-byte = `game/`). G3 (Opus) dilewati. **Fase 8 selesai di sisi kode; menunggu uji HP pemilik (daftar di HANDOFF 5 entri "FASE 8 G2 + G4") + rilis.** Berikutnya Fase 9 (bagian 4).
- 03-10 (Sonnet): **F9 G0 + G1 SELESAI** (bukti `hasil/g9_tebak/`, `kiriman/TileDuel_Fase9_b14.zip`). Detail di HANDOFF 5 (entri "FASE 9"). G2 Opus dilewati (kredit). Menunggu uji HP b14 + rilis.
