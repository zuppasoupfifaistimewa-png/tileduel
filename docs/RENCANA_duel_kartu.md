# RENCANA: Pengumuman duel & kartu di semua device (host + client + AI)

Disusun oleh Opus setelah uji 3 proses nyata (mode 2P+2AI, UJI_DUEL+UJI_SERI hanya di salinan uji).
Dikerjakan oleh Sonnet. ATURAN USER: edit hanya baris yang relevan (jangan tulis ulang file);
setelah selesai kirim SET LENGKAP 12 file sekaligus dalam SATU pesan; balas dalam Bahasa Indonesia.
File produksi: UJI_DUEL, UJI_SERI, UJI_SELALU_PEDANG WAJIB tetap false.

## Bukti uji (sebelum perbaikan)
- Host bertahan vs AI P4: 3 dtk di "CHOOSE YOUR ELEMENT!" dengan segel musuh = 0. Segel AI tidak pernah
  muncul saat host memilih. Penyebab: AI memilih & _kabari_lawan_duel_terkunci() menyetel musuh_siap=true
  SEBELUM _tunggu_pilihan_elemen_lokal() -> ui_elemen.siapkan_pilih_elemen() me-reset musuh_siap=false.
- Client penonton (duel host vs AI): selama host memilih hanya teks "DUEL! P4 vs P1 -- choosing
  elements..."; layar duel baru muncul di "BOTH LOCKED!" (replay naskah). Rolet, koin seri, dan pemenang
  SUDAH tampil lengkap di penonton.
- Pedang AI: di semua device hanya teks "P4 uses Sword Card! (+3 ATK)" 1.8 dtk (AiMusuh.pilih_pedang_ai
  -> _umumkan("ai_pedang")). Penyerang manusia sudah dapat UI kartu pedang penuh (mode "tonton").
- Kartu tersimpan (LOW/HIGH ROLL, SHIELD): hanya teks _umumkan, tanpa animasi kartu.
- BUG BARU: AI bisa "memakai" kartu PEDANG sebagai kartu sebelum lempar dadu (ai_musuh.gd baris ~144-160
  memilih acak dari seluruh inventaris) -> teks "P3 is using a card!" lalu tidak terjadi apa-apa, kartu
  pedang hilang sia-sia (_eksekusi_kartu_simpan tidak punya cabang untuk pedang).

## Keputusan desain
- Semua pemakaian kartu tersimpan berujung di SATU titik: pemain.gd _eksekusi_kartu_simpan() yang
  berjalan di host/solo (host manusia, client lewat rpc_minta_pakai_kartu, dan AI). Animasi kartu dipicu
  di sana + disiarkan ke semua client -> otomatis mencakup host, client, dan AI.
- Pedang AI memakai ulang UI pedang mode "tonton" + RPC yang sudah ada (rpc_lawan_memilih_pedang,
  rpc_pedang_dipilih_host) -- tidak perlu RPC baru.
- Segel LOCKED disiarkan ke SEMUA device (bukan hanya ke lawan peserta). Penonton membuka layar duel
  mode tonton sejak awal fase pilih elemen.
- AI "berpikir" 2.0 dtk sebelum mengunci elemen (sama dengan jeda solo "IS THINKING..."). AI vs AI:
  penyerang 1.5 dtk, pembela 2.5 dtk (segel muncul bergantian). Jeda tetap (bukan acak) supaya tidak
  menggeser urutan mesin_acak.
- Jalur SOLO duel (ui_elemen.jalankan_duel tanpa naskah) TIDAK diubah. Tapi pedang AI (A) dan animasi
  kartu (C) ikut berlaku di solo juga (jalur kodenya sama) -- menunggu persetujuan user.
- AI memilih elemen tetap tanpa mengintip pilihan manusia: _pilih_elemen_adaptif hanya membaca
  memori_serang/bertahan (riwayat), yang baru diperbarui di jalankan_duel setelah naskah terkunci.
- Setelah host keluar, client memakai StatusJaringan.keluar_dari_sesi() -> peran "" -> semua jalur MP
  baru otomatis tidak dipakai.

