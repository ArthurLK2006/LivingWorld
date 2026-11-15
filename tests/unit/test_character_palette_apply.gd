extends GutTest
## ART-12, entrega 4b: a paleta dos personagens (CharacterPainter) com os ativos, o catálogo e as paletas REAIS (sem janela). Os `instance uniform` de cada malha batem com a paleta da ficha; fichas diferentes dão valores diferentes e a mesma ficha dá os mesmos; paleta neutra deixa tudo neutro; olhos, couro e metal não recebem o deslocamento de pano; o material é compartilhado (nenhum por personagem) e mantém a textura, o normal map e a rugosidade do original; falhas devolvem falso sem mudar nada; a peça trocada em tempo de execução recebe a paleta; nenhum nó órfão. O sombreador em si só se confere na janela (as capturas da entrega).

const OUTFITS: String = "res://assets/characters/quaternius/outfits/"
## Corpo, roupa, cabelo, sobrancelha e barba (o quinto item, "" = sem barba).
const MALE_PEASANT: Array = ["male_a", "peasant_m", "buzzed", "brow_regular", ""]
const MALE_RANGER: Array = ["male_a", "ranger_m", "simple_parted", "brow_regular", "beard_01"]
const FEMALE_RANGER: Array = ["female_a", "ranger_f", "buns", "brow_female", ""]
## A classe de cada material original, escrita aqui à parte do pintor (o oráculo dos testes).
const CLASS_OF: Dictionary = {"MI_Peasant": "cloth", "MI_Ranger": "cloth", "MI_Superhero_Male": "skin", "MI_Superhero_Female": "skin", "MI_Regular_Male": "skin", "MI_Regular_Female": "skin", "MI_Hair_1": "hair", "MI_Hair_2": "hair"}
const LEATHER_MESHES: PackedStringArray = ["Male_Ranger_Feet_Boots", "Male_Ranger_Body_Belt_1", "Male_Ranger_Body_Belt_2", "Male_Ranger_Arms_Bracer", "Male_Ranger_Acc_Pauldron"]
const CLOTH_MESHES: PackedStringArray = ["Male_Ranger_Body", "Male_Ranger_Legs", "Male_Ranger_Head_Hood"]
const LOOKS_COUNT: int = 12
## O prefixo das propriedades de `instance uniform` que o Godot lista em cada malha (só as que o sombreador do material declara) e os nomes que o pintor escreve.
const INSTANCE_PREFIX: String = "instance_shader_parameters/"
const WRITTEN_UNIFORMS: Array[StringName] = [&"pal", &"leather_val", &"leather_piece", &"tint"]

var _catalog: CharacterCatalog
var _palettes: CharacterPalettes
var _painter: CharacterPainter


func before_all() -> void:
	var catalog: CharacterCatalog.LoadResult = CharacterCatalog.from_file()
	var palettes: CharacterPalettes.LoadResult = CharacterPalettes.from_file()
	assert_true(catalog.result.ok and palettes.result.ok, "catálogo e paletas reais carregam")
	_catalog = catalog.catalog
	_palettes = palettes.palettes


func before_each() -> void:
	_painter = CharacterPainter.new(_palettes)


func _look(combo: Array, cloth: int, skin: int, hair_tone: int) -> CharacterAppearance:
	var look: CharacterAppearance = CharacterAppearance.new()
	look.body_id = combo[0]
	look.outfit_id = combo[1]
	look.hair_id = combo[2]
	look.eyebrow_id = combo[3]
	look.beard_id = combo[4]
	look.cloth_palette_index = cloth
	look.skin_index = skin
	look.hair_tone_index = hair_tone
	return look


func _built(look: CharacterAppearance) -> CharacterAssembler:
	var assembler: CharacterAssembler = add_child_autofree(CharacterAssembler.new())
	assert_true(assembler.build(look, _catalog), "montou " + look.outfit_id)
	return assembler


func _painted(look: CharacterAppearance) -> CharacterAssembler:
	var assembler: CharacterAssembler = _built(look)
	assert_true(_painter.apply(assembler, look), "pintou " + look.outfit_id)
	return assembler


func _index_of(kind: String, id: String) -> int:
	for index: int in _palettes.count(kind):
		if _palettes.entry(kind, index)["id"] == id:
			return index
	return -1


func _mesh(assembler: CharacterAssembler, mesh_name: String) -> MeshInstance3D:
	for mesh: MeshInstance3D in CharacterSceneLoader.meshes_of(assembler):
		if String(mesh.name) == mesh_name:
			return mesh
	return null


