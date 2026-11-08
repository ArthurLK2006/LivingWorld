class_name PlaceChooser
extends RefCounted
## Escolha do LOCAL de uma ação (LW-061; contrato em docs/modules/npc.md, seção 4): a rotina diz o QUÊ, o local vem daqui. `home` e `work`
## vêm do estado do NPC (`home_place_id` e `work_place_id`); `rest` e `social` são o local mais PRÓXIMO COM VAGA do mesmo assentamento
## (`world.peek_places_of_kind`), desempate pelo menor id do local; ação sem tipo de local vale onde o NPC está. A vaga vem da capacidade
## do `world` menos a ocupação derivada (PlaceOccupancy); o próprio NPC, se já está no local, não o enche. Só consulta: não altera nada.

const CODE_NO_ROOM: String = "NPC_NO_PLACE_WITH_ROOM"
const CODE_NO_ASSIGNED_PLACE: String = "NPC_NO_ASSIGNED_PLACE"
const CODE_KIND_UNSUPPORTED: String = "NPC_PLACE_KIND_UNSUPPORTED"

var _places: SettlementService
var _occupancy: PlaceOccupancy


func _init(places: SettlementService, occupancy: PlaceOccupancy) -> void:
	_places = places
	_occupancy = occupancy


## O local onde `state` fará `action`. `place_id` vazio no resultado significa "onde o NPC está" (ação sem tipo de local).
func place_for(state: NpcState, action: ActionDef) -> ChosenPlace:
	match action.place_kind:
		"":
			return ChosenPlace.new(Result.success(), state.place_id)
		Place.KIND_HOME:
			return _assigned(state, state.home_place_id, "casa")
		Place.KIND_WORK:
			return _assigned(state, state.work_place_id, "local de trabalho")
		Place.KIND_REST, Place.KIND_SOCIAL:
			return nearest_with_room(state, action.place_kind)
	return ChosenPlace.new(Result.failure(CODE_KIND_UNSUPPORTED, "PlaceChooser.place_for: o tipo de local '%s' da ação '%s' não tem regra de escolha (o `market_reserved` é reservado)." % [action.place_kind, action.id]), "")


## O local de tipo `kind`, do assentamento do NPC, mais próximo (distância em linha reta) entre os que têm vaga; empate: menor id.
## Assentamento desconhecido ou tipo fora do vocabulário: a falha do `world`. Nenhum com vaga: NPC_NO_PLACE_WITH_ROOM.
func nearest_with_room(state: NpcState, kind: String) -> ChosenPlace:
	var found: SettlementService.PlacesQuery = _places.peek_places_of_kind(state.settlement_id, kind)
	if not found.result.ok:
		return ChosenPlace.new(found.result, "")
	var counts: Dictionary[String, int] = _occupancy.counts()
	var best_id: String = ""
	var best_distance: int = 0
	for place: Place in found.places:
		var present: int = int(counts.get(place.id, 0))
		if state.is_alive and state.place_id == place.id:
			present -= 1
		if present >= place.capacity:
			continue
		var distance: int = _squared_distance_cm(state, place)
		if best_id.is_empty() or distance < best_distance:
			best_id = place.id
			best_distance = distance
	if best_id.is_empty():
		return ChosenPlace.new(Result.failure(CODE_NO_ROOM, "PlaceChooser.nearest_with_room: nenhum local '%s' com vaga no assentamento '%s' (%d no total)." % [kind, state.settlement_id, found.places.size()]), "")
	return ChosenPlace.new(Result.success(), best_id)


func _assigned(state: NpcState, place_id: String, label: String) -> ChosenPlace:
	if place_id.is_empty():
		return ChosenPlace.new(Result.failure(CODE_NO_ASSIGNED_PLACE, "PlaceChooser.place_for: o NPC %d não tem %s atribuída(o)." % [state.npc_id, label]), "")
	return ChosenPlace.new(Result.success(), place_id)


## Quadrado da distância, em centímetros inteiros, entre a posição lógica do NPC e o local (sem raiz: só para comparar).
func _squared_distance_cm(state: NpcState, place: Place) -> int:
	var delta_x: int = roundi(place.position.x * TerrainData.CM_PER_METER) - state.x_cm
	var delta_z: int = roundi(place.position.z * TerrainData.CM_PER_METER) - state.z_cm
	return delta_x * delta_x + delta_z * delta_z


## Resposta da escolha: `place_id` só vale se `result.ok` (vazio = onde o NPC está).
class ChosenPlace:
	extends RefCounted

	var result: Result
	var place_id: String

	func _init(choice_result: Result, chosen_place_id: String) -> void:
		result = choice_result
		place_id = chosen_place_id
