class_name InhabitantHeadwear
extends RefCounted
## Coberturas da cabeça (ART-9d e 9e, protótipo isolado, só apresentação): capuz VOLUMOSO (casca grossa e lisa, aro de pano enrolado em volta do rosto, capelo largo e rabo caído com prega), boné de roda (sozinho ou por cima do capuz), chapéu de aba larga (com pena) e de palha tecida, e o elmo do guarda com nasal, bochechas e crista de fio ou penacho (o do recruta é grande demais; o penacho do capitão, maior). Lenço, boina e gorro de lã ficam em InhabitantHats. Tudo loftado e em fração dos raios da cabeça. De longe (LOD 1 e 2) vira uma casca simples com a cor e a silhueta da peça.

const HOOD_ROWS: Array[Vector4] = [Vector4(-0.85, 1.04, 1.06, 2.4), Vector4(-0.7, 1.28, 1.3, 2.4), Vector4(-0.42, 1.38, 1.42, 2.4), Vector4(-0.05, 1.4, 1.46, 2.3), Vector4(0.45, 1.28, 1.34, 2.3), Vector4(0.95, 0.92, 0.98, 2.3), Vector4(1.25, 0.45, 0.52, 2.3), Vector4(1.38, 0.0, 0.0, 2.3)]
const HOOD_RIM_BANDS: int = 2
const HOOD_RIM_DARKEN: float = 0.16
## Meio ângulo (rad) do arco do capuz depois da horizontal: deixa o queixo livre (a mandíbula nunca fica sob pano escuro).
const HOOD_OPEN: float = 0.38
const HOOD_SIDES: int = 12
const HOOD_FAR_SHELL: Array[Vector3] = [Vector3(0.0, 0.06, 0.2), Vector3(1.25, 1.2, 1.2)]
const HOOD_FAR_DEG: float = 126.0
## Aro enrolado em volta do rosto: posição no eixo (fração de rz), raios (fração de rx e ry), raio do tubo (fração de rx) e pontos do arco.
const HOOD_ROLL: Vector4 = Vector4(-0.7, 1.28, 1.3, 0.17)
const HOOD_ROLL_POINTS: int = 9
## Rabo do capuz: saída (fração dos raios da cabeça), altura da ponta (fração de H) e raios (largura e espessura, fração de rx) da base e da ponta.
const TAIL_FROM: Vector3 = Vector3(0.0, -0.1, 1.0)
const TAIL_TO_Y: float = 0.5
const TAIL_BASE: Vector2 = Vector2(0.4, 0.15)
const TAIL_TIP: Vector2 = Vector2(0.06, 0.04)
## Bonés: lugar do centro, raios (fração dos da cabeça) e polar máximo (graus) do boné de roda e do boné sobre o capuz.
const CAP: Array[Vector3] = [Vector3(0.0, 0.5, 0.04), Vector3(1.06, 0.72, 1.08)]
const CAP_DEG: float = 100.0
const CAP_ON_HOOD: Array[Vector3] = [Vector3(0.0, 0.8, 0.3), Vector3(1.12, 0.62, 1.06)]
const CAP_ON_HOOD_DEG: float = 105.0
const POM_RADIUS: float = 0.13
## Chapéu largo: base acima do centro da cabeça (fração de ry), aba (altura e raio por anel em fração de ry e rx), copa (altura e raio por anel) e escala da copa; palha: cor, aba maior e copa baixa.
const HAT_RISE: float = 0.4
const BRIM: Array[Vector2] = [Vector2(0.07, 1.02), Vector2(0.1, 1.7), Vector2(0.03, 1.72), Vector2(0.0, 1.05)]
const CROWN: Array[Vector2] = [Vector2(0.02, 1.0), Vector2(0.22, 0.98), Vector2(0.5, 0.94), Vector2(0.78, 0.8), Vector2(0.98, 0.45), Vector2(1.06, 0.0)]
const CROWN_HEIGHT: float = 0.78
const BRIM_UNDER_DARKEN: float = 0.22
const STRAW: Color = Color("D9B96A")
const STRAW_BRIM: float = 1.12
const STRAW_CROWN: float = 0.62
## Elmo: lugar do centro, raios e polar máximo (graus); quanto o elmo grande demais afunda (fração de ry por unidade a mais de escala); bandas de aro; nasal e bochechas (fração dos raios); crista (fio ou penacho).
const HELM: Array[Vector3] = [Vector3(0.0, 0.5, 0.0), Vector3(1.08, 0.75, 1.1)]
const HELM_DEG: float = 98.0
const HELM_SINK: float = 1.1
const NASAL_Y: Vector2 = Vector2(0.4, -0.18)
const NASAL_HALF: float = 0.045
const NASAL_LIFT: float = 0.1
const CHEEK_PLATE: Vector4 = Vector4(0.96, 0.3, -0.25, 0.14)
const RIDGE_DEG: Vector2 = Vector2(-80.0, 55.0)
const RIDGE_HEIGHT: float = 0.26
const RIDGE_SEGMENTS: int = 6
const PLUME_RED: Color = Color("B83A32")
const PLUME: Array[Vector4] = [Vector4(0.0, 0.0, 0.0, 0.16), Vector4(0.0, 0.34, 0.25, 0.24), Vector4(0.0, 0.36, 0.72, 0.21), Vector4(0.0, -0.1, 1.15, 0.05)]

