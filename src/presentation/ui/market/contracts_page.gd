class_name ContractsPage
extends RefCounted
## A PÁGINA da aba "Contratos" da tela de mercado (LW-107e2a: extraída da `MarketView` sem mudar comportamento, texto, tecla nem ponte; contrato em docs/modules/presentation.md, "Quadro de contratos (LW-107)"): cria os nós (`ContractsLayout`) sob a
## coluna do painel, liga o `ContractsViewModel` (dados), escreve os textos só por chave (`UiText`), preenche as duas listas e o detalhe e refaz a consulta quando a `MarketView` manda (`refresh`, no ritmo de 1 s da tela), PRESERVANDO a escolha (por
## `contract_id`) e o foco. NÃO abre nem fecha a tela, NÃO troca de aba e NÃO conhece o relógio: a `MarketView` decide e a página só lhe PEDE o fechamento (`close_requested`). SÓ LEITURA por enquanto: Aceitar e Entregar ficam SEMPRE desativados e nada além
## das consultas vai à ponte; a LW-107e2 os liga em `_update_actions`, o ÚNICO lugar que decide os botões; quem ENVIA os pedidos (`request_contract_accept` e `request_contract_deliver`) é a `MarketView`, por sinal da página (o contrato diz que ela é a única que envia). A divisão em "Disponíveis" e "Meus contratos" e o estado mostrado
## (`display_state`) são do modelo: a página só os escreve.

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
const KEY_EXPIRED_NOTE: String = "ui.contracts.expired_note"
const KEY_ACCEPT: String = "ui.contracts.accept"
const KEY_DELIVER: String = "ui.contracts.deliver"
const KEY_CONTRACTS_UNAVAILABLE: String = "ui.contracts.unavailable"
const KEY_CLOSE: String = "ui.market.close"
const KEY_GOOD_NAME: String = "good.%s.name"
const KEY_SETTLEMENT_NAME: String = "settlement.%s.name"
## Separador das informações do detalhe da linha escolhida (como na linha de dicas do mercado).
const FACT_SEPARATOR: String = " · "

## Sai quando o botão "Fechar" da página é apertado; quem fecha a tela é a `MarketView`.
signal close_requested

var _bridge: SimBridge
var _texts: UiText
var _actor_id: int = IdGenerator.NO_ID
var _layout: ContractsLayout = ContractsLayout.new()
var _model: ContractsViewModel = ContractsViewModel.new()
var _contract_rows: Dictionary[int, ContractsViewModel.Row] = {}
var _chosen_contract: int = IdGenerator.NO_ID


## Cria os nós da página sob `parent` (a coluna do painel do mercado, onde ela é IRMÃ da página do mercado e nasce ESCONDIDA), escreve os textos e liga os cliques. Chamar uma vez. Fechar usa o texto `ui.market.close`; a linha de dicas fica vazia e
## ESCONDIDA (a LW-107e2 a preenche, com `hint_accept` e `hint_deliver`, e a mostra).
func setup(bridge: SimBridge, texts: UiText, actor_id: int, parent: Control) -> void:
	_bridge = bridge
	_texts = texts
	_actor_id = actor_id
	_layout.build(parent)
	_layout.title.text = _texts.get_text(KEY_CONTRACTS_TITLE)
	_layout.open_title.text = _texts.get_text(KEY_SECTION_OPEN)
	_layout.mine_title.text = _texts.get_text(KEY_SECTION_MINE)
	_layout.accept_button.text = _texts.get_text(KEY_ACCEPT)
	_layout.deliver_button.text = _texts.get_text(KEY_DELIVER)
	_layout.close_button.text = _texts.get_text(KEY_CLOSE)
	_layout.hints.visible = false
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


## Refaz a consulta de contratos do mercado `market_id` e as duas listas, PRESERVANDO a escolha (por `contract_id`; uma só nas duas listas; sem escolha válida, a primeira linha) e o foco. Falhou (sem jogo ou sem conta): listas vazias, sem
## número da leitura anterior, e `ui.contracts.unavailable` na linha de resultado da aba. Aceitar e Entregar seguem desativados.
func refresh(market_id: int) -> void:
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


## LW-107e2: o ÚNICO lugar que decide Aceitar e Entregar; os pedidos (`request_contract_accept` e `request_contract_deliver`) são ENVIADOS pela `MarketView`, a partir de sinais da página (o contrato diz que ela é a única que envia). Hoje os dois ficam SEMPRE desativados e nada vai à ponte além
## das consultas. É chamado no `setup`, depois de cada leitura (`refresh`) e de cada escolha (`_choose`), os momentos em que a linha escolhida e o estado dos botões mudam; a LW-107e2 acrescenta o relógio pausado, que a `MarketView` já lê para Comprar e Vender.
func _update_actions() -> void:
	_layout.accept_button.disabled = true
	_layout.deliver_button.disabled = true


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


## As informações do detalhe da linha escolhida, na ordem do contrato: bem e quantidade, recompensa, prazo restante (só se há), destino (só se é um mercado), "você tem X de Y", estado e, no vencido, a nota da falha por prazo.
func _facts_of(row: ContractsViewModel.Row) -> String:
	var destination: String = ""
	if not row.destination_settlement_id.is_empty():
		destination = _texts.get_text(KEY_DESTINATION, {"destination": _texts.get_text(KEY_SETTLEMENT_NAME % row.destination_settlement_id)})
	var note: String = _texts.get_text(KEY_EXPIRED_NOTE) if row.display_state == ContractsViewModel.STATE_EXPIRED else ""
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
