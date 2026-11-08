extends GutTest
## LW-069: o LOD dentro do NpcModule, sem janela: os pedidos de foco, o `tick` e o evento LodChanged pelo barramento, com o mundo montado
## pelo SimulationRunner (relógio, agendador e entrega de eventos de verdade). Valores ESCRITOS À MÃO: parâmetros reais de data/lod_params.json
## (80 m, 120 m, 50); níveis do evento 0 = S0 e 1 = S1. O nível não é salvo e não entra no hash.

const WORLD_SEED: int = 3
const GAME_VERSION: String = "0.0.1-test"
const ACTOR_ID: int = 77
const OTHER_ACTOR_ID: int = 78
const FOCUS_M: Vector3 = Vector3(1000.0, 10.0, 500.0)
const FOCUS_Z_M: float = 500.0
const EVENT_TYPE: String = "LodChanged"
const NPC_COUNT_ABOVE_THE_LIMIT: int = 60
const S0: int = NpcLod.LEVEL_S0
const S1: int = NpcLod.LEVEL_S1

var _games: Array[Game] = []
var _codec: JsonSaveCodec = JsonSaveCodec.new()


## Um mundo de teste: o runner, o módulo e os eventos LodChanged que chegaram.
class Game:
	extends RefCounted

	var runner: SimulationRunner
	var module: NpcModule
	var events: Array[LodChanged] = []

	func on_lod_changed(event: SimEvent) -> void:
		events.append(event as LodChanged)

	func text() -> String:
		var parts: PackedStringArray = PackedStringArray()
		for event: LodChanged in events:
			parts.append("%d:%d>%d" % [event.npc_id, event.from_level, event.to_level])
		return ",".join(parts)


func after_each() -> void:
	for game: Game in _games:
		game.runner.finish()
	_games.clear()


## Mundo com o módulo `npc` registrado; `configured` liga o LOD com os parâmetros reais; `started` inicia o jogo (senão serve para carregar um save).
func _new_game(configured: bool = true, started: bool = true) -> Game:
	var game: Game = Game.new()
	game.runner = SimulationRunner.new(WORLD_SEED)
	game.module = NpcModule.new()
	if configured:
		var loaded: LodParamsLoader.LoadResult = LodParamsLoader.load_dir()
		assert_true(loaded.result.ok, loaded.result.message)
		assert_true(game.module.lod.configure(loaded.params).ok)
	assert_true(game.runner.register_module("npc", game.module).ok)
	game.runner.world.context.events.subscribe(EVENT_TYPE, game.on_lod_changed)
	if started:
		game.runner.start_new_game()
	_games.append(game)
	return game


func _create(game: Game, x_m: float, z_m: float) -> int:
	var spec: NpcSpec = NpcSpec.new()
	spec.name_key = "npc.name.villager"
	spec.x_cm = roundi(x_m * 100.0)
	spec.z_cm = roundi(z_m * 100.0)
	var created: NpcModule.CreateResult = game.module.request_create_npc(spec)
	assert_true(created.result.ok, created.result.message)
	return created.npc_id


func test_a_module_without_lod_params_refuses_the_focus_and_never_emits() -> void:
	var game: Game = _new_game(false)
	var npc_id: int = _create(game, 1000.0, FOCUS_Z_M)
	var refused: Result = game.module.request_set_focus(ACTOR_ID, FOCUS_M)
	assert_false(refused.ok)
	assert_eq(refused.code, NpcLod.CODE_NOT_CONFIGURED)
	assert_eq(game.module.request_clear_focus(ACTOR_ID).code, NpcLod.CODE_NOT_CONFIGURED)
	game.runner.run_steps(5)
	assert_eq(game.events.size(), 0, "Sem parâmetros o LOD não existe: nenhum evento e o NPC fica em S1.")
	assert_eq(game.module.lod.level_of(npc_id), S1)


func test_the_focus_makes_a_close_npc_s0_and_the_event_carries_the_ids_the_levels_and_the_stamps() -> void:
	var game: Game = _new_game()
	var near_id: int = _create(game, 1050.0, FOCUS_Z_M)
	var far_id: int = _create(game, 1300.0, FOCUS_Z_M)
	assert_true(game.module.request_set_focus(ACTOR_ID, FOCUS_M).ok)
	assert_eq(game.events.size(), 0, "Pedir o foco só enfileira nada: quem reclassifica é o passo.")
	game.runner.step_once()
	assert_eq(game.events.size(), 1, "Só o NPC a 50 m trocou de nível.")
	var event: LodChanged = game.events[0]
	assert_eq([event.npc_id, event.from_level, event.to_level], [near_id, S1, S0])
	assert_eq(event.type, EVENT_TYPE)
	assert_gt(event.id, 0, "O barramento carimbou o ID.")
	assert_eq(event.time, game.runner.world.context.clock.total_minutes(), "E a hora do passo.")
	assert_eq(event.cause_id, SimEvent.NO_CAUSE, "Ninguém provocou o evento: sem causa.")
	assert_eq(event.severity, 0)
	assert_eq(game.module.lod.level_of(near_id), S0)
	assert_eq(game.module.lod.level_of(far_id), S1)


