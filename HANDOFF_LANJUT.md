# HANDOFF -- lanjutkan proyek Tile Duel (Fase 4 Langkah B-f, tahap F5)

Dokumen ini ditulis 02-10-2026 supaya sesi Claude Code (cloud / web, tanpa CLI) mana pun bisa melanjutkan
pekerjaan TANPA riwayat percakapan. BACA INI DULU, lalu `docs/RENCANA_fase4_role.md` bagian 14.19 sampai akhir.

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

## 1. Isi repo
| Folder | Isi |
|---|---|
| `game/` | SET PRODUKSI resmi saat ini (semua .gd). F1-F4 sudah diterapkan (P13, K23, T19). **Belum ada angka hasil F5.** |
| `docs/` | `RENCANA_fase4_role.md` = sumber kebenaran tunggal (bagian 14.19 = rencana B-f; status F0-F4 di bagian paling bawah). Plus rencana fase lama & patokan. |
| `rig/proj_tanpa_uji/` | Proyek Godot lengkap untuk rig simulasi (headless): produksi + `uji_*.gd/.tscn`. **Isinya = produksi + ANGKA KANDIDAT F5 putaran 3** (lihat bagian 3), BUKAN produksi murni. Cache `.godot/` dibuang -> impor ulang dulu (bagian 4). |
| `rig/skrip/` | `f4/uji_seimbang.sh` (pelari), `f4/ringkas_seimbang.py` (ringkasan win-rate + CI), `f4/buat_tugas_u9.py` (pembuat S1-S5), `f4/cek_panggil.py`, `f5_analisa.py`, `f5_pasangan.py`, skrip batch regresi `batch_reg10.sh`, `uji_f2_t2_a/b.sh`, dll. |
| `hasil/f4_u9_baseline_sebelum_tuning/` | Data S1 (1200, 2P) & S2 (400, 4P) SEBELUM penyetelan (S3 parsial 31 baris -- JANGAN dipakai). |
| `hasil/f5_putaran/r1,r2,r3/` | Hasil S1 tiap putaran penyetelan. r3 PARSIAL (633/1200, proses mati). |
| `f5_kandidat/*.patch` | Selisih produksi -> angka kandidat putaran 3 (data_role.gd, ai_jebakan.gd). |

## 2. Status ringkas (lihat RENCANA bagian bawah untuk rincian)
- F0-F3 selesai. F3 = regresi MP 37 skenario: 37/37 lolos.
- F4 (U9): S1 & S2 baseline selesai -> trigger eskalasi Opus terpicu (angin kuat, api lemah, jebakan/AI < 2).
- **F5 (penyetelan, Opus) SEDANG BERJALAN.** Data baseline S1 (2P, target tiap role 44-56%):
  | | air | angin | api | petir | tanah | jebakan/AI |
  |---|---|---|---|---|---|---|
  | baseline | 47.7 | **57.5** | **42.9** | 51.7 | 50.2 | 1.88 |
  | r1 | 47.5 | 54.2 | **42.9** | 54.0 | 51.5 | 1.99 |
  | r2 | 48.1 | 56.0 | 44.6 | 51.9 | 49.4 | 2.18 |
  | r3 | belum selesai (633/1200) | | | | | |
  Masalah sisa: **angin ~56%** (batas atas) dan pasangan **api vs petir ~34% (batas bawah CI > 55% untuk petir -> ditandai "!")**,
  karena petir punya ketahanan api (heat_skin) yang memotong bakaran. Sinyal Quick 4P (S2 baseline): angin 32.5 / api 19.8
  (target 20-30) -- BELUM diuji ulang setelah tuning.
- Putaran 1 mengubah: `AMBANG_NILAI` 50->40, `hot_flames` 70/80/90->75/90/105, `strong_wind` 0.12/.14/.16->0.11/.12/.13.
- Putaran 2 menambah: `AMBANG_PELUANG` 80->90, `hot_flames`->80/100/120, `fire_tax` 0.25/.5/.75->0.5/.75/1.0.
- Putaran 3 (kandidat saat ini, di `rig/` & `f5_kandidat/`): `hot_flames`->90/110/130, `homing_wind` 0.25/.5/.75->0.2/.4/.6.
- Urutan tuas P14 (jangan lompat): (1) konstanta P13 & `AMBANG_*`, (2) `NODE_LV` yang menyimpang, (3) `PRESET_URUTAN_JEBAKAN`/`PRESET`,
  (4) `BOBOT_TAHAN_AI`/K17-K19. JANGAN ubah `DASAR` kecuali ketimpangan juga muncul di S4 (Lv1).
- Derau: +-2.3 poin per role per 1200 pertandingan -- jangan mengejar derau. Konfirmasi akhir WAJIB di benih BARU.
- Setiap angka yang berubah dicatat (lama -> baru, alasan) di bagian 14.21 RENCANA (BELUM ditulis -- tugas Opus di akhir F5).

## 3. PENTING: rig != produksi
`rig/proj_tanpa_uji/` memakai angka kandidat F5. `game/` memakai angka ASLI. Jangan menyalin angka kandidat ke `game/`
sebelum lolos konfirmasi benih baru. `pengelola_iklan.gd` di rig sengaja beda (stub iklan untuk uji) -- jangan disalin ke `game/`.
Setelah angka final disetujui: terapkan HANYA baris yang berubah ke `game/data_role.gd` & `game/ai_jebakan.gd` (aturan 0.2).

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
7. Skrip `f4/uji_seimbang.sh` & beberapa skrip lama masih berisi path scratchpad lama -- ubah/override lewat env bila perlu.
   Skrip MP (`uji_f2_t2_a/b.sh`, LocalPlay.tscn) TIDAK boleh jalan paralel (port tetap) -- jalankan berurutan.

## 5. Langkah berikutnya (rencana terkunci, bagian 14.19)
- **F5 (Opus):** selesaikan penyetelan. Ide yang belum dicoba: kurangi keunggulan petir vs api lewat bobot nilai AI / `NODE_LV`
  `heat_skin`-terkait, atau sedikit naikkan `long_burn`; turunkan angin sedikit lagi (`strong_wind`/`whirlwind`) bila r3 masih >56%.
  Lalu konfirmasi di BENIH BARU (ubah benih mulai di `buat_tugas_u9.py`, bukan 5000). Catat semua di 14.21.
- **F6 (Sonnet):** verifikasi akhir. Bila kredit/kuota menipis, pangkas jadi ulang S1+S2 saja dengan benih baru (kesepakatan pengguna 28-09),
  tapi regresi MP 37 skenario TETAP wajib bila F5 mengubah `ai_jebakan.gd`/`ai_musuh.gd` (angka `data_role.gd` saja tidak mengubah AI,
  tetapi `cek_nilai=1` & `U11` tetap dijalankan).
- **F7:** grep counter/debug sementara = 0; sinkron rig; diff bersih. **F8:** kirim 29 .gd resmi + RENCANA = 30 file (satu ZIP).
- Ukuran U9 penuh (K24): S3 (solo Lv20 2P, 1200), S4 (solo Lv1 2P, 400), S5 (panjang, 240) BELUM dijalankan -- jalankan SETELAH angka final.

## 6. Konteks pengguna
Akun Claude Pro berakhir pekan ini; pengguna mungkin lanjut dengan akun Free + kredit sesi cloud (khusus Claude Code cloud, via browser).
Hemat token: jangan baca ulang RENCANA penuh (~2000 baris) -- baca 14.19 dan bagian STATUS di bawah; jalankan rig di background lalu `sleep` panjang.
