#!/bin/bash
SP=/tmp/claude-0/-home-claude/bc2a37a6-77d5-5593-942f-124ebd210f19/scratchpad
G=/tmp/claude-0/godot/Godot_v4.7.1-stable_linux.x86_64
PROJ=$1
OUT_PREFIX=$2
declare -A M
M[M1]="role=petir,tanah jenis=3"
M[M2]="role=tanah,api jenis=3"
M[M3]="role=tanah,air preset=balanced sp=12"
M[M4]="role=tanah,petir preset=balanced sp=12"
M[M5]="maks_node=1 maks_lv=3 role=api,petir jenis=3"
for m in M1 M2 M3 M4 M5; do
  for seed in 301 302 303; do
    H=$(mktemp -d $SP/mp3/home_XXXX)
    HOME=$H timeout 200 $G --headless --path $PROJ res://uji_nyata.tscn -- lawan=1 peta=alam seed=$seed semua_ai=1 panjang=quick giliran=30 escala=8 ${M[$m]} > $SP/bd_baseline/${OUT_PREFIX}_${m}_seed${seed}.log 2>&1
    ec=$?
    echo "$m seed=$seed exit=$ec scripterr=$(grep -ac 'SCRIPT ERROR' $SP/bd_baseline/${OUT_PREFIX}_${m}_seed${seed}.log) statcek=$(grep -a 'STAT_CEK' $SP/bd_baseline/${OUT_PREFIX}_${m}_seed${seed}.log | tail -1) jebakan=$(grep -c 'JEBAKAN_AI' $SP/bd_baseline/${OUT_PREFIX}_${m}_seed${seed}.log)"
    rm -rf $H
  done
done
echo "BD_BASELINE_${OUT_PREFIX}_SELESAI"
