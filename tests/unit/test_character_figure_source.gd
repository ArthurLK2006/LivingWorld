extends GutTest
## ART-12, 7b-2: a fonte das figuras (`CharacterFigureSource`) com figura SINTÉTICA em memória, sem disco de ativo: a figura é preparada UMA vez (empacotada, e a montada liberada) e `make` entrega instâncias distintas e soltas (o metadado de velocidades, o `AnimationPlayer` e os descendentes fundos sobrevivem ao empacotar); área vazia não toca o construtor; id desconhecido, figura recusada e catálogo ausente dão null com o motivo em `failures`; nem o preparo nem as cópias deixam nó órfão; o catálogo LOCAL opcional vale no lugar do padrão (local inválido = falha, sem cair no padrão em silêncio); a área lista seus ids de figura.

const FIGURE_ID: String = "synthetic"
const DEEP_NAME: String = "Deep"
const SPEEDS: Dictionary = {"walk": 0.73, "jog": 4.1}
const CLIPS: PackedStringArray = ["idle", "walk", "jog"]
const AREA_JSON: String = '{"version": 1, "entries": [{"npc_id": 7, "figure": "synthetic"}]}'
const NO_ENTRIES_JSON: String = '{"version": 1, "entries": []}'
const COPIES: int = 20

var _built: Array[String] = []
var _asked: Array[String] = []
var _local_text: String = ""


## O GUT usa uma só instância do script em todos os testes: o estado volta ao zero antes de cada um.
func before_each() -> void:
	_built.clear()
	_asked.clear()
	_local_text = ""


## A figura sintética: o metadado de velocidades, um descendente fundo com malha e um `AnimationPlayer` com os clipes, como o `build` real os entrega (sem dono, como o `build` acrescenta).
func _builder(figure_id: String) -> Node3D:
	_built.append(figure_id)
	var figure: Node3D = Node3D.new()
	figure.set_meta(CharacterFigure.LOCOMOTION_META, SPEEDS.duplicate())
	var deep: Node3D = Node3D.new()
	deep.name = DEEP_NAME
	figure.add_child(deep)
	deep.add_child(MeshInstance3D.new())
	var library: AnimationLibrary = AnimationLibrary.new()
	for clip: String in CLIPS:
		library.add_animation(StringName(clip), Animation.new())
	var player: AnimationPlayer = AnimationPlayer.new()
	figure.add_child(player)
	player.add_animation_library("", library)
	return figure


func _refuse(_figure_id: String) -> Node3D:
	return null


func _exists(_path: String) -> bool:
	return true


## O leitor do catálogo LOCAL: devolve `_local_text` ("" = o arquivo não existe) e anota o que foi pedido.
func _read(path: String) -> String:
	_asked.append(path)
	return _local_text


func _area(json: String) -> CharacterArea:
	return CharacterArea.from_files([CharacterArea.DEFAULT_PATH], func(_path: String) -> String: return json)


func _catalog() -> CharacterCatalog:
	return CharacterCatalog.from_file(CharacterCatalog.DEFAULT_PATH, _exists).catalog


func _local_json() -> String:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CharacterCatalog.DEFAULT_PATH))
	data[CharacterCatalog.FIGURE_TABLE] = [{"id": FIGURE_ID, "scene": "res://art_samples/x.scn", "meta": "res://art_samples/x.json"}]
	return JSON.stringify(data)


func test_the_figure_is_prepared_once_and_make_delivers_distinct_loose_copies_that_keep_the_speeds_the_clips_and_the_deep_nodes() -> void:
	var source: CharacterFigureSource = CharacterFigureSource.prepare(_area(AREA_JSON), _catalog(), _builder)
	assert_eq([_built.size(), source.failures.is_empty()], [1, true], "O construtor roda UMA vez, no preparo.")
	var first: Node3D = autofree(source.make(FIGURE_ID))
	var second: Node3D = autofree(source.make(FIGURE_ID))
	assert_true(first != null and second != null and first != second, "Cada entrada em S0 leva uma instância NOVA.")
	assert_null(first.get_parent(), "A cópia chega solta.")
	assert_eq(_built.size(), 1, "O `make` não monta de novo.")
	var speeds: Dictionary[String, float] = CharacterFigure.locomotion_of(first)
	assert_eq([speeds.get("walk"), speeds.get("jog")], [0.73, 4.1], "O metadado de velocidades sobrevive ao empacotar.")
	var player: AnimationPlayer = first.find_children("*", "AnimationPlayer", false, false)[0] as AnimationPlayer
	for clip: String in CLIPS:
		assert_true(player.has_animation(StringName(clip)), "O clipe %s sobrevive ao empacotar." % clip)
	assert_eq([first.get_node(DEEP_NAME).get_child_count(), first.find_children("*", "MeshInstance3D", true, false).size()], [1, 1], "Os descendentes fundos sobrevivem ao empacotar.")


