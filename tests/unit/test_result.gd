extends GutTest


func test_success_is_ok_without_error_data() -> void:
	var result: Result = Result.success()
	assert_true(result.ok, "Sucesso deve ter ok verdadeiro.")
	assert_eq(result.code, "", "Sucesso não tem código de erro.")
	assert_eq(result.message, "", "Sucesso não tem mensagem de erro.")


func test_failure_keeps_code_and_message() -> void:
	var result: Result = Result.failure("NOT_ENOUGH_MONEY", "Faltam 5 moedas.")
	assert_false(result.ok, "Falha deve ter ok falso.")
	assert_eq(result.code, "NOT_ENOUGH_MONEY")
	assert_eq(result.message, "Faltam 5 moedas.")


func test_success_and_failure_are_distinguishable() -> void:
	assert_ne(Result.success().ok, Result.failure("X", "y").ok)


func test_failure_without_code_gets_unspecified_code() -> void:
	var result: Result = Result.failure("", "sem código")
	assert_false(result.ok)
	assert_eq(result.code, Result.UNSPECIFIED_CODE, "Falha nunca pode ficar sem código.")
	assert_eq(result.message, "sem código")
