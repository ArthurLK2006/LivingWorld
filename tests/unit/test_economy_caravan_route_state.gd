extends GutTest
## LW-098e: a PARADA, a RETOMADA e o DESVIO da caravana por `RouteStateChanged` (docs/modules/economy.md, 9.3, 9.4, 9.7 e 9.8), com a economia REAL (data/economy, 3 povoados) e o `world` REAL (A-B 520 m, A-C 430 m e B-C 340 m: 143, 124 e 96 minutos por trecho), dentro do `SimulationRunner` (a ordem de cada
## passo do host: relógio, módulos no `tick`, entrega dos eventos). O comerciante leva pão do A ao B. O fechamento e a reabertura saem do `request_close_route` e do `request_open_route` do `world` e o evento é entregue NA HORA (`dispatch` sem passo: o relógio fica onde está e os minutos parados saem da mão). Só os testes
## de chegada e fechamento no mesmo passo usam um módulo "fechador" (depois da economia, como o `npc`) que pede o fechamento DENTRO do `tick`.

const SEED: int = 98
const WORLD_DIR: String = "res://data/world"
const TRADER: int = 100
const OTHER: int = 101
const START_MINUTE: int = 1000
const LOT: int = 12
const SETTLEMENT_A: String = "test_settlement_a"
const SETTLEMENT_B: String = "test_settlement_b"
const SETTLEMENT_C: String = "test_settlement_c"
const A_B: String = "route_a_b"
const A_C: String = "route_a_c"
const B_C: String = "route_b_c"

var _routes: RouteService
var _rigs: Array[Rig] = []


## Faz o papel de quem fecha a rota no passo (o `military` depois, ou o comando de desenvolvimento): no minuto `at_minute` pede o fechamento de `route_id` DENTRO do `tick`. Registrado depois da economia, como o `npc` no jogo.
class Closer:
	extends SimModule

	var world: WorldModule
	var route_id: String = ""
	var at_minute: int = -1
	var _context: SimContext

	func setup(ctx: SimContext) -> void:
		_context = ctx

	func tick(_elapsed_minutes: int) -> void:
		if _context.clock.total_minutes() == at_minute:
			world.request_close_route(route_id)


class Rig:
	extends RefCounted

	var runner: SimulationRunner
	var module: EconomyModule
	var routes: WorldModule
	var closer: Closer
	var arrivals: Array[CaravanArrived] = []
	var market_a: int
	var market_b: int


func before_all() -> void:
	var terrain: TerrainLoader.LoadResult = TerrainLoader.load_dir(WORLD_DIR)
	var settlements: SettlementLoader.LoadResult = SettlementLoader.load_dir(WORLD_DIR, terrain.terrain)
	var loaded: RouteLoader.LoadResult = RouteLoader.load_dir(WORLD_DIR, settlements.settlements)
	assert_true(loaded.result.ok, loaded.result.message)
	_routes = RouteService.new(loaded.routes, settlements.settlements)


## Encerra os mundos do teste: os ouvintes do `EventBus` seguram o `Rig` e o `Rig` segura o mundo (sem isto o motor acusa vazamento ao sair).
func after_each() -> void:
	for rig: Rig in _rigs:
		rig.runner.finish()
	_rigs.clear()


## Os módulos na ordem do jogo (`world`, `economy` e o fechador), SEM iniciar o mundo: serve ao jogo novo (`_rig`) e ao carregado (`_reloaded`).
func _build() -> Rig:
	var rig: Rig = Rig.new()
	var setup: EconomySetup = EconomySetup.from_dir(EconomySetup.DEFAULT_DIR, true)
	assert_true(setup.result.ok, setup.result.message)
	setup.definitions.caravan_params = CaravanParamsLoader.load_dir(EconomySetup.DEFAULT_DIR).params
	rig.routes = WorldModule.new(_routes, true)
	rig.module = EconomyModule.new(false, setup.definitions, rig.routes)
	rig.closer = Closer.new()
	rig.closer.world = rig.routes
	rig.runner = SimulationRunner.new(SEED, START_MINUTE)
	for entry: Array in [["world", rig.routes], ["economy", rig.module], ["closer", rig.closer]]:
		assert_true(rig.runner.register_module(entry[0], entry[1]).ok)
	_rigs.append(rig)
	return rig


