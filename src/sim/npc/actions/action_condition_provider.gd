class_name ActionConditionProvider
extends RefCounted
## Interface mínima (LW-060) das condições de ação que dependem de dado que o `npc` ainda não tem ou que é de outro dono: comida no
## assentamento (`has_food`, TEMP-LW-065) e vaga num local (`place_has_room`, ocupação derivada, LW-061). O ActionRunner recebe um
## provedor OPCIONAL pelo construtor (sem global, sem autoload). SEM provedor, ou com esta classe-base, a condição NÃO é atendida: falha
## segura (uma ação que depende de comida nunca começa por engano). Quem entrega a resposta de verdade herda desta classe e sobrescreve.


## Há comida para uma refeição no assentamento? (a regra de "quanto basta" é do provedor)
func has_food(_settlement_id: String) -> bool:
	return false


## LW-093: há comida para ESTE NPC? Por padrão vale a do assentamento (`has_food`), então os provedores de teste não mudam; o provedor do jogo olha antes o inventário do NPC (da economia).
func npc_has_food(_npc_id: int, settlement_id: String) -> bool:
	return has_food(settlement_id)


## LW-093: o NPC tem dinheiro e há comida à venda no mercado do povoado dele? Quem decide se `buy` é candidata é o pensador. Sem quem responda, não.
func can_buy_food(_npc_id: int) -> bool:
	return false


## LW-093: o NPC tem algum bem no inventário (o que a ação `sell` vende)? Sem quem responda, não.
func has_goods(_npc_id: int) -> bool:
	return false


## LW-093 (R6-I1): a necessidade que a conclusão da ação vai aliviar pela economia ('' = nenhuma), SEM mudar nada. O `ActionRunner` confere que ela existe nas definições ANTES de chamar `complete_action`, para a economia nunca
## comprar, consumir ou vender por uma ação que depois falharia (troca atômica, npc.md 14.2). O padrão não alivia nenhuma.
func completion_need_id(_npc_id: int, _action_id: String) -> String:
	return ""


## LW-093: a ação COMPLETA do NPC pede à economia o que ela faz (comprar, vender, consumir): devolve o `problem` (texto; vazio = deu certo) e, se comeu do inventário, a necessidade aliviada e o alívio do bem. O runner
## chama depois de conferir de novo as condições e ANTES de aplicar qualquer efeito; com `problem`, a ação falha por regra e nenhum efeito é aplicado. O padrão não faz nada.
func complete_action(_npc_id: int, _action_id: String) -> Completion:
	return Completion.new()


## O que a economia fez ao completar a ação (ver `complete_action`).
class Completion:
	extends RefCounted

	var problem: String = ""
	## Só quando o NPC comeu do inventário: a necessidade que o bem alivia e quanto (o runner corrige o efeito da tabela da ação por esse alívio).
	var relieved_need_id: String = ""
	var relief: int = 0
	## O bem consumido saiu do inventário do NPC (da economia): o estoque provisório de comida (`FoodStub`) não consome nada desta vez.
	var consumed_from_inventory: bool = false

	static func failed(reason: String) -> Completion:
		var failure: Completion = Completion.new()
		failure.problem = reason
		return failure


## O local tem vaga para mais um NPC?
func place_has_room(_place_id: String) -> bool:
	return false


## Gancho (LW-065): o runner o chama DEPOIS que uma ação COMPLETA (progresso 1000) aplicou os efeitos nas necessidades, com o id da ação e
## o assentamento e o ofício do NPC (só texto: o provedor nunca recebe o estado do NPC e não escreve nele). Quem guarda estoque de algo que
## a ação consome ou produz (o FoodStub, TEMP-LW-065) sobrescreve; o padrão não faz nada. Ação interrompida não chama o gancho.
func on_action_completed(_action_id: String, _settlement_id: String, _occupation_id: String) -> void:
	pass


## Efeitos EXTRAS (LW-066) que o provedor soma aos da tabela de efeitos da ação para este ofício, por exemplo o alívio de renda de quem
## trabalha (IncomeStub, TEMP-LW-066). O ActionRunner os aplica na MESMA função e pela MESMA conta dos efeitos da tabela (proporcional ao
## progresso, também na ação interrompida), então o caminho único de escrita nas necessidades continua único. O padrão não tem efeito extra.
func extra_effects(_action_id: String, _occupation_id: String) -> Array[ActionDef.ActionEffect]:
	return []
