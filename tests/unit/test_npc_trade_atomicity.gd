extends GutTest
## LW-093 (093k, R6-I1): a troca é atômica (docs/modules/npc.md, 14.2): o `ActionRunner` confere que a necessidade que a economia aliviaria EXISTE nas definições ANTES de chamar a conclusão da ação, então uma ação que falharia não deixa a economia
## mudada (nada comprado, consumido nem vendido) e o sinalizador do estoque provisório não fica ligado. Cenário: o NPC tem 1 grão no inventário (economia REAL) e as necessidades do runner NÃO têm `hunger` (dado inconsistente entre `needs.json`
## e `goods.json`); o `eat` falha por necessidade desconhecida e saldo, inventário e conservação seguem iguais. O controle positivo (com `hunger`) come e esvazia o inventário. `completion_need_id` é a pergunta que o runner faz.

const SEED: int = 89
const SETTLEMENT_A: String = "test_settlement_a"
const NPC: int = 100
const NEEDS_WITH_HUNGER: Array[String] = ["hunger", "rest", "safety", "income", "social"]
const NEEDS_WITHOUT_HUNGER: Array[String] = ["thirst", "rest", "safety", "income", "social"]
const START_NEED: int = 80


## Guarda quantas vezes o `FoodStub` de teste foi avisado de uma ação completa.
class FoodSpy:
	extends ActionConditionProvider

	var completed: int = 0

	func on_action_completed(_action_id: String, _settlement_id: String, _occupation_id: String) -> void:
		completed += 1


func _setup() -> Array:
	var setup: EconomySetup = EconomySetup.from_dir(EconomySetup.DEFAULT_DIR)
	assert_true(setup.result.ok, setup.result.message)
	var economy: EconomyModule = EconomyModule.new(false, setup.definitions)
	var clock: SimClock = SimClock.new()
	var world: World = World.new(SimContext.new(clock, EventBus.new(clock), WorldRng.new(SEED), IdGenerator.new()))
	assert_true(world.register_module("economy", economy).ok)
	world.setup()
	world.post_setup()
	world.on_new_game(SEED)
	assert_true(economy.request_open_owner(NPC, "npc").ok)
	var market_id: int = economy.peek_market_of(SETTLEMENT_A).market_id
	assert_true(economy.request_transfer_goods(market_id, NPC, "grain", 1).ok, "O NPC começa com 1 grão no inventário.")
	var state: NpcState = NpcState.new(NPC)
	state.settlement_id = SETTLEMENT_A
	state.need_values = PackedInt64Array([START_NEED, START_NEED, START_NEED, START_NEED, START_NEED])
	var states: Dictionary[int, NpcState] = {NPC: state}
	return [world, economy, states, state]


func _runner(need_ids: Array[String], states: Dictionary[int, NpcState], provider: ActionConditionProvider) -> ActionRunner:
	var defs: Array[NeedDef] = []
	for position: int in need_ids.size():
		defs.append(NeedDef.new(need_ids[position], position, 0, 0, 40, 65, 90))
	var eat: ActionDef = ActionDef.new("eat", 20, "", 0, true)
	eat.effects.append(ActionDef.ActionEffect.new("rest", -10))
	return ActionRunner.new(states, [eat], defs, null, provider)


func _finish_eating(runner: ActionRunner) -> ActionRunner.AdvanceResult:
	assert_true(runner.begin(NPC, "eat", "", 0).ok)
	return runner.advance(NPC, 20)


func test_an_action_that_would_fail_for_an_unknown_need_leaves_the_economy_and_the_flag_untouched() -> void:
	var parts: Array = _setup()
	var world: World = parts[0]
	var economy: EconomyModule = parts[1]
	var states: Dictionary[int, NpcState] = parts[2]
	var spy: FoodSpy = FoodSpy.new()
	var trade: NpcTrade = NpcTrade.new(economy, states, 2)
	var provider: NpcThinker.ConditionProvider = NpcThinker.ConditionProvider.new(null, null, spy, null, trade)
	var balance_before: int = economy.peek_balance(NPC).balance
	var finished: ActionRunner.AdvanceResult = _finish_eating(_runner(NEEDS_WITHOUT_HUNGER, states, provider))
	assert_eq([finished.outcome, finished.result.code], [ActionRunner.Outcome.FAILED, ActionRunner.CODE_UNKNOWN_NEED])
	assert_string_contains(finished.result.message, "hunger")
	assert_string_contains(finished.result.message, "nada foi comprado, consumido nem vendido")
	assert_eq(economy.peek_inventory(NPC).rows, [{"good_id": "grain", "quantity": 1}] as Array[Dictionary], "O grão continua no inventário: a economia não mudou.")
	assert_eq(economy.peek_balance(NPC).balance, balance_before, "O saldo não mudou.")
	for row: Dictionary in economy.peek_goods_conservation().rows:
		if row["good_id"] == "grain":
			assert_eq(int(row["destroyed"]), 0, "Nada foi consumido.")
	assert_eq(states[NPC].need_values[1], START_NEED, "Nenhum efeito foi aplicado.")
	provider.on_action_completed("eat", SETTLEMENT_A, "")
	assert_eq(spy.completed, 1, "O sinalizador do estoque provisório não ficou ligado: a próxima conclusão o avisa.")
	world.teardown()


func test_with_the_need_in_the_definitions_the_same_action_eats_and_empties_the_inventory() -> void:
	var parts: Array = _setup()
	var world: World = parts[0]
	var economy: EconomyModule = parts[1]
	var states: Dictionary[int, NpcState] = parts[2]
	var provider: NpcThinker.ConditionProvider = NpcThinker.ConditionProvider.new(null, null, FoodSpy.new(), null, NpcTrade.new(economy, states, 2))
	var finished: ActionRunner.AdvanceResult = _finish_eating(_runner(NEEDS_WITH_HUNGER, states, provider))
	assert_eq(finished.outcome, ActionRunner.Outcome.COMPLETED)
	assert_eq(economy.peek_inventory(NPC).rows.size(), 0, "Comeu o grão.")
	assert_eq(states[NPC].need_values[0], START_NEED - 30, "O grão alivia 30 de fome (a tabela de `eat` do teste não mexe nela).")
	world.teardown()


func test_the_question_the_runner_asks_names_the_need_of_the_food_and_nothing_else() -> void:
	var parts: Array = _setup()
	var world: World = parts[0]
	var economy: EconomyModule = parts[1]
	var states: Dictionary[int, NpcState] = parts[2]
	var trade: NpcTrade = NpcTrade.new(economy, states, 2)
	assert_eq(trade.completion_need_id(NPC, "eat"), "hunger", "O `eat` consumiria o grão, que alivia a fome.")
	assert_eq([trade.completion_need_id(NPC, "buy"), trade.completion_need_id(NPC, "sell"), trade.completion_need_id(NPC, "work")], ["", "", ""], "As outras ações não aliviam nada pela economia.")
	assert_eq(trade.completion_need_id(999, "eat"), "", "NPC sem inventário: nada.")
	var provider: NpcThinker.ConditionProvider = NpcThinker.ConditionProvider.new(null, null, null, null, trade)
	assert_eq(provider.completion_need_id(NPC, "eat"), "hunger")
	assert_eq(NpcThinker.ConditionProvider.new(null, null, null, null, null).completion_need_id(NPC, "eat"), "", "Sem economia o provedor não alivia nada.")
	assert_eq(ActionConditionProvider.new().completion_need_id(NPC, "eat"), "", "O provedor padrão também não.")
	assert_eq(economy.peek_inventory(NPC).rows.size(), 1, "Perguntar não consome nada.")
	world.teardown()
