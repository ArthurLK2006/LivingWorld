class_name Scheduler
extends RefCounted
## Agendador de módulos (arquitetura 6.4, 6.5 e 20.4). Duas funções:
## 1. Frequência: cada módulo roda a cada N minutos simulados (com deslocamento opcional, para
##    escalonar), recebendo os minutos decorridos desde sua última execução.
## 2. Orçamento por passo, em UNIDADES DE TRABALHO declaradas por módulo (não em milissegundos):
##    o módulo que não cabe é adiado para o passo seguinte, sem perder minutos, e passa à frente
##    na fila (ordem: quem venceu há mais tempo, depois a ordem de registro), então ninguém passa
##    fome. Cortar por tempo real tornaria o mundo dependente da velocidade da máquina (DEC-081).
## A medição em microssegundos só observa e alerta; nunca altera o que roda nem entra no save.

const UNLIMITED_BUDGET: int = 0
const DEFAULT_EVERY_MINUTES: int = 1
const DEFAULT_COST_UNITS: int = 1
const KEY_MODULES: String = "modules"
const KEY_LAST_RUN: String = "last_run"
const KEY_NEXT_DUE: String = "next_due"

var _world: World
var _budget_units: int
var _usec_source: Callable
var _time_alert_usec: int = 0
var _order: Array[String] = []
var _config: Dictionary[String, Dictionary] = {}
var _state: Dictionary[String, Dictionary] = {}
var _stats: Dictionary[String, Dictionary] = {}
var _last_ran: int = 0
var _last_deferred: int = 0
var _deferred_total: int = 0


## `budget_units`: unidades por passo (UNLIMITED_BUDGET = sem limite). `usec_source` devolve
## microssegundos (padrão: relógio do sistema, só para medir); testes injetam um falso.
func _init(world: World, budget_units: int = UNLIMITED_BUDGET, usec_source: Callable = Callable()) -> void:
	_world = world
	_budget_units = budget_units
	_usec_source = usec_source if usec_source.is_valid() else Time.get_ticks_usec
	var now: int = world.context.clock.total_minutes()
	for module_name: String in world.module_names():
		_order.append(module_name)
		_config[module_name] = {"every": DEFAULT_EVERY_MINUTES, "cost": DEFAULT_COST_UNITS, "offset": 0}
		_state[module_name] = {KEY_LAST_RUN: now, KEY_NEXT_DUE: _next_instant_after(now, DEFAULT_EVERY_MINUTES, 0)}
		_stats[module_name] = {"runs": 0, "total_usec": 0, "max_usec": 0, "over_limit": 0}


## Define frequência (a cada `every_minutes`), custo em unidades e deslocamento (0 a every-1).
## Reinicia a contagem do módulo a partir do minuto atual.
func configure_module(module_name: String, every_minutes: int, cost_units: int = DEFAULT_COST_UNITS, offset_minutes: int = 0) -> Result:
	if not _config.has(module_name):
		return Result.failure("SCHEDULER_UNKNOWN_MODULE", "Scheduler.configure_module: módulo '%s' não registrado no World." % module_name)
	if every_minutes < 1 or cost_units < 0 or offset_minutes < 0 or offset_minutes >= every_minutes:
		return Result.failure("SCHEDULER_INVALID_CONFIG", "Scheduler.configure_module('%s'): every=%d (>=1), cost=%d (>=0), offset=%d (0 a every-1)." % [module_name, every_minutes, cost_units, offset_minutes])
	var now: int = _world.context.clock.total_minutes()
	_config[module_name] = {"every": every_minutes, "cost": cost_units, "offset": offset_minutes}
	_state[module_name] = {KEY_LAST_RUN: now, KEY_NEXT_DUE: _next_instant_after(now, every_minutes, offset_minutes)}
	return Result.success()


## Alerta de desempenho: conta toda execução de módulo acima deste tempo (0 = desligado).
func set_time_alert_usec(limit_usec: int) -> void:
	_time_alert_usec = limit_usec


## Chamar uma vez por passo, depois de avançar o relógio. Devolve quantos módulos rodaram.
func step() -> int:
	var now: int = _world.context.clock.total_minutes()
	var due: Array[String] = []
	for module_name: String in _order:
		if _state[module_name][KEY_NEXT_DUE] <= now:
			due.append(module_name)
	# Quem venceu há mais tempo vai primeiro; o desempate é a ordem de registro (sort estável por índice).
	var order_index: Dictionary[String, int] = {}
	for index: int in _order.size():
		order_index[_order[index]] = index
	due.sort_custom(func(a: String, b: String) -> bool:
		var due_a: int = _state[a][KEY_NEXT_DUE]
		var due_b: int = _state[b][KEY_NEXT_DUE]
		if due_a != due_b:
			return due_a < due_b
		return order_index[a] < order_index[b])
	var budget_left: int = _budget_units
	var ran: int = 0
	var deferred: int = 0
	for module_name: String in due:
		var cost: int = _config[module_name]["cost"]
		# O primeiro da fila sempre roda, mesmo que sozinho passe do orçamento: garante progresso.
		if _budget_units != UNLIMITED_BUDGET and ran > 0 and cost > budget_left:
			deferred += 1
			continue
		_run_module(module_name, now)
		budget_left -= cost
		ran += 1
	_last_ran = ran
	_last_deferred = deferred
	_deferred_total += deferred
	return ran


