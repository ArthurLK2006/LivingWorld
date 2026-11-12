class_name PostDef
extends RefCounted
## Um posto de serviço (LW-095; docs/modules/economy.md, seção 6): local de trabalho SEM receita para os ofícios `guard` e `innkeeper`, com a folha paga pela conta do mercado do povoado. SÓ LEITURA. Cada definição vira um posto no jogo novo. Até
## a distribuição de dados dos povoados (LW-097, com `service_posts.json`) as definições só existem montadas à mão nos testes (`EconomyDefinitions.service_posts`); a conferência do local e do tipo `work` é do verificador da LW-093a.

var id: String
var settlement_id: String
var place_id: String
var occupation_id: String
var workers_wanted: int
var wage_per_hour: int


func _init(post_id: String, settlement: String, place: String, occupation: String, wanted: int, wage: int) -> void:
	id = post_id
	settlement_id = settlement
	place_id = place
	occupation_id = occupation
	workers_wanted = wanted
	wage_per_hour = wage
