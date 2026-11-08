extends GutTest
## LW-079: relações entre pessoas (docs/modules/npc.md, seção 7), sem janela. Uma relação por PAR (a chave não depende da ordem de quem
## pergunta), com cinco dimensões de -100 a +100 (afeição, confiança, respeito, medo, dívida) e um rótulo derivado da afeição. Só existe entre quem
## se conheceu e só se um dos lados é notável (T2) vivo ou é o jogador (Q11); cada NPC tem um limite de relações, e ao estourar sai a mais fraca dele
## (nunca a do jogador); o decaimento diário rumo a 0 é preguiçoso e exato; a morte descarta as relações do morto; rebaixar resume as relações com
## cidadãos em traços e arredonda a do jogador. "O jogador" é qualquer ID que não é NPC da tabela: aqui o 9000.

const VILLAGE: String = "village_a"
const HOME: String = "home_a1"
const WORK: String = "work_a1"
const NEED_IDS: Array[String] = ["hunger", "rest", "safety", "income", "social"]
const TRAIT_IDS: Array[String] = ["caution", "sociability", "ambition", "loyalty"]
const HOME_X_CM: int = 8400
const THINK_INTERVAL: int = 10
const NOTABLE: int = NpcState.TIER_NOTABLE
const NORMAL: int = NpcState.TIER_NORMAL
const PLAYER: int = 9000
const OTHER_PLAYER: int = 9001
const MINUTES_PER_DAY: int = 1440
const FRIEND_AT: int = 50
const RIVAL_AT: int = 40
const DATA_DIR: String = "res://data"
const WORLD_DIR: String = "res://data/world"
const PARAMS_LABEL: String = "res://data/npc_params.json"
const PARAMS_ISSUE_CODE: String = "NPC_PARAMS_INVALID"
const AFFECTION: int = NpcRelation.DIM_AFFECTION
const TRUST: int = NpcRelation.DIM_TRUST
const RESPECT: int = NpcRelation.DIM_RESPECT
const FEAR: int = NpcRelation.DIM_FEAR
const DEBT: int = NpcRelation.DIM_DEBT


# ---------------------------------------------------------------------------------------------------- mundo de teste

class RealGame:
	extends RefCounted

	var runner: SimulationRunner
	var modules: GameModules


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
		Place.new(HOME, VILLAGE, Place.KIND_HOME, Vector3(84.0, 0.0, 0.0), 12), Place.new(WORK, VILLAGE, Place.KIND_WORK, Vector3(184.0, 0.0, 0.0), 12),
	]
	return SettlementService.new(settlements, places)


func _params(capacity: int, decay: int, with_memory: bool) -> NpcParams:
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
	params.relations_capacity = capacity
	params.relation_decay_per_day = decay
	params.relation_friend_threshold = FRIEND_AT
	params.relation_rival_threshold = RIVAL_AT
	if with_memory:
		params.memory_capacity = 5
		params.trait_threshold = 80
		params.trait_slots = 3
	return params


## Módulo completo. `capacity` 0 = relações não configuradas. `with_memory` liga a memória (para ver os traços do rebaixamento).
func _module(capacity: int = 8, decay: int = 0, is_development_build: bool = true, with_memory: bool = false, lethal: bool = false) -> NpcModule:
	var definitions: NpcModule.Definitions = NpcModule.Definitions.new()
	definitions.actions = _catalog()
	var traits: Array[TraitLoader.TraitDef] = []
	for position: int in TRAIT_IDS.size():
		traits.append(TraitLoader.TraitDef.new(TRAIT_IDS[position], position))
	definitions.traits = traits
	definitions.params = _params(capacity, decay, with_memory)
	definitions.places = _places()
	definitions.is_development_build = is_development_build
	if with_memory:
		definitions.memory_kinds = [MemoryKindLoader.KindDef.new("big", -80, 90, 0), MemoryKindLoader.KindDef.new("steady", 30, 50, 0)]
	return NpcModule.new(_need_defs(lethal), _routine(), definitions)


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


## As cinco mudanças (afeição, confiança, respeito, medo, dívida).
func _deltas(affection: int, trust: int = 0, respect: int = 0, fear: int = 0, debt: int = 0) -> PackedInt64Array:
	return PackedInt64Array([affection, trust, respect, fear, debt])


func _relate(module: NpcModule, first_id: int, second_id: int, deltas: PackedInt64Array) -> void:
	var adjusted: Result = module.request_adjust_relation(first_id, second_id, deltas)
	assert_true(adjusted.ok, adjusted.message)


func _values(module: NpcModule, first_id: int, second_id: int) -> Array:
	var opinion: NpcModule.OpinionQuery = module.peek_opinion(first_id, second_id)
	var found: Array = []
	for value: int in opinion.values:
		found.append(value)
	return found


func _knows(module: NpcModule, first_id: int, second_id: int) -> bool:
	return module.peek_opinion(first_id, second_id).is_known


## Marca o NPC como morto pelo caminho do save (a morte de verdade, pela fome, tem o seu próprio teste).
func _mark_dead(module: NpcModule, npc_id: int) -> void:
	var saved: Dictionary = module.serialize()
	var entries: Dictionary = saved["npcs"]
	var entry: Dictionary = entries[str(npc_id)]
	entry["is_alive"] = false
	entry["death_cause"] = "hunger"
	entry["died_at"] = 1
	assert_true(module.on_load(saved).ok)


# ---------------------------------------------------------------------------------------------------- contas puras

