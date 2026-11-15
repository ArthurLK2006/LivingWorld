class_name MerchantTrade
extends RefCounted
## O comerciante no mercado (LW-098f2; docs/modules/npc.md, 14.11; economy.md, 9.2, 9.5 e 9.8): o que o `npc` faz com a porta da economia (`economy/api`, DEC-132) para decidir e começar uma viagem. A conta do lucro é da economia
## (`peek_trade_plans`): o `net_profit` dela JÁ traz o tempo e o risco da viagem, então aqui NADA é descontado de novo. O `npc` só pega o plano de maior `net_profit` do mercado do povoado onde o comerciante está, dá a ele o valor
## `net_profit` × `haul_value_percent` / 100 e, ao COMPLETAR a ação `haul` (o ato de partir; o local é o mercado, que garante a presença, economy.md 9.6), pede `request_start_caravan`. A viagem é da economia (a `Caravan`, derivada do
## relógio): enquanto `peek_caravan(npc_id).found` o NPC está em TRÂNSITO e o pensador não o faz pensar. Não é uma ação do `ActionRunner` porque o runner só conhece o fim fixo (`duration_min`) e o `held` desloca a chegada: caberia
## só mudando o contrato do `npc` (risco T1 de economy.md 9.13). Tudo inteiro, sem sorteio e sem estado: nada aqui é salvo.

const HAUL_ACTION_ID: String = "haul"

var _economy: EconomyModule
var _states: Dictionary[int, NpcState]
var _value_percent: int


## `value_percent`: pontos de utilidade por moeda de lucro esperado, em percentagem (`haul_value_percent` de `npc_params.json`; 100 = um ponto por moeda; 0 = a `haul` não vale nada).
func _init(economy: EconomyModule, states: Dictionary[int, NpcState], value_percent: int) -> void:
	_economy = economy
	_states = states
	_value_percent = value_percent


## O plano de maior `net_profit` que a economia dá ao comerciante no mercado do povoado onde ele está (empate: o primeiro da lista, o de menor `destination_market_id`); nulo se não há (quem não é comerciante, povoado sem mercado
## ou nenhum plano passa dos limiares da economia).
func best_plan(npc_id: int) -> CaravanReplies.PlanQuery:
	var best: CaravanReplies.PlanQuery = null
	var origin: int = _origin_market_id(npc_id)
	if origin == IdGenerator.NO_ID:
		return best
	for plan: CaravanReplies.PlanQuery in _economy.peek_trade_plans(npc_id, origin).plans:
		if best == null or plan.net_profit > best.net_profit:
			best = plan
	return best


## A condição `has_trade_plan` da ação `haul`: há plano de viagem com lucro esperado agora?
func has_trade_plan(npc_id: int) -> bool:
	return best_plan(npc_id) != null


## O valor DERIVADO de `haul` (npc.md, 14.11): só o `net_profit` do melhor plano vezes `value_percent` / 100; 0 se não há plano.
func haul_value(npc_id: int) -> int:
	var plan: CaravanReplies.PlanQuery = best_plan(npc_id)
	return 0 if plan == null else IntMath.floor_div(plan.net_profit * _value_percent, NpcTrade.PERCENT_SCALE)


## O NPC está em viagem (tem caravana na economia)? Então o pensador não o faz pensar e a vaga não o interessa.
func in_transit(npc_id: int) -> bool:
	return _economy.peek_caravan(npc_id).found


## O que a economia faz quando a ação `haul` COMPLETA (ver `ActionConditionProvider.complete_action`): pede a partida do melhor plano de AGORA (a conta é refeita: o preço pode ter andado desde a decisão). Sem plano, ou com a economia
## recusando, é FALHA POR REGRA (npc.md, 14.2): nada entra, nada é comprado e o comerciante fica livre.
func complete(npc_id: int) -> ActionConditionProvider.Completion:
	var plan: CaravanReplies.PlanQuery = best_plan(npc_id)
	if plan == null:
		return ActionConditionProvider.Completion.failed("o comerciante %d não tem plano de viagem com lucro no mercado do povoado dele" % npc_id)
	var started: CaravanReplies.StartResult = _economy.request_start_caravan(npc_id, _origin_market_id(npc_id), plan.destination_market_id, plan.good_id, plan.quantity)
	if not started.result.ok:
		return ActionConditionProvider.Completion.failed("a partida de %d de '%s' para o mercado %d falhou: %s" % [plan.quantity, plan.good_id, plan.destination_market_id, started.result.message])
	return ActionConditionProvider.Completion.new()


## O mercado do povoado onde o NPC está agora (`IdGenerator.NO_ID` se o NPC não existe ou o povoado não tem mercado).
func _origin_market_id(npc_id: int) -> int:
	if not _states.has(npc_id):
		return IdGenerator.NO_ID
	var market: EconomyReplies.MarketQuery = _economy.peek_market_of(_states[npc_id].settlement_id)
	return market.market_id if market.result.ok else IdGenerator.NO_ID
