class_name ContractLimitDef
extends RefCounted
## Uma linha de `data/economy/contract_limits.json` (LW-107f2; docs/economy/dados.md e docs/modules/economy.md, seção 8, item (c)): o máximo de encomendas ACEITAS ao mesmo tempo de UMA categoria de contrato (`kind`, do vocabulário de
## `ContractBook.CONTRACT_TYPES`). SÓ LEITURA. Quem a consulta é `EconomyModule.peek_contract_limit`; quem a aplica é a ponte, no `accept` do jogador (LW-107f3). A faixa e o vocabulário são conferidos pelo `ContractLimitLoader`.

var id: String
var kind: String
var max_accepted: int


func _init(limit_id: String, contract_kind: String, accepted_cap: int) -> void:
	id = limit_id
	kind = contract_kind
	max_accepted = accepted_cap
