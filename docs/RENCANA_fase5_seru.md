# RENCANA FASE 5: Seru dalam pertandingan

Disusun Opus, 02-10-2026 (sesi Claude Code cloud), setelah membaca kode `game/` (hasil Fase 4 = isi ZIP b9).
**STATUS: DISETUJUI 02-10 -- pemilik: "setuju semua a" (K1-K10 = a). Rencana DIKUNCI. G0-G7 SELESAI (lihat bagian 9). Berikutnya: G8 keseimbangan (OPUS), lalu G9.**

Sumber isi: dokumen "Rancangan Tile Duel: Retensi, Monetisasi & Role Elemen" (Fase 5 = Tebak Duel, event papan,
bounty, bantuan posisi terakhir, animasi cepat; syarat lolos "semua HP melihat event yang sama") +
`RENCANA_fase1_iklan_quick.md` K2 (putar ulang rolet setelah kalah duel solo DITUNDA ke Fase 5) dan baris 817
(event papan tiap 2 ronde Quick / 3 Classic) + `RENCANA_fase2_profil*.md` (XP Tebak Duel -> Fase 5).

ATURAN USER yang tetap berlaku: balas Bahasa Indonesia; teks pemain = bahasa Inggris sederhana; edit hanya
baris/bagian relevan; RNG permainan lewat `mesin_acak` (host/solo) -- JANGAN randi()/randf()/pick_random()
global; `ai_*.gd` hanya BACA state; FPS prioritas (setiap efek baru punya versi Very Low); saklar `UJI_*` false
di produksi; kirim SET LENGKAP sekaligus; `rig/` = angka uji, `game/` = produksi; jangan salin stub iklan rig ke
`game/`; satu rantai simulasi saja, jangan ubah `rig/` selama simulasi berjalan.

**Hubungan dengan rilis A+B:** rilis memakai `kiriman/TileDuel_FaseB_b9.zip` (tetap tersimpan di repo). Kode
Fase 5 baru mengubah `game/` SETELAH rencana ini disetujui; itu tidak mengganggu rilis b9.

## 0. Ringkas

Enam fitur kecil di DALAM pertandingan, semuanya sama untuk semua pemain dan tidak bisa dibeli:

| # | Fitur | Mode | Mengubah hasil pertandingan? |
|---|---|---|---|
| 1 | Event papan (4 jenis, berkala) | solo + multiplayer | ya, sama untuk semua |
| 2 | Bounty (target kecil, hadiah +1 bintang) | solo + multiplayer | ya, sedikit |
| 3 | Kartu bantuan posisi terakhir (saat lewat START) | solo + multiplayer | ya, sedikit (penyeimbang) |
| 4 | Tebak Duel (penonton menebak pemenang) | penonton duel | tidak -- hanya XP/Crowns profil |
| 5 | Putar ulang rolet duel setelah kalah (iklan berhadiah) | solo saja | ya, hanya bagi yang menonton iklan (solo vs AI -- prinsip "kekuatan boleh di solo") |
| 6 | Tombol AI cepat (animasi giliran AI dipercepat) | solo saja | tidak |

Fitur 1-3 mengubah ekonomi pertandingan AI-vs-AI -> keseimbangan role (P14, Fase 4) WAJIB dicek ulang di rig.

## 1. Keputusan (DISETUJUI pemilik 02-10: semua "a" -- yang berlaku = pilihan a di setiap K)

- **K1. Daftar event.** a) GOLD RUSH (denda petak x2), MARKET DAY (harga beli petak & menara -30%), EARTHQUAKE
  (satu menara acak -1 HP, tidak pernah hancur), **STAR SHOWER** (semua pemain +1 bintang, maks 10) -- menggantikan
  "Storm! (semua jebakan terlihat)" di dokumen rancangan, karena di kode semua jebakan SUDAH terlihat (hanya
  jebakan petir Ultimate `stealth_charge` yang tersembunyi), jadi Storm hampir tidak berefek.
  b) tetap Storm = membuka jebakan petir siluman saja. c) hanya 3 event (tanpa pengganti Storm).
- **K2. Jadwal event.** a) Quick: tiap 2 ronde mulai ronde 3 (2P 8 ronde -> ronde 3, 5, 7; 3P/4P -> 3, 5);
  Classic: tiap 3 ronde mulai ronde 4 (4, 7, 10, ...). Event berlaku SATU ronde (setiap pemain tepat satu giliran).
  b) tiap 3 ronde di semua mode (dokumen rancangan).
