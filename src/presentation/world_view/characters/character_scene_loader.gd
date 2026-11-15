class_name CharacterSceneLoader
extends RefCounted
## Leitura das cenas (.glb) das peças e das animações dos personagens (ART-12, entrega 4a; só apresentação): carrega pelo ResourceLoader (síncrono; o pré-carregamento é da entrega 4c), acha o esqueleto e as malhas e confere se uma peça serve a um esqueleto. Caminho ausente ou que não é cena vira null, sem exceção e sem log. Contrato: docs/modules/presentation.md.


## Uma instância nova da cena (o chamador a libera com free); null se o caminho não existe ou não é uma cena.
static func instantiate(path: String) -> Node:
	if not ResourceLoader.exists(path):
		return null
	var scene: PackedScene = ResourceLoader.load(path, "PackedScene") as PackedScene
	return scene.instantiate() if scene != null else null


static func skeleton_of(root: Node) -> Skeleton3D:
	var found: Array[Node] = root.find_children("*", "Skeleton3D", true, false)
	return found[0] as Skeleton3D if not found.is_empty() else null


static func meshes_of(root: Node) -> Array[MeshInstance3D]:
	var meshes: Array[MeshInstance3D] = []
	for node: Node in root.find_children("*", "MeshInstance3D", true, false):
		meshes.append(node as MeshInstance3D)
	return meshes


## A peça serve ao esqueleto: tem malha, toda malha tem pele e todo osso citado pela pele existe nele (a pele liga por NOME de osso, então basta isso para peças com o mesmo esqueleto).
static func fits(root: Node, skeleton: Skeleton3D) -> bool:
	var meshes: Array[MeshInstance3D] = meshes_of(root)
	for mesh: MeshInstance3D in meshes:
		if mesh.skin == null:
			return false
		for bind: int in mesh.skin.get_bind_count():
			if skeleton.find_bone(mesh.skin.get_bind_name(bind)) < 0:
				return false
	return not meshes.is_empty()
