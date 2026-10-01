#!/bin/bash
# jalankan_sim.sh <dir_proyek> <label> <pemain> <manusia> <seed> [giliran] [uang]
PROJ=$1; LBL=$2; NP=$3; NM=$4; SD=$5; GL=${6:-60}; UA=${7:-2500}
SP=/tmp/claude-0/-home-claude/bc2a37a6-77d5-5593-942f-124ebd210f19/scratchpad
G=/tmp/claude-0/godot/Godot_v4.7.1-stable_linux.x86_64
mkdir -p $SP/sim
H=$(mktemp -d $SP/sim/home_XXXX)
OUT=$SP/sim/${LBL}_p${NP}_m${NM}_s${SD}_u${UA}
HOME=$H MESA_SHADER_CACHE_DISABLE=true timeout 900 $G --headless --fixed-fps 60 --quit-after 400000 --path $PROJ res://uji_sim.tscn -- pemain=$NP manusia=$NM seed=$SD giliran=$GL jejak=$OUT.txt uang=$UA $EXTRA > $OUT.log 2>&1
echo "$LBL p$NP m$NM s$SD u$UA exit=$? $(grep -a '^SIM' $OUT.log | tail -1) err=$(grep -ac 'SCRIPT ERROR\|ERROR:' $OUT.log)"
rm -rf $H
