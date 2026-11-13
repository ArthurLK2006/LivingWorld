class_name PlazaMeshKit
extends RefCounted
## Construtor de malhas FACETADAS da praça de mercado procedural, nascido na cena de teste de renderizadores (ARTE-F0) e promovido ao jogo na ART-1 (só apresentação, sem relação com a simulação): cada triângulo tem a própria normal plana
## (vértices duplicados por triângulo) e cor por vértice, sem textura. O sentido da face é corrigido por um ponto "de dentro" da forma, então cada forma só informa o centro.
## A variação (escala, giro, tom) vem de uma função de hash de inteiros: nenhum sorteio da engine (AGENTS 4.9), tudo reproduzível.

const MASK_32: int = 0xFFFFFFFF
const UNIT_DIVISOR: float = 4294967296.0
## Constante de 32 bits que espalha o índice antes do hash (razão áurea).
const INDEX_SPREAD: int = 0x9E3779B1
## Oclusão ambiente barata (guia visual, seção 5): a base das peças escurece e o topo clareia até SHADE_HEIGHT_M.
const SHADE_AMOUNT: float = 0.28
const SHADE_HEIGHT_M: float = 3.0
## Os 6 quadriláteros de uma caixa, como índices dos 8 cantos (bit 0 = x, bit 1 = y, bit 2 = z).
const BOX_QUADS: PackedInt32Array = [0, 2, 6, 4, 1, 3, 7, 5, 0, 1, 5, 4, 2, 3, 7, 6, 0, 1, 3, 2, 4, 5, 7, 6]
const BLOB_VARIANT_STRIDE: int = 1013
const BLOB_RING_STRIDE: int = 61
const BLOB_CHANNEL: int = 7919

## Desliga o escurecimento da base (o chão não leva a oclusão das peças).
var is_shaded: bool = true

var _surface: SurfaceTool = SurfaceTool.new()
var _pending: int = 0


func _init() -> void:
	_surface.begin(Mesh.PRIMITIVE_TRIANGLES)


## Hash de inteiros de 32 bits (Wang): o mesmo valor sempre dá o mesmo resultado, sem estado.
static func hash_int(value: int) -> int:
	var mixed: int = value & MASK_32
	mixed = ((mixed ^ 61) ^ (mixed >> 16)) & MASK_32
	mixed = (mixed + (mixed << 3)) & MASK_32
	mixed = mixed ^ (mixed >> 4)
	mixed = (mixed * 0x27D4EB2D) & MASK_32
	return (mixed ^ (mixed >> 15)) & MASK_32


## Número em [0, 1) para o par (índice, canal): canais diferentes dão sequências independentes.
static func unit(index: int, channel: int) -> float:
	return float(hash_int(index * INDEX_SPREAD + channel)) / UNIT_DIVISOR


static func between(index: int, channel: int, low: float, high: float) -> float:
	return lerpf(low, high, unit(index, channel))


## Um triângulo com normal plana virada para fora do ponto `inside`; a cor sai mais escura perto do chão.
func tri(a: Vector3, b: Vector3, c: Vector3, color: Color, inside: Vector3) -> void:
	var normal: Vector3 = (c - a).cross(b - a)
	var second: Vector3 = b
	var third: Vector3 = c
	if normal.dot(a - inside) < 0.0:
		second = c
		third = b
		normal = -normal
	normal = normal.normalized()
	for point: Vector3 in [a, second, third]:
		_surface.set_normal(normal)
		_surface.set_color(_shade(color, point.y))
		_surface.add_vertex(point)
	_pending += 1


func quad(a: Vector3, b: Vector3, c: Vector3, d: Vector3, color: Color, inside: Vector3) -> void:
	tri(a, b, c, color, inside)
	tri(a, c, d, color, inside)


## Caixa de tamanho `size` centrada em `center`, girada `yaw` em torno do eixo vertical (12 triângulos).
func box(center: Vector3, size: Vector3, color: Color, yaw: float = 0.0) -> void:
	var corners: Array[Vector3] = []
	for index: int in 8:
		var local: Vector3 = Vector3(size.x * (float(index & 1) - 0.5), size.y * (float((index >> 1) & 1) - 0.5), size.z * (float((index >> 2) & 1) - 0.5))
		corners.append(center + local.rotated(Vector3.UP, yaw))
	for first: int in range(0, BOX_QUADS.size(), 4):
		quad(corners[BOX_QUADS[first]], corners[BOX_QUADS[first + 1]], corners[BOX_QUADS[first + 2]], corners[BOX_QUADS[first + 3]], color, center)