- **K3. Kekuatan event (angka awal, boleh disetel Opus setelah uji rig).** a) Gold Rush x2, Market Day -30%,
  Earthquake -1 HP (HP minimal 1), Star Shower +1. b) lebih lunak: Gold Rush x1,5, Market Day -20%.
- **K4. Bounty.** a) Satu bounty aktif: "First to win a duel with WATER gets +1 Star" (elemen diundi, tidak sama
  dengan bounty sebelumnya). Bounty pertama di ronde 2; setelah diklaim, bounty baru muncul di ronde event
  berikutnya. AI juga bisa mengklaim (tanpa logika khusus). b) tanpa bounty di Fase 5.
- **K5. Kartu bantuan posisi terakhir.** a) Saat lewat START: kalau pemain itu kekayaannya (koin + nilai petak,
  rumus Quick yang sudah ada) PALING RENDAH dan tertinggal >= 1000 dari yang terkaya, ia dapat 1 kartu acak
  (LOW ROLL / HIGH ROLL / SHIELD / SWORD Lv1 -- daftar `KARTU_HADIAH_IKLAN`). Inventaris penuh (3) = tidak dapat.
  Semua mode. b) hanya 3-4 pemain. c) tanpa fitur ini.
- **K6. Tebak Duel.** a) Hanya untuk pemain MANUSIA yang menonton duel (bukan peserta): solo 3-4 pemain (duel AI
  vs AI) dan multiplayer. Dua tombol nama peserta selama fase pilih elemen; satu ketukan, tidak bisa diubah, boleh
  tidak menebak. Permainan TIDAK PERNAH menunggu tebakan. Tebakan benar = +5 XP & +3 Crowns profil, maks 5 tebakan
  benar dihitung per pertandingan (tidak ikut DOUBLE). Tebakan tidak diperlihatkan ke pemain lain.
  b) sama, tapi tebakan diperlihatkan ("P3 bets on P2").
- **K7. Putar ulang rolet.** a) Solo saja, sekali per pertandingan, hanya saat pemain manusia KALAH karena skor
  (bukan karena lempar koin seri). Tombol "WATCH AD: SPIN AGAIN" muncul di layar skor duel; kalau iklan ditonton
  sampai habis, HANYA rolet pemain diputar ulang (elemen tetap), skor dihitung ulang (bisa menang, seri -> lempar
  koin seperti biasa, atau tetap kalah). Ikut batas 8 iklan berhadiah per hari. b) boleh juga setelah kalah lempar koin.
- **K8. Tombol AI cepat.** a) Solo saja: tombol kecil ">>" di HUD; kalau aktif, giliran AI berjalan 2x (Quick:
  2x, bukan 1,5x) selama layar duel/pilihan pemain tidak tampil. Pilihan diingat di profil. Bawaan MATI.
  b) juga di multiplayer bagi host (giliran AI). -- tidak disarankan: semua HP ikut terpengaruh.
- **K9. Uji keseimbangan ulang.** a) Setelah fitur 1-3 jadi: rig U9 S1 (1200, 2P) + S2 (400, 4P) + S5 (panjang)
  di benih BARU; syarat P14 sama (2P tiap role 44-56%, 4P 20-30%, jebakan/AI 2-6, panjang Quick di bawah batas).
  Kalau gagal, yang disetel angka EVENT/bounty/bantuan (K3/K5), bukan angka role F5. b) tanpa uji ulang.
- **K10. Pengiriman.** a) Satu kiriman di akhir Fase 5 (ZIP b10, set lengkap) untuk uji HP, lalu rilis.
  b) dua kiriman (1-3 dulu, lalu 4-6).

## 2. Fakta kode yang menentukan rancangan (dibaca Opus 02-10)

1. **Host-otoritatif.** `ganti_giliran()` / `_mulai_giliran()` (pemain.gd) hanya berjalan di host/solo. Client
   menyamakan papan lewat `_siarkan_state_giliran` -> `rpc_terima_state_giliran` (pemain_jaringan.gd, Dictionary;
   field baru cukup ditambah dengan `data.has()` di sisi penerima). Host baru (migrasi) melanjutkan dari state itu.
2. **Ronde hanya dihitung di Quick** (`batas_ronde > 0 and slot == 0` di `ganti_giliran`). Classic butuh penghitung
   ronde sendiri untuk jadwal event (jangan pakai `ronde_sekarang` -- label ROUND x/y Quick membacanya).
