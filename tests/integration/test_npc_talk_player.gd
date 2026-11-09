extends GutTest
## LW-083a: a ação `talk_player` e a parada do NPC para conversar (NpcDecisionRuntime.begin_talk_player), sem janela e com os dados reais. O NPC com corpo
## (S0) interrompe o que fazia pelo caminho do alarme (cancela sem efeito), ganha a Intent ACT_AT_PLACE de local vazio (o corpo fica onde está), só pensa
## de novo no fim da conversa e retoma a rotina; sem corpo (S1) é recusado sem tocar em nada. Bancada: peças do jogo ligadas como em `NpcModule`; o
## relógio anda minuto a minuto e o teste faz o papel do corpo. Relação, promoção e memória são da LW-083c.

const DATA_DIR: String = "res://data"
const SETTLEMENT: String = "test_settlement_a"
const NPC_ID: int = 1
const ACTOR_ID: int = 77
## 07:00, o começo do bloco de trabalho do lavrador (data/routine_blocks.json).
const START_MIN: int = 420
const TALK: String = "talk_player"
const WORK: String = "work"
const TALK_MIN: int = 6
## Com 200 min de trabalho feitos (de 240), o efeito proporcional do `work` seria 4 de descanso: se o cancelamento o aplicasse, o teste veria.
const WORK_DONE_MIN: int = 200
const CAUTIOUS: Array[int] = [95, 10, 50, 10]

var _setup: NpcSetup
var _all_places: Array[Place] = []
var _lod_params: LodParams


## Um mundo de teste: um NPC, o relógio, o LOD, os corpos, o quadro de Intents e o runtime de decisão do jogo.
class Bench:
	extends RefCounted

	var states: Dictionary[int, NpcState] = {}
	var clock: SimClock = SimClock.new()
	var lod: NpcLod
	var board: NpcIntentBoard
	var bodies: NpcBodies
	var runtime: NpcDecisionRuntime

	func npc() -> NpcState:
		return states[NPC_ID]


func before_all() -> void:
	var data: NpcLifeCheck.GameData = NpcLifeCheck.load_game_data()
	assert_eq(data.problem, "", "Os dados reais do jogo carregam.")
	_all_places = data.places
	_setup = NpcSetup.from_dir(DATA_DIR, SettlementService.new(data.settlements, data.places))
	assert_true(_setup.result.ok, _setup.result.message)
	var loaded: LodParamsLoader.LoadResult = LodParamsLoader.load_dir()
	assert_true(loaded.result.ok, loaded.result.message)
	_lod_params = loaded.params


func _place_of_kind(kind: String) -> Place:
	var found: Place = null
	for place: Place in _all_places:
		if place.settlement_id == SETTLEMENT and place.kind == kind and (found == null or place.id < found.id):
			found = place
	assert_not_null(found, "O assentamento A tem um local do tipo '%s'." % kind)
	return found


func _unknown(_caller: String, npc_id: int) -> Result:
	return Result.failure(ActionRunner.CODE_UNKNOWN_NPC, "NPC %d inexistente." % npc_id)


