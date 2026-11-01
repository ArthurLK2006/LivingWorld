extends GutTest
## LW-025: três tipos de dado de teste com referências cruzadas (spike SP3).

const OK_DIR: String = "res://tests/fixtures/data/ok"
const BAD_DIR: String = "res://tests/fixtures/data/bad"


func test_three_test_tables_load_and_cross_references_resolve() -> void:
	var bundle: DataBundle = DataLoader.load_all(OK_DIR, PipelineSchemas.build())
	assert_true(bundle.is_valid(), bundle.describe_issues())
	assert_eq(bundle.tables.size(), 3)
	var offer: Dictionary = bundle.tables["offers"][0]
	assert_eq(offer["good"], "test_good_a")
	assert_eq(typeof(offer["price_multiplier"]), TYPE_FLOAT)


func test_optional_reference_may_be_absent() -> void:
	var bundle: DataBundle = DataLoader.load_all(OK_DIR, PipelineSchemas.build())
	var offer_without_recipe: Dictionary = bundle.tables["offers"][1]
	assert_false(offer_without_recipe.has("source_recipe"))
	assert_true(bundle.is_valid())


func test_missing_table_file_does_not_hide_other_errors() -> void:
	# A pasta "bad" não tem offers.json: o erro deve aparecer sem esconder os das outras tabelas.
	var bundle: DataBundle = DataLoader.load_all(BAD_DIR, PipelineSchemas.build())
	var text: String = bundle.describe_issues()
	assert_string_contains(text, "offers.json | arquivo não encontrado")
	assert_string_contains(text, "ghost_good")
