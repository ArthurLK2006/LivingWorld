extends GutTest
## LW-050: localização mínima. data/text/pt_br.json é um objeto plano {"chave": "texto"} lido por UiText: troca {nome} por valor, chave
## ausente devolve [chave] e avisa uma vez, arquivo inválido falha apontando arquivo e chave. Sem TranslationServer.

## Toda chave que o código de jogo usa hoje; o teste confere que o arquivo real as tem (escritas à mão).
const USED_KEYS: Array[String] = [
	"poi.test_marker_near", "poi.test_marker_far", "ui.interact_prompt", "ui.interact_too_far", "ui.interact_unknown",
	"ui.interact_failed", "ui.hud_title", "ui.hud_clock", "ui.hud_date", "ui.hud_pause_hint", "ui.hud_pace_paused", "ui.hud_pace_speed",
]

var _temp_dirs: Array[DirAccess] = []


func after_each() -> void:
	for dir: DirAccess in _temp_dirs:
		for file_name: String in dir.get_files():
			dir.remove(file_name)
		DirAccess.remove_absolute(dir.get_current_dir())
	_temp_dirs.clear()


## Arquivo temporário de textos com o conteúdo dado; devolve o caminho.
func _file_with(content: String) -> String:
	var dir: DirAccess = DirAccess.create_temp("lw050")
	_temp_dirs.append(dir)
	var path: String = dir.get_current_dir().path_join("pt_br.json")
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(content)
	file.close()
	return path


func _texts_from(content: String) -> UiText:
	var loaded: UiText.LoadResult = UiText.from_file(_file_with(content))
	assert_true(loaded.result.ok, loaded.result.message)
	return loaded.texts


func test_the_real_file_has_every_key_the_game_uses_with_non_empty_text() -> void:
	var loaded: UiText.LoadResult = UiText.from_file(UiText.DEFAULT_PATH)
	assert_true(loaded.result.ok, loaded.result.message)
	for key: String in USED_KEYS:
		assert_true(loaded.texts.has_key(key), "Falta a chave '%s' em data/text/pt_br.json." % key)
		assert_ne(loaded.texts.get_text(key), "[%s]" % key, "A chave '%s' devolveu a própria chave." % key)


func test_the_two_markers_and_the_prompt_have_the_agreed_texts() -> void:
	var texts: UiText = UiText.from_file(UiText.DEFAULT_PATH).texts
	assert_string_contains(texts.get_text("poi.test_marker_near"), "pedra", "Um marco de pedra simples.")
	assert_string_contains(texts.get_text("poi.test_marker_far"), "fogueira", "Restos frios de uma fogueira.")
	assert_ne(texts.get_text("poi.test_marker_near"), texts.get_text("poi.test_marker_far"))
	assert_eq(texts.get_text("ui.interact_prompt", {"key": "E"}), "[E] Interagir")
	assert_eq(texts.get_text("ui.interact_too_far"), "Chegue mais perto.")


func test_each_name_in_braces_is_replaced_by_its_value() -> void:
	var texts: UiText = _texts_from('{"a": "{x} e {y} e {x}", "b": "sem nada"}')
	assert_eq(texts.get_text("a", {"x": "um", "y": 2}), "um e 2 e um")
	assert_eq(texts.get_text("b", {"x": "ignorado"}), "sem nada", "Valor que não aparece no texto é ignorado.")
	assert_eq(texts.get_text("a"), "{x} e {y} e {x}", "Sem valores, o texto vem como está.")


func test_a_missing_key_gives_the_key_in_brackets_and_warns_once() -> void:
	var texts: UiText = _texts_from('{"a": "texto"}')
	assert_eq(texts.get_text("nao.existe"), "[nao.existe]")
	assert_eq(texts.get_text("nao.existe"), "[nao.existe]", "A segunda chamada devolve o mesmo.")
	assert_push_warning_count(1, "Um aviso por chave, não um por chamada.")
	assert_eq(texts.get_text("outra.ausente"), "[outra.ausente]")
	assert_push_warning_count(2, "Outra chave ausente avisa de novo, uma vez.")


func test_an_invalid_file_fails_with_file_and_key() -> void:
	var cases: Dictionary[String, Array] = {
		'{"a": "texto", "b": 5}': ["pt_br.json", "chave 'b'", "texto não vazio"],
		'{"a": "   "}': ["pt_br.json", "chave 'a'", "texto não vazio"],
		'{"": "texto"}': ["pt_br.json", "chave vazia"],
		'["a", "b"]': ["pt_br.json", "raiz deve ser um objeto"],
		'{"a": "texto"': ["pt_br.json", "JSON inválido"],
		'{"a": null}': ["pt_br.json", "chave 'a'"],
	}
	for content: String in cases:
		var loaded: UiText.LoadResult = UiText.from_file(_file_with(content))
		assert_false(loaded.result.ok, "Deveria falhar: " + content)
		assert_eq(loaded.result.code, UiText.CODE_INVALID)
		for part: String in cases[content]:
			assert_string_contains(loaded.result.message, part)
		assert_eq(loaded.texts.key_count(), 0, "Falha devolve textos vazios.")
	var missing: UiText.LoadResult = UiText.from_file("res://tests/fixtures/world/pasta_que_nao_existe/pt_br.json")
	assert_false(missing.result.ok)
	assert_string_contains(missing.result.message, "arquivo não encontrado")
