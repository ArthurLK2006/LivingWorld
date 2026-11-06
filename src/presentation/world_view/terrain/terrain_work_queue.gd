class_name TerrainWorkQueue
extends RefCounted
## Filas de trabalho do TerrainView (LW-040), só dados, sem nós: malhas a (re)construir, corpos de colisão a criar e chunks a
## liberar. Prioridade: corpo de colisão, depois malha (a mais PERTO do foco primeiro), depois liberação. Dividida do
## terrain_view.gd, que passou de 300 linhas. Contrato: docs/modules/presentation.md.

enum Kind { NONE, COLLISION, MESH, FREE }

## Malhas a (re)construir: a mais PERTO do foco fica no fim.
var _meshes: Array[Vector2i] = []
## Passo desejado de cada malha da fila (no modo de foco); sem entrada vale o passo de reserva dado a `wanted_step`.
var _wanted_steps: Dictionary[Vector2i, int] = {}
## Chunks de malha fina ainda sem corpo de colisão.
var _collisions: Array[Vector2i] = []
## Chunks carregados que devem sair.
var _frees: Array[Vector2i] = []


## Os chunks dados, ordenados do mais LONGE para o mais perto do foco (x, z em metros); empate pela posição na grade.
static func sorted_far_to_near(coords: Array[Vector2i], focus_m: Vector2, chunk_size_m: float, columns: int) -> Array[Vector2i]:
	var distances: Dictionary[Vector2i, float] = {}
	for coord: Vector2i in coords:
		distances[coord] = TerrainStreaming.chunk_distance_m(coord, chunk_size_m, focus_m)
	var sorted: Array[Vector2i] = []
	sorted.assign(coords)
	sorted.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		if distances[a] != distances[b]:
			return distances[a] > distances[b]
		return a.y * columns + a.x > b.y * columns + b.x)
	return sorted


func has_work() -> bool:
	return not _meshes.is_empty() or not _collisions.is_empty() or not _frees.is_empty()


## O tipo da próxima tarefa, pela prioridade.
func next_kind() -> Kind:
	if not _collisions.is_empty():
		return Kind.COLLISION
	if not _meshes.is_empty():
		return Kind.MESH
	if not _frees.is_empty():
		return Kind.FREE
	return Kind.NONE


func mesh_count() -> int:
	return _meshes.size()


func collision_count() -> int:
	return _collisions.size()


func free_count() -> int:
	return _frees.size()


## Próxima malha (a mais perto), sem tirá-la da fila: `finish_mesh` a tira, dê certo ou não.
func next_mesh() -> Vector2i:
	return _meshes[_meshes.size() - 1]


func wanted_step(coord: Vector2i, fallback_step: int) -> int:
	return _wanted_steps.get(coord, fallback_step)


func finish_mesh(coord: Vector2i) -> void:
	_meshes.erase(coord)
	_wanted_steps.erase(coord)


func pop_collision() -> Vector2i:
	return _collisions.pop_back()


func pop_free() -> Vector2i:
	return _frees.pop_back()


func queue_collision(coord: Vector2i) -> void:
	if not _collisions.has(coord):
		_collisions.append(coord)


func cancel_collision(coord: Vector2i) -> void:
	_collisions.erase(coord)


## Modo completo (sem foco): todas as malhas, do mais perto do foco dado ao mais longe.
func schedule_all(coords: Array[Vector2i], focus_m: Vector2, chunk_size_m: float, columns: int) -> void:
	_wanted_steps.clear()
	_meshes = sorted_far_to_near(coords, focus_m, chunk_size_m, columns)


## Modo de foco: SUBSTITUI a fila de malhas pelo que falta construir ou reconstruir segundo o plano (o que ficou fora do raio
## sai dela antes de ser construído) e a de liberação pelo que saiu do raio. Os corpos de colisão pendentes ficam.
func schedule(plan: TerrainStreaming.Plan, current_steps: Dictionary[Vector2i, int], focus_m: Vector2, chunk_size_m: float, columns: int) -> void:
	var work: Array[Vector2i] = []
	_wanted_steps.clear()
	for coord: Vector2i in plan.wanted:
		if current_steps.get(coord, TerrainStreaming.ABSENT) != plan.wanted[coord]:
			work.append(coord)
			_wanted_steps[coord] = plan.wanted[coord]
	_meshes = sorted_far_to_near(work, focus_m, chunk_size_m, columns)
	_frees = plan.unload


func clear() -> void:
	_meshes.clear()
	_wanted_steps.clear()
	_collisions.clear()
	_frees.clear()
