extends RefCounted
## Fonte do Ice Warrior para a ferramenta de preparo (ferramenta de arte, fora do jogo): lê as superfícies do GLB importado já em espaço mundial e em metros (o importador aplica a escala 0,01 da raiz do FBX e a 11,04 do `Cube_001`; os pés ficam em y = 0) e calcula as ilhas conexas. A geometria NUNCA é alterada: só é lida e, mais adiante, reescrita igual.
## Os vértices do GLB só são compartilhados dentro de uma face (normais planas), então as ilhas saem de uma soldagem por POSIÇÃO NA GRADE (cada posição é arredondada para a grade de WELD_M e vértices na mesma célula se soldam; NÃO é uma tolerância de distância: dois pontos a menos de WELD_M podem cair em células vizinhas e ficar separados) e união-busca. A ordem das ilhas é total (mais triângulos primeiro; empate pelo menor vértice), para o índice da ilha não depender da estabilidade da ordenação.

const SOURCE_PATH: String = "res://art_samples/novos_modelos/ice_warrior/IceWarrior.glb"
const WELD_M: float = 0.0001
const TRI: int = 3
const MIN_AREA_M2: float = 0.0000001
const EXPECTED_SURFACES: int = 2
const EXPECTED_TRIANGLES: int = 7956
const EXPECTED_ISLANDS: int = 73


## Uma superfície em espaço mundial; `material` é o objeto importado (o mesmo, sem troca) e `offset` o índice global do primeiro vértice.
class Surf:
	extends RefCounted
	var name: String = ""
	var material: Material
	var positions: PackedVector3Array = PackedVector3Array()
	var normals: PackedVector3Array = PackedVector3Array()
	var uvs: PackedVector2Array = PackedVector2Array()
	var indices: PackedInt32Array = PackedInt32Array()
	var offset: int = 0

	func triangles() -> int:
		return floori(indices.size() / float(TRI))


## Uma ilha conexa (triângulos ligados por vértices na mesma posição); `root` é o menor vértice global dela.
class Island:
	extends RefCounted
	var id: int = 0
	var root: int = 0
	var tris: int = 0
	var area: float = 0.0
	var center: Vector3 = Vector3.ZERO


## As ilhas (da maior para a menor) e, por vértice global, o índice da ilha (-1 se o vértice não é usado).
class IslandSet:
	extends RefCounted
	var list: Array[Island] = []
	var of_vertex: PackedInt32Array = PackedInt32Array()


## Um subconjunto da malha (os triângulos das ilhas pedidas, ou os das outras) em superfícies novas e COMPACTAS: só os vértices usados, na ordem da fonte, e os índices renumerados; a superfície que fica sem triângulo some. Os valores dos vértices (posição, normal) são os da fonte, sem mudança; `from_surface[i]` e `from_vertex[i][v]` dizem a superfície e o vértice de origem, para levar junto os valores que a fonte não guarda (UVs da paleta, ossos, pesos) por `pick`.
class Subset:
	extends RefCounted
	var surfs: Array[Surf] = []
	var from_surface: PackedInt32Array = PackedInt32Array()
	var from_vertex: Array[PackedInt32Array] = []

	## Os valores de `all` (uma lista por superfície da FONTE, `stride` valores por vértice) que cabem a este subconjunto, uma lista por superfície dele. `Variant` porque o mesmo seletor serve a UVs, ossos e pesos (Packed*Array de tipos diferentes).
	func pick(all: Array, stride: int = 1) -> Array:
		var out: Array = []
		for index: int in surfs.size():
			var values: Variant = all[from_surface[index]]
			var kept: Variant = values.slice(0, 0)
			for vertex: int in from_vertex[index]:
				kept.append_array(values.slice(vertex * stride, vertex * stride + stride))
			out.append(kept)
		return out


## União por conjuntos disjuntos; a raiz é sempre o menor índice do conjunto.
class Dsu:
	extends RefCounted
	var parent: PackedInt32Array = PackedInt32Array()

	func _init(count: int) -> void:
		parent.resize(count)
		for index: int in count:
			parent[index] = index

	func find(node: int) -> int:
		var top: int = node
		while parent[top] != top:
			top = parent[top]
		while parent[node] != top:
			var next: int = parent[node]
			parent[node] = top
			node = next
		return top

	func union(a: int, b: int) -> void:
		var root_a: int = find(a)
		var root_b: int = find(b)
		if root_a != root_b:
			parent[maxi(root_a, root_b)] = mini(root_a, root_b)


