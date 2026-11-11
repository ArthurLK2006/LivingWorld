extends GutTest
## LW-056: assentamentos e locais (conteúdo de data/world/settlements.json e places.json) e as consultas do `world`, sem janela.
## Aqui: arquivos inválidos (cada um falha apontando arquivo, item e campo), consultas (cópias, ordem crescente, falhas tratadas) e a ida
## e volta de save. Os dados reais (contagens, chão plano, textos) ficam em tests/unit/test_settlements_data.gd. Os valores esperados
## estão ESCRITOS À MÃO a partir do contrato (docs/modules/world.md, seção "Extensão da Fase 2").

const BLOCKOUT_DIR: String = "res://data/world"
const MISSING_DIR: String = "res://tests/fixtures/world/pasta_que_nao_existe"
const WORLD_SEED: int = 5
const GAME_VERSION: String = "0.0.1-test"
const STEPS_BEFORE_SAVE: int = 90
const SETTLEMENT_A: String = "test_settlement_a"
const SETTLEMENT_B: String = "test_settlement_b"
## O blockout tem 1.024 m (102.400 cm): exatamente na borda ainda é dentro; 1 cm além, não.
const MAP_EDGE_CM: int = 102400
const SETTLEMENT_RADIUS_CM: int = 15000
## Assentamento e local mínimos e corretos; os casos inválidos trocam um pedaço deles.
const TOWN: String = '{"id": "town", "name_key": "settlement.town", "x_cm": 32000, "z_cm": 54000}'
const HOME: String = '{"id": "town_home", "settlement_id": "town", "kind": "home", "x_cm": 32500, "z_cm": 54500, "capacity": 5}'

var _terrain: TerrainData
var _loaded: SettlementLoader.LoadResult
var _service: SettlementService
var _codec: JsonSaveCodec = JsonSaveCodec.new()
var _temp_dirs: Array[DirAccess] = []


func before_all() -> void:
	var terrain_loaded: TerrainLoader.LoadResult = TerrainLoader.load_dir(BLOCKOUT_DIR)
	assert_true(terrain_loaded.result.ok, terrain_loaded.result.message)
	_terrain = terrain_loaded.terrain
	_loaded = SettlementLoader.load_dir(BLOCKOUT_DIR, _terrain)
	assert_true(_loaded.result.ok, _loaded.result.message)
	_service = SettlementService.new(_loaded.settlements, _loaded.places)


func after_each() -> void:
	for dir: DirAccess in _temp_dirs:
		for file_name: String in dir.get_files():
			dir.remove(file_name)
		DirAccess.remove_absolute(dir.get_current_dir())
	_temp_dirs.clear()


func _dir_with(settlements_text: String, places_text: String) -> String:
	var dir: DirAccess = DirAccess.create_temp("lw056")
	_temp_dirs.append(dir)
	for entry: Array in [[SettlementLoader.DEFAULT_SETTLEMENTS_FILE, settlements_text], [SettlementLoader.DEFAULT_PLACES_FILE, places_text]]:
		var file: FileAccess = FileAccess.open(dir.get_current_dir().path_join(entry[0]), FileAccess.WRITE)
		file.store_string(entry[1])
		file.close()
	return dir.get_current_dir()


func _assert_invalid(settlements_text: String, places_text: String, expected_parts: Array[String]) -> void:
	var loaded: SettlementLoader.LoadResult = SettlementLoader.load_dir(_dir_with(settlements_text, places_text), _terrain)
	assert_false(loaded.result.ok, "Arquivo inválido deveria falhar: " + places_text)
	assert_eq(loaded.result.code, SettlementLoader.CODE_INVALID)
	assert_eq(loaded.settlements.size() + loaded.places.size(), 0, "Falha não devolve assentamento nem local.")
	for part: String in expected_parts:
		assert_string_contains(loaded.result.message, part)


func _assert_valid(settlements_text: String, places_text: String) -> void:
	var loaded: SettlementLoader.LoadResult = SettlementLoader.load_dir(_dir_with(settlements_text, places_text), _terrain)
	assert_true(loaded.result.ok, "Deveria valer: %s -> %s" % [places_text, loaded.result.message])


func _assert_ascending(ids: Array[String]) -> void:
	for index: int in range(1, ids.size()):
		assert_lt(ids[index - 1], ids[index], "Os ids saem em ordem crescente.")


## Ids dos locais do assentamento, calculados pelo teste (filtro e ordenação próprios), para conferir contra a consulta.
func _expected_place_ids(settlement_id: String) -> Array[String]:
	var ids: Array[String] = []
	for place: Place in _loaded.places:
		if place.settlement_id == settlement_id:
			ids.append(place.id)
	ids.sort()
	return ids