3. **Denda petak ditulis ulang di 6 tempat** (100/300/600): `_bayar_denda` (pemain_papan.gd), teks tombol Give Up/
   Fight (pemain.gd `periksa_status_petak`), `ai_musuh.gd` (2 tempat), `ai_jebakan._denda_petak`, label petak
   (pemain_tampilan.gd baris ~357). Gold Rush butuh SATU fungsi pusat.
4. **Harga beli** `harga_tanah`/`harga_menara_lv1/lv2` (pemain_dasar.gd) juga dipakai untuk NILAI aset (kekayaan
   Quick, jual aset/hutang). Market Day hanya boleh mengubah harga BELI -> fungsi `harga_beli_*()` baru; variabel
   lama tetap = nilai aset.
5. **Jebakan semua terlihat**, kecuali jebakan petir `siluman` (stealth_charge, `_terapkan_siluman`) -> K1.
6. **HP petak** = `nyawa_petak[i]` (3/4/5 menurut menara, serangan jarak jauh -1, hancur di 0).
7. **Duel**: solo manusia ikut duel -> `ui_elemen.jalankan_duel` alur asli (rolet diundi `ui_elemen.rng`, AI memilih
   elemen di dalamnya). Penonton/AI-vs-AI/multiplayer -> NASKAH (`_kumpulkan_naskah_duel` di host,
   `_naskah_duel_ai` di solo) lalu diputar di semua layar. Penonton multiplayer dikabari `rpc_duel_dimulai`.
   Host sedang menunggu pilihan elemen = `_duel_mengumpulkan == true`; nomor duel `_nomor_duel`.
8. **Statistik per slot** `_tambah_stat()` hanya di host/solo, ikut siaran state ("statistik") -> profil di akhir
   (`ProfilPemain.catat_akhir_match`). Kunci baru: tambahkan juga ke `statistik_kosong()`.
9. **Iklan berhadiah**: pola `_tawarkan_iklan_hutang` (pemain_papan.gd) -- `PengelolaIklan.rewarded_tersedia()` lalu
   `await PengelolaIklan.tonton_rewarded()`; stub rig (`uji_rewarded`) bawaan false -> jejak rig tidak berubah.
10. **Kartu hadiah**: `_kartu_hadiah_acak()` (pemain_kartu.gd) memakai pengacak SENDIRI (sengaja, untuk iklan).
    Kartu bantuan K5 berlaku di multiplayer -> WAJIB diundi `mesin_acak` di host (inventaris ikut siaran "kartu").
11. **Kecepatan**: `_atur_kecepatan_permainan()` -- Quick 1,5x; Classic tidak pernah menyentuh `Engine.time_scale`
    (rig memakai skala dasar 3). Tombol AI cepat bawaan MATI -> rig tidak berubah.
12. Spanduk siap pakai: `UiDinamis.tampilkan_spanduk(self, teks, warna)` (2D, ringan -- aman di Very Low).

## 3. Rancangan per fitur (asumsi K = a)

### 3.1 Event papan
- State baru (pemain_dasar.gd): `ronde_event := 1` (naik setiap giliran kembali ke slot 0, SEMUA mode),
  `event_aktif := ""` ("" / "gold_rush" / "market_day"), `event_terakhir := ""`.
- Di `ganti_giliran()` saat `slot == 0` (setelah blok Quick yang sudah ada, termasuk kalau pertandingan berakhir
  karena ronde habis -> tidak ada event): `ronde_event += 1`; `event_aktif = ""`; kalau ronde ini jadwal event (K2)
  -> `_mulai_event_papan()`:
  - pilih dari 4 event dengan `mesin_acak`, tidak sama dengan `event_terakhir`;
  - EARTHQUAKE: calon = petak bermenara (`level_menara_petak >= 1`) dengan `nyawa_petak > 1`; kalau kosong ->
    petak dimiliki dengan HP > 1; kalau kosong -> "The ground shakes. No damage." Pilih dengan `mesin_acak`, HP -1.
  - STAR SHOWER: semua slot `bintang = mini(bintang + 1, 10)`.
  - GOLD RUSH / MARKET DAY: `event_aktif` = id-nya sampai ronde berikutnya.
  - Spanduk + siaran `rpc_event_papan(id, data)` ke client (hanya tampilan); state ikut `_siarkan_state_giliran`
    ("event": {"ronde_event", "aktif", "terakhir"}) supaya client & host baru (migrasi) sama.
