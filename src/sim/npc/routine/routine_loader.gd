class_name RoutineLoader
extends RefCounted
## Lê e valida os ofícios e a agenda (LW-061; contrato em docs/modules/npc.md, seção 4) pelo módulo `data`: data/occupations.json (`id`,
## `work_place_kind`) e data/routine_blocks.json (`id`, `occupation_id`, `from_hour` de 0 a 23, `to_hour` de 1 a 24 exclusivo,
## `action_id`). Para conferir as ações da agenda, lê JUNTO o catálogo de ações (o `data` só confere referência entre tabelas da mesma
## leitura) e reaproveita a conferência dele. Cada ofício cobre EXATAMENTE as 24 horas, sem lacuna nem sobreposição; ofício ou ação
## inexistente é rejeitado; qualquer problema vira falha com arquivo, item e campo. Nunca carrega recurso nem executa nada do arquivo.

const OCCUPATIONS_TABLE: String = "occupations"
const ROUTINE_TABLE: String = "routine_blocks"
const DEFAULT_DIR: String = "res://data"
const CODE_INVALID: String = "ROUTINE_DATA_INVALID"


## Esquemas das oito tabelas lidas juntas: as seis do catálogo de ações (só para as referências) mais ofícios e agenda.
static func build_schemas() -> Array[DataSchema]:
	var schemas: Array[DataSchema] = ActionCatalogLoader.build_schemas()
	var occupations: DataSchema = DataSchema.new(OCCUPATIONS_TABLE, "occupations.json")
	occupations.add_field("work_place_kind", DataSchema.FieldType.STRING)
	schemas.append(occupations)
	var blocks: DataSchema = DataSchema.new(ROUTINE_TABLE, "routine_blocks.json")
	blocks.add_field("occupation_id", DataSchema.FieldType.STRING).set_ref(OCCUPATIONS_TABLE)
	blocks.add_field("from_hour", DataSchema.FieldType.INT).set_range(0, RoutineTable.HOURS_PER_DAY - 1)
	blocks.add_field("to_hour", DataSchema.FieldType.INT).set_range(1, RoutineTable.HOURS_PER_DAY)
	blocks.add_field("action_id", DataSchema.FieldType.STRING).set_ref(ActionCatalogLoader.ACTIONS_TABLE)
	schemas.append(blocks)
	return schemas


## Lê os arquivos de `base_dir`, valida e monta a tabela de rotina.
static func load_dir(base_dir: String = DEFAULT_DIR) -> LoadResult:
	return _finish(DataLoader.load_all(base_dir, build_schemas()))


## Mesmo caminho a partir de tabelas já em memória (id da tabela -> registros), sem tocar em disco: para testar dado inválido.
## `base_dir` só rotula os arquivos nas mensagens.
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
	ActionCatalogLoader.check_semantics(bundle)
	_check_occupations(bundle)
	_check_blocks(bundle)
	if not bundle.is_valid():
		return LoadResult.new(Result.failure(CODE_INVALID, bundle.describe_issues()), null)
	return LoadResult.new(Result.success(), _build(bundle))


## `work_place_kind` precisa ser um tipo do vocabulário de locais do `world`.
static func _check_occupations(bundle: DataBundle) -> void:
	if not bundle.tables.has(OCCUPATIONS_TABLE):
		return
	var file_path: String = bundle.file_paths[OCCUPATIONS_TABLE]
	for record: Dictionary in bundle.tables[OCCUPATIONS_TABLE]:
		var kind: Variant = record.get("work_place_kind")
		if typeof(kind) == TYPE_STRING and not Place.KINDS.has(str(kind)):
			bundle.add_issue(file_path, str(record.get("id", "")), "work_place_kind", "tipo de local '%s' inexistente; esperado um de: %s" % [kind, ", ".join(Place.KINDS)])


