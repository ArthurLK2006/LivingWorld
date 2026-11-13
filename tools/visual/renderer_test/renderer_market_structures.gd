class_name RendererMarketStructures
extends RefCounted
## As peças feitas pela mão do homem na praça: 5 barracas de pano, caixotes, barris e sacos, 4 postes com lampião e 3 tochas (corpo emissivo + luz pequena sem sombra), bandeirolas em catenária, poço e 3 casas. Tudo facetado (cor por vértice, sem textura); a altura de cada peça vem do chão (RendererMarketGround.spawn). As luzes pequenas ficam em `lamp_lights` e `torch_lights` para a cena acender e apagar.

var lamp_lights: Array[OmniLight3D] = []
var torch_lights: Array[OmniLight3D] = []

var _ground: RendererMarketGround
var _materials: Dictionary[StringName, Material]


func _init(ground: RendererMarketGround, materials: Dictionary[StringName, Material]) -> void:
	_ground = ground
	_materials = materials


## As barracas, uma por lugar de RendererMarketData.STALL_SPOTS.
func add_stalls() -> void:
	for index: int in RendererMarketData.STALL_SPOTS.size():
		_add_stall(index)


## Os adereços de cada barraca (RendererMarketData.PROP_KINDS), espalhados na frente dela por hash.
func add_props() -> void:
	var meshes: Array[ArrayMesh] = [_crate_mesh(), _barrel_mesh(), _sack_mesh()]
	for stall: int in RendererMarketData.STALL_SPOTS.size():
		var spot: Vector2 = RendererMarketData.STALL_SPOTS[stall]
		var frame: Transform3D = Transform3D(Basis(Vector3.UP, atan2(-spot.x, -spot.y)), Vector3(spot.x, 0.0, spot.y))
		for prop: int in RendererMarketData.PROP_KINDS.size():
			var key: int = stall * RendererMarketData.PROP_KINDS.size() + prop
			var world: Vector3 = frame * Vector3(RendererMeshKit.between(key, RendererMarketData.Channel.PROP_X, -2.6, 2.6), 0.0, RendererMeshKit.between(key, RendererMarketData.Channel.PROP_Z, 1.9, 3.3))
			var node_name: String = "%s%d" % [RendererMarketData.PROP_NAMES[RendererMarketData.PROP_KINDS[prop]], key]
			_ground.spawn(meshes[RendererMarketData.PROP_KINDS[prop]], node_name, Vector2(world.x, world.z), RendererMeshKit.between(key, RendererMarketData.Channel.PROP_YAW, 0.0, TAU), RendererMeshKit.between(key, RendererMarketData.Channel.PROP_SCALE, 0.7, 1.35))


## Os postes com lampião, cada um seguido do fio de bandeirolas que o liga ao próximo (a ordem dos nós filhos é essa).
func add_lamps() -> void:
	for index: int in RendererMarketData.LAMP_SPOTS.size():
		_add_post("LampPost%d" % index, RendererMarketData.LAMP_SPOTS[index], RendererMarketData.LAMP_HEIGHT_M, false)
		_add_bunting(index)


## As tochas, depois dos postes.
func add_torches() -> void:
	for index: int in RendererMarketData.TORCH_SPOTS.size():
		_add_post("Torch%d" % index, RendererMarketData.TORCH_SPOTS[index], RendererMarketData.TORCH_HEIGHT_M, true)


## O poço no centro da praça, com o telhadinho de duas águas.
func add_well() -> void:
	var kit: RendererMeshKit = RendererMeshKit.new()
	for stone: int in RendererMarketData.WELL_STONES:
		var angle: float = TAU * stone / RendererMarketData.WELL_STONES
		var tone: Color = RendererMarketData.STONE.darkened(RendererMeshKit.unit(stone, RendererMarketData.Channel.STONE) * 0.25)
		kit.box(Vector3(cos(angle) * RendererMarketData.WELL_RADIUS_M, 0.4, sin(angle) * RendererMarketData.WELL_RADIUS_M), Vector3(0.62, 0.8, 0.42), tone, -(angle + PI * 0.5))
	kit.frustum(Vector3(0.0, 0.62, 0.0), 0.85, 0.85, 0.02, 8, RendererMarketData.WATER)
	for side: int in 2:
		kit.frustum(Vector3(1.15 if side == 0 else -1.15, 0.0, 0.0), 0.09, 0.08, 2.3, 6, RendererMarketData.WOOD)
	kit.box(Vector3(0.0, 2.3, 0.0), Vector3(2.5, 0.12, 0.14), RendererMarketData.WOOD)
	kit.gable(Vector3(0.0, 2.36, 0.0), Vector3(2.9, 0.7, 1.9), RendererMarketData.ROOF_COLORS[1])
	_ground.spawn(kit.finish(ArrayMesh.new(), _materials[&"solid"]), "Well", Vector2.ZERO)


## As casas ao fundo.
func add_houses() -> void:
	for index: int in RendererMarketData.HOUSE_SPOTS.size():
		_add_house(index)


