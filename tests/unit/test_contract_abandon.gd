extends GutTest
## LW-107f1: abandonar uma encomenda NA ECONOMIA (docs/modules/economy.md, seção 8, itens (a), (b), (d) e (g); DEC-238, D2 e D3): o aceitante larga o `delivery` ANTES do prazo e a custódia volta ao emissor (ou ao mercado do povoado do destino, se ele morreu; sem povoado conhecido fica retida [LIM]);
## o contrato vira `failed` com o `closed_reason` `abandoned` (campo OPCIONAL, AUSENTE em todo contrato que não foi abandonado), sem multa e sem mexer em bens, saldos de terceiros nem IDs. Cobre os critérios do D3 (distinguível, sobrevive ao save, save antigo igual, custódia, conservação, sem penalidade),
## as recusas na ordem do contrato, o evento, o `expire` e a validação do `closed_reason` no save (pelo `EconomyModule.on_load`, o caminho do save de verdade). Economia REAL (data/economy, 3 povoados) sem locais de produção e com um único posto de `guard` em `a_work_05` (montado à mão, para a vaga ter um local só) e NPCs reais (saldo inicial 60); o relógio anda minuto a minuto.

const SEED: int = 1071
const MODULE: String = "economy"
const MINUTES_PER_HOUR: int = 60
const SETTLEMENT_A: String = "test_settlement_a"
const SETTLEMENT_B: String = "test_settlement_b"
const PLACE_POST: String = "a_work_05"
const GOOD: String = "grain"
const ISSUER: int = 100
const ACTOR: int = 101
const OTHER: int = 102
const GUARD: int = 103
const NO_SUCH_CONTRACT: int = 999999
const REWARD: int = 25
const QUANTITY: int = 3
const LONG_DEADLINE: int = 1000
const SHORT_DEADLINE: int = 90
const NPC_START_MONEY: int = 60
## O texto do contrato (item (b)): o único valor do `closed_reason` e o `reason` do `ContractFailed`.
const ABANDONED: String = "abandoned"
## O contrato dos livros sem mundo (`Rig`).
const BOOK_CONTRACT: int = 200


class Scene:
	extends RefCounted

	var world: World
	var economy: EconomyModule
	var market_a: int = IdGenerator.NO_ID
	var market_b: int = IdGenerator.NO_ID
	var failed: Array[ContractFailed] = []


## Os livros sem mundo (só o `OwnerBook`, o `Ledger` e o `ContractBook`), para o que o módulo não alcança: o `Ledger` recusando a devolução e a custódia já vazia. O `BOOK_CONTRACT` está aceito pelo ACTOR.
class Rig:
	extends RefCounted

	var owners: OwnerBook
	var ledger: Ledger
	var contracts: ContractBook


## `new_game` falso monta o mundo só para receber um save. Com jogo novo: os NPCs ISSUER e OTHER e o jogador ACTOR têm conta.
func _scene(new_game: bool = true) -> Scene:
	var setup: EconomySetup = EconomySetup.from_dir(EconomySetup.DEFAULT_DIR)
	assert_true(setup.result.ok, setup.result.message)
	var no_sites: Array[SiteDef] = []
	setup.definitions.production_sites = no_sites
	var posts: Array[PostDef] = [PostDef.new("post_a_guard", SETTLEMENT_A, PLACE_POST, "guard", 1, 3)]
	setup.definitions.service_posts = posts
	var scene: Scene = Scene.new()
	scene.economy = EconomyModule.new(false, setup.definitions)
	var clock: SimClock = SimClock.new()
	scene.world = World.new(SimContext.new(clock, EventBus.new(clock), WorldRng.new(SEED), IdGenerator.new()))
	assert_true(scene.world.register_module(MODULE, scene.economy).ok)
	scene.world.setup()
	scene.world.post_setup()
	var failed: Array[ContractFailed] = scene.failed
	scene.world.context.events.subscribe("ContractFailed", func(event: SimEvent) -> void: failed.append(event))
	if new_game:
		scene.world.on_new_game(SEED)
		for npc_id: int in [ISSUER, OTHER]:
			assert_true(scene.economy.request_open_owner(npc_id, "npc").ok)
		assert_true(scene.economy.request_open_owner(ACTOR, "player").ok)
		scene.market_a = scene.economy.peek_market_of(SETTLEMENT_A).market_id
		scene.market_b = scene.economy.peek_market_of(SETTLEMENT_B).market_id
	return scene


