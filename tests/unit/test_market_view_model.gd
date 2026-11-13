extends GutTest
## LW-106c: o `MarketViewModel` (src/presentation/ui/market/market_view_model.gd; contrato em docs/modules/presentation.md, "Interface de mercado (LW-106)"), sem janela, com o jogo REAL (`data/economy` e `data/world`: 3 mercados de 10 bens) e a
## ponte real, montados como em `test_bridge_player_trade.gd`. Confere que o modelo é a cópia fiel das duas consultas da ponte nos 3 mercados, com as linhas em ordem crescente de `good_id` (também com uma ponte que as entrega ao
## contrário); que cada `refresh` substitui tudo (depois de uma compra, ao trocar de mercado e em toda falha); que ator que não é o jogador, mercado inexistente e ponte nula, sem jogo ou sem economia devolvem falso e deixam o modelo vazio;
## que um bem sem estoque e um em escassez são copiados como estão (os dados reais não têm nenhum dos dois no dia 0: são criados com o comando de depuração da economia e o passar dos dias); e que ler nunca muda o `state_hash`.

const WORLD_DIR: String = "res://data/world"
const SEED: int = 106
const SETTLEMENT: String = "test_settlement_a"
const MARKET_PLACE_ID: String = "a_market_01"
const BREAD: String = "bread"
const WOOD: String = "wood"
const WOOL: String = "wool"
const BREAD_BOUGHT: int = 2
const WOOD_BOUGHT: int = 3
const UNKNOWN_ID: int = 999999
const MARKET_COUNT: int = 3
const GOOD_COUNT: int = 10
## A escassez é declarada depois de alguns dias sem estoque (`shortage_days`, dos dados [HIP]): o teste espera dia a dia até este teto em vez de fixar o número.
const MAX_DAYS_TO_SHORTAGE: int = 30

var _terrain: TerrainData
var _places: Array[Place] = []
var _setup: EconomySetup
var _center: Vector3
var _host: SimulationHostNode
var _bridge: SimBridge
var _economy: EconomyModule
var _actor_id: int = 0
var _market_id: int = 0
var _model: MarketViewModel


## Uma ponte cujos bens de cada mercado chegam do MAIOR `good_id` para o menor: a ordem crescente é garantida pelo modelo, não pela sorte da ponte.
class ReversedBridge:
	extends SimBridge

	func peek_economy_markets() -> BridgeEconomyReplies.EconomyMarketsReply:
		var reply: BridgeEconomyReplies.EconomyMarketsReply = super()
		for entry: BridgeEconomyReplies.EconomyMarketEntry in reply.markets:
			entry.rows.reverse()
		return reply


func before_all() -> void:
	var terrain_loaded: TerrainLoader.LoadResult = TerrainLoader.load_dir(WORLD_DIR)
	assert_true(terrain_loaded.result.ok, terrain_loaded.result.message)
	_terrain = terrain_loaded.terrain
	var settlements: SettlementLoader.LoadResult = SettlementLoader.load_dir(WORLD_DIR, _terrain)
	assert_true(settlements.result.ok, settlements.result.message)
	_places = settlements.places
	for place: Place in _places:
		if place.id == MARKET_PLACE_ID:
			_center = place.position
	_setup = EconomySetup.from_dir(EconomySetup.DEFAULT_DIR, true)
	assert_true(_setup.result.ok, _setup.result.message)


## Um jogo só com o personagem e a economia (sem NPCs: o jogo corre rápido e só muda o que o teste muda), com o jogador junto ao mercado `a_market_01` e com a conta aberta. A economia nasce com os comandos de depuração.
func before_each() -> void:
	_host = SimulationHostNode.new()
	_host.start_new_game(SEED, _terrain, [], null, 0, _setup)
	_bridge = SimBridge.new(_host, _terrain, _places)
	_economy = _host.economy
	_actor_id = _bridge.request_spawn_character().actor_id
	assert_true(_bridge.request_report_position(_actor_id, _center, 0.0).ok, "O jogador começa junto ao mercado.")
	assert_true(_bridge.request_open_player_account(_actor_id).ok)
	_market_id = _economy.peek_market_of(SETTLEMENT).market_id
	_model = MarketViewModel.new()


func after_each() -> void:
	_host.runner.finish()
	_host.free()


func _buy(good_id: String, quantity: int) -> BridgePlayerEconomyReplies.PlayerTradeReply:
	var bought: BridgePlayerEconomyReplies.PlayerTradeReply = _bridge.request_trade(_actor_id, _market_id, good_id, quantity, BridgePlayerEconomyReplies.SIDE_BUY)
	assert_true(bought.result.ok, bought.result.message)
	return bought


func _step_day() -> void:
	for _minute: int in SimClock.MINUTES_PER_DAY:
		_host.runner.step_once()


func _row_of(good_id: String) -> MarketViewModel.Row:
	for row: MarketViewModel.Row in _model.rows():
		if row.good_id == good_id:
			return row
	return null


