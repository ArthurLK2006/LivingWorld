extends GutTest
## LW-093b (DEC-137; ressalva ao critério 8 de 2.F): um ofício novo acrescentado SÓ como dado, sem tocar código, passa na validação e é usado:
## o NPC com esse ofício nasce, recebe casa e local de trabalho, segue a agenda dele num dia de jogo e a consulta da rotina devolve a ação de
## cada hora. Um ofício inválido (campo ausente, tipo errado, referência quebrada, id repetido, agenda com lacuna) é recusado com arquivo,
## item e campo. Modelo: test_a_new_action_added_only_by_data_passes_validation. O ofício `tinker` e a agenda dele nascem AQUI, em memória
## (nada é gravado em data/ nem em tests/fixtures/). Os valores esperados da agenda são escritos à mão; as grandezas [HIP] dos dados reais
## (necessidades, pesos) não são fixadas: só se confere o que a agenda do ofício novo manda nas horas em que ela difere da inércia.

const DATA_DIR: String = "res://data"
const WORLD_DIR: String = "res://data/world"
const OCCUPATIONS_FILE: String = "occupations.json"
const BLOCKS_FILE: String = "routine_blocks.json"
const ISSUE_CODE: String = "ROUTINE_DATA_INVALID"
const NEW_OCCUPATION: String = "tinker"
const SETTLEMENT_A: String = "test_settlement_a"
const WORLD_SEED: int = 7
## Agenda do ofício novo (de, até, ação): cobre 0 a 24 e usa só ações que já existem no catálogo.
const NEW_AGENDA: Array = [[0, 5, "sleep"], [5, 6, "eat"], [6, 12, "work"], [12, 13, "eat"], [13, 19, "work"], [19, 20, "rest"], [20, 22, "talk"], [22, 24, "sleep"]]
## Horas (meia hora depois do início) em que o NPC novo mostra a agenda dele: dorme, já trabalha às 6, trabalha às 8, conversa às 21, dorme às 22.
const SAMPLED_HOURS: Dictionary = {3: "sleep", 6: "work", 8: "work", 21: "talk", 22: "sleep"}


# ---------------------------------------------------------------------------------------------------- montagem

func _tables() -> Dictionary[String, Array]:
	var bundle: DataBundle = DataLoader.load_all(DATA_DIR, RoutineLoader.build_schemas())
	assert_true(bundle.is_valid(), bundle.describe_issues())
	var copy: Dictionary[String, Array] = {}
	for table_id: String in bundle.tables:
		copy[table_id] = bundle.tables[table_id].duplicate(true)
	return copy


## As tabelas reais mais o ofício novo e a agenda dele (só dados).
func _tables_with_new_occupation(reverse_blocks: bool = false) -> Dictionary[String, Array]:
	var tables: Dictionary[String, Array] = _tables()
	tables["occupations"].append({"id": NEW_OCCUPATION, "work_place_kind": "work"})
	var rows: Array = []
	for entry: Array in NEW_AGENDA:
		rows.append({"id": "%s_%02d_%02d" % [NEW_OCCUPATION, entry[0], entry[1]], "occupation_id": NEW_OCCUPATION, "from_hour": entry[0], "to_hour": entry[1], "action_id": entry[2]})
	if reverse_blocks:
		rows.reverse()
	tables["routine_blocks"].append_array(rows)
	return tables


func _load(tables: Dictionary[String, Array]) -> RoutineLoader.LoadResult:
	return RoutineLoader.from_tables(tables, DATA_DIR)


func _expected_action(hour: int) -> String:
	for entry: Array in NEW_AGENDA:
		if hour >= entry[0] and hour < entry[1]:
			return entry[2]
	return ""


## `Variant` só na fronteira com o JSON: `parse_string` devolve qualquer tipo, e o tipo é conferido logo abaixo.
func _read_rows(path: String) -> Array:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	assert_eq(typeof(parsed), TYPE_ARRAY, "%s deve ser uma lista." % path)
	var rows: Array = parsed if typeof(parsed) == TYPE_ARRAY else []
	return rows


