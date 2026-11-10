extends GutTest
## LW-082d: o resto da inspeção de NPC da ponte (docs/modules/bridge.md, "Inspeção de NPC"; contrato na LW-082a): `peek_npc_trace` (o rastro do NPC marcado),
## `peek_npc_memories`, `peek_npc_relations` e `request_set_npc_traced`, a ÚNICA escrita da inspeção (decisão de Arthur, 09/11/2026), que só existe em build
## de desenvolvimento. Sem janela e com os dados reais do jogo (terreno, assentamentos e os 100 NPCs). Confere as cópias fiéis do `npc`, os códigos de falha
## e, para a escrita, que marcar o NPC não muda o hash, o save, o RNG, os IDs gerados nem o futuro da simulação.

const DATA_DIR: String = "res://data"
const WORLD_SEED: int = 5
const WARMUP_STEPS: int = 60
const LONG_RUN_STEPS: int = 200
const TWIN_STEPS: int = 120
const SOCIAL_PLACE: String = "a_social_01"
const MEMORY_KIND: String = "conversation"
const MEMORY_VALENCE: int = 20
const MEMORY_SALIENCE: int = 30

var _terrain: TerrainData
var _points: Array[PointOfInterest] = []
var _settlements: Array[Settlement] = []
var _places: Array[Place] = []
var _hosts: Array[SimulationHostNode] = []
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
	_host = _new_game(true)
	_bridge = _bridge_of(_host)


func after_each() -> void:
	for host: SimulationHostNode in _hosts:
		if host.runner != null:
			host.runner.finish()
		host.free()
	_hosts.clear()


## Um jogo igual ao real. `is_development_build` falso: o `npc` recusa os comandos de depuração.
func _new_game(is_development_build: bool) -> SimulationHostNode:
	var setup: NpcSetup = NpcSetup.from_dir(DATA_DIR, SettlementService.new(_settlements, _places), is_development_build)
	assert_true(setup.result.ok, setup.result.message)
	var host: SimulationHostNode = SimulationHostNode.new()
	host.start_new_game(WORLD_SEED, _terrain, _points, setup)
	_hosts.append(host)
	return host


func _bridge_of(host: SimulationHostNode) -> SimBridge:
	return SimBridge.new(host, _terrain, _places, host.npc)


func _step(host: SimulationHostNode, count: int) -> void:
	for _index: int in count:
		host.runner.step_once()


## Tudo que a escrita da marca NÃO pode mudar: o hash do mundo, o save do `npc`, o estado do RNG e os IDs gerados.
func _fingerprint(host: SimulationHostNode) -> Array:
	var world: World = host.runner.world
	return [world.state_hash(), host.npc.serialize(), world.context.rng.debug_summary(), world.context.ids.debug_summary()]


# ---------------------------------------------------------------------------------------------------- o rastro e a marcação

