# RENCANA: Mode "4 PLAYERS" + Migrasi Host (host keluar -> pemain lain lanjut BERSAMA)

Disusun oleh Opus (24-09) setelah membaca layar_local_play.gd, pemain.gd (jaringan, siaran state,
takeover), ui_dinamis.gd (panel OPPONENT LEFT), status_jaringan.gd, uji_robot_mp.gd.
Dikerjakan oleh Sonnet. ATURAN USER: edit hanya baris yang relevan (jangan tulis ulang file);
setelah tiap TAHAP selesai & lolos uji, kirim SET LENGKAP terbaru sekaligus dalam SATU pesan dan minta
user membuang unduhan lama yang bernama sama; balas dalam Bahasa Indonesia. File produksi: UJI_DUEL,
UJI_SERI, UJI_SELALU_PEDANG WAJIB tetap false. Salinan uji:
/tmp/claude-0/-home-claude/bc2a37a6-77d5-5593-942f-124ebd210f19/scratchpad/proj (samakan setiap edit;
bedanya hanya saklar UJI_*). Teks untuk pemain: bahasa Inggris SEDERHANA.

## Perilaku SEKARANG (sebelum rencana ini)
- 3P+1AI, host P1 keluar: P2 & P3 masing-masing melihat "OPPONENT LEFT" -> CONTINUE VS AI -> tiap HP
  meneruskan permainannya SENDIRI (semua slot lain jadi AI). Hasilnya dua permainan terpisah yang lama-
  lama berbeda; tidak ada sambung ulang. (Terbukti di uji S3/D3/D4: LANJUT_SETELAH_HOST_KELUAR.)
- Catatan: AI (P4) bukan "client" -- AI selalu dijalankan di HP host. Setelah migrasi, AI dijalankan
  host baru.
- Hotspot P1 mati = jaringannya hilang. Game tidak bisa menyalakan hotspot sendiri (Android membatasi;
  satu-satunya jalan plugin Android native LocalOnlyHotspot dengan SSID/sandi acak -- di luar lingkup).
  Jadi menyalakan hotspot & menyambung WiFi = langkah MANUAL pemain, dipandu teks di layar.

## Keputusan user (24-09)
1. Host baru = siapa yang menekan BECOME HOST duluan. Dua host dengan id_sesi sama saling mendengar ->
   yang "umur host"-nya (detik sejak menekan, diukur di HP masing-masing & ikut di pesan UDP -- tidak butuh
   jam yang sama) LEBIH MUDA mengalah. Selisih < 0.5 dtk -> host lama (P1) menang; selain itu aturan lobby
   (IP lebih besar mengalah; IP sama [rig uji satu mesin] -> slot lebih besar mengalah).
1b. (24-09, pertanyaan lanjutan user) Host lama yang hotspot-nya mati TIDAK SENGAJA boleh kembali jadi host
   selama game-nya masih terbuka dan belum ada host baru -- lihat bagian 2B.
2. Tanpa batas waktu: permainan lanjut HANYA saat host baru menekan START NOW. Slot yang belum kembali
   saat itu dijalankan AI.
3. Bertahap: TAHAP 1 (mode 4P) dikirim duluan, TAHAP 2 (migrasi) set berikutnya.

## TAHAP 1: Mode "4 PLAYERS" (4 HP)
layar_local_play.gd:
- MODE_LOBBY: tambah DI AKHIR `{"nama": "4 PLAYERS", "jenis": ["manusia", "manusia", "manusia", "manusia"]}`
  (indeks 5; indeks 0-4 jangan digeser -- robot uji memilih mode lewat indeks).
- MAKS_CLIENT = 3; perbarui komentar baris 44, 55 ("Client pertama = P2, kedua = P3, ketiga = P4"), 221.
- Panel lobby kini 6 tombol mode: ambil foto lobby host & client di layar kecil (seperti
  foto_lobby_host.png). Kalau terpotong, kecilkan tinggi tombol mode (48 -> 42) / jarak antartombol saja.
