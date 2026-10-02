# HANDOFF -- lanjutkan proyek Tile Duel (Fase 4 SELESAI; Fase 5: G0-G3 + getaran Earthquake SELESAI, G4 berikutnya)

Dokumen ini ditulis 02-10-2026 supaya sesi Claude Code (cloud / web, tanpa CLI) mana pun bisa melanjutkan
pekerjaan TANPA riwayat percakapan. BACA INI DULU, lalu `docs/RENCANA_fase4_role.md` bagian 14.19 & **14.21-14.24** (paling akhir).
Diperbarui 02-10 (Opus, sesi Claude Code cloud): **uji HP pemilik dengan `kiriman/TileDuel_FaseB_b9.zip` = "lancar" -> Fase 4 SELESAI** (RENCANA 14.24).
Berikutnya: pemilik merilis A+B (daftar periksa di bagian 5). **Fase 5: rencana `docs/RENCANA_fase5_seru.md` DISETUJUI 02-10 (K1-K10 = a); G0-G3 + getaran Earthquake SELESAI (Sonnet, 02-10) -> berikutnya Sonnet mengerjakan G4 (Tebak Duel).**

**Fase 5 G0 SELESAI (Sonnet, 02-10):** refactor `denda_petak()` / `harga_beli_tanah()` / `harga_beli_menara(lv)` / `ronde_event` di
`pemain_dasar.gd` (+ semua pemakai di `ai_jebakan/ai_musuh/pemain/pemain_papan/pemain_tampilan`), `game/` & rig identik (34/35, kecuali stub iklan).
Bukti: S1 100 pertandingan benih 20000 IDENTIK baris per baris dgn F5 konfirmasi; `cek_nilai` 8/8; reg10 sama; data di `hasil/g0_refactor/`.

**Fase 5 G1 SELESAI (Sonnet, 02-10):** event papan (gold_rush / market_day / earthquake / star_shower; Quick ronde 3,5,7.. tiap 2; Classic
ronde 4,7,10.. tiap 3; tanpa pengulangan berurutan; undian `mesin_acak`). Kode: `pemain_dasar.gd` (state `event_aktif/event_terakhir`, konstanta,
`denda_petak` x2 & `harga_beli_*` x0,7 dibulatkan 10), `pemain_papan.gd` (`_ronde_jadwal_event`, `_mulai_event_papan`, `rpc_event_papan`, teks),
`pemain.gd` (dipanggil di `ganti_giliran` slot 0), `pemain_jaringan.gd` (siaran state "event"), `pemain_tampilan.gd`+`ui_dinamis.gd` (label HUD event;
`buat_label_ronde` +param warna). Rig-only: log `EVENT ...` di `uji_nyata.gd` & `uji_robot_mp.gd` (+ "event" di potret sinkron host-vs-client).
Bukti (`hasil/g1_event/`): solo Quick 2P/4P & Classic 2P/4P 0 SCRIPT ERROR, jadwal benar; MP 3P Quick: EVENT identik di host+2 client, cek_gagal=0;
host keluar di ronde event (migrasi): event berlanjut (c1 jadi host, ronde 5 gold_rush lanjut tanpa mengulang), cek_ok_migrasi=3, 0 beda; `cek_nilai` 8/8.
BELUM diverifikasi: tampilan label HUD event (headless tidak merender; cek di uji HP G9). (Getaran kamera Earthquake: DIBUAT di sesi G3, lihat bawah.) Keseimbangan role
TIDAK dicek (itu G8, Opus) -- event sudah mengubah ekonomi pertandingan. Berikutnya: **G2 bounty (Sonnet)**.