## Assentamentos e locais reais (altura 0: só x e z importam aqui), como em test_population.gd.
func _real_places() -> SettlementService:
	var settlements: Array[Settlement] = []
	for row: Variant in _read_rows(WORLD_DIR.path_join("settlements.json")):
		var record: Dictionary = row
		settlements.append(Settlement.new(str(record["id"]), str(record["name_key"]), Vector3(float(record["x_cm"]) / 100.0, 0.0, float(record["z_cm"]) / 100.0)))
	var places: Array[Place] = []
	for row: Variant in _read_rows(WORLD_DIR.path_join("places.json")):
		var record: Dictionary = row
		places.append(Place.new(str(record["id"]), str(record["settlement_id"]), str(record["kind"]), Vector3(float(record["x_cm"]) / 100.0, 0.0, float(record["z_cm"]) / 100.0), int(record["capacity"])))
	return SettlementService.new(settlements, places)


func _rows(tinkers: int, farmers: int) -> Array[PopulationPlan.PopulationRow]:
	return [PopulationPlan.PopulationRow.new(SETTLEMENT_A, NEW_OCCUPATION, tinkers), PopulationPlan.PopulationRow.new(SETTLEMENT_A, "farmer", farmers)]


## Joga um dia no mundo novo com o ofício novo na população e devolve o que importa para comparar.
func _run_day(world_seed: int) -> Dictionary:
	var loaded: RoutineLoader.LoadResult = _load(_tables_with_new_occupation())
	assert_true(loaded.result.ok, loaded.result.message)
	var places: SettlementService = _real_places()
	var setup: NpcSetup = NpcSetup.from_dir(DATA_DIR, places)
	assert_true(setup.result.ok, setup.result.message)
	setup.definitions.population = PopulationPlan.new(_rows(3, 2))
	var module: NpcModule = NpcModule.new(setup.need_defs, loaded.table, setup.definitions)
	var clock: SimClock = SimClock.new()
	var world: World = World.new(SimContext.new(clock, EventBus.new(clock), WorldRng.new(world_seed), IdGenerator.new()))
	assert_true(world.register_module("npc", module).ok)
	world.setup()
	world.post_setup()
	world.on_new_game(world_seed)
	var tinker_id: int = 0
	for npc_id: int in module.peek_npc_ids():
		if module.peek_npc(npc_id).occupation_id == NEW_OCCUPATION:
			tinker_id = npc_id
			break
	var actions: Array[String] = []
	for minute: int in SimClock.MINUTES_PER_DAY:
		world.context.clock.advance_step()
		world.tick(1)
		if minute % 60 == 30:
			actions.append(module.peek_npc(tinker_id).action_id)
	var tinker: NpcModule.NpcQuery = module.peek_npc(tinker_id)
	var work_place_ids: Array[String] = []
	for place: Place in places.peek_places_of_kind(SETTLEMENT_A, "work").places:
		work_place_ids.append(place.id)
	var result: Dictionary = {
		"actions": actions, "hash": world.state_hash(), "by_occupation": module.debug_summary()["by_occupation"], "tinker_work_place": tinker.work_place_id,
		"tinker_home": tinker.home_place_id, "work_places": work_place_ids, "problems": module.validate() + world.validate(), "alive": module.peek_counts()["alive"],
	}
	world.teardown()
	return result


# ---------------------------------------------------------------------------------------------------- o ofício novo, só por dados

