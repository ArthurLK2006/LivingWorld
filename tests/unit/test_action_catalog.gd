extends GutTest
## LW-059: catálogo de ações em dados (docs/modules/npc.md, seção 3), sem janela. Os quatro arquivos reais carregam com as sete ações
## iniciais (propriedades estruturais ESCRITAS À MÃO a partir do contrato; as grandezas [HIP] dos dados NÃO são fixadas aqui);
## referência a necessidade, traço ou ação inexistente, tipo de local ou de condição fora do vocabulário e as demais falhas apontam
## arquivo, item e campo; e uma ação nova SÓ por dados passa na validação. Casos inválidos usam tabelas em memória (nada é gravado).

const DATA_DIR: String = "res://data"
const ISSUE_CODE: String = "ACTION_DATA_INVALID"
const ACTION_IDS: Array[String] = ["sleep", "eat", "work", "rest", "talk", "go_to_place", "wait"]
const EFFECTS_FILE: String = "action_effects.json"
const CONDITIONS_FILE: String = "action_conditions.json"
const WEIGHTS_FILE: String = "action_trait_weights.json"
const ACTIONS_FILE: String = "actions.json"


## Tabelas dos arquivos reais, copiadas em profundidade para cada caso poder alterá-las.
func _tables() -> Dictionary[String, Array]:
	var bundle: DataBundle = DataLoader.load_all(DATA_DIR, ActionCatalogLoader.build_schemas())
	assert_true(bundle.is_valid(), bundle.describe_issues())
	var copy: Dictionary[String, Array] = {}
	for table_id: String in bundle.tables:
		copy[table_id] = bundle.tables[table_id].duplicate(true)
	return copy


func _row(tables: Dictionary[String, Array], table_id: String, row_id: String) -> Dictionary:
	for record: Dictionary in tables[table_id]:
		if record["id"] == row_id:
			return record
	fail_test("A linha '%s' não existe em '%s'." % [row_id, table_id])
	return {}


func _load(tables: Dictionary[String, Array]) -> ActionCatalogLoader.LoadResult:
	return ActionCatalogLoader.from_tables(tables, DATA_DIR)


func _action(actions: Array[ActionDef], action_id: String) -> ActionDef:
	for action: ActionDef in actions:
		if action.id == action_id:
			return action
	fail_test("A ação '%s' não está no catálogo." % action_id)
	return null


func _expect_failure(label: String, tables: Dictionary[String, Array], fragments: Array[String]) -> void:
	var loaded: ActionCatalogLoader.LoadResult = _load(tables)
	assert_false(loaded.result.ok, "%s: deveria falhar." % label)
	assert_eq(loaded.result.code, ISSUE_CODE, label)
	assert_eq(loaded.actions.size(), 0, "%s: falha não devolve ações." % label)
	for fragment: String in fragments:
		assert_string_contains(loaded.result.message, fragment, "%s: a mensagem deveria citar '%s'." % [label, fragment])


# ---------------------------------------------------------------------------------------------------- dados reais

func test_the_real_files_load_the_seven_initial_actions_in_file_order() -> void:
	var loaded: ActionCatalogLoader.LoadResult = ActionCatalogLoader.load_dir()
	assert_true(loaded.result.ok, loaded.result.message)
	var ids: Array[String] = []
	for action: ActionDef in loaded.actions:
		ids.append(action.id)
	assert_eq(ids, ACTION_IDS)


