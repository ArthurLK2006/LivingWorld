extends GutTest
## LW-099b2a: a reserva de corpos de caravana (`CaravanViewPool`), sem janela, ponte nem simulação. O tamanho vem do dado (`view.pool_size`, 8 [HIP]); no máximo UM corpo
## por comerciante (pedir de novo devolve o MESMO corpo, sem duplicado); reserva vazia devolve nulo SEM criar corpo; devolver esconde e reaproveita o corpo como novo; 100
## entradas e saídas sem vazamento nem duplicado, com pico até o tamanho da reserva; contadores no padrão do `NpcViewPool`; e a reserva não cita a simulação nem a ponte.

const SOURCE: String = "res://src/presentation/world_view/entities/caravan_view_pool.gd"
const FORBIDDEN: PackedStringArray = ["SimBridge", "SimulationHost", "EventBus", "peek_", "request_", "res://src/sim", "res://src/bridge"]
const POINT: Vector3 = Vector3(20.0, 10.0, 40.0)
const ROUNDS: int = 100
## Dado mínimo com reserva de 3 corpos, para o teste que não depende do arquivo real.
const SMALL: String = '{"version": 1, "view": {"enter_m": 80, "exit_m": 120, "lateral_offset_m": 1.2, "pool_size": 3, "max_pitch_deg": 25}, "routes": [{"route_id": "r1"}], "cargo": [{"good_id": "g1", "color": "#C4A24C", "shape": "sack"}]}'

var _real: CaravanRoutesReader
var _parent: Node3D


func before_all() -> void:
	var loaded: CaravanRoutesReader.LoadResult = CaravanRoutesReader.from_file()
	assert_true(loaded.result.ok, loaded.result.message)
	_real = loaded.data


func before_each() -> void:
	_parent = Node3D.new()
	add_child_autofree(_parent)


func _monitor(which: Performance.Monitor) -> int:
	return int(Performance.get_monitor(which))


## Todo comerciante ativo tem o SEU corpo (ligado a ele) e nenhum corpo serve a dois.
func _assert_one_body_per_trader(pool: CaravanViewPool) -> void:
	var seen: Dictionary[int, int] = {}
	for trader_id: int in pool.active_ids():
		var body: CaravanView = pool.body_of(trader_id)
		assert_eq(body.trader_id, trader_id, "o corpo do comerciante %d está ligado a ele" % trader_id)
		assert_false(seen.has(body.get_instance_id()), "o comerciante %d divide corpo com outro" % trader_id)
		seen[body.get_instance_id()] = trader_id


func test_the_pool_has_the_size_of_the_data_and_starts_with_free_hidden_bodies() -> void:
	var pool: CaravanViewPool = CaravanViewPool.new(_parent, _real)
	assert_gt(_real.pool_size, 0, "o dado real tem reserva")
	assert_eq([pool.created, pool.free_count(), pool.active_count(), _parent.get_child_count(), pool.lost_count()], [_real.pool_size, _real.pool_size, 0, _real.pool_size, 0])
	for child: Node in _parent.get_children():
		var body: CaravanView = child as CaravanView
		assert_not_null(body, "só corpos de caravana")
		assert_eq([body.visible, body.is_bound()], [false, false], "os de antemão ficam escondidos e livres")
	var small: CaravanRoutesReader.LoadResult = CaravanRoutesReader.from_json(SMALL, "pool_test")
	assert_true(small.result.ok, small.result.message)
	var small_parent: Node3D = Node3D.new()
	add_child_autofree(small_parent)
	assert_eq(CaravanViewPool.new(small_parent, small.data).created, 3, "o tamanho vem do dado: 3 no dado pequeno")
	var unloaded_parent: Node3D = Node3D.new()
	add_child_autofree(unloaded_parent)
	assert_eq(CaravanViewPool.new(unloaded_parent, CaravanRoutesReader.new()).created, 0, "dado não carregado: reserva de zero corpos, sem quebrar")


func test_taking_binds_the_body_and_giving_back_hides_it_and_counts() -> void:
	var pool: CaravanViewPool = CaravanViewPool.new(_parent, _real)
	for trader_id: int in [9, 3, 7]:
		assert_not_null(pool.take(trader_id))
	assert_eq(pool.active_ids(), [3, 7, 9] as Array[int], "os ativos saem em ordem crescente")
	var body: CaravanView = pool.body_of(7)
	assert_eq([body.trader_id, body.visible, pool.free_count(), pool.taken, pool.peak_active], [7, false, _real.pool_size - 3, 3, 3], "ligado ao comerciante e escondido até a primeira pose")
	body.apply_pose(POINT, 0.0, 0.0)
	assert_true(body.visible, "a pose o mostra")
	assert_true(pool.give_back(7))
	assert_eq([body.visible, body.trader_id, pool.body_of(7), pool.free_count(), pool.returned], [false, IdGenerator.NO_ID, null, _real.pool_size - 2, 1])
	assert_false(pool.give_back(7), "devolver de novo não faz nada")
	assert_eq(pool.returned, 1, "e não conta como devolução")
	assert_eq(_parent.get_child_count(), _real.pool_size, "nada foi apagado")


