class_name EconomyInspectorMount
extends RefCounted
## Onde o painel de depuração da economia é montado (LW-108d; contrato em docs/modules/tools.md, "Painel econômico"): **só em build de desenvolvimento**, sem autoload (como o painel de NPC). O sinal de
## desenvolvimento entra por PARÂMETRO (`is_development_build`; quem chama lê `OS.is_debug_build()`), então o teste prova os dois casos. Fora de desenvolvimento o painel nem é criado: nenhum nó, nenhuma
## consulta à ponte, nenhuma tecla tratada. Quem monta deve fazê-lo DEPOIS do painel de NPC: o Godot entrega a entrada não tratada do último nó da árvore para o primeiro, e é assim que o Shift+Tab chega
## ao painel da economia antes de o painel de NPC ver o Tab.

const PANEL_NAME: String = "EconomyInspectorPanel"


## Cria o painel como filho de `parent` e o liga à ponte e aos textos. Devolve o painel, ou nulo se não é build de desenvolvimento (nada é criado) ou se a ligação falhar (o painel já registrou o motivo e é solto).
static func mount(parent: Node, bridge: SimBridge, texts: UiText, is_development_build: bool) -> EconomyInspectorPanel:
	if not is_development_build:
		return null
	var panel: EconomyInspectorPanel = EconomyInspectorPanel.new()
	panel.name = PANEL_NAME
	if not panel.setup(bridge, texts):
		panel.free()
		return null
	parent.add_child(panel)
	return panel
