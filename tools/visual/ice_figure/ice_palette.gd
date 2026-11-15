extends RefCounted
## Paleta PRÓPRIA do Ice Warrior (ferramenta de arte, fora do jogo). Origem documentada: cada cor da paleta é a cor sólida de uma FACE do original, amostrada no centro da UV da face; a imagem original só é lida para obter essas cores e NÃO é usada na versão preparada.
## Face = triângulos que compartilham vértices dentro de uma superfície (o quad de duas pontas, o triângulo solto, o leque); o centro da UV é a média das UVs dos vértices distintos da face. A paleta é uma grade de células quadradas de CELL_PX px, uma célula por cor única, em ordem crescente de cor; as UVs de cada face passam para o CENTRO da célula da sua cor (filtro NEAREST, sem mipmaps: nada sangra entre células).
## Se as cores únicas passam da grade (MAX_SIDE_CELLS x MAX_SIDE_CELLS), cores a menos de FUSE_BELOW níveis em cada canal fundem-se na mais baixa do grupo (guloso em ordem crescente: determinístico).
const Source = preload("res://tools/visual/ice_figure/ice_source.gd")
const CELL_PX: int = 4
const MAX_SIDE_CELLS: int = 16
const FUSE_BELOW: int = 2
const SHIFTS: PackedInt32Array = [16, 8, 0]
const BYTE_MASK: int = 255


## A paleta gerada: a imagem, as UVs reescritas (uma lista por superfície) e a cor de cada célula (chave 0xRRGGBB); `error` não vazio = não coube.
class Built:
	extends RefCounted
	var error: String = ""
	var image: Image
	var uvs: Array[PackedVector2Array] = []
	var colors: PackedInt32Array = PackedInt32Array()
	var distinct: int = 0


## Por superfície: a face (raiz) de cada vértice (-1 se não usado) e a chave de cor de cada face.
class Faces:
	extends RefCounted
	var root_of: PackedInt32Array = PackedInt32Array()
	var key_of: Dictionary[int, int] = {}


## A imagem original de uma superfície (a textura do material), sem compressão; só serve para ler as cores das faces.
static func image_of(material: Material) -> Image:
	var image: Image = (material as BaseMaterial3D).albedo_texture.get_image()
	if image.is_compressed():
		image.decompress()
	return image


## Gera a paleta e as UVs novas de todas as superfícies (uma imagem original por superfície).
static func build(surfs: Array[Source.Surf], images: Array[Image], max_side: int = MAX_SIDE_CELLS) -> Built:
	var out: Built = Built.new()
	var all_faces: Array[Faces] = []
	var seen: Dictionary[int, bool] = {}
	for index: int in surfs.size():
		all_faces.append(_faces(surfs[index], images[index]))
		for key: int in all_faces[index].key_of.values():
			seen[key] = true
	var keys: Array[int] = []
	keys.assign(seen.keys())
	keys.sort()
	out.distinct = keys.size()
	var anchor_of: Dictionary[int, int] = _anchors(keys, max_side * max_side)
	var cells: Array[int] = []
	for key: int in keys:
		if anchor_of[key] == key:
			cells.append(key)
	if cells.is_empty() or cells.size() > max_side * max_side:
		out.error = "paleta não cabe: %d cores únicas, %d depois de fundir cores a menos de %d níveis (grade de %d x %d células)" % [keys.size(), cells.size(), FUSE_BELOW, max_side, max_side]
		return out
	var side_cells: int = ceili(sqrt(cells.size()))
	var side_px: int = nearest_po2(side_cells * CELL_PX)
	out.image = Image.create(side_px, side_px, false, Image.FORMAT_RGB8)
	var rank_of: Dictionary[int, int] = {}
	var center_of: Array[Vector2] = []
	for rank: int in cells.size():
		var column: int = rank % side_cells
		var row: int = floori(rank / float(side_cells))
		out.image.fill_rect(Rect2i(column * CELL_PX, row * CELL_PX, CELL_PX, CELL_PX), _color(cells[rank]))
		rank_of[cells[rank]] = rank
		center_of.append(Vector2((column + 0.5) * CELL_PX, (row + 0.5) * CELL_PX) / float(side_px))
		out.colors.append(cells[rank])
	for index: int in surfs.size():
		var uvs: PackedVector2Array = PackedVector2Array()
		uvs.resize(surfs[index].positions.size())
		uvs.fill(center_of[0])
		for vertex: int in uvs.size():
			if all_faces[index].root_of[vertex] >= 0:
				uvs[vertex] = center_of[rank_of[anchor_of[all_faces[index].key_of[all_faces[index].root_of[vertex]]]]]
		out.uvs.append(uvs)
	return out


## O material da versão preparada: o importado (mesmas propriedades) com a paleta no lugar da textura e filtro NEAREST.
static func material_for(source: Material, palette: Texture2D) -> StandardMaterial3D:
	var copy: StandardMaterial3D = source.duplicate() as StandardMaterial3D
	copy.albedo_texture = palette
	copy.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	return copy


static func _faces(surf: Source.Surf, image: Image) -> Faces:
	var dsu: Source.Dsu = Source.Dsu.new(surf.positions.size())
	for first: int in range(0, surf.indices.size(), Source.TRI):
		dsu.union(surf.indices[first], surf.indices[first + 1])
		dsu.union(surf.indices[first], surf.indices[first + 2])
	var faces: Faces = Faces.new()
	faces.root_of.resize(surf.positions.size())
	faces.root_of.fill(-1)
	var sums: Dictionary[int, Vector2] = {}
	var counts: Dictionary[int, int] = {}
	for vertex: int in surf.indices:
		if faces.root_of[vertex] >= 0:
			continue
		var root: int = dsu.find(vertex)
		faces.root_of[vertex] = root
		sums[root] = sums.get(root, Vector2.ZERO) + surf.uvs[vertex]
		counts[root] = counts.get(root, 0) + 1
	for root: int in sums:
		var uv: Vector2 = sums[root] / float(counts[root])
		var size: Vector2i = image.get_size()
		var pixel: Color = image.get_pixel(clampi(floori(uv.x * size.x), 0, size.x - 1), clampi(floori(uv.y * size.y), 0, size.y - 1))
		faces.key_of[root] = pixel.r8 << SHIFTS[0] | pixel.g8 << SHIFTS[1] | pixel.b8
	return faces


## Cor (chave) -> célula (a âncora mais baixa do grupo). Sem fusão enquanto as cores cabem na grade.
static func _anchors(keys: Array[int], capacity: int) -> Dictionary[int, int]:
	var anchor_of: Dictionary[int, int] = {}
	var anchors: Array[int] = []
	for key: int in keys:
		var found: int = key
		if keys.size() > capacity:
			for position: int in range(anchors.size() - 1, -1, -1):
				if _channel(key, SHIFTS[0]) - _channel(anchors[position], SHIFTS[0]) >= FUSE_BELOW:
					break
				if _near(key, anchors[position]):
					found = anchors[position]
					break
		if found == key:
			anchors.append(key)
		anchor_of[key] = found
	return anchor_of


static func _near(a: int, b: int) -> bool:
	for shift: int in SHIFTS:
		if absi(_channel(a, shift) - _channel(b, shift)) >= FUSE_BELOW:
			return false
	return true


static func _channel(key: int, shift: int) -> int:
	return (key >> shift) & BYTE_MASK


static func _color(key: int) -> Color:
	return Color8(_channel(key, SHIFTS[0]), _channel(key, SHIFTS[1]), _channel(key, SHIFTS[2]))
