extends GutTest
## LW-118c: a ligação povoado → província e povoado → cultura (colunas `province_id` e `culture_id` de data/world/settlements.json; docs/modules/world.md, "Extensão da Fase 4"). O arquivo real: todo
## povoado pertence a uma província, o C está na `province_c` (a fronteira não tem povoado) e cada povoado tem a sua cultura (A e B mercantil, C tradicional; PROPOSTA). `peek_province_of` e
## `peek_culture_of` devolvem cópias e erro tratado; o `SettlementProvinceCheck` falha apontando arquivo, item e campo (povoado sem província ou cultura, referência quebrada, `settled` sem povoado,
## `frontier` com povoado). As colunas são opcionais no `SettlementLoader` (arquivos sem elas seguem valendo); quem as exige é a conferência. Conteúdo: nada disto é salvo.

const WORLD_DIR: String = "res://data/world"
const TOWNS: Array[String] = ["test_settlement_a", "test_settlement_b", "test_settlement_c"]

var _settlements: Array[Settlement]
var _provinces: ProvinceLoader.LoadResult
var _cultures: CultureLoader.LoadResult
var _province_service: ProvinceService
var _culture_service: CultureService


func before_each() -> void:
	var terrain: TerrainLoader.LoadResult = TerrainLoader.load_dir(WORLD_DIR)
	assert_true(terrain.result.ok, terrain.result.message)
	var settlements: SettlementLoader.LoadResult = SettlementLoader.load_dir(WORLD_DIR, terrain.terrain)
	assert_true(settlements.result.ok, settlements.result.message)
	_settlements = settlements.settlements
	_provinces = ProvinceLoader.load_dir(WORLD_DIR)
	_cultures = CultureLoader.load_dir(WORLD_DIR)
	assert_true(_provinces.result.ok and _cultures.result.ok, _provinces.result.message + _cultures.result.message)
	_province_service = ProvinceService.new(_provinces.provinces, _provinces.links, _settlements)
	_culture_service = CultureService.new(_cultures.cultures, _settlements)


func _settlement(settlement_id: String, province_id: String, culture_id: String) -> Settlement:
	return Settlement.new(settlement_id, "k.%s" % settlement_id, Vector3.ZERO, province_id, culture_id)


func _province(province_id: String, kind: String) -> Province:
	return Province.new(province_id, "k.%s" % province_id, kind)


func _culture(culture_id: String) -> Culture:
	return Culture.new(culture_id, "k.%s" % culture_id, 50, 50, 50, 50)


func _check(provinces: Array[Province], settlements: Array[Settlement], cultures: Array[Culture]) -> Result:
	return SettlementProvinceCheck.check(WORLD_DIR, provinces, settlements, cultures)


func _assert_invalid(result: Result, parts: Array[String]) -> void:
	assert_false(result.ok)
	assert_eq(result.code, ProvinceLoader.CODE_INVALID)
	for part: String in parts:
		assert_string_contains(result.message, part)


# ---------------------------------------------------------------- o arquivo real

func test_the_real_data_passes_the_check_and_every_settlement_belongs_to_a_province_and_a_culture() -> void:
	assert_true(_check(_provinces.provinces, _settlements, _cultures.cultures).ok)
	assert_eq(_settlements.size(), 3)
	for settlement: Settlement in _settlements:
		assert_ne(settlement.province_id, "", "%s tem província." % settlement.id)
		assert_ne(settlement.culture_id, "", "%s tem cultura." % settlement.id)
	assert_eq(_province_service.validate(), [] as Array[String])
	assert_eq(_culture_service.validate(), [] as Array[String])


func test_each_settlement_is_in_its_own_province_and_the_border_has_none() -> void:
	var expected: Dictionary[String, String] = {"test_settlement_a": "province_a", "test_settlement_b": "province_b", "test_settlement_c": "province_c"}
	for settlement_id: String in TOWNS:
		var query: ProvinceService.ProvinceQuery = _province_service.peek_province_of(settlement_id)
		assert_true(query.result.ok, query.result.message)
		assert_eq(query.province.id, expected[settlement_id], "Província de %s." % settlement_id)
		assert_eq(query.settlement_ids, [settlement_id] as Array[String], "Uma província por povoado (DEC-207).")
	assert_eq(_province_service.peek_province("province_border").settlement_ids, [] as Array[String], "A fronteira não tem povoado.")
	assert_eq(_province_service.peek_province("province_c").province.kind, Province.KIND_SETTLED, "O C está numa província com povoado.")


func test_the_culture_of_each_settlement_is_a_and_b_trade_and_c_tradition() -> void:
	var expected: Dictionary[String, String] = {"test_settlement_a": "culture_trade", "test_settlement_b": "culture_trade", "test_settlement_c": "culture_tradition"}
	for settlement_id: String in TOWNS:
		var query: CultureService.CultureQuery = _culture_service.peek_culture_of(settlement_id)
		assert_true(query.result.ok, query.result.message)
		assert_eq(query.culture.id, expected[settlement_id], "Cultura de %s." % settlement_id)
	assert_eq(_culture_service.peek_culture("culture_trade").culture.trade_openness, 80)
	assert_eq(_culture_service.peek_cultures().cultures.size(), 2)
	assert_eq([_culture_service.peek_cultures().cultures[0].id, _culture_service.peek_cultures().cultures[1].id], ["culture_trade", "culture_tradition"], "Em ordem crescente de id.")


