class_name UtilityScorer
extends RefCounted
## Pontuação de utilidade de uma ação candidata (LW-062; contrato em docs/modules/npc.md, seção 5, e arquitetura 9.4). FUNÇÃO PURA em
## inteiros: não sorteia, não lê relógio, não altera nada; mesmo estado e mesmos parâmetros dão sempre a mesma pontuação. Total =
##   benefício + personalidade - custo de tempo - custo de distância - custo de risco + bônus de inércia + bônus de rotina.
## - Benefício: para cada efeito da ação, o alívio (limitado ao que a necessidade ainda tem para aliviar) vezes o peso do NÍVEL de
##   urgência atual da necessidade; efeito que AUMENTA a pressão (ex.: trabalhar cansa) entra com sinal contrário, limitado ao espaço que
##   resta até 100. Os valores usados são os guardados no estado: quem chama leva as necessidades até agora antes (NeedMath.settle).
## - Personalidade: piso de soma((traço - 50) x peso da ação para o traço) / 50, com os traços de 0 a 100 (50 é neutro).
## - Custos (todos pelo piso): tempo = duração em minutos x custo por hora / 60 (duração 0 não custa: a distância já conta);
##   distância = centímetros x custo por 100 m / 10.000; risco = `risk` x percentual / 100.
## - Bônus de inércia (a ação é a que o NPC já faz) e de rotina (é a ação que a rotina manda na hora): valores fixos dos parâmetros.
## Só PONTUA: ordenar, sortear entre as melhores e executar é do fluxo de decisão (LW-063).

const CODE_NOT_READY: String = "NPC_SCORER_NOT_READY"
const CODE_UNKNOWN_REFERENCE: String = "NPC_SCORER_UNKNOWN_REFERENCE"
const POINTS_NEUTRAL_TRAIT: int = NpcState.NEUTRAL_TRAIT
## Divisor do ajuste de personalidade e da conversão de minutos e centímetros (nomes só para o código dizer o que é).
const PERSONALITY_DIVISOR: int = 50
const CM_PER_100_M: int = 10000
const PERCENT: int = 100

var _params: NpcParams
var _need_defs: Array[NeedDef]
var _need_position: Dictionary[String, int] = {}
var _trait_position: Dictionary[String, int] = {}
## Motivo de o pontuador não servir (vazio = serve). Conferido uma vez, no construtor.
var _problem: String = ""


## `need_defs`: as cinco definições na ordem de `order`; `trait_defs`: os quatro traços na ordem de `order` (ambos como os carregadores os
## entregam).
func _init(params: NpcParams, need_defs: Array[NeedDef], trait_defs: Array[TraitLoader.TraitDef]) -> void:
	_params = params
	_need_defs = need_defs
	_problem = _definitions_problem(trait_defs)


## Motivo de o pontuador não servir (texto vazio se serve).
func peek_problem() -> String:
	return _problem


## Pontua `action` para `state`. `distance_cm`: caminhada até o local da ação (0 se já está lá; negativo conta como 0). `is_current`: é a
## ação que o NPC faz agora. `is_routine`: é a ação da rotina na hora. Referência desconhecida (necessidade ou traço fora das definições)
## devolve falha, sem pontuação.
func score(state: NpcState, action: ActionDef, distance_cm: int, is_current: bool, is_routine: bool) -> ScoreBreakdown:
	if not _problem.is_empty():
		return ScoreBreakdown.failed(Result.failure(CODE_NOT_READY, "UtilityScorer.score: pontuador não está pronto (%s)." % _problem))
	var breakdown: ScoreBreakdown = ScoreBreakdown.new()
	for effect: ActionDef.ActionEffect in action.effects:
		if not _need_position.has(effect.need_id):
			return ScoreBreakdown.failed(_unknown("necessidade", effect.need_id, action.id))
		breakdown.benefit += _effect_benefit(state, effect)
	var weighted_traits: int = 0
	for weight: ActionDef.ActionTraitWeight in action.trait_weights:
		if not _trait_position.has(weight.trait_id):
			return ScoreBreakdown.failed(_unknown("traço", weight.trait_id, action.id))
		weighted_traits += (state.traits[_trait_position[weight.trait_id]] - POINTS_NEUTRAL_TRAIT) * weight.weight
	breakdown.personality = IntMath.floor_div(weighted_traits, PERSONALITY_DIVISOR)
	breakdown.time_cost = IntMath.floor_div(maxi(action.duration_min, 0) * _params.time_cost_per_hour, SimClock.MINUTES_PER_HOUR)
	breakdown.distance_cost = IntMath.floor_div(maxi(distance_cm, 0) * _params.distance_cost_per_100m, CM_PER_100_M)
	breakdown.risk_cost = IntMath.floor_div(action.risk * _params.risk_cost_percent, PERCENT)
	breakdown.inertia_bonus = _params.inertia_bonus if is_current else 0
	breakdown.routine_bonus = _params.routine_bonus if is_routine else 0
	breakdown.total = breakdown.benefit + breakdown.personality - breakdown.time_cost - breakdown.distance_cost - breakdown.risk_cost + breakdown.inertia_bonus + breakdown.routine_bonus
	return breakdown


## Benefício de UM efeito: alívio (ou, com sinal contrário, aumento de pressão) vezes o peso do nível de urgência da necessidade agora.
func _effect_benefit(state: NpcState, effect: ActionDef.ActionEffect) -> int:
	var position: int = _need_position[effect.need_id]
	var value: int = state.need_values[position]
	var weight: int = _params.urgency_weight(NeedMath.urgency(value, _need_defs[position]))
	if effect.delta < 0:
		return mini(-effect.delta, value) * weight
	return -mini(effect.delta, NpcState.VALUE_MAX - value) * weight


func _unknown(what: String, missing_id: String, action_id: String) -> Result:
	return Result.failure(CODE_UNKNOWN_REFERENCE, "UtilityScorer.score: a ação '%s' cita %s '%s', que não existe nas definições." % [action_id, what, missing_id])


## Motivo de as definições não servirem (texto vazio se servem); monta os índices de consulta.
func _definitions_problem(trait_defs: Array[TraitLoader.TraitDef]) -> String:
	if _params == null:
		return "parâmetros nulos"
	var need_problem: String = NeedMath.definitions_problem(_need_defs)
	if not need_problem.is_empty():
		return "definições de necessidades: %s" % need_problem
	if trait_defs.size() != NpcState.TRAIT_COUNT:
		return "%d definições de traço; esperado %d (uma por posição)" % [trait_defs.size(), NpcState.TRAIT_COUNT]
	for def: NeedDef in _need_defs:
		_need_position[def.id] = def.order
	for index: int in trait_defs.size():
		if trait_defs[index].order != index:
			return "o traço '%s' está na posição %d da lista mas tem order %d; esperado a lista ordenada por `order`" % [trait_defs[index].id, index, trait_defs[index].order]
		_trait_position[trait_defs[index].id] = index
	return ""


## As parcelas da pontuação de uma ação (todas inteiras), para o rastro de decisão (LW-064) e para os testes. `result.ok` falso = sem
## pontuação (pontuador não pronto ou referência desconhecida).
class ScoreBreakdown:
	extends RefCounted

	var result: Result = Result.success()
	var benefit: int = 0
	var personality: int = 0
	var time_cost: int = 0
	var distance_cost: int = 0
	var risk_cost: int = 0
	var inertia_bonus: int = 0
	var routine_bonus: int = 0
	var total: int = 0

	static func failed(failure: Result) -> ScoreBreakdown:
		var breakdown: ScoreBreakdown = ScoreBreakdown.new()
		breakdown.result = failure
		return breakdown
