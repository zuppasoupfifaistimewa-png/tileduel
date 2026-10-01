#!/bin/bash
cd /tmp/claude-0/-home-claude/bc2a37a6-77d5-5593-942f-124ebd210f19/scratchpad
echo "== mode 0 (1v1)";            ./jalankan_mp3.sh m0_alam 0 alam 1 "" 30 11
echo "== mode 1 (2P+1AI)";         ./jalankan_mp3.sh m1_alam 1 alam 1 "" 30 12
echo "== mode 2 (2P+2AI)";         ./jalankan_mp3.sh m2_alam 2 alam 1 "" 30 13
echo "== mode 3 (3P)";             ./jalankan_mp3.sh m3_alam 3 alam 2 "" 30 14
echo "== mode 4 (3P+1AI)";         ./jalankan_mp3.sh m4_alam 4 alam 2 "" 30 15
echo "== mode 4 pantai";           ./jalankan_mp3.sh m4_pantai 4 pantai 2 "" 30 16
echo "== mode 1 pantai";           ./jalankan_mp3.sh m1_pantai 1 pantai 1 "" 30 17
echo BATCH_SELESAI
