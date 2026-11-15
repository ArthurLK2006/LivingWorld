extends GutTest
## LW-107e2b (critérios C7, parte e2, e C8): ACEITAR e ENTREGAR na aba "Contratos" da `MarketView` (src/presentation/ui/market/market_view.gd e contracts_page.gd; contrato em docs/modules/presentation.md, "Quadro de contratos (LW-107)"), sem janela, com o jogo REAL (`res://data`), a ponte real e os
## textos reais (`data/text/pt_br.json`), montados como em `test_contracts_tab.gd` (a aba de leitura, LW-107e1; este arquivo é à parte porque os dois juntos passariam do teto de ~450 linhas por arquivo, AGENTS 4.5): o jogador junto ao mercado A, com a conta aberta, os contratos postados DIRETO na economia
## (o jogador não posta) e o relógio andando pelo `runner` do jogo. Confere: as regras dos botões e das dicas por linha escolhida (Aceitar só na linha `open` no prazo, Entregar só com `can_deliver`, nenhum com o relógio pausado); aceitar e entregar enviam o pedido pela ponte, mostram a resposta (o texto da
## `text_key` e, no sucesso, a recompensa) e refazem as consultas, com a escolha e o foco preservados; CADA recusa mostra a sua chave (`expired` quando o prazo passa entre a consulta e o clique, `not_open` quando outro aceitou antes, `too_far`, `no_goods`, `impossible` e as outras por resposta fabricada); pausado, nada
## é enviado, nem com a pausa vindo depois da última consulta; a página só AVISA por sinal (quem envia é a `MarketView`); e abrir, trocar de aba, atualizar e fechar continuam sem mudar o `state_hash`. Os nós da tela são achados pelos nomes fixos dos layouts: a tela não os expõe.

const WORLD_DIR: String = "res://data/world"
const SEED: int = 107
const SETTLEMENT_A: String = "test_settlement_a"
const SETTLEMENT_B: String = "test_settlement_b"
const SETTLEMENT_C: String = "test_settlement_c"
const BREAD: String = "bread"
const WOOD: String = "wood"
## Os números dos contratos do teste (os do jogo são [HIP]): recompensa, quantidade e prazos em minutos depois de agora. O quadro de `_build_board` é lido no minuto 100: o curto já venceu, o médio ainda consta aberto ou aceito (a economia só vence na hora cheia 120) e o longo falta 500 min.
const REWARD: int = 12
const QUANTITY: int = 2
const SHORT_MINUTES: int = 40
const MEDIUM_MINUTES: int = 90
const LONG_MINUTES: int = 600
const BOARD_MINUTE: int = 100
## Distância (m) do centro do mercado, além do alcance de 3 m do `world`.
const FAR_M: float = 3.5
const KEY_PREFIX: String = "ui.contracts."
const KEY_FOR_MISSING_TEXT: String = "\\[[a-z_]+(\\.[a-z_]+)+\\]"
const TAB_CONTRACTS: String = "MarketTabContracts"
const TAB_MARKET: String = "MarketTabMarket"
const OPEN_LIST: String = "ContractsOpen"
const MINE_LIST: String = "ContractsMine"
const ACCEPT: String = "ContractsAccept"
const DELIVER: String = "ContractsDeliver"
## As 11 chaves `economy.contract.*` (sem o prefixo) e, para as 9 de recusa, o código que a ponte recusa (item (iii) do `bridge.md`; `failed` é a genérica, de todo código sem chave própria, aqui `BRIDGE_NO_ECONOMY`).
const REPLY_KEYS: Array[String] = ["accepted", "delivered", "not_open", "unknown", "impossible", "no_goods", "destination_full", "too_far", "not_yours", "expired", "failed"]
const REFUSAL_CODES: Dictionary[String, String] = {
	"not_open": "ECON_CONTRACT_NOT_OPEN",
	"unknown": "ECON_UNKNOWN_CONTRACT",
	"impossible": "ECON_CONTRACT_IMPOSSIBLE",
	"no_goods": "ECON_INSUFFICIENT_GOODS",
	"destination_full": "ECON_CAPACITY_EXCEEDED",
	"too_far": "PLACE_TOO_FAR",
	"not_yours": "BRIDGE_CONTRACT_NOT_YOURS",
	"expired": "BRIDGE_CONTRACT_EXPIRED",
	"failed": "BRIDGE_NO_ECONOMY",
}

