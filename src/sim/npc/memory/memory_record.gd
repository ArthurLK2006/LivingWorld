class_name MemoryRecord
extends RefCounted
## Um episódio guardado na memória de um NPC notável (T2) (LW-078; docs/modules/npc.md, seção 7). Dados simples e salvos. A importância de
## verdade do registro é o seu VALOR (`NpcMemory.value_of`): a saliência de partida menos o desgaste por dia do tipo, nunca abaixo de 0.
## Só existe a fonte `WITNESSED` (o NPC presenciou o episódio): rumor, que é de segunda mão, fica para outra fase.

const SOURCE_WITNESSED: String = "WITNESSED"
const MAX_ACTORS: int = 2
const MIN_VALENCE: int = -100
const MAX_VALENCE: int = 100
const MIN_SALIENCE: int = 0
const MAX_SALIENCE: int = 100
const MIN_CONFIDENCE: int = 0
const MAX_CONFIDENCE: int = 100
## Confiança de quem PRESENCIOU o episódio: a única fonte que existe nesta fase [HIP].
const WITNESSED_CONFIDENCE: int = 100
## Maior inteiro que um número do JSON (decimal de 64 bits) guarda sem perder precisão.
const MAX_SAFE_INTEGER: int = 9007199254740991
const KEY_KIND: String = "kind"
const KEY_ACTORS: String = "actors"
const KEY_PLACE_ID: String = "place_id"
const KEY_TIME: String = "time"
const KEY_VALENCE: String = "valence"
const KEY_SALIENCE: String = "salience"
const KEY_SOURCE: String = "source"
const KEY_CONFIDENCE: String = "confidence"
const INT_KEYS: Array[String] = [KEY_TIME, KEY_VALENCE, KEY_SALIENCE, KEY_CONFIDENCE]
const STRING_KEYS: Array[String] = [KEY_KIND, KEY_PLACE_ID, KEY_SOURCE]

## Tipo do episódio (id de data/memory_kinds.json).
var kind: String = ""
## IDs das pessoas envolvidas (até MAX_ACTORS), sem o dono da memória.
var actors: PackedInt64Array = PackedInt64Array()
var place_id: String = ""
## Minuto de simulação em que o NPC presenciou o episódio.
var time: int = 0
var valence: int = 0
var salience: int = 0
var source: String = SOURCE_WITNESSED
var confidence: int = WITNESSED_CONFIDENCE


func to_dict() -> Dictionary:
	var saved_actors: Array = []
	for actor_id: int in actors:
		saved_actors.append(actor_id)
	return {
		KEY_KIND: kind, KEY_ACTORS: saved_actors, KEY_PLACE_ID: place_id, KEY_TIME: time, KEY_VALENCE: valence, KEY_SALIENCE: salience,
		KEY_SOURCE: source, KEY_CONFIDENCE: confidence,
	}


## Uma cópia independente (as consultas devolvem cópias, nunca o registro guardado).
func duplicate_record() -> MemoryRecord:
	var copy: MemoryRecord = MemoryRecord.new()
	copy.kind = kind
	copy.actors = actors.duplicate()
	copy.place_id = place_id
	copy.time = time
	copy.valence = valence
	copy.salience = salience
	copy.source = source
	copy.confidence = confidence
	return copy


## Lê um registro do save. Só confere o que não dá para converter (formato e tipos); faixas e coerência são do `validate()` do módulo.
static func parse(raw_entry: Variant) -> ParseResult:
	if typeof(raw_entry) != TYPE_DICTIONARY:
		return ParseResult.new(null, "o registro não é um objeto (veio %s)" % type_string(typeof(raw_entry)))
	var entry: Dictionary = raw_entry
	for key: String in INT_KEYS:
		if not is_int_like(entry.get(key)):
			return ParseResult.new(null, bad_field(entry, key, "inteiro"))
	for key: String in STRING_KEYS:
		if typeof(entry.get(key)) != TYPE_STRING:
			return ParseResult.new(null, bad_field(entry, key, "texto"))
	if typeof(entry.get(KEY_ACTORS)) != TYPE_ARRAY:
		return ParseResult.new(null, bad_field(entry, KEY_ACTORS, "lista de inteiros"))
	var raw_actors: Array = entry[KEY_ACTORS]
	var parsed_actors: PackedInt64Array = PackedInt64Array()
	for item: Variant in raw_actors:
		if not is_int_like(item):
			return ParseResult.new(null, bad_field(entry, KEY_ACTORS, "lista de inteiros"))
		parsed_actors.append(int(item))
	var record: MemoryRecord = MemoryRecord.new()
	record.kind = entry[KEY_KIND]
	record.actors = parsed_actors
	record.place_id = entry[KEY_PLACE_ID]
	record.time = int(entry[KEY_TIME])
	record.valence = int(entry[KEY_VALENCE])
	record.salience = int(entry[KEY_SALIENCE])
	record.source = entry[KEY_SOURCE]
	record.confidence = int(entry[KEY_CONFIDENCE])
	return ParseResult.new(record, "")


## Inteiro, ou decimal sem parte fracionária (é assim que o JSON devolve os inteiros), dentro da faixa segura.
static func is_int_like(raw_value: Variant) -> bool:
	if typeof(raw_value) == TYPE_INT:
		return true
	if typeof(raw_value) != TYPE_FLOAT:
		return false
	var number: float = raw_value
	return is_finite(number) and number == floorf(number) and absf(number) <= float(MAX_SAFE_INTEGER)


## Mensagem de campo ausente ou do tipo errado, com o que era esperado.
static func bad_field(entry: Dictionary, key: String, expected: String) -> String:
	if not entry.has(key):
		return "campo '%s' ausente; esperado %s" % [key, expected]
	return "campo '%s' inválido: esperado %s, veio %s (%s)" % [key, expected, type_string(typeof(entry[key])), str(entry[key])]


## Resultado de `parse`: `record` só vale se `error` estiver vazio.
class ParseResult:
	extends RefCounted

	var record: MemoryRecord
	var error: String

	func _init(parsed_record: MemoryRecord, parse_error: String) -> void:
		record = parsed_record
		error = parse_error
