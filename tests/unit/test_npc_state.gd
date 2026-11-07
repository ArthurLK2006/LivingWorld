extends GutTest
## LW-057: estado do NPC e módulo `npc` (docs/modules/npc.md, seções 1, 10 e 11), sem janela. Os valores esperados estão ESCRITOS À MÃO:
## IDs que nunca voltam, criar e remover, ida e volta de save pelo JSON, entrada no state_hash, recusas com mensagem, validate() e o
## registro do módulo no mundo do jogo (GameModules).

## Terreno de teste pequeno e somente leitura: só serve para montar o mundo do jogo no último teste.
const TERRAIN_DIR: String = "res://tests/fixtures/world/terrain_ok"
const WORLD_SEED: int = 3
const GAME_VERSION: String = "0.0.1-test"
const MAX_SAFE_INTEGER: int = 9007199254740991

var _module: NpcModule
var _world: World


## Mundo de teste com o módulo registrado e já em setup(); quem chama faz o teardown().
func _new_world(module: NpcModule) -> World:
	var clock: SimClock = SimClock.new()
	var world: World = World.new(SimContext.new(clock, EventBus.new(clock), WorldRng.new(WORLD_SEED), IdGenerator.new()))
	assert_true(world.register_module("npc", module).ok)
	world.setup()
	return world


func before_each() -> void:
	_module = NpcModule.new()
	_world = _new_world(_module)


func after_each() -> void:
	_world.teardown()


## Pedido com todos os campos diferentes do padrão, para provar que cada um chega ao estado.
func _full_spec() -> NpcSpec:
	var spec: NpcSpec = NpcSpec.new()
	spec.name_key = "npc.name.villager"
	spec.name_number = 7
	spec.tier = NpcState.TIER_NOTABLE
	spec.traits = PackedInt64Array([10, 90, 50, 0])
	spec.x_cm = 123456
	spec.z_cm = 654321
	spec.settlement_id = "village_a"
	spec.place_id = "home_a_1"
	spec.occupation_id = "farmer"
	spec.home_place_id = "home_a_1"
	spec.work_place_id = "field_a_1"
	return spec


func _basic_spec(number: int) -> NpcSpec:
	var spec: NpcSpec = NpcSpec.new()
	spec.name_key = "npc.name.villager"
	spec.name_number = number
	return spec


func _create(spec: NpcSpec) -> int:
	var created: NpcModule.CreateResult = _module.request_create_npc(spec)
	assert_true(created.result.ok, created.result.message)
	return created.npc_id


func _next_id(world: World) -> int:
	return world.context.ids.debug_summary()["next_id"]


## Registro de save completo, no formato escrito à mão; `overrides` troca campos.
func _entry(overrides: Dictionary = {}) -> Dictionary:
	var entry: Dictionary = {
		"name_key": "npc.name.villager", "name_number": 4, "tier": 1, "is_alive": true, "death_cause": "", "died_at": -1,
		"traits": [50, 50, 50, 50], "need_values": [0, 0, 0, 0, 0], "need_remainders": [0, 0, 0, 0, 0], "needs_updated_at": 0,
		"x_cm": 100, "z_cm": 200, "settlement_id": "", "place_id": "", "occupation_id": "", "home_place_id": "", "work_place_id": "",
		"action_id": "", "action_target_place_id": "", "action_started_at": 0, "action_ends_at": 0, "action_serial": 0,
	}
	for key: String in overrides:
		entry[key] = overrides[key]
	return entry


func _alive_with_action() -> Dictionary:
	return _entry({"name_number": 12, "tier": 2, "traits": [1, 2, 3, 4], "need_values": [100, 55, 3, 0, 77], "need_remainders": [59, 0, 1, 30, 2],
		"needs_updated_at": 4990, "x_cm": 10000000, "z_cm": 6, "settlement_id": "village_a", "place_id": "home_a_1", "occupation_id": "guard",
		"home_place_id": "home_a_1", "work_place_id": "post_a", "action_id": "sleep", "action_target_place_id": "home_a_1",
		"action_started_at": 4000, "action_ends_at": 4480, "action_serial": 9})


func _dead_without_action() -> Dictionary:
	return _entry({"name_number": 3, "is_alive": false, "death_cause": "hunger", "died_at": MAX_SAFE_INTEGER, "occupation_id": "farmer"})


