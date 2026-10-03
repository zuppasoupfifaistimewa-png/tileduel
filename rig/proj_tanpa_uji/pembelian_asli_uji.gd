extends Node
# Fase 7 G4: pembelian Remove Ads (Google Play Billing). AUTOLOAD bernama PengelolaPembelian
# (daftarkan di Project Settings > Autoload; urutan bebas -- kerja dimulai satu frame setelah semua autoload siap).
#
# Memakai plugin "GodotGooglePlayBilling" (godot-sdk-integrations/godot-google-play-billing, Godot 4.2+) LEWAT
# Engine.get_singleton -- TANPA mengacu kelas plugin, jadi tanpa plugin (editor, desktop, rig) skrip tetap
# terkompilasi dan jalan sebagai MODE STUB: tidak pernah crash, tidak pernah membeli.
#
# Aturan (RENCANA_fase6_9 F7.5, K5=a): bebas_iklan mematikan interstisial + app open + banner; iklan berhadiah
# tetap (pilihan pemain). Sumber kebenaran = query Play; profil (remove_ads) hanya cadangan saat offline.
# Pembelian baru WAJIB di-acknowledge (kalau tidak, Play mengembalikan dana setelah 3 hari).
# Bonus 500 Crowns sekali per profil, hanya untuk pembelian BARU (belum di-acknowledge), bukan restore.

signal status_berubah(punya: bool)
signal pembelian_selesai(berhasil: bool, pesan: String)

const ID_PRODUK := "remove_ads"          # produk non-consumable di Play Console
const BONUS_CROWNS := 500
const NAMA_PLUGIN := "GodotGooglePlayBilling"
const JENIS_INAPP := "inapp"
const KODE_OK := 0
const KODE_BATAL := 1
const KODE_SUDAH_DIMILIKI := 7
const STATUS_DIBELI := 1                 # Purchase.PurchaseState.PURCHASED (2 = PENDING)

var mode_stub := true                    # true = tidak ada plugin (editor/desktop/rig)
var _plugin = null
var _tersambung := false
var _detail_siap := false
var _harga := ""
var _sedang_beli := false
var _bonus_baru := false                 # true = pemanggilan _proses_pembelian terakhir memberi bonus

func _ready() -> void:
	# Autoload lain (PengelolaIklan, ProfilPemain) mungkin belum masuk pohon -> mulai sesudah frame ini.
	_mulai.call_deferred()

func _mulai() -> void:
	# Cadangan profil berlaku dulu (iklan tidak muncul selagi query Play berjalan).
	_terapkan(ProfilPemain.remove_ads)
	if Engine.has_singleton(NAMA_PLUGIN):
		_sambungkan_plugin(Engine.get_singleton(NAMA_PLUGIN))

func _sambungkan_plugin(plugin) -> void:
	# Dipisah dari _mulai supaya rig bisa memasang plugin TIRUAN.
	_plugin = plugin
	mode_stub = false
	_pasang_sinyal("connected", _saat_tersambung)
	_pasang_sinyal("disconnected", _saat_putus)
	_pasang_sinyal("connect_error", _saat_gagal_sambung)
	_pasang_sinyal("query_product_details_response", _saat_detail_produk)
	_pasang_sinyal("query_purchases_response", _saat_daftar_pembelian)
	_pasang_sinyal("on_purchase_updated", _saat_pembelian_berubah)
	_pasang_sinyal("acknowledge_purchase_response", _saat_acknowledge)
	_plugin.startConnection()

func _pasang_sinyal(nama: String, penerima: Callable) -> void:
	if _plugin.has_signal(nama):
		_plugin.connect(nama, penerima)

# ==========================================
# API UNTUK UI
# ==========================================
func punya_remove_ads() -> bool:
	return ProfilPemain.remove_ads

func harga_remove_ads() -> String:
	# Harga berformat dari Play (mis. "$2.99"); "" kalau belum diketahui / mode stub.
	return _harga

func toko_tersedia() -> bool:
	return not mode_stub and _tersambung and _detail_siap

func beli_remove_ads() -> void:
	# Hasil lewat sinyal pembelian_selesai(berhasil, pesan). Tidak pernah melempar error.
	if punya_remove_ads():
		_kabari(true, "Remove Ads is already active.")
	elif mode_stub:
		_kabari(false, "Store is not available on this device.")
	elif _sedang_beli:
		_kabari(false, "Purchase in progress...")
	elif not toko_tersedia():
		restore()
		_kabari(false, "Store is not ready. Try again in a moment.")
	else:
		_sedang_beli = true
		var hasil = _plugin.purchase(ID_PRODUK, "", "", false)
		if not (hasil is Dictionary) or int(hasil.get("response_code", -1)) != KODE_OK:
			_sedang_beli = false
			_kabari(false, "Purchase failed. Please try again.")

