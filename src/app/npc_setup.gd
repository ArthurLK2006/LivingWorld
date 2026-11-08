class_name NpcSetup
extends RefCounted
## LW-067: monta, a partir dos arquivos de `data/`, TUDO o que o `NpcModule` recebe pelo construtor (necessidades, traços, catálogo de
## ações, ofícios e rotina, parâmetros, FoodStub, IncomeStub e população), junto com o serviço de locais do `world`. Sem global e sem
## autoload: o `GameApp` chama `from_dir` uma vez, ao iniciar o jogo, e entrega o resultado ao `GameModules.register`. Qualquer arquivo
## ausente ou inválido vira UMA falha tratada (`result`) com o nome do assunto e a mensagem do carregador (arquivo, item e campo); quem
## chama decide o que fazer (o `GameApp` registra o erro e o jogo segue sem NPCs). Nunca lança erro nem escreve no log por conta própria.

const CODE_INVALID: String = "NPC_SETUP_INVALID"
const DEFAULT_DIR: String = "res://data"

## Só vale se `result.ok`.
var result: Result = Result.success()
var need_defs: Array[NeedDef] = []
var routine: RoutineTable
var definitions: NpcModule.Definitions


## Lê os arquivos de `data_dir` e monta o conjunto. `places`: o serviço de locais do `world` já montado (conteúdo, fora do save).
## `is_development_build`: vem da fronteira do app (`OS.is_debug_build()`); a simulação nunca lê `OS`.
static func from_dir(data_dir: String, places: SettlementService, is_development_build: bool = false) -> NpcSetup:
	var setup: NpcSetup = NpcSetup.new()
	if places == null:
		return setup._fail("o serviço de locais do `world` não foi entregue (esperado um SettlementService)")
	var needs: NeedLoader.LoadResult = NeedLoader.load_dir(data_dir)
	if not needs.result.ok:
		return setup._fail_with("necessidades", needs.result)
	var traits: TraitLoader.LoadResult = TraitLoader.load_dir(data_dir)
	if not traits.result.ok:
		return setup._fail_with("traços", traits.result)
	var catalog: ActionCatalogLoader.LoadResult = ActionCatalogLoader.load_dir(data_dir)
	if not catalog.result.ok:
		return setup._fail_with("catálogo de ações", catalog.result)
	var routine_table: RoutineLoader.LoadResult = RoutineLoader.load_dir(data_dir)
	if not routine_table.result.ok:
		return setup._fail_with("ofícios e rotina", routine_table.result)
	var params: NpcParamsLoader.LoadResult = NpcParamsLoader.load_dir(data_dir)
	if not params.result.ok:
		return setup._fail_with("parâmetros", params.result)
	var food: FoodStubLoader.LoadResult = FoodStubLoader.load_dir(data_dir)
	if not food.result.ok:
		return setup._fail_with("FoodStub (TEMP-LW-065)", food.result)
	var income: IncomeStubLoader.LoadResult = IncomeStubLoader.load_dir(data_dir)
	if not income.result.ok:
		return setup._fail_with("IncomeStub (TEMP-LW-066)", income.result)
	var population: PopulationLoader.LoadResult = PopulationLoader.load_dir(data_dir)
	if not population.result.ok:
		return setup._fail_with("população inicial", population.result)
	var lod: LodParamsLoader.LoadResult = LodParamsLoader.load_dir(data_dir)
	if not lod.result.ok:
		return setup._fail_with("LOD lógico (LW-069)", lod.result)
	var intents: NpcIntentParams.LoadResult = NpcIntentParams.load_dir(data_dir)
	if not intents.result.ok:
		return setup._fail_with("Intents do modo S0 (LW-070)", intents.result)
	setup.need_defs = needs.needs
	setup.routine = routine_table.table
	var assembled: NpcModule.Definitions = NpcModule.Definitions.new()
	assembled.actions = catalog.actions
	assembled.traits = traits.traits
	assembled.params = params.params
	assembled.places = places
	assembled.food = food.stub
	assembled.income = income.stub
	assembled.population = population.plan
	assembled.lod_params = lod.params
	assembled.intent_params = intents.params
	assembled.is_development_build = is_development_build
	setup.definitions = assembled
	return setup


func _fail_with(subject: String, failure: Result) -> NpcSetup:
	return _fail("%s não carregado(a): %s" % [subject, failure.message])


func _fail(detail: String) -> NpcSetup:
	result = Result.failure(CODE_INVALID, "NpcSetup.from_dir: %s." % detail)
	return self
