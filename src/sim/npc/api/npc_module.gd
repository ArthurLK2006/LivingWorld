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
## (padrão) o `tick` não faz nada. LW-077: `request_promote` e `request_demote` (NpcTiers) mudam o tier entre T1 e T2 com teto global `max_t2`.
## LW-078: memória dos notáveis (`NpcMemory`, uma por NPC T2, salva junto): `peek_memories`, gravação por `NpcNotables.record_memory`, descarte na morte e
## resumo em traços ao rebaixar. LW-079: relações entre pessoas (`RelationGraph`, uma por par, salva junto): `peek_opinion`, ajuste por
## `NpcNotables.adjust_relation`, descarte na morte e arrumação ao rebaixar. LW-081a: o código foi dividido em classes ajudantes (docs/modules/npc.md, "Organização
## interna"); o módulo segue como a ÚNICA porta e só delega: `NpcBodies` (passo 1) cuida do LOD, dos Intents e do interruptor de corpos; `NpcNotables`
## (passo 2), da memória, das relações e dos tiers; `NpcPersistence` (passo 3), de salvar, carregar, conferir e resumir; `NpcLifecycle` (passo 4), de criar, remover e
## matar; `NpcDecisionRuntime` (passo 5), da montagem do pensador e de `_start_action`. Dependências: só core, `world` e a própria pasta; não importa o
## `character`.

const CODE_NOT_READY: String = "NPC_NOT_READY"
const CODE_UNKNOWN: String = "NPC_UNKNOWN"
const CODE_INVALID_SPEC: String = "NPC_INVALID_SPEC"
const CODE_INVALID_SAVE: String = "NPC_INVALID_SAVE"
const CODE_NO_ID: String = "NPC_NO_ID"
const CODE_DUPLICATE_ID: String = "NPC_DUPLICATE_ID"
const CODE_ROUTINE_NOT_CONFIGURED: String = "NPC_ROUTINE_NOT_CONFIGURED"
## Alarme (LW-076): tipo do evento, gravidade máxima aceita [HIP] e o código do pedido inválido.
const ALARM_EVENT_TYPE: String = "AlarmRaised"
const MAX_ALARM_SEVERITY: int = 10
const CODE_INVALID_ALARM: String = "NPC_INVALID_ALARM"
## Comandos que só existem em build de desenvolvimento (a flag vem em `Definitions.is_development_build`).
const CODE_DEV_ONLY: String = "NPC_DEV_ONLY"
## TEMP-LW-065: sem FoodStub nas definições não há estoque de comida.
const CODE_FOOD_NOT_CONFIGURED: String = "NPC_FOOD_NOT_CONFIGURED"
## Memória (LW-078): sem tipos ou sem capacidade configurados; NPC que não é notável; tipo inexistente; pedido de gravação inválido.
const CODE_MEMORY_NOT_CONFIGURED: String = "NPC_MEMORY_NOT_CONFIGURED"
const CODE_NOT_NOTABLE: String = "NPC_NOT_NOTABLE"
const CODE_UNKNOWN_MEMORY_KIND: String = "NPC_UNKNOWN_MEMORY_KIND"
const CODE_INVALID_MEMORY: String = "NPC_INVALID_MEMORY"
## Conversa com o jogador (LW-083b): longe demais, NPC ocupado (dormindo, fugindo, ajudando ou em alarme) e cooldown da última conversa.
const CODE_TALK_TOO_FAR: String = "NPC_TALK_TOO_FAR"
const CODE_TALK_BUSY: String = "NPC_TALK_BUSY"
const CODE_TALK_COOLDOWN: String = "NPC_TALK_COOLDOWN"
## Códigos e nível que a ponte mapeia (LW-085a): a `api` os reexporta, como alias dos originais (mesmos valores), para quem está fora do módulo nunca citar `NpcLod`, `NpcTiers` nem `RelationGraph`.
const CODE_NOT_IN_S0: String = NpcLod.CODE_NOT_IN_S0
const CODE_INVALID_POSITION: String = NpcLod.CODE_INVALID_POSITION
const CODE_DEAD: String = NpcTiers.CODE_DEAD
const CODE_RELATION_INVALID: String = RelationGraph.CODE_INVALID
const CODE_RELATION_NOT_ALLOWED: String = RelationGraph.CODE_NOT_ALLOWED
const LEVEL_S0: int = NpcLod.LEVEL_S0
const KEY_NPCS: String = "npcs"
## Chave da memória no save: só aparece se algum NPC tem algo guardado (save sem ela carrega com a memória vazia).
const KEY_MEMORIES: String = "memories"
## Chave das relações no save: lista que só aparece se existe alguma relação (save sem ela carrega sem relações).
const KEY_RELATIONS: String = "relations"
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
## Por que a população inicial não nasceu (vazio = nasceu, ou não havia plano). Não é salvo: só aparece no debug_summary().
var _population_problem: String = ""
## Rastro de decisão dos NPCs marcados (LW-064): só para olhar, não é salvo nem entra no hash.
var _tracer: DecisionTracer = DecisionTracer.new()
## A tabela é UMA só e vive o tempo todo do módulo: o runner, a ocupação e o pensador a recebem por referência (on_load a atualiza no lugar).
var _npcs: Dictionary[int, NpcState] = {}
## Corpos (LW-081a, passo 1): LOD, Intents, interruptor de corpos, relato do corpo e espera do corpo atrasado. Criado no construtor.
var _bodies: NpcBodies
## Notáveis (LW-081a, passo 2): memória (LW-078), relações (LW-079), promoção e rebaixamento (LW-077) e o descarte na morte. Dona das tabelas de memória e de
## relações, que são salvas junto (chaves `memories` e `relations`). Criada no construtor.
var _notables: NpcNotables
## Estado para fora (LW-081a, passo 3): salvar, carregar, conferir e resumir, com o estoque de comida salvo. Criada no construtor.
var _persistence: NpcPersistence
## Vida e morte (LW-081a, passo 4): criar, remover, matar e conferir o pedido de criação. Criada no construtor.
var _lifecycle: NpcLifecycle
## Fluxo de decisão (LW-081a, passo 5): provedor, runner, pensador e ações sociais, montados no primeiro `tick`, e a função única que inicia uma ação.
var _runtime: NpcDecisionRuntime
## Conversa do jogador (LW-083b): a validação do pedido, a parada do NPC e o cooldown. Criada no construtor.
var _player_talk: NpcPlayerTalk
## Detector de impasse (LW-073): recupera o NPC cuja ação passou do fim previsto sem ninguém encerrá-la, ou cujos Intents venceram por tempo em sequência. Só memória (não é salvo). Criado no construtor.
var _impasse: NpcImpasse


