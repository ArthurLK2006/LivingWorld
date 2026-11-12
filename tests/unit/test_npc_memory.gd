extends GutTest
## LW-078: memória dos NPCs notáveis (T2) (docs/modules/npc.md, seção 7), sem janela. Cada episódio é um `MemoryRecord` de um tipo de
## data/memory_kinds.json; a memória tem capacidade, esquece por VALOR (saliência menos idade em dias vezes o desgaste do tipo, nunca abaixo
## de 0; sai o menor, no empate o mais antigo) e, antes de esquecer um registro com saliência acima do limiar, guarda um TRAÇO PERMANENTE (uma
## valência por pessoa, no máximo `trait_slots`). Só notável vivo tem memória; a morte a descarta; rebaixar resume o que resta em traços.
## Os números de cada cenário estão nos comentários: tipos de teste `minor` (valência 10, saliência 20, desgaste 5 por dia), `steady`
## (30, 50, sem desgaste) e `big` (-80, 90, sem desgaste); capacidade 3, limiar 80, 2 traços, salvo quando o teste diz outra coisa.

const VILLAGE: String = "village_a"
const HOME: String = "home_a1"
const WORK: String = "work_a1"
const NEED_IDS: Array[String] = ["hunger", "rest", "safety", "income", "social"]
const TRAIT_IDS: Array[String] = ["caution", "sociability", "ambition", "loyalty"]
const HOME_X_CM: int = 8400
const THINK_INTERVAL: int = 10
const CAPACITY: int = 3
const THRESHOLD: int = 80
const SLOTS: int = 2
const NOTABLE: int = NpcState.TIER_NOTABLE
const NORMAL: int = NpcState.TIER_NORMAL
const PERSON_A: int = 7001
const PERSON_B: int = 7002
const PERSON_C: int = 7003
const PERSON_D: int = 7004
const MINUTES_PER_DAY: int = 1440
const DATA_DIR: String = "res://data"
const WORLD_DIR: String = "res://data/world"
const KINDS_LABEL: String = "res://data/memory_kinds.json"
const KINDS_ISSUE_CODE: String = "MEMORY_KIND_DATA_INVALID"
const PARAMS_LABEL: String = "res://data/npc_params.json"
const PARAMS_ISSUE_CODE: String = "NPC_PARAMS_INVALID"


# ---------------------------------------------------------------------------------------------------- mundo de teste

## Espião do ponto de extensão do rebaixamento (LW-077): guarda o ID e o tier que o NPC tinha na hora da chamada.
class DemoteSpy:
	extends RefCounted

	var module: NpcModule
	var calls: Array = []

	func on_demote(npc_id: int) -> void:
		calls.append([npc_id, module.peek_npc(npc_id).tier])


class RealGame:
	extends RefCounted

	var runner: SimulationRunner
	var modules: GameModules


func _rules(capacity: int = CAPACITY, threshold: int = THRESHOLD, slots: int = SLOTS) -> NpcMemory.Rules:
	var decays: Dictionary[String, int] = {"minor": 5, "steady": 0, "big": 0}
	return NpcMemory.Rules.new(capacity, threshold, slots, decays)


func _record(kind: String, salience: int, time: int = 0, valence: int = 10, actors: Array[int] = []) -> MemoryRecord:
	var record: MemoryRecord = MemoryRecord.new()
	record.kind = kind
	record.salience = salience
	record.time = time
	record.valence = valence
	record.actors = PackedInt64Array(actors)
	return record


func _saliences(memory: NpcMemory) -> Array[int]:
	var found: Array[int] = []
	for record: MemoryRecord in memory.records:
		found.append(record.salience)
	return found


## [pessoa, valência] de cada traço, na ordem em que estão guardados.
func _trait_pairs(traits: Array[NpcMemory.Trait]) -> Array:
	var pairs: Array = []
	for memory_trait: NpcMemory.Trait in traits:
		pairs.append([memory_trait.actor_id, memory_trait.valence])
	return pairs


## Faz o registro `target` SAIR de uma memória de capacidade 1: entra um registro de saliência 100 e o alvo (menor ou empatado e mais antigo) sai.
func _push_out(memory: NpcMemory, rules: NpcMemory.Rules, target: MemoryRecord, now: int = 0) -> void:
	memory.remember(target, now, rules)
	memory.remember(_record("steady", 100, now, 0), now, rules)


func _need_defs(lethal: bool) -> Array[NeedDef]:
	var defs: Array[NeedDef] = []
	for position: int in NEED_IDS.size():
		if lethal and position == 0:
			defs.append(NeedDef.new(NEED_IDS[position], position, 95, 0, 40, 65, 90, 24, 72, 50))
		else:
			defs.append(NeedDef.new(NEED_IDS[position], position, 0, 0, 40, 65, 90))
	return defs


func _catalog() -> Array[ActionDef]:
	var work: ActionDef = ActionDef.new("work", 240, "work", 5, true)
	work.effects.append(ActionDef.ActionEffect.new("rest", 5))
	return [work, ActionDef.new("wait", 10, "", 0, true), ActionDef.new(ActionRunner.GO_TO_PLACE_ID, 0, "", 0, true)]


func _routine() -> RoutineTable:
	var occupations: Array[RoutineTable.OccupationDef] = [RoutineTable.OccupationDef.new("tester", "work")]
	var blocks: Array[RoutineTable.RoutineBlock] = [RoutineTable.RoutineBlock.new("t", "tester", 0, 24, "work")]
	return RoutineTable.new(occupations, blocks)


func _places() -> SettlementService:
	var settlements: Array[Settlement] = [Settlement.new(VILLAGE, "settlement.a", Vector3.ZERO)]
	var places: Array[Place] = [
		Place.new(HOME, VILLAGE, Place.KIND_HOME, Vector3(84.0, 0.0, 0.0), 8), Place.new(WORK, VILLAGE, Place.KIND_WORK, Vector3(184.0, 0.0, 0.0), 8),
	]
	return SettlementService.new(settlements, places)


func _params(capacity: int, slots: int) -> NpcParams:
	var params: NpcParams = NpcParams.new()
	params.urgency_weight_attention = 1
	params.urgency_weight_urgent = 3
	params.urgency_weight_critical = 6
	params.time_cost_per_hour = 2
	params.distance_cost_per_100m = 2
	params.risk_cost_percent = 100
	params.inertia_bonus = 25
	params.routine_bonus = 40
	params.think_interval_min = THINK_INTERVAL
	params.max_thinks_per_step = 20
	params.decision_top_k = 1
	params.memory_capacity = capacity
	params.trait_threshold = THRESHOLD
	params.trait_slots = slots
	return params


func _kinds() -> Array[MemoryKindLoader.KindDef]:
	return [MemoryKindLoader.KindDef.new("minor", 10, 20, 5), MemoryKindLoader.KindDef.new("steady", 30, 50, 0), MemoryKindLoader.KindDef.new("big", -80, 90, 0)]


