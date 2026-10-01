#!/bin/bash
SP=/tmp/claude-0/-home-claude/bc2a37a6-77d5-5593-942f-124ebd210f19/scratchpad
G=/tmp/claude-0/godot/Godot_v4.7.1-stable_linux.x86_64
cd $SP/proj
for t in uji_takeover uji_solo uji_kartu uji_koin uji_pedang uji_pedang_tonton uji_tanah2 uji_kamera_hud_solo uji_cabang_solo; do
  H=$(mktemp -d $SP/sim/home_XXXX)
  HOME=$H timeout 400 $G --headless --path $SP/proj res://$t.tscn > $SP/reg9_$t.log 2>&1
  echo "$t exit=$? gagal=$(grep -ac 'GAGAL' $SP/reg9_$t.log) ok=$(grep -ac '   ok   :' $SP/reg9_$t.log)"
  rm -rf $H
done
for t in uji_air_solo uji_angin_solo; do
  H=$(mktemp -d $SP/sim/home_XXXX)
  HOME=$H timeout 400 $G --headless --path $SP/proj res://$t.tscn 2>/dev/null | grep -a "SOLO seed" > $SP/rng_r16_$t.txt
  echo "$t: $(diff -q $SP/rng_r4_$t.txt $SP/rng_r16_$t.txt >/dev/null && echo 'RNG SAMA dengan r4' || echo 'RNG BEDA')"
  rm -rf $H
done
echo REG_SELESAI
