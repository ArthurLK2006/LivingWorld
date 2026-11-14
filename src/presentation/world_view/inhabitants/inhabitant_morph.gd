class_name InhabitantMorph
extends RefCounted
## Morfologia dos habitantes (ART-9e, protótipo isolado, só apresentação): da linha da matriz (InhabitantArchetypes) e do hash saem altura, constituição, idade, ombros, peito, barriga, quadril, pescoço, braços, pernas, cabeça e postura; daí vêm o perfil do tronco em anéis (medidas em metros, anatomia diferente por pessoa: não é escala uniforme do mesmo molde) e a forma da cabeça (redonda, comprida, queixo quadrado, queixo pequeno). Tudo [HIP] de arte, por hash de inteiros.

const REFERENCE_HEIGHT_M: float = 1.7
## Constituição: espessura do tronco (1 = médio) e a variação por hash em torno dela.
const BUILD_GIRTH: Dictionary[int, float] = {
	InhabitantSpec.Build.LEAN: 0.78, InhabitantSpec.Build.THIN: 0.88, InhabitantSpec.Build.AVERAGE: 1.0,
	InhabitantSpec.Build.STOCKY: 1.15, InhabitantSpec.Build.STRONG: 1.1, InhabitantSpec.Build.HEAVY: 1.32,
}
const GIRTH_JITTER: Vector2 = Vector2(0.95, 1.05)
## Metade da cabeça em fração de H por idade (o jovem tem a cabeça maior), e quanto cada postura curva o tronco (0 a 1).
const HEAD_FRACTION: Dictionary[int, float] = {InhabitantSpec.Age.YOUNG: 0.165, InhabitantSpec.Age.ADULT: 0.155, InhabitantSpec.Age.OLD: 0.15}
const STOOP_RANGE: Dictionary[int, Vector2] = {InhabitantSpec.Posture.UPRIGHT: Vector2(0.0, 0.12), InhabitantSpec.Posture.LEANING: Vector2(0.25, 0.45), InhabitantSpec.Posture.STOOPED: Vector2(0.7, 1.0)}
## Meias larguras e profundidades do molde médio (m, a 1,70 m): ombro, quadril, cintura, profundidade da cintura e do peito, pescoço, folga dos braços.
const SHOULDER_HALF_M: float = 0.215
const HIP_HALF_M: float = 0.245
const WAIST_HALF_M: float = 0.225
const WAIST_DEPTH_M: float = 0.2
const CHEST_DEPTH_M: float = 0.17
const NECK_HALF_M: float = 0.085
const ARM_ALLOWANCE_M: float = 0.1
## Alturas das marcas do corpo (fração de H): quadril, cintura, peito e ombro; o ombro desce com o pescoço comprido e com a curvatura; axila, ombro e pescoço ficam em volta dele.
const HIP_Y: float = 0.33
const WAIST_Y: float = 0.415
const CHEST_Y: float = 0.5
const SHOULDER_Y: float = 0.585
const NECK_SHIFT: float = 0.06
const STOOP_DROP: float = 0.035
const ARMPIT_BELOW: float = 0.035
const SHOULDER_ABOVE: float = 0.012
const NECK_ABOVE: float = 0.075
## A barra e o quanto ela abre por peça (vestido e casaco longo em sino; túnica curta deixa as pernas à mostra).
const HEM_Y: Dictionary[int, float] = {InhabitantSpec.Garment.TUNIC: 0.2, InhabitantSpec.Garment.LONG_COAT: 0.075, InhabitantSpec.Garment.TABARD: 0.21, InhabitantSpec.Garment.DRESS: 0.05, InhabitantSpec.Garment.SHORT_TUNIC: 0.27}
const HEM_FLARE: Dictionary[int, float] = {InhabitantSpec.Garment.TUNIC: 1.05, InhabitantSpec.Garment.LONG_COAT: 1.16, InhabitantSpec.Garment.TABARD: 1.0, InhabitantSpec.Garment.DRESS: 1.25, InhabitantSpec.Garment.SHORT_TUNIC: 1.0}
const DROOP_AMOUNT: float = 0.14
const LEAN_SIDE: float = 0.012
const STOOP_FORWARD: float = 0.1
## Quanto de cada anel acompanha a curvatura (de baixo para cima).
const STOOP_WEIGHT: Array[float] = [0.0, 0.0, 0.15, 0.45, 0.8, 1.0, 1.1]
## Cabeça: anéis (altura, rx, rz) de polo a polo, o peso da mandíbula em cada um e, por forma, a escala (x, y, z) e a mandíbula (rx, rz, expoente).
const HEAD_N: float = 2.3
const HEAD_BASE: Array[Vector3] = [Vector3(-1.0, 0.0, 0.0), Vector3(-0.9, 0.46, 0.44), Vector3(-0.76, 0.7, 0.68), Vector3(-0.52, 0.9, 0.88), Vector3(-0.22, 0.99, 0.97), Vector3(0.12, 1.0, 1.0), Vector3(0.45, 0.96, 0.97), Vector3(0.74, 0.8, 0.82), Vector3(0.92, 0.52, 0.55), Vector3(1.0, 0.0, 0.0)]
const JAW_WEIGHT: Array[float] = [1.0, 1.0, 0.95, 0.75, 0.3, 0.0, 0.0, 0.0, 0.0, 0.0]
const HEAD_SHAPES: Dictionary[int, Array] = {
	InhabitantSpec.HeadShape.ROUND: [Vector3(1.0, 1.0, 1.0), Vector3(1.0, 1.0, 2.3)],
	InhabitantSpec.HeadShape.LONG: [Vector3(0.9, 1.15, 0.93), Vector3(0.94, 0.96, 2.4)],
	InhabitantSpec.HeadShape.SQUARE: [Vector3(1.02, 0.97, 1.0), Vector3(1.14, 1.08, 3.0)],
	InhabitantSpec.HeadShape.SMALL_CHIN: [Vector3(1.0, 1.0, 1.0), Vector3(0.7, 0.8, 2.1)],
}


