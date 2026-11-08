class_name NpcIntentBoard
extends RefCounted
## Quadro de Intents do modo S0 (LW-070; contrato em docs/modules/npc.md, seção 6, e arquitetura 8.5). Para um NPC em S0, começar uma ação
## EMITE um NpcIntent em vez de deixar o ActionRunner abstrato contar o tempo; a apresentação cumpre com o corpo e devolve um
## NpcActionResult. Só um resultado de SUCESSO faz os efeitos entrarem, e sempre pela função única do ActionRunner (`finish_embodied`, que
## passa pelo `advance`). BLOCKED e CANCELLED cancelam a ação sem efeito; resultado de ação velha é descartado e contado; Intent sem
## resultado até `intent_timeout_min` depois do fim planejado cancela a ação sem efeito (o NPC volta a poder pensar).
## As intenções pendentes são estado de apresentação em curso: NÃO são salvas e não entram no state_hash (um mundo carregado começa com
## todos em S1, e a ação de quem estava esperando segue em modo abstrato). Quem sai de S0 perde o Intent; a ação segue abstrata.
## Não pensa, não sorteia e não guarda o relógio: recebe `now` de quem chama. Ligado por `configure`; sem isso nada acontece.

const CODE_NOT_CONFIGURED: String = "NPC_INTENTS_NOT_CONFIGURED"
## Resultado que não casa com nenhum Intent pendente (ação velha, tempo limite já vencido, NPC fora de S0): descartado e contado.
const CODE_STALE_RESULT: String = "NPC_RESULT_STALE"
const CODE_INVALID_RESULT: String = "NPC_RESULT_INVALID"
## Desfecho que não combina com o tipo do Intent (ARRIVED para ACT_AT_PLACE, DONE para MOVE_TO_PLACE): o Intent continua pendente.
const CODE_OUTCOME_MISMATCH: String = "NPC_RESULT_OUTCOME_MISMATCH"

var _lod: NpcLod
var _runner: ActionRunner
var _states: Dictionary[int, NpcState] = {}
var _places: SettlementService
var _params: NpcIntentParams
## Um Intent por NPC (um NPC só tem uma ação por vez).
var _pending: Dictionary[int, Pending] = {}
var _discarded_results: int = 0
var _timed_out_intents: int = 0


## `lod_controller`: quem diz quem está em S0 e onde está o corpo (o `lod` do NpcModule).
func _init(lod_controller: NpcLod) -> void:
	_lod = lod_controller


## Liga o quadro. O `runner` precisa ter sido criado sobre a MESMA tabela `states` do módulo (NpcModule.create_action_runner garante).
## `places` é opcional (sem ele só valem ações sem local). Runner que não serve ou parâmetros inválidos: falha tratada, e o quadro fica
## como estava (desligado, se nunca foi ligado).
func configure(runner: ActionRunner, states: Dictionary[int, NpcState], places: SettlementService, params: NpcIntentParams) -> Result:
	if runner == null:
		return Result.failure(CODE_NOT_CONFIGURED, "NpcIntentBoard.configure: runner nulo; esperado um ActionRunner criado sobre a tabela de NPCs do módulo.")
	if not runner.peek_problem().is_empty():
		return Result.failure(CODE_NOT_CONFIGURED, "NpcIntentBoard.configure: o runner não serve (%s)." % runner.peek_problem())
	if params == null:
		return Result.failure(CODE_NOT_CONFIGURED, "NpcIntentBoard.configure: parâmetros nulos; esperado o conteúdo de data/intent_params.json.")
	var problem: String = params.problem()
	if not problem.is_empty():
		return Result.failure(CODE_NOT_CONFIGURED, "NpcIntentBoard.configure: parâmetros inválidos: %s." % problem)
	_runner = runner
	_states = states
	_places = places
	_params = params
	return Result.success()


func is_configured() -> bool:
	return _runner != null and _params != null


