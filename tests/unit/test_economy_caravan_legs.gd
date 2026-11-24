extends GutTest
## LW-099b1: as consultas de leitura da economia para a viagem visível (contrato da LW-099, seções 5, 6 e 8): `peek_caravans` (TODAS as caravanas, em cópias e por `trader_id` crescente, inclusive a parada num povoado, que `peek_caravans_on` não conta) e os dois campos derivados da linha de `peek_caravan`,
## `leg_minutes` (a duração do trecho atual) e `leg_walked_min` (os minutos já andados nele; parada, `elapsed_at_hold`), cortados em [0, `leg_minutes`] e nunca salvos. Economia e `world` REAIS, como `test_economy_caravan_trip.gd`; o ajudante é o `CaravanRig`. Os minutos esperados saem da mão.

const TRADER: int = 100
const OTHER: int = 101
const THIRD: int = 102
const TRADERS: Array[int] = [TRADER, OTHER, THIRD]
const START: int = CaravanRig.START_MINUTE
const SETTLEMENT_A: String = CaravanRig.SETTLEMENT_A
const SETTLEMENT_B: String = CaravanRig.SETTLEMENT_B
const SETTLEMENT_C: String = CaravanRig.SETTLEMENT_C

var _routes: RouteService
var _rigs: Array[CaravanRig] = []


func before_all() -> void:
	_routes = CaravanRig.load_routes()


func after_each() -> void:
	for rig: CaravanRig in _rigs:
		rig.release()
	_rigs.clear()


func _rig(cadence: int = 1) -> CaravanRig:
	var rig: CaravanRig = CaravanRig.build(_routes, cadence)
	rig.start_new_game(TRADERS)
	_rigs.append(rig)
	return rig


## `[estado, leg_minutes, leg_walked_min]` da caravana de `trader_id` agora.
func _leg_of(rig: CaravanRig, trader_id: int = TRADER) -> Array:
	var row: CaravanReplies.CaravanQuery = rig.module.peek_caravan(trader_id)
	return [row.state, row.leg_minutes, row.leg_walked_min]


func test_peek_caravans_lists_every_caravan_by_trader_id_and_equals_peek_caravan() -> void:
	var rig: CaravanRig = _rig()
	assert_eq(rig.module.peek_caravans().caravans.size(), 0, "Sem viagem, nenhuma linha.")
	rig.three_states(TRADER, OTHER, THIRD)
	var rows: Array[CaravanReplies.CaravanQuery] = rig.module.peek_caravans().caravans
	assert_eq(rows.map(CaravanRig.fields_of), TRADERS.map(func(id: int) -> Array: return CaravanRig.fields_of(rig.module.peek_caravan(id))), "Exatamente o conjunto de `peek_caravan` por comerciante, na ordem de `trader_id` (a partida foi em outra ordem).")
	var summary: Array = rows.map(func(row: CaravanReplies.CaravanQuery) -> Array: return [row.trader_id, row.state, row.leg_from_settlement_id, row.leg_to_settlement_id, row.leg_minutes, row.leg_walked_min, row.progress_m])
	assert_eq(summary, [[TRADER, "travelling", SETTLEMENT_A, SETTLEMENT_C, 124, 100, 346], [OTHER, "held", SETTLEMENT_B, SETTLEMENT_C, 96, 20, 70], [THIRD, "held", SETTLEMENT_C, SETTLEMENT_B, 96, 0, 0]], "Andando, parada no meio da estrada e parada num povoado.")
	var on_road: Array[int] = []
	for route_id: String in [CaravanRig.A_B, CaravanRig.A_C, CaravanRig.B_C]:
		for row: CaravanReplies.CaravanQuery in rig.module.peek_caravans_on(route_id).caravans:
			on_road.append(row.trader_id)
	assert_eq(on_road, [TRADER, OTHER] as Array[int], "`peek_caravans_on` não conta a parada num povoado; `peek_caravans` conta.")
	rows[0].quantity = 999
	rows[0].route_ids.append("route_x")
	assert_eq([rig.module.peek_caravan(TRADER).quantity, rig.module.peek_caravan(TRADER).route_ids], [CaravanRig.LOT, [CaravanRig.A_C] as Array[String]], "As linhas são cópias: mexer nelas não toca a economia.")


func test_a_one_leg_trip_walks_one_minute_per_minute_until_the_end_of_the_leg() -> void:
	var rig: CaravanRig = _rig()
	assert_eq(rig.depart(TRADER, rig.market_a, rig.market_b).eta_minute, START + 143, "A-B: 143 minutos.")
	for walked: int in [0, 1, 70, 142]:
		rig.until(START + walked)
		var row: CaravanReplies.CaravanQuery = rig.module.peek_caravan(TRADER)
		assert_eq([row.leg_minutes, row.leg_walked_min, row.progress_m], [143, walked, floori(520.0 * walked / 143.0)], "%d minutos depois da partida." % walked)
	rig.until(START + 143)
	assert_false(rig.module.peek_caravan(TRADER).found, "Chegou: o registro some e, com ele, os campos.")


