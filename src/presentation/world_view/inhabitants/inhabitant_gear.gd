class_name InhabitantGear
extends RefCounted
## Bolsas e cargas do habitante (ART-9d e 9e, protótipo isolado, só apresentação), orgânicas e nada de caixinha: cesta tecida (fundo, barriga e aro de ripas alternadas, alça grossa em arco, maçãs e um pano), saco de estopa (bojos, pescoço franzido e duas amarrações), bolsa de couro macia (aba curva com costura, fivela e alça de fita), bolsinha de moedas pendurada e trouxa nas costas amarrada com corda (a do mascate é enorme). Hastes, bengala, lampião, escudo e bainha ficam em InhabitantTools. LOD 1 leva só os de silhueta (menos facetas); LOD 2, os grandes.

const BAG_KINDS: Array[StringName] = [&"basket", &"sack", &"satchel", &"coin_pouch", &"bundle"]
const MID_KINDS: Array[StringName] = [&"basket", &"sack", &"satchel", &"bundle"]
const FAR_KINDS: Array[StringName] = [&"basket", &"sack", &"bundle"]
const WOOD_DARK: Color = Color("7A5230")
const BAG: Color = Color("8B5A33")
const BAG_FLAP: Color = Color("6E4426")
const STRAP: Color = Color("5A3A24")
const STITCH: Color = Color("D8C08A")
const WICKER: Color = Color("C09A55")
const BURLAP: Color = Color("B89B68")
const ROPE: Color = Color("8A6A3A")
const APPLE: Color = Color("C0452F")
const BRASS: Color = Color("D6B04A")
const COIN: Color = Color("E8B84A")
## Cesta (raio da base, do aro e altura, fração de H), alça, maçãs; saco (raios); bolsa (largura, altura, profundidade), lugar (altura, x sobre o raio) e giro; bolsinha; trouxa (raios, altura nas costas).
const BASKET: Vector3 = Vector3(0.085, 0.11, 0.11)
const HANDLE_RADIUS: float = 0.012
const HANDLE_SEGMENTS: int = 6
const SACK: Vector3 = Vector3(0.115, 0.125, 0.105)
const SATCHEL: Vector3 = Vector3(0.2, 0.15, 0.085)
const SATCHEL_SPOT: Vector2 = Vector2(0.32, 0.8)
const SATCHEL_YAW: float = 0.5
const STRAP_RADII: Vector2 = Vector2(0.03, 0.011)
const POUCH_RADIUS: float = 0.038
const POUCH_SPOT: Vector2 = Vector2(0.27, 0.66)
const BUNDLE: Vector3 = Vector3(0.1, 0.11, 0.09)
const BUNDLE_Y: float = 0.46
const BUNDLE_RISE: float = 0.07

var _rig: InhabitantRig
var _shapes: InhabitantShapes
var _h: float


func _init(rig: InhabitantRig) -> void:
	_rig = rig
	_shapes = rig.shapes
	_h = rig.h


func build() -> void:
	for kind: StringName in _rig.spec.accessories:
		if BAG_KINDS.has(kind) and (_rig.is_near or (_rig.lod == InhabitantRig.LOD_MID and MID_KINDS.has(kind)) or FAR_KINDS.has(kind)):
			_accessory(kind)


func _sides(near: int) -> int:
	return near if _rig.is_near else (maxi(near - 2, 4) if _rig.lod == InhabitantRig.LOD_MID else maxi(near - 4, 4))


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


