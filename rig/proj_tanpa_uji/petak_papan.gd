extends Node3D
class_name PetakPapan

@export_category("Sistem Navigasi Cabang")
@export var petak_selanjutnya: Array[NodePath]
@export var nama_arah: Array[String]

@export_category("Tipe Petak Khusus")
@export var is_start_point: bool = false
@export var is_di_atas_air: bool = false

@export_group("Pengaturan Permata (Misi)")
@export var is_petak_permata: bool = false
@export_enum("Hijau", "Kuning", "Biru") var pilihan_warna_permata: int = 0
var nama_warna_permata: String:
	get:
		match pilihan_warna_permata:
			0: return "[img=28]res://permata/permata_hijau.png[/img]"
			1: return "[img=28]res://permata/permata_kuning.png[/img]"
			2: return "[img=28]res://permata_biru.png[/img]"
		return "[img=28]res://permata_hijau.png[/img]"
@export var warna_cahaya_permata: Color = Color(0.0, 0.8, 1.0)

# =======================================================
# TAMBAHAN BARU: SISTEM PETAK KARTU ACAK
# =======================================================
@export_group("Pengaturan Kartu Gacha")
@export var is_petak_kartu: bool = false
var node_sistem_kartu: Node3D # <--- Tempat menyimpan referensi skrip kartu

var referensi_node_selanjutnya: Array[Node3D] = []
var node_visual_permata: Node3D 

func _ready():
	add_to_group("grup_petak_papan")
	
	if is_petak_permata:
		node_visual_permata = PetakPermata.new() 
		node_visual_permata.nama_warna = nama_warna_permata
		node_visual_permata.warna_permata = warna_cahaya_permata
		add_child(node_visual_permata)
		
	# LOGIKA INJEKSI PETAK KARTU
	if is_petak_kartu:
		var script_kartu = load("res://petak_kartu.gd")
		if script_kartu:
			node_sistem_kartu = script_kartu.new()
			add_child(node_sistem_kartu)

# =======================================================
# FUNGSI BARU UNTUK MEMICU EFEK DARI SKRIP PEMAIN
# =======================================================
func mainkan_efek_permata():
	if node_visual_permata and node_visual_permata.has_method("mainkan_efek_koleksi"):
		node_visual_permata.mainkan_efek_koleksi()
