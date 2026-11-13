class_name RendererMarketBuilder
extends RefCounted
## Monta a praça de mercado procedural (cerca de 30 x 30 m) da cena de teste de renderizadores (ARTE-F0): chão de relevo suave com caminho de terra, 5 barracas de pano, caixotes, barris e
## sacos, 4 postes com lampião e 3 tochas (corpo emissivo + luz pequena sem sombra), bandeirolas em catenária, poço, 3 casas, 12 árvores, rochas, grama e flores por MultiMesh com vento por
## shader. Tudo procedural e facetado (cor por vértice, sem textura), variação por hash de inteiros; formas e lugares são [HIP] de composição, a calibrar olhando a cena.

## Contagens da cena (o teste e o resumo usam estas constantes).
const GROUND_HALF_M: int = 18
const GRASS_COUNT: int = 6000
const FLOWERS_PER_COLOR: int = 240
const TREE_COUNT: int = 12
const ROCK_COUNT: int = 8
const FLAGS_PER_STRING: int = 14
const STRIPS_PER_STALL: int = 9
const WELL_STONES: int = 8
const BLADES_PER_TUFT: int = 3
const SCATTER_ATTEMPTS: int = 6
const SCATTER_KEY_STRIDE: int = 100000
## Lugares (x, z em metros; as casas levam o giro em rad no terceiro valor). Os postes estão em ordem de laço: as bandeirolas ligam cada um ao seguinte.
const STALL_SPOTS: Array[Vector2] = [Vector2(-9.5, -2.0), Vector2(-5.5, -4.8), Vector2(0.0, -6.0), Vector2(5.5, -4.8), Vector2(9.5, -2.0)]
const LAMP_SPOTS: Array[Vector2] = [Vector2(-11.0, 9.0), Vector2(11.0, 9.0), Vector2(11.0, -7.0), Vector2(-11.0, -7.0)]
const TORCH_SPOTS: Array[Vector2] = [Vector2(-2.5, 7.0), Vector2(2.5, 7.0), Vector2(3.2, -2.0)]
const HOUSE_SPOTS: Array[Vector3] = [Vector3(-10.5, -11.5, 0.08), Vector3(0.5, -12.0, -0.05), Vector3(10.5, -11.5, 0.1)]
## Adereços de cada barraca: 0 = caixote, 1 = barril, 2 = saco (2 caixotes, 1 barril e 2 sacos por barraca).
const PROP_KINDS: Array[int] = [0, 0, 1, 2, 2]
const PROP_NAMES: Array[String] = ["Crate", "Barrel", "Sack"]
## Árvores de cones empilhados, 3 variações: (níveis de copa, raio da base, altura de cada nível).
const TREE_VARIANTS: Array[Vector3] = [Vector3(4.0, 1.5, 1.6), Vector3(3.0, 1.9, 1.9), Vector3(2.0, 2.3, 2.3)]
const TREE_RADII_M: Vector2 = Vector2(16.3, 17.4)
const ROCK_RADII_M: Vector2 = Vector2(10.5, 16.5)
## Arco das rochas (rad): só a metade da frente e as laterais, longe das casas do fundo.
const ROCK_ARC: Vector2 = Vector2(-0.47, 3.61)
## Medidas em metros [HIP].
const LAMP_HEIGHT_M: float = 5.2
const TORCH_HEIGHT_M: float = 1.8
const LAMP_RANGE_M: float = 7.5
const TORCH_RANGE_M: float = 5.0
const STALL_POST_M: float = 2.4
const CANOPY_RADIUS_M: float = 2.8
const CANOPY_RISE_M: float = 0.8
const FLAG_DROP_M: float = 0.55
const CATENARY_PARAM_M: float = 60.0
const WELL_RADIUS_M: float = 1.05
const HOUSE_WALL_M: float = 3.4
const HOUSE_ROOF_M: float = 1.7
const HOUSE_DEPTH_M: float = 4.6
const HOUSE_FOUNDATION_M: float = 0.8
const TRUNK_HEIGHT_M: float = 1.4
const FLOWER_STEM_M: float = 0.33
## Relevo suave (plano perto do poço), caminho de terra sinuoso de norte a sul e clareira de terra em volta do poço.
const RELIEF_AMPLITUDE_M: float = 0.45
const RELIEF_FLAT_RADIUS_M: float = 7.0
const RELIEF_RAMP_M: float = 6.0
const PATH_SWAY_M: float = 3.0
const PATH_WAVE: float = 0.18
const PATH_HALF_WIDTH_M: float = 1.6
const PATH_EDGE_M: float = 1.8
const PLAZA_RADIUS_M: float = 9.0
const GROUND_FLOOR_M: float = -50.0
## A grama some onde o chão é caminho de terra: a partir deste desgaste ela vai encolhendo.
const SCATTER_FADE_FROM: float = 0.4
## Paleta do guia visual (docs/arte/GUIA_VISUAL.md): ocre #B09050, marrons #907030 e #705030, oliva #909030, emissivos #FFB347, #FF9A3C e #3FE0E0.
const DIRT: Color = Color("B09050")
const DIRT_DARK: Color = Color("907030")
const GRASS: Color = Color("909030")
const GRASS_DARK: Color = Color("707028")
const WOOD: Color = Color("705030")
const WOOD_LIGHT: Color = Color("907030")
const STONE: Color = Color("8A8678")
const SACK: Color = Color("C8B078")
const WATER: Color = Color("2A3A48")
const TRUNK: Color = Color("5A3C28")
const LAMP_COLOR: Color = Color("FFB347")
const TORCH_COLOR: Color = Color("FF9A3C")
const CYAN: Color = Color("3FE0E0")
const GRASS_LOW: Color = Color("586020")
const GRASS_HIGH: Color = Color("A0A838")
const FLOWER_STEM: Color = Color("5A7A30")
const FLOWER_COLORS: Array[Color] = [Color("F0E8D0"), Color("E8C040"), Color("D060A0")]
const CLOTH_COLORS: Array[Color] = [Color("C04030"), Color("D88030"), Color("D0A030"), Color("A03858"), Color("3C7088")]
const WALL_COLORS: Array[Color] = [Color("C8B088"), Color("B89868"), Color("D0C0A0")]
const ROOF_COLORS: Array[Color] = [Color("503050"), Color("705030"), Color("A04830")]
const TREE_GREENS: Array[Color] = [Color("587838"), Color("48683A"), Color("688840")]
const SURFACE_ROUGHNESS: float = 0.85
const RIM_STRENGTH: float = 0.2
## Cada canal é uma sequência independente do hash (RendererMeshKit.unit). ROCK_RADIUS e TREE_RADIUS vêm logo depois do ângulo: `_ring_spot` usa canal e canal + 1.
enum Channel { PATCH, DIRT, GRASS, PROP_X, PROP_Z, PROP_YAW, PROP_SCALE, STRIP, HOUSE, STONE, TREE_ANGLE, TREE_RADIUS, TREE_YAW, TREE_SCALE, ROCK_ANGLE, ROCK_RADIUS, ROCK_SIZE, ROCK_YAW, SCATTER_X, SCATTER_Z, SCATTER_ACCEPT, SCATTER_SIZE, SCATTER_YAW }
## Grama e flores: lâmina de 5 pontos (3 triângulos) e quatro diagonais do chão alternadas.
const BLADE_POINTS: PackedVector3Array = [Vector3(-0.04, 0.0, 0.0), Vector3(0.04, 0.0, 0.0), Vector3(-0.025, 0.18, 0.0), Vector3(0.025, 0.18, 0.0), Vector3(0.0, 0.38, 0.03)]
const BLADE_INDICES: PackedInt32Array = [0, 1, 3, 0, 3, 2, 2, 3, 4]
const DIAGONAL_A: PackedInt32Array = [0, 1, 2, 0, 2, 3]
const DIAGONAL_B: PackedInt32Array = [0, 1, 3, 1, 2, 3]
## Vento simples: a ponta se move mais que a base; cor da base à ponta por uniformes `source_color` (o motor cuida do espaço de cor em cada renderer) e o alfa do vértice marca a cabeça da flor.
const WIND_SHADER: String = """
shader_type spatial;
render_mode cull_disabled;
uniform vec3 low_color : source_color;
uniform vec3 high_color : source_color;
uniform vec3 accent_color : source_color;
uniform float sway_amount = 0.35;
uniform float sway_speed = 1.7;
uniform float sway_scale = 0.4;
varying vec3 tint;
void vertex() {
	vec3 world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float phase = TIME * sway_speed + (world.x + world.z * 0.7) * sway_scale;
	VERTEX.x += sin(phase) * sway_amount * VERTEX.y;
	VERTEX.z += cos(phase * 0.8) * sway_amount * 0.5 * VERTEX.y;
	NORMAL = vec3(0.0, 1.0, 0.0);
	tint = mix(mix(low_color, high_color, clamp(VERTEX.y / 0.4, 0.0, 1.0)), accent_color, COLOR.a);
}
void fragment() {
	ALBEDO = tint;
	ROUGHNESS = 0.95;
}
"""


