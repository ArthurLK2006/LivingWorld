extends GutTest
## LW-052: teste de integração scriptado da Fase 1, sem janela, com o MESMO mundo do jogo (GameModules, terreno e pontos reais) e os nós da
## cena principal montados como a cena os monta (TerrainView, PlayerBody, ThirdPersonCamera, InteractionView, HudView). Sem código novo de jogo.
##   Cenário A (um caminho só): nasce no ponto certo, anda por entrada scriptada até o ponto de interesse próximo, interage (evento
##   InteractionPerformed e texto da chave), pausa (relógio, corpo e relato congelam), salva (capture_game + codec JSON), carrega num
##   runner NOVO e confere hash e posição.
##   Cenário B: 30 dias simulados com o jogador parado, invariantes e hash final; duas execuções completas dão o MESMO hash, e salvar e
##   carregar no meio também.
##   Cenário C: a contagem de nós da cena fica estável (depois de N quadros e depois de andar e voltar).
## O relógio do motor é acelerado como em tests/unit/test_player_body.gd (PhysicsBoost). A simulação é avançada à mão, um quadro de 1/60 s por
## quadro de física (o host do teste não está na árvore). Valores esperados escritos à mão a partir do envio.

const BLOCKOUT_DIR: String = "res://data/world"
const WORLD_SEED: int = 11
const FRAMES_PER_SECOND: int = 60
const FRAME_SECONDS: float = 1.0 / 60.0
const SECONDS_PER_MINUTE: float = SimClock.DEFAULT_REAL_MS_PER_MINUTE / 1000.0
const HUGE_BUDGET_MS: float = 1.0e9
const EAST_YAW_DEGREES: float = -90.0
const WEST_YAW_DEGREES: float = 90.0
const SETTLE_FRAMES: int = 20
const REPORT_FRAMES: int = 8
const FOCUS_EVERY_FRAMES: int = 20
const MAX_WALK_FRAMES: int = 900
const STOP_DISTANCE_M: float = 2.0
const SPAWN_TOLERANCE_M: float = 0.001
const REPORT_TOLERANCE_M: float = 1.0
const FROZEN_TOLERANCE_M: float = 0.0001
const PAUSED_SECONDS: int = 3
const GAME_VERSION: String = "0.0.1-test"
const DAYS: int = 30
const HALF_DAYS: int = 15
const STILL_FRAMES: int = 120
const OUT_AND_BACK_SECONDS: int = 6
const NODE_SETTLE_FRAMES: int = 4
## [HIP] Folga de nós que a histerese do terreno pode deixar a mais depois da primeira ida e volta, e quantas idas e voltas extras repetir.
const HYSTERESIS_MARGIN_NODES: int = 16
const EXTRA_TRIPS: int = 2
const NEAR_ID: String = "test_marker_near"
const EVENT_TYPE: String = "InteractionPerformed"

var _boost: PhysicsBoost = PhysicsBoost.new()
var _terrain: TerrainData
var _points: Array[PointOfInterest] = []
var _texts: UiText
var _codec: JsonSaveCodec = JsonSaveCodec.new()
var _host: SimulationHostNode
var _bridge: SimBridge
var _modules_root: Node3D
var _ui_root: Node
var _reference: Node3D
var _view: TerrainView
var _body: PlayerBody
var _camera: ThirdPersonCamera
var _interaction: InteractionView
var _hud: HudView
var _prompt: Label
var _result: Label
var _received: Array[InteractionPerformed] = []


func before_all() -> void:
	await _boost.enable(get_tree())
	var terrain_loaded: TerrainLoader.LoadResult = TerrainLoader.load_dir(BLOCKOUT_DIR)
	assert_true(terrain_loaded.result.ok, terrain_loaded.result.message)
	_terrain = terrain_loaded.terrain
	var points_loaded: PointOfInterestLoader.LoadResult = PointOfInterestLoader.load_dir(BLOCKOUT_DIR, _terrain)
	assert_true(points_loaded.result.ok, points_loaded.result.message)
	_points = points_loaded.points
	var texts_loaded: UiText.LoadResult = UiText.from_file(UiText.DEFAULT_PATH)
	assert_true(texts_loaded.result.ok, texts_loaded.result.message)
	_texts = texts_loaded.texts


func after_all() -> void:
	await _boost.restore(get_tree())


func after_each() -> void:
	for action: StringName in InputActions.ALL:
		Input.action_release(action)
	if _host != null:
		_host.runner.finish()
		_host.free()
		_host = null
	if _modules_root != null:
		_modules_root.free()
		_modules_root = null
	if _ui_root != null:
		_ui_root.free()
		_ui_root = null