func _json_round_trip(data: Dictionary) -> Dictionary:
	var parsed: Variant = JSON.parse_string(JSON.stringify(data, "", true, true))
	assert_eq(typeof(parsed), TYPE_DICTIONARY, "O JSON voltou como objeto.")
	var restored: Dictionary = parsed
	return restored


func _scripted_hash() -> String:
	var module: NpcModule = NpcModule.new()
	var world: World = _new_world(module)
	module.request_create_npc(_full_spec())
	module.request_create_npc(_basic_spec(2))
	world.context.clock.advance_step()
	var state_hash: String = world.state_hash()
	world.teardown()
	return state_hash


func test_create_gives_increasing_ids_from_the_core_counter() -> void:
	var counter_before: int = _next_id(_world)
	var first: int = _create(_basic_spec(1))
	var second: int = _create(_basic_spec(2))
	assert_eq(first, counter_before, "O ID vem do contador do core (ctx.ids), o mesmo dos personagens.")
	assert_eq(second, first + 1)
	assert_eq(_next_id(_world), counter_before + 2)
	var expected: Array[int] = [first, second]
	assert_eq(_module.peek_npc_ids(), expected)


func test_removed_ids_are_never_reused() -> void:
	var first: int = _create(_basic_spec(1))
	var second: int = _create(_basic_spec(2))
	var third: int = _create(_basic_spec(3))
	assert_true(_module.request_remove_npc(second).ok)
	assert_true(_module.request_remove_npc(third).ok)
	var only_first: Array[int] = [first]
	assert_eq(_module.peek_npc_ids(), only_first)
	var fourth: int = _create(_basic_spec(4))
	assert_gt(fourth, third, "Mesmo removendo o último, o ID novo é maior que todos os já emitidos.")
	assert_false(_module.peek_npc(second).result.ok, "O ID removido continua sem dono.")
	assert_false(_module.peek_npc_ids().has(second))
	assert_true(_module.request_remove_npc(first).ok)
	assert_true(_module.request_remove_npc(fourth).ok)
	assert_eq(_module.peek_counts()[NpcModule.COUNT_TOTAL], 0)
	assert_gt(_create(_basic_spec(5)), fourth, "Com a tabela vazia o ID também não volta.")


func test_created_state_matches_the_request() -> void:
	_world.context.clock.advance_step()
	_world.context.clock.advance_step()
	var npc_id: int = _create(_full_spec())
	var query: NpcModule.NpcQuery = _module.peek_npc(npc_id)
	assert_true(query.result.ok, query.result.message)
	assert_eq(query.npc_id, npc_id)
	assert_eq(query.name_key, "npc.name.villager")
	assert_eq(query.name_number, 7)
	assert_eq(query.tier, 2)
	assert_true(query.is_alive)
	assert_eq(query.death_cause, "")
	assert_eq(query.traits, PackedInt64Array([10, 90, 50, 0]))
	assert_eq(query.need_values, PackedInt64Array([0, 0, 0, 0, 0]))
	assert_eq(query.needs_updated_at, 2, "O minuto da última atualização das necessidades é o relógio da criação.")
	assert_eq(query.x_cm, 123456)
	assert_eq(query.z_cm, 654321)
	assert_eq(query.settlement_id, "village_a")
	assert_eq(query.place_id, "home_a_1")
	assert_eq(query.occupation_id, "farmer")
	assert_eq(query.home_place_id, "home_a_1")
	assert_eq(query.work_place_id, "field_a_1")
	assert_eq(query.action_id, "", "Quem nasce não tem ação atual.")
	assert_eq(query.action_serial, 0)


func test_default_request_gives_a_neutral_tier_1_npc() -> void:
	var query: NpcModule.NpcQuery = _module.peek_npc(_create(_basic_spec(1)))
	assert_eq(query.tier, NpcState.TIER_NORMAL)
	assert_eq(query.traits, PackedInt64Array([50, 50, 50, 50]), "Traços neutros (50) por padrão.")
	assert_eq(query.occupation_id, "")
	assert_eq(query.place_id, "")


