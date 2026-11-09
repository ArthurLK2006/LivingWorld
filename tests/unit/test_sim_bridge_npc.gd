extends GutTest
## LW-070: a ponte repassa o protocolo de NPC em S0 ao `npc` (intenções pendentes, resultado e posições do corpo) e entrega o FOCO do LOD
## a cada relato de posição do ator. Sem janela. Terreno e locais do blockout reais; o `npc` tem um mundo próprio (SimulationRunner) com
## necessidades e catálogo de teste, e o host só traz o personagem. A ponte não tem regra de jogo: o que decide é o `npc`, testado em
## test_npc_intents.gd; aqui se confere o repasse, as cópias, as unidades (metros) e os códigos de falha da ponte.

const BLOCKOUT_DIR: String = "res://data/world"
const WORLD_SEED: int = 3
const SETTLEMENT: String = "test_settlement_a"
const HOME: String = "a_home_01"
const WORK: String = "a_work_01"
## Centro do local de casa em centímetros (data/world/places.json), e o do trabalho.
const HOME_CM: Vector2i = Vector2i(28500, 54200)
const HOME_M: Vector2 = Vector2(285.0, 542.0)
const WORK_M: Vector2 = Vector2(285.0, 528.0)
const NEXT_TO_HOME_M: Vector3 = Vector3(285.0, 10.0, 540.0)
const FAR_AWAY_M: Vector3 = Vector3(900.0, 10.0, 900.0)
const OUTSIDE_M: Vector3 = Vector3(-5.0, 10.0, 500.0)
const BODY_AT_HOME_M: Vector3 = Vector3(285.2, 0.0, 541.9)
const NEED_IDS: Array[String] = ["hunger", "rest", "safety", "income", "social"]
const HUNGER: int = 0
const START_HUNGER: int = 80
const EAT_RELIEF: int = -60
const EAT_MIN: int = 20
const HEIGHT_TOLERANCE_M: float = 0.001
## ID que não é de ator nem de NPC nenhum.
const UNKNOWN_ID: int = 999
const S0: int = NpcLod.LEVEL_S0
const S1: int = NpcLod.LEVEL_S1

var _terrain: TerrainData
var _loaded: SettlementLoader.LoadResult
var _host: SimulationHostNode
var _npc_runner: SimulationRunner
var _npc_module: NpcModule
var _bridge: SimBridge
var _npc_id: int = 0


## Provedor de teste: sempre há comida.
class FoodAlways:
	extends ActionConditionProvider

	func has_food(_settlement_id: String) -> bool:
		return true


func before_all() -> void:
	var terrain_loaded: TerrainLoader.LoadResult = TerrainLoader.load_dir(BLOCKOUT_DIR)
	assert_true(terrain_loaded.result.ok, terrain_loaded.result.message)
	_terrain = terrain_loaded.terrain
	_loaded = SettlementLoader.load_dir(BLOCKOUT_DIR, _terrain)
	assert_true(_loaded.result.ok, _loaded.result.message)


func before_each() -> void:
	_host = SimulationHostNode.new()
	_host.start_new_game(WORLD_SEED, _terrain)
	_npc_module = _new_npc_world(true)
	_npc_id = _create_npc(HOME_CM.x, HOME_CM.y)
	_bridge = SimBridge.new(_host, _terrain, _loaded.places, _npc_module)


func after_each() -> void:
	_host.runner.finish()
	_host.free()
	_npc_runner.finish()


func _need_defs() -> Array[NeedDef]:
	var defs: Array[NeedDef] = []
	for position: int in NEED_IDS.size():
		var start_value: int = START_HUNGER if position == HUNGER else 0
		defs.append(NeedDef.new(NEED_IDS[position], position, start_value, 0, 40, 65, 90))
	return defs


