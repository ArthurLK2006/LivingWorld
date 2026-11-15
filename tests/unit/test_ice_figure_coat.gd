extends GutTest
## ART-12, entrega 6d-ii: o casaco por lado. `Weights.left_share` (ilha de um lado só: o lado da ilha; ilha CENTRAL: rampa linear em X do PONTO, +-SIDE_BLEND_M) e os pesos suaves do papel `~skirt` da tabela real (pelvis, spine_01 e a coxa do PRÓPRIO lado; as duas coxas só na faixa do meio) com geometria SINTÉTICA: uma tira de quads cruzando o plano do meio (uma ilha central) e dois quads soltos (ilhas de um lado só). Sem o ativo.

const Source = preload("res://tools/visual/ice_figure/ice_source.gd")
const Skel = preload("res://tools/visual/ice_figure/ice_skeleton.gd")
const Weights = preload("res://tools/visual/ice_figure/ice_weights.gd")
const QUAD_M: float = 0.02
const QUAD_VERTICES: int = 4
const STRIP_QUADS: int = 30
const STRIP_START_X: float = -0.30
const COAT_Y: float = 0.45
const APART_Z: float = 0.5
const LEFT_PIECE_X: float = 0.12
const RIGHT_PIECE_X: float = -0.14
const SUM_TOLERANCE: float = 0.00001
const SYMMETRY_TOLERANCE: float = 0.01

var _rig: Skel.Rig
var _out: Weights.Assigned
var _strip_vertices: int = STRIP_QUADS * QUAD_VERTICES


func before_all() -> void:
	_rig = Skel.build(CharacterCatalog.from_file().catalog, Skel.load_landmarks())
	var surf: Source.Surf = Source.Surf.new()
	var corners: PackedVector3Array = PackedVector3Array()
	for step: int in STRIP_QUADS:
		corners.append(Vector3(STRIP_START_X + step * QUAD_M, COAT_Y, 0.0))
	corners.append(Vector3(LEFT_PIECE_X, COAT_Y, APART_Z))
	corners.append(Vector3(RIGHT_PIECE_X, COAT_Y, APART_Z))
	for corner: Vector3 in corners:
		var first: int = surf.positions.size()
		for step: Vector3 in PackedVector3Array([Vector3.ZERO, Vector3.RIGHT, Vector3(1.0, 1.0, 0.0), Vector3.UP]):
			surf.positions.append(corner + step * QUAD_M)
		surf.indices.append_array(PackedInt32Array([first, first + 1, first + 2, first, first + 2, first + 3]))
	var surfs: Array[Source.Surf] = [surf]
	var found: Source.IslandSet = Source.islands(surfs)
	assert_eq(found.list.size(), 3, "a tira é uma ilha e cada quad solto, outra")
	var rows: Array = []
	for index: int in found.list.size():
		var center_cm: Vector3 = found.list[index].center * 100.0
		rows.append({"island": index, "triangles": found.list[index].tris, "center_cm": [center_cm.x, center_cm.y, center_cm.z], "role": "~skirt"})
	var table: Dictionary = Weights.load_table().duplicate()
	table["roles"] = rows
	_out = Weights.assign(surfs, found, _rig, table)
	assert_eq(_out.errors, PackedStringArray())


func after_all() -> void:
	_rig.skeleton.free()


func _island(center_x: float) -> Source.Island:
	var island: Source.Island = Source.Island.new()
	island.center = Vector3(center_x, COAT_Y, 0.0)
	return island


## O peso total do osso `bone_name` no vértice.
func _weight(vertex: int, bone_name: String) -> float:
	var total: float = 0.0
	for slot: int in Weights.SLOTS:
		if _rig.skeleton.get_bone_name(_out.bones[0][vertex * Weights.SLOTS + slot]) == bone_name:
			total += _out.weights[0][vertex * Weights.SLOTS + slot]
	return total


