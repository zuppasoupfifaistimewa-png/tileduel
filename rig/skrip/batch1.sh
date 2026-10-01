#!/bin/bash
S=/tmp/claude-0/-home-claude/bc2a37a6-77d5-5593-942f-124ebd210f19/scratchpad
$S/ukur_pantai.sh $S/proj sangat_rendah abl_langit 30 "matikan=langit"
$S/ukur_pantai.sh $S/proj sangat_rendah abl_obor_laut 30 "matikan=obor_laut"
$S/ukur_pantai.sh $S/proj sangat_rendah abl_pasirv 30 "matikan=pasir_vertex,obor_laut"
$S/ukur_pantai.sh $S/proj sangat_rendah abl_kombo 30 "matikan=pasir_vertex,obor_laut,langit,dermaga"
$S/ukur_pantai.sh $S/proj sedang abl_ortho 20 "matikan=bayangan_ortho"
$S/ukur_pantai.sh $S/proj sedang abl_2split 20 "matikan=bayangan_2split"
echo SELESAI_BATCH1