## Monta o mundo do jogo e a cena: o host com terreno e pontos (GameModules), a ponte e os nós da cena principal, ligados como o
## MainWorldView os liga.
func _build_world_and_scene() -> void:
	_received.clear()
	_host = SimulationHostNode.new()
	_host.start_new_game(WORLD_SEED, _terrain, _points)
	_bridge = SimBridge.new(_host, _terrain)
	_host.runner.world.context.events.subscribe(EVENT_TYPE, _on_interaction)
	_modules_root = Node3D.new()
	add_child(_modules_root)
	_ui_root = Node.new()
	add_child(_ui_root)
	_reference = Node3D.new()
	_reference.rotation_degrees = Vector3(0.0, EAST_YAW_DEGREES, 0.0)
	_modules_root.add_child(_reference)
	_view = TerrainView.new()
	_modules_root.add_child(_view)
	_view.setup(_bridge)
	_view.set_focus(_bridge.peek_spawn_point().point)
	_view.process_budget(HUGE_BUDGET_MS)
	_body = PlayerBody.new()
	_modules_root.add_child(_body)
	assert_true(_body.setup(_bridge, _view, _reference))
	_camera = ThirdPersonCamera.new()
	_modules_root.add_child(_camera)
	assert_true(_camera.setup(_bridge, _body))
	_prompt = Label.new()
	_result = Label.new()
	_ui_root.add_child(_prompt)
	_ui_root.add_child(_result)
	_interaction = InteractionView.new()
	_modules_root.add_child(_interaction)
	assert_true(_interaction.setup(_bridge, _body, _view, _texts, _prompt, _result))
	var status: Label = Label.new()
	_ui_root.add_child(status)
	_hud = HudView.new()
	status.add_child(_hud)
	assert_true(_hud.setup(_bridge, _texts, "Living World", GAME_VERSION))


func _on_interaction(event: SimEvent) -> void:
	_received.append(event as InteractionPerformed)


## Um quadro de física por vez; a simulação avança com o tempo do quadro (pausa e velocidade valem).
func _frames(count: int) -> void:
	for frame: int in range(count):
		await get_tree().physics_frame
		_host.advance(FRAME_SECONDS)
		if frame % FOCUS_EVERY_FRAMES == 0:
			_view.set_focus(_body.global_position)
			_view.process_budget(HUGE_BUDGET_MS)


func _stored_position() -> Vector3:
	return _bridge.peek_character(_body.get_actor_id()).position


func _total_minutes() -> int:
	return _bridge.peek_time().total_minutes


func _near_point() -> PointOfInterest:
	for point: PointOfInterest in _points:
		if point.id == NEAR_ID:
			return point
	return null


func _horizontal_distance_to(point: PointOfInterest) -> float:
	return Vector2(_body.global_position.x - point.position.x, _body.global_position.z - point.position.z).length()


# ---------------------------------------------------------------- cenário A

