extends GutTest
## LW-061: ofícios e rotina por hora do dia (docs/modules/npc.md, seção 4), sem janela. A consulta é provada com uma agenda de teste montada
## à mão (valores esperados escritos à mão); os arquivos reais só têm as PROPRIEDADES conferidas (as horas da agenda são [HIP]); dado inválido
## falha apontando arquivo, item e campo, com tabelas em memória (nada é gravado em disco).

const DATA_DIR: String = "res://data"
const OCCUPATION_IDS: Array[String] = ["farmer", "lumberjack", "artisan", "guard", "innkeeper"]
const OCCUPATIONS_FILE: String = "occupations.json"
const BLOCKS_FILE: String = "routine_blocks.json"
const ISSUE_CODE: String = "ROUTINE_DATA_INVALID"
const WORLD_SEED: int = 3


func _occupation(occupation_id: String) -> RoutineTable.OccupationDef:
	return RoutineTable.OccupationDef.new(occupation_id, "work")


func _block(block_id: String, occupation_id: String, from_hour: int, to_hour: int, action_id: String) -> RoutineTable.RoutineBlock:
	return RoutineTable.RoutineBlock.new(block_id, occupation_id, from_hour, to_hour, action_id)


## Agenda de teste: dorme 0 a 6, trabalha 6 a 12, come 12 a 13, trabalha 13 a 22, dorme 22 a 24. Os blocos são LISTADOS FORA DE ORDEM
## de propósito (um arquivo válido pode listá-los assim): o resultado não pode depender da ordem da lista.
func _tester_table(ascending: bool = false) -> RoutineTable:
	var occupations: Array[RoutineTable.OccupationDef] = [_occupation("tester")]
	var blocks: Array[RoutineTable.RoutineBlock] = [
		_block("t4", "tester", 13, 22, "work"), _block("t1", "tester", 0, 6, "sleep"), _block("t5", "tester", 22, 24, "sleep"),
		_block("t3", "tester", 12, 13, "eat"), _block("t2", "tester", 6, 12, "work"),
	]
	if ascending:
		blocks.sort_custom(func(first: RoutineTable.RoutineBlock, second: RoutineTable.RoutineBlock) -> bool: return first.from_hour < second.from_hour)
	return RoutineTable.new(occupations, blocks)


func _tables() -> Dictionary[String, Array]:
	var bundle: DataBundle = DataLoader.load_all(DATA_DIR, RoutineLoader.build_schemas())
	assert_true(bundle.is_valid(), bundle.describe_issues())
	var copy: Dictionary[String, Array] = {}
	for table_id: String in bundle.tables:
		copy[table_id] = bundle.tables[table_id].duplicate(true)
	return copy


func _row(tables: Dictionary[String, Array], table_id: String, row_id: String) -> Dictionary:
	for record: Dictionary in tables[table_id]:
		if record["id"] == row_id:
			return record
	fail_test("A linha '%s' não existe em '%s'." % [row_id, table_id])
	return {}


func _remove_row(tables: Dictionary[String, Array], table_id: String, row_id: String) -> void:
	var kept: Array = []
	for record: Dictionary in tables[table_id]:
		if record["id"] != row_id:
			kept.append(record)
	tables[table_id] = kept


func _expect_failure(label: String, tables: Dictionary[String, Array], fragments: Array[String]) -> void:
	var loaded: RoutineLoader.LoadResult = RoutineLoader.from_tables(tables, DATA_DIR)
	assert_false(loaded.result.ok, "%s: deveria falhar." % label)
	assert_eq(loaded.result.code, ISSUE_CODE, label)
	assert_null(loaded.table, "%s: falha não devolve tabela." % label)
	for fragment: String in fragments:
		assert_string_contains(loaded.result.message, fragment, "%s: a mensagem deveria citar '%s'." % [label, fragment])


func _new_world(module: NpcModule) -> World:
	var clock: SimClock = SimClock.new()
	var world: World = World.new(SimContext.new(clock, EventBus.new(clock), WorldRng.new(WORLD_SEED), IdGenerator.new()))
	assert_true(world.register_module("npc", module).ok)
	world.setup()
	return world


# ---------------------------------------------------------------------------------------------------- consulta por ofício e hora

