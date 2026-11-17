extends GutTest
## LW-107g: o CICLO do contrato de entrega do jogador, de ponta a ponta e sem janela (C4 de docs/modules/bridge.md, "Quadro de contratos do jogador", item (v)), com o jogo real de `res://data` (economia, terreno e locais; sem NPCs, o relógio anda pelo `runner`). O contrato é postado DIRETO na economia
## pelo teste (o jogador não posta), com emissor e destino no mercado B, como o postador da LW-107c2 vai fazer. Cobre: (1) comprar no mercado A, aceitar e entregar no B paga a recompensa, zera a custódia, move os bens e mantém as duas conservações (dinheiro e bens) depois de CADA passo, inclusive com a
## entrega em `deadline - 1`; (2) aceitar e deixar vencer (relógio além do prazo mais 1 hora) dá `expired`, `ContractFailed`, custódia de volta ao emissor e saldo do jogador intacto, e a entrega depois disso é recusada sem mudar nada; (3) salvar e carregar com o contrato `accepted` mantém
## o contrato, a custódia e o `state_hash`, e a entrega ainda funciona; (4) no ciclo, entregar sem os bens e entregar o contrato de outro ator são recusados sem mudar nada. Valores à mão: recompensa e quantidade são as constantes do teste e o relógio parte do minuto 0.
## LW-107f5 (a mesma montagem; docs/modules/economy.md, seção 8, item 107f5, DEC-237): (5) comprar, aceitar e ABANDONAR pela ponte: a custódia volta ao emissor, o saldo e os bens do jogador ficam intactos, o contrato fica `failed` com o `closed_reason` `abandoned` e sai UM `ContractFailed`
## com esse motivo; (6) o limite do dado real (3 entregas aceitas por vez): a 4ª aceitação é recusada com `BRIDGE_CONTRACT_LIMIT` SEM chamar a economia e abandonar uma libera exatamente uma vaga; (7) salvar e carregar com a encomenda abandonada mantém o `closed_reason` e o `state_hash`, e o mundo SEM
## abandono segue salvo como antes da 107f (o `completed` e o `expired` sem o campo `closed_reason`; mesma semente e mesmo roteiro, mesmo `state_hash`). O limite, o código, as chaves e os campos salvos são literais DO CONTRATO de propósito: o teste não herda o valor do código que ele confere.

const WORLD_DIR: String = "res://data/world"
const SEED: int = 107
const SETTLEMENT_A: String = "test_settlement_a"
const SETTLEMENT_B: String = "test_settlement_b"
const BREAD: String = "bread"
const GAME_VERSION: String = "0.0.1-test"
const MINUTES_PER_HOUR: int = 60
## O contrato do teste (os números do jogo são [HIP]): recompensa e quantidade; o prazo longo e o curto (minutos depois do minuto 0, quando o contrato é postado) e a caminhada de A até B.
const REWARD: int = 30
const QUANTITY: int = 2
const LONG_MINUTES: int = 600
const SHORT_MINUTES: int = 90
const TRAVEL_MINUTES: int = 30
const KEY_ACCEPTED: String = "economy.contract.accepted"
const KEY_DELIVERED: String = "economy.contract.delivered"
const KEY_NOT_OPEN: String = "economy.contract.not_open"
const KEY_IMPOSSIBLE: String = "economy.contract.impossible"
const KEY_NO_GOODS: String = "economy.contract.no_goods"
const KEY_NOT_YOURS: String = "economy.contract.not_yours"
## Os literais da 107f (ponte e dado): o limite de `data/economy/contract_limits.json`, o motivo do abandono, o campo salvo, o código e as chaves, e os campos de um contrato de entrega como o save os grava SEM abandono (os mesmos de antes da 107f, em ordem alfabética).
const LIMIT: int = 3
const ABANDONED: String = "abandoned"
const REASON_KEY: String = "closed_reason"
const CODE_LIMIT: String = "BRIDGE_CONTRACT_LIMIT"
const KEY_ABANDONED: String = "economy.contract.abandoned"
const KEY_LIMIT: String = "economy.contract.limit"
const SAVED_KEYS: Array = ["acceptor_id", "deadline", "destination_id", "good_id", "issuer_id", "kind", "quantity", "reward", "state"]

var _terrain: TerrainData
var _places: Array[Place] = []
var _setup: EconomySetup
var _center_a: Vector3
var _center_b: Vector3
var _host: SimulationHostNode
var _bridge: SimBridge
var _economy: EconomyModule
var _actor_id: int = 0
var _market_a: int = 0
var _market_b: int = 0
var _completed: Array[ContractCompleted] = []
var _failed: Array[ContractFailed] = []
var _codec: JsonSaveCodec = JsonSaveCodec.new()


