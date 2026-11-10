class_name NpcInspectorModel
extends RefCounted
## Modelo do painel de depuração de NPC (LW-082e; contrato em docs/modules/tools.md). Sem nó, sem ponte e sem texto: recebe as RESPOSTAS da ponte já feitas
## (`apply_*`; quem consulta a ponte é o painel, na LW-082f) e devolve o que mostrar, como LINHAS com chave de texto e valores (`Line`): o painel troca a
## chave pela frase (`UiText`), e os ids vindos dos dados (necessidades, ações, ofícios, locais, tipos de memória) seguem CRUS, como Arthur decidiu (Q5).
## Também guarda a seleção: lista de todos os NPCs, próximo e anterior com volta ao início. NPC que SOME da lista passa a seleção para o próximo id
## (volta ao primeiro se era o último) [HIP]; NPC que MORRE continua selecionado, marcado como morto. Só lê o que a ponte entrega: nada aqui escreve.

const NO_NPC: int = 0
## Quantas memórias (as mais recentes) e quantas relações (as mais fortes) o painel mostra. Decisão de Arthur (10) e [HIP].
const MAX_MEMORIES_SHOWN: int = 10
const MAX_RELATIONS_SHOWN: int = 10
## Código que a ponte devolve para NPC sem marca; copiado do `DecisionTracer` (`tools` não cita classe de `src/sim/`) e conferido em teste.
const CODE_NOT_TRACED: String = "NPC_NOT_TRACED"
## Nada escrito (texto vazio de um id) vira um traço.
const EMPTY_MARK: String = "-"
## Chaves de texto (data/text/pt_br.json, acrescentadas na LW-082f); os valores de cada uma estão em `values` da linha.
const KEY_PREFIX: String = "tools.npc_inspector."
const KEY_SUMMARY_TIME: String = KEY_PREFIX + "summary_time"
const KEY_SUMMARY_NPCS: String = KEY_PREFIX + "summary_npcs"
const KEY_SUMMARY_TIERS: String = KEY_PREFIX + "summary_tiers"
const KEY_SUMMARY_LEVELS: String = KEY_PREFIX + "summary_levels"
const KEY_SUMMARY_INTENTS: String = KEY_PREFIX + "summary_intents"
const KEY_SUMMARY_PROBLEMS: String = KEY_PREFIX + "summary_problems"
const KEY_SUMMARY_PROBLEM: String = KEY_PREFIX + "summary_problem"
const KEY_DETAIL_ALIVE: String = KEY_PREFIX + "detail_alive"
const KEY_DETAIL_DEAD: String = KEY_PREFIX + "detail_dead"
const KEY_NEED_LINE: String = KEY_PREFIX + "need_line"
const KEY_ACTION_LINE: String = KEY_PREFIX + "action_line"
const KEY_ACTION_IDLE: String = KEY_PREFIX + "action_idle"
const KEY_OCCUPATION_LINE: String = KEY_PREFIX + "occupation_line"
const KEY_TRACE_NOT_MARKED: String = KEY_PREFIX + "trace_not_marked"
const KEY_TRACE_EMPTY: String = KEY_PREFIX + "trace_empty"
const KEY_TRACE_THOUGHT: String = KEY_PREFIX + "trace_thought"
const KEY_TRACE_CANDIDATE: String = KEY_PREFIX + "trace_candidate"
const KEY_MEMORY_NONE: String = KEY_PREFIX + "memory_none"
const KEY_MEMORY_LINE: String = KEY_PREFIX + "memory_line"
const KEY_TRAIT_LINE: String = KEY_PREFIX + "trait_line"
const KEY_RELATION_NONE: String = KEY_PREFIX + "relation_none"
const KEY_RELATION_LINE: String = KEY_PREFIX + "relation_line"

var _roster: Array[BridgeInspectReplies.NpcRosterEntry] = []
var _selected_id: int = NO_NPC
var _summary: BridgeInspectReplies.SimSummaryReply
var _detail: BridgeInspectReplies.NpcDetailReply
var _trace: BridgeInspectReplies.NpcTraceReply
var _memories: BridgeInspectReplies.NpcMemoriesReply
var _relations: BridgeInspectReplies.NpcRelationsReply


