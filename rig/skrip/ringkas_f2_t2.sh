#!/bin/bash
# Ringkasan T2 (Fase 2): SELESAI/scripterr/beda per HP + baris AKHIR sama di semua HP.
cd /tmp/claude-0/-home-claude/bc2a37a6-77d5-5593-942f-124ebd210f19/scratchpad
cat t2a_f2.out t2b_f2.out > t2_f2_semua.out
echo "baris SELESAI: $(grep -c 'SELESAI ' t2_f2_semua.out)  MACET: $(grep -c MACET t2_f2_semua.out)  scripterr>0: $(grep -o 'scripterr=[0-9]*' t2_f2_semua.out | grep -vc 'scripterr=0$')  beda>0: $(grep -o '| beda=[0-9]*' t2_f2_semua.out | grep -vc 'beda=0$')  cek_gagal>0: $(grep -o 'cek_gagal=[0-9]*' t2_f2_semua.out | grep -vc 'cek_gagal=0$')"
for L in $(ls mp3/f2_*.host.log | sed 's/.host.log//' | xargs -n1 basename); do
  N=$(grep -ah "^AKHIR" mp3/$L.*.log | wc -l)
  U=$(grep -ah "^AKHIR" mp3/$L.*.log | sort -u | wc -l)
  P=$(grep -ah "^AKHIR" mp3/$L.*.log | head -1 | grep -o "penghargaan[^]]*]" | head -4 | tr '\n' ' ')
  echo "$L: AKHIR=$N berbeda=$U $([ $U -le 1 ] && echo OK || echo GAGAL) | $P"
done
