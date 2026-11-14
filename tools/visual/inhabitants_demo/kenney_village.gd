class_name KenneyVillage
extends RefCounted
## Vila de TESTE com peças do Fantasy Town Kit 2.0 da Kenney (CC0; ficam em art_samples/, fora do Git até o aceite visual de Arthur, DEC-021), só para ver o estilo delas ao lado dos habitantes (ART-9b, protótipo isolado, fora de `src/`). Regras de montagem medidas nos AABBs reais dos GLB: o módulo é uma célula de 1 unidade (fator SCALE = 2,5 para o habitante de 1,7 m), com pivô no centro da célula e base em y = 0; a parede é uma lâmina de 0,1 no lado +X da célula (girar 90 graus a leva a -Z, 180 a -X, 270 a +Z) e o canto leva duas lâminas (+X e +Z); o telhado tem o mesmo pivô e base em y = 0 (assenta no topo da parede, y = 1), cumeeira ao longo de X, 5 cm de beiral em X e 3,5 cm em Z, e a ponta de duas águas (`-end`) fecha o lado -X (girada 180 graus, o +X); para 2 células de profundidade o telhado é esticado 2 vezes em Z. A chaminé e o estandarte são feitos para o lado de DENTRO da parede (x de 0,21 a 0,43 e de 0,375 a 0,425), então o estandarte sai 0,125 para fora.

const PIECE_PATH: String = "res://art_samples/kenney_fantasy_town/glb/%s.glb"
const SCALE: float = 2.5
const ROOF_STRETCH: Vector3 = Vector3(1.0, 1.25, 2.0)
const CHIMNEY_CENTER_X: float = 0.32
const CHIMNEY_BASE_Y: float = 1.2
const BANNER_OUT: float = 0.125
const FRONT_YAW: float = 270.0
const BACK_YAW: float = 90.0
## Casas (células): telhado, x do 1º módulo, z da fila de trás (a da frente é +1), módulos da frente e de trás entre os cantos, estandarte e o módulo do canto da frente em que ele fica.
const HOUSES: Array = [
	["roof-gable", -4.1, -3.9, ["wall-wood-window-shutters", "wall-wood-door"], ["wall-wood-window-small", "wall-wood"], "banner-red", 0],
	["roof-high-gable", 1.9, -3.9, ["wall-wood-door", "wall-wood-window-small"], ["wall-wood", "wall-wood-window-shutters"], "banner-green", 3],
]
## Rua de calçamento: células em X, fileiras de pista (z) e o calçadão de trás; a pista afunda para o topo ficar rente ao chão.
const ROAD_X: Vector2i = Vector2i(-6, 5)
const ROAD_ROWS: Array[float] = [-0.5, 0.5]
const CURB_ROW: float = -1.5
const ROAD_SINK: float = -0.025
## Peças soltas (nome, x e z em metros, giro, tamanho sobre o fator).
const PROPS: Array = [
	["stall-red", -7.6, -3.9, 0.0, 1.0], ["stall-bench", -7.6, -2.3, 90.0, 1.0], ["stall-stool", -5.9, -2.9, 0.0, 1.0], ["stall-green", 9.8, -3.9, 0.0, 1.0],
	["cart", 4.6, -3.1, -20.0, 1.0], ["fountain-round", 0.4, -4.7, 0.0, 1.0], ["lantern", -1.9, -2.9, 0.0, 1.0], ["lantern", 3.0, -2.9, 0.0, 1.0],
	["planks", -5.25, -3.7, 0.0, 1.0], ["planks", 7.25, -3.7, 0.0, 1.0], ["tree-high-round", 0.6, -10.5, 0.0, 1.0], ["tree", -1.0, -12.5, 0.0, 1.0],
	["tree-high", -13.8, -5.0, 0.0, 1.0], ["tree", 15.5, -6.0, 0.0, 1.0], ["rock-small", -3.6, -3.4, 30.0, 0.5], ["rock-large", 14.2, -2.8, 0.0, 0.5],
	["fence", -13.0, -3.0, 90.0, 1.0], ["fence", -10.5, -3.0, 90.0, 1.0], ["hedge", 13.0, -4.6, 270.0, 1.0], ["hedge", 15.5, -4.6, 270.0, 1.0],
]
const GRASS_COLOR: Color = Color("629C55")
const CATALOG_GROUND_COLOR: Color = Color("B9C0A8")
const GROUND_NAME: String = "Ground"
const MERGED_NAME: String = "Merged"
const GROUND_SIZE_M: float = 260.0
const GROUND_DROP_M: float = -0.03
## Catálogo: as 37 peças em quatro fileiras (pequenas, paredes, telhados e acabamentos, grandes), as finas giradas para a face ficar de frente.
const CATALOG_ROWS: Array = [
	["road", "road-corner", "road-curb", "planks", "hedge", "fence", "stall-stool", "stall-bench", "banner-red", "banner-green"],
	["wall", "wall-wood", "wall-corner", "wall-wood-corner", "wall-window-stone", "wall-wood-window-small", "wall-wood-window-shutters", "wall-doorway-round", "wall-wood-doorway-square"],
	["wall-wood-door", "roof-gable", "roof-gable-end", "roof-gable-top", "roof-corner", "roof-high-gable", "roof-high-gable-end", "chimney", "lantern"],
	["stall-red", "stall-green", "cart", "fountain-round", "tree", "tree-high", "tree-high-round", "rock-small", "rock-large"],
]
const CATALOG_FACING: Array[String] = ["wall", "fence", "hedge", "banner", "stall-bench"]
const CATALOG_GAP_M: float = 0.8
const CATALOG_ROW_STEP_M: float = 7.0
const CATALOG_HUMAN_ROW: float = 0.3

