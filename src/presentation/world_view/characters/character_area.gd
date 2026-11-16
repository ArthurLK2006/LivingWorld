class_name CharacterArea
extends RefCounted
## A área controlada das figuras inteiras no mundo (ART-12, entrega 7a; só apresentação): diz qual NPC (`npc_id`) usa qual figura (`figure`, um id da lista `figures` do character_catalog.json) no lugar da cápsula. Formato (JSON): `{"version": 1, "entries": [{"npc_id": <inteiro de MIN_NPC_ID a MAX_NPC_ID, a faixa do IdGenerator>, "figure": "<id>"}]}`; no máximo `MAX_ENTRIES` entrada(s) [HIP]: a área é para UM NPC de teste, e mais que isso é falha tratada (para não virar adoção em massa). Sem entrada, sem arquivo ou com falha, TODO NPC segue cápsula, como hoje. DOIS arquivos: o dado `DEFAULT_PATH` (padrão VAZIO, no Git) e o LOCAL `LOCAL_PATH` (mesmo formato, FORA do Git). `from_files(paths)` lê o PRIMEIRO caminho da lista com texto não vazio e esse arquivo decide: o local, se existir, vale no lugar do padrão; se ele for inválido a área é VAZIA com `failure` e NÃO cai no padrão (a falha tem de aparecer, e cair em silêncio no padrão esconderia o erro de quem editou o local); arquivo ausente ou vazio (o leitor devolve "" nos dois casos) conta como ausente; nenhum com texto = área vazia, sem falha. Os caminhos são CONSTANTES do código, nunca vêm de dado (AGENTS 12.6): `from_files` ainda recusa, sem ler nada, o que não é res:// ou tem o segmento `..` (AGENTS 4.16; a mesma regra de `CharacterCatalog._stays_in_project`, que é privada). Qualquer problema vira UMA falha tratada no formato dos outros carregadores (arquivo | item | campo | mensagem; item `entries[i]` quando o problema é de uma entrada, sem item nos do arquivo inteiro: versão, campo da raiz e entradas demais) e a área devolvida fica VAZIA: nunca lança erro nem escreve no log. Só dados simples: nada do arquivo é executado. `text_reader(path: String) -> String` troca a leitura do disco ("" se o arquivo não existe), para os testes não tocarem o disco nem `user://` (AGENTS 4.16 e 9.4). Contrato: docs/modules/presentation.md.

const DEFAULT_PATH: String = "res://data/presentation/character_area.json"
const LOCAL_PATH: String = "res://art_samples/character_area.json"
const SUPPORTED_VERSION: int = 1
const ENTRIES: String = "entries"
const ROOT_FIELDS: PackedStringArray = ["version", ENTRIES]
const ENTRY_FIELDS: PackedStringArray = ["npc_id", "figure"]
const PARENT_SEGMENT: String = ".."
## [HIP] O máximo de entradas: a área é para UM NPC de teste controlado.
const MAX_ENTRIES: int = 1
## A faixa de um `npc_id` é a dos IDs de entidade do repositório (`IdGenerator`, arquitetura 7.3): do primeiro ID real (1: o 0 é `NO_ID`, "sem ID", e nunca é um NPC) ao máximo, 2^53 - 1, o maior inteiro que o JSON (todo número é real) lê sem perder exatidão.
const MIN_NPC_ID: int = IdGenerator.FIRST_ID
const MAX_NPC_ID: int = IdGenerator.MAX_ID

## O motivo da falha ("" se os arquivos eram válidos ou não existiam).
var failure: String = ""
var _figures: Dictionary[int, String] = {}


## A área do jogo: o arquivo LOCAL, se existir, no lugar do dado padrão.
static func load_default(text_reader: Callable = Callable()) -> CharacterArea:
	return from_files([LOCAL_PATH, DEFAULT_PATH], text_reader)