var _terrain: TerrainData
var _places: Array[Place] = []
var _setup: EconomySetup
var _texts: UiText
var _center_a: Vector3
var _host: SimulationHostNode
var _bridge: SpyBridge
var _economy: EconomyModule
var _actor_id: int = 0
var _market_a: int = 0
var _market_b: int = 0
var _market_c: int = 0
var _view: MarketView


## Ponte que ANOTA todo pedido (`sent`) e repassa à de verdade: o que a tela envia e o que NÃO envia.
class SpyBridge:
	extends SimBridge

	var sent: Array[String] = []

	func request_trade(actor_id: int, market_id: int, good_id: String, quantity: int, side: String) -> BridgePlayerEconomyReplies.PlayerTradeReply:
		sent.append("trade")
		return super(actor_id, market_id, good_id, quantity, side)

	func request_contract_accept(actor_id: int, contract_id: int) -> BridgePlayerContractsReplies.ContractActionReply:
		sent.append("accept")
		return super(actor_id, contract_id)

	func request_contract_deliver(actor_id: int, contract_id: int) -> BridgePlayerContractsReplies.ContractActionReply:
		sent.append("deliver")
		return super(actor_id, contract_id)


## Ponte espiã que responde aos pedidos de contrato com a recusa FABRICADA `forced_code` (nada chega à economia): serve às recusas que uma tela de verdade não consegue provocar (`unknown`, `not_yours`, `destination_full` e `failed`) e prova que a tela mostra a chave que a ponte devolve.
class ForcedBridge:
	extends SpyBridge

	var forced_code: String = ""

	func request_contract_accept(_actor_id: int, contract_id: int) -> BridgePlayerContractsReplies.ContractActionReply:
		sent.append("accept")
		return _refusal(contract_id)

	func request_contract_deliver(_actor_id: int, contract_id: int) -> BridgePlayerContractsReplies.ContractActionReply:
		sent.append("deliver")
		return _refusal(contract_id)

	func _refusal(contract_id: int) -> BridgePlayerContractsReplies.ContractActionReply:
		return BridgePlayerContractsReplies.ContractActionReply.new(Result.failure(forced_code, "recusa fabricada"), contract_id)


func before_all() -> void:
	var loaded: TerrainLoader.LoadResult = TerrainLoader.load_dir(WORLD_DIR)
	assert_true(loaded.result.ok, loaded.result.message)
	_terrain = loaded.terrain
	var settlements: SettlementLoader.LoadResult = SettlementLoader.load_dir(WORLD_DIR, _terrain)
	assert_true(settlements.result.ok, settlements.result.message)
	_places = settlements.places
	for place: Place in _places:
		if place.kind == Place.KIND_MARKET and place.settlement_id == SETTLEMENT_A:
			_center_a = place.position
	_setup = EconomySetup.from_dir(EconomySetup.DEFAULT_DIR)
	assert_true(_setup.result.ok, _setup.result.message)
	var texts: UiText.LoadResult = UiText.from_file(UiText.DEFAULT_PATH)
	assert_true(texts.result.ok, texts.result.message)
	_texts = texts.texts


## Um jogo só com o personagem e a economia (sem NPCs), com o jogador junto ao mercado A e a conta aberta (o relógio está no minuto 0), e a tela FECHADA, ligada a uma ponte espiã.
func before_each() -> void:
	_host = SimulationHostNode.new()
	_host.start_new_game(SEED, _terrain, [], null, 0, _setup)
	_bridge = SpyBridge.new(_host, _terrain, _places)
	_economy = _host.economy
	_actor_id = _bridge.request_spawn_character().actor_id
	assert_true(_bridge.request_report_position(_actor_id, _center_a, 0.0).ok, "O jogador começa junto ao mercado A.")
	assert_true(_bridge.request_open_player_account(_actor_id).ok)
	_market_a = _economy.peek_market_of(SETTLEMENT_A).market_id
	_market_b = _economy.peek_market_of(SETTLEMENT_B).market_id
	_market_c = _economy.peek_market_of(SETTLEMENT_C).market_id
	_view = _make_view(_bridge, _actor_id)


func after_each() -> void:
	_host.runner.finish()
	_host.free()


func _make_view(bridge: SimBridge, actor_id: int) -> MarketView:
	var view: MarketView = MarketView.new()
	add_child_autofree(view)
	assert_true(view.setup(bridge, _texts, actor_id, [] as Array[Node]))
	return view