## O jogo no minuto 1000 com dois comerciantes (peso 120, saldo 300) e as quantidades dos dados nos mercados (pão: A 60, B 40 e C 200), a economia conferida a cada `cadence` minutos (o agendador).
func _rig(cadence: int = 1) -> Rig:
	var rig: Rig = _build()
	rig.runner.start_new_game(func(scheduler: Scheduler) -> void: assert_true(scheduler.configure_module("economy", cadence).ok))
	rig.runner.world.context.events.subscribe("CaravanArrived", func(event: SimEvent) -> void: rig.arrivals.append(event))
	rig.market_a = rig.module.peek_market_of(SETTLEMENT_A).market_id
	rig.market_b = rig.module.peek_market_of(SETTLEMENT_B).market_id
	for trader_id: int in [TRADER, OTHER]:
		assert_true(rig.module.request_open_owner(trader_id, EconomyModule.KIND_MERCHANT).ok)
	return rig


## Salva o jogo do `rig`, passa pelo JSON e carrega num mundo novo com os mesmos módulos.
func _reloaded(rig: Rig) -> Rig:
	var copy: Rig = _build()
	# Variant: o JSON devolve qualquer tipo; aqui o formato é conhecido (o save do jogo, um objeto).
	var payload: Variant = JSON.parse_string(JSON.stringify(rig.runner.capture_game()))
	var loaded: Result = copy.runner.load_game(payload as Dictionary)
	assert_true(loaded.ok, loaded.message)
	return copy


## Roda passos de 1 minuto (relógio, módulos, entrega dos eventos) até o relógio chegar a `minute`.
func _until(rig: Rig, minute: int) -> void:
	rig.runner.run_steps(minute - rig.runner.world.context.clock.total_minutes())


func _depart(rig: Rig, trader_id: int = TRADER) -> CaravanReplies.StartResult:
	var started: CaravanReplies.StartResult = rig.module.request_start_caravan(trader_id, rig.market_a, rig.market_b, "bread", LOT)
	assert_true(started.result.ok, started.result.message)
	return started


## Abre ou fecha a rota no `world` e entrega o `RouteStateChanged` agora, no minuto em que o relógio está.
func _set_route(rig: Rig, route_id: String, is_open: bool) -> void:
	var asked: Result = rig.routes.request_open_route(route_id) if is_open else rig.routes.request_close_route(route_id)
	assert_true(asked.ok, asked.message)
	rig.runner.world.context.events.dispatch()


## O registro salvo da caravana (para ler `elapsed_at_hold`, `leg_started_at`, `leg_minutes`: a resposta de `peek_caravan` não os traz).
func _record(rig: Rig, trader_id: int = TRADER) -> Dictionary:
	var records: Array = rig.module.serialize().get("caravans", [])
	for record: Dictionary in records:
		if record["trader_id"] == trader_id:
			return record
	return {}


func _bytes(rig: Rig) -> String:
	return JSON.stringify(rig.module.serialize(), "", true, true)


func _conserved(rig: Rig) -> bool:
	return rig.module.peek_conservation().ok and rig.module.peek_goods_conservation().ok


## O comerciante parte do A ao B com a A-B FECHADA (o caminho é A-C e C-B, 220 minutos) e, no minuto 60 do trecho A-C, a B-C fecha (rota de um trecho FUTURO: a caravana não muda) e, com `reopen_a_b`, a A-B reabre (rota já fora do caminho: também não muda).
func _on_the_way_to_c(rig: Rig, reopen_a_b: bool) -> CaravanReplies.StartResult:
	_set_route(rig, A_B, false)
	var started: CaravanReplies.StartResult = _depart(rig)
	assert_eq(started.eta_minute, START_MINUTE + 124 + 96, "Com a A-B fechada o caminho é A-C (124) e C-B (96).")
	_until(rig, START_MINUTE + 60)
	var before: String = _bytes(rig)
	_set_route(rig, B_C, false)
	if reopen_a_b:
		_set_route(rig, A_B, true)
	assert_eq(_bytes(rig), before, "Rota de trecho futuro ou fora do caminho que fecha ou reabre não muda a caravana (o desvio é no fim do trecho).")
	return started


