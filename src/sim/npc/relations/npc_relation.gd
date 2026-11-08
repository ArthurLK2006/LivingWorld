class_name NpcRelation
extends RefCounted
## Uma relação entre duas pessoas (LW-079; docs/modules/npc.md, seção 7): cinco dimensões inteiras de -100 a +100 (afeição, confiança,
## respeito, medo, dívida). Existe UMA relação por par, e o par não tem ordem: `a_id` é sempre o menor ID, então perguntar (a, b) ou (b, a)
## dá a mesma relação. Existir já quer dizer "se conheceram" (`met_at`). O DECAIMENTO diário rumo a 0 é preguiçoso e exato: `values` vale
## no dia `updated_day`; o valor de outro dia é calculado na hora (cada dimensão perde `decay_per_day` pontos por dia, sem passar de 0),
## então o resultado é o mesmo qualquer que seja a frequência com que alguém olha a relação.

const DIM_AFFECTION: int = 0
const DIM_TRUST: int = 1
const DIM_RESPECT: int = 2
const DIM_FEAR: int = 3
const DIM_DEBT: int = 4
const DIM_COUNT: int = 5
const DIM_IDS: Array[String] = ["affection", "trust", "respect", "fear", "debt"]
const MIN_VALUE: int = -100
const MAX_VALUE: int = 100
## Rótulos derivados da afeição pelos limiares dos parâmetros; família e empregador esperam os sistemas deles.
const LABEL_ACQUAINTANCE: String = "acquaintance"
const LABEL_FRIEND: String = "friend"
const LABEL_RIVAL: String = "rival"
## Ao rebaixar o NPC, a relação dele com o jogador é guardada com cada dimensão arredondada para um múltiplo disto [HIP].
const PLAYER_ROUNDING: int = 10
const KEY_A_ID: String = "a_id"
const KEY_B_ID: String = "b_id"
const KEY_VALUES: String = "values"
const KEY_MET_AT: String = "met_at"
const KEY_UPDATED_DAY: String = "updated_day"

## O menor ID do par.
var a_id: int = 0
## O maior ID do par.
var b_id: int = 0
## As cinco dimensões no dia `updated_day`, na ordem de DIM_IDS.
var values: PackedInt64Array = PackedInt64Array()
## Minuto em que se conheceram.
var met_at: int = 0
## Dia (número do dia de simulação) em que `values` foi acertado pela última vez.
var updated_day: int = 0


func _init(first_id: int = 0, second_id: int = 0) -> void:
	a_id = mini(first_id, second_id)
	b_id = maxi(first_id, second_id)
	values.resize(DIM_COUNT)


## Chave do par, a mesma para (x, y) e (y, x).
static func make_key(first_id: int, second_id: int) -> String:
	return "%d:%d" % [mini(first_id, second_id), maxi(first_id, second_id)]


## O valor depois de `days` dias de decaimento: rumo a 0 sem passar dele. `days` negativo conta como 0.
static func decayed(value: int, days: int, decay_per_day: int) -> int:
	var step: int = maxi(days, 0) * decay_per_day
	if value > 0:
		return maxi(value - step, 0)
	if value < 0:
		return mini(value + step, 0)
	return 0


## Múltiplo de `multiple` mais próximo de `value` (metade arredonda para longe de 0).
static func rounded(value: int, multiple: int) -> int:
	var magnitude: int = IntMath.floor_div(absi(value) + IntMath.floor_div(multiple, 2), multiple) * multiple
	return magnitude if value >= 0 else -magnitude


func key() -> String:
	return make_key(a_id, b_id)


func involves(npc_id: int) -> bool:
	return a_id == npc_id or b_id == npc_id


func other_id(npc_id: int) -> int:
	return b_id if npc_id == a_id else a_id


## As dimensões em `today` (cópia; não muda a relação).
func values_at(today: int, decay_per_day: int) -> PackedInt64Array:
	var days: int = today - updated_day
	var at_day: PackedInt64Array = PackedInt64Array()
	at_day.resize(DIM_COUNT)
	for index: int in DIM_COUNT:
		at_day[index] = decayed(values[index], days, decay_per_day)
	return at_day


