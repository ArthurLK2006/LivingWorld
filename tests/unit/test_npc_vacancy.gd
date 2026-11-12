extends GutTest
## LW-096a: o NPC aceita vaga pela utilidade, com histerese (docs/modules/npc.md, 14.4; DEC-165 e DEC-169). Economia REAL com um local de `bake_bread` em `a_work_01` (salário 2 por hora, 2 vagas) e um posto de `guard` em `a_work_05` (salário
## `POST_WAGE`, 1 vaga), definições montadas à mão, e o `npc` real com lugares montados à mão (casas perto e longe) e o custo de distância dos parâmetros. O desempregado aceita a vaga se a utilidade é positiva; o empregado só TROCA se a utilidade da vaga
## passar da do emprego atual por mais que a histerese; sem laço de trocas; o emprego só termina por morte ou por aceitar outra vaga; o local sem dinheiro para a folha para e não demite; o melhor candidato (distância e ofício) aceita, empate pelo menor ID;
## o `work_place_id` do NPC e a lista de trabalhadores da economia coincidem; o mesmo mundo dá o mesmo resultado. A utilidade usa constantes [HIP] nomeadas em `NpcEmployment` (8 horas pagas, 2 caminhadas, bônus de ofício 10, histerese 20).

const SEED: int = 97
const MINUTES_PER_HOUR: int = 60
const SETTLEMENT_A: String = "test_settlement_a"
const SETTLEMENT_B: String = "test_settlement_b"
const SITE_PLACE: String = "a_work_01"
const POST_PLACE: String = "a_work_05"
const HOME_NEAR: String = "home_near"
const HOME_FAR: String = "home_far"
const HOME_B: String = "home_b"
const SITE: int = 3
const POST: int = 4
const SITE_WAGE: int = 2
const SITE_WANTED: int = 2
const NEED_IDS: Array[String] = ["hunger", "rest", "safety", "income", "social"]
## 1 ponto por 100 m de caminhada: 3 km de casa ao trabalho custam 30 por viagem, 60 por dia.
const DISTANCE_COST_PER_100M: int = 1


func _need_defs() -> Array[NeedDef]:
	var defs: Array[NeedDef] = []
	for position: int in NEED_IDS.size():
		defs.append(NeedDef.new(NEED_IDS[position], position, 0, 0, 40, 65, 90))
	return defs


func _places() -> SettlementService:
	var settlements: Array[Settlement] = [Settlement.new(SETTLEMENT_A, "settlement.a", Vector3(0.0, 0.0, 0.0)), Settlement.new(SETTLEMENT_B, "settlement.b", Vector3(5000.0, 0.0, 0.0))]
	var places: Array[Place] = [
		Place.new(HOME_NEAR, SETTLEMENT_A, Place.KIND_HOME, Vector3(100.0, 0.0, 0.0), 5),
		Place.new(HOME_FAR, SETTLEMENT_A, Place.KIND_HOME, Vector3(3100.0, 0.0, 0.0), 5),
		Place.new(HOME_B, SETTLEMENT_B, Place.KIND_HOME, Vector3(100.0, 0.0, 0.0), 5),
		Place.new(SITE_PLACE, SETTLEMENT_A, Place.KIND_WORK, Vector3(100.0, 0.0, 0.0), 12),
		Place.new(POST_PLACE, SETTLEMENT_A, Place.KIND_WORK, Vector3(100.0, 0.0, 0.0), 12),
	]
	return SettlementService.new(settlements, places)


func _definitions(post_wage: int, site_money: int) -> EconomyDefinitions:
	var setup: EconomySetup = EconomySetup.from_dir(EconomySetup.DEFAULT_DIR)
	assert_true(setup.result.ok, setup.result.message)
	var definitions: EconomyDefinitions = setup.definitions
	var sites: Array[SiteDef] = [SiteDef.new("site_bread", SETTLEMENT_A, SITE_PLACE, "bake_bread", SITE_WANTED)]
	definitions.production_sites = sites
	var posts: Array[PostDef] = [PostDef.new("post_a_guard", SETTLEMENT_A, POST_PLACE, "guard", 1, post_wage)]
	definitions.service_posts = posts
	for kind: OwnerKindDef in definitions.kinds:
		if kind.id == ProductionBook.KIND_SITE:
			kind.initial_balance = site_money
	return definitions


## Mundo com a economia e o `npc` (nesta ordem). Devolve [world, economy, npc].
func _world(post_wage: int = 3, site_money: int = 5000) -> Array:
	var economy: EconomyModule = EconomyModule.new(false, _definitions(post_wage, site_money))
	var npc_definitions: NpcModule.Definitions = NpcModule.Definitions.new()
	npc_definitions.params = NpcParams.new()
	npc_definitions.params.distance_cost_per_100m = DISTANCE_COST_PER_100M
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


