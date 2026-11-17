extends GutTest
## LW-107f2: data/economy/contract_limits.json, o LIMITE de encomendas aceitas ao mesmo tempo, POR CATEGORIA e em dado (docs/economy/dados.md; docs/modules/economy.md, seção 8, item (c); D1, aprovado por Arthur em 16/11/2026), lido e validado
## pelo `ContractLimitLoader` e exposto por `EconomyModule.peek_contract_limit`. O arquivo REAL (`delivery` = 3, provisório do primeiro recorte) é provado pelo CAMINHO DO JOGO: `EconomySetup.from_dir` da pasta real e o `SimulationHostNode.start_new_game`,
## que monta os módulos como o app. Dado inválido falha apontando arquivo, item e campo, com arquivos escritos numa pasta temporária. A economia NÃO aplica o limite (a ponte o aplica, LW-107f3): o `accept` segue sem teto para qualquer aceitante.

const DATA_DIR: String = EconomySetup.DEFAULT_DIR
const WORLD_DIR: String = "res://data/world"
const SEED: int = 1072
const SETTLEMENT_A: String = "test_settlement_a"
const SETTLEMENT_B: String = "test_settlement_b"
const PLAYER: int = 101
const GOOD: String = "grain"
const REWARD: int = 25
const DEADLINE: int = 1000
## Mais encomendas aceitas por um ator do que o limite do arquivo real (3).
const MANY: int = 7
const FIELDS: Array[String] = ["id", "kind", "max_accepted"]

var _terrain: TerrainData
var _host: SimulationHostNode


func before_all() -> void:
	var loaded: TerrainLoader.LoadResult = TerrainLoader.load_dir(WORLD_DIR)
	assert_true(loaded.result.ok, loaded.result.message)
	_terrain = loaded.terrain


func after_each() -> void:
	if _host != null:
		_host.runner.finish()
		_host.free()
		_host = null


func _row(overrides: Dictionary = {}) -> Dictionary:
	var row: Dictionary = {"id": "delivery_limit", "kind": "delivery", "max_accepted": 3}
	row.merge(overrides, true)
	return row


func _as_rows(limits: Array[ContractLimitDef]) -> Array:
	var summary: Array = []
	for limit: ContractLimitDef in limits:
		summary.append([limit.id, limit.kind, limit.max_accepted])
	return summary


## O jogo montado como o app monta: o `EconomySetup` da pasta real e o `SimulationHostNode`, que registra os módulos (`GameModules`) e começa o jogo.
func _start_game() -> SimulationHostNode:
	var setup: EconomySetup = EconomySetup.from_dir(DATA_DIR)
	assert_true(setup.result.ok, setup.result.message)
	var host: SimulationHostNode = SimulationHostNode.new()
	host.start_new_game(SEED, _terrain, [], null, 0, setup)
	assert_not_null(host.economy, "O jogo montou a economia.")
	return host


## Escreve o `contract_limits.json` na pasta (texto vazio: sem o arquivo).
func _write_limits(dir_path: String, limits_json: String) -> void:
	if limits_json.is_empty():
		return
	var file: FileAccess = FileAccess.open(dir_path.path_join(ContractLimitLoader.LIMITS_FILE), FileAccess.WRITE)
	file.store_string(limits_json)
	file.close()


func _empty(dir_path: String) -> void:
	for file_name: String in DirAccess.get_files_at(dir_path):
		DirAccess.remove_absolute(dir_path.path_join(file_name))


## O carregador numa pasta temporária que só tem o arquivo dos limites (ele não lê outro).
func _load_text(limits_json: String) -> ContractLimitLoader.LoadResult:
	var temp: DirAccess = DirAccess.create_temp("lw107f2_loader")
	assert_not_null(temp, "A pasta temporária foi criada.")
	_write_limits(temp.get_current_dir(), limits_json)
	var loaded: ContractLimitLoader.LoadResult = ContractLimitLoader.load_dir(temp.get_current_dir())
	_empty(temp.get_current_dir())
	return loaded


## Uma cópia de `data/economy` numa pasta temporária com o `contract_limits.json` trocado pelo texto dado (texto vazio: sem o arquivo), montada pelo `EconomySetup`.
func _setup_with(limits_json: String) -> EconomySetup:
	var temp: DirAccess = DirAccess.create_temp("lw107f2_setup")
	assert_not_null(temp, "A pasta temporária foi criada.")
	var dir_path: String = temp.get_current_dir()
	for file_name: String in DirAccess.get_files_at(DATA_DIR):
		if file_name.ends_with(".json") and file_name != ContractLimitLoader.LIMITS_FILE:
			assert_eq(DirAccess.copy_absolute(DATA_DIR.path_join(file_name), dir_path.path_join(file_name)), OK, "Copiou %s." % file_name)
	_write_limits(dir_path, limits_json)
	var setup: EconomySetup = EconomySetup.from_dir(dir_path)
	_empty(dir_path)
	return setup


## `tail` é o que vem depois do arquivo na mensagem: `item '..' | campo '..'`, ou o problema da tabela inteira.
func _expect_failure(label: String, limits_json: String, tail: String) -> void:
	var loaded: ContractLimitLoader.LoadResult = _load_text(limits_json)
	assert_false(loaded.result.ok, "%s: deveria falhar." % label)
	assert_eq(loaded.result.code, EconomyCodes.DATA_INVALID, label)
	assert_eq(loaded.limits.size(), 0, "%s: falha não devolve limite." % label)
	assert_string_contains(loaded.result.message, "%s | %s" % [ContractLimitLoader.LIMITS_FILE, tail], "%s: a mensagem deveria citar o arquivo e '%s'." % [label, tail])


func test_the_real_file_carries_only_the_delivery_limit_of_three_in_file_order() -> void:
	var loaded: ContractLimitLoader.LoadResult = ContractLimitLoader.load_dir(DATA_DIR)
	assert_true(loaded.result.ok, loaded.result.message)
	assert_eq(_as_rows(loaded.limits), [["delivery_limit", "delivery", 3]])


## O CAMINHO REAL: o jogo lê a pasta com o `EconomySetup` e monta o módulo no `SimulationHostNode`; o arquivo REAL chega à porta (3 em `delivery`, 0 nas outras categorias e em qualquer texto que não é categoria).
func test_the_game_assembly_reads_the_real_file_and_the_economy_answers_three_for_delivery_and_zero_for_the_rest() -> void:
	var setup: EconomySetup = EconomySetup.from_dir(DATA_DIR)
	assert_true(setup.result.ok, setup.result.message)
	assert_eq(_as_rows(setup.definitions.contract_limits), [["delivery_limit", "delivery", 3]], "O setup leva a linha do arquivo real às definições.")
	_host = _start_game()
	var answers: Array = []
	for kind: String in [ContractBook.DELIVERY, ContractBook.LABOR, ContractBook.VACANCY, "hunt", ""]:
		answers.append(_host.economy.peek_contract_limit(kind))
	assert_eq(answers, [3, 0, 0, 0, 0])


## A economia só INFORMA o limite: com `delivery` = 3 carregado, o mesmo ator aceita 7 encomendas pela economia (a ponte, e não o `ContractBook.accept`, é quem recusa a 4ª do jogador, LW-107f3).
func test_the_economy_does_not_apply_the_limit_one_actor_still_accepts_more_deliveries_than_the_real_limit() -> void:
	_host = _start_game()
	var economy: EconomyModule = _host.economy
	assert_eq(economy.peek_contract_limit(ContractBook.DELIVERY), 3, "O limite do arquivo real está carregado.")
	assert_true(economy.request_open_owner(PLAYER, "player").ok)
	var market_a: int = economy.peek_market_of(SETTLEMENT_A).market_id
	var market_b: int = economy.peek_market_of(SETTLEMENT_B).market_id
	var states: Array = []
	for _index: int in MANY:
		var objective: Dictionary = {ContractBook.KEY_GOOD: GOOD, ContractBook.KEY_QUANTITY: 1, ContractBook.KEY_DESTINATION: market_b}
		var posted: EconomyReplies.PostContractResult = economy.request_post_contract(ContractBook.DELIVERY, market_a, REWARD, DEADLINE, objective)
		assert_true(posted.result.ok, posted.result.message)
		var accepted: Result = economy.request_accept_contract(posted.contract_id, PLAYER)
		assert_true(accepted.ok, accepted.message)
		states.append(economy.peek_contract(posted.contract_id).state)
	var expected: Array = []
	expected.resize(MANY)
	expected.fill(ContractBook.STATE_ACCEPTED)
	assert_eq(states, expected, "Todas as encomendas ficam `accepted`: a economia não tem teto.")


## Cada categoria responde pela PRÓPRIA linha (a de uma não vale para a outra); sem linha, 0. O módulo sem definições (sem o `EconomySetup`) não tem limite nenhum.
func test_each_category_answers_with_its_own_line_and_a_module_without_definitions_has_no_limit() -> void:
	var loaded: ContractLimitLoader.LoadResult = _load_text(JSON.stringify([_row(), _row({"id": "labor_limit", "kind": "labor", "max_accepted": 20})]))
	assert_true(loaded.result.ok, loaded.result.message)
	var definitions: EconomyDefinitions = EconomyDefinitions.new()
	definitions.contract_limits = loaded.limits
	var economy: EconomyModule = EconomyModule.new(false, definitions)
	assert_eq([economy.peek_contract_limit("delivery"), economy.peek_contract_limit("labor"), economy.peek_contract_limit("vacancy"), economy.peek_contract_limit("hunt")], [3, 20, 0, 0])
	assert_eq(EconomyModule.new().peek_contract_limit("delivery"), EconomyModule.NO_CONTRACT_LIMIT, "Sem definições não há limite definido.")


## Os dois lados da faixa de 1 a 20 (o de fora está em `test_each_rule_and_each_range_fails...`) e as três categorias do vocabulário juntas, uma linha cada.
func test_values_on_the_edge_of_the_range_and_one_line_for_each_category_are_accepted() -> void:
	for edge: int in [1, 3, 20]:
		var loaded: ContractLimitLoader.LoadResult = _load_text(JSON.stringify([_row({"max_accepted": edge})]))
		assert_true(loaded.result.ok, "%d: %s" % [edge, loaded.result.message])
		assert_eq(_as_rows(loaded.limits), [["delivery_limit", "delivery", edge]])
	var all: ContractLimitLoader.LoadResult = _load_text(JSON.stringify([_row(), _row({"id": "labor_limit", "kind": "labor", "max_accepted": 7}), _row({"id": "vacancy_limit", "kind": "vacancy", "max_accepted": 2})]))
	assert_true(all.result.ok, all.result.message)
	assert_eq(_as_rows(all.limits), [["delivery_limit", "delivery", 3], ["labor_limit", "labor", 7], ["vacancy_limit", "vacancy", 2]])


func test_each_rule_and_each_range_fails_pointing_at_file_item_and_field() -> void:
	var cases: Array = [
		["categoria repetida (a segunda linha)", [_row(), _row({"id": "delivery_limit_2"})], "delivery_limit_2", "kind"],
		["id repetido", [_row(), _row({"kind": "labor"})], "delivery_limit", "id"],
		["id fora do snake_case", [_row({"id": "Delivery-Limit"})], "Delivery-Limit", "id"],
		["kind desconhecido", [_row({"kind": "hunt"})], "delivery_limit", "kind"],
		["kind de outra caixa", [_row({"kind": "Delivery"})], "delivery_limit", "kind"],
		["kind vazio", [_row({"kind": ""})], "delivery_limit", "kind"],
		["kind numérico", [_row({"kind": 5})], "delivery_limit", "kind"],
		["kind nulo", [_row({"kind": null})], "delivery_limit", "kind"],
		["limite 0", [_row({"max_accepted": 0})], "delivery_limit", "max_accepted"],
		["limite negativo", [_row({"max_accepted": -1})], "delivery_limit", "max_accepted"],
		["limite 21", [_row({"max_accepted": 21})], "delivery_limit", "max_accepted"],
		["limite fracionário", [_row({"max_accepted": 2.5})], "delivery_limit", "max_accepted"],
		["limite em texto", [_row({"max_accepted": "3"})], "delivery_limit", "max_accepted"],
		["limite nulo", [_row({"max_accepted": null})], "delivery_limit", "max_accepted"],
		["limite booleano", [_row({"max_accepted": true})], "delivery_limit", "max_accepted"],
		["campo desconhecido", [_row({"note": "x"})], "delivery_limit", "note"],
	]
	for case: Array in cases:
		_expect_failure(case[0], JSON.stringify(case[1]), "item '%s' | campo '%s'" % [case[2], case[3]])
	for field: String in FIELDS:
		var missing: Dictionary = _row()
		missing.erase(field)
		_expect_failure("campo ausente: %s" % field, JSON.stringify([missing]), "item '%s' | campo '%s'" % ["#0" if field == "id" else "delivery_limit", field])


## A linha que não é objeto aponta o item `#posição`; o arquivo ilegível ou sem lista na raiz aponta só o arquivo (o `data` não tem item nem campo nesses casos).
func test_a_row_that_is_not_an_object_malformed_json_and_a_root_that_is_not_a_list_fail() -> void:
	_expect_failure("linha que não é objeto", JSON.stringify([_row(), 5]), "item '#1' | cada registro deve ser um objeto")
	_expect_failure("JSON malformado", "{", "JSON inválido")
	_expect_failure("raiz que não é lista", "{}", "a raiz do arquivo deve ser uma lista de registros")


## Arquivo ausente e tabela vazia: nenhuma falha e nenhum limite (a economia responde 0), pelo carregador e pela montagem do `EconomySetup`.
func test_without_the_file_or_with_an_empty_table_there_is_no_limit_and_no_failure() -> void:
	for text: String in ["", "[]"]:
		var loaded: ContractLimitLoader.LoadResult = _load_text(text)
		assert_true(loaded.result.ok, loaded.result.message)
		assert_eq(loaded.limits.size(), 0, "Sem linha, nenhum limite (texto '%s')." % text)
		var setup: EconomySetup = _setup_with(text)
		assert_true(setup.result.ok, setup.result.message)
		assert_eq(EconomyModule.new(false, setup.definitions).peek_contract_limit("delivery"), 0, "Sem o arquivo ou com a tabela vazia o jogo não tem limite (texto '%s')." % text)


## O `EconomySetup` recusa o arquivo inválido inteiro, com a mensagem do carregador; o arquivo presente e ilegível não vira "sem limite".
func test_the_setup_refuses_an_invalid_file_and_an_unreadable_one_and_names_the_file() -> void:
	var bad: EconomySetup = _setup_with(JSON.stringify([_row({"max_accepted": 0})]))
	assert_false(bad.result.ok, "Arquivo inválido: o setup inteiro falha.")
	assert_eq(bad.result.code, EconomySetup.CODE_INVALID)
	assert_string_contains(bad.result.message, "%s | item 'delivery_limit' | campo 'max_accepted'" % ContractLimitLoader.LIMITS_FILE)
	for broken: String in ["{", "{}"]:
		var corrupt: EconomySetup = _setup_with(broken)
		assert_false(corrupt.result.ok, "Arquivo presente e ilegível não vira 'sem limite' (texto '%s')." % broken)
		assert_string_contains(corrupt.result.message, ContractLimitLoader.LIMITS_FILE)


func test_loading_twice_gives_the_same_limits() -> void:
	var first: ContractLimitLoader.LoadResult = ContractLimitLoader.load_dir(DATA_DIR)
	var second: ContractLimitLoader.LoadResult = ContractLimitLoader.load_dir(DATA_DIR)
	assert_eq(_as_rows(first.limits).size(), 1)
	assert_eq(_as_rows(first.limits), _as_rows(second.limits))
	assert_eq(_as_rows(EconomySetup.from_dir(DATA_DIR).definitions.contract_limits), _as_rows(first.limits))
