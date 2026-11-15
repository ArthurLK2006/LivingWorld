class_name PlazaCrafted
extends RefCounted
## D1 (estudo isolado, nada entra no jogo): as peças da praça na nova linguagem, low poly maduro e facetado (arestas chanfradas, tábuas sobrepostas, fiadas de pedra, vigas e ferragens), só com o kit (PlazaMeshKit) e a ficha de estilo (PlazaStyle). Cada peça no quadro local dela (origem no chão, frente da barraca para +Z); sem sorteio, só o hash de inteiros. A PlazaStructures chama estas funções quando a ficha da variante traz estilo. Medidas [HIP] em metros.

## Barraca de encosto: metade da largura e da profundidade entre os postes, altura dos postes de trás e da frente, seção do poste, quanto o pano passa deles (trás, frente), tiras e caída das pontas da barra.
const HALF_W_M: float = 1.85
const HALF_D_M: float = 1.25
const BACK_H_M: float = 2.8
const FRONT_H_M: float = 2.0
const POST_M: float = 0.15
const BEAM_DROP_M: float = 0.08
const CANOPY_OVER_M: Vector2 = Vector2(0.35, 0.4)
const CANOPY_STRIPS: int = 7
const ACCENT_STRIP: int = 3
const CANOPY_SAG_M: float = 0.05
const STRIPE_SHIFT: float = 0.12
const LINING_GAP_M: float = 0.03
const SIDE_FLAPS: int = 4
const SIDE_FLAP_DROP_M: float = 0.32
const FINIAL_M: Vector2 = Vector2(0.106, 0.22)
const HEM_DROP_M: Vector2 = Vector2(0.2, 0.4)
const BACKDROP_STRIPS: int = 5
const COUNTER_M: Vector3 = Vector3(3.5, 0.86, 0.7)
const COUNTER_Z_M: float = 0.75
const COUNTER_BOARDS: int = 5
const TOP_BOARDS: int = 6
## Poço: anel de blocos (raio, quantos, fiadas, altura de cada uma, profundidade), postes (x e altura) e telhado (comprimento, subida e meia profundidade até o beiral).
const WELL_RING_M: float = 1.0
const WELL_BLOCKS: int = 10
const WELL_COURSES: int = 3
const WELL_COURSE_M: float = 0.27
const WELL_DEPTH_M: float = 0.42
const WELL_POST_X_M: float = 1.4
const WELL_POST_M: float = 2.3
const WELL_ROOF_M: Vector3 = Vector3(3.3, 0.8, 1.15)
## Barril: perfil (altura, raio) das 4 faixas e os aros de ferro; saco, bandeirola e fio.
const BARREL_PROFILE: Array[Vector2] = [Vector2(0.0, 0.26), Vector2(0.2, 0.33), Vector2(0.4, 0.365), Vector2(0.6, 0.33), Vector2(0.8, 0.26)]
const BARREL_HOOPS: Array[float] = [0.06, 0.2, 0.4, 0.6, 0.74]
const BARREL_SIDES: int = 10
const FLAG_FOLD_M: float = 0.05
const ROPE_M: float = 0.025

var _materials: Dictionary[StringName, Material]
var _style: PlazaStyle
## As cores dos panos da ficha: as de base e, a última, o acento.
var _cloth: Array[Color]


func _init(materials: Dictionary[StringName, Material], style: PlazaStyle, cloth_colors: Array[Color]) -> void:
	_materials = materials
	_style = style
	_cloth = cloth_colors


## A barraca `index`: balcão de tábuas, postes e vigas com nervuras (madeira, pedra e ferro no material sólido) e o toldo em tiras de barra em ponta (no de pano).
func stall(index: int) -> ArrayMesh:
	var kit: PlazaMeshKit = PlazaMeshKit.new()
	var mesh: ArrayMesh = ArrayMesh.new()
	_counter(kit, index)
	_frame(kit)
	kit.finish(mesh, _materials[&"solid"])
	_canopy(kit, index)
	kit.finish(mesh, _materials[&"cloth"])
	return mesh


