class_name InhabitantBody
extends RefCounted
## Corpo do habitante (ART-9d, protótipo isolado, só apresentação): botas grossas com sola, pernas, o tronco loftado pelo perfil do papel (sem tronco de cone nem cilindro), braços de dois segmentos com ombro redondo, cotovelo levemente dobrado e punho, e mãos de luva com polegar e três dedos arredondados. LOD 0 leva tudo; LOD 1, membros simples; LOD 2, só o tronco e um bloco de botas.

const TORSO_JITTER: float = 0.025
const NECK_RISE: float = 0.012
## Botas (altura, rx e rz em fração de H) e quanto cada anel avança para a frente (fração de H); a primeira faixa é a sola, mais escura. O cano do guarda é mais alto. Anéis usados por LOD e setores por LOD.
const BOOT_ROWS: Array[Vector3] = [Vector3(0.0, 0.04, 0.066), Vector3(0.012, 0.047, 0.076), Vector3(0.034, 0.046, 0.072), Vector3(0.06, 0.04, 0.054), Vector3(0.088, 0.037, 0.046)]
const BOOT_FORWARD: Array[float] = [-0.016, -0.018, -0.014, -0.006, 0.0]
const BOOT_KEEP: Array[Array] = [[0, 1, 2, 3, 4], [0, 2, 4], [0, 2, 4]]
const BOOT_SIDES: Array[int] = [8, 5, 5]
const SHAFT_GUARD: float = 1.7
const SOLE_DARKEN: float = 0.5
const FOOT_X: float = 0.1
const FOOT_IN_R: float = 0.52
const LEG_RADII: Vector2 = Vector2(0.04, 0.052)
const LEG_SIDES: int = 6
const LEG_OVERLAP: float = 0.025
const FAR_BOOTS: Vector3 = Vector3(0.1, 0.05, 0.075)
## Braço: altura do ombro por papel (o aldeão tem o ombro mais caído), onde ele fica sobre a largura do tronco, bola do ombro e raios (ombro, cotovelo, pulso) em fração de H, cotovelo dobrado para fora e para trás, recuo do pulso até a mão e punho dobrado (antes e depois do pulso, e quanto cresce).
const SHOULDER_Y: Dictionary[StringName, float] = {InhabitantSpec.VILLAGER: 0.56, InhabitantSpec.MERCHANT: 0.565, InhabitantSpec.GUARD: 0.585}
const SHOULDER_IN: float = 0.88
const SHOULDER_BALL: float = 0.068
const ARM_RADII: Array[float] = [0.064, 0.054, 0.044]
const ARM_DEPTH: float = 0.94
const ARM_SIDES: int = 6
const ELBOW_OUT: float = 0.035
const ELBOW_BACK: float = 0.012
const WRIST_BACK: float = 0.034
const CUFF_SPAN: Vector2 = Vector2(0.012, 0.018)
const CUFF_GROW: float = 1.12
## Mão de luva: palma, polegar (raios e lugar sobre a palma, x para dentro) e três dedos (raios e lugar do dedo do meio; o espaçamento vai em x), tudo em fração de H.
const PALM: Vector3 = Vector3(0.05, 0.054, 0.042)
const THUMB: Vector3 = Vector3(0.022, 0.03, 0.022)
const THUMB_SPOT: Vector3 = Vector3(0.036, 0.012, -0.026)
const FINGER: Vector3 = Vector3(0.016, 0.03, 0.017)
const FINGER_SPOT: Vector3 = Vector3(0.021, -0.05, -0.008)
const FAR_ARM: Array[Vector2] = [Vector2(0.065, 0.06), Vector2(0.05, 0.048)]

var _rig: InhabitantRig
var _shapes: InhabitantShapes


func _init(rig: InhabitantRig) -> void:
	_rig = rig
	_shapes = rig.shapes


func build() -> void:
	_legs()
	_torso()
	_arms()


func _legs() -> void:
	var h: float = _rig.h
	var foot_x: float = minf(FOOT_X * h, _rig.r * FOOT_IN_R)
	var spec: InhabitantSpec = _rig.spec
	if _rig.lod == InhabitantRig.LOD_FAR:
		var box: Vector3 = FAR_BOOTS * h
		_shapes.kit.box(Vector3(0.0, box.y, 0.0), Vector3(foot_x * 2.0 + box.x, box.y * 2.0, box.z), spec.boots)
		return
	var shaft: float = SHAFT_GUARD if spec.role == InhabitantSpec.GUARD else 1.0
	var sole: Color = spec.boots.darkened(SOLE_DARKEN)
	var boots: Color = spec.boots
	var tint: Callable = func(ring: int, _side: int) -> Color:
		return sole if ring == 0 and _rig.is_near else boots
	var rows: Array[Vector4] = []
	var shifts: PackedVector2Array = PackedVector2Array()
	for index: int in BOOT_KEEP[_rig.lod]:
		var row: Vector3 = BOOT_ROWS[index]
		rows.append(Vector4(row.x * h * (shaft if index >= 3 else 1.0), row.y * h, row.z * h, 2.2))
		shifts.append(Vector2(0.0, BOOT_FORWARD[index] * h))
	var top: float = rows[-1].x
	for side: float in [-1.0, 1.0]:
		_shapes.loft(InhabitantShapes.y_frame(Vector3(side * foot_x, 0.0, 0.0)), rows, BOOT_SIDES[_rig.lod], boots, TORSO_JITTER, InhabitantShapes.FULL_ARC, shifts, tint)
		if _rig.hem_y() > top:
			var from: Vector3 = Vector3(side * foot_x, top - 0.01 * h, 0.0)
			_shapes.limb(from, Vector3(side * foot_x * 1.04, _rig.hem_y() + LEG_OVERLAP * h, 0.0), Vector2(LEG_RADII.x, LEG_RADII.x) * h, Vector2(LEG_RADII.y, LEG_RADII.y * 0.95) * h, LEG_SIDES if _rig.is_near else 4, spec.bottom, 1)


