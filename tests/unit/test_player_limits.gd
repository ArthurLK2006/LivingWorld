extends GutTest
## LW-047: limites do jogador (inclinação máxima caminhável, borda do mundo e recuperação abaixo do terreno) com terrenos SINTÉTICOS
## montados aqui dentro (nenhum arquivo de dados é lido ou mudado). O motor avança a física em tempo real; para os cenários de alguns
## segundos não levarem esse tempo, o teste acelera o relógio do motor como o test_player_body (time_scale e physics_ticks_per_second
## na mesma proporção, o que mantém o passo de física em 1/60 s) e restaura ao fim. Valores esperados escritos à mão: inclinação
## máxima de 40° (encostas de 30° e 39° sobem, de 41° e 50° bloqueiam), margem de 1 m até a borda, recuperação abaixo de 2 m.

const CELL_CM: int = 200
const CHUNK_CELLS: int = 8
const SURFACE_CODE: int = 5
## Mundo plano RETANGULAR (para o teste enxergar x e z trocados): 32 x 24 células de 2 m (64 x 48 m), chão a 10 m, nascimento no centro.
const WORLD_CELLS: Vector2i = Vector2i(32, 24)
const FLAT_HEIGHT_CM: int = 1000
const FLAT_GROUND_M: float = 10.0
const FLAT_CENTER_M: Vector2 = Vector2(32.0, 24.0)
## Mundo com rampa: a mesma grade; plano até a coluna 6 de nós (x = 12 m) e daí em diante o chão sobe em linha reta, para o leste.
const RAMP_FLAT_NODES: int = 6
const RAMP_SPAWN_M: Vector2 = Vector2(6.0, 24.0)
const DESCENT_SPAWN_M: Vector2 = Vector2(40.0, 24.0)
## [inclinação em graus, o corpo consegue subir?]
const SLOPE_CASES: Array[Array] = [[30.0, true], [39.0, true], [41.0, false], [50.0, false]]
const DESCENT_DEGREES: Array[float] = [35.0, 39.0]
## Subindo, a velocidade na encosta cai (cerca de v x cos(a) x sin(a) na vertical: 2,5 s a 39° dariam até 4,9 m; medido: 3,1 m).
## O que interessa é o contraste com o bloqueio (no máximo 1 m).
const CLIMB_MIN_M: float = 2.0
const BLOCKED_MAX_M: float = 1.0
const SLOPE_SECONDS: int = 4
const DESCENT_SECONDS: int = 3
## Apoiada numa encosta de a graus, a cápsula (raio 0,4 m) tem a origem r x (1/cos(a) - 1) acima do chão sob ela: 8,8 cm a 35°.
const CAPSULE_RADIUS_M: float = 0.4
const DESCENT_EXCESS_MAX_M: float = 0.03
const DESCENT_ON_FLOOR_MIN: float = 0.95
## [giro da referência em graus, posição inicial (x, z), eixo (0 = x, 1 = z), valor esperado na borda]
const BORDER_CASES: Array[Array] = [[-90.0, Vector2(60.0, 24.0), 0, 63.0], [90.0, Vector2(4.0, 24.0), 0, 1.0], [0.0, Vector2(32.0, 4.0), 1, 1.0], [180.0, Vector2(32.0, 44.0), 1, 47.0]]
const BORDER_SECONDS: int = 3
const BORDER_TOLERANCE_M: float = 0.001
const SLIDE_TOLERANCE_M: float = 0.05
const CORNER_START_M: Vector2 = Vector2(50.0, 14.0)
const CORNER_YAW_DEGREES: float = -45.0
const CORNER_SECONDS: int = 6
const CORNER_EXPECTED_M: Vector2 = Vector2(63.0, 1.0)
const BELOW_FAR_M: float = 5.0
const BELOW_NEAR_M: float = 1.9
const HEIGHT_TOLERANCE_M: float = 0.02
const SPAWN_CLEARANCE_M: float = 0.05
const RECOVERY_FRAMES: int = 90
const MAX_SLOPE_DEGREES: float = 40.0
const ANGLE_TOLERANCE_RAD: float = 0.00001
const FRAMES_PER_SECOND: int = 60
const HUGE_BUDGET_MS: float = 1.0e9
const SETTLE_MIN_FRAMES: int = 4
const SETTLE_MAX_FRAMES: int = 180
const ACCELERATION: float = 10.0
const HOST_PATH: String = "/root/SimulationHost"
const SPEED_CHANGE_FRAMES: int = 3
const EAST_YAW_DEGREES: float = -90.0
const WEST_YAW_DEGREES: float = 90.0