## O poço: fiadas de pedra com juntas alternadas e a borda de lajes, a água, dois postes com travessa, o rolo com manivela, a corda e o balde, e o telhadinho de duas águas de telhas e vigas.
func well(kit: PlazaMeshKit) -> void:
	var block: float = 2.0 * WELL_RING_M * sin(PI / WELL_BLOCKS) * 1.06
	for course: int in WELL_COURSES:
		kit.stone_course(Vector3(0.0, WELL_COURSE_M * (course + 0.5), 0.0), WELL_RING_M, WELL_BLOCKS, Vector3(block, WELL_COURSE_M, WELL_DEPTH_M), _style.stone.darkened(0.12 - 0.05 * course), 0.5 * (course % 2), course)
	var rim: float = WELL_COURSE_M * WELL_COURSES
	kit.stone_course(Vector3(0.0, rim + 0.045, 0.0), WELL_RING_M, WELL_BLOCKS, Vector3(block, 0.09, WELL_DEPTH_M + 0.2), _style.stone.lightened(0.05), 0.25, WELL_COURSES)
	kit.frustum(Vector3(0.0, 0.6, 0.0), WELL_RING_M - WELL_DEPTH_M * 0.5 - 0.05, 0.0, 0.03, WELL_BLOCKS, PlazaData.WATER, 0.0, false)
	for side: float in [-1.0, 1.0]:
		kit.chamfered_box(Vector3(side * WELL_POST_X_M, WELL_POST_M * 0.5, 0.0), Vector3(POST_M, WELL_POST_M, POST_M), _style.wood_dark, _style.chamfer_m)
	kit.beam(Vector3(-WELL_POST_X_M - 0.1, 2.2, 0.0), Vector3(WELL_POST_X_M + 0.1, 2.2, 0.0), 0.14, 0.14, _style.wood)
	kit.beam(Vector3(-WELL_POST_X_M - 0.05, 1.75, 0.0), Vector3(WELL_POST_X_M + 0.3, 1.75, 0.0), 0.16, 0.16, _style.wood)
	kit.beam(Vector3(WELL_POST_X_M + 0.3, 1.75, 0.0), Vector3(WELL_POST_X_M + 0.3, 1.45, 0.0), 0.05, 0.05, _style.wood_dark)
	kit.beam(Vector3(0.0, 1.75, 0.0), Vector3(0.0, 1.3, 0.0), 0.03, 0.03, _style.rope)
	kit.frustum(Vector3(0.0, 0.86, 0.0), 0.15, 0.2, 0.27, 8, _style.wood_light)
	for hoop: float in [0.9, 1.06]:
		var radius: float = lerpf(0.15, 0.2, (hoop - 0.86) / 0.27) + 0.014
		kit.frustum(Vector3(0.0, hoop - 0.02, 0.0), radius, radius, 0.04, 8, _style.iron, 0.0, false)
	for side: float in [-1.0, 1.0]:
		kit.beam(Vector3(side * 0.2, 1.13, 0.0), Vector3(0.0, 1.3, 0.0), 0.025, 0.025, _style.iron)
	_well_roof(kit)


func crate() -> ArrayMesh:
	var kit: PlazaMeshKit = PlazaMeshKit.new()
	kit.chamfered_box(Vector3(0.0, 0.33, 0.0), Vector3(0.78, 0.66, 0.78), _style.wood, _style.chamfer_m)
	for quarter: int in 4:
		var turn: Basis = Basis(Vector3.UP, quarter * PI * 0.5)
		kit.planks(turn * Vector3(-0.39, 0.04, 0.39), turn * Vector3(0.78, 0.0, 0.0), Vector3(0.0, 0.58, 0.0), turn * Vector3.BACK, 3, _style.lap_m, _style.wood_light, quarter)
	kit.chamfered_box(Vector3(0.0, 0.7, 0.0), Vector3(0.86, 0.08, 0.86), _style.wood_dark, _style.chamfer_m)
	kit.beam(Vector3(-0.3, 0.1, 0.425), Vector3(0.3, 0.58, 0.425), 0.03, 0.07, _style.wood_dark)
	return kit.finish(ArrayMesh.new(), _materials[&"solid"])


