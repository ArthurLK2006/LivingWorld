extends GutTest
## LW-095 (parte d): o `npc` ouve o salário (docs/modules/npc.md, 14.4; DEC-152). A cada `WagesPaid` (um por local de trabalho e por hora) a necessidade `income` dos NPCs que trabalham ali cai `amount_each` pontos (a constante [HIP]
## `WageIncome.RELIEF_PER_COIN` é 1), em ordem de ID, limitada a 0; quem não trabalha ali, quem o `npc` não conhece e quem morreu não é tocado; sem folha não há evento e nada muda. Economia REAL (data/economy) com um local de `bake_bread`
## em `a_work_01` (2 de salário) e um posto de `guard` em `a_work_05` (3 de salário), definições montadas à mão; NPCs reais pela porta do `npc`, com necessidades montadas à mão (`income` sem subida própria, para a conta ficar exata).

const SEED: int = 71
const MINUTES_PER_HOUR: int = 60
const SETTLEMENT_A: String = "test_settlement_a"
const PLACE_SITE: String = "a_work_01"
const PLACE_POST: String = "a_work_05"
const SITE_WAGE: int = 2
const POST_WAGE: int = 3
const START_INCOME: int = 80
const NEED_IDS: Array[String] = ["hunger", "rest", "safety", "income", "social"]
const INCOME: int = 3


func _need_defs(start_income: int = START_INCOME, income_rate: int = 0) -> Array[NeedDef]:
	var defs: Array[NeedDef] = []
	for position: int in NEED_IDS.size():
		defs.append(NeedDef.new(NEED_IDS[position], position, start_income if position == INCOME else 0, income_rate if position == INCOME else 0, 40, 65, 90))
	return defs


func _definitions(site_money: int) -> EconomyDefinitions:
	var setup: EconomySetup = EconomySetup.from_dir(EconomySetup.DEFAULT_DIR)
	assert_true(setup.result.ok, setup.result.message)
	var definitions: EconomyDefinitions = setup.definitions
	var sites: Array[SiteDef] = [SiteDef.new("site_bread", SETTLEMENT_A, PLACE_SITE, "bake_bread", 4)]
	definitions.production_sites = sites
	var posts: Array[PostDef] = [PostDef.new("post_a_guard", SETTLEMENT_A, PLACE_POST, "guard", 8, POST_WAGE)]
	definitions.service_posts = posts
	for kind: OwnerKindDef in definitions.kinds:
		if kind.id == ProductionBook.KIND_SITE:
			kind.initial_balance = site_money
	return definitions


## Mundo com a economia e o `npc` registrados nesta ordem. Devolve [world, economy, npc].
func _world(site_money: int = 5000, start_income: int = START_INCOME, income_rate: int = 0) -> Array:
	var economy: EconomyModule = EconomyModule.new(false, _definitions(site_money))
	var npc: NpcModule = NpcModule.new(_need_defs(start_income, income_rate), null, null, economy)
	var clock: SimClock = SimClock.new()
	var world: World = World.new(SimContext.new(clock, EventBus.new(clock), WorldRng.new(SEED), IdGenerator.new()))
	assert_true(world.register_module("economy", economy).ok)
	assert_true(world.register_module("npc", npc).ok)
	world.setup()
	world.post_setup()
	world.on_new_game(SEED)
	return [world, economy, npc]


func _hire(npc: NpcModule, work_place_id: String) -> int:
	var spec: NpcSpec = NpcSpec.new()
	spec.name_key = "npc.name.villager"
	spec.name_number = 1
	spec.work_place_id = work_place_id
	var created: NpcModule.CreateResult = npc.request_create_npc(spec)
	assert_true(created.result.ok, created.result.message)
	return created.npc_id


func _run_hours(world: World, hours: int) -> void:
	for _minute: int in hours * MINUTES_PER_HOUR:
		world.context.clock.advance_step()
		world.tick(1)
		world.context.events.dispatch()


func _income(npc: NpcModule, npc_id: int) -> int:
	return npc.peek_npc(npc_id).need_values[INCOME]


func test_each_paid_hour_lowers_the_income_of_the_workers_by_the_wage_of_their_workplace() -> void:
	var parts: Array = _world()
	var world: World = parts[0]
	var npc: NpcModule = parts[2]
	var bakers: Array[int] = [_hire(npc, PLACE_SITE), _hire(npc, PLACE_SITE), _hire(npc, PLACE_SITE)]
	var guard: int = _hire(npc, PLACE_POST)
	var idle: int = _hire(npc, "")
	var elsewhere: int = _hire(npc, "a_work_03")
	_run_hours(world, 3)
	for baker: int in bakers:
		assert_eq(_income(npc, baker), START_INCOME - 3 * SITE_WAGE, "O padeiro recebeu 2 por hora, 3 horas: `income` cai 6.")
	assert_eq(_income(npc, guard), START_INCOME - 3 * POST_WAGE, "O guarda é pago pelo mercado, 3 por hora: cai 9.")
	assert_eq([_income(npc, idle), _income(npc, elsewhere)], [START_INCOME, START_INCOME], "Sem local de trabalho com folha, nada muda.")
	world.teardown()


