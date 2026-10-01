#!/bin/bash
cd /tmp/claude-0/-home-claude/bc2a37a6-77d5-5593-942f-124ebd210f19/scratchpad
echo "== K1 3P+1AI kartu_awal";                 EXTRA="kartu_awal=1" ./jalankan_mp3.sh k1_m4 4 alam 2 "" 24 51
echo "== K2 2P+1AI kartu_awal (1 client)";      EXTRA="kartu_awal=1" ./jalankan_mp3.sh k2_m1 1 pantai 1 "" 24 52
echo "== K3 1v1 kartu_awal";                    EXTRA="kartu_awal=1" ./jalankan_mp3.sh k3_m0 0 alam 1 "" 24 53
echo "== K4 3P kartu_awal, host keluar g10";    EXTRA="kartu_awal=1" ./jalankan_mp3.sh k4_m3_hostkeluar 3 alam 2 host_keluar 40 54 10
echo "== K5 3P kartu_awal, client2 keluar g6";  EXTRA="kartu_awal=1" ./jalankan_mp3.sh k5_m3_c2keluar 3 alam 2 client_keluar 24 55 6 2
echo "== uji_mp 1v1"; (cd proj && ./jalankan_uji_mp.sh > ../mp_run11.out 2>&1); cat mp_run11.out
echo "mp_host: ok=$(grep -ac '   ok   :' mp_host.log) gagal=$(grep -ac 'GAGAL' mp_host.log) scripterr=$(grep -ac 'SCRIPT ERROR' mp_host.log) / client scripterr=$(grep -ac 'SCRIPT ERROR' mp_client.log)"
echo C3_SELESAI
