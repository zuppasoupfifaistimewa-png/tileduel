# RENCANA FASE 3: Rapikan pemain.gd (dipecah tanpa mengubah perilaku)

Disusun Opus, 25-09. STATUS: SELESAI & DIKIRIM 25-09 (K1-K3 disetujui, K4 = a: dikerjakan setelah uji HP
Fase 1+2 lolos). Hasil pengerjaan (Sonnet/Opus, pemain.gd set Fase 2 tanpa tambalan HP): cek_pindah LOLOS
(458 potongan, 5.437 baris = 5.437 baris), cek_nama_ganda LOLOS (271 fungsi, 6 @abstract), warning 0 di 22
file, jejak simulasi 108/108 identik, adegan asli tanpa iklan 12/12 identik, adegan + iklan & profil
PROFIL_CEK OK (10 run sampai layar akhir, 2 berhenti di batas giliran), multiplayer 37 skenario: 0 macet,
0 error, 0 beda, AKHIR sama di semua HP, PROFIL_MP 62/62 OK, iklan tiruan FREE CARD 8/8 + DOUBLE/EXIT 4/4,
editor headless tanpa error. Menunggu uji HP user (bagian 6).

ATURAN USER yang tetap berlaku: balas dalam Bahasa Indonesia; teks untuk pemain = bahasa Inggris sederhana;
saklar UJI_DUEL, UJI_SERI, UJI_SELALU_PEDANG WAJIB false di file produksi; kirim SET LENGKAP terbaru dalam
SATU pesan dan minta unduhan lama dibuang; edit hanya bagian yang relevan (jangan tulis ulang file).
Tentang aturan terakhir: Fase 3 adalah satu-satunya saat pemain.gd sengaja dipotong besar-besaran (sesuai
peta jalan). Tidak ada baris yang diketik ulang: alat memotong-tempel, lalu `cek_pindah.py` membuktikan
setiap fungsi di file baru sama PERSIS huruf demi huruf dengan aslinya. Sesudah Fase 3 aturan biasa berlaku.

## 0. Ringkas

pemain.gd sekarang 6.141 baris (271 fungsi, 58 di antaranya fungsi RPC multiplayer, 187 variabel/konstanta/
sinyal). Dipecah jadi 7 file yang dinamai menurut bagian permainan:

| File | Isi | Baris | Fungsi (RPC) |
|---|---|---|---|
| `pemain_dasar.gd` | variabel bersama, saklar UJI, pembantu slot 2-4 pemain, teks sudut pandang, narasi, statistik | 624 | 41 (1) |
| `pemain_tampilan.gd` | HUD uang/bintang, label petak & ronde, menara, posisi karakter, pemanasan shader | 552 | 15 (0) |
| `pemain_papan.gd` | beli, bangun, jebakan (pasang & efek), serangan jarak jauh, jual aset & hutang, denda, koin tercecer, permata, Start | 1.249 | 67 (21) |
| `pemain_kartu.gd` | petak kartu, Use Card, kartu pedang saat menyerang, kartu hadiah iklan | 587 | 29 (12) |
| `pemain_duel.gd` | pilih elemen, naskah & tayangan duel, lempar koin penentu seri, hasil duel | 598 | 31 (8) |
| `pemain_jaringan.gd` | susunan slot, siaran state, langkah di client, pemain keluar, AI ambil alih, migrasi host | 1.145 | 52 (9) |
| `pemain.gd` | alur: `_ready`/`_process`/kamera/input, mulai peta, HOW TO WIN, lempar dadu, melangkah & cabang, menu aksi, ganti giliran, akhir permainan, Quick Match, hadiah profil | 1.486 | 36 (7) |

Total 6.241 baris (+100 baris kepala file & keterangan). File terbesar turun dari 6.141 ke 1.486 baris.
Adegan (.tscn), autoload, dan Project Settings TIDAK berubah; file lain (ui_dinamis.gd, ai_musuh.gd, dst.)
juga tidak berubah.

## 1. Keputusan (perlu persetujuan user)

K1. Cara memecah: BERTINGKAT (disarankan).
    Tiap file meneruskan file sebelumnya (`extends`), jadi ketujuhnya tetap SATU node Pemain -- ibarat satu
    buku yang dijilid per bab. Variabel dan fungsi dari file lain dipakai langsung seperti sekarang, jadi
    ISI FUNGSI TIDAK PERLU DIUBAH SAMA SEKALI. Rantainya:
    `pemain_dasar.gd -> pemain_tampilan.gd -> pemain_papan.gd -> pemain_kartu.gd -> pemain_duel.gd ->
    pemain_jaringan.gd -> pemain.gd` (adegan tetap memasang `pemain.gd`).
    Alternatif yang TIDAK disarankan: modul static seperti ui_dinamis.gd / audio_grafis.gd (dulu dipakai
    untuk bagian yang mudah dilepas). Untuk sisa kode ini hampir setiap baris harus diubah jadi
    `main_node.xxx`, dan 58 fungsi RPC wajib tetap tinggal di node -- pemain.gd tetap besar, risiko salah
    ketik tinggi.