func test_the_pair_key_decay_and_rounding_are_pure_integer_arithmetic() -> void:
	assert_eq(NpcRelation.make_key(3, 5), NpcRelation.make_key(5, 3), "A chave do par não depende da ordem.")
	assert_ne(NpcRelation.make_key(3, 5), NpcRelation.make_key(3, 6))
	assert_eq(NpcRelation.make_key(12, 4), "4:12")
	assert_eq(NpcRelation.decayed(9, 3, 2), 3)
	assert_eq(NpcRelation.decayed(9, 5, 2), 0, "Positivo para em zero.")
	assert_eq(NpcRelation.decayed(-9, 3, 2), -3)
	assert_eq(NpcRelation.decayed(-9, 50, 2), 0, "Negativo também: nunca passa de zero.")
	assert_eq(NpcRelation.decayed(0, 9, 2), 0)
	assert_eq(NpcRelation.decayed(7, 0, 2), 7, "Zero dias, nada muda.")
	assert_eq(NpcRelation.decayed(7, -4, 2), 7, "Dia negativo conta como zero.")
	assert_eq(NpcRelation.decayed(7, 9, 0), 7, "Sem decaimento configurado, nada decai.")
	assert_eq(NpcRelation.decayed(NpcRelation.decayed(30, 4, 3), 5, 3), NpcRelation.decayed(30, 9, 3), "Decair em dois pedaços dá o mesmo que de uma vez.")
	assert_eq([NpcRelation.rounded(44, 10), NpcRelation.rounded(45, 10), NpcRelation.rounded(5, 10), NpcRelation.rounded(4, 10), NpcRelation.rounded(0, 10)], [40, 50, 10, 0, 0])
	assert_eq([NpcRelation.rounded(-44, 10), NpcRelation.rounded(-45, 10), NpcRelation.rounded(-5, 10), NpcRelation.rounded(-4, 10), NpcRelation.rounded(95, 10)], [-40, -50, -10, 0, 100], "Metade arredonda para longe de zero.")


# ---------------------------------------------------------------------------------------------------- o par, o conhecer-se, as dimensões

func test_a_relation_is_one_per_pair_and_the_order_of_the_question_does_not_matter() -> void:
	var module: NpcModule = _module()
	var world: World = _world(module)
	var first: int = _spawn(module)
	var second: int = _spawn(module, NORMAL)
	_relate(module, first, second, _deltas(10))
	assert_eq(_values(module, first, second), [10, 0, 0, 0, 0])
	assert_eq(_values(module, second, first), [10, 0, 0, 0, 0], "Perguntar ao contrário dá a mesma relação.")
	_relate(module, second, first, _deltas(0, 5))
	assert_eq(_values(module, first, second), [10, 5, 0, 0, 0], "Ajustar ao contrário mexe na MESMA relação.")
	assert_eq(module.debug_summary()["relations"], 1, "Uma relação só para o par.")
	var saved: Array = module.serialize()["relations"]
	assert_eq([saved.size(), saved[0]["a_id"], saved[0]["b_id"]], [1, mini(first, second), maxi(first, second)], "Guardada com o menor ID primeiro.")
	world.teardown()


func test_a_relation_exists_only_between_people_who_met() -> void:
	var module: NpcModule = _module()
	var world: World = _world(module)
	var first: int = _spawn(module)
	var second: int = _spawn(module)
	var third: int = _spawn(module)
	var before: NpcModule.OpinionQuery = module.peek_opinion(first, second)
	assert_true(before.result.ok)
	assert_eq([before.is_known, before.label, before.met_at, before.other_is_alive], [false, "", -1, true], "Nunca se encontraram: não se conhecem.")
	assert_eq(_values(module, first, second), [0, 0, 0, 0, 0])
	_run(world, 40)
	_relate(module, first, second, _deltas(5))
	var met: NpcModule.OpinionQuery = module.peek_opinion(first, second)
	assert_eq([met.is_known, met.met_at, met.label], [true, 40, NpcRelation.LABEL_ACQUAINTANCE])
	_run(world, 100)
	_relate(module, first, second, _deltas(5))
	assert_eq(module.peek_opinion(first, second).met_at, 40, "O momento em que se conheceram não muda.")
	assert_false(_knows(module, first, third), "Quem não se encontrou continua desconhecido.")
	assert_false(_knows(module, second, third))
	world.teardown()


## Q11: só vale se um dos lados é notável vivo ou é o jogador. Cidadão com cidadão, não. Jogador com jogador, não (precisa de um NPC). Morto, não.
func test_only_a_notable_or_the_player_can_have_a_relation() -> void:
	var module: NpcModule = _module()
	var world: World = _world(module)
	var citizen: int = _spawn(module, NORMAL)
	var other_citizen: int = _spawn(module, NORMAL)
	var notable: int = _spawn(module)
	var other_notable: int = _spawn(module)
	var dead: int = _spawn(module)
	_mark_dead(module, dead)
	var before: Dictionary = module.serialize()
	var both_citizens: Result = module.request_adjust_relation(citizen, other_citizen, _deltas(10))
	assert_eq(both_citizens.code, RelationGraph.CODE_NOT_ALLOWED)
	assert_string_contains(both_citizens.message, "cidadãos (T1)")
	assert_eq(module.request_adjust_relation(PLAYER, OTHER_PLAYER, _deltas(10)).code, RelationGraph.CODE_NOT_ALLOWED, "Dois que não são NPCs: nenhum NPC.")
	var with_dead: Result = module.request_adjust_relation(notable, dead, _deltas(10))
	assert_eq(with_dead.code, RelationGraph.CODE_NOT_ALLOWED)
	assert_string_contains(with_dead.message, "morto")
	assert_eq(module.request_adjust_relation(dead, PLAYER, _deltas(10)).code, RelationGraph.CODE_NOT_ALLOWED, "Morto nem com o jogador.")
	assert_eq(module.serialize(), before, "Nenhum pedido recusado alterou o estado.")
	_relate(module, citizen, notable, _deltas(10))
	_relate(module, notable, other_notable, _deltas(10))
	_relate(module, citizen, PLAYER, _deltas(10))
	_relate(module, notable, PLAYER, _deltas(10))
	assert_eq(module.debug_summary()["relations"], 4)
	assert_eq(module.validate().size(), 0, str(module.validate()))
	world.teardown()