var _reference: Node3D
var _host: Node
var _original_scale: float = 1.0
var _original_ticks: int = 60


## Ponte de teste que falha sob pedido, para os casos de erro (altura ou formato do terreno indisponíveis).
class FailingBridge:
	extends SimBridge

	var fail_heights: bool = false
	var fail_layout: bool = false

	func _init(terrain: TerrainData) -> void:
		super(null, terrain)

	func peek_height(x: float, z: float) -> SimBridge.HeightReply:
		if fail_heights:
			return SimBridge.HeightReply.new(Result.failure("TEST_HEIGHT", "altura de teste indisponível"), 0.0)
		return super(x, z)

	func peek_terrain_layout() -> SimBridge.TerrainLayoutReply:
		if fail_layout:
			return SimBridge.TerrainLayoutReply.new(Result.failure("TEST_LAYOUT", "formato de teste indisponível"), null)
		return super()


func before_all() -> void:
	# Trocar a velocidade do motor dá um quadro com delta negativo, que o relógio da simulação (SimulationHost) recusa com erro;
	# ele não é usado aqui, então fica sem processar enquanto a velocidade muda.
	_host = get_node_or_null(HOST_PATH)
	if _host != null:
		_host.set_process(false)
	_original_scale = Engine.time_scale
	_original_ticks = Engine.physics_ticks_per_second
	Engine.time_scale = ACCELERATION
	Engine.physics_ticks_per_second = int(float(_original_ticks) * ACCELERATION)
	for _frame: int in range(SPEED_CHANGE_FRAMES):
		await get_tree().process_frame
	_reference = Node3D.new()
	add_child(_reference)


func after_all() -> void:
	Engine.time_scale = _original_scale
	Engine.physics_ticks_per_second = _original_ticks
	for _frame: int in range(SPEED_CHANGE_FRAMES):
		await get_tree().process_frame
	if _host != null:
		_host.set_process(true)
	_reference.free()


func after_each() -> void:
	for action: StringName in InputActions.ALL:
		Input.action_release(action)
	_reference.rotation_degrees = Vector3(0.0, EAST_YAW_DEGREES, 0.0)


## Terreno sintético retangular: `height_cm` dá a altura (cm) de cada nó (x, z); o nascimento fica em `spawn_m` (x, z).
func _make_terrain(height_cm: Callable, spawn_m: Vector2) -> TerrainData:
	var nodes_x: int = WORLD_CELLS.x + 1
	var nodes_z: int = WORLD_CELLS.y + 1
	var heights: PackedInt64Array = PackedInt64Array()
	heights.resize(nodes_x * nodes_z)
	for node_z: int in range(nodes_z):
		for node_x: int in range(nodes_x):
			heights[node_z * nodes_x + node_x] = height_cm.call(node_x, node_z)
	var surfaces: PackedInt64Array = PackedInt64Array()
	surfaces.resize(WORLD_CELLS.x * WORLD_CELLS.y)
	surfaces.fill(SURFACE_CODE)
	var ids: Dictionary[int, String] = {SURFACE_CODE: "grass"}
	var spawn_cm: Vector2i = Vector2i(roundi(spawn_m.x * 100.0), roundi(spawn_m.y * 100.0))
	return TerrainData.new(WORLD_CELLS, CELL_CM, CHUNK_CELLS, heights, surfaces, ids, spawn_cm)


func _flat_terrain() -> TerrainData:
	return _make_terrain(func(_node_x: int, _node_z: int) -> int: return FLAT_HEIGHT_CM, FLAT_CENTER_M)


