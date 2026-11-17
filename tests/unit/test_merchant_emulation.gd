extends GutTest
## LW-098h0a: a EMULAÇÃO de comerciantes (tests/soak/merchant_emulation/merchant_emulation.gd), na versão CURTA do check_all: 3 comerciantes, 1 dia, semente 1 (a longa é o corredor tests/soak/run_merchant_emulation). O jogo é o REAL montado como o
## `GameApp` monta (dados de `res://data`). Cobre: os 3 comerciantes nascem como os dados descrevem (povoado, mercado, casa, ofício, saldo), a agenda roda (com a Q7 eles fazem viagens e chegam), todos vivos e as conservações conferidas no dia;
## a mesma semente dá o mesmo `state_hash` e outra semente dá outro; a Q7 muda os estoques iniciais e os preços e a `none` não muda nada (sem comerciante e sem Q7 o mundo tem o MESMO hash da partida padrão, também depois de 1 hora);
## a contabilidade por comerciante (morte, fome, chegadas) e as estatísticas do passo, com números exatos; o resumo imprime os campos pedidos.

const SEED: int = 1
const MERCHANTS: int = 3
const MARKETS: Array[String] = ["a_market_01", "b_market_01", "c_market_01"]
const MERCHANT_BALANCE: int = 300
## A diferença Q7 que o teste espera, na ordem A, B, C (uma cópia independente da tabela do ajudante).
const Q7_STOCKS: Dictionary[String, Array] = {"bread": [90, 30, 60], "wool": [20, 40, 10], "wood": [30, 10, 50]}
const BREAD: String = "bread"
## Um passo de verdade (um mundo de 130 NPCs) custa bem mais que isto; um relógio ao redor do NADA mede 0 ou 1 microssegundo.
const REAL_STEP_FLOOR_USEC: int = 10
const ONE_HOUR: int = 60

var _first: MerchantEmulation
var _report: MerchantEmulation.Report
var _to_finish: Array[MerchantEmulation] = []
## Chegadas e lucro por comerciante, contados aqui direto dos eventos (uma conta independente da do ajudante): [chegadas, lucro].
var _tally: Dictionary[int, Array] = {}


func before_all() -> void:
	_first = _start(SEED, MerchantEmulation.SPREAD_Q7, MERCHANTS)
	_to_finish.erase(_first)
	_first.runner.world.context.events.subscribe(MerchantEmulation.ARRIVED_EVENT, _on_arrived)
	_report = _first.run(1)


func _on_arrived(event: SimEvent) -> void:
	var arrived: CaravanArrived = event as CaravanArrived
	var entry: Array = _tally.get(arrived.trader_id, [0, 0])
	_tally[arrived.trader_id] = [entry[0] + 1, entry[1] + arrived.revenue - arrived.cost_paid]


func after_each() -> void:
	for emulation: MerchantEmulation in _to_finish:
		emulation.finish()
	_to_finish.clear()


func after_all() -> void:
	_first.finish()


func _start(world_seed: int, spread: String, merchants: int) -> MerchantEmulation:
	var emulation: MerchantEmulation = MerchantEmulation.new()
	assert_eq(emulation.start(world_seed, spread), "", "O jogo real monta.")
	var before: int = emulation.npc.peek_npc_ids().size()
	assert_eq(emulation.create_merchants(merchants), "", "Os comerciantes nascem.")
	assert_eq(emulation.npc.peek_npc_ids().size(), before + merchants, "Nem a mais nem a menos.")
	_to_finish.append(emulation)
	return emulation


func _stock(emulation: MerchantEmulation, settlement: String, good: String) -> int:
	return emulation.economy.peek_stock(emulation.economy.peek_market_of(settlement).market_id, good).value


func _price(emulation: MerchantEmulation, settlement: String, good: String) -> int:
	return emulation.economy.peek_price(emulation.economy.peek_market_of(settlement).market_id, good).value


## Uma resposta de `peek_npc` montada à mão: fome no índice 0, a urgência dada e vivo ou morto.
func _query(is_alive: bool, hunger: int, urgency: int, cause: String = "") -> NpcModule.NpcQuery:
	var state: NpcState = NpcState.new(7)
	state.is_alive = is_alive
	state.death_cause = cause
	state.need_values = PackedInt64Array([hunger, 0, 0, 0, 0])
	var query: NpcModule.NpcQuery = NpcModule.NpcQuery.new(Result.success(), state)
	query.need_urgencies = PackedInt64Array([urgency, 0, 0, 0, 0])
	return query


