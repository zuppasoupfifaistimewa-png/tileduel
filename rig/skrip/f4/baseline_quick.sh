#!/bin/bash
# Patokan (baseline) panjang pertandingan Quick Match SEBELUM Fase 4.
# Pakai rig T4/T5 (uji_nyata.gd) yang sudah ada, TANPA modifikasi apa pun.
# Kode diuji = proj_tanpa_uji (hasil sinkron dari produksi pasca-Fase-3, saklar UJI_* mati).
SP=/tmp/claude-0/-home-claude/bc2a37a6-77d5-5593-942f-124ebd210f19/scratchpad
cd "$SP"
rm -f sim/base_*.log sim/base_*.txt
satu() {
  # $1=lawan(jumlah AI) $2=peta $3=seed
  PROJ=$SP/proj_tanpa_uji EXTRA="panjang=quick" ./jalankan_nyata.sh base $1 $2 $3 200 > /dev/null
}
export -f satu; export SP
{
  for LW in 1 2 3; do
    for PT in alam pantai; do
      N=60
      if [ "$LW" != "1" ]; then N=30; fi
      for S in $(seq 200 $((200+N-1))); do
        echo "$LW $PT $S"
      done
    done
  done
} | xargs -P 2 -L 1 bash -c 'satu "$0" "$1" "$2"'
echo BASELINE_SELESAI