func _text(key: String, values: Dictionary = {}) -> String:
	return _texts.get_text(key, values)


func _say(key: String, values: Dictionary = {}) -> String:
	return _text(KEY_PREFIX + key, values)


## A frase de uma das 11 chaves `economy.contract.*` (sem o prefixo), com a recompensa do teste no `{reward}`.
func _reply_text(key: String) -> String:
	return _text("economy.contract." + key, {"reward": REWARD})


func _left(days: int, hours: int, minutes: int) -> String:
	return _say("deadline", {"d": days, "h": hours, "m": minutes})


func _node(node_name: String) -> Node:
	return _view.find_child(node_name, true, false)


func _tree(list_name: String) -> Tree:
	return _node(list_name) as Tree


func _press(button_name: String) -> void:
	(_node(button_name) as Button).pressed.emit()


func _is_off(button_name: String) -> bool:
	return (_node(button_name) as Button).disabled


func _detail_text() -> String:
	return (_node("ContractsDetail") as Label).text


func _result_text() -> String:
	return (_node("ContractsResult") as Label).text


## O texto e a visibilidade da linha de dicas da aba.
func _hints() -> Array:
	var hints: Label = _node("ContractsHints") as Label
	return [hints.text, hints.visible]


## Abre a tela sobre o mercado A e escolhe a aba "Contratos".
func _open_contracts() -> void:
	_view.open(_market_a)
	(_node(TAB_CONTRACTS) as Button).pressed.emit()


func _items(tree: Tree) -> Array[TreeItem]:
	return tree.get_root().get_children() if tree.get_root() != null else ([] as Array[TreeItem])


## Os `contract_id` de uma lista, na ordem em que a tela os mostra (a linha da mensagem de lista vazia não tem id).
func _ids_of(list_name: String) -> Array[int]:
	var ids: Array[int] = []
	for item: TreeItem in _items(_tree(list_name)):
		if item.get_metadata(ContractsLayout.COLUMN_LINE) != null:
			ids.append(int(item.get_metadata(ContractsLayout.COLUMN_LINE)))
	return ids


## A linha do contrato, em qualquer das duas listas (nula se a tela não a mostra).
func _row_of(contract_id: int) -> TreeItem:
	for list_name: String in [OPEN_LIST, MINE_LIST]:
		for item: TreeItem in _items(_tree(list_name)):
			if item.get_metadata(ContractsLayout.COLUMN_LINE) == contract_id:
				return item
	return null


## A coluna do prazo (ou do estado) da linha do contrato.
func _when_of(contract_id: int) -> String:
	return _row_of(contract_id).get_text(ContractsLayout.COLUMN_WHEN)


func _select(contract_id: int) -> void:
	_row_of(contract_id).select(ContractsLayout.COLUMN_LINE)


func _funds() -> int:
	return _bridge.peek_player_economy(_actor_id).funds


func _state_of(contract_id: int) -> String:
	return _economy.peek_contract(contract_id).state


## Posta um contrato de entrega direto na economia: `issuer` paga a recompensa para a custódia e o prazo é `minutes` depois de agora.
func _post(issuer: int, destination: int, minutes: int, good_id: String = BREAD, quantity: int = QUANTITY) -> int:
	var now: int = _bridge.peek_time().total_minutes
	var posted: EconomyReplies.PostContractResult = _economy.request_post_contract(ContractBook.DELIVERY, issuer, REWARD, now + minutes, {"good_id": good_id, "quantity": quantity, "destination_id": destination})
	assert_true(posted.result.ok, posted.result.message)
	return posted.contract_id


func _accept(contract_id: int) -> void:
	var accepted: Result = _economy.request_accept_contract(contract_id, _actor_id)
	assert_true(accepted.ok, accepted.message)


## Põe `quantity` do bem no inventário do jogador (tirado do mercado A, direto na economia, sem passar por compra).
func _give(good_id: String, quantity: int) -> void:
	var moved: Result = _economy.request_transfer_goods(_market_a, _actor_id, good_id, quantity)
	assert_true(moved.ok, moved.message)


## Posta e aceita (direto na economia) um contrato de pão de C para A, que o jogador entrega em A com o pão no inventário (`_give`): o contrato `can_deliver` do quadro.
func _carry_to_a(minutes: int) -> int:
	var contract_id: int = _post(_market_c, _market_a, minutes)
	_accept(contract_id)
	return contract_id


