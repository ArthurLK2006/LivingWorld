extends SceneTree
## ART-12 (entrega 2): regenera o subconjunto processado e CC0 dos pacotes da Quaternius em assets/characters/quaternius/ a partir dos
## três zips originais (que ficam fora do Git; sem rede). Transformações, hashes e o porquê de cada grupo: docs/arte/MANIFESTO_LICENCAS.md.
## Uso: tools/assets/process_quaternius <fantasy.zip> <ubc.zip> <ual.zip> [pasta_de_saida]

const OUT_DEFAULT: String = "res://assets/characters/quaternius"
const ZIP_SHA256: PackedStringArray = [
	"c3468b18871cc8c8f05ab14df7712baf22cb9f389cbd870babf130e595187f70",
	"fdbf1804c90dfc1ea03e992bff7da2dfd1a79318e13270a660180f9308455f40",
	"cc73fc4e495b82958207316596317a3f40b9fa38065bde1027937452da537724",
]
const FANTASY_ROOT: String = "Modular Character Outfits - Fantasy[Standard]/"
const UBC_ROOT: String = "Universal Base Characters[Standard]/"
const UAL_ROOT: String = "Universal Animation Library[Standard]/"
const OUTFITS_DIR: String = FANTASY_ROOT + "Exports/glTF (Godot-Unreal)/Outfits/"
const BODY_DIR: String = UBC_ROOT + "Base Characters/Godot - UE/"
const HAIR_DIR: String = UBC_ROOT + "Hairstyles/Rigged to Head Bone/glTF (Godot -Unreal)/"
const UAL_FILE: String = UAL_ROOT + "Unreal-Godot/UAL1_Standard.glb"
const OUTFITS: PackedStringArray = ["Male_Peasant", "Female_Peasant", "Male_Ranger", "Female_Ranger"]
const BODY_MESH: Dictionary = {"Male": "SuperHero_Male", "Female": "Superhero_Female"}
const HAIRS: PackedStringArray = ["Eyebrows_Female", "Eyebrows_Regular", "Hair_Beard", "Hair_Buns", "Hair_Buzzed", "Hair_BuzzedFemale", "Hair_Long", "Hair_SimpleParted"]
const ANIMATIONS: PackedStringArray = ["Idle_Loop", "Walk_Loop", "Jog_Fwd_Loop", "Idle_Talking_Loop", "Interact", "PickUp_Table"]
const LICENSES: Array[Array] = [[0, FANTASY_ROOT + "License_Standard.txt", "License_Fantasy_Standard.txt"], [1, UBC_ROOT + "License_Standard.txt", "License_UBC_Standard.txt"], [2, UAL_ROOT + "License.txt", "License_UAL.txt"]]
const HEAD_BONES: PackedStringArray = ["Head", "neck_01"]
## Só o que o material usa: o Blender exportou camadas de UV e de cor sem uso (TEXCOORD_1 a 4, COLOR_1 a 3), que só pesam.
const KEEP_ATTRIBUTES: PackedStringArray = ["POSITION", "NORMAL", "TEXCOORD_0", "COLOR_0", "JOINTS_0", "WEIGHTS_0"]
const TEXTURE_SIZE: int = 1024
const TEXTURE_IMPORT: String = "[remap]\n\nimporter=\"texture\"\ntype=\"CompressedTexture2D\"\n\n[params]\n\ncompress/mode=2\ncompress/normal_map=%d\nmipmaps/generate=true\n"
const GLB_IMPORT: String = "[remap]\n\nimporter=\"scene\"\ntype=\"PackedScene\"\n\n[params]\n\nmeshes/ensure_tangents=true\nmeshes/generate_lods=true\nmeshes/create_shadow_meshes=true\n"

var _out: String = OUT_DEFAULT
var _failed: bool = false
var _written: int = 0
var _zip: ZIPReader = null
var _zip_files: PackedStringArray = PackedStringArray()
var _package: String = ""
var _src_dir: String = ""
var _src: Dictionary = {}
var _src_bin: PackedByteArray = PackedByteArray()
var _bin: PackedByteArray = PackedByteArray()
var _views: Array = []
var _accessors: Array = []
var _meshes: Array = []
var _materials: Array = []
var _textures: Array = []
var _images: Array = []
var _acc_map: Dictionary = {}
var _mat_map: Dictionary = {}
var _tex_map: Dictionary = {}
var _done: Dictionary = {}


