extends GutTest
## Conversa com o comerciante em viagem (24/11/2026; segue a correção do comerciante-fantasma, `test_merchant_ghost_body.gd`): o NPC que tem caravana na economia (`peek_caravan(id).found`) segue em S0 no mercado de partida, mas já não
## tem corpo na tela; por isso o PEDIDO de conversa (`NpcModule.request_converse` e a ponte `SimBridge.request_converse`) também o RECUSA, com o código `NPC_TALK_BUSY` ("ocupado e não atende"; a chave `npc.talk.busy` já existe) e SEM
## escrever nada (nem estado, nem relação, nem memória, nem cooldown, nem evento). Antes da partida e depois da chegada ele conversa como sempre, quem não é comerciante não muda e o jogo sem economia também não. O jogo real é montado
## como o `GameApp` monta (dados reais, economia e rotas, semente e hora do jogo novo); o jogador nasce pela ponte e fica perto do mercado de partida, com os corpos ligados; a apresentação é um corpo "perfeito" (cumpre cada Intent no fim previsto).

const DATA_DIR: String = "res://data"
const WORLD_DIR: String = "res://data/world"
const MERCHANT: String = "merchant"
const HAUL: String = MerchantTrade.HAUL_ACTION_ID
const TALK: String = "talk_player"
const BUSY_KEY: String = "npc.talk.busy"
const DAY: int = SimClock.MINUTES_PER_DAY
## Prazo para algum comerciante partir (o jogo real o faz no 1º dia) e para a viagem acabar; passou disso, a premissa mudou.
const SEARCH_LIMIT: int = 3 * DAY
const TRIP_LIMIT: int = 1500
const CM_PER_M: float = 100.0
const NEAR_M: float = 10.0
const CLOSE_M: float = 1.5
const HELD_MINUTES: int = 30
const PROBE_EVERY: int = 10
const COOLDOWN: int = NpcPlayerTalk.TALK_COOLDOWN_MIN
## Minutos ANTES da partida natural em que o ator conversa no teste da precedência sobre o cooldown (medido: entre 30 e 58 a conversa não atrasa a partida e ela vem 28 a 50 minutos depois; com menos de 25 o comerciante perde o plano).
const EARLY_TALK_MIN: int = 40

var _data: NpcLifeCheck.GameData
var _runners: Array[SimulationRunner] = []
var _hosts: Array[SimulationHostNode] = []
var _origin_settlement: String = ""
var _origin_m: Vector2 = Vector2.ZERO


class Game:
	extends RefCounted

	var runner: SimulationRunner
	var npc: NpcModule
	var economy: EconomyModule
	var world: WorldModule
	var bridge: SimBridge
	var actor_id: int = IdGenerator.NO_ID

	func now() -> int:
		return runner.world.context.clock.total_minutes()


func before_all() -> void:
	_data = NpcLifeCheck.load_game_data()
	assert_eq(_data.problem, "", "Os dados reais do jogo carregam.")
	# Descoberta (como no teste do fantasma): sem corpos, quem parte primeiro e de que mercado; é ali que o jogador vai ficar.
	var found: Game = _build()
	found.runner.start_new_game()
	var traders: Array[int] = _merchants(found)
	assert_gt(traders.size(), 0, "O jogo novo tem comerciantes.")
	for _minute: int in SEARCH_LIMIT:
		found.runner.step_once()
		for trader: int in traders:
			if found.economy.peek_caravan(trader).found and _origin_settlement.is_empty():
				var leaver: NpcModule.NpcQuery = found.npc.peek_npc(trader)
				_origin_settlement = leaver.settlement_id
				_origin_m = Vector2(leaver.x_cm, leaver.z_cm) / CM_PER_M
		if not _origin_settlement.is_empty():
			break
	assert_ne(_origin_settlement, "", "Algum comerciante parte em até 3 dias (a premissa destes testes).")


