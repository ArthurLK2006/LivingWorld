class_name InhabitantTools
extends RefCounted
## Hastes e equipamento de mão (ART-9e, protótipo isolado, só apresentação): cajado, bengala de cabo curvo, lança de lâmina em folha com flâmula, cajado de guarda (com a alabarda do vigia: lâmina de machado, ponta e espigão), lampião de armação com alça, escudo redondo com listra e desgaste e a bainha no cinto. LOD 1 leva só o de silhueta (menos facetas); LOD 2, as hastes grandes.

const MID_KINDS: Array[StringName] = [&"staff", &"spear", &"guard_staff", &"cane"]
const FAR_KINDS: Array[StringName] = [&"staff", &"spear", &"guard_staff"]
const WOOD: Color = Color("B07A45")
const WOOD_DARK: Color = Color("7A5230")
const STRAP: Color = Color("5A3A24")
const STEEL: Color = Color("A9B2BC")
const DARK_METAL: Color = Color("3A3A40")
const GLASS: Color = Color("FFC24D")
const BRASS: Color = Color("D6B04A")
const PLUME_RED: Color = Color("B83A32")
const LANTERN_SIZE: float = 0.055
const LANTERN_DROP: float = 0.1
## Hastes (altura do topo, raio, ponta: fração de H); lâmina (meia largura, afinamento) e flâmula (comprimento, altura, sobra para trás); escudo (raio, lugar da mão, giro) e bainha.
const POLES: Dictionary[StringName, Vector3] = {&"staff": Vector3(1.02, 0.02, 0.0), &"spear": Vector3(0.92, 0.014, 0.13), &"guard_staff": Vector3(0.95, 0.022, 0.07), &"cane": Vector3(0.46, 0.016, 0.0)}
const BLADE_HALF: float = 0.04
const BLADE_THIN: float = 0.22
const PENNANT: Vector3 = Vector3(0.17, 0.06, 0.045)
const SHIELD_RADIUS: float = 0.095
const SHIELD_SPOT: Vector3 = Vector3(-0.03, 0.06, -0.07)
const SHIELD_YAW: float = 0.45
const SCABBARD: Vector3 = Vector3(0.1, 0.33, 0.12)
## Cabo da bengala: pontos do arco (x, y em fração de H) depois do topo da haste.
const CROOK: Array[Vector2] = [Vector2(0.0, 0.022), Vector2(-0.02, 0.044), Vector2(-0.046, 0.04), Vector2(-0.056, 0.018)]

var _rig: InhabitantRig
var _shapes: InhabitantShapes
var _h: float


func _init(rig: InhabitantRig) -> void:
	_rig = rig
	_shapes = rig.shapes
	_h = rig.h


func build() -> void:
	for kind: StringName in _rig.spec.accessories:
		if POLES.has(kind):
			if _rig.is_near or (_rig.lod == InhabitantRig.LOD_MID and MID_KINDS.has(kind)) or FAR_KINDS.has(kind):
				_pole(kind)
		elif kind == &"lantern" and _rig.is_near:
			_lantern()
	if _rig.spec.has_shield and _rig.lod != InhabitantRig.LOD_FAR:
		_shield()
	if _rig.spec.role == InhabitantSpec.GUARD and _rig.is_near:
		_scabbard()


func _sides(near: int) -> int:
	return near if _rig.is_near else (maxi(near - 2, 4) if _rig.lod == InhabitantRig.LOD_MID else maxi(near - 4, 4))


## Lampião de armação: vidro aceso, quatro varetas, tampa e alça até a mão.
func _lantern() -> void:
	var size: float = LANTERN_SIZE * _h
	var body: Vector3 = _rig.hands[0] + Vector3.DOWN * LANTERN_DROP * _h
	var glass: Array[Vector4] = [Vector4(-size * 0.65, 0.0, 0.0, 2.0), Vector4(-size * 0.65, size * 0.55, size * 0.55, 2.2), Vector4(0.0, size * 0.8, size * 0.8, 2.2), Vector4(size * 0.65, size * 0.55, size * 0.55, 2.2), Vector4(size * 0.65, 0.0, 0.0, 2.0)]
	_shapes.loft(InhabitantShapes.y_frame(body), glass, 6, GLASS, 0.03)
	var cap: Array[Vector4] = [Vector4(size * 0.65, size * 0.85, size * 0.85, 2.2), Vector4(size * 1.05, 0.0, 0.0, 2.2)]
	_shapes.loft(InhabitantShapes.y_frame(body), cap, 6, DARK_METAL)
	for index: int in 4:
		var angle: float = TAU * (index + 0.5) / 4.0
		var spot: Vector3 = Vector3(cos(angle), 0.0, sin(angle)) * size * 0.74
		_shapes.limb(body + spot + Vector3(0.0, -size * 0.65, 0.0), body + spot * 0.7 + Vector3(0.0, size * 0.65, 0.0), Vector2(0.006, 0.006) * _h, Vector2(0.006, 0.006) * _h, 4, DARK_METAL)
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
			if _rig.spec.halberd:
				_halberd(top)
			else:
				_shapes.ball(top + Vector3(0.0, 0.025 * _h, 0.0), Vector3(0.03, 0.04, 0.03) * _h, 2, _sides(6), STEEL, 0.03)
				_shapes.limb(top - Vector3(0.0, 0.01 * _h, 0.0), top + Vector3(0.0, 0.006 * _h, 0.0), Vector2(0.034, 0.034) * _h, Vector2(0.034, 0.034) * _h, _sides(6), DARK_METAL)
		&"cane":
			_crook(top, radius)
		_:
			if _rig.is_near:
				_shapes.ball(top, Vector3(0.03, 0.035, 0.03) * _h, 2, 6, WOOD, 0.1)


