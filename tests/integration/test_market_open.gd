extends GutTest
## LW-106e: abrir o mercado pela tecla `interact` (E) e a tela montada na cena principal (contrato em docs/modules/presentation.md, "Interface de mercado (LW-106)"), sem janela. A cena REAL (res://scenes/main.tscn, com a `MarketView`
## criada e ligada pela `MainWorldView`) é montada sobre o jogo real de res://data (terreno, locais, pontos e economia) e a ponte real, sem o módulo `npc` (nenhum NPC por perto), como em `test_npc_bodies_in_game.gd`: um GameApp de
## teste no lugar do autoload. O mundo é do teste (o relógio não anda sozinho); o jogador é posto à mão e a posição é relatada pela ponte. Confere: o aviso e a tecla oferecem o mercado SÓ sem ponto nem NPC ao alcance (nos 3 mercados);
## ponto ou NPC ao alcance mantêm a tecla e o aviso de sempre; a 3,5 m do centro e com o relógio pausado nada abre; E, `ui_cancel` e o botão fecham pelo caminho de entrada de verdade; a view bloqueada não avisa, não consulta e não age;
## a pergunta à ponte se repete no máximo a cada 0,25 s; o `PlayerBody` e a câmera REAIS param com a tela aberta e voltam ao fechar; e abrir, atualizar e fechar não mudam o `state_hash`.

const WORLD_DIR: String = "res://data/world"
const MAIN_SCENE: String = "res://scenes/main.tscn"
const SEED: int = 106
const MARKET_COUNT: int = 3
const KEY_PROMPT: String = "ui.interact_prompt"
const KEY_MARKET_PROMPT: String = "ui.market.prompt"
const KEY_TOO_FAR: String = "ui.interact_too_far"
const ACTION_CANCEL: StringName = &"ui_cancel"
const CLOSE_BUTTON: String = "MarketClose"
const TOO_FAR_M: float = 3.5
const EAST_M: float = 2.0
const POINT_WEST_M: float = 2.5
const POINT_ID: String = "test_beside_the_market"
const POINT_TEXT_KEY: String = "poi.test_marker_near"
const NPC_ID: int = 7
const WALK_FRAMES: int = 30
const GROUND_WAIT_FRAMES: int = 300
const MIN_WALK_M: float = 1.0

var _terrain: TerrainData
var _places: Array[Place] = []
var _markets: Array[Place] = []
var _points: Array[PointOfInterest] = []
var _economy: EconomySetup
var _texts: UiText
var _host: SimulationHostNode
var _bridge: CountingBridge
var _stub: StubApp
var _real_app: Node
var _real_index: int = 0
var _main: Node
var _view: InteractionView
var _market: MarketView
var _player: PlayerBody
var _prompt: Label
var _result: Label
var _requested: Array[int] = []


## GameApp de teste: entrega a ponte do teste e NÃO inicia jogo nenhum (o `_ready` do autoload recomeçaria o mundo do autoload).
class StubApp:
	extends GameAppNode

	var stub_bridge: SimBridge

	func _ready() -> void:
		pass

	func peek_bridge() -> SimBridge:
		return stub_bridge


## Ponte que conta as perguntas pelo mercado ao alcance.
class CountingBridge:
	extends SimBridge

	var queries: int = 0

	func peek_market_in_reach(actor_id: int) -> BridgePlayerEconomyReplies.MarketInReachReply:
		queries += 1
		return super(actor_id)


## Corpos de NPC de mentira: o NPC `NPC_ID` parado onde a reserva o pôs.
class FakeBodies:
	extends NpcBodiesView

	var fake_pool: NpcViewPool

	func active_ids() -> Array[int]:
		return fake_pool.active_ids()

	func pool() -> NpcViewPool:
		return fake_pool


