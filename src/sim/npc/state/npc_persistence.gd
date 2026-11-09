class_name NpcPersistence
extends RefCounted
## O estado do `npc` para fora: salvar (`serialize`), carregar (`on_load`), conferir (`validate`) e resumir (`debug_summary`), com o estoque de comida salvo junto
## (TEMP-LW-065). LW-081a (passo 3): o código saiu do `NpcModule` sem mudar de comportamento; o módulo segue sendo a única porta e só delega aqui. A tabela de
## NPCs é a do módulo (a mesma, por referência; `on_load` a atualiza no lugar). As chaves e os códigos do save continuam sendo as constantes do `NpcModule`.

var _npcs: Dictionary[int, NpcState]
var _notables: NpcNotables
var _bodies: NpcBodies
var _tracer: DecisionTracer
var _routine: RoutineTable
var _definitions: NpcModule.Definitions
## Motivo de as definições de necessidades não servirem (vazio = servem), conferido uma vez pelo módulo.
var _defs_problem: String
var _ctx: SimContext


func _init(npcs: Dictionary[int, NpcState], notables: NpcNotables, bodies: NpcBodies, tracer: DecisionTracer, routine: RoutineTable, definitions: NpcModule.Definitions, defs_problem: String) -> void:
	_npcs = npcs
	_notables = notables
	_bodies = bodies
	_tracer = tracer
	_routine = routine
	_definitions = definitions
	_defs_problem = defs_problem


func setup(ctx: SimContext) -> void:
	_ctx = ctx


## IDs viram texto (assim o JSON guarda chaves) e entram em ordem crescente do número.
func serialize() -> Dictionary:
	var saved: Dictionary = {}
	for npc_id: int in _sorted_ids():
		saved[str(npc_id)] = _npcs[npc_id].to_dict()
	var data: Dictionary = {NpcModule.KEY_NPCS: saved}
	var food_stub: FoodStub = _food_stub()
	if food_stub != null:
		data[FoodStub.SAVE_KEY] = food_stub.serialize()
	var saved_memories: Dictionary = _notables.memories_to_dict()
	if not saved_memories.is_empty():
		data[NpcModule.KEY_MEMORIES] = saved_memories
	if _notables.has_relations():
		data[NpcModule.KEY_RELATIONS] = _notables.relations_to_array()
	return data


## Confere tudo antes de alterar o estado: se algo for inválido, o estado fica como estava. Só recusa o que não dá para converter
## (estrutura, tipos, chave de ID); faixas e coerência ficam com validate() (mesmo critério do `character`).
func on_load(data: Dictionary) -> Result:
	# Variant: valor cru do save (JSON); o tipo é conferido na linha seguinte.
	var raw_npcs: Variant = data.get(NpcModule.KEY_NPCS)
	if typeof(raw_npcs) != TYPE_DICTIONARY:
		return _invalid_save("campo '%s' ausente ou não é um objeto (veio %s)" % [NpcModule.KEY_NPCS, type_string(typeof(raw_npcs))])
	var entries: Dictionary = raw_npcs
	var keys: Array = entries.keys()
	keys.sort()
	var loaded: Dictionary[int, NpcState] = {}
	for key: Variant in keys:
		var npc_id: int = _read_npc_id(str(key))
		if npc_id == IdGenerator.NO_ID:
			return _invalid_save("chave de NPC '%s' inválida; esperado um inteiro de %d a %d" % [str(key), IdGenerator.FIRST_ID, IdGenerator.MAX_ID])
		if loaded.has(npc_id):
			return _invalid_save("o NPC %d aparece duas vezes (chave '%s')" % [npc_id, str(key)])
		var parsed: NpcState.ParseResult = NpcState.parse(npc_id, entries[key])
		if parsed.state == null:
			return _invalid_save("NPC %d: %s" % [npc_id, parsed.error])
		loaded[npc_id] = parsed.state
	var stock_problem: String = _food_stock_save_problem(data)
	if not stock_problem.is_empty():
		return _invalid_save(stock_problem)
	var loaded_notables: NpcNotables.ParsedSave = _notables.parse_save(data.get(NpcModule.KEY_MEMORIES, {}), data.get(NpcModule.KEY_RELATIONS, []))
	if not loaded_notables.error.is_empty():
		return _invalid_save(loaded_notables.error)
	_npcs.clear()
	for loaded_id: int in loaded:
		_npcs[loaded_id] = loaded[loaded_id]
	_notables.replace_with(loaded_notables)
	_load_food_stock(data)
	_tracer.clear()
	return Result.success()


