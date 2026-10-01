class_name UiRole
# ============================================================
# UI ROLE (Fase 4 Langkah A6): layar "CHOOSE YOUR ROLE" -- dipakai SOLO
# (main_menu.gd, sesudah SELECT STAGE) dan LOBBY multiplayer (layar_local_play.gd,
# tombol "MY ROLE"). Semua fungsi static, dipanggil lewat nama kelas
# (UiRole.xxx) -- pola sama dengan UiProfil (dan memakai pembantu-pembantu
# UiProfil/UiDinamis yang sudah ada, bukan menulis ulang gaya tombol/kartu).
# Data angka/nama/warna dari DataRole (class_name statis, aman dipanggil di
# mana pun). Teks untuk pemain = bahasa Inggris sederhana.
# ============================================================

const EMAS := Color(1.0, 0.85, 0.2)
const ABU := Color(0.75, 0.75, 0.8)

# konteks (Dictionary, semua opsional kecuali disebutkan "wajib" di bawah):
#   "role": String            -- role terpilih awal ("" = belum pernah pilih)
#   "jebakan": Array           -- jenis tambahan terakhir (role selalu ditambahkan sendiri)
#   "jumlah_jenis": int        -- WAJIB secara praktik: total jenis jebakan yang boleh dibawa
#                                  (solo: DataRole.slot_jebakan_solo(level); lobby: DataRole.SLOT_JEBAKAN_MP)
#   "teks_tombol": String      -- teks tombol konfirmasi ("START" solo / "OK" lobby)
#   "petunjuk_level": bool     -- true (default): tampilkan "Level N: bring M traps" (solo saja)
#   "boleh_batal": bool        -- true: tampilkan tombol BACK
#   "batal": Callable          -- dipanggil kalau BACK ditekan (tanpa argumen)
#   "lapisan": int             -- layer CanvasLayer (default 11)
#   "level_role": bool         -- true (P11, solo): tombol role tertulis "FIRE\nLv 4"
#   "arena": bool              -- true (P11, lobby): baris "ARENA BUILD:" + preset
#                                  ATTACK/DEFENSE/BALANCED di bawah baris jebakan,
#                                  menulis ProfilPemain.arena[role] SEBELUM "selesai"
#                                  dipanggil (lobby menghitung build_arena sesudahnya).
# selesai: Callable(role: String, jebakan: Array) -- dipanggil sekali saat tombol
# konfirmasi ditekan; layar ROLE sudah membuang dirinya sendiri saat ini dipanggil.
static func buka_pilih_role(induk: Node, konteks: Dictionary, selesai: Callable) -> CanvasLayer:
	var jumlah_jenis: int = int(konteks.get("jumlah_jenis", DataRole.SLOT_JEBAKAN_MP))
	var role0: String = str(konteks.get("role", ""))
	if role0 != "" and not DataRole.ROLE.has(role0):
		role0 = ""
	var jebakan0: Array = (konteks.get("jebakan", []) as Array).duplicate()
	if role0 != "" and not jebakan0.has(role0):
		jebakan0.insert(0, role0)
	# State DIBAGI lewat SATU Dictionary yang ISINYA diubah (state["role"] = ...),
	# bukan lewat menimpa variabel lokal biasa -- lambda GDScript menangkap
	# variabel lokal primitif lewat NILAI saat closure dibuat, jadi hanya
	# Dictionary/Array/Node (tipe referensi) yang aman dibagi antar closure
	# tombol di bawah.
	var state := {"role": role0, "jebakan": jebakan0}
	var teks_tombol: String = str(konteks.get("teks_tombol", "START"))
	var petunjuk_level: bool = bool(konteks.get("petunjuk_level", true))
	var level_role_ctx: bool = bool(konteks.get("level_role", false)) # P11 (B-e)
	var arena_ctx: bool = bool(konteks.get("arena", false)) # P11 (B-e)

	var kanvas = UiProfil._layar_gelap(induk, int(konteks.get("lapisan", 11)))
	var isi = UiProfil._kartu_tengah(kanvas, true)
	isi.custom_minimum_size = Vector2(560, 0)

	isi.add_child(UiProfil._label("CHOOSE YOUR ROLE", 30, EMAS))

	var baris_role = GridContainer.new()
	baris_role.columns = 5
	baris_role.add_theme_constant_override("h_separation", 10)
	baris_role.add_theme_constant_override("v_separation", 10)
	baris_role.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	isi.add_child(baris_role)

	var lbl_ket = UiProfil._label("", 17)
	lbl_ket.custom_minimum_size = Vector2(500, 0)
	lbl_ket.autowrap_mode = TextServer.AUTOWRAP_WORD
	isi.add_child(lbl_ket)

	var lbl_bawa = UiProfil._label("", 18, ABU)
	isi.add_child(lbl_bawa)

	var baris_jebakan = GridContainer.new()
	baris_jebakan.columns = 4
	baris_jebakan.add_theme_constant_override("h_separation", 8)
	baris_jebakan.add_theme_constant_override("v_separation", 8)
	baris_jebakan.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	isi.add_child(baris_jebakan)

	# P11 (B-e, lobby): "ARENA BUILD:" + preset ATTACK/DEFENSE/BALANCED untuk role
	# terpilih -- menulis ProfilPemain.arena[role] SEGERA (lobby membaca lewat
	# DataRole.build_arena sesudah "selesai" -- C2 tidak berubah).
	var lbl_arena_judul := UiProfil._label("", 15, ABU)
	var baris_arena := HBoxContainer.new()
	var tombol_arena_preset: Dictionary = {}
	var lbl_arena_custom := UiProfil._label("CUSTOM", 14, EMAS)
	if arena_ctx:
		isi.add_child(lbl_arena_judul)
		baris_arena.alignment = BoxContainer.ALIGNMENT_CENTER
		baris_arena.add_theme_constant_override("separation", 8)
		isi.add_child(baris_arena)
		for preset in ["attack", "defense", "balanced"]:
			# Tombol dibuat DI SINI (belum di-wire) -- pola sama placeholder
			# tombol_role/tombol_jebakan di bawah: closure "segarkan" belum ada.
			var bp = UiProfil._tombol(preset.to_upper(), Color(0.35, 0.35, 0.4), Vector2(120, 40), 14)
			tombol_arena_preset[preset] = bp
			baris_arena.add_child(bp)
		baris_arena.add_child(lbl_arena_custom)

	var lbl_petunjuk = UiProfil._label("", 14, ABU)
	isi.add_child(lbl_petunjuk)

	# Placeholder dibuat SEKARANG (bukan lewat UiProfil._tombol nanti) supaya
	# closure "segarkan" di bawah menangkap OBJEK tombolnya, bukan null --
	# properti tombol ini (.disabled dst) yang diubah belakangan, bukan
	# variabelnya sendiri ditimpa (lihat catatan "state" di atas).
	var tombol_role: Dictionary = {}
	var tombol_jebakan: Dictionary = {}
	var btn_mulai := Button.new()

	var segarkan := func():
		var r_sel: String = state["role"]
		var j_sel: Array = state["jebakan"]
		for r in DataRole.ROLE:
			var b: Button = tombol_role[r]
			var terpilih = (r == r_sel)
			UiDinamis._gaya_tombol(b, DataRole.warna_role(r) if terpilih else DataRole.warna_role(r).darkened(0.55))
			b.add_theme_color_override("font_color", Color(1, 1, 1, 1.0 if terpilih else 0.65))
		if r_sel == "":
			lbl_ket.text = "Pick a role to see its trap and resistances."
			lbl_bawa.text = ""
		else:
			lbl_ket.text = "%s - Your trap: %s Trap. Tough against: %s." % [
				DataRole.nama_role(r_sel), DataRole.nama_role(r_sel).capitalize(), DataRole.teks_tahan_role(r_sel)]
			lbl_bawa.text = "TRAPS YOU BRING %d/%d" % [j_sel.size(), jumlah_jenis]
		for e in tombol_jebakan.keys():
			var bj: Button = tombol_jebakan[e]
			var dibawa = j_sel.has(e)
			var terkunci = (e == r_sel)
			bj.disabled = terkunci or r_sel == "" or (not dibawa and j_sel.size() >= jumlah_jenis)
			UiDinamis._gaya_tombol(bj, DataRole.warna_role(e) if dibawa else Color(0.3, 0.3, 0.35))
			bj.text = DataRole.nama_role(e) + (" (Role)" if terkunci else (" ✓" if dibawa else ""))
		btn_mulai.disabled = r_sel == ""
		if petunjuk_level:
			_isi_petunjuk_slot(lbl_petunjuk, j_sel.size())
		if arena_ctx:
			# P11: highlight preset AKTIF untuk role terpilih; CUSTOM (dari tab
			# ARENA layar pohon, buka_pohon) tampil sebagai label, tanpa tombol aktif.
			lbl_arena_judul.text = "ARENA BUILD: %s" % DataRole.nama_role(r_sel) if r_sel != "" else "ARENA BUILD:"
			var simpanan_arena: Dictionary = ProfilPemain.arena.get(r_sel, {}) if r_sel != "" else {}
			var preset_aktif := str(simpanan_arena.get("preset", ""))
			for preset in tombol_arena_preset.keys():
				var bp: Button = tombol_arena_preset[preset]
				bp.disabled = r_sel == ""
				var terpilih_p = (preset == preset_aktif)
				UiDinamis._gaya_tombol(bp, Color(0.15, 0.5, 0.7) if terpilih_p else Color(0.35, 0.35, 0.4))
				bp.add_theme_color_override("font_color", Color(1, 1, 1, 1.0 if terpilih_p else 0.7))
			lbl_arena_custom.visible = (preset_aktif == "custom")

	for r in DataRole.ROLE:
		var teks_tombol_role = DataRole.nama_role(r)
		if level_role_ctx: # P11 (B-e, solo): "FIRE\nLv 4" -- Level Role role ini SENDIRI.
			var lv_r = int(DataRole.info_level_role(int(ProfilPemain.xp_role.get(r, 0)))["level"])
			teks_tombol_role += "\nLv %d" % lv_r
		var b = UiProfil._tombol(teks_tombol_role, DataRole.warna_role(r), Vector2(96, 64), 16)
		tombol_role[r] = b
		baris_role.add_child(b)
		b.pressed.connect(func():
			# Ganti role: jebakan role lama yang bukan role baru tetap dipakai
			# kalau masih muat (UX lebih enak daripada mengosongkan semuanya).
			var j: Array = (state["jebakan"] as Array).filter(func(x): return x != r)
			j.insert(0, r)
			while j.size() > jumlah_jenis:
				j.pop_back()
			state["role"] = r
			state["jebakan"] = j
			segarkan.call()
		)

	for e in DataRole.ROLE:
		var bj = UiProfil._tombol(DataRole.nama_role(e), Color(0.3, 0.3, 0.35), Vector2(112, 48), 15)
		tombol_jebakan[e] = bj
		baris_jebakan.add_child(bj)
		bj.pressed.connect(func():
			if e == str(state["role"]):
				return
			var j: Array = (state["jebakan"] as Array).duplicate()
			if j.has(e):
				j.erase(e)
			elif j.size() < jumlah_jenis:
				j.append(e)
			state["jebakan"] = j
			segarkan.call()
		)

	if arena_ctx:
		for preset in tombol_arena_preset.keys():
			var bp: Button = tombol_arena_preset[preset]
			bp.pressed.connect(func():
				var r_sel_arena: String = state["role"]
				if r_sel_arena == "":
					return
				ProfilPemain.arena[r_sel_arena] = {"preset": preset, "node": DataRole.build_dari_preset(r_sel_arena, preset, DataRole.SP_ARENA, DataRole.LEVEL_ROLE_MAKS)}
				ProfilPemain.simpan()
				segarkan.call()
			)

	var baris_tombol = HBoxContainer.new()
	baris_tombol.alignment = BoxContainer.ALIGNMENT_CENTER
	baris_tombol.add_theme_constant_override("separation", 16)
	isi.add_child(baris_tombol)

	if bool(konteks.get("boleh_batal", false)):
		var btn_batal = UiProfil._tombol("BACK", Color(0.5, 0.2, 0.2), Vector2(150, 56), 20)
		baris_tombol.add_child(btn_batal)
		btn_batal.pressed.connect(func():
			kanvas.queue_free()
			var batal: Callable = konteks.get("batal", Callable())
			if batal.is_valid():
				batal.call()
		)

	btn_mulai.text = teks_tombol
	btn_mulai.custom_minimum_size = Vector2(220, 60)
	btn_mulai.add_theme_font_size_override("font_size", 22)
	UiDinamis._gaya_tombol(btn_mulai, Color(0.15, 0.55, 0.25))
	baris_tombol.add_child(btn_mulai)
	btn_mulai.pressed.connect(func():
		if str(state["role"]) == "":
			return
		btn_mulai.disabled = true
		var role_akhir: String = state["role"]
		var jebakan_akhir: Array = (state["jebakan"] as Array).duplicate()
		kanvas.queue_free()
		selesai.call(role_akhir, jebakan_akhir)
	)

	segarkan.call()
	return kanvas