## Lê o PRIMEIRO caminho de `paths` que tem texto (ver o cabeçalho). Sem `text_reader`, o arquivo vem do disco.
static func from_files(paths: Array[String], text_reader: Callable = Callable()) -> CharacterArea:
	var read: Callable = text_reader if text_reader.is_valid() else _read_text
	for path: String in paths:
		var reader: CharacterDataReader = CharacterDataReader.new(path)
		if not _stays_in_project(path):
			reader.fail("", "", "o caminho deve começar com %s e não pode ter o segmento '%s'" % [CharacterDataReader.RES_PREFIX, PARENT_SEGMENT])
			return _failed(reader)
		var content: String = read.call(path)
		if content.strip_edges().is_empty():
			continue
		var root: Dictionary = reader.parse_json(content)
		var area: CharacterArea = CharacterArea.new()
		if reader.bundle.is_valid():
			area._read(reader, root)
		return area if reader.bundle.is_valid() else _failed(reader)
	return CharacterArea.new()


## O id da figura do NPC `npc_id`, ou "" se ele não está na área (segue cápsula).
func figure_for(npc_id: int) -> String:
	return _figures[npc_id] if _figures.has(npc_id) else ""


## Nenhuma entrada: todo NPC segue cápsula.
func is_empty() -> bool:
	return _figures.is_empty()


## Os ids de figura da área (a fonte da figura, 7b-2, prepara cada um UMA vez). Com `MAX_ENTRIES` = 1 não há id repetido nem ordem a manter.
func figure_ids() -> PackedStringArray:
	return PackedStringArray(_figures.values())


## Confere o objeto raiz e guarda as entradas; os problemas vão para `reader`.
func _read(reader: CharacterDataReader, root: Dictionary) -> void:
	for field: String in root:
		if not ROOT_FIELDS.has(field):
			reader.fail("", field, "campo desconhecido na raiz do arquivo")
	reader.whole(root, "version", "", SUPPORTED_VERSION, SUPPORTED_VERSION)
	var listed: Variant = root.get(ENTRIES)  # Variant: fronteira com o JSON, conferido logo abaixo
	if typeof(listed) == TYPE_ARRAY and (listed as Array).is_empty():
		return
	var rows: Array[Dictionary] = reader.rows(root, ENTRIES, "")
	if rows.size() > MAX_ENTRIES:
		reader.fail("", ENTRIES, "entradas demais: %d (no máximo %d)" % [rows.size(), MAX_ENTRIES])
	for index: int in rows.size():
		_read_entry(reader, rows[index], "%s[%d]" % [ENTRIES, index])


## Confere uma entrada (campos conhecidos, `npc_id` inteiro e único, `figure` texto) e a guarda se ela está inteira certa.
func _read_entry(reader: CharacterDataReader, row: Dictionary, item: String) -> void:
	for field: String in row:
		if not ENTRY_FIELDS.has(field):
			reader.fail(item, field, "campo desconhecido na entrada")
	var problems: int = reader.bundle.issues.size()
	var npc_id: int = reader.whole(row, "npc_id", item, MIN_NPC_ID, MAX_NPC_ID)
	var figure: String = reader.text(row, "figure", item)
	if reader.bundle.issues.size() > problems:
		return
	if _figures.has(npc_id):
		reader.fail(item, "npc_id", "npc_id %d repetido" % npc_id)
	_figures[npc_id] = figure


## A área vazia com a falha do `reader`.
static func _failed(reader: CharacterDataReader) -> CharacterArea:
	var area: CharacterArea = CharacterArea.new()
	area.failure = reader.bundle.describe_issues()
	return area


## O caminho é res:// e nunca sobe de pasta: nenhum segmento `..`, nem escrito com `\` (o Godot a trata como `/`).
static func _stays_in_project(path: String) -> bool:
	return path.begins_with(CharacterDataReader.RES_PREFIX) and not path.replace("\\", "/").split("/").has(PARENT_SEGMENT)


## O texto do arquivo do disco; "" se ele não existe.
static func _read_text(path: String) -> String:
	return FileAccess.get_file_as_string(path) if FileAccess.file_exists(path) else ""