func test_scenario_a_spawns_walks_to_the_point_interacts_pauses_saves_and_reloads() -> void:
	_build_world_and_scene()
	# 1. Nasce no ponto certo, e a simulação já sabe onde.
	var spawn: Vector3 = _bridge.peek_spawn_point().point
	assert_gt(_body.get_actor_id(), IdGenerator.NO_ID, "O corpo nasceu na simulação.")
	assert_almost_eq(_body.global_position.x, spawn.x, SPAWN_TOLERANCE_M, "Nasce no x do ponto de nascimento.")
	assert_almost_eq(_body.global_position.z, spawn.z, SPAWN_TOLERANCE_M, "Nasce no z do ponto de nascimento.")
	assert_almost_eq(_stored_position().x, spawn.x, SPAWN_TOLERANCE_M)
	await _frames(SETTLE_FRAMES)
	assert_false(_prompt.visible, "No nascimento (a cerca de 20 m) não há aviso.")
	# 2. Anda por entrada scriptada (ações, como nos testes da LW-045) até ficar a menos de 2 m do ponto próximo.
	var near: PointOfInterest = _near_point()
	assert_not_null(near)
	Input.action_press(InputActions.MOVE_FORWARD)
	var walked_frames: int = 0
	while _horizontal_distance_to(near) > STOP_DISTANCE_M and walked_frames < MAX_WALK_FRAMES:
		await _frames(1)
		walked_frames += 1
	Input.action_release(InputActions.MOVE_FORWARD)
	assert_lt(walked_frames, MAX_WALK_FRAMES, "Chegou ao ponto andando (%d quadros)." % walked_frames)
	await _frames(REPORT_FRAMES)
	assert_lte((_stored_position() - _body.global_position).length(), REPORT_TOLERANCE_M, "A simulação sabe onde o corpo parou.")
	_interaction.refresh()
	assert_true(_prompt.visible, "Perto do ponto o aviso aparece.")
	assert_eq(_prompt.text, "[E] Interagir")
	# 3. Interage: o texto da chave aparece e o evento é publicado e entregue no passo seguinte.
	assert_true(_interaction.interact())
	assert_true(_result.visible)
	assert_eq(_result.text, _texts.get_text("poi.test_marker_near"), "Aparece o texto da chave do ponto.")
	assert_eq(_received.size(), 0, "O evento só é entregue no dispatch do passo.")
	_host.advance(SECONDS_PER_MINUTE)
	assert_eq(_received.size(), 1)
	assert_eq(_received[0].actor_id, _body.get_actor_id())
	assert_eq(_received[0].poi_id, NEAR_ID)
	assert_eq(_received[0].cause_id, SimEvent.NO_CAUSE)
	# 4. Pausa: relógio, corpo e relato congelam.
	assert_true(_bridge.request_pause(true).ok)
	_hud.refresh()
	assert_string_contains(_hud.text, "PAUSADO")
	var minutes_paused: int = _total_minutes()
	var body_paused: Vector3 = _body.global_position
	var stored_paused: Vector3 = _stored_position()
	Input.action_press(InputActions.MOVE_FORWARD)
	Input.action_press(InputActions.JUMP)
	await _frames(PAUSED_SECONDS * FRAMES_PER_SECOND)
	Input.action_release(InputActions.MOVE_FORWARD)
	Input.action_release(InputActions.JUMP)
	assert_eq(_total_minutes(), minutes_paused, "O relógio da simulação parou.")
	assert_lte((_body.global_position - body_paused).length(), FROZEN_TOLERANCE_M, "O corpo parou.")
	assert_eq(_stored_position(), stored_paused, "O relato parou: a posição guardada não mudou.")
	# 5. Salva (capture_game e o codec JSON) e carrega num runner NOVO, com os mesmos módulos.
	assert_true(_host.runner.can_capture_game(), "Entre passos a fila de eventos está vazia.")
	var hash_saved: String = _host.runner.world.state_hash()
	var decoded: DecodedSave = _codec.decode(_codec.encode(_host.runner.capture_game(), GAME_VERSION))
	assert_true(decoded.result.ok, decoded.result.message)
	var restored: SimulationRunner = SimulationRunner.new(WORLD_SEED)
	var modules: GameModules = GameModules.register(restored, _terrain, _points)
	assert_true(modules.result.ok, modules.result.message)
	var loaded: Result = restored.load_game(decoded.payload)
	assert_true(loaded.ok, loaded.message)
	assert_eq(restored.world.state_hash(), hash_saved, "O mundo carregado tem o mesmo hash.")
	var after_load: CharacterQuery = modules.character.peek_character(_body.get_actor_id())
	assert_true(after_load.result.ok, after_load.result.message)
	assert_eq(after_load.position, stored_paused, "A posição do jogador é a mesma depois de carregar.")
	assert_lte((after_load.position - body_paused).length(), REPORT_TOLERANCE_M, "E bate com a da cápsula.")
	assert_eq(restored.world.validate().size(), 0)
	assert_eq(_host.runner.world.validate().size(), 0)
	restored.finish()


# ---------------------------------------------------------------- cenário B

## Jogo novo com o personagem parado no nascimento e 30 dias simulados; devolve o hash final depois de conferir os invariantes.
func _thirty_days(save_in_the_middle: bool) -> String:
	var runner: SimulationRunner = SimulationRunner.new(WORLD_SEED)
	var modules: GameModules = GameModules.register(runner, _terrain, _points)
	assert_true(modules.result.ok, modules.result.message)
	runner.start_new_game()
	var spawn: SpawnResult = modules.character.request_spawn()
	assert_true(spawn.result.ok, spawn.result.message)
	assert_true(modules.character.report_position(spawn.actor_id, _terrain.peek_spawn_point(), 0.0).ok)
	var active: SimulationRunner = runner
	var active_modules: GameModules = modules
	if save_in_the_middle:
		runner.run_days(HALF_DAYS)
		var decoded: DecodedSave = _codec.decode(_codec.encode(runner.capture_game(), GAME_VERSION))
		assert_true(decoded.result.ok, decoded.result.message)
		var reloaded: SimulationRunner = SimulationRunner.new(WORLD_SEED)
		active_modules = GameModules.register(reloaded, _terrain, _points)
		var loaded: Result = reloaded.load_game(decoded.payload)
		assert_true(loaded.ok, loaded.message)
		runner.finish()
		active = reloaded
		active.run_days(DAYS - HALF_DAYS)
	else:
		active.run_days(DAYS)
	assert_eq(active.world.context.clock.total_minutes(), DAYS * SimClock.MINUTES_PER_DAY, "30 dias simulados.")
	assert_eq(active.world.validate().size(), 0, "world.validate() sem problemas depois de 30 dias: %s" % str(active.world.validate()))
	var stored: CharacterQuery = active_modules.character.peek_character(spawn.actor_id)
	assert_true(stored.result.ok, stored.result.message)
	assert_true(_terrain.peek_height(stored.position.x, stored.position.z).result.ok, "O personagem continua dentro do mapa.")
	assert_eq(stored.position, _terrain.peek_spawn_point(), "Parado, a posição não mudou em 30 dias.")
	assert_true(active.can_capture_game(), "Sem evento pendente no fim.")
	var final_hash: String = active.world.state_hash()
	active.finish()
	return final_hash


