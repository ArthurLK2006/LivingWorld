class_name ContractBook
extends RefCounted
## Os contratos da economia (LW-096; docs/modules/economy.md, seção 8; DEC-165): `labor` (trabalho avulso: `place_id` e `minutes`), `delivery` (entrega: `good_id`, `quantity` e `destination_id`) e, na parte das vagas, `vacancy`. O `contract_id` é um ID do
## `core`; o contrato COM recompensa é dono de uma conta do tipo `contract`, a CUSTÓDIA: ao postar, o emissor paga a recompensa para ela (`contract_escrow`) e o dinheiro só sai dali para o aceitante (`contract_payout`) ou de volta para o emissor
## (`contract_refund`), nunca fica retido. Estado: `open`, `accepted`, `completed`, `failed`, `expired`. Esta parte: postar (validado, tudo ou nada) e aceitar (só `open`, um aceitante); a conclusão, o prazo e as vagas vêm nas partes seguintes.
## Conclusão (parte c): `labor` pelo turno de trabalho registrado no local (`work_shift`; "um trabalho, um pagamento": recusado se o trabalhador já é atribuído àquele local) e `delivery` pela entrega dos bens ao destino (`deliver`); a custódia paga o
## aceitante (`contract_payout`) e o estado vira `completed`. Prazo (parte d): `expire` vence, na hora seguinte, o contrato aberto ou aceito cujo prazo passou: a custódia volta ao emissor (`contract_refund`) e o estado vira `expired`; emissor FECHADO (morreu) não recebe de volta e a recompensa fica na
## conta do contrato [LIM] (o dinheiro continua contado no teste de ouro). `deadline` é um minuto de simulação (0 = sem prazo, só para a vaga). Nunca sorteia nem olha o relógio: quem chama passa o `now`.

const LABOR: String = "labor"
const DELIVERY: String = "delivery"
const VACANCY: String = "vacancy"
## Os tipos de contrato (`kind`). Sem o prefixo `KIND_`, que o `tools/check_content_ids` reserva para os tipos de dono de `owner_kinds.json`.
const CONTRACT_TYPES: Array[String] = [LABOR, DELIVERY, VACANCY]
const STATE_OPEN: String = "open"
const STATE_ACCEPTED: String = "accepted"
const STATE_COMPLETED: String = "completed"
const STATE_FAILED: String = "failed"
const STATE_EXPIRED: String = "expired"
const STATES: Array[String] = [STATE_OPEN, STATE_ACCEPTED, STATE_COMPLETED, STATE_FAILED, STATE_EXPIRED]
## Id do tipo de dono da custódia (`owner_kinds.json`).
const KIND_OWNER: String = "contract"
const KEY_CONTRACTS: String = "contracts"
const KEY_KIND: String = "kind"
const KEY_ISSUER: String = "issuer_id"
const KEY_REWARD: String = "reward"
const KEY_DEADLINE: String = "deadline"
const KEY_STATE: String = "state"
const KEY_ACCEPTOR: String = "acceptor_id"
const KEY_PLACE: String = "place_id"
const KEY_MINUTES: String = "minutes"
const KEY_GOOD: String = "good_id"
const KEY_QUANTITY: String = "quantity"
const KEY_DESTINATION: String = "destination_id"
## Minutos de trabalho já registrados no `labor` (0 ao postar).
const KEY_WORKED: String = "worked_minutes"
## O local de trabalho (o `site_id` ou o `post_id`) a que a vaga se refere.
const KEY_WORKPLACE: String = "workplace_id"
## Chaves do objetivo que quem posta entrega (as mesmas do estado).
const OBJECTIVE_LABOR: Array[String] = [KEY_PLACE, KEY_MINUTES]
const OBJECTIVE_DELIVERY: Array[String] = [KEY_GOOD, KEY_QUANTITY, KEY_DESTINATION]
const OBJECTIVE_VACANCY: Array[String] = [KEY_WORKPLACE]

var _book: OwnerBook
var _ledger: Ledger
var _goods: GoodsStore
var _production: ProductionBook
var _posts: ServicePostBook
var _contracts: Dictionary[int, Dictionary] = {}


## `production` e `posts` podem ser nulos (economia sem eles): então nenhum local de trabalho é conhecido.
func _init(owner_book: OwnerBook, money_ledger: Ledger, goods_store: GoodsStore, production_book: ProductionBook, post_book: ServicePostBook) -> void:
	_book = owner_book
	_ledger = money_ledger
	_goods = goods_store
	_production = production_book
	_posts = post_book