## A. Pedang AI terlihat di semua device (REVISI: AI juga bisa NO, SAVE IT)
Tambahan permintaan user (disetujui, berlaku juga di SOLO -- lihat catatan solo di bawah): layar kartu
pedang yang SAMA dengan milik penyerang manusia muncul di host & semua client; AI "berpikir" ±1 dtk lalu
kartunya disorot emas "<AI> USES SWORD CARD! +N ATK" -- ATAU AI menekan NO, SAVE IT sendiri (tidak selalu
dipakai). Reuse total sistem UI pedang yang sudah ada (munculkan_ui_pedang_penyerang mode "tonton" +
pedang_jaringan + rpc_lawan_memilih_pedang/rpc_pedang_dipilih_host) -- tidak ada RPC baru.

ai_musuh.gd -- pilih_pedang_ai(main_node, slot): KEPUTUSAN saja (tanpa efek/UI): cari kartu pedang
level tertinggi di inventaris slot. Kalau tidak ada -> null. Kalau ada -> 75% kembalikan kartunya,
25% kembalikan null (AI "menekan" NO, SAVE IT sendiri -- disimpan untuk duel berikutnya). Dihapus:
remove_at, teks_dadu.show(), _umumkan("ai_pedang"), timer 1.8, teks_dadu.hide() (semua pindah ke UI).

pemain.gd -- fungsi baru _pilih_pedang_ai_terlihat(slot_ai) di dekat _pilih_pedang_penyerang():
    - Kumpulkan daftar_pedang (semua kartu id "pedang*" di inventaris slot_ai). Kosong -> return 0
      (tidak ada tawaran sama sekali, sama seperti penyerang manusia tanpa pedang).
    - kartu = AiMusuh.pilih_pedang_ai(self, slot_ai); indeks = daftar_pedang.find(kartu) kalau kartu
      != null, else -1 (kode untuk NO, SAVE IT -- sama seperti tombol batal manusia).
    - if host: rpc("rpc_lawan_memilih_pedang", daftar_pedang, slot_ai)
    - Buat PetakKartu (is_petak_kartu=false), munculkan_ui_pedang_penyerang(daftar_pedang, "tonton",
      _nama_ui(slot_ai)) TANPA await -- UI-nya baru ditutup lewat pedang_jaringan() di bawah.
    - await get_tree().create_timer(1.0).timeout   # AI "berpikir" ±1 detik
    - if host: rpc("rpc_pedang_dipilih_host", indeks); UI.pedang_jaringan(indeks); await
      UI.pedang_terpilih; UI.queue_free()
    - kartu == null -> return 0. Selain itu hapus kartu dari inventaris slot_ai (find + remove_at),
      return int(kartu["id"].right(1)).
_mulai_duel(): cabang `if _is_ai(slot_a):` -> `poin_bonus_pedang = await _pilih_pedang_ai_terlihat(slot_a)`.
(Pola ini sama persis dengan jalur penyerang client di _pilih_pedang_penyerang.)

STATUS: SUDAH DIIMPLEMENTASI & DIUJI (lihat bukti uji di bagian E).

