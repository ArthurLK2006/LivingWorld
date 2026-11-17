extends GutTest
## LW-107f3: a PONTE das encomendas por objetivo (docs/modules/bridge.md, "Encomendas por objetivo: abandonar e limite", itens (i) a (iii); economy.md, seção 8, itens (c), (d) e (g)): `request_contract_abandon`, o limite por categoria no `accept` (`BRIDGE_CONTRACT_LIMIT`) e o que o quadro ganha (`accepted_limit`, `closed_reason` e o `failed` entre os terminados).
## O jogo é o REAL, montado como o `GameApp` monta (`GameApp.start_default_game`: terreno, NPCs, locais e economia de `res://data`, só `--headless`) e o limite de 3 chega do `data/economy/contract_limits.json` pela fiação do jogo; só o caso "categoria sem linha no dado" monta o jogo à mão, com a tabela do limite vazia. Os contratos são postados DIRETO na economia (o jogador não posta e o postador está desligado) e o relógio
## anda pelo `runner`. O `before_each` leva o jogo à hora cheia, para o prazo curto (30 minutos) vencer SEM a economia o encerrar (ela só o faz na hora cheia seguinte). As chaves são só chaves: o texto delas é da LW-107f4c.

const WORLD_DIR: String = "res://data/world"
const SEED: int = 107
const SETTLEMENT_A: String = "test_settlement_a"
const SETTLEMENT_B: String = "test_settlement_b"
const BREAD: String = "bread"
const WORK_PLACE: String = "a_work_01"
const UNKNOWN_ID: int = 999999
const MINUTES_PER_HOUR: int = 60
## Os números dos contratos do teste (os do jogo são [HIP]) e o limite do dado real (`delivery_limit`: 3, provisório do primeiro recorte).
const REWARD: int = 12
const QUANTITY: int = 2
const LONG_MINUTES: int = 600
const SHORT_MINUTES: int = 30
const LIMIT: int = 3
## Distância (m) do centro do mercado, além do alcance [HIP] de 3 m do `world`.
const FAR_M: float = 3.5
## "O jogador" como ator dos pedidos recusados que aceitam outro ator.
const PLAYER: int = -1
const ABANDONED: String = "abandoned"
const KEY_ABANDONED: String = "economy.contract.abandoned"
const KEY_LIMIT: String = "economy.contract.limit"
const KEY_NOT_OPEN: String = "economy.contract.not_open"
const KEY_UNKNOWN: String = "economy.contract.unknown"
const KEY_IMPOSSIBLE: String = "economy.contract.impossible"
const KEY_NOT_YOURS: String = "economy.contract.not_yours"
const KEY_TOO_FAR: String = "economy.contract.too_far"
const KEY_EXPIRED: String = "economy.contract.expired"
const KEY_FAILED: String = "economy.contract.failed"

var _host: SimulationHostNode
var _app: GameAppNode
var _bridge: SimBridge
var _economy: EconomyModule
var _actor_id: int = 0
var _market_a: int = 0
var _market_b: int = 0
var _center_a: Vector3
var _failed: Array[ContractFailed] = []


func before_each() -> void:
	_host = SimulationHostNode.new()
	_app = GameAppNode.new()
	_app.bind_host(_host)
	_app.start_default_game(_host)
	_begin(_app.peek_bridge())


func after_each() -> void:
	_end()


## Põe em campo o jogo `_host` (já iniciado) e a ponte dele: o jogador nasce com a conta aberta junto ao centro do mercado A, o relógio na hora cheia e os `ContractFailed` ficam em `_failed`.
func _begin(bridge: SimBridge) -> void:
	_bridge = bridge
	_economy = _host.economy
	_failed = []
	_host.runner.world.context.events.subscribe("ContractFailed", func(event: SimEvent) -> void: _failed.append(event))
	_actor_id = _bridge.request_spawn_character().actor_id
	assert_true(_bridge.request_open_player_account(_actor_id).ok)
	_market_a = _economy.peek_market_of(SETTLEMENT_A).market_id
	_market_b = _economy.peek_market_of(SETTLEMENT_B).market_id
	_center_a = _center_of(SETTLEMENT_A)
	_host.runner.run_steps((MINUTES_PER_HOUR - _now() % MINUTES_PER_HOUR) % MINUTES_PER_HOUR)
	_go(_center_a)


func _end() -> void:
	if _app != null:
		_app.free()
		_app = null
	if _host.runner != null:
		_host.runner.finish()
	_host.free()