## Uma linha a mostrar: a chave do texto e os valores que entram nos `{nome}` dele (já em texto ou número, sem formatação de idioma).
class Line:
	extends RefCounted

	var key: String
	var values: Dictionary

	func _init(line_key: String, line_values: Dictionary = {}) -> void:
		key = line_key
		values = line_values


# ---------------------------------------------------------------------------------------------------- seleção

func roster() -> Array[BridgeInspectReplies.NpcRosterEntry]:
	return _roster


func selected_id() -> int:
	return _selected_id


## A linha da lista do NPC selecionado, ou nulo se não há seleção.
func selected_entry() -> BridgeInspectReplies.NpcRosterEntry:
	return _entry_of(_selected_id)


## Seleciona o NPC. Id que não está na lista: falso e nada muda.
func select(npc_id: int) -> bool:
	if _entry_of(npc_id) == null:
		return false
	if npc_id != _selected_id:
		_selected_id = npc_id
		_forget_selected_data()
	return true


## Próximo da lista, com volta ao início. Sem seleção, vai ao primeiro. Lista vazia: não faz nada.
func select_next() -> void:
	if _roster.is_empty():
		return
	var position: int = _position_of(_selected_id)
	select(_roster[(position + 1) % _roster.size()].npc_id)


## Anterior da lista, com volta ao fim. Sem seleção, vai ao último. Lista vazia: não faz nada.
func select_previous() -> void:
	if _roster.is_empty():
		return
	var position: int = _position_of(_selected_id)
	select(_roster[(position - 1 + _roster.size()) % _roster.size() if position >= 0 else _roster.size() - 1].npc_id)


# ---------------------------------------------------------------------------------------------------- respostas da ponte

## Respostas com falha são ignoradas: fica o que já havia.
func apply_roster(reply: BridgeInspectReplies.NpcRosterReply) -> void:
	if not reply.result.ok:
		return
	_roster = reply.entries
	if _selected_id == NO_NPC or _entry_of(_selected_id) != null:
		return
	var gone_id: int = _selected_id
	_selected_id = NO_NPC
	_forget_selected_data()
	for entry: BridgeInspectReplies.NpcRosterEntry in _roster:
		if entry.npc_id > gone_id:
			_selected_id = entry.npc_id
			return
	if not _roster.is_empty():
		_selected_id = _roster[0].npc_id


func apply_summary(reply: BridgeInspectReplies.SimSummaryReply) -> void:
	if reply.result.ok:
		_summary = reply


## Só vale o detalhe do NPC selecionado (a resposta de outro, que chegou tarde, é ignorada).
func apply_detail(reply: BridgeInspectReplies.NpcDetailReply) -> void:
	if reply.result.ok and reply.npc_id == _selected_id:
		_detail = reply


## O rastro: com sucesso o NPC está MARCADO; `NPC_NOT_TRACED` quer dizer "sem marca" (não é erro); qualquer outra falha é ignorada.
func apply_trace(reply: BridgeInspectReplies.NpcTraceReply) -> void:
	if reply.result.ok:
		_trace = reply
	elif reply.result.code == CODE_NOT_TRACED:
		_trace = null


func apply_memories(reply: BridgeInspectReplies.NpcMemoriesReply) -> void:
	if reply.result.ok:
		_memories = reply


func apply_relations(reply: BridgeInspectReplies.NpcRelationsReply) -> void:
	if reply.result.ok:
		_relations = reply


## O NPC selecionado está marcado para o rastro (a última resposta de rastro foi de sucesso)?
func is_traced() -> bool:
	return _trace != null


# ---------------------------------------------------------------------------------------------------- o que mostrar

