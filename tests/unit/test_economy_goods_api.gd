extends GutTest
## LW-089c: a porta do `EconomyModule` para os bens (`peek_inventory`, `peek_goods_conservation`, `request_transfer_goods`), o tipo de dono conferido contra as definições, o bloco `goods` do save e o fechamento do dono
## quando o `npc` publica `NpcDied` (docs/modules/economy.md, seções 3 e 10; DEC-146). Usa os bens e os tipos de dono REAIS (data/economy). Valores esperados escritos à mão.

const WORLD_SEED: int = 31
const NPC: int = 7
const MARKET: int = 8


func _definitions() -> EconomyDefinitions:
	var loaded: GoodsLoader.LoadResult = GoodsLoader.load_dir(GoodsLoader.DEFAULT_DIR)
	assert_true(loaded.result.ok, loaded.result.message)
	return EconomyDefinitions.new(loaded.goods, loaded.kinds)


func _through_json(data: Dictionary) -> Dictionary:
	# Variant: o JSON devolve qualquer tipo; aqui o formato é conhecido (um objeto).
	var parsed: Variant = JSON.parse_string(JSON.stringify(data))
	assert_eq(typeof(parsed), TYPE_DICTIONARY)
	var copy: Dictionary = parsed
	return copy


## Um bloco `economy` com um NPC (dono 7) e um mercado (dono 8), dinheiro e pão no mercado, montado pelas peças soltas (a porta não cria dinheiro nem bem).
func _block() -> Dictionary:
	var definitions: EconomyDefinitions = _definitions()
	var book: OwnerBook = OwnerBook.new()
	book.open_owner(NPC, "npc")
	book.open_owner(MARKET, "market")
	var ledger: Ledger = Ledger.new(book)
	ledger.mint(NPC, 60, Ledger.REASON_GAME_START)
	var store: GoodsStore = GoodsStore.new(book, definitions.goods, definitions.kinds)
	store.create(MARKET, "bread", 40, GoodsStore.REASON_GAME_START)
	store.create(MARKET, "plank", 12, GoodsStore.REASON_PRODUCED)
	store.transfer(MARKET, NPC, "bread", 4)
	return _through_json({EconomyModule.KEY_OWNERS: book.serialize(), EconomyModule.KEY_LEDGER: ledger.serialize(), EconomyModule.KEY_GOODS: store.serialize()})


func _world(module: EconomyModule) -> World:
	var clock: SimClock = SimClock.new()
	var world: World = World.new(SimContext.new(clock, EventBus.new(clock), WorldRng.new(WORLD_SEED), IdGenerator.new()))
	assert_true(world.register_module("economy", module).ok)
	world.setup()
	world.post_setup()
	world.on_new_game(WORLD_SEED)
	return world


func test_the_owner_kind_is_checked_against_the_definitions_when_there_are_some() -> void:
	var module: EconomyModule = EconomyModule.new(false, _definitions())
	assert_true(module.request_open_owner(1, "npc").ok)
	var unknown: Result = module.request_open_owner(2, "wizard")
	assert_eq(unknown.code, EconomyCodes.DATA_INVALID)
	assert_string_contains(unknown.message, "o tipo de dono 'wizard' não existe; esperado um de: npc, player, site, market, contract")
	assert_eq(module.peek_balance(2).result.code, EconomyCodes.UNKNOWN_OWNER, "O pedido recusado não abre nada.")
	var without: EconomyModule = EconomyModule.new()
	assert_true(without.request_open_owner(2, "wizard").ok, "Sem definições qualquer tipo é aceito (a casca da LW-088).")
	assert_eq(without.request_transfer_goods(1, 2, "bread", 1).code, EconomyCodes.UNKNOWN_GOOD, "E nenhum bem existe.")


