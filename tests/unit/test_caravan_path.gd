extends GutTest
## LW-099a: as contas puras da estrada da caravana (`CaravanPath`), sem janela, nó, ponte nem relógio. Propriedades da polilinha: as pontas, o sentido invertido,
## o avanço que nunca recua e em ritmo uniforme, o passo que nunca passa da fração andada, o giro contínuo nas quinas, o deslocamento lateral sempre à direita
## da marcha, `u` fora de [0,1], entradas degeneradas e a inclinação limitada. Os números do jogo (2 m à frente, 1,2 m, 25 graus) são [HIP] provisórios; aqui
## só valem as propriedades, com polilinhas de teste.

const EPS: float = 0.0001
const STEPS: int = 300
const LATERAL_M: float = 1.2
## Escada de 30 m com duas quinas de 90 graus (leste, sul, leste); nunca recua em x nem em z.
const STAIRS: PackedVector2Array = [Vector2(0, 0), Vector2(10, 0), Vector2(10, 10), Vector2(20, 10)]
## Quina de 45 graus (50 m para o leste e 42,43 m para o sudeste).
const BEND: PackedVector2Array = [Vector2(0, 0), Vector2(50, 0), Vector2(80, 30)]
const EAST: PackedVector2Array = [Vector2(0, 0), Vector2(100, 0)]


func _pose(path: CaravanPath, u: float, forward: bool = true, lateral_m: float = 0.0) -> CaravanPath.Pose:
	var pose: CaravanPath.Pose = CaravanPath.Pose.new()
	path.sample_into(u, forward, lateral_m, pose)
	return pose


func _near(got: Vector2, expected: Vector2, why: String) -> void:
	assert_true(got.distance_to(expected) < EPS, "%s: veio %s, esperado %s" % [why, got, expected])


## Para onde a frente do corpo aponta (no plano x, z) com aquele giro: -Z local girado em torno de Y.
func _facing(pose: CaravanPath.Pose) -> Vector2:
	var forward: Vector3 = Basis(Vector3.UP, pose.yaw) * Vector3.FORWARD
	return Vector2(forward.x, forward.z)


func test_the_ends_and_the_length_of_the_polyline() -> void:
	var path: CaravanPath = CaravanPath.new(STAIRS)
	assert_almost_eq(path.length_m(), 30.0, EPS, "10 + 10 + 10 m")
	_near(_pose(path, 0.0).position, Vector2(0, 0), "u = 0 é a ponta A")
	_near(_pose(path, 1.0).position, Vector2(20, 10), "u = 1 é a ponta B")


func test_the_reverse_direction_swaps_the_ends_and_mirrors_the_fraction() -> void:
	var path: CaravanPath = CaravanPath.new(STAIRS)
	_near(_pose(path, 0.0, false).position, Vector2(20, 10), "invertido sai da ponta B")
	_near(_pose(path, 1.0, false).position, Vector2(0, 0), "e chega na ponta A")
	for tenth: int in 11:
		var u: float = float(tenth) / 10.0
		_near(_pose(path, u, false).position, _pose(path, 1.0 - u).position, "invertido em u = %s é o de ida em 1 - u" % u)


func test_progress_never_goes_back_and_the_pace_is_uniform() -> void:
	var path: CaravanPath = CaravanPath.new(STAIRS)
	var previous: Vector2 = Vector2.ZERO
	var walked: float = 0.0
	var worst_back: float = 0.0
	var worst_pace: float = 0.0
	for index: int in range(1, STEPS + 1):
		var u: float = float(index) / float(STEPS)
		var here: Vector2 = _pose(path, u).position
		worst_back = maxf(worst_back, maxf(previous.x - here.x, previous.y - here.y))
		walked += here.distance_to(previous)
		worst_pace = maxf(worst_pace, absf(walked - u * path.length_m()))
		previous = here
	assert_lt(worst_back, EPS, "x e z nunca diminuem ao longo da escada")
	assert_lt(worst_pace, 0.05, "a distância andada é u vezes o comprimento: ritmo uniforme, também nas quinas")


func test_a_step_is_never_longer_than_the_fraction_walked_plus_the_turn_of_the_offset() -> void:
	var path: CaravanPath = CaravanPath.new(STAIRS)
	var worst: float = -INF
	for forward: bool in [true, false]:
		for lateral_m: float in [0.0, LATERAL_M]:
			var previous: CaravanPath.Pose = _pose(path, 0.0, forward, lateral_m)
			for index: int in range(1, STEPS + 1):
				var here: CaravanPath.Pose = _pose(path, float(index) / float(STEPS), forward, lateral_m)
				var allowed: float = path.length_m() / float(STEPS) + lateral_m * absf(angle_difference(previous.yaw, here.yaw))
				worst = maxf(worst, here.position.distance_to(previous.position) - allowed)
				previous = here
	assert_lt(worst, EPS, "o passo cabe na fração andada (e, com deslocamento, na volta do deslocamento)")


func test_the_yaw_turns_continuously_through_the_corners_and_points_along_the_march() -> void:
	var path: CaravanPath = CaravanPath.new(STAIRS)
	var previous: CaravanPath.Pose = _pose(path, 0.0)
	var worst_turn: float = 0.0
	var total_turn: float = 0.0
	for index: int in range(1, 6 * STEPS + 1):
		var here: CaravanPath.Pose = _pose(path, float(index) / float(6 * STEPS))
		var turn: float = absf(angle_difference(previous.yaw, here.yaw))
		worst_turn = maxf(worst_turn, turn)
		total_turn += turn
		previous = here
	assert_lt(worst_turn, 0.02, "sem salto de giro nas quinas (0,017 m por passo; a quina gira no máximo 1 rad por metro)")
	assert_almost_eq(total_turn, PI, 0.01, "duas quinas de 90 graus, de volta ao leste")
	_near(_facing(_pose(path, 0.1)), Vector2(1, 0), "no primeiro trecho a frente aponta para o leste")
	_near(_facing(_pose(path, 0.5)), Vector2(0, 1), "no trecho do meio, para o sul (+z)")
	_near(_facing(_pose(path, 0.1, false)), Vector2(-1, 0), "invertida, a frente aponta para o outro lado")
	assert_almost_eq(_pose(CaravanPath.new(EAST), 0.5).yaw, NpcRoute.facing_yaw(Vector3.RIGHT), EPS, "mesma convenção do giro do NpcRoute")