func summary_lines() -> Array[Line]:
	var lines: Array[Line] = []
	if _summary == null:
		return lines
	var time: BridgeReplies.TimeSnapshot = _summary.time
	lines.append(Line.new(KEY_SUMMARY_TIME, {"year": time.year, "day": time.day_of_year, "hour": "%02d" % time.hour_of_day, "minute": "%02d" % time.minute_of_hour}))
	lines.append(Line.new(KEY_SUMMARY_NPCS, {"total": _summary.npc_total, "alive": _summary.npc_alive, "dead": _summary.npc_dead}))
	lines.append(Line.new(KEY_SUMMARY_TIERS, {"normal": _summary.npc_tier_normal, "notable": _summary.npc_tier_notable}))
	lines.append(Line.new(KEY_SUMMARY_LEVELS, {"s0": _summary.npc_s0, "s1": _summary.npc_s1}))
	lines.append(Line.new(KEY_SUMMARY_INTENTS, {"count": _summary.pending_intents}))
	lines.append(Line.new(KEY_SUMMARY_PROBLEMS, {"count": _summary.problems.size()}))
	for problem: String in _summary.problems:
		lines.append(Line.new(KEY_SUMMARY_PROBLEM, {"text": problem}))
	return lines


## Do selecionado: se vive, as necessidades (com a urgência), a ação e o ofício.
func detail_lines() -> Array[Line]:
	var lines: Array[Line] = []
	if _detail == null:
		return lines
	var level: String = "S0" if _detail.level == BridgeInspectReplies.NpcLevel.S0 else "S1"
	var tier: String = "T2" if _detail.tier == BridgeInspectReplies.TIER_NOTABLE else "T1"
	if _detail.is_alive:
		lines.append(Line.new(KEY_DETAIL_ALIVE, {"level": level, "tier": tier}))
	else:
		lines.append(Line.new(KEY_DETAIL_DEAD, {"level": level, "tier": tier, "cause": _raw(_detail.death_cause)}))
	for index: int in mini(_detail.need_ids.size(), _detail.need_values.size()):
		lines.append(Line.new(KEY_NEED_LINE, {"id": _detail.need_ids[index], "value": _detail.need_values[index], "urgency": _detail.need_urgencies[index] if index < _detail.need_urgencies.size() else 0}))
	if _detail.action_id.is_empty():
		lines.append(Line.new(KEY_ACTION_IDLE))
	else:
		lines.append(Line.new(KEY_ACTION_LINE, {"action": _detail.action_id, "place": _raw(_detail.action_target_place_id), "started": _detail.action_started_at, "ends": _detail.action_ends_at, "serial": _detail.action_serial}))
	lines.append(Line.new(KEY_OCCUPATION_LINE, {"occupation": _raw(_detail.occupation_id), "home": _raw(_detail.home_place_id), "work": _raw(_detail.work_place_id), "routine": _raw(_detail.routine_action_id)}))
	return lines


## O rastro do selecionado, o pensamento mais novo primeiro, cada um com todas as candidatas. Sem marca ou sem pensamento ainda: uma linha só.
func trace_lines() -> Array[Line]:
	var lines: Array[Line] = []
	if _selected_id == NO_NPC:
		return lines
	if _trace == null:
		lines.append(Line.new(KEY_TRACE_NOT_MARKED))
		return lines
	if _trace.records.is_empty():
		lines.append(Line.new(KEY_TRACE_EMPTY))
	for index: int in range(_trace.records.size() - 1, -1, -1):
		var record: BridgeInspectReplies.NpcTraceRecord = _trace.records[index]
		lines.append(Line.new(KEY_TRACE_THOUGHT, {"minute": record.minute, "action": _raw(record.chosen_action_id), "place": _raw(record.chosen_place_id), "reason": _raw(record.reason)}))
		for candidate: BridgeInspectReplies.NpcTraceCandidate in record.candidates:
			lines.append(Line.new(KEY_TRACE_CANDIDATE, {"action": candidate.action_id, "place": _raw(candidate.place_id), "total": candidate.total, "benefit": candidate.benefit, "personality": candidate.personality, "time": candidate.time_cost, "distance": candidate.distance_cost, "risk": candidate.risk_cost, "inertia": candidate.inertia_bonus, "routine": candidate.routine_bonus, "current": "*" if candidate.is_current else "", "source": _raw(candidate.source)}))
	return lines


