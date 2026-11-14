class_name CaravanArrived
extends SimEvent
## Fato: a caravana de um comerciante chegou ao destino (LW-098d2; docs/modules/economy.md, 9.7; docs/events.md): UM por viagem concluída (nunca por trecho), publicado DEPOIS de a economia vender o lote e apagar o registro (o `EventBus` só enfileira: quem ouve vê o estado final).
## `route_id` é o último trecho do caminho, `destination_id` o `settlement_id` do destino, `revenue` o total recebido na venda do lote (0 se nada foi vendido) e `cost_paid` o que o lote custou na saída (quem ouve calcula o lucro realizado sem campo novo). A classe mora em `economy/api/`
## para o `npc` poder citá-la (regra E). `cause_id` é preenchido pelo EventBus. Catalogado em docs/events.md.

var trader_id: int
var route_id: String
var destination_id: String
var revenue: int
var cost_paid: int


func _init(arrived_trader_id: int, last_route_id: String, arrival_settlement_id: String, sale_revenue: int, lot_cost: int) -> void:
	super("CaravanArrived")
	trader_id = arrived_trader_id
	route_id = last_route_id
	destination_id = arrival_settlement_id
	revenue = sale_revenue
	cost_paid = lot_cost
