extends GutTest
## ART-12, entrega 3: as CharacterPalettes (só dados, sem Node nem janela). O arquivo REAL (data/presentation/character_palettes.json) carrega com paletas moderadas, duas cargas dão o mesmo e cada erro de carga (arquivo ausente, JSON inválido, campo ausente, de tipo errado ou fora da faixa, id repetido, tabela vazia) vira UMA falha tratada com arquivo, item e campo.

const LABEL: String = "paletas_de_teste.json"
const ERASE: String = "__apagar__"
const KINDS: PackedStringArray = [CharacterPalettes.CLOTH, CharacterPalettes.SKIN, CharacterPalettes.HAIR]
const EXPECTED_CLOTH: PackedStringArray = ["slate", "petrol", "wine", "sand", "ochre", "moss", "rust", "gray"]
## O que é "moderado" no arquivo real [HIP]: saturação até 1,1x, valor de 0,7x a 1,1x, saturação somada até 0,3, matiz até meia volta, pele nunca mais clara que o material original. A afinação visual é da entrega 4.
const MAX_SATURATION: int = 1100
const MIN_VALUE: int = 700
const MAX_VALUE: int = 1100
const MAX_SATURATION_ADDED: int = 300
const MAX_HUE_DEG: int = 180
const MAX_SKIN: int = 1000
## Cada caso: [caminho do valor no JSON, valor novo (ERASE apaga a chave), item esperado na falha, campo esperado].
const BAD_CASES: Array = [
	[["version"], ERASE, "", "version"],
	[["version"], 2, "", "version"],
	[["cloth"], [], "", "cloth"],
	[["skin"], ERASE, "", "skin"],
	[["hair"], "nenhuma", "", "hair"],
	[["cloth", 0, "hue_deg"], "90", "slate", "hue_deg"],
	[["cloth", 0, "hue_deg"], 999, "slate", "hue_deg"],
	[["cloth", 0, "sat_add_permille"], 12.5, "slate", "sat_add_permille"],
	[["cloth", 1, "id"], "slate", "slate", "id"],
	[["cloth", 2, "val_permille"], ERASE, "wine", "val_permille"],
	[["skin", 0, "r_permille"], -5, "base", "r_permille"],
	[["hair", 3, "b_permille"], 2001, "auburn", "b_permille"],
]


func _text_with(path: Array, value: Variant) -> String:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CharacterPalettes.DEFAULT_PATH))
	var node: Variant = data
	for step: Variant in path.slice(0, path.size() - 1):
		node = node[step]
	var last: Variant = path[path.size() - 1]
	if typeof(value) == TYPE_STRING and value == ERASE:
		node.erase(last)
	else:
		node[last] = value
	return JSON.stringify(data)


func test_the_real_file_loads_with_moderate_palettes() -> void:
	var loaded: CharacterPalettes.LoadResult = CharacterPalettes.from_file()
	assert_true(loaded.result.ok, loaded.result.message)
	var palettes: CharacterPalettes = loaded.palettes
	assert_true(palettes.is_ready())
	assert_between(palettes.count(CharacterPalettes.CLOTH), 8, 10)
	assert_between(palettes.count(CharacterPalettes.SKIN), 4, 6)
	assert_between(palettes.count(CharacterPalettes.HAIR), 4, 6)
	var cloth_ids: PackedStringArray = []
	for index: int in palettes.count(CharacterPalettes.CLOTH):
		var cloth: Dictionary = palettes.entry(CharacterPalettes.CLOTH, index)
		cloth_ids.append(cloth["id"])
		assert_between(cloth["hue_deg"], -MAX_HUE_DEG, MAX_HUE_DEG, cloth["id"])
		assert_lte(cloth["sat_permille"], MAX_SATURATION, cloth["id"])
		assert_between(cloth["val_permille"], MIN_VALUE, MAX_VALUE, cloth["id"])
		assert_between(cloth["leather_val_permille"], MIN_VALUE, MAX_VALUE, cloth["id"])
		assert_between(cloth["sat_add_permille"], 0, MAX_SATURATION_ADDED, cloth["id"])
	assert_eq(cloth_ids, EXPECTED_CLOTH)
	for index: int in palettes.count(CharacterPalettes.SKIN):
		var skin: Dictionary = palettes.entry(CharacterPalettes.SKIN, index)
		assert_lte(maxi(skin["r_permille"], maxi(skin["g_permille"], skin["b_permille"])), MAX_SKIN, skin["id"])


func test_two_loads_give_the_same_palettes_and_a_bad_index_gives_an_empty_entry() -> void:
	var first: CharacterPalettes = CharacterPalettes.from_file().palettes
	var second: CharacterPalettes = CharacterPalettes.from_file().palettes
	for kind: String in KINDS:
		assert_eq(first.count(kind), second.count(kind), kind)
		assert_eq(first.entry(kind, -1), {})
		assert_eq(first.entry(kind, first.count(kind)), {})
		for index: int in first.count(kind):
			assert_eq(first.entry(kind, index), second.entry(kind, index), "%s %d" % [kind, index])
	assert_eq(CharacterPalettes.new().count(CharacterPalettes.CLOTH), 0)


func test_missing_file_and_bad_json_are_handled_failures() -> void:
	var missing: String = "res://data/presentation/nao_existe.json"
	var absent: CharacterPalettes.LoadResult = CharacterPalettes.from_file(missing)
	assert_false(absent.result.ok)
	assert_eq(absent.result.code, CharacterPalettes.CODE_INVALID)
	assert_string_contains(absent.result.message, missing)
	assert_false(absent.palettes.is_ready())
	for broken: String in ["{ isso nao e json", "[]", ""]:
		var loaded: CharacterPalettes.LoadResult = CharacterPalettes.from_json(broken, LABEL)
		assert_false(loaded.result.ok, broken)
		assert_string_contains(loaded.result.message, LABEL)


func test_each_invalid_palette_file_is_one_handled_failure_with_file_item_and_field() -> void:
	for index: int in BAD_CASES.size():
		var spec: Array = BAD_CASES[index]
		var loaded: CharacterPalettes.LoadResult = CharacterPalettes.from_json(_text_with(spec[0], spec[1]), LABEL)
		var message: String = loaded.result.message
		assert_false(loaded.result.ok, "caso %d deveria falhar" % index)
		assert_false(loaded.palettes.is_ready(), "caso %d: as paletas da falha são vazias" % index)
		assert_true(message.begins_with(LABEL), "caso %d: arquivo em %s" % [index, message])
		assert_true(spec[2] == "" or message.contains("item '%s'" % spec[2]), "caso %d: item em %s" % [index, message])
		assert_true(message.contains("campo '%s'" % spec[3]), "caso %d: campo em %s" % [index, message])