## Começa uma ação de um NPC em S0: o runner confere as condições e fixa o fim; em vez de contar o tempo, o quadro emite o Intent
## (`go_to_place` vira MOVE_TO_PLACE; as outras ações, ACT_AT_PLACE). Os efeitos NÃO entram agora: só com o resultado de sucesso. NPC
## fora de S0 usa o runner abstrato (`begin` e `advance`), então aqui falha com NPC_NOT_IN_S0. O local é conferido ANTES de começar,
## para uma recusa não deixar a ação pela metade. Qualquer recusa do runner passa com o código dele (ocupado, condição, NPC morto...).
func begin_embodied(npc_id: int, action_id: String, place_id: String, now: int) -> Result:
	if not is_configured():
		return _unconfigured("begin_embodied")
	if not _states.has(npc_id):
		return Result.failure(ActionRunner.CODE_UNKNOWN_NPC, "NpcIntentBoard.begin_embodied: o NPC %d não existe; esperado um ID da tabela de NPCs." % npc_id)
	if _lod.level_of(npc_id) != NpcLod.LEVEL_S0:
		return Result.failure(NpcLod.CODE_NOT_IN_S0, "NpcIntentBoard.begin_embodied: o NPC %d não está em S0; esperado usar o runner abstrato (begin e advance) para NPC sem corpo." % npc_id)
	var target: Destination = _destination(npc_id, place_id)
	if not target.result.ok:
		return target.result
	var started: Result = _runner.begin(npc_id, action_id, place_id, now)
	if not started.ok:
		return started
	var state: NpcState = _states[npc_id]
	var kind: NpcIntent.Kind = NpcIntent.Kind.MOVE_TO_PLACE if action_id == ActionRunner.GO_TO_PLACE_ID else NpcIntent.Kind.ACT_AT_PLACE
	var intent: NpcIntent = NpcIntent.new(npc_id, state.action_serial, kind, place_id, target.position_cm, state.action_ends_at - state.action_started_at)
	_pending[npc_id] = Pending.new(intent, state.action_ends_at + _params.intent_timeout_min)
	return Result.success()


## Intents que a apresentação ainda não cumpriu, em CÓPIAS e em ordem crescente de NPC. Só os de quem ainda está em S0.
func peek_pending() -> Array[NpcIntent]:
	var copies: Array[NpcIntent] = []
	for npc_id: int in _sorted_pending_ids():
		if _lod.level_of(npc_id) == NpcLod.LEVEL_S0:
			copies.append(_pending[npc_id].intent.copy())
	return copies


## Recebe o resultado da apresentação em `now`. Resultado que não casa com o Intent pendente do NPC (outra ação, tempo limite já
## vencido, NPC fora de S0) é DESCARTADO e contado (NPC_RESULT_STALE), sem mudar nada. Sucesso (ARRIVED ou DONE): os efeitos entram uma
## vez pela função única e o NPC fica livre; BLOCKED e CANCELLED: a ação é cancelada sem efeito e o NPC fica livre. Em todos os casos
## aceitos a posição final vira o último relato do corpo. Desfecho que não combina com o tipo, ou posição inválida: recusado, o Intent
## continua pendente (o tempo limite o cancela se a apresentação não corrigir). O Result de sucesso vale também para BLOCKED e CANCELLED;
## `NPC_ACTION_FAILED` é a falha por regra do runner (uma condição deixou de valer ao terminar): o Intent foi consumido e nada entrou.
func report_result(result: NpcActionResult, now: int) -> Result:
	if not is_configured():
		return _unconfigured("report_result")
	var invalid: String = _result_problem(result)
	if not invalid.is_empty():
		return Result.failure(CODE_INVALID_RESULT, "NpcIntentBoard.report_result: resultado inválido: %s." % invalid)
	var npc_id: int = result.npc_id
	if not _pending.has(npc_id) or _lod.level_of(npc_id) != NpcLod.LEVEL_S0:
		_pending.erase(npc_id)
		return _discard("o NPC %d não tem Intent pendente (o tempo limite já venceu, o NPC saiu de S0 ou a ação já terminou)" % npc_id)
	var intent: NpcIntent = _pending[npc_id].intent
	if intent.action_serial != result.action_serial:
		return _discard("o resultado é da ação %d, mas o Intent pendente do NPC %d é da ação %d" % [result.action_serial, npc_id, intent.action_serial])
	var mismatch: String = _mismatch_problem(intent, result)
	if not mismatch.is_empty():
		return Result.failure(CODE_OUTCOME_MISMATCH, "NpcIntentBoard.report_result: NPC %d: %s." % [npc_id, mismatch])
	var body_cm: Vector2i = to_cm(result.final_position_m)
	if body_cm == LodReconstruction.NO_POSITION:
		return Result.failure(NpcLod.CODE_INVALID_POSITION, "NpcIntentBoard.report_result: NPC %d com posição final %s inválida; esperado números finitos com x e z de 0 a %d cm." % [npc_id, str(result.final_position_m), NpcState.MAX_COORDINATE_CM])
	_pending.erase(npc_id)
	var reported: Result = _lod.report_position(npc_id, body_cm)
	if not reported.ok:
		return reported
	if not result.is_success():
		return _runner.cancel_action(npc_id, intent.action_serial)
	return _runner.finish_embodied(npc_id, intent.action_serial, now).result


