#!/bin/bash
# Menjalankan host & client sebagai dua proses Godot terpisah (ENet sungguhan).
cd "$(dirname "$0")"
G=/tmp/claude-0/godot/Godot_v4.7.1-stable_linux.x86_64
OUT=${1:-/tmp/claude-0/-home-claude/bc2a37a6-77d5-5593-942f-124ebd210f19/scratchpad}
timeout 300 $G --headless --path . res://uji_mp.tscn -- host > $OUT/mp_host.log 2>&1 &
H=$!
timeout 300 $G --headless --path . res://uji_mp.tscn -- client > $OUT/mp_client.log 2>&1 &
C=$!
wait $H; echo "host exit: $?"
wait $C; echo "client exit: $?"