**Fase 5 G2 SELESAI (Sonnet, 02-10):** bounty. State `bounty_elemen/bounty_terakhir` (+`label_bounty`, `BOUNTY_RONDE_PERTAMA=2`) di `pemain_dasar.gd`;
`_bounty_perlu_muncul/_mulai_bounty/_klaim_bounty/rpc_bounty/_tampilkan_bounty` di `pemain_papan.gd`; dipanggil dari `ganti_giliran` (slot 0, sesudah event)
dan `eksekusi_dadu_pertarungan` (`pemain_duel.gd`, klaim = pemenang duel dgn `elemen_pemenang == bounty_elemen` -> +1 bintang maks 10, stat `bounty`);
siaran state "bounty" (`pemain_jaringan.gd`); label HUD `_atur_posisi_label_bounty` (`pemain_tampilan.gd`); kunci `bounty` di `statistik_kosong`.
Jadwal: bounty pertama ronde_event 2; sesudah diklaim, yang baru muncul di ronde event berikutnya; elemen diundi `mesin_acak`, tidak sama dgn yang terakhir. AI ikut mengklaim otomatis.
Bukti (`hasil/g2_bounty/`): solo 27 run (Quick/Classic 2P/4P) 0 SCRIPT ERROR, jadwal benar, klaim selalu tepat +1 bintang;
MP 3P Quick: sinkron host+2 client identik (urutan BOUNTY sama, cek_gagal=0), klaim teruji (robot rig `bounty_pilih=1`), host keluar saat bounty aktif:
bounty bertahan di host baru (c1), klaim setelah migrasi tercatat sama di c1 & c2, bounty baru diundi host baru; `cek_nilai` 8/8.
Rig-only: log `BOUNTY`/`BOUNTY_KLAIM` di `uji_nyata.gd` & `uji_robot_mp.gd` (+ "bounty" di potret), opsi `bounty_pilih=1` di `uji_robot_mp.gd`.
Untuk G8 (Opus): bounty di Quick hampir tak berarti -- 11 bounty di 11 run Quick solo, hanya 1 diklaim (Classic: 39 bounty, 23 diklaim); keputusan keseimbangan, jangan disetel Sonnet.

**Fase 5 G3 + getaran kamera Earthquake SELESAI (Sonnet, 02-10):**
- G3 kartu bantuan: `pemain.gd` (`_berhak_kartu_bantuan`, `_beri_kartu_bantuan`, `rpc_kartu_bantuan`, `_tampilkan_kartu_bantuan`; dipanggil di `bergerak_maju` setelah efek
  "passed Start"), `pemain_kartu.gd` (`_daftar_kartu_hadiah()` dipecah dari `_kartu_hadiah_acak()` -- perilaku iklan tak berubah), konstanta `KARTU_BANTUAN_SELISIH=1000` /
  `KARTU_BANTUAN_MAKS_INVENTARIS=3` (`pemain_dasar.gd`), stat `kartu_bantuan` (`statistik_kosong`). Syarat: kekayaan (`_kekayaan_slot`) PALING rendah (seri = tidak berhak),
  tertinggal >= 1000 dari yang terkaya, inventaris < 3, saat lewat START dgn gaji cair. Kartu = acak `mesin_acak` dari `KARTU_HADIAH_IKLAN`. Spanduk "COMEBACK CARD!" + "<You/P3> got LOW ROLL".
  Inventaris sampai ke client lewat siaran state "kartu" (seperti kartu gacha); RPC `rpc_kartu_bantuan` hanya tampilan.
- Getaran kamera: `_mulai_getar_kamera`/`_perbarui_getar_kamera` (`pemain_tampilan.gd`, dipanggil dari `_process` di `pemain.gd`), konstanta `GETAR_KAMERA_DURASI=0.8` /
  `GETAR_KAMERA_KUAT=0.5` + `_getar_kamera_sisa` (`pemain_dasar.gd`). Memakai `Camera3D.h_offset/v_offset` (tidak mengganggu posisi kamera yang mengikuti pemain), tanpa pengacak
  (sin/cos), dipicu di `_tampilkan_event_papan` untuk id "earthquake" (host, solo & client), DILEWATI di Very Low (`AudioGrafis.baca_tingkat() == "sangat_rendah"`).
