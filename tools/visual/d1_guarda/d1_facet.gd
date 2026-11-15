extends RefCounted
## D1-A (estudo isolado, só apresentação): a passagem de FACETAMENTO sobre as malhas com pele da base Quaternius. Por peça: (1) decimação ao orçamento de triângulos (simplificador do motor, SurfaceTool.generate_lod); (2) um triângulo = 3 vértices próprios, com NORMAL PLANA, copiando ossos e pesos; (3) cor por face lida na textura de origem (WebP, média linear dos 3 vértices) e gravada como cor de vértice, opcionalmente passada por `recolor`; (4) tudo numa superfície só, com UM material. Peças rígidas entram como vértices 100% pesados num osso.

const NORMAL_MERGE_DEG: float = 60.0
const NORMAL_SPLIT_DEG: float = 90.0

var _v: PackedVector3Array = PackedVector3Array()
var _n: PackedVector3Array = PackedVector3Array()
var _c: PackedColorArray = PackedColorArray()
var _b: PackedInt32Array = PackedInt32Array()
var _w: PackedFloat32Array = PackedFloat32Array()
var _names: PackedStringArray = PackedStringArray()
var _poses: Array[Transform3D] = []
var _images: Dictionary[String, Image] = {}


## `skin` é a pele de uma peça do esqueleto de 65 ossos: dela vêm os nomes e as poses de repouso da pele única.
func _init(skin: Skin) -> void:
	for bind: int in skin.get_bind_count():
		_names.append(skin.get_bind_name(bind))
		_poses.append(skin.get_bind_pose(bind))


func triangles() -> int:
	@warning_ignore("integer_division")
	return _v.size() / 3


## Uma superfície de uma MeshInstance3D com pele, reduzida a `tris` triângulos. `recolor` (opcional) recebe a cor lida e o centro da face e devolve a cor final (sRGB).
func add_surface(mi: MeshInstance3D, surface: int, tris: int, recolor: Callable = Callable()) -> void:
	var arrays: Array = mi.mesh.surface_get_arrays(surface)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
	var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
	var map: PackedInt32Array = PackedInt32Array()
	for bind: int in mi.skin.get_bind_count():
		map.append(_names.find(mi.skin.get_bind_name(bind)))
	var image: Image = _image(mi.mesh.surface_get_material(surface))
	var indices: PackedInt32Array = _decimate(arrays, tris)
	@warning_ignore("integer_division")
	for face: int in indices.size() / 3:
		var corner: PackedInt32Array = indices.slice(face * 3, face * 3 + 3)
		var normal: Vector3 = (verts[corner[2]] - verts[corner[0]]).cross(verts[corner[1]] - verts[corner[0]])
		if normal.length_squared() < 1.0e-14:
			continue
		var linear: Color = Color(0.0, 0.0, 0.0, 1.0)
		for vertex: int in corner:
			var pixel: Color = image.get_pixel(mini(int(fposmod(uvs[vertex].x, 1.0) * image.get_width()), image.get_width() - 1), mini(int(fposmod(uvs[vertex].y, 1.0) * image.get_height()), image.get_height() - 1))
			linear += Color(pixel.srgb_to_linear(), 0.0)
		var color: Color = Color(linear.r / 3.0, linear.g / 3.0, linear.b / 3.0).linear_to_srgb()
		if recolor.is_valid():
			color = recolor.call(color, (verts[corner[0]] + verts[corner[1]] + verts[corner[2]]) / 3.0)
		for vertex: int in corner:
			_v.append(verts[vertex])
			_n.append(normal.normalized())
			_c.append(color)
			for slot: int in 4:
				_b.append(map[bones[vertex * 4 + slot]])
				_w.append(weights[vertex * 4 + slot])


## Peça rígida já em coordenadas do repouso do personagem: `piece` = {"bone", "v", "n", "c"} (vértices, normais e cores sem índice); com "bone2", "y0" e "y1" os vértices mais baixos que y0 passam até 70% para o segundo osso (pano que acompanha a coxa).
func add_rigid(piece: Dictionary) -> void:
	var bone: int = _names.find(String(piece["bone"]))
	var second: int = _names.find(String(piece.get("bone2", "")))
	for point: int in (piece["v"] as PackedVector3Array).size():
		var mix: float = 0.0
		if second >= 0:
			mix = 0.7 * clampf((float(piece["y0"]) - piece["v"][point].y) / (float(piece["y0"]) - float(piece["y1"])), 0.0, 1.0)
		_v.append(piece["v"][point])
		_n.append(piece["n"][point])
		_c.append(piece["c"][point])
		_b.append_array([bone, maxi(second, 0), 0, 0])
		_w.append_array([1.0 - mix, mix, 0.0, 0.0])


## A malha pronta: uma superfície, o material único e nenhum índice.
func build() -> ArrayMesh:
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = _v
	arrays[Mesh.ARRAY_NORMAL] = _n
	arrays[Mesh.ARRAY_COLOR] = _c
	arrays[Mesh.ARRAY_BONES] = _b
	arrays[Mesh.ARRAY_WEIGHTS] = _w
	var mesh: ArrayMesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh.surface_set_material(0, single_material())
	return mesh


func skin() -> Skin:
	var result: Skin = Skin.new()
	for bind: int in _names.size():
		result.add_named_bind(_names[bind], _poses[bind])
	return result


static func single_material() -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.roughness = 0.9
	return material


## Os níveis de LOD do importador (ImporterMesh.generate_lods, soldando as costuras de UV): fica o nível cujo número de triângulos é o mais próximo do orçamento.
static func _decimate(arrays: Array, tris: int) -> PackedInt32Array:
	var best: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var importer: ImporterMesh = ImporterMesh.new()
	importer.add_surface(Mesh.PRIMITIVE_TRIANGLES, arrays)
	importer.generate_lods(NORMAL_MERGE_DEG, NORMAL_SPLIT_DEG, [])
	for level: int in importer.get_surface_lod_count(0):
		var lod: PackedInt32Array = importer.get_surface_lod_indices(0, level)
		if absi(lod.size() / 3 - tris) < absi(best.size() / 3 - tris):
			best = lod
	return best


## A textura de origem do material, lida do WebP (sem passar pelo formato comprimido do motor).
func _image(material: Material) -> Image:
	var texture: Texture2D = (material as BaseMaterial3D).albedo_texture
	var path: String = texture.resource_path
	if not _images.has(path):
		var image: Image = Image.load_from_file(ProjectSettings.globalize_path(path))
		_images[path] = image if image != null else texture.get_image()
	return _images[path]
