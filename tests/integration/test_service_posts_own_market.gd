extends GutTest
## LW-095e (ajuste da revisão independente da LW-095): cada posto de serviço é pago pela conta do MERCADO do PRÓPRIO povoado (docs/modules/economy.md, seção 6; DEC-164). Economia REAL (`data/economy`, com os 6 postos de `service_posts.json`),
## sem os locais de produção (a receita deles mexeria nos mesmos mercados) e sem o módulo `npc`: os trabalhadores são NPCs abertos pela porta nos locais dos postos, com equipes DIFERENTES por povoado (folhas de 5, 3 e 2 por hora), e os três
## mercados recebem saldos DIFERENTES (um NPC compra grão em cada um, mais em A e menos em C). (1) Em 2 horas só o mercado do povoado de cada posto diminui, pela folha exata dele; os outros ficam como estavam e o dinheiro se conserva.
## (2) Com o mercado de B sem dinheiro, só os postos de B param (ninguém de B recebe) e os de A e C seguem pagos: nenhum mercado cobre a folha de outro povoado. Os dois testes falham se um posto pagasse pelo mercado de outro povoado.

const SEED: int = 95
const MINUTES_PER_HOUR: int = 60
const NPC_START_MONEY: int = 60
const FIRST_WORKER: int = 100
const FIRST_BUYER: int = 300
const GOOD: String = "grain"
const POSTED_ESCROW: int = 53 ## O pão que o postador de encomendas põe em cada mercado (LW-107c3, opção B: 5 pães de valor-base 10 mais 5%): o mercado retém 53 na custódia enquanto o contrato dele está aberto.
## Os três povoados e o mercado de cada um, na mesma ordem (os IDs 1 a 3 são dos mercados; tests/unit/test_game_economy_wiring.gd confere isso nos dados reais).
const SETTLEMENTS: Array[String] = ["test_settlement_a", "test_settlement_b", "test_settlement_c"]
const MARKETS: Array[int] = [1, 2, 3]
## O índice do povoado B nas duas listas acima.
const INDEX_B: int = 1
## Os locais dos 6 postos reais e a equipe de cada um: folha por hora (salário 1) de A = 5, de B = 3 e de C = 2.
const CREWS: Dictionary[String, int] = {"a_work_06": 3, "a_work_07": 2, "b_work_07": 2, "b_work_08": 1, "c_work_04": 1, "c_work_05": 1}


## `market_money`: o saldo inicial do tipo `market` (negativo mantém o dado real, 3000); sem locais de produção.
func _definitions(market_money: int) -> EconomyDefinitions:
	var setup: EconomySetup = EconomySetup.from_dir(EconomySetup.DEFAULT_DIR)
	assert_true(setup.result.ok, setup.result.message)
	var definitions: EconomyDefinitions = setup.definitions
	assert_eq(definitions.service_posts.size(), CREWS.size(), "Os dados reais têm os 6 postos.")
	var no_sites: Array[SiteDef] = []
	definitions.production_sites = no_sites
	for kind: OwnerKindDef in definitions.kinds:
		if kind.id == MarketBook.KIND_MARKET and market_money >= 0:
			kind.initial_balance = market_money
	return definitions


func _world(module: EconomyModule) -> World:
	var clock: SimClock = SimClock.new()
	var world: World = World.new(SimContext.new(clock, EventBus.new(clock), WorldRng.new(SEED), IdGenerator.new()))
	assert_true(world.register_module("economy", module).ok)
	world.setup()
	world.post_setup()
	world.on_new_game(SEED)
	return world


func _run_minutes(world: World, minutes: int) -> void:
	for _minute: int in minutes:
		world.context.clock.advance_step()
		world.tick(1)
	world.context.events.dispatch()


## Abre os NPCs de cada posto pela porta e devolve os trabalhadores por local do posto.
func _open_crews(module: EconomyModule) -> Dictionary[String, Array]:
	var crews: Dictionary[String, Array] = {}
	var next_id: int = FIRST_WORKER
	for place_id: String in CREWS:
		var workers: Array[int] = []
		for _worker: int in CREWS[place_id]:
			assert_true(module.request_open_owner(next_id, "npc", place_id).ok)
			workers.append(next_id)
			next_id += 1
		crews[place_id] = workers
	return crews


## Um NPC compra grão em cada mercado (`grain_by_market`, na ordem de `MARKETS`): o dinheiro vai da conta dele para a do mercado, que passa a ter um saldo diferente dos outros.
func _enrich_markets(module: EconomyModule, grain_by_market: Array[int]) -> void:
	for index: int in MARKETS.size():
		if grain_by_market[index] > 0:
			var buyer: int = FIRST_BUYER + index
			assert_true(module.request_open_owner(buyer, "npc").ok)
			assert_true(module.request_trade(buyer, MARKETS[index], GOOD, grain_by_market[index], "buy").result.ok, "O NPC compra grão no mercado %d." % MARKETS[index])


func _balances(module: EconomyModule, owner_ids: Array[int]) -> Array[int]:
	var balances: Array[int] = []
	for owner_id: int in owner_ids:
		balances.append(module.peek_balance(owner_id).balance)
	return balances


