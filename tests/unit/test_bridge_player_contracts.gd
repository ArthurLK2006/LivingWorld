extends GutTest
## LW-107b: o quadro de contratos do JOGADOR na ponte (`SimBridge.peek_contract_board`, `request_contract_accept` e `request_contract_deliver`; contrato em docs/modules/bridge.md, "Quadro de contratos do jogador", itens (i) a (v)), sem janela, com a economia, o terreno e os locais REAIS
## (`data/economy`, `data/world`: três mercados). Os contratos são postados DIRETO na economia pelo teste (o jogador não posta; o postador é da LW-107c2) e o relógio anda pelo `runner` do jogo. C1: o quadro. C2: aceitar, na ordem do contrato, inclusive o prazo (contrato vencido é recusado pela PONTE com
## `BRIDGE_CONTRACT_EXPIRED`, a fronteira em `deadline - 1` e `deadline`). C3: entregar. C8 (a parte da ponte): só `accept` e `deliver` mudam o `state_hash`; a consulta e as recusas não mudam nada e não publicam evento. As chaves são só chaves: o texto delas é da LW-107e2.

const WORLD_DIR: String = "res://data/world"
const SEED: int = 107
const SETTLEMENT_A: String = "test_settlement_a"
const SETTLEMENT_B: String = "test_settlement_b"
const SETTLEMENT_C: String = "test_settlement_c"
const BREAD: String = "bread"
const WORK_PLACE: String = "a_work_01"
const UNKNOWN_ID: int = 999999
const MINUTES_PER_HOUR: int = 60
## Os números dos contratos do teste (os do jogo são [HIP]): recompensa e quantidade; o prazo longo (minutos depois de agora) só os testes do prazo encurtam.
const REWARD: int = 12
const QUANTITY: int = 2
const LONG_MINUTES: int = 600
const SHORT_MINUTES: int = 90
## Distância (m) do centro do mercado, além do alcance [HIP] de 3 m do `world`.
const FAR_M: float = 3.5
## "O jogador" como ator dos pedidos recusados que aceitam outro ator.
const PLAYER: int = -1
const KEY_ACCEPTED: String = "economy.contract.accepted"
const KEY_NOT_OPEN: String = "economy.contract.not_open"
const KEY_IMPOSSIBLE: String = "economy.contract.impossible"
const KEY_TOO_FAR: String = "economy.contract.too_far"
const KEY_NOT_YOURS: String = "economy.contract.not_yours"
const KEY_EXPIRED: String = "economy.contract.expired"
const KEY_FAILED: String = "economy.contract.failed"
## A tabela do contrato (item (iii) e, na LW-107f3, o item (iv) de "Encomendas por objetivo"): o código que a ponte recusa e a chave que devolve; com as 3 de sucesso (aceite, entrega e abandono) e a genérica são as 13 chaves (mudança de contrato aprovada por Arthur no D4).
const EXPECTED_FAILURE_KEYS: Dictionary[String, String] = {
	"ECON_CONTRACT_NOT_OPEN": KEY_NOT_OPEN,
	"ECON_UNKNOWN_CONTRACT": "economy.contract.unknown",
	"ECON_CONTRACT_IMPOSSIBLE": KEY_IMPOSSIBLE,
	"ECON_INSUFFICIENT_GOODS": "economy.contract.no_goods",
	"ECON_CAPACITY_EXCEEDED": "economy.contract.destination_full",
	"PLACE_TOO_FAR": KEY_TOO_FAR,
	"BRIDGE_CONTRACT_NOT_YOURS": KEY_NOT_YOURS,
	"BRIDGE_CONTRACT_EXPIRED": KEY_EXPIRED,
	"BRIDGE_CONTRACT_LIMIT": "economy.contract.limit",
}

