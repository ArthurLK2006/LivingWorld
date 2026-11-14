extends GutTest

## ART-5b1, os arquétipos de barraca (sem renderizar): a ficha de cada variante põe um arquétipo em cada lugar; cada arquétipo existe, difere dos outros pelas medidas da malha e tem a forma que promete; o veio da madeira alterna de tábua em tábua e só algumas tiras de pano levam remendo (nunca as de acento emissivo); cada barraca cabe no retângulo de encaixe da praça sem tocar as outras; duas montagens iguais dão a mesma barraca e cada lugar tem as próprias cores.
const KINDS: Array[int] = [PlazaData.StallKind.TENT, PlazaData.StallKind.LEAN_TO, PlazaData.StallKind.PARASOL, PlazaData.StallKind.CART]
const IDS: Array[StringName] = [&"a", &"b", &"c"]
## Os materiais de pano de B (pano e acento emissivo) e os de C (só pano).
const CLOTH_AND_ACCENT: Array[StringName] = [&"cloth", &"accent_cyan"]
const CLOTH_ONLY: Array[StringName] = [&"cloth"]
## Superfícies da malha de uma barraca: 0 é a madeira, 1 o pano com a cor por vértice, 2 o acento emissivo.
const CLOTH_SURFACE: int = 1
const ACCENT_SURFACE: int = 2
## A fila de barracas de teste (m entre elas) e quantas chaves de remendo o teste olha.
const SPACING_M: float = 10.0
const KEYS_SAMPLED: int = 200
const MEND_SHARE_TOLERANCE: float = 0.1
const TOLERANCE: float = 0.001

var _root: Node3D


## Monta só as estruturas (barracas, adereços, postes e peça central) de uma praça com a ficha `spec`.
func _build(spec: PlazaVariants.Spec) -> void:
	_root = Node3D.new()
	add_child_autofree(_root)
	var options: PlazaBuilder.Options = PlazaBuilder.Options.new()
	options.has_ground = false
	options.has_vegetation = false
	options.has_houses = false
	options.variant = spec
	PlazaBuilder.new().build(_root, options)


## Ficha com `count` barracas do arquétipo `kind` em fila e os materiais de pano `cloth`.
func _spec_of(kind: int, count: int, cloth: Array[StringName]) -> PlazaVariants.Spec:
	var spec: PlazaVariants.Spec = PlazaVariants.Spec.new()
	var poses: Array[Vector3] = []
	var kinds: Array[int] = []
	for index: int in count:
		poses.append(Vector3(index * SPACING_M, 0.0, 0.0))
		kinds.append(kind)
	spec.stalls = poses
	spec.stall_kinds = kinds
	spec.cloth_materials = cloth
	return spec


func _mesh(node_name: String) -> ArrayMesh:
	return (_root.get_node(node_name) as MeshInstance3D).mesh as ArrayMesh


func _vertices(mesh: ArrayMesh, surface: int) -> PackedVector3Array:
	return mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX] as PackedVector3Array


func _triangles(mesh: ArrayMesh, surface: int) -> int:
	return int(_vertices(mesh, surface).size() / 3.0)


## O que a malha tem de seu: triângulos por superfície e tamanho da caixa.
func _signature(mesh: ArrayMesh) -> String:
	var counts: PackedStringArray = PackedStringArray()
	for surface: int in mesh.get_surface_count():
		counts.append(str(_triangles(mesh, surface)))
	return "%s %s" % [",".join(counts), mesh.get_aabb().size]


func _digest(node_name: String) -> int:
	var mesh: ArrayMesh = _mesh(node_name)
	var digest: int = 0
	for surface: int in mesh.get_surface_count():
		digest = hash([digest, mesh.surface_get_arrays(surface)])
	return digest


func _kinds_of(variant_id: StringName) -> Array[int]:
	var spec: PlazaVariants.Spec = PlazaVariants.named(variant_id)
	var kinds: Array[int] = []
	for index: int in spec.stalls.size():
		kinds.append(spec.stall_kind(index))
	return kinds


