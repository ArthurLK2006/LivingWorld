class_name CultureLoader
extends RefCounted
## Lê e valida data/world/cultures.json pelo módulo `data` (LW-118a; formato em docs/modules/world.md, "Extensão da Fase 4", e docs/fase-4/dados.md, seção 1). Cultura: `id`, `name_key` (texto não
## vazio) e os quatro parâmetros `trade_openness`, `foreigner_tolerance`, `martial_stance` e `authority_weight` (inteiros de 0 a 100). Além do esquema: o arquivo precisa ter ao menos uma
## cultura. Quais culturas existem e de quem é cada uma é conteúdo e decisão de dados (a de cada povoado entra na LW-118c). Qualquer problema vira falha com arquivo, item e campo; nunca carrega
## recurso nem executa nada do arquivo. Mesmo padrão do RouteLoader.

const CULTURES_TABLE: String = "cultures"
const DEFAULT_CULTURES_FILE: String = "cultures.json"
const CODE_INVALID: String = "CULTURE_DATA_INVALID"
## Os quatro parâmetros, na ordem do contrato.
const PARAMETERS: Array[String] = ["trade_openness", "foreigner_tolerance", "martial_stance", "authority_weight"]


## Esquema da tabela; o nome do arquivo pode ser trocado (testes).
static func build_schema(cultures_file: String = DEFAULT_CULTURES_FILE) -> DataSchema:
	var cultures: DataSchema = DataSchema.new(CULTURES_TABLE, cultures_file)
	cultures.add_field("name_key", DataSchema.FieldType.STRING)
	for parameter: String in PARAMETERS:
		cultures.add_field(parameter, DataSchema.FieldType.INT).set_range(Culture.MIN_PARAMETER, Culture.MAX_PARAMETER)
	return cultures


## Lê, valida e monta as culturas, na ordem do arquivo.
static func load_dir(base_dir: String, cultures_file: String = DEFAULT_CULTURES_FILE) -> LoadResult:
	var schemas: Array[DataSchema] = [build_schema(cultures_file)]
	var bundle: DataBundle = DataLoader.load_all(base_dir, schemas)
	if bundle.tables.has(CULTURES_TABLE):
		_check_semantics(bundle)
	if not bundle.is_valid():
		return LoadResult.new(Result.failure(CODE_INVALID, bundle.describe_issues()), [])
	var cultures: Array[Culture] = []
	for record: Dictionary in bundle.tables[CULTURES_TABLE]:
		cultures.append(Culture.new(str(record["id"]), str(record["name_key"]), int(record["trade_openness"]), int(record["foreigner_tolerance"]), int(record["martial_stance"]), int(record["authority_weight"])))
	return LoadResult.new(Result.success(), cultures)


## O que o esquema não vê: texto do nome não vazio e ao menos uma cultura. Registro com problema de tipo é pulado (o erro já foi relatado).
static func _check_semantics(bundle: DataBundle) -> void:
	var file_path: String = bundle.file_paths[CULTURES_TABLE]
	if bundle.tables[CULTURES_TABLE].is_empty():
		bundle.add_issue(file_path, "", "id", "nenhuma cultura no arquivo; esperado ao menos uma")
	for record: Dictionary in bundle.tables[CULTURES_TABLE]:
		if typeof(record.get("name_key")) == TYPE_STRING and str(record["name_key"]).strip_edges().is_empty():
			bundle.add_issue(file_path, str(record.get("id", "")), "name_key", "chave de texto vazia; esperado o nome de uma chave de data/text")


## Resultado do carregamento: `cultures` só vale se `result.ok` (mesmo padrão de RouteLoader.LoadResult).
class LoadResult:
	extends RefCounted

	var result: Result
	var cultures: Array[Culture]

	func _init(load_result: Result, loaded_cultures: Array[Culture]) -> void:
		result = load_result
		cultures = loaded_cultures
