#!/bin/bash
cd /tmp/claude-0/-home-claude/bc2a37a6-77d5-5593-942f-124ebd210f19/scratchpad
rm -rf mp3/home_*
X="pedang_awal=1 kartu_awal=1"
echo "== A0 1v1 (+kartu)";        EXTRA="$X" ./jalankan_mp3.sh ua_m0 0 alam 1 "" 30 11
echo "== A1 2P+1AI (+kartu)";     EXTRA="$X" ./jalankan_mp3.sh ua_m1 1 alam 1 "" 30 12
echo "== A2 2P+2AI (+kartu)";     EXTRA="$X" ./jalankan_mp3.sh ua_m2 2 alam 1 "" 30 13
echo "== A3 3P (+kartu)";         EXTRA="$X" ./jalankan_mp3.sh ua_m3 3 alam 2 "" 30 14
echo "== A4 3P+1AI (+kartu)";     EXTRA="$X" ./jalankan_mp3.sh ua_m4 4 alam 2 "" 30 15
echo "== A5 3P+1AI pantai";       ./jalankan_mp3.sh ua_m4p 4 pantai 2 "" 30 16
echo "== A6 2P+1AI pantai";       ./jalankan_mp3.sh ua_m1p 1 pantai 1 "" 30 17
echo "== S1 3P c2 keluar g8";     ./jalankan_mp3.sh ua_s1 3 alam 2 client_keluar 30 21 8 2
echo "== S2 3P+1AI c1 keluar g10"; ./jalankan_mp3.sh ua_s2 4 alam 2 client_keluar 30 22 10 1
echo "== S3 3P host keluar g8";   ./jalankan_mp3.sh ua_s3 3 alam 2 host_keluar 40 23 8
echo "== D1 3P c1 keluar saat pilih elemen";   EXTRA="$X" ./jalankan_mp3.sh ua_d1 3 alam 2 client_keluar_duel 30 31 8 1
echo "== D2 1v1 c1 keluar saat pilih elemen";  EXTRA="$X" ./jalankan_mp3.sh ua_d2 0 alam 1 client_keluar_duel 25 32 8 1
echo "== D3 3P+1AI host keluar saat pilih elemen"; EXTRA="$X" ./jalankan_mp3.sh ua_d3 4 alam 2 host_keluar_duel 40 33
echo "== D4 2P+1AI host keluar saat pilih elemen"; EXTRA="$X" ./jalankan_mp3.sh ua_d4 1 alam 1 host_keluar_duel 40 34
echo SEMUA_SELESAI
