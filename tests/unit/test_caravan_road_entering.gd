extends GutTest
## LW-099f: o trecho que SAI de um povoado de passagem (`CaravanRoad.entering`), sem janela, nó, ponte nem relógio. Passa por `start` em s = 0 com a tangente de chegada,
## termina em `end`, o vértice da quina fica a R tan(θ/2) (o ponto fixo converge: o teste compara com a forma fechada), os cantos reais (89, 129 e 142 graus), o trecho de
## saída curto (o raio encolhe), a volta de 180 graus (sem NaN, sem laço infinito) e a reta de chegada antes de 0. `through` está em `test_caravan_road.gd`.
## O `Vector2` do Godot é float32: as contas de precisão ficam perto da origem; longe dela as tolerâncias de posição sobem para 1e-3 m.

const EPS: float = 0.0001
const RADIUS_M: float = 10.0
const LEG_OUT_M: float = 150.0
const LANE_M: float = 1.2
const RAMP_M: float = 12.0
## O trecho reto depois do mercado: o apoio da frente do cavalo anda a +1,2 m da origem do líder.
const RUN_M: float = 1.2
## Os três cantos reais da viagem de 2 trechos (~89, ~129 e ~142 graus), para a direita ou a esquerda.
const REAL_CORNERS: Array = [[89.3, true], [129.1, true], [141.6, false]]
## [virada em graus, para a direita?]: o ângulo na quina entre a chegada e a saída (os três cantos reais da viagem de 2 trechos são ~89, ~129 e ~142 graus).
const CORNERS: Array = [[55.0, true], [90.0, true], [90.0, false], [129.1, true], [141.6, false]]


func _near(got: Vector2, expected: Vector2, why: String, tolerance: float = EPS) -> void:
	assert_true(got.distance_to(expected) <= tolerance, "%s: veio %s, esperado %s" % [why, got, expected])


## O `end` que dá a virada `turn_deg` NO VÉRTICE: o vértice fica a R tan(θ/2) de `start` ao longo da chegada e `end` a `LEG_OUT_M` dele.
func _end_for(start: Vector2, dir_in: Vector2, turn_deg: float, right: bool) -> Vector2:
	var vertex: Vector2 = start + dir_in * (RADIUS_M * tan(deg_to_rad(turn_deg) * 0.5))
	return vertex + dir_in.rotated((1.0 if right else -1.0) * deg_to_rad(turn_deg)) * LEG_OUT_M


## A tangente R tan(θ/2) que resolve o vértice, em forma fechada: a quadrática (b - 2R) T² + 2 R a T - R² b = 0, com a e b o `end` visto de `start` ao longo e através da chegada.
func _closed_form_tangent(start: Vector2, dir_in: Vector2, end: Vector2) -> float:
	var rel: Vector2 = end - start
	var a: float = dir_in.x * rel.x + dir_in.y * rel.y
	var b: float = absf(dir_in.x * rel.y - dir_in.y * rel.x)
	return RADIUS_M * (-a + sqrt(a * a + b * b - 2.0 * RADIUS_M * b)) / (b - 2.0 * RADIUS_M)