## Rampa de `degrees` graus (altura que cresce em linha reta com x a partir da coluna RAMP_FLAT_NODES).
func _ramp_terrain(degrees: float, spawn_m: Vector2) -> TerrainData:
	var rise_cm: int = roundi(tan(deg_to_rad(degrees)) * float(CELL_CM))
	return _make_terrain(func(node_x: int, _node_z: int) -> int: return maxi(node_x - RAMP_FLAT_NODES, 0) * rise_cm, spawn_m)


func _new_view(bridge: SimBridge, spawn_m: Vector2) -> TerrainView:
	var view: TerrainView = TerrainView.new()
	add_child(view)
	view.setup(bridge)
	view.set_focus(Vector3(spawn_m.x, 0.0, spawn_m.y))
	view.process_budget(HUGE_BUDGET_MS)
	return view


func _new_body(bridge: SimBridge, view: TerrainView) -> PlayerBody:
	var body: PlayerBody = PlayerBody.new()
	add_child(body)
	assert_true(body.setup(bridge, view, _reference))
	return body


func _frames(count: int) -> void:
	for _frame: int in range(count):
		await get_tree().physics_frame


func _settle(body: PlayerBody) -> void:
	await _frames(SETTLE_MIN_FRAMES)
	for _frame: int in range(SETTLE_MAX_FRAMES):
		if body.is_on_floor():
			return
		await get_tree().physics_frame
	fail_test("O corpo não assentou no chão em %d quadros." % SETTLE_MAX_FRAMES)


func _hold(actions: Array[StringName], frames: int) -> void:
	for action: StringName in actions:
		Input.action_press(action)
	await _frames(frames)
	for action: StringName in actions:
		Input.action_release(action)


func _teleport(body: PlayerBody, point: Vector3) -> void:
	body.global_position = point
	body.velocity = Vector3.ZERO
	await _settle(body)


func _ground_at(bridge: SimBridge, x: float, z: float) -> float:
	return bridge.peek_height(x, z).height_m


func test_the_limits_are_the_agreed_hypotheses() -> void:
	var body: PlayerBody = PlayerBody.new()
	add_child_autofree(body)
	assert_almost_eq(body.floor_max_angle, deg_to_rad(MAX_SLOPE_DEGREES), ANGLE_TOLERANCE_RAD, "Inclinação máxima caminhável: 40°.")
	assert_eq(PlayerBody.MAX_WALKABLE_SLOPE_DEGREES, 40.0)
	assert_eq(PlayerBody.BORDER_MARGIN_M, 1.0, "Margem de 1 m até a borda.")
	assert_eq(PlayerBody.RECOVERY_DEPTH_M, 2.0, "Recuperação abaixo de 2 m do terreno.")


func test_a_slope_below_the_limit_is_climbed_and_one_above_it_blocks_the_body() -> void:
	for slope_case: Array in SLOPE_CASES:
		var degrees: float = slope_case[0]
		var bridge: SimBridge = SimBridge.new(null, _ramp_terrain(degrees, RAMP_SPAWN_M))
		var view: TerrainView = _new_view(bridge, RAMP_SPAWN_M)
		var body: PlayerBody = _new_body(bridge, view)
		await _settle(body)
		var start_y: float = body.global_position.y
		await _hold([InputActions.MOVE_FORWARD], SLOPE_SECONDS * FRAMES_PER_SECOND)
		var gain_m: float = body.global_position.y - start_y
		if slope_case[1]:
			assert_gt(gain_m, CLIMB_MIN_M, "Encosta de %s°: o corpo devia subir e subiu só %s m." % [str(degrees), str(gain_m)])
		else:
			assert_lt(gain_m, BLOCKED_MAX_M, "Encosta de %s°: o corpo devia ser bloqueado e subiu %s m." % [str(degrees), str(gain_m)])
		body.free()
		view.free()


