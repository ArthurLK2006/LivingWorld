class_name TradeEngine
extends RefCounted
## O comércio entre um ator e um mercado (LW-091; docs/modules/economy.md, seção 5): `quote` (o total e a tarifa de uma ordem, sem executar) e `execute` (a ordem, ATÔMICA: toda conferência vem antes da primeira escrita, e só então o
## `Ledger` move o dinheiro e o `GoodsStore` move os bens). `side` = `buy` (o ator compra do mercado, paga o `ask`) ou `sell` (o ator vende ao mercado, recebe o `bid`); o total é a soma por degrau da seção 4 (a ordem "anda pela
## curva"). Ordem das conferências (a primeira que falha devolve o erro): mercado, bem, lado, quantidade, regras (`TradeRules`), ator, teto de compra ou estoque, fundos, capacidade. A tarifa que a regra pedir é CALCULADA e
## devolvida, mas não é cobrada na Fase 3 (para onde ela vai é decisão da Fase 4): com a regra neutra é sempre 0.

const SIDE_BUY: String = "buy"
const SIDE_SELL: String = "sell"

var _book: OwnerBook
var _ledger: Ledger
var _goods: GoodsStore
var _markets: MarketBook
var _rules: TradeRules
var _params: PriceParams


func _init(book: OwnerBook, ledger: Ledger, goods: GoodsStore, markets: MarketBook, rules: TradeRules, params: PriceParams) -> void:
	_book = book
	_ledger = ledger
	_goods = goods
	_markets = markets
	_rules = rules
	_params = params


## O total e a tarifa da ordem, sem executar. Mesmas falhas de `execute` que não dependem do ator.
func quote(market_id: int, good_id: String, quantity: int, side: String, actor_id: int = IdGenerator.NO_ID) -> Outcome:
	var checked: Result = _check_order(market_id, good_id, quantity, side)
	if not checked.ok:
		return Outcome.new(checked, 0, 0, 0)
	var terms: TradeTerms = _rules.peek_terms(good_id, market_id, actor_id)
	if terms.banned:
		return Outcome.new(Result.failure(EconomyCodes.TRADE_BANNED, "TradeEngine.quote: as regras de comércio proíbem '%s' no mercado %d." % [good_id, market_id]), 0, 0, 0)
	var stock: int = _goods.quantity_of(market_id, good_id)
	if side == SIDE_BUY and quantity > stock:
		return Outcome.new(Result.failure(EconomyCodes.INSUFFICIENT_STOCK, "TradeEngine.quote: o mercado %d tem %d de '%s' e a compra pede %d." % [market_id, stock, good_id, quantity]), 0, 0, 0)
	if side == SIDE_SELL and stock + quantity > _markets.buy_cap_of(market_id, good_id):
		return Outcome.new(Result.failure(EconomyCodes.MARKET_FULL, "TradeEngine.quote: o mercado %d tem %d de '%s' e o teto de compra é %d; a venda de %d não cabe." % [market_id, stock, good_id, _markets.buy_cap_of(market_id, good_id), quantity]), 0, 0, 0)
	var total: int = _markets.quote_buy(market_id, good_id, quantity) if side == SIDE_BUY else _markets.quote_sell(market_id, good_id, quantity)
	return Outcome.new(Result.success(), quantity, total, IntMath.floor_div(total * terms.tariff_bp, PriceMath.BASIS))


## Executa a ordem: tudo ou nada. Falhas: as de `quote` mais `ECON_UNKNOWN_OWNER`, `ECON_OWNER_CLOSED`, `ECON_INSUFFICIENT_FUNDS` (o ator compra sem dinheiro), `ECON_MARKET_NO_FUNDS` (o mercado não paga a venda),
## `ECON_INSUFFICIENT_GOODS` (o ator vende o que não tem) e `ECON_CAPACITY_EXCEEDED` (quem recebe não carrega o peso).
func execute(actor_id: int, market_id: int, good_id: String, quantity: int, side: String) -> Outcome:
	var quoted: Outcome = quote(market_id, good_id, quantity, side, actor_id)
	if not quoted.result.ok:
		return quoted
	var opened: Result = _book.check_open(actor_id)
	if not opened.ok:
		return Outcome.new(Result.failure(opened.code, "TradeEngine.execute: %s" % opened.message), 0, 0, 0)
	var buying: bool = side == SIDE_BUY
	var payer: int = actor_id if buying else market_id
	var seller: int = market_id if buying else actor_id
	var buyer: int = actor_id if buying else market_id
	var payee: int = market_id if buying else actor_id
	if _ledger.balance_of(payer) < quoted.total:
		var code: String = EconomyCodes.INSUFFICIENT_FUNDS if buying else EconomyCodes.MARKET_NO_FUNDS
		return Outcome.new(Result.failure(code, "TradeEngine.execute: o dono %d tem saldo %d e a ordem custa %d." % [payer, _ledger.balance_of(payer), quoted.total]), 0, 0, 0)
	var goods_ok: Result = _goods.check_transfer(seller, buyer, good_id, quantity)
	if not goods_ok.ok:
		return Outcome.new(goods_ok, 0, 0, 0)
	var money_ok: Result = _ledger.check_transfer(payer, payee, quoted.total, Ledger.REASON_TRADE)
	if not money_ok.ok:
		return Outcome.new(money_ok, 0, 0, 0)
	_ledger.transfer(payer, payee, quoted.total, Ledger.REASON_TRADE)
	_goods.transfer(seller, buyer, good_id, quantity)
	return quoted


## Resultado de `quote` e de `execute`: `quantity`, `total` (o que muda de mãos) e `tariff` só valem se `result.ok`.
class Outcome:
	extends RefCounted

	var result: Result
	var quantity: int
	var total: int
	var tariff: int

	func _init(outcome_result: Result, traded_quantity: int, traded_total: int, traded_tariff: int) -> void:
		result = outcome_result
		quantity = traded_quantity
		total = traded_total
		tariff = traded_tariff


func _check_order(market_id: int, good_id: String, quantity: int, side: String) -> Result:
	if _markets == null or not _markets.has_market(market_id):
		return Result.failure(EconomyCodes.UNKNOWN_MARKET, "TradeEngine: o mercado %d não existe." % market_id)
	if not _markets.is_traded(market_id, good_id):
		return Result.failure(EconomyCodes.UNKNOWN_GOOD, "TradeEngine: o bem '%s' não é negociado no mercado %d." % [good_id, market_id])
	if side != SIDE_BUY and side != SIDE_SELL:
		return Result.failure(EconomyCodes.DATA_INVALID, "TradeEngine: o lado '%s' não existe; esperado '%s' ou '%s'." % [side, SIDE_BUY, SIDE_SELL])
	if quantity < 1 or quantity > _params.max_order_quantity:
		return Result.failure(EconomyCodes.BAD_QUANTITY, "TradeEngine: quantidade %d inválida; esperado de 1 a %d por ordem." % [quantity, _params.max_order_quantity])
	return Result.success()