## Preenche a morfologia da ficha (a roupa já escolhida define a largura total) a partir da linha da matriz.
static func apply(spec: InhabitantSpec, entry: Dictionary, key: int) -> void:
	var span: Vector2 = entry["height"]
	spec.height_m = PlazaMeshKit.between(key, InhabitantSpec.Channel.HEIGHT, span.x, span.y)
	spec.build = _pick(entry["build"], key, InhabitantSpec.Channel.BUILD)
	spec.age = _pick(entry["age"], key, InhabitantSpec.Channel.AGE)
	spec.girth = BUILD_GIRTH[spec.build] * PlazaMeshKit.between(key, InhabitantSpec.Channel.GIRTH, GIRTH_JITTER.x, GIRTH_JITTER.y)
	spec.shoulder = _range(entry["shoulder"], key, InhabitantSpec.Channel.SHOULDER)
	spec.chest = _range(entry["chest"], key, InhabitantSpec.Channel.CHEST)
	spec.belly = _range(entry["belly"], key, InhabitantSpec.Channel.BELLY)
	spec.hip = _range(entry["hip"], key, InhabitantSpec.Channel.HIP)
	spec.neck = _range(entry["neck"], key, InhabitantSpec.Channel.NECK)
	spec.limbs = _range(entry["limbs"], key, InhabitantSpec.Channel.LIMBS)
	spec.legs = _range(entry["legs"], key, InhabitantSpec.Channel.LEGS)
	spec.head_scale = _range(entry["head"], key, InhabitantSpec.Channel.HEAD)
	spec.head_shape = _pick(entry["shapes"], key, InhabitantSpec.Channel.SHAPE)
	spec.posture = _pick(entry["posture"], key, InhabitantSpec.Channel.POSTURE)
	spec.stoop = _range(STOOP_RANGE[spec.posture], key, InhabitantSpec.Channel.STOOP)
	spec.droop = PlazaMeshKit.unit(key, InhabitantSpec.Channel.DROOP)
	spec.lean = PlazaMeshKit.between(key, InhabitantSpec.Channel.LEAN, -1.0, 1.0)
	var widest: float = 0.0
	for row: Vector4 in torso(spec)["rows"]:
		widest = maxf(widest, row.y)
	var arms: float = SHOULDER_HALF_M * spec.shoulder * sqrt(spec.height_m / REFERENCE_HEIGHT_M) + ARM_ALLOWANCE_M * spec.limbs
	spec.width_m = 2.0 * maxf(widest, arms)


## Altura do ombro (fração de H): desce com o pescoço comprido e com a curvatura.
static func shoulder_y(spec: InhabitantSpec) -> float:
	return SHOULDER_Y - NECK_SHIFT * (spec.neck - 1.0) - STOOP_DROP * spec.stoop


