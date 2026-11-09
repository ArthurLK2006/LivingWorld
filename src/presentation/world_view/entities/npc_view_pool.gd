class_name NpcViewPool
extends RefCounted
## Reserva de corpos de NPC (LW-072b). Cria PREWARM_COUNT corpos de antemão (filhos de `parent`, escondidos) e só cresce se faltar; um corpo
## devolvido fica escondido e é reaproveitado, e nada é apagado durante o jogo (criar e liberar nós em plena caminhada gera picos). No máximo
## UM corpo ativo por NPC: o pedido repetido é recusado, contado e registrado. Os contadores existem para o relatório e para os testes.
## Contrato: docs/modules/presentation.md.

## Corpos criados de antemão [HIP]: o SP2 mediu que 60 cobrem o limite de 50 NPCs em S0 com folga; se faltar, o pool cresce um corpo por vez.
const PREWARM_COUNT: int = 60

## Corpos criados (os de antemão e os que o pool criou por falta).
var created: int = 0
var taken: int = 0
var returned: int = 0
var peak_active: int = 0
## Vezes em que o pool estava vazio e teve de criar um corpo.
var empty_hits: int = 0
## Pedidos de corpo para NPC que já tinha um: recusados.
var duplicate_requests: int = 0

var _parent: Node3D
var _free: Array[NpcView] = []
var _active: Dictionary[int, NpcView] = {}


func _init(parent: Node3D, prewarm_count: int = PREWARM_COUNT) -> void:
	_parent = parent
	for _index: int in prewarm_count:
		_free.append(_new_view())


## Corpo para o NPC, parado, com os pés em `ground_position`. Nulo (com push_error) se o ID não for válido ou se o NPC já tiver corpo.
func take(npc_id: int, ground_position: Vector3) -> NpcView:
	if npc_id <= IdGenerator.NO_ID:
		push_error("NpcViewPool.take: NPC %d inválido; esperado um ID maior que %d." % [npc_id, IdGenerator.NO_ID])
		return null
	if _active.has(npc_id):
		duplicate_requests += 1
		push_error("NpcViewPool.take: o NPC %d já tem corpo; pedido duplicado recusado (recusados até agora: %d)." % [npc_id, duplicate_requests])
		return null
	if _free.is_empty():
		empty_hits += 1
		_free.append(_new_view())
	var view: NpcView = _free.pop_back()
	view.attach(npc_id, ground_position)
	_active[npc_id] = view
	taken += 1
	peak_active = maxi(peak_active, _active.size())
	return view


## Devolve o corpo do NPC ao pool (escondido). Falso, sem mudar nada, se o NPC não tinha corpo.
func give_back(npc_id: int) -> bool:
	if not _active.has(npc_id):
		return false
	var view: NpcView = _active[npc_id]
	_active.erase(npc_id)
	view.detach()
	_free.append(view)
	returned += 1
	return true


## O corpo do NPC, ou nulo se ele não tem.
func body_of(npc_id: int) -> NpcView:
	return _active.get(npc_id) as NpcView


## IDs dos NPCs com corpo, em ordem crescente.
func active_ids() -> Array[int]:
	var ids: Array[int] = []
	ids.assign(_active.keys())
	ids.sort()
	return ids


func active_count() -> int:
	return _active.size()


func free_count() -> int:
	return _free.size()


## Corpos que são filhos do pai mas não estão nem livres nem ativos (deveria ser sempre zero).
func lost_count() -> int:
	var children: int = 0
	for child: Node in _parent.get_children():
		if child is NpcView:
			children += 1
	return children - _free.size() - _active.size()


func _new_view() -> NpcView:
	var view: NpcView = NpcView.new()
	view.visible = false
	_parent.add_child(view)
	created += 1
	return view
