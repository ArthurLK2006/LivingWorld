class_name LegacyInhabitantBuilder
extends RefCounted
## CÓPIA CONGELADA da v6 (ART-9c, commit 33cc04b), SÓ para a cena de comparação v6 x v7 (não vai para PR). Malha de UM habitante (ART-9 e 9b, protótipo isolado, só apresentação): corpo em sino com ombros redondos, cabeça, rosto com bochechas e boca, capuz grosso, roupa e acessórios numa superfície só, facetada e com cor por vértice (PlazaMeshKit), pés em y = 0, origem entre os pés, frente para -Z (como `look_at`; +X é a direita dele). LOD 0 (perto) leva o rosto, os braços e os detalhes; LOD 1 (longe), só a silhueta e as cores principais. As proporções são [HIP] em fração da altura (H), do raio da barriga (R) e dos raios da cabeça, a calibrar olhando a cena de demonstração.

const LOD_NEAR: int = 0
const LOD_FAR: int = 1
const SIDES_NEAR: int = 10
const SIDES_FAR: int = 6
const HOOD_SIDES: int = 9
const BOOT_SIDES: int = 7
const FULL_ARC: Vector2 = Vector2(0.0, TAU)
const FRONT_ARC: Vector2 = Vector2(-PI / 2.0 - 0.62, -PI / 2.0 + 0.62)
const BACK_ARC: Vector2 = Vector2(PI / 2.0 - 0.62, PI / 2.0 + 0.62)
## Irregularidade das facetas (fração do raio), por hash do id; o canal fica depois dos da ficha.
const JITTER: float = 0.03
const HEAD_JITTER: float = 0.02
const JITTER_CHANNEL: int = 64
const RING_STRIDE: int = 61
const SEED_STRIDE: int = 1013
const SALT_PER_M: float = 1000.0
const POLE_EPSILON: float = 0.0005
## Luz rebatida do chão, pintada nos vértices: as faces voltadas para baixo (queixo, barra do manto) clareiam rumo a BOUNCE_COLOR (areia quente, não branco, para não desbotar a cor), até a fração BOUNCE.
const BOUNCE: float = 0.7
const BOUNCE_COLOR: Color = Color("F4DDB0")
## Corpo em sino gordo: perfil do manto (altura em fração de H, raio em fração de R): a barra afunila, a barriga é o ponto mais largo e o alto arredonda nos ombros. O pescoço fecha dentro da cabeça. A largura TOTAL do habitante inclui os braços (ARM_REACH_M de cada lado).
const BELL_PROFILE: Array[Vector2] = [Vector2(0.1, 0.9), Vector2(0.2, 0.97), Vector2(0.31, 1.0), Vector2(0.45, 0.93), Vector2(0.56, 0.78), Vector2(0.635, 0.47)]
const COAT_HEM: Vector2 = Vector2(0.065, 1.1)
const NEAR_RINGS: Array[int] = [0, 1, 2, 3, 4, 5]
const FAR_RINGS: Array[int] = [0, 2, 4, 5]
const NECK_DEPTH: float = 0.78
const NECK_MIN_RISE: float = 0.01
const BODY_DEPTH: float = 0.95
const ARM_REACH_M: float = 0.09
const MIN_RADIUS_M: float = 0.16
## Faixas sobre o manto (altura em fração de H, folga sobre o raio dele): cinto, avental e painéis do tabardo. O escudo do tabardo: altura do centro, meia largura (fração de H), levantamento (m) e contorno em meias larguras.
const BELT_SPANS: Array[Vector2] = [Vector2(0.285, 1.07), Vector2(0.325, 1.06)]
const APRON_SPANS: Array[Vector2] = [Vector2(0.105, 1.12), Vector2(0.28, 1.07), Vector2(0.43, 1.05)]
const TABARD_SPANS: Array[Vector2] = [Vector2(0.095, 1.13), Vector2(0.28, 1.07), Vector2(0.45, 1.05), Vector2(0.57, 1.05)]
const PANEL_SIDES: int = 3
const SHIELD_Y: float = 0.45
const SHIELD_HALF: float = 0.034
const SHIELD_LIFT_M: float = 0.022
const SHIELD_LAYER_LIFT_M: float = 0.006
const SHIELD_INNER: float = 0.62
const SHIELD_OUTLINE: Array[Vector2] = [Vector2(-1.0, 1.0), Vector2(1.0, 1.0), Vector2(1.0, 0.15), Vector2(0.0, -1.3), Vector2(-1.0, 0.15)]
const SHIELD_EDGE_DARKEN: float = 0.45
## Botas redondas (anéis de altura, raio em x e em z, fração de H), meia e pés: x dos pés (limitado pela barriga), saída das botas, raio e topo da meia.
const BOOT_RINGS: Array[Vector3] = [Vector3(0.0, 0.042, 0.064), Vector3(0.03, 0.053, 0.08), Vector3(0.062, 0.04, 0.06)]
const FOOT_X: float = 0.1
const FOOT_IN_R: float = 0.52
const BOOT_FORWARD: float = 0.02
const SOCK_SIDES: int = 5
const SOCK_RADIUS: float = 0.032
const SOCK_TOP: float = 0.115
## Ombros redondos e braços curtos e rombudos: altura do ombro, raio da bola do ombro, raios da manga (ombro, pulso), mão de luva (raios) e onde ela cai (altura; x em fração do raio da barriga, colada nela).
const SHOULDER_Y: float = 0.585
const SHOULDER_BALL: float = 0.086
const SLEEVE_RADII: Vector2 = Vector2(0.078, 0.056)
const ARM_SIDES: int = 6
const HAND_RADII: Vector3 = Vector3(0.05, 0.056, 0.045)
## Polegar da luva: lugar sobre a mão (x para dentro, y para cima, z para a frente, em frações dos raios dela) e tamanho (fração dos raios da mão).
const THUMB_SPOT: Vector3 = Vector3(0.6, 0.3, -0.75)
const THUMB_SIZE: Vector3 = Vector3(0.5, 0.6, 0.5)
const HAND_HEIGHT: float = 0.37
const HAND_IN_R: float = 0.98
## Cabeça: meia altura (fração de H, vezes a escala da ficha), abaixamento do centro (fração da meia altura), proporção dos outros dois raios e anéis da casca.
const HEAD_HALF_HEIGHT: float = 0.15
const HEAD_DROP: float = 0.1
const HEAD_ASPECT: Vector2 = Vector2(0.95, 0.92)
const HEAD_RINGS_NEAR: int = 6
const HEAD_RINGS_FAR: int = 3
const SHELL_RINGS_NEAR: int = 4
const SHELL_RINGS_FAR: int = 2
## Rosto, em fração dos raios da cabeça (x, y sobre a face): olhos pontuais, sobrancelhas em barra (de dentro para fora), nariz (raio e comprimento sobre rx), boca (do canto ao centro) e bochechas rosadas; tudo em geometria, levantado FACE_LIFT sobre a casca para não afundar nas facetas.
const EYE_SPOT: Vector2 = Vector2(0.37, 0.06)
const EYE_HALF: Vector2 = Vector2(0.085, 0.12)
const BROW_INNER: Vector2 = Vector2(0.15, 0.32)
const BROW_OUTER: Vector2 = Vector2(0.58, 0.34)
const BROW_THICK: float = 0.045
const NOSE_SPOT: Vector2 = Vector2(0.0, -0.12)
const NOSE_SIZE: Vector2 = Vector2(0.17, 0.34)
const MOUTH_CORNER: Vector2 = Vector2(0.21, -0.435)
const MOUTH_CENTER: Vector2 = Vector2(0.0, -0.455)
const MOUTH_THICK: float = 0.03
const CHEEK_SPOT: Vector2 = Vector2(0.56, -0.2)
const CHEEK_HALF: Vector2 = Vector2(0.14, 0.12)
## Bochechas: manchas redondas (8 lados, quase planas) e menores que as de antes.
const CHEEK_SIDES: int = 8
const CHEEK_BULGE: float = 1.3
const PATCH_SIDES: int = 6
const PATCH_BULGE: float = 1.7
const FACE_LIFT: float = 0.05
const FACE_MIN_DEPTH: float = 0.04
const NOSE_BLUSH: float = 0.25
const CHEEK_BLUSH: float = 0.45
const BROW_DARKEN: float = 0.35
## Coberturas em casca (fração dos raios da cabeça): deslocamento do centro, escala dos raios, ângulo polar máximo (graus) e largura da faixa de borda (graus; 0 = sem faixa). O capuz de perto é a tigela HOOD_BOWL; esta casca só serve ao capuz de longe.
const SHELLS: Dictionary[int, Array] = {
	LegacyInhabitantSpec.HeadCover.NONE: [Vector3(0.0, 0.14, 0.12), Vector3(1.04, 0.95, 1.04), 96.0, 0.0],
	LegacyInhabitantSpec.HeadCover.HOOD: [Vector3(0.0, 0.06, 0.2), Vector3(1.13, 1.1, 1.1), 126.0, 0.0],
	LegacyInhabitantSpec.HeadCover.CAP: [Vector3(0.0, 0.5, 0.04), Vector3(1.06, 0.72, 1.08), 100.0, 9.0],
	LegacyInhabitantSpec.HeadCover.OPEN_HELM: [Vector3(0.0, 0.45, 0.0), Vector3(1.1, 0.8, 1.12), 96.0, 12.0],
	LegacyInhabitantSpec.HeadCover.HOOD_CAP: [Vector3(0.0, 0.95, 0.38), Vector3(1.0, 0.72, 0.95), 100.0, 0.0],
}
## Boné sobre o capuz (HOOD_CAP): a entrada de cima é a cúpula do boné (acima do capuz, sem faixa); o capuz leva o tom da roupa mais escuro e o boné a cor da calça, como na referência.
const CAP_RINGS_NEAR: int = 3
const HOOD_CAP_DARKEN: float = 0.3
## Capuz grosso: tigela aberta para a frente, de revolução em torno de Z (profundidade em fração de rz, raios em x e em y em fração de rx e ry), do aro de dentro (a borda do rosto) e do aro de fora (a face da frente, a faixa grossa) até o fundo; o arco deixa o queixo livre. A gola é o capelo, liso e contínuo com o capuz: perfil (altura em fração de H, raio em fração de R) que acompanha o manto uns 8% maior e termina num beiral, sem formar cúpula.
const HOOD_BOWL: Array[Vector3] = [Vector3(-0.5, 0.9, 0.93), Vector3(-0.34, 1.13, 1.16), Vector3(0.05, 1.24, 1.26), Vector3(0.75, 1.02, 1.06), Vector3(1.3, 0.0, 0.0)]
const HOOD_ARC: Vector2 = Vector2(-0.87, 4.01)
const HOOD_RIM_DARKEN: float = 0.2
const COWL_PROFILE: Array[Vector2] = [Vector2(0.5, 0.93), Vector2(0.57, 0.8), Vector2(0.63, 0.54), Vector2(0.675, 0.3)]
const COWL_JITTER: float = 0.015
const RIM_GROW: float = 1.03
const HELM_NASAL: Vector3 = Vector3(0.1, 0.36, 0.06)
const HELM_KNOB: float = 0.1
const HELM_KNOB_Y: float = 1.25
const HAT_BRIM: Vector3 = Vector3(1.4, 1.2, 0.1)
const HAT_CROWN: Vector3 = Vector3(0.98, 0.78, 0.6)
const HAT_BAND: float = 0.16
const HAT_RISE: float = 0.5
const HAT_FAR_HEIGHT: float = 0.8
## Acessórios (fração de H). Os de silhueta grande também vão no LOD 1. Bolsa: tamanho, lugar (altura; x sobre o raio), giro e fita. Bolsinha. Carga à frente (cesta, saco): altura, saída e meia largura das mãos.
const FAR_ACCESSORIES: Array[StringName] = [&"basket", &"sack", &"staff", &"spear", &"guard_staff"]
const SATCHEL_SIZE: Vector3 = Vector3(0.2, 0.15, 0.085)
## Aba da bolsa (fração da altura dela), fecho (meia largura e meia altura, fração da bolsa) e saída do fecho (m).
const FLAP_HEIGHT: float = 0.55
const CLASP: Vector2 = Vector2(0.13, 0.1)
const CLASP_LIFT_M: float = 0.004
const SATCHEL_SPOT: Vector2 = Vector2(0.28, 0.8)
const SATCHEL_YAW: float = 0.5
const STRAP_RADII: Vector2 = Vector2(0.028, 0.028)
const STRAP_LIFT_M: float = 0.012
const POUCH_SPOT: Vector2 = Vector2(0.24, 0.55)
const POUCH_RADIUS: float = 0.04
const CARRY_Y: float = 0.33
const CARRY_OUT: float = 0.04
const CARRY_REACH: float = 0.115
const BASKET: Vector3 = Vector3(0.085, 0.11, 0.11)
const HANDLE_RADIUS: float = 0.008
const HANDLE_RISE: float = 0.9
const SACK: Vector3 = Vector3(0.115, 0.125, 0.105)
const LANTERN_SIZE: float = 0.055
const LANTERN_DROP: float = 0.1
const LANTERN_FORWARD: float = 0.1
## Hastes (altura do topo, raio, ponta: fração de H); a mão direita segura. O raio da lâmina é fração de H.
const POLES: Dictionary[StringName, Vector3] = {&"staff": Vector3(1.02, 0.02, 0.0), &"spear": Vector3(0.92, 0.014, 0.13), &"guard_staff": Vector3(0.95, 0.022, 0.07)}
const POLE_RAISE: float = 0.04
const POLE_FORWARD: float = 0.02
const BLADE_RADIUS: float = 0.04
const BLADE_FLAT: float = 0.3
const CAP_RADIUS: float = 0.03
const KNOB_RADII: Vector3 = Vector3(0.03, 0.035, 0.03)
## Cores dos acessórios e do rosto.
const WOOD: Color = Color("B07A45")
const WOOD_DARK: Color = Color("7A5230")
const LEATHER: Color = Color("6A4630")
const POUCH: Color = Color("8A5A35")
const LINEN: Color = Color("E8DFC8")
const STEEL: Color = Color("A9B2BC")
const DARK_METAL: Color = Color("3A3A40")
const WICKER: Color = Color("C09A55")
const BURLAP: Color = Color("B89B68")
const ROPE: Color = Color("8A6A3A")
const GLASS: Color = Color("FFC24D")
const APPLE: Color = Color("C0452F")
const FACE_DARK: Color = Color("2B2220")
const MOUTH_COLOR: Color = Color("6E3B32")
const BLUSH: Color = Color("E8707A")

