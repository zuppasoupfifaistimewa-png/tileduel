#!/bin/bash
# TAHAP 2 -- kode final (setelah perbaikan hasil review). M1-M8 lalu sisa regresi.
cd /tmp/claude-0/-home-claude/bc2a37a6-77d5-5593-942f-124ebd210f19/scratchpad
rm -rf mp3/home_*
X="pedang_awal=1 kartu_awal=1"
echo "== M1 3P+1AI -> 2P+2AI";        ./jalankan_mp3.sh fm_1 4 alam 2 host_keluar_migrasi 40 51 8
echo "== M2 4P -> 3P+1AI";            ./jalankan_mp3.sh fm_2 5 alam 3 host_keluar_migrasi 40 52 8
echo "== M3 4P, P4 main sendiri";     ./jalankan_mp3.sh fm_3 5 alam 3 migrasi_sendiri 40 53 8
echo "== M4 rebutan";                 ./jalankan_mp3.sh fm_4 4 alam 2 migrasi_rebutan 40 54 8
echo "== M5 host keluar saat pilih elemen"; EXTRA="$X" ./jalankan_mp3.sh fm_5 5 alam 3 host_keluar_duel_migrasi 40 55
echo "== M6 migrasi dua kali";        ./jalankan_mp3.sh fm_6 5 alam 3 migrasi_dua_kali 50 56 8
echo "== M7 hotspot P1 mati, P1 kembali"; ./jalankan_mp3.sh fm_7 4 alam 2 host_hotspot_mati 40 57 8
echo "== M8 P1 kembali terlambat";    ./jalankan_mp3.sh fm_8 5 alam 3 host_hotspot_telat 40 58 8
echo "== A6 2P+1AI pantai";       ./jalankan_mp3.sh ua_m1p 1 pantai 1 "" 30 17
echo "== S1 3P c2 keluar g8";     ./jalankan_mp3.sh ua_s1 3 alam 2 client_keluar 30 21 8 2
echo "== S2 3P+1AI c1 keluar g10"; ./jalankan_mp3.sh ua_s2 4 alam 2 client_keluar 30 22 10 1
echo "== S3 3P host keluar g8";   ./jalankan_mp3.sh ua_s3 3 alam 2 host_keluar 40 23 8
echo "== D1 3P c1 keluar saat pilih elemen";   EXTRA="$X" ./jalankan_mp3.sh ua_d1 3 alam 2 client_keluar_duel 30 31 8 1
echo "== D2 1v1 c1 keluar saat pilih elemen";  EXTRA="$X" ./jalankan_mp3.sh ua_d2 0 alam 1 client_keluar_duel 25 32 8 1
echo "== D3 3P+1AI host keluar saat pilih elemen"; EXTRA="$X" ./jalankan_mp3.sh ua_d3 4 alam 2 host_keluar_duel 40 33
echo "== D4 2P+1AI host keluar saat pilih elemen"; EXTRA="$X" ./jalankan_mp3.sh ua_d4 1 alam 1 host_keluar_duel 40 34
echo "== B0 4P (+kartu)";            EXTRA="$X" ./jalankan_mp3.sh ub_m5 5 alam 3 "" 30 41
echo "== B1 4P pantai";              ./jalankan_mp3.sh ub_m5p 5 pantai 3 "" 30 42
echo "== B2 4P c3 keluar g8";        ./jalankan_mp3.sh ub_s1 5 alam 3 client_keluar 30 43 8 3
echo "== B3 4P c2 keluar pilih elemen"; EXTRA="$X" ./jalankan_mp3.sh ub_d1 5 alam 3 client_keluar_duel 30 44 8 2
echo "== B4 4P host keluar g8 (lanjut sendiri)"; ./jalankan_mp3.sh ub_s3 5 alam 3 host_keluar 40 45 8
echo "== A0 1v1 (+kartu)";        EXTRA="$X" ./jalankan_mp3.sh ua_m0 0 alam 1 "" 30 11
echo "== A1 2P+1AI (+kartu)";     EXTRA="$X" ./jalankan_mp3.sh ua_m1 1 alam 1 "" 30 12
echo "== A2 2P+2AI (+kartu)";     EXTRA="$X" ./jalankan_mp3.sh ua_m2 2 alam 1 "" 30 13
echo "== A3 3P (+kartu)";         EXTRA="$X" ./jalankan_mp3.sh ua_m3 3 alam 2 "" 30 14
echo "== A4 3P+1AI (+kartu)";     EXTRA="$X" ./jalankan_mp3.sh ua_m4 4 alam 2 "" 30 15
echo "== A5 3P+1AI pantai";       ./jalankan_mp3.sh ua_m4p 4 pantai 2 "" 30 16
echo SEMUA_SELESAI