- Bukti (`hasil/g3_bantuan/`): solo 16 run (Quick/Classic 2P/4P, alam+pantai) 0 SCRIPT ERROR; 5 kartu bantuan di Classic, semuanya valid (penerima termiskin & tertinggal >= 1000);
  getaran: `GETAR_KAMERA maks_h` 0.06-0.45, `akhir_h=0` tiap kali (21 kejadian). MP: 4P & 3P Classic + 3P Quick sinkron cek_gagal=0, kartu_beda=0; opsi rig `kaya_awal=1` (host +3000) memaksa kartu:
  kartu bantuan identik di host+c1+c2 (s402); host keluar -> kartu bantuan diberikan host BARU setelah migrasi, identik di c1 & c2 (s413). `batch_reg10` sama persis dgn G0
  (takeover ok=29, kamera_hud ok=4, 0 gagal, 0 scripterr), `cek_nilai` 8/8, `IKLAN_KARTU cek=OK` (iklan kartu awal tak berubah).
- BELUM: tampilan spanduk COMEBACK CARD & getaran di layar sungguhan (headless) -> uji HP G9; kekuatan getaran 0.5 tebakan awal, boleh disetel. Rig-only: log `KARTU_BANTUAN`/`GETAR_KAMERA`
  (`uji_nyata.gd`, `uji_robot_mp.gd`), opsi `kaya_awal=1` (`uji_robot_mp.gd`).
- Untuk G8 (Opus): kartu bantuan hampir tak pernah muncul di Quick (0 kartu di 12 run Quick solo; 5 kartu di 4 run Classic) -- selisih 1000 mungkin terlalu ketat untuk Quick; keputusan keseimbangan.

## 0. Aturan tetap dari pemilik proyek (WAJIB)
1. Balas dalam **Bahasa Indonesia saja**.
2. Mengedit file yang SUDAH ada: ubah hanya baris/bagian relevan, JANGAN tulis ulang seluruh file.
   (File baru boleh ditulis penuh.) Tips: Edit gagal diam-diam kalau jumlah tab salah -> pakai skrip Python
   yang mengiris daftar baris + assert isi persis sebelum menulis.
3. Selalu beri arahan KAPAN ganti model: Opus = arsitektur / tinjau rencana besar / penyetelan keseimbangan /
   bug membingungkan; Sonnet = menulis kode dari rencana yang sudah disepakati, cek diff, tambalan kecil.
4. Jangan kirim file bernama sama berulang kali di pesan terpisah; kalau ada yang berubah kirim SET LENGKAP
   sekaligus (satu ZIP) dan minta unduhan lama dibuang.
5. Proyek: game papan 3D Godot 4.7.1 (GDScript) "Tile Duel", sudah rilis di Google Play. Aturan P1: fungsi
   `ai_*.gd` hanya BACA state (tanpa efek samping stat). RNG game HARUS lewat `mesin_acak` (bukan `randi()`).
6. (02-10) Di AKHIR TIAP TAHAP (tiap putaran F5 selesai dianalisis, tiap fase F6/F7/F8, dst.): perbarui
   HANDOFF_LANJUT.md (status + langkah berikutnya) dan push ke GitHub (branch `claude/new-session-e4ogqo`),
   bersama data hasil tahap itu. Pekerjaan tidak boleh hanya ada di satu sesi/container.
7. (02-10) JANGAN jalankan dua rantai simulasi bersamaan, dan JANGAN ubah file apa pun di `rig/` (terutama
   `rig/proj_tanpa_uji/*.gd`) selama simulasi masih berjalan. Cek `ps -eo comm | grep -c ^Godot` = 0 dulu sebelum
   mengubah angka atau memulai rantai baru (`pgrep -f Godot_v4` keliru: cocok dengan baris perintahnya sendiri).