## Módulo completo (decide e anda). `capacity` 0 ou `with_kinds` falso = memória não configurada.
func _module(capacity: int = CAPACITY, slots: int = SLOTS, with_kinds: bool = true, is_development_build: bool = true, lethal: bool = false, spy: DemoteSpy = null) -> NpcModule:
	var definitions: NpcModule.Definitions = NpcModule.Definitions.new()
	definitions.actions = _catalog()
	var traits: Array[TraitLoader.TraitDef] = []
	for position: int in TRAIT_IDS.size():
		traits.append(TraitLoader.TraitDef.new(TRAIT_IDS[position], position))
	definitions.traits = traits
	definitions.params = _params(capacity, slots)
	definitions.places = _places()
	definitions.is_development_build = is_development_build
	if with_kinds:
		definitions.memory_kinds = _kinds()
	if spy != null:
		definitions.on_demote = spy.on_demote
	var module: NpcModule = NpcModule.new(_need_defs(lethal), _routine(), definitions)
	if spy != null:
		spy.module = module
	return module


func _world(module: NpcModule, world_seed: int = 3) -> World:
	var clock: SimClock = SimClock.new()
	var world: World = World.new(SimContext.new(clock, EventBus.new(clock), WorldRng.new(world_seed), IdGenerator.new()))
	assert_true(world.register_module("npc", module).ok)
	world.setup()
	world.post_setup()
	return world


func _spawn(module: NpcModule, tier: int = NOTABLE, occupation_id: String = "") -> int:
	var spec: NpcSpec = NpcSpec.new()
	spec.name_key = "npc.name.villager"
	spec.tier = tier
	spec.occupation_id = occupation_id
	spec.settlement_id = VILLAGE
	spec.place_id = HOME
	spec.home_place_id = HOME
	spec.work_place_id = WORK
	spec.x_cm = HOME_X_CM
	var created: NpcModule.CreateResult = module.request_create_npc(spec)
	assert_true(created.result.ok, created.result.message)
	return created.npc_id


func _run(world: World, minutes: int) -> void:
	for _step: int in minutes:
		world.context.clock.advance_step()
		world.tick(1)
		world.context.events.dispatch()


func _remember(module: NpcModule, npc_id: int, kind_id: String, actors: Array[int] = [], place_id: String = "") -> void:
	var recorded: Result = module.request_record_memory(npc_id, kind_id, actors, place_id)
	assert_true(recorded.ok, recorded.message)


func _kinds_of(records: Array[MemoryRecord]) -> Array[String]:
	var found: Array[String] = []
	for record: MemoryRecord in records:
		found.append(record.kind)
	return found


# ---------------------------------------------------------------------------------------------------- esquecimento por valor

## Capacidade 3, tudo no minuto 0 (sem desgaste). Entram saliências 50, 30 e 70; a 4ª (40) enche: valores 50, 30, 70 e 40, sai a de 30.
## A 5ª (10) é a mais fraca de todas: nem chega a ficar.
func test_when_full_the_record_with_the_lowest_value_leaves_and_the_capacity_is_never_exceeded() -> void:
	var memory: NpcMemory = NpcMemory.new()
	var rules: NpcMemory.Rules = _rules(CAPACITY, 100)
	for salience: int in [50, 30, 70]:
		memory.remember(_record("steady", salience), 0, rules)
	assert_eq(_saliences(memory), [50, 30, 70], "Ainda cabe: nada sai.")
	memory.remember(_record("steady", 40), 0, rules)
	assert_eq(_saliences(memory), [50, 70, 40], "Sai a de menor valor (30).")
	memory.remember(_record("steady", 10), 0, rules)
	assert_eq(_saliences(memory), [50, 70, 40], "O novo, o mais fraco de todos, nem fica.")
	for index: int in 20:
		memory.remember(_record("steady", 60 + index), 0, rules)
		assert_true(memory.records.size() <= CAPACITY, "A capacidade nunca é passada.")
	assert_eq(memory.traits.size(), 0, "Limiar 100: nada vira traço.")


## Empate de valor (40 e 40): sai o mais antigo, mesmo que tenha entrado depois (B entrou primeiro no minuto 100, A depois no minuto 0). No
## mesmo minuto, sai o que entrou primeiro (marcado pela valência 1, 2, 3 e 4).
func test_a_tie_sends_out_the_oldest_and_then_the_one_that_came_first() -> void:
	var rules: NpcMemory.Rules = _rules(CAPACITY, 100)
	var memory: NpcMemory = NpcMemory.new()
	memory.remember(_record("steady", 40, 100, 1), 200, rules)
	memory.remember(_record("steady", 90, 50, 2), 200, rules)
	memory.remember(_record("steady", 40, 0, 3), 200, rules)
	memory.remember(_record("steady", 60, 200, 4), 200, rules)
	var times: Array[int] = []
	for record: MemoryRecord in memory.records:
		times.append(record.time)
	assert_eq(times, [100, 50, 200], "Saiu o de tempo 0, o mais antigo dos dois empatados.")
	var same_minute: NpcMemory = NpcMemory.new()
	same_minute.remember(_record("steady", 40, 10, 1), 10, rules)
	same_minute.remember(_record("steady", 40, 10, 2), 10, rules)
	same_minute.remember(_record("steady", 90, 10, 3), 10, rules)
	same_minute.remember(_record("steady", 60, 10, 4), 10, rules)
	var markers: Array[int] = []
	for record: MemoryRecord in same_minute.records:
		markers.append(record.valence)
	assert_eq(markers, [2, 3, 4], "No mesmo minuto sai o que entrou primeiro.")


func test_value_falls_by_whole_days_and_never_below_zero() -> void:
	var rules: NpcMemory.Rules = _rules()
	var record: MemoryRecord = _record("minor", 100)
	assert_eq(NpcMemory.value_of(record, 0, rules), 100)
	assert_eq(NpcMemory.value_of(record, MINUTES_PER_DAY - 1, rules), 100, "Ainda não completou um dia.")
	assert_eq(NpcMemory.value_of(record, MINUTES_PER_DAY, rules), 95, "Um dia inteiro: -5.")
	assert_eq(NpcMemory.value_of(record, MINUTES_PER_DAY * 10, rules), 50)
	assert_eq(NpcMemory.value_of(record, MINUTES_PER_DAY * 100, rules), 0, "Nunca abaixo de zero.")
	assert_eq(NpcMemory.value_of(record, -50, rules), 100, "Relógio antes do registro: idade zero.")
	assert_eq(NpcMemory.value_of(_record("steady", 100), MINUTES_PER_DAY * 365, rules), 100, "Desgaste zero não desgasta.")
	assert_eq(NpcMemory.value_of(_record("ghost", 100), MINUTES_PER_DAY * 50, rules), 100, "Tipo desconhecido não desgasta.")


