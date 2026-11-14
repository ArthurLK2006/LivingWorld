class_name InhabitantShapes
extends RefCounted
## Formas orgânicas dos habitantes (ART-9d, protótipo isolado, só apresentação): superfícies LOFTADAS (cada anel é uma seção de superelipse com o próprio raio, então sino, pera e cabaça saem do perfil, não de cone nem de cilindro), membros com barriga, bolas, fitas e folhas, tudo facetado e com cor por vértice pelo PlazaMeshKit (normal plana por triângulo). A pequena assimetria vem de hash de inteiros: o mesmo vértice sai sempre igual, nada de sorteio.

const FULL_ARC: Vector2 = Vector2(0.0, TAU)
## Giro da seção (rad, 0 = +X) que olha para a frente do habitante (-Z) e para trás (+Z).
const FRONT_ANGLE: float = -PI / 2.0
const BACK_ANGLE: float = PI / 2.0
const JITTER_CHANNEL: int = 64
const RING_STRIDE: int = 61
const SERIAL_STRIDE: int = 7919
const POLE_EPSILON: float = 0.0005
## Luz rebatida do chão pintada nos vértices: as faces voltadas para baixo clareiam rumo à areia quente, até a fração BOUNCE.
const BOUNCE: float = 0.7
const BOUNCE_COLOR: Color = Color("F4DDB0")
## Oclusão ambiente barata (como a do PlazaMeshKit): a base das peças escurece e o topo clareia até SHADE_HEIGHT_M. Vértices a menos de 0,5 mm são o mesmo ponto na pele suave.
const SHADE_AMOUNT: float = 0.28
const SHADE_HEIGHT_M: float = 3.0
const WELD_SCALE: float = 2000.0

## Pele: com `soft` ligado os triângulos desenhados ganham normais SUAVIZADAS (média dos triângulos que dividem o vértice), um híbrido macio na pele e facetado no tecido; desligado, normal plana por triângulo.
var soft: bool = false
var _salt: int
var _serial: int = 0
var _points: PackedVector3Array = PackedVector3Array()
var _colors: PackedColorArray = PackedColorArray()
var _normals: PackedVector3Array = PackedVector3Array()
var _softness: PackedByteArray = PackedByteArray()
var _sums: Dictionary[Vector3i, Vector3] = {}


func _init(salt: int) -> void:
	_salt = salt


## Moldura de um loft ao longo de Y (altura), girada `yaw` em torno de Y.
static func y_frame(origin: Vector3, yaw: float = 0.0) -> Transform3D:
	return Transform3D(Basis(Vector3.UP, yaw), origin)


## Moldura de um loft ao longo de Z (da frente para trás); o Z local aponta para BAIXO, então o giro -PI/2 da seção aponta para CIMA.
static func z_frame(origin: Vector3, yaw: float = 0.0) -> Transform3D:
	return Transform3D(Basis(Vector3.UP, yaw) * Basis(Vector3.RIGHT, Vector3.BACK, Vector3.DOWN), origin)


## Ponto da seção de superelipse no giro `angle`: expoente `n` = 2 é a elipse; maior deixa os cantos mais cheios (ombros de trapézio).
static func section(angle: float, radius_x: float, radius_z: float, n: float) -> Vector2:
	var cosine: float = cos(angle)
	var sine: float = sin(angle)
	var power: float = 2.0 / n
	return Vector2(signf(cosine) * pow(absf(cosine), power) * radius_x, signf(sine) * pow(absf(sine), power) * radius_z)


## Anéis de uma cúpula (de `from_deg`, 0 = polo, até `to_deg`): (posição no eixo, raio em x, raio em z, expoente).
static func dome(radii: Vector3, from_deg: float, to_deg: float, bands: int, n: float = 2.2) -> Array[Vector4]:
	var rows: Array[Vector4] = []
	for index: int in bands + 1:
		var polar: float = deg_to_rad(lerpf(from_deg, to_deg, float(index) / bands))
		rows.append(Vector4(radii.y * cos(polar), radii.x * sin(polar), radii.z * sin(polar), n))
	return rows