var _rig: InhabitantRig
var _shapes: InhabitantShapes


func _init(rig: InhabitantRig) -> void:
	_rig = rig
	_shapes = rig.shapes


func build() -> void:
	var hats: InhabitantHats = InhabitantHats.new(_rig)
	match _rig.spec.head_cover:
		InhabitantSpec.HeadCover.HOOD:
			_hood(_rig.spec.cover_color)
		InhabitantSpec.HeadCover.HOOD_CAP:
			_hood(InhabitantClothes.hood_color(_rig.spec))
			_cap(CAP_ON_HOOD, CAP_ON_HOOD_DEG, _rig.spec.bottom, false)
		InhabitantSpec.HeadCover.CAP:
			_cap(CAP, CAP_DEG, _rig.spec.cover_color, true)
		InhabitantSpec.HeadCover.WIDE_HAT:
			_wide_hat(_rig.spec.cover_color, 1.0, 1.0, false)
			if _rig.spec.has_feather and _rig.is_near:
				hats.feather()
		InhabitantSpec.HeadCover.STRAW_HAT:
			_wide_hat(STRAW.lerp(_rig.spec.cover_color, 0.15), STRAW_BRIM, STRAW_CROWN, true)
		InhabitantSpec.HeadCover.OPEN_HELM:
			_helm()
		InhabitantSpec.HeadCover.SCARF:
			hats.kerchief()
		InhabitantSpec.HeadCover.BERET:
			hats.beret()
		InhabitantSpec.HeadCover.WOOL_CAP:
			hats.wool_cap()


func _bands(near: int, far: int) -> int:
	return near if _rig.is_near else (near - 1 if _rig.lod == InhabitantRig.LOD_MID else far)


## Capuz volumoso: tigela larga aberta para a frente (arco que deixa o queixo livre) com o aro de pano ENROLADO em volta do rosto e o rabo grosso caído nas costas com prega; de longe, uma casca.
func _hood(color: Color) -> void:
	var head: Vector3 = _rig.head_r
	if not _rig.is_near:
		var offset: Vector3 = HOOD_FAR_SHELL[0]
		var scale: Vector3 = HOOD_FAR_SHELL[1]
		_shapes.loft(InhabitantShapes.y_frame(_rig.head_c + offset * head), InhabitantShapes.dome(head * scale, 0.0, HOOD_FAR_DEG, _bands(4, 2)), _rig.sides, color, 0.015)
		return
	var rows: Array[Vector4] = []
	for row: Vector4 in HOOD_ROWS:
		rows.append(Vector4(row.x * head.z, row.y * head.x, row.z * head.y, row.w))
	var rim: Color = color.darkened(HOOD_RIM_DARKEN)
	var arc: Vector2 = Vector2(-PI - HOOD_OPEN, HOOD_OPEN)
	var frame: Transform3D = InhabitantShapes.z_frame(_rig.head_c)
	_shapes.loft(frame, rows, HOOD_SIDES, color, 0.015, arc, PackedVector2Array(), func(ring: int, _side: int) -> Color: return rim if ring < HOOD_RIM_BANDS else color)
	var tube: float = HOOD_ROLL.w * head.x
	var previous: Vector3 = Vector3.ZERO
	for index: int in HOOD_ROLL_POINTS:
		var angle: float = lerpf(arc.x, arc.y, float(index) / (HOOD_ROLL_POINTS - 1))
		var across: Vector2 = InhabitantShapes.section(angle, HOOD_ROLL.y * head.x, HOOD_ROLL.z * head.y, 2.4)
		var point: Vector3 = frame * Vector3(across.x, HOOD_ROLL.x * head.z, across.y)
		if index > 0:
			_shapes.limb(previous, point, Vector2(tube, tube), Vector2(tube, tube), 5, rim, 1)
		previous = point
	var from: Vector3 = _rig.head_c + TAIL_FROM * head
	var tip_y: float = TAIL_TO_Y * _rig.h
	var to: Vector3 = Vector3(0.0, tip_y, _rig.shift_at(tip_y).y + _rig.row_at(tip_y).z * 0.95 + 0.03 * _rig.h)
	_shapes.limb(from, to, TAIL_BASE * head.x, TAIL_TIP * head.x, 5, color, 3, 0.25)