func test_the_query_returns_the_expected_action_for_every_hour() -> void:
	var table: RoutineTable = _tester_table()
	var expected: Array[String] = []
	expected.append_array(["sleep", "sleep", "sleep", "sleep", "sleep", "sleep"])
	expected.append_array(["work", "work", "work", "work", "work", "work"])
	expected.append("eat")
	expected.append_array(["work", "work", "work", "work", "work", "work", "work", "work", "work"])
	expected.append_array(["sleep", "sleep"])
	assert_eq(expected.size(), 24)
	for hour: int in 24:
		var query: RoutineTable.RoutineQuery = table.peek_action("tester", hour)
		assert_true(query.result.ok, query.result.message)
		assert_eq(query.action_id, expected[hour], "Hora %d." % hour)


func test_the_listing_order_of_the_blocks_does_not_change_the_answers() -> void:
	var scrambled: RoutineTable = _tester_table(false)
	var ascending: RoutineTable = _tester_table(true)
	for hour: int in 24:
		assert_eq(scrambled.peek_action("tester", hour).action_id, ascending.peek_action("tester", hour).action_id, "Hora %d." % hour)


func test_the_end_of_each_block_is_exclusive() -> void:
	var table: RoutineTable = _tester_table()
	assert_eq(table.peek_action("tester", 5).action_id, "sleep", "5h ainda é do bloco [0, 6).")
	assert_eq(table.peek_action("tester", 6).action_id, "work", "6h já é do bloco seguinte.")
	assert_eq(table.peek_action("tester", 11).action_id, "work")
	assert_eq(table.peek_action("tester", 12).action_id, "eat")
	assert_eq(table.peek_action("tester", 13).action_id, "work")
	assert_eq(table.peek_action("tester", 21).action_id, "work")
	assert_eq(table.peek_action("tester", 22).action_id, "sleep")
	assert_eq(table.peek_action("tester", 23).action_id, "sleep", "A última hora do dia é a 23.")


func test_unknown_occupation_invalid_hours_and_a_hand_built_gap_fail_without_crashing() -> void:
	var table: RoutineTable = _tester_table()
	var unknown: RoutineTable.RoutineQuery = table.peek_action("wizard", 7)
	assert_false(unknown.result.ok)
	assert_eq(unknown.result.code, RoutineTable.CODE_UNKNOWN_OCCUPATION)
	assert_string_contains(unknown.result.message, "wizard")
	assert_string_contains(unknown.result.message, "tester")
	for bad_hour: int in [-1, 24, 100]:
		var query: RoutineTable.RoutineQuery = table.peek_action("tester", bad_hour)
		assert_false(query.result.ok, "Hora %d." % bad_hour)
		assert_eq(query.result.code, RoutineTable.CODE_INVALID_HOUR)
	var occupations: Array[RoutineTable.OccupationDef] = [_occupation("half_day")]
	var blocks: Array[RoutineTable.RoutineBlock] = [_block("h1", "half_day", 0, 6, "sleep")]
	var gap: RoutineTable.RoutineQuery = RoutineTable.new(occupations, blocks).peek_action("half_day", 10)
	assert_eq(gap.result.code, RoutineTable.CODE_ROUTINE_GAP, "Hora sem ação em tabela montada à mão: falha tratada.")


func test_the_table_keeps_the_occupation_order_and_the_work_place_kind() -> void:
	var table: RoutineTable = _tester_table()
	assert_true(table.has_occupation("tester"))
	assert_false(table.has_occupation("wizard"))
	assert_eq(table.peek_occupation_ids(), ["tester"] as Array[String])
	assert_eq(table.peek_work_place_kind("tester"), "work")
	assert_eq(table.peek_work_place_kind("wizard"), "")
	var ids: Array[String] = table.peek_occupation_ids()
	ids.clear()
	assert_eq(table.peek_occupation_ids().size(), 1, "A lista devolvida é cópia.")


# ---------------------------------------------------------------------------------------------------- arquivos reais

