class_name TerrainStreaming
extends RefCounted
## Decide QUAIS chunks do terreno devem existir em volta do foco, com QUAL passo (fino perto, grosso longe) e QUAIS devem
## sair (LW-040). Função pura: sem nós e sem estado além dos raios. Distância = do foco ao CENTRO do chunk, em metros.
## HISTERESE: um chunk só é carregado a menos que o raio de carga, mas só sai depois do raio de carga mais a histerese;
## só vira fino a menos que o raio fino, mas só volta ao grosso depois do raio fino mais a histerese. Assim um foco que oscila
## na borda não carrega e descarta sem parar. Valores [HIP]. Contrato: docs/modules/presentation.md.

## "Passo atual" de um chunk que não existe.
const ABSENT: int = 0
const DEFAULT_LOAD_RADIUS_M: float = 384.0
const DEFAULT_FINE_RADIUS_M: float = 128.0
const DEFAULT_HYSTERESIS_M: float = 64.0
## Centro de um chunk, em chunks, a partir do canto de menor x e z.
const CHUNK_CENTER: Vector2 = Vector2(0.5, 0.5)

var load_radius_m: float = DEFAULT_LOAD_RADIUS_M
var fine_radius_m: float = DEFAULT_FINE_RADIUS_M
var hysteresis_m: float = DEFAULT_HYSTERESIS_M


## O plano para um foco: `wanted` tem os chunks que devem existir (coordenada -> passo) e `unload`, os já carregados que devem sair.
class Plan:
	extends RefCounted

	var wanted: Dictionary[Vector2i, int] = {}
	var unload: Array[Vector2i] = []


## Passo que o chunk a `distance_m` do foco deve ter, dado o passo atual (ABSENT se não existe): ABSENT, grosso ou fino.
func desired_step(distance_m: float, current_step: int) -> int:
	var keep_radius_m: float = load_radius_m + (hysteresis_m if current_step != ABSENT else 0.0)
	if distance_m > keep_radius_m:
		return ABSENT
	var fine_limit_m: float = fine_radius_m + (hysteresis_m if current_step == TerrainChunkBuilder.STEP_FINE else 0.0)
	return TerrainChunkBuilder.STEP_FINE if distance_m <= fine_limit_m else TerrainChunkBuilder.STEP_COARSE


static func chunk_distance_m(coord: Vector2i, chunk_size_m: float, focus_m: Vector2) -> float:
	return ((Vector2(coord) + CHUNK_CENTER) * chunk_size_m).distance_to(focus_m)


## Plano para `focus_m` (x, z em metros). `current` guarda o passo de cada chunk carregado (coordenada -> passo).
func plan(chunk_count: Vector2i, chunk_size_m: float, focus_m: Vector2, current: Dictionary[Vector2i, int]) -> Plan:
	var result: Plan = Plan.new()
	var reach_m: float = load_radius_m + hysteresis_m
	var first: Vector2i = Vector2i(maxi(floori((focus_m.x - reach_m) / chunk_size_m), 0), maxi(floori((focus_m.y - reach_m) / chunk_size_m), 0))
	var last: Vector2i = Vector2i(mini(floori((focus_m.x + reach_m) / chunk_size_m), chunk_count.x - 1), mini(floori((focus_m.y + reach_m) / chunk_size_m), chunk_count.y - 1))
	for chunk_z: int in range(first.y, last.y + 1):
		for chunk_x: int in range(first.x, last.x + 1):
			var coord: Vector2i = Vector2i(chunk_x, chunk_z)
			var step: int = desired_step(chunk_distance_m(coord, chunk_size_m, focus_m), current.get(coord, ABSENT))
			if step != ABSENT:
				result.wanted[coord] = step
	for coord: Vector2i in current:
		if not result.wanted.has(coord):
			result.unload.append(coord)
	return result