K2. Tujuh file di atas, dengan nama & isi seperti tabel. Nama boleh diganti; jumlah boleh diubah
    (gabung/pisah) -- cukup ubah peta `peta_fungsi.json`, alat membuat ulang semuanya.
K3. Fase 3 tidak mengubah SATU huruf pun di dalam fungsi dan komentar. Akibatnya: (a) beberapa komentar judul
    bagian ikut pindah bersama baris pertama di bawahnya, jadi ada judul yang "terbelah" (mis. judul
    PANEL SYARAT MENANG ikut ke pemain.gd, variabelnya di file lain); (b) komentar lama seperti
    "# ---> TAMBAHKAN BARIS INI <---" tetap ada. Merapikan komentar = pekerjaan kecil terpisah nanti (opsional).
K4. Kapan kodenya dibuat:
    (a) DISARANKAN: setelah uji HP Fase 1 + Fase 2 lolos. Kalau uji HP menemukan bug, tambalannya masuk dulu
        ke pemain.gd utuh, lalu alat dijalankan pada versi terbaru (± 2-3 jam termasuk uji rig). Asal
        masalah di HP tetap jelas (Fase 1/2, bukan Fase 3).
    (b) Sekarang juga, lalu uji HP sekali untuk Fase 1+2+3. Lebih cepat, tapi kalau ada masalah di HP,
        penelusurannya melewati kode yang sudah dipecah.

Keputusan teknis Opus (tidak perlu persetujuan):
- Variabel/konstanta PUBLIK (tanpa awalan `_`, termasuk `@onready` & `@export`) -> `pemain_dasar.gd`, urutan
  asli. Variabel PRIVAT (`_nama`) dan SINYAL -> file TERENDAH yang memakainya. Alasannya aturan peringatan
  Godot: variabel privat/sinyal yang dideklarasikan di satu file tapi hanya dipakai file lain memunculkan
  warning "declared but never used" (dicoba, bagian 3).
- Konstanta yang dulu ada di tengah file (`PATH_SCRIPT_JEBAKAN`, `OFFSET_BERBAGI_PETAK`) ikut bagiannya.
- Fungsi bawaan mesin (`_ready`, `_process`, `_unhandled_input`) hanya di pemain.gd.
- Fungsi di file bawah yang memanggil fungsi di file atas butuh DEKLARASI di pemain_dasar.gd:
  `@abstract func nama(...)` (tanda tangan disalin persis). Susunan file dipilih supaya hanya 6 yang perlu:
  `periksa_status_petak`, `ganti_giliran`, `cek_game_over`, `_proses_tombol_tutup` (isinya di pemain.gd),
  `_mulai_duel` (pemain_duel.gd), `_jalankan_ai_di_tengah_giliran` (pemain_jaringan.gd). Tidak ada
  pemanggilan `await` ke file yang lebih tinggi (kalau ada, Godot memberi warning "redundant await").
- Semua file kecuali pemain.gd bertanda `@abstract` (= bagian dari pemain.gd, tidak dipasang sendiri).
  Butuh Godot 4.5 ke atas; proyek memakai 4.7.1.
- Saklar `UJI_DUEL` & `UJI_SERI` pindah ke `pemain_dasar.gd` (isinya tetap false). `UJI_SELALU_PEDANG` tetap
  di petak_kartu.gd.

## 2. Kenapa aman (dicoba di Godot 4.7.1, proyek percobaan kecil + rig)

- Fungsi RPC di file mana pun dalam rantai tetap bekerja: host->client dan client->host dicoba untuk RPC di
  file dasar, tengah, dan atas. Nama & jalur node RPC tidak berubah.
- File lain yang memanggil `main_node.xxx` / `p.xxx` (ui_dinamis.gd, ai_musuh.gd, jebakan_*.gd, robot uji)
  tetap jalan karena semua anggota tetap milik node yang sama.
- Skrip robot uji yang meneruskan pemain.gd (uji_sim_pemain.gd, uji_nyata_pemain.gd, uji_mp_pemain.gd) dan
  menimpa fungsi (mis. `lempar_dadu`) tetap bekerja walau fungsinya kini di file lain.
- `@onready`, `@export` (material_pemain/musuh dari adegan), sinyal, `await`, `Callable` ke fungsi file atas:
  dicoba, bekerja.
