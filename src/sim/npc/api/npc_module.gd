class_name NpcModule
extends SimModule
## Módulo `npc` (camada 3; contrato em docs/modules/npc.md). LW-057: tabela de NPCs indexada por npc_id (um NpcState por NPC), criar e
## remover com IDs de ctx.ids que nunca voltam, salvar e carregar, validate e debug_summary. O módulo entra no World e, pelo
## serialize(), no state_hash. LW-058: as definições das necessidades (NeedDef, lidas de data/needs.json por quem monta o módulo)
## entram pelo CONSTRUTOR, sem global nem autoload; sem elas (padrão) os NPCs nascem com tudo em zero e sem urgência. Ainda NÃO
## decide, anda nem tem LOD: isso é das tarefas seguintes. LW-061: a tabela de rotina (RoutineTable, de data/occupations.json e
## data/routine_blocks.json) também entra pelo construtor: `peek_routine_action` e a conferência do ofício. LW-063: com o objeto
## `Definitions` (catálogo, traços, parâmetros, serviço de locais e, opcional, o provedor de comida) o módulo DECIDE: `tick` roda a fila de
## pensamento (NpcThinker) e toda ação começa pela função única `_start_action` (ponto de extensão do modo S0, LW-070). Sem `Definitions`
## (padrão) o `tick` não faz nada. Dependências: só core, `world` e a própria pasta; não importa o `character`.

const CODE_NOT_READY: String = "NPC_NOT_READY"
const CODE_UNKNOWN: String = "NPC_UNKNOWN"
const CODE_INVALID_SPEC: String = "NPC_INVALID_SPEC"
const CODE_INVALID_SAVE: String = "NPC_INVALID_SAVE"
const CODE_NO_ID: String = "NPC_NO_ID"
const CODE_DUPLICATE_ID: String = "NPC_DUPLICATE_ID"
const CODE_ROUTINE_NOT_CONFIGURED: String = "NPC_ROUTINE_NOT_CONFIGURED"
## Comandos que só existem em build de desenvolvimento (a flag vem em `Definitions.is_development_build`).
const CODE_DEV_ONLY: String = "NPC_DEV_ONLY"
## TEMP-LW-065: sem FoodStub nas definições não há estoque de comida.
const CODE_FOOD_NOT_CONFIGURED: String = "NPC_FOOD_NOT_CONFIGURED"
const KEY_NPCS: String = "npcs"
## Chaves de peek_counts().
const COUNT_TOTAL: String = "total"
const COUNT_ALIVE: String = "alive"
const COUNT_DEAD: String = "dead"
const COUNT_TIER_NORMAL: String = "tier_1"
const COUNT_TIER_NOTABLE: String = "tier_2"
## Rótulo, no resumo de depuração, de quem não tem ofício.
const NO_OCCUPATION_LABEL: String = "none"

var _ctx: SimContext
var _need_defs: Array[NeedDef] = []
## Motivo de as definições não servirem (vazio = servem, ou não foram dadas). Conferido uma vez, no construtor.
var _defs_problem: String = ""
var _routine: RoutineTable
var _definitions: Definitions
## Fluxo de decisão (LW-063): montado no primeiro `tick`, só se as definições estão completas. `_decision_problem` diz por que não.
var _decision_checked: bool = false
var _decision_problem: String = ""
## Por que a população inicial não nasceu (vazio = nasceu, ou não havia plano). Não é salvo: só aparece no debug_summary().
var _population_problem: String = ""
## Rastro de decisão dos NPCs marcados (LW-064): só para olhar, não é salvo nem entra no hash.
var _tracer: DecisionTracer = DecisionTracer.new()
var _runner: ActionRunner
var _provider: NpcThinker.ConditionProvider
var _thinker: NpcThinker
## A tabela é UMA só e vive o tempo todo do módulo: o runner, a ocupação e o pensador a recebem por referência (on_load a atualiza no lugar).
var _npcs: Dictionary[int, NpcState] = {}


