#!/bin/bash
# Salinan uji KEDUA dengan saklar UJI_* MATI (dadu 2-12 & duel sungguhan).
# Isi = proj (termasuk alat uji & stub iklan), lalu file produksi disalin apa adanya.
# Fase 3: pemain.gd dipecah jadi 7 file berantai (extends). Semua ikut disalin.
# Fase 4 Langkah A: +4 file baru (data_role.gd, pemain_role.gd, ai_jebakan.gd, ui_role.gd).
SP=/tmp/claude-0/-home-claude/bc2a37a6-77d5-5593-942f-124ebd210f19/scratchpad
rm -rf $SP/proj_tanpa_uji
cp -r $SP/proj $SP/proj_tanpa_uji
cd /home/claude
for f in pemain.gd pemain_dasar.gd pemain_tampilan.gd pemain_role.gd pemain_papan.gd pemain_kartu.gd pemain_duel.gd pemain_jaringan.gd ai_musuh.gd ai_jebakan.gd petak_kartu.gd ui_elemen.gd ui_dinamis.gd ui_petak.gd main_menu.gd layar_local_play.gd status_jaringan.gd data_pemain.gd data_role.gd jebakan_air.gd jebakan_api.gd jebakan_angin.gd jebakan_petir.gd jebakan_tanah.gd migrasi_host.gd profil_pemain.gd ui_profil.gd ui_role.gd; do
  cp -f "$f" "$SP/proj_tanpa_uji/$f"
done
grep -n "^const UJI_" $SP/proj_tanpa_uji/pemain_dasar.gd $SP/proj_tanpa_uji/petak_kartu.gd
