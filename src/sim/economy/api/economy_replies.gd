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


## `peek_quote(actor_id, ...)`: a mesma conta de `request_trade` para o ator, sem executar: o `total`, o preço médio (o total dividido pela quantidade, para baixo) e a `tariff`; só valem se `result.ok`.
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


## `peek_site` e `peek_site_at`: um local de produção (seções 6 e 8 do contrato). `workplace_id` é o `site_id`; `worker_ids`, os trabalhadores atribuídos em ordem crescente; `running` e `reason` (`NO_WORKER`, `NO_INPUT`, `OUTPUT_FULL` ou `NO_FUNDS` quando parado,
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


## `peek_post`, `peek_post_at`: um posto de serviço (LW-095; seção 6 do contrato), com os mesmos nomes do local de produção para a LW-096a pontuar a vaga sem distinguir os dois: `workplace_id` é o `post_id`; `place_id`; `settlement_id`;
## `occupation_id` (o ofício esperado); `wage_per_hour`; `workers_wanted`; `workers_assigned`; `worker_ids`, em ordem crescente; `running` e `reason` (`NO_FUNDS` quando a conta do mercado não cobre a folha, senão vazio). O posto não tem
## receita, eficiência nem estoque. `result` falha com `ECON_UNKNOWN_OWNER` se não há o posto (então o resto não vale).
class PostQuery:
	extends RefCounted

	var result: Result
	var workplace_id: int = IdGenerator.NO_ID
	var place_id: String = ""
	var settlement_id: String = ""
	var occupation_id: String = ""
	var wage_per_hour: int = 0
	var workers_wanted: int = 0
	var workers_assigned: int = 0
	var worker_ids: Array[int] = []
	var running: bool = false
	var reason: String = ""

	func _init(query_result: Result) -> void:
		result = query_result


## `peek_posts_of`: os postos de serviço do assentamento, por ID crescente.
class PostsQuery:
	extends RefCounted

	var posts: Array[PostQuery]

	func _init(post_rows: Array[PostQuery]) -> void:
		posts = post_rows


## `request_consume`: o que o consumo fez: a quantidade consumida, o id da necessidade que o bem alivia (`need_id` de `goods.json`) e o alívio total (`need_relief` × quantidade) para o `npc` aplicar; só valem se `result.ok`.
class ConsumeResult:
	extends RefCounted

	var result: Result
	var quantity: int
	var need_id: String
	var relief: int

	func _init(consume_result: Result, consumed_quantity: int, relieved_need_id: String, total_relief: int) -> void:
		result = consume_result
		quantity = consumed_quantity
		need_id = relieved_need_id
		relief = total_relief


## `peek_good`: a ficha de um bem (`need_id` e `need_relief` só valem para comida: texto vazio e 0 nos outros); `result` falha com `ECON_UNKNOWN_GOOD`.
class GoodQuery:
	extends RefCounted

	var result: Result
	var good_id: String
	var need_id: String
	var need_relief: int
	var base_value: int
	var weight: int

	func _init(query_result: Result, queried_good_id: String = "", relieved_need_id: String = "", relief: int = 0, value: int = 0, unit_weight: int = 0) -> void:
		result = query_result
		good_id = queried_good_id
		need_id = relieved_need_id
		need_relief = relief
		base_value = value
		weight = unit_weight


## `peek_goods_for_need`: os bens que aliviam a necessidade, por `good_id` crescente (lista vazia se nenhum).
class GoodsQuery:
	extends RefCounted

	var goods: Array[GoodQuery]

	func _init(found_goods: Array[GoodQuery]) -> void:
		goods = found_goods

