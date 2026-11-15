class_name CharacterRetarget
extends RefCounted
## Retarget das animações da UAL (Quaternius) para o esqueleto montado de um personagem, em modo GLOBAL (ART-12, entrega 4a; só apresentação). Reescrita, no padrão do projeto, do MODE_GLOBAL da ART-12a (protótipo fora de src/). Contrato: docs/modules/presentation.md.
## POR QUÊ (medido na entrega 4a, no idle, pela altura do osso do pé sobre a do repouso): a UAL e os personagens têm os mesmos 65 ossos, mas repousos diferentes (pélvis em repouso a 0,9491 m no homem e 0,9318 m na mulher, contra 0,9167 m na UAL; a perna do personagem é cerca de 5 cm mais longa). A CAUSA dos pés AFUNDADOS 3 a 4 cm da ART-11 era a translação: ela copiava a posição ABSOLUTA da pélvis da UAL e o corpo inteiro descia essa diferença (-3,7 cm no homem e -2,1 cm na mulher). Com a translação convertida (regra 2) os pés ficam a menos de 1 cm do repouso (-0,6 e -0,8 cm); a razão da perna é só um refinamento (mexe cerca de 0,3 cm no pé). O delta GLOBAL de rotação (regra 1), com o repouso do PRÓPRIO esqueleto de destino, preserva o DELTA de cada osso da UAL em relação ao repouso dela (a rotação MUNDIAL que a pose acrescenta ao repouso), apesar dos repousos locais diferentes; NÃO preserva a orientação mundial absoluta: no idle e no walk o `foot_l` retargetado difere do da UAL em cerca de 4,1° no homem e 8,7° na mulher, a mesma diferença dos repousos mundiais, e o `ball_l` bate. Isso evita o erro da ART-11 de usar o esqueleto masculino para todos (pé da mulher inclinado -4,7°); sozinho, quase não muda a altura do pé (idle do homem: -0,58 cm contra -0,72 cm com o delta local).
## O QUE FAZ: (1) a rotação mundial de cada osso é (rotação mundial da UAL no instante t) x (inverso do repouso mundial da UAL) x (repouso mundial do destino), com o repouso do PRÓPRIO esqueleto de destino (o do gênero do corpo); a rotação local sai de pai^-1 x osso, amostrada a 30 quadros por segundo; (2) a translação de raiz e pélvis é a posição de repouso do destino mais o deslocamento da UAL em relação ao repouso dela, este multiplicado pela razão entre o comprimento da perna do destino e o da UAL (pélvis até o pé, em repouso); (3) as trilhas apontam para o Skeleton3D montado ("Skeleton3D:osso").
## OSSO SEM PAR: um osso do destino que a UAL não tem (pelo nome) fica no repouso MUNDIAL do destino, isto é, não acompanha o pai (a rotação local dele compensa a do pai). Nenhum ativo atual exerce isso: a UAL e os personagens têm os mesmos 65 ossos (medido nos ativos), então o caso vale só para um esqueleto futuro.
## OPÇÕES (entrega 6a; DESLIGADAS por padrão: sem `Options`, ou com uma `Options` nova, as trilhas saem IDÊNTICAS às de antes, e `new(fonte, destino)` e `library_for(destino, clipes)` funcionam como sempre). Vêm da prova de movimento do Ice Warrior (malha inteira, esqueleto próprio), que precisou corrigir fora de src/ o que o retarget acima supõe. Valem para TODO clipe retargetado pela instância (na `library_for`, para todos os clipes dela; o jog, com fase aérea, não deve passar pela trava de chão).
## (1) POSE DE REFERÊNCIA (`Options.bind_pose` não vazio; o "re-base"). POR QUÊ: o retarget acima SUPÕE a malha do destino na pose de repouso do esqueleto (o T da UAL). Uma figura inteira pode estar noutra pose (braços caídos, espada para a frente), com o esqueleto em T no repouso e a pose da malha só nos binds da `Skin`; aí o delta mundial da UAL sobre o repouso leva a malha à pose ABSOLUTA da UAL (medido na prova: a espada saía de lado e os pés ficavam 3 a 5 cm abaixo do chão). O QUE FAZ: o delta de cada osso passa a ser relativo ao QUADRO 0 de um clipe de referência (`reference_clip`, 4º argumento do construtor; na `library_for`, o clipe da chave `Options.reference_key`, por padrão `idle`) e é aplicado à rotação MUNDIAL de bind do destino (`bind_pose`: osso -> Transform3D mundial; osso fora do dicionário fica no repouso): o quadro 0 da referência É a pose da malha e o resto é o movimento da UAL em torno dela. A translação da pélvis é o repouso do destino mais o deslocamento em relação ao quadro 0 da referência, vezes a razão da perna. NÃO FAZ: só as ROTAÇÕES do bind entram (as posições vêm das translações de repouso do esqueleto, que devem ser coerentes com o bind, como no esqueleto do Ice Warrior); não conserta uma pose de bind que o esqueleto não alcança; sem clipe de referência o delta é o do repouso da UAL; a razão da perna segue vindo do repouso.
## (2) TRAVA DE CHÃO (`Options.ground_lock`). POR QUÊ: a perna do Ice Warrior é bem mais curta que a da UAL (razão 0,761, medida por este retarget) e o pé afundou até 5,2 cm no walk: o retarget só escala a translação da pélvis pela razão da perna, o que não basta quando coxa e canela também mudam de proporção. O QUE FAZ: por quadro (reamostrada a 30 por segundo, como a rotação), mede a altura de cada osso de `GROUND_BONES` (tornozelo, base e ponta dos dedos, dos dois pés) em relação à SUA altura na pose de referência (a de repouso; com a pose de referência, a de bind) e move a pélvis, só na vertical, pelo desvio do osso mais baixo: o pé mais baixo fica na altura de referência, sem afundar nem flutuar. NÃO FAZ: IK (se a perna não alcança o passo, o pé continua escorregando); não preserva fase aérea (num clipe de corrida o pé mais baixo ficaria sempre no chão); só a translação da PÉLVIS entra na conta (a UAL só anima a dela); sem trilha da pélvis no clipe, cria uma com o repouso mais a correção.
## (3) AMORTECIMENTO (`Options.damping`: osso -> fator de 0 a 1). POR QUÊ: uma peça rígida longa na mão (a espada de 80 cm do Ice Warrior) transforma o balanço do punho em grande deslocamento da ponta; a prova a amorteceu a 40% no braço dela. O QUE FAZ: mistura (slerp) o delta MUNDIAL de rotação do osso com a identidade: 1 = inteiro, 0 = o osso fica parado na orientação de referência (a de bind, ou a de repouso). Cada osso é independente (a rotação local do filho compensa a do pai). NÃO FAZ: não amortece translação; fator fora de 0 a 1 é limitado; osso que o destino não tem é ignorado.