- Fungsi pusat (pemain_dasar.gd): `denda_petak(posisi) -> int` (100/300/600 x 2 kalau gold_rush) dan
  `harga_beli_tanah()/harga_beli_menara(lv) -> int` (x0,7 kalau market_day, dibulatkan ke 10). Semua tempat di
  fakta 3 & tempat BELI di fakta 4 diganti memanggilnya (ai_*.gd memanggil = membaca, aman P1).
- HUD: label kecil di bawah label ronde selama event: "GOLD RUSH: tile fees x2" / "MARKET DAY: -30% prices".
  Spanduk: "GOLD RUSH!", "MARKET DAY!", "EARTHQUAKE!", "STAR SHOWER!" + baris kedua di `teks_dadu`
  ("Tile fees x2 this round!", "Tiles and towers -30% this round!", "P2's tower lost 1 HP!", "Everyone gets +1 Star!").
- Very Low: hanya spanduk 2D; Earthquake boleh getaran kamera singkat yang SUDAH ada, dilewati di Very Low.

### 3.2 Bounty
- State: `bounty_elemen := ""`, `bounty_terakhir := ""` (ikut siaran state "bounty").
- Mulai ronde 2 (dan di setiap ronde event kalau tidak ada bounty aktif): elemen diundi `mesin_acak`, tidak sama
  dengan `bounty_terakhir`. Spanduk "BOUNTY!" + teks "First to win a duel with WATER: +1 Star". HUD: "BOUNTY: WATER duel".
- Klaim: di `_hasil_duel_petak` / `eksekusi_dadu_pertarungan` (host/solo), pemenang duel dengan `elemen_pemenang ==
  bounty_elemen` -> +1 bintang (maks 10), `_tambah_stat(slot, "bounty")`, teks "P2 claimed the BOUNTY! +1 Star",
  `bounty_elemen = ""`.

### 3.3 Kartu bantuan posisi terakhir
- Di blok "LOGIKA MELEWATI START TILE" (pemain.gd `bergerak_maju`, host/solo): kalau syarat K5 terpenuhi ->
  kartu = acak `mesin_acak` dari kartu `database_efek` yang id-nya ada di `KARTU_HADIAH_IKLAN` (pola
  `_kartu_hadiah_acak`, tapi pengacaknya `mesin_acak`) -> `inventaris_kartu.append`. Teks
  "COMEBACK CARD! P3 got LOW ROLL". `_tambah_stat(slot, "kartu_bantuan")`. Sampai ke client lewat siaran "kartu"
  + teks lewat RPC tampilan yang sudah ada atau RPC kecil baru.
- AI sudah memakai kartu simpanan (`ai_musuh.gd` membaca `inventaris_kartu`) -> tidak perlu logika AI baru.

### 3.4 Tebak Duel
- Kapan: manusia lokal BUKAN peserta duel. Solo: `_tonton_ai_pilih_elemen` (jendela ~2,5 dtk). Multiplayer:
  layar tonton dibuka `rpc_duel_dimulai`; jendela sampai host mengirim naskah (`_duel_mengumpulkan` jadi false).
- UI (ui_elemen.gd, mode tonton): judul "WHO WINS?" + 2 tombol nama peserta ("P2" / "P3", atau "ENEMY" di 2 pemain
  -- tidak terjadi karena 2P selalu peserta). Setelah ketuk: "Your guess: P2" (tombol hilang).
- Jaringan: client -> host `rpc_kirim_tebakan(slot_ditebak)`; host menerima hanya kalau pengirim bukan peserta,
  `_duel_mengumpulkan` masih true, dan belum menebak di duel ini; host membalas `rpc_tebakan_diterima(ok)`
  ("Too late!" kalau ditolak). Host-penonton: dicatat langsung. Simpanan host: `_tebakan_duel: Dictionary` (slot ->
  slot ditebak), dikosongkan di awal `_kumpulkan_naskah_duel`.
- Hasil: setelah pemenang duel diketahui (host/solo), tiap tebakan benar -> `_tambah_stat(slot, "tebak_benar")`.
  Tiap layar penonton menampilkan "Good guess!" / "Wrong guess." (hasilnya bisa dihitung lokal dari naskah).
- Profil: `catat_akhir_match` + `xp_tebak = 5 * mini(tebak_benar, 5)`, `crowns_tebak = 3 * mini(tebak_benar, 5)`;
  baris kartu hadiah "Duel guesses: 2 right +10 XP +6 Crowns"; `tebak_benar` masuk `STAT_SEUMUR`.