func test_invalid_requests_are_refused_and_change_nothing() -> void:
	var module: NpcModule = _module()
	var world: World = _world(module)
	var notable: int = _spawn(module)
	var before: Dictionary = module.serialize()
	var invalid_cases: Array = [
		["a mesma pessoa", notable, notable, _deltas(1)], ["ID zero", 0, notable, _deltas(1)], ["ID negativo", -4, notable, _deltas(1)],
		["ID acima da faixa", IdGenerator.MAX_ID + 1, notable, _deltas(1)], ["quatro mudanças", notable, PLAYER, PackedInt64Array([1, 2, 3, 4])],
		["seis mudanças", notable, PLAYER, PackedInt64Array([1, 2, 3, 4, 5, 6])], ["mudança grande demais", notable, PLAYER, _deltas(0, 0, 0, 0, RelationGraph.MAX_DELTA + 1)],
		["mudança negativa grande demais", notable, PLAYER, _deltas(-RelationGraph.MAX_DELTA - 1)],
	]
	for case: Array in invalid_cases:
		var refused: Result = module.request_adjust_relation(case[1], case[2], case[3])
		assert_eq(refused.code, RelationGraph.CODE_INVALID, "%s: deveria ser recusado." % case[0])
	assert_eq(module.serialize(), before)
	var production: NpcModule = _module(8, 0, false)
	var production_world: World = _world(production)
	var production_npc: int = _spawn(production)
	assert_eq(production.request_adjust_relation(production_npc, PLAYER, _deltas(1)).code, NpcModule.CODE_DEV_ONLY, "O comando de ajuste é de depuração.")
	var unconfigured: NpcModule = _module(0)
	var unconfigured_world: World = _world(unconfigured)
	var unconfigured_npc: int = _spawn(unconfigured)
	assert_eq(unconfigured.request_adjust_relation(unconfigured_npc, PLAYER, _deltas(1)).code, RelationGraph.CODE_NOT_CONFIGURED, "Sem capacidade configurada as relações não estão ligadas.")
	var bare: NpcModule = NpcModule.new()
	var bare_world: World = _world(bare)
	assert_eq(bare.request_adjust_relation(1, PLAYER, _deltas(1)).code, NpcModule.CODE_DEV_ONLY)
	assert_eq(module.peek_opinion(notable, notable).result.code, RelationGraph.CODE_INVALID)
	assert_eq(module.peek_opinion(0, notable).result.code, RelationGraph.CODE_INVALID)
	assert_eq(module.peek_opinion(PLAYER, OTHER_PLAYER).result.code, NpcModule.CODE_UNKNOWN, "Pelo menos um dos dois precisa ser NPC.")
	var with_player: NpcModule.OpinionQuery = module.peek_opinion(notable, PLAYER)
	assert_true(with_player.result.ok)
	assert_true(with_player.other_is_alive, "Quem não é NPC conta como vivo.")
	world.teardown()
	production_world.teardown()
	unconfigured_world.teardown()
	bare_world.teardown()


func test_each_dimension_accumulates_on_its_own_and_stays_within_100() -> void:
	var module: NpcModule = _module()
	var world: World = _world(module)
	var notable: int = _spawn(module)
	_relate(module, notable, PLAYER, _deltas(60, 30, -20, -40, 5))
	assert_eq(_values(module, notable, PLAYER), [60, 30, -20, -40, 5])
	_relate(module, notable, PLAYER, _deltas(60, 0, 0, -200, -10))
	assert_eq(_values(module, notable, PLAYER), [100, 30, -20, -100, -5], "Cada uma para em ±100 sem afetar as outras.")
	_relate(module, notable, PLAYER, _deltas(-200, -200, 200, 200, 0))
	assert_eq(_values(module, notable, PLAYER), [-100, -100, 100, 100, -5])
	world.teardown()


func test_the_label_comes_from_the_affection_and_the_thresholds() -> void:
	var module: NpcModule = _module()
	var world: World = _world(module)
	var notable: int = _spawn(module)
	var labels: Array[String] = []
	for affection: int in [FRIEND_AT - 1, FRIEND_AT]:
		var person: int = PLAYER + labels.size()
		_relate(module, notable, person, _deltas(affection))
		labels.append(module.peek_opinion(notable, person).label)
	assert_eq(labels, [NpcRelation.LABEL_ACQUAINTANCE, NpcRelation.LABEL_FRIEND], "49 ainda é conhecido; 50 já é amigo.")
	var rivals: Array[String] = []
	for affection: int in [-(RIVAL_AT - 1), -RIVAL_AT]:
		var person: int = PLAYER + 10 + rivals.size()
		_relate(module, notable, person, _deltas(affection))
		rivals.append(module.peek_opinion(notable, person).label)
	assert_eq(rivals, [NpcRelation.LABEL_ACQUAINTANCE, NpcRelation.LABEL_RIVAL], "-39 ainda é conhecido; -40 já é rival (o limiar de rival é diferente do de amigo).")
	var friend: NpcModule.OpinionQuery = module.peek_opinion(PLAYER + 1, notable)
	assert_eq(friend.label, NpcRelation.LABEL_FRIEND, "O rótulo também sai perguntando ao contrário.")
	var rules: RelationGraph.Rules = RelationGraph.Rules.new(8, 0, 0, 0)
	assert_eq(RelationGraph.label_for(100, rules), NpcRelation.LABEL_ACQUAINTANCE, "Limiar 0 desliga o rótulo de amigo.")
	assert_eq(RelationGraph.label_for(-100, rules), NpcRelation.LABEL_ACQUAINTANCE, "E o de rival.")
	world.teardown()


# ---------------------------------------------------------------------------------------------------- decaimento diário

## Decaimento 2 por dia. Afeição +9 e confiança -5 no dia 0; no dia 3: afeição 3 e confiança 0 (-5 + 6 passaria de zero: para em 0); no dia 5: tudo 0.
func test_decay_is_daily_toward_zero_and_never_crosses_it() -> void:
	var module: NpcModule = _module(8, 2)
	var world: World = _world(module)
	var notable: int = _spawn(module)
	_relate(module, notable, PLAYER, _deltas(9, -5))
	_run(world, MINUTES_PER_DAY - 1)
	assert_eq(_values(module, notable, PLAYER), [9, -5, 0, 0, 0], "Ainda é o dia 0: nada decaiu.")
	_run(world, 1)
	assert_eq(_values(module, notable, PLAYER), [7, -3, 0, 0, 0], "Virou o dia 1: -2 em cada dimensão.")
	_run(world, MINUTES_PER_DAY * 2)
	assert_eq(_values(module, notable, PLAYER), [3, 0, 0, 0, 0], "Dia 3: a confiança parou em zero.")
	_run(world, MINUTES_PER_DAY * 2)
	assert_eq(_values(module, notable, PLAYER), [0, 0, 0, 0, 0], "Dia 5: tudo zerado, mas a relação continua (se conhecem).")
	assert_true(_knows(module, notable, PLAYER))
	world.teardown()