const SAMPLES_PER_SECOND: float = 30.0
const SKELETON_NODE: String = "Skeleton3D"
const PELVIS_BONE: String = "pelvis"
const FOOT_BONE: String = "foot_l"
## Os ossos cuja TRANSLAÇÃO a UAL anima (os outros só giram).
const MOVING_BONES: PackedStringArray = ["root", "pelvis"]
## Os ossos que a trava de chão mede: tornozelo, base e ponta dos dedos, dos dois pés.
const GROUND_BONES: PackedStringArray = ["foot_l", "foot_r", "ball_l", "ball_r", "ball_leaf_l", "ball_leaf_r"]


## As opções da entrega 6a, todas DESLIGADAS por padrão (ver o cabeçalho). `bind_pose`: osso -> Transform3D MUNDIAL da pose da malha (vazio = sem pose de referência); `reference_key`: a chave, em `clips` da `library_for`, do clipe cujo quadro 0 é a referência; `ground_lock`: a trava de chão; `damping`: osso -> fator de 0 a 1 (vazio = sem amortecer).
class Options extends RefCounted:
	var bind_pose: Dictionary[String, Transform3D] = {}
	var reference_key: String = "idle"
	var ground_lock: bool = false
	var damping: Dictionary[String, float] = {}


## Comprimento da perna do destino sobre o da UAL (1 se um dos esqueletos não tem pélvis ou pé).
var leg_ratio: float = 1.0
var _options: Options
var _source: Skeleton3D
var _target: Skeleton3D
var _source_order: PackedInt32Array
var _target_order: PackedInt32Array
var _source_of: PackedInt32Array = PackedInt32Array()
var _source_rest_local: Array[Quaternion] = []
var _source_base_inverse: Array[Quaternion] = []
var _source_origin: Array[Vector3] = []
var _target_base: Array[Quaternion] = []
var _rest_origins: Array[Vector3] = []
var _damping: PackedFloat64Array = PackedFloat64Array()
var _ground_chains: Array[PackedInt32Array] = []
var _ground_heights: PackedFloat64Array = PackedFloat64Array()