var _kit: PlazaMeshKit = PlazaMeshKit.new()
var _spec: LegacyInhabitantSpec
var _is_near: bool
var _sides: int
var _h: float
var _r: float
var _head: Vector3
var _head_c: Vector3
var _seed: int
var _profile: Array[Vector2] = []
var _hands: Array[Vector3] = []


func _init(spec: LegacyInhabitantSpec, lod: int) -> void:
	_spec = spec
	_is_near = lod == LOD_NEAR
	_sides = SIDES_NEAR if _is_near else SIDES_FAR
	_h = spec.height_m
	_r = maxf(spec.width_m * 0.5 - ARM_REACH_M, MIN_RADIUS_M)
	var half_height: float = HEAD_HALF_HEIGHT * _h * spec.head_scale
	_head = Vector3(HEAD_ASPECT.x, 1.0, HEAD_ASPECT.y) * half_height
	_head_c = Vector3(0.0, _h - half_height * (1.0 + HEAD_DROP), 0.0)
	_seed = spec.id * SEED_STRIDE
	for index: int in (NEAR_RINGS if _is_near else FAR_RINGS):
		_profile.append(COAT_HEM if index == 0 and spec.garment == LegacyInhabitantSpec.Garment.LONG_COAT else BELL_PROFILE[index])