func before_all() -> void:
	var loaded: TerrainLoader.LoadResult = TerrainLoader.load_dir(WORLD_DIR)
	assert_true(loaded.result.ok, loaded.result.message)
	_terrain = loaded.terrain
	var settlements: SettlementLoader.LoadResult = SettlementLoader.load_dir(WORLD_DIR, _terrain)
	assert_true(settlements.result.ok, settlements.result.message)
	_places = settlements.places
	var centers: Dictionary[String, Vector3] = {}
	for place: Place in _places:
		if place.kind == Place.KIND_MARKET:
			centers[place.settlement_id] = place.position
	_center_a = centers[SETTLEMENT_A]
	_center_b = centers[SETTLEMENT_B]
	_setup = EconomySetup.from_dir(EconomySetup.DEFAULT_DIR)
	assert_true(_setup.result.ok, _setup.result.message)


## Um jogo só com o personagem e a economia (sem NPCs), com o jogador nascido, com a conta aberta e junto ao centro do mercado A, no minuto 0. Os eventos de contrato concluído e falho ficam em `_completed` e `_failed`.
func before_each() -> void:
	_host = SimulationHostNode.new()
	_host.start_new_game(SEED, _terrain, [], null, 0, _setup)
	_bridge = SimBridge.new(_host, _terrain, _places)
	_economy = _host.economy
	_completed = []
	_failed = []
	_host.runner.world.context.events.subscribe("ContractCompleted", func(event: SimEvent) -> void: _completed.append(event))
	_host.runner.world.context.events.subscribe("ContractFailed", func(event: SimEvent) -> void: _failed.append(event))
	_actor_id = _bridge.request_spawn_character().actor_id
	assert_true(_bridge.request_open_player_account(_actor_id).ok)
	_market_a = _economy.peek_market_of(SETTLEMENT_A).market_id
	_market_b = _economy.peek_market_of(SETTLEMENT_B).market_id
	_go(_center_a)


func after_each() -> void:
	_host.runner.finish()
	_host.free()


func _go(spot: Vector3) -> void:
	var reported: Result = _bridge.request_report_position(_actor_id, spot, 0.0)
	assert_true(reported.ok, reported.message)


func _now() -> int:
	return _bridge.peek_time().total_minutes


func _funds() -> int:
	return _bridge.peek_player_economy(_actor_id).funds


func _cash(owner_id: int) -> int:
	return _economy.peek_balance(owner_id).balance


## Quantos pães o jogador carrega.
func _carried() -> int:
	for row: Dictionary in _economy.peek_inventory(_actor_id).rows:
		if row["good_id"] == BREAD:
			return int(row["quantity"])
	return 0


func _accept(contract_id: int) -> BridgePlayerContractsReplies.ContractActionReply:
	return _bridge.request_contract_accept(_actor_id, contract_id)


func _deliver(contract_id: int) -> BridgePlayerContractsReplies.ContractActionReply:
	return _bridge.request_contract_deliver(_actor_id, contract_id)


## Posta DIRETO na economia o contrato de entrega do mercado B para ele mesmo (emissor e destino iguais, como o postador): B paga REWARD para a custódia e o prazo é `minutes` depois de agora.
func _post(minutes: int) -> int:
	var posted: EconomyReplies.PostContractResult = _economy.request_post_contract(ContractBook.DELIVERY, _market_b, REWARD, _now() + minutes, {"good_id": BREAD, "quantity": QUANTITY, "destination_id": _market_b})
	assert_true(posted.result.ok, posted.result.message)
	return posted.contract_id


## O jogador compra QUANTITY pães no mercado A (ele precisa estar lá).
func _buy_bread() -> BridgePlayerEconomyReplies.PlayerTradeReply:
	var bought: BridgePlayerEconomyReplies.PlayerTradeReply = _bridge.request_trade(_actor_id, _market_a, BREAD, QUANTITY, BridgePlayerEconomyReplies.SIDE_BUY)
	assert_true(bought.result.ok, bought.result.message)
	return bought


## O começo do ciclo: o contrato do B postado no minuto 0, a compra no A, TRAVEL_MINUTES de caminhada até o B e o aceite lá. Devolve o contrato, `accepted`, com o jogador junto ao B (minuto TRAVEL_MINUTES).
func _start_cycle(minutes: int) -> int:
	var contract_id: int = _post(minutes)
	_buy_bread()
	_go(_center_b)
	_host.runner.run_steps(TRAVEL_MINUTES)
	var accepted: BridgePlayerContractsReplies.ContractActionReply = _accept(contract_id)
	assert_true(accepted.result.ok, accepted.result.message)
	return contract_id


func _moved(reason: String) -> int:
	for row: Dictionary in _economy.peek_ledger_totals().rows:
		if row["reason"] == reason:
			return int(row["moved"])
	return 0


