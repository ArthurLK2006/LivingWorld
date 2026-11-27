extends GutTest
## LW-100c2 (docs/modules/economy.md, 9.16.6 e 9.16.8): o livro do `TradeFlow` na economia. T6, o save: a chave `trade_flow` só com o livro NÃO virgem, a ida e volta (lote `travelling`, lote `held` e resto de risco diferente de 0), o save inválido que falha ANTES de mudar qualquer coisa e as conferências cruzadas (dono-trânsito, mercados, bem e estoque = soma dos lotes), no `on_load` e no `validate()` com o prefixo
## `[trade_flow]`. T7, "desligado = nada muda": o livro virgem não muda o bloco `economy`, o `IdGenerator` nem o hash. Economia REAL (data/economy, 3 povoados). Nada abre o dono-trânsito sozinho (é da LW-100d1): o teste o abre por `request_open_owner`, põe os bens com `request_transfer_goods` e o livro entra pelo save.
## A rota contra o `world` NÃO é conferida aqui: a economia só a vê pela porta de rotas do módulo (LW-100d1), como a caravana (`CaravanRunner.route_problems`).

const SEED: int = 100
const HOLDER: int = 100
const ROUTE_A_B: String = "route_a_b"
const ROUTE_A_C: String = "route_a_c"
const ROUTE_B_C: String = "route_b_c"
## O tipo de dono sem inventário (capacidade 0) em `owner_kinds.json`.
const CONTRACT_KIND: String = "contract"
## T7: o SHA-256 dos bytes do bloco `economy` do jogo novo (dados reais, semente 100, só o módulo da economia), MEDIDO com o código de ANTES da LW-100c2 (sem o livro) em 27/11/2026: o livro virgem não muda um byte. Mudar de propósito os dados reais da economia muda este valor junto com os hashes de referência (DEC-175: só por ordem de Arthur).
const NEW_GAME_SHA256: String = "47f69c97c8ffea2d115ffd969579a9335fa6b9baa67140bdb7aa050a6cbbe008"
const NEW_GAME_KEYS: Array[String] = ["owners", "ledger", "goods", "markets", "production", "posts"]
## O jogo novo só com a economia gasta 23 IDs (3 mercados, 14 locais e 6 postos): o próximo é o 24 (sem vagas, que dependem de `places`).
const NEW_GAME_NEXT_ID: int = 24


func _definitions() -> EconomyDefinitions:
	var setup: EconomySetup = EconomySetup.from_dir(EconomySetup.DEFAULT_DIR)
	assert_true(setup.result.ok, setup.result.message)
	return setup.definitions


func _module() -> EconomyModule:
	return EconomyModule.new(false, _definitions())


func _through_json(data: Dictionary) -> Dictionary:
	# Variant: o JSON devolve qualquer tipo; aqui o formato é conhecido (um objeto).
	var parsed: Variant = JSON.parse_string(JSON.stringify(data))
	assert_eq(typeof(parsed), TYPE_DICTIONARY)
	var copy: Dictionary = parsed
	return copy


func _bytes(module: EconomyModule) -> String:
	return JSON.stringify(module.serialize(), "", true, true)


func _market(module: EconomyModule, letter: String) -> int:
	return module.peek_market_of("test_settlement_" + letter).market_id


func _lot(lot_id: int, route_id: String, origin: int, destination: int, good_id: String, quantity: int, state: String, departed_at: int, arrives_at: int, remaining: int) -> Dictionary:
	return {"lot_id": lot_id, "route_id": route_id, "origin_market_id": origin, "destination_market_id": destination, "good_id": good_id, "quantity": quantity, "state": state, "departed_at": departed_at, "arrives_at": arrives_at, "remaining_minutes": remaining}


## Os três lotes do cenário: pão 6 de A para C andando, pão 4 de A para B parado (`held`, faltam 60 min) e farinha 3 de B para C andando. O id 3 foi de um lote já entregue (o contador `next_lot_id` é 5).
func _lots(module: EconomyModule) -> Array:
	var a: int = _market(module, "a")
	var b: int = _market(module, "b")
	var c: int = _market(module, "c")
	return [_lot(1, ROUTE_A_C, a, c, "bread", 6, "travelling", 100, 224, 0), _lot(2, ROUTE_A_B, a, b, "bread", 4, "held", 40, 0, 60), _lot(4, ROUTE_B_C, b, c, "flour", 3, "travelling", 150, 274, 0)]


## A cópia dos lotes com `changes` por cima do lote de índice `index`.
func _changed(lots: Array, index: int, changes: Dictionary) -> Array:
	var copy: Array = lots.duplicate(true)
	(copy[index] as Dictionary).merge(changes, true)
	return copy