func _init() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() < 3:
		push_error("uso: tools/assets/process_quaternius <fantasy.zip> <ubc.zip> <ual.zip> [pasta_de_saida]")
		quit(2)
		return
	if args.size() > 3:
		_out = args[3]
	var zips: Array[ZIPReader] = []
	for i: int in ZIP_SHA256.size():
		var reader: ZIPReader = ZIPReader.new()
		if FileAccess.get_sha256(args[i]) != ZIP_SHA256[i] or reader.open(args[i]) != OK:
			push_error("zip ausente ou com SHA-256 diferente do registrado: " + args[i])
			quit(1)
			return
		zips.append(reader)
	_outfits(zips[0])
	_bodies(zips[1])
	_hair(zips[1])
	_open(zips[2], UAL_FILE, "animations")
	_write("animations/UAL1_Standard_Subset.glb", _extract(PackedStringArray(), ANIMATIONS, ""))
	for entry: Array in LICENSES:
		_write(String(entry[2]), (zips[int(entry[0])] as ZIPReader).read_file(String(entry[1])))
	print("process_quaternius: %d arquivos escritos em %s" % [_written, _out])
	quit(1 if _failed else 0)


func _outfits(zip: ZIPReader) -> void:
	for outfit: String in OUTFITS:
		_open(zip, OUTFITS_DIR + outfit + ".gltf", "outfits")
		var groups: Dictionary = {}
		for node_name: String in _mesh_nodes():
			# Tronco e braços vão juntos: a manga e a mão só fazem sentido com o tronco; o resto fica uma peça por arquivo.
			var file: String = outfit + "_Body_Arms" if node_name.trim_prefix(outfit + "_") in ["Body", "Arms"] else node_name
			var list: PackedStringArray = groups.get(file, PackedStringArray())
			list.append(node_name)
			groups[file] = list
		for file: String in groups:
			_write("outfits/" + file + ".glb", _extract(groups[file], PackedStringArray(), ""))


## Do corpo-base só a cabeça (o corpo nu atravessa a roupa) e os olhos; as sobrancelhas vêm dos arquivos de cabelo.
func _bodies(zip: ZIPReader) -> void:
	for gender: String in BODY_MESH:
		_open(zip, BODY_DIR + "Superhero_" + gender + "_FullBody.gltf", "base")
		var body: String = BODY_MESH[gender]
		_write("base/Superhero_" + gender + "_Head.glb", _extract(PackedStringArray(["Eyes", body]), PackedStringArray(), body))


func _hair(zip: ZIPReader) -> void:
	for hair: String in HAIRS:
		_open(zip, HAIR_DIR + hair + ".gltf", "hair")
		_write("hair/" + hair + ".glb", _extract(_mesh_nodes(), PackedStringArray(), ""))


## Lê um glTF do zip (.gltf com o .bin ao lado, ou .glb: cabeçalho de 12 bytes e depois os blocos JSON e BIN).
func _open(zip: ZIPReader, path: String, package: String) -> void:
	_zip = zip
	_zip_files = zip.get_files()
	_package = package
	_src_dir = path.get_base_dir() + "/"
	var raw: PackedByteArray = _read(path)
	if path.ends_with(".glb"):
		var json_len: int = raw.decode_u32(12)
		_src = JSON.parse_string(raw.slice(20, 20 + json_len).get_string_from_utf8())  # Variant: fronteira com JSON
		_src_bin = raw.slice(28 + json_len, 28 + json_len + raw.decode_u32(20 + json_len))
	else:
		_src = JSON.parse_string(raw.get_string_from_utf8())  # Variant: fronteira com JSON
		_src_bin = _read(path.get_basename() + ".bin")


func _read(path: String) -> PackedByteArray:
	if not _zip_files.has(path):
		push_error("não está no zip: " + path)
		_failed = true
		return PackedByteArray()
	return _zip.read_file(path)


