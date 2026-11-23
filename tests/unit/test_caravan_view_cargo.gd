extends GutTest
## LW-099b2a: a carga do corpo da caravana (`CaravanView`), sem janela, ponte nem simulação. De 0 a 3 volumes pela FAIXA do peso do lote (`load_permille`; nos limites
## 0, 1, 333, 334, 666, 667 e 1000), nunca a contagem exata; cor e forma de cada bem vêm do dado REAL (`CaravanRoutesReader`); os volumes apoiam no leito e cabem nele;
## bem desconhecido não quebra: vira um volume NEUTRO (caixa cinza), escolha documentada em `CaravanView.NEUTRAL_*`. Os tamanhos são [HIP]: confere-se a relação, não os números.

const EPS: float = 0.001
## [peso do lote em milésimos, volumes esperados]: os limites das faixas.
const BANDS: Array = [[0, 0], [1, 1], [333, 1], [334, 2], [666, 2], [667, 3], [1000, 3], [-5, 0], [5000, 3]]
const POINT: Vector3 = Vector3(320.0, 12.5, 540.0)

var _routes: CaravanRoutesReader


func before_all() -> void:
	var loaded: CaravanRoutesReader.LoadResult = CaravanRoutesReader.from_file()
	assert_true(loaded.result.ok, loaded.result.message)
	_routes = loaded.data


func _loaded_view(good_id: String, load_permille: int) -> CaravanView:
	var view: CaravanView = CaravanView.new(_routes)
	add_child_autofree(view)
	view.bind(7)
	view.apply_state(true, good_id, load_permille)
	return view


## Os volumes À MOSTRA, na ordem dos lugares.
func _shown(view: CaravanView) -> Array[MeshInstance3D]:
	var shown: Array[MeshInstance3D] = []
	for index: int in CaravanView.MAX_VOLUMES:
		var volume: MeshInstance3D = view.get_node(NodePath("%s/%s%d" % [CaravanView.CARGO_NAME, CaravanView.VOLUME_PREFIX, index])) as MeshInstance3D
		if volume.visible:
			shown.append(volume)
	return shown


func _color_of(volume: MeshInstance3D) -> Color:
	return (volume.mesh.material as StandardMaterial3D).albedo_color


## O volume no quadro do leito (a carga fica no centro do topo do leito): a caixa que ele ocupa depois do giro.
func _box_of(volume: MeshInstance3D) -> AABB:
	return volume.transform * volume.mesh.get_aabb()


func test_the_volumes_follow_the_band_of_the_lot_weight_at_every_limit() -> void:
	for band: Array in BANDS:
		var permille: int = int(band[0])
		var expected: int = int(band[1])
		assert_eq(CaravanView.volumes_for(permille), expected, "%d milésimos: %d volumes" % [permille, expected])
		var view: CaravanView = _loaded_view("grain", permille)
		assert_eq([view.volume_count(), _shown(view).size()], [expected, expected], "%d milésimos: o corpo mostra %d" % [permille, expected])


func test_the_weight_going_up_and_down_adds_and_removes_volumes_without_leaving_any_behind() -> void:
	var view: CaravanView = _loaded_view("grain", 1000)
	for permille: int in [400, 100, 0, 700, 334]:
		view.apply_state(true, "grain", permille)
		assert_eq(_shown(view).size(), CaravanView.volumes_for(permille), "%d milésimos" % permille)


func test_every_good_of_the_real_data_has_its_color_and_shape_on_all_its_volumes() -> void:
	assert_gt(_routes.cargo_ids().size(), 0, "há bens no dado")
	for good_id: String in _routes.cargo_ids():
		var shown: Array[MeshInstance3D] = _shown(_loaded_view(good_id, 1000))
		assert_eq(shown.size(), CaravanView.MAX_VOLUMES, good_id)
		for volume: MeshInstance3D in shown:
			assert_eq(_color_of(volume), _routes.cargo_color(good_id), "%s: a cor do dado" % good_id)
			_assert_shape(volume, _routes.cargo_shape(good_id), good_id)


