class_name InhabitantLayers
extends RefCounted
## Camadas de roupa extras (ART-9e, protótipo isolado, só apresentação): faixa larga com nó e pontas, cinto de corda com nó (os dois no lugar do cinto de couro), xale sobre os ombros e cachecol enrolado no pescoço com a ponta caída no peito; todas cascas ou fitas que acompanham o tronco (InhabitantRig.row_at). LOD 1 leva faixa e corda; só o LOD 0 leva xale e cachecol; LOD 2 nada.

const SASH_LEVELS: Array[float] = [0.335, 0.37, 0.405]
const SASH_GROW: float = 1.06
const ROPE_LEVELS: Array[float] = [0.34, 0.352]
const ROPE_GROW: float = 1.045
const ROPE_COLOR: Color = Color("A88A55")
const TAIL_LENGTH: float = 0.11
const SHAWL_LEVELS: Array[float] = [0.4, 0.46, 0.52, 0.575, 0.62]
const SHAWL_GROW: float = 1.1
const SHAWL_GAP_M: float = 0.012
const SHAWL_OPEN: float = 0.55
const SHAWL_DARKEN: float = 0.14
const WRAP_LEVELS: Array[float] = [0.628, 0.646, 0.664]
const WRAP_RADII: Array[float] = [0.74, 0.82, 0.7]
const WRAP_TAIL_X: float = 0.05
const WRAP_TAIL_Y: Vector3 = Vector3(0.625, 0.53, 0.44)

var _rig: InhabitantRig
var _shapes: InhabitantShapes


func _init(rig: InhabitantRig) -> void:
	_rig = rig
	_shapes = rig.shapes


func build() -> void:
	if _rig.lod == InhabitantRig.LOD_FAR:
		return
	if _rig.spec.waist == InhabitantSpec.Waist.SASH:
		_sash()
	elif _rig.spec.waist == InhabitantSpec.Waist.ROPE:
		_rope()
	if not _rig.is_near:
		return
	if _rig.spec.neck_wrap == InhabitantSpec.Wrap.SHAWL:
		_shawl()
	elif _rig.spec.neck_wrap == InhabitantSpec.Wrap.SCARF:
		_neckcloth()


## Faixa larga em volta do quadril e da cintura, com o nó do lado esquerdo e duas pontas caídas.
func _sash() -> void:
	var color: Color = _rig.spec.alt
	_rig.shell(SASH_LEVELS, SASH_GROW, 0.004, color, InhabitantShapes.FULL_ARC, 0, func(ring: int, _side: int) -> Color: return color if ring == 1 else color.darkened(0.12))
	if _rig.is_near:
		_knot(SASH_LEVELS[1], color, 0.026)


## Cinto de corda fino com nó e duas pontas.
func _rope() -> void:
	_rig.shell(ROPE_LEVELS, ROPE_GROW, 0.004, ROPE_COLOR)
	if _rig.is_near:
		_knot(ROPE_LEVELS[0], ROPE_COLOR, 0.018)


func _knot(level: float, color: Color, size: float) -> void:
	var h: float = _rig.h
	var y: float = level * h
	var knot: Vector3 = _rig.on_body(-_rig.half_width(y) * 0.5, y, 0.02)
	_shapes.ball(knot, Vector3(size, size * 0.85, size * 0.75) * h, 2, 5, color.darkened(0.06), 0.05)
	for side: float in [-1.0, 1.0]:
		var end: Vector3 = knot + Vector3(side * 0.025 * h, -TAIL_LENGTH * h, -0.012 * h)
		_shapes.limb(knot, end, Vector2(size * 0.45, size * 0.2) * h, Vector2(size * 0.4, size * 0.16) * h, 4, color.darkened(0.1), 1)


## Xale: casca aberta na frente em V sobre os ombros e as costas, com a barra mais escura.
func _shawl() -> void:
	var color: Color = _rig.spec.alt.darkened(0.05)
	var arc: Vector2 = Vector2(InhabitantShapes.FRONT_ANGLE + SHAWL_OPEN, InhabitantShapes.FRONT_ANGLE + TAU - SHAWL_OPEN)
	_rig.shell(SHAWL_LEVELS, SHAWL_GROW, SHAWL_GAP_M, color, arc, 10, func(ring: int, _side: int) -> Color: return color.darkened(SHAWL_DARKEN) if ring == 0 else color)


## Cachecol: duas voltas grossas no pescoço e a ponta caída no peito.
func _neckcloth() -> void:
	var spec: InhabitantSpec = _rig.spec
	var head: Vector3 = _rig.head_r
	var rows: Array[Vector4] = []
	var shifts: PackedVector2Array = PackedVector2Array()
	for index: int in WRAP_LEVELS.size():
		var y: float = WRAP_LEVELS[index] * _rig.h
		rows.append(Vector4(y, WRAP_RADII[index] * head.x, WRAP_RADII[index] * head.z, 2.2))
		shifts.append(_rig.shift_at(y) * 0.5)
	_shapes.loft(InhabitantShapes.y_frame(Vector3.ZERO), rows, 8, spec.alt, 0.0, InhabitantShapes.FULL_ARC, shifts)
	var x: float = WRAP_TAIL_X * _rig.h
	var points: Array[Vector3] = [_rig.on_body(x, WRAP_TAIL_Y.x * _rig.h, 0.03), _rig.on_body(x * 1.3, WRAP_TAIL_Y.y * _rig.h, 0.03), _rig.on_body(x * 1.1, WRAP_TAIL_Y.z * _rig.h, 0.03)]
	_shapes.ribbon(points, Vector3(0.026 * _rig.h, 0.0, 0.0), spec.alt.darkened(0.06), points[0] + Vector3(0.0, 0.0, 0.3))
