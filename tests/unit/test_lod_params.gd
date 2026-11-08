extends GutTest
## LW-069: parâmetros do LOD (data/lod_params.json, LodParams e LodParamsLoader), sem janela. Os valores esperados estão ESCRITOS À MÃO a partir
## do envio da tarefa (80 m, 120 m, 50 [HIP]). Arquivos de teste ficam em res://.godot/ (dentro do projeto, fora do Git) e são apagados.

const REAL_DIR: String = "res://data"
const TEMP_ROOT: String = "res://.godot/lw069_lod_params_tests"
const GOOD_ROW: String = '{"id": "lod", "lod_enter_radius_m": 80, "lod_exit_radius_m": 120, "max_s0": 50}'

var _temp_dirs: Array[String] = []


func after_each() -> void:
	for dir_path: String in _temp_dirs:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(dir_path.path_join(LodParamsLoader.DEFAULT_FILE)))
		DirAccess.remove_absolute(ProjectSettings.globalize_path(dir_path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEMP_ROOT))
	_temp_dirs.clear()


## Pasta de teste com um lod_params.json de conteúdo `text`; devolve a pasta.
func _dir_with(text: String) -> String:
	var dir_path: String = "%s/case_%d" % [TEMP_ROOT, _temp_dirs.size()]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir_path))
	var file: FileAccess = FileAccess.open(dir_path.path_join(LodParamsLoader.DEFAULT_FILE), FileAccess.WRITE)
	file.store_string(text)
	file.close()
	_temp_dirs.append(dir_path)
	return dir_path


func _row(overrides: String) -> String:
	return "[%s]" % GOOD_ROW.replace(overrides.get_slice("=>", 0), overrides.get_slice("=>", 1))


func _assert_invalid(text: String, expected_parts: Array[String]) -> void:
	var loaded: LodParamsLoader.LoadResult = LodParamsLoader.load_dir(_dir_with(text))
	assert_false(loaded.result.ok, "Arquivo inválido deveria falhar: " + text)
	assert_eq(loaded.result.code, LodParamsLoader.CODE_INVALID)
	assert_null(loaded.params, "Falha não devolve parâmetros.")
	for part: String in expected_parts:
		assert_string_contains(loaded.result.message, part)


func _assert_valid(text: String) -> LodParams:
	var loaded: LodParamsLoader.LoadResult = LodParamsLoader.load_dir(_dir_with(text))
	assert_true(loaded.result.ok, "Deveria valer: %s -> %s" % [text, loaded.result.message])
	return loaded.params


func test_the_real_file_has_the_agreed_values() -> void:
	var loaded: LodParamsLoader.LoadResult = LodParamsLoader.load_dir(REAL_DIR)
	assert_true(loaded.result.ok, loaded.result.message)
	assert_eq(loaded.params.lod_enter_radius_m, 80)
	assert_eq(loaded.params.lod_exit_radius_m, 120)
	assert_eq(loaded.params.max_s0, 50)
	assert_eq(loaded.params.enter_radius_cm(), 8000)
	assert_eq(loaded.params.exit_radius_cm(), 12000)
	assert_eq(loaded.params.problem(), "")


func test_a_missing_field_an_unknown_field_and_a_wrong_type_are_reported_with_file_item_and_field() -> void:
	_assert_invalid('[{"id": "lod", "lod_enter_radius_m": 80, "max_s0": 50}]', ["lod_params.json", "lod", "lod_exit_radius_m", "campo obrigatório ausente"])
	_assert_invalid(_row('"max_s0": 50=>"max_s0": 50, "color": "red"'), ["lod_params.json", "lod", "color", "campo desconhecido"])
	_assert_invalid(_row('"max_s0": 50=>"max_s0": "cinquenta"'), ["lod_params.json", "lod", "max_s0", "tipo inválido"])
	_assert_invalid(_row('"lod_enter_radius_m": 80=>"lod_enter_radius_m": 80.5'), ["lod_params.json", "lod", "lod_enter_radius_m", "tipo inválido"])


func test_values_out_of_range_are_reported_and_the_range_edges_are_valid() -> void:
	_assert_invalid(_row('"lod_enter_radius_m": 80=>"lod_enter_radius_m": 0'), ["lod_enter_radius_m", "abaixo do mínimo"])
	_assert_invalid(_row('"lod_enter_radius_m": 80=>"lod_enter_radius_m": -5'), ["lod_enter_radius_m", "abaixo do mínimo"])
	_assert_invalid(_row('"lod_exit_radius_m": 120=>"lod_exit_radius_m": 100001'), ["lod_exit_radius_m", "acima do máximo"])
	_assert_invalid(_row('"max_s0": 50=>"max_s0": 0'), ["max_s0", "abaixo do mínimo"])
	_assert_invalid(_row('"max_s0": 50=>"max_s0": 10001'), ["max_s0", "acima do máximo"])
	var smallest: LodParams = _assert_valid('[{"id": "lod", "lod_enter_radius_m": 1, "lod_exit_radius_m": 2, "max_s0": 1}]')
	assert_eq([smallest.lod_enter_radius_m, smallest.lod_exit_radius_m, smallest.max_s0], [1, 2, 1])
	var largest: LodParams = _assert_valid('[{"id": "lod", "lod_enter_radius_m": 99999, "lod_exit_radius_m": 100000, "max_s0": 10000}]')
	assert_eq([largest.lod_enter_radius_m, largest.lod_exit_radius_m, largest.max_s0], [99999, 100000, 10000])


func test_the_exit_radius_must_be_larger_than_the_enter_radius() -> void:
	_assert_invalid(_row('"lod_exit_radius_m": 120=>"lod_exit_radius_m": 80'), ["lod_params.json", "lod", "lod_exit_radius_m", "precisa ser maior", "histerese"])
	_assert_invalid(_row('"lod_exit_radius_m": 120=>"lod_exit_radius_m": 50'), ["lod_exit_radius_m", "precisa ser maior"])
	assert_not_null(_assert_valid(_row('"lod_exit_radius_m": 120=>"lod_exit_radius_m": 81')), "Saída um metro maior que a entrada já vale.")


func test_exactly_one_row_is_required_and_malformed_or_missing_files_are_reported() -> void:
	_assert_invalid("[]", ["lod_params.json", "exatamente 1 linha", "encontradas 0"])
	_assert_invalid("[%s, %s]" % [GOOD_ROW, GOOD_ROW.replace('"id": "lod"', '"id": "lod_two"')], ["lod_params.json", "exatamente 1 linha", "encontradas 2"])
	_assert_invalid("[{", ["lod_params.json", "JSON inválido"])
	var missing: LodParamsLoader.LoadResult = LodParamsLoader.load_dir("res://tests/fixtures/world/pasta_que_nao_existe")
	assert_false(missing.result.ok)
	assert_string_contains(missing.result.message, "lod_params.json")
	assert_string_contains(missing.result.message, "arquivo não encontrado")


func test_params_built_by_hand_report_their_own_problem() -> void:
	assert_eq(LodParams.new(80, 120, 50).problem(), "")
	assert_string_contains(LodParams.new(120, 120, 50).problem(), "precisa ser maior")
	assert_string_contains(LodParams.new(0, 120, 50).problem(), "lod_enter_radius_m")
	assert_string_contains(LodParams.new(80, 200000, 50).problem(), "lod_exit_radius_m")
	assert_string_contains(LodParams.new(80, 120, 0).problem(), "max_s0")
