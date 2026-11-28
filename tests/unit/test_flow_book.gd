extends GutTest
## LW-100c1: o livro do fluxo (`FlowBook`, com `Lot` e `RouteRow`, e os tipos de `FlowReplies`; docs/modules/economy.md, 9.16.2, 9.16.6 e 9.16.7): estrutura pura, sem o módulo, sem o save da economia e sem dados (a ligação é da LW-100c2). O livro nasce VIRGEM e o virgem não tem o que gravar; o save faz ida e volta com lote a caminho e lote parado; os mesmos dados dão os
## mesmos bytes em qualquer ordem; `load_from` recusa cada problema INTERNO (tipo, campo, faixa, id, rota do lote, dono-trânsito) sem mudar nada e aceita cada limite; o contador de lotes nunca devolve um id; as respostas e as buscas são cópias.


## Um lote válido do save (a caminho, rota A-B, 6 pães do mercado 1 ao 2), com `changes` por cima.
func _lot(lot_id: int, changes: Dictionary = {}) -> Dictionary:
	var record: Dictionary = {"lot_id": lot_id, "route_id": "route_a_b", "origin_market_id": 1, "destination_market_id": 2, "good_id": "bread", "quantity": 6, "state": "travelling", "departed_at": 120, "arrives_at": 300, "remaining_minutes": 0}
	record.merge(changes, true)
	return record


## O lote 2 PARADO (`held`) da rota B-C: sem chegada marcada e com 40 minutos para andar.
func _held() -> Dictionary:
	return _lot(2, {"route_id": "route_b_c", "state": "held", "arrives_at": 0, "remaining_minutes": 40})


func _route(route_id: String, changes: Dictionary = {}) -> Dictionary:
	var record: Dictionary = {"route_id": route_id, "enabled": true, "risk_carry_bp": 0}
	record.merge(changes, true)
	return record


## O save de um livro com o dono-trânsito 7, duas rotas (resto 125 e 0) e dois lotes (a caminho e parado), na ordem de 9.16.6; `changes` troca campos do topo.
func _payload(changes: Dictionary = {}) -> Dictionary:
	var payload: Dictionary = {"holder_id": 7, "next_lot_id": 3, "routes": [_route("route_a_b", {"risk_carry_bp": 125}), _route("route_b_c")], "lots": [_lot(1), _held()]}
	payload.merge(changes, true)
	return payload


func _new_lot() -> FlowBook.Lot:
	return FlowBook.Lot.from_record(_lot(0))


func _book(payload: Dictionary) -> FlowBook:
	var book: FlowBook = FlowBook.new()
	assert_true(book.load_from(payload).ok)
	return book


## Os bytes SEM ordenar as chaves: a ordem em que o livro as emite conta.
func _bytes(book: FlowBook) -> String:
	return JSON.stringify(book.serialize(), "", false, true)


func _through_json(data: Dictionary) -> Dictionary:
	# Variant: o JSON devolve qualquer tipo; aqui o formato é conhecido (um objeto).
	var parsed: Variant = JSON.parse_string(JSON.stringify(data))
	assert_eq(typeof(parsed), TYPE_DICTIONARY)
	var copy: Dictionary = parsed
	return copy


func _without(data: Dictionary, key: String) -> Dictionary:
	var copy: Dictionary = data.duplicate(true)
	copy.erase(key)
	return copy


func test_a_new_book_is_pristine_and_has_nothing_to_save() -> void:
	var book: FlowBook = FlowBook.new()
	assert_true(book.is_pristine())
	assert_eq([book.serialize(), book.holder_id(), book.next_lot_id(), book.route_ids(), book.lot_ids()], [{}, 0, 1, [] as Array[String], [] as Array[int]])
	assert_eq([book.lot_of(1), book.route_of("route_a_b")], [null, null], "Sem registro não há cópia.")


func test_adding_anything_to_a_pristine_book_makes_it_not_pristine() -> void:
	var virgin: Dictionary = {"holder_id": 0, "next_lot_id": 1, "routes": [], "lots": []}
	assert_true(_book(_payload(virgin)).is_pristine(), "Um save todo vazio continua virgem.")
	for added: Dictionary in [{"holder_id": 7}, {"routes": [_route("route_a_b")]}]:
		var changed: Dictionary = virgin.duplicate()
		changed.merge(added, true)
		assert_false(_book(_payload(changed)).is_pristine(), "Acrescentou %s." % str(added.keys()))
	var book: FlowBook = FlowBook.new()
	assert_eq(book.add_lot(_new_lot()), 1)
	assert_false(book.is_pristine(), "Acrescentou um lote.")


