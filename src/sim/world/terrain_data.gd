class_name TerrainData
extends RefCounted
## Dados físicos do terreno: altura nos nós de uma grade, tipo de superfície por célula e ponto de
## nascimento. Convenções (nós, eixos, unidades, interpolação) em docs/modules/world.md.
## É CONTEÚDO carregado de data/world/ (somente leitura): não entra no save nem no hash de estado.

## Centímetros por metro: único ponto de conversão entre o arquivo (inteiros em cm) e a API (metros).
const CM_PER_METER: float = 100.0
const CODE_OUT_OF_BOUNDS: String = "TERRAIN_OUT_OF_BOUNDS"
const CODE_INVALID_COORDINATE: String = "TERRAIN_INVALID_COORDINATE"
## Código de superfície devolvido quando a consulta falha (códigos válidos nunca são negativos).
const NO_SURFACE_CODE: int = -1

var _cells: Vector2i
var _cell_size_cm: int
## Alturas em cm nos nós, por linhas de z: o nó (ix, iz) fica em iz * (células_x + 1) + ix.
var _heights_cm: PackedInt64Array
## Código de superfície por célula, por linhas de z: a célula (cx, cz) fica em cz * células_x + cx.
var _surfaces: PackedInt64Array
## Código -> id de conteúdo (texto) de cada tipo de superfície.
var _surface_ids: Dictionary[int, String]
var _spawn_cm: Vector2i
## Tamanho do mapa em metros, em decimais de 64 bits (Vector2 usa 32 bits e erraria a borda exata).
var _size_x_m: float
var _size_z_m: float
var _spawn_point: Vector3 = Vector3.ZERO


## O TerrainData passa a ser dono das listas recebidas (arrays "Packed" são passados por referência):
## quem chama não deve alterá-las depois. Quem monta o objeto é o TerrainLoader.
func _init(cells: Vector2i, cell_size_cm: int, heights_cm: PackedInt64Array, surfaces: PackedInt64Array, surface_ids: Dictionary[int, String], spawn_cm: Vector2i) -> void:
	_cells = cells
	_cell_size_cm = cell_size_cm
	_heights_cm = heights_cm
	_surfaces = surfaces
	_surface_ids = surface_ids
	_spawn_cm = spawn_cm
	_size_x_m = float(cells.x * cell_size_cm) / CM_PER_METER
	_size_z_m = float(cells.y * cell_size_cm) / CM_PER_METER
	# Grade incoerente não é lida (índices fora da lista): validate() relata o problema.
	if _grid_problems().is_empty():
		var spawn_x: float = float(spawn_cm.x) / CM_PER_METER
		var spawn_z: float = float(spawn_cm.y) / CM_PER_METER
		_spawn_point = Vector3(spawn_x, _height_m_at(spawn_x, spawn_z), spawn_z)


## Altura do chão (metros) no ponto (x, z), por interpolação bilinear. Fora do mapa ou com
## coordenada não numérica devolve falha tratada.
func peek_height(x: float, z: float) -> HeightQuery:
	var check: Result = _check_point("peek_height", x, z)
	if not check.ok:
		return HeightQuery.new(check, 0.0)
	return HeightQuery.new(check, _height_m_at(x, z))


## Tipo de superfície da célula que contém (x, z). Mesmas falhas de `peek_height`.
func peek_surface(x: float, z: float) -> SurfaceQuery:
	var check: Result = _check_point("peek_surface", x, z)
	if not check.ok:
		return SurfaceQuery.new(check, NO_SURFACE_CODE, "")
	var cell_x: int = _cell_index(_to_cells(x), _cells.x)
	var cell_z: int = _cell_index(_to_cells(z), _cells.y)
	var code: int = _surfaces[cell_z * _cells.x + cell_x]
	return SurfaceQuery.new(check, code, _surface_ids.get(code, ""))


## Ponto de nascimento (metros); y é a altura do chão ali. Dado validado no carregamento: não falha.
func peek_spawn_point() -> Vector3:
	return _spawn_point


## Metadados da grade, somente leitura (para a malha e para os testes).
func peek_cells() -> Vector2i:
	return _cells


func peek_cell_size_m() -> float:
	return float(_cell_size_cm) / CM_PER_METER


func peek_size_m() -> Vector2:
	return Vector2(_size_x_m, _size_z_m)


## Inconsistências da grade (vazia se estiver certo). Roda depois de carregar e em testes.
func validate() -> Array[String]:
	var problems: Array[String] = _grid_problems()
	var unknown_codes: Dictionary[int, bool] = {}
	for code: int in _surfaces:
		if not _surface_ids.has(code):
			unknown_codes[code] = true
	for code: int in unknown_codes:
		problems.append("superfícies: código %d não existe na tabela de tipos de superfície." % code)
	return problems


