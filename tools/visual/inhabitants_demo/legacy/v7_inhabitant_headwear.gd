class_name V7InhabitantHeadwear
extends RefCounted
## [v7 CONGELADA, só para a cena de comparação] Coberturas da cabeça (ART-9d, protótipo isolado, só apresentação): capuz grosso com aro e rabo, boné de roda (sozinho ou por cima do capuz), chapéu de aba larga do comerciante e elmo do guarda com nasal, bochechas, crista de fio ou penacho. Tudo loftado e em fração dos raios da cabeça. De longe (LOD 1 e 2) vira uma casca simples com a cor e a silhueta da peça.

const HOOD_ROWS: Array[Vector4] = [Vector4(-0.52, 0.96, 0.98, 2.4), Vector4(-0.42, 1.14, 1.16, 2.4), Vector4(-0.25, 1.2, 1.22, 2.4), Vector4(0.1, 1.24, 1.27, 2.3), Vector4(0.55, 1.12, 1.16, 2.3), Vector4(0.95, 0.8, 0.84, 2.3), Vector4(1.2, 0.35, 0.4, 2.3), Vector4(1.3, 0.0, 0.0, 2.3)]
const HOOD_RIM_BANDS: int = 2
const HOOD_RIM_DARKEN: float = 0.2
## Meio ângulo (rad) do arco do capuz depois da horizontal: deixa o queixo livre (a mandíbula nunca fica sob pano escuro).
const HOOD_OPEN: float = 0.38
const HOOD_SIDES: int = 10
const HOOD_FAR_SHELL: Array[Vector3] = [Vector3(0.0, 0.06, 0.2), Vector3(1.13, 1.1, 1.1)]
const HOOD_FAR_DEG: float = 126.0
## Rabo do capuz: saída (fração dos raios da cabeça), altura da ponta (fração de H) e raios (largura e espessura, fração de rx) da base e da ponta.
const TAIL_FROM: Vector3 = Vector3(0.0, -0.1, 1.0)
const TAIL_TO_Y: float = 0.5
const TAIL_BASE: Vector2 = Vector2(0.28, 0.1)
const TAIL_TIP: Vector2 = Vector2(0.03, 0.02)
## Bonés: lugar do centro, raios (fração dos da cabeça) e polar máximo (graus) do boné de roda e do boné sobre o capuz.
const CAP: Array[Vector3] = [Vector3(0.0, 0.5, 0.04), Vector3(1.06, 0.72, 1.08)]
const CAP_DEG: float = 100.0
const CAP_ON_HOOD: Array[Vector3] = [Vector3(0.0, 0.8, 0.3), Vector3(1.12, 0.62, 1.06)]
const CAP_ON_HOOD_DEG: float = 105.0
const POM_RADIUS: float = 0.13
## Chapéu largo: base acima do centro da cabeça (fração de ry), aba (altura e raio por anel em fração de ry e rx), copa (altura e raio por anel) e escala da copa.
const HAT_RISE: float = 0.4
const BRIM: Array[Vector2] = [Vector2(0.07, 1.02), Vector2(0.1, 2.3), Vector2(0.03, 2.32), Vector2(0.0, 1.05)]
const CROWN: Array[Vector2] = [Vector2(0.02, 1.0), Vector2(0.22, 0.98), Vector2(0.5, 0.94), Vector2(0.78, 0.8), Vector2(0.98, 0.45), Vector2(1.06, 0.0)]
const CROWN_HEIGHT: float = 0.78
const BRIM_UNDER_DARKEN: float = 0.22
## Elmo: lugar do centro, raios e polar máximo (graus); bandas de aro; nasal e bochechas (fração dos raios); crista (fio ou penacho).
const HELM: Array[Vector3] = [Vector3(0.0, 0.5, 0.0), Vector3(1.08, 0.75, 1.1)]
const HELM_DEG: float = 98.0
const NASAL_Y: Vector2 = Vector2(0.4, -0.18)
const NASAL_HALF: float = 0.045
const NASAL_LIFT: float = 0.1
const CHEEK_PLATE: Vector4 = Vector4(0.96, 0.3, -0.25, 0.14)
const RIDGE_DEG: Vector2 = Vector2(-80.0, 55.0)
const RIDGE_HEIGHT: float = 0.26
const RIDGE_SEGMENTS: int = 6
const PLUME_RED: Color = Color("B83A32")
const PLUME: Array[Vector4] = [Vector4(0.0, 0.0, 0.0, 0.16), Vector4(0.0, 0.34, 0.25, 0.24), Vector4(0.0, 0.36, 0.72, 0.21), Vector4(0.0, -0.1, 1.15, 0.05)]