# ---------------------------------------------------------------- arquivo inválido

func test_a_missing_field_is_reported_with_file_item_and_field() -> void:
	_assert_invalid("[%s]" % TOWN, "[%s]" % HOME.replace(', "capacity": 5', ""), ["places.json", "town_home", "capacity", "campo obrigatório ausente"])
	_assert_invalid("[%s]" % TOWN.replace(', "name_key": "settlement.town"', ""), "[%s]" % HOME, ["settlements.json", "town", "name_key", "campo obrigatório ausente"])


func test_an_unknown_field_is_reported() -> void:
	_assert_invalid("[%s]" % TOWN, "[%s]" % HOME.replace('"capacity": 5', '"capacity": 5, "color": "red"'), ["places.json", "town_home", "color", "campo desconhecido"])


func test_a_repeated_id_is_reported_for_places_and_for_settlements() -> void:
	_assert_invalid("[%s]" % TOWN, "[%s, %s]" % [HOME, HOME], ["places.json", "town_home", "id", "duplicado"])
	_assert_invalid("[%s, %s]" % [TOWN, TOWN], "[%s]" % HOME, ["settlements.json", "town", "id", "duplicado"])


func test_a_broken_reference_is_reported_with_file_item_and_field() -> void:
	_assert_invalid("[%s]" % TOWN, "[%s]" % HOME.replace('"settlement_id": "town"', '"settlement_id": "nowhere"'), ["places.json", "town_home", "settlement_id", "referência a id inexistente 'nowhere'"])


func test_a_place_outside_the_map_is_reported_and_the_edge_itself_is_inside() -> void:
	var edge_town: String = TOWN.replace("32000", str(MAP_EDGE_CM - 1000))
	var edge_home: String = HOME.replace("32500", str(MAP_EDGE_CM))
	_assert_valid("[%s]" % edge_town, "[%s]" % edge_home)
	_assert_invalid("[%s]" % edge_town, "[%s]" % HOME.replace("32500", str(MAP_EDGE_CM + 1)), ["places.json", "town_home", "x_cm", "fora do mapa"])
	_assert_invalid("[%s]" % TOWN, "[%s]" % HOME.replace("54500", str(MAP_EDGE_CM + 1)), ["places.json", "town_home", "fora do mapa"])


func test_a_settlement_outside_the_map_is_reported() -> void:
	_assert_invalid("[%s]" % TOWN.replace("54000", str(MAP_EDGE_CM + 1)), "[%s]" % HOME, ["settlements.json", "town", "x_cm", "fora do mapa"])


func test_a_wrong_type_is_reported() -> void:
	_assert_invalid("[%s]" % TOWN, "[%s]" % HOME.replace("32500", "12.5"), ["places.json", "town_home", "x_cm", "tipo inválido"])
	_assert_invalid("[%s]" % TOWN, "[%s]" % HOME.replace('"capacity": 5', '"capacity": "cinco"'), ["places.json", "town_home", "capacity", "tipo inválido"])
	_assert_invalid("[%s]" % TOWN.replace('"settlement.town"', "7"), "[%s]" % HOME, ["settlements.json", "town", "name_key", "tipo inválido"])


func test_an_invalid_capacity_is_reported_and_the_edges_of_the_range_are_valid() -> void:
	_assert_invalid("[%s]" % TOWN, "[%s]" % HOME.replace('"capacity": 5', '"capacity": 0'), ["places.json", "town_home", "capacity", "abaixo do mínimo"])
	_assert_invalid("[%s]" % TOWN, "[%s]" % HOME.replace('"capacity": 5', '"capacity": 65'), ["places.json", "town_home", "capacity", "acima do máximo"])
	_assert_valid("[%s]" % TOWN, "[%s]" % HOME.replace('"capacity": 5', '"capacity": 1'))
	_assert_valid("[%s]" % TOWN, "[%s]" % HOME.replace('"capacity": 5', '"capacity": 64'))


func test_a_kind_outside_the_vocabulary_is_reported_and_market_reserved_is_accepted() -> void:
	for wrong: String in ["Home", "farm", ""]:
		_assert_invalid("[%s]" % TOWN, "[%s]" % HOME.replace('"kind": "home"', '"kind": "%s"' % wrong), ["places.json", "town_home", "kind", "fora do vocabulário", "market_reserved"])
	for valid_kind: String in Place.KINDS:
		_assert_valid("[%s]" % TOWN, "[%s]" % HOME.replace('"kind": "home"', '"kind": "%s"' % valid_kind))


