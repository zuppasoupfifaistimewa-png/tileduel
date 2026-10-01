#!/bin/bash
# jalankan_nyata.sh <label> <lawan> <peta> <seed> [giliran]
LBL=$1; NL=$2; PT=$3; SD=$4; GL=${5:-40}
SP=/tmp/claude-0/-home-claude/bc2a37a6-77d5-5593-942f-124ebd210f19/scratchpad
G=/tmp/claude-0/godot/Godot_v4.7.1-stable_linux.x86_64
mkdir -p $SP/sim
H=$(mktemp -d $SP/sim/home_XXXX)
OUT=$SP/sim/${LBL}_l${NL}_${PT}_s${SD}
HOME=$H MESA_SHADER_CACHE_DISABLE=true timeout 1200 $G --headless --fixed-fps 60 --quit-after 600000 --path ${PROJ:-$SP/proj} res://uji_nyata.tscn -- lawan=$NL peta=$PT seed=$SD giliran=$GL jejak=$OUT.txt $EXTRA > $OUT.log 2>&1
echo "$LBL lawan=$NL $PT s$SD exit=$? $(grep -a '^SIM\|^START\|^MENU\|^GAGAL' $OUT.log | tr '\n' ' ') err=$(grep -ac 'SCRIPT ERROR' $OUT.log)"
rm -rf $H
