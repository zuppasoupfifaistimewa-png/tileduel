# Catatan kerja: Tile Duel 2–4 pemain (mulai 21 Sep 2026 sore)

## Keputusan user
- Warna: P1 biru (slot0), P2 merah (slot1), P3 hijau (slot2), P4 kuning (slot3).
- Nama di teks: pemain lokal "YOU"/"You"; lainnya "P1".."P4" (untuk 3+ pemain).
  2 pemain: tetap "Enemy" (perilaku 1v1 TIDAK berubah).
- HUD 3+ pemain: panel YOU besar (kiri, seperti sekarang) + daftar lawan kecil di kanan.
  2 pemain: HUD lama tetap.
- Lobby MP: host pilih mode (5 mode) + peta (Grassland/Beach).
  Mode: 1v1 | 2P+1AI | 2P+2AI | 3P | 3P+1AI. Slot: host=0, client urutan gabung=1,2; AI isi sisa.
- Solo: 1 vs 1/2/3 AI (menu SINGLE PLAYER -> pilih lawan -> pilih peta).
- Lawan putus: JANGAN tukar slot/warna. Client tetap slot & warnanya; AI ambil alih slot yang keluar
  (termasuk host slot 0 bila host yang keluar -> client jadi otoritas lokal/solo).

## Baseline sebelum refactor
- scratchpad/proj_r5 = kode sebelum refactor 4 pemain (untuk banding RNG & perilaku).
- File terkini user: /home/claude/*.gd (pemain, ui_dinamis, ui_petak, ai_musuh, ui_elemen, jebakan_*, petak_kartu, ...).

## Desain inti
- NAMA_AKTOR = ["pemain","musuh","pemain3","pemain4"]; giliran_sekarang pakai nama ini.
- Helper: _slot_aktor, _aktor_slot, _model(slot), _anim(slot), _node_karakter(slot),
  _warna_slot, _material_slot, _subjek(slot) ("You"/"Enemy"/"P3"), jumlah_pemain().
- Data per slot (array 4) + alias properti lama utk slot 0/1:
  koleksi_permata, tipe_dadu, sisa_durasi_dadu, putaran, kemarahan.
- ganti_giliran -> slot berikutnya (slot+1)%N lalu _mulai_giliran(slot) (efek dadu/gelembung/bakar/paralisis, lalu AI/menu).
- Denda: _bayar_denda(pembayar, penerima, pengali); wrapper lama tetap.
- Duel: penyerang = pendarat, pembela = pemilik petak; ui_elemen sisi "pemain"= peserta lokal (atau penyerang), "musuh" = lainnya.
- AI: AiMusuh.* menerima slot (default 1).
- Model P3/P4: instansiasi beras.glb, warnai hijau/kuning.

## Progres
- [ ] A. infrastruktur slot + alias
- [ ] B. ganti_giliran umum
- [ ] C. bergerak_maju / periksa_status_petak / denda / duel
- [ ] D. AI slot mana pun
- [ ] E. serangan, jebakan, kartu, permata, start, bangkrut
- [ ] F. HUD, teks, model P3/P4, warna ui_petak
- [ ] G. menu solo 1 vs N AI
- [ ] H. uji: tes 1v1 lama identik + simulasi AI 3/4 pemain
- [ ] I. takeover client tanpa tukar
- [ ] J. lobby + jaringan N device + harness 3 proses

## Status 23 Sep (siang)
- CHECKPOINT 1 terkirim (outputs/checkpoint1): 10 file .gd -- takeover tanpa tukar + solo 1v1/2/3 AI.
- CHECKPOINT 2 terkirim (outputs/checkpoint2): layar_local_play.gd (lobby 5 mode + peta) + pemain.gd
  (teks WAITING FOR PLAYERS, sinkron efek dadu tipe_dadu/durasi_dadu ke client).
- Rig 3 proses: proj/LocalPlay.tscn (replika), proj/panggung_utama.tscn (salinan uji_panggung, model kapsul),
  autoload UjiRobotMP (proj/uji_robot_mp.gd, aktif hanya dgn robot=host|client), runner jalankan_mp3.sh
  (EXTRA="kartu_awal=1" untuk beri 3 kartu simpanan ke semua slot).
- CHECKPOINT 3 (sedang): kartu simpanan client -- inventaris ikut siaran state ("kartu"),
  client pilih kartu -> rpc_minta_pakai_kartu(indeks,id,target) -> host eksekusi -> periksa (siar state).
  Juga teks "P2 activated a Shield!" utk 3+ pemain (2 pemain tetap kalimat lama).
  File berubah: pemain.gd, ui_dinamis.gd (cabang client di munculkan_ui_pilih_target).
