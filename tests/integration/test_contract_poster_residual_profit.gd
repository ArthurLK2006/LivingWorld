extends GutTest
## LW-107c2 (risco residual (d), docs/modules/economy.md, seção 8; AGENTS 9.3): 30 dias do jogo REAL (720 horas, a população inteira, produção e consumo) com os 3 modelos de partida ativos (o arquivo de exemplo `contract_templates.initial.json`, porque
## o padrão do jogo não tem modelo). A cada hora cheia, DEPOIS do postador, um jogador (conta do tipo `player`, saldo inicial do tipo) COMPRA no mercado emissor o lote de cada contrato aberto do postador, aceita e entrega; o ciclo que o saldo ou o
## estoque não cobre é PULADO. O lucro de cada ciclo é a variação do saldo do jogador (recompensa recebida menos custo da compra), somado por mercado: tem de ficar abaixo do teto [HIP] de 10% do saldo inicial do tipo `market`. O teste IMPRIME o lucro
## medido, os ciclos feitos e os pulados por mercado; passou do teto: PARE e mostre a Arthur (ninguém sobe o teto, relaxa a regra (b) nem põe conferência no `accept`).

const WORLD_SEED: int = 1
const HOURS: int = 720
const MINUTES_PER_HOUR: int = 60
const PLAYER: int = 900000
const PROFIT_CAP_BP: int = 1000
const EXAMPLE_PATH: String = "res://data/economy/contract_templates.initial.json"

var _host: SimulationHostNode
var _app: GameAppNode
var _market_money: int = 0


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


## O jogo novo como o do jogo (os mesmos carregadores do `GameApp`), com os modelos de partida no lugar dos do arquivo padrão.
func _start() -> EconomyModule:
	var terrain: TerrainLoader.LoadResult = TerrainLoader.load_dir(GameAppNode.TERRAIN_DIR)
	var points: PointOfInterestLoader.LoadResult = PointOfInterestLoader.load_dir(GameAppNode.TERRAIN_DIR, terrain.terrain)
	var places: SettlementLoader.LoadResult = SettlementLoader.load_dir(GameAppNode.TERRAIN_DIR, terrain.terrain)
	var npc_setup: NpcSetup = NpcSetup.from_dir(GameAppNode.NPC_DATA_DIR, SettlementService.new(places.settlements, places.places), OS.is_debug_build())
	var world_setup: WorldSetup = WorldSetup.from_dir(GameAppNode.TERRAIN_DIR, places.settlements, OS.is_debug_build())
	var economy_setup: EconomySetup = EconomySetup.from_dir(EconomySetup.DEFAULT_DIR, OS.is_debug_build())
	assert_true(terrain.result.ok and points.result.ok and places.result.ok and npc_setup.result.ok and world_setup.result.ok and economy_setup.result.ok, "Os dados reais carregam.")
	economy_setup.definitions.contract_templates = _templates()
	for kind: OwnerKindDef in economy_setup.definitions.kinds:
		if kind.id == MarketBook.KIND_MARKET:
			_market_money = kind.initial_balance
	_host.start_new_game(WORLD_SEED, terrain.terrain, points.points, npc_setup, GameAppNode.NEW_GAME_START_MINUTE, economy_setup, world_setup)
	return _host.economy


## Um ciclo por contrato aberto do postador: compra o lote no emissor, aceita e entrega; o lucro entra no mercado do emissor.
func _cycle(economy: EconomyModule, tally: Dictionary[String, Dictionary]) -> void:
	for row: EconomyReplies.ContractQuery in economy.peek_contracts(ContractBook.STATE_OPEN).contracts:
		if row.kind != ContractBook.DELIVERY or row.issuer_id != row.destination_id:
			continue
		var key: String = str(row.issuer_id)
		var counts: Dictionary = tally.get(key, {"profit": 0, "done": 0, "skipped": 0})
		tally[key] = counts
		var before: int = economy.peek_balance(PLAYER).balance
		if not economy.request_trade(PLAYER, row.issuer_id, row.good_id, row.quantity, "buy").result.ok:
			counts["skipped"] += 1
			continue
		assert_true(economy.request_accept_contract(row.contract_id, PLAYER).ok, "O aceite não ganhou restrição nova.")
		assert_true(economy.request_deliver_contract(row.contract_id).ok, "A entrega no emissor funciona.")
		counts["done"] += 1
		counts["profit"] += economy.peek_balance(PLAYER).balance - before


func test_thirty_days_of_buying_at_the_issuer_and_delivering_stay_under_the_profit_cap() -> void:
	var economy: EconomyModule = _start()
	assert_true(economy.request_open_owner(PLAYER, "player").ok)
	var tally: Dictionary[String, Dictionary] = {}
	var clock: SimClock = _host.runner.world.context.clock
	var hours_done: int = 0
	while hours_done < HOURS:
		_host.runner.run_steps(1)
		if clock.total_minutes() % MINUTES_PER_HOUR == 0:
			hours_done += 1
			_cycle(economy, tally)
	var cap: int = IntMath.floor_div(_market_money * PROFIT_CAP_BP, PriceMath.BASIS)
	assert_gt(tally.size(), 0, "O postador postou contratos nos 30 dias.")
	for key: String in tally:
		print("LW-107c2 lucro residual, mercado %s: lucro %d (teto %d), ciclos feitos %d, pulados %d" % [key, tally[key]["profit"], cap, tally[key]["done"], tally[key]["skipped"]])
		assert_lt(int(tally[key]["profit"]), cap, "Mercado %s: o lucro acumulado passou do teto; PARE e mostre a Arthur." % key)
	assert_true(economy.peek_conservation().ok, "A conservação do dinheiro vale depois dos 30 dias.")
	assert_eq(_host.runner.world.validate(), [] as Array[String])
