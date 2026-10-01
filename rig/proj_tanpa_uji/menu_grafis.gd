extends CanvasLayer

var panel_utama: Panel
var btn_tutup: Button
var judul: Label
# --- TAMBAHAN VARIABEL FPS ---
var btn_fps: Button
var status_fps_nyala: bool = false
var btn_auto: Button
var sedang_mengukur: bool = false
var perlu_diterapkan: bool = false
var btn_manual: Button
var dropdown_kualitas: OptionButton

func _ready():
	layer = 100 
	
	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.8)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	
	panel_utama = Panel.new()
	panel_utama.custom_minimum_size = Vector2(450, 360)
	panel_utama.set_anchors_preset(Control.PRESET_CENTER)
	panel_utama.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel_utama.grow_vertical = Control.GROW_DIRECTION_BOTH
	# Digeser sedikit ke atas supaya tombol paling bawah tidak tertutup banner iklan
	panel_utama.position.y -= 60
	
	var style_panel = StyleBoxFlat.new()
	style_panel.bg_color = Color(0.1, 0.1, 0.15, 0.95)
	style_panel.corner_radius_top_left = 15
	style_panel.corner_radius_top_right = 15
	style_panel.corner_radius_bottom_right = 15
	style_panel.corner_radius_bottom_left = 15
	style_panel.border_width_top = 3
	style_panel.border_width_bottom = 3
	style_panel.border_width_left = 3
	style_panel.border_width_right = 3
	style_panel.border_color = Color(0.4, 0.6, 0.8)
	panel_utama.add_theme_stylebox_override("panel", style_panel)
	add_child(panel_utama)
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("margin_top", 20)
	vbox.add_theme_constant_override("separation", 20)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	panel_utama.add_child(vbox)
	
	# PERBAIKAN: Hubungkan ke variabel global
	judul = Label.new()
	judul.text = "⚙ GRAPHICS SETTINGS"
	judul.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	judul.add_theme_font_size_override("font_size", 26)
	vbox.add_child(judul)
	
	# ========================================================
	# BACA STATUS FPS DARI MEMORI SAAT MENU DIBUKA
	# ========================================================
	var config = ConfigFile.new()
	if config.load("user://seting_grafis.cfg") == OK:
		status_fps_nyala = config.get_value("Pengaturan", "tampilkan_fps", false)
		
	# BUAT TOMBOL TOGGLE FPS
	var teks_fps = "🟢 FPS Counter: ON" if status_fps_nyala else "🔴 FPS Counter: OFF"
	btn_fps = _buat_tombol(teks_fps, Color(0.2, 0.4, 0.6))
	btn_fps.pressed.connect(_toggle_fps)
	vbox.add_child(btn_fps)
	
	# TOMBOL AUTO DETECT
	btn_auto = _buat_tombol("🔍 AUTO DETECT (Recommended)", Color(0.15, 0.6, 0.55))
	btn_auto.pressed.connect(_jalankan_auto_detect)
	vbox.add_child(btn_auto)

	# BARIS MANUAL: tombol + dropdown di sampingnya.
	# Dipakai dropdown (bukan 4 tombol terpisah) supaya panelnya jauh lebih pendek
	# dan tombol Apply di bawah tidak tertutup banner iklan.
	var baris_manual = HBoxContainer.new()
	baris_manual.alignment = BoxContainer.ALIGNMENT_CENTER
	baris_manual.add_theme_constant_override("separation", 10)
	vbox.add_child(baris_manual)

	btn_manual = _buat_tombol("⚙ MANUAL", Color(0.4, 0.4, 0.5))
	btn_manual.custom_minimum_size = Vector2(150, 55)
	btn_manual.pressed.connect(_toggle_manual)
	baris_manual.add_child(btn_manual)

	dropdown_kualitas = OptionButton.new()
	dropdown_kualitas.custom_minimum_size = Vector2(190, 55)
	dropdown_kualitas.add_theme_font_size_override("font_size", 18)
	dropdown_kualitas.add_item("VERY LOW")
	dropdown_kualitas.add_item("LOW")
	dropdown_kualitas.add_item("MEDIUM")
	dropdown_kualitas.add_item("HIGH")
	dropdown_kualitas.hide() # muncul hanya setelah tombol MANUAL ditekan

	# Tampilkan setelan yang sedang aktif sebagai pilihan awal
	var urutan = ["sangat_rendah", "rendah", "sedang", "tinggi"]
	var idx_sekarang = urutan.find(AudioGrafis.baca_tingkat())
	if idx_sekarang != -1:
		dropdown_kualitas.select(idx_sekarang)

	dropdown_kualitas.item_selected.connect(_on_kualitas_dipilih)
	baris_manual.add_child(dropdown_kualitas)
	
	# ========================================================
	# MODIFIKASI TOMBOL TUTUP
	# ========================================================
	btn_tutup = _buat_tombol("Close", Color(0.3, 0.3, 0.3))
	# Hapus `queue_free()`, arahkan ke fungsi khusus
	btn_tutup.pressed.connect(_aksi_tutup_ditekan) 
	vbox.add_child(btn_tutup)
	