func test_entering_starts_at_start_along_the_arrival_and_ends_at_the_target_for_the_real_corners() -> void:
	for dir_in: Vector2 in [Vector2.RIGHT, Vector2.from_angle(deg_to_rad(37.0))]:
		for spec: Array in CORNERS:
			var start: Vector2 = Vector2.ZERO
			var end: Vector2 = _end_for(start, dir_in, float(spec[0]), bool(spec[1]))
			var road: CaravanRoad = CaravanRoad.entering(dir_in, start, end, RADIUS_M)
			var why: String = "virada %s, direita %s, chegada %s" % [spec[0], spec[1], dir_in]
			var corner: CaravanRoad.Corner = road.corners()[0]
			_near(road.axis_point(0.0), start, "s = 0 é o mercado (%s)" % why, 1e-5)
			_near(road.axis_tangent(0.0), dir_in.normalized(), "com a tangente de chegada (%s)" % why, 1e-6)
			_near(road.axis_point(road.length_m()), end, "e termina em end (%s)" % why)
			_near(road.end_tangent(), (end - dir_in * corner.tangent_m).normalized(), "na direção da reta de saída (%s)" % why, 1e-5)
			assert_almost_eq(rad_to_deg(corner.turn_rad), float(spec[0]), 1e-3, "a virada pedida (%s)" % why)
			assert_eq(corner.side, 1 if bool(spec[1]) else -1, "o lado (%s)" % why)
			assert_true(corner.fits, "cabe (%s)" % why)
			assert_almost_eq(corner.radius_eff_m, RADIUS_M, 1e-6, "o raio efetivo é o pedido, com o erro da iteração abaixo de 1e-6 m (%s)" % why)
			assert_almost_eq(corner.tangent_m, RADIUS_M * tan(corner.turn_rad * 0.5), 1e-6, "vértice a R tan(θ/2) de start (%s)" % why)
			assert_almost_eq(corner.tangent_m, _closed_form_tangent(start, dir_in.normalized(), end), 1e-6, "e igual à forma fechada (%s)" % why)
			var departure: Vector2 = (road.axis_point(road.length_m()) - road.axis_point(road.length_m() - 100.0)).normalized()
			var center: Vector2 = start + Vector2(-dir_in.normalized().y, dir_in.normalized().x) * (float(corner.side) * RADIUS_M)
			assert_almost_eq(absf(departure.cross(center - end)), RADIUS_M, 1e-3, "a reta de saída toca o círculo de raio R que sai de start (%s)" % why)
			var expected_length: float = corner.arc_m + (end - dir_in.normalized() * corner.tangent_m).length() - corner.tangent_m
			assert_almost_eq(road.length_m(), expected_length, EPS, "comprimento = arco + saída - tangente (%s)" % why)


func test_entering_is_continuous_in_position_and_tangent_and_extends_the_arrival_line_before_zero() -> void:
	var dir_in: Vector2 = Vector2.from_angle(deg_to_rad(37.0))
	var road: CaravanRoad = CaravanRoad.entering(dir_in, Vector2.ZERO, _end_for(Vector2.ZERO, dir_in, 129.1, true), RADIUS_M)
	var previous_point: Vector2 = road.axis_point(-3.0)
	var previous_dir: Vector2 = road.axis_tangent(-3.0)
	var worst_step: float = 0.0
	var worst_turn: float = 0.0
	var total_turn: float = 0.0
	for index: int in range(1, 3001):
		var s: float = -3.0 + float(index) * 0.01
		var dir: Vector2 = road.axis_tangent(s)
		worst_step = maxf(worst_step, road.axis_point(s).distance_to(previous_point))
		worst_turn = maxf(worst_turn, absf(previous_dir.angle_to(dir)))
		total_turn += absf(previous_dir.angle_to(dir))
		previous_point = road.axis_point(s)
		previous_dir = dir
	assert_lt(worst_step, 0.01 + EPS, "de 1 cm em 1 cm o ponto nunca anda mais que 1 cm")
	assert_lt(worst_turn, 0.01 / RADIUS_M + 1e-5, "e a tangente gira no máximo 1 cm / R por passo: sem salto em s = 0 nem no fim do arco")
	assert_almost_eq(total_turn, deg_to_rad(129.1), 2e-3, "a janela de -3 a 27 m inclui o arco inteiro: gira os 129,1 graus")
	for s: float in [-0.5, -7.0, -40.0]:
		_near(road.axis_point(s), dir_in.normalized() * s, "antes de 0 a estrada é a reta de chegada (s = %s)" % s, 1e-4)
		_near(road.axis_tangent(s), dir_in.normalized(), "com a tangente de chegada (s = %s)" % s, 1e-6)
	var far_start: Vector2 = Vector2(300, 200)
	var far: CaravanRoad = CaravanRoad.entering(Vector2.RIGHT, far_start, _end_for(far_start, Vector2.RIGHT, 90.0, true), RADIUS_M)
	_near(far.axis_point(0.0), far_start, "longe da origem também passa por start (resolução float32 de 3e-5 m)", 1e-3)
	_near(far.axis_tangent(0.0), Vector2.RIGHT, "com a tangente de chegada", 1e-6)
	_near(far.axis_point(far.length_m()), _end_for(far_start, Vector2.RIGHT, 90.0, true), "e termina em end", 1e-3)
	assert_almost_eq(far.corners()[0].radius_eff_m, RADIUS_M, 1e-6, "o raio efetivo não depende de onde a estrada está")


