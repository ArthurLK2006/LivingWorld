class_name EconomyModule
extends SimModule
## Módulo `economy` (contrato em docs/modules/economy.md). LW-088a: a casca, registrada no `World` ANTES do `npc` (o `npc` vai abrir as contas ao criar NPCs) e dona do bloco `economy` do save (DEC-172).
## LW-088: o cadastro de donos (`OwnerBook`) e o livro-razão (`Ledger`), com a porta de entrada: `request_open_owner`, `peek_balance`, `peek_conservation` e `peek_ledger_totals`. As operações de saldo
## (`transfer`, `mint`, `burn`) NÃO são da porta: quem as usa são as partes internas da economia (comércio, produção, salário), cada uma na sua tarefa. Esta é a porta: o `npc` só pode citar classes
## desta pasta (regra E do `tools/check_architecture`, DEC-171) e devolve-se só cópia (tipos de `EconomyReplies`). O bloco do save só ganha conteúdo quando há estado: sem dono e sem movimento ele
## continua `{}` (o mesmo valor da casca), então o hash de um jogo em que ninguém abriu conta não muda.

const CODE_INVALID_SAVE: String = EconomyCodes.INVALID_SAVE
const KEY_OWNERS: String = "owners"
const KEY_LEDGER: String = "ledger"

var _record_history: bool
var _book: OwnerBook
var _ledger: Ledger


## `record_history`: modo de teste do `Ledger` (guarda cada lançamento). No jogo fica desligado e só os totais por motivo vão ao save.
func _init(record_history: bool = false) -> void:
	_record_history = record_history
	_reset()


## Sem dono e sem movimento: bloco vazio (nada entra no hash além da presença do módulo).
func serialize() -> Dictionary:
	if _book.is_empty() and _ledger.is_pristine():
		return {}
	return {KEY_OWNERS: _book.serialize(), KEY_LEDGER: _ledger.serialize()}


## Aceita o bloco vazio ou os dois campos conhecidos, tudo conferido antes de trocar o estado; qualquer outra chave é recusada com mensagem clara (AGENTS 12.6).
func on_load(data: Dictionary) -> Result:
	if data.is_empty():
		_reset()
		return Result.success()
	var names: PackedStringArray = PackedStringArray()
	for key: Variant in data.keys():
		names.append(str(key))
	names.sort()
	for name: String in names:
		if name != KEY_OWNERS and name != KEY_LEDGER:
			return Result.failure(CODE_INVALID_SAVE, "EconomyModule.on_load: o bloco 'economy' do save tem %d chave(s) (%s); esperado vazio ou só '%s' e '%s'." % [names.size(), ", ".join(names), KEY_OWNERS, KEY_LEDGER])
	# Variant: valores crus do save (JSON); o tipo é conferido na linha seguinte.
	var raw_owners: Variant = data.get(KEY_OWNERS)
	var raw_ledger: Variant = data.get(KEY_LEDGER)
	if typeof(raw_owners) != TYPE_DICTIONARY or typeof(raw_ledger) != TYPE_DICTIONARY:
		return Result.failure(CODE_INVALID_SAVE, "EconomyModule.on_load: '%s' e '%s' devem ser objetos e estar os dois no bloco 'economy'." % [KEY_OWNERS, KEY_LEDGER])
	var book: OwnerBook = OwnerBook.new()
	var loaded: Result = book.load_from(raw_owners)
	if not loaded.ok:
		return loaded
	var ledger: Ledger = Ledger.new(book, _record_history)
	loaded = ledger.load_from(raw_ledger)
	if not loaded.ok:
		return loaded
	_book = book
	_ledger = ledger
	return Result.success()


func validate() -> Array[String]:
	var problems: Array[String] = []
	for problem: String in _book.validate():
		problems.append("[owners] " + problem)
	for problem: String in _ledger.validate():
		problems.append("[ledger] " + problem)
	return problems


## Abre o dono (conta e, nas tarefas seguintes, inventário). Idempotente: quem já existe fica como está. Falhas: `ECON_UNKNOWN_OWNER` (ID fora da faixa) e `ECON_DATA_INVALID` (tipo vazio).
func request_open_owner(owner_id: int, kind: String) -> Result:
	return _book.open_owner(owner_id, kind)


func peek_balance(owner_id: int) -> EconomyReplies.BalanceQuery:
	if not _book.has_owner(owner_id):
		return EconomyReplies.BalanceQuery.new(Result.failure(EconomyCodes.UNKNOWN_OWNER, "EconomyModule.peek_balance: o dono %d não existe." % owner_id), 0)
	return EconomyReplies.BalanceQuery.new(Result.success(), _ledger.balance_of(owner_id))


func peek_conservation() -> EconomyReplies.ConservationQuery:
	return EconomyReplies.ConservationQuery.new(_ledger.sum_of_balances(), _ledger.total_created(), _ledger.total_destroyed())


func peek_ledger_totals() -> EconomyReplies.LedgerTotals:
	return EconomyReplies.LedgerTotals.new(_ledger.totals_rows())


func _reset() -> void:
	_book = OwnerBook.new()
	_ledger = Ledger.new(_book, _record_history)