## O dinheiro do mundo (soma das contas, criado e destruído): o ciclo só MOVE dinheiro, então os três não mudam.
func _money() -> Array:
	var money: EconomyReplies.ConservationQuery = _economy.peek_conservation()
	return [money.sum, money.created, money.destroyed]


## As duas conservações (dinheiro e bens) e o `validate()` da economia fecham depois do passo `step`.
func _assert_books_closed(step: String) -> void:
	assert_true(_economy.peek_conservation().ok, "O dinheiro fecha %s." % step)
	assert_true(_economy.peek_goods_conservation().ok, "Os bens fecham %s." % step)
	assert_eq(_economy.validate(), [] as Array[String], "O `validate()` da economia fecha %s." % step)


## O que o quadro do mercado mostra do jogador, por estado, na ordem dos contratos.
func _board_states(market_id: int) -> Array[String]:
	var states: Array[String] = []
	for row: BridgePlayerContractsReplies.ContractBoardRow in _bridge.peek_contract_board(_actor_id, market_id).rows:
		states.append(row.state)
	return states


## O que um pedido recusado não pode mexer, além do `state_hash` e da fila de eventos: o saldo e os pães do jogador, o estoque e o caixa do B e a custódia do contrato.
func _holdings(contract_id: int) -> Array:
	return [_funds(), _carried(), _economy.peek_stock(_market_b, BREAD).value, _cash(_market_b), _cash(contract_id)]


func _snapshot() -> Array:
	return [_host.runner.world.state_hash(), int(_host.runner.world.context.events.debug_summary()["pending"])]


## A entrega de `actor_id` é recusada com `code`, a chave `key` e recompensa 0, e NADA muda: nem o `state_hash` nem a fila de eventos, nem o dinheiro e os bens (`_holdings`).
func _refused_deliver(actor_id: int, contract_id: int, code: String, key: String) -> void:
	var before: Array = _snapshot()
	var held: Array = _holdings(contract_id)
	var reply: BridgePlayerContractsReplies.ContractActionReply = _bridge.request_contract_deliver(actor_id, contract_id)
	assert_eq([reply.result.code, reply.text_key, reply.reward, reply.contract_id], [code, key, 0, contract_id], "A entrega recusada do contrato %d." % contract_id)
	assert_eq(_snapshot(), before, "A recusa não mudou o mundo (nem o `state_hash`, nem evento).")
	assert_eq(_holdings(contract_id), held, "A recusa não mudou o dinheiro nem os bens.")


## Os campos do contrato como a economia os dá, na ordem: tipo, estado, emissor, aceitante, recompensa, prazo, bem, quantidade e destino.
func _fields(economy: EconomyModule, contract_id: int) -> Array:
	var contract: EconomyReplies.ContractQuery = economy.peek_contract(contract_id)
	return [contract.kind, contract.state, contract.issuer_id, contract.acceptor_id, contract.reward, contract.deadline, contract.good_id, contract.quantity, contract.destination_id]