## Boné de roda: cúpula com a borda virada na cor de apoio e, no sem-capuz, um pompom.
func _cap(shell: Array[Vector3], polar_deg: float, color: Color, has_pom: bool) -> void:
	var head: Vector3 = _rig.head_r
	var center: Vector3 = _rig.head_c + shell[0] * head
	var bands: int = _bands(4, 2)
	var rim: Color = _rig.spec.trim
	var rows: Array[Vector4] = InhabitantShapes.dome(shell[1] * head, 0.0, polar_deg, bands)
	_shapes.loft(InhabitantShapes.y_frame(center), rows, _rig.sides, color, 0.015, InhabitantShapes.FULL_ARC, PackedVector2Array(), func(ring: int, _side: int) -> Color: return rim if ring == bands - 1 and _rig.lod != InhabitantRig.LOD_FAR else color)
	if has_pom and _rig.is_near:
		_shapes.ball(center + Vector3(0.0, shell[1].y * head.y * 1.02, 0.0), Vector3(POM_RADIUS, POM_RADIUS, POM_RADIUS) * head.x, 2, 6, rim, 0.05)


## Chapéu largo (ou de palha tecida, de aba maior e copa baixa): aba de borda levantada (embaixo mais escura), copa de ombros caídos e a fita de apoio; de longe, um só sólido.
func _wide_hat(color: Color, brim_scale: float, crown_scale: float, is_woven: bool) -> void:
	var head: Vector3 = _rig.head_r
	var base: Vector3 = _rig.head_c + Vector3(0.0, HAT_RISE * head.y, 0.0)
	var ribbon: Color = _rig.spec.trim
	var crown_height: float = CROWN_HEIGHT * crown_scale
	if _rig.lod == InhabitantRig.LOD_FAR:
		var solid: Array[Vector4] = [Vector4(0.0, head.x * BRIM[1].y * brim_scale, head.z * BRIM[1].y * brim_scale, 2.2), Vector4(0.1 * head.y, head.x, head.z, 2.2), Vector4((0.1 + crown_height * 0.8) * head.y, 0.0, 0.0, 2.2)]
		_shapes.loft(InhabitantShapes.y_frame(base), solid, _rig.sides, color)
		return
	var brim: Array[Vector4] = []
	for ring: Vector2 in BRIM:
		var spread: float = ring.y * brim_scale if ring.y > 1.5 else ring.y
		brim.append(Vector4(ring.x * head.y, spread * head.x, spread * head.z, 2.4))
	var under: Color = color.darkened(BRIM_UNDER_DARKEN)
	var dark: Color = color.darkened(0.1)
	var brim_rows: Array[Vector4] = brim
	var keep: Array[int] = [0, 1, 2, 3, 4, 5]
	if not _rig.is_near:
		brim_rows = [brim[0], brim[1], brim[3]]
		keep = [0, 2, 4, 5]
	_shapes.loft(InhabitantShapes.y_frame(base), brim_rows, _rig.sides, color, 0.0, InhabitantShapes.FULL_ARC, PackedVector2Array(), func(ring: int, side: int) -> Color: return under if ring == 2 and _rig.is_near else (dark if is_woven and (ring + side) % 2 == 0 else color))
	var crown: Array[Vector4] = []
	for index: int in keep:
		var ring: Vector2 = CROWN[index]
		crown.append(Vector4(ring.x * crown_height * head.y, ring.y * head.x, ring.y * head.z, 2.2))
	_shapes.loft(InhabitantShapes.y_frame(base), crown, _rig.sides, color, 0.012, InhabitantShapes.FULL_ARC, PackedVector2Array(), func(ring: int, side: int) -> Color: return ribbon if ring == 0 else (dark if is_woven and (ring + side) % 2 == 0 else color))


