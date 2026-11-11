extends GutTest
## LW-092b: os locais de produção (`ProductionBook`; docs/modules/economy.md, seção 6) e os eventos `ProductionStopped` e `ProductionResumed`. Usa os dados REAIS (data/economy) com UM local de `bake_bread` (a lista de locais dos
## dados vem com a LW-097) no povoado A: 3 trabalhadores por lote, insumo `flour` e manutenção de `tool`, `plank` e `fabric`. Aqui: o lote por hora e a venda do excedente, os motivos de parada e a retomada só na mudança, o progresso
## pela eficiência, a manutenção (a eficiência cai por degrau até o piso e volta, e a conservação de bens fecha com `maintenance`), e o determinismo (o save do livro é da LW-092c). O passo da folha de pagamento é da LW-095.

const SETTLEMENT_A: String = "test_settlement_a"
const MARKET: int = 1
const SITE: int = 10
const WORKERS: Array[int] = [101, 102, 103]
## Receita só do teste: 2 trabalhadores por lote, até 3 lotes por hora; 1 de farinha (2 de peso) vira 10 de madeira (50 de peso), um lote que engorda o inventário.
const HEAVY: String = "heavy_batch"


class Rig:
	extends RefCounted

	var book: OwnerBook
	var ledger: Ledger
	var goods: GoodsStore
	var markets: MarketBook
	var production: ProductionBook
	var recipe: RecipeDef
	var params: SiteParams


func _heavy_recipe() -> RecipeDef:
	var recipe: RecipeDef = RecipeDef.new(HEAVY, "recipe.heavy_batch.name", "artisan", 2, 3, 2)
	recipe.inputs["flour"] = 1
	recipe.outputs["wood"] = 10
	return recipe


## Os mesmos parâmetros de preço, só com outra ordem máxima.
func _with_max_order(base: PriceParams, max_order: int) -> PriceParams:
	return PriceParams.new({"min_factor_bp": base.min_factor_bp, "max_factor_bp": base.max_factor_bp, "smoothing_bp": base.smoothing_bp, "spread_bp": base.spread_bp, "significant_change_bp": base.significant_change_bp, "max_order_quantity": max_order, "history_days": base.history_days, "shortage_threshold_bp": base.shortage_threshold_bp, "shortage_days": base.shortage_days})


## `max_order` menor que 1 = o valor dos dados.
func _rig(site_money: int = 200, recipe_id: String = "bake_bread", max_order: int = 0) -> Rig:
	var goods: GoodsLoader.LoadResult = GoodsLoader.load_dir(GoodsLoader.DEFAULT_DIR)
	var market: MarketLoader.LoadResult = MarketLoader.load_dir(GoodsLoader.DEFAULT_DIR)
	var loaded: ProductionLoader.LoadResult = ProductionLoader.load_dir(GoodsLoader.DEFAULT_DIR)
	assert_true(goods.result.ok and market.result.ok and loaded.result.ok, goods.result.message + market.result.message + loaded.result.message)
	var rig: Rig = Rig.new()
	rig.params = loaded.params
	rig.recipe = loaded.recipes["bake_bread"]
	rig.book = OwnerBook.new()
	rig.book.open_owner(MARKET, MarketBook.KIND_MARKET)
	rig.book.open_owner(SITE, ProductionBook.KIND_SITE)
	rig.ledger = Ledger.new(rig.book)
	rig.goods = GoodsStore.new(rig.book, goods.goods, goods.kinds)
	assert_true(rig.ledger.mint(MARKET, 3000, Ledger.REASON_GAME_START).ok)
	if site_money > 0:
		assert_true(rig.ledger.mint(SITE, site_money, Ledger.REASON_GAME_START).ok)
	for target: MarketTargetDef in market.targets:
		if target.settlement_id == SETTLEMENT_A:
			assert_true(rig.goods.create(MARKET, target.good_id, target.initial_stock, GoodsStore.REASON_GAME_START).ok)
	rig.markets = MarketBook.new(rig.book, rig.goods, goods.goods, market.targets, market.params)
	rig.markets.register_market(SETTLEMENT_A, MARKET)
	var trade_params: PriceParams = market.params if max_order < 1 else _with_max_order(market.params, max_order)
	var engine: TradeEngine = TradeEngine.new(rig.book, rig.ledger, rig.goods, rig.markets, NeutralTradeRules.new(), trade_params)
	var recipes: Dictionary[String, RecipeDef] = {}
	for key: String in loaded.recipes.keys():
		recipes[key] = loaded.recipes[key]
	recipes[HEAVY] = _heavy_recipe()
	rig.production = ProductionBook.new(rig.book, rig.goods, rig.markets, engine, recipes, loaded.params, trade_params.max_order_quantity)
	assert_true(rig.production.register_site(SITE, SiteDef.new("site_bread", SETTLEMENT_A, "a_work_01", recipe_id, 4)).ok)
	return rig