## B. Segel LOCKED & layar pilih elemen untuk semua device (SUDAH DIIMPLEMENTASI & DIUJI)
Catatan: jalur ini (jeda "berpikir" 2.0/1.5/2.5 dtk + segel LOCKED satu per satu) HANYA berjalan di
_kumpulkan_naskah_duel (HOST multiplayer sungguhan). Duel AI vs AI di SOLO murni (3-4 pemain lokal
tanpa jaringan) tetap lewat _naskah_duel_ai seperti sebelumnya (TIDAK diubah, sesuai rencana awal) --
user hanya menyetujui bagian A (pedang AI) & C (animasi kartu) berlaku juga di solo, bukan bagian B.
pemain.gd:
1. var baru: `var _nomor_duel: int = 0` (penjaga timer AI dari duel sebelumnya).
2. HAPUS _kabari_lawan_duel_terkunci(); ganti dengan:
    func _kunci_elemen_peserta(slot: int, elemen: String) -> void:   # HOST
        if _pilihan_elemen_jaringan.has(slot): return
        _pilihan_elemen_jaringan[slot] = elemen
        _siarkan_segel_terkunci(slot)
        elemen_jaringan_diterima.emit(slot)
    func _siarkan_segel_terkunci(slot: int) -> void:                 # HOST
        _tampilkan_segel_terkunci(slot)
        rpc("rpc_segel_terkunci", slot)
    @rpc("authority", "call_remote", "reliable")
    func rpc_segel_terkunci(slot: int) -> void: _tampilkan_segel_terkunci(slot)
    func _tampilkan_segel_terkunci(slot: int) -> void:               # semua device
        if _duel_slot_penyerang < 0 or _duel_slot_pembela < 0: return
        var sisi_p = _sisi_p_duel(_duel_slot_penyerang, _duel_slot_pembela)
        var nama = ui_elemen.nama_sisi_p if slot == sisi_p else ui_elemen.nama_sisi_m
        if slot == sisi_p: ui_elemen.pemain_siap = true
        else: ui_elemen.musuh_siap = true
        ui_elemen.queue_redraw()
        if ui_elemen.mode_tonton:
            ui_elemen.teks_judul.text = nama + " LOCKED IN!"
        elif slot != sisi_p and ui_elemen.fase_duel == "PILIH_PEMAIN" and not ui_elemen.pemain_siap:
            ui_elemen.teks_judul.text = nama + " CHOSE! YOUR TURN!"
   rpc_lawan_sudah_memilih() jadi tidak terpakai -> hapus.
3. Pecah _tunggu_pilihan_elemen_lokal() jadi dua (isi lama dipindah apa adanya):
   - _siapkan_pilihan_elemen_lokal(): siapkan_pilih_elemen("CHOOSE YOUR ELEMENT!") + aktifkan tombol (sinkron)
   - _tunggu_klik_elemen_lokal() -> String: sisa isi lama (generasi, await elemen_diklik, segel sendiri,
     "WAITING FOR OPPONENT...")
   - _tunggu_pilihan_elemen_lokal() tetap ada sebagai pembungkus (siapkan lalu return await tunggu) --
     dipakai rpc_minta_pilihan_elemen_duel.
4. rpc_minta_pilihan_elemen_duel(slot_a, slot_d): baris pertama set `_duel_slot_penyerang = slot_a`,
   `_duel_slot_pembela = slot_d`.
5. rpc_duel_dimulai(slot_a, slot_d) (penonton; host juga memanggilnya lokal kalau host penonton):
   set _duel_slot_*; menu_aksi/teks_uang/teks_bintang/teks_dadu hide; musik duel kalau belum jalan
   (pola `if not (pemutar_bgm_duel and pemutar_bgm_duel.playing)`); _atur_nama_duel(slot_a, slot_d);
   ui_elemen.siapkan_tonton_pilih_elemen(ui_elemen._kata_serang(ui_elemen.nama_sisi_p) + " CHOOSING ELEMENTS...")
6. _kumpulkan_naskah_duel() urutan baru:
   a. reset lama + `_nomor_duel += 1`
   b. rpc_minta_pilihan_elemen_duel ke client peserta (tetap)
   c. rpc_duel_dimulai ke penonton + lokal kalau host penonton (tetap)
   d. `var host_ikut = (slot_a == slot_lokal or slot_d == slot_lokal) and not _is_ai(slot_lokal)`
      if host_ikut: _siapkan_pilihan_elemen_lokal()
   e. AI: kalau keduanya AI -> jeda penyerang 1.5, pembela 2.5; selain itu 2.0.
      `_ai_kunci_elemen_tertunda(s, jeda, _nomor_duel)` untuk tiap peserta AI (TANPA await)
   f. if host_ikut: `var e = await _tunggu_klik_elemen_lokal()`; `if e != "": _kunci_elemen_peserta(slot_lokal, e)`
   g. tunggu semua: for s in [slot_a, slot_d]: while not _pilihan_elemen_jaringan.has(s): await elemen_jaringan_diterima
   h. `elemen = {slot_a: _pilihan_elemen_jaringan[slot_a], slot_d: _pilihan_elemen_jaringan[slot_d]}`; sisanya tetap.
    func _ai_kunci_elemen_tertunda(slot: int, jeda: float, nomor: int) -> void:
        await get_tree().create_timer(jeda).timeout
        if nomor != _nomor_duel or not _duel_mengumpulkan: return
        _kunci_elemen_peserta(slot, ui_elemen._pilih_elemen_adaptif("menyerang" if slot == _duel_slot_penyerang else "bertahan"))