## Capacidade 2. O registro `minor` de saliência 60 (a maior) tem 10 dias no minuto 14400: valor 60 - 10 x 5 = 10. Os novos (40 e 20) valem
## mais; quando o terceiro entra, sai o velho.
func test_an_old_record_loses_to_a_fresher_weaker_one_because_of_the_decay() -> void:
	var rules: NpcMemory.Rules = _rules(2, 100)
	var memory: NpcMemory = NpcMemory.new()
	var day_ten: int = MINUTES_PER_DAY * 10
	memory.remember(_record("minor", 60, 0), 0, rules)
	memory.remember(_record("steady", 40, day_ten), day_ten, rules)
	memory.remember(_record("steady", 20, day_ten), day_ten, rules)
	assert_eq(_saliences(memory), [40, 20], "O velho (valor 10) saiu, apesar da saliência de partida mais alta.")


# ---------------------------------------------------------------------------------------------------- traços permanentes

## Capacidade 1, limiar 80: o alvo sai quando entra um registro de saliência 100.
func test_a_record_above_the_threshold_becomes_a_trait_before_leaving_and_one_at_or_below_does_not() -> void:
	var rules: NpcMemory.Rules = _rules(1, THRESHOLD, 4)
	var strong: NpcMemory = NpcMemory.new()
	_push_out(strong, rules, _record("big", 90, 0, -80, [PERSON_A]))
	assert_eq(_trait_pairs(strong.traits), [[PERSON_A, -80]], "Saliência 90 > 80: virou traço antes de sair.")
	var just_above: NpcMemory = NpcMemory.new()
	_push_out(just_above, rules, _record("big", THRESHOLD + 1, 0, -50, [PERSON_A]))
	assert_eq(_trait_pairs(just_above.traits), [[PERSON_A, -50]], "81 já passa do limiar.")
	var at_threshold: NpcMemory = NpcMemory.new()
	_push_out(at_threshold, rules, _record("big", THRESHOLD, 0, -50, [PERSON_A]))
	assert_eq(at_threshold.traits.size(), 0, "Saliência igual ao limiar NÃO passa dele.")
	var nobody: NpcMemory = NpcMemory.new()
	_push_out(nobody, rules, _record("big", 95, 0, -50))
	assert_eq(nobody.traits.size(), 0, "Sem pessoa envolvida não há de quem guardar a valência.")
	var two_people: NpcMemory = NpcMemory.new()
	_push_out(two_people, rules, _record("big", 95, 0, -60, [PERSON_A, PERSON_B]))
	assert_eq(_trait_pairs(two_people.traits), [[PERSON_A, -60], [PERSON_B, -60]], "Cada pessoa do episódio ganha o seu traço.")
	assert_eq(strong.records.size(), 1, "E o registro que ficou é o que empurrou.")


## O traço usa a saliência DE PARTIDA, não o valor: o registro `minor` de saliência 90 já está com valor 0 aos 20 dias (90 - 20 x 5), mas passa do limiar.
func test_the_trait_rule_uses_the_original_salience_not_the_decayed_value() -> void:
	var rules: NpcMemory.Rules = _rules(1, THRESHOLD, 4)
	var memory: NpcMemory = NpcMemory.new()
	var day_twenty: int = MINUTES_PER_DAY * 20
	_push_out(memory, rules, _record("minor", 90, 0, -40, [PERSON_A]), day_twenty)
	assert_eq(NpcMemory.value_of(_record("minor", 90, 0), day_twenty, rules), 0)
	assert_eq(_trait_pairs(memory.traits), [[PERSON_A, -40]])
	assert_eq(memory.traits[0].since, day_twenty, "O traço nasce quando o registro sai.")


func test_a_trait_sums_the_valence_per_person_clamped_and_slots_are_never_exceeded() -> void:
	var rules: NpcMemory.Rules = _rules(1, THRESHOLD, 2)
	var memory: NpcMemory = NpcMemory.new()
	_push_out(memory, rules, _record("big", 90, 0, -60, [PERSON_A]))
	_push_out(memory, rules, _record("big", 90, 0, -30, [PERSON_A]))
	assert_eq(_trait_pairs(memory.traits), [[PERSON_A, -90]], "Mesma pessoa: a valência soma.")
	_push_out(memory, rules, _record("big", 90, 0, -30, [PERSON_A]))
	assert_eq(_trait_pairs(memory.traits), [[PERSON_A, -100]], "Limitada a -100.")
	_push_out(memory, rules, _record("big", 90, 0, 150, [PERSON_A]))
	assert_eq(_trait_pairs(memory.traits), [[PERSON_A, 50]], "E soma de volta.")
	_push_out(memory, rules, _record("big", 90, 0, 20, [PERSON_B]))
	assert_eq(_trait_pairs(memory.traits), [[PERSON_A, 50], [PERSON_B, 20]], "Dois traços: a vaga acabou.")
	_push_out(memory, rules, _record("big", 90, 0, 10, [PERSON_C]))
	assert_eq(_trait_pairs(memory.traits), [[PERSON_A, 50], [PERSON_B, 20]], "Cheio: um novo MAIS FRACO (10) que o mais fraco (20) não entra.")
	_push_out(memory, rules, _record("big", 90, 0, 20, [PERSON_D]))
	assert_eq(_trait_pairs(memory.traits), [[PERSON_A, 50], [PERSON_B, 20]], "Empate de módulo (20 e 20) não troca.")
	_push_out(memory, rules, _record("big", 90, 0, -70, [PERSON_C]))
	assert_eq(_trait_pairs(memory.traits), [[PERSON_A, 50], [PERSON_C, -70]], "Mais forte (70) entra no lugar do mais fraco (20).")
	_push_out(memory, rules, _record("big", 90, 0, 5, [PERSON_A]))
	assert_eq(_trait_pairs(memory.traits), [[PERSON_A, 55], [PERSON_C, -70]], "Quem já tem traço soma sem precisar de vaga.")
	var no_slots: NpcMemory = NpcMemory.new()
	_push_out(no_slots, _rules(1, THRESHOLD, 0), _record("big", 90, 0, -80, [PERSON_A]))
	assert_eq(no_slots.traits.size(), 0, "Sem vagas de traço nenhum traço nasce.")


# ---------------------------------------------------------------------------------------------------- resumo ao rebaixar