## `need_defs`: uma definição por posição, na ordem de `order` (como NeedLoader as entrega). Vazio = sem necessidades configuradas.
## `routine`: ofícios e agenda por hora (RoutineLoader); nulo = sem rotina configurada (o ofício do NPC fica como texto sem conferência).
## `definitions`: o que falta para o módulo DECIDIR (LW-063); nulo = o módulo só guarda estado e o `tick` não faz nada.
func _init(need_defs: Array[NeedDef] = [], routine: RoutineTable = null, definitions: Definitions = null) -> void:
	_need_defs = need_defs
	_routine = routine
	_definitions = definitions
	_defs_problem = "" if need_defs.is_empty() else NeedMath.definitions_problem(need_defs)
	_bodies = NpcBodies.new(lod, intents, _npcs)
	_notables = NpcNotables.new(_npcs, _definitions, _unknown)
	_persistence = NpcPersistence.new(_npcs, _notables, _bodies, _tracer, _routine, _definitions, _defs_problem)
	_lifecycle = NpcLifecycle.new(_npcs, _notables, _tracer, _need_defs, _defs_problem, _routine, _definitions, _unknown)
	_runtime = NpcDecisionRuntime.new(_npcs, _bodies, intents, _notables, _lifecycle, _tracer, _definitions, _need_defs, _defs_problem, _routine)
	_impasse = NpcImpasse.new(_npcs, _definitions.places if _definitions != null else null, _bodies.is_embodied, _runtime.cancel_action, NpcImpasse.DEFAULT_LIMIT_MIN, intents.has_pending, _bodies.release_body)
	_player_talk = NpcPlayerTalk.new(_npcs, lod, _runtime.begin_talk_player, _notables.relation_values, _unknown, _notables, _definitions.params if _definitions != null else null)


