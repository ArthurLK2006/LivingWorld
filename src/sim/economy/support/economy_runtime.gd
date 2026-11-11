class_name EconomyRuntime
extends RefCounted
## O que a economia faz com o tempo e na abertura do jogo (LW-092f; divisão do `EconomyModule`, sem mudar comportamento): o jogo novo (mercados e locais de produção, com os IDs do `core`), o fim do dia (mercados, depois locais
## de produção) e a hora de produção, publicando os eventos no `EventBus`. Funções estáticas sobre o `EconomyState`; o relógio (qual hora e qual dia) continua no módulo.


## Jogo novo: um mercado por assentamento dos dados, com o saldo inicial do tipo `market` (motivo `game_start`) e o estoque inicial de cada bem; depois um local de produção por linha dos dados. Falha visível (`push_error`) se um dado não couber.
static func open_new_game(state: EconomyState, ids: IdGenerator) -> void:
	if state.markets == null:
		return
	for settlement_id: String in state.markets.settlement_ids():
		var market_id: int = ids.next_id()
		var opened: Result = state.book.open_owner(market_id, MarketBook.KIND_MARKET)
		if opened.ok:
			opened = _fund_market(state, market_id, settlement_id)
		if not opened.ok:
			push_error("EconomyModule.on_new_game: o mercado de '%s' não abriu: %s" % [settlement_id, opened.message])
			continue
		state.markets.register_market(settlement_id, market_id)
	if state.production != null:
		for definition: SiteDef in state.definitions.production_sites:
			_open_production_site(state, ids, definition)


static func close_day(state: EconomyState, events: EventBus) -> void:
	for event: SimEvent in state.markets.end_of_day():
		events.publish(event)
	if state.production != null:
		state.production.end_of_day()


static func run_production_hour(state: EconomyState, events: EventBus) -> void:
	if state.production == null:
		return
	for event: SimEvent in state.production.hour_step():
		events.publish(event)


## Saldo inicial do tipo `market` (se o tipo tem) e o estoque inicial de cada bem negociado no assentamento.
static func _fund_market(state: EconomyState, market_id: int, settlement_id: String) -> Result:
	var funded: Result = _mint_initial_balance(state, market_id, MarketBook.KIND_MARKET)
	if not funded.ok:
		return funded
	for good_id: String in state.markets.traded_goods(settlement_id):
		var initial_stock: int = state.markets.initial_stock_of(settlement_id, good_id)
		if initial_stock > 0:
			var created: Result = state.goods.create(market_id, good_id, initial_stock, GoodsStore.REASON_GAME_START)
			if not created.ok:
				return created
	return Result.success()


## O saldo inicial do tipo (se o tipo tem), com o motivo `game_start`.
static func _mint_initial_balance(state: EconomyState, owner_id: int, kind_id: String) -> Result:
	for kind: OwnerKindDef in state.definitions.kinds:
		if kind.id == kind_id and kind.initial_balance > 0:
			return state.ledger.mint(owner_id, kind.initial_balance, Ledger.REASON_GAME_START)
	return Result.success()


## Um local de produção por linha dos dados: dono do tipo `site` com o saldo inicial do tipo. Falha visível (`push_error`) se algo não couber.
static func _open_production_site(state: EconomyState, ids: IdGenerator, definition: SiteDef) -> void:
	var site_id: int = ids.next_id()
	var opened: Result = state.book.open_owner(site_id, ProductionBook.KIND_SITE)
	if opened.ok:
		opened = _mint_initial_balance(state, site_id, ProductionBook.KIND_SITE)
	if opened.ok:
		opened = state.production.register_site(site_id, definition)
	if not opened.ok:
		push_error("EconomyModule.on_new_game: o local de produção '%s' não abriu: %s" % [definition.id, opened.message])
