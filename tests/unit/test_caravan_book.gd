extends GutTest
## LW-098c: o livro de caravanas (`CaravanBook` e `Caravan`; docs/modules/economy.md, 9.3, 9.4 e 9.10), sem o módulo. Livros REAIS (donos, bens e mercados de data/economy). O livro nasce vazio; o save faz ida e volta com caravana em trânsito, parada no MEIO da estrada e
## parada num povoado; os mesmos registros dão os mesmos bytes em qualquer ordem, por `trader_id` crescente; `load_from` recusa tipo errado e comerciante repetido sem mudar nada; `validate` pega cada invariante de 9.3 (trecho que não existe, estado inválido, dono que não é `merchant`...).

const SETTLEMENTS: Array[String] = ["test_settlement_a", "test_settlement_b", "test_settlement_c"]
const MARKETS: Array[int] = [1, 2, 3]
const TRADERS: Array[int] = [10, 11, 12]
const NPC: int = 20
const DEAD_TRADER: int = 21


class Rig:
	extends RefCounted

	var book: OwnerBook
	var caravans: CaravanBook


func _rig() -> Rig:
	var loaded_goods: GoodsLoader.LoadResult = GoodsLoader.load_dir(GoodsLoader.DEFAULT_DIR)
	var market: MarketLoader.LoadResult = MarketLoader.load_dir(GoodsLoader.DEFAULT_DIR)
	assert_true(loaded_goods.result.ok and market.result.ok)
	var rig: Rig = Rig.new()
	rig.book = OwnerBook.new()
	for opening: Array in [[1, "market"], [2, "market"], [3, "market"], [10, "merchant"], [11, "merchant"], [12, "merchant"], [NPC, "npc"], [DEAD_TRADER, "merchant"]]:
		assert_true(rig.book.open_owner(opening[0], opening[1]).ok)
	assert_true(rig.book.close_owner(DEAD_TRADER).ok)
	var markets: MarketBook = MarketBook.new(rig.book, GoodsStore.new(rig.book, loaded_goods.goods, loaded_goods.kinds), loaded_goods.goods, market.targets, market.params)
	for index: int in MARKETS.size():
		markets.register_market(SETTLEMENTS[index], MARKETS[index])
	rig.caravans = CaravanBook.new(rig.book, markets)
	return rig


## Um registro válido do A ao C pelo B (rotas reais), com `changes` por cima.
func _record(trader_id: int, changes: Dictionary = {}) -> Dictionary:
	var record: Dictionary = {"trader_id": trader_id, "state": "travelling", "origin_market_id": 1, "destination_market_id": 3, "route_ids": ["route_a_b", "route_b_c"], "leg_index": 0, "leg_started_at": 100, "leg_minutes": 143, "elapsed_at_hold": 0, "good_id": "bread", "quantity": 6, "cost_paid": 78, "departed_at": 100}
	record.merge(changes, true)
	return record


## Em trânsito, parada no meio do segundo trecho e parada num povoado (`elapsed_at_hold` 0).
func _trip() -> Array:
	return [_record(10), _record(11, {"state": "held", "leg_index": 1, "leg_minutes": 96, "elapsed_at_hold": 40}), _record(12, {"state": "held", "leg_index": 1, "leg_started_at": 243, "leg_minutes": 96})]


func _through_json(records: Array) -> Array:
	# Variant: o JSON devolve qualquer tipo; aqui o formato é conhecido (uma lista).
	var parsed: Variant = JSON.parse_string(JSON.stringify(records))
	assert_eq(typeof(parsed), TYPE_ARRAY)
	var copy: Array = parsed
	return copy


func _bytes(rig: Rig) -> String:
	return JSON.stringify(rig.caravans.serialize(), "", true, true)


func test_a_new_book_is_empty_and_has_nothing_to_save() -> void:
	var rig: Rig = _rig()
	assert_true(rig.caravans.is_pristine())
	assert_eq([rig.caravans.serialize(), rig.caravans.trader_ids(), rig.caravans.validate()], [[] as Array[Dictionary], [] as Array[int], [] as Array[String]])
	assert_null(rig.caravans.caravan_of(10), "Sem registro o comerciante está parado.")


func test_the_save_round_trips_a_caravan_in_transit_held_mid_road_and_held_in_a_settlement() -> void:
	var rig: Rig = _rig()
	assert_true(rig.caravans.load_from(_through_json(_trip())).ok)
	assert_false(rig.caravans.is_pristine())
	assert_eq(rig.caravans.validate(), [] as Array[String])
	assert_eq(_bytes(rig), JSON.stringify(_trip(), "", true, true), "O que sai é o que entrou: os 13 campos de cada registro, inteiros.")
	var restored: Rig = _rig()
	assert_true(restored.caravans.load_from(_through_json(rig.caravans.serialize())).ok)
	assert_eq(_bytes(restored), _bytes(rig), "Ida e volta pelo JSON: os mesmos bytes.")
	var held: Caravan = restored.caravans.caravan_of(11)
	assert_eq([held.state, held.elapsed_at_hold, held.current_route_id(), held.is_on_road(), restored.caravans.caravan_of(12).is_on_road()], ["held", 40, "route_b_c", true, false])
	held.route_ids.append("route_a_c")
	assert_eq(restored.caravans.caravan_of(11).route_ids, ["route_a_b", "route_b_c"] as Array[String], "`caravan_of` devolve cópia.")
	restored.caravans.remove(11)
	assert_eq(restored.caravans.trader_ids(), [10, 12] as Array[int])


