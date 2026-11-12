class_name ProvinceLoader
extends RefCounted
## Lê e valida data/world/provinces.json e data/world/province_adjacency.json pelo módulo `data` (LW-118b; formato em docs/modules/world.md, "Extensão da Fase 4", e docs/fase-4/dados.md, seção 1).
## Província: `id`, `name_key` (texto não vazio) e `kind` (vocabulário fechado de Province.KINDS). Ligação: `id` (`<a>__<b>`), `province_a_id` e `province_b_id` (referências a províncias que existem).
## Além do esquema: ligação de uma província com ela mesma, par repetido (inclusive o par invertido: o par não tem direção), pontas fora da ordem alfabética, `id` que não bate com as colunas e grafo
## de províncias não conectado. A conferência dos povoados contra as províncias (povoado sem província, `settled` sem povoado e `frontier` com povoado) é da LW-118c. Qualquer problema vira falha com
## arquivo, item e campo; nunca carrega recurso nem executa nada do arquivo. Mesmo padrão do RouteLoader.

const PROVINCES_TABLE: String = "provinces"
const ADJACENCY_TABLE: String = "province_adjacency"
const DEFAULT_PROVINCES_FILE: String = "provinces.json"
const DEFAULT_ADJACENCY_FILE: String = "province_adjacency.json"
const CODE_INVALID: String = "PROVINCE_DATA_INVALID"
const ID_SEPARATOR: String = "__"


## Esquemas das duas tabelas; os nomes dos arquivos podem ser trocados (testes). As pontas da ligação são referências à tabela de províncias.
static func build_schemas(provinces_file: String = DEFAULT_PROVINCES_FILE, adjacency_file: String = DEFAULT_ADJACENCY_FILE) -> Array[DataSchema]:
	var provinces: DataSchema = DataSchema.new(PROVINCES_TABLE, provinces_file)
	provinces.add_field("name_key", DataSchema.FieldType.STRING)
	provinces.add_field("kind", DataSchema.FieldType.STRING)
	var adjacency: DataSchema = DataSchema.new(ADJACENCY_TABLE, adjacency_file)
	adjacency.add_field("province_a_id", DataSchema.FieldType.STRING).set_ref(PROVINCES_TABLE)
	adjacency.add_field("province_b_id", DataSchema.FieldType.STRING).set_ref(PROVINCES_TABLE)
	var schemas: Array[DataSchema] = [provinces, adjacency]
	return schemas


## Lê, valida e monta as províncias e as ligações, na ordem dos arquivos.
static func load_dir(base_dir: String, provinces_file: String = DEFAULT_PROVINCES_FILE, adjacency_file: String = DEFAULT_ADJACENCY_FILE) -> LoadResult:
	var bundle: DataBundle = DataLoader.load_all(base_dir, build_schemas(provinces_file, adjacency_file))
	if bundle.tables.has(PROVINCES_TABLE):
		_check_provinces(bundle)
	if bundle.tables.has(PROVINCES_TABLE) and bundle.tables.has(ADJACENCY_TABLE):
		_check_links(bundle)
	if not bundle.is_valid():
		return LoadResult.new(Result.failure(CODE_INVALID, bundle.describe_issues()), [], [])
	var provinces: Array[Province] = []
	for record: Dictionary in bundle.tables[PROVINCES_TABLE]:
		provinces.append(Province.new(str(record["id"]), str(record["name_key"]), str(record["kind"])))
	var links: Array[ProvinceLink] = []
	for record: Dictionary in bundle.tables[ADJACENCY_TABLE]:
		links.append(ProvinceLink.new(str(record["id"]), str(record["province_a_id"]), str(record["province_b_id"])))
	return LoadResult.new(Result.success(), provinces, links)


## O que o esquema não vê nas províncias: ao menos uma, texto do nome não vazio e `kind` no vocabulário. Registro com problema de tipo é pulado (o erro já foi relatado).
static func _check_provinces(bundle: DataBundle) -> void:
	var file_path: String = bundle.file_paths[PROVINCES_TABLE]
	if bundle.tables[PROVINCES_TABLE].is_empty():
		bundle.add_issue(file_path, "", "id", "nenhuma província no arquivo; esperado ao menos uma")
	for record: Dictionary in bundle.tables[PROVINCES_TABLE]:
		var item: String = str(record.get("id", ""))
		if typeof(record.get("name_key")) == TYPE_STRING and str(record["name_key"]).strip_edges().is_empty():
			bundle.add_issue(file_path, item, "name_key", "chave de texto vazia; esperado o nome de uma chave de data/text")
		if typeof(record.get("kind")) == TYPE_STRING and not Province.KINDS.has(str(record["kind"])):
			bundle.add_issue(file_path, item, "kind", "'%s' fora do vocabulário; esperado um de: %s" % [str(record["kind"]), ", ".join(Province.KINDS)])


