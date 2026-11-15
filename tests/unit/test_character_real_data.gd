extends GutTest
## ART-12, entrega 3: os DADOS REAIS (o catálogo da entrega 2 e as paletas da 3b) carregam sem erro, com a verificação de existência de verdade, e a aparência dos 132 NPCs do mundo sai válida e variada com eles.

const WORLD_NPCS: int = 132
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