func test_events_come_only_on_the_change_and_not_on_every_step() -> void:
	var game: Game = _new_game()
	_create(game, 1050.0, FOCUS_Z_M)
	_create(game, 1300.0, FOCUS_Z_M)
	assert_true(game.module.request_set_focus(ACTOR_ID, FOCUS_M).ok)
	game.runner.run_steps(30)
	assert_eq(game.events.size(), 1, "Trinta passos com tudo parado: um só evento, o da entrada.")


func test_a_focus_hovering_around_the_border_does_not_make_the_npc_oscillate() -> void:
	var game: Game = _new_game()
	var npc_id: int = _create(game, 1080.0, FOCUS_Z_M)
	assert_true(game.module.request_set_focus(ACTOR_ID, Vector3(1000.0, 10.0, FOCUS_Z_M)).ok)
	game.runner.step_once()
	for step: int in 20:
		assert_true(game.module.request_set_focus(ACTOR_ID, Vector3(999.0 if step % 2 == 0 else 1000.0, 10.0, FOCUS_Z_M)).ok)
		game.runner.step_once()
	assert_eq(game.events.size(), 1, "80 m entra; ir e vir entre 80 m e 81 m não gera mais troca.")
	assert_true(game.module.request_set_focus(ACTOR_ID, Vector3(880.0, 10.0, FOCUS_Z_M)).ok)
	game.runner.step_once()
	assert_true(game.module.request_set_focus(ACTOR_ID, Vector3(1000.0, 10.0, FOCUS_Z_M)).ok)
	game.runner.step_once()
	assert_eq(game.text(), "%d:1>0,%d:0>1,%d:1>0" % [npc_id, npc_id, npc_id], "A 200 m sai; de volta a 80 m entra de novo: três trocas no total.")


func test_the_module_respects_the_limit_of_the_real_params_with_sixty_npcs() -> void:
	var game: Game = _new_game()
	var ids_by_distance: Dictionary[int, int] = {}
	for index: int in NPC_COUNT_ABOVE_THE_LIMIT:
		var distance_m: int = (index * 7) % NPC_COUNT_ABOVE_THE_LIMIT + 1
		ids_by_distance[distance_m] = _create(game, 1000.0 + float(distance_m), FOCUS_Z_M)
	assert_true(game.module.request_set_focus(ACTOR_ID, FOCUS_M).ok)
	game.runner.step_once()
	assert_eq(game.events.size(), 50, "Sessenta a menos de 80 m, cinquenta vagas.")
	var expected: Array[int] = []
	for distance_m: int in range(1, 51):
		expected.append(ids_by_distance[distance_m])
	expected.sort()
	assert_eq(game.module.lod.s0_ids(), expected, "Os cinquenta mais próximos (1 m a 50 m).")
	for event: LodChanged in game.events:
		assert_eq([event.from_level, event.to_level], [S1, S0])


func test_removing_an_s0_npc_publishes_the_exit_and_frees_the_slot() -> void:
	var game: Game = _new_game()
	var npc_id: int = _create(game, 1050.0, FOCUS_Z_M)
	assert_true(game.module.request_set_focus(ACTOR_ID, FOCUS_M).ok)
	game.runner.step_once()
	assert_true(game.module.request_remove_npc(npc_id).ok)
	game.runner.step_once()
	assert_eq(game.text(), "%d:1>0,%d:0>1" % [npc_id, npc_id])
	assert_eq(game.module.lod.s0_ids().size(), 0)


