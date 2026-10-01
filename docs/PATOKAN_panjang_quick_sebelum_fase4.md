# Patokan panjang pertandingan Quick Match — SEBELUM Fase 4

Diukur 25-09 oleh Sonnet, di rig saja (tidak menyentuh file game). Kode yang diuji = produksi
pasca-Fase-3 (7 file pemain_*.gd berantai), saklar UJI_* mati, disalin ke `proj_tanpa_uji` lewat
`sinkron_tanpa_uji.sh` yang sudah ada. Alat: `uji_nyata.gd` (rig T4/T5, sudah ada, TIDAK diubah) --
adegan asli, robot menekan tombol UI asli di slot 0, AI mengisi slot lain, 2 peta (Grassland/alam,
Night Beach/pantai), mode QUICK MATCH sungguhan (bukan simulasi papan generik `uji_sim.gd`).

Jumlah: 240 pertandingan total, 0 script error, 0 GAGAL, 0 cek AKHIR yang salah (kekayaan/pemenang
cocok dengan hitungan independen di rig).
- 2 pemain (lawan=1): 60 benih x 2 peta = 120 pertandingan
- 3 pemain (lawan=2): 30 benih x 2 peta = 60 pertandingan
- 4 pemain (lawan=3): 30 benih x 2 peta = 60 pertandingan

## Hasil

| Jumlah pemain | n   | Giliran rata2 | Giliran median | Detik rata2 (in-game) | Batas naik 15% (detik) |
|----------------|-----|---------------|-----------------|------------------------|--------------------------|
| 2 pemain       | 120 | 14,11 (±0,68 CI95) | 16 | 276,6 dtk (±15,1 CI95) | **318,1 dtk** |
| 3 pemain       | 60  | 16,25 (±0,88 CI95) | 18 | 348,2 dtk (±23,6 CI95) | **400,4 dtk** |
| 4 pemain       | 60  | 18,13 (±0,88 CI95) | 20 | 403,3 dtk (±25,2 CI95) | **463,8 dtk** |

Catatan penting:
- **Giliran (jumlah putaran) punya batas atas tetap** = `batas_ronde x jumlah_pemain` (2p: 16, 3p: 18,
  4p: 20) -- ini tidak berubah oleh Fase 4 (K4/role tidak mengubah `BATAS_RONDE_QUICK`). Jadi jumlah
  giliran BUKAN ukuran yang sensitif untuk mendeteksi kenaikan akibat Fase 4.
- **Detik (waktu dalam-permainan, dihitung dari delta `_process` yang sudah kena `Engine.time_scale`,
  jadi ini mendekati waktu yang dialami pemain sungguhan, BUKAN waktu nyata proses rig yang jauh lebih
  cepat)** adalah ukuran yang tepat untuk syarat "panjang Quick naik paling banyak 15%", karena Fase 4
  menambah aksi (AI memasang jebakan, animasi jebakan ~1,5 dtk, kemungkinan duel elemen tambahan dari
  ketahanan/serangan role) yang menambah waktu per giliran tanpa menambah jumlah giliran.
- Alasan pertandingan berakhir (2 pemain): 90/120 kena batas ronde ("ronde" -- 8 ronde penuh), 30/120
  menang lebih awal lewat target permata ("start"). Pola serupa di 3 & 4 pemain.
- Per peta (2 pemain): alam rata2 14,32 giliran, pantai rata2 13,90 giliran -- beda kecil, wajar.

## Cara pakai patokan ini di U3 (uji keseimbangan Fase 4)

Setelah Langkah A/B ditulis, jalankan pertandingan Quick yang SEPADAN (2/3/4 pemain, peta sama,
`panjang=quick`) lewat rig `f4/uji_seimbang.sh` yang akan dibuat sesuai rencana, ambil rata-rata
`detik` per jumlah pemain, lalu bandingkan dengan kolom "Batas naik 15%" di atas. Kalau rata-rata detik
sesudah Fase 4 melebihi batas itu, berarti pertandingan Quick jadi terlalu panjang dan perlu
disesuaikan (mis. animasi jebakan dipercepat, AI dibuat lebih pelit memasang jebakan, dll) sebelum
rilis.

Data mentah: `scratchpad/sim/base_l{1,2,3}_{alam,pantai}_s{200..259}.log` (240 berkas, sesi ini).
Skrip: `scratchpad/f4/baseline_quick.sh`.