- Migrasi saat duel: tebakan duel yang sedang berjalan dibuang (tidak ada hadiah) -- diterima.

### 3.5 Putar ulang rolet (solo)
- `ui_elemen` dapat `var penawar_putar_ulang: Callable` (diisi pemain.gd HANYA di solo, dikosongkan di multiplayer).
- Di `jalankan_duel` alur asli (naskah kosong, bukan mode tonton), setelah skor RANGKUMAN dihitung dan SEBELUM
  pengumuman/lempar koin: kalau skor pemain < skor musuh dan penawar valid -> `await penawar_putar_ulang.call()`.
  Penawar (pemain_duel.gd, pola `_tawarkan_iklan_hutang`): cek solo, belum terpakai, `rewarded_tersedia()`; tombol
  "WATCH AD: SPIN AGAIN" / "NO THANKS"; nonton -> true. Kalau true: putar ulang HANYA rolet sisi pemain
  (pecah kode putar rolet "ROLET_PEMAIN" jadi fungsi bantu supaya tidak disalin), angka baru dari `rng` yang sama,
  hitung ulang skor, lanjut alur normal. Gagal iklan -> "No ad right now." dan kekalahan tetap.
- `_putar_ulang_terpakai` direset di awal pertandingan. Stat `putar_ulang` (untuk rekap).
- Waktu menunggu tombol: `Engine.time_scale` kembali 1x (seperti panel lain yang menghentikan permainan).

### 3.6 Tombol AI cepat (solo)
- Tombol ">>" kecil di HUD solo (sembunyi di multiplayer). Field profil baru `ai_cepat := false` (dibaca dengan
  nilai bawaan -> berkas profil lama aman; VERSI tidak perlu naik kecuali `muat()` menuntutnya -- cek).
- `_atur_kecepatan_permainan()`: solo + `ai_cepat` + giliran AI + layar duel/kartu/panel tidak tampil ->
  `skala_dasar x 2.0`; selain itu perilaku lama (Quick 1,5x, Classic tidak disentuh).

## 4. Jaringan & migrasi (ringkas)
- Semua keputusan acak (event, target Earthquake, bounty, kartu bantuan) HANYA di host/solo dengan `mesin_acak`.
- Siaran state + field baru: "event", "bounty" (statistik & kartu sudah ikut). Penerima memakai `data.has()`.
- RPC baru (authority -> client, hanya tampilan): `rpc_event_papan`, `rpc_bounty` (mulai/diklaim), teks kartu
  bantuan. RPC baru (any_peer -> host): `rpc_kirim_tebakan`; balasan `rpc_tebakan_diterima`.
- Host baru melanjutkan `ronde_event`, `event_aktif`, `bounty_elemen` dari state terakhir.

## 5. Urutan kerja (tiap langkah diverifikasi rig sebelum lanjut)
- **G0 (Sonnet).** Refactor tanpa perubahan perilaku: `denda_petak()`, `harga_beli_*()`, `ronde_event`. Bukti:
  `cek_nilai` 8/8 + U9 S1 100 pertandingan benih 20000 IDENTIK dengan hasil F5 konfirmasi (baris per baris) +
  `batch_reg10`.
- **G1 (Sonnet).** Event papan + sinkron + HUD. Rig: solo 2P/4P Quick & Classic tanpa SCRIPT ERROR, log event per
  ronde; MP: skenario baru "event sinkron" (3 HP, log `EVENT ronde=.. id=..` di semua proses harus sama) +
  "host keluar di ronde event" (event berlanjut sama di host baru).
- **G2 (Sonnet).** Bounty. **G3 (Sonnet).** Kartu bantuan. Rig sama seperti G1 (klaim bounty & kartu bantuan
  tercatat sama di semua proses).
- **G4 (Sonnet).** Tebak Duel (solo + MP). Rig: robot penonton menebak (uji_robot_mp.gd, rig-only); statistik
  `tebak_benar` sama di host & client; "Too late!" teruji (tebakan sengaja telat).
- **G5 (Sonnet).** Putar ulang rolet (solo). Rig: `uji_rewarded=true` + slot manusia tiruan kalah duel -> rolet
  diputar ulang sekali, kedua kalinya tidak ditawarkan; `uji_rewarded=false` -> jejak identik dengan G4.
