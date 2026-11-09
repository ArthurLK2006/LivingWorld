extends GutTest
## LW-075: equivalência entre a ação abstrata (S1) e a ação com corpo (S0). Para CADA ação do catálogo real (res://data), duas execuções idênticas do
## mesmo NPC no mesmo mundo: em S1 o runner começa e termina a ação pelo relógio; em S0 o quadro de Intents emite o Intent, o teste faz o papel do
## corpo (ARRIVED ou DONE no fim previsto) e depois o papel do pensador (`advance` no pensamento seguinte). Compara o estado final do NPC inteiro
## (`NpcState.to_dict()`, o que o save e o hash cobrem) e quantas vezes a função única de efeitos rodou (uma). Bancada: a tabela de NPCs é do teste,
## mas o runner (EmbodiedActionRunner) e o quadro (NpcIntentBoard) são os do jogo, ligados como em `npc_decision_runtime.gd`. A caminhada é FIXA
## (WALK_SPEED_CM_PER_MIN), então o teste não depende da velocidade padrão (DEC-123, direção P3). Só ações COMPLETADAS: a cancelada tem diferença
## conhecida (LW-072h) e não é coberta aqui. Memória e relações de `talk` e `help` vêm do gancho social do pensador (test_npc_s0_social.gd). A varredura
## do "segundo caminho de efeitos" é do test_action_single_path.gd; este teste a completa pelo comportamento.

const DATA_DIR: String = "res://data"
const SETTLEMENT: String = "test_settlement_a"
const NPC_ID: int = 1
const ACTOR_ID: int = 77
const START_MIN: int = 600
## Todas as necessidades começam no meio, para o efeito de cada ação aparecer (sem cair no piso 0 nem no teto 100).
const START_NEED_VALUE: int = 70
const WALK_SPEED_CM_PER_MIN: int = 4200
const TIMEOUT_MIN: int = 30
const FOOD_ACTION_ID: String = "eat"
## Posição da necessidade `hunger` (data/needs.json, `order` 0).
const HUNGER: int = 0
const KIND_ANY: String = ""

var _setup: NpcSetup
var _places: SettlementService
var _all_places: Array[Place] = []
var _lod_params: LodParams


## Provedor espião: não soma efeito algum (só os da tabela do catálogo contam) e anota quantas vezes a função única de efeitos rodou.
class SpyProvider:
	extends ActionConditionProvider

	var food: bool = true
	var effect_calls: int = 0
	var completed_calls: int = 0

	func has_food(_settlement_id: String) -> bool:
		return food

	func extra_effects(_action_id: String, _occupation_id: String) -> Array[ActionDef.ActionEffect]:
		effect_calls += 1
		var none: Array[ActionDef.ActionEffect] = []
		return none

	func on_action_completed(_action_id: String, _settlement_id: String, _occupation_id: String) -> void:
		completed_calls += 1


## Um mundo de teste: um NPC, o LOD, o quadro de Intents, o runner do jogo e o espião.
class Bench:
	extends RefCounted

	var states: Dictionary[int, NpcState] = {}
	var lod: NpcLod
	var board: NpcIntentBoard
	var runner: EmbodiedActionRunner
	var spy: SpyProvider = SpyProvider.new()

	func npc() -> NpcState:
		return states[NPC_ID]


func before_all() -> void:
	var data: NpcLifeCheck.GameData = NpcLifeCheck.load_game_data()
	assert_eq(data.problem, "", "Os dados reais do jogo carregam.")
	_all_places = data.places
	_places = SettlementService.new(data.settlements, data.places)
	_setup = NpcSetup.from_dir(DATA_DIR, _places)
	assert_true(_setup.result.ok, _setup.result.message)
	var loaded: LodParamsLoader.LoadResult = LodParamsLoader.load_dir()
	assert_true(loaded.result.ok, loaded.result.message)
	_lod_params = loaded.params


# ---------------------------------------------------------------------------------------------------- montagem

## Primeiro local do tipo (ordem de ID) no assentamento A; tipo vazio = qualquer lugar (a casa).
func _place_of_kind(kind: String) -> Place:
	var wanted: String = Place.KIND_HOME if kind == KIND_ANY else kind
	var found: Place = null
	for place: Place in _all_places:
		if place.settlement_id == SETTLEMENT and place.kind == wanted and (found == null or place.id < found.id):
			found = place
	assert_not_null(found, "O assentamento A tem um local do tipo '%s'." % wanted)
	return found


func _position_cm(place: Place) -> Vector2i:
	return Vector2i(roundi(place.position.x * TerrainData.CM_PER_METER), roundi(place.position.z * TerrainData.CM_PER_METER))