func test_the_merchants_are_born_in_the_market_of_each_settlement_as_the_data_describes() -> void:
	var emulation: MerchantEmulation = _start(SEED, MerchantEmulation.SPREAD_NONE, MERCHANTS)
	var seen: Dictionary[int, bool] = {}
	for index: int in MERCHANTS:
		var row: MerchantEmulation.Row = emulation.rows[index]
		var query: NpcModule.NpcQuery = emulation.npc.peek_npc(row.npc_id)
		seen[row.npc_id] = true
		assert_eq([query.settlement_id, query.place_id, query.work_place_id, query.occupation_id], [emulation.settlements[index], MARKETS[index], MARKETS[index], MerchantEmulation.OCCUPATION], "Um por povoado, em ordem, no mercado e com o ofício merchant.")
		var home: Place = emulation.places.peek_place(query.home_place_id).place
		assert_eq([home.kind, home.settlement_id], [Place.KIND_HOME, query.settlement_id], "A casa JÁ existia: um local de moradia do mesmo povoado.")
		assert_eq(emulation.economy.peek_balance(row.npc_id).balance, MERCHANT_BALANCE, "O saldo é o do tipo de dono merchant.")
	assert_eq(seen.size(), MERCHANTS, "IDs distintos.")
	assert_eq(emulation.npc.peek_routine_action(MerchantEmulation.OCCUPATION, 8).action_id, "haul", "A agenda real do comerciante é `haul` nas horas de trabalho.")


func test_a_day_with_the_q7_runs_the_agenda_keeps_everyone_alive_and_checks_the_conservation() -> void:
	assert_eq(_report.alive_count(), MERCHANTS, "Os 3 vivos.")
	assert_gt(_report.arrivals(), 0, "Com a Q7 há comércio: a agenda `haul` roda e as viagens terminam no dia.")
	assert_eq([_report.checks, _report.money_ok, _report.goods_ok, _report.validate_problems], [1, true, true, 0], "Conservação de dinheiro e de bens conferida no fim do dia, e `validate` vazio.")
	assert_true(_report.is_sound())
	var now: int = _first.runner.world.context.clock.total_minutes()
	for row: MerchantEmulation.Row in _first.rows:
		var query: NpcModule.NpcQuery = _first.npc.peek_npc(row.npc_id)
		assert_gt(query.action_serial, 1, "Pensou e agiu ao longo do dia.")
		assert_eq([row.arrivals, row.profit], _tally.get(row.npc_id, [0, 0]), "As chegadas e o lucro de cada comerciante batem com os eventos.")
		assert_gte(query.next_think_time, now, "O próximo pensamento está no futuro: não ficou parado.")


func test_the_same_seed_gives_the_same_hash_and_another_seed_another() -> void:
	var again: MerchantEmulation = _start(SEED, MerchantEmulation.SPREAD_Q7, MERCHANTS)
	var second: MerchantEmulation.Report = again.run(1)
	assert_eq(second.state_hash, _report.state_hash, "Mesma semente, mesmo hash depois de 1 dia.")
	assert_eq(second.rows.map(func(row: MerchantEmulation.Row) -> String: return row.describe()), _report.rows.map(func(row: MerchantEmulation.Row) -> String: return row.describe()), "E a mesma contabilidade por comerciante.")
	var other: MerchantEmulation = _start(2, MerchantEmulation.SPREAD_Q7, MERCHANTS)
	assert_ne(other.run(1).state_hash, _report.state_hash, "Outra semente, outro mundo (o hash do fim do dia 1, tomado dentro do `run`).")


