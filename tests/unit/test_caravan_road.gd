extends GutTest
## LW-099f: a geometria da estrada da caravana (`CaravanRoad.through`), sem janela, nó, ponte nem relógio. A reta, uma quina de 90 graus com os números de R tan(θ/2),
## a continuidade de posição e de tangente nas junções reta-arco, o raio que não cabe, a quina viva (a estrada de hoje), as curvas espelhadas, as entradas degeneradas,
## a pureza e o `axis_offset`. A faixa e o `solve_behind` estão em `test_caravan_road_lane.gd`; o trecho de saída, em `test_caravan_road_entering.gd`.
## O `Vector2` do Godot é float32 (a 300 m a resolução é de uns 3e-5 m): as tolerâncias de posição longe da origem são de 1e-4 m.

const EPS: float = 0.0001
const ARC_90_R10: float = 10.0 * PI * 0.5
const EAST: PackedVector2Array = [Vector2(0, 0), Vector2(100, 0)]
## Quina de 90 graus para a DIREITA (o sul, +z) entre dois trechos de 300 m, e a espelhada (para a esquerda).
const RIGHT_90: PackedVector2Array = [Vector2(0, 0), Vector2(300, 0), Vector2(300, 300)]
const LEFT_90: PackedVector2Array = [Vector2(0, 0), Vector2(300, 0), Vector2(300, -300)]


func _near(got: Vector2, expected: Vector2, why: String, tolerance: float = EPS) -> void:
	assert_true(got.distance_to(expected) <= tolerance, "%s: veio %s, esperado %s" % [why, got, expected])


## Uma quina: chega pelo oeste (indo para o leste), vira `turn_deg` para a DIREITA (negativo: esquerda) e segue `leg_out_m`.
func _corner_road(turn_deg: float, leg_in_m: float, leg_out_m: float, radius_m: float) -> CaravanRoad:
	return CaravanRoad.through(PackedVector2Array([Vector2(-leg_in_m, 0.0), Vector2.ZERO, Vector2.from_angle(deg_to_rad(turn_deg)) * leg_out_m]), radius_m)


func _assert_all_finite(road: CaravanRoad, why: String) -> void:
	var values: Array[Vector2] = [road.axis_point(3.0), road.sample(3.0), road.tangent(3.0), road.axis_tangent(3.0), road.end_tangent(), road.axis_offset(Vector2(3, 4))]
	for value: Vector2 in values:
		assert_true(value.is_finite(), "%s: valor não finito %s" % [why, value])
	assert_true(is_finite(road.solve_behind(Vector2(1, 1), 2.0, 5.0)), "%s: solve_behind finito" % why)
	assert_almost_eq(road.axis_tangent(3.0).length(), 1.0, 1e-6, "%s: a tangente é unitária" % why)


func test_a_straight_road_has_the_length_of_its_points_and_continues_straight_beyond_both_ends() -> void:
	var road: CaravanRoad = CaravanRoad.through(EAST, 10.0)
	assert_almost_eq(road.length_m(), 100.0, EPS, "o comprimento é a distância entre os pontos")
	assert_eq(road.corners().size(), 0, "sem quina interna")
	_near(road.axis_point(0.0), Vector2(0, 0), "s = 0 é a ponta A")
	_near(road.axis_point(50.0), Vector2(50, 0), "o meio")
	_near(road.axis_point(100.0), Vector2(100, 0), "s = comprimento é a ponta B")
	_near(road.axis_point(-25.0), Vector2(-25, 0), "antes de 0 a estrada continua em reta")
	_near(road.axis_point(125.0), Vector2(125, 0), "e depois do fim também")
	for s: float in [-25.0, 0.0, 50.0, 100.0, 125.0]:
		_near(road.axis_tangent(s), Vector2.RIGHT, "tangente constante em s = %s" % s, 1e-6)
		_near(road.tangent(s), Vector2.RIGHT, "sem faixa a tangente é a do eixo (s = %s)" % s, 1e-6)
		_near(road.sample(s), road.axis_point(s), "sem faixa o ponto da faixa é o do eixo (s = %s)" % s, 1e-6)
	_near(road.end_tangent(), Vector2.RIGHT, "o fim aponta para o leste", 1e-6)
	var split: CaravanRoad = CaravanRoad.through(PackedVector2Array([Vector2(0, 0), Vector2(40, 0), Vector2(100, 0)]), 10.0)
	assert_almost_eq(split.length_m(), 100.0, EPS, "pontos colineares: o mesmo comprimento")
	assert_eq(split.corners().size(), 1, "o ponto do meio é uma quina da lista")
	var flat: CaravanRoad.Corner = split.corners()[0]
	assert_almost_eq(flat.turn_rad, 0.0, 1e-6, "sem virada")
	assert_eq(flat.arc_m, 0.0, "sem arco")
	assert_true(flat.fits, "quina reta: não há raio a caber")
	_near(split.axis_point(40.0), Vector2(40, 0), "e a estrada passa pelo ponto do meio")


