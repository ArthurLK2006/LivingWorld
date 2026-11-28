class_name FlowReplies
extends RefCounted
## Tipos de resposta do fluxo (LW-100c1; docs/modules/economy.md, 9.16.7): a porta devolve CÓPIAS destes tipos, só com campos simples (inteiros, textos e booleano), nunca o `Lot` nem a `RouteRow` do livro: mudar a resposta nunca muda o livro. Arquivo à parte, como `caravan_replies.gd`. As listas saem por `route_id` e por `lot_id` crescentes.
## A porta (`peek_flow_routes`, `peek_flow_lots` e `peek_flow_plan`, LW-100d1b) os devolve; aqui só os tipos, sem dependência da regra nem dos parâmetros do fluxo; os campos derivados são PREENCHIDOS por quem chama (o `FlowRunner`).


## Uma linha de `peek_flow_routes`: a rota já ligada alguma vez. `route_state` (o estado da rota no `world`) e `lots_count` (os lotes dela) são preenchidos por quem chama.
class RouteQuery:
	extends RefCounted

	var route_id: String = ""
	var enabled: bool = false
	var route_state: String = ""
	var risk_carry_bp: int = 0
	var lots_count: int = 0

	## `row`: a linha de que se tira a cópia (sem ela, os campos ficam nos valores iniciais).
	func _init(row: FlowBook.RouteRow = null) -> void:
		if row == null:
			return
		route_id = row.route_id
		enabled = row.enabled
		risk_carry_bp = row.risk_carry_bp


## Uma linha de `peek_flow_lots`: os campos de 9.16.2 e `minutes_left`, os minutos que faltam para a chegada, que quem chama preenche (deriva do relógio; em `held` é `remaining_minutes`).
class LotQuery:
	extends RefCounted

	var lot_id: int = 0
	var route_id: String = ""
	var origin_market_id: int = 0
	var destination_market_id: int = 0
	var good_id: String = ""
	var quantity: int = 0
	var state: String = ""
	var departed_at: int = 0
	var arrives_at: int = 0
	var remaining_minutes: int = 0
	var minutes_left: int = 0

	## `lot`: o registro de que se tira a cópia, campo a campo (os dez de `FlowBook.Lot.KEYS`; o teste confere cada um).
	func _init(lot: FlowBook.Lot = null) -> void:
		if lot == null:
			return
		lot_id = lot.lot_id
		route_id = lot.route_id
		origin_market_id = lot.origin_market_id
		destination_market_id = lot.destination_market_id
		good_id = lot.good_id
		quantity = lot.quantity
		state = lot.state
		departed_at = lot.departed_at
		arrives_at = lot.arrives_at
		remaining_minutes = lot.remaining_minutes


## `peek_flow_routes` (LW-100d1b): as rotas já ligadas alguma vez, por `route_id` crescente (acréscimo, como o `CaravanReplies.CaravansQuery`). `result` é sempre ok hoje; o tipo guarda o lugar de uma falha futura.
class RoutesQuery:
	extends RefCounted

	var result: Result
	var rows: Array[RouteQuery]

	func _init(query_result: Result, route_rows: Array[RouteQuery] = []) -> void:
		result = query_result
		rows = route_rows


## `peek_flow_lots` (LW-100d1b): os lotes, por `lot_id` crescente (acréscimo). Rota que nunca teve lote dá lista vazia, sem erro.
class LotsQuery:
	extends RefCounted

	var result: Result
	var rows: Array[LotQuery]

	func _init(query_result: Result, lot_rows: Array[LotQuery] = []) -> void:
		result = query_result
		rows = lot_rows


## `peek_flow_plan`: o que a regra enviaria agora (nada é gravado). `result` falha com `ECON_NO_ROUTE` nos casos de 9.16.7; os outros campos só valem se `result.ok` e são preenchidos por quem chama: o sentido (mercado de origem e de destino), o bem, a quantidade planejada, a quantidade enviada (com o resto de risco de hoje), os minutos da viagem e o lucro líquido.
class PlanQuery:
	extends RefCounted

	var result: Result
	var origin_market_id: int = 0
	var destination_market_id: int = 0
	var good_id: String = ""
	var planned_quantity: int = 0
	var sent_quantity: int = 0
	var minutes: int = 0
	var net_profit: int = 0

	func _init(query_result: Result) -> void:
		result = query_result
