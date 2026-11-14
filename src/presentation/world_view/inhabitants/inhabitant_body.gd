class_name InhabitantBody
extends RefCounted
## Corpo do habitante (ART-9d e 9e, protótipo isolado, só apresentação): botas grossas com sola, pernas (a grossura vem da ficha), o tronco loftado pelo perfil ANATÔMICO da ficha (InhabitantRig: barriga, ombros, quadril, postura), braços de dois segmentos com ombro redondo, cotovelo levemente dobrado e mangas (longa, curta, dobrada e bufante, com o antebraço de pele macia nas curtas) e as mãos (InhabitantHands, de luva no guarda). LOD 0 leva tudo; LOD 1, membros simples; LOD 2, só o tronco e um bloco de botas.

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
## Braço: onde ele fica sobre a largura do tronco, bola do ombro e raios (ombro, cotovelo, pulso) em fração de H (vezes a grossura da ficha), cotovelo dobrado para fora e para trás, recuo do pulso até a mão e punho dobrado (antes e depois do pulso, e quanto cresce).
const SHOULDER_IN: float = 0.88
const SHOULDER_BALL: float = 0.068
const ARM_RADII: Array[float] = [0.06, 0.05, 0.041]
const ARM_DEPTH: float = 0.94
const ARM_SIDES: int = 6
const ELBOW_OUT: float = 0.035
const ELBOW_BACK: float = 0.012
const WRIST_BACK: float = 0.034
const CUFF_SPAN: Vector2 = Vector2(0.012, 0.018)
const CUFF_GROW: float = 1.12
const FAR_ARM: Array[Vector2] = [Vector2(0.065, 0.06), Vector2(0.05, 0.048)]
## Mangas: onde a curta acaba no braço (fração do ombro ao cotovelo), a dobra e o balão da bufante (crescimento do raio e posição no braço).
const SHORT_CUT: float = 0.6
const ROLL_GROW: float = 1.16
const PUFF: Vector2 = Vector2(1.5, 0.45)
const GLOVE: Color = Color("4A382C")

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
	var spec: InhabitantSpec = _rig.spec
	var thick: float = lerpf(1.0, spec.legs, 0.7)
	var foot_x: float = minf(FOOT_X * h * lerpf(1.0, spec.legs, 0.5), _rig.r * FOOT_IN_R)
	if _rig.lod == InhabitantRig.LOD_FAR:
		var box: Vector3 = FAR_BOOTS * h * thick
		_shapes.box(Vector3(0.0, box.y, 0.0), Vector3(foot_x * 2.0 + box.x, box.y * 2.0, box.z), spec.boots)
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
		rows.append(Vector4(row.x * h * (shaft if index >= 3 else 1.0), row.y * h * thick, row.z * h * thick, 2.2))
		shifts.append(Vector2(0.0, BOOT_FORWARD[index] * h))
	var top: float = rows[-1].x
	for side: float in [-1.0, 1.0]:
		_shapes.loft(InhabitantShapes.y_frame(Vector3(side * foot_x, 0.0, 0.0)), rows, BOOT_SIDES[_rig.lod], boots, TORSO_JITTER, InhabitantShapes.FULL_ARC, shifts, tint)
		if _rig.hem_y() > top:
			var from: Vector3 = Vector3(side * foot_x, top - 0.01 * h, 0.0)
			_shapes.limb(from, Vector3(side * foot_x * 1.04, _rig.hem_y() + LEG_OVERLAP * h, 0.0), Vector2(LEG_RADII.x, LEG_RADII.x) * h * spec.legs, Vector2(LEG_RADII.y, LEG_RADII.y * 0.95) * h * spec.legs, LEG_SIDES if _rig.is_near else 4, spec.bottom, 1)


func _torso() -> void:
	var spec: InhabitantSpec = _rig.spec
	var rows: Array[Vector4] = []
	rows.append_array(_rig.rows)
	var shifts: PackedVector2Array = _rig.shifts.duplicate()
	rows.append(Vector4(rows[-1].x + NECK_RISE * _rig.h, 0.0, 0.0, rows[-1].w))
	shifts.append(shifts[-1])
	var base: Color = _rig.body_color()
	var hem: Color = spec.trim if spec.garment != InhabitantSpec.Garment.TABARD else base.darkened(0.15)
	var stripe: Color = base.lerp(spec.alt, 0.32)
	var is_striped: bool = spec.fabric == InhabitantSpec.Fabric.STRIPED and spec.garment != InhabitantSpec.Garment.TABARD
	var tint: Callable = Callable()
	if _rig.is_near:
		tint = func(ring: int, _side: int) -> Color:
			if ring == 0:
				return hem
			return stripe if is_striped and ring % 2 == 0 else base
	_shapes.loft(InhabitantShapes.y_frame(Vector3.ZERO), rows, _rig.sides, base, TORSO_JITTER, InhabitantShapes.FULL_ARC, shifts, tint)