## Posta um contrato `labor` ou `delivery` e retém a recompensa na custódia. Tudo ou nada: valida o emissor (aberto), o tipo, a recompensa (1 ou mais), o prazo (depois de `now`) e o objetivo (`objective` com as chaves do tipo) ANTES de mudar
## qualquer coisa. Falhas: `ECON_UNKNOWN_OWNER`, `ECON_OWNER_CLOSED`, `ECON_BAD_AMOUNT`, `ECON_CONTRACT_IMPOSSIBLE`, `ECON_INSUFFICIENT_FUNDS`.
func post(contract_id: int, kind: String, issuer_id: int, reward: int, deadline: int, now: int, objective: Dictionary) -> Result:
	var checked: Result = _book.check_open(issuer_id)
	if not checked.ok:
		return checked
	if _contracts.has(contract_id) or _book.has_owner(contract_id):
		return Result.failure(EconomyCodes.CONTRACT_IMPOSSIBLE, "ContractBook.post: o ID %d já está em uso." % contract_id)
	if kind != LABOR and kind != DELIVERY:
		return Result.failure(EconomyCodes.CONTRACT_IMPOSSIBLE, "ContractBook.post: o tipo '%s' não é postado por este comando; esperado '%s' ou '%s'." % [kind, LABOR, DELIVERY])
	if reward < 1:
		return Result.failure(EconomyCodes.BAD_AMOUNT, "ContractBook.post: a recompensa é %d; esperado 1 ou mais." % reward)
	if deadline <= now:
		return Result.failure(EconomyCodes.CONTRACT_IMPOSSIBLE, "ContractBook.post: o prazo %d não é depois de agora (%d)." % [deadline, now])
	var problem: String = _objective_problem(kind, objective)
	if not problem.is_empty():
		return Result.failure(EconomyCodes.CONTRACT_IMPOSSIBLE, "ContractBook.post: %s." % problem)
	if _ledger.balance_of(issuer_id) < reward:
		return Result.failure(EconomyCodes.INSUFFICIENT_FUNDS, "ContractBook.post: o emissor %d tem saldo %d e não cobre a recompensa %d." % [issuer_id, _ledger.balance_of(issuer_id), reward])
	var opened: Result = _book.open_owner(contract_id, KIND_OWNER)
	if opened.ok:
		opened = _ledger.transfer(issuer_id, contract_id, reward, Ledger.REASON_CONTRACT_ESCROW)
	if not opened.ok:
		return opened
	var state: Dictionary = {KEY_KIND: kind, KEY_ISSUER: issuer_id, KEY_REWARD: reward, KEY_DEADLINE: deadline, KEY_STATE: STATE_OPEN, KEY_ACCEPTOR: IdGenerator.NO_ID}
	for key: String in _objective_keys(kind):
		state[key] = objective[key]
	if kind == LABOR:
		state[KEY_WORKED] = 0
	_contracts[contract_id] = state
	return Result.success()


## Aceita o contrato: só `open`, um aceitante; o aceitante é um dono aberto e não é o emissor. Falhas: `ECON_UNKNOWN_CONTRACT`, `ECON_CONTRACT_NOT_OPEN`, `ECON_UNKNOWN_OWNER`, `ECON_OWNER_CLOSED`, `ECON_CONTRACT_IMPOSSIBLE`.
func accept(contract_id: int, actor_id: int) -> Result:
	if not _contracts.has(contract_id):
		return Result.failure(EconomyCodes.UNKNOWN_CONTRACT, "ContractBook.accept: o contrato %d não existe." % contract_id)
	var state: Dictionary = _contracts[contract_id]
	if state[KEY_STATE] != STATE_OPEN:
		return Result.failure(EconomyCodes.CONTRACT_NOT_OPEN, "ContractBook.accept: o contrato %d está '%s'; esperado '%s'." % [contract_id, state[KEY_STATE], STATE_OPEN])
	if state[KEY_KIND] == VACANCY:
		return Result.failure(EconomyCodes.CONTRACT_IMPOSSIBLE, "ContractBook.accept: a vaga %d é aceita pelo comando das vagas, que atribui o trabalhador." % contract_id)
	var checked: Result = _book.check_open(actor_id)
	if not checked.ok:
		return checked
	if actor_id == state[KEY_ISSUER]:
		return Result.failure(EconomyCodes.CONTRACT_IMPOSSIBLE, "ContractBook.accept: o emissor %d não aceita o próprio contrato." % actor_id)
	state[KEY_STATE] = STATE_ACCEPTED
	state[KEY_ACCEPTOR] = actor_id
	return Result.success()