- **G6 (Sonnet).** Tombol AI cepat. **G7 (Sonnet).** Profil (XP/Crowns tebak, kartu hadiah, stat seumur).
- **G8 (Opus).** U9 ulang (K9) + regresi MP 37 skenario + skenario baru + `cek_nilai` + `cek_muat`.
  Kalau P14 gagal -> Opus menyetel K3/K5.
- **G9 (Sonnet).** Bersih-bersih (pola F7) -> kiriman `kiriman/TileDuel_Fase5_b10.zip` (set lengkap) -> uji HP.

## 6. Uji HP pemilik (setelah G9)
Solo Quick 2P & 4P: tiap event minimal sekali terlihat (spanduk + label), Market Day harga di tombol turun, Gold
Rush denda di tombol naik; bounty diklaim; kartu bantuan muncul saat tertinggal jauh; Tebak Duel di solo 4P
(XP tebak di kartu hadiah); kalah duel -> tombol SPIN AGAIN (iklan) -> rolet berputar ulang; tombol ">>".
Multiplayer HP + laptop: event & bounty SAMA di kedua layar; penonton (3P) bisa menebak; satu device keluar saat
ronde event -> event tetap. FPS di Very Low tidak turun saat spanduk event.

## 7. Arahan model
Rencana & K = Opus (sekarang). G0-G7 & G9 = Sonnet (kode dari rencana ini). G8 = Opus (keseimbangan).
Pindah ke Opus lebih awal kalau: G0 tidak identik, client & host berbeda event, migrasi kehilangan event,
atau P14 gagal.

## 8. Sengaja tidak dikerjakan di Fase 5
Event mingguan & toko event (Fase 8); misi baru untuk Tebak Duel; tebakan dengan taruhan Crowns; AI menyesuaikan
pilihan elemen dengan bounty; tombol AI cepat di multiplayer; putar ulang rolet di multiplayer (iklan tidak
pernah di tengah giliran multiplayer).

## 9. STATUS
- 02-10 (Sonnet): **G0 SELESAI & lolos** (S1 100 baris identik F5, cek_nilai 8/8, reg10 sama; `hasil/g0_refactor/`). Berikutnya G1.
- 02-10 (Sonnet): **G1 SELESAI** (event papan; bukti `hasil/g1_event/`; label HUD belum dilihat di layar sungguhan; getaran Earthquake tidak dibuat). Berikutnya G2.
- 02-10 (Sonnet): **G2 SELESAI** (bounty; bukti `hasil/g2_bounty/`: solo 27 run, MP sinkron + klaim + migrasi saat bounty aktif). Berikutnya G3.
- 02-10 (Sonnet): **G3 SELESAI** (kartu bantuan; `hasil/g3_bantuan/`) + **getaran kamera Earthquake dibuat** (`h_offset/v_offset`, dilewati di Very Low). Berikutnya G4 (Tebak Duel).
  Catatan G8: bounty & kartu bantuan hampir tak muncul di Quick (lihat HANDOFF) -> K3/K4/K5 mungkin perlu disetel Opus.
- 02-10 (Sonnet): **G4 SELESAI** (Tebak Duel solo + MP; stat `tebak_benar`; bukti `hasil/g4_tebak/`: robot penonton menebak, stat identik di semua device, "Too late!" teruji, migrasi saat duel bersih; S1 100 G3==G4).
  Hadiah profil = G7 (belum). Jendela tebak solo ~2,5 dtk KETAT -- disetel di uji HP. Berikutnya G5.
- 02-10 (Sonnet): **G5 SELESAI** (putar ulang rolet solo; `hasil/g5_putar_ulang/`: 8/8 putar ulang cek OK, sekali per pertandingan, NO THANKS/iklan gagal -> boleh ditawari lagi, MP tak terpengaruh, S1 100 G4==G5). Berikutnya G6 (tombol AI cepat).
- 02-10 (Sonnet): **G5 diperbaiki**: NO THANKS = tidak ditawari lagi di pertandingan itu (iklan gagal tetap boleh); bukti `hasil/g6_ai_cepat/tolak_ringkas.txt`.
- 02-10 (Sonnet): **G6 SELESAI** (tombol AI cepat solo, profil `[pengaturan] ai_cepat`, 2x hanya giliran AI tanpa layar duel/menu/spanduk event, MP tak terpengaruh; `hasil/g6_ai_cepat/`: `salah=0`, persisten lintas proses, S1 100 G4==G5==G6, cek_nilai 8/8, reg10 sama). Berikutnya G7 (profil).
- 02-10 (Sonnet): **G7 SELESAI** (hadiah profil Tebak Duel: 5 XP/3 Crowns per tebakan benar maks 5, tidak ikut DOUBLE, baris kartu "Duel guesses", `tebak_benar` di STAT_SEUMUR; `hasil/g7_profil/`: uji unit 21/21, solo penuh PROFIL_CEK OK, MP Quick 3P PROFIL_MP OK, S1 100 G4==G7). Berikutnya G8 (OPUS).
  TEMUAN untuk Opus: soft-lock bangkrut tanpa petak (kode lama; lihat HANDOFF "TEMUAN").
