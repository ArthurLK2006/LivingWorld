extends SceneTree
## Medidor da economia, sem janela: `tools/measure_economy --days N [--seed S] [--markets]`.
## Joga o jogo REAL (o mesmo `GameAppNode.start_default_game` do jogo) por N dias simulados e imprime UMA linha CSV por dia
## (mais o cabeçalho): o dia 0 é o estado de partida; as demais amostras saem às 05:45, a hora em que o jogo novo começa.
## Colunas: vivos e mortos; dinheiro MOVIDO acumulado por motivo do livro-razão (`led_*`, o `moved` de `peek_ledger_totals`),
## criado e destruído; dinheiro por tipo de dono (`money_*`: NPC vivo, NPC morto, local de produção, mercado e o resto, que é o
## que a conservação soma além disso, como jogador e contratos); locais de produção por estado (o motivo da parada) e postos;
## comida por povoado (no mercado e nos inventários dos NPCs vivos); maior e menor preço de tabela por bem entre os mercados;
## e a conferência do dia (`validate`, conservação do dinheiro e dos bens). Com `--markets`, depois da tabela vêm linhas que
## começam com `#`: o estado dos mercados no último dia, que serve para calcular a melhor viagem de um comerciante.
## Não grava nada em disco: tudo sai pelo stdout. Sai com 0 se todos os dias fecharam sem problema; com 1 se não ou se o
## argumento for inválido. A semente só é aceita por `SimulationHostNode.start_new_game`: o `start_default_game` usa sempre
## `GameAppNode.DEFAULT_WORLD_SEED`; por isso, com `--seed`, os mesmos carregadores do `GameApp` são chamados aqui, e o teste
## confere que `--seed 1` e a partida padrão dão o mesmo resultado.

const DEFAULT_DAYS: int = 30
const COLUMN_SEPARATOR: String = ","

var _host: SimulationHostNode
var _app: GameAppNode
## Povoados (ordem alfabética), bens (ordem alfabética) e bens que matam a fome, descobertos pelo próprio jogo: nada de nome de dado aqui.
var _settlements: Array[String] = []
var _goods: Array[String] = []
var _food_goods: Array[String] = []


func _initialize() -> void:
	var days: int = DEFAULT_DAYS
	var world_seed: int = 0
	var has_seed: bool = false
	var wants_markets: bool = false
	var arguments: PackedStringArray = OS.get_cmdline_user_args()
	var index: int = 0
	while index < arguments.size():
		var flag: String = arguments[index]
		if flag == "--markets":
			wants_markets = true
			index += 1
			continue
		var value: String = arguments[index + 1] if index + 1 < arguments.size() else ""
		if (flag != "--days" and flag != "--seed") or not value.is_valid_int():
			_fail("argumento inválido: '%s %s'. Uso: tools/measure_economy --days N [--seed S] [--markets]" % [flag, value])
			return
		if flag == "--days":
			days = value.to_int()
		else:
			world_seed = value.to_int()
			has_seed = true
		index += 2
	if days < 0:
		_fail("--days deve ser zero ou positivo, veio %d" % days)
		return
	_host = SimulationHostNode.new()
	_app = GameAppNode.new()
	_app.bind_host(_host)
	var start_error: String = _start_game(world_seed, has_seed)
	if not start_error.is_empty() or _host.economy == null or _host.npc == null:
		_fail(start_error if not start_error.is_empty() else "o jogo começou sem os módulos economy e npc (terreno ou dados não carregaram)")
		return
	_discover_names()
	var header: PackedStringArray = _header()
	print(COLUMN_SEPARATOR.join(header))
	var is_valid: bool = true
	for day: int in range(days + 1):
		if day > 0:
			_host.runner.run_days(1)
		var row: PackedStringArray = _row(day)
		is_valid = is_valid and row[header.find("problems")] == "0" and row[header.find("money_ok")] == "1" and row[header.find("goods_ok")] == "1"
		print(COLUMN_SEPARATOR.join(row))
	if wants_markets:
		_print_markets()
	_host.runner.finish()
	_host.free()
	_app.free()
	quit(0 if is_valid else 1)