func test_the_variants_put_the_planned_archetype_in_each_place_and_a_place_without_an_entry_is_a_tent() -> void:
	var tents: Array[int] = [PlazaData.StallKind.TENT, PlazaData.StallKind.TENT, PlazaData.StallKind.TENT, PlazaData.StallKind.TENT, PlazaData.StallKind.TENT]
	assert_eq(_kinds_of(&"a"), tents, "A só tem tendas")
	assert_eq(PlazaVariants.Spec.new().stall_kind(0), PlazaData.StallKind.TENT, "ficha sem entrada: a tenda")
	var in_b: PlazaVariants.Spec = PlazaVariants.named(&"b")
	var lean_tos: Array[Vector3] = []
	for index: int in in_b.stalls.size():
		if in_b.stall_kind(index) == PlazaData.StallKind.LEAN_TO:
			lean_tos.append(in_b.stalls[index])
	assert_eq(_kinds_of(&"b").count(PlazaData.StallKind.PARASOL), 2, "B: duas mesas com guarda-sol")
	assert_eq(lean_tos.size(), 2, "B: dois toldos de uma água")
	assert_almost_eq(lean_tos[0].x, -lean_tos[1].x, TOLERANCE, "os toldos ficam em lados opostos do corredor")
	assert_almost_eq(lean_tos[0].y, lean_tos[1].y, TOLERANCE, "e de frente um para o outro")
	for kind: int in [PlazaData.StallKind.CART, PlazaData.StallKind.LEAN_TO, PlazaData.StallKind.TENT]:
		assert_eq(_kinds_of(&"c").count(kind), 1, "C: um de cada (carroça, toldo e tenda), arquétipo %d" % kind)


func test_each_archetype_exists_differs_from_the_others_and_has_the_shape_it_promises() -> void:
	var signatures: Array[String] = []
	var boxes: Array[AABB] = []
	for kind: int in KINDS:
		_build(_spec_of(kind, 1, CLOTH_AND_ACCENT))
		assert_true(_root.has_node("Stall0"), "barraca do arquétipo %d" % kind)
		signatures.append(_signature(_mesh("Stall0")))
		boxes.append(_mesh("Stall0").get_aabb())
	for first: int in KINDS.size():
		for second: int in range(first + 1, KINDS.size()):
			assert_ne(signatures[first], signatures[second], "os arquétipos %d e %d têm malhas diferentes" % [KINDS[first], KINDS[second]])
	var parasol: AABB = boxes[PlazaData.StallKind.PARASOL]
	assert_almost_eq(parasol.size.x, PlazaData.PARASOL_RADIUS_M * 2.0, TOLERANCE, "o guarda-sol é redondo: o mesmo diâmetro em x")
	assert_almost_eq(parasol.size.z, PlazaData.PARASOL_RADIUS_M * 2.0, TOLERANCE, "e em z")
	assert_almost_eq(parasol.size.y, PlazaData.PARASOL_HEIGHT_M + PlazaData.PARASOL_RISE_M, TOLERANCE, "e sobe até o centro do cone")
	var cart: AABB = boxes[PlazaData.StallKind.CART]
	assert_almost_eq(cart.size.y, PlazaData.CART_WHEEL_M + PlazaData.CART_BED_M.y + PlazaData.CART_ARCH_RISE_M, TOLERANCE, "a carroça tem roda, caixa e arco de lona")
	assert_gt(cart.size.x, cart.size.z, "é comprida")
	assert_lt(cart.size.y, boxes[PlazaData.StallKind.TENT].size.y, "e mais baixa que a tenda")


func test_the_lean_to_roof_is_higher_at_the_back_edge_than_at_the_front_edge() -> void:
	_build(_spec_of(PlazaData.StallKind.LEAN_TO, 1, CLOTH_ONLY))
	var back_top: float = -INF
	var front_top: float = -INF
	for point: Vector3 in _vertices(_mesh("Stall0"), CLOTH_SURFACE):
		if point.z < -PlazaStalls.ROOF_EDGE_Z_M + TOLERANCE:
			back_top = maxf(back_top, point.y)
		elif point.z > PlazaStalls.ROOF_EDGE_Z_M - TOLERANCE:
			front_top = maxf(front_top, point.y)
	assert_gt(back_top - front_top, PlazaData.LEAN_TO_BACK_M - PlazaData.LEAN_TO_FRONT_M, "o teto de uma água cai para a frente")