## `need_defs`: uma definição por posição, na ordem de `order` (como NeedLoader as entrega). Vazio = sem necessidades configuradas.
## `routine`: ofícios e agenda por hora (RoutineLoader); nulo = sem rotina configurada (o ofício do NPC fica como texto sem conferência).
## `definitions`: o que falta para o módulo DECIDIR (LW-063); nulo = o módulo só guarda estado e o `tick` não faz nada.
func _init(need_defs: Array[NeedDef] = [], routine: RoutineTable = null, definitions: Definitions = null) -> void:
	_need_defs = need_defs
	_routine = routine
	_definitions = definitions
	_defs_problem = "" if need_defs.is_empty() else NeedMath.definitions_problem(need_defs)


func setup(ctx: SimContext) -> void:
	_ctx = ctx


## Cria um NPC (ID novo de ctx.ids). Confere o pedido inteiro ANTES de gastar um ID: pedido recusado não altera nada.
func request_create_npc(spec: NpcSpec) -> CreateResult:
	if _ctx == null:
		return CreateResult.new(Result.failure(CODE_NOT_READY, "NpcModule.request_create_npc: módulo sem setup() (sem relógio nem IDs); esperado um módulo registrado no World."), IdGenerator.NO_ID)
	if not _defs_problem.is_empty():
		return CreateResult.new(Result.failure(CODE_NOT_READY, "NpcModule.request_create_npc: definições de necessidades inválidas: %s." % _defs_problem), IdGenerator.NO_ID)
	var problem: String = _spec_problem(spec)
	if not problem.is_empty():
		return CreateResult.new(Result.failure(CODE_INVALID_SPEC, "NpcModule.request_create_npc: pedido inválido: %s." % problem), IdGenerator.NO_ID)
	var npc_id: int = _ctx.ids.next_id()
	if npc_id == IdGenerator.NO_ID:
		return CreateResult.new(Result.failure(CODE_NO_ID, "NpcModule.request_create_npc: o contador de IDs esgotou; não há ID novo."), IdGenerator.NO_ID)
	if _npcs.has(npc_id):
		return CreateResult.new(Result.failure(CODE_DUPLICATE_ID, "NpcModule.request_create_npc: o ID novo %d já pertence a um NPC (save inconsistente); nada foi sobrescrito." % npc_id), IdGenerator.NO_ID)
	var created: NpcState = NpcState.from_spec(npc_id, spec, _ctx.clock.total_minutes(), _start_needs())
	created.next_think_time = _first_think_time(npc_id, _ctx.clock.total_minutes())
	_npcs[npc_id] = created
	return CreateResult.new(Result.success(), npc_id)


## Remove o NPC da tabela. O ID não volta: o contador do core só sobe.
func request_remove_npc(npc_id: int) -> Result:
	if not _npcs.has(npc_id):
		return _unknown("request_remove_npc", npc_id)
	_npcs.erase(npc_id)
	_tracer.forget(npc_id)
	return Result.success()


## Resumo do NPC, em CÓPIA. ID inexistente devolve falha tratada, nunca derruba o jogo.
func peek_npc(npc_id: int) -> NpcQuery:
	if not _npcs.has(npc_id):
		return NpcQuery.new(_unknown("peek_npc", npc_id), null)
	var state: NpcState = _npcs[npc_id]
	var query: NpcQuery = NpcQuery.new(Result.success(), state)
	query.need_urgencies = _urgencies_of(state)
	return query


## Marca ou desmarca o NPC para o rastro de decisão (LW-064). SÓ em build de desenvolvimento (`Definitions.is_development_build`); fora dele,
## `NPC_DEV_ONLY` e nada muda. NPC inexistente: falha tratada. Desmarcar apaga o rastro.
func request_set_traced(npc_id: int, is_traced: bool) -> Result:
	if _definitions == null or not _definitions.is_development_build:
		return Result.failure(CODE_DEV_ONLY, "NpcModule.request_set_traced: comando só existe em build de desenvolvimento (Definitions.is_development_build).")
	if not _npcs.has(npc_id):
		return _unknown("request_set_traced", npc_id)
	_tracer.set_traced(npc_id, is_traced)
	return Result.success()


