class_name ActionCatalogLoader
extends RefCounted
## Lê e valida o catálogo de ações (LW-059; contrato em docs/modules/npc.md, seção 3) pelo módulo `data`. São quatro tabelas planas
## (o `data` não aceita objetos aninhados): actions.json, action_effects.json, action_conditions.json e action_trait_weights.json; cada
## linha tem `id`. Para conferir as referências, o carregador lê JUNTO traits.json e needs.json (o `data` só confere referência entre
## tabelas da mesma leitura) e reaproveita a conferência de cada um. Referência a necessidade, traço ou ação inexistente, tipo de local
## fora do vocabulário e tipo de condição desconhecido falham apontando arquivo, item e campo. Acrescentar uma ação que só usa tipos de
## condição e de efeito que já existem é EDITAR DADOS: passa na validação sem tocar em código. Só descreve: quem executa é o `ActionRunner`
## (LW-060). Nunca carrega recurso nem executa nada do arquivo.

const ACTIONS_TABLE: String = "actions"
const EFFECTS_TABLE: String = "action_effects"
const CONDITIONS_TABLE: String = "action_conditions"
const TRAIT_WEIGHTS_TABLE: String = "action_trait_weights"
const DEFAULT_DIR: String = "res://data"
const CODE_INVALID: String = "ACTION_DATA_INVALID"
## Faixas de segurança [HIP]: duração de até um dia, efeito e peso de até 100 pontos para cima ou para baixo, hora de 0 a 24.
const MAX_DURATION_MIN: int = 1440
const MAX_ABS_DELTA: int = 100
const MAX_ABS_WEIGHT: int = 100
const MAX_HOUR: int = 24


## Esquemas das seis tabelas lidas juntas: traços e necessidades (só para as referências) e as quatro do catálogo.
static func build_schemas() -> Array[DataSchema]:
	var schemas: Array[DataSchema] = [TraitLoader.build_schema(), NeedLoader.build_schema()]
	var actions: DataSchema = DataSchema.new(ACTIONS_TABLE, "actions.json")
	actions.add_field("duration_min", DataSchema.FieldType.INT).set_range(0, MAX_DURATION_MIN)
	actions.add_field("place_kind", DataSchema.FieldType.STRING)
	actions.add_field("risk", DataSchema.FieldType.INT).set_range(0, 100)
	actions.add_field("interruptible", DataSchema.FieldType.BOOL)
	schemas.append(actions)
	var effects: DataSchema = DataSchema.new(EFFECTS_TABLE, "action_effects.json")
	effects.add_field("action_id", DataSchema.FieldType.STRING).set_ref(ACTIONS_TABLE)
	effects.add_field("need_id", DataSchema.FieldType.STRING).set_ref(NeedLoader.NEEDS_TABLE)
	effects.add_field("delta", DataSchema.FieldType.INT).set_range(-MAX_ABS_DELTA, MAX_ABS_DELTA)
	schemas.append(effects)
	var conditions: DataSchema = DataSchema.new(CONDITIONS_TABLE, "action_conditions.json")
	conditions.add_field("action_id", DataSchema.FieldType.STRING).set_ref(ACTIONS_TABLE)
	conditions.add_field("kind", DataSchema.FieldType.STRING)
	conditions.add_field("need_id", DataSchema.FieldType.STRING, false).set_ref(NeedLoader.NEEDS_TABLE)
	conditions.add_field("min_value", DataSchema.FieldType.INT, false).set_range(0, NpcState.VALUE_MAX)
	conditions.add_field("max_value", DataSchema.FieldType.INT, false).set_range(0, NpcState.VALUE_MAX)
	schemas.append(conditions)
	var weights: DataSchema = DataSchema.new(TRAIT_WEIGHTS_TABLE, "action_trait_weights.json")
	weights.add_field("action_id", DataSchema.FieldType.STRING).set_ref(ACTIONS_TABLE)
	weights.add_field("trait_id", DataSchema.FieldType.STRING).set_ref(TraitLoader.TRAITS_TABLE)
	weights.add_field("weight", DataSchema.FieldType.INT).set_range(-MAX_ABS_WEIGHT, MAX_ABS_WEIGHT)
	schemas.append(weights)
	return schemas


## Lê os seis arquivos de `base_dir`, valida e monta as ações, na ordem do arquivo de ações.
static func load_dir(base_dir: String = DEFAULT_DIR) -> LoadResult:
	return _finish(DataLoader.load_all(base_dir, build_schemas()))


## Mesmo caminho a partir de tabelas já em memória (id da tabela -> registros), sem tocar em disco: para testar dado inválido e
## ação nova só por dados. `base_dir` só rotula os arquivos nas mensagens.
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
	check_semantics(bundle)
	if not bundle.is_valid():
		return LoadResult.new(Result.failure(CODE_INVALID, bundle.describe_issues()), [])
	return LoadResult.new(Result.success(), _build(bundle))


## Acrescenta ao pacote o que o esquema não vê: traços, necessidades, tipo de local, tipo de condição e pares repetidos. Também usada
## pelo carregador da rotina (LW-061), que lê estas mesmas tabelas para conferir as ações da agenda.
static func check_semantics(bundle: DataBundle) -> void:
	TraitLoader.check_semantics(bundle)
	NeedLoader.check_semantics(bundle)
	_check_places(bundle)
	_check_conditions(bundle)
	_check_unique_pairs(bundle, EFFECTS_TABLE, "need_id", "efeito")
	_check_unique_pairs(bundle, TRAIT_WEIGHTS_TABLE, "trait_id", "peso")


