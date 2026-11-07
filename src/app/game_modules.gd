class_name GameModules
extends RefCounted
## Módulos do mundo do JOGO (LW-048): a lista de quem entra no `SimulationRunner` fica só aqui. O `SimulationHost` a usa ao
## iniciar um jogo novo e os testes de integração a usam para montar o MESMO mundo (por isso é uma função única, pequena).
## Hoje o personagem (módulo registrado no `World`) e o serviço de interação com pontos de interesse (LW-049; conteúdo, sem estado
## salvo, por isso NÃO é registrado no `World` e não muda o save); cada módulo novo do jogo é criado aqui e em mais nenhum lugar. O que vem de `data/` (o terreno)
## entra pelo construtor do módulo, sem global nem autoload. Contrato: docs/modules/app.md.

## Nome do módulo no mundo (é a chave dele no save).
const CHARACTER_NAME: String = "character"

var result: Result = Result.success()
## Os dois só valem se `result.ok`.
var character: CharacterModule
var interaction: InteractionService


## Registra no `runner` (ainda não iniciado) os módulos do jogo, com o terreno e os pontos de interesse já carregados (`points` pode
## ser vazio: toda interação então dá "ponto desconhecido"). Terreno nulo ou runner já iniciado: falha tratada em `result`, sem módulo
## nenhum registrado.
static func register(runner: SimulationRunner, terrain: TerrainData, points: Array[PointOfInterest] = []) -> GameModules:
	var modules: GameModules = GameModules.new()
	if terrain == null:
		modules.result = Result.failure("GAME_MODULES_NO_TERRAIN", "GameModules.register: terreno nulo; esperado um TerrainData carregado para o módulo '%s'." % CHARACTER_NAME)
		return modules
	var character_module: CharacterModule = CharacterModule.new(terrain)
	var registered: Result = runner.register_module(CHARACTER_NAME, character_module)
	if not registered.ok:
		modules.result = registered
		return modules
	modules.character = character_module
	modules.interaction = InteractionService.new(points, runner.world.context)
	return modules
