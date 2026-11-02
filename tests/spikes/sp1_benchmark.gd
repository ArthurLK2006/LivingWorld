extends SceneTree

const POPULATION: int = 1000
# Hipótese para o experimento, não uma duração de ano aprovada.
const DAYS_PER_TEST_YEAR: int = 365
const MINUTES_PER_DAY: int = 1440

class FakePopulation extends SimModule:
	var hunger: PackedInt32Array = PackedInt32Array()
	var actions: int = 0
	var events: SimEventBus
	func setup(ctx: SimContext) -> void:
		events = ctx.events
		hunger.resize(POPULATION)
		for index: int in range(POPULATION):
			hunger[index] = ctx.rng.next_int("population") % 100
	func work() -> bool:
		for index: int in range(POPULATION):
			hunger[index] += 1
			if hunger[index] >= 100:
				hunger[index] = 0
				actions += 1
		events.publish("PopulationUpdated", {"actions": actions})
		return true
	func serialize() -> Dictionary:
		return {"hunger": Array(hunger), "actions": actions}


func _initialize() -> void:
	print("SP1 modo: ", "editor" if OS.has_feature("editor") else "release")
	print("SP1 aquecimento (1 dia): ", _run(123, MINUTES_PER_DAY))
	var expected_hash: String = ""
	for index: int in range(5):
		var measurement: Dictionary = _run(123, DAYS_PER_TEST_YEAR * MINUTES_PER_DAY)
		print("SP1 execução %d: " % (index + 1), measurement)
		if measurement.has("error"):
			printerr("SP1: erro na execução")
			quit(1)
			return
		if expected_hash.is_empty():
			expected_hash = measurement["hash"]
		elif expected_hash != measurement["hash"]:
			printerr("SP1: hashes diferentes")
			quit(1)
			return
	quit(0)


func _run(world_seed: int, minutes: int) -> Dictionary:
	var initialization_start: int = Time.get_ticks_usec()
	var runner: SimulationRunner = SimulationRunner.new(world_seed)
	var population: FakePopulation = FakePopulation.new()
	if not runner.world.register_module("sp1_population", population):
		return {"error": "registro de módulo falhou"}
	runner.world.setup()
	runner.world.on_new_game(world_seed)
	if not runner.scheduler.register_job(60, population.work):
		return {"error": "registro no agendador falhou"}
	var initialization_us: int = Time.get_ticks_usec() - initialization_start
	var maximum_us: int = 0
	var elapsed_us: int = 0
	var samples: PackedInt64Array = PackedInt64Array()
	samples.resize(minutes)
	var spikes: Array[Dictionary] = []
	for minute: int in range(minutes):
		var start: int = Time.get_ticks_usec()
		var result: SimResult = runner.advance_minute()
		while result.ok and result.code == "WORK_PENDING":
			result = runner.advance_minute()
		if not result.ok:
			return {"error": result.code}
		var after_runner: int = Time.get_ticks_usec()
		var event_result: SimResult = runner.context.events.dispatch()
		if not event_result.ok:
			return {"error": event_result.code}
		var duration: int = Time.get_ticks_usec() - start
		samples[minute] = duration
		if duration > 10000:
			spikes.append({"minute": minute + 1, "total_us": duration, "runner_us": after_runner - start, "events_us": duration - (after_runner - start)})
		elapsed_us += duration
		maximum_us = maxi(maximum_us, duration)
	samples.sort()
	return {"ticks": minutes, "init_us": initialization_us, "average_us": float(elapsed_us) / float(minutes), "p50_us": samples[int((minutes - 1) * 0.50)], "p95_us": samples[int((minutes - 1) * 0.95)], "p99_us": samples[int((minutes - 1) * 0.99)], "p999_us": samples[int((minutes - 1) * 0.999)], "max_us": maximum_us, "spikes_over_10ms": spikes, "hash": runner.world.state_hash(), "actions": population.actions}
