class_name NpcView
extends Node3D
## Corpo provisório de um NPC em S0 (LW-072b): uma cápsula azul-acinzentada com um "nariz" que mostra a frente (-Z local, como no `look_at`).
## A origem fica nos pés, como no `PlayerBody`. SÓ VISUAL: sem colisão, sem física e sem regra de jogo. Parado fica imóvel; andando quica na
## vertical e se inclina um pouco para a frente. Não conhece o `npc`: guarda só o ID do NPC a que está ligado. Contrato: docs/modules/presentation.md.
## FIGURA INTEIRA (ART-12, 7b-1): `attach_figure` põe uma figura montada (`CharacterFigure.build`) no lugar da cápsula, como filha do corpo e não da parte que balança; com figura a cápsula fica escondida e sem quique nem inclinação, e `set_walking` e `set_speed_mps` escolhem o clipe (idle, walk ou jog) e a escala pelo `CharacterLocomotion`; `clear_figure` (que o `detach` chama) solta e libera a figura. Quem monta a figura e a entrega ao corpo é a 7b-2; aqui o corpo só a recebe, e sem figura ele é a cápsula de sempre.
## DISSOLUÇÃO (LW-099d): `set_fade(amount)` põe a transparência de instância (`PresenceFade`) na cápsula, no nariz e na figura, se houver; quem o faz sumir é a `NpcBodiesView` na partida da caravana. `attach`, `detach` e `clear_figure` voltam o corpo a OPACO: o corpo reaproveitado da reserva nunca nasce transparente.

## Cápsula [HIP] (m): a mesma do jogador, com poucos segmentos (até 50 corpos na tela; estilo low-poly).
const CAPSULE_RADIUS_M: float = 0.4
const CAPSULE_HEIGHT_M: float = 1.8
const CAPSULE_RADIAL_SEGMENTS: int = 8
const CAPSULE_RINGS: int = 2
## Cores [HIP], iguais para todos os NPCs: corpo azul-acinzentado (longe do laranja do jogador) e nariz claro.
const BODY_COLOR: Color = Color(0.45, 0.55, 0.70)
const NOSE_COLOR: Color = Color(0.92, 0.92, 0.85)
## Nariz [HIP]: lado do cubo (m) e altura dele como fração da altura do corpo.
const NOSE_SIZE_M: float = 0.2
const NOSE_HEIGHT_RATIO: float = 0.8
## Andar [HIP]: quiques por segundo, altura do quique (m) e inclinação para a frente (graus).
const WALK_BOUNCES_PER_SECOND: float = 2.5
const WALK_BOUNCE_HEIGHT_M: float = 0.06
const WALK_TILT_DEGREES: float = 4.0
const VISUAL_NAME: String = "Visual"
const CAPSULE_NAME: String = "Capsule"
const NOSE_NAME: String = "Nose"
const HALF: float = 0.5
## Giro da figura (rad): a figura gravada olha para +Z e o nariz da cápsula (a frente do corpo, como no `look_at`) para -Z, então ela entra virada meia-volta.
const FIGURE_YAW_RAD: float = PI
## Escala de reprodução do clipe que não tem escala própria (idle e walk sem velocidade conhecida): o passo na velocidade em que foi gravado.
const NEUTRAL_PLAY_SCALE: float = 1.0
## `custom_blend` negativo do `AnimationPlayer.play`: vale a mistura padrão da biblioteca da figura.
const DEFAULT_BLEND: float = -1.0

## NPC a que o corpo está ligado (IdGenerator.NO_ID = livre, esperando no pool).
var npc_id: int = IdGenerator.NO_ID

## Parte que balança: a cápsula e o nariz ficam nela, para o nó do corpo guardar sempre a posição lógica (os pés no chão).
var _visual: Node3D
var _is_walking: bool = false
var _bounce_phase: float = 0.0
## Velocidade do corpo (m/s) que o motorista informa por `set_speed_mps`; só a figura a usa; 0 = desconhecida.
var _speed_mps: float = 0.0
## A figura inteira (null = a cápsula), o `AnimationPlayer` filho direto dela (null = a figura não anima), as velocidades dela (lidas UMA vez, ao receber a figura) e o último clipe e escala que mandamos tocar ("" = nenhum ainda).
var _figure: Node3D
var _figure_player: AnimationPlayer
var _figure_speeds: Dictionary[String, float] = {}
var _played_clip: String = ""
var _played_scale: float = NEUTRAL_PLAY_SCALE
## A transparência que `set_fade` pôs por último (0 = opaco, 1 = invisível).
var _fade: float = PresenceFade.OPAQUE


