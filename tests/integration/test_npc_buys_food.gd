extends GutTest
## LW-093 (parte 7): o jogo de verdade (`GameApp.start_default_game`, economia e dados reais) com o estoque provisório de comida ZERADO nos dois assentamentos: o NPC com fome e dinheiro (saldo inicial 60) compra a comida no
## mercado do povoado (pontuada pelo valor derivado: alívio da comida menos o preço) e come do inventário; o dinheiro e os bens seguem conservados e todo dinheiro novo veio de `mint` `game_start` (DEC-145, 153, 163).
## Sem dinheiro o pensador não escolhe `buy`: coberto em test_npc_trade.gd (`buy_value` 0 sem saldo).

const SETTLEMENTS: Array[String] = ["test_settlement_a", "test_settlement_b"]
const DAYS: int = 3
const FOOD_GOODS: Array[String] = ["bread", "grain"]

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


func _food_destroyed(economy: EconomyModule) -> int:
	var destroyed: int = 0
	for row: Dictionary in economy.peek_goods_conservation().rows:
		if FOOD_GOODS.has(str(row["good_id"])):
			destroyed += int(row["destroyed"])
	return destroyed


func _money_reasons(economy: EconomyModule) -> Array[String]:
	var reasons: Array[String] = []
	for row: Dictionary in economy.peek_ledger_totals().rows:
		reasons.append(str(row["reason"]))
	return reasons


func test_hungry_npcs_with_money_buy_food_at_the_market_and_eat_it_without_breaking_conservation() -> void:
	_app.start_default_game(_host)
	var economy: EconomyModule = _host.economy
	for settlement_id: String in SETTLEMENTS:
		assert_true(_host.npc.request_set_food_stock(settlement_id, 0).ok, "O estoque provisório de %s zerou." % settlement_id)
	var before: int = _food_destroyed(economy)
	_host.runner.run_days(DAYS)
	assert_eq(_money_reasons(economy), ["game_start", "trade"] as Array[String], "Todo o dinheiro novo veio de `mint` `game_start` e a única movimentação é a compra (`trade`): nenhum outro caminho mexe em saldo.")
	assert_true(_food_destroyed(economy) > before, "Comida foi consumida do inventário dos NPCs.")
	assert_true(economy.peek_conservation().ok and economy.peek_goods_conservation().ok)
	assert_eq(economy.validate(), [] as Array[String])
	assert_eq(_host.npc.validate(), [] as Array[String])