func test_a_short_exit_leg_shrinks_the_radius_and_the_road_still_passes_through_start() -> void:
	var road: CaravanRoad = CaravanRoad.entering(Vector2.RIGHT, Vector2.ZERO, Vector2(6, 12), RADIUS_M)
	var corner: CaravanRoad.Corner = road.corners()[0]
	assert_almost_eq(corner.tangent_m, 6.0, 1e-6, "a tangente é a metade do trecho de saída (12 m)")
	assert_almost_eq(corner.radius_eff_m, 6.0, 1e-6, "então o raio efetivo é 6 m")
	assert_almost_eq(rad_to_deg(corner.turn_rad), 90.0, 1e-4, "virada de 90 graus no vértice (6, 0)")
	assert_false(corner.fits, "não cabe o raio pedido")
	_near(road.axis_point(0.0), Vector2.ZERO, "passa por start em s = 0")
	_near(road.axis_tangent(0.0), Vector2.RIGHT, "com a tangente de chegada", 1e-6)
	_near(road.axis_point(road.length_m()), Vector2(6, 12), "e termina em end")
	assert_almost_eq(road.length_m(), 6.0 * PI * 0.5 + 6.0, 1e-5, "arco de R 6 e mais 6 m de reta")


func test_entering_without_a_turn_or_with_a_half_turn_gives_finite_values_and_still_passes_through_start() -> void:
	var ahead: CaravanRoad = CaravanRoad.entering(Vector2.RIGHT, Vector2.ZERO, Vector2(200, 0), RADIUS_M)
	assert_almost_eq(ahead.length_m(), 200.0, EPS, "em frente: a reta")
	assert_eq(ahead.corners().size(), 0, "sem quina")
	var barely: CaravanRoad = CaravanRoad.entering(Vector2.RIGHT, Vector2.ZERO, Vector2(200, 0.01), RADIUS_M)
	assert_eq(barely.corners().size(), 0, "virada de 5e-5 rad (tangente de 0,25 mm, abaixo de 1 mm): sem arco")
	assert_lt(absf(barely.axis_tangent(0.0).angle_to(Vector2.RIGHT)), 1e-4, "a tangente de saída difere da chegada menos que a própria virada")
	for turn_deg: float in [175.0, 178.0, 179.9, 180.0]:
		for radius: float in [RADIUS_M, 100.0]:
			var start: Vector2 = Vector2(2, 3)
			var end: Vector2 = start + Vector2.from_angle(deg_to_rad(turn_deg)) * 100.0
			var road: CaravanRoad = CaravanRoad.entering(Vector2.RIGHT, start, end, radius)
			var why: String = "volta de %s graus, raio %s" % [turn_deg, radius]
			_near(road.axis_point(0.0), start, "passa por start (%s)" % why, 1e-5)
			_near(road.axis_tangent(0.0), Vector2.RIGHT, "com a tangente de chegada (%s)" % why, 1e-6)
			_near(road.axis_point(road.length_m()), end, "e termina em end (%s)" % why, 1e-3)
			assert_true(is_finite(road.length_m()) and road.length_m() >= start.distance_to(end) - 1e-3, "comprimento finito e não menor que a corda (%s)" % why)
			assert_false(road.corners()[0].fits, "não cabe (%s)" % why)
			assert_true(is_finite(road.corners()[0].tangent_m) and road.corners()[0].tangent_m <= 100.001, "tangente finita, no máximo a distância (%s)" % why)
			for step: int in 60:
				var s: float = -5.0 + float(step) * (road.length_m() + 10.0) / 59.0
				for value: Vector2 in [road.axis_point(s), road.sample(s), road.axis_tangent(s), road.tangent(s)]:
					assert_true(value.is_finite(), "valor finito em s = %s (%s)" % [s, why])
	var turned_back: CaravanRoad.Corner = CaravanRoad.entering(Vector2.RIGHT, Vector2.ZERO, Vector2(-100, 0), RADIUS_M).corners()[0]
	assert_almost_eq(turned_back.tangent_m, 100.0, 1e-6, "volta exata de 180 graus: a tangente se fecha em metade do trecho de saída (a distância)")