func test_each_initial_action_has_the_place_and_effects_the_contract_describes() -> void:
	var actions: Array[ActionDef] = ActionCatalogLoader.load_dir().actions
	var place_by_action: Dictionary = {"sleep": "home", "eat": "home", "work": "work", "rest": "rest", "talk": "social", "go_to_place": "", "wait": ""}
	for action_id: String in place_by_action:
		assert_eq(_action(actions, action_id).place_kind, place_by_action[action_id], "Tipo de local de %s." % action_id)
	var relieves: Dictionary = {"sleep": "rest", "eat": "hunger", "rest": "rest", "talk": "social"}
	for action_id: String in relieves:
		var effects: Array[ActionDef.ActionEffect] = _action(actions, action_id).effects
		assert_eq(effects.size(), 1, "%s tem um efeito." % action_id)
		assert_eq(effects[0].need_id, relieves[action_id])
		assert_lt(effects[0].delta, 0, "%s alivia a necessidade (delta negativo)." % action_id)
	var work: ActionDef = _action(actions, "work")
	assert_eq(work.effects.size(), 1)
	assert_eq(work.effects[0].need_id, "rest", "Trabalhar tem custo leve de descanso.")
	assert_gt(work.effects[0].delta, 0)
	assert_eq(_action(actions, "go_to_place").effects.size(), 0, "Ir até um local não mexe em necessidade.")
	assert_eq(_action(actions, "wait").effects.size(), 0)
	assert_eq(_action(actions, "go_to_place").duration_min, 0, "Duração 0 = calculada pela distância em execução.")
	for action_id: String in ["sleep", "eat", "work", "rest", "talk", "wait"]:
		assert_gt(_action(actions, action_id).duration_min, 0, "%s tem duração fixa." % action_id)


func test_eating_requires_food_and_nothing_else_has_conditions_yet() -> void:
	var actions: Array[ActionDef] = ActionCatalogLoader.load_dir().actions
	var eat: ActionDef = _action(actions, "eat")
	assert_eq(eat.conditions.size(), 1)
	assert_eq(eat.conditions[0].kind, ActionDef.CONDITION_HAS_FOOD)
	assert_eq(eat.conditions[0].need_id, "")
	assert_eq(eat.conditions[0].min_value, ActionDef.ABSENT)
	assert_eq(eat.conditions[0].max_value, ActionDef.ABSENT)
	for action: ActionDef in actions:
		if action.id != "eat":
			assert_eq(action.conditions.size(), 0, "%s não tem condição no catálogo inicial." % action.id)


func test_no_initial_action_uses_the_reserved_market_place_and_every_kind_is_known() -> void:
	for action: ActionDef in ActionCatalogLoader.load_dir().actions:
		assert_ne(action.place_kind, "market_reserved", "%s: nenhuma ação da Fase 2 usa o mercado-reservado." % action.id)
		assert_true(action.place_kind.is_empty() or ActionDef.PLACE_KINDS.has(action.place_kind))
		assert_true(action.risk >= 0 and action.risk <= 100)


func test_the_place_vocabulary_and_condition_kinds_are_the_closed_lists() -> void:
	assert_eq(ActionDef.PLACE_KINDS, ["home", "work", "rest", "social", "market_reserved"] as Array[String])
	assert_eq(ActionDef.CONDITION_KINDS, ["need_at_least", "need_at_most", "hour_between", "place_has_room", "has_food"] as Array[String])


func test_loading_twice_gives_the_same_result() -> void:
	var first: ActionCatalogLoader.LoadResult = ActionCatalogLoader.load_dir()
	var second: ActionCatalogLoader.LoadResult = ActionCatalogLoader.load_dir()
	assert_eq(first.actions.size(), second.actions.size())
	for index: int in first.actions.size():
		assert_eq(first.actions[index].id, second.actions[index].id)
		assert_eq(first.actions[index].effects.size(), second.actions[index].effects.size())
		assert_eq(first.actions[index].duration_min, second.actions[index].duration_min)


func test_the_in_memory_path_gives_the_same_catalog_as_the_files() -> void:
	var from_files: ActionCatalogLoader.LoadResult = ActionCatalogLoader.load_dir()
	var from_memory: ActionCatalogLoader.LoadResult = _load(_tables())
	assert_true(from_memory.result.ok, from_memory.result.message)
	assert_eq(from_memory.actions.size(), from_files.actions.size())
	for index: int in from_files.actions.size():
		assert_eq(from_memory.actions[index].id, from_files.actions[index].id)
		assert_eq(from_memory.actions[index].effects.size(), from_files.actions[index].effects.size())


