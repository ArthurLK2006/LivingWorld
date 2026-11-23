extends GutTest
## LW-107c3, opção B (PR #152, RASCUNHO): verificação FUNCIONAL automática no jogo REAL (23/11/2026). O mundo inteiro de `res://data` (138 NPCs, produção, consumo, os carregadores do `GameApp`) com o dado REAL da opção B (`bread_standing` e `flour_shortage`); só a escassez muda o estoque inicial do pão, em memória (a pasta local de escassez muda o mesmo campo, `initial_stock` 5).
## (1) Publicação às 06:00 (A e C postam, B não, nada antes; o limite de abertos impede a 2ª postagem); (2) o ciclo do jogador: comprar no B, aceitar e entregar no A paga 53 com as conservações fechadas a cada passo, e comprar no próprio emissor nunca dá lucro (regra de 14/11); (3) abandono e vencimento com o postador ATIVO (a custódia volta, o espaço volta e ele reposta); (4) a escassez (SÓ caracteriza, não julga lucro nem prejuízo; a decisão X, Y ou Z é de Arthur) e o limite de 3 aceitas com os 3 contratos reais; (5) salvar e carregar no meio de um contrato aceito.
## ISTO NÃO SUBSTITUI A VALIDAÇÃO VISUAL NA JANELA: a leitura da tela, a clareza do texto e o "sentir" do jogo só a janela mostra. Valores à mão: os do dado (`data/economy/contract_templates.json`: 5 pães, margem 500 bp sobre o valor-base 10 = 53, 48 h) e o relógio do jogo novo (05:45, minuto 345, a 1ª hora cheia às 06:00).

const WORLD_SEED: int = 1
const GAME_VERSION: String = "0.0.1-test"
const SETTLEMENT_PREFIX: String = "test_settlement_"
const BREAD: String = "bread"
const QUANTITY: int = 5
const REWARD: int = 53
const DEADLINE_MINUTES: int = 2880
const FIRST_POST_MINUTE: int = 360
const WALK_B_TO_A: int = 58 ## A até B: 503 m correndo a 7 m/s = 72 s reais = 58 minutos de jogo (docs/economia/lw-107c3-opcao-b-condicoes.md, 2.1).
const SCARCE_STOCK: int = 5
const LIMIT: int = 3
const FOURTH_REWARD: int = 30
const FOURTH_QUANTITY: int = 2
const KEY_ACCEPTED: String = "economy.contract.accepted"
const KEY_DELIVERED: String = "economy.contract.delivered"
const KEY_ABANDONED: String = "economy.contract.abandoned"
const KEY_LIMIT: String = "economy.contract.limit"
const CODE_LIMIT: String = "BRIDGE_CONTRACT_LIMIT"
const ABANDONED: String = "abandoned"

var _terrain: TerrainData
var _points: Array[PointOfInterest] = []
var _settlements: SettlementLoader.LoadResult
var _places: Array[Place] = []
var _host: SimulationHostNode
var _other: SimulationHostNode
var _bridge: SimBridge
var _economy: EconomyModule
var _actor_id: int = 0
var _failed: Array[ContractFailed] = []
var _completed: Array[ContractCompleted] = []
var _codec: JsonSaveCodec = JsonSaveCodec.new()


func before_all() -> void:
	var terrain: TerrainLoader.LoadResult = TerrainLoader.load_dir(GameAppNode.TERRAIN_DIR)
	var points: PointOfInterestLoader.LoadResult = PointOfInterestLoader.load_dir(GameAppNode.TERRAIN_DIR, terrain.terrain)
	_settlements = SettlementLoader.load_dir(GameAppNode.TERRAIN_DIR, terrain.terrain)
	assert_true(terrain.result.ok and points.result.ok and _settlements.result.ok, "Os dados reais do mundo carregam.")
	_terrain = terrain.terrain
	_points = points.points
	_places = _settlements.places


func after_each() -> void:
	for host: SimulationHostNode in [_host, _other]:
		if host != null:
			if host.runner != null:
				host.runner.finish()
			host.free()
	_host = null
	_other = null


func _npc_setup() -> NpcSetup:
	return NpcSetup.from_dir(GameAppNode.NPC_DATA_DIR, SettlementService.new(_settlements.settlements, _settlements.places), OS.is_debug_build())