func test_an_unknown_id_a_refused_figure_and_a_missing_catalog_give_null_with_the_reason() -> void:
	var source: CharacterFigureSource = CharacterFigureSource.prepare(_area(AREA_JSON), _catalog(), _builder)
	assert_null(source.make("outra"), "Id fora da área: sem figura.")
	var refused: CharacterFigureSource = CharacterFigureSource.prepare(_area(AREA_JSON), _catalog(), _refuse)
	assert_eq([refused.make(FIGURE_ID), refused.failures.get(FIGURE_ID)], [null, CharacterFigureSource.BUILDER_FAILED_REASON], "Construtor que recusa: cápsula e o motivo.")
	var real: CharacterFigureSource = CharacterFigureSource.prepare(_area(AREA_JSON), _catalog())
	assert_string_contains(String(real.failures.get(FIGURE_ID, "")), "não está no catálogo", "Sem construtor injetado vale o `build` real, que diz o motivo.")
	_built.clear()
	for catalog: CharacterCatalog in [null, CharacterCatalog.new()]:
		var blind: CharacterFigureSource = CharacterFigureSource.prepare(_area(AREA_JSON), catalog, _builder)
		assert_eq([blind.make(FIGURE_ID), blind.failures.get(FIGURE_ID), _built.size()], [null, CharacterFigureSource.NO_CATALOG_REASON, 0], "Sem catálogo: cápsula, o motivo e o construtor intocado.")


func test_an_empty_or_null_area_builds_nothing_and_touches_neither_the_builder_nor_the_catalog() -> void:
	for area: CharacterArea in [_area(NO_ENTRIES_JSON), null]:
		var source: CharacterFigureSource = CharacterFigureSource.prepare(area, null, _builder)
		assert_eq([source.failures.is_empty(), source.make(FIGURE_ID), _built.size()], [true, null, 0], "Fonte vazia, sem falha.")


func test_neither_the_preparation_nor_the_copies_leave_an_orphan_node() -> void:
	var before: int = int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
	var source: CharacterFigureSource = CharacterFigureSource.prepare(_area(AREA_JSON), _catalog(), _builder)
	assert_eq(int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)), before, "Preparado, a figura montada foi liberada: nenhum nó órfão.")
	for _copy: int in COPIES:
		source.make(FIGURE_ID).free()
	assert_eq(int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)), before, "As cópias liberadas não deixam nó órfão.")


func test_the_local_catalog_replaces_the_default_and_an_invalid_one_is_a_failure_not_a_fallback() -> void:
	var absent: CharacterCatalog.LoadResult = CharacterFigureSource.load_catalog(_read, _exists)
	assert_eq([absent.result.ok, absent.catalog.is_ready(), absent.catalog.figure(FIGURE_ID).is_empty(), _asked], [true, true, true, [CharacterFigureSource.LOCAL_CATALOG_PATH]], "Sem o local vale o padrão, que não tem a figura.")
	_local_text = _local_json()
	var local: CharacterCatalog.LoadResult = CharacterFigureSource.load_catalog(_read, _exists)
	assert_eq([local.result.ok, local.catalog.figure(FIGURE_ID).is_empty()], [true, false], "O local, com a lista `figures`, vale no lugar do padrão.")
	_local_text = "{"
	var broken: CharacterCatalog.LoadResult = CharacterFigureSource.load_catalog(_read, _exists)
	assert_eq([broken.result.code, broken.catalog.is_ready()], [CharacterCatalog.CODE_INVALID, false], "Local inválido = falha tratada, sem cair no padrão.")


func test_the_area_lists_its_figure_ids() -> void:
	assert_eq([Array(_area(AREA_JSON).figure_ids()), _area(NO_ENTRIES_JSON).figure_ids().size()], [[FIGURE_ID], 0], "Os ids da área, e nenhum na vazia.")
