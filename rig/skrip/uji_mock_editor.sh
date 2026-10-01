#!/bin/bash
# Uji FREE CARD dengan pengelola_iklan.gd ASLI + tiruan Editor Mock Ads (klik sungguhan).
# Jalan 2 sekaligus. Keluaran: mock_editor/<proyek>_<skenario>_<layer>.txt
SP=/tmp/claude-0/-home-claude/bc2a37a6-77d5-5593-942f-124ebd210f19/scratchpad
G=/tmp/claude-0/godot/Godot_v4.7.1-stable_linux.x86_64
mkdir -p $SP/mock_editor
for d in proj_mock_editor proj_mock_editor_lama; do timeout 300 $G --headless --path $SP/$d --import >/dev/null 2>&1; done
satu() { # $1=proyek $2=skenario $3=layer
  local O=$SP/mock_editor/$1_$2_$3.txt
  # Layar maya 1280x720: di --headless viewport hanya 64x64, klik sungguhan meleset.
  env MESA_SHADER_CACHE_DISABLE=true LP_NUM_THREADS=1 xvfb-run -a -s "-screen 0 1280x720x24" timeout 300 $G --rendering-driver opengl3 --resolution 1280x720 --path $SP/$1 res://uji_iklan_editor.tscn -- skenario=$2 layer=$3 > $O 2>&1
}
export -f satu; export SP G
rm -f ~/.local/share/godot/app_userdata/uji_mock_editor/iklan.cfg ~/.local/share/godot/app_userdata/uji_mock_editor_lama/iklan.cfg
{
  echo "proj_mock_editor_lama start_saat_iklan 100"
  echo "proj_mock_editor_lama start_sebelum_muncul 100"
  for sk in start_saat_iklan start_sebelum_muncul gagal_tampil tutup_awal; do for ly in 100 1000; do echo "proj_mock_editor $sk $ly"; done; done
} | xargs -P 2 -L 1 bash -c 'satu "$0" "$1" "$2"'
for O in $SP/mock_editor/*.txt; do
  n=$(basename $O .txt)
  echo "[$n] $(grep -E '^HASIL' $O | head -1 | sed 's/^HASIL //') | scripterr=$(grep -c 'SCRIPT ERROR' $O) freed=$(grep -c 'previously freed' $O)"
  grep -E "^SAAT_IKLAN|^SETELAH_IKLAN" $O | sed 's/^/    /'
done
echo MOCK_SELESAI
