class_name SupplyRules
extends RefCounted
## As regras de oferta da LW-094b (PROPOSTA em ramo; docs/economia/contrato-lw-094b-regras-de-oferta.md), só funções puras: tudo vem da HORA ABSOLUTA da economia (`h`, a hora cheia que está sendo processada) e dos IDs. Nenhum estado,
## nenhum sorteio: o mesmo `h` dá sempre a mesma resposta, num jogo novo ou depois de carregar um save.


## R. A ordem dos locais na hora `hour`: os `ids` (em ordem crescente) começando no índice `h mod n`, para a FRENTE quando `⌊h ÷ n⌋` é par e para TRÁS quando é ímpar (circular). Em cada janela de `2n` horas cada local é o primeiro 2 vezes e,
## para qualquer par, cada um vem antes do outro em `n` horas. Com `hour` 0 é a ordem crescente (a antiga).
static func rotated_order(ids: Array[int], hour: int) -> Array[int]:
	var count: int = ids.size()
	if count < 2:
		return ids.duplicate()
	var start: int = posmod(hour, count)
	var step: int = 1 if posmod(IntMath.floor_div(hour, count), 2) == 0 else -1
	var order: Array[int] = []
	for offset: int in count:
		order.append(ids[posmod(start + step * offset, count)])
	return order