## Registra `minutes` de trabalho do `worker_id` no local `place_id` para o contrato `labor` que ele aceitou ali; ao completar os minutos do contrato (dentro do prazo) a custódia paga o trabalhador e o contrato fica `completed`. Tudo ou nada.
## Falhas: `ECON_UNKNOWN_OWNER`, `ECON_OWNER_CLOSED`, `ECON_CONTRACT_IMPOSSIBLE` (minutos fora da faixa ou prazo vencido), `ECON_WORKER_ALREADY_ASSIGNED` (o trabalhador já é atribuído ao local de produção ou ao posto de `place_id`: o salário paga esse trabalho)
## e `ECON_UNKNOWN_CONTRACT` (ele não aceitou nenhum `labor` ali).
func work_shift(place_id: String, worker_id: int, minutes: int, now: int) -> Outcome:
	var checked: Result = _book.check_open(worker_id)
	if not checked.ok:
		return Outcome.failed(checked)
	if minutes < 1:
		return Outcome.failed(Result.failure(EconomyCodes.CONTRACT_IMPOSSIBLE, "ContractBook.work_shift: os minutos são %d; esperado 1 ou mais." % minutes))
	if _is_assigned_at(place_id, worker_id):
		return Outcome.failed(Result.failure(EconomyCodes.WORKER_ALREADY_ASSIGNED, "ContractBook.work_shift: o trabalhador %d já é atribuído ao local '%s' e é pago pela folha dele; um trabalho, um pagamento." % [worker_id, place_id]))
	var contract_id: int = _accepted_labor_of(worker_id, place_id)
	if contract_id == IdGenerator.NO_ID:
		return Outcome.failed(Result.failure(EconomyCodes.UNKNOWN_CONTRACT, "ContractBook.work_shift: o trabalhador %d não aceitou nenhum contrato de trabalho avulso em '%s'." % [worker_id, place_id]))
	var state: Dictionary = _contracts[contract_id]
	if now >= int(state[KEY_DEADLINE]):
		return Outcome.failed(Result.failure(EconomyCodes.CONTRACT_IMPOSSIBLE, "ContractBook.work_shift: o prazo do contrato %d (%d) já passou (agora %d)." % [contract_id, state[KEY_DEADLINE], now]))
	var worked: int = int(state[KEY_WORKED]) + minutes
	if worked < int(state[KEY_MINUTES]):
		state[KEY_WORKED] = worked
		return Outcome.progress(contract_id)
	var paid: Result = _ledger.check_transfer(contract_id, worker_id, int(state[KEY_REWARD]), Ledger.REASON_CONTRACT_PAYOUT)
	if not paid.ok:
		return Outcome.failed(paid)
	state[KEY_WORKED] = int(state[KEY_MINUTES])
	return _complete(contract_id)