func after_each() -> void:
	for runner: SimulationRunner in _runners:
		runner.finish()
	_runners.clear()
	for host: SimulationHostNode in _hosts:
		host.free()
	_hosts.clear()


## O jogo montado como o `GameApp` monta, com a ponte real sobre um host que guarda `runner`, `character`, `npc` e `economy`. `with_economy` falso: o jogo SEM os dados da economia (a casca, sem bens, mercados nem contas).
func _build(with_economy: bool = true) -> Game:
	var setup: NpcSetup = NpcSetup.from_dir(DATA_DIR, SettlementService.new(_data.settlements, _data.places))
	assert_true(setup.result.ok, setup.result.message)
	var game: Game = Game.new()
	game.runner = SimulationRunner.new(GameAppNode.DEFAULT_WORLD_SEED, GameAppNode.NEW_GAME_START_MINUTE)
	_runners.append(game.runner)
	var economy_setup: EconomySetup = EconomySetup.from_dir(EconomySetup.DEFAULT_DIR) if with_economy else null
	var modules: GameModules = GameModules.register(game.runner, _data.terrain, _data.points, setup, economy_setup, WorldSetup.from_dir(WORLD_DIR, _data.settlements, OS.is_debug_build()))
	assert_true(modules.result.ok, modules.result.message)
	game.npc = modules.npc
	game.economy = modules.economy
	game.world = modules.world
	var host: SimulationHostNode = SimulationHostNode.new()
	host.runner = game.runner
	host.character = modules.character
	host.npc = game.npc
	host.economy = game.economy
	_hosts.append(host)
	game.bridge = SimBridge.new(host, _data.terrain, _data.places, game.npc)
	return game


## O jogo novo com o jogador nascido pela ponte, os corpos ligados e o jogador a `NEAR_M` do mercado de partida (o foco do LOD vai junto, pela ponte).
func _new_game(with_economy: bool = true) -> Game:
	var game: Game = _build(with_economy)
	game.runner.start_new_game()
	game.actor_id = game.bridge.request_spawn_character().actor_id
	assert_ne(game.actor_id, IdGenerator.NO_ID, "O jogador nasce pela ponte.")
	assert_true(game.bridge.request_set_bodies_available(true).ok)
	_stand_at(game, _origin_m + Vector2(NEAR_M, 0.0))
	return game


func _merchants(game: Game, settlement_id: String = "") -> Array[int]:
	var ids: Array[int] = []
	for npc_id: int in game.npc.peek_npc_ids():
		var npc: NpcModule.NpcQuery = game.npc.peek_npc(npc_id)
		if npc.occupation_id == MERCHANT and (settlement_id.is_empty() or npc.settlement_id == settlement_id):
			ids.append(npc_id)
	return ids


func _stand_at(game: Game, spot_m: Vector2) -> void:
	var reported: Result = game.bridge.request_report_position(game.actor_id, Vector3(spot_m.x, 10.0, spot_m.y), 0.0)
	assert_true(reported.ok, reported.message)


## O jogador a `CLOSE_M` do CORPO do NPC (a posição do LOD, a que vale para o alcance da conversa); devolve a posição, em metros, para o pedido direto ao módulo.
func _next_to(game: Game, npc_id: int) -> Vector3:
	var body_cm: Vector2i = game.npc.lod.position_of(npc_id)
	var spot: Vector3 = Vector3(float(body_cm.x) / CM_PER_M + CLOSE_M, 10.0, float(body_cm.y) / CM_PER_M)
	_stand_at(game, Vector2(spot.x, spot.z))
	return spot


