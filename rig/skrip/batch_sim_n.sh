#!/bin/bash
SP=/tmp/claude-0/-home-claude/bc2a37a6-77d5-5593-942f-124ebd210f19/scratchpad
cd $SP
for sd in 3 8; do ./jalankan_sim.sh $SP/proj n 3 1 $sd 100 1500; done
for sd in 4 9; do ./jalankan_sim.sh $SP/proj n 4 1 $sd 100 1500; done
for sd in 5 10; do ./jalankan_sim.sh $SP/proj n 3 0 $sd 100 1500; done
for sd in 6 12; do ./jalankan_sim.sh $SP/proj n 4 0 $sd 120 1500; done
./jalankan_sim.sh $SP/proj n 2 0 21 100 1500
echo BATCH_SELESAI
