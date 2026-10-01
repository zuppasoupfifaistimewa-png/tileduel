#!/bin/bash
cd /tmp/claude-0/-home-claude/bc2a37a6-77d5-5593-942f-124ebd210f19/scratchpad
echo "== K3b 1v1 kartu_awal";               EXTRA="kartu_awal=1" ./jalankan_mp3.sh k3b_m0 0 alam 1 "" 24 63
echo "== K2b 2P+1AI pantai kartu_awal";     EXTRA="kartu_awal=1" ./jalankan_mp3.sh k2b_m1 1 pantai 1 "" 24 62
echo "== K6 2P+2AI kartu_awal";             EXTRA="kartu_awal=1" ./jalankan_mp3.sh k6_m2 2 alam 1 "" 24 66
./batch_reg10.sh > reg10.out 2>&1; sed 's/^/REG: /' reg10.out
echo C3B_SELESAI