func test_closing_the_route_under_the_caravan_holds_it_in_the_middle_of_the_road_and_it_waits() -> void:
	var rig: Rig = _rig()
	var started: CaravanReplies.StartResult = _depart(rig)
	_until(rig, START_MINUTE + 50)
	var sum: int = rig.module.peek_conservation().sum
	_set_route(rig, A_C, false)
	_set_route(rig, A_C, true)
	assert_eq(rig.module.peek_caravan(TRADER).state, "travelling", "Outra rota que fecha e reabre não a mexe.")
	_set_route(rig, A_B, false)
	var held: CaravanReplies.CaravanQuery = rig.module.peek_caravan(TRADER)
	assert_eq([held.state, _record(rig)["elapsed_at_hold"], held.progress_m, held.eta_minute, held.current_route_id, held.leg_from_settlement_id, held.leg_to_settlement_id], ["held", 50, 181, 0, A_B, SETTLEMENT_A, SETTLEMENT_B], "Parou no minuto 50 do trecho: 50 minutos andados, 181 m (floor de 520 × 50 / 143), sem ETA.")
	assert_eq(rig.module.peek_caravans_on(A_B).caravans.size(), 1, "Parada no meio da estrada ainda está na estrada.")
	_set_route(rig, A_C, false)
	_set_route(rig, A_C, true)
	_until(rig, started.eta_minute + 600)
	held = rig.module.peek_caravan(TRADER)
	assert_eq([held.state, held.route_ids, _record(rig)["elapsed_at_hold"], rig.arrivals.size()], ["held", [A_B] as Array[String], 50, 0], "No meio da estrada ela não volta, não desvia (o A-C-B está aberto) e não chega: espera a A-B reabrir, e outra rota que reabre não a retoma.")
	assert_eq([rig.module.peek_inventory(TRADER).weight, rig.module.peek_balance(TRADER).balance, rig.module.peek_conservation().sum, _conserved(rig), rig.module.validate()], [LOT, 300 - started.cost_paid, sum, true, [] as Array[String]], "Sem perder carga nem dinheiro: nenhuma venda e as duas conservações fecham.")


func test_reopening_the_route_resumes_with_the_eta_shifted_by_the_time_parked() -> void:
	for parked: int in [1, 7, 60, 300]:
		var rig: Rig = _rig()
		var started: CaravanReplies.StartResult = _depart(rig)
		_until(rig, START_MINUTE + 50)
		_set_route(rig, A_B, false)
		_until(rig, START_MINUTE + 50 + parked)
		_set_route(rig, A_B, true)
		var resumed: CaravanReplies.CaravanQuery = rig.module.peek_caravan(TRADER)
		assert_eq([resumed.state, _record(rig)["elapsed_at_hold"], resumed.progress_m, resumed.eta_minute, rig.module.peek_caravans_on(A_B).caravans.size()], ["travelling", 0, 181, started.eta_minute + parked, 1], "Parada %d minutos: volta a andar do mesmo ponto, segue na estrada e o ETA é o original mais o tempo parado." % parked)
		_until(rig, started.eta_minute + parked - 1)
		assert_eq(rig.arrivals.size(), 0, "Um minuto antes do ETA novo ainda viaja.")
		_until(rig, started.eta_minute + parked)
		assert_eq([rig.arrivals.size(), rig.arrivals[0].time, rig.arrivals[0].revenue > 0, _conserved(rig)], [1, started.eta_minute + parked, true, true], "Parada %d minutos: chega no ETA deslocado e vende." % parked)