func test_a_two_leg_trip_restarts_the_count_at_the_exact_minute_the_first_leg_ends() -> void:
	var rig: CaravanRig = _rig()
	rig.set_route(CaravanRig.A_B, false)
	assert_eq(rig.depart(TRADER, rig.market_a, rig.market_b).eta_minute, START + 124 + 96, "A-B fechada: o caminho é A-C (124) e C-B (96).")
	for expected: Array in [[0, 124, 0, SETTLEMENT_A, SETTLEMENT_C], [123, 124, 123, SETTLEMENT_A, SETTLEMENT_C], [124, 96, 0, SETTLEMENT_C, SETTLEMENT_B], [174, 96, 50, SETTLEMENT_C, SETTLEMENT_B], [219, 96, 95, SETTLEMENT_C, SETTLEMENT_B]]:
		rig.until(START + expected[0])
		var row: CaravanReplies.CaravanQuery = rig.module.peek_caravan(TRADER)
		assert_eq([row.leg_minutes, row.leg_walked_min, row.leg_from_settlement_id, row.leg_to_settlement_id], expected.slice(1), "Minuto %d da viagem." % expected[0])


func test_the_fields_stay_consistent_with_the_registry_and_progress_at_every_minute_whatever_the_step() -> void:
	var clamped: int = 0
	for cadence: int in [1, 7, 60, 180]:
		var rig: CaravanRig = _rig(cadence)
		rig.set_route(CaravanRig.A_B, false)
		rig.depart(TRADER, rig.market_a, rig.market_b)
		for minute: int in range(START + 1, START + 301):
			rig.until(minute)
			var row: CaravanReplies.CaravanQuery = rig.module.peek_caravan(TRADER)
			if not row.found:
				continue
			var record: Dictionary = rig.module.serialize()["caravans"][0]
			var leg_minutes: int = record["leg_minutes"]
			var expected: int = clampi(minute - int(record["leg_started_at"]), 0, leg_minutes)
			clamped += 1 if expected == leg_minutes else 0
			assert_eq([row.leg_minutes, row.leg_walked_min, row.progress_m], [leg_minutes, expected, floori(row.leg_length_m * float(expected) / leg_minutes)], "Passo de %d minutos, minuto %d: o trecho, os minutos andados (cortados no fim do trecho) e a posição batem com o registro." % [cadence, minute])
	assert_gt(clamped, 0, "Com a conferência a cada 60 ou 180 minutos o trecho passa do fim antes de ela rodar: o corte em `leg_minutes` foi exercitado.")


func test_a_caravan_held_mid_road_keeps_its_walked_minutes_and_resumes_from_there() -> void:
	var rig: CaravanRig = _rig()
	rig.depart(TRADER, rig.market_a, rig.market_b)
	rig.until(START + 40)
	rig.set_route(CaravanRig.A_B, false)
	var held: Array = []
	for minute: int in [40, 41, 70]:
		rig.until(START + minute)
		held.append(_leg_of(rig))
	assert_eq(held, [["held", 143, 40], ["held", 143, 40], ["held", 143, 40]], "Parada a 40 minutos: o relógio anda, os minutos andados não.")
	rig.set_route(CaravanRig.A_B, true)
	var resumed: Array = [_leg_of(rig)]
	for minute: int in [71, 100]:
		rig.until(START + minute)
		resumed.append(_leg_of(rig))
	assert_eq(resumed, [["travelling", 143, 40], ["travelling", 143, 41], ["travelling", 143, 70]], "Reaberta a rota, segue dos 40 minutos já andados.")


func test_a_caravan_held_in_a_settlement_has_walked_zero_and_the_duration_of_the_blocked_leg() -> void:
	var rig: CaravanRig = _rig()
	rig.three_states(TRADER, OTHER, THIRD)
	assert_eq(_leg_of(rig, THIRD), ["held", 96, 0], "Parada no C com a C-B fechada: o trecho bloqueado é de 96 minutos e nenhum foi andado.")
	rig.until(START + 160)
	assert_eq(_leg_of(rig, THIRD), ["held", 96, 0], "Parada num povoado não anda: 36 minutos depois, nada mudou.")
	rig.set_route(CaravanRig.B_C, true)
	assert_eq([_leg_of(rig, THIRD), _leg_of(rig, OTHER)], [["travelling", 96, 0], ["travelling", 96, 20]], "Reaberta a B-C: a do povoado parte do zero (o trecho começa agora); a do meio da estrada segue dos 20 minutos andados.")
	rig.until(START + 161)
	assert_eq([_leg_of(rig, THIRD)[2], _leg_of(rig, OTHER)[2]], [1, 21], "Um minuto depois, mais um minuto andado em cada uma.")