## Os últimos pensamentos do NPC MARCADO: necessidades, todas as candidatas com cada parcela da pontuação, a ação escolhida e o motivo
## (cópias; o mais antigo primeiro). NPC não marcado: `NPC_NOT_TRACED`; NPC inexistente: `NPC_UNKNOWN`.
func explain_decision(npc_id: int) -> DecisionTracer.Explanation:
	if not _npcs.has(npc_id):
		return DecisionTracer.Explanation.new(_unknown("explain_decision", npc_id), [])
	return _tracer.explain(npc_id)


## IDs dos NPCs em ordem crescente.
func peek_npc_ids() -> Array[int]:
	return _sorted_ids()


## Jogo novo (LW-067): cria a população inicial do plano de `Definitions.population`, em ordem fixa, com os traços sorteados no fluxo
## `npc.population` do ctx.rng. Sem plano (o padrão dos testes) não cria ninguém. Plano que não fecha (assentamento ou ofício inexistente,
## falta de casa ou de local de trabalho com vaga) é erro de DADO: nenhum NPC nasce, `push_error` diz o motivo e o `debug_summary()` o repete.
func on_new_game(_world_seed: int) -> void:
	if _definitions == null or _definitions.population == null or _ctx == null:
		return
	if _routine == null or _definitions.places == null:
		_report_population_problem("faltam a tabela de rotina ou o serviço de locais do `world`")
		return
	var built: PopulationPlan.BuildResult = _definitions.population.build_specs(_definitions.places, _routine, _ctx.rng)
	if not built.result.ok:
		_report_population_problem(built.result.message)
		return
	for spec: NpcSpec in built.specs:
		var created: CreateResult = request_create_npc(spec)
		if not created.result.ok:
			_report_population_problem(created.result.message)
			return


## A cada passo: a fila de pensamento (LW-063). Quem chegou no seu `next_think_time` pensa, até `max_thinks_per_step` por passo.
func tick(_elapsed_minutes: int) -> void:
	if _definitions == null or _ctx == null or not _ensure_thinker():
		return
	_thinker.run_step(_ctx.clock.total_minutes())


## A ação da rotina do ofício na hora (0 a 23, a de SimClock.hour_of_day()). Sem rotina configurada, ofício desconhecido ou hora fora de
## 0 a 23: falha tratada. A rotina diz só o QUÊ; o local vem do PlaceChooser.
func peek_routine_action(occupation_id: String, hour: int) -> RoutineTable.RoutineQuery:
	if _routine == null:
		return RoutineTable.RoutineQuery.new(Result.failure(CODE_ROUTINE_NOT_CONFIGURED, "NpcModule.peek_routine_action: o módulo foi criado sem tabela de rotina."), "")
	return _routine.peek_action(occupation_id, hour)


## TEMP-LW-065: estoque de comida do assentamento. Sem FoodStub nas definições, ou assentamento sem regra: falha tratada.
func peek_food_stock(settlement_id: String) -> FoodStub.StockQuery:
	var food_stub: FoodStub = _food_stub()
	if food_stub == null:
		return FoodStub.StockQuery.new(_food_not_configured("peek_food_stock"), 0, 0)
	return food_stub.peek_stock(settlement_id)


## TEMP-LW-065: define o estoque de comida (de 0 ao teto). SÓ em build de desenvolvimento; fora dele, `NPC_DEV_ONLY` e nada muda.
func request_set_food_stock(settlement_id: String, amount: int) -> Result:
	if _definitions == null or not _definitions.is_development_build:
		return Result.failure(CODE_DEV_ONLY, "NpcModule.request_set_food_stock: comando só existe em build de desenvolvimento (Definitions.is_development_build).")
	var food_stub: FoodStub = _food_stub()
	if food_stub == null:
		return _food_not_configured("request_set_food_stock")
	return food_stub.request_set_stock(settlement_id, amount)


## Contagens (chaves COUNT_*): total, vivos, mortos e por tier.
func peek_counts() -> Dictionary:
	var counts: Dictionary = {COUNT_TOTAL: _npcs.size(), COUNT_ALIVE: 0, COUNT_DEAD: 0, COUNT_TIER_NORMAL: 0, COUNT_TIER_NOTABLE: 0}
	for npc_id: int in _sorted_ids():
		var state: NpcState = _npcs[npc_id]
		counts[COUNT_ALIVE if state.is_alive else COUNT_DEAD] += 1
		if state.tier == NpcState.TIER_NORMAL:
			counts[COUNT_TIER_NORMAL] += 1
		elif state.tier == NpcState.TIER_NOTABLE:
			counts[COUNT_TIER_NOTABLE] += 1
	return counts


