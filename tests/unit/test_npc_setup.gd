extends GutTest
## LW-067: a ligação dos dados reais do `npc` ao jogo (NpcSetup, GameModules.register e SimulationHost.start_new_game; docs/modules/app.md),
## sem janela. Cobre: o conjunto montado dos arquivos reais; falha tratada com o assunto e a mensagem do carregador, sem nada no log; o
## módulo `npc` do jogo nasce com 100 NPCs quando recebe o conjunto e continua sem nenhum quando não recebe (o padrão dos outros testes); o
## mundo que o autoload `GameApp` iniciou ao abrir o projeto; e um dia inteiro de jogo com os dados reais, que fecha sem problema nenhum.

const DATA_DIR: String = "res://data"
const WORLD_DIR: String = "res://data/world"
const WORLD_SEED: int = 5

var _terrain: TerrainData
var _points: Array[PointOfInterest] = []
var _settlements: Array[Settlement] = []
var _places: Array[Place] = []


func before_all() -> void:
	var terrain_loaded: TerrainLoader.LoadResult = TerrainLoader.load_dir(WORLD_DIR)
	assert_true(terrain_loaded.result.ok, terrain_loaded.result.message)
	_terrain = terrain_loaded.terrain
	var points_loaded: PointOfInterestLoader.LoadResult = PointOfInterestLoader.load_dir(WORLD_DIR, _terrain)
	assert_true(points_loaded.result.ok, points_loaded.result.message)
	_points = points_loaded.points
	var settlements_loaded: SettlementLoader.LoadResult = SettlementLoader.load_dir(WORLD_DIR, _terrain)
	assert_true(settlements_loaded.result.ok, settlements_loaded.result.message)
	_settlements = settlements_loaded.settlements
	_places = settlements_loaded.places


func _service() -> SettlementService:
	return SettlementService.new(_settlements, _places)


func _setup(is_development_build: bool = false) -> NpcSetup:
	var setup: NpcSetup = NpcSetup.from_dir(DATA_DIR, _service(), is_development_build)
	assert_true(setup.result.ok, setup.result.message)
	return setup


# ---------------------------------------------------------------------------------------------------- o conjunto

func test_from_dir_assembles_everything_the_module_needs_from_the_real_data() -> void:
	var setup: NpcSetup = _setup()
	assert_eq(setup.need_defs.size(), NpcState.NEED_COUNT, "As cinco necessidades.")
	assert_true(setup.routine.has_occupation("farmer"))
	var definitions: NpcModule.Definitions = setup.definitions
	assert_eq(definitions.traits.size(), NpcState.TRAIT_COUNT)
	assert_gt(definitions.actions.size(), 0)
	assert_not_null(definitions.params)
	assert_not_null(definitions.places)
	assert_eq(definitions.population.total(), 100)
	var food: FoodStub = definitions.food as FoodStub
	assert_not_null(food, "O provedor de comida do jogo é o FoodStub (TEMP-LW-065).")
	var settlement_ids: Array[String] = []
	for settlement: Settlement in _settlements:
		settlement_ids.append(settlement.id)
		assert_true(food.has_food(settlement.id), "O assentamento '%s' começa com comida." % settlement.id)
	assert_eq(food.settlement_ids().size(), settlement_ids.size())
	assert_gt(definitions.income.peek_relief("farmer"), 0, "O IncomeStub (TEMP-LW-066) vem carregado.")
	assert_false(definitions.is_development_build, "Padrão: não é build de desenvolvimento.")
	assert_true(_setup(true).definitions.is_development_build, "A flag que a fronteira do app entrega vai até as definições.")


func test_a_broken_folder_or_missing_places_fail_with_one_message_and_no_log_noise() -> void:
	var broken: NpcSetup = NpcSetup.from_dir("res://tests/fixtures/data/ok", _service())
	assert_false(broken.result.ok)
	assert_eq(broken.result.code, NpcSetup.CODE_INVALID)
	assert_string_contains(broken.result.message, "NpcSetup.from_dir")
	assert_string_contains(broken.result.message, "necessidades")
	assert_string_contains(broken.result.message, "needs.json")
	assert_null(broken.definitions)
	var no_places: NpcSetup = NpcSetup.from_dir(DATA_DIR, null)
	assert_false(no_places.result.ok)
	assert_eq(no_places.result.code, NpcSetup.CODE_INVALID)
	assert_string_contains(no_places.result.message, "serviço de locais")


# ---------------------------------------------------------------------------------------------------- no jogo

