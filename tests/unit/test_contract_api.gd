extends GutTest
## LW-096 (parte b): a porta dos contratos da economia (docs/modules/economy.md, seção 8): `request_post_contract`, `request_accept_contract`, `peek_contract` e `peek_contracts`, e o evento `ContractOffered` (classe em `economy/api/`). Economia REAL
## (data/economy) com um posto de `guard` em `a_work_05` (definição montada à mão) para o local de trabalho do `labor` e NPCs reais abertos pela porta (saldo inicial 60). Postar retém a recompensa na custódia (conta do tipo `contract`) e publica UM
## `ContractOffered`; as recusas não mudam nada e não publicam; aceitar só `open`; o filtro da consulta; o bloco `contracts` do save (só quando há contratos).

const SEED: int = 73
const MINUTES_PER_HOUR: int = 60
const SETTLEMENT_A: String = "test_settlement_a"
const PLACE_POST: String = "a_work_05"
const ISSUER: int = 100
const WORKER: int = 101
const OTHER: int = 102
const REWARD: int = 25
const NPC_START_MONEY: int = 60
const DEADLINE_MINUTES: int = 600


func _definitions() -> EconomyDefinitions:
	var setup: EconomySetup = EconomySetup.from_dir(EconomySetup.DEFAULT_DIR)
	assert_true(setup.result.ok, setup.result.message)
	var definitions: EconomyDefinitions = setup.definitions
	var posts: Array[PostDef] = [PostDef.new("post_a_guard", SETTLEMENT_A, PLACE_POST, "guard", 8, 3)]
	definitions.service_posts = posts
	return definitions


## Mundo com a economia e três NPCs com conta. Devolve [world, economy].
func _world() -> Array:
	var economy: EconomyModule = EconomyModule.new(false, _definitions())
	var clock: SimClock = SimClock.new()
	var world: World = World.new(SimContext.new(clock, EventBus.new(clock), WorldRng.new(SEED), IdGenerator.new()))
	assert_true(world.register_module("economy", economy).ok)
	world.setup()
	world.post_setup()
	world.on_new_game(SEED)
	for npc_id: int in [ISSUER, WORKER, OTHER]:
		assert_true(economy.request_open_owner(npc_id, "npc").ok)
	return [world, economy]


func _labor(minutes: int = 30) -> Dictionary:
	return {"place_id": PLACE_POST, "minutes": minutes}


func _delivery() -> Dictionary:
	return {"good_id": "grain", "quantity": 3, "destination_id": OTHER}


func _offers(world: World) -> Array[ContractOffered]:
	var offers: Array[ContractOffered] = []
	world.context.events.subscribe("ContractOffered", func(event: SimEvent) -> void: offers.append(event))
	return offers


func test_posting_a_labor_contract_retains_the_reward_and_publishes_one_offer() -> void:
	var parts: Array = _world()
	var world: World = parts[0]
	var economy: EconomyModule = parts[1]
	var offers: Array[ContractOffered] = _offers(world)
	var posted: EconomyReplies.PostContractResult = economy.request_post_contract("labor", ISSUER, REWARD, DEADLINE_MINUTES, _labor())
	assert_true(posted.result.ok, posted.result.message)
	assert_ne(posted.contract_id, IdGenerator.NO_ID)
	world.context.events.dispatch()
	assert_eq(offers.size(), 1)
	assert_eq([offers[0].contract_id, offers[0].kind, offers[0].issuer_id, offers[0].reward, offers[0].deadline], [posted.contract_id, "labor", ISSUER, REWARD, DEADLINE_MINUTES])
	assert_eq([economy.peek_balance(ISSUER).balance, economy.peek_balance(posted.contract_id).balance], [NPC_START_MONEY - REWARD, REWARD], "A recompensa saiu do emissor e está na custódia.")
	var contract: EconomyReplies.ContractQuery = economy.peek_contract(posted.contract_id)
	assert_true(contract.result.ok)
	assert_eq([contract.kind, contract.issuer_id, contract.reward, contract.deadline, contract.state, contract.acceptor_id, contract.place_id, contract.minutes], ["labor", ISSUER, REWARD, DEADLINE_MINUTES, "open", IdGenerator.NO_ID, PLACE_POST, 30])
	assert_true(economy.peek_conservation().ok)
	assert_eq(economy.validate(), [] as Array[String])
	world.teardown()