## Um dono do tipo `npc` na economia: o "outro" que aceita o contrato antes do jogador.
func _new_npc() -> int:
	var npc_id: int = _host.runner.world.context.ids.next_id()
	assert_true(_economy.request_open_owner(npc_id, "npc").ok)
	return npc_id


## Posta, aceita e entrega na hora um contrato de pão de A para B: fica `completed`, com o prazo (`minutes` depois de agora) já passado ou por vir quando o quadro é lido.
func _complete(minutes: int) -> int:
	var contract_id: int = _post(_market_a, _market_b, minutes)
	_accept(contract_id)
	_give(BREAD, QUANTITY)
	var delivered: Result = _economy.request_deliver_contract(contract_id)
	assert_true(delivered.ok, delivered.message)
	return contract_id


## Um quadro com um contrato de cada situação, lido no minuto 100 (a mesma montagem de `test_contracts_tab.gd`): `completed` (entregue no minuto 0, prazo já passado, A para B), `failed` (aceito e vencido pela economia na hora 60, A para B), `late_accepted` (aceito, prazo passado, ainda
## `accepted` na economia, C para C), `carried` (aceito, no prazo, C para C), `late_open` (aberto, prazo passado, ainda `open`, A para B) e `fresh_open` (aberto, no prazo, C para A; pede madeira). Devolve os IDs por nome.
func _build_board() -> Dictionary[String, int]:
	var ids: Dictionary[String, int] = {}
	ids["completed"] = _complete(SHORT_MINUTES)
	ids["failed"] = _post(_market_a, _market_b, SHORT_MINUTES)
	_accept(ids["failed"])
	ids["late_accepted"] = _post(_market_c, _market_c, MEDIUM_MINUTES)
	_accept(ids["late_accepted"])
	ids["carried"] = _post(_market_c, _market_c, LONG_MINUTES)
	_accept(ids["carried"])
	ids["late_open"] = _post(_market_a, _market_b, MEDIUM_MINUTES)
	ids["fresh_open"] = _post(_market_c, _market_a, LONG_MINUTES, WOOD, 1)
	_host.runner.run_steps(BOARD_MINUTE)
	return ids


func test_the_buttons_and_the_hints_follow_the_chosen_row_and_only_an_open_row_in_time_can_be_accepted() -> void:
	var ids: Dictionary[String, int] = _build_board()
	ids["deliverable"] = _carry_to_a(LONG_MINUTES)
	_give(BREAD, QUANTITY)
	_open_contracts()
	var accept_hint: Array = [_say("hint_accept"), true]
	var deliver_hint: Array = [_say("hint_deliver"), true]
	var no_hint: Array = ["", false]
	## Por linha: [Aceitar desativado, Entregar desativado, dicas]. `carried` e `late_accepted` têm o destino em C (a tela é de A); `late_accepted`, `late_open` e `failed` venceram; `completed` terminou.
	var expected: Dictionary[String, Array] = {
		"fresh_open": [false, true, accept_hint],
		"late_open": [true, true, no_hint],
		"deliverable": [true, false, deliver_hint],
		"carried": [true, true, deliver_hint],
		"late_accepted": [true, true, no_hint],
		"completed": [true, true, no_hint],
		"failed": [true, true, no_hint],
	}
	for contract_name: String in expected:
		_select(ids[contract_name])
		assert_eq([_is_off(ACCEPT), _is_off(DELIVER), _hints()], expected[contract_name], "Botões e dicas da linha '%s'." % contract_name)


