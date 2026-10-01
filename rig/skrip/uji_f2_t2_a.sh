#!/bin/bash
# T2 (Fase 2) bagian A -- dijalankan di network namespace sendiri.
cd /tmp/claude-0/-home-claude/bc2a37a6-77d5-5593-942f-124ebd210f19/scratchpad
SP=$PWD
X="pedang_awal=1 kartu_awal=1"
Q="panjang=quick"
echo "== M1 3P+1AI -> 2P+2AI";        ./jalankan_mp3.sh f2_m1 4 alam 2 host_keluar_migrasi 40 51 8
echo "== M2 4P -> 3P+1AI";            ./jalankan_mp3.sh f2_m2 5 alam 3 host_keluar_migrasi 40 52 8
echo "== M3 4P, P4 main sendiri";     ./jalankan_mp3.sh f2_m3 5 alam 3 migrasi_sendiri 40 53 8
echo "== M4 rebutan";                 ./jalankan_mp3.sh f2_m4 4 alam 2 migrasi_rebutan 40 54 8
echo "== M5 host keluar saat pilih elemen"; EXTRA="$X" ./jalankan_mp3.sh f2_m5 5 alam 3 host_keluar_duel_migrasi 40 55
echo "== M6 migrasi dua kali";        ./jalankan_mp3.sh f2_m6 5 alam 3 migrasi_dua_kali 50 56 8
echo "== M7 hotspot P1 mati, P1 kembali"; ./jalankan_mp3.sh f2_m7 4 alam 2 host_hotspot_mati 40 57 8
echo "== M8 P1 kembali terlambat";    ./jalankan_mp3.sh f2_m8 5 alam 3 host_hotspot_telat 40 58 8
echo "== A6 2P+1AI pantai";           ./jalankan_mp3.sh f2_a6 1 pantai 1 "" 30 17
echo "== S1 3P c2 keluar g8";         ./jalankan_mp3.sh f2_s1 3 alam 2 client_keluar 30 21 8 2
echo "== S2 3P+1AI c1 keluar g10";    ./jalankan_mp3.sh f2_s2 4 alam 2 client_keluar 30 22 10 1
echo "== S3 3P host keluar g8";       ./jalankan_mp3.sh f2_s3 3 alam 2 host_keluar 40 23 8
echo "== D1 3P c1 keluar saat pilih elemen";  EXTRA="$X" ./jalankan_mp3.sh f2_d1 3 alam 2 client_keluar_duel 30 31 8 1
echo "== D2 1v1 c1 keluar saat pilih elemen"; EXTRA="$X" ./jalankan_mp3.sh f2_d2 0 alam 1 client_keluar_duel 25 32 8 1
echo "== Q1 1v1 alam";                EXTRA="$Q" ./jalankan_mp3.sh f2_q1 0 alam 1 "" 60 61
echo "== Q2 2P+1AI pantai";           EXTRA="$Q" ./jalankan_mp3.sh f2_q2 1 pantai 1 "" 60 62
echo "== Q3 3P alam";                 EXTRA="$Q" ./jalankan_mp3.sh f2_q3 3 alam 2 "" 60 63
echo "== Q4 4P alam";                 EXTRA="$Q" ./jalankan_mp3.sh f2_q4 5 alam 3 "" 60 64
echo A_SELESAI