## O que a montagem deixa para a cena mexer depois: materiais (por nome) e as luzes pequenas dos lampiões e das tochas.
class Built extends RefCounted:
	var materials: Dictionary[StringName, Material] = {}
	var lamp_lights: Array[OmniLight3D] = []
	var torch_lights: Array[OmniLight3D] = []


var _root: Node3D
var _built: Built = Built.new()
var _wind_shader: Shader = Shader.new()


## Altura do relevo em (x, z): ondas suaves que crescem fora da clareira do poço.
static func ground_height(x: float, z: float) -> float:
	var swell: float = sin(x * 0.23 + 1.3) * cos(z * 0.19 + 4.1) + 0.5 * sin((x + z) * 0.41 + 2.2)
	var open_field: float = clampf((Vector2(x, z).length() - RELIEF_FLAT_RADIUS_M) / RELIEF_RAMP_M, 0.15, 1.0)
	return swell * RELIEF_AMPLITUDE_M * open_field


## Quanto de caminho de terra há em (x, z): 1 no caminho e na clareira do poço, 0 na grama.
static func path_weight(x: float, z: float) -> float:
	var lane: float = absf(x - PATH_SWAY_M * sin(z * PATH_WAVE))
	var on_lane: float = 1.0 - smoothstep(PATH_HALF_WIDTH_M, PATH_HALF_WIDTH_M + PATH_EDGE_M, lane)
	var on_plaza: float = 1.0 - smoothstep(PLAZA_RADIUS_M, PLAZA_RADIUS_M + PATH_EDGE_M, Vector2(x, z).length())
	return maxf(on_lane, on_plaza)


