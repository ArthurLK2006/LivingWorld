extends GutTest
## ART-12, entrega 3: o CharacterCatalog (só dados, sem Node nem janela). Dados válidos (o fixture em tests/unit/support aponta para arquivos REAIS do projeto, então a conferência de existência é a de verdade), duas cargas iguais, as consultas; e cada erro de carga (arquivo ausente, JSON inválido, campo ausente ou de tipo errado, id repetido, caminho inexistente, categoria vazia, gênero sem roupa ou sem cabelo) vira UMA falha tratada com arquivo, item e campo. A conferência de existência também pode ser injetada. Entrega 3c: a tabela `beards` é opcional (ausente ou vazia vale, inválida falha) e o `gender` das sobrancelhas também (ausente = qualquer; inválido falha).

const FIXTURE: String = "res://tests/unit/support/character_catalog_ok.json"
const LABEL: String = "catalogo_de_teste.json"
const ERASE: String = "__apagar__"
const MISSING: String = "res://nao_existe/peca.glb"
const SCENE: String = "res://scenes/main.tscn"
const TABLES: PackedStringArray = ["bodies", "outfits", "hair", "eyebrows"]
## Cada caso: [caminho do valor no JSON, valor novo (ERASE apaga a chave), item esperado na falha, campo esperado].
const BAD_CASES: Array = [
	[["version"], ERASE, "", "version"],
	[["version"], 2, "", "version"],
	[["skeleton_bones"], "65", "", "skeleton_bones"],
	[["eyebrows"], ERASE, "", "eyebrows"],
	[["bodies", 0, "head_scene"], ERASE, "male_a", "head_scene"],
	[["bodies", 0, "gender"], 7, "male_a", "gender"],
	[["bodies", 0, "gender"], "robot", "male_a", "gender"],
	[["outfits", 0, "parts", "legs"], MISSING, "peasant_m", "legs"],
	[["outfits", 0, "parts", "extras"], [MISSING], "peasant_m", "extras"],
	[["outfits", 1, "id"], "peasant_m", "peasant_m", "id"],
	[["hair", 0, "scene"], MISSING, "hair_m1", "scene"],
	[["beards", 0, "scene"], MISSING, "beard_01", "scene"],
	[["beards", 0, "gender"], "robot", "beard_01", "gender"],
	[["beards", 0, "gender"], ERASE, "beard_01", "gender"],
	[["beards", 1, "id"], "beard_01", "beard_01", "id"],
	[["beards"], 7, "", "beards"],
	[["eyebrows", 0, "gender"], "robot", "brow_01", "gender"],
	[["eyebrows", 1, "gender"], 7, "brow_02", "gender"],
	[["animations", "walk"], ERASE, "animations", "walk"],
	[["animations", "idle", "path"], "", "idle", "path"],
	[["outfits"], [{"id": "only_m", "gender": "male", "parts": {"torso_arms": SCENE, "legs": SCENE, "boots": SCENE, "extras": []}}], "female_a", "gender"],
	[["hair"], [{"id": "only_m", "gender": "male", "scene": SCENE}], "female_a", "gender"],
]


func _text_with(path: Array, value: Variant) -> String:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(FIXTURE))
	var node: Variant = data
	for step: Variant in path.slice(0, path.size() - 1):
		node = node[step]
	var last: Variant = path[path.size() - 1]
	if typeof(value) == TYPE_STRING and value == ERASE:
		node.erase(last)
	else:
		node[last] = value
	return JSON.stringify(data)


func _ids(rows: Array[Dictionary]) -> Array:
	var ids: Array = []
	for row: Dictionary in rows:
		ids.append(row["id"])
	return ids


func test_the_fixture_loads_and_answers_the_queries() -> void:
	var loaded: CharacterCatalog.LoadResult = CharacterCatalog.from_file(FIXTURE)
	assert_true(loaded.result.ok, loaded.result.message)
	var catalog: CharacterCatalog = loaded.catalog
	assert_true(catalog.is_ready())
	assert_eq(catalog.skeleton_bones, 65)
	assert_eq(_ids(catalog.bodies()), ["male_a", "female_a"])
	assert_eq(_ids(catalog.outfits_for("female")), ["peasant_f", "ranger_f", "smith_f"])
	assert_eq(_ids(catalog.hair_for("male")), ["hair_m1", "hair_m2", "hair_any"])
	assert_eq(_ids(catalog.hair_for("female")), ["hair_f1", "hair_f2", "hair_any"])
	assert_eq(_ids(catalog.eyebrows()), ["brow_01", "brow_02", "brow_03"])
	assert_eq(_ids(catalog.beards_for("male")), ["beard_01", "beard_02", "beard_any"])
	assert_eq(_ids(catalog.beards_for("female")), ["beard_any"])
	assert_eq(_ids(catalog.eyebrows_for("male")), ["brow_01", "brow_03"])
	assert_eq(_ids(catalog.eyebrows_for("female")), ["brow_02", "brow_03"])
	assert_eq(catalog.animations()["walk"]["name"], "Walk")