func _assert_empty() -> void:
	assert_eq([_model.is_valid(), _model.shown_market_id(), _model.funds(), _model.weight(), _model.capacity(), _model.rows().size()], [false, IdGenerator.NO_ID, 0, 0, 0, 0], "Modelo vazio e inválido, sem nada da leitura anterior.")


## Uma falha de `refresh`: devolve falso e deixa o modelo vazio, mesmo depois de uma leitura boa (que o `refresh` da falha tem de apagar).
func _assert_refused(bridge: SimBridge, actor_id: int, market_id: int, why: String) -> void:
	assert_true(_model.refresh(_bridge, _actor_id, _market_id), "Leitura boa antes de: %s." % why)
	assert_false(_model.refresh(bridge, actor_id, market_id), why)
	_assert_empty()


## O modelo (já atualizado para `market_id`) é a cópia fiel das duas consultas da ponte real: as linhas do mercado, uma por bem e em ordem crescente, e os totais do jogador. `held` é quanto o jogador tem de cada bem
## (o que o teste comprou, uma conta que não vem da ponte): o que não está nele é 0.
func _assert_mirrors_the_bridge(market_id: int, held: Dictionary) -> void:
	var player: BridgePlayerEconomyReplies.PlayerEconomyReply = _bridge.peek_player_economy(_actor_id)
	var source_rows: Array[BridgeEconomyReplies.EconomyMarketRow] = []
	for entry: BridgeEconomyReplies.EconomyMarketEntry in _bridge.peek_economy_markets().markets:
		if entry.market_id == market_id:
			source_rows = entry.rows
	var shown: Array[MarketViewModel.Row] = _model.rows()
	assert_true(_model.is_valid())
	assert_eq([_model.shown_market_id(), _model.funds(), _model.weight(), _model.capacity()], [market_id, player.funds, player.weight, player.capacity], "O mercado e os totais do jogador são os da ponte.")
	assert_eq([shown.size(), source_rows.size()], [GOOD_COUNT, GOOD_COUNT], "Uma linha por bem do mercado, nenhuma da leitura anterior.")
	for index: int in mini(shown.size(), source_rows.size()):
		var row: MarketViewModel.Row = shown[index]
		var source: BridgeEconomyReplies.EconomyMarketRow = source_rows[index]
		assert_true(index == 0 or shown[index - 1].good_id < row.good_id, "Ordem crescente de `good_id` na linha %d." % index)
		assert_eq([row.good_id, row.ask, row.bid, row.stock, row.owned, row.is_in_shortage], [source.good_id, source.ask, source.bid, source.stock, held.get(row.good_id, 0), source.is_in_shortage], "Mercado %d, linha %d." % [market_id, index])


func test_a_new_model_is_empty_and_invalid() -> void:
	_assert_empty()


func test_each_market_is_a_faithful_copy_of_the_bridge_with_ten_rows_in_ascending_order() -> void:
	_buy(BREAD, BREAD_BOUGHT)
	_buy(WOOD, WOOD_BOUGHT)
	var entries: Array[BridgeEconomyReplies.EconomyMarketEntry] = _bridge.peek_economy_markets().markets
	assert_eq(entries.size(), MARKET_COUNT)
	for entry: BridgeEconomyReplies.EconomyMarketEntry in entries:
		assert_true(_model.refresh(_bridge, _actor_id, entry.market_id), "Mercado %d." % entry.market_id)
		_assert_mirrors_the_bridge(entry.market_id, {BREAD: BREAD_BOUGHT, WOOD: WOOD_BOUGHT})


func test_the_model_puts_the_rows_in_ascending_order_even_when_the_bridge_does_not() -> void:
	var reversed: ReversedBridge = ReversedBridge.new(_host, _terrain, _places)
	var raw: Array[BridgeEconomyReplies.EconomyMarketRow] = reversed.peek_economy_markets().markets[0].rows
	assert_true(raw[0].good_id > raw[raw.size() - 1].good_id, "Pré-condição: a ponte de teste entrega do maior para o menor.")
	assert_true(_model.refresh(reversed, _actor_id, _market_id))
	_assert_mirrors_the_bridge(_market_id, {})


func test_a_purchase_shows_in_the_next_refresh_and_nothing_stays_from_the_previous_one() -> void:
	assert_true(_model.refresh(_bridge, _actor_id, _market_id))
	var bread_before: MarketViewModel.Row = _row_of(BREAD)
	var stock_before: int = bread_before.stock
	var funds_before: int = _model.funds()
	var weight_before: int = _model.weight()
	var bought: BridgePlayerEconomyReplies.PlayerTradeReply = _buy(BREAD, BREAD_BOUGHT)
	assert_true(_model.refresh(_bridge, _actor_id, _market_id))
	var bread: MarketViewModel.Row = _row_of(BREAD)
	assert_eq([bread.owned, bread.stock], [BREAD_BOUGHT, stock_before - BREAD_BOUGHT], "Mais pão com o jogador e menos no mercado.")
	assert_eq([_model.funds(), _model.weight()], [funds_before - bought.total, weight_before + BREAD_BOUGHT * _economy.peek_good(BREAD).weight], "Menos dinheiro (o total da resposta do pedido) e mais peso.")
	assert_eq([bread_before.owned, bread_before.stock], [0, stock_before], "Uma linha da leitura anterior que a tela ainda segure não muda: o `refresh` cria linhas novas.")
	_assert_mirrors_the_bridge(_market_id, {BREAD: BREAD_BOUGHT})


