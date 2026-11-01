class_name WalkerModule
extends SimModule
## Módulo de teste que usa os quatro serviços do núcleo (aleatoriedade, IDs, eventos, relógio)
## para dar ao estado do mundo algo que realmente muda ao longo da simulação.

var value: int = 0
var last_id: int = 0
var events_seen: int = 0
var _ctx: SimContext
var _subscription: int = 0


func setup(context: SimContext) -> void:
	_ctx = context


func post_setup() -> void:
	_subscription = _ctx.events.subscribe("WalkerStepped", _on_stepped)


func tick(elapsed_minutes: int) -> void:
	value += _ctx.rng.range_int("walker", 1, 6) * elapsed_minutes
	last_id = _ctx.ids.next_id()
	if _ctx.clock.total_minutes() % 100 == 0:
		_ctx.events.publish(TestEvent.new("WalkerStepped"))


func serialize() -> Dictionary:
	return {"value": value, "last_id": last_id, "events_seen": events_seen}


func on_load(data: Dictionary) -> Result:
	value = int(data["value"])
	last_id = int(data["last_id"])
	events_seen = int(data["events_seen"])
	return Result.success()


func teardown() -> void:
	_ctx.events.unsubscribe(_subscription)


func _on_stepped(_event: SimEvent) -> void:
	events_seen += 1
