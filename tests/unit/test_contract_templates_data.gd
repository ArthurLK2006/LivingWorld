extends GutTest
## LW-107c1: data/economy/contract_templates.json, os modelos do postador de contratos de entrega (docs/economy/dados.md; docs/modules/economy.md, seção 8), lidos e validados pelo `ContractTemplateLoader` (a proteção (a) do contrato: as faixas). O arquivo real
## é `[]` (o padrão do jogo não tem modelo, LW-107c2) e o exemplo `contract_templates.initial.json` tem os 3 modelos de partida; dado inválido falha apontando arquivo, item e campo, com tabelas montadas em memória (3 bens de teste, para os limites do lote não dependerem dos números [HIP] do `goods.json`). Só dado e carregador: nenhum código lê os modelos ainda.

const DATA_DIR: String = "res://data/economy"
const EXAMPLE_FILE: String = "contract_templates.initial.json"
const FIELDS: Array[String] = ["kind", "good_id", "quantity", "trigger", "reward_margin_bp", "deadline_hours", "max_open"]
const TEXT_FIELDS: Array[String] = ["kind", "good_id", "trigger"]
const INT_FIELDS: Array[String] = ["quantity", "reward_margin_bp", "deadline_hours", "max_open"]


func _good(good_id: String, value: int, weight: int) -> Dictionary:
	return {"id": good_id, "name_key": "good.%s.name" % good_id, "category": "food", "base_value": value, "weight": weight, "perishability_days": 0}


## O pão pesa 1 e a farinha pesa 2; o jogador carrega 60: os dois lados do limite do lote ficam em 60 e 61 pães e em 30 e 31 de farinha.
func _tables(rows: Array) -> Dictionary[String, Array]:
	var tables: Dictionary[String, Array] = {}
	tables[GoodsLoader.GOODS_TABLE] = [_good("bread", 10, 1), _good("flour", 6, 2), _good("grain", 4, 2)]
	tables[GoodsLoader.OWNER_KINDS_TABLE] = [{"id": "player", "weight_capacity": 60, "initial_balance": 100}]
	tables[ContractTemplateLoader.TEMPLATES_TABLE] = rows
	return tables


func _row(overrides: Dictionary = {}) -> Dictionary:
	var row: Dictionary = {"id": "bread_standing", "kind": "delivery", "good_id": "bread", "quantity": 5, "trigger": "standing", "reward_margin_bp": 500, "deadline_hours": 48, "max_open": 1}
	row.merge(overrides, true)
	return row


func _load(rows: Array) -> ContractTemplateLoader.LoadResult:
	return ContractTemplateLoader.from_tables(_tables(rows), DATA_DIR)


func _as_rows(templates: Array[ContractTemplateDef]) -> Array:
	var summary: Array = []
	for template: ContractTemplateDef in templates:
		summary.append([template.id, template.kind, template.good_id, template.quantity, template.trigger, template.reward_margin_bp, template.deadline_hours, template.max_open])
	return summary


## Os modelos do arquivo de exemplo (`contract_templates.initial.json`, que o jogo NÃO lê), carregados como se ele fosse o `contract_templates.json` da pasta, com os bens e os tipos de dono reais.
func _example_templates() -> Array[ContractTemplateDef]:
	var setup: EconomySetup = _setup_with(FileAccess.get_file_as_string(DATA_DIR.path_join(EXAMPLE_FILE)))
	assert_true(setup.result.ok, setup.result.message)
	return setup.definitions.contract_templates


## O item citado é o da última linha (a que tem o problema), salvo quando o teste o dá.
func _expect_failure(label: String, rows: Array, field: String, item: String = "") -> void:
	var loaded: ContractTemplateLoader.LoadResult = _load(rows)
	var expected_item: String = item if not item.is_empty() else str(rows[rows.size() - 1]["id"])
	assert_false(loaded.result.ok, "%s: deveria falhar." % label)
	assert_eq(loaded.result.code, EconomyCodes.DATA_INVALID, label)
	assert_eq(loaded.templates.size(), 0, "%s: falha não devolve modelo." % label)
	assert_string_contains(loaded.result.message, "%s | item '%s' | campo '%s'" % [ContractTemplateLoader.TEMPLATES_FILE, expected_item, field], "%s: a mensagem deveria citar arquivo, item e campo." % label)


## Uma cópia de `data/economy` numa pasta temporária com o `contract_templates.json` trocado pelo texto dado (texto vazio: sem o arquivo), montada pelo `EconomySetup`.
func _setup_with(templates_json: String) -> EconomySetup:
	var temp: DirAccess = DirAccess.create_temp("lw107c1_setup")
	assert_not_null(temp, "A pasta temporária foi criada.")
	var dir_path: String = temp.get_current_dir()
	for file_name: String in DirAccess.get_files_at(DATA_DIR):
		if file_name.ends_with(".json") and file_name != ContractTemplateLoader.TEMPLATES_FILE:
			assert_eq(DirAccess.copy_absolute(DATA_DIR.path_join(file_name), dir_path.path_join(file_name)), OK, "Copiou %s." % file_name)
	if not templates_json.is_empty():
		var file: FileAccess = FileAccess.open(dir_path.path_join(ContractTemplateLoader.TEMPLATES_FILE), FileAccess.WRITE)
		file.store_string(templates_json)
		file.close()
	var setup: EconomySetup = EconomySetup.from_dir(dir_path)
	for file_name: String in DirAccess.get_files_at(dir_path):
		DirAccess.remove_absolute(dir_path.path_join(file_name))
	return setup


## O padrão do jogo é SEM modelo (`[]`, LW-107c2): o postador não posta nada até Arthur decidir ativá-lo (cada modelo postado muda valores de referência, DEC-175). Os 3 modelos iniciais ficam no arquivo de exemplo, que este teste carrega como se fosse o ativo.
func test_the_default_file_has_no_template_and_the_example_file_has_the_three_initial_templates_in_file_order() -> void:
	var loaded: ContractTemplateLoader.LoadResult = ContractTemplateLoader.load_dir(DATA_DIR)
	assert_true(loaded.result.ok, loaded.result.message)
	assert_eq(loaded.templates.size(), 0, "O arquivo ativo do jogo não traz modelo.")
	assert_eq(_as_rows(_example_templates()), [
		["bread_standing", "delivery", "bread", 5, "standing", 500, 48, 1],
		["flour_shortage", "delivery", "flour", 10, "shortage", 2500, 48, 1],
		["grain_shortage", "delivery", "grain", 10, "shortage", 2500, 48, 1],
	])


## A fórmula do contrato com os bens REAIS: 53, 75 e 50 são os números da tabela de dados iniciais do `dados.md`; 63 é o exemplo de 25% (5 pães).
func test_the_reward_formula_with_the_real_goods_gives_the_numbers_of_the_data_table() -> void:
	var goods: GoodsLoader.LoadResult = GoodsLoader.load_dir(DATA_DIR)
	assert_true(goods.result.ok, goods.result.message)
	var base_values: Dictionary[String, int] = {}
	for good: GoodDef in goods.goods:
		base_values[good.id] = good.base_value
	var rewards: Array = []
	for template: ContractTemplateDef in _example_templates():
		rewards.append(PriceMath.ceil_div(template.quantity * base_values[template.good_id] * (PriceMath.BASIS + template.reward_margin_bp), PriceMath.BASIS))
	assert_eq(rewards, [53, 75, 50])
	assert_eq(PriceMath.ceil_div(5 * base_values["bread"] * (PriceMath.BASIS + 2500), PriceMath.BASIS), 63)


func test_every_field_comes_from_its_own_column() -> void:
	var loaded: ContractTemplateLoader.LoadResult = _load([_row({"id": "flour_shortage", "good_id": "flour", "quantity": 7, "trigger": "shortage", "reward_margin_bp": 1234, "deadline_hours": 17, "max_open": 2})])
	assert_true(loaded.result.ok, loaded.result.message)
	assert_eq(_as_rows(loaded.templates), [["flour_shortage", "delivery", "flour", 7, "shortage", 1234, 17, 2]])


## Os dois lados de cada limite: o valor de dentro passa (o de fora está em `test_each_rule_and_each_range_fails...`). O bônus do `shortage` vai além de 1000 (o teto do `standing`).
func test_values_on_the_edge_of_each_range_are_accepted() -> void:
	var edges: Array = [
		{"trigger": "shortage", "reward_margin_bp": 0}, {"trigger": "shortage", "reward_margin_bp": 1001}, {"trigger": "shortage", "reward_margin_bp": 5000},
		{"reward_margin_bp": 0}, {"reward_margin_bp": 1000}, {"quantity": 1}, {"quantity": 60}, {"good_id": "flour", "quantity": 30},
		{"deadline_hours": 1}, {"deadline_hours": 168}, {"max_open": 1}, {"max_open": 3},
	]
	for edge: Dictionary in edges:
		var loaded: ContractTemplateLoader.LoadResult = _load([_row(edge)])
		assert_true(loaded.result.ok, "%s: %s" % [edge, loaded.result.message])


func test_each_rule_and_each_range_fails_pointing_at_file_item_and_field() -> void:
	var cases: Array = [
		["id repetido", [_row(), _row({"good_id": "flour"})], "id"],
		["kind diferente de delivery", [_row({"kind": "labor"})], "kind"],
		["bem desconhecido", [_row({"good_id": "nope"})], "good_id"],
		["bem repetido", [_row(), _row({"id": "bread_shortage", "trigger": "shortage"})], "good_id"],
		["gatilho fora do vocabulário", [_row({"trigger": "always"})], "trigger"],
		["bônus negativo", [_row({"reward_margin_bp": -1})], "reward_margin_bp"],
		["bônus do shortage acima de 5000", [_row({"trigger": "shortage", "reward_margin_bp": 5001})], "reward_margin_bp"],
		["bônus do standing acima de 1000 (a faixa é a do gatilho)", [_row({"reward_margin_bp": 1001})], "reward_margin_bp"],
		["quantidade 0", [_row({"quantity": 0})], "quantity"],
		["lote de 61 pães mais pesado que o jogador", [_row({"quantity": 61})], "quantity"],
		["lote de 31 de farinha mais pesado que o jogador", [_row({"good_id": "flour", "quantity": 31})], "quantity"],
		["quantidade acima do teto técnico (a conta do lote estouraria o inteiro)", [_row({"good_id": "flour", "quantity": 4611686018427387905})], "quantity"],
		["prazo 0", [_row({"deadline_hours": 0})], "deadline_hours"],
		["prazo 169", [_row({"deadline_hours": 169})], "deadline_hours"],
		["máximo de abertos 0", [_row({"max_open": 0})], "max_open"],
		["máximo de abertos 4", [_row({"max_open": 4})], "max_open"],
	]
	for case: Array in cases:
		_expect_failure(case[0], case[1], case[2])


