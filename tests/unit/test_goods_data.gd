extends GutTest
## LW-089: os dados dos bens e dos tipos de dono (data/economy/goods.json e owner_kinds.json) e o `GoodsLoader` (docs/economy/dados.md). Aqui: o arquivo real (10 bens, 5 tipos, textos por chave), um bem novo só por dado
## (como o ofício da LW-093b) e o dado inválido, que falha apontando arquivo, item e campo. Valores esperados escritos à mão; os [HIP] dos dados reais (valor e peso) só são conferidos quanto à faixa.

const DATA_DIR: String = "res://data/economy"
const TEXT_FILE: String = "res://data/text/pt_br.json"
const GOODS_FILE: String = "goods.json"
const KINDS_FILE: String = "owner_kinds.json"
const GOOD_IDS: Array[String] = ["grain", "flour", "bread", "wood", "plank", "ore", "metal", "tool", "wool", "fabric"]
const KIND_IDS: Array[String] = ["npc", "player", "site", "market", "contract"]


func _tables() -> Dictionary[String, Array]:
	var bundle: DataBundle = DataLoader.load_all(DATA_DIR, GoodsLoader.build_schemas())
	assert_true(bundle.is_valid(), bundle.describe_issues())
	var copy: Dictionary[String, Array] = {}
	for table_id: String in bundle.tables:
		copy[table_id] = bundle.tables[table_id].duplicate(true)
	return copy


func _expect_failure(label: String, tables: Dictionary[String, Array], fragments: Array[String]) -> void:
	var loaded: GoodsLoader.LoadResult = GoodsLoader.from_tables(tables, DATA_DIR)
	assert_false(loaded.result.ok, "%s: deveria falhar." % label)
	assert_eq(loaded.result.code, EconomyCodes.DATA_INVALID, label)
	assert_true(loaded.goods.is_empty() and loaded.kinds.is_empty(), "%s: falha não devolve definição." % label)
	for fragment: String in fragments:
		assert_string_contains(loaded.result.message, fragment, "%s: a mensagem deveria citar '%s'." % [label, fragment])


func _row(tables: Dictionary[String, Array], table_id: String, row_id: String) -> Dictionary:
	for record: Dictionary in tables[table_id]:
		if record["id"] == row_id:
			return record
	fail_test("A linha '%s' não existe em '%s'." % [row_id, table_id])
	return {}


func test_the_real_data_loads_the_ten_goods_and_the_five_owner_kinds() -> void:
	var loaded: GoodsLoader.LoadResult = GoodsLoader.load_dir(DATA_DIR)
	assert_true(loaded.result.ok, loaded.result.message)
	var good_ids: Array[String] = []
	for good: GoodDef in loaded.goods:
		good_ids.append(good.id)
		assert_true(good.base_value >= 1 and good.weight >= 1 and good.perishability_days >= 0, "%s: valor, peso e validade na faixa." % good.id)
		assert_true(GoodDef.CATEGORIES.has(good.category), "%s: categoria do vocabulário." % good.id)
		assert_eq(good.name_key, "good.%s.name" % good.id)
	assert_eq(good_ids, GOOD_IDS, "Os 10 bens do contrato, na ordem do arquivo.")
	var consumable: Dictionary[String, int] = {}
	for good: GoodDef in loaded.goods:
		if good.is_consumable():
			consumable[good.id] = good.need_relief
			assert_eq(good.need_id, "hunger")
	assert_eq(consumable, {"grain": 30, "bread": 60}, "Só o pão e o grão são comida do NPC, e o pão alivia mais (Q9).")
	var kind_ids: Array[String] = []
	for kind: OwnerKindDef in loaded.kinds:
		kind_ids.append(kind.id)
		assert_true(kind.initial_balance >= 0, "%s: saldo inicial não negativo." % kind.id)
		assert_eq(kind.weight_capacity == 0, kind.id == "contract", "Só o contrato não tem inventário (capacidade 0).")
	assert_eq(kind_ids, KIND_IDS)


func test_every_good_has_a_text_key_in_the_text_file() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(TEXT_FILE))
	assert_eq(typeof(parsed), TYPE_DICTIONARY)
	var texts: Dictionary = parsed if typeof(parsed) == TYPE_DICTIONARY else {}
	for good: GoodDef in GoodsLoader.load_dir(DATA_DIR).goods:
		assert_true(texts.has(good.name_key), "A chave '%s' existe em pt_br.json." % good.name_key)
		assert_false(str(texts.get(good.name_key, "")).is_empty(), "%s: o nome não é vazio." % good.name_key)


