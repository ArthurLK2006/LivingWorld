extends GutTest
## LW-062: data/npc_params.json, os parâmetros da pontuação de utilidade (docs/modules/npc.md, seção 5), lidos e validados pelo módulo
## `data` (NpcParamsLoader). O arquivo real só tem PROPRIEDADES conferidas (os números são [HIP]); dado inválido falha apontando arquivo,
## item e campo, com pacotes montados em memória (nada é gravado em disco).

const FILE_LABEL: String = "res://data/npc_params.json"
const ISSUE_CODE: String = "NPC_PARAMS_INVALID"
const FIELDS: Array[String] = [
	"urgency_weight_comfortable", "urgency_weight_attention", "urgency_weight_urgent", "urgency_weight_critical",
	"time_cost_per_hour", "distance_cost_per_100m", "risk_cost_percent", "inertia_bonus", "routine_bonus",
]


func _valid_record() -> Dictionary:
	return {
		"id": "default", "urgency_weight_comfortable": 0, "urgency_weight_attention": 1, "urgency_weight_urgent": 3, "urgency_weight_critical": 6,
		"time_cost_per_hour": 2, "distance_cost_per_100m": 2, "risk_cost_percent": 100, "inertia_bonus": 25, "routine_bonus": 40,
	}


## Mesmo caminho do carregador de arquivo: o `data` valida o pacote e o NpcParamsLoader confere o resto e monta.
func _load_records(records: Array[Dictionary]) -> NpcParamsLoader.LoadResult:
	var bundle: DataBundle = DataBundle.new()
	bundle.tables[NpcParamsLoader.PARAMS_TABLE] = records
	bundle.file_paths[NpcParamsLoader.PARAMS_TABLE] = FILE_LABEL
	DataValidator.new().validate(bundle, [NpcParamsLoader.build_schema()])
	return NpcParamsLoader.from_bundle(bundle)


func _expect_failure(label: String, records: Array[Dictionary], fragments: Array[String]) -> void:
	var loaded: NpcParamsLoader.LoadResult = _load_records(records)
	assert_false(loaded.result.ok, "%s: deveria falhar." % label)
	assert_eq(loaded.result.code, ISSUE_CODE, label)
	assert_null(loaded.params, "%s: falha não devolve parâmetros." % label)
	for fragment: String in fragments:
		assert_string_contains(loaded.result.message, fragment, "%s: a mensagem deveria citar '%s'." % [label, fragment])


func test_the_real_file_has_one_row_with_every_parameter_in_range_and_weights_that_do_not_decrease() -> void:
	var loaded: NpcParamsLoader.LoadResult = NpcParamsLoader.load_dir()
	assert_true(loaded.result.ok, loaded.result.message)
	var params: NpcParams = loaded.params
	assert_true(params.urgency_weight_comfortable <= params.urgency_weight_attention)
	assert_true(params.urgency_weight_attention <= params.urgency_weight_urgent)
	assert_true(params.urgency_weight_urgent <= params.urgency_weight_critical)
	assert_gt(params.urgency_weight_critical, 0, "Necessidade crítica pesa alguma coisa.")
	for value: int in [params.time_cost_per_hour, params.distance_cost_per_100m, params.risk_cost_percent, params.inertia_bonus, params.routine_bonus]:
		assert_true(value >= 0)
	assert_gt(params.inertia_bonus, 0, "Sem inércia o NPC trocaria de ação a cada pensamento.")
	assert_gt(params.routine_bonus, 0, "Sem bônus de rotina a rotina nunca decidiria nada.")


func test_loading_twice_gives_the_same_parameters() -> void:
	var first: NpcParams = NpcParamsLoader.load_dir().params
	var second: NpcParams = NpcParamsLoader.load_dir().params
	for level: int in 4:
		assert_eq(first.urgency_weight(level), second.urgency_weight(level))
	assert_eq(first.inertia_bonus, second.inertia_bonus)
	assert_eq(first.routine_bonus, second.routine_bonus)


func test_the_in_memory_path_builds_every_field_from_the_record() -> void:
	var record: Dictionary = _valid_record()
	record["urgency_weight_attention"] = 2
	record["time_cost_per_hour"] = 11
	record["distance_cost_per_100m"] = 12
	record["risk_cost_percent"] = 130
	record["inertia_bonus"] = 33
	record["routine_bonus"] = 44
	var loaded: NpcParamsLoader.LoadResult = _load_records([record])
	assert_true(loaded.result.ok, loaded.result.message)
	assert_eq(loaded.params.urgency_weight_attention, 2)
	assert_eq(loaded.params.time_cost_per_hour, 11)
	assert_eq(loaded.params.distance_cost_per_100m, 12)
	assert_eq(loaded.params.risk_cost_percent, 130)
	assert_eq(loaded.params.inertia_bonus, 33)
	assert_eq(loaded.params.routine_bonus, 44)


