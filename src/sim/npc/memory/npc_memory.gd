class_name NpcMemory
extends RefCounted
## A memória de UM NPC notável (T2) (LW-078; docs/modules/npc.md, seção 7): os registros (episódios) e os traços permanentes. Lógica pura, em
## inteiros, sem relógio nem sorteio: quem chama entrega o minuto `now` e as regras (`Rules`). ESQUECIMENTO POR VALOR: valor = saliência menos
## (idade em dias inteiros x desgaste do tipo), nunca abaixo de 0; com a memória cheia sai o de MENOR valor (empate: o mais antigo). Antes de
## sair, um registro com saliência ACIMA do limiar vira TRAÇO PERMANENTE: uma valência por pessoa (soma limitada a -100..100), no máximo
## `trait_slots` traços por NPC. Rebaixar o NPC (`summarize`) resume os registros que restam em traços e esvazia a lista de registros.
## O valor é calculado na hora de usar (a idade vem do relógio): não há tick de decaimento e nada disto depende da frequência de uso.

const KEY_RECORDS: String = "records"
const KEY_TRAITS: String = "traits"
const KEY_ACTOR_ID: String = "actor_id"
const KEY_VALENCE: String = "valence"
const KEY_SINCE: String = "since"

var records: Array[MemoryRecord] = []
var traits: Array[Trait] = []


## Valor de um registro em `now`: a saliência menos (idade em dias inteiros x desgaste do tipo), nunca abaixo de 0. Tipo desconhecido não desgasta.
static func value_of(record: MemoryRecord, now: int, rules: Rules) -> int:
	var age_days: int = IntMath.floor_div(maxi(now - record.time, 0), SimClock.MINUTES_PER_DAY)
	var decay: int = int(rules.decay_per_day.get(record.kind, 0))
	return maxi(record.salience - age_days * decay, 0)


func is_empty() -> bool:
	return records.is_empty() and traits.is_empty()


## Guarda o registro. Com mais registros que a capacidade, sai o de MENOR valor entre todos (o novo inclusive); empate: o mais antigo (menor
## `time`; no mesmo minuto, o que entrou primeiro). Antes de sair, um registro com saliência acima do limiar vira traço permanente.
func remember(record: MemoryRecord, now: int, rules: Rules) -> void:
	records.append(record)
	while records.size() > rules.capacity:
		_forget(_weakest_index(now, rules), now, rules)


## Rebaixamento: os registros que restam viram traços (valência somada por pessoa e limitada a -100..100; as pessoas de maior módulo primeiro,
## empate: o menor ID) e a lista de registros se esvazia, então promover de novo não duplica nada. Registro sem pessoa não deixa traço, e uma
## soma zero não diz nada sobre a pessoa. Os traços que já existiam continuam.
func summarize(now: int, rules: Rules) -> void:
	var sums: Dictionary[int, int] = {}
	for record: MemoryRecord in records:
		for actor_id: int in record.actors:
			sums[actor_id] = int(sums.get(actor_id, 0)) + record.valence
	absorb_sums(sums, now, rules)
	records.clear()


## Transforma valências por pessoa (pessoa -> valência) em traços: as de maior módulo primeiro, empate: o menor ID; soma zero não diz nada e
## não vira traço; quem já tem traço soma nele. Usada pelo resumo dos registros e, na LW-079, pelo das relações ao rebaixar.
func absorb_sums(sums: Dictionary[int, int], now: int, rules: Rules) -> void:
	var actor_ids: Array = sums.keys()
	actor_ids.sort_custom(func(first: int, second: int) -> bool:
		if absi(sums[first]) != absi(sums[second]):
			return absi(sums[first]) > absi(sums[second])
		return first < second)
	for actor_id: int in actor_ids:
		if sums[actor_id] != 0:
			_add_to_trait(actor_id, clampi(sums[actor_id], MemoryRecord.MIN_VALENCE, MemoryRecord.MAX_VALENCE), now, rules)


## Cópias dos registros, na ordem em que entraram; `kind_filter` vazio = todos.
func copy_records(kind_filter: String) -> Array[MemoryRecord]:
	var found: Array[MemoryRecord] = []
	for record: MemoryRecord in records:
		if kind_filter.is_empty() or record.kind == kind_filter:
			found.append(record.duplicate_record())
	return found


func copy_traits() -> Array[Trait]:
	var found: Array[Trait] = []
	for memory_trait: Trait in traits:
		found.append(memory_trait.duplicate_trait())
	return found


