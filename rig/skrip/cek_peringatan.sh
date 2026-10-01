#!/bin/bash
# Cari PERINGATAN GDScript (yang tampil di debugger editor user). Peringatan hanya
# dicetak kalau debugger aktif, jadi dijalankan dengan --debug (stdin /dev/null).
# Tiap skrip dimuat dari adegan cek_muat.tscn (autoload sudah siap). LAMA vs BARU.
SP=/tmp/claude-0/-home-claude/bc2a37a6-77d5-5593-942f-124ebd210f19/scratchpad
G=/tmp/claude-0/godot/Godot_v4.7.1-stable_linux.x86_64
U=/root/.claude/uploads/bc2a37a6-77d5-5593-942f-124ebd210f19/6c2388ec-pengelola_iklan.gd
siapkan() { # $1=nama $2=proyek sumber $3=pengelola_iklan asli
  local D=$SP/cek_warn/$1
  rm -rf $D; mkdir -p $D
  (cd $2 && tar cf - --exclude='*.png' --exclude='.godot' .) | (cd $D && tar xf -)
  cp -f "$3" $D/pengelola_iklan.gd
  cp -r $SP/proj_iklan/tiruan $D/tiruan
  cp -f $SP/cek_warn/cek_muat.gd $SP/cek_warn/cek_muat.tscn $D/
  timeout 300 $G --headless --path $D --import >/dev/null 2>&1
}
periksa() { # $1=nama
  local D=$SP/cek_warn/$1
  timeout 300 $G --headless --path $D --debug res://cek_muat.tscn < /dev/null > $SP/cek_warn/$1.txt 2>&1
}
[ "$1" = "baru_saja" ] || siapkan lama $SP/proj_sebelum_fase1_tanpa_uji $U
siapkan baru $SP/proj_tanpa_uji /home/claude/pengelola_iklan.gd
[ "$1" = "baru_saja" ] || periksa lama
periksa baru
echo CEK_SELESAI
