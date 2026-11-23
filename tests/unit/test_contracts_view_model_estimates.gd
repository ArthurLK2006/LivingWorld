extends GutTest
## LW-107h (custo e resultado estimados da aba Contratos): o cálculo do `ContractsViewModel` (`refresh_estimates` e `estimate_of`), sem janela, com o jogo REAL (`data/economy` e `data/world`, 3 mercados, sem NPCs, build de desenvolvimento para o `request_set_stock`) e a ponte real,
## montados como em `test_contracts_view_model.gd`. O custo vem da economia (a cotação real de COMPRA das unidades que FALTAM, nunca `ask x N`); o modelo só subtrai e compara. Confere: o custo é o `peek_quote` da economia e o resultado é a recompensa menos ele; as unidades em mãos não contam duas vezes
## (as aceitas as consomem primeiro, por `contract_id`; as abertas só veem a sobra); saldo insuficiente e a faixa da margem pequena (0 a 10% da recompensa, em inteiros); cotação recusada = custo DESCONHECIDO, nunca zero (sem estoque, lote acima de 50); a curva (o custo de 5 passa de 5 x `ask` com estoque baixo);
## nada a comprar não consulta; linha terminada ou vencida não tem estimativa nem consulta; o custo é igual ao total que o `request_trade` cobra no mesmo instante; e estimar não muda o `state_hash` nem a fila de eventos. Os preços do pão (55 para 5 no A, 160 na escassez) vêm dos dados: o teste os LÊ do oráculo.

const WORLD_DIR: String = "res://data/world"
const SEED: int = 107
const SETTLEMENT_A: String = "test_settlement_a"
const SETTLEMENT_B: String = "test_settlement_b"
const SETTLEMENT_C: String = "test_settlement_c"
const BREAD: String = "bread"
## Os contratos do teste: o pão de 5 por 53 é o da opção B da LW-107c3 (recompensa no máximo `ask x quantidade` do emissor).
const REWARD: int = 53
const QUANTITY: int = 5
const LONG_MINUTES: int = 600
const SHORT_MINUTES: int = 40
const BOARD_MINUTE: int = 100
const BUY: String = BridgePlayerEconomyReplies.SIDE_BUY
const NONE: ContractsViewModel.EstimateKind = ContractsViewModel.EstimateKind.NONE
const HELD: ContractsViewModel.EstimateKind = ContractsViewModel.EstimateKind.HELD
const UNKNOWN: ContractsViewModel.EstimateKind = ContractsViewModel.EstimateKind.UNKNOWN
const KNOWN: ContractsViewModel.EstimateKind = ContractsViewModel.EstimateKind.KNOWN

var _terrain: TerrainData
var _places: Array[Place] = []
var _setup: EconomySetup
var _center_a: Vector3
var _host: SimulationHostNode
var _bridge: QuoteSpyBridge
var _economy: EconomyModule
var _actor_id: int = 0
var _market_a: int = 0
var _market_b: int = 0
var _market_c: int = 0
var _model: ContractsViewModel


## Ponte que ANOTA cada cotação pedida e, com `forced_total` não negativo, a responde com ele (para fixar a aritmética do modelo) ou, com `forced_refusal`, a recusa com esse código; sem nenhum dos dois, repassa à de verdade.
class QuoteSpyBridge:
	extends SimBridge

	var asked: Array[Array] = []
	var forced_total: int = -1
	var forced_refusal: String = ""

	func peek_trade_quote(actor_id: int, market_id: int, good_id: String, quantity: int, side: String) -> BridgePlayerEconomyReplies.TradeQuoteReply:
		asked.append([market_id, good_id, quantity, side])
		if not forced_refusal.is_empty():
			return BridgePlayerEconomyReplies.TradeQuoteReply.new(Result.failure(forced_refusal, "recusa forçada pelo teste"))
		if forced_total >= 0:
			return BridgePlayerEconomyReplies.TradeQuoteReply.new(Result.success(), quantity, forced_total, 0, 0)
		return super(actor_id, market_id, good_id, quantity, side)


func before_all() -> void:
	var loaded: TerrainLoader.LoadResult = TerrainLoader.load_dir(WORLD_DIR)
	assert_true(loaded.result.ok, loaded.result.message)
	_terrain = loaded.terrain
	var settlements: SettlementLoader.LoadResult = SettlementLoader.load_dir(WORLD_DIR, _terrain)
	assert_true(settlements.result.ok, settlements.result.message)
	_places = settlements.places
	for place: Place in _places:
		if place.kind == Place.KIND_MARKET and place.settlement_id == SETTLEMENT_A:
			_center_a = place.position
	_setup = EconomySetup.from_dir(EconomySetup.DEFAULT_DIR, true)
	assert_true(_setup.result.ok, _setup.result.message)