func test_invalid_requests_are_refused_without_spending_an_id() -> void:
	var counter_before: int = _next_id(_world)
	var hash_before: String = _world.state_hash()
	var bad_specs: Array[NpcSpec] = []
	for mutation: String in ["empty_name", "blank_name", "negative_number", "tier_0", "tier_3", "traits_3", "traits_5", "trait_high", "trait_low", "x_negative", "x_far", "z_negative", "z_far"]:
		var spec: NpcSpec = _basic_spec(1)
		match mutation:
			"empty_name": spec.name_key = ""
			"blank_name": spec.name_key = "   "
			"negative_number": spec.name_number = -1
			"tier_0": spec.tier = 0
			"tier_3": spec.tier = 3
			"traits_3": spec.traits = PackedInt64Array([50, 50, 50])
			"traits_5": spec.traits = PackedInt64Array([50, 50, 50, 50, 50])
			"trait_high": spec.traits = PackedInt64Array([50, 101, 50, 50])
			"trait_low": spec.traits = PackedInt64Array([50, 50, -1, 50])
			"x_negative": spec.x_cm = -1
			"x_far": spec.x_cm = NpcState.MAX_COORDINATE_CM + 1
			"z_negative": spec.z_cm = -1
			"z_far": spec.z_cm = NpcState.MAX_COORDINATE_CM + 1
		bad_specs.append(spec)
	bad_specs.append(null)
	for bad: NpcSpec in bad_specs:
		var created: NpcModule.CreateResult = _module.request_create_npc(bad)
		assert_false(created.result.ok, "Pedido inválido deveria ser recusado.")
		assert_eq(created.result.code, NpcModule.CODE_INVALID_SPEC)
		assert_eq(created.npc_id, IdGenerator.NO_ID)
	assert_string_contains(_module.request_create_npc(_trait_high_spec()).result.message, "valor 101")
	assert_eq(_next_id(_world), counter_before, "Pedido recusado não gasta ID.")
	assert_eq(_world.state_hash(), hash_before, "Pedido recusado não muda o estado.")
	assert_eq(_module.peek_counts()[NpcModule.COUNT_TOTAL], 0)


func _trait_high_spec() -> NpcSpec:
	var spec: NpcSpec = _basic_spec(1)
	spec.traits = PackedInt64Array([50, 101, 50, 50])
	return spec


func test_boundary_values_are_accepted() -> void:
	var spec: NpcSpec = _basic_spec(0)
	spec.traits = PackedInt64Array([0, 100, 0, 100])
	spec.x_cm = 0
	spec.z_cm = NpcState.MAX_COORDINATE_CM
	var query: NpcModule.NpcQuery = _module.peek_npc(_create(spec))
	assert_eq(query.traits, PackedInt64Array([0, 100, 0, 100]))
	assert_eq(query.z_cm, NpcState.MAX_COORDINATE_CM)
	assert_eq(query.name_number, 0)


func test_commands_fail_before_setup() -> void:
	var without_setup: NpcModule = NpcModule.new()
	var created: NpcModule.CreateResult = without_setup.request_create_npc(_basic_spec(1))
	assert_false(created.result.ok)
	assert_eq(created.result.code, NpcModule.CODE_NOT_READY)
	assert_eq(without_setup.validate().size(), 0, "Sem setup() não há com o que comparar o contador; só não pode quebrar.")


func test_unknown_ids_fail_without_crashing() -> void:
	var known: int = _create(_basic_spec(1))
	for bad_id: int in [0, -1, known + 1, 99999999]:
		var query: NpcModule.NpcQuery = _module.peek_npc(bad_id)
		assert_false(query.result.ok, "peek_npc com ID %d." % bad_id)
		assert_eq(query.result.code, NpcModule.CODE_UNKNOWN)
		assert_string_contains(query.result.message, str(bad_id))
		var removed: Result = _module.request_remove_npc(bad_id)
		assert_eq(removed.code, NpcModule.CODE_UNKNOWN, "request_remove_npc com ID %d." % bad_id)
	assert_eq(_module.peek_counts()[NpcModule.COUNT_TOTAL], 1, "Nada foi removido.")


func test_peek_returns_copies_not_the_internal_state() -> void:
	var npc_id: int = _create(_full_spec())
	var query: NpcModule.NpcQuery = _module.peek_npc(npc_id)
	query.traits[0] = 99
	query.need_values[1] = 99
	query.name_key = "alterado"
	var again: NpcModule.NpcQuery = _module.peek_npc(npc_id)
	assert_eq(again.traits, PackedInt64Array([10, 90, 50, 0]))
	assert_eq(again.need_values, PackedInt64Array([0, 0, 0, 0, 0]))
	assert_eq(again.name_key, "npc.name.villager")
	var ids: Array[int] = _module.peek_npc_ids()
	ids.clear()
	assert_eq(_module.peek_npc_ids().size(), 1, "A lista de IDs devolvida também é cópia.")