## `source` é o esqueleto do arquivo de animações (a UAL) e `target`, o do personagem montado; só os repousos deles são lidos. `options` (padrão: tudo desligado) e `reference_clip` (o clipe da UAL cujo quadro 0 é a pose de referência; só vale com `options.bind_pose`) são da entrega 6a.
func _init(source: Skeleton3D, target: Skeleton3D, options: Options = null, reference_clip: Animation = null) -> void:
	_options = options if options != null else Options.new()
	_source = source
	_target = target
	_source_order = _parents_first(source)
	_target_order = _parents_first(target)
	var source_world: Array[Transform3D] = _rest_world(source, _source_order)
	var target_world: Array[Transform3D] = _rest_world(target, _target_order)
	for bone: int in source.get_bone_count():
		_source_rest_local.append(source.get_bone_rest(bone).basis.get_rotation_quaternion())
		_source_base_inverse.append(source_world[bone].basis.get_rotation_quaternion().inverse())
		_source_origin.append(source.get_bone_rest(bone).origin)
	for bone: int in target.get_bone_count():
		var bone_name: String = target.get_bone_name(bone)
		_source_of.append(source.find_bone(bone_name))
		_target_base.append(target_world[bone].basis.get_rotation_quaternion())
		_rest_origins.append(target.get_bone_rest(bone).origin)
		_damping.append(clampf(_options.damping[bone_name], 0.0, 1.0) if _options.damping.has(bone_name) else 1.0)
	var source_leg: float = _leg_length(source, source_world)
	var target_leg: float = _leg_length(target, target_world)
	if source_leg > 0.0 and target_leg > 0.0:
		leg_ratio = target_leg / source_leg
	_use_reference(reference_clip)
	_find_ground()


## A biblioteca (uma animação por chave) retargetada para `target`. `clips` = {chave: {"path": cena, "name": animação}}, como em `CharacterCatalog.animations()`; a chave é o nome da animação na biblioteca (sem o `_Loop` da UAL). `options` (padrão: tudo desligado) vale para todos os clipes; com `options.bind_pose`, o clipe de `options.reference_key` precisa estar em `clips`. Devolve null, sem exceção, se um arquivo, uma animação ou o clipe de referência faltar.
static func library_for(target: Skeleton3D, clips: Dictionary, options: Options = null) -> AnimationLibrary:
	var reference_clip: Animation = null
	if options != null and not options.bind_pose.is_empty():
		reference_clip = _find_reference_clip(clips, options.reference_key)
		if reference_clip == null:
			return null
	var keys_by_path: Dictionary[String, Array] = {}
	for key: String in clips:
		var path: String = clips[key]["path"]
		if not keys_by_path.has(path):
			keys_by_path[path] = []
		keys_by_path[path].append(key)
	var library: AnimationLibrary = AnimationLibrary.new()
	for path: String in keys_by_path:
		if not _add_clips(library, target, path, keys_by_path[path], clips, options, reference_clip):
			return null
	return library


## Uma animação nova, com o mesmo comprimento e modo de repetição de `clip`.
func retarget(clip: Animation) -> Animation:
	var out: Animation = Animation.new()
	out.length = clip.length
	out.loop_mode = clip.loop_mode
	var moves: Dictionary[int, int] = _tracks_of(clip, Animation.TYPE_POSITION_3D)
	for bone: int in moves:
		_move(clip, moves[bone], bone, out)
	var rotations: PackedInt32Array = _rotate(clip, _tracks_of(clip, Animation.TYPE_ROTATION_3D), out)
	if _options.ground_lock:
		_lock_ground(out, rotations)
	return out