## As superfícies em espaço mundial, com os pés (menor y) em y = 0; vazio se o arquivo não existe ou se alguma transformação espelha a malha.
static func load_surfaces(path: String = SOURCE_PATH) -> Array[Surf]:
	var surfs: Array[Surf] = []
	var packed: PackedScene = load(path) as PackedScene
	if packed == null:
		return surfs
	var scene: Node = packed.instantiate()
	var low: float = INF
	for found: Node in scene.find_children("*", "MeshInstance3D", true, false):
		var holder: MeshInstance3D = found as MeshInstance3D
		var to_world: Transform3D = _world(holder)
		if to_world.basis.determinant() <= 0.0:
			push_error("fonte inválida: a transformação de %s espelha a malha" % holder.name)
			scene.free()
			return []
		var turn: Basis = to_world.basis.orthonormalized()
		for index: int in holder.mesh.get_surface_count():
			var arrays: Array = holder.mesh.surface_get_arrays(index)
			var surf: Surf = Surf.new()
			surf.name = "%s/%d" % [holder.name, index]
			surf.material = holder.get_active_material(index)
			for vertex: Vector3 in (arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array):
				var point: Vector3 = to_world * vertex
				surf.positions.append(point)
				low = minf(low, point.y)
			for normal: Vector3 in (arrays[Mesh.ARRAY_NORMAL] as PackedVector3Array):
				surf.normals.append((turn * normal).normalized())
			surf.uvs = arrays[Mesh.ARRAY_TEX_UV] as PackedVector2Array
			surf.indices = arrays[Mesh.ARRAY_INDEX] as PackedInt32Array
			surfs.append(surf)
	scene.free()
	var total: int = 0
	for surf: Surf in surfs:
		surf.offset = total
		total += surf.positions.size()
		for vertex_index: int in surf.positions.size():
			surf.positions[vertex_index] -= Vector3(0.0, low, 0.0)
	return surfs


## As ilhas conexas (soldagem por posição arredondada para a grade de WELD_M, não por distância) e o centroide de cada uma, ponderado pela área; sem superfícies, nenhuma ilha.
static func islands(surfs: Array[Surf]) -> IslandSet:
	var total: int = 0 if surfs.is_empty() else surfs[-1].offset + surfs[-1].positions.size()
	var dsu: Dsu = Dsu.new(total)
	var cell: Dictionary[Vector3i, int] = {}
	for surf: Surf in surfs:
		for index: int in surf.positions.size():
			var key: Vector3i = Vector3i((surf.positions[index] / WELD_M).round())
			if cell.has(key):
				dsu.union(surf.offset + index, cell[key])
			else:
				cell[key] = surf.offset + index
		for first: int in range(0, surf.indices.size(), TRI):
			dsu.union(surf.offset + surf.indices[first], surf.offset + surf.indices[first + 1])
			dsu.union(surf.offset + surf.indices[first], surf.offset + surf.indices[first + 2])
	return _collect(surfs, dsu, total)


## Os triângulos das ilhas `ids` (`inside`) ou os das outras (`not inside`); um triângulo é da ilha do seu primeiro vértice (as ilhas não dividem vértice). Sem `ids`, `inside` falso devolve a malha inteira.
static func subset(surfs: Array[Surf], found: IslandSet, ids: PackedInt32Array, inside: bool) -> Subset:
	var out: Subset = Subset.new()
	for number: int in surfs.size():
		var surf: Surf = surfs[number]
		var chosen: PackedByteArray = PackedByteArray()
		chosen.resize(surf.triangles())
		var used: PackedByteArray = PackedByteArray()
		used.resize(surf.positions.size())
		for tri: int in chosen.size():
			if ids.has(found.of_vertex[surf.offset + surf.indices[tri * TRI]]) == inside:
				chosen[tri] = 1
				for corner: int in TRI:
					used[surf.indices[tri * TRI + corner]] = 1
		var part: Surf = Surf.new()
		part.name = surf.name
		part.material = surf.material
		var origin: PackedInt32Array = PackedInt32Array()
		var renumbered: PackedInt32Array = PackedInt32Array()
		renumbered.resize(used.size())
		for vertex: int in used.size():
			if used[vertex] == 1:
				renumbered[vertex] = origin.size()
				origin.append(vertex)
				part.positions.append(surf.positions[vertex])
				part.normals.append(surf.normals[vertex])
		for tri: int in chosen.size():
			if chosen[tri] == 1:
				for corner: int in TRI:
					part.indices.append(renumbered[surf.indices[tri * TRI + corner]])
		if not part.indices.is_empty():
			out.surfs.append(part)
			out.from_surface.append(number)
			out.from_vertex.append(origin)
	return out


