class_name EconomyModule
extends SimModule
## Módulo `economy` (contrato em docs/modules/economy.md). LW-088a: a casca, registrada no `World` ANTES do `npc` (o `npc` vai abrir as contas ao criar NPCs) e dona do bloco `economy` do save (DEC-172).
## LW-088: o cadastro de donos (`OwnerBook`) e o livro-razão (`Ledger`). LW-089c: o inventário por dono (`GoodsStore`) e as definições (`EconomyDefinitions`, pelo construtor). Esta é a PORTA: `request_open_owner`,
## `request_transfer_goods`, `peek_balance`, `peek_conservation`, `peek_ledger_totals`, `peek_inventory` e `peek_goods_conservation`. As operações de saldo e de criar e destruir bens NÃO são da porta: quem
## as usa são as partes internas da economia (comércio, produção, salário), cada uma na sua tarefa. O `npc` só pode citar classes desta pasta (regra E do `tools/check_architecture`, DEC-171) e a porta
## devolve só cópia (tipos de `EconomyReplies`). A economia ouve `NpcDied` pelo NOME do evento (não importa o `npc`, DEC-132) e fecha a conta e o inventário do NPC morto: nada mais é aceito, mas o saldo e os bens
## continuam na soma da conservação (DEC-146). O bloco do save só ganha conteúdo quando há estado (sem dono e sem movimento continua `{}`, o hash de um jogo em que ninguém abriu conta não muda); `goods` só entra
## no bloco quando há bem em estoque ou movimento de bens.

const CODE_INVALID_SAVE: String = EconomyCodes.INVALID_SAVE
const KEY_OWNERS: String = "owners"
const KEY_LEDGER: String = "ledger"
const KEY_GOODS: String = "goods"
const NPC_DIED: String = "NpcDied"
## Tipo do dono que o `npc` abre (id em `owner_kinds.json`); só para o aviso de morte, que fecha o dono desse tipo.
const KIND_NPC: String = "npc"

var _record_history: bool
var _definitions: EconomyDefinitions
var _events: EventBus
var _subscription: int = EventBus.NO_SUBSCRIPTION
var _book: OwnerBook
var _ledger: Ledger
var _goods: GoodsStore


## `record_history`: modo de teste do `Ledger` (guarda cada lançamento). `definitions`: bens e tipos de dono já lidos (vazio por padrão: sem bens, qualquer tipo de dono).
func _init(record_history: bool = false, definitions: EconomyDefinitions = null) -> void:
	_record_history = record_history
	_definitions = definitions if definitions != null else EconomyDefinitions.new()
	_reset()


func setup(ctx: SimContext) -> void:
	_events = ctx.events


func post_setup() -> void:
	_subscription = _events.subscribe(NPC_DIED, _on_npc_died)


func teardown() -> void:
	if _events != null and _subscription != EventBus.NO_SUBSCRIPTION:
		_events.unsubscribe(_subscription)
	_subscription = EventBus.NO_SUBSCRIPTION


## Sem dono e sem movimento: bloco vazio (nada entra no hash além da presença do módulo).
func serialize() -> Dictionary:
	if _book.is_empty() and _ledger.is_pristine() and _goods.is_pristine():
		return {}
	var block: Dictionary = {KEY_OWNERS: _book.serialize(), KEY_LEDGER: _ledger.serialize()}
	if not _goods.is_pristine():
		block[KEY_GOODS] = _goods.serialize()
	return block


## Aceita o bloco vazio ou os campos conhecidos (`owners` e `ledger` sempre; `goods` quando há bens), tudo conferido antes de trocar o estado; qualquer outra chave é recusada com mensagem clara (AGENTS 12.6).
func on_load(data: Dictionary) -> Result:
	if data.is_empty():
		_reset()
		return Result.success()
	var names: PackedStringArray = PackedStringArray()
	for key: Variant in data.keys():
		names.append(str(key))
	names.sort()
	for name: String in names:
		if name != KEY_OWNERS and name != KEY_LEDGER and name != KEY_GOODS:
			return Result.failure(CODE_INVALID_SAVE, "EconomyModule.on_load: o bloco 'economy' do save tem %d chave(s) (%s); esperado vazio ou só '%s', '%s' e '%s'." % [names.size(), ", ".join(names), KEY_OWNERS, KEY_LEDGER, KEY_GOODS])
	# Variant: valores crus do save (JSON); o tipo é conferido na linha seguinte.
	var raw_owners: Variant = data.get(KEY_OWNERS)
	var raw_ledger: Variant = data.get(KEY_LEDGER)
	var raw_goods: Variant = data.get(KEY_GOODS, {})
	if typeof(raw_owners) != TYPE_DICTIONARY or typeof(raw_ledger) != TYPE_DICTIONARY or typeof(raw_goods) != TYPE_DICTIONARY:
		return Result.failure(CODE_INVALID_SAVE, "EconomyModule.on_load: '%s' e '%s' devem ser objetos e estar os dois no bloco 'economy' (e '%s', se houver, também um objeto)." % [KEY_OWNERS, KEY_LEDGER, KEY_GOODS])
	var book: OwnerBook = OwnerBook.new()
	var loaded: Result = book.load_from(raw_owners)
	if not loaded.ok:
		return loaded
	var ledger: Ledger = Ledger.new(book, _record_history)
	loaded = ledger.load_from(raw_ledger)
	if not loaded.ok:
		return loaded
	var goods: GoodsStore = GoodsStore.new(book, _definitions.goods, _definitions.kinds)
	var goods_data: Dictionary = raw_goods
	if not goods_data.is_empty():
		loaded = goods.load_from(goods_data)
		if not loaded.ok:
			return loaded
	_book = book
	_ledger = ledger
	_goods = goods
	return Result.success()


