class_name NpcNotables
extends RefCounted
## Notáveis (T2) do `npc` (docs/modules/npc.md, seções 7 e 8): a memória (LW-078), as relações entre pessoas (LW-079), a promoção e o rebaixamento
## (LW-077) e o descarte de tudo isso quando o NPC morre ou sai. LW-081a (passo 2): o código saiu do `NpcModule` sem mudar de comportamento; o módulo
## segue sendo a única porta (com a conferência de build de desenvolvimento dos comandos de depuração) e só delega aqui; a documentação de cada
## pedido fica nele. A classe é DONA da tabela de memórias e do grafo de relações; a tabela de NPCs é a do módulo (a mesma, por referência).

var _npcs: Dictionary[int, NpcState]
var _definitions: NpcModule.Definitions
## "NPC inexistente" do módulo (a mesma falha tratada em toda a API): recebe o nome do chamador e o ID.
var _unknown: Callable
var _ctx: SimContext
## Memória dos NPCs notáveis (LW-078), por npc_id: só tem entrada quem já guardou algo. Salva junto (chave `memories`).
var _memories: Dictionary[int, NpcMemory] = {}
## Relações entre pessoas (LW-079): uma por par, numa tabela só. Salva junto (chave `relations`).
var _relations: RelationGraph = RelationGraph.new()


func _init(npcs: Dictionary[int, NpcState], definitions: NpcModule.Definitions, unknown_npc: Callable) -> void:
	_npcs = npcs
	_definitions = definitions
	_unknown = unknown_npc


func setup(ctx: SimContext) -> void:
	_ctx = ctx


## Teto de notáveis vivos (`max_t2` dos parâmetros); 0 = sem teto configurado (sem definições ou sem parâmetros também).
func max_notable() -> int:
	return _definitions.params.max_t2 if _definitions != null and _definitions.params != null else 0


## Promove o NPC de T1 a T2 (LW-077), com o teto global `max_t2`. Regras completas em `NpcTiers.promote`.
func promote(npc_id: int, tier: int) -> Result:
	if not _npcs.has(npc_id):
		return _not_found("request_promote", npc_id)
	return NpcTiers.promote(_npcs[npc_id], tier, NpcTiers.count_notable_alive(_npcs), max_notable())


## Rebaixa o NPC de T2 a T1 (LW-077) e libera a vaga; antes de mudar o tier chama `_on_demoting`. Regras em `NpcTiers.demote`.
func demote(npc_id: int, tier: int) -> Result:
	if not _npcs.has(npc_id):
		return _not_found("request_demote", npc_id)
	return NpcTiers.demote(_npcs[npc_id], tier, _on_demoting)


## A morte do NPC (LW-081) e a remoção dele (LW-057) descartam a memória e as relações dele.
func forget(npc_id: int) -> void:
	_memories.erase(npc_id)
	_relations.remove_involving(npc_id)


## As memórias do NPC, em CÓPIAS (LW-078); `kind_filter` vazio = todos os tipos. ID inexistente ou tipo que não existe nos dados: falha tratada.
func peek_memories(npc_id: int, kind_filter: String = "") -> NpcModule.MemoriesQuery:
	if not _npcs.has(npc_id):
		return NpcModule.MemoriesQuery.new(_not_found("peek_memories", npc_id), [], [])
	var known_kinds: Array[String] = _known_kind_ids()
	if not kind_filter.is_empty() and not known_kinds.is_empty() and not known_kinds.has(kind_filter):
		return NpcModule.MemoriesQuery.new(_unknown_kind("peek_memories", kind_filter, known_kinds), [], [])
	var memory: NpcMemory = _memories.get(npc_id)
	if memory == null:
		return NpcModule.MemoriesQuery.new(Result.success(), [], [])
	return NpcModule.MemoriesQuery.new(Result.success(), memory.copy_records(kind_filter), memory.copy_traits())


