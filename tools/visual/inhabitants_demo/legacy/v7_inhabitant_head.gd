class_name V7InhabitantHead
extends RefCounted
## [v7 CONGELADA, só para a cena de comparação] Cabeça e rosto do habitante (ART-9d, protótipo isolado, só apresentação): crânio loftado de queixo redondo, pescoço de pele, orelhas, e o rosto charmoso em geometria colada à casca (olhos ovais de esclera clara, íris escura e brilho minúsculo, pálpebras e sobrancelhas inclinadas pela expressão da ficha, nariz de bulbo arredondado, bochechas de volume suave mais a cor rosada, boca curva em dois pedaços com covinha), cabelo e barba de verdade (só em alguns aldeões, sempre abaixo da boca, para o pescoço do capelo nunca parecer barba). LOD 1 leva só olhos, sobrancelhas e nariz; LOD 2, o crânio.

const HEAD_JITTER: float = 0.015
const NECK_RADII: Vector2 = Vector2(0.38, 0.36)
const NECK_FROM: float = 0.62
const NECK_TO: float = -0.7
## Rosto, em fração dos raios da cabeça (x, y sobre a face): levantamento da primeira camada e de cada camada seguinte (fração de rx), olhos, íris, sobrancelha (x por dentro e por fora), nariz (centro e raios), bochecha, boca (altura, meia largura) e orelha.
const FACE_LIFT: float = 0.06
const LAYER_LIFT: float = 0.012
const LAYER_BULGE: float = 0.01
const EYE_SPOT: Vector2 = Vector2(0.37, 0.07)
const EYE_HALF: Vector2 = Vector2(0.17, 0.12)
const IRIS_HALF: Vector2 = Vector2(0.09, 0.1)
const BROW_X: Vector2 = Vector2(0.15, 0.6)
const BROW_ARCH: float = 0.03
const NOSE_SPOT: Vector2 = Vector2(0.0, -0.13)
const NOSE_RADII: Vector3 = Vector3(0.13, 0.15, 0.15)
const CHEEK_SPOT: Vector2 = Vector2(0.56, -0.22)
const CHEEK_RADII: Vector3 = Vector3(0.22, 0.19, 0.095)
const MOUTH_Y: float = -0.47
const MOUTH_HALF: float = 0.23
const MOUTH_THICK: float = 0.028
const EAR: Vector3 = Vector3(0.05, 0.12, 0.09)
const CURIOUS_RAISE: float = 0.07
## Expressões: altura da sobrancelha por dentro e por fora, meia espessura, quanto a pálpebra cobre do olho (fração), altura do canto da boca (sorriso) e olho arregalado (1 = normal).
const EXPRESSIONS: Dictionary[int, Array] = {
	V7InhabitantSpec.Mood.GENTLE: [0.34, 0.29, 0.045, 0.0, 0.05, 1.0],
	V7InhabitantSpec.Mood.CURIOUS: [0.34, 0.4, 0.045, 0.0, 0.025, 1.15],
	V7InhabitantSpec.Mood.TIRED: [0.29, 0.24, 0.05, 0.45, -0.015, 0.95],
	V7InhabitantSpec.Mood.SEVERE: [0.27, 0.37, 0.06, 0.25, -0.01, 0.9],
}
const SCLERA: Color = Color("F4EEE2")
const IRIS: Color = Color("33241D")
const GLINT: Color = Color("FFFFFF")
const MOUTH_COLOR: Color = Color("6E3B32")
const BLUSH: Color = Color("E8707A")
const CHEEK_BLUSH: float = 0.38
const NOSE_BLUSH: float = 0.1
const BROW_DARKEN: float = 0.35
const LID_DARKEN: float = 0.1
const DIMPLE_DARKEN: float = 0.3
## Cabelo (cúpula e nuca), em fração dos raios da cabeça, e barba: alturas dos anéis (fração de ry), folga sobre a cabeça, avanço para a frente e giro (rad) em torno do rosto.
const HAIR_SHELL: Array[Vector3] = [Vector3(0.0, 0.14, 0.12), Vector3(1.04, 0.95, 1.04)]
const HAIR_POLAR_DEG: float = 96.0
const BEARD_Y: Array[float] = [-0.56, -0.74, -0.92, -1.06]
const BEARD_SCALE: Array[float] = [1.1, 1.12, 1.1, 0.55]
const BEARD_FORWARD: Array[float] = [0.0, -0.03, -0.06, -0.1]
const BEARD_FULL_TIP: float = -1.3
const BEARD_CLAMP_Y: float = -0.88
const BEARD_HALF_ARC: float = 1.4
const BEARD_SIDES: int = 8