## Cria tudo como filhos de `root` e devolve o que a cena precisa guardar.
func build(root: Node3D) -> Built:
	_root = root
	_make_materials()
	_add_ground()
	for index: int in STALL_SPOTS.size():
		_add_stall(index)
	_add_props()
	for index: int in LAMP_SPOTS.size():
		_add_post("LampPost%d" % index, LAMP_SPOTS[index], LAMP_HEIGHT_M, false)
		_add_bunting(index)
	for index: int in TORCH_SPOTS.size():
		_add_post("Torch%d" % index, TORCH_SPOTS[index], TORCH_HEIGHT_M, true)
	_add_well()
	for index: int in HOUSE_SPOTS.size():
		_add_house(index)
	_add_trees()
	_add_rocks()
	_scatter("Grass", _tuft_mesh(), GRASS_COUNT, 0, &"grass", Vector2(0.7, 1.4))
	var flower: ArrayMesh = _flower_mesh()
	for index: int in FLOWER_COLORS.size():
		_scatter("Flowers%d" % index, flower, FLOWERS_PER_COLOR, (index + 1) * SCATTER_KEY_STRIDE, StringName("flower%d" % index), Vector2(0.8, 1.3))
	return _built


func _mat(key: StringName) -> Material:
	return _built.materials[key]


func _make_materials() -> void:
	_wind_shader.code = WIND_SHADER
	_built.materials[&"solid"] = _standard(Color.WHITE, true, BaseMaterial3D.CULL_BACK)
	_built.materials[&"cloth"] = _standard(Color.WHITE, true, BaseMaterial3D.CULL_DISABLED)
	_built.materials[&"lantern"] = _standard(LAMP_COLOR, false, BaseMaterial3D.CULL_DISABLED)
	_built.materials[&"flame"] = _standard(TORCH_COLOR, false, BaseMaterial3D.CULL_DISABLED)
	_built.materials[&"accent_warm"] = _standard(TORCH_COLOR, false, BaseMaterial3D.CULL_DISABLED)
	_built.materials[&"accent_cyan"] = _standard(CYAN, false, BaseMaterial3D.CULL_DISABLED)
	for key: StringName in [&"lantern", &"flame", &"accent_warm", &"accent_cyan"]:
		var emissive: StandardMaterial3D = _built.materials[key] as StandardMaterial3D
		emissive.emission_enabled = true
		emissive.emission = emissive.albedo_color
	_built.materials[&"grass"] = _wind(GRASS_LOW, GRASS_HIGH, Color.BLACK)
	for index: int in FLOWER_COLORS.size():
		_built.materials[StringName("flower%d" % index)] = _wind(FLOWER_STEM, FLOWER_STEM, FLOWER_COLORS[index])


