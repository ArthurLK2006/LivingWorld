extends GutTest
## LW-105d1: alcance do mercado (MarketReach.peek_within_reach), sem janela. Os locais são montados à mão (sem terreno nem arquivo) e
## um caso usa o mercado real a_market_01 do povoado a. Os valores esperados estão ESCRITOS À MÃO a partir do envio: alcance de 3 m
## (inclusive no limite), distância horizontal (x, z) até o centro do local, vale o mercado mais próximo (empate: menor id) e a falha
## PLACE_TOO_FAR nas três recusas (longe demais, posição não finita, assentamento sem mercado).

const BLOCKOUT_DIR: String = "res://data/world"
const EXPECTED_CODE: String = "PLACE_TOO_FAR"
const SETTLEMENT_A: String = "test_settlement_a"
const SETTLEMENT_B: String = "test_settlement_b"
const REACH_M: float = 3.0
const ONE_MILLIMETER_M: float = 0.001
const HIGH_ABOVE_M: float = 50.0
const CAPACITY: int = 8
## Posições exatas em 32 bits (inteiros e meios): o limite do alcance é comparado sem arredondamento.
const MARKET: Vector3 = Vector3(100.0, 10.0, 200.0)
## O mercado real do povoado a em data/world/places.json: x_cm 31300 e z_cm 55600.
const REAL_MARKET_ID: String = "a_market_01"
const REAL_MARKET_X_M: float = 313.0
const REAL_MARKET_Z_M: float = 556.0
const COORDINATE_TOLERANCE_M: float = 0.001


func _place(place_id: String, settlement_id: String, kind: String, place_position: Vector3) -> Place:
	return Place.new(place_id, settlement_id, kind, place_position, CAPACITY)


## Um único mercado, `a_market_01`, do povoado a, em MARKET.
func _one_market() -> Array[Place]:
	var places: Array[Place] = [_place(REAL_MARKET_ID, SETTLEMENT_A, Place.KIND_MARKET, MARKET)]
	return places


## Um texto por local, na ordem da lista, com todos os campos: serve para provar que a lista não mudou.
func _describe(places: Array[Place]) -> Array[String]:
	var lines: Array[String] = []
	for place: Place in places:
		lines.append("%s|%s|%s|%s|%d" % [place.id, place.settlement_id, place.kind, str(place.position), place.capacity])
	return lines


func test_the_reach_and_the_failure_code_are_the_agreed_ones() -> void:
	assert_eq(MarketReach.MARKET_REACH_M, REACH_M, "Alcance [HIP, experimental] de 3 m: mudar o número exige mudar este teste de propósito.")
	assert_eq(MarketReach.CODE_PLACE_TOO_FAR, EXPECTED_CODE)


func test_an_actor_inside_the_reach_is_accepted() -> void:
	var places: Array[Place] = _one_market()
	assert_true(MarketReach.peek_within_reach(places, SETTLEMENT_A, MARKET).ok, "No centro do mercado.")
	assert_true(MarketReach.peek_within_reach(places, SETTLEMENT_A, MARKET + Vector3(1.0, 0.0, 1.0)).ok, "A cerca de 1,4 m.")
	assert_true(MarketReach.peek_within_reach(places, SETTLEMENT_A, MARKET + Vector3(-2.0, 0.0, 2.0)).ok, "Em diagonal, 2 e 2 dão cerca de 2,8 m.")
	assert_eq(MarketReach.peek_within_reach(places, SETTLEMENT_A, MARKET).code, "", "Sucesso não traz código de falha.")


func test_an_actor_far_from_the_market_is_refused_with_context_in_the_message() -> void:
	var outcome: Result = MarketReach.peek_within_reach(_one_market(), SETTLEMENT_A, MARKET + Vector3(10.0, 0.0, 0.0))
	assert_false(outcome.ok)
	assert_eq(outcome.code, EXPECTED_CODE)
	assert_string_contains(outcome.message, "muito longe")
	assert_string_contains(outcome.message, REAL_MARKET_ID, "A mensagem diz qual mercado.")
	assert_string_contains(outcome.message, SETTLEMENT_A, "E de qual assentamento.")
	assert_string_contains(outcome.message, "10.0 m", "Traz a distância.")
	assert_string_contains(outcome.message, "alcance de 3.0 m", "E o alcance.")
	var diagonal: Result = MarketReach.peek_within_reach(_one_market(), SETTLEMENT_A, MARKET + Vector3(2.5, 0.0, 2.0))
	assert_eq(diagonal.code, EXPECTED_CODE, "Em diagonal, 2,5 e 2 dão cerca de 3,2 m.")


