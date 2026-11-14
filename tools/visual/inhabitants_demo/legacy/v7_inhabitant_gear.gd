class_name V7InhabitantGear
extends RefCounted
## [v7 CONGELADA, só para a cena de comparação] Acessórios do habitante (ART-9d, protótipo isolado, só apresentação), orgânicos e nada de caixinha: cesta tecida (anéis e alça em arco), saco de pescoço amarrado com volumes, bolsa de couro arredondada (aba curva, alça e fivela), bolsinha de moedas pendurada, trouxa nas costas, lampião, hastes (cajado, lança de lâmina em folha com flâmula, cajado de guarda), escudo redondo com botão e bainha no cinto. LOD 1 leva só os de silhueta (menos facetas); LOD 2, os grandes (cesta, saco e hastes).

const MID_KINDS: Array[StringName] = [&"basket", &"sack", &"staff", &"spear", &"guard_staff", &"satchel", &"bundle"]
const FAR_KINDS: Array[StringName] = [&"basket", &"sack", &"staff", &"spear", &"guard_staff"]
const WOOD: Color = Color("B07A45")
const WOOD_DARK: Color = Color("7A5230")
const BAG: Color = Color("8B5A33")
const BAG_FLAP: Color = Color("6E4426")
const STRAP: Color = Color("5A3A24")
const STEEL: Color = Color("A9B2BC")
const DARK_METAL: Color = Color("3A3A40")
const WICKER: Color = Color("C09A55")
const BURLAP: Color = Color("B89B68")
const ROPE: Color = Color("8A6A3A")
const GLASS: Color = Color("FFC24D")
const APPLE: Color = Color("C0452F")
const BRASS: Color = Color("D6B04A")
const PLUME_RED: Color = Color("B83A32")
const COIN: Color = Color("E8B84A")
## Cesta (raio da base, do aro e altura, fração de H), alça, maçãs; saco (raios); bolsa (largura, altura, profundidade), lugar (altura, x sobre o raio) e giro; bolsinha; trouxa.
const BASKET: Vector3 = Vector3(0.085, 0.11, 0.11)
const HANDLE_RADIUS: float = 0.009
const HANDLE_SEGMENTS: int = 5
const SACK: Vector3 = Vector3(0.115, 0.125, 0.105)
const SATCHEL: Vector3 = Vector3(0.2, 0.15, 0.085)
const SATCHEL_SPOT: Vector2 = Vector2(0.32, 0.8)
const SATCHEL_YAW: float = 0.5
const STRAP_RADII: Vector2 = Vector2(0.03, 0.011)
const POUCH_RADIUS: float = 0.038
const POUCH_SPOT: Vector2 = Vector2(0.27, 0.66)
const BUNDLE: Vector3 = Vector3(0.1, 0.11, 0.09)
const BUNDLE_Y: float = 0.46
const LANTERN_SIZE: float = 0.055
const LANTERN_DROP: float = 0.1
## Hastes (altura do topo, raio, ponta: fração de H); lâmina (meia largura, afinamento) e flâmula (comprimento, altura, sobra para trás); escudo (raio, lugar da mão, giro) e bainha.
const POLES: Dictionary[StringName, Vector3] = {&"staff": Vector3(1.02, 0.02, 0.0), &"spear": Vector3(0.92, 0.014, 0.13), &"guard_staff": Vector3(0.95, 0.022, 0.07)}
const BLADE_HALF: float = 0.04
const BLADE_THIN: float = 0.22
const PENNANT: Vector3 = Vector3(0.17, 0.06, 0.045)
const SHIELD_RADIUS: float = 0.105
const SHIELD_SPOT: Vector3 = Vector3(-0.03, 0.06, -0.07)
const SHIELD_YAW: float = 0.45
const SCABBARD: Vector3 = Vector3(0.1, 0.33, 0.12)

var _rig: V7InhabitantRig
var _shapes: V7InhabitantShapes
var _h: float


func _init(rig: V7InhabitantRig) -> void:
	_rig = rig
	_shapes = rig.shapes
	_h = rig.h


func build() -> void:
	for kind: StringName in _rig.spec.accessories:
		if _rig.is_near or (_rig.lod == V7InhabitantRig.LOD_MID and MID_KINDS.has(kind)) or FAR_KINDS.has(kind):
			_accessory(kind)
	if _rig.spec.has_shield and _rig.lod != V7InhabitantRig.LOD_FAR:
		_shield()
	if _rig.spec.role == V7InhabitantSpec.GUARD and _rig.is_near:
		_scabbard()


