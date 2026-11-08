class_name RelationGraph
extends RefCounted
## O grafo esparso de relações do módulo `npc` (LW-079; docs/modules/npc.md, seção 7): uma `NpcRelation` por par, numa tabela só, com a chave
## do par em ordem (perguntar (a, b) ou (b, a) dá a mesma). Só existe relação entre quem se conheceu, e só se um dos lados é um notável (T2) VIVO
## ou é o jogador [Q11]: T1 com T1 só alivia a necessidade `social`. "O jogador" aqui é qualquer ID que NÃO é um NPC da tabela (o `character` é
## dono dele). Cada NPC tem um limite de relações (`capacity`): ao criar uma relação nova com o NPC cheio, sai a relação mais FRACA dele (menor
## soma dos módulos), nunca a que envolve o jogador; sem relação que possa sair, o pedido é recusado e nada muda. A conta é toda em inteiros,
## sem relógio nem sorteio: quem chama entrega o minuto `now`, as regras (`Rules`) e a tabela de NPCs.

const CODE_NOT_CONFIGURED: String = "NPC_RELATIONS_NOT_CONFIGURED"
const CODE_INVALID: String = "NPC_INVALID_RELATION"
const CODE_NOT_ALLOWED: String = "NPC_RELATION_NOT_ALLOWED"
const CODE_LIMIT_REACHED: String = "NPC_RELATION_LIMIT_REACHED"
## Maior mudança de uma dimensão num único pedido (uma virada completa de -100 a +100).
const MAX_DELTA: int = 200
const KIND_EXTERNAL: int = 0
const KIND_DEAD: int = 1
const KIND_CITIZEN: int = 2
const KIND_NOTABLE: int = 3

## Relações por chave do par (`NpcRelation.make_key`).
var relations: Dictionary[String, NpcRelation] = {}


## A relação do par, ou nulo se nunca se conheceram. Não depende da ordem dos IDs.
func find(first_id: int, second_id: int) -> NpcRelation:
	return relations.get(NpcRelation.make_key(first_id, second_id))


func is_empty() -> bool:
	return relations.is_empty()


## Quantas relações envolvem o NPC.
func count_of(npc_id: int) -> int:
	var count: int = 0
	for relation: NpcRelation in relations.values():
		if relation.involves(npc_id):
			count += 1
	return count


## Relações que envolvem a pessoa, em ordem crescente de (a_id, b_id).
func relations_of(npc_id: int) -> Array[NpcRelation]:
	var found: Array[NpcRelation] = []
	for relation: NpcRelation in sorted_relations():
		if relation.involves(npc_id):
			found.append(relation)
	return found


## Todas as relações, em ordem crescente de (a_id, b_id).
func sorted_relations() -> Array[NpcRelation]:
	var ordered: Array[NpcRelation] = []
	for relation: NpcRelation in relations.values():
		ordered.append(relation)
	ordered.sort_custom(func(first: NpcRelation, second: NpcRelation) -> bool:
		if first.a_id != second.a_id:
			return first.a_id < second.a_id
		return first.b_id < second.b_id)
	return ordered


## Que tipo de pessoa é o ID: o jogador (ou qualquer um que não é NPC da tabela), um NPC morto, um cidadão (T1) ou um notável (T2).
static func kind_of(person_id: int, npcs: Dictionary[int, NpcState]) -> int:
	if not npcs.has(person_id):
		return KIND_EXTERNAL
	var state: NpcState = npcs[person_id]
	if not state.is_alive:
		return KIND_DEAD
	return KIND_NOTABLE if state.tier == NpcState.TIER_NOTABLE else KIND_CITIZEN


## Rótulo pela afeição: amigo a partir do limiar de amizade, rival a partir do de rivalidade (limiar 0 desliga o rótulo), senão conhecido.
static func label_for(affection: int, rules: Rules) -> String:
	if rules.friend_threshold > 0 and affection >= rules.friend_threshold:
		return NpcRelation.LABEL_FRIEND
	if rules.rival_threshold > 0 and affection <= -rules.rival_threshold:
		return NpcRelation.LABEL_RIVAL
	return NpcRelation.LABEL_ACQUAINTANCE