var _rig: V7InhabitantRig
var _shapes: V7InhabitantShapes
var _hx: float


func _init(rig: V7InhabitantRig) -> void:
	_rig = rig
	_shapes = rig.shapes
	_hx = rig.head_r.x


func build() -> void:
	_shapes.loft(V7InhabitantShapes.y_frame(_rig.head_c), _rig.head_rows, _rig.sides, _rig.spec.skin, HEAD_JITTER)
	if _rig.lod == V7InhabitantRig.LOD_FAR:
		return
	_neck()
	if _rig.is_near:
		_ears()
		_face()
		_beard()
	else:
		_minimal_face()
	var cover: int = _rig.spec.head_cover
	if cover == V7InhabitantSpec.HeadCover.NONE:
		_hair()
	if _rig.is_near and (cover == V7InhabitantSpec.HeadCover.NONE or cover == V7InhabitantSpec.HeadCover.CAP or cover == V7InhabitantSpec.HeadCover.WIDE_HAT):
		_nape()


func _neck() -> void:
	var top: float = _rig.head_c.y + NECK_TO * _rig.head_r.y
	var shift: Vector2 = _rig.shift_at(NECK_FROM * _rig.h)
	_shapes.limb(Vector3(shift.x, NECK_FROM * _rig.h, 0.0), Vector3(0.0, top, 0.0), Vector2(NECK_RADII.x, NECK_RADII.y) * _hx * 1.05, Vector2(NECK_RADII.x, NECK_RADII.y) * _hx, 6 if _rig.is_near else 4, _rig.spec.skin, 1)


func _ears() -> void:
	var head: Vector3 = _rig.head_r
	for side: float in [-1.0, 1.0]:
		_shapes.ball(_rig.head_c + Vector3(side * head.x * 0.99, -0.06 * head.y, 0.06 * head.z), Vector3(EAR.x * head.x, EAR.y * head.y, EAR.z * head.z), 2, 5, _rig.spec.skin.darkened(0.04), 0.05)


## O rosto de perto: olhos, pálpebras, sobrancelhas, bochechas, bolsas sob os olhos (cansado), boca, covinhas e nariz.
func _face() -> void:
	var expression: Array = EXPRESSIONS[_rig.spec.expression]
	var brow_in: float = expression[0]
	var brow_out: float = expression[1]
	var brow_thick: float = expression[2]
	var lid: float = expression[3]
	var smile: float = expression[4]
	var wide: float = expression[5]
	var skin: Color = _rig.spec.skin
	var brow_color: Color = _rig.spec.hair.darkened(BROW_DARKEN)
	for side: float in [-1.0, 1.0]:
		var raise: float = CURIOUS_RAISE if _rig.spec.expression == V7InhabitantSpec.Mood.CURIOUS and side > 0.0 else 0.0
		_eye(side, lid, wide)
		_brow(side, brow_in + raise, brow_out + raise, brow_thick, brow_color)
		_shapes.ball(_rig.face_point(Vector2(side * CHEEK_SPOT.x, CHEEK_SPOT.y), 0.0), CHEEK_RADII * _hx, 4, 8, skin.lerp(BLUSH, CHEEK_BLUSH), 0.015)
		if _rig.spec.expression == V7InhabitantSpec.Mood.TIRED:
			_oval(Vector2(side * EYE_SPOT.x, EYE_SPOT.y - EYE_HALF.y * 1.5), Vector2(EYE_HALF.x * 0.8, 0.035), skin.darkened(LID_DARKEN), 0, 6)
		_mouth(side, smile)
	var nose: Vector3 = _rig.face_point(NOSE_SPOT, 0.02 * _hx)
	_shapes.ball(nose, NOSE_RADII * _hx, 4, 8, skin.lerp(BLUSH, NOSE_BLUSH), 0.015)


