class_name PlazaStructures
extends RefCounted
## As peças feitas pela mão do homem na praça: as barracas de pano (5 na praça de hoje), caixotes, barris e sacos, 4 postes com lampião e 3 tochas (corpo emissivo + luz pequena sem sombra), bandeirolas em catenária, a peça central (poço, fonte ou rotunda) e 3 casas. Tudo facetado (cor por vértice, sem textura); a altura de cada peça vem do chão (PlazaGround.spawn).
## As luzes pequenas ficam em `lamp_lights` e `torch_lights` para a cena acender e apagar. A ART-3 troca o que muda de uma praça para outra (barracas, adereços, panos, peça central e casas) pela ficha da variante (PlazaVariants.Spec); sem ficha vale a de hoje.

var lamp_lights: Array[OmniLight3D] = []
var torch_lights: Array[OmniLight3D] = []

var _ground: PlazaGround
var _materials: Dictionary[StringName, Material]
var _variant: PlazaVariants.Spec


func _init(ground: PlazaGround, materials: Dictionary[StringName, Material], variant: PlazaVariants.Spec = null) -> void:
	_ground = ground
	_materials = materials
	_variant = variant if variant != null else PlazaVariants.named(PlazaVariants.DEFAULT)


## As barracas, uma por lugar da variante.
func add_stalls() -> void:
	for index: int in _variant.stalls.size():
		_add_stall(index)


## Os adereços de cada barraca (os tipos da variante), espalhados na frente dela por hash.
func add_props() -> void:
	var meshes: Array[ArrayMesh] = [_crate_mesh(), _barrel_mesh(), _sack_mesh()]
	var per_stall: int = _variant.prop_kinds.size()
	for stall: int in _variant.stalls.size():
		var pose: Vector3 = _variant.stalls[stall]
		var frame: Transform3D = Transform3D(Basis(Vector3.UP, pose.z), Vector3(pose.x, 0.0, pose.y))
		for prop: int in per_stall:
			var key: int = stall * per_stall + prop
			var world: Vector3 = frame * Vector3(PlazaMeshKit.between(key, PlazaData.Channel.PROP_X, -2.6, 2.6), 0.0, PlazaMeshKit.between(key, PlazaData.Channel.PROP_Z, 1.9, 3.3))
			var node_name: String = "%s%d" % [PlazaData.PROP_NAMES[_variant.prop_kinds[prop]], key]
			_ground.spawn(meshes[_variant.prop_kinds[prop]], node_name, Vector2(world.x, world.z), PlazaMeshKit.between(key, PlazaData.Channel.PROP_YAW, 0.0, TAU), PlazaMeshKit.between(key, PlazaData.Channel.PROP_SCALE, 0.7, 1.35))


## Os postes com lampião, cada um seguido do fio de bandeirolas que o liga ao próximo (a ordem dos nós filhos é essa).
func add_lamps() -> void:
	for index: int in PlazaData.LAMP_SPOTS.size():
		_add_post("LampPost%d" % index, PlazaData.LAMP_SPOTS[index], PlazaData.LAMP_HEIGHT_M, false)
		_add_bunting(index)


## As tochas, depois dos postes.
func add_torches() -> void:
	for index: int in PlazaData.TORCH_SPOTS.size():
		_add_post("Torch%d" % index, PlazaData.TORCH_SPOTS[index], PlazaData.TORCH_HEIGHT_M, true)


## A peça central da variante (poço, fonte ou rotunda), no centro da praça.
func add_center() -> void:
	var kit: PlazaMeshKit = PlazaMeshKit.new()
	match _variant.center:
		PlazaVariants.Center.FOUNTAIN:
			_fill_fountain(kit)
		PlazaVariants.Center.ROTUNDA:
			_fill_rotunda(kit)
		_:
			_fill_well(kit)
	_ground.spawn(kit.finish(ArrayMesh.new(), _materials[&"solid"]), PlazaVariants.CENTER_NAMES[_variant.center], Vector2.ZERO)


## As casas ao fundo.
func add_houses() -> void:
	for index: int in PlazaData.HOUSE_SPOTS.size():
		_add_house(index)


