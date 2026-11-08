class_name EmbodiedActionRunner
extends ActionRunner
## ActionRunner do jogo com corpos (LW-070b; contrato em docs/modules/npc.md, seções 5 e 6). Para o NPC com Intent pendente (o corpo cumpre a
## ação e só o resultado do corpo, ou o tempo limite do Intent, a encerra) o pensador precisa de duas respostas diferentes das do modo
## abstrato, e este runner as dá SEM mexer no pensador (npc_thinker.gd): (1) `advance` NÃO termina a ação pelo relógio, então o NPC pensa de
## verdade (necessidade urgente ou crítica, alarme, fim do bloco da rotina, morte) com a ação em andamento e a inércia a favor dela; (2)
## `interrupt` CANCELA a ação sem efeito algum (o corpo não cumpriu nada que a simulação possa contar) em vez de aplicar o efeito proporcional.
## Quem não tem Intent pendente usa o caminho abstrato de sempre (`super`). Quem diz se há Intent pendente é quem monta o runner (o quadro
## de Intents do módulo), por um Callable: o runner não conhece o quadro, e assim os dois não formam um ciclo de referências.

## (npc_id: int) -> bool: o NPC tem Intent pendente que ainda vale?
var _is_embodied: Callable


## Os cinco primeiros argumentos são os do ActionRunner; `is_embodied` vem do quadro de Intents (`NpcIntentBoard.has_pending`).
func _init(states: Dictionary[int, NpcState], catalog: Array[ActionDef], need_defs: Array[NeedDef], places: SettlementService, provider: ActionConditionProvider, walk_speed_cm_per_min: int, is_embodied: Callable) -> void:
	super(states, catalog, need_defs, places, provider, walk_speed_cm_per_min)
	_is_embodied = is_embodied


## Com Intent pendente a ação está sempre em andamento: o tempo previsto passar não a encerra (só o resultado do corpo ou o tempo limite).
func advance(npc_id: int, now: int) -> ActionRunner.AdvanceResult:
	if _embodies(npc_id):
		return ActionRunner.AdvanceResult.new(Result.success(), ActionRunner.Outcome.RUNNING)
	return super.advance(npc_id, now)


## Com Intent pendente, trocar de ação é CANCELAR a atual: sem efeito (nem proporcional) e sem mexer nas necessidades. O Intent sai da lista
## porque a ação deixou de ser a dele. Resultado tardio do corpo antigo chega com o contador velho e é descartado e contado.
func interrupt(npc_id: int, now: int) -> Result:
	if not _embodies(npc_id):
		return super.interrupt(npc_id, now)
	return cancel_action(npc_id, _states[npc_id].action_serial)


func _embodies(npc_id: int) -> bool:
	return _is_embodied.is_valid() and bool(_is_embodied.call(npc_id))
