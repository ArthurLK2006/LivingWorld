extends GutTest
## LW-118b: o dado inválido de provinces.json e province_adjacency.json falha apontando arquivo, item e campo (docs/modules/world.md, "Extensão da Fase 4"): campo ausente, desconhecido, tipo errado,
## id repetido, nome vazio, `kind` fora do vocabulário, lista vazia, ponta que não existe, ligação de uma província com ela mesma, par repetido (também invertido), pontas fora da ordem alfabética,
## `id` que não bate com as colunas, grafo não conectado, JSON malformado e arquivo ausente. Província nova entra só por dado.

const MISSING_DIR: String = "res://tests/fixtures/world/pasta_que_nao_existe"
const P_A: String = '{"id": "pa", "name_key": "province.pa.name", "kind": "settled"}'
const P_B: String = '{"id": "pb", "name_key": "province.pb.name", "kind": "settled"}'
const P_BORDER: String = '{"id": "pc", "name_key": "province.pc.name", "kind": "frontier"}'
const L_AB: String = '{"id": "pa__pb", "province_a_id": "pa", "province_b_id": "pb"}'
const L_BC: String = '{"id": "pb__pc", "province_a_id": "pb", "province_b_id": "pc"}'

var _temp_dirs: Array[DirAccess] = []


func after_each() -> void:
	for dir: DirAccess in _temp_dirs:
		for file_name: String in dir.get_files():
			dir.remove(file_name)
		DirAccess.remove_absolute(dir.get_current_dir())
	_temp_dirs.clear()


func _dir_with(provinces_text: String, adjacency_text: String) -> String:
	var dir: DirAccess = DirAccess.create_temp("lw118b")
	_temp_dirs.append(dir)
	for entry: Array in [[ProvinceLoader.DEFAULT_PROVINCES_FILE, provinces_text], [ProvinceLoader.DEFAULT_ADJACENCY_FILE, adjacency_text]]:
		var file: FileAccess = FileAccess.open(dir.get_current_dir().path_join(entry[0]), FileAccess.WRITE)
		file.store_string(entry[1])
		file.close()
	return dir.get_current_dir()


func _assert_invalid(provinces_text: String, adjacency_text: String, expected_parts: Array[String]) -> void:
	var loaded: ProvinceLoader.LoadResult = ProvinceLoader.load_dir(_dir_with(provinces_text, adjacency_text))
	assert_false(loaded.result.ok, "Arquivo inválido deveria falhar: %s | %s" % [provinces_text, adjacency_text])
	assert_eq(loaded.result.code, ProvinceLoader.CODE_INVALID)
	assert_eq(loaded.provinces.size() + loaded.links.size(), 0, "Falha não devolve província nem ligação.")
	for part: String in expected_parts:
		assert_string_contains(loaded.result.message, part)


func _assert_valid(provinces_text: String, adjacency_text: String) -> ProvinceLoader.LoadResult:
	var loaded: ProvinceLoader.LoadResult = ProvinceLoader.load_dir(_dir_with(provinces_text, adjacency_text))
	assert_true(loaded.result.ok, "Deveria valer: %s | %s -> %s" % [provinces_text, adjacency_text, loaded.result.message])
	return loaded


func _good_provinces() -> String:
	return "[%s, %s, %s]" % [P_A, P_B, P_BORDER]


func _good_links() -> String:
	return "[%s, %s]" % [L_AB, L_BC]


# ---------------------------------------------------------------- províncias

func test_a_missing_or_unknown_field_is_reported_with_file_item_and_field() -> void:
	_assert_invalid("[%s, %s, %s]" % [P_A.replace(', "kind": "settled"', ""), P_B, P_BORDER], _good_links(), ["provinces.json", "pa", "kind", "campo obrigatório ausente"])
	_assert_invalid("[%s, %s, %s]" % [P_A.replace(', "name_key": "province.pa.name"', ""), P_B, P_BORDER], _good_links(), ["provinces.json", "pa", "name_key", "campo obrigatório ausente"])
	_assert_invalid("[%s, %s, %s]" % [P_A.replace('"kind": "settled"', '"kind": "settled", "owner": "x"'), P_B, P_BORDER], _good_links(), ["provinces.json", "pa", "owner", "campo desconhecido"])