## Ajusta a relação do par (soma `deltas`, uma por dimensão, cada dimensão limitada a -100..100), criando-a se ainda não existe (é o "se
## conheceram"). Recusa sem mudar nada: sem configuração, pedido inválido, nenhum dos dois é NPC, NPC morto, T1 com T1 (Q11) ou NPC sem como
## abrir vaga. Relação nova com NPC cheio: sai a mais fraca dele que não envolva o jogador, uma por NPC cheio, e só depois de conferir que todas
## podem sair (tudo ou nada).
func adjust(first_id: int, second_id: int, deltas: PackedInt64Array, now: int, rules: Rules, npcs: Dictionary[int, NpcState]) -> Result:
	if rules == null or rules.capacity <= 0:
		return Result.failure(CODE_NOT_CONFIGURED, "RelationGraph.adjust: relações não configuradas; esperado relations_capacity maior que 0 nos parâmetros.")
	var problem: String = _request_problem(first_id, second_id, deltas)
	if not problem.is_empty():
		return Result.failure(CODE_INVALID, "RelationGraph.adjust: pedido inválido (%d, %d): %s." % [first_id, second_id, problem])
	var first_kind: int = kind_of(first_id, npcs)
	var second_kind: int = kind_of(second_id, npcs)
	if first_kind == KIND_EXTERNAL and second_kind == KIND_EXTERNAL:
		return Result.failure(CODE_NOT_ALLOWED, "RelationGraph.adjust: nem %d nem %d é um NPC; pelo menos um dos lados precisa ser um NPC." % [first_id, second_id])
	for person_id: int in [first_id, second_id]:
		if kind_of(person_id, npcs) == KIND_DEAD:
			return Result.failure(CODE_NOT_ALLOWED, "RelationGraph.adjust: o NPC %d está morto; esperado um NPC vivo." % person_id)
	var both_citizens: bool = first_kind == KIND_CITIZEN and second_kind == KIND_CITIZEN
	if both_citizens:
		return Result.failure(CODE_NOT_ALLOWED, "RelationGraph.adjust: os NPCs %d e %d são cidadãos (T1); a relação só existe se um dos lados é notável (T2) ou o jogador." % [first_id, second_id])
	var today: int = IntMath.floor_div(now, SimClock.MINUTES_PER_DAY)
	var existing: NpcRelation = find(first_id, second_id)
	if existing != null:
		existing.settle(today, rules.decay_per_day)
		existing.add(deltas)
		return Result.success()
	var to_evict: Array[NpcRelation] = []
	for person_id: int in [first_id, second_id]:
		if kind_of(person_id, npcs) == KIND_EXTERNAL or count_of(person_id) < rules.capacity:
			continue
		var weakest: NpcRelation = _weakest_evictable(person_id, today, rules, npcs)
		if weakest == null:
			return Result.failure(CODE_LIMIT_REACHED, "RelationGraph.adjust: o NPC %d já tem %d relações e nenhuma pode sair (todas são com o jogador); a relação com %d não foi criada." % [person_id, rules.capacity, second_id if person_id == first_id else first_id])
		to_evict.append(weakest)
	for evicted: NpcRelation in to_evict:
		relations.erase(evicted.key())
	var created: NpcRelation = NpcRelation.new(first_id, second_id)
	created.met_at = now
	created.updated_day = today
	created.add(deltas)
	relations[created.key()] = created
	return Result.success()


## Apaga todas as relações da pessoa (morte ou remoção do NPC) e devolve quantas eram. As dos outros pares ficam.
func remove_involving(npc_id: int) -> int:
	var doomed: Array[String] = []
	for relation: NpcRelation in relations.values():
		if relation.involves(npc_id):
			doomed.append(relation.key())
	for doomed_key: String in doomed:
		relations.erase(doomed_key)
	return doomed.size()


