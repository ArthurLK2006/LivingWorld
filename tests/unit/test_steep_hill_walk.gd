extends GutTest
## LW-047A: um PlayerBody de verdade, com entrada scriptada (ações, como nos testes da LW-045 e da LW-047), NÃO consegue subir o lado íngreme
## do morro de teste (a inclinação máxima caminhável é 40° e o lado oeste chega a cerca de 50°) e CONSEGUE subir o lado suave (cerca de 31°).
## Terreno de blockout real, sem janela; o relógio do motor é acelerado como em tests/unit/test_player_body.gd (PhysicsBoost). Valores
## escritos à mão: andar 4 m/s, correr 7 m/s, planície a 10 m, morro de cerca de 15 m, pico no centro (168 m, 469 m).

const BLOCKOUT_DIR: String = "res://data/world"
const FRAMES_PER_SECOND: int = 60
const HUGE_BUDGET_MS: float = 1.0e9
const COLLISION_FRAMES: int = 4
const SETTLE_MIN_FRAMES: int = 4
const SETTLE_MAX_FRAMES: int = 120
const PLAIN_M: float = 10.0
## Pé do lado íngreme (oeste), de frente para o leste, e pé do lado suave (leste), de frente para o oeste, na linha central do morro.
const STEEP_FOOT: Vector2 = Vector2(147.0, 469.0)
const GENTLE_FOOT: Vector2 = Vector2(209.0, 469.0)
const EAST_YAW_DEGREES: float = -90.0
const WEST_YAW_DEGREES: float = 90.0
const STEEP_SECONDS: int = 8
const GENTLE_SECONDS: int = 14
## Altura máxima que o corpo pode alcançar no lado íngreme: só o pé do morro, que é suave, é caminhável (medido: cerca de 1,7 m).
const STEEP_CLIMB_LIMIT_M: float = 3.0
## O lado suave tem de levar o corpo a mais de dois terços da subida do morro (cerca de 15 m).
const GENTLE_CLIMB_MIN_M: float = 10.0
const JUMP_TOGGLE_FRAMES: int = 20
const PEAK_X_M: float = 168.0
const NEAR_PEAK_M: float = 12.0
## A encosta oeste passa de 40° a cerca de 16 m do pico em x (fórmula do morro; medido: o corpo parou a 16,2 m); o corpo não pode passar de 14 m.
const WALL_FROM_PEAK_M: float = 14.0

var _boost: PhysicsBoost = PhysicsBoost.new()
var _terrain: TerrainData
var _bridge: SimBridge
var _view: TerrainView
var _reference: Node3D
## Menor distância em x até o pico durante a última corrida.
var _closest_to_peak_m: float = INF


func before_all() -> void:
	await _boost.enable(get_tree())
	var loaded: TerrainLoader.LoadResult = TerrainLoader.load_dir(BLOCKOUT_DIR)
	assert_true(loaded.result.ok, loaded.result.message)
	_terrain = loaded.terrain
	_bridge = SimBridge.new(null, _terrain)
	_reference = Node3D.new()
	add_child(_reference)
	_view = TerrainView.new()
	add_child(_view)
	_view.setup(_bridge)
	_view.set_focus(Vector3(PEAK_X_M, 0.0, STEEP_FOOT.y))
	_view.process_budget(HUGE_BUDGET_MS)
	for _frame: int in range(COLLISION_FRAMES):
		await get_tree().physics_frame


func after_all() -> void:
	_view.free()
	_reference.free()
	await _boost.restore(get_tree())


func after_each() -> void:
	for action: StringName in InputActions.ALL:
		Input.action_release(action)


func _new_body() -> PlayerBody:
	var body: PlayerBody = PlayerBody.new()
	add_child_autofree(body)
	assert_true(body.setup(_bridge, _view, _reference))
	assert_push_warning("o personagem não nasceu na simulação")
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


func _teleport(body: PlayerBody, foot: Vector2) -> void:
	var ground: float = _bridge.peek_height(foot.x, foot.y).height_m
	body.global_position = Vector3(foot.x, ground + PlayerBody.SPAWN_CLEARANCE_M, foot.y)
	body.velocity = Vector3.ZERO
	await _settle(body)


## Corre para a frente por `seconds` e devolve a maior altura que os pés alcançaram. Com `jumping`, aperta e solta o pulo sem parar.
func _run_and_track_highest(body: PlayerBody, seconds: int, jumping: bool) -> float:
	var highest: float = body.global_position.y
	_closest_to_peak_m = INF
	Input.action_press(InputActions.MOVE_FORWARD)
	Input.action_press(InputActions.RUN)
	for frame: int in range(seconds * FRAMES_PER_SECOND):
		if jumping and frame % JUMP_TOGGLE_FRAMES == 0:
			Input.action_release(InputActions.JUMP)
		elif jumping and frame % JUMP_TOGGLE_FRAMES == 2:
			Input.action_press(InputActions.JUMP)
		await get_tree().physics_frame
		highest = maxf(highest, body.global_position.y)
		_closest_to_peak_m = minf(_closest_to_peak_m, absf(body.global_position.x - PEAK_X_M))
	Input.action_release(InputActions.MOVE_FORWARD)
	Input.action_release(InputActions.RUN)
	Input.action_release(InputActions.JUMP)
	return highest


func test_the_player_cannot_climb_the_steep_side() -> void:
	_reference.rotation_degrees = Vector3(0.0, EAST_YAW_DEGREES, 0.0)
	var body: PlayerBody = _new_body()
	await _teleport(body, STEEP_FOOT)
	var highest: float = await _run_and_track_highest(body, STEEP_SECONDS, false)
	assert_lt(highest - PLAIN_M, STEEP_CLIMB_LIMIT_M, "Correndo 8 s contra o lado íngreme os pés só chegaram a %s m acima da planície." % str(highest - PLAIN_M))
	assert_gt(_closest_to_peak_m, WALL_FROM_PEAK_M, "O corpo parou no pé da encosta íngreme: o mais perto do pico foi a %s m em x." % str(_closest_to_peak_m))


func test_jumping_against_the_steep_side_does_not_get_the_player_up_either() -> void:
	_reference.rotation_degrees = Vector3(0.0, EAST_YAW_DEGREES, 0.0)
	var body: PlayerBody = _new_body()
	await _teleport(body, STEEP_FOOT)
	var highest: float = await _run_and_track_highest(body, STEEP_SECONDS, true)
	assert_lt(highest - PLAIN_M, STEEP_CLIMB_LIMIT_M + 1.0, "Pulando sem parar os pés só chegaram a %s m acima da planície." % str(highest - PLAIN_M))


func test_the_player_climbs_the_gentle_side() -> void:
	_reference.rotation_degrees = Vector3(0.0, WEST_YAW_DEGREES, 0.0)
	var body: PlayerBody = _new_body()
	await _teleport(body, GENTLE_FOOT)
	var highest: float = await _run_and_track_highest(body, GENTLE_SECONDS, false)
	assert_gt(highest - PLAIN_M, GENTLE_CLIMB_MIN_M, "Correndo pelo lado suave os pés chegaram a %s m acima da planície." % str(highest - PLAIN_M))
	assert_lt(_closest_to_peak_m, NEAR_PEAK_M, "E chegou perto do pico (a %s m dele em x)." % str(_closest_to_peak_m))
