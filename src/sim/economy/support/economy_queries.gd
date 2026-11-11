class_name EconomyQueries
extends RefCounted
## As consultas da porta da economia (LW-092f; divisão do `EconomyModule`, sem mudar comportamento): cada `peek_*` do módulo é uma linha que chama a função de mesmo nome daqui, passando o estado. Só LÊ o `EconomyState` e
## devolve CÓPIAS (tipos de `EconomyReplies`), nunca um livro. As mensagens de erro continuam dizendo `EconomyModule.<consulta>`, porque é pela porta do módulo que o chamador chega até aqui.


## A mesma conta de `request_trade`, sem executar, PARA O ATOR (as regras de comércio podem depender de quem compra: proibição, tarifa, licença); serve à interface e ao `npc` para decidirem antes de pedir.
static func peek_quote(state: EconomyState, actor_id: int, market_id: int, good_id: String, quantity: int, side: String) -> EconomyReplies.QuoteQuery:
	if state.engine == null:
		return EconomyReplies.QuoteQuery.new(Result.failure(EconomyCodes.UNKNOWN_MARKET, "EconomyModule.peek_quote: o mercado %d não existe (o módulo não tem mercados)." % market_id), 0, 0, 0)
	var outcome: TradeEngine.Outcome = state.engine.quote(market_id, good_id, quantity, side, actor_id)
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


## O posto de serviço `post_id` (`ECON_UNKNOWN_OWNER` se não existe): ofício, salário, equipe e se a folha está paga (seção 6 do contrato).
static func peek_post(state: EconomyState, post_id: int) -> EconomyReplies.PostQuery:
	if state.posts == null or not state.posts.has_post(post_id):
		return EconomyReplies.PostQuery.new(Result.failure(EconomyCodes.UNKNOWN_OWNER, "EconomyModule.peek_post: o posto de serviço %d não existe." % post_id))
	return _post_query(state, post_id)


## O posto de serviço que ocupa o local `place_id` (`ECON_UNKNOWN_OWNER` se não há).
static func peek_post_at(state: EconomyState, place_id: String) -> EconomyReplies.PostQuery:
	var post_id: int = IdGenerator.NO_ID if state.posts == null else state.posts.post_at(place_id)
	if post_id == IdGenerator.NO_ID:
		return EconomyReplies.PostQuery.new(Result.failure(EconomyCodes.UNKNOWN_OWNER, "EconomyModule.peek_post_at: o local '%s' não tem posto de serviço." % place_id))
	return _post_query(state, post_id)


## Os postos de serviço do assentamento, por ID crescente (lista vazia se não há).
static func peek_posts_of(state: EconomyState, settlement_id: String) -> EconomyReplies.PostsQuery:
	var posts: Array[EconomyReplies.PostQuery] = []
	if state.posts != null:
		for post_id: int in state.posts.posts_of(settlement_id):
			posts.append(_post_query(state, post_id))
	return EconomyReplies.PostsQuery.new(posts)


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


## A ficha do bem (`ECON_UNKNOWN_GOOD` se não existe): o que o `npc` precisa para valorizar comida (LW-093; contrato, seção 10). Cópia: o `GoodDef` não sai da economia.
static func peek_good(state: EconomyState, good_id: String) -> EconomyReplies.GoodQuery:
	for good: GoodDef in state.definitions.goods:
		if good.id == good_id:
			return _good_query(good)
	return EconomyReplies.GoodQuery.new(Result.failure(EconomyCodes.UNKNOWN_GOOD, "EconomyModule.peek_good: o bem '%s' não existe." % good_id))


## Os bens que aliviam a necessidade `need_id` (os de comida, `hunger`, na Fase 3), por `good_id` crescente.
static func peek_goods_for_need(state: EconomyState, need_id: String) -> EconomyReplies.GoodsQuery:
	var found: Array[EconomyReplies.GoodQuery] = []
	for good: GoodDef in state.definitions.goods:
		if not need_id.is_empty() and good.need_id == need_id:
			found.append(_good_query(good))
	found.sort_custom(func(first: EconomyReplies.GoodQuery, second: EconomyReplies.GoodQuery) -> bool: return first.good_id < second.good_id)
	return EconomyReplies.GoodsQuery.new(found)


static func _good_query(good: GoodDef) -> EconomyReplies.GoodQuery:
	return EconomyReplies.GoodQuery.new(Result.success(), good.id, good.need_id, good.need_relief, good.base_value, good.weight)


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


static func _post_query(state: EconomyState, post_id: int) -> EconomyReplies.PostQuery:
	var post_state: Dictionary = state.posts.state_of(post_id)
	var query: EconomyReplies.PostQuery = EconomyReplies.PostQuery.new(Result.success())
	query.workplace_id = post_id
	query.place_id = post_state[ServicePostBook.KEY_PLACE]
	query.settlement_id = post_state[ServicePostBook.KEY_SETTLEMENT]
	query.occupation_id = post_state[ServicePostBook.KEY_OCCUPATION]
	query.wage_per_hour = post_state[ServicePostBook.KEY_WAGE]
	query.workers_wanted = post_state[ServicePostBook.KEY_WANTED]
	query.worker_ids.assign(post_state[ServicePostBook.KEY_WORKERS])
	query.workers_assigned = query.worker_ids.size()
	query.running = post_state["running"]
	query.reason = "" if query.running else ServicePostBook.NO_FUNDS
	return query