func test_scenario_b_thirty_days_with_the_player_standing_still_keep_the_invariants_and_the_hash() -> void:
	var first: String = _thirty_days(false)
	var second: String = _thirty_days(false)
	assert_eq(first.length(), 64, "SHA-256 em hexadecimal.")
	assert_eq(second, first, "Duas execuções completas com a mesma semente dão o MESMO hash.")
	var with_save: String = _thirty_days(true)
	assert_eq(with_save, first, "Salvar e carregar no meio dos 30 dias não muda o resultado.")


# ---------------------------------------------------------------- cenário C

## Nós da cena do teste (a raiz dos módulos e a da interface), contados por recursão.
func _count_nodes(node: Node) -> int:
	var total: int = 1
	for child: Node in node.get_children():
		total += _count_nodes(child)
	return total


func _scene_node_count() -> int:
	return _count_nodes(_modules_root) + _count_nodes(_ui_root)


func _settle_nodes() -> void:
	_view.process_budget(HUGE_BUDGET_MS)
	for _frame: int in range(NODE_SETTLE_FRAMES):
		await get_tree().process_frame


## Anda para o leste, volta pelo oeste, é posto de volta no ponto exato e o terreno é replanejado com o mesmo foco de antes.
func _round_trip(start: Vector3) -> void:
	_reference.rotation_degrees = Vector3(0.0, EAST_YAW_DEGREES, 0.0)
	Input.action_press(InputActions.MOVE_FORWARD)
	await _frames(OUT_AND_BACK_SECONDS * FRAMES_PER_SECOND)
	Input.action_release(InputActions.MOVE_FORWARD)
	assert_gt(_body.global_position.x - start.x, 10.0, "Andou de verdade (o teste não é vazio).")
	_reference.rotation_degrees = Vector3(0.0, WEST_YAW_DEGREES, 0.0)
	Input.action_press(InputActions.MOVE_FORWARD)
	for _frame: int in range(OUT_AND_BACK_SECONDS * FRAMES_PER_SECOND):
		await get_tree().physics_frame
		_host.advance(FRAME_SECONDS)
		if _body.global_position.x <= start.x:
			break
	Input.action_release(InputActions.MOVE_FORWARD)
	_body.global_position = start
	_body.velocity = Vector3.ZERO
	_view.replan_move_m = 0.0
	_view.set_focus(start)
	await _settle_nodes()


func test_scenario_c_the_scene_node_count_is_stable_after_frames_and_after_walking_out_and_back() -> void:
	_build_world_and_scene()
	await _frames(SETTLE_FRAMES)
	await _settle_nodes()
	var start: Vector3 = _body.global_position
	var before: int = _scene_node_count()
	assert_gt(before, 100, "A cena tem os chunks, o jogador, a câmera e a interface (o teste não é vazio).")
	await _frames(STILL_FRAMES)
	await _settle_nodes()
	assert_eq(_scene_node_count(), before, "Depois de %d quadros parado, o número de nós é o mesmo." % STILL_FRAMES)
	# A primeira ida e volta pode deixar alguns chunks a mais: o terreno só descarta além do raio MAIS a histerese, então o que foi
	# carregado no caminho e ficou nessa faixa continua carregado com o mesmo foco (medido em 07/11/2026: 4 chunks e 8 nós a mais).
	await _round_trip(start)
	var after_first: int = _scene_node_count()
	var orphans_after_first: int = int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
	assert_gte(after_first, before, "Voltar ao ponto não descarrega o que a histerese guarda.")
	assert_lte(after_first - before, HYSTERESIS_MARGIN_NODES, "A diferença é só a da histerese: %d nós a mais." % (after_first - before))
	# O que não pode acontecer é crescer a cada ida e volta: da primeira em diante o número de nós e o de órfãos ficam iguais.
	for _trip: int in range(EXTRA_TRIPS):
		await _round_trip(start)
	assert_eq(_scene_node_count(), after_first, "Depois de mais %d idas e voltas o número de nós é o mesmo (nenhum vazamento)." % EXTRA_TRIPS)
	assert_eq(int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)), orphans_after_first, "Nenhum nó órfão novo.")
