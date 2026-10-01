#!/bin/bash
# T4 (Fase 2): adegan asli solo -- hadiah profil, berkas, muat ulang, kartu hadiah, DOUBLE, EXIT.
SP=/tmp/claude-0/-home-claude/bc2a37a6-77d5-5593-942f-124ebd210f19/scratchpad
cd $SP
rm -f sim/f2t4_*
satu() { PROJ=$SP/proj_tanpa_uji EXTRA="panjang=$4 profil=1 iklan=1" ./jalankan_nyata.sh f2t4_$4 $1 $2 $3 200 > /dev/null; }
export -f satu; export SP
{
  for PJ in quick classic; do for NL in 1 2 3; do for PT in alam pantai; do
    echo "$NL $PT $((NL*10+${#PT})) $PJ"
  done; done; done
} | xargs -P 2 -L 1 bash -c 'satu "$0" "$1" "$2" "$3"'
for f in sim/f2t4_*.log; do
  echo "$(basename $f .log): $(grep -a '^PROFIL_CEK' $f | head -1) | scripterr=$(grep -ac 'SCRIPT ERROR' $f) | $(grep -a '^SIM' $f | tail -1)"
done
echo T4_SELESAI