## O poço, com o telhadinho de duas águas.
func _fill_well(kit: PlazaMeshKit) -> void:
	for stone: int in PlazaData.WELL_STONES:
		var angle: float = TAU * stone / PlazaData.WELL_STONES
		var tone: Color = PlazaData.STONE.darkened(PlazaMeshKit.unit(stone, PlazaData.Channel.STONE) * 0.25)
		kit.box(Vector3(cos(angle) * PlazaData.WELL_RADIUS_M, 0.4, sin(angle) * PlazaData.WELL_RADIUS_M), Vector3(0.62, 0.8, 0.42), tone, -(angle + PI * 0.5))
	kit.frustum(Vector3(0.0, 0.62, 0.0), 0.85, 0.85, 0.02, 8, PlazaData.WATER)
	for side: int in 2:
		kit.frustum(Vector3(1.15 if side == 0 else -1.15, 0.0, 0.0), 0.09, 0.08, 2.3, 6, PlazaData.WOOD)
	kit.box(Vector3(0.0, 2.3, 0.0), Vector3(2.5, 0.12, 0.14), PlazaData.WOOD)
	kit.gable(Vector3(0.0, 2.36, 0.0), Vector3(2.9, 0.7, 1.9), PlazaData.ROOF_COLORS[1])


## A fonte de B: anel de pedras como o do poço, água rasa e uma coluna com taça e um fio de água no alto.
func _fill_fountain(kit: PlazaMeshKit) -> void:
	_stone_ring(kit, PlazaData.FOUNTAIN_STONES, PlazaData.FOUNTAIN_RADIUS_M, Vector3(0.66, 0.6, 0.4), 0.0)
	var cup_top: float = PlazaData.FOUNTAIN_COLUMN_M + 0.22
	kit.frustum(Vector3(0.0, 0.42, 0.0), PlazaData.FOUNTAIN_RADIUS_M - 0.2, PlazaData.FOUNTAIN_RADIUS_M - 0.2, 0.02, PlazaData.FOUNTAIN_STONES, PlazaData.WATER)
	kit.frustum(Vector3.ZERO, 0.34, 0.22, PlazaData.FOUNTAIN_COLUMN_M, 8, PlazaData.STONE)
	kit.frustum(Vector3(0.0, PlazaData.FOUNTAIN_COLUMN_M, 0.0), 0.22, 0.6, 0.25, 8, PlazaData.STONE)
	kit.frustum(Vector3(0.0, cup_top, 0.0), 0.5, 0.5, 0.02, 8, PlazaData.WATER)
	kit.frustum(Vector3(0.0, cup_top, 0.0), 0.08, 0.0, 0.55, 6, PlazaData.WATER.lightened(0.35))


## A rotunda de C: anel de pedras irregulares sobre uma base baixa, em volta de uma pedra alta e sem água.
func _fill_rotunda(kit: PlazaMeshKit) -> void:
	_stone_ring(kit, PlazaData.ROTUNDA_STONES, PlazaData.ROTUNDA_RADIUS_M, Vector3(0.7, 0.75, 0.5), 0.5)
	kit.frustum(Vector3.ZERO, PlazaData.ROTUNDA_RADIUS_M - 0.3, PlazaData.ROTUNDA_RADIUS_M - 0.4, 0.12, PlazaData.ROTUNDA_STONES, PlazaData.STONE.darkened(0.3))
	kit.frustum(Vector3(0.0, 0.12, 0.0), 0.5, 0.28, PlazaData.ROTUNDA_MENHIR_M, 5, PlazaData.STONE.lightened(0.06), 0.4)


## Anel de `count` pedras (caixas de tamanho `size` viradas para o centro); o tom de cada uma sai do hash e, com `shrink` entre 0 e 1, a altura também (canal STONE).
func _stone_ring(kit: PlazaMeshKit, count: int, radius: float, size: Vector3, shrink: float) -> void:
	for stone: int in count:
		var angle: float = TAU * stone / count
		var luck: float = PlazaMeshKit.unit(stone, PlazaData.Channel.STONE)
		var height: float = size.y * (1.0 - shrink * luck)
		kit.box(Vector3(cos(angle) * radius, height * 0.5, sin(angle) * radius), Vector3(size.x, height, size.z), PlazaData.STONE.darkened(luck * 0.25), -(angle + PI * 0.5))


## Gera as peças de pano em uma superfície por material da variante (pano comum e acentos emissivos): a peça `item` vai para a superfície `item % quantidade`.
func _cloth_surfaces(kit: PlazaMeshKit, mesh: ArrayMesh, count: int, add_item: Callable) -> void:
	var surfaces: int = _variant.cloth_materials.size()
	for surface: int in surfaces:
		for item: int in count:
			if item % surfaces == surface:
				add_item.call(kit, item)
		kit.finish(mesh, _materials[_variant.cloth_materials[surface]])


