extends GutTest
## LW-093 (parte 7): o pensador escolhe `buy` quando a fome está urgente, o NPC tem dinheiro e não há comida à mão (docs/modules/npc.md, 14.3 e 14.6). Economia REAL (data/economy, mercado do povoado `test_settlement_a`) e mundo de teste montado à mão
## (casa, trabalho e mercado; catálogo `eat`, `buy`, `wait`; sem comida no estoque provisório): o faminto com dinheiro anda até o mercado, compra, volta para casa e come do inventário; sem dinheiro nunca começa `buy` e segue a rotina; o preço
## pesa no valor da compra e a compra que não compensa nunca é escolhida. Os números do alívio vêm dos dados reais da economia (grão 30 por unidade, o melhor por moeda).

const SEED: int = 83
const SETTLEMENT: String = "test_settlement_a"
const HOME: String = "home_a1"
const WORK: String = "work_a1"
const MARKET_PLACE: String = "market_a1"
const NEED_IDS: Array[String] = ["hunger", "rest", "safety", "income", "social"]
const TRAIT_IDS: Array[String] = ["caution", "sociability", "ambition", "loyalty"]
const HUNGER: int = 0
const REST: int = 1
const WALK_SPEED_CM_PER_MIN: int = 8400
const HOME_X_CM: int = 8400
const MARKET_X_CM: int = 12000
## Casa a 5 km do mercado: comer lá custa uns 100 pontos de distância.
const FAR_HOME_X_CM: int = 500000
const THINK_INTERVAL: int = 10
const START_HUNGER: int = 95
const INITIAL_MONEY: int = 60


## Estoque provisório de teste: com ou sem comida no assentamento.
class StubFood:
	extends ActionConditionProvider

	var food: bool = false

	func has_food(_settlement_id: String) -> bool:
		return food


## O cenário de um teste: o que muda de um para outro (o resto é igual).
class Scenario:
	extends RefCounted

	var price_percent: int = 100
	var start_hunger: int = START_HUNGER
	var start_rest: int = 0
	var home_x_cm: int = HOME_X_CM
	var starts_at_market: bool = false
	var settlement_has_food: bool = false


func _need_defs(scenario: Scenario) -> Array[NeedDef]:
	var defs: Array[NeedDef] = []
	for position: int in NEED_IDS.size():
		var start: int = 0
		if position == HUNGER:
			start = scenario.start_hunger
		elif position == REST:
			start = scenario.start_rest
		defs.append(NeedDef.new(NEED_IDS[position], position, start, 0, 40, 65, 90))
	return defs


func _params(price_percent: int) -> NpcParams:
	var params: NpcParams = NpcParams.new()
	params.urgency_weight_attention = 1
	params.urgency_weight_urgent = 3
	params.urgency_weight_critical = 6
	params.time_cost_per_hour = 2
	params.distance_cost_per_100m = 2
	params.risk_cost_percent = 100
	params.inertia_bonus = 25
	params.routine_bonus = 40
	params.think_interval_min = THINK_INTERVAL
	params.max_thinks_per_step = 20
	params.decision_top_k = 3
	params.decision_margin = 15
	params.buy_units = 2
	params.buy_price_percent = price_percent
	return params


func _catalog() -> Array[ActionDef]:
	var eat: ActionDef = ActionDef.new("eat", 20, "home", 0, true)
	eat.effects.append(ActionDef.ActionEffect.new("hunger", -60))
	eat.conditions.append(ActionDef.ActionCondition.new(ActionDef.CONDITION_HAS_FOOD, "", ActionDef.ABSENT, ActionDef.ABSENT))
	var work: ActionDef = ActionDef.new("work", 240, "work", 5, true)
	work.effects.append(ActionDef.ActionEffect.new("rest", 5))
	return [eat, work, ActionDef.new("buy", 10, "market", 0, true), ActionDef.new("wait", 10, "", 0, true), ActionDef.new(ActionRunner.GO_TO_PLACE_ID, 0, "", 0, true)]


func _definitions(scenario: Scenario) -> NpcModule.Definitions:
	var definitions: NpcModule.Definitions = NpcModule.Definitions.new()
	definitions.actions = _catalog()
	var traits: Array[TraitLoader.TraitDef] = []
	for position: int in TRAIT_IDS.size():
		traits.append(TraitLoader.TraitDef.new(TRAIT_IDS[position], position))
	definitions.traits = traits
	definitions.params = _params(scenario.price_percent)
	definitions.walk_speed_cm_per_min = WALK_SPEED_CM_PER_MIN
	var settlements: Array[Settlement] = [Settlement.new(SETTLEMENT, "settlement.a", Vector3(0.0, 0.0, 0.0))]
	var places: Array[Place] = [
		Place.new(HOME, SETTLEMENT, Place.KIND_HOME, Vector3(scenario.home_x_cm / 100.0, 0.0, 0.0), 5),
		Place.new(WORK, SETTLEMENT, Place.KIND_WORK, Vector3(184.0, 0.0, 0.0), 5),
		Place.new(MARKET_PLACE, SETTLEMENT, Place.KIND_MARKET, Vector3(MARKET_X_CM / 100.0, 0.0, 0.0), 5),
	]
	definitions.places = SettlementService.new(settlements, places)
	var stock: StubFood = StubFood.new()
	stock.food = scenario.settlement_has_food
	definitions.food = stock
	return definitions


