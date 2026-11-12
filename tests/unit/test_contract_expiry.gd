extends GutTest
## LW-096 (parte d): o prazo dos contratos (docs/modules/economy.md, seção 8; Q14): na hora seguinte ao vencimento o contrato `labor` ou `delivery`, aberto ou aceito, vira `expired`, a custódia volta ao emissor (`contract_refund`) e o `ContractFailed`
## (`reason` = `expired`) sai, por ID crescente; o contrato concluído não é tocado; emissor FECHADO (morreu) não recebe de volta e a recompensa fica na conta do contrato (o teste de ouro segue fechando). Economia REAL com um posto de `guard` em
## `a_work_05` (montado à mão) e NPCs reais (saldo inicial 60); o tempo anda pelo relógio do mundo, hora a hora.

const SEED: int = 83
const MINUTES_PER_HOUR: int = 60
const SETTLEMENT_A: String = "test_settlement_a"
const PLACE_POST: String = "a_work_05"
const ISSUER: int = 100
const WORKER: int = 101
const DESTINATION: int = 102
const REWARD: int = 25
const NPC_START_MONEY: int = 60


func _definitions() -> EconomyDefinitions:
	var setup: EconomySetup = EconomySetup.from_dir(EconomySetup.DEFAULT_DIR)
	assert_true(setup.result.ok, setup.result.message)
	var definitions: EconomyDefinitions = setup.definitions
	var posts: Array[PostDef] = [PostDef.new("post_a_guard", SETTLEMENT_A, PLACE_POST, "guard", 8, 3)]
	definitions.service_posts = posts
	return definitions


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
	return [world, economy]


func _run_minutes(world: World, minutes: int) -> void:
	for _minute: int in minutes:
		world.context.clock.advance_step()
		world.tick(1)
		world.context.events.dispatch()


func _failures(world: World) -> Array[ContractFailed]:
	var failed: Array[ContractFailed] = []
	world.context.events.subscribe("ContractFailed", func(event: SimEvent) -> void: failed.append(event))
	return failed


func _labor(economy: EconomyModule, deadline: int, issuer: int = ISSUER) -> int:
	var posted: EconomyReplies.PostContractResult = economy.request_post_contract("labor", issuer, REWARD, deadline, {"place_id": PLACE_POST, "minutes": 30})
	assert_true(posted.result.ok, posted.result.message)
	return posted.contract_id


func test_an_open_contract_expires_in_the_hour_after_its_deadline_and_the_custody_goes_back() -> void:
	var parts: Array = _world()
	var world: World = parts[0]
	var economy: EconomyModule = parts[1]
	var failed: Array[ContractFailed] = _failures(world)
	var contract_id: int = _labor(economy, 2 * MINUTES_PER_HOUR)
	_run_minutes(world, MINUTES_PER_HOUR)
	assert_eq([economy.peek_contract(contract_id).state, economy.peek_balance(contract_id).balance, failed.size()], ["open", REWARD, 0], "Antes do prazo: nada.")
	_run_minutes(world, MINUTES_PER_HOUR)
	assert_eq(economy.peek_contract(contract_id).state, "expired", "Na hora cheia do prazo vence.")
	assert_eq([economy.peek_balance(ISSUER).balance, economy.peek_balance(contract_id).balance], [NPC_START_MONEY, 0], "A custódia voltou inteira ao emissor.")
	assert_eq(failed.size(), 1)
	assert_eq([failed[0].contract_id, failed[0].issuer_id, failed[0].reason], [contract_id, ISSUER, "expired"])
	assert_true(economy.peek_conservation().ok)
	assert_eq(economy.validate(), [] as Array[String])
	_run_minutes(world, 3 * MINUTES_PER_HOUR)
	assert_eq(failed.size(), 1, "Vence uma vez só.")
	assert_eq(economy.request_accept_contract(contract_id, WORKER).code, EconomyCodes.CONTRACT_NOT_OPEN, "Contrato vencido não se aceita.")
	world.teardown()