func _run_minutes(scene: Scene, minutes: int) -> void:
	for _minute: int in minutes:
		scene.world.context.clock.advance_step()
		scene.world.tick(1)
		scene.world.context.events.dispatch()


func _post(scene: Scene, issuer: int, destination: int, deadline: int = LONG_DEADLINE) -> int:
	var objective: Dictionary = {ContractBook.KEY_GOOD: GOOD, ContractBook.KEY_QUANTITY: QUANTITY, ContractBook.KEY_DESTINATION: destination}
	var posted: EconomyReplies.PostContractResult = scene.economy.request_post_contract(ContractBook.DELIVERY, issuer, REWARD, deadline, objective)
	assert_true(posted.result.ok, posted.result.message)
	return posted.contract_id


## Posta o `delivery` e o ACTOR o aceita.
func _accepted(scene: Scene, issuer: int, destination: int, deadline: int = LONG_DEADLINE) -> int:
	var contract_id: int = _post(scene, issuer, destination, deadline)
	assert_true(scene.economy.request_accept_contract(contract_id, ACTOR).ok)
	return contract_id


## Um contrato em cada fim possível, do mercado A para o B, até o minuto 120: aberto, aceito, concluído, vencido, abandonado, o `labor` aceito e a vaga do posto que falhou (o guarda foi contratado). Devolve os IDs pelo nome.
func _endings(scene: Scene) -> Dictionary:
	var ids: Dictionary = {}
	ids["open"] = _post(scene, scene.market_a, scene.market_b)
	ids["accepted"] = _accepted(scene, scene.market_a, scene.market_b)
	ids["completed"] = _accepted(scene, scene.market_a, scene.market_b)
	ids["expired"] = _accepted(scene, scene.market_a, scene.market_b, SHORT_DEADLINE)
	ids["abandoned"] = _accepted(scene, scene.market_a, scene.market_b)
	var labor: EconomyReplies.PostContractResult = scene.economy.request_post_contract(ContractBook.LABOR, scene.market_a, REWARD, LONG_DEADLINE, {ContractBook.KEY_PLACE: PLACE_POST, ContractBook.KEY_MINUTES: 30})
	assert_true(labor.result.ok and scene.economy.request_accept_contract(labor.contract_id, ACTOR).ok, labor.result.message)
	ids["labor"] = labor.contract_id
	assert_true(scene.economy.request_transfer_goods(scene.market_a, ACTOR, GOOD, QUANTITY).ok)
	assert_true(scene.economy.request_deliver_contract(ids["completed"]).ok)
	assert_true(scene.economy.request_abandon_contract(ids["abandoned"], ACTOR).ok)
	_run_minutes(scene, MINUTES_PER_HOUR)
	ids["vacancy"] = _vacancy_at(scene.economy, PLACE_POST)
	assert_ne(ids["vacancy"], IdGenerator.NO_ID, "A vaga do posto nasce na primeira hora.")
	assert_true(scene.economy.request_open_owner(GUARD, "npc", PLACE_POST).ok)
	_run_minutes(scene, MINUTES_PER_HOUR)
	return ids


func _vacancy_at(economy: EconomyModule, place_id: String) -> int:
	for row: EconomyReplies.ContractQuery in economy.peek_contracts("", IdGenerator.NO_ID, place_id).contracts:
		if row.kind == ContractBook.VACANCY and row.state == ContractBook.STATE_OPEN:
			return row.contract_id
	return IdGenerator.NO_ID


func _balance(scene: Scene, owner_id: int) -> int:
	return scene.economy.peek_balance(owner_id).balance


func _held(economy: EconomyModule, owner_id: int) -> int:
	for row: Dictionary in economy.peek_inventory(owner_id).rows:
		if row["good_id"] == GOOD:
			return int(row["quantity"])
	return 0


