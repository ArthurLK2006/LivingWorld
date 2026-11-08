extends GutTest
## LW-070b: o interruptor de corpos do `npc` (docs/modules/npc.md, seção 6), sem janela e com o jogo montado como o real: os dados reais de
## res://data (NpcSetup.from_dir), os 100 NPCs da população inicial (60 no assentamento A e 40 no B), o mundo do SimulationRunner e o relógio de
## verdade (1 passo = 1 minuto). O "corpo" é o próprio teste. No jogo real ninguém responde aos Intents (a apresentação só chega na LW-072), então
## o jogo NASCE sem corpos: o LOD fica inerte e o mundo não muda porque o jogador olhou. Só a apresentação (aqui, o teste) liga os corpos.

const DATA_DIR: String = "res://data"
const WORLD_SEED: int = 11
const ACTOR_ID: int = 77
const OTHER_ACTOR_ID: int = 78
const FOCUS_A_M: Vector3 = Vector3(320.0, 10.0, 540.0)
const FOCUS_A_CM: Vector2i = Vector2i(32000, 54000)
const FOCUS_FAR_M: Vector3 = Vector3(520.0, 10.0, 900.0)
const MAX_S0: int = 50
const FIRST_THINKS_DONE: int = 12
## Às 6h a rotina troca o sono por `eat` (20 min); 6h12 = todos já trocaram e os que estão em S0 têm o Intent de `eat`.
const AFTER_THE_ROUTINE_SWAP: int = 6 * 60 + 12
const DAY: int = SimClock.MINUTES_PER_DAY
const CM_PER_M: float = 100.0
const HUNGER: int = 0
const GAME_VERSION: String = "0.0.1-test"

var _data: NpcLifeCheck.GameData
var _rigs: Array[Rig] = []
var _codec: JsonSaveCodec = JsonSaveCodec.new()


## Um jogo de teste: o runner, o módulo `npc` e os LodChanged que chegaram.
class Rig:
	extends RefCounted

	var runner: SimulationRunner
	var npc: NpcModule
	var changes: Array[LodChanged] = []

	func on_lod_changed(event: SimEvent) -> void:
		changes.append(event as LodChanged)

	func now() -> int:
		return runner.world.context.clock.total_minutes()


func before_all() -> void:
	_data = NpcLifeCheck.load_game_data()
	assert_eq(_data.problem, "", "Os dados reais do jogo carregam.")


func after_each() -> void:
	for rig: Rig in _rigs:
		rig.runner.finish()
	_rigs.clear()


# ---------------------------------------------------------------------------------------------------- montagem

## Jogo novo igual ao real (nasce SEM corpos). `started` falso deixa o mundo pronto para carregar um save.
func _rig(started: bool = true) -> Rig:
	var setup: NpcSetup = NpcSetup.from_dir(DATA_DIR, SettlementService.new(_data.settlements, _data.places))
	assert_true(setup.result.ok, setup.result.message)
	var rig: Rig = Rig.new()
	rig.runner = SimulationRunner.new(WORLD_SEED)
	var modules: GameModules = GameModules.register(rig.runner, _data.terrain, _data.points, setup)
	assert_true(modules.result.ok, modules.result.message)
	rig.npc = modules.npc
	rig.runner.world.context.events.subscribe("LodChanged", rig.on_lod_changed)
	if started:
		rig.runner.start_new_game()
	_rigs.append(rig)
	return rig


## Jogo com os corpos ligados e o foco do ator no centro do assentamento A.
func _rig_with_bodies() -> Rig:
	var rig: Rig = _rig()
	assert_true(rig.npc.request_set_bodies_available(true).ok)
	assert_true(rig.npc.request_set_focus(ACTOR_ID, FOCUS_A_M).ok)
	return rig


func _body_of(intent: NpcIntent) -> Vector3:
	return Vector3(intent.destination_cm.x / CM_PER_M, 0.0, intent.destination_cm.y / CM_PER_M)


func _result_for(intent: NpcIntent, outcome: NpcActionResult.Outcome) -> NpcActionResult:
	return NpcActionResult.new(intent.npc_id, intent.action_serial, outcome, _body_of(intent))


