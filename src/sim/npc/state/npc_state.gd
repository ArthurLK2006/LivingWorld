class_name NpcState
extends RefCounted
## Estado compacto de UM NPC (LW-057; contrato em docs/modules/npc.md, seção 1). Só dados, nada de cena. Quem guarda, cria, remove e
## valida é o NpcModule, único dono (AGENTS 5.2). Ofício, casa, local de trabalho, locais e ação são ids de CONTEÚDO em texto
## ("" = nenhum): a conferência de que existem é de cada tarefa que cria o dado (LW-056, LW-059, LW-061). Traços e necessidades
## ficam em posição fixa (`order` dos dados); o tamanho vem das constantes abaixo. Tempo em minutos de simulação; posição em cm.

## Quantidade de necessidades e de traços: tamanho dos vetores do estado. Os dados (needs.json e traits.json) precisam ter uma
## linha por posição; mudar estes números é mudar o formato do save.
const NEED_COUNT: int = 5
const TRAIT_COUNT: int = 4
## Faixa de necessidades e de traços (inteiros); 50 é o traço neutro.
const VALUE_MIN: int = 0
const VALUE_MAX: int = 100
const NEUTRAL_TRAIT: int = 50
## Tiers do protótipo (DEC-041: só T1 e T2).
const TIER_NORMAL: int = 1
const TIER_NOTABLE: int = 2
## `died_at` de quem está vivo.
const NO_TIME: int = -1
## Faixa de segurança [HIP] das coordenadas (100 km), a mesma dos outros arquivos de posição; o limite verdadeiro é o mapa.
const MAX_COORDINATE_CM: int = 10000000
const MAX_SAFE_INTEGER: int = 9007199254740991

const KEY_NAME_KEY: String = "name_key"
const KEY_NAME_NUMBER: String = "name_number"
const KEY_TIER: String = "tier"
const KEY_IS_ALIVE: String = "is_alive"
const KEY_DEATH_CAUSE: String = "death_cause"
const KEY_DIED_AT: String = "died_at"
const KEY_TRAITS: String = "traits"
const KEY_NEED_VALUES: String = "need_values"
const KEY_NEED_REMAINDERS: String = "need_remainders"
const KEY_NEEDS_UPDATED_AT: String = "needs_updated_at"
const KEY_X_CM: String = "x_cm"
const KEY_Z_CM: String = "z_cm"
const KEY_SETTLEMENT_ID: String = "settlement_id"
const KEY_PLACE_ID: String = "place_id"
const KEY_OCCUPATION_ID: String = "occupation_id"
const KEY_HOME_PLACE_ID: String = "home_place_id"
const KEY_WORK_PLACE_ID: String = "work_place_id"
const KEY_ACTION_ID: String = "action_id"
const KEY_ACTION_TARGET_PLACE_ID: String = "action_target_place_id"
const KEY_ACTION_STARTED_AT: String = "action_started_at"
const KEY_ACTION_ENDS_AT: String = "action_ends_at"
const KEY_ACTION_SERIAL: String = "action_serial"
const KEY_NEXT_THINK_TIME: String = "next_think_time"
const KEY_CRITICAL_SINCE: String = "critical_since"
## Campos do save por tipo, para conferir tudo antes de montar o estado.
const INT_KEYS: Array[String] = [KEY_NAME_NUMBER, KEY_TIER, KEY_DIED_AT, KEY_NEEDS_UPDATED_AT, KEY_X_CM, KEY_Z_CM, KEY_ACTION_STARTED_AT, KEY_ACTION_ENDS_AT, KEY_ACTION_SERIAL]
const STRING_KEYS: Array[String] = [KEY_NAME_KEY, KEY_DEATH_CAUSE, KEY_SETTLEMENT_ID, KEY_PLACE_ID, KEY_OCCUPATION_ID, KEY_HOME_PLACE_ID, KEY_WORK_PLACE_ID, KEY_ACTION_ID, KEY_ACTION_TARGET_PLACE_ID]

