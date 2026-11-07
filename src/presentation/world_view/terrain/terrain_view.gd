class_name TerrainView
extends Node3D
## Terreno desenhado: um MeshInstance3D por chunk, filhos desta view. Lê tudo SÓ pela ponte (setup recebe a SimBridge) e é só
## apresentação (DEC-057 c): nada aqui é salvo. Com um FOCO (set_focus, LW-040) só existem os chunks em volta dele: os mais
## perto com malha fina e colisão, os outros com malha grossa e sem colisão (TerrainStreaming decide). Sem foco a view constrói
## todos os chunks no passo fino, com colisão (modo completo da LW-038). As tarefas (criar um corpo de colisão, construir uma
## malha ou liberar um chunk, nesta prioridade, em TerrainWorkQueue) rodam aos poucos, dentro de um orçamento de milissegundos
## por quadro, para não engasgar (DEC-057 a). Contrato: docs/modules/presentation.md.

## Avisa quem acompanha o terreno (a decoração) quando um chunk passa a existir e quando é liberado.
signal chunk_loaded(coord: Vector2i)
signal chunk_unloaded(coord: Vector2i)

## Orçamento de trabalho por quadro [HIP]; sempre sai ao menos uma tarefa por quadro.
const FRAME_BUDGET_MS: float = 4.0
const USEC_PER_MS: float = 1000.0
## Nível de detalhe do modo completo (sem foco).
const GAME_STEP: int = TerrainChunkBuilder.STEP_FINE
## Camada de física do terreno (número de 1 a 32) [HIP]: a primeira. Quem andar sobre o terreno (LW-045) usa esta
## camada na máscara. O corpo do terreno não procura nada (máscara 0).
const TERRAIN_PHYSICS_LAYER: int = 1
const COLLISION_BODY_NAME: String = "Collision"
## Quanto o foco precisa andar (m) para refazer o plano [HIP]; a histerese cobre o que fica no meio do caminho.
const DEFAULT_REPLAN_MOVE_M: float = 4.0
## Quadros de física até um corpo novo valer para quem anda: o servidor de física só o incorpora no passo seguinte.
const COLLISION_SETTLE_PHYSICS_FRAMES: int = 2

## Raios e histerese da carga por distância. Pública para os testes (e a cena) ajustarem.
var streaming: TerrainStreaming = TerrainStreaming.new()
## Quanto o foco precisa andar para a view refazer o plano; 0 refaz a cada set_focus.
var replan_move_m: float = DEFAULT_REPLAN_MOVE_M
## Diagnóstico (ms): tempo gasto pela última chamada de process_budget que fez trabalho e o maior já visto. Servem para
## separar o que é do terreno do que é do resto do quadro ao medir engasgos.
var last_work_ms: float = 0.0
var max_work_ms: float = 0.0

var _builder: TerrainChunkBuilder
var _layout: BridgeReplies.TerrainLayoutReply
var _material: StandardMaterial3D
var _queue: TerrainWorkQueue = TerrainWorkQueue.new()
var _chunks: Dictionary[Vector2i, MeshInstance3D] = {}
var _chunk_steps: Dictionary[Vector2i, int] = {}
var _vertex_counts: Dictionary[Vector2i, int] = {}
## Quadro de física em que cada corpo de colisão entrou na cena.
var _body_frames: Dictionary[Vector2i, int] = {}
var _is_streaming: bool = false
var _focus_m: Vector2 = Vector2.ZERO
var _planned_focus_m: Vector2 = Vector2.ZERO


## Liga a view à ponte e enfileira todos os chunks (modo completo, do mais perto do ponto de nascimento); o primeiro set_focus
## troca essa fila pela do foco. Ponte nula ou sem terreno: push_error e nada é construído.
func setup(bridge: SimBridge) -> void:
	_clear()
	if bridge == null:
		push_error("TerrainView.setup: ponte nula; esperado uma SimBridge.")
		return
	var layout: BridgeReplies.TerrainLayoutReply = bridge.peek_terrain_layout()
	if not layout.result.ok:
		push_error("TerrainView.setup: formato do terreno indisponível (%s): %s" % [layout.result.code, layout.result.message])
		return
	var spawn: BridgeReplies.SpawnReply = bridge.peek_spawn_point()
	_layout = layout
	_builder = TerrainChunkBuilder.new(bridge, layout)
	_material = _make_material()
	var all_chunks: Array[Vector2i] = []
	for chunk_z: int in range(layout.chunk_count.y):
		for chunk_x: int in range(layout.chunk_count.x):
			all_chunks.append(Vector2i(chunk_x, chunk_z))
	_queue.schedule_all(all_chunks, Vector2(spawn.point.x, spawn.point.z), _chunk_size_m(), layout.chunk_count.x)
	set_process(true)


