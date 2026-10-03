# HANDOFF -- lanjutkan proyek Tile Duel (Fase 4 SELESAI; Fase 5 SELESAI: G0-G9 + uji HP b10 LANCAR (02-10); rencana Fase 6-9 DISETUJUI 02-10 (`docs/RENCANA_fase6_9.md`); Fase 6 G0+G1+G2 SELESAI (02-10/03-10); berikutnya Fase 6 G3 (Sonnet: bersih-bersih + ZIP b11))

Dokumen ini ditulis 02-10-2026 supaya sesi Claude Code (cloud / web, tanpa CLI) mana pun bisa melanjutkan
pekerjaan TANPA riwayat percakapan. BACA INI DULU, lalu `docs/RENCANA_fase4_role.md` bagian 14.19 & **14.21-14.24** (paling akhir).
Diperbarui 02-10 (Opus, sesi Claude Code cloud): **uji HP pemilik dengan `kiriman/TileDuel_FaseB_b9.zip` = "lancar" -> Fase 4 SELESAI** (RENCANA 14.24).
Berikutnya: pemilik merilis A+B (daftar periksa di bagian 5). **Fase 5: rencana `docs/RENCANA_fase5_seru.md` DISETUJUI 02-10 (K1-K10 = a); G0-G7 + getaran Earthquake SELESAI (Sonnet, 02-10); G8 SELESAI (Opus, 02-10, RENCANA_fase5 bagian 10); pemilik memilih K11 = a, K12 = a (tanpa perubahan angka); G9 SELESAI (Sonnet, 02-10): `kiriman/TileDuel_Fase5_b10.zip` (29 .gd) -> berikutnya pemilik uji HP (daftar: RENCANA_fase5 bagian 6).**

**Fase 5 G0 SELESAI (Sonnet, 02-10):** refactor `denda_petak()` / `harga_beli_tanah()` / `harga_beli_menara(lv)` / `ronde_event` di
`pemain_dasar.gd` (+ semua pemakai di `ai_jebakan/ai_musuh/pemain/pemain_papan/pemain_tampilan`), `game/` & rig identik (34/35, kecuali stub iklan).
Bukti: S1 100 pertandingan benih 20000 IDENTIK baris per baris dgn F5 konfirmasi; `cek_nilai` 8/8; reg10 sama; data di `hasil/g0_refactor/`.

**Fase 5 G1 SELESAI (Sonnet, 02-10):** event papan (gold_rush / market_day / earthquake / star_shower; Quick ronde 3,5,7.. tiap 2; Classic
ronde 4,7,10.. tiap 3; tanpa pengulangan berurutan; undian `mesin_acak`). Kode: `pemain_dasar.gd` (state `event_aktif/event_terakhir`, konstanta,
`denda_petak` x2 & `harga_beli_*` x0,7 dibulatkan 10), `pemain_papan.gd` (`_ronde_jadwal_event`, `_mulai_event_papan`, `rpc_event_papan`, teks),
`pemain.gd` (dipanggil di `ganti_giliran` slot 0), `pemain_jaringan.gd` (siaran state "event"), `pemain_tampilan.gd`+`ui_dinamis.gd` (label HUD event;
`buat_label_ronde` +param warna). Rig-only: log `EVENT ...` di `uji_nyata.gd` & `uji_robot_mp.gd` (+ "event" di potret sinkron host-vs-client).
Bukti (`hasil/g1_event/`): solo Quick 2P/4P & Classic 2P/4P 0 SCRIPT ERROR, jadwal benar; MP 3P Quick: EVENT identik di host+2 client, cek_gagal=0;
host keluar di ronde event (migrasi): event berlanjut (c1 jadi host, ronde 5 gold_rush lanjut tanpa mengulang), cek_ok_migrasi=3, 0 beda; `cek_nilai` 8/8.
BELUM diverifikasi: tampilan label HUD event (headless tidak merender; cek di uji HP G9). (Getaran kamera Earthquake: DIBUAT di sesi G3, lihat bawah.) Keseimbangan role
TIDAK dicek (itu G8, Opus) -- event sudah mengubah ekonomi pertandingan. Berikutnya: **G2 bounty (Sonnet)**.

**Fase 5 G2 SELESAI (Sonnet, 02-10):** bounty. State `bounty_elemen/bounty_terakhir` (+`label_bounty`, `BOUNTY_RONDE_PERTAMA=2`) di `pemain_dasar.gd`;
`_bounty_perlu_muncul/_mulai_bounty/_klaim_bounty/rpc_bounty/_tampilkan_bounty` di `pemain_papan.gd`; dipanggil dari `ganti_giliran` (slot 0, sesudah event)
dan `eksekusi_dadu_pertarungan` (`pemain_duel.gd`, klaim = pemenang duel dgn `elemen_pemenang == bounty_elemen` -> +1 bintang maks 10, stat `bounty`);
siaran state "bounty" (`pemain_jaringan.gd`); label HUD `_atur_posisi_label_bounty` (`pemain_tampilan.gd`); kunci `bounty` di `statistik_kosong`.
Jadwal: bounty pertama ronde_event 2; sesudah diklaim, yang baru muncul di ronde event berikutnya; elemen diundi `mesin_acak`, tidak sama dgn yang terakhir. AI ikut mengklaim otomatis.
Bukti (`hasil/g2_bounty/`): solo 27 run (Quick/Classic 2P/4P) 0 SCRIPT ERROR, jadwal benar, klaim selalu tepat +1 bintang;
MP 3P Quick: sinkron host+2 client identik (urutan BOUNTY sama, cek_gagal=0), klaim teruji (robot rig `bounty_pilih=1`), host keluar saat bounty aktif:
bounty bertahan di host baru (c1), klaim setelah migrasi tercatat sama di c1 & c2, bounty baru diundi host baru; `cek_nilai` 8/8.
Rig-only: log `BOUNTY`/`BOUNTY_KLAIM` di `uji_nyata.gd` & `uji_robot_mp.gd` (+ "bounty" di potret), opsi `bounty_pilih=1` di `uji_robot_mp.gd`.
Untuk G8 (Opus): bounty di Quick hampir tak berarti -- 11 bounty di 11 run Quick solo, hanya 1 diklaim (Classic: 39 bounty, 23 diklaim); keputusan keseimbangan, jangan disetel Sonnet.

**Fase 5 G3 + getaran kamera Earthquake SELESAI (Sonnet, 02-10):**
- G3 kartu bantuan: `pemain.gd` (`_berhak_kartu_bantuan`, `_beri_kartu_bantuan`, `rpc_kartu_bantuan`, `_tampilkan_kartu_bantuan`; dipanggil di `bergerak_maju` setelah efek
  "passed Start"), `pemain_kartu.gd` (`_daftar_kartu_hadiah()` dipecah dari `_kartu_hadiah_acak()` -- perilaku iklan tak berubah), konstanta `KARTU_BANTUAN_SELISIH=1000` /
  `KARTU_BANTUAN_MAKS_INVENTARIS=3` (`pemain_dasar.gd`), stat `kartu_bantuan` (`statistik_kosong`). Syarat: kekayaan (`_kekayaan_slot`) PALING rendah (seri = tidak berhak),
  tertinggal >= 1000 dari yang terkaya, inventaris < 3, saat lewat START dgn gaji cair. Kartu = acak `mesin_acak` dari `KARTU_HADIAH_IKLAN`. Spanduk "COMEBACK CARD!" + "<You/P3> got LOW ROLL".
  Inventaris sampai ke client lewat siaran state "kartu" (seperti kartu gacha); RPC `rpc_kartu_bantuan` hanya tampilan.
- Getaran kamera: `_mulai_getar_kamera`/`_perbarui_getar_kamera` (`pemain_tampilan.gd`, dipanggil dari `_process` di `pemain.gd`), konstanta `GETAR_KAMERA_DURASI=0.8` /
  `GETAR_KAMERA_KUAT=0.5` + `_getar_kamera_sisa` (`pemain_dasar.gd`). Memakai `Camera3D.h_offset/v_offset` (tidak mengganggu posisi kamera yang mengikuti pemain), tanpa pengacak
  (sin/cos), dipicu di `_tampilkan_event_papan` untuk id "earthquake" (host, solo & client), DILEWATI di Very Low (`AudioGrafis.baca_tingkat() == "sangat_rendah"`).