func test_the_q7_changes_the_initial_stocks_and_prices_and_none_changes_nothing() -> void:
	var plain: MerchantEmulation = _start(SEED, MerchantEmulation.SPREAD_NONE, 0)
	var q7: MerchantEmulation = _start(SEED, MerchantEmulation.SPREAD_Q7, 0)
	var data: Array[MarketTargetDef] = EconomySetup.from_dir(EconomySetup.DEFAULT_DIR).definitions.market_targets
	for target: MarketTargetDef in data:
		var expected_q7: int = target.initial_stock
		if Q7_STOCKS.has(target.good_id):
			expected_q7 = Q7_STOCKS[target.good_id][plain.settlements.find(target.settlement_id)]
		assert_eq(_stock(plain, target.settlement_id, target.good_id), target.initial_stock, "`none`: o estoque inicial é o dos dados (%s, %s)." % [target.settlement_id, target.good_id])
		assert_eq(_stock(q7, target.settlement_id, target.good_id), expected_q7, "`q7`: pão, lã e madeira rotacionados; o resto como nos dados (%s, %s)." % [target.settlement_id, target.good_id])
	var plain_prices: Array = plain.settlements.map(func(settlement: String) -> int: return _price(plain, settlement, BREAD))
	var q7_prices: Array = q7.settlements.map(func(settlement: String) -> int: return _price(q7, settlement, BREAD))
	assert_eq(plain_prices.count(plain_prices[0]), plain_prices.size(), "Sem a Q7 o pão custa o mesmo nos três mercados.")
	assert_eq(q7_prices.size(), 3, "A Q7 tem um preço por mercado.")
	assert_true(q7_prices[0] < q7_prices[1] and q7_prices[1] < q7_prices[2], "Com a Q7 o pão é barato no A (muito estoque) e caro no C (pouco): a diferença de preço existe desde o dia 0.")


func test_without_merchants_and_without_spread_the_world_is_the_default_game() -> void:
	var host: SimulationHostNode = SimulationHostNode.new()
	var app: GameAppNode = GameAppNode.new()
	app.bind_host(host)
	app.start_default_game(host)
	var plain: MerchantEmulation = _start(SEED, MerchantEmulation.SPREAD_NONE, 0)
	assert_eq(plain.runner.world.state_hash(), host.runner.world.state_hash(), "Mesmo mundo no começo.")
	host.runner.run_steps(ONE_HOUR)
	plain.runner.run_steps(ONE_HOUR)
	assert_eq(plain.runner.world.state_hash(), host.runner.world.state_hash(), "E depois de 1 hora de jogo.")
	assert_ne(_start(SEED, MerchantEmulation.SPREAD_Q7, 0).runner.world.state_hash(), host.runner.world.state_hash(), "A Q7 muda o mundo.")
	host.runner.finish()
	host.free()
	app.free()


func test_the_row_follows_the_hunger_and_counts_a_death_once() -> void:
	var row: MerchantEmulation.Row = MerchantEmulation.Row.new(7, "s")
	row.observe(_query(true, 40, NeedMath.URGENCY_ATTENTION), 0, 10)
	for minute: int in 6:
		row.observe(_query(true, 90 + minute, NeedMath.URGENCY_CRITICAL), 0, 11 + minute)
	assert_eq([row.hunger_max, row.critical_minutes, row.alive, row.death_minute], [95, 6, true, -1], "Fome máxima, minutos críticos e ainda vivo.")
	row.observe(_query(false, 100, NeedMath.URGENCY_CRITICAL, "hunger"), 0, 13042)
	row.observe(_query(false, 100, NeedMath.URGENCY_CRITICAL, "hunger"), 0, 14000)
	assert_eq([row.alive, row.death_minute, row.death_cause, row.hunger_max, row.critical_minutes], [false, 13042, "hunger", 95, 6], "A morte vale uma vez, no minuto visto, e o morto não conta mais fome.")
	assert_eq(row.describe(), "MERCHANT id=7 settlement=s alive=false death=d9_01:22 cause=hunger hunger_max=95 critical_hours=0.1 arrivals=0 profit=0", "O dia e a hora da morte saem como no diagnóstico (d9_01:22).")
	var report: MerchantEmulation.Report = MerchantEmulation.Report.new()
	report.rows.append(row)
	assert_eq(report.alive_count(), 0, "Morto não conta como vivo no relatório.")
	assert_string_contains(report.summary(), "alive_merchants=0/1")


