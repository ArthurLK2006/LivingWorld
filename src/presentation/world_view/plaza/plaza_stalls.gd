class_name PlazaStalls
extends RefCounted
## ART-5b1: os arquétipos novos de barraca da praça (toldo de uma água, mesa com guarda-sol e carroça de feira), no quadro local da barraca: origem no chão, frente para +Z. A tenda piramidal de sempre fica na PlazaStructures, que escolhe o arquétipo pela ficha da variante (PlazaVariants.Spec.stall_kind).
## Cada barraca é uma malha só: a madeira (material sólido, com o veio das tábuas), o pano principal e as tiras ou abas penduradas, que seguem a divisão de materiais da ficha como as da tenda (as de acento são emissivas; as de pano levam a cor por vértice e, por hash, um remendo). Tudo facetado, sem textura e sem sorteio: só o hash de inteiros de sempre (PlazaMeshKit.unit). Medidas [HIP] em PlazaData.

## Quanto as tábuas ficam à frente da face da caixa, para não brigar com ela.
const BOARD_LIFT_M: float = 0.01
## O teto do toldo passa dos postes (PlazaData.LEAN_TO_OVERHANG_M) para os lados e para frente e trás.
const ROOF_REACH_M: float = PlazaData.LEAN_TO_HALF_WIDTH_M + PlazaData.LEAN_TO_OVERHANG_M
const ROOF_EDGE_Z_M: float = PlazaData.LEAN_TO_HALF_DEPTH_M + PlazaData.LEAN_TO_OVERHANG_M
## A beirada do pano pendurado atrás do toldo, e quanto as abas e a franja descem (menor, maior).
const BACKDROP_BOTTOM_M: float = 0.5
const FRINGE_DROP_M: Vector2 = Vector2(0.25, 0.5)
## Mesa: banquinhos (raio de baixo e de cima, altura e lugar em x e z) e a folga entre a roda e a caixa.
const STOOL_M: Vector3 = Vector3(0.22, 0.2, 0.45)
const STOOL_SPOT_M: Vector2 = Vector2(0.55, 1.0)
const WHEEL_GAP_M: float = 0.02
## Carroça: as varas (tamanho) e o cubo da roda (fração do raio; quanto sai da face, em frações da meia espessura).
const SHAFT_M: Vector3 = Vector3(0.9, 0.07, 0.07)
const HUB_SHARE: float = 0.4
const HUB_LIFT: float = 1.2
## Chave de remendo das tiras que não podem ter um.
const NO_MEND: int = -1

var _materials: Dictionary[StringName, Material]
var _variant: PlazaVariants.Spec
## `PlazaStructures._cloth_surfaces`: reparte as peças de pano pelas superfícies de material da ficha.
var _cloth_surfaces: Callable


func _init(materials: Dictionary[StringName, Material], variant: PlazaVariants.Spec, cloth_surfaces: Callable) -> void:
	_materials = materials
	_variant = variant
	_cloth_surfaces = cloth_surfaces


## O tom da tábua `board` do conjunto `key`: as ímpares saem mais escuras (a faixa alterna) e o hash mexe um pouco em cada uma (o veio).
static func grain(key: int, board: int) -> Color:
	var shade: float = PlazaData.GRAIN_STEP * (board % 2) + PlazaMeshKit.between(key * PlazaData.GRAIN_BOARDS + board, PlazaData.Channel.GRAIN, 0.0, PlazaData.GRAIN_JITTER)
	return PlazaData.WOOD_LIGHT.darkened(shade)


## Se a tira de chave `key` leva remendo (em algumas, por hash).
static func is_mended(key: int) -> bool:
	return PlazaMeshKit.unit(key, PlazaData.Channel.MEND) < PlazaData.MEND_CHANCE


