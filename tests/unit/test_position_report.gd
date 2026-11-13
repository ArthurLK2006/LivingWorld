extends GutTest
## LW-048: o PlayerBody pede um personagem à simulação ao nascer e RELATA a posição e a orientação pela ponte, em intervalo fixo.
## O fluxo é de um sentido só: a simulação guarda o que foi relatado e nunca move a cápsula. Terreno de blockout real, mundo do
## jogo real (GameModules) e ponte real, sem janela. O relógio do motor é acelerado como em tests/unit/test_player_body.gd
## (PhysicsBoost), mantendo cada passo de física em 1/60 s. Os valores esperados estão ESCRITOS À MÃO a partir das hipóteses do
## envio: correr 7 m/s, relato a cada 6 quadros de física (10 por segundo) e tolerância de 1 m (6 quadros a 7 m/s dão 0,7 m).

const BLOCKOUT_DIR: String = "res://data/world"
const WORLD_SEED: int = 3
const FRAMES_PER_SECOND: int = 60
const RUN_SECONDS: int = 10
const SAMPLE_EVERY_FRAMES: int = 30
const REPORT_TOLERANCE_M: float = 1.0
const STILL_TOLERANCE_M: float = 0.06
const SETTLED_TOLERANCE_M: float = 0.001
const RUN_MIN_DISTANCE_M: float = 60.0
const HUGE_BUDGET_MS: float = 1.0e9
const EAST_YAW_DEGREES: float = -90.0
const YAW_TOLERANCE: float = 0.001
const SETTLE_FRAMES: int = 20
const STILL_FRAMES: int = 120
const STOP_FRAMES: int = 8
const REPORT_FRAMES: int = 7
const FAR_AWAY_POSITION: Vector3 = Vector3(900.0, 10.0, 100.0)
const SLIDE_TOLERANCE_M: float = 0.05

var _boost: PhysicsBoost = PhysicsBoost.new()
var _terrain: TerrainData
var _host: SimulationHostNode
var _bridge: SimBridge
var _view: TerrainView
var _reference: Node3D


func before_all() -> void:
	await _boost.enable(get_tree())
	var loaded: TerrainLoader.LoadResult = TerrainLoader.load_dir(BLOCKOUT_DIR)
	assert_true(loaded.result.ok, loaded.result.message)
	_terrain = loaded.terrain
	_host = SimulationHostNode.new()
	_host.start_new_game(WORLD_SEED, _terrain)
	_bridge = SimBridge.new(_host, _terrain)
	_reference = Node3D.new()
	add_child(_reference)
	_view = TerrainView.new()
	add_child(_view)
	_view.setup(_bridge)
	_focus_on(_bridge.peek_spawn_point().point)


func after_all() -> void:
	_host.runner.finish()
	_host.free()
	_view.free()
	_reference.free()
	await _boost.restore(get_tree())


func before_each() -> void:
	_host.start_new_game(WORLD_SEED, _terrain)
	_reference.rotation_degrees = Vector3(0.0, EAST_YAW_DEGREES, 0.0)


func after_each() -> void:
	for action: StringName in InputActions.ALL:
		Input.action_release(action)


func _focus_on(point: Vector3) -> void:
	_view.set_focus(point)
	_view.process_budget(HUGE_BUDGET_MS)


func _new_body(bridge: SimBridge = _bridge) -> PlayerBody:
	var body: PlayerBody = PlayerBody.new()
	add_child_autofree(body)
	assert_true(body.setup(bridge, _view, _reference))
	return body


func _frames(count: int) -> void:
	for _frame: int in range(count):
		await get_tree().physics_frame


func _stored(body: PlayerBody) -> BridgeReplies.CharacterReply:
	return _bridge.peek_character(body.get_actor_id())


func test_the_body_is_born_in_the_simulation_at_the_spawn_point_and_reports_its_birth() -> void:
	var spawn: Vector3 = _bridge.peek_spawn_point().point
	var body: PlayerBody = _new_body()
	assert_gt(body.get_actor_id(), IdGenerator.NO_ID, "O corpo guardou o ID do personagem que a simulação criou.")
	var stored: BridgeReplies.CharacterReply = _stored(body)
	assert_true(stored.result.ok, stored.result.message)
	assert_almost_eq(stored.position.x, spawn.x, SETTLED_TOLERANCE_M, "Nasce no x do ponto de nascimento.")
	assert_almost_eq(stored.position.z, spawn.z, SETTLED_TOLERANCE_M, "Nasce no z do ponto de nascimento.")
	assert_almost_eq(stored.position.y, spawn.y + PlayerBody.SPAWN_CLEARANCE_M, SETTLED_TOLERANCE_M, "Relata a altura real do corpo.")
	assert_almost_eq(stored.yaw, deg_to_rad(EAST_YAW_DEGREES), YAW_TOLERANCE, "O giro relatado é o do nó de referência (a câmera).")


