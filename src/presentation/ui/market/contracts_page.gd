class_name ContractsPage
extends RefCounted
## A PÁGINA da aba "Contratos" da tela de mercado (LW-107e2a: extraída da `MarketView` sem mudar comportamento, texto, tecla nem ponte; contrato em docs/modules/presentation.md, "Quadro de contratos (LW-107)"): cria os nós (`ContractsLayout`) sob a
## coluna do painel, liga o `ContractsViewModel` (dados), escreve os textos só por chave (`UiText`), preenche as duas listas e o detalhe e refaz a consulta quando a `MarketView` manda (`refresh`, no ritmo de 1 s da tela), PRESERVANDO a escolha (por
## `contract_id`) e o foco. NÃO abre nem fecha a tela, NÃO troca de aba e NÃO lê o relógio: a `MarketView` decide, lhe diz se está pausado (`refresh`) e a página só lhe PEDE o fechamento (`close_requested`). LW-107e2b: Aceitar e Entregar são ligados em `_update_actions`, o ÚNICO lugar que
## decide os botões e as dicas; a página NÃO envia pedido nenhum à ponte (só consulta): quem ENVIA `request_contract_accept` e `request_contract_deliver` é a `MarketView`, ouvindo os sinais `accept_requested` e `deliver_requested` da página (o contrato diz que ela é a única que envia), e a resposta volta
## por `show_reply`. A divisão em "Disponíveis" e "Meus contratos" e o estado mostrado (`display_state`) são do modelo: a página só os escreve. LW-107f4a (docs/modules/presentation.md, "Encomendas por objetivo: abandonar, confirmar e capacidade"): o botão Abandonar só AVISA, pelo
## sinal `abandon_asked` (LW-107f4b: a própria página o ouve e abre o painel de confirmação, `AbandonConfirm`); Aceitar fica desativado quando o jogador já está na capacidade (só dica: a ponte decide e recusa com `economy.contract.limit`); a linha da capacidade ("n de N") fica escondida sem limite definido;
## e as linhas terminadas mostram "Abandonado" (com a nota de que não há multa), "Falhou" ou "Vencido", sempre diferentes entre si. LW-107f4b: só o "Abandonar" do painel faz a página emitir `abandon_requested` (a `MarketView` o ligará a `request_contract_abandon` na 107f4c); o `refresh` fecha o painel
## sozinho se a linha deixa de ser abandonável ou o relógio para (`keep_if`), e a tela ou a página que escondem o fecham (o próprio painel ouve o `hidden`); a página continua SÓ consultando a ponte.

## Chaves de texto da página (as frases moram em data/text/pt_br.json); o estado mostrado entra pelo prefixo (`ui.contracts.state.open`, `accepted`, `completed` e `expired`).
const KEY_CONTRACTS_TITLE: String = "ui.contracts.title"
const KEY_SECTION_OPEN: String = "ui.contracts.section_open"
const KEY_SECTION_MINE: String = "ui.contracts.section_mine"
const KEY_EMPTY: String = "ui.contracts.empty"
const KEY_EMPTY_MINE: String = "ui.contracts.empty_mine"
const KEY_LINE: String = "ui.contracts.line"
const KEY_REWARD: String = "ui.contracts.reward"
const KEY_DEADLINE: String = "ui.contracts.deadline"
const KEY_DESTINATION: String = "ui.contracts.destination"
const KEY_OWNED: String = "ui.contracts.owned"
const KEY_STATE_PREFIX: String = "ui.contracts.state."
const KEY_ACCEPT: String = "ui.contracts.accept"
const KEY_DELIVER: String = "ui.contracts.deliver"
const KEY_ABANDON: String = "ui.contracts.abandon"
const KEY_CAPACITY: String = "ui.contracts.capacity"
const KEY_CONTRACTS_UNAVAILABLE: String = "ui.contracts.unavailable"
const KEY_CLOSE: String = "ui.market.close"
## A nota do detalhe de cada estado mostrado que a tem: o "Vencido" e o "Abandonado" (o "Falhou" não tem nota).
const KEY_NOTES: Dictionary[String, String] = {ContractsViewModel.STATE_EXPIRED: "ui.contracts.expired_note", ContractsViewModel.STATE_ABANDONED: "ui.contracts.abandoned_note"}
## A dica de uso de cada estado mostrado em que ainda há o que fazer (a regra está em `_update_actions`).
const KEY_HINTS: Dictionary[String, String] = {
	ContractsViewModel.STATE_OPEN: "ui.contracts.hint_accept",
	ContractsViewModel.STATE_ACCEPTED: "ui.contracts.hint_deliver",
}
const KEY_GOOD_NAME: String = "good.%s.name"
const KEY_SETTLEMENT_NAME: String = "settlement.%s.name"
## Separador das informações do detalhe da linha escolhida (como na linha de dicas do mercado).
const FACT_SEPARATOR: String = " · "