7. rpc_kirim_pilihan_elemen_duel(): setelah validasi, ganti 3 baris (simpan/kabari/emit) dengan
   `_kunci_elemen_peserta(slot, elemen)`.
8. _bebaskan_penantian_slot(): blok "Elemen duel" -> `_kunci_elemen_peserta(slot, ui_elemen._pilih_elemen_adaptif(...))`.
9. _tutup_ui_jaringan_client(): di cabang `if not _replay_duel_berjalan: ui_elemen.hide()` tambahkan
   kembali ke musik normal (AudioGrafis.kembali_ke_musik_normal(self)) kalau musik duel sedang jalan.
ui_elemen.gd -- fungsi baru setelah siapkan_pilih_elemen():
    func siapkan_tonton_pilih_elemen(judul_teks: String) -> void:
        siapkan_pilih_elemen(judul_teks)
        fase_duel = "MENUNGGU_MUSUH"   # klik diabaikan oleh penjaga _on_tombol_ditekan
        for btn in tombol_elemen.values(): btn.disabled = true
        queue_redraw()
Replay naskah (jalankan_duel dengan naskah) tidak diubah: tetap mulai "BOTH LOCKED!" -- sekarang
tersambung mulus karena kedua segel sudah terlihat di semua layar.

## C. Animasi pemakaian kartu tersimpan di semua device (SUDAH DIIMPLEMENTASI & DIUJI)
Berlaku juga di SOLO (disetujui user): _eksekusi_kartu_simpan dipanggil sama persis di solo maupun
multiplayer, RPC-nya otomatis dilewati kalau peran_multiplayer != "host". Durasi total animasi ~2.9 dtk
(disetujui user sebagai "~3 dtk"): fade in 0.2 + kartu muncul 0.35 + jeda 0.3 + balik ke muka 0.36 +
tahan 1.4 + fade out 0.3.
petak_kartu.gd -- fungsi baru (gaya sama dengan kartu gacha; hanya Control + tween, aman Very Low):
    func putar_animasi_pakai_kartu(id_kartu: String, judul: String, teks_target: String,
                                   warna_judul: Color, warna_target: Color) -> void
    - teks kartu diambil dari database_efek berdasarkan id
    - CanvasLayer layer 15, PROCESS_MODE_ALWAYS; overlay hitam, fade 0 -> 0.75 (0.2 dtk)
    - Label judul atas (warna_judul, outline hitam), mis. "P3 USED A CARD!"
    - kartu punggung di tengah (gaya gacha: biru tua, "Tile Duel / ? / Tile Duel"), muncul scale 0 -> 1.1 -> 1 (0.35 dtk)
    - jeda 0.3 dtk, lalu balik: scale:x 1 -> 0 (0.18), ganti ke muka emas berisi teks kartu, 0 -> 1 (0.18)
    - Label target di bawah kartu (warna_target), fade in 0.25 dtk
    - tahan 1.4 dtk, fade out semuanya 0.3 dtk, queue_free kanvas. Total +/- 3.2 dtk.
    Ukuran mengikuti rasio layar seperti _bangun_ui_layar_kartu (rasio = min(1, x/650, y/400)).