func setup(ctx: SimContext) -> void:
	_ctx = ctx
	_bodies.setup(ctx, _definitions.lod_params if _definitions != null else null)
	_notables.setup(ctx)
	_persistence.setup(ctx)
	_lifecycle.setup(ctx)
	_runtime.setup(ctx)
	_impasse.setup(ctx)


## Cria um NPC (ID novo de ctx.ids). Confere o pedido inteiro ANTES de gastar um ID: pedido recusado não altera nada.
func request_create_npc(spec: NpcSpec) -> CreateResult:
	return _lifecycle.create(spec)


## Remove o NPC da tabela. O ID não volta: o contador do core só sobe.
func request_remove_npc(npc_id: int) -> Result:
	return _lifecycle.remove(npc_id)


## Promove o NPC de T1 a T2 (LW-077; `tier` precisa ser 2). Teto global `max_t2` dos parâmetros: cheio, `NPC_T2_LIMIT_REACHED` e ninguém é
## expulso. Só muda o tier: identidade, ofício e rotina ficam como estavam. Regras completas em `NpcTiers.promote`.
func request_promote(npc_id: int, tier: int) -> Result:
	return _notables.promote(npc_id, tier)


## Rebaixa o NPC de T2 a T1 (LW-077; `tier` precisa ser 1) e libera a vaga. Antes de mudar o tier (o NPC ainda é notável) o módulo resume a
## memória dele em traços permanentes (LW-078) e chama o ponto de extensão `Definitions.on_demote` (`NpcNotables`). Regras em `NpcTiers.demote`.
func request_demote(npc_id: int, tier: int) -> Result:
	return _notables.demote(npc_id, tier)


## Grava um episódio na memória de um NPC notável (LW-078). Comando de DEPURAÇÃO: só em build de desenvolvimento (`Definitions.is_development_build`);
## fora dele, `NPC_DEV_ONLY` e nada muda. As ações sociais (LW-080) e a conversa com o jogador (LW-083) gravam pelo mesmo caminho interno.
func request_record_memory(npc_id: int, kind_id: String, actor_ids: Array[int], place_id: String) -> Result:
	if _definitions == null or not _definitions.is_development_build:
		return Result.failure(CODE_DEV_ONLY, "NpcModule.request_record_memory: comando só existe em build de desenvolvimento (Definitions.is_development_build).")
	return _notables.record_memory(npc_id, kind_id, actor_ids, place_id)


## As memórias do NPC, em CÓPIAS (LW-078): os registros, na ordem em que entraram, e os traços permanentes. `kind_filter` vazio = todos os
## tipos; um tipo que não existe nos dados é falha tratada. NPC cidadão (T1) devolve a lista de registros vazia (e os traços que guardou
## de quando era notável). ID inexistente: falha tratada.
func peek_memories(npc_id: int, kind_filter: String = "") -> MemoriesQuery:
	return _notables.peek_memories(npc_id, kind_filter)


## O que `a_id` pensa de `b_id` (LW-079): se se conhecem, as cinco dimensões de HOJE (já com o decaimento diário), o rótulo (conhecido, amigo ou
## rival, pela afeição) e se `b_id` está vivo. A relação é uma só por par: perguntar (b, a) dá as mesmas dimensões. Pelo menos um dos dois precisa
## ser um NPC; quem não é NPC (o jogador) conta como vivo. NPC morto não tem relações (a morte as descarta): "não se conhecem" e `other_is_alive`
## falso. Pedido sem sentido (ID fora da faixa ou a mesma pessoa): falha tratada.
func peek_opinion(a_id: int, b_id: int) -> OpinionQuery:
	return _notables.peek_opinion(a_id, b_id)


## As relações do NPC, em CÓPIAS (LW-082b; painel de depuração): uma por pessoa que ele conhece, em ordem crescente do ID da outra, cada uma com as cinco
## dimensões de HOJE (a mesma conta de `peek_opinion`), o rótulo, o minuto em que se conheceram e se a outra pessoa está viva. No máximo `relations_capacity`
## por NPC. Cidadão sem relação ou NPC morto: lista vazia, com sucesso. ID inexistente: falha tratada. Só lê.
func peek_relations(npc_id: int) -> NpcRelationsQuery:
	return _notables.peek_relations(npc_id)