func _staff(rig: Rig) -> void:
	for worker_id: int in WORKERS:
		assert_true(rig.production.assign_worker(SITE, worker_id).ok)


func _types(events: Array[SimEvent]) -> Array[String]:
	var types: Array[String] = []
	for event: SimEvent in events:
		types.append(event.type)
	return types


func _hash(rig: Rig) -> String:
	return JSON.stringify([rig.production.state_of(SITE), rig.ledger.serialize(), rig.goods.serialize()], "", true, true).sha256_text()


func test_a_staffed_site_buys_the_flour_makes_a_batch_and_sells_the_bread_every_hour() -> void:
	var rig: Rig = _rig(2000)
	_staff(rig)
	var events: Array[SimEvent] = rig.production.hour_step()
	assert_eq(_types(events), [] as Array[String], "Produzindo desde a primeira hora: nenhuma mudança de estado.")
	assert_eq([rig.goods.total_by_reason("flour", GoodsStore.REASON_CONSUMED), rig.goods.total_by_reason("bread", GoodsStore.REASON_PRODUCED)], [6, 6], "Um lote: 6 de farinha viram 6 de pão.")
	assert_eq([rig.goods.quantity_of(SITE, "flour"), rig.goods.quantity_of(SITE, "bread")], [0, 0], "A farinha foi toda usada e o pão todo vendido.")
	assert_eq([rig.goods.quantity_of(MARKET, "flour"), rig.goods.quantity_of(MARKET, "bread")], [34, 66], "O mercado vendeu a farinha e comprou o pão.")
	assert_ne(rig.ledger.balance_of(SITE), 200, "O dinheiro da compra e da venda passou pelo `Ledger`.")
	assert_true(rig.ledger.is_conserved() and rig.goods.is_conserved(), "Nada é criado nem destruído de graça.")
	var state: Dictionary = rig.production.state_of(SITE)
	assert_eq([state["running"], state["batch_progress_bp"], state["efficiency_bp"], state["worker_ids"]], [true, 0, 10000, WORKERS])
	for _hour: int in 5:
		rig.production.hour_step()
	assert_eq(rig.goods.total_by_reason("bread", GoodsStore.REASON_PRODUCED), 36, "Seis horas, seis lotes.")


func test_the_stop_reason_is_published_once_on_the_change_and_the_resume_once_when_it_runs_again() -> void:
	var rig: Rig = _rig(2000)
	assert_eq(_types(rig.production.hour_step()), ["ProductionStopped"], "Sem equipe: o local para por NO_WORKER.")
	var stopped: ProductionStopped = ProductionStopped.new(0, "", "", "")
	assert_eq(rig.production.state_of(SITE)["reason"], ProductionBook.NO_WORKER)
	assert_eq(_types(rig.production.hour_step()), [] as Array[String], "Parado de novo na hora seguinte: nada de evento.")
	for worker_id: int in [101, 102]:
		assert_true(rig.production.assign_worker(SITE, worker_id).ok)
	assert_eq([_types(rig.production.hour_step()), rig.production.state_of(SITE)["reason"], rig.goods.total_by_reason("bread", GoodsStore.REASON_PRODUCED)], [[] as Array[String], ProductionBook.NO_WORKER, 0], "Dois de três trabalhadores não fazem um lote.")
	assert_true(rig.production.assign_worker(SITE, 103).ok)
	var resumed: Array[SimEvent] = rig.production.hour_step()
	assert_eq(_types(resumed), ["ProductionResumed"])
	assert_eq([(resumed[0] as ProductionResumed).site_id, (resumed[0] as ProductionResumed).settlement_id, (resumed[0] as ProductionResumed).recipe_id], [SITE, SETTLEMENT_A, "bake_bread"])
	assert_true(rig.goods.destroy(MARKET, "flour", rig.goods.quantity_of(MARKET, "flour"), GoodsStore.REASON_CONSUMED).ok, "O mercado fica sem farinha.")
	var no_input: Array[SimEvent] = rig.production.hour_step()
	assert_eq(_types(no_input), ["ProductionStopped"])
	stopped = no_input[0]
	assert_eq([stopped.site_id, stopped.settlement_id, stopped.recipe_id, stopped.reason], [SITE, SETTLEMENT_A, "bake_bread", ProductionBook.NO_INPUT])
	assert_true(rig.goods.create(MARKET, "flour", 40, GoodsStore.REASON_PRODUCED).ok)
	assert_eq(_types(rig.production.hour_step()), ["ProductionResumed"], "A farinha voltou: volta a produzir.")
	assert_true(rig.goods.create(SITE, "flour", 6, GoodsStore.REASON_PRODUCED).ok and rig.goods.create(SITE, "bread", 388, GoodsStore.REASON_PRODUCED).ok, "O inventário do local enche: 6 de farinha (12 de peso) e 388 de pão (388), os 400 da capacidade.")
	var full: Array[SimEvent] = rig.production.hour_step()
	assert_eq([_types(full), (full[0] as ProductionStopped).reason], [["ProductionStopped"], ProductionBook.OUTPUT_FULL])
	assert_eq(_types(rig.production.hour_step()), ["ProductionResumed"], "O local vendeu o excedente ao mercado e abriu espaço.")
	assert_true(rig.goods.is_conserved())