## Gera as peças de pano em 3 superfícies: pano comum (cor por vértice), acento quente e acento ciano (emissivos). A peça `item` vai para a superfície `item % 3`.
func _cloth_surfaces(kit: RendererMeshKit, mesh: ArrayMesh, count: int, add_item: Callable) -> void:
	var materials: Array[Material] = [_materials[&"cloth"], _materials[&"accent_warm"], _materials[&"accent_cyan"]]
	for surface: int in materials.size():
		for item: int in count:
			if item % materials.size() == surface:
				add_item.call(kit, item)
		kit.finish(mesh, materials[surface])


func _add_stall(index: int) -> void:
	var spot: Vector2 = RendererMarketData.STALL_SPOTS[index]
	var kit: RendererMeshKit = RendererMeshKit.new()
	var mesh: ArrayMesh = ArrayMesh.new()
	kit.box(Vector3(0.0, 0.45, 1.0), Vector3(2.8, 0.9, 0.8), RendererMarketData.WOOD_LIGHT)
	for post: int in 4:
		kit.frustum(Vector3(1.5 if post % 2 == 0 else -1.5, 0.0, 1.2 if post < 2 else -1.2), 0.08, 0.07, RendererMarketData.STALL_POST_M, 6, RendererMarketData.WOOD)
	kit.finish(mesh, _materials[&"solid"])
	kit.frustum(Vector3(0.0, RendererMarketData.STALL_POST_M, 0.0), RendererMarketData.CANOPY_RADIUS_M, 0.0, RendererMarketData.CANOPY_RISE_M, 4, RendererMarketData.CLOTH_COLORS[index % RendererMarketData.CLOTH_COLORS.size()], PI * 0.25)
	_cloth_surfaces(kit, mesh, RendererMarketData.STRIPS_PER_STALL, _add_strip.bind(index))
	_ground.spawn(mesh, "Stall%d" % index, spot, atan2(-spot.x, -spot.y))


## Tira de pano pendurada na borda da frente do toldo (a pirâmide girada 45 graus tem meia largura de 0,7071 do raio).
func _add_strip(kit: RendererMeshKit, item: int, index: int) -> void:
	var rim: float = RendererMarketData.CANOPY_RADIUS_M * 0.7071
	var width: float = rim * 2.0 / RendererMarketData.STRIPS_PER_STALL
	var left: float = -rim + width * item
	var drop: float = RendererMeshKit.between(index * RendererMarketData.STRIPS_PER_STALL + item, RendererMarketData.Channel.STRIP, 0.5, 1.0)
	var top_left: Vector3 = Vector3(left, RendererMarketData.STALL_POST_M, rim)
	var top_right: Vector3 = Vector3(left + width, RendererMarketData.STALL_POST_M, rim)
	kit.tri(top_left, top_right, Vector3(left + width * 0.5, RendererMarketData.STALL_POST_M - drop, rim), RendererMarketData.CLOTH_COLORS[(index + item) % RendererMarketData.CLOTH_COLORS.size()], top_left - Vector3.BACK)


func _crate_mesh() -> ArrayMesh:
	var kit: RendererMeshKit = RendererMeshKit.new()
	kit.box(Vector3(0.0, 0.35, 0.0), Vector3(0.8, 0.7, 0.8), RendererMarketData.WOOD_LIGHT)
	kit.box(Vector3(0.0, 0.7, 0.0), Vector3(0.88, 0.08, 0.88), RendererMarketData.WOOD)
	return kit.finish(ArrayMesh.new(), _materials[&"solid"])


func _barrel_mesh() -> ArrayMesh:
	var kit: RendererMeshKit = RendererMeshKit.new()
	kit.frustum(Vector3.ZERO, 0.3, 0.38, 0.4, 8, RendererMarketData.WOOD_LIGHT)
	kit.frustum(Vector3(0.0, 0.4, 0.0), 0.38, 0.3, 0.4, 8, RendererMarketData.WOOD_LIGHT)
	kit.frustum(Vector3(0.0, 0.34, 0.0), 0.385, 0.385, 0.07, 8, RendererMarketData.WOOD)
	return kit.finish(ArrayMesh.new(), _materials[&"solid"])


func _sack_mesh() -> ArrayMesh:
	var kit: RendererMeshKit = RendererMeshKit.new()
	kit.blob(Vector3(0.0, 0.26, 0.0), Vector3(0.34, 0.26, 0.26), Vector3i(4, 7, 1), 0.1, RendererMarketData.SACK)
	kit.frustum(Vector3(0.0, 0.48, 0.0), 0.1, 0.05, 0.14, 5, RendererMarketData.SACK.darkened(0.2))
	return kit.finish(ArrayMesh.new(), _materials[&"solid"])


