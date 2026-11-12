extends GutTest
## LW-096 (parte a): o livro de contratos (`ContractBook`; docs/modules/economy.md, seção 8; DEC-165): postar `labor` e `delivery` com a recompensa retida na custódia (dono do tipo `contract`, motivo `contract_escrow`), tudo ou nada; aceitar só
## contrato `open`, um aceitante; o save (ida e volta e recusa de bloco inválido sem mudar nada) e as invariantes (a custódia guarda a recompensa inteira enquanto o contrato está aberto ou aceito). Livros REAIS (dono, `Ledger`, bens reais de data/economy,
## posto de serviço para o local de trabalho conhecido). A conclusão, o prazo e as vagas são das partes seguintes.

const SETTLEMENT_A: String = "test_settlement_a"
const MARKET: int = 1
const ISSUER: int = 10
const WORKER: int = 11
const DESTINATION: int = 12
const POST: int = 5
const PLACE: String = "a_work_05"
const CONTRACT: int = 20
const NOW: int = 100
const DEADLINE: int = 500
const START_MONEY: int = 100
const REWARD: int = 40


class Rig:
	extends RefCounted

	var book: OwnerBook
	var ledger: Ledger
	var goods: GoodsStore
	var contracts: ContractBook


func _rig() -> Rig:
	var loaded_goods: GoodsLoader.LoadResult = GoodsLoader.load_dir(GoodsLoader.DEFAULT_DIR)
	var market: MarketLoader.LoadResult = MarketLoader.load_dir(GoodsLoader.DEFAULT_DIR)
	assert_true(loaded_goods.result.ok and market.result.ok)
	var rig: Rig = Rig.new()
	rig.book = OwnerBook.new()
	for opening: Array in [[MARKET, "market"], [ISSUER, "npc"], [WORKER, "npc"], [DESTINATION, "npc"]]:
		assert_true(rig.book.open_owner(opening[0], opening[1]).ok)
	rig.ledger = Ledger.new(rig.book)
	assert_true(rig.ledger.mint(ISSUER, START_MONEY, Ledger.REASON_GAME_START).ok)
	rig.goods = GoodsStore.new(rig.book, loaded_goods.goods, loaded_goods.kinds)
	var markets: MarketBook = MarketBook.new(rig.book, rig.goods, loaded_goods.goods, market.targets, market.params)
	markets.register_market(SETTLEMENT_A, MARKET)
	var posts: ServicePostBook = ServicePostBook.new(markets, WagePayer.new(rig.book, rig.ledger))
	assert_true(posts.register_post(POST, PostDef.new("post_a_guard", SETTLEMENT_A, PLACE, "guard", 8, 3)).ok)
	rig.contracts = ContractBook.new(rig.book, rig.ledger, rig.goods, null, posts)
	return rig


func _labor(minutes: int = 30) -> Dictionary:
	return {"place_id": PLACE, "minutes": minutes}


func _delivery(quantity: int = 3, destination: int = DESTINATION) -> Dictionary:
	return {"good_id": "grain", "quantity": quantity, "destination_id": destination}


func _snapshot(rig: Rig) -> String:
	return JSON.stringify([rig.book.serialize(), rig.ledger.serialize(), rig.contracts.serialize()], "", true, true)


func test_posting_a_labor_contract_holds_the_reward_in_the_custody_account() -> void:
	var rig: Rig = _rig()
	assert_true(rig.contracts.post(CONTRACT, ContractBook.LABOR, ISSUER, REWARD, DEADLINE, NOW, _labor()).ok)
	assert_eq([rig.ledger.balance_of(ISSUER), rig.ledger.balance_of(CONTRACT)], [START_MONEY - REWARD, REWARD], "A recompensa saiu do emissor e está na custódia.")
	assert_eq([rig.book.kind_of(CONTRACT), rig.contracts.has_contract(CONTRACT), rig.contracts.contract_ids()], ["contract", true, [CONTRACT] as Array[int]])
	var state: Dictionary = rig.contracts.state_of(CONTRACT)
	assert_eq([state["kind"], state["issuer_id"], state["reward"], state["deadline"], state["state"], state["acceptor_id"], state["place_id"], state["minutes"]], ["labor", ISSUER, REWARD, DEADLINE, "open", IdGenerator.NO_ID, PLACE, 30])
	assert_true(rig.ledger.is_conserved(), "Nada foi criado nem destruído.")
	assert_eq(rig.contracts.validate(), [] as Array[String])