func test_the_player_buys_at_a_accepts_and_delivers_at_b_the_reward_is_paid_and_both_books_close_at_every_step() -> void:
	var cash_b: int = _cash(_market_b)
	var contract_id: int = _post(LONG_MINUTES)
	var money: Array = _money()
	var funds_start: int = _funds()
	var cash_a: int = _cash(_market_a)
	assert_eq([_cash(_market_b), _cash(contract_id)], [cash_b - REWARD, REWARD], "Pré-condição: o emissor pagou a recompensa para a custódia.")
	var bought: BridgePlayerEconomyReplies.PlayerTradeReply = _buy_bread()
	assert_eq([_funds(), _cash(_market_a), _carried(), _economy.peek_inventory(_actor_id).weight], [funds_start - bought.total, cash_a + bought.total, QUANTITY, QUANTITY * _economy.peek_good(BREAD).weight], "A compra no A: o jogador paga o total, leva os pães e o peso conta.")
	_assert_books_closed("depois da compra")
	assert_eq(_money(), money, "Comprar só move dinheiro.")
	_go(_center_b)
	_host.runner.run_steps(TRAVEL_MINUTES)
	assert_eq(_board_states(_market_b), [ContractBook.STATE_OPEN] as Array[String], "No B o quadro mostra o contrato aberto.")
	var accepted: BridgePlayerContractsReplies.ContractActionReply = _accept(contract_id)
	assert_true(accepted.result.ok, accepted.result.message)
	assert_eq([accepted.reward, accepted.text_key], [REWARD, KEY_ACCEPTED])
	assert_eq(_fields(_economy, contract_id), [ContractBook.DELIVERY, ContractBook.STATE_ACCEPTED, _market_b, _actor_id, REWARD, LONG_MINUTES, BREAD, QUANTITY, _market_b], "O aceite grava o jogador como aceitante e não muda o resto.")
	assert_eq([_funds(), _cash(contract_id)], [funds_start - bought.total, REWARD], "Aceitar não mexe no saldo: a recompensa segue na custódia.")
	assert_eq(_board_states(_market_b), [ContractBook.STATE_ACCEPTED] as Array[String], "O quadro mostra o contrato como aceito.")
	_assert_books_closed("depois do aceite")
	assert_eq(_money(), money, "Aceitar não move dinheiro.")
	var stock: int = _economy.peek_stock(_market_b, BREAD).value
	var delivered: BridgePlayerContractsReplies.ContractActionReply = _deliver(contract_id)
	assert_true(delivered.result.ok, delivered.result.message)
	assert_eq([delivered.reward, delivered.text_key], [REWARD, KEY_DELIVERED])
	assert_eq([_funds(), _cash(contract_id), _cash(_market_a), _cash(_market_b)], [funds_start - bought.total + REWARD, 0, cash_a + bought.total, cash_b - REWARD], "A recompensa subiu no saldo, a custódia zerou: o dinheiro foi do B para o jogador e do jogador para o A.")
	assert_eq([_economy.peek_stock(_market_b, BREAD).value, _carried(), _economy.peek_inventory(_actor_id).weight], [stock + QUANTITY, 0, 0], "Os pães saíram do jogador e entraram no estoque do B.")
	assert_eq([_economy.peek_contract(contract_id).state, _board_states(_market_b)], [ContractBook.STATE_COMPLETED, [ContractBook.STATE_COMPLETED] as Array[String]])
	assert_eq([_moved(Ledger.REASON_CONTRACT_ESCROW), _moved(Ledger.REASON_CONTRACT_PAYOUT), _moved(Ledger.REASON_CONTRACT_REFUND)], [REWARD, REWARD, 0], "No livro-razão: reteve, pagou e nada foi devolvido.")
	_host.runner.world.context.events.dispatch()
	assert_eq([_completed.size(), _failed.size()], [1, 0], "Sai UM `ContractCompleted` e nenhum `ContractFailed`.")
	assert_eq([_completed[0].contract_id, _completed[0].acceptor_id, _completed[0].reward], [contract_id, _actor_id, REWARD])
	_assert_books_closed("depois da entrega")
	assert_eq(_money(), money, "O ciclo inteiro só moveu dinheiro: nada criado nem destruído.")


func test_delivering_at_the_last_minute_before_the_deadline_still_pays() -> void:
	var contract_id: int = _start_cycle(SHORT_MINUTES)
	var funds_before: int = _funds()
	_host.runner.run_steps(SHORT_MINUTES - 1 - _now())
	assert_eq(_economy.peek_contract(contract_id).deadline - _now(), 1, "Pré-condição: o relógio está em `deadline - 1`, depois da hora cheia de 01:00 e antes da que venceria o contrato.")
	var delivered: BridgePlayerContractsReplies.ContractActionReply = _deliver(contract_id)
	assert_true(delivered.result.ok, delivered.result.message)
	assert_eq([_funds(), _economy.peek_contract(contract_id).state, _cash(contract_id)], [funds_before + REWARD, ContractBook.STATE_COMPLETED, 0], "Em `deadline - 1` a entrega dá certo e paga.")
	_host.runner.world.context.events.dispatch()
	assert_eq([_completed.size(), _failed.size()], [1, 0])
	_assert_books_closed("depois da entrega no limite")


