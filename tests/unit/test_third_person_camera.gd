extends GutTest
## LW-046: ThirdPersonCamera sobre o terreno de blockout real e a ponte real, sem janela. Quase tudo é testado passo a passo,
## chamando follow_step e view_step com tempos escolhidos (determinístico, sem depender do relógio do motor); o teste de seguir um
## jogador de verdade acelera o relógio do motor como o test_player_body (time_scale e physics_ticks_per_second na mesma proporção,
## o que mantém o passo de física em 1/60 s) e restaura ao fim. Os valores esperados estão ESCRITOS À MÃO a partir das hipóteses do
## envio: 12 m de distância, 35° para baixo, ponto de mira 1,5 m acima dos pés, zoom de 4 a 40 m, inclinação de 10° a 75°, folga de
## 0,5 m sobre o terreno, 0,25° por pixel, 90°/s nas setas e 15% por clique da roda.

const BLOCKOUT_DIR: String = "res://data/world"
const DEFAULT_DISTANCE_M: float = 12.0
const AIM_HEIGHT_M: float = 1.5
const MIN_DISTANCE_M: float = 4.0
const MAX_DISTANCE_M: float = 40.0
const MIN_PITCH_DEGREES: float = 10.0
const MAX_PITCH_DEGREES: float = 75.0
const DEFAULT_PITCH_DEGREES: float = 35.0
const GROUND_MARGIN_M: float = 0.5
## 12 m a 35° para baixo: 12 x cos(35°) para trás e 12 x sin(35°) para cima, a partir do ponto de mira.
const BEHIND_M: float = 9.8298
const ABOVE_AIM_M: float = 6.8829
const POSITION_TOLERANCE_M: float = 0.01
const ANGLE_TOLERANCE_RAD: float = 0.0002
## Passo longo: a suavização exponencial praticamente termina em um passo; poucos passos assentam a câmera.
const LONG_STEP_S: float = 10.0
const SETTLE_STEPS: int = 4
const SAMPLE_STEP_M: float = 0.25
const LINE_TOLERANCE_M: float = 0.05
const PLAIN_SPAWN: Vector3 = Vector3(100.0, 10.0, 512.0)
## Pontos de teste do jogador (x, z): pé da colina, meio da encosta, topo, vale e junto à borda oeste do mapa.
const PLAYER_SPOTS: Array[Vector2] = [Vector2(570.0, 300.0), Vector2(610.0, 300.0), Vector2(700.0, 300.0), Vector2(300.0, 750.0), Vector2(3.0, 512.0), Vector2(1021.0, 40.0)]
const YAW_STEP_DEGREES: float = 15.0
const PITCHES_DEGREES: Array[float] = [10.0, 35.0, 75.0]
const DISTANCES_M: Array[float] = [4.0, 12.0, 40.0]
const ORBIT_FRAMES: int = 144
const ORBIT_DEGREES_PER_FRAME: float = 2.5
const FRAME_S: float = 1.0 / 60.0
const MOUSE_DRAG: Vector2 = Vector2(100.0, 40.0)
const ORBIT_DEGREES_PER_PIXEL: float = 0.25
const KEY_SECONDS: float = 0.5
const KEY_DEGREES: float = 45.0
const ZOOM_FACTOR: float = 1.15
const MANY_CLICKS: int = 100
const UPHILL_SPOT: Vector2 = Vector2(570.0, 300.0)
const FAR_DISTANCE_M: float = 30.0
const UPHILL_DISTANCE_M: float = 20.0
const SHORTENED_BY_M: float = 1.0
## Jitter: jogador a 7 m/s em passos de física de 60 Hz, quadros de 144 Hz (a tela do Mac de referência é de 120 Hz).
const RUN_SPEED_MPS: float = 7.0
const TICK_S: float = 1.0 / 60.0
const SCREEN_FRAME_S: float = 1.0 / 144.0
const JITTER_SECONDS: float = 3.0
const JITTER_WARMUP_S: float = 1.0
const JITTER_TOLERANCE_M: float = 0.005
const NAIVE_JITTER_MIN_M: float = 0.02
const FOLLOW_TIME_S: float = 0.10
## Seguir um jogador de verdade, com o relógio do motor acelerado.
const ACCELERATION: float = 10.0
const HOST_PATH: String = "/root/SimulationHost"
const SPEED_CHANGE_FRAMES: int = 3
const FRAMES_PER_SECOND: int = 60
const FOLLOW_SECONDS: int = 5
const HORIZONTAL_LAG_M: float = 0.7
const FOLLOW_RANGE_M: float = 1.0
const FOLLOW_HEIGHT_TOLERANCE_M: float = 0.15
const FLOAT_TOLERANCE: float = 0.000001
## Terreno sintético com um penhasco: 64 x 64 células de 2 m (128 m); da coluna de nós 32 em diante (x = 64 m) o chão sobe 10 m.
const CLIFF_CELLS: int = 64
const CLIFF_CELL_CM: int = 200
const CLIFF_CHUNK_CELLS: int = 8
const CLIFF_FIRST_HIGH_NODE: int = 32
const CLIFF_HEIGHT_CM: int = 1000
const CLIFF_SURFACE_CODE: int = 5
const CLIFF_X_M: float = 64.0
const CLIFF_Z_M: float = 64.0
const CLIFF_FOOT_GAPS_M: Array[float] = [6.0, 3.0, 1.0, 0.3]
const RECOVERY_START_GAP_M: float = 3.0
const RECOVERY_FAR_GAP_M: float = 30.0

