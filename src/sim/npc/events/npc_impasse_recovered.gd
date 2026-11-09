class_name NpcImpasseRecovered
extends SimEvent
## Fato: o detector de impasse (LW-073) recuperou um NPC sem progresso: cancelou a ação dele, levou-o a um local válido e o mandou pensar. Carga pequena: o ID,
## o motivo (`no_progress` ou `result_timeout`, constantes de NpcImpasse) e o local onde ele foi posto (vazio se nenhum local pôde ser usado). `cause_id` é preenchido
## pelo EventBus. Catalogado em docs/events.md.

var npc_id: int
var reason: String
var place_id: String


func _init(recovered_npc_id: int, recovery_reason: String, recovery_place_id: String) -> void:
	super("NpcImpasseRecovered")
	npc_id = recovered_npc_id
	reason = recovery_reason
	place_id = recovery_place_id