## A malha do habitante: UMA superfície, com `material` (o `solid` da praça se vier nulo). Passar o mesmo material a todos os habitantes de uma cena os faz dividir um só.
static func build(spec: LegacyInhabitantSpec, lod: int, material: Material = null) -> ArrayMesh:
	var surface_material: Material = material if material != null else PlazaMaterials.create()[&"solid"]
	return LegacyInhabitantBuilder.new(spec, lod).assemble(surface_material)


func assemble(material: Material) -> ArrayMesh:
	_hands = _hand_targets()
	_legs()
	_torso()
	_arms()
	_lathe(_head_c, _dome(_head, 180.0, HEAD_RINGS_NEAR if _is_near else HEAD_RINGS_FAR), _sides, _spec.skin, HEAD_JITTER)
	_cover()
	if _is_near:
		_face()
	for kind: StringName in _spec.accessories:
		if _is_near or FAR_ACCESSORIES.has(kind):
			_accessory(kind)
	return _kit.finish(ArrayMesh.new(), material)


func _body_color() -> Color:
	return _spec.bottom if _spec.garment == LegacyInhabitantSpec.Garment.TABARD and _is_near else _spec.top


## Botas redondas (revolução oval com o fundo aberto) e a meia da cor da calça; de longe, um bloco só.
func _legs() -> void:
	var foot_x: float = minf(FOOT_X * _h, _r * FOOT_IN_R)
	var forward: float = -BOOT_FORWARD * _h
	var widest: Vector3 = BOOT_RINGS[1] * _h
	if not _is_near:
		_kit.box(Vector3(0.0, widest.x, forward), Vector3(foot_x * 2.0 + widest.y * 2.0, widest.x * 2.0, widest.z * 2.0), _spec.boots)
		return
	var boot: Array[Vector3] = []
	for ring: Vector3 in BOOT_RINGS:
		boot.append(ring * _h)
	for side: float in [-1.0, 1.0]:
		var x: float = side * foot_x
		_lathe(Vector3(x, 0.0, forward), boot, BOOT_SIDES, _spec.boots, JITTER)
		_tube(Vector3(x, boot[2].x * 0.9, forward * 0.5), Vector3(x, SOCK_TOP * _h, 0.0), Vector2(SOCK_RADIUS, SOCK_RADIUS) * _h, SOCK_SIDES, _spec.bottom)