func _sides(near: int) -> int:
	return near if _rig.is_near else (maxi(near - 2, 4) if _rig.lod == V7InhabitantRig.LOD_MID else maxi(near - 4, 4))


func _accessory(kind: StringName) -> void:
	match kind:
		&"satchel":
			_satchel()
		&"coin_pouch":
			_pouch()
		&"basket":
			_basket()
		&"sack":
			_sack()
		&"bundle":
			_bundle()
		&"lantern":
			_lantern()
		_:
			if POLES.has(kind):
				_pole(kind)


## Cesta tecida: fundo, barriga, aro; facetas alternadas de palha clara e escura dão a trama; alça de madeira em arco e maçãs.
func _basket() -> void:
	var size: Vector3 = BASKET * _h
	var center: Vector3 = _rig.carry()
	var half: float = size.z * 0.5
	var rows: Array[Vector4] = [Vector4(-half, 0.0, 0.0, 2.0), Vector4(-half, size.x, size.x, 2.2), Vector4(-half * 0.15, (size.x + size.y) * 0.54, (size.x + size.y) * 0.54, 2.2), Vector4(half - 0.012 * _h, size.y, size.y, 2.2), Vector4(half, size.y * 1.06, size.y * 1.06, 2.2), Vector4(half + 0.014 * _h, size.y * 1.06, size.y * 1.06, 2.2)]
	if not _rig.is_near:
		rows = [rows[0], rows[1], rows[4], Vector4(half, 0.0, 0.0, 2.0)]
	var dark: Color = WICKER.darkened(0.14)
	var rim: Color = WOOD_DARK
	var is_near: bool = _rig.is_near
	_shapes.loft(V7InhabitantShapes.y_frame(center), rows, _sides(10), WICKER, 0.02, V7InhabitantShapes.FULL_ARC, PackedVector2Array(), func(ring: int, side: int) -> Color: return rim if ring >= 3 and is_near else (dark if (ring + side) % 2 == 0 else WICKER))
	if not _rig.is_near:
		return
	var top: Vector3 = center + Vector3(0.0, half + 0.007 * _h, 0.0)
	var previous: Vector3 = top + Vector3(-size.y, 0.0, 0.0)
	for index: int in range(1, HANDLE_SEGMENTS + 1):
		var angle: float = PI - PI * index / HANDLE_SEGMENTS
		var point: Vector3 = top + Vector3(cos(angle) * size.y, sin(angle) * size.y * 0.95, 0.0)
		_shapes.limb(previous, point, Vector2(HANDLE_RADIUS, HANDLE_RADIUS) * _h, Vector2(HANDLE_RADIUS, HANDLE_RADIUS) * _h, 4, WOOD_DARK, 1, 0.0, Vector3.FORWARD)
		previous = point
	for side: float in [-1.0, 1.0]:
		_shapes.ball(top + Vector3(side * size.y * 0.42, size.y * 0.1, 0.0), Vector3(size.y, size.y, size.y) * 0.3, 2, 6, APPLE, 0.06)


## Saco de estopa: corpo cheio, dois volumes na frente e o pescoço franzido amarrado com corda.
func _sack() -> void:
	var radii: Vector3 = SACK * _h
	var center: Vector3 = _rig.carry()
	_shapes.ball(center, radii, 4 if _rig.is_near else 3, _sides(8), BURLAP, 0.08)
	if not _rig.is_near:
		return
	var neck: Vector3 = center + Vector3(0.0, radii.y * 0.9, 0.0)
	_shapes.limb(neck, neck + Vector3(0.0, 0.07 * _h, 0.0), Vector2(0.06, 0.06) * _h, Vector2(0.03, 0.03) * _h, 6, BURLAP, 1, 0.2)
	_shapes.limb(neck + Vector3(0.0, 0.032 * _h, 0.0), neck + Vector3(0.0, 0.044 * _h, 0.0), Vector2(0.044, 0.044) * _h, Vector2(0.044, 0.044) * _h, 6, ROPE)
	_shapes.ball(neck + Vector3(0.0, 0.085 * _h, 0.0), Vector3(0.05, 0.036, 0.05) * _h, 2, 6, BURLAP, 0.1)
	for side: float in [-1.0, 1.0]:
		_shapes.ball(center + Vector3(side * radii.x * 0.5, -radii.y * 0.1, -radii.z * 0.78), Vector3(0.05, 0.055, 0.04) * _h, 2, 6, BURLAP.darkened(0.06), 0.1)


