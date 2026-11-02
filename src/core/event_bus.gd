class_name SimEventBus
extends RefCounted

const DEFAULT_EVENT_LIMIT: int = 1024

var _next_id: int = 1
var _current_cause: int = 0
var _dispatching: bool = false
var _queue: Array[Dictionary] = []
var _listeners: Dictionary = {}


func subscribe(event_type: String, listener: Callable) -> void:
	if not _listeners.has(event_type):
		_listeners[event_type] = []
	var listeners: Array = _listeners[event_type]
	if not listeners.has(listener):
		listeners.append(listener)


func publish(event_type: String, payload: Dictionary = {}) -> int:
	var event_id: int = _next_id
	_next_id += 1
	_queue.append({"id": event_id, "type": event_type, "cause_id": _current_cause, "payload": payload.duplicate(true)})
	return event_id


func serialize() -> Dictionary:
	return {"next_id": _next_id, "queue": _queue.duplicate(true)}


func dispatch(max_events: int = DEFAULT_EVENT_LIMIT) -> SimResult:
	if max_events < 1:
		return SimResult.new(false, "INVALID_EVENT_LIMIT", "O limite deve ser positivo.")
	if _dispatching:
		return SimResult.new(false, "EVENT_DISPATCH_REENTRANT", "A entrega de eventos já está em andamento.")
	_dispatching = true
	var delivered: int = 0
	while not _queue.is_empty():
		if delivered >= max_events:
			_current_cause = 0
			_dispatching = false
			return SimResult.new(false, "EVENT_LIMIT_EXCEEDED", "Limite de eventos atingido; a fila restante foi preservada.")
		var event: Dictionary = _queue.pop_front()
		delivered += 1
		_current_cause = event["id"]
		var listeners: Array = _listeners.get(event["type"], [])
		for listener: Callable in listeners.duplicate():
			listener.call(event.duplicate(true))
	_current_cause = 0
	_dispatching = false
	return SimResult.new(true)