func _kind(mesh: MeshInstance3D, surface: int) -> String:
	return CLASS_OF.get(mesh.mesh.surface_get_material(surface).resource_name, "")


## Os valores do pano da paleta; `hue_locked` é o Ranger (sem giro de matiz).
func _cloth_values(index: int, hue_locked: bool = false) -> Array:
	var row: Dictionary = _palettes.entry("cloth", index)
	var hue: float = 0.0 if hue_locked else row["hue_deg"] / 360.0
	return [Vector4(hue, row["sat_permille"] / 1000.0, row["val_permille"] / 1000.0, row["sat_add_permille"] / 1000.0), row["leather_val_permille"] / 1000.0]


func _tint_value(kind: String, index: int) -> Vector3:
	var row: Dictionary = _palettes.entry(kind, index)
	var linear: Color = Color(row["r_permille"] / 1000.0, row["g_permille"] / 1000.0, row["b_permille"] / 1000.0).srgb_to_linear()
	return Vector3(linear.r, linear.g, linear.b)


## Tudo que a pintura pôs em cada malha: nome -> texto dos `instance uniform` e dos materiais (para comparar personagens).
func _snapshot(assembler: CharacterAssembler) -> Dictionary:
	var shot: Dictionary = {}
	for mesh: MeshInstance3D in CharacterSceneLoader.meshes_of(assembler):
		var materials: Array = []
		for surface: int in mesh.mesh.get_surface_count():
			materials.append(mesh.get_surface_override_material(surface))
		shot[String(mesh.name)] = [mesh.get_instance_shader_parameter(&"pal"), mesh.get_instance_shader_parameter(&"leather_val"), mesh.get_instance_shader_parameter(&"leather_piece"), mesh.get_instance_shader_parameter(&"tint"), materials]
	return shot


func test_every_mesh_gets_the_values_of_the_palettes_in_the_look_and_keeps_the_original_textures() -> void:
	for combo: Array in [MALE_RANGER, FEMALE_RANGER]:
		var look: CharacterAppearance = _look(combo, 2, 4, 3) if combo == MALE_RANGER else _look(combo, 7, 5, 5)
		var cloth: Array = _cloth_values(look.cloth_palette_index, true)
		var painted: int = 0
		for mesh: MeshInstance3D in CharacterSceneLoader.meshes_of(_painted(look)):
			for surface: int in mesh.mesh.get_surface_count():
				var original: BaseMaterial3D = mesh.mesh.surface_get_material(surface)
				var shared: ShaderMaterial = mesh.get_surface_override_material(surface) as ShaderMaterial
				var kind: String = _kind(mesh, surface)
				var label: String = "%s %s" % [combo[1], mesh.name]
				if kind.is_empty():
					assert_null(mesh.get_surface_override_material(surface), "olhos e material desconhecido ficam como estão: " + label)
					continue
				painted += 1
				assert_not_null(shared, "material compartilhado: " + label)
				assert_true(original is StandardMaterial3D, "o material original da malha não foi trocado: " + label)
				assert_true(shared.get_shader_parameter(&"tex_albedo") == original.albedo_texture and shared.get_shader_parameter(&"tex_normal") == original.normal_texture and shared.get_shader_parameter(&"tex_orm") == original.roughness_texture, "mesma textura, normal map e rugosidade: " + label)
				assert_eq([shared.get_shader_parameter(&"rough_factor"), shared.get_shader_parameter(&"metal_factor")], [original.roughness, original.metallic], "mesmos fatores: " + label)
				if kind == "cloth":
					assert_true(mesh.get_instance_shader_parameter(&"pal").is_equal_approx(cloth[0]), "pal: " + label)
					assert_almost_eq(float(mesh.get_instance_shader_parameter(&"leather_val")), float(cloth[1]), 0.0001, "leather_val: " + label)
				else:
					var index: int = look.skin_index if kind == "skin" else look.hair_tone_index
					assert_true(mesh.get_instance_shader_parameter(&"tint").is_equal_approx(_tint_value(kind, index)), "tint de %s: %s" % [kind, label])
		assert_gt(painted, 0, "pintou alguma superfície: " + combo[1])