func test_every_failure_returns_false_and_leaves_the_model_empty() -> void:
	var unopened: int = _bridge.request_spawn_character().actor_id
	var idle_host: SimulationHostNode = SimulationHostNode.new()
	_assert_refused(_bridge, UNKNOWN_ID, _market_id, "ID solto")
	_assert_refused(_bridge, _market_id, _market_id, "dono da economia que não é personagem (o próprio mercado)")
	_assert_refused(_bridge, unopened, _market_id, "personagem sem conta aberta")
	_assert_refused(_bridge, _actor_id, UNKNOWN_ID, "mercado que não existe")
	_assert_refused(SimBridge.new(idle_host, _terrain, _places), _actor_id, _market_id, "ponte sem jogo (o host não iniciou partida)")
	_assert_refused(SimBridge.new(null, null), _actor_id, _market_id, "ponte sem host")
	_assert_refused(null, _actor_id, _market_id, "ponte nula")
	idle_host.free()
	assert_true(_model.refresh(_bridge, _actor_id, _market_id))
	_host.economy = null
	assert_false(_model.refresh(_bridge, _actor_id, _market_id), "Jogo sem economia.")
	_host.economy = _economy
	_assert_empty()
	assert_true(_model.refresh(_bridge, _actor_id, _market_id), "Depois de uma falha, a próxima leitura boa volta a valer.")
	_assert_mirrors_the_bridge(_market_id, {})


func test_an_npc_id_is_refused_even_though_the_npc_has_an_account_in_the_economy() -> void:
	var host: SimulationHostNode = SimulationHostNode.new()
	var app: GameAppNode = GameAppNode.new()
	app.bind_host(host)
	app.start_default_game(host)
	var bridge: SimBridge = app.peek_bridge()
	var market_id: int = host.economy.peek_market_of(SETTLEMENT).market_id
	var player_id: int = bridge.request_spawn_character().actor_id
	assert_true(bridge.request_open_player_account(player_id).ok)
	assert_true(_model.refresh(bridge, player_id, market_id), "Controle: o jogador desse jogo é lido.")
	var npc_id: int = host.npc.peek_npc_ids()[0]
	assert_true(host.economy.peek_balance(npc_id).result.ok, "Pré-condição: o NPC tem conta na economia, então só o fato de não ser o jogador o recusa.")
	assert_false(_model.refresh(bridge, npc_id, market_id), "O NPC não é o jogador.")
	_assert_empty()
	app.free()
	host.runner.finish()
	host.free()


func test_a_good_without_stock_and_a_good_in_shortage_are_copied_as_they_are() -> void:
	for entry: BridgeEconomyReplies.EconomyMarketEntry in _bridge.peek_economy_markets().markets:
		for source: BridgeEconomyReplies.EconomyMarketRow in entry.rows:
			assert_true(source.stock > 0 and not source.is_in_shortage, "Pré-condição dos dados reais: no dia 0 o bem %s do mercado %d tem estoque e não está em falta." % [source.good_id, entry.market_id])
	assert_true(_economy.request_set_stock(_market_id, WOOL, 0).ok, "O comando de depuração existe neste teste (a economia nasce como build de desenvolvimento).")
	assert_true(_model.refresh(_bridge, _actor_id, _market_id))
	assert_eq(_row_of(WOOL).stock, 0, "Sem estoque.")
	_assert_mirrors_the_bridge(_market_id, {})
	for _day: int in MAX_DAYS_TO_SHORTAGE:
		_step_day()
		assert_true(_model.refresh(_bridge, _actor_id, _market_id))
		if _row_of(WOOL).is_in_shortage:
			break
	assert_true(_row_of(WOOL).is_in_shortage, "Dias sem estoque declaram a escassez, e o modelo mostra a marca.")
	assert_eq(_row_of(WOOL).stock, 0)
	_assert_mirrors_the_bridge(_market_id, {})


func test_refreshing_never_changes_the_state_hash() -> void:
	var hash_before: String = _host.runner.world.state_hash()
	assert_true(_model.refresh(_bridge, _actor_id, _market_id))
	assert_false(_model.refresh(_bridge, UNKNOWN_ID, _market_id))
	assert_false(_model.refresh(null, _actor_id, _market_id))
	assert_eq(_host.runner.world.state_hash(), hash_before, "Ler a ponte não escreve na simulação.")