- Bukti (`hasil/g3_bantuan/`): solo 16 run (Quick/Classic 2P/4P, alam+pantai) 0 SCRIPT ERROR; 5 kartu bantuan di Classic, semuanya valid (penerima termiskin & tertinggal >= 1000);
  getaran: `GETAR_KAMERA maks_h` 0.06-0.45, `akhir_h=0` tiap kali (21 kejadian). MP: 4P & 3P Classic + 3P Quick sinkron cek_gagal=0, kartu_beda=0; opsi rig `kaya_awal=1` (host +3000) memaksa kartu:
  kartu bantuan identik di host+c1+c2 (s402); host keluar -> kartu bantuan diberikan host BARU setelah migrasi, identik di c1 & c2 (s413). `batch_reg10` sama persis dgn G0
  (takeover ok=29, kamera_hud ok=4, 0 gagal, 0 scripterr), `cek_nilai` 8/8, `IKLAN_KARTU cek=OK` (iklan kartu awal tak berubah).
- BELUM: tampilan spanduk COMEBACK CARD & getaran di layar sungguhan (headless) -> uji HP G9; kekuatan getaran 0.5 tebakan awal, boleh disetel. Rig-only: log `KARTU_BANTUAN`/`GETAR_KAMERA`
  (`uji_nyata.gd`, `uji_robot_mp.gd`), opsi `kaya_awal=1` (`uji_robot_mp.gd`).
- Untuk G8 (Opus): kartu bantuan hampir tak pernah muncul di Quick (0 kartu di 12 run Quick solo; 5 kartu di 4 run Classic) -- selisih 1000 mungkin terlalu ketat untuk Quick; keputusan keseimbangan.