func _init() -> void:
	_visual = Node3D.new()
	_visual.name = VISUAL_NAME
	add_child(_visual)
	var capsule: CapsuleMesh = CapsuleMesh.new()
	capsule.radius = CAPSULE_RADIUS_M
	capsule.height = CAPSULE_HEIGHT_M
	capsule.radial_segments = CAPSULE_RADIAL_SEGMENTS
	capsule.rings = CAPSULE_RINGS
	_visual.add_child(_new_part(CAPSULE_NAME, capsule, BODY_COLOR, Vector3(0.0, CAPSULE_HEIGHT_M * HALF, 0.0)))
	var nose: BoxMesh = BoxMesh.new()
	nose.size = Vector3.ONE * NOSE_SIZE_M
	# O nariz fica à frente (-Z local), na altura da cabeça.
	_visual.add_child(_new_part(NOSE_NAME, nose, NOSE_COLOR, Vector3(0.0, CAPSULE_HEIGHT_M * NOSE_HEIGHT_RATIO, -CAPSULE_RADIUS_M)))


## A Godot liga o `_process` sozinha quando o nó entra na árvore (o script tem `_process`); o corpo só processa andando.
func _ready() -> void:
	set_process(_capsule_bounces())


## Liga o corpo ao NPC, parado, olhando para -Z, com os pés em `ground_position` (metros, mundo), OPACO, e o mostra.
func attach(new_npc_id: int, ground_position: Vector3) -> void:
	set_fade(PresenceFade.OPAQUE)
	set_walking(false)
	npc_id = new_npc_id
	position = ground_position
	rotation = Vector3.ZERO
	visible = true


## Solta o NPC: o corpo some e fica livre para o pool. O corpo reciclado NÃO herda a figura, a velocidade nem a transparência da dissolução (todo `give_back` do pool passa por aqui).
func detach() -> void:
	clear_figure()
	set_walking(false)
	npc_id = IdGenerator.NO_ID
	visible = false


## Liga ou desliga o andar. Parar devolve o corpo à posição de pé (sem quique nem inclinação). Com figura, também troca o clipe (parado = idle).
func set_walking(walking: bool) -> void:
	if walking == _is_walking:
		return
	_is_walking = walking
	_apply_capsule_pose()
	_apply_figure_clip()


func is_walking() -> bool:
	return _is_walking


## Põe `figure` (a raiz de `CharacterFigure.build`, SOLTA: sem pai; senão erro visível e nada muda) no lugar da cápsula e passa a ser dona dela. A figura vira filha do CORPO, e não de `_visual`, que se inclina e quica; a escala é a do `build` e fica como está. Lê UMA vez as velocidades dela (`CharacterFigure.locomotion_of`) e acha o `AnimationPlayer` filho direto; figura SEM player aparece mas não anima. Se já havia figura, a antiga é solta e liberada (nunca há duas). Começa conforme o estado do corpo (parado = idle).
func attach_figure(figure: Node3D) -> void:
	if figure == null or figure.get_parent() != null:
		push_error("NpcView.attach_figure: a figura deve existir e chegar solta (sem pai); o corpo é quem passa a ser o dono dela.")
		return
	_drop_figure()
	_figure = figure
	_figure.rotation.y = FIGURE_YAW_RAD
	add_child(_figure)
	_figure_speeds = CharacterFigure.locomotion_of(_figure)
	var players: Array[Node] = _figure.find_children("*", "AnimationPlayer", false, false)
	_figure_player = players[0] as AnimationPlayer if not players.is_empty() else null
	_apply_capsule_pose()
	_apply_figure_clip()
	if _fade > PresenceFade.OPAQUE:
		PresenceFade.apply(_figure, _fade)


## Solta a figura do corpo NA HORA (`remove_child`: sai da lista de filhos) e a libera (`queue_free` se estava na árvore; `free` se não estava); a cápsula volta. Zera a velocidade do corpo, a tabela de velocidades, o player e o clipe lembrado, e volta o corpo a OPACO (`set_fade(0)`).
## Sem figura e opaco só zera a velocidade (nada visível muda).
func clear_figure() -> void:
	_speed_mps = 0.0
	_drop_figure()
	set_fade(PresenceFade.OPAQUE)


