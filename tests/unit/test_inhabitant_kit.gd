extends GutTest

## ART-9 e ART-9d, protótipo isolado dos habitantes (sem renderizar): ficha e malha determinísticas nos três níveis, variação por ID (incluindo os campos novos da 9d), o que define cada papel, orçamento de triângulos por nível (varredura de 40 ids por papel), UMA malha e UM material, medidas, isolamento (nada de `src/` fora da pasta dos habitantes os cita; a pasta não sorteia nem lê relógio ou sistema) e arquivos pequenos (AGENTS 5.2).
const KIT_DIR: String = "res://src/presentation/world_view/inhabitants"
const SOURCES_DIR: String = "res://src"
const FORBIDDEN: String = "\\b(randf|randi|randomize|randf_range|randi_range|randfn|rand_from_seed)\\s*\\(|RandomNumberGenerator|\\.(shuffle|pick_random)\\s*\\(|\\bTime\\.|\\bOS\\."
const CITED: String = "\\bInhabitant[A-Za-z]*\\b"
const SAMPLE_IDS: int = 40
const VARIATION_IDS: int = 6
const MIN_VARYING_ASPECTS: int = 4
## Tetos [HIP] de triângulos por nível (ART-9e: LOD 0 até 2.200, LOD 1 até 520 e LOD 2 até 130; a ART-9d tinha 1.800, 450 e 120). Os números reais saem na linha `triângulos reais` do teste de orçamento.
const MAX_TRIANGLES: Array[int] = [2200, 520, 130]
const HEIGHT_RANGE_M: Vector2 = Vector2(1.3, 2.25)
const MAX_WIDTH_M: float = 1.7
const MAX_FILE_LINES: int = 330
const TOLERANCE: float = 0.001


func _spec(id: int, role: StringName) -> InhabitantSpec:
	return InhabitantSpec.for_inhabitant(id, role)


func _signature(spec: InhabitantSpec) -> Array:
	return [spec.height_m, spec.width_m, spec.head_scale, spec.skin, spec.hair, spec.top, spec.bottom, spec.trim, spec.boots, spec.cover_color, spec.alt, spec.collar, spec.garment, spec.head_cover, spec.accessories, spec.expression, spec.beard, spec.fabric, spec.apron, spec.crest, spec.has_pauldrons, spec.has_shield, spec.belly, spec.droop, spec.lean]


func _vertex_hash(mesh: ArrayMesh) -> int:
	return hash(mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX])


func _scripts(directory: String) -> Array[String]:
	var found: Array[String] = []
	for file_name: String in DirAccess.get_files_at(directory):
		if file_name.ends_with(".gd"):
			found.append(directory.path_join(file_name))
	for sub: String in DirAccess.get_directories_at(directory):
		found.append_array(_scripts(directory.path_join(sub)))
	return found


func test_same_id_and_role_give_same_spec_and_same_vertices() -> void:
	for role: StringName in InhabitantSpec.ROLES:
		assert_eq(_signature(_spec(7, role)), _signature(_spec(7, role)), "mesma ficha de %s" % role)
		for lod: int in [InhabitantBuilder.LOD_NEAR, InhabitantBuilder.LOD_MID, InhabitantBuilder.LOD_FAR]:
			assert_eq(_vertex_hash(InhabitantBuilder.build(_spec(7, role), lod)), _vertex_hash(InhabitantBuilder.build(_spec(7, role), lod)), "mesmos vértices de %s no LOD %d" % [role, lod])
	assert_ne(_signature(_spec(7, InhabitantSpec.VILLAGER)), _signature(_spec(8, InhabitantSpec.VILLAGER)), "ids diferentes, fichas diferentes")
	assert_ne(_vertex_hash(InhabitantBuilder.build(_spec(7, InhabitantSpec.GUARD), 0)), _vertex_hash(InhabitantBuilder.build(_spec(8, InhabitantSpec.GUARD), 0)), "ids diferentes, malhas diferentes")


func test_unknown_role_falls_back_to_villager() -> void:
	assert_eq(_signature(_spec(3, &"dragon")), _signature(_spec(3, InhabitantSpec.VILLAGER)), "papel desconhecido vira aldeão")


func test_ids_of_a_role_vary_in_at_least_four_aspects() -> void:
	for role: StringName in InhabitantSpec.ROLES:
		var seen: Array[Dictionary] = [{}, {}, {}, {}, {}]
		for id: int in range(1, VARIATION_IDS + 1):
			var spec: InhabitantSpec = _spec(id, role)
			var aspects: Array = [snappedf(spec.height_m, 0.01), snappedf(spec.width_m, 0.01), spec.top, spec.head_cover, str(spec.accessories)]
			for index: int in aspects.size():
				seen[index][aspects[index]] = true
		var varying: int = seen.filter(func(values: Dictionary) -> bool: return values.size() > 1).size()
		assert_gte(varying, MIN_VARYING_ASPECTS, "%s: aspectos que variam (altura, largura, paleta, cobertura, acessório) entre %d ids" % [role, VARIATION_IDS])
		assert_gte(seen[0].size(), VARIATION_IDS - 1, "%s: alturas diferentes" % role)


