#!/bin/bash
# T3c (Fase 1): solo lewat adegan ASLI (menu -> QUICK/CLASSIC -> peta -> HOW TO WIN), UJI_* mati.
SP=/tmp/claude-0/-home-claude/bc2a37a6-77d5-5593-942f-124ebd210f19/scratchpad
cd $SP
rm -f sim/n3c_* sim/n3i_*
export PROJ=$SP/proj_tanpa_uji
for PJ in quick classic; do for NL in 1 2 3; do for PT in alam pantai; do
  GL=60; [ $PJ = classic ] && GL=30
  EXTRA="panjang=$PJ" ./jalankan_nyata.sh n3c_${PJ} $NL $PT $((NL*10+${#PT})) $GL
done; done; done
# iklan berhadiah (stub "tersedia"): FREE CARD & +300 COINS
EXTRA="panjang=quick iklan=1" ./jalankan_nyata.sh n3i_quick 1 alam 71 60
EXTRA="panjang=classic iklan=1" ./jalankan_nyata.sh n3i_classic 3 alam 72 60
echo T3C_SELESAI
