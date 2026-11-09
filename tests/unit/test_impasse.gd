extends GutTest
## LW-073a: o detector de impasse (docs/modules/npc.md, seção 6), sem janela. Na primeira parte o detector é testado sozinho, com um `ActionRunner` de verdade (a mesma
## tabela de NPCs) e os minutos passando à mão; na segunda, o módulo `npc` do jogo real (dados de res://data): um NPC bloqueado de propósito é recuperado e sete dias de
## vida normal não recuperam ninguém. Impasse = ação aberta `NpcImpasse.DEFAULT_LIMIT_MIN` minutos DEPOIS do fim previsto; dormir 480 minutos ou andar 99 não é impasse.

const VILLAGE: String = "village_a"
const HOME: String = "home_a"
const WORK: String = "work_a"
const FAR_PLACE: String = "far_a"
const NEED_IDS: Array[String] = ["hunger", "rest", "safety", "income", "social"]
const HOME_X_CM: int = 8400
const STUCK_X_CM: int = 50000
const ROUTE_AB_M: float = 495.0
const WAIT_MIN: int = 10
const SLEEP_MIN: int = 480
const MANY_NPCS: int = 40
const WORLD_SEED: int = 11
const WEEK_MIN: int = 7 * SimClock.MINUTES_PER_DAY
const NEVER_MIN: int = 1000000
## O limite padrão do detector; os testes usam a constante para não fixar o valor [HIP].
const LIMIT_MIN: int = NpcImpasse.DEFAULT_LIMIT_MIN

var _games: Array[Game] = []


## O detector montado sozinho: relógio, eventos, locais, a tabela de NPCs e um `ActionRunner` que a divide com ele.
class Rig:
	extends RefCounted

	var clock: SimClock = SimClock.new()
	var ctx: SimContext
	var states: Dictionary[int, NpcState] = {}
	var runner: ActionRunner
	var detector: NpcImpasse
	var embodied: Dictionary[int, bool] = {}
	var heard: Array[NpcImpasseRecovered] = []

	func is_embodied(npc_id: int) -> bool:
		return embodied.get(npc_id, false)

	func on_recovered(event: SimEvent) -> void:
		heard.append(event as NpcImpasseRecovered)


## O jogo real (módulo `npc` com os dados de res://data) e os eventos de impasse ouvidos.
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


func _places() -> SettlementService:
	var settlements: Array[Settlement] = [Settlement.new(VILLAGE, "settlement.a", Vector3(0.0, 0.0, 0.0))]
	var places: Array[Place] = [
		Place.new(HOME, VILLAGE, Place.KIND_HOME, Vector3(84.0, 0.0, 0.0), 5),
		Place.new(WORK, VILLAGE, Place.KIND_WORK, Vector3(100.5, 0.0, 0.0), 10),
		Place.new(FAR_PLACE, VILLAGE, Place.KIND_REST, Vector3(ROUTE_AB_M, 0.0, 0.0), 3),
	]
	return SettlementService.new(settlements, places)


func _rig(places: SettlementService = _places(), cancel_override: Callable = Callable()) -> Rig:
	var rig: Rig = Rig.new()
	rig.ctx = SimContext.new(rig.clock, EventBus.new(rig.clock), WorldRng.new(WORLD_SEED), IdGenerator.new())
	var catalog: Array[ActionDef] = [ActionDef.new("wait", WAIT_MIN, "", 0, true), ActionDef.new("sleep", SLEEP_MIN, "", 0, true), ActionDef.new(ActionRunner.GO_TO_PLACE_ID, 0, "", 0, true)]
	var need_defs: Array[NeedDef] = []
	for position: int in NEED_IDS.size():
		need_defs.append(NeedDef.new(NEED_IDS[position], position, 0, 0, 40, 65, 90))
	rig.runner = ActionRunner.new(rig.states, catalog, need_defs, _places())
	var cancel: Callable = cancel_override if cancel_override.is_valid() else rig.runner.cancel_action
	rig.detector = NpcImpasse.new(rig.states, places, rig.is_embodied, cancel)
	rig.detector.setup(rig.ctx)
	rig.ctx.events.subscribe("NpcImpasseRecovered", rig.on_recovered)
	return rig


func _npc(rig: Rig, npc_id: int, x_cm: int = STUCK_X_CM, home_id: String = HOME, work_id: String = WORK) -> NpcState:
	var state: NpcState = NpcState.new(npc_id)
	state.need_values = PackedInt64Array([10, 10, 10, 10, 10])
	state.x_cm = x_cm
	state.settlement_id = VILLAGE
	state.home_place_id = home_id
	state.work_place_id = work_id
	rig.states[npc_id] = state
	return state


func _begin(rig: Rig, npc_id: int, action_id: String, place_id: String = "") -> void:
	var started: Result = rig.runner.begin(npc_id, action_id, place_id, rig.clock.total_minutes())
	assert_true(started.ok, started.message)


