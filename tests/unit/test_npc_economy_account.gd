extends GutTest
## LW-093 (primeira parte): o NPC abre a conta dele na economia ao nascer, pela porta `economy/api` entregue ao módulo `npc` pelo construtor (docs/modules/npc.md, 14.4 e 14.6; DEC-145): o dono nasce do tipo `npc`, é atribuído ao
## local de produção do `work_place_id` (se houver), abrir de novo não muda nada e o módulo sem economia continua criando NPCs. A economia aqui é a REAL, com os dados reais (data/economy) e um local de produção de pão em `a_work_01`.

const SEED: int = 71
const SETTLEMENT_A: String = "test_settlement_a"
const PLACE_BREAD: String = "a_work_01"


func _definitions() -> EconomyDefinitions:
	var setup: EconomySetup = EconomySetup.from_dir(EconomySetup.DEFAULT_DIR)
	assert_true(setup.result.ok, setup.result.message)
	var definitions: EconomyDefinitions = setup.definitions
	var sites: Array[SiteDef] = [SiteDef.new("site_bread", SETTLEMENT_A, PLACE_BREAD, "bake_bread", 4)]
	definitions.production_sites = sites
	return definitions


func _world(economy: EconomyModule, npc: NpcModule) -> World:
	var clock: SimClock = SimClock.new()
	var world: World = World.new(SimContext.new(clock, EventBus.new(clock), WorldRng.new(SEED), IdGenerator.new()))
	if economy != null:
		assert_true(world.register_module("economy", economy).ok)
	assert_true(world.register_module("npc", npc).ok)
	world.setup()
	world.post_setup()
	world.on_new_game(SEED)
	return world


func _spec(work_place_id: String) -> NpcSpec:
	var spec: NpcSpec = NpcSpec.new()
	spec.name_key = "npc.name.villager"
	spec.name_number = 1
	spec.work_place_id = work_place_id
	return spec


func test_a_new_npc_opens_its_account_in_the_economy_and_joins_the_site_of_its_work_place() -> void:
	var economy: EconomyModule = EconomyModule.new(false, _definitions())
	var npc: NpcModule = NpcModule.new([], null, null, economy)
	var world: World = _world(economy, npc)
	var site_id: int = economy.peek_site_at(PLACE_BREAD).workplace_id
	var worker: NpcModule.CreateResult = npc.request_create_npc(_spec(PLACE_BREAD))
	assert_true(worker.result.ok, worker.result.message)
	var idle: NpcModule.CreateResult = npc.request_create_npc(_spec("a_work_05"))
	assert_true(idle.result.ok, idle.result.message)
	assert_true(economy.peek_balance(worker.npc_id).result.ok, "A conta do NPC existe na economia, com o ID dele.")
	assert_eq(economy.peek_site(site_id).worker_ids, [worker.npc_id] as Array[int], "Só quem tem o local de trabalho do local de produção é atribuído.")
	assert_true(economy.peek_balance(idle.npc_id).result.ok, "Quem não tem local de produção também ganha conta, sem ser atribuído.")
	assert_eq(economy.validate(), [] as Array[String])
	world.teardown()


func test_without_an_economy_the_npc_module_still_creates_npcs_and_opens_nothing() -> void:
	var npc: NpcModule = NpcModule.new()
	var world: World = _world(null, npc)
	var created: NpcModule.CreateResult = npc.request_create_npc(_spec(PLACE_BREAD))
	assert_true(created.result.ok, created.result.message)
	var economy_alone: EconomyModule = EconomyModule.new()
	assert_eq(economy_alone.peek_balance(created.npc_id).result.code, EconomyCodes.UNKNOWN_OWNER, "Outra economia, que não foi entregue ao módulo, não vê o NPC.")
	world.teardown()