func _routine() -> RoutineTable:
	var occupations: Array[RoutineTable.OccupationDef] = [RoutineTable.OccupationDef.new("tester", "work")]
	var blocks: Array[RoutineTable.RoutineBlock] = [RoutineTable.RoutineBlock.new("t1", "tester", 0, 24, "work")]
	return RoutineTable.new(occupations, blocks)


## Mundo com a economia real e um NPC do ofício "tester" (em casa, ou no mercado se o cenário mandar).
func _setup(scenario: Scenario = Scenario.new()) -> Array:
	var setup: EconomySetup = EconomySetup.from_dir(EconomySetup.DEFAULT_DIR)
	assert_true(setup.result.ok, setup.result.message)
	var economy: EconomyModule = EconomyModule.new(false, setup.definitions)
	var module: NpcModule = NpcModule.new(_need_defs(scenario), _routine(), _definitions(scenario), economy)
	var clock: SimClock = SimClock.new()
	var world: World = World.new(SimContext.new(clock, EventBus.new(clock), WorldRng.new(SEED), IdGenerator.new()))
	assert_true(world.register_module("economy", economy).ok)
	assert_true(world.register_module("npc", module).ok)
	world.setup()
	world.post_setup()
	world.on_new_game(SEED)
	var spec: NpcSpec = NpcSpec.new()
	spec.name_key = "npc.name.villager"
	spec.occupation_id = "tester"
	spec.settlement_id = SETTLEMENT
	spec.place_id = MARKET_PLACE if scenario.starts_at_market else HOME
	spec.home_place_id = HOME
	spec.work_place_id = WORK
	spec.x_cm = MARKET_X_CM if scenario.starts_at_market else scenario.home_x_cm
	var created: NpcModule.CreateResult = module.request_create_npc(spec)
	assert_true(created.result.ok, created.result.message)
	assert_eq(module.debug_summary()["decision_problem"], "", "Definições completas: o módulo decide.")
	return [world, module, economy, created.npc_id]


func _run(world: World, minutes: int) -> void:
	for _step: int in minutes:
		world.context.clock.advance_step()
		world.tick(1)


## Gasta o dinheiro do NPC e consome o que ele comprou: sobra menos que o preço da comida mais barata e o inventário fica vazio.
func _make_broke(economy: EconomyModule, npc_id: int) -> void:
	var market_id: int = economy.peek_market_of(SETTLEMENT).market_id
	while economy.request_trade(npc_id, market_id, "grain", 1, "buy").result.ok:
		pass
	for row: Dictionary in economy.peek_inventory(npc_id).rows:
		assert_true(economy.request_consume(npc_id, str(row["good_id"]), int(row["quantity"])).result.ok)
	assert_eq(economy.peek_inventory(npc_id).rows.size(), 0)
	assert_true(economy.peek_balance(npc_id).balance < economy.peek_quote(npc_id, market_id, "grain", 1, "buy").total, "Sem dinheiro nem para um grão.")


func test_a_hungry_npc_with_money_and_no_food_walks_to_the_market_buys_and_eats_from_the_inventory() -> void:
	var parts: Array = _setup()
	var world: World = parts[0]
	var module: NpcModule = parts[1]
	var economy: EconomyModule = parts[2]
	var npc_id: int = parts[3]
	var bought_at: int = -1
	var seen_buy: bool = false
	for minute: int in 90:
		_run(world, 1)
		if module.peek_npc(npc_id).action_id == "buy" and not seen_buy:
			seen_buy = true
			bought_at = minute
	assert_true(seen_buy, "Sem comida à mão e com dinheiro, o pensador escolheu `buy`.")
	var balance: int = economy.peek_balance(npc_id).balance
	assert_true(balance < INITIAL_MONEY, "Pagou pela comida: saldo %d." % balance)
	assert_eq(module.peek_npc(npc_id).need_values[HUNGER], START_HUNGER - 30 - 30, "Comeu as duas unidades de grão do inventário: 30 de alívio cada (a tabela diria 60).")
	assert_eq(economy.peek_inventory(npc_id).rows.size(), 0, "Comeu tudo o que comprou.")
	assert_true(economy.peek_conservation().ok and economy.peek_goods_conservation().ok)
	assert_true(bought_at > 0)
	world.teardown()


