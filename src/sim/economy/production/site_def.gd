class_name SiteDef
extends RefCounted
## Uma linha de `data/economy/production_sites.json` (LW-092): um local de produção (assentamento, local `work` do `world`, receita e a equipe desejada). SÓ LEITURA. Cada linha vira um local de produção em `on_new_game` (dono do tipo
## `site`). Os dados dos povoados (as 14 linhas da distribuição) chegam com a LW-097; a existência do assentamento e do local, o tipo `work` e a capacidade são conferidos pelo verificador da LW-093a (D1).

var id: String
var settlement_id: String
var place_id: String
var recipe_id: String
var workers_wanted: int


func _init(site_id: String, settlement: String, place: String, recipe: String, wanted: int) -> void:
	id = site_id
	settlement_id = settlement
	place_id = place
	recipe_id = recipe
	workers_wanted = wanted
