extends GutTest
## LW-099f (curvas naturais, EXPERIMENTAL): os CANTOS REAIS vistos pela `CaravanBodiesView` com o modo ligado: os 6 trechos de duas pernas (A para C para B e os outros cinco) passados com quadros de 0,5 m, de 1 s de caminhada (2,9 m) e de 1/60 s (0,048 m). Lê as transformações dos corpos. Em cada passagem:
## a troca de trecho é EXATA (posição e giro iguais entre o último quadro de um trecho, `u` = 1, e o primeiro do outro, `u` = 0); nenhum passo do corpo passa de (passo andado) x (a maior velocidade da FAIXA da própria estrada, derivada por varredura fina de `road_of`, com margem de 0,1%): por fora da curva a faixa anda
## (R + 1,2) / R, uns 1,17 com o eixo a 7,2 m; nenhum giro por quadro passa do que o raio dá (1/R do caminho mais a curvatura da rampa da faixa); tudo finito; o corpo é sempre o mesmo; e o giro termina olhando para a estrada nova. Os raios de 4,1, 8 e 10 m e o raio 0 (quinas vivas) também.

const A: String = NaturalCurvesRig.A
const B: String = NaturalCurvesRig.B
const C: String = NaturalCurvesRig.C
const TRADER: int = NaturalCurvesRig.TRADER
const MARKETS: Dictionary[String, Vector2] = NaturalCurvesRig.MARKETS
const PASSAGES: Array = [[A, C, B], [B, C, A], [A, B, C], [C, B, A], [B, A, C], [C, A, B]]
## A troca de trecho: até 1 mm de posição e 0,1 grau de giro.
const JOINT_GAP_M: float = 0.001
const JOINT_TURN_DEG: float = 0.1
## No fim de um trecho (`u` = 1) o corpo está no mercado de chegada, a 1 cm.
const END_TOLERANCE_M: float = 0.01
## O passo do corpo (m) pode passar do andado vezes o fator da faixa em 0,1% e em 0,1 mm (o `Vector2` é float32); o giro por quadro, em 2% e 0,1 mrad.
const STEP_MARGIN: float = 1.001
const STEP_EPSILON_M: float = 0.0001
const TURN_MARGIN: float = 1.02
const TURN_EPSILON_RAD: float = 0.0001
## A maior curvatura (rad/m) que a rampa da faixa soma ao giro: a derivada segunda do smoothstep, 6 / rampa^2, vezes a faixa.
const RAMP_TURN_RATE: float = NaturalCurvesRig.LANE_M * 6.0 / (NaturalCurvesRig.RAMP_M * NaturalCurvesRig.RAMP_M)
## O giro termina olhando para a estrada nova: a corda do carrinho aponta para o mercado de chegada a menos de 1 grau, depois de 35 m do povoado (o arco mais longo, de 141 graus, acaba aos 18 m e a rampa da faixa aos 12).
const LOOK_AHEAD_M: float = 35.0
const LOOK_TOLERANCE_DEG: float = 1.0
const WINDOW_NEAR_M: float = 40.0
const WINDOW_MEDIUM_M: float = 80.0

var _rig: NaturalCurvesRig


## O que uma passagem pelo canto mediu: o pior (positivo = passou do limite) de cada regra.
class Walk:
	extends RefCounted

	var frames: int = 0
	var finite: bool = true
	var same_body: bool = true
	var joint_gap_m: float = 0.0
	var joint_turn_deg: float = 0.0
	var end_gap_m: float = 0.0
	var step_excess_m: float = -INF
	var turn_excess_rad: float = -INF
	var looked: bool = false
	var look_deg: float = 0.0


func before_all() -> void:
	_rig = NaturalCurvesRig.load_world()
	assert_eq(_rig.failure, "", "O mundo de teste e o dado de apresentação carregaram.")