## Escala (x, y, z) da cabeça da forma `shape`.
static func shape_scale(shape: int) -> Vector3:
	var entry: Array = HEAD_SHAPES[shape]
	return entry[0]


## Os 10 anéis da cabeça da forma `shape` (altura, rx, rz em fração dos raios; expoente): a mandíbula muda por forma e fica de lado a calota.
static func head_rows(shape: int) -> Array[Vector4]:
	var entry: Array = HEAD_SHAPES[shape]
	var jaw: Vector3 = entry[1]
	var rows: Array[Vector4] = []
	for index: int in HEAD_BASE.size():
		var base: Vector3 = HEAD_BASE[index]
		var weight: float = JAW_WEIGHT[index]
		rows.append(Vector4(base.x, base.y * lerpf(1.0, jaw.x, weight), base.z * lerpf(1.0, jaw.y, weight), lerpf(HEAD_N, jaw.z, weight)))
	return rows


## O tronco em 7 anéis (barra, quadril, cintura, peito, axila, ombro, pescoço): {"rows": (altura m, rx m, rz m, expoente), "shifts": (x, z) do centro do anel}. A barriga avança, o ombro e o pescoço vão para a frente com a curvatura.
static func torso(spec: InhabitantSpec) -> Dictionary:
	var h: float = spec.height_m
	var scale: float = sqrt(h / REFERENCE_HEIGHT_M)
	var girth: float = spec.girth
	var belly_out: float = maxf(spec.belly - 1.0, 0.0)
	var shoulder_x: float = SHOULDER_HALF_M * spec.shoulder * (0.82 + 0.18 * girth) * scale
	var hip_x: float = HIP_HALF_M * lerpf(1.0, girth, 0.85) * spec.hip * scale
	var waist_x: float = WAIST_HALF_M * girth * lerpf(1.0, spec.belly, 0.55) * scale
	var waist_z: float = WAIST_DEPTH_M * girth * pow(spec.belly, 0.85) * scale
	var chest_z: float = CHEST_DEPTH_M * spec.chest * (0.7 + 0.3 * girth) * scale
	var chest_x: float = shoulder_x * (0.9 + 0.08 * spec.chest)
	var neck_x: float = NECK_HALF_M * (0.8 + 0.25 * girth) * scale
	var drop: float = 1.0 - DROOP_AMOUNT * spec.droop
	var flare: float = HEM_FLARE[spec.garment]
	var square: float = 2.2 + 0.7 * clampf(spec.shoulder - 1.0, -0.2, 0.5)
	var top: float = shoulder_y(spec)
	var heights: Array[float] = [HEM_Y[spec.garment], HIP_Y, WAIST_Y, CHEST_Y, top - ARMPIT_BELOW, top + SHOULDER_ABOVE, top + NECK_ABOVE]
	var radii: Array[Vector3] = [
		Vector3(hip_x * flare, hip_x * 0.8 * flare, 2.3), Vector3(hip_x, hip_x * 0.8, 2.3), Vector3(waist_x, waist_z, 2.2), Vector3(chest_x, chest_z, square),
		Vector3(shoulder_x, chest_z * 0.92, square), Vector3(shoulder_x * 0.8 * drop, chest_z * 0.7 * drop, 2.2), Vector3(neck_x, neck_x * 0.95, 2.2),
	]
	var forward: Array[float] = [-0.01, -0.02 - 0.05 * belly_out, -0.03 - 0.14 * belly_out, -0.015, 0.0, 0.0, 0.0]
	var rows: Array[Vector4] = []
	var shifts: PackedVector2Array = PackedVector2Array()
	for index: int in heights.size():
		rows.append(Vector4(heights[index] * h, radii[index].x, radii[index].y, radii[index].z))
		shifts.append(Vector2(spec.lean * LEAN_SIDE * heights[index] * h, forward[index] * scale - STOOP_FORWARD * h * spec.stoop * STOOP_WEIGHT[index]))
	return {"rows": rows, "shifts": shifts}


static func _range(span: Vector2, key: int, channel: int) -> float:
	return PlazaMeshKit.between(key, channel, span.x, span.y)


static func _pick(list: Array, key: int, channel: int) -> int:
	return list[mini(int(PlazaMeshKit.unit(key, channel) * list.size()), list.size() - 1)]
