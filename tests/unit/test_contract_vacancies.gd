extends GutTest
## LW-096 (parte e): as vagas (docs/modules/economy.md, seção 8; DEC-165 e DEC-169): o local de produção ou posto com MENOS trabalhadores atribuídos do que `workers_wanted` ganha UMA vaga (emissor: o local, recompensa 0, sem prazo, sem custódia) e o
## `ContractOffered` sai; a vaga mostra os nomes de `peek_site` e `peek_post`; aceitar atribui o NPC ao local, tira a atribuição anterior (que gera vaga lá na hora seguinte), conclui na hora (`ContractCompleted`, recompensa 0); a vaga que o preenchimento
## alheio tornou desnecessária falha em silêncio; o local sem dinheiro para a folha PARA e NÃO demite (a equipe fica e não gera vaga). Economia REAL com um local de `bake_bread` em `a_work_01` (4 vagas, 2 de salário) e um posto de `guard` em
## `a_work_05` (1 vaga, 3 de salário), definições montadas à mão; NPCs reais (saldo inicial 60). A hora é a cadência: a conferência roda a cada hora cheia.

const SEED: int = 89
const MINUTES_PER_HOUR: int = 60
const SETTLEMENT_A: String = "test_settlement_a"
const PLACE_SITE: String = "a_work_01"
const PLACE_POST: String = "a_work_05"
const SITE: int = 3
const POST: int = 4
const SITE_WANTED: int = 4
const SITE_WAGE: int = 2
const POST_WAGE: int = 3
const NPC_BASE: int = 100


func _definitions(site_money: int = 5000) -> EconomyDefinitions:
	var setup: EconomySetup = EconomySetup.from_dir(EconomySetup.DEFAULT_DIR)
	assert_true(setup.result.ok, setup.result.message)
	var definitions: EconomyDefinitions = setup.definitions
	var sites: Array[SiteDef] = [SiteDef.new("site_bread", SETTLEMENT_A, PLACE_SITE, "bake_bread", SITE_WANTED)]
	definitions.production_sites = sites
	var posts: Array[PostDef] = [PostDef.new("post_a_guard", SETTLEMENT_A, PLACE_POST, "guard", 1, POST_WAGE)]
	definitions.service_posts = posts
	for kind: OwnerKindDef in definitions.kinds:
		if kind.id == ProductionBook.KIND_SITE:
			kind.initial_balance = site_money
	return definitions


func _world(site_money: int = 5000) -> Array:
	var economy: EconomyModule = EconomyModule.new(false, _definitions(site_money))
	var clock: SimClock = SimClock.new()
	var world: World = World.new(SimContext.new(clock, EventBus.new(clock), WorldRng.new(SEED), IdGenerator.new()))
	assert_true(world.register_module("economy", economy).ok)
	world.setup()
	world.post_setup()
	world.on_new_game(SEED)
	return [world, economy]


func _hire(economy: EconomyModule, npc_id: int, place_id: String = "") -> void:
	assert_true(economy.request_open_owner(npc_id, "npc", place_id).ok)


func _run_hours(world: World, hours: int) -> void:
	for _minute: int in hours * MINUTES_PER_HOUR:
		world.context.clock.advance_step()
		world.tick(1)
		world.context.events.dispatch()


func _offers(world: World) -> Array[ContractOffered]:
	var offers: Array[ContractOffered] = []
	world.context.events.subscribe("ContractOffered", func(event: SimEvent) -> void: offers.append(event))
	return offers


func _vacancy_of(economy: EconomyModule, workplace_id: int, state_name: String = "open") -> EconomyReplies.ContractQuery:
	for row: EconomyReplies.ContractQuery in economy.peek_contracts(state_name).contracts:
		if row.kind == "vacancy" and row.workplace_id == workplace_id:
			return row
	return null


