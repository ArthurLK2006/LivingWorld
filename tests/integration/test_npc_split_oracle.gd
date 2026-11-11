extends GutTest
## LW-081a, passo 0: o ORÁCULO da divisão do `npc_module.gd` (passos 1 a 5). Montagem dos testes de integração do S0 (dados reais de res://data,
## NpcSetup, GameModules, SimulationRunner) com o CORPO PERFEITO: a apresentação devolve ARRIVED ou DONE no fim previsto de cada Intent. Cinco
## responsabilidades, em fases, cada uma com uma IMPRESSÃO DIGITAL (SHA-256 do hash do mundo, do `debug_summary()`, dos Intents, do LOD, dos eventos,
## das memórias e das opiniões): 1) LOD, Intents, interruptor de corpos, relatos, corpo atrasado e alarme; 2) memória, relações, promoção,
## rebaixamento, morte e a conversa de dois notáveis; 3) serialize, on_load, validate e debug_summary, com salvar e carregar no meio; 4) criar,
## remover e matar NPC (e a população inicial); 5) a montagem do provedor, do runner, do pensador e das ações sociais, e `_start_action`. Os valores
## esperados saíram do commit 5a7d453, ANTES da divisão, e cinco deles seguem os mesmos até hoje (intents, alarm, resumed, switches e real_game). Os outros
## quatro (talk, save, demote e starved) foram trocados na LW-073b (commit 5346091), por decisão de Arthur em 10/11/2026: o NPC LATE, de corpo mais atrasado que o
## tempo limite do Intent, passou a ser recuperado pelo detector de impasse (`result_timeout`), e isso muda o mundo dali em diante. Se um mudar de propósito, o valor
## novo é decisão de Arthur, nunca um ajuste para o teste passar. Na LW-097a (marco 3, DEC-175) os nove valores foram trocados por decisão de Arthur em 11/11/2026: o
## terceiro povoado ganhou a regra do FoodStub (`food_test_settlement_c`, TEMP-LW-065), e o estoque de comida de cada povoado entra no save do `npc`, então todo hash mudou.
## Na LW-097c (marco 3) os nove valores mudaram de novo: o `world` virou módulo registrado e ganhou o bloco dele no save (`world`, vazio com todas as rotas abertas); o valor novo
## é só o registro do marco 3, que Arthur já aprovou na LW-097a (DEC-175).