var _terrain: TerrainData
var _places: Array[Place] = []
var _setup: EconomySetup
var _center_a: Vector3
var _center_b: Vector3
var _center_c: Vector3
var _host: SimulationHostNode
var _bridge: SimBridge
var _economy: EconomyModule
var _actor_id: int = 0
var _market_a: int = 0
var _market_b: int = 0
var _market_c: int = 0
var _completed: Array[ContractCompleted] = []


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
	_center_c = centers[SETTLEMENT_C]
	_setup = EconomySetup.from_dir(EconomySetup.DEFAULT_DIR)
	assert_true(_setup.result.ok, _setup.result.message)


## Um jogo só com o personagem e a economia (sem NPCs), com o jogador já nascido, com a conta aberta e junto ao centro do mercado A. Os contratos concluídos ficam em `_completed`.
func before_each() -> void:
	_host = SimulationHostNode.new()
	_host.start_new_game(SEED, _terrain, [], null, 0, _setup)
	_bridge = SimBridge.new(_host, _terrain, _places)
	_economy = _host.economy
	_completed = []
	_host.runner.world.context.events.subscribe("ContractCompleted", func(event: SimEvent) -> void: _completed.append(event))
	_actor_id = _bridge.request_spawn_character().actor_id
	assert_true(_bridge.request_open_player_account(_actor_id).ok)
	_market_a = _economy.peek_market_of(SETTLEMENT_A).market_id
	_market_b = _economy.peek_market_of(SETTLEMENT_B).market_id
	_market_c = _economy.peek_market_of(SETTLEMENT_C).market_id
	_go(_center_a)


func after_each() -> void:
	_host.runner.finish()
	_host.free()


func _go(spot: Vector3) -> void:
	var reported: Result = _bridge.request_report_position(_actor_id, spot, 0.0)
	assert_true(reported.ok, reported.message)


func _far_from(center: Vector3) -> Vector3:
	return center + Vector3(FAR_M, 0.0, 0.0)


func _now() -> int:
	return _bridge.peek_time().total_minutes


func _board(market_id: int) -> BridgePlayerContractsReplies.ContractBoardReply:
	return _bridge.peek_contract_board(_actor_id, market_id)


func _accept(contract_id: int) -> BridgePlayerContractsReplies.ContractActionReply:
	return _bridge.request_contract_accept(_actor_id, contract_id)


func _deliver(contract_id: int) -> BridgePlayerContractsReplies.ContractActionReply:
	return _bridge.request_contract_deliver(_actor_id, contract_id)


## Posta um contrato de entrega direto na economia: `issuer` paga a recompensa para a custódia, o prazo é `minutes` depois de agora e o destino é `destination`.
func _post(issuer: int, destination: int, minutes: int = LONG_MINUTES) -> int:
	var posted: EconomyReplies.PostContractResult = _economy.request_post_contract(ContractBook.DELIVERY, issuer, REWARD, _now() + minutes, {"good_id": BREAD, "quantity": QUANTITY, "destination_id": destination})
	assert_true(posted.result.ok, posted.result.message)
	return posted.contract_id


func _post_labor() -> int:
	var posted: EconomyReplies.PostContractResult = _economy.request_post_contract(ContractBook.LABOR, _market_a, REWARD, _now() + LONG_MINUTES, {"place_id": WORK_PLACE, "minutes": 30})
	assert_true(posted.result.ok, posted.result.message)
	return posted.contract_id


## Um segundo personagem, junto do mercado A, com a conta aberta (ou sem ela: `with_account` falso).
func _new_character(with_account: bool = true) -> int:
	var actor_id: int = _bridge.request_spawn_character().actor_id
	assert_true(_bridge.request_report_position(actor_id, _center_a, 0.0).ok)
	if with_account:
		assert_true(_bridge.request_open_player_account(actor_id).ok)
	return actor_id


## Um dono do tipo `npc` na economia que NÃO é personagem do `character` (o "NPC" como ator, ou emissor e destino que não são mercado).
func _new_npc() -> int:
	var npc_id: int = _host.runner.world.context.ids.next_id()
	assert_true(_economy.request_open_owner(npc_id, "npc").ok)
	return npc_id