## O dinheiro que o `Ledger` já moveu por motivo (0 se nunca houve).
func _moved(economy: EconomyModule, reason: String) -> int:
	for row: Dictionary in economy.peek_ledger_totals().rows:
		if row["reason"] == reason:
			return int(row["moved"])
	return 0


## Saldo e bens (o `GOOD`) de quem importa: o emissor, o jogador, o outro NPC, os dois mercados e a custódia.
func _books(scene: Scene, contract_id: int) -> Dictionary:
	var books: Dictionary = {}
	for owner_id: int in [ISSUER, ACTOR, OTHER, scene.market_a, scene.market_b, contract_id]:
		books[owner_id] = [_balance(scene, owner_id), _held(scene.economy, owner_id)]
	return books


## O que o abandono não pode mexer: as duas conservações (dinheiro: soma, criado e destruído; bens: as linhas) e os IDs gastos.
func _totals(scene: Scene) -> Array:
	var money: EconomyReplies.ConservationQuery = scene.economy.peek_conservation()
	return [money.sum, money.created, money.destroyed, scene.economy.peek_goods_conservation().rows, scene.world.context.ids.serialize()]


func _snapshot(scene: Scene) -> String:
	return JSON.stringify([scene.economy.serialize(), scene.world.context.ids.serialize()], "", true, true)


func _assert_books_close(scene: Scene) -> void:
	assert_true(scene.economy.peek_conservation().ok, "O dinheiro continua contado.")
	assert_true(scene.economy.peek_goods_conservation().ok, "Os bens continuam contados.")
	assert_eq(scene.economy.validate(), [] as Array[String], "Nenhum problema nos livros.")


func _kill_issuer(scene: Scene) -> void:
	scene.world.context.events.publish(NpcDied.new(ISSUER, "test", 0))
	scene.world.context.events.dispatch()


## O que um save de verdade faz com o bloco da economia: vai para JSON e volta (os inteiros voltam como `float`).
func _json(data: Dictionary) -> Dictionary:
	var parsed: Variant = JSON.parse_string(JSON.stringify(data))  # Variant: a fronteira com o JSON
	assert_eq(typeof(parsed), TYPE_DICTIONARY)
	return parsed


## O save do mundo com o bloco da economia ida e volta por JSON; o núcleo (relógio, sorteio, IDs) fica como está, porque a codificação dele é de outro módulo.
func _save_of(scene: Scene) -> Dictionary:
	var saved: Dictionary = scene.world.serialize()
	(saved[World.KEY_MODULES] as Dictionary)[MODULE] = _json(scene.economy.serialize())
	return saved


## O contrato dentro do bloco `economy` de um save (a mesma forma com ou sem JSON).
func _entry(block: Dictionary, contract_id: int) -> Dictionary:
	return (block[ContractBook.KEY_CONTRACTS] as Dictionary)[ContractBook.KEY_CONTRACTS][str(contract_id)]


func _rig() -> Rig:
	var loaded: GoodsLoader.LoadResult = GoodsLoader.load_dir(GoodsLoader.DEFAULT_DIR)
	assert_true(loaded.result.ok, loaded.result.message)
	var rig: Rig = Rig.new()
	rig.owners = OwnerBook.new()
	for owner_id: int in [ISSUER, ACTOR, OTHER]:
		assert_true(rig.owners.open_owner(owner_id, "npc").ok)
	rig.ledger = Ledger.new(rig.owners)
	assert_true(rig.ledger.mint(ISSUER, REWARD, Ledger.REASON_GAME_START).ok)
	rig.contracts = ContractBook.new(rig.owners, rig.ledger, GoodsStore.new(rig.owners, loaded.goods, loaded.kinds), null, null)
	var objective: Dictionary = {ContractBook.KEY_GOOD: GOOD, ContractBook.KEY_QUANTITY: QUANTITY, ContractBook.KEY_DESTINATION: OTHER}
	assert_true(rig.contracts.post(BOOK_CONTRACT, ContractBook.DELIVERY, ISSUER, REWARD, SHORT_DEADLINE, 0, objective).ok)
	assert_true(rig.contracts.accept(BOOK_CONTRACT, ACTOR, 0).ok)
	return rig


