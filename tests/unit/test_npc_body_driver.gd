extends GutTest
## LW-072e: o NpcBodyDriver, sem janela, com o jogo montado como o real (100 NPCs, ponte real, `NpcBodiesView` e `TerrainView` de verdade). O jogador chega a A às
## 6h50 e, às 7h, os NPCs saem de casa para o trabalho, a 14 a 58 m. Uma ponte espiã registra o que o motorista relatou. Confere só isso, se o Intent saiu da lista e
## o ok do relato; NÃO que o NPC ficou livre, que o efeito entrou ou quando a próxima ação começou (isso muda com a LW-070d).

const DATA_DIR: String = "res://data"
const WORLD_SEED: int = 5
const A_M: Vector3 = Vector3(320.0, 10.0, 540.0)
## Longe dos três povoados (o C, da LW-097d, fica em 560 m, 860 m; o raio de saída do S0 é de 120 m).
const FAR_M: Vector3 = Vector3(700.0, 10.0, 960.0)
const ARRIVAL_MINUTE: int = 6 * 60 + 50
const PHYSICS_DELTA: float = 1.0 / 60.0
## Um minuto de jogo dura 1,25 s reais a 1x: 75 quadros de física a 60 Hz.
const FRAMES_PER_MINUTE: int = 75
const EDGE_TOLERANCE_M: float = 0.05

var _data: NpcLifeCheck.GameData
var _half_by_place: Dictionary[String, Vector2] = {}
var _host: SimulationHostNode
var _bridge: SpyBridge
var _bodies: NpcBodiesView
var _driver: NpcBodyDriver
var _actor_id: int = 0


## Ponte que registra o que o motorista faz: cada Intent visto (com o minuto), cada resultado relatado (com o retorno e se o Intent ainda estava na lista logo
## depois), o quadro de cada lote de posições e, com `steep`, um terreno íngreme demais para andar (degraus de 5 m a cada 2 m). `forced` troca os retornos.
class SpyBridge:
	extends SimBridge

	var frame: int = 0
	var steep: bool = false
	var seen: Dictionary[String, Dictionary] = {}
	var reports: Array[Dictionary] = []
	var batch_frames: Array[int] = []
	var forced: Array[Result] = []

	static func key_of(npc_id: int, serial: int) -> String:
		return "%d:%d" % [npc_id, serial]

	func peek_height(x: float, z: float) -> BridgeReplies.HeightReply:
		return BridgeReplies.HeightReply.new(Result.success(), 5.0 * float(posmod(floori(x / 2.0), 2) + posmod(floori(z / 2.0), 2))) if steep else super(x, z)

	func peek_pending_npc_intents() -> BridgeReplies.NpcIntentsReply:
		var listed: BridgeReplies.NpcIntentsReply = super()
		for intent: BridgeReplies.NpcIntentReply in listed.intents:
			if not seen.has(key_of(intent.npc_id, intent.action_serial)):
				seen[key_of(intent.npc_id, intent.action_serial)] = {"minute": peek_time().total_minutes, "intent": intent}
		return listed

	func request_report_npc_result(npc_id: int, action_serial: int, outcome: BridgeReplies.NpcOutcome, final_position: Vector3) -> Result:
		var answer: Result = forced.pop_front() if not forced.is_empty() else super(npc_id, action_serial, outcome, final_position)
		var still_listed: bool = false
		for intent: BridgeReplies.NpcIntentReply in peek_pending_npc_intents().intents:
			still_listed = still_listed or (intent.npc_id == npc_id and intent.action_serial == action_serial)
		reports.append({"key": key_of(npc_id, action_serial), "npc_id": npc_id, "outcome": outcome, "position": final_position, "result": answer, "minute": peek_time().total_minutes, "still_listed": still_listed})
		return answer

	func request_report_npc_positions(positions: Dictionary[int, Vector3]) -> Result:
		batch_frames.append(frame)
		return super(positions)


func before_all() -> void:
	_data = NpcLifeCheck.load_game_data()
	assert_eq(_data.problem, "", "Os dados reais do jogo carregam.")
	for place: Place in _data.places:
		if PlacePalette.is_drawn(place.kind):
			_half_by_place[place.id] = Vector2(PlacePalette.SIZES[place.kind].x, PlacePalette.SIZES[place.kind].z) * 0.5


func after_each() -> void:
	if _bodies != null:
		_bodies.release()
	if _host != null:
		_host.runner.finish()
		_host.free()
	_bodies = null
	_host = null


## Jogo novo, ponte espiã, corpos, motorista e o jogador longe até as 6h50, quando chega a A (os 50 mais perto ganham corpo).
func _start() -> void:
	var setup: NpcSetup = NpcSetup.from_dir(DATA_DIR, SettlementService.new(_data.settlements, _data.places))
	assert_true(setup.result.ok, setup.result.message)
	_host = SimulationHostNode.new()
	_host.start_new_game(WORLD_SEED, _data.terrain, _data.points, setup)
	_bridge = SpyBridge.new(_host, _data.terrain, _data.places, _host.npc)
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
	_actor_id = _bridge.request_spawn_character().actor_id
	assert_true(_bridge.request_report_position(_actor_id, FAR_M, 0.0).ok)
	_host.runner.run_steps(ARRIVAL_MINUTE)
	assert_true(_bridge.request_report_position(_actor_id, A_M, 0.0).ok)