## Dissolução (LW-099d): põe a transparência `amount` (presa entre 0 = opaco e 1 = invisível; NaN é ignorado) na cápsula, no nariz e na figura, se houver. Repetir o mesmo valor não faz nada. É SÓ visual: não mexe em `visible`, na posição nem na pisada.
func set_fade(amount: float) -> void:
	if is_nan(amount):
		return
	var value: float = clampf(amount, PresenceFade.OPAQUE, PresenceFade.INVISIBLE)
	if value == _fade:
		return
	_fade = value
	PresenceFade.apply(self, _fade)


## A transparência que o corpo tem agora (0 = opaco, 1 = invisível).
func fade() -> float:
	return _fade


func has_figure() -> bool:
	return is_instance_valid(_figure)


## A velocidade do corpo (m/s), informada pelo motorista (a cápsula não a usa). Com figura e andando, reaplica o clipe e a escala: a velocidade que a tabela da figura cobre vira walk ou jog (`CharacterLocomotion.pick`).
func set_speed_mps(new_speed_mps: float) -> void:
	_speed_mps = new_speed_mps
	_apply_figure_clip()


## A velocidade guardada por `set_speed_mps` (0 = desconhecida), para os testes do motorista.
func speed_mps() -> float:
	return _speed_mps


## Avança o quique em `delta` segundos. Parado, ou com figura (que se anima sozinha), não faz nada. O quique nunca afunda o corpo no chão: vai de 0 até WALK_BOUNCE_HEIGHT_M.
func advance_animation(delta: float) -> void:
	if not _capsule_bounces():
		return
	_bounce_phase = fmod(_bounce_phase + delta * WALK_BOUNCES_PER_SECOND * PI, PI)
	_visual.position.y = sin(_bounce_phase) * WALK_BOUNCE_HEIGHT_M


func _process(delta: float) -> void:
	advance_animation(delta)


## Só a cápsula quica e se inclina, e só andando: com figura ela fica escondida e parada.
func _capsule_bounces() -> bool:
	return _is_walking and not has_figure()


## Põe a cápsula conforme o estado: escondida se há figura; de pé, ou inclinada e quicando se anda sem figura. O `_process` só liga quando ela quica.
func _apply_capsule_pose() -> void:
	var bounces: bool = _capsule_bounces()
	_bounce_phase = 0.0
	_visual.visible = not has_figure()
	_visual.position = Vector3.ZERO
	_visual.rotation = Vector3(-deg_to_rad(WALK_TILT_DEGREES), 0.0, 0.0) if bounces else Vector3.ZERO
	set_process(bounces)


## Tira a figura (se houver) e esquece o que era dela; a cápsula volta ao estado do corpo. Sem figura não faz nada. A cápsula escondida é o sinal de que havia figura, mesmo uma que alguém liberou por fora (o corpo reciclado não pode ficar invisível).
func _drop_figure() -> void:
	if has_figure():
		var was_in_tree: bool = _figure.is_inside_tree()
		remove_child(_figure)
		if was_in_tree:
			_figure.queue_free()
		else:
			_figure.free()
	_figure = null
	_figure_player = null
	_figure_speeds.clear()
	_played_clip = ""
	if not _visual.visible:
		_apply_capsule_pose()


## O clipe e a escala da figura para o estado do corpo: parado = idle (escala 1); andando com velocidade conhecida (finita e maior que 0) = o que o `CharacterLocomotion.pick` devolve; andando sem ela = walk na escala 1 (como a cápsula). Só manda tocar quando o clipe OU a escala mudam (`is_equal_approx`): repetir o mesmo pedido não reinicia o passo. Clipe que o player não tem (figura incompleta) fica como está, sem erro por quadro.
func _apply_figure_clip() -> void:
	if not is_instance_valid(_figure_player):
		return
	var clip: String = CharacterLocomotion.IDLE
	var play_scale: float = NEUTRAL_PLAY_SCALE
	if _is_walking:
		clip = CharacterLocomotion.WALK
		if is_finite(_speed_mps) and _speed_mps > 0.0:
			var choice: CharacterLocomotion.Pick = CharacterLocomotion.pick(_speed_mps, _figure_speeds)
			clip = choice.clip
			play_scale = choice.scale
	if clip == _played_clip and is_equal_approx(play_scale, _played_scale):
		return
	if not _figure_player.has_animation(StringName(clip)):
		return
	_figure_player.play(StringName(clip), DEFAULT_BLEND, play_scale)
	_played_clip = clip
	_played_scale = play_scale


static func _new_part(part_name: String, mesh: PrimitiveMesh, color: Color, at: Vector3) -> MeshInstance3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = color
	mesh.material = material
	var part: MeshInstance3D = MeshInstance3D.new()
	part.name = part_name
	part.mesh = mesh
	part.position = at
	return part
