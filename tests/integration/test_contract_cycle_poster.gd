extends GutTest
## LW-107, verificação do ciclo das encomendas (21/11/2026): lacunas do `test_contract_cycle.gd` (que posta os contratos DIRETO). Jogo real de `res://data`, sem NPCs (o relógio anda pelo `runner`); os modelos do postador só são ligados AQUI, em memória (o jogo real tem a tabela vazia e `data/` não muda).
## (1) O ciclo que COMEÇA no postador (LW-107c2, os 3 modelos iniciais): publica na 1ª hora cheia; o jogador compra no A, aceita e entrega no B pela ponte; as duas conservações e o `validate()` fecham a cada passo; ao concluir, o postador reposta na hora cheia seguinte.
## (2) A recompensa do postador é proporcional ao lote (5 e 10 pães). (3) O espaço do limite de 3 aceitos também é liberado ao CONCLUIR (o abandono é do cycle). (4) Salvar com 3 aceitos e carregar: o limite segue valendo, e abandonar e aceitar de novo dão o mesmo resultado e o mesmo `state_hash` do mundo que não foi salvo.
## (5) Emissor morto com a encomenda ACEITA: a entrega ainda é paga pela custódia. (6) Destino sem capacidade (`ECON_CAPACITY_EXCEEDED` real da economia): tudo ou nada, e a entrega funciona quando o espaço aparece. Valores do postador: os literais do contrato (`docs/economy/dados.md`).

const WORLD_DIR: String = "res://data/world"
const EXAMPLE_PATH: String = "res://data/economy/contract_templates.initial.json"
const SEED: int = 107
const SETTLEMENT_A: String = "test_settlement_a"
const SETTLEMENT_B: String = "test_settlement_b"
const BREAD: String = "bread"
const GAME_VERSION: String = "0.0.1-test"
const MINUTES_PER_HOUR: int = 60
## O contrato do teste (direto na economia): recompensa, lote, prazo longo e a caminhada de A até B. O limite do dado real é 3.
const REWARD: int = 30
const QUANTITY: int = 2
const LONG_MINUTES: int = 600
const TRAVEL_MINUTES: int = 30
const LIMIT: int = 3
const CODE_LIMIT: String = "BRIDGE_CONTRACT_LIMIT"
const KEY_LIMIT: String = "economy.contract.limit"
const KEY_FULL: String = "economy.contract.destination_full"
## O pão do postador (`bread_standing`: 5 pães, 500 bp, 48 h): a recompensa da tabela de `dados.md` e o prazo contado do começo da hora cheia; com 10 pães a conta dá 105.
const POSTED_QUANTITY: int = 5
const POSTED_REWARD: int = 53
const POSTED_REWARD_DOUBLE: int = 105
const DEADLINE_HOURS: int = 48
const MARGIN_BP: int = 500

var _terrain: TerrainData
var _places: Array[Place] = []
var _centers: Dictionary[String, Vector3] = {}
var _setup: EconomySetup
var _hosts: Array[SimulationHostNode] = []
var _host: SimulationHostNode
var _bridge: SimBridge
var _economy: EconomyModule
var _actor_id: int = 0
var _market_a: int = 0
var _market_b: int = 0
var _completed: Array[ContractCompleted] = []
var _codec: JsonSaveCodec = JsonSaveCodec.new()


func before_all() -> void:
	var loaded: TerrainLoader.LoadResult = TerrainLoader.load_dir(WORLD_DIR)
	assert_true(loaded.result.ok, loaded.result.message)
	_terrain = loaded.terrain
	var settlements: SettlementLoader.LoadResult = SettlementLoader.load_dir(WORLD_DIR, _terrain)
	assert_true(settlements.result.ok, settlements.result.message)
	_places = settlements.places
	for place: Place in _places:
		if place.kind == Place.KIND_MARKET:
			_centers[place.settlement_id] = place.position


func after_each() -> void:
	for host: SimulationHostNode in _hosts:
		host.runner.finish()
		host.free()
	_hosts = []


