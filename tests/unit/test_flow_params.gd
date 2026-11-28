extends GutTest
## LW-100b: data/economy/flow_params.json, os parâmetros próprios do fluxo agregado (docs/modules/economy.md, 9.16.2), lidos e validados pelo `FlowParamsLoader`. O arquivo real traz 50 e 25 ([HIP], calibração no SP7); dado inválido falha apontando arquivo, item e campo, com tabelas montadas em memória (nada é gravado em disco).
## Serialização, compatibilidade e determinismo do formato novo têm teste próprio (como no `test_caravan_params.gd`).

const DATA_DIR: String = "res://data/economy"
const FIELDS: Array[String] = ["daily_cap_units", "risk_bp_per_point"]


## Um valor DIFERENTE por coluna: se duas colunas se trocarem no carregador, a conferência pega.
func _record() -> Dictionary:
	return {"id": "flow_defaults", "daily_cap_units": 51, "risk_bp_per_point": 26}


func _load(records: Array[Dictionary]) -> FlowParamsLoader.LoadResult:
	var tables: Dictionary[String, Array] = {}
	tables[FlowParamsLoader.PARAMS_TABLE] = records
	return FlowParamsLoader.from_tables(tables, DATA_DIR)


func _expect_failure(label: String, records: Array[Dictionary], fragments: Array[String]) -> void:
	var loaded: FlowParamsLoader.LoadResult = _load(records)
	assert_false(loaded.result.ok, "%s: deveria falhar." % label)
	assert_eq(loaded.result.code, EconomyCodes.DATA_INVALID, label)
	assert_null(loaded.params, "%s: falha não devolve parâmetros." % label)
	for fragment: String in fragments:
		assert_string_contains(loaded.result.message, fragment, "%s: a mensagem deveria citar '%s'." % [label, fragment])


func test_the_real_file_loads_with_50_and_25() -> void:
	var loaded: FlowParamsLoader.LoadResult = FlowParamsLoader.load_dir(DATA_DIR)
	assert_true(loaded.result.ok, loaded.result.message)
	assert_eq(loaded.params.daily_cap_units, 50, "Partida: o `max_order_quantity` de hoje.")
	assert_eq(loaded.params.risk_bp_per_point, 25, "Partida: o valor da caravana.")
	assert_eq(loaded.params.to_record(), {"id": "flow_defaults", "daily_cap_units": 50, "risk_bp_per_point": 25})


func test_the_in_memory_path_builds_every_field_from_its_own_column() -> void:
	var loaded: FlowParamsLoader.LoadResult = _load([_record()])
	assert_true(loaded.result.ok, loaded.result.message)
	for field: String in FIELDS:
		assert_eq(loaded.params.to_record()[field], _record()[field], "A coluna '%s' vai para o seu campo." % field)


func test_the_row_written_and_read_again_gives_the_same_object() -> void:
	var first: FlowParams = FlowParamsLoader.load_dir(DATA_DIR).params
	var parsed: Variant = JSON.parse_string(JSON.stringify([first.to_record()]))  # Variant: fronteira com o JSON, tipada logo abaixo.
	var rows: Array[Dictionary] = []
	rows.assign(parsed)
	var again: FlowParamsLoader.LoadResult = _load(rows)
	assert_true(again.result.ok, again.result.message)
	assert_eq(again.params.to_record(), first.to_record(), "A linha reescrita e relida dá o mesmo objeto.")


func test_loading_twice_gives_the_same_parameters() -> void:
	assert_eq(FlowParamsLoader.load_dir(DATA_DIR).params.to_record(), FlowParamsLoader.load_dir(DATA_DIR).params.to_record())
	assert_eq(_load([_record()]).params.to_record(), _load([_record()]).params.to_record())


