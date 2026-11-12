extends GutTest
## LW-118a: as duas culturas genéricas e contrastantes (DEC-203; data/world/cultures.json) e o `CultureLoader` (docs/modules/world.md, "Extensão da Fase 4"). Aqui: o arquivo real (as duas culturas, os
## quatro parâmetros de cada uma com os valores [HIP] escritos à mão, os nomes no arquivo de texto) e o arquivo inválido, que falha apontando arquivo, item e campo (campo ausente, desconhecido, tipo
## errado, fora da faixa 0 a 100 com as bordas válidas, id repetido, nome vazio, lista vazia, JSON malformado e arquivo ausente). Uma cultura nova entra só por dado.

const REAL_DIR: String = "res://data/world"
const MISSING_DIR: String = "res://tests/fixtures/world/pasta_que_nao_existe"
const TRADE: String = '{"id": "culture_trade", "name_key": "culture.culture_trade.name", "trade_openness": 80, "foreigner_tolerance": 60, "martial_stance": 30, "authority_weight": 40}'
const TRADITION: String = '{"id": "culture_tradition", "name_key": "culture.culture_tradition.name", "trade_openness": 30, "foreigner_tolerance": 25, "martial_stance": 65, "authority_weight": 75}'

var _temp_dirs: Array[DirAccess] = []


func after_each() -> void:
	for dir: DirAccess in _temp_dirs:
		for file_name: String in dir.get_files():
			dir.remove(file_name)
		DirAccess.remove_absolute(dir.get_current_dir())
	_temp_dirs.clear()


func _dir_with(cultures_text: String) -> String:
	var dir: DirAccess = DirAccess.create_temp("lw118a")
	_temp_dirs.append(dir)
	var file: FileAccess = FileAccess.open(dir.get_current_dir().path_join(CultureLoader.DEFAULT_CULTURES_FILE), FileAccess.WRITE)
	file.store_string(cultures_text)
	file.close()
	return dir.get_current_dir()


func _assert_invalid(cultures_text: String, expected_parts: Array[String]) -> void:
	var loaded: CultureLoader.LoadResult = CultureLoader.load_dir(_dir_with(cultures_text))
	assert_false(loaded.result.ok, "Arquivo inválido deveria falhar: " + cultures_text)
	assert_eq(loaded.result.code, CultureLoader.CODE_INVALID)
	assert_eq(loaded.cultures.size(), 0, "Falha não devolve cultura.")
	for part: String in expected_parts:
		assert_string_contains(loaded.result.message, part)


func _assert_valid(cultures_text: String) -> void:
	var loaded: CultureLoader.LoadResult = CultureLoader.load_dir(_dir_with(cultures_text))
	assert_true(loaded.result.ok, "Deveria valer: %s -> %s" % [cultures_text, loaded.result.message])


func _values(culture: Culture) -> Array[int]:
	return [culture.trade_openness, culture.foreigner_tolerance, culture.martial_stance, culture.authority_weight]


# ---------------------------------------------------------------- o arquivo real

func test_the_real_file_has_the_two_cultures_with_the_four_parameters_in_the_file_order() -> void:
	var loaded: CultureLoader.LoadResult = CultureLoader.load_dir(REAL_DIR)
	assert_true(loaded.result.ok, loaded.result.message)
	assert_eq(loaded.cultures.size(), 2, "DEC-203: duas culturas.")
	assert_eq([loaded.cultures[0].id, loaded.cultures[1].id], ["culture_trade", "culture_tradition"])
	assert_eq(_values(loaded.cultures[0]), [80, 60, 30, 40] as Array[int], "A mercantil [HIP].")
	assert_eq(_values(loaded.cultures[1]), [30, 25, 65, 75] as Array[int], "A tradicional [HIP].")


func test_the_two_cultures_contrast_and_every_parameter_is_inside_zero_to_one_hundred() -> void:
	var loaded: CultureLoader.LoadResult = CultureLoader.load_dir(REAL_DIR)
	var trade: Culture = loaded.cultures[0]
	var tradition: Culture = loaded.cultures[1]
	assert_gt(trade.trade_openness, tradition.trade_openness, "A mercantil é mais aberta ao comércio.")
	assert_gt(trade.foreigner_tolerance, tradition.foreigner_tolerance, "E mais tolerante com o estrangeiro.")
	assert_gt(tradition.martial_stance, trade.martial_stance, "A tradicional é mais ofensiva.")
	assert_gt(tradition.authority_weight, trade.authority_weight, "E mais centralizada.")
	for culture: Culture in loaded.cultures:
		for value: int in _values(culture):
			assert_true(value >= Culture.MIN_PARAMETER and value <= Culture.MAX_PARAMETER, "%s: parâmetro dentro da faixa." % culture.id)


