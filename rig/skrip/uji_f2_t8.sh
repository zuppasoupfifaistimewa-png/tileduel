#!/bin/bash
# T8 (Fase 2): DOUBLE & interstisial saat EXIT dengan tiruan Editor Mock Ads, klik sungguhan.
SP=/tmp/claude-0/-home-claude/bc2a37a6-77d5-5593-942f-124ebd210f19/scratchpad
G=/tmp/claude-0/godot/Godot_v4.7.1-stable_linux.x86_64
D=$SP/proj_mock_editor
timeout 300 $G --headless --path $D --import >/dev/null 2>&1
mkdir -p $SP/mock_editor
for sk in ${SKEN:-double exit}; do for ly in 100 1000; do
  H=$(mktemp -d $SP/home_XXXX)
  O=$SP/mock_editor/f2_${sk}_${ly}.txt
  env HOME=$H MESA_SHADER_CACHE_DISABLE=true LP_NUM_THREADS=1 xvfb-run -a -s "-screen 0 1280x720x24" timeout 300 $G --rendering-driver opengl3 --resolution 1280x720 --path $D res://uji_iklan_editor_f2.tscn -- skenario=$sk layer=$ly > $O 2>&1
  echo "[$sk $ly] $(grep -a '^HASIL' $O | tail -1) | scripterr=$(grep -ac 'SCRIPT ERROR' $O) freed=$(grep -ac 'previously freed' $O)"
  rm -rf $H
done; done
echo T8_SELESAI