# ---------------------------------------------------------------------------------------------------- ação nova só por dados

func test_a_new_action_added_only_by_data_passes_validation() -> void:
	var tables: Dictionary[String, Array] = _tables()
	tables["actions"].append({"id": "gather_wood", "duration_min": 120, "place_kind": "work", "risk": 10, "interruptible": false})
	tables["action_effects"].append({"id": "gather_wood_rest", "action_id": "gather_wood", "need_id": "rest", "delta": 15})
	tables["action_effects"].append({"id": "gather_wood_income", "action_id": "gather_wood", "need_id": "income", "delta": -10})
	tables["action_conditions"].append({"id": "gather_wood_daylight", "action_id": "gather_wood", "kind": "hour_between", "min_value": 6, "max_value": 18})
	tables["action_conditions"].append({"id": "gather_wood_not_exhausted", "action_id": "gather_wood", "kind": "need_at_most", "need_id": "rest", "max_value": 80})
	tables["action_conditions"].append({"id": "gather_wood_hungry_enough", "action_id": "gather_wood", "kind": "need_at_least", "need_id": "hunger", "min_value": 0})
	tables["action_conditions"].append({"id": "gather_wood_room", "action_id": "gather_wood", "kind": "place_has_room"})
	tables["action_trait_weights"].append({"id": "gather_wood_ambition", "action_id": "gather_wood", "trait_id": "ambition", "weight": 10})
	tables["action_trait_weights"].append({"id": "gather_wood_caution", "action_id": "gather_wood", "trait_id": "caution", "weight": -5})
	var loaded: ActionCatalogLoader.LoadResult = _load(tables)
	assert_true(loaded.result.ok, loaded.result.message)
	assert_eq(loaded.actions.size(), 8)
	var added: ActionDef = _action(loaded.actions, "gather_wood")
	assert_eq(added.duration_min, 120)
	assert_eq(added.place_kind, "work")
	assert_eq(added.risk, 10)
	assert_false(added.interruptible)
	assert_eq(added.effects.size(), 2)
	assert_eq(added.effects[1].need_id, "income")
	assert_eq(added.effects[1].delta, -10)
	assert_eq(added.conditions.size(), 4)
	assert_eq(added.conditions[0].kind, ActionDef.CONDITION_HOUR_BETWEEN)
	assert_eq(added.conditions[0].min_value, 6)
	assert_eq(added.conditions[0].max_value, 18)
	assert_eq(added.conditions[1].need_id, "rest")
	assert_eq(added.conditions[1].max_value, 80)
	assert_eq(added.conditions[1].min_value, ActionDef.ABSENT)
	assert_eq(added.conditions[3].kind, ActionDef.CONDITION_PLACE_HAS_ROOM)
	assert_eq(added.trait_weights.size(), 2)
	assert_eq(added.trait_weights[1].trait_id, "caution")
	assert_eq(added.trait_weights[1].weight, -5)
	assert_eq(_action(loaded.actions, "eat").effects.size(), 1, "As ações que já existiam não mudaram.")


func test_a_minimal_new_action_and_the_reserved_place_kind_pass() -> void:
	var tables: Dictionary[String, Array] = _tables()
	tables["actions"].append({"id": "stand_around", "duration_min": 5, "place_kind": "", "risk": 0, "interruptible": true})
	tables["actions"].append({"id": "browse", "duration_min": 5, "place_kind": "market_reserved", "risk": 0, "interruptible": true})
	var loaded: ActionCatalogLoader.LoadResult = _load(tables)
	assert_true(loaded.result.ok, loaded.result.message)
	assert_eq(_action(loaded.actions, "browse").place_kind, "market_reserved", "O vocabulário aceita o tipo reservado.")


# ---------------------------------------------------------------------------------------------------- dado inválido