## A malha da barraca `index` do arquétipo `kind` (toldo de uma água, mesa com guarda-sol ou carroça); nula para os outros (a tenda é da PlazaStructures).
func build(kind: int, index: int) -> ArrayMesh:
	var kit: PlazaMeshKit = PlazaMeshKit.new()
	var mesh: ArrayMesh = ArrayMesh.new()
	match kind:
		PlazaData.StallKind.LEAN_TO:
			_lean_to(kit, mesh, index)
		PlazaData.StallKind.PARASOL:
			_parasol(kit, mesh, index)
		PlazaData.StallKind.CART:
			_cart(kit, mesh, index)
		_:
			return null
	return mesh


## Toldo de uma água sobre um balcão comprido, de frente aberta: 2 postes altos atrás e 2 baixos na frente, o teto inclinado em faixas de duas cores, um pano pendurado atrás e a franja na beirada da frente.
func _lean_to(kit: PlazaMeshKit, mesh: ArrayMesh, index: int) -> void:
	var counter: Vector3 = Vector3(0.0, PlazaData.LEAN_TO_COUNTER_M.y * 0.5, PlazaData.LEAN_TO_COUNTER_Z_M)
	kit.box(counter, PlazaData.LEAN_TO_COUNTER_M, PlazaData.WOOD_LIGHT)
	_boards(kit, counter, PlazaData.LEAN_TO_COUNTER_M, true, index * 2)
	_boards(kit, counter, PlazaData.LEAN_TO_COUNTER_M, false, index * 2 + 1)
	for post: int in 4:
		var is_back: bool = post < 2
		var spot: Vector3 = Vector3(PlazaData.LEAN_TO_HALF_WIDTH_M if post % 2 == 0 else -PlazaData.LEAN_TO_HALF_WIDTH_M, 0.0, -PlazaData.LEAN_TO_HALF_DEPTH_M if is_back else PlazaData.LEAN_TO_HALF_DEPTH_M)
		kit.frustum(spot, 0.08, 0.07, PlazaData.LEAN_TO_BACK_M if is_back else PlazaData.LEAN_TO_FRONT_M, 6, PlazaData.WOOD)
	kit.finish(mesh, _materials[&"solid"])
	var back: float = _roof_y(-ROOF_EDGE_Z_M)
	var front: float = _roof_y(ROOF_EDGE_Z_M)
	var under: Vector3 = Vector3(0.0, PlazaData.LEAN_TO_FRONT_M * 0.5, 0.0)
	for stripe: int in PlazaData.LEAN_TO_STRIPES:
		var left: float = lerpf(-ROOF_REACH_M, ROOF_REACH_M, float(stripe) / PlazaData.LEAN_TO_STRIPES)
		var right: float = lerpf(-ROOF_REACH_M, ROOF_REACH_M, float(stripe + 1) / PlazaData.LEAN_TO_STRIPES)
		_cloth_quad(kit, Vector3(left, back, -ROOF_EDGE_Z_M), Vector3(right, back, -ROOF_EDGE_Z_M), Vector3(right, front, ROOF_EDGE_Z_M), Vector3(left, front, ROOF_EDGE_Z_M), index + 2 * (stripe % 2), under, _mend_key(index, stripe))
	var wall: float = _roof_y(-PlazaData.LEAN_TO_HALF_DEPTH_M)
	var wall_z: float = -PlazaData.LEAN_TO_HALF_DEPTH_M
	_cloth_quad(kit, Vector3(-PlazaData.LEAN_TO_HALF_WIDTH_M, BACKDROP_BOTTOM_M, wall_z), Vector3(PlazaData.LEAN_TO_HALF_WIDTH_M, BACKDROP_BOTTOM_M, wall_z), Vector3(PlazaData.LEAN_TO_HALF_WIDTH_M, wall, wall_z), Vector3(-PlazaData.LEAN_TO_HALF_WIDTH_M, wall, wall_z), index + 1, Vector3(0.0, 1.5, -ROOF_EDGE_Z_M), _mend_key(index, PlazaData.LEAN_TO_STRIPES))
	_cloth_surfaces.call(kit, mesh, PlazaData.STRIPS_PER_STALL, _lean_fringe.bind(index))