func test_every_instance_uniform_the_painter_writes_is_declared_by_the_shader() -> void:
	var checked: int = 0
	for combo: Array in [MALE_RANGER, MALE_PEASANT]:
		for mesh: MeshInstance3D in CharacterSceneLoader.meshes_of(_painted(_look(combo, 2, 4, 3))):
			var declared: Dictionary = {}
			for property: Dictionary in mesh.get_property_list():
				var property_name: String = property["name"]
				if property_name.begins_with(INSTANCE_PREFIX):
					declared[property_name.trim_prefix(INSTANCE_PREFIX)] = true
			for uniform_name: StringName in WRITTEN_UNIFORMS:
				if mesh.get_instance_shader_parameter(uniform_name) != null:
					assert_true(declared.has(String(uniform_name)), "o sombreador declara o que o pintor escreve: %s em %s" % [uniform_name, mesh.name])
					checked += 1
	assert_gt(checked, 20, "conferiu os valores de várias malhas")


func test_other_looks_give_other_values_and_the_same_look_gives_the_same_values() -> void:
	var base: Dictionary = _snapshot(_painted(_look(MALE_RANGER, 2, 4, 3)))
	assert_eq(_snapshot(_painted(_look(MALE_RANGER, 2, 4, 3))), base, "a mesma ficha dá os mesmos valores (e os mesmos materiais)")
	var other_cloth: Dictionary = _snapshot(_painted(_look(MALE_RANGER, 0, 4, 3)))
	var other_skin: Dictionary = _snapshot(_painted(_look(MALE_RANGER, 2, 1, 3)))
	var other_hair: Dictionary = _snapshot(_painted(_look(MALE_RANGER, 2, 4, 5)))
	assert_ne(other_cloth["Male_Ranger_Legs"][0], base["Male_Ranger_Legs"][0], "outro pano: outro pal")
	assert_eq([other_cloth["SuperHero_Male"][3], other_cloth["Hair_SimpleParted"][3]], [base["SuperHero_Male"][3], base["Hair_SimpleParted"][3]], "e a pele e o cabelo ficam")
	assert_ne(other_skin["SuperHero_Male"][3], base["SuperHero_Male"][3], "outra pele: outro tint no rosto")
	assert_eq([other_skin["Male_Ranger_Legs"][0], other_skin["Hair_SimpleParted"][3]], [base["Male_Ranger_Legs"][0], base["Hair_SimpleParted"][3]], "e o pano e o cabelo ficam")
	assert_ne(other_hair["Hair_SimpleParted"][3], base["Hair_SimpleParted"][3], "outro cabelo: outro tint")
	assert_eq(other_hair["SuperHero_Male"][3], base["SuperHero_Male"][3], "e a pele fica")
	var seen: Dictionary = {}
	for npc_id: int in range(1, LOOKS_COUNT + 1):
		var look: CharacterAppearance = CharacterAppearance.of(npc_id, _catalog, _palettes)
		var shot: Dictionary = _snapshot(_painted(look))
		assert_eq(_snapshot(_painted(CharacterAppearance.of(npc_id, _catalog, _palettes))), shot, "o NPC %d dá os mesmos valores de novo" % npc_id)
		seen[str(look.cloth_palette_index) + str(look.skin_index) + str(look.hair_tone_index)] = true
	assert_gt(seen.size(), 6, "os NPCs 1 a 12 têm paletas bem diferentes")


func test_the_neutral_palettes_leave_the_instance_uniforms_neutral() -> void:
	var neutral: Dictionary = _snapshot(_painted(_look(MALE_RANGER, _index_of("cloth", "sand"), _index_of("skin", "base"), _index_of("hair", "natural"))))
	assert_eq(neutral["Male_Ranger_Legs"][0], Vector4(0.0, 1.0, 1.0, 0.0), "pano neutro: sem giro de matiz, escalas 1 e sem saturação somada")
	assert_eq(neutral["Male_Ranger_Legs"][1], 1.0, "e o couro sem mudança de valor")
	assert_true(neutral["SuperHero_Male"][3].is_equal_approx(Vector3.ONE) and neutral["Hair_SimpleParted"][3].is_equal_approx(Vector3.ONE), "pele e cabelo neutros multiplicam por 1")