func test_a_wrong_type_a_repeated_id_an_empty_name_and_a_kind_outside_the_vocabulary_are_reported() -> void:
	_assert_invalid("[%s, %s, %s]" % [P_A.replace('"settled"', "3"), P_B, P_BORDER], _good_links(), ["provinces.json", "pa", "kind", "tipo inválido"])
	_assert_invalid("[%s, %s, %s, %s]" % [P_A, P_B, P_BORDER, P_A], _good_links(), ["provinces.json", "pa", "id", "duplicado"])
	_assert_invalid("[%s, %s, %s]" % [P_A.replace('"province.pa.name"', '"  "'), P_B, P_BORDER], _good_links(), ["provinces.json", "pa", "name_key", "vazia"])
	_assert_invalid("[%s, %s, %s]" % [P_A.replace('"settled"', '"capital"'), P_B, P_BORDER], _good_links(), ["provinces.json", "pa", "kind", "'capital' fora do vocabulário", "settled, frontier"])


func test_an_empty_province_list_is_reported() -> void:
	_assert_invalid("[]", "[]", ["provinces.json", "nenhuma província"])


# ---------------------------------------------------------------- adjacência

func test_a_link_to_a_province_that_does_not_exist_is_a_broken_reference() -> void:
	_assert_invalid(_good_provinces(), "[%s, %s]" % [L_AB, L_BC.replace('"province_b_id": "pc"', '"province_b_id": "nowhere"')], ["province_adjacency.json", "pb__pc", "province_b_id", "referência a id inexistente 'nowhere'"])


func test_a_link_from_a_province_to_itself_is_reported() -> void:
	_assert_invalid(_good_provinces(), '[{"id": "pa__pa", "province_a_id": "pa", "province_b_id": "pa"}, %s, %s]' % [L_AB, L_BC], ["province_adjacency.json", "pa__pa", "province_b_id", "com ela mesma"])


func test_a_repeated_pair_is_reported_also_when_it_comes_inverted() -> void:
	_assert_invalid(_good_provinces(), "[%s, %s, %s]" % [L_AB, L_BC, L_AB.replace('"id": "pa__pb"', '"id": "outra"')], ["province_adjacency.json", "outra", "province_b_id", "já existe na linha 'pa__pb'", "sem direção"])
	var inverted: String = '{"id": "pb__pa", "province_a_id": "pb", "province_b_id": "pa"}'
	_assert_invalid(_good_provinces(), "[%s, %s, %s]" % [L_AB, L_BC, inverted], ["province_adjacency.json", "pb__pa", "province_b_id", "o par invertido também conta como repetido"])


func test_ends_out_of_alphabetical_order_and_an_id_that_does_not_match_the_columns_are_reported() -> void:
	var inverted: String = '{"id": "pb__pa", "province_a_id": "pb", "province_b_id": "pa"}'
	_assert_invalid(_good_provinces(), "[%s, %s]" % [inverted, L_BC], ["province_adjacency.json", "pb__pa", "province_a_id", "ordem alfabética"])
	_assert_invalid(_good_provinces(), "[%s, %s]" % [L_AB.replace('"id": "pa__pb"', '"id": "ab"'), L_BC], ["province_adjacency.json", "ab", "id", "o id não bate com as colunas", "pa__pb"])


func test_a_graph_that_is_not_connected_is_reported() -> void:
	_assert_invalid(_good_provinces(), "[%s]" % L_AB, ["province_adjacency.json", "pc", "grafo não conectado"])
	_assert_invalid(_good_provinces(), "[]", ["province_adjacency.json", "grafo não conectado"])


func test_a_single_province_needs_no_links_and_the_graph_is_connected() -> void:
	var loaded: ProvinceLoader.LoadResult = _assert_valid("[%s]" % P_A, "[]")
	assert_eq([loaded.provinces.size(), loaded.links.size()], [1, 0])


# ---------------------------------------------------------------- arquivo

func test_malformed_json_and_missing_files_are_reported() -> void:
	_assert_invalid("[{", _good_links(), ["provinces.json", "JSON inválido"])
	_assert_invalid(_good_provinces(), "not json", ["province_adjacency.json", "JSON inválido"])
	var missing: ProvinceLoader.LoadResult = ProvinceLoader.load_dir(MISSING_DIR)
	assert_false(missing.result.ok)
	for part: String in ["provinces.json", "province_adjacency.json", "arquivo não encontrado"]:
		assert_string_contains(missing.result.message, part)


func test_a_fourth_province_added_only_by_data_loads_without_any_code_change() -> void:
	var extra: String = '{"id": "pd", "name_key": "province.pd.name", "kind": "frontier"}'
	var link: String = '{"id": "pc__pd", "province_a_id": "pc", "province_b_id": "pd"}'
	var loaded: ProvinceLoader.LoadResult = _assert_valid("[%s, %s, %s, %s]" % [P_A, P_B, P_BORDER, extra], "[%s, %s, %s]" % [L_AB, L_BC, link])
	var service: ProvinceService = ProvinceService.new(loaded.provinces, loaded.links)
	assert_eq([service.peek_provinces().provinces.size(), service.peek_adjacent_provinces("pd").provinces[0].id], [4, "pc"])