## Entrega os bens do contrato `delivery` aceito (do aceitante para o destino) e a custódia paga o aceitante. Tudo ou nada: confere os bens e o pagamento ANTES de mover qualquer coisa. Falhas: `ECON_UNKNOWN_CONTRACT`, `ECON_CONTRACT_IMPOSSIBLE` (não é
## `delivery` ou o prazo venceu), `ECON_CONTRACT_NOT_OPEN` (não está aceito) e as dos bens (`ECON_INSUFFICIENT_GOODS`, `ECON_CAPACITY_EXCEEDED`, `ECON_OWNER_CLOSED`).
func deliver(contract_id: int, now: int) -> Outcome:
	if not _contracts.has(contract_id):
		return Outcome.failed(Result.failure(EconomyCodes.UNKNOWN_CONTRACT, "ContractBook.deliver: o contrato %d não existe." % contract_id))
	var state: Dictionary = _contracts[contract_id]
	if state[KEY_KIND] != DELIVERY:
		return Outcome.failed(Result.failure(EconomyCodes.CONTRACT_IMPOSSIBLE, "ContractBook.deliver: o contrato %d é '%s'; esperado '%s'." % [contract_id, state[KEY_KIND], DELIVERY]))
	if state[KEY_STATE] != STATE_ACCEPTED:
		return Outcome.failed(Result.failure(EconomyCodes.CONTRACT_NOT_OPEN, "ContractBook.deliver: o contrato %d está '%s'; esperado '%s'." % [contract_id, state[KEY_STATE], STATE_ACCEPTED]))
	if now >= int(state[KEY_DEADLINE]):
		return Outcome.failed(Result.failure(EconomyCodes.CONTRACT_IMPOSSIBLE, "ContractBook.deliver: o prazo do contrato %d (%d) já passou (agora %d)." % [contract_id, state[KEY_DEADLINE], now]))
	var acceptor: int = state[KEY_ACCEPTOR]
	var moved: Result = _goods.check_transfer(acceptor, state[KEY_DESTINATION], state[KEY_GOOD], state[KEY_QUANTITY])
	if not moved.ok:
		return Outcome.failed(moved)
	var paid: Result = _ledger.check_transfer(contract_id, acceptor, int(state[KEY_REWARD]), Ledger.REASON_CONTRACT_PAYOUT)
	if not paid.ok:
		return Outcome.failed(paid)
	_goods.transfer(acceptor, state[KEY_DESTINATION], state[KEY_GOOD], state[KEY_QUANTITY])
	return _complete(contract_id)


## Um contrato que acabou de vencer (para quem chama publicar o `ContractFailed`).
class Expired:
	extends RefCounted

	var contract_id: int
	var issuer_id: int

	func _init(expired_contract_id: int, contract_issuer_id: int) -> void:
		contract_id = expired_contract_id
		issuer_id = contract_issuer_id


## O que um comando de conclusão fez: `result`, o contrato (`IdGenerator.NO_ID` se nenhum) e, se ele foi concluído, o aceitante e a recompensa paga (para quem chama publicar o `ContractCompleted`).
class Outcome:
	extends RefCounted

	var result: Result
	var contract_id: int = IdGenerator.NO_ID
	var completed: bool = false
	var acceptor_id: int = IdGenerator.NO_ID
	var reward: int = 0

	static func failed(failure: Result) -> Outcome:
		var outcome: Outcome = Outcome.new()
		outcome.result = failure
		return outcome

	## Turno registrado, contrato ainda não completo.
	static func progress(worked_contract_id: int) -> Outcome:
		var outcome: Outcome = Outcome.new()
		outcome.result = Result.success()
		outcome.contract_id = worked_contract_id
		return outcome


## Vence os contratos `labor` e `delivery`, abertos ou aceitos, cujo prazo passou (`now` maior ou igual ao prazo), por ID crescente: a custódia volta ao emissor (`contract_refund`) se ele está aberto, e o estado vira `expired`. Devolve os que venceram.
func expire(now: int) -> Array[Expired]:
	var expired: Array[Expired] = []
	for contract_id: int in contract_ids():
		var state: Dictionary = _contracts[contract_id]
		var held: bool = state[KEY_STATE] == STATE_OPEN or state[KEY_STATE] == STATE_ACCEPTED
		if not held or state[KEY_KIND] == VACANCY or int(state[KEY_DEADLINE]) == 0 or now < int(state[KEY_DEADLINE]):
			continue
		var issuer: int = state[KEY_ISSUER]
		if _book.check_open(issuer).ok and _ledger.balance_of(contract_id) > 0:
			var refunded: Result = _ledger.transfer(contract_id, issuer, _ledger.balance_of(contract_id), Ledger.REASON_CONTRACT_REFUND)
			if not refunded.ok:
				push_error("ContractBook.expire: a custódia do contrato %d não voltou ao emissor %d: %s" % [contract_id, issuer, refunded.message])
		state[KEY_STATE] = STATE_EXPIRED
		expired.append(Expired.new(contract_id, issuer))
	return expired


## Posta a vaga do local de trabalho `workplace_id` (a economia a posta sozinha, nunca por comando): emissor o próprio local, recompensa 0, sem prazo e SEM custódia. Falha se o ID já está em uso.
func post_vacancy(contract_id: int, workplace_id: int) -> Result:
	if _contracts.has(contract_id) or _book.has_owner(contract_id):
		return Result.failure(EconomyCodes.CONTRACT_IMPOSSIBLE, "ContractBook.post_vacancy: o ID %d já está em uso." % contract_id)
	_contracts[contract_id] = {KEY_KIND: VACANCY, KEY_ISSUER: workplace_id, KEY_REWARD: 0, KEY_DEADLINE: 0, KEY_STATE: STATE_OPEN, KEY_ACCEPTOR: IdGenerator.NO_ID, KEY_WORKPLACE: workplace_id}
	return Result.success()


