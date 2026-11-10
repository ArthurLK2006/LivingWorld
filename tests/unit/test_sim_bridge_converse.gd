extends GutTest
## LW-083d: a ponte repassa a conversa do jogador ao `npc` (SimBridge.request_converse), sem janela e com os dados reais. A posição do ator vem do personagem
## GUARDADO (nunca da apresentação) e a resposta traz sempre a chave do texto: a da conversa ou a da recusa, pelo código. O que a conversa faz no mundo é do npc
## (test_npc_player_talk.gd e test_npc_player_talk_effects.gd); aqui se confere o repasse, a posição, a chave por código, as falhas da ponte e as chaves em pt_br.json.

const DATA_DIR: String = "res://data"
const SETTLEMENT: String = "test_settlement_a"
const WORLD_SEED: int = 3
const UNKNOWN_ID: int = 999
## IDs gastos antes de criar os NPCs, para ficarem acima do ID do ator.
const BURNED_IDS: int = 100

var _data: NpcLifeCheck.GameData
var _host: SimulationHostNode
var _world: World
var _module: NpcModule
var _bridge: SimBridge
var _work: Place
var _actor_id: int = 0
var _npc_id: int = 0
var _far_npc_id: int = 0


func before_all() -> void:
	_data = NpcLifeCheck.load_game_data()
	assert_eq(_data.problem, "", "Os dados reais do jogo carregam.")
	for place: Place in _data.places:
		if place.settlement_id == SETTLEMENT and place.kind == Place.KIND_WORK and (_work == null or place.id < _work.id):
			_work = place


## O jogo da ponte (só traz o personagem) e um mundo do `npc` à parte, às 07:00: um lavrador trabalhando no local de trabalho de A, com corpo, e um NPC longe dele.
## O ator nasce pela ponte e relata a posição a 2 m do lavrador.
func before_each() -> void:
	_host = SimulationHostNode.new()
	_host.start_new_game(WORLD_SEED, _data.terrain)
	var setup: NpcSetup = NpcSetup.from_dir(DATA_DIR, SettlementService.new(_data.settlements, _data.places))
	assert_true(setup.result.ok, setup.result.message)
	_module = NpcModule.new(setup.need_defs, setup.routine, setup.definitions)
	var clock: SimClock = SimClock.new()
	_world = World.new(SimContext.new(clock, EventBus.new(clock), WorldRng.new(WORLD_SEED), IdGenerator.new()))
	assert_true(_world.register_module("npc", _module).ok)
	_world.setup()
	_world.post_setup()
	for _minute: int in 7 * SimClock.MINUTES_PER_HOUR:
		clock.advance_step()
	assert_true(_module.request_set_bodies_available(true).ok)
	_bridge = SimBridge.new(_host, _data.terrain, _data.places, _module)
	_actor_id = _bridge.request_spawn_character().actor_id
	assert_true(_bridge.request_report_position(_actor_id, _work.position + Vector3(2.0, 0.0, 0.0), 0.0).ok)
	# O jogo de verdade tem UM gerador de IDs (o ator e os NPCs nunca coincidem); aqui são dois mundos, então os IDs dos NPCs saem da faixa do ator.
	for _burned: int in BURNED_IDS:
		_world.context.ids.next_id()
	var spec: NpcSpec = NpcSpec.new()
	spec.name_key = "npc.name.villager"
	spec.settlement_id = SETTLEMENT
	_far_npc_id = _module.request_create_npc(spec).npc_id
	spec.occupation_id = "farmer"
	spec.place_id = _work.id
	spec.work_place_id = _work.id
	spec.x_cm = roundi(_work.position.x * NpcLod.CM_PER_METER_FLOAT)
	spec.z_cm = roundi(_work.position.z * NpcLod.CM_PER_METER_FLOAT)
	_npc_id = _module.request_create_npc(spec).npc_id
	for _minute: int in 15:
		clock.advance_step()
		_world.tick(1)
	assert_eq([_module.lod.level_of(_npc_id), _module.peek_npc(_npc_id).action_id], [NpcLod.LEVEL_S0, "work"], "O lavrador, com corpo, trabalha.")


func after_each() -> void:
	_host.runner.finish()
	_host.free()
	_world.teardown()


# ---------------------------------------------------------------------------------------------------- o repasse

func test_the_reply_carries_the_result_the_key_and_the_promotion_and_the_npc_stops() -> void:
	var reply: BridgeReplies.ConverseReply = _bridge.request_converse(_actor_id, _npc_id)
	assert_true(reply.result.ok, reply.result.message)
	assert_eq([reply.text_key, reply.was_promoted], [NpcPlayerTalk.TEXT_KEY_FIRST, true], "Primeira conversa: first, e o NPC virou T2.")
	assert_eq([_module.peek_npc(_npc_id).action_id, _module.peek_npc(_npc_id).tier], ["talk_player", NpcState.TIER_NOTABLE])