func test_the_efficiency_sets_the_pace_of_the_batches_with_the_remainder_carried() -> void:
	var rig: Rig = _rig(0)
	_staff(rig)
	for _day: int in 12:
		rig.production.end_of_day()
	assert_eq(rig.production.state_of(SITE)["efficiency_bp"], rig.params.min_efficiency_bp, "Sem peças a eficiência caiu até o piso (3000).")
	assert_true(rig.ledger.mint(SITE, 500, Ledger.REASON_GAME_START).ok)
	var progress: Array[int] = []
	var batches: Array[int] = []
	for _hour: int in 4:
		rig.production.hour_step()
		progress.append(rig.production.state_of(SITE)["batch_progress_bp"])
		batches.append(rig.goods.total_by_reason("bread", GoodsStore.REASON_PRODUCED))
	assert_eq(progress, [3000, 6000, 9000, 2000] as Array[int], "3000 por hora: o lote sai na 4ª hora e sobram 2000.")
	assert_eq(batches, [0, 0, 0, 6] as Array[int])
	assert_true(rig.ledger.is_conserved() and rig.goods.is_conserved())


func test_without_the_parts_the_efficiency_steps_down_to_the_floor_and_never_zero_and_with_them_it_recovers() -> void:
	var rig: Rig = _rig(0)
	var floor_bp: int = rig.params.min_efficiency_bp
	var seen: Array[int] = []
	for _day: int in 14:
		rig.production.end_of_day()
		seen.append(rig.production.state_of(SITE)["efficiency_bp"])
	assert_eq(seen.slice(0, 5), [10000, 10000, 10000, 10000, 9000] as Array[int], "A 1ª regra vence no 5º dia (as tábuas, a cada 5 dias): só então a eficiência cai.")
	assert_eq(seen[seen.size() - 1], floor_bp, "Cai por degrau até o piso.")
	assert_true(seen.min() >= floor_bp and floor_bp > 0, "E nunca zera.")
	assert_true(rig.ledger.mint(SITE, 300, Ledger.REASON_GAME_START).ok)
	_staff(rig)
	rig.production.hour_step()
	assert_true(rig.goods.quantity_of(SITE, "plank") >= 1 and rig.goods.quantity_of(SITE, "tool") >= 1 and rig.goods.quantity_of(SITE, "fabric") >= 1, "A hora compra do mercado as peças das três regras vencidas.")
	rig.production.end_of_day()
	assert_eq(rig.production.state_of(SITE)["efficiency_bp"], floor_bp + rig.params.efficiency_recover_bp, "Pagas as peças, a eficiência sobe um degrau.")
	assert_eq([rig.goods.total_by_reason("plank", GoodsStore.REASON_MAINTENANCE), rig.goods.total_by_reason("tool", GoodsStore.REASON_MAINTENANCE), rig.goods.total_by_reason("fabric", GoodsStore.REASON_MAINTENANCE)], [1, 1, 1], "As peças são destruídas com o motivo `maintenance`.")
	for _day: int in 8:
		for _hour: int in 24:
			rig.production.hour_step()
		rig.production.end_of_day()
	assert_eq(rig.production.state_of(SITE)["efficiency_bp"], 10000, "E segue subindo até 10000 enquanto o local compra e paga as peças que vencem.")
	assert_true(rig.goods.is_conserved(), "A conservação de bens fecha com `maintenance`.")