func test_an_accepted_contract_also_expires_and_the_unpaid_work_pays_nothing() -> void:
	var parts: Array = _world()
	var world: World = parts[0]
	var economy: EconomyModule = parts[1]
	var failed: Array[ContractFailed] = _failures(world)
	var contract_id: int = _labor(economy, 2 * MINUTES_PER_HOUR)
	assert_true(economy.request_accept_contract(contract_id, WORKER).ok)
	assert_true(economy.request_work_shift(PLACE_POST, WORKER, 10).ok)
	_run_minutes(world, 2 * MINUTES_PER_HOUR)
	assert_eq([economy.peek_contract(contract_id).state, economy.peek_balance(WORKER).balance, economy.peek_balance(ISSUER).balance, failed.size()], ["expired", NPC_START_MONEY, NPC_START_MONEY, 1], "Trabalho incompleto não é pago e o emissor recebe de volta.")
	world.teardown()


func test_a_completed_contract_is_never_expired_and_the_ones_that_expire_come_by_id() -> void:
	var parts: Array = _world()
	var world: World = parts[0]
	var economy: EconomyModule = parts[1]
	var failed: Array[ContractFailed] = _failures(world)
	var done: int = _labor(economy, 2 * MINUTES_PER_HOUR)
	assert_true(economy.request_accept_contract(done, WORKER).ok)
	assert_true(economy.request_work_shift(PLACE_POST, WORKER, 30).ok)
	var first: int = _labor(economy, 2 * MINUTES_PER_HOUR)
	var second: int = _labor(economy, 2 * MINUTES_PER_HOUR, WORKER)
	var no_deadline_yet: int = _labor(economy, 5 * MINUTES_PER_HOUR, DESTINATION)
	_run_minutes(world, 2 * MINUTES_PER_HOUR)
	assert_eq(economy.peek_contract(done).state, "completed", "O concluído fica como está.")
	assert_eq([economy.peek_contract(first).state, economy.peek_contract(second).state, economy.peek_contract(no_deadline_yet).state], ["expired", "expired", "open"])
	assert_eq([failed.size(), failed[0].contract_id, failed[1].contract_id], [2, first, second], "Por ID crescente.")
	assert_eq([economy.peek_balance(WORKER).balance, economy.peek_balance(ISSUER).balance, economy.peek_balance(DESTINATION).balance], [NPC_START_MONEY + REWARD, NPC_START_MONEY - REWARD, NPC_START_MONEY - REWARD], "O trabalhador recebeu o concluído e teve o vencido dele de volta; o emissor pagou o concluído e teve o vencido de volta; quem postou o aberto ainda o retém.")
	assert_true(economy.peek_conservation().ok)
	assert_eq(economy.validate(), [] as Array[String])
	world.teardown()


func test_a_dead_issuer_gets_nothing_back_and_the_reward_stays_in_the_contract_account() -> void:
	var parts: Array = _world()
	var world: World = parts[0]
	var economy: EconomyModule = parts[1]
	var failed: Array[ContractFailed] = _failures(world)
	var contract_id: int = _labor(economy, 2 * MINUTES_PER_HOUR)
	world.context.events.publish(NpcDied.new(ISSUER, "test", 0))
	world.context.events.dispatch()
	_run_minutes(world, 2 * MINUTES_PER_HOUR)
	assert_eq([economy.peek_contract(contract_id).state, economy.peek_balance(contract_id).balance, failed.size()], ["expired", REWARD, 1], "O contrato vence e o evento sai, mas o emissor morto não recebe.")
	assert_true(economy.peek_conservation().ok, "O dinheiro continua contado.")
	assert_eq(economy.validate(), [] as Array[String], "Limitação conhecida, não é inconsistência.")
	world.teardown()


func test_the_expired_state_survives_the_save() -> void:
	var parts: Array = _world()
	var world: World = parts[0]
	var economy: EconomyModule = parts[1]
	var contract_id: int = _labor(economy, 2 * MINUTES_PER_HOUR)
	_run_minutes(world, 2 * MINUTES_PER_HOUR)
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
	assert_eq([copy.peek_contract(contract_id).state, copy.peek_balance(contract_id).balance, copy.validate()], ["expired", 0, [] as Array[String]])
	world.teardown()
	other_world.teardown()
