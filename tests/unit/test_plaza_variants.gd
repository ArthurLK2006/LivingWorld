extends GutTest

## ART-3, as variantes da praça (sem renderizar): a tabela escolhe a variante pelo id do mercado, as três (a de hoje, B e C) diferem em várias medidas, a variante padrão é a praça de sempre, cada variante entrega as 7 luzes e duas montagens iguais dão a mesma praça.
const IDS: Array[StringName] = [&"a", &"b", &"c"]
const STALLS: Array[int] = [5, 4, 3]
const MIN_DIFFERENT_ASPECTS: int = 3
## Índices das medidas de `_measure`.
const STALL_ASPECT: int = 0
const CENTER_ASPECT: int = 2
## A superfície do pano na malha da barraca (a 0 é a madeira).
const CLOTH_SURFACE: int = 1
const TOLERANCE: float = 0.0001
## Quanto a frente da barraca (z local) aponta para a linha central do corredor de B (cosseno).
const FACING_COSINE: float = 0.99

var _root: Node3D


func _build_with(options: PlazaBuilder.Options = null) -> PlazaBuilder.Built:
	_root = Node3D.new()
	add_child_autofree(_root)
	return PlazaBuilder.new().build(_root, options)


func _build_variant(spec: PlazaVariants.Spec) -> PlazaBuilder.Built:
	var options: PlazaBuilder.Options = PlazaBuilder.Options.new()
	options.variant = spec
	return _build_with(options)


## Resumo da geometria e da ordem dos nós; o renderer sem janela descarta as posições das instâncias do MultiMesh, então delas só entram o nome e a contagem.
func _digest() -> int:
	var digest: int = 0
	for node: Node in _root.find_children("*", "MeshInstance3D", true, false):
		var instance: MeshInstance3D = node as MeshInstance3D
		digest = hash([digest, instance.name, instance.transform])
		for surface: int in instance.mesh.get_surface_count():
			digest = hash([digest, instance.mesh.surface_get_arrays(surface)])
	for node: Node in _root.find_children("*", "MultiMeshInstance3D", true, false):
		digest = hash([digest, node.name, (node as MultiMeshInstance3D).multimesh.instance_count])
	return digest


func _count(pattern: String) -> int:
	return _root.find_children(pattern, "MeshInstance3D", true, false).size()


func _first_color(node_name: String, surface: int) -> Color:
	var mesh: ArrayMesh = (_root.get_node(node_name) as MeshInstance3D).mesh as ArrayMesh
	return (mesh.surface_get_arrays(surface)[Mesh.ARRAY_COLOR] as PackedColorArray)[0]


## Monta a variante e mede, em texto: barracas, cor do toldo, peça central, mistura de adereços e cor das paredes das casas.
func _measure(variant_id: StringName) -> PackedStringArray:
	_build_variant(PlazaVariants.named(variant_id))
	var center: String = ""
	for node_name: String in PlazaVariants.CENTER_NAMES:
		if _root.has_node(node_name):
			center = node_name
	var props: Array[int] = [_count("Crate*"), _count("Barrel*"), _count("Sack*")]
	return PackedStringArray([str(_count("Stall?")), str(_first_color("Stall0", CLOTH_SURFACE)), center, str(props), str(_first_color("House0", 0))])


func _stall_height(variant_id: StringName) -> float:
	_build_variant(PlazaVariants.named(variant_id))
	return ((_root.get_node("Stall0") as MeshInstance3D).mesh as ArrayMesh).get_aabb().size.y


func test_the_table_picks_the_variant_by_the_market_id_and_an_unknown_id_gets_the_plaza_of_today() -> void:
	assert_eq(PlazaVariants.for_market("a_market_01").center, PlazaVariants.Center.WELL)
	assert_eq(PlazaVariants.for_market("b_market_01").center, PlazaVariants.Center.FOUNTAIN)
	assert_eq(PlazaVariants.for_market("c_market_01").center, PlazaVariants.Center.ROTUNDA)
	_build_variant(PlazaVariants.named(PlazaVariants.DEFAULT))
	var today: int = _digest()
	for unknown: String in ["", "d_market_01", "t_market_01"]:
		_build_variant(PlazaVariants.for_market(unknown))
		assert_eq(_digest(), today, "id '%s' fora da tabela: a praça de hoje" % unknown)
	_build_variant(PlazaVariants.named(&"x"))
	assert_eq(_digest(), today, "variante desconhecida: a praça de hoje")