func test_the_grain_alternates_the_tone_of_the_boards_and_the_counter_front_shows_one_tone_per_board() -> void:
	for key: int in 6:
		for board: int in PlazaData.GRAIN_BOARDS - 1:
			var here: Color = PlazaStalls.grain(key, board)
			assert_eq(here.v > PlazaStalls.grain(key, board + 1).v, board % 2 == 0, "a tábua %d do conjunto %d é mais clara que a seguinte só se for par" % [board, key])
			assert_eq(PlazaStalls.grain(key, board), here, "a mesma entrada dá o mesmo tom")
	_build(_spec_of(PlazaData.StallKind.LEAN_TO, 1, CLOTH_ONLY))
	var mesh: ArrayMesh = _mesh("Stall0")
	var colors: PackedColorArray = mesh.surface_get_arrays(0)[Mesh.ARRAY_COLOR] as PackedColorArray
	var vertices: PackedVector3Array = _vertices(mesh, 0)
	var front_z: float = PlazaData.LEAN_TO_COUNTER_Z_M + PlazaData.LEAN_TO_COUNTER_M.z * 0.5 + PlazaStalls.BOARD_LIFT_M
	var tones: Array[Color] = []
	for index: int in vertices.size():
		if absf(vertices[index].z - front_z) < TOLERANCE and is_zero_approx(vertices[index].y) and not tones.has(colors[index]):
			tones.append(colors[index])
	assert_eq(tones.size(), PlazaData.GRAIN_BOARDS, "a frente do balcão, rente ao chão, mostra uma cor por tábua")
	for board: int in tones.size() - 1:
		assert_eq(tones[board].v > tones[board + 1].v, board % 2 == 0, "e o tom alterna de uma tábua para a outra (tábua %d)" % board)


func test_only_some_strips_get_a_mend_as_one_more_triangle_and_the_accent_strips_never_do() -> void:
	var mended: int = 0
	for key: int in KEYS_SAMPLED:
		mended += 1 if PlazaStalls.is_mended(key) else 0
	assert_almost_eq(float(mended) / KEYS_SAMPLED, PlazaData.MEND_CHANCE, MEND_SHARE_TOLERANCE, "algumas tiras, perto da chance da ficha")
	var strips: int = PlazaData.CART_ARCH_BANDS * PlazaData.CART_ARCH_SEGMENTS
	var expected: int = 0
	for key: int in strips:
		expected += 1 if PlazaStalls.is_mended(key) else 0
	_build(_spec_of(PlazaData.StallKind.CART, 1, CLOTH_ONLY))
	assert_gt(expected, 0, "a carroça 0 tem remendos")
	assert_eq(_triangles(_mesh("Stall0"), CLOTH_SURFACE), 2 * strips + expected, "cada faixa tem 2 triângulos e cada remendo, 1")
	_build(_spec_of(PlazaData.StallKind.LEAN_TO, 3, CLOTH_AND_ACCENT))
	for index: int in 3:
		assert_eq(_triangles(_mesh("Stall%d" % index), ACCENT_SURFACE), int(PlazaData.STRIPS_PER_STALL / 2.0), "as tiras de acento do toldo %d seguem lisas" % index)


func test_every_stall_of_every_variant_fits_the_footprint_and_the_new_ones_clear_each_other() -> void:
	for variant_id: StringName in IDS:
		var spec: PlazaVariants.Spec = PlazaVariants.named(variant_id)
		_build(spec)
		var rects: Array[Rect2] = []
		for index: int in spec.stalls.size():
			var instance: MeshInstance3D = _root.get_node("Stall%d" % index) as MeshInstance3D
			var box: AABB = instance.transform * instance.mesh.get_aabb()
			var rect: Rect2 = Rect2(box.position.x, box.position.z, box.size.x, box.size.z)
			assert_true(MarketPlazaView.FOOTPRINT_M.grow(TOLERANCE).encloses(rect), "a barraca %d da variante %s cabe no encaixe" % [index, variant_id])
			if variant_id != &"a":
				for other: Rect2 in rects:
					assert_false(rect.intersects(other), "a barraca %d da variante %s não toca as outras" % [index, variant_id])
			rects.append(rect)


func test_two_builds_of_each_archetype_are_identical_and_each_place_has_its_own_colors() -> void:
	for kind: int in KINDS:
		_build(_spec_of(kind, 2, CLOTH_AND_ACCENT))
		var first: int = _digest("Stall0")
		var second: int = _digest("Stall1")
		assert_ne(first, second, "os lugares 0 e 1 do arquétipo %d diferem (cor e hash por lugar)" % kind)
		_build(_spec_of(kind, 2, CLOTH_AND_ACCENT))
		assert_eq(_digest("Stall0"), first, "duas montagens iguais, lugar 0, arquétipo %d" % kind)
		assert_eq(_digest("Stall1"), second, "duas montagens iguais, lugar 1, arquétipo %d" % kind)