func test_the_real_files_load_five_occupations_that_cover_the_24_hours_with_known_actions() -> void:
	var loaded: RoutineLoader.LoadResult = RoutineLoader.load_dir()
	assert_true(loaded.result.ok, loaded.result.message)
	var catalog: ActionCatalogLoader.LoadResult = ActionCatalogLoader.load_dir()
	var action_ids: Array[String] = []
	for action: ActionDef in catalog.actions:
		action_ids.append(action.id)
	assert_eq(loaded.table.peek_occupation_ids(), OCCUPATION_IDS)
	for occupation_id: String in OCCUPATION_IDS:
		assert_true(Place.KINDS.has(loaded.table.peek_work_place_kind(occupation_id)), "%s: tipo de local de trabalho do vocabulário do `world`." % occupation_id)
		var seen: Array[String] = []
		for hour: int in 24:
			var query: RoutineTable.RoutineQuery = loaded.table.peek_action(occupation_id, hour)
			assert_true(query.result.ok, "%s na hora %d: %s" % [occupation_id, hour, query.result.message])
			assert_true(action_ids.has(query.action_id), "%s na hora %d: a ação '%s' existe no catálogo." % [occupation_id, hour, query.action_id])
			if not seen.has(query.action_id):
				seen.append(query.action_id)
		for essential: String in ["work", "eat", "sleep"]:
			assert_true(seen.has(essential), "%s: a agenda tem '%s'." % [occupation_id, essential])


func test_loading_twice_gives_the_same_table() -> void:
	var first: RoutineLoader.LoadResult = RoutineLoader.load_dir()
	var second: RoutineLoader.LoadResult = RoutineLoader.load_dir()
	for occupation_id: String in OCCUPATION_IDS:
		for hour: int in 24:
			assert_eq(first.table.peek_action(occupation_id, hour).action_id, second.table.peek_action(occupation_id, hour).action_id)


func test_the_in_memory_path_gives_the_same_table_as_the_files() -> void:
	var from_files: RoutineLoader.LoadResult = RoutineLoader.load_dir()
	var from_memory: RoutineLoader.LoadResult = RoutineLoader.from_tables(_tables(), DATA_DIR)
	assert_true(from_memory.result.ok, from_memory.result.message)
	for hour: int in 24:
		assert_eq(from_memory.table.peek_action("guard", hour).action_id, from_files.table.peek_action("guard", hour).action_id)


func test_the_place_vocabulary_has_a_single_source() -> void:
	assert_eq(ActionDef.PLACE_KINDS, Place.KINDS, "O catálogo usa o vocabulário do `world`, sem cópia.")


# ---------------------------------------------------------------------------------------------------- módulo

func test_the_module_answers_the_query_and_the_hour_comes_from_the_clock() -> void:
	var table: RoutineLoader.LoadResult = RoutineLoader.load_dir()
	var module: NpcModule = NpcModule.new([], table.table)
	var world: World = _new_world(module)
	for _step: int in 7 * 60 + 30:
		world.context.clock.advance_step()
	assert_eq(world.context.clock.hour_of_day(), 7)
	var from_module: RoutineTable.RoutineQuery = module.peek_routine_action("farmer", world.context.clock.hour_of_day())
	assert_true(from_module.result.ok, from_module.result.message)
	assert_eq(from_module.action_id, table.table.peek_action("farmer", 7).action_id)
	assert_eq(module.peek_routine_action("wizard", 7).result.code, RoutineTable.CODE_UNKNOWN_OCCUPATION)
	assert_eq(module.peek_routine_action("farmer", 24).result.code, RoutineTable.CODE_INVALID_HOUR)
	world.teardown()


func test_a_module_without_a_routine_table_says_so() -> void:
	var module: NpcModule = NpcModule.new()
	var query: RoutineTable.RoutineQuery = module.peek_routine_action("farmer", 7)
	assert_false(query.result.ok)
	assert_eq(query.result.code, NpcModule.CODE_ROUTINE_NOT_CONFIGURED)


