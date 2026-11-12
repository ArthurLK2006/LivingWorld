extends GutTest
## LW-118d: as províncias, a adjacência e as culturas ligadas ao módulo `world` (docs/modules/world.md, "Extensão da Fase 4"): o `WorldSetup` lê e confere tudo no carregamento (uma falha tratada com
## arquivo, item e campo), o `WorldModule` responde `peek_province`, `peek_provinces`, `peek_province_of`, `peek_adjacent_provinces`, `peek_culture` e `peek_culture_of`, e NADA disso entra no save nem no
## `state_hash` (conteúdo). "Ida e volta de save" = carregar o save num mundo novo com os mesmos arquivos e obter as mesmas consultas. O jogo real (GameApp) nasce com a estrutura ligada.

const WORLD_DIR: String = "res://data/world"
const WORLD_SEED: int = 5
const GAME_VERSION: String = "0.0.1-test"
const TOWN_C: String = "test_settlement_c"

var _terrain: TerrainData
var _settlements: Array[Settlement] = []
var _codec: JsonSaveCodec = JsonSaveCodec.new()
var _runners: Array[SimulationRunner] = []
var _temp_dirs: Array[DirAccess] = []


func before_all() -> void:
	var terrain: TerrainLoader.LoadResult = TerrainLoader.load_dir(WORLD_DIR)
	assert_true(terrain.result.ok, terrain.result.message)
	_terrain = terrain.terrain
	var loaded: SettlementLoader.LoadResult = SettlementLoader.load_dir(WORLD_DIR, _terrain)
	assert_true(loaded.result.ok, loaded.result.message)
	_settlements = loaded.settlements


func after_each() -> void:
	for runner: SimulationRunner in _runners:
		runner.finish()
	_runners.clear()
	for dir: DirAccess in _temp_dirs:
		for file_name: String in dir.get_files():
			dir.remove(file_name)
		DirAccess.remove_absolute(dir.get_current_dir())
	_temp_dirs.clear()


## Um mundo com o `world` e a estrutura reais; `with_structure` falso registra o módulo só com as rotas (como antes da LW-118d).
func _new_game(with_structure: bool = true, world_seed: int = WORLD_SEED) -> GameModules:
	var runner: SimulationRunner = SimulationRunner.new(world_seed)
	_runners.append(runner)
	var setup: WorldSetup = WorldSetup.from_dir(WORLD_DIR, _settlements, true)
	assert_true(setup.result.ok, setup.result.message)
	var modules: GameModules
	if with_structure:
		modules = GameModules.register(runner, _terrain, [], null, null, setup)
	else:
		var bare: WorldSetup = WorldSetup.new()
		bare.routes = setup.routes
		modules = GameModules.register(runner, _terrain, [], null, null, bare)
	assert_true(modules.result.ok, modules.result.message)
	runner.start_new_game()
	return modules


## Pasta temporária com cópias do que o `WorldSetup` lê; `overrides` troca o texto de um arquivo (ou o remove, se o texto é nulo).
func _dir_with(overrides: Dictionary[String, Variant]) -> String:
	var dir: DirAccess = DirAccess.create_temp("lw118d")
	_temp_dirs.append(dir)
	for file_name: String in ["routes.json", "provinces.json", "province_adjacency.json", "cultures.json"]:
		var text: Variant = overrides.get(file_name, FileAccess.get_file_as_string(WORLD_DIR.path_join(file_name)))
		if text == null:
			continue
		var file: FileAccess = FileAccess.open(dir.get_current_dir().path_join(file_name), FileAccess.WRITE)
		file.store_string(str(text))
		file.close()
	return dir.get_current_dir()


func _assert_setup_fails(overrides: Dictionary[String, Variant], parts: Array[String], settlements: Array[Settlement] = _settlements) -> void:
	var setup: WorldSetup = WorldSetup.from_dir(_dir_with(overrides), settlements)
	assert_false(setup.result.ok, "O `WorldSetup` deveria falhar.")
	assert_eq(setup.result.code, WorldSetup.CODE_INVALID)
	for part: String in parts:
		assert_string_contains(setup.result.message, part)


func _ids(provinces: Array[Province]) -> Array[String]:
	var ids: Array[String] = []
	for province: Province in provinces:
		ids.append(province.id)
	return ids


# ---------------------------------------------------------------- as consultas pelo módulo

func test_the_world_module_answers_the_province_and_culture_queries_of_the_real_data() -> void:
	var world: WorldModule = _new_game().world
	assert_eq(_ids(world.peek_provinces().provinces), ["province_a", "province_b", "province_border", "province_c"] as Array[String])
	assert_eq(_ids(world.peek_adjacent_provinces("province_border").provinces), ["province_a", "province_b", "province_c"] as Array[String])
	assert_eq(world.peek_province("province_c").settlement_ids, [TOWN_C] as Array[String])
	assert_eq(world.peek_province_of(TOWN_C).province.id, "province_c", "O povoado C está na sua província.")
	assert_eq([world.peek_culture_of(TOWN_C).culture.id, world.peek_culture_of("test_settlement_a").culture.id], ["culture_tradition", "culture_trade"])
	assert_eq(world.peek_culture("culture_trade").culture.martial_stance, 30)
	assert_eq(world.validate(), [] as Array[String])