func _center_of(settlement_id: String) -> Vector3:
	for place: BridgeReplies.PlaceReply in _bridge.peek_places().places:
		if place.kind == Place.KIND_MARKET and place.settlement_id == settlement_id:
			return Vector3(place.x, place.y, place.z)
	assert_true(false, "O assentamento %s não tem mercado." % settlement_id)
	return Vector3.ZERO


func _go(spot: Vector3) -> void:
	var reported: Result = _bridge.request_report_position(_actor_id, spot, 0.0)
	assert_true(reported.ok, reported.message)


func _now() -> int:
	return _bridge.peek_time().total_minutes


func _accept(contract_id: int) -> BridgePlayerContractsReplies.ContractActionReply:
	return _bridge.request_contract_accept(_actor_id, contract_id)


func _abandon(contract_id: int) -> BridgePlayerContractsReplies.ContractActionReply:
	return _bridge.request_contract_abandon(_actor_id, contract_id)


## Posta um contrato de entrega direto na economia: o mercado `issuer` paga a recompensa para a custódia, o prazo é `minutes` depois de agora e o destino é `destination`.
func _post(issuer: int, destination: int, minutes: int = LONG_MINUTES) -> int:
	var posted: EconomyReplies.PostContractResult = _economy.request_post_contract(ContractBook.DELIVERY, issuer, REWARD, _now() + minutes, {"good_id": BREAD, "quantity": QUANTITY, "destination_id": destination})
	assert_true(posted.result.ok, posted.result.message)
	return posted.contract_id


func _post_labor() -> int:
	var posted: EconomyReplies.PostContractResult = _economy.request_post_contract(ContractBook.LABOR, _market_a, REWARD, _now() + LONG_MINUTES, {"place_id": WORK_PLACE, "minutes": 30})
	assert_true(posted.result.ok, posted.result.message)
	return posted.contract_id


## Um segundo personagem, junto do mercado A, com a conta aberta.
func _new_character() -> int:
	var actor_id: int = _bridge.request_spawn_character().actor_id
	assert_true(_bridge.request_report_position(actor_id, _center_a, 0.0).ok)
	assert_true(_bridge.request_open_player_account(actor_id).ok)
	return actor_id


## O jogador aceita, PELA PONTE, tantos contratos novos (de A para B) quantos o limite do dado permite; devolve os IDs.
func _fill_the_slots() -> Array[int]:
	var ids: Array[int] = []
	for index: int in LIMIT:
		ids.append(_post(_market_a, _market_b))
		var accepted: BridgePlayerContractsReplies.ContractActionReply = _accept(ids[index])
		assert_true(accepted.result.ok, "O aceite %d cabe no limite: %s" % [index, accepted.result.message])
	return ids


## Termina o contrato como `completed`, só pela economia: o jogador o aceita, leva o pão do mercado A e entrega no destino.
func _complete(contract_id: int) -> void:
	assert_true(_economy.request_accept_contract(contract_id, _actor_id).ok)
	assert_true(_economy.request_transfer_goods(_market_a, _actor_id, BREAD, QUANTITY).ok)
	assert_true(_economy.request_deliver_contract(contract_id).ok)


func _ids(board: BridgePlayerContractsReplies.ContractBoardReply) -> Array[int]:
	var ids: Array[int] = []
	for row: BridgePlayerContractsReplies.ContractBoardRow in board.rows:
		ids.append(row.contract_id)
	return ids


## O que NENHUMA consulta nem recusa pode mudar: o `state_hash` do mundo e a fila de eventos (os pendentes, ainda não entregues).
func _snapshot() -> Array:
	return [_host.runner.world.state_hash(), int(_host.runner.world.context.events.debug_summary()["pending"])]


## O pedido (do jogador ou, em `actor_id`, de outro ator) é recusado com `code`, a chave `key` e a recompensa 0, e NADA muda: nem o `state_hash`, nem a fila de eventos.
func _refused_abandon(contract_id: int, code: String, key: String, actor_id: int = PLAYER) -> void:
	var before: Array = _snapshot()
	_assert_refusal(_bridge.request_contract_abandon(_actor_id if actor_id == PLAYER else actor_id, contract_id), contract_id, code, key, before)


func _refused_accept(contract_id: int, code: String, key: String) -> void:
	var before: Array = _snapshot()
	_assert_refusal(_accept(contract_id), contract_id, code, key, before)