var _bridge: SimBridge
var _target: Node3D


func before_all() -> void:
	var loaded: TerrainLoader.LoadResult = TerrainLoader.load_dir(BLOCKOUT_DIR)
	assert_true(loaded.result.ok, loaded.result.message)
	_bridge = SimBridge.new(null, loaded.terrain)


func before_each() -> void:
	_target = Node3D.new()
	add_child_autofree(_target)


func after_each() -> void:
	for action: StringName in InputActions.ALL:
		Input.action_release(action)


func _ground(point: Vector3) -> float:
	return _bridge.peek_height(clampf(point.x, 0.0, 1024.0), clampf(point.z, 0.0, 1024.0)).height_m


func _spot(point: Vector2) -> Vector3:
	var spot: Vector3 = Vector3(point.x, 0.0, point.y)
	spot.y = _ground(spot)
	return spot


## Câmera nova seguindo o alvo posto em `player`, sem processamento próprio: os passos são dados pelo teste.
func _new_camera(player: Vector3) -> ThirdPersonCamera:
	_target.global_position = player
	var camera: ThirdPersonCamera = ThirdPersonCamera.new()
	add_child_autofree(camera)
	assert_true(camera.setup(_bridge, _target))
	camera.set_process(false)
	camera.set_physics_process(false)
	return camera


func _settle(camera: ThirdPersonCamera) -> void:
	for _step: int in range(SETTLE_STEPS):
		camera.follow_step(LONG_STEP_S)
		camera.view_step(LONG_STEP_S)


## A câmera está acima do terreno com a folga, e o terreno não corta a linha do ponto de mira até ela.
func _assert_clear_of_terrain(camera: ThirdPersonCamera, label: String) -> void:
	var aim: Vector3 = _target.global_position + Vector3(0.0, AIM_HEIGHT_M, 0.0)
	var camera_at: Vector3 = camera.global_position
	assert_gte(camera_at.y, _ground(camera_at) + GROUND_MARGIN_M - FLOAT_TOLERANCE, "Câmera abaixo do terreno (%s)." % label)
	var length: float = aim.distance_to(camera_at)
	var steps: int = ceili(length / SAMPLE_STEP_M)
	for index: int in range(steps + 1):
		var sample: Vector3 = aim.lerp(camera_at, float(index) / float(steps))
		assert_gte(sample.y, _ground(sample) + GROUND_MARGIN_M - LINE_TOLERANCE_M, "O terreno corta a linha até a câmera (%s)." % label)


func _mouse_drag(relative: Vector2) -> InputEventMouseMotion:
	var motion: InputEventMouseMotion = InputEventMouseMotion.new()
	motion.relative = relative
	return motion


func _wheel(button: MouseButton) -> InputEventMouseButton:
	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.button_index = button
	event.pressed = true
	return event


