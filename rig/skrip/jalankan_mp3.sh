#!/bin/bash
# jalankan_mp3.sh <label> <mode 0-4> <peta> <jumlah_client> [skenario] [giliran] [seed] [giliran_keluar]
EXTRA=${EXTRA:-}
LBL=$1; MODE=$2; PETA=$3; NC=$4; SKEN=${5:-}; GL=${6:-30}; SD=${7:-7}; KL=${8:-8}; KU=${9:-2}
SP=/tmp/claude-0/-home-claude/bc2a37a6-77d5-5593-942f-124ebd210f19/scratchpad
G=/tmp/claude-0/godot/Godot_v4.7.1-stable_linux.x86_64
mkdir -p $SP/mp3
OUT=$SP/mp3/${LBL}
rm -f $OUT.*
HS=""
H0=$(mktemp -d $SP/mp3/home_XXXX); HS="$HS $H0"
HOME=$H0 timeout 1200 $G --headless --path ${PROJ:-$SP/proj} res://LocalPlay.tscn -- robot=host mode=$MODE peta=$PETA giliran=$GL seed=$SD skenario=$SKEN keluar=$KL keluar_urut=$KU $EXTRA log=$OUT.host.txt > $OUT.host.log 2>&1 &
for c in $(seq 1 $NC); do
  Hc=$(mktemp -d $SP/mp3/home_XXXX); HS="$HS $Hc"
  HOME=$Hc timeout 1200 $G --headless --path ${PROJ:-$SP/proj} res://LocalPlay.tscn -- robot=client urut=$c skenario=$SKEN keluar=$KL keluar_urut=$KU $EXTRA log=$OUT.c$c.txt > $OUT.c$c.log 2>&1 &
done
wait
for f in $OUT.host $(for c in $(seq 1 $NC); do echo $OUT.c$c; done); do
  echo "$(basename $f): $(grep -a '^SELESAI' $f.log | tail -1) | scripterr=$(grep -ac 'SCRIPT ERROR' $f.log) | beda=$(grep -ac 'BEDA\|GAGAL' $f.log)"
done
rm -rf $HS