func test_references_to_things_that_do_not_exist_point_at_file_item_and_field() -> void:
	var missing_need: Dictionary[String, Array] = _tables()
	_row(missing_need, "action_effects", "eat_hunger")["need_id"] = "thirst"
	_expect_failure("necessidade inexistente no efeito", missing_need, [EFFECTS_FILE, "item 'eat_hunger'", "campo 'need_id'", "referência a id inexistente 'thirst' na tabela 'needs'"])
	var missing_action: Dictionary[String, Array] = _tables()
	_row(missing_action, "action_effects", "sleep_rest")["action_id"] = "fly"
	_expect_failure("ação inexistente no efeito", missing_action, [EFFECTS_FILE, "item 'sleep_rest'", "campo 'action_id'", "'fly' na tabela 'actions'"])
	var condition_need: Dictionary[String, Array] = _tables()
	condition_need["action_conditions"].append({"id": "work_limit", "action_id": "work", "kind": "need_at_least", "need_id": "thirst", "min_value": 10})
	_expect_failure("necessidade inexistente na condição", condition_need, [CONDITIONS_FILE, "item 'work_limit'", "campo 'need_id'", "'thirst' na tabela 'needs'"])
	var condition_action: Dictionary[String, Array] = _tables()
	condition_action["action_conditions"].append({"id": "ghost_food", "action_id": "ghost", "kind": "has_food"})
	_expect_failure("ação inexistente na condição", condition_action, [CONDITIONS_FILE, "item 'ghost_food'", "campo 'action_id'", "'ghost' na tabela 'actions'"])
	var weight_trait: Dictionary[String, Array] = _tables()
	weight_trait["action_trait_weights"].append({"id": "talk_charm", "action_id": "talk", "trait_id": "charm", "weight": 5})
	_expect_failure("traço inexistente", weight_trait, [WEIGHTS_FILE, "item 'talk_charm'", "campo 'trait_id'", "'charm' na tabela 'traits'"])
	var weight_action: Dictionary[String, Array] = _tables()
	weight_action["action_trait_weights"].append({"id": "ghost_caution", "action_id": "ghost", "trait_id": "caution", "weight": 5})
	_expect_failure("ação inexistente no peso", weight_action, [WEIGHTS_FILE, "item 'ghost_caution'", "campo 'action_id'", "'ghost' na tabela 'actions'"])


func test_unknown_place_kind_and_unknown_condition_kind_fail() -> void:
	var place: Dictionary[String, Array] = _tables()
	_row(place, "actions", "work")["place_kind"] = "kitchen"
	_expect_failure("tipo de local inexistente", place, [ACTIONS_FILE, "item 'work'", "campo 'place_kind'", "tipo de local 'kitchen' inexistente", "home, work, rest, social, market_reserved"])
	var kind: Dictionary[String, Array] = _tables()
	_row(kind, "action_conditions", "eat_has_food")["kind"] = "is_raining"
	_expect_failure("tipo de condição desconhecido", kind, [CONDITIONS_FILE, "item 'eat_has_food'", "campo 'kind'", "tipo de condição desconhecido 'is_raining'", "need_at_least"])