func test_entering_falls_back_to_the_plain_road_when_there_is_no_arrival_or_no_radius() -> void:
	var start: Vector2 = Vector2(0, 0)
	var end: Vector2 = Vector2(60, 80)
	var plain: CaravanRoad = CaravanRoad.through(PackedVector2Array([start, end]), RADIUS_M)
	for bad_dir: Vector2 in [Vector2.ZERO, Vector2(NAN, 0), Vector2(INF, 1)]:
		var road: CaravanRoad = CaravanRoad.entering(bad_dir, start, end, RADIUS_M)
		assert_eq(road.length_m(), plain.length_m(), "chegada %s: a reta de start a end" % bad_dir)
		assert_eq(road.corners().size(), 0, "sem quina")
		assert_eq(road.axis_tangent(30.0), plain.axis_tangent(30.0), "e a mesma tangente")
	for radius: float in [0.0, -4.0, NAN]:
		assert_eq(CaravanRoad.entering(Vector2.RIGHT, start, end, radius).length_m(), 100.0, "raio %s: quinas vivas, a reta" % radius)
	assert_eq(CaravanRoad.entering(Vector2(3, 0), start, Vector2(200, 100), RADIUS_M).length_m(), CaravanRoad.entering(Vector2.RIGHT, start, Vector2(200, 100), RADIUS_M).length_m(), "a chegada não unitária é normalizada")
	assert_eq(CaravanRoad.entering(Vector2.RIGHT, start, Vector2(0, 0.0005), RADIUS_M).length_m(), 0.0, "start e end a 0,5 mm: estrada vazia")
	assert_eq(CaravanRoad.entering(Vector2.RIGHT, Vector2(NAN, 0), end, RADIUS_M).length_m(), 0.0, "start não finito: vazia")
	assert_eq(CaravanRoad.entering(Vector2.RIGHT, start, Vector2(INF, 0), RADIUS_M).length_m(), 0.0, "end não finito: vazia")
	assert_eq(CaravanRoad.entering(Vector2.RIGHT, start, end, 0.0, RUN_M).length_m(), 100.0, "raio 0 com trecho reto: nada a atrasar, a reta de start a end")
	assert_eq(CaravanRoad.entering(Vector2.ZERO, start, end, RADIUS_M, RUN_M).corners().size(), 0, "chegada nula com trecho reto: a reta de start a end")


## O `end` que dá a virada `turn_deg` no vértice quando o arco só começa depois de `RUN_M` metros de reta: o vértice fica a RUN_M + R tan(θ/2) de `start`.
func _end_with_run(dir_in: Vector2, turn_deg: float, right: bool) -> Vector2:
	var vertex: Vector2 = dir_in.normalized() * (RUN_M + RADIUS_M * tan(deg_to_rad(turn_deg) * 0.5))
	return vertex + dir_in.rotated((1.0 if right else -1.0) * deg_to_rad(turn_deg)) * LEG_OUT_M


## De 1 cm em 1 cm: [o maior passo do ponto, a maior virada da tangente por passo, a virada total].
func _sweep(road: CaravanRoad, from_s: float, to_s: float) -> Array[float]:
	var previous_point: Vector2 = road.axis_point(from_s)
	var previous_dir: Vector2 = road.axis_tangent(from_s)
	var worst_step: float = 0.0
	var worst_turn: float = 0.0
	var total_turn: float = 0.0
	for index: int in range(1, int((to_s - from_s) / 0.01) + 1):
		var s: float = from_s + float(index) * 0.01
		var point: Vector2 = road.axis_point(s)
		var dir: Vector2 = road.axis_tangent(s)
		var turn: float = absf(previous_dir.angle_to(dir))
		worst_step = maxf(worst_step, point.distance_to(previous_point))
		worst_turn = maxf(worst_turn, turn)
		total_turn += turn
		previous_point = point
		previous_dir = dir
	return [worst_step, worst_turn, total_turn]