func debug_summary() -> Dictionary:
	return {
		"cells_x": _cells.x,
		"cells_z": _cells.y,
		"cell_size_cm": _cell_size_cm,
		"size_x_m": _size_x_m,
		"size_z_m": _size_z_m,
		"node_count": _heights_cm.size(),
		"surface_kinds": _surface_ids.size(),
		"spawn_point": _spawn_point,
		"problems": validate(),
	}


## Parte barata de validate(): grade com tamanho positivo, listas do tamanho certo, nascimento dentro do mapa.
func _grid_problems() -> Array[String]:
	var problems: Array[String] = []
	if _cells.x < 1 or _cells.y < 1 or _cell_size_cm < 1:
		problems.append("grade inválida: %d x %d células de %d cm; esperado ao menos 1 célula por lado e passo positivo." % [_cells.x, _cells.y, _cell_size_cm])
		return problems
	var node_count: int = (_cells.x + 1) * (_cells.y + 1)
	if _heights_cm.size() != node_count:
		problems.append("alturas: esperado %d nós, encontrado %d." % [node_count, _heights_cm.size()])
	if _surfaces.size() != _cells.x * _cells.y:
		problems.append("superfícies: esperado %d células, encontrado %d." % [_cells.x * _cells.y, _surfaces.size()])
	var size_cm: Vector2i = Vector2i(_cells.x * _cell_size_cm, _cells.y * _cell_size_cm)
	if _spawn_cm.x < 0 or _spawn_cm.x > size_cm.x or _spawn_cm.y < 0 or _spawn_cm.y > size_cm.y:
		problems.append("ponto de nascimento (%d, %d) cm fora do mapa de %d x %d cm." % [_spawn_cm.x, _spawn_cm.y, size_cm.x, size_cm.y])
	return problems


## Confere se (x, z) é um ponto válido: número finito e dentro do mapa (intervalo fechado).
func _check_point(caller: String, x: float, z: float) -> Result:
	if is_nan(x) or is_nan(z) or is_inf(x) or is_inf(z):
		return Result.failure(CODE_INVALID_COORDINATE, "TerrainData.%s: coordenada não numérica (x=%s, z=%s); esperado número finito." % [caller, str(x), str(z)])
	if x < 0.0 or x > _size_x_m or z < 0.0 or z > _size_z_m:
		return Result.failure(CODE_OUT_OF_BOUNDS, "TerrainData.%s: ponto (x=%s, z=%s) fora do mapa; esperado x de 0 a %s m e z de 0 a %s m." % [caller, str(x), str(z), str(_size_x_m), str(_size_z_m)])
	return Result.success()


## Posição em unidades de célula (decimal) de uma coordenada em metros.
func _to_cells(meters: float) -> float:
	return meters * CM_PER_METER / float(_cell_size_cm)


## Índice da célula que contém a posição: a célula k cobre [k, k+1), então na divisa vale a de maior
## índice; a borda final do mapa pertence à última célula.
func _cell_index(position_in_cells: float, cell_count: int) -> int:
	return clampi(floori(position_in_cells), 0, cell_count - 1)


## Altura (metros) por interpolação bilinear entre os 4 nós da célula; o ponto já está dentro do mapa.
func _height_m_at(x: float, z: float) -> float:
	var grid_x: float = _to_cells(x)
	var grid_z: float = _to_cells(z)
	var cell_x: int = _cell_index(grid_x, _cells.x)
	var cell_z: int = _cell_index(grid_z, _cells.y)
	var u: float = clampf(grid_x - float(cell_x), 0.0, 1.0)
	var v: float = clampf(grid_z - float(cell_z), 0.0, 1.0)
	var nodes_per_row: int = _cells.x + 1
	var first_node: int = cell_z * nodes_per_row + cell_x
	var near_row: float = lerpf(float(_heights_cm[first_node]), float(_heights_cm[first_node + 1]), u)
	var far_row: float = lerpf(float(_heights_cm[first_node + nodes_per_row]), float(_heights_cm[first_node + nodes_per_row + 1]), u)
	return lerpf(near_row, far_row, v) / CM_PER_METER


## Resultado de `peek_height`: `result.ok` diz se deu certo; só então `height_m` vale.
class HeightQuery:
	extends RefCounted

	var result: Result
	var height_m: float

	func _init(query_result: Result, value_m: float) -> void:
		result = query_result
		height_m = value_m


## Resultado de `peek_surface`: só vale se `result.ok`. `surface_id` é o id de conteúdo (texto) e
## `surface_code` o código inteiro guardado na grade.
class SurfaceQuery:
	extends RefCounted

	var result: Result
	var surface_code: int
	var surface_id: String

	func _init(query_result: Result, code: int, id: String) -> void:
		result = query_result
		surface_code = code
		surface_id = id