func to_dict() -> Dictionary:
	var saved_records: Array = []
	for record: MemoryRecord in records:
		saved_records.append(record.to_dict())
	var saved_traits: Array = []
	for memory_trait: Trait in traits:
		saved_traits.append(memory_trait.to_dict())
	return {KEY_RECORDS: saved_records, KEY_TRAITS: saved_traits}


## Lê a memória de um NPC do save. Só confere formato e tipos; faixas e coerência são do `validate()` do módulo.
static func parse(raw_entry: Variant) -> ParseResult:
	if typeof(raw_entry) != TYPE_DICTIONARY:
		return ParseResult.new(null, "a memória não é um objeto (veio %s)" % type_string(typeof(raw_entry)))
	var entry: Dictionary = raw_entry
	for list_key: String in [KEY_RECORDS, KEY_TRAITS]:
		if typeof(entry.get(list_key)) != TYPE_ARRAY:
			return ParseResult.new(null, MemoryRecord.bad_field(entry, list_key, "lista"))
	var memory: NpcMemory = NpcMemory.new()
	var raw_records: Array = entry[KEY_RECORDS]
	for index: int in raw_records.size():
		var parsed_record: MemoryRecord.ParseResult = MemoryRecord.parse(raw_records[index])
		if parsed_record.record == null:
			return ParseResult.new(null, "registro %d: %s" % [index, parsed_record.error])
		memory.records.append(parsed_record.record)
	var raw_traits: Array = entry[KEY_TRAITS]
	for index: int in raw_traits.size():
		var problem: Array[String] = []
		var memory_trait: Trait = _parse_trait(raw_traits[index], problem)
		if memory_trait == null:
			return ParseResult.new(null, "traço %d: %s" % [index, problem[0]])
		memory.traits.append(memory_trait)
	return ParseResult.new(memory, "")


## A tabela do módulo (npc_id -> memória) como dicionário do save: IDs em texto, em ordem crescente, e só entra quem tem alguma coisa guardada.
static func table_to_dict(table: Dictionary[int, NpcMemory]) -> Dictionary:
	var ids: Array = table.keys()
	ids.sort()
	var saved: Dictionary = {}
	for npc_id: int in ids:
		if not table[npc_id].is_empty():
			saved[str(npc_id)] = table[npc_id].to_dict()
	return saved


## Lê a tabela do save. Qualquer problema de formato recusa a tabela inteira (o módulo não altera nada).
static func parse_table(raw_table: Variant) -> TableResult:
	if typeof(raw_table) != TYPE_DICTIONARY:
		return TableResult.new({}, "o campo da memória não é um objeto (veio %s)" % type_string(typeof(raw_table)))
	var entries: Dictionary = raw_table
	var keys: Array = entries.keys()
	keys.sort()
	var table: Dictionary[int, NpcMemory] = {}
	for key: Variant in keys:
		var key_text: String = str(key)
		var npc_id: int = key_text.to_int() if key_text.is_valid_int() else IdGenerator.NO_ID
		if npc_id < IdGenerator.FIRST_ID or npc_id > IdGenerator.MAX_ID:
			return TableResult.new({}, "chave de memória '%s' inválida; esperado um ID de NPC inteiro de %d a %d" % [key_text, IdGenerator.FIRST_ID, IdGenerator.MAX_ID])
		if table.has(npc_id):
			return TableResult.new({}, "a memória do NPC %d aparece duas vezes (chave '%s')" % [npc_id, key_text])
		var parsed: ParseResult = parse(entries[key])
		if parsed.memory == null:
			return TableResult.new({}, "memória do NPC %d: %s" % [npc_id, parsed.error])
		table[npc_id] = parsed.memory
	return TableResult.new(table, "")


