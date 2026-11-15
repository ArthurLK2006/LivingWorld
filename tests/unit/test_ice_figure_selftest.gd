extends GutTest
## ART-12, entrega 6c-ii: o autoteste LOCAL da figura gravada do Ice Warrior (posições e índices idênticos aos da fonte e normais dentro da codificação de 16 bits do Godot, `Skin` com 65 binds nomeados, pesos que somam 1, paleta e JSON coerentes, cena que carrega e se instancia) e os testes do texto de proveniência e da ordem dos 12 números da pose, que não precisam do ativo. Os casos com o ativo PULAM se o original ou a figura gravada (fora do Git, em art_samples/) não existirem: rode antes tools/visual/ice_figure/ice_prepare.gd.

const Source = preload("res://tools/visual/ice_figure/ice_source.gd")
const Palette = preload("res://tools/visual/ice_figure/ice_palette.gd")
const Writer = preload("res://tools/visual/ice_figure/ice_writer.gd")
const BONES: int = 65
const SLOTS: int = 4
const POSE_NUMBERS: int = 12
## O Godot guarda os 4 pesos de cada vértice em 16 bits: a soma gravada erra até uns 3e-5 (em memória os pesos somam 1 a 1e-5, testado em test_ice_figure_weights).
const SUM_TOLERANCE: float = 0.0001
## As normais gravadas passam pela codificação octaédrica de 16 bits do Godot (medido: até 1,24e-4, uns 0,007 grau); posições e índices são EXATAMENTE iguais.
const NORMAL_TOLERANCE: float = 0.0002
const SKIN_TOLERANCE_M: float = 0.0001
const HEIGHT_TOLERANCE: float = 0.00001


func _path(file: String) -> String:
	return "%s/%s" % [Writer.OUT_DIR, file]


func _assets_missing() -> bool:
	var missing: bool = not FileAccess.file_exists(Source.SOURCE_PATH) or not FileAccess.file_exists(_path(Writer.SCENE_FILE))
	if missing:
		pending("ativo ausente (fica fora do Git): rode ice_prepare antes")
	return missing


func _figure() -> Node3D:
	return add_child_autofree((load(_path(Writer.SCENE_FILE)) as PackedScene).instantiate())


func _json() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(_path(Writer.DATA_FILE)))


func test_provenance_text_has_credit_license_hashes_and_every_change() -> void:
	var built: Palette.Built = Palette.Built.new()
	built.image = Image.create(8, 8, false, Image.FORMAT_RGB8)
	built.colors = PackedInt32Array([1, 2, 3])
	var text: String = Writer.provenance("aaaa", "bbbb", built, 1.44)
	for expected: String in [Writer.CREDIT, Writer.AUTHOR_URL, Writer.WORK_URL, Writer.LICENSE_URL, "aaaa", "bbbb", "3 cores", "fator 1.2500 para 1.80 m"]:
		assert_string_contains(text, expected)
	for change: String in Writer.CHANGES:
		assert_string_contains(text, change)


func test_pose_numbers_are_the_three_axes_then_the_origin() -> void:
	var pose: Transform3D = Transform3D(Basis(Vector3(1.0, 2.0, 3.0), Vector3(4.0, 5.0, 6.0), Vector3(7.0, 8.0, 9.0)), Vector3(10.0, 11.0, 12.0))
	assert_eq(Writer.transform_numbers(pose), [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0, 11.0, 12.0] as Array[float])


func test_saved_geometry_is_identical_to_the_source_and_weights_are_valid() -> void:
	if _assets_missing():
		return
	var surfs: Array[Source.Surf] = Source.load_surfaces()
	var holder: MeshInstance3D = _figure().find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D
	assert_eq(holder.mesh.get_surface_count(), surfs.size(), "2 superfícies")
	var worst_normal: float = 0.0
	for index: int in surfs.size():
		var arrays: Array = holder.mesh.surface_get_arrays(index)
		assert_eq(arrays[Mesh.ARRAY_VERTEX], surfs[index].positions, "posições idênticas")
		assert_eq(arrays[Mesh.ARRAY_INDEX], surfs[index].indices, "índices idênticos")
		var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
		var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
		var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		for vertex: int in surfs[index].positions.size():
			worst_normal = maxf(worst_normal, normals[vertex].distance_to(surfs[index].normals[vertex]))
			var total: float = 0.0
			for slot: int in SLOTS:
				total += weights[vertex * SLOTS + slot]
				assert_true(bones[vertex * SLOTS + slot] >= 0 and bones[vertex * SLOTS + slot] < BONES, "osso dentro da lista")
			assert_almost_eq(total, 1.0, SUM_TOLERANCE)
	assert_lt(worst_normal, NORMAL_TOLERANCE, "normais: só a recodificação octaédrica de 16 bits do Godot")


