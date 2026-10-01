#!/bin/bash
# T1 (Fase 2) ulang dengan rig TERKINI + benih 7..12 (36 per kelompok, sesuai rencana):
# Classic UJI nyala, Classic UJI mati, Quick UJI mati. Kode sebelum Fase 2 vs kode Fase 2.
SP=/tmp/claude-0/-home-claude/bc2a37a6-77d5-5593-942f-124ebd210f19/scratchpad
cd $SP
rm -f sim/g2*
P=${P:-2}
daftar() { # <label> <proj> [extra]
  for NP in 2 3 4; do for NM in 0 1; do for SD in 7 8 9 10 11 12; do
    echo "$1 $2 $NP $NM $SD ${3:--}"
  done; done; done
}
satu() { X="$6"; [ "$X" = "-" ] && X=""; EXTRA="$X" ./jalankan_sim.sh $SP/$2 $1 $3 $4 $5 60 > /dev/null; }
export -f satu; export SP
{
  daftar g2lama proj_sebelum_fase2
  daftar g2baru proj
  daftar g2lamaN proj_sebelum_fase2_tanpa_uji
  daftar g2baruN proj_tanpa_uji
  daftar g2lamaQ proj_sebelum_fase2_tanpa_uji quick=1
  daftar g2baruQ proj_tanpa_uji quick=1
} | xargs -P $P -L 1 bash -c 'satu "$0" "$1" "$2" "$3" "$4" "$5"'
BEDA=0; SAMA=0
for f in sim/g2lama_*.txt sim/g2lamaN_*.txt sim/g2lamaQ_*.txt; do
  g=${f/g2lama/g2baru}
  if cmp -s "$f" "$g"; then SAMA=$((SAMA+1)); else BEDA=$((BEDA+1)); echo "BEDA: $f"; diff "$f" "$g" | head -6; fi
done
echo "T1b SAMA=$SAMA BEDA=$BEDA err_baru=$(cat sim/g2baru*.log | grep -ac 'SCRIPT ERROR') stat_salah=$(cat sim/g2baru*.log | grep -ac 'STAT_CEK SALAH') stat_ok=$(cat sim/g2baru*.log | grep -ac 'STAT_CEK OK')"
grep -ah "^SIM" sim/g2baru*.log | awk '{print $2}' | sort | uniq -c
echo T1b_SELESAI
