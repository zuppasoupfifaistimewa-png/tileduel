#!/bin/bash
cd /tmp/claude-0/-home-claude/bc2a37a6-77d5-5593-942f-124ebd210f19/scratchpad
X="pedang_awal=1 kartu_awal=1"
echo "== A0 1v1 (+kartu)";        EXTRA="$X" ./jalankan_mp3.sh ua_m0f1 0 alam 1 "" 30 11
echo "== A1 2P+1AI (+kartu)";     EXTRA="$X" ./jalankan_mp3.sh ua_m1f1 1 alam 1 "" 30 12
echo "== A2 2P+2AI (+kartu)";     EXTRA="$X" ./jalankan_mp3.sh ua_m2f1 2 alam 1 "" 30 13
echo A_SELESAI
