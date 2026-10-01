#!/bin/bash
# T6: foto layar Fase 1 (xvfb + opengl3), dua ukuran layar.
SP=/tmp/claude-0/-home-claude/bc2a37a6-77d5-5593-942f-124ebd210f19/scratchpad
G=/tmp/claude-0/godot/Godot_v4.7.1-stable_linux.x86_64
P=$SP/proj_tanpa_uji
mkdir -p $SP/foto_f1
for UK in 1280x720 1600x720; do
  H=$(mktemp -d $SP/home_XXXX)
  env HOME=$H MESA_SHADER_CACHE_DISABLE=true LP_NUM_THREADS=2 xvfb-run -a -s "-screen 0 ${UK}x24" timeout 600 $G --rendering-driver opengl3 --resolution $UK --path $P res://uji_foto_fase1.tscn -- foto=$SP/foto_f1/f1_$UK 2>&1 | grep -E "^FOTO|SCRIPT ERROR"
  env HOME=$H MESA_SHADER_CACHE_DISABLE=true LP_NUM_THREADS=2 xvfb-run -a -s "-screen 0 ${UK}x24" timeout 1500 $G --rendering-driver opengl3 --resolution $UK --path $P res://uji_nyata.tscn -- lawan=3 peta=alam seed=91 giliran=60 panjang=quick iklan=1 foto=$SP/foto_f1/q4_$UK jejak=$SP/foto_f1/q4_$UK.txt 2>&1 | grep -E "^(SIM|AKHIR|SPANDUK|IKLAN|PANEL)|SCRIPT ERROR"
  rm -rf $H
done
ls -la $SP/foto_f1/
