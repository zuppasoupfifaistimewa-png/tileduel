#!/bin/bash
cd /tmp/claude-0/-home-claude/bc2a37a6-77d5-5593-942f-124ebd210f19/scratchpad
X="pedang_awal=1 kartu_awal=1"
echo "== A3 3P (+kartu)";         EXTRA="$X" ./jalankan_mp3.sh ua_m3f1 3 alam 2 "" 30 14
echo "== A4 3P+1AI (+kartu)";     EXTRA="$X" ./jalankan_mp3.sh ua_m4f1 4 alam 2 "" 30 15
echo "== A5 3P+1AI pantai";       ./jalankan_mp3.sh ua_m4pf1 4 pantai 2 "" 30 16
echo B_SELESAI