func _ids(board: BridgePlayerContractsReplies.ContractBoardReply) -> Array[int]:
	var ids: Array[int] = []
	for row: BridgePlayerContractsReplies.ContractBoardRow in board.rows:
		ids.append(row.contract_id)
	return ids


func _ids_of_kind(kind: String) -> Array[int]:
	var ids: Array[int] = []
	for contract: EconomyReplies.ContractQuery in _economy.peek_contracts().contracts:
		if contract.kind == kind:
			ids.append(contract.contract_id)
	return ids


## O que NENHUMA consulta nem recusa pode mudar: o `state_hash` do mundo (C8) e a fila de eventos (os eventos pendentes ainda não entregues).
func _snapshot() -> Array:
	return [_host.runner.world.state_hash(), int(_host.runner.world.context.events.debug_summary()["pending"])]


## O pedido (do jogador ou, em `actor_id`, de outro ator) é recusado com `code`, a chave `key` e a recompensa 0, e NADA muda: nem o `state_hash`, nem a fila de eventos.
func _refused_accept(contract_id: int, code: String, key: String, actor_id: int = PLAYER) -> void:
	var before: Array = _snapshot()
	var reply: BridgePlayerContractsReplies.ContractActionReply = _bridge.request_contract_accept(_actor_id if actor_id == PLAYER else actor_id, contract_id)
	_assert_refusal(reply, contract_id, code, key, before)


func _refused_deliver(contract_id: int, code: String, key: String, actor_id: int = PLAYER) -> void:
	var before: Array = _snapshot()
	var reply: BridgePlayerContractsReplies.ContractActionReply = _bridge.request_contract_deliver(_actor_id if actor_id == PLAYER else actor_id, contract_id)
	_assert_refusal(reply, contract_id, code, key, before)


## `before` é o `_snapshot()` tirado ANTES do pedido.
func _assert_refusal(reply: BridgePlayerContractsReplies.ContractActionReply, contract_id: int, code: String, key: String, before: Array) -> void:
	assert_eq([reply.result.code, reply.text_key, reply.reward, reply.contract_id], [code, key, 0, contract_id], "A recusa do contrato %d." % contract_id)
	assert_eq(_snapshot(), before, "A recusa do contrato %d não mudou nada (nem o `state_hash`, nem evento)." % contract_id)


func _assert_row_matches_the_economy(row: BridgePlayerContractsReplies.ContractBoardRow) -> void:
	var contract: EconomyReplies.ContractQuery = _economy.peek_contract(row.contract_id)
	var from_row: Array = [row.kind, row.state, row.is_mine, row.issuer_id, row.reward, row.deadline, row.good_id, row.quantity, row.destination_id, row.place_id, row.minutes, row.worked_minutes]
	var from_economy: Array = [contract.kind, contract.state, contract.acceptor_id == _actor_id, contract.issuer_id, contract.reward, contract.deadline, contract.good_id, contract.quantity, contract.destination_id, contract.place_id, contract.minutes, contract.worked_minutes]
	assert_eq(from_row, from_economy, "A linha do contrato %d tem os campos da economia." % row.contract_id)