func test_a_90_degree_corner_becomes_an_arc_with_the_expected_tangent_length_and_cut() -> void:
	var road: CaravanRoad = CaravanRoad.through(RIGHT_90, 10.0)
	assert_eq(road.corners().size(), 1, "uma quina")
	var corner: CaravanRoad.Corner = road.corners()[0]
	assert_almost_eq(corner.turn_rad, PI * 0.5, 1e-9, "virada de 90 graus")
	assert_eq(corner.side, 1, "para a direita (o sul, +z)")
	assert_almost_eq(corner.radius_req_m, 10.0, 1e-9, "raio pedido")
	assert_almost_eq(corner.radius_eff_m, 10.0, 1e-9, "cabe: o efetivo é o pedido")
	assert_true(corner.fits, "cabe")
	assert_almost_eq(corner.tangent_m, 10.0, 1e-9, "tangente = R tan(45 graus)")
	assert_almost_eq(corner.arc_m, ARC_90_R10, 1e-9, "arco = R x θ")
	assert_almost_eq(corner.cut_m, 20.0 - ARC_90_R10, 1e-9, "o arco encurta a estrada em duas tangentes menos o arco")
	assert_almost_eq(corner.apex_s, 290.0 + 0.5 * ARC_90_R10, 1e-9, "o meio do arco")
	assert_almost_eq(corner.apex_off_m, 10.0 * (sqrt(2.0) - 1.0), 1e-9, "o meio do arco fica a R (1/cos(θ/2) - 1) do vértice")
	assert_almost_eq(road.length_m(), 600.0 - 20.0 + ARC_90_R10, 1e-9, "comprimento = trechos - 2T + arco")
	var worst_radius: float = 0.0
	for step: int in 41:
		var s: float = 290.0 + ARC_90_R10 * float(step) / 40.0
		worst_radius = maxf(worst_radius, absf(road.axis_point(s).distance_to(Vector2(290, 10)) - 10.0))
	assert_lt(worst_radius, EPS, "todo ponto do arco fica a R do centro (290, 10)")
	_near(road.axis_point(290.0), Vector2(290, 0), "o arco começa onde a tangente toca o primeiro trecho")
	_near(road.axis_point(290.0 + ARC_90_R10), Vector2(300, 10), "e termina onde toca o segundo")
	_near(road.axis_tangent(100.0), Vector2.RIGHT, "o primeiro trecho vai para o leste", 1e-6)
	_near(road.end_tangent(), Vector2.DOWN, "e o fim vai para o sul (+z)", 1e-6)
	_near(road.axis_point(road.length_m()), Vector2(300, 300), "termina na ponta B")


func test_the_axis_is_continuous_in_position_and_in_tangent_through_both_junctions() -> void:
	var road: CaravanRoad = CaravanRoad.through(RIGHT_90, 10.0)
	var previous_point: Vector2 = road.axis_point(280.0)
	var previous_dir: Vector2 = road.axis_tangent(280.0)
	var worst_step: float = 0.0
	var worst_turn: float = 0.0
	var total_turn: float = 0.0
	for index: int in range(1, 4001):
		var s: float = 280.0 + float(index) * 0.01
		var point: Vector2 = road.axis_point(s)
		var dir: Vector2 = road.axis_tangent(s)
		var turn: float = absf(previous_dir.angle_to(dir))
		worst_step = maxf(worst_step, point.distance_to(previous_point))
		worst_turn = maxf(worst_turn, turn)
		total_turn += turn
		previous_point = point
		previous_dir = dir
	assert_lt(worst_step, 0.01 + EPS, "de 1 cm em 1 cm o ponto nunca anda mais que 1 cm: sem salto de posição")
	assert_lt(worst_turn, 0.01 / 10.0 + 1e-5, "a tangente gira no máximo 1 cm / R por passo: sem salto nas duas junções reta-arco")
	assert_almost_eq(total_turn, PI * 0.5, 1e-3, "e a janela inteira gira os 90 graus da quina")
	for junction: float in [290.0, 290.0 + ARC_90_R10]:
		assert_lt(absf(road.axis_tangent(junction - 1e-6).angle_to(road.axis_tangent(junction + 1e-6))), 1e-5, "mesma tangente dos dois lados da junção em s = %s" % junction)
		assert_lt(road.axis_point(junction - 1e-6).distance_to(road.axis_point(junction + 1e-6)), 1e-3, "e o ponto não salta (menos de 1 mm) em s = %s" % junction)