func test_counts_by_tier_and_alive() -> void:
	_create(_basic_spec(1))
	_create(_full_spec())
	_create(_basic_spec(3))
	var counts: Dictionary = _module.peek_counts()
	assert_eq(counts[NpcModule.COUNT_TOTAL], 3)
	assert_eq(counts[NpcModule.COUNT_ALIVE], 3)
	assert_eq(counts[NpcModule.COUNT_DEAD], 0)
	assert_eq(counts[NpcModule.COUNT_TIER_NORMAL], 2)
	assert_eq(counts[NpcModule.COUNT_TIER_NOTABLE], 1)


func test_save_round_trip_through_json_keeps_everything_and_the_hash() -> void:
	var created_id: int = _create(_full_spec())
	var loaded_alive: Dictionary = _alive_with_action()
	var loaded_dead: Dictionary = _dead_without_action()
	var raw: Dictionary = _world.serialize()
	raw["modules"]["npc"]["npcs"]["500"] = loaded_alive
	raw["modules"]["npc"]["npcs"]["501"] = loaded_dead
	raw["core"]["ids"]["next_id"] = 600
	var source_module: NpcModule = NpcModule.new()
	var source: World = _new_world(source_module)
	assert_true(source.on_load(raw).ok)
	var other_module: NpcModule = NpcModule.new()
	var other: World = _new_world(other_module)
	var loaded: Result = other.on_load(_json_round_trip(source.serialize()))
	assert_true(loaded.ok, loaded.message)
	assert_eq(other.state_hash(), source.state_hash(), "O hash deve ser igual antes e depois de salvar e carregar.")
	assert_eq(JSON.stringify(other_module.serialize(), "", true, true), JSON.stringify(source_module.serialize(), "", true, true), "Todos os campos voltam iguais.")
	var expected_ids: Array[int] = [created_id, 500, 501]
	assert_eq(other_module.peek_npc_ids(), expected_ids)
	var alive: NpcModule.NpcQuery = other_module.peek_npc(500)
	assert_eq(alive.action_id, "sleep")
	assert_eq(alive.action_ends_at, 4480)
	assert_eq(alive.action_serial, 9)
	assert_eq(alive.need_values, PackedInt64Array([100, 55, 3, 0, 77]))
	assert_eq(alive.x_cm, 10000000)
	var dead: NpcModule.NpcQuery = other_module.peek_npc(501)
	assert_false(dead.is_alive)
	assert_eq(dead.death_cause, "hunger")
	assert_eq(other_module.peek_counts()[NpcModule.COUNT_DEAD], 1)
	assert_eq(_next_id(other), 600, "O contador de IDs também volta do save.")
	assert_eq(other_module.validate().size(), 0, str(other_module.validate()))
	var next_created: NpcModule.CreateResult = other_module.request_create_npc(_basic_spec(9))
	assert_eq(next_created.npc_id, 600, "O ID seguinte continua a sequência.")
	source.teardown()
	other.teardown()


func test_dead_npc_keeps_identity_after_the_round_trip() -> void:
	assert_true(_module.on_load({"npcs": {"5": _dead_without_action()}}).ok)
	var query: NpcModule.NpcQuery = _module.peek_npc(5)
	assert_true(query.result.ok, "O ID do morto continua consultável: quem guarda o ID não tem erro.")
	assert_false(query.is_alive)
	assert_eq(query.death_cause, "hunger")
	assert_eq(query.occupation_id, "farmer")
	assert_true(_module.request_remove_npc(5).ok)


func test_npc_enters_the_state_hash() -> void:
	var empty_hash: String = _world.state_hash()
	assert_true(_world.serialize()["modules"].has("npc"), "O estado do módulo vai no serialize do mundo.")
	var npc_id: int = _create(_basic_spec(1))
	var created_hash: String = _world.state_hash()
	assert_ne(created_hash, empty_hash)
	var other_module: NpcModule = NpcModule.new()
	var other: World = _new_world(other_module)
	var different: NpcSpec = _basic_spec(1)
	different.traits = PackedInt64Array([50, 50, 50, 51])
	assert_true(other_module.request_create_npc(different).result.ok)
	assert_ne(other.state_hash(), created_hash, "Só um traço mudou (o contador de IDs é o mesmo): o estado do NPC entra no hash.")
	other.teardown()
	assert_false(_module.request_create_npc(null).result.ok)
	assert_eq(_world.state_hash(), created_hash, "Comando recusado não muda o hash.")
	assert_true(_module.request_remove_npc(npc_id).ok)
	assert_ne(_world.state_hash(), created_hash, "Remover também muda o hash.")


