extends GutTest
## LW-098f1 (docs/modules/economy.md 9.9 e 9.12; docs/modules/npc.md 14.11): os DADOS e os CARREGADORES do comerciante no `npc`, ainda sem nenhum comerciante no jogo real. (1) `occupations.json`: o ofício `merchant` (local `market`,
## `owner_kind` `merchant`) e a coluna OPCIONAL `owner_kind` (sem ela vale `npc`; vazia ou do tipo errado falha apontando arquivo, item e campo; o id é conferido contra `economy/owner_kinds.json` pelo `check_content_ids`, que
## tests/test_check_content_ids.sh exercita); (2) `routine_blocks.json`: a agenda própria do ofício, 24 horas sem lacuna, só com ações que já existem (`rest` no lugar de `sleep`; a `haul` é da 098f2); (3) a conta que o `NpcLifecycle` abre
## com o tipo do ofício; (4) `npc_params.json`: `haul_value_percent` e `sell_value_percent`, opcionais, de 0 a 1.000 (ausentes valem 0). Cada grupo traz serialização (a linha reescrita e relida dá o mesmo objeto), compatibilidade (ofícios e
## parâmetros antigos iguais) e determinismo (carregar duas vezes dá o mesmo resultado). Tudo em memória (nada é gravado em data/); dos números [HIP] só se fixam os do contrato (conta 300 e 120; parâmetros 100 e 100).

const DATA_DIR: String = "res://data"
const OCCUPATIONS_FILE: String = "occupations.json"
const BLOCKS_FILE: String = "routine_blocks.json"
const PARAMS_LABEL: String = "res://data/npc_params.json"
const ROUTINE_CODE: String = "ROUTINE_DATA_INVALID"
const PARAMS_CODE: String = "NPC_PARAMS_INVALID"
const MERCHANT: String = "merchant"
const OLD_OCCUPATIONS: Array[String] = ["farmer", "lumberjack", "artisan", "guard", "innkeeper", "miner", "shepherd"]
const NEW_FIELDS: Array[String] = ["haul_value_percent", "sell_value_percent"]
const MARKET_PLACE: String = "a_market_01"
const NIGHT_HOURS: Array[int] = [0, 1, 2, 3, 4, 5, 21, 22, 23]
const SEED: int = 98


# ---------------------------------------------------------------------------------------------------- montagem

## `Variant` só na fronteira com o JSON: `parse_string` devolve qualquer tipo, e o tipo é conferido logo abaixo.
func _parse_rows(text: String) -> Array:
	var parsed: Variant = JSON.parse_string(text)
	assert_eq(typeof(parsed), TYPE_ARRAY, "O texto deve ser uma lista.")
	var rows: Array = parsed if typeof(parsed) == TYPE_ARRAY else []
	return rows


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


func _load(tables: Dictionary[String, Array]) -> RoutineTable:
	var loaded: RoutineLoader.LoadResult = RoutineLoader.from_tables(tables, DATA_DIR)
	assert_true(loaded.result.ok, loaded.result.message)
	return loaded.table


func _expect_failure(label: String, tables: Dictionary[String, Array], fragments: Array[String]) -> void:
	var loaded: RoutineLoader.LoadResult = RoutineLoader.from_tables(tables, DATA_DIR)
	assert_false(loaded.result.ok, "%s: deveria falhar." % label)
	assert_eq(loaded.result.code, ROUTINE_CODE, label)
	assert_null(loaded.table, "%s: falha não devolve tabela." % label)
	for fragment: String in fragments:
		assert_string_contains(loaded.result.message, fragment, "%s: a mensagem deveria citar '%s'." % [label, fragment])


## Tudo que a tabela diz de cada ofício: local de trabalho, tipo de dono e a ação das 24 horas.
func _digest(table: RoutineTable) -> Array:
	var rows: Array = []
	for occupation_id: String in table.peek_occupation_ids():
		var hours: Array[String] = []
		for hour: int in RoutineTable.HOURS_PER_DAY:
			hours.append(table.peek_action(occupation_id, hour).action_id)
		rows.append([occupation_id, table.peek_work_place_kind(occupation_id), table.peek_owner_kind(occupation_id), hours])
	return rows


