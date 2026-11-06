extends GutTest
## LW-045: PlayerBody sobre o terreno de blockout real, com a ponte real, sem janela. O motor avança a física em tempo real (60
## quadros por segundo): para um cenário de 5 s não levar 5 s, o teste acelera o relógio do motor com Engine.time_scale e
## physics_ticks_per_second na MESMA proporção, o que mantém cada passo de física em 1/60 s (medido em 06/11/2026: 300 quadros em
## 0,49 s com fator 10, todos com delta 0,01667). O fator volta ao normal no fim. Os valores esperados estão ESCRITOS À MÃO a partir
## das hipóteses do envio: andar 4 m/s, correr 7 m/s, pulo de 5 m/s e gravidade 9,8 m/s² (pico 1,28 m, voo de cerca de 1 s).

const BLOCKOUT_DIR: String = "res://data/world"
const ACCELERATION: float = 10.0
const FRAMES_PER_SECOND: int = 60
const HUGE_BUDGET_MS: float = 1.0e9
const SETTLE_MIN_FRAMES: int = 4
const SETTLE_MAX_FRAMES: int = 120
const WALK_5S_M: float = 20.0
const RUN_5S_M: float = 35.0
const WALK_1S_M: float = 4.0
const DISTANCE_TOLERANCE_M: float = 0.3
const DIRECTION_TOLERANCE_M: float = 0.2
const HEIGHT_TOLERANCE_M: float = 0.01
const JUMP_PEAK_MIN_M: float = 1.18
const JUMP_PEAK_MAX_M: float = 1.38
const JUMP_AIR_FRAMES_MIN: int = 55
const JUMP_AIR_FRAMES_MAX: int = 75
const JUMP_WATCH_FRAMES: int = 90
const HELD_JUMP_FRAMES: int = 200
const REPEAT_JUMP_LIMIT_M: float = 0.05
## Encosta oeste da colina (inclinação de até 16°, medida): o jogador sobe para o leste.
const SLOPE_START: Vector2 = Vector2(570.0, 300.0)
const SLOPE_FRAMES: int = 180
const SLOPE_MIN_CLIMB_M: float = 2.0
const SINK_LIMIT_M: float = 0.02
const FLOAT_LIMIT_M: float = 0.08
const EAST_YAW_DEGREES: float = -90.0
const STILL_FRAMES: int = 120
const STILL_TOLERANCE_M: float = 0.001
const GRAVITY_MPS2: float = 9.8
const CAPSULE_RADIUS_M: float = 0.4
const CAPSULE_HEIGHT_M: float = 1.8
const SPAWN_CLEARANCE_M: float = 0.05
const NORMAL_SCALE: float = 1.0
const FLOAT_TOLERANCE: float = 0.000001
const HOST_PATH: String = "/root/SimulationHost"
## Quadros de processo esperados depois de trocar a velocidade do motor, antes de religar o SimulationHost.
const SPEED_CHANGE_FRAMES: int = 3
const NORMAL_TICKS: int = 60

var _bridge: SimBridge
var _view: TerrainView
var _reference: Node3D
var _original_scale: float = NORMAL_SCALE
var _original_ticks: int = NORMAL_TICKS
var _host: Node


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
	var loaded: TerrainLoader.LoadResult = TerrainLoader.load_dir(BLOCKOUT_DIR)
	assert_true(loaded.result.ok, loaded.result.message)
	_bridge = SimBridge.new(null, loaded.terrain)
	_reference = Node3D.new()
	add_child(_reference)
	var spawn: Vector3 = _bridge.peek_spawn_point().point
	_view = _new_terrain_view(Vector2(spawn.x, spawn.z))


func after_all() -> void:
	Engine.time_scale = _original_scale
	Engine.physics_ticks_per_second = _original_ticks
	for _frame: int in range(SPEED_CHANGE_FRAMES):
		await get_tree().process_frame
	if _host != null:
		_host.set_process(true)
	_view.free()
	_reference.free()


func after_each() -> void:
	for action: StringName in InputActions.ALL:
		Input.action_release(action)
	_reference.rotation_degrees = Vector3(0.0, EAST_YAW_DEGREES, 0.0)


func _new_terrain_view(focus: Vector2) -> TerrainView:
	var view: TerrainView = TerrainView.new()
	add_child(view)
	view.setup(_bridge)
	view.set_focus(Vector3(focus.x, 0.0, focus.y))
	view.process_budget(HUGE_BUDGET_MS)
	return view