## Sai quando o botão "Fechar" da página é apertado; quem fecha a tela é a `MarketView`.
signal close_requested
## Saem quando Aceitar ou Entregar é apertado COM o botão ativo, trazendo o contrato escolhido; quem ENVIA o pedido é a `MarketView`, nunca a página.
signal accept_requested(contract_id: int)
signal deliver_requested(contract_id: int)
## Sai quando Abandonar é apertado COM o botão ativo, trazendo o contrato escolhido; a própria página o ouve e abre o painel de confirmação (LW-107f4b).
signal abandon_asked(contract_id: int)
## Sai quando o "Abandonar" do PAINEL de confirmação é apertado, trazendo o contrato perguntado; quem ENVIA o pedido é a `MarketView` (LW-107f4c: ninguém o ouve ainda), nunca a página.
signal abandon_requested(contract_id: int)

var _bridge: SimBridge
var _texts: UiText
var _actor_id: int = IdGenerator.NO_ID
var _is_paused: bool = false
var _layout: ContractsLayout = ContractsLayout.new()
var _confirm: AbandonConfirm = AbandonConfirm.new()
var _model: ContractsViewModel = ContractsViewModel.new()
var _contract_rows: Dictionary[int, ContractsViewModel.Row] = {}
var _chosen_contract: int = IdGenerator.NO_ID


## Cria os nós da página sob `parent` (a coluna do painel do mercado, onde ela é IRMÃ da página do mercado e nasce ESCONDIDA), escreve os textos e liga os cliques. Chamar uma vez. Fechar usa o texto `ui.market.close`; a linha de dicas nasce vazia e
## ESCONDIDA (`_update_actions` a preenche, com `hint_accept` e `hint_deliver`, e a mostra).
func setup(bridge: SimBridge, texts: UiText, actor_id: int, parent: Control) -> void:
	_bridge = bridge
	_texts = texts
	_actor_id = actor_id
	_layout.build(parent)
	_confirm.build(_layout.page, _texts)
	_layout.title.text = _texts.get_text(KEY_CONTRACTS_TITLE)
	_layout.open_title.text = _texts.get_text(KEY_SECTION_OPEN)
	_layout.mine_title.text = _texts.get_text(KEY_SECTION_MINE)
	_layout.accept_button.text = _texts.get_text(KEY_ACCEPT)
	_layout.deliver_button.text = _texts.get_text(KEY_DELIVER)
	_layout.abandon_button.text = _texts.get_text(KEY_ABANDON)
	_layout.close_button.text = _texts.get_text(KEY_CLOSE)
	_layout.accept_button.pressed.connect(_notify.bind(accept_requested, _layout.accept_button))
	_layout.deliver_button.pressed.connect(_notify.bind(deliver_requested, _layout.deliver_button))
	_layout.abandon_button.pressed.connect(_notify.bind(abandon_asked, _layout.abandon_button))
	abandon_asked.connect(_confirm.open)
	_confirm.confirmed.connect(abandon_requested.emit)
	_layout.close_button.pressed.connect(close_requested.emit)
	_layout.open_list.item_selected.connect(_choose.bind(_layout.open_list))
	_layout.mine_list.item_selected.connect(_choose.bind(_layout.mine_list))
	_update_actions()


## Abre a página: apaga o aviso da linha de resultado (o `refresh` que vem em seguida o refaz se a consulta falhar).
func open() -> void:
	_layout.result.text = ""


## Mostra ou esconde a página. Só `visible` muda: nenhum nó muda de pai.
func set_shown(is_shown: bool) -> void:
	_layout.page.visible = is_shown


## A lista que recebe o foco quando a página é escolhida (a primeira, "Disponíveis neste mercado").
func main_list() -> Tree:
	return _layout.open_list


## Esc (`ui_cancel`) e `interact` só cancelam o painel de confirmação aberto: devolve verdadeiro se ele estava aberto e cancelou. A `MarketView` o chama no início do `_input` (LW-107f4c) e, com verdadeiro, cede a vez: a tela só fecha com o painel já fechado.
func consume_cancel(event: InputEvent) -> bool:
	return _confirm.consume_cancel(event)


## Refaz a consulta de contratos do mercado `market_id` e as duas listas, PRESERVANDO a escolha (por `contract_id`; uma só nas duas listas; sem escolha válida, a primeira linha) e o foco. Falhou (sem jogo ou sem conta): listas vazias, sem
## número da leitura anterior, e `ui.contracts.unavailable` na linha de resultado da aba; Aceitar e Entregar ficam desativados (sem linha escolhida). `is_paused` é o relógio pausado, lido pela `MarketView` como faz para Comprar e Vender: pausado, os dois ficam desativados.
## LW-107f4b: o painel de confirmação aberto se fecha sozinho, SEM enviar nada, se o contrato que ele pergunta deixou de ser abandonável nesta leitura (`keep_if`).
func refresh(market_id: int, is_paused: bool) -> void:
	_is_paused = is_paused
	var is_valid: bool = _model.refresh(_bridge, _actor_id, market_id)
	var open_rows: Array[ContractsViewModel.Row] = _model.available()
	var mine_rows: Array[ContractsViewModel.Row] = _model.mine()
	var listed: Array[ContractsViewModel.Row] = open_rows + mine_rows
	_contract_rows.clear()
	for row: ContractsViewModel.Row in listed:
		_contract_rows[row.contract_id] = row
	if not _contract_rows.has(_chosen_contract):
		_chosen_contract = listed[0].contract_id if not listed.is_empty() else IdGenerator.NO_ID
	if is_valid:
		_fill_list(_layout.open_list, open_rows, KEY_EMPTY)
		_fill_list(_layout.mine_list, mine_rows, KEY_EMPTY_MINE)
	else:
		_layout.open_list.clear()
		_layout.mine_list.clear()
		_layout.result.text = _texts.get_text(KEY_CONTRACTS_UNAVAILABLE)
	_show_detail()
	_update_actions()
	_confirm.keep_if(_is_abandonable(_confirm.asked_contract_id()))


## Escreve a resposta de um pedido na linha de resultado: o texto da `text_key` que a ponte devolveu, com a recompensa no `{reward}` das frases de sucesso (`economy.contract.accepted` e `delivered`; nas recusas ela é 0 e a frase não a usa). SÓ escreve: quem envia o pedido é a `MarketView`.
func show_reply(reply: BridgePlayerContractsReplies.ContractActionReply) -> void:
	_layout.result.text = _texts.get_text(reply.text_key, {"reward": reply.reward})


