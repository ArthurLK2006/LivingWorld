extends GutTest
## LW-099a: as bordas do `CaravanPath` (sem janela). O giro olha `LOOKAHEAD_M` à frente (a corda), então uma curva mais fechada que isso NÃO tem tangente única: na
## meia-volta EXATA a corda é nula (giro 0 e sem deslocamento lateral) e, perto dela, o giro vira quase meia-volta em poucos decímetros e o deslocamento lateral
## troca de lado (a posição salta até 2 vezes o deslocamento). É característica do DADO da estrada (as 3 rotas reais são retas; polilinha com curva assim não deve
## entrar), não um defeito a corrigir nesta tarefa: os testes só a documentam e garantem pose finita e posição contínua. Também: deslocamento lateral negativo
## (esquerda), `u` e `lateral_m` que não são número, e polilinha de um ponto só.

const EPS: float = 0.0001
const LATERAL_M: float = 1.2
const STEPS: int = 960
## Ida e volta de 8 m, com a meia-volta aos 8 m: aos 7 m (7/16 do comprimento) a janela de 2 m à frente a cobre de ponta a ponta; frações binárias exatas, então a corda nula é exata.
const U_TURN: PackedVector2Array = [Vector2(0, 0), Vector2(8, 0), Vector2(0, 0)]
const BEFORE_U_TURN_U: float = 7.0 / 16.0
## Quase meia-volta aos 8 m: a volta passa 0,5 m ao lado da ida. A margem alarga a janela onde o giro pode saltar (2 m antes da curva até a curva).
const NEAR_U_TURN: PackedVector2Array = [Vector2(0, 0), Vector2(8, 0), Vector2(0, 0.5)]
const TURN_AT_M: float = 8.0
const WINDOW_MARGIN_M: float = 0.1
const EAST: PackedVector2Array = [Vector2(0, 0), Vector2(100, 0)]
const ONE_POINT: Vector2 = Vector2(5, 6)


func _pose(path: CaravanPath, u: float, forward: bool = true, lateral_m: float = 0.0) -> CaravanPath.Pose:
	var pose: CaravanPath.Pose = CaravanPath.Pose.new()
	path.sample_into(u, forward, lateral_m, pose)
	return pose


func _is_finite(pose: CaravanPath.Pose) -> bool:
	return pose.position.is_finite() and is_finite(pose.yaw)


func _near(got: Vector2, expected: Vector2, why: String) -> void:
	assert_true(got.distance_to(expected) < EPS, "%s: veio %s, esperado %s" % [why, got, expected])


func test_an_exact_u_turn_has_a_null_chord_so_no_yaw_and_no_lateral_offset() -> void:
	var path: CaravanPath = CaravanPath.new(U_TURN)
	for forward: bool in [true, false]:
		var pose: CaravanPath.Pose = _pose(path, BEFORE_U_TURN_U, forward, LATERAL_M)
		assert_eq(pose.yaw, 0.0, "corda nula: giro 0 (forward = %s)" % forward)
		assert_eq(pose.position, Vector2(7, 0), "e sem deslocamento lateral: fica na linha da estrada (forward = %s)" % forward)
	var finite: bool = true
	for index: int in range(STEPS + 1):
		finite = finite and _is_finite(_pose(path, float(index) / float(STEPS), true, LATERAL_M))
	assert_true(finite, "pose finita em toda a ida e volta, inclusive na corda nula")