func _catalog() -> Array[ActionDef]:
	var eat: ActionDef = ActionDef.new("eat", EAT_MIN, "", 0, true)
	eat.effects.append(ActionDef.ActionEffect.new("hunger", EAT_RELIEF))
	var go: ActionDef = ActionDef.new(ActionRunner.GO_TO_PLACE_ID, 0, "", 0, true)
	var catalog: Array[ActionDef] = [eat, go]
	return catalog


## Mundo do `npc` (relógio e eventos de verdade). `with_lod` liga o LOD com os parâmetros reais; o protocolo é sempre ligado.
func _new_npc_world(with_lod: bool) -> NpcModule:
	var module: NpcModule = NpcModule.new(_need_defs())
	if with_lod:
		assert_true(module.lod.configure(LodParamsLoader.load_dir().params).ok)
	_npc_runner = SimulationRunner.new(WORLD_SEED)
	assert_true(_npc_runner.register_module("npc", module).ok)
	_npc_runner.start_new_game()
	var places: SettlementService = SettlementService.new(_loaded.settlements, _loaded.places)
	var actions: ActionRunner = module.create_action_runner(_catalog(), places, FoodAlways.new())
	assert_eq(actions.peek_problem(), "")
	var linked: Result = module.configure_intents(actions, places, NpcIntentParams.new(30))
	assert_true(linked.ok, linked.message)
	return module


func _create_npc(x_cm: int, z_cm: int) -> int:
	var spec: NpcSpec = NpcSpec.new()
	spec.name_key = "npc.name.villager"
	spec.x_cm = x_cm
	spec.z_cm = z_cm
	spec.settlement_id = SETTLEMENT
	spec.place_id = HOME
	var created: NpcModule.CreateResult = _npc_module.request_create_npc(spec)
	assert_true(created.result.ok, created.result.message)
	return created.npc_id


func _spawned_actor() -> int:
	var spawned: BridgeReplies.SpawnCharacterReply = _bridge.request_spawn_character()
	assert_true(spawned.result.ok, spawned.result.message)
	return spawned.actor_id


## Ator que relata uma posição ao lado de casa e o passo que põe o NPC em S0, tudo pela ponte.
func _make_the_npc_s0() -> int:
	var actor_id: int = _spawned_actor()
	var reported: Result = _bridge.request_report_position(actor_id, NEXT_TO_HOME_M, 0.0)
	assert_true(reported.ok, reported.message)
	_npc_runner.step_once()
	assert_eq(_npc_module.lod.level_of(_npc_id), S0, "O NPC a 2 m do foco deveria estar em S0.")
	return actor_id


func _now() -> int:
	return _npc_runner.world.context.clock.total_minutes()


func _begin(npc_id: int, action_id: String, place_id: String) -> void:
	var started: Result = _npc_module.intents.begin_embodied(npc_id, action_id, place_id, _now())
	assert_true(started.ok, started.message)


func _hunger() -> int:
	return _npc_module.peek_npc(_npc_id).need_values[HUNGER]


## O pensamento seguinte (LW-070d): quem encerra a ação que o relato marcou. O módulo montado à mão não tem pensador; um runner sobre a MESMA tabela de NPCs faz o `advance`.
func _next_think() -> ActionRunner.AdvanceResult:
	var places: SettlementService = SettlementService.new(_loaded.settlements, _loaded.places)
	return _npc_module.create_action_runner(_catalog(), places, FoodAlways.new()).advance(_npc_id, _now())


# ---------------------------------------------------------------------------------------------------- foco

func test_a_position_report_delivers_the_stored_position_as_the_focus_of_that_actor() -> void:
	var actor_id: int = _make_the_npc_s0()
	assert_eq(_npc_module.lod.focus_count(), 1)
	var far_npc: int = _create_npc(HOME_CM.x + 40000, HOME_CM.y)
	_npc_runner.step_once()
	assert_eq(_npc_module.lod.level_of(far_npc), S1, "O NPC a 400 m do foco continua em S1.")
	assert_true(_bridge.request_report_position(actor_id, FAR_AWAY_M, 0.0).ok)
	_npc_runner.step_once()
	assert_eq(_npc_module.lod.level_of(_npc_id), S1, "O foco acompanhou o novo relato: o NPC de casa ficou longe.")
	assert_eq(_npc_module.lod.focus_count(), 1, "Um ator, um foco: relatar de novo move o foco, não cria outro.")