func _standard(albedo: Color, uses_vertex_color: bool, cull: BaseMaterial3D.CullMode) -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = albedo
	material.vertex_color_use_as_albedo = uses_vertex_color
	material.vertex_color_is_srgb = true
	material.roughness = SURFACE_ROUGHNESS
	material.rim_enabled = true
	material.rim = RIM_STRENGTH
	material.cull_mode = cull
	return material


func _wind(low: Color, high: Color, accent: Color) -> ShaderMaterial:
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = _wind_shader
	material.set_shader_parameter(&"low_color", low)
	material.set_shader_parameter(&"high_color", high)
	material.set_shader_parameter(&"accent_color", accent)
	return material


func _attach(mesh: Mesh, node_name: String, placement: Transform3D) -> MeshInstance3D:
	var instance: MeshInstance3D = MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = mesh
	instance.transform = placement
	_root.add_child(instance)
	return instance


## Põe a malha no chão em (x, z) (a altura vem do relevo), com giro e escala.
func _spawn(mesh: Mesh, node_name: String, spot: Vector2, yaw: float = 0.0, size: float = 1.0) -> MeshInstance3D:
	var placement: Transform3D = Transform3D(Basis(Vector3.UP, yaw).scaled(Vector3.ONE * size), Vector3(spot.x, ground_height(spot.x, spot.y), spot.y))
	return _attach(mesh, node_name, placement)


func _add_ground() -> void:
	var kit: RendererMeshKit = RendererMeshKit.new()
	kit.is_shaded = false
	var cells: int = GROUND_HALF_M * 2
	for row: int in cells:
		for col: int in cells:
			var x: float = float(col - GROUND_HALF_M)
			var z: float = float(row - GROUND_HALF_M)
			var corners: Array[Vector3] = [_ground_point(x, z), _ground_point(x + 1.0, z), _ground_point(x + 1.0, z + 1.0), _ground_point(x, z + 1.0)]
			var split: PackedInt32Array = DIAGONAL_A if (row + col) % 2 == 0 else DIAGONAL_B
			for half: int in 2:
				var a: Vector3 = corners[split[half * 3]]
				var b: Vector3 = corners[split[half * 3 + 1]]
				var c: Vector3 = corners[split[half * 3 + 2]]
				var center: Vector3 = (a + b + c) / 3.0
				kit.tri(a, b, c, _ground_color(center, (row * cells + col) * 2 + half), Vector3(center.x, GROUND_FLOOR_M, center.z))
	_attach(kit.finish(ArrayMesh.new(), _mat(&"solid")), "Ground", Transform3D.IDENTITY)


func _ground_point(x: float, z: float) -> Vector3:
	return Vector3(x, ground_height(x, z), z)


## Cor do triângulo: terra ocre no caminho e na clareira, oliva no resto, com manchas e variação por triângulo.
func _ground_color(point: Vector3, tri_index: int) -> Color:
	var patch: float = 0.5 + 0.5 * sin(point.x * 0.37 + 1.1) * sin(point.z * 0.29 + 2.3)
	var wear: float = path_weight(point.x, point.z) + (patch - 0.5) * 0.7 + (RendererMeshKit.unit(tri_index, Channel.PATCH) - 0.5) * 0.3
	var dirt: Color = DIRT.lerp(DIRT_DARK, RendererMeshKit.unit(tri_index, Channel.DIRT) * 0.7)
	var grass: Color = GRASS.lerp(GRASS_DARK, RendererMeshKit.unit(tri_index, Channel.GRASS))
	return grass.lerp(dirt, smoothstep(0.35, 0.65, wear))


## Gera as peças de pano em 3 superfícies: pano comum (cor por vértice), acento quente e acento ciano (emissivos). A peça `item` vai para a superfície `item % 3`.
func _cloth_surfaces(kit: RendererMeshKit, mesh: ArrayMesh, count: int, add_item: Callable) -> void:
	var materials: Array[Material] = [_mat(&"cloth"), _mat(&"accent_warm"), _mat(&"accent_cyan")]
	for surface: int in materials.size():
		for item: int in count:
			if item % materials.size() == surface:
				add_item.call(kit, item)
		kit.finish(mesh, materials[surface])


