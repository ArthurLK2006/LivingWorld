class_name Sp4aTerrainData
extends RefCounted
## SPIKE descartável (LW-033/SP4a). Gera o terreno de teste de forma determinística (sem randf/
## randi/randomize): ruído com semente fixa + uma colina, um vale e um caminho plano, todos por
## fórmula. As DUAS variantes (própria e addon) usam esta mesma fonte, para a comparação ser justa.
## Números marcados [HIP]: só servem ao spike, não são requisito do jogo (DEC-055 segue PENDENTE).

const MAP_SIZE: float = 1024.0  ## [HIP] ~1 km² (roadmap LW-033)
const CHUNK_SIZE: float = 64.0  ## [HIP] roadmap LW-033
const CHUNKS_PER_SIDE: int = 16  ## MAP_SIZE / CHUNK_SIZE

const NOISE_SEED: int = 1337
const NOISE_FREQUENCY: float = 0.004
const NOISE_AMPLITUDE: float = 2.5

const HILL_CENTER: Vector2 = Vector2(300.0, 300.0)
const HILL_HEIGHT: float = 40.0
const HILL_RADIUS: float = 150.0

const VALLEY_CENTER: Vector2 = Vector2(700.0, 700.0)
const VALLEY_DEPTH: float = 15.0
const VALLEY_RADIUS: float = 120.0

const PATH_Z: float = 512.0
const PATH_HALF_WIDTH: float = 10.0
const PATH_BLEND: float = 8.0
const PATH_HEIGHT: float = 0.0

const SPAWN_POINT: Vector3 = Vector3(150.0, 0.0, 150.0)  ## altura real calculada em peek_spawn_point()

var _noise: FastNoiseLite


func _init() -> void:
	_noise = FastNoiseLite.new()
	_noise.seed = NOISE_SEED
	_noise.frequency = NOISE_FREQUENCY
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX


func is_inside_map(x: float, z: float) -> bool:
	return x >= 0.0 and x <= MAP_SIZE and z >= 0.0 and z <= MAP_SIZE


## Altura determinística em metros. Não valida limites (uso interno pela malha); consultas
## públicas (peek_height) validam e devolvem erro tratado fora do mapa.
func get_height(x: float, z: float) -> float:
	var height: float = _noise.get_noise_2d(x, z) * NOISE_AMPLITUDE
	var hill_distance_sq: float = HILL_CENTER.distance_squared_to(Vector2(x, z))
	height += HILL_HEIGHT * exp(-hill_distance_sq / (2.0 * HILL_RADIUS * HILL_RADIUS))
	var valley_distance_sq: float = VALLEY_CENTER.distance_squared_to(Vector2(x, z))
	height -= VALLEY_DEPTH * exp(-valley_distance_sq / (2.0 * VALLEY_RADIUS * VALLEY_RADIUS))
	var path_distance: float = absf(z - PATH_Z)
	if path_distance <= PATH_HALF_WIDTH + PATH_BLEND:
		var blend: float = clampf((path_distance - PATH_HALF_WIDTH) / PATH_BLEND, 0.0, 1.0)
		height = lerpf(PATH_HEIGHT, height, blend)
	return height


func get_surface(x: float, z: float) -> String:
	if absf(z - PATH_Z) <= PATH_HALF_WIDTH:
		return "path"
	var height: float = get_height(x, z)
	if height < -5.0:
		return "valley"
	if height > 15.0:
		return "hill_top"
	if height > 5.0:
		return "hill_slope"
	return "plain"


## Devolve {result: Result, height: float}. Fora do mapa: result de falha (AGENTS 13.1.4).
func peek_height(x: float, z: float) -> Dictionary:
	if not is_inside_map(x, z):
		return {"result": Result.failure("SP4A_OUT_OF_MAP", "Altura pedida fora do mapa de teste."), "height": 0.0}
	return {"result": Result.success(), "height": get_height(x, z)}


## Devolve {result: Result, surface: String}. Fora do mapa: result de falha.
func peek_surface(x: float, z: float) -> Dictionary:
	if not is_inside_map(x, z):
		return {"result": Result.failure("SP4A_OUT_OF_MAP", "Superfície pedida fora do mapa de teste."), "surface": ""}
	return {"result": Result.success(), "surface": get_surface(x, z)}


func peek_spawn_point() -> Vector3:
	return Vector3(SPAWN_POINT.x, get_height(SPAWN_POINT.x, SPAWN_POINT.z), SPAWN_POINT.z)


func chunk_count() -> int:
	return CHUNKS_PER_SIDE * CHUNKS_PER_SIDE