func test_a_workplace_with_missing_staff_offers_one_vacancy_that_shows_the_names_of_the_workplace() -> void:
	var parts: Array = _world()
	var world: World = parts[0]
	var economy: EconomyModule = parts[1]
	var offers: Array[ContractOffered] = _offers(world)
	_hire(economy, NPC_BASE, PLACE_SITE)
	_run_hours(world, 1)
	assert_eq(offers.size(), 2, "O local de produção (1 de 4) e o posto (0 de 1): uma vaga cada.")
	assert_eq([offers[0].kind, offers[0].issuer_id, offers[0].reward, offers[0].deadline, offers[1].issuer_id], ["vacancy", SITE, 0, 0, POST], "Em ordem: local de produção, depois posto; emissor é o local.")
	var site_vacancy: EconomyReplies.ContractQuery = _vacancy_of(economy, SITE)
	assert_not_null(site_vacancy)
	assert_eq([site_vacancy.contract_id, site_vacancy.issuer_id, site_vacancy.reward, site_vacancy.deadline, site_vacancy.state, site_vacancy.acceptor_id], [offers[0].contract_id, SITE, 0, 0, "open", IdGenerator.NO_ID])
	assert_eq([site_vacancy.workplace_id, site_vacancy.place_id, site_vacancy.settlement_id, site_vacancy.occupation_id, site_vacancy.wage_per_hour, site_vacancy.workers_wanted, site_vacancy.workers_assigned], [SITE, PLACE_SITE, SETTLEMENT_A, "artisan", SITE_WAGE, SITE_WANTED, 1])
	var post_vacancy: EconomyReplies.ContractQuery = _vacancy_of(economy, POST)
	assert_eq([post_vacancy.place_id, post_vacancy.occupation_id, post_vacancy.wage_per_hour, post_vacancy.workers_wanted, post_vacancy.workers_assigned], [PLACE_POST, "guard", POST_WAGE, 1, 0])
	assert_eq(economy.peek_balance(site_vacancy.contract_id).result.ok, false, "A vaga não tem custódia: nenhuma conta foi aberta.")
	_run_hours(world, 3)
	assert_eq(offers.size(), 2, "Uma vaga aberta por local: as horas seguintes não postam outra.")
	assert_true(economy.peek_conservation().ok)
	assert_eq(economy.validate(), [] as Array[String])
	world.teardown()


func test_a_full_workplace_offers_nothing_and_a_death_opens_a_vacancy_in_the_next_hour() -> void:
	var parts: Array = _world()
	var world: World = parts[0]
	var economy: EconomyModule = parts[1]
	for index: int in SITE_WANTED:
		_hire(economy, NPC_BASE + index, PLACE_SITE)
	_hire(economy, NPC_BASE + 10, PLACE_POST)
	var offers: Array[ContractOffered] = _offers(world)
	_run_hours(world, 2)
	assert_eq(offers.size(), 0, "Equipes completas: nenhuma vaga.")
	world.context.events.publish(NpcDied.new(NPC_BASE + 1, "test", 0))
	world.context.events.dispatch()
	assert_eq(offers.size(), 0, "A conferência é por hora: a vaga ainda não nasceu.")
	_run_hours(world, 1)
	assert_eq([offers.size(), offers[0].issuer_id], [1, SITE], "Depois da morte falta um e a vaga nasce na hora seguinte.")
	world.teardown()


func test_accepting_assigns_the_npc_completes_the_vacancy_and_a_still_missing_slot_gets_a_new_one() -> void:
	var parts: Array = _world()
	var world: World = parts[0]
	var economy: EconomyModule = parts[1]
	_hire(economy, NPC_BASE, PLACE_SITE)
	_hire(economy, NPC_BASE + 1)
	var done: Array[ContractCompleted] = []
	world.context.events.subscribe("ContractCompleted", func(event: SimEvent) -> void: done.append(event))
	_run_hours(world, 1)
	var vacancy: EconomyReplies.ContractQuery = _vacancy_of(economy, SITE)
	assert_true(economy.request_accept_contract(vacancy.contract_id, NPC_BASE + 1).ok)
	world.context.events.dispatch()
	var after: EconomyReplies.ContractQuery = economy.peek_contract(vacancy.contract_id)
	assert_eq([after.state, after.acceptor_id], ["completed", NPC_BASE + 1])
	assert_eq(economy.peek_site(SITE).worker_ids, [NPC_BASE, NPC_BASE + 1] as Array[int], "O NPC entrou na equipe.")
	assert_eq(done.size(), 1)
	assert_eq([done[0].contract_id, done[0].acceptor_id, done[0].reward], [vacancy.contract_id, NPC_BASE + 1, 0])
	assert_eq(economy.request_accept_contract(vacancy.contract_id, NPC_BASE + 1).code, EconomyCodes.CONTRACT_NOT_OPEN, "Vaga ocupada não se aceita de novo.")
	_run_hours(world, 1)
	var next: EconomyReplies.ContractQuery = _vacancy_of(economy, SITE)
	assert_not_null(next, "Ainda faltam 2 de 4: nasce outra vaga.")
	assert_ne(next.contract_id, vacancy.contract_id)
	assert_eq(next.workers_assigned, 2)
	world.teardown()