func _books_snapshot(rig: Rig) -> String:
	return JSON.stringify([rig.owners.serialize(), rig.ledger.serialize(), rig.contracts.serialize()], "", true, true)


func test_abandoning_an_accepted_delivery_closes_it_as_failed_abandoned_and_the_custody_goes_back_to_the_issuer() -> void:
	var scene: Scene = _scene()
	var contract_id: int = _accepted(scene, ISSUER, scene.market_b)
	assert_eq([_balance(scene, ISSUER), _balance(scene, contract_id)], [NPC_START_MONEY - REWARD, REWARD], "Antes: a recompensa está na custódia.")
	var abandoned: Result = scene.economy.request_abandon_contract(contract_id, ACTOR)
	assert_true(abandoned.ok, abandoned.message)
	var row: EconomyReplies.ContractQuery = scene.economy.peek_contract(contract_id)
	assert_eq([row.state, row.closed_reason, row.acceptor_id], [ContractBook.STATE_FAILED, ABANDONED, ACTOR], "O estado vai a `failed`, o motivo é `abandoned` e o aceitante fica no contrato.")
	assert_eq([_balance(scene, ISSUER), _balance(scene, contract_id)], [NPC_START_MONEY, 0], "A custódia voltou inteira ao emissor.")
	_assert_books_close(scene)
	scene.world.teardown()


func test_the_query_tells_the_abandoned_apart_from_every_other_ending() -> void:
	var scene: Scene = _scene()
	var ids: Dictionary = _endings(scene)
	var expected: Dictionary = {
		"open": [ContractBook.STATE_OPEN, ""],
		"accepted": [ContractBook.STATE_ACCEPTED, ""],
		"completed": [ContractBook.STATE_COMPLETED, ""],
		"expired": [ContractBook.STATE_EXPIRED, ""],
		"labor": [ContractBook.STATE_ACCEPTED, ""],
		"vacancy": [ContractBook.STATE_FAILED, ""],
		"abandoned": [ContractBook.STATE_FAILED, ABANDONED],
	}
	for ending: String in expected:
		var row: EconomyReplies.ContractQuery = scene.economy.peek_contract(ids[ending])
		assert_eq([row.state, row.closed_reason], expected[ending], "Fim '%s': estado e `closed_reason` (vazio fora do abandono)." % ending)
	var listed: Dictionary = {}
	for row: EconomyReplies.ContractQuery in scene.economy.peek_contracts(ContractBook.STATE_FAILED).contracts:
		listed[row.contract_id] = row.closed_reason
	assert_eq(listed, {ids["abandoned"]: ABANDONED, ids["vacancy"]: ""}, "`peek_contracts` também leva o campo: o abandonado e a vaga cancelada se distinguem.")
	scene.world.teardown()


func test_the_abandoned_ending_survives_saving_and_loading_with_the_same_state_hash() -> void:
	var scene: Scene = _scene()
	var contract_id: int = _accepted(scene, ISSUER, scene.market_b)
	assert_true(scene.economy.request_abandon_contract(contract_id, ACTOR).ok)
	scene.world.context.events.dispatch()
	assert_eq(_entry(scene.economy.serialize(), contract_id).get(ContractBook.KEY_CLOSED_REASON), ABANDONED, "O save leva o motivo como texto.")
	var loaded: Scene = _scene(false)
	var result: Result = loaded.world.on_load(_save_of(scene))
	assert_true(result.ok, result.message)
	var row: EconomyReplies.ContractQuery = loaded.economy.peek_contract(contract_id)
	assert_eq([row.state, row.closed_reason, row.acceptor_id, _balance(loaded, contract_id), _balance(loaded, ISSUER)], [ContractBook.STATE_FAILED, ABANDONED, ACTOR, 0, NPC_START_MONEY], "Estado, motivo, aceitante e custódia sobrevivem.")
	assert_eq(loaded.world.state_hash(), scene.world.state_hash(), "O `state_hash` do mundo carregado é o do salvo.")
	_assert_books_close(loaded)
	scene.world.teardown()
	loaded.world.teardown()


