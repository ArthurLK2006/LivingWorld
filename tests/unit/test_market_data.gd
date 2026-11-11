extends GutTest
## LW-090: os dados dos mercados (data/economy/market_targets.json e price_params.json) e o `MarketLoader` (docs/economy/dados.md). Aqui: o arquivo real (dois povoados, os 10 bens em cada, o estoque inicial dentro do teto e
## do peso do mercado, as constantes de preço) e o dado inválido, que falha apontando arquivo, item e campo. Valores esperados escritos à mão; os [HIP] só são conferidos quanto à faixa.

const DATA_DIR: String = "res://data/economy"
const SETTLEMENTS: Array[String] = ["test_settlement_a", "test_settlement_b"]


func _tables() -> Dictionary[String, Array]:
	var bundle: DataBundle = DataLoader.load_all(DATA_DIR, MarketLoader.build_schemas())
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


func _expect_failure(label: String, tables: Dictionary[String, Array], fragments: Array[String]) -> void:
	var loaded: MarketLoader.LoadResult = MarketLoader.from_tables(tables, DATA_DIR)
	assert_false(loaded.result.ok, "%s: deveria falhar." % label)
	assert_eq(loaded.result.code, EconomyCodes.DATA_INVALID, label)
	assert_true(loaded.targets.is_empty() and loaded.params == null, "%s: falha não devolve definição." % label)
	for fragment: String in fragments:
		assert_string_contains(loaded.result.message, fragment, "%s: a mensagem deveria citar '%s'." % [label, fragment])


func test_the_real_data_has_every_good_in_both_markets_inside_the_cap_and_the_capacity() -> void:
	var loaded: MarketLoader.LoadResult = MarketLoader.load_dir(DATA_DIR)
	assert_true(loaded.result.ok, loaded.result.message)
	var goods: GoodsLoader.LoadResult = GoodsLoader.load_dir(DATA_DIR)
	var weights: Dictionary[String, int] = {}
	for good: GoodDef in goods.goods:
		weights[good.id] = good.weight
	var market_capacity: int = 0
	for kind: OwnerKindDef in goods.kinds:
		if kind.id == "market":
			market_capacity = kind.weight_capacity
	assert_eq(loaded.targets.size(), 20, "Dois povoados com os 10 bens cada (o 3º povoado é da LW-097).")
	for settlement_id: String in SETTLEMENTS:
		var seen: Array[String] = []
		var initial_weight: int = 0
		var cap_weight: int = 0
		for target: MarketTargetDef in loaded.targets:
			if target.settlement_id != settlement_id:
				continue
			seen.append(target.good_id)
			assert_true(target.target_stock > 0, "%s negocia %s." % [settlement_id, target.good_id])
			assert_true(target.initial_stock <= target.buy_cap(), "%s/%s: estoque inicial dentro do teto de compra." % [settlement_id, target.good_id])
			assert_eq(target.id, "mt_%s_%s" % [settlement_id, target.good_id])
			initial_weight += target.initial_stock * weights[target.good_id]
			cap_weight += target.buy_cap() * weights[target.good_id]
		assert_eq(seen.size(), 10, "%s: os 10 bens." % settlement_id)
		assert_true(initial_weight <= market_capacity and cap_weight <= market_capacity, "%s: estoque inicial e teto cabem na capacidade do mercado (%d)." % [settlement_id, market_capacity])
	var imported: Dictionary[String, int] = {}
	for target: MarketTargetDef in loaded.targets:
		imported["%s/%s" % [target.settlement_id, target.good_id]] = target.initial_stock
	assert_eq([imported["test_settlement_a/tool"], imported["test_settlement_a/fabric"], imported["test_settlement_b/tool"], imported["test_settlement_b/plank"]], [29, 25, 29, 21], "Os bens importados de 30 dias da tabela de dados.md.")


func test_the_real_price_constants_follow_the_documented_ranges() -> void:
	var params: PriceParams = MarketLoader.load_dir(DATA_DIR).params
	assert_eq([params.min_factor_bp, params.max_factor_bp], [5000, 30000], "O piso 0,5 e o teto 3 vezes do GDD 12.3.")
	assert_true(params.min_factor_bp <= params.max_factor_bp)
	assert_true(params.spread_bp >= 1 and params.spread_bp <= 20000, "`spread_bp` de 1 a 20000.")
	assert_true(params.shortage_days >= 1 and params.shortage_days < 60, "A escassez é declarada bem antes dos 60 dias sem produtor.")
	assert_true(params.max_order_quantity >= 1 and params.history_days >= 1)