func _torso() -> void:
	var spec: InhabitantSpec = _rig.spec
	var rows: Array[Vector4] = []
	rows.append_array(_rig.rows)
	var shifts: PackedVector2Array = _rig.shifts.duplicate()
	rows.append(Vector4(rows[-1].x + NECK_RISE * _rig.h, 0.0, 0.0, rows[-1].w))
	shifts.append(shifts[-1])
	var base: Color = _rig.body_color()
	var hem: Color = spec.trim if spec.garment != InhabitantSpec.Garment.TABARD else base.darkened(0.15)
	var stripe: Color = base.lerp(spec.alt, 0.45)
	var is_striped: bool = spec.fabric == InhabitantSpec.Fabric.STRIPED and spec.garment != InhabitantSpec.Garment.TABARD
	var tint: Callable = Callable()
	if _rig.is_near:
		tint = func(ring: int, _side: int) -> Color:
			if ring == 0:
				return hem
			return stripe if is_striped and ring % 2 == 0 else base
	_shapes.loft(InhabitantShapes.y_frame(Vector3.ZERO), rows, _rig.sides, base, TORSO_JITTER, InhabitantShapes.FULL_ARC, shifts, tint)


## Ombros redondos, braços de dois segmentos (cotovelo para fora e para trás) com punho dobrado e a mão de luva; de longe, um braço simples com a palma.
func _arms() -> void:
	if _rig.lod == InhabitantRig.LOD_FAR:
		return
	var h: float = _rig.h
	var y: float = SHOULDER_Y[_rig.spec.role] * h
	var sleeve: Color = _rig.body_color()
	for index: int in 2:
		var side: float = 2.0 * index - 1.0
		var shift: Vector2 = _rig.shift_at(y)
		var shoulder: Vector3 = Vector3(side * _rig.half_width(y) * SHOULDER_IN + shift.x, y, shift.y)
		var hand: Vector3 = _rig.hands[index]
		if not _rig.is_near:
			_shapes.limb(shoulder, hand, FAR_ARM[0] * h, FAR_ARM[1] * h, 4, sleeve, 1)
			_shapes.ball(hand, PALM * h, 2, 4, _rig.spec.skin)
			continue
		var elbow: Vector3 = shoulder.lerp(hand, 0.5) + Vector3(side * ELBOW_OUT * h, 0.0, ELBOW_BACK * h)
		var forward: Vector3 = (hand - elbow).normalized()
		var wrist: Vector3 = hand - forward * WRIST_BACK * h
		var radii: Array[Vector2] = []
		for radius: float in ARM_RADII:
			radii.append(Vector2(radius, radius * ARM_DEPTH) * h)
		_shapes.ball(shoulder, Vector3(SHOULDER_BALL, SHOULDER_BALL * 0.95, SHOULDER_BALL) * h, 2, ARM_SIDES, sleeve)
		_shapes.limb(shoulder, elbow, radii[0], radii[1], ARM_SIDES, sleeve, 2, 0.06)
		_shapes.ball(elbow, Vector3(radii[1].x, radii[1].x, radii[1].x) * 1.02, 2, ARM_SIDES, sleeve)
		_shapes.limb(elbow, wrist, radii[1], radii[2], ARM_SIDES, sleeve, 2, 0.05)
		_shapes.limb(wrist - forward * CUFF_SPAN.x * h, wrist + forward * CUFF_SPAN.y * h, radii[2] * CUFF_GROW, radii[2] * CUFF_GROW, ARM_SIDES, _rig.spec.trim)
		_hand(hand, -side)


## Mão de luva: palma, polegar do lado de dentro e três dedos arredondados caídos.
func _hand(center: Vector3, inward: float) -> void:
	var h: float = _rig.h
	var skin: Color = _rig.spec.skin
	_shapes.ball(center, PALM * h, 3, 7, skin, 0.03)
	_shapes.ball(center + Vector3(inward * THUMB_SPOT.x, THUMB_SPOT.y, THUMB_SPOT.z) * h, THUMB * h, 2, 5, skin, 0.03)
	for finger: int in 3:
		_shapes.ball(center + Vector3((finger - 1) * FINGER_SPOT.x, FINGER_SPOT.y, FINGER_SPOT.z) * h, FINGER * h, 2, 5, skin, 0.03)
