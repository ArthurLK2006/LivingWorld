class_name V7InhabitantClothes
extends RefCounted
## [v7 CONGELADA, só para a cena de comparação] Roupa em CAMADAS sobre o tronco (ART-9d, protótipo isolado, só apresentação): gola ou capelo, cinto com fivela, avental (curto do aldeão com bolso; longo do comerciante com peitilho e alças), remendos, tabardo do guarda sobre o gibão com faixa de ouro e emblema, e as ombreiras de aço. Cada camada é uma casca loftada que acompanha o tronco (V7InhabitantRig.row_at), um pouco maior, com debrum e listras em cor por faceta. O tronco já leva a barra com debrum e as listras (V7InhabitantBody). LOD 1 leva gola, cinto e ombreiras; LOD 2 nada.

const COWL_LEVELS: Array[float] = [0.47, 0.53, 0.585, 0.63, 0.662]
const COWL_GROW: float = 1.1
const COWL_GAP_M: float = 0.012
const HOOD_CAP_DARKEN: float = 0.3
const COWL_LIGHTEN: float = 0.04
const COWL_EDGE_DARKEN: float = 0.12
## Gola (o pescoço da roupa, clara para não ler como barba): alturas (fração de H) e raios (fração de rx da cabeça).
const COLLAR_LEVELS: Array[float] = [0.625, 0.652, 0.675]
const COLLAR_RADII: Array[float] = [0.62, 0.5, 0.42]
const BELT_Y: Vector2 = Vector2(0.285, 0.335)
const BELT_GROW: float = 1.05
const BELT_BULGE: float = 1.012
const BUCKLE_RADIUS: Vector2 = Vector2(0.026, 0.034)
const BUCKLE_LIFT_M: float = 0.014
const BUCKLE_SIDES: int = 8
const BRASS: Color = Color("D6B04A")
const LEATHER: Color = Color("6A4630")
const GUARD_LEATHER: Color = Color("3E2E26")
## Aventais: alturas (fração de H) do avental curto, do longo (da barra ao cinto) e do peitilho, folga sobre o tronco e meio arco (rad).
const SHORT_APRON: Vector2 = Vector2(0.19, 0.335)
const LONG_APRON_TOP: float = 0.335
const BIB_TOP: float = 0.5
const APRON_GROW: float = 1.07
const APRON_ARC: Vector2 = Vector2(0.95, 1.05)
const BIB_ARC: float = 0.55
const STRAP_SPAN: Vector4 = Vector4(0.22, 0.5, 0.3, 0.6)
const STRAP_DARKEN: float = 0.15
const POCKET: Vector3 = Vector3(0.0, 0.25, 0.05)
## Remendos (x em fração da meia largura, altura em fração de H, meia largura e meia altura em fração de H) e levantamento (m).
const PATCHES: Array[Vector4] = [Vector4(0.35, 0.4, 0.05, 0.045), Vector4(-0.45, 0.24, 0.045, 0.055), Vector4(0.12, 0.5, 0.04, 0.04)]
const PATCH_LIFT_M: float = 0.007
## Tabardo do guarda: alturas, folga, abertura da barra e meio arco; emblema (altura, raio) em fração de H.
const TABARD_LEVELS: Array[float] = [0.2, 0.32, 0.44, 0.545, 0.6]
const TABARD_GROW: float = 1.07
const TABARD_FLARE: float = 0.07
const TABARD_ARC: float = 0.72
const TABARD_SIDES: int = 5
const EMBLEM: Vector2 = Vector2(0.46, 0.034)
const EMBLEM_LIFT_M: float = 0.016
const EMBLEM_INNER: float = 0.55
const EMBLEM_DARKEN: float = 0.35
## Ombreiras: raios (fração de H), levantamento sobre o ombro e polar máximo (graus).
const PAULDRON: Vector3 = Vector3(0.12, 0.075, 0.115)
const PAULDRON_LIFT: Vector2 = Vector2(0.025, 0.02)
const PAULDRON_DEG: float = 105.0

var _rig: V7InhabitantRig
var _shapes: V7InhabitantShapes


func _init(rig: V7InhabitantRig) -> void:
	_rig = rig
	_shapes = rig.shapes