## Confere a fonte contra o esperado; devolve as mensagens de falha (vazio = é a fonte esperada). Sem superfícies (original presente mas não importado) é uma falha só, com o remédio.
static func validate(surfs: Array[Surf], found: IslandSet, surfaces: int = EXPECTED_SURFACES, triangles: int = EXPECTED_TRIANGLES, island_count: int = EXPECTED_ISLANDS) -> PackedStringArray:
	if surfs.is_empty():
		return PackedStringArray(["nenhuma superfície lida de %s: o original ainda não foi importado nesta máquina (rode godot --headless --path <projeto> --import e tente de novo) ou uma transformação dele espelha a malha" % SOURCE_PATH])
	var errors: PackedStringArray = PackedStringArray()
	var tris: int = 0
	for surf: Surf in surfs:
		tris += surf.triangles()
	if surfs.size() != surfaces:
		errors.append("fonte inesperada: %d superfícies (esperado %d)" % [surfs.size(), surfaces])
	if tris != triangles:
		errors.append("fonte inesperada: %d triângulos (esperado %d)" % [tris, triangles])
	if found.list.size() != island_count:
		errors.append("fonte inesperada: %d ilhas (esperado %d)" % [found.list.size(), island_count])
	return errors


## A malha a partir das mesmas posições, normais e índices da fonte, com as UVs e os materiais dados e, se vierem, ossos e pesos (4 por vértice).
static func mesh_of(surfs: Array[Surf], uvs: Array[PackedVector2Array], materials: Array[Material], bones: Array[PackedInt32Array] = [], weights: Array[PackedFloat32Array] = []) -> ArrayMesh:
	var mesh: ArrayMesh = ArrayMesh.new()
	for index: int in surfs.size():
		var arrays: Array = []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = surfs[index].positions
		arrays[Mesh.ARRAY_NORMAL] = surfs[index].normals
		arrays[Mesh.ARRAY_TEX_UV] = uvs[index]
		arrays[Mesh.ARRAY_INDEX] = surfs[index].indices
		if not bones.is_empty():
			arrays[Mesh.ARRAY_BONES] = bones[index]
			arrays[Mesh.ARRAY_WEIGHTS] = weights[index]
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		mesh.surface_set_material(index, materials[index])
	return mesh


static func _collect(surfs: Array[Surf], dsu: Dsu, total: int) -> IslandSet:
	var by_root: Dictionary[int, Island] = {}
	var weighted: Dictionary[int, Vector3] = {}
	for surf: Surf in surfs:
		for first: int in range(0, surf.indices.size(), TRI):
			var a: Vector3 = surf.positions[surf.indices[first]]
			var b: Vector3 = surf.positions[surf.indices[first + 1]]
			var c: Vector3 = surf.positions[surf.indices[first + 2]]
			var root: int = dsu.find(surf.offset + surf.indices[first])
			if not by_root.has(root):
				by_root[root] = Island.new()
				by_root[root].root = root
				weighted[root] = Vector3.ZERO
			var area: float = (b - a).cross(c - a).length() * 0.5
			by_root[root].tris += 1
			by_root[root].area += area
			weighted[root] += (a + b + c) / 3.0 * area
	var result: IslandSet = IslandSet.new()
	for root: int in by_root:
		by_root[root].center = weighted[root] / maxf(by_root[root].area, MIN_AREA_M2)
		result.list.append(by_root[root])
	result.list.sort_custom(func(left: Island, right: Island) -> bool: return left.tris > right.tris or (left.tris == right.tris and left.root < right.root))
	result.of_vertex.resize(total)
	result.of_vertex.fill(-1)
	var id_of_root: Dictionary[int, int] = {}
	for index: int in result.list.size():
		result.list[index].id = index
		id_of_root[result.list[index].root] = index
	for surf: Surf in surfs:
		for corner: int in surf.indices:
			result.of_vertex[surf.offset + corner] = id_of_root[dsu.find(surf.offset + corner)]
	return result


static func _world(node: Node3D) -> Transform3D:
	var accumulated: Transform3D = node.transform
	var up: Node = node.get_parent()
	while up is Node3D:
		accumulated = (up as Node3D).transform * accumulated
		up = up.get_parent()
	return accumulated
