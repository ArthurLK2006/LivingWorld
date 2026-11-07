class_name InteractionPerformed
extends SimEvent
## Fato: um ator interagiu com um ponto de interesse (LW-049). Carga pequena: só IDs e o tipo do ponto. `cause_id` é preenchido pelo
## EventBus (NO_CAUSE quando ninguém o provocou). Catalogado em docs/events.md.

var actor_id: int
var poi_id: String
var kind: String


func _init(for_actor_id: int, for_poi_id: String, poi_kind: String) -> void:
	super("InteractionPerformed")
	actor_id = for_actor_id
	poi_id = for_poi_id
	kind = poi_kind