func test_a_new_occupation_added_only_by_data_passes_validation_and_keeps_the_others() -> void:
	var real: RoutineLoader.LoadResult = _load(_tables())
	var loaded: RoutineLoader.LoadResult = _load(_tables_with_new_occupation())
	assert_true(loaded.result.ok, loaded.result.message)
	var ids: Array[String] = real.table.peek_occupation_ids()
	ids.append(NEW_OCCUPATION)
	assert_eq(loaded.table.peek_occupation_ids(), ids, "O ofício novo entra depois dos que já existiam.")
	assert_eq(loaded.table.peek_work_place_kind(NEW_OCCUPATION), "work")
	for hour: int in 24:
		var query: RoutineTable.RoutineQuery = loaded.table.peek_action(NEW_OCCUPATION, hour)
		assert_true(query.result.ok, query.result.message)
		assert_eq(query.action_id, _expected_action(hour), "Agenda do ofício novo na hora %d." % hour)
	for occupation_id: String in real.table.peek_occupation_ids():
		assert_eq(loaded.table.peek_work_place_kind(occupation_id), real.table.peek_work_place_kind(occupation_id), "%s: o local de trabalho não mudou." % occupation_id)
		for hour: int in 24:
			assert_eq(loaded.table.peek_action(occupation_id, hour).action_id, real.table.peek_action(occupation_id, hour).action_id, "%s, hora %d: a agenda dos ofícios que já existiam não mudou." % [occupation_id, hour])


func test_the_order_of_the_agenda_lines_does_not_matter() -> void:
	var ordered: RoutineLoader.LoadResult = _load(_tables_with_new_occupation())
	var reversed: RoutineLoader.LoadResult = _load(_tables_with_new_occupation(true))
	assert_true(reversed.result.ok, reversed.result.message)
	for hour: int in 24:
		assert_eq(reversed.table.peek_action(NEW_OCCUPATION, hour).action_id, ordered.table.peek_action(NEW_OCCUPATION, hour).action_id, "Hora %d." % hour)


func test_an_occupation_with_one_block_for_the_whole_day_is_the_smallest_valid_one() -> void:
	var tables: Dictionary[String, Array] = _tables()
	tables["occupations"].append({"id": "watcher", "work_place_kind": "rest"})
	tables["routine_blocks"].append({"id": "watcher_all_day", "occupation_id": "watcher", "from_hour": 0, "to_hour": 24, "action_id": "wait"})
	var loaded: RoutineLoader.LoadResult = _load(tables)
	assert_true(loaded.result.ok, loaded.result.message)
	assert_eq(loaded.table.peek_work_place_kind("watcher"), "rest")
	assert_eq([loaded.table.peek_action("watcher", 0).action_id, loaded.table.peek_action("watcher", 23).action_id], ["wait", "wait"])
	assert_eq(loaded.table.peek_action("watcher", 24).result.code, RoutineTable.CODE_INVALID_HOUR, "A hora 24 não existe: o dia vai de 0 a 23.")


func test_without_the_data_the_population_row_is_refused_and_with_it_the_npc_is_born() -> void:
	var places: SettlementService = _real_places()
	var plan: PopulationPlan = PopulationPlan.new(_rows(3, 2))
	var without: PopulationPlan.BuildResult = plan.build_specs(places, _load(_tables()).table, WorldRng.new(WORLD_SEED))
	assert_false(without.result.ok, "Sem o ofício nos dados, a linha da população é recusada.")
	assert_eq(without.result.code, PopulationPlan.CODE_INVALID_REFERENCE)
	assert_string_contains(without.result.message, "o ofício '%s' da linha de população não existe nos dados de ofícios" % NEW_OCCUPATION)
	var built: PopulationPlan.BuildResult = plan.build_specs(places, _load(_tables_with_new_occupation()).table, WorldRng.new(WORLD_SEED))
	assert_true(built.result.ok, built.result.message)
	assert_eq(built.specs.size(), 5)
	for spec: NpcSpec in built.specs:
		if spec.occupation_id == NEW_OCCUPATION:
			assert_true(spec.work_place_id.begins_with("a_work_"), "O ofício novo trabalha num local do tipo 'work': %s." % spec.work_place_id)


