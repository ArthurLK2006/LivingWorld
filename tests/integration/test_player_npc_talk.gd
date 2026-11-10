extends GutTest
## LW-083f: a conversa do jogador com um NPC de ponta a ponta, sem janela e com o jogo real de res://data às 07:00 (host, ponte, terreno, 100 NPCs). O jogador nasce,
## anda até o povoado A e conversa pela ponte com um lavrador que trabalha: ele vira T2, a relação e a memória existem e ele para. Salva e carrega como na LW-052 (capture_game,
## codec JSON, runner novo): no MEIO da conversa (o que acontece está nos asserts) e depois dela, com opinião, memória, hash e validate() iguais; num mundo carregado o cooldown
## vale e, passado ele, a 2ª conversa traz a chave `known`. Sem corpos de verdade: o teste faz o papel do corpo (relata `DONE` da conversa). Valores escritos à mão a partir do envio.

const DATA_DIR: String = "res://data"
const WORLD_SEED: int = 5
const START_MIN: int = 7 * SimClock.MINUTES_PER_HOUR
const A_M: Vector3 = Vector3(320.0, 10.0, 540.0)
const WALK_MIN: int = 60
const WARMUP_MIN: int = 30
const CLOSE_M: float = 1.5
const TALK_MIN: int = 6
const COOLDOWN: int = NpcPlayerTalk.TALK_COOLDOWN_MIN
const AFTER_TALK_MIN: int = 4
const GAME_VERSION: String = "0.0.1-test"
const WORK: String = "work"
const TALK: String = "talk_player"
const GAIN: int = 3
const AFFECTION: int = NpcRelation.DIM_AFFECTION
const TRUST: int = NpcRelation.DIM_TRUST

var _data: NpcLifeCheck.GameData
var _codec: JsonSaveCodec = JsonSaveCodec.new()
var _host: SimulationHostNode
var _bridge: SimBridge
var _actor_id: int = 0
var _npc_id: int = 0


func before_all() -> void:
	_data = NpcLifeCheck.load_game_data()
	assert_eq(_data.problem, "", "Os dados reais do jogo carregam.")


func after_each() -> void:
	if _host != null:
		_host.runner.finish()
		_host.free()
	_host = null


func _setup() -> NpcSetup:
	var setup: NpcSetup = NpcSetup.from_dir(DATA_DIR, SettlementService.new(_data.settlements, _data.places))
	assert_true(setup.result.ok, setup.result.message)
	return setup


## O jogo às 07:00, o ator nascido pela ponte, os corpos ligados, a caminhada até o povoado A e meia hora lá até haver NPCs em S0.
func _arrive_at_the_settlement() -> void:
	_host = SimulationHostNode.new()
	_host.start_new_game(WORLD_SEED, _data.terrain, _data.points, _setup(), START_MIN)
	_bridge = SimBridge.new(_host, _data.terrain, _data.places, _host.npc)
	_actor_id = _bridge.request_spawn_character().actor_id
	assert_true(_bridge.request_set_bodies_available(true).ok)
	var from: Vector3 = _data.terrain.peek_spawn_point()
	for minute: int in WALK_MIN:
		assert_true(_bridge.request_report_position(_actor_id, from.lerp(A_M, float(minute + 1) / float(WALK_MIN)), 0.0).ok)
		_host.runner.step_once()
	_step_host(WARMUP_MIN)


func _step_host(minutes: int) -> void:
	for _minute: int in minutes:
		_host.runner.step_once()


func _now() -> int:
	return _host.runner.world.context.clock.total_minutes()


## O jogador a 1,5 m do corpo do NPC (o relato vai pela ponte, que guarda no personagem).
func _stand_next_to(npc_id: int) -> void:
	var body_cm: Vector2i = _host.npc.lod.position_of(npc_id)
	var spot: Vector3 = Vector3(float(body_cm.x) / NpcLod.CM_PER_METER_FLOAT + CLOSE_M, A_M.y, float(body_cm.y) / NpcLod.CM_PER_METER_FLOAT)
	assert_true(_bridge.request_report_position(_actor_id, spot, 0.0).ok)


