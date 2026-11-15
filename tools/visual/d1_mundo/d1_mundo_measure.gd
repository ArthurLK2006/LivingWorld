extends SceneTree
## D1-B (estudo isolado, só cálculo, roda com --headless): triângulos, nós e superfícies por peça da praça de demonstração de cada variante (ver D1MundoOptions).
## Uso: godot --headless --path <projeto> -s res://tools/visual/d1_mundo/d1_mundo_measure.gd -- [a a_lean d]  (sem argumentos: a e d)

## Grupos de peças, pelo prefixo do nome do nó.
const GROUPS: Array[String] = ["Stall", "Well", "Crate", "Barrel", "Sack", "LampPost", "Bunting", "Torch", "House", "Tree", "Rock", "Ground", "Grass", "Flowers"]


func _initialize() -> void:
	var ids: PackedStringArray = OS.get_cmdline_user_args()
	if ids.is_empty():
		ids = PackedStringArray(["a", "d"])
	for variant_id: String in ids:
		_report(variant_id)
	quit()


func _report(variant_id: String) -> void:
	var plaza: Node3D = Node3D.new()
	root.add_child(plaza)
	var built: PlazaBuilder.Built = PlazaBuilder.new().build(plaza, D1MundoOptions.for_variant(variant_id))
	var total: int = 0
	var lines: Array[String] = []
	for group: String in GROUPS:
		var pieces: int = 0
		var triangles: int = 0
		var surfaces: int = 0
		var smallest: int = 1 << 30
		var biggest: int = 0
		for node: Node in plaza.get_children():
			if node.name.begins_with(group) and node is MeshInstance3D:
				var mesh: Mesh = (node as MeshInstance3D).mesh
				var count: int = int(mesh.get_faces().size() / 3.0)
				pieces += 1
				triangles += count
				surfaces += mesh.get_surface_count()
				smallest = mini(smallest, count)
				biggest = maxi(biggest, count)
			elif node.name.begins_with(group) and node is MultiMeshInstance3D:
				var multimesh: MultiMesh = (node as MultiMeshInstance3D).multimesh
				pieces += 1
				triangles += multimesh.instance_count * int(multimesh.mesh.get_faces().size() / 3.0)
				surfaces += multimesh.mesh.get_surface_count()
				smallest = 0
		if pieces > 0:
			lines.append("  %-9s peças %3d | triângulos %6d (por peça: média %7.1f, mín %d, máx %d) | superfícies %d" % [group, pieces, triangles, float(triangles) / pieces, smallest, biggest, surfaces])
			total += triangles
	print("== variante %s: %d triângulos no total | %d nós | %d materiais" % [variant_id, total, plaza.find_children("*", "", true, false).size(), built.materials.size()])
	for line: String in lines:
		print(line)
	plaza.queue_free()