## O mesmo NPC e o mesmo mundo, sempre: em casa, com as necessidades no meio. `in_s0`: o foco do ator está sobre ele e ele ganha corpo.
func _bench(in_s0: bool) -> Bench:
	var bench: Bench = Bench.new()
	var home: Place = _place_of_kind(Place.KIND_HOME)
	var spec: NpcSpec = NpcSpec.new()
	spec.name_key = "npc.name.villager"
	spec.settlement_id = SETTLEMENT
	spec.place_id = home.id
	spec.home_place_id = home.id
	spec.x_cm = _position_cm(home).x
	spec.z_cm = _position_cm(home).y
	var start_needs: PackedInt64Array = PackedInt64Array()
	start_needs.resize(NpcState.NEED_COUNT)
	start_needs.fill(START_NEED_VALUE)
	bench.states[NPC_ID] = NpcState.from_spec(NPC_ID, spec, START_MIN, start_needs)
	bench.lod = NpcLod.new(_lod_params)
	bench.board = NpcIntentBoard.new(bench.lod)
	bench.runner = EmbodiedActionRunner.new(bench.states, _setup.definitions.actions, _setup.need_defs, _places, bench.spy, WALK_SPEED_CM_PER_MIN, bench.board.has_pending)
	var linked: Result = bench.board.configure(bench.runner, bench.states, _places, NpcIntentParams.new(TIMEOUT_MIN))
	assert_true(linked.ok, linked.message)
	if in_s0:
		assert_true(bench.lod.set_focus(ACTOR_ID, home.position).ok)
		bench.lod.update(bench.states, START_MIN)
		assert_eq(bench.lod.level_of(NPC_ID), NpcLod.LEVEL_S0, "O NPC sob o foco ganha corpo.")
	return bench


## O local da ação: o do tipo dela; `go_to_place` vai ao trabalho (outro local, para o NPC andar de verdade).
func _target_of(action: ActionDef) -> String:
	if action.id == ActionRunner.GO_TO_PLACE_ID:
		return _place_of_kind(Place.KIND_WORK).id
	return _place_of_kind(action.place_kind).id


func _start(bench: Bench, in_s0: bool, action_id: String, place_id: String) -> Result:
	if in_s0:
		return bench.board.begin_embodied(NPC_ID, action_id, place_id, START_MIN)
	return bench.runner.begin(NPC_ID, action_id, place_id, START_MIN)


## Termina a ação que está em andamento no fim previsto e devolve o desfecho do `advance`. S0: o corpo relata (no destino, se é um Intent de ida),
## o pensador fecha no pensamento seguinte.
func _finish(bench: Bench, in_s0: bool) -> ActionRunner.AdvanceResult:
	var end_min: int = bench.npc().action_ends_at
	if in_s0:
		assert_eq(bench.runner.advance(NPC_ID, end_min).outcome, ActionRunner.Outcome.RUNNING, "Com Intent pendente o relógio não encerra a ação.")
		var intent: NpcIntent = bench.board.peek_pending()[0]
		var outcome: NpcActionResult.Outcome = NpcActionResult.Outcome.ARRIVED if intent.kind == NpcIntent.Kind.MOVE_TO_PLACE else NpcActionResult.Outcome.DONE
		var body_m: Vector3 = Vector3(intent.destination_cm.x / TerrainData.CM_PER_METER, 0.0, intent.destination_cm.y / TerrainData.CM_PER_METER)
		var reported: Result = bench.board.report_result(NpcActionResult.new(NPC_ID, intent.action_serial, outcome, body_m), end_min)
		assert_true(reported.ok, reported.message)
	return bench.runner.advance(NPC_ID, end_min)


func _state_text(bench: Bench) -> String:
	return JSON.stringify(bench.npc().to_dict(), "", true, true)


## O estado do NPC sobrevive à ida e volta do save (o que o `validate` do módulo exige dele).
func _assert_valid(bench: Bench, label: String) -> void:
	var parsed: NpcState.ParseResult = NpcState.parse(NPC_ID, bench.npc().to_dict())
	assert_eq(parsed.error, "", "%s: o estado final é um estado válido de save." % label)


## Roda a ação inteira num dos modos e devolve a bancada no fim.
func _complete(action: ActionDef, in_s0: bool) -> Bench:
	var bench: Bench = _bench(in_s0)
	var label: String = "%s em %s" % [action.id, "S0" if in_s0 else "S1"]
	var started: Result = _start(bench, in_s0, action.id, _target_of(action))
	assert_true(started.ok, "%s: começa. %s" % [label, started.message])
	assert_eq(bench.board.peek_pending().size(), 1 if in_s0 else 0, "%s: só o NPC com corpo tem Intent." % label)
	assert_eq(bench.spy.effect_calls, 0, "%s: os efeitos não entram ao começar." % label)
	var finished: ActionRunner.AdvanceResult = _finish(bench, in_s0)
	assert_eq(finished.outcome, ActionRunner.Outcome.COMPLETED, "%s: termina completa. %s" % [label, finished.result.message])
	assert_eq(bench.spy.effect_calls, 1, "%s: a função única de efeitos rodou uma vez." % label)
	assert_eq(bench.spy.completed_calls, 1, "%s: o aviso de ação completa saiu uma vez." % label)
	assert_eq(bench.npc().action_id, "", "%s: o NPC ficou livre." % label)
	assert_eq(bench.board.peek_pending().size(), 0, "%s: nenhum Intent sobrou." % label)
	_assert_valid(bench, label)
	return bench


# ---------------------------------------------------------------------------------------------------- aceite