func test_the_board_lists_the_open_deliveries_of_the_market_in_ascending_order_with_the_economys_fields() -> void:
	_host.runner.run_steps(5)
	var first: int = _post(_market_a, _market_b)
	var second: int = _post(_market_c, _market_a)
	var third: int = _post(_market_c, _market_c)
	assert_eq(_economy.peek_contract(_post_labor()).kind, ContractBook.LABOR, "Pré-condição: o `labor` fica no livro de contratos e FORA do quadro.")
	var before: Array = _snapshot()
	var at_a: BridgePlayerContractsReplies.ContractBoardReply = _board(_market_a)
	assert_true(at_a.result.ok, at_a.result.message)
	assert_eq([at_a.market_id, at_a.settlement_id, at_a.now], [_market_a, SETTLEMENT_A, _now()], "O `now` é o `total_minutes` do relógio de `peek_time()`.")
	assert_eq(_now(), 5)
	assert_eq(_ids(at_a), [first, second] as Array[int], "No mercado A: o que ele emite e o que ele espera como destino, em ordem crescente de contrato.")
	for row: BridgePlayerContractsReplies.ContractBoardRow in at_a.rows:
		_assert_row_matches_the_economy(row)
		assert_eq([row.kind, row.state, row.is_mine, row.good_id, row.quantity, row.reward], [ContractBook.DELIVERY, ContractBook.STATE_OPEN, false, BREAD, QUANTITY, REWARD])
	assert_eq([_ids(_board(_market_b)), _ids(_board(_market_c))], [[first] as Array[int], [second, third] as Array[int]], "B só espera o primeiro; C emite o segundo e o terceiro.")
	assert_eq(_snapshot(), before, "A consulta só lê: nada mudou (C8).")
	at_a.rows[0].reward = -1
	assert_eq(_economy.peek_contract(first).reward, REWARD, "A linha é cópia: mexer nela não mexe na economia.")


func test_an_empty_board_is_a_success_even_with_vacancies_and_the_board_needs_no_reach() -> void:
	_host.runner.run_steps(MINUTES_PER_HOUR)
	assert_false(_ids_of_kind(ContractBook.VACANCY).is_empty(), "Pré-condição: na hora cheia a economia posta as vagas, e elas ficam fora do quadro.")
	_go(_far_from(_center_a))
	var board: BridgePlayerContractsReplies.ContractBoardReply = _board(_market_a)
	assert_true(board.result.ok, board.result.message)
	assert_eq([board.rows.size(), board.now], [0, MINUTES_PER_HOUR], "Sem contrato de entrega o quadro é sucesso e vazio, mesmo a 3,5 m do mercado.")
	var contract_id: int = _post(_market_a, _market_b)
	assert_eq(_ids(_board(_market_a)), [contract_id] as Array[int], "A consulta não exige alcance do mercado.")


func test_the_board_shows_what_the_actor_carries_in_any_market_and_only_the_five_most_recent_finished_ones() -> void:
	var other: int = _new_character()
	var carried: int = _post(_market_c, _market_c)
	var theirs: int = _post(_market_c, _market_c)
	assert_true(_economy.request_accept_contract(carried, _actor_id).ok)
	assert_true(_economy.request_accept_contract(theirs, other).ok)
	var at_a: BridgePlayerContractsReplies.ContractBoardReply = _board(_market_a)
	assert_eq(_ids(at_a), [carried] as Array[int], "O que o ator carrega aparece em qualquer mercado; o que é de outro ator, não.")
	assert_true(at_a.rows[0].is_mine and at_a.rows[0].state == ContractBook.STATE_ACCEPTED)
	var posted: Array[int] = []
	for index: int in BridgePlayerContracts.FINISHED_LIMIT + 2:
		posted.append(_post(_market_a, _market_b, SHORT_MINUTES))
		assert_true(_economy.request_accept_contract(posted[index], _actor_id).ok)
	assert_true(_economy.request_transfer_goods(_market_a, _actor_id, BREAD, QUANTITY).ok)
	assert_true(_economy.request_deliver_contract(posted[5]).ok, "Pré-condição: um dos contratos termina `completed`; os outros vencem.")
	var unaccepted: int = _post(_market_a, _market_b, SHORT_MINUTES)
	assert_true(_economy.request_accept_contract(_post(_market_a, _market_b, SHORT_MINUTES), other).ok)
	_host.runner.run_steps(2 * MINUTES_PER_HOUR)
	assert_eq(_economy.peek_contract(unaccepted).state, ContractBook.STATE_EXPIRED, "Pré-condição: na hora cheia depois do prazo a economia venceu os que sobraram.")
	var expected: Array[int] = [carried]
	expected.append_array(posted.slice(2))
	var board: BridgePlayerContractsReplies.ContractBoardReply = _board(_market_a)
	assert_eq(_ids(board), expected, "Só os 5 terminados mais recentes do ator (maiores IDs): os 2 mais velhos saem, o de outro ator e o sem aceitante nunca entram; o que ele carrega continua.")
	var states: Array[String] = []
	for row: BridgePlayerContractsReplies.ContractBoardRow in board.rows:
		states.append(row.state)
		_assert_row_matches_the_economy(row)
	assert_eq(states, [ContractBook.STATE_ACCEPTED, ContractBook.STATE_EXPIRED, ContractBook.STATE_EXPIRED, ContractBook.STATE_EXPIRED, ContractBook.STATE_COMPLETED, ContractBook.STATE_EXPIRED] as Array[String], "`completed` e `expired` contam, na ordem dos IDs.")


