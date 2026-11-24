class_name CaravanViewPool
extends RefCounted
## LW-099b2a (viagem visível dos comerciantes; só apresentação): a reserva de corpos de caravana. Cria de antemão `routes.pool_size` corpos (o dado de apresentação;
## 8 [HIP]: os 6 comerciantes e folga), filhos de `parent` e escondidos, e NUNCA cresce: com a reserva vazia o pedido volta nulo e é contado (o corpo que falta
## aparece no relatório em vez de ser inventado em pleno jogo). No máximo UM corpo por comerciante (`trader_id`): pedir de novo devolve o MESMO corpo e conta o
## pedido repetido, nunca um segundo. Devolver esconde o corpo e o reaproveita; nada é apagado durante o jogo. Os contadores seguem o `NpcViewPool`, para o
## relatório e para os testes. Quem decide QUEM tem corpo é a 099b2b; aqui só se guarda a reserva. Contrato: docs/economia/contrato-lw-099-viagem-visivel.md, seção 2.

## Corpos criados (os de antemão; a reserva não cria outros).
var created: int = 0
var taken: int = 0
var returned: int = 0
var peak_active: int = 0
## `empty_hits` e `duplicate_requests` NÃO têm o sentido dos de mesmo nome do `NpcViewPool` (lá a reserva cresce e o pedido repetido é recusado; aqui vazia = nulo e repetido = o mesmo corpo): o chamador deve usar `body_of` ANTES de `take` (como o `NpcBodiesView.reconcile`), senão o contador incha.
## Pedidos feitos com a reserva vazia: devolveram nulo, sem criar corpo.
var empty_hits: int = 0
## Pedidos de corpo para comerciante que já tinha um: devolveram o corpo que ele já tinha.
var duplicate_requests: int = 0

var _parent: Node3D
var _free: Array[CaravanView] = []
var _active: Dictionary[int, CaravanView] = {}


## `routes.pool_size` corpos escondidos, filhos de `parent`, cada um com a tabela de carga de `routes` (dado não carregado, ou nulo: reserva de zero corpos).
func _init(parent: Node3D, routes: CaravanRoutesReader) -> void:
	_parent = parent
	var size: int = routes.pool_size if routes != null else 0
	for _index: int in size:
		var view: CaravanView = CaravanView.new(routes)
		_parent.add_child(view)
		_free.append(view)
		created += 1


## O corpo da caravana do comerciante, ligado e ainda escondido até a primeira pose (`CaravanView.bind`). Se ele já tinha corpo, o MESMO corpo (pedido repetido,
## contado). Reserva vazia: nulo (contado), sem criar corpo. ID inválido: nulo com erro visível.
func take(trader_id: int) -> CaravanView:
	if trader_id <= IdGenerator.NO_ID:
		push_error("CaravanViewPool.take: comerciante %d inválido; esperado um ID maior que %d." % [trader_id, IdGenerator.NO_ID])
		return null
	if _active.has(trader_id):
		duplicate_requests += 1
		return _active[trader_id]
	if _free.is_empty():
		empty_hits += 1
		return null
	var view: CaravanView = _free.pop_back()
	view.bind(trader_id)
	_active[trader_id] = view
	taken += 1
	peak_active = maxi(peak_active, _active.size())
	return view


## Devolve o corpo do comerciante à reserva (escondido e como novo). Falso, sem mudar nada, se ele não tinha corpo.
func give_back(trader_id: int) -> bool:
	if not _active.has(trader_id):
		return false
	var view: CaravanView = _active[trader_id]
	_active.erase(trader_id)
	view.release()
	_free.append(view)
	returned += 1
	return true


## O corpo do comerciante, ou nulo se ele não tem.
func body_of(trader_id: int) -> CaravanView:
	return _active.get(trader_id) as CaravanView


## IDs dos comerciantes com corpo, em ordem crescente.
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
		if child is CaravanView:
			children += 1
	return children - _free.size() - _active.size()
