class_name CharacterRetarget
extends RefCounted
## Retarget das animações da UAL (Quaternius) para o esqueleto montado de um personagem, em modo GLOBAL (ART-12, entrega 4a; só apresentação). Reescrita, no padrão do projeto, do MODE_GLOBAL da ART-12a (protótipo fora de src/). Contrato: docs/modules/presentation.md.
## POR QUÊ (medido na entrega 4a, no idle, pela altura do osso do pé sobre a do repouso): a UAL e os personagens têm os mesmos 65 ossos, mas repousos diferentes (pélvis em repouso a 0,9491 m no homem e 0,9318 m na mulher, contra 0,9167 m na UAL; a perna do personagem é cerca de 5 cm mais longa). A CAUSA dos pés AFUNDADOS 3 a 4 cm da ART-11 era a translação: ela copiava a posição ABSOLUTA da pélvis da UAL e o corpo inteiro descia essa diferença (-3,7 cm no homem e -2,1 cm na mulher). Com a translação convertida (regra 2) os pés ficam a menos de 1 cm do repouso (-0,6 e -0,8 cm); a razão da perna é só um refinamento (mexe cerca de 0,3 cm no pé). O delta GLOBAL de rotação (regra 1), com o repouso do PRÓPRIO esqueleto de destino, preserva o DELTA de cada osso da UAL em relação ao repouso dela (a rotação MUNDIAL que a pose acrescenta ao repouso), apesar dos repousos locais diferentes; NÃO preserva a orientação mundial absoluta: no idle e no walk o `foot_l` retargetado difere do da UAL em cerca de 4,1° no homem e 8,7° na mulher, a mesma diferença dos repousos mundiais, e o `ball_l` bate. Isso evita o erro da ART-11 de usar o esqueleto masculino para todos (pé da mulher inclinado -4,7°); sozinho, quase não muda a altura do pé (idle do homem: -0,58 cm contra -0,72 cm com o delta local).
## O QUE FAZ: (1) a rotação mundial de cada osso é (rotação mundial da UAL no instante t) x (inverso do repouso mundial da UAL) x (repouso mundial do destino), com o repouso do PRÓPRIO esqueleto de destino (o do gênero do corpo); a rotação local sai de pai^-1 x osso, amostrada a 30 quadros por segundo; (2) a translação de raiz e pélvis é a posição de repouso do destino mais o deslocamento da UAL em relação ao repouso dela, este multiplicado pela razão entre o comprimento da perna do destino e o da UAL (pélvis até o pé, em repouso); (3) as trilhas apontam para o Skeleton3D montado ("Skeleton3D:osso").
## OSSO SEM PAR: um osso do destino que a UAL não tem (pelo nome) fica no repouso MUNDIAL do destino, isto é, não acompanha o pai (a rotação local dele compensa a do pai). Nenhum ativo atual exerce isso: a UAL e os personagens têm os mesmos 65 ossos (medido nos ativos), então o caso vale só para um esqueleto futuro.

const SAMPLES_PER_SECOND: float = 30.0
const SKELETON_NODE: String = "Skeleton3D"
const PELVIS_BONE: String = "pelvis"
const FOOT_BONE: String = "foot_l"
## Os ossos cuja TRANSLAÇÃO a UAL anima (os outros só giram).
const MOVING_BONES: PackedStringArray = ["root", "pelvis"]

## Comprimento da perna do destino sobre o da UAL (1 se um dos esqueletos não tem pélvis ou pé).
var leg_ratio: float = 1.0
var _source: Skeleton3D
var _target: Skeleton3D
var _source_order: PackedInt32Array
var _target_order: PackedInt32Array
var _source_of: PackedInt32Array = PackedInt32Array()
var _source_rest_local: Array[Quaternion] = []
var _source_rest_inverse: Array[Quaternion] = []
var _target_rest_world: Array[Quaternion] = []