## Telhado de duas águas com a cumeeira ao longo de X; `size` = (comprimento, altura, profundidade) e a base fica em `base`.
func gable(base: Vector3, size: Vector3, color: Color, yaw: float = 0.0) -> void:
	var half_x: float = size.x * 0.5
	var half_z: float = size.z * 0.5
	var points: Array[Vector3] = []
	for corner: Vector3 in [Vector3(-half_x, 0.0, -half_z), Vector3(-half_x, 0.0, half_z), Vector3(-half_x, size.y, 0.0), Vector3(half_x, 0.0, -half_z), Vector3(half_x, 0.0, half_z), Vector3(half_x, size.y, 0.0)]:
		points.append(base + corner.rotated(Vector3.UP, yaw))
	var inside: Vector3 = base + Vector3(0.0, size.y * 0.3, 0.0)
	tri(points[0], points[1], points[2], color, inside)
	tri(points[3], points[4], points[5], color, inside)
	quad(points[0], points[2], points[5], points[3], color, inside)
	quad(points[1], points[4], points[5], points[2], color, inside)
	quad(points[0], points[1], points[4], points[3], color, inside)


## Prisma ou cone truncado de eixo vertical: `r_top` 0 faz um cone; `is_capped` fecha a base e o topo.
func frustum(base: Vector3, r_bottom: float, r_top: float, height: float, sides: int, color: Color, yaw: float = 0.0, is_capped: bool = true) -> void:
	var top: Vector3 = base + Vector3.UP * height
	var inside: Vector3 = base + Vector3.UP * height * 0.5
	for side: int in sides:
		var dir_a: Vector3 = Vector3.RIGHT.rotated(Vector3.UP, yaw + TAU * side / sides)
		var dir_b: Vector3 = Vector3.RIGHT.rotated(Vector3.UP, yaw + TAU * (side + 1) / sides)
		var bottom_a: Vector3 = base + dir_a * r_bottom
		var bottom_b: Vector3 = base + dir_b * r_bottom
		var top_a: Vector3 = top + dir_a * r_top
		var top_b: Vector3 = top + dir_b * r_top
		tri(bottom_a, bottom_b, top_b, color, inside)
		if r_top > 0.0:
			tri(bottom_a, top_b, top_a, color, inside)
		if is_capped:
			tri(base, bottom_a, bottom_b, color, inside)
			if r_top > 0.0:
				tri(top, top_a, top_b, color, inside)


## Esferóide facetado (rochas e sacos): `shape` = (faixas, setores, variante). Cada vértice é deslocado pelo hash, e o mesmo vértice sempre pelo mesmo valor.
func blob(center: Vector3, radii: Vector3, shape: Vector3i, jitter: float, color: Color) -> void:
	for ring: int in shape.x:
		for sector: int in shape.y:
			var a: Vector3 = _blob_point(center, radii, shape, jitter, ring, sector)
			var b: Vector3 = _blob_point(center, radii, shape, jitter, ring, sector + 1)
			var c: Vector3 = _blob_point(center, radii, shape, jitter, ring + 1, sector + 1)
			var d: Vector3 = _blob_point(center, radii, shape, jitter, ring + 1, sector)
			if ring == 0:
				tri(a, c, d, color, center)
			elif ring == shape.x - 1:
				tri(a, b, c, color, center)
			else:
				quad(a, b, c, d, color, center)


## Acrescenta o que foi desenhado a `mesh` como uma superfície com `material` e prepara a próxima; sem triângulos pendentes não faz nada.
func finish(mesh: ArrayMesh, material: Material) -> ArrayMesh:
	if _pending > 0:
		_surface.set_material(material)
		_surface.commit(mesh)
		_surface.clear()
		_surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		_pending = 0
	return mesh


func _blob_point(center: Vector3, radii: Vector3, shape: Vector3i, jitter: float, ring: int, sector: int) -> Vector3:
	var column: int = 0 if ring == 0 or ring == shape.x else sector % shape.y
	var bump: float = 1.0 + jitter * (unit(shape.z * BLOB_VARIANT_STRIDE + ring * BLOB_RING_STRIDE + column, BLOB_CHANNEL) * 2.0 - 1.0)
	var polar: float = PI * ring / shape.x
	var azimuth: float = TAU * column / shape.y
	var direction: Vector3 = Vector3(sin(polar) * cos(azimuth), cos(polar), sin(polar) * sin(azimuth))
	return center + direction * radii * bump


func _shade(color: Color, height_m: float) -> Color:
	if not is_shaded:
		return color
	return color.darkened(SHADE_AMOUNT * (1.0 - clampf(height_m / SHADE_HEIGHT_M, 0.0, 1.0)))