func test_looking_does_not_change_the_state_and_adjusting_settles_the_decay_first() -> void:
	var module: NpcModule = _module(8, 2)
	var world: World = _world(module)
	var notable: int = _spawn(module)
	_relate(module, notable, PLAYER, _deltas(9))
	_run(world, MINUTES_PER_DAY * 3)
	var before: Dictionary = module.serialize()
	assert_eq(_values(module, notable, PLAYER), [3, 0, 0, 0, 0])
	assert_eq(module.serialize(), before, "Consultar com decaimento pendente não grava nada.")
	_relate(module, notable, PLAYER, _deltas(10))
	assert_eq(_values(module, notable, PLAYER), [13, 0, 0, 0, 0], "O decaimento (9 -> 3) veio antes da soma (+10).")
	var saved: Array = module.serialize()["relations"]
	assert_eq(saved[0]["updated_day"], 3)
	world.teardown()


## O mesmo fim por dois caminhos: um mundo mexe na relação todo dia (com mudança zero), o outro só no fim.
func test_the_decay_gives_the_same_result_however_often_it_is_touched() -> void:
	var touched: NpcModule = _module(8, 3)
	var touched_world: World = _world(touched)
	var rested: NpcModule = _module(8, 3)
	var rested_world: World = _world(rested)
	var touched_npc: int = _spawn(touched)
	var rested_npc: int = _spawn(rested)
	_relate(touched, touched_npc, PLAYER, _deltas(50, -40, 25, 0, 100))
	_relate(rested, rested_npc, PLAYER, _deltas(50, -40, 25, 0, 100))
	for _day: int in 6:
		_run(touched_world, MINUTES_PER_DAY)
		_relate(touched, touched_npc, PLAYER, _deltas(0))
	_run(rested_world, MINUTES_PER_DAY * 6)
	assert_eq(_values(touched, touched_npc, PLAYER), _values(rested, rested_npc, PLAYER), "Tocar todo dia ou só no fim: mesma relação.")
	assert_eq(_values(rested, rested_npc, PLAYER), [32, -22, 7, 0, 82])
	touched_world.teardown()
	rested_world.teardown()


# ---------------------------------------------------------------------------------------------------- limite por NPC

## Capacidade 2, sem decaimento. X tem uma relação fraca (soma 10) com P e uma forte (soma 30) com Q; a terceira (com R) tira a de P.
func test_a_new_relation_pushes_out_the_weakest_of_the_full_npc() -> void:
	var module: NpcModule = _module(2)
	var world: World = _world(module)
	var keeper: int = _spawn(module)
	var weak: int = _spawn(module, NORMAL)
	var strong: int = _spawn(module, NORMAL)
	var newest: int = _spawn(module, NORMAL)
	var elsewhere: int = _spawn(module)
	_relate(module, keeper, weak, _deltas(10))
	_relate(module, keeper, strong, _deltas(10, 10, 10))
	_relate(module, weak, elsewhere, _deltas(5))
	_relate(module, keeper, newest, _deltas(1))
	assert_false(_knows(module, keeper, weak), "A mais fraca do NPC cheio saiu.")
	assert_false(_knows(module, weak, keeper), "Para os dois lados.")
	assert_true(_knows(module, keeper, strong))
	assert_true(_knows(module, keeper, newest))
	assert_true(_knows(module, weak, elsewhere), "As relações do outro lado com terceiros não foram tocadas.")
	assert_eq(module.validate().size(), 0, str(module.validate()))
	world.teardown()


## Empate de soma: sai a mais antiga (conhecida antes). Decaimento 5 por dia: P começou mais forte (20), mas no dia 3 vale 5 e Q (12 no dia 2) vale 7.
func test_the_weakest_is_judged_after_the_decay_and_a_tie_sends_out_the_oldest() -> void:
	var tied: NpcModule = _module(2)
	var tied_world: World = _world(tied)
	var tied_owner: int = _spawn(tied)
	var first_met: int = _spawn(tied, NORMAL)
	var second_met: int = _spawn(tied, NORMAL)
	var third_met: int = _spawn(tied, NORMAL)
	_relate(tied, tied_owner, first_met, _deltas(10))
	_run(tied_world, 5)
	_relate(tied, tied_owner, second_met, _deltas(10))
	_relate(tied, tied_owner, third_met, _deltas(10))
	assert_false(_knows(tied, tied_owner, first_met), "Empate: saiu a conhecida primeiro.")
	assert_true(_knows(tied, tied_owner, second_met))
	var module: NpcModule = _module(2, 5)
	var world: World = _world(module)
	var keeper: int = _spawn(module)
	var older: int = _spawn(module, NORMAL)
	var newer: int = _spawn(module, NORMAL)
	var latest: int = _spawn(module, NORMAL)
	_relate(module, keeper, older, _deltas(20))
	_run(world, MINUTES_PER_DAY * 2)
	_relate(module, keeper, newer, _deltas(12))
	_run(world, MINUTES_PER_DAY)
	assert_eq(_values(module, keeper, older), [5, 0, 0, 0, 0])
	assert_eq(_values(module, keeper, newer), [7, 0, 0, 0, 0])
	_relate(module, keeper, latest, _deltas(1))
	assert_false(_knows(module, keeper, older), "A que começou mais forte, mas decaiu mais, é a mais fraca hoje.")
	assert_true(_knows(module, keeper, newer))
	tied_world.teardown()
	world.teardown()


