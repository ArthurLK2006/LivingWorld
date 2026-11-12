extends GutTest
## LW-095 (item 5 do bloco v11): o carregador dos postos de serviço (`PostLoader`; docs/modules/economy.md, seção 6; docs/economy/dados.md) e a ligação no `EconomySetup`, SEM nenhum dado novo em data/: o arquivo `service_posts.json` é OPCIONAL (sem ele não há posto; o teste desse caso usa uma pasta
## temporária sem o arquivo) e, se existe, é validado com arquivo, item e campo nas mensagens (campos, faixas, texto em branco, um posto por local). `EconomySetup` leva os postos às definições e recusa o local que tem posto e local de produção. Os arquivos de teste ficam numa cópia de
## `data/economy` em `res://.godot/` (cache ignorado pelo Git), nunca no `data/` de verdade.

const SETTLEMENT_A: String = "test_settlement_a"
const TEMP_DIR: String = "res://.godot/lw095_service_post_tests"


func _row(post_id: String, place_id: String = "a_work_06", wanted: int = 8, wage: int = 2) -> Dictionary:
	return {"id": post_id, "settlement_id": SETTLEMENT_A, "place_id": place_id, "occupation_id": "guard", "workers_wanted": wanted, "wage_per_hour": wage}


func _tables(rows: Array[Dictionary]) -> Dictionary[String, Array]:
	var tables: Dictionary[String, Array] = {}
	tables[PostLoader.POSTS_TABLE] = rows
	return tables


## Uma cópia de `data/economy` em `res://.godot/` com `service_posts.json` e, se vier, `production_sites.json` trocados pelas linhas dadas.
func _temp_economy_dir(post_rows: Array[Dictionary], site_rows: Array = []) -> String:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(TEMP_DIR))
	for file_name: String in DirAccess.get_files_at(EconomySetup.DEFAULT_DIR):
		if file_name.ends_with(".json"):
			assert_eq(DirAccess.copy_absolute(EconomySetup.DEFAULT_DIR.path_join(file_name), TEMP_DIR.path_join(file_name)), OK, "Copiou %s." % file_name)
	var posts_file: FileAccess = FileAccess.open(TEMP_DIR.path_join(PostLoader.POSTS_FILE), FileAccess.WRITE)
	posts_file.store_string(JSON.stringify(post_rows))
	posts_file.close()
	if not site_rows.is_empty():
		var sites_file: FileAccess = FileAccess.open(TEMP_DIR.path_join("production_sites.json"), FileAccess.WRITE)
		sites_file.store_string(JSON.stringify(site_rows))
		sites_file.close()
	return TEMP_DIR


func after_each() -> void:
	if DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(TEMP_DIR)):
		for file_name: String in DirAccess.get_files_at(TEMP_DIR):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(TEMP_DIR.path_join(file_name)))
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEMP_DIR))


## R26-I1 (decisão de Arthur de 12/11/2026): a pasta SEM o arquivo é montada numa pasta temporária (`DirAccess.create_temp`), com os demais arquivos de `data/economy` e sem `service_posts.json`, para o teste não depender de o `data/economy` de verdade ter ou não o arquivo.
func test_without_the_file_there_are_no_posts_and_the_real_economy_setup_still_loads() -> void:
	var temp: DirAccess = DirAccess.create_temp("lw095_without_posts")
	assert_not_null(temp, "A pasta temporária foi criada.")
	if temp == null:
		return
	var dir_path: String = temp.get_current_dir()
	for file_name: String in DirAccess.get_files_at(EconomySetup.DEFAULT_DIR):
		if file_name.ends_with(".json") and file_name != PostLoader.POSTS_FILE:
			assert_eq(DirAccess.copy_absolute(EconomySetup.DEFAULT_DIR.path_join(file_name), dir_path.path_join(file_name)), OK, "Copiou %s." % file_name)
	assert_false(FileAccess.file_exists(dir_path.path_join(PostLoader.POSTS_FILE)), "A pasta temporária não tem o arquivo dos postos.")
	var loaded: PostLoader.LoadResult = PostLoader.load_dir(dir_path)
	assert_true(loaded.result.ok, loaded.result.message)
	assert_eq(loaded.posts.size(), 0)
	var setup: EconomySetup = EconomySetup.from_dir(dir_path)
	assert_true(setup.result.ok, setup.result.message)
	assert_eq(setup.definitions.service_posts.size(), 0, "Sem o arquivo as definições não têm posto e o jogo é o de sempre.")
	for file_name: String in DirAccess.get_files_at(dir_path):
		DirAccess.remove_absolute(dir_path.path_join(file_name))


func test_valid_rows_become_post_defs_in_file_order_and_an_empty_table_is_valid() -> void:
	var rows: Array[Dictionary] = [_row("post_a_guard", "a_work_06", 8, 3), _row("post_a_inn", "a_work_07", 6, 2)]
	var loaded: PostLoader.LoadResult = PostLoader.from_tables(_tables(rows), "res://data/economy")
	assert_true(loaded.result.ok, loaded.result.message)
	var first: PostDef = loaded.posts[0]
	assert_eq([loaded.posts.size(), first.id, first.settlement_id, first.place_id, first.occupation_id, first.workers_wanted, first.wage_per_hour], [2, "post_a_guard", SETTLEMENT_A, "a_work_06", "guard", 8, 3])
	assert_eq(loaded.posts[1].place_id, "a_work_07")
	assert_true(PostLoader.from_tables(_tables([] as Array[Dictionary]), "res://data/economy").result.ok)
	var free: PostLoader.LoadResult = PostLoader.from_tables(_tables([_row("post_free", "a_work_06", 1, 0)] as Array[Dictionary]), "res://data/economy")
	assert_true(free.result.ok and free.posts[0].wage_per_hour == 0, "Salário 0 é permitido.")