func _world_setup() -> WorldSetup:
	return WorldSetup.from_dir(GameAppNode.TERRAIN_DIR, _settlements.settlements, OS.is_debug_build())


## O dado real da economia; `scarce` põe o estoque inicial do pão em 5 nos três mercados (o que a pasta local de escassez faz no arquivo, aqui só em memória).
func _economy_setup(scarce: bool) -> EconomySetup:
	var setup: EconomySetup = EconomySetup.from_dir(EconomySetup.DEFAULT_DIR, OS.is_debug_build())
	assert_true(setup.result.ok, setup.result.message)
	if scarce:
		for target: MarketTargetDef in setup.definitions.market_targets:
			if target.good_id == BREAD:
				target.initial_stock = SCARCE_STOCK
	return setup


## O jogo novo como o do jogo (05:45, 138 NPCs), com o jogador nascido e a conta aberta.
func _start(scarce: bool) -> void:
	_host = SimulationHostNode.new()
	_host.start_new_game(WORLD_SEED, _terrain, _points, _npc_setup(), GameAppNode.NEW_GAME_START_MINUTE, _economy_setup(scarce), _world_setup())
	_economy = _host.economy
	_bridge = SimBridge.new(_host, _terrain, _places)
	_failed = []
	_completed = []
	_host.runner.world.context.events.subscribe("ContractFailed", func(event: SimEvent) -> void: _failed.append(event))
	_host.runner.world.context.events.subscribe("ContractCompleted", func(event: SimEvent) -> void: _completed.append(event))
	_actor_id = _bridge.request_spawn_character().actor_id
	assert_true(_bridge.request_open_player_account(_actor_id).ok)


func _now() -> int:
	return _bridge.peek_time().total_minutes


func _run_to(minute: int) -> void:
	_host.runner.run_steps(maxi(0, minute - _now()))


func _market(letter: String) -> int:
	return _economy.peek_market_of(SETTLEMENT_PREFIX + letter).market_id


func _go(market_id: int) -> void:
	var settlement_id: String = _economy.peek_market(market_id).settlement_id
	for place: Place in _places:
		if place.kind == Place.KIND_MARKET and place.settlement_id == settlement_id:
			assert_true(_bridge.request_report_position(_actor_id, place.position, 0.0).ok)


func _funds() -> int:
	return _bridge.peek_player_economy(_actor_id).funds


func _cash(owner_id: int) -> int:
	return _economy.peek_balance(owner_id).balance


func _carried() -> int:
	for row: Dictionary in _economy.peek_inventory(_actor_id).rows:
		if row["good_id"] == BREAD:
			return int(row["quantity"])
	return 0


## Os contratos de ENTREGA da economia (as vagas ficam de fora), por ID crescente.
func _deliveries() -> Array[EconomyReplies.ContractQuery]:
	var rows: Array[EconomyReplies.ContractQuery] = []
	for contract: EconomyReplies.ContractQuery in _economy.peek_contracts().contracts:
		if contract.kind == ContractBook.DELIVERY:
			rows.append(contract)
	return rows


func _of(market_id: int) -> Array[EconomyReplies.ContractQuery]:
	return _deliveries().filter(func(contract: EconomyReplies.ContractQuery) -> bool: return contract.issuer_id == market_id)


func _states_of(market_id: int) -> Array[String]:
	var states: Array[String] = []
	for contract: EconomyReplies.ContractQuery in _of(market_id):
		states.append(contract.state)
	return states


func _ask(market_id: int) -> int:
	for row: Dictionary in _economy.peek_market(market_id).rows:
		if row["good_id"] == BREAD:
			return int(row["ask"])
	return -1


func _quote(market_id: int) -> int:
	return _economy.peek_quote(_actor_id, market_id, BREAD, QUANTITY, BridgePlayerEconomyReplies.SIDE_BUY).total


func _moved(reason: String) -> int:
	for row: Dictionary in _economy.peek_ledger_totals().rows:
		if row["reason"] == reason:
			return int(row["moved"])
	return 0


## As duas conservações (dinheiro e bens) e o `validate()` da economia fecham depois do passo `step`.
func _books(step: String, economy: EconomyModule = null) -> void:
	var book: EconomyModule = _economy if economy == null else economy
	assert_true(book.peek_conservation().ok, "O dinheiro fecha %s." % step)
	assert_true(book.peek_goods_conservation().ok, "Os bens fecham %s." % step)
	assert_eq(book.validate(), [] as Array[String], "O `validate()` da economia fecha %s." % step)