func _make_cliff_bridge() -> SimBridge:
	var nodes_per_side: int = CLIFF_CELLS + 1
	var heights: PackedInt64Array = PackedInt64Array()
	heights.resize(nodes_per_side * nodes_per_side)
	for node_z: int in range(nodes_per_side):
		for node_x: int in range(nodes_per_side):
			heights[node_z * nodes_per_side + node_x] = CLIFF_HEIGHT_CM if node_x >= CLIFF_FIRST_HIGH_NODE else 0
	var surfaces: PackedInt64Array = PackedInt64Array()
	surfaces.resize(CLIFF_CELLS * CLIFF_CELLS)
	surfaces.fill(CLIFF_SURFACE_CODE)
	var ids: Dictionary[int, String] = {CLIFF_SURFACE_CODE: "rock"}
	var terrain: TerrainData = TerrainData.new(Vector2i(CLIFF_CELLS, CLIFF_CELLS), CLIFF_CELL_CM, CLIFF_CHUNK_CELLS, heights, surfaces, ids, Vector2i.ZERO)
	return SimBridge.new(null, terrain)


func test_setup_puts_the_camera_behind_and_above_the_player_looking_at_the_aim_point() -> void:
	var camera: ThirdPersonCamera = _new_camera(PLAIN_SPAWN)
	assert_true(camera.is_following())
	# Giro padrão: para o leste. A câmera fica a oeste do jogador, atrás e acima do ponto de mira.
	assert_almost_eq(camera.global_position.x, PLAIN_SPAWN.x - BEHIND_M, POSITION_TOLERANCE_M)
	assert_almost_eq(camera.global_position.y, PLAIN_SPAWN.y + AIM_HEIGHT_M + ABOVE_AIM_M, POSITION_TOLERANCE_M)
	assert_almost_eq(camera.global_position.z, PLAIN_SPAWN.z, POSITION_TOLERANCE_M)
	assert_almost_eq(camera.global_rotation.y, deg_to_rad(-90.0), ANGLE_TOLERANCE_RAD, "Olha para o leste.")
	assert_almost_eq(camera.global_rotation.x, deg_to_rad(-DEFAULT_PITCH_DEGREES), ANGLE_TOLERANCE_RAD, "35° para baixo.")
	var aim: Vector3 = PLAIN_SPAWN + Vector3(0.0, AIM_HEIGHT_M, 0.0)
	var to_aim: Vector3 = (aim - camera.global_position).normalized()
	assert_almost_eq(to_aim.dot(-camera.global_basis.z), 1.0, ANGLE_TOLERANCE_RAD, "O ponto de mira está no eixo da câmera.")
	assert_almost_eq(camera.global_position.distance_to(aim), DEFAULT_DISTANCE_M, POSITION_TOLERANCE_M)


func test_the_camera_never_goes_below_the_terrain_for_any_angle_zoom_or_player_spot() -> void:
	for spot: Vector2 in PLAYER_SPOTS:
		var camera: ThirdPersonCamera = _new_camera(_spot(spot))
		var yaw_degrees: float = 0.0
		while yaw_degrees < 360.0:
			for pitch_degrees: float in PITCHES_DEGREES:
				for distance: float in DISTANCES_M:
					camera.yaw_rad = deg_to_rad(yaw_degrees)
					camera.pitch_rad = deg_to_rad(pitch_degrees)
					camera.distance_m = distance
					_settle(camera)
					_assert_clear_of_terrain(camera, "ponto %s, giro %s°, inclinação %s°, distância %s m" % [str(spot), str(yaw_degrees), str(pitch_degrees), str(distance)])
			yaw_degrees += YAW_STEP_DEGREES


func test_the_camera_stays_above_the_terrain_on_every_frame_of_a_full_orbit_with_zoom() -> void:
	var camera: ThirdPersonCamera = _new_camera(_spot(Vector2(610.0, 300.0)))
	camera.pitch_rad = deg_to_rad(MIN_PITCH_DEGREES)
	for frame: int in range(ORBIT_FRAMES):
		camera.orbit_by(deg_to_rad(ORBIT_DEGREES_PER_FRAME), 0.0)
		camera.zoom_by(1.0 if frame % 24 < 12 else -1.0)
		camera.follow_step(FRAME_S)
		camera.view_step(FRAME_S)
		_assert_clear_of_terrain(camera, "quadro %d da órbita" % frame)