8. (02-10) Pantau panjang sesi. Kalau sesi sudah panjang (satu tahap selesai & ter-push, puluhan panggilan alat /
   beberapa hasil simulasi panjang, konteks mulai diringkas otomatis, atau tahap berikutnya cocok untuk model lain):
   INGATKAN pemilik untuk membuka sesi baru, setelah memastikan semua sudah di-push, dan beri prompt siap tempel
   (lihat dokumen "Tile Duel -- Panduan Sesi Kerja": https://claude.ai/code/artifact/bc2bfff0-d4f6-4ff0-89ed-16dd35ecbe48).
9. (02-10) Sesi baru TIDAK bisa membaca percakapan lama. Jadi di akhir tiap sesi: tambah ringkasan (tanggal, model,
   yang dikerjakan, keputusan, commit terakhir, langkah berikutnya) ke `docs/LOG_SESI.md` lalu push. Sesi baru membaca
   `CLAUDE.md` -> `HANDOFF_LANJUT.md` -> `docs/LOG_SESI.md`.

## 1. Isi repo
| Folder | Isi |
|---|---|
| `game/` | Produksi saat ini, 35 .gd = **29 set resmi** (daftar di bagian 5) + 6 file pendukung T21 yang tidak dikirim. F1-F4 sudah diterapkan (P13, K23, T19). **Angka final F5 SUDAH diterapkan (F6, 02-10); 34/35 identik dengan rig (beda hanya `pengelola_iklan.gd`).** |
| `docs/` | `RENCANA_fase4_role.md` = sumber kebenaran tunggal (bagian 14.19 = rencana B-f; status F0-F4 di bagian paling bawah). Plus rencana fase lama & patokan. |
| `rig/proj_tanpa_uji/` | Proyek Godot lengkap untuk rig simulasi (headless): produksi + `uji_*.gd/.tscn`. **Setelah F6: = `game/` + uji** (diff hanya `pengelola_iklan.gd` stub + berkas `uji_*`). Cache `.godot/` tidak di-git -> impor ulang dulu (bagian 4). |
| `rig/skrip/` | `f4/uji_seimbang.sh` (pelari), `f4/ringkas_seimbang.py` (ringkasan win-rate + CI), `f4/buat_tugas_u9.py` (pembuat S1-S5), `f4/cek_panggil.py`, `f5_analisa.py`, `f5_pasangan.py`, skrip batch regresi `batch_reg10.sh`, `uji_f2_t2_a/b.sh`, dll. |
| `hasil/f4_u9_baseline_sebelum_tuning/` | Data S1 (1200, 2P) & S2 (400, 4P) SEBELUM penyetelan (S3 parsial 31 baris -- JANGAN dipakai). |
| `hasil/f5_putaran/r1..r4/` | Hasil S1 tiap putaran penyetelan (r3 lengkap 1200; r4 + S2 4P). |
| `hasil/f5_konfirmasi_b20000/` | KONFIRMASI angka final, benih baru 20000: S1-S5 (+ berkas `.tugas`). |
| `hasil/f5_s4_tambahan/` | S4 tambahan 800 (benih 30000 & 40000) -- digabung dengan S4 benih 20000. |
| `f5_kandidat/*.patch` | Selisih produksi lama -> ANGKA FINAL F5 (sudah diterapkan di F6). |
| `hasil/f6_regresi/` | Hasil F6: ringkasan regresi MP 37 skenario, `batch_reg10`, `cek_nilai` 8/8. Tinjauan F6: `tinjauan_reg10/` (temuan 1), `tinjauan_mp_d1/` (temuan 4) -- baca `RINGKAS.txt` masing-masing. |
| `hasil/f7_bersih/` | F7: `F7_cek.txt` (grep debug, sinkron, cek_muat, cek_nilai) + log `uji_tanah2` setelah diperbaiki. |
| `kiriman/` | F8: `TileDuel_FaseB_b9.zip` = 29 .gd resmi + `RENCANA_fase4_role.md` (30 file). **Uji HP pemilik lolos (02-10); isi = `game/` saat ini.** |

## 2. Status ringkas (rincian: RENCANA 14.21)
- F0-F4 selesai. **F5 SELESAI 02-10 (Opus).** Semua syarat P14 lolos di benih BARU 20000:
  | | air | angin | api | petir | tanah | catatan |
  |---|---|---|---|---|---|---|
  | baseline S1 2P | 47.7 | 57.5 | 42.9 | 51.7 | 50.2 | jebakan/AI 1.88 |
  | **konfirmasi S1 2P** | 50.2 | 49.8 | 46.5 | 48.1 | 55.4 | 0 pasangan !, 0 sel wajib/mati, jebakan/AI 2.12 |
  | konfirmasi S2 4P | 22.7 | 27.6 | 21.1 | 26.7 | 27.4 | target 20-30 |
  | konfirmasi S3 solo Lv20 | 44.8 | 50.8 | 54.2 | 51.0 | 49.2 | |
  | konfirmasi S4 solo Lv1 (1200 gabungan) | 48.8 | 55.2 | 46.9 | 47.7 | 51.5 | DASAR tidak diubah |
  S5 panjang 2P/3P/4P = 264/306/387 dtk (batas 318/400/464). XP: Lv15 ~40 pertandingan Quick.
- Angka final (produksi -> final): AMBANG_NILAI 50->40, AMBANG_PELUANG 80->90, NILAI_PETIR_LEWAT_GILIRAN 75->150,
  FAKTOR_ULANG_ULTIMATE 1.5->1.2 (ai_jebakan.gd); hot_flames 70/80/90->90/110/130, fire_tax .25/.5/.75->.5/.75/1.0,
  strong_wind .12/.14/.16->.11/.12/.13, homing_wind .25/.5/.75->.15/.3/.45 (data_role.gd NODE_LV).
- Kunci diagnosis: AI api dulu tidak pernah memakai jebakan petir melawan role petir (penilaian jebakan api terlalu
  tinggi), padahal petir tidak punya grounded. Dipantau: angin Lv1 ~55%, air Lv20 44.8%, api 4P ~21% (lolos, dekat batas).

## 3. rig vs produksi (setelah F7)
`game/` dan rig kini memakai angka final F5. `pengelola_iklan.gd` di rig sengaja beda (stub iklan untuk uji) -- JANGAN disalin ke `game/`.
Satu-satunya perbedaan lain: `rig/proj_tanpa_uji/uji_nyata.gd` (rig-only) harapan `cek_nilai` sudah 390/130/324.
Rig-only lain: `uji_*`, `cek_muat_f3.gd` (alat), dan 5 file proyek yang tidak ada di `game/` (`audio_grafis`, `lingkungan_alam`,
`menu_grafis`, `mesh_instance_3d`, `validasi_peta` -- tidak pernah diubah fase mana pun). F7: `uji_tanah2.gd` kini punya tiruan `_angka_jebakan` (0 SCRIPT ERROR).

## 4. Cara menjalankan rig (headless)
1. Perlu Godot **4.7.1-stable linux x86_64**. Unduh dari GitHub releases (`godotengine/godot-builds`, tag `4.7.1-stable`) ke
   `/opt/godot/Godot_v4.7.1-stable_linux.x86_64` (atau set env `G=`). Kalau jaringan memblokir, minta pengguna mengunggah binernya.
2. Impor sekali: `G --headless --path rig/proj_tanpa_uji --import` (buat ulang cache `.godot/`; perlu beberapa menit).
3. Buat tugas: `python3 rig/skrip/f4/buat_tugas_u9.py` (hasilkan s1..s5.tugas; deterministik dari benih).
4. Jalankan: `PARALEL=2 bash rig/skrip/f4/uji_seimbang.sh <berkas.tugas> <hasil.txt>` -- bisa DILANJUTKAN kalau terputus
   (baris yang tag+seed+peta sudah ada dilewati). **Satu pelari saja per mesin 2-core.** JANGAN jalankan dua rantai berbeda bersamaan
   dan JANGAN ubah file `.gd` rig sementara rantai masih berjalan (pernah mencemari data 4P r1 -- lihat RENCANA).
5. Ringkas: `python3 rig/skrip/f4/ringkas_seimbang.py <hasil.txt>`; rincian pasangan: `python3 rig/skrip/f5_pasangan.py <hasil> api petir`.
6. Kecepatan terukur: ~2.3 dtk/pertandingan (PARALEL=2, `--fixed-fps 60`) -> S1 (1200) ~45-50 menit. Perintah `sleep` panjang
   di alat Bash perlu parameter `timeout` (default 2 menit).
   **Sesi Claude Code cloud (02-10):** unduhan Godot dari GitHub releases LOLOS lewat proxy; mesin 4 inti -> `PARALEL=4`,
   S1 (1200) ~20 menit, S2 (400) ~10 menit. Hasil deterministik per benih (tidak bergantung PARALEL). Jalankan tiap rantai
   sebagai perintah latar belakang terpisah (<30 menit tiap perintah). Cek proses dengan `ps -eo comm | grep -c ^Godot`
   -- JANGAN `pgrep -f Godot_v4` (cocok dengan baris perintah sendiri).
   `buat_tugas_u9.py <dir> <benih_awal>` -- argumen ke-2 = benih awal (bawaan 5000).
7. Skrip `f4/uji_seimbang.sh` & beberapa skrip lama masih berisi path scratchpad lama -- ubah/override lewat env bila perlu.
   Skrip MP (`uji_f2_t2_a/b.sh`, LocalPlay.tscn) TIDAK boleh jalan paralel (port tetap) -- jalankan berurutan.

## 5. Langkah berikutnya
- **F6 SELESAI (Sonnet, 02-10):** 8 angka final diterapkan ke `game/` (commit 0785152); `cek_nilai=1` 8/8 (390/130/324);
  regresi MP 37/37 skenario (97 baris SELESAI, 0 MACET/scripterr/beda/cek_gagal); U11 OK. Rincian: RENCANA 14.22.
- **Tinjauan F6 SELESAI (Opus, 02-10, RENCANA 14.23):**
  1. `batch_reg10` BUKAN "9 uji 0 gagal": 6 uji "gagal: 0"; `uji_pedang` & `uji_cabang_solo` memang tanpa baris kesimpulan
     (cuma mencetak pengamatan) -> diperiksa manual: benar & IDENTIK dgn angka produksi lama (cabang: benih 1-10);
     `uji_tanah2` 2 SCRIPT ERROR identik dgn angka lama (terbukti sudah ada sebelum F6). Data: `hasil/f6_regresi/tinjauan_reg10/`.
  2. Set resmi 29 .gd (tiga sumber cocok: `sinkron_tanpa_uji.sh` + `jebakan_dasar`, `game/` - 6 file T21, commit fe39bec):
     `ai_jebakan ai_musuh data_pemain data_role jebakan_air jebakan_angin jebakan_api jebakan_dasar jebakan_petir jebakan_tanah
     layar_local_play main_menu migrasi_host pemain pemain_dasar pemain_duel pemain_jaringan pemain_kartu pemain_papan
     pemain_role pemain_tampilan petak_kartu profil_pemain status_jaringan ui_dinamis ui_elemen ui_petak ui_profil ui_role` (.gd).
     6 file sisa di `game/` (T21): `petak_papan`, `koin_tercecer`, `petak_permata`, `lingkungan_pantai`, `rolet` (tidak pernah
     diubah Fase 4, identik dgn rig) + `pengelola_iklan` (produksi asli AdMob; rig pakai stub). Ada di `game/` supaya proyek
     lengkap; pemilik sudah punya -> tidak dikirim.
  3. Komentar `AMBANG_NILAI` (F5 r1 50->40) & `AMBANG_PELUANG` (F5 r2 80->90) di `ai_jebakan.gd` game + rig; angka tidak berubah.
  4. 97 vs 96 = skenario **D1** (3P c1 keluar saat pilih elemen): di run F6 c1 tidak sempat jadi peserta duel (hanya 1
     kesempatan/pertandingan, giliran 24) -> main sampai habis, +1 SELESAI. Run ulang D1 (angka F6 & angka lama): c1 keluar di
     giliran 24, 2 baris, 0 error -> variasi timing, bukan regresi; jalur D1 kini sudah teruji. Data: `hasil/f6_regresi/tinjauan_mp_d1/`.
- **F7 SELESAI (Opus, 02-10):** grep counter/debug sementara/print/TODO di `game/` = 0; saklar UJI_* false; 34/35 `game/` identik
  dgn rig (beda hanya `pengelola_iklan.gd`, disengaja); `cek_muat_f3` 26/26, `cek_nilai` 8/8; `uji_tanah2.gd` (rig-only)
  diperbaiki -> 0 SCRIPT ERROR. Data: `hasil/f7_bersih/F7_cek.txt`.
- **F8 SELESAI (02-10):** `kiriman/TileDuel_FaseB_b9.zip` = 29 .gd + RENCANA = 30 file. Pemilik: buang unduhan lama, TIMPA ke-29
  file (14 berbeda dari commit fe39bec/b8 -- jangan hanya salin yang berubah di F6), buka Godot, tunggu impor, uji HP RENCANA
  bagian 10 (Langkah A + B). `ID_INTERSTISIAL_ASLI` (`pengelola_iklan.gd`) masih kosong -- keputusan pemilik sebelum rilis.
- **UJI HP b9 LOLOS (02-10, laporan pemilik: "lancar") -> Fase 4 SELESAI** (RENCANA 14.24). `game/` = isi ZIP b9 (dicek
  byte-per-byte); jangan ubah `game/` sebelum rilis kecuali ada bug.
- **BERIKUTNYA (pemilik): rilis A+B.** Daftar periksa (rincian RENCANA 14.24): (1) isi `ID_INTERSTISIAL_ASLI` atau sengaja
  biarkan iklan uji; (2) naikkan version code; (3) uji pasang-timpa di atas versi Play (profil lama utuh, layar ROLE minta role);
  (4) coba build rilis sekali; (5) Internal testing -> Production. Bug dari HP/rilis -> Opus menganalisis dulu.
- **Fase 5 (rencana Opus 02-10, DISETUJUI): `docs/RENCANA_fase5_seru.md`** -- event papan, bounty, kartu bantuan posisi terakhir, Tebak Duel,
  putar ulang rolet (iklan, solo), tombol AI cepat (solo). Status: **DISETUJUI 02-10, pemilik "setuju semua a"**
  (dicatat di bagian 1 & 9 rencana itu). Berikutnya: **Sonnet** mengerjakan G0 (refactor tanpa perubahan perilaku,
  harus identik di rig) dst. Baca rencana itu PENUH (pendek, ~200 baris); RENCANA_fase4 hanya untuk rujukan.
- Opsional (Sonnet, tidak menghalangi rilis): T22 (rig-only, D1 lebih kuat, RENCANA 14.23); komentar F5 untuk
  `hot_flames`/`fire_tax`/`strong_wind` di `data_role.gd` (komentar saja; ikut kiriman berikutnya).
- Cara regresi MP di sesi cloud: salin `rig/skrip/jalankan_mp3.sh`, `uji_f2_t2_a/b.sh` ke scratchpad, ganti path
  (`SP`, `G=/opt/godot/...`, `PROJ=rig/proj_tanpa_uji`); jalankan A lalu B BERURUTAN (~1 jam total di 4 inti).

## 6. Konteks pengguna
Akun Claude Pro berakhir pekan ini; pengguna mungkin lanjut dengan akun Free + kredit sesi cloud (khusus Claude Code cloud, via browser).
Hemat token: jangan baca ulang RENCANA penuh (~2000 baris) -- baca 14.19 dan bagian STATUS di bawah; jalankan rig di background lalu `sleep` panjang.
