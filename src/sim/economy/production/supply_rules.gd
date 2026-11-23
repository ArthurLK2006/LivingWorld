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


## P. Os `size` trabalhadores que recebem na folha parcial da hora `hour`: a lista `workers` (crescente) começando no índice `h mod trabalhadores`, circular, devolvida em ordem crescente (a ordem dos pagamentos). Em `trabalhadores` horas
## seguidas cada trabalhador entra o mesmo número de vezes. `size` maior que a lista devolve a lista toda.
static func rotated_team(workers: Array[int], hour: int, size: int) -> Array[int]:
	var count: int = workers.size()
	if size >= count:
		return workers.duplicate()
	var team: Array[int] = []
	var start: int = posmod(hour, count)
	for offset: int in maxi(size, 0):
		team.append(workers[(start + offset) % count])
	team.sort()
	return team


## E. Há comprador para a produção? `outputs` é a saída de um lote por bem, `held` o que o local já guarda e `sellable` se o mercado do povoado compraria AGORA um lote daquele bem (a cotação de venda passa e o saldo do mercado paga o
## total). Sem comprador só quando, para TODO bem de saída, o local já tem um lote parado (`held ≥ saída`) E o mercado não compraria mais um lote. Receita sem saída sempre tem comprador.
static func has_buyer(outputs: Dictionary[String, int], held: Dictionary[String, int], sellable: Dictionary[String, bool]) -> bool:
	if outputs.is_empty():
		return true
	for good_id: String in outputs:
		if int(held.get(good_id, 0)) < outputs[good_id] or bool(sellable.get(good_id, false)):
			return true
	return false
