extends GutTest
## ART-12, entrega 6i: a PAREDE DO TRONCO nos pesos do Ice Warrior (`Weights.wall_share`, `Weights.wall_arm_keep` e a retenção do peso do braço e da clavícula no conjunto `body`), por PROPRIEDADES, com geometria SINTÉTICA (um quad por ponto) e a tabela real de papéis acrescida do conjunto `plain` (os MESMOS ossos do `body` com outro nome, que a correção não conhece: o "antes"). A zona e a retenção (`WALL_*` de `Weights`) são parâmetros AJUSTÁVEIS: todo ponto de teste sai dessas constantes e nenhum número de zona ou de retenção está escrito aqui, então reajustá-las não pede mudança no teste. Sem o ativo e sem disco.

const Source = preload("res://tools/visual/ice_figure/ice_source.gd")
const Skel = preload("res://tools/visual/ice_figure/ice_skeleton.gd")
const Weights = preload("res://tools/visual/ice_figure/ice_weights.gd")
const QUAD_M: float = 0.02
const OUTSIDE_M: float = 0.02
const TOLERANCE: float = 0.00001
const RATIO_TOLERANCE: float = 0.0001
const GRID_STEPS: int = 12
const EDGE_STEPS: int = 8
const SCAN_STEPS: int = 130
const BODY_ROLE: String = "~body"
const PLAIN_ROLE: String = "~plain"
const ARM_BASES: PackedStringArray = ["clavicle", "upperarm", "lowerarm", "hand"]
const OTHER_SETS: PackedStringArray = ["plain", "torso", "skirt", "leg", "knee"]

var _rig: Skel.Rig
var _table: Dictionary


func before_all() -> void:
	_rig = Skel.build(CharacterCatalog.from_file().catalog, Skel.load_landmarks())
	_table = Weights.load_table().duplicate()
	var sets: Dictionary = (_table["sets"] as Dictionary).duplicate()
	sets["plain"] = sets["body"]
	_table["sets"] = sets


func after_all() -> void:
	_rig.skeleton.free()


func _mid(first: float, second: float) -> float:
	return (first + second) * 0.5


## A caixa da zona em passos iguais, dos dois lados: |x| até WALL_X_NONE_M e y de WALL_Y_NONE_LOW_M a WALL_Y_NONE_HIGH_M (dentro e nas bordas).
func _grid() -> PackedVector3Array:
	var points: PackedVector3Array = PackedVector3Array()
	for column: int in GRID_STEPS + 1:
		for row: int in GRID_STEPS + 1:
			points.append(Vector3(lerpf(-Weights.WALL_X_NONE_M, Weights.WALL_X_NONE_M, float(column) / GRID_STEPS), lerpf(Weights.WALL_Y_NONE_LOW_M, Weights.WALL_Y_NONE_HIGH_M, float(row) / GRID_STEPS), 0.0))
	return points


## A parede em linhas finas (passo de cerca de 2 mm em x, só o lado direito, em três alturas da faixa cheia): onde um osso do braço e um do tronco disputam um dos K_NEAREST lugares, que a grade larga pode não pegar.
func _wall_scan() -> PackedVector3Array:
	var points: PackedVector3Array = PackedVector3Array()
	for fraction: float in [0.0, 0.5, 1.0]:
		for step: int in SCAN_STEPS + 1:
			points.append(Vector3(-Weights.WALL_X_NONE_M * float(step) / SCAN_STEPS, lerpf(Weights.WALL_Y_FULL_LOW_M, Weights.WALL_Y_FULL_HIGH_M, fraction), 0.0))
	return points


## Pontos logo fora da zona (a OUTSIDE_M da borda externa): ao lado, abaixo e acima da parede, onde o braço e o tronco ainda se misturam.
func _outside() -> PackedVector3Array:
	var wall_x: float = _mid(Weights.WALL_X_FULL_M, Weights.WALL_X_NONE_M)
	var beyond: float = Weights.WALL_X_NONE_M + OUTSIDE_M
	var middle: float = _mid(Weights.WALL_Y_FULL_LOW_M, Weights.WALL_Y_FULL_HIGH_M)
	return PackedVector3Array([Vector3(beyond, middle, 0.0), Vector3(-beyond, middle, 0.0), Vector3(-wall_x, Weights.WALL_Y_NONE_LOW_M - OUTSIDE_M, 0.0), Vector3(-wall_x, Weights.WALL_Y_NONE_HIGH_M + OUTSIDE_M, 0.0), Vector3(wall_x, Weights.WALL_Y_NONE_HIGH_M + OUTSIDE_M, 0.0)])


