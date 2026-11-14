extends GutTest

## ART-9e, protótipo isolado dos habitantes (sem renderizar): a MATRIZ de arquétipos (3 papéis x 4 subarquétipos), o determinismo da MORFOLOGIA, a DIVERSIDADE dentro de cada papel (dispersão de altura, largura, barriga e proporção; todos os subarquétipos aparecem; pares do mesmo papel diferem na silhueta, medida como no `test_inhabitant_silhouette`) e a pele de normais suaves. Os números reais saem nas linhas `gut.p`.
const SAMPLE_IDS: int = 40
const PAIR_BLOCKS: int = 3
const SLICES: int = 10
const MIN_HEIGHT_SPREAD_M: float = 0.2
const MIN_WIDTH_SPREAD_M: float = 0.25
const MIN_BELLY_SPREAD: float = 0.3
const MIN_ASPECT_SPREAD: float = 0.12
const MIN_PAIR_GAP: float = 0.02
const MIN_SMOOTH_VERTICES: int = 200
const SMOOTH_COSINE: float = 0.995


func _signature(spec: InhabitantSpec) -> Array:
	return [spec.archetype, spec.height_m, spec.width_m, spec.age, spec.build, spec.girth, spec.shoulder, spec.chest, spec.belly, spec.hip, spec.neck, spec.limbs, spec.legs, spec.head_scale, spec.head_shape, spec.posture, spec.stoop, spec.sleeve, spec.hair_style, spec.waist, spec.neck_wrap, spec.beard, spec.accessories, spec.has_feather, spec.halberd, spec.bundle_size]


func _curve(mesh: ArrayMesh) -> Array[float]:
	var height: float = mesh.get_aabb().size.y
	var low: Array[float] = []
	var high: Array[float] = []
	for slice: int in SLICES:
		low.append(1000.0)
		high.append(-1000.0)
	for vertex: Vector3 in mesh.get_faces():
		var index: int = clampi(int(vertex.y / height * SLICES), 0, SLICES - 1)
		low[index] = minf(low[index], vertex.x)
		high[index] = maxf(high[index], vertex.x)
	var curve: Array[float] = []
	for slice: int in SLICES:
		curve.append(maxf(high[slice] - low[slice], 0.0) / height)
	return curve


func _gap(first: Array[float], second: Array[float]) -> float:
	var total: float = 0.0
	for slice: int in SLICES:
		total += absf(first[slice] - second[slice])
	return total / SLICES


func test_matrix_is_three_roles_by_four_named_subarchetypes() -> void:
	assert_eq(InhabitantArchetypes.TABLE.size(), InhabitantSpec.ROLES.size(), "uma linha de matriz por papel")
	for role: StringName in InhabitantSpec.ROLES:
		var rows: Array = InhabitantArchetypes.TABLE[role]
		assert_eq(rows.size(), InhabitantArchetypes.SLOTS, "%s: quatro subarquétipos" % role)
		var names: Dictionary = {}
		for row: Dictionary in rows:
			names[row["name"]] = true
			for key: String in ["height", "shoulder", "belly", "hip", "neck", "limbs", "legs", "head", "build", "age", "shapes", "posture", "outfits", "sleeves", "hair", "beard", "mood"]:
				assert_true(row.has(key), "%s / %s tem '%s'" % [role, row["name"], key])
		assert_eq(names.size(), 4, "%s: nomes diferentes" % role)


func test_morphology_is_deterministic() -> void:
	for role: StringName in InhabitantSpec.ROLES:
		for id: int in range(1, 13):
			assert_eq(_signature(InhabitantSpec.for_inhabitant(id, role)), _signature(InhabitantSpec.for_inhabitant(id, role)), "mesma morfologia de %s %d" % [role, id])


func test_all_subarchetypes_appear_and_four_consecutive_ids_show_all_four() -> void:
	for role: StringName in InhabitantSpec.ROLES:
		var seen: Dictionary = {}
		for id: int in range(1, SAMPLE_IDS + 1):
			seen[InhabitantSpec.for_inhabitant(id, role).archetype] = true
		assert_eq(seen.size(), 4, "%s: os quatro subarquétipos aparecem em %d ids" % [role, SAMPLE_IDS])
		for block: int in 3:
			var group: Dictionary = {}
			for id: int in range(block * 4 + 1, block * 4 + 5):
				group[InhabitantSpec.for_inhabitant(id, role).archetype] = true
			assert_eq(group.size(), 4, "%s: quatro ids seguidos (bloco %d) mostram os quatro" % [role, block])