## Ajusta (ou cria, o "se conheceram") a relação do par somando `deltas` (cinco, na ordem de NpcRelation.DIM_IDS) (LW-079). Comando de DEPURAÇÃO:
## só em build de desenvolvimento; fora dele, `NPC_DEV_ONLY` e nada muda. As ações sociais (LW-080) e a conversa com o jogador (LW-083) ajustam
## pelo mesmo caminho interno (`NpcNotables.adjust_relation`).
func request_adjust_relation(a_id: int, b_id: int, deltas: PackedInt64Array) -> Result:
	if _definitions == null or not _definitions.is_development_build:
		return Result.failure(CODE_DEV_ONLY, "NpcModule.request_adjust_relation: comando só existe em build de desenvolvimento (Definitions.is_development_build).")
	return _notables.adjust_relation(a_id, b_id, deltas)


## O jogador (`actor_id`, em `actor_position_m`) pede para conversar com o NPC (LW-083b). Confere, nesta ordem: NPC inexistente, morto, sem corpo (`NPC_NOT_IN_S0`),
## posição inválida (`NPC_INVALID_POSITION`), longe (`NPC_TALK_TOO_FAR`, até 3 m do corpo), ocupado (`NPC_TALK_BUSY`: dormindo, fugindo, ajudando ou em alarme) e cooldown
## (`NPC_TALK_COOLDOWN`, 60 min). Recusado, NADA muda. Aceito: o NPC interrompe o que fazia, para onde está e conversa (ação `talk_player`), e `text_key` é a chave do
## texto: `first` ou `known`. Na mesma chamada (LW-083c) o NPC é promovido a T2 se houver vaga (`was_promoted`), a relação com o jogador sobe e, sendo T2, a memória `conversation`
## é gravada. Antes de tudo o ator é conferido: ID fora da faixa ou NPC é recusado. Módulo sem `setup()`: `NPC_NOT_READY`.
func request_converse(actor_id: int, actor_position_m: Vector3, npc_id: int) -> ConverseResult:
	if _ctx == null:
		return ConverseResult.new(Result.failure(CODE_NOT_READY, "NpcModule.request_converse: módulo sem setup() (sem relógio); esperado um módulo registrado no World."), "", false)
	return _player_talk.converse(actor_id, actor_position_m, npc_id, _ctx.clock.total_minutes())


## Resumo do NPC, em CÓPIA. ID inexistente devolve falha tratada, nunca derruba o jogo.
func peek_npc(npc_id: int) -> NpcQuery:
	if not _npcs.has(npc_id):
		return NpcQuery.new(_unknown("peek_npc", npc_id), null)
	var state: NpcState = _npcs[npc_id]
	var query: NpcQuery = NpcQuery.new(Result.success(), state)
	query.need_urgencies = _urgencies_of(state)
	return query


## Passou o setup: ouve os alarmes (LW-076). O módulo só reage; quem publica `AlarmRaised` hoje é o comando de depuração abaixo.
func post_setup() -> void:
	if _ctx != null:
		_ctx.events.subscribe(ALARM_EVENT_TYPE, on_alarm_raised)


