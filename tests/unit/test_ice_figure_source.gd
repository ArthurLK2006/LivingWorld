extends GutTest
## ART-12, entrega 6c-i: a fonte do Ice Warrior (ilhas por soldagem por posição, validação e malha reescrita igual) com dados SINTÉTICOS, sem o ativo; o caso com o arquivo real PULA se o ativo (fora do Git, em art_samples/) não existir.

const Source = preload("res://tools/visual/ice_figure/ice_source.gd")
const NORMAL_TOLERANCE: float = 0.001
const QUAD_VERTICES: int = 4


## Uma superfície com um quad (4 vértices, 2 triângulos, normais para +Z) com o canto em cada origem.
func _surfs(origins: PackedVector3Array) -> Array[Source.Surf]:
	var surf: Source.Surf = Source.Surf.new()
	for origin: Vector3 in origins:
		var first: int = surf.positions.size()
		for corner: Vector3 in PackedVector3Array([Vector3.ZERO, Vector3.RIGHT, Vector3(1.0, 1.0, 0.0), Vector3.UP]):
			surf.positions.append(origin + corner)
			surf.normals.append(Vector3.BACK)
			surf.uvs.append(Vector2(corner.x, corner.y))
		surf.indices.append_array(PackedInt32Array([first, first + 1, first + 2, first, first + 2, first + 3]))
	var surfs: Array[Source.Surf] = [surf]
	return surfs


func test_separate_quads_are_separate_islands() -> void:
	var found: Source.IslandSet = Source.islands(_surfs(PackedVector3Array([Vector3.ZERO, Vector3(5.0, 0.0, 0.0)])))
	assert_eq([found.list.size(), found.list[0].tris, found.list[1].tris], [2, 2, 2])
	assert_eq(found.of_vertex, PackedInt32Array([0, 0, 0, 0, 1, 1, 1, 1]))


func test_weld_by_position_joins_islands_and_orders_by_size() -> void:
	var near: float = Source.WELD_M * 0.3
	var found: Source.IslandSet = Source.islands(_surfs(PackedVector3Array([Vector3(10.0, 0.0, 0.0), Vector3.ZERO, Vector3(1.0 + near, 1.0, 0.0)])))
	assert_eq([found.list.size(), found.list[0].tris, found.list[1].tris], [2, 4, 2])
	assert_lt(found.list[0].center.x, 3.0, "a ilha maior (soldada por posição) tem id 0")
	assert_almost_eq(found.list[1].center, Vector3(10.5, 0.5, 0.0), Vector3.ONE * 0.001)


func test_equal_sized_islands_order_is_total_and_repeatable() -> void:
	var surfs: Array[Source.Surf] = _surfs(PackedVector3Array([Vector3(8.0, 0.0, 0.0), Vector3.ZERO, Vector3(4.0, 0.0, 0.0)]))
	var first: Source.IslandSet = Source.islands(surfs)
	assert_eq(first.of_vertex, PackedInt32Array([0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2]), "empate: o menor vértice vem primeiro")
	assert_eq(Source.islands(surfs).of_vertex, first.of_vertex)


func test_validate_names_each_unexpected_count() -> void:
	var surfs: Array[Source.Surf] = _surfs(PackedVector3Array([Vector3.ZERO]))
	var found: Source.IslandSet = Source.islands(surfs)
	assert_eq(Source.validate(surfs, found, 1, 2, 1), PackedStringArray())
	var errors: PackedStringArray = Source.validate(surfs, found, 2, 3, 4)
	assert_eq(errors.size(), 3)
	assert_string_contains(errors[0], "1 superfícies (esperado 2)")
	assert_string_contains(errors[2], "1 ilhas (esperado 4)")


func test_mesh_of_rewrites_the_same_geometry_with_bones_and_weights() -> void:
	var surfs: Array[Source.Surf] = _surfs(PackedVector3Array([Vector3.ZERO, Vector3(2.0, 3.0, 4.0)]))
	var count: int = surfs[0].positions.size()
	var uvs: Array[PackedVector2Array] = [surfs[0].uvs]
	var materials: Array[Material] = [null]
	var bones: Array[PackedInt32Array] = [PackedInt32Array()]
	var weights: Array[PackedFloat32Array] = [PackedFloat32Array()]
	for vertex: int in count:
		bones[0].append_array(PackedInt32Array([vertex % 3, 0, 0, 0]))
		weights[0].append_array(PackedFloat32Array([1.0, 0.0, 0.0, 0.0]))
	var arrays: Array = Source.mesh_of(surfs, uvs, materials, bones, weights).surface_get_arrays(0)
	assert_eq(arrays[Mesh.ARRAY_VERTEX], surfs[0].positions, "posições idênticas")
	assert_eq(arrays[Mesh.ARRAY_INDEX], surfs[0].indices, "índices idênticos")
	assert_eq(arrays[Mesh.ARRAY_TEX_UV], surfs[0].uvs, "UVs dadas")
	for index: int in count:
		assert_lt((arrays[Mesh.ARRAY_NORMAL] as PackedVector3Array)[index].distance_to(Vector3.BACK), NORMAL_TOLERANCE)
	assert_eq([(arrays[Mesh.ARRAY_BONES] as PackedInt32Array).size(), (arrays[Mesh.ARRAY_WEIGHTS] as PackedFloat32Array).size()], [count * QUAD_VERTICES, count * QUAD_VERTICES], "4 ossos e 4 pesos por vértice")


func test_real_source_is_the_expected_asset() -> void:
	if not FileAccess.file_exists(Source.SOURCE_PATH):
		pending("ativo ausente (fica fora do Git): %s" % Source.SOURCE_PATH)
		return
	var surfs: Array[Source.Surf] = Source.load_surfaces()
	var found: Source.IslandSet = Source.islands(surfs)
	assert_eq(Source.validate(surfs, found), PackedStringArray())
	var low: float = INF
	for surf: Source.Surf in surfs:
		for point: Vector3 in surf.positions:
			low = minf(low, point.y)
	assert_almost_eq(low, 0.0, 0.000001, "pés em y = 0")
	assert_eq(Source.islands(surfs).of_vertex, found.of_vertex, "mesma ordem das ilhas a cada leitura")
