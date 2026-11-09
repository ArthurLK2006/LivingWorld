extends GutTest
## LW-082c: as consultas de inspeção de NPC da ponte, só de leitura (docs/modules/bridge.md, "Inspeção de NPC"; contrato na LW-082a), sem janela e com os
## dados reais do jogo (terreno, assentamentos e os 100 NPCs): `peek_npc_roster` (a lista de todos), `peek_npc_detail` (um NPC) e
## `peek_simulation_summary` (os contadores). A ponte não tem regra de jogo: confere-se que as respostas são cópias fiéis do que o `npc` diz, a ordem,
## o nível S0/S1 do LOD, os códigos de falha e que consultar não escreve nada na simulação (hash, save, relógio, RNG e IDs ficam iguais).

const DATA_DIR: String = "res://data"
const WORLD_SEED: int = 5
## Assentamento A: centro em (320, 540) m; o jogador a 30 m dele põe os NPCs de lá em S0 quando os corpos estão ligados.
const NEAR_A_M: Vector3 = Vector3(350.0, 10.0, 540.0)
const TOLERANCE_M: float = 0.001
const THINK_WARMUP_STEPS: int = 15
const PROMOTED_COUNT: int = 2

var _terrain: TerrainData
var _points: Array[PointOfInterest] = []
var _settlements: Array[Settlement] = []
var _places: Array[Place] = []
var _host: SimulationHostNode
var _bridge: SimBridge


func before_all() -> void:
	var data: NpcLifeCheck.GameData = NpcLifeCheck.load_game_data()
	assert_eq(data.problem, "", "Os dados reais do jogo carregam.")
	_terrain = data.terrain
	_points = data.points
	_settlements = data.settlements
	_places = data.places


func before_each() -> void:
	var setup: NpcSetup = NpcSetup.from_dir(DATA_DIR, SettlementService.new(_settlements, _places))
	assert_true(setup.result.ok, setup.result.message)
	_host = SimulationHostNode.new()
	_host.start_new_game(WORLD_SEED, _terrain, _points, setup)
	_bridge = SimBridge.new(_host, _terrain, _places, _host.npc)


func after_each() -> void:
	if _host.runner != null:
		_host.runner.finish()
	_host.free()


## Liga os corpos, põe um ator a 30 m do centro do assentamento A e dá um passo (o LOD reclassifica).
func _put_bodies_near_a() -> void:
	assert_true(_bridge.request_set_bodies_available(true).ok)
	var spawned: BridgeReplies.SpawnCharacterReply = _bridge.request_spawn_character()
	assert_true(spawned.result.ok, spawned.result.message)
	assert_true(_bridge.request_report_position(spawned.actor_id, NEAR_A_M, 0.0).ok)
	_host.runner.step_once()


func _step(count: int) -> void:
	for _index: int in count:
		_host.runner.step_once()


# ---------------------------------------------------------------------------------------------------- a lista

func test_the_roster_lists_every_npc_in_ascending_order_with_the_npc_summary() -> void:
	var reply: BridgeInspectReplies.NpcRosterReply = _bridge.peek_npc_roster()
	assert_true(reply.result.ok, reply.result.message)
	var ids: Array[int] = _host.npc.peek_npc_ids()
	assert_gt(ids.size(), 0, "O jogo real nasce com NPCs.")
	assert_eq(reply.entries.size(), ids.size(), "Uma linha por NPC.")
	for index: int in ids.size():
		var entry: BridgeInspectReplies.NpcRosterEntry = reply.entries[index]
		var query: NpcModule.NpcQuery = _host.npc.peek_npc(ids[index])
		assert_eq([entry.npc_id, entry.name_key, entry.name_number, entry.tier, entry.is_alive, entry.occupation_id, entry.action_id], [query.npc_id, query.name_key, query.name_number, query.tier, query.is_alive, query.occupation_id, query.action_id], "Linha %d: o resumo do `npc`." % ids[index])
		assert_eq(entry.level, BridgeInspectReplies.NpcLevel.S1, "Sem corpos ligados todos estão em S1.")