const WORLD_SEED: int = 11
const ACTOR_ID: int = 77
const SETTLEMENT: String = "test_settlement_a"
const SOCIAL_PLACE: String = "a_social_01"
const HOUR: int = 60
const DAY: int = SimClock.MINUTES_PER_DAY
const ALARM_SEVERITY: int = 2
const CONVERSATION_KIND: String = "conversation"
## Metade da velocidade padrão (8400): as viagens passam a durar 2 minutos e a ligação `Definitions` -> runner do jogo fica visível.
const WALK_SPEED_CM_PER_MIN: int = 4200
const REAL_GAME_NOTABLES: int = 30
## Elenco: FIRST e SECOND são os notáveis que conversam às 11h; HELPER ajuda no alarme (depois dele o corpo atrasa 6 min por ação e, depois do
## save, adianta 5); LATE tem o corpo mais atrasado que o tempo limite do Intent (30 min), então nenhuma ação dele termina; LEAVING sai do jogo.
enum Who { FIRST, SECOND, HELPER, LATE, LEAVING }
const OCCUPATIONS: Array[String] = ["artisan", "artisan", "guard", "lumberjack", "innkeeper"]
const HOMES: Array[String] = ["a_home_02", "a_home_01", "a_home_03", "a_home_04", "a_home_05"]
const WORKS: Array[String] = ["a_work_03", "a_work_01", "a_work_02", "a_work_04", "a_work_05"]
const BODY_DELAYS_MIN: Array[int] = [0, 0, 0, 40, 0]
const LATE_BODY_MIN: int = 6
const EARLY_BODY_MIN: int = 5
const CALM_TRAITS: Array[int] = [10, 10, 50, 10]
const HERO_TRAITS: Array[int] = [5, 90, 50, 95]
## Instantes do cenário (minutos desde a meia-noite do dia 0).
const T_INTENTS: int = 1 * HOUR
const T_ALARM: int = 2 * HOUR
const T_REMOVE: int = 4 * HOUR
const T_SWITCHES: int = 5 * HOUR + 10
const T_TALKED: int = 12 * HOUR + 20
const T_SAVE: int = 14 * HOUR
const T_AFTER_LOAD: int = 14 * HOUR + 30
const T_DEMOTE: int = DAY + 6 * HOUR
const T_STARVED: int = 4 * DAY + 9 * HOUR
## Impressões digitais esperadas, por fase (SHA-256 completo). MARCO 1 de hash (LW-088a, DEC-175; valores novos aprovados por Arthur em 11/11/2026): o registro da `economy`
## acrescentou ao save do mundo o bloco vazio `economy`, e só isso mudou os nove valores (sem o bloco, voltam todos aos anteriores, que eram os de 5a7d453 para `intents`,
## `alarm`, `resumed` e `switches`, e os da LW-073b e da LW-085 para os demais; ver o cabeçalho).
const EXPECTED: Dictionary[String, String] = {
	"intents": "741f663a0acab2d965338e813a00504876e800de4fb240edcd17a846a353cf02",
	"alarm": "619241a479331a96319898ddfba83e190c00a5fd3d45e479b24e37ce30ab27c2",
	"resumed": "83d4d6f1bad3fa7912f0047631fb66b124c9388012c919525c31eff50e39fc1e",
	"switches": "b2f79365b4c0309e66135d9c7c5bab954b70fbad1d1b9db92f3b440f1d099100",
	"talk": "388c4752b18b17497a034329196534fea115fef342ad6cc91c117334f6ff78ab",
	"save": "cd8cfe84a7647afcc7a8489a8d7150ad15e62ec8190875a72be2cb5951c54f9f",
	"demote": "225b4a4fbdaaaac17f412a7bfb9029972809966ca545cef8ac6988e409338cb9",
	"starved": "b23c4e65cad99410febbf564584f3b4a740f07e8f299cd59f145f207e2842bed",
	"real_game": "9f37878f3add92467a403d05aa4a3e2c66d851818d36ae2fe7bdae7412defb0d",
}

var _data: NpcLifeCheck.GameData
var _places: SettlementService
var _social_m: Vector3
var _rigs: Array[Rig] = []
var _codec: JsonSaveCodec = JsonSaveCodec.new()


## Um jogo de teste: o runner, o módulo `npc`, o atraso do corpo de cada NPC e o que o teste anotou.
class Rig:
	extends RefCounted

	var runner: SimulationRunner
	var npc: NpcModule
	## Minutos que o corpo de cada NPC demora depois do fim previsto do Intent (padrão 0: corpo perfeito).
	var body_delay: Dictionary[int, int] = {}
	## Os NPCs de que a impressão digital olha memórias e opiniões.
	var watched: Array[int] = []
	var event_log: PackedStringArray = PackedStringArray()

	func on_event(event: SimEvent) -> void:
		var detail: Array = []
		match event.type:
			"LodChanged": detail = [(event as LodChanged).npc_id, (event as LodChanged).from_level, (event as LodChanged).to_level]
			"RelationChanged": detail = [(event as RelationChanged).a_id, (event as RelationChanged).b_id, Array((event as RelationChanged).values)]
			"NpcDied": detail = [(event as NpcDied).npc_id, (event as NpcDied).cause, (event as NpcDied).tier]
			"AlarmRaised": detail = [(event as AlarmRaised).x_cm, (event as AlarmRaised).z_cm, event.severity]
		event_log.append("%s|%d|%d|%s" % [event.type, event.id, event.time, str(detail)])

	func now() -> int:
		return runner.world.context.clock.total_minutes()