func test_the_position_comes_from_the_stored_character_not_from_the_caller() -> void:
	assert_true(_bridge.request_report_position(_actor_id, _work.position + Vector3(12.0, 0.0, 0.0), 0.0).ok)
	var before: String = JSON.stringify(_module.serialize())
	var far: BridgeReplies.ConverseReply = _bridge.request_converse(_actor_id, _npc_id)
	assert_eq([far.result.code, far.text_key], [NpcModule.CODE_TALK_TOO_FAR, "npc.talk.too_far"], "A 12 m guardados, a ponte recusa (não há como passar outra posição).")
	assert_eq(JSON.stringify(_module.serialize()), before, "A recusa não mudou nada no npc.")
	assert_true(_bridge.request_report_position(_actor_id, _work.position + Vector3(2.0, 0.0, 0.0), 0.0).ok)
	assert_true(_bridge.request_converse(_actor_id, _npc_id).result.ok, "De volta a 2 m, a mesma ponte aceita.")


func test_each_refusal_comes_back_with_its_own_key() -> void:
	assert_true(_bridge.request_converse(_actor_id, _npc_id).result.ok)
	var again: BridgeReplies.ConverseReply = _bridge.request_converse(_actor_id, _npc_id)
	assert_eq([again.result.code, again.text_key], [NpcModule.CODE_TALK_COOLDOWN, "npc.talk.cooldown"])
	var no_body: BridgeReplies.ConverseReply = _bridge.request_converse(_actor_id, _far_npc_id)
	assert_eq([no_body.result.code, no_body.text_key], [NpcLod.CODE_NOT_IN_S0, "npc.talk.no_body"], "O NPC longe do foco não tem corpo.")
	var gone: BridgeReplies.ConverseReply = _bridge.request_converse(_actor_id, UNKNOWN_ID)
	assert_eq([gone.result.code, gone.text_key], [NpcModule.CODE_UNKNOWN, "npc.talk.gone"])


func test_the_bridge_failures_answer_with_the_generic_key() -> void:
	var unknown_actor: BridgeReplies.ConverseReply = _bridge.request_converse(UNKNOWN_ID, _npc_id)
	assert_eq([unknown_actor.result.ok, unknown_actor.text_key], [false, BridgeReplies.ConverseReply.FALLBACK_KEY], "Ator que o personagem não conhece: a falha dele e a chave genérica.")
	var without_npc: BridgeReplies.ConverseReply = SimBridge.new(_host, _data.terrain, _data.places).request_converse(_actor_id, _npc_id)
	assert_eq([without_npc.result.code, without_npc.text_key], [SimBridge.CODE_NO_NPC, BridgeReplies.ConverseReply.FALLBACK_KEY])
	var idle_host: SimulationHostNode = SimulationHostNode.new()
	var without_game: BridgeReplies.ConverseReply = SimBridge.new(idle_host, _data.terrain, _data.places, _module).request_converse(_actor_id, _npc_id)
	assert_eq(without_game.result.code, SimBridge.CODE_NO_GAME)
	idle_host.free()


# ---------------------------------------------------------------------------------------------------- as chaves

func test_every_refusal_code_has_a_key_and_every_key_exists_in_the_text_file() -> void:
	var texts: UiText = UiText.from_file(UiText.DEFAULT_PATH).texts
	var refusals: Array[String] = [NpcModule.CODE_TALK_TOO_FAR, NpcModule.CODE_TALK_BUSY, NpcModule.CODE_TALK_COOLDOWN, NpcLod.CODE_NOT_IN_S0, NpcTiers.CODE_DEAD, NpcModule.CODE_UNKNOWN, RelationGraph.CODE_INVALID, RelationGraph.CODE_NOT_ALLOWED, NpcLod.CODE_INVALID_POSITION]
	for code: String in refusals:
		var reply: BridgeReplies.ConverseReply = BridgeReplies.ConverseReply.new(Result.failure(code, "x"), "", false)
		assert_eq(reply.text_key, BridgeReplies.ConverseReply.FAILURE_KEYS.get(code), "O código %s tem a sua chave." % code)
		assert_ne(reply.text_key, BridgeReplies.ConverseReply.FALLBACK_KEY, "O código %s não cai na chave genérica." % code)
	assert_eq(BridgeReplies.ConverseReply.new(Result.failure("OUTRO", "x"), "", false).text_key, BridgeReplies.ConverseReply.FALLBACK_KEY)
	assert_eq(BridgeReplies.ConverseReply.new(Result.success(), NpcPlayerTalk.TEXT_KEY_KNOWN, false).text_key, NpcPlayerTalk.TEXT_KEY_KNOWN, "Sucesso passa a chave do npc.")
	var keys: Array[String] = [NpcPlayerTalk.TEXT_KEY_FIRST, NpcPlayerTalk.TEXT_KEY_KNOWN, BridgeReplies.ConverseReply.FALLBACK_KEY]
	keys.append_array(BridgeReplies.ConverseReply.FAILURE_KEYS.values())
	for key: String in keys:
		assert_true(key.begins_with("npc.talk."), "A chave %s tem o prefixo npc.talk." % key)
		assert_true(texts.has_key(key), "Falta a chave '%s' em data/text/pt_br.json." % key)
		assert_ne(texts.get_text(key), "[%s]" % key, "A chave '%s' devolveu a própria chave." % key)