## A altura do teto inclinado em `z`: a reta pelas pontas dos postes (alta atrás, baixa na frente).
func _roof_y(z: float) -> float:
	return remap(z, -PlazaData.LEAN_TO_HALF_DEPTH_M, PlazaData.LEAN_TO_HALF_DEPTH_M, PlazaData.LEAN_TO_BACK_M, PlazaData.LEAN_TO_FRONT_M)


## Tira `item` da franja pendurada na beirada da frente do teto (como as da tenda, só que mais curtas).
func _lean_fringe(kit: PlazaMeshKit, item: int, index: int) -> void:
	var width: float = ROOF_REACH_M * 2.0 / PlazaData.STRIPS_PER_STALL
	var edge: float = _roof_y(ROOF_EDGE_Z_M)
	var drop: float = PlazaMeshKit.between(index * PlazaData.STRIPS_PER_STALL + item, PlazaData.Channel.STRIP, FRINGE_DROP_M.x, FRINGE_DROP_M.y)
	var top_left: Vector3 = Vector3(-ROOF_REACH_M + width * item, edge, ROOF_EDGE_Z_M)
	_cloth_tri(kit, top_left, top_left + Vector3.RIGHT * width, top_left + Vector3(width * 0.5, -drop, 0.0), index + item, top_left - Vector3.BACK, _strip_key(index, PlazaData.LEAN_TO_STRIPES + 1 + item, item))


## Mesa baixa sob um guarda-sol redondo (cone achatado de PARASOL_SIDES lados, os gomos alternam duas cores) num mastro, com dois banquinhos e uma aba pendurada em cada gomo.
func _parasol(kit: PlazaMeshKit, mesh: ArrayMesh, index: int) -> void:
	var table: Vector3 = Vector3(0.0, PlazaData.PARASOL_TABLE_Y_M, 0.0)
	var leg_height: float = PlazaData.PARASOL_TABLE_Y_M - PlazaData.PARASOL_TABLE_M.y * 0.5
	var apex: Vector3 = Vector3(0.0, PlazaData.PARASOL_HEIGHT_M + PlazaData.PARASOL_RISE_M, 0.0)
	kit.box(table, PlazaData.PARASOL_TABLE_M, PlazaData.WOOD_LIGHT)
	_boards(kit, table, PlazaData.PARASOL_TABLE_M, true, index * 2)
	for side: float in [-1.0, 1.0]:
		kit.box(Vector3(side * (PlazaData.PARASOL_TABLE_M.x * 0.5 - 0.15), leg_height * 0.5, 0.0), Vector3(0.1, leg_height, PlazaData.PARASOL_TABLE_M.z * 0.8), PlazaData.WOOD)
		kit.frustum(Vector3(side * STOOL_SPOT_M.x, 0.0, STOOL_SPOT_M.y), STOOL_M.x, STOOL_M.y, STOOL_M.z, 6, PlazaData.WOOD)
	kit.frustum(Vector3.ZERO, 0.07, 0.05, apex.y, 6, PlazaData.WOOD)
	kit.finish(mesh, _materials[&"solid"])
	var inside: Vector3 = Vector3(0.0, PlazaData.PARASOL_HEIGHT_M, 0.0)
	for side: int in PlazaData.PARASOL_SIDES:
		_cloth_tri(kit, _parasol_rim(side), _parasol_rim(side + 1), apex, index + 2 * (side % 2), inside, _mend_key(index, side))
	_cloth_surfaces.call(kit, mesh, PlazaData.PARASOL_SIDES, _parasol_flap.bind(index))


## O ponto `side` da borda do guarda-sol.
func _parasol_rim(side: int) -> Vector3:
	var angle: float = TAU * side / PlazaData.PARASOL_SIDES
	return Vector3(cos(angle) * PlazaData.PARASOL_RADIUS_M, PlazaData.PARASOL_HEIGHT_M, sin(angle) * PlazaData.PARASOL_RADIUS_M)


