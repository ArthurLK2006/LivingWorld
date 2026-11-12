extends GutTest
## LW-061: escolha de local (docs/modules/npc.md, seção 4) e ocupação derivada, sem janela. Mundo de teste montado à mão, com distâncias
## calculadas na mão: o local mais PRÓXIMO COM VAGA do mesmo assentamento, desempate pelo menor id; a vaga é a capacidade do `world` menos
## quem está lá (NPC vivo); o próprio NPC não enche o local onde já está; só consulta, nada é gravado.

const VILLAGE_A: String = "village_a"
const VILLAGE_B: String = "village_b"
const WORLD_DIR: String = "res://data/world"

var _states: Dictionary[int, NpcState] = {}
var _next_npc_id: int = 100


func before_each() -> void:
	_states = {}
	_next_npc_id = 100


func _world() -> SettlementService:
	var settlements: Array[Settlement] = [
		Settlement.new(VILLAGE_A, "settlement.a", Vector3(0.0, 0.0, 0.0)),
		Settlement.new(VILLAGE_B, "settlement.b", Vector3(500.0, 0.0, 0.0)),
	]
	var places: Array[Place] = [
		Place.new("home_a1", VILLAGE_A, Place.KIND_HOME, Vector3(10.0, 0.0, 0.0), 2),
		Place.new("work_a1", VILLAGE_A, Place.KIND_WORK, Vector3(30.0, 0.0, 0.0), 3),
		Place.new("rest_a1", VILLAGE_A, Place.KIND_REST, Vector3(100.0, 0.0, 0.0), 1),
		Place.new("rest_a3", VILLAGE_A, Place.KIND_REST, Vector3(50.0, 0.0, 0.0), 2),
		Place.new("rest_a2", VILLAGE_A, Place.KIND_REST, Vector3(50.0, 0.0, 0.0), 2),
		Place.new("social_a1", VILLAGE_A, Place.KIND_SOCIAL, Vector3(0.0, 0.0, 200.0), 2),
		Place.new("social_a2", VILLAGE_A, Place.KIND_SOCIAL, Vector3(0.0, 0.0, 300.0), 1),
		Place.new("market_a1", VILLAGE_A, Place.KIND_MARKET, Vector3(5.0, 0.0, 5.0), 4),
		Place.new("rest_b1", VILLAGE_B, Place.KIND_REST, Vector3(5.0, 0.0, 0.0), 3),
	]
	return SettlementService.new(settlements, places)


func _chooser() -> PlaceChooser:
	return PlaceChooser.new(_world(), PlaceOccupancy.new(_states))


## NPC em (x, z) metros; `place_id` vazio = fora de qualquer local.
func _npc(x_m: float, z_m: float, place_id: String = "", settlement_id: String = VILLAGE_A, is_alive: bool = true) -> NpcState:
	var state: NpcState = NpcState.new(_next_npc_id)
	_next_npc_id += 1
	state.x_cm = roundi(x_m * 100.0)
	state.z_cm = roundi(z_m * 100.0)
	state.place_id = place_id
	state.settlement_id = settlement_id
	state.is_alive = is_alive
	_states[state.npc_id] = state
	return state


func _fill(place_id: String, how_many: int) -> void:
	for _index: int in how_many:
		_npc(0.0, 0.0, place_id)


func _action(place_kind: String) -> ActionDef:
	return ActionDef.new("test_action", 10, place_kind, 0, true)


func _pick(state: NpcState, kind: String) -> String:
	var chosen: PlaceChooser.ChosenPlace = _chooser().nearest_with_room(state, kind)
	assert_true(chosen.result.ok, chosen.result.message)
	return chosen.place_id


# ---------------------------------------------------------------------------------------------------- ocupação derivada

func test_occupancy_counts_living_npcs_by_place_and_ignores_the_dead_and_those_in_transit() -> void:
	_fill("rest_a2", 2)
	_fill("rest_a3", 1)
	_npc(0.0, 0.0, "rest_a1", VILLAGE_A, false)
	_npc(0.0, 0.0, "")
	var occupancy: PlaceOccupancy = PlaceOccupancy.new(_states)
	assert_eq(occupancy.counts(), {"rest_a2": 2, "rest_a3": 1})
	assert_eq(occupancy.count_at("rest_a2"), 2)
	assert_eq(occupancy.count_at("rest_a1"), 0, "O morto não ocupa lugar.")
	assert_eq(occupancy.count_at("nowhere"), 0)


