extends GutTest
## ART-12 (entrega 2): ativos CC0 da Quaternius. O catálogo de dados segue o esquema e todo caminho dele existe e carrega; peças e animações
## usam o esqueleto de 65 ossos; o diretório respeita o teto de tamanho; os .import versionados pedem VRAM com mipmaps e LOD; e o manifesto
## cita o SHA-256 de cada arquivo versionado. Sem janela e sem os pacotes originais (que ficam fora do Git).

const CATALOG: String = "res://data/presentation/character_catalog.json"
const ASSETS: String = "res://assets/characters/quaternius"
const MANIFEST: String = "res://docs/arte/MANIFESTO_LICENCAS.md"
const MAX_BYTES: int = 20 * 1024 * 1024
const BONES: int = 65
const GENDERS: Dictionary = {"bodies": ["male", "female"], "outfits": ["male", "female"], "hair": ["male", "female", "any"]}
const SCENE_KEY: Dictionary = {"bodies": "head_scene", "hair": "scene", "eyebrows": "scene"}
const REQUIRED_ANIMATIONS: Array[String] = ["idle", "walk"]


func _catalog() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CATALOG))  # Variant: fronteira com JSON
	assert_true(parsed is Dictionary, "catálogo ausente ou com JSON inválido: " + CATALOG)
	return parsed if parsed is Dictionary else {}


## Todo caminho res:// do catálogo, em qualquer profundidade; `skip` tira uma chave do primeiro nível (as animações).
func _paths(node: Variant, skip: String = "") -> PackedStringArray:
	var out: PackedStringArray = PackedStringArray()
	if node is Dictionary:
		for key: Variant in (node as Dictionary):
			if String(key) != skip:
				out.append_array(_paths(node[key]))
	elif node is Array:
		for item: Variant in (node as Array):
			out.append_array(_paths(item))
	elif node is String and String(node).begins_with("res://"):
		out.append(String(node))
	return out


func _files(dir: String) -> PackedStringArray:
	var out: PackedStringArray = PackedStringArray()
	for file: String in DirAccess.get_files_at(dir):
		out.append(dir.path_join(file))
	for sub: String in DirAccess.get_directories_at(dir):
		out.append_array(_files(dir.path_join(sub)))
	return out


func _instance(path: String) -> Node:
	var scene: PackedScene = load(path) as PackedScene
	assert_not_null(scene, "não carregou: " + path)
	return scene.instantiate() if scene != null else Node.new()


func test_catalog_follows_the_schema() -> void:
	var c: Dictionary = _catalog()
	assert_eq(int(c.get("version", 0)), 1, "version")
	assert_eq(int(c.get("skeleton_bones", 0)), BONES, "skeleton_bones")
	for group: String in ["bodies", "outfits", "hair", "eyebrows"]:
		var entries: Array = c.get(group, [])
		var ids: Dictionary = {}
		assert_gt(entries.size(), 1, group + ": deveria ter ao menos dois itens")
		for e: Dictionary in entries:
			assert_true(e.get("id") is String and not ids.has(e["id"]), group + ": id ausente ou repetido")
			ids[e["id"]] = true
			assert_true(not GENDERS.has(group) or (GENDERS[group] as Array).has(e.get("gender")), "%s/%s: gênero inválido" % [group, e["id"]])
			assert_true(not SCENE_KEY.has(group) or e.get(SCENE_KEY[group]) is String, "%s/%s: falta a cena" % [group, e["id"]])
			if group == "outfits":
				var parts: Dictionary = e.get("parts", {})
				for slot: String in ["torso_arms", "legs", "boots"]:
					assert_true(parts.get(slot) is String, "%s: falta a peça %s" % [e["id"], slot])
				assert_true(parts.get("extras") is Array, e["id"] + ": extras deve ser lista")
	var animations: Dictionary = c.get("animations", {})
	for key: String in REQUIRED_ANIMATIONS:
		assert_true(animations.has(key), "falta a animação " + key)
	for key: String in animations:
		assert_true(animations[key].get("path") is String and animations[key].get("name") is String, "animação " + key + " sem path ou name")