## As memórias mais recentes (até MAX_MEMORIES_SHOWN, pelo minuto; empate: a que entrou depois) e os traços permanentes.
func memory_lines() -> Array[Line]:
	var lines: Array[Line] = []
	if _memories == null:
		return lines
	if _memories.records.is_empty() and _memories.traits.is_empty():
		lines.append(Line.new(KEY_MEMORY_NONE))
		return lines
	var order: Array[int] = []
	order.assign(range(_memories.records.size()))
	var records: Array[BridgeInspectReplies.NpcMemoryEntry] = _memories.records
	order.sort_custom(func(first: int, second: int) -> bool: return records[first].time > records[second].time if records[first].time != records[second].time else first > second)
	for position: int in mini(order.size(), MAX_MEMORIES_SHOWN):
		var record: BridgeInspectReplies.NpcMemoryEntry = records[order[position]]
		var actors: PackedStringArray = PackedStringArray()
		for actor_id: int in record.actors:
			actors.append(str(actor_id))
		lines.append(Line.new(KEY_MEMORY_LINE, {"kind": record.kind, "time": record.time, "valence": record.valence, "salience": record.salience, "place": _raw(record.place_id), "actors": ",".join(actors) if not actors.is_empty() else EMPTY_MARK}))
	for memory_trait: BridgeInspectReplies.NpcTraitEntry in _memories.traits:
		lines.append(Line.new(KEY_TRAIT_LINE, {"actor": memory_trait.actor_id, "valence": memory_trait.valence, "since": memory_trait.since}))
	return lines


## As relações mais fortes (até MAX_RELATIONS_SHOWN): a maior soma dos módulos das cinco dimensões primeiro; empate pelo menor id da outra pessoa.
func relation_lines() -> Array[Line]:
	var lines: Array[Line] = []
	if _relations == null:
		return lines
	if _relations.entries.is_empty():
		lines.append(Line.new(KEY_RELATION_NONE))
		return lines
	var entries: Array[BridgeInspectReplies.NpcRelationEntry] = _relations.entries
	var order: Array[int] = []
	order.assign(range(entries.size()))
	order.sort_custom(func(first: int, second: int) -> bool: return _strength(entries[first]) > _strength(entries[second]) if _strength(entries[first]) != _strength(entries[second]) else entries[first].other_id < entries[second].other_id)
	for position: int in mini(order.size(), MAX_RELATIONS_SHOWN):
		var entry: BridgeInspectReplies.NpcRelationEntry = entries[order[position]]
		lines.append(Line.new(KEY_RELATION_LINE, {"other": entry.other_id, "label": entry.label, "affection": entry.values[0], "trust": entry.values[1], "respect": entry.values[2], "fear": entry.values[3], "debt": entry.values[4], "met": entry.met_at}))
	return lines


# ---------------------------------------------------------------------------------------------------- por dentro

func _entry_of(npc_id: int) -> BridgeInspectReplies.NpcRosterEntry:
	var position: int = _position_of(npc_id)
	return _roster[position] if position >= 0 else null


## Posição do NPC na lista, ou -1 se não está nela.
func _position_of(npc_id: int) -> int:
	for index: int in _roster.size():
		if _roster[index].npc_id == npc_id:
			return index
	return -1


## O detalhe, o rastro, as memórias e as relações são do NPC antigo: somem quando a seleção muda.
func _forget_selected_data() -> void:
	_detail = null
	_trace = null
	_memories = null
	_relations = null


static func _raw(text: String) -> String:
	return text if not text.is_empty() else EMPTY_MARK


static func _strength(entry: BridgeInspectReplies.NpcRelationEntry) -> int:
	var total: int = 0
	for value: int in entry.values:
		total += absi(value)
	return total
