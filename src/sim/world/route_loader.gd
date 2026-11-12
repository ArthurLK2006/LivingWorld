class_name RouteLoader
extends RefCounted
## Lê e valida data/world/routes.json pelo módulo `data` (LW-097b; formato em docs/modules/world.md, seção "Extensão da Fase 3"). Rota:
## `id`, `settlement_a_id` e `settlement_b_id` (assentamentos que existem), `length_m` (1 a 100.000), `difficulty` e `risk` (0 a 100). Além do
## esquema: rota de um assentamento para ele mesmo, par repetido (a mesma ligação nos dois sentidos), comprimento menor que a distância em
## linha reta entre os centros, assentamento sem nenhuma rota e grafo não conectado (a economia precisa de um caminho entre qualquer par).
## Qualquer problema vira falha com arquivo, item e campo. Nunca carrega recurso nem executa nada do arquivo. Mesmo padrão do SettlementLoader.

const ROUTES_TABLE: String = "routes"
const DEFAULT_ROUTES_FILE: String = "routes.json"
const CODE_INVALID: String = "ROUTE_DATA_INVALID"


## Esquema da tabela; o nome do arquivo pode ser trocado (testes). Os assentamentos são de outro módulo e ficam como texto livre, conferidos adiante.
static func build_schema(routes_file: String = DEFAULT_ROUTES_FILE) -> DataSchema:
	var routes: DataSchema = DataSchema.new(ROUTES_TABLE, routes_file)
	routes.add_field("settlement_a_id", DataSchema.FieldType.STRING)
	routes.add_field("settlement_b_id", DataSchema.FieldType.STRING)
	routes.add_field("length_m", DataSchema.FieldType.INT).set_range(Route.MIN_LENGTH_M, Route.MAX_LENGTH_M)
	routes.add_field("difficulty", DataSchema.FieldType.INT).set_range(0, Route.MAX_RATING)
	routes.add_field("risk", DataSchema.FieldType.INT).set_range(0, Route.MAX_RATING)
	return routes


## Lê, valida e monta as rotas, na ordem do arquivo. Os assentamentos dão as pontas válidas e a distância em linha reta.
static func load_dir(base_dir: String, settlements: Array[Settlement], routes_file: String = DEFAULT_ROUTES_FILE) -> LoadResult:
	var schemas: Array[DataSchema] = [build_schema(routes_file)]
	var bundle: DataBundle = DataLoader.load_all(base_dir, schemas)
	if bundle.tables.has(ROUTES_TABLE):
		_check_semantics(bundle, settlements)
	if not bundle.is_valid():
		return LoadResult.new(Result.failure(CODE_INVALID, bundle.describe_issues()), [])
	var routes: Array[Route] = []
	for record: Dictionary in bundle.tables[ROUTES_TABLE]:
		routes.append(Route.new(str(record["id"]), str(record["settlement_a_id"]), str(record["settlement_b_id"]), int(record["length_m"]), int(record["difficulty"]), int(record["risk"])))
	return LoadResult.new(Result.success(), routes)


## O que o esquema não vê. Registro com problema de tipo é pulado (o erro já foi relatado).
static func _check_semantics(bundle: DataBundle, settlements: Array[Settlement]) -> void:
	var file_path: String = bundle.file_paths[ROUTES_TABLE]
	var by_id: Dictionary[String, Settlement] = {}
	for settlement: Settlement in settlements:
		by_id[settlement.id] = settlement
	var known: Array[String] = []
	known.assign(by_id.keys())
	known.sort()
	var first_of_pair: Dictionary[String, String] = {}
	var edges: Array[Array] = []
	for record: Dictionary in bundle.tables[ROUTES_TABLE]:
		var item: String = str(record.get("id", ""))
		if typeof(record.get("settlement_a_id")) != TYPE_STRING or typeof(record.get("settlement_b_id")) != TYPE_STRING or typeof(record.get("length_m")) != TYPE_INT:
			continue
		var from_id: String = str(record["settlement_a_id"])
		var to_id: String = str(record["settlement_b_id"])
		var ends_known: bool = true
		for field: String in ["settlement_a_id", "settlement_b_id"]:
			if not by_id.has(str(record[field])):
				ends_known = false
				bundle.add_issue(file_path, item, field, "o assentamento '%s' não existe; esperado um de: %s" % [str(record[field]), ", ".join(known)])
		if not ends_known:
			continue
		if from_id == to_id:
			bundle.add_issue(file_path, item, "settlement_b_id", "rota de '%s' para ele mesmo; esperado dois assentamentos diferentes" % from_id)
			continue
		var pair: String = "%s|%s" % ([from_id, to_id] if from_id < to_id else [to_id, from_id])
		if first_of_pair.has(pair):
			bundle.add_issue(file_path, item, "settlement_b_id", "a ligação entre '%s' e '%s' já existe na rota '%s'; esperado uma rota só por par, sem direção" % [from_id, to_id, first_of_pair[pair]])
			continue
		first_of_pair[pair] = item
		var straight_m: float = Vector2(by_id[from_id].position.x, by_id[from_id].position.z).distance_to(Vector2(by_id[to_id].position.x, by_id[to_id].position.z))
		if float(int(record["length_m"])) < straight_m:
			bundle.add_issue(file_path, item, "length_m", "%d m é menor que a distância em linha reta entre '%s' e '%s' (%s m); esperado ao menos a linha reta" % [int(record["length_m"]), from_id, to_id, str(snappedf(straight_m, 0.01))])
		edges.append([from_id, to_id])
	if settlements.size() >= 2:
		_check_connected(bundle, file_path, known, edges)


## Todo assentamento tem ao menos uma rota e todos se alcançam pelas rotas (busca em largura a partir do primeiro, em ordem de id).
static func _check_connected(bundle: DataBundle, file_path: String, known: Array[String], edges: Array[Array]) -> void:
	var neighbors: Dictionary[String, Array] = {}
	for settlement_id: String in known:
		neighbors[settlement_id] = []
	for edge: Array in edges:
		var from_id: String = edge[0]
		var to_id: String = edge[1]
		neighbors[from_id].append(to_id)
		neighbors[to_id].append(from_id)
	for settlement_id: String in known:
		if neighbors[settlement_id].is_empty():
			bundle.add_issue(file_path, settlement_id, "settlement_a_id", "assentamento sem nenhuma rota em %s; esperado ao menos 1 rota que o ligue aos outros" % file_path.get_file())
	var reached: Dictionary[String, bool] = {known[0]: true}
	var pending: Array[String] = [known[0]]
	while not pending.is_empty():
		var current: String = pending.pop_back()
		for next_id: String in neighbors[current]:
			if not reached.has(next_id):
				reached[next_id] = true
				pending.append(next_id)
	for settlement_id: String in known:
		if not reached.has(settlement_id) and not neighbors[settlement_id].is_empty():
			bundle.add_issue(file_path, settlement_id, "settlement_a_id", "grafo não conectado: de '%s' não se chega a '%s' pelas rotas; esperado um caminho entre qualquer par" % [known[0], settlement_id])
			return


## Resultado do carregamento: `routes` só vale se `result.ok` (mesmo padrão de SettlementLoader.LoadResult).
class LoadResult:
	extends RefCounted

	var result: Result
	var routes: Array[Route]

	func _init(load_result: Result, loaded_routes: Array[Route]) -> void:
		result = load_result
		routes = loaded_routes