func _add_stall(index: int) -> void:
	var pose: Vector3 = _variant.stalls[index]
	var kit: PlazaMeshKit = PlazaMeshKit.new()
	var mesh: ArrayMesh = ArrayMesh.new()
	kit.box(Vector3(0.0, 0.45, 1.0), Vector3(2.8, 0.9, 0.8), PlazaData.WOOD_LIGHT)
	for post: int in 4:
		kit.frustum(Vector3(1.5 if post % 2 == 0 else -1.5, 0.0, 1.2 if post < 2 else -1.2), 0.08, 0.07, _variant.stall_post_m, 6, PlazaData.WOOD)
	kit.finish(mesh, _materials[&"solid"])
	kit.frustum(Vector3(0.0, _variant.stall_post_m, 0.0), PlazaData.CANOPY_RADIUS_M, 0.0, PlazaData.CANOPY_RISE_M, 4, _variant.cloth_colors[index % _variant.cloth_colors.size()], PI * 0.25)
	_cloth_surfaces(kit, mesh, PlazaData.STRIPS_PER_STALL, _add_strip.bind(index))
	_ground.spawn(mesh, "Stall%d" % index, Vector2(pose.x, pose.y), pose.z)


## Tira de pano pendurada na borda da frente do toldo (a pirâmide girada 45 graus tem meia largura de 0,7071 do raio).
func _add_strip(kit: PlazaMeshKit, item: int, index: int) -> void:
	var rim: float = PlazaData.CANOPY_RADIUS_M * 0.7071
	var width: float = rim * 2.0 / PlazaData.STRIPS_PER_STALL
	var left: float = -rim + width * item
	var drop: float = PlazaMeshKit.between(index * PlazaData.STRIPS_PER_STALL + item, PlazaData.Channel.STRIP, 0.5, 1.0)
	var top_left: Vector3 = Vector3(left, _variant.stall_post_m, rim)
	var top_right: Vector3 = Vector3(left + width, _variant.stall_post_m, rim)
	kit.tri(top_left, top_right, Vector3(left + width * 0.5, _variant.stall_post_m - drop, rim), _variant.cloth_colors[(index + item) % _variant.cloth_colors.size()], top_left - Vector3.BACK)


func _crate_mesh() -> ArrayMesh:
	var kit: PlazaMeshKit = PlazaMeshKit.new()
	kit.box(Vector3(0.0, 0.35, 0.0), Vector3(0.8, 0.7, 0.8), PlazaData.WOOD_LIGHT)
	kit.box(Vector3(0.0, 0.7, 0.0), Vector3(0.88, 0.08, 0.88), PlazaData.WOOD)
	return kit.finish(ArrayMesh.new(), _materials[&"solid"])


func _barrel_mesh() -> ArrayMesh:
	var kit: PlazaMeshKit = PlazaMeshKit.new()
	kit.frustum(Vector3.ZERO, 0.3, 0.38, 0.4, 8, PlazaData.WOOD_LIGHT)
	kit.frustum(Vector3(0.0, 0.4, 0.0), 0.38, 0.3, 0.4, 8, PlazaData.WOOD_LIGHT)
	kit.frustum(Vector3(0.0, 0.34, 0.0), 0.385, 0.385, 0.07, 8, PlazaData.WOOD)
	return kit.finish(ArrayMesh.new(), _materials[&"solid"])


func _sack_mesh() -> ArrayMesh:
	var kit: PlazaMeshKit = PlazaMeshKit.new()
	kit.blob(Vector3(0.0, 0.26, 0.0), Vector3(0.34, 0.26, 0.26), Vector3i(4, 7, 1), 0.1, PlazaData.SACK)
	kit.frustum(Vector3(0.0, 0.48, 0.0), 0.1, 0.05, 0.14, 5, PlazaData.SACK.darkened(0.2))
	return kit.finish(ArrayMesh.new(), _materials[&"solid"])