## Aba `item`, pendurada na borda do gomo de mesmo número.
func _parasol_flap(kit: PlazaMeshKit, item: int, index: int) -> void:
	var drop: float = PlazaMeshKit.between(index * PlazaData.PARASOL_SIDES + item, PlazaData.Channel.STRIP, FRINGE_DROP_M.x, FRINGE_DROP_M.y)
	var left: Vector3 = _parasol_rim(item)
	var right: Vector3 = _parasol_rim(item + 1)
	_cloth_tri(kit, left, right, (left + right) * 0.5 + Vector3.DOWN * drop, index + 2 * (item % 2), Vector3(0.0, PlazaData.PARASOL_HEIGHT_M, 0.0), _strip_key(index, PlazaData.PARASOL_SIDES + item, item))


## Carroça de feira: caixa de tábuas sobre duas rodas de cilindro (uma de cada lado, no meio), duas varas na ponta e um arco de lona sobre a caixa (as faixas ao longo alternam duas cores).
func _cart(kit: PlazaMeshKit, mesh: ArrayMesh, index: int) -> void:
	var bed: Vector3 = PlazaData.CART_BED_M
	var center: Vector3 = Vector3(0.0, PlazaData.CART_WHEEL_M + bed.y * 0.5, 0.0)
	kit.box(center, bed, PlazaData.WOOD_LIGHT)
	_boards(kit, center, bed, false, index * 2 + 1)
	kit.box(center + Vector3(0.0, bed.y * 0.5, 0.0), Vector3(bed.x + 0.1, 0.06, bed.z + 0.1), PlazaData.WOOD)
	for side: float in [-1.0, 1.0]:
		_wheel(kit, Vector3(0.0, PlazaData.CART_WHEEL_M, side * (bed.z + PlazaData.CART_WHEEL_THICKNESS_M) * 0.5 + side * WHEEL_GAP_M))
		kit.box(Vector3(-(bed.x + SHAFT_M.x) * 0.5, center.y, side * bed.z * 0.25), SHAFT_M, PlazaData.WOOD)
	kit.finish(mesh, _materials[&"solid"])
	_canvas(kit, index, center.y + bed.y * 0.5)
	kit.finish(mesh, _materials[_variant.cloth_materials[0]])


## Roda de cilindro de eixo em Z: o aro, as duas tampas e um cubo mais claro em cada uma.
func _wheel(kit: PlazaMeshKit, center: Vector3) -> void:
	var half: Vector3 = Vector3(0.0, 0.0, PlazaData.CART_WHEEL_THICKNESS_M * 0.5)
	for side: int in PlazaData.CART_WHEEL_SIDES:
		var rim_a: Vector3 = _wheel_rim(side)
		var rim_b: Vector3 = _wheel_rim(side + 1)
		kit.quad(center + rim_a - half, center + rim_b - half, center + rim_b + half, center + rim_a + half, PlazaData.WOOD, center)
		for face: float in [-1.0, 1.0]:
			var cap: Vector3 = center + half * face
			var hub: Vector3 = center + half * face * HUB_LIFT
			kit.tri(cap, cap + rim_a, cap + rim_b, PlazaData.WOOD, center)
			kit.tri(hub, hub + rim_a * HUB_SHARE, hub + rim_b * HUB_SHARE, PlazaData.WOOD_LIGHT, center)


func _wheel_rim(side: int) -> Vector3:
	var angle: float = TAU * side / PlazaData.CART_WHEEL_SIDES
	return Vector3(cos(angle), sin(angle), 0.0) * PlazaData.CART_WHEEL_M


## O arco de lona: CART_ARCH_BANDS faixas ao longo da caixa, cada uma com CART_ARCH_SEGMENTS lados no arco que parte da borda da caixa (a altura `bed_top`).
func _canvas(kit: PlazaMeshKit, index: int, bed_top: float) -> void:
	var half: float = PlazaData.CART_BED_M.x * 0.5
	var axis: Vector3 = Vector3(0.0, bed_top, 0.0)
	for band: int in PlazaData.CART_ARCH_BANDS:
		var left: float = lerpf(-half, half, float(band) / PlazaData.CART_ARCH_BANDS)
		var right: float = lerpf(-half, half, float(band + 1) / PlazaData.CART_ARCH_BANDS)
		for segment: int in PlazaData.CART_ARCH_SEGMENTS:
			var from: Vector3 = _arch_point(segment, bed_top)
			var to: Vector3 = _arch_point(segment + 1, bed_top)
			_cloth_quad(kit, Vector3(left, from.y, from.z), Vector3(left, to.y, to.z), Vector3(right, to.y, to.z), Vector3(right, from.y, from.z), index + 2 * (band % 2), axis, _mend_key(index, band * PlazaData.CART_ARCH_SEGMENTS + segment))