func barrel() -> ArrayMesh:
	var kit: PlazaMeshKit = PlazaMeshKit.new()
	for band: int in BARREL_PROFILE.size() - 1:
		var low: Vector2 = BARREL_PROFILE[band]
		var high: Vector2 = BARREL_PROFILE[band + 1]
		kit.frustum(Vector3(0.0, low.x, 0.0), low.y, high.y, high.x - low.x, BARREL_SIDES, _style.wood_light.darkened(0.07 * (band % 2)), 0.0, false)
	var top: Vector2 = BARREL_PROFILE[BARREL_PROFILE.size() - 1]
	kit.frustum(Vector3(0.0, top.x, 0.0), top.y * 0.94, 0.0, 0.03, BARREL_SIDES, _style.wood, 0.0, false)
	for hoop: float in BARREL_HOOPS:
		var radius: float = _barrel_radius(hoop) + 0.02
		kit.frustum(Vector3(0.0, hoop - 0.025, 0.0), radius, radius, 0.05, BARREL_SIDES, _style.iron, 0.0, false)
	return kit.finish(ArrayMesh.new(), _materials[&"solid"])


func sack() -> ArrayMesh:
	var kit: PlazaMeshKit = PlazaMeshKit.new()
	kit.blob(Vector3(0.0, 0.25, 0.0), Vector3(0.37, 0.25, 0.28), Vector3i(5, 8, 1), 0.18, _style.linen)
	kit.frustum(Vector3(0.0, 0.46, 0.0), 0.12, 0.07, 0.12, 6, _style.linen.darkened(0.12))
	kit.frustum(Vector3(0.0, 0.52, 0.0), 0.085, 0.085, 0.04, 6, _style.rope, 0.0, false)
	kit.frustum(Vector3(0.0, 0.56, 0.0), 0.085, 0.0, 0.16, 5, _style.linen.lightened(0.05), 0.3)
	return kit.finish(ArrayMesh.new(), _materials[&"solid"])


## Poste com lampião (sem a parte que brilha) ou tocha: base de pedra, fuste facetado, braçadeiras e braço de ferro, capelo; a tocha leva o copo de ferro onde fica a chama.
func post(kit: PlazaMeshKit, height: float, is_torch: bool) -> void:
	var base: float = 0.0 if is_torch else 0.3
	if not is_torch:
		kit.chamfered_box(Vector3(0.0, 0.15, 0.0), Vector3(0.44, 0.3, 0.44), _style.stone, _style.chamfer_m)
	kit.frustum(Vector3(0.0, base, 0.0), 0.1, 0.065, height - base, 8, _style.wood_dark)
	var collars: Array[float] = [0.9, height - 0.6]
	if is_torch:
		collars = [0.5, 1.1]
	for collar: float in collars:
		var radius: float = lerpf(0.1, 0.065, (collar - base) / (height - base)) + 0.016
		kit.frustum(Vector3(0.0, collar - 0.03, 0.0), radius, radius, 0.06, 8, _style.iron, 0.0, false)
	if is_torch:
		kit.frustum(Vector3(0.0, height - 0.3, 0.0), 0.075, 0.16, 0.3, 8, _style.iron, 0.0, false)
		return
	var arm: float = height - 0.38
	kit.beam(Vector3(-0.5, arm, 0.0), Vector3(0.5, arm, 0.0), 0.05, 0.06, _style.iron)
	for side: float in [-1.0, 1.0]:
		kit.beam(Vector3(0.0, arm - 0.45, 0.0), Vector3(side * 0.42, arm, 0.0), 0.04, 0.05, _style.iron)
	for rib: int in 6:
		var angle: float = TAU * rib / 6.0
		kit.beam(Vector3(cos(angle) * 0.215, height, sin(angle) * 0.215), Vector3(cos(angle) * 0.275, height + 0.45, sin(angle) * 0.275), 0.03, 0.03, _style.iron)
	kit.frustum(Vector3(0.0, height + 0.45, 0.0), 0.32, 0.0, 0.25, 6, _style.iron)
	kit.frustum(Vector3(0.0, height + 0.69, 0.0), 0.05, 0.0, 0.15, 5, _style.iron)


