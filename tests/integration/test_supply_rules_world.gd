extends GutTest
## LW-094b (PROPOSTA; docs/economia/contrato-lw-094b-regras-de-oferta.md), invariantes 4 a 6. (6) Duas fazendas iguais no mesmo povoado, com o mercado que só compra um lote por hora: em 30 dias vendem em quase o mesmo número de horas
## (antes a de ID menor vendia em todas). (4) O jogo real (`SimulationRunner`, com o `FoodStub`): duas execuções iguais dão o mesmo `state_hash`, e salvar e carregar no meio de uma janela de rodízio dá o mesmo hash da execução direta.
## (5) As chaves do bloco da economia no save são as de antes.

const SEED: int = 59
const SETTLEMENT_A: String = "test_settlement_a"
const GRAIN_CAP: int = 240
const BATCH: int = 8
const DAYS: int = 30
const SAVE_AT_STEPS: int = 1000
const AFTER_SAVE_STEPS: int = 500
## As chaves do bloco da economia nesse ponto do jogo real (as mesmas do ramo de partida: `EconomyPersistence` não muda nesta tarefa).
const ECONOMY_KEYS: Array[String] = ["goods", "ledger", "markets", "owners", "posts", "production"]


func _farm_world() -> Array:
	var setup: EconomySetup = EconomySetup.from_dir(EconomySetup.DEFAULT_DIR)
	assert_true(setup.result.ok, setup.result.message)
	var definitions: EconomyDefinitions = setup.definitions
	var sites: Array[SiteDef] = [SiteDef.new("farm_1", SETTLEMENT_A, "a_work_01", "grow_grain", 4), SiteDef.new("farm_2", SETTLEMENT_A, "a_work_02", "grow_grain", 4)]
	definitions.production_sites = sites
	definitions.recipes["grow_grain"].upkeep.clear()
	definitions.is_development_build = true
	for kind: OwnerKindDef in definitions.kinds:
		if kind.id == ProductionBook.KIND_SITE:
			kind.initial_balance = 100000
	var module: EconomyModule = EconomyModule.new(false, definitions)
	var clock: SimClock = SimClock.new()
	var world: World = World.new(SimContext.new(clock, EventBus.new(clock), WorldRng.new(SEED), IdGenerator.new()))
	assert_true(world.register_module("economy", module).ok)
	world.setup()
	world.post_setup()
	world.on_new_game(SEED)
	for offset: int in 8:
		assert_true(module.request_open_owner(100 + offset, "npc", "a_work_01" if offset < 4 else "a_work_02").ok)
	return [world, module]


func _grain(module: EconomyModule, owner_id: int) -> int:
	for row: Dictionary in module.peek_inventory(owner_id).rows:
		if row["good_id"] == "grain":
			return int(row["quantity"])
	return 0


func test_two_equal_farms_sell_in_almost_the_same_number_of_hours() -> void:
	var parts: Array = _farm_world()
	var world: World = parts[0]
	var module: EconomyModule = parts[1]
	var farm_1: int = module.peek_site_at("a_work_01").workplace_id
	var farm_2: int = module.peek_site_at("a_work_02").workplace_id
	assert_true(farm_1 < farm_2, "A fazenda 1 tem o ID menor (a que levava vantagem com a ordem fixa).")
	var market_id: int = module.peek_market_of(SETTLEMENT_A).market_id
	var sold_hours: Dictionary[int, int] = {farm_1: 0, farm_2: 0}
	for _hour: int in DAYS * SimClock.HOURS_PER_DAY:
		assert_true(module.request_set_stock(market_id, "grain", GRAIN_CAP - BATCH).ok, "O povoado compra um lote por hora: o teto deixa espaço para 8 grãos.")
		var before: Dictionary[int, int] = {farm_1: _grain(module, farm_1), farm_2: _grain(module, farm_2)}
		for _minute: int in SimClock.MINUTES_PER_HOUR:
			world.context.clock.advance_step()
			world.tick(1)
		world.context.events.dispatch()
		for site_id: int in [farm_1, farm_2]:
			var made: int = BATCH if module.peek_site(site_id).running else 0
			if before[site_id] + made - _grain(module, site_id) > 0:
				sold_hours[site_id] += 1
	gut.p("Horas com venda em 30 dias: fazenda %d = %d, fazenda %d = %d." % [farm_1, sold_hours[farm_1], farm_2, sold_hours[farm_2]])
	assert_true(sold_hours[farm_1] > 0 and sold_hours[farm_2] > 0, "As duas vendem.")
	assert_true(absi(sold_hours[farm_1] - sold_hours[farm_2]) <= 1, "Nenhuma das duas tem vantagem pela ordem do ID (diferença de no máximo 1 hora).")
	assert_true(module.peek_conservation().ok and module.peek_goods_conservation().ok)
	world.teardown()


func _runner() -> SimulationRunner:
	var data: NpcLifeCheck.GameData = NpcLifeCheck.load_game_data()
	var setup: NpcSetup = NpcSetup.from_dir("res://data", SettlementService.new(data.settlements, data.places))
	var runner: SimulationRunner = SimulationRunner.new(GameAppNode.DEFAULT_WORLD_SEED, GameAppNode.NEW_GAME_START_MINUTE)
	var modules: GameModules = GameModules.register(runner, data.terrain, data.points, setup, EconomySetup.from_dir(EconomySetup.DEFAULT_DIR), WorldSetup.from_dir("res://data/world", data.settlements))
	assert_true(modules.result.ok, modules.result.message)
	return runner


func test_the_real_game_is_deterministic_and_a_save_in_the_middle_of_a_rotation_gives_the_same_hash() -> void:
	var direct: SimulationRunner = _runner()
	direct.start_new_game()
	direct.run_steps(SAVE_AT_STEPS)
	var hour: int = IntMath.floor_div(direct.world.context.clock.total_minutes(), SimClock.MINUTES_PER_HOUR)
	assert_true(posmod(hour, 14) != 0, "O save cai no meio de uma janela de rodízio dos 14 locais (hora %d)." % hour)
	var codec: JsonSaveCodec = JsonSaveCodec.new()
	var payload: Dictionary = direct.capture_game()
	var economy_block: Dictionary = ((payload["world"] as Dictionary)["modules"] as Dictionary)["economy"]
	var keys: Array[String] = []
	keys.assign(economy_block.keys())
	keys.sort()
	assert_eq(keys, ECONOMY_KEYS, "O bloco da economia tem as chaves de antes: nenhum estado novo no save.")
	var bytes: PackedByteArray = codec.encode(payload, "0.0.1-test")
	direct.run_steps(AFTER_SAVE_STEPS)
	var direct_hash: String = direct.world.state_hash()
	direct.finish()
	var again: SimulationRunner = _runner()
	again.start_new_game()
	again.run_steps(SAVE_AT_STEPS + AFTER_SAVE_STEPS)
	assert_eq(again.world.state_hash(), direct_hash, "Duas execuções iguais, o mesmo hash.")
	again.finish()
	var loaded: SimulationRunner = _runner()
	var decoded: DecodedSave = codec.decode(bytes)
	assert_true(decoded.result.ok, decoded.result.message)
	var result: Result = loaded.load_game(decoded.payload)
	assert_true(result.ok, result.message)
	loaded.run_steps(AFTER_SAVE_STEPS)
	assert_eq(loaded.world.state_hash(), direct_hash, "Salvar e carregar no meio do rodízio dá o mesmo resultado da execução direta.")
	loaded.finish()
