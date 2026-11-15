extends GutTest
## LW-107c2 (C5): o postador de contratos de entrega (`ContractPoster`; docs/modules/economy.md, seção 8): a cada hora cheia, por mercado e por modelo, a economia posta UM contrato `delivery` (emissor e destino: o mercado) com a recompensa
## `ceil_div(quantity x base_value x (10000 + reward_margin_bp), 10000)`; não repete enquanto há um aberto ou aceito e reposta depois que ele termina; só posta com o gatilho valendo (`shortage` pede a escassez DECLARADA) e sem a recompensa passar
## do `ask` de hoje vezes a quantidade (regra (b)); a recusa do livro (mercado sem fundos) não gasta ID; o contrato postado não é cancelado quando a escassez acaba; mesma semente, mesmo mundo; salvar e carregar não repete contrato.
## Economia REAL (mercados dos dados, SEM locais de produção nem postos: só o postador mexe em contrato) com os modelos que o PRÓPRIO TESTE monta; o arquivo padrão do jogo não entra aqui.

const SEED: int = 107
const MINUTES_PER_HOUR: int = 60
const DEADLINE_HOURS: int = 48
const HOURS_PER_DAY: int = 24
const SHORTAGE_DAYS: int = 10
const SETTLEMENT_A: String = "test_settlement_a"
const ACTOR: int = 5000
const LOT: int = 5
const POOR_MARKET_BALANCE: int = 50


func _typed(templates: Array) -> Array[ContractTemplateDef]:
	var typed: Array[ContractTemplateDef] = []
	typed.assign(templates)
	return typed


func _bread_standing(margin_bp: int = 500) -> ContractTemplateDef:
	return ContractTemplateDef.new("bread_standing", ContractBook.DELIVERY, "bread", LOT, ContractTemplateDef.TRIGGER_STANDING, margin_bp, DEADLINE_HOURS, 1)


func _grain_shortage() -> ContractTemplateDef:
	return ContractTemplateDef.new("grain_shortage", ContractBook.DELIVERY, "grain", 10, ContractTemplateDef.TRIGGER_SHORTAGE, 2500, DEADLINE_HOURS, 1)


## `market_money` (se 0 ou mais) troca o saldo inicial do tipo `market`; `new_game` falso monta o mundo para receber um save.
func _world(templates: Array, market_money: int = -1, new_game: bool = true) -> Array:
	var setup: EconomySetup = EconomySetup.from_dir(EconomySetup.DEFAULT_DIR)
	assert_true(setup.result.ok, setup.result.message)
	var definitions: EconomyDefinitions = setup.definitions
	definitions.is_development_build = true
	var no_sites: Array[SiteDef] = []
	definitions.production_sites = no_sites
	var no_posts: Array[PostDef] = []
	definitions.service_posts = no_posts
	definitions.contract_templates = _typed(templates)
	for kind: OwnerKindDef in definitions.kinds:
		if kind.id == MarketBook.KIND_MARKET and market_money >= 0:
			kind.initial_balance = market_money
	var economy: EconomyModule = EconomyModule.new(false, definitions)
	var clock: SimClock = SimClock.new()
	var world: World = World.new(SimContext.new(clock, EventBus.new(clock), WorldRng.new(SEED), IdGenerator.new()))
	assert_true(world.register_module("economy", economy).ok)
	world.setup()
	world.post_setup()
	if new_game:
		world.on_new_game(SEED)
	return [world, economy]


func _run_hours(world: World, hours: int) -> void:
	for _minute: int in hours * MINUTES_PER_HOUR:
		world.context.clock.advance_step()
		world.tick(1)
		world.context.events.dispatch()


func _offers(world: World) -> Array[ContractOffered]:
	var offers: Array[ContractOffered] = []
	world.context.events.subscribe("ContractOffered", func(event: SimEvent) -> void: offers.append(event))
	return offers


func _ids(world: World) -> String:
	return JSON.stringify(world.context.ids.serialize(), "", true, true)


func _contracts(economy: EconomyModule, state_name: String = "", issuer_id: int = IdGenerator.NO_ID) -> Array:
	return economy.peek_contracts(state_name, issuer_id).contracts


func _moved(economy: EconomyModule, reason: String) -> int:
	for row: Dictionary in economy.peek_ledger_totals().rows:
		if row["reason"] == reason:
			return int(row["moved"])
	return 0