func test_a_short_leg_shrinks_the_radius_and_the_corner_no_longer_fits() -> void:
	var short_90: CaravanRoad = _corner_road(90.0, 12.0, 12.0, 10.0)
	var corner: CaravanRoad.Corner = short_90.corners()[0]
	assert_almost_eq(corner.radius_eff_m, 6.0, 1e-4, "trechos de 12 m: a tangente é a metade do trecho (6 m), então R = 6")
	assert_almost_eq(corner.tangent_m, 6.0, 1e-4, "a tangente é a metade do trecho")
	assert_false(corner.fits, "o raio efetivo não é o pedido")
	assert_almost_eq(corner.radius_req_m, 10.0, 1e-9, "o pedido continua guardado")
	assert_almost_eq(short_90.length_m(), 24.0 - 12.0 + 6.0 * PI * 0.5, 1e-3, "o comprimento usa o raio que coube")
	assert_almost_eq(_corner_road(150.0, 12.0, 12.0, 10.0).corners()[0].radius_eff_m, 6.0 / tan(deg_to_rad(75.0)), 1e-4, "150 graus em trechos de 12 m: R = 1,61 m")
	assert_almost_eq(_corner_road(90.0, 100.0, 12.0, 10.0).corners()[0].radius_eff_m, 6.0, 1e-4, "vale o trecho adjacente MAIS CURTO")
	assert_true(_corner_road(150.0, 80.0, 80.0, 10.0).corners()[0].fits, "150 graus com trechos de 80 m (precisa de 74,6 m): cabe")
	assert_false(_corner_road(150.0, 70.0, 70.0, 10.0).corners()[0].fits, "com trechos de 70 m não cabe")
	var s_shape: CaravanRoad = CaravanRoad.through(PackedVector2Array([Vector2(0, 0), Vector2(20, 0), Vector2(20, 20), Vector2(40, 20)]), 10.0)
	assert_true(s_shape.corners()[0].fits and s_shape.corners()[1].fits, "duas quinas coladas (20 m entre elas) com R 10: cada uma usa a metade do trecho do meio e cabe")
	assert_eq([s_shape.corners()[0].side, s_shape.corners()[1].side], [1, -1], "uma para a direita e a seguinte para a esquerda")
	assert_almost_eq(s_shape.length_m(), 10.0 + ARC_90_R10 + 0.0 + ARC_90_R10 + 10.0, EPS, "10 m de reta + arco + 0 m entre os arcos + arco + 10 m de reta")
	_near(s_shape.axis_point(10.0 + ARC_90_R10), Vector2(20, 10), "a emenda dos dois arcos")
	assert_false(CaravanRoad.through(PackedVector2Array([Vector2(0, 0), Vector2(20, 0), Vector2(20, 20), Vector2(40, 20)]), 12.0).corners()[0].fits, "R 12 não cabe nesses 20 m")