## O objeto `trade_flow` de partida (as três rotas, uma com resto 125 e outra com o limite 9999), com `changes` por cima dos campos de cima.
func _flow(module: EconomyModule, changes: Dictionary = {}) -> Dictionary:
	var flow: Dictionary = {"holder_id": HOLDER, "next_lot_id": 5, "routes": [{"route_id": ROUTE_A_B, "enabled": false, "risk_carry_bp": 125}, {"route_id": ROUTE_A_C, "enabled": true, "risk_carry_bp": 0}, {"route_id": ROUTE_B_C, "enabled": true, "risk_carry_bp": 9999}], "lots": _lots(module)}
	flow.merge(changes, true)
	return flow


## Os bytes do bloco `economy` e o hash do `World`, para provar que nada mudou.
func _snapshot(world: World, module: EconomyModule) -> Array[String]:
	return [_bytes(module), world.state_hash()]


## O save inteiro da economia com o objeto `trade_flow` dado, já passado pelo JSON.
func _with_flow(module: EconomyModule, flow: Dictionary) -> Dictionary:
	var block: Dictionary = module.serialize()
	block["trade_flow"] = flow
	return _through_json(block)


## Um jogo novo (os mercados A, B e C abertos): devolve o `World` e o módulo.
func _new_game() -> Array:
	var module: EconomyModule = _module()
	var clock: SimClock = SimClock.new()
	var world: World = World.new(SimContext.new(clock, EventBus.new(clock), WorldRng.new(SEED), IdGenerator.new()))
	assert_true(world.register_module("economy", module).ok)
	world.setup()
	world.post_setup()
	world.on_new_game(SEED)
	return [world, module]


## O jogo novo com o dono-trânsito (tipo `flow`) aberto e os bens dos lotes NELE (10 de pão e 3 de farinha, tirados dos mercados); com `with_book`, o livro entra pelo save.
func _scenario(with_book: bool) -> Array:
	var game: Array = _new_game()
	var module: EconomyModule = game[1]
	assert_true(module.request_open_owner(HOLDER, FlowBook.KIND_FLOW).ok)
	assert_true(module.request_transfer_goods(_market(module, "a"), HOLDER, "bread", 10).ok)
	assert_true(module.request_transfer_goods(_market(module, "b"), HOLDER, "flour", 3).ok)
	if with_book:
		assert_true(module.on_load(_with_flow(module, _flow(module))).ok)
	return game


func test_the_save_round_trips_a_travelling_lot_a_held_lot_and_a_carry_also_through_json() -> void:
	var first: Array = _scenario(true)
	var world: World = first[0]
	var module: EconomyModule = first[1]
	assert_eq(_bytes(module), _bytes(_scenario(true)[1]), "Os mesmos comandos dão os mesmos bytes.")
	assert_eq(module.serialize()["trade_flow"], _flow(module), "O save traz o livro como foi montado: dono-trânsito, contador, rotas (por id) e lotes (por id), com os dois estados e os restos 125 e 9999.")
	var restored: Array = _scenario(false)
	assert_true((restored[0] as World).on_load(_through_json(world.serialize())).ok)
	var loaded: EconomyModule = restored[1]
	assert_eq(_snapshot(restored[0], loaded), _snapshot(world, module), "Ida e volta pelo JSON: os mesmos bytes e o mesmo hash.")
	assert_eq([loaded.validate(), loaded.debug_summary()["flow_lots"]], [[] as Array[String], 3], "O livro carregado confere e o resumo de depuração conta os lotes.")


func test_a_save_without_the_key_loads_and_an_unknown_empty_or_misshaped_key_is_refused() -> void:
	var module: EconomyModule = _scenario(false)[1]
	var block: Dictionary = _through_json(module.serialize())
	assert_false(block.has("trade_flow"), "Livro virgem: o bloco não ganha a chave.")
	var restored: EconomyModule = _module()
	assert_true(restored.on_load(block).ok, "O save sem a chave `trade_flow` carrega (livro virgem).")
	assert_eq(_bytes(restored), _bytes(module))
	var unknown: Result = restored.on_load({"owners": {}, "ledger": {}, "extra": 1})
	assert_eq(unknown.code, EconomyCodes.INVALID_SAVE)
	assert_string_contains(unknown.message, "'caravans' e 'trade_flow'", "A mensagem lista a chave nova entre as aceitas.")
	# Variant: o valor cru que um save corrompido traria em `trade_flow` (objeto vazio, lista, número, objeto incompleto).
	for wrong: Variant in [{}, [], 3, {"holder_id": 0}]:
		var bad: Dictionary = _through_json(block)
		bad["trade_flow"] = wrong
		assert_eq(restored.on_load(bad).code, EconomyCodes.INVALID_SAVE, "`trade_flow` mal formado é recusado: %s." % str(wrong))
	assert_eq(_bytes(restored), _bytes(module), "Recusado, o módulo continua como estava.")


