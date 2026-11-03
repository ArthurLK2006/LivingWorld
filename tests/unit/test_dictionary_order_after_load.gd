extends GutTest
## Canário de determinismo (LW-029A; achado I1 da LW-029; DEC-081; arquitetura 18.3 e 21.5).
## O módulo-canário guarda estado num Dictionary e usa a ORDEM de visita para repartir sorteios.
## Depois de carregar um save a ordem "natural" muda (o JSON volta com as chaves ordenadas), logo:
## - visitando por chaves ordenadas, salvar e carregar no meio NÃO muda o hash final (teste verde);
## - visitando pela ordem natural, muda: o teste prova que a verificação TEM dentes, isto é, que a
##   divergência é detectada. Se um dia este segundo teste falhar, a verificação deixou de enxergar o erro.
## Módulo novo que guarde um Dictionary deve copiar este modelo (docs/modules/MODELO.md).

const CANARY_SCRIPT: GDScript = preload("res://tests/fixtures/world/dictionary_canary_module.gd")
const GAME_VERSION: String = "0.0.1-test"
const WORLD_SEED: int = 11
const STEPS_BEFORE_SAVE: int = 30
const STEPS_AFTER_LOAD: int = 30


func _new_runner(sorted_iteration: bool) -> SimulationRunner:
	var runner: SimulationRunner = SimulationRunner.new(WORLD_SEED)
	var module: SimModule = CANARY_SCRIPT.new(sorted_iteration)
	assert_true(runner.register_module("canary", module).ok)
	return runner


## Hash do mundo depois de rodar sem nenhuma interrupção.
func _straight_hash(sorted_iteration: bool, steps_before_save: int, steps_after_load: int) -> String:
	var runner: SimulationRunner = _new_runner(sorted_iteration)
	runner.start_new_game()
	runner.run_steps(steps_before_save + steps_after_load)
	var final_hash: String = runner.world.state_hash()
	runner.finish()
	return final_hash


## Hash do mundo quando se salva e se carrega no meio (pelo codec) e se roda o restante.
func _resumed_hash(sorted_iteration: bool, steps_before_save: int, steps_after_load: int) -> String:
	var first: SimulationRunner = _new_runner(sorted_iteration)
	first.start_new_game()
	first.run_steps(steps_before_save)
	var codec: JsonSaveCodec = JsonSaveCodec.new()
	var decoded: DecodedSave = codec.decode(codec.encode(first.capture_game(), GAME_VERSION))
	first.finish()
	assert_true(decoded.result.ok, decoded.result.message)
	var second: SimulationRunner = _new_runner(sorted_iteration)
	var loaded: Result = second.load_game(decoded.payload)
	assert_true(loaded.ok, loaded.message)
	second.run_steps(steps_after_load)
	var final_hash: String = second.world.state_hash()
	second.finish()
	return final_hash


func test_sorted_iteration_gives_the_same_hash_with_or_without_saving_in_the_middle() -> void:
	var resumed: String = _resumed_hash(true, STEPS_BEFORE_SAVE, STEPS_AFTER_LOAD)
	var straight: String = _straight_hash(true, STEPS_BEFORE_SAVE, STEPS_AFTER_LOAD)
	assert_eq(resumed, straight, "Visitando por chaves ordenadas, salvar e carregar no meio não pode mudar o hash final.")


func test_natural_order_iteration_is_caught_by_the_same_comparison() -> void:
	var resumed: String = _resumed_hash(false, STEPS_BEFORE_SAVE, STEPS_AFTER_LOAD)
	var straight: String = _straight_hash(false, STEPS_BEFORE_SAVE, STEPS_AFTER_LOAD)
	assert_ne(resumed, straight, "O canário tem de acusar a visita pela ordem natural do Dictionary; se não acusar, a verificação perdeu os dentes.")


## Caso-limite 1: sem nenhum passo depois de carregar a ordem ainda não foi usada, então até a visita
## natural coincide. A divergência só aparece quando a ordem é consumida.
func test_without_any_step_after_loading_both_orders_still_match() -> void:
	var resumed: String = _resumed_hash(false, STEPS_BEFORE_SAVE, 0)
	var straight: String = _straight_hash(false, STEPS_BEFORE_SAVE, 0)
	assert_eq(resumed, straight, "Sem passos depois de carregar, o estado salvo e o estado carregado têm de ser iguais.")


## Caso-limite 2: salvar antes do primeiro passo (minuto 0). A regra vale desde o começo.
func test_saving_before_the_first_step_follows_the_same_rule() -> void:
	var sorted_is_stable: bool = _resumed_hash(true, 0, STEPS_AFTER_LOAD) == _straight_hash(true, 0, STEPS_AFTER_LOAD)
	var natural_is_stable: bool = _resumed_hash(false, 0, STEPS_AFTER_LOAD) == _straight_hash(false, 0, STEPS_AFTER_LOAD)
	assert_true(sorted_is_stable, "Visitando por chaves ordenadas o hash tem de coincidir, mesmo salvando no minuto 0.")
	assert_false(natural_is_stable, "Visitando pela ordem natural o hash tem de divergir, mesmo salvando no minuto 0.")


## Caso de erro: dado inválido é recusado e o estado do módulo não muda.
func test_canary_rejects_invalid_save_data_without_changing_its_state() -> void:
	var module: SimModule = CANARY_SCRIPT.new(true)
	var before: Dictionary = module.serialize()
	var missing: Result = module.on_load({})
	assert_false(missing.ok)
	assert_eq(missing.code, "CANARY_INVALID_SAVE")
	var wrong_keys: Result = module.on_load({"entries": {"npc_99": 1}})
	assert_false(wrong_keys.ok)
	assert_eq(wrong_keys.code, "CANARY_INVALID_SAVE")
	var fractional: Result = module.on_load({"entries": {"npc_30": 1.5, "npc_10": 0, "npc_50": 0, "npc_20": 0, "npc_40": 0}})
	assert_false(fractional.ok)
	assert_eq(fractional.code, "CANARY_INVALID_SAVE")
	assert_eq(module.serialize(), before, "Carga recusada não pode alterar o estado.")
