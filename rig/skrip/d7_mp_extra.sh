#!/bin/bash
SP=/tmp/claude-0/-home-claude/bc2a37a6-77d5-5593-942f-124ebd210f19/scratchpad
# D7.5 TAMBAHAN: 6 match asli (giliran=20) semua cek_gagal=0/scripterr=0 TAPI
# CEK_BD (sacred/guard_nol/fight_faktor/benteng_lewati/benteng_tahan_ai) nol
# di 5/5 yang sudah dicek -- diagnosis: bukan bug (kode sudah diverifikasi
# cek_nilai=1 solo + M1-M5 AI-vs-AI), tapi giliran=20 (~5 giliran/pemain di
# mode 4P) terlalu pendek utk kondisi sempit tiap counter (butuh setup
# menara/jebakan berturut2 dari giliran2 sebelumnya). Sweep ini: mode=2
# (2P+2AI, kepadatan AI maksimal), giliran=50 (~12/pemain), + role_ai= untuk
# MEMAKSA robot host jadi tanah (jamin ada Fortress di papan) di separuh run.
PROJ=proj bash jalankan_mp3.sh d7ex_1 2 alam 1 "" 50 411 20 2>&1
EXTRA="role_ai=tanah" PROJ=proj bash jalankan_mp3.sh d7ex_2 2 pantai 1 "" 50 412 20 2>&1
PROJ=proj bash jalankan_mp3.sh d7ex_3 2 alam 1 "" 50 413 20 2>&1
EXTRA="role_ai=tanah" PROJ=proj bash jalankan_mp3.sh d7ex_4 2 pantai 1 "" 50 414 20 2>&1
echo "D7_MP_EXTRA_SELESAI"