## O que `a_id` pensa de `b_id` (LW-079): as cinco dimensões de HOJE (com o decaimento diário), o rótulo e se `b_id` está vivo. Pedido sem sentido: falha tratada.
func peek_opinion(a_id: int, b_id: int) -> NpcModule.OpinionQuery:
	for person_id: int in [a_id, b_id]:
		if person_id < IdGenerator.FIRST_ID or person_id > IdGenerator.MAX_ID:
			return NpcModule.OpinionQuery.new(Result.failure(RelationGraph.CODE_INVALID, "NpcModule.peek_opinion: ID %d fora da faixa [%d, %d]." % [person_id, IdGenerator.FIRST_ID, IdGenerator.MAX_ID]))
	if a_id == b_id:
		return NpcModule.OpinionQuery.new(Result.failure(RelationGraph.CODE_INVALID, "NpcModule.peek_opinion: uma pessoa (%d) não tem relação com ela mesma." % a_id))
	if not _npcs.has(a_id) and not _npcs.has(b_id):
		return NpcModule.OpinionQuery.new(_not_found("peek_opinion", a_id))
	var query: NpcModule.OpinionQuery = NpcModule.OpinionQuery.new(Result.success())
	query.other_is_alive = not _npcs.has(b_id) or _npcs[b_id].is_alive
	var relation: NpcRelation = _relations.find(a_id, b_id)
	if relation == null:
		return query
	var rules: RelationGraph.Rules = _relation_rules()
	query.is_known = true
	query.values = relation.values_at(_today(), rules.decay_per_day)
	query.label = RelationGraph.label_for(query.values[NpcRelation.DIM_AFFECTION], rules)
	query.met_at = relation.met_at
	return query


## As relações do NPC, em CÓPIAS (LW-082b): uma por pessoa que ele conhece, em ordem crescente do ID da outra, com as dimensões de HOJE (a mesma conta de
## `peek_opinion`). ID inexistente: falha tratada. Morto não tem relações (a morte as descartou): lista vazia, com sucesso.
func peek_relations(npc_id: int) -> NpcRelationsQuery:
	if not _npcs.has(npc_id):
		return NpcRelationsQuery.new(_not_found("peek_relations", npc_id))
	return NpcRelationsQuery.build(_relations, _npcs, npc_id, _today(), _relation_rules())


## Caminho único de ajuste das relações (LW-079): o comando de depuração, as ações sociais (LW-080) e, na LW-083, a conversa com o jogador. As regras
## (Q11, limite por NPC, mudanças válidas) estão em `RelationGraph.adjust`; recusado, nada muda. Ajustou, publica `RelationChanged` (LW-080).
func adjust_relation(a_id: int, b_id: int, deltas: PackedInt64Array) -> Result:
	if _ctx == null:
		return Result.failure(NpcModule.CODE_NOT_READY, "NpcModule.request_adjust_relation: módulo sem setup() (sem relógio); esperado um módulo registrado no World.")
	var rules: RelationGraph.Rules = _relation_rules()
	var today: int = _today()
	var existing: NpcRelation = _relations.find(a_id, b_id)
	var before: PackedInt64Array = existing.values_at(today, rules.decay_per_day) if existing != null else PackedInt64Array()
	var adjusted: Result = _relations.adjust(a_id, b_id, deltas, _ctx.clock.total_minutes(), rules, _npcs)
	if adjusted.ok:
		# `RelationChanged` (LW-080): relação nova ou com valor diferente, no máximo uma vez por par por dia (o dia vai na própria relação).
		var relation: NpcRelation = _relations.find(a_id, b_id)
		var after: PackedInt64Array = relation.values_at(today, rules.decay_per_day)
		if (before.is_empty() or before != after) and relation.last_event_day < today:
			relation.last_event_day = today
			_ctx.events.publish(RelationChanged.new(relation.a_id, relation.b_id, after))
	return adjusted


## As dimensões de hoje do par, ou uma lista vazia se não se conhecem (o que o `SocialActions` pergunta antes de somar o ganho da conversa).
func relation_values(a_id: int, b_id: int) -> PackedInt64Array:
	var relation: NpcRelation = _relations.find(a_id, b_id)
	if relation == null:
		return PackedInt64Array()
	return relation.values_at(_today(), _relation_rules().decay_per_day)