## Cesta tecida: fundo, barriga, aro; facetas alternadas de palha clara e escura dão a trama; alça grossa de madeira em arco, maçãs e um pano dobrado.
func _basket() -> void:
	var size: Vector3 = BASKET * _h
	var center: Vector3 = _rig.carry()
	var half: float = size.z * 0.5
	var rows: Array[Vector4] = [Vector4(-half, 0.0, 0.0, 2.0), Vector4(-half, size.x, size.x, 2.2), Vector4(-half * 0.55, lerpf(size.x, size.y, 0.35), lerpf(size.x, size.y, 0.35), 2.2), Vector4(0.0, lerpf(size.x, size.y, 0.75), lerpf(size.x, size.y, 0.75), 2.2), Vector4(half - 0.012 * _h, size.y, size.y, 2.2), Vector4(half, size.y * 1.06, size.y * 1.06, 2.2), Vector4(half + 0.014 * _h, size.y * 1.06, size.y * 1.06, 2.2)]
	if not _rig.is_near:
		rows = [rows[0], rows[1], rows[5], Vector4(half, 0.0, 0.0, 2.0)]
	var dark: Color = WICKER.darkened(0.14)
	var is_near: bool = _rig.is_near
	_shapes.loft(InhabitantShapes.y_frame(center), rows, _sides(12), WICKER, 0.02, InhabitantShapes.FULL_ARC, PackedVector2Array(), func(ring: int, side: int) -> Color: return WOOD_DARK if ring >= 4 and is_near else (dark if (ring + side) % 2 == 0 else WICKER))
	if not _rig.is_near:
		return
	var top: Vector3 = center + Vector3(0.0, half + 0.007 * _h, 0.0)
	var previous: Vector3 = top + Vector3(-size.y, 0.0, 0.0)
	for index: int in range(1, HANDLE_SEGMENTS + 1):
		var angle: float = PI - PI * index / HANDLE_SEGMENTS
		var point: Vector3 = top + Vector3(cos(angle) * size.y, sin(angle) * size.y * 0.95, 0.0)
		_shapes.limb(previous, point, Vector2(HANDLE_RADIUS, HANDLE_RADIUS) * _h, Vector2(HANDLE_RADIUS, HANDLE_RADIUS) * _h, 4, WOOD_DARK, 1, 0.0, Vector3.FORWARD)
		previous = point
	for side: float in [0.4, 0.62]:
		_shapes.ball(top + Vector3(side * size.y, size.y * 0.1, (side - 0.5) * size.y * 0.4), Vector3(size.y, size.y, size.y) * 0.3, 2, 6, APPLE, 0.06)
	_shapes.ball(top + Vector3(-size.y * 0.35, size.y * 0.02, 0.0), Vector3(size.y * 0.58, size.y * 0.2, size.y * 0.8), 2, 7, _rig.spec.alt, 0.08)


## Saco de estopa: corpo cheio, quatro volumes na frente e o pescoço franzido amarrado com duas voltas de corda.
func _sack() -> void:
	var radii: Vector3 = SACK * _h
	var center: Vector3 = _rig.carry()
	_shapes.ball(center, radii, 4 if _rig.is_near else 3, _sides(8), BURLAP, 0.08)
	if not _rig.is_near:
		return
	var neck: Vector3 = center + Vector3(0.0, radii.y * 0.9, 0.0)
	_shapes.limb(neck, neck + Vector3(0.0, 0.07 * _h, 0.0), Vector2(0.06, 0.06) * _h, Vector2(0.03, 0.03) * _h, 6, BURLAP, 1, 0.2)
	for rise: float in [0.032, 0.05]:
		_shapes.limb(neck + Vector3(0.0, rise * _h, 0.0), neck + Vector3(0.0, (rise + 0.008) * _h, 0.0), Vector2(0.044, 0.044) * _h * (1.0 - (rise - 0.032) * 4.0), Vector2(0.044, 0.044) * _h * (1.0 - (rise - 0.032) * 4.0), 6, ROPE)
	_shapes.ball(neck + Vector3(0.0, 0.085 * _h, 0.0), Vector3(0.05, 0.036, 0.05) * _h, 2, 6, BURLAP, 0.1)
	for side: float in [-1.0, 1.0]:
		_shapes.ball(center + Vector3(side * radii.x * 0.5, -radii.y * 0.1, -radii.z * 0.78), Vector3(0.05, 0.055, 0.04) * _h, 2, 6, BURLAP.darkened(0.06), 0.1)
		_shapes.ball(center + Vector3(side * radii.x * 0.3, radii.y * 0.45, -radii.z * 0.7), Vector3(0.04, 0.04, 0.035) * _h, 2, 5, BURLAP.lightened(0.04), 0.1)