## Faz soar um alarme no ponto (centímetros) com a gravidade dada (1 a MAX_ALARM_SEVERITY): publica `AlarmRaised` (LW-076). SÓ em build de
## desenvolvimento (`Definitions.is_development_build`); fora dele, `NPC_DEV_ONLY` e nada acontece. Ponto fora do mapa ou gravidade fora da
## faixa: `NPC_INVALID_ALARM`. Sem tecla nem tela: a tecla é da LW-082.
func request_raise_alarm(x_cm: int, z_cm: int, severity: int) -> Result:
	if _definitions == null or not _definitions.is_development_build:
		return Result.failure(CODE_DEV_ONLY, "NpcModule.request_raise_alarm: comando só existe em build de desenvolvimento (Definitions.is_development_build).")
	if _ctx == null:
		return Result.failure(CODE_NOT_READY, "NpcModule.request_raise_alarm: módulo sem setup() (sem barramento de eventos); esperado um módulo registrado no World.")
	if x_cm < 0 or x_cm > NpcState.MAX_COORDINATE_CM or z_cm < 0 or z_cm > NpcState.MAX_COORDINATE_CM:
		return Result.failure(CODE_INVALID_ALARM, "NpcModule.request_raise_alarm: ponto (x_cm %d, z_cm %d) fora da faixa; esperado de 0 a %d." % [x_cm, z_cm, NpcState.MAX_COORDINATE_CM])
	if severity < 1 or severity > MAX_ALARM_SEVERITY:
		return Result.failure(CODE_INVALID_ALARM, "NpcModule.request_raise_alarm: gravidade %d; esperado de 1 a %d." % [severity, MAX_ALARM_SEVERITY])
	_ctx.events.publish(AlarmRaised.new(x_cm, z_cm, severity))
	return Result.success()


## Reação ao evento `AlarmRaised` (LW-076): os NPCs vivos a até `alarm_radius_m` do ponto pensam já, em ordem de ID (a pressão de `safety` sobe,
## `flee` e `help` entram entre as candidatas e a ação atual é interrompida com efeito proporcional se uma reação vencer). Quem ignora segue a vida.
func on_alarm_raised(event: SimEvent) -> void:
	_runtime.react_to_alarm(event, _sorted_ids())


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


## Os ids das necessidades na ordem dos dados (`order` de data/needs.json), em CÓPIA (LW-082b; o painel de depuração nomeia com eles os valores de `peek_npc`).
## Módulo sem definições de necessidade: lista vazia.
func peek_need_ids() -> Array[String]:
	var ids: Array[String] = []
	for def: NeedDef in _need_defs:
		ids.append(def.id)
	return ids


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
	# Primeiro o LOD e os Intents (LW-069 e LW-070; funcionam sem `Definitions`); depois a fila de pensamento.
	_impasse.tick(_bodies.tick())
	_runtime.run_step()


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


## LOD lógico (LW-069; docs/modules/npc.md, seção 6). Quem monta o módulo o liga com `lod.configure(LodParams)`; sem isso ele fica
## desligado (o pedido de foco falha com NPC_LOD_NOT_CONFIGURED e nada muda). O nível dos NPCs não é salvo nem entra no hash.
var lod: NpcLod = NpcLod.new()


## Põe ou move o foco do LOD (ID do ator e posição em metros). Quem entrega a posição é a ponte: o `npc` não importa o `character`.
func request_set_focus(focus_id: int, position_m: Vector3) -> Result:
	return lod.set_focus(focus_id, position_m)


## Tira o foco do LOD. Foco desconhecido: falha tratada.
func request_clear_focus(focus_id: int) -> Result:
	return lod.clear_focus(focus_id)


## O nível de simulação do NPC (LW-085a): `LEVEL_S0` se está em S0; senão o de S1, inclusive para NPC inexistente (como `lod.level_of`). Só lê.
func peek_level_of(npc_id: int) -> int:
	return lod.level_of(npc_id)


## Quantos NPCs estão em S0 agora (LW-085a; o tamanho de `lod.s0_ids()`). Só lê.
func peek_s0_count() -> int:
	return lod.s0_ids().size()


## Interruptor de corpos (LW-070b; docs/modules/npc.md, seção 6): só a apresentação sabe se existem corpos para os NPCs; sem eles o LOD fica inerte e o
## hash do mundo não depende do foco. O estado do interruptor mora no `NpcBodies` (LW-081a); o do jogo nasce SEM corpos e a apresentação (LW-072) o liga.
## Liga ou desliga os corpos. Desligar tira TODOS de S0 pelo mesmo caminho de quem se afasta (um LodChanged por NPC), solta os Intents pendentes
## e deixa cada ação seguir abstrata com o tempo que falta; os focos ficam guardados. Ligar de novo volta ao comportamento da LW-070a. Repetir o
## estado atual não faz nada. Módulo sem `setup()`: NPC_NOT_READY e nada muda.
func request_set_bodies_available(available: bool) -> Result:
	return _bodies.set_available(available)