func _arch_point(segment: int, bed_top: float) -> Vector3:
	var angle: float = PI * segment / PlazaData.CART_ARCH_SEGMENTS
	return Vector3(0.0, bed_top + PlazaData.CART_ARCH_RISE_M * sin(angle), PlazaData.CART_BED_M.z * 0.5 * cos(angle))


## `PlazaData.GRAIN_BOARDS` tábuas lado a lado (ao longo de x) sobre a face de cima (`on_top`) ou a da frente (+Z) da caixa `center`/`size`, o tom de cada uma de `grain(key, tábua)`.
func _boards(kit: PlazaMeshKit, center: Vector3, size: Vector3, on_top: bool, key: int) -> void:
	var low: Vector3 = center - size * 0.5
	var origin: Vector3 = Vector3(low.x, center.y + size.y * 0.5 + BOARD_LIFT_M, low.z) if on_top else Vector3(low.x, low.y, center.z + size.z * 0.5 + BOARD_LIFT_M)
	var along: Vector3 = Vector3(0.0, 0.0, size.z) if on_top else Vector3(0.0, size.y, 0.0)
	for board: int in PlazaData.GRAIN_BOARDS:
		var from: Vector3 = origin + Vector3(size.x * board / PlazaData.GRAIN_BOARDS, 0.0, 0.0)
		var to: Vector3 = origin + Vector3(size.x * (board + 1) / PlazaData.GRAIN_BOARDS, 0.0, 0.0)
		kit.quad(from, to, to + along, from + along, grain(key, board), center)


func _tone(slot: int) -> Color:
	return _variant.cloth_colors[slot % _variant.cloth_colors.size()]


## Triângulo de pano da cor `tone` (posição na paleta da ficha). Se a tira `key` é das remendadas (chave negativa: nunca), ganha um remendo: um triângulo menor, de outra cor, um pouco à frente da face dela.
func _cloth_tri(kit: PlazaMeshKit, a: Vector3, b: Vector3, c: Vector3, tone: int, inside: Vector3, key: int) -> void:
	kit.tri(a, b, c, _tone(tone), inside)
	if key < 0 or not is_mended(key):
		return
	var center: Vector3 = (a + b + c) / 3.0
	var normal: Vector3 = (b - a).cross(c - a).normalized()
	var lift: Vector3 = normal * signf(normal.dot(center - inside)) * PlazaData.MEND_LIFT_M
	kit.tri(center.lerp(a, PlazaData.MEND_SHRINK) + lift, center.lerp(b, PlazaData.MEND_SHRINK) + lift, center.lerp(c, PlazaData.MEND_SHRINK) + lift, _tone(tone + PlazaData.MEND_COLOR_SHIFT), inside)


## Quadrilátero de pano: dois triângulos da mesma cor, com o remendo (se a tira tem) no primeiro.
func _cloth_quad(kit: PlazaMeshKit, a: Vector3, b: Vector3, c: Vector3, d: Vector3, tone: int, inside: Vector3, key: int) -> void:
	_cloth_tri(kit, a, b, c, tone, inside, key)
	kit.tri(a, c, d, _tone(tone), inside)


func _mend_key(index: int, piece: int) -> int:
	return index * PlazaData.MEND_KEY_STRIDE + piece


## A chave de remendo da tira `item` (peça `piece` da barraca): só as tiras da primeira superfície de pano, a que leva a cor por vértice, podem ter remendo; nas de acento (emissivas) ele não apareceria.
func _strip_key(index: int, piece: int, item: int) -> int:
	return _mend_key(index, piece) if item % _variant.cloth_materials.size() == 0 else NO_MEND