func test_a_zero_or_invalid_straight_run_is_exactly_the_road_without_the_parameter() -> void:
	var dir_in: Vector2 = Vector2.from_angle(deg_to_rad(37.0))
	for spec: Array in CORNERS:
		var end: Vector2 = _end_for(Vector2.ZERO, dir_in, float(spec[0]), bool(spec[1]))
		var base: CaravanRoad = CaravanRoad.entering(dir_in, Vector2.ZERO, end, RADIUS_M).with_lane(LANE_M, RAMP_M)
		var base_corner: CaravanRoad.Corner = base.corners()[0]
		for run: float in [0.0, -2.5, NAN, INF, -INF]:
			var other: CaravanRoad = CaravanRoad.entering(dir_in, Vector2.ZERO, end, RADIUS_M, run).with_lane(LANE_M, RAMP_M)
			var corner: CaravanRoad.Corner = other.corners()[0]
			var why: String = "virada %s, trecho reto %s" % [spec[0], run]
			assert_true(other.length_m() == base.length_m() and corner.tangent_m == base_corner.tangent_m and corner.apex_s == base_corner.apex_s and corner.radius_eff_m == base_corner.radius_eff_m, "comprimento e quina idênticos (%s)" % why)
			for step: int in 40:
				var s: float = -6.0 + float(step) * (base.length_m() + 12.0) / 39.0
				assert_true(other.sample(s) == base.sample(s) and other.axis_tangent(s) == base.axis_tangent(s) and other.tangent(s) == base.tangent(s), "mesmos bits em s = %s (%s)" % [s, why])


func test_a_straight_run_keeps_the_road_on_the_arrival_line_and_starts_the_arc_after_it() -> void:
	for dir_in: Vector2 in [Vector2.RIGHT, Vector2.from_angle(deg_to_rad(37.0))]:
		var unit: Vector2 = dir_in.normalized()
		for spec: Array in REAL_CORNERS:
			var end: Vector2 = _end_with_run(dir_in, float(spec[0]), bool(spec[1]))
			var road: CaravanRoad = CaravanRoad.entering(dir_in, Vector2.ZERO, end, RADIUS_M, RUN_M)
			var corner: CaravanRoad.Corner = road.corners()[0]
			var why: String = "virada %s, direita %s, chegada %s" % [spec[0], spec[1], dir_in]
			for step: int in 25:
				var s: float = -5.0 + float(step) * (RUN_M + 5.0) / 24.0
				_near(road.sample(s), unit * s, "de -5 a 1,2 m o ponto está na reta de chegada (s = %s, %s)" % [s, why], 1e-5)
				_near(road.axis_tangent(s), unit, "com a tangente de chegada (s = %s, %s)" % [s, why], 1e-6)
			_near(road.axis_point(RUN_M), unit * RUN_M, "o arco começa em s = 1,2 (%s)" % why, 1e-5)
			assert_almost_eq(corner.apex_s, RUN_M + 0.5 * corner.arc_m, EPS, "e o meio do arco vem logo depois dos 1,2 m de reta (%s)" % why)
			assert_almost_eq(absf(unit.angle_to(road.axis_tangent(RUN_M + 0.5))), 0.5 / RADIUS_M, 1e-3, "0,5 m depois a tangente já virou 0,5 / R (%s)" % why)
			assert_almost_eq(rad_to_deg(corner.turn_rad), float(spec[0]), 1e-3, "a virada pedida (%s)" % why)
			assert_true(corner.fits, "cabe (%s)" % why)
			assert_almost_eq(corner.radius_eff_m, RADIUS_M, 1e-6, "raio efetivo = pedido (%s)" % why)
			assert_almost_eq(corner.tangent_m, RADIUS_M * tan(corner.turn_rad * 0.5), 1e-6, "tangente R tan(θ/2) (%s)" % why)
			assert_almost_eq(corner.tangent_m, _closed_form_tangent(unit * RUN_M, unit, end), 1e-6, "e igual à forma fechada vista de onde o arco começa (%s)" % why)
			var vertex: Vector2 = unit * (RUN_M + corner.tangent_m)
			assert_almost_eq(road.length_m(), RUN_M + corner.arc_m + (end - vertex).length() - corner.tangent_m, EPS, "comprimento = reta + arco + saída - tangente (%s)" % why)
			_near(road.axis_point(road.length_m()), end, "e termina em end (%s)" % why)
			_near(road.end_tangent(), (end - vertex).normalized(), "na direção da reta de saída (%s)" % why, 1e-5)
			var sweep: Array[float] = _sweep(road, -2.0, RUN_M + corner.arc_m + 3.0)
			assert_lt(sweep[0], 0.01 + EPS, "de 1 cm em 1 cm o ponto nunca anda mais que 1 cm (%s)" % why)
			assert_lt(sweep[1], 0.01 / RADIUS_M + 1e-5, "e a tangente gira no máximo 1 cm / R por passo: sem salto em s = 1,2 (%s)" % why)
			assert_almost_eq(sweep[2], corner.turn_rad, 2e-3, "e a janela inteira gira só a virada da quina (%s)" % why)
	var ahead: CaravanRoad = CaravanRoad.entering(Vector2.RIGHT, Vector2.ZERO, Vector2(200, 0), RADIUS_M, RUN_M)
	assert_eq(ahead.corners().size(), 0, "em frente (0 graus): sem quina, a reta")
	assert_almost_eq(ahead.length_m(), 200.0, EPS, "de comprimento 200")
	_near(ahead.axis_point(RUN_M), Vector2(RUN_M, 0), "passando pelo ponto de 1,2 m")
	var turned_back: CaravanRoad = CaravanRoad.entering(Vector2.RIGHT, Vector2(2, 3), Vector2(2, 3) + Vector2.from_angle(deg_to_rad(175.0)) * 100.0, RADIUS_M, RUN_M)
	_near(turned_back.axis_point(0.0), Vector2(2, 3), "175 graus: passa por start", 1e-5)
	_near(turned_back.axis_point(RUN_M), Vector2(2 + RUN_M, 3), "segue reto 1,2 m", 1e-5)
	_near(turned_back.axis_tangent(0.6), Vector2.RIGHT, "com a tangente de chegada", 1e-6)
	_near(turned_back.axis_point(turned_back.length_m()), Vector2(2, 3) + Vector2.from_angle(deg_to_rad(175.0)) * 100.0, "termina em end", 1e-3)
	assert_false(turned_back.corners()[0].fits, "não cabe")
	for step: int in 60:
		var s: float = -5.0 + float(step) * (turned_back.length_m() + 10.0) / 59.0
		assert_true(turned_back.axis_point(s).is_finite() and turned_back.axis_tangent(s).is_finite(), "valores finitos em s = %s" % s)


