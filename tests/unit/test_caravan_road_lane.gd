extends GutTest
## LW-099f: a FAIXA (lado direito, rampa suave) e a busca `solve_behind` da estrada da caravana (`CaravanRoad`), sem janela, nó, ponte nem relógio. O lado da faixa (a
## direita de quem vai para o leste é o sul, +z, como no `CaravanPath`), o smoothstep da rampa (0,5 no meio, derivada 0 nas pontas), a simetria fora do trecho (a pose do
## fim de um trecho é a do começo do seguinte), a tangente da faixa e a corda EXATA de `solve_behind` em reta, arco, quina e volta sobre si (o PRIMEIRO cruzamento).
## O `Vector2` do Godot é float32: as estradas dos testes de corda ficam perto da origem (a 30 m a resolução é de 2e-6 m) para provar o erro de 1e-5 m.

const EPS: float = 0.0001
const LANE_M: float = 1.2
const RAMP_M: float = 12.0
const EAST_400: PackedVector2Array = [Vector2(0, 0), Vector2(400, 0)]
## Quina de 90 graus para a DIREITA perto da origem (o arco de R 10 vai de (-10, 0) a (0, 10)) e a espelhada.
const RIGHT_SMALL: PackedVector2Array = [Vector2(-30, 0), Vector2(0, 0), Vector2(0, 30)]
const LEFT_SMALL: PackedVector2Array = [Vector2(-30, 0), Vector2(0, 0), Vector2(0, -30)]


func _near(got: Vector2, expected: Vector2, why: String, tolerance: float = EPS) -> void:
	assert_true(got.distance_to(expected) <= tolerance, "%s: veio %s, esperado %s" % [why, got, expected])


## O fator da faixa numa estrada que vai para o leste: o deslocamento para o sul dividido pela faixa.
func _factor(road: CaravanRoad, s: float) -> float:
	return road.sample(s).y / LANE_M


func test_the_lane_is_to_the_right_of_the_march_and_the_sign_is_the_side() -> void:
	var east: CaravanRoad = CaravanRoad.through(EAST_400, 0.0).with_lane(LANE_M, 0.0)
	_near(east.sample(50.0), Vector2(50, LANE_M), "indo para o leste a direita é o sul (+z)")
	var west: CaravanRoad = CaravanRoad.through(PackedVector2Array([Vector2(400, 0), Vector2(0, 0)]), 0.0).with_lane(LANE_M, 0.0)
	_near(west.sample(50.0), Vector2(350, -LANE_M), "indo para o oeste a direita é o norte (-z): quem vai e quem volta não se cruzam")
	var north: CaravanRoad = CaravanRoad.through(PackedVector2Array([Vector2(0, 0), Vector2(0, -400)]), 0.0).with_lane(LANE_M, 0.0)
	_near(north.sample(50.0), Vector2(LANE_M, -50), "indo para o norte (-z) a direita é o leste (+x)")
	_near(CaravanRoad.through(EAST_400, 0.0).with_lane(-LANE_M, 0.0).sample(50.0), Vector2(50, -LANE_M), "faixa negativa: à esquerda")
	_near(east.axis_offset(east.sample(50.0)), Vector2(LANE_M, LANE_M), "distância 1,2 e lado + (direita) pelo axis_offset", 1e-5)
	assert_eq(east.lane_m(), LANE_M, "lane_m() devolve a faixa pedida")
	var same: CaravanRoad = CaravanRoad.through(EAST_400, 0.0)
	assert_true(same.with_lane(LANE_M, RAMP_M) == same, "with_lane devolve a própria estrada")
	for bad: float in [NAN, INF, -INF]:
		var flat: CaravanRoad = CaravanRoad.through(EAST_400, 0.0).with_lane(bad, 0.0)
		assert_eq(flat.lane_m(), 0.0, "faixa %s vale 0" % bad)
		assert_eq(flat.sample(50.0), flat.axis_point(50.0), "e o ponto da faixa é o do eixo")


func test_the_lane_keeps_its_distance_and_side_on_arcs_inside_a_right_turn_and_outside_a_left_turn() -> void:
	var right: CaravanRoad = CaravanRoad.through(RIGHT_SMALL, 10.0).with_lane(LANE_M, 0.0)
	var left: CaravanRoad = CaravanRoad.through(LEFT_SMALL, 10.0).with_lane(LANE_M, 0.0)
	var arc_mid: float = 20.0 + 0.5 * 10.0 * PI * 0.5
	assert_almost_eq(right.sample(arc_mid).distance_to(Vector2(-10, 10)), 10.0 - LANE_M, EPS, "curva à direita: a direita é por dentro (R - 1,2)")
	assert_almost_eq(left.sample(arc_mid).distance_to(Vector2(-10, -10)), 10.0 + LANE_M, EPS, "curva à esquerda: a direita é por fora (R + 1,2)")
	for road: CaravanRoad in [right, left]:
		for step: int in 40:
			var s: float = -3.0 + float(step) * (road.length_m() + 6.0) / 39.0
			_near(road.axis_offset(road.sample(s)), Vector2(LANE_M, LANE_M), "a faixa fica a 1,2 m do eixo, do lado + (s = %s)" % s)