func test_every_catalog_action_leaves_the_same_final_state_in_s1_and_in_s0() -> void:
	var catalog: Array[ActionDef] = _setup.definitions.actions
	assert_gt(catalog.size(), 0, "O catálogo real não está vazio (senão o teste passaria vazio).")
	var compared: int = 0
	for action: ActionDef in catalog:
		var abstract_world: Bench = _complete(action, false)
		var embodied_world: Bench = _complete(action, true)
		assert_eq(_state_text(embodied_world), _state_text(abstract_world), "Ação '%s': o estado final do NPC com corpo difere do abstrato." % action.id)
		compared += 1
	assert_eq(compared, catalog.size(), "Todas as ações do catálogo foram comparadas.")


func test_the_comparison_sees_a_real_effect_and_a_real_walk() -> void:
	var catalog: Array[ActionDef] = _setup.definitions.actions
	var by_id: Dictionary[String, ActionDef] = {}
	for action: ActionDef in catalog:
		by_id[action.id] = action
	assert_true(by_id.has(FOOD_ACTION_ID) and by_id.has(ActionRunner.GO_TO_PLACE_ID), "O catálogo traz comer e ir a um local.")
	var eaten: Bench = _complete(by_id[FOOD_ACTION_ID], true)
	assert_lt(eaten.npc().need_values[HUNGER], START_NEED_VALUE, "Comer alivia a fome (o estado comparado muda de verdade).")
	var walked: Bench = _complete(by_id[ActionRunner.GO_TO_PLACE_ID], true)
	var work: Place = _place_of_kind(Place.KIND_WORK)
	assert_eq([walked.npc().place_id, Vector2i(walked.npc().x_cm, walked.npc().z_cm)], [work.id, _position_cm(work)], "Ir a um local leva o NPC ao destino, nos dois modos.")


# ---------------------------------------------------------------------------------------------------- erro

func test_a_condition_that_is_not_met_applies_no_effect_in_either_mode() -> void:
	var eat: ActionDef = null
	for action: ActionDef in _setup.definitions.actions:
		if action.id == FOOD_ACTION_ID:
			eat = action
	assert_not_null(eat, "O catálogo traz comer.")
	var place_id: String = _target_of(eat)
	for in_s0: bool in [false, true]:
		var refused: Bench = _bench(in_s0)
		var untouched: String = _state_text(refused)
		refused.spy.food = false
		var denied: Result = _start(refused, in_s0, FOOD_ACTION_ID, place_id)
		assert_eq(denied.code, ActionRunner.CODE_CONDITION_NOT_MET, "Sem comida a ação não começa (S0: %s)." % str(in_s0))
		assert_eq([_state_text(refused), refused.spy.effect_calls, refused.board.peek_pending().size()], [untouched, 0, 0], "Recusada: nada muda e nenhum Intent sai (S0: %s)." % str(in_s0))
		var failing: Bench = _bench(in_s0)
		assert_true(_start(failing, in_s0, FOOD_ACTION_ID, place_id).ok)
		failing.spy.food = false
		var finished: ActionRunner.AdvanceResult = _finish(failing, in_s0)
		assert_eq([finished.outcome, finished.result.code], [ActionRunner.Outcome.FAILED, ActionRunner.CODE_ACTION_FAILED], "Sem comida ao terminar, a ação falha por regra (S0: %s)." % str(in_s0))
		assert_eq([failing.spy.effect_calls, failing.spy.completed_calls, failing.npc().need_values[HUNGER] >= START_NEED_VALUE], [0, 0, true], "Falha por regra: nenhum efeito entra (S0: %s)." % str(in_s0))
		assert_eq(failing.npc().action_id, "", "O NPC é liberado (S0: %s)." % str(in_s0))


# ---------------------------------------------------------------------------------------------------- caso-limite

func test_a_trip_to_the_place_the_npc_is_already_at_lasts_the_minimum_minute_in_both_modes() -> void:
	var home: Place = _place_of_kind(Place.KIND_HOME)
	var results: Array[String] = []
	for in_s0: bool in [false, true]:
		var bench: Bench = _bench(in_s0)
		var started: Result = _start(bench, in_s0, ActionRunner.GO_TO_PLACE_ID, home.id)
		assert_true(started.ok, started.message)
		assert_eq(bench.npc().action_ends_at - START_MIN, ActionRunner.MIN_TRAVEL_MINUTES, "Mesma posição: a viagem dura o mínimo de 1 minuto.")
		if in_s0:
			assert_eq(bench.board.peek_pending()[0].expected_minutes, ActionRunner.MIN_TRAVEL_MINUTES, "O Intent espera 1 minuto.")
		assert_eq(_finish(bench, in_s0).outcome, ActionRunner.Outcome.COMPLETED)
		assert_eq([bench.npc().place_id, Vector2i(bench.npc().x_cm, bench.npc().z_cm)], [home.id, _position_cm(home)], "O NPC continua onde estava.")
		assert_eq(bench.spy.effect_calls, 1)
		results.append(_state_text(bench))
	assert_eq(results[1], results[0], "Viagem de 1 minuto: o mesmo estado final nos dois modos.")
