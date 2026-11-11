extends GutTest
## LW-089b: o inventário por dono (`GoodsStore`; docs/modules/economy.md, seção 3): criar, destruir e transferir bens com peso e capacidade respeitados, falha sem mudar nada, conservação por bem (com `consumed` e
## `maintenance`), dono fechado que continua na soma e a ida e volta de save. Usa os bens e os tipos de dono REAIS (data/economy). A conservação roda contra um modelo escrito aqui, depois de muitas operações sorteadas.

const WORLD_SEED: int = 23
const STREAM: String = "goods_test"
const OPERATIONS: int = 4000
const OWNER_COUNT: int = 5
const NPC: int = 1
const OTHER_NPC: int = 2
const MARKET: int = 3
const CONTRACT: int = 4
const DEAD_NPC: int = 5


func _loaded() -> GoodsLoader.LoadResult:
	var loaded: GoodsLoader.LoadResult = GoodsLoader.load_dir(GoodsLoader.DEFAULT_DIR)
	assert_true(loaded.result.ok, loaded.result.message)
	return loaded


func _book() -> OwnerBook:
	var book: OwnerBook = OwnerBook.new()
	for owner_id: int in [NPC, OTHER_NPC, DEAD_NPC]:
		assert_true(book.open_owner(owner_id, "npc").ok)
	assert_true(book.open_owner(MARKET, "market").ok)
	assert_true(book.open_owner(CONTRACT, "contract").ok)
	return book


func _store(book: OwnerBook) -> GoodsStore:
	var loaded: GoodsLoader.LoadResult = _loaded()
	return GoodsStore.new(book, loaded.goods, loaded.kinds)


func _snapshot(store: GoodsStore) -> Array:
	var rows: Array = []
	for owner_id: int in range(0, OWNER_COUNT + 2):
		rows.append(store.inventory_rows(owner_id))
	return [rows, store.conservation_rows()]


func test_create_destroy_and_transfer_move_the_quantities_and_the_weights() -> void:
	var store: GoodsStore = _store(_book())
	assert_true(store.create(MARKET, "bread", 20, GoodsStore.REASON_GAME_START).ok)
	assert_true(store.create(MARKET, "tool", 3, GoodsStore.REASON_PRODUCED).ok)
	assert_true(store.transfer(MARKET, NPC, "bread", 5).ok)
	assert_true(store.destroy(NPC, "bread", 2, GoodsStore.REASON_CONSUMED).ok)
	assert_eq([store.quantity_of(MARKET, "bread"), store.quantity_of(NPC, "bread"), store.quantity_of(NPC, "tool")], [15, 3, 0])
	assert_eq(store.inventory_rows(MARKET), [{"good_id": "bread", "quantity": 15}, {"good_id": "tool", "quantity": 3}] as Array[Dictionary], "Por good_id crescente.")
	assert_eq([store.weight_of(NPC), store.weight_of(MARKET)], [3, 21], "Peso = quantidade × peso do bem (pão 1, ferramenta 2).")
	assert_true(store.is_conserved())
	assert_eq(store.conservation_rows(), [{"good_id": "bread", "in_stock": 18, "created": 20, "destroyed": 2, "ok": true}, {"good_id": "tool", "in_stock": 3, "created": 3, "destroyed": 0, "ok": true}] as Array[Dictionary])
	assert_eq(store.total_by_reason("bread", GoodsStore.REASON_CONSUMED), 2)
	assert_true(store.transfer(NPC, NPC, "bread", 3).ok, "Mover para si mesmo não muda nada.")
	assert_eq(store.quantity_of(NPC, "bread"), 3)