## Um jogo só com o personagem e a economia (sem NPCs), com o jogador junto ao mercado A e com a conta aberta (saldo inicial 100); o relógio está no minuto 0.
func before_each() -> void:
	_host = SimulationHostNode.new()
	_host.start_new_game(SEED, _terrain, [], null, 0, _setup)
	_bridge = QuoteSpyBridge.new(_host, _terrain, _places)
	_economy = _host.economy
	_actor_id = _bridge.request_spawn_character().actor_id
	assert_true(_bridge.request_report_position(_actor_id, _center_a, 0.0).ok, "O jogador começa junto ao mercado A.")
	assert_true(_bridge.request_open_player_account(_actor_id).ok)
	_market_a = _economy.peek_market_of(SETTLEMENT_A).market_id
	_market_b = _economy.peek_market_of(SETTLEMENT_B).market_id
	_market_c = _economy.peek_market_of(SETTLEMENT_C).market_id
	_model = ContractsViewModel.new()


func after_each() -> void:
	_host.runner.finish()
	_host.free()


## Posta um contrato de entrega direto na economia (o jogador não posta): o emissor paga a recompensa para a custódia e o prazo é `minutes` depois de agora.
func _post(issuer: int, destination: int, reward: int = REWARD, quantity: int = QUANTITY, minutes: int = LONG_MINUTES) -> int:
	var posted: EconomyReplies.PostContractResult = _economy.request_post_contract(ContractBook.DELIVERY, issuer, reward, _bridge.peek_time().total_minutes + minutes, {"good_id": BREAD, "quantity": quantity, "destination_id": destination})
	assert_true(posted.result.ok, posted.result.message)
	return posted.contract_id


func _accept(contract_id: int) -> void:
	var accepted: Result = _economy.request_accept_contract(contract_id, _actor_id)
	assert_true(accepted.ok, accepted.message)


## Põe pão no inventário do jogador, tirado do mercado C (os preços do A e do B não mexem).
func _give(quantity: int) -> void:
	var moved: Result = _economy.request_transfer_goods(_market_c, _actor_id, BREAD, quantity)
	assert_true(moved.ok, moved.message)


## Lê o quadro do mercado `market_id` e refaz as estimativas, como a página faz com a aba visível.
func _read(market_id: int) -> void:
	assert_true(_model.refresh(_bridge, _actor_id, market_id))
	_model.refresh_estimates(_bridge, _actor_id)


func _quote(market_id: int, quantity: int) -> int:
	var quoted: EconomyReplies.QuoteQuery = _economy.peek_quote(_actor_id, market_id, BREAD, quantity, BUY)
	assert_true(quoted.result.ok, quoted.result.message)
	return quoted.total


## O que nenhuma leitura nem estimativa pode mudar: o `state_hash` do mundo e a fila de eventos pendentes.
func _snapshot() -> Array:
	return [_host.runner.world.state_hash(), int(_host.runner.world.context.events.debug_summary()["pending"])]


func test_the_cost_is_the_economys_real_quote_of_the_missing_units_and_the_result_is_the_reward_minus_it() -> void:
	var contract_id: int = _post(_market_a, _market_a)
	_read(_market_a)
	var estimate: ContractsViewModel.Estimate = _model.estimate_of(contract_id)
	var oracle: int = _quote(_market_a, QUANTITY)
	assert_gt(oracle, REWARD, "Com os dados de hoje, 5 pães no mercado emissor custam mais que a recompensa (a regra (b) do postador: recompensa no máximo `ask x quantidade`).")
	assert_eq([estimate.kind, estimate.missing, estimate.cost, estimate.result, estimate.funds_short, estimate.is_small_margin], [KNOWN, QUANTITY, oracle, REWARD - oracle, 0, false], "O custo é o da economia e o resultado é a recompensa menos ele (negativo: possível prejuízo).")
	assert_eq(_bridge.asked, [[_market_a, BREAD, QUANTITY, BUY]] as Array[Array], "Uma só cotação: de compra, das unidades que faltam, no mercado mostrado.")