func test_each_invalid_save_fails_with_a_message_before_changing_anything() -> void:
	var scenario: Array = _scenario(true)
	var world: World = scenario[0]
	var module: EconomyModule = scenario[1]
	var a: int = _market(module, "a")
	var lots: Array = _lots(module)
	var extra: Array = lots + [_lot(5, ROUTE_A_C, a, _market(module, "c"), "wood", 2, "travelling", 100, 224, 0)]
	var cases: Array[Dictionary] = [
		{"label": "dono-trânsito que não existe", "flow": _flow(module, {"holder_id": 999}), "expect": "o dono-trânsito: o dono 999 não existe"},
		{"label": "dono-trânsito de outro tipo", "flow": _flow(module, {"holder_id": a}), "expect": "o dono-trânsito %d é do tipo 'market'; esperado 'flow'" % a},
		{"label": "linha de rota sem dono-trânsito", "flow": _flow(module, {"holder_id": 0, "lots": []}), "expect": "há linha de rota ou lote, mas 'holder_id' é 0"},
		{"label": "mercado de origem desconhecido", "flow": _flow(module, {"lots": _changed(lots, 0, {"origin_market_id": 999})}), "expect": "o lote 1: o mercado de origem 999 não existe"},
		{"label": "mercado de destino desconhecido", "flow": _flow(module, {"lots": _changed(lots, 0, {"destination_market_id": 998})}), "expect": "o lote 1: o mercado de destino 998 não existe"},
		{"label": "bem desconhecido", "flow": _flow(module, {"lots": _changed(lots, 0, {"good_id": "zzz"})}), "expect": "o lote 1: o bem 'zzz' não é negociado no mercado de origem %d" % a},
		{"label": "lote sem o bem no dono-trânsito", "flow": _flow(module, {"next_lot_id": 6, "lots": extra}), "expect": "o dono-trânsito tem 0 de 'wood' e os lotes somam 2"},
		{"label": "bem no dono-trânsito sem lote", "flow": _flow(module, {"lots": lots.slice(0, 2)}), "expect": "o dono-trânsito tem 3 de 'flour' e os lotes somam 0"},
		{"label": "soma dos lotes maior por UM", "flow": _flow(module, {"lots": _changed(lots, 0, {"quantity": 7})}), "expect": "o dono-trânsito tem 10 de 'bread' e os lotes somam 11"},
		{"label": "soma dos lotes menor por UM", "flow": _flow(module, {"lots": _changed(lots, 0, {"quantity": 5})}), "expect": "o dono-trânsito tem 10 de 'bread' e os lotes somam 9"},
		{"label": "lote de rota sem linha (conferência do livro)", "flow": _flow(module, {"lots": _changed(lots, 0, {"route_id": "route_x"})}), "expect": "o lote 1 é da rota 'route_x', que não tem linha"},
		{"label": "partida negativa", "flow": _flow(module, {"lots": _changed(lots, 1, {"departed_at": -1})}), "expect": "o lote 2: 'departed_at' é -1; esperado 0 ou mais"},
		{"label": "chegada negativa", "flow": _flow(module, {"lots": _changed(lots, 0, {"arrives_at": -5})}), "expect": "o lote 1: 'arrives_at' é -5; esperado 0 ou mais"},
		{"label": "origem igual ao destino", "flow": _flow(module, {"lots": _changed(lots, 0, {"destination_market_id": a})}), "expect": "o lote 1: a origem e o destino são o mesmo mercado (%d)" % a},
	]
	var closed: Dictionary = _with_flow(module, _flow(module))
	var owners: Dictionary = closed["owners"]
	(owners[str(HOLDER)] as Dictionary)["closed"] = true
	var saves: Array[Dictionary] = [closed]
	var expected: Array[String] = ["o dono-trânsito: o dono %d está fechado" % HOLDER]
	var labels: Array[String] = ["dono-trânsito fechado"]
	for test_case: Dictionary in cases:
		saves.append(_with_flow(module, test_case["flow"]))
		expected.append(str(test_case["expect"]))
		labels.append(str(test_case["label"]))
	var before: Array[String] = _snapshot(world, module)
	for index: int in saves.size():
		var result: Result = module.on_load(saves[index])
		assert_eq(result.code, EconomyCodes.INVALID_SAVE, labels[index])
		assert_string_contains(result.message, expected[index], labels[index])
		assert_eq(_snapshot(world, module), before, "%s: falhou antes de mudar qualquer coisa (bytes e hash iguais)." % labels[index])


