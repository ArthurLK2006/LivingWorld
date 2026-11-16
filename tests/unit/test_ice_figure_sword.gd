extends GutTest
## ART-12, entrega 6d-i: a espada do Ice Warrior como malha PRÓPRIA presa à mão: o subconjunto da malha (`Source.subset`, valores intactos e vértices na ordem da fonte), o papel de equipamento da tabela, a cena preparada em memória (corpo com pele e espada sem pele, filha de um `BoneAttachment3D` com a transformação local que a deixa onde estava na pose de bind; nada é gravado no disco). O aceite do `CharacterFigure` ao equipamento está em `test_character_figure.gd`. Geometria SINTÉTICA (4 quads em 2 superfícies, o papel `sword` no 1º quad da 2ª), sem o ativo; o caso com o arquivo real (corpo e espada juntos são a fonte) PULA se o ativo (fora do Git) não existir.

const Source = preload("res://tools/visual/ice_figure/ice_source.gd")
const Palette = preload("res://tools/visual/ice_figure/ice_palette.gd")
const Skel = preload("res://tools/visual/ice_figure/ice_skeleton.gd")
const Weights = preload("res://tools/visual/ice_figure/ice_weights.gd")
const Writer = preload("res://tools/visual/ice_figure/ice_writer.gd")
const QUAD_M: float = 0.02
const QUAD_VERTICES: int = 4
const SWORD_ISLAND: int = 2
const CORNERS: Array = [[Vector3(0.18, 0.08, -0.05), Vector3(-0.2, 0.08, -0.05)], [Vector3(-0.31, 0.77, 0.0), Vector3(0.0, 0.9, 0.0)]]
const ROLES: PackedStringArray = ["foot", "foot", "sword", "pelvis"]
const SWING_RAD: float = 1.0
const NORMAL_TOLERANCE: float = 0.0002

var _surfs: Array[Source.Surf] = []
var _found: Source.IslandSet
var _hand_bind: Transform3D
var _packed: PackedScene


func before_all() -> void:
	for corners: Array in CORNERS:
		var surf: Source.Surf = Source.Surf.new()
		surf.material = StandardMaterial3D.new()
		surf.offset = 0 if _surfs.is_empty() else _surfs[0].positions.size()
		for corner: Vector3 in corners:
			var first: int = surf.positions.size()
			for step: Vector3 in PackedVector3Array([Vector3.ZERO, Vector3.RIGHT, Vector3(1.0, 1.0, 0.0), Vector3.UP]):
				surf.positions.append(corner + step * QUAD_M)
				surf.normals.append(Vector3.BACK)
			surf.indices.append_array(PackedInt32Array([first, first + 1, first + 2, first, first + 2, first + 3]))
		_surfs.append(surf)
	_found = Source.islands(_surfs)
	var rig: Skel.Rig = Skel.build(CharacterCatalog.from_file().catalog, Skel.load_landmarks())
	_hand_bind = rig.bind[rig.skeleton.find_bone("hand_r")]
	var rows: Array = []
	for index: int in ROLES.size():
		var center: Vector3 = _found.list[index].center * 100.0
		rows.append({"island": index, "triangles": _found.list[index].tris, "center_cm": [center.x, center.y, center.z], "role": ROLES[index]})
	var table: Dictionary = Weights.load_table().duplicate()
	table["roles"] = rows
	var assigned: Weights.Assigned = Weights.assign(_surfs, _found, rig, table)
	assert_eq(assigned.errors, PackedStringArray())
	assert_eq([assigned.equipment.keys(), assigned.equipment.values(), assigned.roles[SWORD_ISLAND]], [[SWORD_ISLAND], ["hand_r"], "hand_r"], "o papel sword é equipamento da mão direita, e o papel final segue sendo o osso")
	var built: Palette.Built = Palette.Built.new()
	built.image = Image.create(8, 8, false, Image.FORMAT_RGB8)
	built.colors = PackedInt32Array([0])
	for surf: Source.Surf in _surfs:
		built.uvs.append(PackedVector2Array([Vector2.ZERO, Vector2.RIGHT, Vector2.ONE, Vector2.DOWN, Vector2.ZERO, Vector2.RIGHT, Vector2.ONE, Vector2.DOWN]))
	_packed = Writer.build_scene(_surfs, _found, built, assigned, rig)
	assert_not_null(_packed)


func _instance() -> Node3D:
	return add_child_autofree(_packed.instantiate())