func test_contracts_not_abandoned_serialize_without_the_key_and_a_save_without_it_loads_the_same() -> void:
	var scene: Scene = _scene()
	var ids: Dictionary = _endings(scene)
	var saved: Dictionary = _json(scene.economy.serialize())
	for ending: String in ids:
		assert_eq(_entry(saved, ids[ending]).has(ContractBook.KEY_CLOSED_REASON), ending == "abandoned", "A chave só existe no abandonado (nunca vazia nos outros): %s." % ending)
	var old: Dictionary = saved.duplicate(true)
	_entry(old, ids["abandoned"]).erase(ContractBook.KEY_CLOSED_REASON)
	var without_key: Scene = _scene(false)
	assert_true(without_key.economy.on_load(old).ok, "Um save sem a chave, isto é, todo save anterior, carrega.")
	var row: EconomyReplies.ContractQuery = without_key.economy.peek_contract(ids["abandoned"])
	assert_eq([row.state, row.closed_reason], [ContractBook.STATE_FAILED, ""], "Sem a chave é a falha sem motivo: `closed_reason` vazio.")
	assert_eq(_json(without_key.economy.serialize()), old, "A ida e volta do save antigo é idêntica: a chave não aparece.")
	var with_key: Scene = _scene(false)
	assert_true(with_key.economy.on_load(saved).ok)
	assert_eq(_json(with_key.economy.serialize()), saved, "Com a chave a ida e volta também é idêntica.")
	for each: Scene in [scene, without_key, with_key]:
		each.world.teardown()


func test_with_the_issuer_dead_the_custody_goes_to_the_market_of_the_destination_settlement() -> void:
	var scene: Scene = _scene()
	var market_before: int = _balance(scene, scene.market_b)
	var contract_id: int = _accepted(scene, ISSUER, scene.market_b)
	_kill_issuer(scene)
	assert_true(scene.economy.request_abandon_contract(contract_id, ACTOR).ok)
	assert_eq([_balance(scene, contract_id), _balance(scene, scene.market_b)], [0, market_before + REWARD], "O destino é o mercado do povoado B: a recompensa fica lá (a mesma rotina do `expire`).")
	assert_eq([scene.economy.peek_contract(contract_id).state, _moved(scene.economy, Ledger.REASON_CONTRACT_REFUND)], [ContractBook.STATE_FAILED, REWARD], "Pelo motivo `contract_refund`.")
	_assert_books_close(scene)
	scene.world.teardown()


func test_with_the_issuer_dead_and_no_known_refuge_the_custody_stays_in_the_contract() -> void:
	var scene: Scene = _scene()
	var markets_before: Array[int] = [_balance(scene, scene.market_a), _balance(scene, scene.market_b)]
	var contract_id: int = _accepted(scene, ISSUER, OTHER)
	_kill_issuer(scene)
	assert_true(scene.economy.request_abandon_contract(contract_id, ACTOR).ok)
	var row: EconomyReplies.ContractQuery = scene.economy.peek_contract(contract_id)
	assert_eq([row.state, row.closed_reason, _balance(scene, contract_id)], [ContractBook.STATE_FAILED, ABANDONED, REWARD], "[LIM] O destino é um NPC: a economia não sabe o povoado e a recompensa fica retida na conta do contrato, como no `expire`.")
	assert_eq([_balance(scene, scene.market_a), _balance(scene, scene.market_b)], markets_before, "Nenhum mercado recebeu nada.")
	_assert_books_close(scene)
	scene.world.teardown()