func test_two_actors_are_two_foci() -> void:
	_make_the_npc_s0()
	var second_actor: int = _spawned_actor()
	assert_true(_bridge.request_report_position(second_actor, FAR_AWAY_M, 0.0).ok)
	assert_eq(_npc_module.lod.focus_count(), 2, "Nada supõe um jogador só.")


func test_a_refused_report_delivers_no_focus() -> void:
	var actor_id: int = _spawned_actor()
	var refused: Result = _bridge.request_report_position(actor_id, OUTSIDE_M, 0.0)
	assert_false(refused.ok)
	assert_eq(refused.code, CharacterModule.CODE_OUT_OF_BOUNDS)
	assert_eq(_npc_module.lod.focus_count(), 0, "Relato recusado pelo personagem não vira foco.")
	assert_eq(_bridge.request_report_position(UNKNOWN_ID, NEXT_TO_HOME_M, 0.0).code, CharacterModule.CODE_UNKNOWN_ACTOR)
	assert_eq(_npc_module.lod.focus_count(), 0)


func test_a_focus_refused_by_the_npc_is_returned_but_the_character_report_is_kept() -> void:
	_npc_runner.finish()
	_npc_module = _new_npc_world(false)
	_bridge = SimBridge.new(_host, _terrain, _loaded.places, _npc_module)
	var actor_id: int = _spawned_actor()
	var outcome: Result = _bridge.request_report_position(actor_id, NEXT_TO_HOME_M, 1.5)
	assert_false(outcome.ok)
	assert_eq(outcome.code, NpcLod.CODE_NOT_CONFIGURED, "LOD sem parâmetros: a falha do `npc` aparece, não é engolida.")
	var stored: BridgeReplies.CharacterReply = _bridge.peek_character(actor_id)
	assert_true(stored.result.ok, stored.result.message)
	assert_almost_eq(stored.position.z, NEXT_TO_HOME_M.z, HEIGHT_TOLERANCE_M)
	assert_almost_eq(stored.yaw, 1.5, HEIGHT_TOLERANCE_M)


func test_a_bridge_without_npc_reports_positions_as_before_and_fails_the_npc_calls_with_a_code() -> void:
	var plain: SimBridge = SimBridge.new(_host, _terrain, _loaded.places)
	var spawned: BridgeReplies.SpawnCharacterReply = plain.request_spawn_character()
	assert_true(plain.request_report_position(spawned.actor_id, NEXT_TO_HOME_M, 0.0).ok, "Sem `npc` o relato de posição funciona como antes.")
	assert_eq(plain.peek_pending_npc_intents().result.code, SimBridge.CODE_NO_NPC)
	assert_eq(plain.request_report_npc_result(_npc_id, 1, BridgeReplies.NpcOutcome.DONE, BODY_AT_HOME_M).code, SimBridge.CODE_NO_NPC)
	var batch: Dictionary[int, Vector3] = {}
	assert_eq(plain.request_report_npc_positions(batch).code, SimBridge.CODE_NO_NPC)


