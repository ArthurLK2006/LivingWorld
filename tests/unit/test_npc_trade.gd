extends GutTest
## LW-093 (parte 6): o NPC no mercado (docs/modules/npc.md, 14.2, 14.3 e 14.6): `NpcTrade` pede `request_trade` e `request_consume` à porta da economia (o `npc` nunca altera saldo nem estoque), a conclusão da ação (`buy`, `eat`,
## `sell`) passa pelo `ActionRunner` num ponto único e o `FoodStub` só consome quando a comida não saiu do inventário. Economia REAL (data/economy): mercado A (dono 1, pão alivia 60 e grão 30 de fome) e o NPC 100 (saldo inicial 60).

const SEED: int = 79
const SETTLEMENT_A: String = "test_settlement_a"
const MARKET: int = 1
const NPC: int = 100
const BROKE: int = 101
const NEED_IDS: Array[String] = ["hunger", "rest", "safety", "income", "social"]

var _states: Dictionary[int, NpcState] = {}


## Provedor de teste do runner: devolve a conclusão que o teste mandar.
class FakeCompletion:
	extends ActionConditionProvider

	var completion: ActionConditionProvider.Completion = ActionConditionProvider.Completion.new()

	func complete_action(_npc_id: int, _action_id: String) -> ActionConditionProvider.Completion:
		return completion


## Guarda quantas vezes o `FoodStub` de teste foi avisado de uma ação completa.
class FoodSpy:
	extends ActionConditionProvider

	var completed: int = 0

	func on_action_completed(_action_id: String, _settlement_id: String, _occupation_id: String) -> void:
		completed += 1


func before_each() -> void:
	_states = {}


func _world_with_economy() -> Array:
	var setup: EconomySetup = EconomySetup.from_dir(EconomySetup.DEFAULT_DIR)
	assert_true(setup.result.ok, setup.result.message)
	var module: EconomyModule = EconomyModule.new(false, setup.definitions)
	var clock: SimClock = SimClock.new()
	var world: World = World.new(SimContext.new(clock, EventBus.new(clock), WorldRng.new(SEED), IdGenerator.new()))
	assert_true(world.register_module("economy", module).ok)
	world.setup()
	world.post_setup()
	world.on_new_game(SEED)
	assert_true(module.request_open_owner(NPC, "npc").ok)
	assert_true(module.request_open_owner(BROKE, "contract").ok, "Conta sem dinheiro (saldo inicial 0).")
	for npc_id: int in [NPC, BROKE]:
		var state: NpcState = NpcState.new(npc_id)
		state.settlement_id = SETTLEMENT_A
		_states[npc_id] = state
	return [module, world]


func _quote(module: EconomyModule, good_id: String, units: int) -> EconomyReplies.QuoteQuery:
	return module.peek_quote(NPC, MARKET, good_id, units, "buy")


func test_the_plan_buys_the_food_that_relieves_the_most_per_coin_as_much_as_the_money_allows() -> void:
	var pair: Array = _world_with_economy()
	var module: EconomyModule = pair[0]
	var trade: NpcTrade = NpcTrade.new(module, _states, 2)
	var plan: NpcTrade.FoodPlan = trade.plan_food(NPC)
	assert_false(plan.is_empty())
	var grain: EconomyReplies.QuoteQuery = _quote(module, "grain", 2)
	var bread: EconomyReplies.QuoteQuery = _quote(module, "bread", 2)
	assert_true(30 * 2 * bread.total > 60 * 2 * grain.total, "Por moeda o grão (30 por unidade) rende mais que o pão (60) neste mercado.")
	assert_eq([plan.good_id, plan.units, plan.total, plan.relief, plan.market_id], ["grain", 2, grain.total, 60, MARKET])
	assert_true(trade.plan_food(BROKE).is_empty(), "Sem dinheiro não há compra.")
	assert_true(NpcTrade.new(module, _states, 0).plan_food(NPC).is_empty(), "`buy_units` 0: o NPC não compra.")
	assert_true(NpcTrade.new(module, _states, 2).plan_food(999).is_empty(), "NPC que não existe: nada.")
	(pair[1] as World).teardown()