func test_the_module_rejects_an_unknown_occupation_and_accepts_known_or_empty_ones() -> void:
	var module: NpcModule = NpcModule.new([], _tester_table())
	var world: World = _new_world(module)
	var counter_before: int = world.context.ids.debug_summary()["next_id"]
	var spec: NpcSpec = NpcSpec.new()
	spec.name_key = "npc.name.villager"
	spec.occupation_id = "wizard"
	var refused: NpcModule.CreateResult = module.request_create_npc(spec)
	assert_false(refused.result.ok, "Ofício inexistente é rejeitado.")
	assert_eq(refused.result.code, NpcModule.CODE_INVALID_SPEC)
	assert_string_contains(refused.result.message, "wizard")
	assert_string_contains(refused.result.message, "tester")
	assert_eq(world.context.ids.debug_summary()["next_id"], counter_before, "Recusa não gasta ID.")
	spec.occupation_id = "tester"
	assert_true(module.request_create_npc(spec).result.ok)
	spec.occupation_id = ""
	assert_true(module.request_create_npc(spec).result.ok, "Sem ofício também vale (não há rotina para ele).")
	assert_eq(module.validate().size(), 0, str(module.validate()))
	world.teardown()


func test_validate_flags_a_loaded_npc_with_an_unknown_occupation_only_when_the_module_has_a_routine() -> void:
	var entry: Dictionary = {
		"name_key": "npc.name.villager", "name_number": 1, "tier": 1, "is_alive": true, "death_cause": "", "died_at": -1,
		"traits": [50, 50, 50, 50], "need_values": [0, 0, 0, 0, 0], "need_remainders": [0, 0, 0, 0, 0], "needs_updated_at": 0,
		"x_cm": 0, "z_cm": 0, "settlement_id": "", "place_id": "", "occupation_id": "wizard", "home_place_id": "", "work_place_id": "",
		"action_id": "", "action_target_place_id": "", "action_started_at": 0, "action_ends_at": 0, "action_serial": 0,
	}
	var with_routine: NpcModule = NpcModule.new([], _tester_table())
	var world: World = _new_world(with_routine)
	world.context.ids.next_id()
	assert_true(with_routine.on_load({"npcs": {"1": entry}}).ok)
	var problems: Array[String] = with_routine.validate()
	assert_eq(problems.size(), 1, str(problems))
	assert_string_contains(problems[0], "NPC 1: ofício 'wizard' inexistente")
	world.teardown()
	var without_routine: NpcModule = NpcModule.new()
	var other: World = _new_world(without_routine)
	other.context.ids.next_id()
	assert_true(without_routine.on_load({"npcs": {"1": entry}}).ok)
	assert_eq(without_routine.validate().size(), 0, "Sem tabela de rotina o ofício fica como texto, sem conferência.")
	other.teardown()


# ---------------------------------------------------------------------------------------------------- dado inválido

