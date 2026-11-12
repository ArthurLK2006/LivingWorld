extends GutTest
## LW-096 (parte c): a conclusão dos contratos (docs/modules/economy.md, seção 8; DEC-151): `request_work_shift` completa o `labor` (os minutos de turno somam até os do contrato, dentro do prazo, e a custódia paga o aceitante, `contract_payout`) e é
## RECUSADO com `ECON_WORKER_ALREADY_ASSIGNED` para quem já é atribuído ao local (um trabalho, um pagamento); `request_deliver_contract` move os bens do aceitante ao destino e paga, tudo ou nada. Cada conclusão publica UM `ContractCompleted`; a
## custódia fica vazia, o dinheiro e os bens seguem conservados. Economia REAL com um posto de `guard` em `a_work_05` (montado à mão) e NPCs reais (saldo inicial 60).

const SEED: int = 79
const SETTLEMENT_A: String = "test_settlement_a"
const PLACE_POST: String = "a_work_05"
const PLACE_FREE: String = "a_work_04"
const ISSUER: int = 100
const WORKER: int = 101
const DESTINATION: int = 102
const GUARD: int = 103
const REWARD: int = 25
const NPC_START_MONEY: int = 60
const MINUTES: int = 30
const DEADLINE: int = 600


func _definitions() -> EconomyDefinitions:
	var setup: EconomySetup = EconomySetup.from_dir(EconomySetup.DEFAULT_DIR)
	assert_true(setup.result.ok, setup.result.message)
	var definitions: EconomyDefinitions = setup.definitions
	var posts: Array[PostDef] = [PostDef.new("post_a_guard", SETTLEMENT_A, PLACE_POST, "guard", 8, 3), PostDef.new("post_a_inn", SETTLEMENT_A, PLACE_FREE, "innkeeper", 6, 2)]
	definitions.service_posts = posts
	return definitions


## Mundo com a economia e os NPCs com conta; o GUARD é atribuído ao posto de `a_work_05`. Devolve [world, economy].
func _world() -> Array:
	var economy: EconomyModule = EconomyModule.new(false, _definitions())
	var clock: SimClock = SimClock.new()
	var world: World = World.new(SimContext.new(clock, EventBus.new(clock), WorldRng.new(SEED), IdGenerator.new()))
	assert_true(world.register_module("economy", economy).ok)
	world.setup()
	world.post_setup()
	world.on_new_game(SEED)
	for npc_id: int in [ISSUER, WORKER, DESTINATION]:
		assert_true(economy.request_open_owner(npc_id, "npc").ok)
	assert_true(economy.request_open_owner(GUARD, "npc", PLACE_POST).ok)
	return [world, economy]


func _completions(world: World) -> Array[ContractCompleted]:
	var done: Array[ContractCompleted] = []
	world.context.events.subscribe("ContractCompleted", func(event: SimEvent) -> void: done.append(event))
	return done


func _accepted_labor(economy: EconomyModule, place_id: String = PLACE_FREE) -> int:
	var contract_id: int = economy.request_post_contract("labor", ISSUER, REWARD, DEADLINE, {"place_id": place_id, "minutes": MINUTES}).contract_id
	assert_true(economy.request_accept_contract(contract_id, WORKER).ok)
	return contract_id


func test_the_labor_contract_completes_when_the_shifts_add_up_and_the_custody_pays_the_worker() -> void:
	var parts: Array = _world()
	var world: World = parts[0]
	var economy: EconomyModule = parts[1]
	var done: Array[ContractCompleted] = _completions(world)
	var contract_id: int = _accepted_labor(economy)
	assert_true(economy.request_work_shift(PLACE_FREE, WORKER, 10).ok)
	assert_true(economy.request_work_shift(PLACE_FREE, WORKER, 10).ok)
	var middle: EconomyReplies.ContractQuery = economy.peek_contract(contract_id)
	assert_eq([middle.state, middle.worked_minutes, economy.peek_balance(WORKER).balance, economy.peek_balance(contract_id).balance], ["accepted", 20, NPC_START_MONEY, REWARD], "Meio caminho: nada pago, custódia inteira.")
	world.context.events.dispatch()
	assert_eq(done.size(), 0)
	assert_true(economy.request_work_shift(PLACE_FREE, WORKER, 15).ok, "Passar dos minutos também completa.")
	world.context.events.dispatch()
	var finished: EconomyReplies.ContractQuery = economy.peek_contract(contract_id)
	assert_eq([finished.state, economy.peek_balance(WORKER).balance, economy.peek_balance(contract_id).balance, economy.peek_balance(ISSUER).balance], ["completed", NPC_START_MONEY + REWARD, 0, NPC_START_MONEY - REWARD], "A custódia pagou o trabalhador e ficou vazia.")
	assert_eq(done.size(), 1)
	assert_eq([done[0].contract_id, done[0].acceptor_id, done[0].reward], [contract_id, WORKER, REWARD])
	assert_true(economy.peek_conservation().ok)
	assert_eq(economy.validate(), [] as Array[String])
	assert_eq(economy.request_work_shift(PLACE_FREE, WORKER, 5).code, EconomyCodes.UNKNOWN_CONTRACT, "Depois de completo não há mais o que trabalhar.")
	world.teardown()