func test_posting_a_delivery_contract_keeps_the_good_destination_and_quantity() -> void:
	var rig: Rig = _rig()
	assert_true(rig.contracts.post(CONTRACT, ContractBook.DELIVERY, ISSUER, REWARD, DEADLINE, NOW, _delivery()).ok)
	var state: Dictionary = rig.contracts.state_of(CONTRACT)
	assert_eq([state["kind"], state["good_id"], state["quantity"], state["destination_id"], rig.ledger.balance_of(CONTRACT)], ["delivery", "grain", 3, DESTINATION, REWARD])
	assert_false(state.has("place_id"), "Cada tipo guarda só o objetivo dele.")


func test_an_impossible_or_unfunded_contract_is_refused_and_nothing_changes() -> void:
	var rig: Rig = _rig()
	var before: String = _snapshot(rig)
	var refusals: Array[Array] = [
		[rig.contracts.post(CONTRACT, "labor", 999, REWARD, DEADLINE, NOW, _labor()), EconomyCodes.UNKNOWN_OWNER],
		[rig.contracts.post(CONTRACT, "vacancy", ISSUER, REWARD, DEADLINE, NOW, _labor()), EconomyCodes.CONTRACT_IMPOSSIBLE],
		[rig.contracts.post(CONTRACT, "labor", ISSUER, 0, DEADLINE, NOW, _labor()), EconomyCodes.BAD_AMOUNT],
		[rig.contracts.post(CONTRACT, "labor", ISSUER, REWARD, NOW, NOW, _labor()), EconomyCodes.CONTRACT_IMPOSSIBLE],
		[rig.contracts.post(CONTRACT, "labor", ISSUER, REWARD, DEADLINE, NOW, {"place_id": "nowhere", "minutes": 30}), EconomyCodes.CONTRACT_IMPOSSIBLE],
		[rig.contracts.post(CONTRACT, "labor", ISSUER, REWARD, DEADLINE, NOW, _labor(0)), EconomyCodes.CONTRACT_IMPOSSIBLE],
		[rig.contracts.post(CONTRACT, "labor", ISSUER, REWARD, DEADLINE, NOW, {"place_id": PLACE}), EconomyCodes.CONTRACT_IMPOSSIBLE],
		[rig.contracts.post(CONTRACT, "labor", ISSUER, REWARD, DEADLINE, NOW, {"place_id": 7, "minutes": "x"}), EconomyCodes.CONTRACT_IMPOSSIBLE],
		[rig.contracts.post(CONTRACT, "delivery", ISSUER, REWARD, DEADLINE, NOW, {"good_id": "gold", "quantity": 3, "destination_id": DESTINATION}), EconomyCodes.CONTRACT_IMPOSSIBLE],
		[rig.contracts.post(CONTRACT, "delivery", ISSUER, REWARD, DEADLINE, NOW, _delivery(0)), EconomyCodes.CONTRACT_IMPOSSIBLE],
		[rig.contracts.post(CONTRACT, "delivery", ISSUER, REWARD, DEADLINE, NOW, _delivery(3, 999)), EconomyCodes.CONTRACT_IMPOSSIBLE],
		[rig.contracts.post(CONTRACT, "labor", ISSUER, START_MONEY + 1, DEADLINE, NOW, _labor()), EconomyCodes.INSUFFICIENT_FUNDS],
	]
	for refusal: Array in refusals:
		var refused: Result = refusal[0]
		assert_false(refused.ok, "Deveria recusar: %s" % refused.message)
		assert_eq(refused.code, refusal[1], refused.message)
	assert_eq(_snapshot(rig), before, "Nada mudou: nem conta de custódia, nem dinheiro, nem contrato.")
	assert_false(rig.book.has_owner(CONTRACT))
	assert_true(rig.book.close_owner(ISSUER).ok)
	assert_eq(rig.contracts.post(CONTRACT, "labor", ISSUER, REWARD, DEADLINE, NOW, _labor()).code, EconomyCodes.OWNER_CLOSED, "Emissor fechado (morreu).")
	var again: Rig = _rig()
	assert_true(again.contracts.post(CONTRACT, "labor", ISSUER, REWARD, DEADLINE, NOW, _labor()).ok)
	assert_eq(again.contracts.post(CONTRACT, "labor", ISSUER, REWARD, DEADLINE, NOW, _labor()).code, EconomyCodes.CONTRACT_IMPOSSIBLE, "O mesmo ID de novo.")


