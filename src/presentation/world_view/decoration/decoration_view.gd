class_name DecorationView
extends Node3D
## Árvores e pedras (LW-043): UM MultiMeshInstance3D por chunk E por tipo, só nos chunks que têm instâncias, filhos desta
## view. Só visual: sem colisão, não é recurso de jogo, nada é salvo (decisão E4 de Arthur). A altura de cada instância
## vem da ponte (peek_height); posição, giro e escala vêm do arquivo. Um só material (cor de vértice). Todos os MultiMesh
## nascem ESCONDIDOS e só ficam visíveis enquanto o terreno do chunk existe (set_chunk_visible, LW-040): sem isso as árvores
## flutuariam no vazio onde o terreno foi descartado. Contrato: docs/modules/presentation.md.

const CM_PER_METER: float = 100.0
const PERCENT: float = 100.0

var _multimesh_instances: Array[MultiMeshInstance3D] = []
var _instance_counts: Dictionary[String, int] = {}
## Transformações montadas, por nome do nó. Ficam guardadas aqui porque, sem janela (renderizador "dummy"), o MultiMesh
## não devolve o que recebeu e os testes não poderiam conferir posição e altura.
var _transforms: Dictionary[String, Array] = {}
## MultiMeshInstance3D de cada chunk (um por tipo), para ligar e desligar a visibilidade sem procurar.
var _instances_by_chunk: Dictionary[Vector2i, Array] = {}


## Monta os MultiMesh a partir dos itens lidos. Ponte nula ou sem terreno: push_error e nada é construído.
func setup(bridge: SimBridge, items: Array[DecorationReader.Item]) -> void:
	_clear()
	if bridge == null:
		push_error("DecorationView.setup: ponte nula; esperado uma SimBridge.")
		return
	var layout: SimBridge.TerrainLayoutReply = bridge.peek_terrain_layout()
	if not layout.result.ok:
		push_error("DecorationView.setup: formato do terreno indisponível (%s): %s" % [layout.result.code, layout.result.message])
		return
	var chunk_size_cm: int = roundi(float(layout.chunk_cells) * layout.cell_size_m * CM_PER_METER)
	var groups: Dictionary[String, Array] = {}
	for item: DecorationReader.Item in items:
		var key: String = "%s_%d_%d" % [item.kind, IntMath.floor_div(item.x_cm, chunk_size_cm), IntMath.floor_div(item.z_cm, chunk_size_cm)]
		if not groups.has(key):
			groups[key] = []
		groups[key].append(item)
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	var meshes: Dictionary[String, ArrayMesh] = {DecorationReader.KIND_TREE: DecorationShapes.tree_mesh(), DecorationReader.KIND_ROCK: DecorationShapes.rock_mesh()}
	var keys: Array = groups.keys()
	keys.sort()
	for key: String in keys:
		var group: Array = groups[key]
		var first: DecorationReader.Item = group[0]
		var chunk: Vector2i = Vector2i(IntMath.floor_div(first.x_cm, chunk_size_cm), IntMath.floor_div(first.z_cm, chunk_size_cm))
		_add_group(bridge, key, first.kind, group, chunk, meshes[first.kind], material)


## Mostra ou esconde as decorações (árvores e pedras) do chunk; chunk sem decoração não faz nada.
func set_chunk_visible(chunk: Vector2i, shown: bool) -> void:
	for instance: MultiMeshInstance3D in _instances_by_chunk.get(chunk, []):
		instance.visible = shown


## Instâncias montadas de um tipo ("tree" ou "rock"), somando todos os chunks.
func instance_count(kind: String) -> int:
	return _instance_counts.get(kind, 0)


func multimesh_instances() -> Array[MultiMeshInstance3D]:
	return _multimesh_instances


## Transformações (posição no mundo, giro e escala) das instâncias de um MultiMeshInstance3D desta view.
func transforms_of(instance: MultiMeshInstance3D) -> Array[Transform3D]:
	var result: Array[Transform3D] = []
	result.assign(_transforms.get(instance.name, []))
	return result


func _add_group(bridge: SimBridge, key: String, kind: String, group: Array, chunk: Vector2i, mesh: ArrayMesh, material: StandardMaterial3D) -> void:
	var transforms: Array[Transform3D] = []
	for entry: DecorationReader.Item in group:
		var x: float = float(entry.x_cm) / CM_PER_METER
		var z: float = float(entry.z_cm) / CM_PER_METER
		var height: SimBridge.HeightReply = bridge.peek_height(x, z)
		if not height.result.ok:
			push_error("DecorationView: altura indisponível em (x=%s, z=%s): %s" % [str(x), str(z), height.result.message])
			continue
		var orientation: Basis = Basis(Vector3.UP, deg_to_rad(float(entry.yaw_deg))).scaled(Vector3.ONE * float(entry.scale_pct) / PERCENT)
		transforms.append(Transform3D(orientation, Vector3(x, height.height_m, z)))
	if transforms.is_empty():
		return
	var multimesh: MultiMesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = mesh
	multimesh.instance_count = transforms.size()
	for index: int in range(transforms.size()):
		multimesh.set_instance_transform(index, transforms[index])
	var instance: MultiMeshInstance3D = MultiMeshInstance3D.new()
	instance.name = "Deco_%s" % key
	instance.multimesh = multimesh
	instance.material_override = material
	instance.visible = false
	add_child(instance)
	_multimesh_instances.append(instance)
	if not _instances_by_chunk.has(chunk):
		_instances_by_chunk[chunk] = []
	_instances_by_chunk[chunk].append(instance)
	_transforms[instance.name] = transforms
	_instance_counts[kind] = _instance_counts.get(kind, 0) + transforms.size()


func _clear() -> void:
	for instance: MultiMeshInstance3D in _multimesh_instances:
		remove_child(instance)
		instance.free()
	_multimesh_instances.clear()
	_instance_counts.clear()
	_transforms.clear()
	_instances_by_chunk.clear()