func _frames(count: int) -> void:
	for _frame: int in count:
		_bridge.frame += 1
		_driver.advance(PHYSICS_DELTA)


## O jogo em miniatura: por minuto de jogo, um passo da simulação, os corpos em dia e os quadros de física do minuto.
func _drive(minutes: int) -> void:
	for _minute: int in minutes:
		_host.runner.step_once()
		_bodies.reconcile()
		_frames(FRAMES_PER_MINUTE)


func _flat_distance(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x, a.z).distance_to(Vector2(b.x, b.z))


## O corpo com trabalho em curso e mais caminho pela frente.
func _farthest_walker() -> NpcView:
	var best: float = 0.0
	var farthest: NpcView = null
	for entry: Dictionary in _bridge.seen.values():
		var intent: BridgeReplies.NpcIntentReply = entry["intent"]
		var view: NpcView = _bodies.pool().body_of(intent.npc_id)
		if view != null and _driver.job_serial_of(intent.npc_id) == intent.action_serial and _flat_distance(view.position, intent.destination) > best:
			best = _flat_distance(view.position, intent.destination)
			farthest = view
	return farthest


func test_the_bodies_walk_to_the_edge_report_arrived_and_done_at_the_estimated_end_and_send_positions_in_batches() -> void:
	_start()
	_drive(40)
	var arrived: int = 0
	var done: int = 0
	var reported: Dictionary[String, bool] = {}
	for report: Dictionary in _bridge.reports:
		var intent: BridgeReplies.NpcIntentReply = _bridge.seen[report["key"]]["intent"]
		var gap: Vector2 = Vector2(intent.destination.x - report["position"].x, intent.destination.z - report["position"].z).abs() - (_half_by_place.get(intent.place_id, Vector2.ZERO) + Vector2.ONE * NpcView.CAPSULE_RADIUS_M)
		assert_false(reported.has(report["key"]), "Cada Intent recebe um resultado só.")
		reported[report["key"]] = true
		assert_true(report["result"].ok, "O relato voltou ok: %s." % report["key"])
		assert_false(report["still_listed"], "O Intent saiu da lista da ponte logo depois do relato.")
		if intent.kind == BridgeReplies.NpcIntentKind.MOVE_TO_PLACE:
			arrived += 1
			assert_eq(report["outcome"], BridgeReplies.NpcOutcome.ARRIVED, "Ir a um local termina em ARRIVED.")
			assert_almost_eq(maxf(gap.x, gap.y), 0.0, EDGE_TOLERANCE_M, "O corpo parou na borda da caixa, não no centro.")
		else:
			done += 1
			assert_eq(report["outcome"], BridgeReplies.NpcOutcome.DONE, "As outras ações terminam em DONE.")
			assert_lte(maxf(gap.x, gap.y), EDGE_TOLERANCE_M, "No local.")
			assert_eq(report["minute"], _bridge.seen[report["key"]]["minute"] + intent.expected_minutes, "DONE no minuto em que viu o Intent mais a duração esperada.")
	assert_gt(arrived, 0, "Houve corpos que andaram até o local.")
	assert_gt(done, 0, "E ações cumpridas no local.")
	assert_gt(_bridge.batch_frames.size(), 0, "As posições de quem andou foram em lote.")
	for index: int in _bridge.batch_frames.size():
		assert_eq(_bridge.batch_frames[index] % NpcBodyDriver.REPORT_EVERY_PHYSICS_FRAMES, 0, "Lote só a cada 6 quadros de física.")
		assert_true(index == 0 or _bridge.batch_frames[index] > _bridge.batch_frames[index - 1], "Nunca dois lotes no mesmo quadro.")


func test_an_intent_that_vanishes_or_an_npc_that_leaves_s0_drops_the_job_and_reports_nothing() -> void:
	_start()
	_drive(12)
	var answered: Array[String] = []
	for report: Dictionary in _bridge.reports:
		answered.append(report["key"])
	var walking: Dictionary[String, int] = {}
	for key: String in _bridge.seen:
		var intent: BridgeReplies.NpcIntentReply = _bridge.seen[key]["intent"]
		if _driver.job_serial_of(intent.npc_id) == intent.action_serial and not answered.has(key):
			walking[key] = intent.npc_id
	_host.runner.run_steps(35)
	_bodies.reconcile()
	var listed: Array[String] = []
	for intent: BridgeReplies.NpcIntentReply in _bridge.peek_pending_npc_intents().intents:
		listed.append(SpyBridge.key_of(intent.npc_id, intent.action_serial))
	_frames(1)
	var vanished: Array[String] = []
	for key: String in walking:
		if not listed.has(key):
			vanished.append(key)
			assert_ne(_driver.job_serial_of(walking[key]), _bridge.seen[key]["intent"].action_serial, "O Intent %s venceu e o corpo largou o trabalho." % key)
	assert_gt(vanished.size(), 0, "Sem quadros por 35 minutos, alguns Intents venceram pelo tempo limite (fim previsto + 30).")
	for report: Dictionary in _bridge.reports:
		assert_false(vanished.has(report["key"]), "Nada foi relatado sobre um Intent que sumiu.")
	var reports_before: int = _bridge.reports.size()
	assert_true(_bridge.request_report_position(_actor_id, FAR_M, 0.0).ok)
	_host.runner.step_once()
	_bodies.reconcile()
	_frames(1)
	assert_eq([_driver.job_count(), _bodies.active_ids().size(), _bridge.reports.size()], [0, 0, reports_before], "Sem corpo (saiu de S0): sem trabalho e sem relato.")