## IDs viram texto (assim o JSON guarda chaves) e entram em ordem crescente do número.
func serialize() -> Dictionary:
	var saved: Dictionary = {}
	for npc_id: int in _sorted_ids():
		saved[str(npc_id)] = _npcs[npc_id].to_dict()
	var data: Dictionary = {KEY_NPCS: saved}
	var food_stub: FoodStub = _food_stub()
	if food_stub != null:
		data[FoodStub.SAVE_KEY] = food_stub.serialize()
	return data


## Confere tudo antes de alterar o estado: se algo for inválido, o estado fica como estava. Só recusa o que não dá para converter
## (estrutura, tipos, chave de ID); faixas e coerência ficam com validate() (mesmo critério do `character`).
func on_load(data: Dictionary) -> Result:
	# Variant: valor cru do save (JSON); o tipo é conferido na linha seguinte.
	var raw_npcs: Variant = data.get(KEY_NPCS)
	if typeof(raw_npcs) != TYPE_DICTIONARY:
		return _invalid_save("campo '%s' ausente ou não é um objeto (veio %s)" % [KEY_NPCS, type_string(typeof(raw_npcs))])
	var entries: Dictionary = raw_npcs
	var keys: Array = entries.keys()
	keys.sort()
	var loaded: Dictionary[int, NpcState] = {}
	for key: Variant in keys:
		var npc_id: int = _read_npc_id(str(key))
		if npc_id == IdGenerator.NO_ID:
			return _invalid_save("chave de NPC '%s' inválida; esperado um inteiro de %d a %d" % [str(key), IdGenerator.FIRST_ID, IdGenerator.MAX_ID])
		if loaded.has(npc_id):
			return _invalid_save("o NPC %d aparece duas vezes (chave '%s')" % [npc_id, str(key)])
		var parsed: NpcState.ParseResult = NpcState.parse(npc_id, entries[key])
		if parsed.state == null:
			return _invalid_save("NPC %d: %s" % [npc_id, parsed.error])
		loaded[npc_id] = parsed.state
	var stock_problem: String = _food_stock_save_problem(data)
	if not stock_problem.is_empty():
		return _invalid_save(stock_problem)
	_npcs.clear()
	for loaded_id: int in loaded:
		_npcs[loaded_id] = loaded[loaded_id]
	_load_food_stock(data)
	_tracer.clear()
	return Result.success()


## Problemas do estado (lista vazia se estiver tudo certo). O ofício é conferido contra a tabela de rotina quando o módulo a tem (LW-061);
## local e ação ficam como texto: cada tarefa futura acrescenta a sua conferência.
func validate() -> Array[String]:
	var problems: Array[String] = []
	if not _defs_problem.is_empty():
		problems.append("Definições de necessidades inválidas: %s." % _defs_problem)
	var next_id: int = _next_issued_id()
	for npc_id: int in _sorted_ids():
		var state: NpcState = _npcs[npc_id]
		if npc_id < IdGenerator.FIRST_ID or npc_id > IdGenerator.MAX_ID:
			problems.append("NPC %d: ID fora da faixa [%d, %d]." % [npc_id, IdGenerator.FIRST_ID, IdGenerator.MAX_ID])
		elif _ctx != null and npc_id >= next_id:
			problems.append("NPC %d: ID acima do contador do core (o próximo ID a sair é %d); esse ID nunca foi emitido." % [npc_id, next_id])
		if state.tier != NpcState.TIER_NORMAL and state.tier != NpcState.TIER_NOTABLE:
			problems.append("NPC %d: tier %d inválido; esperado %d ou %d." % [npc_id, state.tier, NpcState.TIER_NORMAL, NpcState.TIER_NOTABLE])
		_append_range_problems(problems, npc_id, "necessidade", state.need_values, NpcState.VALUE_MIN, NpcState.VALUE_MAX)
		_append_range_problems(problems, npc_id, "resto de necessidade", state.need_remainders, 0, NeedMath.MAX_REMAINDER)
		_append_range_problems(problems, npc_id, "traço", state.traits, NpcState.VALUE_MIN, NpcState.VALUE_MAX)
		if not state.is_alive and not state.action_id.is_empty():
			problems.append("NPC %d: morto, mas com ação atual '%s'; esperado nenhuma." % [npc_id, state.action_id])
		if state.next_think_time < 0:
			problems.append("NPC %d: next_think_time %d negativo; esperado 0 ou mais." % [npc_id, state.next_think_time])
		if state.critical_since < NpcState.NO_TIME:
			problems.append("NPC %d: critical_since %d inválido; esperado %d (nenhuma) ou um minuto de 0 em diante." % [npc_id, state.critical_since, NpcState.NO_TIME])
		if not state.is_alive and state.critical_since != NpcState.NO_TIME:
			problems.append("NPC %d: morto, mas com critical_since %d; esperado %d." % [npc_id, state.critical_since, NpcState.NO_TIME])
		if _routine != null and not state.occupation_id.is_empty() and not _routine.has_occupation(state.occupation_id):
			problems.append("NPC %d: ofício '%s' inexistente nos dados de ofícios." % [npc_id, state.occupation_id])
	var food_stub: FoodStub = _food_stub()
	if food_stub != null:
		problems.append_array(food_stub.validate())
	return problems