func test_the_lateral_offset_is_always_to_the_right_of_the_march() -> void:
	var line: CaravanPath = CaravanPath.new(EAST)
	_near(_pose(line, 0.5, true, LATERAL_M).position, Vector2(50, LATERAL_M), "quem vai para o leste tem a direita ao sul (+z)")
	_near(_pose(line, 0.5, false, LATERAL_M).position, Vector2(50, -LATERAL_M), "quem volta tem a direita ao norte: as faixas não se cruzam")
	var bend: CaravanPath = CaravanPath.new(BEND)
	var worst_side: float = INF
	var worst_size: float = 0.0
	for forward: bool in [true, false]:
		for index: int in 200:
			var u: float = float(index) / 200.0
			var center: Vector2 = _pose(bend, u, forward).position
			var offset: Vector2 = _pose(bend, u, forward, LATERAL_M).position - center
			var march: Vector2 = _pose(bend, u + 0.001, forward).position - center
			worst_side = minf(worst_side, march.normalized().cross(offset))
			worst_size = maxf(worst_size, absf(offset.length() - LATERAL_M))
	assert_gt(worst_side, 0.0, "o deslocamento fica sempre à direita da marcha, também na quina")
	assert_lt(worst_size, EPS, "e mede sempre o pedido")


func test_a_fraction_outside_the_leg_is_clamped() -> void:
	var path: CaravanPath = CaravanPath.new(STAIRS)
	for forward: bool in [true, false]:
		for pair: Array in [[-0.5, 0.0], [1.5, 1.0], [INF, 1.0], [-INF, 0.0], [NAN, 0.0]]:
			var got: CaravanPath.Pose = _pose(path, float(pair[0]), forward, LATERAL_M)
			var expected: CaravanPath.Pose = _pose(path, float(pair[1]), forward, LATERAL_M)
			_near(got.position, expected.position, "u = %s vale %s (com deslocamento)" % [pair[0], pair[1]])
			assert_almost_eq(got.yaw, expected.yaw, EPS, "o giro também (u = %s)" % pair[0])


func test_the_pitch_follows_the_slope_and_is_limited() -> void:
	assert_eq(CaravanPath.pitch_from_heights(10.0, 10.0, 1.5, 25.0), 0.0, "plano")
	assert_almost_eq(CaravanPath.pitch_from_heights(0.0, 0.15, 1.5, 25.0), atan(0.1), EPS, "subida suave: não é limitada")
	assert_almost_eq(CaravanPath.pitch_from_heights(0.15, 0.0, 1.5, 25.0), -atan(0.1), EPS, "descida suave")
	assert_almost_eq(rad_to_deg(CaravanPath.pitch_from_heights(0.0, 3.0, 1.5, 25.0)), 25.0, EPS, "63 graus de terreno viram 25")
	assert_almost_eq(rad_to_deg(CaravanPath.pitch_from_heights(3.0, 0.0, 1.5, 25.0)), -25.0, EPS, "e -25 na descida")
	assert_eq(CaravanPath.pitch_from_heights(0.0, 3.0, 0.0, 25.0), 0.0, "espaço zero: nivelado")
	assert_eq(CaravanPath.pitch_from_heights(NAN, 3.0, 1.5, 25.0), 0.0, "altura que não é número: nivelado")
	assert_eq(CaravanPath.pitch_from_heights(0.0, 3.0, 1.5, 0.0), 0.0, "limite zero: nivelado")


func test_a_polyline_without_a_leg_gives_a_finite_pose() -> void:
	var cases: Array[PackedVector2Array] = [PackedVector2Array(), PackedVector2Array([Vector2(5, 6)]), PackedVector2Array([Vector2(5, 6), Vector2(5, 6)]), PackedVector2Array([Vector2(1, 1), Vector2(NAN, 0), Vector2(3, 3)])]
	for polyline: PackedVector2Array in cases:
		var path: CaravanPath = CaravanPath.new(polyline)
		var pose: CaravanPath.Pose = _pose(path, 0.5, true, LATERAL_M)
		assert_eq(path.length_m(), 0.0, "sem trecho, sem comprimento")
		assert_true(pose.position.is_finite() and is_finite(pose.yaw), "pose finita (%s)" % [polyline])
	assert_eq(_pose(CaravanPath.new(cases[1]), 0.5).position, Vector2(5, 6), "um ponto só: fica nele")


func test_through_joins_the_two_ends_with_the_waypoints() -> void:
	var straight: CaravanPath = CaravanPath.through(Vector2(0, 0), PackedVector2Array(), Vector2(30, 40))
	assert_almost_eq(straight.length_m(), 50.0, EPS, "sem pontos de passagem: a reta (3-4-5)")
	var bent: CaravanPath = CaravanPath.through(Vector2(0, 0), PackedVector2Array([Vector2(30, 0)]), Vector2(30, 40))
	assert_almost_eq(bent.length_m(), 70.0, EPS, "30 + 40 m")
	_near(_pose(bent, 30.0 / 70.0).position, Vector2(30, 0), "passa pelo ponto de passagem")