## De longe: olhos escuros, sobrancelhas e o nariz.
func _minimal_face() -> void:
	var skin: Color = _rig.spec.skin
	var hair: Color = _rig.spec.hair.darkened(BROW_DARKEN)
	for side: float in [-1.0, 1.0]:
		_oval(Vector2(side * EYE_SPOT.x, EYE_SPOT.y), IRIS_HALF * 1.2, IRIS, 0, 5)
		_brow_strip(side, hair)
	_shapes.ball(_rig.face_point(NOSE_SPOT, 0.02 * _hx), NOSE_RADII * _hx, 2, 5, skin.lerp(BLUSH, NOSE_BLUSH), 0.03)


func _brow_strip(side: float, color: Color) -> void:
	var points: Array[Vector3] = [_rig.face_point(Vector2(side * BROW_X.x, 0.3), _lift(0)), _rig.face_point(Vector2(side * BROW_X.y, 0.3), _lift(0))]
	_shapes.ribbon(points, Vector3.UP * 0.05 * _rig.head_r.y, color, _rig.head_c)


func _lift(layer: int) -> float:
	return (FACE_LIFT + LAYER_LIFT * layer) * _hx


## Mancha oval no rosto: um leque sobre a casca, com o meio um pouco mais saliente.
func _oval(spot: Vector2, half: Vector2, color: Color, layer: int, sides: int = 8) -> void:
	var edge: Array[Vector3] = []
	for index: int in sides:
		var angle: float = TAU * index / sides
		edge.append(_rig.face_point(spot + Vector2(cos(angle) * half.x, sin(angle) * half.y), _lift(layer)))
	_shapes.fan(_rig.face_point(spot, _lift(layer) + LAYER_BULGE * _hx), edge, color, _rig.head_c)


## Olho oval: esclera clara, íris escura levemente voltada para dentro, brilho minúsculo e, se a expressão pede, a pálpebra de pele por cima.
func _eye(side: float, lid: float, wide: float) -> void:
	var spot: Vector2 = Vector2(side * EYE_SPOT.x, EYE_SPOT.y)
	var half: Vector2 = Vector2(EYE_HALF.x, EYE_HALF.y * wide)
	_oval(spot, half, SCLERA, 0)
	_oval(spot + Vector2(-side * 0.012, -0.004), Vector2(IRIS_HALF.x, minf(IRIS_HALF.y * wide, half.y * 0.95)), IRIS, 1)
	_oval(spot + Vector2(-side * 0.035, 0.045), Vector2(0.025, 0.03), GLINT, 2, 4)
	if lid <= 0.0:
		return
	var chord: float = 1.0 - 2.0 * lid
	var start: float = asin(chord)
	var edge: Array[Vector3] = []
	for index: int in 7:
		var angle: float = start + (PI - 2.0 * start) * index / 6.0
		edge.append(_rig.face_point(spot + Vector2(cos(angle) * half.x * 1.04, sin(angle) * half.y * 1.06), _lift(3)))
	_shapes.fan(_rig.face_point(spot + Vector2(0.0, half.y * chord), _lift(3) + LAYER_BULGE * _hx), edge, _rig.spec.skin.darkened(LID_DARKEN), _rig.head_c)


## Sobrancelha em arco suave de três pontos (por dentro, meio, por fora), com a inclinação da expressão.
func _brow(side: float, inner: float, outer: float, thick: float, color: Color) -> void:
	var middle: float = (inner + outer) * 0.5 + BROW_ARCH
	var points: Array[Vector3] = []
	for spot: Vector2 in [Vector2(side * BROW_X.x, inner), Vector2(side * lerpf(BROW_X.x, BROW_X.y, 0.5), middle), Vector2(side * BROW_X.y, outer)]:
		points.append(_rig.face_point(spot, _lift(1)))
	_shapes.ribbon(points, Vector3.UP * thick * _rig.head_r.y, color, _rig.head_c)


