class_name TraitLoader
extends RefCounted
## Lê e valida data/traits.json pelo módulo `data` (LW-057; contrato em docs/modules/npc.md, seção 1). Cada objeto tem `id` (texto em
## snake_case, único) e `order` (posição do traço no estado do NPC). A tabela precisa ter UM traço por posição, de 0 a
## NpcState.TRAIT_COUNT - 1: o estado guarda os traços por posição fixa, então acrescentar um traço é mudar o código e o save, não só
## o dado. Qualquer problema vira falha com arquivo, item e campo. Nunca carrega recurso nem executa nada do arquivo.

const TRAITS_TABLE: String = "traits"
const DEFAULT_FILE: String = "traits.json"
const DEFAULT_DIR: String = "res://data"
const CODE_INVALID: String = "TRAIT_DATA_INVALID"


## Esquema da tabela; o nome do arquivo pode ser trocado (testes).
static func build_schema(file_name: String = DEFAULT_FILE) -> DataSchema:
	var schema: DataSchema = DataSchema.new(TRAITS_TABLE, file_name)
	schema.add_field("order", DataSchema.FieldType.INT).set_range(0, NpcState.TRAIT_COUNT - 1)
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


## Acrescenta ao pacote o que o esquema não vê: `order` repetido e quantidade diferente de NpcState.TRAIT_COUNT. Registro com
## problema de tipo é pulado (o erro já foi relatado). Também usada pelo carregador do catálogo de ações.
static func check_semantics(bundle: DataBundle) -> void:
	if not bundle.tables.has(TRAITS_TABLE):
		return
	var file_path: String = bundle.file_paths[TRAITS_TABLE]
	var records: Array = bundle.tables[TRAITS_TABLE]
	if records.size() != NpcState.TRAIT_COUNT:
		bundle.add_issue(file_path, "", "", "esperado %d traços (um por posição de 0 a %d), encontrados %d" % [NpcState.TRAIT_COUNT, NpcState.TRAIT_COUNT - 1, records.size()])
	var first_owner: Dictionary[int, String] = {}
	for record: Dictionary in records:
		if typeof(record.get("order")) != TYPE_INT:
			continue
		var order: int = record["order"]
		var item: String = str(record.get("id", ""))
		if first_owner.has(order):
			bundle.add_issue(file_path, item, "order", "posição %d já usada pelo traço '%s'; cada traço precisa de uma posição própria" % [order, first_owner[order]])
		else:
			first_owner[order] = item


static func _build(bundle: DataBundle) -> Array[TraitDef]:
	var by_order: Dictionary[int, TraitDef] = {}
	for record: Dictionary in bundle.tables[TRAITS_TABLE]:
		by_order[record["order"]] = TraitDef.new(str(record["id"]), record["order"])
	var defs: Array[TraitDef] = []
	for order: int in range(NpcState.TRAIT_COUNT):
		defs.append(by_order[order])
	return defs


## Definição de um traço de personalidade (conteúdo de data/traits.json, somente leitura depois de montado). O NpcState guarda o
## valor de cada traço por POSIÇÃO (`order`); este objeto liga a posição ao id de conteúdo (ex.: "caution"), que a LW-059 usa para
## validar os pesos de personalidade das ações. Nada aqui é salvo.
class TraitDef:
	extends RefCounted

	var id: String
	## Posição do traço no estado do NPC, de 0 a NpcState.TRAIT_COUNT - 1.
	var order: int

	func _init(trait_id: String, trait_order: int) -> void:
		id = trait_id
		order = trait_order


## Resultado do carregamento: `traits` só vale se `result.ok` (mesmo padrão dos outros carregadores).
class LoadResult:
	extends RefCounted

	var result: Result
	var traits: Array[TraitDef]

	func _init(load_result: Result, loaded_traits: Array[TraitDef]) -> void:
		result = load_result
		traits = loaded_traits
