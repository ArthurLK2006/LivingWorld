class_name NpcTrade
extends RefCounted
## O NPC no mercado (LW-093; docs/modules/npc.md, 14.2, 14.3 e 14.6): o que o `npc` faz com a porta da economia (`economy/api`, DEC-132) para comprar comida, comer do inventário e vender. O `npc` NUNCA altera saldo nem estoque:
## só pede `request_trade` e `request_consume`, que a economia valida e aplica de uma vez ou não aplica. Tudo aqui é inteiro e sem sorteio. As regras (PROPOSTAS, números em `data/npc_params.json`): o NPC compra a COMIDA que mais alivia a
## fome por moeda no mercado do povoado dele, até `buy_units` unidades, as que o saldo e o estoque deixam; come do inventário a comida de menor `good_id`, e o alívio vem do bem (a tabela de efeitos de `eat` fala de 60; o que o
## bem alivia a mais ou a menos entra como efeito extra); vende ao mercado o que tem no inventário (o primeiro bem, por id, que o mercado negocia).

## Escalas das contas inteiras (não são valores de jogo): a porcentagem tem base 100 e o alívio por moeda é medido em milésimos (base 1000), para a divisão inteira não perder precisão.
const PERCENT_SCALE: int = 100
const PERMILLE_SCALE: int = 1000
## A necessidade que a comida alivia (id de `data/needs.json`).
const FOOD_NEED_ID: String = "hunger"
## Os dois lados de `request_trade` (`economy.md`, seção 5).
const BUY_SIDE: String = "buy"
const SELL_SIDE: String = "sell"
const BUY_ACTION_ID: String = "buy"
const SELL_ACTION_ID: String = "sell"
const EAT_ACTION_ID: String = "eat"

var _economy: EconomyModule
var _states: Dictionary[int, NpcState]
var _buy_units: int
var _price_percent: int


## `buy_units`: o teto de unidades de uma compra (`npc_params.json`); 0 = o NPC não compra. `price_percent`: quanto do preço pago desconta do valor de `buy` (100 = um ponto de alívio por moeda).
func _init(economy: EconomyModule, states: Dictionary[int, NpcState], buy_units: int, price_percent: int = 0) -> void:
	_economy = economy
	_states = states
	_buy_units = buy_units
	_price_percent = price_percent


## A melhor compra de comida do NPC agora (`FoodPlan.is_empty()` se não há): a comida do mercado do povoado dele que mais alivia por moeda, na quantidade que o saldo e o estoque deixam.
func plan_food(npc_id: int) -> FoodPlan:
	var plan: FoodPlan = FoodPlan.new()
	if not _states.has(npc_id) or _buy_units < 1:
		return plan
	var market: EconomyReplies.MarketQuery = _economy.peek_market_of(_states[npc_id].settlement_id)
	if not market.result.ok:
		return plan
	var balance: int = _economy.peek_balance(npc_id).balance
	for good: EconomyReplies.GoodQuery in _economy.peek_goods_for_need(FOOD_NEED_ID).goods:
		var stock: int = _stock_of(market, good.good_id)
		var units: int = mini(_buy_units, stock)
		while units > 0:
			var quote: EconomyReplies.QuoteQuery = _economy.peek_quote(npc_id, market.market_id, good.good_id, units, BUY_SIDE)
			if quote.result.ok and quote.total <= balance:
				plan.consider(market.market_id, good, units, quote.total)
				break
			units -= 1
	return plan


## O valor DERIVADO de `buy` (Q19, decidida por Arthur): o alívio da melhor compra de comida, em pontos de necessidade, menos o preço (o total pago vezes `price_percent` / 100); 0 se não há compra ou se o preço come o alívio todo.
## É o que o pensador usa para pontuar `buy`: a utilidade dela herda o alívio da comida, sem rotina fixa e sem planejador.
func buy_value(npc_id: int) -> int:
	var plan: FoodPlan = plan_food(npc_id)
	if plan.is_empty():
		return 0
	return maxi(0, plan.relief - IntMath.floor_div(plan.total * _price_percent, PERCENT_SCALE))


## O NPC tem comida no inventário (algum bem que alivia a fome)?
func has_food(npc_id: int) -> bool:
	return not _food_row(npc_id).is_empty()


## O NPC tem algum bem no inventário?
func has_goods(npc_id: int) -> bool:
	return _economy.peek_inventory(npc_id).rows.size() > 0


## O que a economia faz quando a ação COMPLETA (ver `ActionConditionProvider.complete_action`): `buy` compra a comida planejada, `eat` consome uma unidade de comida do inventário e devolve o alívio do bem, `sell` vende ao mercado o
## que o NPC tem. `eat` sem comida no inventário não faz nada aqui (vale o `FoodStub`, de reserva até a LW-094). Outra ação: nada.
func complete(npc_id: int, action_id: String) -> ActionConditionProvider.Completion:
	match action_id:
		BUY_ACTION_ID:
			return _complete_buy(npc_id)
		EAT_ACTION_ID:
			return _complete_eat(npc_id)
		SELL_ACTION_ID:
			return _complete_sell(npc_id)
	return ActionConditionProvider.Completion.new()