func test_the_level_follows_the_lod_and_a_dead_npc_stays_in_the_list() -> void:
	_put_bodies_near_a()
	var s0_ids: Array[int] = _host.npc.lod.s0_ids()
	assert_gt(s0_ids.size(), 0, "Com os corpos ligados e o ator perto, há NPCs em S0.")
	var in_s0: Array[int] = []
	for entry: BridgeInspectReplies.NpcRosterEntry in _bridge.peek_npc_roster().entries:
		if entry.level == BridgeInspectReplies.NpcLevel.S0:
			in_s0.append(entry.npc_id)
	assert_eq(in_s0, s0_ids, "A lista marca S0 exatamente em quem o LOD diz.")
	var dead_id: int = _host.npc.peek_npc_ids()[0]
	var saved: Dictionary = _host.npc.serialize()
	var saved_npcs: Dictionary = saved["npcs"]
	saved_npcs[str(dead_id)]["is_alive"] = false
	saved_npcs[str(dead_id)]["death_cause"] = "hunger"
	saved_npcs[str(dead_id)]["died_at"] = 1
	assert_true(_host.npc.on_load(saved).ok)
	var after: BridgeInspectReplies.NpcRosterReply = _bridge.peek_npc_roster()
	assert_eq(after.entries.size(), _host.npc.peek_npc_ids().size(), "O morto continua na lista.")
	assert_false(after.entries[0].is_alive)


# ---------------------------------------------------------------------------------------------------- o detalhe

func test_the_detail_copies_the_npc_summary_names_the_needs_and_gives_the_routine_action() -> void:
	_step(THINK_WARMUP_STEPS)
	var npc_id: int = _host.npc.peek_npc_ids()[0]
	var reply: BridgeInspectReplies.NpcDetailReply = _bridge.peek_npc_detail(npc_id)
	assert_true(reply.result.ok, reply.result.message)
	var query: NpcModule.NpcQuery = _host.npc.peek_npc(npc_id)
	assert_eq([reply.npc_id, reply.name_key, reply.name_number, reply.tier, reply.is_alive, reply.death_cause], [query.npc_id, query.name_key, query.name_number, query.tier, query.is_alive, query.death_cause])
	assert_eq([reply.settlement_id, reply.place_id, reply.occupation_id, reply.home_place_id, reply.work_place_id], [query.settlement_id, query.place_id, query.occupation_id, query.home_place_id, query.work_place_id])
	assert_eq([reply.action_id, reply.action_target_place_id, reply.action_started_at, reply.action_ends_at, reply.action_serial, reply.next_think_time], [query.action_id, query.action_target_place_id, query.action_started_at, query.action_ends_at, query.action_serial, query.next_think_time])
	assert_eq([reply.traits, reply.need_values, reply.need_urgencies, reply.needs_updated_at], [query.traits, query.need_values, query.need_urgencies, query.needs_updated_at])
	assert_eq(reply.need_ids, _host.npc.peek_need_ids(), "Os ids das necessidades vêm do `npc`, na ordem dos dados.")
	assert_eq(reply.need_ids.size(), reply.need_values.size(), "Um id para cada valor.")
	assert_almost_eq(reply.position_m.x, query.x_cm / TerrainData.CM_PER_METER, TOLERANCE_M, "A posição sai em metros (centímetros divididos por 100).")
	assert_almost_eq(reply.position_m.y, query.z_cm / TerrainData.CM_PER_METER, TOLERANCE_M)
	assert_eq(reply.level, BridgeInspectReplies.NpcLevel.S1)
	var routine: RoutineTable.RoutineQuery = _host.npc.peek_routine_action(query.occupation_id, _bridge.peek_time().hour_of_day)
	assert_true(routine.result.ok, "O ofício do NPC tem agenda nos dados reais.")
	assert_eq(reply.routine_action_id, routine.action_id, "A ação da rotina agora.")


func test_the_detail_is_a_copy_and_an_unknown_npc_is_a_handled_failure() -> void:
	var npc_id: int = _host.npc.peek_npc_ids()[0]
	var first: BridgeInspectReplies.NpcDetailReply = _bridge.peek_npc_detail(npc_id)
	first.need_values[0] = 99
	first.need_ids.append("intruder")
	first.traits[0] = 99
	var second: BridgeInspectReplies.NpcDetailReply = _bridge.peek_npc_detail(npc_id)
	assert_eq(second.need_values, _host.npc.peek_npc(npc_id).need_values, "Mexer na resposta não muda o NPC.")
	assert_eq(second.need_ids.size(), _host.npc.peek_need_ids().size())
	var unknown: BridgeInspectReplies.NpcDetailReply = _bridge.peek_npc_detail(9999999)
	assert_eq(unknown.result.code, NpcModule.CODE_UNKNOWN, "NPC inexistente: o código do `npc` passa como está.")
	assert_eq(unknown.npc_id, 0)


# ---------------------------------------------------------------------------------------------------- o resumo