pemain.gd / ui_dinamis.gd: slot 3 sebagai MANUSIA_JARINGAN belum pernah diuji (3P+1AI memakai slot 3
sebagai AI). Audit lewat uji saja: HUD daftar lawan 3 baris, nama "P4", warna kuning, _atur_nama_duel,
"WAITING FOR PLAYERS...", _periksa_kesiapan_klien, tawaran pedang/kartu di device P4. Perbaiki HANYA
yang terbukti salah.
Uji (X="pedang_awal=1 kartu_awal=1"; jalankan_mp3.sh sudah mendukung NC=3):
- B0 `EXTRA="$X" ./jalankan_mp3.sh ub_m5 5 alam 3 "" 30 41`
- B1 `./jalankan_mp3.sh ub_m5p 5 pantai 3 "" 30 42`
- B2 client3 keluar g8: `./jalankan_mp3.sh ub_s1 5 alam 3 client_keluar 30 43 8 3` (host+2 client lanjut)
- B3 client2 keluar saat pilih elemen: `EXTRA="$X" ./jalankan_mp3.sh ub_d1 5 alam 3 client_keluar_duel 30 44 8 2`
- B4 host keluar g8 (perilaku lama): `./jalankan_mp3.sh ub_s3 5 alam 3 host_keluar 40 45 8`
- Regresi: A0, A3, A4 dari uji_akhir_duelkartu.sh.
Syarat lolos: semua SELESAI normal (bukan MACET), scripterr=0, beda=0, cek_gagal=0 di semua log.
Kirim: set lengkap 12 file (yang berubah cuma layar_local_play.gd kecuali audit menemukan hal lain).

## TAHAP 2: Migrasi host
### Alur di layar
Panel baru "HOST LEFT" -- muncul di CLIENT saat host putus, HANYA kalau masih ada manusia jaringan lain
selain device ini (bukan host lama, bukan AI). Kalau device ini satu-satunya manusia tersisa -> panel
lama OPPONENT LEFT (tidak berubah).
    HOST LEFT
    To keep playing together:
    1. One player turns on a hotspot and taps BECOME HOST.
    2. Other players connect WiFi to that hotspot. This screen joins by itself.
    [BECOME HOST] (hijau)   [PLAY ALONE VS AI] (biru = perilaku lama)   [EXIT TO MAIN MENU]
    status: "Searching for the new host..." / "Found P2! Joining..." / "Joined! Waiting for P2 to start..."
Panel host baru:
    YOU ARE THE NEW HOST
    Keep your hotspot on. Players back:  P3 OK   P4 ...
    [START NOW]  (keterangan kecil: "Players not back will be played by AI.")   [PLAY ALONE VS AI]
Setelah START NOW: panel di semua HP tertutup, teks "P1 left. AI takes over!", permainan lanjut dari
state terakhir.

### Teknis
File BARU `migrasi_host.gd` (extends Node, dibuat pemain.gd saat dibutuhkan): semua UDP diskaveri &
pembuatan peer ENet untuk migrasi -- supaya pemain.gd tidak makin gemuk. Set kiriman TAHAP 2 = 13 file.

1. id_sesi (supaya tidak menyambung ke permainan lain):
   layar_local_play.gd _mulai_dari_lobby: `var id_sesi = randi()`; rpc_mulai_dari_lobby & _masuk_permainan
   dapat argumen id_sesi -> `StatusJaringan.id_sesi` (var baru, 0 di reset_susunan).
2. Pesan UDP di PORT_DISKAVERI 7778 (awalan beda dari lobby supaya lobby tidak salah tangkap):
   - host baru, tiap 0.5 dtk: "TILEDUEL_MIGRASI_HOST|<id_sesi>|<slot>|<umur_host_dtk>|<host_lama 0/1>"
   - pencari, tiap 0.4 dtk: "TILEDUEL_MIGRASI_CARI|<id_sesi>|<slot>" (host baru membalas langsung)
   Abaikan id_sesi lain. Siaran/bind TIRU PERSIS lobby (_kumpulkan_alamat_siaran dsb. -- sudah terbukti
   jalan di HP & di rig 3 proses). Host baru yang mendengar HOST lain dgn id_sesi sama: aturan mengalah di
   Keputusan 1 -> yang kalah menutup servernya lalu jadi pencari.