func test_each_role_has_what_defines_it() -> void:
	var spears: int = 0
	for id: int in range(1, SAMPLE_IDS + 1):
		var guard: InhabitantSpec = _spec(id, InhabitantSpec.GUARD)
		assert_eq(guard.head_cover, InhabitantSpec.HeadCover.OPEN_HELM, "guarda com elmo")
		assert_true(guard.has_accessory(&"spear") or guard.has_accessory(&"guard_staff"), "guarda com lança ou cajado de guarda")
		spears += int(guard.has_accessory(&"spear"))
		var merchant: InhabitantSpec = _spec(id, InhabitantSpec.MERCHANT)
		assert_true(merchant.has_accessory(&"satchel") or merchant.has_accessory(&"coin_pouch"), "comerciante com bolsa ou bolsinha")
		assert_true(merchant.has_accessory(&"apron") or merchant.head_cover == InhabitantSpec.HeadCover.WIDE_HAT, "comerciante com avental ou chapéu largo")
		var villager: InhabitantSpec = _spec(id, InhabitantSpec.VILLAGER)
		assert_ne(villager.head_cover, InhabitantSpec.HeadCover.OPEN_HELM, "aldeão sem elmo")
		assert_false(villager.has_accessory(&"spear") or villager.has_accessory(&"guard_staff"), "aldeão sem lança")
	assert_gt(spears, 0, "há guardas de lança")


## Os campos da 9d: o guarda tem ombreiras e escudo só com lança, as expressões e as cristas aparecem, barba só em aldeão, avental longo só no comerciante que o tem.
func test_new_spec_fields_follow_the_role_and_vary_by_hash() -> void:
	var moods: Dictionary = {}
	var crests: Dictionary = {}
	var beards: int = 0
	var shields: int = 0
	for id: int in range(1, SAMPLE_IDS + 1):
		var guard: InhabitantSpec = _spec(id, InhabitantSpec.GUARD)
		assert_true(guard.has_pauldrons, "guarda com ombreiras")
		assert_ne(guard.crest, InhabitantSpec.Crest.NONE, "guarda com crista ou penacho")
		assert_false(guard.has_shield and not guard.has_accessory(&"spear"), "escudo só com lança")
		shields += int(guard.has_shield)
		crests[guard.crest] = true
		var villager: InhabitantSpec = _spec(id, InhabitantSpec.VILLAGER)
		moods[villager.expression] = true
		beards += int(villager.beard != InhabitantSpec.Beard.NONE)
		var merchant: InhabitantSpec = _spec(id, InhabitantSpec.MERCHANT)
		assert_eq(merchant.beard, InhabitantSpec.Beard.NONE, "barba só em aldeão")
		assert_false(merchant.has_pauldrons or villager.has_pauldrons, "ombreira só no guarda")
		assert_eq(merchant.apron == InhabitantSpec.Apron.LONG, merchant.has_accessory(&"apron"), "avental longo é o do comerciante que o tem")
	assert_gte(moods.size(), 3, "expressões de aldeão variam")
	assert_eq(crests.size(), 2, "crista de fio e penacho aparecem")
	assert_between(beards, 3, SAMPLE_IDS - 3, "barba em alguns aldeões, não em todos")
	assert_gt(shields, 0, "há guardas com escudo")


func test_budget_single_surface_shared_material_and_dimensions() -> void:
	var material: Material = PlazaMaterials.create()[&"solid"]
	var worst: Array[int] = [0, 0, 0]
	var totals: Dictionary = {}
	for role: StringName in InhabitantSpec.ROLES:
		for id: int in range(1, SAMPLE_IDS + 1):
			var spec: InhabitantSpec = _spec(id, role)
			assert_between(spec.height_m, HEIGHT_RANGE_M.x, HEIGHT_RANGE_M.y, "altura da ficha")
			for lod: int in 3:
				var mesh: ArrayMesh = InhabitantBuilder.build(spec, lod, material)
				var triangles: int = int(mesh.get_faces().size() / 3.0)
				worst[lod] = maxi(worst[lod], triangles)
				totals[[role, lod]] = maxi(int(totals.get([role, lod], 0)), triangles)
				assert_eq(mesh.get_surface_count(), 1, "UMA malha, uma superfície (%s %d LOD %d)" % [role, id, lod])
				assert_same(mesh.surface_get_material(0), material, "UM material compartilhado")
				assert_lte(triangles, MAX_TRIANGLES[lod], "triângulos do LOD %d (%s %d)" % [lod, role, id])
				assert_almost_eq(mesh.get_aabb().position.y, 0.0, TOLERANCE, "pés em y = 0")
				if lod == 0:
					assert_between(mesh.get_aabb().size.y, HEIGHT_RANGE_M.x, HEIGHT_RANGE_M.y, "altura da malha (%s %d)" % [role, id])
					assert_lte(mesh.get_aabb().size.x, MAX_WIDTH_M + TOLERANCE, "largura da malha (%s %d)" % [role, id])
	gut.p("triângulos reais (máximo de %d ids por papel): LOD 0 %d, LOD 1 %d, LOD 2 %d; por papel: %s" % [SAMPLE_IDS, worst[0], worst[1], worst[2], str(totals)])


func test_sources_are_deterministic_isolated_and_small() -> void:
	var forbidden: RegEx = RegEx.create_from_string(FORBIDDEN)
	var cited: RegEx = RegEx.create_from_string(CITED)
	var kit_files: int = 0
	for path: String in _scripts(SOURCES_DIR):
		var text: String = FileAccess.get_file_as_string(path)
		if path.begins_with(KIT_DIR):
			kit_files += 1
			assert_null(forbidden.search(text), "%s não sorteia nem lê relógio ou sistema" % path)
			assert_lte(text.count("\n"), MAX_FILE_LINES, "%s tem arquivos pequenos (AGENTS 5.2)" % path)
		else:
			assert_null(cited.search(text), "%s não cita os habitantes" % path)
	assert_gte(kit_files, 7, "arquivos do kit verificados (ficha, formas, medidas, corpo, cabeça, roupa, cobertura, acessórios e o orquestrador)")