## Anda a caravana pelo trecho de `passage[0]` a `passage[1]` e depois pelo de `passage[1]` a `passage[2]`, de `step_m` em `step_m` (`window_m` metros antes e depois do povoado de passagem; 0 = os trechos inteiros), com o raio `radius_m` do caminho, numa vista nova.
func _walk(passage: Array, step_m: float, window_m: float, radius_m: float = CaravanBodiesView.CURVE_PATH_RADIUS_M) -> Walk:
	assert_true(_rig.start(self))
	_rig.view.set_curve_radius_m(radius_m)
	var walk: Walk = Walk.new()
	var body: CaravanView = null
	var last_spot: Vector2 = Vector2.ZERO
	var last_yaw: float = 0.0
	for leg: int in 2:
		var from: String = passage[leg]
		var to: String = passage[leg + 1]
		var length_m: float = MARKETS[from].distance_to(MARKETS[to])
		var span_m: float = length_m if window_m <= 0.0 else minf(window_m, length_m)
		var count: int = ceili(span_m / step_m)
		var factor: float = 1.0
		var last_u: float = 0.0
		for k: int in count + 1:
			var share: float = float(k) / float(count)
			var u: float = 1.0 - span_m / length_m * (1.0 - share) if leg == 0 else span_m / length_m * share
			var current: CaravanView = _rig.go(from, to, u)
			if current == null or (body != null and current != body):
				walk.same_body = false
				continue
			body = current
			var spot: Vector2 = NaturalCurvesRig.spot_of(current)
			var yaw: float = current.rotation.y
			if not (spot.is_finite() and is_finite(yaw) and is_finite(current.rotation.x)):
				walk.finite = false
				continue
			walk.frames += 1
			var road: CaravanRoad = _rig.view.road_of(TRADER)
			if u >= 1.0:
				walk.end_gap_m = maxf(walk.end_gap_m, spot.distance_to(MARKETS[to]))
			if k == 0:
				factor = NaturalCurvesRig.max_lane_speed(road)
				if leg == 1:
					walk.joint_gap_m = spot.distance_to(last_spot)
					walk.joint_turn_deg = rad_to_deg(absf(angle_difference(last_yaw, yaw)))
			else:
				var walked_m: float = (u - last_u) * road.length_m()
				walk.step_excess_m = maxf(walk.step_excess_m, spot.distance_to(last_spot) - (walked_m * factor * STEP_MARGIN + STEP_EPSILON_M))
				if radius_m > 0.0:
					walk.turn_excess_rad = maxf(walk.turn_excess_rad, absf(angle_difference(last_yaw, yaw)) - (walked_m * (1.0 / radius_m + RAMP_TURN_RATE) * TURN_MARGIN + TURN_EPSILON_RAD))
			if leg == 1 and not walk.looked and u * road.length_m() >= LOOK_AHEAD_M:
				walk.looked = true
				walk.look_deg = rad_to_deg(absf(angle_difference(yaw, NaturalCurvesRig.yaw_of(MARKETS[to] - spot))))
			last_u = u
			last_spot = spot
			last_yaw = yaw
	return walk


func _check(walk: Walk, label: String, exact_turn: bool = true) -> void:
	gut.p("%s: %d quadros; troca de trecho %.5f mm e %.5f graus; pior passo %+.5f m e pior giro %+.5f rad em relação ao limite; olhar %.3f graus" % [label, walk.frames, walk.joint_gap_m * 1000.0, walk.joint_turn_deg, walk.step_excess_m, walk.turn_excess_rad, walk.look_deg])
	assert_gt(walk.frames, 0, "%s: houve quadros." % label)
	assert_true(walk.finite, "%s: nada de NaN nem infinito." % label)
	assert_true(walk.same_body, "%s: o corpo é SEMPRE o mesmo (nunca dois, nenhum quadro sem corpo)." % label)
	assert_lt(walk.joint_gap_m, JOINT_GAP_M, "%s: troca de trecho, posição entre o último e o primeiro quadro (m)." % label)
	assert_lt(walk.end_gap_m, END_TOLERANCE_M, "%s: no fim de cada trecho andado (u = 1) o corpo está no mercado de chegada (m)." % label)
	if exact_turn:
		assert_lt(walk.joint_turn_deg, JOINT_TURN_DEG, "%s: troca de trecho, giro entre o último e o primeiro quadro (graus)." % label)
		assert_lte(walk.turn_excess_rad, 0.0, "%s: nenhum giro por quadro passa do que o raio dá (excesso em rad)." % label)
		assert_true(walk.looked, "%s: a caravana andou %.0f m depois do povoado." % [label, LOOK_AHEAD_M])
		assert_lt(walk.look_deg, LOOK_TOLERANCE_DEG, "%s: o giro termina olhando para a estrada nova (graus de erro)." % label)
	assert_lte(walk.step_excess_m, 0.0, "%s: nenhum passo do corpo passa do andado vezes o fator da faixa (excesso em m)." % label)


func _label(passage: Array, step_m: float, radius_m: float = CaravanBodiesView.CURVE_PATH_RADIUS_M) -> String:
	return "%s, %s, %s (quadro de %.3f m, raio %.1f m)" % [passage[0].right(1), passage[1].right(1), passage[2].right(1), step_m, radius_m]


func test_the_six_real_corners_with_frames_of_half_a_metre() -> void:
	for passage: Array in PASSAGES:
		_check(_walk(passage, 0.5, WINDOW_MEDIUM_M), _label(passage, 0.5))


func test_the_six_real_corners_with_frames_of_a_second_of_walking_along_the_whole_legs() -> void:
	for passage: Array in PASSAGES:
		_check(_walk(passage, NaturalCurvesRig.WALK_MPS, 0.0), _label(passage, NaturalCurvesRig.WALK_MPS))


func test_the_six_real_corners_with_frames_of_a_sixtieth_of_a_second() -> void:
	var step_m: float = NaturalCurvesRig.WALK_MPS * NaturalCurvesRig.FRAME_S
	for passage: Array in PASSAGES:
		_check(_walk(passage, step_m, WINDOW_NEAR_M), _label(passage, step_m))


