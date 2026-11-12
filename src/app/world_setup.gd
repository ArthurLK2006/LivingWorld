class_name WorldSetup
extends RefCounted
## LW-097c: monta, a partir de `data/world/routes.json` e dos assentamentos já lidos, o que o `WorldModule` recebe pelo construtor (o grafo de
## rotas e o sinal de build de desenvolvimento), no mesmo padrão do EconomySetup: sem global nem autoload, e arquivo ausente ou inválido vira UMA
## falha tratada (`result`, `WORLD_SETUP_INVALID`) com a mensagem do carregador (arquivo, item e campo). Nunca lança erro nem derruba o jogo.
## LW-118d: lê também as províncias, a adjacência e as culturas (`provinces.json`, `province_adjacency.json`, `cultures.json`) e confere os povoados contra elas (SettlementProvinceCheck).

const CODE_INVALID: String = "WORLD_SETUP_INVALID"

## Os dois só valem se `result.ok`.
var result: Result = Result.success()
var routes: RouteService
var provinces: ProvinceService
var cultures: CultureService
var is_development_build: bool = false


## `is_development_build`: vem da fronteira do app (`OS.is_debug_build()`); a simulação nunca lê `OS`.
static func from_dir(data_dir: String, settlements: Array[Settlement], is_development_build_flag: bool = false) -> WorldSetup:
	var setup: WorldSetup = WorldSetup.new()
	var loaded: RouteLoader.LoadResult = RouteLoader.load_dir(data_dir, settlements)
	if not loaded.result.ok:
		setup.result = Result.failure(CODE_INVALID, "WorldSetup.from_dir: rotas inválidas: %s" % loaded.result.message)
		return setup
	var loaded_provinces: ProvinceLoader.LoadResult = ProvinceLoader.load_dir(data_dir)
	if not loaded_provinces.result.ok:
		setup.result = Result.failure(CODE_INVALID, "WorldSetup.from_dir: províncias inválidas: %s" % loaded_provinces.result.message)
		return setup
	var loaded_cultures: CultureLoader.LoadResult = CultureLoader.load_dir(data_dir)
	if not loaded_cultures.result.ok:
		setup.result = Result.failure(CODE_INVALID, "WorldSetup.from_dir: culturas inválidas: %s" % loaded_cultures.result.message)
		return setup
	var checked: Result = SettlementProvinceCheck.check(data_dir, loaded_provinces.provinces, settlements, loaded_cultures.cultures)
	if not checked.ok:
		setup.result = Result.failure(CODE_INVALID, "WorldSetup.from_dir: povoados e províncias não batem: %s" % checked.message)
		return setup
	setup.routes = RouteService.new(loaded.routes, settlements)
	setup.provinces = ProvinceService.new(loaded_provinces.provinces, loaded_provinces.links, settlements)
	setup.cultures = CultureService.new(loaded_cultures.cultures, settlements)
	setup.is_development_build = is_development_build_flag
	return setup
