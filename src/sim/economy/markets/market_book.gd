class_name MarketBook
extends RefCounted
## Os mercados da economia (LW-090b; docs/modules/economy.md, seção 4): um por assentamento, com o ID inteiro do dono do tipo `market` (a conta e o inventário dele são do `Ledger` e do `GoodsStore`: o ESTOQUE do mercado é a
## quantidade que o dono tem). Aqui mora só o que é do mercado: por bem, o preço de tabela, o estoque de referência (o estoque em que o preço foi fixado), o último preço publicado, o histórico curto, os dias seguidos abaixo
## do limiar de escassez e se a escassez foi declarada. As definições (alvos e constantes de dados) são conteúdo, não entram no save. Ao FIM DO DIA o preço anda em direção ao preço-alvo (suavizado) e o livro devolve
## os eventos (`PriceChanged`, `ShortageDeclared`, `ShortageEnded`) para quem o chama publicar. Nunca sorteia, nunca olha o relógio e visita tudo por ID e por `good_id` crescentes.

## Id do tipo de dono do mercado (`owner_kinds.json`).
const KIND_MARKET: String = "market"
const KEY_MARKETS: String = "markets"
const KEY_SETTLEMENT: String = "settlement_id"
const KEY_GOODS: String = "goods"
const KEY_PRICE: String = "price"
const KEY_REF_STOCK: String = "ref_stock"
const KEY_LAST_PUBLISHED: String = "last_published"
const KEY_HISTORY: String = "history"
const KEY_DAYS_BELOW: String = "days_below"
const KEY_DECLARED: String = "declared"
const SEVERITY_SCALE: int = 100

var _params: PriceParams
var _goods: Dictionary[String, GoodDef] = {}
var _targets: Dictionary[String, Dictionary] = {}
var _book: OwnerBook
var _store: GoodsStore
var _market_of: Dictionary[String, int] = {}
var _states: Dictionary[int, Dictionary] = {}


## `targets`: as linhas de `market_targets.json` (só as com alvo maior que 0 contam como bem negociado).
func _init(book: OwnerBook, store: GoodsStore, goods: Array[GoodDef], targets: Array[MarketTargetDef], params: PriceParams) -> void:
	_book = book
	_store = store
	_params = params
	for good: GoodDef in goods:
		_goods[good.id] = good
	for target: MarketTargetDef in targets:
		if target.target_stock > 0:
			var by_good: Dictionary = _targets.get(target.settlement_id, {})
			by_good[target.good_id] = target
			_targets[target.settlement_id] = by_good


## Os assentamentos que têm mercado nos dados, em ordem alfabética.
func settlement_ids() -> Array[String]:
	var ids: Array[String] = []
	ids.assign(_targets.keys())
	ids.sort()
	return ids


## Os bens negociados num assentamento, em ordem alfabética (vazia se o assentamento não tem mercado nos dados).
func traded_goods(settlement_id: String) -> Array[String]:
	var ids: Array[String] = []
	ids.assign(_targets.get(settlement_id, {}).keys())
	ids.sort()
	return ids


## Registra o mercado de `settlement_id` com o dono `market_id` (já aberto e com o estoque inicial): o preço de cada bem nasce da fórmula com o estoque de hoje, e esse estoque vira o de referência.
func register_market(settlement_id: String, market_id: int) -> void:
	_market_of[settlement_id] = market_id
	var states: Dictionary = {}
	for good_id: String in traded_goods(settlement_id):
		var target: MarketTargetDef = _targets[settlement_id][good_id]
		var stock: int = _store.quantity_of(market_id, good_id)
		var price: int = PriceMath.goal_price(_goods[good_id].base_value, target.target_stock, stock, _params)
		states[good_id] = {KEY_PRICE: price, KEY_REF_STOCK: stock, KEY_LAST_PUBLISHED: price, KEY_HISTORY: [price], KEY_DAYS_BELOW: 0, KEY_DECLARED: false}
	_states[market_id] = states