func test_invalid_data_fails_pointing_at_file_item_and_field() -> void:
	for field: String in FIELDS:
		var missing: Dictionary = _valid_record()
		missing.erase(field)
		_expect_failure("%s ausente" % field, [missing], [FILE_LABEL, "item 'default'", "campo '%s'" % field, "obrigatório ausente"])
	var negative: Dictionary = _valid_record()
	negative["time_cost_per_hour"] = -1
	_expect_failure("custo negativo", [negative], [FILE_LABEL, "item 'default'", "campo 'time_cost_per_hour'", "abaixo do mínimo"])
	var too_heavy: Dictionary = _valid_record()
	too_heavy["urgency_weight_critical"] = 101
	_expect_failure("peso acima do máximo", [too_heavy], [FILE_LABEL, "campo 'urgency_weight_critical'", "acima do máximo"])
	var huge_bonus: Dictionary = _valid_record()
	huge_bonus["inertia_bonus"] = 10001
	_expect_failure("bônus acima do máximo", [huge_bonus], [FILE_LABEL, "campo 'inertia_bonus'", "acima do máximo"])
	var as_text: Dictionary = _valid_record()
	as_text["routine_bonus"] = "40"
	_expect_failure("bônus como texto", [as_text], [FILE_LABEL, "campo 'routine_bonus'", "tipo inválido"])
	var fraction: Dictionary = _valid_record()
	fraction["risk_cost_percent"] = 99.5
	_expect_failure("percentual com fração", [fraction], [FILE_LABEL, "campo 'risk_cost_percent'", "tipo inválido"])
	var unknown: Dictionary = _valid_record()
	unknown["money_cost"] = 3
	_expect_failure("campo desconhecido", [unknown], [FILE_LABEL, "item 'default'", "campo 'money_cost'", "campo desconhecido"])
	var bad_id: Dictionary = _valid_record()
	bad_id["id"] = "Default"
	_expect_failure("id fora do padrão", [bad_id], [FILE_LABEL, "item 'Default'", "campo 'id'", "snake_case"])


func test_the_file_must_have_exactly_one_row() -> void:
	_expect_failure("nenhuma linha", [], [FILE_LABEL, "esperada exatamente 1 linha", "encontradas 0"])
	var second: Dictionary = _valid_record()
	second["id"] = "other"
	_expect_failure("duas linhas", [_valid_record(), second], [FILE_LABEL, "esperada exatamente 1 linha", "encontradas 2"])


func test_weights_cannot_decrease_with_the_urgency_level() -> void:
	var attention_below: Dictionary = _valid_record()
	attention_below["urgency_weight_comfortable"] = 2
	attention_below["urgency_weight_attention"] = 1
	_expect_failure("atenção abaixo do confortável", [attention_below], [FILE_LABEL, "item 'default'", "campo 'urgency_weight_attention'", "o peso 1 é menor que o do nível anterior (urgency_weight_comfortable = 2)"])
	var urgent_below: Dictionary = _valid_record()
	urgent_below["urgency_weight_urgent"] = 0
	_expect_failure("urgente abaixo da atenção", [urgent_below], [FILE_LABEL, "campo 'urgency_weight_urgent'", "(urgency_weight_attention = 1)"])
	var critical_below: Dictionary = _valid_record()
	critical_below["urgency_weight_critical"] = 2
	_expect_failure("crítico abaixo do urgente", [critical_below], [FILE_LABEL, "campo 'urgency_weight_critical'", "(urgency_weight_urgent = 3)"])
	var equal_weights: Dictionary = _valid_record()
	equal_weights["urgency_weight_attention"] = 0
	equal_weights["urgency_weight_urgent"] = 0
	equal_weights["urgency_weight_critical"] = 0
	assert_true(_load_records([equal_weights]).result.ok, "Pesos iguais são permitidos (só não podem diminuir).")


func test_a_missing_file_fails_pointing_at_the_file() -> void:
	var loaded: NpcParamsLoader.LoadResult = NpcParamsLoader.load_dir("res://tests/fixtures/data/ok")
	assert_false(loaded.result.ok)
	assert_eq(loaded.result.code, ISSUE_CODE)
	assert_string_contains(loaded.result.message, "npc_params.json")
	assert_string_contains(loaded.result.message, "arquivo não encontrado")
