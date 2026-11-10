extends GutTest
## LW-082e: o modelo do painel de depuração de NPC (src/tools/npc_inspector/npc_inspector_model.gd; contrato em docs/modules/tools.md), sem janela e SEM
## ponte: recebe respostas falsas (`BridgeInspectReplies`) e devolve linhas com chave e valores. Confere a seleção (próximo e anterior com volta ao início,
## NPC que some ou morre), o recorte de 10 memórias (as mais recentes) e de 10 relações (as mais fortes), as linhas de cada seção e as chaves.


func _entry(npc_id: int, is_alive: bool = true) -> BridgeInspectReplies.NpcRosterEntry:
	var entry: BridgeInspectReplies.NpcRosterEntry = BridgeInspectReplies.NpcRosterEntry.new()
	entry.npc_id = npc_id
	entry.is_alive = is_alive
	return entry


func _roster(ids: Array[int], dead: Array[int] = []) -> BridgeInspectReplies.NpcRosterReply:
	var entries: Array[BridgeInspectReplies.NpcRosterEntry] = []
	for npc_id: int in ids:
		entries.append(_entry(npc_id, not dead.has(npc_id)))
	return BridgeInspectReplies.NpcRosterReply.new(Result.success(), entries)


func _model(ids: Array[int]) -> NpcInspectorModel:
	var model: NpcInspectorModel = NpcInspectorModel.new()
	model.apply_roster(_roster(ids))
	return model


func _detail(npc_id: int) -> BridgeInspectReplies.NpcDetailReply:
	var detail: BridgeInspectReplies.NpcDetailReply = BridgeInspectReplies.NpcDetailReply.new(Result.success())
	detail.npc_id = npc_id
	detail.is_alive = true
	detail.tier = BridgeInspectReplies.TIER_NOTABLE
	detail.level = BridgeInspectReplies.NpcLevel.S0
	detail.need_ids = ["hunger", "rest"]
	detail.need_values = PackedInt64Array([30, 70])
	detail.need_urgencies = PackedInt64Array([0, 2])
	detail.action_id = "eat"
	detail.action_target_place_id = "a_home_01"
	detail.action_started_at = 600
	detail.action_ends_at = 620
	detail.occupation_id = "guard"
	detail.home_place_id = "a_home_01"
	return detail


func _memory(time: int, kind: String = "conversation") -> BridgeInspectReplies.NpcMemoryEntry:
	var memory: BridgeInspectReplies.NpcMemoryEntry = BridgeInspectReplies.NpcMemoryEntry.new()
	memory.kind = kind
	memory.time = time
	memory.actors = PackedInt64Array([7])
	return memory


func _relation(other_id: int, affection: int, fear: int = 0) -> BridgeInspectReplies.NpcRelationEntry:
	var relation: BridgeInspectReplies.NpcRelationEntry = BridgeInspectReplies.NpcRelationEntry.new()
	relation.other_id = other_id
	relation.values = PackedInt64Array([affection, 0, 0, fear, 0])
	relation.label = "acquaintance"
	return relation


func _keys(lines: Array[NpcInspectorModel.Line]) -> Array[String]:
	var keys: Array[String] = []
	for line: NpcInspectorModel.Line in lines:
		keys.append(line.key)
	return keys


# ---------------------------------------------------------------------------------------------------- seleção

func test_next_and_previous_walk_the_whole_list_and_wrap_around() -> void:
	var empty: NpcInspectorModel = NpcInspectorModel.new()
	empty.select_next()
	empty.select_previous()
	assert_eq(empty.selected_id(), NpcInspectorModel.NO_NPC, "Lista vazia: nada acontece.")
	var model: NpcInspectorModel = _model([3, 5, 9])
	var forward: Array[int] = []
	for _step: int in 4:
		model.select_next()
		forward.append(model.selected_id())
	assert_eq(forward, [3, 5, 9, 3] as Array[int], "Sem seleção vai ao primeiro e, no fim, volta ao início.")
	model.select_previous()
	assert_eq(model.selected_id(), 9, "Antes do primeiro, volta ao fim.")
	var fresh: NpcInspectorModel = _model([3, 5, 9])
	fresh.select_previous()
	assert_eq(fresh.selected_id(), 9, "Sem seleção, o anterior é o último.")
	assert_true(fresh.select(5))
	assert_false(fresh.select(4), "Id fora da lista é recusado.")
	assert_eq(fresh.selected_id(), 5, "E nada muda.")


