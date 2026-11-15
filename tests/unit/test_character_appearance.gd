extends GutTest
## ART-12, entrega 3: a ficha de aparência (CharacterAppearance) é função PURA do `npc_id` e das tabelas. Catálogo: o fixture de tests/unit/support (arquivos reais do projeto); paletas: o arquivo real. Determinismo (duas cargas, duas instâncias, ordens de consulta diferentes, valores de referência do hash conferidos também em Python), variedade nos 132 NPCs, faixas e tabelas, ids de borda (0, negativos, 2^31-1), catálogo não carregado e isolamento da pasta (sem sorteio, relógio, print, Node nem tipo de src/sim).

const CATALOG_FIXTURE: String = "res://tests/unit/support/character_catalog_ok.json"
const CHARACTERS_DIR: String = "res://src/presentation/world_view/characters"
const APPEARANCE_FILE: String = "character_appearance.gd"
const WORLD_NPCS: int = 132
const STRIDE: int = 37
const EDGE_IDS: Array[int] = [1000, 2147483647]
const ODD_IDS: Array[int] = [0, -1, -2147483648]
const MIN_DISTINCT_LOOKS: int = 40
const MIN_USES_PER_OUTFIT: int = 5
## mix32 de alguns valores, calculados também em Python (mesmo algoritmo, mascarando a cada passo).
const GOLDEN_MIX: Dictionary = {0: 0, 1: 2261973619, 2147483647: 1289417537, -1: 2578835075}
const GOLDEN_BODY_HASH_OF_1: int = 2139722617
## A aparência (sem o id) de alguns NPCs com o fixture e as 8, 6 e 6 paletas do arquivo real, calculada também em Python por uma segunda implementação; mexer em sal, ordem de campo ou tabela muda a cara de todo NPC e quebra isto de propósito.
const GOLDEN_LOOKS: Dictionary = {
	1: "female_a|peasant_f|hair_f1|brow_01|3|2|3|1026",
	2: "male_a|ranger_m|hair_any|brow_01|3|3|5|994",
	132: "male_a|smith_m|hair_any|brow_01|7|4|2|1019",
	2147483647: "female_a|ranger_f|hair_any|brow_03|2|1|5|1038",
	-1: "male_a|peasant_m|hair_m1|brow_02|7|3|3|989",
}
const FORBIDDEN_WORDS: PackedStringArray = ["randf", "randi", "randomize", "Time", "OS", "print", "Node", "Node3D"]

var _catalog: CharacterCatalog
var _palettes: CharacterPalettes


func before_each() -> void:
	_catalog = _load_catalog()
	_palettes = CharacterPalettes.from_file().palettes
	assert_true(_palettes.is_ready())


func _load_catalog() -> CharacterCatalog:
	var loaded: CharacterCatalog.LoadResult = CharacterCatalog.from_file(CATALOG_FIXTURE)
	assert_true(loaded.result.ok, loaded.result.message)
	return loaded.catalog


func _world_ids() -> Array[int]:
	var ids: Array[int] = []
	for id: int in range(1, WORLD_NPCS + 1):
		ids.append(id)
	return ids


func _of(id: int) -> CharacterAppearance:
	return CharacterAppearance.of(id, _catalog, _palettes)


func _dump(sheet: CharacterAppearance) -> String:
	return "%d|%s|%s" % [sheet.npc_id, sheet.gender, sheet.fingerprint()]


func _ids(rows: Array[Dictionary]) -> Array:
	var ids: Array = []
	for row: Dictionary in rows:
		ids.append(row["id"])
	return ids


## As palavras do código de um arquivo (sem os comentários).
func _code_words(path: String) -> Dictionary:
	var words: Dictionary = {}
	var pattern: RegEx = RegEx.create_from_string("[A-Za-z_][A-Za-z0-9_]*")
	for line: String in FileAccess.get_file_as_string(path).split("\n"):
		for found: RegExMatch in pattern.search_all(line.get_slice("#", 0)):
			words[found.get_string()] = true
	return words


func test_the_hash_matches_the_reference_values_and_ignores_the_high_bits() -> void:
	for value: int in GOLDEN_MIX:
		assert_eq(CharacterAppearance.mix32(value), GOLDEN_MIX[value], "mix32(%d)" % value)
	assert_eq(CharacterAppearance.mix32(4294967301), CharacterAppearance.mix32(5))
	assert_eq(CharacterAppearance.hash_field(1, CharacterAppearance.SALT_BODY), GOLDEN_BODY_HASH_OF_1)
	assert_ne(CharacterAppearance.hash_field(1, CharacterAppearance.SALT_BODY), CharacterAppearance.hash_field(1, CharacterAppearance.SALT_OUTFIT))
	assert_eq(CharacterAppearance.pick(7, CharacterAppearance.SALT_BODY, 0), 0)
	for id: int in GOLDEN_LOOKS:
		assert_eq(_of(id).fingerprint(), GOLDEN_LOOKS[id], "aparência de referência do id %d" % id)


