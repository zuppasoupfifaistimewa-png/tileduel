extends Node
# STUB KHUSUS RIG UJI (bukan file game) -- JANGAN disalin ke game/.
# Autoload PengelolaPembelian di rig: tanpa plugin Play Billing, sama seperti mode stub file asli.
# Logika asli diuji lewat salinan pembelian_asli_uji.gd (uji_pembelian.gd) dengan plugin tiruan.
signal status_berubah(punya: bool)
signal pembelian_selesai(berhasil: bool, pesan: String)

var mode_stub := true

func punya_remove_ads() -> bool:
	return ProfilPemain.remove_ads

func harga_remove_ads() -> String:
	return ""

func toko_tersedia() -> bool:
	return false

func beli_remove_ads() -> void:
	pembelian_selesai.emit.call_deferred(false, "Store is not available on this device.")

func restore() -> void:
	pass