## Problemas do estado (lista vazia se estiver tudo certo). O ofício é conferido contra a tabela de rotina quando o módulo a tem (LW-061);
## local e ação ficam como texto: cada tarefa futura acrescenta a sua conferência.
func validate() -> Array[String]:
	var problems: Array[String] = []
	if not _defs_problem.is_empty():
		problems.append("Definições de necessidades inválidas: %s." % _defs_problem)
	var next_id: int = _next_issued_id()
	for npc_id: int in _sorted_ids():
		var state: NpcState = _npcs[npc_id]
		if npc_id < IdGenerator.FIRST_ID or npc_id > IdGenerator.MAX_ID:
			problems.append("NPC %d: ID fora da faixa [%d, %d]." % [npc_id, IdGenerator.FIRST_ID, IdGenerator.MAX_ID])
		elif _ctx != null and npc_id >= next_id:
			problems.append("NPC %d: ID acima do contador do core (o próximo ID a sair é %d); esse ID nunca foi emitido." % [npc_id, next_id])
		if state.tier != NpcState.TIER_NORMAL and state.tier != NpcState.TIER_NOTABLE:
			problems.append("NPC %d: tier %d inválido; esperado %d ou %d." % [npc_id, state.tier, NpcState.TIER_NORMAL, NpcState.TIER_NOTABLE])
		_append_range_problems(problems, npc_id, "necessidade", state.need_values, NpcState.VALUE_MIN, NpcState.VALUE_MAX)
		_append_range_problems(problems, npc_id, "resto de necessidade", state.need_remainders, 0, NeedMath.MAX_REMAINDER)
		_append_range_problems(problems, npc_id, "traço", state.traits, NpcState.VALUE_MIN, NpcState.VALUE_MAX)
		if not state.is_alive and not state.action_id.is_empty():
			problems.append("NPC %d: morto, mas com ação atual '%s'; esperado nenhuma." % [npc_id, state.action_id])
		if state.next_think_time < 0:
			problems.append("NPC %d: next_think_time %d negativo; esperado 0 ou mais." % [npc_id, state.next_think_time])
		if state.critical_since < NpcState.NO_TIME:
			problems.append("NPC %d: critical_since %d inválido; esperado %d (nenhuma) ou um minuto de 0 em diante." % [npc_id, state.critical_since, NpcState.NO_TIME])
		if state.alarm_until < NpcState.NO_TIME:
			problems.append("NPC %d: alarm_until %d inválido; esperado %d (nenhuma) ou um minuto de 0 em diante." % [npc_id, state.alarm_until, NpcState.NO_TIME])
		if state.last_player_talk_at < NpcState.NO_TIME:
			problems.append("NPC %d: last_player_talk_at %d inválido; esperado %d (nunca) ou um minuto de 0 em diante." % [npc_id, state.last_player_talk_at, NpcState.NO_TIME])
		if not state.is_alive and state.critical_since != NpcState.NO_TIME:
			problems.append("NPC %d: morto, mas com critical_since %d; esperado %d." % [npc_id, state.critical_since, NpcState.NO_TIME])
		if _routine != null and not state.occupation_id.is_empty() and not _routine.has_occupation(state.occupation_id):
			problems.append("NPC %d: ofício '%s' inexistente nos dados de ofícios." % [npc_id, state.occupation_id])
	problems.append_array(_notables.problems())
	var food_stub: FoodStub = _food_stub()
	if food_stub != null:
		problems.append_array(food_stub.validate())
	return problems