func test_summarizing_turns_the_records_into_one_trait_per_person_and_empties_them() -> void:
	var rules: NpcMemory.Rules = _rules(10, THRESHOLD, 4)
	var memory: NpcMemory = NpcMemory.new()
	memory.remember(_record("big", 90, 0, -80, [PERSON_A]), 0, rules)
	memory.remember(_record("steady", 50, 0, 30, [PERSON_B]), 0, rules)
	memory.remember(_record("steady", 50, 0, 30, [PERSON_B]), 0, rules)
	memory.remember(_record("minor", 20, 0, 10), 0, rules)
	memory.remember(_record("steady", 50, 0, 25, [PERSON_C, PERSON_D]), 0, rules)
	memory.remember(_record("steady", 50, 0, -25, [PERSON_D]), 0, rules)
	memory.summarize(500, rules)
	assert_eq(memory.records.size(), 0, "Os registros foram resumidos e esvaziados.")
	assert_eq(_trait_pairs(memory.traits), [[PERSON_A, -80], [PERSON_B, 60], [PERSON_C, 25]], "Soma por pessoa: A -80, B 60, C 25; D (25 - 25 = 0) não diz nada; o registro sem pessoa some.")
	memory.summarize(600, rules)
	assert_eq(_trait_pairs(memory.traits), [[PERSON_A, -80], [PERSON_B, 60], [PERSON_C, 25]], "Resumir de novo, sem registros, não duplica nem muda nada.")


## Três pessoas e só 2 vagas: ficam as de maior módulo (A 80 e C 50); empate de módulo vai para o menor ID (A antes de B).
func test_summarizing_keeps_the_strongest_people_when_there_are_not_enough_slots() -> void:
	var rules: NpcMemory.Rules = _rules(10, THRESHOLD, 2)
	var memory: NpcMemory = NpcMemory.new()
	memory.remember(_record("big", 90, 0, -80, [PERSON_A]), 0, rules)
	memory.remember(_record("steady", 50, 0, 30, [PERSON_B]), 0, rules)
	memory.remember(_record("steady", 50, 0, 50, [PERSON_C]), 0, rules)
	memory.summarize(0, rules)
	assert_eq(_trait_pairs(memory.traits), [[PERSON_A, -80], [PERSON_C, 50]])
	var tied: NpcMemory = NpcMemory.new()
	tied.remember(_record("steady", 50, 0, 40, [PERSON_B]), 0, rules)
	tied.remember(_record("steady", 50, 0, -40, [PERSON_A]), 0, rules)
	tied.remember(_record("steady", 50, 0, 40, [PERSON_C]), 0, rules)
	tied.summarize(0, rules)
	assert_eq(_trait_pairs(tied.traits), [[PERSON_A, -40], [PERSON_B, 40]], "Empate de módulo: o menor ID.")
	var existing: NpcMemory = NpcMemory.new()
	existing.traits.append(NpcMemory.Trait.new(PERSON_B, 20, 0))
	existing.remember(_record("steady", 50, 0, 30, [PERSON_B]), 0, rules)
	existing.summarize(0, rules)
	assert_eq(_trait_pairs(existing.traits), [[PERSON_B, 50]], "O traço que já existia soma com o resumo.")


# ---------------------------------------------------------------------------------------------------- formato do save (a memória sozinha)

func test_a_memory_survives_the_json_round_trip_and_bad_formats_are_refused_with_context() -> void:
	var rules: NpcMemory.Rules = _rules(1, THRESHOLD, 4)
	var memory: NpcMemory = NpcMemory.new()
	_push_out(memory, rules, _record("big", 90, 5, -80, [PERSON_A, PERSON_B]))
	memory.records[0].place_id = WORK
	var original: Dictionary = memory.to_dict()
	var parsed_json: Variant = JSON.parse_string(JSON.stringify(original))
	var restored: NpcMemory.ParseResult = NpcMemory.parse(parsed_json)
	assert_eq(restored.error, "")
	assert_eq(restored.memory.to_dict(), original, "O JSON devolve os inteiros como decimais; a leitura converte de volta.")
	var table: Dictionary[int, NpcMemory] = {3: memory, 5: NpcMemory.new()}
	var saved_table: Dictionary = NpcMemory.table_to_dict(table)
	assert_eq(saved_table.keys(), ["3"], "Só entra quem tem alguma coisa guardada; o ID vira texto.")
	var bad_cases: Array = [
		["memória que não é objeto", "texto", "não é um objeto"],
		["sem a lista de registros", {"traits": []}, "records"],
		["sem a lista de traços", {"records": []}, "traits"],
		["registro que não é objeto", {"records": [5], "traits": []}, "registro 0"],
		["registro sem o tipo", {"records": [{"actors": [], "place_id": "", "time": 0, "valence": 0, "salience": 0, "source": "WITNESSED", "confidence": 100}], "traits": []}, "kind"],
		["tempo fracionário", {"records": [{"kind": "big", "actors": [], "place_id": "", "time": 1.5, "valence": 0, "salience": 0, "source": "WITNESSED", "confidence": 100}], "traits": []}, "time"],
		["pessoas que não são lista", {"records": [{"kind": "big", "actors": "A", "place_id": "", "time": 0, "valence": 0, "salience": 0, "source": "WITNESSED", "confidence": 100}], "traits": []}, "actors"],
		["pessoa que não é inteiro", {"records": [{"kind": "big", "actors": ["A"], "place_id": "", "time": 0, "valence": 0, "salience": 0, "source": "WITNESSED", "confidence": 100}], "traits": []}, "actors"],
		["traço que não é objeto", {"records": [], "traits": ["x"]}, "traço 0"],
		["traço sem a pessoa", {"records": [], "traits": [{"valence": 1, "since": 0}]}, "actor_id"],
	]
	for case: Array in bad_cases:
		var refused: NpcMemory.ParseResult = NpcMemory.parse(case[1])
		assert_null(refused.memory, "%s: deveria ser recusada." % case[0])
		assert_string_contains(refused.error, case[2], str(case[0]))
	for bad_table: Variant in ["texto", {"abc": {"records": [], "traits": []}}, {"0": {"records": [], "traits": []}}, {"1": {"records": [], "traits": []}, "01": {"records": [], "traits": []}}]:
		assert_ne(NpcMemory.parse_table(bad_table).error, "", "Tabela %s deveria ser recusada." % str(bad_table))
	assert_eq(NpcMemory.parse_table({}).error, "")


# ---------------------------------------------------------------------------------------------------- o módulo: gravar

func test_a_recorded_memory_takes_its_values_from_the_kind_and_the_clock() -> void:
	var module: NpcModule = _module()
	var world: World = _world(module)
	var npc_id: int = _spawn(module)
	_run(world, 120)
	_remember(module, npc_id, "big", [PERSON_A], WORK)
	var query: NpcModule.MemoriesQuery = module.peek_memories(npc_id)
	assert_true(query.result.ok, query.result.message)
	assert_eq(query.records.size(), 1)
	var record: MemoryRecord = query.records[0]
	assert_eq([record.kind, record.place_id, record.time, record.valence, record.salience, record.source, record.confidence], ["big", WORK, 120, -80, 90, MemoryRecord.SOURCE_WITNESSED, 100])
	assert_eq(Array(record.actors), [PERSON_A])
	assert_eq(query.traits.size(), 0)
	assert_eq(module.validate().size(), 0, str(module.validate()))
	world.teardown()


