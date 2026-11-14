class_name CaravanReplies
extends RefCounted
## Tipos de resposta das caravanas (LW-098c; docs/modules/economy.md, 9.8): a porta devolve CÓPIAS destes tipos, nunca o `Caravan` do livro. Arquivo à parte porque `economy_replies.gd` já tem mais de 300 linhas. As listas saem por `trader_id` crescente.


## `peek_caravan` e cada linha de `peek_caravans_on`: a caravana de um comerciante. `found` falso = parado (sem registro; os outros campos não valem); `result` falha com `ECON_UNKNOWN_OWNER` se o dono não existe. `trader_id` é o dono do registro (as linhas de
## `peek_caravans_on` precisam dele). Os CINCO campos derivados da rota e do relógio (a geometria do trecho, a posição e o ETA, 9.3) dependem da porta de rotas do `world`, que só nasce na 098d1: até lá ficam vazios ou 0.
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


## `peek_caravans_on`: as caravanas na estrada cujo trecho atual é a rota, por `trader_id` crescente.
class CaravansQuery:
	extends RefCounted

	var caravans: Array[CaravanQuery]

	func _init(caravan_rows: Array[CaravanQuery]) -> void:
		caravans = caravan_rows