## O lavrador no trabalho (ou em casa), com as necessidades de partida e o relógio em START_MIN; ainda não pensou. `in_s0`: o foco do ator está sobre ele.
func _bench(in_s0: bool, at_home: bool = false, traits: Array[int] = []) -> Bench:
	var bench: Bench = Bench.new()
	var home: Place = _place_of_kind(Place.KIND_HOME)
	var spot: Place = home if at_home else _place_of_kind(Place.KIND_WORK)
	for _minute: int in START_MIN:
		bench.clock.advance_step()
	var spec: NpcSpec = NpcSpec.new()
	spec.name_key = "npc.name.villager"
	spec.occupation_id = "farmer"
	spec.settlement_id = SETTLEMENT
	spec.place_id = spot.id
	spec.home_place_id = home.id
	spec.work_place_id = _place_of_kind(Place.KIND_WORK).id
	spec.x_cm = roundi(spot.position.x * TerrainData.CM_PER_METER)
	spec.z_cm = roundi(spot.position.z * TerrainData.CM_PER_METER)
	if not traits.is_empty():
		spec.traits = PackedInt64Array(traits)
	var start_needs: PackedInt64Array = PackedInt64Array()
	start_needs.resize(NpcState.NEED_COUNT)
	for def: NeedDef in _setup.need_defs:
		start_needs[def.order] = def.start_value
	bench.states[NPC_ID] = NpcState.from_spec(NPC_ID, spec, START_MIN, start_needs)
	bench.lod = NpcLod.new(_lod_params)
	bench.board = NpcIntentBoard.new(bench.lod)
	bench.bodies = NpcBodies.new(bench.lod, bench.board, bench.states)
	var ctx: SimContext = SimContext.new(bench.clock, EventBus.new(bench.clock), WorldRng.new(3), IdGenerator.new())
	bench.bodies.setup(ctx, null)
	var tracer: DecisionTracer = DecisionTracer.new()
	var notables: NpcNotables = NpcNotables.new(bench.states, _setup.definitions, _unknown)
	var lifecycle: NpcLifecycle = NpcLifecycle.new(bench.states, notables, tracer, _setup.need_defs, "", _setup.routine, _setup.definitions, _unknown)
	bench.runtime = NpcDecisionRuntime.new(bench.states, bench.bodies, bench.board, notables, lifecycle, tracer, _setup.definitions, _setup.need_defs, "", _setup.routine)
	bench.runtime.setup(ctx)
	if in_s0:
		assert_true(bench.lod.set_focus(ACTOR_ID, spot.position).ok)
		bench.lod.update(bench.states, START_MIN)
		assert_eq(bench.lod.level_of(NPC_ID), NpcLod.LEVEL_S0, "O NPC sob o foco ganha corpo.")
	return bench


## Anda `minutes` minutos como o módulo: o relógio, os corpos (LOD e Intents) e a fila de pensamento. O corpo (o teste) não responde.
func _advance(bench: Bench, minutes: int) -> void:
	for _minute: int in minutes:
		bench.clock.advance_step()
		bench.bodies.tick()
		bench.runtime.run_step()


func _working_bench(minutes_working: int) -> Bench:
	var bench: Bench = _bench(true)
	_advance(bench, minutes_working)
	assert_eq(bench.npc().action_id, WORK, "No bloco da manhã o lavrador trabalha, e segue trabalhando.")
	return bench


func _state_text(bench: Bench) -> String:
	return JSON.stringify(bench.npc().to_dict(), "", true, true)


## As necessidades que o NPC teria em `minute` SEM nenhum efeito de ação: o estado salvo e relido, levado até lá (só o tempo passando).
func _needs_without_effects(bench: Bench, minute: int) -> PackedInt64Array:
	var twin: NpcState = NpcState.parse(NPC_ID, bench.npc().to_dict()).state
	assert_true(NeedMath.settle(twin, _setup.need_defs, minute).ok)
	return twin.need_values


func test_the_real_catalog_has_talk_player_without_effects_conditions_or_weights() -> void:
	var talk: ActionDef = null
	for action: ActionDef in _setup.definitions.actions:
		if action.id == TALK:
			talk = action
	assert_not_null(talk, "A ação talk_player está no catálogo real.")
	assert_eq([talk.duration_min, talk.place_kind, talk.interruptible, talk.risk], [TALK_MIN, "", true, 0], "Seis minutos, sem local, interrompível, sem risco.")
	assert_eq([talk.effects.size(), talk.conditions.size(), talk.trait_weights.size()], [0, 0, 0], "Sem efeitos, sem condições e sem pesos de traço.")


func test_a_working_npc_with_a_body_stops_and_gets_an_intent_that_keeps_the_body_in_place() -> void:
	var bench: Bench = _working_bench(WORK_DONE_MIN)
	var work_serial: int = bench.npc().action_serial
	var expected_needs: PackedInt64Array = _needs_without_effects(bench, bench.clock.total_minutes())
	var started: Result = bench.runtime.begin_talk_player(NPC_ID)
	assert_true(started.ok, started.message)
	var npc: NpcState = bench.npc()
	assert_eq([npc.action_id, npc.action_target_place_id, npc.action_serial], [TALK, "", work_serial + 1], "A conversa tomou o lugar do trabalho.")
	assert_eq([npc.action_started_at, npc.action_ends_at], [bench.clock.total_minutes(), bench.clock.total_minutes() + TALK_MIN])
	assert_eq(npc.need_values, expected_needs, "O trabalho cancelado não aplicou efeito (nem o proporcional): só o tempo passou.")
	var queued: Array[NpcIntent] = bench.board.peek_pending()
	assert_eq(queued.size(), 1, "Só a Intent da conversa: a do trabalho saiu.")
	assert_eq([queued[0].kind, queued[0].place_id, queued[0].action_serial, queued[0].expected_minutes], [NpcIntent.Kind.ACT_AT_PLACE, "", npc.action_serial, TALK_MIN])
	assert_eq(queued[0].destination_cm, bench.lod.position_of(NPC_ID), "O destino é onde o corpo já está: ele não anda.")


