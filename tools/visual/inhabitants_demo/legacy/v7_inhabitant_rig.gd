class_name V7InhabitantRig
extends RefCounted
## [v7 CONGELADA, só para a cena de comparação] As medidas de UM habitante (ART-9d, protótipo isolado, só apresentação): perfil do tronco por papel (pera, sino e trapézio) em anéis de superelipse com a variação do hash da ficha (barriga, ombro caído, inclinação), cabeça, pontos de mão e perguntas à superfície (`on_body`, `face_point`) que o corpo, a roupa, a cabeça e os acessórios usam para se pregar no tronco e no rosto. Pés em y = 0, origem entre os pés, frente para -Z (+X é a direita dele). Proporções [HIP] em fração da altura H, do raio-base R e dos raios da cabeça, a calibrar olhando as capturas.

const LOD_NEAR: int = 0
const LOD_MID: int = 1
const LOD_FAR: int = 2
const SIDES: Array[int] = [12, 8, 6]
const ARM_REACH_M: float = 0.09
const MIN_RADIUS_M: float = 0.16
const SEED_STRIDE: int = 1013
## Perfis do tronco, de baixo para cima: [altura/H, rx/R, rz/R, expoente da seção, avanço do centro em fração de R (negativo = para a frente)]. Aldeão = pera de ombro caído; comerciante = sino largo na barra; guarda = trapézio de ombros largos e cintura fina.
const PROFILES: Dictionary[StringName, Array] = {
	V7InhabitantSpec.VILLAGER: [[0.17, 0.86, 0.8, 2.4, -0.02], [0.26, 0.99, 0.95, 2.3, -0.05], [0.36, 1.06, 1.04, 2.2, -0.09], [0.46, 0.98, 0.95, 2.2, -0.06], [0.545, 0.8, 0.76, 2.2, -0.03], [0.6, 0.6, 0.58, 2.2, 0.0], [0.65, 0.33, 0.35, 2.2, 0.0]],
	V7InhabitantSpec.MERCHANT: [[0.07, 1.12, 1.02, 2.3, 0.0], [0.17, 1.07, 0.98, 2.3, -0.01], [0.29, 0.97, 0.96, 2.2, -0.05], [0.41, 0.92, 0.9, 2.2, -0.05], [0.51, 0.8, 0.78, 2.2, -0.02], [0.585, 0.6, 0.58, 2.2, 0.0], [0.65, 0.33, 0.35, 2.2, 0.0]],
	V7InhabitantSpec.GUARD: [[0.21, 0.88, 0.7, 2.6, 0.0], [0.32, 0.8, 0.68, 2.6, 0.0], [0.42, 0.72, 0.64, 2.6, -0.01], [0.51, 0.86, 0.7, 2.8, -0.03], [0.585, 1.0, 0.74, 3.0, -0.03], [0.63, 0.74, 0.58, 2.6, 0.0], [0.66, 0.38, 0.36, 2.4, 0.0]],
}
## Linhas do perfil que cada LOD usa, o quanto a barriga e o ombro caído (da ficha) pesam em cada linha, a barra do comerciante de túnica e a inclinação (fração de H por altura).
const TORSO_KEEP: Array[Array] = [[0, 1, 2, 3, 4, 5, 6], [0, 2, 4, 6], [0, 3, 6]]
const BELLY_WEIGHT: Array[float] = [0.5, 0.9, 1.0, 0.8, 0.3, 0.0, 0.0]
const DROOP_WEIGHT: Array[float] = [0.0, 0.0, 0.0, 0.0, 0.3, 1.0, 0.6]
const DROOP_AMOUNT: float = 0.14
const TUNIC_MERCHANT_HEM: float = 0.14
const LEAN: float = 0.012
## Cabeça: fração de H por papel (guarda com a cabeça menor), proporção em x e z, abaixamento do centro e anéis (altura, rx, rz em fração dos raios) por LOD.
const HEAD_FRACTION: Dictionary[StringName, float] = {V7InhabitantSpec.VILLAGER: 0.17, V7InhabitantSpec.MERCHANT: 0.165, V7InhabitantSpec.GUARD: 0.148}
const HEAD_ASPECT: Vector2 = Vector2(0.98, 0.95)
const HEAD_DROP: float = 0.06
const HEAD_N: float = 2.3
const HEAD_ROWS: Array[Vector3] = [Vector3(-1.0, 0.0, 0.0), Vector3(-0.88, 0.5, 0.48), Vector3(-0.64, 0.8, 0.78), Vector3(-0.26, 0.97, 0.95), Vector3(0.14, 1.0, 1.0), Vector3(0.54, 0.93, 0.94), Vector3(0.84, 0.68, 0.7), Vector3(1.0, 0.0, 0.0)]
const HEAD_KEEP: Array[Array] = [[0, 1, 2, 3, 4, 5, 6, 7], [0, 3, 5, 7], [0, 4, 7]]
## Mãos: altura delas caídas, folga para fora do tronco, carga à frente (altura, saída, meia largura entre as mãos), hastes que a mão direita segura e subida e avanço da mão na haste e no lampião.
const HAND_HEIGHT: float = 0.37
const HAND_OUT: float = 0.05
const POLE_OUT: float = 0.03
const CARRY_Y: float = 0.33
const CARRY_OUT: float = 0.04
const CARRY_REACH: float = 0.115
const POLE_KINDS: Array[StringName] = [&"staff", &"spear", &"guard_staff"]
const POLE_RAISE: float = 0.04
const POLE_FORWARD: float = 0.02
const LANTERN_FORWARD: float = 0.1