## O ID da vaga ABERTA do local de trabalho (`IdGenerator.NO_ID` se não há).
func open_vacancy_of(workplace_id: int) -> int:
	for contract_id: int in contract_ids():
		var state: Dictionary = _contracts[contract_id]
		if state[KEY_KIND] == VACANCY and state[KEY_STATE] == STATE_OPEN and state[KEY_WORKPLACE] == workplace_id:
			return contract_id
	return IdGenerator.NO_ID


## A vaga aberta que não faz mais falta falha (sem evento: quem a quiser aceitar recebe `ECON_CONTRACT_NOT_OPEN`).
func cancel_vacancy(contract_id: int) -> void:
	if _contracts.has(contract_id) and _contracts[contract_id][KEY_KIND] == VACANCY and _contracts[contract_id][KEY_STATE] == STATE_OPEN:
		_contracts[contract_id][KEY_STATE] = STATE_FAILED


## O NPC `actor_id` ocupou a vaga: o contrato fica `completed` e o resultado (recompensa 0) serve para o `ContractCompleted`. Quem chama já atribuiu o NPC ao local.
func complete_vacancy(contract_id: int, actor_id: int) -> Outcome:
	var state: Dictionary = _contracts[contract_id]
	state[KEY_STATE] = STATE_COMPLETED
	state[KEY_ACCEPTOR] = actor_id
	var outcome: Outcome = Outcome.new()
	outcome.result = Result.success()
	outcome.contract_id = contract_id
	outcome.completed = true
	outcome.acceptor_id = actor_id
	outcome.reward = 0
	return outcome


func has_contract(contract_id: int) -> bool:
	return _contracts.has(contract_id)


## Os contratos, por ID crescente.
func contract_ids() -> Array[int]:
	var ids: Array[int] = []
	ids.assign(_contracts.keys())
	ids.sort()
	return ids


## Uma cópia do estado do contrato (vazia se não existe).
func state_of(contract_id: int) -> Dictionary:
	return (_contracts.get(contract_id, {}) as Dictionary).duplicate(true)


func is_pristine() -> bool:
	return _contracts.is_empty()


func serialize() -> Dictionary:
	var contracts: Dictionary = {}
	for contract_id: int in contract_ids():
		contracts[str(contract_id)] = _contracts[contract_id].duplicate(true)
	return {KEY_CONTRACTS: contracts}


## Confere tudo antes de alterar o estado: tipo e estado conhecidos, emissor e aceitante como IDs positivos, recompensa 0 ou mais (só a vaga é 0), objetivo com as chaves e os tipos do tipo. Se algo for inválido, o livro fica como estava.
func load_from(data: Dictionary) -> Result:
	var raw_contracts: Variant = data.get(KEY_CONTRACTS)
	if typeof(raw_contracts) != TYPE_DICTIONARY:
		return _invalid_save("campo '%s' ausente ou não é um objeto" % KEY_CONTRACTS)
	var contracts: Dictionary[int, Dictionary] = {}
	var raw_table: Dictionary = raw_contracts
	for key: Variant in raw_table.keys():
		var contract_id: int = EconomyJson.id_of_key(key)
		var parsed: Variant = _parse_contract(contract_id, raw_table[key])
		if typeof(parsed) == TYPE_STRING:
			return _invalid_save("contrato '%s': %s" % [str(key), str(parsed)])
		contracts[contract_id] = parsed
	_contracts = contracts
	return Result.success()