var root: Node3D
var pieces: int = 0
var triangles: int = 0

var _cache: Dictionary[String, PackedScene] = {}
var _counts: Dictionary[String, int] = {}


func _init(parent: Node3D, node_name: String, origin: Vector3 = Vector3.ZERO) -> void:
	root = Node3D.new()
	root.name = node_name
	root.position = origin
	parent.add_child(root)


## A rua de vila: chão de grama, calçamento, duas casas montadas, barracas e o resto.
func build_village() -> void:
	_ground(GRASS_COLOR)
	for x: int in range(ROAD_X.x, ROAD_X.y + 1):
		for row: float in ROAD_ROWS:
			place("road", Vector3(x, ROAD_SINK, row))
		place("road-curb", Vector3(x, ROAD_SINK, CURB_ROW))
	for house: Array in HOUSES:
		_house(house)
	for prop: Array in PROPS:
		place(prop[0], Vector3(prop[1], 0.0, prop[2]) / SCALE, prop[3], Vector3.ONE * float(prop[4]))


## ART-9c, chamadas de desenho: junta as peças ESTÁTICAS da vila por material numa malha só (as transformações já aplicadas, com a normal pela inversa transposta), em vez de um nó por peça (e por material de cada peça); o chão fica de fora. Chamar com a vila montada e dentro da árvore.
func merge_static() -> void:
	var inverse: Transform3D = root.global_transform.affine_inverse()
	var batches: Dictionary[String, Dictionary] = {}
	var originals: Array[Node] = []
	for child: Node in root.get_children():
		if child.name != GROUND_NAME:
			originals.append(child)
	for original: Node in originals:
		for mesh_node: Node in original.find_children("*", "MeshInstance3D", true, false):
			var instance: MeshInstance3D = mesh_node as MeshInstance3D
			for surface: int in instance.mesh.get_surface_count():
				_append_surface(batches, instance.get_active_material(surface), instance.mesh.surface_get_arrays(surface), inverse * instance.global_transform)
	var merged: ArrayMesh = ArrayMesh.new()
	for key: String in batches:
		var arrays: Array = []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = batches[key]["vertices"]
		arrays[Mesh.ARRAY_NORMAL] = batches[key]["normals"]
		arrays[Mesh.ARRAY_TEX_UV] = batches[key]["uvs"]
		arrays[Mesh.ARRAY_INDEX] = batches[key]["indices"]
		merged.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		merged.surface_set_material(merged.get_surface_count() - 1, batches[key]["material"])
	var merged_node: MeshInstance3D = MeshInstance3D.new()
	merged_node.name = MERGED_NAME
	merged_node.mesh = merged
	root.add_child(merged_node)
	for original: Node in originals:
		root.remove_child(original)
		original.free()