static func _add_clips(library: AnimationLibrary, target: Skeleton3D, path: String, keys: Array, clips: Dictionary, options: Options, reference_clip: Animation) -> bool:
	var scene: Node = CharacterSceneLoader.instantiate(path)
	if scene == null:
		return false
	var skeleton: Skeleton3D = CharacterSceneLoader.skeleton_of(scene)
	var players: Array[Node] = scene.find_children("*", "AnimationPlayer", true, false)
	var complete: bool = skeleton != null and not players.is_empty()
	if complete:
		var converter: CharacterRetarget = CharacterRetarget.new(skeleton, target, options, reference_clip)
		var player: AnimationPlayer = players[0] as AnimationPlayer
		for key: String in keys:
			var clip_name: StringName = StringName(String(clips[key]["name"]))
			complete = complete and player.has_animation(clip_name)
			if complete:
				library.add_animation(StringName(key), converter.retarget(player.get_animation(clip_name)))
	scene.free()
	return complete


## O clipe da UAL da chave `key` (a referência da pose de referência); null se a chave, o arquivo ou a animação faltar.
static func _find_reference_clip(clips: Dictionary, key: String) -> Animation:
	var scene: Node = CharacterSceneLoader.instantiate(clips[key]["path"]) if clips.has(key) else null
	if scene == null:
		return null
	var players: Array[Node] = scene.find_children("*", "AnimationPlayer", true, false)
	var clip_name: StringName = StringName(String(clips[key]["name"]))
	var found: bool = not players.is_empty() and (players[0] as AnimationPlayer).has_animation(clip_name)
	var clip: Animation = (players[0] as AnimationPlayer).get_animation(clip_name) if found else null
	scene.free()
	return clip


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
	var source_rest: Vector3 = _source_origin[bone]
	var target_rest: Vector3 = _target.get_bone_rest(target_bone).origin
	for key: int in clip.track_get_key_count(track):
		var offset: Vector3 = (clip.track_get_key_value(track, key) as Vector3) - source_rest
		out.position_track_insert_key(moved, clip.track_get_key_time(track, key), target_rest + offset * leg_ratio)


## Uma trilha de rotação por osso do destino, amostrada a 30 quadros por segundo (o último quadro cai em `length`). Devolve o índice de cada uma em `out`, por osso do destino.
func _rotate(clip: Animation, rotations: Dictionary[int, int], out: Animation) -> PackedInt32Array:
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
			world[bone] = _target_base[bone]
			if source_bone >= 0:
				var delta: Quaternion = source_world[source_bone] * _source_base_inverse[source_bone]
				if _damping[bone] < 1.0:
					delta = Quaternion.IDENTITY.slerp(delta, _damping[bone])
				world[bone] = delta * _target_base[bone]
			var parent: int = _target.get_bone_parent(bone)
			var local_rotation: Quaternion = world[bone] if parent < 0 else world[parent].inverse() * world[bone]
			if step > 0 and previous[bone].dot(local_rotation) < 0.0:
				local_rotation = -local_rotation
			previous[bone] = local_rotation
			out.rotation_track_insert_key(tracks[bone], time, local_rotation)
	return tracks


## Rotação mundial de cada osso da UAL no instante `time`: a da trilha, ou a do repouso se o osso não tem trilha.
func _source_world(clip: Animation, rotations: Dictionary[int, int], time: float) -> Array[Quaternion]:
	var world: Array[Quaternion] = []
	world.resize(_source.get_bone_count())
	for bone: int in _source_order:
		var local_rotation: Quaternion = clip.rotation_track_interpolate(rotations[bone], time) if rotations.has(bone) else _source_rest_local[bone]
		var parent: int = _source.get_bone_parent(bone)
		world[bone] = local_rotation if parent < 0 else world[parent] * local_rotation
	return world


## A trilha de cada osso da UAL (e o osso é achado pelo nome) para o tipo de trilha dado.
func _tracks_of(clip: Animation, type: Animation.TrackType) -> Dictionary[int, int]:
	var tracks: Dictionary[int, int] = {}
	for track: int in clip.get_track_count():
		var bone: int = _source.find_bone(clip.track_get_path(track).get_concatenated_subnames())
		if bone >= 0 and clip.track_get_type(track) == type:
			tracks[bone] = track
	return tracks


