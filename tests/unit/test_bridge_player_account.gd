extends GutTest
## LW-105 (parte a): a ponte abre a conta do JOGADOR na economia e mostra o que ele tem. O jogo é o de verdade (`GameApp.start_default_game`: terreno, NPCs e economia reais; só
## `--headless`). O jogador é um personagem guardado no `character`; o saldo vem do `Ledger` (a ponte só copia) e o peso e os bens, do inventário da `economy` (DEC-130). O saldo
## inicial e a capacidade de peso são do tipo `player` de `data/economy/owner_kinds.json` [HIP]: o teste os LÊ dos dados em vez de fixá-los. Quem não é personagem (um NPC, um ID
## solto) é recusado e nada é aberto; antes de abrir a conta a consulta falha com código; sem jogo ou sem economia as chamadas falham com código, sem derrubar nada.

const UNKNOWN_ACTOR: int = 999999

var _host: SimulationHostNode
var _app: GameAppNode
var _bridge: SimBridge
var _kind: OwnerKindDef


func before_all() -> void:
	var setup: EconomySetup = EconomySetup.from_dir(EconomySetup.DEFAULT_DIR)
	assert_true(setup.result.ok, setup.result.message)
	for kind: OwnerKindDef in setup.definitions.kinds:
		if kind.id == BridgePlayerEconomy.OWNER_KIND:
			_kind = kind
	assert_not_null(_kind, "O tipo `player` existe nos dados da economia.")


func before_each() -> void:
	_host = SimulationHostNode.new()
	_app = GameAppNode.new()
	_app.bind_host(_host)
	_app.start_default_game(_host)
	_bridge = _app.peek_bridge()


func after_each() -> void:
	_app.free()
	if _host.runner != null:
		_host.runner.finish()
	_host.free()


func _spawn() -> int:
	var spawned: BridgeReplies.SpawnCharacterReply = _bridge.request_spawn_character()
	assert_true(spawned.result.ok, spawned.result.message)
	return spawned.actor_id


func test_the_account_opens_with_the_initial_money_of_the_kind_and_an_empty_inventory() -> void:
	var actor_id: int = _spawn()
	var created_before: int = _host.economy.peek_conservation().created
	var opened: Result = _bridge.request_open_player_account(actor_id)
	assert_true(opened.ok, opened.message)
	var view: BridgePlayerEconomyReplies.PlayerEconomyReply = _bridge.peek_player_economy(actor_id)
	assert_true(view.result.ok, view.result.message)
	assert_eq([view.funds, view.weight, view.capacity, view.goods], [_kind.initial_balance, 0, _kind.weight_capacity, [] as Array[Dictionary]], "O saldo inicial e a capacidade são os do tipo `player`; nada no inventário.")
	assert_eq(view.funds, _host.economy.peek_balance(actor_id).balance, "O saldo que a ponte mostra é o do `Ledger`.")
	var conservation: EconomyReplies.ConservationQuery = _host.economy.peek_conservation()
	assert_eq([conservation.created - created_before, conservation.ok], [_kind.initial_balance, true], "O dinheiro do jogador nasceu por um `mint` só, e a conservação fecha.")
	assert_eq(_host.economy.validate(), [] as Array[String])


func test_opening_the_account_again_changes_nothing() -> void:
	var actor_id: int = _spawn()
	assert_true(_bridge.request_open_player_account(actor_id).ok)
	var created: int = _host.economy.peek_conservation().created
	assert_true(_bridge.request_open_player_account(actor_id).ok, "Idempotente.")
	assert_eq([_host.economy.peek_conservation().created, _bridge.peek_player_economy(actor_id).funds], [created, _kind.initial_balance], "Sem novo `mint`: o saldo continua o inicial.")


func test_an_actor_the_character_does_not_know_is_refused_and_nothing_is_opened() -> void:
	var npc_id: int = _host.npc.peek_npc_ids()[0]
	var npc_balance: int = _host.economy.peek_balance(npc_id).balance
	var created: int = _host.economy.peek_conservation().created
	for stranger: int in [npc_id, UNKNOWN_ACTOR]:
		var refused: Result = _bridge.request_open_player_account(stranger)
		assert_eq(refused.code, CharacterModule.CODE_UNKNOWN_ACTOR, "O ator %d não é um personagem." % stranger)
		assert_eq(_bridge.peek_player_economy(stranger).result.code, CharacterModule.CODE_UNKNOWN_ACTOR)
	assert_false(_host.economy.peek_balance(UNKNOWN_ACTOR).result.ok, "Nenhuma conta foi aberta para o ID solto.")
	assert_eq([_host.economy.peek_balance(npc_id).balance, _host.economy.peek_conservation().created], [npc_balance, created], "A conta do NPC não mudou e nenhum dinheiro nasceu.")


func test_the_view_before_the_account_is_open_is_a_handled_failure() -> void:
	var actor_id: int = _spawn()
	var view: BridgePlayerEconomyReplies.PlayerEconomyReply = _bridge.peek_player_economy(actor_id)
	assert_eq(view.result.code, EconomyCodes.UNKNOWN_OWNER, "O personagem existe, mas ainda não tem conta na economia.")
	assert_eq([view.funds, view.weight, view.capacity, view.goods.size()], [0, 0, 0, 0])


func test_without_a_game_or_without_the_economy_the_calls_fail_with_a_code() -> void:
	var idle_host: SimulationHostNode = SimulationHostNode.new()
	var idle_bridge: SimBridge = SimBridge.new(idle_host, null)
	assert_eq(idle_bridge.request_open_player_account(1).code, SimBridge.CODE_NO_GAME, "Sem jogo iniciado.")
	assert_eq(idle_bridge.peek_player_economy(1).result.code, SimBridge.CODE_NO_GAME)
	idle_host.free()
	var terrainless: SimulationHostNode = SimulationHostNode.new()
	terrainless.start_new_game(5)
	var terrainless_bridge: SimBridge = SimBridge.new(terrainless, null)
	assert_eq(terrainless_bridge.request_open_player_account(1).code, SimBridge.CODE_NO_CHARACTER, "Jogo sem terreno: sem personagem, sem economia.")
	terrainless.runner.finish()
	terrainless.free()
	var actor_id: int = _spawn()
	var economy: EconomyModule = _host.economy
	_host.economy = null
	assert_eq(_bridge.request_open_player_account(actor_id).code, SimBridge.CODE_NO_ECONOMY, "Há personagem, mas o jogo não tem economia.")
	assert_eq(_bridge.peek_player_economy(actor_id).result.code, SimBridge.CODE_NO_ECONOMY)
	_host.economy = economy