## O corpo (o teste) relata o fim da conversa: a Intent pendente do NPC é cumprida no destino.
func _finish_the_talk_as_the_body() -> void:
	for intent: BridgeReplies.NpcIntentReply in _bridge.peek_pending_npc_intents().intents:
		if intent.npc_id == _npc_id:
			assert_true(_bridge.request_report_npc_result(_npc_id, intent.action_serial, BridgeReplies.NpcOutcome.DONE, intent.destination).ok)


## Salva como a LW-052 e carrega num runner NOVO com os mesmos módulos; devolve os módulos do mundo carregado (o runner fica em `modules`'s dono).
class Reloaded:
	extends RefCounted

	var runner: SimulationRunner
	var modules: GameModules


func _save_and_reload() -> Reloaded:
	assert_true(_host.runner.can_capture_game(), "Entre passos a fila de eventos está vazia.")
	var decoded: DecodedSave = _codec.decode(_codec.encode(_host.runner.capture_game(), GAME_VERSION))
	assert_true(decoded.result.ok, decoded.result.message)
	var reloaded: Reloaded = Reloaded.new()
	reloaded.runner = SimulationRunner.new(WORLD_SEED)
	reloaded.modules = GameModules.register(reloaded.runner, _data.terrain, _data.points, _setup())
	assert_true(reloaded.modules.result.ok, reloaded.modules.result.message)
	var loaded: Result = reloaded.runner.load_game(decoded.payload)
	assert_true(loaded.ok, loaded.message)
	return reloaded


func _relation(npc: NpcModule) -> Array[int]:
	var opinion: NpcModule.OpinionQuery = npc.peek_opinion(_actor_id, _npc_id)
	var shown: Array[int] = []
	if opinion.is_known:
		shown.assign([opinion.values[AFFECTION], opinion.values[TRUST]])
	return shown


func _memory_times(npc: NpcModule) -> Array[int]:
	var times: Array[int] = []
	for record: MemoryRecord in npc.peek_memories(_npc_id).records:
		times.append(record.time)
	return times


