class_name ContractFailed
extends SimEvent
## Fato: um contrato falhou (LW-096; docs/events.md): o prazo vencido (`reason` = `expired`) ou o abandono do aceitante (`abandoned`, LW-107f1), quando a custódia volta ao emissor (`contract_refund`). Carga pequena: o contrato, o emissor e o motivo. A classe mora em `economy/api/` para
## outros módulos poderem citá-la (regra E). `cause_id` é preenchido pelo EventBus. Catalogado em docs/events.md.

const REASON_EXPIRED: String = "expired"
## O aceitante largou a encomenda `delivery` antes do prazo: o contrato fecha, mas o abandono NÃO é falha para a crônica, a reputação nem as ordens de facção (sem multa; economy.md, seção 8, item (b)).
const REASON_ABANDONED: String = "abandoned"

var contract_id: int
var issuer_id: int
var reason: String


func _init(failed_contract_id: int, contract_issuer_id: int, failure_reason: String) -> void:
	super("ContractFailed")
	contract_id = failed_contract_id
	issuer_id = contract_issuer_id
	reason = failure_reason