func _assert_refusal(reply: BridgePlayerContractsReplies.ContractActionReply, contract_id: int, code: String, key: String, before: Array) -> void:
	assert_eq([reply.result.code, reply.text_key, reply.reward, reply.contract_id], [code, key, 0, contract_id], "A recusa do contrato %d." % contract_id)
	assert_eq(_snapshot(), before, "A recusa do contrato %d não mudou nada (nem o `state_hash`, nem evento)." % contract_id)


func test_abandoning_from_far_away_fails_the_contract_with_the_abandoned_reason_and_changes_nothing_else() -> void:
	var contract_id: int = _post(_market_a, _market_b)
	assert_true(_bridge.request_trade(_actor_id, _market_a, BREAD, 1, BridgePlayerEconomyReplies.SIDE_BUY).result.ok, "O jogador leva um pão: abandonar não o move.")
	assert_true(_accept(contract_id).result.ok)
	_go(_center_a + Vector3(FAR_M, 0.0, 0.0))
	var funds: int = _bridge.peek_player_economy(_actor_id).funds
	var inventory: Array[Dictionary] = _economy.peek_inventory(_actor_id).rows
	var issuer_cash: int = _economy.peek_balance(_market_a).balance
	assert_eq([_economy.peek_balance(contract_id).balance, inventory.size()], [REWARD, 1], "Pré-condição: a recompensa está na custódia e o jogador leva o pão.")
	_host.runner.world.context.events.dispatch()
	_failed.clear()
	var before: Array = _snapshot()
	var abandoned: BridgePlayerContractsReplies.ContractActionReply = _abandon(contract_id)
	assert_true(abandoned.result.ok, abandoned.result.message)
	assert_eq([abandoned.contract_id, abandoned.reward, abandoned.text_key], [contract_id, 0, KEY_ABANDONED], "Nada é pago: recompensa 0 e a chave do abandono.")
	var contract: EconomyReplies.ContractQuery = _economy.peek_contract(contract_id)
	assert_eq([contract.state, contract.closed_reason, contract.acceptor_id], [ContractBook.STATE_FAILED, ABANDONED, _actor_id], "O `accepted` virou `failed` com o motivo, e o aceitante fica.")
	assert_eq([_bridge.peek_player_economy(_actor_id).funds, _economy.peek_inventory(_actor_id).rows], [funds, inventory], "Saldo e inventário do jogador ficam iguais.")
	assert_eq([_economy.peek_balance(contract_id).balance, _economy.peek_balance(_market_a).balance], [0, issuer_cash + REWARD], "A custódia voltou ao emissor.")
	assert_ne(_snapshot()[0], before[0], "Abandonar muda o `state_hash`.")
	_host.runner.world.context.events.dispatch()
	assert_eq(_failed.size(), 1, "Sai UM `ContractFailed`.")
	assert_eq([_failed[0].contract_id, _failed[0].issuer_id, _failed[0].reason], [contract_id, _market_a, ABANDONED])
	assert_true(_economy.peek_conservation().ok and _economy.peek_goods_conservation().ok and _economy.validate().is_empty(), "O dinheiro e os bens continuam contados.")


func test_abandon_refuses_in_the_order_of_the_contract_and_changes_nothing() -> void:
	var other: int = _new_character()
	var mine: int = _post(_market_a, _market_b)
	assert_true(_accept(mine).result.ok)
	var theirs: int = _post(_market_a, _market_b)
	assert_true(_economy.request_accept_contract(theirs, other).ok)
	var open: int = _post(_market_a, _market_b)
	var labor: int = _post_labor()
	var done: int = _post(_market_a, _market_b)
	_complete(done)
	var npc: int = _host.npc.peek_npc_ids()[0]
	for stranger: int in [npc, _market_a, UNKNOWN_ID]:
		_refused_abandon(mine, CharacterModule.CODE_UNKNOWN_ACTOR, KEY_FAILED, stranger)
	_refused_abandon(UNKNOWN_ID, CharacterModule.CODE_UNKNOWN_ACTOR, KEY_FAILED, npc)
	_refused_abandon(UNKNOWN_ID, EconomyCodes.UNKNOWN_CONTRACT, KEY_UNKNOWN)
	for not_mine: int in [open, theirs, labor]:
		_refused_abandon(not_mine, BridgePlayerContracts.CODE_NOT_YOURS, KEY_NOT_YOURS)
	_refused_abandon(done, EconomyCodes.CONTRACT_NOT_OPEN, KEY_NOT_OPEN)
	var late: int = _post(_market_a, _market_b, SHORT_MINUTES)
	assert_true(_accept(late).result.ok)
	_host.runner.run_steps(SHORT_MINUTES)
	assert_eq(_economy.peek_contract(late).state, ContractBook.STATE_ACCEPTED, "Pré-condição: no prazo, mas a economia ainda não o venceu (só na hora cheia).")
	_refused_abandon(late, EconomyCodes.CONTRACT_IMPOSSIBLE, KEY_IMPOSSIBLE)
	_host.runner.run_steps(MINUTES_PER_HOUR)
	assert_eq(_economy.peek_contract(late).state, ContractBook.STATE_EXPIRED, "Pré-condição: na hora cheia a economia o venceu.")
	_refused_abandon(late, EconomyCodes.CONTRACT_NOT_OPEN, KEY_NOT_OPEN)
	assert_true(_abandon(mine).result.ok)
	_refused_abandon(mine, EconomyCodes.CONTRACT_NOT_OPEN, KEY_NOT_OPEN)


