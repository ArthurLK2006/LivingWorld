extends GutTest
## LW-099f (curvas naturais, EXPERIMENTAL): a `CaravanBodiesView` com o modo `set_natural_curves` sobre as três estradas reais (ponte roteirizada, terreno e mercados reais). Os cantos de duas pernas estão em `test_caravan_bodies_view_natural_corners.gd`. Lê as TRANSFORMAÇÕES dos corpos (o que se vê) e confere com contas de
## referência escritas à parte (`NaturalCurvesRig`): a faixa em smoothstep, o apoio de trás sobre a faixa, a pose como função pura de `u`, a viagem sem memória, a inclinação pelo eixo real, o liga e desliga, o raio e a rampa limitada ao meio do trecho.

const A: String = NaturalCurvesRig.A
const B: String = NaturalCurvesRig.B
const C: String = NaturalCurvesRig.C
const TRADER: int = NaturalCurvesRig.TRADER
const OTHER: int = NaturalCurvesRig.OTHER
const MARKETS: Dictionary[String, Vector2] = NaturalCurvesRig.MARKETS
const LANE_M: float = NaturalCurvesRig.LANE_M
const PAIRS: Array = [[A, B], [B, A], [A, C], [C, A], [B, C], [C, B]]
const POSE_TOLERANCE_M: float = 0.01
const LANE_TOLERANCE_M: float = 0.001
const AXLE_TOLERANCE_M: float = 0.0001
const YAW_TOLERANCE: float = 0.001
const ANGLE_TOLERANCE: float = 0.0001
const GENTLE_SLOPE: float = 0.15
const SHORT_ROAD_M: float = 20.0

var _rig: NaturalCurvesRig


func before_all() -> void:
	_rig = NaturalCurvesRig.load_world()
	assert_eq(_rig.failure, "", "O mundo de teste e o dado de apresentação carregaram.")


func _start(natural: bool = true) -> void:
	assert_true(_rig.start(self, natural), "A vista foi ligada à ponte e ao terreno.")


## O que se vê do corpo: posição e giros (a transformação que a `CaravanView` recebeu).
func _pose_of(body: CaravanView) -> Array:
	return [body.position, body.rotation]


## A viagem A para C para B até o começo do 2º trecho: a caravana chega ao fim do 1º (`u` = 1) e sai do povoado de passagem na fração `u` do 2º.
func _cross(x: String, y: String, z: String, u: float) -> CaravanView:
	_rig.go(x, y, 0.5)
	_rig.go(x, y, 1.0)
	return _rig.go(y, z, u)


## Os pontos (metros desde a saída) onde a reta é medida: de 0,25 em 0,25 m nas duas rampas e de 5 em 5 m no resto.
func _walk_points(length_m: float) -> Array[float]:
	var points: Array[float] = []
	var s: float = 0.0
	while s < 30.0:
		points.append(s)
		s += 0.25
	while s < length_m - 30.0:
		points.append(s)
		s += 5.0
	s = length_m - 30.0
	while s < length_m:
		points.append(s)
		s += 0.25
	points.append(length_m)
	return points


func test_the_mode_is_born_off_and_off_the_pose_is_the_one_of_today_whatever_the_radius() -> void:
	var fresh: CaravanBodiesView = CaravanBodiesView.new()
	add_child_autofree(fresh)
	assert_false(fresh.natural_curves(), "O modo nasce DESLIGADO.")
	assert_eq(fresh.curve_radius_m(), 6.0, "O raio do caminho nasce em 6 m (a referência de Arthur).")
	assert_null(fresh.road_of(TRADER), "Sem caravana, sem estrada.")
	_start(false)
	_rig.view.set_curve_radius_m(8.0)
	var path: CaravanPath = CaravanPath.through(MARKETS[A], PackedVector2Array(), MARKETS[B])
	var pose: CaravanPath.Pose = CaravanPath.Pose.new()
	for u: float in [0.0, 0.01, 0.2, 0.5, 0.99, 1.0]:
		var body: CaravanView = _rig.go(A, B, u)
		path.sample_into(u, true, LANE_M, pose, CaravanBodiesView.LATERAL_RAMP_M)
		assert_lt(NaturalCurvesRig.spot_of(body).distance_to(pose.position), POSE_TOLERANCE_M, "Desligado, a posição em u=%.2f é a do CaravanPath." % u)
		assert_almost_eq(body.rotation.y, pose.yaw, ANGLE_TOLERANCE, "Desligado, o giro em u=%.2f é o do CaravanPath." % u)
		assert_false(body.wheel_differential(), "Desligado, as rodas giram juntas, como sempre.")
	assert_null(_rig.view.road_of(TRADER), "Desligado nenhuma estrada com arcos é montada (mesmo com outro raio).")