func test_a_settlement_without_any_place_is_reported() -> void:
	_assert_invalid("[%s, %s]" % [TOWN, TOWN.replace('"town"', '"empty_town"')], "[%s]" % HOME, ["settlements.json", "empty_town", "sem nenhum local"])


func test_a_place_too_far_from_its_settlement_center_is_reported_and_exactly_the_limit_is_valid() -> void:
	_assert_valid("[%s]" % TOWN, "[%s]" % HOME.replace("32500", str(32000 + SETTLEMENT_RADIUS_CM)).replace("54500", "54000"))
	_assert_invalid("[%s]" % TOWN, "[%s]" % HOME.replace("32500", str(32000 + SETTLEMENT_RADIUS_CM + 1)).replace("54500", "54000"), ["places.json", "town_home", "x_cm", "acima do limite", "town"])


func test_an_empty_name_key_is_reported() -> void:
	_assert_invalid("[%s]" % TOWN.replace('"settlement.town"', '"  "'), "[%s]" % HOME, ["settlements.json", "town", "name_key", "vazia"])


func test_malformed_json_and_missing_files_are_reported() -> void:
	_assert_invalid("[{", "[%s]" % HOME, ["settlements.json", "JSON inválido"])
	_assert_invalid("[%s]" % TOWN, "not json", ["places.json", "JSON inválido"])
	var missing: SettlementLoader.LoadResult = SettlementLoader.load_dir(MISSING_DIR, _terrain)
	assert_false(missing.result.ok)
	assert_string_contains(missing.result.message, "settlements.json")
	assert_string_contains(missing.result.message, "places.json")
	assert_string_contains(missing.result.message, "arquivo não encontrado")


func test_a_null_terrain_is_refused_without_crashing() -> void:
	var refused: SettlementLoader.LoadResult = SettlementLoader.load_dir(BLOCKOUT_DIR, null)
	assert_false(refused.result.ok)
	assert_string_contains(refused.result.message, "terreno nulo")
	assert_eq(refused.places.size(), 0)


func test_loading_twice_gives_the_same_settlements_and_places() -> void:
	var again: SettlementLoader.LoadResult = SettlementLoader.load_dir(BLOCKOUT_DIR, _terrain)
	assert_true(again.result.ok, again.result.message)
	assert_eq(again.settlements.size(), _loaded.settlements.size())
	assert_eq(again.places.size(), _loaded.places.size())
	for index: int in _loaded.settlements.size():
		assert_eq([again.settlements[index].id, again.settlements[index].name_key, again.settlements[index].position], [_loaded.settlements[index].id, _loaded.settlements[index].name_key, _loaded.settlements[index].position])
	for index: int in _loaded.places.size():
		var before: Place = _loaded.places[index]
		assert_eq([again.places[index].id, again.places[index].settlement_id, again.places[index].kind, again.places[index].position, again.places[index].capacity], [before.id, before.settlement_id, before.kind, before.position, before.capacity])


# ---------------------------------------------------------------- consultas

func test_peek_settlement_returns_the_data_the_place_ids_in_ascending_order_and_a_copy() -> void:
	var query: SettlementService.SettlementQuery = _service.peek_settlement(SETTLEMENT_A)
	assert_true(query.result.ok, query.result.message)
	assert_eq(query.settlement.id, SETTLEMENT_A)
	assert_eq(query.settlement.name_key, "settlement.test_settlement_a.name")
	assert_eq(query.settlement.position, _loaded.settlements[0].position, "O centro é o do arquivo, com a altura do terreno.")
	assert_eq(query.place_ids, _expected_place_ids(SETTLEMENT_A))
	_assert_ascending(query.place_ids)
	query.settlement.name_key = "alterado"
	query.settlement.position = Vector3.ZERO
	query.place_ids.clear()
	var again: SettlementService.SettlementQuery = _service.peek_settlement(SETTLEMENT_A)
	assert_eq(again.settlement.name_key, "settlement.test_settlement_a.name", "Mexer na cópia não altera o conteúdo.")
	assert_ne(again.settlement.position, Vector3.ZERO)
	assert_gt(again.place_ids.size(), 0)


func test_peek_place_returns_the_data_as_a_copy() -> void:
	var original: Place = _loaded.places[0]
	var query: SettlementService.PlaceQuery = _service.peek_place(original.id)
	assert_true(query.result.ok, query.result.message)
	assert_eq([query.place.id, query.place.settlement_id, query.place.kind, query.place.position, query.place.capacity], [original.id, original.settlement_id, original.kind, original.position, original.capacity])
	query.place.capacity = 99
	query.place.kind = "alterado"
	var again: SettlementService.PlaceQuery = _service.peek_place(original.id)
	assert_eq(again.place.capacity, original.capacity, "Mexer na cópia não altera o conteúdo.")
	assert_eq(again.place.kind, original.kind)


