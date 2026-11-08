class_name NpcDied
extends SimEvent
## Fato: um NPC morreu de necessidade crítica prolongada (LW-081). Carga pequena: o ID, a causa (o id da necessidade letal, por exemplo
## `hunger`) e o tier. `cause_id` é preenchido pelo EventBus. Catalogado em docs/events.md.

var npc_id: int
var cause: String
var tier: int


func _init(dead_npc_id: int, death_cause: String, dead_tier: int) -> void:
	super("NpcDied")
	npc_id = dead_npc_id
	cause = death_cause
	tier = dead_tier