func test_the_lane_of_the_three_real_roads_rises_in_smoothstep_and_the_rear_support_stays_on_it() -> void:
	for pair: Array in PAIRS:
		_start()
		var from: Vector2 = MARKETS[pair[0]]
		var to: Vector2 = MARKETS[pair[1]]
		var length_m: float = from.distance_to(to)
		var right: Vector2 = Vector2(-(to - from).normalized().y, (to - from).normalized().x)
		var lane_err: float = 0.0
		var axle_err: float = 0.0
		var yaw_err: float = 0.0
		for s: float in _walk_points(length_m):
			var body: CaravanView = _rig.go(pair[0], pair[1], s / length_m)
			var spot: Vector2 = NaturalCurvesRig.spot_of(body)
			var reference: Vector2 = NaturalCurvesRig.lane_point(from, to, s)
			lane_err = maxf(lane_err, spot.distance_to(reference))
			var rear: Vector2 = spot + Vector2(sin(body.rotation.y), cos(body.rotation.y)) * CaravanView.CART_BACK_M
			axle_err = maxf(axle_err, NaturalCurvesRig.lane_error_m(from, to, rear))
			var chord: Vector2 = (reference - NaturalCurvesRig.rear_point(from, to, s)).normalized()
			yaw_err = maxf(yaw_err, absf(angle_difference(body.rotation.y, NaturalCurvesRig.yaw_of(chord))))
		var label: String = "%s para %s" % [pair[0], pair[1]]
		assert_lt(lane_err, LANE_TOLERANCE_M, "%s: o pé do comerciante anda na faixa de referência (m)." % label)
		assert_lt(axle_err, AXLE_TOLERANCE_M, "%s: o apoio de trás do carrinho fica SOBRE a faixa em todo quadro (m)." % label)
		assert_lt(yaw_err, YAW_TOLERANCE, "%s: o giro é o da corda entre os pés e o eixo (rad)." % label)
		for probe: Array in [[0.0, 0.0], [6.0, 0.6], [12.0, LANE_M], [length_m * 0.5, LANE_M], [length_m - 6.0, 0.6], [length_m, 0.0]]:
			var body: CaravanView = _rig.go(pair[0], pair[1], float(probe[0]) / length_m)
			assert_almost_eq((NaturalCurvesRig.spot_of(body) - from).dot(right), float(probe[1]), LANE_TOLERANCE_M, "%s: a %.1f m da saída a faixa está a %.2f m do eixo." % [label, probe[0], probe[1]])
		assert_lt(NaturalCurvesRig.spot_of(_rig.go(pair[0], pair[1], 0.0)).distance_to(from), POSE_TOLERANCE_M, "%s: na saída o corpo está no mercado." % label)
		assert_lt(NaturalCurvesRig.spot_of(_rig.go(pair[0], pair[1], 1.0)).distance_to(to), POSE_TOLERANCE_M, "%s: na chegada o corpo está no mercado." % label)
		assert_eq(_rig.view.active_ids(), [TRADER] as Array[int], "%s: um corpo só." % label)
		assert_eq(_rig.view.road_of(TRADER).corners().size(), 0, "%s: sem pontos de passagem a estrada é reta." % label)


func test_the_pose_at_a_fraction_does_not_depend_on_the_frames_that_led_to_it() -> void:
	for target: float in [0.01, 0.2, 0.55, 0.999]:
		_start()
		var direct: Array = _pose_of(_rig.go(A, C, target))
		_start()
		var fine: CaravanView = null
		for step: int in 201:
			fine = _rig.go(A, C, target * float(step) / 200.0)
		assert_eq(_pose_of(fine), direct, "Quadros finos até u=%.3f dão a pose de ir direto a ela." % target)
		_start()
		var wandering: CaravanView = null
		for u: float in [0.9, 0.1, target, 0.3, 0.77, target]:
			wandering = _rig.go(A, C, u)
		assert_eq(_pose_of(wandering), direct, "Indo e voltando até u=%.3f a pose é a mesma." % target)
	_start()
	_cross(A, C, B, 0.0)
	var cornered: Array = _pose_of(_rig.go(C, B, 0.012))
	_start()
	var steps: CaravanView = _cross(A, C, B, 0.0)
	for step: int in 61:
		steps = _rig.go(C, B, 0.012 * float(step) / 60.0)
	assert_eq(_pose_of(steps), cornered, "Depois da quina, passo a passo ou de uma vez, a pose em u=0,012 é a mesma.")
	var settled: CaravanView = _rig.go(C, B, 0.4)
	var before: Array = _pose_of(settled)
	for _repeat: int in 3:
		_rig.view.reconcile()
	assert_eq(_pose_of(settled), before, "Consultar de novo sem mudança não muda nada.")
	_rig.go(C, B, 0.4, TRADER, BridgeReplies.CaravanBodyReply.STATE_HELD)
	assert_eq(_pose_of(settled), before, "Parada (held) ou em pausa, a mesma `u` dá a mesma pose.")