func _spawn(npc: NpcModule, home_place_id: String, work_place_id: String = "", occupation_id: String = "", settlement_id: String = SETTLEMENT_A) -> int:
	var spec: NpcSpec = NpcSpec.new()
	spec.name_key = "npc.name.villager"
	spec.name_number = 1
	spec.settlement_id = settlement_id
	spec.home_place_id = home_place_id
	spec.work_place_id = work_place_id
	spec.occupation_id = occupation_id
	var created: NpcModule.CreateResult = npc.request_create_npc(spec)
	assert_true(created.result.ok, created.result.message)
	return created.npc_id


## O guarda que enche o posto (a vaga do posto existe desde a primeira hora; nos testes que não são sobre ela o posto começa completo).
func _fill_post(npc: NpcModule) -> int:
	return _spawn(npc, HOME_NEAR, POST_PLACE, "guard")


func _run_hours(world: World, hours: int) -> void:
	for _minute: int in hours * MINUTES_PER_HOUR:
		world.context.clock.advance_step()
		world.tick(1)
		world.context.events.dispatch()


func _work_place(npc: NpcModule, npc_id: int) -> String:
	return npc.peek_npc(npc_id).work_place_id


func _die(world: World, npc: NpcModule, npc_id: int) -> void:
	world.context.events.publish(NpcDied.new(npc_id, "test", 0))
	world.context.events.dispatch()
	assert_true(npc.request_remove_npc(npc_id).ok)


func test_an_unemployed_npc_takes_the_vacancy_a_death_opened_and_the_work_place_follows_in_the_same_pass() -> void:
	var parts: Array = _world()
	var world: World = parts[0]
	var economy: EconomyModule = parts[1]
	var npc: NpcModule = parts[2]
	_fill_post(npc)
	var first: int = _spawn(npc, HOME_NEAR, SITE_PLACE, "artisan")
	var second: int = _spawn(npc, HOME_NEAR, SITE_PLACE, "artisan")
	var jobless: int = _spawn(npc, HOME_NEAR, "", "artisan")
	_run_hours(world, 1)
	assert_eq(economy.peek_site(SITE).worker_ids, [first, second] as Array[int], "O local está completo e o desempregado não pegou a vaga que não existe.")
	assert_eq(_work_place(npc, jobless), "", "Ainda sem emprego.")
	_die(world, npc, second)
	_run_hours(world, 1)
	assert_eq(economy.peek_site(SITE).worker_ids, [first, jobless] as Array[int], "A morte abriu uma vaga e o desempregado a aceitou.")
	assert_eq(_work_place(npc, jobless), SITE_PLACE, "O `work_place_id` mudou na mesma passagem.")
	assert_eq(economy.validate(), [] as Array[String])
	world.teardown()


func test_an_employed_npc_does_not_switch_for_a_small_gain_but_switches_above_the_hysteresis() -> void:
	var small: Array = _world(4)
	var small_world: World = small[0]
	var small_economy: EconomyModule = small[1]
	var small_npc: NpcModule = small[2]
	var worker: int = _spawn(small_npc, HOME_NEAR, SITE_PLACE, "artisan")
	_spawn(small_npc, HOME_NEAR, SITE_PLACE, "artisan")
	_run_hours(small_world, 2)
	assert_eq(small_economy.peek_site(SITE).worker_ids.has(worker), true)
	assert_true(small_economy.peek_post(POST).worker_ids.is_empty(), "O posto fica com a vaga: pagar 4 contra 2 rende só 6 a mais por dia (32 contra 26), abaixo da histerese de 20.")
	assert_eq(_work_place(small_npc, worker), SITE_PLACE)
	small_world.teardown()
	var big: Array = _world(6)
	var big_world: World = big[0]
	var big_economy: EconomyModule = big[1]
	var big_npc: NpcModule = big[2]
	var big_worker: int = _spawn(big_npc, HOME_NEAR, SITE_PLACE, "artisan")
	_spawn(big_npc, HOME_NEAR, SITE_PLACE, "artisan")
	_run_hours(big_world, 2)
	assert_eq(big_economy.peek_post(POST).worker_ids, [big_worker] as Array[int], "6 contra 2 rende 22 a mais por dia (48 contra 26), acima da histerese de 20: troca.")
	assert_eq(_work_place(big_npc, big_worker), POST_PLACE)
	assert_false(big_economy.peek_site(SITE).worker_ids.has(big_worker), "Só um emprego: saiu do local de produção.")
	big_world.teardown()