static func _isi_petunjuk_slot(lbl: Label, jumlah_sekarang: int) -> void:
	# "Level N: bring M traps" -- tingkat SLOT_JEBAKAN_SOLO berikutnya di atas
	# jumlah sekarang (list-nya terurut dari syarat level TERTINGGI ke
	# terendah, jadi hasil akhir loop ini otomatis yang PALING DEKAT). Kosong
	# kalau sudah maksimal (5 jenis) -- multiplayer (petunjuk_level=false)
	# tidak pernah memanggil fungsi ini sama sekali.
	var berikut := ""
	for pasangan in DataRole.SLOT_JEBAKAN_SOLO:
		if int(pasangan[1]) > jumlah_sekarang:
			berikut = "Level %d: bring %d traps" % [int(pasangan[0]), int(pasangan[1])]
	lbl.text = berikut

# ============================================================
# B-e (P11) -- LAYAR POHON SKILL (B2) + ARENA. Tombol "ROLES" main_menu.gd
# (solo) & bisa juga dibuka lobby (belum dipakai lobby -- lobby tetap pakai
# buka_pilih_role + baris ARENA BUILD ringkas, lihat layar_local_play.gd).
# konteks: "role" (awal), "tab" "tree"|"arena" (awal, bawaan "tree"),
# "lapisan" (bawaan 11), "tutup" Callable (dipanggil sesudah CLOSE, opsional).
# ============================================================

