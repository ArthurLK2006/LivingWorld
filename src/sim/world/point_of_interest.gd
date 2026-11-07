class_name PointOfInterest
extends RefCounted
## Ponto de interesse (LW-049; arquitetura 5.2): um lugar do mapa com o qual o ator pode interagir. É CONTEÚDO lido de
## data/world/pois.json (somente leitura depois de montado): não é salvo nem entra no state_hash. A simulação guarda só a CHAVE
## do texto (`text_key`); quem a traduz em frase é a apresentação. A altura (`position.y`) NÃO vem do arquivo: é a do terreno.

var id: String
## Tipo do ponto, texto em snake_case (hoje só "test_marker").
var kind: String
## Metros; y = altura do terreno em (x, z).
var position: Vector3
var text_key: String


func _init(point_id: String, point_kind: String, point_position: Vector3, point_text_key: String) -> void:
	id = point_id
	kind = point_kind
	position = point_position
	text_key = point_text_key