func test_the_ramp_is_a_smoothstep_that_starts_and_ends_flat() -> void:
	var road: CaravanRoad = CaravanRoad.through(EAST_400, 0.0).with_lane(LANE_M, RAMP_M)
	assert_almost_eq(_factor(road, 0.0), 0.0, 1e-6, "no começo o veículo está no eixo (onde o NpcView está)")
	assert_almost_eq(_factor(road, 3.0), 0.15625, 1e-6, "3 m de 12: 3t² - 2t³ com t = 1/4")
	assert_almost_eq(_factor(road, 6.0), 0.5, 1e-6, "no meio da rampa vale 0,5")
	assert_almost_eq(_factor(road, 12.0), 1.0, 1e-6, "depois da rampa, a faixa cheia")
	assert_almost_eq(_factor(road, 200.0), 1.0, 1e-6, "e cheia no meio do trecho")
	assert_almost_eq(_factor(road, 394.0), 0.5, 1e-6, "a rampa de chegada espelha a de saída")
	assert_almost_eq(_factor(road, 400.0), 0.0, 1e-6, "na chegada a faixa volta a 0")
	assert_lt((_factor(road, 0.01) - _factor(road, 0.0)) / 0.01, 1e-3, "derivada ~0 em s = 0 (a rampa linear teria 1/12 = 0,083)")
	assert_lt((_factor(road, 12.0) - _factor(road, 11.99)) / 0.01, 1e-3, "e ~0 onde a rampa encontra a faixa cheia")
	assert_almost_eq((_factor(road, 6.01) - _factor(road, 5.99)) / 0.02, 1.5 / RAMP_M, 1e-3, "no meio a inclinação é 1,5 / rampa")
	for ramp: float in [0.0, -3.0, NAN, INF]:
		var full: CaravanRoad = CaravanRoad.through(EAST_400, 0.0).with_lane(LANE_M, ramp)
		assert_almost_eq(_factor(full, 0.0), 1.0, 1e-6, "rampa %s: faixa cheia em todo o trecho, até na ponta" % ramp)
		assert_almost_eq(_factor(full, 400.0), 1.0, 1e-6, "e na chegada")
	var short: CaravanRoad = CaravanRoad.through(PackedVector2Array([Vector2(0, 0), Vector2(10, 0)]), 0.0).with_lane(LANE_M, RAMP_M)
	var t: float = 5.0 / RAMP_M
	assert_almost_eq(_factor(short, 5.0), t * t * (3.0 - 2.0 * t), 1e-6, "trecho menor que 2 rampas: a faixa não chega a 1 (o fator é o da ponta mais perto: 3t² - 2t³ com t = 5/12)")


func test_the_ramp_is_symmetric_outside_the_leg_so_the_end_of_a_leg_matches_the_start_of_the_next() -> void:
	var road: CaravanRoad = CaravanRoad.through(EAST_400, 0.0).with_lane(LANE_M, RAMP_M)
	for d: float in [0.5, 3.0, 6.0, 11.9, 20.0]:
		assert_almost_eq(_factor(road, -d), _factor(road, d), 1e-6, "s = -%s e s = %s têm o mesmo fator" % [d, d])
		assert_almost_eq(_factor(road, 400.0 + d), _factor(road, 400.0 - d), 1e-6, "e 400 + %s e 400 - %s também" % [d, d])
		assert_almost_eq(road.sample(-d).x, -d, 1e-5, "antes de 0 a faixa segue a reta (s = -%s)" % d)
	var leg_a: CaravanRoad = CaravanRoad.through(PackedVector2Array([Vector2(-60, 0), Vector2(0, 0)]), 10.0).with_lane(LANE_M, RAMP_M)
	var leg_b: CaravanRoad = CaravanRoad.entering(leg_a.end_tangent(), Vector2.ZERO, Vector2(30, 40), 6.0).with_lane(LANE_M, RAMP_M)
	for d: float in [0.5, 3.0, 6.0, 11.0, 20.0]:
		_near(leg_a.sample(60.0 - d), leg_b.sample(-d), "a cauda a %s m do mercado é o mesmo ponto vista do trecho que chega e do que sai" % d, 1e-5)
		_near(leg_a.tangent(60.0 - d), leg_b.tangent(-d), "e a mesma tangente (%s m)" % d, 1e-5)
	_near(leg_a.sample(60.0), leg_b.sample(0.0), "e no próprio mercado (faixa 0) os dois trechos estão no mesmo ponto", 1e-5)