static func buka_pohon(induk: Node, konteks: Dictionary) -> CanvasLayer:
	var role0: String = str(konteks.get("role", ""))
	if role0 == "" or not DataRole.ROLE.has(role0):
		role0 = ProfilPemain.role_terakhir if DataRole.ROLE.has(ProfilPemain.role_terakhir) else DataRole.ROLE[0]
	var tab0: String = str(konteks.get("tab", "tree"))
	if tab0 != "arena":
		tab0 = "tree"
	var state := {"role": role0, "tab": tab0}
	var lapisan: int = int(konteks.get("lapisan", 11))

	var kanvas = UiProfil._layar_gelap(induk, lapisan)
	var isi = UiProfil._kartu_tengah(kanvas, false)
	isi.custom_minimum_size = Vector2(1100, 0)

	# --- baris atas: 5 tab role + sakelar ROLE TREE / ARENA ---
	var baris_atas = HBoxContainer.new()
	baris_atas.alignment = BoxContainer.ALIGNMENT_CENTER
	baris_atas.add_theme_constant_override("separation", 28)
	isi.add_child(baris_atas)
	var grup_role = HBoxContainer.new()
	grup_role.add_theme_constant_override("separation", 8)
	baris_atas.add_child(grup_role)
	var grup_tab = HBoxContainer.new()
	grup_tab.add_theme_constant_override("separation", 8)
	baris_atas.add_child(grup_tab)

	var tombol_tab_role: Dictionary = {}
	for r in DataRole.ROLE:
		var rb = UiProfil._tombol(DataRole.nama_role(r), DataRole.warna_role(r), Vector2(92, 48), 14)
		tombol_tab_role[r] = rb
		grup_role.add_child(rb)

	var btn_tab_tree = UiProfil._tombol("ROLE TREE", Color(0.2, 0.45, 0.75), Vector2(140, 48), 15)
	var btn_tab_arena = UiProfil._tombol("ARENA", Color(0.2, 0.45, 0.75), Vector2(140, 48), 15)
	grup_tab.add_child(btn_tab_tree)
	grup_tab.add_child(btn_tab_arena)

	# --- baris utama: kiri (level/SP/preset/reset) + kanan (grid node) ---
	var baris_utama = HBoxContainer.new()
	baris_utama.add_theme_constant_override("separation", 26)
	isi.add_child(baris_utama)

	var kiri = VBoxContainer.new()
	kiri.custom_minimum_size = Vector2(300, 0)
	kiri.add_theme_constant_override("separation", 8)
	baris_utama.add_child(kiri)

	var lbl_judul_kiri = UiProfil._label("", 20, EMAS)
	lbl_judul_kiri.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	kiri.add_child(lbl_judul_kiri)
	var batang_xp = UiProfil._batang_xp(280, 14)
	kiri.add_child(batang_xp)
	var lbl_xp_kiri = UiProfil._label("", 14, ABU)
	lbl_xp_kiri.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	kiri.add_child(lbl_xp_kiri)
	var lbl_sp = UiProfil._label("", 18, EMAS)
	lbl_sp.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	kiri.add_child(lbl_sp)

	var baris_preset = HBoxContainer.new()
	baris_preset.add_theme_constant_override("separation", 6)
	kiri.add_child(baris_preset)
	var tombol_preset: Dictionary = {}
	for preset in ["attack", "defense", "balanced"]:
		var bp = UiProfil._tombol(preset.to_upper().substr(0, 3), Color(0.35, 0.35, 0.4), Vector2(76, 40), 13)
		tombol_preset[preset] = bp
		baris_preset.add_child(bp)
	var lbl_custom_kiri = UiProfil._label("CUSTOM", 13, EMAS)
	kiri.add_child(lbl_custom_kiri)
	var btn_reset = UiProfil._tombol("RESET", Color(0.5, 0.2, 0.2), Vector2(120, 40), 14)
	kiri.add_child(btn_reset)

	var kanan = VBoxContainer.new()
	kanan.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	kanan.add_theme_constant_override("separation", 6)
	baris_utama.add_child(kanan)

	kanan.add_child(UiProfil._label("TRAPS", 15, ABU))
	var baris_jeb = HBoxContainer.new()
	baris_jeb.add_theme_constant_override("separation", 10)
	kanan.add_child(baris_jeb)
	var btn_jebakan: Array = []
	for i in range(3):
		var bj = Button.new()
		bj.custom_minimum_size = Vector2(160, 58)
		bj.add_theme_font_size_override("font_size", 14)
		btn_jebakan.append(bj)
		baris_jeb.add_child(bj)

	kanan.add_child(UiProfil._label("DEFENSE", 15, ABU))
	var baris_tahan = HBoxContainer.new()
	baris_tahan.add_theme_constant_override("separation", 10)
	kanan.add_child(baris_tahan)
	var btn_tahan: Array = []
	for i in range(2):
		var bt = Button.new()
		bt.custom_minimum_size = Vector2(160, 58)
		bt.add_theme_font_size_override("font_size", 14)
		btn_tahan.append(bt)
		baris_tahan.add_child(bt)

	var btn_ultimate = Button.new()
	btn_ultimate.custom_minimum_size = Vector2(520, 58)
	btn_ultimate.add_theme_font_size_override("font_size", 15)
	kanan.add_child(btn_ultimate)

	var btn_tutup = UiProfil._tombol("CLOSE", Color(0.4, 0.4, 0.4), Vector2(200, 52), 20)
	btn_tutup.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	isi.add_child(btn_tutup)

	# slot id SEKARANG (diisi ulang tiap segarkan -- dibaca closure tombol node
	# di titik KLIK, bukan disalin ke closure saat tombol dibuat, karena id
	# berubah tiap ganti tab role -- "segarkan = ubah properti", P11).
	var slot_jebakan_id: Array = ["", "", ""]
	var slot_tahan_id: Array = ["", ""]

	var baca_state := func() -> Dictionary:
		var role_sel: String = state["role"]
		var tab_arena: bool = (str(state["tab"]) == "arena")
		var level_role: int
		var sp_total: int
		var simpanan
		if tab_arena:
			level_role = DataRole.LEVEL_ROLE_MAKS
			sp_total = DataRole.SP_ARENA
			simpanan = ProfilPemain.arena.get(role_sel, {})
		else:
			level_role = int(DataRole.info_level_role(int(ProfilPemain.xp_role.get(role_sel, 0)))["level"])
			sp_total = DataRole.sp_dari_level(level_role)
			simpanan = ProfilPemain.build_solo.get(role_sel, {})
		var build_efektif: Dictionary = DataRole.build_arena(role_sel, simpanan) if tab_arena else DataRole.build_solo(role_sel, simpanan, level_role)
		return {
			"role": role_sel, "tab_arena": tab_arena, "level_role": level_role,
			"sp_total": sp_total, "build": build_efektif,
			"sp_sisa": sp_total - DataRole.biaya_build(build_efektif),
			"preset": (str(simpanan.get("preset", "")) if typeof(simpanan) == TYPE_DICTIONARY else ""),
		}

	var segarkan := func():
		var s: Dictionary = baca_state.call()
		var role_sel: String = s["role"]
		var tab_arena: bool = s["tab_arena"]
		var level_role: int = s["level_role"]
		for r in DataRole.ROLE:
			var rb: Button = tombol_tab_role[r]
			var terpilih_r = (r == role_sel)
			UiDinamis._gaya_tombol(rb, DataRole.warna_role(r) if terpilih_r else DataRole.warna_role(r).darkened(0.55))
			rb.add_theme_color_override("font_color", Color(1, 1, 1, 1.0 if terpilih_r else 0.65))
		UiDinamis._gaya_tombol(btn_tab_tree, Color(0.2, 0.45, 0.75) if not tab_arena else Color(0.25, 0.25, 0.3))
		btn_tab_tree.add_theme_color_override("font_color", Color(1, 1, 1, 1.0 if not tab_arena else 0.6))
		UiDinamis._gaya_tombol(btn_tab_arena, Color(0.2, 0.45, 0.75) if tab_arena else Color(0.25, 0.25, 0.3))
		btn_tab_arena.add_theme_color_override("font_color", Color(1, 1, 1, 1.0 if tab_arena else 0.6))

		if tab_arena:
			lbl_judul_kiri.text = "%s ARENA BUILD (Multiplayer)" % DataRole.nama_role(role_sel)
			batang_xp.hide()
			lbl_xp_kiri.hide()
		else:
			lbl_judul_kiri.text = "%s ROLE Lv %d" % [DataRole.nama_role(role_sel), level_role]
			batang_xp.show()
			lbl_xp_kiri.show()
			var info = DataRole.info_level_role(int(ProfilPemain.xp_role.get(role_sel, 0)))
			if int(info["xp_perlu"]) > 0:
				batang_xp.max_value = float(info["xp_perlu"])
				batang_xp.value = float(info["xp_di_level"])
				lbl_xp_kiri.text = "%d/%d XP to Lv %d" % [int(info["xp_di_level"]), int(info["xp_perlu"]), level_role + 1]
			else:
				batang_xp.max_value = 1.0
				batang_xp.value = 1.0
				lbl_xp_kiri.text = "MAX ROLE LEVEL"
		lbl_sp.text = "SP: %d left / %d" % [int(s["sp_sisa"]), int(s["sp_total"])]
		var preset_aktif: String = s["preset"]
		for preset in tombol_preset.keys():
			var bp: Button = tombol_preset[preset]
			var terpilih_p = (preset == preset_aktif)
			UiDinamis._gaya_tombol(bp, Color(0.15, 0.5, 0.7) if terpilih_p else Color(0.35, 0.35, 0.4))
			bp.add_theme_color_override("font_color", Color(1, 1, 1, 1.0 if terpilih_p else 0.7))
		lbl_custom_kiri.visible = (preset_aktif == "custom")

		var build_efektif: Dictionary = s["build"]
		var jeb_ids: Array = DataRole.NODE_JEBAKAN_ID.get(role_sel, [])
		for i in range(3):
			var id_j: String = jeb_ids[i] if i < jeb_ids.size() else ""
			slot_jebakan_id[i] = id_j
			_segarkan_tombol_node(btn_jebakan[i], id_j, int(build_efektif.get(id_j, 0)), level_role, tab_arena, role_sel)
		var tahan_ids: Array = DataRole.TAHAN_ROLE.get(role_sel, [])
		for i in range(2):
			var id_t: String = tahan_ids[i] if i < tahan_ids.size() else ""
			slot_tahan_id[i] = id_t
			_segarkan_tombol_node(btn_tahan[i], id_t, int(build_efektif.get(id_t, 0)), level_role, tab_arena, role_sel)
		var id_ult_data: String = DataRole.NODE_ULTIMATE_ID.get(role_sel, "")
		var id_ult_build: String = "ULT_" + role_sel
		var dimiliki: bool = bool(build_efektif.get(id_ult_build, false))
		var ult_terkunci: bool = (not tab_arena) and level_role < DataRole.BUKA_ULTIMATE
		btn_ultimate.text = "%s\n%s" % [DataRole.nama_node(id_ult_data), ("OWNED" if dimiliki else "%d SP" % DataRole.BIAYA_ULTIMATE)]
		if dimiliki:
			UiDinamis._gaya_tombol(btn_ultimate, EMAS.darkened(0.25))
			btn_ultimate.add_theme_color_override("font_color", Color.BLACK)
		else:
			UiDinamis._gaya_tombol(btn_ultimate, Color(0.3, 0.3, 0.35) if ult_terkunci else Color(0.45, 0.38, 0.12))
			btn_ultimate.add_theme_color_override("font_color", Color(1, 1, 1, 0.5 if ult_terkunci else 1.0))

	for r in DataRole.ROLE:
		var rb2: Button = tombol_tab_role[r]
		rb2.pressed.connect(func():
			state["role"] = r
			segarkan.call()
		)
	btn_tab_tree.pressed.connect(func():
		state["tab"] = "tree"
		segarkan.call()
	)
	btn_tab_arena.pressed.connect(func():
		state["tab"] = "arena"
		segarkan.call()
	)
	for preset in tombol_preset.keys():
		var bp2: Button = tombol_preset[preset]
		bp2.pressed.connect(func():
			var s: Dictionary = baca_state.call()
			var baru = {"preset": preset, "node": DataRole.build_dari_preset(s["role"], preset, s["sp_total"], s["level_role"])}
			if s["tab_arena"]:
				ProfilPemain.arena[s["role"]] = baru
			else:
				ProfilPemain.build_solo[s["role"]] = baru
			ProfilPemain.simpan()
			segarkan.call()
		)
	btn_reset.pressed.connect(func():
		var s: Dictionary = baca_state.call()
		_kartu_reset(induk, lapisan + 1, s["role"], s["tab_arena"], segarkan)
	)
	for i in range(3):
		var idx_j = i
		btn_jebakan[idx_j].pressed.connect(func():
			var id_j = str(slot_jebakan_id[idx_j])
			if id_j == "":
				return
			_touch_node(induk, lapisan + 1, id_j, id_j, baca_state.call(), segarkan)
		)
	for i in range(2):
		var idx_t = i
		btn_tahan[idx_t].pressed.connect(func():
			var id_t = str(slot_tahan_id[idx_t])
			if id_t == "":
				return
			_touch_node(induk, lapisan + 1, id_t, id_t, baca_state.call(), segarkan)
		)
	btn_ultimate.pressed.connect(func():
		var s: Dictionary = baca_state.call()
		var id_data: String = DataRole.NODE_ULTIMATE_ID.get(str(s["role"]), "")
		if id_data == "":
			return
		_touch_node(induk, lapisan + 1, id_data, "ULT_" + str(s["role"]), s, segarkan)
	)
	btn_tutup.pressed.connect(func():
		kanvas.queue_free()
		var tutup: Callable = konteks.get("tutup", Callable())
		if tutup.is_valid():
			tutup.call()
	)

	segarkan.call()
	return kanvas