func test_running_down_a_steep_slope_keeps_the_body_on_the_ground() -> void:
	for degrees: float in DESCENT_DEGREES:
		var bridge: SimBridge = SimBridge.new(null, _ramp_terrain(degrees, DESCENT_SPAWN_M))
		var view: TerrainView = _new_view(bridge, DESCENT_SPAWN_M)
		var body: PlayerBody = _new_body(bridge, view)
		await _settle(body)
		_reference.rotation_degrees = Vector3(0.0, WEST_YAW_DEGREES, 0.0) # para o oeste: ladeira abaixo
		var start_x: float = body.global_position.x
		var resting_gap_m: float = CAPSULE_RADIUS_M * (1.0 / cos(deg_to_rad(degrees)) - 1.0)
		var worst_excess_m: float = 0.0
		var frames_on_floor: int = 0
		var frames: int = DESCENT_SECONDS * FRAMES_PER_SECOND
		Input.action_press(InputActions.MOVE_FORWARD)
		Input.action_press(InputActions.RUN)
		for _frame: int in range(frames):
			await get_tree().physics_frame
			var gap_m: float = body.global_position.y - _ground_at(bridge, body.global_position.x, body.global_position.z)
			worst_excess_m = maxf(worst_excess_m, gap_m - resting_gap_m)
			frames_on_floor += 1 if body.is_on_floor() else 0
		assert_lt(body.global_position.x, start_x - 10.0, "A %s° o corpo desceu a ladeira (o teste não é vazio)." % str(degrees))
		assert_lte(worst_excess_m, DESCENT_EXCESS_MAX_M, "Descendo a %s° correndo, o corpo chegou a %s m acima do esperado para apoiado." % [str(degrees), str(worst_excess_m)])
		assert_gte(float(frames_on_floor) / float(frames), DESCENT_ON_FLOOR_MIN, "Descendo a %s° o corpo ficou no ar em muitos quadros (%d de %d no chão)." % [str(degrees), frames_on_floor, frames])
		body.free()
		view.free()


func test_the_body_cannot_leave_the_map_through_any_of_the_four_sides() -> void:
	var bridge: SimBridge = SimBridge.new(null, _flat_terrain())
	var view: TerrainView = _new_view(bridge, FLAT_CENTER_M)
	var body: PlayerBody = _new_body(bridge, view)
	await _settle(body)
	for border_case: Array in BORDER_CASES:
		var start: Vector2 = border_case[1]
		var axis: int = border_case[2]
		_reference.rotation_degrees = Vector3(0.0, border_case[0], 0.0)
		await _teleport(body, Vector3(start.x, FLAT_GROUND_M + SPAWN_CLEARANCE_M, start.y))
		await _hold([InputActions.MOVE_FORWARD], BORDER_SECONDS * FRAMES_PER_SECOND)
		var position: Vector3 = body.global_position
		var along: float = position.x if axis == 0 else position.z
		var across: float = position.z if axis == 0 else position.x
		var across_start: float = start.y if axis == 0 else start.x
		assert_almost_eq(along, float(border_case[3]), BORDER_TOLERANCE_M, "O corpo parou a %s m (esperado %s) com a referência girada %s°." % [str(along), str(border_case[3]), str(border_case[0])])
		assert_almost_eq(across, across_start, SLIDE_TOLERANCE_M, "Sem desvio de lado.")
		assert_almost_eq(position.y, FLAT_GROUND_M, HEIGHT_TOLERANCE_M, "E ainda está no chão, não caiu pela borda.")
	body.free()
	view.free()


func test_the_body_slides_into_a_corner_and_stops_one_meter_from_both_borders() -> void:
	var bridge: SimBridge = SimBridge.new(null, _flat_terrain())
	var view: TerrainView = _new_view(bridge, FLAT_CENTER_M)
	var body: PlayerBody = _new_body(bridge, view)
	await _settle(body)
	_reference.rotation_degrees = Vector3(0.0, CORNER_YAW_DEGREES, 0.0) # para o nordeste: x cresce e z diminui
	await _teleport(body, Vector3(CORNER_START_M.x, FLAT_GROUND_M + SPAWN_CLEARANCE_M, CORNER_START_M.y))
	await _hold([InputActions.MOVE_FORWARD], CORNER_SECONDS * FRAMES_PER_SECOND)
	assert_almost_eq(body.global_position.x, CORNER_EXPECTED_M.x, BORDER_TOLERANCE_M)
	assert_almost_eq(body.global_position.z, CORNER_EXPECTED_M.y, BORDER_TOLERANCE_M)
	assert_almost_eq(body.global_position.y, FLAT_GROUND_M, HEIGHT_TOLERANCE_M)
	body.free()
	view.free()