func _add_stall(index: int) -> void:
	var spot: Vector2 = STALL_SPOTS[index]
	var kit: RendererMeshKit = RendererMeshKit.new()
	var mesh: ArrayMesh = ArrayMesh.new()
	kit.box(Vector3(0.0, 0.45, 1.0), Vector3(2.8, 0.9, 0.8), WOOD_LIGHT)
	for post: int in 4:
		kit.frustum(Vector3(1.5 if post % 2 == 0 else -1.5, 0.0, 1.2 if post < 2 else -1.2), 0.08, 0.07, STALL_POST_M, 6, WOOD)
	kit.finish(mesh, _mat(&"solid"))
	kit.frustum(Vector3(0.0, STALL_POST_M, 0.0), CANOPY_RADIUS_M, 0.0, CANOPY_RISE_M, 4, CLOTH_COLORS[index % CLOTH_COLORS.size()], PI * 0.25)
	_cloth_surfaces(kit, mesh, STRIPS_PER_STALL, _add_strip.bind(index))
	_spawn(mesh, "Stall%d" % index, spot, atan2(-spot.x, -spot.y))


## Tira de pano pendurada na borda da frente do toldo (a pirâmide girada 45 graus tem meia largura de 0,7071 do raio).
func _add_strip(kit: RendererMeshKit, item: int, index: int) -> void:
	var rim: float = CANOPY_RADIUS_M * 0.7071
	var width: float = rim * 2.0 / STRIPS_PER_STALL
	var left: float = -rim + width * item
	var drop: float = RendererMeshKit.between(index * STRIPS_PER_STALL + item, Channel.STRIP, 0.5, 1.0)
	var top_left: Vector3 = Vector3(left, STALL_POST_M, rim)
	var top_right: Vector3 = Vector3(left + width, STALL_POST_M, rim)
	kit.tri(top_left, top_right, Vector3(left + width * 0.5, STALL_POST_M - drop, rim), CLOTH_COLORS[(index + item) % CLOTH_COLORS.size()], top_left - Vector3.BACK)


func _add_props() -> void:
	var meshes: Array[ArrayMesh] = [_crate_mesh(), _barrel_mesh(), _sack_mesh()]
	for stall: int in STALL_SPOTS.size():
		var spot: Vector2 = STALL_SPOTS[stall]
		var frame: Transform3D = Transform3D(Basis(Vector3.UP, atan2(-spot.x, -spot.y)), Vector3(spot.x, 0.0, spot.y))
		for prop: int in PROP_KINDS.size():
			var key: int = stall * PROP_KINDS.size() + prop
			var world: Vector3 = frame * Vector3(RendererMeshKit.between(key, Channel.PROP_X, -2.6, 2.6), 0.0, RendererMeshKit.between(key, Channel.PROP_Z, 1.9, 3.3))
			var node_name: String = "%s%d" % [PROP_NAMES[PROP_KINDS[prop]], key]
			_spawn(meshes[PROP_KINDS[prop]], node_name, Vector2(world.x, world.z), RendererMeshKit.between(key, Channel.PROP_YAW, 0.0, TAU), RendererMeshKit.between(key, Channel.PROP_SCALE, 0.7, 1.35))


func _crate_mesh() -> ArrayMesh:
	var kit: RendererMeshKit = RendererMeshKit.new()
	kit.box(Vector3(0.0, 0.35, 0.0), Vector3(0.8, 0.7, 0.8), WOOD_LIGHT)
	kit.box(Vector3(0.0, 0.7, 0.0), Vector3(0.88, 0.08, 0.88), WOOD)
	return kit.finish(ArrayMesh.new(), _mat(&"solid"))


func _barrel_mesh() -> ArrayMesh:
	var kit: RendererMeshKit = RendererMeshKit.new()
	kit.frustum(Vector3.ZERO, 0.3, 0.38, 0.4, 8, WOOD_LIGHT)
	kit.frustum(Vector3(0.0, 0.4, 0.0), 0.38, 0.3, 0.4, 8, WOOD_LIGHT)
	kit.frustum(Vector3(0.0, 0.34, 0.0), 0.385, 0.385, 0.07, 8, WOOD)
	return kit.finish(ArrayMesh.new(), _mat(&"solid"))


func _sack_mesh() -> ArrayMesh:
	var kit: RendererMeshKit = RendererMeshKit.new()
	kit.blob(Vector3(0.0, 0.26, 0.0), Vector3(0.34, 0.26, 0.26), Vector3i(4, 7, 1), 0.1, SACK)
	kit.frustum(Vector3(0.0, 0.48, 0.0), 0.1, 0.05, 0.14, 5, SACK.darkened(0.2))
	return kit.finish(ArrayMesh.new(), _mat(&"solid"))


