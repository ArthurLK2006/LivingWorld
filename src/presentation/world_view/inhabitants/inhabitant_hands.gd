class_name InhabitantHands
extends RefCounted
## A mão do habitante (ART-9e, protótipo isolado, só apresentação): palma achatada, polegar de dois pedaços voltado para o corpo e quatro dedos curvos de comprimentos diferentes, tudo em fração de H; `is_soft` dá normais suaves (pele); com `is_soft` desligado a mão é de luva (couro facetado). De longe, só a palma (InhabitantBody).

const PALM: Vector3 = Vector3(0.046, 0.05, 0.036)
const FINGER_RADIUS: float = 0.0125
const FINGER_SPREAD: float = 0.0185
const FINGER_LENGTH: Vector2 = Vector2(0.034, 0.026)
const FINGER_CURL: Vector2 = Vector2(0.004, 0.017)
const FINGER_TAPER: Vector2 = Vector2(0.92, 0.78)
const THUMB_SPOT: Vector3 = Vector3(0.036, 0.004, -0.014)
const THUMB_PATH: Array[Vector3] = [Vector3(0.007, -0.03, -0.014), Vector3(0.0, -0.052, -0.036)]
const THUMB_RADII: Vector3 = Vector3(0.0165, 0.014, 0.011)


## Monta a mão em `center` (m); `inward` (-1 ou 1) é o lado do corpo, onde fica o polegar.
static func build(shapes: InhabitantShapes, h: float, center: Vector3, inward: float, color: Color, is_soft: bool) -> void:
	shapes.soft = is_soft
	shapes.ball(center, PALM * h, 3, 7, color, 0.03)
	var top: float = center.y - PALM.y * h * 0.55
	for finger: int in 4:
		var reach: float = 1.0 - 0.12 * absf(finger - 1.5)
		var start: Vector3 = Vector3(center.x + (finger - 1.5) * FINGER_SPREAD * h, top, center.z - PALM.z * h * 0.2)
		var bend: Vector3 = start + Vector3(0.0, -FINGER_LENGTH.x * h * reach, -FINGER_CURL.x * h)
		var tip: Vector3 = bend + Vector3(0.0, -FINGER_LENGTH.y * h * reach, -FINGER_CURL.y * h)
		var radius: Vector2 = Vector2(FINGER_RADIUS, FINGER_RADIUS) * h
		shapes.limb(start, bend, radius, radius * FINGER_TAPER.x, 4, color, 1)
		shapes.limb(bend, tip, radius * FINGER_TAPER.x, radius * FINGER_TAPER.y, 4, color, 1)
	var root: Vector3 = center + Vector3(inward * THUMB_SPOT.x, THUMB_SPOT.y, THUMB_SPOT.z) * h
	var previous: Vector3 = root
	var radii: Array[float] = [THUMB_RADII.x, THUMB_RADII.y, THUMB_RADII.z]
	for index: int in THUMB_PATH.size():
		var next: Vector3 = root + Vector3(inward * THUMB_PATH[index].x, THUMB_PATH[index].y, THUMB_PATH[index].z) * h
		shapes.limb(previous, next, Vector2(radii[index], radii[index]) * h, Vector2(radii[index + 1], radii[index + 1]) * h, 5, color, 1)
		previous = next
	shapes.soft = false
