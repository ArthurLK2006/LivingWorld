extends GutTest
## LW-118b: as quatro províncias (DEC-207: uma por povoado e uma de fronteira) e a adjacência (data/world/provinces.json e province_adjacency.json), pelo `ProvinceLoader` e pelo
## `ProvinceService` (docs/modules/world.md, "Extensão da Fase 4"). O arquivo real carrega; as consultas devolvem cópias em ordem crescente de `id`; o grafo é coerente (sem direção) e conexo, e A e B
## só chegam a C pela fronteira; consulta de província desconhecida é erro tratado com o código `PROVINCE_UNKNOWN`. Os povoados de cada província entram na LW-118c. Conteúdo: nada disto é salvo.

const REAL_DIR: String = "res://data/world"
const IDS: Array[String] = ["province_a", "province_b", "province_border", "province_c"]

var _loaded: ProvinceLoader.LoadResult
var _service: ProvinceService


func before_each() -> void:
	_loaded = ProvinceLoader.load_dir(REAL_DIR)
	assert_true(_loaded.result.ok, _loaded.result.message)
	_service = ProvinceService.new(_loaded.provinces, _loaded.links)


func _ids(provinces: Array[Province]) -> Array[String]:
	var ids: Array[String] = []
	for province: Province in provinces:
		ids.append(province.id)
	return ids


func test_the_real_files_have_the_four_provinces_of_dec_207_with_the_right_kinds() -> void:
	assert_eq(_loaded.provinces.size(), 4, "DEC-207: quatro províncias.")
	assert_eq(_ids(_service.peek_provinces().provinces), IDS, "Em ordem crescente de id, não na ordem do arquivo.")
	var kinds: Array[String] = []
	for province_id: String in IDS:
		kinds.append(_service.peek_province(province_id).province.kind)
	assert_eq(kinds, [Province.KIND_SETTLED, Province.KIND_SETTLED, Province.KIND_FRONTIER, Province.KIND_SETTLED] as Array[String], "A, B e C têm povoado; a fronteira não.")


func test_the_adjacency_is_the_starting_proposal_and_a_and_b_reach_c_only_through_the_border() -> void:
	assert_eq(_loaded.links.size(), 4)
	var expected: Dictionary[String, Array] = {
		"province_a": ["province_b", "province_border"],
		"province_b": ["province_a", "province_border"],
		"province_border": ["province_a", "province_b", "province_c"],
		"province_c": ["province_border"],
	}
	for province_id: String in IDS:
		assert_eq(_ids(_service.peek_adjacent_provinces(province_id).provinces), expected[province_id] as Array[String], "Vizinhas de %s." % province_id)


func test_the_adjacency_has_no_direction_and_the_graph_is_connected() -> void:
	for province_id: String in IDS:
		for neighbor: Province in _service.peek_adjacent_provinces(province_id).provinces:
			assert_true(_ids(_service.peek_adjacent_provinces(neighbor.id).provinces).has(province_id), "%s é vizinha de %s nos dois sentidos." % [province_id, neighbor.id])
			assert_ne(neighbor.id, province_id, "Nenhuma província é vizinha de si mesma.")
	var reached: Dictionary[String, bool] = {IDS[0]: true}
	var to_visit: Array[String] = [IDS[0]]
	while not to_visit.is_empty():
		var current: String = to_visit.pop_back()
		for neighbor: Province in _service.peek_adjacent_provinces(current).provinces:
			if not reached.has(neighbor.id):
				reached[neighbor.id] = true
				to_visit.append(neighbor.id)
	assert_eq(reached.size(), IDS.size(), "De qualquer província se chega a todas as outras.")


func test_the_answers_are_copies_and_changing_one_changes_nothing() -> void:
	var first: ProvinceService.ProvinceQuery = _service.peek_province("province_a")
	first.province.kind = Province.KIND_FRONTIER
	first.province.name_key = "x"
	var again: Province = _service.peek_province("province_a").province
	assert_eq([again.kind, again.name_key], [Province.KIND_SETTLED, "province.province_a.name"], "A consulta devolve cópia.")
	var listed: Array[Province] = _service.peek_provinces().provinces
	listed.clear()
	assert_eq(_service.peek_provinces().provinces.size(), 4)
	var neighbors: Array[Province] = _service.peek_adjacent_provinces("province_border").provinces
	neighbors[0].kind = Province.KIND_FRONTIER
	assert_eq(_service.peek_province(neighbors[0].id).province.kind, Province.KIND_SETTLED)


func test_an_unknown_province_is_a_handled_error_with_the_code_and_the_known_ids() -> void:
	for query: Variant in [_service.peek_province("nowhere").result, _service.peek_adjacent_provinces("nowhere").result]:
		var result: Result = query
		assert_false(result.ok)
		assert_eq(result.code, ProvinceService.CODE_PROVINCE_UNKNOWN)
		assert_string_contains(result.message, "'nowhere'")
		assert_string_contains(result.message, "province_a, province_b, province_border, province_c")
	assert_null(_service.peek_province("nowhere").province)
	assert_eq(_service.peek_adjacent_provinces("nowhere").provinces.size(), 0)


func test_the_answers_do_not_depend_on_the_order_the_content_was_given() -> void:
	var provinces: Array[Province] = []
	var links: Array[ProvinceLink] = []
	for index: int in range(_loaded.provinces.size() - 1, -1, -1):
		provinces.append(_loaded.provinces[index])
	for index: int in range(_loaded.links.size() - 1, -1, -1):
		links.append(_loaded.links[index])
	var reversed: ProvinceService = ProvinceService.new(provinces, links)
	assert_eq(_ids(reversed.peek_provinces().provinces), IDS)
	for province_id: String in IDS:
		assert_eq(_ids(reversed.peek_adjacent_provinces(province_id).provinces), _ids(_service.peek_adjacent_provinces(province_id).provinces))


func test_the_service_reports_a_repeated_province_and_a_link_to_a_province_that_does_not_exist() -> void:
	assert_eq(_service.validate(), [] as Array[String], "O conteúdo real não tem inconsistência.")
	var provinces: Array[Province] = [Province.new("p1", "k.p1", Province.KIND_SETTLED), Province.new("p1", "k.p1", Province.KIND_SETTLED), Province.new("p2", "k.p2", Province.KIND_FRONTIER)]
	var links: Array[ProvinceLink] = [ProvinceLink.new("p1__p2", "p1", "p2"), ProvinceLink.new("p1__p9", "p1", "p9")]
	var odd: ProvinceService = ProvinceService.new(provinces, links)
	var problems: Array[String] = odd.validate()
	assert_eq(problems.size(), 2)
	assert_string_contains(problems[0], "'p1' repetida")
	assert_string_contains(problems[1], "'p9'")
	assert_eq(_ids(odd.peek_adjacent_provinces("p1").provinces), ["p2"] as Array[String], "A ligação boa continua valendo.")


func test_the_province_names_exist_in_the_text_file_and_differ() -> void:
	var texts: UiText.LoadResult = UiText.from_file(UiText.DEFAULT_PATH)
	assert_true(texts.result.ok, texts.result.message)
	var names: Array[String] = []
	for province: Province in _loaded.provinces:
		assert_true(texts.texts.has_key(province.name_key), "Falta a chave '%s' em data/text/pt_br.json." % province.name_key)
		names.append(texts.texts.get_text(province.name_key))
	for index: int in names.size():
		assert_eq(names.count(names[index]), 1, "Os nomes são todos diferentes.")