func _snapshot() -> Array:
	return [_host.runner.world.state_hash(), int(_host.runner.world.context.events.debug_summary()["pending"])]


func _buy(market_id: int) -> BridgePlayerEconomyReplies.PlayerTradeReply:
	return _bridge.request_trade(_actor_id, market_id, BREAD, QUANTITY, BridgePlayerEconomyReplies.SIDE_BUY)


## O que a aba Contratos do mercado mostra (o modelo da tela, sem a janela).
func _view(market_id: int) -> ContractsViewModel:
	var view: ContractsViewModel = ContractsViewModel.new()
	assert_true(view.refresh(_bridge, _actor_id, market_id))
	return view


## O jogo real até 1 minuto depois da 1ª hora cheia, com o jogador no B comprando os 5 pães e voltando ao A (a viagem passa no relógio): devolve o contrato do A e o que a compra custou.
func _bought_at_b_and_back_at_a() -> Array[int]:
	_run_to(FIRST_POST_MINUTE + 1)
	var contract_id: int = _of(_market("a"))[0].contract_id
	_go(_market("b"))
	var bought: BridgePlayerEconomyReplies.PlayerTradeReply = _buy(_market("b"))
	assert_true(bought.result.ok, bought.result.message)
	_books("depois da compra no B")
	_go(_market("a"))
	_host.runner.run_steps(WALK_B_TO_A)
	_books("depois da viagem do B ao A")
	return [contract_id, bought.total]


func test_the_real_world_posts_the_bread_at_six_at_a_and_c_not_at_b_and_the_open_limit_stops_a_second_post() -> void:
	_start(false)
	var a: int = _market("a")
	var b: int = _market("b")
	var c: int = _market("c")
	var asks_at_start: Array[int] = [_ask(a), _ask(b), _ask(c)]
	_run_to(FIRST_POST_MINUTE - 1)
	assert_eq(_deliveries().size(), 0, "Antes das 06:00 ninguém postou.")
	_run_to(FIRST_POST_MINUTE + 1)
	print("L3 pão (ask) A/B/C no começo (05:45): %s; às 06:01: %d/%d/%d; cotação de 5 pães no B às 06:01: %d" % [asks_at_start, _ask(a), _ask(b), _ask(c), _quote(b)])
	var posted: Array[EconomyReplies.ContractQuery] = _deliveries()
	var shape: Array = posted.map(func(contract: EconomyReplies.ContractQuery) -> Array: return [contract.issuer_id, contract.destination_id, contract.good_id, contract.quantity, contract.reward, contract.state, contract.acceptor_id, contract.deadline])
	var expected: Array = [[a, a, BREAD, QUANTITY, REWARD, ContractBook.STATE_OPEN, IdGenerator.NO_ID, FIRST_POST_MINUTE + DEADLINE_MINUTES], [c, c, BREAD, QUANTITY, REWARD, ContractBook.STATE_OPEN, IdGenerator.NO_ID, FIRST_POST_MINUTE + DEADLINE_MINUTES]]
	assert_eq(shape, expected, "Às 06:00 só o pão de 5 por 53, aberto e de 48 h, no A e no C: o B não postou e a farinha (escassez) também não.")
	assert_true(_ask(a) * QUANTITY >= REWARD and _ask(c) * QUANTITY >= REWARD and _ask(b) * QUANTITY < REWARD, "A regra de postagem (53 <= 5 x ask): A e C passam; o B, com o pão barato, não.")
	assert_eq([_cash(posted[0].contract_id), _cash(posted[1].contract_id), _moved(Ledger.REASON_CONTRACT_ESCROW)], [REWARD, REWARD, 2 * REWARD], "Cada emissor pagou 53 para a custódia do contrato dele.")
	_books("depois da 1ª postagem")
	var ids: Array[int] = [posted[0].contract_id, posted[1].contract_id]
	_run_to(FIRST_POST_MINUTE + 23 * 60)
	var later: Array[int] = []
	for contract: EconomyReplies.ContractQuery in _deliveries():
		later.append(contract.contract_id)
		assert_eq([contract.state, contract.acceptor_id], [ContractBook.STATE_OPEN, IdGenerator.NO_ID], "O contrato %d segue aberto e ninguém o aceitou (o NPC só lê vagas)." % contract.contract_id)
	assert_eq(later.filter(func(contract_id: int) -> bool: return contract_id in ids), ids, "As duas encomendas do começo seguem no quadro.")
	for market_id: int in [a, c]:
		assert_eq(_of(market_id).size(), 1, "O limite de 1 aberto por mercado: o A e o C não postam de novo enquanto a encomenda está aberta.")
	assert_eq(_host.runner.world.validate(), [] as Array[String])
	_books("depois de 23 horas")


