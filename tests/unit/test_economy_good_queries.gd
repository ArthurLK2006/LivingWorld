extends GutTest
## LW-093 (parte 4): as consultas `peek_good` e `peek_goods_for_need` da economia (docs/modules/economy.md, seção 10; acréscimo de contrato autorizado por Arthur): o `npc` valoriza comida pelo alívio sem importar `GoodDef`. Dados REAIS
## (data/economy): `bread` alivia 60 de `hunger` (valor-base 10, peso 1), `grain` 30 (valor-base 4, peso 2); `tool` não é comida.


func _module() -> EconomyModule:
	var setup: EconomySetup = EconomySetup.from_dir(EconomySetup.DEFAULT_DIR)
	assert_true(setup.result.ok, setup.result.message)
	return EconomyModule.new(false, setup.definitions)


func test_a_good_sheet_gives_the_relief_and_the_numbers_as_a_copy() -> void:
	var module: EconomyModule = _module()
	var bread: EconomyReplies.GoodQuery = module.peek_good("bread")
	assert_true(bread.result.ok, bread.result.message)
	assert_eq([bread.good_id, bread.need_id, bread.need_relief, bread.base_value, bread.weight], ["bread", "hunger", 60, 10, 1])
	var tool: EconomyReplies.GoodQuery = module.peek_good("tool")
	assert_eq([tool.result.ok, tool.need_id, tool.need_relief], [true, "", 0], "Ferramenta existe, mas não alivia necessidade nenhuma.")
	bread.need_relief = 999
	assert_eq(module.peek_good("bread").need_relief, 60, "A resposta é uma cópia: mudar a cópia não muda a economia.")
	assert_eq(module.peek_good("gold").result.code, EconomyCodes.UNKNOWN_GOOD)
	assert_eq(EconomyModule.new().peek_good("bread").result.code, EconomyCodes.UNKNOWN_GOOD, "Sem definições não há bem nenhum.")


func test_the_goods_that_relieve_a_need_come_by_id() -> void:
	var module: EconomyModule = _module()
	var food: EconomyReplies.GoodsQuery = module.peek_goods_for_need("hunger")
	var ids: Array[String] = []
	for good: EconomyReplies.GoodQuery in food.goods:
		ids.append(good.good_id)
	assert_eq(ids, ["bread", "grain"] as Array[String], "Só a comida, por id crescente.")
	assert_eq([food.goods[0].need_relief, food.goods[1].need_relief], [60, 30])
	assert_eq(module.peek_goods_for_need("rest").goods.size(), 0, "Nenhum bem alivia o descanso.")
	assert_eq(module.peek_goods_for_need("").goods.size(), 0, "Necessidade vazia não casa com os bens sem necessidade.")