func test_an_accepted_contract_left_to_expire_fails_the_custody_goes_back_to_the_issuer_and_the_funds_stay_intact() -> void:
	var cash_b: int = _cash(_market_b)
	var contract_id: int = _start_cycle(SHORT_MINUTES)
	var money: Array = _money()
	var funds_kept: int = _funds()
	assert_eq([_cash(_market_b), _cash(contract_id)], [cash_b - REWARD, REWARD], "Pré-condição: a recompensa está na custódia, fora do caixa do emissor.")
	_host.runner.run_steps(SHORT_MINUTES - _now())
	_host.runner.world.context.events.dispatch()
	assert_eq([_now(), _economy.peek_contract(contract_id).state, _failed.size()], [SHORT_MINUTES, ContractBook.STATE_ACCEPTED, 0], "No minuto do prazo a economia ainda não venceu o contrato (só na hora cheia).")
	_refused_deliver(_actor_id, contract_id, EconomyCodes.CONTRACT_IMPOSSIBLE, KEY_IMPOSSIBLE)
	_host.runner.run_steps(SHORT_MINUTES + MINUTES_PER_HOUR - _now())
	_host.runner.world.context.events.dispatch()
	assert_eq(_now(), SHORT_MINUTES + MINUTES_PER_HOUR, "O relógio passou da hora cheia que vence (02:00) e foi além do prazo mais 1 hora.")
	assert_eq(_economy.peek_contract(contract_id).state, ContractBook.STATE_EXPIRED)
	assert_eq(_failed.size(), 1, "Sai UM `ContractFailed`.")
	assert_eq([_failed[0].contract_id, _failed[0].issuer_id, _failed[0].reason], [contract_id, _market_b, "expired"])
	assert_eq(_completed.size(), 0, "Nenhum `ContractCompleted`.")
	assert_eq([_cash(contract_id), _cash(_market_b)], [0, cash_b], "A custódia voltou inteira ao emissor.")
	assert_eq([_moved(Ledger.REASON_CONTRACT_REFUND), _moved(Ledger.REASON_CONTRACT_PAYOUT)], [REWARD, 0], "No livro-razão: devolveu e não pagou.")
	assert_eq([_funds(), _carried()], [funds_kept, QUANTITY], "O saldo do jogador está intacto (sem recompensa e sem multa) e os pães que ele comprou continuam com ele.")
	assert_eq(_board_states(_market_b), [ContractBook.STATE_EXPIRED] as Array[String], "O quadro mostra o contrato vencido.")
	assert_eq(_money(), money, "Vencer só devolve dinheiro: nada criado nem destruído.")
	_assert_books_closed("depois do vencimento")
	_refused_deliver(_actor_id, contract_id, EconomyCodes.CONTRACT_NOT_OPEN, KEY_NOT_OPEN)


func test_saving_with_the_contract_accepted_and_loading_keeps_the_contract_the_custody_and_the_hash_and_the_delivery_still_pays() -> void:
	var contract_id: int = _start_cycle(LONG_MINUTES)
	assert_true(_host.runner.can_capture_game(), "Entre passos a fila de eventos está vazia.")
	var hash_saved: String = _host.runner.world.state_hash()
	var funds: int = _funds()
	var decoded: DecodedSave = _codec.decode(_codec.encode(_host.runner.capture_game(), GAME_VERSION))
	assert_true(decoded.result.ok, decoded.result.message)
	var loaded: SimulationHostNode = SimulationHostNode.new()
	loaded.runner = SimulationRunner.new(SEED)
	var modules: GameModules = GameModules.register(loaded.runner, _terrain, [], null, _setup)
	assert_true(modules.result.ok, modules.result.message)
	loaded.character = modules.character
	loaded.economy = modules.economy
	var result: Result = loaded.runner.load_game(decoded.payload)
	assert_true(result.ok, result.message)
	var bridge: SimBridge = SimBridge.new(loaded, _terrain, _places)
	assert_eq(loaded.runner.world.state_hash(), hash_saved, "O mundo carregado tem o `state_hash` do momento do salvamento.")
	assert_eq(_fields(modules.economy, contract_id), [ContractBook.DELIVERY, ContractBook.STATE_ACCEPTED, _market_b, _actor_id, REWARD, LONG_MINUTES, BREAD, QUANTITY, _market_b], "O contrato segue `accepted`, com o mesmo aceitante e o resto igual.")
	assert_eq([modules.economy.peek_balance(contract_id).balance, modules.economy.peek_balance(_actor_id).balance, modules.economy.peek_inventory(_actor_id).weight], [REWARD, funds, QUANTITY * modules.economy.peek_good(BREAD).weight], "A custódia, o saldo e a carga do jogador voltam iguais.")
	assert_eq([modules.economy.peek_conservation().ok, modules.economy.peek_goods_conservation().ok, modules.economy.validate()], [true, true, [] as Array[String]], "As conservações e o `validate()` fecham no mundo carregado.")
	var done: Array[ContractCompleted] = []
	loaded.runner.world.context.events.subscribe("ContractCompleted", func(event: SimEvent) -> void: done.append(event))
	var delivered: BridgePlayerContractsReplies.ContractActionReply = bridge.request_contract_deliver(_actor_id, contract_id)
	assert_true(delivered.result.ok, delivered.result.message)
	assert_true(_deliver(contract_id).result.ok, "O mundo que não foi salvo entrega do mesmo jeito.")
	loaded.runner.world.context.events.dispatch()
	assert_eq([done.size(), modules.economy.peek_contract(contract_id).state, modules.economy.peek_balance(_actor_id).balance, modules.economy.peek_balance(contract_id).balance], [1, ContractBook.STATE_COMPLETED, funds + REWARD, 0], "Depois de carregar, a entrega paga a recompensa e sai UM `ContractCompleted`.")
	assert_eq(loaded.runner.world.state_hash(), _host.runner.world.state_hash(), "Depois da entrega o mundo carregado e o original seguem iguais.")
	loaded.runner.finish()
	loaded.free()