func test_at_a_settlement_with_the_next_route_closed_the_caravan_detours_with_the_route_ids_rewritten() -> void:
	var outcomes: Array = []
	for cadence: int in [1, 7, 60]:
		var rig: Rig = _rig(cadence)
		_on_the_way_to_c(rig, true)
		_until(rig, START_MINUTE + 124 + cadence)
		var detour: CaravanReplies.CaravanQuery = rig.module.peek_caravan(TRADER)
		var record: Dictionary = _record(rig)
		assert_eq([detour.state, detour.route_ids, detour.leg_index, record["leg_started_at"], record["leg_minutes"], detour.leg_from_settlement_id, detour.leg_to_settlement_id, detour.eta_minute], ["travelling", [A_C, A_C, A_B] as Array[String], 1, START_MINUTE + 124, 124, SETTLEMENT_C, SETTLEMENT_A, START_MINUTE + 124 + 124 + 143], "Passo de %d minutos: no povoado C a B-C está fechada e o caminho novo é C-A e A-B; `route_ids` guarda a rota já andada e o caminho novo, o trecho novo começa no minuto exato do fim do anterior." % cadence)
		_until(rig, START_MINUTE + 500)
		assert_eq([rig.arrivals.size(), rig.arrivals[0].route_id, rig.arrivals[0].destination_id, rig.arrivals[0].revenue > 0, _conserved(rig), rig.module.validate()], [1, A_B, SETTLEMENT_B, true, true, [] as Array[String]], "Passo de %d minutos: chega ao B pelo caminho novo e vende." % cadence)
		outcomes.append([rig.arrivals[0].revenue, rig.runner.world.state_hash()])
	assert_eq([outcomes[1], outcomes[2]], [outcomes[0], outcomes[0]], "Passos de 1, 7 e 60 minutos: o mesmo resultado e o mesmo hash do estado.")


func test_without_a_path_the_caravan_holds_at_the_settlement_and_resumes_when_a_route_gives_it_a_path() -> void:
	var rig: Rig = _rig()
	var started: CaravanReplies.StartResult = _on_the_way_to_c(rig, false)
	_until(rig, START_MINUTE + 124)
	var parked: CaravanReplies.CaravanQuery = rig.module.peek_caravan(TRADER)
	var record: Dictionary = _record(rig)
	assert_eq([parked.state, record["elapsed_at_hold"], parked.leg_index, parked.route_ids, record["leg_started_at"], record["leg_minutes"]], ["held", 0, 1, [A_C, B_C] as Array[String], START_MINUTE + 124, 96], "A-B e B-C fechadas: sem caminho do C ao B, fica `held` no C, com o `leg_index` no trecho que ainda não andou (o bloqueado).")
	assert_eq([parked.leg_from_settlement_id, parked.leg_to_settlement_id, parked.leg_length_m, parked.progress_m, parked.eta_minute, parked.current_route_id], [SETTLEMENT_C, SETTLEMENT_B, 340, 0, 0, B_C], "Parada num povoado: a derivação dá o povoado da parada, 0 m andados e nenhum ETA.")
	assert_eq([rig.module.peek_caravans_on(A_C).caravans.size(), rig.module.peek_caravans_on(B_C).caravans.size()], [0, 0], "Parada num povoado não está na estrada.")
	assert_eq([rig.module.peek_inventory(TRADER).weight, rig.module.peek_balance(TRADER).balance, _conserved(rig), rig.module.validate()], [LOT, 300 - started.cost_paid, true, [] as Array[String]], "Sem perder carga nem dinheiro.")
	_until(rig, START_MINUTE + 154)
	_set_route(rig, A_C, false)
	_set_route(rig, A_C, true)
	assert_eq(_record(rig), record, "A rota que reabre não dá caminho (a A-B segue fechada): continua `held`, igual.")
	_set_route(rig, A_B, true)
	var resumed: CaravanReplies.CaravanQuery = rig.module.peek_caravan(TRADER)
	record = _record(rig)
	assert_eq([resumed.state, resumed.route_ids, resumed.leg_index, record["leg_started_at"], record["leg_minutes"], resumed.eta_minute], ["travelling", [A_C, A_C, A_B] as Array[String], 1, START_MINUTE + 154, 124, START_MINUTE + 154 + 124 + 143], "A A-B reabriu: o caminho C-A, A-B aparece, `route_ids` é reescrito e o trecho novo começa agora (o ETA se desloca pelo tempo parado).")
	_until(rig, START_MINUTE + 154 + 124 + 143)
	assert_eq([rig.arrivals.size(), rig.arrivals[0].route_id], [1, A_B], "Chegou ao B pelo caminho novo, no ETA que partiu da reabertura.")