## A cor do capuz e do capelo: a da cobertura (aldeão de capuz) ou a da roupa mais escura (capuz sob o boné).
static func hood_color(spec: V7InhabitantSpec) -> Color:
	return spec.top.darkened(HOOD_CAP_DARKEN) if spec.head_cover == V7InhabitantSpec.HeadCover.HOOD_CAP else spec.cover_color


func build() -> void:
	if _rig.lod == V7InhabitantRig.LOD_FAR:
		return
	_collar()
	_belt()
	if _rig.spec.has_pauldrons:
		_pauldrons()
	if not _rig.is_near:
		return
	if _rig.spec.apron == V7InhabitantSpec.Apron.SHORT:
		_short_apron()
	elif _rig.spec.apron == V7InhabitantSpec.Apron.LONG:
		_long_apron()
	if _rig.spec.garment == V7InhabitantSpec.Garment.TABARD:
		_tabard()
	if _rig.spec.fabric == V7InhabitantSpec.Fabric.PATCHED:
		_patches()


## Casca que acompanha o tronco nas alturas `levels` (fração de H): `grow` vezes o raio mais `gap` (m), com a barra `flare` mais aberta.
func _shell(levels: Array[float], grow: float, gap: float, color: Color, arc: Vector2 = V7InhabitantShapes.FULL_ARC, sides: int = 0, tint: Callable = Callable(), flare: float = 0.0) -> void:
	var rows: Array[Vector4] = []
	var shifts: PackedVector2Array = PackedVector2Array()
	for index: int in levels.size():
		var y: float = levels[index] * _rig.h
		var row: Vector4 = _rig.row_at(y)
		var opening: float = 1.0 + flare * (1.0 - float(index) / maxf(levels.size() - 1.0, 1.0))
		rows.append(Vector4(y, row.y * grow * opening + gap, row.z * grow * opening + gap, row.w))
		shifts.append(_rig.shift_at(y))
	_shapes.loft(V7InhabitantShapes.y_frame(Vector3.ZERO), rows, sides if sides > 0 else _rig.sides, color, 0.0, arc, shifts, tint)


func _front_arc(half: float) -> Vector2:
	return Vector2(V7InhabitantShapes.FRONT_ANGLE - half, V7InhabitantShapes.FRONT_ANGLE + half)


## Capelo liso e contínuo com o capuz (aldeão encapuzado) ou gola clara de camisa (os outros): sempre uma peça de pano abaixo do queixo, nunca uma faixa escura.
func _collar() -> void:
	var spec: V7InhabitantSpec = _rig.spec
	var head: Vector3 = _rig.head_r
	if spec.head_cover == V7InhabitantSpec.HeadCover.HOOD or spec.head_cover == V7InhabitantSpec.HeadCover.HOOD_CAP:
		var cowl: Color = hood_color(spec).lightened(COWL_LIGHTEN)
		var edge: Color = cowl.darkened(COWL_EDGE_DARKEN)
		_shell(COWL_LEVELS, COWL_GROW, COWL_GAP_M, cowl, V7InhabitantShapes.FULL_ARC, 0, func(ring: int, _side: int) -> Color: return edge if ring == 0 and _rig.is_near else cowl)
	if not _rig.is_near:
		return
	var rows: Array[Vector4] = []
	var shifts: PackedVector2Array = PackedVector2Array()
	for index: int in COLLAR_LEVELS.size():
		var y: float = COLLAR_LEVELS[index] * _rig.h
		rows.append(Vector4(y, COLLAR_RADII[index] * head.x, COLLAR_RADII[index] * head.z, 2.2))
		shifts.append(_rig.shift_at(y) * 0.5)
	_shapes.loft(V7InhabitantShapes.y_frame(Vector3.ZERO), rows, 8 if _rig.is_near else 6, spec.collar, 0.0, V7InhabitantShapes.FULL_ARC, shifts)