func test_two_loads_give_the_same_catalog_and_the_queries_return_copies() -> void:
	var first: CharacterCatalog = CharacterCatalog.from_file(FIXTURE).catalog
	var second: CharacterCatalog = CharacterCatalog.from_file(FIXTURE).catalog
	assert_eq(first.bodies(), second.bodies())
	assert_eq(first.outfits_for("male"), second.outfits_for("male"))
	assert_eq(first.hair_for("female"), second.hair_for("female"))
	assert_eq(first.beards_for("male"), second.beards_for("male"))
	assert_eq(first.eyebrows_for("female"), second.eyebrows_for("female"))
	assert_eq(first.animations(), second.animations())
	first.bodies()[0]["id"] = "alterado"
	first.beards_for("male")[0]["id"] = "alterado"
	first.eyebrows_for("male")[0]["id"] = "alterado"
	assert_eq(_ids(first.bodies()), _ids(second.bodies()))
	assert_eq(_ids(first.beards_for("male")), _ids(second.beards_for("male")))
	assert_eq(_ids(first.eyebrows_for("male")), _ids(second.eyebrows_for("male")))


func test_missing_file_and_bad_json_are_handled_failures() -> void:
	var missing: String = "res://tests/unit/support/nao_existe.json"
	var absent: CharacterCatalog.LoadResult = CharacterCatalog.from_file(missing)
	assert_false(absent.result.ok)
	assert_eq(absent.result.code, CharacterCatalog.CODE_INVALID)
	assert_string_contains(absent.result.message, missing)
	assert_false(absent.catalog.is_ready())
	for broken: String in ["{ isso nao e json", "[]", ""]:
		var loaded: CharacterCatalog.LoadResult = CharacterCatalog.from_json(broken, LABEL)
		assert_false(loaded.result.ok, broken)
		assert_string_contains(loaded.result.message, LABEL)


func test_each_invalid_catalog_is_one_handled_failure_with_file_item_and_field() -> void:
	for index: int in BAD_CASES.size():
		var spec: Array = BAD_CASES[index]
		var loaded: CharacterCatalog.LoadResult = CharacterCatalog.from_json(_text_with(spec[0], spec[1]), LABEL)
		var message: String = loaded.result.message
		assert_false(loaded.result.ok, "caso %d deveria falhar" % index)
		assert_false(loaded.catalog.is_ready(), "caso %d: o catálogo da falha é vazio" % index)
		assert_true(message.begins_with(LABEL), "caso %d: arquivo em %s" % [index, message])
		assert_true(spec[2] == "" or message.contains("item '%s'" % spec[2]), "caso %d: item em %s" % [index, message])
		assert_true(message.contains("campo '%s'" % spec[3]), "caso %d: campo em %s" % [index, message])


func test_an_empty_category_fails_with_a_clear_message() -> void:
	for table: String in TABLES:
		var loaded: CharacterCatalog.LoadResult = CharacterCatalog.from_json(_text_with([table], []), LABEL)
		assert_false(loaded.result.ok, table)
		assert_string_contains(loaded.result.message, "campo '%s' | a lista está vazia" % table)


func test_the_beards_table_is_optional_and_an_old_file_without_it_stays_valid() -> void:
	for text: String in [_text_with(["beards"], ERASE), _text_with(["beards"], [])]:
		var loaded: CharacterCatalog.LoadResult = CharacterCatalog.from_json(text, LABEL)
		assert_true(loaded.result.ok, loaded.result.message)
		assert_true(loaded.catalog.is_ready())
		assert_true(loaded.catalog.beards_for("male").is_empty())
		assert_eq(_ids(loaded.catalog.hair_for("male")), ["hair_m1", "hair_m2", "hair_any"], "o resto do catálogo segue igual")


func test_the_eyebrow_gender_is_optional_and_a_missing_one_fits_any_body() -> void:
	var loaded: CharacterCatalog.LoadResult = CharacterCatalog.from_json(_text_with(["eyebrows", 0, "gender"], ERASE), LABEL)
	assert_true(loaded.result.ok, loaded.result.message)
	assert_eq(_ids(loaded.catalog.eyebrows_for("male")), ["brow_01", "brow_03"], "brow_01 ficou sem gênero: serve aos dois")
	assert_eq(_ids(loaded.catalog.eyebrows_for("female")), ["brow_01", "brow_02", "brow_03"])


func test_the_existence_check_can_be_injected() -> void:
	var text: String = _text_with(["bodies", 0, "head_scene"], MISSING)
	assert_false(CharacterCatalog.from_json(text, LABEL).result.ok)
	assert_true(CharacterCatalog.from_json(text, LABEL, func(_path: String) -> bool: return true).result.ok)
	var fixture_text: String = FileAccess.get_file_as_string(FIXTURE)
	assert_false(CharacterCatalog.from_json(fixture_text, LABEL, func(_path: String) -> bool: return false).result.ok)


func test_unknown_fields_are_ignored_and_a_bad_outfit_id_is_labelled_by_its_position() -> void:
	for path: Array in [["future_field"], ["outfits", 0, "extra_note"], ["animations", "idle", "note"]]:
		assert_true(CharacterCatalog.from_json(_text_with(path, "x"), LABEL).result.ok, "campo desconhecido é ignorado: " + str(path))
	var loaded: CharacterCatalog.LoadResult = CharacterCatalog.from_json(_text_with(["outfits", 0, "id"], 7), LABEL)
	assert_false(loaded.result.ok, "id numérico")
	assert_string_contains(loaded.result.message, "outfits[0]")
