extends GutTest
## LW-083b: a porta da conversa do jogador com um NPC (`NpcModule.request_converse` e `NpcPlayerTalk`), sem janela. A validação e o cooldown são testados com uma
## tabela de NPCs à mão e a parada trocada por um espião; o campo `last_player_talk_at` do estado (salvar, carregar, conferir) pelo módulo; e uma volta inteira
## com os dados reais prova a fiação (módulo, porta e parada). Promoção, relação e memória são da LW-083c; texto e tela, da 083d e da 083e.

const DATA_DIR: String = "res://data"
const SETTLEMENT: String = "test_settlement_a"
const NPC_ID: int = 1
const ACTOR_ID: int = 77
const NOW: int = 1000
## Onde o NPC e o foco estão (m), todos em S0.
const SPOT_M: Vector3 = Vector3(50.0, 0.0, 60.0)
const COOLDOWN: int = NpcPlayerTalk.TALK_COOLDOWN_MIN


## A parada trocada por um espião: anota quem foi mandado conversar e responde o que o teste mandar; `related` diz se o jogador e o NPC já se conhecem.
class Spy:
	extends RefCounted

	var started: Array[int] = []
	var answer: Result = Result.success()
	var related: bool = false

	func begin(npc_id: int) -> Result:
		started.append(npc_id)
		return answer

	func relation(_a_id: int, _b_id: int) -> PackedInt64Array:
		return PackedInt64Array([1, 0, 0, 0, 0]) if related else PackedInt64Array()


class Bench:
	extends RefCounted

	var states: Dictionary[int, NpcState] = {}
	var lod: NpcLod
	var spy: Spy = Spy.new()
	var talk: NpcPlayerTalk

	func npc() -> NpcState:
		return states[NPC_ID]


func _unknown(_caller: String, npc_id: int) -> Result:
	return Result.failure(NpcModule.CODE_UNKNOWN, "NPC %d inexistente." % npc_id)


## Um NPC vivo em casa; `in_s0`: o foco do ator está sobre ele e ele ganha corpo.
func _bench(in_s0: bool = true) -> Bench:
	var bench: Bench = Bench.new()
	var state: NpcState = NpcState.new(NPC_ID)
	state.x_cm = roundi(SPOT_M.x * NpcLod.CM_PER_METER_FLOAT)
	state.z_cm = roundi(SPOT_M.z * NpcLod.CM_PER_METER_FLOAT)
	bench.states[NPC_ID] = state
	var loaded: LodParamsLoader.LoadResult = LodParamsLoader.load_dir()
	assert_true(loaded.result.ok, loaded.result.message)
	bench.lod = NpcLod.new(loaded.params)
	if in_s0:
		assert_true(bench.lod.set_focus(ACTOR_ID, SPOT_M).ok)
		bench.lod.update(bench.states, NOW)
		assert_eq(bench.lod.level_of(NPC_ID), NpcLod.LEVEL_S0, "O NPC sob o foco ganha corpo.")
	bench.talk = NpcPlayerTalk.new(bench.states, bench.lod, bench.spy.begin, bench.spy.relation, _unknown)
	return bench


## O ator a `east_m` metros a leste (e `north_m` ao norte) do corpo do NPC.
func _near(bench: Bench, east_m: float, north_m: float = 0.0) -> Vector3:
	var body_cm: Vector2i = bench.lod.position_of(NPC_ID)
	return Vector3(float(body_cm.x) / NpcLod.CM_PER_METER_FLOAT + east_m, 0.0, float(body_cm.y) / NpcLod.CM_PER_METER_FLOAT + north_m)


func _ask(bench: Bench, at: Vector3, now: int = NOW, npc_id: int = NPC_ID) -> NpcModule.ConverseResult:
	return bench.talk.converse(ACTOR_ID, at, npc_id, now)


## Pedido recusado com o código esperado, sem chamar a parada e sem mudar o estado do NPC.
func _assert_refused(bench: Bench, reply: NpcModule.ConverseResult, code: String, label: String, before: String) -> void:
	assert_eq(reply.result.code, code, "%s: %s" % [label, reply.result.message])
	assert_eq([reply.text_key, reply.was_promoted, bench.spy.started.size()], ["", false, 0], "%s: sem texto e sem parada." % label)
	assert_eq(JSON.stringify(bench.npc().to_dict()), before, "%s: o estado do NPC não mudou." % label)


# ---------------------------------------------------------------------------------------------------- a validação

func test_the_reach_is_three_meters_horizontal_and_inclusive() -> void:
	var bench: Bench = _bench()
	var before: String = JSON.stringify(bench.npc().to_dict())
	_assert_refused(bench, _ask(bench, _near(bench, 3.01)), NpcModule.CODE_TALK_TOO_FAR, "3,01 m", before)
	_assert_refused(bench, _ask(bench, _near(bench, 2.2, 2.2)), NpcModule.CODE_TALK_TOO_FAR, "diagonal de 3,11 m", before)
	assert_true(_ask(bench, _near(bench, 3.0)).result.ok, "Exatamente 3,00 m aceita.")
	var diagonal: Bench = _bench()
	assert_true(_ask(diagonal, _near(diagonal, 2.1, 2.1)).result.ok, "Diagonal de 2,97 m aceita.")
	var raised: Bench = _bench()
	assert_true(_ask(raised, _near(raised, 0.0) + Vector3(0.0, 40.0, 0.0)).result.ok, "A altura não conta: a distância é horizontal.")


