class_name InhabitantHats
extends RefCounted
## Coberturas de pano e enfeites (ART-9e, protótipo isolado, só apresentação): lenço de cabeça amarrado (calota com aba na testa, painel que cobre as orelhas e a nuca, nó e pontas), boina caída de lado, gorro de lã (cuco com dobra e pompom) e a pena do chapéu largo. Tudo loftado e em fração dos raios da cabeça; de longe, uma casca simples.

const KERCHIEF_SHELL: Array[Vector3] = [Vector3(0.0, 0.64, 0.02), Vector3(1.08, 0.5, 1.1)]
const KERCHIEF_DEG: float = 100.0
const KERCHIEF_BACK: Array[Vector4] = [Vector4(0.45, 1.1, 1.12, 2.3), Vector4(0.0, 1.1, 1.14, 2.3), Vector4(-0.62, 0.98, 1.06, 2.3)]
const KERCHIEF_ARC: float = 1.55
const KNOT: Vector3 = Vector3(0.0, -0.05, 1.12)
const BERET_SHELL: Array[Vector3] = [Vector3(0.16, 0.66, 0.0), Vector3(1.22, 0.4, 1.18)]
const BERET_DEG: float = 125.0
const WOOL_SHELL: Array[Vector3] = [Vector3(0.0, 0.72, 0.02), Vector3(1.07, 0.75, 1.09)]
const WOOL_DEG: float = 104.0
const WOOL_CUFF: Array[Vector4] = [Vector4(0.4, 1.1, 1.12, 2.3), Vector4(0.54, 1.14, 1.16, 2.3), Vector4(0.68, 1.1, 1.12, 2.3)]
const FEATHER_ROOT: Vector3 = Vector3(-0.95, 0.52, -0.05)
const FEATHER_PATH: Array[Vector3] = [Vector3(-0.2, 0.45, 0.3), Vector3(-0.1, 0.95, 0.7), Vector3(0.1, 1.2, 1.15)]
const FEATHER_WIDTHS: Array[float] = [0.06, 0.1, 0.09, 0.02]

var _rig: InhabitantRig
var _shapes: InhabitantShapes


func _init(rig: InhabitantRig) -> void:
	_rig = rig
	_shapes = rig.shapes


func _bands(near: int, far: int) -> int:
	return near if _rig.is_near else (near - 1 if _rig.lod == InhabitantRig.LOD_MID else far)


## Lenço: calota alta (a aba fica acima das sobrancelhas, na cor de apoio mais escura), painel de trás sobre as orelhas e a nuca, nó e duas pontas caídas.
func kerchief() -> void:
	var head: Vector3 = _rig.head_r
	var color: Color = _rig.spec.cover_color
	var bands: int = _bands(4, 2)
	var rows: Array[Vector4] = InhabitantShapes.dome(KERCHIEF_SHELL[1] * head, 0.0, KERCHIEF_DEG, bands)
	var edge: Color = _rig.spec.alt.darkened(0.12)
	_shapes.loft(InhabitantShapes.y_frame(_rig.head_c + KERCHIEF_SHELL[0] * head), rows, _rig.sides, color, 0.015, InhabitantShapes.FULL_ARC, PackedVector2Array(), func(ring: int, _side: int) -> Color: return edge if ring == bands - 1 and _rig.is_near else color)
	if not _rig.is_near:
		return
	var back: Array[Vector4] = []
	for row: Vector4 in KERCHIEF_BACK:
		back.append(Vector4(row.x * head.y, row.y * head.x, row.z * head.z, row.w))
	var behind: float = InhabitantShapes.BACK_ANGLE
	_shapes.loft(InhabitantShapes.y_frame(_rig.head_c), back, 8, color, 0.015, Vector2(behind - KERCHIEF_ARC, behind + KERCHIEF_ARC))
	var knot: Vector3 = _rig.head_c + KNOT * head
	_shapes.ball(knot, Vector3(0.2, 0.16, 0.16) * head.x, 2, 6, color.darkened(0.06), 0.06)
	for side: float in [-1.0, 1.0]:
		_shapes.limb(knot, knot + Vector3(side * 0.13 * head.x, -0.75 * head.y, 0.08 * head.z), Vector2(0.1, 0.05) * head.x, Vector2(0.06, 0.03) * head.x, 4, color, 2, 0.15)


## Boina: disco achatado caído para um lado, com a borda de apoio e o cabinho no alto.
func beret() -> void:
	var head: Vector3 = _rig.head_r
	var color: Color = _rig.spec.cover_color
	var center: Vector3 = _rig.head_c + BERET_SHELL[0] * head
	var bands: int = _bands(4, 2)
	var rim: Color = _rig.spec.trim
	var rows: Array[Vector4] = InhabitantShapes.dome(BERET_SHELL[1] * head, 0.0, BERET_DEG, bands)
	_shapes.loft(InhabitantShapes.y_frame(center), rows, _rig.sides, color, 0.02, InhabitantShapes.FULL_ARC, PackedVector2Array(), func(ring: int, _side: int) -> Color: return rim if ring == bands - 1 and _rig.is_near else color)
	if _rig.is_near:
		_shapes.limb(center + Vector3(0.0, BERET_SHELL[1].y * head.y * 0.95, 0.0), center + Vector3(0.0, BERET_SHELL[1].y * head.y * 1.18, 0.0), Vector2(0.06, 0.06) * head.x, Vector2(0.04, 0.04) * head.x, 5, rim.darkened(0.1), 1)


## Gorro de lã: cuco alto com a dobra (cuff) na cor de apoio e o pompom no alto.
func wool_cap() -> void:
	var head: Vector3 = _rig.head_r
	var color: Color = _rig.spec.cover_color
	var center: Vector3 = _rig.head_c + WOOL_SHELL[0] * head
	var rows: Array[Vector4] = InhabitantShapes.dome(WOOL_SHELL[1] * head, 0.0, WOOL_DEG, _bands(4, 2))
	_shapes.loft(InhabitantShapes.y_frame(center), rows, _rig.sides, color, 0.02)
	if not _rig.is_near:
		return
	var cuff: Array[Vector4] = []
	for row: Vector4 in WOOL_CUFF:
		cuff.append(Vector4(row.x * head.y, row.y * head.x, row.z * head.z, row.w))
	_shapes.loft(InhabitantShapes.y_frame(_rig.head_c), cuff, _rig.sides, _rig.spec.trim.darkened(0.05), 0.015)
	var radius: float = 0.15 * head.x
	_shapes.ball(center + Vector3(0.0, WOOL_SHELL[1].y * head.y * 1.0, 0.1 * head.z), Vector3(radius, radius, radius), 2, 6, _rig.spec.trim, 0.06)


## Pena do chapéu largo: três pedaços curvos que sobem da fita e caem para trás.
func feather() -> void:
	var head: Vector3 = _rig.head_r
	var root: Vector3 = _rig.head_c + FEATHER_ROOT * head
	var color: Color = _rig.spec.alt.lightened(0.3)
	var stops: Array[Vector3] = [root]
	for step: Vector3 in FEATHER_PATH:
		stops.append(root + step * head)
	for index: int in stops.size() - 1:
		var from: float = FEATHER_WIDTHS[index] * head.x
		var to: float = FEATHER_WIDTHS[index + 1] * head.x
		_shapes.limb(stops[index], stops[index + 1], Vector2(from, from * 0.35), Vector2(to, to * 0.35), 4, color, 1, 0.1, Vector3.RIGHT)
