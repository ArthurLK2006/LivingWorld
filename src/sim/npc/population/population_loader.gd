class_name PopulationLoader
extends RefCounted
## Lê e valida data/population.json pelo módulo `data` (LW-067; contrato em docs/modules/npc.md, seção 1). Uma linha por (assentamento,
## ofício): `id`, `settlement_id`, `occupation_id` e `count` (quantos NPCs nascem). O que o esquema não vê é conferido aqui: ao menos uma
## linha, assentamento e ofício não vazios e um par (assentamento, ofício) por linha. Que o assentamento, o ofício e as vagas EXISTEM é
## conferido por quem monta a população (`PopulationPlan.build_specs`), porque o `data` só confere referência dentro da mesma leitura.
## Qualquer problema vira falha com arquivo, item e campo. Nunca carrega recurso nem executa nada do arquivo.

const POPULATION_TABLE: String = "population"
const DEFAULT_FILE: String = "population.json"
const DEFAULT_DIR: String = "res://data"
const CODE_INVALID: String = "NPC_POPULATION_INVALID"
## Faixa de segurança [HIP] do número de NPCs de uma linha (não é limite de design; a escala de 100 a 300 é provisória, DEC-040).
const MAX_COUNT: int = 10000


## Esquema da tabela; o nome do arquivo pode ser trocado (testes).
static func build_schema(file_name: String = DEFAULT_FILE) -> DataSchema:
	var schema: DataSchema = DataSchema.new(POPULATION_TABLE, file_name)
	schema.add_field("settlement_id", DataSchema.FieldType.STRING)
	schema.add_field("occupation_id", DataSchema.FieldType.STRING)
	schema.add_field("count", DataSchema.FieldType.INT).set_range(1, MAX_COUNT)
	return schema


## Lê o arquivo, valida e monta o plano de população.
static func load_dir(base_dir: String = DEFAULT_DIR, file_name: String = DEFAULT_FILE) -> LoadResult:
	var bundle: DataBundle = DataLoader.load_all(base_dir, [build_schema(file_name)])
	return from_bundle(bundle)


## Confere o que o esquema não vê e monta o plano de um pacote já lido e validado pelo `data`.
static func from_bundle(bundle: DataBundle) -> LoadResult:
	check_semantics(bundle)
	if not bundle.is_valid():
		return LoadResult.new(Result.failure(CODE_INVALID, bundle.describe_issues()), null)
	return LoadResult.new(Result.success(), PopulationPlan.new(_build_rows(bundle)))


## Acrescenta ao pacote o que o esquema não vê (ver o cabeçalho).
static func check_semantics(bundle: DataBundle) -> void:
	if not bundle.tables.has(POPULATION_TABLE):
		return
	var file_path: String = bundle.file_paths[POPULATION_TABLE]
	var records: Array = bundle.tables[POPULATION_TABLE]
	if records.is_empty():
		bundle.add_issue(file_path, "", "", "esperada ao menos 1 linha de população, encontradas 0")
	var seen_pairs: Dictionary[String, String] = {}
	for record: Dictionary in records:
		var item: String = str(record.get("id", ""))
		var settlement: Variant = record.get("settlement_id")
		var occupation: Variant = record.get("occupation_id")
		if typeof(settlement) != TYPE_STRING or typeof(occupation) != TYPE_STRING:
			continue
		var settlement_id: String = settlement
		var occupation_id: String = occupation
		if settlement_id.is_empty():
			bundle.add_issue(file_path, item, "settlement_id", "o assentamento não pode ficar vazio")
		if occupation_id.is_empty():
			bundle.add_issue(file_path, item, "occupation_id", "o ofício não pode ficar vazio")
		var pair: String = "%s/%s" % [settlement_id, occupation_id]
		if seen_pairs.has(pair):
			bundle.add_issue(file_path, item, "occupation_id", "o ofício '%s' já tem linha no assentamento '%s' (linha '%s'); esperada uma linha por par" % [occupation_id, settlement_id, seen_pairs[pair]])
		else:
			seen_pairs[pair] = item


static func _build_rows(bundle: DataBundle) -> Array[PopulationPlan.PopulationRow]:
	var rows: Array[PopulationPlan.PopulationRow] = []
	for record: Dictionary in bundle.tables[POPULATION_TABLE]:
		rows.append(PopulationPlan.PopulationRow.new(record["settlement_id"], record["occupation_id"], record["count"]))
	return rows


## Resultado do carregamento: `plan` só vale se `result.ok` (mesmo padrão dos outros carregadores).
class LoadResult:
	extends RefCounted

	var result: Result
	var plan: PopulationPlan

	func _init(load_result: Result, loaded_plan: PopulationPlan) -> void:
		result = load_result
		plan = loaded_plan
