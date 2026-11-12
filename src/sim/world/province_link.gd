class_name ProvinceLink
extends RefCounted
## Ligação entre duas províncias vizinhas (LW-118b): uma linha de data/world/province_adjacency.json, SEM direção (o par (a, b) é o par (b, a)). Por convenção do arquivo `province_a_id` vem antes
## de `province_b_id` na ordem alfabética e o `id` é `<a>__<b>`. CONTEÚDO somente leitura, sem estado salvo.

var id: String
var province_a_id: String
var province_b_id: String


func _init(link_id: String, link_province_a_id: String, link_province_b_id: String) -> void:
	id = link_id
	province_a_id = link_province_a_id
	province_b_id = link_province_b_id


## A província do outro lado da ligação (vazio se `province_id` não é uma das pontas).
func other_end(province_id: String) -> String:
	if province_id == province_a_id:
		return province_b_id
	if province_id == province_b_id:
		return province_a_id
	return ""