func before_all() -> void:
	_data = NpcLifeCheck.load_game_data()
	assert_eq(_data.problem, "", "Os dados reais do jogo carregam.")
	_places = SettlementService.new(_data.settlements, _data.places)
	var social_cm: Vector2i = _place_cm(SOCIAL_PLACE)
	_social_m = Vector3(social_cm.x / TerrainData.CM_PER_METER, 0.0, social_cm.y / TerrainData.CM_PER_METER)


func after_each() -> void:
	for rig: Rig in _rigs:
		rig.runner.finish()
	_rigs.clear()


## Jogo igual ao real (dados de res://data, build de desenvolvimento por causa do alarme e dos comandos de depuração). Sem `payload`, jogo novo;
## com ele, o jogo CARREGADO (sem corpos, como a apresentação o encontra). `with_population` falso tira a população inicial.
func _rig(payload: Dictionary = {}, with_population: bool = false) -> Rig:
	var setup: NpcSetup = NpcSetup.from_dir(NpcLifeCheck.DATA_DIR, _places, true)
	assert_true(setup.result.ok, setup.result.message)
	setup.definitions.walk_speed_cm_per_min = WALK_SPEED_CM_PER_MIN
	if not with_population:
		setup.definitions.population = null
	var rig: Rig = Rig.new()
	rig.runner = SimulationRunner.new(WORLD_SEED)
	var modules: GameModules = GameModules.register(rig.runner, _data.terrain, _data.points, setup)
	assert_true(modules.result.ok, modules.result.message)
	rig.npc = modules.npc
	for event_type: String in ["LodChanged", "RelationChanged", "NpcDied", "AlarmRaised"]:
		rig.runner.world.context.events.subscribe(event_type, rig.on_event)
	if payload.is_empty():
		rig.runner.start_new_game()
	else:
		var loaded: Result = rig.runner.load_game(payload)
		assert_true(loaded.ok, loaded.message)
	_rigs.append(rig)
	return rig


func _place_cm(place_id: String) -> Vector2i:
	var found: SettlementService.PlaceQuery = _places.peek_place(place_id)
	assert_true(found.result.ok, found.result.message)
	return Vector2i(roundi(found.place.position.x * TerrainData.CM_PER_METER), roundi(found.place.position.z * TerrainData.CM_PER_METER))


## Liga os corpos (no jogo real, quem faz isso é a apresentação) e põe o foco do ator.
func _bodies_and_focus(rig: Rig, focus_m: Vector3) -> void:
	assert_true(rig.npc.request_set_bodies_available(true).ok)
	assert_true(rig.npc.request_set_focus(ACTOR_ID, focus_m).ok)


## Cria o NPC `index` do elenco em casa (cidadão; FIRST e SECOND são promovidos a notáveis). Devolve o ID.
func _spawn(rig: Rig, index: int) -> int:
	var spec: NpcSpec = NpcSpec.new()
	spec.name_key = "npc.name.villager"
	spec.occupation_id = OCCUPATIONS[index]
	spec.settlement_id = SETTLEMENT
	spec.home_place_id = HOMES[index]
	spec.work_place_id = WORKS[index]
	spec.place_id = HOMES[index]
	var home_cm: Vector2i = _place_cm(HOMES[index])
	spec.x_cm = home_cm.x
	spec.z_cm = home_cm.y
	if index == Who.FIRST:
		spec.traits = PackedInt64Array(CALM_TRAITS)
	elif index == Who.HELPER:
		spec.traits = PackedInt64Array(HERO_TRAITS)
	var created: NpcModule.CreateResult = rig.npc.request_create_npc(spec)
	assert_true(created.result.ok, created.result.message)
	if index <= Who.SECOND:
		assert_true(rig.npc.request_promote(created.npc_id, NpcState.TIER_NOTABLE).ok)
	rig.body_delay[created.npc_id] = BODY_DELAYS_MIN[index]
	return created.npc_id


