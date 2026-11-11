class_name EconomyQueries
extends RefCounted
## As consultas da porta da economia (LW-092f; divisão do `EconomyModule`, sem mudar comportamento): cada `peek_*` do módulo é uma linha que chama a função de mesmo nome daqui, passando o estado. Só LÊ o `EconomyState` e
## devolve CÓPIAS (tipos de `EconomyReplies`), nunca um livro. As mensagens de erro continuam dizendo `EconomyModule.<consulta>`, porque é pela porta do módulo que o chamador chega até aqui.


## A mesma conta de `request_trade`, sem executar (para a interface e para o `npc` decidirem antes de pedir).
static func peek_quote(state: EconomyState, market_id: int, good_id: String, quantity: int, side: String) -> EconomyReplies.QuoteQuery:
	if state.engine == null:
		return EconomyReplies.QuoteQuery.new(Result.failure(EconomyCodes.UNKNOWN_MARKET, "EconomyModule.peek_quote: o mercado %d não existe (o módulo não tem mercados)." % market_id), 0, 0, 0)
	var outcome: TradeEngine.Outcome = state.engine.quote(market_id, good_id, quantity, side)
	return EconomyReplies.QuoteQuery.new(outcome.result, outcome.total, IntMath.floor_div(outcome.total, quantity) if outcome.result.ok else 0, outcome.tariff)


## A pergunta da `TradeRules` para o bem no mercado e o ator (a neutra devolve tudo livre).
static func peek_terms(state: EconomyState, good_id: String, market_id: int, actor_id: int) -> EconomyReplies.TermsQuery:
	var checked: Result = _check_traded(state, market_id, good_id, "peek_terms")
	if not checked.ok:
		return EconomyReplies.TermsQuery.new(checked, false, 0, false)
	var terms: TradeTerms = state.rules.peek_terms(good_id, market_id, actor_id)
	return EconomyReplies.TermsQuery.new(Result.success(), terms.banned, terms.tariff_bp, terms.needs_license)


## O local de produção `site_id` (`ECON_UNKNOWN_OWNER` se não existe): receita, estado e motivo de parada, equipe, eficiência, manutenção e estoque (seções 6 e 8 do contrato).
static func peek_site(state: EconomyState, site_id: int) -> EconomyReplies.SiteQuery:
	if state.production == null or not state.production.has_site(site_id):
		return EconomyReplies.SiteQuery.new(Result.failure(EconomyCodes.UNKNOWN_OWNER, "EconomyModule.peek_site: o local de produção %d não existe." % site_id))
	return _site_query(state, site_id)


## O local de produção que ocupa o local `place_id` (`ECON_UNKNOWN_OWNER` se não há).
static func peek_site_at(state: EconomyState, place_id: String) -> EconomyReplies.SiteQuery:
	var site_id: int = IdGenerator.NO_ID if state.production == null else state.production.site_at(place_id)
	if site_id == IdGenerator.NO_ID:
		return EconomyReplies.SiteQuery.new(Result.failure(EconomyCodes.UNKNOWN_OWNER, "EconomyModule.peek_site_at: o local '%s' não tem local de produção." % place_id))
	return _site_query(state, site_id)


## Os locais de produção do assentamento, por ID crescente (lista vazia se não há).
static func peek_sites_of(state: EconomyState, settlement_id: String) -> EconomyReplies.SitesQuery:
	var sites: Array[EconomyReplies.SiteQuery] = []
	if state.production != null:
		for site_id: int in state.production.sites_of(settlement_id):
			sites.append(_site_query(state, site_id))
	return EconomyReplies.SitesQuery.new(sites)


static func peek_balance(state: EconomyState, owner_id: int) -> EconomyReplies.BalanceQuery:
	if not state.book.has_owner(owner_id):
		return EconomyReplies.BalanceQuery.new(Result.failure(EconomyCodes.UNKNOWN_OWNER, "EconomyModule.peek_balance: o dono %d não existe." % owner_id), 0)
	return EconomyReplies.BalanceQuery.new(Result.success(), state.ledger.balance_of(owner_id))


static func peek_conservation(state: EconomyState) -> EconomyReplies.ConservationQuery:
	return EconomyReplies.ConservationQuery.new(state.ledger.sum_of_balances(), state.ledger.total_created(), state.ledger.total_destroyed())


static func peek_ledger_totals(state: EconomyState) -> EconomyReplies.LedgerTotals:
	return EconomyReplies.LedgerTotals.new(state.ledger.totals_rows())


static func peek_inventory(state: EconomyState, owner_id: int) -> EconomyReplies.InventoryQuery:
	if not state.book.has_owner(owner_id):
		return EconomyReplies.InventoryQuery.new(Result.failure(EconomyCodes.UNKNOWN_OWNER, "EconomyModule.peek_inventory: o dono %d não existe." % owner_id), [], 0, 0)
	return EconomyReplies.InventoryQuery.new(Result.success(), state.goods.inventory_rows(owner_id), state.goods.weight_of(owner_id), state.goods.capacity_of(owner_id))


static func peek_goods_conservation(state: EconomyState) -> EconomyReplies.GoodsConservationQuery:
	return EconomyReplies.GoodsConservationQuery.new(state.goods.conservation_rows())