## Soma uma superfície (vértices, normais, UVs e índices) ao lote do seu material, já levada para o espaço de `root` por `to_root`.
func _append_surface(batches: Dictionary[String, Dictionary], material: Material, arrays: Array, to_root: Transform3D) -> void:
	var key: String = _material_key(material)
	if not batches.has(key):
		batches[key] = {"material": material, "vertices": PackedVector3Array(), "normals": PackedVector3Array(), "uvs": PackedVector2Array(), "indices": PackedInt32Array()}
	var vertices: PackedVector3Array = batches[key]["vertices"]
	var normals: PackedVector3Array = batches[key]["normals"]
	var offset: int = vertices.size()
	var source_vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var source_normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var normal_basis: Basis = to_root.basis.inverse().transposed()
	for index: int in source_vertices.size():
		vertices.append(to_root * source_vertices[index])
		normals.append((normal_basis * source_normals[index]).normalized())
	var indices: PackedInt32Array = batches[key]["indices"]
	var source_indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	for index: int in source_indices:
		indices.append(index + offset)
	var uvs: PackedVector2Array = batches[key]["uvs"]
	uvs.append_array(arrays[Mesh.ARRAY_TEX_UV])
	batches[key]["vertices"] = vertices
	batches[key]["normals"] = normals
	batches[key]["indices"] = indices
	batches[key]["uvs"] = uvs


## Chave do lote: cada peça da Kenney traz o seu material, mas todos usam a mesma textura de paleta, então se juntam pelo conteúdo (textura, transparência e cor) e não pela instância.
func _material_key(material: Material) -> String:
	var standard: BaseMaterial3D = material as BaseMaterial3D
	if standard == null:
		return str(material.get_instance_id())
	return "%d|%d|%s" % [standard.albedo_texture.get_instance_id() if standard.albedo_texture != null else 0, standard.transparency, standard.albedo_color.to_html()]


## As 37 peças em fileira na escala do jogo; devolve o ponto da frente da primeira fileira, onde o habitante de comparação fica.
func build_catalog() -> Vector3:
	_ground(CATALOG_GROUND_COLOR)
	for row_index: int in CATALOG_ROWS.size():
		var nodes: Array[Node3D] = []
		var boxes: Array[AABB] = []
		var total: float = -CATALOG_GAP_M
		for piece_name: String in CATALOG_ROWS[row_index]:
			var node: Node3D = _instance(piece_name)
			node.scale = Vector3.ONE * SCALE
			node.rotation_degrees.y = FRONT_YAW if CATALOG_FACING.any(func(prefix: String) -> bool: return piece_name.begins_with(prefix)) else 0.0
			nodes.append(node)
			boxes.append(_bounds(node))
			total += boxes[-1].size.x + CATALOG_GAP_M
		var cursor: float = -total * 0.5
		var row_z: float = -row_index * CATALOG_ROW_STEP_M
		for index: int in nodes.size():
			nodes[index].position = Vector3(cursor - boxes[index].position.x, 0.0, row_z - boxes[index].get_center().z)
			root.add_child(nodes[index])
			_count_piece(CATALOG_ROWS[row_index][index], nodes[index])
			cursor += boxes[index].size.x + CATALOG_GAP_M
	return root.global_position + Vector3(0.0, 0.0, CATALOG_ROW_STEP_M * CATALOG_HUMAN_ROW)