func test_the_game_modules_create_the_population_only_when_they_receive_the_setup() -> void:
	var with_setup: SimulationRunner = SimulationRunner.new(WORLD_SEED)
	var modules: GameModules = GameModules.register(with_setup, _terrain, _points, _setup())
	assert_true(modules.result.ok, modules.result.message)
	assert_eq(modules.npc.peek_counts()["total"], 0, "Antes do jogo novo ninguém existe.")
	with_setup.start_new_game()
	assert_eq(modules.npc.peek_counts()["total"], 100)
	assert_eq(with_setup.world.context.ids.serialize()[IdGenerator.KEY_NEXT_ID], 101, "Os 100 NPCs gastaram os IDs de 1 a 100; o próximo é do personagem.")
	assert_eq(modules.npc.validate().size(), 0)
	with_setup.finish()
	var without: SimulationRunner = SimulationRunner.new(WORLD_SEED)
	var bare: GameModules = GameModules.register(without, _terrain, _points)
	without.start_new_game()
	assert_eq(bare.npc.peek_counts()["total"], 0, "Sem o conjunto o módulo nasce sem NPCs (o comportamento de antes).")
	without.finish()
	var failed_setup: NpcSetup = NpcSetup.from_dir("res://tests/fixtures/data/ok", _service())
	var failed_runner: SimulationRunner = SimulationRunner.new(WORLD_SEED)
	var failed: GameModules = GameModules.register(failed_runner, _terrain, _points, failed_setup)
	assert_true(failed.result.ok, "Conjunto que não carregou não derruba o registro dos módulos.")
	failed_runner.start_new_game()
	assert_eq(failed.npc.peek_counts()["total"], 0)
	failed_runner.finish()


func test_the_host_starts_a_new_game_with_the_population_when_it_gets_the_setup() -> void:
	var host: SimulationHostNode = autofree(SimulationHostNode.new())
	host.start_new_game(WORLD_SEED, _terrain, _points, _setup())
	var saved: Dictionary = host.runner.world.serialize()
	var modules_data: Dictionary = saved["modules"]
	var npc_data: Dictionary = modules_data["npc"]
	var npcs: Dictionary = npc_data["npcs"]
	assert_eq(npcs.size(), 100)
	assert_true(npc_data.has(FoodStub.SAVE_KEY), "O estoque de comida vai no save do jogo.")
	host.runner.finish()
	host.start_new_game(WORLD_SEED, _terrain, _points)
	var bare_modules: Dictionary = host.runner.world.serialize()["modules"]
	var bare_npc: Dictionary = bare_modules["npc"]
	var bare_npcs: Dictionary = bare_npc["npcs"]
	assert_eq(bare_npcs.size(), 0, "Sem o conjunto, o jogo de antes: nenhum NPC.")
	host.runner.finish()


func test_the_world_the_game_app_started_when_the_project_opened_has_the_population() -> void:
	var host: SimulationHostNode = get_node_or_null("/root/SimulationHost") as SimulationHostNode
	assert_not_null(host, "O autoload SimulationHost existe.")
	if host == null or host.runner == null:
		return
	var modules_data: Dictionary = host.runner.world.serialize()["modules"]
	var npc_data: Dictionary = modules_data["npc"]
	var npcs: Dictionary = npc_data["npcs"]
	assert_eq(npcs.size(), 100, "O `_ready` do GameApp leu os dados reais e o jogo nasceu com os 100 NPCs.")


func test_one_game_day_with_the_real_data_closes_with_nothing_wrong() -> void:
	var runner: SimulationRunner = SimulationRunner.new(WORLD_SEED)
	var modules: GameModules = GameModules.register(runner, _terrain, _points, _setup())
	assert_true(modules.result.ok, modules.result.message)
	runner.start_new_game()
	runner.run_days(1)
	var summary: Dictionary = modules.npc.debug_summary()
	assert_true(summary["decision_enabled"], str(summary["decision_problem"]))
	assert_eq(summary["population_problem"], "")
	assert_gt(summary["max_thinks_in_a_step"], 0, "Os NPCs pensaram.")
	assert_true(summary["max_thinks_in_a_step"] <= 20, "O teto de pensamentos por passo (data/npc_params.json) foi respeitado.")
	var counts: Dictionary = modules.npc.peek_counts()
	assert_eq([counts["total"], counts["alive"]], [100, 100], "Ninguém morreu no primeiro dia.")
	for settlement: Settlement in _settlements:
		var stock: FoodStub.StockQuery = modules.npc.peek_food_stock(settlement.id)
		assert_true(stock.result.ok)
		assert_true(stock.stock >= 0 and stock.stock <= stock.max_stock, "Estoque de '%s' dentro da faixa: %d." % [settlement.id, stock.stock])
	assert_eq(runner.world.validate().size(), 0, str(runner.world.validate()))
	var acting: int = 0
	for npc_id: int in modules.npc.peek_npc_ids():
		if not modules.npc.peek_npc(npc_id).action_id.is_empty():
			acting += 1
	assert_gt(acting, 90, "Ao fim do dia quase todos estão fazendo alguma coisa (%d de 100)." % acting)
	runner.finish()