func test_the_inventory_queries_and_the_transfer_command_through_the_module() -> void:
	var module: EconomyModule = EconomyModule.new(false, _definitions())
	assert_true(module.on_load(_block()).ok)
	var market: EconomyReplies.InventoryQuery = module.peek_inventory(MARKET)
	assert_true(market.result.ok)
	assert_eq(market.rows, [{"good_id": "bread", "quantity": 36}, {"good_id": "plank", "quantity": 12}] as Array[Dictionary])
	assert_eq([market.weight, market.capacity], [36 + 12 * 4, 5000], "Peso: pão 1 e tábua 4; capacidade do tipo mercado.")
	assert_eq(module.peek_inventory(NPC).rows, [{"good_id": "bread", "quantity": 4}] as Array[Dictionary])
	assert_eq(module.peek_inventory(99).result.code, EconomyCodes.UNKNOWN_OWNER)
	var before: Dictionary = module.serialize()
	assert_eq(module.request_transfer_goods(MARKET, NPC, "gold", 1).code, EconomyCodes.UNKNOWN_GOOD)
	assert_eq(module.request_transfer_goods(MARKET, NPC, "bread", 0).code, EconomyCodes.BAD_QUANTITY)
	assert_eq(module.request_transfer_goods(NPC, MARKET, "bread", 5).code, EconomyCodes.INSUFFICIENT_GOODS)
	assert_eq(module.request_transfer_goods(MARKET, NPC, "plank", 10).code, EconomyCodes.CAPACITY_EXCEEDED, "O NPC carrega até 40 de peso: 4 + 10 × 4 não cabe.")
	assert_eq(module.request_transfer_goods(MARKET, 99, "bread", 1).code, EconomyCodes.UNKNOWN_OWNER)
	assert_eq(module.serialize(), before, "Nenhuma falha muda nada.")
	assert_true(module.request_transfer_goods(MARKET, NPC, "plank", 3).ok)
	assert_eq([module.peek_inventory(NPC).weight, module.peek_inventory(MARKET).weight], [4 + 12, 36 + 36])
	var conservation: EconomyReplies.GoodsConservationQuery = module.peek_goods_conservation()
	assert_true(conservation.ok)
	assert_eq(conservation.rows, [{"good_id": "bread", "in_stock": 40, "created": 40, "destroyed": 0, "ok": true}, {"good_id": "plank", "in_stock": 12, "created": 12, "destroyed": 0, "ok": true}] as Array[Dictionary])
	assert_eq(module.validate(), [] as Array[String])


func test_the_block_carries_goods_only_when_there_are_goods_and_round_trips_through_json() -> void:
	var module: EconomyModule = EconomyModule.new(false, _definitions())
	module.request_open_owner(NPC, "npc")
	assert_eq(module.serialize().keys(), [EconomyModule.KEY_OWNERS, EconomyModule.KEY_LEDGER], "Sem bem nenhum, o bloco é o da LW-088c.")
	var block: Dictionary = _block()
	assert_true(module.on_load(block).ok)
	assert_eq(_through_json(module.serialize()), block, "Salvar o que foi carregado devolve o mesmo bloco, com os bens.")
	var broken: Dictionary = block.duplicate(true)
	broken[EconomyModule.KEY_GOODS][GoodsStore.KEY_CREATED] = {"bread": {"game_start": 99}}
	var refused: Result = module.on_load(broken)
	assert_eq(refused.code, EconomyCodes.INVALID_SAVE)
	assert_string_contains(refused.message, "a conservação do bem 'bread' não fecha")
	assert_eq(module.peek_inventory(MARKET).rows.size(), 2, "O módulo continua como estava depois da recusa.")
	assert_eq(module.on_load({EconomyModule.KEY_OWNERS: {}, EconomyModule.KEY_LEDGER: {}, EconomyModule.KEY_GOODS: 3}).code, EconomyCodes.INVALID_SAVE, "`goods` que não é objeto é recusado.")


func test_a_dead_npc_is_closed_by_the_event_and_keeps_money_and_goods_in_the_sum() -> void:
	var module: EconomyModule = EconomyModule.new(false, _definitions())
	assert_true(module.on_load(_block()).ok)
	var world: World = _world(module)
	var events: EventBus = world.context.events
	events.publish(NpcDied.new(99, "hunger", 1))
	events.publish(NpcDied.new(MARKET, "hunger", 1))
	events.dispatch()
	assert_true(module.request_transfer_goods(MARKET, NPC, "bread", 1).ok, "NPC que nunca abriu conta e dono de outro tipo não são fechados.")
	events.publish(NpcDied.new(NPC, "hunger", 1))
	events.dispatch()
	assert_eq(module.request_transfer_goods(NPC, MARKET, "bread", 1).code, EconomyCodes.OWNER_CLOSED, "O NPC morto não aceita mais operação.")
	assert_eq(module.request_transfer_goods(MARKET, NPC, "bread", 1).code, EconomyCodes.OWNER_CLOSED)
	assert_eq([module.peek_balance(NPC).balance, module.peek_inventory(NPC).rows], [60, [{"good_id": "bread", "quantity": 5}] as Array[Dictionary]], "O saldo e os bens continuam consultáveis.")
	assert_true(module.peek_conservation().ok and module.peek_goods_conservation().ok, "E continuam na soma da conservação.")
	assert_eq(module.validate(), [] as Array[String])
	var data: Dictionary = _through_json(world.serialize())
	var restored_module: EconomyModule = EconomyModule.new(false, _definitions())
	var restored: World = _world(restored_module)
	assert_true(restored.on_load(data).ok)
	assert_eq(restored_module.request_transfer_goods(NPC, MARKET, "bread", 1).code, EconomyCodes.OWNER_CLOSED, "O fechamento vai no save.")
	assert_eq(restored.state_hash(), world.state_hash(), "Salvar e carregar não muda o hash.")
	world.teardown()
	restored.teardown()