## Poste com lampião (corpo emissivo e capelo) ou tocha (chama emissivo), com uma luz pequena sem sombra no alto.
func _add_post(node_name: String, spot: Vector2, height: float, is_torch: bool) -> void:
	var kit: PlazaMeshKit = PlazaMeshKit.new()
	var mesh: ArrayMesh = ArrayMesh.new()
	kit.frustum(Vector3.ZERO, 0.11, 0.07, height, 6, PlazaData.WOOD)
	if not is_torch:
		kit.frustum(Vector3(0.0, height + 0.45, 0.0), 0.32, 0.0, 0.25, 6, PlazaData.WOOD)
	kit.finish(mesh, _materials[&"solid"])
	if is_torch:
		kit.frustum(Vector3(0.0, height, 0.0), 0.14, 0.0, 0.42, 5, PlazaData.TORCH_COLOR, 0.0, false)
	else:
		kit.frustum(Vector3(0.0, height, 0.0), 0.2, 0.26, 0.45, 6, PlazaData.LAMP_COLOR)
	kit.finish(mesh, _materials[&"flame" if is_torch else &"lantern"])
	var light: OmniLight3D = OmniLight3D.new()
	light.omni_range = PlazaData.TORCH_RANGE_M if is_torch else PlazaData.LAMP_RANGE_M
	light.light_color = PlazaData.TORCH_COLOR if is_torch else PlazaData.LAMP_COLOR
	light.position = Vector3(0.0, height + 0.25, 0.0)
	_ground.spawn(mesh, node_name, spot).add_child(light)
	if is_torch:
		torch_lights.append(light)
	else:
		lamp_lights.append(light)


## Fio de bandeirolas triangulares entre o poste `edge` e o seguinte, em catenária.
func _add_bunting(edge: int) -> void:
	var mesh: ArrayMesh = ArrayMesh.new()
	_cloth_surfaces(PlazaMeshKit.new(), mesh, PlazaData.FLAGS_PER_STRING, _add_flag.bind(edge))
	_ground.attach(mesh, "Bunting%d" % edge, Transform3D.IDENTITY)


func _add_flag(kit: PlazaMeshKit, item: int, edge: int) -> void:
	var from: Vector2 = PlazaData.LAMP_SPOTS[edge]
	var to: Vector2 = PlazaData.LAMP_SPOTS[(edge + 1) % PlazaData.LAMP_SPOTS.size()]
	var left: Vector3 = _string_point(from, to, (item + 0.1) / PlazaData.FLAGS_PER_STRING)
	var right: Vector3 = _string_point(from, to, (item + 0.9) / PlazaData.FLAGS_PER_STRING)
	var middle: Vector3 = (left + right) * 0.5
	kit.tri(left, right, middle + Vector3.DOWN * PlazaData.FLAG_DROP_M, _variant.cloth_colors[(edge + item) % _variant.cloth_colors.size()], middle + Vector3.UP)


## Ponto do fio a `along` (0 a 1) do caminho: altura da catenária y = H - a * (cosh(meio / a) - cosh(s / a)), com s medido do centro do vão.
func _string_point(from: Vector2, to: Vector2, along: float) -> Vector3:
	var half: float = from.distance_to(to) * 0.5
	var sag: float = PlazaData.CATENARY_PARAM_M * (cosh(half / PlazaData.CATENARY_PARAM_M) - cosh((along - 0.5) * 2.0 * half / PlazaData.CATENARY_PARAM_M))
	var flat: Vector2 = from.lerp(to, along)
	return Vector3(flat.x, PlazaData.LAMP_HEIGHT_M - sag, flat.y)


## Casa ao fundo: paredes com base enterrada (esconde o relevo), porta, chaminé e telhado de duas águas com beiral largo.
func _add_house(index: int) -> void:
	var spec: Vector3 = PlazaData.HOUSE_SPOTS[index]
	var width: float = PlazaMeshKit.between(index, PlazaData.Channel.HOUSE, 5.5, 7.0)
	var kit: PlazaMeshKit = PlazaMeshKit.new()
	kit.box(Vector3(0.0, (PlazaData.HOUSE_WALL_M - PlazaData.HOUSE_FOUNDATION_M) * 0.5, 0.0), Vector3(width, PlazaData.HOUSE_WALL_M + PlazaData.HOUSE_FOUNDATION_M, PlazaData.HOUSE_DEPTH_M), _variant.wall_colors[index % _variant.wall_colors.size()])
	kit.box(Vector3(0.0, 1.0, PlazaData.HOUSE_DEPTH_M * 0.5 + 0.03), Vector3(1.1, 2.0, 0.12), PlazaData.WOOD)
	kit.box(Vector3(width * 0.3, PlazaData.HOUSE_WALL_M + 1.0, -0.8), Vector3(0.7, 1.6, 0.7), PlazaData.STONE)
	kit.gable(Vector3(0.0, PlazaData.HOUSE_WALL_M, 0.0), Vector3(width + 1.2, PlazaData.HOUSE_ROOF_M, PlazaData.HOUSE_DEPTH_M + 1.2), _variant.roof_colors[index % _variant.roof_colors.size()])
	_ground.spawn(kit.finish(ArrayMesh.new(), _materials[&"solid"]), "House%d" % index, Vector2(spec.x, spec.y), spec.z)