func _belt() -> void:
	var spec: V7InhabitantSpec = _rig.spec
	var color: Color = LEATHER
	if spec.role == V7InhabitantSpec.MERCHANT:
		color = spec.trim
	elif spec.role == V7InhabitantSpec.GUARD:
		color = GUARD_LEATHER
	var middle: float = (BELT_Y.x + BELT_Y.y) * 0.5
	var levels: Array[float] = [BELT_Y.x, BELT_Y.y]
	if _rig.is_near:
		levels = [BELT_Y.x, middle, BELT_Y.y]
	var rows: Array[Vector4] = []
	var shifts: PackedVector2Array = PackedVector2Array()
	for level: float in levels:
		var row: Vector4 = _rig.row_at(level * _rig.h)
		var grow: float = BELT_GROW * (BELT_BULGE if level == middle else 1.0)
		rows.append(Vector4(level * _rig.h, row.y * grow, row.z * grow, row.w))
		shifts.append(_rig.shift_at(level * _rig.h))
	_shapes.loft(V7InhabitantShapes.y_frame(Vector3.ZERO), rows, _rig.sides, color, 0.0, V7InhabitantShapes.FULL_ARC, shifts)
	if not _rig.is_near:
		return
	var radius: float = (BUCKLE_RADIUS.y if spec.role == V7InhabitantSpec.GUARD else BUCKLE_RADIUS.x) * _rig.h
	var lift: float = (BELT_GROW * BELT_BULGE - 1.0) * _rig.row_at(middle * _rig.h).z + BUCKLE_LIFT_M
	var center: Vector3 = _rig.on_body(0.0, middle * _rig.h, lift)
	for layer: int in 2:
		var size: float = radius * (1.0 if layer == 0 else 0.45)
		var edge: Array[Vector3] = []
		for index: int in BUCKLE_SIDES:
			var angle: float = TAU * index / BUCKLE_SIDES
			edge.append(center + Vector3(cos(angle) * size, sin(angle) * size * 0.8, -0.002 * layer))
		_shapes.fan(center + Vector3(0.0, 0.0, -0.003 * (layer + 1)), edge, BRASS if layer == 0 else color.darkened(0.2), center + Vector3(0.0, 0.0, 1.0))


func _short_apron() -> void:
	var spec: V7InhabitantSpec = _rig.spec
	var levels: Array[float] = [SHORT_APRON.x, (SHORT_APRON.x + SHORT_APRON.y) * 0.5, SHORT_APRON.y]
	_shell(levels, APRON_GROW, 0.0, spec.collar, _front_arc(APRON_ARC.x), 6, func(ring: int, _side: int) -> Color: return spec.collar.darkened(0.14) if ring == 0 else spec.collar, 0.05)
	var y: float = POCKET.y * _rig.h
	var pocket: float = POCKET.z * _rig.h
	var lift: float = (APRON_GROW - 1.0) * _rig.row_at(y).z + 0.006
	_shapes.quad(_rig.on_body(-pocket, y - pocket * 0.7, lift), _rig.on_body(pocket, y - pocket * 0.7, lift), _rig.on_body(pocket, y + pocket * 0.7, lift), _rig.on_body(-pocket, y + pocket * 0.7, lift), spec.alt, _rig.on_body(0.0, y, -0.3))


## Avental longo do comerciante: saia da barra ao cinto, peitilho estreito até o peito e duas alças que sobem aos ombros.
func _long_apron() -> void:
	var spec: V7InhabitantSpec = _rig.spec
	var low: float = _rig.hem_y() / _rig.h + 0.03
	var skirt: Array[float] = [low, (low + LONG_APRON_TOP) * 0.5, LONG_APRON_TOP]
	_shell(skirt, APRON_GROW, 0.0, spec.alt, _front_arc(APRON_ARC.y), 6, func(ring: int, _side: int) -> Color: return spec.trim if ring == 0 else spec.alt, 0.06)
	var bib: Array[float] = [LONG_APRON_TOP, (LONG_APRON_TOP + BIB_TOP) * 0.5, BIB_TOP]
	_shell(bib, APRON_GROW, 0.0, spec.alt, _front_arc(BIB_ARC), 4)
	var strap: Color = spec.alt.darkened(STRAP_DARKEN)
	for side: float in [-1.0, 1.0]:
		var bottom: Vector3 = _rig.on_body(side * STRAP_SPAN.x * _rig.r, STRAP_SPAN.y * _rig.h, 0.012)
		var top: Vector3 = _rig.on_body(side * STRAP_SPAN.z * _rig.r, STRAP_SPAN.w * _rig.h, 0.012)
		_shapes.ribbon([bottom, top], Vector3(0.02 * _rig.h, 0.0, 0.0), strap, bottom + Vector3(0.0, 0.0, 0.3))