static func _segarkan_tombol_node(btn: Button, id_node: String, lv: int, level_role: int, tab_arena: bool, role: String) -> void:
	if id_node == "":
		btn.text = ""
		btn.disabled = true
		return
	btn.disabled = false
	btn.text = "%s\nLv %d/3" % [DataRole.nama_node(id_node), lv]
	var lv_baru = lv + 1
	var terkunci_next = (not tab_arena) and lv_baru <= 3 and level_role < DataRole.BUKA_TINGKAT[mini(lv_baru, 3) - 1]
	var warna_role = DataRole.warna_role(role)
	if lv >= 3:
		UiDinamis._gaya_tombol(btn, warna_role)
		btn.add_theme_color_override("font_color", Color.WHITE)
	elif terkunci_next:
		UiDinamis._gaya_tombol(btn, Color(0.28, 0.28, 0.32))
		btn.add_theme_color_override("font_color", Color(1, 1, 1, 0.55))
	elif lv >= 1:
		UiDinamis._gaya_tombol(btn, warna_role.darkened(0.15))
		btn.add_theme_color_override("font_color", Color.WHITE)
	else:
		UiDinamis._gaya_tombol(btn, Color(0.35, 0.35, 0.4))
		btn.add_theme_color_override("font_color", Color(1, 1, 1, 0.85))

