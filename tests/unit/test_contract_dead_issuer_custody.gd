extends GutTest
## LW-096n (decisão de Arthur de 12/11/2026, opção B): o contrato `labor` ou `delivery` que vence com o emissor MORTO não deixa mais a custódia retida: ela vai para a conta do MERCADO do povoado do contrato (`contract_refund`, só inteiros, só pelo
## `Ledger`, sem queimar nada, sem evento nem motivo novos). O povoado do contrato é o do local de trabalho (`labor`: local de produção ou posto) ou o do destino (`delivery`: o mercado ou o local de produção de destino); destino que a economia não
## liga a um povoado (um NPC) deixa a custódia retida, a limitação [LIM] que sobra. Emissor vivo: nada muda (a custódia volta a ele). Economia REAL (data/economy, 3 povoados, locais de produção de LW-097) e NPCs reais (saldo inicial 60).

const SEED: int = 109
const MINUTES_PER_HOUR: int = 60
const SETTLEMENT_A: String = "test_settlement_a"
const SETTLEMENT_B: String = "test_settlement_b"
const PLACE_B: String = "b_work_01"
const PLACE_B_OTHER: String = "b_work_02"
const GOOD: String = "grain"
const ISSUER: int = 100
const WORKER: int = 101
const NPC_DESTINATION: int = 102
const REWARD: int = 25
const NPC_START_MONEY: int = 60
const DEADLINE_HOURS: int = 2


func _definitions() -> EconomyDefinitions:
	var setup: EconomySetup = EconomySetup.from_dir(EconomySetup.DEFAULT_DIR)
	assert_true(setup.result.ok, setup.result.message)
	return setup.definitions


func _world() -> Array:
	var economy: EconomyModule = EconomyModule.new(false, _definitions())
	var clock: SimClock = SimClock.new()
	var world: World = World.new(SimContext.new(clock, EventBus.new(clock), WorldRng.new(SEED), IdGenerator.new()))
	assert_true(world.register_module("economy", economy).ok)
	world.setup()
	world.post_setup()
	world.on_new_game(SEED)
	for npc_id: int in [ISSUER, WORKER, NPC_DESTINATION]:
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


func _kill_issuer(world: World) -> void:
	world.context.events.publish(NpcDied.new(ISSUER, "test", 0))
	world.context.events.dispatch()


func _market(economy: EconomyModule, settlement_id: String) -> int:
	return economy.peek_market_of(settlement_id).market_id


func _balance(economy: EconomyModule, owner_id: int) -> int:
	return economy.peek_balance(owner_id).balance


func _labor(economy: EconomyModule, place_id: String) -> int:
	var posted: EconomyReplies.PostContractResult = economy.request_post_contract("labor", ISSUER, REWARD, DEADLINE_HOURS * MINUTES_PER_HOUR, {"place_id": place_id, "minutes": 30})
	assert_true(posted.result.ok, posted.result.message)
	return posted.contract_id


func _delivery(economy: EconomyModule, destination_id: int) -> int:
	var posted: EconomyReplies.PostContractResult = economy.request_post_contract("delivery", ISSUER, REWARD, DEADLINE_HOURS * MINUTES_PER_HOUR, {"good_id": GOOD, "quantity": 1, "destination_id": destination_id})
	assert_true(posted.result.ok, posted.result.message)
	return posted.contract_id


func _assert_books_close(economy: EconomyModule) -> void:
	assert_true(economy.peek_conservation().ok, "O dinheiro continua contado.")
	assert_eq(economy.validate(), [] as Array[String], "Nenhum problema nos livros.")


func test_a_live_issuer_still_gets_the_custody_back_and_the_markets_do_not_move() -> void:
	var parts: Array = _world()
	var world: World = parts[0]
	var economy: EconomyModule = parts[1]
	var market_a: int = _market(economy, SETTLEMENT_A)
	var market_b: int = _market(economy, SETTLEMENT_B)
	var markets_before: Array[int] = [_balance(economy, market_a), _balance(economy, market_b)]
	var contract_id: int = _labor(economy, PLACE_B)
	_run_minutes(world, DEADLINE_HOURS * MINUTES_PER_HOUR)
	assert_eq([economy.peek_contract(contract_id).state, _balance(economy, contract_id), _balance(economy, ISSUER)], ["expired", 0, NPC_START_MONEY], "A custódia voltou inteira ao emissor vivo.")
	assert_eq([_balance(economy, market_a), _balance(economy, market_b)], markets_before, "Nenhum mercado recebeu nada.")
	_assert_books_close(economy)
	world.teardown()