## Bolsa de couro macia: corpo arredondado, aba curva com costura, fivela e alça de fita em diagonal; de longe, só o corpo.
func _satchel() -> void:
	var y: float = SATCHEL_SPOT.x * _h
	var size: Vector3 = SATCHEL * _h * 0.5
	var spot: Vector3 = _rig.on_body(-_rig.half_width(y) * SATCHEL_SPOT.y, y, size.z * 0.9)
	var frame: Transform3D = InhabitantShapes.y_frame(spot, SATCHEL_YAW)
	var rows: Array[Vector4] = [Vector4(-size.y, 0.0, 0.0, 3.0), Vector4(-size.y, size.x * 0.86, size.z * 0.86, 3.4), Vector4(-size.y * 0.4, size.x * 0.98, size.z, 3.4), Vector4(size.y * 0.5, size.x, size.z, 3.4), Vector4(size.y, size.x * 0.92, size.z * 0.88, 3.4), Vector4(size.y, 0.0, 0.0, 3.0)]
	_shapes.loft(frame, rows, _sides(8), BAG, 0.015)
	if not _rig.is_near:
		return
	var flap: Array[Vector4] = [Vector4(size.y * 1.02, size.x * 1.0, size.z * 1.06, 3.4), Vector4(size.y * 0.55, size.x * 1.04, size.z * 1.12, 3.4), Vector4(size.y * 0.1, size.x * 0.92, size.z * 1.12, 3.4), Vector4(-size.y * 0.22, size.x * 0.55, size.z * 0.78, 3.4)]
	_shapes.loft(frame, flap, _sides(8), BAG_FLAP, 0.0, Vector2(InhabitantShapes.FRONT_ANGLE - 1.35, InhabitantShapes.FRONT_ANGLE + 1.35))
	var stitches: Array[Vector3] = []
	for index: int in 6:
		var section: Vector2 = InhabitantShapes.section(InhabitantShapes.FRONT_ANGLE - 1.15 + 2.3 * index / 5.0, size.x * 0.9, size.z * 1.13, 3.4)
		stitches.append(frame * Vector3(section.x, -size.y * 0.1, section.y))
	_shapes.ribbon(stitches, Vector3(0.0, 0.004 * _h, 0.0), STITCH, spot + Vector3(0.0, 0.0, 0.3))
	var clasp: Vector3 = frame * Vector3(0.0, -size.y * 0.16, -size.z * 1.14)
	var edge: Array[Vector3] = []
	for index: int in 6:
		edge.append(clasp + Vector3(cos(TAU * index / 6.0), sin(TAU * index / 6.0), 0.0) * size.x * 0.13)
	_shapes.fan(clasp + Vector3(0.0, 0.0, -0.004), edge, BRASS, clasp + Vector3(0.0, 0.0, 1.0))
	var shoulder_y: float = _rig.shoulder_y + 0.015 * _h
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


## Trouxa nas costas: embrulho cheio (o do mascate é enorme), duas voltas de corda, nó de pano no alto e a fita que passa pelo ombro.
func _bundle() -> void:
	var grow: float = _rig.spec.bundle_size
	var y: float = (BUNDLE_Y + BUNDLE_RISE * (grow - 1.0)) * _h
	var radii: Vector3 = BUNDLE * _h * grow
	var back: float = _rig.shift_at(y).y + _rig.row_at(y).z + radii.z * 0.7
	var center: Vector3 = Vector3(0.0, y, back)
	var cloth: Color = _rig.spec.alt.darkened(0.1)
	_shapes.ball(center, radii, 3 if _rig.is_near else 2, _sides(8), cloth, 0.07)
	if not _rig.is_near:
		return
	for offset: float in [-0.45, 0.35]:
		var spread: float = sqrt(1.0 - offset * offset) * 1.04
		var rows: Array[Vector4] = [Vector4(-0.014 * _h, radii.x * spread, radii.z * spread, 2.2), Vector4(0.014 * _h, radii.x * spread, radii.z * spread, 2.2)]
		_shapes.loft(InhabitantShapes.y_frame(center + Vector3(0.0, offset * radii.y, 0.0)), rows, 10, ROPE)
	_shapes.limb(center + Vector3(0.0, radii.y * 0.8, 0.0), center + Vector3(0.0, radii.y * 1.5, 0.0), Vector2(0.05, 0.05) * _h * grow, Vector2(0.02, 0.02) * _h * grow, 5, cloth, 1, 0.3)
	_shapes.ball(center + Vector3(0.0, radii.y * 1.55, 0.0), Vector3(0.04, 0.03, 0.04) * _h * grow, 2, 5, cloth, 0.1)
	var shoulder: float = _rig.shoulder_y
	for side: float in [-1.0, 1.0]:
		var points: Array[Vector3] = [Vector3(side * radii.x * 0.7, y + radii.y * 0.4, back - radii.z * 0.6), Vector3(side * _rig.half_width(shoulder) * 0.62, shoulder, _rig.shift_at(shoulder).y + _rig.row_at(shoulder).z * 0.5), _rig.on_body(side * _rig.half_width(0.5 * _h) * 0.55, 0.5 * _h, 0.01)]
		_shapes.ribbon(points, Vector3(0.016 * _h, 0.0, 0.0), STRAP, center)
