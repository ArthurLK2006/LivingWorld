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
## O índice da fome na lista de necessidades dos dados.
const HUNGER: int = 0
## Quantos minutos esperar o mercado do A encher (com a fome crítica em todos, ele enche em cerca de 8).
const FILL_LIMIT_MIN: int = 120

var _host: SimulationHostNode
var _app: GameAppNode
## A capacidade de `a_market_01` nos dados (a lida do carregador, não um literal).
var _market_capacity: int = 0


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
	assert_eq(_money_reasons(economy), ["contract_escrow", "contract_refund", "game_start", "salary", "trade"] as Array[String], "Todo o dinheiro novo veio de `mint` `game_start` e as únicas movimentações são a compra (`trade`), o salário dos 14 locais de produção dos dados reais (`salary`, LW-095) e, desde a LW-107c3, a custódia do pão do postador (`contract_escrow`) e a devolução dela quando o contrato vence (`contract_refund`): nenhum outro caminho mexe em saldo.")
	assert_true(_food_destroyed(economy) > before, "Comida foi consumida do inventário dos NPCs.")
	assert_true(economy.peek_conservation().ok and economy.peek_goods_conservation().ok)
	assert_eq(economy.validate(), [] as Array[String])
	assert_eq(_host.npc.validate(), [] as Array[String])


## O mesmo jogo real, com os dados de `res://data` carregados como o `GameApp` carrega (a montagem é a de `start_default_game`; só o valor de partida da fome muda, em memória). `everyone_born_critical`: a fome de TODOS nasce crítica;
## senão o mundo nasce com a fome dos dados e quem receber o `NeedDef` devolvido pode fazer nascerem críticos só os NPCs criados DEPOIS (o `start_value` é lido na criação).
func _start_real_game(everyone_born_critical: bool) -> NeedDef:
	var terrain: TerrainLoader.LoadResult = TerrainLoader.load_dir(GameAppNode.TERRAIN_DIR)
	var points: PointOfInterestLoader.LoadResult = PointOfInterestLoader.load_dir(GameAppNode.TERRAIN_DIR, terrain.terrain)
	var loaded: SettlementLoader.LoadResult = SettlementLoader.load_dir(GameAppNode.TERRAIN_DIR, terrain.terrain)
	var npc_setup: NpcSetup = NpcSetup.from_dir(GameAppNode.NPC_DATA_DIR, SettlementService.new(loaded.settlements, loaded.places), true)
	var world_setup: WorldSetup = WorldSetup.from_dir(GameAppNode.TERRAIN_DIR, loaded.settlements, true)
	var economy_setup: EconomySetup = EconomySetup.from_dir(EconomySetup.DEFAULT_DIR, true)
	for result: Result in [terrain.result, points.result, loaded.result, npc_setup.result, world_setup.result, economy_setup.result]:
		assert_true(result.ok, result.message)
	for place: Place in loaded.places:
		if place.id == MARKET_PLACE:
			_market_capacity = place.capacity
	var hunger: NeedDef = npc_setup.need_defs[HUNGER]
	if everyone_born_critical:
		hunger.start_value = CRITICAL_START
	_host.start_new_game(GameAppNode.DEFAULT_WORLD_SEED, terrain.terrain, points.points, npc_setup, GameAppNode.NEW_GAME_START_MINUTE, economy_setup, world_setup)
	return hunger


## Quantos NPCs vivos estão em `MARKET_PLACE` agora (a mesma conta da ocupação do `npc`, só pela porta pública).
func _present_at_market() -> int:
	var present: int = 0
	for npc_id: int in _host.npc.peek_npc_ids():
		var query: NpcModule.NpcQuery = _host.npc.peek_npc(npc_id)
		present += 1 if query.is_alive and query.place_id == MARKET_PLACE else 0
	return present


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