func test_a_vanished_npc_hands_the_selection_to_the_next_id_and_a_dead_one_stays_selected() -> void:
	var model: NpcInspectorModel = _model([3, 5, 9])
	model.select(5)
	model.apply_roster(_roster([3, 9]))
	assert_eq(model.selected_id(), 9, "O 5 sumiu: a seleção vai ao próximo id.")
	model.apply_roster(_roster([3, 5]))
	assert_eq(model.selected_id(), 3, "O 9 sumiu e era o último: volta ao primeiro.")
	model.apply_roster(_roster([] as Array[int]))
	assert_eq(model.selected_id(), NpcInspectorModel.NO_NPC, "Lista vazia: sem seleção.")
	var dying: NpcInspectorModel = _model([3, 5, 9])
	dying.select(5)
	dying.apply_roster(_roster([3, 5, 9], [5] as Array[int]))
	assert_eq(dying.selected_id(), 5, "Quem morre continua selecionado.")
	assert_false(dying.selected_entry().is_alive, "E aparece como morto.")


func test_the_data_of_the_old_selection_is_dropped_and_failed_or_late_replies_are_ignored() -> void:
	var model: NpcInspectorModel = _model([3, 5, 9])
	model.select(5)
	model.apply_detail(_detail(9))
	assert_eq(model.detail_lines().size(), 0, "O detalhe de outro NPC, que chegou tarde, é ignorado.")
	model.apply_detail(_detail(5))
	assert_gt(model.detail_lines().size(), 0)
	model.select(9)
	assert_eq(model.detail_lines().size(), 0, "Trocar de NPC apaga o que era do anterior.")
	model.apply_roster(BridgeInspectReplies.NpcRosterReply.new(Result.failure("X", "falhou")))
	assert_eq(model.roster().size(), 3, "Resposta que falhou: fica o que já havia.")


# ---------------------------------------------------------------------------------------------------- o que mostrar

func test_the_summary_lines_carry_the_counters_and_cap_the_problems() -> void:
	var model: NpcInspectorModel = NpcInspectorModel.new()
	var reply: BridgeInspectReplies.SimSummaryReply = BridgeInspectReplies.SimSummaryReply.new(Result.success())
	reply.time = BridgeReplies.TimeSnapshot.new(Result.success(), null)
	reply.npc_alive = 98
	reply.npc_s0 = 12
	reply.npc_s1 = 86
	reply.pending_intents = 12
	reply.problems.assign(["um", "dois", "três", "quatro", "cinco"])
	model.apply_summary(reply)
	var lines: Array[NpcInspectorModel.Line] = model.summary_lines()
	assert_eq(_keys(lines).slice(0, 6), [NpcInspectorModel.KEY_SUMMARY_TIME, NpcInspectorModel.KEY_SUMMARY_NPCS, NpcInspectorModel.KEY_SUMMARY_TIERS, NpcInspectorModel.KEY_SUMMARY_LEVELS, NpcInspectorModel.KEY_SUMMARY_INTENTS, NpcInspectorModel.KEY_SUMMARY_PROBLEMS] as Array[String])
	assert_eq([lines[1].values["alive"], lines[3].values["s0"], lines[4].values["count"], lines[5].values["count"]], [98, 12, 12, 5])
	assert_eq(lines.size(), 6 + 5, "Um problema por linha, e a contagem é de todos.")