## `source` é o esqueleto do arquivo de animações (a UAL) e `target`, o do personagem montado; só os repousos deles são lidos.
func _init(source: Skeleton3D, target: Skeleton3D) -> void:
	_source = source
	_target = target
	_source_order = _parents_first(source)
	_target_order = _parents_first(target)
	var source_world: Array[Transform3D] = _rest_world(source, _source_order)
	var target_world: Array[Transform3D] = _rest_world(target, _target_order)
	for bone: int in source.get_bone_count():
		_source_rest_local.append(source.get_bone_rest(bone).basis.get_rotation_quaternion())
		_source_rest_inverse.append(source_world[bone].basis.get_rotation_quaternion().inverse())
	for bone: int in target.get_bone_count():
		_source_of.append(source.find_bone(target.get_bone_name(bone)))
		_target_rest_world.append(target_world[bone].basis.get_rotation_quaternion())
	var source_leg: float = _leg_length(source, source_world)
	var target_leg: float = _leg_length(target, target_world)
	if source_leg > 0.0 and target_leg > 0.0:
		leg_ratio = target_leg / source_leg


## A biblioteca (uma animação por chave) retargetada para `target`. `clips` = {chave: {"path": cena, "name": animação}}, como em `CharacterCatalog.animations()`; a chave é o nome da animação na biblioteca (sem o `_Loop` da UAL). Devolve null, sem exceção, se um arquivo ou uma animação faltar.
static func library_for(target: Skeleton3D, clips: Dictionary) -> AnimationLibrary:
	var keys_by_path: Dictionary[String, Array] = {}
	for key: String in clips:
		var path: String = clips[key]["path"]
		if not keys_by_path.has(path):
			keys_by_path[path] = []
		keys_by_path[path].append(key)
	var library: AnimationLibrary = AnimationLibrary.new()
	for path: String in keys_by_path:
		if not _add_clips(library, target, path, keys_by_path[path], clips):
			return null
	return library


## Uma animação nova, com o mesmo comprimento e modo de repetição de `clip`.
func retarget(clip: Animation) -> Animation:
	var out: Animation = Animation.new()
	out.length = clip.length
	out.loop_mode = clip.loop_mode
	var rotations: Dictionary[int, int] = {}
	for track: int in clip.get_track_count():
		var bone: int = _source.find_bone(clip.track_get_path(track).get_concatenated_subnames())
		if bone < 0:
			continue
		match clip.track_get_type(track):
			Animation.TYPE_ROTATION_3D:
				rotations[bone] = track
			Animation.TYPE_POSITION_3D:
				_move(clip, track, bone, out)
	_rotate(clip, rotations, out)
	return out


static func _add_clips(library: AnimationLibrary, target: Skeleton3D, path: String, keys: Array, clips: Dictionary) -> bool:
	var scene: Node = CharacterSceneLoader.instantiate(path)
	if scene == null:
		return false
	var skeleton: Skeleton3D = CharacterSceneLoader.skeleton_of(scene)
	var players: Array[Node] = scene.find_children("*", "AnimationPlayer", true, false)
	var complete: bool = skeleton != null and not players.is_empty()
	if complete:
		var converter: CharacterRetarget = CharacterRetarget.new(skeleton, target)
		var player: AnimationPlayer = players[0] as AnimationPlayer
		for key: String in keys:
			var clip_name: StringName = StringName(String(clips[key]["name"]))
			complete = complete and player.has_animation(clip_name)
			if complete:
				library.add_animation(StringName(key), converter.retarget(player.get_animation(clip_name)))
	scene.free()
	return complete


## Os ossos com pai antes dos filhos (varredura em largura a partir das raízes).
static func _parents_first(skeleton: Skeleton3D) -> PackedInt32Array:
	var order: PackedInt32Array = skeleton.get_parentless_bones()
	var next: int = 0
	while next < order.size():
		order.append_array(skeleton.get_bone_children(order[next]))
		next += 1
	return order