func test_the_three_variants_differ_in_at_least_three_measured_aspects() -> void:
	var measures: Array[PackedStringArray] = []
	for variant_id: StringName in IDS:
		measures.append(_measure(variant_id))
	var different: int = 0
	for aspect: int in measures[0].size():
		if measures[0][aspect] != measures[1][aspect] and measures[0][aspect] != measures[2][aspect] and measures[1][aspect] != measures[2][aspect]:
			different += 1
	assert_gte(different, MIN_DIFFERENT_ASPECTS, "Aspectos diferentes nas três variantes: %s" % [measures])
	for index: int in IDS.size():
		assert_eq(measures[index][STALL_ASPECT], str(STALLS[index]), "barracas da variante %s" % IDS[index])
		assert_eq(measures[index][CENTER_ASPECT], PlazaVariants.CENTER_NAMES[index], "peça central da variante %s" % IDS[index])


func test_variant_b_lines_its_stalls_up_in_two_rows_that_face_each_other_and_c_is_low_with_more_crates_and_sacks() -> void:
	_build_variant(PlazaVariants.named(&"b"))
	var sides: Array[float] = []
	for index: int in STALLS[1]:
		var stall: Node3D = _root.get_node("Stall%d" % index) as Node3D
		assert_gt((stall.transform.basis * Vector3.BACK).dot(Vector3(-signf(stall.position.x), 0.0, 0.0)), FACING_COSINE, "a barraca %d olha para o corredor" % index)
		sides.append(signf(stall.position.x))
	assert_eq(sides.count(-1.0), 2, "duas barracas de cada lado")
	assert_lt(_stall_height(&"c"), _stall_height(&"a"), "as barracas de C são baixas")
	_build_variant(PlazaVariants.named(&"c"))
	assert_gt(_count("Crate*") + _count("Sack*"), _count("Barrel*"), "C tem mais caixotes e sacos que barris")


func test_the_default_variant_is_the_plaza_of_always() -> void:
	var spec: PlazaVariants.Spec = PlazaVariants.named(PlazaVariants.DEFAULT)
	assert_eq(spec.stalls.size(), PlazaData.STALL_SPOTS.size(), "as mesmas barracas")
	for index: int in spec.stalls.size():
		var spot: Vector2 = PlazaData.STALL_SPOTS[index]
		assert_eq(Vector2(spec.stalls[index].x, spec.stalls[index].y), spot, "lugar da barraca %d" % index)
		assert_almost_eq(spec.stalls[index].z, atan2(-spot.x, -spot.y), TOLERANCE, "barraca %d virada para o centro" % index)
	assert_eq(spec.stall_post_m, PlazaData.STALL_POST_M)
	assert_eq(spec.prop_kinds, PlazaData.PROP_KINDS)
	assert_eq(spec.cloth_colors, PlazaData.CLOTH_COLORS)
	assert_eq(spec.wall_colors, PlazaData.WALL_COLORS)
	assert_eq(spec.roof_colors, PlazaData.ROOF_COLORS)
	assert_eq(spec.cloth_materials.size(), 3, "pano, acento quente e acento ciano")
	assert_eq(spec.center, PlazaVariants.Center.WELL)
	_build_with()
	var plain: int = _digest()
	assert_ne(plain, 0, "a montagem produziu geometria")
	assert_true(_root.has_node("Well"), "o poço de sempre")
	_build_with(PlazaBuilder.Options.new())
	assert_eq(_digest(), plain, "opções padrão montam o mesmo que build(root)")
	_build_variant(PlazaVariants.for_market("a_market_01"))
	assert_eq(_digest(), plain, "a variante A é a praça de sempre")


func test_each_variant_has_the_seven_lights_and_two_builds_are_identical() -> void:
	var digests: Array[int] = []
	for variant_id: StringName in IDS:
		var built: PlazaBuilder.Built = _build_variant(PlazaVariants.named(variant_id))
		assert_eq(built.lamp_lights.size(), PlazaData.LAMP_SPOTS.size(), "lampiões da variante %s" % variant_id)
		assert_eq(built.torch_lights.size(), PlazaData.TORCH_SPOTS.size(), "tochas da variante %s" % variant_id)
		digests.append(_digest())
		_build_variant(PlazaVariants.named(variant_id))
		assert_eq(_digest(), digests[-1], "duas montagens iguais da variante %s" % variant_id)
	assert_eq(digests.size(), IDS.size())
	assert_ne(digests[0], digests[1])
	assert_ne(digests[0], digests[2])
	assert_ne(digests[1], digests[2])
