extends RefCounted
## Esqueleto do Ice Warrior (ferramenta de arte, fora do jogo): os MESMOS 65 ossos e a MESMA hierarquia do corpo male_a (clonado do `CharacterAssembler` só para copiar nomes e hierarquia), com as articulações MEDIDAS na malha (`ice_landmarks.json`, em cm, sem geometria).
## DOIS arranjos do MESMO esqueleto (mesmas translações locais; só as rotações locais mudam):
## - REPOUSO (o `Skeleton3D`, o que o `CharacterRetarget` lê): as rotações do male_a, isto é, o T (braços na horizontal). É obrigatório: o retarget aplica o delta MUNDIAL da UAL sobre o repouso do destino, e a UAL parte do T.
## - BIND (a pose da malha: braços caídos, pernas um pouco abertas): cada osso medido é girado pelo menor arco que alinha o seu eixo principal ao segmento medido na malha. Dele saem as matrizes inversas da `Skin` (que NÃO precisam igualar o repouso) e a pose de referência da 6a.
## Articulações no lado esquerdo do personagem (+X); o direito é o espelho em X. Os ossos sem articulação medida (dedos, IK) só acompanham, na escala `hand_scale` do estudo (a mão do Ice Warrior é uns 55% da do male_a).
const LANDMARKS_PATH: String = "res://tools/visual/ice_figure/ice_landmarks.json"
const BODY_ID: String = "male_a"
const OUTFIT_ID: String = "peasant_m"
const HAIR_ID: String = "simple_parted"
const EYEBROW_ID: String = "brow_regular"
const CM: float = 0.01
const TIP: String = "tip"
const MIDDLE_FINGER: String = "middle_01"
const LEFT: String = "_l"
const RIGHT: String = "_r"


## O esqueleto pronto (repouso em T), a matriz global de cada osso na pose de bind, as pontas virtuais (cabeça e mãos, fim de segmento dos pesos) e a tabela osso -> filho do eixo principal.
class Rig:
	extends RefCounted
	var skeleton: Skeleton3D
	var bind: Array[Transform3D] = []
	var tips: Dictionary[String, Vector3] = {}
	var axis_child: Dictionary = {}

	func origin(bone_name: String) -> Vector3:
		return bind[skeleton.find_bone(bone_name)].origin

	## A transformação local do osso no arranjo de bind (a pose que mostra a malha como o original).
	func bind_local(bone: int) -> Transform3D:
		var parent: int = skeleton.get_bone_parent(bone)
		return bind[bone] if parent < 0 else bind[parent].affine_inverse() * bind[bone]


## Lê a tabela de articulações; vazio se faltar ou estiver malformada. O JSON é a fronteira de dados: o resultado do parser é Variant.
static func load_landmarks(path: String = LANDMARKS_PATH) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}


static func build(catalog: CharacterCatalog, landmarks: Dictionary) -> Rig:
	var skeleton: Skeleton3D = _male_skeleton(catalog)
	var points: Dictionary[String, Vector3] = _points(landmarks)
	var hand_scale: float = landmarks["hand_scale"]
	var count: int = skeleton.get_bone_count()
	var male: Array[Transform3D] = []
	male.resize(count)
	var rig: Rig = Rig.new()
	rig.skeleton = skeleton
	rig.axis_child = landmarks["axis_child"]
	rig.bind.resize(count)
	for bone: int in count:
		var parent: int = skeleton.get_bone_parent(bone)
		male[bone] = skeleton.get_bone_rest(bone) if parent < 0 else male[parent] * skeleton.get_bone_rest(bone)
	for bone: int in count:
		var parent: int = skeleton.get_bone_parent(bone)
		var bone_name: String = skeleton.get_bone_name(bone)
		var rest: Transform3D = skeleton.get_bone_rest(bone)
		var parent_bind: Transform3D = Transform3D.IDENTITY if parent < 0 else rig.bind[parent]
		var offset: Vector3 = rest.origin * hand_scale
		var origin: Vector3 = parent_bind.origin + parent_bind.basis * offset
		var rotation: Basis = parent_bind.basis * rest.basis
		if points.has(bone_name):
			origin = points[bone_name]
			offset = parent_bind.basis.inverse() * (origin - parent_bind.origin)
			rotation = _aligned(skeleton, male, points, rig.axis_child, bone, rotation)
		rig.bind[bone] = Transform3D(rotation, origin)
		skeleton.set_bone_rest(bone, Transform3D(rest.basis, offset))
	skeleton.reset_bone_poses()
	rig.tips["Head"] = rig.origin("Head") + Vector3(0.0, float(landmarks["head_tip_cm"]) * CM, 0.0)
	rig.tips["hand" + LEFT] = points[TIP + LEFT]
	rig.tips["hand" + RIGHT] = points[TIP + RIGHT]
	return rig


## "_l", "_r" ou "" (osso central) pelo sufixo do nome.
static func side_suffix(bone_name: String) -> String:
	return LEFT if bone_name.ends_with(LEFT) else (RIGHT if bone_name.ends_with(RIGHT) else "")


static func vec(raw: Array) -> Vector3:
	return Vector3(raw[0], raw[1], raw[2])


## Clona o esqueleto do corpo male_a montado pelo `CharacterAssembler` (sem as malhas) e solta o montador.
static func _male_skeleton(catalog: CharacterCatalog) -> Skeleton3D:
	var look: CharacterAppearance = CharacterAppearance.new()
	look.body_id = BODY_ID
	look.outfit_id = OUTFIT_ID
	look.hair_id = HAIR_ID
	look.eyebrow_id = EYEBROW_ID
	var assembler: CharacterAssembler = CharacterAssembler.new()
	assembler.build(look, catalog)
	var skeleton: Skeleton3D = CharacterSceneLoader.skeleton_of(assembler)
	assembler.remove_child(skeleton)
	for child: Node in skeleton.get_children():
		skeleton.remove_child(child)
		child.free()
	assembler.free()
	return skeleton


static func _points(landmarks: Dictionary) -> Dictionary[String, Vector3]:
	var points: Dictionary[String, Vector3] = {}
	var center: Dictionary = landmarks["center"]
	for key: String in center:
		points[key] = vec(center[key]) * CM
	var side: Dictionary = landmarks["side"]
	for key: String in side:
		var left: Vector3 = vec(side[key]) * CM
		points[key + LEFT] = left
		points[key + RIGHT] = Vector3(-left.x, left.y, left.z)
	return points


## Rotação de bind do osso: a do pai com o repouso do male_a, girada pelo menor arco até o eixo principal apontar para o filho medido.
static func _aligned(skeleton: Skeleton3D, male: Array[Transform3D], points: Dictionary[String, Vector3], axis_child: Dictionary, bone: int, unadjusted: Basis) -> Basis:
	var bone_name: String = skeleton.get_bone_name(bone)
	var side: String = side_suffix(bone_name)
	var base: String = bone_name.trim_suffix(side)
	if not axis_child.has(base):
		return unadjusted
	var child: String = axis_child[base]
	var male_child: int = skeleton.find_bone((MIDDLE_FINGER if child == TIP else child) + side)
	var axis: Vector3 = (male[bone].basis.inverse() * (male[male_child].origin - male[bone].origin)).normalized()
	var current: Vector3 = (unadjusted * axis).normalized()
	var wanted: Vector3 = (points[child + side] - points[bone_name]).normalized()
	return Basis(Quaternion(current, wanted)) * unadjusted