## O NPC com Intent pendente mais perto do foco (o último a perder a vaga de S0; ver tests/integration/test_npc_s0_flow.gd).
func _closest_pending(rig: Rig) -> NpcIntent:
	var closest: NpcIntent = null
	var closest_sq: int = 0
	for intent: NpcIntent in rig.npc.peek_pending_intents():
		var npc: NpcModule.NpcQuery = rig.npc.peek_npc(intent.npc_id)
		var delta_x: int = npc.x_cm - FOCUS_A_CM.x
		var delta_z: int = npc.z_cm - FOCUS_A_CM.y
		var distance_sq: int = delta_x * delta_x + delta_z * delta_z
		if closest == null or distance_sq < closest_sq:
			closest = intent
			closest_sq = distance_sq
	assert_not_null(closest, "Esperava ao menos um Intent pendente.")
	return closest


func _discarded(rig: Rig) -> int:
	return rig.npc.intents.debug_summary()["discarded_results"]


# ---------------------------------------------------------------------------------------------------- o padrão

func test_the_game_is_born_without_bodies_while_a_module_built_by_hand_keeps_its_bodies() -> void:
	var game: Rig = _rig()
	assert_eq(game.npc.debug_summary()["bodies_available"], false, "O módulo do jogo (com as `Definitions` e o LOD dos dados) nasce sem corpos.")
	var bare: NpcModule = NpcModule.new()
	assert_eq(bare.debug_summary()["bodies_available"], true, "Um módulo montado à mão, sem `Definitions` (banco de ensaio do LOD), segue como antes: com corpos.")


# ---------------------------------------------------------------------------------------------------- (a) sem corpos o jogador não muda o mundo

func test_without_bodies_the_player_never_changes_the_world_whatever_the_focus_does() -> void:
	var watched: Rig = _rig()
	var unwatched: Rig = _rig()
	assert_true(watched.npc.request_set_focus(ACTOR_ID, FOCUS_A_M).ok, "O foco é aceito como sempre: quem relata a posição não precisa saber do interruptor.")
	assert_true(watched.npc.request_set_focus(OTHER_ACTOR_ID, FOCUS_FAR_M).ok, "E vários atores valem.")
	for hour: int in 24:
		# O jogador passeia: o foco principal muda de lugar a cada hora, sempre por cima dos NPCs.
		assert_true(watched.npc.request_set_focus(ACTOR_ID, FOCUS_A_M if hour % 2 == 0 else FOCUS_FAR_M).ok)
		watched.runner.run_steps(60)
	unwatched.runner.run_days(1)
	assert_eq(watched.now(), unwatched.now(), "Os dois mundos andaram o mesmo dia.")
	assert_eq(watched.npc.lod.s0_ids().size(), 0, "Ninguém ganhou corpo, por mais perto que o foco passasse.")
	assert_eq(watched.changes.size(), 0, "Nenhum LodChanged saiu (nem gastou ID de evento).")
	assert_eq(watched.npc.peek_pending_intents().size(), 0, "Nenhuma ação nasceu com Intent.")
	assert_eq(watched.runner.world.state_hash(), unwatched.runner.world.state_hash(), "O hash depois de 1 dia é IGUAL ao do mundo sem foco nenhum: o jogador olhar não muda o mundo.")
	assert_eq(watched.npc.validate().size(), 0, str(watched.npc.validate()))


func test_the_same_player_does_change_the_world_when_the_bodies_are_on() -> void:
	# Controle negativo do teste acima: se o interruptor não valesse, os dois testes passariam por acaso.
	var with_bodies: Rig = _rig_with_bodies()
	var without_focus: Rig = _rig()
	with_bodies.runner.run_steps(AFTER_THE_ROUTINE_SWAP)
	without_focus.runner.run_steps(AFTER_THE_ROUTINE_SWAP)
	assert_gt(with_bodies.npc.lod.s0_ids().size(), 0, "Com os corpos ligados o foco perto faz NPCs ganharem corpo.")
	assert_gt(with_bodies.npc.peek_pending_intents().size(), 0)
	assert_ne(with_bodies.runner.world.state_hash(), without_focus.runner.world.state_hash(), "E o mundo muda: é para isso que o interruptor existe.")


