class_name Sp2World
extends RefCounted
## LW-071 (SP2, DESCARTÁVEL): o mundo PRÓPRIO do spike. O jogo real registra o `npc` (GameModules), mas não liga o LOD nem o protocolo
## S0 e não entrega o `npc` à ponte (LW-069/LW-070, limitações do contrato); ligar isso exigiria mexer em src/. Então o spike monta um
## SimulationRunner com o NpcModule configurado (precedente: tests/unit/test_npc_intents.gd), com os dados REAIS (terreno, locais,
## necessidades, catálogo, LOD, tempo limite), e usa só a API pública do módulo. O relógio deste mundo copia a pausa e a velocidade do
## relógio do jogo (lidas pela ponte, peek_time). O spike chama o NpcModule direto, com as mesmas funções que a ponte só repassa.

const DATA_DIR: String = "res://data"
const WORLD_DIR: String = "res://data/world"

var runner: SimulationRunner
var module: NpcModule
var actions: ActionRunner
var places: SettlementService
var terrain: TerrainData
var director: Sp2Director
var problem: String = ""
## LodChanged recebidos desde a última leitura (o spike cria e devolve os corpos fora do passo).
var _changes: Array[LodChanged] = []
var _lod_changes_by_npc: Dictionary[int, int] = {}
## Posição lógica (cm) de quem saiu de S0, lida no instante do evento (antes de o diretor mexer no NPC no mesmo passo).
var _exit_positions: Dictionary[int, Vector2i] = {}


## `all_in_a`: os 100 NPCs nascem no povoado A (o pior caso de desenho do ensaio de carga); senão 60 em A e 40 em B. `max_s0`: 0 = o de
## data/lod_params.json; outro valor cria um LodParams em código com os mesmos raios (o arquivo não muda).
func _init(loaded_terrain: TerrainData, max_s0: int = 0, all_in_a: bool = false) -> void:
	terrain = loaded_terrain
	var loaded_places: SettlementLoader.LoadResult = SettlementLoader.load_dir(WORLD_DIR, terrain)
	var needs: NeedLoader.LoadResult = NeedLoader.load_dir(DATA_DIR)
	var catalog: ActionCatalogLoader.LoadResult = ActionCatalogLoader.load_dir(DATA_DIR)
	var lod_loaded: LodParamsLoader.LoadResult = LodParamsLoader.load_dir(DATA_DIR)
	var intent_loaded: NpcIntentParams.LoadResult = NpcIntentParams.load_dir(DATA_DIR)
	for check: Result in [loaded_places.result, needs.result, catalog.result, lod_loaded.result, intent_loaded.result]:
		if not check.ok:
			problem = check.message
			return
	places = SettlementService.new(loaded_places.settlements, loaded_places.places)
	module = NpcModule.new(needs.needs)
	var params: LodParams = lod_loaded.params
	if max_s0 > 0:
		params = LodParams.new(params.lod_enter_radius_m, params.lod_exit_radius_m, max_s0)
	var configured: Result = module.lod.configure(params)
	# O módulo ainda não liga o destino dos locais (LW-061/LW-067); quem monta o módulo pode ligar (contrato, seção 6).
	module.lod.place_position_cm = _place_cm
	runner = SimulationRunner.new(Sp2Constants.WORLD_SEED)
	var registered: Result = runner.register_module(GameModules.NPC_NAME, module)
	runner.world.context.events.subscribe("LodChanged", _on_lod_changed)
	runner.start_new_game()
	actions = module.create_action_runner(catalog.actions, places, null)
	var linked: Result = module.configure_intents(actions, places, intent_loaded.params)
	for check: Result in [configured, registered, linked]:
		if not check.ok:
			problem = check.message
			return
	director = Sp2Director.new(self)
	problem = director.populate(loaded_places.places, all_in_a)


func now() -> int:
	return runner.world.context.clock.total_minutes()


func lod_params_text() -> String:
	var summary: Dictionary = module.lod.debug_summary()
	return "focos %d, S0 %d" % [summary["focus_count"], summary["s0_count"]]


## Copia a pausa e a velocidade do relógio do jogo e avança este mundo pelo tempo do quadro; o diretor age a cada minuto.
func advance(delta_ms: int, is_paused: bool, speed: int) -> int:
	var clock: SimClock = runner.world.context.clock
	clock.set_paused(is_paused)
	if speed >= SimClock.MIN_SPEED and speed <= SimClock.MAX_SPEED:
		clock.set_speed(speed)
	var steps: int = mini(clock.steps_for_frame(delta_ms), SimulationRunner.MAX_TICKS_PER_FRAME)
	for _step: int in steps:
		runner.step_once()
		director.on_minute(now())
	return steps


## Trocas de LOD desde a última chamada, em ordem de chegada.
func take_changes() -> Array[LodChanged]:
	var taken: Array[LodChanged] = _changes
	_changes = []
	return taken


## Posição lógica no instante em que o NPC saiu de S0 (NO_POSITION se removido ou desconhecido).
func exit_position_of(npc_id: int) -> Vector2i:
	return _exit_positions.get(npc_id, LodReconstruction.NO_POSITION)


func lod_changes_of(npc_id: int) -> int:
	return _lod_changes_by_npc.get(npc_id, 0)


func reset_lod_change_counts() -> void:
	_lod_changes_by_npc.clear()


func max_lod_changes_per_npc() -> int:
	var best: int = 0
	for count: int in _lod_changes_by_npc.values():
		best = maxi(best, count)
	return best


func intent_counters() -> Dictionary:
	return module.intents.debug_summary()


## Solta o diretor (ele aponta de volta para este mundo) e encerra o runner.
func finish() -> void:
	director = null
	runner.finish()


func _on_lod_changed(event: SimEvent) -> void:
	var change: LodChanged = event as LodChanged
	_changes.append(change)
	_lod_changes_by_npc[change.npc_id] = lod_changes_of(change.npc_id) + 1
	if change.to_level == NpcLod.LEVEL_S1:
		var query: NpcModule.NpcQuery = module.peek_npc(change.npc_id)
		_exit_positions[change.npc_id] = Vector2i(query.x_cm, query.z_cm) if query.result.ok else LodReconstruction.NO_POSITION


func _place_cm(place_id: String) -> Vector2i:
	var found: SettlementService.PlaceQuery = places.peek_place(place_id)
	if not found.result.ok:
		return LodReconstruction.NO_POSITION
	return Vector2i(roundi(found.place.position.x * TerrainData.CM_PER_METER), roundi(found.place.position.z * TerrainData.CM_PER_METER))
