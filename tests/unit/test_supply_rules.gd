extends GutTest
## LW-094b (PROPOSTA; docs/economia/contrato-lw-094b-regras-de-oferta.md): as funções puras das regras de oferta. Regra R: a ordem dos locais gira pela hora absoluta, com a mesma resposta para a mesma hora e equidade por janela de 2n horas.

const IDS: Array[int] = [4, 7, 9, 12, 20]


func test_hour_zero_keeps_the_old_ascending_order() -> void:
	assert_eq(SupplyRules.rotated_order(IDS, 0), IDS, "Com a hora 0 a ordem é a crescente de antes.")


func test_the_order_is_a_permutation_and_depends_only_on_the_hour() -> void:
	for hour: int in 60:
		var order: Array[int] = SupplyRules.rotated_order(IDS, hour)
		var sorted_order: Array[int] = order.duplicate()
		sorted_order.sort()
		assert_eq(sorted_order, IDS, "Hora %d: todo local aparece uma vez." % hour)
		assert_eq(order, SupplyRules.rotated_order(IDS, hour), "Hora %d: a mesma hora dá a mesma ordem (sem estado)." % hour)


func test_every_site_is_first_twice_and_every_pair_is_even_in_each_window() -> void:
	var count: int = IDS.size()
	for window: int in 3:
		var first: Dictionary[int, int] = {}
		var ahead: Dictionary[String, int] = {}
		for hour: int in range(window * 2 * count, (window + 1) * 2 * count):
			var order: Array[int] = SupplyRules.rotated_order(IDS, hour)
			first[order[0]] = int(first.get(order[0], 0)) + 1
			for i: int in count:
				for j: int in range(i + 1, count):
					var key: String = "%d<%d" % [order[i], order[j]]
					ahead[key] = int(ahead.get(key, 0)) + 1
		for site_id: int in IDS:
			assert_eq(int(first.get(site_id, 0)), 2, "Janela %d: o local %d é o primeiro 2 vezes." % [window, site_id])
		for i: int in count:
			for j: int in range(i + 1, count):
				var forward: int = int(ahead.get("%d<%d" % [IDS[i], IDS[j]], 0))
				var backward: int = int(ahead.get("%d<%d" % [IDS[j], IDS[i]], 0))
				assert_eq([forward, backward], [count, count], "Janela %d: o par %d e %d fica empatado." % [window, IDS[i], IDS[j]])


func test_one_or_no_site_is_returned_as_is() -> void:
	assert_eq(SupplyRules.rotated_order([] as Array[int], 5), [] as Array[int])
	assert_eq(SupplyRules.rotated_order([3] as Array[int], 5), [3] as Array[int])