## O que o esquema não vê nas ligações. Pontas desconhecidas já foram relatadas pela referência do esquema, e a ligação é pulada aqui.
static func _check_links(bundle: DataBundle) -> void:
	var file_path: String = bundle.file_paths[ADJACENCY_TABLE]
	var known: Array[String] = []
	for record: Dictionary in bundle.tables[PROVINCES_TABLE]:
		if typeof(record.get("id")) == TYPE_STRING:
			known.append(str(record["id"]))
	known.sort()
	var first_of_pair: Dictionary[String, String] = {}
	var edges: Array[Array] = []
	for record: Dictionary in bundle.tables[ADJACENCY_TABLE]:
		var item: String = str(record.get("id", ""))
		if typeof(record.get("province_a_id")) != TYPE_STRING or typeof(record.get("province_b_id")) != TYPE_STRING:
			continue
		var first_id: String = str(record["province_a_id"])
		var second_id: String = str(record["province_b_id"])
		if not known.has(first_id) or not known.has(second_id):
			continue
		if first_id == second_id:
			bundle.add_issue(file_path, item, "province_b_id", "ligação de '%s' com ela mesma; esperado duas províncias diferentes" % first_id)
			continue
		var low_id: String = first_id if first_id < second_id else second_id
		var high_id: String = second_id if first_id < second_id else first_id
		var pair: String = "%s|%s" % [low_id, high_id]
		if first_of_pair.has(pair):
			bundle.add_issue(file_path, item, "province_b_id", "a ligação entre '%s' e '%s' já existe na linha '%s'; esperado uma linha só por par, sem direção (o par invertido também conta como repetido)" % [low_id, high_id, first_of_pair[pair]])
			continue
		first_of_pair[pair] = item
		if first_id != low_id:
			bundle.add_issue(file_path, item, "province_a_id", "'%s' vem depois de '%s' na ordem alfabética; esperado `province_a_id` antes de `province_b_id`" % [first_id, second_id])
		elif item != "%s%s%s" % [low_id, ID_SEPARATOR, high_id]:
			bundle.add_issue(file_path, item, "id", "o id não bate com as colunas; esperado '%s%s%s'" % [low_id, ID_SEPARATOR, high_id])
		edges.append([low_id, high_id])
	_check_connected(bundle, file_path, known, edges)


## Todas as províncias se alcançam pelas ligações (busca em largura a partir da primeira, em ordem de id). Com uma província só, o grafo é conexo.
static func _check_connected(bundle: DataBundle, file_path: String, known: Array[String], edges: Array[Array]) -> void:
	if known.size() < 2:
		return
	var neighbors: Dictionary[String, Array] = {}
	for province_id: String in known:
		neighbors[province_id] = []
	for edge: Array in edges:
		neighbors[edge[0]].append(edge[1])
		neighbors[edge[1]].append(edge[0])
	var reached: Dictionary[String, bool] = {known[0]: true}
	var pending: Array[String] = [known[0]]
	while not pending.is_empty():
		var current: String = pending.pop_back()
		for next_id: String in neighbors[current]:
			if not reached.has(next_id):
				reached[next_id] = true
				pending.append(next_id)
	for province_id: String in known:
		if not reached.has(province_id):
			bundle.add_issue(file_path, province_id, "province_a_id", "grafo não conectado: de '%s' não se chega a '%s' pelas ligações; esperado um caminho entre quaisquer duas províncias" % [known[0], province_id])
			return


## Resultado do carregamento: `provinces` e `links` só valem se `result.ok` (mesmo padrão de RouteLoader.LoadResult).
class LoadResult:
	extends RefCounted

	var result: Result
	var provinces: Array[Province]
	var links: Array[ProvinceLink]

	func _init(load_result: Result, loaded_provinces: Array[Province], loaded_links: Array[ProvinceLink]) -> void:
		result = load_result
		provinces = loaded_provinces
		links = loaded_links