func before_all() -> void:
	var terrain: TerrainLoader.LoadResult = TerrainLoader.load_dir(WORLD_DIR)
	assert_true(terrain.result.ok, terrain.result.message)
	_terrain = terrain.terrain
	var settlements: SettlementLoader.LoadResult = SettlementLoader.load_dir(WORLD_DIR, _terrain)
	assert_true(settlements.result.ok, settlements.result.message)
	_places = settlements.places
	for place: Place in _places:
		if place.kind == Place.KIND_MARKET:
			_markets.append(place)
	assert_eq(_markets.size(), MARKET_COUNT, "Pré-condição dos dados: três mercados.")
	var points: PointOfInterestLoader.LoadResult = PointOfInterestLoader.load_dir(WORLD_DIR, _terrain)
	assert_true(points.result.ok, points.result.message)
	_points = points.points
	_economy = EconomySetup.from_dir(EconomySetup.DEFAULT_DIR)
	assert_true(_economy.result.ok, _economy.result.message)
	var texts: UiText.LoadResult = UiText.from_file(UiText.DEFAULT_PATH)
	assert_true(texts.result.ok, texts.result.message)
	_texts = texts.texts


func after_each() -> void:
	Input.action_release(InputActions.MOVE_FORWARD)
	if _main != null and is_instance_valid(_main):
		if _main.is_inside_tree():
			_main.get_parent().remove_child(_main)
		_main.free()
	if _stub != null:
		get_tree().root.remove_child(_stub)
		_stub.free()
		get_tree().root.add_child(_real_app)
		get_tree().root.move_child(_real_app, _real_index)
	if _host != null:
		_host.runner.finish()
		_host.free()
	_main = null
	_stub = null
	_host = null


## O jogo real e a cena principal montada sobre ele, com `extra` pontos de interesse a mais; o corpo do jogador fica parado (a física só liga onde o teste a quer) e os pedidos de mercado são anotados.
func _start(extra: Array[PointOfInterest] = []) -> void:
	var points: Array[PointOfInterest] = _points.duplicate()
	points.append_array(extra)
	_host = SimulationHostNode.new()
	_host.start_new_game(SEED, _terrain, points, null, 0, _economy)
	_bridge = CountingBridge.new(_host, _terrain, _places)
	_stub = StubApp.new()
	_stub.name = "GameApp"
	_stub.stub_bridge = _bridge
	_real_app = get_tree().root.get_node("GameApp")
	_real_index = _real_app.get_index()
	get_tree().root.remove_child(_real_app)
	get_tree().root.add_child(_stub)
	_main = (load(MAIN_SCENE) as PackedScene).instantiate()
	add_child(_main)
	assert_push_error(SimBridge.CODE_NO_NPC)
	_view = _main.get_node("InteractionView") as InteractionView
	_market = _main.get_node("MarketView") as MarketView
	_player = _main.get_node("PlayerBody") as PlayerBody
	_prompt = _main.get_node("HUD/InteractionPrompt") as Label
	_result = _main.get_node("HUD/InteractionText") as Label
	_player.set_physics_process(false)
	_requested.clear()
	_view.market_requested.connect(func(market_id: int) -> void: _requested.append(market_id))


## Põe o jogador em `spot` (o corpo e o relato à simulação) e deixa o aviso em dia: passa o tempo da pergunta pelo mercado e a view atualiza.
func _stand_at(spot: Vector3) -> void:
	_player.global_position = spot
	assert_true(_bridge.request_report_position(_player.get_actor_id(), spot, 0.0).ok)
	_view.tick(InteractionView.MARKET_QUERY_INTERVAL_S)
	_view.refresh()


func _prompt_of(key: String) -> String:
	return _texts.get_text(key, {"key": "E"})


func _market_id_of(market: Place) -> int:
	return _host.economy.peek_market_of(market.settlement_id).market_id


## Aperta e solta a ação pelo caminho de entrada de verdade (`_input` e depois `_unhandled_input` de toda a árvore; a Godot entrega os eventos no começo do quadro seguinte, então deixa passar dois quadros).
func _press(action: StringName) -> void:
	var event: InputEventAction = InputEventAction.new()
	event.action = action
	event.pressed = true
	Input.parse_input_event(event)
	var release: InputEventAction = event.duplicate() as InputEventAction
	release.pressed = false
	Input.parse_input_event(release)
	await wait_process_frames(2)