func test_posting_a_delivery_contract_shows_the_good_the_quantity_and_the_destination() -> void:
	var parts: Array = _world()
	var world: World = parts[0]
	var economy: EconomyModule = parts[1]
	var posted: EconomyReplies.PostContractResult = economy.request_post_contract("delivery", ISSUER, REWARD, DEADLINE_MINUTES, _delivery())
	assert_true(posted.result.ok, posted.result.message)
	var contract: EconomyReplies.ContractQuery = economy.peek_contract(posted.contract_id)
	assert_eq([contract.kind, contract.good_id, contract.quantity, contract.destination_id, contract.place_id], ["delivery", "grain", 3, OTHER, ""], "O objetivo de cada tipo, o resto vazio.")
	world.teardown()


func test_a_refused_contract_changes_nothing_publishes_nothing_and_the_module_without_setup_posts_nothing() -> void:
	var parts: Array = _world()
	var world: World = parts[0]
	var economy: EconomyModule = parts[1]
	var offers: Array[ContractOffered] = _offers(world)
	var balance_before: int = economy.peek_balance(ISSUER).balance
	var refusals: Array[Array] = [
		[economy.request_post_contract("labor", 999, REWARD, DEADLINE_MINUTES, _labor()), EconomyCodes.UNKNOWN_OWNER],
		[economy.request_post_contract("labor", ISSUER, 0, DEADLINE_MINUTES, _labor()), EconomyCodes.BAD_AMOUNT],
		[economy.request_post_contract("labor", ISSUER, REWARD, 0, _labor()), EconomyCodes.CONTRACT_IMPOSSIBLE],
		[economy.request_post_contract("labor", ISSUER, REWARD, DEADLINE_MINUTES, {"place_id": "nowhere", "minutes": 30}), EconomyCodes.CONTRACT_IMPOSSIBLE],
		[economy.request_post_contract("delivery", ISSUER, REWARD, DEADLINE_MINUTES, {"good_id": "grain", "quantity": 0, "destination_id": OTHER}), EconomyCodes.CONTRACT_IMPOSSIBLE],
		[economy.request_post_contract("labor", ISSUER, NPC_START_MONEY + 1, DEADLINE_MINUTES, _labor()), EconomyCodes.INSUFFICIENT_FUNDS],
		[economy.request_post_contract("vacancy", ISSUER, REWARD, DEADLINE_MINUTES, _labor()), EconomyCodes.CONTRACT_IMPOSSIBLE],
	]
	for refusal: Array in refusals:
		var refused: EconomyReplies.PostContractResult = refusal[0]
		assert_false(refused.result.ok, refused.result.message)
		assert_eq([refused.result.code, refused.contract_id], [refusal[1], IdGenerator.NO_ID], refused.result.message)
	world.context.events.dispatch()
	assert_eq([offers.size(), economy.peek_balance(ISSUER).balance, economy.peek_contracts().contracts.size()], [0, balance_before, 0], "Nada saiu, nada mudou, nenhum contrato.")
	var lone: EconomyModule = EconomyModule.new(false, _definitions())
	var lone_post: EconomyReplies.PostContractResult = lone.request_post_contract("labor", ISSUER, REWARD, DEADLINE_MINUTES, _labor())
	assert_eq([lone_post.result.ok, lone_post.result.code], [false, EconomyCodes.CONTRACT_IMPOSSIBLE], "Sem `setup` não há relógio nem IDs.")
	world.teardown()


func test_accepting_follows_the_book_rules_through_the_door() -> void:
	var parts: Array = _world()
	var world: World = parts[0]
	var economy: EconomyModule = parts[1]
	var contract_id: int = economy.request_post_contract("labor", ISSUER, REWARD, DEADLINE_MINUTES, _labor()).contract_id
	assert_eq(economy.request_accept_contract(999, WORKER).code, EconomyCodes.UNKNOWN_CONTRACT)
	assert_eq(economy.request_accept_contract(contract_id, ISSUER).code, EconomyCodes.CONTRACT_IMPOSSIBLE, "O emissor não aceita o próprio contrato.")
	assert_true(economy.request_accept_contract(contract_id, WORKER).ok)
	var contract: EconomyReplies.ContractQuery = economy.peek_contract(contract_id)
	assert_eq([contract.state, contract.acceptor_id], ["accepted", WORKER])
	assert_eq(economy.request_accept_contract(contract_id, OTHER).code, EconomyCodes.CONTRACT_NOT_OPEN)
	assert_eq(economy.peek_contract(999).result.code, EconomyCodes.UNKNOWN_CONTRACT)
	world.teardown()


