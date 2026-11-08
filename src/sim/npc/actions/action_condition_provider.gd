class_name ActionConditionProvider
extends RefCounted
## Interface mínima (LW-060) das condições de ação que dependem de dado que o `npc` ainda não tem ou que é de outro dono: comida no
## assentamento (`has_food`, TEMP-LW-065) e vaga num local (`place_has_room`, ocupação derivada, LW-061). O ActionRunner recebe um
## provedor OPCIONAL pelo construtor (sem global, sem autoload). SEM provedor, ou com esta classe-base, a condição NÃO é atendida: falha
## segura (uma ação que depende de comida nunca começa por engano). Quem entrega a resposta de verdade herda desta classe e sobrescreve.


## Há comida para uma refeição no assentamento? (a regra de "quanto basta" é do provedor)
func has_food(_settlement_id: String) -> bool:
	return false


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