func test_the_terrain_between_the_player_and_the_camera_shortens_the_arm() -> void:
	var player: Vector3 = _spot(UPHILL_SPOT)
	var camera: ThirdPersonCamera = _new_camera(player)
	camera.yaw_rad = deg_to_rad(90.0) # a câmera vai para o leste, encosta acima
	camera.pitch_rad = deg_to_rad(MIN_PITCH_DEGREES)
	camera.distance_m = UPHILL_DISTANCE_M
	_settle(camera)
	var aim: Vector3 = player + Vector3(0.0, AIM_HEIGHT_M, 0.0)
	assert_lt(camera.global_position.distance_to(aim), UPHILL_DISTANCE_M - SHORTENED_BY_M, "A encosta encurtou o braço (o teste não é vazio).")
	_assert_clear_of_terrain(camera, "encosta")
	camera.distance_m = DEFAULT_DISTANCE_M
	camera.pitch_rad = deg_to_rad(DEFAULT_PITCH_DEGREES)
	_settle(camera)
	assert_almost_eq(camera.global_position.distance_to(aim), DEFAULT_DISTANCE_M, POSITION_TOLERANCE_M, "Sem terreno no caminho, o braço volta ao tamanho pedido.")


func test_the_mouse_orbits_only_while_the_orbit_button_is_pressed() -> void:
	var camera: ThirdPersonCamera = _new_camera(PLAIN_SPAWN)
	var yaw_before: float = camera.yaw_rad
	var pitch_before: float = camera.pitch_rad
	camera._unhandled_input(_mouse_drag(MOUSE_DRAG))
	assert_eq(camera.yaw_rad, yaw_before, "Sem o botão apertado o mouse não gira.")
	assert_eq(camera.pitch_rad, pitch_before)
	Input.action_press(InputActions.CAMERA_ORBIT)
	camera._unhandled_input(_mouse_drag(MOUSE_DRAG))
	# 100 px para a direita = 25° para a direita (o giro diminui); 40 px para baixo = 10° mais para baixo.
	assert_almost_eq(camera.yaw_rad, yaw_before - deg_to_rad(MOUSE_DRAG.x * ORBIT_DEGREES_PER_PIXEL), ANGLE_TOLERANCE_RAD)
	assert_almost_eq(camera.pitch_rad, pitch_before + deg_to_rad(MOUSE_DRAG.y * ORBIT_DEGREES_PER_PIXEL), ANGLE_TOLERANCE_RAD)
	Input.action_release(InputActions.CAMERA_ORBIT)
	var yaw_after: float = camera.yaw_rad
	camera._unhandled_input(_mouse_drag(MOUSE_DRAG))
	assert_eq(camera.yaw_rad, yaw_after, "Soltou o botão, parou de girar.")


func test_the_arrow_keys_rotate_the_camera_and_the_pitch_stops_at_its_limits() -> void:
	var camera: ThirdPersonCamera = _new_camera(PLAIN_SPAWN)
	var yaw_start: float = camera.yaw_rad
	Input.action_press(InputActions.LOOK_LEFT)
	camera.view_step(KEY_SECONDS)
	Input.action_release(InputActions.LOOK_LEFT)
	assert_almost_eq(camera.yaw_rad, yaw_start + deg_to_rad(KEY_DEGREES), ANGLE_TOLERANCE_RAD, "90°/s por 0,5 s para a esquerda.")
	Input.action_press(InputActions.LOOK_RIGHT)
	camera.view_step(KEY_SECONDS * 2.0)
	Input.action_release(InputActions.LOOK_RIGHT)
	assert_almost_eq(camera.yaw_rad, yaw_start - deg_to_rad(KEY_DEGREES), ANGLE_TOLERANCE_RAD, "Para a direita, 90° de volta.")
	Input.action_press(InputActions.LOOK_DOWN)
	camera.view_step(KEY_SECONDS * 2.0)
	assert_almost_eq(camera.pitch_rad, deg_to_rad(MAX_PITCH_DEGREES), ANGLE_TOLERANCE_RAD, "Para baixo para na inclinação máxima.")
	Input.action_release(InputActions.LOOK_DOWN)
	Input.action_press(InputActions.LOOK_UP)
	camera.view_step(KEY_SECONDS * 4.0)
	assert_almost_eq(camera.pitch_rad, deg_to_rad(MIN_PITCH_DEGREES), ANGLE_TOLERANCE_RAD, "Para cima para na inclinação mínima.")
	Input.action_release(InputActions.LOOK_UP)


