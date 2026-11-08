class_name NpcParamsLoader
extends RefCounted
## Lê e valida data/npc_params.json pelo módulo `data` (LW-062; contrato em docs/modules/npc.md, seção 5). O arquivo tem UMA linha (`id`
## e os parâmetros inteiros da pontuação de utilidade, todos [HIP]); os pesos dos níveis de urgência não podem diminuir de um nível para o
## seguinte (uma necessidade mais urgente nunca pesa menos). Qualquer problema vira falha com arquivo, item e campo. Nunca carrega
## recurso nem executa nada do arquivo.

const PARAMS_TABLE: String = "npc_params"
const DEFAULT_FILE: String = "npc_params.json"
const DEFAULT_DIR: String = "res://data"
const CODE_INVALID: String = "NPC_PARAMS_INVALID"
## Faixas de segurança [HIP] de cada parâmetro (não são limites de design).
const MAX_URGENCY_WEIGHT: int = 100
const MAX_COST_PER_UNIT: int = 1000
const MAX_RISK_PERCENT: int = 1000
const MAX_BONUS: int = 10000
const MAX_MINUTES: int = 1440
const MAX_THINKS_PER_STEP: int = 100000
const MAX_TOP_K: int = 16
const MAX_ALARM_RADIUS_M: int = 10000
const MAX_T2_LIMIT: int = 1000
const MAX_MEMORY_CAPACITY: int = 1000
const MAX_TRAIT_SLOTS: int = 16
const URGENCY_WEIGHT_FIELDS: Array[String] = ["urgency_weight_comfortable", "urgency_weight_attention", "urgency_weight_urgent", "urgency_weight_critical"]


## Esquema da tabela; o nome do arquivo pode ser trocado (testes).
static func build_schema(file_name: String = DEFAULT_FILE) -> DataSchema:
	var schema: DataSchema = DataSchema.new(PARAMS_TABLE, file_name)
	for weight_field: String in URGENCY_WEIGHT_FIELDS:
		schema.add_field(weight_field, DataSchema.FieldType.INT).set_range(0, MAX_URGENCY_WEIGHT)
	schema.add_field("time_cost_per_hour", DataSchema.FieldType.INT).set_range(0, MAX_COST_PER_UNIT)
	schema.add_field("distance_cost_per_100m", DataSchema.FieldType.INT).set_range(0, MAX_COST_PER_UNIT)
	schema.add_field("risk_cost_percent", DataSchema.FieldType.INT).set_range(0, MAX_RISK_PERCENT)
	schema.add_field("inertia_bonus", DataSchema.FieldType.INT).set_range(0, MAX_BONUS)
	schema.add_field("routine_bonus", DataSchema.FieldType.INT).set_range(0, MAX_BONUS)
	schema.add_field("think_interval_min", DataSchema.FieldType.INT).set_range(1, MAX_MINUTES)
	schema.add_field("max_thinks_per_step", DataSchema.FieldType.INT).set_range(1, MAX_THINKS_PER_STEP)
	schema.add_field("decision_top_k", DataSchema.FieldType.INT).set_range(1, MAX_TOP_K)
	schema.add_field("decision_margin", DataSchema.FieldType.INT).set_range(0, MAX_BONUS)
	# Alarme (LW-076): opcionais; ausentes valem 0 (o alarme não alcança ninguém).
	schema.add_field("alarm_radius_m", DataSchema.FieldType.INT, false).set_range(0, MAX_ALARM_RADIUS_M)
	schema.add_field("alarm_safety_pressure", DataSchema.FieldType.INT, false).set_range(0, NpcState.VALUE_MAX)
	schema.add_field("alarm_window_min", DataSchema.FieldType.INT, false).set_range(0, MAX_MINUTES)
	# Camadas (LW-077): opcional; ausente vale 0 (sem teto de notáveis).
	schema.add_field("max_t2", DataSchema.FieldType.INT, false).set_range(0, MAX_T2_LIMIT)
	# Memória (LW-078): opcionais; ausentes valem 0, 100 e 0 (sem memória configurada, nenhum registro vira traço, nenhum traço cabe).
	schema.add_field("memory_capacity", DataSchema.FieldType.INT, false).set_range(0, MAX_MEMORY_CAPACITY)
	schema.add_field("trait_threshold", DataSchema.FieldType.INT, false).set_range(MemoryRecord.MIN_SALIENCE, MemoryRecord.MAX_SALIENCE)
	schema.add_field("trait_slots", DataSchema.FieldType.INT, false).set_range(0, MAX_TRAIT_SLOTS)
	return schema


