class_name Sp1Benchmark
extends RefCounted
## SPIKE SP1 (LW-023) — mede o núcleo da simulação com NPCs de mentira, sem janela.
## Uso (via tests/soak/run_sp1): --days N, --npcs N, --seed S, --top N (lista os N passos mais
## lentos) e --control (executa depois um laço de CONTROLE sem o código do jogo).
## Cada passo (relógio + agendador + módulo + entrega de eventos) é cronometrado com o relógio
## do sistema APENAS para medir; nada disso entra no estado nem no hash. Descartável.
##
## Controle: o mesmo número de passos, cada um com a duração média medida na simulação, mas
## feito só de espera ocupada (sem simulação). Se a máquina ou o build de depuração causam os
## engasgos, o controle tem uma taxa parecida; se só a simulação os tem, a causa é o código.
## Limite do controle: espera ocupada não usa memória nem cache; engasgos causados por
## alocação de memória não apareceriam nele.

const DEFAULT_DAYS: int = 360
const DEFAULT_NPCS: int = 1000
const DEFAULT_SEED: int = 1
const SIM_BUDGET_USEC: int = 3000
const PEAK_LIMIT_USEC: int = 10000
const PROGRESS_EVERY_DAYS: int = 60
const DEFAULT_TOP_SLOW: int = 8
const MAX_TOP_SLOW: int = 500
## Hipóteses de trabalho para o veredito do controle: taxa do controle >= 50% da da simulação
## = parecida; controle sem nenhum engasgo = só na simulação.
const SIMILAR_RATE_FRACTION: float = 0.5
const USEC_PER_SECOND: float = 1000000.0
const SECONDS_PER_MINUTE: float = 60.0


## Devolve o código de saída do processo (0 = medição concluída).
func run(args: PackedStringArray) -> int:
	var days: int = DEFAULT_DAYS
	var npcs: int = DEFAULT_NPCS
	var world_seed: int = DEFAULT_SEED
	var top_slow: int = DEFAULT_TOP_SLOW
	var with_control: bool = false
	var index: int = 0
	while index < args.size():
		if args[index] == "--control":
			with_control = true
			index += 1
			continue
		if index + 1 >= args.size():
			break
		var value: int = args[index + 1].to_int()
		match args[index]:
			"--days":
				days = value
			"--npcs":
				npcs = value
			"--seed":
				world_seed = value
			"--top":
				top_slow = clampi(value, 1, MAX_TOP_SLOW)
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
			print("  ... dia %d de %d" % [IntMath.floor_div(step + 1, SimClock.MINUTES_PER_DAY), days])
	var wall_usec: int = Time.get_ticks_usec() - wall_start
	var memory_after: int = int(Performance.get_monitor(Performance.MEMORY_STATIC))
	_report(runner, population, durations, wall_usec, memory_before, memory_after, days, npcs, world_seed, top_slow)
	if with_control:
		_run_control(durations, wall_usec, top_slow)
	runner.finish()
	return 0


## Os `top_slow` passos mais lentos, para saber se os picos se repetem nos mesmos passos
## (causa no código) ou mudam de lugar a cada execução (ruído do ambiente). Usa o vetor já
## ordenado para achar o limiar e varre os passos uma única vez.
func _slowest(durations: PackedInt32Array, sorted: PackedInt32Array, top_slow: int) -> Array[String]:
	var count: int = mini(top_slow, durations.size())
	var threshold: int = sorted[durations.size() - count]
	var slow_steps: Array[Vector2i] = []
	for step: int in durations.size():
		if durations[step] >= threshold:
			slow_steps.append(Vector2i(step, durations[step]))
	slow_steps.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.y > b.y or (a.y == b.y and a.x < b.x))
	var found: Array[String] = []
	for entry: Vector2i in slow_steps.slice(0, count):
		found.append("%d:%d" % [entry.x, entry.y])
	return found


func _count_over(durations: PackedInt32Array, limit_usec: int) -> int:
	var total: int = 0
	for value: int in durations:
		if value > limit_usec:
			total += 1
	return total