func test_a_sharp_corner_has_no_arc_and_the_tangent_jumps() -> void:
	for radius: float in [0.0, -5.0, NAN, INF]:
		var road: CaravanRoad = CaravanRoad.through(RIGHT_90, radius)
		var corner: CaravanRoad.Corner = road.corners()[0]
		assert_almost_eq(road.length_m(), 600.0, EPS, "sem arco o comprimento é o da polilinha (raio %s)" % radius)
		assert_true(corner.arc_m == 0.0 and corner.cut_m == 0.0 and corner.tangent_m == 0.0 and corner.radius_eff_m == 0.0, "nenhum arco (raio %s)" % radius)
		assert_true(corner.fits, "quina viva: não há raio a caber (raio %s)" % radius)
		assert_almost_eq(corner.apex_s, 300.0, EPS, "o apice é o próprio vértice")
		_near(road.axis_point(300.0), Vector2(300, 0), "a estrada passa pelo vértice")
		_near(road.axis_tangent(299.999), Vector2.RIGHT, "antes da quina vai para o leste", 1e-6)
		_near(road.axis_tangent(300.001), Vector2.DOWN, "depois, para o sul", 1e-6)
		assert_almost_eq(road.axis_tangent(299.999).angle_to(road.axis_tangent(300.001)), PI * 0.5, 1e-5, "o salto de 90 graus de hoje (raio %s)" % radius)


func test_a_left_corner_is_the_mirror_image_of_the_right_corner() -> void:
	var right: CaravanRoad = _corner_road(129.1, 200.0, 150.0, 8.0)
	var left: CaravanRoad = _corner_road(-129.1, 200.0, 150.0, 8.0)
	var rc: CaravanRoad.Corner = right.corners()[0]
	var lc: CaravanRoad.Corner = left.corners()[0]
	assert_eq([rc.side, lc.side], [1, -1], "direita +1, esquerda -1")
	assert_almost_eq(left.length_m(), right.length_m(), EPS, "mesmo comprimento")
	for pair: Array in [[rc.turn_rad, lc.turn_rad], [rc.radius_eff_m, lc.radius_eff_m], [rc.tangent_m, lc.tangent_m], [rc.arc_m, lc.arc_m], [rc.cut_m, lc.cut_m], [rc.apex_s, lc.apex_s]]:
		assert_almost_eq(float(pair[0]), float(pair[1]), 1e-9, "os números da quina são iguais")
	for step: int in 120:
		var s: float = -5.0 + float(step) * (right.length_m() + 10.0) / 119.0
		var mirrored: Vector2 = Vector2(right.axis_point(s).x, -right.axis_point(s).y)
		_near(left.axis_point(s), mirrored, "ponto espelhado em s = %s" % s)
		_near(left.axis_tangent(s), Vector2(right.axis_tangent(s).x, -right.axis_tangent(s).y), "tangente espelhada em s = %s" % s, 1e-5)
	var plain_left: CaravanRoad.Corner = CaravanRoad.through(LEFT_90, 10.0).corners()[0]
	assert_eq(plain_left.side, -1, "norte (-z) é a esquerda de quem vai para o leste")


func test_collinear_repeated_and_non_finite_points_never_give_a_non_finite_value() -> void:
	var empties: Array[PackedVector2Array] = [PackedVector2Array(), PackedVector2Array([Vector2(5, 6)]), PackedVector2Array([Vector2(5, 6), Vector2(5, 6.0005)]),
		PackedVector2Array([Vector2(0, 0), Vector2(NAN, 0), Vector2(10, 0)]), PackedVector2Array([Vector2(0, 0), Vector2(INF, 0)]), PackedVector2Array([Vector2(0, 0), Vector2(0, -INF), Vector2(9, 9)])]
	for points: PackedVector2Array in empties:
		var road: CaravanRoad = CaravanRoad.through(points, 10.0)
		assert_eq(road.length_m(), 0.0, "estrada vazia: comprimento 0 (%s)" % points)
		assert_eq(road.corners().size(), 0, "e nenhuma quina (%s)" % points)
		assert_eq(road.axis_point(7.0), Vector2.ZERO, "o ponto vem na origem (%s)" % points)
		assert_eq(road.axis_tangent(7.0), Vector2(0, -1), "e a tangente em -Z, o giro 0 do CaravanPath (%s)" % points)
		assert_eq(road.axis_offset(Vector2(3, 4)), Vector2.ZERO, "sem estrada não há distância (%s)" % points)
		assert_eq(road.solve_behind(Vector2(1, 1), 2.0, 5.0), 5.0, "e solve_behind devolve hi (%s)" % points)
		_assert_all_finite(road, "estrada vazia")
	var repeated: CaravanRoad = CaravanRoad.through(PackedVector2Array([Vector2(0, 0), Vector2(0, 0), Vector2(100, 0), Vector2(100, 0.0005), Vector2(100, 100)]), 10.0)
	var plain: CaravanRoad = CaravanRoad.through(PackedVector2Array([Vector2(0, 0), Vector2(100, 0), Vector2(100, 100)]), 10.0)
	assert_almost_eq(repeated.length_m(), plain.length_m(), 1e-9, "ponto repetido (a 0,001 m ou menos) é ignorado: a mesma estrada")
	assert_eq(repeated.corners().size(), 1, "uma só quina")
	var road_with_lane: CaravanRoad = CaravanRoad.through(RIGHT_90, 10.0).with_lane(1.2, 12.0)
	for bad: float in [NAN, INF, -INF]:
		assert_eq(road_with_lane.axis_point(bad), road_with_lane.axis_point(0.0), "s = %s vale 0 no eixo" % bad)
		assert_eq(road_with_lane.sample(bad), road_with_lane.sample(0.0), "e na faixa")
		assert_eq(road_with_lane.axis_tangent(bad), road_with_lane.axis_tangent(0.0), "e na tangente do eixo")
		assert_eq(road_with_lane.tangent(bad), road_with_lane.tangent(0.0), "e na tangente da faixa")
		assert_eq(road_with_lane.solve_behind(Vector2(3, 0), 2.0, bad), road_with_lane.solve_behind(Vector2(3, 0), 2.0, 0.0), "e em hi do solve_behind")
	_assert_all_finite(CaravanRoad.through(PackedVector2Array([Vector2(0, 0), Vector2(100, 0), Vector2(0, 0.5)]), 10.0), "volta de quase 180 graus")


