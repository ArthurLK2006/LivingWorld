extends GutTest
## ART-12, entrega 6c-ii: os pesos do Ice Warrior (papéis por ilha, conferência da tabela, pesos suaves com rampa na perna) com geometria SINTÉTICA e a tabela real de papéis; o caso com o arquivo real PULA se o ativo (fora do Git) não existir.

const Source = preload("res://tools/visual/ice_figure/ice_source.gd")
const Skel = preload("res://tools/visual/ice_figure/ice_skeleton.gd")
const Weights = preload("res://tools/visual/ice_figure/ice_weights.gd")
const QUAD_M: float = 0.02
const SUM_TOLERANCE: float = 0.00001
const SHA_HEX_LENGTH: int = 64
const OFF_BY_CM: float = 5.0
const QUAD_VERTICES: int = 4
const EXPECTED_ROLES: int = 45

var _rig: Skel.Rig
var _table: Dictionary


func before_all() -> void:
	_rig = Skel.build(CharacterCatalog.from_file().catalog, Skel.load_landmarks())
	_table = Weights.load_table()


func after_all() -> void:
	_rig.skeleton.free()


## Uma superfície só, com um quad pequeno (4 vértices, 2 triângulos) por canto dado; quads que dividem uma aresta se soldam numa ilha.
func _surfs(corners: PackedVector3Array) -> Array[Source.Surf]:
	var surf: Source.Surf = Source.Surf.new()
	for corner: Vector3 in corners:
		var first: int = surf.positions.size()
		for step: Vector3 in PackedVector3Array([Vector3.ZERO, Vector3.RIGHT, Vector3(1.0, 1.0, 0.0), Vector3.UP]):
			surf.positions.append(corner + step * QUAD_M)
		surf.indices.append_array(PackedInt32Array([first, first + 1, first + 2, first, first + 2, first + 3]))
	var surfs: Array[Source.Surf] = [surf]
	return surfs


## A tabela real (conjuntos, alias, tolerância) com as linhas dadas; cada linha pega triângulos e centroide da ilha achada, mudando só o papel.
func _assign(corners: PackedVector3Array, roles: PackedStringArray, wrong_tris: int = 0, off_cm: float = 0.0) -> Weights.Assigned:
	var surfs: Array[Source.Surf] = _surfs(corners)
	var found: Source.IslandSet = Source.islands(surfs)
	var rows: Array = []
	for index: int in roles.size():
		var center_cm: Vector3 = found.list[index].center * 100.0 + Vector3(off_cm, 0.0, 0.0)
		rows.append({"island": index, "triangles": found.list[index].tris + wrong_tris, "center_cm": [center_cm.x, center_cm.y, center_cm.z], "role": roles[index]})
	var table: Dictionary = _table.duplicate()
	table["roles"] = rows
	return Weights.assign(surfs, found, _rig, table)


func _bone(out: Weights.Assigned, vertex: int, slot: int) -> String:
	return _rig.skeleton.get_bone_name(out.bones[0][vertex * Weights.SLOTS + slot])


func test_rigid_role_takes_its_side_from_the_island_and_the_alias_goes_to_the_hand() -> void:
	var out: Weights.Assigned = _assign(PackedVector3Array([Vector3(0.18, 0.08, -0.05), Vector3(-0.2, 0.08, -0.05), Vector3(-0.31, 0.77, 0.0)]), PackedStringArray(["foot", "foot", "sword"]))
	assert_eq(out.errors, PackedStringArray())
	assert_eq([_bone(out, 0, 0), out.weights[0][0], _bone(out, 4, 0), _bone(out, 8, 0)], ["foot_l", 1.0, "foot_r", "hand_r"])
	assert_eq(out.roles.values(), ["foot_l", "foot_r", "hand_r"])