## A lista plana dos cantos (3 por triângulo, na ordem dos índices) da superfície de uma malha.
func _corners(mesh: Mesh, surface: int, key: int = Mesh.ARRAY_VERTEX) -> PackedVector3Array:
	var arrays: Array = mesh.surface_get_arrays(surface)
	var corners: PackedVector3Array = PackedVector3Array()
	for index: int in arrays[Mesh.ARRAY_INDEX]:
		corners.append((arrays[key] as PackedVector3Array)[index])
	return corners


func test_subset_keeps_values_in_source_order_renumbers_indices_and_drops_empty_surfaces() -> void:
	var sword: Source.Subset = Source.subset(_surfs, _found, PackedInt32Array([SWORD_ISLAND]), true)
	assert_eq([sword.surfs.size(), sword.from_surface, sword.from_vertex[0]], [1, PackedInt32Array([1]), PackedInt32Array([0, 1, 2, 3])])
	assert_eq([sword.surfs[0].positions, sword.surfs[0].indices], [_surfs[1].positions.slice(0, QUAD_VERTICES), PackedInt32Array([0, 1, 2, 0, 2, 3])])
	var body: Source.Subset = Source.subset(_surfs, _found, PackedInt32Array([SWORD_ISLAND]), false)
	assert_eq([body.surfs.size(), body.from_surface, body.from_vertex[1]], [2, PackedInt32Array([0, 1]), PackedInt32Array([4, 5, 6, 7])])
	assert_eq([body.surfs[0].positions, body.surfs[1].positions, body.surfs[1].normals], [_surfs[0].positions, _surfs[1].positions.slice(QUAD_VERTICES, 8), _surfs[1].normals.slice(QUAD_VERTICES, 8)])
	var all: Source.Subset = Source.subset(_surfs, _found, PackedInt32Array(), false)
	for index: int in _surfs.size():
		assert_eq([all.surfs[index].positions, all.surfs[index].indices], [_surfs[index].positions, _surfs[index].indices], "sem equipamento a malha sai igual")


func test_pick_carries_uvs_and_four_bones_per_vertex_from_the_chosen_source_vertices() -> void:
	var uvs: PackedVector2Array = PackedVector2Array()
	var bones: PackedInt32Array = PackedInt32Array()
	for vertex: int in 2 * QUAD_VERTICES:
		uvs.append(Vector2(vertex, vertex))
		bones.append_array([vertex, vertex + 1, vertex + 2, vertex + 3])
	var body: Source.Subset = Source.subset(_surfs, _found, PackedInt32Array([SWORD_ISLAND]), false)
	assert_eq(body.pick([uvs, uvs])[1], uvs.slice(QUAD_VERTICES, 2 * QUAD_VERTICES), "UVs do 2º quad da 2ª superfície")
	assert_eq(body.pick([bones, bones], 4)[1], bones.slice(4 * QUAD_VERTICES, 8 * QUAD_VERTICES), "4 valores por vértice")
	assert_eq(Source.subset(_surfs, _found, PackedInt32Array([SWORD_ISLAND]), true).pick([bones, bones], 4)[0], bones.slice(0, 4 * QUAD_VERTICES), "a espada leva os do seu quad")


func test_the_written_scene_has_a_skinned_body_and_the_sword_as_a_skinless_mesh_on_the_hand() -> void:
	var skeleton: Skeleton3D = CharacterSceneLoader.skeleton_of(_instance())
	var body: MeshInstance3D = skeleton.get_node(Writer.MESH_NAME) as MeshInstance3D
	var carrier: BoneAttachment3D = skeleton.get_node(Writer.ATTACHMENT_NODE) as BoneAttachment3D
	var sword: MeshInstance3D = carrier.get_node(Writer.SWORD_NODE) as MeshInstance3D
	assert_eq([body.mesh.get_surface_count(), sword.mesh.get_surface_count(), carrier.bone_name], [2, 1, "hand_r"])
	assert_not_null(body.skin)
	assert_null(sword.skin, "malha rígida: sem pele")
	assert_null(sword.mesh.surface_get_arrays(0)[Mesh.ARRAY_BONES], "sem ossos nem pesos")
	assert_true((sword.transform * _hand_bind).is_equal_approx(Transform3D.IDENTITY), "transformação local = inverso da pose de bind da mão")
	assert_eq(sword.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX], _surfs[1].positions.slice(0, QUAD_VERTICES), "as posições da espada são as da fonte")
	assert_eq(body.mesh.surface_get_arrays(1)[Mesh.ARRAY_VERTEX], _surfs[1].positions.slice(QUAD_VERTICES, 8), "e as do corpo também")