## Invariantes: o contrato com recompensa tem a conta de custódia, e ela guarda a recompensa inteira enquanto o contrato está aberto ou aceito e NADA depois (a custódia nunca fica retida).
func validate() -> Array[String]:
	var problems: Array[String] = []
	for contract_id: int in contract_ids():
		var state: Dictionary = _contracts[contract_id]
		if int(state[KEY_REWARD]) == 0:
			continue
		if not _book.has_owner(contract_id) or _book.kind_of(contract_id) != KIND_OWNER:
			problems.append("o contrato %d tem recompensa mas não tem a conta de custódia do tipo '%s'" % [contract_id, KIND_OWNER])
			continue
		var held: bool = state[KEY_STATE] == STATE_OPEN or state[KEY_STATE] == STATE_ACCEPTED
		var expected: int = int(state[KEY_REWARD]) if held else 0
		var retained_by_dead_issuer: bool = not held and _book.is_closed(int(state[KEY_ISSUER])) and _ledger.balance_of(contract_id) == int(state[KEY_REWARD])
		if _ledger.balance_of(contract_id) != expected and not retained_by_dead_issuer:
			problems.append("o contrato %d (%s) deveria ter %d na custódia e tem %d" % [contract_id, state[KEY_STATE], expected, _ledger.balance_of(contract_id)])
	return problems


## Texto do problema do objetivo, ou vazio se é possível: `labor` pede um local de trabalho que a economia conhece e minutos de 1 ou mais; `delivery`, um bem que existe, quantidade de 1 ou mais e um destino aberto.
func _objective_problem(kind: String, objective: Dictionary) -> String:
	var keys: Array[String] = _objective_keys(kind)
	for key: String in keys:
		if not objective.has(key):
			return "o objetivo não tem '%s'; esperado %s" % [key, ", ".join(keys)]
	if kind == LABOR:
		if typeof(objective[KEY_PLACE]) != TYPE_STRING or not _is_work_place(str(objective[KEY_PLACE])):
			return "o local '%s' não é um local de trabalho da economia" % str(objective[KEY_PLACE])
		if typeof(objective[KEY_MINUTES]) != TYPE_INT or int(objective[KEY_MINUTES]) < 1:
			return "os minutos devem ser um inteiro de 1 ou mais"
		return ""
	if typeof(objective[KEY_GOOD]) != TYPE_STRING or not _goods.has_good(str(objective[KEY_GOOD])):
		return "o bem '%s' não existe" % str(objective[KEY_GOOD])
	if typeof(objective[KEY_QUANTITY]) != TYPE_INT or int(objective[KEY_QUANTITY]) < 1:
		return "a quantidade deve ser um inteiro de 1 ou mais"
	if typeof(objective[KEY_DESTINATION]) != TYPE_INT or not _book.check_open(int(objective[KEY_DESTINATION])).ok:
		return "o destino %s não é um dono aberto" % str(objective[KEY_DESTINATION])
	return ""


## Paga a custódia ao aceitante (`contract_payout`) e marca o contrato `completed`. Só depois de conferido que o pagamento cabe.
func _complete(contract_id: int) -> Outcome:
	var state: Dictionary = _contracts[contract_id]
	var paid: Result = _ledger.transfer(contract_id, state[KEY_ACCEPTOR], int(state[KEY_REWARD]), Ledger.REASON_CONTRACT_PAYOUT)
	var outcome: Outcome = Outcome.new()
	outcome.result = paid
	if not paid.ok:
		return outcome
	state[KEY_STATE] = STATE_COMPLETED
	outcome.contract_id = contract_id
	outcome.completed = true
	outcome.acceptor_id = state[KEY_ACCEPTOR]
	outcome.reward = state[KEY_REWARD]
	return outcome


## O trabalhador está atribuído ao local de produção ou ao posto de `place_id`?
func _is_assigned_at(place_id: String, worker_id: int) -> bool:
	if _production != null:
		var site_id: int = _production.site_at(place_id)
		if site_id != IdGenerator.NO_ID and (_production.state_of(site_id)[ProductionBook.KEY_WORKERS] as Array).has(worker_id):
			return true
	if _posts != null:
		var post_id: int = _posts.post_at(place_id)
		if post_id != IdGenerator.NO_ID and (_posts.state_of(post_id)[ServicePostBook.KEY_WORKERS] as Array).has(worker_id):
			return true
	return false


## O menor ID de contrato `labor` aceito por `worker_id` em `place_id` (`IdGenerator.NO_ID` se nenhum).
func _accepted_labor_of(worker_id: int, place_id: String) -> int:
	for contract_id: int in contract_ids():
		var state: Dictionary = _contracts[contract_id]
		if state[KEY_KIND] == LABOR and state[KEY_STATE] == STATE_ACCEPTED and state[KEY_ACCEPTOR] == worker_id and state[KEY_PLACE] == place_id:
			return contract_id
	return IdGenerator.NO_ID


