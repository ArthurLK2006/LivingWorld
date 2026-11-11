extends GutTest
## LW-092d (N3 da revisão independente): o `TradeEngine.execute` confere o resultado das duas movimentações (dinheiro e bens) e a ordem das conferências é a do cabeçalho do arquivo: ordem, regras, ATOR, teto ou estoque,
## fundos, capacidade. Duplos de teste (`Ledger` e `GoodsStore` cuja movimentação falha) provam o que o código real não deixa acontecer: a ordem falha inteira e não muda nada. Dados REAIS (data/economy): mercado A (dono 1), NPC (dono 2, 200).

const SETTLEMENT_A: String = "test_settlement_a"
const MARKET: int = 1
const NPC: int = 2


## `Ledger` cuja `transfer` falha a partir da chamada de número `fail_from` (1 = a primeira).
class FlakyLedger:
	extends Ledger

	var fail_from: int = 1
	var calls: int = 0

	func transfer(from_id: int, to_id: int, amount: int, reason: String) -> Result:
		calls += 1
		if calls >= fail_from:
			return Result.failure(EconomyCodes.INSUFFICIENT_FUNDS, "duplo de teste: a transferência %d falhou" % calls)
		return super(from_id, to_id, amount, reason)


## `GoodsStore` cuja `transfer` sempre falha.
class FlakyGoods:
	extends GoodsStore

	func transfer(_from_id: int, _to_id: int, _good_id: String, _quantity: int) -> Result:
		return Result.failure(EconomyCodes.CAPACITY_EXCEEDED, "duplo de teste: a entrega falhou")


class Rig:
	extends RefCounted

	var book: OwnerBook
	var ledger: Ledger
	var goods: GoodsStore
	var engine: TradeEngine


func _rig(ledger_kind: String = "real", goods_kind: String = "real") -> Rig:
	var loaded_goods: GoodsLoader.LoadResult = GoodsLoader.load_dir(GoodsLoader.DEFAULT_DIR)
	var loaded: MarketLoader.LoadResult = MarketLoader.load_dir(GoodsLoader.DEFAULT_DIR)
	assert_true(loaded_goods.result.ok and loaded.result.ok, loaded_goods.result.message + loaded.result.message)
	var rig: Rig = Rig.new()
	rig.book = OwnerBook.new()
	rig.book.open_owner(MARKET, "market")
	rig.book.open_owner(NPC, "npc")
	rig.ledger = FlakyLedger.new(rig.book) if ledger_kind == "flaky" else Ledger.new(rig.book)
	rig.goods = FlakyGoods.new(rig.book, loaded_goods.goods, loaded_goods.kinds) if goods_kind == "flaky" else GoodsStore.new(rig.book, loaded_goods.goods, loaded_goods.kinds)
	assert_true(rig.ledger.mint(MARKET, 3000, Ledger.REASON_GAME_START).ok)
	assert_true(rig.ledger.mint(NPC, 200, Ledger.REASON_GAME_START).ok)
	for target: MarketTargetDef in loaded.targets:
		if target.settlement_id == SETTLEMENT_A:
			assert_true(rig.goods.create(MARKET, target.good_id, target.initial_stock, GoodsStore.REASON_GAME_START).ok)
	var markets: MarketBook = MarketBook.new(rig.book, rig.goods, loaded_goods.goods, loaded.targets, loaded.params)
	markets.register_market(SETTLEMENT_A, MARKET)
	rig.engine = TradeEngine.new(rig.book, rig.ledger, rig.goods, markets, NeutralTradeRules.new(), loaded.params)
	return rig


func _state(rig: Rig) -> Array:
	return [rig.ledger.balance_of(MARKET), rig.ledger.balance_of(NPC), rig.goods.inventory_rows(MARKET), rig.goods.inventory_rows(NPC)]


func test_the_actor_is_checked_before_the_stock_and_after_the_rules() -> void:
	var rig: Rig = _rig()
	assert_eq(rig.engine.execute(99, MARKET, "bread", 50, TradeEngine.SIDE_BUY).result.code, EconomyCodes.UNKNOWN_OWNER, "Ator inexistente e ordem válida: o ator.")
	assert_true(rig.goods.destroy(MARKET, "bread", rig.goods.quantity_of(MARKET, "bread") - 3, GoodsStore.REASON_CONSUMED).ok, "O mercado fica com 3 de pão.")
	assert_eq(rig.engine.execute(99, MARKET, "bread", 5, TradeEngine.SIDE_BUY).result.code, EconomyCodes.UNKNOWN_OWNER, "Ator inexistente E estoque curto: o erro é o do ator, que vem antes.")
	assert_eq(rig.engine.execute(NPC, MARKET, "bread", 5, TradeEngine.SIDE_BUY).result.code, EconomyCodes.INSUFFICIENT_STOCK, "Com o ator certo, o estoque curto aparece.")
	assert_eq(rig.engine.execute(IdGenerator.NO_ID, MARKET, "bread", 5, TradeEngine.SIDE_BUY).result.code, EconomyCodes.UNKNOWN_OWNER, "Sem ator a ordem não passa.")
	assert_true(rig.book.close_owner(NPC).ok)
	assert_eq(rig.engine.execute(NPC, MARKET, "bread", 5, TradeEngine.SIDE_BUY).result.code, EconomyCodes.OWNER_CLOSED, "Ator fechado e estoque curto: o ator.")
	assert_eq(rig.engine.quote(MARKET, "bread", 5, TradeEngine.SIDE_BUY).result.code, EconomyCodes.INSUFFICIENT_STOCK, "A cotação sem ator não confere o ator.")
	assert_eq(rig.engine.quote(MARKET, "bread", 5, TradeEngine.SIDE_BUY, 99).result.code, EconomyCodes.UNKNOWN_OWNER, "A cotação com um ator confere o ator, na mesma ordem.")


func test_a_failed_payment_fails_the_whole_order_and_moves_no_goods() -> void:
	var rig: Rig = _rig("flaky")
	var before: Array = _state(rig)
	var outcome: TradeEngine.Outcome = rig.engine.execute(NPC, MARKET, "bread", 3, TradeEngine.SIDE_BUY)
	assert_false(outcome.result.ok)
	assert_eq([outcome.result.code, outcome.quantity, outcome.total], [EconomyCodes.INSUFFICIENT_FUNDS, 0, 0])
	assert_eq(_state(rig), before, "Nada mudou: nem o dinheiro nem os bens.")


func test_a_failed_delivery_after_the_payment_gives_the_money_back() -> void:
	var rig: Rig = _rig("real", "flaky")
	var before: Array = _state(rig)
	var outcome: TradeEngine.Outcome = rig.engine.execute(NPC, MARKET, "bread", 3, TradeEngine.SIDE_BUY)
	assert_false(outcome.result.ok)
	assert_eq(outcome.result.code, EconomyCodes.CAPACITY_EXCEEDED)
	assert_string_contains(outcome.result.message, "a entrega dos bens falhou depois do pagamento")
	assert_eq(_state(rig), before, "O dinheiro voltou e os bens não saíram do lugar.")
	assert_true(rig.ledger.is_conserved() and rig.goods.is_conserved())
	var broken: Rig = _rig("flaky", "flaky")
	(broken.ledger as FlakyLedger).fail_from = 2
	var stuck: TradeEngine.Outcome = broken.engine.execute(NPC, MARKET, "bread", 3, TradeEngine.SIDE_BUY)
	assert_false(stuck.result.ok)
	assert_string_contains(stuck.result.message, "O dinheiro NÃO voltou")