## LW-107e2b: o ÚNICO lugar que decide Aceitar, Entregar e as dicas; os pedidos (`request_contract_accept` e `request_contract_deliver`) são ENVIADOS pela `MarketView`, a partir dos sinais da página (o contrato diz que ela é a única que envia). **Aceitar** só com a linha escolhida em "Disponíveis"
## com `display_state` `open` (não vencida: a linha "Vencido" não se aceita) e o relógio andando. **Entregar** só com a linha escolhida em "Meus contratos" com `can_deliver` (a dica do modelo: a ponte e a economia decidem) e o relógio andando. Relógio pausado, sem linha, linha vencida, `completed` ou `expired`:
## os dois desativados. **Dicas:** a linha de dicas mostra `hint_accept` com uma linha `open` escolhida e `hint_deliver` com uma `accepted` escolhida (ambas no prazo: o estado mostrado, não o da ponte), a regra do que ainda há a fazer naquela linha, e fica vazia e escondida nas demais (sem linha, `completed`, "Vencido").
## LW-107f4a: **Abandonar** só com a linha escolhida em "Meus contratos" com `can_abandon` (a dica do modelo: minha, `accepted` e no prazo) e o relógio andando; **Aceitar** também fica desativado com a capacidade definida (maior que 0) já alcançada por `accepted_count()`, e a linha da
## capacidade mostra "n de N" só com a capacidade definida. É chamado no `setup`, depois de cada leitura (`refresh`) e de cada escolha (`_choose`), os momentos em que a linha escolhida e o relógio mudam.
func _update_actions() -> void:
	var row: ContractsViewModel.Row = _contract_rows.get(_chosen_contract) as ContractsViewModel.Row
	var shown_state: String = row.display_state if row != null else ""
	var hint_key: String = KEY_HINTS.get(shown_state, "")
	var is_full: bool = _model.capacity() > 0 and _model.accepted_count() >= _model.capacity()
	_layout.accept_button.disabled = _is_paused or shown_state != ContractsViewModel.STATE_OPEN or is_full
	_layout.deliver_button.disabled = _is_paused or row == null or not row.can_deliver
	_layout.abandon_button.disabled = not _is_abandonable(_chosen_contract)
	_layout.capacity.visible = _model.capacity() > 0
	_layout.capacity.text = _texts.get_text(KEY_CAPACITY, {"accepted": _model.accepted_count(), "limit": _model.capacity()}) if _layout.capacity.visible else ""
	_layout.hints.text = _texts.get_text(hint_key) if not hint_key.is_empty() else ""
	_layout.hints.visible = not hint_key.is_empty()


## LW-107f4b: a regra do Abandonar, num lugar só: o contrato é uma linha da última leitura com `can_abandon` (a dica do modelo: minha, `accepted` e no prazo) e o relógio anda. Vale para o botão da página (`_update_actions`) e para o painel de confirmação aberto, que o `refresh` fecha se ela deixa de valer.
func _is_abandonable(contract_id: int) -> bool:
	var row: ContractsViewModel.Row = _contract_rows.get(contract_id) as ContractsViewModel.Row
	return not _is_paused and row != null and row.can_abandon


## O clique de um botão vira o aviso `requested` com o contrato ESCOLHIDO, só se o botão está ativo (a regra é de `_update_actions`; o clique de verdade nem chega num botão desativado, mas o sinal `pressed` pode ser emitido à mão).
func _notify(requested: Signal, button: Button) -> void:
	if not button.disabled:
		requested.emit(_chosen_contract)


## Refaz uma lista: uma linha por contrato (o `contract_id` fica no metadado da primeira coluna) e a escolhida volta a ser escolhida; lista vazia mostra a mensagem da chave, numa linha que não se escolhe. [LIM] Refazer a lista reinicia a rolagem (aceito: a escolha e
## o foco sobrevivem).
func _fill_list(tree: Tree, rows: Array[ContractsViewModel.Row], empty_key: String) -> void:
	tree.clear()
	var root: TreeItem = tree.create_item()
	if rows.is_empty():
		var note: TreeItem = tree.create_item(root)
		note.set_text(ContractsLayout.COLUMN_LINE, _texts.get_text(empty_key))
		note.set_expand_right(ContractsLayout.COLUMN_LINE, true)
		for column: int in ContractsLayout.COLUMN_COUNT:
			note.set_selectable(column, false)
		return
	for row: ContractsViewModel.Row in rows:
		var item: TreeItem = tree.create_item(root)
		var deadline: String = _deadline_of(row)
		item.set_metadata(ContractsLayout.COLUMN_LINE, row.contract_id)
		item.set_text(ContractsLayout.COLUMN_LINE, _line_of(row))
		item.set_text(ContractsLayout.COLUMN_REWARD, _reward_of(row))
		item.set_text(ContractsLayout.COLUMN_WHEN, deadline if not deadline.is_empty() else _state_of(row))
		if row.contract_id == _chosen_contract:
			item.select(ContractsLayout.COLUMN_LINE)