func test_a_good_added_only_by_data_passes_and_loading_twice_gives_the_same_result() -> void:
	var tables: Dictionary[String, Array] = _tables()
	tables["goods"].append({"id": "salt", "name_key": "good.salt.name", "category": "luxury", "base_value": 9, "weight": 1, "perishability_days": 0})
	var loaded: GoodsLoader.LoadResult = GoodsLoader.from_tables(tables, DATA_DIR)
	assert_true(loaded.result.ok, loaded.result.message)
	assert_eq(loaded.goods.size(), GOOD_IDS.size() + 1)
	assert_eq(loaded.goods[GOOD_IDS.size()].id, "salt", "O bem novo entra depois dos que já existiam.")
	assert_false(loaded.goods[GOOD_IDS.size()].is_consumable())
	var first: GoodsLoader.LoadResult = GoodsLoader.load_dir(DATA_DIR)
	var second: GoodsLoader.LoadResult = GoodsLoader.load_dir(DATA_DIR)
	for index: int in first.goods.size():
		assert_eq([second.goods[index].id, second.goods[index].base_value, second.goods[index].weight], [first.goods[index].id, first.goods[index].base_value, first.goods[index].weight])


func test_an_invalid_good_is_refused_pointing_at_file_item_and_field() -> void:
	var cases: Array[Dictionary] = [
		{"label": "campo ausente", "erase": "weight", "expect": ["item 'bread'", "campo 'weight'", "obrigatório ausente"]},
		{"label": "tipo errado", "set": {"base_value": "10"}, "expect": ["item 'bread'", "campo 'base_value'", "tipo inválido"]},
		{"label": "campo desconhecido", "set": {"flavor": 3}, "expect": ["item 'bread'", "campo 'flavor'", "campo desconhecido"]},
		{"label": "id repetido", "set": {"id": "grain"}, "expect": ["item 'grain'", "campo 'id'", "id duplicado"]},
		{"label": "categoria fora do vocabulário", "set": {"category": "dessert"}, "expect": ["item 'bread'", "campo 'category'", "categoria 'dessert'", "food, raw_material, processed, tool"]},
		{"label": "valor zero", "set": {"base_value": 0}, "expect": ["item 'bread'", "campo 'base_value'"]},
		{"label": "peso zero", "set": {"weight": 0}, "expect": ["item 'bread'", "campo 'weight'"]},
		{"label": "validade negativa", "set": {"perishability_days": -1}, "expect": ["item 'bread'", "campo 'perishability_days'"]},
		{"label": "nome sem chave", "set": {"name_key": "  "}, "expect": ["item 'bread'", "campo 'name_key'", "chave de texto vazia"]},
		{"label": "alívio sem necessidade", "erase": "need_id", "expect": ["item 'bread'", "campo 'need_id'", "vêm juntos ou nenhum"]},
		{"label": "necessidade sem alívio", "erase": "need_relief", "expect": ["item 'bread'", "campo 'need_relief'", "vêm juntos ou nenhum"]},
		{"label": "necessidade vazia", "set": {"need_id": ""}, "expect": ["item 'bread'", "campo 'need_id'", "necessidade vazia"]},
		{"label": "alívio zero", "set": {"need_relief": 0}, "expect": ["item 'bread'", "campo 'need_relief'"]},
	]
	for test_case: Dictionary in cases:
		var tables: Dictionary[String, Array] = _tables()
		var row: Dictionary = _row(tables, "goods", "bread")
		if test_case.has("erase"):
			row.erase(test_case["erase"])
		else:
			row.merge(test_case["set"], true)
		var fragments: Array[String] = [GOODS_FILE]
		fragments.append_array(test_case["expect"])
		_expect_failure(test_case["label"], tables, fragments)


func test_an_invalid_owner_kind_is_refused_pointing_at_file_item_and_field() -> void:
	var cases: Array[Dictionary] = [
		{"label": "capacidade negativa", "set": {"weight_capacity": -1}, "expect": ["item 'npc'", "campo 'weight_capacity'"]},
		{"label": "saldo inicial negativo", "set": {"initial_balance": -5}, "expect": ["item 'npc'", "campo 'initial_balance'"]},
		{"label": "saldo inicial com fração", "set": {"initial_balance": 1.5}, "expect": ["item 'npc'", "campo 'initial_balance'", "tipo inválido"]},
		{"label": "id repetido", "set": {"id": "market"}, "expect": ["item 'market'", "campo 'id'", "id duplicado"]},
		{"label": "campo desconhecido", "set": {"slots": 3}, "expect": ["item 'npc'", "campo 'slots'", "campo desconhecido"]},
	]
	for test_case: Dictionary in cases:
		var tables: Dictionary[String, Array] = _tables()
		_row(tables, "owner_kinds", "npc").merge(test_case["set"], true)
		var fragments: Array[String] = [KINDS_FILE]
		fragments.append_array(test_case["expect"])
		_expect_failure(test_case["label"], tables, fragments)
	var missing: Dictionary[String, Array] = _tables()
	_row(missing, "owner_kinds", "site").erase("initial_balance")
	_expect_failure("campo ausente", missing, [KINDS_FILE, "item 'site'", "campo 'initial_balance'", "obrigatório ausente"])