# ---------------------------------------------------------------------------------------------------- ofício e agenda

func test_the_real_files_give_the_merchant_a_market_job_and_a_merchant_account_type_and_the_old_trades_stay_npc() -> void:
	var table: RoutineTable = _load(_tables())
	assert_eq([table.peek_work_place_kind(MERCHANT), table.peek_owner_kind(MERCHANT)], ["market", EconomyModule.KIND_MERCHANT])
	for occupation_id: String in OLD_OCCUPATIONS:
		assert_eq([table.peek_work_place_kind(occupation_id), table.peek_owner_kind(occupation_id)], ["work", EconomyModule.KIND_NPC], "%s: o ofício antigo segue igual (sem a coluna vale `npc`)." % occupation_id)
	assert_eq(table.peek_owner_kind("wizard"), "", "Ofício inexistente: sem tipo de dono.")
	assert_eq(RoutineTable.OccupationDef.new("tester", "work").owner_kind, EconomyModule.KIND_NPC, "Ofício montado à mão, sem o tipo: `npc`.")
	var known: Array[String] = []
	for kind_def: OwnerKindDef in EconomySetup.from_dir(EconomySetup.DEFAULT_DIR).definitions.kinds:
		known.append(kind_def.id)
	for occupation_id: String in table.peek_occupation_ids():
		assert_true(known.has(table.peek_owner_kind(occupation_id)), "%s: o tipo de dono existe em data/economy/owner_kinds.json." % occupation_id)


func test_adding_the_merchant_changes_nothing_in_the_old_occupations() -> void:
	var old_only: Dictionary[String, Array] = _tables()
	old_only["occupations"] = old_only["occupations"].filter(func(record: Dictionary) -> bool: return record["id"] != MERCHANT)
	old_only["routine_blocks"] = old_only["routine_blocks"].filter(func(record: Dictionary) -> bool: return record["occupation_id"] != MERCHANT)
	var expected: Array = _digest(_load(_tables())).filter(func(row: Array) -> bool: return row[0] != MERCHANT)
	assert_eq(expected.size(), OLD_OCCUPATIONS.size())
	assert_eq(_digest(_load(old_only)), expected, "Sem o ofício novo e a agenda dele, os ofícios antigos carregam exatamente iguais.")


func test_the_merchant_has_its_own_agenda_with_rest_at_night_and_no_sleep_or_work() -> void:
	var table: RoutineTable = _load(_tables())
	var catalog: Array[String] = []
	for action: ActionDef in ActionCatalogLoader.load_dir().actions:
		catalog.append(action.id)
	var seen: Array[String] = []
	for hour: int in RoutineTable.HOURS_PER_DAY:
		var query: RoutineTable.RoutineQuery = table.peek_action(MERCHANT, hour)
		assert_true(query.result.ok, "Hora %d: %s" % [hour, query.result.message])
		assert_true(catalog.has(query.action_id), "Hora %d: a ação '%s' existe no catálogo." % [hour, query.action_id])
		seen.append(query.action_id)
	for hour: int in NIGHT_HOURS:
		assert_eq(seen[hour], "rest", "Hora %d: o comerciante descansa à noite (a casa dele pode estar em outro povoado)." % hour)
	assert_true(seen.has("eat"), "A agenda tem refeições.")
	for absent: String in ["sleep", "work"]:
		assert_false(seen.has(absent), "O comerciante não usa '%s'." % absent)


func test_the_merchant_only_loads_with_its_own_agenda_without_gaps() -> void:
	var no_agenda: Dictionary[String, Array] = _tables()
	no_agenda["routine_blocks"] = no_agenda["routine_blocks"].filter(func(record: Dictionary) -> bool: return record["occupation_id"] != MERCHANT)
	_expect_failure("ofício sem agenda", no_agenda, [BLOCKS_FILE, "item 'merchant'", "nenhuma linha de agenda"])
	var gap: Dictionary[String, Array] = _tables()
	_row(gap, "routine_blocks", "merchant_07_12")["from_hour"] = 8
	_expect_failure("lacuna na agenda", gap, [BLOCKS_FILE, "item 'merchant_07_12'", "campo 'from_hour'", "lacuna na agenda de 'merchant'"])
	var past_midnight: Dictionary[String, Array] = _tables()
	_row(past_midnight, "routine_blocks", "merchant_21_24")["to_hour"] = 25
	_expect_failure("agenda além das 24 horas", past_midnight, [BLOCKS_FILE, "item 'merchant_21_24'", "campo 'to_hour'", "acima do máximo"])