# ---------------------------------------------------------------------------------------------------- (b) ligar depois traz a LW-070a de volta

func test_turning_the_bodies_on_later_brings_the_s0_behaviour_back() -> void:
	var rig: Rig = _rig()
	assert_true(rig.npc.request_set_focus(ACTOR_ID, FOCUS_A_M).ok)
	rig.runner.run_steps(FIRST_THINKS_DONE)
	assert_eq(rig.npc.lod.s0_ids().size(), 0, "Antes de ligar, ninguém tem corpo.")
	assert_true(rig.npc.request_set_bodies_available(true).ok)
	rig.runner.step_once()
	assert_eq(rig.npc.lod.s0_ids().size(), MAX_S0, "Dos 60 do assentamento A, 50 ganham corpo (o foco já estava guardado).")
	assert_eq(rig.changes.size(), MAX_S0, "Um LodChanged por NPC que ganhou corpo.")
	assert_eq(rig.npc.peek_pending_intents().size(), 0, "A ação em curso (o sono abstrato) não ganha Intent; a PRÓXIMA ganha.")
	rig.runner.run_steps(AFTER_THE_ROUTINE_SWAP - rig.now())
	var intents: Array[NpcIntent] = rig.npc.peek_pending_intents()
	assert_gt(intents.size(), 0, "Depois da troca da rotina as ações novas nascem com Intent.")
	for intent: NpcIntent in intents:
		assert_eq(rig.npc.lod.level_of(intent.npc_id), NpcLod.LEVEL_S0, "Só quem tem corpo emite Intent.")
		assert_eq(intent.kind, NpcIntent.Kind.ACT_AT_PLACE)
	assert_eq(rig.npc.validate().size(), 0, str(rig.npc.validate()))


# ---------------------------------------------------------------------------------------------------- (c) desligar solta tudo

func test_turning_the_bodies_off_releases_every_intent_and_each_action_goes_on_abstractly() -> void:
	var rig: Rig = _rig_with_bodies()
	rig.runner.run_steps(AFTER_THE_ROUTINE_SWAP)
	var released: NpcIntent = _closest_pending(rig)
	var before: NpcModule.NpcQuery = rig.npc.peek_npc(released.npc_id)
	var waiting: int = rig.npc.peek_pending_intents().size()
	var s0_before: int = rig.npc.lod.s0_ids().size()
	assert_gt(waiting, 0, "Sanidade: havia Intents pendentes.")
	assert_true(rig.npc.request_set_bodies_available(false).ok)
	assert_eq(rig.npc.peek_pending_intents().size(), 0, "Os Intents foram soltos de uma vez.")
	assert_eq(rig.npc.lod.s0_ids().size(), 0, "E todos voltaram a S1.")
	var changes_before: int = rig.changes.size()
	rig.runner.step_once()
	assert_eq(rig.changes.size() - changes_before, s0_before, "Um LodChanged (S0 para S1) por NPC que tinha corpo.")
	assert_eq(rig.npc.debug_summary()["bodies_available"], false)
	var left: NpcModule.NpcQuery = rig.npc.peek_npc(released.npc_id)
	assert_eq([left.action_id, left.action_serial, left.action_ends_at], [before.action_id, before.action_serial, before.action_ends_at], "A ação segue, com o tempo que falta.")
	# O corpo antigo ainda responde: o resultado chega com o contador da ação liberada e é descartado.
	var discarded_before: int = _discarded(rig)
	var snapshot: NpcModule.NpcQuery = rig.npc.peek_npc(released.npc_id)
	var late: Result = rig.npc.request_report_npc_result(_result_for(released, NpcActionResult.Outcome.DONE))
	assert_eq(late.code, NpcIntentBoard.CODE_STALE_RESULT, "Resultado do corpo liberado é descartado: o efeito não entra duas vezes.")
	assert_eq(_discarded(rig), discarded_before + 1, "E contado.")
	var unchanged: NpcModule.NpcQuery = rig.npc.peek_npc(released.npc_id)
	assert_eq([unchanged.need_values, unchanged.action_id, unchanged.action_serial, unchanged.next_think_time], [snapshot.need_values, snapshot.action_id, snapshot.action_serial, snapshot.next_think_time], "O NPC não mudou.")
	# O modo abstrato termina a ação no fim previsto, uma vez só, e o NPC segue a vida.
	rig.runner.run_steps(before.action_ends_at + 2 - rig.now())
	var finished: NpcModule.NpcQuery = rig.npc.peek_npc(released.npc_id)
	assert_gt(finished.action_serial, before.action_serial, "O pensador abstrato terminou a ação e o NPC começou a próxima.")
	assert_eq(finished.need_values[HUNGER], 0, "`eat` aliviou a fome (60 de ~50): o efeito entrou, e entrou pelo caminho abstrato.")
	assert_eq(rig.npc.peek_pending_intents().size(), 0, "Com os corpos desligados nenhuma ação nova nasce com Intent.")
	assert_eq(rig.npc.validate().size(), 0, str(rig.npc.validate()))