func test_an_npc_with_the_new_occupation_is_born_and_follows_its_own_agenda_for_a_day() -> void:
	var day: Dictionary = _run_day(WORLD_SEED)
	assert_eq(day["by_occupation"], {"farmer": 2, "tinker": 3}, "Os três do ofício novo e os dois lavradores nasceram.")
	assert_eq(day["alive"], 5)
	assert_eq(day["problems"], [] as Array[String], "O módulo e o mundo seguem válidos depois de um dia.")
	assert_true(day["work_places"].has(day["tinker_work_place"]), "O local de trabalho do ofício novo é um local do tipo 'work' do assentamento.")
	assert_true(str(day["tinker_home"]).begins_with("a_home_"))
	var actions: Array = day["actions"]
	assert_eq(actions.size(), 24)
	for hour: int in SAMPLED_HOURS:
		assert_eq(actions[hour], SAMPLED_HOURS[hour], "Hora %d: o NPC do ofício novo faz o que a agenda dele manda." % hour)
	# `actions` sai de um Dictionary (Variant); cada item é convertido para texto antes de conferir.
	for action_id: Variant in actions:
		assert_false(str(action_id).is_empty(), "Nenhuma hora fica sem ação.")


func test_the_same_seed_gives_the_same_day_and_another_seed_a_different_world() -> void:
	var first: Dictionary = _run_day(WORLD_SEED)
	var second: Dictionary = _run_day(WORLD_SEED)
	var other: Dictionary = _run_day(WORLD_SEED + 1)
	assert_eq(first["actions"], second["actions"], "Mesma semente, mesma sequência de ações.")
	assert_eq(first["hash"], second["hash"], "Mesma semente, mesmo hash do mundo.")
	assert_ne(first["hash"], other["hash"], "Outra semente, outro hash.")


# ---------------------------------------------------------------------------------------------------- ofício inválido

func _row(tables: Dictionary[String, Array], table_id: String, row_id: String) -> Dictionary:
	for record: Dictionary in tables[table_id]:
		if record["id"] == row_id:
			return record
	fail_test("A linha '%s' não existe em '%s'." % [row_id, table_id])
	return {}


func _expect_failure(label: String, tables: Dictionary[String, Array], fragments: Array[String]) -> void:
	var loaded: RoutineLoader.LoadResult = _load(tables)
	assert_false(loaded.result.ok, "%s: deveria falhar." % label)
	assert_eq(loaded.result.code, ISSUE_CODE, label)
	assert_null(loaded.table, "%s: falha não devolve tabela." % label)
	for fragment: String in fragments:
		assert_string_contains(loaded.result.message, fragment, "%s: a mensagem deveria citar '%s'." % [label, fragment])


func test_an_invalid_occupation_row_is_refused_pointing_at_file_item_and_field() -> void:
	var item: String = "item '%s'" % NEW_OCCUPATION
	var cases: Array[Dictionary] = [
		{"label": "work_place_kind ausente", "erase": "work_place_kind", "expect": [item, "campo 'work_place_kind'", "obrigatório ausente"]},
		{"label": "work_place_kind com tipo errado", "set": {"work_place_kind": 3}, "expect": [item, "campo 'work_place_kind'", "tipo inválido"]},
		{"label": "tipo de local inexistente", "set": {"work_place_kind": "kitchen"}, "expect": [item, "campo 'work_place_kind'", "tipo de local 'kitchen' inexistente", "home, work, rest, social, market"]},
		{"label": "campo desconhecido", "set": {"salary": 3}, "expect": [item, "campo 'salary'", "campo desconhecido"]},
		{"label": "id repetido", "set": {"id": "farmer"}, "expect": ["item 'farmer'", "campo 'id'", "id duplicado"]},
		{"label": "id fora do padrão", "set": {"id": "Tinker"}, "expect": ["item 'Tinker'", "campo 'id'", "snake_case"]},
	]
	for test_case: Dictionary in cases:
		var tables: Dictionary[String, Array] = _tables_with_new_occupation()
		var row: Dictionary = _row(tables, "occupations", NEW_OCCUPATION)
		if test_case.has("erase"):
			row.erase(test_case["erase"])
		else:
			row.merge(test_case["set"], true)
		var fragments: Array[String] = [OCCUPATIONS_FILE]
		fragments.append_array(test_case["expect"])
		_expect_failure(test_case["label"], tables, fragments)