## Bandeirola de duas facetas: a ponta de baixo sai um pouco do plano do fio, e as duas metades pegam a luz diferente.
func flag(kit: PlazaMeshKit, left: Vector3, right: Vector3, drop: float, color: Color) -> void:
	var middle: Vector3 = (left + right) * 0.5
	var side: Vector3 = (right - left).cross(Vector3.UP).normalized()
	var tip: Vector3 = middle + Vector3.DOWN * drop + side * FLAG_FOLD_M
	kit.tri(left, middle, tip, color, middle - side)
	kit.tri(middle, right, tip, color.darkened(0.08), middle - side)


## O fio das bandeirolas (os pontos da catenária) como vigas finas de corda.
func rope(mesh: ArrayMesh, points: Array[Vector3]) -> void:
	var kit: PlazaMeshKit = PlazaMeshKit.new()
	for index: int in points.size() - 1:
		kit.beam(points[index], points[index + 1], ROPE_M, ROPE_M, _style.rope)
	kit.finish(mesh, _materials[&"solid"])


func _counter(kit: PlazaMeshKit, index: int) -> void:
	var half: Vector3 = COUNTER_M * 0.5
	var center: Vector3 = Vector3(0.0, half.y, COUNTER_Z_M)
	var rise: Vector3 = Vector3(0.0, COUNTER_M.y - 0.06, 0.0)
	kit.box(center, COUNTER_M, _style.wood_dark)
	kit.planks(Vector3(-half.x, 0.04, center.z + half.z), Vector3(COUNTER_M.x, 0.0, 0.0), rise, Vector3.BACK, COUNTER_BOARDS, _style.lap_m, _style.wood_light, index)
	for side: float in [-1.0, 1.0]:
		kit.planks(Vector3(side * half.x, 0.04, center.z - half.z), Vector3(0.0, 0.0, COUNTER_M.z), rise, Vector3.RIGHT * side, 3, _style.lap_m, _style.wood_light, index + 7)
	var board: float = COUNTER_M.x / TOP_BOARDS
	for plank: int in TOP_BOARDS:
		var tone: Color = _style.wood_light.darkened(PlazaMeshKit.unit(index * TOP_BOARDS + plank, PlazaData.Channel.GRAIN) * 0.2)
		kit.box(Vector3(-half.x + board * (plank + 0.5), COUNTER_M.y + 0.025, center.z), Vector3(board - 0.014, 0.05, COUNTER_M.z + 0.1), tone)


## Postes com pé de pedra, vigas da frente e de trás, vigas laterais inclinadas, mãos-francesas e as nervuras do toldo por cima do pano.
func _frame(kit: PlazaMeshKit) -> void:
	for corner: int in 4:
		var height: float = BACK_H_M if corner < 2 else FRONT_H_M
		var spot: Vector3 = Vector3(HALF_W_M if corner % 2 == 0 else -HALF_W_M, 0.0, -HALF_D_M if corner < 2 else HALF_D_M)
		kit.chamfered_box(spot + Vector3(0.0, height * 0.5, 0.0), Vector3(POST_M, height, POST_M), _style.wood_dark, _style.chamfer_m)
		kit.chamfered_box(spot + Vector3(0.0, 0.09, 0.0), Vector3(POST_M * 2.0, 0.18, POST_M * 2.0), _style.stone, _style.chamfer_m)
		kit.frustum(spot + Vector3(0.0, height, 0.0), FINIAL_M.x, 0.0, FINIAL_M.y, 4, _style.wood_dark, PI * 0.25)
	for z: float in [-HALF_D_M, HALF_D_M]:
		var top: float = (BACK_H_M if z < 0.0 else FRONT_H_M) - BEAM_DROP_M
		kit.beam(Vector3(-HALF_W_M - 0.3, top, z), Vector3(HALF_W_M + 0.3, top, z), POST_M * 0.8, 0.16, _style.wood)
		for side: float in [-1.0, 1.0]:
			kit.beam(Vector3(side * HALF_W_M, top - 0.7, z), Vector3(side * (HALF_W_M - 0.6), top, z), 0.07, 0.09, _style.wood)
	for side: float in [-1.0, 1.0]:
		var back_top: Vector3 = Vector3(side * HALF_W_M, BACK_H_M - BEAM_DROP_M, -HALF_D_M)
		var front_top: Vector3 = Vector3(side * HALF_W_M, FRONT_H_M - BEAM_DROP_M, HALF_D_M)
		kit.beam(back_top.lerp(front_top, 1.12), back_top.lerp(front_top, -0.12), POST_M * 0.8, 0.16, _style.wood)
	var half: float = HALF_W_M + 0.35
	for rib: int in CANOPY_STRIPS + 1:
		var x: float = -half + half * 2.0 * rib / CANOPY_STRIPS
		kit.beam(Vector3(x, _roof_y(-HALF_D_M - CANOPY_OVER_M.x) + 0.035, -HALF_D_M - CANOPY_OVER_M.x), Vector3(x, _roof_y(HALF_D_M + CANOPY_OVER_M.y + 0.12) + 0.035, HALF_D_M + CANOPY_OVER_M.y + 0.12), 0.05, 0.05, _style.wood)


