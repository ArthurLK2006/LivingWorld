class_name EconomyCodes
extends RefCounted
## Códigos de erro da economia (`Result.code`): todos com prefixo `ECON_` (docs/modules/economy.md, seção 10). Cada tarefa acrescenta os seus; aqui só os do cadastro de
## donos, do `Ledger`, dos bens e do save (LW-088 e LW-089). O `npc` e a ponte comparam o código com estas constantes, nunca com texto solto.

const UNKNOWN_OWNER: String = "ECON_UNKNOWN_OWNER"
const OWNER_CLOSED: String = "ECON_OWNER_CLOSED"
const BAD_AMOUNT: String = "ECON_BAD_AMOUNT"
const INSUFFICIENT_FUNDS: String = "ECON_INSUFFICIENT_FUNDS"
const UNKNOWN_GOOD: String = "ECON_UNKNOWN_GOOD"
const BAD_QUANTITY: String = "ECON_BAD_QUANTITY"
const INSUFFICIENT_GOODS: String = "ECON_INSUFFICIENT_GOODS"
const CAPACITY_EXCEEDED: String = "ECON_CAPACITY_EXCEEDED"
const DATA_INVALID: String = "ECON_DATA_INVALID"
const INVALID_SAVE: String = "ECON_INVALID_SAVE"
