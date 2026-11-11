class_name PriceMath
extends RefCounted
## As fórmulas de preço da `economy` em INTEIROS (docs/modules/economy.md, seção 4; DEC-150), funções puras: nada de estado, relógio ou sorteio. `base` = `base_value` do bem; `target` = estoque-alvo; `stock` = estoque;
## proporções em pontos-base (10000 = 1,0). Toda divisão é inteira. O que vale como contrato são as PROPRIEDADES (o preço fica na faixa; estoque baixo sobe e alto desce; ordem grande custa mais por unidade; comprar e
## vender na hora dá prejuízo; o preço não salta mais que a suavização por dia); a curva exata é calibração.

const BASIS: int = 10000
## O `spread_bp` é a diferença TOTAL entre compra e venda, repartida em dois lados: 2 × 10000.
const SPREAD_DENOMINATOR: int = 20000


static func ceil_div(dividend: int, divisor: int) -> int:
	return IntMath.floor_div(dividend + divisor - 1, divisor)


## Quanto o preço sobe quando o estoque cai: `10000 × alvo ÷ max(estoque, 1)`, preso entre o piso e o teto de fator.
static func factor_bp(target: int, stock: int, params: PriceParams) -> int:
	return clampi(IntMath.floor_div(BASIS * target, maxi(stock, 1)), params.min_factor_bp, params.max_factor_bp)


static func floor_price(base: int, params: PriceParams) -> int:
	return maxi(1, IntMath.floor_div(base * params.min_factor_bp, BASIS))


static func ceiling_price(base: int, params: PriceParams) -> int:
	return maxi(floor_price(base, params), IntMath.floor_div(base * params.max_factor_bp, BASIS))


## O preço para o qual o de tabela anda ao fim do dia, com o estoque `stock` nesse instante.
static func goal_price(base: int, target: int, stock: int, params: PriceParams) -> int:
	var raw: int = maxi(1, IntMath.floor_div(base * factor_bp(target, stock, params), BASIS))
	return clampi(raw, floor_price(base, params), ceiling_price(base, params))


## Um passo da suavização: anda `smoothing_bp` da diferença em direção ao alvo, no mínimo 1 quando há diferença e nunca passando do alvo.
static func smoothed_price(price: int, goal: int, smoothing_bp: int) -> int:
	var gap: int = goal - price
	if gap == 0:
		return price
	var step: int = mini(maxi(1, IntMath.floor_div(absi(gap) * smoothing_bp, BASIS)), absi(gap))
	return price + step if gap > 0 else price - step


## O preço do degrau de estoque `stock`, a partir do preço de tabela fixado com o estoque `ref_stock`. Não cresce quando o estoque cresce e vale `price` em `stock == ref_stock`.
static func price_at(price: int, base: int, target: int, ref_stock: int, stock: int, params: PriceParams) -> int:
	var raw: int = maxi(1, IntMath.floor_div(price * factor_bp(target, stock, params), factor_bp(target, ref_stock, params)))
	return clampi(raw, floor_price(base, params), ceiling_price(base, params))


static func margin(price: int, spread_bp: int) -> int:
	return ceil_div(price * spread_bp, SPREAD_DENOMINATOR)


## Por quanto o mercado VENDE (compra do ator) ao preço `price`.
static func ask(price: int, spread_bp: int) -> int:
	return price + margin(price, spread_bp)


## Por quanto o mercado COMPRA (venda do ator): nunca 0, então o `Ledger` nunca recusa um preço.
static func bid(price: int, spread_bp: int) -> int:
	return maxi(1, price - margin(price, spread_bp))


## O que o ator paga por `quantity` unidades com o estoque do mercado em `stock` (`quantity` ≤ `stock`): a soma de `ask(P(stock − i))`, de i = 0 a quantity − 1 (a ordem "anda pela curva").
static func quote_buy(price: int, base: int, target: int, ref_stock: int, stock: int, quantity: int, params: PriceParams) -> int:
	var total: int = 0
	for step: int in quantity:
		total += ask(price_at(price, base, target, ref_stock, stock - step, params), params.spread_bp)
	return total


## O que o ator recebe por `quantity` unidades vendidas com o estoque em `stock`: a soma de `bid(P(stock + i))`, de i = 1 a quantity.
static func quote_sell(price: int, base: int, target: int, ref_stock: int, stock: int, quantity: int, params: PriceParams) -> int:
	var total: int = 0
	for step: int in range(1, quantity + 1):
		total += bid(price_at(price, base, target, ref_stock, stock + step, params), params.spread_bp)
	return total