func test_occupancy_is_derived_so_it_follows_the_npc_state_with_no_state_of_its_own() -> void:
	var walker: NpcState = _npc(0.0, 0.0, "rest_a2")
	var occupancy: PlaceOccupancy = PlaceOccupancy.new(_states)
	assert_eq(occupancy.count_at("rest_a2"), 1)
	walker.place_id = "rest_a3"
	assert_eq(occupancy.count_at("rest_a2"), 0)
	assert_eq(occupancy.count_at("rest_a3"), 1, "Mudou o `place_id` do NPC, mudou a ocupação.")
	walker.is_alive = false
	assert_eq(occupancy.counts().size(), 0)
	_states.erase(walker.npc_id)
	assert_eq(occupancy.counts().size(), 0, "Sem NPC não há ocupação.")


# ---------------------------------------------------------------------------------------------------- o mais próximo com vaga

func test_the_nearest_place_wins_and_a_tie_goes_to_the_smaller_id() -> void:
	var walker: NpcState = _npc(0.0, 0.0)
	assert_eq(_pick(walker, "rest"), "rest_a2", "rest_a2 e rest_a3 estão a 50 m; rest_a1 a 100 m; o empate vai para o menor id.")
	var near_far_one: NpcState = _npc(95.0, 0.0)
	assert_eq(_pick(near_far_one, "rest"), "rest_a1", "De 95 m, o de 100 m é o mais próximo (5 m contra 45 m).")
	var diagonal: NpcState = _npc(50.0, 30.0)
	assert_eq(_pick(diagonal, "rest"), "rest_a2", "Distância na diagonal: 30 m até o de 50 m, 58 m até o de 100 m.")


func test_social_places_follow_the_same_rule() -> void:
	var walker: NpcState = _npc(0.0, 0.0)
	assert_eq(_pick(walker, "social"), "social_a1", "200 m contra 300 m.")
	_fill("social_a1", 2)
	assert_eq(_pick(walker, "social"), "social_a2", "O mais próximo está cheio: vai para o seguinte.")


func test_full_places_are_skipped_and_the_capacity_boundary_is_exact() -> void:
	var walker: NpcState = _npc(0.0, 0.0)
	_fill("rest_a2", 1)
	assert_eq(_pick(walker, "rest"), "rest_a2", "1 de 2 vagas ocupadas: ainda há vaga.")
	_fill("rest_a2", 1)
	assert_eq(_pick(walker, "rest"), "rest_a3", "2 de 2: cheio, vai para o empatado seguinte.")
	_fill("rest_a3", 2)
	assert_eq(_pick(walker, "rest"), "rest_a1", "Os dois de 50 m estão cheios: sobra o de 100 m.")
	_fill("rest_a1", 1)
	var none: PlaceChooser.ChosenPlace = _chooser().nearest_with_room(walker, "rest")
	assert_false(none.result.ok)
	assert_eq(none.result.code, PlaceChooser.CODE_NO_ROOM)
	assert_string_contains(none.result.message, "rest")
	assert_string_contains(none.result.message, VILLAGE_A)
	assert_eq(none.place_id, "")


func test_the_npc_already_in_a_place_does_not_fill_it_for_himself() -> void:
	var resident: NpcState = _npc(100.0, 0.0, "rest_a1")
	assert_eq(_pick(resident, "rest"), "rest_a1", "A capacidade é 1 e só ele está lá: o local continua disponível para ele.")
	var visitor: NpcState = _npc(100.0, 0.0)
	assert_eq(_pick(visitor, "rest"), "rest_a2", "Para outro NPC o local de 1 vaga já está cheio.")


func test_a_dead_npc_does_not_occupy_a_place() -> void:
	_npc(100.0, 0.0, "rest_a1", VILLAGE_A, false)
	var visitor: NpcState = _npc(100.0, 0.0)
	assert_eq(_pick(visitor, "rest"), "rest_a1")


func test_only_places_of_the_npc_settlement_count() -> void:
	var walker: NpcState = _npc(5.0, 0.0)
	assert_eq(_pick(walker, "rest"), "rest_a2", "O `rest_b1` está a 0 m, mas é do outro assentamento.")
	var in_b: NpcState = _npc(5.0, 0.0, "", VILLAGE_B)
	assert_eq(_pick(in_b, "rest"), "rest_b1")