## Um jogo só com o personagem e a economia, com o jogador nascido, a conta aberta e junto ao centro do mercado A, no minuto 0; `templates` são os modelos do postador (vazio = o jogo real).
func _start(templates: Array[ContractTemplateDef]) -> void:
	_setup = EconomySetup.from_dir(EconomySetup.DEFAULT_DIR)
	assert_true(_setup.result.ok, _setup.result.message)
	_setup.definitions.contract_templates = templates
	_host = SimulationHostNode.new()
	_hosts.append(_host)
	_host.start_new_game(SEED, _terrain, [], null, 0, _setup)
	_bridge = SimBridge.new(_host, _terrain, _places)
	_economy = _host.economy
	_completed = []
	_host.runner.world.context.events.subscribe("ContractCompleted", func(event: SimEvent) -> void: _completed.append(event))
	_actor_id = _bridge.request_spawn_character().actor_id
	assert_true(_bridge.request_open_player_account(_actor_id).ok)
	_market_a = _economy.peek_market_of(SETTLEMENT_A).market_id
	_market_b = _economy.peek_market_of(SETTLEMENT_B).market_id
	_go(SETTLEMENT_A)


func _initial_templates() -> Array[ContractTemplateDef]:
	var templates: Array[ContractTemplateDef] = []
	var rows: Array = JSON.parse_string(FileAccess.get_file_as_string(EXAMPLE_PATH))
	for row: Dictionary in rows:
		templates.append(ContractTemplateDef.new(str(row["id"]), str(row["kind"]), str(row["good_id"]), int(row["quantity"]), str(row["trigger"]), int(row["reward_margin_bp"]), int(row["deadline_hours"]), int(row["max_open"])))
	return templates


func _go(settlement_id: String) -> void:
	assert_true(_bridge.request_report_position(_actor_id, _centers[settlement_id], 0.0).ok)


func _now() -> int:
	return _bridge.peek_time().total_minutes


func _funds() -> int:
	return _bridge.peek_player_economy(_actor_id).funds


func _cash(owner_id: int) -> int:
	return _economy.peek_balance(owner_id).balance


func _carried() -> int:
	for row: Dictionary in _economy.peek_inventory(_actor_id).rows:
		if row["good_id"] == BREAD:
			return int(row["quantity"])
	return 0


func _moved(reason: String) -> int:
	for row: Dictionary in _economy.peek_ledger_totals().rows:
		if row["reason"] == reason:
			return int(row["moved"])
	return 0


func _money() -> Array:
	var money: EconomyReplies.ConservationQuery = _economy.peek_conservation()
	return [money.sum, money.created, money.destroyed]


func _assert_books_closed(step: String) -> void:
	assert_true(_economy.peek_conservation().ok, "O dinheiro fecha %s." % step)
	assert_true(_economy.peek_goods_conservation().ok, "Os bens fecham %s." % step)
	assert_eq(_economy.validate(), [] as Array[String], "O `validate()` da economia fecha %s." % step)


## Os contratos de ENTREGA da economia no estado `state` (as vagas, que o postador não faz, ficam de fora).
func _deliveries(state: String) -> Array[EconomyReplies.ContractQuery]:
	var rows: Array[EconomyReplies.ContractQuery] = []
	for contract: EconomyReplies.ContractQuery in _economy.peek_contracts(state).contracts:
		if contract.kind == ContractBook.DELIVERY:
			rows.append(contract)
	return rows


func _board(market_id: int) -> Array[BridgePlayerContractsReplies.ContractBoardRow]:
	return _bridge.peek_contract_board(_actor_id, market_id).rows


## Os estados das linhas do quadro do mercado, na ordem do quadro.
func _states(market_id: int) -> Array[String]:
	var states: Array[String] = []
	for row: BridgePlayerContractsReplies.ContractBoardRow in _board(market_id):
		states.append(row.state)
	return states


## Guarda só a oferta de ENTREGA (a economia também oferta as vagas).
func _keep_delivery_offer(offers: Array[ContractOffered], event: SimEvent) -> void:
	var offer: ContractOffered = event as ContractOffered
	if offer.kind == ContractBook.DELIVERY:
		offers.append(offer)


func _buy_bread(quantity: int) -> BridgePlayerEconomyReplies.PlayerTradeReply:
	var bought: BridgePlayerEconomyReplies.PlayerTradeReply = _bridge.request_trade(_actor_id, _market_a, BREAD, quantity, BridgePlayerEconomyReplies.SIDE_BUY)
	assert_true(bought.result.ok, bought.result.message)
	return bought


