class_name SimContext
extends RefCounted

var clock: SimClock
var events: SimEventBus
var rng: WorldRng
var ids: EntityIds
var scheduler: SimScheduler
var runner_progress: Dictionary = {"remaining_steps": 0, "next_minute": 0, "minute_scheduled": false}


func _init(world_seed: int) -> void:
	clock = SimClock.new()
	events = SimEventBus.new()
	rng = WorldRng.new(world_seed)
	ids = EntityIds.new()
	scheduler = SimScheduler.new()