func test_in_the_cycle_delivering_without_the_goods_or_the_contract_of_another_actor_is_refused_and_changes_nothing() -> void:
	var mine: int = _post(LONG_MINUTES)
	var theirs: int = _post(LONG_MINUTES)
	var npcs: int = _post(LONG_MINUTES)
	var other: int = _bridge.request_spawn_character().actor_id
	assert_true(_bridge.request_report_position(other, _center_b, 0.0).ok)
	assert_true(_bridge.request_open_player_account(other).ok)
	var npc_id: int = _host.runner.world.context.ids.next_id()
	assert_true(_economy.request_open_owner(npc_id, "npc").ok)
	assert_true(_bridge.request_contract_accept(other, theirs).result.ok, "Outro jogador aceita o dele.")
	assert_true(_economy.request_accept_contract(npcs, npc_id).ok, "Um NPC aceita o dele.")
	_go(_center_b)
	assert_true(_accept(mine).result.ok, "Aceitar não confere os bens: o jogador aceita sem ter o pão.")
	_refused_deliver(_actor_id, mine, EconomyCodes.INSUFFICIENT_GOODS, KEY_NO_GOODS)
	_go(_center_a)
	_buy_bread()
	_go(_center_b)
	_host.runner.run_steps(TRAVEL_MINUTES)
	_refused_deliver(_actor_id, theirs, BridgePlayerContracts.CODE_NOT_YOURS, KEY_NOT_YOURS)
	_refused_deliver(_actor_id, npcs, BridgePlayerContracts.CODE_NOT_YOURS, KEY_NOT_YOURS)
	_refused_deliver(other, mine, BridgePlayerContracts.CODE_NOT_YOURS, KEY_NOT_YOURS)
	var funds_before: int = _funds()
	assert_true(_deliver(mine).result.ok, "As recusas não estragaram o contrato do jogador: ele entrega com os pães.")
	assert_eq([_funds(), _carried(), _economy.peek_contract(mine).state], [funds_before + REWARD, 0, ContractBook.STATE_COMPLETED])
	assert_eq([_economy.peek_contract(theirs).acceptor_id, _economy.peek_contract(npcs).acceptor_id], [other, npc_id], "Os contratos dos outros seguem com os aceitantes deles.")
	_assert_books_closed("depois do ciclo com as recusas")


func _abandon(contract_id: int) -> BridgePlayerContractsReplies.ContractActionReply:
	return _bridge.request_contract_abandon(_actor_id, contract_id)


## O que o abandono não pode mexer na compra: o saldo, os pães e o peso do jogador, e o caixa e o estoque de pães do mercado A (que recebeu o dinheiro e perdeu os pães).
func _purchase() -> Array:
	return [_funds(), _carried(), _economy.peek_inventory(_actor_id).weight, _cash(_market_a), _economy.peek_stock(_market_a, BREAD).value]


## O aceite de `contract_id` é recusado pelo limite (`BRIDGE_CONTRACT_LIMIT`, a chave do limite, recompensa 0) e a economia NÃO é chamada: o contrato segue `open` e sem aceitante, e nem o `state_hash` nem a fila de eventos mudam.
func _refused_by_limit(contract_id: int, which: String) -> void:
	var before: Array = _snapshot()
	var reply: BridgePlayerContractsReplies.ContractActionReply = _accept(contract_id)
	assert_eq([reply.result.code, reply.text_key, reply.reward, reply.contract_id], [CODE_LIMIT, KEY_LIMIT, 0, contract_id], "%s é recusada pelo limite." % which)
	var contract: EconomyReplies.ContractQuery = _economy.peek_contract(contract_id)
	assert_eq([_snapshot(), contract.state, contract.acceptor_id], [before, ContractBook.STATE_OPEN, IdGenerator.NO_ID], "A recusa não chamou a economia: o contrato segue aberto e sem aceitante, e o mundo não mudou.")


## Os campos do contrato como o SAVE da economia o grava, em ordem alfabética.
func _saved_keys(contract_id: int) -> Array:
	var keys: Array = (_economy.serialize()["contracts"]["contracts"][str(contract_id)] as Dictionary).keys()
	keys.sort()
	return keys


## O roteiro SEM abandono, no mundo de agora: o ciclo inteiro até a entrega (`completed`) e um segundo contrato aceito e deixado vencer até a hora cheia depois do prazo (`expired`). Devolve os dois contratos.
func _play_without_abandon() -> Array[int]:
	var done: int = _start_cycle(LONG_MINUTES)
	assert_true(_deliver(done).result.ok)
	var gone: int = _post(SHORT_MINUTES)
	assert_true(_accept(gone).result.ok)
	_host.runner.run_steps(_economy.peek_contract(gone).deadline + MINUTES_PER_HOUR - _now())
	assert_eq([_economy.peek_contract(done).state, _economy.peek_contract(gone).state], [ContractBook.STATE_COMPLETED, ContractBook.STATE_EXPIRED], "O roteiro termina com um contrato `completed` e outro `expired`.")
	return [done, gone]