## Cada forma tem um perfil que a distingue das outras: caixa; saco (cone, mais largo embaixo); barril (cilindro em pé); feixe (cilindro DEITADO, mais comprido que alto).
func _assert_shape(volume: MeshInstance3D, shape: String, good_id: String) -> void:
	var footprint: AABB = _box_of(volume)
	match shape:
		"box":
			assert_true(volume.mesh is BoxMesh, "%s: caixa" % good_id)
		"sack":
			var sack: CylinderMesh = volume.mesh as CylinderMesh
			assert_true(sack != null and sack.top_radius < sack.bottom_radius, "%s: saco, mais estreito em cima" % good_id)
		"barrel":
			var barrel: CylinderMesh = volume.mesh as CylinderMesh
			assert_true(barrel != null and is_equal_approx(barrel.top_radius, barrel.bottom_radius), "%s: barril, reto" % good_id)
			assert_gt(footprint.size.y, footprint.size.x, "%s: o barril fica em pé" % good_id)
		"bundle":
			assert_true(volume.mesh is CylinderMesh, "%s: feixe, um cilindro" % good_id)
			assert_gt(footprint.size.x, footprint.size.y, "%s: o feixe fica deitado, atravessado no leito" % good_id)
		_:
			fail_test("%s: forma '%s' sem desenho nesta vista" % [good_id, shape])


func test_the_volumes_rest_on_the_bed_and_fit_inside_it_spread_evenly_and_never_overlap() -> void:
	for good_id: String in _routes.cargo_ids():
		for count: int in range(1, CaravanView.MAX_VOLUMES + 1):
			var shown: Array[MeshInstance3D] = _shown(_loaded_view(good_id, count * 333))
			assert_eq(shown.size(), count, good_id)
			var middle: float = 0.0
			for index: int in shown.size():
				var box: AABB = _box_of(shown[index])
				assert_almost_eq(box.position.y, 0.0, EPS, "%s: o volume %d apoia no leito" % [good_id, index])
				assert_lte(box.end.x, CaravanView.BED_SIZE_M.x * 0.5 + EPS, "%s: cabe na largura do leito" % good_id)
				assert_gte(box.position.x, -CaravanView.BED_SIZE_M.x * 0.5 - EPS, good_id)
				assert_lte(box.end.z, CaravanView.BED_SIZE_M.z * 0.5 + EPS, "%s: e no comprimento" % good_id)
				assert_gte(box.position.z, -CaravanView.BED_SIZE_M.z * 0.5 - EPS, good_id)
				middle += shown[index].position.z / float(count)
				if index > 0:
					assert_gte(box.position.z, _box_of(shown[index - 1]).end.z - EPS, "%s: um volume não entra no outro" % good_id)
			assert_almost_eq(middle, 0.0, EPS, "%s: %d volumes repartidos em torno do centro do leito" % [good_id, count])


func test_the_cargo_is_one_good_in_one_color_and_changing_the_good_changes_all_the_volumes() -> void:
	var view: CaravanView = _loaded_view("grain", 1000)
	assert_eq(_shown(view).size(), 3)
	view.apply_state(true, "ore", 1000)
	for volume: MeshInstance3D in _shown(view):
		assert_eq(_color_of(volume), _routes.cargo_color("ore"), "a cor segue o bem")
		assert_true(volume.mesh is BoxMesh, "e a forma também (minério: caixa)")
	view.apply_state(true, "wood", 1000)
	assert_true(_shown(view)[0].mesh is CylinderMesh, "madeira: feixe")


func test_an_unknown_good_shows_a_neutral_gray_box_and_never_breaks() -> void:
	for good_id: String in ["no_such_good", ""]:
		var shown: Array[MeshInstance3D] = _shown(_loaded_view(good_id, 1000))
		assert_eq(shown.size(), CaravanView.MAX_VOLUMES, "'%s': a caravana ESTÁ carregada, o carrinho não fica vazio" % good_id)
		for volume: MeshInstance3D in shown:
			assert_eq(_color_of(volume), CaravanView.NEUTRAL_COLOR, "'%s': cor neutra, nunca o magenta de 'faltou'" % good_id)
			assert_true(volume.mesh is BoxMesh, "'%s': caixa" % good_id)
		assert_eq(_shown(_loaded_view(good_id, 0)).size(), 0, "'%s' sem peso: nenhum volume" % good_id)


func test_a_body_without_data_draws_every_good_as_the_neutral_box() -> void:
	# O dado que falhou ao carregar vem VAZIO (nunca nulo), mas o nulo também não pode quebrar o corpo.
	for routes: CaravanRoutesReader in [CaravanRoutesReader.new(), null]:
		var view: CaravanView = CaravanView.new(routes)
		add_child_autofree(view)
		view.bind(7)
		view.apply_state(true, "grain", 500)
		view.apply_pose(POINT, 0.0, 0.0)
		assert_eq([_shown(view).size(), _color_of(_shown(view)[0])], [2, CaravanView.NEUTRAL_COLOR], "sem tabela, o bem vira o volume neutro")