## O toldo em tiras (a do meio no acento, as outras alternando a base e a base escura), com um pouco de caimento no meio, a barra em ponta na frente e o pano de fundo.
func _canopy(kit: PlazaMeshKit, index: int) -> void:
	var base: Color = _cloth[index % (_cloth.size() - 1)]
	var accent: Color = _cloth[_cloth.size() - 1]
	var z_back: float = -HALF_D_M - CANOPY_OVER_M.x
	var z_front: float = HALF_D_M + CANOPY_OVER_M.y
	var z_mid: float = (z_back + z_front) * 0.5
	var y_back: float = _roof_y(z_back)
	var y_mid: float = _roof_y(z_mid) - CANOPY_SAG_M
	var y_front: float = _roof_y(z_front)
	var half: float = HALF_W_M + 0.35
	var width: float = half * 2.0 / CANOPY_STRIPS
	var under: Vector3 = Vector3(0.0, 1.2, 0.0)
	var above: Vector3 = Vector3(0.0, 4.0, 0.0)
	var lining: Color = _cloth[1].darkened(0.08)
	for strip: int in CANOPY_STRIPS:
		var left: float = -half + width * strip
		var right: float = left + width
		var tone: Color = accent if strip == ACCENT_STRIP else (base if strip % 2 == 0 else base.lightened(STRIPE_SHIFT))
		kit.quad(Vector3(left, y_back, z_back), Vector3(right, y_back, z_back), Vector3(right, y_mid, z_mid), Vector3(left, y_mid, z_mid), tone, under)
		kit.quad(Vector3(left, y_mid, z_mid), Vector3(right, y_mid, z_mid), Vector3(right, y_front, z_front), Vector3(left, y_front, z_front), tone, under)
		kit.quad(Vector3(left, y_back - LINING_GAP_M, z_back), Vector3(right, y_back - LINING_GAP_M, z_back), Vector3(right, y_mid - LINING_GAP_M, z_mid), Vector3(left, y_mid - LINING_GAP_M, z_mid), lining, above)
		kit.quad(Vector3(left, y_mid - LINING_GAP_M, z_mid), Vector3(right, y_mid - LINING_GAP_M, z_mid), Vector3(right, y_front - LINING_GAP_M, z_front), Vector3(left, y_front - LINING_GAP_M, z_front), lining, above)
		var drop: float = PlazaMeshKit.between(index * CANOPY_STRIPS + strip, PlazaData.Channel.STRIP, HEM_DROP_M.x, HEM_DROP_M.y)
		for point: int in 2:
			var from_x: float = left + width * 0.5 * point
			kit.tri(Vector3(from_x, y_front, z_front), Vector3(from_x + width * 0.5, y_front, z_front), Vector3(from_x + width * 0.25, y_front - drop, z_front), tone.darkened(0.06), under)
	for side: float in [-1.0, 1.0]:
		for flap: int in SIDE_FLAPS:
			var z0: float = lerpf(z_back, z_front, float(flap) / SIDE_FLAPS)
			var z1: float = lerpf(z_back, z_front, float(flap + 1) / SIDE_FLAPS)
			var middle: float = (z0 + z1) * 0.5
			kit.tri(Vector3(side * half, _roof_y(z0), z0), Vector3(side * half, _roof_y(z1), z1), Vector3(side * half, _roof_y(middle) - SIDE_FLAP_DROP_M, middle), base.darkened(0.06), Vector3(0.0, 1.2, middle))
	var behind: Vector3 = Vector3(0.0, 1.2, -3.0)
	for strip: int in BACKDROP_STRIPS:
		var left: float = -HALF_W_M + HALF_W_M * 2.0 * strip / BACKDROP_STRIPS
		var right: float = left + HALF_W_M * 2.0 / BACKDROP_STRIPS
		var tone: Color = lining.darkened(0.04 + 0.08 * (strip % 2))
		kit.quad(Vector3(left, 0.65, -HALF_D_M + 0.02), Vector3(right, 0.65, -HALF_D_M + 0.02), Vector3(right, BACK_H_M - 0.16, -HALF_D_M + 0.02), Vector3(left, BACK_H_M - 0.16, -HALF_D_M + 0.02), tone, behind)
		kit.tri(Vector3(left, 0.65, -HALF_D_M + 0.02), Vector3(right, 0.65, -HALF_D_M + 0.02), Vector3((left + right) * 0.5, 0.4, -HALF_D_M + 0.02), tone, behind)


