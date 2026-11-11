class_name NpcLifecycle
extends RefCounted
## Vida e morte dos NPCs: criar (LW-057), remover e matar por necessidade crítica prolongada (LW-081), com a conferência do pedido de criação.
## LW-081a (passo 4): o código saiu do `NpcModule` sem mudar de comportamento; o módulo segue sendo a única porta e só delega aqui. A tabela de NPCs é a do
## módulo (a mesma, por referência). A memória e as relações de quem morre ou sai são descartadas pelos `NpcNotables`; o rastro, pelo `DecisionTracer`.

var _npcs: Dictionary[int, NpcState]
var _notables: NpcNotables
var _tracer: DecisionTracer
var _need_defs: Array[NeedDef]
## Motivo de as definições de necessidades não servirem (vazio = servem), conferido uma vez pelo módulo.
var _defs_problem: String
var _routine: RoutineTable
var _definitions: NpcModule.Definitions
## "NPC inexistente" do módulo (a mesma falha tratada em toda a API): recebe o nome do chamador e o ID.
var _unknown: Callable
var _ctx: SimContext
## A porta da economia (`economy/api`, DEC-132; LW-093): o NPC abre a conta dele nela ao nascer. Nulo = módulo sem economia (os testes que só precisam do estado do NPC).
var _economy: EconomyModule


func _init(npcs: Dictionary[int, NpcState], notables: NpcNotables, tracer: DecisionTracer, need_defs: Array[NeedDef], defs_problem: String, routine: RoutineTable, definitions: NpcModule.Definitions, unknown_npc: Callable, economy: EconomyModule = null) -> void:
	_npcs = npcs
	_notables = notables
	_tracer = tracer
	_need_defs = need_defs
	_defs_problem = defs_problem
	_routine = routine
	_definitions = definitions
	_unknown = unknown_npc
	_economy = economy


func setup(ctx: SimContext) -> void:
	_ctx = ctx


## Cria um NPC (ID novo de ctx.ids). Confere o pedido inteiro ANTES de gastar um ID: pedido recusado não altera nada.
func create(spec: NpcSpec) -> NpcModule.CreateResult:
	if _ctx == null:
		return NpcModule.CreateResult.new(Result.failure(NpcModule.CODE_NOT_READY, "NpcModule.request_create_npc: módulo sem setup() (sem relógio nem IDs); esperado um módulo registrado no World."), IdGenerator.NO_ID)
	if not _defs_problem.is_empty():
		return NpcModule.CreateResult.new(Result.failure(NpcModule.CODE_NOT_READY, "NpcModule.request_create_npc: definições de necessidades inválidas: %s." % _defs_problem), IdGenerator.NO_ID)
	var problem: String = _spec_problem(spec)
	if not problem.is_empty():
		return NpcModule.CreateResult.new(Result.failure(NpcModule.CODE_INVALID_SPEC, "NpcModule.request_create_npc: pedido inválido: %s." % problem), IdGenerator.NO_ID)
	if spec.tier == NpcState.TIER_NOTABLE and not NpcTiers.has_room(NpcTiers.count_notable_alive(_npcs), _notables.max_notable()):
		return NpcModule.CreateResult.new(Result.failure(NpcTiers.CODE_T2_LIMIT_REACHED, "NpcModule.request_create_npc: já há %d NPC(s) notável(is) vivo(s) e o teto (max_t2) é %d; esperado um pedido com tier %d ou uma vaga livre." % [NpcTiers.count_notable_alive(_npcs), _notables.max_notable(), NpcState.TIER_NORMAL]), IdGenerator.NO_ID)
	var npc_id: int = _ctx.ids.next_id()
	if npc_id == IdGenerator.NO_ID:
		return NpcModule.CreateResult.new(Result.failure(NpcModule.CODE_NO_ID, "NpcModule.request_create_npc: o contador de IDs esgotou; não há ID novo."), IdGenerator.NO_ID)
	if _npcs.has(npc_id):
		return NpcModule.CreateResult.new(Result.failure(NpcModule.CODE_DUPLICATE_ID, "NpcModule.request_create_npc: o ID novo %d já pertence a um NPC (save inconsistente); nada foi sobrescrito." % npc_id), IdGenerator.NO_ID)
	var created: NpcState = NpcState.from_spec(npc_id, spec, _ctx.clock.total_minutes(), _start_needs())
	created.next_think_time = _first_think_time(npc_id, _ctx.clock.total_minutes())
	_npcs[npc_id] = created
	_open_account(npc_id, spec.work_place_id)
	return NpcModule.CreateResult.new(Result.success(), npc_id)