## Protocolo de Intents do modo S0 (LW-070; docs/modules/npc.md, seção 6). Sem `configure_intents` ele fica desligado: nenhuma intenção sai
## e o pedido de resultado falha com NPC_INTENTS_NOT_CONFIGURED. As intenções pendentes não são salvas nem entram no hash.
var intents: NpcIntentBoard = NpcIntentBoard.new(lod)


## Cria um ActionRunner sobre a MESMA tabela de NPCs e as MESMAS definições de necessidade deste módulo (o runner lê e escreve os
## NpcState por referência). Quem monta o módulo o liga ao quadro de Intents com `configure_intents`.
func create_action_runner(catalog: Array[ActionDef], places: SettlementService = null, provider: ActionConditionProvider = null) -> ActionRunner:
	return ActionRunner.new(_npcs, catalog, _need_defs, places, provider)


## Liga o protocolo de Intents: `runner` vem de `create_action_runner`; `places` é o serviço de locais do `world` (o destino dos Intents).
func configure_intents(runner: ActionRunner, places: SettlementService, params: NpcIntentParams) -> Result:
	return intents.configure(runner, _npcs, places, params)


## Intents que a apresentação ainda não cumpriu (cópias, em ordem crescente de NPC). Quem os entrega à apresentação é a ponte.
func peek_pending_intents() -> Array[NpcIntent]:
	return intents.peek_pending()


## Resultado que a apresentação devolve de um Intent (pela ponte). Sucesso só MARCA o fim da ação e acorda o NPC: os efeitos entram no pensamento
## seguinte, pela função única do runner (LW-070d); BLOCKED e CANCELLED cancelam a ação na hora, sem efeito; resultado de ação velha é descartado
## e contado (NPC_RESULT_STALE). Não devolve mais NPC_ACTION_FAILED: a falha por regra aparece no pensamento seguinte.
func request_report_npc_result(result: NpcActionResult) -> Result:
	return _bodies.report_result(result)


## Posições dos corpos em S0, em lote (NPC -> posição em metros), vindas da ponte. Cada posição vale por si (ver NpcIntentBoard).
func request_report_npc_positions(batch: Dictionary[int, Vector3]) -> Result:
	return intents.report_positions(batch)


## IDs viram texto (assim o JSON guarda chaves) e entram em ordem crescente do número.
func serialize() -> Dictionary:
	return _persistence.serialize()


## Confere tudo antes de alterar o estado: se algo for inválido, o estado fica como estava. Só recusa o que não dá para converter
## (estrutura, tipos, chave de ID); faixas e coerência ficam com validate() (mesmo critério do `character`).
func on_load(data: Dictionary) -> Result:
	var loaded: Result = _persistence.on_load(data)
	if loaded.ok:
		_impasse.reset()
	return loaded


## Problemas do estado (lista vazia se estiver tudo certo). O ofício é conferido contra a tabela de rotina quando o módulo a tem (LW-061);
## local e ação ficam como texto: cada tarefa futura acrescenta a sua conferência.
func validate() -> Array[String]:
	return _persistence.validate()


## As últimas recuperações do detector de impasse (LW-073; as mais antigas primeiro): cópias com `npc_id`, `reason`, `place_id`, `minute`, `action_id` (a cancelada) e
## `overdue_min`. Fica fora do `debug_summary()` de propósito: o resumo entra na impressão digital do oráculo e não pode mudar enquanto não há impasse.
func peek_impasse_records() -> Array[Dictionary]:
	return _impasse.peek_records()


## Contagens por tier, vivos e mortos, ofícios e o tamanho em bytes do serialize() (backlog I4). Só para depuração.
func debug_summary() -> Dictionary:
	var summary: Dictionary = _persistence.debug_summary(peek_counts(), _population_problem)
	_runtime.add_summary(summary)
	return summary


## TEMP-LW-065: o FoodStub real, se o provedor de comida das definições for ele (os testes usam um provedor falso, sem estado salvo).
func _food_stub() -> FoodStub:
	if _definitions == null:
		return null
	return _definitions.food as FoodStub


## TEMP-LW-065
func _food_not_configured(caller: String) -> Result:
	return Result.failure(CODE_FOOD_NOT_CONFIGURED, "NpcModule.%s: o módulo foi criado sem FoodStub; não há estoque de comida." % caller)


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


