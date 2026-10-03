extends Node
# Fase 7 G4 (rig-only): pengelola_pembelian.gd ASLI (salinan pembelian_asli_uji.gd) -- mode stub tanpa plugin,
# alur beli/acknowledge/bonus/refund/offline dengan plugin TIRUAN, dan bebas_iklan mematikan interstisial + banner.
# Jalankan dengan HOME terpisah supaya profil sungguhan tidak tersentuh.
const ASLI := preload("res://pembelian_asli_uji.gd")

class PluginTiruan extends RefCounted:
	signal connected
	signal disconnected
	signal connect_error(kode, pesan)
	signal query_product_details_response(hasil)
	signal query_purchases_response(hasil)
	signal on_purchase_updated(hasil)
	signal acknowledge_purchase_response(hasil)
	var daftar_beli: Array = []          # jawaban queryPurchases
	var kode_query := 0
	var kode_beli := 0                   # response_code balasan purchase() langsung
	var beli_otomatis: Dictionary = {}   # kalau tidak kosong: dikirim lewat on_purchase_updated saat purchase()
	var token_ack: Array = []
	var jumlah_koneksi := 0
	var jumlah_beli := 0
	func startConnection() -> void:
		jumlah_koneksi += 1
	func queryProductDetails(_ids, _jenis) -> void:
		query_product_details_response.emit({"response_code": 0, "product_details": [{"product_id": "remove_ads", "one_time_purchase_offer_details_list": [{"formatted_price": "$2.99"}]}]})
	func queryPurchases(_jenis, _susp) -> void:
		var h = {"response_code": kode_query}
		if kode_query == 0:
			h["purchases"] = daftar_beli
		query_purchases_response.emit(h)
	func purchase(_id, _opsi, _offer, _pers) -> Dictionary:
		jumlah_beli += 1
		if kode_beli == 0 and not beli_otomatis.is_empty():
			on_purchase_updated.emit.call_deferred(beli_otomatis)
		return {"response_code": kode_beli}
	func acknowledgePurchase(token) -> void:
		token_ack.append(token)
		acknowledge_purchase_response.emit({"response_code": 0, "token": token})

var _gagal := 0
var _selesai: Array = []