func test_the_save_round_trips_a_travelling_and_a_held_lot_byte_for_byte() -> void:
	var book: FlowBook = _book(_payload())
	assert_false(book.is_pristine())
	assert_eq(_bytes(book), JSON.stringify(_payload(), "", false, true), "O que sai é o que entrou: o formato de 9.16.6, os campos na ordem de 9.16.2, só inteiros, textos e booleano.")
	var restored: FlowBook = FlowBook.new()
	assert_true(restored.load_from(_through_json(book.serialize())).ok, "Ida e volta pelo JSON (os números voltam decimais).")
	assert_eq(_bytes(restored), _bytes(book))
	var held: FlowBook.Lot = restored.lot_of(2)
	assert_eq([restored.holder_id(), restored.next_lot_id(), restored.lot_ids(), restored.route_ids()], [7, 3, [1, 2] as Array[int], ["route_a_b", "route_b_c"] as Array[String]])
	assert_eq([held.state, held.arrives_at, held.remaining_minutes, restored.lot_of(1).arrives_at, restored.route_of("route_a_b").risk_carry_bp], ["held", 0, 40, 300, 125])


func test_the_same_data_gives_the_same_bytes_in_any_order() -> void:
	var reversed: Dictionary = _payload()
	for key: String in ["routes", "lots"]:
		(reversed[key] as Array).reverse()
	assert_eq(_bytes(_book(reversed)), _bytes(_book(_payload())), "Rotas por route_id e lotes por lot_id, qualquer que seja a ordem de entrada.")
	assert_eq(_book(reversed).lot_ids(), [1, 2] as Array[int])