func test_only_living_notables_remember_and_a_bad_request_changes_nothing() -> void:
	var module: NpcModule = _module()
	var world: World = _world(module)
	var notable: int = _spawn(module)
	var citizen: int = _spawn(module, NORMAL)
	var dead: int = _spawn(module)
	var saved: Dictionary = module.serialize()
	var entries: Dictionary = saved["npcs"]
	var dead_entry: Dictionary = entries[str(dead)]
	dead_entry["is_alive"] = false
	dead_entry["death_cause"] = "hunger"
	dead_entry["died_at"] = 1
	assert_true(module.on_load(saved).ok)
	var before: Dictionary = module.serialize()
	assert_eq(module.request_record_memory(citizen, "big", [], "").code, NpcModule.CODE_NOT_NOTABLE, "Cidadão (T1) não tem memória.")
	assert_string_contains(module.request_record_memory(citizen, "big", [], "").message, "request_promote")
	assert_eq(module.request_record_memory(dead, "big", [], "").code, NpcTiers.CODE_DEAD)
	assert_eq(module.request_record_memory(999, "big", [], "").code, NpcModule.CODE_UNKNOWN)
	var unknown_kind: Result = module.request_record_memory(notable, "ghost", [], "")
	assert_eq(unknown_kind.code, NpcModule.CODE_UNKNOWN_MEMORY_KIND)
	assert_string_contains(unknown_kind.message, "minor", "A mensagem diz quais tipos existem.")
	for bad_actors: Array in [[PERSON_A, PERSON_B, PERSON_C], [0], [-3], [notable], [PERSON_A, PERSON_A]]:
		var typed: Array[int] = []
		typed.assign(bad_actors)
		var refused: Result = module.request_record_memory(notable, "big", typed, "")
		assert_eq(refused.code, NpcModule.CODE_INVALID_MEMORY, "Pessoas %s deveriam ser recusadas." % str(bad_actors))
	assert_eq(module.serialize(), before, "Nenhum pedido recusado alterou o estado.")
	var production: NpcModule = _module(CAPACITY, SLOTS, true, false)
	var production_world: World = _world(production)
	var production_npc: int = _spawn(production)
	assert_eq(production.request_record_memory(production_npc, "big", [], "").code, NpcModule.CODE_DEV_ONLY, "O comando de gravação é de depuração.")
	var no_kinds: NpcModule = _module(CAPACITY, SLOTS, false)
	var no_capacity: NpcModule = _module(0)
	var unconfigured_worlds: Array[World] = [_world(no_kinds), _world(no_capacity)]
	for unconfigured: NpcModule in [no_kinds, no_capacity]:
		var other_npc: int = _spawn(unconfigured)
		assert_eq(unconfigured.request_record_memory(other_npc, "big", [], "").code, NpcModule.CODE_MEMORY_NOT_CONFIGURED, "Sem tipos ou sem capacidade a memória não está configurada.")
	var bare: NpcModule = NpcModule.new()
	var bare_world: World = _world(bare)
	var bare_npc: int = _spawn(bare)
	assert_eq(bare.request_record_memory(bare_npc, "big", [], "").code, NpcModule.CODE_DEV_ONLY, "Módulo sem definições não é build de desenvolvimento.")
	assert_true(bare.peek_memories(bare_npc).result.ok, "Mas consultar funciona: nada guardado.")
	for ended: World in unconfigured_worlds:
		ended.teardown()
	bare_world.teardown()
	world.teardown()
	production_world.teardown()


# ---------------------------------------------------------------------------------------------------- o módulo: consultar

func test_peek_memories_gives_copies_in_order_filters_by_kind_and_handles_odd_ids() -> void:
	var module: NpcModule = _module(10, 4)
	var world: World = _world(module)
	var npc_id: int = _spawn(module)
	var citizen: int = _spawn(module, NORMAL)
	_remember(module, npc_id, "minor", [PERSON_A])
	_run(world, 10)
	_remember(module, npc_id, "steady", [PERSON_B])
	_run(world, 10)
	_remember(module, npc_id, "minor")
	var everything: NpcModule.MemoriesQuery = module.peek_memories(npc_id)
	assert_eq(_kinds_of(everything.records), ["minor", "steady", "minor"], "Na ordem em que entraram.")
	assert_eq([everything.records[0].time, everything.records[1].time, everything.records[2].time], [0, 10, 20])
	assert_eq(_kinds_of(module.peek_memories(npc_id, "minor").records), ["minor", "minor"])
	assert_eq(_kinds_of(module.peek_memories(npc_id, "steady").records), ["steady"])
	assert_eq(module.peek_memories(npc_id, "big").records.size(), 0, "Tipo que existe, mas sem registros: vazio.")
	var bad_filter: NpcModule.MemoriesQuery = module.peek_memories(npc_id, "ghost")
	assert_eq(bad_filter.result.code, NpcModule.CODE_UNKNOWN_MEMORY_KIND)
	assert_eq(module.peek_memories(999).result.code, NpcModule.CODE_UNKNOWN)
	var citizen_query: NpcModule.MemoriesQuery = module.peek_memories(citizen)
	assert_true(citizen_query.result.ok)
	assert_eq([citizen_query.records.size(), citizen_query.traits.size()], [0, 0], "Cidadão: nada guardado.")
	everything.records[0].valence = -100
	everything.records[0].actors.append(PERSON_D)
	everything.records.clear()
	var again: NpcModule.MemoriesQuery = module.peek_memories(npc_id)
	assert_eq(again.records.size(), 3, "Mexer na resposta não mexe na memória.")
	assert_eq([again.records[0].valence, again.records[0].actors.size()], [10, 1])
	world.teardown()


func test_the_module_keeps_the_capacity_and_the_strong_record_becomes_a_trait_you_can_see() -> void:
	var module: NpcModule = _module(1, 4)
	var world: World = _world(module)
	var npc_id: int = _spawn(module)
	_remember(module, npc_id, "big", [PERSON_A])
	assert_eq(module.peek_memories(npc_id).traits.size(), 0, "Ainda cabe.")
	_remember(module, npc_id, "big", [PERSON_B])
	var query: NpcModule.MemoriesQuery = module.peek_memories(npc_id)
	assert_eq(query.records.size(), 1, "Capacidade 1: só um registro fica.")
	assert_eq(_trait_pairs(query.traits), [[PERSON_A, -80]], "O primeiro (empate, mais antigo) saiu e deixou o traço.")
	query.traits[0].valence = 0
	assert_eq(module.peek_memories(npc_id).traits[0].valence, -80, "Os traços também vêm em cópia.")
	world.teardown()


# ---------------------------------------------------------------------------------------------------- o módulo: morte, remoção e rebaixamento