func test_there_is_no_loop_of_switches_after_the_first_change() -> void:
	var parts: Array = _world(6)
	var world: World = parts[0]
	var economy: EconomyModule = parts[1]
	var npc: NpcModule = parts[2]
	var worker: int = _spawn(npc, HOME_NEAR, SITE_PLACE, "artisan")
	_spawn(npc, HOME_NEAR, SITE_PLACE, "artisan")
	_run_hours(world, 2)
	var settled: String = _work_place(npc, worker)
	assert_eq(settled, POST_PLACE)
	_run_hours(world, 48)
	assert_eq([_work_place(npc, worker), economy.peek_post(POST).worker_ids], [settled, [worker] as Array[int]], "A vaga que ele deixou no local de produção não o chama de volta: voltar perderia utilidade.")
	world.teardown()


func test_the_best_candidate_by_distance_and_trade_takes_the_vacancy_ties_go_to_the_lowest_id() -> void:
	var parts: Array = _world()
	var world: World = parts[0]
	var economy: EconomyModule = parts[1]
	var npc: NpcModule = parts[2]
	_fill_post(npc)
	_spawn(npc, HOME_NEAR, SITE_PLACE, "artisan")
	var far: int = _spawn(npc, HOME_FAR, "", "artisan")
	var near: int = _spawn(npc, HOME_NEAR, "", "artisan")
	_run_hours(world, 1)
	assert_eq(economy.peek_site(SITE).worker_ids.has(near), true, "A vaga do local de produção vai para o desempregado de casa perto: a caminhada de 3 km custa 60 por dia.")
	assert_eq(_work_place(npc, far), "", "O de casa longe segue sem emprego (a caminhada de 3 km custa 60 por dia e nada que sobra paga isso).")
	world.teardown()
	var tie: Array = _world()
	var tie_world: World = tie[0]
	var tie_economy: EconomyModule = tie[1]
	var tie_npc: NpcModule = tie[2]
	_fill_post(tie_npc)
	_spawn(tie_npc, HOME_NEAR, SITE_PLACE, "artisan")
	var lower: int = _spawn(tie_npc, HOME_NEAR, "", "artisan")
	var higher: int = _spawn(tie_npc, HOME_NEAR, "", "artisan")
	_run_hours(tie_world, 1)
	assert_eq(tie_economy.peek_site(SITE).worker_ids.has(lower), true, "Empate: o menor ID.")
	assert_eq(_work_place(tie_npc, higher), "", "O de ID maior fica de fora.")
	tie_world.teardown()
	var trade: Array = _world()
	var trade_world: World = trade[0]
	var trade_economy: EconomyModule = trade[1]
	var trade_npc: NpcModule = trade[2]
	_fill_post(trade_npc)
	_spawn(trade_npc, HOME_NEAR, SITE_PLACE, "artisan")
	_spawn(trade_npc, HOME_NEAR, "", "farmer")
	var artisan: int = _spawn(trade_npc, HOME_NEAR, "", "artisan")
	_run_hours(trade_world, 1)
	assert_eq(trade_economy.peek_site(SITE).worker_ids.has(artisan), true, "O ofício esperado da vaga (`artisan`) dá o bônus: vence o de ID menor que é lavrador.")
	trade_world.teardown()


func test_npcs_of_another_settlement_the_dead_and_the_ones_in_the_same_workplace_are_left_out() -> void:
	var parts: Array = _world()
	var world: World = parts[0]
	var economy: EconomyModule = parts[1]
	var npc: NpcModule = parts[2]
	var inside: int = _spawn(npc, HOME_NEAR, SITE_PLACE, "artisan")
	var elsewhere: int = _spawn(npc, HOME_B, "", "artisan", SETTLEMENT_B)
	_run_hours(world, 1)
	assert_eq(_work_place(npc, elsewhere), "", "Outro povoado: não aceita, mesmo com a caminhada de custo zero (a casa dele está na mesma posição do trabalho).")
	assert_eq(economy.peek_site(SITE).worker_ids, [inside] as Array[int], "Quem já trabalha ali não aceita a própria vaga (só há uma na lista).")
	world.teardown()


func test_the_employment_only_ends_by_death_a_site_without_money_keeps_its_staff() -> void:
	var parts: Array = _world(3, 5)
	var world: World = parts[0]
	var economy: EconomyModule = parts[1]
	var npc: NpcModule = parts[2]
	var first: int = _spawn(npc, HOME_NEAR, SITE_PLACE, "artisan")
	var second: int = _spawn(npc, HOME_NEAR, SITE_PLACE, "artisan")
	_run_hours(world, 12)
	var site: EconomyReplies.SiteQuery = economy.peek_site(SITE)
	assert_eq([site.running, site.worker_ids, _work_place(npc, first), _work_place(npc, second)], [false, [first, second] as Array[int], SITE_PLACE, SITE_PLACE], "Sem dinheiro para a folha o local para e NÃO demite.")
	world.teardown()