## Poste com lampião (corpo emissivo e capelo) ou tocha (chama emissivo), com uma luz pequena sem sombra no alto.
func _add_post(node_name: String, spot: Vector2, height: float, is_torch: bool) -> void:
	var kit: RendererMeshKit = RendererMeshKit.new()
	var mesh: ArrayMesh = ArrayMesh.new()
	kit.frustum(Vector3.ZERO, 0.11, 0.07, height, 6, WOOD)
	if not is_torch:
		kit.frustum(Vector3(0.0, height + 0.45, 0.0), 0.32, 0.0, 0.25, 6, WOOD)
	kit.finish(mesh, _mat(&"solid"))
	if is_torch:
		kit.frustum(Vector3(0.0, height, 0.0), 0.14, 0.0, 0.42, 5, TORCH_COLOR, 0.0, false)
	else:
		kit.frustum(Vector3(0.0, height, 0.0), 0.2, 0.26, 0.45, 6, LAMP_COLOR)
	kit.finish(mesh, _mat(&"flame" if is_torch else &"lantern"))
	var light: OmniLight3D = OmniLight3D.new()
	light.omni_range = TORCH_RANGE_M if is_torch else LAMP_RANGE_M
	light.light_color = TORCH_COLOR if is_torch else LAMP_COLOR
	light.position = Vector3(0.0, height + 0.25, 0.0)
	_spawn(mesh, node_name, spot).add_child(light)
	if is_torch:
		_built.torch_lights.append(light)
	else:
		_built.lamp_lights.append(light)


## Fio de bandeirolas triangulares entre o poste `edge` e o seguinte, em catenária.
func _add_bunting(edge: int) -> void:
	var mesh: ArrayMesh = ArrayMesh.new()
	_cloth_surfaces(RendererMeshKit.new(), mesh, FLAGS_PER_STRING, _add_flag.bind(edge))
	_attach(mesh, "Bunting%d" % edge, Transform3D.IDENTITY)


func _add_flag(kit: RendererMeshKit, item: int, edge: int) -> void:
	var from: Vector2 = LAMP_SPOTS[edge]
	var to: Vector2 = LAMP_SPOTS[(edge + 1) % LAMP_SPOTS.size()]
	var left: Vector3 = _string_point(from, to, (item + 0.1) / FLAGS_PER_STRING)
	var right: Vector3 = _string_point(from, to, (item + 0.9) / FLAGS_PER_STRING)
	var middle: Vector3 = (left + right) * 0.5
	kit.tri(left, right, middle + Vector3.DOWN * FLAG_DROP_M, CLOTH_COLORS[(edge + item) % CLOTH_COLORS.size()], middle + Vector3.UP)


## Ponto do fio a `along` (0 a 1) do caminho: altura da catenária y = H - a * (cosh(meio / a) - cosh(s / a)), com s medido do centro do vão.
func _string_point(from: Vector2, to: Vector2, along: float) -> Vector3:
	var half: float = from.distance_to(to) * 0.5
	var sag: float = CATENARY_PARAM_M * (cosh(half / CATENARY_PARAM_M) - cosh((along - 0.5) * 2.0 * half / CATENARY_PARAM_M))
	var flat: Vector2 = from.lerp(to, along)
	return Vector3(flat.x, LAMP_HEIGHT_M - sag, flat.y)


func _add_well() -> void:
	var kit: RendererMeshKit = RendererMeshKit.new()
	for stone: int in WELL_STONES:
		var angle: float = TAU * stone / WELL_STONES
		var tone: Color = STONE.darkened(RendererMeshKit.unit(stone, Channel.STONE) * 0.25)
		kit.box(Vector3(cos(angle) * WELL_RADIUS_M, 0.4, sin(angle) * WELL_RADIUS_M), Vector3(0.62, 0.8, 0.42), tone, -(angle + PI * 0.5))
	kit.frustum(Vector3(0.0, 0.62, 0.0), 0.85, 0.85, 0.02, 8, WATER)
	for side: int in 2:
		kit.frustum(Vector3(1.15 if side == 0 else -1.15, 0.0, 0.0), 0.09, 0.08, 2.3, 6, WOOD)
	kit.box(Vector3(0.0, 2.3, 0.0), Vector3(2.5, 0.12, 0.14), WOOD)
	kit.gable(Vector3(0.0, 2.36, 0.0), Vector3(2.9, 0.7, 1.9), ROOF_COLORS[1])
	_spawn(kit.finish(ArrayMesh.new(), _mat(&"solid")), "Well", Vector2.ZERO)