func test_exactly_at_the_reach_is_accepted_and_one_millimeter_beyond_is_refused() -> void:
	var places: Array[Place] = _one_market()
	assert_true(MarketReach.peek_within_reach(places, SETTLEMENT_A, MARKET + Vector3(REACH_M, 0.0, 0.0)).ok, "3,000 m exatos valem (inclusive no limite).")
	assert_true(MarketReach.peek_within_reach(places, SETTLEMENT_A, MARKET + Vector3(0.0, 0.0, -REACH_M)).ok, "3,000 m exatos no eixo z, para o outro lado.")
	assert_true(MarketReach.peek_within_reach(places, SETTLEMENT_A, MARKET + Vector3(REACH_M - ONE_MILLIMETER_M, 0.0, 0.0)).ok, "2,999 m valem.")
	var beyond: Result = MarketReach.peek_within_reach(places, SETTLEMENT_A, MARKET + Vector3(REACH_M + ONE_MILLIMETER_M, 0.0, 0.0))
	assert_false(beyond.ok, "3,001 m já não valem.")
	assert_eq(beyond.code, EXPECTED_CODE)
	assert_false(MarketReach.peek_within_reach(places, SETTLEMENT_A, MARKET + Vector3(0.0, 0.0, -(REACH_M + ONE_MILLIMETER_M))).ok, "3,001 m no eixo z também não.")


func test_only_the_horizontal_distance_counts_the_height_does_not() -> void:
	var places: Array[Place] = _one_market()
	assert_true(MarketReach.peek_within_reach(places, SETTLEMENT_A, MARKET + Vector3(0.0, HIGH_ABOVE_M, 0.0)).ok, "Mesmo x e z, 50 m acima, vale.")
	assert_true(MarketReach.peek_within_reach(places, SETTLEMENT_A, MARKET + Vector3(0.0, -HIGH_ABOVE_M, 0.0)).ok, "E 50 m abaixo também.")
	assert_true(MarketReach.peek_within_reach(places, SETTLEMENT_A, MARKET + Vector3(REACH_M, HIGH_ABOVE_M, 0.0)).ok, "No limite horizontal e 50 m acima: vale.")
	assert_false(MarketReach.peek_within_reach(places, SETTLEMENT_A, MARKET + Vector3(REACH_M + ONE_MILLIMETER_M, HIGH_ABOVE_M, 0.0)).ok, "Passou do limite horizontal: a altura não compensa.")


func test_a_settlement_without_a_market_place_is_refused() -> void:
	var places: Array[Place] = [
		_place("a_home_01", SETTLEMENT_A, Place.KIND_HOME, MARKET),
		_place("a_work_01", SETTLEMENT_A, Place.KIND_WORK, MARKET),
	]
	var outcome: Result = MarketReach.peek_within_reach(places, SETTLEMENT_A, MARKET)
	assert_false(outcome.ok, "Casa e trabalho, mesmo no mesmo ponto, não são mercado.")
	assert_eq(outcome.code, EXPECTED_CODE)
	assert_string_contains(outcome.message, SETTLEMENT_A)
	assert_string_contains(outcome.message, Place.KIND_MARKET, "A mensagem diz que falta o local do tipo market.")
	var empty: Array[Place] = []
	assert_eq(MarketReach.peek_within_reach(empty, SETTLEMENT_A, MARKET).code, EXPECTED_CODE, "Lista vazia.")
	assert_eq(MarketReach.peek_within_reach(_one_market(), "no_such_settlement", MARKET).code, EXPECTED_CODE, "Assentamento que não existe.")


