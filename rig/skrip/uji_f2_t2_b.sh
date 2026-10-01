#!/bin/bash
# T2 (Fase 2) bagian B -- dijalankan di network namespace sendiri.
cd /tmp/claude-0/-home-claude/bc2a37a6-77d5-5593-942f-124ebd210f19/scratchpad
SP=$PWD
X="pedang_awal=1 kartu_awal=1"
Q="panjang=quick"
echo "== D3 3P+1AI host keluar saat pilih elemen"; EXTRA="$X" ./jalankan_mp3.sh f2_d3 4 alam 2 host_keluar_duel 40 33
echo "== D4 2P+1AI host keluar saat pilih elemen"; EXTRA="$X" ./jalankan_mp3.sh f2_d4 1 alam 1 host_keluar_duel 40 34
echo "== B0 4P (+kartu)";            EXTRA="$X" ./jalankan_mp3.sh f2_b0 5 alam 3 "" 30 41
echo "== B1 4P pantai";              ./jalankan_mp3.sh f2_b1 5 pantai 3 "" 30 42
echo "== B2 4P c3 keluar g8";        ./jalankan_mp3.sh f2_b2 5 alam 3 client_keluar 30 43 8 3
echo "== B3 4P c2 keluar pilih elemen"; EXTRA="$X" ./jalankan_mp3.sh f2_b3 5 alam 3 client_keluar_duel 30 44 8 2
echo "== B4 4P host keluar g8 (lanjut sendiri)"; ./jalankan_mp3.sh f2_b4 5 alam 3 host_keluar 40 45 8
echo "== A0 1v1 (+kartu)";        EXTRA="$X" ./jalankan_mp3.sh f2_a0 0 alam 1 "" 30 11
echo "== A1 2P+1AI (+kartu)";     EXTRA="$X" ./jalankan_mp3.sh f2_a1 1 alam 1 "" 30 12
echo "== A2 2P+2AI (+kartu)";     EXTRA="$X" ./jalankan_mp3.sh f2_a2 2 alam 1 "" 30 13
echo "== A3 3P (+kartu)";         EXTRA="$X" ./jalankan_mp3.sh f2_a3 3 alam 2 "" 30 14
echo "== A4 3P+1AI (+kartu)";     EXTRA="$X" ./jalankan_mp3.sh f2_a4 4 alam 2 "" 30 15
echo "== A5 3P+1AI pantai";       ./jalankan_mp3.sh f2_a5 4 pantai 2 "" 30 16
echo "== Q5 4P migrasi host g8";      EXTRA="$Q" ./jalankan_mp3.sh f2_q5 5 alam 3 host_keluar_migrasi 60 65 8
echo "== Q6 3P+1AI (+kartu)";         EXTRA="$Q $X" ./jalankan_mp3.sh f2_q6 4 alam 2 "" 60 66
echo "== Q7 3P client keluar g8";     EXTRA="$Q" ./jalankan_mp3.sh f2_q7 3 alam 2 client_keluar 60 67 8 2
echo "== Q8 3P+1AI hotspot P1 mati di giliran terakhir"; EXTRA="$Q" ./jalankan_mp3.sh f2_q8 4 alam 2 host_hotspot_mati 60 68 20
echo "== Q1n 1v1 alam (UJI mati)";    PROJ=$SP/proj_tanpa_uji EXTRA="$Q" ./jalankan_mp3.sh f2_q1n 0 alam 1 "" 60 71
echo "== Q4n 4P pantai (UJI mati)";   PROJ=$SP/proj_tanpa_uji EXTRA="$Q" ./jalankan_mp3.sh f2_q4n 5 pantai 3 "" 60 74
echo B_SELESAI
