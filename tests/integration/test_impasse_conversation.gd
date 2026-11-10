extends GutTest
## LW-085b (achado I3 da revisão cruzada da LW-085): o detector de impasse (LW-073) e a conversa do jogador (LW-083) JUNTOS, sem janela e com o jogo real de res://data às 07:00 (host,
## ponte, terreno, 100 NPCs), como na LW-083f. Nenhum teste cruzava os dois: o NPC que para para conversar tem uma Intent `talk_player` que o corpo precisa cumprir, e aqui o corpo NUNCA
## relata (não há apresentação). A conversa vence por tempo (o Intent cancela a ação sem efeito), o NPC volta a decidir, o vencimento seguinte fecha uma sequência de
## `NpcImpasse.DEFAULT_LIMIT_MIN` minutos e ele é recuperado (`result_timeout`, corpo solto, casa). O que a conversa deixou (T2, relação com o jogador, memória e o minuto dela, que é o
## cooldown) não pode se perder em nenhum desses passos. CONTROLE (como o da 082h): o retrato "o que a conversa deixou" é o instrumento do teste, e o controle prova, por mutação de uma
## cópia dele, que a comparação acusa cada perda.

const DATA_DIR: String = "res://data"
const WORLD_SEED: int = 5
const START_MIN: int = 7 * SimClock.MINUTES_PER_HOUR
const A_M: Vector3 = Vector3(320.0, 10.0, 540.0)
const WALK_MIN: int = 60
const WARMUP_MIN: int = 30
const CLOSE_M: float = 1.5
const WORK: String = "work"
const TALK: String = "talk_player"
const GAIN: int = 3
const LIMIT_MIN: int = NpcImpasse.DEFAULT_LIMIT_MIN
## Teto de espera de cada fase: um dia de jogo (o teste falha com mensagem, nunca fica preso).
const MAX_WAIT_MIN: int = SimClock.MINUTES_PER_DAY

var _data: NpcLifeCheck.GameData
var _host: SimulationHostNode
var _bridge: SimBridge
var _actor_id: int = 0
var _npc_id: int = 0
var _spot: Vector3 = Vector3.ZERO


func before_all() -> void:
	_data = NpcLifeCheck.load_game_data()
	assert_eq(_data.problem, "", "Os dados reais do jogo carregam.")


func after_each() -> void:
	if _host != null:
		_host.runner.finish()
		_host.free()
	_host = null


## O jogo às 07:00, o ator nascido pela ponte, os corpos ligados, a caminhada até o povoado A e meia hora lá até haver NPCs em S0 (a mesma chegada da LW-083f).
func _arrive_at_the_settlement() -> void:
	var setup: NpcSetup = NpcSetup.from_dir(DATA_DIR, SettlementService.new(_data.settlements, _data.places))
	assert_true(setup.result.ok, setup.result.message)
	_host = SimulationHostNode.new()
	_host.start_new_game(WORLD_SEED, _data.terrain, _data.points, setup, START_MIN)
	_bridge = SimBridge.new(_host, _data.terrain, _data.places, _host.npc)
	_actor_id = _bridge.request_spawn_character().actor_id
	assert_true(_bridge.request_set_bodies_available(true).ok)
	var from: Vector3 = _data.terrain.peek_spawn_point()
	for minute: int in WALK_MIN:
		assert_true(_bridge.request_report_position(_actor_id, from.lerp(A_M, float(minute + 1) / float(WALK_MIN)), 0.0).ok)
		_host.runner.step_once()
	for _minute: int in WARMUP_MIN:
		_host.runner.step_once()


func _now() -> int:
	return _host.runner.world.context.clock.total_minutes()


## Anda minuto a minuto até `done` valer (no máximo MAX_WAIT_MIN) e devolve o minuto em que parou: o do passo que fez `done` valer.
func _step_until(done: Callable) -> int:
	for _minute: int in MAX_WAIT_MIN:
		if done.call():
			break
		_host.runner.step_once()
	return _now()


func _talk_is_over() -> bool:
	return _host.npc.peek_npc(_npc_id).action_id != TALK


func _record_of_the_npc() -> Dictionary:
	for record: Dictionary in _host.npc.peek_impasse_records():
		if record[NpcImpasse.KEY_NPC_ID] == _npc_id:
			return record
	return {}


func _is_recovered() -> bool:
	return not _record_of_the_npc().is_empty()


## O jogador a 1,5 m do corpo do NPC; o relato vai pela ponte, que guarda no personagem e leva o foco do LOD para junto dele.
func _stand_next_to(npc_id: int) -> void:
	var body_cm: Vector2i = _host.npc.lod.position_of(npc_id)
	_spot = Vector3(float(body_cm.x) / NpcLod.CM_PER_METER_FLOAT + CLOSE_M, A_M.y, float(body_cm.y) / NpcLod.CM_PER_METER_FLOAT)
	assert_true(_bridge.request_report_position(_actor_id, _spot, 0.0).ok)