func test_the_same_records_give_the_same_bytes_in_any_order_by_trader_id() -> void:
	var forward: Rig = _rig()
	var backward: Rig = _rig()
	var records: Array = _trip()
	assert_true(forward.caravans.load_from(records).ok)
	records.reverse()
	assert_true(backward.caravans.load_from(records).ok)
	assert_eq(_bytes(backward), _bytes(forward))
	assert_eq(forward.caravans.serialize().map(func(record: Dictionary) -> int: return record["trader_id"]), [10, 11, 12])


func test_load_from_refuses_wrong_types_and_a_repeated_trader_and_changes_nothing() -> void:
	var rig: Rig = _rig()
	assert_true(rig.caravans.load_from(_trip()).ok)
	var before: String = _bytes(rig)
	var cases: Array[Dictionary] = [
		{"label": "registro que não é objeto", "records": [3], "expect": "registro 0: esperado um objeto"},
		{"label": "inteiro com fração", "records": [_record(10, {"leg_index": 1.5})], "expect": "'leg_index' deve ser um inteiro"},
		{"label": "campo que não é inteiro", "records": [_record(10, {"quantity": "6"})], "expect": "'quantity' deve ser um inteiro"},
		{"label": "estado que não é texto", "records": [_record(10, {"state": 7})], "expect": "'state' deve ser texto"},
		{"label": "rotas que não são textos", "records": [_record(10, {"route_ids": ["route_a_b", 3]})], "expect": "'route_ids' deve ser uma lista de textos"},
		{"label": "dois registros do mesmo comerciante", "records": [_record(10), _record(10, {"quantity": 9})], "expect": "o comerciante 10 tem mais de um registro"},
	]
	for test_case: Dictionary in cases:
		var refused: Result = rig.caravans.load_from(test_case["records"])
		assert_false(refused.ok, test_case["label"])
		assert_eq(refused.code, EconomyCodes.INVALID_SAVE, test_case["label"])
		assert_string_contains(refused.message, test_case["expect"], test_case["label"])
		assert_eq(_bytes(rig), before, "%s: o livro fica como estava." % test_case["label"])


func test_validate_catches_each_invariant_of_the_contract() -> void:
	var cases: Array[Dictionary] = [
		{"label": "comerciante que não existe", "changes": {"trader_id": 99}, "expect": "o dono 99 não existe"},
		{"label": "comerciante morto", "changes": {"trader_id": DEAD_TRADER}, "expect": "o dono 21 está fechado"},
		{"label": "dono que não é merchant", "changes": {"trader_id": NPC}, "expect": "o dono 20 é do tipo 'npc'; esperado 'merchant'"},
		{"label": "estado inválido", "changes": {"state": "flying"}, "expect": "o estado 'flying' não é válido"},
		{"label": "sem rotas", "changes": {"route_ids": []}, "expect": "'route_ids' deve ter ao menos uma rota"},
		{"label": "trecho que não existe", "changes": {"leg_index": 2}, "expect": "o trecho 2 não existe: o caminho tem 2 rota(s)"},
		{"label": "trecho negativo", "changes": {"leg_index": -1}, "expect": "o trecho -1 não existe"},
		{"label": "duração zero", "changes": {"leg_minutes": 0}, "expect": "'leg_minutes' é 0; esperado 1 ou mais"},
		{"label": "parada além do trecho", "changes": {"state": "held", "elapsed_at_hold": 144}, "expect": "'elapsed_at_hold' é 144; esperado de 0 a 143"},
		{"label": "minutos parados em trânsito", "changes": {"elapsed_at_hold": 5}, "expect": "só 'held' pode ter minutos parados"},
		{"label": "lote zero", "changes": {"quantity": 0}, "expect": "'quantity' é 0; esperado 1 ou mais"},
		{"label": "origem igual ao destino", "changes": {"destination_market_id": 1}, "expect": "a origem e o destino são o mesmo mercado (1)"},
		{"label": "destino que não é mercado", "changes": {"destination_market_id": NPC}, "expect": "20 não é um mercado"},
		{"label": "bem que o mercado não negocia", "changes": {"good_id": "salt"}, "expect": "o bem 'salt' não é negociado no mercado 1"},
	]
	for test_case: Dictionary in cases:
		var rig: Rig = _rig()
		assert_true(rig.caravans.load_from([_record(TRADERS[0], test_case["changes"])]).ok, "%s: o tipo está certo, só o conteúdo é inválido." % test_case["label"])
		assert_string_contains("\n".join(rig.caravans.validate()), test_case["expect"], test_case["label"])