## Problemas da tabela para o `validate()` do módulo (lista vazia se está tudo certo). `rules` nulo = sem regras configuradas (a capacidade e
## o limite de traços não são conferidos); `known_kinds` vazio = sem tipos configurados (o tipo do registro não é conferido).
static func table_problems(table: Dictionary[int, NpcMemory], states: Dictionary[int, NpcState], rules: Rules, known_kinds: Array[String]) -> Array[String]:
	var problems: Array[String] = []
	var ids: Array = table.keys()
	ids.sort()
	for npc_id: int in ids:
		var memory: NpcMemory = table[npc_id]
		if not states.has(npc_id):
			problems.append("Memória guardada para o NPC %d, que não existe." % npc_id)
			continue
		var state: NpcState = states[npc_id]
		if not state.is_alive and not memory.is_empty():
			problems.append("NPC %d: morto, mas com memória guardada; esperado nenhuma (a morte a descarta)." % npc_id)
		elif state.tier != NpcState.TIER_NOTABLE and not memory.records.is_empty():
			problems.append("NPC %d: tem %d registro(s) de memória, mas é cidadão (T1); só notável (T2) tem registros." % [npc_id, memory.records.size()])
		if rules != null and memory.records.size() > rules.capacity:
			problems.append("NPC %d: %d registros de memória, mais que a capacidade %d." % [npc_id, memory.records.size(), rules.capacity])
		if rules != null and memory.traits.size() > rules.trait_slots:
			problems.append("NPC %d: %d traços permanentes, mais que o limite %d." % [npc_id, memory.traits.size(), rules.trait_slots])
		for index: int in memory.records.size():
			problems.append_array(_record_problems(npc_id, index, memory.records[index], known_kinds))
		for index: int in memory.traits.size():
			var memory_trait: Trait = memory.traits[index]
			if memory_trait.actor_id < IdGenerator.FIRST_ID or memory_trait.actor_id > IdGenerator.MAX_ID or memory_trait.actor_id == npc_id:
				problems.append("NPC %d: traço %d com pessoa %d inválida." % [npc_id, index, memory_trait.actor_id])
			if memory_trait.valence < MemoryRecord.MIN_VALENCE or memory_trait.valence > MemoryRecord.MAX_VALENCE:
				problems.append("NPC %d: traço %d com valência %d fora de %d a %d." % [npc_id, index, memory_trait.valence, MemoryRecord.MIN_VALENCE, MemoryRecord.MAX_VALENCE])
	return problems


static func _record_problems(npc_id: int, index: int, record: MemoryRecord, known_kinds: Array[String]) -> Array[String]:
	var problems: Array[String] = []
	var label: String = "NPC %d: registro %d" % [npc_id, index]
	if not known_kinds.is_empty() and not known_kinds.has(record.kind):
		problems.append("%s com tipo '%s' inexistente nos dados de tipos de memória." % [label, record.kind])
	if record.source != MemoryRecord.SOURCE_WITNESSED:
		problems.append("%s com fonte '%s'; esperado %s." % [label, record.source, MemoryRecord.SOURCE_WITNESSED])
	if record.time < 0:
		problems.append("%s com tempo %d negativo." % [label, record.time])
	if record.valence < MemoryRecord.MIN_VALENCE or record.valence > MemoryRecord.MAX_VALENCE:
		problems.append("%s com valência %d fora de %d a %d." % [label, record.valence, MemoryRecord.MIN_VALENCE, MemoryRecord.MAX_VALENCE])
	if record.salience < MemoryRecord.MIN_SALIENCE or record.salience > MemoryRecord.MAX_SALIENCE:
		problems.append("%s com saliência %d fora de %d a %d." % [label, record.salience, MemoryRecord.MIN_SALIENCE, MemoryRecord.MAX_SALIENCE])
	if record.confidence < MemoryRecord.MIN_CONFIDENCE or record.confidence > MemoryRecord.MAX_CONFIDENCE:
		problems.append("%s com confiança %d fora de %d a %d." % [label, record.confidence, MemoryRecord.MIN_CONFIDENCE, MemoryRecord.MAX_CONFIDENCE])
	if record.actors.size() > MemoryRecord.MAX_ACTORS:
		problems.append("%s com %d pessoas; o máximo é %d." % [label, record.actors.size(), MemoryRecord.MAX_ACTORS])
	for actor_id: int in record.actors:
		if actor_id < IdGenerator.FIRST_ID or actor_id > IdGenerator.MAX_ID or actor_id == npc_id:
			problems.append("%s com pessoa %d inválida." % [label, actor_id])
	return problems


func _weakest_index(now: int, rules: Rules) -> int:
	var weakest: int = 0
	var weakest_value: int = value_of(records[0], now, rules)
	for index: int in range(1, records.size()):
		var value: int = value_of(records[index], now, rules)
		if value < weakest_value or (value == weakest_value and records[index].time < records[weakest].time):
			weakest = index
			weakest_value = value
	return weakest


## Tira o registro da lista; se a saliência passa do limiar, a valência dele vira traço de cada pessoa envolvida.
func _forget(index: int, now: int, rules: Rules) -> void:
	var gone: MemoryRecord = records[index]
	records.remove_at(index)
	if gone.salience > rules.trait_threshold:
		for actor_id: int in gone.actors:
			_add_to_trait(actor_id, gone.valence, now, rules)