func test_the_board_refusals_come_with_the_codes_and_change_nothing() -> void:
	_post(_market_a, _market_b)
	var npc: int = _new_npc()
	var before: Array = _snapshot()
	for stranger: int in [npc, _market_a, UNKNOWN_ID]:
		assert_eq(_bridge.peek_contract_board(stranger, _market_a).result.code, CharacterModule.CODE_UNKNOWN_ACTOR, "O ator %d (NPC, mercado ou ID solto) não é um personagem." % stranger)
	for not_a_market: int in [UNKNOWN_ID, npc, _actor_id]:
		assert_eq(_board(not_a_market).result.code, EconomyCodes.UNKNOWN_MARKET, "O dono %d não é um mercado." % not_a_market)
	assert_eq(_snapshot(), before, "As recusas só leem: nada mudou.")


func test_accepting_at_the_market_marks_the_contract_accepted_for_the_actor_and_only_that_changes_the_hash() -> void:
	var contract_id: int = _post(_market_a, _market_b)
	var before: Array = _snapshot()
	var accepted: BridgePlayerContractsReplies.ContractActionReply = _accept(contract_id)
	assert_true(accepted.result.ok, accepted.result.message)
	assert_eq([accepted.contract_id, accepted.reward, accepted.text_key], [contract_id, REWARD, KEY_ACCEPTED], "No sucesso: a recompensa que será paga e a chave de aceite.")
	var contract: EconomyReplies.ContractQuery = _economy.peek_contract(contract_id)
	assert_eq([contract.state, contract.acceptor_id], [ContractBook.STATE_ACCEPTED, _actor_id])
	var after: Array = _snapshot()
	assert_ne(after[0], before[0], "Aceitar muda o `state_hash` (C8)...")
	assert_eq(after[1], before[1], "...e não publica evento.")
	var row: BridgePlayerContractsReplies.ContractBoardRow = _board(_market_a).rows[0]
	assert_true(row.is_mine and row.state == ContractBook.STATE_ACCEPTED, "O quadro mostra o contrato como do jogador.")
	_refused_accept(contract_id, EconomyCodes.CONTRACT_NOT_OPEN, KEY_NOT_OPEN)