func _patches() -> void:
	var alt: Color = _rig.body_color().lerp(_rig.spec.alt, 0.6)
	for patch: Vector4 in PATCHES:
		var y: float = patch.y * _rig.h
		var x: float = patch.x * _rig.half_width(y)
		var wide: float = patch.z * _rig.h
		var tall: float = patch.w * _rig.h
		var lift: float = PATCH_LIFT_M
		_shapes.quad(_rig.on_body(x - wide, y - tall, lift), _rig.on_body(x + wide, y - tall, lift), _rig.on_body(x + wide, y + tall, lift), _rig.on_body(x - wide, y + tall, lift), alt, _rig.on_body(x, y, -0.3))


## Tabardo sobre o gibão: painel da frente e das costas (gola ao ouro da barra), faixa de ouro na barra e emblema no peito.
func _tabard() -> void:
	var spec: V7InhabitantSpec = _rig.spec
	var gold: Color = spec.trim
	var tint: Callable = func(ring: int, _side: int) -> Color: return gold if ring == 0 else spec.top
	_shell(TABARD_LEVELS, TABARD_GROW, 0.0, spec.top, _front_arc(TABARD_ARC), TABARD_SIDES, tint, TABARD_FLARE)
	_shell(TABARD_LEVELS, TABARD_GROW, 0.0, spec.top, Vector2(V7InhabitantShapes.BACK_ANGLE - TABARD_ARC, V7InhabitantShapes.BACK_ANGLE + TABARD_ARC), TABARD_SIDES, tint, TABARD_FLARE)
	var y: float = EMBLEM.x * _rig.h
	var radius: float = EMBLEM.y * _rig.h
	var lift: float = (TABARD_GROW - 1.0) * _rig.row_at(y).z + EMBLEM_LIFT_M
	var center: Vector3 = _rig.on_body(0.0, y, lift)
	for layer: int in 2:
		var edge: Array[Vector3] = []
		var size: float = radius * (1.0 if layer == 0 else EMBLEM_INNER)
		for index: int in 10:
			var angle: float = TAU * index / 10.0
			edge.append(center + Vector3(cos(angle) * size, sin(angle) * size, -0.002 * layer))
		_shapes.fan(center + Vector3(0.0, 0.0, -0.003 * (layer + 1)), edge, gold if layer == 0 else spec.top.darkened(EMBLEM_DARKEN), center + Vector3(0.0, 0.0, 1.0))


## Ombreiras de aço (cúpula com a borda de ouro) sobre os ombros: dão ao guarda a silhueta de trapézio.
func _pauldrons() -> void:
	var spec: V7InhabitantSpec = _rig.spec
	var y: float = V7InhabitantBody.SHOULDER_Y[spec.role] * _rig.h
	var steel: Color = spec.cover_color
	var gold: Color = spec.trim
	var bands: int = 3 if _rig.is_near else 2
	var rows: Array[Vector4] = V7InhabitantShapes.dome(PAULDRON * _rig.h, 0.0, PAULDRON_DEG, bands)
	for side: float in [-1.0, 1.0]:
		var shift: Vector2 = _rig.shift_at(y)
		var center: Vector3 = Vector3(side * _rig.half_width(y) * V7InhabitantBody.SHOULDER_IN + shift.x + side * PAULDRON_LIFT.x * _rig.h, y + PAULDRON_LIFT.y * _rig.h, shift.y)
		_shapes.loft(V7InhabitantShapes.y_frame(center), rows, 8 if _rig.is_near else 6, steel, 0.02, V7InhabitantShapes.FULL_ARC, PackedVector2Array(), func(ring: int, _side: int) -> Color: return gold if ring == bands - 1 and _rig.is_near else steel)