func _torso() -> void:
	var rings: Array[Vector3] = _rings_of(_profile)
	rings.append(Vector3(_neck_top(rings[-1].x), 0.0, 0.0))
	_lathe(Vector3.ZERO, rings, _sides, _body_color(), JITTER)
	if not _is_near:
		return
	if _spec.garment == LegacyInhabitantSpec.Garment.TABARD:
		_band(TABARD_SPANS, PANEL_SIDES, _spec.top, FRONT_ARC)
		_band(TABARD_SPANS, PANEL_SIDES, _spec.top, BACK_ARC)
		_shield()
	_band(BELT_SPANS, _sides, _spec.trim)


## Ombros redondos (uma bola em cada), mangas curtas que afinam até o pulso e mãos de luva.
func _arms() -> void:
	if not _is_near:
		return
	var y: float = SHOULDER_Y * _h
	var ball: float = SHOULDER_BALL * _h
	for index: int in 2:
		var shoulder: Vector3 = Vector3((2.0 * index - 1.0) * _radius_at(y), y, 0.0)
		_kit.blob(shoulder, Vector3(ball, ball * 0.95, ball), Vector3i(3, 6, index), 0.04, _body_color())
		_tube(shoulder, _hands[index], SLEEVE_RADII * _h, ARM_SIDES, _body_color())
		var palm: Vector3 = HAND_RADII * _h
		_kit.blob(_hands[index], palm, Vector3i(2, 6, 5 + index), 0.05, _spec.skin)
		var inward: float = 1.0 - 2.0 * index
		var thumb: Vector3 = _hands[index] + Vector3(inward * palm.x * THUMB_SPOT.x, palm.y * THUMB_SPOT.y, palm.z * THUMB_SPOT.z)
		_kit.blob(thumb, palm * THUMB_SIZE, Vector3i(2, 4, 7 + index), 0.05, _spec.skin)


func _cover() -> void:
	match _spec.head_cover:
		LegacyInhabitantSpec.HeadCover.WIDE_HAT:
			_wide_hat()
		LegacyInhabitantSpec.HeadCover.NONE:
			_shell(_spec.head_cover, _spec.hair)
		LegacyInhabitantSpec.HeadCover.HOOD:
			if _is_near:
				_hood(_spec.cover_color)
			else:
				_shell(_spec.head_cover, _spec.cover_color)
		LegacyInhabitantSpec.HeadCover.HOOD_CAP:
			if _is_near:
				_hood(_hood_color())
			else:
				_shell(LegacyInhabitantSpec.HeadCover.HOOD, _hood_color())
			_cap_over_hood()
		LegacyInhabitantSpec.HeadCover.OPEN_HELM:
			_shell(_spec.head_cover, _spec.cover_color)
			if not _is_near:
				return
			_kit.box(_surface_point(Vector2(0.0, 0.2), 0.0) + Vector3.FORWARD * HELM_NASAL.z * _head.z, HELM_NASAL * _head, _spec.cover_color)
			_kit.blob(_head_c + Vector3(0.0, _head.y * HELM_KNOB_Y, 0.0), Vector3(HELM_KNOB * _head.x, HELM_KNOB * _head.x, HELM_KNOB * _head.x), Vector3i(3, 5, 9), 0.0, _spec.trim)
		_:
			_shell(_spec.head_cover, _spec.cover_color)


