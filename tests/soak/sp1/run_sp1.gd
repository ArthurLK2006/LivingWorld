extends SceneTree
## SPIKE SP1 (LW-023) — mede o núcleo da simulação com NPCs de mentira, sem janela.
## Uso: tests/soak/run_sp1 [--days N] [--npcs N] [--seed S]. Descartável.
## Cada passo (relógio + agendador + módulo + entrega de eventos) é cronometrado com o
## relógio do sistema APENAS para medir; nada disso entra no estado nem no hash.

const DEFAULT_DAYS: int = 360
const DEFAULT_NPCS: int = 1000
const DEFAULT_SEED: int = 1
const TICK_ALERT_USEC: int = 10000
const SIM_BUDGET_USEC: int = 3000
const PEAK_LIMIT_USEC: int = 10000
const PROGRESS_EVERY_DAYS: int = 60
const TOP_SLOW_COUNT: int = 8


func _initialize() -> void:
	var days: int = DEFAULT_DAYS
	var npcs: int = DEFAULT_NPCS
	var world_seed: int = DEFAULT_SEED
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var index: int = 0
	while index + 1 < args.size():
		var value: int = args[index + 1].to_int()
		match args[index]:
			"--days":
				days = value
			"--npcs":
				npcs = value
			"--seed":
				world_seed = value
		index += 2
	var runner: SimulationRunner = SimulationRunner.new(world_seed)
	var population: FakeNpcPopulation = FakeNpcPopulation.new(npcs)
	runner.register_module("npcs", population)
	runner.start_new_game()
	var total_steps: int = days * SimClock.MINUTES_PER_DAY
	var durations: PackedInt32Array = PackedInt32Array()
	durations.resize(total_steps)
	var memory_before: int = int(Performance.get_monitor(Performance.MEMORY_STATIC))
	var wall_start: int = Time.get_ticks_usec()
	for step: int in total_steps:
		var started: int = Time.get_ticks_usec()
		runner.step_once()
		durations[step] = Time.get_ticks_usec() - started
		if (step + 1) % (PROGRESS_EVERY_DAYS * SimClock.MINUTES_PER_DAY) == 0:
			print("  ... dia %d de %d" % [(step + 1) / SimClock.MINUTES_PER_DAY, days])
	var wall_usec: int = Time.get_ticks_usec() - wall_start
	var memory_after: int = int(Performance.get_monitor(Performance.MEMORY_STATIC))
	_report(runner, population, durations, wall_usec, memory_before, memory_after, days, npcs, world_seed)
	runner.finish()
	quit(0)


## Os TOP_SLOW_COUNT passos mais lentos, para saber se os picos se repetem nos mesmos passos
## (causa no código) ou mudam de lugar a cada execução (ruído do ambiente).
func _slowest(durations: PackedInt32Array) -> Array[String]:
	var found: Array[String] = []
	var taken: Dictionary = {}
	for _rank: int in TOP_SLOW_COUNT:
		var worst_index: int = -1
		for step: int in durations.size():
			if not taken.has(step) and (worst_index < 0 or durations[step] > durations[worst_index]):
				worst_index = step
		taken[worst_index] = true
		found.append("%d:%d" % [worst_index, durations[worst_index]])
	return found


func _report(runner: SimulationRunner, population: FakeNpcPopulation, durations: PackedInt32Array, wall_usec: int, memory_before: int, memory_after: int, days: int, npcs: int, world_seed: int) -> void:
	var sorted: PackedInt32Array = durations.duplicate()
	sorted.sort()
	var total: int = 0
	var over_budget: int = 0
	var over_peak: int = 0
	for value: int in durations:
		total += value
		if value > SIM_BUDGET_USEC:
			over_budget += 1
		if value > PEAK_LIMIT_USEC:
			over_peak += 1
	var count: int = durations.size()
	print("SP1 — dias: %d, NPCs: %d, semente: %d, passos: %d" % [days, npcs, world_seed, count])
	print("Motor: %s | build de depuração: %s" % [Engine.get_version_info()["string"], "sim" if OS.is_debug_build() else "não"])
	print("Tempo por passo (us): média %.1f | p50 %d | p99 %d | p99,9 %d | máximo %d" % [float(total) / count, sorted[count / 2], sorted[int(count * 0.99)], sorted[int(count * 0.999)], sorted[count - 1]])
	print("Passos acima de %d us: %d | acima de %d us: %d" % [SIM_BUDGET_USEC, over_budget, PEAK_LIMIT_USEC, over_peak])
	print("Passos mais lentos (índice:us): %s" % str(_slowest(durations)))
	print("Tempo total: %.2f s | pensamentos de NPC: %d | eventos de fome: %d" % [wall_usec / 1000000.0, population.thoughts_total, population.starving_events_seen])
	print("Memória estática (bytes): antes %d, depois %d" % [memory_before, memory_after])
	var hash_started: int = Time.get_ticks_usec()
	var state_hash: String = runner.world.state_hash()
	print("state_hash: %s (calculado em %.1f ms)" % [state_hash, (Time.get_ticks_usec() - hash_started) / 1000.0])
	print("Validação: %d problemas" % runner.world.validate().size())
