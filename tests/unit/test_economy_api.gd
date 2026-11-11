extends GutTest
## LW-088c: a porta do `EconomyModule` (`request_open_owner`, `peek_balance`, `peek_conservation`, `peek_ledger_totals`) e o bloco `economy` do save (docs/modules/economy.md, seções 2 e 10). O bloco só ganha
## conteúdo quando há dono ou movimento (sem isso continua `{}`, como na casca da LW-088a); o `on_load` confere tudo antes de trocar o estado. Valores esperados escritos à mão.

const MAX_ID: int = 9007199254740991


func _through_json(data: Dictionary) -> Dictionary:
	# Variant: o JSON devolve qualquer tipo; aqui o formato é conhecido (um objeto).
	var parsed: Variant = JSON.parse_string(JSON.stringify(data))
	assert_eq(typeof(parsed), TYPE_DICTIONARY)
	var copy: Dictionary = parsed
	return copy


func test_the_module_opens_owners_idempotently_and_answers_the_queries() -> void:
	var module: EconomyModule = EconomyModule.new()
	assert_eq(module.serialize(), {}, "Sem dono e sem movimento o bloco é vazio (o hash do jogo não muda).")
	assert_true(module.request_open_owner(5, "npc").ok)
	assert_true(module.request_open_owner(5, "npc").ok, "Abrir de novo é inofensivo.")
	assert_eq(module.request_open_owner(0, "npc").code, EconomyCodes.UNKNOWN_OWNER)
	assert_eq(module.request_open_owner(MAX_ID + 1, "npc").code, EconomyCodes.UNKNOWN_OWNER)
	assert_eq(module.request_open_owner(6, "").code, EconomyCodes.DATA_INVALID)
	var balance: EconomyReplies.BalanceQuery = module.peek_balance(5)
	assert_true(balance.result.ok)
	assert_eq(balance.balance, 0)
	assert_eq(module.peek_balance(6).result.code, EconomyCodes.UNKNOWN_OWNER, "O dono que não abriu não existe.")
	var conservation: EconomyReplies.ConservationQuery = module.peek_conservation()
	assert_eq([conservation.sum, conservation.created, conservation.destroyed, conservation.ok], [0, 0, 0, true])
	assert_eq(module.peek_ledger_totals().rows, [] as Array[Dictionary])
	assert_eq(module.serialize().keys(), [EconomyModule.KEY_OWNERS, EconomyModule.KEY_LEDGER], "Com um dono já há estado a guardar.")
	assert_eq(module.validate(), [] as Array[String])


func test_the_module_loads_a_full_block_through_json_and_refuses_a_broken_one() -> void:
	var book: OwnerBook = OwnerBook.new()
	for owner_id: int in range(1, 5):
		book.open_owner(owner_id, "npc")
	var ledger: Ledger = Ledger.new(book)
	ledger.mint(2, 300, Ledger.REASON_GAME_START)
	ledger.transfer(2, 3, 75, Ledger.REASON_TRADE)
	var block: Dictionary = _through_json({EconomyModule.KEY_OWNERS: book.serialize(), EconomyModule.KEY_LEDGER: ledger.serialize()})
	var module: EconomyModule = EconomyModule.new()
	var loaded: Result = module.on_load(block)
	assert_true(loaded.ok, loaded.message)
	assert_eq([module.peek_balance(2).balance, module.peek_balance(3).balance], [225, 75])
	var conservation: EconomyReplies.ConservationQuery = module.peek_conservation()
	assert_eq([conservation.sum, conservation.created, conservation.destroyed, conservation.ok], [300, 300, 0, true])
	assert_eq(module.peek_ledger_totals().rows, [{"reason": "game_start", "moved": 0, "created": 300, "destroyed": 0}, {"reason": "trade", "moved": 75, "created": 0, "destroyed": 0}] as Array[Dictionary])
	assert_eq(_through_json(module.serialize()), block, "Salvar o que foi carregado devolve o mesmo bloco.")
	var broken: Dictionary = block.duplicate(true)
	broken[EconomyModule.KEY_LEDGER][Ledger.KEY_CREATED] = {"game_start": 301}
	var refused: Result = module.on_load(broken)
	assert_eq(refused.code, EconomyCodes.INVALID_SAVE)
	assert_eq(module.peek_balance(2).balance, 225, "O módulo continua como estava depois da recusa.")
	var half: Dictionary = {EconomyModule.KEY_OWNERS: block[EconomyModule.KEY_OWNERS]}
	assert_eq(module.on_load(half).code, EconomyCodes.INVALID_SAVE, "Os dois campos precisam estar no bloco.")
	var unknown: Result = module.on_load({EconomyModule.KEY_OWNERS: {}, "extra": 1})
	assert_string_contains(unknown.message, "2 chave(s) (extra, owners)")
	assert_true(module.on_load({}).ok, "O bloco vazio volta ao estado inicial.")
	assert_eq(module.peek_balance(2).result.code, EconomyCodes.UNKNOWN_OWNER)
	assert_eq(module.serialize(), {})


func test_the_world_save_carries_the_economy_block_and_the_hash_follows_the_state() -> void:
	var clock: SimClock = SimClock.new()
	var world: World = World.new(SimContext.new(clock, EventBus.new(clock), WorldRng.new(3), IdGenerator.new()))
	var module: EconomyModule = EconomyModule.new()
	assert_true(world.register_module("economy", module).ok)
	world.setup()
	world.post_setup()
	world.on_new_game(3)
	var empty_hash: String = world.state_hash()
	assert_eq(world.serialize()["modules"]["economy"], {}, "Sem estado, o bloco é o mesmo da casca.")
	module.request_open_owner(7, "npc")
	assert_ne(world.state_hash(), empty_hash, "Um dono novo muda a impressão digital.")
	var data: Dictionary = _through_json(world.serialize())
	var clock_two: SimClock = SimClock.new()
	var other: World = World.new(SimContext.new(clock_two, EventBus.new(clock_two), WorldRng.new(3), IdGenerator.new()))
	var other_module: EconomyModule = EconomyModule.new()
	other.register_module("economy", other_module)
	other.setup()
	assert_true(other.on_load(data).ok)
	assert_eq(other.state_hash(), world.state_hash(), "Salvar e carregar não muda o hash.")
	assert_true(other_module.peek_balance(7).result.ok)
	assert_eq(world.validate(), [] as Array[String])
	world.teardown()
	other.teardown()