func test_the_same_trader_gets_the_same_body_and_never_a_second_one() -> void:
	var pool: CaravanViewPool = CaravanViewPool.new(_parent, _real)
	var first: CaravanView = pool.take(5)
	first.apply_pose(POINT, 1.0, 0.0)
	assert_same(pool.take(5), first, "o mesmo comerciante recebe o MESMO corpo")
	assert_same(pool.take(5), first, "quantas vezes pedir")
	assert_eq([pool.duplicate_requests, pool.taken, pool.active_count(), pool.free_count()], [2, 1, 1, _real.pool_size - 1], "o pedido repetido é contado e não tira outro corpo")
	assert_eq([first.position, first.trader_id], [POINT, 5], "e o corpo dele segue intocado")


func test_100_enters_and_exits_keep_every_node_and_never_duplicate_a_body() -> void:
	var pool: CaravanViewPool = CaravanViewPool.new(_parent, _real)
	var size: int = _real.pool_size
	var nodes_before: int = _monitor(Performance.OBJECT_NODE_COUNT)
	var orphans_before: int = _monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)
	for trader_id: int in range(1, ROUNDS + 1):
		if pool.active_count() == size:
			assert_true(pool.give_back(trader_id - size), "a reserva cheia devolve o mais antigo antes de pedir o próximo")
		assert_not_null(pool.take(trader_id))
		assert_eq(pool.lost_count(), 0)
		_assert_one_body_per_trader(pool)
	for trader_id: int in pool.active_ids():
		assert_true(pool.give_back(trader_id))
	assert_eq([pool.created, pool.taken, pool.returned, pool.peak_active], [size, ROUNDS, ROUNDS, size], "nada foi criado depois da reserva; o pico chegou ao tamanho dela e parou")
	assert_eq([pool.empty_hits, pool.duplicate_requests, pool.lost_count(), pool.active_count(), pool.free_count()], [0, 0, 0, 0, size])
	assert_eq(_monitor(Performance.OBJECT_NODE_COUNT), nodes_before, "nenhum nó nasceu nem morreu")
	assert_eq(_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT), orphans_before, "e nenhum ficou órfão")


func test_an_empty_reserve_returns_null_counts_it_and_creates_no_body() -> void:
	var pool: CaravanViewPool = CaravanViewPool.new(_parent, _real)
	var size: int = _real.pool_size
	for trader_id: int in range(1, size + 1):
		assert_not_null(pool.take(trader_id))
	assert_eq([pool.peak_active, pool.free_count()], [size, 0], "tudo em uso")
	assert_null(pool.take(size + 1), "reserva vazia: nulo")
	assert_null(pool.take(size + 2), "e de novo")
	assert_eq([pool.empty_hits, pool.created, _parent.get_child_count(), pool.active_count(), pool.taken], [2, size, size, size, size], "contado, sem criar corpo nem tirar outro")
	var freed: CaravanView = pool.body_of(1)
	assert_true(pool.give_back(1))
	assert_same(pool.take(size + 1), freed, "ao devolverem um corpo, o comerciante que esperava recebe esse mesmo")
	assert_eq(pool.created, size, "ainda sem corpo novo")


func test_an_invalid_id_is_refused_with_a_visible_error_and_takes_no_body() -> void:
	var pool: CaravanViewPool = CaravanViewPool.new(_parent, _real)
	assert_null(pool.take(IdGenerator.NO_ID))
	assert_push_error("inválido")
	assert_null(pool.take(-3))
	assert_push_error("inválido")
	assert_eq([pool.active_count(), pool.taken, pool.empty_hits, pool.duplicate_requests], [0, 0, 0, 0], "ID inválido não tira corpo nem conta como falta")
	assert_false(pool.give_back(99), "devolver quem não tem corpo não faz nada")


func test_a_returned_body_is_reused_clean_by_the_next_trader() -> void:
	var pool: CaravanViewPool = CaravanViewPool.new(_parent, _real)
	var used: CaravanView = pool.take(1)
	used.apply_state(true, "grain", 1000)
	used.apply_pose(POINT, 0.7, 0.2)
	used.apply_pose(POINT + Vector3(0.0, 0.0, -3.0), 0.7, 0.2)
	assert_true(pool.give_back(1))
	var next: CaravanView = pool.take(2)
	assert_same(next, used, "a reserva reaproveita o corpo devolvido")
	assert_eq([next.trader_id, next.visible, next.position, next.rotation, next.volume_count(), next.merchant().is_walking()], [2, false, Vector3.ZERO, Vector3.ZERO, 0, false], "como novo: sem pose, sem carga, parado")


func test_a_body_that_is_neither_free_nor_active_is_counted_as_lost() -> void:
	var pool: CaravanViewPool = CaravanViewPool.new(_parent, _real)
	_parent.add_child(CaravanView.new(_real))
	assert_eq(pool.lost_count(), 1, "o contador enxerga um corpo estranho no pai")


func test_the_pool_never_touches_the_simulation_or_the_bridge() -> void:
	var source: String = FileAccess.get_file_as_string(SOURCE)
	assert_false(source.is_empty(), "o teste achou o código da reserva")
	for forbidden: String in FORBIDDEN:
		assert_false(source.contains(forbidden), "a reserva não pode citar '%s': só apresentação, sem caminho para a simulação" % forbidden)