## A conta do NPC na economia (LW-093; DEC-145): `request_open_owner(npc_id, "npc", work_place_id)`, que também atribui o NPC ao local de produção do `work_place_id`, se houver. Sem economia não há conta. Falha visível (`push_error`), sem desfazer a criação.
func _open_account(npc_id: int, work_place_id: String) -> void:
	if _economy == null:
		return
	var opened: Result = _economy.request_open_owner(npc_id, EconomyModule.KIND_NPC, work_place_id)
	if not opened.ok:
		push_error("NpcLifecycle.create: a conta do NPC %d não abriu na economia: %s" % [npc_id, opened.message])


## Remove o NPC da tabela. O ID não volta: o contador do core só sobe.
func remove(npc_id: int) -> Result:
	if not _npcs.has(npc_id):
		var failure: Result = _unknown.call("request_remove_npc", npc_id)
		return failure
	_npcs.erase(npc_id)
	_notables.forget(npc_id)
	_tracer.forget(npc_id)
	return Result.success()


## Morte por necessidade crítica prolongada (LW-081): o NPC deixa de estar vivo (`is_alive` falso, causa e minuto guardados), a ação é cancelada
## SEM efeito, o local é liberado (a ocupação é derivada dos vivos; `place_id` fica vazio) e `NpcDied(npc_id, cause, tier)` é publicado. Fica só a
## identidade e a causa, para quem guarda o ID (as memórias e relações dele, LW-078 e LW-079, são descartadas aqui).
func kill(npc_id: int, cause: String, now: int) -> void:
	if not _npcs.has(npc_id):
		return
	var state: NpcState = _npcs[npc_id]
	if not state.is_alive:
		return
	state.is_alive = false
	state.death_cause = cause
	state.died_at = now
	state.action_id = ""
	state.action_target_place_id = ""
	state.action_started_at = 0
	state.action_ends_at = 0
	state.place_id = ""
	state.critical_since = NpcState.NO_TIME
	state.alarm_until = NpcState.NO_TIME
	state.alarm_place_id = ""
	_notables.forget(npc_id)
	_ctx.events.publish(NpcDied.new(npc_id, cause, state.tier))


## Minuto do primeiro pensamento: agora mais 1 mais a FASE do NPC (`npc_id` mod intervalo), para os NPCs criados juntos não pensarem todos
## no mesmo passo. O "mais 1" faz o primeiro pensamento cair sempre DEPOIS do minuto da criação (não depende de o módulo já ter rodado
## neste passo) e põe as fases em minutos distintos de 1 a `intervalo` (sem fase no minuto da criação, duas fases não se juntam no
## primeiro passo). Sem parâmetros: agora.
func _first_think_time(npc_id: int, now: int) -> int:
	if _definitions == null or _definitions.params == null:
		return now
	return now + 1 + npc_id % maxi(1, _definitions.params.think_interval_min)


## Valor inicial das necessidades: o `start_value` de cada definição; sem definições, tudo zero.
func _start_needs() -> PackedInt64Array:
	var needs: PackedInt64Array = PackedInt64Array()
	needs.resize(NpcState.NEED_COUNT)
	if not _need_defs.is_empty():
		for def: NeedDef in _need_defs:
			needs[def.order] = def.start_value
	return needs


## Primeiro problema do pedido de criação (texto vazio se estiver certo).
func _spec_problem(spec: NpcSpec) -> String:
	if spec == null:
		return "pedido nulo; esperado um NpcSpec"
	if spec.name_key.strip_edges().is_empty():
		return "name_key vazia; esperado a chave de texto do nome"
	if spec.name_number < 0:
		return "name_number %d negativo; esperado 0 ou mais" % spec.name_number
	if spec.tier != NpcState.TIER_NORMAL and spec.tier != NpcState.TIER_NOTABLE:
		return "tier %d inválido; esperado %d ou %d" % [spec.tier, NpcState.TIER_NORMAL, NpcState.TIER_NOTABLE]
	if spec.traits.size() != NpcState.TRAIT_COUNT:
		return "traits com %d valores; esperado %d (um por traço)" % [spec.traits.size(), NpcState.TRAIT_COUNT]
	for index: int in spec.traits.size():
		if spec.traits[index] < NpcState.VALUE_MIN or spec.traits[index] > NpcState.VALUE_MAX:
			return "traço na posição %d com valor %d; esperado de %d a %d" % [index, spec.traits[index], NpcState.VALUE_MIN, NpcState.VALUE_MAX]
	if spec.x_cm < 0 or spec.x_cm > NpcState.MAX_COORDINATE_CM or spec.z_cm < 0 or spec.z_cm > NpcState.MAX_COORDINATE_CM:
		return "posição (x_cm %d, z_cm %d) fora da faixa; esperado de 0 a %d" % [spec.x_cm, spec.z_cm, NpcState.MAX_COORDINATE_CM]
	if _routine != null and not spec.occupation_id.is_empty() and not _routine.has_occupation(spec.occupation_id):
		return "ofício '%s' inexistente; esperado vazio ou um de: %s" % [spec.occupation_id, ", ".join(_routine.peek_occupation_ids())]
	return ""