func validate() -> Array[String]:
	var problems: Array[String] = []
	for problem: String in _book.validate():
		problems.append("[owners] " + problem)
	for problem: String in _ledger.validate():
		problems.append("[ledger] " + problem)
	for problem: String in _goods.validate():
		problems.append("[goods] " + problem)
	return problems


## Abre o dono (conta e inventário). Idempotente: quem já existe fica como está. Falhas: `ECON_UNKNOWN_OWNER` (ID fora da faixa) e `ECON_DATA_INVALID` (tipo vazio ou, havendo definições, tipo que não existe).
func request_open_owner(owner_id: int, kind: String) -> Result:
	if not _definitions.kinds.is_empty() and not kind.is_empty():
		var known: Array[String] = []
		for kind_def: OwnerKindDef in _definitions.kinds:
			known.append(kind_def.id)
		if not known.has(kind):
			return Result.failure(EconomyCodes.DATA_INVALID, "EconomyModule.request_open_owner: o tipo de dono '%s' não existe; esperado um de: %s." % [kind, ", ".join(known)])
	return _book.open_owner(owner_id, kind)


## Move bens entre donos, sem criar nem destruir; tudo ou nada. Falhas: `ECON_UNKNOWN_GOOD`, `ECON_BAD_QUANTITY`, `ECON_UNKNOWN_OWNER`, `ECON_OWNER_CLOSED`, `ECON_INSUFFICIENT_GOODS` e `ECON_CAPACITY_EXCEEDED`.
func request_transfer_goods(from_id: int, to_id: int, good_id: String, quantity: int) -> Result:
	return _goods.transfer(from_id, to_id, good_id, quantity)


func peek_balance(owner_id: int) -> EconomyReplies.BalanceQuery:
	if not _book.has_owner(owner_id):
		return EconomyReplies.BalanceQuery.new(Result.failure(EconomyCodes.UNKNOWN_OWNER, "EconomyModule.peek_balance: o dono %d não existe." % owner_id), 0)
	return EconomyReplies.BalanceQuery.new(Result.success(), _ledger.balance_of(owner_id))


func peek_conservation() -> EconomyReplies.ConservationQuery:
	return EconomyReplies.ConservationQuery.new(_ledger.sum_of_balances(), _ledger.total_created(), _ledger.total_destroyed())


func peek_ledger_totals() -> EconomyReplies.LedgerTotals:
	return EconomyReplies.LedgerTotals.new(_ledger.totals_rows())


func peek_inventory(owner_id: int) -> EconomyReplies.InventoryQuery:
	if not _book.has_owner(owner_id):
		return EconomyReplies.InventoryQuery.new(Result.failure(EconomyCodes.UNKNOWN_OWNER, "EconomyModule.peek_inventory: o dono %d não existe." % owner_id), [], 0, 0)
	return EconomyReplies.InventoryQuery.new(Result.success(), _goods.inventory_rows(owner_id), _goods.weight_of(owner_id), _goods.capacity_of(owner_id))


func peek_goods_conservation() -> EconomyReplies.GoodsConservationQuery:
	return EconomyReplies.GoodsConservationQuery.new(_goods.conservation_rows())


## `NpcDied` (DEC-146): fecha o dono do NPC, se ele existe e é do tipo `npc`. NPC que nunca abriu conta não é erro. O evento é lido pelo campo `npc_id`, sem citar a classe do `npc`.
func _on_npc_died(event: SimEvent) -> void:
	# Variant: campo cru do evento; o tipo é conferido na linha seguinte.
	var raw_id: Variant = event.get("npc_id")
	if typeof(raw_id) != TYPE_INT:
		return
	var owner_id: int = raw_id
	if _book.has_owner(owner_id) and _book.kind_of(owner_id) == KIND_NPC:
		_book.close_owner(owner_id)


func _reset() -> void:
	_book = OwnerBook.new()
	_ledger = Ledger.new(_book, _record_history)
	_goods = GoodsStore.new(_book, _definitions.goods, _definitions.kinds)