func test_every_refusal_has_its_code_and_leaves_no_trace() -> void:
	var bench: Bench = _bench()
	var near: Vector3 = _near(bench, 1.0)
	var before: String = JSON.stringify(bench.npc().to_dict())
	_assert_refused(bench, _ask(bench, near, NOW, 999), NpcModule.CODE_UNKNOWN, "inexistente", before)
	for bad: Vector3 in [Vector3(NAN, 0.0, 60.0), Vector3(50.0, 0.0, INF), Vector3(-1.0, 0.0, 60.0), Vector3(1.0e9, 0.0, 60.0)]:
		_assert_refused(bench, _ask(bench, bad), NpcLod.CODE_INVALID_POSITION, "posição %s" % str(bad), before)
	for busy_action: String in ["sleep", "flee", "help"]:
		bench.npc().action_id = busy_action
		var busy_before: String = JSON.stringify(bench.npc().to_dict())
		_assert_refused(bench, _ask(bench, near), NpcModule.CODE_TALK_BUSY, "ocupado em %s" % busy_action, busy_before)
	bench.npc().action_id = "work"
	assert_true(_ask(bench, near).result.ok, "Trabalhando, o NPC atende (a parada interrompe o trabalho).")
	var asleep: Bench = _bench(false)
	_assert_refused(asleep, _ask(asleep, near), NpcLod.CODE_NOT_IN_S0, "sem corpo", JSON.stringify(asleep.npc().to_dict()))
	var dead: Bench = _bench()
	dead.npc().is_alive = false
	_assert_refused(dead, _ask(dead, near), NpcTiers.CODE_DEAD, "morto", JSON.stringify(dead.npc().to_dict()))


func test_the_alarm_window_and_the_cooldown_have_exact_edges() -> void:
	var bench: Bench = _bench()
	var near: Vector3 = _near(bench, 1.0)
	bench.npc().alarm_until = NOW + 1
	var alarmed: String = JSON.stringify(bench.npc().to_dict())
	_assert_refused(bench, _ask(bench, near), NpcModule.CODE_TALK_BUSY, "alarme aberto", alarmed)
	bench.npc().alarm_until = NOW
	assert_true(_ask(bench, near).result.ok, "A janela fecha no minuto em que termina (alarm_until é exclusivo).")
	var cooling: Bench = _bench()
	cooling.npc().last_player_talk_at = NOW - (COOLDOWN - 1)
	var cooling_before: String = JSON.stringify(cooling.npc().to_dict())
	_assert_refused(cooling, _ask(cooling, near), NpcModule.CODE_TALK_COOLDOWN, "59 min depois", cooling_before)
	cooling.npc().last_player_talk_at = NOW - COOLDOWN
	assert_true(_ask(cooling, near).result.ok, "60 min depois aceita.")


func test_an_accepted_request_stores_the_cooldown_and_picks_first_or_known() -> void:
	var bench: Bench = _bench()
	var near: Vector3 = _near(bench, 1.0)
	var first: NpcModule.ConverseResult = _ask(bench, near)
	assert_true(first.result.ok, first.result.message)
	assert_eq([first.text_key, first.was_promoted, bench.spy.started, bench.npc().last_player_talk_at], [NpcPlayerTalk.TEXT_KEY_FIRST, false, [NPC_ID], NOW])
	assert_eq(_ask(bench, near, NOW + 5).result.code, NpcModule.CODE_TALK_COOLDOWN, "Enquanto conversa (ou logo depois) o cooldown vale.")
	bench.spy.related = true
	var known: NpcModule.ConverseResult = _ask(bench, near, NOW + COOLDOWN)
	assert_eq([known.result.ok, known.text_key, bench.npc().last_player_talk_at], [true, NpcPlayerTalk.TEXT_KEY_KNOWN, NOW + COOLDOWN], "Com relação existente a chave é known.")


func test_a_failed_start_is_passed_through_and_stores_no_cooldown() -> void:
	var bench: Bench = _bench()
	bench.spy.answer = Result.failure(NpcModule.CODE_NOT_READY, "sem pensador")
	var reply: NpcModule.ConverseResult = _ask(bench, _near(bench, 1.0))
	assert_eq([reply.result.code, reply.text_key, bench.npc().last_player_talk_at], [NpcModule.CODE_NOT_READY, "", NpcState.NO_TIME])


# ---------------------------------------------------------------------------------------------------- o campo salvo

func _module_world(module: NpcModule) -> World:
	var clock: SimClock = SimClock.new()
	var world: World = World.new(SimContext.new(clock, EventBus.new(clock), WorldRng.new(3), IdGenerator.new()))
	assert_true(world.register_module("npc", module).ok)
	world.setup()
	world.post_setup()
	return world