## Contagens por tier, vivos e mortos, ofícios e o tamanho em bytes do serialize() (backlog I4). Só para depuração.
func debug_summary() -> Dictionary:
	var summary: Dictionary = peek_counts()
	var by_occupation: Dictionary = {}
	for npc_id: int in _sorted_ids():
		var occupation: String = _npcs[npc_id].occupation_id
		var label: String = occupation if not occupation.is_empty() else NO_OCCUPATION_LABEL
		by_occupation[label] = int(by_occupation.get(label, 0)) + 1
	var sorted_labels: Array = by_occupation.keys()
	sorted_labels.sort()
	var ordered: Dictionary = {}
	for label: Variant in sorted_labels:
		ordered[label] = by_occupation[label]
	summary["by_occupation"] = ordered
	summary["serialize_bytes"] = JSON.stringify(serialize()).to_utf8_buffer().size()
	var food_stub: FoodStub = _food_stub()
	if food_stub != null:
		summary["food_stock"] = food_stub.serialize()
	summary["population_problem"] = _population_problem
	summary["traced_npcs"] = _tracer.traced_count()
	summary["trace_records_made"] = _tracer.records_made
	summary["decision_problem"] = _decision_problem_text()
	summary["decision_enabled"] = _thinker != null
	summary["thinks_last_step"] = _thinker.last_step_thinks if _thinker != null else 0
	summary["max_thinks_in_a_step"] = _thinker.max_step_thinks if _thinker != null else 0
	return summary


## Por que o módulo não decide (texto vazio = decide): sem `Definitions`, sem setup() ou com definições incompletas ou inválidas. Aparece no
## debug_summary(), para o módulo nunca ficar parado em silêncio.
func _decision_problem_text() -> String:
	if _definitions == null:
		return "o módulo foi criado sem as definições para decidir (NpcModule.Definitions)"
	if _thinker != null:
		return ""
	if _ctx == null:
		return "módulo sem setup()"
	_ensure_thinker()
	return _decision_problem


## Monta o runner, o pontuador e o pensador na primeira vez que o `tick` roda. Falso (e `_decision_problem` preenchido) se faltar algo.
func _ensure_thinker() -> bool:
	if _thinker != null:
		return true
	if _decision_checked:
		return false
	_decision_checked = true
	_decision_problem = _build_decision_runtime()
	return _decision_problem.is_empty()


