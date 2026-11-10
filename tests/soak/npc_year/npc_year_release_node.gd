extends Node
## LW-084c: ponto de entrada do soak longo (300 NPCs [HIP]) como CENA PRINCIPAL do build de RELEASE. O binário de release ignora `-s`, então tests/soak/run_npc_year_release roda esta
## cena (npc_year_release_main.tscn) como cena principal de uma CÓPIA do projeto. Argumentos depois de `--`: `--days N` (30), `--pattern base|stress` (base) e `--control` (o laço de
## controle do SP1, aplicado aqui como PROPOSTA DE TRABALHO: a DEC-113 foi aprovada só para a LW-023). Sai com 0 se não houve problema e com 1 se houve.

const DEFAULT_DAYS: int = 30
const USEC_PER_MINUTE: float = 60000000.0
## Quantos minutos depois de uma troca de foco ainda contam como "logo depois da troca", e quantos dos passos mais lentos se mostram.
const NEAR_CHANGE_MIN: int = 5
const SLOWEST_SHOWN: int = 5


func _ready() -> void:
	get_tree().quit(_run(OS.get_cmdline_user_args()))


func _arg(args: PackedStringArray, flag: String, fallback: String) -> String:
	var at: int = args.find(flag)
	return args[at + 1] if at >= 0 and at + 1 < args.size() else fallback


func _run(args: PackedStringArray) -> int:
	var config: NpcYearMeter.Config = NpcYearMeter.Config.new()
	var days_text: String = _arg(args, "--days", str(DEFAULT_DAYS))
	config.days = int(days_text) if days_text.is_valid_int() else DEFAULT_DAYS
	config.leg_minutes = NpcYearMeter.PATTERN_STRESS_MIN if _arg(args, "--pattern", "base") == "stress" else NpcYearMeter.PATTERN_BASE_MIN
	config.progress = true
	print("Motor: Godot %s | build de depuração: %s" % [Engine.get_version_info()["string"], "sim" if OS.is_debug_build() else "não"])
	var report: NpcYearMeter.Report = NpcYearMeter.run(NpcLifeCheck.load_game_data(), config)
	print(report.summary())
	for problem: String in report.problems:
		print("PROBLEMA: %s" % problem)
	_peaks(report, config.leg_minutes)
	if args.has("--control"):
		_control(report)
	return 0 if report.problems.is_empty() else 1


## Onde estão os passos acima do limite de pico: logo depois de uma troca de foco (o ator "teletransporta" entre os pontos, o que o jogo real não faz) ou espalhados pelo dia.
func _peaks(report: NpcYearMeter.Report, leg_minutes: int) -> void:
	var peaks: Array[Vector2i] = []
	var near_change: int = 0
	for step: int in report.step_usec.size():
		if report.step_usec[step] > NpcYearMeter.STEP_PEAK_USEC:
			peaks.append(Vector2i(report.step_usec[step], step))
			near_change += 1 if step % leg_minutes < NEAR_CHANGE_MIN else 0
	peaks.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.x > b.x)
	var slowest: Array[String] = []
	for peak: Vector2i in peaks.slice(0, SLOWEST_SHOWN):
		slowest.append("passo %d (%d min depois da troca): %d us" % [peak.y, peak.y % leg_minutes, peak.x])
	print("passos acima de %d us: %d, dos quais %d nos %d min depois de uma troca de foco (a cada %d min) | mais lentos: %s" % [NpcYearMeter.STEP_PEAK_USEC, peaks.size(), near_change, NEAR_CHANGE_MIN, leg_minutes, "; ".join(slowest)])


## Laço de controle: o mesmo número de passos e a mesma duração média por passo, só com espera ocupada (sem o código do jogo): separa o ruído da máquina do custo do código.
func _control(report: NpcYearMeter.Report) -> void:
	var count: int = report.step_usec.size()
	var mean_usec: int = maxi(1, roundi(report.mean_step_usec()))
	var over_budget: int = 0
	var over_peak: int = 0
	for _step: int in count:
		var started: int = Time.get_ticks_usec()
		var deadline: int = started + mean_usec
		while Time.get_ticks_usec() < deadline:
			pass
		var spent: int = Time.get_ticks_usec() - started
		over_budget += 1 if spent > NpcYearMeter.STEP_BUDGET_USEC else 0
		over_peak += 1 if spent > NpcYearMeter.STEP_PEAK_USEC else 0
	var minutes: float = maxf(report.mean_step_usec() * float(count) / USEC_PER_MINUTE, 0.001)
	var sim_peak: int = report.steps_over(NpcYearMeter.STEP_PEAK_USEC)
	print("controle (espera ocupada de %d us por passo): acima de %d us: %d | acima de %d us: %d" % [mean_usec, NpcYearMeter.STEP_BUDGET_USEC, over_budget, NpcYearMeter.STEP_PEAK_USEC, over_peak])
	print("passos acima de %d us por minuto de execução contínua: simulação %.2f | controle %.2f" % [NpcYearMeter.STEP_PEAK_USEC, float(sim_peak) / minutes, float(over_peak) / minutes])
	print("conclusão do controle: %s" % _verdict(sim_peak, over_peak))


func _verdict(sim_over: int, control_over: int) -> String:
	if sim_over == 0:
		return "nenhum passo da simulação acima do limite nesta execução (controle: %d)." % control_over
	if control_over == 0:
		return "SÓ NA SIMULAÇÃO: o controle não teve nenhum passo acima do limite; investigar o código (repita antes de concluir)."
	return "o controle também teve passos acima do limite (%d contra %d da simulação): ruído da máquina ou do build; compare as taxas e repita." % [control_over, sim_over]
