#!/bin/bash
cd /tmp/claude-0/-home-claude/bc2a37a6-77d5-5593-942f-124ebd210f19/scratchpad
./uji_akhir_duelkartu.sh
X="pedang_awal=1 kartu_awal=1"
echo "== B0 4P (+kartu)";            EXTRA="$X" ./jalankan_mp3.sh ub_m5 5 alam 3 "" 30 41
echo "== B1 4P pantai";              ./jalankan_mp3.sh ub_m5p 5 pantai 3 "" 30 42
echo "== B2 4P c3 keluar g8";        ./jalankan_mp3.sh ub_s1 5 alam 3 client_keluar 30 43 8 3
echo "== B3 4P c2 keluar pilih elemen"; EXTRA="$X" ./jalankan_mp3.sh ub_d1 5 alam 3 client_keluar_duel 30 44 8 2
echo "== B4 4P host keluar g8 (lanjut sendiri)"; ./jalankan_mp3.sh ub_s3 5 alam 3 host_keluar 40 45 8
echo REGRESI_SELESAI