## A linha que acabou de ser escolhida numa das listas passa a ser A escolhida: a escolha da outra lista sai e o detalhe mostra a nova.
func _choose(tree: Tree) -> void:
	var item: TreeItem = tree.get_selected()
	if item == null:
		return
	_chosen_contract = int(item.get_metadata(ContractsLayout.COLUMN_LINE))
	var other: Tree = _layout.mine_list if tree == _layout.open_list else _layout.open_list
	other.deselect_all()
	_show_detail()
	_update_actions()


func _show_detail() -> void:
	var row: ContractsViewModel.Row = _contract_rows.get(_chosen_contract) as ContractsViewModel.Row
	_layout.detail.text = "" if row == null else _facts_of(row)


## As informações do detalhe da linha escolhida, na ordem do contrato: bem e quantidade, recompensa, prazo restante (só se há), destino (só se é um mercado), "você tem X de Y", estado e a nota do estado (no vencido, a do prazo; no abandonado, a de que não há multa).
func _facts_of(row: ContractsViewModel.Row) -> String:
	var destination: String = ""
	if not row.destination_settlement_id.is_empty():
		destination = _texts.get_text(KEY_DESTINATION, {"destination": _texts.get_text(KEY_SETTLEMENT_NAME % row.destination_settlement_id)})
	var note: String = _texts.get_text(KEY_NOTES[row.display_state]) if KEY_NOTES.has(row.display_state) else ""
	var owned: String = _texts.get_text(KEY_OWNED, {"owned": row.owned, "quantity": row.quantity})
	var shown: PackedStringArray = []
	for fact: String in [_line_of(row), _reward_of(row), _deadline_of(row), destination, owned, _state_of(row), note]:
		if not fact.is_empty():
			shown.append(fact)
	return FACT_SEPARATOR.join(shown)


func _line_of(row: ContractsViewModel.Row) -> String:
	return _texts.get_text(KEY_LINE, {"quantity": row.quantity, "good": _texts.get_text(KEY_GOOD_NAME % row.good_id)})


func _reward_of(row: ContractsViewModel.Row) -> String:
	return _texts.get_text(KEY_REWARD, {"reward": row.reward})


## O estado que a tela MOSTRA (`display_state`): "Vencido" para todo contrato de prazo passado.
func _state_of(row: ContractsViewModel.Row) -> String:
	return _texts.get_text(KEY_STATE_PREFIX + row.display_state)


## O prazo restante em dias, horas e minutos, SÓ para a linha `open` ou `accepted` que NÃO venceu (a regra usa `display_state`, nunca `is_overdue` sozinho); vazio nas demais: a `expired` mostra "Vencido" no lugar dele e a `completed`
## não mostra prazo nenhum, mesmo com o prazo passado.
func _deadline_of(row: ContractsViewModel.Row) -> String:
	if row.display_state != ContractsViewModel.STATE_OPEN and row.display_state != ContractsViewModel.STATE_ACCEPTED:
		return ""
	var day: int = IntMath.floor_div(row.minutes_left, SimClock.MINUTES_PER_DAY)
	var hour: int = IntMath.floor_div(row.minutes_left % SimClock.MINUTES_PER_DAY, SimClock.MINUTES_PER_HOUR)
	return _texts.get_text(KEY_DEADLINE, {"d": day, "h": hour, "m": row.minutes_left % SimClock.MINUTES_PER_HOUR})
