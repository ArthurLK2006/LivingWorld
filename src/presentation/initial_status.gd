extends Label


func _process(_delta: float) -> void:
	text = "Living World · v0.1\n%s\nEsc: pausar" % get_node("../InitialBridge").status_text()
