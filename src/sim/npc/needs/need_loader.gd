class_name NeedLoader
extends RefCounted
## Lê e valida data/needs.json pelo módulo `data` (LW-058; contrato em docs/modules/npc.md, seção 2). Cada objeto tem `id` (texto em
## snake_case, único), `order` (posição no estado do NPC), `start_value` (0 a 100), `rate_per_hour` (inteiro, pode ser negativo) e os
## limiares `attention`, `urgent` e `critical` (0 a 100, estritamente crescentes). A tabela precisa ter UMA necessidade por posição, de
## 0 a NpcState.NEED_COUNT - 1. Qualquer problema vira falha com arquivo, item e campo. Nunca carrega recurso nem executa nada do arquivo.
## Os pesos de utilidade e os limites de fome letal (seção 2 do contrato) entram nas tarefas que os usam (LW-062 e LW-081).

const NEEDS_TABLE: String = "needs"
const DEFAULT_FILE: String = "needs.json"
const DEFAULT_DIR: String = "res://data"
const CODE_INVALID: String = "NEED_DATA_INVALID"
## Faixa de segurança [HIP] da taxa: mais de 100 pontos por hora satura qualquer necessidade em menos de uma hora.
const MAX_RATE_PER_HOUR: int = 100


## Esquema da tabela; o nome do arquivo pode ser trocado (testes).
static func build_schema(file_name: String = DEFAULT_FILE) -> DataSchema:
	var schema: DataSchema = DataSchema.new(NEEDS_TABLE, file_name)
	schema.add_field("order", DataSchema.FieldType.INT).set_range(0, NpcState.NEED_COUNT - 1)
	schema.add_field("start_value", DataSchema.FieldType.INT).set_range(NpcState.VALUE_MIN, NpcState.VALUE_MAX)
	schema.add_field("rate_per_hour", DataSchema.FieldType.INT).set_range(-MAX_RATE_PER_HOUR, MAX_RATE_PER_HOUR)
	for threshold: String in ["attention", "urgent", "critical"]:
		schema.add_field(threshold, DataSchema.FieldType.INT).set_range(NpcState.VALUE_MIN, NpcState.VALUE_MAX)
	return schema


## Lê o arquivo, valida e monta as definições, na ordem de `order`.
static func load_dir(base_dir: String = DEFAULT_DIR, file_name: String = DEFAULT_FILE) -> LoadResult:
	var bundle: DataBundle = DataLoader.load_all(base_dir, [build_schema(file_name)])
	return from_bundle(bundle)


## Confere o que o esquema não vê e monta as definições de um pacote já lido e validado pelo `data`.
static func from_bundle(bundle: DataBundle) -> LoadResult:
	check_semantics(bundle)
	if not bundle.is_valid():
		return LoadResult.new(Result.failure(CODE_INVALID, bundle.describe_issues()), [])
	return LoadResult.new(Result.success(), _build(bundle))


## Acrescenta ao pacote o que o esquema não vê: quantidade diferente de NpcState.NEED_COUNT, `order` repetida e limiares que não
## crescem. Registro com problema de tipo é pulado (o erro já foi relatado). Também usada pelo carregador do catálogo de ações.
static func check_semantics(bundle: DataBundle) -> void:
	if not bundle.tables.has(NEEDS_TABLE):
		return
	var file_path: String = bundle.file_paths[NEEDS_TABLE]
	var records: Array = bundle.tables[NEEDS_TABLE]
	if records.size() != NpcState.NEED_COUNT:
		bundle.add_issue(file_path, "", "", "esperado %d necessidades (uma por posição de 0 a %d), encontradas %d" % [NpcState.NEED_COUNT, NpcState.NEED_COUNT - 1, records.size()])
	var first_owner: Dictionary[int, String] = {}
	for record: Dictionary in records:
		var item: String = str(record.get("id", ""))
		if typeof(record.get("order")) == TYPE_INT:
			var order: int = record["order"]
			if first_owner.has(order):
				bundle.add_issue(file_path, item, "order", "posição %d já usada pela necessidade '%s'; cada necessidade precisa de uma posição própria" % [order, first_owner[order]])
			else:
				first_owner[order] = item
		_check_thresholds(bundle, file_path, item, record)


## `attention` < `urgent` < `critical`; só confere se os três já passaram pelo esquema como inteiros.
static func _check_thresholds(bundle: DataBundle, file_path: String, item: String, record: Dictionary) -> void:
	for field: String in ["attention", "urgent", "critical"]:
		if typeof(record.get(field)) != TYPE_INT:
			return
	if int(record["urgent"]) <= int(record["attention"]):
		bundle.add_issue(file_path, item, "urgent", "limiares precisam crescer (attention < urgent < critical): urgent %d não é maior que attention %d" % [record["urgent"], record["attention"]])
	if int(record["critical"]) <= int(record["urgent"]):
		bundle.add_issue(file_path, item, "critical", "limiares precisam crescer (attention < urgent < critical): critical %d não é maior que urgent %d" % [record["critical"], record["urgent"]])


static func _build(bundle: DataBundle) -> Array[NeedDef]:
	var by_order: Dictionary[int, NeedDef] = {}
	for record: Dictionary in bundle.tables[NEEDS_TABLE]:
		by_order[record["order"]] = NeedDef.new(str(record["id"]), record["order"], record["start_value"], record["rate_per_hour"], record["attention"], record["urgent"], record["critical"])
	var defs: Array[NeedDef] = []
	for order: int in range(NpcState.NEED_COUNT):
		defs.append(by_order[order])
	return defs


## Resultado do carregamento: `needs` só vale se `result.ok` (mesmo padrão dos outros carregadores).
class LoadResult:
	extends RefCounted

	var result: Result
	var needs: Array[NeedDef]

	func _init(load_result: Result, loaded_needs: Array[NeedDef]) -> void:
		result = load_result
		needs = loaded_needs