func test_the_answers_are_copies() -> void:
	var province: ProvinceService.ProvinceQuery = _province_service.peek_province_of("test_settlement_a")
	province.province.kind = Province.KIND_FRONTIER
	province.settlement_ids.clear()
	var again: ProvinceService.ProvinceQuery = _province_service.peek_province_of("test_settlement_a")
	assert_eq([again.province.kind, again.settlement_ids], [Province.KIND_SETTLED, ["test_settlement_a"] as Array[String]])
	var culture: CultureService.CultureQuery = _culture_service.peek_culture_of("test_settlement_a")
	culture.culture.trade_openness = 1
	assert_eq(_culture_service.peek_culture_of("test_settlement_a").culture.trade_openness, 80)
	var listed: Array[Culture] = _culture_service.peek_cultures().cultures
	listed.clear()
	assert_eq(_culture_service.peek_cultures().cultures.size(), 2)


func test_unknown_ids_are_handled_errors_with_their_codes() -> void:
	var no_town: ProvinceService.ProvinceQuery = _province_service.peek_province_of("nowhere")
	assert_eq(no_town.result.code, SettlementService.CODE_SETTLEMENT_UNKNOWN)
	assert_string_contains(no_town.result.message, "'nowhere'")
	assert_eq(_culture_service.peek_culture_of("nowhere").result.code, SettlementService.CODE_SETTLEMENT_UNKNOWN)
	var no_culture: CultureService.CultureQuery = _culture_service.peek_culture("nowhere")
	assert_eq(no_culture.result.code, CultureService.CODE_CULTURE_UNKNOWN)
	assert_string_contains(no_culture.result.message, "culture_trade, culture_tradition")
	assert_null(no_culture.culture)
	var orphan: Array[Settlement] = [_settlement("lost", "nowhere", "nowhere")]
	var odd_provinces: ProvinceService = ProvinceService.new(_provinces.provinces, _provinces.links, orphan)
	var odd_cultures: CultureService = CultureService.new(_cultures.cultures, orphan)
	assert_eq(odd_provinces.peek_province_of("lost").result.code, ProvinceService.CODE_PROVINCE_UNKNOWN, "Povoado cuja província não existe.")
	assert_eq(odd_cultures.peek_culture_of("lost").result.code, CultureService.CODE_CULTURE_UNKNOWN, "Povoado cuja cultura não existe.")
	assert_eq([odd_provinces.validate().size(), odd_cultures.validate().size()], [1, 1], "Os dois serviços acusam o povoado órfão.")


func test_the_settlement_loader_keeps_working_without_the_new_columns_and_carries_them_when_present() -> void:
	var bare: Settlement = Settlement.new("x", "k.x", Vector3.ZERO)
	assert_eq([bare.province_id, bare.culture_id], ["", ""], "Sem as colunas: vazias.")
	assert_eq([_settlements[0].province_id, _settlements[0].culture_id], ["province_a", "culture_trade"], "Com as colunas: as do arquivo.")


# ---------------------------------------------------------------- a conferência

func test_a_settlement_without_province_or_culture_is_reported_with_file_item_and_field() -> void:
	var provinces: Array[Province] = [_province("p1", Province.KIND_SETTLED)]
	var cultures: Array[Culture] = [_culture("c1")]
	_assert_invalid(_check(provinces, [_settlement("town", "", "c1")], cultures), ["settlements.json", "town", "province_id", "campo obrigatório ausente"])
	_assert_invalid(_check(provinces, [_settlement("town", "p1", "")], cultures), ["settlements.json", "town", "culture_id", "campo obrigatório ausente"])


func test_a_broken_reference_is_reported_with_the_known_ids() -> void:
	var provinces: Array[Province] = [_province("p1", Province.KIND_SETTLED), _province("p2", Province.KIND_FRONTIER)]
	var cultures: Array[Culture] = [_culture("c1")]
	_assert_invalid(_check(provinces, [_settlement("town", "p9", "c1")], cultures), ["settlements.json", "town", "province_id", "referência a id inexistente 'p9'", "p1, p2"])
	_assert_invalid(_check(provinces, [_settlement("town", "p1", "c9")], cultures), ["settlements.json", "town", "culture_id", "referência a id inexistente 'c9'", "c1"])


func test_a_settled_province_without_settlement_and_a_frontier_with_one_are_reported() -> void:
	var cultures: Array[Culture] = [_culture("c1")]
	var two: Array[Province] = [_province("p1", Province.KIND_SETTLED), _province("p2", Province.KIND_SETTLED)]
	_assert_invalid(_check(two, [_settlement("town", "p1", "c1")], cultures), ["provinces.json", "p2", "kind", "'settled' sem povoado"])
	var border: Array[Province] = [_province("p1", Province.KIND_SETTLED), _province("p2", Province.KIND_FRONTIER)]
	_assert_invalid(_check(border, [_settlement("town", "p1", "c1"), _settlement("camp", "p2", "c1")], cultures), ["provinces.json", "p2", "kind", "'frontier' com 1 povoado"])


func test_several_problems_come_together_and_a_valid_world_with_one_of_each_passes() -> void:
	var provinces: Array[Province] = [_province("p1", Province.KIND_SETTLED), _province("p2", Province.KIND_FRONTIER)]
	var cultures: Array[Culture] = [_culture("c1")]
	assert_true(_check(provinces, [_settlement("town", "p1", "c1")], cultures).ok)
	var bad: Array[Settlement] = [_settlement("a", "", ""), _settlement("b", "p9", "c9")]
	var result: Result = _check(provinces, bad, cultures)
	_assert_invalid(result, ["'a'", "'b'", "province_id", "culture_id", "'p1'"])
