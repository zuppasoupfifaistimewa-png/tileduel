#!/bin/bash
# Ulang bersih scenario yang bentrok port ENet dengan uji ad-hoc role (B2-B4, A0-A1)
# + skenario baru host_ganti_mode_role -- dijalankan SATU PER SATU (tidak paralel
# dengan apa pun) supaya tidak ada tabrakan port lagi.
cd /tmp/claude-0/-home-claude/bc2a37a6-77d5-5593-942f-124ebd210f19/scratchpad
X="pedang_awal=1 kartu_awal=1"
echo "== B2 4P c3 keluar g8 (ulang)";        ./jalankan_mp3.sh f2_b2 5 alam 3 client_keluar 30 43 8 3
echo "== B3 4P c2 keluar pilih elemen (ulang)"; EXTRA="$X" ./jalankan_mp3.sh f2_b3 5 alam 3 client_keluar_duel 30 44 8 2
echo "== B4 4P host keluar g8 (ulang)"; ./jalankan_mp3.sh f2_b4 5 alam 3 host_keluar 40 45 8
echo "== A0 1v1 (+kartu) (ulang)";        EXTRA="$X" ./jalankan_mp3.sh f2_a0 0 alam 1 "" 30 11
echo "== A1 2P+1AI (+kartu) (ulang)";     EXTRA="$X" ./jalankan_mp3.sh f2_a1 1 alam 1 "" 30 12
echo "== host_ganti_mode_role (ulang bersih)"; EXTRA="" ./jalankan_mp3.sh f4_ganti_mode 3 alam 2 host_ganti_mode_role 20 82
echo RERUN_SELESAI