func test_a_bridge_without_terrain_fails_the_peek_with_a_code_and_still_forwards_the_requests() -> void:
	_make_the_npc_s0()
	_begin(_npc_id, "eat", HOME)
	var no_terrain: SimBridge = SimBridge.new(_host, null, _loaded.places, _npc_module)
	var reply: BridgeReplies.NpcIntentsReply = no_terrain.peek_pending_npc_intents()
	assert_eq(reply.result.code, SimBridge.CODE_NO_TERRAIN, "O destino leva a altura do terreno: sem terreno a consulta falha.")
	assert_eq(reply.intents.size(), 0)
	var batch: Dictionary[int, Vector3] = {_npc_id: BODY_AT_HOME_M}
	assert_true(no_terrain.request_report_npc_positions(batch).ok, "Os pedidos não dependem do terreno.")
	var neither: SimBridge = SimBridge.new(null, null)
	assert_eq(neither.peek_pending_npc_intents().result.code, SimBridge.CODE_NO_TERRAIN)
	assert_eq(neither.request_report_npc_result(_npc_id, 1, BridgeReplies.NpcOutcome.DONE, BODY_AT_HOME_M).code, SimBridge.CODE_NO_NPC)


# ---------------------------------------------------------------------------------------------------- intenções

func test_pending_intents_come_back_as_copies_in_metres_with_the_ground_height() -> void:
	_make_the_npc_s0()
	_begin(_npc_id, "eat", HOME)
	var reply: BridgeReplies.NpcIntentsReply = _bridge.peek_pending_npc_intents()
	assert_true(reply.result.ok, reply.result.message)
	assert_eq(reply.intents.size(), 1)
	var intent: BridgeReplies.NpcIntentReply = reply.intents[0]
	assert_eq([intent.npc_id, intent.action_serial, intent.kind, intent.place_id, intent.expected_minutes], [_npc_id, 1, BridgeReplies.NpcIntentKind.ACT_AT_PLACE, HOME, EAT_MIN])
	assert_almost_eq(intent.destination.x, HOME_M.x, HEIGHT_TOLERANCE_M)
	assert_almost_eq(intent.destination.z, HOME_M.y, HEIGHT_TOLERANCE_M)
	assert_almost_eq(intent.destination.y, _bridge.peek_height(HOME_M.x, HOME_M.y).height_m, HEIGHT_TOLERANCE_M, "O y é a altura do terreno.")
	intent.expected_minutes = 999
	intent.destination = Vector3.ZERO
	reply.intents.clear()
	var again: BridgeReplies.NpcIntentsReply = _bridge.peek_pending_npc_intents()
	assert_eq([again.intents.size(), again.intents[0].expected_minutes], [1, EAT_MIN], "Mexer na resposta não muda o que a ponte entrega depois.")
	assert_eq(_npc_module.peek_pending_intents()[0].expected_minutes, EAT_MIN, "Nem o que está no `npc`.")


func test_intents_are_listed_in_ascending_npc_order_and_the_kinds_map() -> void:
	_make_the_npc_s0()
	var second: int = _create_npc(HOME_CM.x + 300, HOME_CM.y)
	_npc_runner.step_once()
	assert_eq(_npc_module.lod.level_of(second), S0)
	_begin(second, ActionRunner.GO_TO_PLACE_ID, WORK)
	_begin(_npc_id, "eat", HOME)
	var reply: BridgeReplies.NpcIntentsReply = _bridge.peek_pending_npc_intents()
	assert_eq([reply.intents[0].npc_id, reply.intents[1].npc_id], [_npc_id, second], "Ordem crescente de NPC.")
	assert_eq([reply.intents[0].kind, reply.intents[1].kind], [BridgeReplies.NpcIntentKind.ACT_AT_PLACE, BridgeReplies.NpcIntentKind.MOVE_TO_PLACE])
	assert_almost_eq(reply.intents[1].destination.z, WORK_M.y, HEIGHT_TOLERANCE_M)


# ---------------------------------------------------------------------------------------------------- resultados e posições