func test_peek_places_of_kind_is_in_ascending_order_and_empty_for_a_kind_without_places() -> void:
	for kind: String in Place.KINDS:
		var query: SettlementService.PlacesQuery = _service.peek_places_of_kind(SETTLEMENT_A, kind)
		assert_true(query.result.ok, query.result.message)
		var ids: Array[String] = []
		for place: Place in query.places:
			assert_eq(place.kind, kind)
			assert_eq(place.settlement_id, SETTLEMENT_A)
			ids.append(place.id)
		_assert_ascending(ids)
	var only_homes: Place = Place.new("solo_home", "solo", Place.KIND_HOME, Vector3.ZERO, 3)
	var solo: SettlementService = SettlementService.new([Settlement.new("solo", "settlement.solo", Vector3.ZERO)], [only_homes])
	var none: SettlementService.PlacesQuery = solo.peek_places_of_kind("solo", Place.KIND_WORK)
	assert_true(none.result.ok, "Tipo válido sem locais não é erro.")
	assert_eq(none.places.size(), 0)
	assert_eq(solo.peek_places_of_kind("solo", Place.KIND_HOME).places.size(), 1)


func test_market_reserved_is_returned_like_any_other_kind() -> void:
	var query: SettlementService.PlacesQuery = _service.peek_places_of_kind(SETTLEMENT_B, Place.KIND_MARKET_RESERVED)
	assert_true(query.result.ok, query.result.message)
	assert_eq(query.places.size(), 1, "Cada assentamento de teste tem um local de mercado reservado.")


func test_the_answers_do_not_depend_on_the_order_the_content_was_given() -> void:
	var reversed_places: Array[Place] = []
	reversed_places.assign(_loaded.places)
	reversed_places.reverse()
	var reversed_settlements: Array[Settlement] = []
	reversed_settlements.assign(_loaded.settlements)
	reversed_settlements.reverse()
	var other: SettlementService = SettlementService.new(reversed_settlements, reversed_places)
	for settlement_id: String in [SETTLEMENT_A, SETTLEMENT_B]:
		assert_eq(other.peek_settlement(settlement_id).place_ids, _service.peek_settlement(settlement_id).place_ids)
		for kind: String in Place.KINDS:
			var ids_other: Array[String] = []
			var ids_here: Array[String] = []
			for place: Place in other.peek_places_of_kind(settlement_id, kind).places:
				ids_other.append(place.id)
			for place: Place in _service.peek_places_of_kind(settlement_id, kind).places:
				ids_here.append(place.id)
			assert_eq(ids_other, ids_here)


func test_an_unknown_settlement_an_unknown_place_and_an_invalid_kind_are_handled_errors() -> void:
	var unknown_settlement: SettlementService.SettlementQuery = _service.peek_settlement("no_such_town")
	assert_false(unknown_settlement.result.ok)
	assert_eq(unknown_settlement.result.code, SettlementService.CODE_SETTLEMENT_UNKNOWN)
	assert_string_contains(unknown_settlement.result.message, "no_such_town")
	assert_string_contains(unknown_settlement.result.message, SETTLEMENT_A, "A mensagem lista os assentamentos que existem.")
	assert_null(unknown_settlement.settlement)
	var unknown_place: SettlementService.PlaceQuery = _service.peek_place("no_such_place")
	assert_eq(unknown_place.result.code, SettlementService.CODE_PLACE_UNKNOWN)
	assert_string_contains(unknown_place.result.message, "no_such_place")
	assert_string_contains(unknown_place.result.message, "e mais", "Com muitos locais, a mensagem resume o resto.")
	assert_null(unknown_place.place)
	var in_unknown_settlement: SettlementService.PlacesQuery = _service.peek_places_of_kind("no_such_town", Place.KIND_HOME)
	assert_eq(in_unknown_settlement.result.code, SettlementService.CODE_SETTLEMENT_UNKNOWN)
	var invalid_kind: SettlementService.PlacesQuery = _service.peek_places_of_kind(SETTLEMENT_A, "farm")
	assert_false(invalid_kind.result.ok)
	assert_eq(invalid_kind.result.code, SettlementService.CODE_PLACE_KIND_INVALID)
	assert_string_contains(invalid_kind.result.message, "farm")
	assert_string_contains(invalid_kind.result.message, "market_reserved", "A mensagem lista o vocabulário.")
	assert_eq(invalid_kind.places.size(), 0)