func _mesh_nodes() -> PackedStringArray:
	var names: PackedStringArray = PackedStringArray()
	for n: Dictionary in _src["nodes"]:
		if n.has("mesh"):
			names.append(String(n["name"]))
	return names


## Monta um .glb só com as malhas `keep` (nomes de nó), as animações `anims` e o esqueleto inteiro; as texturas ficam fora, reduzidas e
## referenciadas por caminho relativo. Nomes de nós, malhas, materiais e ossos não mudam. `cut`: o nó do corpo-base reduzido à cabeça.
func _extract(keep: PackedStringArray, anims: PackedStringArray, cut: String) -> PackedByteArray:
	_bin = PackedByteArray()
	for list: Array in [_views, _accessors, _meshes, _materials, _textures, _images]:
		list.clear()
	for map: Dictionary in [_acc_map, _mat_map, _tex_map]:
		map.clear()
	var node_map: Dictionary = {}
	var nodes: Array = []
	for i: int in (_src["nodes"] as Array).size():
		var n: Dictionary = _src["nodes"][i]
		if not n.has("mesh") or keep.has(String(n["name"])):
			node_map[i] = nodes.size()
			nodes.append(n.duplicate(true))
	for n: Dictionary in nodes:
		if n.has("children"):
			var kids: Array = []
			for c: Variant in n["children"]:
				if node_map.has(int(c)):
					kids.append(node_map[int(c)])
			n["children"] = kids
		if n.has("mesh"):
			n["mesh"] = _mesh(int(n["mesh"]), String(n["name"]) == cut)
	var skins: Array = []
	for s: Dictionary in _src["skins"]:
		var skin: Dictionary = s.duplicate(true)
		skin["joints"] = (s["joints"] as Array).map(func(j: Variant) -> int: return node_map[int(j)])
		skin["inverseBindMatrices"] = _acc(int(s["inverseBindMatrices"]))
		skins.append(skin)
	var doc: Dictionary = {"asset": {"version": "2.0", "generator": "tools/assets/process_quaternius"}, "scene": 0, "nodes": nodes, "skins": skins,
		"scenes": [{"name": "Scene", "nodes": (_src["scenes"][0]["nodes"] as Array).map(func(r: Variant) -> int: return node_map[int(r)])}],
		"meshes": _meshes, "materials": _materials, "textures": _textures, "images": _images, "samplers": _src.get("samplers", []), "animations": _animations(anims, node_map)}
	for key: String in ["meshes", "materials", "textures", "images", "samplers", "animations"]:
		if (doc[key] as Array).is_empty():
			doc.erase(key)
	while _bin.size() % 4 != 0:
		_bin.append(0)
	doc["accessors"] = _accessors
	doc["bufferViews"] = _views
	doc["buffers"] = [{"byteLength": _bin.size()}]
	return _glb(doc)


func _animations(anims: PackedStringArray, node_map: Dictionary) -> Array:
	var out: Array = []
	for a: Dictionary in _src.get("animations", []):
		if not anims.has(String(a["name"])):
			continue
		var samplers: Array = []
		for s: Dictionary in a["samplers"]:
			samplers.append({"input": _acc(int(s["input"])), "output": _acc(int(s["output"])), "interpolation": s.get("interpolation", "LINEAR")})
		var channels: Array = []
		for c: Dictionary in a["channels"]:
			channels.append({"sampler": int(c["sampler"]), "target": {"node": node_map[int(c["target"]["node"])], "path": c["target"]["path"]}})
		out.append({"name": a["name"], "samplers": samplers, "channels": channels})
	return out


func _mesh(index: int, cut: bool) -> int:
	var src_mesh: Dictionary = _src["meshes"][index]
	var prims: Array = []
	for p: Dictionary in src_mesh["primitives"]:
		prims.append(_primitive(p, cut))
	_meshes.append({"name": src_mesh["name"], "primitives": prims})
	return _meshes.size() - 1