func _shell(cover: int, color: Color) -> void:
	var shell: Array = SHELLS[cover]
	var offset: Vector3 = shell[0]
	var scale: Vector3 = shell[1]
	var polar_deg: float = shell[2]
	var rim_deg: float = shell[3]
	_lathe(_head_c + offset * _head, _dome(_head * scale, polar_deg, SHELL_RINGS_NEAR if _is_near else SHELL_RINGS_FAR), _sides, color, JITTER)
	if rim_deg > 0.0 and _is_near:
		_lathe(_head_c + offset * _head, _dome(_head * scale * RIM_GROW, polar_deg, 1, polar_deg - rim_deg), _sides, _spec.trim, JITTER)


## O capuz de perto: a tigela com o aro grosso (a primeira faixa, mais escura por dentro) em volta do rosto e o capelo liso sobre os ombros, que acompanha o manto.
func _hood(color: Color) -> void:
	var rim: Array[Vector3] = []
	var bowl: Array[Vector3] = []
	for index: int in HOOD_BOWL.size():
		var ring: Vector3 = Vector3(HOOD_BOWL[index].x * _head.z, HOOD_BOWL[index].y * _head.x, HOOD_BOWL[index].z * _head.y)
		if index <= 1:
			rim.append(ring)
		if index >= 1:
			bowl.append(ring)
	_lathe(_head_c, rim, HOOD_SIDES, color.darkened(HOOD_RIM_DARKEN), HEAD_JITTER, HOOD_ARC, true)
	_lathe(_head_c, bowl, HOOD_SIDES, color, HEAD_JITTER, HOOD_ARC, true)
	var cowl: Array[Vector3] = _rings_of(COWL_PROFILE)
	cowl.append(Vector3(_neck_top(cowl[-1].x) + NECK_MIN_RISE * _h, 0.0, 0.0))
	_lathe(Vector3.ZERO, cowl, _sides, color, COWL_JITTER)


## O boné sobre o capuz (a combinação da referência de Arthur): cúpula baixa de poucas facetas, acima do capuz e na cor da calça.
func _cap_over_hood() -> void:
	var shell: Array = SHELLS[LegacyInhabitantSpec.HeadCover.HOOD_CAP]
	var offset: Vector3 = shell[0]
	var scale: Vector3 = shell[1]
	var polar_deg: float = shell[2]
	_lathe(_head_c + offset * _head, _dome(_head * scale, polar_deg, CAP_RINGS_NEAR if _is_near else SHELL_RINGS_FAR), HOOD_SIDES if _is_near else _sides, _spec.bottom, JITTER)


## Com capuz a fita nasce debaixo do beiral do capelo, não do ombro (senão furava o capelo).
func _is_hooded() -> bool:
	return _spec.head_cover == LegacyInhabitantSpec.HeadCover.HOOD or _spec.head_cover == LegacyInhabitantSpec.HeadCover.HOOD_CAP


func _hood_color() -> Color:
	return _spec.top.darkened(HOOD_CAP_DARKEN)


func _wide_hat() -> void:
	var base: Vector3 = _head_c + Vector3.UP * _head.y * HAT_RISE
	if not _is_near:
		_kit.frustum(base, _head.x * HAT_BRIM.x, _head.x * HAT_CROWN.y, _head.y * (HAT_BRIM.z + HAT_CROWN.z) * HAT_FAR_HEIGHT, _sides, _spec.cover_color)
		return
	_kit.frustum(base, _head.x * HAT_BRIM.x, _head.x * HAT_BRIM.y, _head.y * HAT_BRIM.z, _sides, _spec.cover_color)
	_kit.frustum(base, _head.x * HAT_CROWN.x, _head.x * HAT_CROWN.y, _head.y * HAT_CROWN.z, _sides, _spec.cover_color)
	_kit.frustum(base, _head.x * HAT_CROWN.x * 1.02, _head.x * HAT_CROWN.x * 1.0, _head.y * HAT_BAND, _sides, _spec.trim, 0.0, false)


## O rosto: olhos pontuais, sobrancelhas, nariz rosado, boca de sorriso curto e duas bochechas rosadas.
func _face() -> void:
	var blush: Color = _spec.skin.lerp(BLUSH, CHEEK_BLUSH)
	for side: float in [-1.0, 1.0]:
		_patch(Vector2(side * EYE_SPOT.x, EYE_SPOT.y), EYE_HALF, FACE_DARK)
		_patch(Vector2(side * CHEEK_SPOT.x, CHEEK_SPOT.y), CHEEK_HALF, blush, CHEEK_SIDES, CHEEK_BULGE)
		_strip(Vector2(side * BROW_INNER.x, BROW_INNER.y), Vector2(side * BROW_OUTER.x, BROW_OUTER.y), BROW_THICK, _spec.hair.darkened(BROW_DARKEN))
		_strip(Vector2(side * MOUTH_CORNER.x, MOUTH_CORNER.y), MOUTH_CENTER, MOUTH_THICK, MOUTH_COLOR)
	var nose: Vector3 = _surface_point(NOSE_SPOT, 0.0)
	_tube(nose, nose + Vector3.FORWARD * NOSE_SIZE.y * _head.x, Vector2(NOSE_SIZE.x * _head.x, 0.0), 5, _spec.skin.lerp(BLUSH, NOSE_BLUSH), Vector3.UP)


