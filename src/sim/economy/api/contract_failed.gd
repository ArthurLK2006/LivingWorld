class_name ContractFailed
extends SimEvent
## Fato: um contrato falhou (LW-096; docs/events.md): hoje só o prazo vencido (`reason` = `expired`), quando a custódia volta ao emissor (`contract_refund`). Carga pequena: o contrato, o emissor e o motivo. A classe mora em `economy/api/` para
## outros módulos poderem citá-la (regra E). `cause_id` é preenchido pelo EventBus. Catalogado em docs/events.md.

const REASON_EXPIRED: String = "expired"

var contract_id: int
var issuer_id: int
var reason: String


func _init(failed_contract_id: int, contract_issuer_id: int, failure_reason: String) -> void:
	super("ContractFailed")
	contract_id = failed_contract_id
	issuer_id = contract_issuer_id
	reason = failure_reason