## Com `bind_pose`: a rotação mundial de bind vira a base do destino e o quadro 0 de `reference_clip` (se houver) vira a base da UAL.
func _use_reference(reference_clip: Animation) -> void:
	if _options.bind_pose.is_empty():
		return
	for bone: int in _target.get_bone_count():
		var bone_name: String = _target.get_bone_name(bone)
		if _options.bind_pose.has(bone_name):
			_target_base[bone] = _options.bind_pose[bone_name].basis.get_rotation_quaternion()
	if reference_clip == null:
		return
	var world: Array[Quaternion] = _source_world(reference_clip, _tracks_of(reference_clip, Animation.TYPE_ROTATION_3D), 0.0)
	for bone: int in world.size():
		_source_base_inverse[bone] = world[bone].inverse()
	var moves: Dictionary[int, int] = _tracks_of(reference_clip, Animation.TYPE_POSITION_3D)
	for bone: int in moves:
		_source_origin[bone] = reference_clip.position_track_interpolate(moves[bone], 0.0)


## Com a trava de chão: a cadeia (da raiz ao osso) de cada osso do pé que o destino tem e a altura de referência de cada um.
func _find_ground() -> void:
	if not _options.ground_lock:
		return
	for bone_name: String in GROUND_BONES:
		var chain: PackedInt32Array = PackedInt32Array()
		var bone: int = _target.find_bone(bone_name)
		while bone >= 0:
			chain.insert(0, bone)
			bone = _target.get_bone_parent(bone)
		if not chain.is_empty():
			_ground_chains.append(chain)
	_ground_heights = _heights(_target_base, _rest_origins)


## A altura mundial de cada osso do pé (na ordem de `_ground_chains`), dadas as rotações mundiais e as translações locais dos ossos.
func _heights(world: Array[Quaternion], origins: Array[Vector3]) -> PackedFloat64Array:
	var heights: PackedFloat64Array = PackedFloat64Array()
	for chain: PackedInt32Array in _ground_chains:
		var position: Vector3 = Vector3.ZERO
		for bone: int in chain:
			var parent: int = _target.get_bone_parent(bone)
			position += origins[bone] if parent < 0 else world[parent] * origins[bone]
		heights.append(position.y)
	return heights


## A trava de chão (ver o cabeçalho): troca a trilha de translação da pélvis de `out` por uma reamostrada a 30 quadros por segundo, com a altura corrigida. `rotations`: o índice da trilha de rotação de cada osso do destino em `out`.
func _lock_ground(out: Animation, rotations: PackedInt32Array) -> void:
	var pelvis: int = _target.find_bone(PELVIS_BONE)
	if pelvis < 0 or _ground_chains.is_empty():
		return
	var path: NodePath = NodePath("%s:%s" % [SKELETON_NODE, PELVIS_BONE])
	var track: int = out.find_track(path, Animation.TYPE_POSITION_3D)
	var times: PackedFloat64Array = PackedFloat64Array()
	var values: Array[Vector3] = []
	for step: int in int(ceil(out.length * SAMPLES_PER_SECOND)) + 1:
		times.append(minf(step / SAMPLES_PER_SECOND, out.length))
		values.append(_grounded(out, rotations, times[step], pelvis, track))
	if track >= 0:
		out.remove_track(track)
	track = out.add_track(Animation.TYPE_POSITION_3D)
	out.track_set_path(track, path)
	for step: int in times.size():
		out.position_track_insert_key(track, times[step], values[step])


## A translação da pélvis em `time` com a altura corrigida: sobe (ou desce) o quanto falta ao osso do pé mais baixo para chegar à altura de referência dele; a vertical entra pela rotação mundial do pai da pélvis (a raiz da UAL gira 90 graus).
func _grounded(out: Animation, rotations: PackedInt32Array, time: float, pelvis: int, track: int) -> Vector3:
	var origins: Array[Vector3] = []
	origins.assign(_rest_origins)
	if track >= 0:
		origins[pelvis] = out.position_track_interpolate(track, time)
	var world: Array[Quaternion] = []
	world.resize(origins.size())
	for chain: PackedInt32Array in _ground_chains:
		for bone: int in chain:
			var parent: int = _target.get_bone_parent(bone)
			var local_rotation: Quaternion = out.rotation_track_interpolate(rotations[bone], time)
			world[bone] = local_rotation if parent < 0 else world[parent] * local_rotation
	var heights: PackedFloat64Array = _heights(world, origins)
	var gap: float = INF
	for index: int in heights.size():
		gap = minf(gap, heights[index] - _ground_heights[index])
	var lift: Vector3 = Vector3.UP * -gap
	var parent_of_pelvis: int = _target.get_bone_parent(pelvis)
	return origins[pelvis] + (lift if parent_of_pelvis < 0 else world[parent_of_pelvis].inverse() * lift)