func test_the_culture_names_exist_in_the_text_file_and_differ() -> void:
	var loaded: CultureLoader.LoadResult = CultureLoader.load_dir(REAL_DIR)
	var texts: UiText.LoadResult = UiText.from_file(UiText.DEFAULT_PATH)
	assert_true(texts.result.ok, texts.result.message)
	for culture: Culture in loaded.cultures:
		assert_true(texts.texts.has_key(culture.name_key), "Falta a chave '%s' em data/text/pt_br.json." % culture.name_key)
	assert_ne(texts.texts.get_text(loaded.cultures[0].name_key), texts.texts.get_text(loaded.cultures[1].name_key))


func test_loading_twice_gives_the_same_cultures() -> void:
	var first: CultureLoader.LoadResult = CultureLoader.load_dir(REAL_DIR)
	var second: CultureLoader.LoadResult = CultureLoader.load_dir(REAL_DIR)
	assert_eq(first.cultures.size(), second.cultures.size())
	for index: int in first.cultures.size():
		assert_eq([first.cultures[index].id, _values(first.cultures[index])], [second.cultures[index].id, _values(second.cultures[index])])


# ---------------------------------------------------------------- arquivo inválido

func test_a_missing_or_unknown_field_is_reported_with_file_item_and_field() -> void:
	_assert_invalid("[%s]" % TRADE.replace(', "martial_stance": 30', ""), ["cultures.json", "culture_trade", "martial_stance", "campo obrigatório ausente"])
	_assert_invalid("[%s]" % TRADE.replace(', "name_key": "culture.culture_trade.name"', ""), ["cultures.json", "culture_trade", "name_key", "campo obrigatório ausente"])
	_assert_invalid("[%s]" % TRADE.replace('"authority_weight": 40', '"authority_weight": 40, "color": "red"'), ["cultures.json", "culture_trade", "color", "campo desconhecido"])


func test_a_wrong_type_is_reported() -> void:
	_assert_invalid("[%s]" % TRADE.replace('"trade_openness": 80', '"trade_openness": 80.5'), ["cultures.json", "culture_trade", "trade_openness", "tipo inválido"])
	_assert_invalid("[%s]" % TRADE.replace('"foreigner_tolerance": 60', '"foreigner_tolerance": "alta"'), ["cultures.json", "culture_trade", "foreigner_tolerance", "tipo inválido"])
	_assert_invalid("[%s]" % TRADE.replace('"culture.culture_trade.name"', "7"), ["cultures.json", "culture_trade", "name_key", "tipo inválido"])


func test_a_parameter_outside_zero_to_one_hundred_is_reported_and_the_edges_are_valid() -> void:
	_assert_invalid("[%s]" % TRADE.replace('"martial_stance": 30', '"martial_stance": 101'), ["cultures.json", "culture_trade", "martial_stance", "acima do máximo"])
	_assert_invalid("[%s]" % TRADE.replace('"authority_weight": 40', '"authority_weight": -1'), ["cultures.json", "culture_trade", "authority_weight", "abaixo do mínimo"])
	_assert_valid("[%s]" % TRADE.replace('"martial_stance": 30', '"martial_stance": 0').replace('"trade_openness": 80', '"trade_openness": 100'))


func test_a_repeated_id_an_empty_name_and_an_empty_list_are_reported() -> void:
	_assert_invalid("[%s, %s]" % [TRADE, TRADE], ["cultures.json", "culture_trade", "id", "duplicado"])
	_assert_invalid("[%s]" % TRADE.replace('"culture.culture_trade.name"', '"  "'), ["cultures.json", "culture_trade", "name_key", "vazia"])
	_assert_invalid("[]", ["cultures.json", "nenhuma cultura"])


func test_malformed_json_and_a_missing_file_are_reported() -> void:
	_assert_invalid("[{", ["cultures.json", "JSON inválido"])
	var missing: CultureLoader.LoadResult = CultureLoader.load_dir(MISSING_DIR)
	assert_false(missing.result.ok)
	assert_string_contains(missing.result.message, "cultures.json")
	assert_string_contains(missing.result.message, "arquivo não encontrado")


func test_a_third_culture_added_only_by_data_loads_without_any_code_change() -> void:
	var third: String = TRADE.replace("culture_trade", "culture_extra").replace("80", "55")
	var loaded: CultureLoader.LoadResult = CultureLoader.load_dir(_dir_with("[%s, %s, %s]" % [TRADE, TRADITION, third]))
	assert_true(loaded.result.ok, loaded.result.message)
	assert_eq([loaded.cultures.size(), loaded.cultures[2].id, loaded.cultures[2].trade_openness], [3, "culture_extra", 55])