func test_the_work_place_of_each_npc_and_the_economy_staff_lists_agree_and_the_run_is_deterministic() -> void:
	var snapshots: Array[String] = []
	for _run: int in 2:
		var parts: Array = _world(6)
		var world: World = parts[0]
		var economy: EconomyModule = parts[1]
		var npc: NpcModule = parts[2]
		var ids: Array[int] = []
		for index: int in 5:
			ids.append(_spawn(npc, HOME_NEAR if index % 2 == 0 else HOME_FAR, SITE_PLACE if index < 2 else "", "artisan"))
		_die(world, npc, ids[0])
		_run_hours(world, 6)
		var report: Array = []
		for npc_id: int in npc.peek_npc_ids():
			var place: String = _work_place(npc, npc_id)
			var listed: bool = economy.peek_site(SITE).worker_ids.has(npc_id) or economy.peek_post(POST).worker_ids.has(npc_id)
			if listed:
				var listed_at_site: bool = economy.peek_site(SITE).worker_ids.has(npc_id)
				assert_eq(place, SITE_PLACE if listed_at_site else POST_PLACE, "O NPC %d está listado onde o `work_place_id` dele diz." % npc_id)
			report.append([npc_id, place, listed])
		snapshots.append(JSON.stringify([report, economy.peek_site(SITE).worker_ids, economy.peek_post(POST).worker_ids]))
		world.teardown()
	assert_eq(snapshots[0], snapshots[1], "O mesmo mundo dá o mesmo resultado.")


func test_a_module_without_an_economy_ignores_vacancies() -> void:
	var npc: NpcModule = NpcModule.new(_need_defs())
	var clock: SimClock = SimClock.new()
	var world: World = World.new(SimContext.new(clock, EventBus.new(clock), WorldRng.new(SEED), IdGenerator.new()))
	assert_true(world.register_module("npc", npc).ok)
	world.setup()
	world.post_setup()
	npc.on_contract_offered(ContractOffered.new(9, "vacancy", 3, 0, 0))
	world.context.events.publish(ContractOffered.new(9, "vacancy", 3, 0, 0))
	world.context.events.dispatch()
	assert_true(true, "Sem economia o evento passa sem efeito e sem erro.")
	world.teardown()


func test_an_unemployed_npc_takes_the_vacancy_of_the_post_at_the_first_hour() -> void:
	var parts: Array = _world()
	var world: World = parts[0]
	var economy: EconomyModule = parts[1]
	var npc: NpcModule = parts[2]
	_spawn(npc, HOME_NEAR, SITE_PLACE, "artisan")
	_spawn(npc, HOME_NEAR, SITE_PLACE, "artisan")
	var guard: int = _spawn(npc, HOME_NEAR, "", "guard")
	_run_hours(world, 1)
	assert_eq([economy.peek_post(POST).worker_ids, _work_place(npc, guard)], [[guard] as Array[int], POST_PLACE], "O posto sem guarda oferece vaga e o desempregado de ofício `guard` a aceita.")
	world.teardown()


func test_a_better_but_still_negative_job_does_not_move_a_far_employed_npc() -> void:
	var parts: Array = _world(6)
	var world: World = parts[0]
	var economy: EconomyModule = parts[1]
	var npc: NpcModule = parts[2]
	var far: int = _spawn(npc, HOME_FAR, SITE_PLACE, "artisan")
	_spawn(npc, HOME_NEAR, SITE_PLACE, "artisan")
	_run_hours(world, 2)
	assert_eq(economy.peek_site(SITE).worker_ids.has(far), true, "Casa a 3 km: o emprego atual vale 16 + 10 - 60 = -34; o posto vale 48 - 60 = -12 (22 a mais, acima da histerese) mas segue negativo.")
	assert_eq(_work_place(npc, far), SITE_PLACE)
	world.teardown()


func test_the_dead_in_the_npc_table_never_win_the_vacancy() -> void:
	var parts: Array = _world()
	var world: World = parts[0]
	var economy: EconomyModule = parts[1]
	var states: Dictionary[int, NpcState] = {}
	for npc_id: int in [50, 51]:
		var state: NpcState = NpcState.new(npc_id)
		state.settlement_id = SETTLEMENT_A
		state.occupation_id = "artisan"
		states[npc_id] = state
		assert_true(economy.request_open_owner(npc_id, "npc").ok)
	states[50].is_alive = false
	_run_hours(world, 1)
	var site_vacancy: int = 0
	for row: EconomyReplies.ContractQuery in economy.peek_contracts("open").contracts:
		if row.workplace_id == SITE:
			site_vacancy = row.contract_id
	var employment: NpcEmployment = NpcEmployment.new(states, economy, null, null)
	employment.consider(site_vacancy)
	assert_eq([states[51].work_place_id, states[50].work_place_id, economy.peek_site(SITE).worker_ids], [SITE_PLACE, "", [51] as Array[int]], "O morto tem o menor ID e não é escolhido: o vivo pega a vaga.")
	world.teardown()