func test_invalid_data_fails_pointing_at_file_item_and_field() -> void:
	var gap: Dictionary[String, Array] = _tables()
	_row(gap, "routine_blocks", "farmer_07_12")["from_hour"] = 8
	_expect_failure("lacuna", gap, [BLOCKS_FILE, "item 'farmer_07_12'", "campo 'from_hour'", "lacuna na agenda de 'farmer'", "'farmer_06_07' termina na hora 7 e este começa na 8"])
	var overlap: Dictionary[String, Array] = _tables()
	_row(overlap, "routine_blocks", "farmer_12_13")["from_hour"] = 11
	_expect_failure("sobreposição", overlap, [BLOCKS_FILE, "item 'farmer_12_13'", "campo 'from_hour'", "sobreposição na agenda de 'farmer'", "'farmer_07_12' vai até a hora 12 e este começa na 11"])
	var no_start: Dictionary[String, Array] = _tables()
	_remove_row(no_start, "routine_blocks", "farmer_00_06")
	_expect_failure("não começa em 0", no_start, [BLOCKS_FILE, "item 'farmer_06_07'", "campo 'from_hour'", "começa na hora 6; esperado 0"])
	var no_end: Dictionary[String, Array] = _tables()
	_remove_row(no_end, "routine_blocks", "farmer_22_24")
	_expect_failure("não termina em 24", no_end, [BLOCKS_FILE, "item 'farmer_21_22'", "campo 'to_hour'", "termina na hora 22; esperado 24"])
	var backwards: Dictionary[String, Array] = _tables()
	_row(backwards, "routine_blocks", "farmer_07_12")["to_hour"] = 7
	_expect_failure("fim igual ao início", backwards, [BLOCKS_FILE, "item 'farmer_07_12'", "campo 'to_hour'", "a hora final 7 não é maior que a inicial 7"])
	var no_blocks: Dictionary[String, Array] = _tables()
	no_blocks["occupations"].append({"id": "ghost", "work_place_kind": "work"})
	_expect_failure("ofício sem agenda", no_blocks, [BLOCKS_FILE, "item 'ghost'", "nenhuma linha de agenda"])
	var unknown_occupation: Dictionary[String, Array] = _tables()
	_row(unknown_occupation, "routine_blocks", "farmer_07_12")["occupation_id"] = "wizard"
	_expect_failure("ofício inexistente na agenda", unknown_occupation, [BLOCKS_FILE, "item 'farmer_07_12'", "campo 'occupation_id'", "referência a id inexistente 'wizard' na tabela 'occupations'"])
	var unknown_action: Dictionary[String, Array] = _tables()
	_row(unknown_action, "routine_blocks", "farmer_07_12")["action_id"] = "teleport"
	_expect_failure("ação inexistente na agenda", unknown_action, [BLOCKS_FILE, "item 'farmer_07_12'", "campo 'action_id'", "'teleport' na tabela 'actions'"])
	var repeated_id: Dictionary[String, Array] = _tables()
	_row(repeated_id, "routine_blocks", "farmer_13_18")["id"] = "farmer_07_12"
	_expect_failure("id de bloco repetido", repeated_id, [BLOCKS_FILE, "item 'farmer_07_12'", "campo 'id'", "id duplicado"])
	var from_24: Dictionary[String, Array] = _tables()
	_row(from_24, "routine_blocks", "farmer_22_24")["from_hour"] = 24
	_expect_failure("hora inicial 24", from_24, [BLOCKS_FILE, "item 'farmer_22_24'", "campo 'from_hour'", "acima do máximo"])
	var to_0: Dictionary[String, Array] = _tables()
	_row(to_0, "routine_blocks", "farmer_00_06")["to_hour"] = 0
	_expect_failure("hora final 0", to_0, [BLOCKS_FILE, "item 'farmer_00_06'", "campo 'to_hour'", "abaixo do mínimo"])
	var as_text: Dictionary[String, Array] = _tables()
	_row(as_text, "routine_blocks", "farmer_07_12")["from_hour"] = "7"
	_expect_failure("hora como texto", as_text, [BLOCKS_FILE, "item 'farmer_07_12'", "campo 'from_hour'", "tipo inválido"])
	var bad_kind: Dictionary[String, Array] = _tables()
	_row(bad_kind, "occupations", "farmer")["work_place_kind"] = "kitchen"
	_expect_failure("tipo de local de trabalho inexistente", bad_kind, [OCCUPATIONS_FILE, "item 'farmer'", "campo 'work_place_kind'", "tipo de local 'kitchen' inexistente", "market"])
	var unknown_field: Dictionary[String, Array] = _tables()
	_row(unknown_field, "occupations", "guard")["salary"] = 3
	_expect_failure("campo desconhecido", unknown_field, [OCCUPATIONS_FILE, "item 'guard'", "campo 'salary'", "campo desconhecido"])
	for field: String in ["occupation_id", "from_hour", "to_hour", "action_id"]:
		var missing: Dictionary[String, Array] = _tables()
		_row(missing, "routine_blocks", "guard_07_13").erase(field)
		_expect_failure("%s ausente" % field, missing, [BLOCKS_FILE, "item 'guard_07_13'", "campo '%s'" % field, "obrigatório ausente"])
	var broken_catalog: Dictionary[String, Array] = _tables()
	_row(broken_catalog, "actions", "work")["place_kind"] = "kitchen"
	_expect_failure("catálogo de ações inválido também é acusado", broken_catalog, ["actions.json", "item 'work'", "campo 'place_kind'"])


func test_missing_files_fail_pointing_at_each_file() -> void:
	var loaded: RoutineLoader.LoadResult = RoutineLoader.load_dir("res://tests/fixtures/data/ok")
	assert_false(loaded.result.ok)
	assert_eq(loaded.result.code, ISSUE_CODE)
	for file_name: String in [OCCUPATIONS_FILE, BLOCKS_FILE, "actions.json"]:
		assert_string_contains(loaded.result.message, "%s | arquivo não encontrado" % file_name)