var spec: V7InhabitantSpec
var lod: int
var is_near: bool
var sides: int
var h: float
var r: float
var shapes: V7InhabitantShapes
var rows: Array[Vector4] = []
var shifts: PackedVector2Array = PackedVector2Array()
var head_c: Vector3
var head_r: Vector3
var head_rows: Array[Vector4] = []
var hands: Array[Vector3] = []


func _init(inhabitant: V7InhabitantSpec, level: int) -> void:
	spec = inhabitant
	lod = clampi(level, LOD_NEAR, LOD_FAR)
	is_near = lod == LOD_NEAR
	sides = SIDES[lod]
	h = spec.height_m
	r = maxf(spec.width_m * 0.5 - ARM_REACH_M, MIN_RADIUS_M)
	shapes = V7InhabitantShapes.new(spec.id * SEED_STRIDE)
	var profile: Array = PROFILES[spec.role]
	for index: int in TORSO_KEEP[lod]:
		var row: Array = profile[index]
		var height_frac: float = row[0]
		if index == 0 and spec.role == V7InhabitantSpec.MERCHANT and spec.garment == V7InhabitantSpec.Garment.TUNIC:
			height_frac = TUNIC_MERCHANT_HEM
		var radius_x: float = row[1]
		var radius_z: float = row[2]
		var exponent: float = row[3]
		var forward: float = row[4]
		var scale: float = r * lerpf(1.0, spec.belly, BELLY_WEIGHT[index]) * (1.0 - DROOP_AMOUNT * spec.droop * DROOP_WEIGHT[index])
		rows.append(Vector4(height_frac * h, radius_x * scale, radius_z * scale, exponent))
		shifts.append(Vector2(spec.lean * LEAN * height_frac * h, forward * r))
	var half: float = HEAD_FRACTION[spec.role] * h * spec.head_scale
	head_r = Vector3(HEAD_ASPECT.x, 1.0, HEAD_ASPECT.y) * half
	head_c = Vector3(0.0, h - half * (1.0 + HEAD_DROP), 0.0)
	for index: int in HEAD_KEEP[lod]:
		var ring: Vector3 = HEAD_ROWS[index]
		head_rows.append(Vector4(ring.x * head_r.y, ring.y * head_r.x, ring.z * head_r.z, HEAD_N))
	hands = _hand_targets()


## Gibão do guarda (a peça de baixo) só de perto, onde o tabardo cobre; de longe o corpo já leva a cor do tabardo.
func body_color() -> Color:
	return spec.bottom if spec.garment == V7InhabitantSpec.Garment.TABARD and is_near else spec.top


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


func carry() -> Vector3:
	var y: float = CARRY_Y * h
	return Vector3(shift_at(y).x, y, shift_at(y).y - row_at(y).z - CARRY_OUT * h)


## Onde as mãos ficam: caídas ao lado do tronco, à frente segurando a carga, a direita na haste e a esquerda no lampião.
func _hand_targets() -> Array[Vector3]:
	var low: float = HAND_HEIGHT * h
	var out: float = half_width(low) + HAND_OUT * h
	var list: Array[Vector3] = [Vector3(-out, low, 0.0), Vector3(out, low, 0.0)]
	if spec.has_accessory(&"basket") or spec.has_accessory(&"sack"):
		list = [carry() + Vector3.LEFT * CARRY_REACH * h, carry() + Vector3.RIGHT * CARRY_REACH * h]
	for kind: StringName in POLE_KINDS:
		if spec.has_accessory(kind):
			list[1] = Vector3(out + POLE_OUT * h, low + POLE_RAISE * h, -POLE_FORWARD * h)
	if spec.has_accessory(&"lantern"):
		list[0] = Vector3(-out, low + POLE_RAISE * h, -LANTERN_FORWARD * h)
	return list
