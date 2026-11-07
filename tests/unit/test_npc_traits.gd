extends GutTest
## LW-057 (B3b): os quatro traços de personalidade em data/traits.json, lidos e validados pelo módulo `data` (TraitLoader). O arquivo real
## carrega com os valores ESCRITOS À MÃO a partir do contrato (docs/modules/npc.md, seção 1); dado inválido falha apontando arquivo,
## item e campo. Os casos inválidos usam pacotes montados em memória (nada é gravado em disco).

const FILE_LABEL: String = "res://data/traits.json"
const ISSUE_CODE: String = "TRAIT_DATA_INVALID"


func _record(id: String, order: int) -> Dictionary:
	return {"id": id, "order": order}


func _valid_records() -> Array[Dictionary]:
	return [_record("caution", 0), _record("sociability", 1), _record("ambition", 2), _record("loyalty", 3)]


## Mesmo caminho do carregador de arquivo: o `data` valida o pacote e o TraitLoader confere o resto e monta.
func _load_records(records: Array[Dictionary]) -> TraitLoader.LoadResult:
	var bundle: DataBundle = DataBundle.new()
	bundle.tables[TraitLoader.TRAITS_TABLE] = records
	bundle.file_paths[TraitLoader.TRAITS_TABLE] = FILE_LABEL
	DataValidator.new().validate(bundle, [TraitLoader.build_schema()])
	return TraitLoader.from_bundle(bundle)


func test_the_real_file_loads_the_four_traits_in_order() -> void:
	var loaded: TraitLoader.LoadResult = TraitLoader.load_dir()
	assert_true(loaded.result.ok, loaded.result.message)
	assert_eq(loaded.traits.size(), 4)
	assert_eq(loaded.traits.size(), NpcState.TRAIT_COUNT, "Uma linha por posição do estado.")
	var expected_ids: Array[String] = ["caution", "sociability", "ambition", "loyalty"]
	for position: int in expected_ids.size():
		assert_eq(loaded.traits[position].id, expected_ids[position], "Traço na posição %d." % position)
		assert_eq(loaded.traits[position].order, position)


func test_loading_twice_gives_the_same_result() -> void:
	var first: TraitLoader.LoadResult = TraitLoader.load_dir()
	var second: TraitLoader.LoadResult = TraitLoader.load_dir()
	assert_eq(first.traits.size(), second.traits.size())
	for position: int in first.traits.size():
		assert_eq(first.traits[position].id, second.traits[position].id)


func test_records_out_of_file_order_are_returned_by_position() -> void:
	var shuffled: Array[Dictionary] = [_record("loyalty", 3), _record("caution", 0), _record("ambition", 2), _record("sociability", 1)]
	var loaded: TraitLoader.LoadResult = _load_records(shuffled)
	assert_true(loaded.result.ok, loaded.result.message)
	assert_eq(loaded.traits[0].id, "caution")
	assert_eq(loaded.traits[3].id, "loyalty")


func test_a_valid_in_memory_table_passes() -> void:
	var loaded: TraitLoader.LoadResult = _load_records(_valid_records())
	assert_true(loaded.result.ok, loaded.result.message)
	assert_eq(loaded.traits.size(), 4)


func test_invalid_tables_fail_pointing_at_file_item_and_field() -> void:
	var cases: Array[Dictionary] = []
	var missing_order: Array[Dictionary] = _valid_records()
	missing_order[1].erase("order")
	cases.append({"label": "order ausente", "records": missing_order, "expect": [FILE_LABEL, "item 'sociability'", "campo 'order'", "obrigatório ausente"]})
	var order_too_high: Array[Dictionary] = _valid_records()
	order_too_high[2]["order"] = 4
	cases.append({"label": "order acima da faixa", "records": order_too_high, "expect": [FILE_LABEL, "item 'ambition'", "campo 'order'", "acima do máximo"]})
	var order_negative: Array[Dictionary] = _valid_records()
	order_negative[0]["order"] = -1
	cases.append({"label": "order negativa", "records": order_negative, "expect": [FILE_LABEL, "item 'caution'", "campo 'order'", "abaixo do mínimo"]})
	var order_fraction: Array[Dictionary] = _valid_records()
	order_fraction[0]["order"] = 1.5
	cases.append({"label": "order com fração", "records": order_fraction, "expect": [FILE_LABEL, "item 'caution'", "campo 'order'", "tipo inválido"]})
	var order_text: Array[Dictionary] = _valid_records()
	order_text[3]["order"] = "3"
	cases.append({"label": "order texto", "records": order_text, "expect": [FILE_LABEL, "item 'loyalty'", "campo 'order'", "tipo inválido"]})
	var repeated_order: Array[Dictionary] = _valid_records()
	repeated_order[3]["order"] = 2
	cases.append({"label": "order repetida", "records": repeated_order, "expect": [FILE_LABEL, "item 'loyalty'", "campo 'order'", "já usada pelo traço 'ambition'"]})
	var repeated_id: Array[Dictionary] = _valid_records()
	repeated_id[1]["id"] = "caution"
	cases.append({"label": "id repetido", "records": repeated_id, "expect": [FILE_LABEL, "item 'caution'", "campo 'id'", "id duplicado"]})
	var bad_id: Array[Dictionary] = _valid_records()
	bad_id[0]["id"] = "Caution"
	cases.append({"label": "id fora do padrão", "records": bad_id, "expect": [FILE_LABEL, "item 'Caution'", "campo 'id'", "snake_case"]})
	var missing_id: Array[Dictionary] = _valid_records()
	missing_id[2].erase("id")
	cases.append({"label": "id ausente", "records": missing_id, "expect": [FILE_LABEL, "item '#2'", "campo 'id'", "obrigatório ausente"]})
	var unknown_field: Array[Dictionary] = _valid_records()
	unknown_field[0]["name"] = "Cautela"
	cases.append({"label": "campo desconhecido", "records": unknown_field, "expect": [FILE_LABEL, "item 'caution'", "campo 'name'", "campo desconhecido"]})
	var too_few: Array[Dictionary] = _valid_records()
	too_few.pop_back()
	cases.append({"label": "só três traços", "records": too_few, "expect": [FILE_LABEL, "esperado 4 traços", "encontrados 3"]})
	var too_many: Array[Dictionary] = _valid_records()
	too_many.append(_record("greed", 4))
	cases.append({"label": "cinco traços", "records": too_many, "expect": [FILE_LABEL, "item 'greed'", "campo 'order'", "esperado 4 traços", "encontrados 5"]})
	for test_case: Dictionary in cases:
		var records: Array[Dictionary] = []
		records.assign(test_case["records"])
		var loaded: TraitLoader.LoadResult = _load_records(records)
		assert_false(loaded.result.ok, "%s: deveria falhar." % test_case["label"])
		assert_eq(loaded.result.code, ISSUE_CODE, test_case["label"])
		assert_eq(loaded.traits.size(), 0, "Falha não devolve traços.")
		for fragment: String in test_case["expect"]:
			assert_string_contains(loaded.result.message, fragment, "%s: a mensagem deveria citar '%s'." % [test_case["label"], fragment])


func test_a_missing_file_fails_pointing_at_the_file() -> void:
	var loaded: TraitLoader.LoadResult = TraitLoader.load_dir("res://tests/fixtures/data/ok")
	assert_false(loaded.result.ok)
	assert_eq(loaded.result.code, ISSUE_CODE)
	assert_string_contains(loaded.result.message, "traits.json")
	assert_string_contains(loaded.result.message, "arquivo não encontrado")
