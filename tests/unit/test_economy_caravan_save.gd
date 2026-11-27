extends GutTest
## LW-098c: a caravana no módulo `economy` (docs/modules/economy.md, 9.3, 9.8 e 9.10). O dono `merchant` abre com peso 120 e saldo 300 e o `NpcDied` o fecha SEM tirar a soma (e apaga a caravana dele); o save faz ida e volta com caravana em trânsito, parada e com sobra (AGENTS 4.15);
## compatibilidade (sem caravana o bloco não ganha a chave, o save sem ela carrega, chave desconhecida segue recusada) e determinismo (os mesmos comandos dão os mesmos bytes e o mesmo hash); `peek_caravan` e `peek_caravans_on` devolvem cópias por `trader_id` crescente. Economia REAL
## (data/economy, 3 povoados). O livro nasce vazio e nada o preenche ainda (a partida é da 098d1): as caravanas entram pelo save.

const SEED: int = 98
const IN_TRANSIT: int = 100
const HELD_MID_ROAD: int = 101
const HELD_IN_SETTLEMENT: int = 102
const LEFTOVER: int = 103


func _module() -> EconomyModule:
	var setup: EconomySetup = EconomySetup.from_dir(EconomySetup.DEFAULT_DIR)
	assert_true(setup.result.ok, setup.result.message)
	return EconomyModule.new(false, setup.definitions)


func _through_json(data: Dictionary) -> Dictionary:
	# Variant: o JSON devolve qualquer tipo; aqui o formato é conhecido (um objeto).
	var parsed: Variant = JSON.parse_string(JSON.stringify(data))
	assert_eq(typeof(parsed), TYPE_DICTIONARY)
	var copy: Dictionary = parsed
	return copy


func _bytes(module: EconomyModule) -> String:
	return JSON.stringify(module.serialize(), "", true, true)


## Um jogo novo com quatro comerciantes (cada um com 6, 5, 4 e 3 pães do mercado A): os três primeiros viajam do A ao C pela `route_a_c` (em trânsito, parada no meio da estrada e parada num povoado) e o quarto não tem caravana: a SOBRA de uma
## viagem que já chegou. Devolve o `World` e o módulo.
func _scenario(with_caravans: bool) -> Array:
	var module: EconomyModule = _module()
	var clock: SimClock = SimClock.new()
	var world: World = World.new(SimContext.new(clock, EventBus.new(clock), WorldRng.new(SEED), IdGenerator.new()))
	assert_true(world.register_module("economy", module).ok)
	world.setup()
	world.post_setup()
	world.on_new_game(SEED)
	var market_a: int = module.peek_market_of("test_settlement_a").market_id
	var records: Array[Dictionary] = []
	for trader: Array in [[IN_TRANSIT, 6, "travelling", 0], [HELD_MID_ROAD, 5, "held", 40], [HELD_IN_SETTLEMENT, 4, "held", 0], [LEFTOVER, 3, "", 0]]:
		assert_true(module.request_open_owner(trader[0], EconomyModule.KIND_MERCHANT).ok)
		assert_true(module.request_transfer_goods(market_a, trader[0], "bread", trader[1]).ok)
		if not str(trader[2]).is_empty():
			records.append({"trader_id": trader[0], "state": trader[2], "origin_market_id": market_a, "destination_market_id": module.peek_market_of("test_settlement_c").market_id, "route_ids": ["route_a_c"], "leg_index": 0, "leg_started_at": 100, "leg_minutes": 124, "elapsed_at_hold": trader[3], "good_id": "bread", "quantity": trader[1], "cost_paid": 78, "departed_at": 100})
	if with_caravans:
		var block: Dictionary = module.serialize()
		block["caravans"] = records
		assert_true(module.on_load(_through_json(block)).ok)
	return [world, module]


func test_the_merchant_opens_with_weight_120_and_balance_300_and_death_closes_it_keeping_the_sum() -> void:
	var scenario: Array = _scenario(true)
	var world: World = scenario[0]
	var module: EconomyModule = scenario[1]
	assert_eq([module.peek_balance(IN_TRANSIT).balance, module.peek_inventory(IN_TRANSIT).capacity], [300, 120], "Peso 120 e saldo 300 [HIP] do tipo `merchant`.")
	var before: EconomyReplies.ConservationQuery = module.peek_conservation()
	world.context.events.publish(NpcDied.new(IN_TRANSIT, "test", 0))
	world.context.events.dispatch()
	assert_eq(module.request_transfer_goods(IN_TRANSIT, module.peek_market_of("test_settlement_a").market_id, "bread", 1).code, EconomyCodes.OWNER_CLOSED, "O comerciante morto não aceita mais operação.")
	assert_eq([module.peek_balance(IN_TRANSIT).balance, module.peek_inventory(IN_TRANSIT).rows], [300, [{"good_id": "bread", "quantity": 6}] as Array[Dictionary]], "Saldo e carga continuam consultáveis, na conta fechada.")
	assert_eq(module.peek_conservation().sum, before.sum, "O dinheiro continua na soma.")
	assert_true(module.peek_conservation().ok and module.peek_goods_conservation().ok)
	assert_false(module.peek_caravan(IN_TRANSIT).found, "A caravana do morto some.")
	assert_true(module.peek_caravan(HELD_MID_ROAD).found, "As dos outros ficam.")
	assert_eq(module.validate(), [] as Array[String])


