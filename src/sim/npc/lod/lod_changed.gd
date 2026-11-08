class_name LodChanged
extends SimEvent
## Fato: um NPC trocou de nível de simulação (LW-069): 0 = S0 (com corpo) e 1 = S1 (sem corpo), constantes NpcLod.LEVEL_S0 e LEVEL_S1.
## Só sai na TROCA (a histerese do LOD evita o pisca-pisca). Carga pequena: só o ID e os dois níveis; `cause_id` é preenchido pelo
## EventBus (NO_CAUSE quando ninguém o provocou). Catalogado em docs/events.md.

var npc_id: int
var from_level: int
var to_level: int


func _init(changed_npc_id: int, level_before: int, level_after: int) -> void:
	super("LodChanged")
	npc_id = changed_npc_id
	from_level = level_before
	to_level = level_after