## O corpo: a cada minuto relata a posição de todos os corpos em S0 (já no destino) e cumpre, no fim previsto mais o atraso dele, cada Intent
## pendente (ARRIVED para ir, DONE para agir). Falha por regra ao terminar (sem comida, por exemplo) é um desfecho legítimo do jogo, não do teste.
func _answer_due(rig: Rig) -> void:
	var intents: Array[NpcIntent] = rig.npc.peek_pending_intents()
	var bodies_m: Dictionary[int, Vector3] = {}
	for intent: NpcIntent in intents:
		bodies_m[intent.npc_id] = Vector3(intent.destination_cm.x / TerrainData.CM_PER_METER, 0.0, intent.destination_cm.y / TerrainData.CM_PER_METER)
	assert_true(rig.npc.request_report_npc_positions(bodies_m).ok)
	for intent: NpcIntent in intents:
		if rig.now() < rig.npc.peek_npc(intent.npc_id).action_ends_at + rig.body_delay.get(intent.npc_id, 0):
			continue
		var outcome: NpcActionResult.Outcome = NpcActionResult.Outcome.ARRIVED if intent.kind == NpcIntent.Kind.MOVE_TO_PLACE else NpcActionResult.Outcome.DONE
		var reported: Result = rig.npc.request_report_npc_result(NpcActionResult.new(intent.npc_id, intent.action_serial, outcome, bodies_m[intent.npc_id]))
		assert_true(reported.ok or reported.code == ActionRunner.CODE_ACTION_FAILED, reported.message)


## Anda até o minuto `end_min`, com o corpo respondendo depois de cada passo.
func _walk(rig: Rig, end_min: int) -> void:
	while rig.now() < end_min:
		rig.runner.step_once()
		_answer_due(rig)


func _fingerprint(rig: Rig) -> String:
	var parts: PackedStringArray = PackedStringArray([rig.runner.world.state_hash(), str(rig.npc.peek_npc_ids()), str(rig.npc.validate())])
	for summary: Dictionary in [rig.npc.debug_summary(), rig.npc.intents.debug_summary(), rig.npc.lod.debug_summary()]:
		parts.append(JSON.stringify(summary, "", true, true))
	var routine: RoutineTable.RoutineQuery = rig.npc.peek_routine_action(OCCUPATIONS[Who.FIRST], rig.runner.world.context.clock.hour_of_day())
	parts.append(str([routine.result.ok, routine.action_id, rig.npc.peek_food_stock(SETTLEMENT).stock]))
	for intent: NpcIntent in rig.npc.peek_pending_intents():
		parts.append("%d|%d|%d|%s|%s|%d" % [intent.npc_id, intent.action_serial, intent.kind, intent.place_id, str(intent.destination_cm), intent.expected_minutes])
	for npc_id: int in rig.watched:
		var npc: NpcModule.NpcQuery = rig.npc.peek_npc(npc_id)
		parts.append(str([npc.result.ok, npc.tier, npc.is_alive, npc.death_cause, Array(npc.need_values), npc.place_id, npc.x_cm, npc.z_cm, npc.action_id, npc.action_serial, npc.action_ends_at, npc.next_think_time]))
		var memories: NpcModule.MemoriesQuery = rig.npc.peek_memories(npc_id)
		for record: MemoryRecord in memories.records:
			parts.append(JSON.stringify(record.to_dict(), "", true, true))
		for memory_trait: NpcMemory.Trait in memories.traits:
			parts.append(JSON.stringify(memory_trait.to_dict(), "", true, true))
		for other_id: int in rig.watched:
			if other_id > npc_id:
				var opinion: NpcModule.OpinionQuery = rig.npc.peek_opinion(npc_id, other_id)
				parts.append(str([opinion.result.ok, opinion.is_known, Array(opinion.values), opinion.label, opinion.met_at, opinion.other_is_alive]))
	parts.append_array(rig.event_log)
	return "\n".join(parts).sha256_text()


