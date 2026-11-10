class_name NpcInspectorMount
extends RefCounted
## Onde o painel de depuração de NPC é montado (LW-082g; contrato em docs/modules/tools.md): **só em build de desenvolvimento**, sem autoload (decisão de Arthur).
## O sinal de desenvolvimento entra por PARÂMETRO (`is_development_build`; quem chama lê `OS.is_debug_build()`, como o `GameApp` faz), então o teste prova os dois
## casos. Fora de desenvolvimento o painel nem é criado: nenhum nó, nenhuma consulta à ponte, nenhuma tecla tratada.

const PANEL_NAME: String = "NpcInspectorPanel"


## Cria o painel como filho de `parent` e o liga à ponte e aos textos. Devolve o painel, ou nulo se não é build de desenvolvimento (nada é criado) ou se a ligação
## falhar (o painel já registrou o motivo e é solto).
static func mount(parent: Node, bridge: SimBridge, texts: UiText, is_development_build: bool) -> NpcInspectorPanel:
	if not is_development_build:
		return null
	var panel: NpcInspectorPanel = NpcInspectorPanel.new()
	panel.name = PANEL_NAME
	if not panel.setup(bridge, texts):
		panel.free()
		return null
	parent.add_child(panel)
	return panel
