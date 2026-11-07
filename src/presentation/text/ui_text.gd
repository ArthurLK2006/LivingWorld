class_name UiText
extends RefCounted
## Localização mínima (LW-050; decisão D3 de Arthur): textos de jogo ficam em data/text/pt_br.json, um objeto plano {"chave": "texto"}, lido
## pela apresentação. NÃO usa o TranslationServer, tr() nem arquivos .po ou .translation. `get_text(chave, valores)` troca cada {nome} do
## texto pelo valor dado. Chave ausente: devolve a própria chave entre colchetes e avisa UMA vez por chave (visível, sem derrubar o jogo).
## Só dados simples: nunca carrega recurso nem executa nada do arquivo. Contrato: docs/modules/presentation.md.

const DEFAULT_PATH: String = "res://data/text/pt_br.json"
const CODE_INVALID: String = "UI_TEXT_INVALID"

var _texts: Dictionary[String, String] = {}
var _warned_keys: Dictionary[String, bool] = {}


## Lê e valida o arquivo. Qualquer problema vira falha com arquivo (e a chave, quando é o caso) e a UiText devolvida fica vazia.
static func from_file(path: String) -> LoadResult:
	var texts: UiText = UiText.new()
	if not FileAccess.file_exists(path):
		return LoadResult.new(_failure(path, "", "arquivo não encontrado"), UiText.new())
	var content: String = FileAccess.get_file_as_string(path)
	var open_error: Error = FileAccess.get_open_error()
	if open_error != OK:
		return LoadResult.new(_failure(path, "", "não foi possível ler o arquivo (erro %d)" % open_error), UiText.new())
	var parser: JSON = JSON.new()
	if parser.parse(content) != OK:
		return LoadResult.new(_failure(path, "", "JSON inválido na linha %d: %s" % [parser.get_error_line(), parser.get_error_message()]), UiText.new())
	# Variant é inevitável aqui: é a fronteira com o JSON, conferida logo abaixo.
	var root: Variant = parser.data
	if typeof(root) != TYPE_DICTIONARY:
		return LoadResult.new(_failure(path, "", "a raiz deve ser um objeto {\"chave\": \"texto\"}"), UiText.new())
	var entries: Dictionary = root
	for key: Variant in entries:
		var key_text: String = str(key)
		var value: Variant = entries[key]
		if key_text.strip_edges().is_empty():
			return LoadResult.new(_failure(path, key_text, "chave vazia"), UiText.new())
		if typeof(value) != TYPE_STRING or str(value).strip_edges().is_empty():
			return LoadResult.new(_failure(path, key_text, "o valor deve ser um texto não vazio"), UiText.new())
		texts._texts[key_text] = str(value)
	return LoadResult.new(Result.success(), texts)


func has_key(key: String) -> bool:
	return _texts.has(key)


func key_count() -> int:
	return _texts.size()


## Texto da chave, com cada {nome} trocado pelo valor correspondente de `values`. Chave ausente: "[chave]" e um aviso por chave.
func get_text(key: String, values: Dictionary = {}) -> String:
	if not _texts.has(key):
		if not _warned_keys.has(key):
			_warned_keys[key] = true
			push_warning("UiText: chave de texto '%s' ausente em %s; mostrando a própria chave." % [key, DEFAULT_PATH])
		return "[%s]" % key
	var text: String = _texts[key]
	for name: Variant in values:
		text = text.replace("{%s}" % str(name), str(values[name]))
	return text


static func _failure(path: String, key: String, message: String) -> Result:
	var where: String = path if key.is_empty() else "%s | chave '%s'" % [path, key]
	return Result.failure(CODE_INVALID, "%s: %s." % [where, message])


## Resultado da leitura: `texts` só vale se `result.ok` (mesmo padrão de TerrainLoader.LoadResult).
class LoadResult:
	extends RefCounted

	var result: Result
	var texts: UiText

	func _init(load_result: Result, loaded_texts: UiText) -> void:
		result = load_result
		texts = loaded_texts
