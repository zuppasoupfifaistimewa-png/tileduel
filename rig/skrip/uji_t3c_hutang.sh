#!/bin/bash
SP=/tmp/claude-0/-home-claude/bc2a37a6-77d5-5593-942f-124ebd210f19/scratchpad
cd $SP
rm -f sim/n3h_*
export PROJ=$SP/proj_tanpa_uji
EXTRA="panjang=classic iklan=1 uang0=60" ./jalankan_nyata.sh n3h_classic 3 alam 81 80
EXTRA="panjang=classic iklan=1 uang0=60" ./jalankan_nyata.sh n3h_classic 2 pantai 82 80
EXTRA="panjang=quick iklan=1 uang0=60" ./jalankan_nyata.sh n3h_quick 3 pantai 83 60
EXTRA="panjang=quick iklan=1 uang0=60" ./jalankan_nyata.sh n3h_quick 3 alam 84 60
echo HUTANG_SELESAI