func test_a_body_forced_far_below_the_terrain_is_put_back_on_the_ground_with_a_warning() -> void:
	var bridge: SimBridge = SimBridge.new(null, _flat_terrain())
	var view: TerrainView = _new_view(bridge, FLAT_CENTER_M)
	var body: PlayerBody = _new_body(bridge, view)
	await _settle(body)
	body.global_position = Vector3(20.0, FLAT_GROUND_M - BELOW_FAR_M, 40.0)
	await _frames(RECOVERY_FRAMES)
	assert_push_warning("abaixo do terreno")
	assert_almost_eq(body.global_position.x, 20.0, SLIDE_TOLERANCE_M, "Volta no mesmo x.")
	assert_almost_eq(body.global_position.z, 40.0, SLIDE_TOLERANCE_M, "Volta no mesmo z.")
	assert_almost_eq(body.global_position.y, FLAT_GROUND_M, HEIGHT_TOLERANCE_M, "E sobre o chão.")
	assert_true(body.is_on_floor())
	body.free()
	view.free()


func test_a_body_less_than_two_meters_below_the_terrain_is_not_moved_at_once() -> void:
	var bridge: SimBridge = SimBridge.new(null, _flat_terrain())
	var view: TerrainView = _new_view(bridge, FLAT_CENTER_M)
	var body: PlayerBody = _new_body(bridge, view)
	await _settle(body)
	body.global_position = Vector3(20.0, FLAT_GROUND_M - BELOW_NEAR_M, 40.0)
	await _frames(2)
	assert_lt(body.global_position.y, FLAT_GROUND_M - 1.0, "A 1,9 m abaixo ainda não é posto de volta (limite de 2 m).")
	await _frames(RECOVERY_FRAMES)
	assert_push_warning("abaixo do terreno")
	assert_almost_eq(body.global_position.y, FLAT_GROUND_M, HEIGHT_TOLERANCE_M, "Passou dos 2 m caindo e foi posto de volta.")
	body.free()
	view.free()


func test_when_the_terrain_height_cannot_be_read_the_body_goes_back_to_the_spawn_point() -> void:
	var bridge: FailingBridge = FailingBridge.new(_flat_terrain())
	var view: TerrainView = _new_view(bridge, FLAT_CENTER_M)
	var body: PlayerBody = _new_body(bridge, view)
	await _settle(body)
	body.global_position = Vector3(20.0, FLAT_GROUND_M + SPAWN_CLEARANCE_M, 40.0)
	bridge.fail_heights = true
	await _frames(4)
	assert_push_warning("indisponível")
	assert_almost_eq(body.global_position.x, FLAT_CENTER_M.x, SLIDE_TOLERANCE_M, "Voltou ao ponto de nascimento (x).")
	assert_almost_eq(body.global_position.z, FLAT_CENTER_M.y, SLIDE_TOLERANCE_M, "Voltou ao ponto de nascimento (z).")
	bridge.fail_heights = false
	body.free()
	view.free()


func test_a_bridge_that_cannot_give_the_terrain_layout_reports_the_error_and_the_body_does_not_spawn() -> void:
	var bridge: FailingBridge = FailingBridge.new(_flat_terrain())
	var view: TerrainView = _new_view(bridge, FLAT_CENTER_M)
	bridge.fail_layout = true
	var body: PlayerBody = PlayerBody.new()
	add_child_autofree(body)
	assert_false(body.setup(bridge, view, _reference))
	assert_push_error("formato do terreno indisponível")
	assert_false(body.is_spawned())
	assert_false(body.visible)
	assert_false(body.setup(SimBridge.new(null, null), view, _reference))
	assert_push_error("ponto de nascimento indisponível")
	assert_false(body.is_spawned())
	view.free()