func test_every_catalog_path_loads_with_the_65_bone_skeleton_and_imported_textures() -> void:
	var paths: PackedStringArray = _paths(_catalog())
	assert_gt(paths.size(), 30, "poucos caminhos no catálogo")
	for path: String in paths:
		assert_true(ResourceLoader.exists(path), "não existe em res://: " + path)
		var root: Node = _instance(path)
		var skeletons: Array[Node] = root.find_children("*", "Skeleton3D", true, false)
		assert_eq(skeletons.size(), 1, path + ": um esqueleto")
		if skeletons.size() == 1:
			assert_eq((skeletons[0] as Skeleton3D).get_bone_count(), BONES, path + ": ossos")
		var meshes: Array[Node] = root.find_children("*", "MeshInstance3D", true, false)
		assert_eq(meshes.is_empty(), path.contains("/animations/"), path + ": malhas só nas peças, nunca no arquivo de animações")
		for mesh: MeshInstance3D in meshes:
			for s: int in mesh.mesh.get_surface_count():
				var material: BaseMaterial3D = mesh.mesh.surface_get_material(s) as BaseMaterial3D
				assert_true(material != null and material.albedo_texture is CompressedTexture2D, "%s/%s: textura importada ausente" % [path, mesh.name])
		root.free()


func test_requested_animations_exist_with_positive_duration() -> void:
	var animations: Dictionary = _catalog().get("animations", {})
	for key: String in animations:
		var root: Node = _instance(String(animations[key]["path"]))
		var players: Array[Node] = root.find_children("*", "AnimationPlayer", true, false)
		var anim_name: StringName = StringName(String(animations[key]["name"]))
		assert_eq(players.size(), 1, key + ": um AnimationPlayer")
		if players.size() == 1:
			var player: AnimationPlayer = players[0] as AnimationPlayer
			assert_true(player.has_animation(anim_name), "%s: não existe a animação %s" % [key, anim_name])
			assert_gt(player.get_animation(anim_name).length if player.has_animation(anim_name) else 0.0, 0.0, key + ": duração positiva")
		root.free()


func test_asset_directory_stays_under_the_size_cap() -> void:
	var total: int = 0
	for path: String in _files(ASSETS):
		total += FileAccess.open(path, FileAccess.READ).get_length()
	assert_between(total, 1, MAX_BYTES, "tamanho do diretório de ativos, em bytes")


func test_versioned_imports_request_vram_mipmaps_and_lod() -> void:
	var textures: int = 0
	var scenes: int = 0
	for path: String in _files(ASSETS):
		var text: String = FileAccess.get_file_as_string(path) if path.ends_with(".import") else ""
		if path.ends_with(".webp.import"):
			textures += 1
			assert_true(text.contains("compress/mode=2") and text.contains("mipmaps/generate=true"), path + ": VRAM com mipmaps")
			assert_eq(text.contains("compress/normal_map=1"), path.contains("_Normal"), path + ": mapa de normais")
		elif path.ends_with(".glb.import"):
			scenes += 1
			assert_true(text.contains("meshes/generate_lods=true"), path + ": geração de LOD")
	assert_gt(textures, 20, "texturas importadas")
	assert_gt(scenes, 30, "cenas importadas")


func test_manifest_cites_the_sha256_of_every_versioned_file() -> void:
	var manifest: String = FileAccess.get_file_as_string(MANIFEST)
	var checked: int = 0
	for path: String in _files(ASSETS):
		if not path.ends_with(".import"):
			assert_true(manifest.contains(FileAccess.get_sha256(path)), "o manifesto não cita o SHA-256 de " + path)
			checked += 1
	assert_gt(checked, 55, "arquivos versionados conferidos")