func _accessory(kind: StringName) -> void:
	match kind:
		&"satchel":
			_satchel()
		&"coin_pouch":
			var y: float = POUCH_SPOT.x * _h
			var radius: float = POUCH_RADIUS * _h
			_kit.blob(_on_body(_radius_at(y) * POUCH_SPOT.y, y, radius * 0.6), Vector3(radius, radius * 1.15, radius), Vector3i(3, 6, 5), 0.12, POUCH)
		&"apron":
			_band(APRON_SPANS, 5, LINEN, FRONT_ARC)
		&"basket":
			_basket()
		&"sack":
			_sack()
		&"lantern":
			_lantern()
		_:
			_pole(kind)


func _satchel() -> void:
	var y: float = SATCHEL_SPOT.x * _h
	var size: Vector3 = SATCHEL_SIZE * _h
	var bag: Vector3 = _on_body(-_radius_at(y) * SATCHEL_SPOT.y, y, size.z * 0.5)
	_kit.box(bag, size, WOOD, SATCHEL_YAW)
	var flap_size: Vector3 = Vector3(size.x * 1.04, size.y * FLAP_HEIGHT, size.z * 1.14)
	var flap: Vector3 = bag + Vector3.UP * (size.y - flap_size.y) * 0.5
	_kit.box(flap, flap_size, WOOD_DARK, SATCHEL_YAW)
	var front: Vector3 = Vector3.FORWARD.rotated(Vector3.UP, SATCHEL_YAW)
	var across: Vector3 = Vector3.RIGHT.rotated(Vector3.UP, SATCHEL_YAW) * size.x * CLASP.x
	var rise: Vector3 = Vector3.UP * size.y * CLASP.y
	var clasp: Vector3 = flap + Vector3.DOWN * flap_size.y * 0.35 + front * (flap_size.z * 0.5 + CLASP_LIFT_M)
	_kit.quad(clasp - across - rise, clasp + across - rise, clasp + across + rise, clasp - across + rise, STEEL, bag)
	var shoulder_y: float = (COWL_PROFILE[0].x if _is_hooded() else SHOULDER_Y) * _h
	var from: Vector3 = _on_body(_radius_at(shoulder_y) * 0.5, shoulder_y, STRAP_LIFT_M)
	var to: Vector3 = bag + Vector3.UP * size.y * 0.5
	var middle: Vector3 = _on_body((from.x + to.x) * 0.5, (from.y + to.y) * 0.5, STRAP_LIFT_M)
	_tube(from, middle, STRAP_RADII * _h, 4, LEATHER, Vector3.FORWARD, 0.4)
	_tube(middle, to, STRAP_RADII * _h, 4, LEATHER, Vector3.FORWARD, 0.4)


func _basket() -> void:
	var size: Vector3 = BASKET * _h
	var center: Vector3 = _carry()
	_kit.frustum(center - Vector3.UP * size.z * 0.5, size.x, size.y, size.z, _sides, WICKER)
	if not _is_near:
		return
	var rim: Vector3 = center + Vector3.UP * size.z * 0.5
	for side: float in [-1.0, 1.0]:
		_tube(rim + Vector3(side * size.y, 0.0, 0.0), rim + Vector3.UP * size.y * HANDLE_RISE, Vector2(HANDLE_RADIUS, HANDLE_RADIUS) * _h, 4, WOOD_DARK)
		_kit.blob(rim + Vector3(side * size.y * 0.4, size.y * 0.1, 0.0), Vector3(size.y, size.y, size.y) * 0.3, Vector3i(3, 5, 7), 0.1, APPLE)


func _sack() -> void:
	var radii: Vector3 = SACK * _h
	var center: Vector3 = _carry()
	_kit.blob(center, radii, Vector3i(4 if _is_near else 3, 7 if _is_near else 5, 11), 0.1, BURLAP)
	if _is_near:
		var neck: Vector3 = center + Vector3.UP * radii.y * 0.95
		_kit.frustum(neck, radii.x * 0.25, radii.x * 0.45, radii.x * 0.5, 6, BURLAP)
		_kit.frustum(neck + Vector3.UP * 0.005, radii.x * 0.3, radii.x * 0.3, radii.x * 0.14, 6, ROPE, 0.0, false)


func _lantern() -> void:
	var size: float = LANTERN_SIZE * _h
	var body: Vector3 = _hands[0] + Vector3.DOWN * LANTERN_DROP * _h
	_kit.box(body, Vector3(size, size * 1.3, size), GLASS)
	_kit.frustum(body + Vector3.UP * size * 0.65, size * 0.85, 0.0, size * 0.5, 4, DARK_METAL, PI / 4.0)
	_tube(_hands[0], body + Vector3.UP * size * 0.65, Vector2(HANDLE_RADIUS, HANDLE_RADIUS) * _h, 4, DARK_METAL)


func _pole(kind: StringName) -> void:
	if not POLES.has(kind):
		return
	var shape: Vector3 = POLES[kind]
	var grip: Vector3 = _hands[1]
	var top: Vector3 = Vector3(grip.x, shape.x * _h, grip.z)
	var tip: Vector3 = top + Vector3.UP * shape.z * _h
	_tube(Vector3(grip.x, 0.0, grip.z), top, Vector2(shape.y, shape.y) * _h, 5, WOOD_DARK)
	match kind:
		&"spear":
			_tube(top, tip, Vector2(BLADE_RADIUS * _h, 0.0), 4, STEEL, Vector3.FORWARD, BLADE_FLAT)
		&"guard_staff":
			_tube(top, tip, Vector2(CAP_RADIUS * _h, 0.0), 6, STEEL)
		_:
			if _is_near:
				_kit.blob(top, KNOB_RADII * _h, Vector3i(3, 5, 3), 0.1, WOOD)


