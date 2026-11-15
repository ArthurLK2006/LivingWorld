extends GutTest
## ART-12, entrega 6c-i: a paleta própria do Ice Warrior (cor por face, grade determinística, UVs no centro da célula, fusão de cores quase iguais) com dados SINTÉTICOS, sem o ativo; o caso com o arquivo real PULA se o ativo (fora do Git) não existir.

const Source = preload("res://tools/visual/ice_figure/ice_source.gd")
const Palette = preload("res://tools/visual/ice_figure/ice_palette.gd")
const SIDE: int = 4
const RED: Color = Color8(255, 0, 0)
const GREEN: Color = Color8(0, 255, 0)
const BLUE: Color = Color8(0, 0, 255)
const QUAD_SPREAD: PackedVector2Array = [Vector2(-0.05, -0.05), Vector2(0.05, -0.05), Vector2(0.05, 0.05), Vector2(-0.05, 0.05)]
const TRIANGLE_SPREAD: PackedVector2Array = [Vector2(-0.05, -0.03), Vector2(0.05, -0.03), Vector2(0.0, 0.06)]
const BASE_GRAY: int = 10
const GRAY_KEY: int = BASE_GRAY << 16 | BASE_GRAY << 8 | BASE_GRAY
const RED_KEY: int = 0xFF0000
## Diferenças por canal (R, G, B) em relação ao cinza (10, 10, 10), em valores LITERAIS: 1 nível funde, 2 não.
const FUSING: Array[Vector3i] = [Vector3i(1, 0, 0), Vector3i(0, 1, 0), Vector3i(0, 0, 1), Vector3i(1, 1, 1)]
const NOT_FUSING: Array[Vector3i] = [Vector3i(2, 0, 0), Vector3i(0, 2, 0), Vector3i(0, 0, 2)]
## Em unidades de pixel de uma imagem 4 x 4: os 4 cantos de um quad e os 3 de um triângulo, todos em pixels verdes; a média das UVs de cada face cai no pixel (1, 1).
const CORNERS: PackedVector2Array = [Vector2(0.5, 0.5), Vector2(2.5, 0.5), Vector2(2.5, 2.5), Vector2(0.5, 2.5), Vector2(0.5, 0.5), Vector2(2.5, 0.5), Vector2(1.5, 2.5)]


## Imagem 4 x 4 com vermelho em (1,1) e (2,2), verde em (3,0) e azul em (0,3); o resto é preto.
func _images() -> Array[Image]:
	var image: Image = Image.create(SIDE, SIDE, false, Image.FORMAT_RGB8)
	image.set_pixel(1, 1, RED)
	image.set_pixel(2, 2, RED)
	image.set_pixel(3, 0, GREEN)
	image.set_pixel(0, 3, BLUE)
	var images: Array[Image] = [image, image]
	return images


## Imagem 4 x 4 só com o cinza (10,10,10) e, em (3,0), o cinza mais `delta` nos canais R, G e B.
func _pair(delta: Vector3i) -> Array[Image]:
	var image: Image = Image.create(SIDE, SIDE, false, Image.FORMAT_RGB8)
	image.fill(Color8(BASE_GRAY, BASE_GRAY, BASE_GRAY))
	image.set_pixel(3, 0, Color8(BASE_GRAY + delta.x, BASE_GRAY + delta.y, BASE_GRAY + delta.z))
	var images: Array[Image] = [image, image]
	return images


## Uma face em torno do pixel dado: vértices próprios (4 = quad de 2 triângulos; 3 = triângulo) com UVs cuja média é o centro do pixel.
func _face(surf: Source.Surf, pixel: Vector2i, quad: bool) -> void:
	var first: int = surf.positions.size()
	var spread: PackedVector2Array = QUAD_SPREAD if quad else TRIANGLE_SPREAD
	for offset: Vector2 in spread:
		surf.positions.append(Vector3.ZERO)
		surf.uvs.append((Vector2(pixel) + Vector2(0.5, 0.5)) / float(SIDE) + offset)
	surf.indices.append_array(PackedInt32Array([first, first + 1, first + 2]))
	if quad:
		surf.indices.append_array(PackedInt32Array([first, first + 2, first + 3]))


## Superfície 1: quad em (1,1) e triângulo em (3,0). Superfície 2: triângulo em (0,3), quad em (2,2) e um vértice sem triângulo.
func _surfs() -> Array[Source.Surf]:
	var first: Source.Surf = Source.Surf.new()
	_face(first, Vector2i(1, 1), true)
	_face(first, Vector2i(3, 0), false)
	var second: Source.Surf = Source.Surf.new()
	_face(second, Vector2i(0, 3), false)
	_face(second, Vector2i(2, 2), true)
	second.positions.append(Vector3.ZERO)
	second.uvs.append(Vector2.ONE)
	var surfs: Array[Source.Surf] = [first, second]
	return surfs