func test_load_from_refuses_each_invalid_save_and_changes_nothing() -> void:
	var book: FlowBook = _book(_payload())
	var before: String = _bytes(book)
	var cases: Array[Dictionary] = [
		{"label": "sem o dono-trânsito", "data": _without(_payload(), "holder_id"), "expect": "'holder_id' deve ser um inteiro"},
		{"label": "sem a lista de lotes", "data": _without(_payload(), "lots"), "expect": "'lots' deve ser uma lista"},
		{"label": "tudo vazio, nem os campos", "data": {}, "expect": "'holder_id' deve ser um inteiro"},
		{"label": "sem o contador", "data": _without(_payload(), "next_lot_id"), "expect": "'next_lot_id' deve ser um inteiro"},
		{"label": "booleano no lugar de inteiro", "data": _payload({"holder_id": true}), "expect": "'holder_id' deve ser um inteiro"},
		{"label": "linha de rota sem o resto", "data": _payload({"routes": [_without(_route("route_a_b"), "risk_carry_bp")]}), "expect": "'risk_carry_bp' deve ser um inteiro"},
		{"label": "dono-trânsito decimal", "data": _payload({"holder_id": 7.5}), "expect": "'holder_id' deve ser um inteiro"},
		{"label": "dono-trânsito negativo", "data": _payload({"holder_id": -1}), "expect": "'holder_id' é -1; esperado 0 ou mais"},
		{"label": "contador zero", "data": _payload({"next_lot_id": 0}), "expect": "'next_lot_id' é 0; esperado 1 ou mais"},
		{"label": "contador igual ao maior lote", "data": _payload({"next_lot_id": 2}), "expect": "'next_lot_id' é 2; esperado maior que o maior lote (2)"},
		{"label": "contador menor que o maior lote", "data": _payload({"next_lot_id": 1}), "expect": "'next_lot_id' é 1; esperado maior que o maior lote (2)"},
		{"label": "rotas que não são lista", "data": _payload({"routes": {}}), "expect": "'routes' deve ser uma lista"},
		{"label": "linha que não é objeto", "data": _payload({"routes": [3]}), "expect": "linha de rota 0: esperado um objeto"},
		{"label": "rota que não é texto", "data": _payload({"routes": [_route("route_a_b", {"route_id": 5})]}), "expect": "'route_id' deve ser texto"},
		{"label": "enabled que não é booleano", "data": _payload({"routes": [_route("route_a_b", {"enabled": 1})]}), "expect": "'enabled' deve ser verdadeiro ou falso"},
		{"label": "resto decimal", "data": _payload({"routes": [_route("route_a_b", {"risk_carry_bp": 1.5})]}), "expect": "'risk_carry_bp' deve ser um inteiro"},
		{"label": "resto 10000", "data": _payload({"routes": [_route("route_a_b", {"risk_carry_bp": 10000})]}), "expect": "'risk_carry_bp' é 10000; esperado de 0 a 9999"},
		{"label": "resto negativo", "data": _payload({"routes": [_route("route_a_b", {"risk_carry_bp": -1})]}), "expect": "'risk_carry_bp' é -1; esperado de 0 a 9999"},
		{"label": "duas linhas da mesma rota", "data": _payload({"routes": [_route("route_a_b"), _route("route_a_b")]}), "expect": "a rota 'route_a_b' tem mais de uma linha"},
		{"label": "lote que não é objeto", "data": _payload({"lots": [3]}), "expect": "registro de lote 0: esperado um objeto"},
		{"label": "quantidade decimal", "data": _payload({"lots": [_lot(1, {"quantity": 1.5})]}), "expect": "'quantity' deve ser um inteiro"},
		{"label": "quantidade em texto", "data": _payload({"lots": [_lot(1, {"quantity": "6"})]}), "expect": "'quantity' deve ser um inteiro"},
		{"label": "bem que não é texto", "data": _payload({"lots": [_lot(1, {"good_id": 5})]}), "expect": "'good_id' deve ser texto"},
		{"label": "lote sem um campo", "data": _payload({"lots": [_without(_lot(1), "arrives_at")]}), "expect": "'arrives_at' deve ser um inteiro"},
		{"label": "id de lote zero", "data": _payload({"lots": [_lot(1, {"lot_id": 0})]}), "expect": "'lot_id' é 0; esperado 1 ou mais"},
		{"label": "id de lote repetido", "data": _payload({"lots": [_lot(1), _lot(1)]}), "expect": "o id 1 está repetido"},
		{"label": "quantidade zero", "data": _payload({"lots": [_lot(1, {"quantity": 0})]}), "expect": "'quantity' é 0; esperado 1 ou mais"},
		{"label": "estado desconhecido", "data": _payload({"lots": [_lot(1, {"state": "flying"})]}), "expect": "o estado 'flying' não é válido; esperado um de: travelling, held"},
		{"label": "parado com chegada marcada", "data": _payload({"lots": [_lot(1, {"state": "held"})]}), "expect": "em 'held', 'arrives_at' é 300; esperado 0"},
		{"label": "parado com minutos negativos", "data": _payload({"lots": [_lot(1, {"state": "held", "arrives_at": 0, "remaining_minutes": -1})]}), "expect": "em 'held', 'remaining_minutes' é -1; esperado 0 ou mais"},
		{"label": "a caminho com minutos parados", "data": _payload({"lots": [_lot(1, {"remaining_minutes": 5})]}), "expect": "em 'travelling', 'remaining_minutes' é 5; esperado 0"},
		{"label": "lote de rota sem linha", "data": _payload({"lots": [_lot(1, {"route_id": "route_x"})]}), "expect": "o lote 1 é da rota 'route_x', que não tem linha"},
		{"label": "lote sem dono-trânsito aberto", "data": _payload({"holder_id": 0}), "expect": "há lotes, mas 'holder_id' é 0"},
	]
	var pristine: FlowBook = FlowBook.new()
	for test_case: Dictionary in cases:
		var refused: Result = book.load_from(test_case["data"])
		assert_false(refused.ok, test_case["label"])
		assert_eq(refused.code, EconomyCodes.INVALID_SAVE, test_case["label"])
		assert_string_contains(refused.message, test_case["expect"], test_case["label"])
		assert_eq(_bytes(book), before, "%s: o livro fica como estava." % test_case["label"])
		assert_false(pristine.load_from(test_case["data"]).ok)
		assert_true(pristine.is_pristine(), "%s: o livro virgem continua virgem." % test_case["label"])


func test_a_successful_load_from_replaces_everything_the_book_had() -> void:
	var book: FlowBook = _book(_payload())
	var other: Dictionary = {"holder_id": 9, "next_lot_id": 5, "routes": [_route("route_a_c", {"risk_carry_bp": 40})], "lots": []}
	assert_true(book.load_from(other).ok)
	assert_eq(_bytes(book), _bytes(_book(other)), "Carregar de novo deixa só o que o save novo traz: nada das rotas nem dos lotes de antes (não mescla).")
	assert_eq([book.route_ids(), book.lot_ids(), book.holder_id(), book.next_lot_id()], [["route_a_c"] as Array[String], [] as Array[int], 9, 5])


