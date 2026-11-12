extends GutTest
## LW-096a (R18-I1, decisão de Arthur de 12/11/2026): EMPREGADO é quem tem `work_place_id` preenchido (o `npc` é o dono dele); um local de trabalho que a economia NÃO conhece (o posto de um povoado sem `service_posts.json`, por exemplo) não faz o NPC contar
## como desempregado: a utilidade do emprego dele vale 0 (a economia não o paga) e a HISTERESE vale. Cenário: só um local de produção de `bake_bread` em `a_work_01` (2 vagas, salário 2) e NENHUM posto nos dados; o guarda tem `work_place_id` `a_work_05`, que a
## economia não conhece. A vaga do local de produção vale 16 para ele (ofício diferente, sem bônus), abaixo da histerese de 20: ele NÃO a pega, mas o desempregado de verdade (sem `work_place_id`) pega; o artesão com o mesmo `work_place_id` desconhecido ganha o bônus de
## ofício (26, acima de 20) e TROCA: é a histerese, não uma exclusão. Testes novos; os do `test_npc_vacancy.gd` seguem como estavam.

const SEED: int = 103
const MINUTES_PER_HOUR: int = 60
const SETTLEMENT_A: String = "test_settlement_a"
const SITE_PLACE: String = "a_work_01"
const UNKNOWN_PLACE: String = "a_work_05"
const HOME: String = "home_near"
const SITE: int = 3
const NEED_IDS: Array[String] = ["hunger", "rest", "safety", "income", "social"]


func _need_defs() -> Array[NeedDef]:
	var defs: Array[NeedDef] = []
	for position: int in NEED_IDS.size():
		defs.append(NeedDef.new(NEED_IDS[position], position, 0, 0, 40, 65, 90))
	return defs


func _places() -> SettlementService:
	var settlements: Array[Settlement] = [Settlement.new(SETTLEMENT_A, "settlement.a", Vector3(0.0, 0.0, 0.0))]
	var places: Array[Place] = [
		Place.new(HOME, SETTLEMENT_A, Place.KIND_HOME, Vector3(100.0, 0.0, 0.0), 8),
		Place.new(SITE_PLACE, SETTLEMENT_A, Place.KIND_WORK, Vector3(100.0, 0.0, 0.0), 12),
		Place.new(UNKNOWN_PLACE, SETTLEMENT_A, Place.KIND_WORK, Vector3(100.0, 0.0, 0.0), 12),
	]
	return SettlementService.new(settlements, places)


## Mundo com a economia (um local de produção, NENHUM posto) e o `npc`. Devolve [world, economy, npc].
func _world() -> Array:
	var setup: EconomySetup = EconomySetup.from_dir(EconomySetup.DEFAULT_DIR)
	assert_true(setup.result.ok, setup.result.message)
	var definitions: EconomyDefinitions = setup.definitions
	var sites: Array[SiteDef] = [SiteDef.new("site_bread", SETTLEMENT_A, SITE_PLACE, "bake_bread", 2)]
	definitions.production_sites = sites
	var economy: EconomyModule = EconomyModule.new(false, definitions)
	var npc_definitions: NpcModule.Definitions = NpcModule.Definitions.new()
	npc_definitions.params = NpcParams.new()
	npc_definitions.places = _places()
	var npc: NpcModule = NpcModule.new(_need_defs(), null, npc_definitions, economy)
	var clock: SimClock = SimClock.new()
	var world: World = World.new(SimContext.new(clock, EventBus.new(clock), WorldRng.new(SEED), IdGenerator.new()))
	assert_true(world.register_module("economy", economy).ok)
	assert_true(world.register_module("npc", npc).ok)
	world.setup()
	world.post_setup()
	world.on_new_game(SEED)
	return [world, economy, npc]


func _spawn(npc: NpcModule, work_place_id: String, occupation_id: String) -> int:
	var spec: NpcSpec = NpcSpec.new()
	spec.name_key = "npc.name.villager"
	spec.name_number = 1
	spec.settlement_id = SETTLEMENT_A
	spec.home_place_id = HOME
	spec.work_place_id = work_place_id
	spec.occupation_id = occupation_id
	var created: NpcModule.CreateResult = npc.request_create_npc(spec)
	assert_true(created.result.ok, created.result.message)
	return created.npc_id


func _run_hours(world: World, hours: int) -> void:
	for _minute: int in hours * MINUTES_PER_HOUR:
		world.context.clock.advance_step()
		world.tick(1)
		world.context.events.dispatch()


func test_a_npc_with_a_work_place_the_economy_does_not_know_is_employed_and_the_hysteresis_applies() -> void:
	var parts: Array = _world()
	var world: World = parts[0]
	var economy: EconomyModule = parts[1]
	var npc: NpcModule = parts[2]
	var baker: int = _spawn(npc, SITE_PLACE, "artisan")
	var guard: int = _spawn(npc, UNKNOWN_PLACE, "guard")
	_run_hours(world, 3)
	assert_false(economy.peek_site(SITE).worker_ids.has(guard), "Vaga de 16 contra 20 de histerese: o guarda, que TEM `work_place_id`, não troca.")
	assert_eq(npc.peek_npc(guard).work_place_id, UNKNOWN_PLACE, "O `work_place_id` dele não mudou.")
	assert_eq(economy.peek_site(SITE).worker_ids, [baker] as Array[int], "A vaga segue aberta, sem ninguém para pegá-la.")
	assert_eq(economy.peek_contracts("open").contracts.size(), 1)
	world.teardown()


func test_the_jobless_npc_without_a_work_place_takes_the_same_vacancy_and_the_guard_stays() -> void:
	var parts: Array = _world()
	var world: World = parts[0]
	var economy: EconomyModule = parts[1]
	var npc: NpcModule = parts[2]
	_spawn(npc, SITE_PLACE, "artisan")
	var guard: int = _spawn(npc, UNKNOWN_PLACE, "guard")
	var jobless: int = _spawn(npc, "", "guard")
	_run_hours(world, 3)
	assert_eq([economy.peek_site(SITE).worker_ids.has(jobless), npc.peek_npc(jobless).work_place_id], [true, SITE_PLACE], "Sem `work_place_id` é desempregado de verdade: 16 é positivo e ele aceita.")
	assert_eq(npc.peek_npc(guard).work_place_id, UNKNOWN_PLACE, "O guarda de local desconhecido não pegou a vaga na frente dele.")
	world.teardown()


func test_the_same_unknown_work_place_does_switch_when_the_gain_passes_the_hysteresis() -> void:
	var parts: Array = _world()
	var world: World = parts[0]
	var economy: EconomyModule = parts[1]
	var npc: NpcModule = parts[2]
	_spawn(npc, SITE_PLACE, "artisan")
	var artisan: int = _spawn(npc, UNKNOWN_PLACE, "artisan")
	_run_hours(world, 3)
	assert_eq([economy.peek_site(SITE).worker_ids.has(artisan), npc.peek_npc(artisan).work_place_id], [true, SITE_PLACE], "16 mais o bônus de ofício de 10 dão 26, acima da histerese de 20: troca (é a histerese, não uma exclusão).")
	world.teardown()