func test_with_several_markets_the_nearest_one_decides() -> void:
	var places: Array[Place] = [
		_place("a_market_01", SETTLEMENT_A, Place.KIND_MARKET, MARKET),
		_place("a_market_02", SETTLEMENT_A, Place.KIND_MARKET, MARKET + Vector3(50.0, 0.0, 0.0)),
	]
	assert_true(MarketReach.peek_within_reach(places, SETTLEMENT_A, MARKET + Vector3(1.0, 0.0, 0.0)).ok, "Perto do primeiro.")
	assert_true(MarketReach.peek_within_reach(places, SETTLEMENT_A, MARKET + Vector3(51.0, 0.0, 0.0)).ok, "Perto do segundo, a 51 m do primeiro: vale o mais próximo, não o primeiro da lista.")
	var nearer_first: Result = MarketReach.peek_within_reach(places, SETTLEMENT_A, MARKET + Vector3(20.0, 0.0, 0.0))
	assert_eq(nearer_first.code, EXPECTED_CODE)
	assert_string_contains(nearer_first.message, "a_market_01", "Longe dos dois: a mensagem cita o mais próximo (20 m contra 30 m).")
	assert_string_contains(nearer_first.message, "20.0 m")
	var nearer_second: Result = MarketReach.peek_within_reach(places, SETTLEMENT_A, MARKET + Vector3(35.0, 0.0, 0.0))
	assert_string_contains(nearer_second.message, "a_market_02", "A 15 m do segundo e 35 m do primeiro.")
	assert_string_contains(nearer_second.message, "15.0 m")


func test_a_tie_in_distance_goes_to_the_smallest_id_whatever_the_list_order() -> void:
	var first: Place = _place("a_market_01", SETTLEMENT_A, Place.KIND_MARKET, MARKET)
	var second: Place = _place("a_market_02", SETTLEMENT_A, Place.KIND_MARKET, MARKET + Vector3(20.0, 0.0, 0.0))
	var in_order: Array[Place] = [first, second]
	var reversed: Array[Place] = [second, first]
	var actor: Vector3 = MARKET + Vector3(10.0, 0.0, 0.0)
	for outcome: Result in [MarketReach.peek_within_reach(in_order, SETTLEMENT_A, actor), MarketReach.peek_within_reach(reversed, SETTLEMENT_A, actor)]:
		assert_eq(outcome.code, EXPECTED_CODE, "Os dois mercados estão a 10 m: longe demais.")
		assert_string_contains(outcome.message, "a_market_01", "Empate: o de menor id, qualquer que seja a ordem da lista.")
		assert_string_contains(outcome.message, "10.0 m")
	var close_pair: Array[Place] = [first, _place("a_market_02", SETTLEMENT_A, Place.KIND_MARKET, MARKET + Vector3(4.0, 0.0, 0.0))]
	assert_true(MarketReach.peek_within_reach(close_pair, SETTLEMENT_A, MARKET + Vector3(2.0, 0.0, 0.0)).ok, "Empate a 2 m dentro do alcance vale.")


func test_a_market_of_another_settlement_is_ignored() -> void:
	var places: Array[Place] = [
		_place("a_market_01", SETTLEMENT_A, Place.KIND_MARKET, MARKET + Vector3(100.0, 0.0, 0.0)),
		_place("b_market_01", SETTLEMENT_B, Place.KIND_MARKET, MARKET),
	]
	var outcome: Result = MarketReach.peek_within_reach(places, SETTLEMENT_A, MARKET)
	assert_eq(outcome.code, EXPECTED_CODE, "O mercado do povoado b, bem ali, não vale para o a.")
	assert_string_contains(outcome.message, "a_market_01")
	assert_string_contains(outcome.message, "100.0 m")
	assert_true(MarketReach.peek_within_reach(places, SETTLEMENT_B, MARKET).ok, "Mas vale para o próprio povoado b.")
	var only_b: Array[Place] = [places[1]]
	assert_eq(MarketReach.peek_within_reach(only_b, SETTLEMENT_A, MARKET).code, EXPECTED_CODE, "Povoado a sem mercado nenhum: falha, mesmo com o do b ali.")


