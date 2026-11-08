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