# ---------------------------------------------------------------------------------------------------- erros e limites

func test_the_switch_is_refused_before_setup_and_repeating_the_state_does_nothing() -> void:
	var unregistered: NpcModule = NpcModule.new()
	var refused: Result = unregistered.request_set_bodies_available(false)
	assert_eq(refused.code, NpcModule.CODE_NOT_READY, "Módulo fora de um mundo não tem relógio nem barramento: falha tratada.")
	assert_eq(unregistered.debug_summary()["bodies_available"], true, "E nada mudou.")
	var rig: Rig = _rig()
	assert_true(rig.npc.request_set_bodies_available(false).ok, "Repetir o estado atual (desligado) é sucesso sem efeito.")
	assert_true(rig.npc.request_set_focus(ACTOR_ID, FOCUS_A_M).ok)
	assert_true(rig.npc.request_set_bodies_available(true).ok)
	assert_true(rig.npc.request_set_bodies_available(true).ok, "Ligar duas vezes é o mesmo que ligar uma.")
	rig.runner.step_once()
	assert_eq(rig.changes.size(), MAX_S0, "Um só conjunto de LodChanged: nada saiu em dobro.")
	assert_true(rig.npc.request_set_bodies_available(false).ok)
	assert_true(rig.npc.request_set_bodies_available(false).ok, "Desligar duas vezes é o mesmo que desligar uma.")
	rig.runner.step_once()
	assert_eq(rig.changes.size(), MAX_S0 * 2, "E a saída também sai uma vez só por NPC.")


func test_the_switch_is_neither_saved_nor_part_of_the_hash_and_a_loaded_world_starts_without_bodies() -> void:
	var on: Rig = _rig()
	var off: Rig = _rig()
	assert_true(on.npc.request_set_bodies_available(true).ok)
	on.runner.run_steps(30)
	off.runner.run_steps(30)
	assert_eq(on.runner.world.state_hash(), off.runner.world.state_hash(), "Sem foco, ligar os corpos não muda o hash: o interruptor não é estado do mundo.")
	assert_eq(JSON.stringify(on.npc.serialize()), JSON.stringify(off.npc.serialize()), "E não entra no que o módulo salva.")
	var decoded: DecodedSave = _codec.decode(_codec.encode(on.runner.capture_game(), GAME_VERSION))
	assert_true(decoded.result.ok, decoded.result.message)
	var loaded: Rig = _rig(false)
	var result: Result = loaded.runner.load_game(decoded.payload)
	assert_true(result.ok, result.message)
	assert_eq(loaded.runner.world.state_hash(), on.runner.world.state_hash(), "O mundo carregado tem o mesmo hash.")
	assert_eq(loaded.npc.debug_summary()["bodies_available"], false, "Mas o mundo carregado nasce SEM corpos, mesmo que o salvo estivesse com eles: quem os religa é a apresentação.")
