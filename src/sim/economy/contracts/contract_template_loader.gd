class_name ContractTemplateLoader
extends RefCounted
## Lê e valida data/economy/contract_templates.json pelo módulo `data` (LW-107c1; docs/economy/dados.md), LENDO JUNTO os bens e os tipos de dono (para a referência `good_id` e para o peso do lote). O arquivo é OPCIONAL, como `service_posts.json`: sem ele não
## há modelo (lista vazia); a tabela, se existe, pode estar vazia. O esquema confere campos, tipos e faixas (nenhum FLOAT); o que ele não vê é conferido aqui: `kind` igual a `delivery`, `trigger` do vocabulário fechado, o bônus dentro do teto do gatilho do
## PRÓPRIO modelo, um modelo por bem e o lote (`quantity x weight`) que cabe no jogador. Falha com `ECON_DATA_INVALID`, arquivo, item e campo. Nunca carrega recurso, executa nada do arquivo, lança erro nem escreve no log.

const TEMPLATES_TABLE: String = "contract_templates"
const TEMPLATES_FILE: String = "contract_templates.json"
## Tipo de dono do jogador em `owner_kinds.json`: a `weight_capacity` dele é o máximo que o lote de um contrato pode pesar.
const KIND_PLAYER: String = "player"
const NOT_FOUND: int = -1
## Teto de 1 bilhão nas colunas inteiras (evita estouro de inteiro nas contas; como nos outros carregadores).
const MAX_VALUE: int = 1000000000
const MIN_QUANTITY: int = 1
## Faixas [HIP] do `dados.md`. O bônus tem um teto por gatilho: o `standing` termina em 1000 porque o `ask` do mercado já inclui o `spread_bp` de 10%.
const MIN_MARGIN_BP: int = 0
const SHORTAGE_MAX_MARGIN_BP: int = 5000
const STANDING_MAX_MARGIN_BP: int = 1000
const MIN_DEADLINE_HOURS: int = 1
const MAX_DEADLINE_HOURS: int = 168
const MIN_OPEN_CAP: int = 1
const MAX_OPEN_CAP: int = 3


## Os esquemas dos bens e dos tipos de dono (só para a referência e para o peso) mais o dos modelos.
static func build_schemas() -> Array[DataSchema]:
	var schemas: Array[DataSchema] = GoodsLoader.build_schemas()
	var templates: DataSchema = DataSchema.new(TEMPLATES_TABLE, TEMPLATES_FILE)
	templates.add_field("kind", DataSchema.FieldType.STRING)
	templates.add_field("good_id", DataSchema.FieldType.STRING).set_ref(GoodsLoader.GOODS_TABLE)
	templates.add_field("quantity", DataSchema.FieldType.INT).set_range(MIN_QUANTITY, MAX_VALUE)
	templates.add_field("trigger", DataSchema.FieldType.STRING)
	templates.add_field("reward_margin_bp", DataSchema.FieldType.INT).set_range(MIN_MARGIN_BP, MAX_VALUE)
	templates.add_field("deadline_hours", DataSchema.FieldType.INT).set_range(MIN_DEADLINE_HOURS, MAX_DEADLINE_HOURS)
	templates.add_field("max_open", DataSchema.FieldType.INT).set_range(MIN_OPEN_CAP, MAX_OPEN_CAP)
	schemas.append(templates)
	return schemas


## O teto do bônus no gatilho do PRÓPRIO modelo (`trigger` já dentro do vocabulário).
static func max_margin_bp(trigger: String) -> int:
	return STANDING_MAX_MARGIN_BP if trigger == ContractTemplateDef.TRIGGER_STANDING else SHORTAGE_MAX_MARGIN_BP


## Sem o arquivo na pasta não há modelo (lista vazia, sucesso): o arquivo é opcional.
static func load_dir(base_dir: String = GoodsLoader.DEFAULT_DIR) -> LoadResult:
	if not FileAccess.file_exists(base_dir.path_join(TEMPLATES_FILE)):
		return LoadResult.new(Result.success(), [] as Array[ContractTemplateDef])
	return _finish(DataLoader.load_all(base_dir, build_schemas()))


## Mesmo caminho a partir de tabelas já em memória (id da tabela -> registros), sem tocar em disco: para testar dado inválido.
static func from_tables(tables: Dictionary[String, Array], base_dir: String) -> LoadResult:
	var schemas: Array[DataSchema] = build_schemas()
	var bundle: DataBundle = DataBundle.new()
	for schema: DataSchema in schemas:
		if tables.has(schema.table_id):
			bundle.tables[schema.table_id] = tables[schema.table_id]
			bundle.file_paths[schema.table_id] = base_dir.path_join(schema.file_name)
	DataValidator.new().validate(bundle, schemas)
	return _finish(bundle)