func test_the_real_economy_folder_still_loads_with_the_new_file_present() -> void:
	assert_true(FileAccess.file_exists(DATA_DIR.path_join(FlowParamsLoader.PARAMS_FILE)), "O arquivo novo está na pasta real.")
	var setup: EconomySetup = EconomySetup.from_dir(DATA_DIR)
	assert_true(setup.result.ok, setup.result.message)
	assert_false(setup.definitions.goods.is_empty(), "Os outros carregadores seguem entregando as definições de antes.")
	assert_true(CaravanParamsLoader.load_dir(DATA_DIR).result.ok, "O arquivo vizinho da caravana segue válido e independente.")


func test_both_ends_of_every_range_are_accepted() -> void:
	for pair: Array in [[1, 0], [1000, 100]]:
		var row: Dictionary = _record()
		row["daily_cap_units"] = pair[0]
		row["risk_bp_per_point"] = pair[1]
		var loaded: FlowParamsLoader.LoadResult = _load([row])
		assert_true(loaded.result.ok, loaded.result.message)
		assert_eq([loaded.params.daily_cap_units, loaded.params.risk_bp_per_point], pair, "Os extremos da faixa valem.")


func test_invalid_rows_are_refused_pointing_at_file_item_and_field() -> void:
	var cases: Array[Dictionary] = [
		{"label": "campo ausente: teto diário", "erase": "daily_cap_units", "expect": ["flow_params.json", "item 'flow_defaults'", "campo 'daily_cap_units'", "obrigatório ausente"]},
		{"label": "campo ausente: risco", "erase": "risk_bp_per_point", "expect": ["item 'flow_defaults'", "campo 'risk_bp_per_point'", "obrigatório ausente"]},
		{"label": "tipo errado: texto", "set": {"daily_cap_units": "50"}, "expect": ["item 'flow_defaults'", "campo 'daily_cap_units'", "tipo inválido"]},
		{"label": "tipo errado: decimal", "set": {"risk_bp_per_point": 25.5}, "expect": ["item 'flow_defaults'", "campo 'risk_bp_per_point'", "tipo inválido"]},
		{"label": "tipo errado: booleano", "set": {"daily_cap_units": true}, "expect": ["item 'flow_defaults'", "campo 'daily_cap_units'", "tipo inválido"]},
		{"label": "teto diário zero", "set": {"daily_cap_units": 0}, "expect": ["campo 'daily_cap_units'", "abaixo do mínimo"]},
		{"label": "teto diário acima de 1000", "set": {"daily_cap_units": 1001}, "expect": ["campo 'daily_cap_units'", "acima do máximo"]},
		{"label": "risco negativo", "set": {"risk_bp_per_point": -1}, "expect": ["campo 'risk_bp_per_point'", "abaixo do mínimo"]},
		{"label": "risco acima de 100", "set": {"risk_bp_per_point": 101}, "expect": ["campo 'risk_bp_per_point'", "acima do máximo"]},
		{"label": "campo desconhecido", "set": {"extra_column": 1}, "expect": ["item 'flow_defaults'", "campo 'extra_column'", "campo desconhecido"]},
		{"label": "id diferente de flow_defaults", "set": {"id": "caravan_defaults"}, "expect": ["flow_params.json", "item 'caravan_defaults'", "campo 'id'", "'flow_defaults'"]},
	]
	for test_case: Dictionary in cases:
		var row: Dictionary = _record()
		if test_case.has("erase"):
			row.erase(test_case["erase"])
		else:
			row.merge(test_case["set"], true)
		var records: Array[Dictionary] = [row]
		var fragments: Array[String] = []
		fragments.assign(test_case["expect"])
		_expect_failure(test_case["label"], records, fragments)
	var two: Array[Dictionary] = [_record(), _record()]
	_expect_failure("linha duplicada", two, ["flow_params.json", "esperada exatamente 1 linha", "encontradas 2"])
	_expect_failure("nenhuma linha", [], ["esperada exatamente 1 linha", "encontradas 0"])
	var missing: FlowParamsLoader.LoadResult = FlowParamsLoader.load_dir("res://data/economy_missing")
	assert_false(missing.result.ok, "Pasta sem o arquivo: falha.")
	assert_string_contains(missing.result.message, "flow_params.json")
	assert_string_contains(missing.result.message, "arquivo não encontrado")
