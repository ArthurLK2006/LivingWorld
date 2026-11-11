class_name RecipeDef
extends RefCounted
## Uma receita (LW-092; `data/economy/recipes.json`, `recipe_inputs.json`, `recipe_outputs.json` e `site_upkeep.json`; docs/modules/economy.md, seção 6), SÓ LEITURA depois de montada: o ofício ESPERADO (a economia não confere o
## ofício de quem trabalha), quantos trabalhadores fazem um lote por hora, o teto de lotes por hora, o salário por hora (pago na LW-095), os insumos e os produtos (bem → quantidade por lote) e as regras de manutenção.
## Receita de EXTRAÇÃO é a que não tem insumo. Valores [HIP] em dados.

var id: String
var name_key: String
var occupation_id: String
var workers_per_batch: int
var max_batches_per_hour: int
var wage_per_hour: int
var inputs: Dictionary[String, int] = {}
var outputs: Dictionary[String, int] = {}
var upkeep: Array[UpkeepRule] = []


func _init(recipe_id: String, recipe_name_key: String, expected_occupation_id: String, workers: int, batches: int, wage: int) -> void:
	id = recipe_id
	name_key = recipe_name_key
	occupation_id = expected_occupation_id
	workers_per_batch = workers
	max_batches_per_hour = batches
	wage_per_hour = wage


func is_extraction() -> bool:
	return inputs.is_empty()