func test_an_unmarked_npc_has_no_trace_and_marking_it_through_the_bridge_fills_it_with_copies() -> void:
	var npc_id: int = _host.npc.peek_npc_ids()[0]
	var unmarked: BridgeInspectReplies.NpcTraceReply = _bridge.peek_npc_trace(npc_id)
	assert_eq(unmarked.result.code, DecisionTracer.CODE_NOT_TRACED, "NPC sem marca: o código do `npc` passa como está.")
	assert_eq(unmarked.records.size(), 0)
	assert_true(_bridge.request_set_npc_traced(npc_id, true).ok)
	_step(_host, WARMUP_STEPS)
	var reply: BridgeInspectReplies.NpcTraceReply = _bridge.peek_npc_trace(npc_id)
	assert_true(reply.result.ok, reply.result.message)
	var source: DecisionTracer.Explanation = _host.npc.explain_decision(npc_id)
	assert_gt(reply.records.size(), 0, "Depois de pensar, o NPC marcado tem rastro.")
	assert_eq(reply.records.size(), source.records.size())
	for index: int in reply.records.size():
		var record: BridgeInspectReplies.NpcTraceRecord = reply.records[index]
		var original: DecisionTracer.DecisionRecord = source.records[index]
		assert_eq([record.minute, record.need_values, record.chosen_action_id, record.chosen_place_id, record.reason, record.candidates.size()], [original.minute, original.need_values, original.chosen_action_id, original.chosen_place_id, original.reason, original.candidates.size()], "Pensamento %d: cópia do rastro do `npc`." % index)
		for position: int in record.candidates.size():
			var candidate: BridgeInspectReplies.NpcTraceCandidate = record.candidates[position]
			var found: DecisionTracer.CandidateRecord = original.candidates[position]
			assert_eq([candidate.action_id, candidate.place_id, candidate.benefit, candidate.personality, candidate.time_cost, candidate.distance_cost], [found.action_id, found.place_id, found.benefit, found.personality, found.time_cost, found.distance_cost])
			assert_eq([candidate.risk_cost, candidate.inertia_bonus, candidate.routine_bonus, candidate.total, candidate.is_current, candidate.source], [found.risk_cost, found.inertia_bonus, found.routine_bonus, found.total, found.is_current, found.source])
		if index > 0:
			assert_gt(record.minute, reply.records[index - 1].minute, "Do mais antigo ao mais novo.")
	_step(_host, LONG_RUN_STEPS)
	assert_lte(_bridge.peek_npc_trace(npc_id).records.size(), DecisionTracer.TRACE_DEPTH, "O rastro guarda só os últimos pensamentos.")
	reply.records.clear()
	assert_gt(_bridge.peek_npc_trace(npc_id).records.size(), 0, "Mexer na resposta não muda o rastro guardado.")
	assert_true(_bridge.request_set_npc_traced(npc_id, false).ok)
	assert_eq(_bridge.peek_npc_trace(npc_id).result.code, DecisionTracer.CODE_NOT_TRACED, "Desmarcar apaga o rastro.")


func test_the_marking_only_exists_in_a_development_build() -> void:
	var release_host: SimulationHostNode = _new_game(false)
	var release_bridge: SimBridge = _bridge_of(release_host)
	var npc_id: int = release_host.npc.peek_npc_ids()[0]
	var before: Array = _fingerprint(release_host)
	assert_eq(release_bridge.request_set_npc_traced(npc_id, true).code, NpcModule.CODE_DEV_ONLY, "Fora de build de desenvolvimento a escrita é recusada.")
	assert_eq(release_bridge.peek_npc_trace(npc_id).result.code, DecisionTracer.CODE_NOT_TRACED, "E nada ficou marcado.")
	assert_eq(_fingerprint(release_host), before, "Recusada, nada muda.")


func test_marking_changes_neither_hash_nor_save_nor_rng_nor_ids_nor_the_future() -> void:
	var plain: SimulationHostNode = _new_game(true)
	var marked: SimulationHostNode = _new_game(true)
	var marked_bridge: SimBridge = _bridge_of(marked)
	var npc_id: int = marked.npc.peek_npc_ids()[0]
	_step(plain, WARMUP_STEPS)
	_step(marked, WARMUP_STEPS)
	var before: Array = _fingerprint(marked)
	assert_true(marked_bridge.request_set_npc_traced(npc_id, true).ok)
	assert_eq(_fingerprint(marked), before, "Escrita isolada: marcar não muda hash, save, RNG nem IDs.")
	assert_true(marked_bridge.request_set_npc_traced(npc_id, false).ok)
	assert_eq(_fingerprint(marked), before, "Nem desmarcar.")
	assert_true(marked_bridge.request_set_npc_traced(npc_id, true).ok)
	_step(plain, TWIN_STEPS)
	_step(marked, TWIN_STEPS)
	assert_gt(marked_bridge.peek_npc_trace(npc_id).records.size(), 0, "O gêmeo marcado guardou rastro.")
	assert_eq(_fingerprint(marked), _fingerprint(plain), "Depois de rodar, o mundo marcado é idêntico ao que nunca foi marcado.")


# ---------------------------------------------------------------------------------------------------- memórias e relações