## Confere a impressão digital da fase contra a esperada (a de 5a7d453 ou, nas quatro trocadas, a da LW-073b) e imprime o começo dela (para comparar execuções).
func _check(rig: Rig, phase: String) -> void:
	var fingerprint: String = _fingerprint(rig)
	print("oráculo %s (minuto %d): %s" % [phase, rig.now(), fingerprint.left(12)])
	assert_eq(fingerprint, EXPECTED.get(phase, ""), "Fase '%s' (minuto %d): a impressão digital mudou; atual %s." % [phase, rig.now(), fingerprint])


func test_the_five_responsibilities_of_the_module_behave_exactly_as_before_the_split() -> void:
	var rig: Rig = _rig()
	var ids: Array[int] = []
	for index: int in OCCUPATIONS.size():
		ids.append(_spawn(rig, index))
	rig.watched.assign(ids)
	assert_true(rig.npc.request_set_traced(ids[Who.FIRST], true).ok)
	_bodies_and_focus(rig, _social_m)
	# (1) corpos e Intents: todos dormem em S0 com um Intent pendente.
	_walk(rig, T_INTENTS)
	_check(rig, "intents")
	# (1) e (2) alarme na casa do primeiro notável: todos fogem, o ajudante volta e a vítima grava o episódio.
	var alarm_cm: Vector2i = _place_cm(HOMES[Who.FIRST])
	_walk(rig, T_ALARM)
	assert_true(rig.npc.request_raise_alarm(alarm_cm.x, alarm_cm.y, ALARM_SEVERITY).ok)
	_walk(rig, T_REMOVE)
	assert_gt(rig.npc.peek_memories(ids[Who.FIRST], "help_received").records.size(), 0, "O ajudante chegou e a vítima notável lembra de ter sido ajudada.")
	_check(rig, "alarm")
	rig.body_delay[ids[Who.HELPER]] = LATE_BODY_MIN
	# (4) remover um NPC (o ID não volta); (1) o interruptor de corpos, os NPCs que voltam a S0 no meio da ação e o foco que sai e volta.
	assert_true(rig.npc.request_remove_npc(ids[Who.LEAVING]).ok)
	assert_eq(rig.npc.request_remove_npc(ids[Who.LEAVING]).code, NpcModule.CODE_UNKNOWN, "Remover de novo: o ID não existe mais.")
	assert_true(rig.npc.request_set_bodies_available(false).ok)
	_walk(rig, rig.now() + 5)
	assert_eq(rig.npc.peek_pending_intents().size(), 0, "Sem corpos não há Intents.")
	assert_true(rig.npc.request_set_bodies_available(true).ok)
	_walk(rig, rig.now() + 5)
	_check(rig, "resumed")
	assert_true(rig.npc.request_clear_focus(ACTOR_ID).ok)
	_walk(rig, rig.now() + 2)
	_bodies_and_focus(rig, _social_m)
	_walk(rig, T_SWITCHES)
	_check(rig, "switches")
	# (2) a conversa das 11h, um episódio e um ajuste de relação pelos comandos de depuração, e a promoção do ajudante.
	_walk(rig, T_TALKED)
	var witnesses: Array[int] = [ids[Who.HELPER]]
	assert_eq(rig.npc.request_record_memory(ids[Who.HELPER], CONVERSATION_KIND, witnesses, SOCIAL_PLACE).code, NpcModule.CODE_NOT_NOTABLE, "Cidadão não tem memória.")
	assert_true(rig.npc.request_promote(ids[Who.HELPER], NpcState.TIER_NOTABLE).ok)
	assert_true(rig.npc.request_record_memory(ids[Who.FIRST], CONVERSATION_KIND, witnesses, SOCIAL_PLACE).ok)
	assert_true(rig.npc.request_adjust_relation(ids[Who.FIRST], ids[Who.HELPER], PackedInt64Array([5, 0, 0, 0, 0])).ok)
	assert_true(rig.npc.peek_opinion(ids[Who.FIRST], ids[Who.SECOND]).is_known, "Os dois notáveis se conheceram na conversa.")
	_check(rig, "talk")
	# (3) salvar e carregar no meio, com recusa de save inválido, e (4) criar um NPC no mundo carregado.
	_walk(rig, T_SAVE)
	assert_true(rig.runner.can_capture_game(), "Dá para salvar.")
	var live: Rig = _rig(_codec.decode(_codec.encode(rig.runner.capture_game(), NpcLifeCheck.GAME_VERSION)).payload)
	live.event_log = rig.event_log.duplicate()
	live.body_delay = rig.body_delay.duplicate()
	live.watched = rig.watched.duplicate()
	live.body_delay[ids[Who.HELPER]] = -EARLY_BODY_MIN
	assert_eq(live.runner.world.state_hash(), rig.runner.world.state_hash(), "O mundo carregado tem o mesmo hash do salvo.")
	assert_eq(live.npc.validate().size(), 0, str(live.npc.validate()))
	assert_eq(live.npc.on_load({NpcModule.KEY_NPCS: 5}).code, NpcModule.CODE_INVALID_SAVE, "Save inválido é recusado.")
	assert_eq(live.runner.world.state_hash(), rig.runner.world.state_hash(), "E nada muda no mundo carregado.")
	_bodies_and_focus(live, _social_m)
	assert_true(live.npc.request_set_traced(ids[Who.FIRST], true).ok, "O carregamento zera o rastro: a marca volta a ser posta.")
	assert_eq(live.npc.request_create_npc(NpcSpec.new()).result.code, NpcModule.CODE_INVALID_SPEC, "Pedido de criação inválido é recusado.")
	var newcomer: int = _spawn(live, Who.LEAVING)
	assert_gt(newcomer, ids.max(), "O ID do recém-chegado não reaproveita nenhum anterior.")
	live.watched.append(newcomer)
	assert_true(live.npc.request_set_food_stock(SETTLEMENT, 0).ok)
	_walk(live, T_AFTER_LOAD)
	_check(live, "save")
	# (2) rebaixar o notável que conversou: as relações com cidadãos viram traços.
	_walk(live, T_DEMOTE)
	assert_true(live.npc.request_demote(ids[Who.SECOND], NpcState.TIER_NORMAL).ok)
	_walk(live, T_DEMOTE + 10)
	_check(live, "demote")
	# (2) e (4) a fome crítica prolongada mata, de cidadão a notável (estoque zerado desde as 14h; o corpo do LATE nunca o deixa comer).
	_walk(live, T_STARVED)
	assert_eq(live.npc.peek_counts()[NpcModule.COUNT_DEAD], live.npc.peek_counts()[NpcModule.COUNT_TOTAL], "Todos morreram de fome.")
	assert_true(live.npc.explain_decision(ids[Who.FIRST]).result.ok, "O rastro de decisão do notável marcado depois do carregamento existe.")
	_check(live, "starved")


func test_the_real_game_with_one_hundred_npcs_behaves_exactly_as_before_the_split() -> void:
	var rig: Rig = _rig({}, true)
	var ids: Array[int] = rig.npc.peek_npc_ids()
	assert_eq(ids.size(), NpcLifeCheck.EXPECTED_POPULATION, "O jogo real nasce com os 100 NPCs.")
	for index: int in REAL_GAME_NOTABLES:
		assert_true(rig.npc.request_promote(ids[index], NpcState.TIER_NOTABLE).ok)
	rig.watched.assign(ids.slice(0, REAL_GAME_NOTABLES))
	_bodies_and_focus(rig, _social_m)
	_walk(rig, DAY)
	_check(rig, "real_game")
