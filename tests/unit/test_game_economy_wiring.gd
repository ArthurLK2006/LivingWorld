extends GutTest
## LW-093 (parte 3): o jogo de verdade (`GameApp.start_default_game`) recebe as definições da economia: os mercados dos assentamentos nascem (IDs 1 e 2, porque a `economy` é registrada antes do `npc`), os NPCs abrem conta com o
## saldo inicial do tipo `npc` (60) e o dinheiro de todo o mundo vem só de `mint` `game_start`. Um mundo sem terreno não tem módulos do jogo, nem economia.

var _host: SimulationHostNode
var _app: GameAppNode


func before_each() -> void:
	_host = SimulationHostNode.new()
	_app = GameAppNode.new()
	_app.bind_host(_host)


func after_each() -> void:
	_app.free()
	_host.runner.finish()
	_host.free()


func test_the_default_game_has_the_markets_and_every_npc_has_an_account_with_the_initial_money() -> void:
	_app.start_default_game(_host)
	var economy: EconomyModule = _host.economy
	assert_not_null(economy)
	var market_a: EconomyReplies.MarketQuery = economy.peek_market_of("test_settlement_a")
	var market_b: EconomyReplies.MarketQuery = economy.peek_market_of("test_settlement_b")
	var market_c: EconomyReplies.MarketQuery = economy.peek_market_of("test_settlement_c")
	assert_true(market_a.result.ok and market_b.result.ok and market_c.result.ok, market_a.result.message + market_b.result.message + market_c.result.message)
	assert_eq([market_a.market_id, market_b.market_id, market_c.market_id], [1, 2, 3], "A economia vem antes do `npc` e gasta os primeiros IDs: os três mercados e, depois, os 14 locais de produção.")
	var npc_ids: Array[int] = _host.npc.peek_npc_ids()
	assert_true(npc_ids.size() > 0)
	assert_eq(npc_ids[0], 18, "O primeiro NPC é o 18: os IDs 1 a 3 são dos mercados e 4 a 17, dos locais de produção.")
	for npc_id: int in npc_ids:
		assert_eq(economy.peek_balance(npc_id).balance, 60, "O NPC %d abriu a conta com o saldo inicial do tipo." % npc_id)
	var conservation: EconomyReplies.ConservationQuery = economy.peek_conservation()
	assert_eq([conservation.created, conservation.ok], [9000 + 14 * 200 + 60 * npc_ids.size(), true], "Três mercados de 3000, 14 locais de produção de 200 e 60 por NPC: tudo por `mint` `game_start`.")
	assert_eq(economy.peek_ledger_totals().rows.size(), 1, "Um só motivo de dinheiro novo.")
	assert_eq(economy.validate(), [] as Array[String])


func test_a_world_without_terrain_has_no_game_modules_and_so_no_economy() -> void:
	_host.start_new_game(5)
	assert_null(_host.economy, "Sem terreno nem módulos do jogo, não há economia.")
