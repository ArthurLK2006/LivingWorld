class_name RouteStateChanged
extends SimEvent
## Fato: o estado de uma rota mudou (LW-097c; `docs/events.md`, `docs/modules/world.md`): publicado pelo `world` UMA vez por mudança real
## (nunca por pedido repetido). Carga pequena: o id da rota e o estado novo, em texto (`open` ou `closed`); o estado anterior não vai.
## `cause_id` é preenchido pelo EventBus (NO_CAUSE quando ninguém o provocou).

var route_id: String
var new_state: String


func _init(for_route_id: String, state_after: String) -> void:
	super("RouteStateChanged")
	route_id = for_route_id
	new_state = state_after
