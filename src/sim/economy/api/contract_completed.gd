class_name ContractCompleted
extends SimEvent
## Fato: um contrato foi concluído (LW-096; docs/events.md): a recompensa foi paga ao aceitante pela custódia (`contract_payout`) ou, na vaga, o NPC a aceitou e foi atribuído ao local (recompensa 0). Carga pequena: o contrato, o aceitante e a
## recompensa. A classe mora em `economy/api/` para o `npc` poder citá-la (regra E). `cause_id` é preenchido pelo EventBus. Catalogado em docs/events.md.

var contract_id: int
var acceptor_id: int
var reward: int


func _init(completed_contract_id: int, contract_acceptor_id: int, contract_reward: int) -> void:
	super("ContractCompleted")
	contract_id = completed_contract_id
	acceptor_id = contract_acceptor_id
	reward = contract_reward
