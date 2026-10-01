#!/bin/bash
cd /tmp/claude-0/-home-claude/bc2a37a6-77d5-5593-942f-124ebd210f19/scratchpad
while pgrep -f "batch_mp3.s[h]" > /dev/null; do sleep 5; done
echo "== S1 3P, client2 keluar giliran 8";        ./jalankan_mp3.sh s1_3p_c2keluar 3 alam 2 client_keluar 30 21 8 2
echo "== S2 3P+1AI, client1 keluar giliran 10";  ./jalankan_mp3.sh s2_3p1ai_c1keluar 4 alam 2 client_keluar 30 22 10 1
echo "== S3 3P, host keluar giliran 8";          ./jalankan_mp3.sh s3_3p_hostkeluar 3 alam 2 host_keluar 40 23 8
echo "== S4 2P+1AI, client keluar giliran 8";    ./jalankan_mp3.sh s4_2p1ai_ckeluar 1 alam 1 client_keluar 30 24 8 1
echo "== S5 2P+2AI, host keluar giliran 9";      ./jalankan_mp3.sh s5_2p2ai_hostkeluar 2 pantai 1 host_keluar 40 25 9
echo SKENARIO_SELESAI
