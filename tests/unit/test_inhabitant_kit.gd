extends GutTest

## ART-9, protótipo isolado dos habitantes (sem renderizar): ficha e malha determinísticas, variação por ID, o que define cada papel, orçamento de triângulos, UMA malha e UM material, medidas e isolamento (nada de `src/` fora da pasta dos habitantes os cita; a pasta dos habitantes não sorteia nem lê relógio ou sistema).
const KIT_DIR: String = "res://src/presentation/world_view/inhabitants"
const SOURCES_DIR: String = "res://src"
const FORBIDDEN: String = "\\b(randf|randi|randomize|randf_range|randi_range|randfn|rand_from_seed)\\s*\\(|RandomNumberGenerator|\\.(shuffle|pick_random)\\s*\\(|\\bTime\\.|\\bOS\\."
const CITED: String = "\\b(InhabitantSpec|InhabitantBuilder|InhabitantView)\\b"
const SAMPLE_IDS: int = 24
const VARIATION_IDS: int = 6
const MIN_VARYING_ASPECTS: int = 4
const MAX_TRIANGLES_NEAR: int = 700
const MAX_TRIANGLES_FAR: int = 120
const HEIGHT_RANGE_M: Vector2 = Vector2(1.3, 2.0)
const MAX_WIDTH_M: float = 0.9
const TOLERANCE: float = 0.001


func _spec(id: int, role: StringName) -> InhabitantSpec:
	return InhabitantSpec.for_inhabitant(id, role)


func _signature(spec: InhabitantSpec) -> Array:
	return [spec.height_m, spec.width_m, spec.head_scale, spec.skin, spec.hair, spec.top, spec.bottom, spec.trim, spec.boots, spec.cover_color, spec.garment, spec.head_cover, spec.accessories]


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
		for lod: int in [InhabitantBuilder.LOD_NEAR, InhabitantBuilder.LOD_FAR]:
			assert_eq(_vertex_hash(InhabitantBuilder.build(_spec(7, role), lod)), _vertex_hash(InhabitantBuilder.build(_spec(7, role), lod)), "mesmos vértices de %s no LOD %d" % [role, lod])
	assert_ne(_signature(_spec(7, InhabitantSpec.VILLAGER)), _signature(_spec(8, InhabitantSpec.VILLAGER)), "ids diferentes, fichas diferentes")


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


func test_budget_single_surface_shared_material_and_dimensions() -> void:
	var material: Material = PlazaMaterials.create()[&"solid"]
	var worst_near: int = 0
	var worst_far: int = 0
	for role: StringName in InhabitantSpec.ROLES:
		for id: int in range(1, SAMPLE_IDS + 1):
			var spec: InhabitantSpec = _spec(id, role)
			var near: ArrayMesh = InhabitantBuilder.build(spec, InhabitantBuilder.LOD_NEAR, material)
			var far: ArrayMesh = InhabitantBuilder.build(spec, InhabitantBuilder.LOD_FAR, material)
			worst_near = maxi(worst_near, int(near.get_faces().size() / 3.0))
			worst_far = maxi(worst_far, int(far.get_faces().size() / 3.0))
			assert_eq(near.get_surface_count(), 1, "UMA malha, uma superfície")
			assert_same(near.surface_get_material(0), material, "UM material compartilhado")
			var box: AABB = near.get_aabb()
			assert_between(spec.height_m, HEIGHT_RANGE_M.x, HEIGHT_RANGE_M.y, "altura da ficha")
			assert_between(box.size.y, HEIGHT_RANGE_M.x, HEIGHT_RANGE_M.y, "altura da malha (%s %d)" % [role, id])
			assert_lte(box.size.x, MAX_WIDTH_M + TOLERANCE, "largura da malha (%s %d)" % [role, id])
			assert_almost_eq(box.position.y, 0.0, TOLERANCE, "pés em y = 0")
	assert_lte(worst_near, MAX_TRIANGLES_NEAR, "triângulos do LOD 0")
	assert_lte(worst_far, MAX_TRIANGLES_FAR, "triângulos do LOD 1")
	gut.p("triângulos reais: LOD 0 até %d, LOD 1 até %d" % [worst_near, worst_far])


func test_sources_are_deterministic_and_isolated() -> void:
	var forbidden: RegEx = RegEx.create_from_string(FORBIDDEN)
	var cited: RegEx = RegEx.create_from_string(CITED)
	var kit_files: int = 0
	for path: String in _scripts(SOURCES_DIR):
		var text: String = FileAccess.get_file_as_string(path)
		if path.begins_with(KIT_DIR):
			kit_files += 1
			assert_null(forbidden.search(text), "%s não sorteia nem lê relógio ou sistema" % path)
		else:
			assert_null(cited.search(text), "%s não cita os habitantes" % path)
	assert_gt(kit_files, 0, "arquivos do kit verificados")