func test_each_outcome_passes_through_the_bridge_with_its_own_effect() -> void:
	_make_the_npc_s0()
	_begin(_npc_id, "eat", HOME)
	_npc_runner.run_steps(EAT_MIN)
	var done: Result = _bridge.request_report_npc_result(_npc_id, 1, BridgeReplies.NpcOutcome.DONE, BODY_AT_HOME_M)
	assert_true(done.ok, done.message)
	assert_eq(_next_think().outcome, ActionRunner.Outcome.COMPLETED, "O pensamento seguinte encerra a ação que o relato marcou (LW-070d).")
	assert_eq(_hunger(), START_HUNGER + EAT_RELIEF, "DONE: os efeitos entraram.")
	assert_eq(_bridge.peek_pending_npc_intents().intents.size(), 0, "E o Intent saiu da lista.")
	_begin(_npc_id, ActionRunner.GO_TO_PLACE_ID, WORK)
	var arrived: Result = _bridge.request_report_npc_result(_npc_id, 2, BridgeReplies.NpcOutcome.ARRIVED, Vector3(WORK_M.x, 0.0, WORK_M.y))
	assert_true(arrived.ok, arrived.message)
	assert_eq(_next_think().outcome, ActionRunner.Outcome.COMPLETED, "O pensamento seguinte encerra a ação que o relato marcou (LW-070d).")
	var npc: NpcModule.NpcQuery = _npc_module.peek_npc(_npc_id)
	assert_eq([npc.place_id, npc.action_id], [WORK, ""], "ARRIVED: o NPC chegou ao local.")
	for outcome: BridgeReplies.NpcOutcome in [BridgeReplies.NpcOutcome.BLOCKED, BridgeReplies.NpcOutcome.CANCELLED]:
		var before: int = _hunger()
		_begin(_npc_id, "eat", WORK)
		var serial: int = _npc_module.peek_npc(_npc_id).action_serial
		assert_true(_bridge.request_report_npc_result(_npc_id, serial, outcome, BODY_AT_HOME_M).ok)
		assert_eq(_hunger(), before, "BLOCKED e CANCELLED não aplicam efeito (%d)." % outcome)
		assert_eq(_npc_module.peek_npc(_npc_id).action_id, "")


func test_the_codes_of_the_npc_pass_through_and_an_unknown_outcome_is_refused_by_the_bridge() -> void:
	_make_the_npc_s0()
	_begin(_npc_id, "eat", HOME)
	var stale: Result = _bridge.request_report_npc_result(_npc_id, 7, BridgeReplies.NpcOutcome.DONE, BODY_AT_HOME_M)
	assert_eq(stale.code, NpcIntentBoard.CODE_STALE_RESULT, "Ação velha: o código do `npc` passa como está.")
	var raw_outcome: int = 9
	var unknown: Result = _bridge.request_report_npc_result(_npc_id, 1, raw_outcome as BridgeReplies.NpcOutcome, BODY_AT_HOME_M)
	assert_eq(unknown.code, SimBridge.CODE_INVALID_OUTCOME)
	var not_finite: Result = _bridge.request_report_npc_result(_npc_id, 1, BridgeReplies.NpcOutcome.DONE, Vector3(NAN, 0.0, 0.0))
	assert_eq(not_finite.code, NpcLod.CODE_INVALID_POSITION)
	assert_eq(_bridge.peek_pending_npc_intents().intents.size(), 1, "Nenhuma dessas recusas consumiu o Intent.")
	assert_eq(_hunger(), START_HUNGER)


func test_body_positions_pass_through_in_metres_and_the_npc_refusals_come_back() -> void:
	_make_the_npc_s0()
	var batch: Dictionary[int, Vector3] = {_npc_id: Vector3(286.0, 0.0, 543.0)}
	assert_true(_bridge.request_report_npc_positions(batch).ok)
	assert_eq(_npc_module.lod.position_of(_npc_id), Vector2i(28600, 54300))
	var unknown: Dictionary[int, Vector3] = {UNKNOWN_ID: Vector3(1.0, 0.0, 1.0)}
	assert_eq(_bridge.request_report_npc_positions(unknown).code, NpcLod.CODE_NOT_IN_S0)
	assert_eq(_npc_module.lod.position_of(_npc_id), Vector2i(28600, 54300), "A recusa de outro NPC não mexe neste.")