## Bolsa de couro arredondada de aba curva, fivela e alça de fita em diagonal; de longe, só o corpo.
func _satchel() -> void:
	var y: float = SATCHEL_SPOT.x * _h
	var size: Vector3 = SATCHEL * _h * 0.5
	var spot: Vector3 = _rig.on_body(-_rig.half_width(y) * SATCHEL_SPOT.y, y, size.z * 0.9)
	var frame: Transform3D = V7InhabitantShapes.y_frame(spot, SATCHEL_YAW)
	var rows: Array[Vector4] = [Vector4(-size.y, 0.0, 0.0, 3.0), Vector4(-size.y, size.x * 0.86, size.z * 0.86, 3.4), Vector4(-size.y * 0.4, size.x * 0.98, size.z, 3.4), Vector4(size.y * 0.5, size.x, size.z, 3.4), Vector4(size.y, size.x * 0.92, size.z * 0.88, 3.4), Vector4(size.y, 0.0, 0.0, 3.0)]
	_shapes.loft(frame, rows, _sides(8), BAG, 0.015)
	if not _rig.is_near:
		return
	var flap: Array[Vector4] = [Vector4(size.y * 1.02, size.x * 1.0, size.z * 1.06, 3.4), Vector4(size.y * 0.55, size.x * 1.04, size.z * 1.12, 3.4), Vector4(size.y * 0.1, size.x * 0.92, size.z * 1.12, 3.4), Vector4(-size.y * 0.22, size.x * 0.55, size.z * 0.78, 3.4)]
	_shapes.loft(frame, flap, _sides(8), BAG_FLAP, 0.0, Vector2(V7InhabitantShapes.FRONT_ANGLE - 1.35, V7InhabitantShapes.FRONT_ANGLE + 1.35))
	var clasp: Vector3 = frame * Vector3(0.0, -size.y * 0.16, -size.z * 1.14)
	var edge: Array[Vector3] = []
	for index: int in 6:
		edge.append(clasp + Vector3(cos(TAU * index / 6.0), sin(TAU * index / 6.0), 0.0) * size.x * 0.13)
	_shapes.fan(clasp + Vector3(0.0, 0.0, -0.004), edge, BRASS, clasp + Vector3(0.0, 0.0, 1.0))
	var shoulder_y: float = (0.6 if _rig.spec.head_cover == V7InhabitantSpec.HeadCover.HOOD or _rig.spec.head_cover == V7InhabitantSpec.HeadCover.HOOD_CAP else 0.565) * _h
	var from: Vector3 = _rig.on_body(_rig.half_width(shoulder_y) * 0.45, shoulder_y, 0.014)
	var to: Vector3 = frame * Vector3(0.0, size.y, 0.0)
	var middle: Vector3 = _rig.on_body((from.x + to.x) * 0.5, (from.y + to.y) * 0.5, 0.014)
	for pair: Array in [[from, middle], [middle, to]]:
		var start: Vector3 = pair[0]
		var finish: Vector3 = pair[1]
		_shapes.limb(start, finish, STRAP_RADII * _h, STRAP_RADII * _h, 4, STRAP, 1, 0.0, Vector3.FORWARD, 3.0)


## Bolsinha de moedas pendurada no cinto: bojo redondo, pescoço franzido e cordão.
func _pouch() -> void:
	var y: float = POUCH_SPOT.x * _h
	var radius: float = POUCH_RADIUS * _h
	var spot: Vector3 = _rig.on_body(_rig.half_width(y) * POUCH_SPOT.y, y, radius * 0.5)
	_shapes.ball(spot, Vector3(radius, radius * 1.15, radius), 3 if _rig.is_near else 2, _sides(7), BAG, 0.1)
	if not _rig.is_near:
		return
	_shapes.limb(spot + Vector3(0.0, radius * 1.0, 0.0), spot + Vector3(0.0, radius * 1.5, 0.0), Vector2(radius * 0.5, radius * 0.5), Vector2(radius * 0.28, radius * 0.28), 6, BAG_FLAP, 1)
	_shapes.limb(spot + Vector3(0.0, radius * 1.5, 0.0), _rig.on_body(spot.x * 0.9, 0.31 * _h, 0.02), Vector2(0.006, 0.006) * _h, Vector2(0.006, 0.006) * _h, 4, ROPE)
	_shapes.ball(spot + Vector3(0.0, radius * 0.1, -radius * 0.8), Vector3(radius * 0.45, radius * 0.45, radius * 0.1), 2, 6, COIN, 0.0)