- 02-10 (Opus): **G8 SELESAI** -- soft-lock bangkrut diperbaiki, jendela tebak solo diperlebar, U9 ulang LOLOS P14 (benih 50000/60000), regresi MP 37 + skenario baru. Rincian & usulan K11/K12: bagian 10. Berikutnya: keputusan pemilik K11/K12, lalu G9 (Sonnet).
- 02-10 (Opus): draf ditulis.
- 02-10: pemilik menyetujui K1-K10 = a. Rencana dikunci. Berikutnya G0 (Sonnet, sesi baru): refactor `denda_petak()`/
  `harga_beli_*()`/`ronde_event` tanpa perubahan perilaku -> bukti identik di rig (bagian 5).

## 10. G8 (Opus, 02-10) -- hasil & usulan

### 10.1 Soft-lock "bangkrut tanpa petak" (HANDOFF TEMUAN 1) -- DIPERBAIKI
- Aturan yang SUDAH ada dipakai: kalau sesudah menjual petak TERAKHIR uang masih minus -> sama seperti cabang
  "No more tiles! You carry the debt." di `sita_aset_untuk_hutang`: hutang dibawa, giliran lanjut.
- Kode (`pemain_papan.gd`, game + rig identik): `eksekusi_jual_aset` cabang baru `elif not _punya_petak(slot)` ->
  `mode_jual_aset/mode_membidik = false`, teks `_teks_bawa_hutang(slot)`, host mengirim `rpc_jual_habis(slot)` (RPC BARU,
  client menutup mode jual & menampilkan teks yang sama dari sudut pandangnya), tunggu 2,5 dtk, `ganti_giliran()`.
  Fungsi bantu baru `_punya_petak`, `_teks_bawa_hutang` (dipakai juga oleh cabang lama di `sita_aset_untuk_hutang`).
  AI (`_ai_jual_sampai_lunas`) sudah benar sejak dulu ("accepts debt"), tidak diubah.
