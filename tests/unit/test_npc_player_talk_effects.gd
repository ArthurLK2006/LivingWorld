extends GutTest
## LW-083c: o que a conversa do jogador faz no mundo (NpcModule.request_converse), sem janela e com os dados reais: promove o NPC a T2 se houver vaga (teto cheio: a
## conversa acontece sem promover e sem memória), sobe a relação com o jogador (o ganho da conversa entre NPCs, +3 até o teto 60) e grava a memória `conversation`.
## Um lavrador de verdade, com corpo (S0) e trabalhando; o jogador é o ator 900. A validação, o alcance e o cooldown são do test_npc_player_talk.gd.

const DATA_DIR: String = "res://data"
const SETTLEMENT: String = "test_settlement_a"
const ACTOR_ID: int = 900
const COOLDOWN: int = NpcPlayerTalk.TALK_COOLDOWN_MIN
const GAIN: int = 3
const LIMIT: int = 60


class Game:
	extends RefCounted

	var world: World
	var module: NpcModule
	var npc_id: int = 0


func _module_world(module: NpcModule) -> World:
	var clock: SimClock = SimClock.new()
	var world: World = World.new(SimContext.new(clock, EventBus.new(clock), WorldRng.new(3), IdGenerator.new()))
	assert_true(world.register_module("npc", module).ok)
	world.setup()
	world.post_setup()
	return world


func _spec(tier: int) -> NpcSpec:
	var spec: NpcSpec = NpcSpec.new()
	spec.name_key = "npc.name.villager"
	spec.tier = tier
	return spec


## Um lavrador (T1, ou `tier`) trabalhando em S0 às 07:15, mais `fill` notáveis longe dele (para encher o teto de T2). `with_memory` falso tira os tipos de memória.
func _game(tier: int = NpcState.TIER_NORMAL, fill: int = 0, with_memory: bool = true) -> Game:
	var data: NpcLifeCheck.GameData = NpcLifeCheck.load_game_data()
	var setup: NpcSetup = NpcSetup.from_dir(DATA_DIR, SettlementService.new(data.settlements, data.places), true)
	assert_true(setup.result.ok, setup.result.message)
	if not with_memory:
		setup.definitions.memory_kinds = []
	var game: Game = Game.new()
	game.module = NpcModule.new(setup.need_defs, setup.routine, setup.definitions)
	game.world = _module_world(game.module)
	var work: Place = null
	for place: Place in data.places:
		if place.settlement_id == SETTLEMENT and place.kind == Place.KIND_WORK and (work == null or place.id < work.id):
			work = place
	for _minute: int in 7 * SimClock.MINUTES_PER_HOUR:
		game.world.context.clock.advance_step()
	assert_true(game.module.request_set_bodies_available(true).ok)
	assert_true(game.module.request_set_focus(ACTOR_ID, work.position).ok)
	for _index: int in fill:
		assert_true(game.module.request_create_npc(_spec(NpcState.TIER_NOTABLE)).result.ok, "Os notáveis de enchimento nascem.")
	var spec: NpcSpec = _spec(tier)
	spec.occupation_id = "farmer"
	spec.settlement_id = SETTLEMENT
	spec.place_id = work.id
	spec.work_place_id = work.id
	spec.x_cm = roundi(work.position.x * NpcLod.CM_PER_METER_FLOAT)
	spec.z_cm = roundi(work.position.z * NpcLod.CM_PER_METER_FLOAT)
	game.npc_id = game.module.request_create_npc(spec).npc_id
	_run(game, 15)
	assert_eq(game.module.peek_npc(game.npc_id).action_id, "work", "No bloco da manhã o lavrador, com corpo, trabalha.")
	return game


func _run(game: Game, minutes: int) -> void:
	for _minute: int in minutes:
		game.world.context.clock.advance_step()
		game.world.tick(1)
		game.world.context.events.dispatch()


