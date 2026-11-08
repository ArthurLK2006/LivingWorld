class_name FoodStub
extends ActionConditionProvider
## TEMP-LW-065: estoque de comida PROVISÓRIO por assentamento (docs/modules/npc.md, seção 9). SAI NA LW-094, quando a comida passar a vir do
## mercado ou do inventário do próprio NPC; até lá os NPCs precisam comer antes de existir economia. Estoque inteiro, NUNCA negativo (consumo
## que não cabe falha) e com teto. Responde `has_food` ao ActionRunner (condição da ação `eat`) e, pelo gancho `on_action_completed` (o runner
## o chama depois que uma ação COMPLETA aplicou os efeitos), consome a refeição (`eat`) ou repõe a colheita (`work` do ofício que produz
## comida). A regra é dado (data/food_stub.json, uma linha por assentamento); aqui só estão os nomes das duas ações do provisório. O estoque é
## estado do `npc` e vai no save dele: quem salva é o NpcModule, que chama serialize/check_save/load_save. Sem dinheiro, preço ou mercado.

const TEMP_MARK: String = "TEMP-LW-065"
## Chave do estoque dentro do save do módulo `npc`.
const SAVE_KEY: String = "food_stock"
const EAT_ACTION_ID: String = "eat"
const WORK_ACTION_ID: String = "work"
const CODE_UNKNOWN_SETTLEMENT: String = "NPC_FOOD_UNKNOWN_SETTLEMENT"
const CODE_INVALID_AMOUNT: String = "NPC_FOOD_INVALID_AMOUNT"
const CODE_NOT_ENOUGH: String = "NPC_FOOD_NOT_ENOUGH"

var _rules: Dictionary[String, FoodRule] = {}
var _stock: Dictionary[String, int] = {}


## `rules`: uma por assentamento (o carregador recusa repetição; aqui a primeira vence). O estoque começa em `start_stock`.
func _init(rules: Array[FoodRule] = []) -> void:
	for rule: FoodRule in rules:
		if _rules.has(rule.settlement_id):
			continue
		_rules[rule.settlement_id] = rule
		_stock[rule.settlement_id] = rule.start_stock


## Há comida para uma refeição (`eat_cost`) no assentamento? Assentamento sem regra: não.
func has_food(settlement_id: String) -> bool:
	return _rules.has(settlement_id) and _stock[settlement_id] >= _rules[settlement_id].eat_cost


## Estoque atual e teto do assentamento.
func peek_stock(settlement_id: String) -> StockQuery:
	if not _rules.has(settlement_id):
		return StockQuery.new(_unknown_settlement("peek_stock", settlement_id), 0, 0)
	return StockQuery.new(Result.success(), _stock[settlement_id], _rules[settlement_id].max_stock)


## Tira `amount` (1 ou mais) do estoque. Se não cabe, falha e NADA muda: o estoque nunca fica negativo.
func request_consume(settlement_id: String, amount: int) -> Result:
	if not _rules.has(settlement_id):
		return _unknown_settlement("request_consume", settlement_id)
	if amount < 1:
		return Result.failure(CODE_INVALID_AMOUNT, "FoodStub.request_consume: quantidade %d; esperado 1 ou mais." % amount)
	if _stock[settlement_id] < amount:
		return Result.failure(CODE_NOT_ENOUGH, "FoodStub.request_consume: o assentamento '%s' tem %d de comida e a refeição pede %d; nada foi consumido." % [settlement_id, _stock[settlement_id], amount])
	_stock[settlement_id] -= amount
	return Result.success()


## Põe `amount` (1 ou mais, no máximo o teto) no estoque; o que passa do teto se perde.
func request_add(settlement_id: String, amount: int) -> Result:
	if not _rules.has(settlement_id):
		return _unknown_settlement("request_add", settlement_id)
	var rule: FoodRule = _rules[settlement_id]
	if amount < 1 or amount > rule.max_stock:
		return Result.failure(CODE_INVALID_AMOUNT, "FoodStub.request_add: quantidade %d; esperado de 1 a %d (o teto do assentamento '%s')." % [amount, rule.max_stock, settlement_id])
	_stock[settlement_id] = mini(_stock[settlement_id] + amount, rule.max_stock)
	return Result.success()


## Define o estoque (de 0 ao teto). Só para o teste "comida a zero"; quem expõe isso é o NpcModule, apenas em build de desenvolvimento.
func request_set_stock(settlement_id: String, amount: int) -> Result:
	if not _rules.has(settlement_id):
		return _unknown_settlement("request_set_stock", settlement_id)
	var rule: FoodRule = _rules[settlement_id]
	if amount < 0 or amount > rule.max_stock:
		return Result.failure(CODE_INVALID_AMOUNT, "FoodStub.request_set_stock: quantidade %d; esperado de 0 a %d (o teto do assentamento '%s')." % [amount, rule.max_stock, settlement_id])
	_stock[settlement_id] = amount
	return Result.success()


## Gancho do runner: a ação COMPLETA `action_id` acabou de aplicar os efeitos num NPC do assentamento e do ofício dados. `eat` consome a
## refeição; `work` do ofício que produz comida repõe a colheita. O runner conferiu `has_food` um instante antes, então a refeição sempre cabe.
func on_action_completed(action_id: String, settlement_id: String, occupation_id: String) -> void:
	if not _rules.has(settlement_id):
		return
	var rule: FoodRule = _rules[settlement_id]
	if action_id == EAT_ACTION_ID:
		var taken: Result = request_consume(settlement_id, rule.eat_cost)
		if not taken.ok:
			push_error(taken.message)
	elif action_id == WORK_ACTION_ID and occupation_id == rule.yield_occupation_id and rule.work_yield > 0:
		request_add(settlement_id, rule.work_yield)


