class_name NpcPlayerTalk
extends RefCounted
## A porta da conversa do jogador com um NPC (LW-083b; docs/modules/npc.md, seção 7). Confere o pedido e, se vale, manda o NPC parar e conversar (a
## `begin_talk_player` do runtime, LW-083a), grava o cooldown e diz qual texto mostrar. LW-083c: na mesma chamada, depois da parada, promove o NPC a T2 (se
## houver vaga), soma a relação com o jogador e grava a memória. A tabela de NPCs é a do módulo (a mesma, por referência); o módulo segue sendo a única
## porta e só delega aqui. Devolve a CHAVE do texto, nunca o texto (DEC-036).

## Alcance [HIP]: distância horizontal máxima, em metros e inclusive, entre o jogador e o CORPO do NPC (a posição do LOD, não a lógica do estado, que
## fica parada enquanto o NPC está em S0).
const TALK_REACH_M: int = 3
## Cooldown [HIP]: minutos de jogo, contados do COMEÇO da última conversa, até o NPC aceitar outra com o jogador.
const TALK_COOLDOWN_MIN: int = 60
const CM_PER_METER: int = 100
## Chaves de texto de `data/text/pt_br.json` (a 083d as cria): primeira conversa e já conhecidos (existe relação entre o jogador e o NPC).
const TEXT_KEY_FIRST: String = "npc.talk.first"
const TEXT_KEY_KNOWN: String = "npc.talk.known"
const SLEEP_ACTION_ID: String = "sleep"
## O NPC não atende dormindo, fugindo ou ajudando (decisão de Arthur, P2), nem com a janela de alarme aberta.
const BUSY_ACTION_IDS: Array[String] = [SLEEP_ACTION_ID, NpcThinker.FLEE_ACTION_ID, NpcThinker.HELP_ACTION_ID]

var _npcs: Dictionary[int, NpcState]
var _lod: NpcLod
## (npc_id: int) -> Result: a parada para conversar do `NpcDecisionRuntime`.
var _begin_talk: Callable
## (a_id: int, b_id: int) -> PackedInt64Array: as dimensões de hoje da relação do par, vazia se não se conhecem.
var _relation_values: Callable
## (caller: String, npc_id: int) -> Result: a falha "NPC inexistente" do módulo.
var _unknown_npc: Callable
## Promoção, relação e memória (LW-083c): os caminhos únicos dos notáveis. Nulos (as bancadas do alcance e do cooldown da LW-083b), a conversa só valida e para.
var _notables: NpcNotables
## Só para a conta `capped_gain` da conversa entre NPCs (mesmos `talk_gain` e `talk_limit`): a conversa com o jogador soma o mesmo ganho, sem número novo.
var _gain: SocialActions


func _init(npcs: Dictionary[int, NpcState], lod: NpcLod, begin_talk: Callable, relation_values: Callable, unknown_npc: Callable, notables: NpcNotables = null, params: NpcParams = null) -> void:
	_npcs = npcs
	_lod = lod
	_begin_talk = begin_talk
	_relation_values = relation_values
	_unknown_npc = unknown_npc
	_notables = notables
	if notables != null and params != null:
		_gain = SocialActions.new(npcs, params.talk_gain, params.talk_limit, notables.relation_values, notables.adjust_relation, notables.record_memory)


## O `actor_id`, em `actor_position_m`, pede para conversar com `npc_id` no minuto `now`. Confere nesta ordem (a primeira que falha recusa e NADA muda): ator
## inválido (ID fora da faixa ou que é um NPC), NPC inexistente, morto, sem corpo (NPC_NOT_IN_S0), posição inválida, longe (NPC_TALK_TOO_FAR), ocupado
## (NPC_TALK_BUSY) e cooldown (NPC_TALK_COOLDOWN). Aceito: o NPC para e conversa, o minuto fica gravado e a chave é `first` (nunca se conheceram, decidido
## ANTES de a relação nascer) ou `known`. Depois (LW-083c) vêm as consequências; se uma delas falhar, a conversa CONTINUA e o resultado leva a falha.
func converse(actor_id: int, actor_position_m: Vector3, npc_id: int, now: int) -> NpcModule.ConverseResult:
	var refusal: Result = _refusal(actor_id, actor_position_m, npc_id, now)
	if not refusal.ok:
		return NpcModule.ConverseResult.new(refusal, "", false)
	var known: PackedInt64Array = _relation_values.call(actor_id, npc_id)
	var started: Result = _begin_talk.call(npc_id)
	if not started.ok:
		return NpcModule.ConverseResult.new(started, "", false)
	_npcs[npc_id].last_player_talk_at = now
	var key: String = TEXT_KEY_FIRST if known.is_empty() else TEXT_KEY_KNOWN
	if _notables == null or _gain == null:
		return NpcModule.ConverseResult.new(Result.success(), key, false)
	return _consequences(actor_id, npc_id, known, key)