## Passa `minutes` minutos, um a um: o relógio avança, o detector olha e os eventos são entregues.
func _run_minutes(rig: Rig, minutes: int) -> void:
	for _i: int in minutes:
		rig.clock.advance_step()
		rig.detector.tick()
		rig.ctx.events.dispatch()


func test_an_action_left_open_past_its_planned_end_by_the_limit_is_recovered_at_home() -> void:
	var rig: Rig = _rig()
	var state: NpcState = _npc(rig, 1)
	_begin(rig, 1, "wait")
	var serial: int = state.action_serial
	var needs_before: PackedInt64Array = state.need_values.duplicate()
	_run_minutes(rig, WAIT_MIN + LIMIT_MIN - 1)
	assert_eq(rig.heard.size(), 0, "Um minuto antes do limite depois do fim previsto ainda não é impasse.")
	assert_eq(state.action_id, "wait", "A ação segue aberta.")
	_run_minutes(rig, 1)
	assert_eq(rig.heard.size(), 1, "No limite exato o NPC é recuperado, uma vez.")
	assert_eq([rig.heard[0].npc_id, rig.heard[0].reason, rig.heard[0].place_id], [1, NpcImpasse.REASON_NO_PROGRESS, HOME])
	assert_eq([state.action_id, state.place_id, state.x_cm, state.z_cm], ["", HOME, HOME_X_CM, 0], "Ação cancelada e o NPC na casa.")
	assert_eq(state.next_think_time, rig.clock.total_minutes(), "O NPC pensa já.")
	assert_eq(state.need_values, needs_before, "Cancelar não aplica efeito nenhum.")
	assert_eq(state.action_serial, serial, "O contador de ações não volta.")
	assert_eq(rig.detector.peek_records(), [{NpcImpasse.KEY_NPC_ID: 1, NpcImpasse.KEY_REASON: NpcImpasse.REASON_NO_PROGRESS, NpcImpasse.KEY_PLACE_ID: HOME, NpcImpasse.KEY_MINUTE: WAIT_MIN + LIMIT_MIN, NpcImpasse.KEY_ACTION_ID: "wait", NpcImpasse.KEY_OVERDUE_MIN: LIMIT_MIN}] as Array[Dictionary])


func test_a_long_planned_action_is_not_an_impasse_until_the_limit_after_its_own_end() -> void:
	var cases: Array[Array] = [["dormir", "sleep", "", STUCK_X_CM], ["andar a rota A para B", ActionRunner.GO_TO_PLACE_ID, FAR_PLACE, 0]]
	for case: Array in cases:
		var rig: Rig = _rig()
		var state: NpcState = _npc(rig, 1, case[3])
		_begin(rig, 1, case[1], case[2])
		var planned: int = state.action_ends_at - state.action_started_at
		assert_gt(planned, LIMIT_MIN, "%s: a ação planejada é mais longa que o limite." % case[0])
		_run_minutes(rig, planned + LIMIT_MIN - 1)
		assert_eq(rig.heard.size(), 0, "%s: dentro do tempo previsto mais o limite não é impasse." % case[0])
		_run_minutes(rig, 1)
		assert_eq(rig.heard.size(), 1, "%s: passado o limite depois do fim previsto, é." % case[0])


func test_a_failed_cancel_is_reported_once_per_window_and_changes_nothing() -> void:
	var failing: Callable = func(_npc_id: int, _serial: int) -> Result: return Result.failure("TEST_CANCEL_REFUSED", "recusado de propósito.")
	var rig: Rig = _rig(_places(), failing)
	var state: NpcState = _npc(rig, 1)
	_begin(rig, 1, "wait")
	_run_minutes(rig, WAIT_MIN + LIMIT_MIN)
	assert_push_error("TEST_CANCEL_REFUSED")
	_run_minutes(rig, LIMIT_MIN - 1)
	assert_eq(rig.heard.size(), 0, "Sem cancelar não há evento.")
	assert_eq([state.action_id, state.x_cm], ["wait", STUCK_X_CM], "Nada muda no NPC.")
	_run_minutes(rig, 1)
	assert_push_error("TEST_CANCEL_REFUSED")


func test_embodied_and_dead_npcs_are_left_alone() -> void:
	var rig: Rig = _rig()
	var embodied_state: NpcState = _npc(rig, 1)
	var dead_state: NpcState = _npc(rig, 2)
	_begin(rig, 1, "wait")
	_begin(rig, 2, "wait")
	rig.embodied[1] = true
	dead_state.is_alive = false
	_run_minutes(rig, WAIT_MIN + LIMIT_MIN + LIMIT_MIN)
	assert_eq(rig.heard.size(), 0)
	assert_eq([embodied_state.action_id, dead_state.action_id], ["wait", "wait"])