## Caminho único de gravação na memória (LW-078): o comando de depuração, as ações sociais (LW-080) e a conversa com o jogador (LW-083). Só NPC vivo e
## notável (T2) tem memória; o tipo precisa existir em `data/memory_kinds.json`; até `MemoryRecord.MAX_ACTORS` pessoas válidas. Recusado, nada muda.
func record_memory(npc_id: int, kind_id: String, actor_ids: Array[int], place_id: String) -> Result:
	if _ctx == null:
		return Result.failure(NpcModule.CODE_NOT_READY, "NpcModule.request_record_memory: módulo sem setup() (sem relógio); esperado um módulo registrado no World.")
	if not _npcs.has(npc_id):
		return _not_found("request_record_memory", npc_id)
	var rules: NpcMemory.Rules = _memory_rules_or_null()
	if rules == null:
		return Result.failure(NpcModule.CODE_MEMORY_NOT_CONFIGURED, "NpcModule.request_record_memory: memória não configurada; esperado Definitions.memory_kinds com algum tipo e memory_capacity maior que 0 nos parâmetros.")
	var state: NpcState = _npcs[npc_id]
	if not state.is_alive:
		return Result.failure(NpcTiers.CODE_DEAD, "NpcModule.request_record_memory: o NPC %d está morto; esperado um NPC vivo." % npc_id)
	if state.tier != NpcState.TIER_NOTABLE:
		return Result.failure(NpcModule.CODE_NOT_NOTABLE, "NpcModule.request_record_memory: o NPC %d é cidadão (T1); só notável (T2) tem memória, então é preciso promovê-lo antes (request_promote)." % npc_id)
	var known_kinds: Array[String] = _known_kind_ids()
	if not known_kinds.has(kind_id):
		return _unknown_kind("request_record_memory", kind_id, known_kinds)
	var actors_problem: String = _actors_problem(npc_id, actor_ids)
	if not actors_problem.is_empty():
		return Result.failure(NpcModule.CODE_INVALID_MEMORY, "NpcModule.request_record_memory: pedido inválido para o NPC %d: %s." % [npc_id, actors_problem])
	var kind: MemoryKindLoader.KindDef = _kind_by_id(kind_id)
	var record: MemoryRecord = MemoryRecord.new()
	record.kind = kind.id
	record.actors = PackedInt64Array(actor_ids)
	record.place_id = place_id
	record.time = _ctx.clock.total_minutes()
	record.valence = kind.valence
	record.salience = kind.salience
	if not _memories.has(npc_id):
		_memories[npc_id] = NpcMemory.new()
	_memories[npc_id].remember(record, record.time, rules)
	return Result.success()


func memories_to_dict() -> Dictionary:
	return NpcMemory.table_to_dict(_memories)


func has_relations() -> bool:
	return not _relations.is_empty()


func relations_to_array() -> Array:
	return _relations.to_array()


## Confere a memória e as relações cruas de um save SEM alterar nada (a primeira falha de cada vez). `error` vazio = pode carregar.
## Variant: valores crus do save (JSON); o tipo é conferido por `NpcMemory.parse_table` e `RelationGraph.parse`.
func parse_save(raw_memories: Variant, raw_relations: Variant) -> ParsedSave:
	var parsed: ParsedSave = ParsedSave.new()
	parsed.memories = NpcMemory.parse_table(raw_memories)
	if not parsed.memories.error.is_empty():
		parsed.error = parsed.memories.error
		return parsed
	parsed.relations = RelationGraph.parse(raw_relations)
	parsed.error = parsed.relations.error
	return parsed


## Troca a memória e as relações pelas de um save já conferido (`parse_save` sem erro).
func replace_with(parsed: ParsedSave) -> void:
	_memories = parsed.memories.table
	_relations = parsed.relations.graph


## Problemas do estado dos notáveis (lista vazia se estiver tudo certo): teto de T2, memórias e relações.
func problems() -> Array[String]:
	var found: Array[String] = []
	var tier_problem: String = NpcTiers.limit_problem(NpcTiers.count_notable_alive(_npcs), max_notable())
	if not tier_problem.is_empty():
		found.append(tier_problem)
	found.append_array(NpcMemory.table_problems(_memories, _npcs, _memory_rules_or_null(), _known_kind_ids()))
	found.append_array(_relations.problems(_npcs, _relation_rules(), _today() if _ctx != null else -1))
	for relation: NpcRelation in _relations.sorted_relations():
		if relation.last_event_day < NpcRelation.NO_EVENT_DAY or (_ctx != null and relation.last_event_day > _today()):
			found.append("Relação %s: last_event_day %d fora de %d (nunca) a hoje." % [relation.key(), relation.last_event_day, NpcRelation.NO_EVENT_DAY])
	return found


func add_summary(summary: Dictionary) -> void:
	var memory_records: int = 0
	var memory_traits: int = 0
	for memory: NpcMemory in _memories.values():
		memory_records += memory.records.size()
		memory_traits += memory.traits.size()
	summary["npcs_with_memory"] = _memories.size()
	summary["memory_records"] = memory_records
	summary["memory_traits"] = memory_traits
	summary["relations"] = _relations.relations.size()


func _not_found(caller: String, npc_id: int) -> Result:
	var failure: Result = _unknown.call(caller, npc_id)
	return failure


## As regras das relações (parâmetros de `Definitions`); sem parâmetros, tudo em 0 (relações não configuradas).
func _relation_rules() -> RelationGraph.Rules:
	if _definitions == null or _definitions.params == null:
		return RelationGraph.Rules.new(0, 0, 0, 0)
	var params: NpcParams = _definitions.params
	return RelationGraph.Rules.new(params.relations_capacity, params.relation_decay_per_day, params.relation_friend_threshold, params.relation_rival_threshold)