## Nível de urgência de cada necessidade do NPC, pelos limiares dos dados. Sem definições, tudo 0 (não há limiares para comparar).
func _urgencies_of(state: NpcState) -> PackedInt64Array:
	var urgencies: PackedInt64Array = PackedInt64Array()
	urgencies.resize(NpcState.NEED_COUNT)
	if _need_defs.is_empty() or not _defs_problem.is_empty():
		return urgencies
	for def: NeedDef in _need_defs:
		urgencies[def.order] = NeedMath.urgency(state.need_values[def.order], def)
	return urgencies


func _unknown(caller: String, npc_id: int) -> Result:
	return Result.failure(CODE_UNKNOWN, "NpcModule.%s: o NPC %d não existe; esperado um ID devolvido por request_create_npc (há %d NPC(s))." % [caller, npc_id, _npcs.size()])


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
	## Opcional (LW-070a): parâmetros do LOD lógico (data/lod_params.json). Nulo = LOD desligado: ninguém ganha corpo (S0).
	var lod_params: LodParams
	## Opcional (LW-070a): parâmetros dos Intents do modo S0 (data/intent_params.json). Nulo = nenhuma ação nasce com Intent.
	var intent_params: NpcIntentParams
	var walk_speed_cm_per_min: int = ActionRunner.DEFAULT_WALK_SPEED_CM_PER_MIN
	## Build de desenvolvimento? Só então valem os comandos de depuração do módulo (hoje `request_set_food_stock`). A fronteira do app lê
	## `OS.is_debug_build()` e entrega aqui; a simulação não lê `OS`. Padrão falso.
	var is_development_build: bool = false
	## Opcional (LW-077): ponto de extensão do rebaixamento. É chamado com o `npc_id`, uma vez por rebaixamento de verdade, ANTES de o tier mudar
	## (o NPC ainda é notável). A LW-078 e a LW-079 o usarão para resumir memória e relações em traços; hoje só os testes o usam. Sem ele, nada.
	var on_demote: Callable = Callable()
	## Opcional (LW-078): os tipos de episódio (data/memory_kinds.json). Sem eles, ou sem `memory_capacity` nos parâmetros, ninguém grava memória.
	var memory_kinds: Array[MemoryKindLoader.KindDef] = []


## Resultado de `peek_memories`: `result.ok` diz se deu certo; só então as listas valem. São CÓPIAS, na ordem em que os registros entraram.
class MemoriesQuery:
	extends RefCounted

	var result: Result
	var records: Array[MemoryRecord]
	var traits: Array[NpcMemory.Trait]

	func _init(query_result: Result, found_records: Array[MemoryRecord], found_traits: Array[NpcMemory.Trait]) -> void:
		result = query_result
		records = found_records
		traits = found_traits


## Resultado de `peek_opinion`: `result.ok` diz se deu certo; só então os campos valem. `values` é uma CÓPIA, na ordem de NpcRelation.DIM_IDS.
class OpinionQuery:
	extends RefCounted

	var result: Result
	## Se conhecem (existe relação entre os dois).
	var is_known: bool = false
	var values: PackedInt64Array = PackedInt64Array()
	## `acquaintance`, `friend` ou `rival`; vazio se não se conhecem.
	var label: String = ""
	## Minuto em que se conheceram (-1 se não se conhecem).
	var met_at: int = -1
	## O segundo (`b_id`) está vivo? Quem não é NPC (o jogador) conta como vivo.
	var other_is_alive: bool = true

	func _init(query_result: Result) -> void:
		result = query_result
		values.resize(NpcRelation.DIM_COUNT)


## Resultado de `request_converse`: `result.ok` diz se a conversa começou; só então `text_key` vale (a CHAVE do texto, nunca o texto, DEC-036). `was_promoted`: o NPC virou
## notável nesta conversa (LW-083c).
class ConverseResult:
	extends RefCounted

	var result: Result
	var text_key: String
	var was_promoted: bool

	func _init(converse_result: Result, key: String, promoted: bool) -> void:
		result = converse_result
		text_key = key
		was_promoted = promoted


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