## A necessidade que `complete` aliviaria para esta ação, sem mudar nada: a da comida que o `eat` consumiria do inventário (`need_id` do bem, da economia); vazio para as outras ações ou sem comida no inventário (R6-I1).
func completion_need_id(npc_id: int, action_id: String) -> String:
	if action_id != EAT_ACTION_ID:
		return ""
	var row: Dictionary = _food_row(npc_id)
	return "" if row.is_empty() else _economy.peek_good(str(row["good_id"])).need_id


func _complete_buy(npc_id: int) -> ActionConditionProvider.Completion:
	var plan: FoodPlan = plan_food(npc_id)
	if plan.is_empty():
		return ActionConditionProvider.Completion.failed("o NPC %d não tem dinheiro e comida à venda no mercado do povoado" % npc_id)
	var traded: EconomyReplies.TradeResult = _economy.request_trade(npc_id, plan.market_id, plan.good_id, plan.units, BUY_SIDE)
	if not traded.result.ok:
		return ActionConditionProvider.Completion.failed("a compra de %d de '%s' falhou: %s" % [plan.units, plan.good_id, traded.result.message])
	return ActionConditionProvider.Completion.new()


func _complete_eat(npc_id: int) -> ActionConditionProvider.Completion:
	var row: Dictionary = _food_row(npc_id)
	if row.is_empty():
		return ActionConditionProvider.Completion.new()
	var eaten: EconomyReplies.ConsumeResult = _economy.request_consume(npc_id, str(row["good_id"]), 1)
	if not eaten.result.ok:
		return ActionConditionProvider.Completion.failed("o consumo de '%s' falhou: %s" % [row["good_id"], eaten.result.message])
	var completion: ActionConditionProvider.Completion = ActionConditionProvider.Completion.new()
	completion.consumed_from_inventory = true
	completion.relieved_need_id = eaten.need_id
	completion.relief = eaten.relief
	return completion


func _complete_sell(npc_id: int) -> ActionConditionProvider.Completion:
	if not _states.has(npc_id):
		return ActionConditionProvider.Completion.failed("o NPC %d não existe" % npc_id)
	var market: EconomyReplies.MarketQuery = _economy.peek_market_of(_states[npc_id].settlement_id)
	if not market.result.ok:
		return ActionConditionProvider.Completion.failed("o povoado do NPC %d não tem mercado" % npc_id)
	for row: Dictionary in _economy.peek_inventory(npc_id).rows:
		var good_id: String = str(row["good_id"])
		if not _traded_in(market, good_id):
			continue
		var units: int = int(row["quantity"])
		while units > 0:
			var sold: EconomyReplies.TradeResult = _economy.request_trade(npc_id, market.market_id, good_id, units, SELL_SIDE)
			if sold.result.ok:
				return ActionConditionProvider.Completion.new()
			units -= 1
	return ActionConditionProvider.Completion.failed("o mercado não comprou nada do NPC %d" % npc_id)


## A linha do inventário do NPC com a comida de menor `good_id` (vazio se não há).
func _food_row(npc_id: int) -> Dictionary:
	var food_ids: Array[String] = []
	for good: EconomyReplies.GoodQuery in _economy.peek_goods_for_need(FOOD_NEED_ID).goods:
		food_ids.append(good.good_id)
	for row: Dictionary in _economy.peek_inventory(npc_id).rows:
		if food_ids.has(str(row["good_id"])) and int(row["quantity"]) > 0:
			return row
	return {}


func _stock_of(market: EconomyReplies.MarketQuery, good_id: String) -> int:
	for row: Dictionary in market.rows:
		if row["good_id"] == good_id:
			return int(row["stock"])
	return 0


func _traded_in(market: EconomyReplies.MarketQuery, good_id: String) -> bool:
	for row: Dictionary in market.rows:
		if row["good_id"] == good_id:
			return true
	return false


## A melhor compra de comida: o mercado, o bem, a quantidade, o total e o alívio por moeda (em milésimos, para comparar sem divisão). Vazia = nada a comprar.
class FoodPlan:
	extends RefCounted

	var market_id: int = IdGenerator.NO_ID
	var good_id: String = ""
	var units: int = 0
	var total: int = 0
	var relief: int = 0
	var relief_per_coin_permille: int = 0

	func is_empty() -> bool:
		return units < 1

	## Fica com a oferta se alivia mais por moeda que a atual (empate: o menor `good_id`, que já chega primeiro).
	func consider(market: int, good: EconomyReplies.GoodQuery, offered_units: int, offered_total: int) -> void:
		var per_coin: int = IntMath.floor_div(good.need_relief * offered_units * PERMILLE_SCALE, offered_total)
		if is_empty() or per_coin > relief_per_coin_permille:
			market_id = market
			good_id = good.good_id
			units = offered_units
			total = offered_total
			relief = good.need_relief * offered_units
			relief_per_coin_permille = per_coin
