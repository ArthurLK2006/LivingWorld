extends SceneTree


func _initialize() -> void:
	var arguments: PackedStringArray = OS.get_cmdline_user_args()
	var scene_path: String = arguments[0] if not arguments.is_empty() else "res://scenes/main.tscn"
	if not ResourceLoader.exists(scene_path, "PackedScene"):
		_fail("cena inexistente: " + scene_path)
		return
	var scene: PackedScene = load(scene_path) as PackedScene
	if scene == null:
		_fail("não foi possível carregar a cena: " + scene_path)
		return
	var instance: Node = scene.instantiate()
	var counts: Dictionary = {"camera": 0, "sun": 0, "environment": 0, "terrain_view": 0}
	_count_nodes(instance, counts)
	instance.free()
	if counts["camera"] != 1 or counts["sun"] != 1 or counts["environment"] != 1 or counts["terrain_view"] != 1:
		_fail("componentes da cena não correspondem ao esperado")
		return
	print("SMOKE_TEST: PASS")
	quit(0)


func _count_nodes(node: Node, counts: Dictionary) -> void:
	if node is Camera3D:
		counts["camera"] += 1
	if node is DirectionalLight3D:
		counts["sun"] += 1
	if node is WorldEnvironment:
		counts["environment"] += 1
	if node is TerrainView:
		counts["terrain_view"] += 1
	for child: Node in node.get_children():
		_count_nodes(child, counts)


func _fail(message: String) -> void:
	print("SMOKE_TEST: FAIL " + message)
	quit(1)