## Ombros redondos, braços de dois segmentos com a manga da ficha e a mão; de longe, um braço simples com a palma.
func _arms() -> void:
	if _rig.lod == InhabitantRig.LOD_FAR:
		return
	var spec: InhabitantSpec = _rig.spec
	var h: float = _rig.h
	var y: float = _rig.shoulder_y
	for index: int in 2:
		var side: float = 2.0 * index - 1.0
		var shift: Vector2 = _rig.shift_at(y)
		var shoulder: Vector3 = Vector3(side * _rig.half_width(y) * SHOULDER_IN + shift.x, y, shift.y)
		var hand: Vector3 = _rig.hands[index]
		if not _rig.is_near:
			_shapes.limb(shoulder, hand, FAR_ARM[0] * h * spec.limbs, FAR_ARM[1] * h * spec.limbs, 4, _rig.body_color(), 1)
			_shapes.ball(hand, InhabitantHands.PALM * h, 2, 4, spec.skin)
			continue
		_near_arm(shoulder, hand, side)


func _near_arm(shoulder: Vector3, hand: Vector3, side: float) -> void:
	var spec: InhabitantSpec = _rig.spec
	var h: float = _rig.h
	var sleeve: Color = _rig.body_color()
	var elbow: Vector3 = shoulder.lerp(hand, 0.5) + Vector3(side * ELBOW_OUT * h, 0.0, ELBOW_BACK * h)
	var forward: Vector3 = (hand - elbow).normalized()
	var wrist: Vector3 = hand - forward * WRIST_BACK * h
	var radii: Array[Vector2] = []
	for radius: float in ARM_RADII:
		radii.append(Vector2(radius, radius * ARM_DEPTH) * h * spec.limbs)
	var ball: float = SHOULDER_BALL * h * lerpf(1.0, spec.limbs, 0.6)
	_shapes.ball(shoulder, Vector3(ball, ball * 0.95, ball), 2, ARM_SIDES, sleeve)
	var is_short: bool = spec.sleeve == InhabitantSpec.Sleeve.SHORT
	var is_bare: bool = is_short or spec.sleeve == InhabitantSpec.Sleeve.ROLLED
	var cut: Vector3 = shoulder.lerp(elbow, SHORT_CUT) if is_short else elbow
	var cut_radii: Vector2 = radii[0].lerp(radii[1], SHORT_CUT) if is_short else radii[1]
	_shapes.limb(shoulder, cut, radii[0], cut_radii, ARM_SIDES, sleeve, 2, 0.06)
	if spec.sleeve == InhabitantSpec.Sleeve.PUFFED:
		var puff: Vector2 = radii[0] * PUFF.x
		_shapes.ball(shoulder.lerp(elbow, PUFF.y), Vector3(puff.x, puff.x * 1.1, puff.x), 3, ARM_SIDES + 2, sleeve, 0.04)
	if not is_bare:
		_shapes.ball(elbow, Vector3(radii[1].x, radii[1].x, radii[1].x) * 1.02, 2, ARM_SIDES, sleeve)
		_shapes.limb(elbow, wrist, radii[1], radii[2], ARM_SIDES, sleeve, 2, 0.05)
		_shapes.limb(wrist - forward * CUFF_SPAN.x * h, wrist + forward * CUFF_SPAN.y * h, radii[2] * CUFF_GROW, radii[2] * CUFF_GROW, ARM_SIDES, spec.trim)
	else:
		var along: Vector3 = (elbow - shoulder).normalized() * CUFF_SPAN.y * h
		_shapes.limb(cut - along, cut + along * 0.5, cut_radii * ROLL_GROW, cut_radii * ROLL_GROW, ARM_SIDES, sleeve.darkened(0.1))
		_shapes.soft = true
		if is_short:
			_shapes.limb(cut, elbow, cut_radii, radii[1], ARM_SIDES, spec.skin, 1, 0.04)
		_shapes.ball(elbow, Vector3(radii[1].x, radii[1].x, radii[1].x) * 1.02, 2, ARM_SIDES, spec.skin)
		_shapes.limb(elbow, wrist, radii[1], radii[2], ARM_SIDES, spec.skin, 2, 0.05)
		_shapes.soft = false
	var is_gloved: bool = spec.role == InhabitantSpec.GUARD
	InhabitantHands.build(_shapes, h, hand, -side, GLOVE if is_gloved else spec.skin, not is_gloved)