## Escudo pequeno do tabardo (duas camadas planas, a de dentro mais clara) sobre o peito, no lugar do emblema que parecia um bolso.
func _shield() -> void:
	var half: float = SHIELD_HALF * _h
	var axis: Vector3 = Vector3(0.0, SHIELD_Y * _h, 0.0)
	for layer: int in 2:
		var size: float = half * (1.0 if layer == 0 else SHIELD_INNER)
		var lift: float = SHIELD_LIFT_M + SHIELD_LAYER_LIFT_M * layer
		var outline: Array[Vector3] = []
		for corner: Vector2 in SHIELD_OUTLINE:
			outline.append(_on_body(corner.x * size, axis.y + corner.y * size, lift))
		var color: Color = _spec.trim.darkened(SHIELD_EDGE_DARKEN) if layer == 0 else _spec.trim
		_kit.tri(outline[0], outline[1], outline[2], color, axis)
		_kit.tri(outline[0], outline[2], outline[4], color, axis)
		_kit.tri(outline[4], outline[2], outline[3], color, axis)


## Onde as mãos ficam: caídas ao lado da barriga, à frente segurando a carga, a direita na haste e a esquerda no lampião.
func _hand_targets() -> Array[Vector3]:
	var out: float = _r * HAND_IN_R
	var low: float = HAND_HEIGHT * _h
	var hands: Array[Vector3] = [Vector3(-out, low, 0.0), Vector3(out, low, 0.0)]
	if _spec.has_accessory(&"basket") or _spec.has_accessory(&"sack"):
		hands = [_carry() + Vector3.LEFT * CARRY_REACH * _h, _carry() + Vector3.RIGHT * CARRY_REACH * _h]
	for kind: StringName in POLES:
		if _spec.has_accessory(kind):
			hands[1] = Vector3(out, low + POLE_RAISE * _h, -POLE_FORWARD * _h)
	if _spec.has_accessory(&"lantern"):
		hands[0] = Vector3(-out, low + POLE_RAISE * _h, -LANTERN_FORWARD * _h)
	return hands


func _carry() -> Vector3:
	var y: float = CARRY_Y * _h
	return Vector3(0.0, y, -(_radius_at(y) * BODY_DEPTH + CARRY_OUT * _h))


## Altura em que o pescoço fecha: dentro da cabeça (a ponta some atrás do queixo) e nunca abaixo do último anel.
func _neck_top(last_ring_y: float) -> float:
	return maxf(_head_c.y - _head.y * NECK_DEPTH, last_ring_y + NECK_MIN_RISE * _h)


## Raio do manto na altura `y` (m), interpolado pelo perfil.
func _radius_at(y: float) -> float:
	for index: int in range(1, _profile.size()):
		var upper: Vector2 = _profile[index]
		if y <= upper.x * _h:
			var lower: Vector2 = _profile[index - 1]
			return lerpf(lower.y, upper.y, clampf(inverse_lerp(lower.x * _h, upper.x * _h, y), 0.0, 1.0)) * _r
	return _profile[-1].y * _r


## Ponto da frente do manto em (x, y), `lift` metros para fora.
func _on_body(x: float, y: float, lift: float) -> Vector3:
	var radius: float = _radius_at(y)
	var across: float = clampf(x / radius, -1.0, 1.0)
	return Vector3(x, y, -(radius * BODY_DEPTH * sqrt(1.0 - across * across) + lift))


## Ponto do rosto na frente do elipsoide da cabeça (`spot` em fração dos raios), `lift` (fração de rx) para fora.
func _surface_point(spot: Vector2, lift: float) -> Vector3:
	var depth: float = sqrt(maxf(1.0 - spot.x * spot.x - spot.y * spot.y, FACE_MIN_DEPTH))
	var local: Vector3 = Vector3(spot.x * _head.x, spot.y * _head.y, -depth * _head.z)
	return _head_c + local + local.normalized() * lift * _head.x


## Mancha de cor no rosto (olho, bochecha): um leque de PATCH_SIDES triângulos sobre a casca, com o meio mais saliente.
func _patch(spot: Vector2, half: Vector2, color: Color, sides: int = PATCH_SIDES, bulge: float = PATCH_BULGE) -> void:
	var center: Vector3 = _surface_point(spot, FACE_LIFT * bulge)
	for side: int in sides:
		var first: Vector2 = spot + Vector2(cos(TAU * side / sides) * half.x, sin(TAU * side / sides) * half.y)
		var second: Vector2 = spot + Vector2(cos(TAU * (side + 1) / sides) * half.x, sin(TAU * (side + 1) / sides) * half.y)
		_kit.tri(center, _surface_point(first, FACE_LIFT), _surface_point(second, FACE_LIFT), color, _head_c)


## Barra no rosto (sobrancelha, boca) entre dois pontos da face, com `thick` de meia espessura em y.
func _strip(from: Vector2, to: Vector2, thick: float, color: Color) -> void:
	var up: Vector2 = Vector2(0.0, thick)
	_kit.quad(_surface_point(from - up, FACE_LIFT), _surface_point(from + up, FACE_LIFT), _surface_point(to + up, FACE_LIFT), _surface_point(to - up, FACE_LIFT), color, _head_c)


