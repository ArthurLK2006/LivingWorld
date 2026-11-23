class_name CaravanReplies
extends RefCounted
## Tipos de resposta das caravanas (LW-098c; docs/modules/economy.md, 9.8): a porta devolve CÓPIAS destes tipos, nunca o `Caravan` do livro. Arquivo à parte porque `economy_replies.gd` já tem mais de 300 linhas. As listas saem por `trader_id` crescente.


## `peek_caravan` e cada linha de `peek_caravans_on`: a caravana de um comerciante. `found` falso = parado (sem registro; os outros campos não valem); `result` falha com `ECON_UNKNOWN_OWNER` se o dono não existe. `trader_id` é o dono do registro (as linhas de
## `peek_caravans_on` precisam dele). Os SETE campos derivados da rota e do relógio (a geometria do trecho, a posição e o ETA, 9.3; mais, na LW-099b1, `leg_minutes` e `leg_walked_min`) são preenchidos pelo `CaravanRunner` (LW-098d1) quando a economia tem a porta de rotas do `world` e os parâmetros da caravana;
## sem eles, ou com rota que o `world` não conhece, ficam vazios ou 0. LW-099b1: `leg_minutes` é a duração do trecho atual e `leg_walked_min` os minutos já andados nele (`agora − leg_started_at`, ou `elapsed_at_hold` se parada), cortados em [0, `leg_minutes`]: a apresentação deriva a fração do trecho sem tocar no `progress_m`, que é inteiro e muda uma vez por minuto.
class CaravanQuery:
	extends RefCounted

	var result: Result
	var found: bool = false
	var trader_id: int = IdGenerator.NO_ID
	var state: String = ""
	var origin_market_id: int = IdGenerator.NO_ID
	var destination_market_id: int = IdGenerator.NO_ID
	var route_ids: Array[String] = []
	var leg_index: int = 0
	var current_route_id: String = ""
	var leg_from_settlement_id: String = ""
	var leg_to_settlement_id: String = ""
	var leg_length_m: int = 0
	var progress_m: int = 0
	var eta_minute: int = 0
	var leg_minutes: int = 0
	var leg_walked_min: int = 0
	var good_id: String = ""
	var quantity: int = 0
	var cost_paid: int = 0
	var departed_at: int = 0

	## `caravan`: o registro de que se tira a cópia; sem ele (comerciante parado ou dono desconhecido) só o `result` vale.
	func _init(query_result: Result, caravan: Caravan = null) -> void:
		result = query_result
		if caravan == null:
			return
		found = true
		trader_id = caravan.trader_id
		state = caravan.state
		origin_market_id = caravan.origin_market_id
		destination_market_id = caravan.destination_market_id
		route_ids.assign(caravan.route_ids)
		leg_index = caravan.leg_index
		current_route_id = caravan.current_route_id()
		good_id = caravan.good_id
		quantity = caravan.quantity
		cost_paid = caravan.cost_paid
		departed_at = caravan.departed_at


## `peek_caravans_on`: as caravanas na estrada cujo trecho atual é a rota, por `trader_id` crescente. `peek_caravans` (LW-099b1) devolve este mesmo tipo com TODAS as caravanas, inclusive a parada num povoado.
class CaravansQuery:
	extends RefCounted

	var caravans: Array[CaravanQuery]

	func _init(caravan_rows: Array[CaravanQuery]) -> void:
		caravans = caravan_rows


## Uma linha de `peek_trade_plans` (LW-098d1; 9.8): o melhor plano de um destino, cópia do `TradePlanner.Plan` SEM o `time_cost` (que já está dentro do `net_profit`).
class PlanQuery:
	extends RefCounted

	var destination_market_id: int
	var good_id: String
	var quantity: int
	var cost: int
	var revenue: int
	var risk_discount: int
	var minutes: int
	var net_profit: int
	var margin_bp: int
	var route_ids: Array[String] = []

	func _init(plan: TradePlanner.Plan) -> void:
		destination_market_id = plan.destination_market_id
		good_id = plan.good_id
		quantity = plan.quantity
		cost = plan.cost
		revenue = plan.revenue
		risk_discount = plan.risk_discount
		minutes = plan.minutes
		net_profit = plan.net_profit
		margin_bp = plan.margin_bp
		route_ids.assign(plan.route_ids)


## `peek_trade_plans`: os planos por `destination_market_id` crescente (só os que passam dos limiares de 9.5); `result` falha com o código do comerciante, `ECON_UNKNOWN_MARKET` ou `ECON_NO_ROUTE` (então a lista é vazia).
class PlansQuery:
	extends RefCounted

	var result: Result
	var plans: Array[PlanQuery] = []

	func _init(query_result: Result, found: Array[TradePlanner.Plan] = []) -> void:
		result = query_result
		for plan: TradePlanner.Plan in found:
			plans.append(PlanQuery.new(plan))


## `request_start_caravan`: o minuto da chegada prevista (`eta_minute`) e o que o lote custou (`cost_paid`); só valem se `result.ok`.
class StartResult:
	extends RefCounted

	var result: Result
	var eta_minute: int
	var cost_paid: int

	func _init(start_result: Result, arrival_minute: int = 0, paid: int = 0) -> void:
		result = start_result
		eta_minute = arrival_minute
		cost_paid = paid
