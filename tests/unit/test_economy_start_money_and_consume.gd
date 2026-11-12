extends GutTest
## LW-093 (parte 2): o dinheiro inicial nasce na ABERTURA da conta, só por `mint` com o motivo `game_start` (DEC-145 e DEC-170), e `request_consume` (docs/modules/economy.md, seção 7): o NPC consome comida do inventário dele, o bem
## é destruído com o motivo `consumed` e o alívio (`need_relief` × quantidade) volta para o `npc` aplicar. Usa os dados REAIS (data/economy): os mercados A e B levam os IDs 1 e 2 (3000 cada); `npc` abre com 60, `player` com 100,
## `contract` com 0; pão alivia 60 de `hunger` por unidade e grão 30; ferramenta não é comida.

const SEED: int = 73
const MARKET: int = 1
const NPC: int = 100


func _module() -> EconomyModule:
	var setup: EconomySetup = EconomySetup.from_dir(EconomySetup.DEFAULT_DIR)
	assert_true(setup.result.ok, setup.result.message)
	return EconomyModule.new(false, setup.definitions)


func _world(module: EconomyModule) -> World:
	var clock: SimClock = SimClock.new()
	var world: World = World.new(SimContext.new(clock, EventBus.new(clock), WorldRng.new(SEED), IdGenerator.new()))
	assert_true(world.register_module("economy", module).ok)
	world.setup()
	world.post_setup()
	world.on_new_game(SEED)
	return world


func test_the_initial_money_is_minted_only_when_the_account_opens_with_the_reason_game_start() -> void:
	var module: EconomyModule = _module()
	var world: World = _world(module)
	assert_eq(module.peek_conservation().created, 11800, "Os três mercados (3000 cada) e os 14 locais de produção (200 cada) já nasceram com `game_start`.")
	assert_true(module.request_open_owner(NPC, "npc").ok)
	assert_eq(module.peek_balance(NPC).balance, 60, "O NPC abre com o saldo inicial do tipo.")
	assert_true(module.request_open_owner(NPC, "npc").ok, "Abrir de novo é inofensivo...")
	assert_eq(module.peek_balance(NPC).balance, 60, "...e não cria dinheiro de novo.")
	assert_true(module.request_open_owner(101, "player").ok)
	assert_true(module.request_open_owner(102, "contract").ok)
	assert_eq([module.peek_balance(101).balance, module.peek_balance(102).balance], [100, 0], "O jogador abre com 100 e o contrato (saldo inicial 0) sem `mint`.")
	var conservation: EconomyReplies.ConservationQuery = module.peek_conservation()
	assert_eq([conservation.sum, conservation.created, conservation.ok], [11960, 11960, true], "Todo o dinheiro novo vem de `mint`.")
	assert_eq(module.peek_ledger_totals().rows, [{"reason": "game_start", "moved": 0, "created": 11960, "destroyed": 0}] as Array[Dictionary], "E só com o motivo `game_start`.")
	var bare: EconomyModule = EconomyModule.new()
	assert_true(bare.request_open_owner(NPC, "npc").ok)
	assert_eq(bare.peek_balance(NPC).balance, 0, "Sem tipos nas definições não há saldo inicial.")
	assert_eq(module.validate(), [] as Array[String])
	world.teardown()


func test_a_npc_eats_from_its_own_inventory_and_the_economy_returns_the_relief() -> void:
	var module: EconomyModule = _module()
	var world: World = _world(module)
	assert_true(module.request_open_owner(NPC, "npc").ok)
	assert_true(module.request_transfer_goods(MARKET, NPC, "bread", 3).ok)
	assert_true(module.request_transfer_goods(MARKET, NPC, "grain", 2).ok)
	var eaten: EconomyReplies.ConsumeResult = module.request_consume(NPC, "bread", 2)
	assert_true(eaten.result.ok, eaten.result.message)
	assert_eq([eaten.quantity, eaten.need_id, eaten.relief], [2, "hunger", 120], "Pão: 60 de alívio por unidade.")
	var grain: EconomyReplies.ConsumeResult = module.request_consume(NPC, "grain", 2)
	assert_eq([grain.need_id, grain.relief], ["hunger", 60], "Grão: 30 por unidade, menos que o pão.")
	assert_eq(module.peek_inventory(NPC).rows, [{"good_id": "bread", "quantity": 1}] as Array[Dictionary], "O que foi comido saiu do inventário.")
	var bread: Array[Dictionary] = module.peek_goods_conservation().rows.filter(func(row: Dictionary) -> bool: return row["good_id"] == "bread")
	assert_eq([bread[0]["destroyed"], bread[0]["ok"]], [2, true], "O pão consumido foi destruído com o motivo `consumed` e a conservação fecha.")
	world.teardown()


func test_a_refused_consumption_changes_nothing_and_says_why() -> void:
	var module: EconomyModule = _module()
	var world: World = _world(module)
	assert_true(module.request_open_owner(NPC, "npc").ok)
	assert_true(module.request_transfer_goods(MARKET, NPC, "bread", 2).ok)
	assert_true(module.request_transfer_goods(MARKET, NPC, "tool", 1).ok)
	var before: Dictionary = module.serialize()
	var cases: Array[Dictionary] = [
		{"label": "mais do que tem", "reply": module.request_consume(NPC, "bread", 3), "code": EconomyCodes.INSUFFICIENT_GOODS},
		{"label": "ferramenta não é comida", "reply": module.request_consume(NPC, "tool", 1), "code": EconomyCodes.NOT_CONSUMABLE},
		{"label": "bem que não existe", "reply": module.request_consume(NPC, "gold", 1), "code": EconomyCodes.UNKNOWN_GOOD},
		{"label": "quantidade zero", "reply": module.request_consume(NPC, "bread", 0), "code": EconomyCodes.BAD_QUANTITY},
		{"label": "dono que não existe", "reply": module.request_consume(999, "bread", 1), "code": EconomyCodes.UNKNOWN_OWNER},
	]
	for test_case: Dictionary in cases:
		var reply: EconomyReplies.ConsumeResult = test_case["reply"]
		assert_eq(reply.result.code, test_case["code"], test_case["label"])
		assert_eq([reply.quantity, reply.relief, reply.need_id], [0, 0, ""], "%s: nada foi consumido." % test_case["label"])
	assert_eq(module.serialize(), before, "Nenhuma recusa muda o estado.")
	world.context.events.publish(NpcDied.new(NPC, "hunger", 1))
	world.context.events.dispatch()
	assert_eq(module.request_consume(NPC, "bread", 1).result.code, EconomyCodes.OWNER_CLOSED, "O NPC morto não come.")
	world.teardown()
