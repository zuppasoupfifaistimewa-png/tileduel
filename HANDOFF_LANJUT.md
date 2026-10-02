# HANDOFF -- lanjutkan proyek Tile Duel (Fase 4 Langkah B-f, tahap F6)

Dokumen ini ditulis 02-10-2026 supaya sesi Claude Code (cloud / web, tanpa CLI) mana pun bisa melanjutkan
pekerjaan TANPA riwayat percakapan. BACA INI DULU, lalu `docs/RENCANA_fase4_role.md` bagian 14.19 & **14.21** (paling akhir).
Diperbarui 02-10 (Opus, sesi Claude Code cloud): **F5 SELESAI, semua syarat P14 lolos di benih baru.**

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
| `game/` | SET PRODUKSI resmi saat ini (semua .gd). F1-F4 sudah diterapkan (P13, K23, T19). **Angka final F5 BELUM diterapkan (tugas F6).** |
| `docs/` | `RENCANA_fase4_role.md` = sumber kebenaran tunggal (bagian 14.19 = rencana B-f; status F0-F4 di bagian paling bawah). Plus rencana fase lama & patokan. |
| `rig/proj_tanpa_uji/` | Proyek Godot lengkap untuk rig simulasi (headless): produksi + `uji_*.gd/.tscn`. **Isinya = produksi + ANGKA FINAL F5 (r5)**, BUKAN produksi murni. Cache `.godot/` tidak di-git -> impor ulang dulu (bagian 4). |
| `rig/skrip/` | `f4/uji_seimbang.sh` (pelari), `f4/ringkas_seimbang.py` (ringkasan win-rate + CI), `f4/buat_tugas_u9.py` (pembuat S1-S5), `f4/cek_panggil.py`, `f5_analisa.py`, `f5_pasangan.py`, skrip batch regresi `batch_reg10.sh`, `uji_f2_t2_a/b.sh`, dll. |
| `hasil/f4_u9_baseline_sebelum_tuning/` | Data S1 (1200, 2P) & S2 (400, 4P) SEBELUM penyetelan (S3 parsial 31 baris -- JANGAN dipakai). |
| `hasil/f5_putaran/r1..r4/` | Hasil S1 tiap putaran penyetelan (r3 lengkap 1200; r4 + S2 4P). |
| `hasil/f5_konfirmasi_b20000/` | KONFIRMASI angka final, benih baru 20000: S1-S5 (+ berkas `.tugas`). |
| `hasil/f5_s4_tambahan/` | S4 tambahan 800 (benih 30000 & 40000) -- digabung dengan S4 benih 20000. |
| `f5_kandidat/*.patch` | Selisih produksi -> ANGKA FINAL F5 (data_role.gd, ai_jebakan.gd). Panduan F6. |

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
   **Sesi Claude Code cloud (02-10):** unduhan Godot dari GitHub releases LOLOS lewat proxy; mesin 4 inti -> `PARALEL=4`,
   S1 (1200) ~20 menit, S2 (400) ~10 menit. Hasil deterministik per benih (tidak bergantung PARALEL). Jalankan tiap rantai
   sebagai perintah latar belakang terpisah (<30 menit tiap perintah). Cek proses dengan `ps -eo comm | grep -c ^Godot`
   -- JANGAN `pgrep -f Godot_v4` (cocok dengan baris perintah sendiri).
   `buat_tugas_u9.py <dir> <benih_awal>` -- argumen ke-2 = benih awal (bawaan 5000).
7. Skrip `f4/uji_seimbang.sh` & beberapa skrip lama masih berisi path scratchpad lama -- ubah/override lewat env bila perlu.
   Skrip MP (`uji_f2_t2_a/b.sh`, LocalPlay.tscn) TIDAK boleh jalan paralel (port tetap) -- jalankan berurutan.

## 5. Langkah berikutnya
- **F6 (Sonnet) -- BERIKUTNYA:** terapkan HANYA baris angka final (bagian 2) ke `game/data_role.gd` & `game/ai_jebakan.gd`
  (aturan 0.2; panduan = `f5_kandidat/*.patch`; JANGAN salin `pengelola_iklan.gd` rig). Perbarui 3 harapan `cek_nilai` di
  `rig/proj_tanpa_uji/uji_nyata.gd` ke angka final (lihat RENCANA 14.21) -> `cek_nilai=1` 8/8. Lalu rig = produksi + uji
  (diff `game/` vs rig hanya `pengelola_iklan.gd`). Regresi MP 37 skenario WAJIB (`uji_f2_t2_a/b.sh`, BERURUTAN, port tetap)
  karena ai_jebakan.gd berubah; `batch_reg10.sh`; U11.
- **F7:** grep counter/debug sementara = 0; sinkron rig; diff bersih. **F8:** kirim 29 .gd resmi + RENCANA = 30 file (satu ZIP).

## 6. Konteks pengguna
Akun Claude Pro berakhir pekan ini; pengguna mungkin lanjut dengan akun Free + kredit sesi cloud (khusus Claude Code cloud, via browser).
Hemat token: jangan baca ulang RENCANA penuh (~2000 baris) -- baca 14.19 dan bagian STATUS di bawah; jalankan rig di background lalu `sleep` panjang.