func test_two_identical_runs_give_the_same_hash() -> void:
	assert_eq(_scripted_hash(), _scripted_hash())


func test_on_load_rejects_invalid_data_and_keeps_the_state() -> void:
	_create(_basic_spec(1))
	var state_before: Dictionary = _module.serialize()
	var cases: Array[Dictionary] = [
		{}, {"npcs": 5}, {"npcs": []}, {"npcs": {"1": 5}}, {"npcs": {"1": []}},
		{"npcs": {"abc": _entry()}}, {"npcs": {"1.5": _entry()}}, {"npcs": {"0": _entry()}}, {"npcs": {"-3": _entry()}},
		{"npcs": {"9007199254740992": _entry()}}, {"npcs": {"1": _entry(), "01": _entry()}},
		{"npcs": {"1": _entry({"tier": "1"})}}, {"npcs": {"1": _entry({"tier": 1.5})}}, {"npcs": {"1": _entry({"x_cm": INF})}},
		{"npcs": {"1": _entry({"is_alive": "sim"})}}, {"npcs": {"1": _entry({"name_key": 5})}},
		{"npcs": {"1": _entry({"traits": [50, 50, 50]})}}, {"npcs": {"1": _entry({"traits": [50, 50, "a", 50]})}},
		{"npcs": {"1": _entry({"traits": 50})}}, {"npcs": {"1": _entry({"need_values": [0, 0, 0, 0]})}},
		{"npcs": {"1": _entry({"need_remainders": [0, 0, 0, 0, 0, 0]})}}, {"npcs": {"1": _entry({"need_values": [0, 0, 0, 0, 0.5]})}},
		{"npcs": {"1": _entry({"died_at": 1.0e300})}},
	]
	for field: String in _entry().keys():
		var missing: Dictionary = _entry()
		missing.erase(field)
		cases.append({"npcs": {"1": missing}})
	for invalid: Dictionary in cases:
		var result: Result = _module.on_load(invalid)
		assert_false(result.ok, "Deveria recusar %s." % [invalid])
		assert_eq(result.code, NpcModule.CODE_INVALID_SAVE)
	assert_eq(_module.serialize(), state_before, "Carga recusada não altera o estado.")
	var missing_tier: Result = _module.on_load({"npcs": {"7": _entry({"tier": "1"})}})
	assert_string_contains(missing_tier.message, "NPC 7")
	assert_string_contains(missing_tier.message, "'tier'")


func test_on_load_accepts_whole_numbers_that_json_gives_as_decimals() -> void:
	var as_decimals: Dictionary = _entry({"tier": 2.0, "x_cm": 150.0, "need_values": [1.0, 2.0, 3.0, 4.0, 5.0]})
	assert_true(_module.on_load({"npcs": {"2": as_decimals}}).ok)
	var query: NpcModule.NpcQuery = _module.peek_npc(2)
	assert_eq(query.tier, 2)
	assert_eq(query.x_cm, 150)
	assert_eq(query.need_values, PackedInt64Array([1, 2, 3, 4, 5]))


func test_validate_is_clean_for_a_normal_world() -> void:
	assert_eq(_module.validate().size(), 0, "Sem NPCs não há problema.")
	_create(_full_spec())
	_create(_basic_spec(2))
	assert_eq(_module.validate().size(), 0, str(_module.validate()))