## O corpo perfeito: cumpre cada Intent pendente no fim previsto (ARRIVED para ir, DONE para agir), no destino.
func _answer_due(game: Game) -> void:
	for intent: NpcIntent in game.npc.peek_pending_intents():
		if game.now() < game.npc.peek_npc(intent.npc_id).action_ends_at:
			continue
		var outcome: NpcActionResult.Outcome = NpcActionResult.Outcome.ARRIVED if intent.kind == NpcIntent.Kind.MOVE_TO_PLACE else NpcActionResult.Outcome.DONE
		var spot_m: Vector3 = Vector3(intent.destination_cm.x / CM_PER_M, 0.0, intent.destination_cm.y / CM_PER_M)
		var reported: Result = game.npc.request_report_npc_result(NpcActionResult.new(intent.npc_id, intent.action_serial, outcome, spot_m))
		assert_true(reported.ok or reported.code == ActionRunner.CODE_ACTION_FAILED, reported.message)


## Um minuto do jogo: um passo e as respostas do corpo.
func _tick(game: Game) -> void:
	game.runner.step_once()
	_answer_due(game)


func _walk(game: Game, minutes: int) -> void:
	for _minute: int in minutes:
		_tick(game)


## Anda até algum comerciante do povoado de partida ter caravana (o passo da partida acabou de rodar) e o devolve.
func _depart(game: Game) -> int:
	var traders: Array[int] = _merchants(game, _origin_settlement)
	var leaver: int = IdGenerator.NO_ID
	for _minute: int in SEARCH_LIMIT:
		_tick(game)
		for trader: int in traders:
			if leaver == IdGenerator.NO_ID and game.economy.peek_caravan(trader).found:
				leaver = trader
		if leaver != IdGenerator.NO_ID:
			break
	assert_ne(leaver, IdGenerator.NO_ID, "Algum comerciante do povoado de partida parte em até 3 dias.")
	return leaver


## Anda até um comerciante do povoado de partida estar na ação `haul` (o ato de partir, no mercado), em S0 e ainda sem caravana, e o devolve.
func _wait_for_haul(game: Game) -> int:
	var traders: Array[int] = _merchants(game, _origin_settlement)
	for _minute: int in SEARCH_LIMIT:
		_tick(game)
		for trader: int in traders:
			if game.npc.peek_npc(trader).action_id == HAUL and not game.economy.peek_caravan(trader).found and game.npc.lod.level_of(trader) == NpcLod.LEVEL_S0:
				return trader
	assert_true(false, "Algum comerciante do povoado de partida chega à ação `haul` em até 3 dias.")
	return IdGenerator.NO_ID


## Anda até a caravana do comerciante sumir (a chegada); devolve os minutos andados.
func _arrive(game: Game, trader: int) -> int:
	var minutes: int = 0
	while game.economy.peek_caravan(trader).found and minutes < TRIP_LIMIT:
		_tick(game)
		minutes += 1
	assert_false(game.economy.peek_caravan(trader).found, "A viagem acaba dentro do prazo.")
	return minutes


## O que um pedido recusado NÃO pode mexer: o hash do estado, o barramento de eventos (fila e contador de IDs) e as Intents pendentes.
func _fingerprint(game: Game) -> Array:
	var intents: Array[String] = []
	for intent: NpcIntent in game.npc.peek_pending_intents():
		intents.append("%d:%d" % [intent.npc_id, intent.action_serial])
	return [game.runner.world.state_hash(), game.runner.world.context.events.debug_summary(), intents]


## Um NPC em S0 que não é comerciante, está vivo, sem caravana e fora das ações que o impedem de atender (dormir, fugir, ajudar).
func _first_ordinary_in_s0(game: Game) -> int:
	for npc_id: int in game.npc.lod.s0_ids():
		var npc: NpcModule.NpcQuery = game.npc.peek_npc(npc_id)
		if npc.occupation_id != MERCHANT and npc.is_alive and not NpcPlayerTalk.BUSY_ACTION_IDS.has(npc.action_id) and not game.economy.peek_caravan(npc_id).found:
			return npc_id
	return IdGenerator.NO_ID