func test_the_relation_with_the_player_is_never_pushed_out() -> void:
	var module: NpcModule = _module(2)
	var world: World = _world(module)
	var keeper: int = _spawn(module)
	var other: int = _spawn(module, NORMAL)
	var newest: int = _spawn(module, NORMAL)
	_relate(module, keeper, PLAYER, _deltas(1))
	_relate(module, keeper, other, _deltas(50, 50))
	_relate(module, keeper, newest, _deltas(2))
	assert_true(_knows(module, keeper, PLAYER), "A do jogador, a mais fraca de todas, fica.")
	assert_false(_knows(module, keeper, other), "Sai a mais fraca das que podem sair.")
	assert_true(_knows(module, keeper, newest))
	world.teardown()


## Capacidade 1. Os dois lados da relação nova estão cheios: saem uma de cada. Depois, se um deles só tem relação com o jogador, o pedido é
## recusado e NADA sai do outro lado (tudo ou nada).
func test_both_full_sides_each_lose_one_and_a_side_that_cannot_lose_refuses_everything() -> void:
	var module: NpcModule = _module(1)
	var world: World = _world(module)
	var left: int = _spawn(module)
	var right: int = _spawn(module)
	var left_friend: int = _spawn(module, NORMAL)
	var right_friend: int = _spawn(module, NORMAL)
	_relate(module, left, left_friend, _deltas(10))
	_relate(module, right, right_friend, _deltas(10))
	_relate(module, left, right, _deltas(5))
	assert_true(_knows(module, left, right))
	assert_false(_knows(module, left, left_friend), "Saiu uma de cada lado.")
	assert_false(_knows(module, right, right_friend))
	var guarded: int = _spawn(module)
	var holder: int = _spawn(module)
	var holder_friend: int = _spawn(module, NORMAL)
	_relate(module, guarded, PLAYER, _deltas(1))
	_relate(module, holder, holder_friend, _deltas(10))
	var before: Dictionary = module.serialize()
	var refused: Result = module.request_adjust_relation(holder, guarded, _deltas(5))
	assert_eq(refused.code, RelationGraph.CODE_LIMIT_REACHED)
	assert_string_contains(refused.message, str(guarded))
	assert_true(_knows(module, holder, holder_friend), "O lado que podia sair não perdeu nada.")
	assert_eq(module.serialize(), before, "Recusado: nada mudou.")
	world.teardown()


## O que pesa é o tamanho: ódio e medo (valores negativos) pesam tanto quanto amor. Capacidade 2: a relação com -40 de afeição e -10 de confiança pesa
## 50; a com +10 de afeição pesa 10 e é a que sai.
func test_the_strength_counts_negative_values_by_their_size() -> void:
	var module: NpcModule = _module(2)
	var world: World = _world(module)
	var keeper: int = _spawn(module)
	var hated: int = _spawn(module, NORMAL)
	var liked: int = _spawn(module, NORMAL)
	var newest: int = _spawn(module, NORMAL)
	_relate(module, keeper, hated, _deltas(-40, -10))
	_relate(module, keeper, liked, _deltas(10))
	_relate(module, keeper, newest, _deltas(1))
	assert_true(_knows(module, keeper, hated), "A de ódio pesa 50 e fica.")
	assert_false(_knows(module, keeper, liked), "A de +10 pesa menos e sai.")
	world.teardown()


func test_a_relation_that_already_exists_never_needs_a_slot() -> void:
	var module: NpcModule = _module(1)
	var world: World = _world(module)
	var keeper: int = _spawn(module)
	var friend: int = _spawn(module, NORMAL)
	_relate(module, keeper, friend, _deltas(10))
	_relate(module, keeper, friend, _deltas(10))
	assert_eq(_values(module, keeper, friend), [20, 0, 0, 0, 0], "Ajustar a que já existe com o NPC cheio funciona.")
	assert_eq(module.debug_summary()["relations"], 1)
	world.teardown()


# ---------------------------------------------------------------------------------------------------- morte, remoção e rebaixamento

## X morre de fome (72 h) e Y não (fome começa em 0). As relações de X somem (com Y e com o jogador); a de Y com Z fica; perguntar de Y sobre X diz
## que X morreu. Os outros dois NPCs vivos seguem normais.
func test_death_discards_the_relations_of_the_dead_and_keeps_the_others() -> void:
	var module: NpcModule = _module(8, 0, true, false, true)
	var world: World = _world(module)
	var dying: int = _spawn(module)
	var living: int = _spawn(module)
	var third: int = _spawn(module, NORMAL)
	var saved: Dictionary = module.serialize()
	var entries: Dictionary = saved["npcs"]
	var living_entry: Dictionary = entries[str(living)]
	var living_needs: Array = living_entry["need_values"]
	living_needs[0] = 0
	var third_entry: Dictionary = entries[str(third)]
	var third_needs: Array = third_entry["need_values"]
	third_needs[0] = 0
	assert_true(module.on_load(saved).ok)
	_relate(module, dying, living, _deltas(30))
	_relate(module, dying, PLAYER, _deltas(20))
	_relate(module, living, third, _deltas(15))
	assert_eq(module.debug_summary()["relations"], 3)
	_run(world, 72 * 60 + 40)
	assert_false(module.peek_npc(dying).is_alive)
	assert_true(module.peek_npc(living).is_alive)
	assert_false(_knows(module, dying, living), "As relações do morto sumiram.")
	assert_false(_knows(module, living, dying))
	assert_false(_knows(module, dying, PLAYER))
	assert_true(_knows(module, living, third), "As dos outros ficam.")
	var about_the_dead: NpcModule.OpinionQuery = module.peek_opinion(living, dying)
	assert_true(about_the_dead.result.ok)
	assert_eq([about_the_dead.is_known, about_the_dead.other_is_alive], [false, false], "Sem relação, mas dizendo que o outro morreu.")
	assert_true(module.peek_opinion(dying, living).other_is_alive, "E de volta o vivo é o Y.")
	assert_eq(module.request_adjust_relation(living, dying, _deltas(5)).code, RelationGraph.CODE_NOT_ALLOWED, "Ninguém cria relação com morto.")
	assert_eq(module.validate().size(), 0, str(module.validate()))
	world.teardown()


