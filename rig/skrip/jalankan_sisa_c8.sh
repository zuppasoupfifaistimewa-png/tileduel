#!/bin/bash
# Jalankan berurutan (bukan paralel, hindari kontensi CPU 2-core):
# 1) migrasi host  2) 3P  3) peta pantai  4) custom_ilegal re-konfirmasi
set -x
cd /tmp/claude-0/-home-claude/bc2a37a6-77d5-5593-942f-124ebd210f19/scratchpad
bash jalankan_mp3.sh c8_migrasi_host 5 "" 3 host_keluar_migrasi 30 7 8 2
bash jalankan_mp3.sh c8_3p 3 alam 2 "" 30 7 8 2
bash jalankan_mp3.sh c8_pantai 0 pantai 1 "" 24 7 8 2
EXTRA="arena=custom_ilegal" bash jalankan_mp3.sh c8_custom_ilegal 0 "" 1 "" 20 7 8 2
echo "SEMUA_SISA_C8_SELESAI"