## Os pesos (osso -> peso, só os não nulos) do vértice 0 de um quad com o canto em `point`, com `role` na ilha única.
func _weights(point: Vector3, role: String) -> Dictionary[String, float]:
	var surf: Source.Surf = Source.Surf.new()
	for step: Vector3 in PackedVector3Array([Vector3.ZERO, Vector3.RIGHT, Vector3(1.0, 1.0, 0.0), Vector3.UP]):
		surf.positions.append(point + step * QUAD_M)
	surf.indices.append_array(PackedInt32Array([0, 1, 2, 0, 2, 3]))
	var surfs: Array[Source.Surf] = [surf]
	var found: Source.IslandSet = Source.islands(surfs)
	var center_cm: Vector3 = found.list[0].center / Skel.CM
	var table: Dictionary = _table.duplicate()
	table["roles"] = [{"island": 0, "triangles": found.list[0].tris, "center_cm": [center_cm.x, center_cm.y, center_cm.z], "role": role}]
	var out: Weights.Assigned = Weights.assign(surfs, found, _rig, table)
	assert_eq(out.errors, PackedStringArray(), "a linha da tabela bate com a ilha")
	var result: Dictionary[String, float] = {}
	for slot: int in Weights.SLOTS:
		if out.weights[0][slot] > 0.0:
			result[_rig.skeleton.get_bone_name(out.bones[0][slot])] = out.weights[0][slot]
	return result


func _is_arm(bone_name: String) -> bool:
	return ARM_BASES.has(bone_name.trim_suffix(Skel.side_suffix(bone_name)))


func _total(weights: Dictionary[String, float]) -> float:
	var total: float = 0.0
	for bone_name: String in weights:
		total += weights[bone_name]
	return total


func _arm(weights: Dictionary[String, float]) -> float:
	var total: float = 0.0
	for bone_name: String in weights:
		total += weights[bone_name] if _is_arm(bone_name) else 0.0
	return total


func _names(weights: Dictionary[String, float]) -> Array:
	var names: Array = weights.keys()
	names.sort()
	return names


func _same(first: Dictionary[String, float], second: Dictionary[String, float]) -> bool:
	if _names(first) != _names(second):
		return false
	for bone_name: String in first:
		if absf(first[bone_name] - second[bone_name]) > TOLERANCE:
			return false
	return true


func _mirror(bone_name: String) -> String:
	var side: String = Skel.side_suffix(bone_name)
	if side.is_empty():
		return bone_name
	return bone_name.trim_suffix(side) + (Skel.RIGHT if side == Skel.LEFT else Skel.LEFT)


## Verdadeiro se o share sobe (ou cai) a cada passo ao longo da borda de `from` a `to`.
func _strictly(from: Vector3, to: Vector3, rising: bool) -> bool:
	var direction: float = 1.0 if rising else -1.0
	var previous: float = Weights.wall_share(from)
	for step: int in range(1, EDGE_STEPS + 1):
		var share: float = Weights.wall_share(from.lerp(to, float(step) / EDGE_STEPS))
		if (share - previous) * direction <= 0.0:
			return false
		previous = share
	return true


## Confere, para cada par (osso do braço, osso do tronco) de um vértice com os mesmos ossos antes e depois, que a razão entre os dois cai exatamente na retenção do ponto (a normalização some da razão); devolve quantos pares conferiu.
func _check_ratios(point: Vector3, before: Dictionary[String, float], after: Dictionary[String, float]) -> int:
	var keep: float = Weights.wall_arm_keep(point, "body")
	var checked: int = 0
	for arm_bone: String in after:
		for trunk_bone: String in after:
			if _is_arm(arm_bone) and not _is_arm(trunk_bone):
				checked += 1
				assert_almost_eq(after[arm_bone] / after[trunk_bone], keep * before[arm_bone] / before[trunk_bone], RATIO_TOLERANCE, "%s contra %s: %s" % [arm_bone, trunk_bone, point])
	return checked