func test_left_share_is_the_island_side_for_one_sided_islands_and_a_linear_ramp_on_the_point_for_central_ones() -> void:
	for x: float in [-0.2, -0.01, 0.0, 0.01, 0.4]:
		assert_eq(Weights.left_share(Vector3(x, COAT_Y, 0.0), _island(Weights.CENTRAL_M * 4.0)), 1.0, "ilha da esquerda, ponto em x=%.2f" % x)
		assert_eq(Weights.left_share(Vector3(x, COAT_Y, 0.0), _island(-Weights.CENTRAL_M * 4.0)), 0.0, "ilha da direita, ponto em x=%.2f" % x)
	var center: Source.Island = _island(0.0)
	var half: float = Weights.SIDE_BLEND_M
	assert_eq([Weights.left_share(Vector3(-half * 2.0, 0.0, 0.0), center), Weights.left_share(Vector3(-half, 0.0, 0.0), center), Weights.left_share(Vector3.ZERO, center), Weights.left_share(Vector3(half, 0.0, 0.0), center), Weights.left_share(Vector3(half * 2.0, 0.0, 0.0), center)], [0.0, 0.0, 0.5, 1.0, 1.0])
	assert_almost_eq(Weights.left_share(Vector3(half * 0.5, 0.0, 0.0), center), 0.75, SUM_TOLERANCE, "linear entre os extremos")


func test_central_coat_follows_its_own_thigh_far_from_the_middle_and_mixes_both_near_it() -> void:
	var worst_sum: float = 0.0
	var shares: Array[float] = []
	for vertex: int in _strip_vertices:
		var x: float = _out_x(vertex)
		var total: float = 0.0
		for slot: int in Weights.SLOTS:
			total += _out.weights[0][vertex * Weights.SLOTS + slot]
		worst_sum = maxf(worst_sum, absf(total - 1.0))
		if x > Weights.SIDE_BLEND_M:
			assert_eq(_weight(vertex, "thigh_r"), 0.0, "o lado esquerdo do casaco não puxa a coxa direita (x=%.2f)" % x)
		if x < -Weights.SIDE_BLEND_M:
			assert_eq(_weight(vertex, "thigh_l"), 0.0, "o lado direito não puxa a coxa esquerda (x=%.2f)" % x)
		if absf(x) < SYMMETRY_TOLERANCE:
			assert_almost_eq(_weight(vertex, "thigh_l"), _weight(vertex, "thigh_r"), SYMMETRY_TOLERANCE, "no meio as duas coxas pesam igual")
			assert_gt(_weight(vertex, "thigh_l"), 0.0)
		if is_equal_approx(_out_y(vertex), COAT_Y) and absf(x) <= Weights.SIDE_BLEND_M:
			shares.append(_weight(vertex, "thigh_l") / (_weight(vertex, "thigh_l") + _weight(vertex, "thigh_r")))
	assert_lt(worst_sum, SUM_TOLERANCE, "os pesos somam 1 também na mistura")
	for index: int in range(1, shares.size()):
		assert_gte(shares[index], shares[index - 1] - SUM_TOLERANCE, "na faixa do meio, a parte da coxa esquerda só cresce com X")


func test_one_sided_coat_pieces_follow_only_their_own_thigh() -> void:
	var left_first: int = _strip_vertices
	var right_first: int = _strip_vertices + QUAD_VERTICES
	for offset: int in QUAD_VERTICES:
		assert_gt(_weight(left_first + offset, "thigh_l"), 0.0)
		assert_eq(_weight(left_first + offset, "thigh_r"), 0.0)
		assert_gt(_weight(right_first + offset, "thigh_r"), 0.0)
		assert_eq(_weight(right_first + offset, "thigh_l"), 0.0)


func _out_x(vertex: int) -> float:
	return STRIP_START_X + floori(vertex / float(QUAD_VERTICES)) * QUAD_M + (QUAD_M if vertex % QUAD_VERTICES in [1, 2] else 0.0)


func _out_y(vertex: int) -> float:
	return COAT_Y + (QUAD_M if vertex % QUAD_VERTICES in [2, 3] else 0.0)
