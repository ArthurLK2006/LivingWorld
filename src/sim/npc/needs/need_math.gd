class_name NeedMath
extends RefCounted
## Conta das necessidades (LW-058; contrato em docs/modules/npc.md, seção 2): urgência pelos limiares e variação por hora, tudo em
## inteiros. ATUALIZAÇÃO PREGUIÇOSA E EXATA: o valor só é recalculado quando alguém pede, com
## pontos = piso((taxa x minutos + resto) / 60), valor = limitado a 0..100 e o resto (sempre de 0 a 59) guardado no estado. Como o
## resto vai junto, dividir um intervalo em pedaços dá o MESMO total que calculá-lo de uma vez: o resultado não depende de com que
## frequência o NPC pensa nem de ele estar com corpo ou sem corpo. Para taxa negativa o piso arredonda para baixo (o primeiro minuto
## já tira 1 ponto e o resto compensa depois). Efeitos de ação e alarme (outras tarefas) mexem no valor por fora desta conta.

const URGENCY_COMFORTABLE: int = 0
const URGENCY_ATTENTION: int = 1
const URGENCY_URGENT: int = 2
const URGENCY_CRITICAL: int = 3
const CODE_NO_DEFINITIONS: String = "NPC_NEEDS_NOT_CONFIGURED"
const CODE_TIME_WENT_BACK: String = "NPC_NEEDS_TIME_WENT_BACK"
## Maior valor do resto: o resto está sempre em 0 .. MINUTES_PER_HOUR - 1.
const MAX_REMAINDER: int = SimClock.MINUTES_PER_HOUR - 1


## Nível de urgência de um valor: 0 (confortável), 1 (atenção), 2 (urgente) ou 3 (crítica). Valor igual ao limiar já é o nível dele.
static func urgency(value: int, def: NeedDef) -> int:
	if value >= def.critical:
		return URGENCY_CRITICAL
	if value >= def.urgent:
		return URGENCY_URGENT
	if value >= def.attention:
		return URGENCY_ATTENTION
	return URGENCY_COMFORTABLE


## Novo valor e novo resto de UMA necessidade depois de `minutes` minutos (0 ou mais). Função pura.
static func advance(value: int, remainder: int, rate_per_hour: int, minutes: int) -> Advanced:
	var total: int = rate_per_hour * minutes + remainder
	var points: int = IntMath.floor_div(total, SimClock.MINUTES_PER_HOUR)
	var new_remainder: int = total - points * SimClock.MINUTES_PER_HOUR
	return Advanced.new(clampi(value + points, NpcState.VALUE_MIN, NpcState.VALUE_MAX), new_remainder)


## Problema das definições para esta conta (texto vazio se servem): precisa de uma por posição, na ordem de `order`.
static func definitions_problem(defs: Array[NeedDef]) -> String:
	if defs.size() != NpcState.NEED_COUNT:
		return "%d definições de necessidade; esperado %d (uma por posição, na ordem de `order`)" % [defs.size(), NpcState.NEED_COUNT]
	for index: int in defs.size():
		if defs[index].order != index:
			return "a definição '%s' está na posição %d da lista mas tem order %d; esperado a lista ordenada por `order`" % [defs[index].id, index, defs[index].order]
	return ""


## Leva as necessidades do NPC até o minuto `now_minutes`: atualiza valores e restos pela taxa de cada uma e o minuto da última
## atualização. Não mexe em nada se falhar (sem definições boas, ou `now_minutes` antes da última atualização).
static func settle(state: NpcState, defs: Array[NeedDef], now_minutes: int) -> Result:
	var problem: String = definitions_problem(defs)
	if not problem.is_empty():
		return Result.failure(CODE_NO_DEFINITIONS, "NeedMath.settle: NPC %d: %s." % [state.npc_id, problem])
	if now_minutes < state.needs_updated_at:
		return Result.failure(CODE_TIME_WENT_BACK, "NeedMath.settle: NPC %d: o minuto %d é anterior à última atualização das necessidades (minuto %d); o relógio só avança." % [state.npc_id, now_minutes, state.needs_updated_at])
	var elapsed: int = now_minutes - state.needs_updated_at
	for index: int in defs.size():
		var moved: Advanced = advance(state.need_values[index], state.need_remainders[index], defs[index].rate_per_hour, elapsed)
		state.need_values[index] = moved.value
		state.need_remainders[index] = moved.remainder
	state.needs_updated_at = now_minutes
	return Result.success()


## Valor e resto de uma necessidade depois de `advance`.
class Advanced:
	extends RefCounted

	var value: int
	var remainder: int

	func _init(new_value: int, new_remainder: int) -> void:
		value = new_value
		remainder = new_remainder
