class_name CharacterFigureSource
extends RefCounted
## A fonte das figuras inteiras do mundo (ART-12, 7b-2; só apresentação): prepara UMA vez, antes do laço do jogo, a figura de cada id distinto da área (`CharacterArea.figure_ids`, no máximo 1 [HIP]) com `CharacterFigure.build` (a primeira carga de arquivo levou 545 ms e não pode cair num quadro) e guarda o protótipo FORA da árvore; `make(figure_id)` entrega uma instância NOVA (`duplicate`) a cada entrada em S0, e os protótipos são liberados quando a fonte morre (o corpo é dono só da cópia). Figura que o `build` recusa, ou falta de catálogo, não lança erro: o id entra em `failures` (id -> motivo curto) e `make` devolve null (o NPC segue cápsula). Área vazia = fonte vazia, sem tocar em disco nem em catálogo. O catálogo vem de `load_catalog`: o LOCAL `LOCAL_CATALOG_PATH` (FORA do Git, o mesmo formato do padrão com a lista `figures`; o padrão não a tem, e a linha do Ice Warrior exige caminhos res:// que só existem onde há o ativo) no lugar do padrão, se existir. `builder(figure_id) -> Node3D` troca a montagem (os testes injetam uma figura sintética, sem disco). Contrato: docs/modules/presentation.md.

const LOCAL_CATALOG_PATH: String = "res://art_samples/character_catalog.json"
const NO_CATALOG_REASON: String = "não há catálogo de figuras para ler"
const BUILDER_FAILED_REASON: String = "o construtor não devolveu a figura"

## id da figura -> o motivo curto de ela não ter sido preparada.
var failures: Dictionary[String, String] = {}
var _prototypes: Dictionary[String, Node3D] = {}


## Prepara a figura de cada id da `area`. Sem `builder`, a montagem é a real (`CharacterFigure.build` com o `catalog`).
static func prepare(area: CharacterArea, catalog: CharacterCatalog, builder: Callable = Callable()) -> CharacterFigureSource:
	var source: CharacterFigureSource = CharacterFigureSource.new()
	if area == null or area.is_empty():
		return source
	for figure_id: String in area.figure_ids():
		if catalog == null or not catalog.is_ready():
			source.failures[figure_id] = NO_CATALOG_REASON
		else:
			source._prepare_one(catalog, figure_id, builder)
	return source


## O catálogo das figuras: o LOCAL, se o arquivo existe (texto não vazio), no lugar do padrão. Um local INVÁLIDO é falha tratada (`result` não ok e catálogo vazio) e NÃO cai no padrão: a falha tem de aparecer, como na área. `text_reader(path) -> String` troca a leitura do disco ("" se não existe) e `exists`, a conferência dos caminhos res:// do catálogo, para os testes.
static func load_catalog(text_reader: Callable = Callable(), exists: Callable = Callable()) -> CharacterCatalog.LoadResult:
	var read: Callable = text_reader if text_reader.is_valid() else _read_text
	var content: String = read.call(LOCAL_CATALOG_PATH)
	if content.strip_edges().is_empty():
		return CharacterCatalog.from_file(CharacterCatalog.DEFAULT_PATH, exists)
	return CharacterCatalog.from_json(content, LOCAL_CATALOG_PATH, exists)


## Uma instância NOVA e solta da figura `figure_id` (quem a recebe é dono dela), ou null se o id não tem protótipo (a montagem falhou ou ele não está na área).
func make(figure_id: String) -> Node3D:
	var prototype: Node3D = _prototypes.get(figure_id) as Node3D
	return prototype.duplicate() as Node3D if prototype != null else null


func _prepare_one(catalog: CharacterCatalog, figure_id: String, builder: Callable) -> void:
	var assembler: CharacterFigure = CharacterFigure.new()
	var figure: Node3D = builder.call(figure_id) as Node3D if builder.is_valid() else assembler.build(catalog, figure_id)
	if figure != null:
		_prototypes[figure_id] = figure
	else:
		failures[figure_id] = assembler.failure if not assembler.failure.is_empty() else BUILDER_FAILED_REASON


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		for prototype: Node3D in _prototypes.values():
			if is_instance_valid(prototype):
				prototype.free()


## O texto do arquivo do disco; "" se ele não existe.
static func _read_text(path: String) -> String:
	return FileAccess.get_file_as_string(path) if FileAccess.file_exists(path) else ""