## O estoque inicial do bem no mercado do assentamento (dado de `market_targets.json`).
func initial_stock_of(settlement_id: String, good_id: String) -> int:
	var target: MarketTargetDef = _targets.get(settlement_id, {}).get(good_id)
	return target.initial_stock if target != null else 0


func has_market(market_id: int) -> bool:
	return _states.has(market_id)


## O mercado do assentamento (`IdGenerator.NO_ID` se não existe).
func market_of(settlement_id: String) -> int:
	return int(_market_of.get(settlement_id, IdGenerator.NO_ID))


func settlement_of(market_id: int) -> String:
	for settlement_id: String in settlement_ids():
		if market_of(settlement_id) == market_id:
			return settlement_id
	return ""


## Os mercados, por ID crescente.
func market_ids() -> Array[int]:
	var ids: Array[int] = []
	ids.assign(_states.keys())
	ids.sort()
	return ids


func is_traded(market_id: int, good_id: String) -> bool:
	return _states.get(market_id, {}).has(good_id)


## Preço de tabela (0 se o bem não é negociado nesse mercado).
func price_of(market_id: int, good_id: String) -> int:
	return int(_states.get(market_id, {}).get(good_id, {}).get(KEY_PRICE, 0))


func ref_stock_of(market_id: int, good_id: String) -> int:
	return int(_states.get(market_id, {}).get(good_id, {}).get(KEY_REF_STOCK, 0))


func target_of(market_id: int, good_id: String) -> int:
	var target: MarketTargetDef = _targets.get(settlement_of(market_id), {}).get(good_id)
	return target.target_stock if target != null else 0


## Teto de compra do bem: acima dele o mercado não compra (DEC-177).
func buy_cap_of(market_id: int, good_id: String) -> int:
	var target: MarketTargetDef = _targets.get(settlement_of(market_id), {}).get(good_id)
	return target.buy_cap() if target != null else 0


func is_in_shortage(market_id: int, good_id: String) -> bool:
	return bool(_states.get(market_id, {}).get(good_id, {}).get(KEY_DECLARED, false))


## Os últimos preços diários, do mais antigo ao mais novo (cópia).
func history_of(market_id: int, good_id: String) -> Array[int]:
	var history: Array[int] = []
	history.assign(_states.get(market_id, {}).get(good_id, {}).get(KEY_HISTORY, []))
	return history


## O preço de tabela, o `ask` e o `bid` do bem no estoque de hoje.
func ask_of(market_id: int, good_id: String) -> int:
	return PriceMath.ask(PriceMath.price_at(price_of(market_id, good_id), _goods[good_id].base_value, target_of(market_id, good_id), ref_stock_of(market_id, good_id), _store.quantity_of(market_id, good_id), _params), _params.spread_bp)


func bid_of(market_id: int, good_id: String) -> int:
	return PriceMath.bid(PriceMath.price_at(price_of(market_id, good_id), _goods[good_id].base_value, target_of(market_id, good_id), ref_stock_of(market_id, good_id), _store.quantity_of(market_id, good_id), _params), _params.spread_bp)


## Fim do dia: para cada mercado e bem (por ID e `good_id` crescentes), o preço anda em direção ao preço-alvo do estoque de agora, o estoque vira o de referência, o histórico cresce e a escassez é conferida.
## Devolve os eventos desse dia, na ordem, para quem chama publicar.
func end_of_day() -> Array[SimEvent]:
	var events: Array[SimEvent] = []
	for market_id: int in market_ids():
		var states: Dictionary = _states[market_id]
		var good_ids: Array[String] = []
		good_ids.assign(states.keys())
		good_ids.sort()
		for good_id: String in good_ids:
			_end_of_day_for(market_id, good_id, states[good_id], events)
	return events


