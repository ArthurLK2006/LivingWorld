class_name CharacterDataReader
extends RefCounted
## Leitor dos JSON de personagens (catálogo e paletas; ART-12, entrega 3, só apresentação): dados simples, nunca carrega recurso nem executa nada do arquivo. Os problemas se acumulam num DataBundle, no formato "arquivo | item | campo | mensagem" dos outros carregadores, e cada leitura devolve um valor neutro em vez de lançar erro: quem chama lê tudo e confere `bundle.is_valid()` no fim. Nada vai para o log.

const RES_PREFIX: String = "res://"

var bundle: DataBundle = DataBundle.new()
var _file: String
var _exists: Callable


## `file` é o nome que aparece nas falhas. `exists` confere se um caminho res:// existe; o padrão aceita recurso importável ou arquivo (os testes injetam a deles).
func _init(file: String, exists: Callable = Callable()) -> void:
	_file = file
	_exists = exists if exists.is_valid() else _resource_exists


## O objeto raiz do arquivo; {} com o problema registrado se ele faltar, não abrir ou não for um objeto JSON.
func parse_file() -> Dictionary:
	if not FileAccess.file_exists(_file):
		fail("", "", "arquivo não encontrado")
		return {}
	var content: String = FileAccess.get_file_as_string(_file)
	var open_error: Error = FileAccess.get_open_error()
	if open_error != OK:
		fail("", "", "não foi possível ler o arquivo (erro %d)" % open_error)
		return {}
	return parse_json(content)


func parse_json(content: String) -> Dictionary:
	var parser: JSON = JSON.new()
	if parser.parse(content) != OK:
		fail("", "", "JSON inválido na linha %d: %s" % [parser.get_error_line(), parser.get_error_message()])
		return {}
	# Variant é inevitável aqui: é a fronteira com o JSON, conferida logo abaixo.
	var root: Variant = parser.data
	if typeof(root) != TYPE_DICTIONARY:
		fail("", "", "a raiz deve ser um objeto JSON")
		return {}
	var object_root: Dictionary = root
	return object_root


func fail(item: String, field: String, message: String) -> void:
	bundle.add_issue(_file, item, field, message)


## Campo de texto obrigatório e não vazio.
func text(entry: Dictionary, field: String, item: String) -> String:
	var value: Variant = _value_of(entry, field, item, TYPE_STRING, "um texto")
	return "" if value == null else str(value)


## Campo inteiro obrigatório na faixa [low, high]. O JSON entrega todo número como float; aqui ele só passa se for inteiro.
func whole(entry: Dictionary, field: String, item: String, low: int, high: int) -> int:
	var value: Variant = _value_of(entry, field, item, TYPE_FLOAT, "um número inteiro")
	if value == null:
		return low
	var number: float = value
	if number != floorf(number) or number < low or number > high:
		fail(item, field, "esperado um inteiro de %d a %d" % [low, high])
		return low
	return int(number)


## Campo de texto que precisa ser um dos valores aceitos.
func choice(entry: Dictionary, field: String, item: String, allowed: PackedStringArray) -> String:
	var value: String = text(entry, field, item)
	if not value.is_empty() and not allowed.has(value):
		fail(item, field, "'%s' não é um dos valores aceitos (%s)" % [value, ", ".join(allowed)])
	return value


## Campo com um caminho res:// que existe.
func resource(entry: Dictionary, field: String, item: String) -> String:
	var path: String = text(entry, field, item)
	if not path.is_empty():
		_check_path(path, field, item)
	return path


## Campo com uma lista (que pode ser vazia) de caminhos res://, cada um conferido.
func paths(entry: Dictionary, field: String, item: String) -> void:
	var value: Variant = _value_of(entry, field, item, TYPE_ARRAY, "uma lista")
	if value == null:
		return
	var entries: Array = value
	for path: Variant in entries:
		_check_path(str(path), field, item)


func object(entry: Dictionary, field: String, item: String) -> Dictionary:
	var value: Variant = _value_of(entry, field, item, TYPE_DICTIONARY, "um objeto")
	var found: Dictionary = {}
	if value != null:
		found = value
	return found


## Lista obrigatória e não vazia de objetos (as linhas de uma tabela); [] com o problema registrado se faltar ou for outra coisa.
func rows(owner: Dictionary, field: String, item: String) -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	var value: Variant = _value_of(owner, field, item, TYPE_ARRAY, "uma lista")
	if value == null:
		return found
	var entries: Array = value
	if entries.is_empty():
		fail(item, field, "a lista está vazia: é preciso ao menos uma entrada")
	for index: int in entries.size():
		if typeof(entries[index]) == TYPE_DICTIONARY:
			found.append(entries[index])
		else:
			fail("%s[%d]" % [field, index], "", "esperado um objeto")
	return found


## O id de uma linha (texto único na tabela) e o nome dela nas falhas: o próprio id, ou "tabela[índice]" se o id não presta.
func identify(row: Dictionary, table: String, index: int, seen: Dictionary) -> String:
	var item: String = "%s[%d]" % [table, index]
	var id: String = text(row, "id", item)
	if id.is_empty():
		return item
	if seen.has(id):
		fail(id, "id", "id repetido na tabela '%s'" % table)
	seen[id] = true
	return id


## O valor do campo se existir e tiver o tipo pedido; senão registra o problema e devolve null.
func _value_of(entry: Dictionary, field: String, item: String, type: int, kind: String) -> Variant:
	var value: Variant = entry.get(field)
	if value == null:
		fail(item, field, "campo obrigatório ausente")
	elif typeof(value) != type:
		fail(item, field, "tipo inválido: esperado %s" % kind)
	elif type == TYPE_STRING and str(value).strip_edges().is_empty():
		fail(item, field, "o texto está vazio")
	else:
		return value
	return null


func _check_path(path: String, field: String, item: String) -> void:
	var found: bool = path.begins_with(RES_PREFIX) and _exists.call(path)
	if not found:
		fail(item, field, "o arquivo '%s' não existe em res://" % path)


static func _resource_exists(path: String) -> bool:
	return ResourceLoader.exists(path) or FileAccess.file_exists(path)