func restore() -> void:
	# Tanya ulang Play. Dipanggil otomatis saat tersambung; boleh juga dari tombol "Restore".
	if _plugin != null and _tersambung:
		_plugin.queryPurchases(JENIS_INAPP, false)

# ==========================================
# SINYAL PLUGIN
# ==========================================
func _saat_tersambung() -> void:
	_tersambung = true
	_plugin.queryProductDetails(PackedStringArray([ID_PRODUK]), JENIS_INAPP)
	_plugin.queryPurchases(JENIS_INAPP, false)

func _saat_putus() -> void:
	_tersambung = false
	_detail_siap = false

func _saat_gagal_sambung(_kode = 0, _pesan = "") -> void:
	_tersambung = false # offline: cadangan profil tetap berlaku

func _saat_detail_produk(hasil: Dictionary) -> void:
	if int(hasil.get("response_code", -1)) != KODE_OK:
		return
	for detail in hasil.get("product_details", []):
		if not (detail is Dictionary) or str(detail.get("product_id", "")) != ID_PRODUK:
			continue
		_detail_siap = true
		var daftar = detail.get("one_time_purchase_offer_details_list", null)
		if daftar is Array and not daftar.is_empty() and daftar[0] is Dictionary:
			_harga = str(daftar[0].get("formatted_price", ""))

func _saat_daftar_pembelian(hasil: Dictionary) -> void:
	# Query gagal (offline dll.) -> JANGAN mencabut apa pun; cadangan profil dipakai.
	if int(hasil.get("response_code", -1)) != KODE_OK:
		return
	var punya = _proses_pembelian(hasil.get("purchases", []))
	_terapkan(punya) # Play = sumber kebenaran: refund/tidak ada -> dicabut

func _saat_pembelian_berubah(hasil: Dictionary) -> void:
	var kode = int(hasil.get("response_code", -1))
	_sedang_beli = false
	if kode == KODE_OK:
		if _proses_pembelian(hasil.get("purchases", [])):
			_terapkan(true)
			_kabari(true, "Thank you! Ads removed. +%d Crowns" % BONUS_CROWNS if _bonus_baru else "Thank you! Ads removed.")
		else:
			_kabari(false, "Payment is pending. Ads will be removed when it completes.")
	elif kode == KODE_BATAL:
		_kabari(false, "Purchase cancelled.")
	elif kode == KODE_SUDAH_DIMILIKI:
		restore() # sudah dibeli (mis. di HP lain / balasan hilang): sinkronkan
		_kabari(false, "You already own this. Restoring...")
	else:
		_kabari(false, "Purchase failed. Please try again.")

func _saat_acknowledge(_hasil: Dictionary) -> void:
	pass # gagal -> pembelian tetap belum di-acknowledge, dicoba lagi tiap query (tiap start)

# ==========================================
# INTI
# ==========================================
func _proses_pembelian(daftar) -> bool:
	# true = ada pembelian remove_ads berstatus DIBELI. Pembelian belum di-acknowledge = BARU:
	# bonus (sekali) + acknowledge.
	_bonus_baru = false
	var punya = false
	if not (daftar is Array):
		return false
	for p in daftar:
		if not (p is Dictionary) or int(p.get("purchase_state", 0)) != STATUS_DIBELI:
			continue
		if not (ID_PRODUK in p.get("product_ids", [])):
			continue
		punya = true
		if not bool(p.get("is_acknowledged", false)):
			_bonus_baru = ProfilPemain.ambil_bonus_remove_ads(BONUS_CROWNS)
			var token = str(p.get("purchase_token", ""))
			if token != "" and _plugin != null:
				_plugin.acknowledgePurchase(token)
	return punya

func _terapkan(punya: bool) -> void:
	var berubah = PengelolaIklan.bebas_iklan != punya or ProfilPemain.remove_ads != punya
	ProfilPemain.atur_remove_ads(punya)
	PengelolaIklan.bebas_iklan = punya
	if punya:
		PengelolaIklan.sembunyikan_banner()
	if berubah:
		status_berubah.emit(punya)

func _kabari(berhasil: bool, pesan: String) -> void:
	pembelian_selesai.emit.call_deferred(berhasil, pesan)
