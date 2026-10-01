#!/bin/bash
# Salin file produksi ke salinan uji; bedanya HANYA saklar UJI_* di pemain_dasar.gd.
# Fase 3: pemain.gd dipecah jadi 7 file berantai (extends). Semua ikut disalin.
# Fase 4 Langkah A: +4 file baru (data_role.gd, pemain_role.gd, ai_jebakan.gd, ui_role.gd)
# -- pemain_role.gd masuk RANTAI (antara pemain_tampilan.gd & pemain_papan.gd), 3
# lainnya kelas statis lepas seperti data_pemain.gd/ai_musuh.gd/ui_profil.gd.
P=/tmp/claude-0/-home-claude/bc2a37a6-77d5-5593-942f-124ebd210f19/scratchpad/proj
cd /home/claude
for f in pemain.gd pemain_dasar.gd pemain_tampilan.gd pemain_role.gd pemain_papan.gd pemain_kartu.gd pemain_duel.gd pemain_jaringan.gd ai_musuh.gd ai_jebakan.gd petak_kartu.gd ui_elemen.gd ui_dinamis.gd ui_petak.gd main_menu.gd layar_local_play.gd status_jaringan.gd data_pemain.gd data_role.gd jebakan_air.gd jebakan_api.gd jebakan_angin.gd jebakan_petir.gd jebakan_tanah.gd migrasi_host.gd profil_pemain.gd ui_profil.gd ui_role.gd; do
  cp -f "$f" "$P/$f"
done
sed -i 's/^const UJI_DUEL := false/const UJI_DUEL := true/; s/^const UJI_SERI := false/const UJI_SERI := true/' "$P/pemain_dasar.gd"
echo "== diff pemain.gd (harus kosong) =="
diff /home/claude/pemain.gd "$P/pemain.gd"
echo "== diff pemain_dasar.gd (harus HANYA 2 baris saklar UJI_DUEL/UJI_SERI) =="
diff /home/claude/pemain_dasar.gd "$P/pemain_dasar.gd"
echo "== diff 6 file lapis lain (harus kosong) =="
for f in pemain_tampilan.gd pemain_role.gd pemain_papan.gd pemain_kartu.gd pemain_duel.gd pemain_jaringan.gd; do
  diff /home/claude/$f "$P/$f"
done