static func _finish(bundle: DataBundle) -> LoadResult:
	_check_templates(bundle)
	if not bundle.is_valid():
		return LoadResult.new(Result.failure(EconomyCodes.DATA_INVALID, bundle.describe_issues()), [] as Array[ContractTemplateDef])
	var templates: Array[ContractTemplateDef] = []
	for record: Dictionary in bundle.tables.get(TEMPLATES_TABLE, []):
		templates.append(ContractTemplateDef.new(str(record["id"]), str(record["kind"]), str(record["good_id"]), record["quantity"], str(record["trigger"]), record["reward_margin_bp"], record["deadline_hours"], record["max_open"]))
	return LoadResult.new(Result.success(), templates)


## O que o esquema não vê, linha a linha: `kind`, gatilho e teto do bônus, um modelo por bem e o lote que cabe no jogador. Campo de tipo errado já tem o problema do esquema e é pulado aqui.
static func _check_templates(bundle: DataBundle) -> void:
	if not bundle.tables.has(TEMPLATES_TABLE):
		return
	var file_path: String = bundle.file_paths[TEMPLATES_TABLE]
	var weights: Dictionary[String, int] = _int_column(bundle, GoodsLoader.GOODS_TABLE, "weight")
	var capacities: Dictionary[String, int] = _int_column(bundle, GoodsLoader.OWNER_KINDS_TABLE, "weight_capacity")
	var capacity: int = capacities[KIND_PLAYER] if capacities.has(KIND_PLAYER) else NOT_FOUND
	var first_of_good: Dictionary[String, String] = {}
	for record: Dictionary in bundle.tables[TEMPLATES_TABLE]:
		var item: String = str(record.get("id", ""))
		if _is_text(record, "kind") and record["kind"] != ContractBook.DELIVERY:
			bundle.add_issue(file_path, item, "kind", "o tipo '%s' não é aceito nesta etapa; esperado '%s'" % [record["kind"], ContractBook.DELIVERY])
		_check_trigger(bundle, file_path, item, record)
		if not _is_text(record, "good_id"):
			continue
		var good_id: String = record["good_id"]
		if first_of_good.has(good_id):
			bundle.add_issue(file_path, item, "good_id", "o bem '%s' já tem o modelo '%s'; esperado um modelo por bem" % [good_id, first_of_good[good_id]])
		else:
			first_of_good[good_id] = item
		_check_lot(bundle, file_path, item, record, weights[good_id] if weights.has(good_id) else NOT_FOUND, capacity)


## O gatilho do vocabulário fechado e o bônus dentro do teto DELE.
static func _check_trigger(bundle: DataBundle, file_path: String, item: String, record: Dictionary) -> void:
	if not _is_text(record, "trigger"):
		return
	var trigger: String = record["trigger"]
	if not ContractTemplateDef.TRIGGERS.has(trigger):
		bundle.add_issue(file_path, item, "trigger", "gatilho '%s' fora do vocabulário; esperado um de: %s" % [trigger, ", ".join(ContractTemplateDef.TRIGGERS)])
	elif typeof(record.get("reward_margin_bp")) == TYPE_INT and record["reward_margin_bp"] > max_margin_bp(trigger):
		bundle.add_issue(file_path, item, "reward_margin_bp", "bônus %d acima do teto de %d do gatilho '%s'" % [record["reward_margin_bp"], max_margin_bp(trigger), trigger])


## O lote cabe no jogador: `quantity x weight` do bem não passa da `weight_capacity` do tipo `player`. Bem desconhecido (`weight` NOT_FOUND) já foi apontado pela referência.
static func _check_lot(bundle: DataBundle, file_path: String, item: String, record: Dictionary, weight: int, capacity: int) -> void:
	if weight == NOT_FOUND or typeof(record.get("quantity")) != TYPE_INT:
		return
	if capacity == NOT_FOUND:
		bundle.add_issue(file_path, item, "quantity", "sem o tipo de dono '%s' em owner_kinds.json não dá para conferir se o lote cabe no jogador" % KIND_PLAYER)
		return
	var lot_weight: int = record["quantity"] * weight
	if lot_weight > capacity:
		bundle.add_issue(file_path, item, "quantity", "o lote pesa %d (quantidade %d x peso %d); passa dos %d que o jogador carrega" % [lot_weight, record["quantity"], weight, capacity])


## Id -> valor inteiro de uma coluna de outra tabela já lida (só as linhas bem formadas; as outras já têm o problema apontado).
static func _int_column(bundle: DataBundle, table: String, column: String) -> Dictionary[String, int]:
	var values: Dictionary[String, int] = {}
	for record: Dictionary in bundle.tables.get(table, []):
		if _is_text(record, "id") and typeof(record.get(column)) == TYPE_INT:
			values[record["id"]] = record[column]
	return values


static func _is_text(record: Dictionary, field: String) -> bool:
	return typeof(record.get(field)) == TYPE_STRING


## Resultado do carregamento: `templates` (na ordem do arquivo) só vale se `result.ok`.
class LoadResult:
	extends RefCounted

	var result: Result
	var templates: Array[ContractTemplateDef]

	func _init(load_result: Result, loaded_templates: Array[ContractTemplateDef]) -> void:
		result = load_result
		templates = loaded_templates
