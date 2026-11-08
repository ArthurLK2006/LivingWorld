class_name Sp2BodyPool
extends RefCounted
## LW-071 (SP2, DESCARTÁVEL): pool de corpos. Pré-aquece POOL_PREWARM corpos (filhos de `parent`, escondidos) e cresce só se faltar; no
## máximo UM corpo ativo por NPC. Corpo devolvido fica escondido e é reaproveitado; nada é apagado durante o jogo. Contadores para o
## relatório: criados, retirados, devolvidos, pico de ativos e vezes em que o pool estava vazio.

var created: int = 0
var taken: int = 0
var returned: int = 0
var peak_active: int = 0
var empty_hits: int = 0
## Pedidos de corpo para NPC que já tinha um (seria um duplicado): recusados e contados.
var duplicate_requests: int = 0

var _parent: Node
var _free: Array[Sp2Body] = []
var _active: Dictionary[int, Sp2Body] = {}


func _init(parent: Node, prewarm: int = Sp2Constants.POOL_PREWARM) -> void:
	_parent = parent
	for _index: int in prewarm:
		_free.append(_new_body())


## Corpo para o NPC (ou null, se ele já tem um: duplicado recusado).
func take(npc_id: int, at: Vector3) -> Sp2Body:
	if _active.has(npc_id):
		duplicate_requests += 1
		return null
	if _free.is_empty():
		empty_hits += 1
		_free.append(_new_body())
	var body: Sp2Body = _free.pop_back()
	body.attach(npc_id, at)
	_active[npc_id] = body
	taken += 1
	peak_active = maxi(peak_active, _active.size())
	return body


## Devolve o corpo do NPC ao pool. Devolve false se o NPC não tinha corpo.
func give_back(npc_id: int) -> bool:
	if not _active.has(npc_id):
		return false
	var body: Sp2Body = _active[npc_id]
	_active.erase(npc_id)
	body.detach()
	_free.append(body)
	returned += 1
	return true


func body_of(npc_id: int) -> Sp2Body:
	return _active.get(npc_id) as Sp2Body


func active_ids() -> Array[int]:
	var ids: Array[int] = []
	ids.assign(_active.keys())
	ids.sort()
	return ids


func active_count() -> int:
	return _active.size()


func free_count() -> int:
	return _free.size()


## Corpos ativos com o mesmo NPC (deveria ser sempre zero) e corpos que são filhos do pai mas não estão nem livres nem ativos.
func lost_bodies() -> int:
	var known: int = _free.size() + _active.size()
	var children: int = 0
	for child: Node in _parent.get_children():
		children += 1 if child is Sp2Body else 0
	return children - known


func show_numbers(is_shown: bool) -> void:
	for body: Sp2Body in _active.values():
		body.show_number(is_shown)


func summary() -> String:
	return "criados %d, retirados %d, devolvidos %d, pico de ativos %d, pool vazio %d, pedidos duplicados %d" % [created, taken, returned, peak_active, empty_hits, duplicate_requests]


func _new_body() -> Sp2Body:
	var body: Sp2Body = Sp2Body.new()
	body.visible = false
	_parent.add_child(body)
	created += 1
	return body