func test_the_ranger_keeps_its_hue_and_the_peasant_still_turns_it() -> void:
	var slate: int = _index_of("cloth", "slate")
	var row: Dictionary = _palettes.entry("cloth", slate)
	assert_ne(row["hue_deg"], 0, "a paleta do teste gira o matiz")
	var ranger: Dictionary = _snapshot(_painted(_look(MALE_RANGER, slate, 0, 0)))
	var peasant: Dictionary = _snapshot(_painted(_look(MALE_PEASANT, slate, 0, 0)))
	for mesh_name: String in CLOTH_MESHES:
		var pal: Vector4 = ranger[mesh_name][0]
		assert_eq(pal.x, 0.0, "o Ranger não gira o matiz: " + mesh_name)
		assert_true(is_equal_approx(pal.y, row["sat_permille"] / 1000.0) and is_equal_approx(pal.z, row["val_permille"] / 1000.0) and is_equal_approx(pal.w, row["sat_add_permille"] / 1000.0), "mas muda saturação, valor e saturação somada: " + mesh_name)
	var peasant_pal: Vector4 = peasant["Male_Peasant_Legs"][0]
	assert_almost_eq(peasant_pal.x, row["hue_deg"] / 360.0, 0.0001, "o Peasant gira o matiz da tabela")
	assert_eq(_snapshot(_painted(_look(MALE_RANGER, slate, 0, 0))), ranger, "e a trava não depende da ordem nem do estado")


func test_eyes_leather_and_metal_pieces_do_not_get_the_cloth_shift() -> void:
	var assembler: CharacterAssembler = _painted(_look(MALE_RANGER, 2, 4, 3))
	var eyes: MeshInstance3D = _mesh(assembler, "Eyes")
	assert_null(eyes.get_surface_override_material(0), "os olhos ficam como estão")
	assert_null(eyes.get_instance_shader_parameter(&"pal"), "e sem pal")
	assert_null(eyes.get_instance_shader_parameter(&"tint"), "e sem tint")
	for mesh_name: String in ["SuperHero_Male", "Hair_SimpleParted", "Eyebrows_Regular", "Hair_Beard"]:
		assert_null(_mesh(assembler, mesh_name).get_instance_shader_parameter(&"pal"), "pele, cabelo, sobrancelha e barba não têm pal: " + mesh_name)
	for mesh_name: String in LEATHER_MESHES:
		assert_eq(_mesh(assembler, mesh_name).get_instance_shader_parameter(&"leather_piece"), 1.0, "peça de couro ou metal: " + mesh_name)
	for mesh_name: String in CLOTH_MESHES:
		assert_eq(_mesh(assembler, mesh_name).get_instance_shader_parameter(&"leather_piece"), 0.0, "peça de pano: " + mesh_name)
		assert_null(_mesh(assembler, mesh_name).get_instance_shader_parameter(&"tint"), "o pano não leva o tint da pele: " + mesh_name)
	var arms: MeshInstance3D = _mesh(assembler, "Male_Ranger_Arms")
	assert_eq(arms.get_instance_shader_parameter(&"leather_piece"), 0.0, "os braços são de pano")
	assert_eq(arms.mesh.get_surface_count(), 2, "os braços têm pano e pele")
	assert_ne(arms.get_surface_override_material(0), arms.get_surface_override_material(1), "cada superfície com o material da sua classe")
	assert_true(arms.get_instance_shader_parameter(&"pal") != null and arms.get_instance_shader_parameter(&"tint") != null, "e os dois grupos de valores na mesma malha")


func test_the_materials_are_shared_between_characters_and_do_not_grow_with_them() -> void:
	var materials: Dictionary = {}
	var kinds: Dictionary = {}
	for npc_id: int in range(1, LOOKS_COUNT + 1):
		for mesh: MeshInstance3D in CharacterSceneLoader.meshes_of(_painted(CharacterAppearance.of(npc_id, _catalog, _palettes))):
			for surface: int in mesh.mesh.get_surface_count():
				var shared: Material = mesh.get_surface_override_material(surface)
				if shared != null:
					var original: BaseMaterial3D = mesh.mesh.surface_get_material(surface)
					materials[shared] = true
					kinds[[_kind(mesh, surface), original.albedo_texture, original.roughness]] = true
	assert_eq(materials.size(), kinds.size(), "um material por classe e conjunto de texturas, não por personagem nem por peça")
	var first: Dictionary = _snapshot(_painted(_look(MALE_RANGER, 0, 0, 0)))
	var second: Dictionary = _snapshot(_painted(_look(MALE_RANGER, 5, 3, 2)))
	assert_eq(second["Male_Ranger_Legs"][4], first["Male_Ranger_Legs"][4], "dois personagens, o mesmo material na mesma peça")
	assert_eq(second["SuperHero_Male"][4], first["SuperHero_Male"][4], "inclusive na pele")