func test_the_crew_sets_how_many_batches_an_hour_runs_and_a_batch_that_no_longer_fits_is_not_made() -> void:
	var produced: Array[int] = []
	for crew: int in [1, 3, 4, 9]:
		var rig: Rig = _rig(2000, HEAVY)
		for worker_id: int in range(101, 101 + crew):
			assert_true(rig.production.assign_worker(SITE, worker_id).ok)
		rig.production.hour_step()
		produced.append(rig.goods.total_by_reason("wood", GoodsStore.REASON_PRODUCED))
	assert_eq(produced, [0, 10, 20, 30] as Array[int], "A equipe divide por 2 (para baixo) e o teto é de 3 lotes por hora: 1, 3, 4 e 9 trabalhadores = 0, 1, 2 e 3 lotes.")
	var full: Rig = _rig(2000, HEAVY)
	for worker_id: int in range(101, 107):
		assert_true(full.production.assign_worker(SITE, worker_id).ok)
	assert_true(full.goods.create(SITE, "wood", 61, GoodsStore.REASON_GAME_START).ok, "61 de madeira são 305 dos 400 de peso do local.")
	assert_eq(full.production.hour_step(), [] as Array[SimEvent], "Cabe um lote: o local não para.")
	assert_eq([full.goods.total_by_reason("wood", GoodsStore.REASON_PRODUCED), full.goods.total_by_reason("flour", GoodsStore.REASON_CONSUMED), full.goods.quantity_of(SITE, "flour")], [10, 1, 2], "Só o 1º lote cabe: o 2º não gasta a farinha (3 compradas, 1 usada).")
	assert_eq(full.production.state_of(SITE)["batch_progress_bp"], 9999, "O progresso que sobrou nunca passa de um lote menos 1.")
	assert_true(full.goods.is_conserved())


func test_the_orders_to_the_market_are_cut_at_the_max_order_quantity() -> void:
	var rig: Rig = _rig(2000, "bake_bread", 4)
	_staff(rig)
	assert_eq(_types(rig.production.hour_step()), [] as Array[String], "6 de farinha em ordens de 4 e 2: o local produz.")
	assert_eq([rig.goods.total_by_reason("bread", GoodsStore.REASON_PRODUCED), rig.goods.quantity_of(SITE, "bread")], [6, 0], "O pão também foi vendido em ordens de 4 e 2.")


func test_workers_are_assigned_in_order_and_the_sites_are_found_by_place_and_settlement() -> void:
	var rig: Rig = _rig()
	assert_eq(rig.production.assign_worker(99, 5).code, EconomyCodes.UNKNOWN_OWNER)
	for worker_id: int in [103, 101, 102, 101]:
		assert_true(rig.production.assign_worker(SITE, worker_id).ok)
	assert_eq(rig.production.state_of(SITE)["worker_ids"], WORKERS, "Em ordem crescente e sem repetição.")
	rig.production.remove_worker(102)
	rig.production.remove_worker(555)
	assert_eq(rig.production.state_of(SITE)["worker_ids"], [101, 103])
	assert_eq([rig.production.site_at("a_work_01"), rig.production.site_at("a_work_02"), rig.production.sites_of(SETTLEMENT_A), rig.production.sites_of("test_settlement_b")], [SITE, IdGenerator.NO_ID, [SITE] as Array[int], [] as Array[int]])
	assert_eq(rig.production.state_of(99), {})
	assert_true(rig.book.open_owner(11, ProductionBook.KIND_SITE).ok)
	assert_eq(rig.production.register_site(11, SiteDef.new("x", SETTLEMENT_A, "a_work_02", "no_such_recipe", 1)).code, EconomyCodes.DATA_INVALID)
	for not_a_site: int in [99, MARKET]:
		assert_eq(rig.production.register_site(not_a_site, SiteDef.new("x", SETTLEMENT_A, "a_work_02", "bake_bread", 1)).code, EconomyCodes.UNKNOWN_OWNER, "Só um dono do tipo `site` já aberto vira local de produção.")
		assert_false(rig.production.has_site(not_a_site))
	assert_eq(rig.production.site_ids(), [SITE] as Array[int], "Nenhuma recusa deixou um local para trás.")


func test_the_same_hours_and_days_give_the_same_state() -> void:
	var first: Rig = _rig()
	var second: Rig = _rig()
	for rig: Rig in [first, second]:
		_staff(rig)
		for _day: int in 6:
			for _hour: int in 24:
				rig.production.hour_step()
			rig.production.end_of_day()
	assert_true(first.goods.total_by_reason("bread", GoodsStore.REASON_PRODUCED) > 0, "O local produziu nesses seis dias.")
	assert_eq(_hash(first), _hash(second), "Mesmos dias, mesmo estado.")