func test_removing_an_npc_discards_its_relations_and_the_others_keep_theirs() -> void:
	var module: NpcModule = _module()
	var world: World = _world(module)
	var removed: int = _spawn(module)
	var kept: int = _spawn(module)
	var friend: int = _spawn(module, NORMAL)
	_relate(module, removed, friend, _deltas(10))
	_relate(module, removed, PLAYER, _deltas(10))
	_relate(module, kept, friend, _deltas(10))
	assert_true(module.request_remove_npc(removed).ok)
	assert_eq(module.debug_summary()["relations"], 1)
	assert_true(_knows(module, kept, friend))
	assert_eq(module.validate().size(), 0, str(module.validate()))
	world.teardown()


## X (notável) tem relação com: Y (notável), Z e W (cidadãos) e o jogador. Rebaixar X: as com Z (+60 afeição) e W (-30) deixam de valer (cidadão com
## cidadão não pode) e viram traços de X; a com Y fica; a com o jogador fica e é arredondada para múltiplos de 10.
func test_demoting_summarizes_the_relations_with_citizens_and_rounds_the_players() -> void:
	var module: NpcModule = _module(8, 0, true, true)
	var world: World = _world(module)
	var demoted: int = _spawn(module)
	var notable_friend: int = _spawn(module)
	var citizen_one: int = _spawn(module, NORMAL)
	var citizen_two: int = _spawn(module, NORMAL)
	_relate(module, demoted, notable_friend, _deltas(40))
	_relate(module, demoted, citizen_one, _deltas(60, 20))
	_relate(module, demoted, citizen_two, _deltas(-30))
	_relate(module, demoted, PLAYER, _deltas(44, 26, 5, -14, 95))
	assert_true(module.request_demote(demoted, NORMAL).ok)
	assert_false(_knows(module, demoted, citizen_one), "A relação com cidadão saiu (dos dois lados).")
	assert_false(_knows(module, citizen_two, demoted))
	assert_eq(_values(module, demoted, notable_friend), [40, 0, 0, 0, 0], "A com outro notável ficou como estava.")
	assert_eq(_values(module, demoted, PLAYER), [40, 30, 10, -10, 100], "A do jogador ficou, arredondada para múltiplos de 10.")
	var traits: Array = []
	for memory_trait: NpcMemory.Trait in module.peek_memories(demoted).traits:
		traits.append([memory_trait.actor_id, memory_trait.valence])
	assert_eq(traits, [[citizen_one, 60], [citizen_two, -30]], "A afeição de cada relação que saiu virou traço, a mais forte primeiro.")
	assert_eq(module.validate().size(), 0, str(module.validate()))
	assert_true(module.request_promote(demoted, NOTABLE).ok)
	assert_false(_knows(module, demoted, citizen_one), "Promover de novo não recria a relação.")
	assert_eq(module.peek_memories(demoted).traits.size(), 2, "E os traços continuam, sem duplicar.")
	_relate(module, demoted, citizen_one, _deltas(5))
	assert_true(_knows(module, demoted, citizen_one), "Notável de novo, pode se relacionar com cidadão.")
	world.teardown()


## Os registros de memória e as relações somam no mesmo traço: o registro `big` (-80) com Z e a relação com Z (+60, decaída 2 pontos em 2 dias
## de decaimento 1 por dia = +58) dão o traço -22.
func test_demoting_adds_the_relation_to_what_the_memory_already_says_about_the_person() -> void:
	var module: NpcModule = _module(8, 1, true, true)
	var world: World = _world(module)
	var demoted: int = _spawn(module)
	var citizen: int = _spawn(module, NORMAL)
	assert_true(module.request_record_memory(demoted, "big", [citizen], "").ok)
	_relate(module, demoted, citizen, _deltas(60))
	_run(world, MINUTES_PER_DAY * 2)
	assert_true(module.request_demote(demoted, NORMAL).ok)
	var traits: Array = []
	for memory_trait: NpcMemory.Trait in module.peek_memories(demoted).traits:
		traits.append([memory_trait.actor_id, memory_trait.valence])
	assert_eq(traits, [[citizen, -22]], "-80 do registro + 58 da relação (60 menos 2 de decaimento).")
	world.teardown()


func test_demoting_without_the_memory_configured_still_drops_the_invalid_relations() -> void:
	var module: NpcModule = _module(8, 0, true, false)
	var world: World = _world(module)
	var demoted: int = _spawn(module)
	var citizen: int = _spawn(module, NORMAL)
	_relate(module, demoted, citizen, _deltas(60))
	_relate(module, demoted, PLAYER, _deltas(14))
	assert_true(module.request_demote(demoted, NORMAL).ok)
	assert_false(_knows(module, demoted, citizen), "Sem onde guardar traços, a relação sai do mesmo jeito.")
	assert_eq(_values(module, demoted, PLAYER), [10, 0, 0, 0, 0])
	assert_eq(module.peek_memories(demoted).traits.size(), 0)
	assert_eq(module.validate().size(), 0, str(module.validate()))
	world.teardown()


# ---------------------------------------------------------------------------------------------------- save, validate e determinismo

func test_the_relations_go_into_the_save_and_back_and_an_old_save_loads_without_them() -> void:
	var module: NpcModule = _module(8, 1)
	var world: World = _world(module)
	var first: int = _spawn(module)
	var second: int = _spawn(module, NORMAL)
	_relate(module, first, second, _deltas(30, -20, 10, 5, -90))
	_relate(module, first, PLAYER, _deltas(70))
	_run(world, MINUTES_PER_DAY)
	var parsed: Variant = JSON.parse_string(JSON.stringify(world.serialize(), "", true, true))
	var saved: Dictionary = parsed
	var other: NpcModule = _module(8, 1)
	var other_world: World = _world(other)
	assert_true(other_world.on_load(saved).ok)
	assert_eq(_values(other, first, second), _values(module, first, second))
	assert_eq(_values(other, PLAYER, first), _values(module, first, PLAYER))
	assert_eq(other_world.state_hash(), world.state_hash(), "Mesmo estado, mesmo hash.")
	assert_eq(other.validate().size(), 0, str(other.validate()))
	var old_save: Dictionary = module.serialize()
	old_save.erase("relations")
	assert_true(module.on_load(old_save).ok, "Save de antes da LW-079 carrega.")
	assert_eq(module.debug_summary()["relations"], 0)
	world.teardown()
	other_world.teardown()