pemain.gd:
    func _nama_layar(slot: int) -> String: "YOU" kalau slot_lokal; "ENEMY" kalau <= 2 pemain; selain itu "P%d"
    func _putar_animasi_pakai_kartu(id_kartu: String, slot: int, slot_target: int) -> void:
        judul = "YOU USED A CARD!" (lokal) atau _nama_layar(slot) + " USED A CARD!"
        teks_target:
          dadu_rendah/dadu_tinggi -> "LOW ROLL for <T> (3 turns)" / "HIGH ROLL for <T> (3 turns)"
             <T> = "YOU" kalau slot_target == slot_lokal; kalau slot_target == slot (bukan lokal) -> nama + " (SELF)"
          pelindung -> "+500 COINS for " + _nama_layar(slot)
        warna: WARNA_SLOT[slot], WARNA_SLOT[slot_target]
        buat PetakKartu (is_petak_kartu=false), add_child, await putar_animasi_pakai_kartu(...), queue_free
    @rpc("authority", "call_remote", "reliable")
    func rpc_animasi_pakai_kartu(id_kartu: String, slot: int, slot_target: int) -> void:
        _putar_animasi_pakai_kartu(id_kartu, slot, slot_target)   # client: tampilan saja
    _eksekusi_kartu_simpan(): setelah slot/slot_target dihitung, untuk id dadu_rendah/dadu_tinggi/pelindung:
        if host: rpc("rpc_animasi_pakai_kartu", id, slot, slot_target)
        await _putar_animasi_pakai_kartu(id, slot, slot_target)
      lalu efek + _umumkan seperti sekarang, jeda sesudahnya dipendekkan: dadu 2.0 -> 1.0, pelindung 1.5 -> 1.0.
ai_musuh.gd: hapus `_umumkan("ai_pakai_kartu", slot)` + timer 1.0 sebelum _eksekusi_kartu_simpan
(judul animasi sudah mengumumkannya).

## C2. REVISI animasi kartu tersimpan (permintaan user 23-09 19:04) -- SUDAH DIIMPLEMENTASI & DIUJI
Mekanisme mirip kartu pedang: semua kartu simpanan pemakai tampil (pedang redup) -> 0.8 dtk -> kartu
terpilih emas, sisanya mengecil hilang (animasi buang kartu) & kartu terpilih bergeser ke tengah ->
tahan 2 dtk -> keterangan target -> 1 dtk -> latar memudar + kamera menyorot target (geser_kamera
dinolkan) -> kartu mengecil masuk ke tubuh target -> 1 dtk -> kamera kembali, normal.
petak_kartu.gd: tampilkan_kartu_pakai / lepas_latar_kartu_pakai / masukkan_kartu_pakai / tutup_kartu_pakai
(menggantikan putar_animasi_pakai_kartu). pemain.gd: _putar_animasi_pakai_kartu(daftar_id, indeks, slot,
slot_target) + rpc_animasi_pakai_kartu dengan argumen yang sama; _eksekusi_kartu_simpan dapat param
indeks_asal (posisi kartu sebelum dihapus) dari semua pemanggil (pemain.gd x2, ui_dinamis.gd, ai_musuh.gd).
Uji: kartu_m2 (seed 21) & kartu_m2b (seed 55) scripterr=0 beda=0; host/client/AI benar di kedua layar,
kamera pindah ke target; solo lawan=3 err=0.

## C3. Rapikan (permintaan user 23-09 20:11) -- SUDAH DIIMPLEMENTASI & DIUJI
1. Narasi di CLIENT ("P4 inflicted LOW ROLL...") ditahan sampai animasi kartu di layar client selesai:
   pemain.gd var _animasi_kartu_klien + signal animasi_kartu_klien_selesai (dinaikkan/diturunkan di
   rpc_animasi_pakai_kartu); rpc_umumkan menunggu selama > 0. Uji rapi_m2: tidak ada lagi baris narasi
   kartu yang muncul selagi animasi kartu yang sama masih tampil.
2. SOLO, duel AI vs AI (pemain manusia menonton): fungsi baru _tonton_ai_pilih_elemen(slot_a, slot_d)
   dipanggil di _jalankan_duel setelah _naskah_duel_ai -- layar tonton dibuka, penyerang mengunci di 1.5
   dtk, pembela 1 dtk kemudian (sama seperti AI vs AI di multiplayer), baru "BOTH LOCKED!". Uji langsung
   (uji_nyata duel_ai=1): 0.0 CHOOSING -> 1.5 "P3 LOCKED IN!" -> 2.5 BOTH LOCKED -> 4.5 UNLOCKING.

