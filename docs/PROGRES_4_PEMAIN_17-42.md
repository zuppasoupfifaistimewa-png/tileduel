# Progres: Tile Duel 2–4 pemain (21 Sep 2026, 17:42)

**Status: BELUM BISA DIPAKAI.** File `pemain_WIP_BELUM_BISA_DIPAKAI.gd` adalah cadangan
pekerjaan yang sedang berjalan. JANGAN dimasukkan ke proyek dulu — file lain yang
dipanggilnya belum ikut diubah, jadi game akan error. Pakai terus file versi kiriman
terakhir (Exit to Main Menu, HOW TO WIN, animasi menang/kalah, dst).

## Sudah dikerjakan (di pemain.gd)
- Data per slot untuk 4 pemain (dadu, putaran, permata, uang tampil) + nama lama tetap ada.
- Pembantu slot: model/animasi/warna per slot, P3 (hijau) & P4 (kuning) dibuat dari salinan Musuh.
- Pergantian giliran umum 0→1→2→3 (`_mulai_giliran`), jalan/jebakan/koin/permata/Start/kartu per slot.
- Menu petak: konfrontasi & serangan berlaku untuk petak milik pemain lain mana pun.
- Denda, hasil duel, jual aset (AI & manusia), serangan jarak jauh — umum per slot.
- Duel 2–4 pemain: naskah per slot, peserta/penonton, koin seri untuk peserta AI.
- Sinkron jaringan N device (state, kartu, pedang, cabang, koin) + teks narasi dari sudut pandang tiap device.
- HUD 3–4 pemain (panel YOU + daftar lawan), posisi 4 karakter di satu petak.
- OPPONENT LEFT tanpa tukar slot: client tetap slot & warnanya, AI mengambil alih slot yang keluar.
- Teks 2 pemain dijaga sama persis dengan versi lama.

## Belum dikerjakan
- `ai_musuh.gd`: AI untuk slot mana pun + `pilih_pedang_ai` (pemain.gd sudah memanggilnya).
- `ui_elemen.gd`: `atur_sudut_pandang`, `skor_duel`, mode tonton & koin otomatis AI vs AI.
- `ui_dinamis.gd`: `atur_hud_banyak_pemain`, nama pemilih di panel cabang, target kartu 3–4 pemain.
- `petak_kartu.gd`: nama aktor di judul + mode "ai".
- `ui_petak.gd`, `jebakan_air.gd`, `jebakan_api.gd`: warna/slot 3–4.
- `status_jaringan.gd`, `main_menu.gd` (pilih 1/2/3 AI), `layar_local_play.gd` (lobby 5 mode + peta).
- Semua pengujian (simulasi 1v1 lama vs baru, 35 skenario 2 device, 3 device).

## Urutan lanjutan
1. Checkpoint: file-file di atas sampai bisa jalan + perbaikan OPPONENT LEFT → uji → kirim.
2. Solo 1 vs 2/3 AI.
3. Lobby multiplayer 5 mode + pilih peta + uji 3 device.
