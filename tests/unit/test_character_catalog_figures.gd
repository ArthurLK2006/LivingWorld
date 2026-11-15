extends GutTest
## ART-12, entrega 6b (1): a tabela OPCIONAL `figures` do CharacterCatalog (só dados, sem Node, sem janela e sem ativo de terceiros: os caminhos das figuras NÃO precisam existir). Ausente ou vazia (no catálogo REAL e no fixture) = nenhuma figura e nada muda; uma tabela válida responde `figures()` e `figure(id)` com cópias; arquivo inexistente NÃO é falha do catálogo (o ativo não está no Git: quem não o tem não perde o catálogo); cada erro (id repetido, campo desconhecido ou ausente, tipo errado, prefixo de caminho, lista que não é lista, linha que não é objeto) vira UMA falha tratada com arquivo, item e campo, e o catálogo da falha é vazio.

const FIXTURE: String = "res://tests/unit/support/character_catalog_ok.json"
const LABEL: String = "catalogo_de_teste.json"
const SCENE: String = "res://figuras_de_teste/figura.scn"
const META: String = "user://pasta_que_nao_existe/figura.json"
const ROW: Dictionary = {"id": "ice", "scene": SCENE, "meta": META}
## Cada caso: [valor de `figures`, item esperado na falha, campo esperado].
const BAD_CASES: Array = [
	[[ROW, ROW], "ice", "id"],
	[[{"id": "ice", "scene": SCENE, "meta": META, "mesh": "x"}], "ice", "mesh"],
	[[{"id": "ice", "meta": META}], "ice", "scene"],
	[[{"id": "ice", "scene": SCENE}], "ice", "meta"],
	[[{"id": "ice", "scene": ["x"], "meta": META}], "ice", "scene"],
	[[{"id": "ice", "scene": SCENE, "meta": 7}], "ice", "meta"],
	[[{"id": 7, "scene": SCENE, "meta": META}], "figures[0]", "id"],
	[[{"id": "ice", "scene": "", "meta": META}], "ice", "scene"],
	[[{"id": "ice", "scene": "figura.scn", "meta": META}], "ice", "scene"],
	[[{"id": "ice", "scene": SCENE, "meta": "http://exemplo.org/figura.json"}], "ice", "meta"],
	[7, "", "figures"],
	[["ice"], "figures[0]", ""],
]


## O fixture com `figures` trocada por `figures`, que é Variant porque os casos ruins levam qualquer forma de JSON (lista, número, texto).
func _text_with(figures: Variant) -> String:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(FIXTURE))
	data["figures"] = figures
	return JSON.stringify(data)


func test_the_real_catalog_and_the_fixture_have_no_figures_and_stay_valid() -> void:
	var real_data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CharacterCatalog.DEFAULT_PATH))
	assert_false(real_data.has(CharacterCatalog.FIGURE_TABLE), "o arquivo real do repositório não ganha figura")
	for loaded: CharacterCatalog.LoadResult in [CharacterCatalog.from_file(), CharacterCatalog.from_file(FIXTURE), CharacterCatalog.from_json(_text_with([]), LABEL)]:
		assert_true(loaded.result.ok, loaded.result.message)
		assert_true(loaded.catalog.is_ready())
		assert_true(loaded.catalog.figures().is_empty())
		assert_true(loaded.catalog.figure("ice").is_empty())


func test_a_valid_table_is_read_in_order_and_the_queries_return_copies() -> void:
	var other: Dictionary = {"id": "other", "scene": META, "meta": SCENE}
	var loaded: CharacterCatalog.LoadResult = CharacterCatalog.from_json(_text_with([ROW, other]), LABEL)
	assert_true(loaded.result.ok, loaded.result.message)
	assert_true(loaded.catalog.is_ready())
	assert_eq(loaded.catalog.figures(), [ROW, other])
	assert_eq(loaded.catalog.figure("other"), other)
	assert_true(loaded.catalog.figure("nao_existe").is_empty())
	loaded.catalog.figures()[0]["id"] = "alterado"
	loaded.catalog.figure("ice")["scene"] = "alterado"
	assert_eq(loaded.catalog.figure("ice"), ROW, "as consultas devolvem cópias")


func test_a_figure_file_that_does_not_exist_is_not_a_catalog_failure() -> void:
	assert_false(ResourceLoader.exists(SCENE) or FileAccess.file_exists(META), "os arquivos da figura de teste não existem")
	var only_figure_files_missing: Callable = func(path: String) -> bool: return path != SCENE and path != META
	var loaded: CharacterCatalog.LoadResult = CharacterCatalog.from_json(_text_with([ROW]), LABEL, only_figure_files_missing)
	assert_true(loaded.result.ok, loaded.result.message)
	assert_eq(loaded.catalog.figure("ice"), ROW)


func test_each_invalid_figure_table_is_one_handled_failure_with_file_item_and_field() -> void:
	for index: int in BAD_CASES.size():
		var spec: Array = BAD_CASES[index]
		var loaded: CharacterCatalog.LoadResult = CharacterCatalog.from_json(_text_with(spec[0]), LABEL)
		var message: String = loaded.result.message
		assert_false(loaded.result.ok, "caso %d deveria falhar" % index)
		assert_false(loaded.catalog.is_ready(), "caso %d: o catálogo da falha é vazio" % index)
		assert_true(message.begins_with(LABEL), "caso %d: arquivo em %s" % [index, message])
		assert_true(spec[1] == "" or message.contains("item '%s'" % spec[1]), "caso %d: item em %s" % [index, message])
		assert_true(spec[2] == "" or message.contains("campo '%s'" % spec[2]), "caso %d: campo em %s" % [index, message])
