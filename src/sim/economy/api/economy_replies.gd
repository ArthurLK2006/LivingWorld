class_name EconomyReplies
extends RefCounted
## Tipos de resposta da `economy` (docs/modules/economy.md, seção 10): a porta devolve CÓPIAS destes tipos, nunca um objeto interno (lição da LW-085a). Só os da LW-088; cada
## tarefa acrescenta os seus. Todas as listas saem por ordem crescente.


## `peek_balance`: o saldo de um dono; `result` falha com `ECON_UNKNOWN_OWNER` se o dono não existe (então `balance` não vale).
class BalanceQuery:
	extends RefCounted

	var result: Result
	var balance: int

	func _init(query_result: Result, owner_balance: int) -> void:
		result = query_result
		balance = owner_balance


## `peek_conservation`: a soma de todas as contas, o dinheiro criado e o destruído; `ok` quando soma = criado − destruído (o teste de ouro).
class ConservationQuery:
	extends RefCounted

	var sum: int
	var created: int
	var destroyed: int
	var ok: bool

	func _init(balances_sum: int, total_created: int, total_destroyed: int) -> void:
		sum = balances_sum
		created = total_created
		destroyed = total_destroyed
		ok = balances_sum == total_created - total_destroyed


## `peek_ledger_totals`: uma linha por motivo (`reason`, `moved`, `created`, `destroyed`), por motivo em ordem alfabética; só os motivos que já tiveram movimento.
class LedgerTotals:
	extends RefCounted

	var rows: Array[Dictionary]

	func _init(totals_rows: Array[Dictionary]) -> void:
		rows = totals_rows


## `peek_inventory`: os bens de um dono (`good_id` e `quantity`, por `good_id` crescente), o peso carregado e a capacidade do tipo; `result` falha com `ECON_UNKNOWN_OWNER` se o dono não existe.
class InventoryQuery:
	extends RefCounted

	var result: Result
	var rows: Array[Dictionary]
	var weight: int
	var capacity: int

	func _init(query_result: Result, owner_rows: Array[Dictionary], carried_weight: int, weight_capacity: int) -> void:
		result = query_result
		rows = owner_rows
		weight = carried_weight
		capacity = weight_capacity


## `peek_goods_conservation`: uma linha por bem que já teve movimento (`good_id`, `in_stock`, `created`, `destroyed`, `ok`); `ok` quando TODAS fecham (em estoque = criado − destruído, inclusive o destruído por `maintenance`).
class GoodsConservationQuery:
	extends RefCounted

	var rows: Array[Dictionary]
	var ok: bool

	func _init(conservation_rows: Array[Dictionary]) -> void:
		rows = conservation_rows
		ok = true
		for row: Dictionary in conservation_rows:
			ok = ok and bool(row["ok"])


## `peek_market_of` e `peek_market`: o mercado (`market_id`, `settlement_id`) e uma linha por bem negociado (`good_id`, `stock`, `target_stock`, `price`, `ask`, `bid`, `in_shortage`), por `good_id` crescente;
## `result` falha com `ECON_UNKNOWN_MARKET` se não existe (então o resto não vale).
class MarketQuery:
	extends RefCounted

	var result: Result
	var market_id: int
	var settlement_id: String
	var rows: Array[Dictionary]

	func _init(query_result: Result, id_of_market: int, id_of_settlement: String, market_rows: Array[Dictionary]) -> void:
		result = query_result
		market_id = id_of_market
		settlement_id = id_of_settlement
		rows = market_rows


## `peek_price` e `peek_stock`: um inteiro; `result` falha com `ECON_UNKNOWN_MARKET` ou `ECON_UNKNOWN_GOOD` (então `value` não vale).
class ValueQuery:
	extends RefCounted

	var result: Result
	var value: int

	func _init(query_result: Result, queried_value: int) -> void:
		result = query_result
		value = queried_value


## `request_trade`: o que mudou de mãos (`quantity`, `total` em dinheiro e `tariff`, sempre 0 na Fase 3); só valem se `result.ok`. Nada foi negociado se falhou.
class TradeResult:
	extends RefCounted

	var result: Result
	var quantity: int
	var total: int
	var tariff: int

	func _init(trade_result: Result, traded_quantity: int, traded_total: int, traded_tariff: int) -> void:
		result = trade_result
		quantity = traded_quantity
		total = traded_total
		tariff = traded_tariff


## `peek_quote`: a mesma conta de `request_trade`, sem executar: o `total`, o preço médio (o total dividido pela quantidade, para baixo) e a `tariff`; só valem se `result.ok`.
class QuoteQuery:
	extends RefCounted

	var result: Result
	var total: int
	var average_price: int
	var tariff: int

	func _init(query_result: Result, quoted_total: int, quoted_average: int, quoted_tariff: int) -> void:
		result = query_result
		total = quoted_total
		average_price = quoted_average
		tariff = quoted_tariff


## `peek_terms`: a pergunta da `TradeRules` (proibido, tarifa em pontos-base, exige licença); `result` falha com `ECON_UNKNOWN_MARKET` ou `ECON_UNKNOWN_GOOD`.
class TermsQuery:
	extends RefCounted

	var result: Result
	var banned: bool
	var tariff_bp: int
	var needs_license: bool

	func _init(query_result: Result, is_banned: bool, tariff_basis_points: int, requires_license: bool) -> void:
		result = query_result
		banned = is_banned
		tariff_bp = tariff_basis_points
		needs_license = requires_license


## `peek_site` e `peek_site_at`: um local de produção (seções 6 e 8 do contrato). `workplace_id` é o `site_id`; `worker_ids`, os trabalhadores atribuídos em ordem crescente; `running` e `reason` (`NO_WORKER`, `NO_INPUT` ou `OUTPUT_FULL` quando parado,
## senão vazio); `upkeep`, uma linha por regra de manutenção (`good_id`, `quantity`, `period_days`, `days_since_paid`); `stock`, o inventário do local (`good_id` e `quantity`). `result` falha com `ECON_UNKNOWN_OWNER` se não há o local (então o resto não vale).
class SiteQuery:
	extends RefCounted

	var result: Result
	var workplace_id: int = IdGenerator.NO_ID
	var place_id: String = ""
	var settlement_id: String = ""
	var recipe_id: String = ""
	var occupation_id: String = ""
	var wage_per_hour: int = 0
	var workers_wanted: int = 0
	var workers_assigned: int = 0
	var worker_ids: Array[int] = []
	var efficiency_bp: int = 0
	var batch_progress_bp: int = 0
	var running: bool = false
	var reason: String = ""
	var upkeep: Array[Dictionary] = []
	var stock: Array[Dictionary] = []

	func _init(query_result: Result) -> void:
		result = query_result


## `peek_sites_of`: os locais de produção do assentamento, por ID crescente.
class SitesQuery:
	extends RefCounted

	var sites: Array[SiteQuery]

	func _init(site_rows: Array[SiteQuery]) -> void:
		sites = site_rows
