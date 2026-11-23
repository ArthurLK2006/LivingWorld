extends GutTest
## LW-107, verificação do ciclo das encomendas (21/11/2026): a ACEITAÇÃO é voluntária e o jogo real não posta encomenda. Jogo REAL (população inteira, produção e consumo, os carregadores do `GameApp`) por 2 dias.
## (1) Com o dado real (tabela de modelos VAZIA: a LW-107c3 NÃO está ativada) nenhuma entrega é postada e o quadro de cada mercado fica vazio. (2) Com os 3 modelos iniciais ligados SÓ em memória, o postador publica encomendas, mas ninguém as aceita sozinho (o `npc` só lê vagas até a LW-104:
## `npc_employment.gd` e docs/modules/economy.md, seção 8): ficam `open` ou `expired`; só o pedido do jogador pela ponte aceita uma, e só ela. Se a LW-104 fizer NPCs aceitarem entregas, o item (2) deve ser revisto de propósito, não ajustado em silêncio.

const WORLD_SEED: int = 1
const DAY_MINUTES: int = 1440
const DAYS: int = 1
const EXAMPLE_PATH: String = "res://data/economy/contract_templates.initial.json"

var _host: SimulationHostNode
var _app: GameAppNode
var _bridge: SimBridge
var _economy: EconomyModule
var _places: Array[Place] = []
var _actor_id: int = 0


func before_each() -> void:
	_host = SimulationHostNode.new()
	_app = GameAppNode.new()
	_app.bind_host(_host)


func after_each() -> void:
	_app.free()
	if _host.runner != null:
		_host.runner.finish()
	_host.free()


func _templates() -> Array[ContractTemplateDef]:
	var templates: Array[ContractTemplateDef] = []
	var rows: Array = JSON.parse_string(FileAccess.get_file_as_string(EXAMPLE_PATH))
	for row: Dictionary in rows:
		templates.append(ContractTemplateDef.new(str(row["id"]), str(row["kind"]), str(row["good_id"]), int(row["quantity"]), str(row["trigger"]), int(row["reward_margin_bp"]), int(row["deadline_hours"]), int(row["max_open"])))
	return templates


## O jogo novo como o do jogo, com o jogador nascido e com a conta aberta; `templates` null = o dado real (tabela vazia), senão os modelos dados no lugar dos do arquivo padrão.
func _start(templates: Variant) -> void:
	var terrain: TerrainLoader.LoadResult = TerrainLoader.load_dir(GameAppNode.TERRAIN_DIR)
	var points: PointOfInterestLoader.LoadResult = PointOfInterestLoader.load_dir(GameAppNode.TERRAIN_DIR, terrain.terrain)
	var settlements: SettlementLoader.LoadResult = SettlementLoader.load_dir(GameAppNode.TERRAIN_DIR, terrain.terrain)
	var npc_setup: NpcSetup = NpcSetup.from_dir(GameAppNode.NPC_DATA_DIR, SettlementService.new(settlements.settlements, settlements.places), OS.is_debug_build())
	var world_setup: WorldSetup = WorldSetup.from_dir(GameAppNode.TERRAIN_DIR, settlements.settlements, OS.is_debug_build())
	var economy_setup: EconomySetup = EconomySetup.from_dir(EconomySetup.DEFAULT_DIR, OS.is_debug_build())
	assert_true(terrain.result.ok and points.result.ok and settlements.result.ok and npc_setup.result.ok and world_setup.result.ok and economy_setup.result.ok, "Os dados reais carregam.")
	if templates != null:
		economy_setup.definitions.contract_templates = templates
	_host.start_new_game(WORLD_SEED, terrain.terrain, points.points, npc_setup, GameAppNode.NEW_GAME_START_MINUTE, economy_setup, world_setup)
	_economy = _host.economy
	_places = settlements.places
	_bridge = SimBridge.new(_host, terrain.terrain, _places)
	_actor_id = _bridge.request_spawn_character().actor_id
	assert_true(_bridge.request_open_player_account(_actor_id).ok)