func _primitive(p: Dictionary, cut: bool) -> Dictionary:
	var attrs: Dictionary = p["attributes"]
	var out: Dictionary = {"attributes": {}, "material": _material(int(p["material"]))}
	var order: PackedInt32Array = PackedInt32Array()
	if cut:
		var flags: PackedByteArray = _head_flags(attrs)
		var renumber: PackedInt32Array = PackedInt32Array()
		renumber.resize(flags.size())
		renumber.fill(-1)
		var old: PackedByteArray = _bytes(int(p["indices"]))
		var indices: PackedByteArray = PackedByteArray()
		var index_count: int = 0
		for t: int in range(0, old.size(), 6):
			var tri: Array[int] = [old.decode_u16(t), old.decode_u16(t + 2), old.decode_u16(t + 4)]
			if flags[tri[0]] + flags[tri[1]] + flags[tri[2]] < 3:
				continue
			for v: int in tri:
				if renumber[v] < 0:
					renumber[v] = order.size()
					order.append(v)
				indices.resize(indices.size() + 2)
				indices.encode_u16(indices.size() - 2, renumber[v])
				index_count += 1
		out["indices"] = _add({"componentType": 5123, "count": index_count, "type": "SCALAR"}, indices)
	else:
		out["indices"] = _acc(int(p["indices"]))
	for key: String in KEEP_ATTRIBUTES:
		if attrs.has(key):
			out["attributes"][key] = _gather(int(attrs[key]), order) if cut else _acc(int(attrs[key]))
	return out


## 1 para o vértice cujo osso de maior peso é da cabeça ou do pescoço (JOINTS_0 em ubyte e WEIGHTS_0 em float32, como o Blender exporta).
func _head_flags(attrs: Dictionary) -> PackedByteArray:
	var skin: Dictionary = _src["skins"][0]
	var head_joints: Array[int] = []
	for j: int in (skin["joints"] as Array).size():
		if HEAD_BONES.has(String(_src["nodes"][int(skin["joints"][j])]["name"])):
			head_joints.append(j)
	var joints: PackedByteArray = _bytes(int(attrs["JOINTS_0"]))
	var weights: PackedByteArray = _bytes(int(attrs["WEIGHTS_0"]))
	var flags: PackedByteArray = PackedByteArray()
	flags.resize(int(_src["accessors"][int(attrs["POSITION"])]["count"]))
	for v: int in flags.size():
		var best: int = 0
		for k: int in 4:
			if weights.decode_float(v * 16 + k * 4) > weights.decode_float(v * 16 + best * 4):
				best = k
		flags[v] = 1 if head_joints.has(joints[v * 4 + best]) else 0
	return flags


func _material(index: int) -> int:
	if not _mat_map.has(index):
		var m: Dictionary = (_src["materials"] as Array)[index].duplicate(true)
		for holder: Dictionary in [m, m.get("pbrMetallicRoughness", {})]:
			for key: String in ["baseColorTexture", "metallicRoughnessTexture", "normalTexture", "occlusionTexture", "emissiveTexture"]:
				if holder.has(key):
					holder[key]["index"] = _texture(int(holder[key]["index"]))
		_mat_map[index] = _materials.size()
		_materials.append(m)
	return _mat_map[index]


## A textura vira um WebP SEM perdas de até 1024 px (sem canal alfa quando ele é todo opaco), com um nome só para o pacote inteiro.
func _texture(index: int) -> int:
	if not _tex_map.has(index):
		var t: Dictionary = (_src["textures"] as Array)[index].duplicate(true)
		# O Blender apontou duas texturas por um nome com "_png" que não existe no zip; o arquivo certo é o de nome sem o sufixo.
		var uri: String = String(_src["images"][int(t["source"])]["uri"]).uri_decode().replace("_png.png", ".png")
		var file: String = uri.get_file().get_basename() + ".webp"
		var rel: String = _package + "/textures/" + file
		if not _done.has(rel):
			_done[rel] = true
			var img: Image = Image.new()
			_failed = img.load_png_from_buffer(_read(_src_dir + uri)) != OK or _failed
			if img.get_width() > TEXTURE_SIZE:
				img.resize(TEXTURE_SIZE, TEXTURE_SIZE, Image.INTERPOLATE_LANCZOS)
			if img.get_format() == Image.FORMAT_RGBA8 and img.detect_alpha() == Image.ALPHA_NONE:
				img.convert(Image.FORMAT_RGB8)
			_write(rel, img.save_webp_to_buffer(false, 1.0))
		t["source"] = _images.size()
		_images.append({"uri": "textures/" + file, "name": file.get_basename(), "mimeType": "image/webp"})
		_tex_map[index] = _textures.size()
		_textures.append(t)
	return _tex_map[index]


