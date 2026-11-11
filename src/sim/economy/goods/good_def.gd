class_name GoodDef
extends RefCounted
## Definição de um bem (LW-089; docs/modules/economy.md, seção 3, e docs/economy/dados.md): conteúdo de `data/economy/goods.json`, SÓ LEITURA depois de montado (o `GoodsLoader` valida e cria). Valor e peso são
## inteiros [HIP] em dados (a calibração é da LW-112). `perishability_days` (0 = não perece) ainda não tem comportamento na Fase 3. `need_id` e `need_relief` só existem no bem de consumo do NPC (o contrato
## manda: `bread` e `grain`): quanto 1 unidade alivia da necessidade, na escala de 0 a 100 do `npc`. A economia NÃO importa o `npc`: `need_id` é só texto, conferido contra as necessidades pelo verificador da LW-093a.

const CATEGORY_FOOD: String = "food"
const CATEGORY_RAW_MATERIAL: String = "raw_material"
const CATEGORY_PROCESSED: String = "processed"
const CATEGORY_TOOL: String = "tool"
## Vocabulário fechado. `weapon`, `luxury` e `magic` são aceitos e RESERVADOS, sem uso na Fase 3 (GDD 12.3).
const CATEGORIES: Array[String] = [CATEGORY_FOOD, CATEGORY_RAW_MATERIAL, CATEGORY_PROCESSED, CATEGORY_TOOL, "weapon", "luxury", "magic"]

var id: String
var name_key: String
var category: String
var base_value: int
var weight: int
var perishability_days: int
var need_id: String
var need_relief: int


func _init(good_id: String, good_name_key: String, good_category: String, value: int, unit_weight: int, days: int, relieved_need_id: String = "", relief: int = 0) -> void:
	id = good_id
	name_key = good_name_key
	category = good_category
	base_value = value
	weight = unit_weight
	perishability_days = days
	need_id = relieved_need_id
	need_relief = relief


## O bem é comida do NPC (alivia uma necessidade)?
func is_consumable() -> bool:
	return not need_id.is_empty()