func test_unknown_ids_are_handled_errors_with_their_codes() -> void:
	var world: WorldModule = _new_game().world
	assert_eq(world.peek_province("nowhere").result.code, ProvinceService.CODE_PROVINCE_UNKNOWN)
	assert_eq(world.peek_adjacent_provinces("nowhere").result.code, ProvinceService.CODE_PROVINCE_UNKNOWN)
	assert_eq(world.peek_province_of("nowhere").result.code, SettlementService.CODE_SETTLEMENT_UNKNOWN)
	assert_eq(world.peek_culture("nowhere").result.code, CultureService.CODE_CULTURE_UNKNOWN)
	assert_eq(world.peek_culture_of("nowhere").result.code, SettlementService.CODE_SETTLEMENT_UNKNOWN)


func test_a_world_registered_without_the_structure_has_no_province_and_no_culture_but_works() -> void:
	var world: WorldModule = _new_game(false).world
	assert_eq(world.peek_provinces().provinces.size(), 0)
	assert_eq(world.peek_province("province_a").result.code, ProvinceService.CODE_PROVINCE_UNKNOWN)
	assert_eq(world.peek_culture("culture_trade").result.code, CultureService.CODE_CULTURE_UNKNOWN)
	assert_true(world.peek_route("route_a_b").result.ok, "As rotas seguem valendo.")
	assert_eq(world.validate(), [] as Array[String])


# ---------------------------------------------------------------- conteúdo: sem save, sem hash

func test_the_structure_does_not_enter_the_save_nor_the_state_hash() -> void:
	var with_structure: GameModules = _new_game(true)
	var without: GameModules = _new_game(false)
	var runner_with: SimulationRunner = _runners[0]
	var runner_without: SimulationRunner = _runners[1]
	assert_eq(runner_with.world.state_hash(), runner_without.world.state_hash(), "Mesmo hash com e sem a estrutura: é conteúdo.")
	var saved: Dictionary = runner_with.capture_game()
	assert_eq(saved["world"]["modules"][GameModules.WORLD_NAME], {}, "O bloco `world` continua vazio (todas as rotas abertas).")
	assert_not_null(with_structure.world)
	assert_not_null(without.world)


func test_a_saved_game_loaded_into_a_new_world_gives_the_same_queries() -> void:
	var first: GameModules = _new_game()
	var runner: SimulationRunner = _runners[0]
	assert_true(first.world.request_close_route("route_b_c").ok)
	var decoded: DecodedSave = _codec.decode(_codec.encode(runner.capture_game(), GAME_VERSION))
	var second_runner: SimulationRunner = SimulationRunner.new(WORLD_SEED)
	_runners.append(second_runner)
	var second: GameModules = GameModules.register(second_runner, _terrain, [], null, null, WorldSetup.from_dir(WORLD_DIR, _settlements, true))
	assert_true(second.result.ok, second.result.message)
	var loaded: Result = second_runner.load_game(decoded.payload)
	assert_true(loaded.ok, loaded.message)
	assert_eq(_ids(second.world.peek_provinces().provinces), _ids(first.world.peek_provinces().provinces))
	assert_eq(second.world.peek_province_of(TOWN_C).province.id, first.world.peek_province_of(TOWN_C).province.id)
	assert_eq(second.world.peek_route("route_b_c").state, WorldModule.STATE_CLOSED, "O estado de rota continua sendo salvo.")


# ---------------------------------------------------------------- o carregamento confere tudo

func test_the_setup_fails_with_one_handled_error_when_a_file_is_missing_or_invalid() -> void:
	_assert_setup_fails({"provinces.json": null}, ["províncias inválidas", "provinces.json", "arquivo não encontrado"])
	_assert_setup_fails({"cultures.json": null}, ["culturas inválidas", "cultures.json", "arquivo não encontrado"])
	_assert_setup_fails({"province_adjacency.json": "[]"}, ["províncias inválidas", "province_adjacency.json", "grafo não conectado"])
	_assert_setup_fails({"cultures.json": "[]"}, ["culturas inválidas", "cultures.json", "nenhuma cultura"])


func test_the_setup_fails_when_a_settlement_does_not_match_the_provinces_or_the_cultures() -> void:
	var lost: Array[Settlement] = [Settlement.new("test_settlement_a", "k.a", Vector3.ZERO, "province_a", "culture_trade"), Settlement.new("test_settlement_b", "k.b", Vector3.ZERO, "province_b", "culture_trade"), Settlement.new(TOWN_C, "k.c", Vector3.ZERO, "province_nowhere", "culture_nowhere")]
	_assert_setup_fails({}, ["povoados e províncias não batem", "settlements.json", TOWN_C, "province_id", "culture_id", "referência a id inexistente"], lost)