## Só o controle de frequência vai para o save; configuração vem do código e medição não é estado.
func serialize() -> Dictionary:
	var modules_data: Dictionary = {}
	for module_name: String in _order:
		modules_data[module_name] = {KEY_LAST_RUN: _state[module_name][KEY_LAST_RUN], KEY_NEXT_DUE: _state[module_name][KEY_NEXT_DUE]}
	return {KEY_MODULES: modules_data}


## Restaura o controle de frequência. Só altera o estado se todo o dado for válido.
func on_load(data: Dictionary) -> Result:
	var modules_variant: Variant = data.get(KEY_MODULES)
	if typeof(modules_variant) != TYPE_DICTIONARY:
		return Result.failure("SCHEDULER_INVALID_SAVE", "Scheduler.on_load: '%s' deve ser um objeto." % KEY_MODULES)
	var modules_data: Dictionary = modules_variant
	var restored: Dictionary[String, Dictionary] = {}
	for module_name: String in _order:
		var entry: Variant = modules_data.get(module_name)
		if typeof(entry) != TYPE_DICTIONARY:
			return Result.failure("SCHEDULER_INVALID_SAVE", "Scheduler.on_load: dados do módulo '%s' ausentes." % module_name)
		var entry_data: Dictionary = entry
		var last_run: Variant = _whole_number(entry_data.get(KEY_LAST_RUN))
		var next_due: Variant = _whole_number(entry_data.get(KEY_NEXT_DUE))
		if last_run == null or next_due == null or last_run < 0 or next_due <= last_run:
			return Result.failure("SCHEDULER_INVALID_SAVE", "Scheduler.on_load: '%s' e '%s' do módulo '%s' devem ser inteiros com 0 <= last_run < next_due." % [KEY_LAST_RUN, KEY_NEXT_DUE, module_name])
		restored[module_name] = {KEY_LAST_RUN: last_run, KEY_NEXT_DUE: next_due}
	if modules_data.size() != _order.size():
		return Result.failure("SCHEDULER_INVALID_SAVE", "Scheduler.on_load: o save tem módulos que o agendador não conhece.")
	_state = restored
	return Result.success()


func validate() -> Array[String]:
	var problems: Array[String] = []
	for module_name: String in _order:
		var config: Dictionary = _config[module_name]
		var state: Dictionary = _state[module_name]
		if config["every"] < 1 or config["cost"] < 0 or config["offset"] < 0 or config["offset"] >= config["every"]:
			problems.append("Scheduler: configuração inválida do módulo '%s'." % module_name)
		if state[KEY_LAST_RUN] < 0 or state[KEY_NEXT_DUE] <= state[KEY_LAST_RUN]:
			problems.append("Scheduler: controle de frequência inválido do módulo '%s'." % module_name)
	return problems


func debug_summary() -> Dictionary:
	var modules_summary: Dictionary = {}
	for module_name: String in _order:
		modules_summary[module_name] = {
			"every": _config[module_name]["every"],
			"cost": _config[module_name]["cost"],
			"offset": _config[module_name]["offset"],
			"last_run": _state[module_name][KEY_LAST_RUN],
			"next_due": _state[module_name][KEY_NEXT_DUE],
			"runs": _stats[module_name]["runs"],
			"total_usec": _stats[module_name]["total_usec"],
			"max_usec": _stats[module_name]["max_usec"],
			"over_limit": _stats[module_name]["over_limit"],
		}
	return {
		"budget_units": _budget_units,
		"last_step": {"ran": _last_ran, "deferred": _last_deferred},
		"deferred_total": _deferred_total,
		"modules": modules_summary,
	}


func _run_module(module_name: String, now: int) -> void:
	var elapsed: int = now - _state[module_name][KEY_LAST_RUN]
	var started: int = _usec_source.call()
	_world.tick_module(module_name, elapsed)
	var spent: int = _usec_source.call() - started
	var stats: Dictionary = _stats[module_name]
	stats["runs"] += 1
	stats["total_usec"] += spent
	stats["max_usec"] = maxi(stats["max_usec"], spent)
	if _time_alert_usec > 0 and spent > _time_alert_usec:
		stats["over_limit"] += 1
	var config: Dictionary = _config[module_name]
	_state[module_name] = {KEY_LAST_RUN: now, KEY_NEXT_DUE: _next_instant_after(now, config["every"], config["offset"])}


## Primeiro minuto depois de `minute` que cai na grade "offset + k * every".
func _next_instant_after(minute: int, every: int, offset: int) -> int:
	var candidate: int = minute + 1
	var remainder: int = posmod(candidate - offset, every)
	if remainder != 0:
		candidate += every - remainder
	return candidate


## Inteiro vindo do JSON (que grava decimal) ou null se não for número inteiro.
func _whole_number(raw: Variant) -> Variant:
	if typeof(raw) == TYPE_INT:
		return raw
	if typeof(raw) == TYPE_FLOAT and raw == floorf(raw) and absf(raw) <= SimClock.MAX_TOTAL_MINUTES:
		return int(raw)
	return null