func test_the_summary_counts_tiers_levels_intents_and_world_problems() -> void:
	var ids: Array[int] = _host.npc.peek_npc_ids()
	for index: int in PROMOTED_COUNT:
		assert_true(_host.npc.request_promote(ids[index], NpcState.TIER_NOTABLE).ok)
	_put_bodies_near_a()
	_step(THINK_WARMUP_STEPS)
	var reply: BridgeInspectReplies.SimSummaryReply = _bridge.peek_simulation_summary()
	assert_true(reply.result.ok, reply.result.message)
	var counts: Dictionary = _host.npc.peek_counts()
	assert_eq([reply.npc_total, reply.npc_alive, reply.npc_dead], [counts[NpcModule.COUNT_TOTAL], counts[NpcModule.COUNT_ALIVE], counts[NpcModule.COUNT_DEAD]])
	assert_eq([reply.npc_tier_normal, reply.npc_tier_notable], [reply.npc_total - PROMOTED_COUNT, PROMOTED_COUNT], "Os dois promovidos contam como notáveis.")
	var s0_count: int = _host.npc.lod.s0_ids().size()
	assert_gt(s0_count, 0)
	assert_eq([reply.npc_s0, reply.npc_s1], [s0_count, reply.npc_alive - s0_count], "S1 são os vivos que não estão em S0.")
	assert_eq(reply.pending_intents, _bridge.peek_pending_npc_intents().intents.size(), "Os Intents pendentes são os mesmos da consulta da LW-070.")
	var time: BridgeReplies.TimeSnapshot = _bridge.peek_time()
	assert_eq([reply.time.total_minutes, reply.time.hour_of_day, reply.time.is_paused], [time.total_minutes, time.hour_of_day, time.is_paused], "A hora é a do relógio da simulação.")
	assert_eq(reply.problems, _host.runner.world.validate(), "Os problemas são o `validate()` do mundo.")
	assert_eq(reply.problems.size(), 0, "O jogo real saudável não acusa problema.")


# ---------------------------------------------------------------------------------------------------- falhas e só-leitura

func test_a_bridge_without_the_npc_module_or_without_a_game_fails_with_codes() -> void:
	var without_npc: SimBridge = SimBridge.new(_host, _terrain, _places)
	assert_eq(without_npc.peek_npc_roster().result.code, SimBridge.CODE_NO_NPC)
	assert_eq(without_npc.peek_npc_detail(1).result.code, SimBridge.CODE_NO_NPC)
	assert_eq(without_npc.peek_simulation_summary().result.code, SimBridge.CODE_NO_NPC)
	var empty_host: SimulationHostNode = SimulationHostNode.new()
	var without_game: SimBridge = SimBridge.new(empty_host, null, [], NpcModule.new())
	var roster: BridgeInspectReplies.NpcRosterReply = without_game.peek_npc_roster()
	assert_true(roster.result.ok, "A lista só precisa do módulo `npc`: sem NPCs, vem vazia.")
	assert_eq(roster.entries.size(), 0)
	assert_eq(without_game.peek_npc_detail(1).result.code, SimBridge.CODE_NO_GAME, "O detalhe precisa do relógio da simulação.")
	assert_eq(without_game.peek_simulation_summary().result.code, SimBridge.CODE_NO_GAME)
	empty_host.free()


func test_the_inspection_queries_write_nothing_in_the_simulation() -> void:
	_put_bodies_near_a()
	_step(THINK_WARMUP_STEPS)
	var world: World = _host.runner.world
	var hash_before: String = world.state_hash()
	var save_before: Dictionary = _host.npc.serialize()
	var summary_before: Dictionary = world.debug_summary()
	var rng_before: Dictionary = world.context.rng.debug_summary()
	var ids_before: Dictionary = world.context.ids.debug_summary()
	for _round: int in 3:
		_bridge.peek_npc_roster()
		_bridge.peek_npc_detail(_host.npc.peek_npc_ids()[0])
		_bridge.peek_simulation_summary()
	assert_eq(world.state_hash(), hash_before, "O hash do mundo não muda.")
	assert_eq(_host.npc.serialize(), save_before, "O save do `npc` não muda.")
	assert_eq(world.debug_summary(), summary_before, "O resumo de depuração do mundo (relógio, eventos, módulos) não muda.")
	assert_eq(world.context.rng.debug_summary(), rng_before, "Nenhum sorteio é gasto.")
	assert_eq(world.context.ids.debug_summary(), ids_before, "Nenhum ID é gerado.")


func test_the_tier_constants_of_the_replies_match_the_npc_state() -> void:
	assert_eq(BridgeInspectReplies.TIER_NORMAL, NpcState.TIER_NORMAL)
	assert_eq(BridgeInspectReplies.TIER_NOTABLE, NpcState.TIER_NOTABLE)
