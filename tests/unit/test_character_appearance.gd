extends GutTest
## ART-12, entrega 3: a ficha de aparência (CharacterAppearance) é função PURA do `npc_id` e das tabelas. Catálogo: o fixture de tests/unit/support (arquivos reais do projeto); paletas: o arquivo real. Determinismo (duas cargas, duas instâncias, ordens de consulta diferentes, valores de referência do hash conferidos também em Python), variedade nos 132 NPCs, faixas e tabelas, ids de borda (0, negativos, 2^31-1), catálogo não carregado e isolamento da pasta (sem sorteio, relógio, print, Node nem tipo de src/sim). Entrega 3c: a barba é uma camada à parte (só homem, cerca de 350 milésimos, nunca um "cabelo") e a sobrancelha sai das compatíveis com o gênero.

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
## O hash do sal da barba (o 9º múltiplo de 0x9E3779B9): o resto por 1000 do id 1 é 510 (sem barba, o limite é 350) e o do id 2 é 328 (com barba).
const GOLDEN_BEARD_HASH: Dictionary = {1: 2385880510, 2: 4149407328}
## A aparência (sem o id) de alguns NPCs com o fixture e as 8, 6 e 6 paletas do arquivo real, calculada também em Python por uma segunda implementação (a ordem dos campos é a do `fingerprint`: corpo, roupa, cabelo, BARBA, sobrancelha, ...); mexer em sal, ordem de campo ou tabela muda a cara de todo NPC e quebra isto de propósito. Os ids 2, 29 e 35 fixam as três barbas do fixture e o 132 e o -1 são homens sem barba.
const GOLDEN_LOOKS: Dictionary = {
	1: "female_a|peasant_f|hair_f1||brow_02|3|2|3|1026",
	2: "male_a|ranger_m|hair_any|beard_any|brow_03|3|3|5|994",
	29: "male_a|smith_m|hair_m2|beard_02|brow_03|4|5|1|973",
	35: "male_a|peasant_m|hair_m2|beard_01|brow_03|3|2|0|971",
	132: "male_a|smith_m|hair_any||brow_01|7|4|2|1019",
	2147483647: "female_a|ranger_f|hair_any||brow_02|2|1|5|1038",
	-1: "male_a|peasant_m|hair_m1||brow_01|7|3|3|989",
}
## Fração de homens com barba medida de 1 a N, contra o alvo do contrato (350 milésimos [HIP], escrito aqui e não lido da constante da ficha, para que mudar a constante quebre o teste) e a tolerância declarada: a amostra de n homens tem desvio-padrão de raiz(0,35 x 0,65 / n); com 70 homens (ids 1 a 132) 3 desvios são 171 milésimos e com cerca de 2.500 (ids 1 a 5.000) 4 desvios são 38. Medido com o fixture: 371 e 355.
const BEARD_TARGET_PERMILLE: int = 350
const BEARD_TOLERANCE_PERMILLE: Dictionary = {132: 175, 5000: 40}
const PERMILLE: int = 1000
const SCENE: String = "res://scenes/main.tscn"
const FORBIDDEN_WORDS: PackedStringArray = ["randf", "randi", "randomize", "Time", "OS", "print", "printerr", "push_error", "push_warning", "assert", "Node", "Node3D"]
## Só os arquivos de DADOS da pasta: a entrega 4 põe nela o montador e o visual (Node3D), que não entram nesta varredura.
const DATA_FILES: PackedStringArray = ["character_appearance.gd", "character_catalog.gd", "character_palettes.gd", "character_data_reader.gd"]

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


## O catálogo do fixture com uma tabela trocada pelas linhas dadas (null a apaga); nada vai para o disco. Variant: as linhas são o valor cru do JSON.
func _catalog_with(table: String, rows: Variant) -> CharacterCatalog:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CATALOG_FIXTURE))
	if rows == null:
		data.erase(table)
	else:
		data[table] = rows
	var loaded: CharacterCatalog.LoadResult = CharacterCatalog.from_json(JSON.stringify(data), "catalogo_de_teste.json")
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
	for id: int in GOLDEN_BEARD_HASH:
		assert_eq(CharacterAppearance.hash_field(id, CharacterAppearance.SALT_BEARD), GOLDEN_BEARD_HASH[id], "hash da barba do id %d" % id)
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
		assert_has(_ids(_catalog.eyebrows_for(sheet.gender)), sheet.eyebrow_id, "id %d: sobrancelha do gênero" % id)
		assert_true(sheet.beard_id.is_empty() or _ids(_catalog.beards_for(sheet.gender)).has(sheet.beard_id), "id %d: barba da tabela" % id)
		assert_has(_ids(_catalog.bodies()), sheet.body_id)