## Posições do corpo em lote (NPC -> posição em metros), no máximo uma vez a cada 6 quadros de física [HIP]. Cada posição é
## independente: as válidas valem mesmo se outra do lote for recusada (NPC fora de S0, posição inválida); a falha devolvida é a da
## primeira recusada (menor ID) e diz quantas foram aplicadas. Lote vazio: sucesso.
func report_positions(batch: Dictionary[int, Vector3]) -> Result:
	var ids: Array[int] = []
	ids.assign(batch.keys())
	ids.sort()
	var applied: int = 0
	var first_failure: Result = null
	for npc_id: int in ids:
		var reported: Result = _lod.report_position(npc_id, to_cm(batch[npc_id]))
		if reported.ok:
			applied += 1
		elif first_failure == null:
			first_failure = reported
	if first_failure == null:
		return Result.success()
	return Result.failure(first_failure.code, "%s Posições aplicadas: %d de %d; as válidas do lote valem." % [first_failure.message, applied, ids.size()])


## A cada passo: cancela, SEM efeito, a ação dos Intents que passaram do tempo limite (o limite é `intent_timeout_min` depois do fim
## planejado; a partir do minuto `fim + limite` o Intent já venceu) e solta os Intents de quem saiu de S0 (a ação segue abstrata). Devolve
## os NPCs cancelados por tempo, em ordem crescente (o detector de impasse da LW-073 vai lê-los). Resultado que chegar depois é descartado.
func expire(now: int) -> Array[int]:
	var cancelled: Array[int] = []
	if not is_configured():
		return cancelled
	for npc_id: int in _sorted_pending_ids():
		var entry: Pending = _pending[npc_id]
		if _lod.level_of(npc_id) != NpcLod.LEVEL_S0:
			_pending.erase(npc_id)
			continue
		if now < entry.deadline:
			continue
		_pending.erase(npc_id)
		if _runner.cancel_action(npc_id, entry.intent.action_serial).ok:
			_timed_out_intents += 1
			cancelled.append(npc_id)
	return cancelled


## Contagens para depuração: Intents pendentes, resultados descartados e Intents vencidos por tempo.
func debug_summary() -> Dictionary:
	return {"pending": _pending.size(), "discarded_results": _discarded_results, "timed_out_intents": _timed_out_intents}


## Posição do corpo em metros -> centímetros inteiros no plano (x e z; o y é ignorado). Não finita ou fora de 0 até o máximo do mundo:
## NO_POSITION. Confere em metros ANTES de converter: o Vector2i é de 32 bits e um valor absurdo daria a volta e pareceria válido.
static func to_cm(position_m: Vector3) -> Vector2i:
	var max_m: float = float(NpcState.MAX_COORDINATE_CM) / TerrainData.CM_PER_METER
	if not position_m.is_finite() or position_m.x < 0.0 or position_m.x > max_m or position_m.z < 0.0 or position_m.z > max_m:
		return LodReconstruction.NO_POSITION
	return Vector2i(roundi(position_m.x * TerrainData.CM_PER_METER), roundi(position_m.z * TerrainData.CM_PER_METER))