- Bukti (`hasil/g8_bangkrut/`, opsi rig-only `hutang_habis=SLOT`: begitu SLOT punya >= 2 petak, uangnya dibuat minus melebihi
  nilai jual semua petaknya -> denda berikutnya memaksa jalur ini). Kode LAMA s801 -> `SIM MACET giliran=9` ("Still in minus! Tap
  another tile" tanpa petak). Kode BARU: solo 2P Classic x4 (s801-804, hingga 4x hutang dibawa per run), Quick 2P + iklan +300
  (iklan ditonton, tetap minus, jual habis, dibawa), Classic + iklan, slot AI 3P; MP: host bangkrut (1v1), client bangkrut (1v1 &
  3P c2 Classic), AI bangkrut (2P+1AI): di SEMUA device "No more tiles! ..." lalu `mode_jual=false`, giliran lanjut, 0 SCRIPT ERROR,
  0 MACET. (3P Quick s823: hutang dipasang tapi pertandingan habis sebelum ada denda -- tidak menguji jalur.)
- Catatan: build MP harus sama di semua HP (RPC baru `rpc_jual_habis`).

### 10.2 Jendela Tebak Duel solo (catatan G4) -- DIPERLEBAR
- `_tonton_ai_pilih_elemen` (`pemain_duel.gd`): kalau tombol tebak tampil (manusia lokal bukan peserta), penyerang AI "berpikir"
  tambahan maks `TEBAK_SOLO_TAMBAHAN = 2.0` dtk (`pemain_dasar.gd`), BERHENTI begitu pemain menebak. Tanpa penonton manusia
  (rig semua AI, MP) tidak berubah. Jendela: tidak menebak 2,5 -> ~5,3 dtk game (Quick ~3,5 dtk nyata); menebak cepat
  -> jendela ~3,3 dtk (permainan hanya ~0,8 dtk lebih lama). Rig `tebak_jeda=3.0` (dulu pasti "Too late!") kini diterima, cek OK.
  Bukti `hasil/g8_tebak/`.

### 10.3 U9 ulang (K9) -- LOLOS P14 (angka K3/K5 & role F5 TIDAK diubah)
| | air | angin | api | petir | tanah | catatan |
|---|---|---|---|---|---|---|
| F5 konfirmasi S1 2P (b20000) | 50.2 | 49.8 | 46.5 | 48.1 | 55.4 | jebakan/AI 2.12, 291 dtk |
| **G8 S1 2P (1200, b50000)** | 48.8 | 54.6 | 45.6 | 48.3 | 52.7 | 0 pasangan !, 0 sel wajib/mati, jebakan/AI 2.18, 298 dtk |
| F5 konfirmasi S2 4P | 22.7 | 27.6 | 21.1 | 26.7 | 27.4 | |
| G8 S2 4P (400, b50000) | **18.8** | 26.6 | 25.8 | 28.3 | 24.9 | air di bawah 20 (CI 14.7-23.6) |
| G8 S2 4P tambahan (400, b60000) | 23.4 | 28.6 | 23.0 | 23.1 | 27.0 | |
| **G8 S2 4P gabungan 800** | 21.2 | 27.6 | 24.3 | 25.7 | 25.9 | lolos (pola F5: S4 tambahan digabung) |
- S5 panjang (240, robot slot 0, TIDAK menebak -> jendela tebak terpanjang): 2P/3P/4P = 297 / 331 / 377 dtk (batas 318 / 400 / 464).
- Dipantau: air 4P 21.2 (dekat batas bawah; air x defense 4P rendah sejak F5: 17.7 -> 14.9), angin 2P 54.6.
- Kolom rig-only baru `f5=ev/bm/bk/kb/hb` di baris SEIMBANG (event, bounty muncul, bounty diklaim, kartu bantuan, hutang dibawa).
  Data: `hasil/g8_u9_b50000/`, `hasil/g8_u9_s2_tambahan/`.

### 10.4 Bounty & kartu bantuan di Quick (catatan G2/G3) -- DATA + USULAN (keputusan pemilik)
| U9 (semua AI) | event/match | bounty muncul | bounty DIKLAIM (% match) | duel dimenangkan/match | kartu bantuan (% match) |
|---|---|---|---|---|---|
| S1 Quick 2P (1200) | 2.58 | 1.05 | 8% | 0.48 | 5.2% |
| S2 Quick 4P (800) | 1.65 | 1.13 | 17-20% | 1.1-1.2 | 2.0-2.8% |
| S5 Quick 2-4P robot (240) | 2.05 | 1.13 | 20% | 1.11 | 2.9% |
Penyebab: di Quick duel jarang (2P < 0,5 duel dimenangkan per pertandingan) dan klaim butuh menang duel DENGAN elemen tertentu
(~1/5); kartu bantuan butuh tertinggal >= 1000 saat lewat START, padahal selisih kekayaan AKHIR Quick 2P median ~900.
Hutang tanpa petak tidak pernah terjadi di U9 (semua AI) -- jalur 10.1 terutama untuk pemain manusia.
- **K11 (bounty di Quick).** a) biarkan (bounty terutama fitur Classic; di Quick cuma hiasan); b) **Quick: klaim = menang duel
  APA PUN** (label "BOUNTY: win a duel"), Classic tetap elemen -- usul Opus; c) tanpa bounty di Quick.
- **K12 (kartu bantuan di Quick).** a) biarkan 1000 (2-5% pertandingan); b) **Quick: selisih 600** (konstanta baru
  `KARTU_BANTUAN_SELISIH_QUICK`), Classic tetap 1000 -- usul Opus; c) Quick 400.
- Kalau b/c dipilih: perubahan kecil (Sonnet), lalu WAJIB U9 S1 + S2 ulang di benih baru (~45 menit) sebelum G9, karena
  ekonomi Quick berubah.

### 10.5 Temuan baru (belum diperbaiki)
- MP s821 (1v1 Classic, host role api dgn Ultimate Phoenix): CEK#12 BEDA -- jebakan api Phoenix di petak 15 masih ada di host
  (`aktif_ulang:0`, sudah selamat sekali) tapi hilang di client, SEBELUM ada penjualan petak (tidak terkait 10.1). Kode lama
  (B-c C5). Lihat juga hasil regresi MP di bawah.