**Fase 5 G4 SELESAI (Sonnet, 02-10): Tebak Duel (solo + MP).** Pemain MANUSIA yang menonton duel (bukan peserta; 3-4 pemain) mengetuk salah satu dari dua tombol nama
peserta (tumpuk di tengah layar tonton, "WHO WINS? TAP ONE!"); satu ketukan, tidak bisa diubah, boleh tidak menebak; permainan TIDAK menunggu. Tebakan tidak diperlihatkan ke pemain lain.
- Kode: `ui_elemen.gd` (sinyal `tebakan_dipilih`, `tombol_tebak_p/m`, `teks_tebak`, `tebak_sisi`, fungsi `tampilkan_tebak/sembunyikan_tombol_tebak/batal_tebak/tebak_telat/_tampilkan_hasil_tebak`;
  hasil "Good guess!"/"Wrong guess." tampil di pengumuman akhir duel DAN di jalur lempar koin seri), `pemain_duel.gd` (blok "TEBAK DUEL": `_buka_tebak_duel`, `_saat_tebakan_dipilih`, `_catat_tebakan`,
  `rpc_kirim_tebakan(nomor, slot_ditebak)` any_peer->host, `rpc_tebakan_diterima(nomor, ok)` host->client, `_nilai_tebakan_duel`; `rpc_duel_dimulai` +param `nomor=0`; jendela host =
  `_tebak_terbuka` (true di awal `_kumpulkan_naskah_duel`, false begitu semua peserta terkunci -> tebakan telat dijawab ok=false -> "Too late!"); solo = `_tonton_ai_pilih_elemen` (~2,5 dtk, 2 segel),
  `pemain.gd` (sambung sinyal), `pemain_jaringan.gd` (migrasi: `_tutup_ui_jaringan_client` & `_reset_penantian_host` membuang tebakan berjalan, TANPA hadiah), `profil_pemain.gd` (kunci `tebak_benar` di `statistik_kosong`).
- Stat `tebak_benar` dicatat di host/solo (`_nilai_tebakan_duel` sesudah `_jalankan_duel`) dan ikut siaran state "statistik" -> identik di semua device. Nomor duel (`_nomor_duel`) mencegah tebakan basi dari duel sebelumnya.
- BELUM (sengaja, tahap lain): hadiah profil (XP 5 / Crowns 3 per tebakan benar, maks 5, baris "Duel guesses", `STAT_SEUMUR`) = G7. Tampilan tombol/teks di layar sungguhan belum dilihat (headless) -> uji HP G9;
  jendela solo cuma ~2,5 dtk game (Quick 1,5x = ~1,7 dtk nyata) -- sesuai rencana, tapi KETAT; kandidat disetel di uji HP (mis. tambah jeda khusus saat pemain bisa menebak).
- Bukti (`hasil/g4_tebak/`): rig-only `tebak=1` (`uji_nyata.gd` solo, `uji_robot_mp.gd` MP) = robot penonton menebak selang-seling penyerang/pembela lalu mencocokkan stat `tebak_benar` + teks hasil dgn pemenang sebenarnya (log `TEBAK_*`);
  `tebak_telat=1` (MP) = client urut genap mengetuk SESUDAH jendela tutup. Solo 16 run (4P Classic alam x8, 3P Classic pantai x4, 4P Quick pantai x4): 0 SCRIPT ERROR, 0 `TEBAK_CEK` gagal (4P Quick hampir tak ada duel AI-vs-AI -> 0 tebakan).
  MP: 3P Quick (1 tebakan benar), 3P Classic (host 3, c1 5 tebakan/3 benar, c2 7 tebakan TELAT -> 7 ditolak "Too late!"), 4P Classic (4 device: `tebak_benar_per_slot=[1,2,0,3]` identik, 2 telat ditolak), 3P+1AI Classic ([1,1,1,0] identik),
  host keluar saat pilih elemen (2 seed Classic 3P): migrasi ok, tebakan menggantung dibuang, duel berikutnya bersih, stat identik di host baru & client, cek_ok_migrasi 7-8, 0 beda.
  Regresi: S1 100 pertandingan (semua_ai) kode G3 vs G4 IDENTIK (baseline G0 sudah tidak berlaku -- G1-G3 mengubah ekonomi; pembanding baru: `hasil/g4_tebak/reg/s1_100_g3_pembanding.txt`), `cek_nilai` 8/8, `batch_reg10` sama dgn G3
  (satu SCRIPT ERROR di `uji_takeover` karena Control tiruan tanpa `batal_tebak` -> dijaga `has_method`, 0 error), `IKLAN_KARTU cek=OK`.
- Catatan teknis: solo dgn pemain manusia TIDAK deterministik antar-run kalau dijalankan paralel (beban CPU memengaruhi waktu); bukti "identik" hanya valid untuk run `semua_ai=1`.
  MP perlu build yang sama di semua HP (RPC baru: `rpc_kirim_tebakan`, `rpc_tebakan_diterima`, param baru `rpc_duel_dimulai`).

**Fase 5 G5 SELESAI (Sonnet, 02-10): putar ulang rolet (solo, iklan berhadiah).** Di duel manusia vs AI (alur asli `ui_elemen.jalankan_duel`, bukan mode tonton/naskah), kalau skor pemain < skor musuh
(KALAH skor; seri -> lempar koin biasa, tidak ditawari) muncul dialog "SO CLOSE! Watch an ad to spin your wheel again?" [WATCH AD: SPIN AGAIN] [NO THANKS]. Ditonton sampai habis -> HANYA rolet pemain diputar ulang
(elemen tetap, angka baru dari `ui_elemen.rng`), skor dihitung ulang ("NEW TOTAL SCORE: x"), lalu alur normal (menang / seri -> lempar koin / tetap kalah). SEKALI per pertandingan (`_putar_ulang_terpakai`, direset di `pemain.gd`);
**NO THANKS = tidak ditawari lagi di pertandingan itu** (`_putar_ulang_ditolak`, diperbaiki 02-10 sebelum G6); iklan GAGAL ditonton -> boleh ditawari lagi di kekalahan berikutnya. Ikut batas 8 iklan berhadiah per hari (lewat `PengelolaIklan.rewarded_tersedia()`). Multiplayer TIDAK pernah (`penawar_putar_ulang` hanya diisi saat `peran_multiplayer == ""`).
- Kode: `ui_elemen.gd` (`penawar_putar_ulang: Callable`; fungsi bantu `_teks_panel_pemain()` & `_animasi_rolet_pemain()` DIPECAH dari `jalankan_duel` -- perilaku & urutan `rng` sama; blok putar ulang sebelum "PENGUMUMAN_TRANSISI"),
  `pemain_duel.gd` (`_tawarkan_putar_ulang()`, pola `_tawarkan_iklan_hutang`; gagal iklan -> `teks_bantuan` "No ad right now." 1,5 dtk), `ui_dinamis.gd` (`tanya_iklan_hutang` kini punya parameter berisi nilai bawaan LAMA +
  `tanya_putar_ulang()` memakainya, latar 0,6), `pemain.gd` (sambung penawar + reset flag), `profil_pemain.gd` (kunci `putar_ulang` di `statistik_kosong`; stat dipakai G7/rekap).
- Bukti (`hasil/g5_putar_ulang/`): rig-only (`uji_nyata.gd`, opsi `iklan=1` stub iklan tersedia; baru `putar_tolak=1` & `iklan_gagal=1`; `pengelola_iklan.gd` STUB rig +`uji_tonton_gagal` -- JANGAN disalin ke `game/`).
  Solo 2P Classic x8 (`iklan=1`): TIAP run tepat 1 tawaran & 1 klik, 8/8 `PUTAR_ULANG_CEK` OK (skor baru > musuh -> slot 0 menang, < -> kalah), stat `putar_ulang`=1, kekalahan berikutnya (hingga 7 kalah duel di satu run) TIDAK ditawari lagi;
  3 dari 8 putar ulang berbalik jadi menang; Quick 2P x4: 2 tawaran (1 cek OK, 1 skor baru = skor musuh -> lempar koin tanpa error); NO THANKS x4: ditawari tiap kalah skor (3/8/5/5), stat 0; iklan gagal: ditawari lagi tiap kalah, pesan "No ad right now." muncul (3/3 di s551), stat 0;
  3P/4P (lawan=2): 0 tawaran (tidak ada duel manusia). 0 SCRIPT ERROR. Regresi: S1 100 (semua_ai) G4 vs G5 IDENTIK (`reg/s1_100_g5.txt`), `cek_nilai` 8/8, `batch_reg10` sama dgn G4, MP 3P Classic + 4P Quick sinkron (lihat `mp_ringkas.txt`).
- BELUM: dialog & animasi putar ulang di layar sungguhan (headless) + iklan AdMob sungguhan -> uji HP G9; `Engine.time_scale` Quick 1,5x TIDAK dikembalikan 1x saat dialog tampil (tidak ada timer yang menunggu, dan tawaran hutang juga begitu) -- tambahkan kalau uji HP bermasalah.
  Untuk G8 (Opus): putar ulang menaikkan peluang menang pemain solo yang menonton iklan (disengaja, "kekuatan boleh di solo"); keseimbangan role di rig tidak terpengaruh (rig/AI-vs-AI tidak punya penawar).

**Fase 5 G6 SELESAI (Sonnet, 02-10): tombol AI cepat (solo).** Tombol ">>" kecil di HUD kanan atas (di kiri tombol ⚙; `tombol_ai_cepat`, dibuat di `ui_dinamis.gd` `setup_ui_elegan`, `focus_mode = NONE` supaya Spasi
tidak menekannya; tampil HANYA di solo -- `pemain.gd _mulai_transisi_game`). Ketuk = hidup/mati (`UiDinamis.ganti_ai_cepat` -> `ProfilPemain.atur_ai_cepat`); tombol emas = hidup, abu-abu = mati; **bawaan MATI**.
- Pilihan diingat di profil: `ProfilPemain.ai_cepat`, berkas `profil.cfg` bagian `[pengaturan] ai_cepat` (dibaca `get_value(..., false)` -> berkas lama aman, `VERSI` tidak dinaikkan karena `muat()` tidak memeriksanya).
- Kecepatan: `_ai_cepat_berlaku()` + `_atur_kecepatan_permainan()` (`pemain.gd`); konstanta `KECEPATAN_AI_CEPAT=2.0` (`pemain_dasar.gd`). 2x (Quick juga 2x, bukan 1,5x) hanya kalau: SOLO, saklar hidup, `_giliran_berjalan`, belum selesai,
  giliran slot AI, `ui_elemen` (duel / tebak duel) TIDAK tampil, `menu_aksi` TIDAK tampil, dan bukan saat spanduk event/bounty antar-ronde (`_pengumuman_papan_berjalan`, diset di `ganti_giliran` slot 0). Selain itu kecepatan lama
  (Quick 1,5x, Classic 1x). Classic yang tidak pernah menyalakan tombol TIDAK menyentuh `Engine.time_scale` (sama seperti dulu); sesudah pernah menyala, `StatusJaringan.skala_waktu_dasar` mengembalikan 1x.
- Multiplayer: tombol tersembunyi dan `_ai_cepat_berlaku()` selalu false (`peran_multiplayer != ""`) walau profil `ai_cepat=true`.
- Bukti (`hasil/g6_ai_cepat/`): rig-only `uji_nyata.gd` opsi `ai_cepat=1|0|ingat` (robot menekan >>, pencocokan `Engine.time_scale` tiap frame vs keadaan, baca berkas profil.cfg; log `AI_CEPAT*`) + `uji_robot_mp.gd` opsi `ai_cepat=1`.
  Solo Classic 2P x3, 4P x1, Quick 2P & 4P: `salah=0` (selisih >= 3 frame berturut-turut), 0 SCRIPT ERROR; klik toggle hidup->mati->hidup, berkas profil ikut berubah tiap klik; proses BARU dgn HOME yang sama: tombol langsung hidup tanpa klik
  (`profil_awal=true`); pembanding mati `frame_2x=0`. Frame lebih sedikit ~19-24% di run yang separuh waktunya hidup (4P Classic 16147 vs 21313; Quick 4P 2775 vs 3654). MP (3P+1AI Classic, 2P+2AI Quick) dgn profil hidup di semua device: `frame_2x=0`, tombol tak pernah terlihat, cek_gagal=0.
  Regresi saklar MATI (bawaan): S1 100 pertandingan G6 vs G4 vs G5 IDENTIK (`reg/s1_100_g6.txt`), `cek_nilai` 8/8, `batch_reg10` sama dgn G5, MP 3P Classic + tebak sinkron (`tebak_benar_per_slot` identik di 3 device).
- BELUM: posisi/gaya tombol di layar sungguhan (headless) -> uji HP G9 (posisi `(-130, 20)` kanan atas, ukuran 50x50 -- boleh digeser). Dialog yang butuh pemain di giliran AI selain duel/menu aksi (mis. tawaran hutang, jual aset) tetap berjalan 2x;
  tidak menunggu timer jadi aman, tapi kalau di uji HP terasa kurang nyaman tambahkan syaratnya di `_ai_cepat_berlaku()`.
- Perbaikan G5 yang dikerjakan sebelum G6 (02-10): **NO THANKS pada putar ulang rolet = tidak ditawari lagi di pertandingan itu** (`_putar_ulang_ditolak`, `pemain_duel.gd` + reset di `pemain.gd`); iklan GAGAL tetap boleh ditawari lagi.
  Bukti `hasil/g6_ai_cepat/tolak_ringkas.txt`: 4 run "tolak" (kalah duel 8/5/4/5 kali) -> hanya 1 tawaran & 1 klik per run (sebelumnya 3/8/5/5); iklan gagal tetap 3/5 tawaran; ditonton tetap sekali + cek skor OK.

**Fase 5 G7 SELESAI (Sonnet, 02-10): hadiah profil Tebak Duel.** `profil_pemain.gd`: konstanta `XP_PER_TEBAKAN=5`, `CROWNS_PER_TEBAKAN=3`, `TEBAK_MAKS_HADIAH=5`; `catat_akhir_match` menambah `xp_tebak`/`crowns_tebak` =
5/3 x `mini(tebak_benar, 5)` ke XP & Crowns (hasil dikembalikan di `tebak_benar`, `tebak_dihitung`, `xp_tebak`, `crowns_tebak`); `"tebak_benar"` masuk `STAT_SEUMUR` (angka PENUH, tidak dibatasi 5). **Tidak ikut DOUBLE**
(`tambah_double` tetap hanya `xp_match + xp_penghargaan`; `bisa_double` tidak berubah). `ui_profil.gd`: angka atas kartu hadiah (`_tulis_angka`) ikut menjumlah `xp_tebak/crowns_tebak`; baris baru
"Duel guesses: N right  +X XP  +Y Crowns" di `_isi_baris_hadiah` (urutan: level up, tebakan, misi, penghargaan; maks 3 baris + "+N more rewards"). Berkas profil lama/stat tanpa kunci `tebak_benar` aman (default 0).
Tidak ada baris "Guesses" di panel statistik profil (hanya tersimpan di `statistik["tebak_benar"]`; tambahkan di `ui_profil.gd` ~baris 402 kalau pemilik mau).
- Bukti (`hasil/g7_profil/`): uji unit rig-only baru `uji_hadiah_tebak.tscn` 21/21 (N=0,1,3,5,7: hadiah, profil naik tepat, stat seumur penuh; DOUBLE tanpa tebakan; bisa_double false saat giliran 0; muat ulang berkas; berkas lama).
  Solo penuh Classic 3P/4P x4 + Quick 3P/4P x2 (`profil=1 tebak=1 iklan=1`): `PROFIL_CEK OK` (rumus, profil naik tepat = match+penghargaan+misi+tebak, berkas, muat ulang, kartu YOUR REWARDS, DOUBLE tidak menggandakan tebakan, EXIT) dgn tebak_benar 5/9/9/12 -> dihitung 5
  (+25 XP +15 Crowns), stat seumur penuh (5/9/9/12), baris kartu tampil; Quick tanpa tebakan -> 0 hadiah, tanpa baris. MP Quick 3P x3 (host + 2 client): `PROFIL_MP cek=OK` di 9/9 device; seed 23: client 2 tebakan benar 1x -> +5 XP +3 Crowns hanya di HP itu, tercatat sekali.
  Regresi: S1 100 G7 == G4 IDENTIK, `cek_nilai` 8/8, `batch_reg10` sama dgn G5, `cek_muat_f3` 26/26. Rig-only: `uji_nyata.gd` (`PROFIL_CEK` + `tebak_hadiah`/`tebak_baris_kartu`, log `TEBAK_HADIAH`), `uji_robot_mp.gd` (`PROFIL_MP` + log `TEBAK_HADIAH_MP`).
- BELUM: tampilan baris "Duel guesses" di layar sungguhan (headless) -> uji HP G9. Classic MP 3P/4P di rig berhenti di BATAS_GILIRAN sebelum tuntas (tak ada hadiah profil); jalur hadiah MP diuji lewat Quick 3P.

**Fase 5 G8 SELESAI (Opus, 02-10; rincian RENCANA_fase5 bagian 10):**
- Soft-lock bangkrut tanpa petak DIPERBAIKI (`pemain_papan.gd`: `eksekusi_jual_aset` cabang `elif not _punya_petak(slot)` -> hutang dibawa,
  giliran lanjut; RPC baru `rpc_jual_habis`; bantu `_punya_petak`/`_teks_bawa_hutang`). Bukti `hasil/g8_bangkrut/`: kode lama MACET, kode baru solo x7
  + MP host/client(1v1, 3P)/AI lolos, 0 SCRIPT ERROR. Opsi rig-only `hutang_habis=SLOT` (`uji_nyata.gd`, `uji_robot_mp.gd`).
- Jendela Tebak Duel solo: +maks 2 dtk (`TEBAK_SOLO_TAMBAHAN`, `pemain_duel._tonton_ai_pilih_elemen`), hanya saat tombol tebak tampil, berhenti begitu
  pemain menebak. Bukti `hasil/g8_tebak/` (opsi rig-only `tebak_jeda=N`).
- U9 ulang benih 50000 (+S2 tambahan 60000) LOLOS P14: S1 2P 48.8/54.6/45.6/48.3/52.7 (air/angin/api/petir/tanah), S2 4P gabungan 800
  21.2/27.6/24.3/25.7/25.9 (S2 400 pertama air 18.8 -> ditambah 400, pola F5), S5 297/331/377 dtk. Angka K3/K5/F5 TIDAK diubah.
  Kolom rig-only `f5=ev/bm/bk/kb/hb` di baris SEIMBANG.
- Bounty diklaim hanya di 8% pertandingan Quick 2P (duel jarang), kartu bantuan 2-5% -> USULAN K11/K12 (RENCANA_fase5 10.4) menunggu pemilik.
- Regresi: MP 37/37 (97 SELESAI, 0 MACET/scripterr/beda/cek_gagal), cek_nilai 8/8, cek_muat 26/26, reg10 sama dgn G7 (`hasil/g8_regresi/`).
- Temuan baru (dipantau): 1x BEDA jebakan Phoenix host vs client di uji bangkrut MP s821 (tidak terkait G8, tidak muncul di regresi) -- RENCANA_fase5 10.5.

**TEMUAN (dicatat Sonnet 02-10; no. 1 DIPERBAIKI di G8):**
1. **[DIPERBAIKI G8] Soft-lock bangkrut tanpa petak** (kode LAMA, ada juga di ZIP b9, bukan dari G0-G7): `eksekusi_jual_aset` (`pemain_papan.gd` ~baris 975-1004) -- kalau pemain manusia masih minus sesudah menjual petak TERAKHIR, cabang `else` hanya menulis
   "Still in minus! Tap another tile to sell." dan menunggu ketukan padahal tidak ada petak lagi -> permainan macet (pemeriksaan `punya_aset` hanya di awal, ~baris 1276). Terlihat 2 dari 8 run solo Classic G7 (`hasil/g7_profil/solo_ringkas.txt`, s701 & s723, `SIM MACET`).
   Event GOLD RUSH (denda x2, G1) membuat hutang lebih besar sehingga lebih sering terjadi. Perlu keputusan aturan (hutang dihapus / pemain tersingkir / dll.) -> Opus, SEBELUM rilis b10.
2. Catatan G8 (sudah ada di atas): bounty & kartu bantuan hampir tak muncul di Quick; jendela tebak solo ~2,5 dtk ketat; putar ulang rolet menambah peluang menang solo.

## 0. Aturan tetap dari pemilik proyek (WAJIB)
1. Balas dalam **Bahasa Indonesia saja**.
2. Mengedit file yang SUDAH ada: ubah hanya baris/bagian relevan, JANGAN tulis ulang seluruh file.
   (File baru boleh ditulis penuh.) Tips: Edit gagal diam-diam kalau jumlah tab salah -> pakai skrip Python
   yang mengiris daftar baris + assert isi persis sebelum menulis.
3. Selalu beri arahan KAPAN ganti model: Opus = arsitektur / tinjau rencana besar / penyetelan keseimbangan /
   bug membingungkan; Sonnet = menulis kode dari rencana yang sudah disepakati, cek diff, tambalan kecil.
4. Jangan kirim file bernama sama berulang kali di pesan terpisah; kalau ada yang berubah kirim SET LENGKAP
   sekaligus (satu ZIP) dan minta unduhan lama dibuang.
5. Proyek: game papan 3D Godot 4.7.1 (GDScript) "Tile Duel", sudah rilis di Google Play. Aturan P1: fungsi
   `ai_*.gd` hanya BACA state (tanpa efek samping stat). RNG game HARUS lewat `mesin_acak` (bukan `randi()`).
6. (02-10) Di AKHIR TIAP TAHAP (tiap putaran F5 selesai dianalisis, tiap fase F6/F7/F8, dst.): perbarui
   HANDOFF_LANJUT.md (status + langkah berikutnya) dan push ke GitHub (branch `claude/wonderful-gates-8v431l` -- branch kerja sejak Fase 5; `claude/new-session-e4ogqo` LAMA, jangan dipakai),
   bersama data hasil tahap itu. Pekerjaan tidak boleh hanya ada di satu sesi/container.
7. (02-10) JANGAN jalankan dua rantai simulasi bersamaan, dan JANGAN ubah file apa pun di `rig/` (terutama
   `rig/proj_tanpa_uji/*.gd`) selama simulasi masih berjalan. Cek `ps -eo comm | grep -c ^Godot` = 0 dulu sebelum
   mengubah angka atau memulai rantai baru (`pgrep -f Godot_v4` keliru: cocok dengan baris perintahnya sendiri).
8. (02-10) Pantau panjang sesi. Kalau sesi sudah panjang (satu tahap selesai & ter-push, puluhan panggilan alat /
   beberapa hasil simulasi panjang, konteks mulai diringkas otomatis, atau tahap berikutnya cocok untuk model lain):
   INGATKAN pemilik untuk membuka sesi baru, setelah memastikan semua sudah di-push, dan beri prompt siap tempel
   (lihat dokumen "Tile Duel -- Panduan Sesi Kerja": https://claude.ai/code/artifact/bc2bfff0-d4f6-4ff0-89ed-16dd35ecbe48).
9. (02-10) Sesi baru TIDAK bisa membaca percakapan lama. Jadi di akhir tiap sesi: tambah ringkasan (tanggal, model,
   yang dikerjakan, keputusan, commit terakhir, langkah berikutnya) ke `docs/LOG_SESI.md` lalu push. Sesi baru membaca
   `CLAUDE.md` -> `HANDOFF_LANJUT.md` -> `docs/LOG_SESI.md`.

## 1. Isi repo
| Folder | Isi |
|---|---|
| `game/` | Produksi saat ini, 35 .gd = **29 set resmi** (daftar di bagian 5) + 6 file pendukung T21 yang tidak dikirim. F1-F4 sudah diterapkan (P13, K23, T19). **Angka final F5 SUDAH diterapkan (F6, 02-10); 34/35 identik dengan rig (beda hanya `pengelola_iklan.gd`).** |
| `docs/` | `RENCANA_fase4_role.md` = sumber kebenaran tunggal (bagian 14.19 = rencana B-f; status F0-F4 di bagian paling bawah). Plus rencana fase lama & patokan. |
| `rig/proj_tanpa_uji/` | Proyek Godot lengkap untuk rig simulasi (headless): produksi + `uji_*.gd/.tscn`. **Setelah F6: = `game/` + uji** (diff hanya `pengelola_iklan.gd` stub + berkas `uji_*`). Cache `.godot/` tidak di-git -> impor ulang dulu (bagian 4). |
| `rig/skrip/` | `f4/uji_seimbang.sh` (pelari), `f4/ringkas_seimbang.py` (ringkasan win-rate + CI), `f4/buat_tugas_u9.py` (pembuat S1-S5), `f4/cek_panggil.py`, `f5_analisa.py`, `f5_pasangan.py`, skrip batch regresi `batch_reg10.sh`, `uji_f2_t2_a/b.sh`, dll. |
| `hasil/f4_u9_baseline_sebelum_tuning/` | Data S1 (1200, 2P) & S2 (400, 4P) SEBELUM penyetelan (S3 parsial 31 baris -- JANGAN dipakai). |
| `hasil/f5_putaran/r1..r4/` | Hasil S1 tiap putaran penyetelan (r3 lengkap 1200; r4 + S2 4P). |
| `hasil/f5_konfirmasi_b20000/` | KONFIRMASI angka final, benih baru 20000: S1-S5 (+ berkas `.tugas`). |
| `hasil/f5_s4_tambahan/` | S4 tambahan 800 (benih 30000 & 40000) -- digabung dengan S4 benih 20000. |
| `f5_kandidat/*.patch` | Selisih produksi lama -> ANGKA FINAL F5 (sudah diterapkan di F6). |
| `hasil/f6_regresi/` | Hasil F6: ringkasan regresi MP 37 skenario, `batch_reg10`, `cek_nilai` 8/8. Tinjauan F6: `tinjauan_reg10/` (temuan 1), `tinjauan_mp_d1/` (temuan 4) -- baca `RINGKAS.txt` masing-masing. |
| `hasil/f7_bersih/` | F7: `F7_cek.txt` (grep debug, sinkron, cek_muat, cek_nilai) + log `uji_tanah2` setelah diperbaiki. |
| `kiriman/` | `TileDuel_FaseB_b9.zip` (F8; 29 .gd + RENCANA, uji HP lolos) dan **`TileDuel_Fase5_b10.zip` (G9; 29 .gd = `game/` saat ini, komit 3507b38; belum diuji HP)**. |

## 2. Status ringkas (rincian: RENCANA 14.21)
- F0-F4 selesai. **F5 SELESAI 02-10 (Opus).** Semua syarat P14 lolos di benih BARU 20000:
  | | air | angin | api | petir | tanah | catatan |
  |---|---|---|---|---|---|---|
  | baseline S1 2P | 47.7 | 57.5 | 42.9 | 51.7 | 50.2 | jebakan/AI 1.88 |
  | **konfirmasi S1 2P** | 50.2 | 49.8 | 46.5 | 48.1 | 55.4 | 0 pasangan !, 0 sel wajib/mati, jebakan/AI 2.12 |
  | konfirmasi S2 4P | 22.7 | 27.6 | 21.1 | 26.7 | 27.4 | target 20-30 |
  | konfirmasi S3 solo Lv20 | 44.8 | 50.8 | 54.2 | 51.0 | 49.2 | |
  | konfirmasi S4 solo Lv1 (1200 gabungan) | 48.8 | 55.2 | 46.9 | 47.7 | 51.5 | DASAR tidak diubah |
  S5 panjang 2P/3P/4P = 264/306/387 dtk (batas 318/400/464). XP: Lv15 ~40 pertandingan Quick.
- Angka final (produksi -> final): AMBANG_NILAI 50->40, AMBANG_PELUANG 80->90, NILAI_PETIR_LEWAT_GILIRAN 75->150,
  FAKTOR_ULANG_ULTIMATE 1.5->1.2 (ai_jebakan.gd); hot_flames 70/80/90->90/110/130, fire_tax .25/.5/.75->.5/.75/1.0,
  strong_wind .12/.14/.16->.11/.12/.13, homing_wind .25/.5/.75->.15/.3/.45 (data_role.gd NODE_LV).
- Kunci diagnosis: AI api dulu tidak pernah memakai jebakan petir melawan role petir (penilaian jebakan api terlalu
  tinggi), padahal petir tidak punya grounded. Dipantau: angin Lv1 ~55%, air Lv20 44.8%, api 4P ~21% (lolos, dekat batas).

## 3. rig vs produksi (setelah F7)
`game/` dan rig kini memakai angka final F5. `pengelola_iklan.gd` di rig sengaja beda (stub iklan untuk uji) -- JANGAN disalin ke `game/`. Sejak F7 G4 juga `pengelola_pembelian.gd` (stub rig; `game/` punya versi asli, diuji lewat salinan `pembelian_asli_uji.gd`).
Satu-satunya perbedaan lain: `rig/proj_tanpa_uji/uji_nyata.gd` (rig-only) harapan `cek_nilai` sudah 390/130/324.
Rig-only lain: `uji_*`, `cek_muat_f3.gd` (alat), dan 5 file proyek yang tidak ada di `game/` (`audio_grafis`, `lingkungan_alam`,
`menu_grafis`, `mesh_instance_3d`, `validasi_peta` -- tidak pernah diubah fase mana pun). F7: `uji_tanah2.gd` kini punya tiruan `_angka_jebakan` (0 SCRIPT ERROR).

## 4. Cara menjalankan rig (headless)
1. Perlu Godot **4.7.1-stable linux x86_64**. Unduh dari GitHub releases (`godotengine/godot-builds`, tag `4.7.1-stable`) ke
   `/opt/godot/Godot_v4.7.1-stable_linux.x86_64` (atau set env `G=`). Kalau jaringan memblokir, minta pengguna mengunggah binernya.
2. Impor sekali: `G --headless --path rig/proj_tanpa_uji --import` (buat ulang cache `.godot/`; perlu beberapa menit).
3. Buat tugas: `python3 rig/skrip/f4/buat_tugas_u9.py` (hasilkan s1..s5.tugas; deterministik dari benih).
4. Jalankan: `PARALEL=2 bash rig/skrip/f4/uji_seimbang.sh <berkas.tugas> <hasil.txt>` -- bisa DILANJUTKAN kalau terputus
   (baris yang tag+seed+peta sudah ada dilewati). **Satu pelari saja per mesin 2-core.** JANGAN jalankan dua rantai berbeda bersamaan
   dan JANGAN ubah file `.gd` rig sementara rantai masih berjalan (pernah mencemari data 4P r1 -- lihat RENCANA).
5. Ringkas: `python3 rig/skrip/f4/ringkas_seimbang.py <hasil.txt>`; rincian pasangan: `python3 rig/skrip/f5_pasangan.py <hasil> api petir`.
6. Kecepatan terukur: ~2.3 dtk/pertandingan (PARALEL=2, `--fixed-fps 60`) -> S1 (1200) ~45-50 menit. Perintah `sleep` panjang
   di alat Bash perlu parameter `timeout` (default 2 menit).
   **Sesi Claude Code cloud (02-10):** unduhan Godot dari GitHub releases LOLOS lewat proxy; mesin 4 inti -> `PARALEL=4`,
   S1 (1200) ~20 menit, S2 (400) ~10 menit. Hasil deterministik per benih (tidak bergantung PARALEL). Jalankan tiap rantai
   sebagai perintah latar belakang terpisah (<30 menit tiap perintah). Cek proses dengan `ps -eo comm | grep -c ^Godot`
   -- JANGAN `pgrep -f Godot_v4` (cocok dengan baris perintah sendiri).
   `buat_tugas_u9.py <dir> <benih_awal>` -- argumen ke-2 = benih awal (bawaan 5000).
7. Skrip `f4/uji_seimbang.sh` & beberapa skrip lama masih berisi path scratchpad lama -- ubah/override lewat env bila perlu.
   Skrip MP (`uji_f2_t2_a/b.sh`, LocalPlay.tscn) TIDAK boleh jalan paralel (port tetap) -- jalankan berurutan.

## 5. Langkah berikutnya
- **F6 SELESAI (Sonnet, 02-10):** 8 angka final diterapkan ke `game/` (commit 0785152); `cek_nilai=1` 8/8 (390/130/324);
  regresi MP 37/37 skenario (97 baris SELESAI, 0 MACET/scripterr/beda/cek_gagal); U11 OK. Rincian: RENCANA 14.22.
- **Tinjauan F6 SELESAI (Opus, 02-10, RENCANA 14.23):**
  1. `batch_reg10` BUKAN "9 uji 0 gagal": 6 uji "gagal: 0"; `uji_pedang` & `uji_cabang_solo` memang tanpa baris kesimpulan
     (cuma mencetak pengamatan) -> diperiksa manual: benar & IDENTIK dgn angka produksi lama (cabang: benih 1-10);
     `uji_tanah2` 2 SCRIPT ERROR identik dgn angka lama (terbukti sudah ada sebelum F6). Data: `hasil/f6_regresi/tinjauan_reg10/`.
  2. Set resmi 29 .gd (tiga sumber cocok: `sinkron_tanpa_uji.sh` + `jebakan_dasar`, `game/` - 6 file T21, commit fe39bec):
     `ai_jebakan ai_musuh data_pemain data_role jebakan_air jebakan_angin jebakan_api jebakan_dasar jebakan_petir jebakan_tanah
     layar_local_play main_menu migrasi_host pemain pemain_dasar pemain_duel pemain_jaringan pemain_kartu pemain_papan
     pemain_role pemain_tampilan petak_kartu profil_pemain status_jaringan ui_dinamis ui_elemen ui_petak ui_profil ui_role` (.gd).
     6 file sisa di `game/` (T21): `petak_papan`, `koin_tercecer`, `petak_permata`, `lingkungan_pantai`, `rolet` (tidak pernah
     diubah Fase 4, identik dgn rig) + `pengelola_iklan` (produksi asli AdMob; rig pakai stub). Ada di `game/` supaya proyek
     lengkap; pemilik sudah punya -> tidak dikirim.
  3. Komentar `AMBANG_NILAI` (F5 r1 50->40) & `AMBANG_PELUANG` (F5 r2 80->90) di `ai_jebakan.gd` game + rig; angka tidak berubah.
  4. 97 vs 96 = skenario **D1** (3P c1 keluar saat pilih elemen): di run F6 c1 tidak sempat jadi peserta duel (hanya 1
     kesempatan/pertandingan, giliran 24) -> main sampai habis, +1 SELESAI. Run ulang D1 (angka F6 & angka lama): c1 keluar di
     giliran 24, 2 baris, 0 error -> variasi timing, bukan regresi; jalur D1 kini sudah teruji. Data: `hasil/f6_regresi/tinjauan_mp_d1/`.
- **F7 SELESAI (Opus, 02-10):** grep counter/debug sementara/print/TODO di `game/` = 0; saklar UJI_* false; 34/35 `game/` identik
  dgn rig (beda hanya `pengelola_iklan.gd`, disengaja); `cek_muat_f3` 26/26, `cek_nilai` 8/8; `uji_tanah2.gd` (rig-only)
  diperbaiki -> 0 SCRIPT ERROR. Data: `hasil/f7_bersih/F7_cek.txt`.
- **F8 SELESAI (02-10):** `kiriman/TileDuel_FaseB_b9.zip` = 29 .gd + RENCANA = 30 file. Pemilik: buang unduhan lama, TIMPA ke-29
  file (14 berbeda dari commit fe39bec/b8 -- jangan hanya salin yang berubah di F6), buka Godot, tunggu impor, uji HP RENCANA
  bagian 10 (Langkah A + B). `ID_INTERSTISIAL_ASLI` (`pengelola_iklan.gd`) masih kosong -- keputusan pemilik sebelum rilis.
- **UJI HP b9 LOLOS (02-10, laporan pemilik: "lancar") -> Fase 4 SELESAI** (RENCANA 14.24). `game/` = isi ZIP b9 (dicek
  byte-per-byte); jangan ubah `game/` sebelum rilis kecuali ada bug.
- **BERIKUTNYA (pemilik): rilis A+B.** Daftar periksa (rincian RENCANA 14.24): (1) isi `ID_INTERSTISIAL_ASLI` atau sengaja
  biarkan iklan uji; (2) naikkan version code; (3) uji pasang-timpa di atas versi Play (profil lama utuh, layar ROLE minta role);
  (4) coba build rilis sekali; (5) Internal testing -> Production. Bug dari HP/rilis -> Opus menganalisis dulu.
- **Fase 5 (rencana Opus 02-10, DISETUJUI): `docs/RENCANA_fase5_seru.md`** -- event papan, bounty, kartu bantuan posisi terakhir, Tebak Duel,
  putar ulang rolet (iklan, solo), tombol AI cepat (solo). Status: **DISETUJUI 02-10, pemilik "setuju semua a"**
  (dicatat di bagian 1 & 9 rencana itu). G0-G8 SELESAI (G8 Opus 02-10, bagian 10). Berikutnya: (1) pemilik memilih **K11** (bounty Quick) & **K12** (kartu bantuan Quick), RENCANA_fase5 10.4; kalau b/c -> Sonnet menerapkan + U9 S1+S2 ulang di benih BARU (mis. 70000) WAJIB sebelum G9; kalau a/a -> langsung **G9 (Sonnet)**: bersih-bersih (pola F7) + `kiriman/TileDuel_Fase5_b10.zip` (set lengkap) + uji HP (RENCANA_fase5 bagian 6). Baca rencana itu PENUH (~280 baris); RENCANA_fase4 hanya untuk rujukan.
- **G9 SELESAI (Sonnet, 02-10):** K11 = a, K12 = a (RENCANA_fase5 bagian 9). `kiriman/TileDuel_Fase5_b10.zip` = 29 .gd resmi dari `game/` akhir G8 (13 berbeda dari b9; 6 file pendukung tidak dikirim, tidak berubah sejak b9).
  Bersih-bersih minimal: `game/` 34/35 identik dgn rig (beda hanya stub iklan), `UJI_*` false, tanpa `print`/TODO -> tidak ada .gd `game/` berubah, ZIP tidak dibuat ulang; `cek_muat`/`cek_nilai`/regresi MP/U9 TIDAK diulang (sengaja, hemat kredit; hasil G8 masih berlaku).
  SISA: 11 `godot.log` terlacak di `rig/proj_tanpa_uji/sim/home_*` (sampah uji) -- penghapusan ditolak izin sesi, hapus dgn `git rm -r rig/proj_tanpa_uji/sim` bila mau.
  **UJI HP b10 LANCAR (02-10, laporan pemilik) -> Fase 5 SELESAI; `game/` = isi ZIP b10, jangan ubah kecuali ada bug.**
  **BERIKUTNYA: sesi OPUS menyusun rencana Fase 6-9 (hemat kredit); pemilik merilis A+B+Fase 5** (daftar periksa rilis di atas, plus `ID_INTERSTISIAL_ASLI`). Bug dari HP -> Opus dulu.
- **FASE 6 G0+G1 SELESAI (Sonnet, 02-10; rincian RENCANA_fase6_9 bagian 9, bukti `hasil/g6_profil/`):** profil VERSI 3 (`respect`, `mvp_total`; uji headless 18/18), penjaga versi lobby BARU
  (`VERSI_PROTOKOL=2`, `rpc_sosial_profil`/`rpc_tolak_versi` -- nama RPC baru harus jatuh SESUDAH `rpc_role_lobby` secara abjad), profil lobby -> `StatusJaringan.profil_slot` (semua HP), nama+level tampil di lobby/teks/papan/akhir.
  `game/` & rig identik (beda hanya stub iklan); rig-only: `uji_profil_v3.gd/.tscn`, `uji_robot_mp.gd` (nama "Bot ..." + log `PROFIL_NAMA`). Subset MP 1v1 / 3P client keluar / 4P migrasi host: 0 beda, 0 SCRIPT ERROR; `cek_muat_f3` 26/26. `game/` BERUBAH (8 .gd) -> ZIP b11 dibuat di G3.
- **FASE 6 G2 SELESAI (Sonnet, 03-10; rincian RENCANA_fase6_9 bagian 9, bukti `hasil/g6_mvp_respect/`):** MVP (`ProfilPemain.hitung_mvp`, dihitung lokal dari penghargaan; seri -> pemenang -> slot terkecil; `catat_mvp()` di `_proses_hadiah_akhir`; label "MVP" di layar akhir),
  Respect (`kirim_respect` -> client `rpc_zrespect_kirim` ke host -> host validasi -> `rpc_zrespect_terima` ke target; 1x per pasangan per laga; AI/diri sendiri ditolak; toast "<nama> gave you Respect!"),
  kartu profil (`UiProfil.tampilkan_kartu_profil`: ketuk nama di lobby [RichTextLabel url] atau baris layar akhir; profil lobby + field `role`). **ATURAN RPC pemain: nama RPC baru HARUS diawali `rpc_z`** (sesudah `rpc_umumkan` = RPC terakhir lama); di `layar_local_play.gd` awalan > `rpc_role_lobby` (mis. `rpc_s*`/`rpc_t*`/`rpc_z*`).
  Bukti: `uji_profil_v3` 22/22 (+5 uji MVP), `cek_muat_f3` 26/26, MP quick: Q1 1v1, S1 3P client keluar, M2 4P migrasi host = 0 beda/0 SCRIPT ERROR; R1 (3P+1AI skenario `respect`): tiap HP menerima TEPAT +1 per lawan manusia (+2), kirim ganda (lokal & paksa lewat RPC / `_host_proses_respect`) tidak menambah, diri sendiri & AI ditolak. MVP sama di semua HP. `game/` & rig identik (beda hanya stub iklan); `game/` BERUBAH (6 .gd) -> ZIP b11 di G3.
  BELUM teruji: tampilan nyata (tombol RESPECT/kartu/toast di layar HP, tata letak 4 pemain) dan jalur TOLAK versi -> uji 2 HP di G3.
  **FASE 6 G3 SELESAI (Sonnet, 03-10; bukti `hasil/g6_bersih/G3_cek.txt`):** bersih-bersih pola F7 (0 debug/print/TODO, `UJI_*` false, `game/` 34/35 identik dgn rig); .gd `game/` tidak berubah.
  `kiriman/TileDuel_Fase6_b11.zip` = 29 .gd resmi (9 berbeda dari b10). Pemilik: buang unduhan lama, TIMPA ke-29 file, impor, uji 2 HP sesuai daftar di RENCANA_fase6_9 bagian 9 (nama, level, MVP, Respect, kartu profil, versi beda ditolak, profil lama utuh). `game/` = isi ZIP b11; jangan ubah kecuali bug.
  **UJI HP b11 LOLOS (03-10, laporan pemilik: semua butir daftar berhasil) -> FASE 6 SELESAI; `game/` = isi ZIP b11.**
  **BERIKUTNYA: sesi OPUS Fase 7 G0** (harga & isi katalog toko Crowns -> tabel di RENCANA_fase6_9 bagian 2.1; baca CLAUDE.md, HANDOFF 0 & 5, LOG teratas, RENCANA_fase6_9 bagian 0, 2, 8; ekonomi Crowns dari `profil_pemain.gd` `catat_akhir_match`/misi/login). Lalu G1-G5 Sonnet. Bug dari HP -> Opus dulu.
  **FASE 7 G0 SELESAI (Opus, 03-10):** tabel katalog & harga FINAL di RENCANA_fase6_9 bagian 2.1 (24 barang: 8 pawn, 10 title, 6 frame; 150-3500 Crowns; syarat Lv 5-15 untuk barang mahal; warna bidak = trim, warna badan tetap warna slot).
  (G1 sudah selesai, lihat di bawah.)
  **FASE 7 G1 SELESAI (Sonnet, 03-10; bukti `hasil/g7_kosmetik/`, rincian RENCANA_fase6_9 bagian 9):** `game/data_kosmetik.gd` (katalog 24 barang = tabel 2.1) + profil VERSI 4 (`kosmetik_dimiliki`/`kosmetik_dipakai`, `beli`/`pakai`/`alasan_tolak_beli`/`kosmetik_pakai`); `uji_kosmetik` 33/33, `uji_profil_v3` 0 gagal, `cek_muat_f3` 26/26. Tanpa perubahan jaringan. `game/` BERUBAH (+1 file baru `data_kosmetik.gd`, `profil_pemain.gd`) -> set resmi jadi 30 .gd di ZIP b12 (G5). Ingat: `class_name` baru -> `--import` ulang rig dulu.
  **FASE 7 G2 SELESAI (Sonnet, 03-10; bukti `hasil/g7_kosmetik/`):** `game/ui_toko.gd` (layar SHOP: tab Pawn/Title/Frame, BUY/EQUIP/EQUIPPED, alasan terkunci, pratinjau), tombol SHOP di panel PROFILE (menggantikan teks "unlock items soon") dan di menu utama (bawah MISSIONS); `uji_toko` 0 gagal, `cek_muat_f3` 27/27, tangkapan layar via xvfb+opengl3 (cara: `xvfb-run -a -s "-screen 0 1280x720x24" Godot --rendering-driver opengl3 --path rig/proj_tanpa_uji res://uji_toko_foto.tscn`). Set resmi `game/` kini 31 .gd (+`data_kosmetik`, `ui_toko`) di ZIP b12 (G5).
  **FASE 7 G3 SELESAI (Sonnet, 03-10; bukti `hasil/g7_tampil/`):** `kosmetik` {pawn,title,frame} masuk payload profil lobby (Dictionary yang sudah ada -> TANPA RPC baru, `VERSI_PROTOKOL` tetap 2; HP b11 tanpa field = AWAL); host validasi lewat `DataKosmetik.sah_semua` (-> `sah_untuk_jenis`: id tak dikenal/jenis salah/bukan string = AWAL). Trim bidak: cabang `else` di `_warnai_karakter(model, warna, id_pawn)` (`pemain_dasar.gd`; `_terapkan_trim`: albedo + emisi + logam/kasar); badan tetap warna slot. Bahan dinilai dari bahan ASLI mesh (bukan override) -- bug yang ditemukan lewat log MP: slot 3-4 menyalin musuh yang trim-nya sudah jenuh (Lava) -> salah dikira badan. Trim hanya untuk bahan putih/abu terang (s<0.2, v>0.3). Gelar: lobby (baris kecil di bawah nama), layar akhir/papan skor (`_gelar_manusia`), kartu profil. Bingkai: `UiProfil._gaya_bingkai` dipakai `tampilkan_kartu_profil`. Kartu sendiri memuat `ProfilPemain.kosmetik_pakai_semua()`. Bukti: `uji_kosmetik_tampil` 33/33 (headless), `cek_muat_f3` 27/27, MP Q1 1v1 + M2 4P migrasi host: 0 beda, 0 SCRIPT ERROR, log `KOSMETIK_UJI` identik di semua HP sebelum/sesudah migrasi (client3 sengaja kirim id rusak -> AWAL). **UPDATE (03-10, pemilik mengirim `beras.glb`): model asli = 3 bahan: badan merah, tangan putih (0.9), sepatu HITAM (0.02) -- bukan abu. Filter trim diubah jadi s<0.2 saja (v>0.3 melewatkan sepatu hitam); `uji_kosmetik_glb` (rig-only, aset `rig/proj_tanpa_uji/beras_asli_uji.glb`) 4/4: badan = warna slot, tangan+sepatu = trim, salinan slot 3-4 benar, classic = bahan asli. Peringatan lama di bawah SUDAH TERJAWAB (tinggal lihat tampilan di HP G5). (Peringatan lama:) model .glb ASLI tidak ada di repo (rig memakai stand-in `beras_uji.tscn`: badan merah + sepatu abu, TANPA sarung tangan). Bahwa sarung tangan putih + sepatu abu memang terwarnai di model asli BELUM terbukti di cloud (dasar: komentar lama di `_warnai_karakter`); cek di HP/editor di G5. Kalau ternyata tidak terwarnai/jelek -> Opus memutuskan (badan TIDAK diganti).
  **FASE 7 G4 SELESAI (Sonnet, 03-10; bukti `hasil/g7_pembelian/`, rincian RENCANA_fase6_9 bagian 9):** `game/pengelola_pembelian.gd` BARU (autoload `PengelolaPembelian`; plugin "GodotGooglePlayBilling" hanya lewat `Engine.has_singleton/get_singleton` -> tanpa plugin = MODE STUB, tidak pernah crash; produk `remove_ads`; query Play saat start = restore otomatis; pembelian BARU di-acknowledge; bonus 500 Crowns sekali per profil, hanya untuk pembelian baru bukan restore; cadangan di profil, Play = sumber kebenaran, refund mencabut, query gagal/offline tidak mencabut). `bebas_iklan` mematikan interstisial + app open (sudah ada di `pengelola_iklan.gd`) + BANNER (baru, 2 baris `tampilkan_banner`; iklan berhadiah tetap). `profil_pemain.gd`: `remove_ads`, `bonus_remove_ads_diambil` (bagian berkas "pembelian", VERSI tetap 4), `atur_remove_ads`, `ambil_bonus_remove_ads`.
  Rig-only: `pengelola_pembelian.gd` = STUB autoload (JANGAN disalin ke `game/`); `pembelian_asli_uji.gd` = salinan file ASLI (uji memastikan identik dgn `game/`); `uji_pembelian` 27/27 (mode stub, plugin TIRUAN: beli, ack, bonus sekali, restore, refund, offline, batal, pending, kode 7, putus); stub iklan +`bebas_iklan`/`jumlah_banner`; `uji_nyata.gd` opsi `bebas_iklan=1` (solo penuh 2 run: interstisial=0 banner=0, dibanding 1/1 tanpa opsi; 0 SCRIPT ERROR); `cek_muat_f3` 28/28 (+file asli), `uji_profil_v3`/`uji_kosmetik`/`uji_toko` 0 gagal. Tanpa jaringan/RPC. Regresi MP 37 tidak diulang (jatah G5).
  **YANG MASIH BELUM (dibawa ke G5 / pemilik):** (a) `game/` tidak punya `project.godot` -> PEMILIK harus mendaftarkan autoload `PengelolaPembelian="*res://pengelola_pembelian.gd"` (urutan bebas) + memasang plugin Play Billing (versi Godot 4.2+; nama singleton `GodotGooglePlayBilling`, diperiksa dari sumber plugin, BELUM diuji di HP). (b) BELUM ADA TOMBOL beli di UI (G4 hanya mesin): API siap -- `PengelolaPembelian.beli_remove_ads()`, sinyal `pembelian_selesai(berhasil, pesan)`, `harga_remove_ads()`, `punya_remove_ads()`, `restore()`; usulan: baris "REMOVE ADS $2.99 / Restore" di `ui_toko.gd` atau panel PROFILE (butuh keputusan pemilik; Sonnet bisa di G5). (c) uji pembelian nyata hanya bisa di HP (Internal testing + akun penguji lisensi).
  **FASE 7 G5 SELESAI (Sonnet, 03-10; bukti `hasil/g7_pembelian/`, daftar uji HP di RENCANA_fase6_9 bagian 9):** keputusan pemilik: banner ikut mati saat Remove Ads (dipertahankan) + tombol di UI (dibuat). `ui_toko.gd`: baris "REMOVE ADS" di bawah daftar (tombol BUY <harga Play> + RESTORE; setelah punya: "Ads removed. Thank you!"), memakai `PengelolaPembelian` LEWAT POHON (`root.get_node_or_null`) -> kalau autoload belum didaftarkan toko tetap terbuka tanpa baris itu; status berubah (restore/refund) menggambar ulang panel; tinggi daftar 330 -> 260 agar muat 720p (tangkapan `toko_pawn_g5.png`/`toko_frame_g5.png`). Uji rig `uji_toko_iklan` 9/9 (stub rig, pengelola ASLI + plugin tiruan: harga, beli, bonus, refund saat panel terbuka, tanpa autoload), `uji_toko` 0 gagal, `cek_nilai` 8/8 (`cek_nilai.txt`), `cek_muat_f3` 28/28.
  **Regresi MP 37 skenario (K8, SEKALI): 37 skenario, 99 baris SELESAI, 0 MACET / scripterr / beda / cek_gagal** (`hasil/g7_pembelian/mp/`; pembanding G8 97 -- +2 di f2_d4 & f2_m5 = skenario "host keluar saat pilih elemen", variasi timing seperti D1). Bersih-bersih: 0 print/TODO, `UJI_*` false, `game/` identik dgn rig kecuali `pengelola_iklan.gd` & `pengelola_pembelian.gd` (stub rig, sengaja).
  **`kiriman/TileDuel_Fase7_b12.zip` = 33 .gd** (29 resmi b11 + `data_kosmetik`, `ui_toko`, `pengelola_pembelian`, + `pengelola_iklan.gd` yang BERUBAH [banner] -- JANGAN lewatkan; 6 file T21 lain tidak berubah). Beda dari b11: layar_local_play, main_menu, pemain, pemain_dasar, profil_pemain, ui_dinamis, ui_profil + 4 file baru/di atas. Diverifikasi byte-per-byte dgn `game/`.
  **BERIKUTNYA (pemilik): (1) TIMPA ke-33 file, (2) daftarkan autoload `PengelolaPembelian="*res://pengelola_pembelian.gd"` di Project Settings > Autoload, (3) pasang plugin Godot Google Play Billing (singleton `GodotGooglePlayBilling`, Godot 4.2+; aktifkan di export Android), produk non-consumable `remove_ads` di Play Console + akun penguji lisensi, (4) impor, uji HP b12 (daftar di RENCANA_fase6_9 bagian 9), (5) rilis. Setelah itu Fase 8 (Opus G0/Sonnet) per RENCANA_fase6_9 bagian 3.** `game/` = isi ZIP b12; jangan ubah kecuali bug. Bug dari HP -> Opus dulu.
- **RENCANA FASE 6-9 DISETUJUI (Opus, 02-10): `docs/RENCANA_fase6_9.md`** -- pemilik "setuju semua a" (K1-K15). Tujuan: retensi.
  F6 identitas MP ringan (nama/level, MVP, Respect, penjaga versi) -> F7 toko Crowns + Remove Ads (regresi MP 37 SEKALI di F7 G5)
  -> F8 event mingguan offline + mastery -> F9 misi/taruhan Tebak Duel + penutup. Kredit ~US$25, perkiraan ~23.5 (urutan pangkas: bagian 6).
  **BERIKUTNYA: sesi SONNET Fase 6 G0+G1** -- baca CLAUDE.md, HANDOFF 0 & 5, LOG teratas, RENCANA_fase6_9 bagian 0, 1, 6, 7 saja.
  Pemilik (paralel): rilis A+B+Fase 5; siapkan plugin Play Billing & produk `remove_ads` sebelum Fase 7 G4.
- Opsional (Sonnet, tidak menghalangi rilis): T22 (rig-only, D1 lebih kuat, RENCANA 14.23); komentar F5 untuk
  `hot_flames`/`fire_tax`/`strong_wind` di `data_role.gd` (komentar saja; ikut kiriman berikutnya).
- Cara regresi MP di sesi cloud: salin `rig/skrip/jalankan_mp3.sh`, `uji_f2_t2_a/b.sh` ke scratchpad, ganti path
  (`SP`, `G=/opt/godot/...`, `PROJ=rig/proj_tanpa_uji`); jalankan A lalu B BERURUTAN (~1 jam total di 4 inti).

## 6. Konteks pengguna
Akun Claude Pro berakhir pekan ini; pengguna mungkin lanjut dengan akun Free + kredit sesi cloud (khusus Claude Code cloud, via browser).
Hemat token: jangan baca ulang RENCANA penuh (~2000 baris) -- baca 14.19 dan bagian STATUS di bawah; jalankan rig di background lalu `sleep` panjang.