func _deliveries() -> Array[EconomyReplies.ContractQuery]:
	var rows: Array[EconomyReplies.ContractQuery] = []
	for contract: EconomyReplies.ContractQuery in _economy.peek_contracts().contracts:
		if contract.kind != ContractBook.VACANCY:
			rows.append(contract)
	return rows


## O ID do mercado de cada povoado, na ordem dos locais.
func _markets() -> Array[int]:
	var ids: Array[int] = []
	for place: Place in _places:
		if place.kind == Place.KIND_MARKET:
			ids.append(_economy.peek_market_of(place.settlement_id).market_id)
	return ids


func _center_of(market_id: int) -> Vector3:
	var settlement_id: String = _economy.peek_market(market_id).settlement_id
	for place: Place in _places:
		if place.kind == Place.KIND_MARKET and place.settlement_id == settlement_id:
			return place.position
	return Vector3.ZERO


func test_with_the_real_data_no_delivery_is_posted_in_a_day_and_every_board_is_empty() -> void:
	_start(null)
	_host.runner.run_steps(DAYS * DAY_MINUTES)
	assert_eq(_deliveries().size(), 0, "O jogo real não posta entrega nem trabalho avulso (a tabela do postador está vazia): só vagas.")
	var markets: Array[int] = _markets()
	assert_gt(markets.size(), 0, "Pré-condição: o jogo tem mercados.")
	for market_id: int in markets:
		var board: BridgePlayerContractsReplies.ContractBoardReply = _bridge.peek_contract_board(_actor_id, market_id)
		assert_true(board.result.ok and board.rows.is_empty(), "O quadro do mercado %d está vazio." % market_id)
	assert_true(_economy.peek_conservation().ok and _economy.peek_goods_conservation().ok, "As conservações valem depois do dia.")


func test_with_the_templates_on_the_poster_posts_but_nobody_accepts_alone_and_only_the_players_request_does() -> void:
	_start(_templates())
	_host.runner.run_steps(DAYS * DAY_MINUTES)
	var posted: Array[EconomyReplies.ContractQuery] = _deliveries()
	assert_gt(posted.size(), 0, "Pré-condição: o postador publicou encomendas no 1º dia.")
	for contract: EconomyReplies.ContractQuery in posted:
		assert_true(contract.state in [ContractBook.STATE_OPEN, ContractBook.STATE_EXPIRED] and contract.acceptor_id == IdGenerator.NO_ID, "O contrato %d (%s) não foi aceito por ninguém: o NPC só lê vagas." % [contract.contract_id, contract.state])
	var market_id: int = 0
	var open_id: int = IdGenerator.NO_ID
	for candidate: int in _markets():
		for row: BridgePlayerContractsReplies.ContractBoardRow in _bridge.peek_contract_board(_actor_id, candidate).rows:
			if row.state == ContractBook.STATE_OPEN and open_id == IdGenerator.NO_ID:
				market_id = candidate
				open_id = row.contract_id
	assert_ne(open_id, IdGenerator.NO_ID, "Pré-condição: há uma encomenda aberta num quadro.")
	assert_true(_bridge.request_report_position(_actor_id, _center_of(market_id), 0.0).ok)
	assert_true(_bridge.request_contract_accept(_actor_id, open_id).result.ok, "O jogador pede e a encomenda é aceita.")
	_host.runner.run_steps(DAY_MINUTES)
	var accepted: Array[int] = []
	for contract: EconomyReplies.ContractQuery in _deliveries():
		assert_true(contract.acceptor_id in [IdGenerator.NO_ID, _actor_id], "O contrato %d só tem o jogador como aceitante, se tiver." % contract.contract_id)
		if contract.acceptor_id == _actor_id:
			accepted.append(contract.contract_id)
	assert_eq(accepted, [open_id] as Array[int], "Só a encomenda que o jogador pediu tem aceitante; mais um dia de NPCs vivos não aceitou nenhuma outra.")
	assert_true(_economy.peek_conservation().ok and _economy.peek_goods_conservation().ok, "As conservações valem depois dos 2 dias.")
	assert_eq(_host.runner.world.validate(), [] as Array[String])
