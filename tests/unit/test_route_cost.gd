extends GutTest
## LW-098b: o custo de rota do comerciante (`RouteCost`, docs/modules/economy.md, 9.3 e 9.5) com os parâmetros de PARTIDA do contrato (400 cm por minuto, 50 pontos-base por ponto de dificuldade, 25 de risco, 2 por hora, 5 fixo), montados em memória: o teste não depende da calibração do arquivo.
## As três rotas reais (data/world/routes.json) batem com a conta à mão: 143, 124 e 96 minutos.

const ROUTES_FILE: String = "res://data/world/routes.json"


func _params(speed: int = 400) -> CaravanParams:
	return CaravanParams.new({"speed_cm_per_min": speed, "difficulty_slowdown_bp": 50, "risk_bp_per_point": 25, "time_cost_per_hour": 2, "fixed_cost": 5, "min_net_profit": 20, "min_margin_bp": 500, "origin_reserve_bp": 5000})


func _real_legs() -> Dictionary[String, RouteCost.Leg]:
	var legs: Dictionary[String, RouteCost.Leg] = {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(ROUTES_FILE))  # Variant: fronteira com o JSON, tipada logo abaixo.
	var rows: Array = parsed if typeof(parsed) == TYPE_ARRAY else []
	for row: Dictionary in rows:
		legs[str(row["id"])] = RouteCost.Leg.new(str(row["id"]), int(row["length_m"]), int(row["difficulty"]), int(row["risk"]))
	return legs


func _path(first: RouteCost.Leg, second: RouteCost.Leg = null) -> Array[RouteCost.Leg]:
	var legs: Array[RouteCost.Leg] = [first]
	if second != null:
		legs.append(second)
	return legs


func test_the_three_real_routes_take_143_124_and_96_minutes() -> void:
	var legs: Dictionary[String, RouteCost.Leg] = _real_legs()
	assert_eq(legs.size(), 3, "O arquivo real tem as 3 rotas.")
	assert_eq(RouteCost.leg_minutes(legs["route_a_b"], _params()), 143, "A–B: ceil_div(52000 × 11000, 400 × 10000) = 143.")
	assert_eq(RouteCost.leg_minutes(legs["route_a_c"], _params()), 124, "A–C: 43000 × 11500 ÷ 4.000.000 = 123,625, para cima.")
	assert_eq(RouteCost.leg_minutes(legs["route_b_c"], _params()), 96, "B–C: 34000 × 11250 ÷ 4.000.000 = 95,625, para cima.")


func test_risk_and_time_of_the_three_real_routes_match_the_hand_calculation() -> void:
	var legs: Dictionary[String, RouteCost.Leg] = _real_legs()
	var expected_risk: Dictionary[String, int] = {"route_a_b": 25, "route_a_c": 50, "route_b_c": 38}
	var expected_time: Dictionary[String, int] = {"route_a_b": 10, "route_a_c": 10, "route_b_c": 9}
	for route_id: String in expected_risk:
		var path: Array[RouteCost.Leg] = _path(legs[route_id])
		assert_eq(RouteCost.risk_discount(1000, RouteCost.path_risk_points(path), _params()), expected_risk[route_id], "%s: risco sobre 1000 de receita (10, 20 e 15 pontos a 25 bp; B–C dá 37,5, para cima)." % route_id)
		assert_eq(RouteCost.time_cost(RouteCost.path_minutes(path, _params()), _params()), expected_time[route_id], "%s: ceil_div(minutos × 2, 60) + 5." % route_id)


func test_a_path_adds_its_legs_and_an_empty_path_costs_nothing_but_the_fixed_cost() -> void:
	var legs: Dictionary[String, RouteCost.Leg] = _real_legs()
	var via_b: Array[RouteCost.Leg] = _path(legs["route_a_b"], legs["route_b_c"])
	assert_eq(RouteCost.path_minutes(via_b, _params()), 239, "143 + 96.")
	assert_eq(RouteCost.path_risk_points(via_b), 25, "10 + 15.")
	assert_eq(RouteCost.time_cost(239, _params()), 13, "ceil_div(239 × 2, 60) = 8, mais 5 fixos.")
	var empty: Array[RouteCost.Leg] = []
	assert_eq([RouteCost.path_minutes(empty, _params()), RouteCost.path_risk_points(empty), RouteCost.time_cost(0, _params())], [0, 0, 5])


func test_harder_longer_or_slower_costs_more_time_and_the_minimum_is_one_minute() -> void:
	var flat: RouteCost.Leg = RouteCost.Leg.new("flat", 520, 0, 0)
	var hard: RouteCost.Leg = RouteCost.Leg.new("hard", 520, 100, 0)
	assert_eq(RouteCost.leg_minutes(flat, _params()), 130, "Sem dificuldade: 52000 ÷ 400.")
	assert_eq(RouteCost.leg_minutes(hard, _params()), 195, "Dificuldade 100: 50% mais lenta.")
	assert_lt(RouteCost.leg_minutes(flat, _params(800)), RouteCost.leg_minutes(flat, _params()), "O dobro da velocidade, menos minutos.")
	assert_gt(RouteCost.leg_minutes(RouteCost.Leg.new("long", 1040, 0, 0), _params()), RouteCost.leg_minutes(flat, _params()), "O dobro do comprimento, mais minutos.")
	assert_eq(RouteCost.leg_minutes(RouteCost.Leg.new("tiny", 1, 0, 0), _params(100000)), 1, "Trecho de 1 m na maior velocidade: 1 minuto, nunca 0.")
	assert_eq(RouteCost.risk_discount(0, 25, _params()), 0, "Sem receita não há desconto de risco.")
	assert_eq(RouteCost.risk_discount(1000, 0, _params()), 0, "Rota sem risco não desconta.")
	assert_lt(RouteCost.risk_discount(1000, 10, _params()), RouteCost.risk_discount(1000, 11, _params()), "Mais risco, mais desconto.")
	assert_eq(RouteCost.risk_discount(1000, 15, _params()), RouteCost.risk_discount(1000, 15, _params()), "Função pura: mesma entrada, mesma saída.")