## Pede a conversa pelos DOIS caminhos (o módulo, com a posição do ator, e a ponte, que usa a posição guardada) e confere a recusa por ocupado, sem texto, sem promoção e sem nada escrito.
func _assert_refused_as_busy(game: Game, trader: int, spot: Vector3, label: String) -> void:
	var before: Array = _fingerprint(game)
	var direct: NpcModule.ConverseResult = game.npc.request_converse(game.actor_id, spot, trader)
	assert_eq([direct.result.code, direct.text_key, direct.was_promoted], [NpcModule.CODE_TALK_BUSY, "", false], "%s, pelo módulo: recusa por ocupado, sem texto e sem promoção." % label)
	assert_true(direct.result.message.contains("viagem"), "%s: a mensagem diz que o NPC está em viagem: %s" % [label, direct.result.message])
	var reply: BridgeReplies.ConverseReply = game.bridge.request_converse(game.actor_id, trader)
	assert_eq([reply.result.code, reply.text_key, reply.was_promoted], [NpcModule.CODE_TALK_BUSY, BUSY_KEY, false], "%s, pela ponte: a mesma recusa, com a chave `npc.talk.busy`." % label)
	assert_eq(_fingerprint(game), before, "%s: a recusa não escreveu nada (hash do estado, eventos e Intents iguais)." % label)


func test_a_travelling_merchant_refuses_the_conversation_and_nothing_changes() -> void:
	var game: Game = _new_game()
	var trader: int = _depart(game)
	assert_true(game.economy.peek_caravan(trader).found, "Premissa: o comerciante está em viagem.")
	assert_eq(game.npc.lod.level_of(trader), NpcLod.LEVEL_S0, "Premissa: ele segue em S0, a poucos metros do jogador (o fantasma que a ponte esconde).")
	var spot: Vector3 = _next_to(game, trader)
	_assert_refused_as_busy(game, trader, spot, "Em viagem, ao lado do corpo")
	# A ordem das recusas não muda: quem está longe continua recebendo `longe`, e o cooldown nunca é gravado pela recusa.
	_stand_at(game, Vector2(spot.x, spot.z) + Vector2(NEAR_M, 0.0))
	assert_eq(game.bridge.request_converse(game.actor_id, trader).result.code, NpcModule.CODE_TALK_TOO_FAR, "Longe do corpo (10 m), a recusa segue sendo `longe`.")


func test_a_held_caravan_refuses_the_conversation_too() -> void:
	var game: Game = _new_game()
	var trader: int = _depart(game)
	_walk(game, 20)
	var road: CaravanReplies.CaravanQuery = game.economy.peek_caravan(trader)
	assert_true(road.found and road.state == Caravan.STATE_TRAVELLING, "Aos 20 minutos a caravana segue na estrada.")
	assert_true(game.world.request_close_route(road.current_route_id).ok, "A rota do meio da viagem fecha.")
	_walk(game, HELD_MINUTES)
	assert_eq([game.economy.peek_caravan(trader).found, game.economy.peek_caravan(trader).state], [true, Caravan.STATE_HELD], "A caravana ficou parada (`held`) e continua existindo.")
	assert_eq(game.npc.lod.level_of(trader), NpcLod.LEVEL_S0, "Parada, o NPC lógico segue em S0 no mercado de partida.")
	_assert_refused_as_busy(game, trader, _next_to(game, trader), "Caravana parada")
	assert_true(game.world.request_open_route(road.current_route_id).ok, "A rota reabre.")
	_walk(game, 1)
	_assert_refused_as_busy(game, trader, _next_to(game, trader), "Caravana andando de novo")


