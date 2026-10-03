extends Node
# Fase 3: seperti cek_muat.gd + 6 file pecahan pemain.gd (file @abstract dianggap OK).
# Fase 4 Langkah A: +4 file baru (data_role.gd, pemain_role.gd, ai_jebakan.gd, ui_role.gd)
# -- 22 file Fase 3 + 4 = 26 file set kiriman.
const DAFTAR = ["status_jaringan.gd", "pengelola_iklan.gd", "profil_pemain.gd", "ui_profil.gd", "ui_toko.gd", "ui_role.gd", "data_pemain.gd", "data_role.gd", "ui_elemen.gd", "ui_petak.gd", "petak_kartu.gd", "ai_musuh.gd", "ai_jebakan.gd", "jebakan_air.gd", "jebakan_api.gd", "migrasi_host.gd", "ui_dinamis.gd", "pemain_dasar.gd", "pemain_tampilan.gd", "pemain_role.gd", "pemain_papan.gd", "pemain_kartu.gd", "pemain_duel.gd", "pemain_jaringan.gd", "pemain.gd", "main_menu.gd", "layar_local_play.gd"]
func _ready():
	for f in DAFTAR:
		printerr("### MUAT ", f)
		var s = ResourceLoader.load("res://" + f, "", ResourceLoader.CACHE_MODE_IGNORE)
		var ok = s != null and (s.can_instantiate() or (s.has_method("is_abstract") and s.is_abstract()))
		printerr("### HASIL ", f, " ", "OK" if ok else "GAGAL")
	get_tree().quit()