func test_the_accepted_contracts_consume_the_units_in_hand_first_by_contract_id_and_a_unit_is_never_counted_twice() -> void:
	var first: int = _post(_market_a, _market_a)
	var second: int = _post(_market_a, _market_a)
	var open: int = _post(_market_a, _market_a)
	_accept(first)
	_accept(second)
	_give(7)
	_read(_market_a)
	assert_eq([_model.estimate_of(first).kind, _model.estimate_of(first).missing], [HELD, 0], "O aceito de menor id fica com 5 das 7 unidades: nada a comprar.")
	assert_eq([_model.estimate_of(second).kind, _model.estimate_of(second).missing, _model.estimate_of(second).cost], [KNOWN, 3, _quote(_market_a, 3)], "O segundo aceito fica só com as 2 que sobraram e compra as 3 que faltam.")
	assert_eq([_model.estimate_of(open).kind, _model.estimate_of(open).missing, _model.estimate_of(open).cost], [KNOWN, QUANTITY, _quote(_market_a, QUANTITY)], "O contrato aberto não vê unidade nenhuma: as 7 já são dos aceitos.")
	assert_eq(_bridge.asked.map(func(ask: Array) -> int: return ask[2]), [3, QUANTITY],"Só duas cotações: a das 3 e a das 5; o contrato sem nada a comprar não consulta.")


func test_the_open_contracts_see_only_what_is_left_and_each_sees_the_same_rest() -> void:
	var accepted: int = _post(_market_a, _market_a)
	var open_one: int = _post(_market_a, _market_a)
	var open_two: int = _post(_market_a, _market_a)
	_accept(accepted)
	_give(7)
	_read(_market_a)
	for contract_id: int in [open_one, open_two]:
		assert_eq([_model.estimate_of(contract_id).missing, _model.estimate_of(contract_id).cost], [3, _quote(_market_a, 3)], "Sobram 2 unidades depois do aceito (7 menos 5): cada aberto compra as 3 que faltam, e nenhum desconta o outro (só um será aceito de cada vez).")


func test_a_negative_result_and_the_funds_shortfall_are_plain_subtractions() -> void:
	var contract_id: int = _post(_market_a, _market_a)
	var funds: int = _bridge.peek_player_economy(_actor_id).funds
	for total: int in [funds + 60, funds + 1, funds, funds - 1]:
		_bridge.forced_total = total
		_read(_market_a)
		var estimate: ContractsViewModel.Estimate = _model.estimate_of(contract_id)
		assert_eq([estimate.cost, estimate.result, estimate.funds_short], [total, REWARD - total, maxi(0, total - funds)], "Custo %d contra o saldo %d." % [total, funds])
	assert_eq(_model.estimate_of(contract_id).funds_short, 0, "Custo menor que o saldo: nada falta.")


func test_the_small_margin_band_is_zero_to_ten_percent_of_the_reward_in_integers() -> void:
	var small: int = _post(_market_a, _market_a, REWARD)
	var large: int = _post(_market_a, _market_a, 100)
	var expected: Dictionary = {
		[REWARD, REWARD + 1]: [false, false], [REWARD, REWARD]: [true, true], [REWARD, 48]: [true, true], [REWARD, 47]: [true, false],
		[100, 90]: [true, true], [100, 89]: [true, false], [100, 100]: [true, true], [100, 101]: [false, false],
	}
	for pair: Array in expected:
		_bridge.forced_total = pair[1]
		_read(_market_a)
		var estimate: ContractsViewModel.Estimate = _model.estimate_of(small if pair[0] == REWARD else large)
		assert_eq([estimate.result >= 0, estimate.is_small_margin], expected[pair], "Recompensa %d e custo %d: resultado %d." % [pair[0], pair[1], estimate.result])


func test_a_refused_quote_makes_the_cost_unknown_never_zero() -> void:
	var contract_id: int = _post(_market_a, _market_a)
	assert_true(_economy.request_set_stock(_market_a, BREAD, QUANTITY - 1).ok)
	_read(_market_a)
	var refused: ContractsViewModel.Estimate = _model.estimate_of(contract_id)
	assert_eq([refused.kind, refused.missing], [UNKNOWN, QUANTITY], "Sem estoque para 5: o custo é desconhecido (cotação recusada), não um zero que pareceria de graça.")
	assert_ne(refused.kind, KNOWN)
	_bridge.forced_refusal = EconomyCodes.BAD_QUANTITY
	assert_true(_economy.request_set_stock(_market_a, BREAD, 2 * QUANTITY).ok)
	_read(_market_a)
	assert_eq(_model.estimate_of(contract_id).kind, UNKNOWN, "Qualquer recusa (lote acima do limite por ordem, bem banido...) deixa o custo desconhecido.")


func test_a_batch_above_the_order_limit_has_an_unknown_cost() -> void:
	var contract_id: int = _post(_market_a, _market_a, REWARD, 51)
	_read(_market_a)
	assert_eq([_model.estimate_of(contract_id).kind, _model.estimate_of(contract_id).missing], [UNKNOWN, 51], "51 unidades passam do limite de 50 por ordem: a economia recusa a cotação e o custo fica desconhecido.")