func _end_of_day_for(market_id: int, good_id: String, state: Dictionary, events: Array[SimEvent]) -> void:
	var target: int = target_of(market_id, good_id)
	var stock: int = _store.quantity_of(market_id, good_id)
	var goal: int = PriceMath.goal_price(_goods[good_id].base_value, target, stock, _params)
	var price: int = PriceMath.smoothed_price(int(state[KEY_PRICE]), goal, _params.smoothing_bp)
	state[KEY_PRICE] = price
	state[KEY_REF_STOCK] = stock
	var history: Array = state[KEY_HISTORY]
	history.append(price)
	while history.size() > _params.history_days:
		history.pop_front()
	var last: int = int(state[KEY_LAST_PUBLISHED])
	if absi(price - last) * PriceMath.BASIS > _params.significant_change_bp * last:
		events.append(PriceChanged.new(market_id, good_id, last, price))
		state[KEY_LAST_PUBLISHED] = price
	if stock * PriceMath.BASIS < target * _params.shortage_threshold_bp:
		state[KEY_DAYS_BELOW] = int(state[KEY_DAYS_BELOW]) + 1
		if int(state[KEY_DAYS_BELOW]) >= _params.shortage_days and not state[KEY_DECLARED]:
			state[KEY_DECLARED] = true
			var declared: ShortageDeclared = ShortageDeclared.new(market_id, good_id, stock, target)
			declared.severity = clampi(SEVERITY_SCALE - IntMath.floor_div(SEVERITY_SCALE * stock, target), 0, SEVERITY_SCALE)
			events.append(declared)
	else:
		if state[KEY_DECLARED]:
			events.append(ShortageEnded.new(market_id, good_id, int(state[KEY_DAYS_BELOW])))
		state[KEY_DECLARED] = false
		state[KEY_DAYS_BELOW] = 0


func is_pristine() -> bool:
	return _states.is_empty()


func serialize() -> Dictionary:
	var markets: Dictionary = {}
	for market_id: int in market_ids():
		var goods: Dictionary = {}
		var good_ids: Array[String] = []
		good_ids.assign(_states[market_id].keys())
		good_ids.sort()
		for good_id: String in good_ids:
			var state: Dictionary = _states[market_id][good_id]
			goods[good_id] = {KEY_PRICE: state[KEY_PRICE], KEY_REF_STOCK: state[KEY_REF_STOCK], KEY_LAST_PUBLISHED: state[KEY_LAST_PUBLISHED], KEY_HISTORY: state[KEY_HISTORY].duplicate(), KEY_DAYS_BELOW: state[KEY_DAYS_BELOW], KEY_DECLARED: state[KEY_DECLARED]}
		markets[str(market_id)] = {KEY_SETTLEMENT: settlement_of(market_id), KEY_GOODS: goods}
	return {KEY_MARKETS: markets}


## Confere tudo antes de alterar o estado: o dono existe e é do tipo `market`, o assentamento tem mercado nos dados, os bens são exatamente os negociados, e cada preço, estoque de referência, histórico e contagem estão
## na faixa. Se algo for inválido, o livro fica como estava.
func load_from(data: Dictionary) -> Result:
	var raw_markets: Variant = data.get(KEY_MARKETS)
	if typeof(raw_markets) != TYPE_DICTIONARY:
		return _invalid_save("campo '%s' ausente ou não é um objeto" % KEY_MARKETS)
	var markets_by_settlement: Dictionary[String, int] = {}
	var states: Dictionary[int, Dictionary] = {}
	var raw_table: Dictionary = raw_markets
	for key: Variant in raw_table.keys():
		var market_id: int = EconomyJson.id_of_key(key)
		var raw_entry: Variant = raw_table[key]
		if not _book.has_owner(market_id) or _book.kind_of(market_id) != KIND_MARKET or typeof(raw_entry) != TYPE_DICTIONARY:
			return _invalid_save("mercado '%s': esperado o ID de um dono do tipo '%s' e um objeto" % [str(key), KIND_MARKET])
		var entry: Dictionary = raw_entry
		var settlement_id: Variant = entry.get(KEY_SETTLEMENT)
		if typeof(settlement_id) != TYPE_STRING or not _targets.has(str(settlement_id)) or markets_by_settlement.has(str(settlement_id)):
			return _invalid_save("mercado %d: assentamento inválido ou repetido (esperado um dos dados: %s)" % [market_id, ", ".join(settlement_ids())])
		var parsed: Result = _parse_goods(market_id, str(settlement_id), entry.get(KEY_GOODS), states)
		if not parsed.ok:
			return parsed
		markets_by_settlement[str(settlement_id)] = market_id
	_market_of = markets_by_settlement
	_states = states
	return Result.success()