func test_death_discards_the_memory_of_the_dead() -> void:
	var module: NpcModule = _module(CAPACITY, SLOTS, true, true, true)
	var world: World = _world(module)
	var npc_id: int = _spawn(module)
	var second: int = _spawn(module)
	_remember(module, npc_id, "big", [PERSON_A])
	_remember(module, second, "steady", [PERSON_B])
	assert_true(module.serialize().has("memories"))
	_run(world, 72 * 60 + 40)
	assert_false(module.peek_npc(npc_id).is_alive, "Morreu de fome (sem como comer).")
	assert_false(module.peek_npc(second).is_alive, "O outro também.")
	var query: NpcModule.MemoriesQuery = module.peek_memories(npc_id)
	assert_true(query.result.ok, "Consultar o morto não falha.")
	assert_eq([query.records.size(), query.traits.size()], [0, 0])
	assert_false(module.serialize().has("memories"), "Nenhuma memória sobrou no save.")
	assert_eq(module.validate().size(), 0, str(module.validate()))
	assert_eq(module.debug_summary()["npcs_with_memory"], 0)
	world.teardown()


func test_removing_an_npc_discards_its_memory_and_the_others_keep_theirs() -> void:
	var module: NpcModule = _module()
	var world: World = _world(module)
	var removed: int = _spawn(module)
	var kept: int = _spawn(module)
	_remember(module, removed, "big", [PERSON_A])
	_remember(module, kept, "big", [PERSON_B])
	assert_true(module.request_remove_npc(removed).ok)
	assert_eq(module.validate().size(), 0, str(module.validate()))
	assert_eq(module.debug_summary()["npcs_with_memory"], 1)
	assert_eq(module.peek_memories(kept).records.size(), 1)
	world.teardown()


## Notável com 3 episódios: `big` (-80) com A, `steady` (30) com B e `minor` (10) sem ninguém. Ao rebaixar, os registros somem e ficam dois
## traços (A -80 e B 30); o espião do ponto de extensão da LW-077 ainda é chamado uma vez, com o NPC ainda notável. Promover de novo começa
## sem registros e com os mesmos traços; um novo episódio com A (-80) e outro rebaixamento SOMAM no traço de A (-160, limitado a -100), sem duplicar.
func test_demoting_summarizes_the_memory_into_traits_and_promoting_again_does_not_duplicate() -> void:
	var spy: DemoteSpy = DemoteSpy.new()
	var module: NpcModule = _module(CAPACITY, SLOTS, true, true, false, spy)
	var world: World = _world(module)
	var npc_id: int = _spawn(module)
	_remember(module, npc_id, "big", [PERSON_A])
	_remember(module, npc_id, "steady", [PERSON_B])
	_remember(module, npc_id, "minor")
	assert_true(module.request_demote(npc_id, NORMAL).ok)
	var demoted: NpcModule.MemoriesQuery = module.peek_memories(npc_id)
	assert_eq(demoted.records.size(), 0, "Cidadão não tem registros.")
	assert_eq(_trait_pairs(demoted.traits), [[PERSON_A, -80], [PERSON_B, 30]])
	assert_eq(spy.calls, [[npc_id, NOTABLE]], "O gancho da LW-077 continua sendo chamado uma vez, com o NPC ainda notável.")
	assert_eq(module.validate().size(), 0, str(module.validate()))
	assert_true(module.request_promote(npc_id, NOTABLE).ok)
	var promoted: NpcModule.MemoriesQuery = module.peek_memories(npc_id)
	assert_eq([promoted.records.size(), _trait_pairs(promoted.traits)], [0, [[PERSON_A, -80], [PERSON_B, 30]]], "Promover não recria nem duplica nada.")
	_remember(module, npc_id, "big", [PERSON_A])
	assert_true(module.request_demote(npc_id, NORMAL).ok)
	assert_eq(_trait_pairs(module.peek_memories(npc_id).traits), [[PERSON_A, -100], [PERSON_B, 30]], "O traço de A soma e é limitado; continua um por pessoa.")
	assert_true(module.request_demote(npc_id, NORMAL).ok, "Rebaixar quem já é cidadão não muda nada.")
	assert_eq(_trait_pairs(module.peek_memories(npc_id).traits), [[PERSON_A, -100], [PERSON_B, 30]])
	assert_eq(module.validate().size(), 0, str(module.validate()))
	world.teardown()


func test_demoting_without_any_memory_or_without_the_memory_configured_just_works() -> void:
	var module: NpcModule = _module()
	var world: World = _world(module)
	var empty: int = _spawn(module)
	assert_true(module.request_demote(empty, NORMAL).ok)
	assert_eq(module.peek_memories(empty).traits.size(), 0)
	var unconfigured: NpcModule = _module(CAPACITY, SLOTS, false)
	var other_world: World = _world(unconfigured)
	var plain: int = _spawn(unconfigured)
	assert_true(unconfigured.request_demote(plain, NORMAL).ok, "Sem tipos de memória o rebaixamento só muda o tier.")
	assert_eq(unconfigured.peek_npc(plain).tier, NORMAL)
	world.teardown()
	other_world.teardown()


# ---------------------------------------------------------------------------------------------------- o módulo: save, validate e determinismo

## Capacidade 2. Três `big` (valor 90 cada) nos minutos 30, 31 e 32: o terceiro enche e sai o mais antigo (A e B), que deixa dois traços.
func test_the_memory_goes_into_the_save_and_back_and_an_old_save_loads_with_empty_memory() -> void:
	var module: NpcModule = _module(2, 4)
	var world: World = _world(module)
	var npc_id: int = _spawn(module)
	_run(world, 30)
	_remember(module, npc_id, "big", [PERSON_A, PERSON_B], WORK)
	_run(world, 1)
	_remember(module, npc_id, "big", [PERSON_C])
	_run(world, 1)
	_remember(module, npc_id, "big", [PERSON_D])
	var before: NpcModule.MemoriesQuery = module.peek_memories(npc_id)
	assert_eq([before.records.size(), before.records[0].time, before.records[1].time], [2, 31, 32])
	assert_eq(_trait_pairs(before.traits), [[PERSON_A, -80], [PERSON_B, -80]], "O mais antigo saiu e deixou um traço para cada pessoa dele.")
	var parsed: Variant = JSON.parse_string(JSON.stringify(world.serialize(), "", true, true))
	var saved: Dictionary = parsed
	var other: NpcModule = _module(2, 4)
	var other_world: World = _world(other)
	assert_true(other_world.on_load(saved).ok)
	var after: NpcModule.MemoriesQuery = other.peek_memories(npc_id)
	assert_eq(_kinds_of(after.records), _kinds_of(before.records))
	assert_eq(_trait_pairs(after.traits), _trait_pairs(before.traits))
	assert_eq(other_world.state_hash(), world.state_hash(), "Mesmo estado, mesmo hash.")
	var old_save: Dictionary = module.serialize()
	old_save.erase("memories")
	assert_true(module.on_load(old_save).ok, "Save de antes da LW-078 carrega.")
	assert_eq(module.peek_memories(npc_id).records.size(), 0)
	assert_eq(module.validate().size(), 0, str(module.validate()))
	world.teardown()
	other_world.teardown()


