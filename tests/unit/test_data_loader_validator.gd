extends GutTest

## Pasta congelada: não muda quando a pasta editável "ok" é editada.
const OK_DIR: String = "res://tests/fixtures/data/frozen"
const BAD_DIR: String = "res://tests/fixtures/data/bad"


func _make_schemas(goods_file: String = "goods.json") -> Array[DataSchema]:
	var goods: DataSchema = DataSchema.new("goods", goods_file)
	goods.add_field("name_key", DataSchema.FieldType.STRING)
	goods.add_field("base_price", DataSchema.FieldType.INT).set_range(1, 1000000)
	goods.add_field("is_tradable", DataSchema.FieldType.BOOL, false)
	var recipes: DataSchema = DataSchema.new("recipes", "recipes.json")
	recipes.add_field("output_good", DataSchema.FieldType.STRING).set_ref("goods")
	recipes.add_field("output_amount", DataSchema.FieldType.INT).set_range(1, 1000)
	recipes.add_field("yield_chance", DataSchema.FieldType.FLOAT).set_range(0.0, 1.0)
	var schemas: Array[DataSchema] = [goods, recipes]
	return schemas


func _find_issue(bundle: DataBundle, item: String, field: String) -> DataBundle.Issue:
	for issue: DataBundle.Issue in bundle.issues:
		if issue.item == item and issue.field == field:
			return issue
	return null


func _assert_issue(bundle: DataBundle, item: String, field: String, message_part: String, file_name: String) -> void:
	var issue: DataBundle.Issue = _find_issue(bundle, item, field)
	assert_not_null(issue, "Esperava problema em item '%s', campo '%s'." % [item, field])
	if issue == null:
		return
	assert_string_contains(issue.message, message_part)
	assert_true(issue.file.ends_with(file_name), "O problema deve apontar o arquivo %s, mas apontou %s." % [file_name, issue.file])


func test_valid_files_load_without_issues() -> void:
	var bundle: DataBundle = DataLoader.load_all(OK_DIR, _make_schemas())
	assert_true(bundle.is_valid(), bundle.describe_issues())
	assert_true(bundle.to_result().ok)
	assert_eq(bundle.tables["goods"].size(), 2)
	assert_eq(bundle.tables["recipes"].size(), 2)


func test_numbers_are_converted_to_schema_types() -> void:
	var bundle: DataBundle = DataLoader.load_all(OK_DIR, _make_schemas())
	var good: Dictionary = bundle.tables["goods"][0]
	assert_eq(typeof(good["base_price"]), TYPE_INT, "Preço 10 do JSON deve virar inteiro.")
	var recipe: Dictionary = bundle.tables["recipes"][1]
	assert_eq(typeof(recipe["yield_chance"]), TYPE_FLOAT, "Chance 1 do JSON deve virar decimal.")
	assert_eq(typeof(recipe["output_amount"]), TYPE_INT)


func test_loading_twice_gives_same_result() -> void:
	var first: DataBundle = DataLoader.load_all(OK_DIR, _make_schemas())
	var second: DataBundle = DataLoader.load_all(OK_DIR, _make_schemas())
	assert_eq(JSON.stringify(first.tables), JSON.stringify(second.tables))


func test_missing_required_field_is_reported() -> void:
	var bundle: DataBundle = DataLoader.load_all(BAD_DIR, _make_schemas())
	_assert_issue(bundle, "missing_price", "base_price", "obrigatório ausente", "goods.json")


func test_wrong_type_is_reported() -> void:
	var bundle: DataBundle = DataLoader.load_all(BAD_DIR, _make_schemas())
	_assert_issue(bundle, "wrong_type", "base_price", "tipo inválido", "goods.json")


func test_fractional_value_in_integer_field_is_reported() -> void:
	var bundle: DataBundle = DataLoader.load_all(BAD_DIR, _make_schemas())
	_assert_issue(bundle, "fraction", "base_price", "tipo inválido", "goods.json")


func test_value_out_of_range_is_reported() -> void:
	var bundle: DataBundle = DataLoader.load_all(BAD_DIR, _make_schemas())
	_assert_issue(bundle, "below_range", "base_price", "abaixo do mínimo", "goods.json")
	_assert_issue(bundle, "above_range", "yield_chance", "acima do máximo", "recipes.json")


func test_reference_to_missing_id_is_reported() -> void:
	var bundle: DataBundle = DataLoader.load_all(BAD_DIR, _make_schemas())
	_assert_issue(bundle, "ghost_ref", "output_good", "id inexistente 'ghost_good'", "recipes.json")
	assert_null(_find_issue(bundle, "above_range", "output_good"), "Referência a id existente não deve gerar problema.")


func test_invalid_duplicate_and_unknown_fields_are_reported() -> void:
	var bundle: DataBundle = DataLoader.load_all(BAD_DIR, _make_schemas())
	_assert_issue(bundle, "Bad-Id", "id", "id inválido", "goods.json")
	_assert_issue(bundle, "dup_good", "id", "duplicado", "goods.json")
	_assert_issue(bundle, "typo_field", "base_prise", "campo desconhecido", "goods.json")


func test_invalid_bundle_converts_to_failed_result() -> void:
	var bundle: DataBundle = DataLoader.load_all(BAD_DIR, _make_schemas())
	var result: Result = bundle.to_result()
	assert_false(result.ok)
	assert_eq(result.code, "DATA_INVALID")
	assert_string_contains(result.message, "goods.json")


func test_malformed_json_reports_file_and_line() -> void:
	var bundle: DataBundle = DataLoader.load_all(BAD_DIR, _make_schemas("malformed.json"))
	var issue: DataBundle.Issue = _find_issue(bundle, "", "")
	assert_not_null(issue)
	assert_true(issue.file.ends_with("malformed.json"))
	assert_string_contains(issue.message, "JSON inválido na linha")


func test_root_that_is_not_a_list_is_reported() -> void:
	var bundle: DataBundle = DataLoader.load_all(BAD_DIR, _make_schemas("not_a_list.json"))
	var issue: DataBundle.Issue = _find_issue(bundle, "", "")
	assert_not_null(issue)
	assert_string_contains(issue.message, "lista")


func test_missing_file_is_reported() -> void:
	var bundle: DataBundle = DataLoader.load_all(OK_DIR, _make_schemas("does_not_exist.json"))
	var issue: DataBundle.Issue = _find_issue(bundle, "", "")
	assert_not_null(issue)
	assert_true(issue.file.ends_with("does_not_exist.json"))
	assert_string_contains(issue.message, "não encontrado")