var _rig: V7InhabitantRig
var _shapes: V7InhabitantShapes


func _init(rig: V7InhabitantRig) -> void:
	_rig = rig
	_shapes = rig.shapes


func build() -> void:
	match _rig.spec.head_cover:
		V7InhabitantSpec.HeadCover.HOOD:
			_hood(_rig.spec.cover_color)
		V7InhabitantSpec.HeadCover.HOOD_CAP:
			_hood(V7InhabitantClothes.hood_color(_rig.spec))
			_cap(CAP_ON_HOOD, CAP_ON_HOOD_DEG, _rig.spec.bottom, false)
		V7InhabitantSpec.HeadCover.CAP:
			_cap(CAP, CAP_DEG, _rig.spec.cover_color, true)
		V7InhabitantSpec.HeadCover.WIDE_HAT:
			_wide_hat()
		V7InhabitantSpec.HeadCover.OPEN_HELM:
			_helm()


func _bands(near: int, far: int) -> int:
	return near if _rig.is_near else (near - 1 if _rig.lod == V7InhabitantRig.LOD_MID else far)


## Capuz grosso: tigela aberta para a frente (aro grosso e mais escuro em volta do rosto, arco que deixa o queixo livre) mais o rabo caído nas costas; de longe, uma casca.
func _hood(color: Color) -> void:
	var head: Vector3 = _rig.head_r
	if not _rig.is_near:
		var offset: Vector3 = HOOD_FAR_SHELL[0]
		var scale: Vector3 = HOOD_FAR_SHELL[1]
		_shapes.loft(V7InhabitantShapes.y_frame(_rig.head_c + offset * head), V7InhabitantShapes.dome(head * scale, 0.0, HOOD_FAR_DEG, _bands(4, 2)), _rig.sides, color, 0.015)
		return
	var rows: Array[Vector4] = []
	for row: Vector4 in HOOD_ROWS:
		rows.append(Vector4(row.x * head.z, row.y * head.x, row.z * head.y, row.w))
	var rim: Color = color.darkened(HOOD_RIM_DARKEN)
	var arc: Vector2 = Vector2(-PI - HOOD_OPEN, HOOD_OPEN)
	_shapes.loft(V7InhabitantShapes.z_frame(_rig.head_c), rows, HOOD_SIDES, color, 0.015, arc, PackedVector2Array(), func(ring: int, _side: int) -> Color: return rim if ring < HOOD_RIM_BANDS else color)
	var from: Vector3 = _rig.head_c + TAIL_FROM * head
	var tip_y: float = TAIL_TO_Y * _rig.h
	var to: Vector3 = Vector3(0.0, tip_y, _rig.shift_at(tip_y).y + _rig.row_at(tip_y).z * 0.95 + 0.03 * _rig.h)
	_shapes.limb(from, to, TAIL_BASE * head.x, TAIL_TIP * head.x, 4, color, 2, 0.1)


## Boné de roda: cúpula com a borda virada na cor de apoio e, no sem-capuz, um pompom.
func _cap(shell: Array[Vector3], polar_deg: float, color: Color, has_pom: bool) -> void:
	var head: Vector3 = _rig.head_r
	var center: Vector3 = _rig.head_c + shell[0] * head
	var bands: int = _bands(4, 2)
	var rim: Color = _rig.spec.trim
	var rows: Array[Vector4] = V7InhabitantShapes.dome(shell[1] * head, 0.0, polar_deg, bands)
	_shapes.loft(V7InhabitantShapes.y_frame(center), rows, _rig.sides, color, 0.015, V7InhabitantShapes.FULL_ARC, PackedVector2Array(), func(ring: int, _side: int) -> Color: return rim if ring == bands - 1 and _rig.lod != V7InhabitantRig.LOD_FAR else color)
	if has_pom and _rig.is_near:
		_shapes.ball(center + Vector3(0.0, shell[1].y * head.y * 1.02, 0.0), Vector3(POM_RADIUS, POM_RADIUS, POM_RADIUS) * head.x, 2, 6, rim, 0.05)