func test_the_detail_lines_name_the_needs_the_action_and_the_occupation_with_raw_ids() -> void:
	var model: NpcInspectorModel = _model([5])
	model.select(5)
	model.apply_detail(_detail(5))
	var lines: Array[NpcInspectorModel.Line] = model.detail_lines()
	assert_eq(_keys(lines), [NpcInspectorModel.KEY_DETAIL_ALIVE, NpcInspectorModel.KEY_NEED_LINE, NpcInspectorModel.KEY_NEED_LINE, NpcInspectorModel.KEY_ACTION_LINE, NpcInspectorModel.KEY_OCCUPATION_LINE] as Array[String])
	assert_eq([lines[0].values["level"], lines[0].values["tier"]], ["S0", "T2"])
	assert_eq([lines[2].values["id"], lines[2].values["value"], lines[2].values["urgency"]], ["rest", 70, 2], "Cada necessidade com o id cru, o valor e a urgência.")
	assert_eq([lines[3].values["action"], lines[3].values["place"], lines[3].values["started"], lines[3].values["ends"]], ["eat", "a_home_01", 600, 620])
	assert_eq([lines[4].values["occupation"], lines[4].values["work"], lines[4].values["routine"]], ["guard", NpcInspectorModel.EMPTY_MARK, NpcInspectorModel.EMPTY_MARK], "O que não está escrito vira um traço.")
	var detail: BridgeInspectReplies.NpcDetailReply = _detail(5)
	detail.is_alive = false
	detail.death_cause = "hunger"
	detail.action_id = ""
	model.apply_detail(detail)
	assert_eq(_keys(model.detail_lines()).slice(0, 1), [NpcInspectorModel.KEY_DETAIL_DEAD] as Array[String], "Morto: a linha de estado traz a causa.")
	assert_true(_keys(model.detail_lines()).has(NpcInspectorModel.KEY_ACTION_IDLE), "Sem ação: linha de parado.")


func test_the_trace_shows_the_newest_thought_first_and_says_when_there_is_no_mark() -> void:
	var model: NpcInspectorModel = _model([5])
	model.select(5)
	model.apply_trace(BridgeInspectReplies.NpcTraceReply.new(Result.failure(NpcInspectorModel.CODE_NOT_TRACED, "sem marca")))
	assert_eq(_keys(model.trace_lines()), [NpcInspectorModel.KEY_TRACE_NOT_MARKED] as Array[String])
	assert_false(model.is_traced())
	var old_thought: BridgeInspectReplies.NpcTraceRecord = BridgeInspectReplies.NpcTraceRecord.new()
	old_thought.minute = 600
	old_thought.chosen_action_id = "sleep"
	old_thought.reason = "ROUTINE"
	var new_thought: BridgeInspectReplies.NpcTraceRecord = BridgeInspectReplies.NpcTraceRecord.new()
	new_thought.minute = 610
	new_thought.chosen_action_id = "eat"
	var candidate: BridgeInspectReplies.NpcTraceCandidate = BridgeInspectReplies.NpcTraceCandidate.new()
	candidate.action_id = "eat"
	candidate.total = 42
	candidate.is_current = true
	new_thought.candidates.append(candidate)
	var records: Array[BridgeInspectReplies.NpcTraceRecord] = [old_thought, new_thought]
	model.apply_trace(BridgeInspectReplies.NpcTraceReply.new(Result.success(), records))
	assert_true(model.is_traced())
	var lines: Array[NpcInspectorModel.Line] = model.trace_lines()
	assert_eq(_keys(lines), [NpcInspectorModel.KEY_TRACE_THOUGHT, NpcInspectorModel.KEY_TRACE_CANDIDATE, NpcInspectorModel.KEY_TRACE_THOUGHT] as Array[String], "O mais novo primeiro, com as candidatas dele.")
	assert_eq([lines[0].values["minute"], lines[1].values["total"], lines[1].values["current"], lines[2].values["reason"]], [610, 42, "*", "ROUTINE"])
	model.apply_trace(BridgeInspectReplies.NpcTraceReply.new(Result.success()))
	assert_eq(_keys(model.trace_lines()), [NpcInspectorModel.KEY_TRACE_EMPTY] as Array[String], "Marcado, mas sem pensamento ainda.")