func _new_body(view: TerrainView) -> PlayerBody:
	var body: PlayerBody = PlayerBody.new()
	add_child_autofree(body)
	assert_true(body.setup(_bridge, view, _reference))
	return body


func _frames(count: int) -> void:
	for _frame: int in range(count):
		await get_tree().physics_frame


## Espera o corpo assentar no chão (ao menos alguns quadros, para o estado de antes de um teletransporte não valer).
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


func _ground_at(point: Vector3) -> float:
	return _bridge.peek_height(point.x, point.z).height_m


func test_the_body_spawns_as_a_visible_capsule_with_the_agreed_size_layers_and_origin_at_the_feet() -> void:
	var spawn: Vector3 = _bridge.peek_spawn_point().point
	var body: PlayerBody = _new_body(_view)
	assert_true(body.is_spawned())
	assert_true(body.visible)
	assert_eq(body.global_position, spawn + Vector3(0.0, SPAWN_CLEARANCE_M, 0.0), "Nasce no ponto de nascimento, 5 cm acima do chão.")
	var visual: MeshInstance3D = body.get_node("Capsule") as MeshInstance3D
	var capsule: CapsuleMesh = visual.mesh as CapsuleMesh
	assert_almost_eq(capsule.radius, CAPSULE_RADIUS_M, FLOAT_TOLERANCE)
	assert_almost_eq(capsule.height, CAPSULE_HEIGHT_M, FLOAT_TOLERANCE)
	assert_almost_eq(visual.position.y, CAPSULE_HEIGHT_M / 2.0, 0.000001, "A origem do corpo fica nos pés.")
	var material: StandardMaterial3D = capsule.material as StandardMaterial3D
	assert_eq(material.albedo_color, Color(0.95, 0.45, 0.10), "Laranja, diferente do verde do terreno.")
	var shape: CapsuleShape3D = (body.get_node("Shape") as CollisionShape3D).shape as CapsuleShape3D
	assert_almost_eq(shape.radius, CAPSULE_RADIUS_M, FLOAT_TOLERANCE)
	assert_almost_eq(shape.height, CAPSULE_HEIGHT_M, FLOAT_TOLERANCE)
	assert_eq(body.collision_layer, 2, "Camada 2.")
	assert_eq(body.collision_mask, 1, "Só enxerga a camada 1, a do terreno.")
	assert_eq(ProjectSettings.get_setting("physics/3d/default_gravity"), GRAVITY_MPS2, "A gravidade esperada nos testes é a do projeto.")


func test_walking_forward_for_five_seconds_covers_the_walk_speed_times_the_time() -> void:
	var body: PlayerBody = _new_body(_view)
	await _settle(body)
	var start: Vector3 = body.global_position
	await _hold([InputActions.MOVE_FORWARD], 5 * FRAMES_PER_SECOND)
	var moved: Vector3 = body.global_position - start
	assert_almost_eq(moved.x, WALK_5S_M, DISTANCE_TOLERANCE_M, "Andou %s m para o leste em 5 s." % str(moved.x))
	assert_almost_eq(moved.z, 0.0, DISTANCE_TOLERANCE_M)


func test_running_covers_more_than_walking() -> void:
	var body: PlayerBody = _new_body(_view)
	await _settle(body)
	var start: Vector3 = body.global_position
	await _hold([InputActions.MOVE_FORWARD], 5 * FRAMES_PER_SECOND)
	var walked: float = (body.global_position - start).length()
	await _teleport(body, start)
	await _hold([InputActions.MOVE_FORWARD, InputActions.RUN], 5 * FRAMES_PER_SECOND)
	var ran: float = (body.global_position - start).length()
	assert_almost_eq(ran, RUN_5S_M, DISTANCE_TOLERANCE_M, "Correu %s m em 5 s." % str(ran))
	assert_gt(ran, walked * 1.5, "Correr cobre bem mais que andar.")


func test_the_body_does_not_sink_into_the_flat_ground_while_standing_and_walking() -> void:
	var body: PlayerBody = _new_body(_view)
	await _settle(body)
	assert_almost_eq(body.global_position.y, _ground_at(body.global_position), HEIGHT_TOLERANCE_M, "Parado, os pés ficam na altura do terreno.")
	var worst_gap: float = 0.0
	Input.action_press(InputActions.MOVE_FORWARD)
	for _frame: int in range(3 * FRAMES_PER_SECOND):
		await get_tree().physics_frame
		worst_gap = maxf(worst_gap, absf(body.global_position.y - _ground_at(body.global_position)))
	assert_lte(worst_gap, HEIGHT_TOLERANCE_M, "A maior diferença para a altura do terreno ao andar foi %s m." % str(worst_gap))