## Casa ao fundo: paredes com base enterrada (esconde o relevo), porta, chaminé e telhado de duas águas com beiral largo.
func _add_house(index: int) -> void:
	var spec: Vector3 = HOUSE_SPOTS[index]
	var width: float = RendererMeshKit.between(index, Channel.HOUSE, 5.5, 7.0)
	var kit: RendererMeshKit = RendererMeshKit.new()
	kit.box(Vector3(0.0, (HOUSE_WALL_M - HOUSE_FOUNDATION_M) * 0.5, 0.0), Vector3(width, HOUSE_WALL_M + HOUSE_FOUNDATION_M, HOUSE_DEPTH_M), WALL_COLORS[index % WALL_COLORS.size()])
	kit.box(Vector3(0.0, 1.0, HOUSE_DEPTH_M * 0.5 + 0.03), Vector3(1.1, 2.0, 0.12), WOOD)
	kit.box(Vector3(width * 0.3, HOUSE_WALL_M + 1.0, -0.8), Vector3(0.7, 1.6, 0.7), STONE)
	kit.gable(Vector3(0.0, HOUSE_WALL_M, 0.0), Vector3(width + 1.2, HOUSE_ROOF_M, HOUSE_DEPTH_M + 1.2), ROOF_COLORS[index % ROOF_COLORS.size()])
	_spawn(kit.finish(ArrayMesh.new(), _mat(&"solid")), "House%d" % index, Vector2(spec.x, spec.y), spec.z)


func _add_trees() -> void:
	var meshes: Array[ArrayMesh] = []
	for variant: int in TREE_VARIANTS.size():
		meshes.append(_tree_mesh(variant))
	for index: int in TREE_COUNT:
		var spot: Vector2 = _ring_spot(index, TREE_COUNT, Channel.TREE_ANGLE, TREE_RADII_M, Vector2(0.0, TAU))
		_spawn(meshes[index % meshes.size()], "Tree%d" % index, spot, RendererMeshKit.between(index, Channel.TREE_YAW, 0.0, TAU), RendererMeshKit.between(index, Channel.TREE_SCALE, 0.85, 1.15))


## Árvore de cones empilhados (tronco + copas que estreitam e clareiam para cima).
func _tree_mesh(variant: int) -> ArrayMesh:
	var spec: Vector3 = TREE_VARIANTS[variant]
	var kit: RendererMeshKit = RendererMeshKit.new()
	kit.frustum(Vector3(0.0, -0.3, 0.0), 0.3, 0.2, TRUNK_HEIGHT_M + 0.3, 6, TRUNK)
	for level: int in int(spec.x):
		var tone: Color = TREE_GREENS[variant].lightened(0.25 * level / spec.x)
		kit.frustum(Vector3(0.0, TRUNK_HEIGHT_M * 0.6 + level * spec.z * 0.62, 0.0), spec.y * (1.0 - 0.2 * level), 0.0, spec.z, 7, tone, level * 0.5)
	return kit.finish(ArrayMesh.new(), _mat(&"solid"))


func _add_rocks() -> void:
	for index: int in ROCK_COUNT:
		var radii: Vector3 = Vector3(RendererMeshKit.between(index, Channel.ROCK_SIZE, 0.6, 1.1), RendererMeshKit.between(index, Channel.ROCK_SIZE + 100, 0.4, 0.8), RendererMeshKit.between(index, Channel.ROCK_SIZE + 200, 0.5, 0.9))
		var kit: RendererMeshKit = RendererMeshKit.new()
		kit.blob(Vector3(0.0, radii.y * 0.6, 0.0), radii, Vector3i(4, 6, index), 0.3, STONE.darkened(RendererMeshKit.unit(index, Channel.STONE) * 0.3))
		var spot: Vector2 = _ring_spot(index, ROCK_COUNT, Channel.ROCK_ANGLE, ROCK_RADII_M, ROCK_ARC)
		_spawn(kit.finish(ArrayMesh.new(), _mat(&"solid")), "Rock%d" % index, spot, RendererMeshKit.between(index, Channel.ROCK_YAW, 0.0, TAU))