func _ready() -> void:
	await get_tree().process_frame
	var P = ProfilPemain
	var I = PengelolaIklan
	DirAccess.remove_absolute(P.BERKAS)
	P.muat()
	P.remove_ads = false
	P.bonus_remove_ads_diambil = false
	I.bebas_iklan = false

	# 0) salinan rig identik dgn game/
	var asli = FileAccess.get_file_as_string("res://pembelian_asli_uji.gd")
	var game = FileAccess.get_file_as_string(ProjectSettings.globalize_path("res://") + "../../game/pengelola_pembelian.gd")
	_cek("salinan asli identik dgn game/pengelola_pembelian.gd", asli != "" and asli == game)
	_cek("autoload stub rig ada, mode_stub", PengelolaPembelian.mode_stub and not PengelolaPembelian.punya_remove_ads())
	PengelolaPembelian.beli_remove_ads()
	await get_tree().process_frame

	# 1) file ASLI tanpa plugin = mode stub, tidak crash
	var m = _baru()
	await get_tree().process_frame
	await get_tree().process_frame
	_cek("tanpa plugin: mode_stub true", m.mode_stub and not m.toko_tersedia() and m.harga_remove_ads() == "")
	_selesai.clear()
	m.pembelian_selesai.connect(func(ok, pesan): _selesai.append([ok, pesan]))
	m.beli_remove_ads()
	m.restore()
	await get_tree().process_frame
	await get_tree().process_frame
	_cek("tanpa plugin: beli ditolak sopan", _selesai.size() == 1 and _selesai[0][0] == false and not m.punya_remove_ads() and not I.bebas_iklan)
	m.queue_free()

	# 2) interstisial & banner: hanya hilang saat bebas_iklan
	var n0 = I.jumlah_interstisial
	var b0 = I.jumlah_banner
	await I.tampilkan_interstisial_akhir_match()
	I.tampilkan_banner()
	_cek("bebas_iklan=false: interstisial & banner tayang", I.jumlah_interstisial == n0 + 1 and I.jumlah_banner == b0 + 1)

	# 3) cadangan profil: remove_ads=true di profil -> bebas_iklan langsung (offline / tanpa plugin)
	P.atur_remove_ads(true)
	m = _baru()
	await get_tree().process_frame
	await get_tree().process_frame
	_cek("cadangan profil -> bebas_iklan true", I.bebas_iklan and m.punya_remove_ads())
	n0 = I.jumlah_interstisial
	b0 = I.jumlah_banner
	await I.tampilkan_interstisial_akhir_match()
	I.tampilkan_banner()
	_cek("bebas_iklan=true: TIDAK ada interstisial & banner", I.jumlah_interstisial == n0 and I.jumlah_banner == b0)
	_cek("iklan berhadiah tetap (pilihan pemain)", I.rewarded_tersedia() == I.uji_rewarded)
	m.queue_free()
	P.atur_remove_ads(false)
	I.bebas_iklan = false

	# 4) plugin tiruan: kondisi awal belum punya -> detail & harga
	var f = PluginTiruan.new()
	m = _baru()
	await get_tree().process_frame
	await get_tree().process_frame
	m._sambungkan_plugin(f)
	f.connected.emit()
	_cek("plugin: startConnection dipanggil, mode bukan stub", f.jumlah_koneksi == 1 and not m.mode_stub)
	_cek("plugin: toko tersedia, harga $2.99, belum punya", m.toko_tersedia() and m.harga_remove_ads() == "$2.99" and not m.punya_remove_ads() and not I.bebas_iklan)

	# 5) beli sukses: acknowledge + bonus 500 sekali
	var c0 = P.crowns
	_selesai.clear()
	m.pembelian_selesai.connect(func(ok, pesan): _selesai.append([ok, pesan]))
	var sts: Array = []
	m.status_berubah.connect(func(p): sts.append(p))
	f.beli_otomatis = {"response_code": 0, "purchases": [{"product_ids": ["remove_ads"], "purchase_state": 1, "is_acknowledged": false, "purchase_token": "tok1"}]}
	m.beli_remove_ads()
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	_cek("beli: purchase() dipanggil sekali", f.jumlah_beli == 1)
	_cek("beli: acknowledge dengan token benar", f.token_ack == ["tok1"])
	_cek("beli: punya + bebas_iklan + profil", m.punya_remove_ads() and I.bebas_iklan and P.remove_ads)
	_cek("beli: bonus 500 Crowns tepat sekali", P.crowns == c0 + 500 and P.bonus_remove_ads_diambil)
	_cek("beli: sinyal selesai ok + status_berubah true", _selesai.size() == 1 and _selesai[0][0] == true and sts == [true])
	# berkas profil ikut tersimpan
	var cf = ConfigFile.new()
	cf.load(P.BERKAS)
	_cek("beli: berkas profil tersimpan (remove_ads, bonus)", bool(cf.get_value("pembelian", "remove_ads", false)) and bool(cf.get_value("pembelian", "bonus_diambil", false)) and int(cf.get_value("profil", "crowns", 0)) == c0 + 500)

	# 6) restore pembelian yang SUDAH di-acknowledge: tanpa bonus, tanpa acknowledge ulang
	f.daftar_beli = [{"product_ids": ["remove_ads"], "purchase_state": 1, "is_acknowledged": true, "purchase_token": "tok1"}]
	m.restore()
	await get_tree().process_frame
	_cek("restore: tetap punya, tanpa bonus & tanpa ack baru", m.punya_remove_ads() and P.crowns == c0 + 500 and f.token_ack.size() == 1)
	# pembelian BARU kedua kali (mis. profil sama, setelah refund) -> tetap tanpa bonus lagi
	f.daftar_beli = [{"product_ids": ["remove_ads"], "purchase_state": 1, "is_acknowledged": false, "purchase_token": "tok2"}]
	m.restore()
	await get_tree().process_frame
	_cek("belum di-ack lagi: di-ack ulang, bonus TIDAK dobel", f.token_ack == ["tok1", "tok2"] and P.crowns == c0 + 500)

	# 7) query gagal (offline): cadangan dipertahankan
	f.kode_query = 2
	m.restore()
	await get_tree().process_frame
	_cek("query gagal: tidak dicabut", m.punya_remove_ads() and I.bebas_iklan)

	# 8) refund / tidak ada pembelian: dicabut (Play = sumber kebenaran)
	f.kode_query = 0
	f.daftar_beli = []
	m.restore()
	await get_tree().process_frame
	_cek("daftar kosong: dicabut (bebas_iklan false, profil false)", not m.punya_remove_ads() and not I.bebas_iklan and not P.remove_ads and sts.back() == false)
	n0 = I.jumlah_interstisial
	await I.tampilkan_interstisial_akhir_match()
	_cek("setelah dicabut: interstisial tayang lagi", I.jumlah_interstisial == n0 + 1)

	# 9) dibatalkan, tertunda (pending), gagal langsung, error lain
	_selesai.clear()
	f.beli_otomatis = {"response_code": 1}
	m.beli_remove_ads()
	await get_tree().process_frame
	await get_tree().process_frame
	_cek("batal: pesan 'cancelled', tetap belum punya", _selesai.size() == 1 and _selesai[0][0] == false and "cancelled" in _selesai[0][1] and not m.punya_remove_ads())
	_selesai.clear()
	f.beli_otomatis = {"response_code": 0, "purchases": [{"product_ids": ["remove_ads"], "purchase_state": 2, "is_acknowledged": false, "purchase_token": "tok3"}]}
	var ack0 = f.token_ack.size()
	m.beli_remove_ads()
	await get_tree().process_frame
	await get_tree().process_frame
	_cek("pending: belum dianggap punya, tanpa ack/bonus", _selesai.size() == 1 and not _selesai[0][0] and not m.punya_remove_ads() and f.token_ack.size() == ack0 and P.crowns == c0 + 500)
	_selesai.clear()
	f.beli_otomatis = {}
	f.kode_beli = 6
	m.beli_remove_ads()
	await get_tree().process_frame
	await get_tree().process_frame
	_cek("purchase() langsung gagal: pesan gagal & bisa coba lagi", _selesai.size() == 1 and not _selesai[0][0] and not m._sedang_beli)
	f.kode_beli = 0
	_selesai.clear()
	f.beli_otomatis = {"response_code": 7}
	f.daftar_beli = [{"product_ids": ["remove_ads"], "purchase_state": 1, "is_acknowledged": true, "purchase_token": "tok1"}]
	m.beli_remove_ads()
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	_cek("sudah dimiliki (kode 7): disinkronkan lewat query", m.punya_remove_ads() and I.bebas_iklan)
	# beli saat sudah punya
	_selesai.clear()
	var jb = f.jumlah_beli
	m.beli_remove_ads()
	await get_tree().process_frame
	await get_tree().process_frame
	_cek("beli saat sudah punya: tidak memanggil purchase()", f.jumlah_beli == jb and _selesai.size() == 1 and _selesai[0][0])

	# 10) putus sambungan: tidak crash, cadangan tetap
	f.disconnected.emit()
	f.connect_error.emit(3, "x")
	_cek("putus/gagal sambung: tidak crash, status tetap", m.punya_remove_ads() and not m.toko_tersedia())
	m.queue_free()
	P.atur_remove_ads(false)
	I.bebas_iklan = false

	print("PEMBELIAN gagal=", _gagal)
	get_tree().quit()

func _baru() -> Node:
	var m = ASLI.new()
	add_child(m)
	return m

func _cek(nama: String, ok: bool) -> void:
	if not ok:
		_gagal += 1
	print("PEMBELIAN ", "OK   " if ok else "GAGAL", " ", nama)