func _sample(built: Palette.Built, uv: Vector2) -> Color:
	var size: int = built.image.get_width()
	return built.image.get_pixel(floori(uv.x * size), floori(uv.y * size))


func test_grid_cells_follow_color_order_and_uvs_hit_the_face_color() -> void:
	var built: Palette.Built = Palette.build(_surfs(), _images())
	assert_eq([built.error, built.distinct, built.colors.size()], ["", 3, 3])
	assert_eq(built.image.get_size(), Vector2i(8, 8), "3 cores: 2 x 2 células de 4 px")
	assert_eq([built.image.get_pixel(0, 0), built.image.get_pixel(3, 3), built.image.get_pixel(4, 0), built.image.get_pixel(0, 4), built.image.get_pixel(7, 7)], [BLUE, BLUE, GREEN, RED, Color.BLACK])
	assert_eq([_sample(built, built.uvs[0][0]), _sample(built, built.uvs[0][3]), _sample(built, built.uvs[0][4])], [RED, RED, GREEN], "quad e triângulo da superfície 1")
	assert_eq([_sample(built, built.uvs[1][0]), _sample(built, built.uvs[1][3])], [BLUE, RED], "a mesma cor em faces distintas usa uma célula só")
	assert_eq(built.uvs[0][0], built.uvs[0][2], "todos os vértices da face na mesma UV (centro da célula)")
	assert_eq(built.uvs[0][0], Vector2(0.25, 0.75), "centro da célula (0, 1) em 8 px")


func test_unused_vertex_points_inside_the_palette_and_input_is_not_changed() -> void:
	var surfs: Array[Source.Surf] = _surfs()
	var before: PackedVector2Array = surfs[1].uvs.duplicate()
	var built: Palette.Built = Palette.build(surfs, _images())
	assert_eq(built.uvs[1][built.uvs[1].size() - 1], Vector2(0.25, 0.25), "vértice sem triângulo vai para a célula 0")
	assert_eq(surfs[1].uvs, before, "a fonte não é alterada")


func test_same_input_gives_the_same_bytes() -> void:
	var first: Palette.Built = Palette.build(_surfs(), _images())
	var second: Palette.Built = Palette.build(_surfs(), _images())
	assert_eq(first.image.get_data(), second.image.get_data())
	assert_eq(first.uvs, second.uvs)


func test_colors_one_level_apart_in_any_channel_fuse_only_when_the_grid_is_full() -> void:
	for delta: Vector3i in FUSING:
		var fused: Palette.Built = Palette.build(_surfs(), _pair(delta), 1)
		assert_eq([fused.error, fused.distinct, fused.colors], ["", 2, PackedInt32Array([GRAY_KEY])], "diferença %s: funde na cor mais baixa" % delta)
		assert_eq(fused.uvs[0][0], fused.uvs[0][4], "as duas faces ficam na mesma célula")
		var kept: Palette.Built = Palette.build(_surfs(), _pair(delta), 2)
		assert_eq([kept.error, kept.colors.size()], ["", 2], "cabendo na grade, nada se funde")


func test_colors_two_levels_apart_in_any_channel_do_not_fuse_and_report_the_overflow() -> void:
	for delta: Vector3i in NOT_FUSING:
		var built: Palette.Built = Palette.build(_surfs(), _pair(delta), 1)
		assert_string_contains(built.error, "não cabe")
		assert_null(built.image, "diferença %s" % delta)


func test_face_color_is_sampled_at_the_center_of_its_uv_not_at_a_corner() -> void:
	var image: Image = Image.create(SIDE, SIDE, false, Image.FORMAT_RGB8)
	image.fill(GREEN)
	image.set_pixel(1, 1, RED)
	var surf: Source.Surf = Source.Surf.new()
	for corner: Vector2 in CORNERS:
		surf.positions.append(Vector3.ZERO)
		surf.uvs.append(corner / float(SIDE))
	surf.indices = PackedInt32Array([0, 1, 2, 0, 2, 3, 4, 5, 6])
	var surfs: Array[Source.Surf] = [surf]
	var images: Array[Image] = [image]
	var built: Palette.Built = Palette.build(surfs, images)
	assert_eq([built.error, built.colors], ["", PackedInt32Array([RED_KEY])], "só a cor do centro entra na paleta; os cantos verdes não")
	assert_eq([_sample(built, built.uvs[0][0]), _sample(built, built.uvs[0][4])], [RED, RED], "o quad e o triângulo")


func test_real_palette_fits_without_fusion() -> void:
	if not FileAccess.file_exists(Source.SOURCE_PATH):
		pending("ativo ausente (fica fora do Git): %s" % Source.SOURCE_PATH)
		return
	var surfs: Array[Source.Surf] = Source.load_surfaces()
	var images: Array[Image] = []
	for surf: Source.Surf in surfs:
		images.append(Palette.image_of(surf.material))
	var built: Palette.Built = Palette.build(surfs, images)
	assert_eq(built.error, "")
	assert_eq(built.colors.size(), built.distinct, "as cores cabem na grade: sem fusão")