## Texto vazio = montou; senão, o que falta ou está inválido.
func _build_decision_runtime() -> String:
	if _need_defs.is_empty() or not _defs_problem.is_empty():
		return "faltam as definições de necessidades (ou estão inválidas)"
	if _routine == null:
		return "falta a tabela de rotina"
	if _definitions.actions.is_empty():
		return "falta o catálogo de ações"
	if _definitions.params == null:
		return "faltam os parâmetros do `npc` (npc_params.json)"
	if _definitions.places == null:
		return "falta o serviço de locais do `world`"
	var food_stub: FoodStub = _food_stub()
	if food_stub != null:
		var food_problem: String = food_stub.check_references(_definitions.places, _routine.peek_occupation_ids())
		if not food_problem.is_empty():
			return "FoodStub (TEMP-LW-065): %s" % food_problem
	if _definitions.income != null:
		var need_ids: Array[String] = []
		for def: NeedDef in _need_defs:
			need_ids.append(def.id)
		var income_problem: String = _definitions.income.check_references(need_ids, _routine.peek_occupation_ids())
		if not income_problem.is_empty():
			return "IncomeStub (TEMP-LW-066): %s" % income_problem
	var occupancy: PlaceOccupancy = PlaceOccupancy.new(_npcs)
	var provider: NpcThinker.ConditionProvider = NpcThinker.ConditionProvider.new(_definitions.places, occupancy, _definitions.food, _definitions.income)
	var runner: ActionRunner = ActionRunner.new(_npcs, _definitions.actions, _need_defs, _definitions.places, provider, _definitions.walk_speed_cm_per_min)
	if not runner.peek_problem().is_empty():
		return "ActionRunner: %s" % runner.peek_problem()
	var scorer: UtilityScorer = UtilityScorer.new(_definitions.params, _need_defs, _definitions.traits)
	if not scorer.peek_problem().is_empty():
		return "UtilityScorer: %s" % scorer.peek_problem()
	_provider = provider
	_runner = runner
	_thinker = NpcThinker.new(_ctx, _npcs, runner, scorer, PlaceChooser.new(_definitions.places, occupancy), provider, _routine, _definitions.params, _need_defs, _definitions.actions, _definitions.places, _start_action, _tracer, _kill_npc)
	return ""


## A ÚNICA função que inicia uma ação (LW-063): hoje só o modo S1, pelo ActionRunner. Ponto de extensão do modo S0: a LW-070 acrescenta
## aqui o ramo que, para NPC com corpo, emite a Intent em vez de começar a ação abstrata.
func _start_action(npc_id: int, action_id: String, place_id: String, now: int) -> Result:
	_provider.subject = _npcs.get(npc_id)
	return _runner.begin(npc_id, action_id, place_id, now)


## Morte por necessidade crítica prolongada (LW-081): o NPC deixa de estar vivo (`is_alive` falso, causa e minuto guardados), a ação é cancelada
## SEM efeito, o local é liberado (a ocupação é derivada dos vivos; `place_id` fica vazio) e `NpcDied(npc_id, cause, tier)` é publicado. Fica só a
## identidade e a causa, para quem guarda o ID (as memórias e relações dele, LW-078 e LW-079, serão descartadas aqui quando existirem).
func _kill_npc(npc_id: int, cause: String, now: int) -> void:
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
	_ctx.events.publish(NpcDied.new(npc_id, cause, state.tier))


## Minuto do primeiro pensamento: agora mais 1 mais a FASE do NPC (`npc_id` mod intervalo), para os NPCs criados juntos não pensarem todos
## no mesmo passo. O "mais 1" faz o primeiro pensamento cair sempre DEPOIS do minuto da criação (não depende de o módulo já ter rodado
## neste passo) e põe as fases em minutos distintos de 1 a `intervalo` (sem fase no minuto da criação, duas fases não se juntam no
## primeiro passo). Sem parâmetros: agora.
func _first_think_time(npc_id: int, now: int) -> int:
	if _definitions == null or _definitions.params == null:
		return now
	return now + 1 + npc_id % maxi(1, _definitions.params.think_interval_min)


## TEMP-LW-065: o FoodStub real, se o provedor de comida das definições for ele (os testes usam um provedor falso, sem estado salvo).
func _food_stub() -> FoodStub:
	if _definitions == null:
		return null
	return _definitions.food as FoodStub


## TEMP-LW-065
func _food_not_configured(caller: String) -> Result:
	return Result.failure(CODE_FOOD_NOT_CONFIGURED, "NpcModule.%s: o módulo foi criado sem FoodStub; não há estoque de comida." % caller)