func test_choosing_is_read_only_and_repeatable() -> void:
	var walker: NpcState = _npc(0.0, 0.0)
	_fill("rest_a2", 1)
	var before: Array = []
	for npc_id: int in _states:
		before.append([npc_id, _states[npc_id].to_dict()])
	var first: String = _pick(walker, "rest")
	var second: String = _pick(walker, "rest")
	assert_eq(first, second)
	var after: Array = []
	for npc_id: int in _states:
		after.append([npc_id, _states[npc_id].to_dict()])
	assert_eq(after, before, "Escolher o local não altera nenhum estado.")


func test_unknown_settlement_and_invalid_kind_return_the_world_failure() -> void:
	var lost: NpcState = _npc(0.0, 0.0, "", "nowhere")
	var unknown: PlaceChooser.ChosenPlace = _chooser().nearest_with_room(lost, "rest")
	assert_false(unknown.result.ok)
	assert_eq(unknown.result.code, SettlementService.CODE_SETTLEMENT_UNKNOWN)
	var walker: NpcState = _npc(0.0, 0.0)
	var bad_kind: PlaceChooser.ChosenPlace = _chooser().nearest_with_room(walker, "kitchen")
	assert_eq(bad_kind.result.code, SettlementService.CODE_PLACE_KIND_INVALID)


# ---------------------------------------------------------------------------------------------------- o local de cada ação

func test_place_for_maps_each_place_kind_to_its_source() -> void:
	var worker: NpcState = _npc(0.0, 0.0, "work_a1")
	worker.home_place_id = "home_a1"
	worker.work_place_id = "work_a1"
	var chooser: PlaceChooser = _chooser()
	assert_eq(chooser.place_for(worker, _action("home")).place_id, "home_a1", "Casa vem do estado.")
	assert_eq(chooser.place_for(worker, _action("work")).place_id, "work_a1", "Trabalho vem do estado.")
	assert_eq(chooser.place_for(worker, _action("rest")).place_id, "rest_a2", "Descanso é o mais próximo com vaga.")
	assert_eq(chooser.place_for(worker, _action("social")).place_id, "social_a1")
	var anywhere: PlaceChooser.ChosenPlace = chooser.place_for(worker, _action(""))
	assert_true(anywhere.result.ok)
	assert_eq(anywhere.place_id, "work_a1", "Ação sem tipo de local vale onde o NPC está.")


func test_place_for_fails_without_an_assignment_or_for_the_reserved_kind() -> void:
	var homeless: NpcState = _npc(0.0, 0.0)
	var chooser: PlaceChooser = _chooser()
	var no_home: PlaceChooser.ChosenPlace = chooser.place_for(homeless, _action("home"))
	assert_false(no_home.result.ok)
	assert_eq(no_home.result.code, PlaceChooser.CODE_NO_ASSIGNED_PLACE)
	assert_string_contains(no_home.result.message, "casa")
	assert_eq(chooser.place_for(homeless, _action("work")).result.code, PlaceChooser.CODE_NO_ASSIGNED_PLACE)
	var market: PlaceChooser.ChosenPlace = chooser.place_for(homeless, _action("market"))
	assert_true(market.result.ok, market.result.message)
	assert_eq(market.place_id, "market_a1", "O tipo `market` (LW-093) é escolhido como o descanso: o local mais próximo do assentamento com vaga.")
	assert_eq(chooser.place_for(homeless, _action("kitchen")).result.code, PlaceChooser.CODE_KIND_UNSUPPORTED)


# ---------------------------------------------------------------------------------------------------- dados reais

func test_with_the_real_settlements_the_choice_is_a_real_place_of_the_same_settlement() -> void:
	var terrain: TerrainLoader.LoadResult = TerrainLoader.load_dir(WORLD_DIR)
	assert_true(terrain.result.ok, terrain.result.message)
	var loaded: SettlementLoader.LoadResult = SettlementLoader.load_dir(WORLD_DIR, terrain.terrain)
	assert_true(loaded.result.ok, loaded.result.message)
	var service: SettlementService = SettlementService.new(loaded.settlements, loaded.places)
	var chooser: PlaceChooser = PlaceChooser.new(service, PlaceOccupancy.new(_states))
	for settlement: Settlement in loaded.settlements:
		var walker: NpcState = _npc(settlement.position.x, settlement.position.z, "", settlement.id)
		for kind: String in ["rest", "social"]:
			var chosen: PlaceChooser.ChosenPlace = chooser.nearest_with_room(walker, kind)
			assert_true(chosen.result.ok, "%s em %s: %s" % [kind, settlement.id, chosen.result.message])
			var place: Place = service.peek_place(chosen.place_id).place
			assert_eq(place.settlement_id, settlement.id)
			assert_eq(place.kind, kind)