## Dentro de cada papel a altura, a largura, a barriga e a proporção (largura sobre altura) se espalham bem, e a faixa de altura da ficha cobre de 1,45 a 1,95 m no conjunto.
func test_spread_inside_each_role_is_real() -> void:
	var lowest: float = 10.0
	var highest: float = 0.0
	for role: StringName in InhabitantSpec.ROLES:
		var heights: Array[float] = []
		var widths: Array[float] = []
		var bellies: Array[float] = []
		var aspects: Array[float] = []
		for id: int in range(1, SAMPLE_IDS + 1):
			var spec: InhabitantSpec = InhabitantSpec.for_inhabitant(id, role)
			heights.append(spec.height_m)
			widths.append(spec.width_m)
			bellies.append(spec.belly)
			aspects.append(spec.width_m / spec.height_m)
		lowest = minf(lowest, heights.min())
		highest = maxf(highest, heights.max())
		var spreads: Array[float] = [heights.max() - heights.min(), widths.max() - widths.min(), bellies.max() - bellies.min(), aspects.max() - aspects.min()]
		gut.p("%s: dispersão de altura %.2f m, largura %.2f m, barriga %.2f, proporção %.2f" % [role, spreads[0], spreads[1], spreads[2], spreads[3]])
		assert_gt(spreads[0], MIN_HEIGHT_SPREAD_M, "%s: dispersão de altura" % role)
		assert_gt(spreads[1], MIN_WIDTH_SPREAD_M, "%s: dispersão de largura" % role)
		assert_gt(spreads[2], MIN_BELLY_SPREAD, "%s: dispersão de barriga" % role)
		assert_gt(spreads[3], MIN_ASPECT_SPREAD, "%s: dispersão da proporção largura/altura" % role)
	gut.p("faixa de altura do conjunto: %.2f a %.2f m" % [lowest, highest])
	assert_lt(lowest, 1.5, "há gente baixa (cerca de 1,45 m)")
	assert_gt(highest, 1.9, "há gente alta (cerca de 1,95 m)")


## Pares do MESMO papel (um de cada subarquétipo, em três blocos de ids) diferem na silhueta acima de um limite.
func test_pairs_of_the_same_role_differ_in_silhouette() -> void:
	for role: StringName in InhabitantSpec.ROLES:
		var smallest: float = 1000.0
		for block: int in PAIR_BLOCKS:
			var curves: Array = []
			for id: int in range(block * 4 + 1, block * 4 + 5):
				curves.append(_curve(InhabitantBuilder.build(InhabitantSpec.for_inhabitant(id, role), InhabitantBuilder.LOD_NEAR)))
			for first: int in curves.size():
				for second: int in range(first + 1, curves.size()):
					smallest = minf(smallest, _gap(curves[first], curves[second]))
		gut.p("%s: menor diferença de silhueta entre dois indivíduos do papel: %.3f (limite %.2f)" % [role, smallest, MIN_PAIR_GAP])
		assert_gt(smallest, MIN_PAIR_GAP, "%s: pares diferem na silhueta" % role)


## A pele tem normais suaves (híbrido macio na pele e facetado no tecido): muitos vértices cuja normal não é a da face.
func test_skin_has_smooth_normals_and_cloth_stays_flat() -> void:
	var mesh: ArrayMesh = InhabitantBuilder.build(InhabitantSpec.for_inhabitant(3, InhabitantSpec.VILLAGER), InhabitantBuilder.LOD_NEAR)
	var arrays: Array = mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	assert_eq(normals.size(), vertices.size(), "uma normal por vértice")
	var smooth: int = 0
	var flat: int = 0
	for index: int in range(0, vertices.size(), 3):
		var face: Vector3 = (vertices[index + 2] - vertices[index]).cross(vertices[index + 1] - vertices[index]).normalized()
		for corner: int in 3:
			var same: float = absf(normals[index + corner].dot(face))
			if same < SMOOTH_COSINE:
				smooth += 1
			else:
				flat += 1
	gut.p("vértices de pele suave: %d; vértices facetados: %d" % [smooth, flat])
	assert_gt(smooth, MIN_SMOOTH_VERTICES, "pele de normais suaves")
	assert_gt(flat, smooth, "o tecido segue facetado")
