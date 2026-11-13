extends GutTest

## ARTE-F0, predefinições de luz e de câmera (sem renderizar): os campos e os valores das três predefinições e das três câmeras, e o suporte de efeitos por renderer.


func test_presets_and_views_have_the_expected_fields() -> void:
	assert_eq(RendererPresets.PRESETS.size(), 3, "dia, hora dourada e crepúsculo")
	var fields: Array = RendererPresets.PRESETS[0].keys()
	for key: String in ["sun_color", "sun_energy", "sun_pitch", "ambient_color", "sky_top", "fog_color", "tonemap", "brightness", "glow", "ssao", "dof", "volumetric_density", "lamp", "torch"]:
		assert_true(fields.has(key), "campo %s" % key)
	for preset: Dictionary in RendererPresets.PRESETS:
		assert_eq(preset.keys(), fields, "as três predefinições têm os mesmos campos, na mesma ordem")
	assert_between(float(RendererPresets.PRESETS[0]["sun_pitch"]), 45.0, 60.0, "sol do dia alto")
	assert_between(float(RendererPresets.PRESETS[1]["sun_pitch"]), 8.0, 15.0, "sol da hora dourada baixo")
	assert_lt(float(RendererPresets.PRESETS[2]["sun_pitch"]), 8.0, "sol do crepúsculo muito baixo")
	assert_eq(float(RendererPresets.PRESETS[0]["lamp"]), 0.0, "lampiões apagados de dia")
	assert_gt(float(RendererPresets.PRESETS[1]["lamp"]), 0.0, "lampiões acesos na hora dourada")
	assert_gt(float(RendererPresets.PRESETS[2]["torch"]), 0.0, "tochas acesas no crepúsculo")
	assert_eq(RendererPresets.VIEWS.size(), 3, "próxima, isométrica e estratégica")
	assert_eq([RendererPresets.VIEWS[0]["distance"], RendererPresets.VIEWS[1]["distance"], RendererPresets.VIEWS[2]["distance"]], [5.0, 22.0, 60.0], "distâncias")
	assert_eq([RendererPresets.VIEWS[0]["pitch"], RendererPresets.VIEWS[1]["pitch"], RendererPresets.VIEWS[2]["pitch"]], [12.0, 50.0, 70.0], "ângulos")


func test_effects_follow_the_renderer_support() -> void:
	var full: Dictionary[StringName, bool] = RendererPresets.supported_effects("forward_plus")
	var none: Dictionary[StringName, bool] = RendererPresets.supported_effects("dummy")
	for effect: StringName in RendererPresets.EFFECTS:
		assert_true(full[effect], "Forward+ aceita %s" % effect)
		assert_false(none[effect], "método desconhecido não aceita %s" % effect)
	assert_eq(RendererPresets.supported_effects("gl_compatibility").size(), RendererPresets.EFFECTS.size(), "o Compatibility também tem uma resposta para cada efeito")