func test_a_broken_memory_in_the_save_is_refused_and_the_module_stays_as_it_was() -> void:
	var module: NpcModule = _module()
	var world: World = _world(module)
	var npc_id: int = _spawn(module)
	_remember(module, npc_id, "big", [PERSON_A])
	var before: Dictionary = module.serialize()
	var broken: Dictionary = module.serialize()
	broken["memories"] = {str(npc_id): {"records": [{"kind": "big", "actors": [], "place_id": "", "time": "ontem", "valence": 0, "salience": 0, "source": "WITNESSED", "confidence": 100}], "traits": []}}
	var refused: Result = module.on_load(broken)
	assert_eq(refused.code, NpcModule.CODE_INVALID_SAVE)
	assert_string_contains(refused.message, "NPC %d" % npc_id)
	assert_string_contains(refused.message, "registro 0")
	assert_string_contains(refused.message, "time")
	assert_eq(module.serialize(), before, "Carga recusada não altera o estado.")
	broken["memories"] = "nada"
	assert_eq(module.on_load(broken).code, NpcModule.CODE_INVALID_SAVE)
	assert_eq(module.serialize(), before)
	world.teardown()


func test_validate_flags_a_memory_that_does_not_fit_the_npcs() -> void:
	var module: NpcModule = _module(CAPACITY, SLOTS)
	var world: World = _world(module)
	var notable: int = _spawn(module)
	var citizen: int = _spawn(module, NORMAL)
	var dead: int = _spawn(module)
	var good_record: Dictionary = _record("big", 90, 0, -80, [PERSON_A]).to_dict()
	var base: Dictionary = module.serialize()
	var entries: Dictionary = base["npcs"]
	var dead_entry: Dictionary = entries[str(dead)]
	dead_entry["is_alive"] = false
	dead_entry["death_cause"] = "hunger"
	dead_entry["died_at"] = 1
	var bad_record: Dictionary = good_record.duplicate()
	bad_record["kind"] = "ghost"
	bad_record["source"] = "RUMOR"
	bad_record["valence"] = 500
	bad_record["salience"] = -1
	bad_record["confidence"] = 101
	bad_record["time"] = -4
	bad_record["actors"] = [PERSON_A, PERSON_B, PERSON_C, notable]
	base["memories"] = {
		str(notable): {"records": [good_record, good_record, good_record, good_record, bad_record], "traits": [{"actor_id": PERSON_A, "valence": 1, "since": 0}, {"actor_id": PERSON_B, "valence": 1, "since": 0}, {"actor_id": 0, "valence": 900, "since": 0}]},
		str(citizen): {"records": [good_record], "traits": []},
		str(dead): {"records": [], "traits": [{"actor_id": PERSON_A, "valence": 5, "since": 0}]},
		"9999": {"records": [good_record], "traits": []},
	}
	assert_true(module.on_load(base).ok, "O formato é aceito; a coerência é do validate().")
	var text: String = "\n".join(module.validate())
	for fragment: String in [
		"NPC 9999, que não existe", "NPC %d: tem 1 registro(s)" % citizen, "cidadão (T1)", "NPC %d: morto, mas com memória" % dead, "5 registros de memória, mais que a capacidade %d" % CAPACITY,
		"3 traços permanentes, mais que o limite %d" % SLOTS, "tipo 'ghost' inexistente", "fonte 'RUMOR'", "tempo -4 negativo", "valência 500 fora de", "saliência -1 fora de", "confiança 101 fora de", "4 pessoas; o máximo é 2",
		"pessoa %d inválida" % notable, "valência 900 fora de",
	]:
		assert_string_contains(text, fragment)
	world.teardown()


func _hash_of_a_busy_run(world_seed: int, save_at_minute: int) -> String:
	var module: NpcModule = _module(4, 3)
	var active_world: World = _world(module, world_seed)
	var ids: Array[int] = []
	for _index: int in 4:
		ids.append(_spawn(module, NOTABLE, "tester"))
	var total_minutes: int = MINUTES_PER_DAY * 3
	var kinds: Array[String] = ["minor", "steady", "big"]
	var minute: int = 0
	var other_world: World = null
	while minute < total_minutes:
		_run(active_world, 97)
		minute += 97
		var round_index: int = IntMath.floor_div(minute, 97)
		var npc_id: int = ids[round_index % ids.size()]
		var people: Array[int] = [PERSON_A + (round_index % 3)]
		assert_true(module.request_record_memory(npc_id, kinds[round_index % kinds.size()], people, "").ok)
		if round_index % 11 == 0:
			assert_true(module.request_demote(npc_id, NORMAL).ok)
			assert_true(module.request_promote(npc_id, NOTABLE).ok)
		if save_at_minute > 0 and other_world == null and minute >= save_at_minute:
			var parsed: Variant = JSON.parse_string(JSON.stringify(active_world.serialize(), "", true, true))
			var saved: Dictionary = parsed
			module = _module(4, 3)
			other_world = _world(module, world_seed)
			var loaded: Result = other_world.on_load(saved)
			assert_true(loaded.ok, loaded.message)
			active_world.teardown()
			active_world = other_world
	var result: String = active_world.state_hash()
	active_world.teardown()
	return result


func test_the_same_seed_gives_the_same_world_with_memories_and_saving_in_the_middle_changes_nothing() -> void:
	var direct: String = _hash_of_a_busy_run(7, 0)
	assert_eq(_hash_of_a_busy_run(7, 0), direct, "Mesma semente, mesmo mundo com memórias, traços e rebaixamentos.")
	assert_eq(_hash_of_a_busy_run(7, MINUTES_PER_DAY), direct, "Salvar e carregar no meio dá o mesmo mundo: a memória vai no save.")
	assert_ne(_hash_of_a_busy_run(8, 0), direct, "Controle: outra semente dá outro mundo.")


# ---------------------------------------------------------------------------------------------------- o dado

func _load_kinds(records: Array[Dictionary]) -> MemoryKindLoader.LoadResult:
	var bundle: DataBundle = DataBundle.new()
	bundle.tables[MemoryKindLoader.KINDS_TABLE] = records
	bundle.file_paths[MemoryKindLoader.KINDS_TABLE] = KINDS_LABEL
	DataValidator.new().validate(bundle, [MemoryKindLoader.build_schema()])
	return MemoryKindLoader.from_bundle(bundle)


func _valid_kind() -> Dictionary:
	return {"id": "quarrel", "valence": -40, "salience": 60, "decay_per_day": 3}