## Chapéu largo: aba de borda levantada (embaixo mais escura), copa de ombros caídos e a fita de apoio; de longe, um só sólido.
func _wide_hat() -> void:
	var head: Vector3 = _rig.head_r
	var base: Vector3 = _rig.head_c + Vector3(0.0, HAT_RISE * head.y, 0.0)
	var color: Color = _rig.spec.cover_color
	var ribbon: Color = _rig.spec.trim
	if _rig.lod == V7InhabitantRig.LOD_FAR:
		var solid: Array[Vector4] = [Vector4(0.0, head.x * BRIM[1].y, head.z * BRIM[1].y, 2.2), Vector4(0.1 * head.y, head.x, head.z, 2.2), Vector4((0.1 + CROWN_HEIGHT * 0.8) * head.y, 0.0, 0.0, 2.2)]
		_shapes.loft(V7InhabitantShapes.y_frame(base), solid, _rig.sides, color)
		return
	var brim: Array[Vector4] = []
	for ring: Vector2 in BRIM:
		brim.append(Vector4(ring.x * head.y, ring.y * head.x, ring.y * head.z, 2.4))
	var under: Color = color.darkened(BRIM_UNDER_DARKEN)
	var brim_rows: Array[Vector4] = brim
	var keep: Array[int] = [0, 1, 2, 3, 4, 5]
	if not _rig.is_near:
		brim_rows = [brim[0], brim[1], brim[3]]
		keep = [0, 2, 4, 5]
	_shapes.loft(V7InhabitantShapes.y_frame(base), brim_rows, _rig.sides, color, 0.0, V7InhabitantShapes.FULL_ARC, PackedVector2Array(), func(ring: int, _side: int) -> Color: return under if ring == 2 and _rig.is_near else color)
	var crown: Array[Vector4] = []
	for index: int in keep:
		var ring: Vector2 = CROWN[index]
		crown.append(Vector4(ring.x * CROWN_HEIGHT * head.y, ring.y * head.x, ring.y * head.z, 2.2))
	_shapes.loft(V7InhabitantShapes.y_frame(base), crown, _rig.sides, color, 0.012, V7InhabitantShapes.FULL_ARC, PackedVector2Array(), func(ring: int, _side: int) -> Color: return ribbon if ring == 0 else color)


## Elmo aberto: cúpula de aço com o aro de ouro, nasal, bochechas e a crista; de longe, só a cúpula e uma bola de crista.
func _helm() -> void:
	var head: Vector3 = _rig.head_r
	var center: Vector3 = _rig.head_c + HELM[0] * head
	var bands: int = _bands(4, 2)
	var steel: Color = _rig.spec.cover_color
	var gold: Color = _rig.spec.trim
	var radii: Vector3 = HELM[1] * head
	var rows: Array[Vector4] = V7InhabitantShapes.dome(radii, 0.0, HELM_DEG, bands)
	_shapes.loft(V7InhabitantShapes.y_frame(center), rows, _rig.sides, steel, 0.012, V7InhabitantShapes.FULL_ARC, PackedVector2Array(), func(ring: int, _side: int) -> Color: return gold if ring == bands - 1 and _rig.lod != V7InhabitantRig.LOD_FAR else steel)
	if not _rig.is_near:
		_crest_ball(center, radii)
		return
	_shapes.ribbon([_rig.face_point(Vector2(0.0, NASAL_Y.x), NASAL_LIFT * head.x), _rig.face_point(Vector2(0.0, NASAL_Y.y), NASAL_LIFT * head.x * 1.4)], Vector3(NASAL_HALF * head.x, 0.0, 0.0), steel.darkened(0.1), _rig.head_c)
	for side: float in [-1.0, 1.0]:
		var top: Vector3 = _rig.head_c + Vector3(side * CHEEK_PLATE.x * head.x, CHEEK_PLATE.y * head.y, -0.1 * head.z)
		var bottom: Vector3 = _rig.head_c + Vector3(side * CHEEK_PLATE.x * 0.94 * head.x, CHEEK_PLATE.z * head.y, -0.16 * head.z)
		_shapes.limb(top, bottom, Vector2(CHEEK_PLATE.w * head.x, 0.04 * head.x), Vector2(CHEEK_PLATE.w * head.x * 0.7, 0.035 * head.x), 4, steel.darkened(0.06), 1, 0.0, Vector3.RIGHT)
	if _rig.spec.crest == V7InhabitantSpec.Crest.RIDGE:
		_ridge(center, radii, gold)
	elif _rig.spec.crest == V7InhabitantSpec.Crest.PLUME:
		_plume(center + Vector3(0.0, radii.y, 0.0), radii)