func test_saved_skin_skeleton_and_pose_reproduce_the_original_mesh() -> void:
	if _assets_missing():
		return
	var surfs: Array[Source.Surf] = Source.load_surfaces()
	var skeleton: Skeleton3D = _figure().find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
	var holder: MeshInstance3D = skeleton.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D
	assert_eq([skeleton.get_bone_count(), holder.skin.get_bind_count()], [BONES, BONES])
	var upper: int = skeleton.find_bone("upperarm_l")
	assert_false(skeleton.get_bone_rest(upper).basis.is_equal_approx(Basis(skeleton.get_bone_pose_rotation(upper))), "repouso em T e pose de bind são arranjos diferentes")
	var matrices: Array[Transform3D] = []
	for bone: int in BONES:
		assert_eq(holder.skin.get_bind_name(bone), skeleton.get_bone_name(bone), "bind nomeado")
		matrices.append(skeleton.get_bone_global_pose(bone) * holder.skin.get_bind_pose(bone))
	var worst: float = 0.0
	for index: int in surfs.size():
		var arrays: Array = holder.mesh.surface_get_arrays(index)
		for vertex: int in surfs[index].positions.size():
			var skinned: Vector3 = Vector3.ZERO
			for slot: int in SLOTS:
				skinned += (matrices[(arrays[Mesh.ARRAY_BONES] as PackedInt32Array)[vertex * SLOTS + slot]] * surfs[index].positions[vertex]) * (arrays[Mesh.ARRAY_WEIGHTS] as PackedFloat32Array)[vertex * SLOTS + slot]
			worst = maxf(worst, skinned.distance_to(surfs[index].positions[vertex]))
	assert_lt(worst, SKIN_TOLERANCE_M, "na pose gravada a pele devolve a malha original")


func test_saved_palette_materials_json_and_provenance_agree() -> void:
	if _assets_missing():
		return
	var holder: MeshInstance3D = _figure().find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D
	var png: Image = Image.new()
	png.load_png_from_buffer(FileAccess.get_file_as_bytes(_path(Writer.PALETTE_FILE)))
	png.convert(Image.FORMAT_RGB8)
	for index: int in holder.mesh.get_surface_count():
		var material: StandardMaterial3D = holder.mesh.surface_get_material(index) as StandardMaterial3D
		assert_eq(material.texture_filter, BaseMaterial3D.TEXTURE_FILTER_NEAREST)
		assert_eq(material.albedo_texture.get_image().get_data(), png.get_data(), "a textura é a paleta gravada")
	var data: Dictionary = _json()
	var height: float = 0.0
	for surf: Source.Surf in Source.load_surfaces():
		for point: Vector3 in surf.positions:
			height = maxf(height, point.y)
	assert_almost_eq(float(data["height_m"]), height, HEIGHT_TOLERANCE)
	assert_almost_eq(float(data["scale_to_body"]), Writer.BODY_M / height, HEIGHT_TOLERANCE)
	assert_eq([data["reference_clip"], (data["bones"] as Array).size(), (data["bind_pose"] as Dictionary).size()], [Writer.REFERENCE_CLIP, BONES, BONES])
	for pose: Array in (data["bind_pose"] as Dictionary).values():
		assert_eq(pose.size(), POSE_NUMBERS)
	assert_eq(data["palette"]["sha256"], FileAccess.get_sha256(_path(Writer.PALETTE_FILE)))
	assert_eq(data["source"]["sha256"], FileAccess.get_sha256(Source.SOURCE_PATH))
	var provenance: String = FileAccess.get_file_as_string(_path(Writer.PROVENANCE_FILE))
	for expected: String in [Writer.CREDIT, data["palette"]["sha256"], data["source"]["sha256"]]:
		assert_string_contains(provenance, expected)