- FPS: memanggil fungsi yang letaknya 6 tingkat di bawah = ±0,01 mikrodetik lebih lama per panggilan
  (1 juta panggilan: ±95 ms vs ±106 ms, sebagian besar derau pengukuran). Tidak terasa.
- Yang TIDAK boleh: dua fungsi bernama sama di dua file -- yang di atas diam-diam menimpa yang di bawah.
  Dicegah `cek_nama_ganda.py` (bagian 5).

## 3. Hasil percobaan penuh di rig (25-09, pemain.gd versi set Fase 2)

Alat: `f3/pecah_pemain.py` + `f3/peta_fungsi.json` di scratchpad rig. Hasilnya dipasang ke salinan rig
`proj_f3` (UJI nyala) & `proj_f3_tanpa_uji` (UJI mati), dibandingkan dengan pemain.gd utuh:
- cek_pindah: LOLOS -- (1) 458 potongan (271 fungsi + 187 deklarasi, beserta komentarnya) masing-masing ada
  PERSIS di tepat satu file, tidak ada baris tambahan selain kepala file & 6 deklarasi; (2) cek kedua yang
  tidak memakai pemotong yang sama: 5.437 baris berisi di file lama = 5.437 baris di 7 file baru (di luar
  kepala & deklarasi). Dicoba juga dengan satu teks yang sengaja diubah: langsung tertangkap.
- cek_nama_ganda: LOLOS (271 fungsi, 6 deklarasi @abstract, 0 ganda).
- Warning GDScript (--debug): 0 di 22 file produksi; semua file termuat.
- Jejak simulasi: 108/108 IDENTIK (36 Classic UJI nyala + 36 Classic UJI mati + 36 Quick; 2-4 pemain x 0-1
  manusia x 6 benih), 0 script error, statistik Fase 2 cocok 108/108.
- Adegan asli (main menu -> peta -> sampai menang), TANPA klik iklan: 12/12 jejak IDENTIK (Quick/Classic x
  1-3 AI x 2 peta).
- Adegan asli DENGAN iklan & profil: PROFIL_CEK OK. Jejaknya tidak dibandingkan: hadiah FREE CARD memang acak
  (pengacak sendiri, `randomize()`), jadi dua kali main dengan kode yang sama pun bisa berbeda.
- Multiplayer (Q3 3P Quick, M2 migrasi host 4P, D1 client keluar saat pilih elemen, Q4n 4P pantai UJI mati):
  0 script error, 0 macet, baris AKHIR sama di semua HP, hadiah profil tiap HP benar & tercatat sekali 12/12.
  Catatan: multiplayer tidak deterministik -- kode yang sama diulang pun hasil akhirnya berbeda (dicoba: Q4n),
  jadi ukurannya "sama di semua HP & tanpa error", bukan "sama dengan sebelum".
- Iklan tiruan editor (FREE CARD + panel HOW TO WIN, klik sungguhan, layer 100 & 1000): 8/8 OK.
- Editor Godot (headless) membuka proyek hasil pecahan tanpa error.
- Tinjauan terpisah (agen lain, tidak ikut membuat): 0 penghalang. Cek identifier sendiri (termasuk `self.`,
  `%`, lambda): tidak ada file bawah yang memakai anggota yang hanya ada di file atas. Rantai `@abstract`
  diekspor jadi .pck (skrip biner) dan dijalankan: panggilan abstrak dengan argumen bawaan, `await` ke fungsi
  abstrak `-> void` (benar-benar menunggu), static warisan, RPC di file dasar -- semuanya jalan (Linux; Android
  memuat skrip dengan cara yang sama).
- Celah yang diketahui: robot multiplayer rig (uji_mp_pemain.gd) menimpa `periksa_status_petak` tanpa `super`,
  jadi versi aslinya tidak pernah dijalankan lewat jaringan di rig -- ditutup oleh uji HP (bagian 6, butir 5).

## 4. Langkah pengerjaan (Sonnet; urutan wajib)

L0. Pembanding: jalankan `sinkron_uji.sh` & `sinkron_tanpa_uji.sh` versi LAMA dulu (rig = kode utuh
    terbaru, termasuk tambalan uji HP), lalu salin -> `proj_sebelum_fase3` & `proj_sebelum_fase3_tanpa_uji`.
    Simpan `cp /home/claude/pemain.gd f3/pemain_utuh.gd`. Hapus folder percobaan `proj_f3`,
    `proj_f3_tanpa_uji`, `proj_mock_editor_f3` supaya tidak ada skrip yang diam-diam memakainya.