func test_load_into_leaves_the_target_state_untouched_when_the_flow_check_fails_and_fills_it_when_all_passes() -> void:
	var module: EconomyModule = _scenario(false)[1]
	var target: EconomyState = EconomyState.create(_definitions(), NeutralTradeRules.new(), false)
	var refused: Result = EconomyPersistence.load_into(target, _with_flow(module, _flow(module, {"holder_id": 999})))
	assert_eq(refused.code, EconomyCodes.INVALID_SAVE)
	assert_eq([EconomyPersistence.serialize(target), target.book.is_empty(), target.flow.is_pristine()], [{}, true, true], "Recusado, o estado de destino segue vazio: nem os donos, nem o dinheiro, nem os bens foram trocados.")
	assert_true(EconomyPersistence.load_into(target, _with_flow(module, _flow(module))).ok)
	assert_eq([target.flow.lot_ids(), EconomyPersistence.validation_problems(target)], [[1, 2, 4] as Array[int], [] as Array[String]], "Aceito, o destino recebe os livros e o livro do fluxo confere.")


func test_validate_catches_a_lot_without_goods_and_goods_without_a_lot_with_the_prefix() -> void:
	var module: EconomyModule = _scenario(true)[1]
	assert_eq(module.validate(), [] as Array[String], "O cenário montado está limpo.")
	assert_true(module.request_transfer_goods(HOLDER, _market(module, "a"), "bread", 1).ok)
	assert_eq(module.validate(), ["[trade_flow] o dono-trânsito tem 9 de 'bread' e os lotes somam 10"] as Array[String], "Um pão saiu do dono-trânsito: os lotes dizem 10 e ele tem 9 (lote sem bem).")
	assert_true(module.request_transfer_goods(_market(module, "b"), HOLDER, "wool", 1).ok)
	assert_eq(module.validate(), ["[trade_flow] o dono-trânsito tem 9 de 'bread' e os lotes somam 10", "[trade_flow] o dono-trânsito tem 1 de 'wool' e os lotes somam 0"] as Array[String], "Um bem sem lote entra na lista, por bem em ordem.")


func test_the_flow_owner_kind_has_weight_5000_and_no_balance_and_weight_zero_means_carries_nothing() -> void:
	var module: EconomyModule = _scenario(false)[1]
	assert_eq([FlowBook.KIND_FLOW, module.peek_inventory(HOLDER).capacity, module.peek_balance(HOLDER).balance, module.peek_conservation().ok], ["flow", 5000, 0, true], "Peso 5000 e saldo 0 [HIP]; abrir o dono-trânsito não cria dinheiro.")
	assert_true(module.request_open_owner(HOLDER + 1, CONTRACT_KIND).ok)
	assert_eq(module.request_transfer_goods(_market(module, "a"), HOLDER + 1, "bread", 1).code, EconomyCodes.CAPACITY_EXCEEDED, "Peso 0 NÃO é sem limite (o tipo `contract` não carrega nada): por isso o dono-trânsito tem 5000.")


func test_without_a_populated_book_the_economy_is_exactly_the_same_as_before() -> void:
	var game: Array = _new_game()
	var world: World = game[0]
	var module: EconomyModule = game[1]
	var block: Dictionary = module.serialize()
	var keys: Array[String] = []
	keys.assign(block.keys())
	assert_eq(keys, NEW_GAME_KEYS, "As mesmas chaves, na mesma ordem, e nenhuma `trade_flow` (T7).")
	assert_eq(_bytes(module).sha256_text(), NEW_GAME_SHA256, "Os mesmos bytes de antes do livro (valor medido sem ele).")
	assert_eq(world.context.ids.next_id(), NEW_GAME_NEXT_ID, "O livro não gastou nenhum ID.")
	var owners: Dictionary = block["owners"]
	assert_false(owners.values().any(func(row: Dictionary) -> bool: return row["kind"] == FlowBook.KIND_FLOW), "Nenhum dono-trânsito foi aberto.")
	assert_eq([module.validate(), module.debug_summary().has("flow_lots")], [[] as Array[String], false], "`validate()` limpo e o resumo sem a chave nova.")


func test_populating_the_book_adds_the_key_and_changes_the_hash_and_nothing_else() -> void:
	var scenario: Array = _scenario(false)
	var world: World = scenario[0]
	var module: EconomyModule = scenario[1]
	var before: Dictionary = _through_json(module.serialize())
	var hash_before: String = world.state_hash()
	var ids_before: Dictionary = world.context.ids.serialize()
	assert_false(before.has("trade_flow"), "O dono-trânsito aberto e os bens movidos NÃO bastam: sem livro, sem chave.")
	assert_true(module.on_load(_with_flow(module, _flow(module))).ok)
	var after: Dictionary = _through_json(module.serialize())
	assert_true(after.has("trade_flow"), "Com o livro populado a chave aparece.")
	assert_ne(world.state_hash(), hash_before, "E o hash muda: a garantia vale só para 'nunca ligado'.")
	after.erase("trade_flow")
	assert_eq([after, world.context.ids.serialize()], [before, ids_before], "Só a chave nova muda: o resto do bloco é igual e o livro não gasta ID.")