func test_the_sword_sits_where_it_was_in_the_bind_pose_and_follows_the_hand() -> void:
	var scene: Node3D = _instance()
	var skeleton: Skeleton3D = CharacterSceneLoader.skeleton_of(scene)
	var sword: MeshInstance3D = skeleton.get_node("%s/%s" % [Writer.ATTACHMENT_NODE, Writer.SWORD_NODE]) as MeshInstance3D
	await wait_process_frames(1)
	assert_true(sword.global_transform.is_equal_approx(Transform3D.IDENTITY), "na pose de bind a espada fica onde estava")
	var hand: int = skeleton.find_bone("hand_r")
	skeleton.set_bone_pose_rotation(hand, Quaternion(Vector3.UP, SWING_RAD) * skeleton.get_bone_pose_rotation(hand))
	skeleton.force_update_all_bone_transforms()
	await wait_process_frames(1)
	assert_true(sword.global_transform.is_equal_approx(skeleton.global_transform * skeleton.get_bone_global_pose(hand) * sword.transform), "segue a mão como corpo rígido")
	assert_false(sword.global_transform.is_equal_approx(Transform3D.IDENTITY), "e saiu do lugar com a mão")


func test_real_body_and_sword_together_are_exactly_the_source_triangles() -> void:
	var real: String = "%s/%s" % [Writer.OUT_DIR, Writer.SCENE_FILE]
	if not FileAccess.file_exists(Source.SOURCE_PATH) or not FileAccess.file_exists(real):
		pending("ativo ausente (fica fora do Git): rode ice_prepare antes")
		return
	var surfs: Array[Source.Surf] = Source.load_surfaces()
	var found: Source.IslandSet = Source.islands(surfs)
	var ids: PackedInt32Array = PackedInt32Array()
	for row: Dictionary in Weights.load_table()["roles"]:
		if row["role"] == "sword":
			ids.append(int(row["island"]))
	var skeleton: Skeleton3D = CharacterSceneLoader.skeleton_of(add_child_autofree((load(real) as PackedScene).instantiate()))
	var body: MeshInstance3D = skeleton.get_node(Writer.MESH_NAME) as MeshInstance3D
	var sword: MeshInstance3D = skeleton.get_node("%s/%s" % [Writer.ATTACHMENT_NODE, Writer.SWORD_NODE]) as MeshInstance3D
	var expected_sword: PackedVector3Array = PackedVector3Array()
	var expected_sword_normals: PackedVector3Array = PackedVector3Array()
	var vertices: int = sword.mesh.surface_get_array_len(0)
	for index: int in surfs.size():
		var expected_body: PackedVector3Array = PackedVector3Array()
		var expected_normals: PackedVector3Array = PackedVector3Array()
		for first: int in range(0, surfs[index].indices.size(), Source.TRI):
			var inside: bool = ids.has(found.of_vertex[surfs[index].offset + surfs[index].indices[first]])
			for corner: int in Source.TRI:
				(expected_sword if inside else expected_body).append(surfs[index].positions[surfs[index].indices[first + corner]])
				(expected_sword_normals if inside else expected_normals).append(surfs[index].normals[surfs[index].indices[first + corner]])
		assert_eq(_corners(body.mesh, index), expected_body, "superfície %d do corpo: os triângulos da fonte sem os da espada, em ordem" % index)
		assert_lt(_max_distance(_corners(body.mesh, index, Mesh.ARRAY_NORMAL), expected_normals), NORMAL_TOLERANCE)
		vertices += body.mesh.surface_get_array_len(index)
	assert_eq(_corners(sword.mesh, 0), expected_sword, "os triângulos da espada, em ordem")
	assert_lt(_max_distance(_corners(sword.mesh, 0, Mesh.ARRAY_NORMAL), expected_sword_normals), NORMAL_TOLERANCE)
	assert_eq([vertices, sword.mesh.get_surface_count(), body.mesh.get_surface_count()], [surfs[0].positions.size() + surfs[1].positions.size(), 1, 2], "nenhum vértice perdido ou repetido")


func _max_distance(first: PackedVector3Array, second: PackedVector3Array) -> float:
	var worst: float = 0.0
	for index: int in first.size():
		worst = maxf(worst, first[index].distance_to(second[index]))
	return worst
