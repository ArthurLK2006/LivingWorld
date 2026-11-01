extends Label
## Texto 2D sobreposto à cena: título, versão, data simulada e tecla de pausa.
## Só exibe o que o GameApp entrega; não conhece a simulação.


func _ready() -> void:
	var app: GameAppNode = get_node_or_null("/root/GameApp") as GameAppNode
	if app == null:
		push_error("StatusOverlay: autoload GameApp não encontrado.")
		return
	app.status_changed.connect(_on_status_changed)
	text = app.status_text()


func _on_status_changed(new_text: String) -> void:
	text = new_text