## Destino do Intent: o local pedido (centro, em cm) ou, sem local, a posição atual do corpo. Local desconhecido: falha, e nada começou.
func _destination(npc_id: int, place_id: String) -> Destination:
	if place_id.is_empty():
		return Destination.new(Result.success(), _lod.position_of(npc_id))
	if _places == null:
		return Destination.new(Result.failure(ActionRunner.CODE_PLACE_UNKNOWN, "NpcIntentBoard.begin_embodied: o local '%s' não pode ser conferido; o quadro foi ligado sem o serviço de locais do `world`." % place_id), LodReconstruction.NO_POSITION)
	var found: SettlementService.PlaceQuery = _places.peek_place(place_id)
	if not found.result.ok:
		return Destination.new(Result.failure(ActionRunner.CODE_PLACE_UNKNOWN, "NpcIntentBoard.begin_embodied: o local '%s' não existe (%s)." % [place_id, found.result.message]), LodReconstruction.NO_POSITION)
	var center: Vector2i = Vector2i(roundi(found.place.position.x * TerrainData.CM_PER_METER), roundi(found.place.position.z * TerrainData.CM_PER_METER))
	return Destination.new(Result.success(), center)


## Problema nos campos do resultado (texto vazio se estão certos). Faixas de verdade ficam por conta do que o resultado vai tocar.
func _result_problem(result: NpcActionResult) -> String:
	if result == null:
		return "resultado nulo; esperado um NpcActionResult"
	if result.npc_id <= IdGenerator.NO_ID:
		return "npc_id %d; esperado um ID maior que %d" % [result.npc_id, IdGenerator.NO_ID]
	if result.action_serial < 1:
		return "action_serial %d; esperado 1 ou mais (o contador das ações do NPC começa em 1)" % result.action_serial
	if result.outcome < NpcActionResult.Outcome.ARRIVED or result.outcome > NpcActionResult.Outcome.CANCELLED:
		return "desfecho %d desconhecido; esperado ARRIVED, DONE, BLOCKED ou CANCELLED" % result.outcome
	return ""


## Desfecho de sucesso que não combina com o tipo do Intent (texto vazio se combina).
func _mismatch_problem(intent: NpcIntent, result: NpcActionResult) -> String:
	if result.outcome == NpcActionResult.Outcome.ARRIVED and intent.kind != NpcIntent.Kind.MOVE_TO_PLACE:
		return "ARRIVED só vale para MOVE_TO_PLACE, e o Intent é ACT_AT_PLACE"
	if result.outcome == NpcActionResult.Outcome.DONE and intent.kind != NpcIntent.Kind.ACT_AT_PLACE:
		return "DONE só vale para ACT_AT_PLACE, e o Intent é MOVE_TO_PLACE"
	return ""


func _discard(why: String) -> Result:
	_discarded_results += 1
	return Result.failure(CODE_STALE_RESULT, "NpcIntentBoard.report_result: resultado descartado: %s." % why)


func _sorted_pending_ids() -> Array[int]:
	var ids: Array[int] = []
	ids.assign(_pending.keys())
	ids.sort()
	return ids


func _unconfigured(caller: String) -> Result:
	return Result.failure(CODE_NOT_CONFIGURED, "NpcIntentBoard.%s: protocolo S0 desligado; esperado NpcModule.configure_intents(runner, locais, parâmetros de data/intent_params.json) antes de usar." % caller)


## Um Intent esperando resultado e o minuto em que vence (fim planejado + intent_timeout_min).
class Pending:
	extends RefCounted

	var intent: NpcIntent
	var deadline: int

	func _init(pending_intent: NpcIntent, pending_deadline: int) -> void:
		intent = pending_intent
		deadline = pending_deadline


## Destino calculado para um Intent: `position_cm` só vale se `result.ok`.
class Destination:
	extends RefCounted

	var result: Result
	var position_cm: Vector2i

	func _init(destination_result: Result, destination_position_cm: Vector2i) -> void:
		result = destination_result
		position_cm = destination_position_cm