# Identidade
var npc_id: int
## Só a CHAVE do nome: a apresentação monta o texto ("Aldeão 001"); a simulação nunca guarda texto de tela.
var name_key: String = ""
var name_number: int = 0
var tier: int = TIER_NORMAL
var is_alive: bool = true
## Id da necessidade que matou ("" enquanto vivo) e minuto da morte (NO_TIME enquanto vivo).
var death_cause: String = ""
var died_at: int = NO_TIME
# Personalidade: um valor de 0 a 100 por traço (posição = `order` de traits.json), fixo desde a criação.
var traits: PackedInt64Array = PackedInt64Array()
# Necessidades: valor de 0 a 100 e resto da última atualização, por posição; minuto da última atualização.
var need_values: PackedInt64Array = PackedInt64Array()
var need_remainders: PackedInt64Array = PackedInt64Array()
var needs_updated_at: int = 0
# Posição lógica: `place_id` vazio = em trânsito ou fora de qualquer local.
var x_cm: int = 0
var z_cm: int = 0
var settlement_id: String = ""
var place_id: String = ""
# Ofício e locais
var occupation_id: String = ""
var home_place_id: String = ""
var work_place_id: String = ""
# Ação atual: `action_id` vazio = nenhuma; `action_serial` conta as ações do NPC.
var action_id: String = ""
var action_target_place_id: String = ""
var action_started_at: int = 0
var action_ends_at: int = 0
var action_serial: int = 0
# Pensamento (LW-063): minuto de simulação em que o NPC pensa de novo; a fila de pensamento só processa quem chegou nesse minuto.
var next_think_time: int = 0
# Necessidade crítica (LW-081): minuto em que o NPC foi visto pela primeira vez com uma necessidade LETAL em nível crítico (NO_TIME se nenhuma).
var critical_since: int = NO_TIME


func _init(new_npc_id: int) -> void:
	npc_id = new_npc_id
	traits = neutral_traits()
	need_values.resize(NEED_COUNT)
	need_remainders.resize(NEED_COUNT)


## Traços todos neutros (50), no tamanho do estado.
static func neutral_traits() -> PackedInt64Array:
	var neutral: PackedInt64Array = PackedInt64Array()
	neutral.resize(TRAIT_COUNT)
	neutral.fill(NEUTRAL_TRAIT)
	return neutral


## Estado de um NPC novo a partir do pedido já conferido pelo módulo. `start_needs` (um valor por necessidade) vira o valor inicial.
static func from_spec(new_npc_id: int, spec: NpcSpec, now_minutes: int, start_needs: PackedInt64Array) -> NpcState:
	var state: NpcState = NpcState.new(new_npc_id)
	state.name_key = spec.name_key
	state.name_number = spec.name_number
	state.tier = spec.tier
	state.traits = spec.traits.duplicate()
	state.need_values = start_needs.duplicate()
	state.needs_updated_at = now_minutes
	state.x_cm = spec.x_cm
	state.z_cm = spec.z_cm
	state.settlement_id = spec.settlement_id
	state.place_id = spec.place_id
	state.occupation_id = spec.occupation_id
	state.home_place_id = spec.home_place_id
	state.work_place_id = spec.work_place_id
	return state


## Dados simples para o save (números, texto, listas): o ID do NPC é a chave de quem guarda, não entra aqui.
func to_dict() -> Dictionary:
	return {
		KEY_NAME_KEY: name_key, KEY_NAME_NUMBER: name_number, KEY_TIER: tier,
		KEY_IS_ALIVE: is_alive, KEY_DEATH_CAUSE: death_cause, KEY_DIED_AT: died_at,
		KEY_TRAITS: _to_array(traits), KEY_NEED_VALUES: _to_array(need_values),
		KEY_NEED_REMAINDERS: _to_array(need_remainders), KEY_NEEDS_UPDATED_AT: needs_updated_at,
		KEY_X_CM: x_cm, KEY_Z_CM: z_cm, KEY_SETTLEMENT_ID: settlement_id, KEY_PLACE_ID: place_id,
		KEY_OCCUPATION_ID: occupation_id, KEY_HOME_PLACE_ID: home_place_id, KEY_WORK_PLACE_ID: work_place_id,
		KEY_ACTION_ID: action_id, KEY_ACTION_TARGET_PLACE_ID: action_target_place_id,
		KEY_ACTION_STARTED_AT: action_started_at, KEY_ACTION_ENDS_AT: action_ends_at, KEY_ACTION_SERIAL: action_serial,
		KEY_NEXT_THINK_TIME: next_think_time,
		KEY_CRITICAL_SINCE: critical_since,
	}


