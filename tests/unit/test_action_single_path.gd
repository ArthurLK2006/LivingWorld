extends GutTest
## LW-060: a "função única" de efeitos de ação (docs/modules/npc.md, seção 3). Varredura dos .gd de src/sim/npc/ (sem mexer em
## tools/check_architecture): SÓ o ActionRunner define e chama `apply_effects`; as linhas de efeito do catálogo (`.effects`) só são
## lidas pelo ActionRunner (aplica), pelo carregador (monta) e pela definição (declara); e o runner não sorteia. Um controle prova que a
## própria varredura enxerga uma violação (sem ele o teste poderia passar vazio).

const NPC_DIR: String = "res://src/sim/npc"
const RUNNER_FILE: String = "action_runner.gd"
const EFFECT_ROW_FILES: Array[String] = ["action_runner.gd", "action_catalog_loader.gd", "action_def.gd"]
const APPLY_CALL_PATTERN: String = "apply_effects\\("
const APPLY_DEFINITION_PATTERN: String = "func\\s+apply_effects\\("
const EFFECT_ROWS_PATTERN: String = "\\.effects\\b"
const DICE_PATTERN: String = "\\b(rng|randi|randf|randi_range|randf_range|shuffle|pick_random)\\b"


## Todos os .gd abaixo da pasta, com caminho completo (ordem fixa).
func _gd_files(dir_path: String) -> Array[String]:
	var found: Array[String] = []
	var files: PackedStringArray = DirAccess.get_files_at(dir_path)
	for file_name: String in files:
		if file_name.ends_with(".gd"):
			found.append(dir_path.path_join(file_name))
	var folders: PackedStringArray = DirAccess.get_directories_at(dir_path)
	for folder: String in folders:
		found.append_array(_gd_files(dir_path.path_join(folder)))
	found.sort()
	return found


## Só as linhas de código: linha inteira de comentário e o que vem depois de um `#` não contam.
func _code_of(text: String) -> String:
	var kept: PackedStringArray = PackedStringArray()
	for line: String in text.split("\n"):
		var cut: int = line.find("#")
		var code: String = line if cut < 0 else line.substr(0, cut)
		if not code.strip_edges().is_empty():
			kept.append(code)
	return "\n".join(kept)


func _count(pattern: String, text: String) -> int:
	return RegEx.create_from_string(pattern).search_all(text).size()


func _file_name(path: String) -> String:
	return path.get_file()


## Arquivos (só o nome) cujo código casa o padrão, mais a contagem total.
func _files_matching(pattern: String, sources: Dictionary) -> Array[String]:
	var names: Array[String] = []
	for path: String in sources:
		if _count(pattern, sources[path]) > 0:
			names.append(_file_name(path))
	return names


func _read_sources() -> Dictionary:
	var sources: Dictionary = {}
	for path: String in _gd_files(NPC_DIR):
		sources[path] = _code_of(FileAccess.get_file_as_string(path))
	return sources


func test_the_scan_really_reads_the_npc_files() -> void:
	var sources: Dictionary = _read_sources()
	assert_gt(sources.size(), 10, "A varredura precisa enxergar os arquivos do `npc` (senão o teste passaria vazio).")
	var names: Array[String] = []
	for path: String in sources:
		names.append(_file_name(path))
	for expected: String in [RUNNER_FILE, "npc_module.gd", "need_math.gd", "action_catalog_loader.gd"]:
		assert_true(names.has(expected), "Faltou %s na varredura." % expected)


func test_only_the_action_runner_defines_and_calls_apply_effects() -> void:
	var sources: Dictionary = _read_sources()
	assert_eq(_files_matching(APPLY_DEFINITION_PATTERN, sources), [RUNNER_FILE] as Array[String], "Só o ActionRunner define a função de efeitos.")
	var definitions: int = 0
	var calls: int = 0
	for path: String in sources:
		definitions += _count(APPLY_DEFINITION_PATTERN, sources[path])
		calls += _count(APPLY_CALL_PATTERN, sources[path])
	assert_eq(definitions, 1, "Existe uma única função de efeitos.")
	assert_gt(calls, definitions, "O ActionRunner a chama (a contagem de `apply_effects(` inclui a definição).")
	assert_eq(_files_matching(APPLY_CALL_PATTERN, sources), [RUNNER_FILE] as Array[String], "Nenhum outro arquivo chama a função de efeitos.")


func test_effect_rows_are_read_only_by_the_runner_the_loader_and_the_definition() -> void:
	var sources: Dictionary = _read_sources()
	var readers: Array[String] = _files_matching(EFFECT_ROWS_PATTERN, sources)
	assert_gt(readers.size(), 0)
	for reader: String in readers:
		assert_true(EFFECT_ROW_FILES.has(reader), "%s mexe nas linhas de efeito do catálogo, o que só o runner, o carregador e a definição podem." % reader)
	assert_true(readers.has(RUNNER_FILE), "O ActionRunner lê as linhas de efeito para aplicá-las.")


func test_the_runner_never_rolls_dice() -> void:
	var runner_path: String = NPC_DIR.path_join("actions").path_join(RUNNER_FILE)
	var code: String = _code_of(FileAccess.get_file_as_string(runner_path))
	assert_gt(code.length(), 0, "O arquivo do runner foi lido.")
	assert_eq(_count(DICE_PATTERN, code), 0, "Efeitos de ação não têm sorteio (a equivalência abstrato x corpóreo da LW-075 depende disso).")


func test_control_the_scan_flags_a_second_caller_and_ignores_comments() -> void:
	var violating: Dictionary = {
		"res://x/action_runner.gd": _code_of("func apply_effects(a: int) -> void:\n\tpass\nfunc advance() -> void:\n\tapply_effects(1)"),
		"res://x/other_module.gd": _code_of("func tick() -> void:\n\tvar r := runner.apply_effects(1, 2, 3, 4)"),
		"res://x/innocent.gd": _code_of("## chamar apply_effects(1) só pelo runner\nvar a: int = 1 # apply_effects(2)\nfunc ok() -> void:\n\tpass"),
	}
	assert_eq(_files_matching(APPLY_CALL_PATTERN, violating), ["action_runner.gd", "other_module.gd"] as Array[String], "A varredura acusa o segundo chamador e ignora comentários.")
	var row_reader: Dictionary = {"res://x/utility.gd": _code_of("for effect in action.effects:\n\tpass")}
	assert_eq(_files_matching(EFFECT_ROWS_PATTERN, row_reader), ["utility.gd"] as Array[String], "A varredura acusa quem lê as linhas de efeito.")
	assert_eq(_count(DICE_PATTERN, _code_of("var n := rng.range_int(\"x\", 0, 1)")), 1, "A varredura acusa sorteio.")
