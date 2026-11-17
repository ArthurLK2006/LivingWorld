class_name AbandonConfirm
extends RefCounted
## O painel de CONFIRMAÇÃO do abandono (LW-107f4b; contrato em docs/modules/presentation.md, "Encomendas por objetivo: abandonar, confirmar e capacidade", item (d)): um painel modal EM LINHA dentro da página de contratos, com o tema do `MarketTheme` (NÃO uma `Window` do sistema), uma frase
## curta e dois botões, "Abandonar" (com o matiz de perigo do `ContractsLayout`) e "Voltar". Cria os nós (como o `ContractsLayout`) e guarda só o que é dele: o contrato perguntado, o foco e os sinais. NÃO lê a ponte e NÃO envia nada: quem ouve `confirmed` é a `ContractsPage` (que o repassa como
## `abandon_requested`) e quem envia o pedido é a `MarketView` (LW-107f4c). Os textos entram por chave (`UiText`) em `build`.
## ONDE FICA (experimento de 17/11/2026, Godot 4.7.2, `--headless`; o contrato marcava "[A CONFIRMAR]"): o `Control` de tela cheia (`ContractsConfirm`, um `CenterContainer`) é filho da página (`VBoxContainer`) com `top_level = true` e as âncoras `PRESET_FULL_RECT`. O `BoxContainer` pula o filho `top_level`:
## os irmãos, o tamanho mínimo da página e os filhos visíveis da `MarketColumn` ficam idênticos com o painel aberto ou fechado; as âncoras passam a valer em relação à janela inteira (o `Control` cobre a tela e o painel nasce no centro dela); o tema do ancestral continua valendo; e o `mouse_filter` STOP engole
## o clique no resto. Esconder a página ou a tela (um ancestral) dispara o `hidden` do `Control` UMA vez (o painel se fecha sozinho), e o foco SOLTA quando ele some (por isso `close` o devolve a quem o tinha).
## [HIP] o fundo é transparente: escurecê-lo pediria um estilo novo no `MarketTheme`, que fica fora desta tarefa.

const KEY_TEXT: String = "ui.contracts.confirm_text"
const KEY_YES: String = "ui.contracts.confirm_yes"
const KEY_BACK: String = "ui.contracts.confirm_back"
## A ação padrão do Godot que cancela (a outra é `InputActions.INTERACT`); nenhuma tecla nova.
const ACTION_CANCEL: StringName = &"ui_cancel"
## Valor [HIP]: largura mínima do painel, para a frase quebrar em poucas linhas.
const PANEL_MIN_WIDTH_PX: float = 360.0

## Saem só por decisão do JOGADOR: `confirmed` pelo botão "Abandonar" do painel (UMA vez, com o contrato perguntado) e `cancelled` por "Voltar", Esc ou `interact`. Fechar por `close` ou por `keep_if` não emite nenhum dos dois.
signal confirmed(contract_id: int)
signal cancelled

var _veil: CenterContainer
var _yes: Button
var _back: Button
var _contract_id: int = IdGenerator.NO_ID
var _previous_focus: Control


## Cria os nós sob `parent` (a página de contratos), ESCONDIDOS, escreve os textos por chave e liga os cliques. Chamar uma vez. Raiz nula: push_error e nada é criado.
func build(parent: Control, texts: UiText) -> void:
	if parent == null:
		push_error("AbandonConfirm.build: raiz nula; esperado o Control onde o painel se pendura.")
		return
	_veil = _add(parent, CenterContainer.new(), "ContractsConfirm") as CenterContainer
	_veil.top_level = true
	_veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_veil.mouse_filter = Control.MOUSE_FILTER_STOP
	_veil.visible = false
	var panel: Control = _add(_veil, PanelContainer.new(), "ContractsConfirmPanel") as Control
	panel.custom_minimum_size.x = PANEL_MIN_WIDTH_PX
	var column: Node = _add(_add(panel, MarginContainer.new(), "ContractsConfirmMargin"), VBoxContainer.new(), "ContractsConfirmColumn")
	var question: Label = _add(column, Label.new(), "ContractsConfirmText") as Label
	question.theme_type_variation = MarketTheme.STATUS
	question.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	question.text = texts.get_text(KEY_TEXT)
	var row: Node = _add(column, HBoxContainer.new(), "ContractsConfirmRow")
	_yes = _button(row, "ContractsConfirmYes", texts.get_text(KEY_YES))
	_back = _button(row, "ContractsConfirmBack", texts.get_text(KEY_BACK))
	ContractsLayout.mark_as_danger(_yes)
	_trap_focus(_yes, _back)
	_trap_focus(_back, _yes)
	_yes.pressed.connect(_confirm)
	_back.pressed.connect(_cancel)
	_veil.hidden.connect(close)