func test_orbit_by_wraps_the_yaw_and_limits_the_pitch() -> void:
	var camera: ThirdPersonCamera = _new_camera(PLAIN_SPAWN)
	camera.orbit_by(0.0, 10.0)
	assert_almost_eq(camera.pitch_rad, deg_to_rad(MAX_PITCH_DEGREES), ANGLE_TOLERANCE_RAD)
	camera.orbit_by(0.0, -10.0)
	assert_almost_eq(camera.pitch_rad, deg_to_rad(MIN_PITCH_DEGREES), ANGLE_TOLERANCE_RAD)
	camera.yaw_rad = 0.0
	camera.orbit_by(deg_to_rad(370.0), 0.0)
	assert_almost_eq(camera.yaw_rad, deg_to_rad(10.0), ANGLE_TOLERANCE_RAD, "Uma volta e mais 10°.")
	assert_between(camera.yaw_rad, -PI, PI)


func test_the_wheel_zooms_by_fifteen_percent_per_click_and_clamps_at_the_limits() -> void:
	var camera: ThirdPersonCamera = _new_camera(PLAIN_SPAWN)
	camera._unhandled_input(_wheel(MOUSE_BUTTON_WHEEL_UP))
	assert_almost_eq(camera.distance_m, DEFAULT_DISTANCE_M / ZOOM_FACTOR, FLOAT_TOLERANCE, "Roda para cima aproxima 15%.")
	camera.distance_m = DEFAULT_DISTANCE_M
	camera._unhandled_input(_wheel(MOUSE_BUTTON_WHEEL_DOWN))
	assert_almost_eq(camera.distance_m, DEFAULT_DISTANCE_M * ZOOM_FACTOR, FLOAT_TOLERANCE, "Roda para baixo afasta 15%.")
	for _click: int in range(MANY_CLICKS):
		camera._unhandled_input(_wheel(MOUSE_BUTTON_WHEEL_UP))
	assert_eq(camera.distance_m, MIN_DISTANCE_M, "Não passa de 4 m.")
	for _click: int in range(MANY_CLICKS):
		camera._unhandled_input(_wheel(MOUSE_BUTTON_WHEEL_DOWN))
	assert_eq(camera.distance_m, MAX_DISTANCE_M, "Não passa de 40 m.")


func test_the_shown_camera_follows_the_zoom_smoothly_and_ends_at_the_new_distance() -> void:
	var camera: ThirdPersonCamera = _new_camera(PLAIN_SPAWN)
	var aim: Vector3 = PLAIN_SPAWN + Vector3(0.0, AIM_HEIGHT_M, 0.0)
	camera.distance_m = MIN_DISTANCE_M
	camera.view_step(FRAME_S)
	var after_one_frame: float = camera.global_position.distance_to(aim)
	assert_lt(after_one_frame, DEFAULT_DISTANCE_M, "Começou a aproximar.")
	assert_gt(after_one_frame, MIN_DISTANCE_M + 1.0, "Mas não pulou direto: é suave.")
	_settle(camera)
	assert_almost_eq(camera.global_position.distance_to(aim), MIN_DISTANCE_M, POSITION_TOLERANCE_M)
	camera.distance_m = FAR_DISTANCE_M
	_settle(camera)
	assert_almost_eq(camera.global_position.distance_to(aim), FAR_DISTANCE_M, POSITION_TOLERANCE_M, "Afastando de novo, o braço cresce até a distância pedida.")


