extends GutTest
## LW-096 (R13-I1 e R14-I1): `request_post_contract` NUNCA gasta ID quando recusa (docs/modules/economy.md, seção 8): a validação (`ContractBook.check_post`) vem ANTES de pedir o ID ao `core`, e os IDs não se reutilizam, então uma recusa que gastasse ID
## deixaria um buraco na numeração para sempre. Aqui o contador de IDs do mundo (`ids.serialize()`) é comparado antes e depois de cada recusa (as mesmas do teste da porta) e depois de um post que dá certo (gasta exatamente UM). Economia REAL com
## um posto de `guard` em `a_work_05` (montado à mão) e NPCs reais (saldo inicial 60).

const SEED: int = 101
const SETTLEMENT_A: String = "test_settlement_a"
const PLACE_POST: String = "a_work_05"
const ISSUER: int = 100
const OTHER: int = 101
const REWARD: int = 25
const DEADLINE: int = 600


func _world() -> Array:
	var setup: EconomySetup = EconomySetup.from_dir(EconomySetup.DEFAULT_DIR)
	assert_true(setup.result.ok, setup.result.message)
	var definitions: EconomyDefinitions = setup.definitions
	var posts: Array[PostDef] = [PostDef.new("post_a_guard", SETTLEMENT_A, PLACE_POST, "guard", 8, 3)]
	definitions.service_posts = posts
	var economy: EconomyModule = EconomyModule.new(false, definitions)
	var clock: SimClock = SimClock.new()
	var world: World = World.new(SimContext.new(clock, EventBus.new(clock), WorldRng.new(SEED), IdGenerator.new()))
	assert_true(world.register_module("economy", economy).ok)
	world.setup()
	world.post_setup()
	world.on_new_game(SEED)
	for npc_id: int in [ISSUER, OTHER]:
		assert_true(economy.request_open_owner(npc_id, "npc").ok)
	return [world, economy]


func _ids(world: World) -> String:
	return JSON.stringify(world.context.ids.serialize(), "", true, true)


func test_every_refusal_leaves_the_id_counter_untouched_and_a_post_that_works_spends_exactly_one() -> void:
	var parts: Array = _world()
	var world: World = parts[0]
	var economy: EconomyModule = parts[1]
	var labor: Dictionary = {"place_id": PLACE_POST, "minutes": 30}
	var refusals: Array[Callable] = [
		func() -> EconomyReplies.PostContractResult: return economy.request_post_contract("labor", 999, REWARD, DEADLINE, labor),
		func() -> EconomyReplies.PostContractResult: return economy.request_post_contract("labor", ISSUER, 0, DEADLINE, labor),
		func() -> EconomyReplies.PostContractResult: return economy.request_post_contract("labor", ISSUER, REWARD, 0, labor),
		func() -> EconomyReplies.PostContractResult: return economy.request_post_contract("labor", ISSUER, REWARD, DEADLINE, {"place_id": "nowhere", "minutes": 30}),
		func() -> EconomyReplies.PostContractResult: return economy.request_post_contract("delivery", ISSUER, REWARD, DEADLINE, {"good_id": "grain", "quantity": 0, "destination_id": OTHER}),
		func() -> EconomyReplies.PostContractResult: return economy.request_post_contract("labor", ISSUER, 61, DEADLINE, labor),
		func() -> EconomyReplies.PostContractResult: return economy.request_post_contract("vacancy", ISSUER, REWARD, DEADLINE, labor),
	]
	for index: int in refusals.size():
		var before: String = _ids(world)
		var refused: EconomyReplies.PostContractResult = refusals[index].call()
		assert_false(refused.result.ok, "A recusa nº %d deveria recusar." % index)
		assert_eq(_ids(world), before, "A recusa nº %d não gastou ID (%s)." % [index, refused.result.code])
	var counter_before: int = world.context.ids.serialize().values()[0]
	var posted: EconomyReplies.PostContractResult = economy.request_post_contract("labor", ISSUER, REWARD, DEADLINE, labor)
	assert_true(posted.result.ok, posted.result.message)
	assert_eq(posted.contract_id, counter_before, "O contrato leva o próximo ID que havia, sem buraco das recusas anteriores.")
	assert_eq(world.context.ids.serialize().values()[0], counter_before + 1, "Postar gasta exatamente UM ID.")
	world.teardown()


func test_the_book_validation_alone_changes_nothing_and_matches_the_post_codes() -> void:
	var parts: Array = _world()
	var world: World = parts[0]
	var economy: EconomyModule = parts[1]
	var issuer_balance: int = economy.peek_balance(ISSUER).balance
	var contracts_before: int = economy.peek_contracts().contracts.size()
	var ledger_before: String = JSON.stringify(economy.serialize(), "", true, true)
	var ok_check: Result = economy.request_post_contract("labor", ISSUER, REWARD, DEADLINE, {"place_id": PLACE_POST, "minutes": 30}).result
	assert_true(ok_check.ok)
	assert_eq(economy.peek_balance(ISSUER).balance, issuer_balance - REWARD)
	var refused: EconomyReplies.PostContractResult = economy.request_post_contract("labor", ISSUER, 1000, DEADLINE, {"place_id": PLACE_POST, "minutes": 30})
	assert_eq(refused.result.code, EconomyCodes.INSUFFICIENT_FUNDS, "O código da recusa é o mesmo de antes da separação.")
	assert_eq([economy.peek_balance(ISSUER).balance, economy.peek_contracts().contracts.size()], [issuer_balance - REWARD, contracts_before + 1], "A recusa não mexeu em dinheiro nem em contrato.")
	assert_ne(JSON.stringify(economy.serialize(), "", true, true), ledger_before, "O post que deu certo mexeu no estado, a recusa depois dele não.")
	world.teardown()