L1. `python3 f3/pecah_pemain.py f3/pemain_utuh.gd f3/keluar`. Alat berhenti kalau: ada fungsi baru yang belum
    punya tujuan (tambalan uji HP) -> tambahkan ke `f3/peta_fungsi.json` menurut topiknya (bagian 0 /
    Lampiran A); ada deklarasi `@abstract` BARU selain 6 yang dikenal, `await` ke file lebih tinggi, atau
    bentuk tingkat atas yang tidak dikenal (enum, class, tanda tangan fungsi 2 baris) -> Opus yang memutuskan.
L2. `python3 f3/cek_pindah.py f3/pemain_utuh.gd f3/keluar` dan `python3 f3/cek_nama_ganda.py f3/keluar` ->
    keduanya LOLOS, tepat 6 deklarasi @abstract. DILARANG mengedit file hasil dengan tangan (kalau perlu
    beda, ubah peta/alatnya lalu jalankan ulang).
L3. Pasang ke produksi DULU: salin 7 file dari f3/keluar ke /home/claude (pemain.gd diganti versi pecahan).
    Baru sesudah itu perbarui `sinkron_uji.sh` & `sinkron_tanpa_uji.sh` (daftar file + 6 file baru; `sed`
    saklar UJI kini ke `pemain_dasar.gd`; `diff` untuk ketujuhnya) dan jalankan -- urutan ini penting:
    skrip sinkron menyalin dari /home/claude, jadi kalau dijalankan sebelum langkah ini, pemain.gd UTUH
    menimpa versi pecahan di rig dan semua uji "lolos" tanpa menguji apa pun. Salin juga ke proj_mock_editor
    (proj_iklan tidak memuat pemain.gd). Cek: `head -1 proj/pemain.gd` harus
    `extends "res://pemain_jaringan.gd"` (skrip uji f3 memeriksanya sendiri dan berhenti kalau salah).
    Kalau uji gagal dan harus mundur: pulihkan /home/claude/pemain.gd dari f3/pemain_utuh.gd, hapus 6 file baru.
L4. Uji (bagian 5). Kalau ada yang gagal: JANGAN menambal file hasil -- cari sebabnya (Opus).
L5. Periksa ulang: saklar UJI false di pemain_dasar.gd & petak_kartu.gd; `ID_INTERSTISIAL_ASLI` masih kosong
    (keputusan user, isi sebelum rilis); 0 print baru.
L6. Kirim SET LENGKAP dalam SATU pesan dan minta unduhan lama dibuang -- 22 file kode, sebut namanya satu per
    satu (jangan "semua .gd": /home/claude berisi file lain yang tidak dikirim):
    pemain.gd, pemain_dasar.gd, pemain_tampilan.gd, pemain_papan.gd, pemain_kartu.gd, pemain_duel.gd,
    pemain_jaringan.gd, ai_musuh.gd, petak_kartu.gd, ui_elemen.gd, ui_dinamis.gd, ui_petak.gd, main_menu.gd,
    layar_local_play.gd, status_jaringan.gd, data_pemain.gd, jebakan_air.gd, jebakan_api.gd, migrasi_host.gd,
    pengelola_iklan.gd, profil_pemain.gd, ui_profil.gd
    + RENCANA_fase1_iklan_quick.md, RENCANA_fase2_profil_meta.md, RENCANA_fase3_rapikan_pemain.md (bukan
    RENCANA_fase2_profil.md -- itu draf lama). Tulis STATUS di rencana ini; tandai Fase 3 di dokumen desain.

## 5. Uji (rig) -- syarat lolos

Skrip uji f3 memakai pasangan LAMA (utuh) / BARU (pecahan) dengan bawaan proj_sebelum_fase3* vs proj*, dan
berhenti sendiri kalau BARU ternyata bukan versi pecahan atau LAMA bukan versi utuh. (Di percobaan dipakai
`LAMA=proj BARU=proj_f3 LAMA_N=proj_tanpa_uji BARU_N=proj_f3_tanpa_uji`.)
U1. cek_pindah LOLOS (dua cek) & cek_nama_ganda LOLOS, tepat 6 deklarasi @abstract.
U2. Warning GDScript 0 di semua file produksi (`f3/cek_peringatan_f3.sh`, bawaan proj_tanpa_uji).
U3. Jejak simulasi IDENTIK dengan pembanding: 108/108 (`f3/uji_f3_t1.sh`, benih 7-12).
U4. Adegan asli tanpa iklan: 12/12 jejak IDENTIK (`f3/uji_f3_t5.sh`).
U5. Adegan asli dengan iklan & profil (`uji_f2_t4.sh`, 12 run, proj_tanpa_uji berisi file pecahan):
    PROFIL_CEK OK di semua run yang sampai layar akhir.
U6. Regresi multiplayer 37 skenario (`uji_f2_t2_a.sh` + `uji_f2_t2_b.sh`, dua network namespace):
    0 MACET, scripterr 0, beda 0, cek_gagal 0, baris AKHIR sama di semua HP, PROFIL_MP semua OK.