func test_the_closed_form_lane_tangent_matches_a_fine_difference_better_than_a_coarse_chord() -> void:
	var points: PackedVector2Array = [Vector2(-30, 0), Vector2(0, 0), Vector2(0, 30)]
	var road: CaravanRoad = CaravanRoad.through(points, 6.0).with_lane(LANE_M, RAMP_M)
	var bare: CaravanRoad = CaravanRoad.through(points, 6.0)
	var worst_closed: float = 0.0
	var worst_chord: float = 0.0
	for index: int in 1200:
		var s: float = -2.0 + float(index) * (road.length_m() + 4.0) / 1199.0
		var tangent_here: Vector2 = road.tangent(s)
		var fine: Vector2 = (road.sample(s + 0.01) - road.sample(s - 0.01)).normalized()
		var coarse: Vector2 = (road.sample(s + 0.05) - road.sample(s - 0.05)).normalized()
		worst_closed = maxf(worst_closed, absf(tangent_here.angle_to(fine)))
		worst_chord = maxf(worst_chord, absf(coarse.angle_to(fine)))
		assert_almost_eq(tangent_here.length(), 1.0, 1e-5, "tangente unitária em s = %s" % s)
		assert_eq(bare.tangent(s), bare.axis_tangent(s), "sem faixa a tangente é a do eixo (s = %s)" % s)
	assert_lt(worst_closed, 2e-4, "a forma fechada concorda com a diferença fina de 0,02 m (dentro do ruído float32), nas rampas, nos arcos e nas junções")
	assert_lt(worst_closed, worst_chord, "e erra menos que a corda de 0,1 m, que erra mais onde a curvatura salta (as junções reta-arco)")
	var straight: CaravanRoad = CaravanRoad.through(EAST_400, 0.0).with_lane(LANE_M, RAMP_M)
	_near(straight.tangent(100.0), Vector2.RIGHT, "faixa cheia numa reta: a tangente do eixo", 1e-6)
	assert_gt(straight.tangent(3.0).y, 0.0, "e na rampa de saída a faixa se afasta para a direita (+z para o leste): a tangente aponta um pouco para a direita")
	assert_lt(straight.tangent(397.0).y, 0.0, "e na de chegada volta ao eixo: aponta um pouco para a esquerda")


func test_solve_behind_returns_the_point_at_the_exact_chord_on_straights_arcs_and_corners() -> void:
	var roads: Array[CaravanRoad] = [CaravanRoad.through(PackedVector2Array([Vector2(-30, 0), Vector2(30, 0)]), 10.0), CaravanRoad.through(RIGHT_SMALL, 10.0), CaravanRoad.through(LEFT_SMALL, 10.0),
		CaravanRoad.through(RIGHT_SMALL, 0.0), CaravanRoad.through(PackedVector2Array([Vector2(-30, 0), Vector2(0, 0), Vector2.from_angle(deg_to_rad(129.1)) * 30.0]), 8.0)]
	var worst: float = 0.0
	var worst_back: float = -INF
	for lane: float in [0.0, LANE_M]:
		for base: CaravanRoad in roads:
			if lane != 0.0 and base.corners().size() > 0 and base.corners()[0].arc_m == 0.0:
				continue
			var road: CaravanRoad = base.with_lane(lane, RAMP_M if lane != 0.0 else 0.0)
			for hi_fraction: float in [0.25, 0.4, 0.5, 0.6, 0.75, 1.0]:
				var hi: float = hi_fraction * road.length_m()
				var q: Vector2 = road.sample(hi)
				for distance: float in [0.5, 1.0, 2.46, 5.0, 10.0]:
					var found: float = road.solve_behind(q, distance, hi)
					worst = maxf(worst, absf(road.sample(found).distance_to(q) - distance))
					worst_back = maxf(worst_back, found - hi)
	assert_lt(worst, 1e-5, "a corda do ponto achado erra menos de 1e-5 m (reta, arco e quina; distâncias de 0,5 a 10 m; com e sem faixa)")
	assert_lt(worst_back, 0.0, "e o ponto achado fica sempre ATRÁS de hi")
	var line: CaravanRoad = CaravanRoad.through(PackedVector2Array([Vector2(-30, 0), Vector2(30, 0)]), 10.0).with_lane(LANE_M, 0.0)
	assert_almost_eq(line.solve_behind(line.sample(7.0), 2.46, 7.0), 4.54, 1e-5, "em reta o ponto está a distance_m de caminho: 7 - 2,46")
	var sharp: CaravanRoad = CaravanRoad.through(RIGHT_SMALL, 0.0)
	assert_almost_eq(sharp.solve_behind(sharp.axis_point(33.0), 5.0, 33.0), 26.0, 1e-5, "quina viva: 3 m depois da quina e 5 m de corda dá 4 m antes dela (3-4-5)")
	sharp.with_lane(LANE_M, 0.0)
	assert_almost_eq(sharp.sample(30.0 - 1e-6).distance_to(sharp.sample(30.0 + 1e-6)), LANE_M * sqrt(2.0), 1e-4, "numa quina VIVA a faixa dá um salto no vértice (é por isso que a estrada com curvas usa arcos)...")
	assert_true(is_finite(sharp.solve_behind(sharp.sample(30.0), 0.5, 30.0)), "...e uma corda que cai no salto não tem solução exata: sai um número finito (o ponto do salto)")