func test_wall_share_is_between_zero_and_one_zero_outside_and_one_in_the_full_zone() -> void:
	for point: Vector3 in _grid():
		assert_between(Weights.wall_share(point), 0.0, 1.0, "entre 0 e 1: %s" % point)
	for point: Vector3 in _outside():
		assert_eq(Weights.wall_share(point), 0.0, "fora da zona: %s" % point)
	var middle: float = _mid(Weights.WALL_Y_FULL_LOW_M, Weights.WALL_Y_FULL_HIGH_M)
	for x: float in [-Weights.WALL_X_FULL_M, 0.0, Weights.WALL_X_FULL_M]:
		for y: float in [Weights.WALL_Y_FULL_LOW_M, middle, Weights.WALL_Y_FULL_HIGH_M]:
			assert_almost_eq(Weights.wall_share(Vector3(x, y, 0.0)), 1.0, TOLERANCE, "zona cheia: x %s, y %s" % [x, y])
	for edge: Vector3 in PackedVector3Array([Vector3(Weights.WALL_X_NONE_M, middle, 0.0), Vector3(-Weights.WALL_X_NONE_M, middle, 0.0), Vector3(0.0, Weights.WALL_Y_NONE_LOW_M, 0.0), Vector3(0.0, Weights.WALL_Y_NONE_HIGH_M, 0.0)]):
		assert_almost_eq(Weights.wall_share(edge), 0.0, TOLERANCE, "borda externa: %s" % edge)


func test_wall_share_changes_smoothly_across_the_transitions_and_is_symmetric_in_x() -> void:
	var middle: float = _mid(Weights.WALL_Y_FULL_LOW_M, Weights.WALL_Y_FULL_HIGH_M)
	for side: float in [1.0, -1.0]:
		assert_true(_strictly(Vector3(Weights.WALL_X_FULL_M * side, middle, 0.0), Vector3(Weights.WALL_X_NONE_M * side, middle, 0.0), false), "em |x| só cai, no lado %s" % side)
		assert_almost_eq(Weights.wall_share(Vector3(_mid(Weights.WALL_X_FULL_M, Weights.WALL_X_NONE_M) * side, middle, 0.0)), 0.5, TOLERANCE, "metade no meio da transição em |x|, lado %s" % side)
	assert_true(_strictly(Vector3(0.0, Weights.WALL_Y_NONE_LOW_M, 0.0), Vector3(0.0, Weights.WALL_Y_FULL_LOW_M, 0.0), true), "em y só sobe até a faixa cheia")
	assert_true(_strictly(Vector3(0.0, Weights.WALL_Y_FULL_HIGH_M, 0.0), Vector3(0.0, Weights.WALL_Y_NONE_HIGH_M, 0.0), false), "em y só cai depois da faixa cheia")
	assert_almost_eq(Weights.wall_share(Vector3(0.0, _mid(Weights.WALL_Y_NONE_LOW_M, Weights.WALL_Y_FULL_LOW_M), 0.0)), 0.5, TOLERANCE, "metade no meio da subida em y")
	assert_almost_eq(Weights.wall_share(Vector3(0.0, _mid(Weights.WALL_Y_FULL_HIGH_M, Weights.WALL_Y_NONE_HIGH_M), 0.0)), 0.5, TOLERANCE, "metade no meio da queda em y")
	for point: Vector3 in _grid():
		assert_almost_eq(Weights.wall_share(point), Weights.wall_share(Vector3(-point.x, point.y, point.z)), TOLERANCE, "o mesmo nos dois lados: %s" % point)


func test_the_arm_retention_reduces_and_only_the_body_set_is_corrected() -> void:
	assert_gt(Weights.WALL_ARM_KEEP, 0.0, "retém algo do braço")
	assert_lt(Weights.WALL_ARM_KEEP, 1.0, "mas menos que tudo: reduz")
	var center: Vector3 = Vector3(0.0, _mid(Weights.WALL_Y_FULL_LOW_M, Weights.WALL_Y_FULL_HIGH_M), 0.0)
	assert_almost_eq(Weights.wall_arm_keep(center, "body"), Weights.WALL_ARM_KEEP, TOLERANCE, "no centro da zona a retenção é inteira")
	for point: Vector3 in _outside():
		assert_eq(Weights.wall_arm_keep(point, "body"), 1.0, "fora da zona retém tudo: %s" % point)
	for other_set: String in OTHER_SETS:
		assert_eq(Weights.wall_arm_keep(center, other_set), 1.0, "outro conjunto não é corrigido: %s" % other_set)


