extends GutTest
## LW-097 (Fase B, junção com a frente A): o jogo de verdade (`GameApp.start_default_game`) nasce com as rotas do `world` E com a economia ligadas ao mesmo tempo. Cada setup (`world_setup` e
## `economy_setup`) chega ao módulo certo pela mesma assinatura, `start_new_game(…, economy_setup, world_setup)`: um dos dois perdido na junção não derruba nenhum outro teste, porque os módulos nascem
## vazios sem o setup. Aqui: as 3 rotas abertas no `world`, os 3 mercados e os 14 locais de produção na economia, e o `c_market_01` do tipo `market` (a LW-093 renomeou o tipo; a linha do C foi trocada na junção).

var _host: SimulationHostNode
var _app: GameAppNode


func before_each() -> void:
	_host = SimulationHostNode.new()
	_app = GameAppNode.new()
	_app.bind_host(_host)


func after_each() -> void:
	_app.free()
	if _host.runner != null:
		_host.runner.finish()
	_host.free()


func test_the_default_game_has_the_three_routes_in_the_world_and_the_economy_with_markets_and_sites() -> void:
	_app.start_default_game(_host)
	var modules: Dictionary = _host.runner.world.debug_summary()["modules"]
	assert_true(modules.has(GameModules.WORLD_NAME) and modules.has(GameModules.ECONOMY_NAME), "Os dois módulos estão registrados.")
	assert_eq(modules[GameModules.WORLD_NAME]["route_count"], 3, "O triângulo A–B, A–C e B–C vem do `routes.json` real.")
	assert_eq(modules[GameModules.WORLD_NAME]["closed_routes"], [] as Array[String], "Jogo novo: todas as rotas abertas.")
	var economy: EconomyModule = _host.economy
	assert_not_null(economy)
	for settlement_id: String in ["test_settlement_a", "test_settlement_b", "test_settlement_c"]:
		var market: EconomyReplies.MarketQuery = economy.peek_market_of(settlement_id)
		assert_true(market.result.ok, "%s tem mercado: %s" % [settlement_id, market.result.message])
		assert_eq(market.rows.size(), 10, "%s negocia os 10 bens." % settlement_id)
	assert_eq(economy.debug_summary()["production_sites"], 14, "Os 14 locais de produção dos dados reais (5 no A, 6 no B e 3 no C).")
	assert_eq(economy.validate(), [] as Array[String])
	assert_eq(_host.runner.world.validate(), [] as Array[String])


func test_the_three_market_places_of_the_real_data_are_of_the_market_kind() -> void:
	var data: NpcLifeCheck.GameData = NpcLifeCheck.load_game_data()
	assert_eq(data.problem, "", "Os dados reais do jogo carregam.")
	var markets: Array[String] = []
	for place: Place in data.places:
		if place.kind == Place.KIND_MARKET:
			markets.append(place.id)
	assert_eq(markets, ["a_market_01", "b_market_01", "c_market_01"] as Array[String], "Um local de mercado por povoado, todos com o tipo renomeado.")