## TEMP-LW-065: problema do trecho de comida do save (texto vazio = pode carregar). Save sem o trecho (de antes do FoodStub) é aceito: o
## estoque volta ao inicial. Trecho de comida num módulo sem FoodStub é recusado.
func _food_stock_save_problem(data: Dictionary) -> String:
	if not data.has(FoodStub.SAVE_KEY):
		return ""
	var food_stub: FoodStub = _food_stub()
	if food_stub == null:
		return "o save tem estoque de comida ('%s'), mas o módulo foi criado sem FoodStub" % FoodStub.SAVE_KEY
	return food_stub.check_save(data[FoodStub.SAVE_KEY])


## TEMP-LW-065: carrega o estoque já conferido (ou o devolve ao inicial se o save não tem o trecho).
func _load_food_stock(data: Dictionary) -> void:
	var food_stub: FoodStub = _food_stub()
	if food_stub == null:
		return
	if data.has(FoodStub.SAVE_KEY):
		var entries: Dictionary = data[FoodStub.SAVE_KEY]
		food_stub.load_save(entries)
	else:
		food_stub.reset_to_start()


## A população inicial não nasceu (ou parou no meio): guarda o motivo e o registra no log, para o erro de dado nunca passar em silêncio.
func _report_population_problem(detail: String) -> void:
	_population_problem = detail
	push_error("NpcModule.on_new_game: população inicial não criada: %s" % detail)


## Nunca visitar o Dictionary pela ordem natural (muda depois de carregar um save).
func _sorted_ids() -> Array[int]:
	var ids: Array[int] = []
	ids.assign(_npcs.keys())
	ids.sort()
	return ids


## Valor inicial das necessidades: o `start_value` de cada definição; sem definições, tudo zero.
func _start_needs() -> PackedInt64Array:
	var needs: PackedInt64Array = PackedInt64Array()
	needs.resize(NpcState.NEED_COUNT)
	if not _need_defs.is_empty():
		for def: NeedDef in _need_defs:
			needs[def.order] = def.start_value
	return needs


## Nível de urgência de cada necessidade do NPC, pelos limiares dos dados. Sem definições, tudo 0 (não há limiares para comparar).
func _urgencies_of(state: NpcState) -> PackedInt64Array:
	var urgencies: PackedInt64Array = PackedInt64Array()
	urgencies.resize(NpcState.NEED_COUNT)
	if _need_defs.is_empty() or not _defs_problem.is_empty():
		return urgencies
	for def: NeedDef in _need_defs:
		urgencies[def.order] = NeedMath.urgency(state.need_values[def.order], def)
	return urgencies


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


func _append_range_problems(problems: Array[String], npc_id: int, what: String, values: PackedInt64Array, lowest: int, highest: int) -> void:
	for index: int in values.size():
		if values[index] < lowest or values[index] > highest:
			problems.append("NPC %d: %s na posição %d fora de %d a %d (valor %d)." % [npc_id, what, index, lowest, highest, values[index]])


## Próximo ID que o contador do core entregaria (0 se o módulo ainda não passou por setup()).
func _next_issued_id() -> int:
	if _ctx == null:
		return IdGenerator.NO_ID
	# Variant: o contador sai do serialize() do core, que é dado simples.
	var raw_next: Variant = _ctx.ids.serialize()[IdGenerator.KEY_NEXT_ID]
	var next_id: int = raw_next
	return next_id


func _unknown(caller: String, npc_id: int) -> Result:
	return Result.failure(CODE_UNKNOWN, "NpcModule.%s: o NPC %d não existe; esperado um ID devolvido por request_create_npc (há %d NPC(s))." % [caller, npc_id, _npcs.size()])


func _invalid_save(detail: String) -> Result:
	return Result.failure(CODE_INVALID_SAVE, "NpcModule.on_load: %s." % detail)


## ID de NPC a partir do texto da chave; NO_ID se não for um inteiro na faixa válida.
func _read_npc_id(key_text: String) -> int:
	if not key_text.is_valid_int():
		return IdGenerator.NO_ID
	var value: int = key_text.to_int()
	return value if value >= IdGenerator.FIRST_ID and value <= IdGenerator.MAX_ID else IdGenerator.NO_ID