func test_an_unknown_route_a_bad_new_state_and_a_caravan_that_is_not_there_change_nothing() -> void:
	var rig: Rig = _rig()
	var events: EventBus = rig.runner.world.context.events
	for fake: Array in [[A_B, "closed"], ["route_x", "closed"], ["route_x", "open"], [A_B, "blocked"]]:
		events.publish(RouteStateChanged.new(fake[0], fake[1]))
	events.dispatch()
	assert_eq(rig.module.serialize().has("caravans"), false, "Sem caravana no livro: o evento sai logo e nada nasce.")
	_on_the_way_to_c(rig, false)
	_until(rig, START_MINUTE + 124)
	var before: String = _bytes(rig)
	rig.module.teardown()
	_set_route(rig, A_B, true)
	rig.module.post_setup()
	for fake: Array in [["route_x", "open"], [A_B, "blocked"], [A_B, ""], ["route_x", "closed"]]:
		events.publish(RouteStateChanged.new(fake[0], fake[1]))
	events.dispatch()
	assert_eq(_bytes(rig), before, "A economia não ouviu a A-B reabrir: com caminho aberto, rota desconhecida e estado que não é `open` nem `closed` não retomam a parada (nem quebram nada).")
	events.publish(RouteStateChanged.new(A_B, "open"))
	events.dispatch()
	assert_eq(rig.module.peek_caravan(TRADER).state, "travelling", "Controle: o evento verdadeiro retoma.")


func test_closing_and_reopening_in_the_same_step_or_reopening_what_never_closed_change_nothing() -> void:
	var rig: Rig = _rig()
	_depart(rig)
	_until(rig, START_MINUTE + 50)
	var before: String = _bytes(rig)
	assert_true(rig.routes.request_close_route(A_B).ok and rig.routes.request_open_route(A_B).ok)
	rig.runner.world.context.events.dispatch()
	assert_eq(_bytes(rig), before, "Fechou e reabriu no mesmo passo: parou e voltou no mesmo minuto, o registro é o mesmo.")
	rig.runner.world.context.events.publish(RouteStateChanged.new(A_C, "open"))
	rig.runner.world.context.events.dispatch()
	assert_eq(_bytes(rig), before, "Reabrir uma rota que nunca fechou: nada muda.")


func test_two_caravans_on_the_same_route_both_stop_and_both_resume_in_trader_id_order() -> void:
	var rig: Rig = _rig()
	var first: CaravanReplies.StartResult = _depart(rig)
	_until(rig, START_MINUTE + 10)
	var second: CaravanReplies.StartResult = _depart(rig, OTHER)
	_until(rig, START_MINUTE + 50)
	_set_route(rig, A_B, false)
	assert_eq([rig.module.peek_caravans_on(A_B).caravans.map(func(row: CaravanReplies.CaravanQuery) -> int: return row.trader_id), _record(rig, TRADER)["elapsed_at_hold"], _record(rig, OTHER)["elapsed_at_hold"]], [[TRADER, OTHER], 50, 40], "As duas param, por `trader_id`, cada uma com os minutos que andou.")
	_until(rig, START_MINUTE + 80)
	_set_route(rig, A_B, true)
	assert_eq([rig.module.peek_caravan(TRADER).eta_minute, rig.module.peek_caravan(OTHER).eta_minute], [first.eta_minute + 30, second.eta_minute + 30], "As duas retomam, cada uma com o ETA mais os 30 minutos parados.")
	_until(rig, second.eta_minute + 30)
	assert_eq([rig.arrivals.map(func(arrived: CaravanArrived) -> int: return arrived.trader_id), rig.arrivals.map(func(arrived: CaravanArrived) -> int: return arrived.time), _conserved(rig)], [[TRADER, OTHER], [first.eta_minute + 30, second.eta_minute + 30], true], "Chegam nos ETAs novos, uma e depois a outra.")


