#!/bin/bash
S=/tmp/claude-0/-home-claude/bc2a37a6-77d5-5593-942f-124ebd210f19/scratchpad
$S/ukur_pantai.sh $S/proj sedang abl_o60 20 "matikan=ortho60"
$S/ukur_pantai.sh $S/proj sedang "" 20
$S/ukur_pantai.sh $S/proj sedang abl_o80 20 "matikan=ortho80"
echo SELESAI_BATCH3