U7. Iklan tiruan editor: FREE CARD 8/8 (`f3/uji_f3_mock.sh`) + DOUBLE/EXIT 4/4 (`uji_f2_t8.sh`).
U8. Editor headless membuka proyek tanpa error.
U9 (opsional). Ekspor rig jadi .pck (`--export-pack`, skrip biner) dan jalankan satu simulasi dari .pck.
Tidak perlu foto ulang: tidak ada tampilan yang berubah.

## 6. Yang user lakukan saat menerima set Fase 3

1. Tutup Godot.
2. Simpan salinan pemain.gd lama DI LUAR folder proyek (untuk jaga-jaga).
3. Salin 22 file ke folder proyek (6 file baru di folder yang sama dengan pemain.gd).
4. Buka Godot, tunggu impor selesai, jalankan. Tidak ada adegan/autoload/Project Settings yang diubah.
5. Uji HP singkat: satu Quick & satu Classic solo sampai layar akhir; satu multiplayer (HP + laptop) yang
   memuat: aksi dari device client (beli/bangun/jebakan), Use Card, duel, lalu satu device keluar supaya AI
   mengambil alih; FPS terasa sama; Debugger editor tanpa error/warning.
Cara kembali: pulihkan pemain.gd lama, hapus 6 file baru beserta file `.gd.uid`-nya yang dibuat editor.
Mencari fungsi: Ctrl+Shift+F (Find in Files) di editor, atau Ctrl+klik nama fungsi untuk melompat ke filenya.

## 7. Aturan sesudah Fase 3 (untuk user & sesi berikutnya)

1. Mau mengubah sesuatu -> buka file topiknya (tabel bagian 0). Fungsi baru ditaruh di file topiknya.
2. `_ready`, `_process`, `_input`, `_unhandled_input`, `_notification` hanya di pemain.gd.
3. Nama fungsi tidak boleh kembar di dua file (jalankan `cek_nama_ganda.py` sesudah menambah fungsi).
4. Fungsi di file BAWAH butuh fungsi di file ATAS -> Godot menolak dengan pesan
   `Function "x()" not found in base self`. Pilihan: pindahkan fungsinya ke bawah (lebih baik), atau tambahkan
   `@abstract func x(...)` (tanda tangan persis) di bagian deklarasi pemain_dasar.gd. Kalau pemanggilannya
   pakai `await`, beri `@warning_ignore("redundant_await")` tepat di atas baris itu.
5. Variabel publik baru -> pemain_dasar.gd. Variabel privat (`_x`) & sinyal baru -> file terendah yang
   memakainya (kalau tidak: warning "declared but never used"). Kalau file yang LEBIH RENDAH kemudian ikut
   memakai variabel privat/sinyal yang sudah ada di file atas, pindahkan deklarasinya (beserta komentarnya)
   ke file rendah itu -- kalau tidak, Godot menolak ("not declared in the current scope").
6. Saklar uji: `UJI_DUEL`/`UJI_SERI` di pemain_dasar.gd, `UJI_SELALU_PEDANG` di petak_kartu.gd -- false saat rilis.
7. File bertanda `@abstract` jangan dipasang langsung ke node.
8. Fase 4 (Role & skill tree) boleh menambah file baru ke rantai (mis. `pemain_role.gd` di antara
   pemain_duel.gd dan pemain_jaringan.gd). Yang harus ikut diubah: file baru bertanda `@abstract` dan
   `extends` file sebelumnya; baris `extends` file sesudahnya; daftar file di `cek_nama_ganda.py`, `URUTAN`
   di `pecah_pemain.py`, `DAFTAR` di `cek_muat_f3.gd`, skrip sinkron rig, dan jumlah file di set kiriman.

## 8. Arahan model

- Rencana ini: Opus (sudah).
- Pengerjaan L0-L6: Sonnet -- mekanis (jalankan alat + uji), alat & peta sudah teruji.
- Pindah ke Opus kalau: cek_pindah/cek_nama_ganda gagal tanpa sebab jelas; Godot memberi error seputar
  `@abstract`/`extends`; jejak U3/U4 tidak identik; multiplayer macet atau beda antar-HP; atau fungsi baru
  dari tambalan uji HP tidak jelas masuk file mana.

## Lampiran A. Fungsi per file (urutan asli; * = RPC)

