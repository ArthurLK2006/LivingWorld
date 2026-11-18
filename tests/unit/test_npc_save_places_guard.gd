extends GutTest
## LW-098h5-G (AGENTS 12.6, opção B de Arthur em 18/11/2026): `NpcPersistence.on_load` NÃO carrega em silêncio um save cujos NPCs VIVOS citam casa ou local que não existe nos dados
## (`home_place_id`, `work_place_id`, `place_id`, `action_target_place_id`). A recusa é `NPC_INVALID_SAVE` com mensagem clara (quantas referências, as primeiras com NPC, campo e local, e a causa provável),
## o módulo fica EXATAMENTE como estava, o NPC morto e o campo vazio (em trânsito, sem alvo, sem local de trabalho) passam, o save válido faz ida e volta idêntica e, sem `places`, nada é conferido.
## Módulo de teste montado à mão; o jogo real com disco e md5 fica em tests/integration/test_save_places_guard.gd.

const VILLAGE: String = "village_a"
const HOME_1: String = "home_a1"
const HOME_2: String = "home_a2"
const WORK: String = "work_a1"
const MARKET: String = "market_a1"
const NEED_IDS: Array[String] = ["hunger", "rest", "safety", "income", "social"]
const TRAIT_IDS: Array[String] = ["caution", "sociability", "ambition", "loyalty"]
const HOME_X_CM: int = 8400
const CAUSE_PHRASE: String = "o save foi feito com outros dados do jogo"
const RESTORE_PHRASE: String = "restaure os dados com que o save foi criado"

var _worlds: Array[World] = []


# ---------------------------------------------------------------------------------------------------- mundo de teste

func _places() -> SettlementService:
	var settlements: Array[Settlement] = [Settlement.new(VILLAGE, "settlement.a", Vector3.ZERO)]
	var places: Array[Place] = [
		Place.new(HOME_1, VILLAGE, Place.KIND_HOME, Vector3(84.0, 0.0, 0.0), 8), Place.new(HOME_2, VILLAGE, Place.KIND_HOME, Vector3(94.0, 0.0, 0.0), 8),
		Place.new(WORK, VILLAGE, Place.KIND_WORK, Vector3(184.0, 0.0, 0.0), 8), Place.new(MARKET, VILLAGE, Place.KIND_MARKET, Vector3(284.0, 0.0, 0.0), 8),
	]
	return SettlementService.new(settlements, places)


## Módulo registrado num mundo próprio (o mundo fica guardado até o fim do teste). `places` nulo: definições sem o serviço de locais; `with_definitions` falso: o módulo sem definições nenhumas.
func _module(places: SettlementService = _places(), with_definitions: bool = true) -> NpcModule:
	var need_defs: Array[NeedDef] = []
	for position: int in NEED_IDS.size():
		need_defs.append(NeedDef.new(NEED_IDS[position], position, 0, 0, 40, 65, 90))
	var definitions: NpcModule.Definitions = NpcModule.Definitions.new()
	var traits: Array[TraitLoader.TraitDef] = []
	for position: int in TRAIT_IDS.size():
		traits.append(TraitLoader.TraitDef.new(TRAIT_IDS[position], position))
	definitions.traits = traits
	definitions.places = places
	var occupations: Array[RoutineTable.OccupationDef] = [RoutineTable.OccupationDef.new("tester", "work")]
	var blocks: Array[RoutineTable.RoutineBlock] = [RoutineTable.RoutineBlock.new("t", "tester", 0, 24, "work")]
	var module: NpcModule = NpcModule.new(need_defs, RoutineTable.new(occupations, blocks), definitions) if with_definitions else NpcModule.new()
	var clock: SimClock = SimClock.new()
	var world: World = World.new(SimContext.new(clock, EventBus.new(clock), WorldRng.new(3), IdGenerator.new()))
	assert_true(world.register_module("npc", module).ok)
	world.setup()
	world.post_setup()
	_worlds.append(world)
	return module


func after_each() -> void:
	_worlds.clear()


func _spawn(module: NpcModule, home: String, work: String, place: String) -> int:
	var spec: NpcSpec = NpcSpec.new()
	spec.name_key = "npc.name.villager"
	spec.occupation_id = "tester"
	spec.settlement_id = VILLAGE
	spec.place_id = place
	spec.home_place_id = home
	spec.work_place_id = work
	spec.x_cm = HOME_X_CM
	var created: NpcModule.CreateResult = module.request_create_npc(spec)
	assert_true(created.result.ok, created.result.message)
	return created.npc_id


## O save de um módulo com três NPCs vivos e válidos (1: em casa e no trabalho; 2: em trânsito, sem local de trabalho e sem local; 3: no mercado).
func _valid_save() -> Dictionary:
	var source: NpcModule = _module()
	_spawn(source, HOME_1, WORK, HOME_1)
	_spawn(source, HOME_2, "", "")
	_spawn(source, HOME_2, WORK, MARKET)
	return source.serialize()