func test_the_player_buys_at_b_accepts_and_delivers_at_a_the_posted_bread_pays_53_and_both_books_close_at_every_step() -> void:
	_start(false)
	var a: int = _market("a")
	var funds_start: int = _funds()
	var made: Array[int] = _bought_at_b_and_back_at_a()
	var contract_id: int = made[0]
	var cost: int = made[1]
	assert_eq([_funds(), _carried()], [funds_start - cost, QUANTITY], "A compra no B custou o total e o jogador leva os 5 pães.")
	assert_lt(cost, REWARD, "O pão do B é barato (o guia diz uns 40): comprar lá e entregar no A é a logística que dá ganho.")
	var board: ContractsViewModel = _view(a)
	assert_eq([board.available().size(), board.mine().size(), board.accepted_count(), board.capacity()], [1, 0, 0, LIMIT], "Antes de aceitar: 1 disponível, nenhuma minha, 0 de 3.")
	var accepted: BridgePlayerContractsReplies.ContractActionReply = _bridge.request_contract_accept(_actor_id, contract_id)
	assert_true(accepted.result.ok, accepted.result.message)
	assert_eq([accepted.reward, accepted.text_key], [REWARD, KEY_ACCEPTED])
	board = _view(a)
	assert_eq([board.available().size(), board.mine().size(), board.accepted_count()], [0, 1, 1], "Aceitar passa a linha para Meus contratos: 1 de 3.")
	assert_true(board.mine()[0].can_deliver and board.mine()[0].is_mine, "A linha é minha e pode ser entregue.")
	assert_eq([_funds(), _cash(contract_id)], [funds_start - cost, REWARD], "Aceitar não mexe no saldo: a recompensa segue na custódia.")
	_books("depois do aceite")
	var stock: int = _economy.peek_stock(a, BREAD).value
	var delivered: BridgePlayerContractsReplies.ContractActionReply = _bridge.request_contract_deliver(_actor_id, contract_id)
	assert_true(delivered.result.ok, delivered.result.message)
	assert_eq([delivered.reward, delivered.text_key], [REWARD, KEY_DELIVERED])
	assert_eq([_funds(), _cash(contract_id), _carried(), _economy.peek_stock(a, BREAD).value], [funds_start - cost + REWARD, 0, 0, stock + QUANTITY], "O saldo subiu 53, a custódia zerou e os 5 pães passaram do jogador ao estoque do A.")
	assert_eq([_economy.peek_contract(contract_id).state, _view(a).mine()[0].display_state], [ContractBook.STATE_COMPLETED, ContractBook.STATE_COMPLETED])
	assert_eq([_moved(Ledger.REASON_CONTRACT_ESCROW), _moved(Ledger.REASON_CONTRACT_PAYOUT), _moved(Ledger.REASON_CONTRACT_REFUND)], [2 * REWARD, REWARD, 0], "Livro-razão: o A e o C retiveram 53 cada, o A pagou 53 ao jogador e nada voltou.")
	_books("depois da entrega")
	_host.runner.world.context.events.dispatch()
	assert_eq(_completed.size(), 1, "Sai UM `ContractCompleted`.")
	assert_eq([_completed[0].contract_id, _completed[0].acceptor_id, _completed[0].reward], [contract_id, _actor_id, REWARD])
	assert_eq(_host.runner.world.validate(), [] as Array[String])
	print("L3 ciclo B->A (mundo real, 1º dia): pão a %d no B, custo dos 5 pães %d, recompensa %d, saldo %d -> %d (líquido %+d)" % [_ask(_market("b")), cost, REWARD, funds_start, _funds(), _funds() - funds_start])