pemain_dasar.gd (41): _array_teks, jumlah_pemain, _slot_dari_aktor, _aktor_dari_slot, _slot_berikutnya,
_node_karakter, _model, _anim, _model_aktor, _slot_dari_model, _warna_slot, _material_slot, _nama_slot,
_subjek, _nama_ui, _aktor_ui_kartu, _is_ai, _siapkan_slot_pemain, _teks_hasil_dadu, _teks_dadu_habis,
_teks_terbakar, _teks_lumpuh, _teks_denda, _teks_rebut, _teks_petak_lawan, _peer_slot, _peer_client_aktif,
_rpc_ke_klien_kecuali, _slot_dari_peer, _teks_gaji_gagal, _tunggu_langkah_ke_petak, _antrian_berisi_petak,
_teruskan_aksi_ke_host, _umumkan, rpc_umumkan*, _teks_narasi, _reset_statistik, _tambah_stat,
_tambah_stat_elemen, _warnai_karakter, _teks_kartu_dadu

pemain_tampilan.gd (15): _pemanasan_shader, _pemanasan_permata, _pemanasan_jebakan_api,
_jalankan_auto_detect_pertama, _munculkan_teks_paralysis, _bangun_fisik_menara, update_semua_label_petak,
_atur_posisi_label_ronde, _perbarui_label_ronde, update_ui_status, _render_uang_tampil,
_render_hud_banyak_pemain, atur_posisi_berbagi_petak, atur_visibilitas_fps, _munculkan_teks_kerugian

pemain_papan.gd (67): _atur_berhenti_petak, _catat_berhenti_di_petak, _on_tombol_tanah_pressed,
_on_tombol_trap_tanah_pressed, _on_tombol_petir_pressed, _on_tombol_set_trap_pressed,
_on_tombol_trap_batal_pressed, _kumpulkan_data_jebakan, _terapkan_data_jebakan, _teks_jebakan_dipasang,
_siarkan_jebakan_dipasang, rpc_jebakan_dipasang*, _kumpulkan_data_koin, _buat_koin_tercecer,
_terapkan_data_koin, _siarkan_koin_tercecer, rpc_koin_tercecer*, rpc_koin_diambil*, _siarkan_permata_diambil,
rpc_permata_diambil*, _siarkan_lewat_start, rpc_lewat_start*, _siarkan_gaji_gagal, rpc_gaji_gagal*,
rpc_mainkan_efek_jebakan*, rpc_mainkan_efek_sisa_paralisis*, rpc_jebakan_air_aktif*, _on_tombol_beli_pressed,
_on_tombol_bangun_pressed, _on_tombol_serang_pressed, _on_tombol_air_pressed, _on_tombol_angin_pressed,
_on_tombol_api_pressed, _on_tombol_trap_petir_pressed, tembak_raycast_ke_petak, _serang_petak,
rpc_minta_serang*, _jual_petak, rpc_minta_jual*, eksekusi_jual_aset, _teks_hasil_jual, _teks_lanjut_jual,
rpc_teks_bangkrut*, rpc_minta_jual_aset*, rpc_efek_jual*, rpc_jual_selesai*, eksekusi_serangan,
_teks_serangan_mulai, _teks_hasil_serangan, rpc_efek_serangan*, rpc_hasil_serangan*, reset_petak_ke_netral,
_tawarkan_iklan_hutang, _bayar_denda, bayar_denda_ke_musuh, bayar_denda_ke_pemain, sita_aset_untuk_hutang,
_ai_jual_sampai_lunas, _ambil_permata_setelah_paralisis, _siarkan_pesan_denda, rpc_pesan_denda*,
_siarkan_jebakan_tanah_aktif, rpc_jebakan_tanah_aktif*, _siarkan_kondisi_petak, rpc_kondisi_petak*,
_siarkan_teks_kerugian, rpc_teks_kerugian*

pemain_kartu.gd (29): _tonton_iklan_kartu_awal, _kartu_hadiah_acak, _terapkan_efek_kartu,
_ambil_kartu_setelah_paralisis, _mode_kartu, _hubungkan_sinyal_kartu, _mulai_petak_kartu_jaringan,
_buang_kartu_sinkron, _saat_kartu_gacha_diklik, _saat_kartu_buang_diklik, rpc_kartu_mulai*,
rpc_kartu_dipilih_client*, rpc_kartu_dibuka_host*, rpc_buang_kartu_mulai*, rpc_kartu_dibuang_client*,
rpc_kartu_dibuang_host*, _pilih_pedang_ai_terlihat, _pilih_pedang_penyerang, rpc_minta_pilih_pedang*,
rpc_jawab_pilih_pedang*, rpc_lawan_memilih_pedang*, rpc_pedang_dipilih_host*, _on_tombol_gunakan_kartu_pressed,
_nama_layar, _putar_animasi_pakai_kartu, rpc_animasi_pakai_kartu*, _eksekusi_kartu_simpan, _minta_pakai_kartu,
rpc_minta_pakai_kartu*

