class_name OwnerBook
extends RefCounted
## Cadastro dos donos da economia (LW-088; docs/modules/economy.md, seções 2 e 3): quem existe, de que tipo e se está fechado. Todo dono (NPC, jogador, mercado, local de produção, contrato) tem um ID inteiro
## do `core`, e a conta do `Ledger` (e, depois, o inventário) é indexada por ele. Dono FECHADO (o NPC que morreu) não aceita mais operação, mas o saldo continua na soma da conservação. O TIPO é só um
## texto não vazio por enquanto: a conferência contra `owner_kinds.json` chega com a LW-089. Abrir é idempotente (quem já existe fica como está, sem comparar o tipo).


var _kinds: Dictionary[int, String] = {}
var _closed: Dictionary[int, bool] = {}


func has_owner(owner_id: int) -> bool:
	return _kinds.has(owner_id)


func is_closed(owner_id: int) -> bool:
	return bool(_closed.get(owner_id, false))


func kind_of(owner_id: int) -> String:
	return str(_kinds.get(owner_id, ""))


## Os IDs em ordem crescente (nunca a ordem do `Dictionary`, que muda depois de carregar um save).
func owner_ids() -> Array[int]:
	var ids: Array[int] = []
	ids.assign(_kinds.keys())
	ids.sort()
	return ids


func open_owner(owner_id: int, kind: String) -> Result:
	if owner_id < IdGenerator.FIRST_ID or owner_id > IdGenerator.MAX_ID:
		return Result.failure(EconomyCodes.UNKNOWN_OWNER, "OwnerBook.open_owner: ID de dono %d inválido; esperado de %d a %d." % [owner_id, IdGenerator.FIRST_ID, IdGenerator.MAX_ID])
	if kind.is_empty():
		return Result.failure(EconomyCodes.DATA_INVALID, "OwnerBook.open_owner: dono %d com tipo vazio; esperado o id de um tipo de dono." % owner_id)
	if not _kinds.has(owner_id):
		_kinds[owner_id] = kind
		_closed[owner_id] = false
	return Result.success()


## Fecha para sempre (não há reabrir). Fechar duas vezes é inofensivo.
func close_owner(owner_id: int) -> Result:
	if not _kinds.has(owner_id):
		return Result.failure(EconomyCodes.UNKNOWN_OWNER, "OwnerBook.close_owner: o dono %d não existe." % owner_id)
	_closed[owner_id] = true
	return Result.success()


## O dono existe e aceita operação? Falha com `ECON_UNKNOWN_OWNER` ou `ECON_OWNER_CLOSED`.
func check_open(owner_id: int) -> Result:
	if not _kinds.has(owner_id):
		return Result.failure(EconomyCodes.UNKNOWN_OWNER, "o dono %d não existe." % owner_id)
	if _closed[owner_id]:
		return Result.failure(EconomyCodes.OWNER_CLOSED, "o dono %d está fechado (morreu); nenhuma operação é aceita." % owner_id)
	return Result.success()
