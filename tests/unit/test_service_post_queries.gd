extends GutTest
## LW-095 (parte c): a consulta dos postos de serviço pela porta da economia (docs/modules/economy.md, seção 6): `peek_post`, `peek_post_at` e `peek_posts_of`, com os MESMOS nomes de `peek_site` (`workplace_id`, `place_id`, `settlement_id`,
## `occupation_id`, `wage_per_hour`, `workers_wanted`, `workers_assigned`, `worker_ids`, `running`, `reason`) para a LW-096a pontuar a vaga sem distinguir o local de produção do posto. Economia REAL com as definições de postos montadas à mão: um posto
## de `guard` em `a_work_05` e um de `innkeeper` em `a_work_04`, ambos no povoado A (IDs 3 e 4, depois dos mercados). A resposta é uma CÓPIA e o ID que não existe falha tratada.

const SEED: int = 67
const MINUTES_PER_HOUR: int = 60
const SETTLEMENT_A: String = "test_settlement_a"
const POST_GUARD: int = 3
const POST_INN: int = 4
const GUARDS: Array[int] = [102, 100, 101]


func _definitions(market_money: int) -> EconomyDefinitions:
	var setup: EconomySetup = EconomySetup.from_dir(EconomySetup.DEFAULT_DIR)
	assert_true(setup.result.ok, setup.result.message)
	var definitions: EconomyDefinitions = setup.definitions
	var posts: Array[PostDef] = [PostDef.new("post_a_guard", SETTLEMENT_A, "a_work_05", "guard", 8, 3), PostDef.new("post_a_inn", SETTLEMENT_A, "a_work_04", "innkeeper", 6, 2)]
	definitions.service_posts = posts
	for kind: OwnerKindDef in definitions.kinds:
		if kind.id == MarketBook.KIND_MARKET:
			kind.initial_balance = market_money
	return definitions


func _world(module: EconomyModule) -> World:
	var clock: SimClock = SimClock.new()
	var world: World = World.new(SimContext.new(clock, EventBus.new(clock), WorldRng.new(SEED), IdGenerator.new()))
	assert_true(world.register_module("economy", module).ok)
	world.setup()
	world.post_setup()
	world.on_new_game(SEED)
	return world


func _run_minutes(world: World, minutes: int) -> void:
	for _minute: int in minutes:
		world.context.clock.advance_step()
		world.tick(1)
	world.context.events.dispatch()


func test_the_door_shows_each_post_with_the_names_of_the_production_site() -> void:
	var module: EconomyModule = EconomyModule.new(false, _definitions(3000))
	var world: World = _world(module)
	var guard: EconomyReplies.PostQuery = module.peek_post(POST_GUARD)
	assert_true(guard.result.ok, guard.result.message)
	assert_eq([guard.workplace_id, guard.place_id, guard.settlement_id, guard.occupation_id, guard.wage_per_hour, guard.workers_wanted, guard.workers_assigned], [POST_GUARD, "a_work_05", SETTLEMENT_A, "guard", 3, 8, 0])
	assert_eq([guard.worker_ids, guard.running, guard.reason], [[] as Array[int], true, ""], "Nasce pago e sem equipe.")
	assert_eq([module.peek_post_at("a_work_04").workplace_id, module.peek_post_at("a_work_04").occupation_id], [POST_INN, "innkeeper"])
	var both: EconomyReplies.PostsQuery = module.peek_posts_of(SETTLEMENT_A)
	assert_eq([both.posts.size(), both.posts[0].workplace_id, both.posts[1].workplace_id], [2, POST_GUARD, POST_INN], "Por ID crescente.")
	assert_eq(module.peek_posts_of("test_settlement_b").posts.size(), 0, "Povoado sem posto: lista vazia.")
	world.teardown()


func test_unknown_ids_and_places_fail_with_a_handled_result_and_a_post_is_not_a_site() -> void:
	var module: EconomyModule = EconomyModule.new(false, _definitions(3000))
	var world: World = _world(module)
	for missing: EconomyReplies.PostQuery in [module.peek_post(999), module.peek_post_at("a_work_01"), module.peek_post(IdGenerator.NO_ID)]:
		assert_false(missing.result.ok)
		assert_eq(missing.result.code, EconomyCodes.UNKNOWN_OWNER)
	assert_string_contains(module.peek_post(999).result.message, "999")
	assert_false(module.peek_site(POST_GUARD).result.ok, "O ID de um posto não é de um local de produção.")
	var without: EconomyModule = EconomyModule.new()
	assert_false(without.peek_post(POST_GUARD).result.ok)
	assert_eq(without.peek_posts_of(SETTLEMENT_A).posts.size(), 0, "Economia sem postos: nada a mostrar, sem erro.")
	world.teardown()


func test_the_team_comes_sorted_and_a_market_without_money_shows_no_funds_and_the_answer_is_a_copy() -> void:
	var module: EconomyModule = EconomyModule.new(false, _definitions(5))
	var world: World = _world(module)
	for npc_id: int in GUARDS:
		assert_true(module.request_open_owner(npc_id, "npc", "a_work_05").ok)
	var before: EconomyReplies.PostQuery = module.peek_post(POST_GUARD)
	assert_eq([before.worker_ids, before.workers_assigned, before.running], [[100, 101, 102] as Array[int], 3, true], "Em ordem crescente, não na ordem de entrada; ainda não houve hora.")
	_run_minutes(world, MINUTES_PER_HOUR)
	var stopped: EconomyReplies.PostQuery = module.peek_post(POST_GUARD)
	assert_eq([stopped.running, stopped.reason], [false, ServicePostBook.NO_FUNDS], "5 no mercado não cobrem a folha de 9.")
	stopped.worker_ids.append(777)
	assert_eq(module.peek_post(POST_GUARD).worker_ids, [100, 101, 102] as Array[int], "Mexer na resposta não muda o estado.")
	assert_eq([module.peek_post(POST_INN).running, module.peek_post(POST_INN).reason], [true, ""], "Posto sem equipe não está parado.")
	world.teardown()
