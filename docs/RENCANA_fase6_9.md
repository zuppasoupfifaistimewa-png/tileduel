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

**Risiko:** taruhan terasa "judi" untuk kebijakan Play -> memakai mata uang game yang TIDAK bisa dibeli dengan uang
(Crowns tidak dijual di Fase 7 -- pertahankan begitu), jadi aman; misi baru membuat pool misi harian terlalu sering
Tebak Duel (bobot rendah).

## 5. Temuan terbuka yang dibawa
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
- Sesi berikut: **Sonnet** -- Fase 6 G0 + G1 (baca: CLAUDE.md, HANDOFF 0 & 5, LOG teratas, bagian 0, 1, 6, 7 rencana ini).
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