func test_a_worker_already_assigned_to_the_place_is_refused_one_job_one_payment() -> void:
	var parts: Array = _world()
	var world: World = parts[0]
	var economy: EconomyModule = parts[1]
	var contract_id: int = economy.request_post_contract("labor", ISSUER, REWARD, DEADLINE, {"place_id": PLACE_POST, "minutes": MINUTES}).contract_id
	assert_true(economy.request_accept_contract(contract_id, GUARD).ok)
	var refused: Result = economy.request_work_shift(PLACE_POST, GUARD, MINUTES)
	assert_eq(refused.code, EconomyCodes.WORKER_ALREADY_ASSIGNED, refused.message)
	assert_eq([economy.peek_contract(contract_id).worked_minutes, economy.peek_balance(GUARD).balance], [0, NPC_START_MONEY], "Nada mudou: o guarda é pago pela folha.")
	assert_true(economy.request_accept_contract(economy.request_post_contract("labor", ISSUER, REWARD, DEADLINE, {"place_id": PLACE_POST, "minutes": 10}).contract_id, WORKER).ok)
	assert_true(economy.request_work_shift(PLACE_POST, WORKER, 10).ok, "Quem não é atribuído ao local pode trabalhar nele por contrato.")
	world.teardown()


func test_a_shift_without_an_accepted_contract_a_bad_amount_or_after_the_deadline_is_refused() -> void:
	var parts: Array = _world()
	var world: World = parts[0]
	var economy: EconomyModule = parts[1]
	assert_eq(economy.request_work_shift(PLACE_FREE, WORKER, 10).code, EconomyCodes.UNKNOWN_CONTRACT, "Sem contrato aceito.")
	var contract_id: int = economy.request_post_contract("labor", ISSUER, REWARD, DEADLINE, {"place_id": PLACE_FREE, "minutes": MINUTES}).contract_id
	assert_eq(economy.request_work_shift(PLACE_FREE, WORKER, 10).code, EconomyCodes.UNKNOWN_CONTRACT, "Contrato só aberto, ninguém o aceitou.")
	assert_true(economy.request_accept_contract(contract_id, WORKER).ok)
	assert_eq(economy.request_work_shift(PLACE_FREE, WORKER, 0).code, EconomyCodes.CONTRACT_IMPOSSIBLE)
	assert_eq(economy.request_work_shift(PLACE_FREE, 999, 10).code, EconomyCodes.UNKNOWN_OWNER)
	assert_eq(economy.request_work_shift(PLACE_POST, WORKER, 10).code, EconomyCodes.UNKNOWN_CONTRACT, "Outro local.")
	assert_eq(economy.request_work_shift(PLACE_FREE, DESTINATION, 10).code, EconomyCodes.UNKNOWN_CONTRACT, "Outro trabalhador.")
	while world.context.clock.total_minutes() < DEADLINE:
		world.context.clock.advance_step()
	var late: Result = economy.request_work_shift(PLACE_FREE, WORKER, MINUTES)
	assert_eq(late.code, EconomyCodes.CONTRACT_IMPOSSIBLE, late.message)
	assert_eq([economy.peek_contract(contract_id).state, economy.peek_balance(WORKER).balance], ["accepted", NPC_START_MONEY], "Depois do prazo nada é pago.")
	var lone: EconomyModule = EconomyModule.new(false, _definitions())
	assert_eq(lone.request_work_shift(PLACE_FREE, WORKER, 10).code, EconomyCodes.CONTRACT_IMPOSSIBLE, "Sem `setup` não há relógio.")
	assert_eq(lone.request_deliver_contract(1).code, EconomyCodes.CONTRACT_IMPOSSIBLE)
	world.teardown()