## Triângulo com a normal para fora de `inside` e luz rebatida nas faces voltadas para baixo.
func tri(a: Vector3, b: Vector3, c: Vector3, color: Color, inside: Vector3) -> void:
	var normal: Vector3 = (c - a).cross(b - a)
	var second: Vector3 = b
	var third: Vector3 = c
	if normal.dot(a - inside) < 0.0:
		second = c
		third = b
		normal = -normal
	var flat: Vector3 = normal.normalized()
	var lit: Color = color.lerp(BOUNCE_COLOR, BOUNCE * maxf(-flat.y, 0.0))
	for point: Vector3 in [a, second, third]:
		_points.append(point)
		_colors.append(lit.darkened(SHADE_AMOUNT * (1.0 - clampf(point.y / SHADE_HEIGHT_M, 0.0, 1.0))))
		_normals.append(flat)
		_softness.append(1 if soft else 0)
		if soft:
			var key: Vector3i = _weld_key(point)
			_sums[key] = _sums.get(key, Vector3.ZERO) + normal


## Caixa de tamanho `size` centrada em `center` (12 triângulos), para o bloco de botas de longe.
func box(center: Vector3, size: Vector3, color: Color) -> void:
	var half: Vector3 = size * 0.5
	var corners: Array[Vector3] = []
	for index: int in 8:
		corners.append(center + Vector3(half.x if (index & 1) != 0 else -half.x, half.y if (index & 2) != 0 else -half.y, half.z if (index & 4) != 0 else -half.z))
	for face: int in 6:
		var quad_corners: PackedInt32Array = PlazaMeshKit.BOX_QUADS.slice(face * 4, face * 4 + 4)
		quad(corners[quad_corners[0]], corners[quad_corners[1]], corners[quad_corners[2]], corners[quad_corners[3]], color, center)


## A malha de tudo o que foi desenhado: UMA superfície com `material`, normais suaves onde `soft` estava ligado e planas no resto.
func finish(material: Material) -> ArrayMesh:
	for index: int in _points.size():
		if _softness[index] == 1:
			var smooth: Vector3 = _sums[_weld_key(_points[index])].normalized()
			if smooth != Vector3.ZERO:
				_normals[index] = smooth
	var mesh: ArrayMesh = ArrayMesh.new()
	if _points.is_empty():
		return mesh
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = _points
	arrays[Mesh.ARRAY_NORMAL] = _normals
	arrays[Mesh.ARRAY_COLOR] = _colors
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh.surface_set_material(0, material)
	return mesh


static func _weld_key(point: Vector3) -> Vector3i:
	return Vector3i(roundi(point.x * WELD_SCALE), roundi(point.y * WELD_SCALE), roundi(point.z * WELD_SCALE))


func quad(a: Vector3, b: Vector3, c: Vector3, d: Vector3, color: Color, inside: Vector3) -> void:
	tri(a, b, c, color, inside)
	tri(a, c, d, color, inside)