func test_failures_return_false_without_error_and_change_nothing() -> void:
	var look: CharacterAppearance = _look(MALE_PEASANT, 0, 0, 0)
	var assembler: CharacterAssembler = _built(look)
	var before: Dictionary = _snapshot(assembler)
	var empty: CharacterAssembler = autofree(CharacterAssembler.new())
	assert_false(_painter.apply(empty, look), "montador vazio")
	assert_false(_painter.apply(null, look), "sem montador")
	assert_false(_painter.apply(assembler, null), "sem ficha")
	assert_false(_painter.apply(assembler, CharacterAppearance.new()), "ficha vazia")
	assert_false(CharacterPainter.new(null).apply(assembler, look), "sem tabela de paletas")
	assert_false(CharacterPainter.new(CharacterPalettes.new()).apply(assembler, look), "tabela de paletas vazia")
	for out_of_range: Array in [[99, 0, 0], [0, 99, 0], [0, 0, 99], [-1, 0, 0]]:
		assert_false(_painter.apply(assembler, _look(MALE_PEASANT, out_of_range[0], out_of_range[1], out_of_range[2])), "índice fora da tabela: " + str(out_of_range))
	assert_eq(_snapshot(assembler), before, "nenhuma falha mudou nada (nem material, nem valor)")
	assert_null(_mesh(assembler, "Male_Peasant_Legs").get_surface_override_material(0), "continua o material original")


func test_a_part_swapped_at_runtime_gets_the_palette_and_a_new_build_drops_it() -> void:
	var look: CharacterAppearance = _look(MALE_PEASANT, 2, 4, 3)
	var assembler: CharacterAssembler = _painted(look)
	var cloth: Array = _cloth_values(2, true)
	assert_true(assembler.swap_part(CharacterAssembler.SLOT_LEGS, OUTFITS + "Male_Ranger_Legs.glb"))
	var legs: MeshInstance3D = _mesh(assembler, "Male_Ranger_Legs")
	assert_true(legs.get_surface_override_material(0) is ShaderMaterial and legs.get_instance_shader_parameter(&"pal").is_equal_approx(cloth[0]), "as calças novas já vêm com a paleta")
	assert_true(assembler.swap_part(CharacterAssembler.SLOT_BOOTS, OUTFITS + "Male_Ranger_Feet_Boots.glb"))
	assert_eq(_mesh(assembler, "Male_Ranger_Feet_Boots").get_instance_shader_parameter(&"leather_piece"), 1.0, "as botas novas são de couro")
	assert_true(assembler.swap_part(CharacterAssembler.SLOT_HAIR, "res://assets/characters/quaternius/hair/Hair_SimpleParted.glb"))
	assert_true(_mesh(assembler, "Hair_SimpleParted").get_instance_shader_parameter(&"tint").is_equal_approx(_tint_value("hair", 3)), "o cabelo novo leva o tom da ficha")
	assert_false(assembler.swap_part(CharacterAssembler.SLOT_LEGS, OUTFITS + "Missing_Legs.glb"), "peça ausente")
	assert_true(_mesh(assembler, "Male_Ranger_Legs").get_instance_shader_parameter(&"pal").is_equal_approx(cloth[0]), "e a falha deixa a peça atual pintada")
	assert_true(assembler.swap_part(CharacterAssembler.SLOT_HAIR, ""), "tirar a peça não chama a pintura em nada")
	assembler.set_paint(Callable())
	assert_true(assembler.swap_part(CharacterAssembler.SLOT_HAIR, "res://assets/characters/quaternius/hair/Hair_Buzzed.glb"))
	assert_null(_mesh(assembler, "Hair_Buzzed").get_surface_override_material(0), "sem pintura guardada, a peça nova fica como é")
	assert_true(_painter.apply(assembler, look))
	assembler.clear()
	assert_true(assembler.build(look, _catalog))
	assert_null(_mesh(assembler, "Male_Peasant_Legs").get_surface_override_material(0), "montar de novo descarta a pintura da ficha anterior")


func test_painting_and_clearing_leave_no_orphan_nodes() -> void:
	var orphans_before: int = int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
	var loose: CharacterAssembler = CharacterAssembler.new()
	var look: CharacterAppearance = _look(FEMALE_RANGER, 1, 2, 3)
	assert_true(loose.build(look, _catalog))
	assert_true(_painter.apply(loose, look))
	assert_true(loose.swap_part(CharacterAssembler.SLOT_BOOTS, OUTFITS + "Female_Peasant_Feet.glb"))
	assert_true(_painter.apply(loose, look), "pintar de novo")
	assert_false(_painter.apply(loose, CharacterAppearance.new()))
	loose.clear()
	assert_false(_painter.apply(loose, look), "depois do clear() não há o que pintar")
	assert_true(loose.build(look, _catalog))
	assert_true(_painter.apply(loose, look))
	loose.free()
	assert_eq(int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)), orphans_before, "nenhum nó órfão")