func test_missing_wrong_typed_float_and_unknown_fields_fail() -> void:
	for field: String in FIELDS:
		var missing: Dictionary = _row()
		missing.erase(field)
		_expect_failure("campo ausente: %s" % field, [missing], field)
	var without_id: Dictionary = _row()
	without_id.erase("id")
	_expect_failure("id ausente", [without_id], "id", "#0")
	for field: String in TEXT_FIELDS:
		_expect_failure("número onde se espera texto: %s" % field, [_row({field: 5})], field)
	for field: String in INT_FIELDS:
		_expect_failure("texto onde se espera inteiro: %s" % field, [_row({field: "5"})], field)
		_expect_failure("FLOAT em %s" % field, [_row({field: 1.5})], field)
	_expect_failure("campo desconhecido", [_row({"note": "x"})], "note")


## Sem o tipo `player` em `owner_kinds.json` não há como conferir o lote: o arquivo falha em vez de ser aceito sem conferência.
func test_without_the_player_kind_the_lot_cannot_be_checked_and_the_file_fails() -> void:
	var tables: Dictionary[String, Array] = _tables([_row()])
	tables[GoodsLoader.OWNER_KINDS_TABLE] = [{"id": "npc", "weight_capacity": 40, "initial_balance": 60}]
	var loaded: ContractTemplateLoader.LoadResult = ContractTemplateLoader.from_tables(tables, DATA_DIR)
	assert_false(loaded.result.ok)
	assert_string_contains(loaded.result.message, "%s | item 'bread_standing' | campo 'quantity'" % ContractTemplateLoader.TEMPLATES_FILE)


func test_without_the_file_or_with_an_empty_table_the_list_is_empty_without_error() -> void:
	var temp: DirAccess = DirAccess.create_temp("lw107c1_without_templates")
	assert_not_null(temp, "A pasta temporária foi criada.")
	var absent: ContractTemplateLoader.LoadResult = ContractTemplateLoader.load_dir(temp.get_current_dir())
	assert_true(absent.result.ok, absent.result.message)
	assert_eq(absent.templates.size(), 0)
	var empty: ContractTemplateLoader.LoadResult = _load([])
	assert_true(empty.result.ok, empty.result.message)
	assert_eq(empty.templates.size(), 0)


func test_loading_twice_gives_the_same_templates() -> void:
	var first: Array[ContractTemplateDef] = _example_templates()
	var second: Array[ContractTemplateDef] = _example_templates()
	assert_eq(first.size(), 3)
	assert_eq(_as_rows(first), _as_rows(second))


## A ligação: o `EconomySetup` leva os modelos às definições, aceita a pasta sem o arquivo e a tabela vazia (nenhum modelo) e recusa o arquivo inválido com a mensagem do carregador.
func test_the_setup_carries_the_templates_to_the_definitions_and_refuses_an_invalid_file() -> void:
	var real: EconomySetup = EconomySetup.from_dir(DATA_DIR)
	assert_true(real.result.ok, real.result.message)
	assert_eq(_as_rows(real.definitions.contract_templates), _as_rows(ContractTemplateLoader.load_dir(DATA_DIR).templates))
	assert_eq(real.definitions.contract_templates.size(), 0, "O jogo padrão não tem modelo (LW-107c2).")
	assert_eq(_example_templates().size(), 3, "O setup leva os modelos de um arquivo ativo às definições.")
	for text: String in ["", "[]"]:
		var none: EconomySetup = _setup_with(text)
		assert_true(none.result.ok, none.result.message)
		assert_eq(none.definitions.contract_templates.size(), 0, "Sem o arquivo ou com a tabela vazia não há modelo (texto '%s')." % text)
	var bad: EconomySetup = _setup_with(JSON.stringify([_row({"quantity": 0})]))
	assert_false(bad.result.ok, "Arquivo inválido: o setup inteiro falha.")
	assert_eq(bad.result.code, EconomySetup.CODE_INVALID)
	assert_string_contains(bad.result.message, "%s | item 'bread_standing' | campo 'quantity'" % ContractTemplateLoader.TEMPLATES_FILE)
	for broken: String in ["{", "{}"]:
		var corrupt: EconomySetup = _setup_with(broken)
		assert_false(corrupt.result.ok, "Arquivo presente e ilegível não vira 'sem modelos' (texto '%s')." % broken)
		assert_string_contains(corrupt.result.message, ContractTemplateLoader.TEMPLATES_FILE)