## Trouxa nas costas do comerciante: embrulho cheio, nó de pano no alto e a fita que passa pelo ombro.
func _bundle() -> void:
	var y: float = BUNDLE_Y * _h
	var radii: Vector3 = BUNDLE * _h
	var back: float = _rig.shift_at(y).y + _rig.row_at(y).z + radii.z * 0.7
	var center: Vector3 = Vector3(0.0, y, back)
	var cloth: Color = _rig.spec.alt.darkened(0.1)
	_shapes.ball(center, radii, 3 if _rig.is_near else 2, _sides(8), cloth, 0.07)
	if not _rig.is_near:
		return
	_shapes.limb(center + Vector3(0.0, radii.y * 0.8, 0.0), center + Vector3(0.0, radii.y * 1.5, 0.0), Vector2(0.05, 0.05) * _h, Vector2(0.02, 0.02) * _h, 5, cloth, 1, 0.3)
	_shapes.ball(center + Vector3(0.0, radii.y * 1.55, 0.0), Vector3(0.04, 0.03, 0.04) * _h, 2, 5, cloth, 0.1)
	var shoulder: float = 0.585 * _h
	for side: float in [-1.0, 1.0]:
		var points: Array[Vector3] = [Vector3(side * radii.x * 0.7, y + radii.y * 0.4, back - radii.z * 0.6), Vector3(side * _rig.half_width(shoulder) * 0.62, shoulder, _rig.shift_at(shoulder).y + _rig.row_at(shoulder).z * 0.5), _rig.on_body(side * _rig.half_width(0.5 * _h) * 0.55, 0.5 * _h, 0.01)]
		_shapes.ribbon(points, Vector3(0.016 * _h, 0.0, 0.0), STRAP, center)


func _lantern() -> void:
	var size: float = LANTERN_SIZE * _h
	var body: Vector3 = _rig.hands[0] + Vector3.DOWN * LANTERN_DROP * _h
	var glass: Array[Vector4] = [Vector4(-size * 0.65, 0.0, 0.0, 2.0), Vector4(-size * 0.65, size * 0.55, size * 0.55, 2.2), Vector4(0.0, size * 0.8, size * 0.8, 2.2), Vector4(size * 0.65, size * 0.55, size * 0.55, 2.2), Vector4(size * 0.65, 0.0, 0.0, 2.0)]
	_shapes.loft(V7InhabitantShapes.y_frame(body), glass, 6 if _rig.is_near else 5, GLASS, 0.03)
	var cap: Array[Vector4] = [Vector4(size * 0.65, size * 0.85, size * 0.85, 2.2), Vector4(size * 1.05, 0.0, 0.0, 2.2)]
	_shapes.loft(V7InhabitantShapes.y_frame(body), cap, 6 if _rig.is_near else 5, DARK_METAL)
	_shapes.limb(_rig.hands[0], body + Vector3(0.0, size * 0.95, 0.0), Vector2(0.008, 0.008) * _h, Vector2(0.008, 0.008) * _h, 4, DARK_METAL)


func _pole(kind: StringName) -> void:
	var shape: Vector3 = POLES[kind]
	var grip: Vector3 = _rig.hands[1]
	var top: Vector3 = Vector3(grip.x, shape.x * _h, grip.z)
	var radius: float = shape.y * _h
	_shapes.limb(Vector3(grip.x, 0.0, grip.z), top, Vector2(radius * 1.15, radius * 1.15), Vector2(radius, radius), _sides(6), WOOD_DARK, 1)
	match kind:
		&"spear":
			_blade(top, shape.z * _h)
		&"guard_staff":
			_shapes.ball(top + Vector3(0.0, 0.025 * _h, 0.0), Vector3(0.03, 0.04, 0.03) * _h, 2, _sides(6), STEEL, 0.03)
			_shapes.limb(top - Vector3(0.0, 0.01 * _h, 0.0), top + Vector3(0.0, 0.006 * _h, 0.0), Vector2(0.034, 0.034) * _h, Vector2(0.034, 0.034) * _h, _sides(6), DARK_METAL)
		_:
			if _rig.is_near:
				_shapes.ball(top, Vector3(0.03, 0.035, 0.03) * _h, 2, 6, WOOD, 0.1)