func test_a_ten_second_scripted_run_keeps_the_stored_position_close_to_the_capsule() -> void:
	var body: PlayerBody = _new_body()
	await _frames(SETTLE_FRAMES)
	var start: Vector3 = body.global_position
	Input.action_press(InputActions.MOVE_FORWARD)
	Input.action_press(InputActions.RUN)
	var worst_gap_m: float = 0.0
	var sample_count: int = 0
	for frame: int in range(RUN_SECONDS * FRAMES_PER_SECOND):
		await get_tree().physics_frame
		if frame % SAMPLE_EVERY_FRAMES == 0:
			_focus_on(body.global_position)
		var stored: BridgeReplies.CharacterReply = _stored(body)
		worst_gap_m = maxf(worst_gap_m, (stored.position - body.global_position).length())
		sample_count += 1
	Input.action_release(InputActions.MOVE_FORWARD)
	Input.action_release(InputActions.RUN)
	assert_gt(sample_count, 0)
	assert_lte(worst_gap_m, REPORT_TOLERANCE_M, "A pior diferença entre a posição guardada e a da cápsula foi %s m." % str(worst_gap_m))
	assert_gt(body.global_position.x - start.x, RUN_MIN_DISTANCE_M, "O corpo correu de verdade (o teste não é vazio): %s m." % str(body.global_position.x - start.x))
	await _frames(STOP_FRAMES)
	var final_gap: Vector3 = _stored(body).position - body.global_position
	assert_lte(final_gap.length(), STILL_TOLERANCE_M, "Parado, o último relato coincide com a cápsula.")


func test_without_movement_the_stored_position_stays_at_the_birth_point() -> void:
	var spawn: Vector3 = _bridge.peek_spawn_point().point
	var body: PlayerBody = _new_body()
	await _frames(STILL_FRAMES)
	var stored: BridgeReplies.CharacterReply = _stored(body)
	assert_almost_eq(stored.position.x, spawn.x, SETTLED_TOLERANCE_M)
	assert_almost_eq(stored.position.z, spawn.z, SETTLED_TOLERANCE_M)
	assert_almost_eq(stored.position.y, spawn.y, STILL_TOLERANCE_M, "Só a folga de nascimento (5 cm) pode diferenciar a altura.")


func test_the_report_changes_the_state_hash_while_the_body_walks_and_not_while_it_is_still() -> void:
	var body: PlayerBody = _new_body()
	await _frames(STILL_FRAMES)
	var still_hash: String = _host.runner.world.state_hash()
	await _frames(STILL_FRAMES)
	assert_eq(_host.runner.world.state_hash(), still_hash, "Parado, o relato repete o mesmo valor e o hash não muda.")
	Input.action_press(InputActions.MOVE_FORWARD)
	await _frames(FRAMES_PER_SECOND)
	Input.action_release(InputActions.MOVE_FORWARD)
	await _frames(REPORT_FRAMES)
	assert_ne(_host.runner.world.state_hash(), still_hash, "Andando, a posição relatada mudou e o hash também.")
	assert_gt(_stored(body).position.x, _bridge.peek_spawn_point().point.x + 1.0)


func test_changing_the_stored_position_does_not_move_the_capsule() -> void:
	var body: PlayerBody = _new_body()
	await _frames(SETTLE_FRAMES)
	var before: Vector3 = body.global_position
	var forced: Result = _bridge.request_report_position(body.get_actor_id(), FAR_AWAY_POSITION, 0.0)
	assert_true(forced.ok, forced.message)
	assert_eq(_stored(body).position, FAR_AWAY_POSITION, "A simulação guardou o valor forçado.")
	assert_eq(body.global_position, before, "A cápsula não se mexeu: quem manda na posição é a física da apresentação.")
	await _frames(REPORT_FRAMES)
	assert_almost_eq(body.global_position.x, before.x, SLIDE_TOLERANCE_M, "Nem depois dos relatos seguintes.")
	assert_almost_eq(body.global_position.z, before.z, SLIDE_TOLERANCE_M)
	assert_almost_eq(_stored(body).position.x, before.x, SLIDE_TOLERANCE_M, "O relato seguinte do corpo sobrescreveu o valor forçado.")


func test_a_bridge_without_a_game_leaves_the_body_walking_without_reporting() -> void:
	var alone: SimBridge = SimBridge.new(null, _terrain)
	var body: PlayerBody = _new_body(alone)
	assert_true(body.is_spawned())
	assert_eq(body.get_actor_id(), IdGenerator.NO_ID, "Sem jogo na simulação o corpo não tem personagem.")
	assert_push_warning("o personagem não nasceu na simulação")
	assert_push_warning_count(1, "Sem personagem não há conta a abrir (LW-105e): nenhum aviso a mais.")
	await _frames(SETTLE_FRAMES)
	var start: Vector3 = body.global_position
	Input.action_press(InputActions.MOVE_FORWARD)
	await _frames(FRAMES_PER_SECOND)
	Input.action_release(InputActions.MOVE_FORWARD)
	assert_gt(body.global_position.x - start.x, 1.0, "O corpo anda do mesmo jeito.")


func test_a_refused_report_warns_once_and_does_not_stop_the_body() -> void:
	var body: PlayerBody = _new_body()
	await _frames(SETTLE_FRAMES)
	_host.start_new_game(WORLD_SEED, _terrain)
	var start: Vector3 = body.global_position
	Input.action_press(InputActions.MOVE_FORWARD)
	await _frames(FRAMES_PER_SECOND * 2)
	Input.action_release(InputActions.MOVE_FORWARD)
	assert_gt(body.global_position.x - start.x, 1.0, "Relatos recusados (o mundo trocou) não travam o corpo.")
	assert_push_warning("relato de posição recusado")
	assert_push_warning_count(1, "Um aviso por código de falha, não um por relato.")
