class_name EconomyCommands
extends RefCounted
## Comandos da porta que mexem no estado e não são comércio nem produção (LW-093; docs/modules/economy.md, seção 7). Hoje só o consumo do NPC. Funções estáticas sobre o `EconomyState`; o módulo só delega.


## `request_consume`: destrói do inventário de `owner_id` a `quantity` do bem de consumo (motivo `consumed`) e devolve o alívio total (`need_relief` × quantidade) e o id da necessidade, para o `npc` aplicar: a economia não conhece
## `NpcState` nem necessidades. Falhas, sem mudar nada: `ECON_UNKNOWN_GOOD`, `ECON_NOT_CONSUMABLE` (o bem não tem `need_id`: só comida é consumida pelo NPC, DEC-153 e DEC-163), `ECON_BAD_QUANTITY`, `ECON_UNKNOWN_OWNER`,
## `ECON_OWNER_CLOSED` e `ECON_INSUFFICIENT_GOODS`.
static func consume(state: EconomyState, owner_id: int, good_id: String, quantity: int) -> EconomyReplies.ConsumeResult:
	var good: GoodDef = null
	for candidate: GoodDef in state.definitions.goods:
		if candidate.id == good_id:
			good = candidate
	if good == null:
		return EconomyReplies.ConsumeResult.new(Result.failure(EconomyCodes.UNKNOWN_GOOD, "EconomyModule.request_consume: o bem '%s' não existe." % good_id), 0, "", 0)
	if good.need_id.is_empty():
		return EconomyReplies.ConsumeResult.new(Result.failure(EconomyCodes.NOT_CONSUMABLE, "EconomyModule.request_consume: o bem '%s' não é de consumo do NPC (sem need_id); só comida é consumida." % good_id), 0, "", 0)
	var destroyed: Result = state.goods.destroy(owner_id, good_id, quantity, GoodsStore.REASON_CONSUMED)
	if not destroyed.ok:
		return EconomyReplies.ConsumeResult.new(destroyed, 0, "", 0)
	return EconomyReplies.ConsumeResult.new(Result.success(), quantity, good.need_id, good.need_relief * quantity)