func test_invalid_rows_are_refused_pointing_at_the_file_the_item_and_the_field() -> void:
	var cases: Array = [
		[_row("post_a_guard", "a_work_06", 0), "workers_wanted"],
		[_row("post_a_guard", "a_work_06", 8, -1), "wage_per_hour"],
		[{"id": "post_a_guard", "settlement_id": SETTLEMENT_A, "place_id": "a_work_06", "workers_wanted": 8, "wage_per_hour": 2}, "occupation_id"],
		[{"id": "post_a_guard", "settlement_id": SETTLEMENT_A, "place_id": "   ", "occupation_id": "guard", "workers_wanted": 8, "wage_per_hour": 2}, "place_id"],
		[{"id": "post_a_guard", "settlement_id": "", "place_id": "a_work_06", "occupation_id": "guard", "workers_wanted": 8, "wage_per_hour": 2}, "settlement_id"],
		[{"id": "post_a_guard", "settlement_id": SETTLEMENT_A, "place_id": "a_work_06", "occupation_id": "guard", "workers_wanted": "oito", "wage_per_hour": 2}, "workers_wanted"],
	]
	for case: Array in cases:
		var rows: Array[Dictionary] = [case[0]]
		var loaded: PostLoader.LoadResult = PostLoader.from_tables(_tables(rows), "res://data/economy")
		assert_false(loaded.result.ok, "Deveria recusar a linha com problema em '%s'." % case[1])
		assert_eq(loaded.result.code, EconomyCodes.DATA_INVALID)
		assert_string_contains(loaded.result.message, "service_posts.json")
		assert_string_contains(loaded.result.message, "post_a_guard")
		assert_string_contains(loaded.result.message, case[1])
		assert_eq(loaded.posts.size(), 0, "Recusado: nenhum posto sai.")
	var twice: PostLoader.LoadResult = PostLoader.from_tables(_tables([_row("post_one", "a_work_06"), _row("post_two", "a_work_06")] as Array[Dictionary]), "res://data/economy")
	assert_false(twice.result.ok)
	assert_string_contains(twice.result.message, "a_work_06")
	assert_string_contains(twice.result.message, "post_one")


func test_a_file_on_disk_is_read_and_the_setup_carries_the_posts_to_the_definitions() -> void:
	var good: EconomySetup = EconomySetup.from_dir(_temp_economy_dir([_row("post_a_guard", "a_work_06", 8, 3)] as Array[Dictionary]))
	assert_true(good.result.ok, good.result.message)
	assert_eq(good.definitions.service_posts.size(), 1)
	assert_eq([good.definitions.service_posts[0].id, good.definitions.service_posts[0].wage_per_hour], ["post_a_guard", 3])
	var bad: EconomySetup = EconomySetup.from_dir(_temp_economy_dir([_row("post_a_guard", "a_work_06", 0)] as Array[Dictionary]))
	assert_false(bad.result.ok, "Arquivo inválido: o setup inteiro falha com a mensagem do carregador.")
	assert_eq(bad.result.code, EconomySetup.CODE_INVALID)
	assert_string_contains(bad.result.message, "workers_wanted")


func test_a_work_place_serves_a_post_or_a_production_site_never_both() -> void:
	var sites: Array[SiteDef] = [SiteDef.new("site_bread", SETTLEMENT_A, "a_work_01", "bake_bread", 4)]
	var apart: Array[PostDef] = [PostDef.new("post_a_guard", SETTLEMENT_A, "a_work_06", "guard", 8, 2)]
	assert_eq(EconomySetup.place_conflict(sites, apart), "", "Locais diferentes: sem conflito.")
	var same: Array[PostDef] = [PostDef.new("post_a_guard", SETTLEMENT_A, "a_work_01", "guard", 8, 2)]
	var conflict: String = EconomySetup.place_conflict(sites, same)
	assert_string_contains(conflict, "a_work_01")
	assert_string_contains(conflict, "site_bread")
	assert_string_contains(conflict, "post_a_guard")
	assert_eq(EconomySetup.place_conflict([] as Array[SiteDef], same), "", "Sem local de produção não há conflito.")
	var site_row: Dictionary = {"id": "site_bread", "settlement_id": SETTLEMENT_A, "place_id": "a_work_06", "recipe_id": "bake_bread", "workers_wanted": 4}
	var clash: EconomySetup = EconomySetup.from_dir(_temp_economy_dir([_row("post_a_guard", "a_work_06", 8, 3)] as Array[Dictionary], [site_row]))
	assert_false(clash.result.ok)
	assert_eq(clash.result.code, EconomySetup.CODE_INVALID)
	assert_string_contains(clash.result.message, "a_work_06")
