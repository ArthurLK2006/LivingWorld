class_name MemoryKindLoader
extends RefCounted
## Lê e valida data/memory_kinds.json pelo módulo `data` (LW-078; contrato em docs/modules/npc.md, seção 7). Cada objeto é um TIPO de
## episódio: `id` (texto em snake_case, único), `valence` (de -100 a 100: o quanto o episódio é bom ou ruim), `salience` (de 0 a 100: a
## importância de partida) e `decay_per_day` (de 0 a 100: pontos de saliência que o episódio perde por dia). Os números são [HIP]. Qualquer
## problema vira falha com arquivo, item e campo. Nunca carrega recurso nem executa nada do arquivo.

const KINDS_TABLE: String = "memory_kinds"
const DEFAULT_FILE: String = "memory_kinds.json"
const DEFAULT_DIR: String = "res://data"
const CODE_INVALID: String = "MEMORY_KIND_DATA_INVALID"


## Esquema da tabela; o nome do arquivo pode ser trocado (testes).
static func build_schema(file_name: String = DEFAULT_FILE) -> DataSchema:
	var schema: DataSchema = DataSchema.new(KINDS_TABLE, file_name)
	schema.add_field("valence", DataSchema.FieldType.INT).set_range(MemoryRecord.MIN_VALENCE, MemoryRecord.MAX_VALENCE)
	schema.add_field("salience", DataSchema.FieldType.INT).set_range(MemoryRecord.MIN_SALIENCE, MemoryRecord.MAX_SALIENCE)
	schema.add_field("decay_per_day", DataSchema.FieldType.INT).set_range(0, MemoryRecord.MAX_SALIENCE)
	return schema


## Lê o arquivo, valida e monta os tipos, na ordem do arquivo.
static func load_dir(base_dir: String = DEFAULT_DIR, file_name: String = DEFAULT_FILE) -> LoadResult:
	var bundle: DataBundle = DataLoader.load_all(base_dir, [build_schema(file_name)])
	return from_bundle(bundle)


## Monta os tipos de um pacote já lido e validado pelo `data`.
static func from_bundle(bundle: DataBundle) -> LoadResult:
	if not bundle.is_valid():
		return LoadResult.new(Result.failure(CODE_INVALID, bundle.describe_issues()), [])
	var kinds: Array[KindDef] = []
	for record: Dictionary in bundle.tables[KINDS_TABLE]:
		kinds.append(KindDef.new(str(record["id"]), record["valence"], record["salience"], record["decay_per_day"]))
	return LoadResult.new(Result.success(), kinds)


## Tipo de episódio (conteúdo de data/memory_kinds.json, somente leitura depois de montado). Nada aqui é salvo: o registro guarda só o `id`.
class KindDef:
	extends RefCounted

	var id: String
	var valence: int
	var salience: int
	var decay_per_day: int

	func _init(kind_id: String, kind_valence: int, kind_salience: int, kind_decay_per_day: int) -> void:
		id = kind_id
		valence = kind_valence
		salience = kind_salience
		decay_per_day = kind_decay_per_day


## Resultado do carregamento: `kinds` só vale se `result.ok` (mesmo padrão dos outros carregadores).
class LoadResult:
	extends RefCounted

	var result: Result
	var kinds: Array[KindDef]

	func _init(load_result: Result, loaded_kinds: Array[KindDef]) -> void:
		result = load_result
		kinds = loaded_kinds
