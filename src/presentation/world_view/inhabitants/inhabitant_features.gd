class_name InhabitantFeatures
extends RefCounted
## Idade e cabelo do habitante (ART-9e, protótipo isolado, só apresentação): rugas (testa, pés de galinha e sulcos do nariz à boca, mais fundas no idoso) e os penteados (nenhum, com a franja da nuca por conta da cabeça; rente; curto; comprido caído nas costas; coque; desgrenhado com tufos), tudo em fração dos raios da cabeça sobre a casca (InhabitantRig.face_point).

const HAIR_POLAR_DEG: float = 96.0
const CROP_POLAR_DEG: float = 84.0
const HAIR_JITTER: float = 0.015
const WRINKLE_LIFT: float = 0.045
const WRINKLE_THICK: float = 0.016
const WRINKLE_DARKEN: Dictionary[int, float] = {InhabitantSpec.Age.ADULT: 0.1, InhabitantSpec.Age.OLD: 0.2}
const FOREHEAD_LINES: Dictionary[int, Array] = {InhabitantSpec.Age.ADULT: [0.55], InhabitantSpec.Age.OLD: [0.46, 0.56, 0.66]}
## Cabelo comprido: anéis (altura, rx, rz em fração dos raios da cabeça) da nuca às costas; coque e tufos (lugar e raios).
const CURTAIN: Array[Vector4] = [Vector4(0.3, 1.05, 1.06, 2.3), Vector4(-0.2, 1.06, 1.1, 2.3), Vector4(-0.7, 1.0, 1.08, 2.3), Vector4(-1.2, 0.92, 1.0, 2.3)]
const CURTAIN_ARC: float = 1.35
const BUN_RADII: Vector3 = Vector3(0.3, 0.27, 0.3)
const BUN_SPOT: Vector3 = Vector3(0.0, 0.62, 0.8)
const TUFTS: Array[Vector3] = [Vector3(-0.55, 0.82, -0.2), Vector3(0.5, 0.86, 0.1), Vector3(0.05, 0.92, 0.55)]
const TUFT_RADII: Vector3 = Vector3(0.27, 0.2, 0.27)

var _rig: InhabitantRig
var _shapes: InhabitantShapes


func _init(rig: InhabitantRig) -> void:
	_rig = rig
	_shapes = rig.shapes


## Cabelo de quem está sem cobertura: cúpula puxada para trás (a testa livre) e o penteado; careca não leva cúpula.
func hair() -> void:
	var style: int = _rig.spec.hair_style
	if style == InhabitantSpec.Hair.BALD:
		return
	var head: Vector3 = _rig.head_r
	var is_crop: bool = style == InhabitantSpec.Hair.CROP
	var offset: Vector3 = Vector3(0.0, 0.16, 0.14) if is_crop else Vector3(0.0, 0.14, 0.12)
	var scale: Vector3 = Vector3(1.02, 0.92, 1.02) if is_crop else Vector3(1.04, 0.95, 1.04)
	var bands: int = 3 if _rig.is_near else 2
	_shapes.loft(InhabitantShapes.y_frame(_rig.head_c + offset * head), InhabitantShapes.dome(head * scale, 0.0, CROP_POLAR_DEG if is_crop else HAIR_POLAR_DEG, bands), _rig.sides, _rig.spec.hair, HAIR_JITTER)
	if not _rig.is_near:
		return
	if style == InhabitantSpec.Hair.LONG:
		var rows: Array[Vector4] = []
		for row: Vector4 in CURTAIN:
			rows.append(Vector4(row.x * head.y, row.y * head.x, row.z * head.z, row.w))
		var back: float = InhabitantShapes.BACK_ANGLE
		_shapes.loft(InhabitantShapes.y_frame(_rig.head_c), rows, 8, _rig.spec.hair, HAIR_JITTER, Vector2(back - CURTAIN_ARC, back + CURTAIN_ARC))
	elif style == InhabitantSpec.Hair.BUN:
		_shapes.ball(_rig.head_c + BUN_SPOT * head, BUN_RADII * head, 3, 7, _rig.spec.hair, 0.04)
	elif style == InhabitantSpec.Hair.MESSY:
		for spot: Vector3 in TUFTS:
			_shapes.ball(_rig.head_c + spot * head, TUFT_RADII * Vector3(head.x, head.y, head.x), 2, 5, _rig.spec.hair, 0.1)


## Rugas: o adulto leva uma linha na testa; o idoso, três, mais os pés de galinha e os sulcos do nariz à boca. A testa só aparece sem cobertura.
func wrinkles() -> void:
	var spec: InhabitantSpec = _rig.spec
	if spec.age == InhabitantSpec.Age.YOUNG:
		return
	var color: Color = spec.skin.darkened(WRINKLE_DARKEN[spec.age])
	if spec.head_cover == InhabitantSpec.HeadCover.NONE:
		for y: float in FOREHEAD_LINES[spec.age]:
			_line([Vector2(-0.46, y), Vector2(0.0, y + 0.03), Vector2(0.46, y)], color)
	if spec.age != InhabitantSpec.Age.OLD:
		return
	for side: float in [-1.0, 1.0]:
		_line([Vector2(side * 0.62, 0.12), Vector2(side * 0.74, 0.17)], color)
		_line([Vector2(side * 0.62, 0.06), Vector2(side * 0.76, 0.05)], color)
		_line([Vector2(side * 0.2, -0.18), Vector2(side * 0.31, -0.32), Vector2(side * 0.31, -0.46)], color)


func _line(spots: Array[Vector2], color: Color) -> void:
	var points: Array[Vector3] = []
	for spot: Vector2 in spots:
		points.append(_rig.face_point(spot, WRINKLE_LIFT * _rig.head_r.x))
	_shapes.ribbon(points, Vector3.UP * WRINKLE_THICK * _rig.head_r.y, color, _rig.head_c)