## Dia de simulação de agora (0 se o módulo ainda não passou por setup()).
func _today() -> int:
	return IntMath.floor_div(_ctx.clock.total_minutes(), SimClock.MINUTES_PER_DAY) if _ctx != null else 0


## Primeiro problema da lista de pessoas do episódio (texto vazio se está certa).
func _actors_problem(npc_id: int, actor_ids: Array[int]) -> String:
	if actor_ids.size() > MemoryRecord.MAX_ACTORS:
		return "%d pessoas; o máximo é %d" % [actor_ids.size(), MemoryRecord.MAX_ACTORS]
	for index: int in actor_ids.size():
		var actor_id: int = actor_ids[index]
		if actor_id < IdGenerator.FIRST_ID or actor_id > IdGenerator.MAX_ID:
			return "pessoa %d fora da faixa de IDs [%d, %d]" % [actor_id, IdGenerator.FIRST_ID, IdGenerator.MAX_ID]
		if actor_id == npc_id:
			return "o NPC não pode ser uma das pessoas do próprio episódio (%d)" % actor_id
		if actor_ids.find(actor_id) != index:
			return "pessoa %d repetida" % actor_id
	return ""


## As regras da memória (parâmetros e tipos de episódio de `Definitions`), ou nulo se a memória não está configurada: sem tipos, ou sem
## `memory_capacity` maior que 0.
func _memory_rules_or_null() -> NpcMemory.Rules:
	if _definitions == null or _definitions.params == null or _definitions.params.memory_capacity <= 0 or _definitions.memory_kinds.is_empty():
		return null
	var decays: Dictionary[String, int] = {}
	for kind: MemoryKindLoader.KindDef in _definitions.memory_kinds:
		decays[kind.id] = kind.decay_per_day
	return NpcMemory.Rules.new(_definitions.params.memory_capacity, _definitions.params.trait_threshold, _definitions.params.trait_slots, decays)


## Ids dos tipos de episódio configurados (vazio = nenhum configurado).
func _known_kind_ids() -> Array[String]:
	var ids: Array[String] = []
	if _definitions != null:
		for kind: MemoryKindLoader.KindDef in _definitions.memory_kinds:
			ids.append(kind.id)
	return ids


func _kind_by_id(kind_id: String) -> MemoryKindLoader.KindDef:
	if _definitions != null:
		for kind: MemoryKindLoader.KindDef in _definitions.memory_kinds:
			if kind.id == kind_id:
				return kind
	return null


func _unknown_kind(caller: String, kind_id: String, known_kinds: Array[String]) -> Result:
	return Result.failure(NpcModule.CODE_UNKNOWN_MEMORY_KIND, "NpcModule.%s: tipo de memória '%s' inexistente; esperado um de: %s." % [caller, kind_id, ", ".join(known_kinds)])


## Ponto de extensão do rebaixamento (LW-077), chamado por `NpcTiers.demote` ANTES de o tier mudar (o NPC ainda é notável): resume a memória dele
## em traços permanentes (LW-078); as relações dele com outro CIDADÃO saem (Q11) e a afeição de cada uma vira traço (LW-079); a com o jogador fica,
## arredondada; as com notáveis ficam. Por último avisa o gancho de fora (`Definitions.on_demote`, usado pelos testes).
func _on_demoting(npc_id: int) -> void:
	var now: int = _ctx.clock.total_minutes() if _ctx != null else 0
	var relation_traits: Dictionary[int, int] = _relations.demote_relations_of(npc_id, now, _relation_rules(), _npcs)
	var memory: NpcMemory = _memories.get(npc_id)
	var rules: NpcMemory.Rules = _memory_rules_or_null()
	if rules != null and (memory != null or not relation_traits.is_empty()):
		if memory == null:
			memory = NpcMemory.new()
			_memories[npc_id] = memory
		memory.summarize(now, rules)
		memory.absorb_sums(relation_traits, now, rules)
		if memory.is_empty():
			_memories.erase(npc_id)
	if _definitions != null and _definitions.on_demote.is_valid():
		_definitions.on_demote.call(npc_id)


## O que `parse_save` devolve: `error` vazio = os dois pedaços conferem e `replace_with` pode trocá-los.
class ParsedSave:
	extends RefCounted

	var error: String = ""
	var memories: NpcMemory.TableResult
	var relations: RelationGraph.ParseResult
