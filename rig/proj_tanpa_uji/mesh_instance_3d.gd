extends MeshInstance3D

func _ready():
	var st = SurfaceTool.new()
	
	# Memulai pembuatan jaring dengan mode Segitiga (Triangles)
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Memberikan warna merah pada material objek
	var material = StandardMaterial3D.new()
	material.albedo_color = Color.WEB_MAROON
	st.set_material(material)

	# Menentukan 5 titik sudut (Vertices) Piramida di ruang X, Y, Z
	var puncak = Vector3(0, 2, 0)
	var depan_kiri = Vector3(-1, 0, 1)
	var depan_kanan = Vector3(1, 0, 1)
	var belakang_kiri = Vector3(-1, 0, -1)
	var belakang_kanan = Vector3(1, 0, -1)

	# Sisi depan (Urutan dibalik: Kiri bawah -> Puncak -> Kanan bawah)
	st.add_vertex(depan_kiri)
	st.add_vertex(puncak)
	st.add_vertex(depan_kanan)

	# Sisi kanan
	st.add_vertex(depan_kanan)
	st.add_vertex(puncak)
	st.add_vertex(belakang_kanan)

	# Sisi belakang
	st.add_vertex(belakang_kanan)
	st.add_vertex(puncak)	st.add_vertex(belakang_kiri)

	# Sisi kiri
	st.add_vertex(belakang_kiri)
	st.add_vertex(puncak)
	st.add_vertex(depan_kiri)

	# Kalkulasi pantulan cahaya secara otomatis
	st.generate_normals()
	
	# Menerapkan hasil jaring matematika ini ke dalam node MeshInstance3D
	self.mesh = st.commit()