func test_accept_sends_the_request_shows_the_reply_with_the_reward_and_moves_the_row_to_my_contracts_keeping_the_choice_and_the_focus() -> void:
	var contract_id: int = _post(_market_a, _market_b, LONG_MINUTES)
	var hash_before: String = _host.runner.world.state_hash()
	_open_contracts()
	assert_eq([_is_off(ACCEPT), _is_off(DELIVER), _hints(), _result_text()], [false, true, [_say("hint_accept"), true], ""], "Linha aberta e no prazo, relógio andando: só Aceitar fica ativo, com a dica de aceitar.")
	_press(ACCEPT)
	assert_eq([_bridge.sent, _state_of(contract_id), _economy.peek_contract(contract_id).acceptor_id], [["accept"] as Array[String], ContractBook.STATE_ACCEPTED, _actor_id], "O pedido saiu pela ponte e o contrato é do jogador.")
	assert_eq([_result_text(), _ids_of(OPEN_LIST), _ids_of(MINE_LIST)], [_reply_text("accepted"), [] as Array[int], [contract_id] as Array[int]], "A resposta é a frase de `accepted` e a linha foi para Meus contratos.")
	assert_true(_result_text().contains(str(REWARD)), "No sucesso a resposta traz a recompensa.")
	assert_eq([_tree(MINE_LIST).get_selected().get_metadata(ContractsLayout.COLUMN_LINE), _tree(OPEN_LIST).has_focus(), _when_of(contract_id)], [contract_id, true, _left(0, 10, 0)], "A escolha segue o contrato para a outra lista e o foco não sai de onde estava.")
	assert_eq([_is_off(ACCEPT), _is_off(DELIVER), _hints()], [true, true, [_say("hint_deliver"), true]], "Aceito, mas com o destino em B e sem o bem: os dois desativados, e a dica agora é a de entregar.")
	assert_ne(_host.runner.world.state_hash(), hash_before, "Aceitar muda o estado da economia (como esperado).")


func test_deliver_sends_the_request_pays_the_reward_and_refreshes_the_funds_and_the_owned_count() -> void:
	var contract_id: int = _carry_to_a(LONG_MINUTES)
	_open_contracts()
	assert_eq([_is_off(ACCEPT), _is_off(DELIVER)], [true, true], "Aceito, mas sem o bem no inventário: Entregar fica desativado.")
	_give(BREAD, QUANTITY)
	_view.refresh()
	assert_eq([_is_off(ACCEPT), _is_off(DELIVER), _detail_text().contains(_say("owned", {"owned": QUANTITY, "quantity": QUANTITY}))], [true, false, true], "Com o bem e junto do destino: só Entregar fica ativo, e o detalhe diz \"você tem 2 de 2\".")
	var funds_before: int = _funds()
	var hash_before: String = _host.runner.world.state_hash()
	_press(DELIVER)
	assert_eq([_bridge.sent, _state_of(contract_id), _funds()], [["deliver"] as Array[String], ContractBook.STATE_COMPLETED, funds_before + REWARD], "O pedido saiu pela ponte, o contrato está concluído e o saldo subiu a recompensa.")
	assert_eq([_result_text(), (_node("MarketFunds") as Label).text], [_reply_text("delivered"), _text("ui.market.funds", {"funds": funds_before + REWARD})], "A resposta é a frase de `delivered` e o saldo da tela de mercado foi refeito.")
	assert_true(_result_text().contains(str(REWARD)), "No sucesso a resposta traz a recompensa.")
	assert_eq([_when_of(contract_id), _detail_text().contains(_say("owned", {"owned": 0, "quantity": QUANTITY})), _is_off(DELIVER), _hints()], [_say("state.completed"), true, true, ["", false]], "A linha vira Concluído, \"você tem 0 de 2\", e Entregar desativa, sem dica.")
	assert_ne(_host.runner.world.state_hash(), hash_before, "Entregar muda o estado da economia (como esperado).")


func test_every_refusal_shows_the_text_of_its_own_key_and_the_eleven_texts_exist_differ_and_have_no_open_field() -> void:
	assert_eq([REPLY_KEYS.size(), REFUSAL_CODES.size()], [11, 9], "As 11 chaves do contrato: 2 de sucesso e 9 de recusa.")
	var missing: RegEx = RegEx.create_from_string(KEY_FOR_MISSING_TEXT)
	var unique: Dictionary[String, bool] = {}
	for key: String in REPLY_KEYS:
		var phrase: String = _reply_text(key)
		unique[phrase] = true
		assert_true(_texts.has_key("economy.contract." + key), "Falta a chave 'economy.contract.%s' em data/text/pt_br.json." % key)
		assert_true(missing.search(phrase) == null and not phrase.contains("{"), "A frase de '%s' não é chave que falta nem tem campo por preencher: %s" % [key, phrase])
	assert_eq(unique.size(), REPLY_KEYS.size(), "Cada chave tem a sua frase.")
	_post(_market_a, _market_b, LONG_MINUTES)
	var forced: ForcedBridge = ForcedBridge.new(_host, _terrain, _places)
	_view = _make_view(forced, _actor_id)
	_open_contracts()
	for key: String in REFUSAL_CODES:
		forced.forced_code = REFUSAL_CODES[key]
		_press(ACCEPT)
		assert_eq(_result_text(), _reply_text(key), "A recusa '%s' mostra o texto da sua chave." % key)
	assert_eq(forced.sent.size(), REFUSAL_CODES.size(), "Um pedido por recusa.")