func test_without_memory_the_road_is_straight_finite_and_each_caravan_has_its_own_memory() -> void:
	_start()
	_rig.go(A, C, 0.5)
	_rig.go(A, C, 1.0)
	var route: String = NaturalCurvesRig.route_of(C, B)
	_rig.show([ScriptedCaravanBridge.row_of(TRADER, 0.0, route, C, B), ScriptedCaravanBridge.row_of(OTHER, 0.0, route, C, B)], MARKETS[C])
	assert_eq(_rig.view.road_of(TRADER).corners().size(), 1, "Quem chegou em C pelo trecho de A tem o arco da quina.")
	assert_eq(_rig.view.road_of(OTHER).corners().size(), 0, "Quem foi vista pela 1ª vez no meio da viagem não tem memória: reta, sem exceção.")
	var turned: float = rad_to_deg(absf(angle_difference(_rig.view.body_of(TRADER).rotation.y, _rig.view.body_of(OTHER).rotation.y)))
	assert_gt(turned, 30.0, "As duas memórias são independentes: a que chegou ainda olha para onde vinha (%.1f graus de diferença)." % turned)
	var from: Vector2 = MARKETS[C]
	var to: Vector2 = MARKETS[B]
	for s: float in [0.0, 3.0, 40.0, 200.0, from.distance_to(to)]:
		var body: CaravanView = _rig.go(C, B, s / from.distance_to(to), OTHER)
		assert_true(_pose_of(body)[0].is_finite() and is_finite(body.rotation.y), "Sem memória, finito em s=%.0f." % s)
		assert_lt(NaturalCurvesRig.spot_of(body).distance_to(NaturalCurvesRig.lane_point(from, to, s)), LANE_TOLERANCE_M, "Sem memória, o corpo está na faixa da reta de C a B em s=%.0f." % s)
	for share: Array in [[0.8999, 0], [0.9, 1], [1.0, 1]]:
		_start()
		_rig.go(A, C, 0.2)
		_rig.go(A, C, float(share[0]))
		_rig.go(C, B, 0.0)
		assert_eq(_rig.view.road_of(TRADER).corners().size(), int(share[1]), "Se o trecho mudou com a última u vista em %.4f, a memória %s." % [share[0], "vale" if share[1] == 1 else "não vale (reta)"])
	_start()
	_rig.go(A, B, 0.5)
	var odd: Array[float] = [-0.5, 1.7, NAN, INF]
	var expected: Array = [_pose_of(_rig.go(A, B, 0.0)), _pose_of(_rig.go(A, B, 1.0)), _pose_of(_rig.go(A, B, 0.0)), _pose_of(_rig.go(A, B, 1.0))]
	for index: int in odd.size():
		assert_eq(_pose_of(_rig.go(A, B, odd[index])), expected[index], "u=%s é cortado como no CaravanPath (NaN conta como 0): nada de NaN nem exceção." % odd[index])


