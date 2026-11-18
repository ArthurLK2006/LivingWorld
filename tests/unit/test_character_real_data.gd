extends GutTest
## ART-12, entrega 3: os DADOS REAIS (o catálogo da entrega 2 e as paletas da 3b) carregam sem erro, com a verificação de existência de verdade, e a aparência dos 138 NPCs do mundo sai válida e variada com eles.

const WORLD_NPCS: int = 138
const MIN_DISTINCT_LOOKS: int = 40


func test_the_real_catalog_and_palettes_load_and_every_world_npc_gets_a_valid_look() -> void:
	var catalog_load: CharacterCatalog.LoadResult = CharacterCatalog.from_file()
	assert_true(catalog_load.result.ok, catalog_load.result.message)
	var palettes_load: CharacterPalettes.LoadResult = CharacterPalettes.from_file()
	assert_true(palettes_load.result.ok, palettes_load.result.message)
	var looks: Dictionary = {}
	var genders: Dictionary = {}
	for npc_id: int in range(1, WORLD_NPCS + 1):
		var look: CharacterAppearance = CharacterAppearance.of(npc_id, catalog_load.catalog, palettes_load.palettes)
		assert_true(look.is_resolved(), "NPC %d sem ficha" % npc_id)
		looks[look.fingerprint()] = true
		genders[look.gender] = true
	assert_gte(looks.size(), MIN_DISTINCT_LOOKS, "fichas distintas com os dados reais")
	assert_eq(genders.size(), 2, "os dois gêneros aparecem")


func _ids(rows: Array[Dictionary]) -> Array:
	var ids: Array = []
	for row: Dictionary in rows:
		ids.append(row["id"])
	return ids


## Entrega 3c com os dados reais: a barba é camada à parte (nenhuma cena de barba entre os cabelos), mulher não a tem e a sobrancelha é do gênero.
func test_with_the_real_data_no_hair_is_a_beard_no_woman_has_one_and_the_eyebrows_fit_the_gender() -> void:
	var catalog: CharacterCatalog = CharacterCatalog.from_file().catalog
	var palettes: CharacterPalettes = CharacterPalettes.from_file().palettes
	var beard_scenes: Array = []
	for gender: String in [CharacterCatalog.MALE, CharacterCatalog.FEMALE]:
		for beard: Dictionary in catalog.beards_for(gender):
			beard_scenes.append(beard["scene"])
	assert_false(beard_scenes.is_empty(), "o catálogo real tem ao menos uma barba")
	for gender: String in [CharacterCatalog.MALE, CharacterCatalog.FEMALE]:
		assert_false(catalog.eyebrows_for(gender).is_empty(), "há sobrancelha do gênero %s (a ficha não depende de cair em todas)" % gender)
		for hair: Dictionary in catalog.hair_for(gender):
			assert_does_not_have(beard_scenes, hair["scene"], "o cabelo %s é uma barba" % hair["id"])
	var bearded: int = 0
	var shaved: int = 0
	for npc_id: int in range(1, WORLD_NPCS + 1):
		var look: CharacterAppearance = CharacterAppearance.of(npc_id, catalog, palettes)
		assert_has(_ids(catalog.eyebrows_for(look.gender)), look.eyebrow_id, "NPC %d: sobrancelha do gênero %s" % [npc_id, look.gender])
		if look.gender == CharacterCatalog.FEMALE:
			assert_eq(look.beard_id, "", "NPC %d: mulher com barba" % npc_id)
		elif look.beard_id.is_empty():
			shaved += 1
		else:
			assert_has(_ids(catalog.beards_for(look.gender)), look.beard_id, "NPC %d: barba fora da tabela" % npc_id)
			bearded += 1
	assert_gt(bearded, 0, "há homens de barba entre os 138")
	assert_gt(shaved, 0, "há homens sem barba entre os 138")