func test_the_memories_and_traits_are_copies_of_the_npc_and_a_citizen_has_no_records() -> void:
	var ids: Array[int] = _host.npc.peek_npc_ids()
	var notable: int = ids[0]
	var citizen: int = ids[1]
	assert_true(_host.npc.request_promote(notable, NpcState.TIER_NOTABLE).ok)
	assert_true(_host.npc.request_record_memory(notable, MEMORY_KIND, [citizen] as Array[int], SOCIAL_PLACE).ok)
	var reply: BridgeInspectReplies.NpcMemoriesReply = _bridge.peek_npc_memories(notable)
	assert_true(reply.result.ok, reply.result.message)
	var source: NpcModule.MemoriesQuery = _host.npc.peek_memories(notable)
	assert_eq([reply.records.size(), reply.traits.size()], [1, source.traits.size()])
	var record: BridgeInspectReplies.NpcMemoryEntry = reply.records[0]
	assert_eq([record.kind, record.place_id, record.time, record.valence, record.salience, record.source, record.confidence], [MEMORY_KIND, SOCIAL_PLACE, source.records[0].time, MEMORY_VALENCE, MEMORY_SALIENCE, source.records[0].source, source.records[0].confidence])
	assert_eq(Array(record.actors), [citizen], "A pessoa do episódio.")
	record.valence = 99
	reply.records.clear()
	assert_eq(_bridge.peek_npc_memories(notable).records[0].valence, MEMORY_VALENCE, "Mexer na resposta não muda a memória.")
	var citizen_reply: BridgeInspectReplies.NpcMemoriesReply = _bridge.peek_npc_memories(citizen)
	assert_true(citizen_reply.result.ok)
	assert_eq(citizen_reply.records.size(), 0, "Cidadão (T1) não tem registros.")


func test_the_relations_are_copies_of_the_npc_in_ascending_order_of_the_other_person() -> void:
	var ids: Array[int] = _host.npc.peek_npc_ids()
	var notable: int = ids[0]
	var spawned: BridgeReplies.SpawnCharacterReply = _bridge.request_spawn_character()
	assert_true(spawned.result.ok, spawned.result.message)
	assert_true(_host.npc.request_promote(notable, NpcState.TIER_NOTABLE).ok)
	assert_true(_host.npc.request_adjust_relation(notable, spawned.actor_id, PackedInt64Array([40, 5, 0, 0, 0])).ok)
	assert_true(_host.npc.request_adjust_relation(notable, ids[2], PackedInt64Array([-60, 0, 0, 10, 0])).ok)
	var reply: BridgeInspectReplies.NpcRelationsReply = _bridge.peek_npc_relations(notable)
	assert_true(reply.result.ok, reply.result.message)
	var source: NpcRelationsQuery = _host.npc.peek_relations(notable)
	assert_eq(reply.entries.size(), 2)
	assert_eq(reply.entries.size(), source.entries.size())
	for index: int in reply.entries.size():
		var entry: BridgeInspectReplies.NpcRelationEntry = reply.entries[index]
		var original: NpcRelationsQuery.Entry = source.entries[index]
		assert_eq([entry.other_id, entry.values, entry.label, entry.met_at, entry.other_is_alive], [original.other_id, original.values, original.label, original.met_at, original.other_is_alive])
		if index > 0:
			assert_gt(entry.other_id, reply.entries[index - 1].other_id, "Ordem crescente do id da outra pessoa.")
	reply.entries[0].values[0] = 99
	assert_ne(_bridge.peek_npc_relations(notable).entries[0].values[0], 99, "Mexer na resposta não muda a relação.")


# ---------------------------------------------------------------------------------------------------- falhas

func test_unknown_npc_and_a_bridge_without_the_npc_module_fail_with_codes() -> void:
	assert_eq(_bridge.peek_npc_trace(9999999).result.code, NpcModule.CODE_UNKNOWN)
	assert_eq(_bridge.peek_npc_memories(9999999).result.code, NpcModule.CODE_UNKNOWN)
	assert_eq(_bridge.peek_npc_relations(9999999).result.code, NpcModule.CODE_UNKNOWN)
	assert_eq(_bridge.request_set_npc_traced(9999999, true).code, NpcModule.CODE_UNKNOWN, "A escrita em NPC inexistente é falha tratada.")
	var without_npc: SimBridge = SimBridge.new(_host, _terrain, _places)
	assert_eq(without_npc.peek_npc_trace(1).result.code, SimBridge.CODE_NO_NPC)
	assert_eq(without_npc.peek_npc_memories(1).result.code, SimBridge.CODE_NO_NPC)
	assert_eq(without_npc.peek_npc_relations(1).result.code, SimBridge.CODE_NO_NPC)
	assert_eq(without_npc.request_set_npc_traced(1, true).code, SimBridge.CODE_NO_NPC)
