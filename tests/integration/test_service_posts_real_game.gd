extends GutTest
## LW-095e: os postos de serviço no JOGO REAL (`res://data` inteiro: NPCs, mundo e economia, com `data/economy/service_posts.json`; docs/modules/economy.md, seção 6). Na partida nova, pela hora do jogo novo e pela semente padrão, confere em 2 horas:
## (1) a lista de trabalhadores de cada posto é a que o `npc` informa (o `work_place_id` de cada NPC vivo; o `npc` é o dono do dado e a economia só deriva); (2) a conta do MERCADO paga a folha de cada posto a cada hora, com UM `WagesPaid` por posto e por
## hora e 1 de salário a cada guarda e estalajadeiro; (3) os postos seguem `running` e as conservações do dinheiro e dos bens fecham. A folha que os postos pagam é a soma do `amount_each` vezes os trabalhadores (os mercados também vendem comida nessas horas).

const HOURS: int = 2
const MINUTES_PER_HOUR: int = 60
const POST_PLACES: Array[String] = ["a_work_06", "a_work_07", "b_work_07", "b_work_08", "c_work_04", "c_work_05"]
const WAGE: int = 1
const PAID_WORKERS: int = 30


func test_the_markets_pay_every_guard_and_innkeeper_each_hour_of_the_new_game() -> void:
	var data: NpcLifeCheck.GameData = NpcLifeCheck.load_game_data()
	assert_eq(data.problem, "")
	var npc_setup: NpcSetup = NpcSetup.from_dir("res://data", SettlementService.new(data.settlements, data.places))
	var runner: SimulationRunner = SimulationRunner.new(GameAppNode.DEFAULT_WORLD_SEED, GameAppNode.NEW_GAME_START_MINUTE)
	var modules: GameModules = GameModules.register(runner, data.terrain, data.points, npc_setup, EconomySetup.from_dir(EconomySetup.DEFAULT_DIR), WorldSetup.from_dir("res://data/world", data.settlements))
	runner.start_new_game()
	var economy: EconomyModule = modules.economy
	var post_ids: Dictionary[int, String] = {}
	for place_id: String in POST_PLACES:
		var post: EconomyReplies.PostQuery = economy.peek_post_at(place_id)
		assert_true(post.result.ok, "Há um posto em %s." % place_id)
		post_ids[post.workplace_id] = place_id
	var paid: Array[WagesPaid] = []
	runner.world.context.events.subscribe("WagesPaid", func(event: SimEvent) -> void:
		if post_ids.has((event as WagesPaid).workplace_id):
			paid.append(event))
	for _minute: int in HOURS * MINUTES_PER_HOUR:
		runner.step_once()
	var workers_by_place: Dictionary[String, Array] = {}
	for npc_id: int in modules.npc.peek_npc_ids():
		var npc: NpcModule.NpcQuery = modules.npc.peek_npc(npc_id)
		if npc.is_alive and POST_PLACES.has(npc.work_place_id):
			if not workers_by_place.has(npc.work_place_id):
				workers_by_place[npc.work_place_id] = []
			workers_by_place[npc.work_place_id].append(npc_id)
	var assigned: int = 0
	for place_id: String in POST_PLACES:
		var post: EconomyReplies.PostQuery = economy.peek_post_at(place_id)
		var expected: Array = workers_by_place.get(place_id, [])
		expected.sort()
		assert_eq(Array(post.worker_ids), expected, "%s: a folha do posto é a lista que o `npc` informa." % place_id)
		assert_true(post.running, "%s segue pago." % place_id)
		assigned += post.workers_assigned
	assert_eq(assigned, PAID_WORKERS, "Os 30 guardas e estalajadeiros da população nascem nos postos.")
	assert_eq(paid.size(), HOURS * POST_PLACES.size(), "Um `WagesPaid` por posto e por hora.")
	var payroll: int = 0
	for event: WagesPaid in paid:
		assert_eq(event.amount_each, WAGE)
		payroll += event.amount_each * economy.peek_post(event.workplace_id).workers_assigned
	assert_eq(payroll, HOURS * PAID_WORKERS * WAGE, "A folha dos postos em 2 horas.")
	assert_true(economy.peek_conservation().ok)
	assert_eq(economy.validate(), [] as Array[String])
	runner.world.teardown()