func test_the_other_radii_of_the_study_have_the_same_exact_joint_and_no_jump() -> void:
	for radius_m: float in [4.1, 8.0, 10.0]:
		for passage: Array in [[A, C, B], [C, A, B]]:
			_check(_walk(passage, 0.5, WINDOW_MEDIUM_M, radius_m), _label(passage, 0.5, radius_m))


func test_with_sharp_corners_radius_zero_the_body_still_turns_by_the_rope_and_stays_finite_and_continuous() -> void:
	for passage: Array in [[A, C, B], [C, A, B]]:
		var walk: Walk = _walk(passage, 0.5, WINDOW_MEDIUM_M, 0.0)
		var label: String = _label(passage, 0.5, 0.0)
		assert_gt(walk.frames, 0, "%s: houve quadros." % label)
		assert_true(walk.finite, "%s: sem arco, tudo finito." % label)
		assert_true(walk.same_body, "%s: o mesmo corpo." % label)
		assert_lt(walk.joint_gap_m, JOINT_GAP_M, "%s: a posição não salta (a quina é viva, o giro estala)." % label)
		assert_gt(walk.joint_turn_deg, 30.0, "%s: sem arco o giro estala na quina (%.1f graus): é o 'hoje' sem o limite por metro." % [label, walk.joint_turn_deg])
		assert_lte(walk.step_excess_m, 0.0, "%s: nenhum passo passa do andado vezes o fator da faixa." % label)


## A volta de 180 graus no povoado de passagem (A para B e depois B para A, e um 3º trecho A para C): a estrada herdada não tem arco, então a caravana usa o caminho de HOJE (giro limitado por metro) pelo RESTO da viagem, sem estalo e com o mesmo corpo.
func test_a_u_turn_at_the_passage_settlement_goes_back_to_the_limited_turn_of_today_for_the_rest_of_the_trip() -> void:
	assert_true(_rig.start(self))
	var legs: Array = [[A, B, 0.85, 1.0, 0.5], [B, A, 0.0, 1.0, NaturalCurvesRig.WALK_MPS], [A, C, 0.0, 0.1, 0.5]]
	var body: CaravanView = null
	var last_spot: Vector2 = Vector2.ZERO
	var last_yaw: float = 0.0
	var healthy: bool = true
	var wheels: bool = true
	var worst_excess: float = -INF
	var joints: Array[Vector2] = []
	var natural: Array[bool] = []
	var end_yaw: float = 0.0
	for index: int in legs.size():
		var leg: Array = legs[index]
		var length_m: float = MARKETS[leg[0]].distance_to(MARKETS[leg[1]])
		var count: int = ceili((float(leg[3]) - float(leg[2])) * length_m / float(leg[4]))
		for k: int in count + 1:
			var current: CaravanView = _rig.go(leg[0], leg[1], lerpf(float(leg[2]), float(leg[3]), float(k) / float(count)))
			if current == null or (body != null and current != body) or not (NaturalCurvesRig.spot_of(current).is_finite() and is_finite(current.rotation.y)):
				healthy = false
				continue
			body = current
			var spot: Vector2 = NaturalCurvesRig.spot_of(current)
			var moved: float = spot.distance_to(last_spot)
			var turned: float = absf(angle_difference(last_yaw, current.rotation.y))
			wheels = wheels and current.wheel_differential()
			if k == 0:
				natural.append(_rig.view.road_of(TRADER) != null)
				if index > 0:
					joints.append(Vector2(moved, rad_to_deg(turned)))
			else:
				worst_excess = maxf(worst_excess, turned - (CaravanBodiesView.TURN_RAD_PER_M * moved * TURN_MARGIN + TURN_EPSILON_RAD))
			if index == 1 and k == count:
				end_yaw = current.rotation.y
			last_spot = spot
			last_yaw = current.rotation.y
	assert_true(healthy, "O corpo é SEMPRE o mesmo e tudo é finito.")
	assert_true(wheels, "As rodas por roda seguem ligadas também no caminho de hoje.")
	assert_eq(natural, [true, false, false], "O 1º trecho é natural; a volta e o trecho seguinte usam o caminho de hoje (`road_of` nulo).")
	for joint: Vector2 in joints:
		assert_lt(joint.x, JOINT_GAP_M, "A troca de trecho não salta de posição (m).")
		assert_lt(joint.y, JOINT_TURN_DEG, "E não estala o giro no quadro da troca (graus; sem o limite eram uns 165).")
	assert_lte(worst_excess, 0.0, "Nenhum quadro gira mais que o limite de hoje (0,5 rad por metro andado; excesso em rad).")
	assert_almost_eq(absf(angle_difference(end_yaw, NaturalCurvesRig.yaw_of(MARKETS[A] - MARKETS[B]))), 0.0, 0.001, "No fim da volta o corpo olha para onde a estrada nova vai.")
	_rig.view.set_natural_curves(false)
	_rig.view.set_natural_curves(true)
	_rig.go(A, C, 0.05)
	assert_not_null(_rig.view.road_of(TRADER), "Trocar o modo desfaz o caminho de hoje: o trecho seguinte volta a ser natural.")
