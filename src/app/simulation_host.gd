class_name SimulationHostNode
extends Node
## Script do autoload `SimulationHost` (arquitetura 4.3): dono do mundo atual. Só repassa o
## tempo de cada quadro ao SimulationRunner, que tem a lógica. O nome da classe difere do
## nome do autoload porque os dois não podem coincidir. Não conhece UI nem cenas.

const MS_PER_SECOND: float = 1000.0
## Código das falhas tratadas dos comandos de ritmo quando ainda não há jogo iniciado.
const CODE_NO_GAME: String = "HOST_NO_GAME"

var runner: SimulationRunner
## Módulo do personagem do mundo atual (LW-048); nulo quando o jogo começou sem terreno. A ponte o usa para repassar nascimento e
## relato de posição. O host só guarda a referência: o dono do dado é o módulo.
var character: CharacterModule
## Serviço de interação com pontos de interesse do mundo atual (LW-049); nulo quando o jogo começou sem terreno.
var interaction: InteractionService
## Módulo `npc` do mundo atual (LW-070a); nulo quando o jogo começou sem terreno. O `GameApp` o entrega à ponte (foco do LOD, Intents e resultados).
var npc: NpcModule


## Cria um mundo novo, encerrando o anterior se houver. Com `terrain`, registra os módulos do jogo (GameModules); sem ele o mundo
## nasce só com o núcleo (testes e ferramentas que não precisam do terreno). `points` são os pontos de interesse já lidos (LW-049).
## `npc_setup` (LW-067): os dados do `npc` já lidos; sem ele o `npc` nasce sem NPCs. Falha de registro: push_error e o mundo segue sem módulos.
## `start_minute` (LW-042b): tempo simulado em que o mundo novo começa, repassado ao `SimulationRunner`; o padrão 0 é 00:00 do dia 1.
## `world_setup` (LW-097c): as rotas já lidas e o sinal de build de desenvolvimento; sem ele o módulo `world` nasce sem rotas.
func start_new_game(world_seed: int, terrain: TerrainData = null, points: Array[PointOfInterest] = [], npc_setup: NpcSetup = null, start_minute: int = 0, world_setup: WorldSetup = null) -> void:
	if runner != null:
		runner.finish()
	character = null
	interaction = null
	npc = null
	runner = SimulationRunner.new(world_seed, start_minute)
	if terrain != null:
		var modules: GameModules = GameModules.register(runner, terrain, points, npc_setup, null, world_setup)
		if modules.result.ok:
			character = modules.character
			interaction = modules.interaction
			npc = modules.npc
		else:
			push_error("SimulationHost.start_new_game: módulos do jogo não registrados (%s): %s" % [modules.result.code, modules.result.message])
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
	character = null
	interaction = null
	npc = null
