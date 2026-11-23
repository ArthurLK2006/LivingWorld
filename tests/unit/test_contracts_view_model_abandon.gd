extends GutTest
## LW-107f4a, item (a): o `ContractsViewModel` e o abandono (docs/modules/presentation.md, "Encomendas por objetivo: abandonar, confirmar e capacidade"; economy.md, seção 8, itens (c), (d) e (g)), sem janela. O jogo é o REAL, montado como o `GameApp` monta
## (`start_default_game`: terreno, NPCs, locais e economia de `res://data`) e a ponte é a do jogo; os contratos são postados DIRETO na economia (o jogador não posta), aceitados e ABANDONADOS pela ponte (`request_contract_accept` e `request_contract_abandon`)
## e o relógio anda pelo `runner`. O `before_each` leva o jogo à hora cheia, para o prazo curto (30 minutos) vencer SEM a economia o encerrar (ela só o faz na hora cheia seguinte). Confere: `closed_reason` copiado; `can_abandon` (minha, `accepted` e no prazo);
## o `display_state` (`abandoned`, `failed`, `expired` e `completed` distintos); `accepted_count()` sem o vencido e igual à conta que a ponte usa no limite; `capacity()` (3 no dado real, 0 sem linha no dado e depois de uma recusa). O `failed` SEM motivo (a falha
## real) nenhuma entrega produz hoje: só se obtém trocando a resposta real da ponte (`EditedBridge`), como o `is_mine` falso de uma linha `accepted`, que a ponte real nunca devolve.

const WORLD_DIR: String = "res://data/world"
const SEED: int = 107
const SETTLEMENT_A: String = "test_settlement_a"
const POSTED_REWARD: int = 53 ## O pão que o postador de encomendas põe em cada mercado (LW-107c3, opção B): 5 pães, recompensa 53; os contratos do teste pagam `REWARD`.
const SETTLEMENT_B: String = "test_settlement_b"
const BREAD: String = "bread"
const MINUTES_PER_HOUR: int = 60
## Os números dos contratos do teste (os do jogo são [HIP]) e o limite do dado real (`delivery_limit`: 3, provisório do primeiro recorte). O tempo anda 40 minutos depois da montagem: o prazo curto (30) passa e a hora cheia seguinte (60) ainda não.
const REWARD: int = 12
const QUANTITY: int = 2
const LONG_MINUTES: int = 600
const SHORT_MINUTES: int = 30
const LATE_MINUTES: int = 40
const LIMIT: int = 3
const ABANDONED: String = "abandoned"
## Os contratos do quadro de `_build_board`, na ordem de criação (a ordem crescente de `contract_id`, a da ponte).
const NAMES: Array[String] = ["held", "late", "dropped", "dropped_late", "done", "fresh"]

var _host: SimulationHostNode
var _app: GameAppNode
var _bridge: SimBridge
var _economy: EconomyModule
var _actor_id: int = 0
var _market_a: int = 0
var _market_b: int = 0
var _model: ContractsViewModel = ContractsViewModel.new()


## A ponte do jogo, com a linha do quadro trocada por `edit` (recebe a `ContractBoardRow`): as outras duas consultas do modelo vão direto à ponte real.
class EditedBridge:
	extends SimBridge

	var real: SimBridge
	var edit: Callable

	func peek_contract_board(actor_id: int, market_id: int) -> BridgePlayerContractsReplies.ContractBoardReply:
		var reply: BridgePlayerContractsReplies.ContractBoardReply = real.peek_contract_board(actor_id, market_id)
		for row: BridgePlayerContractsReplies.ContractBoardRow in reply.rows:
			edit.call(row)
		return reply

	func peek_player_economy(actor_id: int) -> BridgePlayerEconomyReplies.PlayerEconomyReply:
		return real.peek_player_economy(actor_id)

	func peek_economy_markets() -> BridgeEconomyReplies.EconomyMarketsReply:
		return real.peek_economy_markets()


