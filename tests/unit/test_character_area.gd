extends GutTest
## ART-12, entrega 7a: a área controlada das figuras inteiras (`CharacterArea`). Tudo em MEMÓRIA, pelo leitor injetável, com os caminhos reais só como nomes: o arquivo LOCAL de Arthur (art_samples/character_area.json), se existir, NUNCA é lido, e nada toca `user://`; a única leitura de disco é a do dado padrão do repositório, `DEFAULT_PATH`, sozinho na lista. O padrão é a área vazia e sem falha; o arquivo local vale no lugar do padrão se existir (e o padrão nem é lido); se o local for inválido a área é vazia com a falha e NÃO cai no padrão; arquivo ausente, vazio ou em branco conta como ausente; todo arquivo inválido (versão, campo desconhecido, mais de uma entrada, npc_id repetido, negativo, fracionário, fora da faixa ou que não é número, figure vazio ou que não é texto, JSON malformado) vira falha tratada com arquivo, item e campo e área vazia; caminho que não é res:// ou tem `..` é recusado sem ler.

const DEFAULT: String = CharacterArea.DEFAULT_PATH
const LOCAL: String = CharacterArea.LOCAL_PATH
const EMPTY: String = '{"version": 1, "entries": []}'
const NPC_7: String = '{"version": 1, "entries": [{"npc_id": 7, "figure": "ice"}]}'
const NPC_9: String = '{"version": 1, "entries": [{"npc_id": 9, "figure": "guarda"}]}'
const HEAD: String = '{"version": 1, "entries": ['
## [descrição, texto do arquivo, item esperado na falha ("" = sem item), campo esperado ("" = sem campo)].
const INVALID: Array = [
	["versão errada", '{"version": 2, "entries": []}', "", "version"],
	["versão ausente", '{"entries": []}', "", "version"],
	["campo desconhecido na raiz", '{"version": 1, "entries": [], "extra": 1}', "", "extra"],
	["entries ausente", '{"version": 1}', "", "entries"],
	["entries que não é lista", '{"version": 1, "entries": {}}', "", "entries"],
	["entrada que não é objeto", HEAD + "5]}", "entries[0]", ""],
	["campo desconhecido na entrada", HEAD + '{"npc_id": 1, "figure": "ice", "cor": "azul"}]}', "entries[0]", "cor"],
	["mais de uma entrada", HEAD + '{"npc_id": 1, "figure": "ice"}, {"npc_id": 2, "figure": "ice"}]}', "", "entries"],
	["npc_id repetido", HEAD + '{"npc_id": 1, "figure": "ice"}, {"npc_id": 1, "figure": "ice"}]}', "entries[1]", "npc_id"],
	["npc_id negativo", HEAD + '{"npc_id": -1, "figure": "ice"}]}', "entries[0]", "npc_id"],
	["npc_id fracionário", HEAD + '{"npc_id": 1.5, "figure": "ice"}]}', "entries[0]", "npc_id"],
	["npc_id acima do máximo", HEAD + '{"npc_id": 1000001, "figure": "ice"}]}', "entries[0]", "npc_id"],
	["npc_id que é texto", HEAD + '{"npc_id": "1", "figure": "ice"}]}', "entries[0]", "npc_id"],
	["npc_id ausente", HEAD + '{"figure": "ice"}]}', "entries[0]", "npc_id"],
	["figure vazio", HEAD + '{"npc_id": 1, "figure": ""}]}', "entries[0]", "figure"],
	["figure que é número", HEAD + '{"npc_id": 1, "figure": 5}]}', "entries[0]", "figure"],
	["figure ausente", HEAD + '{"npc_id": 1}]}', "entries[0]", "figure"],
	["JSON malformado", '{"version": 1, "entries": [', "", ""],
	["raiz que não é objeto", "[]", "", ""],
]

var _asked: PackedStringArray = PackedStringArray()


## O leitor injetado: `files` (caminho -> texto); o que não está lá "não existe" (""). Anota cada caminho pedido em `_asked`.
func _reader(files: Dictionary) -> Callable:
	return func(path: String) -> String:
		_asked.append(path)
		return files.get(path, "")


## A área de UM arquivo com `text` no caminho padrão.
func _area(text: String) -> CharacterArea:
	return CharacterArea.from_files([DEFAULT], _reader({DEFAULT: text}))


func _load(files: Dictionary) -> CharacterArea:
	_asked.clear()
	return CharacterArea.load_default(_reader(files))


func test_the_default_is_an_empty_area_without_failure() -> void:
	var area: CharacterArea = _area(EMPTY)
	assert_true(area.is_empty(), "sem entradas")
	assert_eq(area.failure, "", "sem falha")
	assert_eq(area.figure_for(0), "", "ninguém tem figura")