func test_the_player_does_not_shake_on_screen_when_the_physics_and_the_frames_differ() -> void:
	var player: Vector3 = PLAIN_SPAWN
	var camera: ThirdPersonCamera = _new_camera(player)
	var naive_follow_x: float = player.x
	var time_s: float = 0.0
	var next_tick_s: float = TICK_S
	var offsets: Array[float] = []
	var naive_offsets: Array[float] = []
	for _frame: int in range(int(JITTER_SECONDS / SCREEN_FRAME_S)):
		time_s += SCREEN_FRAME_S
		while next_tick_s <= time_s:
			player.x += RUN_SPEED_MPS * TICK_S
			_target.global_position = player
			camera.follow_step(TICK_S)
			next_tick_s += TICK_S
		camera.view_step(SCREEN_FRAME_S)
		naive_follow_x = lerpf(naive_follow_x, player.x, 1.0 - exp(-SCREEN_FRAME_S / FOLLOW_TIME_S))
		if time_s > JITTER_WARMUP_S:
			offsets.append(camera.global_position.x - player.x)
			naive_offsets.append(naive_follow_x - player.x)
	assert_lte(offsets.max() - offsets.min(), JITTER_TOLERANCE_M, "A cápsula balançou %s m na tela." % str(offsets.max() - offsets.min()))
	assert_gte(naive_offsets.max() - naive_offsets.min(), NAIVE_JITTER_MIN_M, "Sensibilidade: um seguidor por quadro tremeria; a medida enxerga o problema.")


func test_setup_with_a_missing_piece_reports_the_error_and_the_camera_does_not_follow() -> void:
	var camera: ThirdPersonCamera = ThirdPersonCamera.new()
	add_child_autofree(camera)
	assert_false(camera.setup(null, _target))
	assert_push_error("ponte nula")
	assert_false(camera.setup(SimBridge.new(null, null), _target))
	assert_push_error("formato do terreno indisponível")
	assert_false(camera.setup(_bridge, null))
	assert_push_error("alvo nulo")
	assert_false(camera.is_following())
	assert_false(camera.is_processing())
	var before: Transform3D = camera.global_transform
	camera.view_step(LONG_STEP_S)
	camera.follow_step(LONG_STEP_S)
	camera._unhandled_input(_wheel(MOUSE_BUTTON_WHEEL_UP))
	assert_eq(camera.global_transform, before, "Sem seguir ninguém, a câmera não se mexe.")
	assert_eq(camera.distance_m, DEFAULT_DISTANCE_M)
	var outside: ThirdPersonCamera = ThirdPersonCamera.new()
	assert_false(outside.setup(_bridge, _target))
	assert_push_error("árvore")
	outside.free()


func test_the_camera_follows_a_running_player_within_range_and_the_player_walks_relative_to_it() -> void:
	var host: Node = get_node_or_null(HOST_PATH)
	if host != null:
		host.set_process(false) # trocar a velocidade do motor dá um quadro de delta negativo, que o relógio da simulação recusa
	var original_scale: float = Engine.time_scale
	var original_ticks: int = Engine.physics_ticks_per_second
	Engine.time_scale = ACCELERATION
	Engine.physics_ticks_per_second = int(float(original_ticks) * ACCELERATION)
	for _frame: int in range(SPEED_CHANGE_FRAMES):
		await get_tree().process_frame
	var view: TerrainView = TerrainView.new()
	add_child_autofree(view)
	view.setup(_bridge)
	view.set_focus(PLAIN_SPAWN)
	view.process_budget(1.0e9)
	var body: PlayerBody = PlayerBody.new()
	add_child_autofree(body)
	var camera: ThirdPersonCamera = ThirdPersonCamera.new()
	add_child_autofree(camera)
	assert_true(body.setup(_bridge, view, camera))
	assert_true(camera.setup(_bridge, body))
	for _frame: int in range(FRAMES_PER_SECOND):
		await get_tree().physics_frame
	var start: Vector3 = body.global_position
	Input.action_press(InputActions.MOVE_FORWARD)
	Input.action_press(InputActions.RUN)
	for _frame: int in range(FOLLOW_SECONDS * FRAMES_PER_SECOND):
		await get_tree().physics_frame
	var offset: Vector3 = camera.global_position - body.global_position
	var horizontal: float = Vector2(offset.x, offset.z).length()
	Input.action_release(InputActions.MOVE_FORWARD)
	Input.action_release(InputActions.RUN)
	Engine.time_scale = original_scale
	Engine.physics_ticks_per_second = original_ticks
	for _frame: int in range(SPEED_CHANGE_FRAMES):
		await get_tree().process_frame
	if host != null:
		host.set_process(true)
	assert_gt(body.global_position.x - start.x, 30.0, "O jogador correu para o leste, a direção da câmera (7 m/s por 5 s: cerca de 35 m).")
	# Atrás do jogador pela distância horizontal padrão mais o atraso da suavização (7 m/s x 0,1 s = 0,7 m).
	assert_almost_eq(horizontal, BEHIND_M + HORIZONTAL_LAG_M, FOLLOW_RANGE_M, "A câmera ficou a %s m do jogador na horizontal." % str(horizontal))
	assert_almost_eq(offset.y, AIM_HEIGHT_M + ABOVE_AIM_M, FOLLOW_HEIGHT_TOLERANCE_M, "A altura da câmera sobre o jogador.")
	assert_almost_eq(camera.global_rotation.y, deg_to_rad(-90.0), ANGLE_TOLERANCE_RAD, "Seguir não gira a câmera.")