## Troca o mundo por um novo da mesma semente: a montagem do `before_each` e a liberação do `after_each`, sem copiar.
func _replace_world() -> void:
	after_each()
	before_each()


## Salva o mundo pelo codec do jogo e o carrega num host novo, com os mesmos módulos e dados (o caminho da 107g); quem chama o libera.
func _reloaded() -> SimulationHostNode:
	var decoded: DecodedSave = _codec.decode(_codec.encode(_host.runner.capture_game(), GAME_VERSION))
	assert_true(decoded.result.ok, decoded.result.message)
	var loaded: SimulationHostNode = SimulationHostNode.new()
	loaded.runner = SimulationRunner.new(SEED)
	var modules: GameModules = GameModules.register(loaded.runner, _terrain, [], null, _setup)
	assert_true(modules.result.ok, modules.result.message)
	loaded.character = modules.character
	loaded.economy = modules.economy
	var result: Result = loaded.runner.load_game(decoded.payload)
	assert_true(result.ok, result.message)
	return loaded


## O limite de entregas aceitas por vez que o jogo REAL traz do dado: o jogo montado como o `GameApp` o monta (`start_default_game`, com NPCs e os dados de `res://data`), à parte, só para ler o limite.
func _real_game_limit() -> int:
	var app: GameAppNode = GameAppNode.new()
	var game: SimulationHostNode = SimulationHostNode.new()
	app.bind_host(game)
	app.start_default_game(game)
	var limit: int = game.economy.peek_contract_limit(ContractBook.DELIVERY)
	app.free()
	game.runner.finish()
	game.free()
	return limit


func test_buying_accepting_and_abandoning_sends_the_custody_back_to_the_issuer_and_leaves_the_funds_and_the_goods_untouched() -> void:
	var cash_b: int = _cash(_market_b)
	var funds_start: int = _funds()
	var contract_id: int = _start_cycle(SHORT_MINUTES)
	var bought: Array = _purchase()
	var money: Array = _money()
	assert_true(int(bought[0]) < funds_start and bought[1] == QUANTITY, "Pré-condição: o jogador pagou a compra e leva os pães.")
	assert_eq([_cash(_market_b), _cash(contract_id)], [cash_b - REWARD, REWARD], "Pré-condição: a recompensa está na custódia, fora do caixa do emissor.")
	_assert_books_closed("antes do abandono")
	var abandoned: BridgePlayerContractsReplies.ContractActionReply = _abandon(contract_id)
	assert_true(abandoned.result.ok, abandoned.result.message)
	assert_eq([abandoned.reward, abandoned.text_key, abandoned.contract_id], [0, KEY_ABANDONED, contract_id], "Abandonar não paga recompensa.")
	assert_eq([_cash(contract_id), _cash(_market_b)], [0, cash_b], "A custódia voltou inteira ao emissor.")
	assert_eq([_moved(Ledger.REASON_CONTRACT_REFUND), _moved(Ledger.REASON_CONTRACT_PAYOUT)], [REWARD, 0], "No livro-razão: devolveu e não pagou.")
	assert_eq(_purchase(), bought, "O saldo e os bens do jogador estão intactos: o abandono não cobra, não devolve a compra e não paga recompensa.")
	assert_eq(_money(), money, "Abandonar só devolve dinheiro: nada criado nem destruído (nem multa).")
	var contract: EconomyReplies.ContractQuery = _economy.peek_contract(contract_id)
	assert_eq([contract.state, contract.closed_reason, contract.acceptor_id], [ContractBook.STATE_FAILED, ABANDONED, _actor_id], "O contrato fica `failed` com o `closed_reason` `abandoned`, e o aceitante fica nele.")
	assert_eq(_board_states(_market_b), [ContractBook.STATE_FAILED] as Array[String], "O quadro mostra o contrato como falho.")
	_assert_books_closed("depois do abandono")
	_host.runner.world.context.events.dispatch()
	assert_eq([_failed.size(), _completed.size()], [1, 0], "Sai UM `ContractFailed` e nenhum `ContractCompleted`.")
	assert_eq([_failed[0].contract_id, _failed[0].issuer_id, _failed[0].reason], [contract_id, _market_b, ABANDONED], "O motivo do `ContractFailed` é `abandoned`.")
	_host.runner.run_steps(SHORT_MINUTES + MINUTES_PER_HOUR - _now())
	assert_eq([_economy.peek_contract(contract_id).state, _economy.peek_contract(contract_id).closed_reason, _failed.size()], [ContractBook.STATE_FAILED, ABANDONED, 1], "Passado o prazo o abandonado não vence: segue `failed`, sem segundo `ContractFailed`.")
	assert_eq([_funds(), _carried(), _cash(_market_b), _cash(contract_id)], [bought[0], bought[1], cash_b, 0], "E depois do prazo nada se moveu: o saldo, os pães e a custódia seguem como no abandono.")