func test_changing_jobs_leaves_the_old_workplace_which_then_offers_a_vacancy() -> void:
	var parts: Array = _world()
	var world: World = parts[0]
	var economy: EconomyModule = parts[1]
	_hire(economy, NPC_BASE, PLACE_POST)
	_run_hours(world, 1)
	var vacancy: EconomyReplies.ContractQuery = _vacancy_of(economy, SITE)
	assert_eq(economy.peek_post(POST).worker_ids, [NPC_BASE] as Array[int])
	assert_true(economy.request_accept_contract(vacancy.contract_id, NPC_BASE).ok)
	assert_eq([economy.peek_site(SITE).worker_ids, economy.peek_post(POST).worker_ids], [[NPC_BASE] as Array[int], [] as Array[int]], "Só um emprego: saiu do posto e entrou no local de produção.")
	assert_null(_vacancy_of(economy, POST), "A vaga do posto nasce na conferência da hora.")
	_run_hours(world, 1)
	assert_not_null(_vacancy_of(economy, POST), "Agora o posto está sem guarda: vaga nova.")
	world.teardown()


func test_a_vacancy_that_nobody_needs_any_more_fails_in_silence_and_cannot_be_accepted() -> void:
	var parts: Array = _world()
	var world: World = parts[0]
	var economy: EconomyModule = parts[1]
	_run_hours(world, 1)
	var vacancy: EconomyReplies.ContractQuery = _vacancy_of(economy, POST)
	_hire(economy, NPC_BASE, PLACE_POST)
	var late: Result = economy.request_accept_contract(vacancy.contract_id, NPC_BASE + 1)
	assert_eq(late.code, EconomyCodes.UNKNOWN_OWNER, "Primeiro o aceitante precisa existir.")
	_hire(economy, NPC_BASE + 1)
	var refused: Result = economy.request_accept_contract(vacancy.contract_id, NPC_BASE + 1)
	assert_eq(refused.code, EconomyCodes.CONTRACT_IMPOSSIBLE, "O posto já tem o guarda (outro NPC preencheu): " + refused.message)
	assert_eq(economy.peek_contract(vacancy.contract_id).state, "failed", "A vaga falhou.")
	assert_eq(economy.request_accept_contract(vacancy.contract_id, NPC_BASE + 1).code, EconomyCodes.CONTRACT_NOT_OPEN)
	world.teardown()


func test_the_refusals_of_accepting_a_vacancy_change_nothing() -> void:
	var parts: Array = _world()
	var world: World = parts[0]
	var economy: EconomyModule = parts[1]
	_hire(economy, NPC_BASE, PLACE_SITE)
	_hire(economy, NPC_BASE + 1)
	_run_hours(world, 1)
	var vacancy: EconomyReplies.ContractQuery = _vacancy_of(economy, SITE)
	var market_id: int = economy.peek_market_of(SETTLEMENT_A).market_id
	assert_eq(economy.request_accept_contract(vacancy.contract_id, 999).code, EconomyCodes.UNKNOWN_OWNER)
	assert_eq(economy.request_accept_contract(vacancy.contract_id, market_id).code, EconomyCodes.CONTRACT_IMPOSSIBLE, "Só NPC aceita vaga.")
	assert_eq(economy.request_accept_contract(vacancy.contract_id, NPC_BASE).code, EconomyCodes.CONTRACT_IMPOSSIBLE, "Já trabalha ali.")
	world.context.events.publish(NpcDied.new(NPC_BASE + 1, "test", 0))
	world.context.events.dispatch()
	assert_eq(economy.request_accept_contract(vacancy.contract_id, NPC_BASE + 1).code, EconomyCodes.OWNER_CLOSED, "Morto.")
	assert_eq([economy.peek_contract(vacancy.contract_id).state, economy.peek_site(SITE).worker_ids], ["open", [NPC_BASE] as Array[int]], "A vaga segue aberta e a equipe não mudou.")
	world.teardown()