func test_accept_checks_the_actor_the_contract_the_type_and_the_reach_in_the_order_of_the_contract() -> void:
	var delivery: int = _post(_market_a, _market_b)
	var labor: int = _post_labor()
	var no_market: int = _post(_new_npc(), _new_npc())
	_host.runner.run_steps(MINUTES_PER_HOUR)
	var vacancy: int = _ids_of_kind(ContractBook.VACANCY)[0]
	for stranger: int in [_new_npc(), _market_a, UNKNOWN_ID]:
		_refused_accept(delivery, CharacterModule.CODE_UNKNOWN_ACTOR, KEY_FAILED, stranger)
	_refused_accept(UNKNOWN_ID, EconomyCodes.UNKNOWN_CONTRACT, "economy.contract.unknown")
	_refused_accept(labor, EconomyCodes.CONTRACT_IMPOSSIBLE, KEY_IMPOSSIBLE)
	_refused_accept(vacancy, EconomyCodes.CONTRACT_IMPOSSIBLE, KEY_IMPOSSIBLE)
	_refused_accept(no_market, EconomyCodes.CONTRACT_IMPOSSIBLE, KEY_IMPOSSIBLE)
	_go(_far_from(_center_a))
	_refused_accept(labor, EconomyCodes.CONTRACT_IMPOSSIBLE, KEY_IMPOSSIBLE)
	_refused_accept(delivery, MarketReach.CODE_PLACE_TOO_FAR, KEY_TOO_FAR)
	_go(_center_c)
	_refused_accept(delivery, MarketReach.CODE_PLACE_TOO_FAR, KEY_TOO_FAR)
	_refused_accept(delivery, EconomyCodes.UNKNOWN_OWNER, KEY_FAILED, _new_character(false))
	_go(_center_b)
	assert_true(_accept(delivery).result.ok, "O mercado destino também serve: basta estar ao alcance de um dos dois.")
	_go(_far_from(_center_b))
	_refused_accept(delivery, MarketReach.CODE_PLACE_TOO_FAR, KEY_TOO_FAR)
	assert_eq([_economy.peek_contract(labor).state, _economy.peek_contract(vacancy).state], [ContractBook.STATE_OPEN, ContractBook.STATE_OPEN], "O `labor` e a vaga seguem abertos.")


func test_a_contract_past_its_deadline_is_refused_by_the_bridge_at_the_boundary_and_after_the_full_hour() -> void:
	var first: int = _post(_market_a, _market_b, SHORT_MINUTES)
	var second: int = _post(_market_a, _market_b, SHORT_MINUTES)
	assert_true(_bridge.request_trade(_actor_id, _market_a, BREAD, QUANTITY, BridgePlayerEconomyReplies.SIDE_BUY).result.ok, "O jogador leva o pão do contrato.")
	_host.runner.run_steps(SHORT_MINUTES - 1)
	assert_eq(_now(), _economy.peek_contract(second).deadline - 1)
	assert_true(_accept(first).result.ok, "Com `now` igual a `deadline - 1` o aceite é feito.")
	_host.runner.run_steps(1)
	assert_eq(_now(), _economy.peek_contract(second).deadline, "O relógio chega ao prazo, antes da hora cheia que o venceria.")
	_refused_accept(second, BridgePlayerContracts.CODE_EXPIRED, KEY_EXPIRED)
	assert_eq([_economy.peek_contract(second).state, _ids(_board(_market_a))], [ContractBook.STATE_OPEN, [first, second] as Array[int]], "O `open` vencido segue `open` e no quadro (a tela o mostra como vencido).")
	_go(_far_from(_center_a))
	_refused_accept(second, MarketReach.CODE_PLACE_TOO_FAR, KEY_TOO_FAR)
	_go(_center_a)
	_refused_accept(first, EconomyCodes.CONTRACT_NOT_OPEN, KEY_NOT_OPEN)
	_refused_deliver(first, MarketReach.CODE_PLACE_TOO_FAR, KEY_TOO_FAR)
	_go(_center_b)
	_refused_deliver(first, EconomyCodes.CONTRACT_IMPOSSIBLE, KEY_IMPOSSIBLE)
	_host.runner.run_steps(2 * MINUTES_PER_HOUR - SHORT_MINUTES)
	assert_eq([_economy.peek_contract(first).state, _economy.peek_contract(second).state], [ContractBook.STATE_EXPIRED, ContractBook.STATE_EXPIRED], "Pré-condição: na hora cheia a economia venceu os dois.")
	_refused_accept(second, BridgePlayerContracts.CODE_EXPIRED, KEY_EXPIRED)
	_refused_deliver(first, EconomyCodes.CONTRACT_NOT_OPEN, KEY_NOT_OPEN)