func test_the_npc_does_not_think_during_the_talk_then_finishes_without_effect_and_resumes_the_routine() -> void:
	var bench: Bench = _working_bench(10)
	assert_true(bench.runtime.begin_talk_player(NPC_ID).ok)
	var talk_serial: int = bench.npc().action_serial
	var end_min: int = bench.npc().action_ends_at
	assert_eq(bench.npc().next_think_time, end_min, "Pensa de novo só no fim da conversa (a regra do pensador: o fim vem antes do intervalo).")
	_advance(bench, TALK_MIN - 1)
	assert_eq([bench.npc().action_id, bench.npc().action_serial], [TALK, talk_serial], "No meio da conversa nada mudou.")
	bench.clock.advance_step()
	var intent: NpcIntent = bench.board.peek_pending()[0]
	var body_m: Vector3 = Vector3(intent.destination_cm.x / TerrainData.CM_PER_METER, 0.0, intent.destination_cm.y / TerrainData.CM_PER_METER)
	var reported: Result = bench.board.report_result(NpcActionResult.new(NPC_ID, intent.action_serial, NpcActionResult.Outcome.DONE, body_m), end_min)
	assert_true(reported.ok, reported.message)
	var expected_needs: PackedInt64Array = _needs_without_effects(bench, end_min)
	bench.bodies.tick()
	bench.runtime.run_step()
	assert_eq(bench.npc().need_values, expected_needs, "Terminar a conversa não mexe nas necessidades.")
	assert_eq([bench.npc().action_id, bench.npc().action_serial > talk_serial, bench.board.peek_pending().size()], [WORK, true, 1], "Voltou à rotina: o trabalho recomeçou com Intent nova.")


func test_an_alarm_in_the_middle_of_the_talk_makes_a_cautious_npc_flee() -> void:
	var bench: Bench = _bench(true, true, CAUTIOUS)
	assert_true(bench.runtime.begin_talk_player(NPC_ID).ok, "Sem ação em curso (limite): nada a interromper, a conversa começa.")
	_advance(bench, 2)
	bench.runtime.react_to_alarm(AlarmRaised.new(bench.npc().x_cm, bench.npc().z_cm, 10), [NPC_ID])
	assert_eq(bench.npc().action_id, "flee", "O alarme interrompeu a conversa e o NPC cauteloso foge.")
	assert_eq(bench.board.peek_pending().size(), 1, "A Intent da conversa saiu e a da fuga entrou.")


func test_a_npc_without_a_body_is_refused_and_nothing_changes() -> void:
	var bench: Bench = _bench(false)
	var before: String = _state_text(bench)
	var refused: Result = bench.runtime.begin_talk_player(NPC_ID)
	assert_eq(refused.code, NpcLod.CODE_NOT_IN_S0, refused.message)
	assert_eq([_state_text(bench), bench.board.peek_pending().size()], [before, 0], "O estado ficou igual e nenhuma Intent nasceu.")


func test_unknown_dead_and_already_talking_npcs_are_refused_and_nothing_changes() -> void:
	var bench: Bench = _working_bench(10)
	assert_eq(bench.runtime.begin_talk_player(999).code, ActionRunner.CODE_UNKNOWN_NPC)
	assert_true(bench.runtime.begin_talk_player(NPC_ID).ok)
	_advance(bench, 2)
	var talking: String = _state_text(bench)
	assert_eq(bench.runtime.begin_talk_player(NPC_ID).code, ActionRunner.CODE_BUSY)
	assert_eq(_state_text(bench), talking, "Pedir de novo não renova o fim da conversa nem o contador de ações.")
	bench.npc().is_alive = false
	var dead: String = _state_text(bench)
	assert_eq(bench.runtime.begin_talk_player(NPC_ID).code, ActionRunner.CODE_NOT_ALIVE)
	assert_eq(_state_text(bench), dead, "O NPC morto não foi tocado.")