func test_a_workplace_without_money_for_the_payroll_stops_but_keeps_its_staff_and_offers_no_vacancy() -> void:
	var parts: Array = _world(5)
	var world: World = parts[0]
	var economy: EconomyModule = parts[1]
	for index: int in SITE_WANTED:
		_hire(economy, NPC_BASE + index, PLACE_SITE)
	var offers: Array[ContractOffered] = _offers(world)
	_run_hours(world, 4)
	var site: EconomyReplies.SiteQuery = economy.peek_site(SITE)
	assert_eq([site.running, site.workers_assigned], [false, SITE_WANTED], "Parado por falta de dinheiro, sem demitir ninguém.")
	assert_eq(economy.peek_contracts("open").contracts.size(), 1, "Só a vaga do posto sem guarda; o local parado não gera vaga porque ninguém saiu.")
	assert_eq(offers.size(), 1)
	world.teardown()


func test_the_vacancy_state_goes_to_the_save_and_comes_back() -> void:
	var parts: Array = _world()
	var world: World = parts[0]
	var economy: EconomyModule = parts[1]
	_hire(economy, NPC_BASE, PLACE_SITE)
	_run_hours(world, 1)
	var vacancy_id: int = _vacancy_of(economy, SITE).contract_id
	var saved: Dictionary = economy.serialize()
	var parsed: Variant = JSON.parse_string(JSON.stringify(saved))
	assert_eq(typeof(parsed), TYPE_DICTIONARY)
	var data: Dictionary = parsed
	var copy: EconomyModule = EconomyModule.new(false, _definitions())
	var clock: SimClock = SimClock.new()
	var other_world: World = World.new(SimContext.new(clock, EventBus.new(clock), WorldRng.new(SEED), IdGenerator.new()))
	assert_true(other_world.register_module("economy", copy).ok)
	other_world.setup()
	assert_true(copy.on_load(data).ok)
	assert_eq(JSON.stringify(copy.serialize(), "", true, true), JSON.stringify(saved, "", true, true), "Ida e volta sem mudar nada.")
	assert_eq([copy.peek_contract(vacancy_id).state, copy.peek_contract(vacancy_id).workplace_id, copy.validate()], ["open", SITE, [] as Array[String]])
	var broken: Variant = JSON.parse_string(JSON.stringify(saved))
	var broken_block: Dictionary = broken
	broken_block["contracts"]["contracts"][str(vacancy_id)]["reward"] = 5
	assert_false(copy.on_load(broken_block).ok, "Vaga com recompensa é recusada no save.")
	world.teardown()
	other_world.teardown()


func test_the_hourly_check_fails_an_open_vacancy_when_someone_else_filled_the_slot() -> void:
	var parts: Array = _world()
	var world: World = parts[0]
	var economy: EconomyModule = parts[1]
	_run_hours(world, 1)
	var vacancy_id: int = _vacancy_of(economy, POST).contract_id
	_hire(economy, NPC_BASE, PLACE_POST)
	assert_eq(economy.peek_contract(vacancy_id).state, "open", "Antes da conferência da hora a vaga ainda consta aberta.")
	_run_hours(world, 1)
	assert_eq(economy.peek_contract(vacancy_id).state, "failed", "A conferência da hora a fez falhar: o posto tem o guarda.")
	assert_null(_vacancy_of(economy, POST), "E não nasce outra, porque não falta ninguém.")
	world.teardown()
