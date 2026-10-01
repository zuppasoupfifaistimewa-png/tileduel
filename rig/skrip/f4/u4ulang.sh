#!/bin/bash
# U4 ulang sesudah sambungan role diperbaiki (U3): skenario mewakili + skenario role.
cd /tmp/claude-0/-home-claude/bc2a37a6-77d5-5593-942f-124ebd210f19/scratchpad
SP=$PWD
X="pedang_awal=1 kartu_awal=1"
Q="panjang=quick"
echo "== A0 1v1 (+kartu)";        EXTRA="$X" ./jalankan_mp3.sh r_a0 0 alam 1 "" 30 11
echo "== A4 3P+1AI (+kartu)";     EXTRA="$X" ./jalankan_mp3.sh r_a4 4 alam 2 "" 30 15
echo "== S2 3P+1AI c1 keluar g10 (AI ambil alih, role tetap)"; ./jalankan_mp3.sh r_s2 4 alam 2 client_keluar 30 22 10 1
echo "== M1 3P+1AI -> migrasi host"; ./jalankan_mp3.sh r_m1 4 alam 2 host_keluar_migrasi 40 51 8
echo "== B0 4P (+kartu)";         EXTRA="$X" ./jalankan_mp3.sh r_b0 5 alam 3 "" 30 41
echo "== Q4n 4P pantai (UJI mati)"; PROJ=$SP/proj_tanpa_uji EXTRA="$Q" ./jalankan_mp3.sh r_q4n 5 pantai 3 "" 60 74
echo "== M5 host keluar saat pilih elemen (migrasi)"; EXTRA="$X" ./jalankan_mp3.sh r_m5 5 alam 3 host_keluar_duel_migrasi 40 55
echo "== ganti_role_2x";          ./jalankan_mp3.sh r_gr 0 alam 1 ganti_role_2x 15 81
echo "== host_ganti_mode_role";   ./jalankan_mp3.sh r_gm 3 alam 2 host_ganti_mode_role 20 82
echo U4ULANG_SELESAI
