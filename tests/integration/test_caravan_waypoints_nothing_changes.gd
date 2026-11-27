extends GutTest
## LW-099g: NADA MUDA com as docas e os pontos de passagem (simulação distante; contrato da LW-099, seções 5 e 6): a `CaravanBodiesView` com o dado REAL de apresentação (docas e pontos, se o arquivo os tem) só LÊ. A viagem de dois trechos (A-B fechada: A-C e C-B, 220 minutos) no jogo REAL (economia e `world` pelo `CaravanRig`, a economia conferida a cada minuto)
## dá o MESMO `state_hash` e o mesmo save da economia com a vista rodando a cada quadro de 100 ms (as linhas vêm da ponte real, o terreno e os locais da ponte roteirizada) e sem ela, no meio de cada trecho e no fim; a vista de fato desenhou o corpo (a prova não olhou para o vazio) e nenhuma posição é inválida. A vista não conhece a simulação: as docas e os pontos
## são só dado de apresentação.

const WORLD_DIR: String = "res://data/world"
const TRADER: int = 100
const START: int = CaravanRig.START_MINUTE
const END: int = START + 300
## Marcos no meio da viagem (minutos desde a partida): no trecho A-C (50), no C-B (130) e perto do fim dele (215).
const MARKS: Array[int] = [50, 130, 215]
const FRAME_MS: int = 100
const GROUND_M: float = 10.0
const CHUNK_M: float = 64.0
const FIRST_SPOT_M: Vector2 = Vector2(313.0, 556.0)

var _routes: RouteService
var _terrain: TerrainData
var _places: Array[Place] = []
var _reader: CaravanRoutesReader


func before_all() -> void:
	_routes = CaravanRig.load_routes()
	var terrain: TerrainLoader.LoadResult = TerrainLoader.load_dir(WORLD_DIR)
	assert_true(terrain.result.ok, terrain.result.message)
	_terrain = terrain.terrain
	var settlements: SettlementLoader.LoadResult = SettlementLoader.load_dir(WORLD_DIR, _terrain)
	assert_true(settlements.result.ok, settlements.result.message)
	_places = settlements.places
	var loaded: CaravanRoutesReader.LoadResult = CaravanRoutesReader.from_file()
	assert_true(loaded.result.ok, loaded.result.message)
	_reader = loaded.data


func _snapshot(rig: CaravanRig) -> Array:
	return [rig.runner.world.state_hash(), JSON.stringify(rig.module.serialize(), "", true, true)]


## O terreno em volta do ponto (o chunk dele e os oito vizinhos).
func _draw_terrain_around(terrain_view: TerrainView, spot: Vector2) -> void:
	var center: Vector2i = Vector2i(floori(spot.x / CHUNK_M), floori(spot.y / CHUNK_M))
	for dz: int in range(-1, 2):
		for dx: int in range(-1, 2):
			var coord: Vector2i = center + Vector2i(dx, dz)
			if not terrain_view.has_chunk(coord):
				assert_true(terrain_view.build_chunk(coord), "O chunk %s foi desenhado." % coord)


## A viagem de A a B pelo A-C e C-B até o minuto END, em quadros de 100 ms; com `watch`, a vista das caravanas lê a ponte real a cada quadro e desenha o corpo perto do foco. Devolve os retratos (hash e save) nos marcos e no fim, e quantos quadros desenharam o corpo.
func _trip(watch: bool) -> Array:
	var rig: CaravanRig = CaravanRig.build(_routes, 1)
	rig.start_new_game([TRADER] as Array[int])
	rig.set_route(CaravanRig.A_B, false)
	assert_true(rig.depart(TRADER, rig.market_a, rig.market_b).result.ok, "O comerciante parte do A ao B.")
	var bridge: ScriptedCaravanBridge = ScriptedCaravanBridge.new(null, _terrain, _places)
	var terrain_view: TerrainView = TerrainView.new()
	add_child_autofree(terrain_view)
	terrain_view.setup(bridge)
	terrain_view.set_process(false)
	var view: CaravanBodiesView = CaravanBodiesView.new()
	add_child_autofree(view)
	assert_true(view.setup(bridge, terrain_view, _reader))
	var snapshots: Array = []
	var drawn: int = 0
	var invalid: int = 0
	var spot: Vector2 = FIRST_SPOT_M
	while rig.clock().total_minutes() < END:
		rig.runner.advance_frame(FRAME_MS)
		if watch:
			bridge.rows.assign(rig.bridge.peek_caravan_bodies().bodies)
			_draw_terrain_around(terrain_view, spot)
			terrain_view.set_focus(Vector3(spot.x, GROUND_M, spot.y))
			view.reconcile()
			var body: CaravanView = view.body_of(TRADER)
			if body != null and body.visible:
				drawn += 1
				spot = Vector2(body.position.x, body.position.z)
				invalid += 0 if spot.is_finite() and is_finite(body.rotation.y) else 1
		if snapshots.size() < MARKS.size() and rig.clock().total_minutes() >= START + MARKS[snapshots.size()]:
			snapshots.append(_snapshot(rig))
	snapshots.append(_snapshot(rig))
	rig.release()
	return [snapshots, drawn, invalid]


func test_the_state_hash_and_the_save_are_the_same_with_and_without_the_visible_caravans_on_the_real_data() -> void:
	var silent: Array = _trip(false)
	var watched: Array = _trip(true)
	assert_eq([silent[0].size(), watched[0].size()], [MARKS.size() + 1, MARKS.size() + 1], "Todos os marcos foram alcançados.")
	for index: int in silent[0].size():
		var label: String = "minuto %d da viagem" % MARKS[index] if index < MARKS.size() else "no fim"
		assert_eq(watched[0][index][0], silent[0][index][0], "%s: o mesmo hash com e sem a vista das caravanas." % label)
		assert_true(watched[0][index][1] == silent[0][index][1], "%s: o mesmo save da economia com e sem a vista." % label)
		if index < MARKS.size():
			assert_true(str(silent[0][index][1]).contains("\"caravans\""), "%s: a caravana está no registro (o teste não é cego a ele)." % label)
	assert_eq(silent[1], 0, "Sem a vista nenhum corpo foi desenhado.")
	assert_gt(watched[1], 1000, "Com a vista o corpo foi desenhado em milhares de quadros (a prova não olhou para o vazio).")
	assert_eq(watched[2], 0, "Nenhuma posição nem giro inválido em todos os quadros.")