func test_a_broken_relation_in_the_save_is_refused_and_the_module_stays_as_it_was() -> void:
	var module: NpcModule = _module()
	var world: World = _world(module)
	var notable: int = _spawn(module)
	_relate(module, notable, PLAYER, _deltas(10))
	var before: Dictionary = module.serialize()
	var good: Dictionary = {"a_id": 1, "b_id": 2, "values": [0, 0, 0, 0, 0], "met_at": 0, "updated_day": 0}
	var bad_cases: Array = [
		["lista que não é lista", "nada", "não é uma lista"],
		["relação que não é objeto", [5], "relação 0"],
		["sem a_id", [{"b_id": 2, "values": [0, 0, 0, 0, 0], "met_at": 0, "updated_day": 0}], "a_id"],
		["dimensões em número errado", [{"a_id": 1, "b_id": 2, "values": [0, 0, 0, 0], "met_at": 0, "updated_day": 0}], "values"],
		["dimensão em texto", [{"a_id": 1, "b_id": 2, "values": [0, 0, "x", 0, 0], "met_at": 0, "updated_day": 0}], "values"],
		["met_at fracionário", [{"a_id": 1, "b_id": 2, "values": [0, 0, 0, 0, 0], "met_at": 1.5, "updated_day": 0}], "met_at"],
		["par fora de ordem", [{"a_id": 5, "b_id": 2, "values": [0, 0, 0, 0, 0], "met_at": 0, "updated_day": 0}], "fora de ordem"],
		["par repetido", [good, good], "duas vezes"],
	]
	for case: Array in bad_cases:
		var broken: Dictionary = module.serialize()
		broken["relations"] = case[1]
		var refused: Result = module.on_load(broken)
		assert_eq(refused.code, NpcModule.CODE_INVALID_SAVE, "%s: deveria ser recusado." % case[0])
		assert_string_contains(refused.message, case[2], str(case[0]))
		assert_eq(module.serialize(), before, "%s: o módulo ficou como estava." % case[0])
	world.teardown()


func test_validate_flags_relations_that_do_not_fit_the_npcs() -> void:
	var module: NpcModule = _module(2)
	var world: World = _world(module)
	var notable: int = _spawn(module)
	var citizen: int = _spawn(module, NORMAL)
	var other_citizen: int = _spawn(module, NORMAL)
	var dead: int = _spawn(module)
	var saved: Dictionary = module.serialize()
	var entries: Dictionary = saved["npcs"]
	var dead_entry: Dictionary = entries[str(dead)]
	dead_entry["is_alive"] = false
	dead_entry["death_cause"] = "hunger"
	dead_entry["died_at"] = 1
	var make: Callable = func(first: int, second: int, values: Array, met_at: int = 0, updated_day: int = 0) -> Dictionary:
		return {"a_id": first, "b_id": second, "values": values, "met_at": met_at, "updated_day": updated_day}
	var zeros: Array = [0, 0, 0, 0, 0]
	saved["relations"] = [
		make.call(mini(citizen, other_citizen), maxi(citizen, other_citizen), zeros),
		make.call(mini(notable, dead), maxi(notable, dead), zeros),
		make.call(PLAYER, OTHER_PLAYER, zeros),
		make.call(mini(notable, PLAYER), maxi(notable, PLAYER), [101, 0, 0, 0, -200]),
		make.call(mini(notable, citizen), maxi(notable, citizen), zeros, -3, 99),
		make.call(mini(notable, other_citizen), maxi(notable, other_citizen), zeros),
		make.call(7, 7, zeros),
		make.call(0, 5, zeros),
	]
	assert_true(module.on_load(saved).ok, "O formato é aceito; a coerência é do validate().")
	var text: String = "\n".join(module.validate())
	for fragment: String in [
		"os dois são cidadãos (T1)", "o NPC %d está morto" % dead, "nenhum dos dois é um NPC", "affection 101 fora de -100 a 100", "debt -200 fora de -100 a 100",
		"met_at -3 negativo", "updated_day 99 fora de 0 a hoje", "NPC %d: 4 relações, mais que o limite 2" % notable, "o par é de uma pessoa com ela mesma", "ID 0 fora da faixa",
	]:
		assert_string_contains(text, fragment)
	world.teardown()


func _hash_of_a_busy_run(world_seed: int, save_at_minute: int) -> String:
	var module: NpcModule = _module(3, 1)
	var active_world: World = _world(module, world_seed)
	var ids: Array[int] = []
	for _index: int in 5:
		ids.append(_spawn(module, NOTABLE, "tester"))
	var citizens: Array[int] = []
	for _index: int in 3:
		citizens.append(_spawn(module, NORMAL, "tester"))
	var minute: int = 0
	var other_world: World = null
	while minute < MINUTES_PER_DAY * 3:
		_run(active_world, 89)
		minute += 89
		var round_index: int = IntMath.floor_div(minute, 89)
		var first: int = ids[round_index % ids.size()]
		var partner: int = citizens[round_index % citizens.size()] if round_index % 2 == 0 else ids[(round_index + 2) % ids.size()]
		var changed: Result = module.request_adjust_relation(first, partner, _deltas(7 + round_index % 5, round_index % 3 - 1, 0, -(round_index % 4), 2))
		assert_true(changed.ok, changed.message)
		assert_true(module.request_adjust_relation(first, PLAYER + round_index % 2, _deltas(1)).ok)
		if round_index % 13 == 0:
			assert_true(module.request_demote(first, NORMAL).ok)
			assert_true(module.request_promote(first, NOTABLE).ok)
		if save_at_minute > 0 and other_world == null and minute >= save_at_minute:
			var parsed: Variant = JSON.parse_string(JSON.stringify(active_world.serialize(), "", true, true))
			var saved: Dictionary = parsed
			module = _module(3, 1)
			other_world = _world(module, world_seed)
			var loaded: Result = other_world.on_load(saved)
			assert_true(loaded.ok, loaded.message)
			active_world.teardown()
			active_world = other_world
	assert_eq(module.validate().size(), 0, str(module.validate()))
	var result: String = active_world.state_hash()
	active_world.teardown()
	return result