func test_buying_at_the_issuer_and_delivering_there_never_profits_the_14_11_rule() -> void:
	_start(false)
	var a: int = _market("a")
	_run_to(FIRST_POST_MINUTE + 1)
	var contract_id: int = _of(a)[0].contract_id
	var funds_start: int = _funds()
	_go(a)
	var bought: BridgePlayerEconomyReplies.PlayerTradeReply = _buy(a)
	assert_true(bought.result.ok, bought.result.message)
	assert_gte(bought.total, REWARD, "No emissor, logo depois de postar, os 5 pães custam pelo menos a recompensa (53 <= 5 x ask).")
	assert_true(_bridge.request_contract_accept(_actor_id, contract_id).result.ok)
	var delivered: BridgePlayerContractsReplies.ContractActionReply = _bridge.request_contract_deliver(_actor_id, contract_id)
	assert_true(delivered.result.ok and delivered.reward == REWARD, "A entrega ainda paga os 53 ditos.")
	assert_lte(_funds(), funds_start, "Mas o saldo final não passa do inicial: comprar onde se entrega não dá lucro.")
	_books("depois da compra e entrega no emissor")
	print("L3 compra no emissor A: custo %d, recompensa %d, saldo %d -> %d (líquido %+d)" % [bought.total, REWARD, funds_start, _funds(), _funds() - funds_start])


func test_abandoning_keeps_the_items_without_a_fine_sends_the_custody_back_frees_the_slot_and_the_poster_posts_again() -> void:
	_start(false)
	var a: int = _market("a")
	var made: Array[int] = _bought_at_b_and_back_at_a()
	var contract_id: int = made[0]
	assert_true(_bridge.request_contract_accept(_actor_id, contract_id).result.ok)
	assert_eq(_view(a).accepted_count(), 1, "Pré-condição: 1 de 3 aceita.")
	var funds: int = _funds()
	var cash_a: int = _cash(a)
	var abandoned: BridgePlayerContractsReplies.ContractActionReply = _bridge.request_contract_abandon(_actor_id, contract_id)
	assert_true(abandoned.result.ok, abandoned.result.message)
	assert_eq([abandoned.reward, abandoned.text_key], [0, KEY_ABANDONED])
	assert_eq([_funds(), _carried(), _cash(contract_id), _cash(a)], [funds, QUANTITY, 0, cash_a + REWARD], "Sem multa: o saldo e os 5 pães ficam com o jogador; a custódia de 53 voltou ao caixa do emissor.")
	var after: EconomyReplies.ContractQuery = _economy.peek_contract(contract_id)
	assert_eq([after.state, after.closed_reason], [ContractBook.STATE_FAILED, ABANDONED])
	assert_eq([_view(a).accepted_count(), _view(a).mine()[0].display_state], [0, ABANDONED], "O espaço do limite foi liberado e a linha mostra o abandono.")
	_books("depois do abandono")
	_run_to(_now() + 60)
	assert_eq(_states_of(a), [ContractBook.STATE_FAILED, ContractBook.STATE_OPEN] as Array[String], "Na hora cheia seguinte o postador posta de novo no A (o abandonado deixou de contar como aberto).")
	_books("depois da repostagem")


func test_an_accepted_contract_left_to_expire_with_the_poster_on_returns_the_custody_and_leaves_the_funds_intact() -> void:
	_start(false)
	var a: int = _market("a")
	_run_to(FIRST_POST_MINUTE + 1)
	var contract_id: int = _of(a)[0].contract_id
	_go(a)
	assert_true(_bridge.request_contract_accept(_actor_id, contract_id).result.ok, "O jogador aceita só para deixar vencer (aceitar não pede os pães).")
	var funds: int = _funds()
	_run_to(FIRST_POST_MINUTE + DEADLINE_MINUTES - 1)
	assert_eq([_economy.peek_contract(contract_id).state, _cash(contract_id)], [ContractBook.STATE_ACCEPTED, REWARD], "Um minuto antes do prazo o contrato segue aceito e a custódia intacta.")
	_run_to(FIRST_POST_MINUTE + DEADLINE_MINUTES + 61)
	var expired: EconomyReplies.ContractQuery = _economy.peek_contract(contract_id)
	assert_eq([expired.state, expired.acceptor_id, _cash(contract_id), _funds()], [ContractBook.STATE_EXPIRED, _actor_id, 0, funds], "Vencido: o jogador segue como aceitante, a custódia zerou e os fundos dele ficam intactos.")
	assert_eq(_moved(Ledger.REASON_CONTRACT_REFUND), 2 * REWARD, "A recompensa voltou ao emissor (o do A, aceito, e o do C, aberto, venceram na mesma hora).")
	assert_eq(_view(a).mine()[0].display_state, ContractBook.STATE_EXPIRED, "A linha mostra Vencido.")
	_host.runner.world.context.events.dispatch()
	assert_eq(_failed.filter(func(event: ContractFailed) -> bool: return event.contract_id == contract_id).size(), 1, "Sai UM `ContractFailed` do contrato.")
	assert_eq(_states_of(a), [ContractBook.STATE_EXPIRED, ContractBook.STATE_OPEN] as Array[String], "Com o vencido fora da conta, o postador já pôs outro no A.")
	assert_eq(_host.runner.world.validate(), [] as Array[String])
	_books("depois do vencimento")