## Bytes do bufferView do accessor (cada accessor tem o seu bufferView nestes arquivos).
func _bytes(accessor: int) -> PackedByteArray:
	var view: Dictionary = _src["bufferViews"][int(_src["accessors"][accessor]["bufferView"])]
	var start: int = int(view.get("byteOffset", 0))
	return _src_bin.slice(start, start + int(view["byteLength"]))


func _acc(index: int) -> int:
	if not _acc_map.has(index):
		var a: Dictionary = (_src["accessors"] as Array)[index].duplicate(true)
		_acc_map[index] = _add(a, _bytes(index), _src["bufferViews"][int(a["bufferView"])])
	return _acc_map[index]


## Accessor novo só com os vértices de `order` (já na ordem nova); POSITION recalcula min e max, como o glTF manda.
func _gather(index: int, order: PackedInt32Array) -> int:
	var a: Dictionary = (_src["accessors"] as Array)[index].duplicate(true)
	var raw: PackedByteArray = _bytes(index)
	var size: int = floori(raw.size() / float(a["count"]))
	var data: PackedByteArray = PackedByteArray()
	for v: int in order:
		data.append_array(raw.slice(v * size, v * size + size))
	a["count"] = order.size()
	if a.has("min"):
		var f: PackedFloat32Array = data.to_float32_array()
		var low: Vector3 = Vector3.INF
		var high: Vector3 = -Vector3.INF
		for i: int in range(0, f.size(), 3):
			low = low.min(Vector3(f[i], f[i + 1], f[i + 2]))
			high = high.max(Vector3(f[i], f[i + 1], f[i + 2]))
		a["min"] = [low.x, low.y, low.z]
		a["max"] = [high.x, high.y, high.z]
	return _add(a, data, _src["bufferViews"][int(a["bufferView"])])


func _add(accessor: Dictionary, data: PackedByteArray, src_view: Dictionary = {}) -> int:
	while _bin.size() % 4 != 0:
		_bin.append(0)
	var view: Dictionary = {"buffer": 0, "byteOffset": _bin.size(), "byteLength": data.size()}
	for key: String in ["byteStride", "target"]:
		if src_view.has(key):
			view[key] = src_view[key]
	_bin.append_array(data)
	_views.append(view)
	accessor["bufferView"] = _views.size() - 1
	_accessors.append(accessor)
	return _accessors.size() - 1


func _glb(doc: Dictionary) -> PackedByteArray:
	# O JSON do Godot escreve 5126 como 5126.0, e o glTF exige inteiro em índices e contagens.
	var whole: RegEx = RegEx.create_from_string("(?<=\\d)\\.0(?=[,\\]}])")
	var json: PackedByteArray = whole.sub(JSON.stringify(doc), "", true).to_utf8_buffer()
	while json.size() % 4 != 0:
		json.append(0x20)
	var out: StreamPeerBuffer = StreamPeerBuffer.new()
	for word: int in [0x46546C67, 2, 28 + json.size() + _bin.size(), json.size(), 0x4E4F534A]:
		out.put_u32(word)
	out.put_data(json)
	for word: int in [_bin.size(), 0x004E4942]:
		out.put_u32(word)
	out.put_data(_bin)
	return out.data_array


## Grava o arquivo e, para WebP e GLB, o .import com as configurações que ficam versionadas (VRAM S3TC com mipmaps; LOD nas malhas).
func _write(rel: String, data: PackedByteArray) -> void:
	var path: String = _out.path_join(rel)
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	file.store_buffer(data)
	file.close()
	_written += 1
	var template: String = {"webp": TEXTURE_IMPORT % (1 if rel.contains("_Normal") else 0), "glb": GLB_IMPORT}.get(path.get_extension(), "")
	if not template.is_empty():
		var imp: FileAccess = FileAccess.open(path + ".import", FileAccess.WRITE)
		imp.store_string(template)
		imp.close()