func test_accept_after_the_deadline_passed_between_the_query_and_the_click_shows_the_expired_text_and_changes_nothing() -> void:
	var contract_id: int = _post(_market_a, _market_b, SHORT_MINUTES)
	_open_contracts()
	assert_false(_is_off(ACCEPT), "Pré-condição: no prazo, Aceitar está ativo.")
	_host.runner.run_steps(SHORT_MINUTES)
	var hash_before: String = _host.runner.world.state_hash()
	_press(ACCEPT)
	assert_eq([_bridge.sent, _result_text(), _state_of(contract_id), _host.runner.world.state_hash()], [["accept"] as Array[String], _reply_text("expired"), ContractBook.STATE_OPEN, hash_before], "O prazo passou depois da consulta: a ponte recusa com `expired` e nada muda.")
	assert_eq([_when_of(contract_id), _is_off(ACCEPT), _hints()], [_say("state.expired"), true, ["", false]], "Refeita a consulta, a linha mostra \"Vencido\" e Aceitar desativa.")


func test_accept_of_a_contract_another_actor_took_first_shows_the_not_open_text_and_the_row_leaves_the_board() -> void:
	var contract_id: int = _post(_market_a, _market_b, LONG_MINUTES)
	_open_contracts()
	assert_true(_economy.request_accept_contract(contract_id, _new_npc()).ok, "Pré-condição: outro aceita depois da consulta da tela.")
	_press(ACCEPT)
	assert_eq([_bridge.sent, _result_text(), _ids_of(OPEN_LIST), _ids_of(MINE_LIST), _is_off(ACCEPT)], [["accept"] as Array[String], _reply_text("not_open"), [] as Array[int], [] as Array[int], true], "A ponte recusa com `not_open`; refeita a consulta, a linha sumiu (o contrato é de outro) e Aceitar desativa.")


func test_accept_after_the_player_walked_away_from_the_market_shows_the_too_far_text() -> void:
	var contract_id: int = _post(_market_a, _market_b, LONG_MINUTES)
	_open_contracts()
	assert_true(_bridge.request_report_position(_actor_id, _center_a + Vector3(FAR_M, 0.0, 0.0), 0.0).ok, "Pré-condição: o jogador se afasta depois da consulta.")
	_press(ACCEPT)
	assert_eq([_bridge.sent, _result_text(), _state_of(contract_id)], [["accept"] as Array[String], _reply_text("too_far"), ContractBook.STATE_OPEN], "Longe do mercado, a ponte recusa com `too_far` e o contrato segue aberto.")


func test_deliver_refused_for_missing_goods_or_for_a_deadline_that_passed_shows_the_text_of_its_key() -> void:
	var late: int = _carry_to_a(SHORT_MINUTES)
	var carried: int = _carry_to_a(LONG_MINUTES)
	_give(BREAD, QUANTITY)
	_open_contracts()
	_select(carried)
	assert_false(_is_off(DELIVER), "Pré-condição: com o pão e junto do destino, Entregar está ativo.")
	assert_true(_economy.request_transfer_goods(_actor_id, _market_a, BREAD, QUANTITY).ok, "Pré-condição: o pão sai do inventário depois da consulta.")
	_press(DELIVER)
	assert_eq([_bridge.sent, _result_text(), _state_of(carried)], [["deliver"] as Array[String], _reply_text("no_goods"), ContractBook.STATE_ACCEPTED], "Sem o bem, a ponte recusa com `no_goods` e o contrato segue aceito.")
	_give(BREAD, QUANTITY)
	_view.refresh()
	_select(late)
	assert_false(_is_off(DELIVER), "Pré-condição: de novo com o pão e no prazo, Entregar está ativo.")
	_host.runner.run_steps(SHORT_MINUTES)
	_press(DELIVER)
	assert_eq([_bridge.sent.size(), _result_text(), _state_of(late)], [2, _reply_text("impossible"), ContractBook.STATE_ACCEPTED], "Com o prazo passado e antes da hora cheia, a economia recusa com `impossible` e o contrato segue aceito.")