func test_the_owner_kind_column_is_optional_and_a_bad_value_fails_pointing_at_file_item_and_field() -> void:
	var without_column: Dictionary[String, Array] = _tables()
	_row(without_column, "occupations", MERCHANT).erase("owner_kind")
	assert_eq(_load(without_column).peek_owner_kind(MERCHANT), EconomyModule.KIND_NPC, "Sem a coluna vale `npc`.")
	var explicit: Dictionary[String, Array] = _tables()
	_row(explicit, "occupations", "guard")["owner_kind"] = EconomyModule.KIND_NPC
	assert_eq(_load(explicit).peek_owner_kind("guard"), EconomyModule.KIND_NPC, "Escrever `npc` é o mesmo que omitir a coluna.")
	for blank_value: String in ["", "   "]:
		var blank: Dictionary[String, Array] = _tables()
		_row(blank, "occupations", MERCHANT)["owner_kind"] = blank_value
		_expect_failure("owner_kind vazio", blank, [OCCUPATIONS_FILE, "item 'merchant'", "campo 'owner_kind'", "tipo de dono vazio"])
	var as_number: Dictionary[String, Array] = _tables()
	_row(as_number, "occupations", MERCHANT)["owner_kind"] = 5
	_expect_failure("owner_kind como número", as_number, [OCCUPATIONS_FILE, "item 'merchant'", "campo 'owner_kind'", "tipo inválido"])
	var misspelt: Dictionary[String, Array] = _tables()
	_row(misspelt, "occupations", MERCHANT)["owner_kinds"] = EconomyModule.KIND_MERCHANT
	_expect_failure("coluna com erro de digitação", misspelt, [OCCUPATIONS_FILE, "item 'merchant'", "campo 'owner_kinds'", "campo desconhecido"])


func test_rewritten_and_reread_rows_give_the_same_table_and_loading_twice_gives_the_same_table() -> void:
	var tables: Dictionary[String, Array] = _tables()
	var rewritten: Dictionary[String, Array] = {}
	for table_id: String in tables:
		rewritten[table_id] = _parse_rows(JSON.stringify(tables[table_id]))
	assert_eq(_digest(_load(rewritten)), _digest(_load(tables)), "Reescrever as linhas em JSON e relê-las dá o mesmo objeto.")
	assert_eq(_digest(_load(_tables())), _digest(_load(_tables())), "Carregar duas vezes dá o mesmo resultado.")
	assert_eq(_digest(RoutineLoader.load_dir().table), _digest(_load(tables)), "O caminho do arquivo e o da memória dão o mesmo.")


# ---------------------------------------------------------------------------------------------------- conta na economia

func _economy() -> EconomyModule:
	var setup: EconomySetup = EconomySetup.from_dir(EconomySetup.DEFAULT_DIR)
	assert_true(setup.result.ok, setup.result.message)
	return EconomyModule.new(false, setup.definitions)


func _world(economy: EconomyModule, npc: NpcModule) -> World:
	var clock: SimClock = SimClock.new()
	var world: World = World.new(SimContext.new(clock, EventBus.new(clock), WorldRng.new(SEED), IdGenerator.new()))
	assert_true(world.register_module("economy", economy).ok)
	assert_true(world.register_module("npc", npc).ok)
	world.setup()
	world.post_setup()
	world.on_new_game(SEED)
	return world


func _spec(occupation_id: String, work_place_id: String) -> NpcSpec:
	var spec: NpcSpec = NpcSpec.new()
	spec.name_key = "npc.name.villager"
	spec.name_number = 1
	spec.occupation_id = occupation_id
	spec.work_place_id = work_place_id
	return spec