func test_a_service_made_by_hand_with_inconsistent_content_reports_problems_and_survives() -> void:
	var settlement: Settlement = Settlement.new("town", "settlement.town", Vector3.ZERO)
	var home: Place = Place.new("town_home", "town", Place.KIND_HOME, Vector3.ZERO, 5)
	var twin: Place = Place.new("town_home", "town", Place.KIND_WORK, Vector3.ONE, 5)
	var orphan: Place = Place.new("orphan_home", "nowhere", Place.KIND_HOME, Vector3.ZERO, 5)
	var empty_town: Settlement = Settlement.new("empty_town", "settlement.empty", Vector3.ZERO)
	var service: SettlementService = SettlementService.new([settlement, settlement, empty_town], [home, twin, orphan])
	var problems: String = " | ".join(service.validate())
	assert_string_contains(problems, "assentamento 'town' repetido")
	assert_string_contains(problems, "local 'town_home' repetido")
	assert_string_contains(problems, "orphan_home")
	assert_string_contains(problems, "assentamento 'empty_town' sem nenhum local")
	assert_eq(service.peek_place("town_home").place.kind, Place.KIND_HOME, "Em caso de repetição vale o primeiro.")
	assert_eq(service.peek_place("orphan_home").result.code, SettlementService.CODE_PLACE_UNKNOWN)
	assert_eq(SettlementService.new(_loaded.settlements, _loaded.places).validate().size(), 0, "O conteúdo real não tem problema.")


# ---------------------------------------------------------------- save: o conteúdo não é salvo

func _new_game_runner() -> SimulationRunner:
	var runner: SimulationRunner = SimulationRunner.new(WORLD_SEED)
	var modules: GameModules = GameModules.register(runner, _terrain)
	assert_true(modules.result.ok, modules.result.message)
	return runner


## Todas as respostas das consultas, juntas num texto, para comparar dois serviços.
func _describe_all(service: SettlementService) -> String:
	var lines: PackedStringArray = PackedStringArray()
	for settlement_id: String in [SETTLEMENT_A, SETTLEMENT_B]:
		var settlement: SettlementService.SettlementQuery = service.peek_settlement(settlement_id)
		lines.append("%s %s %s %s" % [settlement.settlement.id, settlement.settlement.name_key, str(settlement.settlement.position), ",".join(settlement.place_ids)])
		for kind: String in Place.KINDS:
			for place: Place in service.peek_places_of_kind(settlement_id, kind).places:
				lines.append("%s %s %s %s %d" % [place.id, place.settlement_id, place.kind, str(place.position), place.capacity])
	return "\n".join(lines)


func test_the_content_is_not_saved_and_save_and_load_keep_the_hash_and_the_queries() -> void:
	var original: SimulationRunner = _new_game_runner()
	original.start_new_game()
	original.run_steps(STEPS_BEFORE_SAVE)
	var bare: SimulationRunner = SimulationRunner.new(WORLD_SEED)
	assert_true(GameModules.register(bare, _terrain).result.ok)
	bare.start_new_game()
	bare.run_steps(STEPS_BEFORE_SAVE)
	assert_eq(original.world.state_hash(), bare.world.state_hash(), "Assentamentos e locais são conteúdo: carregá-los não muda o hash.")
	var saved: Dictionary = original.capture_game()
	assert_eq(saved["world"]["modules"].keys(), [GameModules.CHARACTER_NAME, GameModules.ECONOMY_NAME, GameModules.NPC_NAME], "Nem os assentamentos nem os locais entram no save.")
	var decoded: DecodedSave = _codec.decode(_codec.encode(saved, GAME_VERSION))
	assert_true(decoded.result.ok, decoded.result.message)
	var restored: SimulationRunner = _new_game_runner()
	var loaded: Result = restored.load_game(decoded.payload)
	assert_true(loaded.ok, loaded.message)
	assert_eq(restored.world.state_hash(), original.world.state_hash(), "O mundo carregado tem o hash do salvamento.")
	var reloaded: SettlementLoader.LoadResult = SettlementLoader.load_dir(BLOCKOUT_DIR, _terrain)
	assert_true(reloaded.result.ok, reloaded.result.message)
	var service_after_load: SettlementService = SettlementService.new(reloaded.settlements, reloaded.places)
	assert_eq(_describe_all(service_after_load), _describe_all(_service), "Com os mesmos arquivos, o mundo carregado devolve as mesmas consultas.")
	assert_eq(restored.world.validate().size(), 0)
	original.finish()
	bare.finish()
	restored.finish()
