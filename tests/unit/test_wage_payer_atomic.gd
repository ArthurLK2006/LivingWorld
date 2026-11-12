extends GutTest
## LW-095 (R8-M1 e R8-M2, decisões de Arthur de 12/11/2026): (1) a folha é TUDO OU NADA também no caminho de erro: `WagePayer.pay` confere o saldo da folha inteira e cada transferência (conta aberta, teto de saldo de quem recebe) ANTES de mover a primeira, então um
## pagamento que falharia no meio não deixa ninguém pago pela metade, e `can_pay` já recusa o que o `Ledger` recusaria; um posto com um trabalhador nesse caso PARA (NO_FUNDS) sem pagar nenhum dos outros nem publicar `WagesPaid`. (2) O `debug_summary()` da economia mostra a
## quantidade de postos de serviço (AGENTS 4.15), só quando há postos (o resumo sem postos fica como estava). Livros REAIS (dono, `Ledger`) e a economia real para o resumo.

const SEED: int = 107
const SETTLEMENT_A: String = "test_settlement_a"
const MARKET: int = 1
const FIRST: int = 2
const SECOND: int = 3
const POST: int = 9
const WAGE: int = 10
const MARKETS: int = 3


class Rig:
	extends RefCounted

	var book: OwnerBook
	var ledger: Ledger
	var payer: WagePayer
	var posts: ServicePostBook


func _rig(market_money: int = 1000) -> Rig:
	var goods: GoodsLoader.LoadResult = GoodsLoader.load_dir(GoodsLoader.DEFAULT_DIR)
	var market: MarketLoader.LoadResult = MarketLoader.load_dir(GoodsLoader.DEFAULT_DIR)
	assert_true(goods.result.ok and market.result.ok)
	var rig: Rig = Rig.new()
	rig.book = OwnerBook.new()
	for owner_id: int in [MARKET, FIRST, SECOND]:
		assert_true(rig.book.open_owner(owner_id, "market" if owner_id == MARKET else "npc").ok)
	rig.ledger = Ledger.new(rig.book)
	assert_true(rig.ledger.mint(MARKET, market_money, Ledger.REASON_GAME_START).ok)
	var store: GoodsStore = GoodsStore.new(rig.book, goods.goods, goods.kinds)
	var markets: MarketBook = MarketBook.new(rig.book, store, goods.goods, market.targets, market.params)
	markets.register_market(SETTLEMENT_A, MARKET)
	rig.payer = WagePayer.new(rig.book, rig.ledger)
	rig.posts = ServicePostBook.new(markets, rig.payer)
	return rig


## O segundo trabalhador chega ao teto de saldo: mais um salário estouraria a conta dele.
func _fill_second_to_the_cap(rig: Rig) -> void:
	assert_true(rig.ledger.mint(SECOND, Ledger.MAX_AMOUNT - WAGE + 1, Ledger.REASON_TRADE).ok, "Dinheiro de outro motivo, para o contador de `game_start` não estourar o teto.")


func test_a_payroll_that_would_fail_in_the_middle_pays_nobody_and_can_pay_already_says_no() -> void:
	var rig: Rig = _rig()
	_fill_second_to_the_cap(rig)
	var workers: Array = [FIRST, SECOND]
	assert_false(rig.payer.can_pay(MARKET, WAGE, workers), "O `Ledger` recusaria o salário do segundo (passa do teto): a folha não cabe.")
	var refused: Result = rig.payer.pay(MARKET, WAGE, workers)
	assert_false(refused.ok)
	assert_eq([rig.ledger.balance_of(FIRST), rig.ledger.balance_of(MARKET)], [0, 1000], "O primeiro trabalhador, que viria antes, também não recebeu nada: tudo ou nada.")
	assert_true(rig.ledger.is_conserved())
	assert_true(rig.payer.pay(MARKET, WAGE, [FIRST]).ok, "A mesma folha sem o trabalhador problemático passa.")
	assert_eq(rig.ledger.balance_of(FIRST), WAGE)


func test_pay_checks_the_whole_balance_by_itself_without_relying_on_can_pay() -> void:
	var rig: Rig = _rig(15)
	var refused: Result = rig.payer.pay(MARKET, WAGE, [FIRST, SECOND])
	assert_eq(refused.code, EconomyCodes.INSUFFICIENT_FUNDS, refused.message)
	assert_eq([rig.ledger.balance_of(FIRST), rig.ledger.balance_of(SECOND), rig.ledger.balance_of(MARKET)], [0, 0, 15], "Com 15 não cabem 2 salários de 10: ninguém recebe nem os 10 do primeiro.")


func test_a_post_with_a_worker_the_ledger_would_refuse_stops_and_pays_no_one_and_publishes_nothing() -> void:
	var rig: Rig = _rig()
	_fill_second_to_the_cap(rig)
	assert_true(rig.posts.register_post(POST, PostDef.new("post_a_guard", SETTLEMENT_A, "a_work_05", "guard", 8, WAGE)).ok)
	assert_true(rig.posts.assign_worker(POST, FIRST).ok and rig.posts.assign_worker(POST, SECOND).ok)
	var events: Array[SimEvent] = rig.posts.hour_step()
	assert_eq(events.size(), 0, "Sem folha paga não há `WagesPaid`.")
	assert_eq([rig.posts.state_of(POST)["running"], rig.ledger.balance_of(FIRST), rig.ledger.balance_of(MARKET)], [false, 0, 1000], "O posto parou e ninguém recebeu, nem o primeiro; nenhum erro no log.")


func test_the_economy_debug_summary_shows_the_posts_only_when_there_are_posts() -> void:
	var setup: EconomySetup = EconomySetup.from_dir(EconomySetup.DEFAULT_DIR)
	assert_true(setup.result.ok, setup.result.message)
	var plain: EconomyModule = EconomyModule.new(false, setup.definitions)
	assert_false(plain.debug_summary().has("service_posts"), "Sem postos o resumo é o de sempre.")
	var with_posts: EconomyDefinitions = EconomySetup.from_dir(EconomySetup.DEFAULT_DIR).definitions
	var posts: Array[PostDef] = [PostDef.new("post_a_guard", SETTLEMENT_A, "a_work_05", "guard", 8, WAGE), PostDef.new("post_a_inn", SETTLEMENT_A, "a_work_04", "innkeeper", 6, WAGE)]
	with_posts.service_posts = posts
	var no_sites: Array[SiteDef] = []
	with_posts.production_sites = no_sites
	var module: EconomyModule = EconomyModule.new(false, with_posts)
	var clock: SimClock = SimClock.new()
	var world: World = World.new(SimContext.new(clock, EventBus.new(clock), WorldRng.new(SEED), IdGenerator.new()))
	assert_true(world.register_module("economy", module).ok)
	world.setup()
	world.post_setup()
	world.on_new_game(SEED)
	var summary: Dictionary = module.debug_summary()
	assert_eq(summary["service_posts"], 2, "Dois postos.")
	assert_eq([summary["owners"], summary["production_sites"], summary["money_conserved"]], [MARKETS, 0, true], "Sem locais de produção só restam os mercados (um por povoado dos dados): os postos não são donos.")
	world.teardown()