func test_abandoning_moves_only_the_custody_back_and_nothing_else_changes() -> void:
	var scene: Scene = _scene()
	assert_true(scene.economy.request_transfer_goods(scene.market_a, ACTOR, GOOD, QUANTITY).ok)
	var contract_id: int = _accepted(scene, ISSUER, scene.market_b)
	var books: Dictionary = _books(scene, contract_id)
	var totals: Array = _totals(scene)
	assert_eq(books[ACTOR][1], QUANTITY, "O jogador guarda os bens até entregar.")
	assert_true(scene.economy.request_abandon_contract(contract_id, ACTOR).ok)
	books[ISSUER][0] += REWARD
	books[contract_id][0] -= REWARD
	assert_eq(_books(scene, contract_id), books, "Só o emissor (+recompensa) e a custódia (-recompensa) mudam: saldo e bens do jogador, o outro NPC e os mercados ficam iguais; nenhum bem se move.")
	assert_eq(_totals(scene), totals, "Nada nasce nem some (dinheiro e bens) e nenhum ID é gasto.")
	assert_eq([_moved(scene.economy, Ledger.REASON_CONTRACT_REFUND), _moved(scene.economy, Ledger.REASON_CONTRACT_PAYOUT)], [REWARD, 0], "UM `contract_refund` e nenhum `contract_payout`: nada é pago ao aceitante.")
	_assert_books_close(scene)
	scene.world.teardown()


func test_two_runs_of_the_same_abandon_give_the_same_state() -> void:
	var hashes: Array[String] = []
	for _run: int in 2:
		var scene: Scene = _scene()
		var contract_id: int = _accepted(scene, ISSUER, scene.market_b)
		_run_minutes(scene, 30)
		assert_true(scene.economy.request_abandon_contract(contract_id, ACTOR).ok)
		_run_minutes(scene, MINUTES_PER_HOUR)
		hashes.append(scene.world.state_hash())
		scene.world.teardown()
	assert_eq(hashes[0], hashes[1], "Sem sorte e com o relógio de quem chama: duas execuções dão o mesmo estado.")


func test_each_refusal_follows_the_contract_order_and_changes_and_publishes_nothing() -> void:
	var scene: Scene = _scene()
	var ids: Dictionary = _endings(scene)
	var cases: Array = [
		[NO_SUCH_CONTRACT, ACTOR, EconomyCodes.UNKNOWN_CONTRACT],
		[ids["labor"], ACTOR, EconomyCodes.CONTRACT_IMPOSSIBLE],
		[ids["vacancy"], ACTOR, EconomyCodes.CONTRACT_IMPOSSIBLE],
		[ids["open"], ACTOR, EconomyCodes.CONTRACT_NOT_OPEN],
		[ids["completed"], ACTOR, EconomyCodes.CONTRACT_NOT_OPEN],
		[ids["expired"], ACTOR, EconomyCodes.CONTRACT_NOT_OPEN],
		[ids["abandoned"], ACTOR, EconomyCodes.CONTRACT_NOT_OPEN],
		[ids["completed"], OTHER, EconomyCodes.CONTRACT_NOT_OPEN],
		[ids["accepted"], OTHER, EconomyCodes.CONTRACT_IMPOSSIBLE],
		[ids["accepted"], scene.market_a, EconomyCodes.CONTRACT_IMPOSSIBLE],
	]
	var before: String = _snapshot(scene)
	var published: int = scene.failed.size()
	for refused: Array in cases:
		var contract_id: int = refused[0]
		var actor_id: int = refused[1]
		var code: String = refused[2]
		assert_eq(scene.economy.request_abandon_contract(contract_id, actor_id).code, code, "Recusa do contrato %d pelo ator %d." % [contract_id, actor_id])
	scene.world.context.events.dispatch()
	assert_eq([_snapshot(scene), scene.failed.size()], [before, published], "A recusa não muda nada, não gasta ID e não publica.")
	scene.world.teardown()


func test_the_deadline_minute_is_refused_and_a_late_contract_ends_expired_not_abandoned() -> void:
	var scene: Scene = _scene()
	var early: int = _accepted(scene, scene.market_a, scene.market_b, SHORT_DEADLINE)
	var exact: int = _accepted(scene, scene.market_a, scene.market_b, SHORT_DEADLINE)
	var late: int = _accepted(scene, scene.market_a, scene.market_b, SHORT_DEADLINE)
	_run_minutes(scene, SHORT_DEADLINE - 1)
	assert_true(scene.economy.request_abandon_contract(early, ACTOR).ok, "Um minuto antes do prazo ainda se abandona.")
	_run_minutes(scene, 1)
	assert_eq(scene.economy.request_abandon_contract(exact, ACTOR).code, EconomyCodes.CONTRACT_IMPOSSIBLE, "No minuto exato do prazo, não.")
	_run_minutes(scene, 10)
	var past: Result = scene.economy.request_abandon_contract(late, ACTOR)
	assert_eq([past.code, past.message.contains("prazo")], [EconomyCodes.CONTRACT_IMPOSSIBLE, true], "Depois do prazo, não: " + past.message)
	var stranger: Result = scene.economy.request_abandon_contract(late, OTHER)
	assert_true(stranger.message.contains("aceitante"), "Outro ator depois do prazo: vale a recusa do aceitante, que vem antes: " + stranger.message)
	assert_eq([scene.economy.peek_contract(exact).state, scene.economy.peek_contract(late).state], [ContractBook.STATE_ACCEPTED, ContractBook.STATE_ACCEPTED], "Passado o prazo, o contrato segue aceito até a hora cheia.")
	_run_minutes(scene, 2 * MINUTES_PER_HOUR - scene.world.context.clock.total_minutes())
	var states: Array[String] = []
	var reasons: Array[String] = []
	for contract_id: int in [early, exact, late]:
		states.append(scene.economy.peek_contract(contract_id).state)
	for event: ContractFailed in scene.failed:
		reasons.append(event.reason)
	assert_eq([states, reasons], [[ContractBook.STATE_FAILED, ContractBook.STATE_EXPIRED, ContractBook.STATE_EXPIRED] as Array[String], [ABANDONED, ContractFailed.REASON_EXPIRED, ContractFailed.REASON_EXPIRED] as Array[String]], "O vencido termina `expired` na hora cheia, com o evento de sempre: nunca vira abandono.")
	scene.world.teardown()


func test_the_expire_hour_ignores_an_abandoned_contract_after_its_deadline() -> void:
	var scene: Scene = _scene()
	var contract_id: int = _accepted(scene, ISSUER, scene.market_b, SHORT_DEADLINE)
	_run_minutes(scene, 30)
	assert_true(scene.economy.request_abandon_contract(contract_id, ACTOR).ok)
	_run_minutes(scene, 3 * MINUTES_PER_HOUR)
	var row: EconomyReplies.ContractQuery = scene.economy.peek_contract(contract_id)
	assert_eq([row.state, row.closed_reason], [ContractBook.STATE_FAILED, ABANDONED], "O `expire` não toca o `failed`.")
	assert_eq([_balance(scene, ISSUER), _balance(scene, contract_id), _moved(scene.economy, Ledger.REASON_CONTRACT_REFUND), scene.failed.size()], [NPC_START_MONEY, 0, REWARD, 1], "Nada é devolvido nem publicado de novo.")
	_assert_books_close(scene)
	scene.world.teardown()


func test_a_successful_abandon_publishes_one_contract_failed_with_the_abandoned_reason() -> void:
	var scene: Scene = _scene()
	var contract_id: int = _accepted(scene, ISSUER, scene.market_b)
	assert_true(scene.economy.request_abandon_contract(contract_id, ACTOR).ok)
	scene.world.context.events.dispatch()
	assert_eq(scene.failed.size(), 1, "Sai UM `ContractFailed`.")
	assert_eq([scene.failed[0].contract_id, scene.failed[0].issuer_id, scene.failed[0].reason], [contract_id, ISSUER, ABANDONED], "O emissor é lido do contrato.")
	assert_eq([ContractFailed.REASON_ABANDONED, ContractBook.CLOSED_REASONS], [ABANDONED, [ABANDONED] as Array[String]], "O texto do evento é o do `closed_reason`, e o conjunto fechado só tem o abandono.")
	scene.world.teardown()


func test_without_a_clock_and_a_bus_the_abandon_is_refused() -> void:
	assert_eq(EconomyModule.new().request_abandon_contract(1, ACTOR).code, EconomyCodes.CONTRACT_IMPOSSIBLE, "Módulo fora do `World`: sem relógio nem barramento.")