func _accept(contract_id: int) -> BridgePlayerContractsReplies.ContractActionReply:
	return _bridge.request_contract_accept(_actor_id, contract_id)


func _deliver(contract_id: int) -> BridgePlayerContractsReplies.ContractActionReply:
	return _bridge.request_contract_deliver(_actor_id, contract_id)


## Posta DIRETO na economia o contrato de entrega do mercado B para ele mesmo (QUANTITY pães, REWARD), com o prazo `LONG_MINUTES` depois de agora.
func _post() -> int:
	var posted: EconomyReplies.PostContractResult = _economy.request_post_contract(ContractBook.DELIVERY, _market_b, REWARD, _now() + LONG_MINUTES, {"good_id": BREAD, "quantity": QUANTITY, "destination_id": _market_b})
	assert_true(posted.result.ok, posted.result.message)
	return posted.contract_id


## Compra o lote no A, caminha até o B (TRAVEL_MINUTES) e fica junto ao centro dele.
func _carry_bread_to_b(quantity: int) -> void:
	_buy_bread(quantity)
	_go(SETTLEMENT_B)
	_host.runner.run_steps(TRAVEL_MINUTES)


## Posta LIMIT + 2 contratos, leva pão para entregar um e aceita os LIMIT primeiros. Devolve os IDs.
func _accept_the_limit() -> Array[int]:
	var ids: Array[int] = []
	for _i: int in LIMIT + 2:
		ids.append(_post())
	_carry_bread_to_b(QUANTITY)
	for index: int in LIMIT:
		var accepted: BridgePlayerContractsReplies.ContractActionReply = _accept(ids[index])
		assert_true(accepted.result.ok, accepted.result.message)
	return ids


func _refused_by_limit(bridge: SimBridge, contract_id: int) -> Array:
	var reply: BridgePlayerContractsReplies.ContractActionReply = bridge.request_contract_accept(_actor_id, contract_id)
	return [reply.result.code, reply.text_key, reply.reward]