func test_the_pitch_uses_the_height_under_the_real_axle_on_a_slope() -> void:
	var worst: float = 0.0
	var steepest: float = 0.0
	for pair: Array in [[A, B], [B, A], [A, C]]:
		_start()
		_rig.bridge.slope_x = GENTLE_SLOPE
		for u: float in [0.003, 0.01, 0.2, 0.5, 0.997]:
			var found: Vector2 = _pitch_error(_rig.go(pair[0], pair[1], u))
			worst = maxf(worst, found.x)
			steepest = maxf(steepest, found.y)
	for u: float in [0.0, 0.005, 0.01, 0.02, 0.05, 0.3]:
		_start()
		_rig.bridge.slope_x = GENTLE_SLOPE
		_cross(A, C, B, 0.0)
		var found: Vector2 = _pitch_error(_rig.go(C, B, u))
		worst = maxf(worst, found.x)
		steepest = maxf(steepest, found.y)
	assert_lt(worst, ANGLE_TOLERANCE, "A inclinação é a que liga a altura dos pés à do terreno sob o EIXO real, na reta, nas rampas da faixa e na curva (rad).")
	assert_gt(steepest, 0.05, "Premissa: o declive do teste inclina o corpo de verdade (%.3f rad)." % steepest)
	var posed: CaravanView = _rig.go(C, B, 0.4)
	var kept: Array = _pose_of(posed)
	_rig.bridge.is_blind = true
	_rig.bridge.rows.assign([ScriptedCaravanBridge.row_of(TRADER, 0.41, NaturalCurvesRig.route_of(C, B), C, B)])
	_rig.view.reconcile()
	assert_eq(_pose_of(posed), kept, "Sem altura legível a pose não muda (a última fica), sem exceção.")
	assert_gt(_rig.view.ground_misses, 0, "E a falta é contada em `ground_misses`.")


## (o erro da inclinação do corpo, a inclinação esperada em módulo): a esperada liga a altura dos pés à do terreno sob o EIXO real (o ponto `CART_BACK_M` atrás dos pés ao longo do giro do corpo), limitada a `max_pitch_deg`.
func _pitch_error(body: CaravanView) -> Vector2:
	var feet: Vector2 = NaturalCurvesRig.spot_of(body)
	var axle: Vector2 = feet + Vector2(sin(body.rotation.y), cos(body.rotation.y)) * CaravanView.CART_BACK_M
	var limit: float = deg_to_rad(_rig.routes.max_pitch_deg)
	var expected: float = clampf(atan2(_ground(feet) - _ground(axle), CaravanView.CART_BACK_M), -limit, limit)
	return Vector2(absf(body.rotation.x - expected), absf(expected))


func _ground(point: Vector2) -> float:
	return _rig.bridge.peek_height(point.x, point.y).height_m


func test_switching_the_mode_in_the_middle_of_a_trip_rebuilds_the_roads_and_leaks_nothing() -> void:
	_start()
	var body: CaravanView = _rig.go(A, C, 0.5)
	assert_not_null(_rig.view.road_of(TRADER), "Ligado, a caravana tem a estrada com arcos.")
	assert_true(body.wheel_differential(), "Ligado, cada roda gira pelo próprio centro.")
	var created: int = _rig.view.pool().created
	var children: int = _rig.view.get_child_count()
	_rig.view.set_natural_curves(false)
	assert_null(_rig.view.road_of(TRADER), "Desligar descarta a estrada.")
	assert_false(body.wheel_differential(), "Desligar devolve as rodas ao modo de sempre.")
	var path: CaravanPath = CaravanPath.through(MARKETS[A], PackedVector2Array(), MARKETS[C])
	var pose: CaravanPath.Pose = CaravanPath.Pose.new()
	path.sample_into(0.5, true, LANE_M, pose, CaravanBodiesView.LATERAL_RAMP_M)
	assert_eq(_rig.go(A, C, 0.5), body, "O mesmo corpo continua a viagem.")
	assert_lt(NaturalCurvesRig.spot_of(body).distance_to(pose.position), POSE_TOLERANCE_M, "Desligado outra vez, a posição volta a ser a de hoje...")
	assert_almost_eq(body.rotation.y, pose.yaw, ANGLE_TOLERANCE, "...e o giro também.")
	_rig.view.set_natural_curves(true)
	assert_null(_rig.view.road_of(TRADER), "Ligar descarta o que havia: a estrada é refeita no próximo `reconcile`.")
	assert_eq(_rig.go(A, C, 0.5), body, "O mesmo corpo, sem exceção.")
	assert_not_null(_rig.view.road_of(TRADER), "Refeita.")
	assert_true(body.wheel_differential(), "As rodas voltam a girar por roda.")
	assert_eq([_rig.view.pool().created, _rig.view.get_child_count(), _rig.view.active_ids()], [created, children, [TRADER] as Array[int]], "Nada vaza: nenhum corpo novo, a reserva e os filhos iguais.")