func test_a_near_u_turn_flips_the_yaw_within_one_lookahead_and_the_data_owns_the_corner() -> void:
	var path: CaravanPath = CaravanPath.new(NEAR_U_TURN)
	var step_m: float = path.length_m() / float(STEPS)
	var previous: CaravanPath.Pose = _pose(path, 0.0)
	var previous_offset: CaravanPath.Pose = _pose(path, 0.0, true, LATERAL_M)
	var finite: bool = true
	var worst_inside: float = 0.0
	var worst_outside: float = 0.0
	var worst_excess: float = 0.0
	var worst_jump: float = 0.0
	for index: int in range(1, STEPS + 1):
		var u: float = float(index) / float(STEPS)
		var here: CaravanPath.Pose = _pose(path, u)
		var offset: CaravanPath.Pose = _pose(path, u, true, LATERAL_M)
		var turn: float = absf(angle_difference(previous.yaw, here.yaw))
		var travelled: float = u * path.length_m()
		if travelled > TURN_AT_M - CaravanPath.LOOKAHEAD_M - WINDOW_MARGIN_M and travelled < TURN_AT_M + WINDOW_MARGIN_M:
			worst_inside = maxf(worst_inside, turn)
		else:
			worst_outside = maxf(worst_outside, turn)
		worst_excess = maxf(worst_excess, here.position.distance_to(previous.position) - step_m)
		worst_jump = maxf(worst_jump, offset.position.distance_to(previous_offset.position))
		finite = finite and _is_finite(here) and _is_finite(offset)
		previous = here
		previous_offset = offset
	assert_true(finite, "pose sempre finita")
	assert_lt(worst_excess, EPS, "a posição (sem deslocamento) segue contínua: nenhum passo passa da fração andada")
	assert_lt(worst_outside, 0.02, "fora da janela de 2 m antes da curva o giro é contínuo, como em qualquer trecho")
	assert_gt(worst_inside, 0.2, "característica do dado: dentro da janela o giro vira quase meia-volta em poucos passos (medido 0,52 rad por passo de 1,7 cm); não exige mudança")
	assert_lt(worst_jump, step_m + 2.0 * LATERAL_M, "com deslocamento lateral a posição salta no máximo 2 vezes o deslocamento além do passo (medido 0,62 m)")


func test_a_negative_lateral_offset_is_to_the_left_and_shares_the_lane_of_the_way_back() -> void:
	var path: CaravanPath = CaravanPath.new(EAST)
	var left: Vector2 = _pose(path, 0.5, true, -LATERAL_M).position
	_near(left, Vector2(50, -LATERAL_M), "lateral negativo é a esquerda: para o leste, ao norte (-z)")
	_near(left, _pose(path, 0.5, false, LATERAL_M).position, "a esquerda de quem vai é a direita de quem volta: a mesma faixa")


func test_inputs_that_are_not_numbers_never_poison_the_pose() -> void:
	var path: CaravanPath = CaravanPath.new(NEAR_U_TURN)
	var finite: bool = true
	for forward: bool in [true, false]:
		for bad: float in [NAN, INF, -INF]:
			finite = finite and _is_finite(_pose(path, bad, forward, LATERAL_M)) and _is_finite(_pose(path, 0.5, forward, bad))
			_near(_pose(path, 0.5, forward, bad).position, _pose(path, 0.5, forward).position, "lateral %s vale 0" % bad)
		assert_eq(_pose(path, NAN, forward, LATERAL_M).yaw, _pose(path, 0.0, forward, LATERAL_M).yaw, "u NaN vale 0 (giro)")
		_near(_pose(path, NAN, forward, LATERAL_M).position, _pose(path, 0.0, forward, LATERAL_M).position, "u NaN vale 0 (posição)")
	assert_true(finite, "u e lateral_m que não são número (NaN, infinito) nunca dão pose não finita")


func test_a_one_point_polyline_stays_on_its_point() -> void:
	var paths: Array[CaravanPath] = [CaravanPath.new(PackedVector2Array([ONE_POINT])), CaravanPath.through(ONE_POINT, PackedVector2Array(), ONE_POINT)]
	for path: CaravanPath in paths:
		var stays: bool = path.length_m() == 0.0
		for forward: bool in [true, false]:
			for u: float in [0.0, 0.5, 1.0, NAN]:
				var pose: CaravanPath.Pose = _pose(path, u, forward, LATERAL_M)
				stays = stays and pose.position == ONE_POINT and pose.yaw == 0.0
		assert_true(stays, "um ponto só (ou duas pontas iguais) não tem comprimento: a pose é sempre o ponto, giro 0, sem deslocamento lateral")
