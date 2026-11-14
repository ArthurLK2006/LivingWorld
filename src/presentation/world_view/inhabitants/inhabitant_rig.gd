class_name InhabitantRig
extends RefCounted
## As medidas de UM habitante (ART-9d e 9e, protótipo isolado, só apresentação): o perfil do tronco e a cabeça vêm da MORFOLOGIA da ficha (InhabitantMorph: altura, constituição, ombros, barriga, quadril, pescoço, forma da cabeça, postura e idade), mais os pontos de mão e as perguntas à superfície (`on_body`, `face_point`, `shell`) que o corpo, a roupa, a cabeça e os acessórios usam para se pregar no tronco e no rosto. Pés em y = 0, origem entre os pés, frente para -Z (+X é a direita dele). Proporções [HIP] em fração da altura H, a calibrar olhando as capturas.

const LOD_NEAR: int = 0
const LOD_MID: int = 1
const LOD_FAR: int = 2
const SIDES: Array[int] = [12, 8, 6]
const SEED_STRIDE: int = 1013
## Anéis do tronco (barra, quadril, cintura, peito, axila, ombro, pescoço) e da cabeça (10, de polo a polo) que cada LOD usa.
const TORSO_KEEP: Array[Array] = [[0, 1, 2, 3, 4, 5, 6], [0, 1, 2, 3, 5, 6], [0, 2, 4, 6]]
const HEAD_KEEP: Array[Array] = [[0, 1, 2, 3, 4, 5, 6, 7, 8, 9], [0, 3, 5, 7, 9], [0, 5, 9]]
## Cabeça: proporção em x e z, teto da metade da altura (fração de H), abaixamento do centro e quanto a curvatura leva a cabeça para a frente e para baixo (fração de H).
const HEAD_ASPECT: Vector2 = Vector2(0.98, 0.95)
const MAX_HEAD_HALF: float = 0.178
const HEAD_DROP: float = 0.06
const STOOP_HEAD_FORWARD: float = 0.1
const STOOP_HEAD_DROP: float = 0.03
const STOOP_HAND_FORWARD: float = 0.04
## Mãos: altura delas caídas, folga para fora do tronco, carga à frente (altura, saída, subida da checagem da barriga, meia largura entre as mãos), hastes que a mão direita segura e subida e avanço da mão na haste, na bengala e no lampião.
const HAND_HEIGHT: float = 0.37
const HAND_OUT: float = 0.05
const POLE_OUT: float = 0.03
const CARRY_Y: float = 0.33
const CARRY_OUT: float = 0.04
const CARRY_LIFT: float = 0.1
const CARRY_REACH: float = 0.115
const POLE_KINDS: Array[StringName] = [&"staff", &"spear", &"guard_staff", &"cane"]
const POLE_RAISE: float = 0.04
const CANE_RAISE: float = 0.075
const POLE_FORWARD: float = 0.02
const LANTERN_FORWARD: float = 0.1

var spec: InhabitantSpec
var lod: int
var is_near: bool
var sides: int
var h: float
var r: float
var shoulder_y: float
var shapes: InhabitantShapes
var rows: Array[Vector4] = []
var shifts: PackedVector2Array = PackedVector2Array()
var head_c: Vector3
var head_r: Vector3
var head_rows: Array[Vector4] = []
var hands: Array[Vector3] = []


func _init(inhabitant: InhabitantSpec, level: int) -> void:
	spec = inhabitant
	lod = clampi(level, LOD_NEAR, LOD_FAR)
	is_near = lod == LOD_NEAR
	sides = SIDES[lod]
	h = spec.height_m
	shapes = InhabitantShapes.new(spec.id * SEED_STRIDE)
	var torso: Dictionary = InhabitantMorph.torso(spec)
	var all_rows: Array[Vector4] = torso["rows"]
	var all_shifts: PackedVector2Array = torso["shifts"]
	r = all_rows[1].y
	for index: int in TORSO_KEEP[lod]:
		rows.append(all_rows[index])
		shifts.append(all_shifts[index])
	shoulder_y = InhabitantMorph.shoulder_y(spec) * h
	var shape: Vector3 = InhabitantMorph.shape_scale(spec.head_shape)
	var half: float = minf(InhabitantMorph.HEAD_FRACTION[spec.age] * h * spec.head_scale, MAX_HEAD_HALF * h)
	head_r = Vector3(HEAD_ASPECT.x * shape.x, shape.y, HEAD_ASPECT.y * shape.z) * half
	head_r.y = minf(head_r.y, MAX_HEAD_HALF * h)
	head_c = Vector3(0.0, h - head_r.y * (1.0 + HEAD_DROP) - STOOP_HEAD_DROP * h * spec.stoop, -STOOP_HEAD_FORWARD * h * spec.stoop)
	var unit_rows: Array[Vector4] = InhabitantMorph.head_rows(spec.head_shape)
	for index: int in HEAD_KEEP[lod]:
		var ring: Vector4 = unit_rows[index]
		head_rows.append(Vector4(ring.x * head_r.y, ring.y * head_r.x, ring.z * head_r.z, ring.w))
	hands = _hand_targets()


## Gibão do guarda (a peça de baixo) só de perto, onde o tabardo cobre; de longe o corpo já leva a cor do tabardo.
func body_color() -> Color:
	return spec.bottom if spec.garment == InhabitantSpec.Garment.TABARD and is_near else spec.top