func test_the_relief_is_applied_on_the_value_brought_up_to_the_minute_of_the_payment() -> void:
	var parts: Array = _world(5000, START_INCOME, 2)
	var world: World = parts[0]
	var npc: NpcModule = parts[2]
	var baker_ids: Array[int] = [_hire(npc, PLACE_SITE), _hire(npc, PLACE_SITE), _hire(npc, PLACE_SITE)]
	_run_hours(world, 1)
	assert_eq(_income(npc, baker_ids[0]), START_INCOME, "A necessidade subiu 2 na hora e o salário de 2 a devolveu: 80 + 2 - 2.")
	_run_hours(world, 2)
	assert_eq(_income(npc, baker_ids[0]), START_INCOME, "Pago a cada hora, a renda fica onde estava.")
	world.teardown()


func test_without_a_payroll_there_is_no_event_and_the_income_stays() -> void:
	var parts: Array = _world(5)
	var world: World = parts[0]
	var npc: NpcModule = parts[2]
	var bakers: Array[int] = [_hire(npc, PLACE_SITE), _hire(npc, PLACE_SITE), _hire(npc, PLACE_SITE)]
	_run_hours(world, 2)
	for baker: int in bakers:
		assert_eq(_income(npc, baker), START_INCOME, "O local com 5 de saldo não paga a folha de 6: ninguém recebe e a renda não alivia.")
	world.teardown()


func test_the_relief_stops_at_zero() -> void:
	var parts: Array = _world(5000, 1)
	var world: World = parts[0]
	var npc: NpcModule = parts[2]
	var guard: int = _hire(npc, PLACE_POST)
	_run_hours(world, 2)
	assert_eq(_income(npc, guard), 0, "1 de renda com alívio de 3 por hora: para em 0, nunca negativo.")
	world.teardown()


func test_the_wage_income_ignores_the_dead_the_unknown_and_other_events() -> void:
	var parts: Array = _world()
	var world: World = parts[0]
	var economy: EconomyModule = parts[1]
	var site_id: int = economy.peek_site_at(PLACE_SITE).workplace_id
	var alive: NpcState = NpcState.new(100)
	var dead: NpcState = NpcState.new(101)
	var defs: Array[NeedDef] = _need_defs()
	for state: NpcState in [alive, dead]:
		state.need_values = PackedInt64Array([0, 0, 0, START_INCOME, 0])
		state.need_remainders = PackedInt64Array([0, 0, 0, 0, 0])
		assert_true(economy.request_open_owner(state.npc_id, "npc", PLACE_SITE).ok)
	dead.is_alive = false
	var npcs: Dictionary[int, NpcState] = {100: alive, 101: dead}
	var income: WageIncome = WageIncome.new(npcs, defs, economy)
	assert_eq(economy.peek_site(site_id).worker_ids, [100, 101] as Array[int], "A economia lista os dois, o `npc` conhece os dois.")
	income.on_wages_paid(WagesPaid.new(site_id, SITE_WAGE), 0)
	assert_eq([alive.need_values[INCOME], dead.need_values[INCOME]], [START_INCOME - SITE_WAGE, START_INCOME], "O morto não recebe o alívio.")
	income.on_wages_paid(WagesPaid.new(999, SITE_WAGE), 0)
	income.on_wages_paid(AlarmRaised.new(0, 0, 1), 0)
	assert_eq(alive.need_values[INCOME], START_INCOME - SITE_WAGE, "Local que não existe e evento de outro tipo: nada.")
	var stranger: Dictionary[int, NpcState] = {}
	WageIncome.new(stranger, defs, economy).on_wages_paid(WagesPaid.new(site_id, SITE_WAGE), 0)
	assert_eq(alive.need_values[INCOME], START_INCOME - SITE_WAGE, "NPC que esta instância do `npc` não conhece não é tocado.")
	WageIncome.new(npcs, defs, null).on_wages_paid(WagesPaid.new(site_id, SITE_WAGE), 0)
	assert_eq(alive.need_values[INCOME], START_INCOME - SITE_WAGE, "Sem economia, nada.")
	world.teardown()


func test_a_module_without_an_economy_does_not_listen_to_wages() -> void:
	var npc: NpcModule = NpcModule.new(_need_defs())
	var clock: SimClock = SimClock.new()
	var world: World = World.new(SimContext.new(clock, EventBus.new(clock), WorldRng.new(SEED), IdGenerator.new()))
	assert_true(world.register_module("npc", npc).ok)
	world.setup()
	world.post_setup()
	npc.on_wages_paid(WagesPaid.new(3, 2))
	world.context.events.publish(WagesPaid.new(3, 2))
	world.context.events.dispatch()
	assert_true(true, "Sem economia o evento passa sem efeito e sem erro.")
	world.teardown()
