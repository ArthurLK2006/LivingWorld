extends GutTest
## LW-072d: a rota N1 e o passo P1 do corpo do NPC (DEC-122), funções puras sem nó, ponte nem relógio. Contas à mão: 4 m/s vezes a velocidade do
## relógio (pausa = parado); rota reta por pontos que segue a altura do terreno; recusa acima de 40 graus (a altura ilegível também recusa);
## o corpo para na borda da caixa do local (engordada pelo raio da cápsula), não no centro; o nariz aponta para onde o corpo anda.

const TOLERANCE: float = 0.001
## Um minuto de jogo dura 1,25 s reais com o relógio na velocidade 1 (SimClock.DEFAULT_REAL_MS_PER_MINUTE = 1250).
const REAL_SECONDS_PER_GAME_MINUTE: float = 1.25
const WORK_HALF_M: Vector2 = Vector2(4.0, 3.0)
const RADIUS_M: float = 0.4

var _rise_per_m: float = 0.0


func _flat(_x: float, _z: float) -> float:
	return 10.0


func _ramp(x: float, _z: float) -> float:
	return x * _rise_per_m


## Parede de 5 m de altura a partir de x = 10: entre duas amostras seguidas, mais de 68 graus.
func _wall(x: float, _z: float) -> float:
	return 0.0 if x < 10.0 else 5.0


func _unreadable_after_6(x: float, _z: float) -> float:
	return 0.0 if x <= 6.0 else NAN


func test_p1_walks_4_m_per_s_times_the_clock_speed_and_stands_still_when_paused() -> void:
	for clock_speed: int in range(1, 9):
		assert_almost_eq(NpcRoute.speed_mps(clock_speed, false), 4.0 * float(clock_speed), TOLERANCE, "Velocidade %dx." % clock_speed)
		assert_eq(NpcRoute.speed_mps(clock_speed, true), 0.0, "Pausado, parado (%dx)." % clock_speed)
		var meters_per_game_minute: float = NpcRoute.speed_mps(clock_speed, false) * REAL_SECONDS_PER_GAME_MINUTE / float(clock_speed)
		assert_almost_eq(meters_per_game_minute, 5.0, TOLERANCE, "Em qualquer velocidade o corpo anda 5 m por minuto de jogo.")
	assert_eq([NpcRoute.speed_mps(0, false), NpcRoute.speed_mps(-1, false)], [0.0, 0.0], "Velocidade inválida: parado.")


func test_a_flat_route_is_a_straight_line_of_points_that_follow_the_ground_to_the_goal() -> void:
	_rise_per_m = tan(deg_to_rad(10.0))
	var route: NpcRoute = NpcRoute.plan(Vector3(0.0, 0.0, 5.0), Vector3(20.0, 0.0, 5.0), Vector2.ZERO, _ramp)
	assert_false(route.is_blocked)
	assert_almost_eq(route.length_m, 20.0, TOLERANCE)
	assert_eq(route.points.size(), 11, "Uma amostra a cada 2 m, mais o começo.")
	assert_eq(route.position_at(0.0), Vector3(0.0, 0.0, 5.0))
	assert_almost_eq(route.position_at(5.0).y, 5.0 * _rise_per_m, TOLERANCE, "A altura segue o terreno entre as amostras.")
	assert_almost_eq(route.position_at(5.0).x, 5.0, TOLERANCE)
	assert_almost_eq(route.position_at(20.0), route.points[10], Vector3.ONE * TOLERANCE, "O fim da rota é o destino.")
	assert_almost_eq(route.position_at(99.0), route.points[10], Vector3.ONE * TOLERANCE, "Depois do fim, o fim.")
	assert_almost_eq(route.position_at(-3.0), route.points[0], Vector3.ONE * TOLERANCE, "Antes do começo, o começo.")


