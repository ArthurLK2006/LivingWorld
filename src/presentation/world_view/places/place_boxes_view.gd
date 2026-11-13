class_name PlaceBoxesView
extends Node3D
## Construções provisórias (LW-074): uma CAIXA colorida por local (casa, trabalho, descanso, convívio e mercado), com a base na altura do terreno,
## montada pelos dados de `peek_places`. Só visual: sem colisão, texto nem animação; o mercado é só uma caixa sem modelo (LW-105e). Cada caixa fica
## escondida até o terreno do seu chunk existir (`set_chunk_visible`, ligado a `chunk_loaded` e `chunk_unloaded` pela cena), para não
## flutuar no vazio. Um tipo de local pode ser escondido de forma persistente (`set_kind_hidden`): a ART-2b troca a caixa do mercado pela praça (`MarketPlazaView`) e as
## caixas continuam existindo. A view fica na origem do mundo. Contrato: docs/modules/presentation.md.

const BOX_NAME_PREFIX: String = "Box_"
const HALF: float = 0.5

var _boxes: Dictionary[String, MeshInstance3D] = {}
var _boxes_by_chunk: Dictionary[Vector2i, Array] = {}
var _kinds: Dictionary[MeshInstance3D, String] = {}
var _hidden_kinds: Array[String] = []
var _shown_chunks: Dictionary[Vector2i, bool] = {}
## Uma malha (com o material da cor) por tipo, repartida entre as caixas do tipo.
var _meshes: Dictionary[String, BoxMesh] = {}


## Cria uma caixa por local desenhado. Ponte nula, ponte sem terreno ou consulta que falha: push_error e nada é criado (devolve falso).
func setup(bridge: SimBridge) -> bool:
	_clear()
	if bridge == null:
		push_error("PlaceBoxesView.setup: ponte nula; esperado uma SimBridge.")
		return false
	var layout: BridgeReplies.TerrainLayoutReply = bridge.peek_terrain_layout()
	if not layout.result.ok:
		return _fail(layout.result)
	var reply: BridgeReplies.PlacesReply = bridge.peek_places()
	if not reply.result.ok:
		return _fail(reply.result)
	var chunk_size_m: float = float(layout.chunk_cells) * layout.cell_size_m
	for place: BridgeReplies.PlaceReply in reply.places:
		if PlacePalette.is_drawn(place.kind):
			var chunk: Vector2i = Vector2i(clampi(floori(place.x / chunk_size_m), 0, layout.chunk_count.x - 1), clampi(floori(place.z / chunk_size_m), 0, layout.chunk_count.y - 1))
			_add_box(place, chunk)
	return true


## Mostra ou esconde as caixas do chunk (as de tipo escondido nunca aparecem); chunk sem caixa não faz nada.
func set_chunk_visible(chunk: Vector2i, shown: bool) -> void:
	_shown_chunks[chunk] = shown
	for box: MeshInstance3D in _boxes_by_chunk.get(chunk, []):
		box.visible = shown and not _hidden_kinds.has(_kinds[box])


## Esconde (ou volta a mostrar) as caixas de um tipo de local, de forma persistente: as caixas continuam existindo e contando, e `set_chunk_visible` as respeita. Ao voltar a mostrar, só aparecem nos chunks mostrados.
func set_kind_hidden(kind: String, is_hidden: bool) -> void:
	if is_hidden and not _hidden_kinds.has(kind):
		_hidden_kinds.append(kind)
	elif not is_hidden:
		_hidden_kinds.erase(kind)
	for chunk: Vector2i in _boxes_by_chunk:
		set_chunk_visible(chunk, _shown_chunks.get(chunk, false))


func box_count() -> int:
	return _boxes.size()


## A caixa do local, ou nulo se o local não tem caixa.
func box_of(place_id: String) -> MeshInstance3D:
	return _boxes.get(place_id) as MeshInstance3D


func _add_box(place: BridgeReplies.PlaceReply, chunk: Vector2i) -> void:
	var box: MeshInstance3D = MeshInstance3D.new()
	box.name = BOX_NAME_PREFIX + place.id
	box.mesh = _mesh_of(place.kind)
	box.position = Vector3(place.x, place.y + PlacePalette.SIZES[place.kind].y * HALF, place.z)
	box.visible = false
	add_child(box)
	_boxes[place.id] = box
	_kinds[box] = place.kind
	if not _boxes_by_chunk.has(chunk):
		_boxes_by_chunk[chunk] = []
	_boxes_by_chunk[chunk].append(box)


func _mesh_of(kind: String) -> BoxMesh:
	if not _meshes.has(kind):
		var mesh: BoxMesh = BoxMesh.new()
		mesh.size = PlacePalette.SIZES[kind]
		var material: StandardMaterial3D = StandardMaterial3D.new()
		material.albedo_color = PlacePalette.COLORS[kind]
		mesh.material = material
		_meshes[kind] = mesh
	return _meshes[kind]


func _fail(failure: Result) -> bool:
	push_error("PlaceBoxesView.setup: %s (%s)" % [failure.message, failure.code])
	return false


func _clear() -> void:
	for box: MeshInstance3D in _boxes.values():
		remove_child(box)
		box.free()
	_boxes.clear()
	_boxes_by_chunk.clear()
	_kinds.clear()
	_shown_chunks.clear()
