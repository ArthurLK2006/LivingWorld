class_name BridgeNpcInspect
extends RefCounted
## A conta das consultas de inspeção de NPC da ponte (LW-082c; contrato em docs/modules/bridge.md, "Inspeção de NPC"). O `SimBridge` só delega para cá,
## porque ele já passa de 300 linhas. Sem estado e sem regra de jogo: cada função só LÊ o módulo `npc` (ou os valores que a ponte entrega) e devolve
## CÓPIAS. Quem confere a ponte sem `npc` ou sem jogo é o `SimBridge`, antes de chamar.


## A lista de todos os NPCs, em ordem crescente de id, inclusive os mortos e os sem corpo.
static func roster(npc: NpcModule) -> BridgeInspectReplies.NpcRosterReply:
	var entries: Array[BridgeInspectReplies.NpcRosterEntry] = []
	for npc_id: int in npc.peek_npc_ids():
		var query: NpcModule.NpcQuery = npc.peek_npc(npc_id)
		if not query.result.ok:
			return BridgeInspectReplies.NpcRosterReply.new(query.result)
		var entry: BridgeInspectReplies.NpcRosterEntry = BridgeInspectReplies.NpcRosterEntry.new()
		entry.npc_id = query.npc_id
		entry.name_key = query.name_key
		entry.name_number = query.name_number
		entry.tier = query.tier
		entry.is_alive = query.is_alive
		entry.level = _level_of(npc, npc_id)
		entry.occupation_id = query.occupation_id
		entry.action_id = query.action_id
		entries.append(entry)
	return BridgeInspectReplies.NpcRosterReply.new(Result.success(), entries)


## O detalhe de um NPC. `hour_of_day` (0 a 23, do relógio da simulação) serve só para achar a ação que a rotina do ofício manda agora.
static func detail(npc: NpcModule, npc_id: int, hour_of_day: int) -> BridgeInspectReplies.NpcDetailReply:
	var query: NpcModule.NpcQuery = npc.peek_npc(npc_id)
	var reply: BridgeInspectReplies.NpcDetailReply = BridgeInspectReplies.NpcDetailReply.new(query.result)
	if not query.result.ok:
		return reply
	reply.npc_id = query.npc_id
	reply.name_key = query.name_key
	reply.name_number = query.name_number
	reply.tier = query.tier
	reply.is_alive = query.is_alive
	reply.death_cause = query.death_cause
	reply.level = _level_of(npc, npc_id)
	reply.traits = query.traits.duplicate()
	reply.need_ids = npc.peek_need_ids()
	reply.need_values = query.need_values.duplicate()
	reply.need_urgencies = query.need_urgencies.duplicate()
	reply.needs_updated_at = query.needs_updated_at
	reply.position_m = Vector2(query.x_cm, query.z_cm) / TerrainData.CM_PER_METER
	reply.settlement_id = query.settlement_id
	reply.place_id = query.place_id
	reply.occupation_id = query.occupation_id
	reply.home_place_id = query.home_place_id
	reply.work_place_id = query.work_place_id
	reply.action_id = query.action_id
	reply.action_target_place_id = query.action_target_place_id
	reply.action_started_at = query.action_started_at
	reply.action_ends_at = query.action_ends_at
	reply.action_serial = query.action_serial
	reply.next_think_time = query.next_think_time
	if not query.occupation_id.is_empty():
		var routine: RoutineTable.RoutineQuery = npc.peek_routine_action(query.occupation_id, hour_of_day)
		if routine.result.ok:
			reply.routine_action_id = routine.action_id
	return reply


## Os contadores globais. `time` é a cópia do relógio que a ponte já fez e `world_problems` é o `validate()` do mundo inteiro (a ponte o chama).
static func summary(npc: NpcModule, time: BridgeReplies.TimeSnapshot, world_problems: Array[String]) -> BridgeInspectReplies.SimSummaryReply:
	var reply: BridgeInspectReplies.SimSummaryReply = BridgeInspectReplies.SimSummaryReply.new(Result.success())
	var counts: Dictionary = npc.peek_counts()
	reply.time = time
	reply.npc_total = counts[NpcModule.COUNT_TOTAL]
	reply.npc_alive = counts[NpcModule.COUNT_ALIVE]
	reply.npc_dead = counts[NpcModule.COUNT_DEAD]
	reply.npc_tier_normal = counts[NpcModule.COUNT_TIER_NORMAL]
	reply.npc_tier_notable = counts[NpcModule.COUNT_TIER_NOTABLE]
	reply.npc_s0 = npc.lod.s0_ids().size()
	reply.npc_s1 = maxi(0, reply.npc_alive - reply.npc_s0)
	reply.pending_intents = npc.peek_pending_intents().size()
	reply.problems.assign(world_problems)
	return reply


static func _level_of(npc: NpcModule, npc_id: int) -> BridgeInspectReplies.NpcLevel:
	if npc.lod.level_of(npc_id) == NpcLod.LEVEL_S0:
		return BridgeInspectReplies.NpcLevel.S0
	return BridgeInspectReplies.NpcLevel.S1