func hem_y() -> float:
	return rows[0].x


## Linha do tronco (altura, rx, rz, expoente) interpolada na altura `y` (m).
func row_at(y: float) -> Vector4:
	for index: int in range(1, rows.size()):
		if y <= rows[index].x:
			return rows[index - 1].lerp(rows[index], clampf(inverse_lerp(rows[index - 1].x, rows[index].x, y), 0.0, 1.0))
	return rows[-1]


## Deslocamento (x, z) do centro do tronco na altura `y`.
func shift_at(y: float) -> Vector2:
	for index: int in range(1, rows.size()):
		if y <= rows[index].x:
			return shifts[index - 1].lerp(shifts[index], clampf(inverse_lerp(rows[index - 1].x, rows[index].x, y), 0.0, 1.0))
	return shifts[-1]


func half_width(y: float) -> float:
	return row_at(y).y


## Ponto da frente do tronco em (x, y), `lift` metros para fora.
func on_body(x: float, y: float, lift: float) -> Vector3:
	var row: Vector4 = row_at(y)
	var shift: Vector2 = shift_at(y)
	var across: float = clampf(absf(x - shift.x) / row.y, 0.0, 1.0)
	return Vector3(x, y, shift.y - row.z * pow(1.0 - pow(across, row.w), 1.0 / row.w) - lift)


## Casca que acompanha o tronco nas alturas `levels` (fração de H): `grow` vezes o raio mais `gap` (m), com a barra `flare` mais aberta; `arc` e `side_count` (0 = os do LOD) escolhem o trecho e os setores.
func shell(levels: Array[float], grow: float, gap: float, color: Color, arc: Vector2 = InhabitantShapes.FULL_ARC, side_count: int = 0, tint: Callable = Callable(), flare: float = 0.0) -> void:
	var ring_rows: Array[Vector4] = []
	var ring_shifts: PackedVector2Array = PackedVector2Array()
	for index: int in levels.size():
		var y: float = levels[index] * h
		var row: Vector4 = row_at(y)
		var opening: float = 1.0 + flare * (1.0 - float(index) / maxf(levels.size() - 1.0, 1.0))
		ring_rows.append(Vector4(y, row.y * grow * opening + gap, row.z * grow * opening + gap, row.w))
		ring_shifts.append(shift_at(y))
	shapes.loft(InhabitantShapes.y_frame(Vector3.ZERO), ring_rows, side_count if side_count > 0 else sides, color, 0.0, arc, ring_shifts, tint)


## Ponto do rosto na frente da cabeça: `spot` (x em fração do raio local, y em fração de ry) e `lift` metros para fora.
func face_point(spot: Vector2, lift: float) -> Vector3:
	var y: float = spot.y * head_r.y
	var row: Vector4 = head_row_at(y)
	var across: float = clampf(absf(spot.x), 0.0, 0.999)
	var local: Vector3 = Vector3(spot.x * row.y, y, -row.z * pow(1.0 - pow(across, row.w), 1.0 / row.w))
	var normal: Vector3 = Vector3(local.x / maxf(row.y * row.y, 0.0001), 0.0, local.z / maxf(row.z * row.z, 0.0001)).normalized()
	return head_c + local + normal * lift


## Linha da cabeça (altura relativa ao centro, rx, rz, expoente) na altura relativa `y`.
func head_row_at(y: float) -> Vector4:
	for index: int in range(1, head_rows.size()):
		if y <= head_rows[index].x:
			return head_rows[index - 1].lerp(head_rows[index], clampf(inverse_lerp(head_rows[index - 1].x, head_rows[index].x, y), 0.0, 1.0))
	return head_rows[-1]


## O lugar da carga à frente: na frente da parte mais saliente do tronco (a barriga conta).
func carry() -> Vector3:
	var y: float = CARRY_Y * h
	var above: float = y + CARRY_LIFT * h
	var front: float = minf(shift_at(y).y - row_at(y).z, shift_at(above).y - row_at(above).z)
	return Vector3(shift_at(y).x, y, front - CARRY_OUT * h)


## Onde as mãos ficam: caídas ao lado do tronco, à frente segurando a carga, a direita na haste ou na bengala e a esquerda no lampião.
func _hand_targets() -> Array[Vector3]:
	var low: float = HAND_HEIGHT * h
	var out: float = half_width(low) + HAND_OUT * h
	var forward: float = -STOOP_HAND_FORWARD * h * spec.stoop
	var list: Array[Vector3] = [Vector3(-out, low, forward), Vector3(out, low, forward)]
	if spec.has_accessory(&"basket") or spec.has_accessory(&"sack"):
		list = [carry() + Vector3.LEFT * CARRY_REACH * h, carry() + Vector3.RIGHT * CARRY_REACH * h]
	for kind: StringName in POLE_KINDS:
		if spec.has_accessory(kind):
			var raise: float = CANE_RAISE if kind == &"cane" else POLE_RAISE
			list[1] = Vector3(out + POLE_OUT * h, low + raise * h, forward - POLE_FORWARD * h)
	if spec.has_accessory(&"lantern"):
		list[0] = Vector3(-out, low + POLE_RAISE * h, forward - LANTERN_FORWARD * h)
	return list
