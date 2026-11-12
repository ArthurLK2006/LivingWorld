class_name ContractOffered
extends SimEvent
## Fato: um contrato foi postado (LW-096; docs/events.md): `labor` ou `delivery` com a recompensa retida na custódia, ou (na parte das vagas) uma `vacancy` que um local de trabalho oferece. Carga pequena: o contrato, o tipo, o emissor, a recompensa
## (0 na vaga) e o prazo (0 = sem prazo, só na vaga). A classe mora em `economy/api/` para o `npc` poder citá-la (regra E) e aceitar a vaga pela utilidade. `cause_id` é preenchido pelo EventBus. Catalogado em docs/events.md.

var contract_id: int
var kind: String
var issuer_id: int
var reward: int
var deadline: int


func _init(offered_contract_id: int, contract_kind: String, contract_issuer_id: int, contract_reward: int, contract_deadline: int) -> void:
	super("ContractOffered")
	contract_id = offered_contract_id
	kind = contract_kind
	issuer_id = contract_issuer_id
	reward = contract_reward
	deadline = contract_deadline
