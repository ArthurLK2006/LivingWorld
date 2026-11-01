class_name PipelineSchemas
extends RefCounted
## Esquemas dos três tipos de dado de TESTE do spike SP3 (LW-025). Não são conteúdo do jogo.
## As tabelas se referenciam: receitas e ofertas citam bens; ofertas podem citar receitas.


static func build() -> Array[DataSchema]:
	var goods: DataSchema = DataSchema.new("goods", "goods.json")
	goods.add_field("name_key", DataSchema.FieldType.STRING)
	goods.add_field("base_price", DataSchema.FieldType.INT).set_range(1, 1000000)
	goods.add_field("is_tradable", DataSchema.FieldType.BOOL, false)
	var recipes: DataSchema = DataSchema.new("recipes", "recipes.json")
	recipes.add_field("output_good", DataSchema.FieldType.STRING).set_ref("goods")
	recipes.add_field("output_amount", DataSchema.FieldType.INT).set_range(1, 1000)
	recipes.add_field("yield_chance", DataSchema.FieldType.FLOAT).set_range(0.0, 1.0)
	var offers: DataSchema = DataSchema.new("offers", "offers.json")
	offers.add_field("good", DataSchema.FieldType.STRING).set_ref("goods")
	offers.add_field("price_multiplier", DataSchema.FieldType.FLOAT).set_range(0.5, 2.0)
	offers.add_field("source_recipe", DataSchema.FieldType.STRING, false).set_ref("recipes")
	var schemas: Array[DataSchema] = [goods, recipes, offers]
	return schemas