func test_building_twice_and_asking_in_any_order_gives_the_same_numbers() -> void:
	var first: CaravanRoad = _corner_road(129.1, 200.0, 150.0, 8.0).with_lane(1.2, 12.0)
	var second: CaravanRoad = _corner_road(129.1, 200.0, 150.0, 8.0).with_lane(1.2, 12.0)
	var count: int = 80
	var expected: Array[Vector2] = []
	for index: int in count:
		var s: float = -10.0 + float(index) * (first.length_m() + 20.0) / float(count - 1)
		expected.append(first.sample(s) + first.tangent(s) * 1000.0)
	for index: int in range(count - 1, -1, -1):
		var s: float = -10.0 + float(index) * (first.length_m() + 20.0) / float(count - 1)
		second.solve_behind(second.sample(s + 3.0), 2.46, s + 3.0)
		second.axis_offset(second.sample(s))
		assert_eq(second.sample(s) + second.tangent(s) * 1000.0, expected[index], "mesmo número em s = %s, na ordem inversa e de outra estrada igual" % s)


func test_axis_offset_gives_the_distance_and_the_side_with_the_right_positive() -> void:
	var east: CaravanRoad = CaravanRoad.through(EAST, 10.0)
	assert_eq(east.axis_offset(Vector2(50, 3)), Vector2(3, 3), "3 m ao sul (+z), a direita de quem vai para o leste")
	assert_eq(east.axis_offset(Vector2(50, -2)), Vector2(2, -2), "2 m ao norte: à esquerda, sinal negativo")
	assert_eq(east.axis_offset(Vector2(-20, 5)), Vector2(5, 5), "as retas das pontas se estendem (antes de 0)")
	assert_eq(east.axis_offset(Vector2(130, -4)), Vector2(4, -4), "e depois do fim")
	var right: CaravanRoad = CaravanRoad.through(RIGHT_90, 10.0)
	var radial: Vector2 = Vector2(1, -1).normalized()
	_near(right.axis_offset(Vector2(290, 10) + radial * 8.0), Vector2(2, 2), "dentro da curva à direita (rumo ao centro): à direita, sinal +", 1e-4)
	_near(right.axis_offset(Vector2(290, 10) + radial * 13.0), Vector2(3, -3), "fora da curva à direita: à esquerda, sinal -", 1e-4)
	var left: CaravanRoad = CaravanRoad.through(LEFT_90, 10.0)
	var left_radial: Vector2 = Vector2(1, 1).normalized()
	_near(left.axis_offset(Vector2(290, -10) + left_radial * 8.0), Vector2(2, -2), "dentro da curva à esquerda: sinal -", 1e-4)
	_near(left.axis_offset(Vector2(290, -10) + left_radial * 13.0), Vector2(3, 3), "fora da curva à esquerda: sinal +", 1e-4)