func test_a_contract_posted_by_the_poster_runs_the_whole_cycle_and_both_books_close_at_every_step() -> void:
	_start(_initial_templates())
	var offered: Array[ContractOffered] = []
	_host.runner.world.context.events.subscribe("ContractOffered", func(event: SimEvent) -> void: _keep_delivery_offer(offered, event))
	var money: Array = _money()
	assert_eq(_deliveries(ContractBook.STATE_OPEN).size(), 0, "Pré-condição: antes da 1ª hora cheia ninguém postou encomenda.")
	_host.runner.run_steps(MINUTES_PER_HOUR)
	_host.runner.world.context.events.dispatch()
	var rows: Array[BridgePlayerContractsReplies.ContractBoardRow] = _board(_market_b)
	assert_eq(rows.size(), 1, "O quadro do B mostra a encomenda de pão do postador (farinha e grão só nascem com escassez, e não há).")
	var row: BridgePlayerContractsReplies.ContractBoardRow = rows[0]
	assert_eq([row.kind, row.state, row.issuer_id, row.destination_id, row.good_id, row.quantity, row.reward, row.deadline, row.is_mine], [ContractBook.DELIVERY, ContractBook.STATE_OPEN, _market_b, _market_b, BREAD, POSTED_QUANTITY, POSTED_REWARD, MINUTES_PER_HOUR + DEADLINE_HOURS * MINUTES_PER_HOUR, false], "A encomenda do postador: emissor e destino o mercado, 5 pães, 53 e o prazo contado do começo da hora cheia.")
	var escrowed: int = 0
	for contract: EconomyReplies.ContractQuery in _deliveries(ContractBook.STATE_OPEN):
		escrowed += contract.reward
		assert_eq(_cash(contract.contract_id), contract.reward, "A custódia de cada encomenda postada guarda a recompensa inteira.")
	assert_eq([offered.size(), _moved(Ledger.REASON_CONTRACT_ESCROW), _moved(Ledger.REASON_CONTRACT_PAYOUT)], [_deliveries(ContractBook.STATE_OPEN).size(), escrowed, 0], "Sai uma oferta por contrato, o livro-razão reteve a soma das recompensas e nada foi pago.")
	assert_eq(_money(), money, "Postar só move dinheiro do mercado para a custódia: nada criado nem destruído.")
	_assert_books_closed("depois da postagem")
	var contract_id: int = row.contract_id
	var funds_start: int = _funds()
	var bought: BridgePlayerEconomyReplies.PlayerTradeReply = _buy_bread(POSTED_QUANTITY)
	_assert_books_closed("depois da compra")
	_go(SETTLEMENT_B)
	_host.runner.run_steps(TRAVEL_MINUTES)
	var accepted: BridgePlayerContractsReplies.ContractActionReply = _accept(contract_id)
	assert_true(accepted.result.ok, accepted.result.message)
	assert_eq([accepted.reward, _economy.peek_contract(contract_id).acceptor_id, _cash(contract_id), _funds()], [POSTED_REWARD, _actor_id, POSTED_REWARD, funds_start - bought.total], "Aceitar grava o jogador e não move dinheiro: a recompensa segue na custódia.")
	_assert_books_closed("depois do aceite")
	var stock: int = _economy.peek_stock(_market_b, BREAD).value
	var delivered: BridgePlayerContractsReplies.ContractActionReply = _deliver(contract_id)
	assert_true(delivered.result.ok, delivered.result.message)
	assert_eq([delivered.reward, _funds(), _cash(contract_id), _carried(), _economy.peek_stock(_market_b, BREAD).value], [POSTED_REWARD, funds_start - bought.total + POSTED_REWARD, 0, 0, stock + POSTED_QUANTITY], "A recompensa saiu da custódia para o jogador e os pães foram para o estoque do B.")
	_host.runner.world.context.events.dispatch()
	assert_eq([_completed.size(), _moved(Ledger.REASON_CONTRACT_PAYOUT), _moved(Ledger.REASON_CONTRACT_REFUND)], [1, POSTED_REWARD, 0])
	_assert_books_closed("depois da entrega")
	assert_eq(_money(), money, "O ciclo inteiro só moveu dinheiro: nada criado nem destruído.")
	_host.runner.run_steps(MINUTES_PER_HOUR - _now() % MINUTES_PER_HOUR)
	assert_eq(_states(_market_b), [ContractBook.STATE_COMPLETED] as Array[String], "Na hora cheia seguinte o postador NÃO reposta: os 5 pães entregues puseram o estoque do B acima do alvo, o `ask` caiu e a regra (b) (recompensa até `ask` x lote) segura a postagem.")
	assert_true(_economy.request_transfer_goods(_market_b, _market_a, BREAD, POSTED_QUANTITY).ok, "O excedente volta ao A (o consumo faria isso): o estoque do B volta ao alvo.")
	_host.runner.run_steps(MINUTES_PER_HOUR)
	rows = _board(_market_b)
	assert_eq([_states(_market_b), rows[1].contract_id > contract_id, rows[1].reward, rows[1].deadline], [[ContractBook.STATE_COMPLETED, ContractBook.STATE_OPEN] as Array[String], true, POSTED_REWARD, 3 * MINUTES_PER_HOUR + DEADLINE_HOURS * MINUTES_PER_HOUR], "Com o `ask` de volta, o postador reposta (a concluída liberou o espaço), com o prazo contado da hora cheia em que nasceu.")
	_assert_books_closed("depois da repostagem")


func test_the_reward_the_poster_posts_grows_in_proportion_to_the_lot() -> void:
	var rewards: Array[int] = []
	for quantity: int in [POSTED_QUANTITY, 2 * POSTED_QUANTITY]:
		var template: Array[ContractTemplateDef] = [ContractTemplateDef.new("bread_standing", ContractBook.DELIVERY, BREAD, quantity, "standing", MARGIN_BP, DEADLINE_HOURS, 1)]
		_start(template)
		_host.runner.run_steps(MINUTES_PER_HOUR)
		rewards.append(_board(_market_b)[0].reward)
	assert_eq(rewards, [POSTED_REWARD, POSTED_REWARD_DOUBLE] as Array[int], "5 pães pagam 53 e 10 pães pagam 105 (a conta da seção 8, com o arredondamento para cima).")
	assert_true(rewards[1] <= 2 * rewards[0] and rewards[1] >= 2 * rewards[0] - 1, "O dobro do lote paga o dobro, a menos de 1 de arredondamento: sem prêmio nem desconto por lote.")