func test_the_save_round_trips_and_the_same_commands_give_the_same_bytes_and_hash() -> void:
	var first: Array = _scenario(true)
	var second: Array = _scenario(true)
	var world: World = first[0]
	var module: EconomyModule = first[1]
	assert_eq(_bytes(module), _bytes(second[1]), "Os mesmos comandos dão os mesmos bytes (por trader_id crescente).")
	assert_eq(world.state_hash(), (second[0] as World).state_hash(), "E o mesmo hash.")
	var saved: Dictionary = _through_json(world.serialize())
	assert_eq(saved["modules"]["economy"]["caravans"].map(func(record: Dictionary) -> int: return int(record["trader_id"])), [IN_TRANSIT, HELD_MID_ROAD, HELD_IN_SETTLEMENT])
	var restored: Array = _scenario(false)
	assert_true((restored[0] as World).on_load(saved).ok)
	assert_eq((restored[0] as World).state_hash(), world.state_hash(), "Ida e volta pelo JSON: o mesmo hash.")
	assert_eq(_bytes(restored[1]), _bytes(module))
	assert_eq((restored[1] as EconomyModule).validate(), [] as Array[String])
	assert_eq((restored[1] as EconomyModule).debug_summary()["caravans"], 3, "O resumo de depuração conta as caravanas.")
	assert_eq([(restored[1] as EconomyModule).peek_caravan(LEFTOVER).found, (restored[1] as EconomyModule).peek_inventory(LEFTOVER).rows], [false, [{"good_id": "bread", "quantity": 3}] as Array[Dictionary]], "A sobra fica no inventário, sem caravana.")


func test_without_caravans_the_block_has_no_key_and_a_save_without_it_loads_and_unknown_keys_are_refused() -> void:
	var module: EconomyModule = _scenario(false)[1]
	var block: Dictionary = module.serialize()
	assert_false(block.has("caravans"), "Livro vazio: o bloco e o hash não mudam.")
	assert_false(module.debug_summary().has("caravans"), "Nem o resumo de depuração.")
	var restored: EconomyModule = _module()
	assert_true(restored.on_load(_through_json(block)).ok, "O save sem a chave `caravans` carrega.")
	assert_eq(_bytes(restored), _bytes(module))
	var unknown: Result = restored.on_load({"owners": {}, "ledger": {}, "extra": 1})
	assert_eq(unknown.code, EconomyCodes.INVALID_SAVE)
	assert_string_contains(unknown.message, "'contracts', 'caravans' e 'trade_flow'", "A mensagem lista a chave `caravans` e a seguinte (`trade_flow`, LW-100c2) entre as aceitas.")
	# Variant: o valor cru que um save corrompido poderia trazer em `caravans` (objeto, lista de número, registro incompleto).
	for caravans: Variant in [{}, [3], [{"trader_id": 100}]]:
		var bad: Dictionary = _through_json(block)
		bad["caravans"] = caravans
		assert_eq(restored.on_load(bad).code, EconomyCodes.INVALID_SAVE, "`caravans` mal formado é recusado: %s." % str(caravans))
	assert_eq(_bytes(restored), _bytes(module), "Recusado, o módulo continua como estava.")
	var wrong_owner: Dictionary = _through_json(block)
	wrong_owner["caravans"] = [{"trader_id": 1, "state": "travelling", "origin_market_id": 1, "destination_market_id": 2, "route_ids": ["route_a_b"], "leg_index": 0, "leg_started_at": 0, "leg_minutes": 143, "elapsed_at_hold": 0, "good_id": "bread", "quantity": 1, "cost_paid": 1, "departed_at": 0}]
	assert_true(restored.on_load(wrong_owner).ok, "O tipo do registro está certo: o conteúdo é do `validate`.")
	assert_string_contains("\n".join(restored.validate()), "[caravans] a caravana do comerciante 1: o dono 1 é do tipo 'market'; esperado 'merchant'")


func test_peek_caravan_and_peek_caravans_on_return_copies_by_ascending_trader_id() -> void:
	var module: EconomyModule = _scenario(true)[1]
	var transit: CaravanReplies.CaravanQuery = module.peek_caravan(IN_TRANSIT)
	assert_eq([transit.result.ok, transit.found, transit.state, transit.route_ids, transit.leg_index, transit.current_route_id, transit.good_id, transit.quantity, transit.cost_paid, transit.departed_at], [true, true, "travelling", ["route_a_c"] as Array[String], 0, "route_a_c", "bread", 6, 78, 100])
	transit.route_ids.append("route_b_c")
	transit.state = "held"
	assert_eq([module.peek_caravan(IN_TRANSIT).route_ids, module.peek_caravan(IN_TRANSIT).state], [["route_a_c"] as Array[String], "travelling"], "A resposta é cópia: mudá-la não muda o livro.")
	assert_eq([module.peek_caravan(LEFTOVER).result.ok, module.peek_caravan(LEFTOVER).found], [true, false], "Comerciante sem caravana: parado.")
	assert_eq(module.peek_caravan(999).result.code, EconomyCodes.UNKNOWN_OWNER)
	assert_eq(module.peek_caravans_on("route_a_c").caravans.map(func(row: CaravanReplies.CaravanQuery) -> int: return row.trader_id), [IN_TRANSIT, HELD_MID_ROAD], "Na estrada: andando ou parada no meio; a parada num povoado fica de fora. Por trader_id.")
	assert_eq(module.peek_caravans_on("route_a_b").caravans.size(), 0)