func test_a_cliff_next_to_the_player_never_puts_the_camera_inside_the_terrain() -> void:
	var cliff_bridge: SimBridge = _make_cliff_bridge()
	for gap_m: float in CLIFF_FOOT_GAPS_M:
		_target.global_position = Vector3(CLIFF_X_M - gap_m, 0.0, CLIFF_Z_M)
		var camera: ThirdPersonCamera = ThirdPersonCamera.new()
		add_child_autofree(camera)
		assert_true(camera.setup(cliff_bridge, _target))
		camera.set_process(false)
		camera.set_physics_process(false)
		camera.yaw_rad = deg_to_rad(90.0) # a câmera vai para o leste, para dentro do penhasco
		camera.pitch_rad = deg_to_rad(MIN_PITCH_DEGREES)
		_settle(camera)
		var camera_at: Vector3 = camera.global_position
		var ground: float = cliff_bridge.peek_height(camera_at.x, camera_at.z).height_m
		assert_gte(camera_at.y, ground + GROUND_MARGIN_M - FLOAT_TOLERANCE, "Câmera dentro do penhasco com o jogador a %s m do pé dele." % str(gap_m))
		var aim: Vector3 = _target.global_position + Vector3(0.0, AIM_HEIGHT_M, 0.0)
		assert_lt(camera_at.distance_to(aim), DEFAULT_DISTANCE_M, "O penhasco encurtou o braço (o teste não é vazio).")


func test_the_arm_recovers_gradually_and_then_fully_when_the_obstacle_is_gone() -> void:
	var cliff_bridge: SimBridge = _make_cliff_bridge()
	_target.global_position = Vector3(CLIFF_X_M - RECOVERY_START_GAP_M, 0.0, CLIFF_Z_M)
	var camera: ThirdPersonCamera = ThirdPersonCamera.new()
	add_child_autofree(camera)
	assert_true(camera.setup(cliff_bridge, _target))
	camera.set_process(false)
	camera.set_physics_process(false)
	camera.yaw_rad = deg_to_rad(90.0) # a câmera vai para o leste, para dentro do penhasco
	camera.pitch_rad = deg_to_rad(MIN_PITCH_DEGREES)
	_settle(camera)
	var aim: Vector3 = _target.global_position + Vector3(0.0, AIM_HEIGHT_M, 0.0)
	var blocked_m: float = camera.global_position.distance_to(aim)
	assert_lt(blocked_m, RECOVERY_START_GAP_M + 1.0, "O penhasco prendeu o braço perto do jogador.")
	_target.global_position = Vector3(CLIFF_X_M - RECOVERY_FAR_GAP_M, 0.0, CLIFF_Z_M)
	camera.follow_step(LONG_STEP_S)
	aim = _target.global_position + Vector3(0.0, AIM_HEIGHT_M, 0.0)
	camera.view_step(FRAME_S)
	var one_frame_m: float = camera.global_position.distance_to(aim)
	assert_gt(one_frame_m, blocked_m + 0.2, "O braço começou a voltar.")
	assert_lt(one_frame_m, DEFAULT_DISTANCE_M - 3.0, "Mas só um pouco por quadro: a volta é gradual.")
	_settle(camera)
	assert_almost_eq(camera.global_position.distance_to(aim), DEFAULT_DISTANCE_M, POSITION_TOLERANCE_M, "Livre, o braço volta inteiro.")
