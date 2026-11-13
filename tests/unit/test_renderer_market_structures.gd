extends GutTest

## ARTE-F0, estruturas e fachada (sem renderizar): o que a fachada monta (barracas, adereços, postes, bandeirolas, poço, casas, árvores, grama e flores), a ordem dos nós filhos, as luzes e os materiais entregues em `Built` e duas montagens iguais.
const TOLERANCE: float = 0.001
const BUILD_ORDER: Array[String] = ["Ground", "Stall0", "Stall4", "Crate0", "Sack24", "LampPost0", "Bunting0", "LampPost3", "Bunting3", "Torch0", "Torch2", "Well", "House0", "House2", "Tree0", "Tree11", "Rock0", "Rock7", "Grass", "Flowers0", "Flowers2"]

var _root: Node3D


func _build() -> RendererMarketBuilder.Built:
	_root = Node3D.new()
	add_child_autofree(_root)
	return RendererMarketBuilder.new().build(_root)


func _count(pattern: String, type: String) -> int:
	return _root.find_children(pattern, type, true, false).size()


## Resumo numérico da geometria; o renderer sem janela descarta as posições das instâncias do MultiMesh, então delas só entram a contagem e a malha.
func _fingerprint() -> int:
	var digest: int = 0
	for node: Node in _root.find_children("*", "MeshInstance3D", true, false):
		var instance: MeshInstance3D = node as MeshInstance3D
		digest = hash([digest, instance.transform])
		for surface: int in instance.mesh.get_surface_count():
			digest = hash([digest, instance.mesh.surface_get_arrays(surface)])
	for node: Node in _root.find_children("*", "MultiMeshInstance3D", true, false):
		var multimesh: MultiMesh = (node as MultiMeshInstance3D).multimesh
		digest = hash([digest, multimesh.instance_count, multimesh.mesh.surface_get_arrays(0), multimesh.buffer])
	return digest


func test_market_has_the_requested_content() -> void:
	var built: RendererMarketBuilder.Built = _build()
	var stalls: int = RendererMarketData.STALL_SPOTS.size()
	assert_eq(_count("Stall?", "MeshInstance3D"), stalls, "barracas")
	assert_eq(_count("Crate*", "MeshInstance3D"), 2 * stalls, "caixotes")
	assert_eq(_count("Barrel*", "MeshInstance3D"), stalls, "barris")
	assert_eq(_count("Sack*", "MeshInstance3D"), 2 * stalls, "sacos")
	assert_eq(_count("LampPost?", "MeshInstance3D"), 4, "postes com lampião")
	assert_eq(_count("Bunting?", "MeshInstance3D"), 4, "fios de bandeirolas")
	assert_eq(_count("House?", "MeshInstance3D"), 3, "casas")
	assert_eq(_count("Tree*", "MeshInstance3D"), RendererMarketData.TREE_COUNT, "árvores")
	assert_eq(_count("Well", "MeshInstance3D"), 1, "poço")
	assert_eq(built.lamp_lights.size(), 4, "luzes dos lampiões")
	assert_eq(_count("*", "OmniLight3D"), 4 + RendererMarketData.TORCH_SPOTS.size(), "luzes pequenas (lampiões e tochas)")
	var instances: int = 0
	for node: Node in _root.find_children("*", "MultiMeshInstance3D", true, false):
		instances += (node as MultiMeshInstance3D).multimesh.instance_count
	assert_eq(instances, RendererMarketData.GRASS_COUNT + RendererMarketData.FLOWERS_PER_COLOR * RendererMarketData.FLOWER_COLORS.size(), "instâncias de grama e flores")


func test_children_follow_the_build_order() -> void:
	_build()
	var last: int = -1
	for node_name: String in BUILD_ORDER:
		var index: int = _root.get_node(node_name).get_index()
		assert_gt(index, last, "%s vem depois do nó anterior" % node_name)
		last = index
	assert_eq(_root.get_node("Bunting0").get_index(), _root.get_node("LampPost0").get_index() + 1, "cada poste é seguido do seu fio de bandeirolas")


func test_built_hands_over_the_lights_and_the_materials_the_scene_drives() -> void:
	var built: RendererMarketBuilder.Built = _build()
	assert_eq(built.lamp_lights.size(), RendererMarketData.LAMP_SPOTS.size(), "um lampião por poste")
	assert_eq(built.torch_lights.size(), RendererMarketData.TORCH_SPOTS.size(), "uma luz por tocha")
	for index: int in built.lamp_lights.size():
		assert_eq(built.lamp_lights[index].get_parent().name, StringName("LampPost%d" % index), "a luz %d fica no poste" % index)
		assert_almost_eq(built.lamp_lights[index].omni_range, RendererMarketData.LAMP_RANGE_M, TOLERANCE, "alcance do lampião")
	for index: int in built.torch_lights.size():
		assert_eq(built.torch_lights[index].get_parent().name, StringName("Torch%d" % index), "a luz %d fica na tocha" % index)
		assert_false(built.torch_lights[index].shadow_enabled, "luz pequena sem sombra")
	for key: StringName in [&"solid", &"cloth", &"lantern", &"flame", &"accent_warm", &"accent_cyan", &"grass"]:
		assert_true(built.materials.has(key), "material %s entregue" % key)


func test_two_builds_are_identical() -> void:
	_build()
	var first: int = _fingerprint()
	assert_ne(first, 0, "a montagem produziu geometria")
	_build()
	assert_eq(_fingerprint(), first, "duas montagens iguais")