## Rebaixamento do NPC (T2 vira T1): as relações dele com OUTRO cidadão (T1) deixam de ser válidas (Q11), então são apagadas, e a afeição de
## cada uma em `today` é devolvida (pessoa -> afeição) para virar traço; a relação com o jogador fica, acertada para `today` e com cada
## dimensão arredondada para um múltiplo de PLAYER_ROUNDING; as com notáveis (T2) ficam como estão. Chamado ANTES de o tier mudar.
func demote_relations_of(npc_id: int, now: int, rules: Rules, npcs: Dictionary[int, NpcState]) -> Dictionary[int, int]:
	var summary: Dictionary[int, int] = {}
	var today: int = IntMath.floor_div(now, SimClock.MINUTES_PER_DAY)
	for relation: NpcRelation in relations_of(npc_id):
		var other_id: int = relation.other_id(npc_id)
		var other_kind: int = kind_of(other_id, npcs)
		if other_kind == KIND_CITIZEN:
			summary[other_id] = relation.values_at(today, rules.decay_per_day)[NpcRelation.DIM_AFFECTION]
			relations.erase(relation.key())
		elif other_kind == KIND_EXTERNAL:
			relation.settle(today, rules.decay_per_day)
			for index: int in NpcRelation.DIM_COUNT:
				relation.values[index] = NpcRelation.rounded(relation.values[index], NpcRelation.PLAYER_ROUNDING)
	return summary


## A tabela como lista para o save, em ordem crescente de (a_id, b_id).
func to_array() -> Array:
	var saved: Array = []
	for relation: NpcRelation in sorted_relations():
		saved.append(relation.to_dict())
	return saved


## Lê a lista do save. Qualquer problema de formato (ou par repetido) recusa a lista inteira: o módulo não altera nada.
static func parse(raw_list: Variant) -> ParseResult:
	if typeof(raw_list) != TYPE_ARRAY:
		return ParseResult.new(null, "o campo das relações não é uma lista (veio %s)" % type_string(typeof(raw_list)))
	var items: Array = raw_list
	var graph: RelationGraph = RelationGraph.new()
	for index: int in items.size():
		var parsed: NpcRelation.ParseResult = NpcRelation.parse(items[index])
		if parsed.relation == null:
			return ParseResult.new(null, "relação %d: %s" % [index, parsed.error])
		if graph.relations.has(parsed.relation.key()):
			return ParseResult.new(null, "o par %s aparece duas vezes (relação %d)" % [parsed.relation.key(), index])
		graph.relations[parsed.relation.key()] = parsed.relation
	return ParseResult.new(graph, "")


## Problemas do grafo para o `validate()` do módulo (lista vazia se está tudo certo). `rules` nulo = sem limite conferido; `today` negativo = sem
## relógio (o dia do último acerto não é conferido).
func problems(npcs: Dictionary[int, NpcState], rules: Rules, today: int) -> Array[String]:
	var found: Array[String] = []
	for relation: NpcRelation in sorted_relations():
		var label: String = "Relação %s" % relation.key()
		for person_id: int in [relation.a_id, relation.b_id]:
			if person_id < IdGenerator.FIRST_ID or person_id > IdGenerator.MAX_ID:
				found.append("%s: ID %d fora da faixa [%d, %d]." % [label, person_id, IdGenerator.FIRST_ID, IdGenerator.MAX_ID])
		if relation.a_id == relation.b_id:
			found.append("%s: o par é de uma pessoa com ela mesma." % label)
		var first_kind: int = kind_of(relation.a_id, npcs)
		var second_kind: int = kind_of(relation.b_id, npcs)
		if first_kind == KIND_EXTERNAL and second_kind == KIND_EXTERNAL:
			found.append("%s: nenhum dos dois é um NPC." % label)
		for person_id: int in [relation.a_id, relation.b_id]:
			if kind_of(person_id, npcs) == KIND_DEAD:
				found.append("%s: o NPC %d está morto, mas a relação existe; esperado nenhuma (a morte a descarta)." % [label, person_id])
		if first_kind == KIND_CITIZEN and second_kind == KIND_CITIZEN:
			found.append("%s: os dois são cidadãos (T1); a relação só existe se um dos lados é notável (T2) ou o jogador." % label)
		for index: int in relation.values.size():
			if relation.values[index] < NpcRelation.MIN_VALUE or relation.values[index] > NpcRelation.MAX_VALUE:
				found.append("%s: %s %d fora de %d a %d." % [label, NpcRelation.DIM_IDS[index], relation.values[index], NpcRelation.MIN_VALUE, NpcRelation.MAX_VALUE])
		if relation.met_at < 0:
			found.append("%s: met_at %d negativo." % [label, relation.met_at])
		if relation.updated_day < 0 or (today >= 0 and relation.updated_day > today):
			found.append("%s: updated_day %d fora de 0 a hoje." % [label, relation.updated_day])
	if rules != null and rules.capacity > 0:
		for person_id: int in npcs:
			if count_of(person_id) > rules.capacity:
				found.append("NPC %d: %d relações, mais que o limite %d." % [person_id, count_of(person_id), rules.capacity])
	return found


