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
## D1 (nova linguagem): a aresta chanfrada pega a luz e sai mais clara que a face; o hash mexe no tom de cada tábua e de cada bloco de pedra (`key` separa as peças), e os blocos de uma fiada se assentam até COURSE_SETTLE de altura.
const EDGE_LIGHT: float = 0.1
const PLANK_CHANNEL: int = 6007
const PLANK_KEY_STRIDE: int = 16
const PLANK_JITTER: float = 0.25
const COURSE_CHANNEL: int = 6011
const COURSE_KEY_STRIDE: int = 64
const COURSE_SETTLE: float = 0.06

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


## D1: caixa de `size` com as 12 arestas chanfradas em `chamfer` metros (44 triângulos): 6 faces encolhidas, uma tira por aresta e um triângulo por canto; as tiras e os cantos saem mais claros (a aresta viva pega a luz).
func chamfered_box(center: Vector3, size: Vector3, color: Color, chamfer: float, yaw: float = 0.0) -> void:
	var half: Vector3 = size * 0.5
	var edge: Color = color.lightened(EDGE_LIGHT)
	var points: Array[Vector3] = []
	for corner: int in 8:
		var signs: Vector3 = Vector3(float(corner & 1) * 2.0 - 1.0, float((corner >> 1) & 1) * 2.0 - 1.0, float((corner >> 2) & 1) * 2.0 - 1.0)
		for axis: int in 3:
			var local: Vector3 = signs * (half - Vector3.ONE * chamfer)
			local[axis] = signs[axis] * half[axis]
			points.append(center + local.rotated(Vector3.UP, yaw))
	for axis: int in 3:
		var across: int = (axis + 1) % 3
		var along: int = (axis + 2) % 3
		for side: int in 2:
			var face: int = side << axis
			var ring: Array[int] = [face, face | (1 << across), face | (1 << across) | (1 << along), face | (1 << along)]
			quad(points[ring[0] * 3 + axis], points[ring[1] * 3 + axis], points[ring[2] * 3 + axis], points[ring[3] * 3 + axis], color, center)
			for next: int in 2:
				var low: int = face | (next << across)
				var high: int = low | (1 << along)
				quad(points[low * 3 + axis], points[high * 3 + axis], points[high * 3 + across], points[low * 3 + across], edge, center)
	for corner: int in 8:
		tri(points[corner * 3], points[corner * 3 + 1], points[corner * 3 + 2], edge, center)


## D1: viga de seção `width` (de través, na horizontal) x `height` entre `from` e `to` (12 triângulos); numa viga vertical a largura fica em x.
func beam(from: Vector3, to: Vector3, width: float, height: float, color: Color) -> void:
	var along: Vector3 = to - from
	var side: Vector3 = along.cross(Vector3.UP)
	side = Vector3.RIGHT if side.length_squared() < 0.0001 else side.normalized()
	var rise: Vector3 = side.cross(along).normalized() * height * 0.5
	side *= width * 0.5
	var corners: Array[Vector3] = []
	for index: int in 8:
		corners.append((to if (index & 4) != 0 else from) + (side if (index & 1) != 0 else -side) + (rise if (index & 2) != 0 else -rise))
	for first: int in range(0, BOX_QUADS.size(), 4):
		quad(corners[BOX_QUADS[first]], corners[BOX_QUADS[first + 1]], corners[BOX_QUADS[first + 2]], corners[BOX_QUADS[first + 3]], color, (from + to) * 0.5)


## D1: `count` tábuas sobrepostas (parede de madeira ou telhado) sobre o retângulo `origin` + `across` x `rise`, com a frente para `out`: cada uma sai `lap` metros para fora embaixo e deixa uma sombra sob a borda (4 triângulos por tábua); o tom varia pelo hash de `key`.
func planks(origin: Vector3, across: Vector3, rise: Vector3, out: Vector3, count: int, lap: float, color: Color, key: int) -> void:
	var inside: Vector3 = origin + (across + rise) * 0.5 - out
	for board: int in count:
		var bottom: Vector3 = origin + rise * float(board) / count
		var top: Vector3 = origin + rise * float(board + 1) / count
		var tone: Color = color.darkened(unit(key * PLANK_KEY_STRIDE + board, PLANK_CHANNEL) * PLANK_JITTER)
		quad(bottom + out * lap, bottom + across + out * lap, top + across, top, tone, inside)
		quad(bottom, bottom + across, bottom + across + out * lap, bottom + out * lap, tone.darkened(0.35), bottom + rise.normalized() * 0.1)


## D1: uma fiada de `count` blocos (tamanho = tangente, altura, raio) em anel de `radius` em torno de `center`, a primeira deslocada `phase` (0 a 1) de bloco para as juntas das fiadas se alternarem; o tom e a altura de cada bloco variam pelo hash (`key` separa as fiadas).
func stone_course(center: Vector3, radius: float, count: int, size: Vector3, color: Color, phase: float, key: int) -> void:
	for block: int in count:
		var angle: float = TAU * (float(block) + phase) / count
		var luck: float = unit(key * COURSE_KEY_STRIDE + block, COURSE_CHANNEL)
		var tall: float = size.y * (1.0 - COURSE_SETTLE * luck)
		var spot: Vector3 = center + Vector3(cos(angle) * radius, (tall - size.y) * 0.5, sin(angle) * radius)
		box(spot, Vector3(size.x, tall, size.z), color.darkened(luck * 0.22), -(angle + PI * 0.5))


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