func test_in_the_scarce_world_the_three_markets_post_and_the_delivery_is_characterized_without_judging_profit_or_loss() -> void:
	_start(true)
	_run_to(FIRST_POST_MINUTE + 1)
	var markets: Array[int] = [_market("a"), _market("b"), _market("c")]
	var shape: Array = _deliveries().map(func(contract: EconomyReplies.ContractQuery) -> Array: return [contract.issuer_id, contract.destination_id, contract.good_id, contract.quantity, contract.reward, contract.state])
	assert_eq(shape, markets.map(func(market_id: int) -> Array: return [market_id, market_id, BREAD, QUANTITY, REWARD, ContractBook.STATE_OPEN]), "Com o pão escasso os TRÊS mercados postam às 06:00, a mesma encomenda: 5 pães por 53.")
	var quotes: Array[int] = []
	for market_id: int in markets:
		assert_gte(_ask(market_id) * QUANTITY, REWARD, "A regra de postagem passa no mercado %d." % market_id)
		quotes.append(_quote(market_id))
	var cheapest: int = markets[quotes.find(quotes.min())]
	var funds_start: int = _funds()
	_go(cheapest)
	var contract_id: int = _of(cheapest)[0].contract_id
	var bought: BridgePlayerEconomyReplies.PlayerTradeReply = _buy(cheapest)
	var line: String = "L3 escassez: ask do pão A/B/C %d/%d/%d; cotação dos 5 pães A/B/C %d/%d/%d; saldo inicial %d; compra no mais barato: " % [_ask(markets[0]), _ask(markets[1]), _ask(markets[2]), quotes[0], quotes[1], quotes[2], funds_start]
	if bought.result.ok:
		assert_true(_bridge.request_contract_accept(_actor_id, contract_id).result.ok)
		var delivered: BridgePlayerContractsReplies.ContractActionReply = _bridge.request_contract_deliver(_actor_id, contract_id)
		assert_true(delivered.result.ok and delivered.reward == REWARD, "O contrato aceito conclui e paga a recompensa dita (53).")
		assert_eq([_funds(), _economy.peek_contract(contract_id).state, _cash(contract_id)], [funds_start - bought.total + REWARD, ContractBook.STATE_COMPLETED, 0], "O saldo final é o inicial menos o custo mais a recompensa, nada mais.")
		print(line + "custo %d, recompensa %d, saldo final %d (líquido %+d)" % [bought.total, REWARD, _funds(), _funds() - funds_start])
	else:
		assert_eq([_funds(), _carried()], [funds_start, 0], "A compra recusada não mexe no saldo nem na carga.")
		print(line + "RECUSADA (%s): o jogador novo não paga os 5 pães com o saldo que tem" % bought.result.code)
	_books("depois da escassez")
	assert_eq(_host.runner.world.validate(), [] as Array[String])


