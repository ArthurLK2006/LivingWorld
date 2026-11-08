class_name RoutineTable
extends RefCounted
## Ofícios e agenda por hora do dia (LW-061; contrato em docs/modules/npc.md, seção 4). É CONTEÚDO lido de data/occupations.json e
## data/routine_blocks.json (somente leitura depois de montado; não é salvo nem entra no state_hash). Cada ofício tem uma lista de
## blocos [de, até) que cobre as 24 horas (o RoutineLoader garante); a tabela expande isso em uma ação por hora para a consulta ser
## direta. A rotina diz só O QUÊ fazer em cada hora; o local vem do estado do NPC ou do PlaceChooser.

const CODE_UNKNOWN_OCCUPATION: String = "NPC_OCCUPATION_UNKNOWN"
const CODE_INVALID_HOUR: String = "NPC_INVALID_HOUR"
## Hora sem ação na agenda: só acontece em tabela montada à mão sem o RoutineLoader (os dados carregados cobrem as 24 horas).
const CODE_ROUTINE_GAP: String = "NPC_ROUTINE_GAP"
const HOURS_PER_DAY: int = SimClock.HOURS_PER_DAY

var _occupations: Dictionary[String, OccupationDef] = {}
## Ids dos ofícios na ordem do arquivo.
var _occupation_ids: Array[String] = []
## Ofício -> a ação de cada hora (24 textos; vazio = hora sem ação).
var _action_by_hour: Dictionary[String, Array] = {}


func _init(occupations: Array[OccupationDef], blocks: Array[RoutineBlock]) -> void:
	for occupation: OccupationDef in occupations:
		if _occupations.has(occupation.id):
			continue
		_occupations[occupation.id] = occupation
		_occupation_ids.append(occupation.id)
		var hours: Array = []
		hours.resize(HOURS_PER_DAY)
		hours.fill("")
		_action_by_hour[occupation.id] = hours
	for block: RoutineBlock in blocks:
		if not _action_by_hour.has(block.occupation_id):
			continue
		var hours_of_occupation: Array = _action_by_hour[block.occupation_id]
		for hour: int in range(maxi(block.from_hour, 0), mini(block.to_hour, HOURS_PER_DAY)):
			hours_of_occupation[hour] = block.action_id


func has_occupation(occupation_id: String) -> bool:
	return _occupations.has(occupation_id)


## Ids dos ofícios, na ordem do arquivo (cópia).
func peek_occupation_ids() -> Array[String]:
	var ids: Array[String] = []
	ids.assign(_occupation_ids)
	return ids


## Tipo de local onde o ofício trabalha ("" se o ofício não existe).
func peek_work_place_kind(occupation_id: String) -> String:
	if not _occupations.has(occupation_id):
		return ""
	return _occupations[occupation_id].work_place_kind


## A ação da rotina do ofício na hora (0 a 23, a de SimClock.hour_of_day()). Ofício desconhecido, hora fora de 0 a 23 ou hora sem ação
## devolvem falha tratada.
func peek_action(occupation_id: String, hour: int) -> RoutineQuery:
	if not _occupations.has(occupation_id):
		return RoutineQuery.new(Result.failure(CODE_UNKNOWN_OCCUPATION, "RoutineTable.peek_action: o ofício '%s' não existe; esperado um de: %s." % [occupation_id, ", ".join(_occupation_ids)]), "")
	if hour < 0 or hour >= HOURS_PER_DAY:
		return RoutineQuery.new(Result.failure(CODE_INVALID_HOUR, "RoutineTable.peek_action: hora %d fora de 0 a %d." % [hour, HOURS_PER_DAY - 1]), "")
	var action_id: String = _action_by_hour[occupation_id][hour]
	if action_id.is_empty():
		return RoutineQuery.new(Result.failure(CODE_ROUTINE_GAP, "RoutineTable.peek_action: o ofício '%s' não tem ação na hora %d." % [occupation_id, hour]), "")
	return RoutineQuery.new(Result.success(), action_id)


## Ofício (data/occupations.json): `work_place_kind` é o tipo de local de trabalho (um do vocabulário de `Place.KINDS`).
class OccupationDef:
	extends RefCounted

	var id: String
	var work_place_kind: String

	func _init(occupation_id: String, occupation_work_place_kind: String) -> void:
		id = occupation_id
		work_place_kind = occupation_work_place_kind


## Bloco da agenda (data/routine_blocks.json): do `from_hour` (0 a 23) até `to_hour` (1 a 24, exclusivo) o ofício faz `action_id`.
class RoutineBlock:
	extends RefCounted

	var id: String
	var occupation_id: String
	var from_hour: int
	var to_hour: int
	var action_id: String

	func _init(block_id: String, block_occupation_id: String, block_from_hour: int, block_to_hour: int, block_action_id: String) -> void:
		id = block_id
		occupation_id = block_occupation_id
		from_hour = block_from_hour
		to_hour = block_to_hour
		action_id = block_action_id


## Resposta de `peek_action`: `result.ok` diz se deu certo; só então `action_id` vale.
class RoutineQuery:
	extends RefCounted

	var result: Result
	var action_id: String

	func _init(query_result: Result, found_action_id: String) -> void:
		result = query_result
		action_id = found_action_id