## Lê o arquivo, valida e monta os parâmetros.
static func load_dir(base_dir: String = DEFAULT_DIR, file_name: String = DEFAULT_FILE) -> LoadResult:
	var bundle: DataBundle = DataLoader.load_all(base_dir, [build_schema(file_name)])
	return from_bundle(bundle)


## Confere o que o esquema não vê e monta os parâmetros de um pacote já lido e validado pelo `data`.
static func from_bundle(bundle: DataBundle) -> LoadResult:
	check_semantics(bundle)
	if not bundle.is_valid():
		return LoadResult.new(Result.failure(CODE_INVALID, bundle.describe_issues()), null)
	return LoadResult.new(Result.success(), _build(bundle))


## Acrescenta ao pacote o que o esquema não vê: exatamente uma linha e pesos de urgência que não diminuem com o nível.
static func check_semantics(bundle: DataBundle) -> void:
	if not bundle.tables.has(PARAMS_TABLE):
		return
	var file_path: String = bundle.file_paths[PARAMS_TABLE]
	var records: Array = bundle.tables[PARAMS_TABLE]
	if records.size() != 1:
		bundle.add_issue(file_path, "", "", "esperada exatamente 1 linha de parâmetros, encontradas %d" % records.size())
	for record: Dictionary in records:
		var item: String = str(record.get("id", ""))
		for index: int in range(1, URGENCY_WEIGHT_FIELDS.size()):
			var previous_field: String = URGENCY_WEIGHT_FIELDS[index - 1]
			var field: String = URGENCY_WEIGHT_FIELDS[index]
			if typeof(record.get(previous_field)) != TYPE_INT or typeof(record.get(field)) != TYPE_INT:
				continue
			if int(record[field]) < int(record[previous_field]):
				bundle.add_issue(file_path, item, field, "o peso %d é menor que o do nível anterior (%s = %d); os pesos não podem diminuir com a urgência" % [record[field], previous_field, record[previous_field]])


static func _build(bundle: DataBundle) -> NpcParams:
	var record: Dictionary = bundle.tables[PARAMS_TABLE][0]
	var params: NpcParams = NpcParams.new()
	params.urgency_weight_comfortable = record["urgency_weight_comfortable"]
	params.urgency_weight_attention = record["urgency_weight_attention"]
	params.urgency_weight_urgent = record["urgency_weight_urgent"]
	params.urgency_weight_critical = record["urgency_weight_critical"]
	params.time_cost_per_hour = record["time_cost_per_hour"]
	params.distance_cost_per_100m = record["distance_cost_per_100m"]
	params.risk_cost_percent = record["risk_cost_percent"]
	params.inertia_bonus = record["inertia_bonus"]
	params.routine_bonus = record["routine_bonus"]
	params.think_interval_min = record["think_interval_min"]
	params.max_thinks_per_step = record["max_thinks_per_step"]
	params.decision_top_k = record["decision_top_k"]
	params.decision_margin = record["decision_margin"]
	params.alarm_radius_m = record.get("alarm_radius_m", 0)
	params.alarm_safety_pressure = record.get("alarm_safety_pressure", 0)
	params.alarm_window_min = record.get("alarm_window_min", 0)
	params.max_t2 = record.get("max_t2", 0)
	params.memory_capacity = record.get("memory_capacity", 0)
	params.trait_threshold = record.get("trait_threshold", MemoryRecord.MAX_SALIENCE)
	params.trait_slots = record.get("trait_slots", 0)
	return params


## Resultado do carregamento: `params` só vale se `result.ok` (mesmo padrão dos outros carregadores).
class LoadResult:
	extends RefCounted

	var result: Result
	var params: NpcParams

	func _init(load_result: Result, loaded_params: NpcParams) -> void:
		result = load_result
		params = loaded_params
