extends GutTest
## LW-088d (revisão independente da A, I1 e I3): o `debug_summary()` do `EconomyModule` (donos, soma dos saldos, dinheiro criado e destruído, conservação do dinheiro e dos bens, locais de produção) e a conferência do TIPO do dono
## contra `owner_kinds.json` ao carregar um save e no `validate()` (AGENTS 12.6). Usa os dados REAIS (data/economy): os mercados A e B levam os IDs 1 e 2 (3000 de saldo cada) e, com um local de produção, ele leva o ID 3 (5000).

const SEED: int = 59
const SETTLEMENT_A: String = "test_settlement_a"


func _definitions(with_site: bool = false) -> EconomyDefinitions:
	var setup: EconomySetup = EconomySetup.from_dir(EconomySetup.DEFAULT_DIR)
	assert_true(setup.result.ok, setup.result.message)
	var definitions: EconomyDefinitions = setup.definitions
	if with_site:
		var sites: Array[SiteDef] = [SiteDef.new("site_bread", SETTLEMENT_A, "a_work_01", "bake_bread", 4)]
		definitions.production_sites = sites
		for kind: OwnerKindDef in definitions.kinds:
			if kind.id == ProductionBook.KIND_SITE:
				kind.initial_balance = 5000
	return definitions


func _world(module: EconomyModule) -> World:
	var clock: SimClock = SimClock.new()
	var world: World = World.new(SimContext.new(clock, EventBus.new(clock), WorldRng.new(SEED), IdGenerator.new()))
	assert_true(world.register_module("economy", module).ok)
	world.setup()
	world.post_setup()
	world.on_new_game(SEED)
	return world


func _through_json(data: Dictionary) -> Dictionary:
	# Variant: o JSON devolve qualquer tipo; aqui o formato é conhecido (um objeto).
	var parsed: Variant = JSON.parse_string(JSON.stringify(data))
	assert_eq(typeof(parsed), TYPE_DICTIONARY)
	var copy: Dictionary = parsed
	return copy


func test_the_debug_summary_shows_the_accounts_the_conservation_and_the_sites_without_changing_anything() -> void:
	assert_eq(EconomyModule.new().debug_summary(), {"owners": 0, "balances_sum": 0, "money_created": 0, "money_destroyed": 0, "money_conserved": true, "goods_conserved": true, "production_sites": 0}, "Sem nada aberto, tudo zero e a conservação fecha.")
	var module: EconomyModule = EconomyModule.new(false, _definitions())
	var world: World = _world(module)
	var before: Dictionary = module.serialize()
	assert_eq(module.debug_summary(), {"owners": 2, "balances_sum": 6000, "money_created": 6000, "money_destroyed": 0, "money_conserved": true, "goods_conserved": true, "production_sites": 0}, "Dois mercados de 3000 e nenhum local de produção nos dados reais.")
	assert_eq(module.serialize(), before, "O resumo só olha: o estado fica igual.")
	assert_true(module.request_open_owner(100, "npc").ok)
	assert_eq(module.debug_summary()["owners"], 3, "O resumo acompanha o cadastro.")
	world.teardown()
	var with_site: EconomyModule = EconomyModule.new(false, _definitions(true))
	var site_world: World = _world(with_site)
	assert_eq(with_site.debug_summary(), {"owners": 3, "balances_sum": 11000, "money_created": 11000, "money_destroyed": 0, "money_conserved": true, "goods_conserved": true, "production_sites": 1}, "O local de produção entra: o dono 3, com 5000.")
	site_world.teardown()


func test_a_save_with_an_owner_kind_that_is_not_in_the_data_is_refused_and_changes_nothing() -> void:
	var module: EconomyModule = EconomyModule.new(false, _definitions())
	var world: World = _world(module)
	var saved: Dictionary = _through_json(module.serialize())
	var restored: EconomyModule = EconomyModule.new(false, _definitions())
	assert_true(restored.on_load(saved).ok, "O save de verdade carrega.")
	var before: Dictionary = restored.serialize()
	var bad: Dictionary = saved.duplicate(true)
	bad["owners"]["1"]["kind"] = "wizard"
	var result: Result = restored.on_load(bad)
	assert_false(result.ok)
	assert_eq(result.code, EconomyCodes.INVALID_SAVE)
	assert_string_contains(result.message, "dono 1: o tipo 'wizard' não existe em owner_kinds.json")
	assert_eq(restored.serialize(), before, "Recusado, o módulo continua como estava.")
	var bare: EconomyModule = EconomyModule.new()
	assert_true(bare.request_open_owner(5, "wizard").ok, "Sem tipos nas definições qualquer tipo vale, como na abertura de conta.")
	var loaded: EconomyModule = EconomyModule.new()
	assert_true(loaded.on_load(bare.serialize()).ok and loaded.validate().is_empty(), "E o save com ele carrega e valida.")
	world.teardown()


func test_validate_finds_an_owner_whose_kind_left_the_data() -> void:
	var definitions: EconomyDefinitions = _definitions()
	var module: EconomyModule = EconomyModule.new(false, definitions)
	var world: World = _world(module)
	assert_true(module.request_open_owner(100, "npc").ok)
	assert_eq(module.validate(), [] as Array[String])
	var remaining: Array[OwnerKindDef] = []
	for kind: OwnerKindDef in definitions.kinds:
		if kind.id != "npc":
			remaining.append(kind)
	definitions.kinds = remaining
	var problems: Array[String] = module.validate()
	assert_eq(problems.size(), 1)
	assert_string_contains(problems[0], "[owners] dono 100: o tipo 'npc' não existe em owner_kinds.json")
	world.teardown()
