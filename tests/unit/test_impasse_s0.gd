extends GutTest
## LW-073b: o detector de impasse para o NPC com corpo (docs/modules/npc.md, seção 6), sem janela. Na primeira parte o detector é testado sozinho (corpo e Intent simulados por
## quem testa; a "saída de S0" grava o último relato do corpo, como o LOD faz); na segunda, o módulo `npc` do jogo real com os corpos ligados e NINGUÉM respondendo aos
## Intents: os NPCs em S0 vencem por tempo, em sequência, e são recuperados pelo motivo `result_timeout`. Um vencimento só é tratado pelo tempo limite do Intent; a
## sequência de vencimentos que dura `NpcImpasse.DEFAULT_LIMIT_MIN` minutos ou mais, sem outra ação no meio, é impasse.

const VILLAGE: String = "village_a"
const HOME: String = "home_a"
const WORK: String = "work_a"
const NEED_IDS: Array[String] = ["hunger", "rest", "safety", "income", "social"]
const HOME_X_CM: int = 8400
const BODY_REPORT_X_CM: int = 30000
const STUCK_X_CM: int = 50000
const WAIT_MIN: int = 10
const INTENT_TIMEOUT_MIN: int = 30
const HALF_TIMEOUT_MIN: int = 15
const WORLD_SEED: int = 11
const ACTOR_ID: int = 77
const LIMIT_MIN: int = NpcImpasse.DEFAULT_LIMIT_MIN

var _games: Array[Game] = []


## O detector sozinho, com um `ActionRunner` de verdade na mesma tabela de NPCs; o corpo e o Intent pendente são marcas do teste.
class Rig:
	extends RefCounted

	var clock: SimClock = SimClock.new()
	var ctx: SimContext
	var states: Dictionary[int, NpcState] = {}
	var runner: ActionRunner
	var detector: NpcImpasse
	var embodied: Dictionary[int, bool] = {}
	var pending: Dictionary[int, bool] = {}
	var released: Array[int] = []
	var heard: Array[NpcImpasseRecovered] = []

	func is_embodied(npc_id: int) -> bool:
		return embodied.get(npc_id, false)

	func has_pending(npc_id: int) -> bool:
		return pending.get(npc_id, false)

	## A saída de S0 do LOD grava o último relato do corpo como posição lógica e o NPC deixa de ter corpo.
	func release_body(npc_id: int) -> void:
		released.append(npc_id)
		states[npc_id].x_cm = BODY_REPORT_X_CM
		embodied[npc_id] = false

	func on_recovered(event: SimEvent) -> void:
		heard.append(event as NpcImpasseRecovered)


## O jogo real com os corpos ligados e o foco no povoado A; ninguém responde aos Intents.
class Game:
	extends RefCounted

	var runner: SimulationRunner
	var npc: NpcModule
	var heard: Array[NpcImpasseRecovered] = []

	func on_recovered(event: SimEvent) -> void:
		heard.append(event as NpcImpasseRecovered)


func after_each() -> void:
	for game: Game in _games:
		game.runner.finish()
	_games.clear()


func _rig() -> Rig:
	var rig: Rig = Rig.new()
	rig.ctx = SimContext.new(rig.clock, EventBus.new(rig.clock), WorldRng.new(WORLD_SEED), IdGenerator.new())
	var settlements: Array[Settlement] = [Settlement.new(VILLAGE, "settlement.a", Vector3(0.0, 0.0, 0.0))]
	var places: Array[Place] = [Place.new(HOME, VILLAGE, Place.KIND_HOME, Vector3(84.0, 0.0, 0.0), 5), Place.new(WORK, VILLAGE, Place.KIND_WORK, Vector3(100.5, 0.0, 0.0), 10)]
	var service: SettlementService = SettlementService.new(settlements, places)
	var catalog: Array[ActionDef] = [ActionDef.new("wait", WAIT_MIN, "", 0, true)]
	var need_defs: Array[NeedDef] = []
	for position: int in NEED_IDS.size():
		need_defs.append(NeedDef.new(NEED_IDS[position], position, 0, 0, 40, 65, 90))
	rig.runner = ActionRunner.new(rig.states, catalog, need_defs, service)
	rig.detector = NpcImpasse.new(rig.states, service, rig.is_embodied, rig.runner.cancel_action, LIMIT_MIN, rig.has_pending, rig.release_body)
	rig.detector.setup(rig.ctx)
	rig.ctx.events.subscribe("NpcImpasseRecovered", rig.on_recovered)
	return rig


