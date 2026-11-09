class_name NpcRoute
extends RefCounted
## Rota e passo do corpo do NPC em S0 (LW-072d; DEC-122, APROVADA por ora). Funções puras: sem nó, ponte nem relógio; as alturas do terreno
## chegam por um `Callable`. N1: rota RETA por pontos, do ponto onde o corpo está até a BORDA da caixa do local (a cápsula não entra na
## construção), recusada por inteiro se algum trecho passar da inclinação máxima; não desvia de nada (atravessa pedra e outras caixas; a
## DEC-122 manda revisar quando as construções virarem obstáculo). P1: passo natural de 4 m/s [HIP] vezes a velocidade do relógio; pausa =
## parado. Contrato: docs/modules/presentation.md.

## P1 [HIP]: passo natural do corpo (m/s reais) com o relógio na velocidade 1.
const WALK_SPEED_MPS: float = 4.0
## N1 [HIP]: inclinação máxima (graus) e distância entre as amostras da rota (m).
const MAX_SLOPE_DEGREES: float = 40.0
const SAMPLE_STEP_M: float = 2.0

## Rota recusada não tem pontos. `length_m` é o comprimento no plano (x e z); cada ponto leva a altura do terreno (y) naquela amostra.
var is_blocked: bool = false
var points: PackedVector3Array = PackedVector3Array()
var length_m: float = 0.0


## P1: velocidade do corpo (m/s reais) com o relógio na velocidade `clock_speed` (1 a 8). Pausa ou velocidade inválida: parado.
static func speed_mps(clock_speed: int, is_paused: bool) -> float:
	if is_paused or clock_speed <= 0:
		return 0.0
	return WALK_SPEED_MPS * float(clock_speed)


## Onde o corpo para na reta de `from` até o centro `goal` do local (x e z): na borda da caixa de meia-medida `half_box_m`, engordada pelo raio da
## cápsula. Já dentro dela, no próprio `from`. Sem caixa (meia-medida zero: ação sem local, ou local sem desenho), no centro.
static func stop_point(from: Vector2, goal: Vector2, half_box_m: Vector2) -> Vector2:
	var reach: Vector2 = Vector2.ZERO if half_box_m == Vector2.ZERO else half_box_m + Vector2.ONE * NpcView.CAPSULE_RADIUS_M
	var offset: Vector2 = from - goal
	var fraction: float = 0.0
	for axis: int in 2:
		var gap: float = absf(offset[axis])
		if gap > reach[axis]:
			fraction = maxf(fraction, 1.0 - reach[axis] / gap)
	return from.lerp(goal, fraction)


## N1: planeja a rota reta de `start` até a borda da caixa do local de centro `goal`. `height_at(x, z) -> float` dá a altura do terreno
## (NAN se não puder ser lida). Recusa (`is_blocked`) se algum trecho entre amostras passar da inclinação máxima ou se uma altura não puder ser lida.
static func plan(start: Vector3, goal: Vector3, half_box_m: Vector2, height_at: Callable) -> NpcRoute:
	var route: NpcRoute = NpcRoute.new()
	var from: Vector2 = Vector2(start.x, start.z)
	var stop: Vector2 = stop_point(from, Vector2(goal.x, goal.z), half_box_m)
	route.length_m = from.distance_to(stop)
	var samples: int = maxi(1, ceili(route.length_m / SAMPLE_STEP_M))
	var max_rise_m: float = tan(deg_to_rad(MAX_SLOPE_DEGREES)) * route.length_m / float(samples)
	var previous: float = NAN
	for index: int in samples + 1:
		var spot: Vector2 = from.lerp(stop, float(index) / float(samples))
		# Variant na fronteira com o Callable: a resposta é conferida (finita) antes de usar.
		var ground: float = float(height_at.call(spot.x, spot.y))
		if not is_finite(ground) or (index > 0 and absf(ground - previous) > max_rise_m):
			route.is_blocked = true
			route.points = PackedVector3Array()
			return route
		route.points.append(Vector3(spot.x, ground, spot.y))
		previous = ground
	return route


## Ponto da rota a `distance_m` metros do começo (no plano), limitado ao começo e ao fim. Rota recusada não tem pontos: confira `is_blocked` antes.
func position_at(distance_m: float) -> Vector3:
	if points.size() < 2 or length_m <= 0.0:
		return points[0] if not points.is_empty() else Vector3.ZERO
	var along: float = clampf(distance_m / length_m, 0.0, 1.0) * float(points.size() - 1)
	var index: int = mini(floori(along), points.size() - 2)
	return points[index].lerp(points[index + 1], along - float(index))


## Giro (radianos, em torno de Y) que põe a frente do corpo (-Z local, onde fica o nariz) na direção horizontal dada.
static func facing_yaw(direction: Vector3) -> float:
	return atan2(-direction.x, -direction.z)