## Ponto de um anel: o item `index` de `count` ocupa a sua fatia do arco (rad) com jitter no ângulo (canal) e no raio (canal + 1).
func _ring_spot(index: int, count: int, channel: int, radii: Vector2, arc: Vector2) -> Vector2:
	var angle: float = lerpf(arc.x, arc.y, (float(index) + RendererMeshKit.unit(index, channel) * 0.6) / count)
	return Vector2(cos(angle), sin(angle)) * RendererMeshKit.between(index, channel + 1, radii.x, radii.y)


## Espalha `count` instâncias do `mesh` (MultiMesh, sem sombra) pelo chão, longe do caminho de terra, com giro e tamanho por hash.
func _scatter(node_name: String, mesh: ArrayMesh, count: int, key_offset: int, material_key: StringName, size_range: Vector2) -> void:
	var multimesh: MultiMesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = mesh
	multimesh.instance_count = count
	for index: int in count:
		var key: int = key_offset + index
		var spot: Vector2 = _scatter_spot(key)
		var fade: float = 1.0 - smoothstep(SCATTER_FADE_FROM, 1.0, path_weight(spot.x, spot.y))
		var size: float = RendererMeshKit.between(key, Channel.SCATTER_SIZE, size_range.x, size_range.y) * fade
		var turned: Basis = Basis(Vector3.UP, RendererMeshKit.between(key, Channel.SCATTER_YAW, 0.0, TAU)).scaled(Vector3.ONE * size)
		multimesh.set_instance_transform(index, Transform3D(turned, Vector3(spot.x, ground_height(spot.x, spot.y), spot.y)))
	var instance: MultiMeshInstance3D = MultiMeshInstance3D.new()
	instance.name = node_name
	instance.multimesh = multimesh
	instance.material_override = _mat(material_key)
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_root.add_child(instance)


## Sorteia (por hash) até SCATTER_ATTEMPTS posições e fica com a primeira aceita; onde há mais terra, menos chance.
func _scatter_spot(key: int) -> Vector2:
	var spot: Vector2 = Vector2.ZERO
	var extent: float = GROUND_HALF_M - 0.5
	for attempt: int in SCATTER_ATTEMPTS:
		var candidate: int = key * SCATTER_ATTEMPTS + attempt
		spot = Vector2(RendererMeshKit.between(candidate, Channel.SCATTER_X, -extent, extent), RendererMeshKit.between(candidate, Channel.SCATTER_Z, -extent, extent))
		if RendererMeshKit.unit(candidate, Channel.SCATTER_ACCEPT) > path_weight(spot.x, spot.y):
			return spot
	return spot


## Tufo de lâminas cruzadas (BLADES_PER_TUFT lâminas giradas em torno do eixo vertical); alfa 0 = cor de grama.
func _tuft_mesh() -> ArrayMesh:
	var points: PackedVector3Array = PackedVector3Array()
	var indices: PackedInt32Array = PackedInt32Array()
	var colors: PackedColorArray = PackedColorArray()
	for blade: int in BLADES_PER_TUFT:
		var first: int = points.size()
		for point: Vector3 in BLADE_POINTS:
			points.append(point.rotated(Vector3.UP, PI * blade / BLADES_PER_TUFT))
			colors.append(Color(0.0, 0.0, 0.0, 0.0))
		for corner: int in BLADE_INDICES:
			indices.append(first + corner)
	return _foliage_mesh(points, indices, colors)


## Flor: caule fino (alfa 0) e cabeça em pirâmide (alfa 1, recebe a cor de acento do material).
func _flower_mesh() -> ArrayMesh:
	var head: float = FLOWER_STEM_M
	var points: PackedVector3Array = [Vector3(-0.012, 0.0, 0.0), Vector3(0.012, 0.0, 0.0), Vector3(0.0, head, 0.0), Vector3(-0.07, head, -0.07), Vector3(0.07, head, -0.07), Vector3(0.07, head, 0.07), Vector3(-0.07, head, 0.07), Vector3(0.0, head + 0.1, 0.0)]
	var indices: PackedInt32Array = [0, 1, 2, 3, 4, 7, 4, 5, 7, 5, 6, 7, 6, 3, 7]
	var colors: PackedColorArray = PackedColorArray()
	for index: int in points.size():
		colors.append(Color(0.0, 0.0, 0.0, 0.0 if index < 3 else 1.0))
	return _foliage_mesh(points, indices, colors)


func _foliage_mesh(points: PackedVector3Array, indices: PackedInt32Array, colors: PackedColorArray) -> ArrayMesh:
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = points
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh: ArrayMesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh
