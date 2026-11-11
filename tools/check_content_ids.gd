extends SceneTree
## LW-093a (DEC-137): o verificador de ids de conteúdo. (1) Cada id de conteúdo escrito como CONSTANTE no código (`FLEE_ACTION_ID = "flee"`, `HELP_MEMORY_KIND`, `KIND_SITE`...) existe na tabela de `data/` que é dona dele; um id
## trocado ou removido em `data/` deixa de quebrar o código sem aviso. (2) Cada coluna que as tabelas da economia (e o `population.json`) usam para citar o id de OUTRO módulo existe na tabela do dono (`need_id`, `occupation_id`,
## `settlement_id`, `place_id`, `work_place_id`; a economia não importa o `npc` nem o `world`, então o esquema dela deixa essas colunas como texto livre, D1); e cada local de produção ocupa um local `work` do próprio povoado, sem
## repetir, com `workers_wanted` até a capacidade do local. Nenhum comportamento de jogo muda: só lê. Uso: tools/check_content_ids [raiz-do-projeto]. Código 0 (tudo existe) ou 1 (problemas, cada um com o arquivo e o id).

const ID_FIELD: String = "id"
const CONSTANT_LINE: String = "^const ([A-Z][A-Z0-9_]*): String = \"([^\"]*)\""
## Nome da constante (expressão regular) -> tabela dona dos ids. `scope`: só conta nos arquivos desta pasta (vazio = todos). Nomes com `KEY_` (chave de save) e `CODE_` (código de erro) não são ids de conteúdo.
const CONSTANT_RULES: Array[Dictionary] = [
	{"name": "^(?!KEY_|CODE_)([A-Z0-9_]+_ACTION_ID|GO_TO_PLACE_ID)$", "table": "actions.json", "scope": ""},
	{"name": "^(?!KEY_|CODE_)[A-Z0-9_]*NEED_ID$", "table": "needs.json", "scope": ""},
	{"name": "^(?!KEY_|CODE_)[A-Z0-9_]+_MEMORY_KIND$", "table": "memory_kinds.json", "scope": ""},
	{"name": "^KIND_", "table": "economy/owner_kinds.json", "scope": "src/sim/economy/"},
]
## Colunas que citam o id de outro módulo: `file` (em `data/`), `column`, tabela dona. Coluna ausente na linha é pulada (`need_id` só existe nos bens de comida; `work_place_id` entra com a LW-097).
const REFERENCES: Array[Dictionary] = [
	{"file": "economy/goods.json", "column": "need_id", "owner": "needs.json"},
	{"file": "economy/recipes.json", "column": "occupation_id", "owner": "occupations.json"},
	{"file": "economy/market_targets.json", "column": "settlement_id", "owner": "world/settlements.json"},
	{"file": "economy/production_sites.json", "column": "settlement_id", "owner": "world/settlements.json"},
	{"file": "economy/production_sites.json", "column": "place_id", "owner": "world/places.json"},
	{"file": "population.json", "column": "work_place_id", "owner": "world/places.json"},
]
const SITES_FILE: String = "economy/production_sites.json"
const PLACES_FILE: String = "world/places.json"
const WORK_PLACE_KIND: String = "work"

var _root: String = ""
var _problems: Array[String] = []
var _checks: int = 0
var _tables: Dictionary[String, Array] = {}


func _initialize() -> void:
	var arguments: PackedStringArray = OS.get_cmdline_user_args()
	_root = (arguments[0] if not arguments.is_empty() else ProjectSettings.globalize_path("res://")).rstrip("/")
	_check_constants()
	_check_references()
	_check_sites()
	if _problems.is_empty():
		print("IDS DE CONTEÚDO: tudo existe (%d conferências) em %s" % [_checks, _root])
		quit(0)
		return
	print("IDS DE CONTEÚDO: %d problema(s) em %s\n%s" % [_problems.size(), _root, "\n".join(_problems)])
	quit(1)


func _check_constants() -> void:
	var line_pattern: RegEx = RegEx.create_from_string(CONSTANT_LINE)
	var name_patterns: Array[RegEx] = []
	for rule: Dictionary in CONSTANT_RULES:
		name_patterns.append(RegEx.create_from_string(str(rule["name"])))
	for path: String in _script_files(_root + "/src"):
		var relative: String = path.trim_prefix(_root + "/")
		var lines: PackedStringArray = FileAccess.get_file_as_string(path).split("\n")
		for index: int in lines.size():
			var found: RegExMatch = line_pattern.search(lines[index])
			if found == null:
				continue
			for rule_index: int in CONSTANT_RULES.size():
				var rule: Dictionary = CONSTANT_RULES[rule_index]
				if name_patterns[rule_index].search(found.get_string(1)) == null or not relative.begins_with(str(rule["scope"])):
					continue
				_checks += 1
				if not _ids_of(str(rule["table"])).has(found.get_string(2)):
					_problems.append("%s:%d: a constante %s = \"%s\" não existe em data/%s" % [relative, index + 1, found.get_string(1), found.get_string(2), rule["table"]])


func _check_references() -> void:
	for reference: Dictionary in REFERENCES:
		for row: Dictionary in _rows(str(reference["file"])):
			if not row.has(reference["column"]):
				continue
			_checks += 1
			var cited: String = str(row[reference["column"]])
			if not _ids_of(str(reference["owner"])).has(cited):
				_problems.append("data/%s: item '%s', campo '%s': o id '%s' não existe em data/%s" % [reference["file"], row.get(ID_FIELD, "?"), reference["column"], cited, reference["owner"]])


## Cada local de produção ocupa um local `work` do próprio povoado, que nenhum outro local de produção ocupa, e a equipe desejada cabe no local. Id que não existe já foi apontado por `_check_references`.
func _check_sites() -> void:
	var places: Dictionary[String, Dictionary] = {}
	for place: Dictionary in _rows(PLACES_FILE):
		places[str(place.get(ID_FIELD, ""))] = place
	var occupied: Dictionary[String, String] = {}
	for site: Dictionary in _rows(SITES_FILE):
		var site_id: String = str(site.get(ID_FIELD, "?"))
		var place_id: String = str(site.get("place_id", ""))
		if not places.has(place_id):
			continue
		_checks += 1
		var place: Dictionary = places[place_id]
		if str(place.get("kind", "")) != WORK_PLACE_KIND:
			_problems.append("data/%s: item '%s', campo 'place_id': o local '%s' é do tipo '%s'; esperado '%s'" % [SITES_FILE, site_id, place_id, place.get("kind", ""), WORK_PLACE_KIND])
		if str(place.get("settlement_id", "")) != str(site.get("settlement_id", "")):
			_problems.append("data/%s: item '%s', campo 'place_id': o local '%s' é do povoado '%s', não de '%s'" % [SITES_FILE, site_id, place_id, place.get("settlement_id", ""), site.get("settlement_id", "")])
		if occupied.has(place_id):
			_problems.append("data/%s: item '%s', campo 'place_id': o local '%s' já é de '%s'; um local de produção por local" % [SITES_FILE, site_id, place_id, occupied[place_id]])
		occupied[place_id] = site_id
		if int(site.get("workers_wanted", 0)) > int(place.get("capacity", 0)):
			_problems.append("data/%s: item '%s', campo 'workers_wanted': %d passa da capacidade (%d) do local '%s'" % [SITES_FILE, site_id, int(site.get("workers_wanted", 0)), int(place.get("capacity", 0)), place_id])


## Os ids da tabela (arquivo em `data/`), em um conjunto.
func _ids_of(table: String) -> Dictionary[String, bool]:
	var ids: Dictionary[String, bool] = {}
	for row: Dictionary in _rows(table):
		ids[str(row.get(ID_FIELD, ""))] = true
	return ids


## As linhas da tabela (um arquivo JSON com uma lista de objetos), lidas uma vez. Arquivo ausente ou ilegível vira UM problema.
func _rows(table: String) -> Array:
	if _tables.has(table):
		return _tables[table]
	var rows: Array[Dictionary] = []
	var path: String = "%s/data/%s" % [_root, table]
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path)) if FileAccess.file_exists(path) else null
	if typeof(parsed) != TYPE_ARRAY:
		_problems.append("data/%s: arquivo ausente ou não é uma lista de objetos" % table)
	else:
		for item: Variant in parsed:
			if typeof(item) == TYPE_DICTIONARY:
				rows.append(item)
	_tables[table] = rows
	return rows


func _script_files(directory: String) -> Array[String]:
	var files: Array[String] = []
	for name: String in DirAccess.get_files_at(directory):
		if name.ends_with(".gd"):
			files.append("%s/%s" % [directory, name])
	for name: String in DirAccess.get_directories_at(directory):
		files.append_array(_script_files("%s/%s" % [directory, name]))
	return files