func test_delivering_pays_the_reward_moves_the_goods_and_publishes_one_event() -> void:
	var contract_id: int = _post(_market_a, _market_b)
	assert_true(_accept(contract_id).result.ok)
	_refused_deliver(contract_id, MarketReach.CODE_PLACE_TOO_FAR, KEY_TOO_FAR)
	_go(_center_b)
	_refused_deliver(contract_id, EconomyCodes.INSUFFICIENT_GOODS, "economy.contract.no_goods")
	_go(_center_a)
	assert_true(_bridge.request_trade(_actor_id, _market_a, BREAD, QUANTITY, BridgePlayerEconomyReplies.SIDE_BUY).result.ok)
	_go(_center_b)
	var funds: int = _bridge.peek_player_economy(_actor_id).funds
	var stock: int = _economy.peek_stock(_market_b, BREAD).value
	assert_eq(_economy.peek_balance(contract_id).balance, REWARD, "Pré-condição: a recompensa está na custódia.")
	_host.runner.world.context.events.dispatch()
	var before: Array = _snapshot()
	var delivered: BridgePlayerContractsReplies.ContractActionReply = _deliver(contract_id)
	assert_true(delivered.result.ok, delivered.result.message)
	assert_eq([delivered.contract_id, delivered.reward, delivered.text_key], [contract_id, REWARD, "economy.contract.delivered"])
	assert_eq([_bridge.peek_player_economy(_actor_id).funds, _economy.peek_balance(contract_id).balance], [funds + REWARD, 0], "O saldo do jogador sobe a recompensa e a custódia zera.")
	assert_eq([_economy.peek_stock(_market_b, BREAD).value, _economy.peek_inventory(_actor_id).rows], [stock + QUANTITY, [] as Array[Dictionary]], "O pão saiu do inventário do jogador e entrou no estoque do mercado destino.")
	assert_eq(_economy.peek_contract(contract_id).state, ContractBook.STATE_COMPLETED)
	assert_ne(_snapshot()[0], before[0], "Entregar muda o `state_hash` (C8).")
	_host.runner.world.context.events.dispatch()
	assert_eq(_completed.size(), 1, "Sai UM `ContractCompleted`.")
	assert_eq([_completed[0].contract_id, _completed[0].acceptor_id, _completed[0].reward], [contract_id, _actor_id, REWARD])
	assert_eq(_ids(_board(_market_b)), [contract_id] as Array[int], "O contrato concluído segue no quadro, como terminado do ator.")
	_refused_deliver(contract_id, EconomyCodes.CONTRACT_NOT_OPEN, KEY_NOT_OPEN)
	assert_true(_economy.peek_conservation().ok and _economy.peek_goods_conservation().ok and _economy.validate().is_empty(), "O dinheiro e os bens continuam contados.")


func test_deliver_refuses_what_is_not_the_actors_before_looking_at_the_reach_and_the_goods() -> void:
	var other: int = _new_character()
	var theirs: int = _post(_market_a, _market_b)
	assert_true(_economy.request_accept_contract(theirs, other).ok)
	var open: int = _post(_market_a, _market_b)
	var labor: int = _post_labor()
	var no_market: int = _post(_new_npc(), _new_npc())
	assert_true(_economy.request_accept_contract(no_market, _actor_id).ok)
	var npc: int = _new_npc()
	for not_mine: int in [theirs, open, labor]:
		_refused_deliver(not_mine, BridgePlayerContracts.CODE_NOT_YOURS, KEY_NOT_YOURS)
	_refused_deliver(UNKNOWN_ID, EconomyCodes.UNKNOWN_CONTRACT, "economy.contract.unknown")
	_go(_center_b)
	_refused_deliver(no_market, EconomyCodes.CONTRACT_IMPOSSIBLE, KEY_IMPOSSIBLE)
	for stranger: int in [npc, _market_b, UNKNOWN_ID]:
		_refused_deliver(theirs, CharacterModule.CODE_UNKNOWN_ACTOR, KEY_FAILED, stranger)