func test_invalid_market_targets_are_refused_pointing_at_file_item_and_field() -> void:
	var item: String = "mt_test_settlement_a_bread"
	var cases: Array[Dictionary] = [
		{"label": "campo ausente", "erase": "buy_cap_bp", "expect": ["market_targets.json", "item '%s'" % item, "campo 'buy_cap_bp'", "obrigatório ausente"]},
		{"label": "bem inexistente", "set": {"good_id": "gold"}, "expect": ["item '%s'" % item, "campo 'good_id'", "'gold' na tabela 'goods'"]},
		{"label": "alvo negativo", "set": {"target_stock": -1}, "expect": ["item '%s'" % item, "campo 'target_stock'"]},
		{"label": "teto abaixo de 10000", "set": {"buy_cap_bp": 9999}, "expect": ["item '%s'" % item, "campo 'buy_cap_bp'"]},
		{"label": "estoque inicial acima do teto", "set": {"initial_stock": 121}, "expect": ["item '%s'" % item, "campo 'initial_stock'", "acima do teto de compra 120"]},
		{"label": "par repetido", "set": {"good_id": "grain"}, "expect": ["item '%s'" % item, "campo 'good_id'", "esperada uma linha por par"]},
		{"label": "campo desconhecido", "set": {"note": 1}, "expect": ["item '%s'" % item, "campo 'note'", "campo desconhecido"]},
	]
	for test_case: Dictionary in cases:
		var tables: Dictionary[String, Array] = _tables()
		var row: Dictionary = _row(tables, "market_targets", item)
		if test_case.has("erase"):
			row.erase(test_case["erase"])
		else:
			row.merge(test_case["set"], true)
		var fragments: Array[String] = []
		fragments.assign(test_case["expect"])
		_expect_failure(test_case["label"], tables, fragments)
	var silent: Dictionary[String, Array] = _tables()
	for record: Dictionary in silent["market_targets"]:
		if record["settlement_id"] == "test_settlement_b":
			record["target_stock"] = 0
			record["initial_stock"] = 0
	_expect_failure("povoado que não negocia nada", silent, ["market_targets.json", "o assentamento 'test_settlement_b' não negocia nenhum bem"])


func test_invalid_price_constants_are_refused_pointing_at_file_item_and_field() -> void:
	var cases: Array[Dictionary] = [
		{"label": "piso maior que o teto", "set": {"min_factor_bp": 40000}, "expect": ["price_params.json", "item 'price_defaults'", "campo 'min_factor_bp'", "o piso 40000 é maior que o teto 30000"]},
		{"label": "spread zero", "set": {"spread_bp": 0}, "expect": ["item 'price_defaults'", "campo 'spread_bp'"]},
		{"label": "spread acima de 20000", "set": {"spread_bp": 20001}, "expect": ["item 'price_defaults'", "campo 'spread_bp'"]},
		{"label": "escassez em 60 dias", "set": {"shortage_days": 60}, "expect": ["item 'price_defaults'", "campo 'shortage_days'"]},
		{"label": "ordem máxima zero", "set": {"max_order_quantity": 0}, "expect": ["item 'price_defaults'", "campo 'max_order_quantity'"]},
		{"label": "tipo errado", "set": {"smoothing_bp": "2000"}, "expect": ["item 'price_defaults'", "campo 'smoothing_bp'", "tipo inválido"]},
	]
	for test_case: Dictionary in cases:
		var tables: Dictionary[String, Array] = _tables()
		_row(tables, "price_params", "price_defaults").merge(test_case["set"], true)
		var fragments: Array[String] = []
		fragments.assign(test_case["expect"])
		_expect_failure(test_case["label"], tables, fragments)
	var two: Dictionary[String, Array] = _tables()
	var extra: Dictionary = two["price_params"][0].duplicate(true)
	extra["id"] = "price_other"
	two["price_params"].append(extra)
	_expect_failure("duas linhas", two, ["price_params.json", "esperada exatamente 1 linha de constantes de preço, encontradas 2"])
	var none: Dictionary[String, Array] = _tables()
	none["price_params"] = []
	_expect_failure("nenhuma linha", none, ["esperada exatamente 1 linha", "encontradas 0"])