## Informa o foco (onde está o jogador ou a câmera): só os chunks em volta dele existem. O foco é limitado ao mapa, sem erro.
## A fila é SUBSTITUÍDA: o que ficou fora do raio sai dela antes de ser construído e o mais perto sai primeiro.
func set_focus(position_m: Vector3) -> void:
	if _builder == null:
		push_error("TerrainView.set_focus: view sem terreno; esperado chamar setup com uma ponte válida antes.")
		return
	if not (is_finite(position_m.x) and is_finite(position_m.z)):
		push_error("TerrainView.set_focus: posição não numérica (x=%s, z=%s); esperado número finito." % [str(position_m.x), str(position_m.z)])
		return
	_focus_m = Vector2(clampf(position_m.x, 0.0, _layout.size_m.x), clampf(position_m.z, 0.0, _layout.size_m.y))
	if _is_streaming and _planned_focus_m.distance_to(_focus_m) < replan_move_m:
		return
	_is_streaming = true
	_planned_focus_m = _focus_m
	var plan: TerrainStreaming.Plan = streaming.plan(_layout.chunk_count, _chunk_size_m(), _focus_m, _chunk_steps)
	_queue.schedule(plan, _chunk_steps, _focus_m, _chunk_size_m(), _layout.chunk_count.x)
	set_process(_queue.has_work())


## Constrói (ou reconstrói) um chunk agora, com o passo dado. Chunk novo ganha corpo de colisão em resolução cheia; o corpo de um
## chunk que já existe não muda. Devolve falso, depois de push_error, se falhar.
func build_chunk(coord: Vector2i, step: int = GAME_STEP) -> bool:
	return _build(coord, step, false)


## Faz até `count` construções de malha da fila, do mais perto ao mais longe. Devolve quantos chunks foram construídos.
func process_chunks(count: int) -> int:
	var built: int = 0
	var tried: int = 0
	while tried < count and _queue.mesh_count() > 0:
		tried += 1
		var coord: Vector2i = _queue.next_mesh()
		if _build(coord, _queue.wanted_step(coord, GAME_STEP), _is_streaming):
			built += 1
		else:
			_queue.finish_mesh(coord)
	return built


## Faz tarefas (criar um corpo de colisão, senão construir uma malha, senão liberar um chunk) até gastar `budget_ms`, e ao menos
## uma. Devolve quantas malhas de chunk foram construídas.
func process_budget(budget_ms: float) -> int:
	var start_usec: int = Time.get_ticks_usec()
	var built: int = 0
	var tried: int = 0
	while _queue.has_work() and (tried == 0 or float(Time.get_ticks_usec() - start_usec) / USEC_PER_MS < budget_ms):
		tried += 1
		match _queue.next_kind():
			TerrainWorkQueue.Kind.COLLISION:
				_build_collision(_queue.pop_collision())
			TerrainWorkQueue.Kind.MESH:
				built += process_chunks(1)
			TerrainWorkQueue.Kind.FREE:
				_unload(_queue.pop_free())
	if tried > 0:
		last_work_ms = float(Time.get_ticks_usec() - start_usec) / USEC_PER_MS
		max_work_ms = maxf(max_work_ms, last_work_ms)
	return built


func built_count() -> int:
	return _chunks.size()


## Malhas de chunk na fila de construção.
func pending_count() -> int:
	return _queue.mesh_count()


## Chunks carregados que ainda esperam para ser liberados.
func free_pending_count() -> int:
	return _queue.free_count()


## Chunks de malha fina que ainda esperam o corpo de colisão (só no modo de foco).
func collision_pending_count() -> int:
	return _queue.collision_count()


## Soma dos vértices das malhas já construídas (diagnóstico).
func total_vertex_count() -> int:
	var total: int = 0
	for count: int in _vertex_counts.values():
		total += count
	return total


func has_chunk(coord: Vector2i) -> bool:
	return _chunks.has(coord)


## Passo da malha do chunk (TerrainChunkBuilder.STEP_*), ou TerrainStreaming.ABSENT se ele não existe.
func chunk_step(coord: Vector2i) -> int:
	return _chunk_steps.get(coord, TerrainStreaming.ABSENT)


func loaded_chunks() -> Array[Vector2i]:
	var coords: Array[Vector2i] = []
	coords.assign(_chunks.keys())
	return coords


func chunk_node(coord: Vector2i) -> MeshInstance3D:
	return _chunks.get(coord)


## Corpo de colisão do chunk (filho do nó do chunk: liberar o chunk libera o corpo), ou nulo se não existir.
func chunk_body(coord: Vector2i) -> StaticBody3D:
	var node: MeshInstance3D = _chunks.get(coord)
	if node == null:
		return null
	return node.get_node_or_null(COLLISION_BODY_NAME) as StaticBody3D


## Foco atual, já limitado ao mapa (x, z em metros).
func focus() -> Vector2:
	return _focus_m


## Verdadeiro quando o chunk sob a posição já tem colisão que vale para quem anda: tem corpo e já passaram
## COLLISION_SETTLE_PHYSICS_FRAMES quadros de física desde que o corpo entrou na cena. O PlayerBody usa isto para não cair
## antes de o chão existir. Posição fora do mapa conta como o chunk mais próximo.
func has_collision_at(position_m: Vector3) -> bool:
	if _layout == null:
		return false
	var size_m: float = _chunk_size_m()
	var coord: Vector2i = Vector2i(clampi(floori(position_m.x / size_m), 0, _layout.chunk_count.x - 1), clampi(floori(position_m.z / size_m), 0, _layout.chunk_count.y - 1))
	return _body_frames.has(coord) and Engine.get_physics_frames() >= _body_frames[coord] + COLLISION_SETTLE_PHYSICS_FRAMES