## Quanto o jogador andou (m, no plano) segurando `move_forward` por WALK_FRAMES quadros de física.
func _walked_m() -> float:
	var start: Vector3 = _player.global_position
	Input.action_press(InputActions.MOVE_FORWARD)
	await wait_physics_frames(WALK_FRAMES)
	Input.action_release(InputActions.MOVE_FORWARD)
	return Vector2(_player.global_position.x - start.x, _player.global_position.z - start.z).length()


func test_at_each_market_center_without_point_or_npc_the_prompt_and_the_key_offer_that_market() -> void:
	_start()
	for market: Place in _markets:
		_stand_at(market.position)
		assert_eq([_prompt.visible, _prompt.text, _view.nearest_point_id()], [true, _prompt_of(KEY_MARKET_PROMPT), ""], "Aviso do mercado no centro de %s." % market.id)
		assert_true(_view.interact())
		assert_eq(_requested, [_market_id_of(market)] as Array[int], "O E pede o mercado de %s." % market.id)
		assert_true(_market.is_open(), "Ligada à tela, a tecla a abre.")
		assert_false(_prompt.visible, "Com a tela aberta o aviso some.")
		_market.close()
		_requested.clear()


func test_far_from_the_center_or_with_the_clock_paused_the_key_does_not_open_the_market() -> void:
	_start()
	_stand_at(_markets[0].position + Vector3(TOO_FAR_M, 0.0, 0.0))
	assert_false(_prompt.visible, "A 3,5 m do centro não há aviso do mercado.")
	assert_false(_view.interact())
	assert_eq([_result.text, _requested, _market.is_open()], [_texts.get_text(KEY_TOO_FAR), [] as Array[int], false], "A tecla cai no comportamento de hoje: o texto de `chegue mais perto`.")
	_stand_at(_markets[0].position)
	assert_true(_bridge.request_pause(true).ok)
	assert_false(_view.interact(), "Pausado, não abre.")
	assert_eq([_requested, _market.is_open()], [[] as Array[int], false])
	assert_true(_bridge.request_pause(false).ok)
	assert_true(_view.interact(), "Despausado, o mesmo E abre.")


func test_a_point_of_interest_in_reach_keeps_the_key_and_the_prompt_and_the_market_returns_after_leaving_it() -> void:
	var center: Vector3 = _markets[0].position
	_start([PointOfInterest.new(POINT_ID, "marker", center - Vector3(POINT_WEST_M, 0.0, 0.0), POINT_TEXT_KEY)] as Array[PointOfInterest])
	_stand_at(center)
	assert_eq([_prompt.text, _view.nearest_point_id()], [_prompt_of(KEY_PROMPT), POINT_ID], "Com o ponto ao alcance o aviso é o dele, o do mercado some.")
	assert_true(_view.interact(), "O E interage com o ponto.")
	assert_eq([_result.text, _requested, _market.is_open()], [_texts.get_text(POINT_TEXT_KEY), [] as Array[int], false], "E não abre o mercado.")
	_stand_at(center + Vector3(EAST_M, 0.0, 0.0))
	assert_eq([_prompt.text, _view.nearest_point_id()], [_prompt_of(KEY_MARKET_PROMPT), ""], "Fora do alcance do ponto, o mercado volta a ser oferecido.")
	assert_true(_view.interact())
	assert_eq(_requested, [_market_id_of(_markets[0])] as Array[int])


func test_an_npc_in_reach_keeps_the_key_and_the_prompt() -> void:
	_start()
	var bodies: FakeBodies = FakeBodies.new()
	add_child_autofree(bodies)
	bodies.fake_pool = NpcViewPool.new(bodies, 1)
	assert_not_null(bodies.fake_pool.take(NPC_ID, _markets[0].position))
	_view.set_npc_bodies(bodies)
	_stand_at(_markets[0].position)
	assert_eq(_prompt.text, _prompt_of(KEY_PROMPT), "Com o NPC ao alcance o aviso é o de sempre.")
	_view.interact()
	assert_eq([_requested, _market.is_open()], [[] as Array[int], false], "O E é do NPC, não do mercado.")