## Cópia do save com `changes` por cima do registro de `npc_id`.
func _changed(saved: Dictionary, npc_id: int, changes: Dictionary) -> Dictionary:
	var copy: Dictionary = saved.duplicate(true)
	var entries: Dictionary = copy[NpcModule.KEY_NPCS]
	var entry: Dictionary = entries[str(npc_id)]
	entry.merge(changes, true)
	return copy


## O que o módulo mostra por `peek_npc` (campos de local e de vida), para provar que ficou como estava.
func _look(module: NpcModule) -> Array:
	var seen: Array = []
	for npc_id: int in module.peek_npc_ids():
		var query: NpcModule.NpcQuery = module.peek_npc(npc_id)
		seen.append([npc_id, query.is_alive, query.home_place_id, query.work_place_id, query.place_id, query.action_target_place_id])
	return seen


## Carrega `saved` num módulo que já tem outros NPCs e confere a recusa e o módulo intacto. Devolve a falha para o teste olhar a mensagem.
func _refused(saved: Dictionary) -> Result:
	var target: NpcModule = _module()
	_spawn(target, HOME_2, WORK, HOME_2)
	_spawn(target, HOME_1, "", HOME_1)
	var serialized_before: Dictionary = target.serialize()
	var look_before: Array = _look(target)
	var result: Result = target.on_load(saved)
	assert_false(result.ok, "O save que cita local inexistente é recusado.")
	assert_eq(result.code, NpcModule.CODE_INVALID_SAVE, "O mesmo código de save inválido do módulo, sem código novo.")
	assert_true(result.message.begins_with("NpcModule.on_load: "), result.message)
	assert_eq(target.serialize(), serialized_before, "A recusa não mexe no módulo: o mesmo serialize de antes.")
	assert_eq(_look(target), look_before, "Nem nos NPCs: o mesmo peek_npc de antes (nenhum removido, nenhum trocado).")
	return result


# ---------------------------------------------------------------------------------------------------- recusa, um campo por vez

func test_a_missing_home_is_refused_naming_the_npc_the_field_and_the_place() -> void:
	var result: Result = _refused(_changed(_valid_save(), 2, {"home_place_id": "ghost_home"}))
	assert_string_contains(result.message, "NPC 2, campo 'home_place_id', local 'ghost_home'")
	assert_string_contains(result.message, "1 referência(s) em 1 NPC(s) vivo(s)")


func test_a_missing_work_place_is_refused_naming_the_npc_the_field_and_the_place() -> void:
	var result: Result = _refused(_changed(_valid_save(), 3, {"work_place_id": "ghost_work"}))
	assert_string_contains(result.message, "NPC 3, campo 'work_place_id', local 'ghost_work'")


func test_a_missing_current_place_is_refused_naming_the_npc_the_field_and_the_place() -> void:
	var result: Result = _refused(_changed(_valid_save(), 1, {"place_id": "ghost_place"}))
	assert_string_contains(result.message, "NPC 1, campo 'place_id', local 'ghost_place'")


func test_a_missing_action_target_is_refused_naming_the_npc_the_field_and_the_place() -> void:
	var result: Result = _refused(_changed(_valid_save(), 2, {"action_id": "go_to_place", "action_target_place_id": "ghost_target"}))
	assert_string_contains(result.message, "NPC 2, campo 'action_target_place_id', local 'ghost_target'")


func test_the_message_gives_the_probable_cause_in_portuguese() -> void:
	var result: Result = _refused(_changed(_valid_save(), 1, {"home_place_id": "ghost_home"}))
	assert_string_contains(result.message, "Causa provável")
	assert_string_contains(result.message, CAUSE_PHRASE)
	assert_string_contains(result.message, "faltam casas ou locais")
	assert_string_contains(result.message, RESTORE_PHRASE)


# ---------------------------------------------------------------------------------------------------- vários problemas: a contagem e só os cinco primeiros

func test_several_problems_count_everything_and_list_only_the_first_five_by_npc_id_then_field() -> void:
	var saved: Dictionary = _valid_save()
	saved = _changed(saved, 1, {"home_place_id": "ghost_1", "work_place_id": "ghost_2"})
	saved = _changed(saved, 2, {"home_place_id": "ghost_3", "place_id": "ghost_4", "action_target_place_id": "ghost_5"})
	saved = _changed(saved, 3, {"work_place_id": "ghost_6", "action_target_place_id": "ghost_7"})
	var result: Result = _refused(saved)
	assert_string_contains(result.message, "7 referência(s) em 3 NPC(s) vivo(s)")
	for listed: String in ["NPC 1, campo 'home_place_id', local 'ghost_1'", "NPC 1, campo 'work_place_id', local 'ghost_2'", "NPC 2, campo 'home_place_id', local 'ghost_3'", "NPC 2, campo 'place_id', local 'ghost_4'", "NPC 2, campo 'action_target_place_id', local 'ghost_5'"]:
		assert_string_contains(result.message, listed)
	assert_false(result.message.contains("ghost_6") or result.message.contains("ghost_7"), "Só as cinco primeiras entram na lista.")
	assert_string_contains(result.message, "; e mais 2")
	assert_lt(result.message.find("ghost_1"), result.message.find("ghost_5"), "Na ordem em que foram achadas.")