func test_a_refused_route_reports_blocked_and_the_body_stays_where_it_was() -> void:
	_start()
	_bridge.steep = true
	_drive(14)
	var blocked: int = 0
	for report: Dictionary in _bridge.reports:
		assert_ne(report["outcome"], BridgeReplies.NpcOutcome.ARRIVED, "Nenhuma rota íngreme termina em ARRIVED.")
		if report["outcome"] == BridgeReplies.NpcOutcome.BLOCKED:
			var view: NpcView = _bodies.pool().body_of(report["npc_id"])
			blocked += 1
			assert_true(report["result"].ok and not report["still_listed"], "BLOCKED foi aceito e o Intent saiu da lista.")
			assert_almost_eq(report["position"], view.position, Vector3.ONE * EDGE_TOLERANCE_M, "O corpo não saiu do lugar.")
			assert_false(view.is_walking())
	assert_gt(blocked, 0, "Os Intents de ir ao trabalho voltaram BLOCKED.")


func test_the_body_speed_follows_the_clock_and_the_pause_freezes_it() -> void:
	_start()
	_drive(10)
	var view: NpcView = _farthest_walker()
	assert_not_null(view, "Há um corpo a caminho.")
	var before: Vector3 = view.position
	_frames(60)
	assert_almost_eq(_flat_distance(before, view.position), 4.0, 0.1, "1x: 4 m em 1 s.")
	assert_true(_bridge.request_speed(4).ok)
	before = view.position
	_frames(60)
	assert_almost_eq(_flat_distance(before, view.position), 16.0, 0.1, "4x: 16 m em 1 s.")
	assert_true(_bridge.request_pause(true).ok)
	before = view.position
	_frames(120)
	assert_eq([view.position, view.is_walking()], [before, false], "Pausado, o corpo para.")
	assert_true(_bridge.request_pause(false).ok)
	_frames(60)
	assert_almost_eq(_flat_distance(before, view.position), 16.0, 0.1, "Despausado, volta a andar de onde parou.")


func test_stale_and_failed_action_results_are_not_errors_other_refusals_are_visible_and_none_is_retried() -> void:
	_start()
	_bridge.forced = [Result.failure(NpcBodyDriver.CODE_STALE, "forçado"), Result.failure(NpcBodyDriver.CODE_ACTION_FAILED, "forçado"), Result.failure("NPC_RESULT_OUTCOME_MISMATCH", "forçado")]
	_drive(18)
	assert_push_error("resultado recusado")
	assert_gte(_bridge.reports.size(), 3)
	for index: int in 3:
		var key: String = _bridge.reports[index]["key"]
		assert_eq(_bridge.reports.filter(func(report: Dictionary) -> bool: return report["key"] == key).size(), 1, "O Intent %s recusado não foi tentado de novo." % key)
	assert_eq([NpcBodyDriver.CODE_STALE, NpcBodyDriver.CODE_NOT_IN_S0, NpcBodyDriver.CODE_ACTION_FAILED], [NpcIntentBoard.CODE_STALE_RESULT, NpcLod.CODE_NOT_IN_S0, ActionRunner.CODE_ACTION_FAILED], "Os códigos copiados são os da simulação.")
	assert_eq(NpcBodyDriver.REPORT_EVERY_PHYSICS_FRAMES, PlayerBody.REPORT_EVERY_PHYSICS_FRAMES, "Mesmo ritmo de relato do jogador.")


func test_setup_refuses_a_null_bridge_null_bodies_and_inactive_bodies() -> void:
	_start()
	var bare: NpcBodyDriver = NpcBodyDriver.new()
	autofree(bare)
	assert_false(bare.setup(null, _bodies))
	assert_push_error("ponte nula")
	assert_false(bare.setup(_bridge, null))
	assert_push_error("ponte nula")
	_bodies.release()
	assert_false(bare.setup(_bridge, _bodies), "Corpos inativos recusam.")
	assert_push_error("ponte nula")
	bare.advance(PHYSICS_DELTA)
	assert_eq(bare.job_count(), 0, "Sem setup, o motorista não faz nada.")