func test_the_real_kinds_file_loads_and_a_bad_kind_fails_pointing_at_file_item_and_field() -> void:
	var loaded: MemoryKindLoader.LoadResult = MemoryKindLoader.load_dir()
	assert_true(loaded.result.ok, loaded.result.message)
	assert_gt(loaded.kinds.size(), 0)
	for kind: MemoryKindLoader.KindDef in loaded.kinds:
		assert_true(kind.valence >= MemoryRecord.MIN_VALENCE and kind.valence <= MemoryRecord.MAX_VALENCE, kind.id)
		assert_true(kind.salience >= MemoryRecord.MIN_SALIENCE and kind.salience <= MemoryRecord.MAX_SALIENCE, kind.id)
		assert_true(kind.decay_per_day >= 0, kind.id)
	var good: MemoryKindLoader.LoadResult = _load_kinds([_valid_kind()])
	assert_true(good.result.ok, good.result.message)
	assert_eq([good.kinds[0].id, good.kinds[0].valence, good.kinds[0].salience, good.kinds[0].decay_per_day], ["quarrel", -40, 60, 3])
	var bad_cases: Array = [
		["valência 101", "valence", 101], ["valência -101", "valence", -101], ["saliência -1", "salience", -1], ["saliência 101", "salience", 101],
		["desgaste -1", "decay_per_day", -1], ["desgaste 101", "decay_per_day", 101], ["valência em texto", "valence", "alta"], ["saliência fracionária", "salience", 1.5],
	]
	for case: Array in bad_cases:
		var record: Dictionary = _valid_kind()
		record[case[1]] = case[2]
		var failed: MemoryKindLoader.LoadResult = _load_kinds([record])
		assert_false(failed.result.ok, "%s: deveria falhar." % case[0])
		assert_eq(failed.result.code, KINDS_ISSUE_CODE)
		assert_string_contains(failed.result.message, case[1])
		assert_string_contains(failed.result.message, KINDS_LABEL)
		assert_string_contains(failed.result.message, "quarrel")
	var missing: Dictionary = _valid_kind()
	missing.erase("salience")
	assert_false(_load_kinds([missing]).result.ok, "Campo ausente falha.")
	assert_false(_load_kinds([_valid_kind(), _valid_kind()]).result.ok, "Id repetido falha.")


func _valid_params_record() -> Dictionary:
	return {
		"id": "default", "urgency_weight_comfortable": 0, "urgency_weight_attention": 1, "urgency_weight_urgent": 3, "urgency_weight_critical": 6,
		"time_cost_per_hour": 2, "distance_cost_per_100m": 2, "risk_cost_percent": 100, "inertia_bonus": 25, "routine_bonus": 40,
		"think_interval_min": 10, "max_thinks_per_step": 20, "decision_top_k": 3, "decision_margin": 15,
	}


func _load_params(record: Dictionary) -> NpcParamsLoader.LoadResult:
	var records: Array[Dictionary] = [record]
	var bundle: DataBundle = DataBundle.new()
	bundle.tables[NpcParamsLoader.PARAMS_TABLE] = records
	bundle.file_paths[NpcParamsLoader.PARAMS_TABLE] = PARAMS_LABEL
	DataValidator.new().validate(bundle, [NpcParamsLoader.build_schema()])
	return NpcParamsLoader.from_bundle(bundle)


func test_the_memory_parameters_come_from_the_data_are_optional_and_are_checked() -> void:
	var real: NpcParams = NpcParamsLoader.load_dir().params
	assert_eq([real.memory_capacity, real.trait_threshold, real.trait_slots], [24, 80, 4], "O arquivo real tem os números do contrato [HIP].")
	var absent: NpcParams = _load_params(_valid_params_record()).params
	assert_eq([absent.memory_capacity, absent.trait_threshold, absent.trait_slots], [0, 100, 0], "Sem os campos: memória não configurada, nenhum registro vira traço.")
	var record: Dictionary = _valid_params_record()
	record["memory_capacity"] = 9
	record["trait_threshold"] = 55
	record["trait_slots"] = 3
	var built: NpcParams = _load_params(record).params
	assert_eq([built.memory_capacity, built.trait_threshold, built.trait_slots], [9, 55, 3])
	var bad_cases: Array = [
		["memory_capacity", -1], ["memory_capacity", NpcParamsLoader.MAX_MEMORY_CAPACITY + 1], ["memory_capacity", "muitas"],
		["trait_threshold", -1], ["trait_threshold", 101], ["trait_slots", -1], ["trait_slots", NpcParamsLoader.MAX_TRAIT_SLOTS + 1],
	]
	for case: Array in bad_cases:
		var invalid: Dictionary = _valid_params_record()
		invalid[case[0]] = case[1]
		var failed: NpcParamsLoader.LoadResult = _load_params(invalid)
		assert_false(failed.result.ok, "%s = %s deveria falhar." % [case[0], str(case[1])])
		assert_eq(failed.result.code, PARAMS_ISSUE_CODE)
		assert_string_contains(failed.result.message, case[0])


## O mundo real: o `NpcSetup` entrega os tipos de memória e os parâmetros do arquivo; cinco notáveis gravam episódios, um dia passa, e o
## mundo continua válido, com todos vivos e a memória de volta no save.
func test_the_real_world_has_the_kinds_loaded_and_notables_remember_through_a_day() -> void:
	var terrain_loaded: TerrainLoader.LoadResult = TerrainLoader.load_dir(WORLD_DIR)
	assert_true(terrain_loaded.result.ok, terrain_loaded.result.message)
	var settlements_loaded: SettlementLoader.LoadResult = SettlementLoader.load_dir(WORLD_DIR, terrain_loaded.terrain)
	assert_true(settlements_loaded.result.ok, settlements_loaded.result.message)
	var setup: NpcSetup = NpcSetup.from_dir(DATA_DIR, SettlementService.new(settlements_loaded.settlements, settlements_loaded.places), true)
	assert_true(setup.result.ok, setup.result.message)
	assert_gt(setup.definitions.memory_kinds.size(), 0, "O NpcSetup entregou os tipos de memória.")
	var game: RealGame = RealGame.new()
	game.runner = SimulationRunner.new(5)
	game.modules = GameModules.register(game.runner, terrain_loaded.terrain, [], setup)
	assert_true(game.modules.result.ok, game.modules.result.message)
	game.runner.start_new_game()
	var ids: Array[int] = game.modules.npc.peek_npc_ids()
	for index: int in 5:
		assert_true(game.modules.npc.request_promote(ids[index], NOTABLE).ok)
		var other: Array[int] = [ids[index + 10]]
		assert_true(game.modules.npc.request_record_memory(ids[index], "help_received", other, "").ok)
	game.runner.run_steps(MINUTES_PER_DAY)
	for index: int in 5:
		var query: NpcModule.MemoriesQuery = game.modules.npc.peek_memories(ids[index], "help_received")
		assert_eq(query.records.size(), 1, "O NPC %d guardou o episódio por um dia." % ids[index])
		assert_eq(query.records[0].actors[0], ids[index + 10])
	assert_gte(game.modules.npc.debug_summary()["memory_records"], 5, "Os 5 episódios gravados aqui, mais os das conversas da noite entre notáveis (LW-080).")
	assert_eq(game.modules.npc.peek_counts()[NpcModule.COUNT_ALIVE], 132)
	assert_eq(game.runner.world.validate().size(), 0, str(game.runner.world.validate()))
	game.runner.finish()