## Partida padrão sem semente; com semente, repete o que o `GameApp` faz, trocando só a semente. Devolve o erro, ou "" se deu certo.
func _start_game(world_seed: int, has_seed: bool) -> String:
	if not has_seed:
		_app.start_default_game(_host)
		return ""
	var terrain: TerrainLoader.LoadResult = TerrainLoader.load_dir(GameAppNode.TERRAIN_DIR)
	if not terrain.result.ok:
		return "terreno: " + terrain.result.message
	var points: PointOfInterestLoader.LoadResult = PointOfInterestLoader.load_dir(GameAppNode.TERRAIN_DIR, terrain.terrain)
	var places: SettlementLoader.LoadResult = SettlementLoader.load_dir(GameAppNode.TERRAIN_DIR, terrain.terrain)
	if not points.result.ok or not places.result.ok:
		return "pontos ou assentamentos: " + points.result.message + places.result.message
	var npc_setup: NpcSetup = NpcSetup.from_dir(GameAppNode.NPC_DATA_DIR, SettlementService.new(places.settlements, places.places), OS.is_debug_build())
	var world_setup: WorldSetup = WorldSetup.from_dir(GameAppNode.TERRAIN_DIR, places.settlements, OS.is_debug_build())
	var economy_setup: EconomySetup = EconomySetup.from_dir(EconomySetup.DEFAULT_DIR, OS.is_debug_build())
	if not npc_setup.result.ok or not world_setup.result.ok or not economy_setup.result.ok:
		return "dados: " + npc_setup.result.message + world_setup.result.message + economy_setup.result.message
	_host.start_new_game(world_seed, terrain.terrain, points.points, npc_setup, GameAppNode.NEW_GAME_START_MINUTE, economy_setup, world_setup)
	return ""


func _discover_names() -> void:
	var seen: Dictionary[String, bool] = {}
	for npc_id: int in _host.npc.peek_npc_ids():
		seen[_host.npc.peek_npc(npc_id).settlement_id] = true
	_settlements.assign(seen.keys())
	_settlements.sort()
	var good_seen: Dictionary[String, bool] = {}
	for settlement_id: String in _settlements:
		for row: Dictionary in _host.economy.peek_market_of(settlement_id).rows:
			good_seen[str(row["good_id"])] = true
	_goods.assign(good_seen.keys())
	_goods.sort()
	for good: EconomyReplies.GoodQuery in _host.economy.peek_goods_for_need("hunger").goods:
		_food_goods.append(good.good_id)


func _header() -> PackedStringArray:
	var cells: PackedStringArray = PackedStringArray(["day", "alive", "dead"])
	for settlement_id: String in _settlements:
		cells.append("alive_" + settlement_id.right(1))
	for reason: String in Ledger.REASONS:
		cells.append("led_" + reason)
	cells.append_array(PackedStringArray(["created", "destroyed", "money_npc_alive", "money_npc_dead", "money_site", "money_market", "money_other", "money_total"]))
	cells.append_array(PackedStringArray(["sites", "sites_running"]))
	for reason: String in ProductionBook.REASONS:
		cells.append("sites_" + reason.to_lower())
	cells.append_array(PackedStringArray(["posts", "posts_running"]))
	for settlement_id: String in _settlements:
		cells.append("food_market_" + settlement_id.right(1))
		cells.append("food_npcs_" + settlement_id.right(1))
	for good_id: String in _goods:
		cells.append("pmax_" + good_id)
		cells.append("pmin_" + good_id)
	for good_id: String in _goods:
		cells.append("made_" + good_id)
		cells.append("used_" + good_id)
	cells.append_array(PackedStringArray(["problems", "money_ok", "goods_ok"]))
	return cells


func _row(day: int) -> PackedStringArray:
	var counts: Dictionary = _host.npc.peek_counts()
	var cells: PackedStringArray = PackedStringArray([str(day), str(int(counts[NpcModule.COUNT_ALIVE])), str(int(counts[NpcModule.COUNT_DEAD]))])
	for settlement_id: String in _settlements:
		cells.append(str(_alive_in(settlement_id)))
	var moved: Dictionary[String, int] = {}
	var created: int = 0
	var destroyed: int = 0
	for ledger_row: Dictionary in _host.economy.peek_ledger_totals().rows:
		moved[str(ledger_row["reason"])] = int(ledger_row["moved"])
		created += int(ledger_row["created"])
		destroyed += int(ledger_row["destroyed"])
	for reason: String in Ledger.REASONS:
		cells.append(str(int(moved.get(reason, 0))))
	cells.append_array(PackedStringArray([str(created), str(destroyed)]))
	cells.append_array(_money_cells())
	cells.append_array(_site_cells())
	cells.append_array(_food_cells())
	cells.append_array(_price_cells())
	cells.append_array(_goods_cells())
	var conservation: EconomyReplies.ConservationQuery = _host.economy.peek_conservation()
	cells.append_array(PackedStringArray([str(_host.runner.world.validate().size()), "1" if conservation.ok else "0", "1" if _host.economy.peek_goods_conservation().ok else "0"]))
	return cells


func _alive_in(settlement_id: String) -> int:
	var total: int = 0
	for npc_id: int in _host.npc.peek_npc_ids():
		var npc_query: NpcModule.NpcQuery = _host.npc.peek_npc(npc_id)
		if npc_query.is_alive and npc_query.settlement_id == settlement_id:
			total += 1
	return total


## Bens criados (produção, estoque inicial) e destruídos (consumo, manutenção, insumos) desde o início, por bem (`peek_goods_conservation`).
func _goods_cells() -> PackedStringArray:
	var made: Dictionary[String, int] = {}
	var used: Dictionary[String, int] = {}
	for row: Dictionary in _host.economy.peek_goods_conservation().rows:
		made[str(row["good_id"])] = int(row["created"])
		used[str(row["good_id"])] = int(row["destroyed"])
	var cells: PackedStringArray = PackedStringArray()
	for good_id: String in _goods:
		cells.append(str(int(made.get(good_id, 0))))
		cells.append(str(int(used.get(good_id, 0))))
	return cells