func test_a_dead_issuer_labor_custody_goes_to_the_market_of_the_work_place_settlement() -> void:
	var parts: Array = _world()
	var world: World = parts[0]
	var economy: EconomyModule = parts[1]
	var failed: Array[ContractFailed] = _failures(world)
	var market_a: int = _market(economy, SETTLEMENT_A)
	var market_b: int = _market(economy, SETTLEMENT_B)
	var markets_before: Array[int] = [_balance(economy, market_a), _balance(economy, market_b)]
	var contract_id: int = _labor(economy, PLACE_B)
	_kill_issuer(world)
	_run_minutes(world, DEADLINE_HOURS * MINUTES_PER_HOUR)
	assert_eq([economy.peek_contract(contract_id).state, _balance(economy, contract_id), failed.size()], ["expired", 0, 1], "O contrato vence, o evento de sempre sai e a custódia esvazia.")
	assert_eq([_balance(economy, market_a), _balance(economy, market_b)], [markets_before[0], markets_before[1] + REWARD], "O mercado do povoado B (o do local de trabalho) recebeu a recompensa; o do A não.")
	_assert_books_close(economy)
	world.teardown()


func test_a_dead_issuer_delivery_custody_goes_to_the_market_of_the_destination_settlement() -> void:
	var parts: Array = _world()
	var world: World = parts[0]
	var economy: EconomyModule = parts[1]
	var market_a: int = _market(economy, SETTLEMENT_A)
	var market_b: int = _market(economy, SETTLEMENT_B)
	var markets_before: Array[int] = [_balance(economy, market_a), _balance(economy, market_b)]
	var contract_id: int = _delivery(economy, market_b)
	_kill_issuer(world)
	_run_minutes(world, DEADLINE_HOURS * MINUTES_PER_HOUR)
	assert_eq([economy.peek_contract(contract_id).state, _balance(economy, contract_id)], ["expired", 0])
	assert_eq([_balance(economy, market_a), _balance(economy, market_b)], [markets_before[0], markets_before[1] + REWARD], "O destino é o mercado do povoado B: a recompensa fica lá.")
	_assert_books_close(economy)
	world.teardown()


func test_a_dead_issuer_delivery_to_a_production_site_goes_to_the_market_of_the_site_settlement() -> void:
	var parts: Array = _world()
	var world: World = parts[0]
	var economy: EconomyModule = parts[1]
	var site_id: int = economy.peek_site_at(PLACE_B_OTHER).workplace_id
	var market_b: int = _market(economy, SETTLEMENT_B)
	var before: int = _balance(economy, market_b)
	var contract_id: int = _delivery(economy, site_id)
	_kill_issuer(world)
	_run_minutes(world, DEADLINE_HOURS * MINUTES_PER_HOUR)
	assert_eq([_balance(economy, contract_id), _balance(economy, market_b)], [0, before + REWARD], "O local de produção de destino é do povoado B.")
	_assert_books_close(economy)
	world.teardown()


func test_a_dead_issuer_accepted_contract_that_expires_also_goes_to_the_market() -> void:
	var parts: Array = _world()
	var world: World = parts[0]
	var economy: EconomyModule = parts[1]
	var market_b: int = _market(economy, SETTLEMENT_B)
	var before: int = _balance(economy, market_b)
	var contract_id: int = _labor(economy, PLACE_B)
	assert_true(economy.request_accept_contract(contract_id, WORKER).ok)
	_kill_issuer(world)
	_run_minutes(world, DEADLINE_HOURS * MINUTES_PER_HOUR)
	assert_eq([economy.peek_contract(contract_id).state, _balance(economy, contract_id), _balance(economy, market_b), _balance(economy, WORKER)], ["expired", 0, before + REWARD, NPC_START_MONEY], "Aceito e vencido: o trabalhador não recebe e a recompensa vai para o mercado.")
	_assert_books_close(economy)
	world.teardown()