func test_a_hungry_npc_without_money_never_buys_and_follows_the_routine() -> void:
	var parts: Array = _setup()
	var world: World = parts[0]
	var module: NpcModule = parts[1]
	var economy: EconomyModule = parts[2]
	var npc_id: int = parts[3]
	_make_broke(economy, npc_id)
	var balance: int = economy.peek_balance(npc_id).balance
	for _minute: int in 60:
		_run(world, 1)
		assert_ne(module.peek_npc(npc_id).action_id, "buy", "Sem dinheiro nenhuma compra é escolhida.")
	assert_eq([economy.peek_balance(npc_id).balance, economy.peek_inventory(npc_id).rows.size()], [balance, 0], "Nada foi comprado.")
	assert_eq(module.peek_npc(npc_id).need_values[HUNGER], START_HUNGER, "E a fome continua.")
	world.teardown()


func test_a_purchase_that_costs_more_than_the_relief_is_worth_is_never_chosen() -> void:
	var scenario: Scenario = Scenario.new()
	scenario.price_percent = 1000
	var parts: Array = _setup(scenario)
	var world: World = parts[0]
	var module: NpcModule = parts[1]
	var economy: EconomyModule = parts[2]
	var npc_id: int = parts[3]
	for _minute: int in 60:
		_run(world, 1)
		assert_ne(module.peek_npc(npc_id).action_id, "buy", "Com o preço pesando 10 vezes o alívio de uma unidade não compensa.")
	assert_eq(economy.peek_balance(npc_id).balance, INITIAL_MONEY, "Nenhuma moeda saiu da conta.")
	world.teardown()


func test_a_npc_that_is_not_hungry_does_not_shop_even_with_money() -> void:
	var scenario: Scenario = Scenario.new()
	scenario.start_hunger = 20
	var parts: Array = _setup(scenario)
	var world: World = parts[0]
	var module: NpcModule = parts[1]
	var economy: EconomyModule = parts[2]
	var npc_id: int = parts[3]
	for _minute: int in 90:
		_run(world, 1)
		assert_ne(module.peek_npc(npc_id).action_id, "buy", "Sem fome urgente o NPC não vai ao mercado.")
	assert_eq([economy.peek_balance(npc_id).balance, economy.peek_inventory(npc_id).rows.size()], [INITIAL_MONEY, 0])
	world.teardown()


func test_only_urgent_hunger_sends_the_npc_to_the_market_not_another_urgent_need() -> void:
	var scenario: Scenario = Scenario.new()
	scenario.start_hunger = 20
	scenario.start_rest = 95
	var parts: Array = _setup(scenario)
	var world: World = parts[0]
	var module: NpcModule = parts[1]
	var economy: EconomyModule = parts[2]
	var npc_id: int = parts[3]
	for _minute: int in 90:
		_run(world, 1)
		assert_ne(module.peek_npc(npc_id).action_id, "buy", "O cansaço urgente não é motivo para comprar comida.")
	assert_eq(economy.peek_balance(npc_id).balance, INITIAL_MONEY)
	world.teardown()


## O valor derivado entra na disputa com outra ação que alivia a fome: com a refeição de graça mas a 5 km, a compra (no mercado onde o NPC está) vale mais; se o preço come o alívio, só resta a refeição.
func test_the_derived_value_of_buy_competes_with_a_free_meal_far_away() -> void:
	var scenario: Scenario = Scenario.new()
	scenario.starts_at_market = true
	scenario.home_x_cm = FAR_HOME_X_CM
	scenario.settlement_has_food = true
	var parts: Array = _setup(scenario)
	var world: World = parts[0]
	var module: NpcModule = parts[1]
	var npc_id: int = parts[3]
	var first_think: int = 1 + npc_id % THINK_INTERVAL
	_run(world, first_think)
	assert_eq(module.peek_npc(npc_id).action_id, "buy", "A refeição tem 5 km de distância: comprar aqui rende mais.")
	world.teardown()
	var priced_out: Scenario = Scenario.new()
	priced_out.starts_at_market = true
	priced_out.home_x_cm = FAR_HOME_X_CM
	priced_out.settlement_has_food = true
	priced_out.price_percent = 1000
	var other: Array = _setup(priced_out)
	var other_world: World = other[0]
	var other_module: NpcModule = other[1]
	var other_npc: int = other[3]
	_run(other_world, 1 + other_npc % THINK_INTERVAL)
	var meal: NpcModule.NpcQuery = other_module.peek_npc(other_npc)
	assert_eq([meal.action_id, meal.action_target_place_id], [ActionRunner.GO_TO_PLACE_ID, HOME], "Compra que não compensa: vai comer em casa, longe.")
	other_world.teardown()
