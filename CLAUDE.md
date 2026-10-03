# Tile Duel -- memori proyek untuk Claude

Game papan 3D Godot 4.7.1 (GDScript), sudah rilis di Google Play. Pemilik proyek berbahasa Indonesia.

## Baca dulu, berurutan (sesi baru TIDAK bisa membaca percakapan lama)
1. `HANDOFF_LANJUT.md` -- aturan lengkap (bagian 0), status terbaru, cara menjalankan rig, langkah berikutnya.
2. `docs/LOG_SESI.md` -- ringkasan apa yang terjadi di tiap sesi sebelumnya.
3. `docs/RENCANA_fase4_role.md` -- HANYA bagian yang disebut HANDOFF (file ~2000 baris, jangan dibaca penuh).
Panduan untuk pemilik: https://claude.ai/code/artifact/bc2bfff0-d4f6-4ff0-89ed-16dd35ecbe48

## Aturan wajib (ringkas; versi lengkap di HANDOFF bagian 0)
- Balas dalam Bahasa Indonesia saja. Teks untuk pemain = bahasa Inggris sederhana.
- Edit file yang sudah ada: hanya baris relevan, jangan tulis ulang file.
- Beri arahan kapan ganti model: Opus = arsitektur / penyetelan keseimbangan / bug membingungkan;
  Sonnet = menulis kode dari rencana yang disepakati, cek diff, tambalan kecil.
- RNG game lewat `mesin_acak`, bukan `randi()`. Fungsi `ai_*.gd` hanya membaca state.
- Akhir tiap tahap: perbarui `HANDOFF_LANJUT.md` + data hasil, lalu push ke branch kerja `claude/kind-turing-b71jzs`
  (sejak Fase 9; kalau pemilik menyebut branch lain di awal sesi, ikuti pemilik). Branch default repo = `claude/new-session-e4ogqo`:
  diperbarui lewat PR dari branch kerja (Merge ditekan pemilik); `wonderful-gates-8v431l` sudah LAMA, jangan dipakai.
- Satu rantai simulasi saja; jangan ubah `rig/` selama simulasi berjalan
  (cek `ps -eo comm | grep -c ^Godot` = 0).
- Pantau panjang sesi: kalau sudah panjang, INGATKAN pemilik membuka sesi baru (setelah semua ter-push) dan
  beri prompt siap tempel.
- Akhir tiap sesi: tambah ringkasan ke `docs/LOG_SESI.md`, lalu push.
- `rig/` memakai angka kandidat/uji; `game/` = produksi resmi. Jangan salin `rig/proj_tanpa_uji/pengelola_iklan.gd`
  (stub iklan) ke `game/`.