## LW-098h0 no jogo real (dados de `res://data`, 138 NPCs): o comerciante e o lavrador nascem no mesmo mercado com a mesma casa, a fome crítica e 2 pães na mochila, o grão está esgotado (a compra de pão vale mais que a refeição em casa). O comerciante come em vez
## de comprar; o lavrador, que é NPC comum, compra como antes (a regra é só do comerciante).
## LW-098h5, causa raiz do teste antigo: com a fome crítica em TODOS, os NPCs do A convergiam para o único mercado (`a_market_01`, capacidade 8) e o enchiam por volta das 05:53; quem pensava depois não tinha mercado com vaga, `buy` nem era candidata e ele comia o
## pão que carrega (a regra do NPC comum NÃO mudou; o teste dependia do id do lavrador, que fixa o minuto do 1º pensamento). Aqui só os dois nascem críticos (o resto do mundo tem a fome dos dados): o mercado tem vaga para qualquer id; o mercado cheio é o teste seguinte.
func test_the_hungry_merchant_with_bread_in_the_pack_eats_instead_of_buying_while_the_common_npc_still_buys() -> void:
	var hunger: NeedDef = _start_real_game(false)
	for settlement_id: String in SETTLEMENTS:
		assert_true(_host.npc.request_set_food_stock(settlement_id, 0).ok)
	hunger.start_value = CRITICAL_START
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
	assert_true(_bread_of(merchant) < 2 and _host.npc.peek_npc(merchant).need_urgencies[HUNGER] < NeedMath.URGENCY_CRITICAL, "O comerciante comeu da mochila e a fome saiu do nível crítico.")
	assert_true(_host.economy.peek_conservation().ok and _host.economy.peek_goods_conservation().ok)


## LW-098h5: o outro lado do NPC comum. Com a fome crítica em todos, o mercado do A (capacidade lida dos dados) enche; o lavrador que nasce nele já CHEIO, com pão na mochila, dinheiro e pão à venda, não tem mercado com vaga: `buy` não é candidata e ele come o pão que
## carrega (o comportamento esperado do NPC comum; o que o teste antigo via por acaso). O mercado cheio é observado pela porta pública, não é um minuto nem um id.
func test_the_common_npc_born_in_a_full_market_eats_the_bread_in_the_pack_instead_of_buying() -> void:
	_start_real_game(true)
	for settlement_id: String in SETTLEMENTS:
		assert_true(_host.npc.request_set_food_stock(settlement_id, 0).ok)
	var waited: int = 0
	while _present_at_market() < _market_capacity and waited < FILL_LIMIT_MIN:
		_host.runner.step_once()
		waited += 1
	assert_gte(_present_at_market(), _market_capacity, "Sanidade: com a fome crítica em todos, o mercado do A enche.")
	var farmer: int = _create_in_market("farmer", WORK_PLACE)
	var market_id: int = _host.economy.peek_market_of(SETTLEMENTS[0]).market_id
	assert_true(_host.economy.request_set_stock(market_id, "grain", 0).ok)
	assert_true(_host.economy.request_transfer_goods(market_id, farmer, "bread", 2).ok)
	assert_true(_host.economy.peek_quote(farmer, market_id, "bread", 1, "buy").result.ok, "Sanidade: há pão à venda e o lavrador paga; só falta vaga no mercado.")
	var bought: int = 0
	for _minute: int in HOURS * SimClock.MINUTES_PER_HOUR:
		if _host.npc.peek_npc(farmer).action_id.is_empty():
			assert_gte(_present_at_market() - 1, _market_capacity, "O mercado segue cheio (sem contar o lavrador) até o 1º pensamento dele.")
		_host.runner.step_once()
		bought += 1 if _host.npc.peek_npc(farmer).action_id == "buy" else 0
	assert_eq(bought, 0, "Sem mercado com vaga o lavrador nunca começa `buy`.")
	assert_true(_bread_of(farmer) < 2 and _host.npc.peek_npc(farmer).need_urgencies[HUNGER] < NeedMath.URGENCY_CRITICAL, "Come o pão da mochila e a fome sai do nível crítico.")
	assert_true(_host.economy.peek_conservation().ok and _host.economy.peek_goods_conservation().ok)