func test_only_the_ten_most_recent_memories_are_shown_and_the_traits_follow() -> void:
	var model: NpcInspectorModel = _model([5])
	model.select(5)
	var reply: BridgeInspectReplies.NpcMemoriesReply = BridgeInspectReplies.NpcMemoriesReply.new(Result.success())
	model.apply_memories(reply)
	assert_eq(_keys(model.memory_lines()), [NpcInspectorModel.KEY_MEMORY_NONE] as Array[String], "Sem registro nem traço: linha de vazio.")
	for time: int in [100, 500, 300, 900, 200, 800, 400, 700, 600, 1000, 150, 1100]:
		reply.records.append(_memory(time))
	reply.records.append(_memory(1100, "help_received"))
	var memory_trait: BridgeInspectReplies.NpcTraitEntry = BridgeInspectReplies.NpcTraitEntry.new()
	memory_trait.actor_id = 7
	reply.traits.append(memory_trait)
	model.apply_memories(reply)
	var lines: Array[NpcInspectorModel.Line] = model.memory_lines()
	assert_eq(lines.size(), NpcInspectorModel.MAX_MEMORIES_SHOWN + 1, "Dez memórias e o traço.")
	assert_eq([lines[0].values["kind"], lines[0].values["time"], lines[1].values["kind"], lines[1].values["time"]], ["help_received", 1100, "conversation", 1100], "Empate no minuto: a que entrou depois vem primeiro.")
	assert_eq(lines[9].values["time"], 300, "A décima é a de 300: 100, 150 e 200 ficaram de fora.")
	assert_eq([lines[0].values["actors"], lines[10].key], ["7", NpcInspectorModel.KEY_TRAIT_LINE])


func test_only_the_ten_strongest_relations_are_shown_strongest_first_with_ties_by_lowest_id() -> void:
	var model: NpcInspectorModel = _model([5])
	model.select(5)
	var reply: BridgeInspectReplies.NpcRelationsReply = BridgeInspectReplies.NpcRelationsReply.new(Result.success())
	model.apply_relations(reply)
	assert_eq(_keys(model.relation_lines()), [NpcInspectorModel.KEY_RELATION_NONE] as Array[String])
	for index: int in 12:
		reply.entries.append(_relation(100 + index, 10 + index))
	reply.entries.append(_relation(50, -30, 0))
	reply.entries.append(_relation(40, 5, 25))
	model.apply_relations(reply)
	var lines: Array[NpcInspectorModel.Line] = model.relation_lines()
	assert_eq(lines.size(), NpcInspectorModel.MAX_RELATIONS_SHOWN)
	var others: Array[int] = []
	for line: NpcInspectorModel.Line in lines:
		others.append(line.values["other"])
	assert_eq(others, [40, 50, 111, 110, 109, 108, 107, 106, 105, 104] as Array[int], "As mais fortes primeiro (soma dos módulos): 40 e 50 valem 30 (empate: o menor id), depois 111 (21) e assim por diante; 103 a 100 ficaram de fora.")
	reply.entries.clear()
	reply.entries.append(_relation(9, 20))
	reply.entries.append(_relation(4, 15, 5))
	model.apply_relations(reply)
	var tied: Array[NpcInspectorModel.Line] = model.relation_lines()
	assert_eq([tied[0].values["other"], tied[1].values["other"]], [4, 9], "Empate na força (20 e 20): o menor id da outra pessoa primeiro.")


# ---------------------------------------------------------------------------------------------------- chaves

func test_every_text_key_has_the_panel_prefix_and_is_unique_and_the_not_traced_code_matches() -> void:
	var constants: Dictionary = NpcInspectorModel.new().get_script().get_script_constant_map()
	var keys: Array[String] = []
	for constant_name: String in constants:
		if constant_name.begins_with("KEY_") and constant_name != "KEY_PREFIX":
			keys.append(str(constants[constant_name]))
	assert_gt(keys.size(), 0, "O teste enxerga as chaves.")
	for key: String in keys:
		assert_true(key.begins_with(NpcInspectorModel.KEY_PREFIX), "A chave %s tem o prefixo do painel." % key)
		assert_eq(keys.count(key), 1, "A chave %s não se repete." % key)
	assert_eq(NpcInspectorModel.CODE_NOT_TRACED, DecisionTracer.CODE_NOT_TRACED, "O código copiado é o do `npc`.")