## Elmo aberto: cúpula de aço com o aro de ouro, nasal, bochechas e a crista; o do recruta (escala maior) afunda até as sobrancelhas; de longe, só a cúpula e uma bola de crista.
func _helm() -> void:
	var head: Vector3 = _rig.head_r
	var grow: float = _rig.spec.helm_scale
	var center: Vector3 = _rig.head_c + HELM[0] * head - Vector3(0.0, (grow - 1.0) * HELM_SINK * head.y, 0.0)
	var bands: int = _bands(4, 2)
	var steel: Color = _rig.spec.cover_color
	var gold: Color = _rig.spec.trim
	var radii: Vector3 = HELM[1] * head * grow
	var rows: Array[Vector4] = InhabitantShapes.dome(radii, 0.0, HELM_DEG, bands)
	_shapes.loft(InhabitantShapes.y_frame(center), rows, _rig.sides, steel, 0.012, InhabitantShapes.FULL_ARC, PackedVector2Array(), func(ring: int, _side: int) -> Color: return gold if ring == bands - 1 and _rig.lod != InhabitantRig.LOD_FAR else steel)
	if not _rig.is_near:
		_crest_ball(center, radii)
		return
	_shapes.ribbon([_rig.face_point(Vector2(0.0, NASAL_Y.x), NASAL_LIFT * head.x), _rig.face_point(Vector2(0.0, NASAL_Y.y), NASAL_LIFT * head.x * 1.4)], Vector3(NASAL_HALF * head.x, 0.0, 0.0), steel.darkened(0.1), _rig.head_c)
	for side: float in [-1.0, 1.0]:
		var top: Vector3 = _rig.head_c + Vector3(side * CHEEK_PLATE.x * head.x, CHEEK_PLATE.y * head.y, -0.1 * head.z)
		var bottom: Vector3 = _rig.head_c + Vector3(side * CHEEK_PLATE.x * 0.94 * head.x, CHEEK_PLATE.z * head.y, -0.16 * head.z)
		_shapes.limb(top, bottom, Vector2(CHEEK_PLATE.w * head.x, 0.04 * head.x), Vector2(CHEEK_PLATE.w * head.x * 0.7, 0.035 * head.x), 4, steel.darkened(0.06), 1, 0.0, Vector3.RIGHT)
	if _rig.spec.crest == InhabitantSpec.Crest.RIDGE:
		_ridge(center, radii, gold)
	elif _rig.spec.crest == InhabitantSpec.Crest.PLUME:
		_plume(center + Vector3(0.0, radii.y, 0.0), radii * _rig.spec.plume_scale)


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
	var grow: float = _rig.spec.plume_scale
	_shapes.ball(top, Vector3(0.1, 0.07, 0.1) * head_x, 2, 6, _rig.spec.cover_color.darkened(0.15), 0.03)
	var stops: Array[Vector3] = []
	var widths: Array[float] = []
	for stop: Vector4 in PLUME:
		stops.append(top + Vector3(stop.x * radii.x, stop.y * radii.y, stop.z * radii.z))
		widths.append(stop.w * head_x * lerpf(1.0, grow, 0.5))
	for index: int in stops.size() - 1:
		_shapes.limb(stops[index], stops[index + 1], Vector2(widths[index], widths[index] * 0.7), Vector2(widths[index + 1], widths[index + 1] * 0.7), 6, PLUME_RED, 1, 0.1, Vector3.RIGHT)
		if index > 0:
			_shapes.ball(stops[index], Vector3(widths[index], widths[index], widths[index]) * 0.95, 2, 6, PLUME_RED, 0.05)


func _crest_ball(center: Vector3, radii: Vector3) -> void:
	if _rig.spec.crest == InhabitantSpec.Crest.NONE:
		return
	var radius: float = 0.16 * _rig.head_r.x * lerpf(1.0, _rig.spec.plume_scale, 0.6)
	_shapes.ball(center + Vector3(0.0, radii.y * 0.95, radii.z * 0.35), Vector3(radius, radius * 1.4, radius * 2.2), 2, 4, PLUME_RED if _rig.spec.crest == InhabitantSpec.Crest.PLUME else _rig.spec.trim, 0.0)