func test_a_paused_clock_disables_accept_and_deliver_and_sends_nothing_even_when_the_pause_comes_after_the_last_query() -> void:
	var open_id: int = _post(_market_a, _market_b, LONG_MINUTES)
	var carried: int = _carry_to_a(LONG_MINUTES)
	_give(BREAD, QUANTITY)
	_open_contracts()
	_select(open_id)
	assert_eq([_is_off(ACCEPT), _is_off(DELIVER)], [false, true], "Pré-condição: andando, Aceitar está ativo.")
	_select(carried)
	assert_eq([_is_off(ACCEPT), _is_off(DELIVER)], [true, false], "Pré-condição: andando, Entregar está ativo.")
	var hash_before: String = _host.runner.world.state_hash()
	assert_true(_bridge.request_pause(true).ok)
	_press(DELIVER)
	_select(open_id)
	_press(ACCEPT)
	assert_eq([_bridge.sent, _host.runner.world.state_hash()], [[] as Array[String], hash_before], "A pausa veio DEPOIS da última consulta (os botões ainda estavam ativos): a `MarketView` confere a pausa na hora de enviar e não envia nada.")
	_view.refresh()
	for contract_id: int in [open_id, carried]:
		_select(contract_id)
		assert_eq([_is_off(ACCEPT), _is_off(DELIVER)], [true, true], "Pausado e consultado de novo, os dois ficam desativados (contrato %d)." % contract_id)
		_press(ACCEPT)
		_press(DELIVER)
	assert_eq([_bridge.sent, _host.runner.world.state_hash()], [[] as Array[String], hash_before], "Pausado, nada é enviado.")
	assert_true(_bridge.request_pause(false).ok)
	_view.refresh()
	assert_eq([_is_off(ACCEPT), _is_off(DELIVER)], [true, false], "Andando de novo, a linha escolhida volta a poder ser entregue.")


func test_with_an_enabled_row_opening_switching_tabs_refreshing_and_closing_still_send_nothing_and_keep_the_state_hash() -> void:
	_post(_market_a, _market_b, LONG_MINUTES)
	var hash_before: String = _host.runner.world.state_hash()
	var minutes_before: int = _bridge.peek_time().total_minutes
	_open_contracts()
	assert_false(_is_off(ACCEPT), "Pré-condição: com uma linha aberta e no prazo, Aceitar está ativo.")
	_view.refresh()
	simulate(_view, 1, MarketView.REFRESH_INTERVAL_S)
	_press(TAB_MARKET)
	_press(TAB_CONTRACTS)
	_view.close()
	assert_eq([_host.runner.world.state_hash(), _bridge.peek_time().total_minutes, _bridge.sent], [hash_before, minutes_before, [] as Array[String]], "Só consultas: sem apertar nada, o `state_hash` e o relógio ficam como estavam e nenhum pedido sai.")


func test_the_page_only_announces_the_click_by_signal_and_never_sends_a_request_itself() -> void:
	var open_id: int = _post(_market_a, _market_b, LONG_MINUTES)
	var carried: int = _carry_to_a(LONG_MINUTES)
	_give(BREAD, QUANTITY)
	var holder: Control = Control.new()
	add_child_autofree(holder)
	var page: ContractsPage = ContractsPage.new()
	page.setup(_bridge, _texts, _actor_id, holder)
	watch_signals(page)
	page.refresh(_market_a, false)
	var accept_button: Button = holder.find_child(ACCEPT, true, false) as Button
	var deliver_button: Button = holder.find_child(DELIVER, true, false) as Button
	accept_button.pressed.emit()
	(holder.find_child(MINE_LIST, true, false) as Tree).get_root().get_first_child().select(ContractsLayout.COLUMN_LINE)
	deliver_button.pressed.emit()
	assert_signal_emitted_with_parameters(page, "accept_requested", [open_id])
	assert_signal_emitted_with_parameters(page, "deliver_requested", [carried])
	assert_eq(_bridge.sent, [] as Array[String], "A página só avisa por sinal: nada foi à ponte.")
	page.refresh(_market_a, true)
	accept_button.pressed.emit()
	deliver_button.pressed.emit()
	assert_eq([get_signal_emit_count(page, "accept_requested"), get_signal_emit_count(page, "deliver_requested")], [1, 1], "Pausada, a página nem avisa: os botões estão desativados.")