## O que o módulo precisa, além das necessidades e da rotina, para DECIDIR (LW-063). Tudo já lido e validado por quem monta o módulo (os
## carregadores), sem global nem autoload. Cada tarefa seguinte acrescenta aqui o que for dela, em vez de crescer o construtor.
class Definitions:
	extends RefCounted

	var actions: Array[ActionDef] = []
	## Os quatro traços, na ordem de `order` (TraitLoader).
	var traits: Array[TraitLoader.TraitDef] = []
	var params: NpcParams
	## Serviço de consultas de assentamentos e locais do `world` (conteúdo, fora do save).
	var places: SettlementService
	## Opcional: responde `has_food`. Sem ele nenhuma ação que exija comida começa. Em produção é o FoodStub (TEMP-LW-065), com estoque salvo
	## junto com o módulo; os testes de decisão podem pôr um provedor falso, sem estado.
	var food: ActionConditionProvider
	## Opcional (TEMP-LW-066): a renda simbólica de quem trabalha (IncomeStub). Sem ele o trabalho não alivia a necessidade `income`.
	var income: IncomeStub
	## Opcional (LW-067): quantos NPCs de cada ofício nascem em cada assentamento. Sem ele `on_new_game` não cria ninguém.
	var population: PopulationPlan
	var walk_speed_cm_per_min: int = ActionRunner.DEFAULT_WALK_SPEED_CM_PER_MIN
	## Build de desenvolvimento? Só então valem os comandos de depuração do módulo (hoje `request_set_food_stock`). A fronteira do app lê
	## `OS.is_debug_build()` e entrega aqui; a simulação não lê `OS`. Padrão falso.
	var is_development_build: bool = false


## Resultado de `request_create_npc`: `npc_id` só vale se `result.ok` (mesmo padrão do SpawnResult do `character`).
class CreateResult:
	extends RefCounted

	var result: Result
	var npc_id: int

	func _init(create_result: Result, new_npc_id: int) -> void:
		result = create_result
		npc_id = new_npc_id


## Resumo devolvido por `peek_npc`: `result.ok` diz se deu certo; só então os campos valem. São CÓPIAS dos valores do estado.
class NpcQuery:
	extends RefCounted

	var result: Result
	var npc_id: int = 0
	var name_key: String = ""
	var name_number: int = 0
	var tier: int = 0
	var is_alive: bool = false
	var death_cause: String = ""
	var traits: PackedInt64Array = PackedInt64Array()
	var need_values: PackedInt64Array = PackedInt64Array()
	## Urgência (0 a 3) de cada necessidade pelos limiares dos dados; tudo 0 se o módulo não tem definições.
	var need_urgencies: PackedInt64Array = PackedInt64Array()
	var needs_updated_at: int = 0
	var x_cm: int = 0
	var z_cm: int = 0
	var settlement_id: String = ""
	var place_id: String = ""
	var occupation_id: String = ""
	var home_place_id: String = ""
	var work_place_id: String = ""
	var action_id: String = ""
	var action_target_place_id: String = ""
	var action_started_at: int = 0
	var action_ends_at: int = 0
	var action_serial: int = 0
	var next_think_time: int = 0

	func _init(query_result: Result, state: NpcState) -> void:
		result = query_result
		if state == null:
			return
		npc_id = state.npc_id
		name_key = state.name_key
		name_number = state.name_number
		tier = state.tier
		is_alive = state.is_alive
		death_cause = state.death_cause
		traits = state.traits.duplicate()
		need_values = state.need_values.duplicate()
		needs_updated_at = state.needs_updated_at
		x_cm = state.x_cm
		z_cm = state.z_cm
		settlement_id = state.settlement_id
		place_id = state.place_id
		occupation_id = state.occupation_id
		home_place_id = state.home_place_id
		work_place_id = state.work_place_id
		action_id = state.action_id
		action_target_place_id = state.action_target_place_id
		action_started_at = state.action_started_at
		action_ends_at = state.action_ends_at
		action_serial = state.action_serial
		next_think_time = state.next_think_time
