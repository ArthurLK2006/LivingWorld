extends GutTest
## ART-12, 7b-2: o `NpcBodyDriver` passa ao corpo, junto do andar, a velocidade do quadro (`NpcRoute.speed_mps`, a mesma com que ele anda): 4 m/s a 1x, 8 a 2x e 0 em pausa. Com o jogo montado como o real (100 NPCs, ponte real, corpos do pool de verdade), como no `test_npc_body_driver`; a cápsula só guarda a velocidade (quem a usa é a figura).

const DATA_DIR: String = "res://data"
const WORLD_SEED: int = 5
const A_M: Vector3 = Vector3(320.0, 10.0, 540.0)
## Longe dos três povoados (o raio de saída do S0 é de 120 m).
const FAR_M: Vector3 = Vector3(700.0, 10.0, 960.0)
const ARRIVAL_MINUTE: int = 6 * 60 + 50
const PHYSICS_DELTA: float = 1.0 / 60.0
## Um minuto de jogo dura 1,25 s reais a 1x: 75 quadros de física a 60 Hz.
const FRAMES_PER_MINUTE: int = 75
const WARM_MINUTES: int = 10
const SETTLE_FRAMES: int = 3

var _data: NpcLifeCheck.GameData
var _host: SimulationHostNode
var _bridge: SimBridge
var _bodies: NpcBodiesView
var _driver: NpcBodyDriver


func before_all() -> void:
	_data = NpcLifeCheck.load_game_data()
	assert_eq(_data.problem, "", "Os dados reais do jogo carregam.")


func after_each() -> void:
	if _bodies != null:
		_bodies.release()
	if _host != null:
		_host.runner.finish()
		_host.free()
	_bodies = null
	_host = null


## Jogo novo, corpos, motorista e o jogador longe até as 6h50, quando chega a A (os 50 mais perto ganham corpo e às 7h saem de casa).
func _start() -> void:
	var setup: NpcSetup = NpcSetup.from_dir(DATA_DIR, SettlementService.new(_data.settlements, _data.places))
	assert_true(setup.result.ok, setup.result.message)
	_host = SimulationHostNode.new()
	_host.start_new_game(WORLD_SEED, _data.terrain, _data.points, setup)
	_bridge = SimBridge.new(_host, _data.terrain, _data.places, _host.npc)
	var terrain_view: TerrainView = TerrainView.new()
	add_child_autofree(terrain_view)
	terrain_view.setup(_bridge)
	terrain_view.set_process(false)
	_bodies = NpcBodiesView.new()
	add_child_autofree(_bodies)
	assert_true(_bodies.setup(_bridge, terrain_view))
	_driver = NpcBodyDriver.new()
	add_child_autofree(_driver)
	assert_true(_driver.setup(_bridge, _bodies))
	var actor_id: int = _bridge.request_spawn_character().actor_id
	assert_true(_bridge.request_report_position(actor_id, FAR_M, 0.0).ok)
	_host.runner.run_steps(ARRIVAL_MINUTE)
	assert_true(_bridge.request_report_position(actor_id, A_M, 0.0).ok)


func _frames(count: int) -> void:
	for _frame: int in count:
		_driver.advance(PHYSICS_DELTA)


## O jogo em miniatura: por minuto de jogo, um passo da simulação, os corpos em dia e os quadros de física do minuto.
func _drive(minutes: int) -> void:
	for _minute: int in minutes:
		_host.runner.step_once()
		_bodies.reconcile()
		_frames(FRAMES_PER_MINUTE)


## O corpo com trabalho em curso e mais caminho pela frente (para não chegar durante o teste).
func _farthest_walker() -> NpcView:
	var best: float = 0.0
	var farthest: NpcView = null
	for intent: BridgeReplies.NpcIntentReply in _bridge.peek_pending_npc_intents().intents:
		var view: NpcView = _bodies.pool().body_of(intent.npc_id)
		if view == null or _driver.job_serial_of(intent.npc_id) != intent.action_serial:
			continue
		var remaining_m: float = Vector2(view.position.x - intent.destination.x, view.position.z - intent.destination.z).length()
		if remaining_m > best:
			best = remaining_m
			farthest = view
	return farthest


func test_the_driver_passes_the_body_speed_of_the_clock_and_zero_when_paused() -> void:
	_start()
	_drive(WARM_MINUTES)
	var view: NpcView = _farthest_walker()
	assert_not_null(view, "Há um corpo a caminho.")
	assert_eq([view.is_walking(), view.speed_mps()], [true, 4.0], "1x: andando a 4 m/s.")
	assert_true(_bridge.request_speed(2).ok)
	_frames(SETTLE_FRAMES)
	assert_eq([view.is_walking(), view.speed_mps()], [true, 8.0], "2x: 8 m/s.")
	assert_true(_bridge.request_pause(true).ok)
	_frames(SETTLE_FRAMES)
	assert_eq([view.is_walking(), view.speed_mps()], [false, 0.0], "Pausado: parado e 0 m/s.")