func test_invalid_calls_are_refused_with_the_right_code_and_change_nothing() -> void:
	var book: OwnerBook = _book()
	var store: GoodsStore = _store(book)
	store.create(NPC, "bread", 10, GoodsStore.REASON_GAME_START)
	book.close_owner(DEAD_NPC)
	var before: Array = _snapshot(store)
	var cases: Array[Dictionary] = [
		{"label": "bem inexistente", "result": store.create(NPC, "gold", 1, GoodsStore.REASON_PRODUCED), "code": EconomyCodes.UNKNOWN_GOOD},
		{"label": "quantidade zero", "result": store.transfer(NPC, OTHER_NPC, "bread", 0), "code": EconomyCodes.BAD_QUANTITY},
		{"label": "quantidade negativa", "result": store.destroy(NPC, "bread", -2, GoodsStore.REASON_CONSUMED), "code": EconomyCodes.BAD_QUANTITY},
		{"label": "motivo de criar usado ao destruir", "result": store.destroy(NPC, "bread", 1, GoodsStore.REASON_PRODUCED), "code": EconomyCodes.DATA_INVALID},
		{"label": "motivo fora do conjunto", "result": store.create(NPC, "bread", 1, "gift"), "code": EconomyCodes.DATA_INVALID},
		{"label": "dono inexistente", "result": store.create(99, "bread", 1, GoodsStore.REASON_PRODUCED), "code": EconomyCodes.UNKNOWN_OWNER},
		{"label": "dono fechado recebe", "result": store.transfer(NPC, DEAD_NPC, "bread", 1), "code": EconomyCodes.OWNER_CLOSED},
		{"label": "dono fechado cria", "result": store.create(DEAD_NPC, "bread", 1, GoodsStore.REASON_PRODUCED), "code": EconomyCodes.OWNER_CLOSED},
		{"label": "falta de bem", "result": store.transfer(NPC, OTHER_NPC, "bread", 11), "code": EconomyCodes.INSUFFICIENT_GOODS},
		{"label": "destruir o que não tem", "result": store.destroy(OTHER_NPC, "bread", 1, GoodsStore.REASON_CONSUMED), "code": EconomyCodes.INSUFFICIENT_GOODS},
		{"label": "peso acima da capacidade", "result": store.create(NPC, "metal", 9, GoodsStore.REASON_PRODUCED), "code": EconomyCodes.CAPACITY_EXCEEDED},
		{"label": "tipo sem inventário", "result": store.create(CONTRACT, "bread", 1, GoodsStore.REASON_PRODUCED), "code": EconomyCodes.CAPACITY_EXCEEDED},
		{"label": "origem sem o bem", "result": store.transfer(MARKET, NPC, "bread", 1), "code": EconomyCodes.INSUFFICIENT_GOODS},
	]
	for test_case: Dictionary in cases:
		var result: Result = test_case["result"]
		assert_false(result.ok, "%s: deveria falhar." % test_case["label"])
		assert_eq(result.code, test_case["code"], test_case["label"])
		assert_true(result.message.begins_with("GoodsStore."), "%s: a mensagem diz de onde veio." % test_case["label"])
	assert_eq(_snapshot(store), before, "Nenhuma falha muda o inventário.")


func test_the_capacity_is_respected_exactly_and_a_closed_owner_keeps_its_goods_in_the_sum() -> void:
	var book: OwnerBook = _book()
	var store: GoodsStore = _store(book)
	assert_eq(store.capacity_of(NPC), 40, "A capacidade vem do tipo (owner_kinds.json).")
	assert_true(store.create(NPC, "wood", 8, GoodsStore.REASON_PRODUCED).ok, "8 × peso 5 = 40: exatamente a capacidade.")
	assert_eq(store.create(NPC, "bread", 1, GoodsStore.REASON_PRODUCED).code, EconomyCodes.CAPACITY_EXCEEDED, "Um a mais não cabe.")
	assert_eq(store.create(NPC, "bread", 9007199254740991, GoodsStore.REASON_PRODUCED).code, EconomyCodes.CAPACITY_EXCEEDED, "Quantidade enorme não estoura a conta do peso.")
	assert_true(store.transfer(NPC, MARKET, "wood", 8).ok)
	assert_eq(store.weight_of(NPC), 0)
	assert_true(store.create(DEAD_NPC, "grain", 4, GoodsStore.REASON_PRODUCED).ok)
	book.close_owner(DEAD_NPC)
	assert_eq(store.quantity_of(DEAD_NPC, "grain"), 4, "O dono fechado continua com os bens.")
	assert_true(store.is_conserved(), "E eles continuam na soma da conservação.")
	assert_eq(store.destroy(DEAD_NPC, "grain", 1, GoodsStore.REASON_CONSUMED).code, EconomyCodes.OWNER_CLOSED)


