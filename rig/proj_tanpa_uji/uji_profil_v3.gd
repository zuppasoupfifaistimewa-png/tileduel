extends Node
# Fase 6 G0 (rig-only): profil VERSI 2 dimuat -> respect/mvp_total = 0, data lama utuh; VERSI 3 disimpan & dimuat ulang;
# nilai rusak tidak merusak; tambah_respect/catat_mvp tersimpan. Berkas profil sungguhan TIDAK disentuh kalau HOME diarahkan ke folder uji.
func _ready() -> void:
	var gagal := 0
	var P = ProfilPemain
	# 1) berkas VERSI 2 (tanpa bagian "sosial")
	var c = ConfigFile.new()
	c.set_value("profil", "versi", 2)
	c.set_value("profil", "id", "abcdef0123456789")
	c.set_value("profil", "nama", "Lama Okay")
	c.set_value("profil", "xp", 777)
	c.set_value("profil", "crowns", 321)
	c.set_value("statistik", "isi", {"menang": 5})
	c.set_value("role", "terakhir", "api")
	c.save(P.BERKAS)
	P.muat()
	gagal += _cek("v2 id utuh", P.id == "abcdef0123456789")
	gagal += _cek("v2 nama utuh", P.nama == "Lama Okay")
	gagal += _cek("v2 xp utuh", P.xp_total == 777)
	gagal += _cek("v2 crowns utuh", P.crowns == 321)
	gagal += _cek("v2 statistik utuh", int(P.statistik.get("menang", 0)) == 5)
	gagal += _cek("v2 role utuh", P.role_terakhir == "api")
	gagal += _cek("v2 respect=0", P.respect == 0)
	gagal += _cek("v2 mvp_total=0", P.mvp_total == 0)
	# 2) simpan -> berkas VERSI 3
	P.tambah_respect()
	P.tambah_respect()
	P.catat_mvp()
	var c2 = ConfigFile.new()
	c2.load(P.BERKAS)
	gagal += _cek("simpan versi=3", int(c2.get_value("profil", "versi", 0)) == 3 and P.VERSI == 3)
	gagal += _cek("simpan respect=2", int(c2.get_value("sosial", "respect", -1)) == 2)
	gagal += _cek("simpan mvp=1", int(c2.get_value("sosial", "mvp_total", -1)) == 1)
	P.respect = 0
	P.mvp_total = 0
	P.muat()
	gagal += _cek("muat ulang v3 respect=2", P.respect == 2)
	gagal += _cek("muat ulang v3 mvp=1", P.mvp_total == 1)
	gagal += _cek("muat ulang v3 data lama utuh", P.xp_total == 777 and P.crowns == 321 and P.nama == "Lama Okay")
	# 3) nilai rusak / negatif
	var c3 = ConfigFile.new()
	c3.load(P.BERKAS)
	c3.set_value("sosial", "respect", -5)
	c3.set_value("sosial", "mvp_total", "abc")
	c3.save(P.BERKAS)
	P.muat()
	gagal += _cek("rusak -> respect 0", P.respect == 0)
	gagal += _cek("rusak -> mvp 0", P.mvp_total == 0)
	# 4) profil baru
	DirAccess.remove_absolute(P.BERKAS)
	DirAccess.remove_absolute(P.BERKAS_SEMENTARA)
	DirAccess.remove_absolute(P.BERKAS_CADANGAN)
	P.muat()
	gagal += _cek("baru id terisi (16 hex)", P.id.length() == 16)
	gagal += _cek("baru respect/mvp 0", P.respect == 0 and P.mvp_total == 0)
	# 5) G2: hitung_mvp -- penghargaan terbanyak; seri -> pemenang (baris pertama); masih seri -> slot terkecil
	var papan_a = [{"slot": 2, "penghargaan": ["a"]}, {"slot": 0, "penghargaan": ["a", "b"]}, {"slot": 1, "penghargaan": ["a", "b"]}]
	gagal += _cek("mvp terbanyak (seri 2, pemenang bukan salah satunya) -> slot terkecil", P.hitung_mvp(papan_a) == 0)
	var papan_b = [{"slot": 1, "penghargaan": ["a", "b"]}, {"slot": 0, "penghargaan": ["a", "b"]}]
	gagal += _cek("mvp seri -> pemenang", P.hitung_mvp(papan_b) == 1)
	var papan_c = [{"slot": 1, "penghargaan": []}, {"slot": 0, "penghargaan": []}]
	gagal += _cek("mvp tanpa penghargaan -> pemenang", P.hitung_mvp(papan_c) == 1)
	var papan_d = [{"slot": 1, "penghargaan": ["a"]}, {"slot": 0, "penghargaan": ["a", "b", "c"]}, {"slot": 2, "penghargaan": []}]
	gagal += _cek("mvp jelas terbanyak", P.hitung_mvp(papan_d) == 0)
	gagal += _cek("mvp papan kosong -> -1", P.hitung_mvp([]) == -1)
	print("PROFIL_V3 gagal=", gagal)
	get_tree().quit()

func _cek(nama: String, ok: bool) -> int:
	print("PROFIL_V3 ", "OK   " if ok else "GAGAL", " ", nama)
	return 0 if ok else 1
