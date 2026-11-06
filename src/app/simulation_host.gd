class_name SimulationHostNode
extends Node
## Script do autoload `SimulationHost` (arquitetura 4.3): dono do mundo atual. Só repassa o
## tempo de cada quadro ao SimulationRunner, que tem a lógica. O nome da classe difere do
## nome do autoload porque os dois não podem coincidir. Não conhece UI nem cenas.

const MS_PER_SECOND: float = 1000.0
## Código das falhas tratadas dos comandos de ritmo quando ainda não há jogo iniciado.
const CODE_NO_GAME: String = "HOST_NO_GAME"

var runner: SimulationRunner


## Cria um mundo novo, encerrando o anterior se houver.
func start_new_game(world_seed: int) -> void:
	if runner != null:
		runner.finish()
	runner = SimulationRunner.new(world_seed)
	runner.start_new_game()


## Avança a simulação conforme o tempo do quadro. Devolve quantos passos rodaram.
func advance(delta_seconds: float) -> int:
	if runner == null:
		return 0
	return runner.advance_frame(roundi(delta_seconds * MS_PER_SECOND))


## Pausa ou retoma a simulação. Existe porque a ponte (`bridge`) não pode mexer no relógio
## (regra do `check_architecture`); o nome evita de propósito `set_paused`.
func request_pause(is_paused: bool) -> Result:
	if runner == null:
		return _no_game_failure("request_pause")
	runner.world.context.clock.set_paused(is_paused)
	return Result.success()


## Muda a velocidade (1 a 8x). A faixa é validada pelo SimClock, cujo Result é devolvido como está.
func request_speed(speed: int) -> Result:
	if runner == null:
		return _no_game_failure("request_speed")
	return runner.world.context.clock.set_speed(speed)


func _no_game_failure(caller: String) -> Result:
	return Result.failure(CODE_NO_GAME, "SimulationHost.%s: nenhum jogo iniciado; esperado chamar start_new_game antes." % caller)


func _process(delta: float) -> void:
	advance(delta)


func _exit_tree() -> void:
	if runner != null:
		runner.finish()
		runner = null