## A relação mais fraca do NPC (menor soma dos módulos em `today`; empate: a mais antiga, depois o menor par) que NÃO envolve o jogador.
func _weakest_evictable(npc_id: int, today: int, rules: Rules, npcs: Dictionary[int, NpcState]) -> NpcRelation:
	var weakest: NpcRelation = null
	var weakest_strength: int = 0
	for relation: NpcRelation in relations_of(npc_id):
		if kind_of(relation.other_id(npc_id), npcs) == KIND_EXTERNAL:
			continue
		var strength: int = relation.strength_at(today, rules.decay_per_day)
		if weakest == null or strength < weakest_strength or (strength == weakest_strength and relation.met_at < weakest.met_at):
			weakest = relation
			weakest_strength = strength
	return weakest


## Primeiro problema do pedido (texto vazio se está certo): IDs, dimensões e tamanho das mudanças.
func _request_problem(first_id: int, second_id: int, deltas: PackedInt64Array) -> String:
	for person_id: int in [first_id, second_id]:
		if person_id < IdGenerator.FIRST_ID or person_id > IdGenerator.MAX_ID:
			return "ID %d fora da faixa [%d, %d]" % [person_id, IdGenerator.FIRST_ID, IdGenerator.MAX_ID]
	if first_id == second_id:
		return "uma pessoa não tem relação com ela mesma"
	if deltas.size() != NpcRelation.DIM_COUNT:
		return "%d mudanças; esperado %d (uma por dimensão: %s)" % [deltas.size(), NpcRelation.DIM_COUNT, ", ".join(NpcRelation.DIM_IDS)]
	for index: int in deltas.size():
		if absi(deltas[index]) > MAX_DELTA:
			return "mudança %d em %s; esperado de %d a %d" % [deltas[index], NpcRelation.DIM_IDS[index], -MAX_DELTA, MAX_DELTA]
	return ""


## As regras das relações, já tiradas dos parâmetros (conteúdo de `data/`, nada é salvo).
class Rules:
	extends RefCounted

	## Quantas relações cabem por NPC.
	var capacity: int
	## Pontos que cada dimensão perde por dia, rumo a 0.
	var decay_per_day: int
	## Afeição a partir da qual a relação é de amizade; 0 desliga o rótulo.
	var friend_threshold: int
	## Afeição (em módulo, para baixo) a partir da qual a relação é de rivalidade; 0 desliga o rótulo.
	var rival_threshold: int

	func _init(rule_capacity: int, rule_decay_per_day: int, rule_friend_threshold: int, rule_rival_threshold: int) -> void:
		capacity = rule_capacity
		decay_per_day = rule_decay_per_day
		friend_threshold = rule_friend_threshold
		rival_threshold = rule_rival_threshold


## Resultado de `parse`: `graph` só vale se `error` estiver vazio.
class ParseResult:
	extends RefCounted

	var graph: RelationGraph
	var error: String

	func _init(parsed_graph: RelationGraph, parse_error: String) -> void:
		graph = parsed_graph
		error = parse_error
