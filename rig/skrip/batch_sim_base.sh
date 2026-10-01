#!/bin/bash
SP=/tmp/claude-0/-home-claude/bc2a37a6-77d5-5593-942f-124ebd210f19/scratchpad
cd $SP
for sd in 7 7 11 23 42; do ./jalankan_sim.sh $SP/proj_r5 base 2 1 $sd 80 2500; done
for sd in 5 9 13 31; do ./jalankan_sim.sh $SP/proj_r5 base 2 1 $sd 120 1200; done
echo BATCH_SELESAI
