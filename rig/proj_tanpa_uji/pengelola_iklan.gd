extends Node
# STUB KHUSUS RIG UJI (bukan file game).
# pengelola_iklan.gd yang asli memakai kelas dari plugin AdMob yang tidak ada di
# lingkungan uji, jadi autoload-nya gagal dimuat dan setiap pemanggilan
# PengelolaIklan.* akan error. File ini menirukan antarmukanya saja.
signal iklan_ditutup(dapat_hadiah: bool)

# --- Fase 1: penghitung & saklar untuk robot uji ---
var jumlah_interstisial := 0
var jumlah_match_tuntas := 0
var jumlah_rewarded := 0
var uji_rewarded := false          # true = iklan berhadiah "tersedia" & selalu memberi hadiah
var uji_tonton_gagal := false      # Fase 5 G5: true = "tersedia" tapi tonton_rewarded() gagal (tidak ada iklan saat ditekan)
var bebas_iklan := false           # Fase 7 G4: sama dgn pengelola_iklan.gd asli (diatur PengelolaPembelian)
var jumlah_banner := 0
var uji_jeda_interstisial := 0.0   # > 0 = interstisial pura-pura tampil selama sekian detik

func tampilkan_banner() -> void:
	if bebas_iklan:
		return
	jumlah_banner += 1

func sembunyikan_banner() -> void:
	pass

func mulai_proses_iklan(_apa = null) -> void:
	emit_signal("iklan_ditutup", false)

func catat_match_tuntas() -> void:
	jumlah_match_tuntas += 1

func tampilkan_interstisial_akhir_match() -> void:
	if bebas_iklan:
		return
	jumlah_interstisial += 1
	if uji_jeda_interstisial > 0.0:
		await get_tree().create_timer(uji_jeda_interstisial).timeout

func rewarded_tersedia() -> bool:
	return uji_rewarded

func tonton_rewarded() -> bool:
	jumlah_rewarded += 1
	await get_tree().create_timer(0.2).timeout
	return uji_rewarded and not uji_tonton_gagal