## Superfície loftada ao longo do eixo Y de `frame`: cada anel é (posição no eixo, raio em x, raio em z, expoente); `shifts` (um por anel, opcional) desloca o centro do anel em (x, z); anel de raio 0 é um polo (dois anéis iguais, o segundo de raio 0, fecham uma tampa plana); `arc` permite só um trecho do giro; `tint(anel, setor)` escolhe a cor de cada faceta; `jitter` é a assimetria por hash (fração do raio).
func loft(frame: Transform3D, rings: Array[Vector4], sides: int, color: Color, jitter: float = 0.0, arc: Vector2 = FULL_ARC, shifts: PackedVector2Array = PackedVector2Array(), tint: Callable = Callable()) -> void:
	_serial += 1
	var salt: int = _salt + _serial * SERIAL_STRIDE
	var is_closed: bool = arc == FULL_ARC
	var shift_of: Callable = func(ring: int) -> Vector2:
		return shifts[ring] if ring < shifts.size() else Vector2.ZERO
	var point: Callable = func(ring: int, side: int) -> Vector3:
		var row: Vector4 = rings[ring]
		var column: int = side % sides if is_closed else side
		var bump: float = 1.0 + jitter * (PlazaMeshKit.unit(salt + ring * RING_STRIDE + column, JITTER_CHANNEL) * 2.0 - 1.0)
		var shift: Vector2 = shift_of.call(ring)
		var across: Vector2 = section(lerpf(arc.x, arc.y, float(side) / sides), row.y * bump, row.z * bump, row.w)
		return frame * Vector3(across.x + shift.x, row.x, across.y + shift.y)
	for ring: int in rings.size() - 1:
		var from_shift: Vector2 = shift_of.call(ring)
		var to_shift: Vector2 = shift_of.call(ring + 1)
		var inside: Vector3 = frame * Vector3((from_shift.x + to_shift.x) * 0.5, (rings[ring].x + rings[ring + 1].x) * 0.5, (from_shift.y + to_shift.y) * 0.5)
		for side: int in sides:
			var a: Vector3 = point.call(ring, side)
			var b: Vector3 = point.call(ring, side + 1)
			var c: Vector3 = point.call(ring + 1, side + 1)
			var d: Vector3 = point.call(ring + 1, side)
			var paint: Color = color
			if tint.is_valid():
				paint = tint.call(ring, side)
			if rings[ring].y < POLE_EPSILON:
				tri(a, c, d, paint, inside)
			elif rings[ring + 1].y < POLE_EPSILON:
				tri(a, b, c, paint, inside)
			else:
				tri(a, b, c, paint, inside)
				tri(a, c, d, paint, inside)


## Membro de `from` a `to` com seção oval (raios em x e z nas duas pontas), `rings` faixas e `belly` (fração) de barriga no meio; `hint` gira a seção (o raio z fica na direção de `hint`), `n` arredonda ou quadra.
func limb(from: Vector3, to: Vector3, radii_from: Vector2, radii_to: Vector2, sides: int, color: Color, rings: int = 2, belly: float = 0.0, hint: Vector3 = Vector3.FORWARD, n: float = 2.0) -> void:
	var axis: Vector3 = to - from
	var length: float = axis.length()
	if length < POLE_EPSILON:
		return
	var up: Vector3 = axis / length
	var wide: Vector3 = up.cross(hint).normalized()
	var rows: Array[Vector4] = []
	for index: int in rings + 1:
		var t: float = float(index) / rings
		var swell: float = 1.0 + belly * sin(PI * t)
		rows.append(Vector4(length * t, lerpf(radii_from.x, radii_to.x, t) * swell, lerpf(radii_from.y, radii_to.y, t) * swell, n))
	loft(Transform3D(Basis(wide, up, wide.cross(up)), from), rows, sides, color)


## Elipsoide facetado (ombro, mão, nariz, bolsa): `bands` faixas de polo a polo e `sides` setores.
func ball(center: Vector3, radii: Vector3, bands: int, sides: int, color: Color, jitter: float = 0.04, yaw: float = 0.0) -> void:
	loft(y_frame(center, yaw), dome(radii, 0.0, 180.0, bands, 2.0), sides, color, jitter)


## Leque de triângulos de `center` sobre o contorno fechado `edge`.
func fan(center: Vector3, edge: Array[Vector3], color: Color, inside: Vector3) -> void:
	for index: int in edge.size():
		tri(center, edge[index], edge[(index + 1) % edge.size()], color, inside)


## Fita entre pontos consecutivos; cada ponto vira dois cantos (`point` mais e menos `spread`).
func ribbon(points: Array[Vector3], spread: Vector3, color: Color, inside: Vector3) -> void:
	for index: int in points.size() - 1:
		quad(points[index] - spread, points[index] + spread, points[index + 1] + spread, points[index + 1] - spread, color, inside)


## Folha plana de dois lados (flâmula): polígono convexo em leque a partir do primeiro ponto.
func sheet(points: Array[Vector3], color: Color) -> void:
	var normal: Vector3 = (points[1] - points[0]).cross(points[2] - points[0]).normalized()
	for index: int in range(1, points.size() - 1):
		tri(points[0], points[index], points[index + 1], color, points[0] + normal)
		tri(points[0], points[index], points[index + 1], color, points[0] - normal)
