#!/bin/bash
# T1 (Fase 1): jejak sim Classic kode lama vs kode baru harus identik.
SP=/tmp/claude-0/-home-claude/bc2a37a6-77d5-5593-942f-124ebd210f19/scratchpad
cd $SP
rm -f sim/t1*
jalan() { # <label> <proj>
  for NP in 2 3 4; do for NM in 0 1; do for SD in 7 8 9; do
    ./jalankan_sim.sh $SP/$2 $1 $NP $NM $SD 60 > /dev/null
  done; done; done
}
jalan t1lama proj_sebelum_fase1 &
jalan t1baru proj &
wait
jalan t1lamaN proj_sebelum_fase1_tanpa_uji &
jalan t1baruN proj_tanpa_uji &
wait
BEDA=0; SAMA=0
for f in sim/t1lama_*.txt sim/t1lamaN_*.txt; do
  g=${f/t1lama/t1baru}
  if cmp -s "$f" "$g"; then SAMA=$((SAMA+1)); else BEDA=$((BEDA+1)); echo "BEDA: $f"; diff "$f" "$g" | head -6; fi
done
echo "T1 SAMA=$SAMA BEDA=$BEDA err_baru=$(cat sim/t1baru*.log | grep -ac 'SCRIPT ERROR')"
grep -ah "^SIM" sim/t1baru*.log | awk '{print $2}' | sort | uniq -c