func test_the_default_data_file_of_the_repository_is_the_valid_empty_area() -> void:
	assert_eq(JSON.parse_string(FileAccess.get_file_as_string(DEFAULT)), {"version": 1.0, "entries": []}, "o dado padrão existe e é a área vazia (o JSON entrega todo número como real)")
	var area: CharacterArea = CharacterArea.from_files([DEFAULT])
	assert_true(area.is_empty() and area.failure.is_empty(), "lido do disco pelo leitor padrão: vazio e sem falha: " + area.failure)


func test_one_valid_entry_gives_that_npc_its_figure_and_nobody_else() -> void:
	var area: CharacterArea = _area(NPC_7)
	assert_false(area.is_empty(), "tem uma entrada")
	assert_eq(area.failure, "", "sem falha")
	assert_eq(area.figure_for(7), "ice", "o NPC 7 tem a figura ice")
	for other: int in [0, 6, 8, -1, CharacterArea.MAX_NPC_ID]:
		assert_eq(area.figure_for(other), "", "o NPC %d segue cápsula" % other)


func test_a_missing_empty_or_blank_file_is_an_empty_area_without_failure() -> void:
	for text: String in ["", "  \n\t "]:
		var area: CharacterArea = _area(text)
		assert_true(area.is_empty() and area.failure.is_empty(), "arquivo vazio ou em branco: ausente")
	_asked.clear()
	var absent: CharacterArea = CharacterArea.from_files([DEFAULT, LOCAL], _reader({}))
	assert_true(absent.is_empty() and absent.failure.is_empty(), "nenhum arquivo existe: vazia, sem falha")
	assert_eq(" ".join(_asked), DEFAULT + " " + LOCAL, "pediu os dois, na ordem")
	assert_true(CharacterArea.from_files([], _reader({})).is_empty(), "lista de caminhos vazia")


func test_every_invalid_file_is_a_handled_failure_with_file_item_and_field_and_an_empty_area() -> void:
	for row: Array in INVALID:
		var area: CharacterArea = _area(row[1])
		var why: String = "%s: %s" % [row[0], area.failure]
		assert_true(area.is_empty() and area.figure_for(1) == "" and area.figure_for(2) == "", "área vazia (" + why + ")")
		assert_true(area.failure.begins_with(DEFAULT), "cita o arquivo (" + why + ")")
		assert_true(row[2] == "" or area.failure.contains("item '%s'" % row[2]), "cita o item (" + why + ")")
		assert_true(row[3] == "" or area.failure.contains("campo '%s'" % row[3]), "cita o campo (" + why + ")")


func test_the_local_file_wins_over_the_default_and_the_default_is_not_even_read() -> void:
	var area: CharacterArea = _load({LOCAL: NPC_7, DEFAULT: NPC_9})
	assert_eq(area.figure_for(7), "ice", "vale o local")
	assert_eq(area.figure_for(9), "", "e não o padrão")
	assert_eq(" ".join(_asked), LOCAL, "só o local foi lido")


func test_without_a_local_file_or_with_it_blank_the_default_applies() -> void:
	for files: Dictionary in [{DEFAULT: NPC_9}, {LOCAL: "  \n", DEFAULT: NPC_9}]:
		var area: CharacterArea = _load(files)
		assert_eq(area.figure_for(9), "guarda", "vale o padrão")
		assert_eq(" ".join(_asked), LOCAL + " " + DEFAULT, "perguntou ao local primeiro")


func test_an_invalid_local_file_gives_an_empty_area_with_the_failure_and_does_not_fall_back_to_the_default() -> void:
	var area: CharacterArea = _load({LOCAL: '{"version": 2, "entries": []}', DEFAULT: NPC_9})
	assert_true(area.is_empty(), "área vazia")
	assert_true(area.failure.begins_with(LOCAL) and area.failure.contains("campo 'version'"), "a falha é do local: " + area.failure)
	assert_eq(area.figure_for(9), "", "o padrão NÃO vale em silêncio")
	assert_eq(" ".join(_asked), LOCAL, "o padrão nem é lido")


func test_a_path_outside_res_or_with_a_parent_segment_is_refused_before_reading() -> void:
	for path: String in ["user://area.json", "/tmp/area.json", "area.json", "res://../area.json", "res://a/../area.json", "res://a\\..\\area.json"]:
		_asked.clear()
		var area: CharacterArea = CharacterArea.from_files([path], _reader({path: NPC_7}))
		assert_true(area.is_empty() and _asked.is_empty(), "%s: recusado sem ler" % path)
		assert_true(area.failure.begins_with(path) and area.failure.contains("res://"), "a falha cita o caminho: " + area.failure)
