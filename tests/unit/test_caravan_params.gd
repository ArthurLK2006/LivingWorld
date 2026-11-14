extends GutTest
## LW-098b: data/economy/caravan_params.json, os parâmetros do comerciante e da caravana (docs/economy/dados.md), lidos e validados pelo `CaravanParamsLoader`. O arquivo real só tem PROPRIEDADES conferidas (os números são [HIP], calibração na LW-112); dado inválido falha apontando arquivo, item e campo,
## com tabelas montadas em memória (nada é gravado em disco). Serialização, compatibilidade e determinismo, exigidos por Arthur em 14/11/2026, têm teste próprio.

const DATA_DIR: String = "res://data/economy"
const FIELDS: Array[String] = ["speed_cm_per_min", "difficulty_slowdown_bp", "risk_bp_per_point", "time_cost_per_hour", "fixed_cost", "min_net_profit", "min_margin_bp", "origin_reserve_bp"]


## Um valor DIFERENTE por coluna: se duas colunas se trocarem no carregador, a conferência pega.
func _record() -> Dictionary:
	return {"id": "caravan_defaults", "speed_cm_per_min": 401, "difficulty_slowdown_bp": 51, "risk_bp_per_point": 26, "time_cost_per_hour": 3, "fixed_cost": 6, "min_net_profit": 21, "min_margin_bp": 501, "origin_reserve_bp": 4999}


func _load(records: Array[Dictionary]) -> CaravanParamsLoader.LoadResult:
	var tables: Dictionary[String, Array] = {}
	tables[CaravanParamsLoader.PARAMS_TABLE] = records
	return CaravanParamsLoader.from_tables(tables, DATA_DIR)


func _expect_failure(label: String, records: Array[Dictionary], fragments: Array[String]) -> void:
	var loaded: CaravanParamsLoader.LoadResult = _load(records)
	assert_false(loaded.result.ok, "%s: deveria falhar." % label)
	assert_eq(loaded.result.code, EconomyCodes.DATA_INVALID, label)
	assert_null(loaded.params, "%s: falha não devolve parâmetros." % label)
	for fragment: String in fragments:
		assert_string_contains(loaded.result.message, fragment, "%s: a mensagem deveria citar '%s'." % [label, fragment])


func test_the_real_file_loads_into_a_typed_object_with_every_parameter_in_range() -> void:
	var loaded: CaravanParamsLoader.LoadResult = CaravanParamsLoader.load_dir(DATA_DIR)
	assert_true(loaded.result.ok, loaded.result.message)
	var params: CaravanParams = loaded.params
	assert_true(params.speed_cm_per_min >= 1 and params.speed_cm_per_min <= 100000, "A velocidade é maior que 0 (divide a duração do trecho).")
	for basis_points: int in [params.difficulty_slowdown_bp, params.risk_bp_per_point, params.origin_reserve_bp]:
		assert_true(basis_points >= 0 and basis_points <= 10000)
	assert_true(params.min_margin_bp >= 0 and params.min_margin_bp <= 100000)
	for amount: int in [params.time_cost_per_hour, params.fixed_cost, params.min_net_profit]:
		assert_true(amount >= 0)
	assert_gt(params.origin_reserve_bp, 0, "Sem reserva o comerciante esvaziaria o povoado que exporta (Q8).")
	var record: Dictionary = params.to_record()
	assert_eq(record["id"], "caravan_defaults")
	for field: String in FIELDS:
		assert_true(record.has(field), "A linha tem a coluna '%s'." % field)


func test_the_in_memory_path_builds_every_field_from_its_own_column() -> void:
	var loaded: CaravanParamsLoader.LoadResult = _load([_record()])
	assert_true(loaded.result.ok, loaded.result.message)
	var expected: Dictionary = _record()
	for field: String in FIELDS:
		assert_eq(loaded.params.to_record()[field], expected[field], "A coluna '%s' vai para o seu campo." % field)