func test_the_body_follows_a_slope_without_sinking_or_floating() -> void:
	var view: TerrainView = _new_terrain_view(SLOPE_START)
	var body: PlayerBody = _new_body(view)
	var start: Vector3 = Vector3(SLOPE_START.x, 0.0, SLOPE_START.y)
	start.y = _ground_at(start)
	await _teleport(body, start + Vector3(0.0, SPAWN_CLEARANCE_M, 0.0))
	var lowest_gap: float = INF
	var highest_gap: float = -INF
	Input.action_press(InputActions.MOVE_FORWARD)
	for _frame: int in range(SLOPE_FRAMES):
		await get_tree().physics_frame
		var gap: float = body.global_position.y - _ground_at(body.global_position)
		lowest_gap = minf(lowest_gap, gap)
		highest_gap = maxf(highest_gap, gap)
	Input.action_release(InputActions.MOVE_FORWARD)
	assert_gte(lowest_gap, -SINK_LIMIT_M, "Afundou %s m na encosta." % str(lowest_gap))
	assert_lte(highest_gap, FLOAT_LIMIT_M, "Flutuou %s m acima da encosta." % str(highest_gap))
	assert_gt(body.global_position.y - start.y, SLOPE_MIN_CLIMB_M, "Subiu a encosta (o teste não é vazio).")
	view.free()


func test_jumping_goes_up_and_comes_back_to_the_ground() -> void:
	var body: PlayerBody = _new_body(_view)
	await _settle(body)
	var ground_y: float = body.global_position.y
	var peak_m: float = 0.0
	var air_frames: int = 0
	Input.action_press(InputActions.JUMP)
	await get_tree().physics_frame
	Input.action_release(InputActions.JUMP)
	for _frame: int in range(JUMP_WATCH_FRAMES):
		await get_tree().physics_frame
		peak_m = maxf(peak_m, body.global_position.y - ground_y)
		air_frames += 0 if body.is_on_floor() else 1
	assert_between(peak_m, JUMP_PEAK_MIN_M, JUMP_PEAK_MAX_M, "Pico do pulo: %s m." % str(peak_m))
	assert_between(air_frames, JUMP_AIR_FRAMES_MIN, JUMP_AIR_FRAMES_MAX, "Quadros no ar: %d." % air_frames)
	assert_true(body.is_on_floor(), "Voltou ao chão.")
	assert_almost_eq(body.global_position.y, ground_y, HEIGHT_TOLERANCE_M)


func test_holding_the_jump_key_jumps_only_once() -> void:
	var body: PlayerBody = _new_body(_view)
	await _settle(body)
	var ground_y: float = body.global_position.y
	var later_peak_m: float = 0.0
	Input.action_press(InputActions.JUMP)
	for frame: int in range(HELD_JUMP_FRAMES):
		await get_tree().physics_frame
		if frame > JUMP_WATCH_FRAMES:
			later_peak_m = maxf(later_peak_m, body.global_position.y - ground_y)
	assert_lte(later_peak_m, REPEAT_JUMP_LIMIT_M, "Segurar a tecla não repete o pulo ao pousar.")
	assert_true(body.is_on_floor())


func test_the_direction_is_relative_to_the_yaw_of_the_reference_node() -> void:
	var body: PlayerBody = _new_body(_view)
	await _settle(body)
	# [giro da referência em graus, deslocamento esperado (x, z) em 1 s andando para a frente]
	var table: Array[Array] = [[-90.0, Vector2(WALK_1S_M, 0.0)], [0.0, Vector2(0.0, -WALK_1S_M)], [90.0, Vector2(-WALK_1S_M, 0.0)], [180.0, Vector2(0.0, WALK_1S_M)]]
	for row: Array in table:
		_reference.rotation_degrees = Vector3(0.0, row[0], 0.0)
		var start: Vector3 = body.global_position
		await _hold([InputActions.MOVE_FORWARD], FRAMES_PER_SECOND)
		var moved: Vector3 = body.global_position - start
		var expected: Vector2 = row[1]
		assert_almost_eq(moved.x, expected.x, DIRECTION_TOLERANCE_M, "x com a referência girada %s°." % str(row[0]))
		assert_almost_eq(moved.z, expected.y, DIRECTION_TOLERANCE_M, "z com a referência girada %s°." % str(row[0]))
		await _teleport(body, start)


