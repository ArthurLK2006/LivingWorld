class_name IntMath
extends RefCounted
## Divisão inteira EXPLÍCITA. O projeto conta minutos e passos em inteiros (DEC-081), então dividir
## inteiros descartando a parte decimal é intencional; escrever `a / b` com dois inteiros gera o
## aviso INTEGER_DIVISION do Godot, e o AGENTS.md proíbe silenciar avisos. Este auxiliar deixa a
## intenção clara num só lugar, sem aviso e com teste.

## Maior inteiro cuja divisão por qualquer divisor positivo é exata em decimal de 64 bits: abaixo
## de 2^53 o quociente arredondado nunca cruza para o inteiro seguinte (ver test_int_math.gd).
const MAX_EXACT_DIVIDEND: int = 9007199254740991


## Quociente da divisão arredondado para baixo (piso). Vale para |dividend| <= MAX_EXACT_DIVIDEND.
## Divisor zero registra erro e devolve 0.
static func floor_div(dividend: int, divisor: int) -> int:
	if divisor == 0:
		push_error("IntMath.floor_div: divisor zero (dividendo %d)." % dividend)
		return 0
	return floori(float(dividend) / float(divisor))