# --- FUNGSI-FUNGSI BARU UNTUK MENU GRAFIS ---

func _toggle_fps():
	status_fps_nyala = !status_fps_nyala
	btn_fps.text = "🟢 FPS Counter: ON" if status_fps_nyala else "🔴 FPS Counter: OFF"
	
	# Simpan pengaturan FPS seketika
	var config = ConfigFile.new()
	config.load("user://seting_grafis.cfg")
	config.set_value("Pengaturan", "tampilkan_fps", status_fps_nyala)
	config.save("user://seting_grafis.cfg")
	
	# Kirim sinyal langsung ke file pemain.gd untuk menampilkan/menyembunyikan teks FPS tanpa restart
	var grup_pemain = get_tree().get_nodes_in_group("grup_pemain")
	if grup_pemain.size() > 0:
		grup_pemain[0].atur_visibilitas_fps(status_fps_nyala)

func _toggle_manual():
	dropdown_kualitas.visible = not dropdown_kualitas.visible

func _on_kualitas_dipilih(indeks: int):
	var urutan = ["sangat_rendah", "rendah", "sedang", "tinggi"]
	if indeks < 0 or indeks >= urutan.size():
		return
	_terapkan_grafis(urutan[indeks])

func _jalankan_auto_detect():
	if sedang_mengukur:
		return
	sedang_mengukur = true

	var tingkat_sekarang = AudioGrafis.baca_tingkat()
	judul.text = "MEASURING... PLEASE WAIT"
	judul.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	btn_auto.text = "Measuring performance..."
	btn_auto.disabled = true

	var fps = await AudioGrafis.ukur_fps(self, 5.0)
	var tingkat_baru = AudioGrafis.tentukan_tingkat(fps, tingkat_sekarang)

	btn_auto.disabled = false
	sedang_mengukur = false

	if tingkat_baru == tingkat_sekarang:
		# Tidak ada yang berubah — tidak ada gunanya menyuruh pemain menutup game.
		judul.text = "ALREADY OPTIMAL (%d FPS)" % int(fps)
		judul.add_theme_color_override("font_color", Color(0.3, 0.9, 0.4))
		btn_auto.text = "🔍 AUTO DETECT (Recommended)"
		return

	btn_auto.text = "Recommended: " + AudioGrafis.nama_tampilan(tingkat_baru)
	_terapkan_grafis(tingkat_baru)

func _aksi_tutup_ditekan():
	if perlu_diterapkan:
		# Satu-satunya tempat yang memutuskan CARA setelan diberlakukan.
		# Diserahkan ke AudioGrafis supaya kalau nanti mau diganti (reload vs quit),
		# cukup diubah di satu tempat saja.
		AudioGrafis.terapkan_penuh(self)
	else:
		queue_free() # Tutup menu jika tidak ada grafis yang diubah

func _buat_tombol(teks: String, warna: Color) -> Button:
	var btn = Button.new()
	btn.text = teks
	btn.custom_minimum_size = Vector2(350, 55)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.add_theme_font_size_override("font_size", 20)
	
	var style = StyleBoxFlat.new()
	style.bg_color = warna
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_bottom_left = 8
	btn.add_theme_stylebox_override("normal", style)
	
	var style_hover = style.duplicate()
	style_hover.bg_color = warna.lightened(0.2)
	btn.add_theme_stylebox_override("hover", style_hover)
	
	return btn

# GANTI FUNGSI TERAPKAN GRAFIS SEPENUHNYA DENGAN INI
func _terapkan_grafis(tingkat: String):
	var config = ConfigFile.new()
	config.load("user://seting_grafis.cfg") # Load dulu agar data FPS tidak tertimpa/hilang
	config.set_value("Pengaturan", "kualitas_grafik", tingkat)
	config.save("user://seting_grafis.cfg")
	
	perlu_diterapkan = true

	# Ubah Judul
	var sedang_multiplayer = StatusJaringan.peran_multiplayer != ""
	judul.text = "SAVED! QUIT TO APPLY" if sedang_multiplayer else "SAVED! TAP APPLY BELOW"
	judul.add_theme_color_override("font_color", Color(1.0, 0.7, 0.2))

	# Ubah Tombol Tutup Menjadi Tombol Penerap
	btn_tutup.text = "QUIT GAME TO APPLY" if sedang_multiplayer else "APPLY NOW"
	var style_quit = StyleBoxFlat.new()
	style_quit.bg_color = Color(0.8, 0.2, 0.2)
	style_quit.corner_radius_top_left = 8
	style_quit.corner_radius_top_right = 8
	style_quit.corner_radius_bottom_right = 8
	style_quit.corner_radius_bottom_left = 8
	btn_tutup.add_theme_stylebox_override("normal", style_quit)
	
	# Dropdown disembunyikan lagi — pilihannya sudah tersimpan, tinggal diterapkan
	dropdown_kualitas.hide()

	# Kunci tombol pengubah setelan agar tidak bisa ditekan lagi sebelum diterapkan
	if btn_auto: btn_auto.disabled = true
	if btn_manual: btn_manual.disabled = true
