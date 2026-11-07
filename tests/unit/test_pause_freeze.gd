extends GutTest
## LW-051 (decisão D1 de Arthur, 06/11/2026): a PAUSA CONGELA O PERSONAGEM. Com o relógio da simulação pausado o PlayerBody não anda, não
## pula, não cai, não relata posição e a interação não é enviada; a câmera continua girando e dando zoom (é apresentação); ao despausar tudo
## volta de onde parou, sem salto de posição. Terreno de blockout e mundo do jogo reais, relógio do motor acelerado como em
## tests/unit/test_player_body.gd (PhysicsBoost). Valores esperados escritos à mão: andar 4 m/s, correr 7 m/s, 60 quadros de física por segundo.

const BLOCKOUT_DIR: String = "res://data/world"
const WORLD_SEED: int = 3
const FRAMES_PER_SECOND: int = 60
const PAUSED_SECONDS: int = 5
const SETTLE_FRAMES: int = 20
const HALF_SECOND_FRAMES: int = 30
const RESUME_JUMP_LIMIT_M: float = 0.15
const FROZEN_TOLERANCE_M: float = 0.0001
const NO_JUMP_RISE_M: float = 0.05
const JUMP_MIN_RISE_M: float = 0.5
const AIR_HEIGHT_M: float = 5.0
const WALK_MIN_M: float = 3.0
const REPORT_TOLERANCE_M: float = 1.0
const REPORT_FRAMES: int = 8
const EAST_YAW_DEGREES: float = -90.0
const HUGE_BUDGET_MS: float = 1.0e9
const LOOK_FRAMES: int = 30
const LOOK_MIN_RAD: float = 0.1
const SHOWN_TOLERANCE_RAD: float = 0.01

var _boost: PhysicsBoost = PhysicsBoost.new()
var _terrain: TerrainData
var _points: Array[PointOfInterest] = []
var _host: SimulationHostNode
var _bridge: SimBridge
var _view: TerrainView
var _reference: Node3D


func before_all() -> void:
	await _boost.enable(get_tree())
	var terrain_loaded: TerrainLoader.LoadResult = TerrainLoader.load_dir(BLOCKOUT_DIR)
	assert_true(terrain_loaded.result.ok, terrain_loaded.result.message)
	_terrain = terrain_loaded.terrain
	var points_loaded: PointOfInterestLoader.LoadResult = PointOfInterestLoader.load_dir(BLOCKOUT_DIR, _terrain)
	assert_true(points_loaded.result.ok, points_loaded.result.message)
	_points = points_loaded.points
	_host = SimulationHostNode.new()
	_host.start_new_game(WORLD_SEED, _terrain, _points)
	_bridge = SimBridge.new(_host, _terrain)
	_reference = Node3D.new()
	add_child(_reference)
	_view = TerrainView.new()
	add_child(_view)
	_view.setup(_bridge)
	_view.set_focus(_bridge.peek_spawn_point().point)
	_view.process_budget(HUGE_BUDGET_MS)


func after_all() -> void:
	_host.runner.finish()
	_host.free()
	_view.free()
	_reference.free()
	await _boost.restore(get_tree())


func before_each() -> void:
	_host.start_new_game(WORLD_SEED, _terrain, _points)
	_reference.rotation_degrees = Vector3(0.0, EAST_YAW_DEGREES, 0.0)


func after_each() -> void:
	for action: StringName in InputActions.ALL:
		Input.action_release(action)
	_bridge.request_pause(false)


func _new_body() -> PlayerBody:
	var body: PlayerBody = PlayerBody.new()
	add_child_autofree(body)
	assert_true(body.setup(_bridge, _view, _reference))
	return body


func _frames(count: int) -> void:
	for _frame: int in range(count):
		await get_tree().physics_frame


func _stored(body: PlayerBody) -> Vector3:
	return _bridge.peek_character(body.get_actor_id()).position


func _pause(is_paused: bool) -> void:
	assert_true(_bridge.request_pause(is_paused).ok)


func test_a_paused_body_does_not_walk_run_jump_or_report_in_five_seconds_of_input() -> void:
	var body: PlayerBody = _new_body()
	await _frames(SETTLE_FRAMES)
	var position_before: Vector3 = body.global_position
	var stored_before: Vector3 = _stored(body)
	var hash_before: String = _host.runner.world.state_hash()
	_pause(true)
	Input.action_press(InputActions.MOVE_FORWARD)
	Input.action_press(InputActions.RUN)
	Input.action_press(InputActions.JUMP)
	await _frames(PAUSED_SECONDS * FRAMES_PER_SECOND)
	assert_lte((body.global_position - position_before).length(), FROZEN_TOLERANCE_M, "Pausado, o corpo não saiu do lugar.")
	assert_eq(body.velocity, Vector3.ZERO, "Velocidade zero.")
	assert_eq(_stored(body), stored_before, "Nada foi relatado: a posição guardada na simulação não mudou.")
	assert_eq(_host.runner.world.state_hash(), hash_before, "Nem o hash do mundo.")