func test_each_condition_kind_requires_its_own_fields() -> void:
	var cases: Array[Dictionary] = [
		{"label": "need_at_least sem need_id", "row": {"kind": "need_at_least", "min_value": 10}, "expect": ["item 'c'", "campo 'need_id'", "obrigatório no tipo 'need_at_least'"]},
		{"label": "need_at_least sem min_value", "row": {"kind": "need_at_least", "need_id": "rest"}, "expect": ["campo 'min_value'", "obrigatório no tipo 'need_at_least'"]},
		{"label": "need_at_most sem max_value", "row": {"kind": "need_at_most", "need_id": "rest"}, "expect": ["campo 'max_value'", "obrigatório no tipo 'need_at_most'"]},
		{"label": "need_at_most sem need_id", "row": {"kind": "need_at_most", "max_value": 10}, "expect": ["campo 'need_id'", "obrigatório no tipo 'need_at_most'"]},
		{"label": "hour_between sem min_value", "row": {"kind": "hour_between", "max_value": 10}, "expect": ["campo 'min_value'", "obrigatório no tipo 'hour_between'"]},
		{"label": "hour_between sem max_value", "row": {"kind": "hour_between", "min_value": 10}, "expect": ["campo 'max_value'", "obrigatório no tipo 'hour_between'"]},
		{"label": "hour_between com hora 25", "row": {"kind": "hour_between", "min_value": 6, "max_value": 25}, "expect": ["campo 'max_value'", "hora 25 acima de 24"]},
		{"label": "has_food com need_id", "row": {"kind": "has_food", "need_id": "hunger"}, "expect": ["campo 'need_id'", "não se aplica ao tipo 'has_food'"]},
		{"label": "place_has_room com need_id", "row": {"kind": "place_has_room", "need_id": "hunger"}, "expect": ["campo 'need_id'", "não se aplica ao tipo 'place_has_room'"]},
		{"label": "min_value acima de 100", "row": {"kind": "need_at_least", "need_id": "rest", "min_value": 101}, "expect": ["campo 'min_value'", "acima do máximo"]},
		{"label": "max_value negativo", "row": {"kind": "need_at_most", "need_id": "rest", "max_value": -1}, "expect": ["campo 'max_value'", "abaixo do mínimo"]},
	]
	for test_case: Dictionary in cases:
		var tables: Dictionary[String, Array] = _tables()
		var row: Dictionary = {"id": "c", "action_id": "work"}
		row.merge(test_case["row"])
		tables["action_conditions"].append(row)
		var fragments: Array[String] = [CONDITIONS_FILE, "item 'c'"]
		fragments.append_array(test_case["expect"])
		_expect_failure(test_case["label"], tables, fragments)


func test_repeated_effect_and_repeated_weight_for_the_same_pair_fail() -> void:
	var effect: Dictionary[String, Array] = _tables()
	effect["action_effects"].append({"id": "eat_hunger_again", "action_id": "eat", "need_id": "hunger", "delta": -5})
	_expect_failure("efeito repetido", effect, [EFFECTS_FILE, "item 'eat_hunger_again'", "campo 'need_id'", "efeito repetido para a ação 'eat' e 'hunger'", "linha 'eat_hunger'"])
	var weight: Dictionary[String, Array] = _tables()
	weight["action_trait_weights"].append({"id": "talk_a", "action_id": "talk", "trait_id": "sociability", "weight": 5})
	weight["action_trait_weights"].append({"id": "talk_b", "action_id": "talk", "trait_id": "sociability", "weight": 7})
	_expect_failure("peso repetido", weight, [WEIGHTS_FILE, "item 'talk_b'", "campo 'trait_id'", "peso repetido para a ação 'talk' e 'sociability'", "linha 'talk_a'"])