func test_the_first_five_follow_the_numeric_order_of_the_ids_not_the_text_order() -> void:
	var saved: Dictionary = _valid_save()
	var entries: Dictionary = saved[NpcModule.KEY_NPCS]
	var template: Dictionary = entries["1"]
	entries.clear()
	for npc_id: int in range(1, 13):
		var entry: Dictionary = template.duplicate(true)
		entry["home_place_id"] = "ghost_%d" % npc_id
		entries[str(npc_id)] = entry
	var result: Result = _refused(saved)
	assert_string_contains(result.message, "12 referência(s) em 12 NPC(s) vivo(s)")
	for npc_id: int in range(1, 6):
		assert_string_contains(result.message, "NPC %d, campo 'home_place_id', local 'ghost_%d'" % [npc_id, npc_id])
	assert_false(result.message.contains("NPC 10,") or result.message.contains("NPC 11,") or result.message.contains("NPC 12,"), "Em texto o 10 viria logo depois do 1: a ordem é a do número.")
	assert_string_contains(result.message, "; e mais 7")


# ---------------------------------------------------------------------------------------------------- o que NÃO é recusado

func test_a_dead_npc_with_missing_places_is_exempt_and_the_save_round_trips() -> void:
	var dead: Dictionary = {"is_alive": false, "death_cause": "hunger", "died_at": 10, "action_id": "", "action_target_place_id": "", "place_id": "", "home_place_id": "ghost_home", "work_place_id": "ghost_work"}
	var saved: Dictionary = _changed(_valid_save(), 3, dead)
	var target: NpcModule = _module()
	assert_true(target.on_load(saved).ok, "O morto que cita casa e trabalho inexistentes não barra o save.")
	assert_false(target.peek_npc(3).is_alive)
	assert_eq(target.serialize(), saved, "O morto fica como veio, com os locais que citava: nada é apagado nem corrigido.")
	var alive: Dictionary = _changed(saved, 3, {"is_alive": true, "death_cause": "", "died_at": -1})
	assert_false(_module().on_load(alive).ok, "Controle: o MESMO NPC vivo, com os mesmos locais, é recusado.")


func test_empty_place_fields_are_legitimate_and_load() -> void:
	var saved: Dictionary = _valid_save()
	var in_transit: Dictionary = saved[NpcModule.KEY_NPCS]["2"]
	assert_eq([in_transit["place_id"], in_transit["work_place_id"], in_transit["action_target_place_id"]], ["", "", ""], "Premissa: o NPC 2 está em trânsito, sem local de trabalho e sem alvo.")
	var target: NpcModule = _module()
	assert_true(target.on_load(saved).ok, "Campo vazio não é referência: em trânsito, sem alvo e sem local de trabalho carregam.")
	assert_eq(target.serialize(), saved)


func test_a_valid_action_target_in_transit_loads() -> void:
	var saved: Dictionary = _changed(_valid_save(), 2, {"action_id": "go_to_place", "action_target_place_id": MARKET, "place_id": ""})
	var target: NpcModule = _module()
	assert_true(target.on_load(saved).ok, "A viagem a um local que existe (sem local atual, com alvo) não é recusada.")
	assert_eq(target.peek_npc(2).action_target_place_id, MARKET)
	assert_eq(target.serialize(), saved)


func test_a_valid_save_loads_in_a_fresh_module_and_serializes_back_equal() -> void:
	var saved: Dictionary = _valid_save()
	var fresh: NpcModule = _module()
	var loaded: Result = fresh.on_load(saved)
	assert_true(loaded.ok, loaded.message)
	assert_eq(fresh.serialize(), saved, "Ida e volta idêntica.")
	assert_eq(fresh.peek_npc_ids(), [1, 2, 3] as Array[int])


func test_without_places_nothing_is_checked() -> void:
	var broken: Dictionary = _changed(_valid_save(), 1, {"home_place_id": "ghost_home", "work_place_id": "ghost_work", "place_id": "ghost_place", "action_target_place_id": "ghost_target"})
	var without_service: NpcModule = _module(null)
	assert_true(without_service.on_load(broken).ok, "Definições sem `places`: não há com o que conferir.")
	assert_eq(without_service.serialize(), broken)
	var without_definitions: NpcModule = _module(null, false)
	assert_true(without_definitions.on_load(broken).ok, "Módulo sem definições nenhumas: idem.")
	assert_eq(without_definitions.serialize(), broken)