## Crista de fio: uma aleta fina que corre da testa à nuca por cima da cúpula.
func _ridge(center: Vector3, radii: Vector3, color: Color) -> void:
	var base: Array[Vector3] = []
	var top: Array[Vector3] = []
	for index: int in RIDGE_SEGMENTS + 1:
		var polar: float = deg_to_rad(lerpf(RIDGE_DEG.x, RIDGE_DEG.y, float(index) / RIDGE_SEGMENTS))
		var point: Vector3 = center + Vector3(0.0, radii.y * cos(polar), -radii.z * sin(polar)) * 1.01
		base.append(point)
		top.append(point + Vector3(0.0, RIDGE_HEIGHT * _rig.head_r.y * cos(polar * 0.9), 0.0))
	for side: float in [-1.0, 0.0, 1.0]:
		var offset: Vector3 = Vector3(side * 0.025 * _rig.head_r.x, 0.0, 0.0)
		for index: int in RIDGE_SEGMENTS:
			if side == 0.0:
				_shapes.quad(top[index] - Vector3(0.025 * _rig.head_r.x, 0.0, 0.0), top[index] + Vector3(0.025 * _rig.head_r.x, 0.0, 0.0), top[index + 1] + Vector3(0.025 * _rig.head_r.x, 0.0, 0.0), top[index + 1] - Vector3(0.025 * _rig.head_r.x, 0.0, 0.0), color, center + Vector3(0.0, -1.0, 0.0))
			else:
				_shapes.quad(base[index] + offset, base[index + 1] + offset, top[index + 1] + offset, top[index] + offset, color, center + Vector3(-side, 0.0, 0.0))


## Penacho vermelho: uma pincelada curva (pontos que sobem da cúpula e caem para trás, de seção que afina) sobre um soquete de aço, com bolas nas juntas.
func _plume(top: Vector3, radii: Vector3) -> void:
	var head_x: float = _rig.head_r.x
	_shapes.ball(top, Vector3(0.1, 0.07, 0.1) * head_x, 2, 6, _rig.spec.cover_color.darkened(0.15), 0.03)
	var stops: Array[Vector3] = []
	var widths: Array[float] = []
	for stop: Vector4 in PLUME:
		stops.append(top + Vector3(stop.x * radii.x, stop.y * radii.y, stop.z * radii.z))
		widths.append(stop.w * head_x)
	for index: int in stops.size() - 1:
		_shapes.limb(stops[index], stops[index + 1], Vector2(widths[index], widths[index] * 0.7), Vector2(widths[index + 1], widths[index + 1] * 0.7), 6, PLUME_RED, 1, 0.1, Vector3.RIGHT)
		if index > 0:
			_shapes.ball(stops[index], Vector3(widths[index], widths[index], widths[index]) * 0.95, 2, 6, PLUME_RED, 0.05)


func _crest_ball(center: Vector3, radii: Vector3) -> void:
	if _rig.spec.crest == V7InhabitantSpec.Crest.NONE:
		return
	var radius: float = 0.16 * _rig.head_r.x
	_shapes.ball(center + Vector3(0.0, radii.y * 0.95, radii.z * 0.35), Vector3(radius, radius * 1.4, radius * 2.2), 2, 4, PLUME_RED if _rig.spec.crest == V7InhabitantSpec.Crest.PLUME else _rig.spec.trim, 0.0)