## O mercado do assentamento (`ECON_UNKNOWN_MARKET` se o assentamento não tem).
static func peek_market_of(state: EconomyState, settlement_id: String) -> EconomyReplies.MarketQuery:
	var market_id: int = IdGenerator.NO_ID if state.markets == null else state.markets.market_of(settlement_id)
	if market_id == IdGenerator.NO_ID:
		return EconomyReplies.MarketQuery.new(Result.failure(EconomyCodes.UNKNOWN_MARKET, "EconomyModule.peek_market_of: o assentamento '%s' não tem mercado." % settlement_id), IdGenerator.NO_ID, "", [])
	return peek_market(state, market_id)


## Uma linha por bem negociado (`good_id`, `stock`, `target_stock`, `price`, `ask`, `bid`, `in_shortage`), por `good_id` crescente.
static func peek_market(state: EconomyState, market_id: int) -> EconomyReplies.MarketQuery:
	if state.markets == null or not state.markets.has_market(market_id):
		return EconomyReplies.MarketQuery.new(Result.failure(EconomyCodes.UNKNOWN_MARKET, "EconomyModule.peek_market: o mercado %d não existe." % market_id), IdGenerator.NO_ID, "", [])
	var settlement_id: String = state.markets.settlement_of(market_id)
	var rows: Array[Dictionary] = []
	for good_id: String in state.markets.traded_goods(settlement_id):
		rows.append({"good_id": good_id, "stock": state.goods.quantity_of(market_id, good_id), "target_stock": state.markets.target_of(market_id, good_id), "price": state.markets.price_of(market_id, good_id), "ask": state.markets.ask_of(market_id, good_id), "bid": state.markets.bid_of(market_id, good_id), "in_shortage": state.markets.is_in_shortage(market_id, good_id)})
	return EconomyReplies.MarketQuery.new(Result.success(), market_id, settlement_id, rows)


## O preço de tabela do bem no mercado (`ECON_UNKNOWN_MARKET` ou `ECON_UNKNOWN_GOOD` se o mercado não existe ou não negocia o bem).
static func peek_price(state: EconomyState, market_id: int, good_id: String) -> EconomyReplies.ValueQuery:
	var checked: Result = _check_traded(state, market_id, good_id, "peek_price")
	return EconomyReplies.ValueQuery.new(checked, state.markets.price_of(market_id, good_id) if checked.ok else 0)


## O estoque do bem no mercado (a quantidade do dono mercado), com as mesmas falhas de `peek_price`.
static func peek_stock(state: EconomyState, market_id: int, good_id: String) -> EconomyReplies.ValueQuery:
	var checked: Result = _check_traded(state, market_id, good_id, "peek_stock")
	return EconomyReplies.ValueQuery.new(checked, state.goods.quantity_of(market_id, good_id) if checked.ok else 0)


static func _check_traded(state: EconomyState, market_id: int, good_id: String, operation: String) -> Result:
	if state.markets == null or not state.markets.has_market(market_id):
		return Result.failure(EconomyCodes.UNKNOWN_MARKET, "EconomyModule.%s: o mercado %d não existe." % [operation, market_id])
	if not state.markets.is_traded(market_id, good_id):
		return Result.failure(EconomyCodes.UNKNOWN_GOOD, "EconomyModule.%s: o bem '%s' não é negociado no mercado %d." % [operation, good_id, market_id])
	return Result.success()


## A cópia do local para a porta: o estado do livro mais a receita (ofício esperado e salário), as regras de manutenção e o estoque.
static func _site_query(state: EconomyState, site_id: int) -> EconomyReplies.SiteQuery:
	var site_state: Dictionary = state.production.state_of(site_id)
	var recipe: RecipeDef = state.definitions.recipes[site_state[ProductionBook.KEY_RECIPE]]
	var query: EconomyReplies.SiteQuery = EconomyReplies.SiteQuery.new(Result.success())
	query.workplace_id = site_id
	query.place_id = site_state[ProductionBook.KEY_PLACE]
	query.settlement_id = site_state[ProductionBook.KEY_SETTLEMENT]
	query.recipe_id = recipe.id
	query.occupation_id = recipe.occupation_id
	query.wage_per_hour = recipe.wage_per_hour
	query.workers_wanted = site_state[ProductionBook.KEY_WANTED]
	query.worker_ids.assign(site_state[ProductionBook.KEY_WORKERS])
	query.workers_assigned = query.worker_ids.size()
	query.efficiency_bp = site_state[ProductionBook.KEY_EFFICIENCY]
	query.batch_progress_bp = site_state[ProductionBook.KEY_PROGRESS]
	query.running = site_state["running"]
	query.reason = site_state[ProductionBook.KEY_REASON]
	var days: Dictionary = site_state[ProductionBook.KEY_UPKEEP]
	for rule: UpkeepRule in recipe.upkeep:
		query.upkeep.append({"good_id": rule.good_id, "quantity": rule.quantity, "period_days": rule.period_days, "days_since_paid": days[rule.good_id]})
	query.stock = state.goods.inventory_rows(site_id)
	return query