func test_it_posts_one_contract_per_market_with_the_reward_of_the_formula_and_the_offer_event() -> void:
	var parts: Array = _world([_bread_standing()])
	var world: World = parts[0]
	var economy: EconomyModule = parts[1]
	var offers: Array[ContractOffered] = _offers(world)
	var before: Dictionary[int, int] = {}
	for settlement_id: String in ["test_settlement_a", "test_settlement_b", "test_settlement_c"]:
		var market_id: int = economy.peek_market_of(settlement_id).market_id
		before[market_id] = economy.peek_balance(market_id).balance
	assert_eq(_contracts(economy).size(), 0, "Nada é postado antes da primeira hora cheia.")
	_run_hours(world, 1)
	var reward: int = PriceMath.ceil_div(LOT * 10 * (PriceMath.BASIS + 500), PriceMath.BASIS)
	assert_eq(reward, 53, "A conta do contrato: 5 pães de 10, mais 5%.")
	var rows: Array = _contracts(economy)
	assert_eq(rows.size(), 3, "Um contrato por mercado.")
	var issuers: Array[int] = []
	for row: EconomyReplies.ContractQuery in rows:
		issuers.append(row.issuer_id)
		assert_eq([row.kind, row.state, row.good_id, row.quantity, row.destination_id, row.reward, row.deadline], ["delivery", "open", "bread", LOT, row.issuer_id, reward, (1 + DEADLINE_HOURS) * MINUTES_PER_HOUR], "Contrato do mercado %d." % row.issuer_id)
		assert_eq(economy.peek_balance(row.issuer_id).balance, before[row.issuer_id] - reward, "A recompensa saiu da conta do mercado para a custódia.")
	var ascending: Array[int] = issuers.duplicate()
	ascending.sort()
	assert_eq(issuers, ascending, "Os IDs dos contratos seguem a ordem dos mercados (ID crescente).")
	assert_eq(offers.size(), 3, "Um ContractOffered por contrato postado.")
	for offer: ContractOffered in offers:
		assert_eq([offer.kind, offer.reward, offer.issuer_id, economy.peek_contract(offer.contract_id).reward], ["delivery", reward, offer.issuer_id, reward])
	assert_eq(_moved(economy, Ledger.REASON_CONTRACT_ESCROW), 3 * reward, "Só custódia: nenhum dinheiro nasceu.")
	assert_true(economy.peek_conservation().ok, "A conservação do dinheiro vale.")
	world.teardown()


func test_it_does_not_repeat_while_open_or_accepted_and_reposts_when_the_contract_ends() -> void:
	var parts: Array = _world([_bread_standing()])
	var world: World = parts[0]
	var economy: EconomyModule = parts[1]
	var market_a: int = economy.peek_market_of(SETTLEMENT_A).market_id
	_run_hours(world, 6)
	assert_eq(_contracts(economy).size(), 3, "Aberto: não repete.")
	var first: int = _contracts(economy, "", market_a)[0].contract_id
	assert_true(economy.request_open_owner(ACTOR, "player").ok)
	assert_true(economy.request_accept_contract(first, ACTOR).ok)
	_run_hours(world, 5)
	assert_eq(_contracts(economy).size(), 3, "Aceito: também não repete.")
	assert_true(economy.request_trade(ACTOR, market_a, "bread", LOT, "buy").result.ok)
	assert_true(economy.request_deliver_contract(first).ok)
	assert_eq(economy.peek_contract(first).state, ContractBook.STATE_COMPLETED)
	_run_hours(world, 1)
	assert_eq(_contracts(economy).size(), 4, "Entregue: o mercado reposta na hora cheia seguinte.")
	assert_eq(_contracts(economy, ContractBook.STATE_OPEN).size(), 3)
	_run_hours(world, 49 - 12)
	assert_eq(_contracts(economy, ContractBook.STATE_EXPIRED).size(), 2, "Os de B e C venceram na hora 49.")
	assert_eq(_contracts(economy, ContractBook.STATE_OPEN).size(), 3, "O vencimento da hora já abriu espaço para o próximo (vagas e postador vêm depois dele).")
	world.teardown()


func test_a_market_without_funds_posts_nothing_and_does_not_spend_ids() -> void:
	var poor: Array = _world([_bread_standing()], POOR_MARKET_BALANCE)
	var baseline: Array = _world([], POOR_MARKET_BALANCE)
	_run_hours(poor[0], 3)
	_run_hours(baseline[0], 3)
	assert_eq(_contracts(poor[1]).size(), 0, "O saldo do mercado (50) não cobre a recompensa (53).")
	assert_eq(_ids(poor[0]), _ids(baseline[0]), "A recusa do livro vem antes do ID: o gerador não avançou.")
	poor[0].teardown()
	baseline[0].teardown()