func _process(_delta: float) -> void:
	process_budget(FRAME_BUDGET_MS)
	if not _queue.has_work():
		set_process(false)


func _chunk_size_m() -> float:
	return float(_layout.chunk_cells) * _layout.cell_size_m


## Constrói o chunk com o passo dado. `bodies_follow_step` (modo de foco): só o passo fino tem corpo de colisão, criado numa tarefa
## à parte (_build_collision) ou liberado conforme o passo; senão chunk novo ganha corpo na hora e chunk existente guarda o que tem.
func _build(coord: Vector2i, step: int, bodies_follow_step: bool) -> bool:
	if _builder == null:
		push_error("TerrainView.build_chunk: view sem terreno; esperado chamar setup com uma ponte válida.")
		return false
	var mesh: ArrayMesh = _builder.build(coord, step)
	if mesh == null:
		return false
	var node: MeshInstance3D = _chunks.get(coord)
	var is_new: bool = node == null
	var has_body: bool = _body_frames.has(coord)
	var wants_body: bool = step == TerrainChunkBuilder.STEP_FINE if bodies_follow_step else (is_new or has_body)
	var body: StaticBody3D = null
	if wants_body and not has_body and not bodies_follow_step:
		body = _make_collision_body(coord)
		if body == null:
			return false
	if is_new:
		node = MeshInstance3D.new()
		node.name = "Chunk_%d_%d" % [coord.x, coord.y]
		node.position = _builder.chunk_origin_m(coord)
		node.material_override = _material
	node.mesh = mesh
	if body != null:
		node.add_child(body)
		_body_frames[coord] = Engine.get_physics_frames()
	elif has_body and not wants_body:
		var old_body: StaticBody3D = node.get_node_or_null(COLLISION_BODY_NAME) as StaticBody3D
		node.remove_child(old_body)
		old_body.free()
		_body_frames.erase(coord)
	if not wants_body:
		_queue.cancel_collision(coord)
	elif bodies_follow_step and not has_body:
		_queue.queue_collision(coord)
	if is_new:
		add_child(node)
		_chunks[coord] = node
	_chunk_steps[coord] = step
	_vertex_counts[coord] = mesh.surface_get_array_len(0)
	_queue.finish_mesh(coord)
	if is_new:
		chunk_loaded.emit(coord)
	return true


## Cria o corpo de colisão de um chunk de malha fina que ainda não tem (tarefa do modo de foco).
func _build_collision(coord: Vector2i) -> void:
	var node: MeshInstance3D = _chunks.get(coord)
	if node == null or _body_frames.has(coord):
		return
	var body: StaticBody3D = _make_collision_body(coord)
	if body == null:
		return
	node.add_child(body)
	_body_frames[coord] = Engine.get_physics_frames()


func _unload(coord: Vector2i) -> void:
	var node: MeshInstance3D = _chunks.get(coord)
	if node == null:
		return
	_queue.cancel_collision(coord)
	remove_child(node)
	node.free()
	_chunks.erase(coord)
	_chunk_steps.erase(coord)
	_vertex_counts.erase(coord)
	_body_frames.erase(coord)
	chunk_unloaded.emit(coord)


## Corpo estático do chunk com a malha de triângulos na RESOLUÇÃO CHEIA (passo fino), mesmo que a malha desenhada
## use outro passo (D6). ConcavePolygonShape3D, e não HeightMapShape3D: só ela garante a mesma triangulação da
## malha, sem depender da diagonal que cada motor de física escolhe. Nulo (depois de push_error) se falhar.
func _make_collision_body(coord: Vector2i) -> StaticBody3D:
	var faces: PackedVector3Array = _builder.build_collision_faces(coord)
	if faces.is_empty():
		return null
	var shape: ConcavePolygonShape3D = ConcavePolygonShape3D.new()
	shape.set_faces(faces)
	var collision_shape: CollisionShape3D = CollisionShape3D.new()
	collision_shape.shape = shape
	var body: StaticBody3D = StaticBody3D.new()
	body.name = COLLISION_BODY_NAME
	body.collision_layer = 0
	body.collision_mask = 0
	body.set_collision_layer_value(TERRAIN_PHYSICS_LAYER, true)
	body.add_child(collision_shape)
	return body


func _clear() -> void:
	for coord: Vector2i in _chunks.keys():
		_unload(coord)
	_queue.clear()
	_is_streaming = false
	_builder = null
	_layout = null


## Um só material para o terreno todo: a cor vem do vértice. Marcada como sRGB para a cor aparecer como se
## escolhe no seletor de cores (as cores da paleta são [HIP], ajustadas olhando a tela).
func _make_material() -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	return material
