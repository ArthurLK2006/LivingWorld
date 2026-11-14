extends GutTest
## LW-107b1: o QUADRO de contratos do JOGADOR na ponte (`SimBridge.peek_contract_board`; contrato em docs/modules/bridge.md, "Quadro de contratos do jogador", itens (i) a (v)), no jogo real de `res://data` (`data/economy`, `data/world`: três mercados).
## Os contratos são postados DIRETO na economia pelo teste (o jogador não posta; o postador é da LW-107c2) e o relógio anda pelo `runner` do jogo. C1: o quadro. C8 (a parte da consulta): ela não muda nada e não publica evento. Aceitar e entregar (C2, C3 e o resto do C8) são da LW-107b2.

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


## Um jogo só com o personagem e a economia (sem NPCs), com o jogador já nascido, com a conta aberta e junto ao centro do mercado A. 
func before_each() -> void:
	_host = SimulationHostNode.new()
	_host.start_new_game(SEED, _terrain, [], null, 0, _setup)
	_bridge = SimBridge.new(_host, _terrain, _places)
	_economy = _host.economy
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


func test_without_a_game_a_character_or_the_economy_the_board_fails_with_a_code() -> void:
	var idle_host: SimulationHostNode = SimulationHostNode.new()
	_assert_board_failure_code(SimBridge.new(idle_host, null, _places), SimBridge.CODE_NO_GAME)
	idle_host.free()
	_assert_board_failure_code(SimBridge.new(null, null, _places), SimBridge.CODE_NO_GAME)
	var character: CharacterModule = _host.character
	_host.character = null
	_assert_board_failure_code(_bridge, SimBridge.CODE_NO_CHARACTER)
	_host.character = character
	_host.economy = null
	_assert_board_failure_code(_bridge, SimBridge.CODE_NO_ECONOMY)
	_host.economy = _economy
	assert_true(_board(_market_a).result.ok, "Com os módulos de volta, a consulta funciona.")


func _assert_board_failure_code(bridge: SimBridge, code: String) -> void:
	assert_eq(bridge.peek_contract_board(_actor_id, 1).result.code, code, "A consulta sem jogo, sem personagem ou sem economia.")


func test_the_constants_and_the_economys_names_are_the_contracts() -> void:
	assert_eq(BridgePlayerContracts.FINISHED_LIMIT, 5)
	assert_eq([BridgePlayerContracts.KIND_DELIVERY, BridgePlayerContracts.STATE_OPEN, BridgePlayerContracts.STATE_ACCEPTED, BridgePlayerContracts.STATE_COMPLETED, BridgePlayerContracts.STATE_EXPIRED], [ContractBook.DELIVERY, ContractBook.STATE_OPEN, ContractBook.STATE_ACCEPTED, ContractBook.STATE_COMPLETED, ContractBook.STATE_EXPIRED], "O texto do tipo e dos estados é o da economia.")
