class_name CharacterFigureSource
extends RefCounted
## A fonte das figuras inteiras do mundo (ART-12, 7b-2; só apresentação): prepara UMA vez, antes do laço do jogo, a figura de cada id da área (`CharacterArea.figure_ids`, no máximo 1 [HIP]) com `CharacterFigure.build` (a primeira carga de arquivo levou 545 ms e não pode cair num quadro), EMPACOTA a figura montada (`PackedScene.pack`) e libera a montada (nada fica órfão); `make(figure_id)` entrega uma instância NOVA (`instantiate`) a cada entrada em S0 (o corpo é dono só da cópia). Empacotar, e não `duplicate` da figura montada, porque o `duplicate` do `BoneAttachment3D` (a espada da 6d) emite um aviso do motor por cópia (`set_bone_idx`) e o GUT o trata como erro; as cópias COMPARTILHAM a biblioteca de animação, a malha e a pele, e cada uma leva o seu `AnimationPlayer`, o seu esqueleto e as suas propriedades e metadados (o `locomotion`). Figura que o `build` recusa, ou falta de catálogo, não lança erro: o id entra em `failures` (id -> motivo curto) e `make` devolve null (o NPC segue cápsula). Área vazia = fonte vazia, sem tocar em disco nem em catálogo. O catálogo vem de `load_catalog`: o LOCAL `LOCAL_CATALOG_PATH` (FORA do Git, o mesmo formato do padrão com a lista `figures`; o padrão não a tem, e a linha do Ice Warrior exige caminhos res:// que só existem onde há o ativo) no lugar do padrão, se existir. `builder(figure_id) -> Node3D` troca a montagem (os testes injetam uma figura sintética, sem disco). Quem a entrega a uma view tem de saber que `make` (um `Callable` de método) NÃO segura esta fonte: ver `NpcBodiesView`. Contrato: docs/modules/presentation.md.

const LOCAL_CATALOG_PATH: String = "res://art_samples/character_catalog.json"
const NO_CATALOG_REASON: String = "não há catálogo de figuras para ler"
const BUILDER_FAILED_REASON: String = "o construtor não devolveu a figura"
const PACK_FAILED_REASON: String = "a figura montada não pôde ser empacotada"

## id da figura -> o motivo curto de ela não ter sido preparada.
var failures: Dictionary[String, String] = {}
var _packed: Dictionary[String, PackedScene] = {}


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


## Uma instância NOVA e solta da figura `figure_id` (quem a recebe é dono dela), ou null se o id não tem figura preparada (a montagem falhou ou ele não está na área).
func make(figure_id: String) -> Node3D:
	var packed: PackedScene = _packed.get(figure_id) as PackedScene
	return packed.instantiate() as Node3D if packed != null else null


## Monta a figura, empacota e libera a montada. O `pack` só leva os nós cujo dono é a raiz, e os que o `build` acrescenta (o `AnimationPlayer`, a espada) chegam sem dono: todos os descendentes passam a ser da raiz antes de empacotar.
func _prepare_one(catalog: CharacterCatalog, figure_id: String, builder: Callable) -> void:
	var assembler: CharacterFigure = CharacterFigure.new()
	var figure: Node3D = builder.call(figure_id) as Node3D if builder.is_valid() else assembler.build(catalog, figure_id)
	if figure == null:
		failures[figure_id] = assembler.failure if not assembler.failure.is_empty() else BUILDER_FAILED_REASON
		return
	for node: Node in figure.find_children("*", "", true, false):
		node.owner = figure
	var packed: PackedScene = PackedScene.new()
	if packed.pack(figure) == OK:
		_packed[figure_id] = packed
	else:
		failures[figure_id] = PACK_FAILED_REASON
	figure.free()


## O texto do arquivo do disco; "" se ele não existe.
static func _read_text(path: String) -> String:
	return FileAccess.get_file_as_string(path) if FileAccess.file_exists(path) else ""