func _rings_of(profile: Array[Vector2]) -> Array[Vector3]:
	var rings: Array[Vector3] = []
	for ring: Vector2 in profile:
		rings.append(Vector3(ring.x * _h, ring.y * _r, ring.y * _r * BODY_DEPTH))
	return rings


## Anéis de uma casca esférica de `from_deg` (0 = polo de cima) até `polar_deg`: (altura, raio em x, raio em z).
func _dome(radii: Vector3, polar_deg: float, rings: int, from_deg: float = 0.0) -> Array[Vector3]:
	var rows: Array[Vector3] = []
	for index: int in rings + 1:
		var polar: float = deg_to_rad(lerpf(from_deg, polar_deg, float(index) / rings))
		rows.append(Vector3(radii.y * cos(polar), radii.x * sin(polar), radii.z * sin(polar)))
	return rows


## Faixa que acompanha o manto (cinto, avental, painéis do tabardo): `spans` = (altura em fração de H, folga sobre o raio dele).
func _band(spans: Array[Vector2], sides: int, color: Color, arc: Vector2 = FULL_ARC) -> void:
	var rings: Array[Vector3] = []
	for span: Vector2 in spans:
		var radius: float = _radius_at(span.x * _h) * span.y
		rings.append(Vector3(span.x * _h, radius, radius * BODY_DEPTH))
	_lathe(Vector3.ZERO, rings, sides, color, 0.0, arc)


## Superfície de revolução: `rings` = (posição no eixo, raio em x, raio no outro eixo) a partir de `center`; o eixo é Y (altura e raio em z) ou, com `along_z`, Z (profundidade e raio em y); anel de raio 0 é um polo (leque de triângulos). `arc` (rad, 0 = +X; no eixo Y, -PI/2 = frente; no eixo Z, PI/2 = em cima) permite só um trecho do giro. Cada vértice é deslocado pelo hash (o mesmo vértice, sempre o mesmo valor).
func _lathe(center: Vector3, rings: Array[Vector3], sides: int, color: Color, jitter: float = 0.0, arc: Vector2 = FULL_ARC, along_z: bool = false) -> void:
	var inside: Vector3 = center + (Vector3.BACK if along_z else Vector3.UP) * (rings[0].x + rings[-1].x) * 0.5
	var salt: int = _seed + int(center.y * SALT_PER_M)
	var point: Callable = func(ring: int, side: int) -> Vector3:
		var row: Vector3 = rings[ring]
		var column: int = side % sides if arc == FULL_ARC else side
		var bump: float = 1.0 + jitter * (PlazaMeshKit.unit(salt + ring * RING_STRIDE + column, JITTER_CHANNEL) * 2.0 - 1.0)
		var angle: float = lerpf(arc.x, arc.y, float(side) / sides)
		var across: Vector2 = Vector2(cos(angle) * row.y, sin(angle) * row.z) * bump
		return center + (Vector3(across.x, across.y, row.x) if along_z else Vector3(across.x, row.x, across.y))
	for ring: int in rings.size() - 1:
		for side: int in sides:
			var a: Vector3 = point.call(ring, side)
			var b: Vector3 = point.call(ring, side + 1)
			var c: Vector3 = point.call(ring + 1, side + 1)
			var d: Vector3 = point.call(ring + 1, side)
			if rings[ring].y < POLE_EPSILON:
				_facet(a, c, d, color, inside)
			elif rings[ring + 1].y < POLE_EPSILON:
				_facet(a, b, c, color, inside)
			else:
				_facet(a, b, c, color, inside)
				_facet(a, c, d, color, inside)


## Tubo (ou cone, com `radii.y` 0) de `from` a `to`, sem tampas; `hint` e `flat` giram e achatam a seção (fita, lâmina).
func _tube(from: Vector3, to: Vector3, radii: Vector2, sides: int, color: Color, hint: Vector3 = Vector3.FORWARD, flat: float = 1.0) -> void:
	var axis: Vector3 = (to - from).normalized()
	var wide: Vector3 = axis.cross(hint).normalized()
	var deep: Vector3 = axis.cross(wide) * flat
	var inside: Vector3 = (from + to) * 0.5
	for side: int in sides:
		var first: Vector3 = wide * cos(TAU * (side + 0.5) / sides) + deep * sin(TAU * (side + 0.5) / sides)
		var second: Vector3 = wide * cos(TAU * (side + 1.5) / sides) + deep * sin(TAU * (side + 1.5) / sides)
		_facet(from + first * radii.x, from + second * radii.x, to + second * radii.y, color, inside)
		if radii.y > 0.0:
			_facet(from + first * radii.x, to + second * radii.y, to + first * radii.y, color, inside)


## Triângulo de cor puxada para a luz rebatida (BOUNCE) se a face aponta para baixo; a normal vira para fora do ponto `inside`, como no PlazaMeshKit.
func _facet(a: Vector3, b: Vector3, c: Vector3, color: Color, inside: Vector3) -> void:
	var normal: Vector3 = (c - a).cross(b - a).normalized()
	if normal.dot(a - inside) < 0.0:
		normal = -normal
	_kit.tri(a, b, c, color.lerp(BOUNCE_COLOR, BOUNCE * maxf(-normal.y, 0.0)), inside)