func test_the_player_walks_to_the_settlement_talks_saves_in_the_middle_and_after_and_talks_again() -> void:
	_arrive_at_the_settlement()
	for candidate: int in _host.npc.lod.s0_ids():
		if _npc_id == 0 and _host.npc.peek_npc(candidate).action_id == WORK:
			_npc_id = candidate
	assert_ne(_npc_id, 0, "Junto de A há um lavrador com corpo trabalhando.")
	assert_eq([_host.npc.peek_npc(_npc_id).tier, _relation(_host.npc)], [NpcState.TIER_NORMAL, []], "Antes: cidadão e desconhecido.")
	# 1. A 1ª conversa pela ponte.
	_stand_next_to(_npc_id)
	var started_at: int = _now()
	var first: BridgeReplies.ConverseReply = _bridge.request_converse(_actor_id, _npc_id)
	assert_true(first.result.ok, first.result.message)
	assert_eq([first.text_key, first.was_promoted], [NpcPlayerTalk.TEXT_KEY_FIRST, true], "Primeira conversa: first, e o NPC virou T2.")
	var talking: NpcModule.NpcQuery = _host.npc.peek_npc(_npc_id)
	assert_eq([talking.tier, talking.action_id, talking.action_ends_at], [NpcState.TIER_NOTABLE, TALK, started_at + TALK_MIN], "Ele virou T2 e parou.")
	assert_eq([_relation(_host.npc), _memory_times(_host.npc)], [[GAIN, GAIN], [started_at]], "A relação (+3/+3) e uma memória existem.")
	# 2. Salvar NO MEIO da conversa e carregar: registra o que acontece. Um passo antes: o `RelationChanged` da conversa só é entregue no passo seguinte e,
	# com evento na fila, `can_capture_game()` é falso (a LW-052 também avançava um minuto antes de salvar).
	assert_false(_host.runner.can_capture_game(), "Logo depois de conversar há evento na fila: ainda não dá para salvar.")
	_step_host(1)
	var hash_in_the_middle: String = _host.runner.world.state_hash()
	var middle: Reloaded = _save_and_reload()
	assert_eq(middle.runner.world.state_hash(), hash_in_the_middle, "No meio da conversa: o hash do mundo carregado é o mesmo.")
	var mid_npc: NpcModule.NpcQuery = middle.modules.npc.peek_npc(_npc_id)
	assert_eq([mid_npc.tier, mid_npc.action_id, mid_npc.action_ends_at], [NpcState.TIER_NOTABLE, TALK, started_at + TALK_MIN], "Carregado, o NPC continua T2 e na conversa, com o mesmo fim previsto.")
	assert_eq([middle.modules.npc.lod.level_of(_npc_id), _relation(middle.modules.npc), _memory_times(middle.modules.npc)], [NpcLod.LEVEL_S1, [GAIN, GAIN], [started_at]], "O nível não é salvo (S1); a relação e a memória voltam.")
	for _minute: int in TALK_MIN + AFTER_TALK_MIN:
		middle.runner.step_once()
	var mid_after: NpcModule.NpcQuery = middle.modules.npc.peek_npc(_npc_id)
	assert_ne(mid_after.action_id, TALK, "Em S1 a conversa acaba pelo relógio, no fim previsto, e o NPC segue a rotina.")
	assert_eq([mid_after.tier, _relation(middle.modules.npc), _memory_times(middle.modules.npc)], [NpcState.TIER_NOTABLE, [GAIN, GAIN], [started_at]], "E nada se perde: T2, relação e memória intactos.")
	assert_eq(middle.runner.world.validate().size(), 0, "validate() do mundo carregado no meio da conversa vem vazio.")
	middle.runner.finish()
	# 3. A conversa termina (o corpo relata) e o mundo original segue.
	_step_host(TALK_MIN - 1)
	_finish_the_talk_as_the_body()
	_step_host(AFTER_TALK_MIN)
	assert_ne(_host.npc.peek_npc(_npc_id).action_id, TALK, "Passado o fim, o NPC volta à rotina.")
	# 4. Salvar DEPOIS da conversa e carregar: opinião, memória, hash e validate() iguais.
	var hash_after: String = _host.runner.world.state_hash()
	var after: Reloaded = _save_and_reload()
	assert_eq(after.runner.world.state_hash(), hash_after, "Depois da conversa: o mesmo hash.")
	assert_eq([_relation(after.modules.npc), _memory_times(after.modules.npc), after.modules.npc.peek_npc(_npc_id).tier], [_relation(_host.npc), _memory_times(_host.npc), NpcState.TIER_NOTABLE], "Opinião, memória e tier iguais.")
	assert_eq([after.runner.world.validate().size(), _host.runner.world.validate().size()], [0, 0], "validate() vazio nos dois mundos.")
	# 5. No mundo carregado o cooldown vale; passado ele, a 2ª conversa traz `known`.
	var loaded_npc: NpcModule = after.modules.npc
	assert_true(loaded_npc.request_set_bodies_available(true).ok)
	var loaded_actor: CharacterQuery = after.modules.character.peek_character(_actor_id)
	assert_true(loaded_actor.result.ok, loaded_actor.result.message)
	assert_true(loaded_npc.request_set_focus(_actor_id, loaded_actor.position).ok)
	after.runner.step_once()
	var next_to_npc: Vector3 = Vector3(float(loaded_npc.lod.position_of(_npc_id).x) / NpcLod.CM_PER_METER_FLOAT + CLOSE_M, A_M.y, float(loaded_npc.lod.position_of(_npc_id).y) / NpcLod.CM_PER_METER_FLOAT)
	assert_true(after.modules.character.report_position(_actor_id, next_to_npc, 0.0).ok)
	var too_soon: NpcModule.ConverseResult = loaded_npc.request_converse(_actor_id, next_to_npc, _npc_id)
	assert_eq(too_soon.result.code, NpcModule.CODE_TALK_COOLDOWN, "Carregado, o cooldown ainda vale: %s" % too_soon.result.message)
	for _minute: int in COOLDOWN:
		after.runner.step_once()
	var second: NpcModule.ConverseResult = loaded_npc.request_converse(_actor_id, next_to_npc, _npc_id)
	assert_true(second.result.ok, second.result.message)
	assert_eq([second.text_key, second.was_promoted, _relation(loaded_npc), _memory_times(loaded_npc).size()], [NpcPlayerTalk.TEXT_KEY_KNOWN, false, [2 * GAIN, 2 * GAIN], 2], "2ª conversa: known, sem promover de novo, +3/+3 e mais uma memória.")
	assert_eq(after.runner.world.validate().size(), 0)
	after.runner.finish()