## O jogador a 2 m do corpo do NPC.
func _near(game: Game) -> Vector3:
	var body_cm: Vector2i = game.module.lod.position_of(game.npc_id)
	return Vector3(float(body_cm.x) / NpcLod.CM_PER_METER_FLOAT + 2.0, 0.0, float(body_cm.y) / NpcLod.CM_PER_METER_FLOAT)


func _talk(game: Game) -> NpcModule.ConverseResult:
	return game.module.request_converse(ACTOR_ID, _near(game), game.npc_id)


func _values(game: Game) -> Array[int]:
	var opinion: NpcModule.OpinionQuery = game.module.peek_opinion(ACTOR_ID, game.npc_id)
	var shown: Array[int] = []
	if opinion.is_known:
		shown.assign([opinion.values[NpcRelation.DIM_AFFECTION], opinion.values[NpcRelation.DIM_TRUST], opinion.values[NpcRelation.DIM_RESPECT]])
	return shown


func _tier(game: Game) -> int:
	return game.module.peek_npc(game.npc_id).tier


func _state_text(game: Game) -> String:
	return JSON.stringify(game.module.serialize())


# ---------------------------------------------------------------------------------------------------- aceite

func test_the_first_conversation_promotes_the_npc_and_creates_the_relation_and_the_memory() -> void:
	var game: Game = _game()
	assert_eq([_tier(game), _values(game)], [NpcState.TIER_NORMAL, []], "Antes: cidadão e desconhecido.")
	var first: NpcModule.ConverseResult = _talk(game)
	assert_true(first.result.ok, first.result.message)
	assert_eq([first.text_key, first.was_promoted, _tier(game)], [NpcPlayerTalk.TEXT_KEY_FIRST, true, NpcState.TIER_NOTABLE], "Primeira conversa: first, e o NPC virou T2.")
	assert_eq(_values(game), [GAIN, GAIN, 0], "A relação nasceu com +3 de afeição e +3 de confiança.")
	var memories: NpcModule.MemoriesQuery = game.module.peek_memories(game.npc_id)
	assert_eq(memories.records.size(), 1)
	assert_eq([memories.records[0].kind, memories.records[0].actors], ["conversation", PackedInt64Array([ACTOR_ID])], "Uma memória `conversation` com o jogador como ator.")
	assert_eq(game.module.peek_npc(game.npc_id).action_id, "talk_player", "E o NPC parou para conversar.")
	_run(game, COOLDOWN)
	var second: NpcModule.ConverseResult = _talk(game)
	assert_true(second.result.ok, second.result.message)
	assert_eq([second.text_key, second.was_promoted, _values(game), game.module.peek_memories(game.npc_id).records.size()], [NpcPlayerTalk.TEXT_KEY_KNOWN, false, [2 * GAIN, 2 * GAIN, 0], 2], "Segunda (cooldown vencido): known, sem promover de novo, +3/+3 e mais uma memória.")
	game.world.teardown()


func test_the_gain_stops_at_the_limit_and_never_takes_away() -> void:
	var game: Game = _game()
	var deltas: PackedInt64Array = PackedInt64Array([LIMIT - 2, LIMIT - 1, 0, 0, 0])
	assert_true(game.module.request_promote(game.npc_id, NpcState.TIER_NOTABLE).ok)
	assert_true(game.module.request_adjust_relation(ACTOR_ID, game.npc_id, deltas).ok)
	assert_true(_talk(game).result.ok)
	assert_eq(_values(game), [LIMIT, LIMIT, 0], "58 sobe 2 e 59 sobe 1: o teto é 60.")
	_run(game, COOLDOWN)
	assert_true(_talk(game).result.ok)
	assert_eq(_values(game), [LIMIT, LIMIT, 0], "No teto o ganho é zero.")
	game.world.teardown()


