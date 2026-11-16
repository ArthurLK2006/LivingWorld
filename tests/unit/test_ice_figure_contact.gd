extends GutTest
## ART-12, entrega 6e (ii): os pontos de contato das botas (`ice_contact.gd`) e a linha de proveniência dos metadados de apresentação (`ice_writer.gd`), com dados SINTÉTICOS (nada do ativo de terceiros, nada de disco): só os vértices com peso de pé de pelo menos 0,9 entram (o peso soma as entradas do osso, em qualquer posição); os pontos de apoio de uma bota em forma de caixa são só os cantos de baixo (nunca os de cima), sem repetição, com a ponta e o calcanhar, no espaço do osso; sem vértice, sem ponto; a proveniência só ganha a linha de mudança dos metadados de apresentação quando pedida, e o JSON da figura sem a opção segue chamando `ice_figure.json`.

const Contact = preload("res://tools/visual/ice_figure/ice_contact.gd")
const Palette = preload("res://tools/visual/ice_figure/ice_palette.gd")
const Writer = preload("res://tools/visual/ice_figure/ice_writer.gd")
const FOOT_BONE: int = 3
const BOX_HALF_X_M: float = 0.05
const BOX_HEIGHT_M: float = 0.1
const BOX_HALF_Z_M: float = 0.1
## A origem do osso do pé, 8 cm acima do chão no espaço da malha (a sola fica abaixo da origem do osso) e a tolerância dos números gravados.
const ANKLE_M: float = 0.08
const TOLERANCE: float = 0.000001


func _box() -> PackedVector3Array:
	var corners: PackedVector3Array = PackedVector3Array()
	for x: float in [-BOX_HALF_X_M, BOX_HALF_X_M]:
		for y: float in [0.0, BOX_HEIGHT_M]:
			for z: float in [-BOX_HALF_Z_M, BOX_HALF_Z_M]:
				corners.append(Vector3(x, y, z))
	return corners


func test_only_the_vertices_the_bone_weighs_at_least_the_limit_are_boot_vertices() -> void:
	var positions: PackedVector3Array = PackedVector3Array([Vector3(0, 0, 0), Vector3(1, 0, 0), Vector3(2, 0, 0), Vector3(3, 0, 0)])
	var bones: PackedInt32Array = PackedInt32Array([FOOT_BONE, 0, 0, 0, FOOT_BONE, 1, 0, 0, 1, FOOT_BONE, 0, 0, FOOT_BONE, FOOT_BONE, 0, 0])
	var weights: PackedFloat32Array = PackedFloat32Array([1.0, 0.0, 0.0, 0.0, 0.85, 0.15, 0.0, 0.0, 0.05, 0.95, 0.0, 0.0, 0.5, 0.5, 0.0, 0.0])
	assert_eq(Contact.heavy_vertices(positions, bones, weights, FOOT_BONE), PackedVector3Array([positions[0], positions[2], positions[3]]), "peso 1 passa, 0,85 não, 0,95 em outra posição passa, 0,5 + 0,5 soma 1")


func test_the_support_points_of_a_box_are_its_lowest_corners_in_the_bone_space_without_repeats() -> void:
	var points: Array = Contact.support(_box(), Transform3D(Basis.IDENTITY, Vector3(0.0, ANKLE_M, 0.0)).affine_inverse())
	assert_gt(points.size(), 1, "a ponta e o calcanhar")
	assert_lte(points.size(), 4, "só os 4 cantos de baixo, sem repetição")
	var heels: int = 0
	var toes: int = 0
	for point: Array in points:
		assert_almost_eq(point[1], -ANKLE_M, TOLERANCE, "só canto de baixo: y local = -altura do osso")
		heels += 1 if is_equal_approx(point[2], -BOX_HALF_Z_M) else 0
		toes += 1 if is_equal_approx(point[2], BOX_HALF_Z_M) else 0
	assert_gt(heels, 0, "o calcanhar")
	assert_gt(toes, 0, "a ponta")


func test_a_boot_without_vertices_has_no_support_points() -> void:
	assert_eq(Contact.support(PackedVector3Array(), Transform3D.IDENTITY), [])


func test_the_provenance_gains_the_presentation_change_only_when_asked() -> void:
	var built: Palette.Built = Palette.Built.new()
	built.image = Image.create(8, 8, false, Image.FORMAT_RGB8)
	built.colors = PackedInt32Array([1, 2, 3])
	var plain: String = Writer.provenance("aaaa", "bbbb", built, 1.44)
	assert_false(plain.contains(Writer.PRESENTATION_CHANGE), "sem a opção, a proveniência é a de sempre")
	assert_eq(Writer.provenance("aaaa", "bbbb", built, 1.44, true), plain + "- " + Writer.PRESENTATION_CHANGE + "\n", "com a opção, uma linha de mudança a mais")
	assert_eq(Writer.meta_file(), Writer.DATA_FILE, "sem --meta=, o JSON é o da figura")