static func _touch_node(induk: Node, lapisan: int, id_data: String, id_build: String, s: Dictionary, segarkan: Callable) -> void:
	# Dipakai node biasa (id_data == id_build) & Ultimate (id_build = "ULT_"+role,
	# id_data = DataRole.NODE_ULTIMATE_ID[role] -- nama/teks beda kunci dari build).
	var role: String = s["role"]
	var tab_arena: bool = s["tab_arena"]
	var level_role: int = s["level_role"]
	var sp_total: int = s["sp_total"]
	var sp_sisa: int = s["sp_sisa"]
	var build_efektif: Dictionary = s["build"]
	var ultimate = id_build.begins_with("ULT_")
	var lv: int = (1 if bool(build_efektif.get(id_build, false)) else 0) if ultimate else int(build_efektif.get(id_build, 0))
	var maks_lv = 1 if ultimate else 3
	var nama_tampil = DataRole.nama_node(id_data)
	var teks_now = DataRole.teks_node(id_data, lv) if lv >= 1 else "Not learned"
	var teks_next := ""
	var biaya := 0
	var terkunci := false
	var teks_terkunci := ""
	if lv < maks_lv:
		teks_next = DataRole.teks_node(id_data, 1 if ultimate else lv + 1)
		if ultimate:
			biaya = DataRole.BIAYA_ULTIMATE
			if not tab_arena:
				terkunci = level_role < DataRole.BUKA_ULTIMATE
				teks_terkunci = "Unlocks at Role Lv %d" % DataRole.BUKA_ULTIMATE
		else:
			biaya = DataRole.BIAYA_NODE[lv]
			if not tab_arena:
				var ambang = DataRole.BUKA_TINGKAT[lv]
				terkunci = level_role < ambang
				teks_terkunci = "Unlocks at Role Lv %d" % ambang
	_kartu_konfirmasi(induk, lapisan, nama_tampil, teks_now, teks_next, biaya, sp_sisa, terkunci, teks_terkunci, func():
		var baru: Dictionary = build_efektif.duplicate()
		if ultimate:
			baru[id_build] = true
		else:
			baru[id_build] = lv + 1
		if not DataRole.build_sah(baru, role, sp_total, level_role):
			return
		if tab_arena:
			ProfilPemain.arena[role] = {"preset": "custom", "node": baru}
		else:
			ProfilPemain.build_solo[role] = {"preset": "custom", "node": baru}
		ProfilPemain.simpan()
		segarkan.call()
	)

static func _kartu_konfirmasi(induk: Node, lapisan: int, nama_tampil: String, teks_now: String, teks_next: String, biaya: int, sp_sisa: int, terkunci: bool, teks_terkunci: String, on_learn: Callable) -> void:
	var kanvas = UiProfil._layar_gelap(induk, lapisan)
	var isi = UiProfil._kartu_tengah(kanvas, false)
	isi.custom_minimum_size = Vector2(420, 0)
	isi.add_child(UiProfil._label(nama_tampil, 24, EMAS))
	isi.add_child(UiProfil._label("Now: %s" % teks_now, 16))
	var maks = (teks_next == "")
	if maks:
		isi.add_child(UiProfil._label("MAX", 20, EMAS))
	else:
		var lbl_next = UiProfil._label("Next: %s" % teks_next, 16, Color(0.6, 0.9, 1.0))
		lbl_next.autowrap_mode = TextServer.AUTOWRAP_WORD
		lbl_next.custom_minimum_size = Vector2(380, 0)
		isi.add_child(lbl_next)
		isi.add_child(UiProfil._label("Cost: %d SP" % biaya, 16, ABU))
	var baris = HBoxContainer.new()
	baris.alignment = BoxContainer.ALIGNMENT_CENTER
	baris.add_theme_constant_override("separation", 14)
	isi.add_child(baris)
	var btn_batal = UiProfil._tombol("CANCEL", Color(0.4, 0.4, 0.4), Vector2(140, 50), 18)
	baris.add_child(btn_batal)
	btn_batal.pressed.connect(kanvas.queue_free)
	if not maks:
		var btn_learn = UiProfil._tombol("LEARN", Color(0.15, 0.55, 0.25), Vector2(140, 50), 18)
		baris.add_child(btn_learn)
		var alasan_mati := ""
		if terkunci:
			alasan_mati = teks_terkunci
		elif biaya > sp_sisa:
			alasan_mati = "Not enough SP"
		if alasan_mati != "":
			btn_learn.disabled = true
			isi.add_child(UiProfil._label(alasan_mati, 14, Color(1.0, 0.45, 0.4)))
		btn_learn.pressed.connect(func():
			kanvas.queue_free()
			on_learn.call()
		)