func test_walking_diagonally_is_not_faster_than_walking_straight() -> void:
	var body: PlayerBody = _new_body(_view)
	await _settle(body)
	var start: Vector3 = body.global_position
	await _hold([InputActions.MOVE_FORWARD, InputActions.MOVE_RIGHT], FRAMES_PER_SECOND)
	var moved: Vector3 = body.global_position - start
	assert_almost_eq(moved.length(), WALK_1S_M, DIRECTION_TOLERANCE_M, "Na diagonal, 4 m em 1 s (e não 5,66 m).")
	assert_gt(moved.x, 1.0, "Para a frente (leste) e para a direita (sul)...")
	assert_gt(moved.z, 1.0)


func test_without_input_the_body_stays_still_on_the_ground() -> void:
	var body: PlayerBody = _new_body(_view)
	await _settle(body)
	var start: Vector3 = body.global_position
	await _frames(STILL_FRAMES)
	assert_lte((body.global_position - start).length(), STILL_TOLERANCE_M, "Sem teclas, não se mexe.")
	assert_lte(body.velocity.length(), STILL_TOLERANCE_M)


func test_without_ground_collision_the_body_stays_still_and_moves_once_the_ground_exists() -> void:
	var view: TerrainView = TerrainView.new()
	add_child_autofree(view)
	view.setup(_bridge)
	view.set_process(false)
	var body: PlayerBody = _new_body(view)
	var spawn: Vector3 = body.global_position
	await _hold([InputActions.MOVE_FORWARD], FRAMES_PER_SECOND)
	assert_eq(body.global_position, spawn, "Sem colisão sob o corpo ele não cai nem anda.")
	assert_eq(body.velocity, Vector3.ZERO)
	view.set_focus(Vector3(spawn.x, 0.0, spawn.z))
	view.process_budget(HUGE_BUDGET_MS)
	await _hold([InputActions.MOVE_FORWARD], FRAMES_PER_SECOND)
	assert_almost_eq(body.global_position.x - spawn.x, WALK_1S_M, 0.5, "Com o chão pronto, o corpo anda.")
	assert_almost_eq(body.global_position.y, _ground_at(body.global_position), HEIGHT_TOLERANCE_M)


func test_setup_with_a_missing_piece_reports_the_error_and_the_body_does_not_spawn() -> void:
	var body: PlayerBody = PlayerBody.new()
	add_child_autofree(body)
	assert_false(body.setup(null, _view, _reference))
	assert_push_error("ponte nula")
	assert_false(body.is_spawned())
	assert_false(body.visible)
	assert_false(body.is_physics_processing())
	assert_false(body.setup(SimBridge.new(null, null), _view, _reference))
	assert_push_error("ponto de nascimento indisponível")
	assert_false(body.is_spawned())
	assert_false(body.setup(_bridge, null, _reference))
	assert_push_error("nulo")
	assert_false(body.setup(_bridge, _view, null))
	assert_push_error("nulo")
	assert_false(body.is_spawned())
	var outside: PlayerBody = PlayerBody.new()
	assert_false(outside.setup(_bridge, _view, _reference))
	assert_push_error("árvore")
	outside.free()


func test_the_main_scene_has_one_player_body_that_spawns_and_gives_the_terrain_its_focus() -> void:
	var scene: Node = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	add_child_autofree(scene)
	var players: Array[Node] = scene.find_children("*", "PlayerBody", true, false)
	assert_eq(players.size(), 1, "A cena principal tem exatamente um PlayerBody.")
	var player: PlayerBody = players[0] as PlayerBody
	assert_true(player.is_spawned(), "Ele nasce quando a cena fica pronta.")
	var spawn: Vector3 = _bridge.peek_spawn_point().point
	assert_eq(player.global_position, spawn + Vector3(0.0, SPAWN_CLEARANCE_M, 0.0))
	var terrain: TerrainView = scene.get_node("TerrainView") as TerrainView
	assert_eq(terrain.focus(), Vector2(spawn.x, spawn.z), "O foco do terreno é a posição do jogador.")