func test_without_a_game_a_character_or_the_economy_abandon_fails_with_the_bridge_code() -> void:
	var no_places: Array[Place] = []
	var idle_host: SimulationHostNode = SimulationHostNode.new()
	_assert_bridge_code(SimBridge.new(idle_host, null, no_places), SimBridge.CODE_NO_GAME)
	idle_host.free()
	_assert_bridge_code(SimBridge.new(null, null, no_places), SimBridge.CODE_NO_GAME)
	var character: CharacterModule = _host.character
	_host.character = null
	_host.economy = null
	_assert_bridge_code(_bridge, SimBridge.CODE_NO_CHARACTER)
	_host.character = character
	_assert_bridge_code(_bridge, SimBridge.CODE_NO_ECONOMY)
	_host.economy = _economy
	var contract_id: int = _post(_market_a, _market_b)
	assert_true(_accept(contract_id).result.ok)
	assert_true(_abandon(contract_id).result.ok, "Com os módulos de volta, o abandono funciona.")


func _assert_bridge_code(bridge: SimBridge, code: String) -> void:
	var reply: BridgePlayerContractsReplies.ContractActionReply = bridge.request_contract_abandon(_actor_id, 1)
	assert_eq([reply.result.code, reply.text_key, reply.reward, reply.contract_id], [code, KEY_FAILED, 0, 1], "O pedido sem jogo, sem personagem ou sem economia.")


func test_the_fourth_accept_is_refused_by_the_limit_without_calling_the_economy_and_abandoning_frees_a_slot() -> void:
	assert_eq(_economy.peek_contract_limit(ContractBook.DELIVERY), LIMIT, "Pré-condição: o limite do dado real, pela fiação do jogo.")
	var other: int = _new_character()
	for _index: int in LIMIT:
		assert_true(_economy.request_accept_contract(_post(_market_a, _market_b), other).ok, "Os contratos de OUTRO ator não contam para o jogador.")
	var mine: Array[int] = _fill_the_slots()
	var fourth: int = _post(_market_a, _market_b)
	_refused_accept(fourth, BridgePlayerContracts.CODE_LIMIT, KEY_LIMIT)
	var contract: EconomyReplies.ContractQuery = _economy.peek_contract(fourth)
	assert_eq([contract.state, contract.acceptor_id], [ContractBook.STATE_OPEN, IdGenerator.NO_ID], "A economia não foi chamada: o 4º segue aberto e sem aceitante.")
	assert_true(_abandon(mine[0]).result.ok)
	assert_true(_accept(fourth).result.ok, "Abandonar liberou uma vaga.")
	_refused_accept(_post(_market_a, _market_b), BridgePlayerContracts.CODE_LIMIT, KEY_LIMIT)


func test_far_and_expired_beat_the_limit_and_a_contract_that_is_not_open_does_not_pass_through_it() -> void:
	var stale: int = _post(_market_a, _market_b, SHORT_MINUTES)
	var mine: Array[int] = _fill_the_slots()
	var theirs: int = _post(_market_a, _market_b)
	assert_true(_economy.request_accept_contract(theirs, _new_character()).ok)
	var fresh: int = _post(_market_a, _market_b)
	_refused_accept(fresh, BridgePlayerContracts.CODE_LIMIT, KEY_LIMIT)
	_go(_center_a + Vector3(FAR_M, 0.0, 0.0))
	_refused_accept(fresh, MarketReach.CODE_PLACE_TOO_FAR, KEY_TOO_FAR)
	_go(_center_a)
	_host.runner.run_steps(SHORT_MINUTES)
	_refused_accept(stale, BridgePlayerContracts.CODE_EXPIRED, KEY_EXPIRED)
	for taken: int in [mine[0], theirs]:
		_refused_accept(taken, EconomyCodes.CONTRACT_NOT_OPEN, KEY_NOT_OPEN)


