#!/bin/bash
cd /tmp/claude-0/-home-claude/bc2a37a6-77d5-5593-942f-124ebd210f19/scratchpad
echo "== uji_mp 1v1"; (cd proj && ./jalankan_uji_mp.sh > ../mp_run10.out 2>&1); cat mp_run10.out
echo "mp_host: ok=$(grep -ac '   ok   :' mp_host.log) gagal=$(grep -ac 'GAGAL' mp_host.log) scripterr=$(grep -ac 'SCRIPT ERROR' mp_host.log) / client scripterr=$(grep -ac 'SCRIPT ERROR' mp_client.log)"
echo "== m4 pantai ulang"; ./jalankan_mp3.sh v_m4_pantai 4 pantai 2 "" 30 16
echo "== s1 ulang";        ./jalankan_mp3.sh v_s1_3p_c2keluar 3 alam 2 client_keluar 30 21 8 2
echo "== m3 pantai";       ./jalankan_mp3.sh v_m3_pantai 3 pantai 2 "" 30 31
echo VERIF_SELESAI
