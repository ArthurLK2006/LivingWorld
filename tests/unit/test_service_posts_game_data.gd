extends GutTest
## LW-095e: o dado REAL dos postos de serviço (`data/economy/service_posts.json`; docs/economy/dados.md, tabela `service_posts.json`; contrato aprovado por Arthur em 14/11/2026; salário de 1 por hora [HIP], autorização de Arthur de 21/11/2026 para
## preparar em ramo isolado). Confere (1) que o arquivo traz exatamente os 6 postos do contrato, (2) que cada posto bate com `data/population.json` (mesmo povoado, ofício e quantidade de quem nasce com aquele `work_place_id`) e com `data/world/places.json`
## (local `work` do mesmo povoado, vagas dentro da capacidade) e (3), com a economia REAL e só ela, que o mercado sem a folha inteira de um posto para AQUELE posto com `NO_FUNDS` e paga o outro (tudo ou nada por posto). Os valores esperados são
## literais do contrato de propósito: o teste não herda o número do arquivo que confere.

const SEED: int = 95
const MINUTES_PER_HOUR: int = 60
const SETTLEMENT_A: String = "test_settlement_a"
const NPC_START_MONEY: int = 60
## Os 6 postos do contrato: id, povoado, local, ofício, vagas e salário por hora.
const CONTRACT_POSTS: Array = [
	["post_a_guard", "test_settlement_a", "a_work_06", "guard", 8, 1],
	["post_a_inn", "test_settlement_a", "a_work_07", "innkeeper", 6, 1],
	["post_b_guard", "test_settlement_b", "b_work_07", "guard", 5, 1],
	["post_b_inn", "test_settlement_b", "b_work_08", "innkeeper", 3, 1],
	["post_c_guard", "test_settlement_c", "c_work_04", "guard", 5, 1],
	["post_c_inn", "test_settlement_c", "c_work_05", "innkeeper", 3, 1],
]


func _read_rows(path: String) -> Array:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	assert_eq(typeof(parsed), TYPE_ARRAY, "%s é uma lista." % path)
	return parsed if typeof(parsed) == TYPE_ARRAY else []


func test_the_real_file_has_exactly_the_six_posts_of_the_contract() -> void:
	var loaded: PostLoader.LoadResult = PostLoader.load_dir(EconomySetup.DEFAULT_DIR)
	assert_true(loaded.result.ok, loaded.result.message)
	var found: Array = []
	for post: PostDef in loaded.posts:
		found.append([post.id, post.settlement_id, post.place_id, post.occupation_id, post.workers_wanted, post.wage_per_hour])
	assert_eq(found, CONTRACT_POSTS, "Os 6 postos, na ordem do contrato.")
	var setup: EconomySetup = EconomySetup.from_dir(EconomySetup.DEFAULT_DIR)
	assert_true(setup.result.ok, setup.result.message)
	assert_eq(setup.definitions.service_posts.size(), 6, "O `EconomySetup` real leva os 6 postos às definições, sem conflito com os locais de produção.")


func test_every_post_matches_the_population_and_the_work_place_of_the_world() -> void:
	var population: Array = _read_rows("res://data/population.json")
	var places: Dictionary = {}
	for place: Dictionary in _read_rows("res://data/world/places.json"):
		places[place["id"]] = place
	for post: Array in CONTRACT_POSTS:
		var born_here: Array = population.filter(func(line: Dictionary) -> bool: return line["work_place_id"] == post[2])
		assert_eq(born_here.size(), 1, "Uma linha da população trabalha em %s." % post[2])
		if born_here.size() != 1:
			continue
		var row: Dictionary = born_here[0]
		assert_eq([row["settlement_id"], row["occupation_id"], int(row["count"])], [post[1], post[3], post[4]], "%s: povoado, ofício e quantidade da população." % post[0])
		assert_true(places.has(post[2]), "O local %s existe." % post[2])
		var place: Dictionary = places.get(post[2], {})
		assert_eq([place.get("kind"), place.get("settlement_id")], ["work", post[1]], "%s: local `work` do mesmo povoado." % post[0])
		assert_true(int(place.get("capacity", 0)) >= post[4], "%s: as vagas cabem na capacidade do local." % post[0])


func _world(module: EconomyModule) -> World:
	var clock: SimClock = SimClock.new()
	var world: World = World.new(SimContext.new(clock, EventBus.new(clock), WorldRng.new(SEED), IdGenerator.new()))
	assert_true(world.register_module("economy", module).ok)
	world.setup()
	world.post_setup()
	world.on_new_game(SEED)
	return world


## Mercado A com 7 moedas: a folha do posto de guardas (8 × 1) não cabe e ele para INTEIRO com `NO_FUNDS`; a dos estalajadeiros (6 × 1) cabe e é paga.
func test_a_market_short_of_one_post_payroll_stops_that_whole_post_and_pays_the_other() -> void:
	var setup: EconomySetup = EconomySetup.from_dir(EconomySetup.DEFAULT_DIR)
	assert_true(setup.result.ok, setup.result.message)
	var no_sites: Array[SiteDef] = []
	setup.definitions.production_sites = no_sites
	for kind: OwnerKindDef in setup.definitions.kinds:
		if kind.id == MarketBook.KIND_MARKET:
			kind.initial_balance = 7
	var module: EconomyModule = EconomyModule.new(false, setup.definitions)
	var world: World = _world(module)
	var guards: Array[int] = []
	var innkeepers: Array[int] = []
	for index: int in 8:
		guards.append(100 + index)
		assert_true(module.request_open_owner(100 + index, "npc", "a_work_06").ok)
	for index: int in 6:
		innkeepers.append(200 + index)
		assert_true(module.request_open_owner(200 + index, "npc", "a_work_07").ok)
	var paid: Array[int] = []
	world.context.events.subscribe("WagesPaid", func(event: SimEvent) -> void: paid.append((event as WagesPaid).workplace_id))
	for _minute: int in MINUTES_PER_HOUR:
		world.context.clock.advance_step()
		world.tick(1)
	world.context.events.dispatch()
	var guard_post: EconomyReplies.PostQuery = module.peek_post_at("a_work_06")
	var inn_post: EconomyReplies.PostQuery = module.peek_post_at("a_work_07")
	assert_eq([guard_post.running, guard_post.reason, guard_post.workers_assigned], [false, "NO_FUNDS", 8], "Os guardas: o posto inteiro para e ninguém é demitido.")
	assert_eq([inn_post.running, inn_post.workers_assigned], [true, 6])
	assert_eq(paid, [inn_post.workplace_id] as Array[int], "Só o posto pago publica `WagesPaid`.")
	for guard: int in guards:
		assert_eq(module.peek_balance(guard).balance, NPC_START_MONEY, "Tudo ou nada: nenhum guarda recebe.")
	for innkeeper: int in innkeepers:
		assert_eq(module.peek_balance(innkeeper).balance, NPC_START_MONEY + 1)
	assert_eq(module.peek_posts_of(SETTLEMENT_A).posts.size(), 2, "O povoado A tem os seus 2 postos.")
	assert_true(module.peek_conservation().ok)
	assert_eq(module.validate(), [] as Array[String])
	world.teardown()
