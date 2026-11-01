class_name TestEvent
extends SimEvent
## Evento genérico só para testes do EventBus (não é um evento do jogo e não consta em docs/events.md).

var tag: String


func _init(event_type: String, event_tag: String = "") -> void:
	super(event_type)
	tag = event_tag