3. Client saat host putus (_saat_peer_jaringan_disconnect, peran "client"):
   - slot_host_lama = _slot_dari_peer(1). manusia_lain = slot s != slot_lokal, != slot_host_lama,
     jenis MANUSIA_JARINGAN. Kosong -> alur lama.
   - Selain itu: `_generasi_jaringan += 1`, `_bebaskan_penantian_jaringan()`, `_tutup_ui_jaringan_client()`,
     tunggu replay lokal selesai (ekstrak loop "batas < 20.0" dari _ambil_alih_sebagai_client jadi
     `_selesaikan_replay_lokal()` dan pakai di kedua tempat), slot_host_lama -> MENUNGGU (tetap
     MANUSIA_JARINGAN, id -1 -- BUKAN AI dulu: bisa saja P1 sendiri yang kembali jadi host, lihat 2B;
     keputusan akhir AI/manusia tiap slot datang dari host lewat rpc_lanjut_setelah_migrasi),
     `_migrasi_berjalan = true`, tampilkan panel HOST LEFT, migrasi.mulai_cari().
   - Sinyal: di _siapkan_indikator_jaringan sambungkan KEDUA sinyal (peer_disconnected & server_disconnected)
     ke _saat_peer_jaringan_disconnect, sekali saja. Di handler: `if peran == "client" and id_peer != -1:
     return` (di client, peer_disconnected juga menyala untuk client LAIN -- abaikan); `if _migrasi_berjalan:`
     serahkan ke migrasi (lihat 5).
4. BECOME HOST: migrasi menutup peer lama, `create_server(PORT_GAME, 3)`, `peran_multiplayer = "host"`,
   mulai siaran HOST. pemain.gd `_jadi_host_baru()`: slot manusia lain tetap MANUSIA_JARINGAN dgn
   id_jaringan = -1 (menunggu); reset `_klien_siap`, `_koin_seri_*`, `_pilihan_elemen_jaringan`,
   `_duel_mengumpulkan=false`, `_menunggu_aksi_slot=-1`; panel host baru.
5. Gabung ulang: pencari menemukan host -> create_client(ip, PORT_GAME) -> connected_to_server ->
   `rpc_id(1, "rpc_minta_gabung_ulang", StatusJaringan.id_sesi, slot_lokal)`.
   Host (@rpc any_peer) validasi: id_sesi sama, slot valid & MANUSIA_JARINGAN & id -1, belum START NOW.
   Terima: `daftar_pemain[slot].id_jaringan = pengirim`, `StatusJaringan.peer_slot[pengirim] = slot`,
   `rpc_id(pengirim, "rpc_gabung_ulang_diterima", slot_lokal_host)`, segarkan panel.
   Tolak: `rpc_gabung_ulang_ditolak` -> client putus, status "Could not join. Tap PLAY ALONE VS AI."
   Client yang sudah gabung lalu putus SEBELUM START NOW: host set id -1 lagi & segarkan panel (belum AI).
