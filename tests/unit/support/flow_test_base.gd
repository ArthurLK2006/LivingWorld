class_name FlowTestBase
extends GutTest
## Base dos testes do fluxo agregado da LW-100d1b (docs/modules/economy.md, 9.16): o jogo com a economia e as rotas REAIS (`FlowRig`, chave ligada pelo comando de desenvolvimento) e os ajudantes de leitura do save, do estoque e da consistência. O `test_economy_flow_dispatch.gd` (d1a) tem cópia dos seus e segue como está.

const DAY: int = 1440

var _service: RouteService
var _rigs: Array[FlowRig] = []


func before_all() -> void:
	_service = CaravanRig.load_routes()


func after_each() -> void:
	for rig: FlowRig in _rigs:
		rig.release()
	_rigs.clear()


## `cadence`: de quantos em quantos minutos a economia anda (1 = o jogo real); `quiet`: sem produção, postos nem contratos.
func _rig(flow: FlowParams = null, cadence: int = 1, quiet: bool = false) -> FlowRig:
	var rig: FlowRig = FlowRig.build(_service, flow, -1, quiet)
	rig.start_new_game(cadence)
	_rigs.append(rig)
	return rig


## Parâmetros do fluxo só com `risk_bp_per_point` trocado (a rota A-B tem 10 pontos de risco).
func _risk(risk_bp_per_point: int) -> FlowParams:
	return FlowParams.new({"id": "flow_defaults", "daily_cap_units": 50, "risk_bp_per_point": risk_bp_per_point})


## O bloco `trade_flow` do save da economia (vazio com o livro virgem), os lotes dele e o resto de risco da rota de índice `index`.
func _flow(module: EconomyModule) -> Dictionary:
	return module.serialize().get("trade_flow", {})


func _lots(module: EconomyModule) -> Array:
	return _flow(module).get("lots", [])


func _carry(module: EconomyModule, index: int = 0) -> int:
	return int(_flow(module)["routes"][index]["risk_carry_bp"])


func _stock(rig: FlowRig, market_id: int, good_id: String) -> int:
	return rig.module.peek_stock(market_id, good_id).value


func _stocks(rig: FlowRig) -> Dictionary:
	var stocks: Dictionary = {}
	for market_id: int in [rig.market_a, rig.market_b, rig.market_c]:
		for good_id: String in FlowRig.GOODS:
			stocks["%d:%s" % [market_id, good_id]] = _stock(rig, market_id, good_id)
	return stocks


func _enable(rig: FlowRig, routes: Array[String]) -> void:
	for route: String in routes:
		assert_true(rig.module.request_set_flow_enabled(route, true).ok, route)


## Pão em sobra no mercado de origem e em falta no de destino (o lote do dia sai desse sentido; o preço só reage ao estoque no fim do dia).
func _gap(rig: FlowRig, origin: int, destination: int) -> void:
	assert_true(rig.module.request_set_stock(origin, "bread", 600).ok)
	assert_true(rig.module.request_set_stock(destination, "bread", 0).ok)


## A conservação dos bens e do dinheiro, o `validate` e, por bem, dono-trânsito = soma dos lotes.
func _assert_consistent(rig: FlowRig) -> void:
	assert_true(rig.module.peek_goods_conservation().ok, "bens conservados")
	assert_true(rig.module.peek_conservation().ok, "dinheiro conservado")
	assert_eq(rig.module.validate().size(), 0, "validate: %s" % str(rig.module.validate()))
	var wanted: Dictionary = {}
	for lot: Dictionary in _lots(rig.module):
		wanted[lot["good_id"]] = int(wanted.get(lot["good_id"], 0)) + int(lot["quantity"])
	var held: Dictionary = {}
	for row: Dictionary in rig.module.peek_inventory(int(_flow(rig.module).get("holder_id", 0))).rows:
		held[row["good_id"]] = row["quantity"]
	assert_eq(held, wanted, "o dono-trânsito tem a soma dos lotes, por bem")