func before_each() -> void:
	_host = SimulationHostNode.new()
	_app = GameAppNode.new()
	_app.bind_host(_host)
	_app.start_default_game(_host)
	_begin(_app.peek_bridge())


func after_each() -> void:
	_end()


func _end() -> void:
	if _app != null:
		_app.free()
		_app = null
	if _host.runner != null:
		_host.runner.finish()
	_host.free()


## Põe em campo o jogo `_host` (já iniciado) e a ponte dele: o jogador nasce com a conta aberta junto ao centro do mercado A (o aceite da ponte pede alcance) e o relógio fica na hora cheia.
func _begin(bridge: SimBridge) -> void:
	_bridge = bridge
	_economy = _host.economy
	_actor_id = _bridge.request_spawn_character().actor_id
	assert_true(_bridge.request_open_player_account(_actor_id).ok)
	_market_a = _economy.peek_market_of(SETTLEMENT_A).market_id
	_market_b = _economy.peek_market_of(SETTLEMENT_B).market_id
	_host.runner.run_steps((MINUTES_PER_HOUR - _now() % MINUTES_PER_HOUR) % MINUTES_PER_HOUR)
	for place: BridgeReplies.PlaceReply in _bridge.peek_places().places:
		if place.kind == Place.KIND_MARKET and place.settlement_id == SETTLEMENT_A:
			assert_true(_bridge.request_report_position(_actor_id, Vector3(place.x, place.y, place.z), 0.0).ok)


func _now() -> int:
	return _bridge.peek_time().total_minutes


## Posta um contrato de entrega direto na economia: o mercado A paga a recompensa para a custódia, o prazo é `minutes` depois de agora e o destino é o mercado B.
func _post(minutes: int) -> int:
	var posted: EconomyReplies.PostContractResult = _economy.request_post_contract(ContractBook.DELIVERY, _market_a, REWARD, _now() + minutes, {"good_id": BREAD, "quantity": QUANTITY, "destination_id": _market_b})
	assert_true(posted.result.ok, posted.result.message)
	return posted.contract_id


func _accept(contract_id: int) -> BridgePlayerContractsReplies.ContractActionReply:
	return _bridge.request_contract_accept(_actor_id, contract_id)


## Posta um contrato e o jogador o aceita pela ponte.
func _hold(minutes: int) -> int:
	var contract_id: int = _post(minutes)
	var accepted: BridgePlayerContractsReplies.ContractActionReply = _accept(contract_id)
	assert_true(accepted.result.ok, accepted.result.message)
	return contract_id


## O jogador abandona pela ponte (nada é pago) o contrato que aceitou.
func _drop(contract_id: int) -> int:
	var abandoned: BridgePlayerContractsReplies.ContractActionReply = _bridge.request_contract_abandon(_actor_id, contract_id)
	assert_true(abandoned.result.ok, abandoned.result.message)
	return contract_id


## Um quadro com um contrato de cada situação, lido 40 minutos depois da hora cheia: `held` (aceito, no prazo), `late` (aceito, com o prazo passado e ainda `accepted`), `dropped` (abandonado, no prazo), `dropped_late` (abandonado antes do prazo, que depois passou),
## `done` (entregue) e `fresh` (aberto). Devolve os IDs por nome; o limite de 3 aceitos nunca é passado (o abandono libera a vaga).
func _build_board() -> Dictionary[String, int]:
	var ids: Dictionary[String, int] = {}
	ids["held"] = _hold(LONG_MINUTES)
	ids["late"] = _hold(SHORT_MINUTES)
	ids["dropped"] = _drop(_hold(LONG_MINUTES))
	ids["dropped_late"] = _drop(_hold(SHORT_MINUTES))
	ids["done"] = _post(LONG_MINUTES)
	assert_true(_economy.request_accept_contract(ids["done"], _actor_id).ok)
	assert_true(_economy.request_transfer_goods(_market_a, _actor_id, BREAD, QUANTITY).ok)
	assert_true(_economy.request_deliver_contract(ids["done"]).ok)
	ids["fresh"] = _post(LONG_MINUTES)
	_host.runner.run_steps(LATE_MINUTES)
	assert_true(_model.refresh(_bridge, _actor_id, _market_a))
	return ids


## O contrato de pão que o POSTADOR pôs no mercado `market_id` (o `open` de entrega que o mercado emitiu com a recompensa do modelo; os do teste pagam `REWARD`): o ID, ou NO_ID se não há.
func _posted_bread(market_id: int) -> int:
	for contract: EconomyReplies.ContractQuery in _economy.peek_contracts().contracts:
		if contract.kind == ContractBook.DELIVERY and contract.issuer_id == market_id and contract.reward == POSTED_REWARD:
			return contract.contract_id
	return IdGenerator.NO_ID


func _row(contract_id: int) -> ContractsViewModel.Row:
	for row: ContractsViewModel.Row in _model.rows():
		if row.contract_id == contract_id:
			return row
	assert_true(false, "O contrato %d não está no quadro." % contract_id)
	return null


## O campo `field` de cada linha do quadro, na ordem de `NAMES`.
func _column(ids: Dictionary[String, int], field: String) -> Array:
	var seen: Array = []
	for contract_name: String in NAMES:
		seen.append(_row(ids[contract_name]).get(field))
	return seen


func test_the_rows_copy_the_closed_reason_and_show_an_abandon_as_abandoned_never_as_failed_or_expired() -> void:
	var ids: Dictionary[String, int] = _build_board()
	assert_eq(_column(ids, "state"), ["accepted", "accepted", "failed", "failed", "completed", "open"], "Pré-condição: os `state` crus da ponte; o abandono é `failed` na economia.")
	assert_eq(_column(ids, "closed_reason"), ["", "", ABANDONED, ABANDONED, "", ""], "O `closed_reason` da ponte, copiado: só os dois abandonos o têm.")
	assert_eq(_column(ids, "display_state"), ["accepted", "expired", "abandoned", "abandoned", "completed", "open"], "O abandono é `abandoned` (também com o prazo passado), o vencido `expired` e cada um dos outros o seu `state`.")
	assert_true(_row(ids["dropped_late"]).is_overdue and not _row(ids["dropped"]).is_overdue, "Pré-condição: um abandono de prazo passado e o outro no prazo.")


func test_a_failed_row_without_a_reason_is_failed_and_not_abandoned() -> void:
	var ids: Dictionary[String, int] = _build_board()
	var edited: EditedBridge = EditedBridge.new(_host, null)
	edited.real = _bridge
	edited.edit = func(row: BridgePlayerContractsReplies.ContractBoardRow) -> void: row.closed_reason = ""
	assert_true(_model.refresh(edited, _actor_id, _market_a))
	assert_eq(_column(ids, "state"), ["accepted", "accepted", "failed", "failed", "completed", "open"], "Pré-condição: os mesmos estados, agora sem nenhum motivo.")
	assert_eq(_column(ids, "display_state"), ["accepted", "expired", "failed", "failed", "completed", "open"], "O `failed` sem motivo (a falha real) é `failed`, diferente de `abandoned`; o `expired` segue como está.")


func test_can_abandon_is_a_hint_only_for_my_accepted_contract_in_time() -> void:
	var ids: Dictionary[String, int] = _build_board()
	assert_eq(_column(ids, "can_abandon"), [true, false, false, false, false, false], "Só o aceito no prazo: não o vencido, os abandonados, o entregue nem o aberto.")
	var edited: EditedBridge = EditedBridge.new(_host, null)
	edited.real = _bridge
	edited.edit = func(row: BridgePlayerContractsReplies.ContractBoardRow) -> void: row.is_mine = false
	assert_true(_model.refresh(edited, _actor_id, _market_a))
	assert_eq([_row(ids["held"]).state, _row(ids["held"]).is_overdue], ["accepted", false], "Pré-condição: o `accepted` no prazo segue na linha.")
	assert_eq(_column(ids, "can_abandon"), [false, false, false, false, false, false], "Sem o dono (`is_mine` falso), nenhuma linha se abandona.")


func test_the_abandoned_rows_are_listed_in_my_contracts_after_the_accepted_ones_and_never_among_the_available() -> void:
	var ids: Dictionary[String, int] = _build_board()
	var mine: Array[int] = []
	for row: ContractsViewModel.Row in _model.mine():
		mine.append(row.contract_id)
	var available: Array[int] = []
	for row: ContractsViewModel.Row in _model.available():
		available.append(row.contract_id)
	assert_eq([mine, available], [[ids["held"], ids["late"], ids["dropped"], ids["dropped_late"], ids["done"]], [_posted_bread(_market_a), ids["fresh"]]], "As aceitas primeiro, depois as terminadas (os abandonos entre elas); só as `open` estão entre as disponíveis: o pão do postador e a do teste.")


func test_accepted_count_leaves_out_the_expired_row_and_is_the_count_the_bridge_uses_for_the_limit() -> void:
	_build_board()
	assert_eq([_model.accepted_count(), _model.capacity()], [1, LIMIT], "Só o `held` conta: o `late` venceu e os abandonados saíram.")
	for _index: int in LIMIT - 1:
		_hold(LONG_MINUTES)
	assert_true(_model.refresh(_bridge, _actor_id, _market_a))
	assert_eq([_model.accepted_count(), _model.capacity()], [LIMIT, LIMIT], "A ponte aceitou mais dois: o vencido não ocupou vaga, e agora o modelo conta o limite inteiro.")
	var refused: BridgePlayerContractsReplies.ContractActionReply = _accept(_post(LONG_MINUTES))
	assert_eq(refused.result.code, BridgePlayerContracts.CODE_LIMIT, "No limite que o modelo conta, a ponte recusa o próximo.")


func test_capacity_is_the_limit_of_the_real_game_zero_without_a_line_in_the_data_and_zero_after_a_refusal() -> void:
	assert_true(_model.refresh(_bridge, _actor_id, _market_a))
	assert_eq([_model.capacity(), _model.accepted_count(), _model.rows().size()], [LIMIT, 0, 1], "O dado real traz 3 e o quadro novo só tem uma linha, nenhuma aceita.")
	assert_eq(_model.rows()[0].contract_id, _posted_bread(_market_a), "A única linha é o pão que o postador pôs no mercado A.")
	assert_eq(_model.capacity(), _economy.peek_contract_limit(ContractBook.DELIVERY), "A capacidade é o número do dado, lido pela ponte: o modelo não tem número nenhum.")
	_hold(LONG_MINUTES)
	assert_true(_model.refresh(_bridge, _actor_id, _market_a))
	assert_eq([_model.capacity(), _model.accepted_count()], [LIMIT, 1], "Pré-condição: um aceito e o limite lido.")
	assert_false(_model.refresh(null, _actor_id, _market_a))
	assert_eq([_model.capacity(), _model.accepted_count()], [0, 0], "Leitura recusada: nada da leitura anterior fica.")
	_end()
	var terrain: TerrainData = TerrainLoader.load_dir(WORLD_DIR).terrain
	var places: Array[Place] = SettlementLoader.load_dir(WORLD_DIR, terrain).places
	var setup: EconomySetup = EconomySetup.from_dir(EconomySetup.DEFAULT_DIR)
	setup.definitions.contract_limits.clear()
	_host = SimulationHostNode.new()
	_host.start_new_game(SEED, terrain, [], null, 0, setup)
	_begin(SimBridge.new(_host, terrain, places))
	_hold(LONG_MINUTES)
	assert_true(_model.refresh(_bridge, _actor_id, _market_a))
	assert_eq([_model.capacity(), _model.accepted_count()], [0, 1], "Sem a linha de `delivery` no dado, 0: sem limite (e o aceito segue contado).")