6. START NOW: `refuse_new_connections = true`; slot manusia yang masih id -1 -> AI.
   `rpc("rpc_lanjut_setelah_migrasi", peer_slot, kontrol_per_slot)` -> client: set jenis_kontrol tiap slot
   (slot sendiri MANUSIA_LOKAL), id_jaringan dari peer_slot (host baru = id 1), tutup panel,
   `_migrasi_berjalan = false`.
   Host: tutup panel, `_migrasi_berjalan = false`, `_siarkan_state_giliran(slot_giliran)`, lalu lanjut lewat
   `_lanjutkan_dari_state_terakhir()` = bagian akhir _ambil_alih_sebagai_client (baris "Lanjutkan dari
   keadaan terakhir...") yang diekstrak & dipakai bersama, dengan tambahan:
   - slot giliran = lokal ATAU manusia jaringan -> `periksa_status_petak(slot)` (host menyiarkan state &
     mengisi _menunggu_aksi_slot; client menampilkan menunya sendiri). AI -> `_jalankan_ai_di_tengah_giliran`.
   - mode_jual_aset milik manusia jaringan -> `_ai_jual_sampai_lunas` (kasus langka, cukup begini).
   - konfrontasi/duel_berlangsung -> "akhir" (sama seperti sekarang: duel yang terputus dibatalkan).
7. putaran_slot & kemarahan_slot ikut _siarkan_state_giliran ("putaran", "kemarahan") dan diterapkan di
   rpc_terima_state_giliran (pakai data.has). Tanpa ini host baru -- dan client yang lanjut sendiri seperti
   sekarang -- memakai hitungan putaran & dendam AI yang basi.
8. Host baru keluar lagi -> alurnya sama (migrasi kedua). Host lama yang kembali: bagian 2B.

### 2B. Host lama kembali (hotspot mati tidak sengaja, game di HP P1 masih terbuka)
Masalah utama: hotspot mati membuat client putus SATU PER SATU (timeout ENet beda-beda). Dengan kode
sekarang, client yang putus duluan langsung diambil alih AI ("masih ada device lain"), baru yang terakhir
memunculkan panel. P1 harus bisa membedakan "satu pemain keluar" vs "jaringan saya sendiri hilang".
1. Catat alamat sesi host saat permainan mulai: `_ip_sesi_host` = IP lokal host yang sejaringan dengan
   client (IP client dari `peer_jaringan.get_peer(id).get_remote_address()`, lalu cari IP sendiri dengan
   3 angka depan sama -- tiru _ip_ku_yang_sejaringan di lobby).
2. Host, peer_disconnected: tunda keputusan 3.0 dtk (timer, TANPA langsung _ambil_alih_slot_ai). Setelah
   jeda: kalau `_ip_sesi_host` sudah tidak ada di `IP.get_local_addresses()` ATAU semua client ikut putus
   -> mode JARINGAN PUTUS (di bawah). Kalau jaringan host masih ada & masih ada client lain -> alur lama
   (AI mengambil alih slot itu). Saklar uji (salinan uji saja): `UJI_PAKSA_JARINGAN_PUTUS` supaya rig bisa
   mensimulasikannya (di satu mesin IP tidak pernah hilang).
3. Mode JARINGAN PUTUS di host: slot yang putus -> MENUNGGU (id -1, bukan AI). Penantian yang sedang
   berjalan (cabang, elemen duel, koin, kartu, pedang) dijawab otomatis seperti _bebaskan_penantian_slot
   SEKARANG, tapi TANPA mengambil alih gilirannya. Permainan DITAHAN di awal giliran berikutnya: di baris
   pertama `_mulai_giliran(slot)`: `while _menunggu_pemain_kembali: await pemain_kembali_selesai` (AI yang
   sedang jalan menuntaskan aksinya dulu, lalu berhenti). Giliran manusia yang putus memang sudah menunggu.
   Panel di P1:
       CONNECTION LOST
       Your hotspot or WiFi is off. Turn it back on, then tap WAIT FOR PLAYERS.
       [WAIT FOR PLAYERS]   [PLAY ALONE VS AI]   [EXIT TO MAIN MENU]
4. WAIT FOR PLAYERS: tutup peer lama, `create_server(PORT_GAME, 3)` baru, siarkan MIGRASI_HOST dengan
   host_lama=1 -> panel host yang SAMA dengan host baru (daftar pemain kembali + START NOW). Client yang
   masih di layar HOST LEFT (belum ada yang menekan BECOME HOST) menemukan P1 & bergabung otomatis --
   HP Android biasanya menyambung ulang sendiri ke hotspot yang sudah pernah dipakai.
5. START NOW di P1: sama seperti langkah 6 KECUALI tidak memanggil `_lanjutkan_dari_state_terakhir()`
   (logika host P1 tidak pernah berhenti, jadi memanggilnya = giliran dobel). Cukup:
   `_menunggu_pemain_kembali = false`, `pemain_kembali_selesai.emit()`, `_siarkan_state_giliran(slot)`, dan
   kalau giliran sekarang milik manusia jaringan yang sudah kembali -> `periksa_status_petak(slot)` (menu
   dikirim ulang); yang belum kembali -> AI (`_ambil_alih_slot_ai`).
6. Kalau P1 mendengar host lain (id_sesi sama) yang LEBIH TUA (sudah ada host baru): P1 TIDAK boleh
   bergabung sebagai client -- logika host P1 masih berjalan, mengubahnya jadi pengikut di tengah jalan
   berisiko langkah dobel. Panel P1: "P2 is already the new host. This phone can't join now." ->
   [PLAY ALONE VS AI] [EXIT]. Di host baru, slot P1 menunggu lalu jadi AI saat START NOW.
7. P1 yang MENUTUP aplikasinya tidak bisa kembali (state-nya hilang). Kemungkinan tahap lanjutan (belum
   direncanakan): gabung ulang lewat muat ulang layar permainan sebagai client + snapshot penuh, yang juga
   bisa dipakai client biasa yang putus.

### Uji TAHAP 2 (uji_robot_mp.gd, salinan uji saja)
- Peran pengecek (_mulai_cek/_proses_cek, batas_giliran, rpc_uji_selesai) pakai
  `StatusJaringan.peran_multiplayer == "host"`, bukan argumen robot=host -- supaya host baru ikut mengecek.
- Panel lama: robot yang dulu menekan "CONTINUE VS AI" juga menekan "PLAY ALONE VS AI" di HOST LEFT
  (supaya S3/D3/D4/B4 tetap berperilaku lama).
- Skenario baru: "host_keluar_migrasi" (host quit giliran K; client urut=1 menekan BECOME HOST 1 dtk
  setelah panel muncul; lainnya menunggu; host baru menekan START NOW begitu semua OK atau 20 dtk),
  "migrasi_sendiri" (urut terakhir menekan PLAY ALONE), "migrasi_rebutan" (urut 1 & 2 menekan bersamaan),
  "migrasi_dua_kali" (host baru juga keluar 8 giliran kemudian).
- M1 3P+1AI -> 2P+2AI: `./jalankan_mp3.sh um_1 4 alam 2 host_keluar_migrasi 40 51 8`
- M2 4P -> 3P+1AI: `./jalankan_mp3.sh um_2 5 alam 3 host_keluar_migrasi 40 52 8`
- M3 4P, P4 main sendiri: `... um_3 5 alam 3 migrasi_sendiri 40 53 8`
- M4 rebutan: `... um_4 4 alam 2 migrasi_rebutan 40 54 8`
- M5 host keluar saat pilih elemen + migrasi: `EXTRA="$X" ... um_5 5 alam 3 host_keluar_duel_migrasi 40 55`
- M6 dua kali: `... um_6 5 alam 3 migrasi_dua_kali 50 56 8`
- M7 hotspot P1 mati lalu P1 kembali (skenario "host_hotspot_mati": host menutup peer-nya TANPA quit +
  UJI_PAKSA_JARINGAN_PUTUS, 5 dtk kemudian menekan WAIT FOR PLAYERS, START NOW saat semua kembali):
  `./jalankan_mp3.sh um_7 4 alam 2 host_hotspot_mati 40 57 8` -> SEMUA slot manusia tetap manusia
  (tidak ada yang jadi AI), cek_ok > 0 setelah kembali, host SELESAI BATAS_GILIRAN/MENANG.
- M8 P1 kembali terlambat (client urut=1 sudah BECOME HOST): `... um_8 5 alam 3 host_hotspot_telat 40 58 8`
  -> P1 menampilkan "already the new host" lalu PLAY ALONE; sesi host baru lanjut, slot P1 jadi AI.
- Regresi: seluruh uji_akhir_duelkartu.sh (13) + B0-B4.
Syarat lolos: host baru SELESAI BATAS_GILIRAN/MENANG, client SELESAI HOST_SELESAI, cek_ok > 0 SETELAH
migrasi, cek_gagal=0, scripterr=0, tidak ada MACET; foto panel HOST LEFT & host baru.

### Batasan yang perlu diketahui user
- Menyalakan hotspot manual. Yang menyalakan hotspot sebaiknya yang menekan BECOME HOST: di 4P tersisa 3 HP,
  dan beberapa HP memblokir koneksi antar-client di hotspot orang lain.
- P1 hanya bisa kembali kalau game-nya masih terbuka DAN belum ada host baru (2B). Menutup aplikasi =
  tidak bisa kembali.
- Aksi yang sedang berjalan saat host putus (duel/jalan) dilanjutkan dari state terakhir; duel yang
  belum selesai batal -- sama seperti sekarang.
- Kelanjutan permainan memakai pengacak host baru (wajar, tidak identik dengan kalau host lama tetap ada).
- Rig uji jalan di satu mesin: bisa mensimulasikan proses host mati, TIDAK bisa mensimulasikan hotspot mati.
  Uji perangkat nyata butuh 3-4 HP (atau beberapa instance Godot di laptop + HP di jaringan yang sama).

## STATUS (24-09, dikerjakan Opus): TAHAP 1 terkirim. TAHAP 2 selesai -- catatan implementasi
Beda/tambahan dari rencana di atas (semuanya sudah diuji):
- 2B (tunda 3 dtk + CONNECTION LOST) HANYA kalau host masih punya >= 2 pemain manusia jaringan. Satu pemain
  jaringan (1v1, 2P+AI, atau sisanya sudah AI) -> alur lama OPPONENT LEFT: di situ client tidak punya panel
  HOST LEFT (tidak ada manusia lain), jadi WAIT FOR PLAYERS tidak ada gunanya.
- Setelah START NOW host tetap mengumumkan diri (field "anggota" = slot manusia yang ikut). Pencari yang bukan
  anggota -> "Px already continued the game without this phone." (tamat); anggota -> diam menunggu. Host yang
  sudah START NOW tidak pernah mengalah. Slot yang diambil AI dihapus dari anggota.
- Rebutan: kalau 2 dtk tidak selesai -> aturan seri saja (host_lama, IP, slot). Pemenang mengirim pesan HOST
  langsung ke IP yang kalah (siaran bisa cuma sampai satu arah).
- Uji: port per proses lewat var migrasi_host.gd (port_dengar/port_tujuan/alamat_tambahan/port_game) dan
  pemain.gd var uji_paksa_jaringan_putus -- keduanya HANYA diubah robot, jadi produksi = salinan uji (beda
  cuma UJI_DUEL/UJI_SERI). Hotspot mati disimulasikan host dengan disconnect_peer ke semua client.
- Dari review independen: tunggu kartu (gacha/buang) memakai jenis kontrol, bukan id>0; gabung ulang
  mengganti koneksi lama slot yang sama; tombol hijau nonaktif 1.5 dtk saat artinya berganti; peer ditutup
  -> OfflineMultiplayerPeer (bukan null); panel HOW TO WIN yang ditutup setelah host berganti tidak memulai
  giliran pertama lagi (_generasi_jaringan).
- Bug LAMA yang ketemu (macet "Waiting for P2..." di HP P2 sendiri, juga penyebab A3 MACET di TAHAP 1):
  _sembunyikan_menu_giliran_lawan yang tertunda kini berhenti kalau giliran terbaru milik device ini.
- Belum ada (tahap lanjutan): pemain yang putus SETELAH START NOW tidak bisa gabung lagi ke permainan yang
  sama; client 1v1 tidak bisa menunggu host kembali.