func test_an_invalid_agenda_line_is_refused_pointing_at_file_item_and_field() -> void:
	var cases: Array[Dictionary] = [
		{"label": "ação inexistente", "set": {"action_id": "fly"}, "expect": ["item 'tinker_06_12'", "campo 'action_id'", "'fly' na tabela 'actions'"]},
		{"label": "ofício inexistente", "set": {"occupation_id": "ghost"}, "expect": ["item 'tinker_06_12'", "campo 'occupation_id'", "'ghost' na tabela 'occupations'"]},
		{"label": "hora final acima de 24", "set": {"to_hour": 25}, "expect": ["item 'tinker_06_12'", "campo 'to_hour'", "acima do máximo"]},
		{"label": "hora inicial como texto", "set": {"from_hour": "6"}, "expect": ["item 'tinker_06_12'", "campo 'from_hour'", "tipo inválido"]},
		{"label": "id de bloco repetido", "set": {"id": "tinker_00_05"}, "expect": ["item 'tinker_00_05'", "campo 'id'", "id duplicado"]},
		{"label": "fim antes do início", "set": {"from_hour": 12, "to_hour": 6}, "expect": ["item 'tinker_06_12'", "campo 'to_hour'", "a hora final 6 não é maior que a inicial 12"]},
		{"label": "campo obrigatório ausente", "erase": "action_id", "expect": ["item 'tinker_06_12'", "campo 'action_id'", "obrigatório ausente"]},
	]
	for test_case: Dictionary in cases:
		var tables: Dictionary[String, Array] = _tables_with_new_occupation()
		var row: Dictionary = _row(tables, "routine_blocks", "tinker_06_12")
		if test_case.has("erase"):
			row.erase(test_case["erase"])
		else:
			row.merge(test_case["set"], true)
		var fragments: Array[String] = [BLOCKS_FILE]
		fragments.append_array(test_case["expect"])
		_expect_failure(test_case["label"], tables, fragments)


func test_an_agenda_that_does_not_cover_the_whole_day_is_refused() -> void:
	var cases: Array[Dictionary] = [
		{"label": "lacuna", "remove": ["tinker_06_12"], "expect": ["campo 'from_hour'", "lacuna na agenda de 'tinker'", "o bloco 'tinker_05_06' termina na hora 6 e este começa na 12"]},
		{"label": "não começa em 0", "remove": ["tinker_00_05"], "expect": ["item 'tinker_05_06'", "a agenda de 'tinker' começa na hora 5; esperado 0"]},
		{"label": "não termina em 24", "remove": ["tinker_22_24"], "expect": ["item 'tinker_20_22'", "a agenda de 'tinker' termina na hora 22; esperado 24"]},
		{"label": "sem nenhuma linha de agenda", "remove": ["tinker_00_05", "tinker_05_06", "tinker_06_12", "tinker_12_13", "tinker_13_19", "tinker_19_20", "tinker_20_22", "tinker_22_24"], "expect": ["item 'tinker'", "o ofício não tem nenhuma linha de agenda"]},
	]
	for test_case: Dictionary in cases:
		var tables: Dictionary[String, Array] = _tables_with_new_occupation()
		var kept: Array = []
		for record: Dictionary in tables["routine_blocks"]:
			if not test_case["remove"].has(record["id"]):
				kept.append(record)
		tables["routine_blocks"] = kept
		var fragments: Array[String] = [BLOCKS_FILE]
		fragments.append_array(test_case["expect"])
		_expect_failure(test_case["label"], tables, fragments)
	var overlap: Dictionary[String, Array] = _tables_with_new_occupation()
	_row(overlap, "routine_blocks", "tinker_13_19")["from_hour"] = 12
	_expect_failure("sobreposição", overlap, [BLOCKS_FILE, "item 'tinker_13_19'", "campo 'from_hour'", "sobreposição na agenda de 'tinker'", "o bloco 'tinker_12_13' vai até a hora 13 e este começa na 12"])