func test_in_the_scarce_world_the_three_real_contracts_fill_the_limit_of_three_and_a_fourth_is_refused_until_one_is_abandoned() -> void:
	_start(true)
	_run_to(FIRST_POST_MINUTE + 1)
	var ids: Array[int] = []
	for letter: String in ["a", "b", "c"]:
		_go(_market(letter))
		var contract_id: int = _of(_market(letter))[0].contract_id
		assert_true(_bridge.request_contract_accept(_actor_id, contract_id).result.ok, "Aceita o pão do mercado %s." % letter)
		ids.append(contract_id)
	var c: int = _market("c")
	var fourth: EconomyReplies.PostContractResult = _economy.request_post_contract(ContractBook.DELIVERY, c, FOURTH_REWARD, _now() + 600, {"good_id": BREAD, "quantity": FOURTH_QUANTITY, "destination_id": c})
	assert_true(fourth.result.ok, fourth.result.message)
	var before: Array = _snapshot()
	var funds: int = _funds()
	var refused: BridgePlayerContractsReplies.ContractActionReply = _bridge.request_contract_accept(_actor_id, fourth.contract_id)
	assert_eq([refused.result.code, refused.text_key, refused.reward], [CODE_LIMIT, KEY_LIMIT, 0], "A 4ª aceitação é recusada pelo limite de 3.")
	assert_eq([_snapshot(), _funds(), _economy.peek_contract(fourth.contract_id).state, _economy.peek_contract(fourth.contract_id).acceptor_id], [before, funds, ContractBook.STATE_OPEN, IdGenerator.NO_ID], "A recusa não mudou nada: nem o `state_hash`, nem eventos, nem o saldo.")
	assert_true(_bridge.request_contract_abandon(_actor_id, ids[2]).result.ok, "Abandonar uma das três.")
	assert_true(_bridge.request_contract_accept(_actor_id, fourth.contract_id).result.ok, "Libera exatamente uma vaga: agora a 4ª entra.")
	_books("depois do limite")


func test_saving_with_the_contract_accepted_in_the_real_world_and_loading_keeps_the_hash_the_custody_and_the_delivery_pays() -> void:
	_start(false)
	var a: int = _market("a")
	var made: Array[int] = _bought_at_b_and_back_at_a()
	var contract_id: int = made[0]
	assert_true(_bridge.request_contract_accept(_actor_id, contract_id).result.ok)
	assert_true(_host.runner.can_capture_game(), "Entre passos a fila de eventos está vazia.")
	var hash_saved: String = _host.runner.world.state_hash()
	var funds: int = _funds()
	var decoded: DecodedSave = _codec.decode(_codec.encode(_host.runner.capture_game(), GAME_VERSION))
	assert_true(decoded.result.ok, decoded.result.message)
	_other = SimulationHostNode.new()
	_other.runner = SimulationRunner.new(WORLD_SEED)
	var modules: GameModules = GameModules.register(_other.runner, _terrain, _points, _npc_setup(), _economy_setup(false), _world_setup())
	assert_true(modules.result.ok, modules.result.message)
	_other.character = modules.character
	_other.interaction = modules.interaction
	_other.npc = modules.npc
	_other.economy = modules.economy
	var loaded: Result = _other.runner.load_game(decoded.payload)
	assert_true(loaded.ok, loaded.message)
	var bridge: SimBridge = SimBridge.new(_other, _terrain, _places)
	assert_eq(_other.runner.world.state_hash(), hash_saved, "O mundo carregado tem o `state_hash` do momento do salvamento.")
	var original: EconomyReplies.ContractQuery = _economy.peek_contract(contract_id)
	var again: EconomyReplies.ContractQuery = modules.economy.peek_contract(contract_id)
	assert_eq([again.state, again.acceptor_id, again.reward, again.deadline, again.issuer_id], [original.state, _actor_id, REWARD, original.deadline, a], "O contrato segue `accepted`, com o mesmo aceitante, recompensa e prazo.")
	assert_eq([modules.economy.peek_balance(contract_id).balance, modules.economy.peek_balance(_actor_id).balance, modules.economy.peek_inventory(_actor_id).weight], [REWARD, funds, QUANTITY * modules.economy.peek_good(BREAD).weight], "A custódia de 53, o saldo e a carga do jogador voltam iguais.")
	_books("no mundo carregado", modules.economy)
	assert_eq(bridge.peek_contract_board(_actor_id, a).accepted_limit, LIMIT, "O limite do dado segue valendo.")
	var delivered: BridgePlayerContractsReplies.ContractActionReply = bridge.request_contract_deliver(_actor_id, contract_id)
	assert_true(delivered.result.ok and delivered.reward == REWARD, "Depois de carregar a entrega paga a recompensa.")
	assert_true(_bridge.request_contract_deliver(_actor_id, contract_id).result.ok, "O mundo que não foi salvo entrega do mesmo jeito.")
	assert_eq([modules.economy.peek_balance(_actor_id).balance, modules.economy.peek_balance(contract_id).balance], [funds + REWARD, 0])
	assert_eq(_other.runner.world.state_hash(), _host.runner.world.state_hash(), "Depois da entrega o mundo carregado e o original seguem iguais.")
	_books("depois da entrega no mundo carregado", modules.economy)
