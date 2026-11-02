extends GutTest

const DIVISORS: Array[int] = [1, 2, 3, 7, 10, 60, 99, 1250, 1440, 518400, 1000003]


func test_floor_div_matches_the_definition_for_small_values() -> void:
	assert_eq(IntMath.floor_div(7, 2), 3)
	assert_eq(IntMath.floor_div(6, 2), 3)
	assert_eq(IntMath.floor_div(0, 5), 0)
	assert_eq(IntMath.floor_div(1439, 1440), 0)
	assert_eq(IntMath.floor_div(1440, 1440), 1)
	assert_eq(IntMath.floor_div(1441, 1440), 1)


func test_floor_div_rounds_toward_negative_infinity() -> void:
	assert_eq(IntMath.floor_div(-1, 2), -1)
	assert_eq(IntMath.floor_div(-4, 2), -2)
	assert_eq(IntMath.floor_div(-5, 2), -3)
	assert_eq(IntMath.floor_div(7, -2), -4)


func test_floor_div_is_exact_up_to_the_documented_limit() -> void:
	# Para todo a: floor_div(a, b) * b + posmod(a, b) == a. Se o arredondamento do decimal cruzasse
	# para o inteiro seguinte, esta igualdade quebraria, principalmente perto de 2^53.
	var limit: int = IntMath.MAX_EXACT_DIVIDEND
	var dividends: Array[int] = [limit, limit - 1, limit - 2, limit - 1439, limit - 1440, 4503599627370495, 123456789012345, 1, 59, 60, 61]
	for divisor: int in DIVISORS:
		for dividend: int in dividends:
			var quotient: int = IntMath.floor_div(dividend, divisor)
			assert_eq(quotient * divisor + posmod(dividend, divisor), dividend, "dividendo %d, divisor %d" % [dividend, divisor])


func test_floor_div_by_zero_reports_an_error() -> void:
	assert_eq(IntMath.floor_div(5, 0), 0)
	assert_push_error("divisor zero")