func _npc(rig: Rig, npc_id: int, is_embodied: bool) -> NpcState:
	var state: NpcState = NpcState.new(npc_id)
	state.need_values = PackedInt64Array([10, 10, 10, 10, 10])
	state.x_cm = STUCK_X_CM
	state.settlement_id = VILLAGE
	state.home_place_id = HOME
	state.work_place_id = WORK
	rig.states[npc_id] = state
	rig.embodied[npc_id] = is_embodied
	return state


## O NPC começa uma ação (contador novo); se tem corpo, o Intent fica pendente.
func _begin(rig: Rig, npc_id: int) -> void:
	var started: Result = rig.runner.begin(npc_id, "wait", "", rig.clock.total_minutes())
	assert_true(started.ok, started.message)
	rig.pending[npc_id] = rig.embodied[npc_id]


func _run_minutes(rig: Rig, minutes: int) -> void:
	for _i: int in minutes:
		rig.clock.advance_step()
		rig.detector.tick()
		rig.ctx.events.dispatch()


## O que o quadro de Intents faz no vencimento: cancela a ação sem efeito e solta o Intent; o detector recebe o NPC na lista dos vencidos do passo.
func _time_out(rig: Rig, npc_id: int) -> void:
	assert_true(rig.runner.cancel_action(npc_id, rig.states[npc_id].action_serial).ok)
	rig.pending[npc_id] = false
	rig.clock.advance_step()
	rig.detector.tick([npc_id])
	rig.ctx.events.dispatch()


func test_two_consecutive_timeouts_spanning_the_limit_recover_the_embodied_npc() -> void:
	var rig: Rig = _rig()
	var state: NpcState = _npc(rig, 1, true)
	_begin(rig, 1)
	_run_minutes(rig, WAIT_MIN + INTENT_TIMEOUT_MIN - 1)
	assert_eq(rig.heard.size(), 0, "Com o Intent pendente o detector não mexe: é do tempo limite dele.")
	_time_out(rig, 1)
	var first_timeout_at: int = rig.clock.total_minutes()
	assert_eq(rig.heard.size(), 0, "Um vencimento só é tratado pelo tempo limite do Intent.")
	_begin(rig, 1)
	_run_minutes(rig, LIMIT_MIN - 1)
	_time_out(rig, 1)
	assert_eq(rig.clock.total_minutes() - first_timeout_at, LIMIT_MIN)
	assert_eq(rig.heard.size(), 1, "O segundo vencimento seguido fecha uma sequência de %d minutos: impasse." % LIMIT_MIN)
	assert_eq([rig.heard[0].npc_id, rig.heard[0].reason, rig.heard[0].place_id], [1, NpcImpasse.REASON_RESULT_TIMEOUT, HOME])
	assert_eq(rig.released, [1] as Array[int], "O corpo foi solto.")
	assert_eq([state.x_cm, state.place_id, state.action_id], [HOME_X_CM, HOME, ""], "A posição nova vem depois da saída de S0 (que grava o relato do corpo) e vale a casa.")
	assert_eq(state.next_think_time, rig.clock.total_minutes(), "O NPC pensa já.")
	assert_eq(rig.detector.peek_records()[0][NpcImpasse.KEY_OVERDUE_MIN], LIMIT_MIN, "O registro diz há quantos minutos a sequência começou.")


func test_a_second_timeout_before_the_limit_waits_for_the_third() -> void:
	var rig: Rig = _rig()
	_npc(rig, 1, true)
	for _attempt: int in 2:
		_begin(rig, 1)
		_run_minutes(rig, HALF_TIMEOUT_MIN)
		_time_out(rig, 1)
	assert_eq(rig.heard.size(), 0, "Dois vencimentos em menos de %d minutos ainda não fecham a sequência." % LIMIT_MIN)
	_begin(rig, 1)
	_run_minutes(rig, LIMIT_MIN)
	_time_out(rig, 1)
	assert_eq(rig.heard.size(), 1, "O terceiro vencimento seguido, já passado o limite desde o primeiro, recupera.")
	assert_eq(rig.heard[0].reason, NpcImpasse.REASON_RESULT_TIMEOUT)