func test_load_rejects_a_closed_reason_that_is_unknown_not_text_or_outside_a_failed_delivery_and_changes_nothing() -> void:
	var scene: Scene = _scene()
	var ids: Dictionary = _endings(scene)
	var saved: Dictionary = _json(scene.economy.serialize())
	var abandoned: int = ids["abandoned"]
	var bad_cases: Array = [
		[abandoned, {ContractBook.KEY_CLOSED_REASON: "failed_by_fault"}],
		[abandoned, {ContractBook.KEY_CLOSED_REASON: ""}],
		[abandoned, {ContractBook.KEY_CLOSED_REASON: 7}],
		[abandoned, {ContractBook.KEY_CLOSED_REASON: null}],
		[abandoned, {ContractBook.KEY_STATE: ContractBook.STATE_ACCEPTED}],
		[abandoned, {ContractBook.KEY_STATE: ContractBook.STATE_EXPIRED}],
		[abandoned, {ContractBook.KEY_ACCEPTOR: IdGenerator.NO_ID}],
		[ids["completed"], {ContractBook.KEY_CLOSED_REASON: ABANDONED}],
		[ids["labor"], {ContractBook.KEY_STATE: ContractBook.STATE_FAILED, ContractBook.KEY_CLOSED_REASON: ABANDONED}],
		[ids["vacancy"], {ContractBook.KEY_CLOSED_REASON: ABANDONED}],
	]
	for bad: Array in bad_cases:
		var block: Dictionary = saved.duplicate(true)
		var contract_id: int = bad[0]
		_entry(block, contract_id).merge(bad[1] as Dictionary, true)
		var fresh: Scene = _scene(false)
		var loaded: Result = fresh.economy.on_load(block)
		assert_eq(loaded.code, EconomyCodes.INVALID_SAVE, "O save com %s no contrato %d é recusado." % [str(bad[1]), contract_id])
		assert_true(loaded.message.contains(ContractBook.KEY_CLOSED_REASON), "A mensagem diz qual campo está errado: " + loaded.message)
		assert_eq(fresh.economy.serialize(), {}, "Recusado, o módulo fica como estava (vazio).")
		fresh.world.teardown()
	scene.world.teardown()


func test_when_the_ledger_refuses_the_refund_the_abandon_fails_and_changes_nothing() -> void:
	var rig: Rig = _rig()
	assert_true(rig.ledger.mint(ISSUER, Ledger.MAX_AMOUNT - REWARD + 1, Ledger.REASON_TRADE).ok, "O saldo do emissor fica a uma unidade do teto: a devolução o estouraria.")
	var before: String = _books_snapshot(rig)
	var refused: Result = rig.contracts.abandon(BOOK_CONTRACT, ACTOR, 0)
	assert_eq([refused.code, refused.message.begins_with("ContractBook.abandon: ")], [EconomyCodes.BAD_AMOUNT, true], "O código do `Ledger` sobe, com a mensagem do `abandon`: " + refused.message)
	assert_eq(_books_snapshot(rig), before, "Nada muda, byte a byte: livros, `Ledger` e contrato (segue `accepted`, sem `closed_reason`).")


func test_abandoning_a_contract_whose_custody_is_already_empty_succeeds_without_any_transfer() -> void:
	var rig: Rig = _rig()
	assert_true(rig.ledger.transfer(BOOK_CONTRACT, ISSUER, REWARD, Ledger.REASON_CONTRACT_REFUND).ok, "A custódia é esvaziada à mão (um jogo de verdade não a deixa assim, mas o livro tem de aguentar).")
	var ledger_before: Dictionary = rig.ledger.serialize()
	var abandoned: Result = rig.contracts.abandon(BOOK_CONTRACT, ACTOR, 0)
	assert_true(abandoned.ok, abandoned.message)
	var state: Dictionary = rig.contracts.state_of(BOOK_CONTRACT)
	assert_eq([state[ContractBook.KEY_STATE], state[ContractBook.KEY_CLOSED_REASON]], [ContractBook.STATE_FAILED, ABANDONED], "Sem o que devolver, o contrato fecha do mesmo jeito.")
	assert_eq(rig.ledger.serialize(), ledger_before, "Nenhuma transferência, nem uma de valor 0: o `Ledger` não se mexe.")
	assert_eq(rig.contracts.validate(), [] as Array[String], "Nenhum problema no livro.")