func test_a_non_finite_position_is_refused() -> void:
	var places: Array[Place] = _one_market()
	for bad_position: Vector3 in [Vector3(NAN, 10.0, 200.0), Vector3(100.0, 10.0, INF), Vector3(100.0, -INF, 200.0)]:
		var outcome: Result = MarketReach.peek_within_reach(places, SETTLEMENT_A, bad_position)
		assert_false(outcome.ok, "Posição não finita: " + str(bad_position))
		assert_eq(outcome.code, EXPECTED_CODE)
		assert_string_contains(outcome.message, "não finita")
		assert_string_contains(outcome.message, SETTLEMENT_A)


func test_the_input_list_is_left_untouched() -> void:
	var places: Array[Place] = [
		_place("a_market_02", SETTLEMENT_A, Place.KIND_MARKET, MARKET + Vector3(20.0, 0.0, 0.0)),
		_place("a_home_01", SETTLEMENT_A, Place.KIND_HOME, MARKET),
		_place("b_market_01", SETTLEMENT_B, Place.KIND_MARKET, MARKET + Vector3(5.0, 3.0, 0.0)),
		_place("a_market_01", SETTLEMENT_A, Place.KIND_MARKET, MARKET),
	]
	var before: Array[String] = _describe(places)
	assert_true(MarketReach.peek_within_reach(places, SETTLEMENT_A, MARKET).ok)
	assert_false(MarketReach.peek_within_reach(places, SETTLEMENT_A, MARKET + Vector3(60.0, 0.0, 0.0)).ok)
	assert_false(MarketReach.peek_within_reach(places, SETTLEMENT_B, Vector3(NAN, 0.0, 0.0)).ok)
	assert_false(MarketReach.peek_within_reach(places, "no_such_settlement", MARKET).ok)
	assert_eq(places.size(), before.size(), "A quantidade não muda.")
	assert_eq(_describe(places), before, "Nem a ordem, nem os campos dos locais.")


func test_the_real_market_of_settlement_a_follows_the_same_rule() -> void:
	var terrain_loaded: TerrainLoader.LoadResult = TerrainLoader.load_dir(BLOCKOUT_DIR)
	assert_true(terrain_loaded.result.ok, terrain_loaded.result.message)
	var loaded: SettlementLoader.LoadResult = SettlementLoader.load_dir(BLOCKOUT_DIR, terrain_loaded.terrain)
	assert_true(loaded.result.ok, loaded.result.message)
	var real_market: Place = null
	for place: Place in loaded.places:
		if place.id == REAL_MARKET_ID:
			real_market = place
	assert_not_null(real_market, "O arquivo real tem o mercado " + REAL_MARKET_ID + ".")
	if real_market == null:
		return
	assert_almost_eq(real_market.position.x, REAL_MARKET_X_M, COORDINATE_TOLERANCE_M, "As coordenadas escritas à mão são as do arquivo.")
	assert_almost_eq(real_market.position.z, REAL_MARKET_Z_M, COORDINATE_TOLERANCE_M)
	var center: Vector3 = Vector3(REAL_MARKET_X_M, 0.0, REAL_MARKET_Z_M)
	assert_true(MarketReach.peek_within_reach(loaded.places, SETTLEMENT_A, center).ok, "Em cima do mercado (a altura do terreno não conta).")
	assert_true(MarketReach.peek_within_reach(loaded.places, SETTLEMENT_A, center + Vector3(REACH_M, 0.0, 0.0)).ok, "3,000 m do centro valem.")
	assert_eq(MarketReach.peek_within_reach(loaded.places, SETTLEMENT_A, center + Vector3(REACH_M + ONE_MILLIMETER_M, 0.0, 0.0)).code, EXPECTED_CODE, "3,001 m não.")
	var far: Result = MarketReach.peek_within_reach(loaded.places, SETTLEMENT_A, center + Vector3(10.0, 0.0, 0.0))
	assert_eq(far.code, EXPECTED_CODE)
	assert_string_contains(far.message, REAL_MARKET_ID)
	assert_eq(MarketReach.peek_within_reach(loaded.places, SETTLEMENT_B, center).code, EXPECTED_CODE, "O povoado b só vale junto do mercado dele.")