func test_over_the_zone_the_arm_never_gains_weight_and_the_trunk_takes_the_rest() -> void:
	var reduced: int = 0
	var ratios: int = 0
	for point: Vector3 in _grid():
		var before: Dictionary[String, float] = _weights(point, PLAIN_ROLE)
		var after: Dictionary[String, float] = _weights(point, BODY_ROLE)
		assert_almost_eq(_total(after), 1.0, TOLERANCE, "os pesos somam 1: %s" % point)
		assert_lte(after.size(), Weights.K_NEAREST, "nenhuma influência a mais: %s" % point)
		assert_lte(_arm(after), _arm(before) + TOLERANCE, "o braço e a clavícula nunca ganham peso: %s" % point)
		assert_gte(_total(after) - _arm(after), _total(before) - _arm(before) - TOLERANCE, "o tronco nunca perde peso: %s" % point)
		if Weights.wall_share(point) < TOLERANCE:
			assert_true(_same(after, before), "fora da zona fica idêntico: %s" % point)
			continue
		reduced += 1 if _arm(after) < _arm(before) - TOLERANCE else 0
		if _names(after) == _names(before):
			ratios += _check_ratios(point, before, after)
	assert_gt(reduced, 0, "a redução existe em algum ponto da zona")
	assert_gt(ratios, 0, "e a razão braço/tronco foi conferida em algum ponto")


func test_the_correction_lets_a_trunk_bone_into_the_vertex_before_the_nearest_bones_are_chosen() -> void:
	var entered: int = 0
	for point: Vector3 in _wall_scan():
		var before: Dictionary[String, float] = _weights(point, PLAIN_ROLE)
		var after: Dictionary[String, float] = _weights(point, BODY_ROLE)
		for bone_name: String in after:
			if not _is_arm(bone_name) and not before.has(bone_name):
				entered += 1
				break
	assert_gt(entered, 0, "um osso do tronco entra no lugar de um do braço: o peso bruto do braço cai ANTES da escolha dos K_NEAREST, não depois")


func test_the_mirrored_vertex_gets_the_mirrored_weights() -> void:
	for point: Vector3 in _grid():
		var right: Dictionary[String, float] = _weights(point, BODY_ROLE)
		var left: Dictionary[String, float] = _weights(Vector3(-point.x, point.y, point.z), BODY_ROLE)
		assert_eq(left.size(), right.size(), "as mesmas influências: %s" % point)
		for bone_name: String in right:
			assert_almost_eq(left.get(_mirror(bone_name), -1.0), right[bone_name], TOLERANCE, "%s espelhado: %s" % [bone_name, point])


func test_vertices_outside_the_zone_and_the_rigid_sword_keep_their_uncorrected_weights() -> void:
	for point: Vector3 in _outside():
		assert_true(_same(_weights(point, BODY_ROLE), _weights(point, PLAIN_ROLE)), "idêntico ao de antes: %s" % point)
	var sword: Dictionary[String, float] = _weights(Vector3(-Weights.WALL_X_FULL_M, _mid(Weights.WALL_Y_FULL_LOW_M, Weights.WALL_Y_FULL_HIGH_M), 0.0), "sword")
	assert_eq([sword.keys(), sword.values()], [["hand_r"], [1.0]], "a espada é rígida na mão, mesmo dentro da zona")


func test_the_arm_group_names_the_arm_chain_and_real_bones_of_both_sides() -> void:
	assert_eq(Weights.ARM_BONES.size(), ARM_BASES.size(), "a cadeia do braço: clavícula, braço, antebraço e mão")
	for base: String in ARM_BASES:
		assert_true(Weights.ARM_BONES.has(base), "%s está no grupo" % base)
		for side: String in [Skel.LEFT, Skel.RIGHT]:
			assert_gte(_rig.skeleton.find_bone(base + side), 0, "%s existe no esqueleto" % (base + side))
