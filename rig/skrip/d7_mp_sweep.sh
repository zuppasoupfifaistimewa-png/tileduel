#!/bin/bash
SP=/tmp/claude-0/-home-claude/bc2a37a6-77d5-5593-942f-124ebd210f19/scratchpad
# D7.5: mode 2P+2AI (2) & 3P+1AI (4), 2 peta, giliran cukup panjang utk AI sempat pasang jebakan.
PROJ=proj bash jalankan_mp3.sh d7mp_1 2 alam 1 "" 20 401 10 2>&1
PROJ=proj bash jalankan_mp3.sh d7mp_2 2 pantai 1 "" 20 402 10 2>&1
PROJ=proj bash jalankan_mp3.sh d7mp_3 4 alam 2 "" 20 403 10 2>&1
PROJ=proj bash jalankan_mp3.sh d7mp_4 4 pantai 2 "" 20 404 10 2>&1
# client keluar diambil AI:
PROJ=proj EXTRA="" bash jalankan_mp3.sh d7mp_5 2 alam 1 client_keluar 20 405 6 2>&1
# migrasi host:
PROJ=proj bash jalankan_mp3.sh d7mp_6 4 alam 2 host_keluar_migrasi 20 406 6 2>&1
echo "D7_MP_SWEEP_SELESAI"
