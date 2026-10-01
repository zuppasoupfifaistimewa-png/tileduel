#!/bin/bash
S=/tmp/claude-0/-home-claude/bc2a37a6-77d5-5593-942f-124ebd210f19/scratchpad
for T in sangat_rendah rendah sedang; do
  N=40; [ $T = rendah ] && N=30; [ $T = sedang ] && N=20
  $S/ukur_pantai.sh $S/proj_pantai_lama $T lama $N
  $S/ukur_pantai.sh $S/proj $T baru $N
  $S/ukur_pantai.sh $S/proj $T "" $N
  $S/ukur_pantai.sh $S/proj_pantai_lama $T "" $N
done
echo SELESAI_BATCH2
