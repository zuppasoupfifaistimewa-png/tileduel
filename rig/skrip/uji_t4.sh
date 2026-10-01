#!/bin/bash
# T4 (Fase 1): Quick Match multiplayer. Baris AKHIR harus sama persis di semua HP satu permainan.
SP=/tmp/claude-0/-home-claude/bc2a37a6-77d5-5593-942f-124ebd210f19/scratchpad
cd $SP
rm -rf mp3/home_q*
Q="panjang=quick"
echo "== Q1 1v1 alam";                EXTRA="$Q" ./jalankan_mp3.sh q_1 0 alam 1 "" 60 61
echo "== Q2 2P+1AI pantai";           EXTRA="$Q" ./jalankan_mp3.sh q_2 1 pantai 1 "" 60 62
echo "== Q3 3P alam";                 EXTRA="$Q" ./jalankan_mp3.sh q_3 3 alam 2 "" 60 63
echo "== Q4 4P alam";                 EXTRA="$Q" ./jalankan_mp3.sh q_4 5 alam 3 "" 60 64
echo "== Q5 4P migrasi host g8";      EXTRA="$Q" ./jalankan_mp3.sh q_5 5 alam 3 host_keluar_migrasi 60 65 8
echo "== Q6 3P+1AI (+kartu)";         EXTRA="$Q pedang_awal=1 kartu_awal=1" ./jalankan_mp3.sh q_6 4 alam 2 "" 60 66
echo "== Q7 3P client keluar g8";     EXTRA="$Q" ./jalankan_mp3.sh q_7 3 alam 2 client_keluar 60 67 8 2
echo "== Q8 3P+1AI hotspot P1 mati di giliran terakhir"; EXTRA="$Q" ./jalankan_mp3.sh q_8 4 alam 2 host_hotspot_mati 60 68 20
echo "== Q1n 1v1 alam (UJI mati)";    PROJ=$SP/proj_tanpa_uji EXTRA="$Q" ./jalankan_mp3.sh q_1n 0 alam 1 "" 60 71
echo "== Q4n 4P pantai (UJI mati)";   PROJ=$SP/proj_tanpa_uji EXTRA="$Q" ./jalankan_mp3.sh q_4n 5 pantai 3 "" 60 74
echo "== RINGKASAN AKHIR"
for L in q_1 q_2 q_3 q_4 q_5 q_6 q_7 q_8 q_1n q_4n; do
  N=$(grep -ah "^AKHIR" mp3/$L.*.log | wc -l)
  U=$(grep -ah "^AKHIR" mp3/$L.*.log | sort -u | wc -l)
  echo "$L: baris_AKHIR=$N berbeda=$U | $(grep -ah '^AKHIR' mp3/$L.*.log | head -1 | cut -c1-70)"
done
echo T4_SELESAI
