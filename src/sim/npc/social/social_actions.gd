class_name SocialActions
extends RefCounted
## As consequências sociais das ações `talk` e `help` (LW-080; docs/modules/npc.md, seção 7). O pensador avisa quando uma ação TERMINA
## (`on_action_finished`); aqui sai o que ela deixa para trás, sem tocar em nenhum dado alheio: tudo é pedido ao dono pelos três
## colaboradores que o módulo entrega (consultar a relação, ajustar a relação, gravar memória), então as regras de cada dado (T2, limite, tipos)
## continuam no dono. O alívio da necessidade `social` é do `ActionRunner` e não muda.
##  - `talk`: quem conversa no MESMO local (o NPC que acabou de terminar e os outros vivos que ainda estão em `talk`) forma pares por ORDEM DE ID: o menor
##    com o segundo menor, o terceiro com o quarto... (sem isso o menor ID viraria parceiro de todo mundo); o que sobra sem par não conversa com ninguém. Cidadão com cidadão só alivia a
##    necessidade (Q11): nada além disso. Com ao menos um notável, a afeição e a confiança do par sobem `talk_gain` cada, sem passar do teto
##    `talk_limit` (abaixo do teto soma sem ultrapassá-lo; no teto ou acima, não soma), e cada NOTÁVEL grava o episódio `conversation`.
##  - `help`: cada notável vivo que está no local de quem ajudou grava o episódio `help_received` (valência positiva), com quem ajudou como pessoa.
## Pedido que o dono recusa (relações ou memória não configuradas, tipo ausente, limite) é esperado numa simulação configurada pela metade:
## a consequência que não cabe simplesmente não acontece, sem erro.

const TALK_ACTION_ID: String = "talk"
const HELP_ACTION_ID: String = "help"
## Tipos de episódio gravados (data/memory_kinds.json).
const TALK_MEMORY_KIND: String = "conversation"
const HELP_MEMORY_KIND: String = "help_received"

var _states: Dictionary[int, NpcState]
var _talk_gain: int
var _talk_limit: int
## (a_id: int, b_id: int) -> PackedInt64Array: as dimensões de hoje, ou lista vazia se o par não se conhece.
var _relation_values: Callable
## (a_id: int, b_id: int, deltas: PackedInt64Array) -> Result.
var _adjust_relation: Callable
## (npc_id: int, kind_id: String, actor_ids: Array[int], place_id: String) -> Result.
var _record_memory: Callable


## `states`: a tabela de NPCs do módulo (a MESMA, por referência; só leitura aqui).
func _init(states: Dictionary[int, NpcState], talk_gain: int, talk_limit: int, relation_values: Callable, adjust_relation: Callable, record_memory: Callable) -> void:
	_states = states
	_talk_gain = talk_gain
	_talk_limit = talk_limit
	_relation_values = relation_values
	_adjust_relation = adjust_relation
	_record_memory = record_memory


## Uma ação do NPC terminou no local `place_id`. Só `talk` e `help` têm consequência social; as outras ações passam sem efeito.
func on_action_finished(npc_id: int, action_id: String, place_id: String, _now: int) -> void:
	if not _states.has(npc_id) or place_id.is_empty():
		return
	if action_id == TALK_ACTION_ID:
		_on_talk(npc_id, place_id)
	elif action_id == HELP_ACTION_ID:
		_on_help(npc_id, place_id)


## O parceiro de `npc_id` na conversa em `place_id`, ou IdGenerator.NO_ID se ficou sem par. Entram na lista, em ordem de ID, o próprio NPC (que acabou de
## terminar) e os outros vivos do local que ainda estão em `talk`; os pares são (1º, 2º), (3º, 4º)... e o último de uma lista ímpar fica sem par.
func talk_partner(npc_id: int, place_id: String) -> int:
	var talkers: Array[int] = []
	for candidate_id: int in _sorted_ids():
		var candidate: NpcState = _states[candidate_id]
		if candidate.is_alive and candidate.place_id == place_id and (candidate_id == npc_id or candidate.action_id == TALK_ACTION_ID):
			talkers.append(candidate_id)
	var position: int = talkers.find(npc_id)
	if position < 0:
		return IdGenerator.NO_ID
	var partner_position: int = position + 1 if position % 2 == 0 else position - 1
	return talkers[partner_position] if partner_position < talkers.size() else IdGenerator.NO_ID


## Quanto somar à dimensão para a conversa: `talk_gain`, sem passar de `talk_limit`; no teto ou acima, zero (nunca tira).
func capped_gain(current: int) -> int:
	return maxi(mini(_talk_gain, _talk_limit - current), 0)


func _on_talk(npc_id: int, place_id: String) -> void:
	var partner_id: int = talk_partner(npc_id, place_id)
	if partner_id == IdGenerator.NO_ID:
		return
	var notable_ids: Array[int] = []
	for person_id: int in [npc_id, partner_id]:
		if _states[person_id].tier == NpcState.TIER_NOTABLE and _states[person_id].is_alive:
			notable_ids.append(person_id)
	if notable_ids.is_empty():
		return
	var current: PackedInt64Array = _relation_values.call(npc_id, partner_id)
	var affection: int = current[NpcRelation.DIM_AFFECTION] if not current.is_empty() else 0
	var trust: int = current[NpcRelation.DIM_TRUST] if not current.is_empty() else 0
	var deltas: PackedInt64Array = PackedInt64Array([capped_gain(affection), capped_gain(trust), 0, 0, 0])
	_adjust_relation.call(npc_id, partner_id, deltas)
	for notable_id: int in notable_ids:
		var other_id: int = partner_id if notable_id == npc_id else npc_id
		var actors: Array[int] = [other_id]
		_record_memory.call(notable_id, TALK_MEMORY_KIND, actors, place_id)


func _on_help(npc_id: int, place_id: String) -> void:
	var actors: Array[int] = [npc_id]
	for candidate_id: int in _sorted_ids():
		var candidate: NpcState = _states[candidate_id]
		if candidate_id != npc_id and candidate.is_alive and candidate.tier == NpcState.TIER_NOTABLE and candidate.place_id == place_id:
			_record_memory.call(candidate_id, HELP_MEMORY_KIND, actors, place_id)


func _sorted_ids() -> Array[int]:
	var ids: Array[int] = []
	ids.assign(_states.keys())
	ids.sort()
	return ids
