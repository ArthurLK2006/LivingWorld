class_name SimulationHostNode
extends Node
## Script do autoload `SimulationHost` (arquitetura 4.3): dono do mundo atual. Só repassa o
## tempo de cada quadro ao SimulationRunner, que tem a lógica. O nome da classe difere do
## nome do autoload porque os dois não podem coincidir. Não conhece UI nem cenas.

const MS_PER_SECOND: float = 1000.0

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


func _process(delta: float) -> void:
	advance(delta)


func _exit_tree() -> void:
	if runner != null:
		runner.finish()
		runner = null