## Volta o estoque de todos os assentamentos ao inicial (carregar um save de antes do FoodStub, que não tem o trecho de comida).
func reset_to_start() -> void:
	for settlement_id: String in settlement_ids():
		_stock[settlement_id] = _rules[settlement_id].start_stock


## Ids dos assentamentos com regra, em ordem alfabética (nunca a ordem natural do Dictionary).
func settlement_ids() -> Array[String]:
	var ids: Array[String] = []
	ids.assign(_rules.keys())
	ids.sort()
	return ids


## Estoque por assentamento, para o save (ids em ordem; os valores são inteiros).
func serialize() -> Dictionary:
	var saved: Dictionary = {}
	for settlement_id: String in settlement_ids():
		saved[settlement_id] = _stock[settlement_id]
	return saved


## Problema do trecho do save (texto vazio = pode carregar). Confere tudo, sem alterar nada. `raw` é Variant porque vem cru do JSON.
func check_save(raw: Variant) -> String:
	if typeof(raw) != TYPE_DICTIONARY:
		return "campo '%s' não é um objeto (veio %s)" % [SAVE_KEY, type_string(typeof(raw))]
	var entries: Dictionary = raw
	for key: Variant in entries.keys():
		var settlement_id: String = str(key)
		if not _rules.has(settlement_id):
			return "o estoque de comida cita o assentamento '%s', que não tem regra (esperado um de: %s)" % [settlement_id, ", ".join(settlement_ids())]
		if not _is_whole_number(entries[key]):
			return "o estoque de '%s' não é um inteiro (veio %s)" % [settlement_id, str(entries[key])]
		var amount: int = int(entries[key])
		if amount < 0 or amount > _rules[settlement_id].max_stock:
			return "o estoque %d de '%s' está fora de 0 a %d" % [amount, settlement_id, _rules[settlement_id].max_stock]
	for settlement_id: String in settlement_ids():
		if not entries.has(settlement_id):
			return "falta o estoque do assentamento '%s'" % settlement_id
	return ""


## Carrega um trecho que `check_save` aprovou.
func load_save(entries: Dictionary) -> void:
	for settlement_id: String in settlement_ids():
		_stock[settlement_id] = int(entries[settlement_id])


## Problemas do estado (lista vazia se estiver tudo certo): o estoque de cada assentamento precisa ficar de 0 ao teto.
func validate() -> Array[String]:
	var problems: Array[String] = []
	for settlement_id: String in settlement_ids():
		var max_stock: int = _rules[settlement_id].max_stock
		if _stock[settlement_id] < 0 or _stock[settlement_id] > max_stock:
			problems.append("FoodStub: o estoque %d do assentamento '%s' está fora de 0 a %d." % [_stock[settlement_id], settlement_id, max_stock])
	return problems


## Primeiro problema de referência (texto vazio = tudo existe): o assentamento de cada regra no `world` e o ofício que produz comida.
func check_references(places: SettlementService, occupation_ids: Array[String]) -> String:
	for settlement_id: String in settlement_ids():
		if not places.peek_settlement(settlement_id).result.ok:
			return "o assentamento '%s' da regra de comida não existe no `world`" % settlement_id
		var occupation_id: String = _rules[settlement_id].yield_occupation_id
		if not occupation_ids.has(occupation_id):
			return "o ofício '%s' (que produz comida em '%s') não existe nos dados de ofícios" % [occupation_id, settlement_id]
	return ""


func _unknown_settlement(caller: String, settlement_id: String) -> Result:
	return Result.failure(CODE_UNKNOWN_SETTLEMENT, "FoodStub.%s: o assentamento '%s' não tem regra de comida; esperado um de: %s." % [caller, settlement_id, ", ".join(settlement_ids())])


## O JSON devolve todo número como decimal: vale inteiro, ou decimal sem fração. `raw_value` é Variant (cru).
static func _is_whole_number(raw_value: Variant) -> bool:
	if typeof(raw_value) == TYPE_INT:
		return true
	if typeof(raw_value) != TYPE_FLOAT:
		return false
	var number: float = raw_value
	return is_finite(number) and number == floorf(number)


## Regra de comida de um assentamento (uma linha de data/food_stub.json).
class FoodRule:
	extends RefCounted

	var settlement_id: String
	var start_stock: int
	var max_stock: int
	## Comida que uma refeição (`eat`) consome.
	var eat_cost: int
	## Ofício cujo `work` completo repõe `work_yield` de comida.
	var yield_occupation_id: String
	var work_yield: int

	func _init(rule_settlement_id: String, rule_start_stock: int, rule_max_stock: int, rule_eat_cost: int, rule_yield_occupation_id: String, rule_work_yield: int) -> void:
		settlement_id = rule_settlement_id
		start_stock = rule_start_stock
		max_stock = rule_max_stock
		eat_cost = rule_eat_cost
		yield_occupation_id = rule_yield_occupation_id
		work_yield = rule_work_yield


## Resposta de `peek_stock`: `stock` e `max_stock` só valem se `result.ok`.
class StockQuery:
	extends RefCounted

	var result: Result
	var stock: int
	var max_stock: int

	func _init(query_result: Result, query_stock: int, query_max_stock: int) -> void:
		result = query_result
		stock = query_stock
		max_stock = query_max_stock