func test_clearing_the_focus_sends_everyone_back_to_s1_with_one_event_each_and_several_actors_work() -> void:
	var game: Game = _new_game()
	var first_id: int = _create(game, 1050.0, FOCUS_Z_M)
	var second_id: int = _create(game, 3040.0, FOCUS_Z_M)
	assert_true(game.module.request_set_focus(ACTOR_ID, FOCUS_M).ok)
	assert_true(game.module.request_set_focus(OTHER_ACTOR_ID, Vector3(3000.0, 10.0, FOCUS_Z_M)).ok)
	game.runner.step_once()
	assert_eq(game.text(), "%d:1>0,%d:1>0" % [first_id, second_id], "Cada ator é um foco: nada supõe um jogador só.")
	assert_true(game.module.request_clear_focus(ACTOR_ID).ok)
	game.runner.step_once()
	assert_eq(game.module.lod.level_of(first_id), S1, "Sem o primeiro foco só o primeiro NPC volta.")
	assert_eq(game.module.lod.level_of(second_id), S0)
	assert_true(game.module.request_clear_focus(OTHER_ACTOR_ID).ok)
	game.runner.step_once()
	assert_eq(game.text(), "%d:1>0,%d:1>0,%d:0>1,%d:0>1" % [first_id, second_id, first_id, second_id])
	assert_eq(game.module.request_clear_focus(OTHER_ACTOR_ID).code, NpcLod.CODE_UNKNOWN_FOCUS)


func test_the_level_is_outside_the_save_and_the_hash_and_a_loaded_world_starts_in_s1() -> void:
	var quiet: Game = _new_game()
	var busy: Game = _new_game()
	for game: Game in [quiet, busy]:
		_create(game, 1050.0, FOCUS_Z_M)
		_create(game, 1300.0, FOCUS_Z_M)
	assert_true(busy.module.request_set_focus(ACTOR_ID, FOCUS_M).ok)
	quiet.runner.run_steps(10)
	busy.runner.run_steps(10)
	assert_eq(busy.module.lod.s0_ids().size(), 1, "Um NPC em S0 no mundo com foco.")
	assert_eq(JSON.stringify(busy.module.serialize()), JSON.stringify(quiet.module.serialize()), "O que o módulo salva é o mesmo com e sem S0: o nível não é salvo.")
	var busy_state: Dictionary = busy.runner.world.serialize()
	var quiet_state: Dictionary = quiet.runner.world.serialize()
	assert_eq(JSON.stringify(busy_state[World.KEY_MODULES]), JSON.stringify(quiet_state[World.KEY_MODULES]), "Nenhum módulo muda por causa do nível.")
	for key: String in [World.KEY_CLOCK, World.KEY_RNG, World.KEY_IDS]:
		assert_eq(JSON.stringify(busy_state[World.KEY_CORE][key]), JSON.stringify(quiet_state[World.KEY_CORE][key]), "Núcleo igual: %s." % key)
	assert_ne(busy.runner.world.state_hash(), quiet.runner.world.state_hash(), "O hash difere só porque o LodChanged publicado gastou um ID de evento (contador do core, já salvo).")
	assert_ne(JSON.stringify(busy_state[World.KEY_CORE][World.KEY_EVENTS]), JSON.stringify(quiet_state[World.KEY_CORE][World.KEY_EVENTS]), "É a única parte que difere.")
	var decoded: DecodedSave = _codec.decode(_codec.encode(busy.runner.capture_game(), GAME_VERSION))
	assert_true(decoded.result.ok, decoded.result.message)
	var loaded: Game = _new_game(true, false)
	var result: Result = loaded.runner.load_game(decoded.payload)
	assert_true(result.ok, result.message)
	assert_eq(loaded.runner.world.state_hash(), busy.runner.world.state_hash(), "O mundo carregado tem o mesmo hash.")
	assert_eq(loaded.module.lod.s0_ids().size(), 0, "Ao carregar, todos nascem em S1.")
	loaded.runner.run_steps(5)
	assert_eq(loaded.events.size(), 0, "E sem foco nada muda.")
	assert_true(loaded.module.request_set_focus(ACTOR_ID, FOCUS_M).ok)
	loaded.runner.step_once()
	assert_eq(loaded.events.size(), 1, "Com o foco de volta, o NPC perto volta a S0.")


func test_the_same_scenario_gives_the_same_events_and_the_world_stays_valid() -> void:
	var runs: Array[String] = []
	for run: int in 2:
		var game: Game = _new_game()
		for index: int in 12:
			_create(game, 1000.0 + float((index * 5) % 12) * 10.0, FOCUS_Z_M)
		assert_true(game.module.request_set_focus(ACTOR_ID, FOCUS_M).ok)
		for step: int in 6:
			assert_true(game.module.request_set_focus(ACTOR_ID, Vector3(1000.0 - float(step) * 30.0, 10.0, FOCUS_Z_M)).ok)
			game.runner.step_once()
		runs.append(game.text())
		assert_eq(game.runner.world.validate().size(), 0, "Execução %d: o mundo segue válido com o LOD ativo." % run)
	assert_ne(runs[0], "", "O cenário gerou eventos.")
	assert_eq(runs[0], runs[1], "Mesma entrada, mesma sequência de eventos.")