func test_a_delivery_moves_the_goods_and_pays_all_or_nothing() -> void:
	var parts: Array = _world()
	var world: World = parts[0]
	var economy: EconomyModule = parts[1]
	var done: Array[ContractCompleted] = _completions(world)
	var market_id: int = economy.peek_market_of(SETTLEMENT_A).market_id
	var contract_id: int = economy.request_post_contract("delivery", ISSUER, REWARD, DEADLINE, {"good_id": "grain", "quantity": 3, "destination_id": DESTINATION}).contract_id
	assert_eq(economy.request_deliver_contract(contract_id).code, EconomyCodes.CONTRACT_NOT_OPEN, "Ainda aberto, ninguém aceitou.")
	assert_true(economy.request_accept_contract(contract_id, WORKER).ok)
	var short: Result = economy.request_deliver_contract(contract_id)
	assert_eq(short.code, EconomyCodes.INSUFFICIENT_GOODS, short.message)
	assert_eq([economy.peek_contract(contract_id).state, economy.peek_balance(contract_id).balance, economy.peek_balance(WORKER).balance], ["accepted", REWARD, NPC_START_MONEY], "Sem os bens nada mudou.")
	assert_true(economy.request_transfer_goods(market_id, WORKER, "grain", 3).ok)
	assert_true(economy.request_deliver_contract(contract_id).ok)
	world.context.events.dispatch()
	assert_eq([economy.peek_inventory(WORKER).rows.size(), economy.peek_inventory(DESTINATION).rows], [0, [{"good_id": "grain", "quantity": 3}] as Array[Dictionary]], "Os bens foram para o destino.")
	assert_eq([economy.peek_contract(contract_id).state, economy.peek_balance(WORKER).balance, economy.peek_balance(contract_id).balance], ["completed", NPC_START_MONEY + REWARD, 0])
	assert_eq(done.size(), 1)
	assert_eq([done[0].contract_id, done[0].acceptor_id, done[0].reward], [contract_id, WORKER, REWARD])
	assert_true(economy.peek_conservation().ok and economy.peek_goods_conservation().ok)
	assert_eq(economy.request_deliver_contract(contract_id).code, EconomyCodes.CONTRACT_NOT_OPEN, "Já completo.")
	var labor: int = _accepted_labor(economy)
	assert_eq(economy.request_deliver_contract(labor).code, EconomyCodes.CONTRACT_IMPOSSIBLE, "Contrato `labor` não se entrega.")
	assert_eq(economy.request_deliver_contract(999).code, EconomyCodes.UNKNOWN_CONTRACT)
	world.teardown()


func test_the_worked_minutes_survive_the_save() -> void:
	var parts: Array = _world()
	var world: World = parts[0]
	var economy: EconomyModule = parts[1]
	var contract_id: int = _accepted_labor(economy)
	assert_true(economy.request_work_shift(PLACE_FREE, WORKER, 12).ok)
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
	assert_eq(copy.peek_contract(contract_id).worked_minutes, 12)
	assert_true(copy.request_work_shift(PLACE_FREE, WORKER, 18).ok, "Os 12 minutos já trabalhados contam: faltavam 18.")
	assert_eq(copy.peek_contract(contract_id).state, "completed")
	world.teardown()
	other_world.teardown()


func test_a_delivery_after_the_deadline_is_refused_and_nothing_moves() -> void:
	var parts: Array = _world()
	var world: World = parts[0]
	var economy: EconomyModule = parts[1]
	var market_id: int = economy.peek_market_of(SETTLEMENT_A).market_id
	var contract_id: int = economy.request_post_contract("delivery", ISSUER, REWARD, DEADLINE, {"good_id": "grain", "quantity": 3, "destination_id": DESTINATION}).contract_id
	assert_true(economy.request_accept_contract(contract_id, WORKER).ok)
	assert_true(economy.request_transfer_goods(market_id, WORKER, "grain", 3).ok)
	while world.context.clock.total_minutes() < DEADLINE:
		world.context.clock.advance_step()
	var late: Result = economy.request_deliver_contract(contract_id)
	assert_eq(late.code, EconomyCodes.CONTRACT_IMPOSSIBLE, late.message)
	assert_eq([economy.peek_inventory(WORKER).rows.size(), economy.peek_inventory(DESTINATION).rows.size(), economy.peek_balance(contract_id).balance], [1, 0, REWARD], "Os bens ficam com o aceitante e a custódia intacta.")
	world.teardown()
