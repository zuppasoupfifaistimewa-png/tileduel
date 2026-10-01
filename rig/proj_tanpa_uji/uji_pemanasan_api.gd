extends Node
func _ready():
	var api = preload("res://jebakan_api.gd").new()
	add_child(api)
	# _ready() sudah jalan (add_child memicunya). Cek baseline SEBELUM warmup disentuh.
	print("UJI baseline node_nuklir valid: ", is_instance_valid(api.node_nuklir))
	print("UJI baseline node_nuklir.visible (harus false / disembunyikan): ", api.node_nuklir.visible)
	print("UJI baseline mat_ledakan valid: ", api.mat_ledakan != null)
	print("UJI baseline mat_gelombang valid: ", api.mat_gelombang != null)
	print("UJI baseline dasar.material_override == mat_ledakan: ", api.dasar.material_override == api.mat_ledakan)
	print("UJI baseline batang.material_override == mat_ledakan: ", api.batang.material_override == api.mat_ledakan)
	print("UJI baseline kepala.material_override == mat_ledakan: ", api.kepala.material_override == api.mat_ledakan)
	print("UJI baseline gelombang.material_override == mat_gelombang: ", api.gelombang.material_override == api.mat_gelombang)
	print("UJI baseline kilat (OmniLight3D) valid: ", is_instance_valid(api.kilat))

	# Simulasikan persis baris baru yang ditambahkan ke _pemanasan_shader():
	if is_instance_valid(api.node_nuklir):
		api.node_nuklir.show()
	print("UJI setelah show() node_nuklir.visible: ", api.node_nuklir.visible)
	# Anak-anaknya tidak disentuh individual -> harus tetap default true, jadi
	# subtree BENAR-BENAR akan tergambar (visible in tree = AND semua leluhur).
	print("UJI dasar.visible (individu, harus tetap true): ", api.dasar.visible)
	print("UJI batang.visible (individu, harus tetap true): ", api.batang.visible)
	print("UJI kepala.visible (individu, harus tetap true): ", api.kepala.visible)
	print("UJI gelombang.visible (individu, harus tetap true): ", api.gelombang.visible)
	print("UJI is_visible_in_tree dasar (gabungan leluhur, HARUS true sekarang): ", api.dasar.is_visible_in_tree())

	# mode_residu = true HARUS tetap melewati (skip) pembuatan node_nuklir sama
	# sekali -- jalur efek residu paralisis/terbakar TIDAK BOLEH terpengaruh.
	var api_residu = preload("res://jebakan_api.gd").new()
	api_residu.mode_residu = true
	add_child(api_residu)
	print("UJI mode_residu=true: node_nuklir TIDAK dibuat (harus null): ", api_residu.node_nuklir == null)
	print("UJI mode_residu=true: mat_asap_cache tetap dibuat (dipakai proses_penderitaan_giliran): ", api_residu.mat_asap_cache != null)

	get_tree().quit()