func test_the_same_id_gives_the_same_sheet_across_loads_instances_and_orders() -> void:
	var other_catalog: CharacterCatalog = _load_catalog()
	var other_palettes: CharacterPalettes = CharacterPalettes.from_file().palettes
	var first: Dictionary = {}
	for id: int in _world_ids() + EDGE_IDS + ODD_IDS:
		first[id] = _dump(_of(id))
	var reversed_ids: Array[int] = _world_ids()
	reversed_ids.reverse()
	assert_eq(_dump(CharacterAppearance.of(WORLD_NPCS, other_catalog, other_palettes)), first[WORLD_NPCS])
	for id: int in reversed_ids + ODD_IDS + EDGE_IDS:
		assert_eq(_dump(CharacterAppearance.of(id, other_catalog, other_palettes)), first[id], "id %d em ordem inversa" % id)
	for step: int in range(1, WORLD_NPCS + 1):
		var id: int = (step * STRIDE) % (WORLD_NPCS + 1)
		assert_eq(_dump(_of(id)), first[id], "id %d em ordem saltada" % id)


func test_the_world_ids_have_variety() -> void:
	var looks: Dictionary = {}
	var outfit_uses: Dictionary = {}
	var cloth_uses: Dictionary = {}
	var genders: Dictionary = {}
	for id: int in _world_ids():
		var sheet: CharacterAppearance = _of(id)
		looks[sheet.fingerprint()] = true
		outfit_uses[sheet.outfit_id] = int(outfit_uses.get(sheet.outfit_id, 0)) + 1
		cloth_uses[sheet.cloth_palette_index] = true
		genders[sheet.gender] = true
	assert_gte(looks.size(), MIN_DISTINCT_LOOKS, "fichas distintas de 1 a %d: %d" % [WORLD_NPCS, looks.size()])
	for outfit: Dictionary in _catalog.outfits_for(CharacterCatalog.MALE) + _catalog.outfits_for(CharacterCatalog.FEMALE):
		assert_gte(int(outfit_uses.get(outfit["id"], 0)), MIN_USES_PER_OUTFIT, "usos de %s" % outfit["id"])
	assert_eq(cloth_uses.size(), _palettes.count(CharacterPalettes.CLOTH), "toda paleta de pano é usada")
	assert_eq(genders.size(), 2, "os dois gêneros aparecem")


func test_every_sheet_is_inside_the_ranges_and_the_tables_and_the_hair_fits_the_gender() -> void:
	for id: int in _world_ids() + EDGE_IDS + ODD_IDS:
		var sheet: CharacterAppearance = _of(id)
		assert_true(sheet.is_resolved(), "id %d" % id)
		assert_eq(sheet.npc_id, id)
		assert_between(sheet.scale_permille, CharacterAppearance.SCALE_MIN_PERMILLE, CharacterAppearance.SCALE_MAX_PERMILLE)
		assert_between(sheet.cloth_palette_index, 0, _palettes.count(CharacterPalettes.CLOTH) - 1)
		assert_between(sheet.skin_index, 0, _palettes.count(CharacterPalettes.SKIN) - 1)
		assert_between(sheet.hair_tone_index, 0, _palettes.count(CharacterPalettes.HAIR) - 1)
		assert_has(_ids(_catalog.outfits_for(sheet.gender)), sheet.outfit_id)
		assert_has(_ids(_catalog.hair_for(sheet.gender)), sheet.hair_id)
		assert_has(_ids(_catalog.eyebrows()), sheet.eyebrow_id)
		assert_has(_ids(_catalog.bodies()), sheet.body_id)


func test_an_unloaded_catalog_or_palettes_give_an_unresolved_sheet() -> void:
	var empty: CharacterAppearance = CharacterAppearance.of(7, CharacterCatalog.new(), CharacterPalettes.new())
	assert_false(empty.is_resolved())
	assert_eq(empty.npc_id, 7)
	assert_false(CharacterAppearance.of(7, _catalog, CharacterPalettes.new()).is_resolved())
	assert_false(CharacterAppearance.of(7, CharacterCatalog.new(), _palettes).is_resolved())
	assert_true(_of(7).is_resolved())


func test_the_characters_folder_is_pure_and_does_not_cite_sim_types() -> void:
	var sim_classes: Dictionary = {}
	for entry: Dictionary in ProjectSettings.get_global_class_list():
		if str(entry["path"]).begins_with("res://src/sim/"):
			sim_classes[str(entry["class"])] = true
	assert_gt(sim_classes.size(), 0, "o índice de classes globais precisa estar carregado")
	var violations: PackedStringArray = []
	for file: String in DirAccess.get_files_at(CHARACTERS_DIR):
		if not file.ends_with(".gd"):
			continue
		var words: Dictionary = _code_words(CHARACTERS_DIR.path_join(file))
		for word: String in FORBIDDEN_WORDS:
			if words.has(word):
				violations.append("%s usa %s" % [file, word])
		for sim_class: String in sim_classes:
			if words.has(sim_class):
				violations.append("%s cita o tipo de src/sim %s" % [file, sim_class])
		if file == APPEARANCE_FILE and words.has("float"):
			violations.append("%s usa float (o hash e a escolha são só de inteiros)" % file)
	assert_eq(violations, PackedStringArray(), "\n".join(violations))