func test_with_the_notable_cap_full_the_talk_happens_with_a_relation_but_no_promotion_or_memory() -> void:
	var game: Game = _game(NpcState.TIER_NORMAL, 40)
	var reply: NpcModule.ConverseResult = _talk(game)
	assert_true(reply.result.ok, "O teto cheio não derruba a conversa: " + reply.result.message)
	assert_eq([reply.text_key, reply.was_promoted, _tier(game)], [NpcPlayerTalk.TEXT_KEY_FIRST, false, NpcState.TIER_NORMAL])
	assert_eq([_values(game), game.module.peek_memories(game.npc_id).records.size(), game.module.peek_counts()[NpcModule.COUNT_TIER_NOTABLE]], [[GAIN, GAIN, 0], 0, 40], "Há relação, não há memória e o teto segue em 40.")
	assert_eq(game.module.peek_npc(game.npc_id).action_id, "talk_player", "O NPC parou para conversar.")
	game.world.teardown()


func test_an_npc_that_is_already_notable_records_the_memory_without_a_promotion() -> void:
	var game: Game = _game(NpcState.TIER_NOTABLE)
	var reply: NpcModule.ConverseResult = _talk(game)
	assert_true(reply.result.ok, reply.result.message)
	assert_eq([reply.was_promoted, game.module.peek_memories(game.npc_id).records.size(), _values(game)], [false, 1, [GAIN, GAIN, 0]])
	game.world.teardown()


func test_a_refused_request_leaves_no_relation_promotion_or_memory() -> void:
	var game: Game = _game()
	var before: String = _state_text(game)
	var near: Vector3 = _near(game)
	var far: Vector3 = near + Vector3(10.0, 0.0, 0.0)
	assert_eq(game.module.request_converse(ACTOR_ID, far, game.npc_id).result.code, NpcModule.CODE_TALK_TOO_FAR)
	assert_eq(game.module.request_converse(game.npc_id, near, game.npc_id).result.code, RelationGraph.CODE_NOT_ALLOWED, "O ator não pode ser um NPC.")
	assert_eq(game.module.request_converse(0, near, game.npc_id).result.code, RelationGraph.CODE_INVALID, "Ator fora da faixa de IDs.")
	assert_eq(_state_text(game), before, "Nenhuma recusa mexeu no estado (nem relação, nem tier, nem memória, nem cooldown).")
	assert_eq([_tier(game), _values(game)], [NpcState.TIER_NORMAL, []])
	game.world.teardown()


func test_a_failure_after_the_stop_keeps_the_talk_and_carries_the_code() -> void:
	var game: Game = _game(NpcState.TIER_NORMAL, 0, false)
	var reply: NpcModule.ConverseResult = _talk(game)
	assert_eq([reply.result.code, reply.text_key], [NpcModule.CODE_MEMORY_NOT_CONFIGURED, ""], "A falha da memória vai no resultado.")
	assert_eq([game.module.peek_npc(game.npc_id).action_id, _tier(game), _values(game)], ["talk_player", NpcState.TIER_NOTABLE, [GAIN, GAIN, 0]], "Mas o NPC parou, foi promovido e a relação subiu.")
	game.world.teardown()


func test_saving_and_loading_keeps_the_relation_the_memory_and_the_tier() -> void:
	var game: Game = _game()
	assert_true(_talk(game).result.ok)
	var saved: Dictionary = game.module.serialize()
	var data: NpcLifeCheck.GameData = NpcLifeCheck.load_game_data()
	var setup: NpcSetup = NpcSetup.from_dir(DATA_DIR, SettlementService.new(data.settlements, data.places), true)
	var reloaded: Game = Game.new()
	reloaded.module = NpcModule.new(setup.need_defs, setup.routine, setup.definitions)
	reloaded.world = _module_world(reloaded.module)
	reloaded.npc_id = game.npc_id
	assert_true(reloaded.module.on_load(saved).ok)
	assert_eq([_tier(reloaded), _values(reloaded), reloaded.module.peek_memories(reloaded.npc_id).records.size()], [NpcState.TIER_NOTABLE, [GAIN, GAIN, 0], 1])
	assert_eq(JSON.stringify(reloaded.module.serialize()), JSON.stringify(saved), "A ida e volta do save é exata (o cooldown inclusive).")
	reloaded.world.teardown()
	game.world.teardown()