func test_another_action_between_two_timeouts_breaks_the_sequence() -> void:
	var rig: Rig = _rig()
	var state: NpcState = _npc(rig, 1, true)
	_begin(rig, 1)
	_time_out(rig, 1)
	_begin(rig, 1)
	rig.pending[1] = false
	_run_minutes(rig, WAIT_MIN)
	assert_eq(rig.runner.advance(1, rig.clock.total_minutes()).outcome, ActionRunner.Outcome.COMPLETED, "Uma ação termina com resultado no meio.")
	_begin(rig, 1)
	_run_minutes(rig, LIMIT_MIN + WAIT_MIN)
	_time_out(rig, 1)
	assert_eq(state.action_serial, 3, "Foram três ações; o segundo vencimento não é o seguinte ao primeiro.")
	assert_eq(rig.heard.size(), 0, "Com uma ação concluída no meio não há sequência de vencimentos, por mais tempo que tenha passado.")


func test_an_embodied_npc_without_a_pending_intent_and_an_overrun_action_is_recovered_with_its_body_released() -> void:
	var rig: Rig = _rig()
	var state: NpcState = _npc(rig, 1, true)
	_begin(rig, 1)
	rig.pending[1] = false
	_run_minutes(rig, WAIT_MIN + LIMIT_MIN - 1)
	assert_eq(rig.heard.size(), 0)
	_run_minutes(rig, 1)
	assert_eq([rig.heard.size(), rig.heard[0].reason, rig.released], [1, NpcImpasse.REASON_NO_PROGRESS, [1] as Array[int]])
	assert_eq([state.action_id, state.x_cm, state.place_id], ["", HOME_X_CM, HOME])


func test_a_dead_or_unknown_npc_in_the_timeout_list_is_ignored() -> void:
	var rig: Rig = _rig()
	var dead: NpcState = _npc(rig, 1, true)
	dead.is_alive = false
	for _attempt: int in 3:
		rig.clock.advance_step()
		rig.detector.tick([1, 999] as Array[int])
	assert_eq([rig.heard.size(), rig.released.size()], [0, 0])


# ---------------------------------------------------------------------------------------------------- o módulo do jogo real

func _game() -> Game:
	var data: NpcLifeCheck.GameData = NpcLifeCheck.load_game_data()
	assert_eq(data.problem, "", "Os dados reais do jogo carregam.")
	var setup: NpcSetup = NpcSetup.from_dir(NpcLifeCheck.DATA_DIR, SettlementService.new(data.settlements, data.places))
	var game: Game = Game.new()
	game.runner = SimulationRunner.new(WORLD_SEED)
	var modules: GameModules = GameModules.register(game.runner, data.terrain, data.points, setup)
	assert_true(modules.result.ok, modules.result.message)
	game.npc = modules.npc
	game.runner.world.context.events.subscribe("NpcImpasseRecovered", game.on_recovered)
	game.runner.start_new_game()
	assert_true(game.npc.request_set_bodies_available(true).ok)
	var first_place: Place = data.places[0]
	assert_true(game.npc.request_set_focus(ACTOR_ID, first_place.position).ok, "O foco no povoado põe NPCs em S0.")
	_games.append(game)
	return game


func test_with_the_bodies_on_and_nobody_answering_the_npcs_are_recovered_by_result_timeout() -> void:
	var game: Game = _game()
	var recovered_at: Dictionary[int, Array] = {}
	var seen: int = 0
	for _minute: int in SimClock.MINUTES_PER_DAY:
		game.runner.step_once()
		for index: int in range(seen, game.heard.size()):
			var event: NpcImpasseRecovered = game.heard[index]
			var query: NpcModule.NpcQuery = game.npc.peek_npc(event.npc_id)
			assert_eq([event.reason, event.place_id, query.place_id], [NpcImpasse.REASON_RESULT_TIMEOUT, query.home_place_id, query.home_place_id], "Recuperado pelo vencimento, posto na casa.")
			assert_eq(game.npc.lod.level_of(event.npc_id), NpcLod.LEVEL_S1, "O corpo foi solto: o NPC está em S1 no passo da recuperação.")
			var times: Array = recovered_at.get(event.npc_id, [])
			times.append(event.time)
			recovered_at[event.npc_id] = times
		seen = game.heard.size()
	assert_gt(game.heard.size(), 0, "Em um dia sem ninguém responder, há recuperações.")
	for npc_id: int in recovered_at:
		var times: Array = recovered_at[npc_id]
		for index: int in range(1, times.size()):
			assert_gte(int(times[index]) - int(times[index - 1]), LIMIT_MIN, "O mesmo NPC espera %d minutos entre duas recuperações." % LIMIT_MIN)
	assert_eq(game.npc.validate().size(), 0, str(game.npc.validate()))
	assert_eq(game.npc.peek_impasse_records().size(), mini(game.heard.size(), NpcImpasse.MAX_RECORDS))