func test_the_shortage_model_waits_for_the_declared_shortage_and_the_contract_stays_after_it_ends() -> void:
	var parts: Array = _world([_grain_shortage()])
	var world: World = parts[0]
	var economy: EconomyModule = parts[1]
	var market_a: int = economy.peek_market_of(SETTLEMENT_A).market_id
	_run_hours(world, 2)
	assert_eq(_contracts(economy).size(), 0, "Sem escassez, o modelo `shortage` não posta.")
	assert_true(economy.request_set_stock(market_a, "grain", 0).ok)
	_run_hours(world, SHORTAGE_DAYS * HOURS_PER_DAY - 3)
	assert_eq(_contracts(economy).size(), 0, "A escassez só é DECLARADA no décimo fechamento de dia abaixo do limite.")
	_run_hours(world, 1)
	var rows: Array = _contracts(economy)
	assert_eq(rows.size(), 1, "Declarada a escassez, só o mercado em escassez posta.")
	assert_eq([rows[0].issuer_id, rows[0].good_id, rows[0].quantity, rows[0].reward], [market_a, "grain", 10, PriceMath.ceil_div(10 * 4 * (PriceMath.BASIS + 2500), PriceMath.BASIS)])
	assert_true(economy.request_set_stock(market_a, "grain", 120).ok)
	_run_hours(world, 30)
	assert_eq(_contracts(economy, ContractBook.STATE_OPEN).size(), 1, "O contrato não é cancelado quando a escassez acaba, e não nasce outro.")
	world.teardown()


func test_a_reward_above_the_ask_of_the_lot_is_not_posted_and_follows_the_price_of_the_day() -> void:
	var parts: Array = _world([_bread_standing(3000)])
	var baseline: Array = _world([])
	var world: World = parts[0]
	var economy: EconomyModule = parts[1]
	var market_a: int = economy.peek_market_of(SETTLEMENT_A).market_id
	_run_hours(world, 3)
	_run_hours(baseline[0], 3)
	assert_eq(_contracts(economy).size(), 0, "65 passa dos 55 do `ask` do lote no estoque-alvo: não posta.")
	assert_eq(_ids(world), _ids(baseline[0]), "A regra (b) recusa antes de pedir o ID.")
	assert_true(economy.request_set_stock(market_a, "bread", 6).ok)
	_run_hours(world, 1)
	var rows: Array = _contracts(economy)
	assert_eq(rows.size(), 1, "Só o mercado com o pão escasso (e por isso mais caro) já comporta a recompensa.")
	var ask: int = 0
	for market_row: Dictionary in economy.peek_market(market_a).rows:
		if market_row["good_id"] == "bread":
			ask = int(market_row["ask"])
	assert_lte(rows[0].reward, ask * LOT, "A recompensa não passa do `ask` de hoje vezes o lote.")
	world.teardown()
	baseline[0].teardown()


## A BORDA da regra (b) no mercado A, no estoque-alvo (`ask` 11, lote 5): margem de 1000 pontos = recompensa 55 = `ask` vezes o lote, posta; 1001 = 56, um a mais, não posta (a regra recusa só o que PASSA do `ask`).
func test_a_reward_equal_to_the_ask_of_the_lot_is_posted_and_one_more_is_not() -> void:
	var posted: Array = []
	for margin_bp: int in [1000, 1001]:
		var parts: Array = _world([_bread_standing(margin_bp)])
		var world: World = parts[0]
		var economy: EconomyModule = parts[1]
		_run_hours(world, 1)
		posted.append(_contracts(economy, "", economy.peek_market_of(SETTLEMENT_A).market_id).size())
		world.teardown()
	assert_eq(posted, [1, 0], "Recompensa igual ao `ask` do lote: um contrato; um a mais: nenhum.")


func test_same_seed_gives_the_same_contracts_and_money_and_goods_stay_conserved() -> void:
	var first: Array = _world([_bread_standing(), _grain_shortage()])
	var second: Array = _world([_bread_standing(), _grain_shortage()])
	_run_hours(first[0], 60)
	_run_hours(second[0], 60)
	assert_eq(first[0].state_hash(), second[0].state_hash(), "Mesma semente, mesmo estado, contratos incluídos.")
	assert_gt(_contracts(first[1]).size(), 0)
	assert_true(first[1].peek_conservation().ok)
	assert_true(first[1].peek_goods_conservation().ok)
	assert_eq(first[0].validate(), [])
	first[0].teardown()
	second[0].teardown()


func test_saving_and_loading_does_not_repeat_the_contracts() -> void:
	var original: Array = _world([_bread_standing()])
	_run_hours(original[0], 5)
	var saved: Dictionary = original[0].serialize()
	var restored: Array = _world([_bread_standing()], -1, false)
	var loaded: Result = restored[0].on_load(saved)
	assert_true(loaded.ok, loaded.message)
	_run_hours(original[0], 5)
	_run_hours(restored[0], 5)
	assert_eq(_contracts(restored[1]).size(), 3, "O livro salvo já diz que o mercado tem o contrato: nada se repete.")
	assert_eq(restored[0].state_hash(), original[0].state_hash(), "Salvar e carregar no meio não muda o resultado.")
	original[0].teardown()
	restored[0].teardown()
