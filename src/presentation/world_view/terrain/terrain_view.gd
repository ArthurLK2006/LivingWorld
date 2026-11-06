class_name TerrainView
extends Node3D
## Terreno desenhado: um MeshInstance3D por chunk, filhos desta view. Lê tudo SÓ pela ponte (setup recebe a
## SimBridge) e é só apresentação (DEC-057 c): nada aqui é salvo. Os chunks entram numa fila, do mais perto do
## ponto de nascimento ao mais longe, e são construídos aos poucos, dentro de um orçamento de milissegundos por
## quadro, para não engasgar (DEC-057 a). Contrato: docs/modules/presentation.md.

## Orçamento de construção por quadro [HIP]; sempre sai ao menos um chunk por quadro.
const FRAME_BUDGET_MS: float = 4.0
const USEC_PER_MS: float = 1000.0
## Nível de detalhe usado pelo jogo nesta tarefa; a escolha por distância é da LW-040.
const GAME_STEP: int = TerrainChunkBuilder.STEP_FINE
## Centro de um chunk, em chunks, a partir do canto de menor x e z (para ordenar a fila por distância).
const CHUNK_CENTER: Vector2 = Vector2(0.5, 0.5)

var _builder: TerrainChunkBuilder
var _material: StandardMaterial3D
## Fila de chunks a construir: o mais PERTO do foco fica no fim (sai com pop_back).
var _pending: Array[Vector2i] = []
var _chunks: Dictionary[Vector2i, MeshInstance3D] = {}
var _vertex_counts: Dictionary[Vector2i, int] = {}


## Liga a view à ponte e monta a fila de construção. Ponte nula ou sem terreno: push_error e nada é construído.
func setup(bridge: SimBridge) -> void:
	_clear()
	if bridge == null:
		push_error("TerrainView.setup: ponte nula; esperado uma SimBridge.")
		return
	var layout: SimBridge.TerrainLayoutReply = bridge.peek_terrain_layout()
	if not layout.result.ok:
		push_error("TerrainView.setup: formato do terreno indisponível (%s): %s" % [layout.result.code, layout.result.message])
		return
	var spawn: SimBridge.SpawnReply = bridge.peek_spawn_point()
	_builder = TerrainChunkBuilder.new(bridge, layout)
	_material = _make_material()
	_pending = _queue_from_far_to_near(layout, Vector2(spawn.point.x, spawn.point.z))
	set_process(true)


## Constrói (ou reconstrói) um chunk agora, com o passo dado. Devolve falso, depois de push_error, se falhar.
func build_chunk(coord: Vector2i, step: int = GAME_STEP) -> bool:
	if _builder == null:
		push_error("TerrainView.build_chunk: view sem terreno; esperado chamar setup com uma ponte válida.")
		return false
	var mesh: ArrayMesh = _builder.build(coord, step)
	if mesh == null:
		return false
	var node: MeshInstance3D = _chunks.get(coord)
	if node == null:
		node = MeshInstance3D.new()
		node.name = "Chunk_%d_%d" % [coord.x, coord.y]
		node.position = _builder.chunk_origin_m(coord)
		node.material_override = _material
		add_child(node)
		_chunks[coord] = node
	node.mesh = mesh
	_vertex_counts[coord] = mesh.surface_get_array_len(0)
	_pending.erase(coord)
	return true


## Constrói até `count` chunks da fila, do mais perto ao mais longe. Devolve quantos foram construídos.
func process_chunks(count: int) -> int:
	var built: int = 0
	var tried: int = 0
	while tried < count and not _pending.is_empty():
		tried += 1
		if build_chunk(_pending[_pending.size() - 1]):
			built += 1
		else:
			_pending.pop_back()
	return built


## Constrói chunks da fila até gastar `budget_ms`, e ao menos um. Devolve quantos foram construídos.
func process_budget(budget_ms: float) -> int:
	var start_usec: int = Time.get_ticks_usec()
	var built: int = 0
	var tried: int = 0
	while not _pending.is_empty() and (tried == 0 or float(Time.get_ticks_usec() - start_usec) / USEC_PER_MS < budget_ms):
		tried += 1
		built += process_chunks(1)
	return built


func built_count() -> int:
	return _chunks.size()


func pending_count() -> int:
	return _pending.size()


## Soma dos vértices das malhas já construídas (diagnóstico).
func total_vertex_count() -> int:
	var total: int = 0
	for count: int in _vertex_counts.values():
		total += count
	return total


func has_chunk(coord: Vector2i) -> bool:
	return _chunks.has(coord)


func chunk_node(coord: Vector2i) -> MeshInstance3D:
	return _chunks.get(coord)


func _process(_delta: float) -> void:
	process_budget(FRAME_BUDGET_MS)
	if _pending.is_empty():
		set_process(false)


func _clear() -> void:
	for node: MeshInstance3D in _chunks.values():
		remove_child(node)
		node.free()
	_chunks.clear()
	_vertex_counts.clear()
	_pending.clear()
	_builder = null


## Um só material para o terreno todo: a cor vem do vértice. Marcada como sRGB para a cor aparecer como se
## escolhe no seletor de cores (as cores da paleta são [HIP], ajustadas olhando a tela).
func _make_material() -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	return material


## Todos os chunks, ordenados do mais LONGE para o mais perto do foco (x, z em metros); empate pela posição.
func _queue_from_far_to_near(layout: SimBridge.TerrainLayoutReply, focus: Vector2) -> Array[Vector2i]:
	var chunk_size_m: float = float(layout.chunk_cells) * layout.cell_size_m
	var queue: Array[Vector2i] = []
	for chunk_z: int in range(layout.chunk_count.y):
		for chunk_x: int in range(layout.chunk_count.x):
			queue.append(Vector2i(chunk_x, chunk_z))
	queue.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		var distance_a: float = ((Vector2(a) + CHUNK_CENTER) * chunk_size_m).distance_squared_to(focus)
		var distance_b: float = ((Vector2(b) + CHUNK_CENTER) * chunk_size_m).distance_squared_to(focus)
		if distance_a != distance_b:
			return distance_a > distance_b
		return a.y * layout.chunk_count.x + a.x > b.y * layout.chunk_count.x + b.x)
	return queue
