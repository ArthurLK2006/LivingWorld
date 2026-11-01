extends GutTest


func test_falha_intencional() -> void:
	assert_eq(2 + 2, 5, "Falha intencional para verificar o código de saída.")