static func _kartu_reset(induk: Node, lapisan: int, role: String, tab_arena: bool, segarkan: Callable) -> void:
	var kanvas = UiProfil._layar_gelap(induk, lapisan)
	var isi = UiProfil._kartu_tengah(kanvas, false)
	isi.add_child(UiProfil._label("Reset all points? (free)", 20, EMAS))
	var baris = HBoxContainer.new()
	baris.alignment = BoxContainer.ALIGNMENT_CENTER
	baris.add_theme_constant_override("separation", 14)
	isi.add_child(baris)
	var btn_batal = UiProfil._tombol("CANCEL", Color(0.4, 0.4, 0.4), Vector2(140, 50), 18)
	baris.add_child(btn_batal)
	btn_batal.pressed.connect(kanvas.queue_free)
	var btn_ok = UiProfil._tombol("RESET", Color(0.6, 0.2, 0.2), Vector2(140, 50), 18)
	baris.add_child(btn_ok)
	btn_ok.pressed.connect(func():
		kanvas.queue_free()
		if tab_arena:
			ProfilPemain.arena[role] = {"preset": "custom", "node": {}}
		else:
			ProfilPemain.build_solo[role] = {"preset": "custom", "node": {}}
		ProfilPemain.simpan()
		segarkan.call()
	)