func test_before_the_departure_and_after_the_arrival_the_merchant_converses_as_usual() -> void:
	var game: Game = _new_game()
	var trader: int = _wait_for_haul(game)
	assert_false(game.economy.peek_caravan(trader).found, "Premissa: antes da partida, sem caravana.")
	_next_to(game, trader)
	var first: BridgeReplies.ConverseReply = game.bridge.request_converse(game.actor_id, trader)
	assert_true(first.result.ok, "Antes da partida (na ação `haul`, no mercado) ele conversa: %s" % first.result.message)
	assert_eq([first.text_key, game.npc.peek_npc(trader).action_id], [NpcPlayerTalk.TEXT_KEY_FIRST, TALK], "Primeira conversa, e a parada interrompeu a `haul`.")
	var talked_at: int = game.now()
	assert_eq(game.npc.lod.level_of(trader), NpcLod.LEVEL_S0, "Premissa: ainda em S0.")
	# A viagem acontece depois da conversa (a `haul` recomeça e termina).
	var departed: bool = false
	for _minute: int in SEARCH_LIMIT:
		_tick(game)
		if game.economy.peek_caravan(trader).found:
			departed = true
			break
	assert_true(departed, "O mesmo comerciante parte depois da conversa (premissa).")
	_arrive(game, trader)
	var arrived: NpcModule.NpcQuery = game.npc.peek_npc(trader)
	assert_ne(arrived.settlement_id, _origin_settlement, "Chegou ao povoado do destino.")
	_stand_at(game, Vector2(arrived.x_cm, arrived.z_cm) / CM_PER_M + Vector2(NEAR_M, 0.0))
	_tick(game)
	assert_eq(game.npc.lod.level_of(trader), NpcLod.LEVEL_S0, "Com o jogador no destino o comerciante volta a ter corpo.")
	# O cooldown de 60 min, contado do começo da conversa, é respeitado: se a viagem foi mais curta que ele, espera-se o resto.
	while game.now() - talked_at < COOLDOWN:
		_tick(game)
	_next_to(game, trader)
	var again: BridgeReplies.ConverseReply = game.bridge.request_converse(game.actor_id, trader)
	assert_true(again.result.ok, "Depois da chegada (e do cooldown) ele conversa de novo: %s" % again.result.message)
	assert_eq([again.text_key, again.was_promoted], [NpcPlayerTalk.TEXT_KEY_KNOWN, false], "Já se conhecem: `known`, sem promover de novo.")


func test_the_travel_refusal_takes_precedence_over_the_cooldown() -> void:
	# A ordem das recusas fica fixada: "em viagem" vale ANTES do cooldown. Passo 1: sem conversa nenhuma, anota quem parte e quando. Passo 2: o mesmo jogo (determinista), com o ator conversando com ele `EARLY_TALK_MIN` minutos antes dessa partida
	# (ele espera em casa, em S0, e a conversa não atrasa a partida; conversar na própria `haul` o faria perder o plano e só partir dias depois). Durante a viagem, ainda dentro dos 60 minutos do começo da conversa, o pedido volta
	# `NPC_TALK_BUSY` (mensagem com "viagem") e não `NPC_TALK_COOLDOWN`, sem escrever nada.
	var probe: Game = _new_game()
	var trader: int = _depart(probe)
	var departure_at: int = probe.now()
	var game: Game = _new_game()
	while game.now() < departure_at - EARLY_TALK_MIN:
		_tick(game)
	_next_to(game, trader)
	var first: BridgeReplies.ConverseReply = game.bridge.request_converse(game.actor_id, trader)
	assert_true(first.result.ok, "Antes da partida ele conversa: %s" % first.result.message)
	var talked_at: int = game.now()
	assert_eq(game.bridge.request_converse(game.actor_id, trader).result.code, NpcModule.CODE_TALK_COOLDOWN, "Controle: logo depois da conversa, o pedido cai no cooldown (o relógio de 60 minutos está correndo).")
	var departed: bool = false
	for _minute: int in COOLDOWN:
		_tick(game)
		if game.economy.peek_caravan(trader).found:
			departed = true
			break
	assert_true(departed, "O mesmo comerciante parte em menos de 60 minutos depois da conversa (premissa).")
	assert_lt(game.now() - talked_at, COOLDOWN, "Premissa: a viagem começou a menos de 60 minutos do começo da conversa, com o cooldown ainda aberto.")
	_assert_refused_as_busy(game, trader, _next_to(game, trader), "Em viagem, dentro do cooldown")


