extends GutTest
## LW-073c: os 100 NPCs sem jogador por 30 dias de jogo, versão LONGA, CONTANDO as recuperações do detector de impasse (LW-073): em vida normal são ZERO (o roadmap pede "sem
## falsos positivos em 30 dias de vida normal"). Fora do tools/check_all porque leva cerca de meio minuto; a versão de 7 dias está em tests/unit/test_impasse.gd, no check_all. Roda
## com `tests/soak/run_npc_impasse_30d`. O nome do arquivo não começa com `test_` de propósito, para o GUT não o achar sozinho ao varrer as pastas. Mesmo mundo do
## `soak_npc_life_30d.gd` (semente 11, dados de res://data, sem corpos e sem personagem): o hash impresso no fim é o mesmo dele, porque o detector não escreve no mundo sem impasse.

const WORLD_SEED: int = 11
const DAYS: int = 30
const HASH_PREFIX_LENGTH: int = 12


func test_thirty_days_of_normal_life_recover_nobody() -> void:
	var data: NpcLifeCheck.GameData = NpcLifeCheck.load_game_data()
	assert_eq(data.problem, "", "Os dados reais do jogo carregam.")
	var setup: NpcSetup = NpcSetup.from_dir(NpcLifeCheck.DATA_DIR, SettlementService.new(data.settlements, data.places))
	var runner: SimulationRunner = SimulationRunner.new(WORLD_SEED)
	var modules: GameModules = GameModules.register(runner, data.terrain, data.points, setup)
	assert_true(modules.result.ok, modules.result.message)
	var heard: Array[NpcImpasseRecovered] = []
	runner.world.context.events.subscribe("NpcImpasseRecovered", func(event: SimEvent) -> void: heard.append(event as NpcImpasseRecovered))
	runner.start_new_game()
	runner.run_days(DAYS)
	print("impasse em %d dias: recuperações %d | registros %d | hash %s" % [DAYS, heard.size(), modules.npc.peek_impasse_records().size(), runner.world.state_hash().substr(0, HASH_PREFIX_LENGTH)])
	assert_eq(runner.world.context.clock.total_minutes(), DAYS * SimClock.MINUTES_PER_DAY, "Trinta dias de jogo.")
	assert_eq(heard.size(), 0, "Nenhum falso positivo em 30 dias de vida normal.")
	assert_eq(modules.npc.peek_impasse_records().size(), 0, "O registro do detector fica vazio.")
	assert_eq(modules.npc.validate().size(), 0, str(modules.npc.validate()))
	runner.finish()