## Dinheiro por tipo de dono. O dinheiro de NPC morto continua na conta fechada (a morte fecha a conta, não a esvazia): é medido à parte.
func _money_cells() -> PackedStringArray:
	var alive_money: int = 0
	var dead_money: int = 0
	for npc_id: int in _host.npc.peek_npc_ids():
		var balance: int = _host.economy.peek_balance(npc_id).balance
		if _host.npc.peek_npc(npc_id).is_alive:
			alive_money += balance
		else:
			dead_money += balance
	var site_money: int = 0
	var market_money: int = 0
	for settlement_id: String in _settlements:
		market_money += _host.economy.peek_balance(_host.economy.peek_market_of(settlement_id).market_id).balance
		for site: EconomyReplies.SiteQuery in _host.economy.peek_sites_of(settlement_id).sites:
			site_money += _host.economy.peek_balance(site.workplace_id).balance
	var total: int = _host.economy.peek_conservation().sum
	return PackedStringArray([str(alive_money), str(dead_money), str(site_money), str(market_money), str(total - alive_money - dead_money - site_money - market_money), str(total)])


## Locais de produção: total, rodando e parados por motivo (na ordem de `ProductionBook.REASONS`); depois os postos de serviço (total e rodando).
func _site_cells() -> PackedStringArray:
	var by_reason: Dictionary[String, int] = {}
	var sites: int = 0
	var sites_running: int = 0
	var posts: int = 0
	var posts_running: int = 0
	for settlement_id: String in _settlements:
		for site: EconomyReplies.SiteQuery in _host.economy.peek_sites_of(settlement_id).sites:
			sites += 1
			if site.running:
				sites_running += 1
			else:
				by_reason[site.reason] = int(by_reason.get(site.reason, 0)) + 1
		for post: EconomyReplies.PostQuery in _host.economy.peek_posts_of(settlement_id).posts:
			posts += 1
			if post.running:
				posts_running += 1
	var cells: PackedStringArray = PackedStringArray([str(sites), str(sites_running)])
	for reason: String in ProductionBook.REASONS:
		cells.append(str(int(by_reason.get(reason, 0))))
	cells.append_array(PackedStringArray([str(posts), str(posts_running)]))
	return cells


## Comida por povoado, em unidades dos bens que atendem a fome: a do mercado e a que os NPCs vivos do povoado carregam.
func _food_cells() -> PackedStringArray:
	var in_npcs: Dictionary[String, int] = {}
	for npc_id: int in _host.npc.peek_npc_ids():
		var npc_query: NpcModule.NpcQuery = _host.npc.peek_npc(npc_id)
		if not npc_query.is_alive:
			continue
		for item: Dictionary in _host.economy.peek_inventory(npc_id).rows:
			if _food_goods.has(str(item["good_id"])):
				in_npcs[npc_query.settlement_id] = int(in_npcs.get(npc_query.settlement_id, 0)) + int(item["quantity"])
	var cells: PackedStringArray = PackedStringArray()
	for settlement_id: String in _settlements:
		var in_market: int = 0
		for row: Dictionary in _host.economy.peek_market_of(settlement_id).rows:
			if _food_goods.has(str(row["good_id"])):
				in_market += int(row["stock"])
		cells.append(str(in_market))
		cells.append(str(int(in_npcs.get(settlement_id, 0))))
	return cells


func _price_cells() -> PackedStringArray:
	var cells: PackedStringArray = PackedStringArray()
	for good_id: String in _goods:
		var highest: int = 0
		var lowest: int = 0
		var is_first: bool = true
		for settlement_id: String in _settlements:
			var price: int = _host.economy.peek_price(_host.economy.peek_market_of(settlement_id).market_id, good_id).value
			highest = price if is_first else maxi(highest, price)
			lowest = price if is_first else mini(lowest, price)
			is_first = false
		cells.append(str(highest))
		cells.append(str(lowest))
	return cells


## Estado dos mercados no último dia, em linhas `#`: dinheiro do mercado e, por bem, estoque, alvo, preço de tabela, ask e bid.
func _print_markets() -> void:
	for settlement_id: String in _settlements:
		var market: EconomyReplies.MarketQuery = _host.economy.peek_market_of(settlement_id)
		print("#market_money,%s,%d" % [settlement_id, _host.economy.peek_balance(market.market_id).balance])
		for row: Dictionary in market.rows:
			print("#market,%s,%s,%d,%d,%d,%d,%d" % [settlement_id, str(row["good_id"]), int(row["stock"]), int(row["target_stock"]), int(row["price"]), int(row["ask"]), int(row["bid"])])


func _fail(message: String) -> void:
	print("ERRO: " + message)
	quit(1)