func test_a_straight_run_removes_the_jump_at_the_handoff_for_a_body_ahead_of_the_leader() -> void:
	var leg_a: CaravanRoad = CaravanRoad.through(PackedVector2Array([Vector2(-60, 0), Vector2(0, 0)]), RADIUS_M).with_lane(LANE_M, RAMP_M)
	var end: Vector2 = _end_with_run(Vector2.RIGHT, 129.1, true)
	var with_run: CaravanRoad = CaravanRoad.entering(leg_a.end_tangent(), Vector2.ZERO, end, RADIUS_M, RUN_M).with_lane(LANE_M, RAMP_M)
	var without_run: CaravanRoad = CaravanRoad.entering(leg_a.end_tangent(), Vector2.ZERO, end, RADIUS_M).with_lane(LANE_M, RAMP_M)
	for ahead_m: float in [0.0, 0.3, 0.6, 0.9, 1.2]:
		_near(leg_a.sample(60.0 + ahead_m), with_run.sample(ahead_m), "um corpo %s m à frente do líder está no mesmo ponto no trecho que chega e no que sai" % ahead_m, 1e-5)
		if ahead_m > 0.1 and ahead_m < 1.1:
			_near(leg_a.tangent(60.0 + ahead_m), with_run.tangent(ahead_m), "e com a mesma tangente (%s m)" % ahead_m, 1e-5)
	assert_gt(leg_a.sample(61.2).distance_to(without_run.sample(1.2)), 0.05, "sem o trecho reto a troca daria um salto de uns 7 cm a 1,2 m (o problema que o parâmetro resolve)")
	var capped: CaravanRoad = CaravanRoad.entering(Vector2.RIGHT, Vector2.ZERO, Vector2(200, 100), RADIUS_M, 1000000.0)
	var half: CaravanRoad = CaravanRoad.entering(Vector2.RIGHT, Vector2.ZERO, Vector2(200, 100), RADIUS_M, 0.5 * Vector2(200, 100).length())
	assert_true(capped.length_m() == half.length_m() and capped.axis_point(80.0) == half.axis_point(80.0), "o trecho reto passa no máximo da metade da distância de start a end")
	_near(capped.axis_point(100.0), Vector2(100, 0), "e ainda é reta até lá", 1e-4)
	_near(capped.axis_point(capped.length_m()), Vector2(200, 100), "e a estrada termina em end", 1e-3)
