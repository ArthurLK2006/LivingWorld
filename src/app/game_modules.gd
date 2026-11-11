class_name GameModules
extends RefCounted
## Módulos do mundo do JOGO (LW-048): a lista de quem entra no `SimulationRunner` fica só aqui. O `SimulationHost` a usa ao
## iniciar um jogo novo e os testes de integração a usam para montar o MESMO mundo (por isso é uma função única, pequena).
## Hoje o personagem, a `economy` (LW-088a; só a casca, sem comportamento) e o `npc` (LW-057), módulos registrados no `World` NESSA ordem (a `economy` vem antes do `npc`,
## que vai abrir as contas dela), e o serviço de interação com pontos de interesse (LW-049; conteúdo, sem estado
## salvo, por isso NÃO é registrado no `World` e não muda o save); cada módulo novo do jogo é criado aqui e em mais nenhum lugar. O que vem de `data/` (o terreno)
## entra pelo construtor do módulo, sem global nem autoload. Contrato: docs/modules/app.md.

## Nome do módulo no mundo (é a chave dele no save).
const CHARACTER_NAME: String = "character"
## Nome do módulo `economy` (LW-088a), registrado depois do `character` e antes do `npc`; também é a chave dele no save.
const ECONOMY_NAME: String = "economy"
## Nome do módulo `npc` (LW-057), registrado depois da `economy`; também é a chave dele no save.
const NPC_NAME: String = "npc"

var result: Result = Result.success()
## Os quatro só valem se `result.ok`.
var character: CharacterModule
var economy: EconomyModule
var npc: NpcModule
var interaction: InteractionService


## Registra no `runner` (ainda não iniciado) os módulos do jogo, com o terreno e os pontos de interesse já carregados (`points` pode
## ser vazio: toda interação então dá "ponto desconhecido"). `npc_setup` (LW-067): os dados do `npc` já lidos (NpcSetup); sem ele, ou com
## `result` de falha, o `npc` nasce sem definições e sem nenhum NPC (o comportamento dos testes que não precisam de população). Terreno nulo
## ou runner já iniciado: falha tratada em `result`, sem módulo nenhum registrado. `economy_setup` (LW-090c): os dados da economia já lidos (EconomySetup); sem ele a `economy` nasce sem definições (sem bens e sem mercados, como a casca), porque o NPC ainda não usa a economia e criar os mercados gastaria os primeiros IDs do `core` (a ligação do jogo é da LW-093); com um EconomySetup de falha, falha tratada em `result`.
static func register(runner: SimulationRunner, terrain: TerrainData, points: Array[PointOfInterest] = [], npc_setup: NpcSetup = null, economy_setup: EconomySetup = null) -> GameModules:
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
	var economy_module: EconomyModule = EconomyModule.new()
	if economy_setup != null:
		if not economy_setup.result.ok:
			modules.result = economy_setup.result
			return modules
		economy_module = EconomyModule.new(false, economy_setup.definitions)
	registered = runner.register_module(ECONOMY_NAME, economy_module)
	if not registered.ok:
		modules.result = registered
		return modules
	modules.economy = economy_module
	var npc_module: NpcModule = NpcModule.new()
	if npc_setup != null and npc_setup.result.ok:
		npc_module = NpcModule.new(npc_setup.need_defs, npc_setup.routine, npc_setup.definitions, economy_module)
	registered = runner.register_module(NPC_NAME, npc_module)
	if not registered.ok:
		modules.result = registered
		return modules
	modules.npc = npc_module
	modules.interaction = InteractionService.new(points, runner.world.context)
	return modules