func test_only_an_open_contract_is_accepted_and_by_one_open_owner_that_is_not_the_issuer() -> void:
	var rig: Rig = _rig()
	assert_true(rig.contracts.post(CONTRACT, "labor", ISSUER, REWARD, DEADLINE, NOW, _labor()).ok)
	assert_eq(rig.contracts.accept(999, WORKER).code, EconomyCodes.UNKNOWN_CONTRACT)
	assert_eq(rig.contracts.accept(CONTRACT, 999).code, EconomyCodes.UNKNOWN_OWNER)
	assert_eq(rig.contracts.accept(CONTRACT, ISSUER).code, EconomyCodes.CONTRACT_IMPOSSIBLE, "O emissor não aceita o próprio contrato.")
	assert_eq(rig.contracts.state_of(CONTRACT)["state"], "open", "As recusas não mudam o contrato.")
	assert_true(rig.contracts.accept(CONTRACT, WORKER).ok)
	var state: Dictionary = rig.contracts.state_of(CONTRACT)
	assert_eq([state["state"], state["acceptor_id"]], ["accepted", WORKER])
	assert_eq(rig.contracts.accept(CONTRACT, DESTINATION).code, EconomyCodes.CONTRACT_NOT_OPEN, "Um aceitante só.")
	assert_eq(rig.ledger.balance_of(CONTRACT), REWARD, "A custódia segue inteira depois de aceito.")
	assert_true(rig.book.close_owner(DESTINATION).ok)
	var other: Rig = _rig()
	assert_true(other.contracts.post(CONTRACT, "labor", ISSUER, REWARD, DEADLINE, NOW, _labor()).ok)
	assert_true(other.book.close_owner(WORKER).ok)
	assert_eq(other.contracts.accept(CONTRACT, WORKER).code, EconomyCodes.OWNER_CLOSED, "Aceitante fechado (morreu).")


func test_the_save_round_trips_and_a_bad_block_is_refused_without_changing_the_book() -> void:
	var rig: Rig = _rig()
	assert_true(rig.contracts.is_pristine())
	assert_true(rig.contracts.post(CONTRACT, "labor", ISSUER, REWARD, DEADLINE, NOW, _labor()).ok)
	assert_true(rig.contracts.post(CONTRACT + 1, "delivery", ISSUER, 10, DEADLINE, NOW, _delivery()).ok)
	assert_true(rig.contracts.accept(CONTRACT + 1, WORKER).ok)
	assert_false(rig.contracts.is_pristine())
	var saved: Dictionary = rig.contracts.serialize()
	var parsed: Variant = JSON.parse_string(JSON.stringify(saved))
	assert_eq(typeof(parsed), TYPE_DICTIONARY)
	var data: Dictionary = parsed
	var copy: Rig = _rig()
	assert_true(copy.contracts.load_from(data).ok)
	assert_eq(JSON.stringify(copy.contracts.serialize(), "", true, true), JSON.stringify(saved, "", true, true), "Ida e volta sem mudar nada.")
	var before: String = JSON.stringify(copy.contracts.serialize(), "", true, true)
	var breaks: Array[Callable] = [
		func(block: Dictionary) -> void: block["contracts"][str(CONTRACT)]["kind"] = "gift",
		func(block: Dictionary) -> void: block["contracts"][str(CONTRACT)]["state"] = "done",
		func(block: Dictionary) -> void: block["contracts"][str(CONTRACT)]["reward"] = -1,
		func(block: Dictionary) -> void: block["contracts"][str(CONTRACT)].erase("minutes"),
		func(block: Dictionary) -> void: block["contracts"][str(CONTRACT)]["place_id"] = 7,
		func(block: Dictionary) -> void: block["contracts"]["0"] = block["contracts"][str(CONTRACT)],
		func(block: Dictionary) -> void: block.erase("contracts"),
	]
	for index: int in breaks.size():
		var broken_parsed: Variant = JSON.parse_string(JSON.stringify(saved))
		var broken: Dictionary = broken_parsed
		breaks[index].call(broken)
		var refused: Result = copy.contracts.load_from(broken)
		assert_false(refused.ok, "Bloco inválido nº %d deveria ser recusado." % index)
		assert_eq(refused.code, EconomyCodes.INVALID_SAVE)
		assert_eq(JSON.stringify(copy.contracts.serialize(), "", true, true), before, "Recusou sem mudar o livro (nº %d)." % index)


func test_validate_finds_a_custody_that_does_not_hold_the_reward() -> void:
	var rig: Rig = _rig()
	assert_true(rig.contracts.post(CONTRACT, "labor", ISSUER, REWARD, DEADLINE, NOW, _labor()).ok)
	assert_eq(rig.contracts.validate(), [] as Array[String])
	assert_true(rig.ledger.transfer(CONTRACT, ISSUER, 5, Ledger.REASON_CONTRACT_REFUND).ok)
	var problems: Array[String] = rig.contracts.validate()
	assert_eq(problems.size(), 1)
	assert_string_contains(problems[0], "deveria ter %d na custódia e tem %d" % [REWARD, REWARD - 5])