func test_the_filter_selects_by_state_issuer_and_place_and_the_rows_come_by_id() -> void:
	var parts: Array = _world()
	var world: World = parts[0]
	var economy: EconomyModule = parts[1]
	var first: int = economy.request_post_contract("labor", ISSUER, 10, DEADLINE_MINUTES, _labor()).contract_id
	var second: int = economy.request_post_contract("delivery", WORKER, 10, DEADLINE_MINUTES, _delivery()).contract_id
	var third: int = economy.request_post_contract("labor", ISSUER, 10, DEADLINE_MINUTES, _labor(45)).contract_id
	assert_true(economy.request_accept_contract(third, OTHER).ok)
	assert_true(first < second and second < third, "IDs crescentes.")
	var ids: Callable = func(query: EconomyReplies.ContractsQuery) -> Array[int]:
		var found: Array[int] = []
		for row: EconomyReplies.ContractQuery in query.contracts:
			found.append(row.contract_id)
		return found
	assert_eq(ids.call(economy.peek_contracts()), [first, second, third] as Array[int])
	assert_eq(ids.call(economy.peek_contracts("open")), [first, second] as Array[int])
	assert_eq(ids.call(economy.peek_contracts("accepted")), [third] as Array[int])
	assert_eq(ids.call(economy.peek_contracts("", ISSUER)), [first, third] as Array[int])
	assert_eq(ids.call(economy.peek_contracts("", IdGenerator.NO_ID, PLACE_POST)), [first, third] as Array[int])
	assert_eq(ids.call(economy.peek_contracts("open", ISSUER, PLACE_POST)), [first] as Array[int])
	assert_eq(ids.call(economy.peek_contracts("completed")), [] as Array[int])
	world.teardown()


func test_the_contracts_block_goes_to_the_save_only_when_there_are_contracts_and_round_trips() -> void:
	var parts: Array = _world()
	var world: World = parts[0]
	var economy: EconomyModule = parts[1]
	assert_false(economy.serialize().has("contracts"), "Sem contratos o bloco do save não ganha a chave (nem o hash).")
	var contract_id: int = economy.request_post_contract("labor", ISSUER, REWARD, DEADLINE_MINUTES, _labor()).contract_id
	assert_true(economy.request_accept_contract(contract_id, WORKER).ok)
	var saved: Dictionary = economy.serialize()
	assert_true(saved.has("contracts"))
	var parsed: Variant = JSON.parse_string(JSON.stringify(saved))
	assert_eq(typeof(parsed), TYPE_DICTIONARY)
	var data: Dictionary = parsed
	var copy: EconomyModule = EconomyModule.new(false, _definitions())
	var other: Array = [copy]
	var clock: SimClock = SimClock.new()
	var other_world: World = World.new(SimContext.new(clock, EventBus.new(clock), WorldRng.new(SEED), IdGenerator.new()))
	assert_true(other_world.register_module("economy", copy).ok)
	other_world.setup()
	assert_true(copy.on_load(data).ok)
	assert_eq(JSON.stringify(copy.serialize(), "", true, true), JSON.stringify(saved, "", true, true), "Ida e volta sem mudar nada.")
	assert_eq([copy.peek_contract(contract_id).state, copy.peek_contract(contract_id).acceptor_id, copy.validate()], ["accepted", WORKER, [] as Array[String]])
	var broken: Variant = JSON.parse_string(JSON.stringify(saved))
	var broken_block: Dictionary = broken
	broken_block["contracts"]["contracts"][str(contract_id)]["state"] = "gone"
	var refused: Result = copy.on_load(broken_block)
	assert_false(refused.ok)
	assert_eq(refused.code, EconomyCodes.INVALID_SAVE)
	assert_eq(other.size(), 1)
	world.teardown()
	other_world.teardown()
