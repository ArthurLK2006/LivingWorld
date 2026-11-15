class_name CharacterAssembler
extends Node3D
## Monta UM personagem animado a partir de uma ficha de aparência e do catálogo (ART-12, entrega 4a1: as peças, sem animação; só apresentação): um Skeleton3D compartilhado e uma MeshInstance3D por malha de cada peça (cabeça do corpo com olhos, roupa, cabelo, barba opcional, sobrancelha), todas ligadas ao MESMO esqueleto, cada uma com a própria pele (que liga por NOME de osso). Monta QUALQUER conjunto de peças que compartilhe o esqueleto do catálogo: o visual vem só dos caminhos do catálogo e da ficha. Origem NOS PÉS; `scale_permille` vira escala uniforme. Falha (peça ausente, ficha vazia) devolve falso, sem exceção e sem log, e não deixa nada pela metade. A animação (retarget e AnimationPlayer) vem na entrega 4a2; sem shader, paleta, normais planas nem LOD (entregas 4b e seguintes). Contrato: docs/modules/presentation.md.
## O esqueleto vem da PRIMEIRA peça do plano (o tronco da roupa), não da cabeça: a cabeça-base masculina da Quaternius tem braços e pernas ligeiramente diferentes (até 3,4 cm e 13° nos polegares, medido nos ativos), mas os ossos da cabeça e do pescoço são iguais, então ela se encaixa no esqueleto das roupas.

const SLOT_TORSO: String = "torso_arms"
const SLOT_LEGS: String = "legs"
const SLOT_BOOTS: String = "boots"
const SLOT_HEAD: String = "head"
const SLOT_HAIR: String = "hair"
const SLOT_BEARD: String = "beard"
const SLOT_EYEBROW: String = "eyebrow"
## Cada peça extra da roupa ocupa um encaixe "extra_<posição na lista do catálogo>".
const SLOT_EXTRA_PREFIX: String = "extra_"
const PERMILLE: float = 1000.0

var _skeleton: Skeleton3D = null
var _slots: Dictionary[String, Array] = {}


## Monta o personagem sob este nó. O conteúdo anterior só é trocado se TUDO der certo.
func build(appearance: CharacterAppearance, catalog: CharacterCatalog) -> bool:
	var plan: Dictionary[String, String] = _plan(appearance, catalog)
	var scenes: Dictionary[String, Node] = _instantiate_all(plan)
	if scenes.is_empty():
		return false
	var donor: Skeleton3D = CharacterSceneLoader.skeleton_of(scenes[plan.keys()[0]])
	if donor == null or donor.get_bone_count() != catalog.skeleton_bones or not _all_fit(scenes, donor):
		_free_all(scenes)
		return false
	clear()
	_skeleton = donor
	for slot: String in scenes:
		_mount(slot, CharacterSceneLoader.meshes_of(scenes[slot]))
	donor.get_parent().remove_child(donor)
	donor.owner = null
	add_child(donor)
	_free_all(scenes)
	var permille: int = appearance.scale_permille if appearance.scale_permille > 0 else CharacterAppearance.NEUTRAL_SCALE_PERMILLE
	scale = Vector3.ONE * (float(permille) / PERMILLE)
	return true


## Troca a peça de um encaixe sem recriar o esqueleto; caminho vazio tira a peça. Peça que não existe ou não serve ao esqueleto devolve falso e deixa a atual no lugar.
func swap_part(slot: String, scene_path: String) -> bool:
	if _skeleton == null:
		return false
	if scene_path.is_empty():
		_free_slot(slot)
		return true
	var scene: Node = CharacterSceneLoader.instantiate(scene_path)
	if scene == null:
		return false
	var fits: bool = CharacterSceneLoader.fits(scene, _skeleton)
	if fits:
		_free_slot(slot)
		_mount(slot, CharacterSceneLoader.meshes_of(scene))
	scene.free()
	return fits


