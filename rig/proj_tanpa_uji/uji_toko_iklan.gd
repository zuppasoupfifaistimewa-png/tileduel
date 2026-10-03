extends Node
# Fase 7 G5 (rig-only): baris REMOVE ADS di layar SHOP. Autoload stub rig, lalu pengelola ASLI (salinan) + plugin tiruan, lalu tanpa autoload.
const ASLI := preload("res://pembelian_asli_uji.gd")
const TIRUAN := preload("res://uji_pembelian.gd")
var _gagal := 0

func _ready() -> void:
	await get_tree().process_frame
	var P = ProfilPemain
	var I = PengelolaIklan
	DirAccess.remove_absolute(P.BERKAS)
	P.muat()
	P.crowns = 100
	P.remove_ads = false
	P.bonus_remove_ads_diambil = false
	I.bebas_iklan = false
	var akar = get_tree().root
	var stub = akar.get_node("PengelolaPembelian")

	# 1) autoload stub rig: baris ada, BUY -> pesan "tidak tersedia" (merah), tidak crash
	UiToko.buka_toko(self)
	await _frame()
	var kv = get_node_or_null("PanelToko")
	_cek("stub: baris REMOVE ADS tampil", kv != null and _cari(kv, "BarisRemoveAds") != null and _ada_teks(kv, "REMOVE ADS"))
	var buy = _tombol(_cari(kv, "BarisRemoveAds"), "BUY")
	var pulih = _tombol(_cari(kv, "BarisRemoveAds"), "RESTORE")
	_cek("stub: tombol BUY & RESTORE ada", buy != null and pulih != null)
	pulih.pressed.emit()
	buy.pressed.emit()
	await _frame()
	_cek("stub: pesan 'Store is not available on this device.'", _ada_teks(kv, "Store is not available on this device.") and not P.remove_ads and not I.bebas_iklan)
	kv.free()

	# 2) pengelola ASLI + plugin tiruan menggantikan autoload
	akar.remove_child(stub)
	var asli = ASLI.new()
	asli.name = "PengelolaPembelian"
	akar.add_child(asli)
	await _frame()
	var f = TIRUAN.PluginTiruan.new()
	asli._sambungkan_plugin(f)
	f.connected.emit()
	f.beli_otomatis = {"response_code": 0, "purchases": [{"product_ids": ["remove_ads"], "purchase_state": 1, "is_acknowledged": false, "purchase_token": "tokU"}]}
	UiToko.buka_toko(self)
	await _frame()
	kv = get_node_or_null("PanelToko")
	_cek("asli: tombol 'BUY $2.99' (harga dari Play)", _tombol(kv, "BUY $2.99") != null)
	_tombol(kv, "BUY $2.99").pressed.emit()
	for i in 4:
		await _frame()
	_cek("beli: bebas_iklan + profil + bonus 500", I.bebas_iklan and P.remove_ads and P.crowns == 600 and f.token_ack == ["tokU"])
	_cek("beli: baris jadi 'Ads removed. Thank you!', tombol BUY/RESTORE hilang", _ada_teks(kv, "Ads removed. Thank you!") and _tombol(kv, "RESTORE") == null and _tombol(kv, "BUY $2.99") == null)
	_cek("beli: pesan sukses tampil + label Crowns 600", _ada_teks(kv, "Thank you! Ads removed. +500 Crowns") and _ada_teks(kv, "CROWNS 600   |   Lv 1"))
	kv.free()

	# 3) refund diketahui saat panel terbuka -> baris digambar ulang
	UiToko.buka_toko(self)
	await _frame()
	kv = get_node("PanelToko")
	f.daftar_beli = []
	asli.restore()
	await _frame()
	await _frame()
	_cek("refund saat panel terbuka: baris kembali BUY", not I.bebas_iklan and _tombol(kv, "BUY $2.99") != null and _tombol(kv, "RESTORE") != null and not _ada_teks(kv, "Ads removed. Thank you!"))
	kv.free()

	# 4) tanpa autoload PengelolaPembelian: toko tetap terbuka, tanpa baris
	asli.free()
	UiToko.buka_toko(self)
	await _frame()
	kv = get_node_or_null("PanelToko")
	_cek("tanpa autoload: toko terbuka, tanpa baris Remove Ads", kv != null and _cari(kv, "BarisRemoveAds") == null and not _ada_teks(kv, "REMOVE ADS") and _tombol(kv, "CLOSE") != null)
	print("TOKO_IKLAN gagal=", _gagal)
	get_tree().quit()

func _frame() -> void:
	await get_tree().process_frame
	await get_tree().process_frame

func _semua(n: Node, hasil: Array) -> Array:
	hasil.append(n)
	for k in n.get_children():
		if not k.is_queued_for_deletion():
			_semua(k, hasil)
	return hasil

func _cari(akar: Node, nama: String) -> Node:
	for n in _semua(akar, []):
		if str(n.name) == nama:
			return n
	return null

func _tombol(akar: Node, teks: String) -> Button:
	if akar == null:
		return null
	for n in _semua(akar, []):
		if n is Button and n.text == teks:
			return n
	return null

func _ada_teks(akar: Node, teks: String) -> bool:
	for n in _semua(akar, []):
		if n is Label and n.text == teks:
			return true
	return false

func _cek(nama: String, ok: bool) -> void:
	if not ok:
		_gagal += 1
	print("TOKO_IKLAN ", "OK   " if ok else "GAGAL", " ", nama)