func test_soft_weights_sum_to_one_with_at_most_three_known_bones() -> void:
	var corners: PackedVector3Array = PackedVector3Array()
	for step: int in 5:
		corners.append(Vector3(-0.01, 0.85 + step * QUAD_M, -0.01))
	var out: Weights.Assigned = _assign(corners, PackedStringArray(["~torso"]))
	var torso: PackedStringArray = PackedStringArray(_table["sets"]["torso"])
	for vertex: int in corners.size() * QUAD_VERTICES:
		var total: float = 0.0
		var zeros: int = 0
		for slot: int in Weights.SLOTS:
			total += out.weights[0][vertex * Weights.SLOTS + slot]
			zeros += 1 if out.weights[0][vertex * Weights.SLOTS + slot] == 0.0 else 0
			if out.weights[0][vertex * Weights.SLOTS + slot] > 0.0:
				assert_true(torso.has(_bone(out, vertex, slot)), _bone(out, vertex, slot))
		assert_almost_eq(total, 1.0, SUM_TOLERANCE)
		assert_gte(zeros, 1, "no máximo 3 pesos")


func test_leg_weights_ramp_up_below_the_hip() -> void:
	var out: Weights.Assigned = _assign(PackedVector3Array([Vector3(0.1, 0.9, 0.0), Vector3(0.18, 0.05, -0.04)]), PackedStringArray(["~leg", "~leg"]))
	assert_eq([_bone(out, 0, 0), out.weights[0][0]], ["pelvis", 1.0], "acima do quadril só a pélvis")
	assert_true(["foot_l", "calf_l"].has(_bone(out, 4, 0)), "perto do pé a perna manda")


func test_island_outside_the_table_goes_to_the_nearest_bone() -> void:
	var out: Weights.Assigned = _assign(PackedVector3Array([Vector3(-0.01, 1.31, 0.0)]), PackedStringArray())
	assert_eq([out.errors, out.roles[0], _bone(out, 0, 0)], [PackedStringArray(), "Head", "Head"])


func test_table_rows_that_do_not_match_the_island_are_reported() -> void:
	var triangles: Weights.Assigned = _assign(PackedVector3Array([Vector3(0.18, 0.08, -0.05)]), PackedStringArray(["foot"]), 1)
	assert_string_contains(triangles.errors[0], "a ilha 0 não bate com a tabela de papéis: 2 triângulos (tabela 3)")
	var apart: Weights.Assigned = _assign(PackedVector3Array([Vector3(0.18, 0.08, -0.05)]), PackedStringArray(["foot"]), 0, OFF_BY_CM)
	assert_string_contains(apart.errors[0], "centro a 5.0 cm")
	var unknown: Weights.Assigned = _assign(PackedVector3Array([Vector3(0.18, 0.08, -0.05)]), PackedStringArray(["wing"]))
	assert_string_contains(unknown.errors[0], "papel desconhecido")


func test_real_role_table_names_only_known_roles() -> void:
	var rows: Array = _table["roles"]
	var seen: Dictionary[int, bool] = {}
	for row: Dictionary in rows:
		assert_false(seen.has(int(row["island"])), "ilha repetida")
		seen[int(row["island"])] = true
		var role: String = (_table["aliases"] as Dictionary).get(row["role"], row["role"])
		var known: bool = (_table["sets"] as Dictionary).has(role.trim_prefix(Weights.SOFT)) if role.begins_with(Weights.SOFT) else _rig.skeleton.find_bone(role) >= 0 or _rig.skeleton.find_bone(role + Skel.LEFT) >= 0
		assert_true(known, "papel %s da ilha %d" % [role, int(row["island"])])
	assert_eq([rows.size(), (_table["source"]["sha256"] as String).length()], [EXPECTED_ROLES, SHA_HEX_LENGTH])


func test_real_asset_matches_the_role_table_and_weights_sum_to_one() -> void:
	if not FileAccess.file_exists(Source.SOURCE_PATH):
		pending("ativo ausente (fica fora do Git): %s" % Source.SOURCE_PATH)
		return
	var surfs: Array[Source.Surf] = Source.load_surfaces()
	var out: Weights.Assigned = Weights.assign(surfs, Source.islands(surfs), _rig, _table)
	assert_eq(out.errors, PackedStringArray(), "a tabela bate com as ilhas da fonte")
	assert_eq([out.roles.size(), out.roles[3]], [Source.EXPECTED_ISLANDS, "hand_r"], "a ilha 3 é a espada, rígida na mão direita")
	for index: int in surfs.size():
		for vertex: int in surfs[index].positions.size():
			var total: float = 0.0
			for slot: int in Weights.SLOTS:
				total += out.weights[index][vertex * Weights.SLOTS + slot]
			assert_almost_eq(total, 1.0, SUM_TOLERANCE)