func test_load_from_accepts_the_limits_of_each_field() -> void:
	var edge: Dictionary = {"routes": [_route("route_a_b", {"risk_carry_bp": 9999}), _route("route_b_c", {"risk_carry_bp": 0})], "lots": [_lot(1, {"quantity": 1}), _lot(2, {"route_id": "route_b_c", "state": "held", "arrives_at": 0, "remaining_minutes": 0})], "next_lot_id": 3}
	var book: FlowBook = _book(_payload(edge))
	assert_eq([book.route_of("route_a_b").risk_carry_bp, book.route_of("route_b_c").risk_carry_bp, book.lot_of(1).quantity, book.lot_of(2).remaining_minutes, book.next_lot_id()], [9999, 0, 1, 0, 3], "Resto 0 e 9999, quantidade 1, parado sem minutos e o contador exatamente acima do maior lote.")


func test_next_lot_id_never_reuses_the_id_of_a_removed_lot() -> void:
	var book: FlowBook = _book(_payload())
	assert_eq(book.add_lot(_new_lot()), 3, "O primeiro lote novo recebe o `next_lot_id` do save.")
	book.remove_lot(3)
	assert_eq(book.add_lot(_new_lot()), 4, "O id 3 foi retirado e não volta.")
	book.remove_lot(1)
	assert_eq([book.lot_ids(), book.next_lot_id(), book.lot_of(3)], [[2, 4] as Array[int], 5, null])
	assert_eq(_book(_through_json(book.serialize())).add_lot(_new_lot()), 5, "O contador faz parte do save: depois de carregar, o id retirado também não volta.")


func test_the_replies_and_the_lookups_are_copies_of_simple_fields() -> void:
	var book: FlowBook = _book(_payload())
	var incoming: FlowBook.Lot = _new_lot()
	var new_id: int = book.add_lot(incoming)
	incoming.quantity = 99
	assert_eq(book.lot_of(new_id).quantity, 6, "`add_lot` guarda uma cópia.")
	var before: String = _bytes(book)
	var held: FlowBook.Lot = book.lot_of(2)
	var lot_row: FlowReplies.LotQuery = FlowReplies.LotQuery.new(held)
	assert_eq(FlowBook.Lot.KEYS.size(), 10, "Se um campo entrar no lote, a linha de resposta e este teste acompanham.")
	assert_eq([lot_row.lot_id, lot_row.route_id, lot_row.origin_market_id, lot_row.destination_market_id, lot_row.good_id, lot_row.quantity, lot_row.state, lot_row.departed_at, lot_row.arrives_at, lot_row.remaining_minutes], [held.lot_id, held.route_id, held.origin_market_id, held.destination_market_id, held.good_id, held.quantity, held.state, held.departed_at, held.arrives_at, held.remaining_minutes], "A linha do lote copia os dez campos do lote.")
	assert_eq([lot_row.lot_id, lot_row.route_id, lot_row.state, lot_row.arrives_at, lot_row.remaining_minutes], [2, "route_b_c", "held", 0, 40], "E são os do lote parado do save (9.16.2).")
	var route_row: FlowReplies.RouteQuery = FlowReplies.RouteQuery.new(book.route_of("route_a_b"))
	assert_eq([lot_row.minutes_left, route_row.route_id, route_row.enabled, route_row.risk_carry_bp, route_row.lots_count], [0, "route_a_b", true, 125, 0], "`minutes_left`, `route_state` e `lots_count` são de quem chama.")
	var plan: FlowReplies.PlanQuery = FlowReplies.PlanQuery.new(Result.failure(EconomyCodes.NO_ROUTE, "sem rota"))
	assert_eq([plan.result.code, plan.origin_market_id, plan.good_id, plan.planned_quantity, plan.sent_quantity, plan.minutes, plan.net_profit], [EconomyCodes.NO_ROUTE, 0, "", 0, 0, 0, 0])
	held.quantity = 99
	lot_row.quantity = 99
	lot_row.minutes_left = 15
	route_row.risk_carry_bp = 1
	route_row.enabled = false
	book.lot_of(1).state = "held"
	book.route_of("route_b_c").enabled = false
	assert_eq(_bytes(book), before, "Mudar a resposta ou a cópia nunca muda o livro.")