## Acerta `values` para `today` (aplica o decaimento que faltava). Dia que não avançou não faz nada.
func settle(today: int, decay_per_day: int) -> void:
	if today <= updated_day:
		return
	values = values_at(today, decay_per_day)
	updated_day = today


## Soma dos módulos das cinco dimensões em `today`: o quanto a relação pesa (a mais fraca é a primeira a sair quando o NPC enche).
func strength_at(today: int, decay_per_day: int) -> int:
	var total: int = 0
	for value: int in values_at(today, decay_per_day):
		total += absi(value)
	return total


## Soma `deltas` (uma por dimensão), cada dimensão limitada a -100..100.
func add(deltas: PackedInt64Array) -> void:
	for index: int in DIM_COUNT:
		values[index] = clampi(values[index] + deltas[index], MIN_VALUE, MAX_VALUE)


func duplicate_relation() -> NpcRelation:
	var copy: NpcRelation = NpcRelation.new(a_id, b_id)
	copy.values = values.duplicate()
	copy.met_at = met_at
	copy.updated_day = updated_day
	return copy


func to_dict() -> Dictionary:
	var saved_values: Array = []
	for value: int in values:
		saved_values.append(value)
	return {KEY_A_ID: a_id, KEY_B_ID: b_id, KEY_VALUES: saved_values, KEY_MET_AT: met_at, KEY_UPDATED_DAY: updated_day}


## Lê uma relação do save. Só confere formato e tipos; faixas e coerência são do `validate()` do módulo.
static func parse(raw_entry: Variant) -> ParseResult:
	if typeof(raw_entry) != TYPE_DICTIONARY:
		return ParseResult.new(null, "a relação não é um objeto (veio %s)" % type_string(typeof(raw_entry)))
	var entry: Dictionary = raw_entry
	for key_name: String in [KEY_A_ID, KEY_B_ID, KEY_MET_AT, KEY_UPDATED_DAY]:
		if not MemoryRecord.is_int_like(entry.get(key_name)):
			return ParseResult.new(null, MemoryRecord.bad_field(entry, key_name, "inteiro"))
	if typeof(entry.get(KEY_VALUES)) != TYPE_ARRAY:
		return ParseResult.new(null, MemoryRecord.bad_field(entry, KEY_VALUES, "lista de %d inteiros" % DIM_COUNT))
	var raw_values: Array = entry[KEY_VALUES]
	if raw_values.size() != DIM_COUNT:
		return ParseResult.new(null, MemoryRecord.bad_field(entry, KEY_VALUES, "lista de %d inteiros" % DIM_COUNT))
	var relation: NpcRelation = NpcRelation.new(int(entry[KEY_A_ID]), int(entry[KEY_B_ID]))
	for index: int in DIM_COUNT:
		if not MemoryRecord.is_int_like(raw_values[index]):
			return ParseResult.new(null, MemoryRecord.bad_field(entry, KEY_VALUES, "lista de %d inteiros" % DIM_COUNT))
		relation.values[index] = int(raw_values[index])
	relation.met_at = int(entry[KEY_MET_AT])
	relation.updated_day = int(entry[KEY_UPDATED_DAY])
	if int(entry[KEY_A_ID]) > int(entry[KEY_B_ID]):
		return ParseResult.new(null, "par fora de ordem: a_id %d maior que b_id %d (o par guarda o menor ID primeiro)" % [int(entry[KEY_A_ID]), int(entry[KEY_B_ID])])
	return ParseResult.new(relation, "")


## Resultado de `parse`: `relation` só vale se `error` estiver vazio.
class ParseResult:
	extends RefCounted

	var relation: NpcRelation
	var error: String

	func _init(parsed_relation: NpcRelation, parse_error: String) -> void:
		relation = parsed_relation
		error = parse_error
