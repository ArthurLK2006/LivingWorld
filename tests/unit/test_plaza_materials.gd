extends GutTest

## ARTE-F0, materiais da praça (sem renderizar): os nomes e a ordem de sempre, os emissivos que emitem luz e o Shader de vento, que é um só e compartilhado pela grama e pelas flores.
const EMISSIVE: Array[StringName] = [&"lantern", &"flame", &"accent_warm", &"accent_cyan"]
const WIND: Array[StringName] = [&"grass", &"flower0", &"flower1", &"flower2"]


func test_materials_are_complete_and_the_wind_ones_share_one_shader() -> void:
	var materials: Dictionary[StringName, Material] = PlazaMaterials.create()
	assert_eq(materials.keys(), [&"solid", &"cloth", &"lantern", &"flame", &"accent_warm", &"accent_cyan", &"grass", &"flower0", &"flower1", &"flower2"], "nomes e ordem de sempre")
	for key: StringName in EMISSIVE:
		assert_true((materials[key] as StandardMaterial3D).emission_enabled, "%s emite luz" % key)
	assert_false((materials[&"solid"] as StandardMaterial3D).emission_enabled, "o sólido não emite")
	var shader: Shader = (materials[&"grass"] as ShaderMaterial).shader
	assert_gt(shader.code.length(), 0, "o shader de vento tem código")
	for key: StringName in WIND:
		assert_same((materials[key] as ShaderMaterial).shader, shader, "%s usa o mesmo Shader" % key)