static func _rest_world(skeleton: Skeleton3D, order: PackedInt32Array) -> Array[Transform3D]:
	var world: Array[Transform3D] = []
	world.resize(skeleton.get_bone_count())
	for bone: int in order:
		var parent: int = skeleton.get_bone_parent(bone)
		world[bone] = skeleton.get_bone_rest(bone) if parent < 0 else world[parent] * skeleton.get_bone_rest(bone)
	return world


static func _leg_length(skeleton: Skeleton3D, world: Array[Transform3D]) -> float:
	var pelvis: int = skeleton.find_bone(PELVIS_BONE)
	var foot: int = skeleton.find_bone(FOOT_BONE)
	return 0.0 if pelvis < 0 or foot < 0 else world[pelvis].origin.y - world[foot].origin.y


## Copia a trilha de translação de raiz ou pélvis com o deslocamento escalado pela razão da perna.
func _move(clip: Animation, track: int, bone: int, out: Animation) -> void:
	var bone_name: String = _source.get_bone_name(bone)
	var target_bone: int = _target.find_bone(bone_name)
	if not MOVING_BONES.has(bone_name) or target_bone < 0:
		return
	var moved: int = out.add_track(Animation.TYPE_POSITION_3D)
	out.track_set_path(moved, NodePath("%s:%s" % [SKELETON_NODE, bone_name]))
	var source_rest: Vector3 = _source.get_bone_rest(bone).origin
	var target_rest: Vector3 = _target.get_bone_rest(target_bone).origin
	for key: int in clip.track_get_key_count(track):
		var offset: Vector3 = (clip.track_get_key_value(track, key) as Vector3) - source_rest
		out.position_track_insert_key(moved, clip.track_get_key_time(track, key), target_rest + offset * leg_ratio)


## Uma trilha de rotação por osso do destino, amostrada a 30 quadros por segundo (o último quadro cai em `length`).
func _rotate(clip: Animation, rotations: Dictionary[int, int], out: Animation) -> void:
	var count: int = _target.get_bone_count()
	var tracks: PackedInt32Array = PackedInt32Array()
	for bone: int in count:
		tracks.append(out.add_track(Animation.TYPE_ROTATION_3D))
		out.track_set_path(tracks[bone], NodePath("%s:%s" % [SKELETON_NODE, _target.get_bone_name(bone)]))
	var previous: Array[Quaternion] = []
	previous.resize(count)
	var world: Array[Quaternion] = []
	world.resize(count)
	for step: int in int(ceil(clip.length * SAMPLES_PER_SECOND)) + 1:
		var time: float = minf(step / SAMPLES_PER_SECOND, clip.length)
		var source_world: Array[Quaternion] = _source_world(clip, rotations, time)
		for bone: int in _target_order:
			var source_bone: int = _source_of[bone]
			world[bone] = _target_rest_world[bone]
			if source_bone >= 0:
				world[bone] = source_world[source_bone] * _source_rest_inverse[source_bone] * _target_rest_world[bone]
			var parent: int = _target.get_bone_parent(bone)
			var local_rotation: Quaternion = world[bone] if parent < 0 else world[parent].inverse() * world[bone]
			if step > 0 and previous[bone].dot(local_rotation) < 0.0:
				local_rotation = -local_rotation
			previous[bone] = local_rotation
			out.rotation_track_insert_key(tracks[bone], time, local_rotation)


## Rotação mundial de cada osso da UAL no instante `time`: a da trilha, ou a do repouso se o osso não tem trilha.
func _source_world(clip: Animation, rotations: Dictionary[int, int], time: float) -> Array[Quaternion]:
	var world: Array[Quaternion] = []
	world.resize(_source.get_bone_count())
	for bone: int in _source_order:
		var local_rotation: Quaternion = clip.rotation_track_interpolate(rotations[bone], time) if rotations.has(bone) else _source_rest_local[bone]
		var parent: int = _source.get_bone_parent(bone)
		world[bone] = local_rotation if parent < 0 else world[parent] * local_rotation
	return world
