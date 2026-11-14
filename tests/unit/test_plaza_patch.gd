extends GutTest

## ART-2c, a cor da mancha de terra batida (sem renderizar): contínua do centro escuro e compacto, por terra seca mais clara, até a cor do terreno na borda; variação suave de tom; sem degrau entre vértices que coincidem nem contraste de "roda" entre vizinhos; determinística.
const PATCH_RADIUS_M: float = 9.0
const TOLERANCE: float = 0.001
## Maior distância em RGB (0 a 1) entre os dois vértices de uma aresta: a roda de fatias e anéis de cor lisa da ART-2b passava de 0,19 só entre quadros vizinhos.
const MAX_NEIGHBOR_STEP: float = 0.18
## Vértices na mesma posição são o mesmo ponto da mancha: a cor só difere pela quantização de 8 bits do vértice.
const MAX_SEAM_STEP: float = 0.01
const MAX_CENTER_GRASS: float = 0.1
const MIN_GRASS_GAP: float = 0.5
const MIN_LUMA_GAP: float = 0.05
const MID_BAND: Vector2 = Vector2(0.4, 0.6)
const MM_PER_M: float = 1000.0


func _arrays() -> Array:
	var root: Node3D = Node3D.new()
	add_child_autofree(root)
	return (PlazaGround.new(root, PlazaMaterials.create()).add_patch(PATCH_RADIUS_M).mesh as ArrayMesh).surface_get_arrays(0)


func _distance(first: Color, second: Color) -> float:
	return Vector3(first.r - second.r, first.g - second.g, first.b - second.b).length()


## Cores dos vértices cuja distância ao centro, em fração do raio, fica entre `from` e `to`.
func _colors_between(arrays: Array, from: float, to: float) -> PackedColorArray:
	var points: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var colors: PackedColorArray = arrays[Mesh.ARRAY_COLOR]
	var picked: PackedColorArray = PackedColorArray()
	for index: int in points.size():
		var reach: float = Vector2(points[index].x, points[index].z).length() / PATCH_RADIUS_M
		if reach >= from - TOLERANCE and reach <= to + TOLERANCE:
			picked.append(colors[index])
	return picked


func _luma(colors: PackedColorArray) -> float:
	var total: float = 0.0
	for color: Color in colors:
		total += color.get_luminance()
	return total / colors.size()


## Só o matiz: sem a média dos canais, a terra escura do centro não "vira grama" por ser escura.
func _hue(color: Color) -> Vector3:
	var rgb: Vector3 = Vector3(color.r, color.g, color.b)
	return rgb - Vector3.ONE * (rgb.x + rgb.y + rgb.z) / 3.0


## Quanto as cores têm de grama: 0 na terra média da paleta e 1 na grama média, pela projeção do matiz no eixo terra-grama.
func _grass_share(colors: PackedColorArray) -> float:
	var dirt: Vector3 = _hue(PlazaData.DIRT.lerp(PlazaData.DIRT_DARK, 0.5))
	var axis: Vector3 = _hue(PlazaData.GRASS.lerp(PlazaData.GRASS_DARK, 0.5)) - dirt
	var total: float = 0.0
	for color: Color in colors:
		total += (_hue(color) - dirt).dot(axis) / axis.length_squared()
	return total / colors.size()


func test_no_color_step_at_shared_points_and_only_small_steps_between_neighbors() -> void:
	var arrays: Array = _arrays()
	var points: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var colors: PackedColorArray = arrays[Mesh.ARRAY_COLOR]
	var first_color: Dictionary[Vector2i, Color] = {}
	var worst_seam: float = 0.0
	var worst_edge: float = 0.0
	for index: int in points.size():
		var spot: Vector2i = Vector2i(roundi(points[index].x * MM_PER_M), roundi(points[index].z * MM_PER_M))
		if not first_color.has(spot):
			first_color[spot] = colors[index]
		worst_seam = maxf(worst_seam, _distance(first_color[spot], colors[index]))
		var corner: int = index % 3
		worst_edge = maxf(worst_edge, _distance(colors[index], colors[index - corner + (corner + 1) % 3]))
	assert_eq(first_color.size(), PlazaData.PATCH_SEGMENTS * PlazaData.PATCH_RINGS + 1, "um ponto por cruzamento de anel e setor, mais o centro (os vértices coincidem)")
	assert_lt(worst_seam, MAX_SEAM_STEP, "vértices no mesmo ponto têm a mesma cor (sem degrau nem costura)")
	assert_lt(worst_edge, MAX_NEIGHBOR_STEP, "vértices vizinhos mudam pouco de cor (sem roda)")


func test_patch_goes_from_dark_dirt_through_lighter_dirt_to_the_terrain_color() -> void:
	var arrays: Array = _arrays()
	var center: PackedColorArray = _colors_between(arrays, 0.0, 0.0)
	var band: PackedColorArray = _colors_between(arrays, MID_BAND.x, MID_BAND.y)
	var rim: PackedColorArray = _colors_between(arrays, 1.0, 1.0)
	assert_lt(_luma(center) + MIN_LUMA_GAP, _luma(band), "o centro é mais escuro que a faixa intermediária")
	assert_lt(absf(_grass_share(center)), MAX_CENTER_GRASS, "o centro é terra")
	assert_gt(_grass_share(rim), _grass_share(center) + MIN_GRASS_GAP, "a borda externa está bem mais perto da grama que o centro")
	var previous: float = -INF
	for ring: int in PlazaData.PATCH_RINGS + 1:
		var reach: float = float(ring) / PlazaData.PATCH_RINGS
		var share: float = _grass_share(_colors_between(arrays, reach, reach))
		assert_gte(share, previous - TOLERANCE, "a grama só aumenta do centro para a borda (anel %d)" % ring)
		previous = share
	assert_eq(PlazaData.PATCH_RIM_COLOR, TerrainPalette.GRASS_COLOR, "a borda termina na cor do terreno do jogo")
	var worst_rim: float = 0.0
	for color: Color in rim:
		worst_rim = maxf(worst_rim, _distance(color, TerrainPalette.GRASS_COLOR))
	assert_lt(worst_rim, MAX_SEAM_STEP, "o vértice de fora tem a cor do terreno (a borda não aparece)")


func test_two_patches_are_identical() -> void:
	assert_eq(_arrays(), _arrays(), "duas manchas iguais")
