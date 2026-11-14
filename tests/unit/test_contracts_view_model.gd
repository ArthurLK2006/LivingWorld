extends GutTest
## LW-107d (critério C6): o `ContractsViewModel` (src/presentation/ui/market/contracts_view_model.gd; contrato em docs/modules/presentation.md, "Quadro de contratos (LW-107)"), sem janela, com o jogo REAL (`data/economy` e `data/world`:
## 3 mercados) e a ponte real, montados como em `test_bridge_player_contracts.gd`. Os contratos são postados DIRETO na economia (o jogador não posta) e o relógio anda pelo `runner` do jogo. Confere: as linhas são as da ponte, na ordem
## dela; `minutes_left` e `is_overdue` saem do `now` da resposta, na fronteira do prazo, num minuto em que a economia ainda chama o contrato de `open` ou `accepted` (ela só vence na hora cheia); o `display_state` é `expired` ("Vencido")
## em todo contrato de prazo passado e o `state` da ponte nos demais (um `completed` de prazo passado segue `completed`); a divisão em "Disponíveis" e "Meus contratos"; `owned` e `can_deliver`; o quadro vazio; que toda recusa da ponte
## vira falso, modelo vazio e o código; que o modelo não guarda referência à resposta da ponte; e que ler nunca muda o `state_hash`.

const WORLD_DIR: String = "res://data/world"
const SEED: int = 107
const SETTLEMENT_A: String = "test_settlement_a"
const SETTLEMENT_B: String = "test_settlement_b"
const SETTLEMENT_C: String = "test_settlement_c"
const BREAD: String = "bread"
const WOOD: String = "wood"
const UNKNOWN_ID: int = 999999
const MINUTES_PER_HOUR: int = 60
## Os estados com o texto da economia (o oráculo do teste; o modelo tem as constantes dele, que o último teste confere).
const OPEN: String = ContractBook.STATE_OPEN
const ACCEPTED: String = ContractBook.STATE_ACCEPTED
const COMPLETED: String = ContractBook.STATE_COMPLETED
const EXPIRED: String = ContractBook.STATE_EXPIRED
## Os números dos contratos do teste (os do jogo são [HIP]): recompensa, quantidade e prazos em minutos depois de agora. O curto vence ANTES da primeira hora cheia, o médio entre a primeira e a segunda, e o longo bem depois.
const REWARD: int = 12
const QUANTITY: int = 2
const SHORT_MINUTES: int = 40
const MEDIUM_MINUTES: int = 90
const LONG_MINUTES: int = 600
## O minuto em que o quadro de `_build_board` é lido: depois da hora cheia 60 e antes da 120.
const BOARD_MINUTE: int = 100

var _terrain: TerrainData
var _places: Array[Place] = []
var _setup: EconomySetup
var _center_a: Vector3
var _host: SimulationHostNode
var _bridge: SimBridge
var _economy: EconomyModule
var _actor_id: int = 0
var _market_a: int = 0
var _market_b: int = 0
var _market_c: int = 0
var _model: ContractsViewModel


## Uma ponte que entrega todo contrato como se NÃO fosse do jogador (a real nunca devolve `accepted` de outro ator): só prova que `can_deliver` exige `is_mine`.
class NotMineBridge:
	extends SimBridge

	func peek_contract_board(actor_id: int, market_id: int) -> BridgePlayerContractsReplies.ContractBoardReply:
		var reply: BridgePlayerContractsReplies.ContractBoardReply = super(actor_id, market_id)
		for row: BridgePlayerContractsReplies.ContractBoardRow in reply.rows:
			row.is_mine = false
		return reply


## Uma ponte que guarda a última resposta do quadro, para o teste mexer nela DEPOIS do `refresh` e provar que o modelo não guarda referência a ela.
class RecordingBridge:
	extends SimBridge

	var last_board: BridgePlayerContractsReplies.ContractBoardReply

	func peek_contract_board(actor_id: int, market_id: int) -> BridgePlayerContractsReplies.ContractBoardReply:
		last_board = super(actor_id, market_id)
		return last_board


func before_all() -> void:
	var loaded: TerrainLoader.LoadResult = TerrainLoader.load_dir(WORLD_DIR)
	assert_true(loaded.result.ok, loaded.result.message)
	_terrain = loaded.terrain
	var settlements: SettlementLoader.LoadResult = SettlementLoader.load_dir(WORLD_DIR, _terrain)
	assert_true(settlements.result.ok, settlements.result.message)
	_places = settlements.places
	for place: Place in _places:
		if place.kind == Place.KIND_MARKET and place.settlement_id == SETTLEMENT_A:
			_center_a = place.position
	_setup = EconomySetup.from_dir(EconomySetup.DEFAULT_DIR)
	assert_true(_setup.result.ok, _setup.result.message)


## Um jogo só com o personagem e a economia (sem NPCs), com o jogador junto ao mercado A e com a conta aberta; o relógio está no minuto 0.
func before_each() -> void:
	_host = SimulationHostNode.new()
	_host.start_new_game(SEED, _terrain, [], null, 0, _setup)
	_bridge = SimBridge.new(_host, _terrain, _places)
	_economy = _host.economy
	_actor_id = _bridge.request_spawn_character().actor_id
	assert_true(_bridge.request_report_position(_actor_id, _center_a, 0.0).ok, "O jogador começa junto ao mercado A.")
	assert_true(_bridge.request_open_player_account(_actor_id).ok)
	_market_a = _economy.peek_market_of(SETTLEMENT_A).market_id
	_market_b = _economy.peek_market_of(SETTLEMENT_B).market_id
	_market_c = _economy.peek_market_of(SETTLEMENT_C).market_id
	_model = ContractsViewModel.new()


func after_each() -> void:
	_host.runner.finish()
	_host.free()


func _now() -> int:
	return _bridge.peek_time().total_minutes


func _state_of(contract_id: int) -> String:
	return _economy.peek_contract(contract_id).state


## Posta um contrato de entrega direto na economia: `issuer` paga a recompensa para a custódia e o prazo é `minutes` depois de agora.
func _post(issuer: int, destination: int, minutes: int, good_id: String = BREAD, quantity: int = QUANTITY) -> int:
	var posted: EconomyReplies.PostContractResult = _economy.request_post_contract(ContractBook.DELIVERY, issuer, REWARD, _now() + minutes, {"good_id": good_id, "quantity": quantity, "destination_id": destination})
	assert_true(posted.result.ok, posted.result.message)
	return posted.contract_id


func _accept(contract_id: int) -> void:
	var accepted: Result = _economy.request_accept_contract(contract_id, _actor_id)
	assert_true(accepted.ok, accepted.message)


## Põe bens no inventário do jogador (tirados do mercado A, direto na economia, sem passar por compra).
func _give(good_id: String, quantity: int) -> void:
	var moved: Result = _economy.request_transfer_goods(_market_a, _actor_id, good_id, quantity)
	assert_true(moved.ok, moved.message)


## Um quadro com um contrato de cada situação, lido no minuto `BOARD_MINUTE`, na ordem de criação (a ordem crescente de `contract_id`): `completed` (entregue no minuto 0, com o prazo já passado), `failed` (aceito e vencido
## pela economia na hora 60), `late_accepted` (aceito, com o prazo passado e ainda `accepted`: a economia só o vence na hora 120), `carried` (aceito, no prazo), `late_open` (aberto, com o prazo passado e ainda `open`) e `fresh_open`
## (aberto, no prazo; pede madeira). Devolve os IDs por nome; o jogador termina sem bem nenhum.
func _build_board() -> Dictionary[String, int]:
	var ids: Dictionary[String, int] = {}
	ids["completed"] = _post(_market_a, _market_b, SHORT_MINUTES)
	_accept(ids["completed"])
	_give(BREAD, QUANTITY)
	var delivered: Result = _economy.request_deliver_contract(ids["completed"])
	assert_true(delivered.ok, delivered.message)
	ids["failed"] = _post(_market_a, _market_b, SHORT_MINUTES)
	_accept(ids["failed"])
	ids["late_accepted"] = _post(_market_c, _market_c, MEDIUM_MINUTES)
	_accept(ids["late_accepted"])
	ids["carried"] = _post(_market_c, _market_c, LONG_MINUTES)
	_accept(ids["carried"])
	ids["late_open"] = _post(_market_a, _market_b, MEDIUM_MINUTES)
	ids["fresh_open"] = _post(_market_c, _market_a, LONG_MINUTES, WOOD, 1)
	_host.runner.run_steps(BOARD_MINUTE)
	var economy_states: Array[String] = [_state_of(ids["completed"]), _state_of(ids["failed"]), _state_of(ids["late_accepted"]), _state_of(ids["carried"]), _state_of(ids["late_open"]), _state_of(ids["fresh_open"])]
	assert_eq([_now(), economy_states], [BOARD_MINUTE, [COMPLETED, EXPIRED, ACCEPTED, ACCEPTED, OPEN, OPEN] as Array[String]], "Pré-condição: o que a economia já venceu e o que ela ainda chama de aberto ou aceito.")
	return ids


func _row(contract_id: int) -> ContractsViewModel.Row:
	for row: ContractsViewModel.Row in _model.rows():
		if row.contract_id == contract_id:
			return row
	return null


## O que o teste confere de uma linha: o que falta, se venceu, o estado da ponte e o estado mostrado (vazio se a linha não existe).
func _shape_of(contract_id: int) -> Array:
	var row: ContractsViewModel.Row = _row(contract_id)
	return [] if row == null else [row.minutes_left, row.is_overdue, row.state, row.display_state]


## Todos os campos de cada linha, para comparar leituras inteiras de uma vez.
func _shapes(rows: Array[ContractsViewModel.Row]) -> Array:
	var shapes: Array = []
	for row: ContractsViewModel.Row in rows:
		shapes.append([row.contract_id, row.state, row.is_mine, row.good_id, row.quantity, row.reward, row.deadline, row.destination_id, row.destination_settlement_id, row.minutes_left, row.is_overdue, row.display_state, row.owned, row.can_deliver])
	return shapes


func _ids(rows: Array[ContractsViewModel.Row]) -> Array[int]:
	var ids: Array[int] = []
	for row: ContractsViewModel.Row in rows:
		ids.append(row.contract_id)
	return ids


## Atualiza o modelo para o mercado `market_id` e devolve os IDs das linhas com `can_deliver` verdadeiro.
func _deliverable(market_id: int) -> Array[int]:
	assert_true(_model.refresh(_bridge, _actor_id, market_id), "Mercado %d." % market_id)
	var ids: Array[int] = []
	for row: ContractsViewModel.Row in _model.rows():
		if row.can_deliver:
			ids.append(row.contract_id)
	return ids


## Uma leitura boa e não vazia, para a recusa seguinte ter o que apagar.
func _read_ok() -> void:
	assert_true(_model.refresh(_bridge, _actor_id, _market_a), "Leitura boa antes da recusa.")
	assert_false(_model.rows().is_empty(), "Pré-condição: o quadro tem linhas, então a recusa tem o que apagar.")


## Uma recusa: `refresh` devolve falso e o modelo fica vazio e inválido, com o código da ponte (sem tradução) e sem nada da leitura anterior.
func _assert_refusal(bridge: SimBridge, actor_id: int, market_id: int, code: String, why: String) -> void:
	assert_false(_model.refresh(bridge, actor_id, market_id), why)
	assert_eq([_model.is_valid(), _model.error_code(), _model.shown_market_id(), _model.rows().size(), _model.available().size(), _model.mine().size()], [false, code, IdGenerator.NO_ID, 0, 0, 0], "Modelo vazio e inválido, com o código: %s." % why)


func _assert_refused(bridge: SimBridge, actor_id: int, market_id: int, code: String, why: String) -> void:
	_read_ok()
	_assert_refusal(bridge, actor_id, market_id, code, why)


func test_a_new_model_is_empty_and_invalid() -> void:
	assert_eq([_model.is_valid(), _model.error_code(), _model.shown_market_id(), _model.rows().size(), _model.available().size(), _model.mine().size()], [false, "", IdGenerator.NO_ID, 0, 0, 0])


func test_the_rows_are_the_bridges_in_its_order_with_the_remaining_time_taken_from_its_now() -> void:
	var ids: Dictionary[String, int] = _build_board()
	var board: BridgePlayerContractsReplies.ContractBoardReply = _bridge.peek_contract_board(_actor_id, _market_a)
	assert_true(_model.refresh(_bridge, _actor_id, _market_a))
	var shown: Array[ContractsViewModel.Row] = _model.rows()
	assert_eq([_model.is_valid(), _model.error_code(), _model.shown_market_id(), board.now], [true, "", _market_a, BOARD_MINUTE], "O `now` da resposta é o relógio de `peek_time()`.")
	assert_eq([_ids(shown), board.rows.size()], [[ids["completed"], ids["failed"], ids["late_accepted"], ids["carried"], ids["late_open"], ids["fresh_open"]] as Array[int], 6], "Seis linhas, na ordem crescente de contrato.")
	for index: int in mini(shown.size(), board.rows.size()):
		var row: ContractsViewModel.Row = shown[index]
		var source: BridgePlayerContractsReplies.ContractBoardRow = board.rows[index]
		var copied: Array = [row.contract_id, row.state, row.is_mine, row.good_id, row.quantity, row.reward, row.deadline, row.destination_id]
		assert_eq(copied, [source.contract_id, source.state, source.is_mine, source.good_id, source.quantity, source.reward, source.deadline, source.destination_id], "A linha %d é a da ponte." % index)
		assert_eq([row.minutes_left, row.is_overdue], [source.deadline - board.now, source.deadline <= board.now], "O prazo da linha %d usa o `now` da resposta." % index)
		assert_true(index == 0 or shown[index - 1].contract_id < row.contract_id, "Ordem crescente de `contract_id` na linha %d." % index)


func test_a_contract_is_overdue_exactly_at_its_deadline_while_the_economy_still_calls_it_open_or_accepted() -> void:
	var open_id: int = _post(_market_a, _market_b, SHORT_MINUTES)
	var accepted_id: int = _post(_market_a, _market_b, SHORT_MINUTES)
	_accept(accepted_id)
	_host.runner.run_steps(SHORT_MINUTES - 1)
	assert_true(_model.refresh(_bridge, _actor_id, _market_a))
	assert_eq([_shape_of(open_id), _shape_of(accepted_id)], [[1, false, OPEN, OPEN], [1, false, ACCEPTED, ACCEPTED]], "Um minuto antes do prazo: falta 1, não vencido e o estado mostrado é o da ponte.")
	_host.runner.step_once()
	assert_true(_model.refresh(_bridge, _actor_id, _market_a))
	assert_eq([_shape_of(open_id), _shape_of(accepted_id)], [[0, true, OPEN, EXPIRED], [0, true, ACCEPTED, EXPIRED]], "No minuto do prazo: vencido e mostrado como `expired`, com o `state` da ponte intacto.")
	_host.runner.run_steps(5)
	assert_true(_model.refresh(_bridge, _actor_id, _market_a))
	assert_eq([_shape_of(open_id), _shape_of(accepted_id)], [[-5, true, OPEN, EXPIRED], [-5, true, ACCEPTED, EXPIRED]], "Depois do prazo, antes da hora cheia: tempo negativo, sem limite, e ainda `expired` na tela.")
	assert_eq([_state_of(open_id), _state_of(accepted_id)], [OPEN, ACCEPTED] as Array[String], "A economia só vence na hora cheia: o `state` dela não mudou.")


func test_the_display_state_is_expired_for_every_contract_past_its_deadline_except_the_completed_one() -> void:
	var ids: Dictionary[String, int] = _build_board()
	assert_true(_model.refresh(_bridge, _actor_id, _market_a))
	var elapsed: Array[int] = [SHORT_MINUTES - BOARD_MINUTE, MEDIUM_MINUTES - BOARD_MINUTE, LONG_MINUTES - BOARD_MINUTE]
	assert_eq(_shape_of(ids["completed"]), [elapsed[0], true, COMPLETED, COMPLETED], "`completed` com o prazo passado: `is_overdue` verdadeiro, mas segue `completed`, sem \"Vencido\".")
	assert_eq(_shape_of(ids["failed"]), [elapsed[0], true, EXPIRED, EXPIRED], "O `expired` da economia.")
	assert_eq(_shape_of(ids["late_accepted"]), [elapsed[1], true, ACCEPTED, EXPIRED], "O `accepted` de prazo passado.")
	assert_eq(_shape_of(ids["late_open"]), [elapsed[1], true, OPEN, EXPIRED], "O `open` de prazo passado.")
	assert_eq(_shape_of(ids["carried"]), [elapsed[2], false, ACCEPTED, ACCEPTED], "O `accepted` no prazo.")
	assert_eq(_shape_of(ids["fresh_open"]), [elapsed[2], false, OPEN, OPEN], "O `open` no prazo.")


func test_the_rows_split_into_available_and_mine_with_the_accepted_ones_first() -> void:
	var ids: Dictionary[String, int] = _build_board()
	assert_true(_model.refresh(_bridge, _actor_id, _market_a))
	assert_eq(_ids(_model.available()), [ids["late_open"], ids["fresh_open"]] as Array[int], "Disponíveis: os `open`, inclusive o de prazo passado, na ordem da ponte.")
	assert_eq(_ids(_model.mine()), [ids["late_accepted"], ids["carried"], ids["completed"], ids["failed"]] as Array[int], "Meus contratos: os `accepted` (inclusive o de prazo passado) e depois os terminados, cada grupo na ordem da ponte.")
	assert_eq(_model.available().size() + _model.mine().size(), _model.rows().size(), "Toda linha cai numa seção, uma vez só.")


func test_owned_is_how_much_the_player_has_of_the_rows_good() -> void:
	_build_board()
	assert_true(_model.refresh(_bridge, _actor_id, _market_a))
	var held: Array = []
	for row: ContractsViewModel.Row in _model.rows():
		held.append(row.owned)
	assert_eq(held, [0, 0, 0, 0, 0, 0], "Sem bem nenhum, `owned` é 0 em toda linha.")
	_give(BREAD, 3)
	_give(WOOD, 1)
	assert_true(_model.refresh(_bridge, _actor_id, _market_a))
	held = []
	for row: ContractsViewModel.Row in _model.rows():
		held.append([row.good_id, row.owned])
	assert_eq(held, [[BREAD, 3], [BREAD, 3], [BREAD, 3], [BREAD, 3], [BREAD, 3], [WOOD, 1]], "Cada linha mostra quanto o jogador tem do bem DELA.")


func test_can_deliver_is_true_only_for_my_accepted_contract_to_this_market_with_enough_goods_and_time() -> void:
	var ids: Dictionary[String, int] = _build_board()
	assert_eq(_deliverable(_market_c), [] as Array[int], "Sem o bem: ninguém entrega.")
	_give(BREAD, QUANTITY - 1)
	assert_eq(_deliverable(_market_c), [] as Array[int], "Um bem a menos que a quantidade: não entrega.")
	_give(BREAD, 1)
	assert_eq(_deliverable(_market_c), [ids["carried"]] as Array[int], "Com exatamente a quantidade: só o `accepted` meu, no prazo, com destino neste mercado (o `late_accepted` tem o mesmo destino e os bens, mas o prazo passou).")
	assert_eq(_deliverable(_market_a), [] as Array[int], "No mercado A o destino do `carried` é outro.")
	var done_ahead: int = _post(_market_a, _market_b, LONG_MINUTES)
	_accept(done_ahead)
	_give(BREAD, QUANTITY)
	var delivered: Result = _economy.request_deliver_contract(done_ahead)
	assert_true(delivered.ok, delivered.message)
	assert_eq(_deliverable(_market_b), [] as Array[int], "No mercado B (destino do `completed`, do `failed`, do `late_open` e do `done_ahead`, e o jogador tem os bens): `completed` (mesmo com o prazo por vir), `expired` e `open` nunca se entregam.")
	assert_true(_model.refresh(NotMineBridge.new(_host, _terrain, _places), _actor_id, _market_c))
	assert_false(_row(ids["carried"]).can_deliver, "O contrato que não é meu não se entrega, mesmo `accepted`, no destino e com os bens.")


func test_can_deliver_turns_false_exactly_at_the_deadline() -> void:
	var contract_id: int = _post(_market_a, _market_b, SHORT_MINUTES)
	_accept(contract_id)
	_give(BREAD, QUANTITY)
	_host.runner.run_steps(SHORT_MINUTES - 1)
	assert_eq(_deliverable(_market_b), [contract_id] as Array[int], "Um minuto antes do prazo, aceito, no destino e com os bens: entrega.")
	_host.runner.step_once()
	assert_eq(_deliverable(_market_b), [] as Array[int], "No minuto do prazo a dica de entrega apaga (`is_overdue`).")


func test_the_destination_settlement_comes_from_the_markets_and_is_empty_when_the_destination_is_not_a_market() -> void:
	var to_b: int = _post(_market_a, _market_b, LONG_MINUTES)
	var to_c: int = _post(_market_a, _market_c, LONG_MINUTES)
	var to_player: int = _post(_market_a, _actor_id, LONG_MINUTES)
	assert_true(_model.refresh(_bridge, _actor_id, _market_a))
	assert_eq([_row(to_b).destination_settlement_id, _row(to_c).destination_settlement_id, _row(to_player).destination_settlement_id], [SETTLEMENT_B, SETTLEMENT_C, ""])


func test_an_empty_board_is_a_valid_model_with_no_rows() -> void:
	_host.runner.run_steps(MINUTES_PER_HOUR)
	assert_true(_model.refresh(_bridge, _actor_id, _market_a), "Quadro vazio é sucesso, não erro: o jogo ainda não tem contrato de entrega nenhum.")
	assert_eq([_model.is_valid(), _model.error_code(), _model.shown_market_id(), _model.rows().size(), _model.available().size(), _model.mine().size()], [true, "", _market_a, 0, 0, 0])


func test_every_refusal_returns_false_with_the_bridges_code_and_leaves_the_model_empty() -> void:
	_post(_market_a, _market_b, LONG_MINUTES)
	var unopened: int = _bridge.request_spawn_character().actor_id
	var idle_host: SimulationHostNode = SimulationHostNode.new()
	_assert_refused(_bridge, UNKNOWN_ID, _market_a, CharacterModule.CODE_UNKNOWN_ACTOR, "ID solto")
	_assert_refused(_bridge, _market_a, _market_a, CharacterModule.CODE_UNKNOWN_ACTOR, "dono da economia que não é personagem (o próprio mercado)")
	_assert_refused(_bridge, unopened, _market_a, EconomyCodes.UNKNOWN_OWNER, "personagem sem conta aberta")
	_assert_refused(_bridge, _actor_id, UNKNOWN_ID, EconomyCodes.UNKNOWN_MARKET, "mercado que não existe")
	_assert_refused(SimBridge.new(idle_host, _terrain, _places), _actor_id, _market_a, SimBridge.CODE_NO_GAME, "ponte sem jogo (o host não iniciou partida)")
	_assert_refused(SimBridge.new(null, null), _actor_id, _market_a, SimBridge.CODE_NO_GAME, "ponte sem host")
	_assert_refused(null, _actor_id, _market_a, SimBridge.CODE_NO_GAME, "ponte nula")
	idle_host.free()
	_read_ok()
	var character: CharacterModule = _host.character
	_host.character = null
	_assert_refusal(_bridge, _actor_id, _market_a, SimBridge.CODE_NO_CHARACTER, "jogo sem o módulo do personagem")
	_host.character = character
	_read_ok()
	_host.economy = null
	_assert_refusal(_bridge, _actor_id, _market_a, SimBridge.CODE_NO_ECONOMY, "jogo sem economia")
	_host.economy = _economy
	assert_true(_model.refresh(_bridge, _actor_id, _market_a), "Depois de uma recusa, a próxima leitura boa volta a valer.")
	assert_eq([_model.is_valid(), _model.error_code(), _model.rows().size()], [true, "", 1], "...e apaga o código da recusa.")


func test_the_model_keeps_no_reference_to_the_bridges_reply_and_each_refresh_replaces_everything() -> void:
	var ids: Dictionary[String, int] = _build_board()
	var recording: RecordingBridge = RecordingBridge.new(_host, _terrain, _places)
	assert_true(_model.refresh(recording, _actor_id, _market_a))
	var kept: Array = _shapes(_model.rows())
	for source: BridgePlayerContractsReplies.ContractBoardRow in recording.last_board.rows:
		source.state = ""
		source.reward = -1
		source.deadline = 0
	recording.last_board.now = 0
	recording.last_board.rows.clear()
	_model.rows().clear()
	_model.available().clear()
	_model.mine().clear()
	assert_eq(_shapes(_model.rows()), kept, "Mexer na resposta da ponte ou nas listas devolvidas não muda o modelo.")
	var held: ContractsViewModel.Row = _row(ids["fresh_open"])
	_accept(ids["fresh_open"])
	assert_true(_model.refresh(recording, _actor_id, _market_a))
	assert_eq([_row(ids["fresh_open"]).state, held.state], [ACCEPTED, OPEN], "Cada leitura substitui tudo, e a linha da leitura anterior que a tela ainda segure não muda: o `refresh` cria linhas novas.")


func test_two_readings_of_the_same_state_agree_and_reading_never_changes_the_state_hash() -> void:
	_build_board()
	var other: ContractsViewModel = ContractsViewModel.new()
	var hash_before: String = _host.runner.world.state_hash()
	assert_true(_model.refresh(_bridge, _actor_id, _market_a))
	assert_true(other.refresh(_bridge, _actor_id, _market_a))
	assert_eq(_shapes(other.rows()), _shapes(_model.rows()), "Mesmo estado, mesmas linhas: o modelo não tem relógio nem sorteio.")
	assert_false(_model.refresh(_bridge, UNKNOWN_ID, _market_a))
	assert_false(_model.refresh(null, _actor_id, _market_a))
	assert_eq(_host.runner.world.state_hash(), hash_before, "Ler a ponte não escreve na simulação.")


func test_the_state_names_are_the_economys_and_the_bridges() -> void:
	var names: Array[String] = [ContractsViewModel.STATE_OPEN, ContractsViewModel.STATE_ACCEPTED, ContractsViewModel.STATE_COMPLETED, ContractsViewModel.STATE_EXPIRED]
	assert_eq(names, [OPEN, ACCEPTED, COMPLETED, EXPIRED] as Array[String], "Os nomes do modelo são os da economia.")
	assert_eq(names, [BridgePlayerContracts.STATE_OPEN, BridgePlayerContracts.STATE_ACCEPTED, BridgePlayerContracts.STATE_COMPLETED, BridgePlayerContracts.STATE_EXPIRED] as Array[String], "...e os que a ponte devolve.")