func test_maintenance_destroys_goods_and_the_conservation_counts_it() -> void:
	var store: GoodsStore = _store(_book())
	store.create(MARKET, "plank", 10, GoodsStore.REASON_GAME_START)
	store.destroy(MARKET, "plank", 3, GoodsStore.REASON_MAINTENANCE)
	store.destroy(MARKET, "plank", 1, GoodsStore.REASON_SPOILED)
	assert_eq(store.conservation_rows(), [{"good_id": "plank", "in_stock": 6, "created": 10, "destroyed": 4, "ok": true}] as Array[Dictionary])
	assert_eq([store.total_by_reason("plank", GoodsStore.REASON_MAINTENANCE), store.total_by_reason("plank", GoodsStore.REASON_SPOILED), store.total_by_reason("plank", GoodsStore.REASON_GAME_START)], [3, 1, 10])


func test_thousands_of_random_operations_keep_the_conservation_against_a_separate_model() -> void:
	var book: OwnerBook = _book()
	book.close_owner(DEAD_NPC)
	var store: GoodsStore = _store(book)
	var loaded: GoodsLoader.LoadResult = _loaded()
	var rng: WorldRng = WorldRng.new(WORLD_SEED)
	var model: Dictionary = {}
	var created: Dictionary = {}
	var destroyed: Dictionary = {}
	var failures: int = 0
	for _step: int in OPERATIONS:
		var kind: int = rng.range_int(STREAM, 0, 2)
		var first: int = rng.range_int(STREAM, 1, OWNER_COUNT + 1)
		var second: int = rng.range_int(STREAM, 1, OWNER_COUNT + 1)
		var good: GoodDef = loaded.goods[rng.range_int(STREAM, 0, loaded.goods.size() - 1)]
		var quantity: int = rng.range_int(STREAM, 1, 12)
		var result: Result
		if kind == 0:
			result = store.create(first, good.id, quantity, GoodsStore.REASON_PRODUCED)
			if result.ok:
				model[[first, good.id]] = int(model.get([first, good.id], 0)) + quantity
				created[good.id] = int(created.get(good.id, 0)) + quantity
		elif kind == 1:
			result = store.destroy(first, good.id, quantity, GoodsStore.REASON_MAINTENANCE)
			if result.ok:
				model[[first, good.id]] = int(model.get([first, good.id], 0)) - quantity
				destroyed[good.id] = int(destroyed.get(good.id, 0)) + quantity
		else:
			result = store.transfer(first, second, good.id, quantity)
			if result.ok:
				model[[first, good.id]] = int(model.get([first, good.id], 0)) - quantity
				model[[second, good.id]] = int(model.get([second, good.id], 0)) + quantity
		if not result.ok:
			failures += 1
		assert_true(store.is_conserved(), "A conservação fecha a cada operação.")
		assert_eq(store.validate(), [] as Array[String])
	for owner_id: int in range(1, OWNER_COUNT + 1):
		for good: GoodDef in loaded.goods:
			assert_eq(store.quantity_of(owner_id, good.id), int(model.get([owner_id, good.id], 0)), "Dono %d, %s: igual ao modelo." % [owner_id, good.id])
	for row: Dictionary in store.conservation_rows():
		assert_eq([row["created"], row["destroyed"]], [int(created.get(row["good_id"], 0)), int(destroyed.get(row["good_id"], 0))])
	assert_gt(failures, 100, "O sorteio inclui donos inexistentes, fechados, falta de bem e peso demais: muitas falhas, todas sem efeito.")