## `place_kind` vazio (qualquer lugar) ou um tipo do vocabulário.
static func _check_places(bundle: DataBundle) -> void:
	if not bundle.tables.has(ACTIONS_TABLE):
		return
	var file_path: String = bundle.file_paths[ACTIONS_TABLE]
	for record: Dictionary in bundle.tables[ACTIONS_TABLE]:
		var place_kind: Variant = record.get("place_kind")
		if typeof(place_kind) == TYPE_STRING and not str(place_kind).is_empty() and not ActionDef.PLACE_KINDS.has(str(place_kind)):
			bundle.add_issue(file_path, str(record.get("id", "")), "place_kind", "tipo de local '%s' inexistente; esperado vazio (qualquer lugar) ou um de: %s" % [place_kind, ", ".join(ActionDef.PLACE_KINDS)])


## Tipo de condição conhecido e, para cada tipo, os campos que ele exige (e `need_id` só nos tipos de necessidade).
static func _check_conditions(bundle: DataBundle) -> void:
	if not bundle.tables.has(CONDITIONS_TABLE):
		return
	var file_path: String = bundle.file_paths[CONDITIONS_TABLE]
	for record: Dictionary in bundle.tables[CONDITIONS_TABLE]:
		var item: String = str(record.get("id", ""))
		if typeof(record.get("kind")) != TYPE_STRING:
			continue
		var kind: String = record["kind"]
		if not ActionDef.CONDITION_KINDS.has(kind):
			bundle.add_issue(file_path, item, "kind", "tipo de condição desconhecido '%s'; esperado um de: %s" % [kind, ", ".join(ActionDef.CONDITION_KINDS)])
			continue
		var is_need_kind: bool = kind == ActionDef.CONDITION_NEED_AT_LEAST or kind == ActionDef.CONDITION_NEED_AT_MOST
		if is_need_kind and not record.has("need_id"):
			bundle.add_issue(file_path, item, "need_id", "obrigatório no tipo '%s'" % kind)
		if not is_need_kind and record.has("need_id"):
			bundle.add_issue(file_path, item, "need_id", "não se aplica ao tipo '%s'; remova o campo" % kind)
		if (kind == ActionDef.CONDITION_NEED_AT_LEAST or kind == ActionDef.CONDITION_HOUR_BETWEEN) and not record.has("min_value"):
			bundle.add_issue(file_path, item, "min_value", "obrigatório no tipo '%s'" % kind)
		if (kind == ActionDef.CONDITION_NEED_AT_MOST or kind == ActionDef.CONDITION_HOUR_BETWEEN) and not record.has("max_value"):
			bundle.add_issue(file_path, item, "max_value", "obrigatório no tipo '%s'" % kind)
		if kind == ActionDef.CONDITION_HOUR_BETWEEN:
			for field: String in ["min_value", "max_value"]:
				if typeof(record.get(field)) == TYPE_INT and int(record[field]) > MAX_HOUR:
					bundle.add_issue(file_path, item, field, "hora %d acima de %d" % [record[field], MAX_HOUR])


## Mesma ação com a mesma necessidade (ou o mesmo traço) em duas linhas: ambíguo, então é erro.
static func _check_unique_pairs(bundle: DataBundle, table: String, key_field: String, label: String) -> void:
	if not bundle.tables.has(table):
		return
	var file_path: String = bundle.file_paths[table]
	var first_owner: Dictionary[String, String] = {}
	for record: Dictionary in bundle.tables[table]:
		if typeof(record.get("action_id")) != TYPE_STRING or typeof(record.get(key_field)) != TYPE_STRING:
			continue
		var item: String = str(record.get("id", ""))
		var pair: String = "%s|%s" % [record["action_id"], record[key_field]]
		if first_owner.has(pair):
			bundle.add_issue(file_path, item, key_field, "%s repetido para a ação '%s' e '%s' (já na linha '%s')" % [label, record["action_id"], record[key_field], first_owner[pair]])
		else:
			first_owner[pair] = item


## Monta as ações de um pacote já validado; efeitos, condições e pesos entram na ordem dos arquivos.
static func _build(bundle: DataBundle) -> Array[ActionDef]:
	var actions: Array[ActionDef] = []
	var by_id: Dictionary[String, ActionDef] = {}
	for record: Dictionary in bundle.tables[ACTIONS_TABLE]:
		var action: ActionDef = ActionDef.new(str(record["id"]), record["duration_min"], str(record["place_kind"]), record["risk"], record["interruptible"])
		actions.append(action)
		by_id[action.id] = action
	for record: Dictionary in bundle.tables[EFFECTS_TABLE]:
		by_id[str(record["action_id"])].effects.append(ActionDef.ActionEffect.new(str(record["need_id"]), record["delta"]))
	for record: Dictionary in bundle.tables[CONDITIONS_TABLE]:
		by_id[str(record["action_id"])].conditions.append(ActionDef.ActionCondition.new(str(record["kind"]), str(record.get("need_id", "")), int(record.get("min_value", ActionDef.ABSENT)), int(record.get("max_value", ActionDef.ABSENT))))
	for record: Dictionary in bundle.tables[TRAIT_WEIGHTS_TABLE]:
		by_id[str(record["action_id"])].trait_weights.append(ActionDef.ActionTraitWeight.new(str(record["trait_id"]), record["weight"]))
	return actions


## Resultado do carregamento: `actions` só vale se `result.ok` (mesmo padrão dos outros carregadores).
class LoadResult:
	extends RefCounted

	var result: Result
	var actions: Array[ActionDef]

	func _init(load_result: Result, loaded_actions: Array[ActionDef]) -> void:
		result = load_result
		actions = loaded_actions