## Cabo curvo da bengala: um arco de pedaços que sobe do topo e cai para dentro, mais grosso que a haste.
func _crook(top: Vector3, radius: float) -> void:
	var previous: Vector3 = top
	for spot: Vector2 in CROOK:
		var next: Vector3 = top + Vector3(spot.x, spot.y, 0.0) * _h
		_shapes.limb(previous, next, Vector2(radius * 1.2, radius * 1.2), Vector2(radius * 1.1, radius * 1.1), 5 if _rig.is_near else 4, WOOD, 1)
		previous = next


## Alabarda do vigia: espigão no alto, lâmina de machado para fora, gancho atrás e soquete de ferro.
func _halberd(top: Vector3) -> void:
	var near: bool = _rig.is_near
	_shapes.ball(top + Vector3(0.05 * _h, -0.02 * _h, 0.0), Vector3(0.06, 0.05, 0.009) * _h, 2, 6 if near else 4, STEEL, 0.02)
	if _rig.lod == InhabitantRig.LOD_FAR:
		return
	_shapes.limb(top - Vector3(0.0, 0.06 * _h, 0.0), top + Vector3(0.0, 0.01 * _h, 0.0), Vector2(0.024, 0.024) * _h, Vector2(0.02, 0.02) * _h, _sides(6), DARK_METAL)
	_shapes.limb(top, top + Vector3(0.0, 0.11 * _h, 0.0), Vector2(0.016, 0.01) * _h, Vector2(0.002, 0.002) * _h, 4, STEEL)
	if near:
		_shapes.limb(top + Vector3(0.0, -0.035 * _h, 0.0), top + Vector3(-0.055 * _h, -0.025 * _h, 0.0), Vector2(0.011, 0.008) * _h, Vector2(0.002, 0.002) * _h, 4, STEEL)


## Lâmina em folha (lente achatada, mais larga acima do meio), soquete e flâmula de duas faces.
func _blade(base: Vector3, length: float) -> void:
	var half: float = BLADE_HALF * _h
	var rows: Array[Vector4] = []
	var stops: Array[Vector2] = [Vector2(0.0, 0.3), Vector2(0.45, 1.0), Vector2(1.0, 0.0)]
	if _rig.lod != InhabitantRig.LOD_FAR:
		stops = [Vector2(0.0, 0.3), Vector2(0.2, 0.9), Vector2(0.45, 1.0), Vector2(0.8, 0.5), Vector2(1.0, 0.0)]
	for stop: Vector2 in stops:
		rows.append(Vector4(stop.x * length, stop.y * half, stop.y * half * BLADE_THIN, 2.0))
	_shapes.loft(InhabitantShapes.y_frame(base), rows, 6 if _rig.is_near else 4, STEEL)
	if _rig.lod == InhabitantRig.LOD_FAR:
		return
	var upper: Vector3 = base + Vector3(0.0, -0.012 * _h, 0.0)
	var lower: Vector3 = base + Vector3(0.0, -PENNANT.y * _h, 0.0)
	var tip: Vector3 = base + Vector3(PENNANT.x * _h, -PENNANT.y * 0.55 * _h, PENNANT.z * _h)
	var wave: Array[Vector3] = [upper, upper.lerp(tip, 0.5) + Vector3(0.0, 0.014 * _h, 0.012 * _h), tip, lower.lerp(tip, 0.5) + Vector3(0.0, -0.01 * _h, 0.02 * _h), lower]
	_shapes.sheet(wave, PLUME_RED)
	if _rig.is_near:
		_shapes.limb(base + Vector3(0.0, -0.025 * _h, 0.0), base + Vector3(0.0, 0.004 * _h, 0.0), Vector2(0.02, 0.02) * _h, Vector2(0.016, 0.016) * _h, 6, DARK_METAL)


## Escudo redondo no braço esquerdo: disco de cara do tabardo com a listra de ouro, desgaste em facetas mais escuras, borda de aço, costas de couro e o botão de metal no centro.
func _shield() -> void:
	var radius: float = SHIELD_RADIUS * _h
	var center: Vector3 = _rig.hands[0] + SHIELD_SPOT * _h
	var spec: InhabitantSpec = _rig.spec
	var face: Color = spec.top
	var worn: Color = face.darkened(0.22)
	var rim: Color = STEEL
	var back: Color = STRAP
	var rows: Array[Vector4] = [Vector4(-0.02 * _h, 0.0, 0.0, 2.0), Vector4(-0.012 * _h, radius * 0.55, radius * 0.55, 2.0), Vector4(0.0, radius, radius, 2.0), Vector4(0.016 * _h, radius * 0.97, radius * 0.97, 2.0), Vector4(0.018 * _h, 0.0, 0.0, 2.0)]
	var frame: Transform3D = InhabitantShapes.z_frame(center, SHIELD_YAW)
	var is_near: bool = _rig.is_near
	var gold: Color = spec.trim
	var tint: Callable = func(ring: int, side: int) -> Color:
		if ring >= 3:
			return back
		if ring == 2:
			return rim
		if is_near and side % 5 == 0:
			return gold
		return worn if is_near and (ring * 3 + side * 2) % 7 == 0 else face
	_shapes.loft(frame, rows, 10 if is_near else 6, face, 0.0, InhabitantShapes.FULL_ARC, PackedVector2Array(), tint)
	if not is_near:
		return
	var boss: Array[Vector4] = []
	for row: Vector4 in InhabitantShapes.dome(Vector3(0.034, 0.022, 0.034) * _h, 0.0, 90.0, 2):
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