func test_the_buy_value_is_the_relief_of_the_best_plan_minus_the_price_weighted_by_the_param() -> void:
	var pair: Array = _world_with_economy()
	var module: EconomyModule = pair[0]
	var total: int = NpcTrade.new(module, _states, 2).plan_food(NPC).total
	assert_true(total > 0 and total < 60)
	assert_eq(NpcTrade.new(module, _states, 2, 0).buy_value(NPC), 60, "Preço sem peso: o alívio inteiro (2 grãos, 30 cada).")
	assert_eq(NpcTrade.new(module, _states, 2, 100).buy_value(NPC), 60 - total, "Peso 100%: cada moeda tira um ponto.")
	assert_eq(NpcTrade.new(module, _states, 2, 50).buy_value(NPC), 60 - IntMath.floor_div(total * 50, 100), "Peso 50%: metade do preço.")
	assert_eq(NpcTrade.new(module, _states, 2, 1000).buy_value(NPC), 0, "Preço que come o alívio todo: a compra não vale nada (nunca negativo).")
	assert_eq(NpcTrade.new(module, _states, 2, 100).buy_value(BROKE), 0, "Sem dinheiro não há compra.")
	assert_eq(NpcTrade.new(module, _states, 0, 100).buy_value(NPC), 0, "`buy_units` 0: o NPC não compra.")
	(pair[1] as World).teardown()


func test_completing_buy_pays_through_the_economy_and_a_broke_npc_fails_by_rule() -> void:
	var pair: Array = _world_with_economy()
	var module: EconomyModule = pair[0]
	var trade: NpcTrade = NpcTrade.new(module, _states, 2)
	var plan: NpcTrade.FoodPlan = trade.plan_food(NPC)
	var done: ActionConditionProvider.Completion = trade.complete(NPC, "buy")
	assert_eq(done.problem, "")
	assert_eq([module.peek_balance(NPC).balance, module.peek_inventory(NPC).rows], [60 - plan.total, [{"good_id": "grain", "quantity": 2}] as Array[Dictionary]], "A economia moveu o dinheiro e a comida.")
	assert_true(module.peek_conservation().ok and module.peek_goods_conservation().ok)
	var broke: ActionConditionProvider.Completion = trade.complete(BROKE, "buy")
	assert_string_contains(broke.problem, "não tem dinheiro")
	assert_eq(module.peek_inventory(BROKE).rows.size(), 0, "A compra que falha não muda nada.")
	assert_eq(trade.complete(NPC, "wait").problem, "", "Outra ação: nada a fazer.")
	(pair[1] as World).teardown()


func test_completing_eat_consumes_one_unit_from_the_inventory_and_returns_the_relief_of_the_good() -> void:
	var pair: Array = _world_with_economy()
	var module: EconomyModule = pair[0]
	var trade: NpcTrade = NpcTrade.new(module, _states, 2)
	assert_false(trade.has_food(NPC) or trade.has_goods(NPC), "NPC recém-nascido: inventário vazio.")
	assert_true(module.request_transfer_goods(MARKET, NPC, "bread", 1).ok and module.request_transfer_goods(MARKET, NPC, "grain", 1).ok)
	assert_true(trade.has_food(NPC) and trade.has_goods(NPC))
	var first: ActionConditionProvider.Completion = trade.complete(NPC, "eat")
	assert_eq([first.problem, first.consumed_from_inventory, first.relieved_need_id, first.relief], ["", true, "hunger", 60], "Come o de menor id (pão): alivia 60.")
	var second: ActionConditionProvider.Completion = trade.complete(NPC, "eat")
	assert_eq([second.consumed_from_inventory, second.relief], [true, 30], "Depois o grão: 30.")
	var none: ActionConditionProvider.Completion = trade.complete(NPC, "eat")
	assert_eq([none.problem, none.consumed_from_inventory, none.relieved_need_id], ["", false, ""], "Sem comida no inventário não faz nada aqui: vale o `FoodStub` de reserva.")
	assert_false(trade.has_food(NPC))
	(pair[1] as World).teardown()


func test_completing_sell_gives_what_the_npc_has_to_the_market_for_money() -> void:
	var pair: Array = _world_with_economy()
	var module: EconomyModule = pair[0]
	var trade: NpcTrade = NpcTrade.new(module, _states, 2)
	assert_string_contains(trade.complete(NPC, "sell").problem, "não comprou nada", "Sem nada para vender a ação falha por regra.")
	assert_true(module.request_transfer_goods(MARKET, NPC, "bread", 3).ok)
	var done: ActionConditionProvider.Completion = trade.complete(NPC, "sell")
	assert_eq(done.problem, "")
	assert_true(module.peek_balance(NPC).balance > 60, "O mercado pagou pelo pão.")
	assert_eq(module.peek_inventory(NPC).rows.size(), 0, "E o NPC ficou sem ele.")
	assert_true(module.peek_conservation().ok)
	(pair[1] as World).teardown()