func test_the_same_seed_gives_the_same_world_with_relations_and_saving_in_the_middle_changes_nothing() -> void:
	var direct: String = _hash_of_a_busy_run(7, 0)
	assert_eq(_hash_of_a_busy_run(7, 0), direct, "Mesma semente, mesmo mundo com relações, decaimento, limite e rebaixamentos.")
	assert_eq(_hash_of_a_busy_run(7, MINUTES_PER_DAY), direct, "Salvar e carregar no meio dá o mesmo mundo: as relações entram no hash.")
	assert_ne(_hash_of_a_busy_run(8, 0), direct, "Controle: outra semente dá outro mundo.")


# ---------------------------------------------------------------------------------------------------- o dado e o mundo real

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


func test_the_relation_parameters_come_from_the_data_are_optional_and_are_checked() -> void:
	var real: NpcParams = NpcParamsLoader.load_dir().params
	assert_eq([real.relations_capacity, real.relation_decay_per_day, real.relation_friend_threshold, real.relation_rival_threshold], [16, 1, 50, 50], "O arquivo real tem os números do contrato [HIP].")
	var absent: NpcParams = _load_params(_valid_params_record()).params
	assert_eq([absent.relations_capacity, absent.relation_decay_per_day, absent.relation_friend_threshold, absent.relation_rival_threshold], [0, 0, 0, 0], "Sem os campos: relações não configuradas.")
	var record: Dictionary = _valid_params_record()
	record["relations_capacity"] = 9
	record["relation_decay_per_day"] = 3
	record["relation_friend_threshold"] = 60
	record["relation_rival_threshold"] = 40
	var built: NpcParams = _load_params(record).params
	assert_eq([built.relations_capacity, built.relation_decay_per_day, built.relation_friend_threshold, built.relation_rival_threshold], [9, 3, 60, 40])
	var bad_cases: Array = [
		["relations_capacity", -1], ["relations_capacity", NpcParamsLoader.MAX_RELATIONS_CAPACITY + 1], ["relations_capacity", "muitas"],
		["relation_decay_per_day", -1], ["relation_decay_per_day", 101], ["relation_friend_threshold", -1], ["relation_friend_threshold", 101],
		["relation_rival_threshold", -1], ["relation_rival_threshold", 101],
	]
	for case: Array in bad_cases:
		var invalid: Dictionary = _valid_params_record()
		invalid[case[0]] = case[1]
		var failed: NpcParamsLoader.LoadResult = _load_params(invalid)
		assert_false(failed.result.ok, "%s = %s deveria falhar." % [case[0], str(case[1])])
		assert_eq(failed.result.code, PARAMS_ISSUE_CODE)
		assert_string_contains(failed.result.message, case[0])


## O mundo real: cinco notáveis se relacionam entre si e com o jogador, três dias passam (decaimento de 1 por dia), tudo continua válido.
func test_the_real_world_relations_decay_over_three_days_and_the_world_stays_valid() -> void:
	var terrain_loaded: TerrainLoader.LoadResult = TerrainLoader.load_dir(WORLD_DIR)
	assert_true(terrain_loaded.result.ok, terrain_loaded.result.message)
	var settlements_loaded: SettlementLoader.LoadResult = SettlementLoader.load_dir(WORLD_DIR, terrain_loaded.terrain)
	assert_true(settlements_loaded.result.ok, settlements_loaded.result.message)
	var setup: NpcSetup = NpcSetup.from_dir(DATA_DIR, SettlementService.new(settlements_loaded.settlements, settlements_loaded.places), true)
	assert_true(setup.result.ok, setup.result.message)
	var game: RealGame = RealGame.new()
	game.runner = SimulationRunner.new(5)
	game.modules = GameModules.register(game.runner, terrain_loaded.terrain, [], setup)
	assert_true(game.modules.result.ok, game.modules.result.message)
	game.runner.start_new_game()
	var npc: NpcModule = game.modules.npc
	var ids: Array[int] = npc.peek_npc_ids()
	for index: int in 5:
		assert_true(npc.request_promote(ids[index], NOTABLE).ok)
	_relate(npc, ids[1], PLAYER, _deltas(20, 10))
	_relate(npc, ids[0], ids[50], _deltas(55))
	_relate(npc, ids[2], PLAYER, _deltas(-60))
	assert_eq(npc.peek_opinion(ids[0], ids[50]).label, NpcRelation.LABEL_FRIEND)
	assert_eq(npc.request_adjust_relation(ids[60], ids[61], _deltas(5)).code, RelationGraph.CODE_NOT_ALLOWED, "Dois cidadãos do mundo real: recusado.")
	game.runner.run_steps(MINUTES_PER_DAY * 3)
	assert_eq(_values(npc, ids[1], PLAYER), [17, 7, 0, 0, 0], "Três dias de decaimento de 1 por dia.")
	assert_eq(npc.peek_opinion(ids[0], ids[50]).label, NpcRelation.LABEL_FRIEND, "55 - 3 = 52, ainda acima do limiar de 50.")
	assert_eq(npc.peek_opinion(ids[2], PLAYER).values[AFFECTION], -57)
	assert_eq(npc.peek_counts()[NpcModule.COUNT_ALIVE], 100)
	assert_gte(npc.debug_summary()["relations"], 3, "As 3 criadas aqui, mais as que as conversas da noite entre notáveis criaram (LW-080).")
	assert_eq(game.runner.world.validate().size(), 0, str(game.runner.world.validate()))
	game.runner.finish()
