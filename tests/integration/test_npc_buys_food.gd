extends GutTest
## LW-093 (parte 7): o jogo de verdade (`GameApp.start_default_game`, economia e dados reais) com o estoque provisório de comida ZERADO nos dois assentamentos: o NPC com fome e dinheiro (saldo inicial 60) compra a comida no
## mercado do povoado (pontuada pelo valor derivado: alívio da comida menos o preço) e come do inventário; o dinheiro e os bens seguem conservados e todo dinheiro novo veio de `mint` `game_start` (DEC-145, 153, 163).
## Sem dinheiro o pensador não escolhe `buy`: coberto em test_npc_trade.gd (`buy_value` 0 sem saldo).

const SETTLEMENTS: Array[String] = ["test_settlement_a", "test_settlement_b"]
const DAYS: int = 3
const FOOD_GOODS: Array[String] = ["bread", "grain"]
const MARKET_PLACE: String = "a_market_01"
const HOME_PLACE: String = "a_home_01"
const WORK_PLACE: String = "a_work_01"
const MARKET_X_CM: int = 31300
const MARKET_Z_CM: int = 55600
## A fome nasce crítica (a de dados nasce em 20): a janela em que o NPC com pão na mochila tem de comer cabe em poucas horas.
const CRITICAL_START: int = 95
const HOURS: int = 3

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
	assert_eq(_money_reasons(economy), ["game_start", "salary", "trade"] as Array[String], "Todo o dinheiro novo veio de `mint` `game_start` e as únicas movimentações são a compra (`trade`) e, desde a LW-097, o salário dos 14 locais de produção dos dados reais (`salary`, LW-095): nenhum outro caminho mexe em saldo.")
	assert_true(_food_destroyed(economy) > before, "Comida foi consumida do inventário dos NPCs.")
	assert_true(economy.peek_conservation().ok and economy.peek_goods_conservation().ok)
	assert_eq(economy.validate(), [] as Array[String])
	assert_eq(_host.npc.validate(), [] as Array[String])


## O mesmo jogo real, com os dados de `res://data` carregados como o `GameApp` carrega, mas com a fome de TODOS nascendo crítica (a montagem é a de `start_default_game`; só o valor de partida muda, em memória).
func _start_game_with_critical_hunger() -> void:
	var terrain: TerrainLoader.LoadResult = TerrainLoader.load_dir(GameAppNode.TERRAIN_DIR)
	var points: PointOfInterestLoader.LoadResult = PointOfInterestLoader.load_dir(GameAppNode.TERRAIN_DIR, terrain.terrain)
	var loaded: SettlementLoader.LoadResult = SettlementLoader.load_dir(GameAppNode.TERRAIN_DIR, terrain.terrain)
	var npc_setup: NpcSetup = NpcSetup.from_dir(GameAppNode.NPC_DATA_DIR, SettlementService.new(loaded.settlements, loaded.places), true)
	var world_setup: WorldSetup = WorldSetup.from_dir(GameAppNode.TERRAIN_DIR, loaded.settlements, true)
	var economy_setup: EconomySetup = EconomySetup.from_dir(EconomySetup.DEFAULT_DIR, true)
	for result: Result in [terrain.result, points.result, loaded.result, npc_setup.result, world_setup.result, economy_setup.result]:
		assert_true(result.ok, result.message)
	npc_setup.need_defs[0].start_value = CRITICAL_START
	_host.start_new_game(GameAppNode.DEFAULT_WORLD_SEED, terrain.terrain, points.points, npc_setup, GameAppNode.NEW_GAME_START_MINUTE, economy_setup, world_setup)


func _create_in_market(occupation_id: String, work_place_id: String) -> int:
	var spec: NpcSpec = NpcSpec.new()
	spec.name_key = "npc.name.villager"
	spec.name_number = 1
	spec.occupation_id = occupation_id
	spec.settlement_id = SETTLEMENTS[0]
	spec.place_id = MARKET_PLACE
	spec.work_place_id = work_place_id
	spec.home_place_id = HOME_PLACE
	spec.x_cm = MARKET_X_CM
	spec.z_cm = MARKET_Z_CM
	var created: NpcModule.CreateResult = _host.npc.request_create_npc(spec)
	assert_true(created.result.ok, created.result.message)
	return created.npc_id


func _bread_of(owner_id: int) -> int:
	for row: Dictionary in _host.economy.peek_inventory(owner_id).rows:
		if row["good_id"] == "bread":
			return int(row["quantity"])
	return 0


## LW-098h0 no jogo real (dados de `res://data`, 130 NPCs, fome crítica na partida): o comerciante e o lavrador nascem no mesmo mercado com a mesma casa e 2 pães na mochila, o grão está esgotado (a compra de pão vale mais que a refeição em casa). O comerciante come em vez
## de comprar; o lavrador, que é NPC comum, compra como antes (a regra é só do comerciante).
func test_the_hungry_merchant_with_bread_in_the_pack_eats_instead_of_buying_while_the_common_npc_still_buys() -> void:
	_start_game_with_critical_hunger()
	for settlement_id: String in SETTLEMENTS:
		assert_true(_host.npc.request_set_food_stock(settlement_id, 0).ok)
	var merchant: int = _create_in_market("merchant", MARKET_PLACE)
	var farmer: int = _create_in_market("farmer", WORK_PLACE)
	var market_id: int = _host.economy.peek_market_of(SETTLEMENTS[0]).market_id
	assert_true(_host.economy.request_set_stock(market_id, "grain", 0).ok, "O grão esgotado: a melhor compra é de pão (o alívio dela vence o da refeição em casa).")
	for holder: int in [merchant, farmer]:
		assert_true(_host.economy.request_transfer_goods(market_id, holder, "bread", 2).ok)
	var bought: Dictionary[int, int] = {merchant: 0, farmer: 0}
	for _minute: int in HOURS * SimClock.MINUTES_PER_HOUR:
		_host.runner.step_once()
		for holder: int in [merchant, farmer]:
			bought[holder] += 1 if _host.npc.peek_npc(holder).action_id == "buy" else 0
	assert_eq([bought[merchant], bought[farmer] > 0], [0, true], "O comerciante com pão na mochila nunca começa `buy`; o NPC comum, nas mesmas condições, segue comprando como antes (a correção geral é da LW-094).")
	assert_true(_bread_of(merchant) < 2 and _host.npc.peek_npc(merchant).need_urgencies[0] < NeedMath.URGENCY_CRITICAL, "O comerciante comeu da mochila e a fome saiu do nível crítico.")
	assert_true(_host.economy.peek_conservation().ok and _host.economy.peek_goods_conservation().ok)