## A folha por hora de cada povoado, na ordem de `SETTLEMENTS`: salário vezes trabalhadores de cada posto, como a economia informa.
func _hourly_payroll(module: EconomyModule) -> Array[int]:
	var payroll: Array[int] = [0, 0, 0]
	for place_id: String in CREWS:
		var post: EconomyReplies.PostQuery = module.peek_post_at(place_id)
		assert_true(post.result.ok, "Há um posto em %s." % place_id)
		assert_eq(post.workers_assigned, CREWS[place_id], "A equipe de %s." % place_id)
		payroll[SETTLEMENTS.find(post.settlement_id)] += post.wage_per_hour * post.workers_assigned
	return payroll


func test_only_the_market_of_the_posts_own_settlement_pays_its_payroll_and_the_money_is_conserved() -> void:
	var module: EconomyModule = EconomyModule.new(false, _definitions(-1))
	var world: World = _world(module)
	var crews: Dictionary[String, Array] = _open_crews(module)
	var all_workers: Array[int] = []
	for place_id: String in crews:
		all_workers.append_array(crews[place_id])
	_enrich_markets(module, [5, 3, 1])
	var payroll: Array[int] = _hourly_payroll(module)
	assert_eq(payroll, [5, 3, 2] as Array[int], "Folhas diferentes por povoado: um posto pago pelo mercado errado muda o resultado.")
	var before: Array[int] = _balances(module, MARKETS)
	assert_true(before[0] != before[1] and before[1] != before[2] and before[0] != before[2], "Os três mercados começam com saldos diferentes: %s." % str(before))
	var money_before: int = module.peek_conservation().sum
	var workers_before: int = _balances(module, all_workers).reduce(func(sum: int, money: int) -> int: return sum + money, 0)
	var paid: Array[WagesPaid] = []
	world.context.events.subscribe("WagesPaid", func(event: SimEvent) -> void: paid.append(event))
	_run_minutes(world, 2 * MINUTES_PER_HOUR)
	var after: Array[int] = _balances(module, MARKETS)
	for index: int in MARKETS.size():
		assert_eq(before[index] - after[index], 2 * payroll[index] + POSTED_ESCROW, "O mercado %d (povoado %s) paga só a folha dos postos do povoado dele em 2 horas, mais a custódia do pão do postador; saldos %s -> %s." % [MARKETS[index], SETTLEMENTS[index], str(before), str(after)])
	var workers_after: int = _balances(module, all_workers).reduce(func(sum: int, money: int) -> int: return sum + money, 0)
	assert_eq(workers_after - workers_before, 2 * (payroll[0] + payroll[1] + payroll[2]), "Todo o dinheiro que saiu dos mercados chegou aos trabalhadores.")
	assert_eq(paid.size(), 2 * CREWS.size(), "Um `WagesPaid` por posto e por hora.")
	assert_eq(module.peek_conservation().sum, money_before, "A soma de todas as contas não muda: o dinheiro só passou dos mercados para os trabalhadores.")
	assert_true(module.peek_conservation().ok)
	assert_eq(module.validate(), [] as Array[String])
	world.teardown()


func test_a_market_without_money_stops_only_the_posts_of_its_own_settlement_and_no_other_market_covers_for_it() -> void:
	var module: EconomyModule = EconomyModule.new(false, _definitions(0))
	var world: World = _world(module)
	var crews: Dictionary[String, Array] = _open_crews(module)
	_enrich_markets(module, [5, 0, 2])
	var before: Array[int] = _balances(module, MARKETS)
	assert_eq(before[INDEX_B], 0, "O mercado de B não tem dinheiro: %s." % str(before))
	assert_true(before[0] >= 5 and before[2] >= 2, "Os mercados de A e C, que venderam grão, cobrem a folha de uma hora (5 e 2): %s." % str(before))
	var paid: Array[WagesPaid] = []
	world.context.events.subscribe("WagesPaid", func(event: SimEvent) -> void: paid.append(event))
	_run_minutes(world, MINUTES_PER_HOUR)
	var paid_posts: Array[int] = []
	for event: WagesPaid in paid:
		paid_posts.append(event.workplace_id)
	paid_posts.sort()
	var expected_posts: Array[int] = []
	for place_id: String in CREWS:
		var post: EconomyReplies.PostQuery = module.peek_post_at(place_id)
		var own_market_has_money: bool = post.settlement_id != SETTLEMENTS[INDEX_B]
		assert_eq(post.running, own_market_has_money, "%s (povoado %s): o posto só roda se o mercado do próprio povoado tem a folha." % [place_id, post.settlement_id])
		if own_market_has_money:
			expected_posts.append(post.workplace_id)
		for worker_id: int in crews[place_id]:
			assert_eq(module.peek_balance(worker_id).balance, NPC_START_MONEY + (1 if own_market_has_money else 0), "O trabalhador %d de %s: recebe 1 só se o mercado do próprio povoado paga (tudo ou nada)." % [worker_id, place_id])
	expected_posts.sort()
	assert_eq(paid_posts, expected_posts, "Só os 4 postos de A e C anunciam `WagesPaid`; os de B param sem evento.")
	assert_eq(_balances(module, MARKETS), [before[0] - 5, 0, before[2] - 2] as Array[int], "Só os mercados de A e C pagam, cada um pela folha dos seus postos; o de B segue vazio e nenhum outro o cobre.")
	assert_true(module.peek_conservation().ok)
	world.teardown()
