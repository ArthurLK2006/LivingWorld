extends GutTest
## LW-088a: a casca do módulo `economy` (src/sim/economy/economy_module.gd; contrato em docs/modules/economy.md, seção 2). Sem estado nem comportamento: o que se
## prova é que ela entra no `World` e no save como um bloco VAZIO (e por isso muda o `state_hash`, DEC-172), que carregar recusa qualquer conteúdo com mensagem clara,
## que um save sem o bloco é recusado pelo `World` (DEC-134) e que o jogo a registra ANTES do `npc`. Os valores esperados estão escritos à mão.

const TERRAIN_DIR: String = "res://data/world"
const WORLD_SEED: int = 5
## Escrito à mão: é a chave do módulo no save, e mudá-la sem querer quebraria os saves.
const EXPECTED_NAME: String = "economy"


func _world(world_seed: int, with_economy: bool) -> World:
	var clock: SimClock = SimClock.new()
	var world: World = World.new(SimContext.new(clock, EventBus.new(clock), WorldRng.new(world_seed), IdGenerator.new()))
	if with_economy:
		assert_true(world.register_module(EXPECTED_NAME, EconomyModule.new()).ok)
	world.setup()
	world.post_setup()
	world.on_new_game(world_seed)
	return world


func test_the_shell_saves_an_empty_block_and_has_nothing_to_report() -> void:
	var world: World = _world(WORLD_SEED, true)
	var saved: Dictionary = world.serialize()
	assert_eq(saved["modules"].keys(), [EXPECTED_NAME], "A economy entra no save como um módulo.")
	assert_eq(saved["modules"][EXPECTED_NAME], {}, "Sem estado: o bloco é vazio.")
	assert_eq(world.validate(), [] as Array[String], "A casca não tem inconsistência.")
	assert_eq(GameModules.ECONOMY_NAME, EXPECTED_NAME)
	world.teardown()


func test_loading_accepts_the_empty_block_and_refuses_any_content_with_a_clear_message() -> void:
	var module: EconomyModule = EconomyModule.new()
	assert_true(module.on_load({}).ok)
	var refused: Result = module.on_load({"ledger": {}, "accounts": 1})
	assert_false(refused.ok)
	assert_eq(refused.code, EconomyModule.CODE_INVALID_SAVE)
	assert_eq(EconomyModule.CODE_INVALID_SAVE, "ECON_INVALID_SAVE")
	assert_string_contains(refused.message, "2 chave(s) (accounts, ledger)")
	assert_string_contains(refused.message, "esperado vazio")
	var world: World = _world(WORLD_SEED, true)
	var data: Dictionary = world.serialize()
	data["modules"][EXPECTED_NAME] = {"ledger": {}}
	var target: World = _world(WORLD_SEED, true)
	var via_world: Result = target.on_load(data)
	assert_eq(via_world.code, EconomyModule.CODE_INVALID_SAVE, "O World repassa o código do módulo.")
	assert_string_contains(via_world.message, "módulo 'economy'")
	world.teardown()
	target.teardown()


func test_a_save_without_the_economy_block_is_refused_by_the_world() -> void:
	var without: World = _world(WORLD_SEED, false)
	var with_economy: World = _world(WORLD_SEED, true)
	var refused: Result = with_economy.on_load(without.serialize())
	assert_false(refused.ok, "Save antigo, sem o bloco da economy, é rejeitado (DEC-134).")
	assert_eq(refused.code, "WORLD_MODULE_DATA_MISSING")
	assert_string_contains(refused.message, "'economy'")
	var unknown: Result = without.on_load(with_economy.serialize())
	assert_eq(unknown.code, "WORLD_UNKNOWN_MODULE", "O contrário também: o save tem um módulo que este mundo não registrou.")
	without.teardown()
	with_economy.teardown()


func test_the_empty_block_changes_the_hash_and_the_hash_is_stable_across_runs_and_a_save() -> void:
	var bare: World = _world(WORLD_SEED, false)
	var first: World = _world(WORLD_SEED, true)
	var second: World = _world(WORLD_SEED, true)
	assert_ne(first.state_hash(), bare.state_hash(), "O bloco vazio basta para mudar a impressão digital (DEC-172).")
	assert_eq(first.state_hash(), second.state_hash(), "Mesma semente, mesmo hash.")
	var restored: World = _world(WORLD_SEED + 1, true)
	assert_ne(restored.state_hash(), first.state_hash(), "Outra semente, outro hash.")
	assert_true(restored.on_load(first.serialize()).ok)
	assert_eq(restored.state_hash(), first.state_hash(), "Salvar e carregar não muda o hash.")
	var worlds: Array[World] = [bare, first, second, restored]
	for world: World in worlds:
		world.teardown()


func test_the_game_registers_the_economy_before_the_npc() -> void:
	var loaded: TerrainLoader.LoadResult = TerrainLoader.load_dir(TERRAIN_DIR)
	assert_true(loaded.result.ok, loaded.result.message)
	var runner: SimulationRunner = SimulationRunner.new(WORLD_SEED)
	var modules: GameModules = GameModules.register(runner, loaded.terrain)
	assert_true(modules.result.ok, modules.result.message)
	assert_not_null(modules.economy)
	var names: Array[String] = runner.world.module_names()
	assert_true(names.has(EXPECTED_NAME))
	assert_lt(names.find(EXPECTED_NAME), names.find(GameModules.NPC_NAME), "A economy vem antes do npc, que vai abrir as contas dela.")
	runner.finish()