func test_solve_behind_finds_the_first_crossing_on_a_road_that_folds_back() -> void:
	var points: PackedVector2Array = [Vector2(-20, 0), Vector2(20, 0), Vector2(-20, 3)]
	var hairpin: CaravanRoad = CaravanRoad.through(points, 0.0)
	var hi: float = 60.0
	var q: Vector2 = hairpin.sample(hi)
	assert_gt(hairpin.sample(40.0).distance_to(q), 15.0, "a ida cruza o círculo de 15 m ao redor de q (a volta fica ao lado dela)...")
	assert_lt(hairpin.sample(20.0).distance_to(q), 15.0, "...entrando e saindo dele")
	var found: float = hairpin.solve_behind(q, 15.0, hi)
	assert_almost_eq(found, 45.0, 1e-4, "o primeiro cruzamento (para trás) é na própria volta, a 15 m de caminho, e não nos outros dois da ida")
	assert_lt(absf(hairpin.sample(found).distance_to(q) - 15.0), 1e-5, "e a corda é exata")
	var rounded: CaravanRoad = CaravanRoad.through(points, 1.2)
	assert_false(rounded.corners()[0].fits, "o grampo arredondado (R 1,2) não cabe nos trechos: o raio efetivo encolhe")
	var rounded_hi: float = rounded.corners()[0].apex_s + 6.0
	var rounded_q: Vector2 = rounded.sample(rounded_hi)
	assert_lt(rounded.sample(15.0).distance_to(rounded_q), rounded.sample(20.0).distance_to(rounded_q), "a distância a q sobe, desce e sobe de novo para trás: não é monótona")
	var rounded_found: float = rounded.solve_behind(rounded_q, 11.0, rounded_hi)
	assert_lt(absf(rounded.sample(rounded_found).distance_to(rounded_q) - 11.0), 1e-5, "grampo arredondado: a corda de 11 m é exata")
	var earlier_crossing: bool = false
	for step: int in range(1, 1000):
		var s: float = rounded_found + (rounded_hi - rounded_found) * float(step) / 1000.0
		earlier_crossing = earlier_crossing or rounded.sample(s).distance_to(rounded_q) > 11.0 + 1e-5
	assert_false(earlier_crossing, "entre o ponto achado e hi nenhum ponto está a mais de 11 m: é o primeiro cruzamento")


func test_solve_behind_with_bad_input_gives_a_finite_answer_without_a_long_search() -> void:
	var road: CaravanRoad = CaravanRoad.through(RIGHT_SMALL, 10.0)
	var q: Vector2 = road.axis_point(30.0)
	for distance: float in [0.0, -1.0, NAN, INF]:
		assert_eq(road.solve_behind(q, distance, 30.0), 30.0, "distância %s: devolve hi" % distance)
	assert_eq(road.solve_behind(Vector2(NAN, 0), 2.0, 30.0), 30.0, "q não finito: devolve hi")
	assert_eq(road.solve_behind(q, 2.0, NAN), road.solve_behind(q, 2.0, 0.0), "hi não finito vale 0")
	for distance: float in [1e-9, 1e-3, 1e6]:
		assert_true(is_finite(road.solve_behind(q, distance, 30.0)), "distância %s: devolve um número finito (a varredura tem teto)" % distance)
	assert_true(is_finite(road.solve_behind(Vector2(500, 500), 2.0, 30.0)), "sem ponto a essa distância (fora da pré-condição) ainda sai um palpite finito")