## D. Bug: AI memakai kartu pedang sebelum lempar dadu (SUDAH DIIMPLEMENTASI & DIUJI)
ai_musuh.gd logika_ai_fase_awal() blok "LOGIKA AI MENGGUNAKAN KARTU": pilih hanya dari kartu yang
id-nya TIDAK diawali "pedang":
    var bisa_dipakai = [] (kartu non-pedang)
    if bisa_dipakai.size() > 0:
        if mesin_acak.randi_range(1, 100) <= 40:
            var kartu_dipilih = bisa_dipakai[randi() % bisa_dipakai.size()]
            inventaris.remove_at(inventaris.find(kartu_dipilih))
            ... (target AI & _eksekusi_kartu_simpan tetap)

## E. Pengujian (wajib sebelum kirim) -- HASIL AKTUAL (sudah dijalankan)
Salinan uji: /tmp/claude-0/-home-claude/bc2a37a6-77d5-5593-942f-124ebd210f19/scratchpad/proj
(disinkronkan dari /home/claude, UJI_DUEL & UJI_SERI = true HANYA di salinan uji; produksi tetap false).
uji_robot_mp.gd (khusus salinan uji) ditambah:
- tag pengamat "ANIMASI_KARTU judul='...' target='...'" (selain "KARTU_UI pedang=N judul='...'" untuk
  tawaran pedang) -- dibedakan lewat ada/tidaknya _pedang_tombol/_pedang_tombol_batal.
- BUG kecil ditemukan & diperbaiki DI FILE UJI SAJA: kartu_awal=1 dan pedang_awal=1 berbagi satu
  penjaga `kartu_diberikan`, jadi kalau dipakai BERSAMAAN kartu pedang tidak pernah diberikan.
  Sekarang satu blok yang sama menjalankan kedua bagian kalau keduanya di-set.
1. `timeout 40 Godot --headless --path proj uji_parse.tscn --quit` -> semua skrip "-> true" (tidak ada
   parse error) setelah tiap perubahan.
2. `EXTRA="pedang_awal=1 kartu_awal=1" ./jalankan_mp3.sh duel_m2 2 alam 1 "" 14 21` (host+1client+2AI)
   dan sekali lagi dengan seed lain (giliran=20 seed=55, label duel_m2b) --
   host & client: `SELESAI ... scripterr=0 | beda=0` (cek_ok 7-8, cek_gagal=0, kartu_beda=0).
   - Segel LOCKED progresif di penonton: "D|400.8|DUEL fase=MENUNGGU_MUSUH segelM=0 segelP=1 tonton=1
     judul='P3 LOCKED IN!'" lalu "BOTH LOCKED!" 1 dtk kemudian -- di HOST dan CLIENT sama persis.
   - Pedang AI: "P3 USES SWORD CARD! / +3 ATK" & "P4 SAVED THE SWORD CARD! / No bonus this time"
     TERLIHAT sama persis di host dan client (judul + urutan pedang berkurang benar), dan KEDUANYA
     pernah terjadi dalam 2 sesi uji -- membuktikan probabilitas 75/25 (pakai/simpan) berjalan.
   - Animasi kartu: "ANIMASI_KARTU judul='P4 USED A CARD!' target='LOW ROLL for YOU (3 turns)'" dst,
     termasuk suffix " (SELF)" saat AI membuff dirinya sendiri -- sama di host & client.
   - Tidak ada lagi "is using a card!" (teks lama, sudah tidak dipanggil) di log manapun.
3. Skenario host keluar: `./jalankan_mp3.sh s5_2p2ai_hostkeluar 2 pantai 1 host_keluar 40 25 9` ->
   host log scripterr=0, client lanjut "SELESAI LANJUT_SETELAH_HOST_KELUAR ... scripterr=0 | beda=0".
