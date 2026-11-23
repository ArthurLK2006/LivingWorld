class_name WagesPaid
extends SimEvent
## Fato: a folha de um local de trabalho foi paga nesta hora (LW-095; DEC-152): UM evento por local e por hora, nunca por trabalhador (laço quente, arquitetura 17.4). `workplace_id` é o `site_id` do local de produção (que paga pela conta dele,
## só nas horas em que produz) ou o `post_id` do posto de serviço (que paga pela conta do mercado). `amount_each` é o salário de cada trabalhador; quem ouve lê a lista de trabalhadores por `peek_site` ou `peek_post`. `cause_id` é
## preenchido pelo EventBus. Catalogado em docs/events.md.

## LW-094b (PROPOSTA, classe 3: muda o evento catalogado): os IDs que receberam nesta hora, em ordem crescente. O local de produção sempre preenche (na folha parcial só as equipes pagas); vazia = todos os trabalhadores do local de trabalho
## (o caso dos postos de serviço), lidos por `peek_site` ou `peek_post` como antes.
var paid_worker_ids: Array[int] = []
var workplace_id: int
var amount_each: int


func _init(paying_workplace_id: int, wage_each: int, paid_ids: Array[int] = []) -> void:
	super("WagesPaid")
	workplace_id = paying_workplace_id
	amount_each = wage_each
	paid_worker_ids = paid_ids.duplicate()
