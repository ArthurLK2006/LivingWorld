class_name EventBus
extends RefCounted
## Barramento de eventos próprio (arquitetura 17.2): publicar apenas enfileira; a entrega acontece
## em `dispatch()`, em ponto definido do tick, em ordem determinística:
## eventos na ordem de publicação, ouvintes na ordem de assinatura.
## Evento publicado durante o tratamento de outro entra na fila da rodada seguinte e recebe
## `cause_id` do primeiro, o que forma a cadeia de causa e efeito.

## [HIP] Máximo de rodadas por entrega; o excedente fica na fila para a entrega seguinte (arquitetura 6.5).
const MAX_ROUNDS_PER_DISPATCH: int = 8
const NO_SUBSCRIPTION: int = 0
const KEY_IDS: String = "ids"

var _clock: SimClock
var _ids: IdGenerator = IdGenerator.new()
var _queue: Array[SimEvent] = []
var _next_subscription_id: int = 1
var _listeners: Dictionary[int, Callable] = {}
## tipo de evento -> IDs de assinatura, na ordem em que foram feitas.
var _subscribers_by_type: Dictionary[String, Array] = {}
var _subscription_types: Dictionary[int, String] = {}
var _current_event_id: int = SimEvent.NO_CAUSE
var _is_dispatching: bool = false


func _init(clock: SimClock) -> void:
	_clock = clock


## Assina eventos de um tipo. Devolve o ID da assinatura, ou NO_SUBSCRIPTION (com erro registrado)
## se o tipo for vazio ou o Callable for inválido.
func subscribe(event_type: String, listener: Callable) -> int:
	if event_type.is_empty() or not listener.is_valid():
		push_error("EventBus.subscribe: tipo vazio ou ouvinte inválido (tipo '%s')." % event_type)
		return NO_SUBSCRIPTION
	var subscription_id: int = _next_subscription_id
	_next_subscription_id += 1
	_listeners[subscription_id] = listener
	_subscription_types[subscription_id] = event_type
	if not _subscribers_by_type.has(event_type):
		_subscribers_by_type[event_type] = []
	_subscribers_by_type[event_type].append(subscription_id)
	return subscription_id


## Cancela uma assinatura; cancelar uma inexistente não faz nada.
func unsubscribe(subscription_id: int) -> void:
	if not _listeners.has(subscription_id):
		return
	var event_type: String = _subscription_types[subscription_id]
	_subscribers_by_type[event_type].erase(subscription_id)
	_listeners.erase(subscription_id)
	_subscription_types.erase(subscription_id)


## Enfileira o evento, carimbando `id`, `time` e (se estiver tratando outro evento) `cause_id`.
func publish(event: SimEvent) -> void:
	event.id = _ids.next_id()
	event.time = _clock.total_minutes()
	if event.cause_id == SimEvent.NO_CAUSE:
		event.cause_id = _current_event_id
	_queue.append(event)


## Entrega os eventos enfileirados, em rodadas. Devolve quantos eventos foram entregues.
func dispatch() -> int:
	if _is_dispatching:
		push_error("EventBus.dispatch: chamado durante uma entrega; ouvintes só devem publicar.")
		return 0
	_is_dispatching = true
	var delivered: int = 0
	var rounds: int = 0
	while not _queue.is_empty():
		if rounds >= MAX_ROUNDS_PER_DISPATCH:
			push_error("EventBus.dispatch: limite de %d rodadas atingido; %d eventos ficam para a próxima entrega." % [MAX_ROUNDS_PER_DISPATCH, _queue.size()])
			break
		rounds += 1
		var round_events: Array[SimEvent] = _queue
		_queue = []
		for event: SimEvent in round_events:
			_deliver(event)
			delivered += 1
	_is_dispatching = false
	return delivered


## Solta todas as assinaturas e a fila (encerramento do mundo).
func teardown() -> void:
	_queue = []
	_listeners = {}
	_subscribers_by_type = {}
	_subscription_types = {}
	_current_event_id = SimEvent.NO_CAUSE


func serialize() -> Dictionary:
	return {KEY_IDS: _ids.serialize()}


## Restaura o contador de IDs de evento. A fila é esvaziada; assinaturas não são salvas
## (os módulos assinam de novo em `post_setup`). Só altera o estado se o dado for válido.
func on_load(data: Dictionary) -> Result:
	var ids_data: Variant = data.get(KEY_IDS)
	if typeof(ids_data) != TYPE_DICTIONARY:
		return Result.failure("EVENTBUS_MISSING_FIELD", "EventBus.on_load: campo '%s' ausente ou não é objeto." % KEY_IDS)
	var result: Result = _ids.on_load(ids_data)
	if result.ok:
		_queue = []
	return result


## Chamado entre ticks: um evento ainda na fila seria perdido ao salvar.
func validate() -> Array[String]:
	var problems: Array[String] = _ids.validate()
	if not _queue.is_empty():
		problems.append("EventBus: %d eventos pendentes não entregues." % _queue.size())
	return problems


func debug_summary() -> Dictionary:
	return {"pending": _queue.size(), "subscriptions": _listeners.size(), "ids": _ids.debug_summary()}


func _deliver(event: SimEvent) -> void:
	_current_event_id = event.id
	var subscribed: Array = _subscribers_by_type.get(event.type, [])
	# Cópia: ouvintes podem assinar ou cancelar durante a entrega sem mudar a ordem desta.
	for subscription_id: int in subscribed.duplicate():
		if not _listeners.has(subscription_id):
			continue
		var listener: Callable = _listeners[subscription_id]
		if not listener.is_valid():
			push_error("EventBus: ouvinte da assinatura %d ficou inválido; assinatura removida." % subscription_id)
			unsubscribe(subscription_id)
			continue
		listener.call(event)
	_current_event_id = SimEvent.NO_CAUSE