## Estado a partir de um registro salvo. Só recusa o que não dá para converter (campo ausente, tipo errado, número com fração,
## lista de tamanho errado); faixas e coerência (necessidade fora de 0 a 100, tier, morto com ação) são apontadas por validate()
## do módulo, como no `character`. `raw_entry` é Variant porque vem cru do JSON.
static func parse(saved_npc_id: int, raw_entry: Variant) -> ParseResult:
	if typeof(raw_entry) != TYPE_DICTIONARY:
		return ParseResult.new(null, "esperado um objeto (veio %s)" % type_string(typeof(raw_entry)))
	var entry: Dictionary = raw_entry
	for key: String in INT_KEYS:
		if not _is_int_like(entry.get(key)):
			return ParseResult.new(null, _bad_field(entry, key, "inteiro"))
	for key: String in STRING_KEYS:
		if typeof(entry.get(key)) != TYPE_STRING:
			return ParseResult.new(null, _bad_field(entry, key, "texto"))
	if typeof(entry.get(KEY_IS_ALIVE)) != TYPE_BOOL:
		return ParseResult.new(null, _bad_field(entry, KEY_IS_ALIVE, "verdadeiro ou falso"))
	for list_key: String in [KEY_TRAITS, KEY_NEED_VALUES, KEY_NEED_REMAINDERS]:
		var expected_size: int = TRAIT_COUNT if list_key == KEY_TRAITS else NEED_COUNT
		if not _is_int_list(entry.get(list_key), expected_size):
			return ParseResult.new(null, _bad_field(entry, list_key, "lista de %d inteiros" % expected_size))
	var state: NpcState = NpcState.new(saved_npc_id)
	state.name_key = entry[KEY_NAME_KEY]
	state.name_number = int(entry[KEY_NAME_NUMBER])
	state.tier = int(entry[KEY_TIER])
	state.is_alive = entry[KEY_IS_ALIVE]
	state.death_cause = entry[KEY_DEATH_CAUSE]
	state.died_at = int(entry[KEY_DIED_AT])
	state.traits = _to_packed(entry[KEY_TRAITS])
	state.need_values = _to_packed(entry[KEY_NEED_VALUES])
	state.need_remainders = _to_packed(entry[KEY_NEED_REMAINDERS])
	state.needs_updated_at = int(entry[KEY_NEEDS_UPDATED_AT])
	state.x_cm = int(entry[KEY_X_CM])
	state.z_cm = int(entry[KEY_Z_CM])
	state.settlement_id = entry[KEY_SETTLEMENT_ID]
	state.place_id = entry[KEY_PLACE_ID]
	state.occupation_id = entry[KEY_OCCUPATION_ID]
	state.home_place_id = entry[KEY_HOME_PLACE_ID]
	state.work_place_id = entry[KEY_WORK_PLACE_ID]
	state.action_id = entry[KEY_ACTION_ID]
	state.action_target_place_id = entry[KEY_ACTION_TARGET_PLACE_ID]
	state.action_started_at = int(entry[KEY_ACTION_STARTED_AT])
	state.action_ends_at = int(entry[KEY_ACTION_ENDS_AT])
	state.action_serial = int(entry[KEY_ACTION_SERIAL])
	# Campo acrescentado depois do primeiro formato (LW-063): ausente no save = 0, isto é, pensa no primeiro passo.
	if entry.has(KEY_NEXT_THINK_TIME):
		if not _is_int_like(entry[KEY_NEXT_THINK_TIME]):
			return ParseResult.new(null, _bad_field(entry, KEY_NEXT_THINK_TIME, "inteiro"))
		state.next_think_time = int(entry[KEY_NEXT_THINK_TIME])
	# Campo acrescentado na LW-081: ausente no save = NO_TIME (nenhuma necessidade letal crítica).
	if entry.has(KEY_CRITICAL_SINCE):
		if not _is_int_like(entry[KEY_CRITICAL_SINCE]):
			return ParseResult.new(null, _bad_field(entry, KEY_CRITICAL_SINCE, "inteiro"))
		state.critical_since = int(entry[KEY_CRITICAL_SINCE])
	return ParseResult.new(state, "")


## O JSON devolve todo número como decimal: vale inteiro, ou decimal sem fração dentro da faixa exata. `raw_value` é Variant (cru).
static func _is_int_like(raw_value: Variant) -> bool:
	if typeof(raw_value) == TYPE_INT:
		return true
	if typeof(raw_value) != TYPE_FLOAT:
		return false
	var number: float = raw_value
	return is_finite(number) and number == floorf(number) and absf(number) <= float(MAX_SAFE_INTEGER)


static func _is_int_list(raw_value: Variant, expected_size: int) -> bool:
	if typeof(raw_value) != TYPE_ARRAY:
		return false
	var items: Array = raw_value
	if items.size() != expected_size:
		return false
	for item: Variant in items:
		if not _is_int_like(item):
			return false
	return true


## Lista já conferida por _is_int_list.
static func _to_packed(raw_list: Array) -> PackedInt64Array:
	var packed: PackedInt64Array = PackedInt64Array()
	packed.resize(raw_list.size())
	for index: int in raw_list.size():
		packed[index] = int(raw_list[index])
	return packed


static func _to_array(packed: PackedInt64Array) -> Array:
	var items: Array = []
	for value: int in packed:
		items.append(value)
	return items


static func _bad_field(entry: Dictionary, key: String, expected: String) -> String:
	if not entry.has(key):
		return "campo '%s' ausente; esperado %s" % [key, expected]
	return "campo '%s' inválido: esperado %s, veio %s (%s)" % [key, expected, type_string(typeof(entry[key])), str(entry[key])]


## Resultado de `parse`: `state` só vale se `error` estiver vazio.
class ParseResult:
	extends RefCounted

	var state: NpcState
	var error: String

	func _init(parsed_state: NpcState, parse_error: String) -> void:
		state = parsed_state
		error = parse_error