func test_a_failed_conservation_check_fails_the_report_and_a_good_day_does_not_erase_it() -> void:
	var good_money: EconomyReplies.ConservationQuery = EconomyReplies.ConservationQuery.new(100, 100, 0)
	var bad_money: EconomyReplies.ConservationQuery = EconomyReplies.ConservationQuery.new(101, 100, 0)
	var good_goods: EconomyReplies.GoodsConservationQuery = EconomyReplies.GoodsConservationQuery.new([{"good_id": BREAD, "in_stock": 5, "created": 5, "destroyed": 0, "ok": true}])
	var bad_goods: EconomyReplies.GoodsConservationQuery = EconomyReplies.GoodsConservationQuery.new([{"good_id": BREAD, "in_stock": 6, "created": 5, "destroyed": 0, "ok": false}])
	var report: MerchantEmulation.Report = MerchantEmulation.Report.new()
	report.record_day_check(good_money, good_goods)
	assert_eq([report.checks, report.money_ok, report.goods_ok, report.is_sound()], [1, true, true, true], "Dia bom: o relatório segue sólido.")
	report.record_day_check(bad_money, good_goods)
	report.record_day_check(good_money, good_goods)
	assert_eq([report.checks, report.money_ok, report.goods_ok, report.is_sound()], [3, false, true, false], "O dinheiro que não fechou num dia reprova, e o dia bom seguinte não apaga.")
	var other: MerchantEmulation.Report = MerchantEmulation.Report.new()
	other.record_day_check(good_money, bad_goods)
	other.record_day_check(good_money, good_goods)
	assert_eq([other.checks, other.money_ok, other.goods_ok, other.is_sound()], [2, true, false, false], "Os bens que não fecharam num dia reprovam, e o dia bom seguinte não apaga.")


func test_the_step_statistics_are_exact_on_known_series() -> void:
	var report: MerchantEmulation.Report = MerchantEmulation.Report.new()
	for milliseconds: int in range(100, 0, -1):
		report.steps_usec.append(milliseconds * 1000)
	assert_eq([report.percentile_usec(0.5), report.percentile_usec(0.95), report.percentile_usec(0.99), report.percentile_usec(1.0), report.total_usec()], [50000, 95000, 99000, 100000, 5050000], "Mediana, p95, p99, máximo e soma, pelo posto mais próximo.")
	report.steps_usec = PackedInt64Array([MerchantEmulation.FRAME_USEC, MerchantEmulation.FRAME_USEC + 1, MerchantEmulation.PEAK_USEC, MerchantEmulation.PEAK_USEC + 1, 5])
	assert_eq([report.steps_over(MerchantEmulation.FRAME_USEC), report.steps_over(MerchantEmulation.PEAK_USEC)], [3, 1], "Só conta o que passa do limite (o igual não conta).")


func test_the_step_is_timed_around_the_whole_step_and_the_summary_prints_the_requested_fields() -> void:
	assert_eq(_report.steps_usec.size(), SimClock.MINUTES_PER_DAY, "Um custo por passo de 1 minuto.")
	assert_gt(_report.percentile_usec(0.5), REAL_STEP_FLOOR_USEC, "O relógio cobre o passo de verdade.")
	var text: String = _report.summary()
	for field: String in ["alive_merchants=3/3", "MERCHANT id=", "alive=true", "death=-", "hunger_max=", "critical_hours=", "arrivals=", "profit=", "money_conserved=true", "goods_conserved=true", "conservation_checks=1", "validate_problems=0", "state_hash=", "STEPS n=1440", "total_s=", "median_ms=", "p95_ms=", "p99_ms=", "max_ms=", "over_16_7ms=", "over_33ms="]:
		assert_string_contains(text, field)


func test_the_entry_point_refuses_bad_arguments_and_runs_the_emulation() -> void:
	var node: Node = load("res://tests/soak/merchant_emulation/merchant_emulation_main.tscn").instantiate()
	assert_eq(node.call("_run", PackedStringArray(["--merchants", "x"])), 2, "Argumento inválido: código 2, sem montar o jogo.")
	assert_eq(node.call("_run", PackedStringArray(["--merchants", "1", "--days", "0", "--spread", "foo"])), 1, "Spread inválido: o jogo não monta (código 1).")
	assert_eq(node.call("_run", PackedStringArray(["--merchants", "1", "--days", "0"])), 0, "Argumentos válidos: monta, roda e sai com 0.")
	node.free()