pemain_duel.gd (31): _mulai_duel, _sisi_p_duel, _atur_nama_duel, _jalankan_duel, _naskah_lokal,
_tonton_ai_pilih_elemen, _naskah_duel_ai, _lengkapi_koin_naskah, _ai_kunci_elemen_tertunda,
_kumpulkan_naskah_duel, _kunci_elemen_peserta, _siarkan_segel_terkunci, rpc_segel_terkunci*,
_tampilkan_segel_terkunci, _siapkan_pilihan_elemen_lokal, _tunggu_klik_elemen_lokal,
_tunggu_pilihan_elemen_lokal, rpc_duel_dimulai*, rpc_minta_pilihan_elemen_duel*,
rpc_kirim_pilihan_elemen_duel*, rpc_mulai_replay_duel*, _saat_koin_seri_lokal_dipilih,
rpc_kirim_pilihan_koin_seri*, _terima_pilihan_koin, rpc_pilihan_koin_seri_lawan*, _undi_koin_seri_jika_lengkap,
rpc_hasil_koin_seri*, eksekusi_dadu_pertarungan, _hasil_duel_petak, hasil_akhir_pertarungan_pemain,
hasil_akhir_pertarungan_musuh

pemain_jaringan.gd (52): _susun_slot_jaringan, _siapkan_indikator_jaringan, _saat_peer_jaringan_disconnect,
_bebaskan_penantian_jaringan, _bebaskan_penantian_slot, _ambil_alih_slot_ai, _jalankan_ai_di_tengah_giliran,
rpc_slot_jadi_ai*, lanjutkan_dengan_ai, _ambil_alih_sebagai_client, _selesaikan_replay_lokal,
_lanjutkan_dari_state_terakhir, _tutup_ui_jaringan_client, _periksa_kesiapan_klien, _catat_ip_sesi_host,
_putuskan_setelah_jeda, _masuk_mode_jaringan_putus, _jawab_penantian_selama_putus, _perlu_migrasi_client,
_mulai_migrasi_client, _saat_putus_selama_migrasi, _kembali_mencari, _saat_host_baru_ditemukan,
_saat_tersambung_host_baru, _saat_gagal_sambung_host_baru, rpc_minta_gabung_ulang*, rpc_gabung_ulang_diterima*,
rpc_gabung_ulang_ditolak*, _saat_harus_mengalah, _reset_penantian_host, _tekan_tombol_utama_migrasi,
jadi_host_baru, tunggu_pemain_kembali, mulai_sekarang_migrasi, _lanjutkan_setelah_pemain_kembali,
_teks_setelah_migrasi, rpc_lanjut_setelah_migrasi*, lanjut_sendiri_dari_migrasi, _buka_panel_migrasi,
_tutup_panel_migrasi, _segarkan_panel_migrasi, _siarkan_state_giliran, rpc_mainkan_rolet*, rpc_langkah_client*,
_proses_antrian_langkah, _langkah_satu_petak, _selaraskan_efek_menempel, _bangun_ulang_menara_client,
rpc_terima_state_giliran*, _sembunyikan_menu_giliran_lawan, rpc_minta_aksi*, _siarkan_state_ai

pemain.gd (36): _ready, _process, _mulai_transisi_game, _baris_syarat_menang, _teks_syarat_permata,
_tunggu_kesiapan_mulai, _tunggu_penanda, rpc_client_siap_mulai*, rpc_mulai_permainan*, _unhandled_input,
_boleh_geser_kamera, lempar_dadu, bergerak_maju, _akhiri_permainan, _susun_papan_skor,
_tampilkan_akhir_permainan, rpc_permainan_selesai*, periksa_status_petak, _pilih_arah_cabang,
rpc_minta_pilih_cabang*, rpc_jawab_pilih_cabang*, rpc_lawan_memilih_cabang*, rpc_cabang_dipilih*,
_on_tombol_tutup_pressed, _proses_tombol_tutup, ganti_giliran, _mulai_giliran, cek_game_over,
_atur_kecepatan_permainan, _jumlah_petak_slot, _kekayaan_slot, _pemenang_kekayaan, _akhiri_karena_ronde_habis,
_proses_hadiah_akhir, _data_akhir_profil, _siapkan_peta_dan_mulai

## Lampiran B. Variabel privat & sinyal di luar pemain_dasar.gd (125 deklarasi lain di pemain_dasar.gd)

- pemain_tampilan.gd: _penjaga_shader, _ronde_spanduk, OFFSET_BERBAGI_PETAK
- pemain_papan.gd: _replay_duel_berjalan, replay_duel_selesai, _replay_jebakan_air_berjalan,
  replay_jebakan_air_selesai, _sedang_proses_langkah, _koin_menunggu_diambil, _replay_paralisis_berjalan,
  replay_paralisis_selesai, _replay_serangan_berjalan, replay_serangan_selesai, _versi_state,
  _menunggu_aksi_slot, _iklan_hutang_terpakai, PATH_SCRIPT_JEBAKAN