func test_the_market_is_asked_at_most_every_quarter_second_never_when_blocked_and_the_key_asks_again() -> void:
	_start()
	_stand_at(_markets[0].position)
	var asked: int = _bridge.queries
	for _round: int in 10:
		_view.refresh()
	assert_eq(_bridge.queries, asked, "Dentro dos 0,25 s vale o último resultado.")
	_view.tick(InteractionView.MARKET_QUERY_INTERVAL_S)
	_view.refresh()
	assert_eq(_bridge.queries, asked + 1, "Passados 0,25 s, pergunta de novo.")
	_view.set_blocked(true)
	_view.tick(1.0)
	_view.refresh()
	assert_false(_view.interact())
	assert_eq([_bridge.queries, _prompt.visible, _requested], [asked + 1, false, [] as Array[int]], "Bloqueada: não pergunta, não avisa e a tecla não faz nada.")
	_view.set_blocked(false)
	assert_true(_view.interact())
	assert_eq(_bridge.queries, asked + 2, "A tecla pergunta de novo na hora, sem usar o último resultado.")


func test_the_keys_open_and_close_the_screen_in_the_real_scene_and_the_state_hash_does_not_change() -> void:
	_start()
	_stand_at(_markets[0].position)
	var before: String = _host.runner.world.state_hash()
	for closer: StringName in [ACTION_CANCEL, InputActions.INTERACT, &""]:
		await _press(InputActions.INTERACT)
		assert_true(_market.is_open(), "O E abre a tela.")
		assert_false(_prompt.visible, "Aberta, o aviso some.")
		_market.refresh()
		if closer.is_empty():
			(_market.find_child(CLOSE_BUTTON, true, false) as Button).pressed.emit()
			await wait_process_frames(1)
		else:
			await _press(closer)
		assert_false(_market.is_open(), "Fechada por '%s' (o mesmo E não a reabre)." % closer)
		assert_true(_prompt.visible, "Fechada, o aviso do mercado volta.")
	assert_eq(_host.runner.world.state_hash(), before, "Abrir, atualizar e fechar não mudam o `state_hash`.")


func test_the_real_player_and_camera_stop_while_the_screen_is_open_and_come_back_on_close() -> void:
	_start()
	var camera: ThirdPersonCamera = _main.get_node("Camera") as ThirdPersonCamera
	var terrain: TerrainView = _main.get_node("TerrainView") as TerrainView
	var modes: Array[Node.ProcessMode] = [_player.process_mode, camera.process_mode]
	_player.set_physics_process(true)
	_stand_at(_markets[0].position)
	for _frame: int in GROUND_WAIT_FRAMES:
		if terrain.has_collision_at(_player.global_position):
			break
		await wait_physics_frames(1)
	assert_true(terrain.has_collision_at(_player.global_position), "O chão sob o jogador foi construído.")
	assert_gt(await _walked_m(), MIN_WALK_M, "Controle: com a tela fechada o jogador anda.")
	_stand_at(_markets[0].position)
	assert_true(_view.interact())
	assert_eq([_player.process_mode, camera.process_mode], [Node.PROCESS_MODE_DISABLED, Node.PROCESS_MODE_DISABLED] as Array[Node.ProcessMode], "Aberta a tela, os dois ficam desligados.")
	assert_eq(await _walked_m(), 0.0, "E o jogador não anda ao empurrar `move_forward`.")
	_market.close()
	assert_eq([_player.process_mode, camera.process_mode], modes, "Ao fechar, voltam ao valor anterior.")
	assert_gt(await _walked_m(), MIN_WALK_M, "E o jogador volta a andar.")