## Saldo e capacidade de peso da conta (o tipo de dono define os dois).
func _account(economy: EconomyModule, owner_id: int) -> Array:
	return [economy.peek_balance(owner_id).balance, economy.peek_inventory(owner_id).capacity]


func test_the_merchant_opens_a_merchant_account_and_the_other_trades_keep_the_npc_account() -> void:
	var economy: EconomyModule = _economy()
	var npc: NpcModule = NpcModule.new([], RoutineLoader.load_dir().table, null, economy)
	var world: World = _world(economy, npc)
	var merchant: NpcModule.CreateResult = npc.request_create_npc(_spec(MERCHANT, MARKET_PLACE))
	var farmer: NpcModule.CreateResult = npc.request_create_npc(_spec("farmer", "a_work_01"))
	var jobless: NpcModule.CreateResult = npc.request_create_npc(_spec("", ""))
	for created: NpcModule.CreateResult in [merchant, farmer, jobless]:
		assert_true(created.result.ok, created.result.message)
	assert_eq(_account(economy, merchant.npc_id), [300, 120], "O comerciante abre conta do tipo `merchant`: saldo 300 e peso 120.")
	assert_eq(_account(economy, farmer.npc_id), [60, 40], "O lavrador segue com a conta `npc`: saldo 60 e peso 40.")
	assert_eq(_account(economy, jobless.npc_id), [60, 40], "Sem ofício também vale `npc`.")
	assert_true(economy.peek_conservation().ok, "O dinheiro inicial do comerciante entra pelo `mint` do Ledger.")
	assert_eq(economy.validate(), [] as Array[String])
	world.teardown()


func test_an_owner_kind_the_economy_does_not_know_leaves_the_npc_without_an_account() -> void:
	var occupations: Array[RoutineTable.OccupationDef] = [RoutineTable.OccupationDef.new("ghost_trader", "market", "ghost_kind")]
	var economy: EconomyModule = _economy()
	var npc: NpcModule = NpcModule.new([], RoutineTable.new(occupations, []), null, economy)
	var world: World = _world(economy, npc)
	var created: NpcModule.CreateResult = npc.request_create_npc(_spec("ghost_trader", MARKET_PLACE))
	assert_true(created.result.ok, "A criação não é desfeita: só a conta falha, de forma visível.")
	assert_push_error("não abriu na economia")
	assert_eq(economy.peek_balance(created.npc_id).result.code, EconomyCodes.UNKNOWN_OWNER, "Sem tipo conhecido não há conta.")
	world.teardown()


# ---------------------------------------------------------------------------------------------------- parâmetros

## A linha real de data/npc_params.json, como o JSON a entrega (números inteiros chegam como decimais).
func _real_record() -> Dictionary:
	var record: Dictionary = _parse_rows(FileAccess.get_file_as_string(PARAMS_LABEL))[0]
	return record


func _load_params(record: Dictionary) -> NpcParamsLoader.LoadResult:
	var records: Array[Dictionary] = [record]
	var bundle: DataBundle = DataBundle.new()
	bundle.tables[NpcParamsLoader.PARAMS_TABLE] = records
	bundle.file_paths[NpcParamsLoader.PARAMS_TABLE] = PARAMS_LABEL
	DataValidator.new().validate(bundle, [NpcParamsLoader.build_schema()])
	return NpcParamsLoader.from_bundle(bundle)


## Um valor de cada grupo de parâmetros antigos (o dos dois campos novos vai à parte).
func _old_values(params: NpcParams) -> Array:
	return [params.urgency_weight_critical, params.routine_bonus, params.think_interval_min, params.decision_top_k, params.alarm_radius_m, params.max_t2, params.memory_capacity, params.relations_capacity, params.talk_gain, params.buy_units, params.buy_price_percent]


func test_the_real_params_file_gives_100_and_100_to_the_two_new_fields() -> void:
	var loaded: NpcParamsLoader.LoadResult = NpcParamsLoader.load_dir()
	assert_true(loaded.result.ok, loaded.result.message)
	assert_eq([loaded.params.haul_value_percent, loaded.params.sell_value_percent], [100, 100], "Partida [HIP]: um ponto de utilidade por moeda.")


