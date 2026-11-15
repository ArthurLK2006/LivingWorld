class_name CharacterAssembler
extends Node3D
## Monta UM personagem animado a partir de uma ficha de aparência e do catálogo (ART-12, entrega 4a; só apresentação): um Skeleton3D compartilhado e uma MeshInstance3D por malha de cada peça (cabeça do corpo com olhos, roupa, cabelo, barba opcional, sobrancelha), todas ligadas ao MESMO esqueleto, cada uma com a própria pele (que liga por NOME de osso). Monta QUALQUER conjunto de peças que compartilhe o esqueleto do catálogo: o visual vem só dos caminhos do catálogo e da ficha. Origem NOS PÉS; `scale_permille` vira escala uniforme. Falha (peça ou animação ausente, ficha vazia) devolve falso, sem exceção e sem log, e não deixa nada pela metade. A paleta (4b) não é daqui: o `CharacterPainter` pinta as malhas montadas e deixa uma chamada em `set_paint`, que o montador repete a cada peça montada ou trocada depois. Sem normais planas nem LOD (entregas seguintes). Contrato: docs/modules/presentation.md.
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
var _player: AnimationPlayer = null
var _slots: Dictionary[String, Array] = {}
## A pintura da ficha (recebe as malhas recém-montadas); vazia = o visual original das peças. Dura até o próximo `clear()` ou montagem.
var _paint: Callable = Callable()


## Monta o personagem sob este nó. O conteúdo anterior só é trocado se TUDO der certo.
func build(appearance: CharacterAppearance, catalog: CharacterCatalog) -> bool:
	var plan: Dictionary[String, String] = _plan(appearance, catalog)
	var scenes: Dictionary[String, Node] = _instantiate_all(plan)
	if scenes.is_empty():
		return false
	var donor: Skeleton3D = CharacterSceneLoader.skeleton_of(scenes[plan.keys()[0]])
	var library: AnimationLibrary = CharacterRetarget.library_for(donor, catalog.animations()) if donor != null else null
	if library == null or donor.get_bone_count() != catalog.skeleton_bones or not _all_fit(scenes, donor):
		_free_all(scenes)
		return false
	clear()
	_skeleton = donor
	for slot: String in scenes:
		_mount(slot, CharacterSceneLoader.meshes_of(scenes[slot]))
	donor.get_parent().remove_child(donor)
	donor.owner = null
	donor.name = CharacterRetarget.SKELETON_NODE
	add_child(donor)
	_free_all(scenes)
	_player = AnimationPlayer.new()
	add_child(_player)
	_player.add_animation_library("", library)
	var permille: int = appearance.scale_permille if appearance.scale_permille > 0 else CharacterAppearance.NEUTRAL_SCALE_PERMILLE
	scale = Vector3.ONE * (float(permille) / PERMILLE)
	return true


## Troca a peça de um encaixe sem recriar o esqueleto nem mexer na animação; caminho vazio tira a peça. Peça que não existe ou não serve ao esqueleto devolve falso e deixa a atual no lugar.
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


## Toca o clipe de chave `clip` do catálogo ("idle", "walk", ...) em laço; pedir de novo o clipe que já toca não o reinicia (comportamento do AnimationPlayer, coberto pelo teste). Falso se não há personagem montado ou a chave não existe.
func play(clip: String) -> bool:
	if _player == null or not _player.has_animation(clip):
		return false
	_player.play(clip)
	return true


func is_playing() -> bool:
	return _player != null and _player.is_playing()


## A chave do último clipe iniciado ("" se nenhum).
func current_clip() -> String:
	return String(_player.assigned_animation) if _player != null else ""


## Desmonta o personagem (esqueleto, malhas e animações), sem deixar nó órfão.
func clear() -> void:
	for node: Node in [_player, _skeleton]:
		if node != null:
			remove_child(node)
			node.free()
	_slots.clear()
	_player = null
	_skeleton = null
	_paint = Callable()


## Guarda a pintura (uma chamada que recebe `Array[MeshInstance3D]`) para as peças montadas ou trocadas daqui em diante; chamada vazia a tira. Não pinta o que já está montado (isso é do `CharacterPainter.apply`).
func set_paint(paint: Callable) -> void:
	_paint = paint


## Encaixe -> caminho da cena, com o tronco da roupa primeiro (dele vem o esqueleto). Vazio se a ficha ou uma peça não existe no catálogo; cabelo, barba e sobrancelha vazios na ficha significam "sem a peça"; cada um sai da lista do catálogo para o gênero do corpo (a sobrancelha cai em todas se o catálogo não tem nenhuma para o gênero, como a ficha).
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
	is_complete = is_complete and _add_optional(plan, SLOT_EYEBROW, _eyebrows_of(catalog, gender), appearance.eyebrow_id)
	if not is_complete:
		plan.clear()
	return plan


## As sobrancelhas do gênero do corpo; se o catálogo não tem nenhuma para ele, todas (a mesma regra da ficha, `CharacterAppearance`).
static func _eyebrows_of(catalog: CharacterCatalog, gender: String) -> Array[Dictionary]:
	var rows: Array[Dictionary] = catalog.eyebrows_for(gender)
	return rows if not rows.is_empty() else catalog.eyebrows()


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
	if _paint.is_valid():
		_paint.call(meshes)


func _free_slot(slot: String) -> void:
	if not _slots.has(slot):
		return
	for mesh: MeshInstance3D in _slots[slot]:
		_skeleton.remove_child(mesh)
		mesh.free()
	_slots.erase(slot)