func validate() -> Array[String]:
	var problems: Array[String] = []
	for market_id: int in market_ids():
		if not _book.has_owner(market_id) or _book.kind_of(market_id) != KIND_MARKET:
			problems.append("o mercado %d não é um dono do tipo '%s'" % [market_id, KIND_MARKET])
	return problems


func _parse_goods(market_id: int, settlement_id: String, raw_goods: Variant, states: Dictionary[int, Dictionary]) -> Result:
	if typeof(raw_goods) != TYPE_DICTIONARY:
		return _invalid_save("mercado %d: campo '%s' ausente ou não é um objeto" % [market_id, KEY_GOODS])
	var goods: Dictionary = raw_goods
	if goods.size() != traded_goods(settlement_id).size():
		return _invalid_save("mercado %d: esperados exatamente os %d bens negociados em '%s'" % [market_id, traded_goods(settlement_id).size(), settlement_id])
	var parsed: Dictionary = {}
	for good_key: Variant in goods.keys():
		var good_id: String = str(good_key)
		var raw_state: Variant = goods[good_key]
		if not traded_goods(settlement_id).has(good_id) or typeof(raw_state) != TYPE_DICTIONARY:
			return _invalid_save("mercado %d: o bem '%s' não é negociado em '%s'" % [market_id, good_id, settlement_id])
		var state: Dictionary = raw_state
		var low: int = PriceMath.floor_price(_goods[good_id].base_value, _params)
		var high: int = PriceMath.ceiling_price(_goods[good_id].base_value, _params)
		for field: String in [KEY_PRICE, KEY_LAST_PUBLISHED]:
			if not EconomyJson.is_int_like(state.get(field)) or EconomyJson.to_int(state[field]) < low or EconomyJson.to_int(state[field]) > high:
				return _invalid_save("mercado %d, bem '%s': '%s' deve ser um inteiro de %d a %d" % [market_id, good_id, field, low, high])
		for field: String in [KEY_REF_STOCK, KEY_DAYS_BELOW]:
			if not EconomyJson.is_int_like(state.get(field)) or EconomyJson.to_int(state[field]) < 0:
				return _invalid_save("mercado %d, bem '%s': '%s' deve ser um inteiro de 0 ou mais" % [market_id, good_id, field])
		var history: Variant = state.get(KEY_HISTORY)
		if typeof(history) != TYPE_ARRAY or (history as Array).is_empty() or (history as Array).size() > _params.history_days or typeof(state.get(KEY_DECLARED)) != TYPE_BOOL:
			return _invalid_save("mercado %d, bem '%s': '%s' deve ser uma lista de 1 a %d preços e '%s', verdadeiro ou falso" % [market_id, good_id, KEY_HISTORY, _params.history_days, KEY_DECLARED])
		var prices: Array[int] = []
		for item: Variant in history:
			if not EconomyJson.is_int_like(item) or EconomyJson.to_int(item) < low or EconomyJson.to_int(item) > high:
				return _invalid_save("mercado %d, bem '%s': o histórico tem preço fora da faixa %d a %d" % [market_id, good_id, low, high])
			prices.append(EconomyJson.to_int(item))
		parsed[good_id] = {KEY_PRICE: EconomyJson.to_int(state[KEY_PRICE]), KEY_REF_STOCK: EconomyJson.to_int(state[KEY_REF_STOCK]), KEY_LAST_PUBLISHED: EconomyJson.to_int(state[KEY_LAST_PUBLISHED]), KEY_HISTORY: prices, KEY_DAYS_BELOW: EconomyJson.to_int(state[KEY_DAYS_BELOW]), KEY_DECLARED: state[KEY_DECLARED]}
	states[market_id] = parsed
	return Result.success()


func _invalid_save(detail: String) -> Result:
	return Result.failure(EconomyCodes.INVALID_SAVE, "MarketBook.load_from: %s." % detail)
