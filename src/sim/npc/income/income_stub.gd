class_name IncomeStub
extends RefCounted
## TEMP-LW-066: renda SIMBÓLICA de quem trabalha, provisória (docs/modules/npc.md, seção 9). SAI NA LW-095, quando os locais de produção
## passarem a pagar salário pelo Ledger e a renda vier do dinheiro recebido. Sem dinheiro, preço, Ledger ou mercado. Não tem estado próprio
## (nada a salvar): é só a tabela "ofício -> alívio de renda" de data/income_stub.json. Entra no ActionRunner como `extra_effects` do
## provedor de ações: quando um ofício da tabela faz `work`, a necessidade `income` cai `income_relief` pontos, na MESMA função e pela MESMA
## conta dos efeitos da tabela de ações (proporcional ao progresso: trabalho completo alivia tudo, interrompido alivia a parte cumprida). Sem
## trabalhar a renda "decai" sozinha: é a taxa da própria necessidade `income` (data/needs.json). Ofício que não está na tabela não alivia.

const TEMP_MARK: String = "TEMP-LW-066"
## A necessidade aliviada e a ação que alivia (provisório: ids fixos aqui, a regra por ofício é dado).
const NEED_ID: String = "income"
const WORK_ACTION_ID: String = "work"

var _relief_by_occupation: Dictionary[String, int] = {}


## `rules`: uma por ofício (o carregador recusa repetição; aqui a primeira vence).
func _init(rules: Array[IncomeRule] = []) -> void:
	for rule: IncomeRule in rules:
		if not _relief_by_occupation.has(rule.occupation_id):
			_relief_by_occupation[rule.occupation_id] = rule.income_relief


## O efeito extra (queda de `income`) para esta ação e este ofício; lista vazia se a ação não é o trabalho ou o ofício não está na tabela.
func extra_effects(action_id: String, occupation_id: String) -> Array[ActionDef.ActionEffect]:
	var effects: Array[ActionDef.ActionEffect] = []
	if action_id == WORK_ACTION_ID and _relief_by_occupation.has(occupation_id):
		effects.append(ActionDef.ActionEffect.new(NEED_ID, -_relief_by_occupation[occupation_id]))
	return effects


## Alívio de renda do ofício por trabalho completo (0 se o ofício não está na tabela).
func peek_relief(occupation_id: String) -> int:
	return int(_relief_by_occupation.get(occupation_id, 0))


## Ids dos ofícios da tabela, em ordem alfabética (nunca a ordem natural do Dictionary).
func occupation_ids() -> Array[String]:
	var ids: Array[String] = []
	ids.assign(_relief_by_occupation.keys())
	ids.sort()
	return ids


## Primeiro problema de referência (texto vazio = tudo existe): a necessidade `income` nas definições e cada ofício da tabela nos dados de
## ofícios. `need_ids` e `occupation_ids` são o que o módulo realmente tem.
func check_references(need_ids: Array[String], occupation_ids_known: Array[String]) -> String:
	if not need_ids.has(NEED_ID):
		return "a necessidade '%s' não existe nas definições de necessidades" % NEED_ID
	for occupation_id: String in occupation_ids():
		if not occupation_ids_known.has(occupation_id):
			return "o ofício '%s' da tabela de renda não existe nos dados de ofícios" % occupation_id
	return ""


## Regra de renda de um ofício (uma linha de data/income_stub.json).
class IncomeRule:
	extends RefCounted

	var occupation_id: String
	## Pontos de `income` que um trabalho completo tira.
	var income_relief: int

	func _init(rule_occupation_id: String, rule_income_relief: int) -> void:
		occupation_id = rule_occupation_id
		income_relief = rule_income_relief
