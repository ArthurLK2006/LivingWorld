extends GutTest

const FILE_NAME: String = "lists.json"


## Valida um texto JSON (lista de registros) contra um campo `values` de lista de inteiros de 0 a 100.
func _validate(json_text: String, max_length: int = 4) -> DataBundle:
	var table: DataSchema = DataSchema.new("lists", FILE_NAME)
	table.add_field("values", DataSchema.FieldType.INT_LIST).set_range(0, 100).set_max_length(max_length)
	var parsed: Array = JSON.parse_string(json_text)
	var records: Array[Dictionary] = []
	for entry: Dictionary in parsed:
		records.append(entry)
	var bundle: DataBundle = DataBundle.new()
	bundle.tables["lists"] = records
	bundle.file_paths["lists"] = "res://tests/fixtures/data/" + FILE_NAME
	var schemas: Array[DataSchema] = [table]
	DataValidator.new().validate(bundle, schemas)
	return bundle


func _assert_reported(bundle: DataBundle, message_part: String) -> void:
	assert_false(bundle.is_valid(), "Esperava um problema com '%s'." % message_part)
	assert_string_contains(bundle.describe_issues(), "lists.json | item 'a' | campo 'values' | " + message_part)


func test_valid_list_becomes_packed_integers() -> void:
	var bundle: DataBundle = _validate('[{"id": "a", "values": [0, 5, 100]}]')
	assert_true(bundle.is_valid(), bundle.describe_issues())
	var values: Variant = bundle.tables["lists"][0]["values"]
	assert_eq(typeof(values), TYPE_PACKED_INT64_ARRAY, "A lista validada deve virar PackedInt64Array.")
	assert_eq(values, PackedInt64Array([0, 5, 100]))


func test_empty_list_is_valid_at_this_level() -> void:
	var bundle: DataBundle = _validate('[{"id": "a", "values": []}]')
	assert_true(bundle.is_valid(), bundle.describe_issues())
	assert_eq(bundle.tables["lists"][0]["values"].size(), 0)


func test_element_with_fraction_is_reported_with_its_position() -> void:
	_assert_reported(_validate('[{"id": "a", "values": [1, 2.5, 3]}]'), "elemento na posição 1: tipo inválido")


func test_element_of_wrong_type_is_reported_with_its_position() -> void:
	_assert_reported(_validate('[{"id": "a", "values": [1, 2, "tres"]}]'), "elemento na posição 2: tipo inválido")


func test_element_out_of_range_is_reported() -> void:
	_assert_reported(_validate('[{"id": "a", "values": [1, 101]}]'), "elemento na posição 1: valor 101 acima do máximo")
	_assert_reported(_validate('[{"id": "a", "values": [-1]}]'), "elemento na posição 0: valor -1 abaixo do mínimo")


func test_list_above_the_size_limit_is_reported() -> void:
	_assert_reported(_validate('[{"id": "a", "values": [1, 2, 3, 4, 5]}]'), "lista com 5 elementos, acima do limite de 4")


func test_missing_list_field_is_reported() -> void:
	_assert_reported(_validate('[{"id": "a"}]'), "campo obrigatório ausente")


func test_value_that_is_not_a_list_is_reported() -> void:
	_assert_reported(_validate('[{"id": "a", "values": 5}]'), "tipo inválido: esperado lista de inteiros")


func test_many_bad_elements_are_summarized() -> void:
	var bundle: DataBundle = _validate('[{"id": "a", "values": [0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5]}]', 20)
	assert_eq(bundle.issues.size(), DataValidator.MAX_ELEMENT_ISSUES + 1, "Detalha só os primeiros e resume o resto.")
	assert_string_contains(bundle.issues[bundle.issues.size() - 1].message, "mais 3 elementos inválidos não detalhados (total 13)")