func _npc_hungry(value: int) -> NpcState:
	var state: NpcState = NpcState.new(1)
	state.need_values = PackedInt64Array([value, 0, 0, 0, 0])
	state.settlement_id = SETTLEMENT_A
	_states[1] = state
	return state


func _runner(provider: ActionConditionProvider) -> ActionRunner:
	var defs: Array[NeedDef] = []
	for position: int in NEED_IDS.size():
		defs.append(NeedDef.new(NEED_IDS[position], position, 0, 0, 40, 65, 90))
	var eat: ActionDef = ActionDef.new("eat", 20, "", 0, true)
	eat.effects.append(ActionDef.ActionEffect.new("hunger", -60))
	return ActionRunner.new(_states, [eat], defs, null, provider)


func test_the_runner_corrects_the_table_relief_by_what_the_eaten_good_relieves() -> void:
	var state: NpcState = _npc_hungry(80)
	var provider: FakeCompletion = FakeCompletion.new()
	provider.completion.relieved_need_id = "hunger"
	provider.completion.relief = 30
	var runner: ActionRunner = _runner(provider)
	assert_true(runner.begin(1, "eat", "", 0).ok)
	assert_eq(runner.advance(1, 20).outcome, ActionRunner.Outcome.COMPLETED)
	assert_eq(state.need_values[0], 50, "A tabela alivia 60, o grão alivia 30: a economia corrige para 30 (80 - 30).")


func test_a_completion_problem_fails_the_action_by_rule_without_any_effect() -> void:
	var state: NpcState = _npc_hungry(80)
	var provider: FakeCompletion = FakeCompletion.new()
	provider.completion = ActionConditionProvider.Completion.failed("a compra falhou")
	var runner: ActionRunner = _runner(provider)
	assert_true(runner.begin(1, "eat", "", 0).ok)
	var finished: ActionRunner.AdvanceResult = runner.advance(1, 20)
	assert_eq([finished.outcome, finished.result.code], [ActionRunner.Outcome.FAILED, ActionRunner.CODE_ACTION_FAILED])
	assert_string_contains(finished.result.message, "a compra falhou")
	assert_eq([state.need_values[0], state.action_id], [80, ""], "Nenhum efeito entrou e o NPC ficou livre.")


func test_the_food_stub_only_consumes_when_the_food_did_not_come_from_the_inventory() -> void:
	var pair: Array = _world_with_economy()
	var module: EconomyModule = pair[0]
	var trade: NpcTrade = NpcTrade.new(module, _states, 2)
	var spy: FoodSpy = FoodSpy.new()
	var provider: NpcThinker.ConditionProvider = NpcThinker.ConditionProvider.new(null, null, spy, null, trade)
	assert_false(provider.can_buy_food(BROKE), "Sem dinheiro o provedor diz que não dá para comprar.")
	assert_true(provider.can_buy_food(NPC) and not provider.npc_has_food(NPC, "nowhere"), "Com dinheiro dá para comprar; comida só no inventário ou no estoque provisório.")
	_states[NPC].need_values = PackedInt64Array([80, 0, 0, 0, 0])
	var runner: ActionRunner = _runner(provider)
	assert_true(runner.begin(NPC, "eat", "", 0).ok)
	assert_eq(runner.advance(NPC, 20).outcome, ActionRunner.Outcome.COMPLETED)
	assert_eq(spy.completed, 1, "Sem comida no inventário o estoque provisório consome a refeição.")
	assert_true(module.request_transfer_goods(MARKET, NPC, "bread", 1).ok)
	assert_true(provider.npc_has_food(NPC, "nowhere"))
	assert_true(runner.begin(NPC, "eat", "", 20).ok, "A segunda refeição começa quando a primeira acabou (minuto 20).")
	assert_eq(runner.advance(NPC, 40).outcome, ActionRunner.Outcome.COMPLETED)
	assert_eq([spy.completed, module.peek_inventory(NPC).rows.size()], [1, 0], "Comeu do inventário: o runner não avisa o estoque provisório, que não consome de novo.")
	(pair[1] as World).teardown()