func test_completing_a_delivery_frees_a_slot_of_the_limit_just_like_abandoning_one() -> void:
	_start([])
	var ids: Array[int] = _accept_the_limit()
	assert_eq(_refused_by_limit(_bridge, ids[LIMIT]), [CODE_LIMIT, KEY_LIMIT, 0], "A 4ª aceitação é recusada: o limite do dado real é 3.")
	assert_true(_deliver(ids[0]).result.ok, "Entregar um dos 3 conclui o contrato.")
	assert_eq(_economy.peek_contract(ids[0]).state, ContractBook.STATE_COMPLETED)
	assert_true(_accept(ids[LIMIT]).result.ok, "Concluir liberou uma vaga: a aceitação que foi recusada agora entra.")
	assert_eq(_refused_by_limit(_bridge, ids[LIMIT + 1]), [CODE_LIMIT, KEY_LIMIT, 0], "Só uma vaga se liberou: a próxima volta a ser recusada.")
	var states: Array[String] = _states(_market_b)
	assert_eq([_bridge.peek_contract_board(_actor_id, _market_b).accepted_limit, states.count(ContractBook.STATE_ACCEPTED), states.count(ContractBook.STATE_COMPLETED)], [LIMIT, LIMIT, 1], "O quadro mostra 3 aceitas (o limite) e 1 concluída.")
	_assert_books_closed("depois de concluir e aceitar de novo")


func test_saving_with_three_accepted_and_loading_keeps_the_limit_and_the_same_abandon_and_slot_follow() -> void:
	_start([])
	var ids: Array[int] = _accept_the_limit()
	assert_true(_host.runner.can_capture_game(), "Entre passos a fila de eventos está vazia.")
	var decoded: DecodedSave = _codec.decode(_codec.encode(_host.runner.capture_game(), GAME_VERSION))
	assert_true(decoded.result.ok, decoded.result.message)
	var loaded: SimulationHostNode = SimulationHostNode.new()
	_hosts.append(loaded)
	loaded.runner = SimulationRunner.new(SEED)
	var modules: GameModules = GameModules.register(loaded.runner, _terrain, [], null, _setup)
	assert_true(modules.result.ok, modules.result.message)
	loaded.character = modules.character
	loaded.economy = modules.economy
	assert_true(loaded.runner.load_game(decoded.payload).ok)
	var loaded_bridge: SimBridge = SimBridge.new(loaded, _terrain, _places)
	assert_eq(loaded.runner.world.state_hash(), _host.runner.world.state_hash(), "O mundo carregado tem o `state_hash` do salvamento.")
	var played: Array = []
	for pair: Array in [[_bridge, _economy], [loaded_bridge, modules.economy]]:
		var bridge: SimBridge = pair[0]
		var economy: EconomyModule = pair[1]
		var steps: Array = [_refused_by_limit(bridge, ids[LIMIT])]
		var abandoned: BridgePlayerContractsReplies.ContractActionReply = bridge.request_contract_abandon(_actor_id, ids[0])
		steps.append([abandoned.result.ok, economy.peek_contract(ids[0]).state, economy.peek_contract(ids[0]).closed_reason, economy.peek_balance(ids[0]).balance])
		steps.append(bridge.request_contract_accept(_actor_id, ids[LIMIT]).result.ok)
		steps.append(_refused_by_limit(bridge, ids[LIMIT + 1]))
		played.append(steps)
	assert_eq(played[1], played[0], "Depois de carregar, o limite, o abandono e a vaga liberada se comportam como no mundo que não foi salvo.")
	assert_eq(played[0], [[CODE_LIMIT, KEY_LIMIT, 0], [true, ContractBook.STATE_FAILED, "abandoned", 0], true, [CODE_LIMIT, KEY_LIMIT, 0]], "O limite de 3 vale para o mundo carregado, o abandono devolve a custódia (saldo 0) e libera uma vaga.")
	assert_eq(loaded.runner.world.state_hash(), _host.runner.world.state_hash(), "Os dois mundos terminam com o mesmo `state_hash`.")
	assert_eq([modules.economy.peek_conservation().ok, modules.economy.peek_goods_conservation().ok, modules.economy.validate()], [true, true, [] as Array[String]], "As conservações e o `validate()` fecham no mundo carregado.")