## As consequências sociais da conversa que começou, nesta ordem: (1) promove T1 a T2 se houver vaga (com o teto cheio a falha é engolida de propósito, Q1: a conversa
## acontece sem promover e sem memória); (2) soma à relação o ganho da conversa entre NPCs (afeição e confiança, `capped_gain`), criando-a se for a primeira; (3) grava a
## memória `conversation` com o jogador como ator, só se o NPC é T2. Uma falha inesperada em (1) a (3) vai no resultado, sem desfazer a parada; `was_promoted` diz a verdade.
func _consequences(actor_id: int, npc_id: int, known: PackedInt64Array, key: String) -> NpcModule.ConverseResult:
	var state: NpcState = _npcs[npc_id]
	var promoted: bool = false
	if state.tier != NpcState.TIER_NOTABLE:
		var promotion: Result = _notables.promote(npc_id, NpcState.TIER_NOTABLE)
		promoted = promotion.ok
		if not promotion.ok and promotion.code != NpcTiers.CODE_T2_LIMIT_REACHED:
			return NpcModule.ConverseResult.new(promotion, "", false)
	var affection: int = 0 if known.is_empty() else known[NpcRelation.DIM_AFFECTION]
	var trust: int = 0 if known.is_empty() else known[NpcRelation.DIM_TRUST]
	var deltas: PackedInt64Array = PackedInt64Array([_gain.capped_gain(affection), _gain.capped_gain(trust), 0, 0, 0])
	var adjusted: Result = _notables.adjust_relation(actor_id, npc_id, deltas)
	if not adjusted.ok:
		return NpcModule.ConverseResult.new(adjusted, "", promoted)
	if state.tier == NpcState.TIER_NOTABLE:
		var actors: Array[int] = [actor_id]
		var remembered: Result = _notables.record_memory(npc_id, SocialActions.TALK_MEMORY_KIND, actors, state.place_id)
		if not remembered.ok:
			return NpcModule.ConverseResult.new(remembered, "", promoted)
	return NpcModule.ConverseResult.new(Result.success(), key, promoted)


## Sucesso se nada impede a conversa; senão, a primeira falha. Não altera nada.
func _refusal(actor_id: int, actor_position_m: Vector3, npc_id: int, now: int) -> Result:
	if actor_id < IdGenerator.FIRST_ID or actor_id > IdGenerator.MAX_ID:
		return Result.failure(RelationGraph.CODE_INVALID, "NpcModule.request_converse: ator %d fora da faixa [%d, %d]." % [actor_id, IdGenerator.FIRST_ID, IdGenerator.MAX_ID])
	if _npcs.has(actor_id):
		return Result.failure(RelationGraph.CODE_NOT_ALLOWED, "NpcModule.request_converse: o ator %d é um NPC; esperado o jogador (um ID que não está na tabela de NPCs)." % actor_id)
	if not _npcs.has(npc_id):
		var unknown: Result = _unknown_npc.call("request_converse", npc_id)
		return unknown
	var state: NpcState = _npcs[npc_id]
	if not state.is_alive:
		return Result.failure(NpcTiers.CODE_DEAD, "NpcModule.request_converse: o NPC %d está morto; esperado um NPC vivo." % npc_id)
	if _lod.level_of(npc_id) != NpcLod.LEVEL_S0:
		return Result.failure(NpcLod.CODE_NOT_IN_S0, "NpcModule.request_converse: o NPC %d não tem corpo (não está em S0); só quem tem corpo para e conversa." % npc_id)
	var max_m: float = float(NpcLod.MAX_COORDINATE_CM) / NpcLod.CM_PER_METER_FLOAT
	if not is_finite(actor_position_m.x) or not is_finite(actor_position_m.z) or actor_position_m.x < 0.0 or actor_position_m.z < 0.0 or actor_position_m.x > max_m or actor_position_m.z > max_m:
		return Result.failure(NpcLod.CODE_INVALID_POSITION, "NpcModule.request_converse: posição do ator %s fora da faixa; esperado x e z finitos, de 0 a %s m." % [str(actor_position_m), max_m])
	var body_cm: Vector2i = _lod.position_of(npc_id)
	var delta_x: int = roundi(actor_position_m.x * NpcLod.CM_PER_METER_FLOAT) - body_cm.x
	var delta_z: int = roundi(actor_position_m.z * NpcLod.CM_PER_METER_FLOAT) - body_cm.y
	var reach_cm: int = TALK_REACH_M * CM_PER_METER
	if delta_x * delta_x + delta_z * delta_z > reach_cm * reach_cm:
		return Result.failure(NpcModule.CODE_TALK_TOO_FAR, "NpcModule.request_converse: o ator está longe do NPC %d (corpo em %s cm); esperado no máximo %d m na horizontal." % [npc_id, str(body_cm), TALK_REACH_M])
	if state.alarm_until > now or BUSY_ACTION_IDS.has(state.action_id):
		return Result.failure(NpcModule.CODE_TALK_BUSY, "NpcModule.request_converse: o NPC %d está ocupado ('%s', alarme até o minuto %d) e não atende." % [npc_id, state.action_id, state.alarm_until])
	if state.last_player_talk_at != NpcState.NO_TIME and now - state.last_player_talk_at < TALK_COOLDOWN_MIN:
		return Result.failure(NpcModule.CODE_TALK_COOLDOWN, "NpcModule.request_converse: o NPC %d conversou no minuto %d; esperado %d min entre conversas (agora é o minuto %d)." % [npc_id, state.last_player_talk_at, TALK_COOLDOWN_MIN, now])
	return Result.success()