func test_validate_reports_each_kind_of_problem_with_the_npc_id() -> void:
	for _burned: int in range(10):
		_world.context.ids.next_id()
	var counter: int = _next_id(_world)
	var incoherent: Dictionary = {
		"npcs": {
			"1": _entry({"need_values": [101, 0, 0, 0, 0]}),
			"2": _entry({"need_values": [0, 0, -1, 0, 0]}),
			"3": _entry({"traits": [50, 50, 50, 150]}),
			"4": _entry({"tier": 3}),
			"5": _entry({"tier": 0}),
			"6": _entry({"is_alive": false, "death_cause": "hunger", "died_at": 10, "action_id": "eat"}),
			str(counter + 40): _entry(),
		},
	}
	assert_true(_module.on_load(incoherent).ok, "Faixa e coerência são apontadas por validate(), não recusadas ao carregar.")
	var problems: Array[String] = _module.validate()
	assert_eq(problems.size(), 7, str(problems))
	var joined: String = "\n".join(problems)
	assert_string_contains(joined, "NPC 1: necessidade na posição 0 fora de 0 a 100 (valor 101)")
	assert_string_contains(joined, "NPC 2: necessidade na posição 2 fora de 0 a 100 (valor -1)")
	assert_string_contains(joined, "NPC 3: traço na posição 3 fora de 0 a 100 (valor 150)")
	assert_string_contains(joined, "NPC 4: tier 3 inválido")
	assert_string_contains(joined, "NPC 5: tier 0 inválido")
	assert_string_contains(joined, "NPC 6: morto, mas com ação atual 'eat'")
	assert_string_contains(joined, "NPC %d: ID acima do contador do core" % (counter + 40))
	assert_true(_world.validate().size() >= 7, "O World junta os problemas do módulo, rotulados [npc].")
	assert_string_contains("\n".join(_world.validate()), "[npc] NPC 1:")


func test_debug_summary_counts_and_serialize_size() -> void:
	var farmer: NpcSpec = _full_spec()
	farmer.name_number = 1
	_create(farmer)
	var second_farmer: NpcSpec = _full_spec()
	second_farmer.tier = NpcState.TIER_NORMAL
	_create(second_farmer)
	_create(_basic_spec(3))
	var summary: Dictionary = _module.debug_summary()
	assert_eq(summary[NpcModule.COUNT_TOTAL], 3)
	assert_eq(summary[NpcModule.COUNT_TIER_NORMAL], 2)
	assert_eq(summary[NpcModule.COUNT_TIER_NOTABLE], 1)
	assert_eq(summary["by_occupation"], {"farmer": 2, "none": 1})
	assert_eq(summary["serialize_bytes"], JSON.stringify(_module.serialize()).to_utf8_buffer().size(), "O tamanho do serialize() em bytes (backlog I4).")
	assert_gt(summary["serialize_bytes"], 0)


func test_the_game_registers_the_npc_module_after_the_character() -> void:
	var loaded: TerrainLoader.LoadResult = TerrainLoader.load_dir(TERRAIN_DIR)
	assert_true(loaded.result.ok, loaded.result.message)
	var original: SimulationRunner = SimulationRunner.new(WORLD_SEED)
	var original_modules: GameModules = GameModules.register(original, loaded.terrain)
	assert_true(original_modules.result.ok, original_modules.result.message)
	assert_eq(GameModules.NPC_NAME, "npc")
	assert_not_null(original_modules.npc)
	original.start_new_game()
	var module_names: Array = original.world.debug_summary()["modules"].keys()
	assert_eq(module_names, [GameModules.CHARACTER_NAME, GameModules.NPC_NAME], "O npc é registrado depois do character.")
	var hash_empty: String = original.world.state_hash()
	var created: NpcModule.CreateResult = original_modules.npc.request_create_npc(_full_spec())
	assert_true(created.result.ok, created.result.message)
	assert_ne(original.world.state_hash(), hash_empty, "O NPC do mundo do jogo entra no state_hash.")
	original.run_steps(30)
	var codec: JsonSaveCodec = JsonSaveCodec.new()
	assert_true(original.can_capture_game())
	var decoded: DecodedSave = codec.decode(codec.encode(original.capture_game(), GAME_VERSION))
	assert_true(decoded.result.ok, decoded.result.message)
	assert_true(decoded.payload["world"]["modules"].has("npc"), "O módulo está no save do jogo.")
	assert_eq(decoded.save_version, JsonSaveCodec.CURRENT_SAVE_VERSION, "A versão do save não mudou (Q17).")
	var restored: SimulationRunner = SimulationRunner.new(WORLD_SEED)
	var restored_modules: GameModules = GameModules.register(restored, loaded.terrain)
	assert_true(restored_modules.result.ok, restored_modules.result.message)
	var reloaded: Result = restored.load_game(decoded.payload)
	assert_true(reloaded.ok, reloaded.message)
	assert_eq(restored.world.state_hash(), original.world.state_hash(), "O mundo carregado tem o hash do salvamento.")
	var after: NpcModule.NpcQuery = restored_modules.npc.peek_npc(created.npc_id)
	assert_true(after.result.ok, after.result.message)
	assert_eq(after.occupation_id, "farmer")
	assert_eq(restored.world.validate().size(), 0, str(restored.world.validate()))
	original.finish()
	restored.finish()