## Uma peça no lugar `cell` (em células, o fator SCALE entra aqui), girada `yaw_deg` em torno de Y e esticada por `stretch`.
func place(piece_name: String, cell: Vector3, yaw_deg: float = 0.0, stretch: Vector3 = Vector3.ONE) -> Node3D:
	var node: Node3D = _instance(piece_name)
	node.scale = stretch * SCALE
	node.rotation_degrees.y = yaw_deg
	node.position = cell * SCALE
	root.add_child(node)
	_count_piece(piece_name, node)
	return node


## Casa de 2 células de profundidade: 4 cantos, paredes da frente (+Z) e de trás entre eles, telhado de duas águas esticado em Z, chaminé e estandarte.
func _house(spec: Array) -> void:
	var front: Array = spec[3]
	var back: Array = spec[4]
	var length: int = front.size() + 2
	var x: float = spec[1]
	var z: float = spec[2]
	place("wall-wood-corner", Vector3(x, 0.0, z), 180.0)
	place("wall-wood-corner", Vector3(x + length - 1, 0.0, z), 90.0)
	place("wall-wood-corner", Vector3(x, 0.0, z + 1.0), 270.0)
	place("wall-wood-corner", Vector3(x + length - 1, 0.0, z + 1.0), 0.0)
	for index: int in front.size():
		place(front[index], Vector3(x + 1 + index, 0.0, z + 1.0), FRONT_YAW)
		place(back[index], Vector3(x + 1 + index, 0.0, z), BACK_YAW)
	for index: int in length:
		var is_end: bool = index == 0 or index == length - 1
		place(spec[0] + ("-end" if is_end else ""), Vector3(x + index, 1.0, z + 0.5), 180.0 if index == length - 1 else 0.0, ROOF_STRETCH)
	place("chimney", Vector3(x + 1.5 - CHIMNEY_CENTER_X, CHIMNEY_BASE_Y, z - 0.05))
	place(spec[5], Vector3(x + spec[6], 0.0, z + 1.0 + BANNER_OUT), FRONT_YAW)


## Soma uma peça colocada às contagens de peças e de triângulos (os triângulos de cada modelo são contados uma vez só).
func _count_piece(piece_name: String, node: Node3D) -> void:
	if not _counts.has(piece_name):
		var vertices: int = 0
		for mesh_node: Node in node.find_children("*", "MeshInstance3D", true, false):
			vertices += (mesh_node as MeshInstance3D).mesh.get_faces().size()
		_counts[piece_name] = int(vertices / 3.0)
	pieces += 1
	triangles += _counts[piece_name]


func _instance(piece_name: String) -> Node3D:
	if not _cache.has(piece_name):
		_cache[piece_name] = load(PIECE_PATH % piece_name)
	return _cache[piece_name].instantiate() as Node3D


## Caixa de uma peça já escalada e girada (sem posição), juntando as malhas dos filhos.
func _bounds(node: Node3D) -> AABB:
	var box: AABB = AABB()
	var is_first: bool = true
	for mesh_node: Node in node.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance: MeshInstance3D = mesh_node as MeshInstance3D
		var chain: Transform3D = mesh_instance.transform
		var parent: Node = mesh_instance.get_parent()
		while parent != node and parent != null:
			chain = (parent as Node3D).transform * chain
			parent = parent.get_parent()
		var part: AABB = Transform3D(node.basis, Vector3.ZERO) * chain * mesh_instance.mesh.get_aabb()
		box = part if is_first else box.merge(part)
		is_first = false
	return box


func _ground(color: Color) -> void:
	var plane: PlaneMesh = PlaneMesh.new()
	plane.size = Vector2(GROUND_SIZE_M, GROUND_SIZE_M)
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 1.0
	plane.material = material
	var ground: MeshInstance3D = MeshInstance3D.new()
	ground.name = GROUND_NAME
	ground.mesh = plane
	ground.position.y = GROUND_DROP_M
	root.add_child(ground)