func test_last_player_talk_at_is_saved_only_when_set_and_survives_the_round_trip() -> void:
	var state: NpcState = NpcState.new(NPC_ID)
	assert_false(state.to_dict().has(NpcState.KEY_LAST_PLAYER_TALK_AT), "Quem nunca conversou salva (e entra no hash) como antes da LW-083b.")
	state.last_player_talk_at = 777
	var parsed: NpcState.ParseResult = NpcState.parse(NPC_ID, state.to_dict())
	assert_eq([parsed.error, parsed.state.last_player_talk_at], ["", 777], "A ida e volta do estado guarda o cooldown.")
	var module: NpcModule = NpcModule.new()
	var world: World = _module_world(module)
	var created: NpcModule.CreateResult = module.request_create_npc(_spec())
	var saved: Dictionary = module.serialize()
	var entries: Dictionary = saved["npcs"]
	var entry: Dictionary = entries[str(created.npc_id)]
	assert_false(entry.has(NpcState.KEY_LAST_PLAYER_TALK_AT), "Chave ausente no save de quem nunca conversou.")
	entry[NpcState.KEY_LAST_PLAYER_TALK_AT] = 500
	assert_true(module.on_load(saved).ok)
	var reloaded: Dictionary = module.serialize()["npcs"]
	assert_eq(reloaded[str(created.npc_id)][NpcState.KEY_LAST_PLAYER_TALK_AT], 500, "O save com o campo carrega e salva de novo igual.")
	entry[NpcState.KEY_LAST_PLAYER_TALK_AT] = "ontem"
	assert_string_contains(module.on_load(saved).message, NpcState.KEY_LAST_PLAYER_TALK_AT)
	entry[NpcState.KEY_LAST_PLAYER_TALK_AT] = -5
	assert_true(module.on_load(saved).ok, "O formato é aceito; a coerência é do validate().")
	assert_string_contains(str(module.validate()), "last_player_talk_at -5 inválido")
	world.teardown()


func _spec() -> NpcSpec:
	var spec: NpcSpec = NpcSpec.new()
	spec.name_key = "npc.name.villager"
	return spec


# ---------------------------------------------------------------------------------------------------- a porta de ponta a ponta

func test_the_door_without_setup_is_not_ready_and_the_real_flow_starts_the_conversation() -> void:
	assert_eq(NpcModule.new().request_converse(ACTOR_ID, SPOT_M, NPC_ID).result.code, NpcModule.CODE_NOT_READY)
	var data: NpcLifeCheck.GameData = NpcLifeCheck.load_game_data()
	var setup: NpcSetup = NpcSetup.from_dir(DATA_DIR, SettlementService.new(data.settlements, data.places))
	assert_true(setup.result.ok, setup.result.message)
	var module: NpcModule = NpcModule.new(setup.need_defs, setup.routine, setup.definitions)
	var world: World = _module_world(module)
	var work: Place = null
	for place: Place in data.places:
		if place.settlement_id == SETTLEMENT and place.kind == Place.KIND_WORK and (work == null or place.id < work.id):
			work = place
	var spec: NpcSpec = _spec()
	spec.occupation_id = "farmer"
	spec.settlement_id = SETTLEMENT
	spec.place_id = work.id
	spec.work_place_id = work.id
	spec.x_cm = roundi(work.position.x * NpcLod.CM_PER_METER_FLOAT)
	spec.z_cm = roundi(work.position.z * NpcLod.CM_PER_METER_FLOAT)
	for _minute: int in 7 * SimClock.MINUTES_PER_HOUR:
		world.context.clock.advance_step()
	assert_true(module.request_set_bodies_available(true).ok)
	assert_true(module.request_set_focus(ACTOR_ID, work.position).ok)
	var npc_id: int = module.request_create_npc(spec).npc_id
	for _minute: int in 15:
		world.context.clock.advance_step()
		world.tick(1)
	assert_eq(module.peek_npc(npc_id).action_id, "work", "No bloco da manhã o lavrador, com corpo, trabalha.")
	var body_cm: Vector2i = module.lod.position_of(npc_id)
	var near: Vector3 = Vector3(float(body_cm.x) / NpcLod.CM_PER_METER_FLOAT + 2.0, 0.0, float(body_cm.y) / NpcLod.CM_PER_METER_FLOAT)
	var reply: NpcModule.ConverseResult = module.request_converse(ACTOR_ID, near, npc_id)
	assert_true(reply.result.ok, reply.result.message)
	var now: int = world.context.clock.total_minutes()
	var talking: NpcModule.NpcQuery = module.peek_npc(npc_id)
	assert_eq([reply.text_key, talking.action_id, talking.action_ends_at], [NpcPlayerTalk.TEXT_KEY_FIRST, "talk_player", now + 6], "O NPC parou para conversar.")
	assert_eq(module.request_converse(ACTOR_ID, near, npc_id).result.code, NpcModule.CODE_TALK_COOLDOWN)
	world.teardown()
