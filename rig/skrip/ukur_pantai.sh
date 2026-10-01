#!/bin/bash
# ukur_pantai.sh <folder_proyek> <tingkat> <label_foto> [n] [matikan=a,b]
P=$1; T=$2; F=$3; N=${4:-90}; M=${5:-}
G=/tmp/claude-0/godot/Godot_v4.7.1-stable_linux.x86_64
H=$(mktemp -d /tmp/claude-0/-home-claude/bc2a37a6-77d5-5593-942f-124ebd210f19/scratchpad/home_XXXX)
cd $P
env HOME=$H XDG_DATA_HOME=$H/data XDG_CONFIG_HOME=$H/config MESA_SHADER_CACHE_DISABLE=true LP_NUM_THREADS=${LPT:-2} \
  xvfb-run -a -s "-screen 0 1280x720x24" timeout 590 $G --rendering-driver opengl3 --fixed-fps 30 --path . res://uji_pantai_fps.tscn -- tingkat=$T foto=$F n=$N $M 2>&1 | grep -E "^(INFO|TITIK|HASIL|ABLASI)|SCRIPT ERROR|ERROR:.*pantai|Parse" | grep -v "MobileAds\|AdRequest\|AppOpen\|FullScreen\|AdPosition\|AdSize\|AdView\|RewardedAd\|Interstitial\|pengelola_iklan\|OnUserEarned"
rm -rf $H