func test_without_a_home_the_work_place_is_used_and_without_any_place_only_the_action_is_cancelled() -> void:
	var rig: Rig = _rig()
	var works: NpcState = _npc(rig, 1, STUCK_X_CM, "")
	var lost: NpcState = _npc(rig, 2, STUCK_X_CM, "no_such_home", "no_such_work")
	var no_service: Rig = _rig(null)
	var unserved: NpcState = _npc(no_service, 3)
	for target: Rig in [rig, no_service]:
		for npc_id: int in target.states:
			_begin(target, npc_id, "wait")
		_run_minutes(target, WAIT_MIN + LIMIT_MIN)
	assert_eq([works.place_id, works.x_cm], [WORK, 10050], "Sem casa vai ao local de trabalho.")
	assert_eq([lost.action_id, lost.x_cm, lost.place_id], ["", STUCK_X_CM, ""], "Sem local utilizável só a ação é cancelada.")
	assert_eq([unserved.action_id, unserved.x_cm], ["", STUCK_X_CM], "Sem serviço de locais também.")
	var places_heard: Array[String] = []
	for event: NpcImpasseRecovered in rig.heard + no_service.heard:
		places_heard.append(event.place_id)
	assert_eq(places_heard, [WORK, "", ""], "O evento diz onde o NPC foi posto, vazio se em lugar nenhum.")


func test_recoveries_come_in_ascending_id_order_and_the_record_keeps_only_the_latest() -> void:
	var rig: Rig = _rig()
	for npc_id: int in range(MANY_NPCS, 0, -1):
		_npc(rig, npc_id)
		_begin(rig, npc_id, "wait")
	_run_minutes(rig, WAIT_MIN + LIMIT_MIN)
	assert_eq(rig.detector.recovered_total(), MANY_NPCS)
	var heard_ids: Array[int] = []
	for event: NpcImpasseRecovered in rig.heard:
		heard_ids.append(event.npc_id)
	var ascending: Array[int] = heard_ids.duplicate()
	ascending.sort()
	assert_eq(heard_ids, ascending, "Em ordem crescente de ID.")
	var records: Array[Dictionary] = rig.detector.peek_records()
	assert_eq([records.size(), records[0][NpcImpasse.KEY_NPC_ID]], [NpcImpasse.MAX_RECORDS, MANY_NPCS - NpcImpasse.MAX_RECORDS + 1], "Fica o mais recente: sai o mais antigo.")
	records[0][NpcImpasse.KEY_NPC_ID] = -1
	assert_ne(rig.detector.peek_records()[0][NpcImpasse.KEY_NPC_ID], -1, "O registro é entregue em cópia.")
	rig.detector.reset()
	assert_eq([rig.detector.recovered_total(), rig.detector.peek_records().size()], [0, 0], "Recarregar esquece o registro.")


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
	_games.append(game)
	return game


func test_the_game_module_recovers_a_deliberately_blocked_npc_and_the_reason_is_recorded() -> void:
	var game: Game = _game()
	game.runner.run_steps(SimClock.MINUTES_PER_DAY)
	var now: int = game.runner.world.context.clock.total_minutes()
	var npc_id: int = game.npc.peek_npc_ids()[0]
	var saved: Dictionary = game.npc.serialize()
	var entries: Dictionary = saved["npcs"]
	var entry: Dictionary = entries[str(npc_id)]
	var home_id: String = entry["home_place_id"]
	entry["action_id"] = "wait"
	entry["action_target_place_id"] = ""
	entry["action_started_at"] = now
	entry["action_ends_at"] = now + WAIT_MIN
	entry["action_serial"] = int(entry["action_serial"]) + 1
	entry["next_think_time"] = now + NEVER_MIN
	assert_true(game.npc.on_load(saved).ok, "O NPC bloqueado de propósito: a ação não acaba e ele não pensa.")
	game.runner.run_steps(WAIT_MIN + LIMIT_MIN - 1)
	assert_eq(game.heard.size(), 0, "Antes do limite ninguém é recuperado.")
	game.runner.run_steps(1)
	assert_eq(game.heard.size(), 1, "No limite o NPC bloqueado é recuperado.")
	assert_eq([game.heard[0].npc_id, game.heard[0].reason, game.heard[0].place_id], [npc_id, NpcImpasse.REASON_NO_PROGRESS, home_id])
	var records: Array[Dictionary] = game.npc.peek_impasse_records()
	assert_eq([records.size(), records[0][NpcImpasse.KEY_NPC_ID], records[0][NpcImpasse.KEY_ACTION_ID]], [1, npc_id, "wait"], "O motivo fica registrado.")
	var recovered_at: int = game.runner.world.context.clock.total_minutes()
	game.runner.run_steps(WAIT_MIN + 2)
	assert_gt(game.npc.peek_npc(npc_id).next_think_time, recovered_at, "O NPC voltou a pensar.")
	assert_eq(game.npc.validate().size(), 0, str(game.npc.validate()))
	assert_eq(game.heard.size(), 1, "E só ele.")


func test_seven_days_of_normal_life_recover_nobody() -> void:
	var game: Game = _game()
	game.runner.run_steps(WEEK_MIN)
	assert_eq(game.heard.size(), 0, "Nenhum falso positivo em sete dias de vida normal.")
	assert_eq(game.npc.peek_impasse_records().size(), 0)