func test_the_fourth_accept_is_refused_by_the_limit_and_abandoning_one_frees_exactly_one_slot() -> void:
	var ids: Array[int] = []
	for _i: int in LIMIT + 2:
		ids.append(_post(LONG_MINUTES))
	var theirs: int = _post(LONG_MINUTES)
	var npc_id: int = _host.runner.world.context.ids.next_id()
	assert_true(_economy.request_open_owner(npc_id, "npc").ok)
	assert_true(_economy.request_accept_contract(theirs, npc_id).ok, "Um NPC aceita o dele: a vaga dele não é a do jogador.")
	_go(_center_b)
	assert_eq([_real_game_limit(), _bridge.peek_contract_board(_actor_id, _market_b).accepted_limit], [LIMIT, LIMIT], "O jogo real (como o `GameApp` o monta) e o quadro da ponte trazem o limite do dado: 3 entregas aceitas por vez.")
	for index: int in LIMIT:
		assert_true(_accept(ids[index]).result.ok, "O aceite %d cabe no limite." % (index + 1))
	_refused_by_limit(ids[LIMIT], "A 4ª aceitação")
	var abandoned: BridgePlayerContractsReplies.ContractActionReply = _abandon(ids[0])
	assert_true(abandoned.result.ok, abandoned.result.message)
	assert_true(_accept(ids[LIMIT]).result.ok, "Abandonar um liberou uma vaga: o aceite que foi recusado agora funciona.")
	assert_eq(_economy.peek_contract(ids[LIMIT]).acceptor_id, _actor_id)
	_refused_by_limit(ids[LIMIT + 1], "Só uma vaga se liberou: a próxima aceitação")
	_assert_books_closed("depois do limite")


func test_saving_and_loading_with_an_abandoned_contract_keeps_the_reason_and_the_hash_and_worlds_without_abandon_are_saved_as_before() -> void:
	var played: Array[int] = _play_without_abandon()
	var hash_without: String = _host.runner.world.state_hash()
	assert_eq([_saved_keys(played[0]), _saved_keys(played[1])], [SAVED_KEYS, SAVED_KEYS], "Sem abandono o `completed` e o `expired` são salvos como antes da 107f: os mesmos campos, sem o `closed_reason`.")
	_replace_world()
	assert_eq([_play_without_abandon(), _host.runner.world.state_hash()], [played, hash_without], "Dois mundos da mesma semente com o mesmo roteiro SEM abandono dão o mesmo `state_hash`.")
	var kept: int = _post(LONG_MINUTES)
	assert_true(_accept(kept).result.ok)
	assert_true(_abandon(kept).result.ok)
	_host.runner.world.context.events.dispatch()
	var with_reason: Array = SAVED_KEYS + [REASON_KEY]
	with_reason.sort()
	assert_eq(_saved_keys(kept), with_reason, "O abandonado é salvo com os mesmos campos e só mais o `closed_reason`.")
	assert_true(_host.runner.can_capture_game(), "Entre passos a fila de eventos está vazia.")
	var hash_saved: String = _host.runner.world.state_hash()
	var funds: int = _funds()
	var loaded: SimulationHostNode = _reloaded()
	assert_eq(loaded.runner.world.state_hash(), hash_saved, "O mundo carregado tem o `state_hash` do momento do salvamento.")
	var economy: EconomyModule = loaded.economy
	assert_eq(_fields(economy, kept), [ContractBook.DELIVERY, ContractBook.STATE_FAILED, _market_b, _actor_id, REWARD, _economy.peek_contract(kept).deadline, BREAD, QUANTITY, _market_b], "O abandonado volta `failed`, com o aceitante e o resto iguais.")
	assert_eq([economy.peek_contract(played[0]).closed_reason, economy.peek_contract(played[1]).closed_reason, economy.peek_contract(kept).closed_reason], ["", "", ABANDONED], "Só o abandonado volta com o `closed_reason`.")
	assert_eq([economy.peek_balance(kept).balance, economy.peek_balance(_actor_id).balance, economy.peek_conservation().ok, economy.peek_goods_conservation().ok, economy.validate()], [0, funds, true, true, [] as Array[String]], "A custódia devolvida, o saldo, as conservações e o `validate()` fecham no mundo carregado.")
	loaded.runner.finish()
	loaded.free()
