class_name SimulationRunner
extends RefCounted

const MINUTES_PER_DAY: int = 1440
var context: SimContext
var world: SimWorld
var scheduler: SimScheduler:
	get: return context.scheduler
	set(value): context.scheduler = value


func _init(world_seed: int) -> void:
	context = SimContext.new(world_seed)
	world = SimWorld.new(context)
	world.setup()
	world.on_new_game(world_seed)


func advance_minute() -> SimResult:
	var progress: Dictionary = context.runner_progress
	if progress["remaining_steps"] == 0:
		progress["remaining_steps"] = context.clock.requested_steps()
		if progress["remaining_steps"] == 0:
			return SimResult.new(true)
		progress["next_minute"] = context.clock.total_minutes() + 1
	while progress["remaining_steps"] > 0:
		if not progress["minute_scheduled"]:
			context.clock.advance_single_step()
			world.tick(1.0)
			if not scheduler.schedule_minute(progress["next_minute"]):
				return SimResult.new(false, "SCHEDULE_FAILED", "Não foi possível agendar o minuto.")
			progress["minute_scheduled"] = true
		var result: SimResult = scheduler.run_budget(3000)
		if not result.ok:
			return result
		if scheduler.has_pending():
			return SimResult.new(true, "WORK_PENDING", "O trabalho continua no próximo quadro.")
		progress["remaining_steps"] -= 1
		progress["next_minute"] = 0
		progress["minute_scheduled"] = false
		if progress["remaining_steps"] > 0:
			progress["next_minute"] = context.clock.total_minutes() + 1
	return SimResult.new(true)


func run_days(days: int) -> SimResult:
	if days < 0:
		return SimResult.new(false, "INVALID_DAYS", "O número de dias deve ser não negativo.")
	for _minute: int in range(days * MINUTES_PER_DAY):
		var result: SimResult = advance_minute()
		while result.ok and result.code == "WORK_PENDING":
			result = advance_minute()
		if not result.ok:
			return result
	return SimResult.new(true)
