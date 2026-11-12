class_name BridgeEconomyInspect
extends RefCounted
## A conta das consultas de inspeção da economia da ponte (LW-108b; contrato em docs/modules/bridge.md, "Inspeção da economia"). O `SimBridge` só delega para cá, porque ele já passa de 300 linhas. Sem estado e
## sem regra de jogo: cada função só LÊ o módulo `economy` por consultas (`peek_*`, `validate`) e devolve CÓPIAS. Quem confere a ponte sem jogo ou sem `economy` é o `SimBridge`, antes de chamar. Só cita classes
## de `src/sim/economy/api/` (`EconomyModule` e `EconomyReplies`); a regra D do `tools/check_architecture` confere. Nenhuma escrita: nem `request_*`, nem evento.


## Os `settlement_id` distintos dos locais, em ordem crescente: de onde vêm os assentamentos a perguntar à economia (a ponte ainda não expõe as consultas do `world`).
static func settlement_ids_of(places: Array[Place]) -> Array[String]:
	var ids: Array[String] = []
	for place: Place in places:
		if not ids.has(place.settlement_id):
			ids.append(place.settlement_id)
	ids.sort()
	return ids


## O dinheiro, os bens e o livro-razão da economia, com a conferência de cada um e os problemas do `validate()`.
static func overview(economy: EconomyModule) -> BridgeEconomyReplies.EconomyOverviewReply:
	var reply: BridgeEconomyReplies.EconomyOverviewReply = BridgeEconomyReplies.EconomyOverviewReply.new(Result.success())
	var money: EconomyReplies.ConservationQuery = economy.peek_conservation()
	reply.money_sum = money.sum
	reply.money_created = money.created
	reply.money_destroyed = money.destroyed
	reply.is_money_ok = money.ok
	var goods: EconomyReplies.GoodsConservationQuery = economy.peek_goods_conservation()
	reply.is_goods_ok = goods.ok
	for source: Dictionary in goods.rows:
		var row: BridgeEconomyReplies.EconomyGoodsRow = BridgeEconomyReplies.EconomyGoodsRow.new()
		# Variant: os valores do dicionário da economia são conferidos por conversão, como em toda cópia da ponte.
		row.good_id = str(source["good_id"])
		row.in_stock = int(source["in_stock"])
		row.created = int(source["created"])
		row.destroyed = int(source["destroyed"])
		row.is_ok = bool(source["ok"])
		reply.goods.append(row)
	for source: Dictionary in economy.peek_ledger_totals().rows:
		var line: BridgeEconomyReplies.EconomyLedgerRow = BridgeEconomyReplies.EconomyLedgerRow.new()
		line.reason = str(source["reason"])
		line.moved = int(source["moved"])
		line.created = int(source["created"])
		line.destroyed = int(source["destroyed"])
		reply.ledger.append(line)
	reply.problems.assign(economy.validate())
	return reply


## Um mercado por assentamento que tem mercado (quem não tem não é erro e não aparece), em ordem crescente de `market_id`.
static func markets(economy: EconomyModule, settlement_ids: Array[String]) -> BridgeEconomyReplies.EconomyMarketsReply:
	var entries: Array[BridgeEconomyReplies.EconomyMarketEntry] = []
	for settlement_id: String in settlement_ids:
		var query: EconomyReplies.MarketQuery = economy.peek_market_of(settlement_id)
		if not query.result.ok:
			continue
		var entry: BridgeEconomyReplies.EconomyMarketEntry = BridgeEconomyReplies.EconomyMarketEntry.new()
		entry.market_id = query.market_id
		entry.settlement_id = query.settlement_id
		var funds: EconomyReplies.BalanceQuery = economy.peek_balance(query.market_id)
		entry.cash = funds.balance if funds.result.ok else 0
		for source: Dictionary in query.rows:
			var row: BridgeEconomyReplies.EconomyMarketRow = BridgeEconomyReplies.EconomyMarketRow.new()
			row.good_id = str(source["good_id"])
			row.stock = int(source["stock"])
			row.target_stock = int(source["target_stock"])
			row.price = int(source["price"])
			row.ask = int(source["ask"])
			row.bid = int(source["bid"])
			row.is_in_shortage = bool(source["in_shortage"])
			entry.rows.append(row)
		entries.append(entry)
	entries.sort_custom(_market_before)
	return BridgeEconomyReplies.EconomyMarketsReply.new(Result.success(), entries)


## Os locais de produção de todos os assentamentos dados, em ordem crescente de `site_id`, sem o estoque do local nem a manutenção.
static func sites(economy: EconomyModule, settlement_ids: Array[String]) -> BridgeEconomyReplies.EconomySitesReply:
	var entries: Array[BridgeEconomyReplies.EconomySiteEntry] = []
	for settlement_id: String in settlement_ids:
		for source: EconomyReplies.SiteQuery in economy.peek_sites_of(settlement_id).sites:
			var entry: BridgeEconomyReplies.EconomySiteEntry = BridgeEconomyReplies.EconomySiteEntry.new()
			entry.site_id = source.workplace_id
			entry.settlement_id = source.settlement_id
			entry.place_id = source.place_id
			entry.recipe_id = source.recipe_id
			entry.occupation_id = source.occupation_id
			entry.wage_per_hour = source.wage_per_hour
			entry.workers_wanted = source.workers_wanted
			entry.workers_assigned = source.workers_assigned
			entry.is_running = source.running
			entry.reason = source.reason
			entry.efficiency_bp = source.efficiency_bp
			entry.batch_progress_bp = source.batch_progress_bp
			entries.append(entry)
	entries.sort_custom(_site_before)
	return BridgeEconomyReplies.EconomySitesReply.new(Result.success(), entries)


static func _market_before(first: BridgeEconomyReplies.EconomyMarketEntry, second: BridgeEconomyReplies.EconomyMarketEntry) -> bool:
	return first.market_id < second.market_id


static func _site_before(first: BridgeEconomyReplies.EconomySiteEntry, second: BridgeEconomyReplies.EconomySiteEntry) -> bool:
	return first.site_id < second.site_id