## Poste com lampião (corpo emissivo e capelo) ou tocha (chama emissivo), com uma luz pequena sem sombra no alto.
func _add_post(node_name: String, spot: Vector2, height: float, is_torch: bool) -> void:
	var kit: RendererMeshKit = RendererMeshKit.new()
	var mesh: ArrayMesh = ArrayMesh.new()
	kit.frustum(Vector3.ZERO, 0.11, 0.07, height, 6, RendererMarketData.WOOD)
	if not is_torch:
		kit.frustum(Vector3(0.0, height + 0.45, 0.0), 0.32, 0.0, 0.25, 6, RendererMarketData.WOOD)
	kit.finish(mesh, _materials[&"solid"])
	if is_torch:
		kit.frustum(Vector3(0.0, height, 0.0), 0.14, 0.0, 0.42, 5, RendererMarketData.TORCH_COLOR, 0.0, false)
	else:
		kit.frustum(Vector3(0.0, height, 0.0), 0.2, 0.26, 0.45, 6, RendererMarketData.LAMP_COLOR)
	kit.finish(mesh, _materials[&"flame" if is_torch else &"lantern"])
	var light: OmniLight3D = OmniLight3D.new()
	light.omni_range = RendererMarketData.TORCH_RANGE_M if is_torch else RendererMarketData.LAMP_RANGE_M
	light.light_color = RendererMarketData.TORCH_COLOR if is_torch else RendererMarketData.LAMP_COLOR
	light.position = Vector3(0.0, height + 0.25, 0.0)
	_ground.spawn(mesh, node_name, spot).add_child(light)
	if is_torch:
		torch_lights.append(light)
	else:
		lamp_lights.append(light)


## Fio de bandeirolas triangulares entre o poste `edge` e o seguinte, em catenária.
func _add_bunting(edge: int) -> void:
	var mesh: ArrayMesh = ArrayMesh.new()
	_cloth_surfaces(RendererMeshKit.new(), mesh, RendererMarketData.FLAGS_PER_STRING, _add_flag.bind(edge))
	_ground.attach(mesh, "Bunting%d" % edge, Transform3D.IDENTITY)


func _add_flag(kit: RendererMeshKit, item: int, edge: int) -> void:
	var from: Vector2 = RendererMarketData.LAMP_SPOTS[edge]
	var to: Vector2 = RendererMarketData.LAMP_SPOTS[(edge + 1) % RendererMarketData.LAMP_SPOTS.size()]
	var left: Vector3 = _string_point(from, to, (item + 0.1) / RendererMarketData.FLAGS_PER_STRING)
	var right: Vector3 = _string_point(from, to, (item + 0.9) / RendererMarketData.FLAGS_PER_STRING)
	var middle: Vector3 = (left + right) * 0.5
	kit.tri(left, right, middle + Vector3.DOWN * RendererMarketData.FLAG_DROP_M, RendererMarketData.CLOTH_COLORS[(edge + item) % RendererMarketData.CLOTH_COLORS.size()], middle + Vector3.UP)


## Ponto do fio a `along` (0 a 1) do caminho: altura da catenária y = H - a * (cosh(meio / a) - cosh(s / a)), com s medido do centro do vão.
func _string_point(from: Vector2, to: Vector2, along: float) -> Vector3:
	var half: float = from.distance_to(to) * 0.5
	var sag: float = RendererMarketData.CATENARY_PARAM_M * (cosh(half / RendererMarketData.CATENARY_PARAM_M) - cosh((along - 0.5) * 2.0 * half / RendererMarketData.CATENARY_PARAM_M))
	var flat: Vector2 = from.lerp(to, along)
	return Vector3(flat.x, RendererMarketData.LAMP_HEIGHT_M - sag, flat.y)


## Casa ao fundo: paredes com base enterrada (esconde o relevo), porta, chaminé e telhado de duas águas com beiral largo.
func _add_house(index: int) -> void:
	var spec: Vector3 = RendererMarketData.HOUSE_SPOTS[index]
	var width: float = RendererMeshKit.between(index, RendererMarketData.Channel.HOUSE, 5.5, 7.0)
	var kit: RendererMeshKit = RendererMeshKit.new()
	kit.box(Vector3(0.0, (RendererMarketData.HOUSE_WALL_M - RendererMarketData.HOUSE_FOUNDATION_M) * 0.5, 0.0), Vector3(width, RendererMarketData.HOUSE_WALL_M + RendererMarketData.HOUSE_FOUNDATION_M, RendererMarketData.HOUSE_DEPTH_M), RendererMarketData.WALL_COLORS[index % RendererMarketData.WALL_COLORS.size()])
	kit.box(Vector3(0.0, 1.0, RendererMarketData.HOUSE_DEPTH_M * 0.5 + 0.03), Vector3(1.1, 2.0, 0.12), RendererMarketData.WOOD)
	kit.box(Vector3(width * 0.3, RendererMarketData.HOUSE_WALL_M + 1.0, -0.8), Vector3(0.7, 1.6, 0.7), RendererMarketData.STONE)
	kit.gable(Vector3(0.0, RendererMarketData.HOUSE_WALL_M, 0.0), Vector3(width + 1.2, RendererMarketData.HOUSE_ROOF_M, RendererMarketData.HOUSE_DEPTH_M + 1.2), RendererMarketData.ROOF_COLORS[index % RendererMarketData.ROOF_COLORS.size()])
	_ground.spawn(kit.finish(ArrayMesh.new(), _materials[&"solid"]), "House%d" % index, Vector2(spec.x, spec.y), spec.z)