func test_the_arrival_of_the_step_comes_before_the_closing_requested_in_the_same_step() -> void:
	var rig: Rig = _rig()
	var started: CaravanReplies.StartResult = _depart(rig)
	var order: Array[String] = []
	for event_type: String in ["CaravanArrived", "RouteStateChanged"]:
		rig.runner.world.context.events.subscribe(event_type, func(event: SimEvent) -> void: order.append("%s, caravana no livro: %s" % [event.type, rig.module.peek_caravan(TRADER).found]))
	var expected: int = rig.module.peek_quote(TRADER, rig.market_b, "bread", LOT, "sell").total
	rig.closer.route_id = A_B
	rig.closer.at_minute = started.eta_minute
	_until(rig, started.eta_minute)
	assert_eq(order, ["CaravanArrived, caravana no livro: false", "RouteStateChanged, caravana no livro: false"] as Array[String], "No passo a economia anda antes do fechador (módulos no `tick`) e os eventos saem depois, na ordem de publicação: chega e vende, e o fechamento é entregue quando não há mais caravana.")
	assert_eq([rig.arrivals.size(), rig.arrivals[0].revenue, rig.routes.peek_route(A_B).state, rig.module.serialize().has("caravans"), _conserved(rig)], [1, expected, "closed", false, true], "A caravana que chega no passo em que o fechamento é pedido chega e vende; a rota ficou fechada e o livro, vazio.")


func test_closing_a_route_already_walked_changes_nothing() -> void:
	var rig: Rig = _rig()
	_set_route(rig, A_B, false)
	_depart(rig)
	_until(rig, START_MINUTE + 150)
	var before: String = _bytes(rig)
	_set_route(rig, A_C, false)
	assert_eq([_bytes(rig), rig.module.peek_caravan(TRADER).current_route_id], [before, B_C], "No trecho C-B, a A-C (já andada) fecha: nada muda.")


func test_a_closing_in_the_step_where_a_leg_ends_finds_the_caravan_on_the_next_leg_and_detours_at_once() -> void:
	var rig: Rig = _rig()
	_set_route(rig, A_B, false)
	_depart(rig)
	_until(rig, START_MINUTE + 60)
	_set_route(rig, A_B, true)
	rig.closer.route_id = B_C
	rig.closer.at_minute = START_MINUTE + 124
	_until(rig, START_MINUTE + 124)
	var earlier: Rig = _rig()
	_on_the_way_to_c(earlier, true)
	_until(earlier, START_MINUTE + 124)
	var record: Dictionary = _record(rig)
	assert_eq([record["state"], record["route_ids"], record["leg_index"], record["leg_started_at"], record["leg_minutes"]], ["travelling", [A_C, A_C, A_B] as Array[String], 1, START_MINUTE + 124, 124], "No passo em que o trecho A-C acaba a economia anda antes do fechador (módulos no `tick`): o trecho C-B já começou quando o fechamento é entregue, com 0 minutos andados, no povoado C; ela desvia na hora, pela C-A e A-B, no minuto exato do fim do trecho.")
	assert_eq(record, _record(earlier), "O resultado é o mesmo de quando a B-C fecha um minuto antes: não depende do passo em que o evento foi entregue.")


func test_the_same_closing_without_an_alternative_path_holds_at_the_settlement_with_zero_minutes_walked() -> void:
	var rig: Rig = _rig()
	_set_route(rig, A_B, false)
	var started: CaravanReplies.StartResult = _depart(rig)
	rig.closer.route_id = B_C
	rig.closer.at_minute = START_MINUTE + 124
	_until(rig, START_MINUTE + 124)
	var record: Dictionary = _record(rig)
	assert_eq([record["state"], record["elapsed_at_hold"], record["leg_index"], record["leg_started_at"], record["route_ids"], rig.module.peek_caravans_on(A_C).caravans.size(), rig.module.peek_caravans_on(B_C).caravans.size()], ["held", 0, 1, START_MINUTE + 124, [A_C, B_C] as Array[String], 0, 0], "A-B e B-C fechadas: sem caminho do C ao B, fica `held` no C com 0 minutos andados e fora da estrada.")
	assert_eq([rig.module.peek_inventory(TRADER).weight, rig.module.peek_balance(TRADER).balance, _conserved(rig)], [LOT, 300 - started.cost_paid, true], "Sem perder carga nem dinheiro.")
	_until(rig, START_MINUTE + 134)
	_set_route(rig, B_C, true)
	assert_eq([rig.module.peek_caravan(TRADER).state, _record(rig)["leg_started_at"], rig.module.peek_caravan(TRADER).eta_minute], ["travelling", START_MINUTE + 134, START_MINUTE + 134 + 96], "Parada num povoado, refaz o caminho quando uma rota reabre: a B-C reabriu e o trecho C-B recomeça agora.")