func test_a_dead_issuer_delivery_to_an_npc_keeps_the_custody_because_the_settlement_is_unknown() -> void:
	var parts: Array = _world()
	var world: World = parts[0]
	var economy: EconomyModule = parts[1]
	var market_a: int = _market(economy, SETTLEMENT_A)
	var market_b: int = _market(economy, SETTLEMENT_B)
	var markets_before: Array[int] = [_balance(economy, market_a), _balance(economy, market_b)]
	var contract_id: int = _delivery(economy, NPC_DESTINATION)
	_kill_issuer(world)
	_run_minutes(world, DEADLINE_HOURS * MINUTES_PER_HOUR)
	assert_eq([economy.peek_contract(contract_id).state, _balance(economy, contract_id)], ["expired", REWARD], "[LIM] A economia não sabe o povoado de um NPC: a recompensa continua na conta do contrato.")
	assert_eq([_balance(economy, market_a), _balance(economy, market_b)], markets_before, "Nenhum mercado recebeu nada.")
	_assert_books_close(economy)
	world.teardown()


func test_the_refund_to_the_market_survives_the_save() -> void:
	var parts: Array = _world()
	var world: World = parts[0]
	var economy: EconomyModule = parts[1]
	var market_b: int = _market(economy, SETTLEMENT_B)
	var contract_id: int = _labor(economy, PLACE_B)
	_kill_issuer(world)
	_run_minutes(world, DEADLINE_HOURS * MINUTES_PER_HOUR)
	var parsed: Variant = JSON.parse_string(JSON.stringify(economy.serialize()))
	assert_eq(typeof(parsed), TYPE_DICTIONARY)
	var data: Dictionary = parsed
	var copy: EconomyModule = EconomyModule.new(false, _definitions())
	var clock: SimClock = SimClock.new()
	var other_world: World = World.new(SimContext.new(clock, EventBus.new(clock), WorldRng.new(SEED), IdGenerator.new()))
	assert_true(other_world.register_module("economy", copy).ok)
	other_world.setup()
	assert_true(copy.on_load(data).ok)
	assert_eq([copy.peek_contract(contract_id).state, _balance(copy, contract_id), _balance(copy, market_b)], ["expired", 0, _balance(economy, market_b)])
	_assert_books_close(copy)
	world.teardown()
	other_world.teardown()


## O `validate()` só tolera custódia retida de emissor morto quando a economia NÃO conhece o povoado: um save adulterado que deixa a recompensa retida num contrato de povoado conhecido (a de um `labor` em `b_work_01`) é apontado.
func test_validate_flags_a_retained_custody_when_the_settlement_is_known() -> void:
	var parts: Array = _world()
	var world: World = parts[0]
	var economy: EconomyModule = parts[1]
	var market_b: int = _market(economy, SETTLEMENT_B)
	var contract_id: int = _labor(economy, PLACE_B)
	_kill_issuer(world)
	_run_minutes(world, DEADLINE_HOURS * MINUTES_PER_HOUR)
	var parsed: Variant = JSON.parse_string(JSON.stringify(economy.serialize()))
	assert_eq(typeof(parsed), TYPE_DICTIONARY)
	var data: Dictionary = parsed
	var balances: Dictionary = (data["ledger"] as Dictionary)["balances"]
	balances[str(contract_id)] = int(balances.get(str(contract_id), 0)) + REWARD
	balances[str(market_b)] = int(balances[str(market_b)]) - REWARD
	var copy: EconomyModule = EconomyModule.new(false, _definitions())
	var clock: SimClock = SimClock.new()
	var other_world: World = World.new(SimContext.new(clock, EventBus.new(clock), WorldRng.new(SEED), IdGenerator.new()))
	assert_true(other_world.register_module("economy", copy).ok)
	other_world.setup()
	assert_true(copy.on_load(data).ok)
	var problems: Array[String] = copy.validate()
	assert_eq(problems.size(), 1, "Um problema só: o do contrato.")
	assert_true(problems.size() == 1 and problems[0].contains("o contrato %d" % contract_id), "O problema aponta o contrato.")
	world.teardown()
	other_world.teardown()
