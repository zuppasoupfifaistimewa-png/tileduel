#!/bin/bash
# T1 (Fase 2): jejak sim kode sebelum Fase 2 vs kode Fase 2 harus identik
# (Classic UJI nyala, Classic UJI mati, Quick UJI mati). Dua proses sekaligus.
SP=/tmp/claude-0/-home-claude/bc2a37a6-77d5-5593-942f-124ebd210f19/scratchpad
cd $SP
rm -f sim/f2*
daftar() { # <label> <proj> [extra]
  for NP in 2 3 4; do for NM in 0 1; do for SD in 7 8 9; do
    echo "$1 $2 $NP $NM $SD ${3:--}"
  done; done; done
}
satu() { X="$6"; [ "$X" = "-" ] && X=""; EXTRA="$X" ./jalankan_sim.sh $SP/$2 $1 $3 $4 $5 60 > /dev/null; }
export -f satu; export SP
{
  daftar f2lama proj_sebelum_fase2
  daftar f2baru proj
  daftar f2lamaN proj_sebelum_fase2_tanpa_uji
  daftar f2baruN proj_tanpa_uji
  daftar f2lamaQ proj_sebelum_fase2_tanpa_uji quick=1
  daftar f2baruQ proj_tanpa_uji quick=1
} | xargs -P 2 -L 1 bash -c 'satu "$0" "$1" "$2" "$3" "$4" "$5"'
BEDA=0; SAMA=0
for f in sim/f2lama_*.txt sim/f2lamaN_*.txt sim/f2lamaQ_*.txt; do
  g=${f/f2lama/f2baru}
  if cmp -s "$f" "$g"; then SAMA=$((SAMA+1)); else BEDA=$((BEDA+1)); echo "BEDA: $f"; diff "$f" "$g" | head -6; fi
done
echo "T1 SAMA=$SAMA BEDA=$BEDA err_baru=$(cat sim/f2baru*.log | grep -ac 'SCRIPT ERROR') stat_salah=$(cat sim/f2baru*.log | grep -ac 'STAT_CEK SALAH') stat_ok=$(cat sim/f2baru*.log | grep -ac 'STAT_CEK OK')"
grep -ah "^SIM" sim/f2baru*.log | awk '{print $2}' | sort | uniq -c
echo T1_SELESAI