## Desmonta o personagem (esqueleto e malhas), sem deixar nó órfão.
func clear() -> void:
	if _skeleton != null:
		remove_child(_skeleton)
		_skeleton.free()
	_slots.clear()
	_skeleton = null


## Encaixe -> caminho da cena, com o tronco da roupa primeiro (dele vem o esqueleto). Vazio se a ficha ou uma peça não existe no catálogo; cabelo, barba e sobrancelha vazios na ficha significam "sem a peça"; cada um sai da lista do catálogo para o gênero do corpo.
static func _plan(appearance: CharacterAppearance, catalog: CharacterCatalog) -> Dictionary[String, String]:
	var plan: Dictionary[String, String] = {}
	if appearance == null or catalog == null or not appearance.is_resolved() or not catalog.is_ready():
		return plan
	var body: Dictionary = _row(catalog.bodies(), appearance.body_id)
	var gender: String = String(body.get("gender", ""))
	var outfit: Dictionary = _row(catalog.outfits_for(gender), appearance.outfit_id)
	if body.is_empty() or outfit.is_empty():
		return plan
	var parts: Dictionary = outfit["parts"]
	plan = {SLOT_TORSO: parts["torso_arms"], SLOT_LEGS: parts["legs"], SLOT_BOOTS: parts["boots"]}
	var extras: Array = parts["extras"]
	for index: int in extras.size():
		plan[SLOT_EXTRA_PREFIX + str(index)] = extras[index]
	plan[SLOT_HEAD] = body["head_scene"]
	var is_complete: bool = _add_optional(plan, SLOT_HAIR, catalog.hair_for(gender), appearance.hair_id)
	is_complete = is_complete and _add_optional(plan, SLOT_BEARD, catalog.beards_for(gender), appearance.beard_id)
	is_complete = is_complete and _add_optional(plan, SLOT_EYEBROW, catalog.eyebrows_for(gender), appearance.eyebrow_id)
	if not is_complete:
		plan.clear()
	return plan


static func _row(rows: Array[Dictionary], id: String) -> Dictionary:
	for row: Dictionary in rows:
		if row["id"] == id:
			return row
	return {}


## Id vazio = sem a peça (verdadeiro); id que não está na tabela = falha (falso).
static func _add_optional(plan: Dictionary[String, String], slot: String, rows: Array[Dictionary], id: String) -> bool:
	if id.is_empty():
		return true
	var row: Dictionary = _row(rows, id)
	if not row.is_empty():
		plan[slot] = row["scene"]
	return not row.is_empty()


## Instancia todas as peças do plano; se alguma faltar, libera as já criadas e devolve vazio.
static func _instantiate_all(plan: Dictionary[String, String]) -> Dictionary[String, Node]:
	var scenes: Dictionary[String, Node] = {}
	for slot: String in plan:
		var scene: Node = CharacterSceneLoader.instantiate(plan[slot])
		if scene == null:
			_free_all(scenes)
			return {}
		scenes[slot] = scene
	return scenes


static func _all_fit(scenes: Dictionary[String, Node], skeleton: Skeleton3D) -> bool:
	for scene: Node in scenes.values():
		if not CharacterSceneLoader.fits(scene, skeleton):
			return false
	return true


static func _free_all(scenes: Dictionary[String, Node]) -> void:
	for scene: Node in scenes.values():
		scene.free()
	scenes.clear()


## Liga as malhas ao esqueleto compartilhado (pele própria de cada uma, transformação zerada).
func _mount(slot: String, meshes: Array[MeshInstance3D]) -> void:
	for mesh: MeshInstance3D in meshes:
		mesh.get_parent().remove_child(mesh)
		mesh.owner = null
		mesh.transform = Transform3D.IDENTITY
		_skeleton.add_child(mesh)
		mesh.skeleton = NodePath("..")
	_slots[slot] = meshes


func _free_slot(slot: String) -> void:
	if not _slots.has(slot):
		return
	for mesh: MeshInstance3D in _slots[slot]:
		_skeleton.remove_child(mesh)
		mesh.free()
	_slots.erase(slot)