func test_with_the_issuer_dead_the_accepted_delivery_is_still_delivered_and_paid_by_the_custody() -> void:
	_start([])
	var issuer: int = _host.runner.world.context.ids.next_id()
	assert_true(_economy.request_open_owner(issuer, "npc").ok)
	var posted: EconomyReplies.PostContractResult = _economy.request_post_contract(ContractBook.DELIVERY, issuer, REWARD, _now() + LONG_MINUTES, {"good_id": BREAD, "quantity": QUANTITY, "destination_id": _market_b})
	assert_true(posted.result.ok, posted.result.message)
	_carry_bread_to_b(QUANTITY)
	assert_true(_accept(posted.contract_id).result.ok, "O emissor não é mercado, mas o destino é: o aceite vale ao alcance do B.")
	_host.runner.world.context.events.publish(NpcDied.new(issuer, "test", 0))
	_host.runner.world.context.events.dispatch()
	assert_eq([_economy.peek_contract(posted.contract_id).state, _cash(posted.contract_id)], [ContractBook.STATE_ACCEPTED, REWARD], "A morte do emissor não mexe na encomenda aceita nem na custódia.")
	_assert_books_closed("depois da morte do emissor")
	var funds: int = _funds()
	var delivered: BridgePlayerContractsReplies.ContractActionReply = _deliver(posted.contract_id)
	assert_true(delivered.result.ok, delivered.result.message)
	assert_eq([_funds(), _cash(posted.contract_id), _carried(), _economy.peek_contract(posted.contract_id).state], [funds + REWARD, 0, 0, ContractBook.STATE_COMPLETED], "O jogador recebe da custódia, mesmo com o emissor morto.")
	_assert_books_closed("depois da entrega")


func test_delivering_to_a_destination_without_room_changes_nothing_and_works_when_the_room_appears() -> void:
	_start([])
	var destination: int = _host.runner.world.context.ids.next_id()
	assert_true(_economy.request_open_owner(destination, "npc").ok)
	var weight: int = _economy.peek_good(BREAD).weight
	var free_units: int = IntMath.floor_div(_economy.peek_inventory(destination).capacity - _economy.peek_inventory(destination).weight, weight)
	assert_true(_economy.request_transfer_goods(_market_a, destination, BREAD, free_units - QUANTITY + 1).ok, "Pré-condição: o destino fica com 1 unidade a menos do que o lote pede.")
	var posted: EconomyReplies.PostContractResult = _economy.request_post_contract(ContractBook.DELIVERY, _market_b, REWARD, _now() + LONG_MINUTES, {"good_id": BREAD, "quantity": QUANTITY, "destination_id": destination})
	assert_true(posted.result.ok, posted.result.message)
	_carry_bread_to_b(QUANTITY)
	assert_true(_accept(posted.contract_id).result.ok, "O emissor é o mercado B: o aceite vale.")
	var hash_before: String = _host.runner.world.state_hash()
	var held: Array = [_funds(), _carried(), _cash(posted.contract_id), _cash(destination), _economy.peek_inventory(destination).weight]
	var refused: Result = _economy.request_deliver_contract(posted.contract_id)
	assert_eq(refused.code, EconomyCodes.CAPACITY_EXCEEDED, "O destino não comporta o lote: a economia recusa com o código de capacidade.")
	assert_eq(BridgePlayerContractsReplies.ContractActionReply.new(refused, posted.contract_id).text_key, KEY_FULL, "A ponte traduz a recusa real para a chave do destino cheio.")
	assert_eq([_host.runner.world.state_hash(), [_funds(), _carried(), _cash(posted.contract_id), _cash(destination), _economy.peek_inventory(destination).weight], _economy.peek_contract(posted.contract_id).state], [hash_before, held, ContractBook.STATE_ACCEPTED], "Tudo ou nada: nada se moveu, nada foi pago e o contrato segue aceito.")
	_assert_books_closed("depois da recusa")
	assert_true(_economy.request_transfer_goods(destination, _market_a, BREAD, 1).ok, "O espaço aparece: o destino devolve uma unidade.")
	assert_true(_economy.request_deliver_contract(posted.contract_id).ok, "Com espaço a entrega funciona.")
	assert_eq([_funds(), _carried(), _cash(posted.contract_id), _economy.peek_contract(posted.contract_id).state], [held[0] + REWARD, 0, 0, ContractBook.STATE_COMPLETED], "A custódia pagou o jogador e os pães saíram dele.")
	_assert_books_closed("depois da entrega com espaço")