func test_no_woman_has_a_beard_and_the_men_have_it_in_about_350_permille() -> void:
	assert_false(_catalog.beards_for(CharacterCatalog.FEMALE).is_empty(), "o fixture tem uma barba compatível com mulher: a regra é da ficha, não do catálogo")
	var violations: PackedStringArray = []
	var styles: Dictionary = {}
	for last: int in BEARD_TOLERANCE_PERMILLE:
		var men: int = 0
		var bearded: int = 0
		for id: int in range(1, last + 1):
			var sheet: CharacterAppearance = _of(id)
			if sheet.gender != CharacterCatalog.MALE:
				if not sheet.beard_id.is_empty():
					violations.append("mulher %d com a barba %s" % [id, sheet.beard_id])
				continue
			men += 1
			if not sheet.beard_id.is_empty():
				bearded += 1
				styles[sheet.beard_id] = true
		var tolerance: int = BEARD_TOLERANCE_PERMILLE[last]
		var label: String = "ids 1 a %d: %d de %d homens com barba (esperado %d milésimos, tolerância %d)" % [last, bearded, men, BEARD_TARGET_PERMILLE, tolerance]
		assert_between(bearded * PERMILLE, (BEARD_TARGET_PERMILLE - tolerance) * men, (BEARD_TARGET_PERMILLE + tolerance) * men, label)
	assert_eq(violations, PackedStringArray(), "\n".join(violations))
	assert_eq(styles.size(), _catalog.beards_for(CharacterCatalog.MALE).size(), "toda barba compatível com homem é usada")


func test_a_bearded_man_keeps_his_hair_and_no_hair_is_a_beard() -> void:
	var beard_ids: Array = _ids(_catalog.beards_for(CharacterCatalog.MALE)) + _ids(_catalog.beards_for(CharacterCatalog.FEMALE))
	var bearded: int = 0
	for id: int in _world_ids():
		var sheet: CharacterAppearance = _of(id)
		assert_does_not_have(beard_ids, sheet.hair_id, "id %d: o cabelo não pode ser uma barba" % id)
		assert_false(sheet.hair_id.is_empty(), "id %d: todo NPC tem cabelo, com ou sem barba" % id)
		if not sheet.beard_id.is_empty():
			bearded += 1
	assert_gt(bearded, 0, "há homens de barba entre os 132")


func test_a_catalog_with_no_beard_for_men_gives_no_beard_and_changes_nothing_else() -> void:
	var only_female: Array = [{"id": "beard_f", "gender": "female", "scene": SCENE}]
	for bare: CharacterCatalog in [_catalog_with("beards", null), _catalog_with("beards", only_female)]:
		assert_true(bare.beards_for(CharacterCatalog.MALE).is_empty())
		for id: int in _world_ids():
			var full: CharacterAppearance = _of(id)
			full.beard_id = ""
			assert_eq(CharacterAppearance.of(id, bare, _palettes).fingerprint(), full.fingerprint(), "id %d: sem barba, só a barba some" % id)


func test_the_eyebrow_fits_the_gender_and_falls_back_to_all_when_none_fits() -> void:
	var seen: Dictionary = {}
	for id: int in _world_ids() + EDGE_IDS + ODD_IDS:
		var sheet: CharacterAppearance = _of(id)
		assert_has(_ids(_catalog.eyebrows_for(sheet.gender)), sheet.eyebrow_id, "id %d" % id)
		seen["%s/%s" % [sheet.gender, sheet.eyebrow_id]] = true
	var kinds: Array = seen.keys()
	kinds.sort()
	assert_eq(kinds, ["female/brow_02", "female/brow_03", "male/brow_01", "male/brow_03"], "o gênero filtra e a sobrancelha sem gênero serve aos dois")
	var only_female: CharacterCatalog = _catalog_with("eyebrows", [{"id": "brow_only", "gender": "female", "scene": SCENE}])
	for id: int in _world_ids():
		assert_eq(CharacterAppearance.of(id, only_female, _palettes).eyebrow_id, "brow_only", "id %d: nenhuma do gênero, cai em todas" % id)


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
	for file: String in DATA_FILES:
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


func test_missing_tables_give_an_empty_sheet_without_error() -> void:
	assert_false(CharacterAppearance.of(7, null, _palettes).is_resolved(), "sem catálogo")
	assert_false(CharacterAppearance.of(7, _catalog, null).is_resolved(), "sem paletas")
	assert_eq(CharacterAppearance.of(7, null, null).npc_id, 7, "o id fica na ficha vazia")