## Contagens por tier, vivos e mortos (`counts`, que vêm do `peek_counts()` do módulo), ofícios, o tamanho em bytes do serialize() (backlog I4), o estoque
## de comida, a memória e as relações, o motivo da população inicial (`population_problem`), os corpos e o rastro. Só para depuração.
func debug_summary(counts: Dictionary, population_problem: String) -> Dictionary:
	var summary: Dictionary = counts
	var by_occupation: Dictionary = {}
	for npc_id: int in _sorted_ids():
		var occupation: String = _npcs[npc_id].occupation_id
		var label: String = occupation if not occupation.is_empty() else NpcModule.NO_OCCUPATION_LABEL
		by_occupation[label] = int(by_occupation.get(label, 0)) + 1
	var sorted_labels: Array = by_occupation.keys()
	sorted_labels.sort()
	var ordered: Dictionary = {}
	for label: Variant in sorted_labels:
		ordered[label] = by_occupation[label]
	summary["by_occupation"] = ordered
	summary["serialize_bytes"] = JSON.stringify(serialize()).to_utf8_buffer().size()
	var food_stub: FoodStub = _food_stub()
	if food_stub != null:
		summary["food_stock"] = food_stub.serialize()
	_notables.add_summary(summary)
	summary["population_problem"] = population_problem
	summary["bodies_available"] = _bodies.is_available()
	summary["traced_npcs"] = _tracer.traced_count()
	summary["trace_records_made"] = _tracer.records_made
	return summary


func _append_range_problems(problems: Array[String], npc_id: int, what: String, values: PackedInt64Array, lowest: int, highest: int) -> void:
	for index: int in values.size():
		if values[index] < lowest or values[index] > highest:
			problems.append("NPC %d: %s na posição %d fora de %d a %d (valor %d)." % [npc_id, what, index, lowest, highest, values[index]])


## Próximo ID que o contador do core entregaria (0 se o módulo ainda não passou por setup()).
func _next_issued_id() -> int:
	if _ctx == null:
		return IdGenerator.NO_ID
	# Variant: o contador sai do serialize() do core, que é dado simples.
	var raw_next: Variant = _ctx.ids.serialize()[IdGenerator.KEY_NEXT_ID]
	var next_id: int = raw_next
	return next_id


func _invalid_save(detail: String) -> Result:
	return Result.failure(NpcModule.CODE_INVALID_SAVE, "NpcModule.on_load: %s." % detail)


## ID de NPC a partir do texto da chave; NO_ID se não for um inteiro na faixa válida.
func _read_npc_id(key_text: String) -> int:
	if not key_text.is_valid_int():
		return IdGenerator.NO_ID
	var value: int = key_text.to_int()
	return value if value >= IdGenerator.FIRST_ID and value <= IdGenerator.MAX_ID else IdGenerator.NO_ID


## Nunca visitar o Dictionary pela ordem natural (muda depois de carregar um save). (O módulo tem a mesma função; consolidar numa faxina futura.)
func _sorted_ids() -> Array[int]:
	var ids: Array[int] = []
	ids.assign(_npcs.keys())
	ids.sort()
	return ids


## TEMP-LW-065: o FoodStub real, se o provedor de comida das definições for ele (os testes usam um provedor falso, sem estado salvo). (O módulo tem a mesma função.)
func _food_stub() -> FoodStub:
	if _definitions == null:
		return null
	return _definitions.food as FoodStub


## TEMP-LW-065: problema do trecho de comida do save (texto vazio = pode carregar). Save sem o trecho (de antes do FoodStub) é aceito: o
## estoque volta ao inicial. Trecho de comida num módulo sem FoodStub é recusado.
func _food_stock_save_problem(data: Dictionary) -> String:
	if not data.has(FoodStub.SAVE_KEY):
		return ""
	var food_stub: FoodStub = _food_stub()
	if food_stub == null:
		return "o save tem estoque de comida ('%s'), mas o módulo foi criado sem FoodStub" % FoodStub.SAVE_KEY
	return food_stub.check_save(data[FoodStub.SAVE_KEY])


## TEMP-LW-065: carrega o estoque já conferido (ou o devolve ao inicial se o save não tem o trecho).
func _load_food_stock(data: Dictionary) -> void:
	var food_stub: FoodStub = _food_stub()
	if food_stub == null:
		return
	if data.has(FoodStub.SAVE_KEY):
		var entries: Dictionary = data[FoodStub.SAVE_KEY]
		food_stub.load_save(entries)
	else:
		food_stub.reset_to_start()