## Lâmina em folha (lente achatada, mais larga acima do meio), soquete e flâmula de duas faces.
func _blade(base: Vector3, length: float) -> void:
	var half: float = BLADE_HALF * _h
	var rows: Array[Vector4] = []
	var stops: Array[Vector2] = [Vector2(0.0, 0.3), Vector2(0.45, 1.0), Vector2(1.0, 0.0)]
	if _rig.lod != V7InhabitantRig.LOD_FAR:
		stops = [Vector2(0.0, 0.3), Vector2(0.2, 0.9), Vector2(0.45, 1.0), Vector2(0.8, 0.5), Vector2(1.0, 0.0)]
	for stop: Vector2 in stops:
		rows.append(Vector4(stop.x * length, stop.y * half, stop.y * half * BLADE_THIN, 2.0))
	_shapes.loft(V7InhabitantShapes.y_frame(base), rows, 6 if _rig.is_near else 4, STEEL)
	if _rig.lod == V7InhabitantRig.LOD_FAR:
		return
	var grip: Vector3 = Vector3(base.x, base.y, base.z)
	var upper: Vector3 = grip + Vector3(0.0, -0.012 * _h, 0.0)
	var lower: Vector3 = grip + Vector3(0.0, -PENNANT.y * _h, 0.0)
	var tip: Vector3 = grip + Vector3(PENNANT.x * _h, -PENNANT.y * 0.55 * _h, PENNANT.z * _h)
	var wave: Array[Vector3] = [upper, upper.lerp(tip, 0.5) + Vector3(0.0, 0.014 * _h, 0.012 * _h), tip, lower.lerp(tip, 0.5) + Vector3(0.0, -0.01 * _h, 0.02 * _h), lower]
	_shapes.sheet(wave, PLUME_RED)
	if _rig.is_near:
		_shapes.limb(base + Vector3(0.0, -0.025 * _h, 0.0), base + Vector3(0.0, 0.004 * _h, 0.0), Vector2(0.02, 0.02) * _h, Vector2(0.016, 0.016) * _h, 6, DARK_METAL)


## Escudo redondo no braço esquerdo: disco de cara do tabardo com a borda de aço, costas de couro e o botão de metal no centro.
func _shield() -> void:
	var radius: float = SHIELD_RADIUS * _h
	var center: Vector3 = _rig.hands[0] + SHIELD_SPOT * _h
	var spec: V7InhabitantSpec = _rig.spec
	var face: Color = spec.top
	var rim: Color = STEEL
	var back: Color = STRAP
	var rows: Array[Vector4] = [Vector4(-0.02 * _h, 0.0, 0.0, 2.0), Vector4(-0.012 * _h, radius * 0.55, radius * 0.55, 2.0), Vector4(0.0, radius, radius, 2.0), Vector4(0.016 * _h, radius * 0.97, radius * 0.97, 2.0), Vector4(0.018 * _h, 0.0, 0.0, 2.0)]
	var frame: Transform3D = V7InhabitantShapes.z_frame(center, SHIELD_YAW)
	_shapes.loft(frame, rows, 10 if _rig.is_near else 6, face, 0.0, V7InhabitantShapes.FULL_ARC, PackedVector2Array(), func(ring: int, _side: int) -> Color: return face if ring < 2 else (rim if ring == 2 else back))
	if not _rig.is_near:
		return
	var boss: Array[Vector4] = []
	for row: Vector4 in V7InhabitantShapes.dome(Vector3(0.034, 0.022, 0.034) * _h, 0.0, 90.0, 2):
		boss.append(Vector4(-(0.02 * _h + row.x), row.y, row.z, 2.0))
	_shapes.loft(frame, boss, 8, spec.trim)


## Bainha no cinto, do lado esquerdo: fita de couro com a ponta de aço e o punho com guarda.
func _scabbard() -> void:
	var y: float = SCABBARD.y * _h
	var hip: Vector3 = _rig.on_body(-_rig.half_width(y) * 0.9, y, 0.01)
	var tip: Vector3 = hip + Vector3(-0.04 * _h, -SCABBARD.x * _h * 1.2, 0.07 * _h)
	_shapes.limb(hip, tip, Vector2(0.024, 0.013) * _h, Vector2(0.014, 0.009) * _h, 5, STRAP, 2, 0.04, Vector3.RIGHT)
	_shapes.ball(tip, Vector3(0.016, 0.02, 0.012) * _h, 2, 5, STEEL, 0.03)
	var grip_top: Vector3 = hip + Vector3(0.01 * _h, 0.07 * _h, -0.012 * _h)
	_shapes.limb(hip, grip_top, Vector2(0.012, 0.012) * _h, Vector2(0.011, 0.011) * _h, 5, WOOD_DARK)
	_shapes.limb(hip + Vector3(-0.03 * _h, 0.004 * _h, -0.004 * _h), hip + Vector3(0.05 * _h, 0.004 * _h, -0.004 * _h), Vector2(0.008, 0.008) * _h, Vector2(0.008, 0.008) * _h, 4, STEEL, 1, 0.0, Vector3.UP)
	_shapes.ball(grip_top, Vector3(0.015, 0.015, 0.015) * _h, 2, 5, BRASS, 0.03)