## A altura do teto inclinado em `z`: a reta pelas pontas dos postes (alta atrás, baixa na frente).
func _roof_y(z: float) -> float:
	return remap(z, -HALF_D_M, HALF_D_M, BACK_H_M, FRONT_H_M)


## O telhado do poço: duas águas de 4 fiadas de telhas, as pontas fechadas, o forro, a cumeeira e as vigas dos beirais.
func _well_roof(kit: PlazaMeshKit) -> void:
	var half: float = WELL_ROOF_M.x * 0.5
	var ridge: float = WELL_POST_M + WELL_ROOF_M.y
	for side: float in [-1.0, 1.0]:
		var eave: Vector3 = Vector3(-half, WELL_POST_M, side * WELL_ROOF_M.z)
		var rise: Vector3 = Vector3(0.0, WELL_ROOF_M.y, -side * WELL_ROOF_M.z)
		kit.planks(eave, Vector3(WELL_ROOF_M.x, 0.0, 0.0), rise, Vector3(0.0, WELL_ROOF_M.z, side * WELL_ROOF_M.y).normalized(), 4, _style.shingle_lap_m, _style.shingle, int(side))
		for end: float in [-1.0, 1.0]:
			kit.tri(Vector3(end * half, WELL_POST_M, -WELL_ROOF_M.z), Vector3(end * half, WELL_POST_M, WELL_ROOF_M.z), Vector3(end * half, ridge, 0.0), _style.wood_dark, Vector3(0.0, WELL_POST_M + 0.3, 0.0))
			kit.beam(Vector3(end * (half + 0.06), WELL_POST_M - 0.04, side * (WELL_ROOF_M.z + 0.05)), Vector3(end * (half + 0.06), ridge + 0.04, 0.0), 0.05, 0.12, _style.wood)
	kit.quad(Vector3(-half, WELL_POST_M, -WELL_ROOF_M.z), Vector3(half, WELL_POST_M, -WELL_ROOF_M.z), Vector3(half, WELL_POST_M, WELL_ROOF_M.z), Vector3(-half, WELL_POST_M, WELL_ROOF_M.z), _style.wood_dark, Vector3(0.0, ridge, 0.0))
	kit.beam(Vector3(-half - 0.1, ridge + 0.04, 0.0), Vector3(half + 0.1, ridge + 0.04, 0.0), 0.16, 0.12, _style.wood_dark)


## O raio do perfil do barril na altura `height` (interpolado entre os pontos do perfil).
func _barrel_radius(height: float) -> float:
	for band: int in BARREL_PROFILE.size() - 1:
		var low: Vector2 = BARREL_PROFILE[band]
		var high: Vector2 = BARREL_PROFILE[band + 1]
		if height <= high.x:
			return lerpf(low.y, high.y, (height - low.x) / (high.x - low.x))
	return BARREL_PROFILE[BARREL_PROFILE.size() - 1].y