func test_a_non_merchant_still_converses_while_a_merchant_travels() -> void:
	var game: Game = _new_game()
	var trader: int = _depart(game)
	_assert_refused_as_busy(game, trader, _next_to(game, trader), "Comerciante em viagem")
	var neighbour: int = _first_ordinary_in_s0(game)
	assert_ne(neighbour, IdGenerator.NO_ID, "Há outro NPC em S0 que atende (premissa).")
	assert_false(game.economy.peek_caravan(neighbour).found, "Premissa: ele não tem caravana.")
	_next_to(game, neighbour)
	var reply: BridgeReplies.ConverseReply = game.bridge.request_converse(game.actor_id, neighbour)
	assert_true(reply.result.ok, "Quem não está em viagem conversa normalmente: %s" % reply.result.message)
	assert_eq(reply.text_key, NpcPlayerTalk.TEXT_KEY_FIRST, "Primeira conversa dele.")


func test_without_the_economy_data_the_conversation_works_as_before() -> void:
	# O jogo SEM os dados da economia (a casca: ninguém tem conta nem caravana): `peek_caravan` não acha ninguém em viagem e nada é recusado a mais.
	var game: Game = _new_game(false)
	var neighbour: int = IdGenerator.NO_ID
	for _minute: int in DAY:
		_tick(game)
		neighbour = _first_ordinary_in_s0(game)
		if neighbour != IdGenerator.NO_ID:
			break
	assert_ne(neighbour, IdGenerator.NO_ID, "Em até um dia há um NPC em S0 que atende (premissa).")
	assert_false(game.economy.peek_caravan(neighbour).found, "Sem os dados da economia ninguém tem caravana.")
	_next_to(game, neighbour)
	var reply: BridgeReplies.ConverseReply = game.bridge.request_converse(game.actor_id, neighbour)
	assert_true(reply.result.ok, "Sem economia a conversa é aceita como antes: %s" % reply.result.message)


## Uma viagem inteira com o jogador ao lado do comerciante; `ask`: a cada 10 minutos faz o pedido de conversa pelos dois caminhos (a viagem os recusa). Devolve [minutos andados, hash do estado na chegada, minuto da chegada].
func _trip(ask: bool) -> Array:
	var game: Game = _new_game()
	var trader: int = _depart(game)
	var spot: Vector3 = _next_to(game, trader)
	var minutes: int = 0
	while game.economy.peek_caravan(trader).found and minutes < TRIP_LIMIT:
		if ask and minutes % PROBE_EVERY == 0:
			assert_false(game.npc.request_converse(game.actor_id, spot, trader).result.ok, "O pedido ao módulo é recusado (minuto %d da viagem)." % minutes)
			assert_false(game.bridge.request_converse(game.actor_id, trader).result.ok, "O pedido pela ponte é recusado (minuto %d da viagem)." % minutes)
		_tick(game)
		minutes += 1
	return [minutes, game.runner.world.state_hash(), game.now()]


func test_the_refused_requests_leave_the_whole_trip_identical_to_a_trip_without_them() -> void:
	var asked: Array = _trip(true)
	var silent: Array = _trip(false)
	assert_gt(asked[0], 60, "A viagem dura mais de uma hora (muitos pedidos recusados no caminho).")
	assert_eq(asked, silent, "Com e sem os pedidos recusados: mesma duração, mesmo `state_hash` e mesmo minuto na chegada (a recusa não escreve nem gasta sorteio).")
	assert_eq(_trip(true), asked, "Duas execuções idênticas dão o mesmo resultado (determinismo).")