## Soma a valência ao traço da pessoa (limitada a -100..100) ou cria o traço. Sem vaga, o novo só entra no lugar do traço mais fraco (menor
## módulo; empate: o mais antigo) se tiver módulo MAIOR; senão some. Nunca passa de `trait_slots` traços.
func _add_to_trait(actor_id: int, valence: int, now: int, rules: Rules) -> void:
	for existing: Trait in traits:
		if existing.actor_id == actor_id:
			existing.valence = clampi(existing.valence + valence, MemoryRecord.MIN_VALENCE, MemoryRecord.MAX_VALENCE)
			return
	if rules.trait_slots <= 0:
		return
	var created: Trait = Trait.new(actor_id, clampi(valence, MemoryRecord.MIN_VALENCE, MemoryRecord.MAX_VALENCE), now)
	if traits.size() < rules.trait_slots:
		traits.append(created)
		return
	var weakest: int = _weakest_trait_index()
	if absi(created.valence) > absi(traits[weakest].valence):
		traits[weakest] = created


func _weakest_trait_index() -> int:
	var weakest: int = 0
	for index: int in range(1, traits.size()):
		var current: Trait = traits[index]
		var chosen: Trait = traits[weakest]
		if absi(current.valence) < absi(chosen.valence) or (absi(current.valence) == absi(chosen.valence) and current.since < chosen.since):
			weakest = index
	return weakest


## Traço do save, ou nulo com o motivo em `problem[0]`.
static func _parse_trait(raw_entry: Variant, problem: Array[String]) -> Trait:
	if typeof(raw_entry) != TYPE_DICTIONARY:
		problem.append("o traço não é um objeto (veio %s)" % type_string(typeof(raw_entry)))
		return null
	var entry: Dictionary = raw_entry
	for key: String in [KEY_ACTOR_ID, KEY_VALENCE, KEY_SINCE]:
		if not MemoryRecord.is_int_like(entry.get(key)):
			problem.append(MemoryRecord.bad_field(entry, key, "inteiro"))
			return null
	return Trait.new(int(entry[KEY_ACTOR_ID]), int(entry[KEY_VALENCE]), int(entry[KEY_SINCE]))


## As regras da memória, já tiradas dos parâmetros e dos tipos de episódio (conteúdo de `data/`, nada é salvo).
class Rules:
	extends RefCounted

	## Quantos registros cabem por NPC.
	var capacity: int
	## Saliência ACIMA da qual o registro vira traço antes de sair.
	var trait_threshold: int
	## Quantos traços permanentes cabem por NPC.
	var trait_slots: int
	## Desgaste de saliência por dia, de cada tipo de episódio.
	var decay_per_day: Dictionary[String, int]

	func _init(rule_capacity: int, rule_trait_threshold: int, rule_trait_slots: int, rule_decay_per_day: Dictionary[String, int]) -> void:
		capacity = rule_capacity
		trait_threshold = rule_trait_threshold
		trait_slots = rule_trait_slots
		decay_per_day = rule_decay_per_day


## Traço permanente: o que o NPC pensa de UMA pessoa (valência de -100 a 100), guardado para sempre e fora da capacidade de registros.
class Trait:
	extends RefCounted

	var actor_id: int
	var valence: int
	## Minuto em que o traço nasceu.
	var since: int

	func _init(trait_actor_id: int, trait_valence: int, trait_since: int) -> void:
		actor_id = trait_actor_id
		valence = trait_valence
		since = trait_since

	func to_dict() -> Dictionary:
		return {KEY_ACTOR_ID: actor_id, KEY_VALENCE: valence, KEY_SINCE: since}

	func duplicate_trait() -> Trait:
		return Trait.new(actor_id, valence, since)


## Resultado de `parse`: `memory` só vale se `error` estiver vazio.
class ParseResult:
	extends RefCounted

	var memory: NpcMemory
	var error: String

	func _init(parsed_memory: NpcMemory, parse_error: String) -> void:
		memory = parsed_memory
		error = parse_error


## Resultado de `parse_table`: `table` só vale se `error` estiver vazio.
class TableResult:
	extends RefCounted

	var table: Dictionary[int, NpcMemory]
	var error: String

	func _init(parsed_table: Dictionary[int, NpcMemory], parse_error: String) -> void:
		table = parsed_table
		error = parse_error
