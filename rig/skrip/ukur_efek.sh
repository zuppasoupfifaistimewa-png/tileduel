#!/bin/bash
# ukur_efek.sh <folder> <efek> <tingkat> [opsi]
P=$1; E=$2; T=$3; O=${4:-}
G=/tmp/claude-0/godot/Godot_v4.7.1-stable_linux.x86_64
H=$(mktemp -d /tmp/claude-0/-home-claude/bc2a37a6-77d5-5593-942f-124ebd210f19/scratchpad/home_XXXX)
cd $P
env HOME=$H XDG_DATA_HOME=$H/data XDG_CONFIG_HOME=$H/config MESA_SHADER_CACHE_DISABLE=true \
  xvfb-run -a -s "-screen 0 1280x720x24" timeout 300 $G --rendering-driver opengl3 --path . res://uji_efek_lag.tscn -- efek=$E tingkat=$T varian=asli $O 2>&1 | grep -E "^(UKUR|   putar)" 
rm -rf $H
