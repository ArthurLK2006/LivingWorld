class_name Sp6Geometry
extends RefCounted
## LW-152 (SP6, DESCARTÁVEL): contas de geometria do duelo, puras e testáveis sem janela. Levam as posições do mundo aos dois números
## que as regras pedem (distância horizontal em cm e ângulo em graus) e fazem a seleção por clique sem física.

const CM_PER_METER: float = 100.0


## Distância horizontal entre os pés do jogador e o centro do boneco, em cm inteiros (a altura não conta).
static func horizontal_distance_cm(from_m: Vector3, to_m: Vector3) -> int:
	return roundi(Vector2(to_m.x - from_m.x, to_m.z - from_m.z).length() * CM_PER_METER)


## Ângulo horizontal, de 0 a 180 graus, entre a frente do boneco e a direção boneco -> jogador. Jogador sobre o boneco dá 0.
static func angle_from_front_deg(front: Vector3, dummy_m: Vector3, player_m: Vector3) -> float:
	var to_player: Vector2 = Vector2(player_m.x - dummy_m.x, player_m.z - dummy_m.z)
	return absf(rad_to_deg(Vector2(front.x, front.z).angle_to(to_player)))


## O raio (origem e direção unitária, como a câmera dá) passa a no máximo `radius_m` do centro, à frente da origem?
static func ray_hits_sphere(origin: Vector3, direction: Vector3, center: Vector3, radius_m: float) -> bool:
	var to_center: Vector3 = center - origin
	var along: float = to_center.dot(direction)
	if along < 0.0:
		return false
	return to_center.length_squared() - along * along <= radius_m * radius_m