4. Regresi solo: `./jalankan_nyata.sh reg_solo1 1 alam 9 40` (lawan=1) dan `reg_solo3` (lawan=3, AI vs AI
   ikut terjadi) -> keduanya "SIM BATAS_GILIRAN ... err=0", TIDAK macet.
5. Skenario client keluar: `./jalankan_mp3.sh s4_2p1ai_ckeluar 1 alam 1 client_keluar 30 24 8 1` ->
   host lanjut sampai BATAS_GILIRAN, scripterr=0 | beda=0 di kedua sisi. Client keluar tidak kebetulan
   di tengah fase pilih elemen pada seed ini -- jalur _bebaskan_penantian_slot untuk kasus itu sudah
   ditelusuri manual (sekarang tinggal memanggil _kunci_elemen_peserta yang melakukan 3 langkah yang
   sama persis seperti sebelumnya) tapi belum "tertangkap kamera" oleh robot.
6. Suite akhir lengkap (`uji_akhir_duelkartu.sh`, 13 skenario, EXTRA="pedang_awal=1 kartu_awal=1" untuk
   semua kecuali A5/A6/S1-S3): A0 1v1, A1 2P+1AI, A2 2P+2AI, A3 3P, A4 3P+1AI, A5 3P+1AI pantai,
   A6 2P+1AI pantai, S1 3P client keluar g8, S2 3P+1AI client keluar g10, S3 3P host keluar g8,
   D1 3P client keluar saat pilih elemen, D2 1v1 client keluar saat pilih elemen, D3 3P+1AI host keluar
   saat pilih elemen, D4 2P+1AI host keluar saat pilih elemen -- SEMUA `SELESAI ... scripterr=0 | beda=0`
   bersih di setiap log host & client (tidak ada lagi "BELUM dijalankan").
   - BUG DITEMUKAN & DIPERBAIKI (D2, seed 32, giliran keluar=8): lawan satu-satunya (mode 1v1) keluar
     PERSIS di tengah fase pilih elemen duel -> host lanjut sendiri lewat "CONTINUE VS AI" ->
     StatusJaringan.keluar_dari_sesi() mengubah peran_multiplayer jadi "" DI TENGAH duel yang sudah
     terlanjur berjalan lewat jalur naskah host. Duel itu sendiri lanjut normal (state lokal tidak
     butuh peran_multiplayer) sampai SERI -> lempar koin penentu: _saat_koin_seri_lokal_dipilih() cuma
     menangani peran_multiplayer == "host" atau "client" -- begitu peran jadi "", pilihan koin sendiri
     didiamkan (tidak match cabang mana pun), _koin_seri_wajib tidak pernah lunas, _tunggu_hasil_koin()
     menunggu selamanya -> `SELESAI MACET peran=host giliran=2`.
     Perbaikan (pemain.gd, satu fungsi _saat_koin_seri_lokal_dipilih): cabang dibalik jadi
     `if peran == "client": rpc_id(...) else: _terima_pilihan_koin(...)` -- device yang bukan "client"
     (host ATAU sudah "" karena baru mengambil alih) tetap memproses pilihan koinnya sendiri secara
     lokal, bukan didiamkan. Diuji ulang persis (seed=32 giliran=25 keluar=8 keluar_urut=1):
     `SELESAI BATAS_GILIRAN peran=host giliran=26 ... scripterr=0 | beda=0`, tie-break "SCORE TIED!
     CHOOSE YOUR COIN GUESS!" lanjut normal (bukan macet lagi) sampai akhir giliran.
     D3/D4 (host keluar, client jadi satu-satunya manusia -- kebalikan dari D2) TIDAK menunjukkan
     gejala serupa pada seed yang diuji walau pola kodenya sejenis (_saat_koin_seri_lokal_dipilih tetap
     dipakai di kedua arah) -- kemungkinan besar karena seed itu tidak kebetulan berakhir SERI saat
     client jadi satu-satunya manusia; catatan untuk uji lanjutan kalau ingin dipastikan lebih jauh.