func test_the_cost_follows_the_curve_of_the_stock_not_ask_times_quantity() -> void:
	assert_true(_economy.request_set_stock(_market_b, BREAD, 20).ok, "Estoque baixo no B: o preço sobe a cada unidade comprada.")
	var contract_id: int = _post(_market_a, _market_b)
	_read(_market_b)
	var ask: int = _quote(_market_b, 1)
	var estimate: ContractsViewModel.Estimate = _model.estimate_of(contract_id)
	assert_gt(estimate.cost, QUANTITY * ask, "O custo das 5 unidades (%d) passa de 5 x `ask` (%d): `ask x N` seria um piso que subestima o custo." % [estimate.cost, QUANTITY * ask])
	assert_eq(estimate.cost, _quote(_market_b, QUANTITY))


func test_nothing_to_buy_asks_nothing_and_has_no_cost() -> void:
	var contract_id: int = _post(_market_a, _market_a)
	_accept(contract_id)
	_give(QUANTITY)
	_read(_market_a)
	var estimate: ContractsViewModel.Estimate = _model.estimate_of(contract_id)
	assert_eq([estimate.kind, estimate.missing, estimate.cost, _bridge.asked.size()], [HELD, 0, 0, 0], "Já tem as 5 unidades: sem custo de compra e sem consulta (o que ele pagou antes não está salvo).")


func test_finished_and_overdue_rows_have_no_estimate_and_ask_nothing() -> void:
	var completed: int = _post(_market_a, _market_b, REWARD, 2)
	_accept(completed)
	_give(2)
	assert_true(_economy.request_deliver_contract(completed).ok)
	var abandoned: int = _post(_market_a, _market_b)
	_accept(abandoned)
	assert_true(_economy.request_abandon_contract(abandoned, _actor_id).ok)
	var late_open: int = _post(_market_a, _market_b, REWARD, QUANTITY, SHORT_MINUTES)
	var fresh_open: int = _post(_market_a, _market_b)
	_host.runner.run_steps(BOARD_MINUTE)
	_read(_market_b)
	for contract_id: int in [completed, abandoned, late_open]:
		assert_eq(_model.estimate_of(contract_id).kind, NONE, "Concluído, abandonado e vencido não têm estimativa.")
	assert_eq(_model.estimate_of(fresh_open).kind, KNOWN)
	assert_eq(_model.estimate_of(IdGenerator.NO_ID).kind, NONE, "Uma linha que não existe também é `NONE`.")
	assert_eq(_bridge.asked.size(), 1, "Só a linha ativa foi cotada: nenhuma consulta para as terminadas nem para a vencida.")


func test_the_estimate_equals_the_total_that_request_trade_charges_at_the_same_instant() -> void:
	var contract_id: int = _post(_market_a, _market_a)
	_read(_market_a)
	var estimate: ContractsViewModel.Estimate = _model.estimate_of(contract_id)
	var bought: BridgePlayerEconomyReplies.PlayerTradeReply = _bridge.request_trade(_actor_id, _market_a, BREAD, estimate.missing, BUY)
	assert_true(bought.result.ok, bought.result.message)
	assert_eq(bought.total, estimate.cost, "O que a ordem real cobra no mesmo instante é o custo estimado (nenhuma tolerância é prometida para depois).")


func test_estimating_changes_neither_the_state_hash_nor_the_events_and_a_new_refresh_clears_the_estimates() -> void:
	var contract_id: int = _post(_market_a, _market_a)
	_accept(contract_id)
	var before: Array = _snapshot()
	_read(_market_a)
	_read(_market_a)
	assert_eq(_snapshot(), before, "Estimar só lê: o `state_hash` e os eventos pendentes ficam como estavam.")
	assert_eq(_model.estimate_of(contract_id).kind, KNOWN)
	assert_true(_model.refresh(_bridge, _actor_id, _market_a))
	assert_eq(_model.estimate_of(contract_id).kind, NONE, "O `refresh` apaga as estimativas: nenhum número da leitura anterior sobrevive sem ser refeito.")
	_model.refresh_estimates(null, _actor_id)
	assert_eq(_model.estimate_of(contract_id).kind, NONE, "Sem ponte, nenhuma estimativa.")
	_host.economy = null
	assert_false(_model.refresh(_bridge, _actor_id, _market_a))
	var asked_before: int = _bridge.asked.size()
	_model.refresh_estimates(_bridge, _actor_id)
	assert_eq([_model.estimate_of(contract_id).kind, _bridge.asked.size()], [NONE, asked_before], "Modelo inválido (sem economia): nenhuma estimativa e nenhuma cotação pedida.")
	_host.economy = _economy
