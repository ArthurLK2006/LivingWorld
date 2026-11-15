class_name MerchantArrival
extends RefCounted
## O comerciante chega (LW-098g; docs/modules/npc.md, 14.11; economy.md, 9.7): o `npc` ouve `CaravanArrived` (a economia o publica DEPOIS de vender o lote e apagar a caravana) e faz a parte dele. REALOCA o NPC no povoado do destino (`settlement_id`, o local
## `market` de menor id dele e a posição desse local; a viagem não é uma ação do runner e a posição lógica ficou na origem, 098f2/T1). LIBERA o NPC (a caravana já foi apagada, então o pensador não o pula mais, e ele pensa de novo no passo seguinte). ALIVIA
## `income` pelo lucro realizado, `max(0, revenue − cost_paid)`, pelo escritor de `income` do `npc` (`WageIncome`). Dinheiro e bens já mudaram de mãos na economia (a venda da chegada): o `npc` nunca mexe em saldo nem em estoque. O evento só chega DEPOIS dos
## módulos do passo, então o NPC pode ter começado uma ação no minuto da chegada (a caravana já não existia para o pensador): ela é cancelada SEM efeito, e o corpo, se há, sai de S0 antes de a posição mudar (a saída grava a última posição do corpo e a
## nova tem de vir depois), na mesma ordem do detector de impasse. Quem morreu ou o `npc` não conhece não é tocado. Sem estado próprio: nada aqui é salvo e nenhum evento é publicado.

var _npcs: Dictionary[int, NpcState]
var _places: SettlementService
var _income: WageIncome
var _cancel_action: Callable
var _is_embodied: Callable
var _release_body: Callable


## `places`: o `world` (nulo = só o povoado muda, a posição não). `income`: o escritor de `income`. `cancel_action(npc_id, action_serial)`, `is_embodied(npc_id)` e `release_body(npc_id)`: o que o módulo entrega, como ao detector de impasse; callable inválido = não há o que
## cancelar nem soltar.
func _init(npcs: Dictionary[int, NpcState], places: SettlementService, income: WageIncome, cancel_action: Callable, is_embodied: Callable, release_body: Callable) -> void:
	_npcs = npcs
	_places = places
	_income = income
	_cancel_action = cancel_action
	_is_embodied = is_embodied
	_release_body = release_body


## Reação ao `CaravanArrived`; `now` é o minuto atual da simulação. Evento de outro tipo, NPC que o `npc` não conhece ou morto: não faz nada.
func on_caravan_arrived(event: SimEvent, now: int) -> void:
	var arrived: CaravanArrived = event as CaravanArrived
	if arrived == null:
		return
	var state: NpcState = _npcs.get(arrived.trader_id)
	if state == null or not state.is_alive:
		return
	if not state.action_id.is_empty() and _cancel_action.is_valid():
		_cancel_action.call(state.npc_id, state.action_serial)
	if _is_embodied.is_valid() and _release_body.is_valid() and _is_embodied.call(state.npc_id):
		_release_body.call(state.npc_id)
	_relocate(state, arrived.destination_id)
	var profit: int = maxi(0, arrived.revenue - arrived.cost_paid)
	if profit > 0:
		_income.relieve_coins(state, profit, now)
	state.next_think_time = now


## Põe o NPC no povoado do destino: no local `market` de menor id e na posição dele; sem mercado no `world`, no centro do povoado e sem local (o pensador o leva ao mercado). Sem `world`, ou com povoado que ele não conhece, a posição fica como está.
func _relocate(state: NpcState, settlement_id: String) -> void:
	if _places == null:
		return
	var settlement: SettlementService.SettlementQuery = _places.peek_settlement(settlement_id)
	if not settlement.result.ok:
		return
	state.settlement_id = settlement_id
	state.place_id = ""
	var spot: Vector3 = settlement.settlement.position
	var markets: SettlementService.PlacesQuery = _places.peek_places_of_kind(settlement_id, Place.KIND_MARKET)
	if markets.result.ok and not markets.places.is_empty():
		state.place_id = markets.places[0].id
		spot = markets.places[0].position
	state.x_cm = roundi(spot.x * TerrainData.CM_PER_METER)
	state.z_cm = roundi(spot.z * TerrainData.CM_PER_METER)