## Um dos dois pedaços da boca (do centro ao canto, curvo) e a covinha na ponta.
func _mouth(side: float, smile: float) -> void:
	var points: Array[Vector3] = []
	for spot: Vector2 in [Vector2(0.0, MOUTH_Y), Vector2(side * MOUTH_HALF * 0.5, MOUTH_Y + smile * 0.3), Vector2(side * MOUTH_HALF, MOUTH_Y + smile)]:
		points.append(_rig.face_point(spot, _lift(0)))
	_shapes.ribbon(points, Vector3.UP * MOUTH_THICK * _rig.head_r.y, MOUTH_COLOR, _rig.head_c)
	if smile > 0.01:
		_oval(Vector2(side * (MOUTH_HALF + 0.045), MOUTH_Y + smile), Vector2(0.035, 0.03), _rig.spec.skin.darkened(DIMPLE_DARKEN), 0, 5)


## Cabelo de quem está sem cobertura: cúpula puxada para trás (a testa livre) e, de perto, a nuca.
func _hair() -> void:
	var head: Vector3 = _rig.head_r
	var offset: Vector3 = HAIR_SHELL[0]
	var scale: Vector3 = HAIR_SHELL[1]
	var bands: int = 3 if _rig.is_near else 2
	_shapes.loft(V7InhabitantShapes.y_frame(_rig.head_c + offset * head), V7InhabitantShapes.dome(head * scale, 0.0, HAIR_POLAR_DEG, bands), _rig.sides, _rig.spec.hair, HEAD_JITTER)


## A nuca e as costeletas de quem não tem capuz nem elmo: um arco de cabelo que dá a volta por trás da cabeça.
func _nape() -> void:
	var head: Vector3 = _rig.head_r
	var nape: Array[Vector4] = [Vector4(0.1 * head.y, head.x * 1.04, head.z * 1.05, 2.3), Vector4(-0.3 * head.y, head.x * 1.02, head.z * 1.04, 2.3), Vector4(-0.62 * head.y, head.x * 0.8, head.z * 0.9, 2.3)]
	_shapes.loft(V7InhabitantShapes.y_frame(_rig.head_c), nape, 8, _rig.spec.hair, HEAD_JITTER, Vector2(V7InhabitantShapes.BACK_ANGLE - 1.5, V7InhabitantShapes.BACK_ANGLE + 1.5))


## Barba de verdade (curta ou cheia): da curva de baixo da boca ao queixo, nunca sobre a boca; a cheia ganha bigode.
func _beard() -> void:
	var kind: int = _rig.spec.beard
	if kind == V7InhabitantSpec.Beard.NONE:
		return
	var head: Vector3 = _rig.head_r
	var rows: Array[Vector4] = []
	var shifts: PackedVector2Array = PackedVector2Array()
	for index: int in BEARD_Y.size():
		var level: float = BEARD_Y[index]
		if index == BEARD_Y.size() - 1 and kind == V7InhabitantSpec.Beard.FULL:
			level = BEARD_FULL_TIP
		var row: Vector4 = _rig.head_row_at(maxf(level, BEARD_CLAMP_Y) * head.y)
		rows.append(Vector4(level * head.y, row.y * BEARD_SCALE[index], row.z * BEARD_SCALE[index], 2.3))
		shifts.append(Vector2(0.0, BEARD_FORWARD[index] * head.z))
	var front: float = V7InhabitantShapes.FRONT_ANGLE
	_shapes.loft(V7InhabitantShapes.y_frame(_rig.head_c), rows, BEARD_SIDES, _rig.spec.hair, HEAD_JITTER, Vector2(front - BEARD_HALF_ARC, front + BEARD_HALF_ARC), shifts)
	if kind == V7InhabitantSpec.Beard.FULL:
		for side: float in [-1.0, 1.0]:
			_shapes.ball(_rig.face_point(Vector2(side * 0.13, -0.34), 0.0), Vector3(0.13 * _hx, 0.05 * head.y, 0.08 * _hx), 2, 5, _rig.spec.hair, 0.05)