func test_a_body_in_the_air_stays_in_the_air_while_paused_and_falls_after_resuming() -> void:
	var body: PlayerBody = _new_body()
	await _frames(SETTLE_FRAMES)
	var ground_y: float = body.global_position.y
	body.global_position.y = ground_y + AIR_HEIGHT_M
	await _frames(2)
	_pause(true)
	await _frames(1)
	var frozen_y: float = body.global_position.y
	await _frames(FRAMES_PER_SECOND)
	assert_almost_eq(body.global_position.y, frozen_y, FROZEN_TOLERANCE_M, "Sem gravidade durante a pausa: ele não cai.")
	assert_gt(body.global_position.y, ground_y + 1.0, "Continua no ar (o teste não é vazio).")
	_pause(false)
	await _frames(FRAMES_PER_SECOND * 2)
	assert_almost_eq(body.global_position.y, ground_y, 0.1, "Despausado, a queda continua até o chão.")


func test_after_resuming_the_body_walks_and_reports_again_without_a_jump_in_position() -> void:
	var body: PlayerBody = _new_body()
	await _frames(SETTLE_FRAMES)
	_pause(true)
	await _frames(FRAMES_PER_SECOND)
	var position_paused: Vector3 = body.global_position
	_pause(false)
	await _frames(1)
	assert_lte((body.global_position - position_paused).length(), RESUME_JUMP_LIMIT_M, "Sem salto de posição ao despausar.")
	Input.action_press(InputActions.MOVE_FORWARD)
	await _frames(FRAMES_PER_SECOND)
	Input.action_release(InputActions.MOVE_FORWARD)
	await _frames(REPORT_FRAMES)
	assert_gt(body.global_position.x - position_paused.x, WALK_MIN_M, "Voltou a andar: 4 m/s por 1 s.")
	assert_lte((_stored(body) - body.global_position).length(), REPORT_TOLERANCE_M, "E a posição guardada voltou a acompanhar o corpo.")


func test_holding_the_jump_key_during_the_pause_does_not_jump_on_resume() -> void:
	var body: PlayerBody = _new_body()
	await _frames(SETTLE_FRAMES)
	var ground_y: float = body.global_position.y
	_pause(true)
	Input.action_press(InputActions.JUMP)
	await _frames(HALF_SECOND_FRAMES)
	_pause(false)
	var highest_m: float = ground_y
	for _frame: int in range(HALF_SECOND_FRAMES):
		await get_tree().physics_frame
		highest_m = maxf(highest_m, body.global_position.y)
	assert_lte(highest_m - ground_y, NO_JUMP_RISE_M, "Segurar a tecla durante a pausa não dispara um pulo ao despausar.")
	Input.action_release(InputActions.JUMP)
	await _frames(2)
	Input.action_press(InputActions.JUMP)
	for _frame: int in range(HALF_SECOND_FRAMES):
		await get_tree().physics_frame
		highest_m = maxf(highest_m, body.global_position.y)
	assert_gt(highest_m - ground_y, JUMP_MIN_RISE_M, "Soltar e apertar de novo pula (o teste não é vazio).")


func test_the_camera_still_orbits_and_zooms_while_the_game_is_paused() -> void:
	var body: PlayerBody = _new_body()
	var camera: ThirdPersonCamera = ThirdPersonCamera.new()
	add_child_autofree(camera)
	assert_true(camera.setup(_bridge, body))
	await _frames(SETTLE_FRAMES)
	_pause(true)
	var body_before: Vector3 = body.global_position
	var yaw_before: float = camera.yaw_rad
	var distance_before: float = camera.distance_m
	Input.action_press(InputActions.LOOK_LEFT)
	await _frames(LOOK_FRAMES)
	Input.action_release(InputActions.LOOK_LEFT)
	assert_gt(absf(angle_difference(yaw_before, camera.yaw_rad)), LOOK_MIN_RAD, "As setas giram a câmera com o jogo pausado.")
	var zoom: InputEventAction = InputEventAction.new()
	zoom.action = InputActions.ZOOM_IN
	zoom.pressed = true
	camera._unhandled_input(zoom)
	assert_lt(camera.distance_m, distance_before, "A roda dá zoom com o jogo pausado.")
	await _frames(LOOK_FRAMES)
	assert_almost_eq(angle_difference(camera.global_rotation.y, camera.yaw_rad), 0.0, SHOWN_TOLERANCE_RAD, "A imagem alcança o giro pedido.")
	assert_lte((body.global_position - body_before).length(), FROZEN_TOLERANCE_M, "Enquanto a câmera gira, o corpo continua parado.")


func test_a_body_whose_bridge_has_no_game_is_never_frozen() -> void:
	var alone: SimBridge = SimBridge.new(null, _terrain)
	var body: PlayerBody = PlayerBody.new()
	add_child_autofree(body)
	assert_true(body.setup(alone, _view, _reference))
	assert_push_warning("o personagem não nasceu na simulação")
	await _frames(SETTLE_FRAMES)
	var start: Vector3 = body.global_position
	Input.action_press(InputActions.MOVE_FORWARD)
	await _frames(FRAMES_PER_SECOND)
	Input.action_release(InputActions.MOVE_FORWARD)
	assert_gt(body.global_position.x - start.x, WALK_MIN_M, "Sem hora na ponte conta como não pausado: o corpo anda.")