func test_an_old_params_file_without_the_two_fields_loads_as_before_with_both_at_zero() -> void:
	var record: Dictionary = _real_record()
	var current: NpcParamsLoader.LoadResult = _load_params(record.duplicate())
	assert_true(current.result.ok, current.result.message)
	for field: String in NEW_FIELDS:
		record.erase(field)
	var old: NpcParamsLoader.LoadResult = _load_params(record)
	assert_true(old.result.ok, old.result.message)
	assert_eq([old.params.haul_value_percent, old.params.sell_value_percent], [0, 0], "Sem os campos valem 0.")
	assert_eq(_old_values(old.params), _old_values(current.params), "Os demais parâmetros ficam iguais.")


func test_the_two_fields_are_range_checked_and_a_bad_one_fails_pointing_at_file_item_and_field() -> void:
	var rejected: Array[Dictionary] = [
		{"value": -1, "fragment": "abaixo do mínimo"}, {"value": 1001, "fragment": "acima do máximo"},
		{"value": "100", "fragment": "tipo inválido"}, {"value": 99.5, "fragment": "tipo inválido"},
	]
	for field: String in NEW_FIELDS:
		for accepted: int in [0, 1000]:
			var good: Dictionary = _real_record()
			good[field] = accepted
			var loaded: NpcParamsLoader.LoadResult = _load_params(good)
			assert_true(loaded.result.ok, "%s = %d: dentro da faixa (%s)." % [field, accepted, loaded.result.message])
			assert_eq(loaded.params.haul_value_percent if field == NEW_FIELDS[0] else loaded.params.sell_value_percent, accepted, "%s = %d é guardado." % [field, accepted])
		for bad: Dictionary in rejected:
			var record: Dictionary = _real_record()
			record[field] = bad["value"]
			var failed: NpcParamsLoader.LoadResult = _load_params(record)
			assert_false(failed.result.ok, "%s = %s: deveria falhar." % [field, str(bad["value"])])
			assert_eq(failed.result.code, PARAMS_CODE)
			assert_null(failed.params, "Falha não devolve parâmetros.")
			for fragment: String in [PARAMS_LABEL, "item 'default'", "campo '%s'" % field, str(bad["fragment"])]:
				assert_string_contains(failed.result.message, fragment, "%s = %s: a mensagem deveria citar '%s'." % [field, str(bad["value"]), fragment])
	var unknown: Dictionary = _real_record()
	unknown["haul_value_percnt"] = 100
	var misspelt: NpcParamsLoader.LoadResult = _load_params(unknown)
	assert_false(misspelt.result.ok, "Campo com erro de digitação deveria falhar.")
	for fragment: String in [PARAMS_LABEL, "item 'default'", "campo 'haul_value_percnt'", "campo desconhecido"]:
		assert_string_contains(misspelt.result.message, fragment)


func test_the_rewritten_and_reread_params_row_gives_the_same_object_and_loading_twice_gives_the_same() -> void:
	var record: Dictionary = _real_record()
	var original: NpcParamsLoader.LoadResult = _load_params(record.duplicate())
	var reread: Dictionary = _parse_rows(JSON.stringify([record]))[0]
	var again: NpcParamsLoader.LoadResult = _load_params(reread)
	assert_true(again.result.ok, again.result.message)
	assert_eq(_old_values(again.params), _old_values(original.params), "A linha reescrita e relida dá o mesmo objeto.")
	assert_eq([again.params.haul_value_percent, again.params.sell_value_percent], [original.params.haul_value_percent, original.params.sell_value_percent])
	var first: NpcParams = NpcParamsLoader.load_dir().params
	var second: NpcParams = NpcParamsLoader.load_dir().params
	assert_eq(_old_values(first) + [first.haul_value_percent, first.sell_value_percent], _old_values(second) + [second.haul_value_percent, second.sell_value_percent], "Carregar duas vezes dá o mesmo resultado.")