func test_the_row_written_and_read_again_gives_the_same_object() -> void:
	var first: CaravanParams = CaravanParamsLoader.load_dir(DATA_DIR).params
	var parsed: Variant = JSON.parse_string(JSON.stringify([first.to_record()]))  # Variant: fronteira com o JSON, tipada logo abaixo.
	var rows: Array[Dictionary] = []
	rows.assign(parsed)
	var again: CaravanParamsLoader.LoadResult = _load(rows)
	assert_true(again.result.ok, again.result.message)
	assert_eq(again.params.to_record(), first.to_record(), "A linha reescrita e relida dá o mesmo objeto.")


func test_loading_twice_gives_the_same_parameters() -> void:
	assert_eq(CaravanParamsLoader.load_dir(DATA_DIR).params.to_record(), CaravanParamsLoader.load_dir(DATA_DIR).params.to_record())
	assert_eq(_load([_record()]).params.to_record(), _load([_record()]).params.to_record())


func test_the_real_economy_folder_loads_with_the_new_file_present() -> void:
	assert_true(FileAccess.file_exists(DATA_DIR.path_join(CaravanParamsLoader.PARAMS_FILE)), "O arquivo novo está na pasta real.")
	var setup: EconomySetup = EconomySetup.from_dir(DATA_DIR)
	assert_true(setup.result.ok, setup.result.message)
	assert_false(setup.definitions.goods.is_empty(), "Os outros carregadores seguem entregando as definições de antes.")


func test_invalid_rows_are_refused_pointing_at_file_item_and_field() -> void:
	var cases: Array[Dictionary] = [
		{"label": "campo ausente", "erase": "fixed_cost", "expect": ["caravan_params.json", "item 'caravan_defaults'", "campo 'fixed_cost'", "obrigatório ausente"]},
		{"label": "tipo errado", "set": {"min_net_profit": "20"}, "expect": ["item 'caravan_defaults'", "campo 'min_net_profit'", "tipo inválido"]},
		{"label": "campo desconhecido", "set": {"extra_column": 1}, "expect": ["item 'caravan_defaults'", "campo 'extra_column'", "campo desconhecido"]},
		{"label": "id diferente de caravan_defaults", "set": {"id": "default"}, "expect": ["caravan_params.json", "item 'default'", "campo 'id'", "'caravan_defaults'"]},
		{"label": "velocidade zero", "set": {"speed_cm_per_min": 0}, "expect": ["campo 'speed_cm_per_min'", "abaixo do mínimo"]},
		{"label": "velocidade acima da faixa", "set": {"speed_cm_per_min": 100001}, "expect": ["campo 'speed_cm_per_min'", "acima do máximo"]},
		{"label": "lentidão acima de 10000", "set": {"difficulty_slowdown_bp": 10001}, "expect": ["campo 'difficulty_slowdown_bp'"]},
		{"label": "risco negativo", "set": {"risk_bp_per_point": -1}, "expect": ["campo 'risk_bp_per_point'"]},
		{"label": "custo de tempo negativo", "set": {"time_cost_per_hour": -1}, "expect": ["campo 'time_cost_per_hour'"]},
		{"label": "custo fixo negativo", "set": {"fixed_cost": -1}, "expect": ["campo 'fixed_cost'"]},
		{"label": "lucro mínimo negativo", "set": {"min_net_profit": -1}, "expect": ["campo 'min_net_profit'"]},
		{"label": "margem acima de 100000", "set": {"min_margin_bp": 100001}, "expect": ["campo 'min_margin_bp'"]},
		{"label": "reserva acima de 10000", "set": {"origin_reserve_bp": 10001}, "expect": ["campo 'origin_reserve_bp'"]},
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
	_expect_failure("mais de uma linha", two, ["caravan_params.json", "esperada exatamente 1 linha", "encontradas 2"])
	_expect_failure("nenhuma linha", [], ["esperada exatamente 1 linha", "encontradas 0"])
	var missing: CaravanParamsLoader.LoadResult = CaravanParamsLoader.load_dir("res://data/economy_missing")
	assert_false(missing.result.ok, "Pasta sem o arquivo: falha.")
	assert_string_contains(missing.result.message, "caravan_params.json")
	assert_string_contains(missing.result.message, "arquivo não encontrado")
