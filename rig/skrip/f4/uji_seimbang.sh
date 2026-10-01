#!/bin/bash
# U3 (Fase 4): uji keseimbangan lewat rig uji_nyata.gd (adegan & peta asli, semua slot AI).
# Pakai: uji_seimbang.sh <berkas_tugas> <berkas_hasil>
#   berkas_tugas: satu baris per pertandingan: "<tag> <lawan> <peta> <seed> <panjang> <role,role,..|-> [ekstra..]"
#     role "-" = tanpa semua_ai (robot slot 0 + role acak; dipakai ukur panjang, sama dengan patokan).
#   berkas_hasil: baris "tag=.. SEIMBANG ..." (+ err=N). Tugas yang tag+seed+peta-nya sudah ada di
#     berkas hasil DILEWATI -> bisa dilanjutkan kalau terputus (temuan 13).
# Repo: skrip ini ada di rig/skrip/f4/ -> SP = rig/. Bisa ditimpa lewat env (SP=, G=, PROJ=).
SP=${SP:-$(cd "$(dirname "$0")/../.." && pwd)}
G=${G:-/opt/godot/Godot_v4.7.1-stable_linux.x86_64}
TUGAS=$1; HASIL=$2
PROJ=${PROJ:-$SP/proj_tanpa_uji}
mkdir -p $SP/f4/tmp
touch "$HASIL"
satu() {
  local TAG=$1 NL=$2 PT=$3 SD=$4 PJ=$5 RL=$6; shift 6
  local KUNCI="tag=$TAG peta=$PT seed=$SD "
  grep -qF "$KUNCI" "$HASIL" && return
  local H=$(mktemp -d $SP/f4/tmp/h_XXXX)
  local X="panjang=$PJ $*"
  [ "$RL" != "-" ] && X="$X semua_ai=1 role=$RL"
  local L=$H/log
  HOME=$H MESA_SHADER_CACHE_DISABLE=true timeout 300 $G --headless --fixed-fps 60 --quit-after 900000 --path $PROJ res://uji_nyata.tscn -- lawan=$NL peta=$PT seed=$SD giliran=${GILIRAN:-200} $X > $L 2>&1
  local B=$(grep -a '^SEIMBANG' $L | tail -1 | sed "s/^SEIMBANG peta=$PT seed=$SD //")
  [ -z "$B" ] && B="GAGAL_TANPA_BARIS $(grep -a '^SIM\|^GAGAL' $L | tr '\n' ' ')"
  echo "tag=$TAG peta=$PT seed=$SD $B err=$(grep -ac 'SCRIPT ERROR' $L) stat=$(grep -a '^STAT_CEK' $L | cut -d' ' -f2)" >> "$HASIL"
  rm -rf $H
}
export -f satu; export SP G PROJ HASIL
grep -v '^#' "$TUGAS" | grep -v '^$' | xargs -P ${PARALEL:-2} -L 1 bash -c 'satu "$@"' _
echo "SEIMBANG_SELESAI $(wc -l < "$HASIL") baris"