func test_the_curve_radius_clamps_adds_the_lane_for_the_axis_and_changing_it_keeps_the_arrival() -> void:
	_start()
	var view: CaravanBodiesView = _rig.view
	assert_eq(view.curve_radius_m(), CaravanBodiesView.CURVE_PATH_RADIUS_M, "O raio nasce na referência.")
	for bad: float in [-1.0, NAN, INF, -INF]:
		view.set_curve_radius_m(4.1)
		view.set_curve_radius_m(bad)
		assert_eq(view.curve_radius_m(), 0.0, "Raio %s vira 0 (quinas vivas)." % bad)
	for radius: float in [4.1, 6.0, 8.0, 10.0]:
		view.set_curve_radius_m(radius)
		assert_eq(view.curve_radius_m(), radius, "O raio %.1f fica." % radius)
		_cross(A, C, B, 0.0)
		var corner: CaravanRoad.Corner = view.road_of(TRADER).corners()[0]
		assert_almost_eq(corner.radius_req_m, radius + LANE_M, 1e-6, "O eixo pede o raio do caminho (%.1f) mais a faixa." % radius)
		assert_true(corner.fits, "O arco cabe nos trechos reais.")
	_rig.go(C, B, 0.3)
	view.set_curve_radius_m(8.0)
	assert_null(view.road_of(TRADER), "Trocar o raio descarta a estrada montada.")
	_rig.go(C, B, 0.3)
	assert_almost_eq(view.road_of(TRADER).corners()[0].radius_req_m, 8.0 + LANE_M, 1e-6, "Refeita com o raio novo e com a direção de chegada lembrada (a quina segue arredondada).")
	view.set_curve_radius_m(0.0)
	var live: CaravanView = _cross(A, C, B, 0.0)
	assert_eq(view.road_of(TRADER).corners().size(), 0, "Raio 0: quinas vivas, sem arco.")
	assert_true(_pose_of(live)[0].is_finite() and is_finite(live.rotation.y), "Sem arco tudo segue finito.")
	assert_lt(NaturalCurvesRig.spot_of(live).distance_to(MARKETS[C]), POSE_TOLERANCE_M, "O corpo parte do mercado.")
	assert_lt(rad_to_deg(absf(angle_difference(live.rotation.y, NaturalCurvesRig.yaw_of(MARKETS[B] - MARKETS[C])))), 5.0, "O corpo de 2 apoios gira pela corda: olha para a estrada nova (a quina é viva).")


func test_the_lane_ramp_is_limited_to_half_of_a_short_road_and_an_empty_road_has_no_body() -> void:
	var a_spot: Vector3 = Vector3(MARKETS[A].x, NaturalCurvesRig.GROUND_M, MARKETS[A].y)
	var short_places: Array[Place] = [Place.new("short_a", A, Place.KIND_MARKET, a_spot, 1), Place.new("short_b", B, Place.KIND_MARKET, a_spot + Vector3(SHORT_ROAD_M, 0.0, 0.0), 1)]
	assert_true(_rig.start(self, true, short_places))
	var focus_m: Vector2 = MARKETS[A] + Vector2(SHORT_ROAD_M * 0.5, 0.0)
	_rig.show([ScriptedCaravanBridge.row_of(TRADER, 0.5, "route_a_b", A, B)], focus_m)
	assert_almost_eq(_rig.view.body_of(TRADER).position.z - MARKETS[A].y, LANE_M, LANE_TOLERANCE_M, "Numa estrada de 20 m (menos de 2 rampas) a rampa vai só até o meio e a faixa chega cheia, sem crista (com 12 m a faixa pararia em 1,11 m).")
	_rig.show([ScriptedCaravanBridge.row_of(TRADER, 0.45, "route_a_b", A, B)], focus_m)
	assert_almost_eq(_rig.view.body_of(TRADER).position.z - MARKETS[A].y, LANE_M * smoothstep(0.0, SHORT_ROAD_M * 0.5, SHORT_ROAD_M * 0.45), LANE_TOLERANCE_M, "E a subida é o smoothstep da rampa limitada.")
	var empty_places: Array[Place] = [Place.new("same_a", A, Place.KIND_MARKET, a_spot, 1), Place.new("same_b", B, Place.KIND_MARKET, a_spot, 1)]
	assert_true(_rig.start(self, true, empty_places))
	_rig.show([ScriptedCaravanBridge.row_of(TRADER, 0.5, "route_a_b", A, B)], MARKETS[A])
	assert_null(_rig.view.body_of(TRADER), "Estrada vazia (comprimento 0): sem corpo.")
	assert_eq(_rig.view.unplaced, 1, "Contada como `unplaced`, como a estrada sem mercado.")