- pemain_kartu.gd: _sistem_kartu_aktif, _slot_aktor_kartu, _kartu_menunggu_jaringan, _slot_penyerang_pedang,
  _jawaban_pedang_client, pedang_client_dijawab, _ui_pedang_tonton_aktif
- pemain_duel.gd: _pilihan_elemen_jaringan, elemen_jaringan_diterima, _duel_slot_penyerang, _duel_slot_pembela,
  _koin_seri_pilihan, _koin_seri_wajib, _duel_mengumpulkan, _nomor_duel, _generasi_jaringan
- pemain_jaringan.gd: _permainan_selesai, _panel_putus_terbuka, _client_siap_mulai, _klien_siap,
  _host_mulai_permainan, _alasan_akhir, _slot_pemenang_akhir, _papan_skor_akhir, _akhir_diterima,
  _peran_migrasi, _slot_host_lama, _slot_host_migrasi, _panel_migrasi, _nomor_gabung, _status_migrasi_khusus,
  _menunggu_pemain_kembali, _dijeda_di_awal_giliran, pemain_kembali_selesai, _putus_tertunda, _ip_sesi_host,
  cabang_client_dijawab, _jawaban_cabang_client, _slot_pemilih_cabang, _cabang_tonton_terbuka,
  _pilihan_cabang_tertunda
- pemain.gd: siap_mulai_diklik, _giliran_berjalan, arah_cabang_terpilih, cabang_lokal_diklik
(Beberapa terlihat "salah tempat" -- mis. `_permainan_selesai` di pemain_jaringan.gd -- karena file itu yang
pertama memakainya dalam rantai; ini akibat aturan warning Godot, bukan pilihan topik.)

## Lampiran C. Alat di rig (scratchpad, folder f3/)

pecah_pemain.py (pemecah), peta_fungsi.json (fungsi -> file), cek_pindah.py (bukti pindah utuh),
cek_nama_ganda.py, cek_peringatan_f3.sh, uji_f3_t1.sh (jejak sim), uji_f3_t5.sh (adegan asli tanpa iklan),
uji_f3_t4.sh (adegan asli + iklan & profil), uji_f3_mp.sh (contoh multiplayer), uji_f3_mock.sh (iklan tiruan).
Rig di scratchpad bisa hilang kalau sesi ini ditutup; Lampiran A + aturan di bagian 1 cukup untuk membuat
ulang alat & petanya. Satu-satunya penjaga untuk aturan 7.3 (nama fungsi kembar) disalin utuh di Lampiran D
supaya tidak ikut hilang.

## Lampiran D. cek_nama_ganda.py (salin ke file .py, jalankan: `python3 cek_nama_ganda.py <folder proyek>`)

```python
#!/usr/bin/env python3
"""Fase 3: tidak boleh ada fungsi bernama sama di dua file pecahan pemain.gd (yang di file
atas diam-diam MENIMPA yang di bawah). Deklarasi '@abstract func' + satu isi = boleh.
Pakai: python3 cek_nama_ganda.py <folder proyek>"""
import os, re, sys
FILE = ["pemain_dasar.gd", "pemain_tampilan.gd", "pemain_papan.gd", "pemain_kartu.gd",
        "pemain_duel.gd", "pemain_jaringan.gd", "pemain.gd"]
isi, abstrak = {}, {}
masalah = 0
for f in FILE:
    for no, b in enumerate(open(os.path.join(sys.argv[1], f), encoding="utf-8"), 1):
        m = re.match(r'^(@abstract )?(?:static )?func ([A-Za-z_0-9]+)\s*\(', b)
        if not m:
            continue
        n = m.group(2)
        if m.group(1):
            abstrak.setdefault(n, []).append((f, no))
            continue
        if n in isi:
            print("GANDA: %s di %s:%d dan %s:%d" % (n, isi[n][0], isi[n][1], f, no)); masalah += 1
        else:
            isi[n] = (f, no)
for n, tempat in abstrak.items():
    if len(tempat) > 1:
        print("DEKLARASI GANDA: %s %s" % (n, tempat)); masalah += 1
    if n not in isi:
        print("DEKLARASI TANPA ISI: %s" % n); masalah += 1
print("CEK_NAMA_GANDA %s: %d fungsi, %d deklarasi @abstract, %d masalah" % ("LOLOS" if masalah == 0 else "GAGAL", len(isi), len(abstrak), masalah))
sys.exit(1 if masalah else 0)
```
