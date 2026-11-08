class_name NpcIntentParams
extends RefCounted
## Parâmetros [HIP] do protocolo de Intents do modo S0 (LW-070; contrato em docs/modules/npc.md, seção 6) e o carregador de
## data/intent_params.json, num arquivo só (teto de arquivos da tarefa). UMA linha (tabela plana) com `id` e `intent_timeout_min`: os
## minutos de simulação que um Intent sem resultado espera DEPOIS da duração esperada; passou disso, a ação é cancelada sem efeito.
## Arquivo só do protocolo, e não o `npc_params.json` do contrato (outra tarefa do módulo o cria; dois arquivos novos de mesmo nome
## colidiriam): unificar depois. Qualquer problema vira falha com arquivo, item e campo. Nunca carrega recurso nem executa nada do arquivo.

const TABLE: String = "intent_params"
const DEFAULT_FILE: String = "intent_params.json"
const DEFAULT_DIR: String = "res://data"
const CODE_INVALID: String = "NPC_INTENT_PARAMS_INVALID"
## Faixa aceita [HIP]: de 1 minuto a 1 dia de simulação.
const MIN_TIMEOUT_MIN: int = 1
const MAX_TIMEOUT_MIN: int = 1440

var intent_timeout_min: int


func _init(timeout_min: int) -> void:
	intent_timeout_min = timeout_min


## Texto vazio se os valores servem; senão o motivo (para quem monta os parâmetros por código, sem passar pelo arquivo).
func problem() -> String:
	if intent_timeout_min < MIN_TIMEOUT_MIN or intent_timeout_min > MAX_TIMEOUT_MIN:
		return "intent_timeout_min %d fora da faixa; esperado de %d a %d minutos" % [intent_timeout_min, MIN_TIMEOUT_MIN, MAX_TIMEOUT_MIN]
	return ""


## Esquema da tabela; o nome do arquivo pode ser trocado (testes).
static func build_schema(file_name: String = DEFAULT_FILE) -> DataSchema:
	var schema: DataSchema = DataSchema.new(TABLE, file_name)
	schema.add_field("intent_timeout_min", DataSchema.FieldType.INT).set_range(MIN_TIMEOUT_MIN, MAX_TIMEOUT_MIN)
	return schema


## Lê o arquivo, valida e monta os parâmetros.
static func load_dir(base_dir: String = DEFAULT_DIR, file_name: String = DEFAULT_FILE) -> LoadResult:
	var bundle: DataBundle = DataLoader.load_all(base_dir, [build_schema(file_name)])
	_check_semantics(bundle)
	if not bundle.is_valid():
		return LoadResult.new(Result.failure(CODE_INVALID, bundle.describe_issues()), null)
	var record: Dictionary = bundle.tables[TABLE][0]
	return LoadResult.new(Result.success(), NpcIntentParams.new(record["intent_timeout_min"]))


## O que o esquema não vê: exatamente uma linha. Tabela ausente também é relatada pelo esquema (aqui só se pula).
static func _check_semantics(bundle: DataBundle) -> void:
	if not bundle.tables.has(TABLE):
		return
	var records: Array = bundle.tables[TABLE]
	if records.size() != 1:
		bundle.add_issue(bundle.file_paths[TABLE], "", "", "esperada exatamente 1 linha de parâmetros, encontradas %d" % records.size())


## Resultado do carregamento: `params` só vale se `result.ok` (mesmo padrão dos outros carregadores).
class LoadResult:
	extends RefCounted

	var result: Result
	var params: NpcIntentParams

	func _init(load_result: Result, loaded_params: NpcIntentParams) -> void:
		result = load_result
		params = loaded_params