## Cada bloco com início antes do fim e, por ofício, a agenda sem lacuna e sem sobreposição, de 0 a 24.
static func _check_blocks(bundle: DataBundle) -> void:
	if not bundle.tables.has(ROUTINE_TABLE) or not bundle.tables.has(OCCUPATIONS_TABLE):
		return
	var file_path: String = bundle.file_paths[ROUTINE_TABLE]
	var by_occupation: Dictionary[String, Array] = {}
	for record: Dictionary in bundle.tables[ROUTINE_TABLE]:
		if typeof(record.get("from_hour")) != TYPE_INT or typeof(record.get("to_hour")) != TYPE_INT or typeof(record.get("occupation_id")) != TYPE_STRING:
			continue
		var item: String = str(record.get("id", ""))
		var from_hour: int = record["from_hour"]
		var to_hour: int = record["to_hour"]
		if to_hour <= from_hour:
			bundle.add_issue(file_path, item, "to_hour", "a hora final %d não é maior que a inicial %d" % [to_hour, from_hour])
			continue
		var occupation_id: String = record["occupation_id"]
		if not by_occupation.has(occupation_id):
			by_occupation[occupation_id] = []
		by_occupation[occupation_id].append(record)
	for occupation: Dictionary in bundle.tables[OCCUPATIONS_TABLE]:
		var occupation_id: String = str(occupation.get("id", ""))
		var blocks: Array = by_occupation.get(occupation_id, [])
		_check_coverage(bundle, file_path, occupation_id, blocks)


## `blocks`: os registros do ofício. Ordena por hora inicial (empate: ordem do arquivo) e confere de 0 a 24 sem lacuna nem sobreposição.
static func _check_coverage(bundle: DataBundle, file_path: String, occupation_id: String, blocks: Array) -> void:
	if blocks.is_empty():
		bundle.add_issue(file_path, occupation_id, "", "o ofício não tem nenhuma linha de agenda; esperado cobrir as %d horas do dia" % RoutineTable.HOURS_PER_DAY)
		return
	var ordered: Array = blocks.duplicate()
	ordered.sort_custom(func(first: Dictionary, second: Dictionary) -> bool: return int(first["from_hour"]) < int(second["from_hour"]))
	var first_block: Dictionary = ordered[0]
	if int(first_block["from_hour"]) != 0:
		bundle.add_issue(file_path, str(first_block["id"]), "from_hour", "a agenda de '%s' começa na hora %d; esperado 0" % [occupation_id, int(first_block["from_hour"])])
	for index: int in range(1, ordered.size()):
		var previous: Dictionary = ordered[index - 1]
		var current: Dictionary = ordered[index]
		var previous_end: int = int(previous["to_hour"])
		var start: int = int(current["from_hour"])
		if start > previous_end:
			bundle.add_issue(file_path, str(current["id"]), "from_hour", "lacuna na agenda de '%s': o bloco '%s' termina na hora %d e este começa na %d" % [occupation_id, str(previous["id"]), previous_end, start])
		elif start < previous_end:
			bundle.add_issue(file_path, str(current["id"]), "from_hour", "sobreposição na agenda de '%s': o bloco '%s' vai até a hora %d e este começa na %d" % [occupation_id, str(previous["id"]), previous_end, start])
	var last_block: Dictionary = ordered[ordered.size() - 1]
	if int(last_block["to_hour"]) != RoutineTable.HOURS_PER_DAY:
		bundle.add_issue(file_path, str(last_block["id"]), "to_hour", "a agenda de '%s' termina na hora %d; esperado %d" % [occupation_id, int(last_block["to_hour"]), RoutineTable.HOURS_PER_DAY])


static func _build(bundle: DataBundle) -> RoutineTable:
	var occupations: Array[RoutineTable.OccupationDef] = []
	for record: Dictionary in bundle.tables[OCCUPATIONS_TABLE]:
		occupations.append(RoutineTable.OccupationDef.new(str(record["id"]), str(record["work_place_kind"])))
	var blocks: Array[RoutineTable.RoutineBlock] = []
	for record: Dictionary in bundle.tables[ROUTINE_TABLE]:
		blocks.append(RoutineTable.RoutineBlock.new(str(record["id"]), str(record["occupation_id"]), record["from_hour"], record["to_hour"], str(record["action_id"])))
	return RoutineTable.new(occupations, blocks)


## Resultado do carregamento: `table` só vale se `result.ok` (mesmo padrão dos outros carregadores).
class LoadResult:
	extends RefCounted

	var result: Result
	var table: RoutineTable

	func _init(load_result: Result, loaded_table: RoutineTable) -> void:
		result = load_result
		table = loaded_table