## Abre o painel para o contrato `contract_id`, guarda quem tinha o foco e põe o foco em "Voltar" (o Enter acidental não abandona). Já aberto, só troca o contrato.
func open(contract_id: int) -> void:
	if _veil == null:
		return
	if not _veil.visible:
		_previous_focus = _veil.get_viewport().gui_get_focus_owner()
	_contract_id = contract_id
	_veil.visible = true
	_back.grab_focus()


## Fecha SEM enviar e SEM avisar (`cancelled` é só do jogador) e devolve o foco a quem o tinha, se esse controle ainda aparece. Fechado, não faz nada; o `hidden` do `Control` também chama aqui (e o `visible = false` abaixo o dispara de novo, já sem efeito).
func close() -> void:
	if not is_open():
		return
	_contract_id = IdGenerator.NO_ID
	_veil.visible = false
	if is_instance_valid(_previous_focus) and _previous_focus.is_visible_in_tree():
		_previous_focus.grab_focus()
	_previous_focus = null


func is_open() -> bool:
	return _veil != null and _veil.visible


## O contrato que o painel pergunta agora (`IdGenerator.NO_ID` com o painel fechado): a página o consulta a cada leitura para dizer se ele ainda é abandonável.
func asked_contract_id() -> int:
	return _contract_id


## A regra "o contrato deixa de ser abandonável com o painel aberto" (entregue, vencido, abandonado em outro lugar, relógio pausado): o painel FECHA sozinho, sem enviar. `is_abandonable` é a resposta da página para o contrato perguntado; verdadeiro não muda nada.
func keep_if(is_abandonable: bool) -> void:
	if not is_abandonable:
		close()


## Esc (`ui_cancel`) e `interact` só CANCELAM o painel aberto: devolve verdadeiro se ele estava aberto e cancelou (a `MarketView` então cede a vez: a tela só fecha com o painel já fechado) e falso em qualquer outro caso.
func consume_cancel(event: InputEvent) -> bool:
	if not is_open() or not (event.is_action_pressed(ACTION_CANCEL) or event.is_action_pressed(InputActions.INTERACT)):
		return false
	_cancel()
	return true


## O "Abandonar" do painel: fecha ANTES de avisar, então um segundo clique não reenvia.
func _confirm() -> void:
	if not is_open():
		return
	var asked: int = _contract_id
	close()
	confirmed.emit(asked)


func _cancel() -> void:
	if not is_open():
		return
	close()
	cancelled.emit()


## Dá o nome fixo ao nó, pendura-o no pai e o devolve.
static func _add(parent: Node, node: Node, node_name: String) -> Node:
	node.name = node_name
	parent.add_child(node)
	return node


static func _button(parent: Node, node_name: String, caption: String) -> Button:
	var button: Button = _add(parent, Button.new(), node_name) as Button
	button.text = caption
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return button


## Fecha o foco dentro do painel: Tab, Shift+Tab e as quatro setas de `button` levam SEMPRE ao outro botão (o foco circula entre os dois e nunca sai). As setas PRECISAM disto (sem vizinho explícito o Godot procura o controle mais próximo da tela, dentro ou fora do painel); o Tab e o Shift+Tab o Godot 4.7.2 já mantém dentro de um `Control` `top_level` (experimento), e as duas linhas o tornam explícito, sem depender da travessia do motor.
static func _trap_focus(button: Button, other: Button) -> void:
	var path: NodePath = button.get_path_to(other)
	button.focus_next = path
	button.focus_previous = path
	button.focus_neighbor_left = path
	button.focus_neighbor_right = path
	button.focus_neighbor_top = path
	button.focus_neighbor_bottom = path