func test_a_route_over_40_degrees_is_refused_a_gentler_one_is_not_and_unreadable_ground_refuses() -> void:
	var start: Vector3 = Vector3(0.0, 0.0, 0.0)
	var goal: Vector3 = Vector3(30.0, 0.0, 0.0)
	_rise_per_m = tan(deg_to_rad(39.9))
	assert_false(NpcRoute.plan(start, goal, Vector2.ZERO, _ramp).is_blocked, "39,9 graus passa.")
	_rise_per_m = tan(deg_to_rad(40.1))
	var refused: NpcRoute = NpcRoute.plan(start, goal, Vector2.ZERO, _ramp)
	assert_true(refused.is_blocked, "40,1 graus não passa.")
	assert_eq(refused.points.size(), 0, "Rota recusada não tem pontos.")
	assert_true(NpcRoute.plan(start, goal, Vector2.ZERO, _wall).is_blocked, "Uma parede no meio do caminho recusa a rota inteira.")
	assert_false(NpcRoute.plan(start, Vector3(8.0, 0.0, 0.0), Vector2.ZERO, _wall).is_blocked, "A mesma parede além do destino não conta.")
	assert_true(NpcRoute.plan(start, goal, Vector2.ZERO, _unreadable_after_6).is_blocked, "Altura que não pode ser lida recusa.")
	assert_true(NpcRoute.plan(Vector3(7.0, 0.0, 0.0), goal, Vector2.ZERO, _unreadable_after_6).is_blocked, "Também no ponto de partida.")


func test_the_body_stops_at_the_edge_of_the_box_and_not_at_its_center() -> void:
	var goal: Vector2 = Vector2(100.0, 100.0)
	var along_x: Vector2 = NpcRoute.stop_point(Vector2(0.0, 100.0), goal, WORK_HALF_M)
	assert_almost_eq(along_x.x, 100.0 - (WORK_HALF_M.x + RADIUS_M), TOLERANCE, "Chegando pelo lado, para a meia largura mais o raio antes do centro.")
	assert_almost_eq(along_x.y, 100.0, TOLERANCE)
	var diagonal: Vector2 = NpcRoute.stop_point(Vector2(0.0, 0.0), goal, WORK_HALF_M)
	var gap: Vector2 = (goal - diagonal).abs() - (WORK_HALF_M + Vector2.ONE * RADIUS_M)
	assert_almost_eq(maxf(gap.x, gap.y), 0.0, TOLERANCE, "Na diagonal, para exatamente na borda da caixa engordada.")
	assert_almost_eq(NpcRoute.stop_point(Vector2(200.0, 100.0), goal, WORK_HALF_M).x, 100.0 + WORK_HALF_M.x + RADIUS_M, TOLERANCE, "Do outro lado, a mesma conta.")
	assert_eq(NpcRoute.stop_point(Vector2(98.0, 101.0), goal, WORK_HALF_M), Vector2(98.0, 101.0), "Já dentro da borda, não anda.")
	assert_eq(NpcRoute.stop_point(Vector2(0.0, 0.0), goal, Vector2.ZERO), goal, "Sem caixa, o centro.")
	var route: NpcRoute = NpcRoute.plan(Vector3(0.0, 0.0, 100.0), Vector3(100.0, 0.0, 100.0), WORK_HALF_M, _flat)
	assert_almost_eq(route.length_m, 95.6, TOLERANCE, "A rota termina na borda: 100 menos 4,4.")
	assert_almost_eq(route.points[route.points.size() - 1].x, 95.6, TOLERANCE)
	assert_eq(NpcRoute.plan(Vector3(98.0, 0.0, 100.0), Vector3(100.0, 0.0, 100.0), WORK_HALF_M, _flat).length_m, 0.0, "Quem já está no local tem rota de comprimento zero.")


func test_the_nose_points_where_the_body_walks() -> void:
	for heading: Vector3 in [Vector3(1.0, 0.0, 0.0), Vector3(-1.0, 0.0, 0.0), Vector3(0.0, 0.0, 1.0), Vector3(0.0, 0.0, -1.0), Vector3(3.0, 5.0, -4.0)]:
		var nose: Vector3 = Basis(Vector3.UP, NpcRoute.facing_yaw(heading)) * Vector3(0.0, 0.0, -1.0)
		var flat: Vector3 = Vector3(heading.x, 0.0, heading.z).normalized()
		assert_almost_eq(nose.distance_to(flat), 0.0, TOLERANCE, "Frente do corpo na direção %s." % str(heading))