func test_value_ranges_types_and_shape_of_the_action_table_fail() -> void:
	var cases: Array[Dictionary] = [
		{"label": "duração negativa", "table": "actions", "row": "sleep", "set": {"duration_min": -1}, "expect": [ACTIONS_FILE, "item 'sleep'", "campo 'duration_min'", "abaixo do mínimo"]},
		{"label": "duração acima de um dia", "table": "actions", "row": "sleep", "set": {"duration_min": 1441}, "expect": [ACTIONS_FILE, "campo 'duration_min'", "acima do máximo"]},
		{"label": "duração com fração", "table": "actions", "row": "eat", "set": {"duration_min": 1.5}, "expect": [ACTIONS_FILE, "item 'eat'", "campo 'duration_min'", "tipo inválido"]},
		{"label": "risco acima de 100", "table": "actions", "row": "work", "set": {"risk": 101}, "expect": [ACTIONS_FILE, "item 'work'", "campo 'risk'", "acima do máximo"]},
		{"label": "interruptible como texto", "table": "actions", "row": "rest", "set": {"interruptible": "yes"}, "expect": [ACTIONS_FILE, "item 'rest'", "campo 'interruptible'", "tipo inválido"]},
		{"label": "place_kind como número", "table": "actions", "row": "talk", "set": {"place_kind": 3}, "expect": [ACTIONS_FILE, "item 'talk'", "campo 'place_kind'", "tipo inválido"]},
		{"label": "campo desconhecido", "table": "actions", "row": "wait", "set": {"cost": 3}, "expect": [ACTIONS_FILE, "item 'wait'", "campo 'cost'", "campo desconhecido"]},
		{"label": "id repetido", "table": "actions", "row": "wait", "set": {"id": "sleep"}, "expect": [ACTIONS_FILE, "item 'sleep'", "campo 'id'", "id duplicado"]},
		{"label": "id fora do padrão", "table": "actions", "row": "wait", "set": {"id": "Wait"}, "expect": [ACTIONS_FILE, "item 'Wait'", "campo 'id'", "snake_case"]},
		{"label": "efeito acima de 100", "table": "action_effects", "row": "eat_hunger", "set": {"delta": 101}, "expect": [EFFECTS_FILE, "item 'eat_hunger'", "campo 'delta'", "acima do máximo"]},
		{"label": "efeito abaixo de -100", "table": "action_effects", "row": "eat_hunger", "set": {"delta": -101}, "expect": [EFFECTS_FILE, "campo 'delta'", "abaixo do mínimo"]},
	]
	for field: String in ["duration_min", "place_kind", "risk", "interruptible"]:
		cases.append({"label": "%s ausente" % field, "table": "actions", "row": "work", "erase": field, "expect": [ACTIONS_FILE, "item 'work'", "campo '%s'" % field, "obrigatório ausente"]})
	for field: String in ["action_id", "need_id", "delta"]:
		cases.append({"label": "%s ausente no efeito" % field, "table": "action_effects", "row": "work_rest", "erase": field, "expect": [EFFECTS_FILE, "item 'work_rest'", "campo '%s'" % field, "obrigatório ausente"]})
	for test_case: Dictionary in cases:
		var tables: Dictionary[String, Array] = _tables()
		var row: Dictionary = _row(tables, test_case["table"], test_case["row"])
		if test_case.has("erase"):
			row.erase(test_case["erase"])
		else:
			row.merge(test_case["set"], true)
		var fragments: Array[String] = []
		fragments.assign(test_case["expect"])
		_expect_failure(test_case["label"], tables, fragments)


func test_a_weight_outside_the_range_fails() -> void:
	var tables: Dictionary[String, Array] = _tables()
	tables["action_trait_weights"].append({"id": "talk_loud", "action_id": "talk", "trait_id": "sociability", "weight": 101})
	_expect_failure("peso acima de 100", tables, [WEIGHTS_FILE, "item 'talk_loud'", "campo 'weight'", "acima do máximo"])


func test_a_broken_needs_or_traits_table_is_reported_by_the_catalog_loader_too() -> void:
	var needs: Dictionary[String, Array] = _tables()
	_row(needs, "needs", "hunger")["urgent"] = 10
	_expect_failure("limiares da necessidade", needs, ["needs.json", "item 'hunger'", "campo 'urgent'", "limiares precisam crescer"])
	var traits: Dictionary[String, Array] = _tables()
	traits["traits"].pop_back()
	_expect_failure("só três traços", traits, ["traits.json", "esperado 4 traços", "encontrados 3"])


func test_missing_files_fail_pointing_at_each_file() -> void:
	var loaded: ActionCatalogLoader.LoadResult = ActionCatalogLoader.load_dir("res://tests/fixtures/data/ok")
	assert_false(loaded.result.ok)
	assert_eq(loaded.result.code, ISSUE_CODE)
	for file_name: String in ["traits.json", "needs.json", ACTIONS_FILE, EFFECTS_FILE, CONDITIONS_FILE, WEIGHTS_FILE]:
		assert_string_contains(loaded.result.message, "%s | arquivo não encontrado" % file_name)