func test_save_round_trip_through_json_and_invalid_data_is_refused() -> void:
	var book: OwnerBook = _book()
	var store: GoodsStore = _store(book)
	store.create(MARKET, "bread", 30, GoodsStore.REASON_GAME_START)
	store.create(MARKET, "plank", 12, GoodsStore.REASON_PRODUCED)
	store.transfer(MARKET, NPC, "bread", 7)
	store.destroy(NPC, "bread", 2, GoodsStore.REASON_CONSUMED)
	store.destroy(MARKET, "plank", 5, GoodsStore.REASON_MAINTENANCE)
	store.create(OTHER_NPC, "tool", 2, GoodsStore.REASON_PRODUCED)
	store.transfer(OTHER_NPC, NPC, "tool", 2)
	var good: Dictionary = store.serialize()
	# Variant: o JSON devolve qualquer tipo; aqui o formato é conhecido (um objeto).
	var parsed: Variant = JSON.parse_string(JSON.stringify(good))
	var through_json: Dictionary = parsed
	var restored: GoodsStore = _store(book)
	var loaded: Result = restored.load_from(through_json)
	assert_true(loaded.ok, loaded.message)
	assert_eq(JSON.stringify(restored.serialize(), "", true, true).sha256_text(), JSON.stringify(good, "", true, true).sha256_text(), "Mesmo estado, mesma impressão digital.")
	assert_eq([restored.quantity_of(NPC, "bread"), restored.quantity_of(MARKET, "plank"), restored.total_by_reason("plank", GoodsStore.REASON_MAINTENANCE)], [5, 7, 5])
	assert_eq(restored.validate(), [] as Array[String])
	assert_eq(store.serialize()[GoodsStore.KEY_STOCK].keys(), ["1", "3"], "Por ID crescente; quantidade zero não é guardada.")
	var cases: Array[Dictionary] = [
		{"label": "campo ausente", "mutate": func(data: Dictionary) -> void: data.erase(GoodsStore.KEY_CREATED), "fragment": "campo 'created' ausente"},
		{"label": "dono inexistente", "mutate": func(data: Dictionary) -> void: data[GoodsStore.KEY_STOCK] = {"99": {"bread": 1}}, "fragment": "o ID de um dono existente"},
		{"label": "bem inexistente", "mutate": func(data: Dictionary) -> void: data[GoodsStore.KEY_STOCK] = {"1": {"gold": 1}}, "fragment": "o bem 'gold'"},
		{"label": "quantidade com fração", "mutate": func(data: Dictionary) -> void: data[GoodsStore.KEY_STOCK] = {"1": {"bread": 1.5}}, "fragment": "um inteiro de 1 ou mais"},
		{"label": "motivo fora do conjunto", "mutate": func(data: Dictionary) -> void: data[GoodsStore.KEY_DESTROYED] = {"bread": {"produced": 2}}, "fragment": "um motivo de consumed, maintenance, spoiled"},
		{"label": "peso acima da capacidade", "mutate": func(data: Dictionary) -> void: data[GoodsStore.KEY_STOCK] = {"1": {"metal": 9}}, "fragment": "peso acima da capacidade"},
		{"label": "conservação que não fecha", "mutate": func(data: Dictionary) -> void: data[GoodsStore.KEY_CREATED] = {"bread": {"game_start": 99}}, "fragment": "a conservação do bem 'bread' não fecha"},
	]
	for test_case: Dictionary in cases:
		var data: Dictionary = good.duplicate(true)
		var mutate: Callable = test_case["mutate"]
		mutate.call(data)
		var result: Result = store.load_from(data)
		assert_false(result.ok, "%s: deveria falhar." % test_case["label"])
		assert_eq(result.code, EconomyCodes.INVALID_SAVE, test_case["label"])
		assert_string_contains(result.message, test_case["fragment"], test_case["label"])
		assert_eq(store.serialize(), good, "%s: o inventário continua como estava." % test_case["label"])