func test_without_a_game_a_character_or_the_economy_the_three_calls_fail_with_a_code() -> void:
	var idle_host: SimulationHostNode = SimulationHostNode.new()
	_assert_failure_code(SimBridge.new(idle_host, null, _places), SimBridge.CODE_NO_GAME)
	idle_host.free()
	_assert_failure_code(SimBridge.new(null, null, _places), SimBridge.CODE_NO_GAME)
	var character: CharacterModule = _host.character
	_host.character = null
	_assert_failure_code(_bridge, SimBridge.CODE_NO_CHARACTER)
	_host.character = character
	_host.economy = null
	_assert_failure_code(_bridge, SimBridge.CODE_NO_ECONOMY)
	_host.economy = _economy
	assert_true(_board(_market_a).result.ok, "Com os módulos de volta, a consulta funciona.")


func _assert_failure_code(bridge: SimBridge, code: String) -> void:
	var replies: Array[BridgePlayerContractsReplies.ContractActionReply] = [bridge.request_contract_accept(_actor_id, 1), bridge.request_contract_deliver(_actor_id, 1)]
	for reply: BridgePlayerContractsReplies.ContractActionReply in replies:
		assert_eq([reply.result.code, reply.text_key, reply.reward, reply.contract_id], [code, KEY_FAILED, 0, 1], "O pedido sem jogo, sem personagem ou sem economia.")
	assert_eq(bridge.peek_contract_board(_actor_id, 1).result.code, code, "A consulta, também.")


func test_the_codes_the_keys_and_the_economys_names_are_the_contracts() -> void:
	assert_eq([BridgePlayerContracts.CODE_NOT_YOURS, BridgePlayerContracts.CODE_EXPIRED, BridgePlayerContracts.CODE_LIMIT, BridgePlayerContracts.FINISHED_LIMIT], ["BRIDGE_CONTRACT_NOT_YOURS", "BRIDGE_CONTRACT_EXPIRED", "BRIDGE_CONTRACT_LIMIT", 5])
	assert_eq([BridgePlayerContracts.KIND_DELIVERY, BridgePlayerContracts.STATE_OPEN, BridgePlayerContracts.STATE_ACCEPTED, BridgePlayerContracts.STATE_COMPLETED, BridgePlayerContracts.STATE_EXPIRED, BridgePlayerContracts.STATE_FAILED], [ContractBook.DELIVERY, ContractBook.STATE_OPEN, ContractBook.STATE_ACCEPTED, ContractBook.STATE_COMPLETED, ContractBook.STATE_EXPIRED, ContractBook.STATE_FAILED], "O texto do tipo e dos estados é o da economia.")
	assert_eq(BridgePlayerContractsReplies.ContractActionReply.FAILURE_KEYS, EXPECTED_FAILURE_KEYS, "A tabela do item (iii): uma chave por código.")
	assert_eq(BridgePlayerContractsReplies.ContractActionReply.KEY_ABANDONED, "economy.contract.abandoned", "A chave de sucesso do abandono (LW-107f3).")
	var keys: Array[String] = [BridgePlayerContractsReplies.ContractActionReply.KEY_ACCEPTED, BridgePlayerContractsReplies.ContractActionReply.KEY_DELIVERED, BridgePlayerContractsReplies.ContractActionReply.KEY_ABANDONED, BridgePlayerContractsReplies.ContractActionReply.FALLBACK_KEY]
	keys.append_array(BridgePlayerContractsReplies.ContractActionReply.FAILURE_KEYS.values())
	assert_eq(keys.size(), 13, "São 13 chaves: 3 de sucesso, 9 de recusa e a genérica.")
	for key: String in keys:
		assert_true(key.begins_with("economy.contract."), "A chave %s tem o prefixo economy.contract." % key)
		assert_eq(keys.count(key), 1, "A chave %s é única." % key)
	var full: Result = Result.failure(EconomyCodes.CAPACITY_EXCEEDED, "destino cheio")
	assert_eq(BridgePlayerContractsReplies.ContractActionReply.new(full, 1).text_key, "economy.contract.destination_full", "O código do destino cheio tem a chave própria.")
	assert_eq(BridgePlayerContractsReplies.ContractActionReply.new(Result.failure("OTHER_CODE", "x"), 1).text_key, KEY_FAILED, "Código sem chave própria usa a genérica.")