func _report(runner: SimulationRunner, population: FakeNpcPopulation, durations: PackedInt32Array, wall_usec: int, memory_before: int, memory_after: int, days: int, npcs: int, world_seed: int, top_slow: int) -> void:
	var sorted: PackedInt32Array = durations.duplicate()
	sorted.sort()
	var total: int = 0
	for value: int in durations:
		total += value
	var count: int = durations.size()
	print("SP1 — dias: %d, NPCs: %d, semente: %d, passos: %d" % [days, npcs, world_seed, count])
	print("Motor: %s | build de depuração: %s" % [Engine.get_version_info()["string"], "sim" if OS.is_debug_build() else "não"])
	print("Tempo por passo (us): média %.1f | p50 %d | p99 %d | p99,9 %d | máximo %d" % [float(total) / count, sorted[count >> 1], sorted[int(count * 0.99)], sorted[int(count * 0.999)], sorted[count - 1]])
	print("Passos acima de %d us: %d | acima de %d us: %d" % [SIM_BUDGET_USEC, _count_over(durations, SIM_BUDGET_USEC), PEAK_LIMIT_USEC, _count_over(durations, PEAK_LIMIT_USEC)])
	var slowest: Array[String] = _slowest(durations, sorted, top_slow)
	print("Passos mais lentos (índice:us): %s" % str(slowest))
	var minutes_of_day: Array[int] = []
	for entry: String in slowest:
		minutes_of_day.append(entry.get_slice(":", 0).to_int() % SimClock.MINUTES_PER_DAY)
	print("Minuto do dia desses passos: %s" % str(minutes_of_day))
	print("Tempo total: %.2f s | pensamentos de NPC: %d | eventos de fome: %d" % [wall_usec / USEC_PER_SECOND, population.thoughts_total, population.starving_events_seen])
	print("Memória estática (bytes): antes %d, depois %d" % [memory_before, memory_after])
	var hash_started: int = Time.get_ticks_usec()
	var state_hash: String = runner.world.state_hash()
	print("state_hash: %s (calculado em %.1f ms)" % [state_hash, (Time.get_ticks_usec() - hash_started) / 1000.0])
	print("Validação: %d problemas" % runner.world.validate().size())


## Laço de controle: mesmos passos e mesma duração média por passo, sem o código do jogo.
func _run_control(sim_durations: PackedInt32Array, sim_wall_usec: int, top_slow: int) -> void:
	var count: int = sim_durations.size()
	var sim_total: int = 0
	for value: int in sim_durations:
		sim_total += value
	var mean_usec: int = maxi(1, roundi(float(sim_total) / count))
	var control: PackedInt32Array = PackedInt32Array()
	control.resize(count)
	var wall_start: int = Time.get_ticks_usec()
	for step: int in count:
		var started: int = Time.get_ticks_usec()
		var deadline: int = started + mean_usec
		while Time.get_ticks_usec() < deadline:
			pass
		control[step] = Time.get_ticks_usec() - started
	var control_wall: int = Time.get_ticks_usec() - wall_start
	var control_sorted: PackedInt32Array = control.duplicate()
	control_sorted.sort()
	var sim_over: int = _count_over(sim_durations, PEAK_LIMIT_USEC)
	var control_over: int = _count_over(control, PEAK_LIMIT_USEC)
	print("--- CONTROLE (espera ocupada de %d us por passo, sem simulação) ---" % mean_usec)
	print("Controle — tempo por passo (us): máximo %d | p99,9 %d" % [control_sorted[count - 1], control_sorted[int(count * 0.999)]])
	print("Controle — passos acima de %d us: %d | acima de %d us: %d" % [SIM_BUDGET_USEC, _count_over(control, SIM_BUDGET_USEC), PEAK_LIMIT_USEC, control_over])
	print("Controle — passos mais lentos (índice:us): %s" % str(_slowest(control, control_sorted, top_slow)))
	var sim_per_minute: float = sim_over / (sim_wall_usec / USEC_PER_SECOND) * SECONDS_PER_MINUTE
	var control_per_minute: float = control_over / (control_wall / USEC_PER_SECOND) * SECONDS_PER_MINUTE
	print("Engasgos acima de %d us por minuto de execução contínua: simulação %.2f | controle %.2f" % [PEAK_LIMIT_USEC, sim_per_minute, control_per_minute])
	print("Conclusão do controle: %s" % _control_verdict(sim_over, control_over))


func _control_verdict(sim_over: int, control_over: int) -> String:
	if sim_over == 0 and control_over == 0:
		return "nenhum engasgo acima do limite nesta execução, nem na simulação nem no controle (repita para confirmar)."
	if sim_over == 0:
		return "engasgos só no controle: a máquina os produz; a simulação não teve nenhum nesta execução."
	if control_over == 0:
		return "SÓ NA SIMULAÇÃO: o controle não teve nenhum engasgo; investigar o código (repita 2 a 3 vezes antes de concluir)."
	if float(control_over) >= SIMILAR_RATE_FRACTION * sim_over:
		return "TAXA PARECIDA com a da simulação: os engasgos vêm da máquina ou do build, não do código do jogo (repita 2 a 3 vezes para confirmar)."
	return "INCONCLUSIVO: o controle teve menos engasgos que a simulação, mas não zero; repita 2 a 3 vezes."
