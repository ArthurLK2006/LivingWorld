extends RefCounted
## ART-11 (teste isolado): montador modular. Um Skeleton3D mestre ("Skeleton3D", filho direto da raiz do personagem) recebe as malhas das peças; cada peça é um .gltf com o MESMO esqueleto de 65 ossos, então basta passar a MeshInstance3D (com o seu Skin, que liga por nome de osso) para o esqueleto mestre. `add_part` num encaixe já ocupado troca a peça.

const Look := preload("res://tools/visual/quaternius_test/qt_look.gd")

var root: Node3D = Node3D.new()
var skeleton: Skeleton3D = null
var slots: Dictionary = {}
var look: int = 0
var notes: PackedStringArray = PackedStringArray()


func _init(look_mode: int) -> void:
	look = look_mode
	root.name = "Personagem"


func add_part(slot: String, path: String, keep: PackedStringArray = PackedStringArray()) -> void:
	remove_slot(slot)
	var inst: Node = (load(path) as PackedScene).instantiate()
	var source: Skeleton3D = inst.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
	var meshes: Array[Node] = inst.find_children("*", "MeshInstance3D", true, false)
	if skeleton == null:
		var accumulated: Transform3D = Transform3D.IDENTITY
		var walker: Node = source
		while walker is Node3D:
			accumulated = (walker as Node3D).transform * accumulated
			walker = walker.get_parent()
		source.get_parent().remove_child(source)
		source.owner = null
		source.name = "Skeleton3D"
		source.transform = accumulated
		root.add_child(source)
		skeleton = source
	var added: Array[MeshInstance3D] = []
	for node: Node in meshes:
		var mi: MeshInstance3D = node as MeshInstance3D
		if mi.get_parent() != skeleton:
			mi.get_parent().remove_child(mi)
			mi.owner = null
			skeleton.add_child(mi)
		if not mi.transform.is_equal_approx(Transform3D.IDENTITY):
			notes.append("%s: malha %s com transformação diferente da identidade (zerada)" % [slot, mi.name])
			mi.transform = Transform3D.IDENTITY
		mi.skeleton = NodePath("..")
		Look.apply(mi, look, keep)
		added.append(mi)
	slots[slot] = added
	inst.free()


func remove_slot(slot: String) -> void:
	if not slots.has(slot):
		return
	for mi: MeshInstance3D in slots[slot]:
		mi.get_parent().remove_child(mi)
		mi.free()
	slots.erase(slot)