func test_closing_the_first_route_at_the_departure_detours_from_the_origin_or_holds_there_without_losing_the_cargo() -> void:
	var rig: Rig = _rig()
	var started: CaravanReplies.StartResult = _depart(rig)
	_set_route(rig, A_B, false)
	var record: Dictionary = _record(rig)
	assert_eq([record["state"], record["route_ids"], record["leg_index"], record["leg_started_at"], record["leg_minutes"], rig.module.peek_caravan(TRADER).eta_minute], ["travelling", [A_C, B_C] as Array[String], 0, START_MINUTE, 124, START_MINUTE + 124 + 96], "A-B fechada no minuto da partida (0 minutos andados, ainda no A): desvia da origem pela A-C e C-B.")
	var stuck: Rig = _rig()
	_set_route(stuck, A_C, false)
	var stuck_started: CaravanReplies.StartResult = _depart(stuck)
	_set_route(stuck, A_B, false)
	record = _record(stuck)
	assert_eq([record["state"], record["elapsed_at_hold"], record["leg_index"], record["route_ids"], stuck.module.peek_caravan(TRADER).leg_from_settlement_id, stuck.module.peek_caravans_on(A_B).caravans.size()], ["held", 0, 0, [A_B] as Array[String], SETTLEMENT_A, 0], "A-C e A-B fechadas: sem caminho do A ao B, fica `held` na origem, fora da estrada.")
	assert_eq([rig.module.peek_inventory(TRADER).weight, rig.module.peek_balance(TRADER).balance, stuck.module.peek_inventory(TRADER).weight, stuck.module.peek_balance(TRADER).balance, _conserved(rig) and _conserved(stuck)], [LOT, 300 - started.cost_paid, LOT, 300 - stuck_started.cost_paid, true], "Nos dois casos, sem perder carga nem dinheiro.")


func test_a_closing_one_minute_before_the_arrival_holds_the_caravan_one_minute_short() -> void:
	var rig: Rig = _rig()
	var started: CaravanReplies.StartResult = _depart(rig)
	rig.closer.route_id = A_B
	rig.closer.at_minute = started.eta_minute - 1
	_until(rig, started.eta_minute + 9)
	assert_eq([rig.arrivals.size(), rig.module.peek_caravan(TRADER).state, _record(rig)["elapsed_at_hold"]], [0, "held", 142], "Fechada no passo anterior, para com 142 dos 143 minutos andados e não chega no minuto do ETA.")
	_set_route(rig, A_B, true)
	assert_eq(rig.module.peek_caravan(TRADER).eta_minute, started.eta_minute + 10, "Parou 10 minutos (do minuto do fechamento ao da reabertura): o ETA é o original mais 10.")
	_until(rig, started.eta_minute + 10)
	assert_eq([rig.arrivals.size(), rig.arrivals[0].time], [1, started.eta_minute + 10], "Chega no ETA deslocado.")


func test_held_and_rewritten_caravans_save_and_load_with_the_same_hash() -> void:
	var cases: Dictionary = {"no meio da estrada": ["held", [A_B]], "num povoado": ["held", [A_C, B_C]], "com o caminho reescrito": ["travelling", [A_C, A_C, A_B]]}
	for label: String in cases:
		var rig: Rig = _rig()
		match label:
			"no meio da estrada":
				_depart(rig)
				_until(rig, START_MINUTE + 50)
				_set_route(rig, A_B, false)
			"num povoado":
				_on_the_way_to_c(rig, false)
				_until(rig, START_MINUTE + 130)
			_:
				_on_the_way_to_c(rig, true)
				_until(rig, START_MINUTE + 130)
		var copy: Rig = _reloaded(rig)
		var caravan: CaravanReplies.CaravanQuery = copy.module.peek_caravan(TRADER)
		assert_eq([caravan.state, caravan.route_ids, copy.runner.world.state_hash(), copy.module.validate()], [cases[label][0], cases[label][1] as Array[String], rig.runner.world.state_hash(), [] as Array[String]], "Caravana %s: o save carrega com o mesmo hash, o `validate` (com as rotas do `world`) segue vazio." % label)