## As chaves do objetivo do tipo (a vaga não tem objetivo próprio aqui: o local de trabalho é dela).
func _objective_keys(kind: String) -> Array[String]:
	if kind == LABOR:
		return OBJECTIVE_LABOR
	if kind == DELIVERY:
		return OBJECTIVE_DELIVERY
	return OBJECTIVE_VACANCY


func _is_work_place(place_id: String) -> bool:
	return (_production != null and _production.site_at(place_id) != IdGenerator.NO_ID) or (_posts != null and _posts.post_at(place_id) != IdGenerator.NO_ID)


## Devolve o estado montado, ou o TEXTO do problema (o chamador o prefixa com o contrato).
func _parse_contract(contract_id: int, raw_entry: Variant) -> Variant:
	if contract_id < IdGenerator.FIRST_ID or typeof(raw_entry) != TYPE_DICTIONARY:
		return "esperado um ID positivo e um objeto"
	var entry: Dictionary = raw_entry
	var kind: Variant = entry.get(KEY_KIND)
	var state_name: Variant = entry.get(KEY_STATE)
	if typeof(kind) != TYPE_STRING or not CONTRACT_TYPES.has(str(kind)) or typeof(state_name) != TYPE_STRING or not STATES.has(str(state_name)):
		return "'%s' deve ser um de %s e '%s' um de %s" % [KEY_KIND, ", ".join(CONTRACT_TYPES), KEY_STATE, ", ".join(STATES)]
	for field: String in [KEY_ISSUER, KEY_REWARD, KEY_DEADLINE, KEY_ACCEPTOR]:
		if not EconomyJson.is_int_like(entry.get(field)):
			return "'%s' deve ser um inteiro" % field
	var issuer: int = EconomyJson.to_int(entry[KEY_ISSUER])
	var reward: int = EconomyJson.to_int(entry[KEY_REWARD])
	var deadline: int = EconomyJson.to_int(entry[KEY_DEADLINE])
	var acceptor: int = EconomyJson.to_int(entry[KEY_ACCEPTOR])
	if issuer < IdGenerator.FIRST_ID or reward < 0 or deadline < 0 or (acceptor != IdGenerator.NO_ID and acceptor < IdGenerator.FIRST_ID):
		return "'%s' deve ser um ID positivo, '%s' e '%s' 0 ou mais e '%s' um ID positivo ou %d" % [KEY_ISSUER, KEY_REWARD, KEY_DEADLINE, KEY_ACCEPTOR, IdGenerator.NO_ID]
	if kind == VACANCY and (reward != 0 or deadline != 0):
		return "a vaga tem '%s' e '%s' 0 (sem recompensa e sem prazo)" % [KEY_REWARD, KEY_DEADLINE]
	var state: Dictionary = {KEY_KIND: str(kind), KEY_ISSUER: issuer, KEY_REWARD: reward, KEY_DEADLINE: deadline, KEY_STATE: str(state_name), KEY_ACCEPTOR: acceptor}
	if kind == LABOR:
		if not EconomyJson.is_int_like(entry.get(KEY_WORKED)) or EconomyJson.to_int(entry[KEY_WORKED]) < 0:
			return "'%s' deve ser um inteiro de 0 ou mais" % KEY_WORKED
		state[KEY_WORKED] = EconomyJson.to_int(entry[KEY_WORKED])
	for key: String in _objective_keys(str(kind)):
		var value: Variant = entry.get(key)
		var wants_text: bool = key == KEY_PLACE or key == KEY_GOOD
		if key == KEY_WORKPLACE and (not EconomyJson.is_int_like(value) or EconomyJson.to_int(value) < IdGenerator.FIRST_ID):
			return "'%s' deve ser um ID positivo" % key
		if wants_text and (typeof(value) != TYPE_STRING or str(value).is_empty()):
			return "'%s' deve ser texto não vazio" % key
		if not wants_text and not EconomyJson.is_int_like(value):
			return "'%s' deve ser um inteiro" % key
		if wants_text:
			state[key] = str(value)
		else:
			state[key] = EconomyJson.to_int(value)
	return state


func _invalid_save(detail: String) -> Result:
	return Result.failure(EconomyCodes.INVALID_SAVE, "ContractBook.load_from: %s." % detail)