## O retrato do que a conversa deixou: o tier, a relação com o jogador, os minutos das memórias e o minuto da última conversa (o cooldown, que vive no estado salvo).
func _left_by_the_talk() -> Dictionary:
	var opinion: NpcModule.OpinionQuery = _host.npc.peek_opinion(_actor_id, _npc_id)
	var relation: Array[int] = []
	if opinion.is_known:
		relation.assign([opinion.values[NpcRelation.DIM_AFFECTION], opinion.values[NpcRelation.DIM_TRUST]])
	var times: Array[int] = []
	for record: MemoryRecord in _host.npc.peek_memories(_npc_id).records:
		times.append(record.time)
	var saved: Dictionary = _host.npc.serialize()[NpcModule.KEY_NPCS][str(_npc_id)]
	return {"tier": _host.npc.peek_npc(_npc_id).tier, "relation": relation, "memories": times, "last_talk": saved.get(NpcState.KEY_LAST_PLAYER_TALK_AT, NpcState.NO_TIME)}


## As partes do retrato `before` que `after` não tem iguais.
func _lost(before: Dictionary, after: Dictionary) -> Array[String]:
	var lost: Array[String] = []
	for key: String in before:
		if after.get(key) != before[key]:
			lost.append(key)
	return lost


func test_a_talk_the_body_never_answers_times_out_and_the_npc_is_then_recovered_keeping_what_the_talk_left() -> void:
	_arrive_at_the_settlement()
	for candidate: int in _host.npc.lod.s0_ids():
		if _npc_id == 0 and _host.npc.peek_npc(candidate).action_id == WORK:
			_npc_id = candidate
	assert_ne(_npc_id, 0, "Junto de A há um lavrador com corpo trabalhando.")
	if _npc_id == 0:
		return
	_stand_next_to(_npc_id)
	var started_at: int = _now()
	var talk: NpcModule.ConverseResult = _host.npc.request_converse(_actor_id, _spot, _npc_id)
	assert_true(talk.result.ok, talk.result.message)
	var left: Dictionary = _left_by_the_talk()
	assert_eq(left, {"tier": NpcState.TIER_NOTABLE, "relation": [GAIN, GAIN], "memories": [started_at], "last_talk": started_at}, "A conversa deixou T2, a relação, uma memória e o minuto dela.")
	assert_eq(_host.npc.peek_npc(_npc_id).action_id, TALK)
	# 1. Ninguém relata: a conversa vence por tempo e, sozinha, não é impasse.
	var timed_out_at: int = _step_until(_talk_is_over)
	assert_true(_talk_is_over(), "O Intent da conversa venceu por tempo e a ação foi cancelada.")
	assert_eq(_record_of_the_npc(), {}, "Um vencimento só é tratado pelo tempo limite do Intent: ainda não há impasse.")
	assert_eq(_lost(left, _left_by_the_talk()), [] as Array[String], "A conversa que venceu por tempo não desfez nada.")
	assert_eq(_host.npc.request_converse(_actor_id, _spot, _npc_id).result.code, NpcModule.CODE_TALK_COOLDOWN, "E o cooldown continua valendo.")
	# 2. O vencimento seguinte fecha a sequência de LIMIT_MIN minutos e o NPC é recuperado.
	var recovered_at: int = _step_until(_is_recovered)
	var record: Dictionary = _record_of_the_npc()
	assert_false(record.is_empty(), "Sem ninguém responder, o NPC é recuperado em até um dia de jogo.")
	var npc: NpcModule.NpcQuery = _host.npc.peek_npc(_npc_id)
	assert_eq([record.get(NpcImpasse.KEY_REASON), record.get(NpcImpasse.KEY_PLACE_ID), record.get(NpcImpasse.KEY_MINUTE)], [NpcImpasse.REASON_RESULT_TIMEOUT, npc.home_place_id, recovered_at], "Recuperado pelo vencimento e posto em casa.")
	assert_eq(record.get(NpcImpasse.KEY_OVERDUE_MIN), recovered_at - timed_out_at, "A sequência começou no vencimento da conversa.")
	assert_gte(recovered_at - timed_out_at, LIMIT_MIN, "E durou o limite do detector.")
	assert_ne(npc.action_id, TALK, "O NPC não voltou à conversa.")
	assert_eq(_lost(left, _left_by_the_talk()), [] as Array[String], "Depois da recuperação, T2, relação, memória e cooldown são os que a conversa deixou.")
	assert_eq(_host.runner.world.validate().size(), 0, str(_host.runner.world.validate()))


func test_control_the_comparison_flags_each_thing_the_talk_could_lose() -> void:
	var left: Dictionary = {"tier": NpcState.TIER_NOTABLE, "relation": [GAIN, GAIN], "memories": [START_MIN], "last_talk": START_MIN}
	assert_eq(_lost(left, left.duplicate(true)), [] as Array[String], "Retratos iguais: nada perdido.")
	var losses: Dictionary = {"tier": NpcState.TIER_NORMAL, "relation": [], "memories": [], "last_talk": NpcState.NO_TIME}
	for key: String in losses:
		var mutated: Dictionary = left.duplicate(true)
		mutated[key] = losses[key]
		assert_eq(_lost(left, mutated), [key] as Array[String], "A perda de '%s' é acusada, e só ela." % key)
