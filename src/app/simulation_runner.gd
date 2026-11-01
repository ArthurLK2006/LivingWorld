class_name SimulationRunner
extends RefCounted
## Lógica do SimulationHost (arquitetura 4.5 e 6.5), sem Node: cria o mundo e o avança.
## O autoload `SimulationHost` (tarefa futura) será só um invólucro fino sobre esta classe, e
## `tools/run_sim` a usa direto, sem janela. O nome difere do autoload para não colidir com ele.
## Ordem de cada passo: avançar o relógio, agendador roda os módulos, barramento entrega eventos.

## [HIP] Teto de passos por quadro: se a simulação não acompanha, a velocidade do mundo cai
## em vez de congelar o jogo (arquitetura 6.4).
const MAX_TICKS_PER_FRAME: int = 60

var world: World
var scheduler: Scheduler
var _world_seed: int
var _is_started: bool = false


func _init(world_seed: int) -> void:
	_world_seed = world_seed
	var clock: SimClock = SimClock.new()
	var context: SimContext = SimContext.new(clock, EventBus.new(clock), WorldRng.new(world_seed), IdGenerator.new())
	world = World.new(context)


## Registra um módulo; só antes de `start_new_game`.
func register_module(module_name: String, module: SimModule) -> Result:
	return world.register_module(module_name, module)


## Prepara um mundo novo: ciclo de vida dos módulos e agendador. `configure_scheduler` (opcional)
## recebe o `Scheduler` recém-criado para definir frequências e custos.
func start_new_game(configure_scheduler: Callable = Callable()) -> void:
	if _is_started:
		push_error("SimulationRunner.start_new_game: já iniciado.")
		return
	_is_started = true
	world.setup()
	world.post_setup()
	world.on_new_game(_world_seed)
	scheduler = Scheduler.new(world)
	if configure_scheduler.is_valid():
		configure_scheduler.call(scheduler)


## Estado completo para salvar: mundo (núcleo e módulos) e agendador. Chamar só entre passos,
## com a fila de eventos vazia (arquitetura 18.4); use `can_capture_game()` para conferir.
func capture_game() -> Dictionary:
	return {"world": world.serialize(), "scheduler": scheduler.serialize()}


func can_capture_game() -> bool:
	return _is_started and world.context.events.validate().is_empty()


## Carrega um save neste runner NOVO (ainda não iniciado), com os mesmos módulos registrados.
## Faz o ciclo de vida sem `on_new_game`, restaura o estado e valida. Em caso de falha este
## runner deve ser descartado (AGENTS 12.6: o mundo antigo só sai depois do novo carregar).
## `configure_scheduler` deve ser o mesmo usado ao criar o jogo: a configuração vem do código.
func load_game(payload: Dictionary, configure_scheduler: Callable = Callable()) -> Result:
	if _is_started:
		return Result.failure("RUNNER_ALREADY_STARTED", "SimulationRunner.load_game: use um runner novo.")
	var world_variant: Variant = payload.get("world")
	var scheduler_variant: Variant = payload.get("scheduler")
	if typeof(world_variant) != TYPE_DICTIONARY or typeof(scheduler_variant) != TYPE_DICTIONARY:
		return Result.failure("LOAD_INVALID_PAYLOAD", "SimulationRunner.load_game: faltam 'world' e 'scheduler' no save.")
	_is_started = true
	world.setup()
	world.post_setup()
	scheduler = Scheduler.new(world)
	if configure_scheduler.is_valid():
		configure_scheduler.call(scheduler)
	var world_result: Result = world.on_load(world_variant)
	if not world_result.ok:
		return world_result
	var scheduler_result: Result = scheduler.on_load(scheduler_variant)
	if not scheduler_result.ok:
		return scheduler_result
	_world_seed = world.context.rng.world_seed
	var problems: Array[String] = world.validate() + scheduler.validate()
	if not problems.is_empty():
		return Result.failure("LOAD_INVALID_STATE", "Estado carregado inválido: %s" % "; ".join(problems))
	return Result.success()


## Um passo de 1 minuto simulado.
func step_once() -> void:
	world.context.clock.advance_step()
	scheduler.step()
	world.context.events.dispatch()


func run_steps(step_count: int) -> void:
	for _i: int in step_count:
		step_once()


func run_days(day_count: int) -> void:
	run_steps(day_count * SimClock.MINUTES_PER_DAY)


## Avança conforme o tempo real do quadro (pausa e velocidade valem). Passos acima do teto
## são descartados. Devolve quantos passos rodaram.
func advance_frame(frame_delta_ms: int) -> int:
	var steps: int = mini(world.context.clock.steps_for_frame(frame_delta_ms), MAX_TICKS_PER_FRAME)
	run_steps(steps)
	return steps


## Data simulada em texto curto, ex.: "ano 1, dia 3, 14:05".
func format_clock_line() -> String:
	var clock: SimClock = world.context.clock
	return "ano %d, dia %d, %02d:%02d" % [clock.year(), clock.day_of_year(), clock.hour_of_day(), clock.minute_of_hour()]


## Texto para a linha de comando: data simulada, módulos e problemas de validação.
func describe_state() -> String:
	var clock: SimClock = world.context.clock
	var problems: Array[String] = world.validate()
	var lines: PackedStringArray = PackedStringArray()
	lines.append("Data simulada: %s (%d minutos simulados)" % [format_clock_line(), clock.total_minutes()])
	lines.append("Semente: %d" % _world_seed)
	lines.append("Hash do estado: %s" % world.state_hash())
	var module_names: Array[String] = world.module_names()
	lines.append("Módulos: %d" % module_names.size())
	for module_name: String in module_names:
		lines.append("  %s: %s" % [module_name, str(world.debug_summary()["modules"][module_name])])
	lines.append("Problemas de validação: %d" % problems.size())
	for problem: String in problems:
		lines.append("  " + problem)
	return "\n".join(lines)


func finish() -> void:
	world.teardown()