func test_an_accepted_contract_past_its_deadline_does_not_take_a_slot() -> void:
	var short: int = _post(_market_a, _market_b, SHORT_MINUTES)
	assert_true(_accept(short).result.ok)
	for _index: int in LIMIT - 1:
		assert_true(_accept(_post(_market_a, _market_b)).result.ok)
	var fourth: int = _post(_market_a, _market_b)
	_refused_accept(fourth, BridgePlayerContracts.CODE_LIMIT, KEY_LIMIT)
	_host.runner.run_steps(SHORT_MINUTES)
	assert_eq(_economy.peek_contract(short).state, ContractBook.STATE_ACCEPTED, "Pré-condição: vencido pelo prazo, mas ainda `accepted` (a economia só o encerra na hora cheia).")
	assert_true(_accept(fourth).result.ok, "O vencido não ocupa vaga.")


func test_a_category_without_a_line_in_the_data_has_no_limit_and_the_board_says_zero() -> void:
	_end()
	var terrain: TerrainData = TerrainLoader.load_dir(WORLD_DIR).terrain
	var places: Array[Place] = SettlementLoader.load_dir(WORLD_DIR, terrain).places
	var setup: EconomySetup = EconomySetup.from_dir(EconomySetup.DEFAULT_DIR)
	setup.definitions.contract_limits.clear()
	_host = SimulationHostNode.new()
	_host.start_new_game(SEED, terrain, [], null, 0, setup)
	_begin(SimBridge.new(_host, terrain, places))
	assert_eq([_economy.peek_contract_limit(ContractBook.DELIVERY), _bridge.peek_contract_board(_actor_id, _market_a).accepted_limit], [0, 0], "Sem a linha de `delivery` no dado, 0: sem limite.")
	for index: int in LIMIT + 2:
		var accepted: BridgePlayerContractsReplies.ContractActionReply = _accept(_post(_market_a, _market_b))
		assert_true(accepted.result.ok, "Sem limite, o aceite %d passa: %s" % [index, accepted.result.message])


func test_the_board_shows_the_limit_the_closed_reason_and_the_abandoned_deliveries_among_the_finished_ones() -> void:
	var abandoned: Array[int] = []
	for index: int in BridgePlayerContracts.FINISHED_LIMIT + 1:
		abandoned.append(_post(_market_a, _market_b))
		assert_true(_accept(abandoned[index]).result.ok)
		assert_true(_abandon(abandoned[index]).result.ok)
	var open: int = _post(_market_a, _market_b)
	var carried: int = _post(_market_a, _market_b)
	assert_true(_accept(carried).result.ok)
	var before: Array = _snapshot()
	var board: BridgePlayerContractsReplies.ContractBoardReply = _bridge.peek_contract_board(_actor_id, _market_a)
	assert_true(board.result.ok, board.result.message)
	assert_eq(board.accepted_limit, LIMIT, "O limite de `delivery` do dado real, para a tela mostrar \"n de N\".")
	var expected: Array[int] = []
	expected.append_array(abandoned.slice(1))
	expected.append_array([open, carried])
	assert_eq(_ids(board), expected, "Os 5 `failed` mais recentes (o mais velho sai, no mesmo limite dos terminados), o aberto e o que ele carrega.")
	for row: BridgePlayerContractsReplies.ContractBoardRow in board.rows:
		var contract: EconomyReplies.ContractQuery = _economy.peek_contract(row.contract_id)
		assert_eq([row.state, row.closed_reason, row.is_mine], [contract.state, contract.closed_reason, contract.acceptor_id == _actor_id], "A linha do contrato %d tem o estado e o motivo da economia." % row.contract_id)
	assert_eq([board.rows[0].state, board.rows[0].closed_reason, board.rows[0].is_mine], [ContractBook.STATE_FAILED, ABANDONED, true], "O abandonado é `failed` com o motivo CRU, e é do jogador.")
	assert_eq([board.rows[5].closed_reason, board.rows[6].closed_reason], ["", ""], "Sem abandono, o motivo é vazio.")
	assert_eq(_snapshot(), before, "A consulta só lê.")
