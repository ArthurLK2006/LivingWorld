class_name InteractionView
extends Node3D
## Interação na tela (LW-050): desenha um MARCADOR provisório por ponto de interesse (um cilindro de cor própria, sem modelo importado,
## sobre a altura do terreno e só enquanto o chão dele existe), acha o ponto mais próximo dentro do alcance, mostra o aviso
## "[tecla] Interagir" enquanto houver um e, ao apertar a ação `interact`, pede a interação pela ponte e mostra o texto devolvido por
## alguns segundos. A detecção do ponto próximo é só DICA VISUAL (distância horizontal, a mesma regra do mundo): quem decide é a
## simulação, que confere a distância pela posição guardada no personagem. Todo texto vem de data/text/pt_br.json (UiText); o código
## só conhece chaves. Sem regra de jogo. Contrato: docs/modules/presentation.md.

## Valores [HIP]: quanto tempo o texto do resultado fica na tela (s) e o desenho do marcador (m).
const RESULT_TEXT_SECONDS: float = 5.0
const MARKER_RADIUS_M: float = 0.4
const MARKER_HEIGHT_M: float = 2.5
## Cor provisória do marcador [HIP]: ciano vivo, para não se confundir com o terreno nem com a cápsula laranja.
const MARKER_COLOR: Color = Color(0.1, 0.85, 1.0)
const MARKER_NAME_PREFIX: String = "Marker_"
const HALF: float = 0.5
## Chaves de texto usadas aqui (as frases moram em data/text/pt_br.json).
const KEY_PROMPT: String = "ui.interact_prompt"
const KEY_TOO_FAR: String = "ui.interact_too_far"
const KEY_UNKNOWN: String = "ui.interact_unknown"
const KEY_FAILED: String = "ui.interact_failed"
## Códigos de falha da simulação que viram texto próprio. São os mesmos de InteractionService, que a apresentação não pode citar
## (regra B do check_architecture); tests/unit/test_interaction_view.gd confere que continuam iguais.
const CODE_TOO_FAR: String = "INTERACTION_TOO_FAR"
const CODE_UNKNOWN_POI: String = "INTERACTION_UNKNOWN_POI"

var _bridge: SimBridge
var _player: PlayerBody
var _terrain: TerrainView
var _texts: UiText
var _prompt_label: Label
var _result_label: Label
var _points: Array[BridgeReplies.PointReply] = []
var _markers: Dictionary[String, MeshInstance3D] = {}
var _nearest_id: String = ""
var _result_left_s: float = 0.0


func _ready() -> void:
	set_process(false)


## Liga a view à ponte, ao corpo do jogador, ao terreno (para saber se o chão do marcador existe), aos textos e aos dois rótulos da
## tela. Lê os pontos UMA vez e cria os marcadores. Qualquer peça nula ou falha da ponte: push_error e nada é criado (devolve falso).
func setup(bridge: SimBridge, player: PlayerBody, terrain: TerrainView, texts: UiText, prompt_label: Label, result_label: Label) -> bool:
	_clear()
	if bridge == null or player == null or terrain == null or texts == null or prompt_label == null or result_label == null:
		push_error("InteractionView.setup: ponte, jogador, terreno, textos ou rótulo nulo; esperado todos.")
		return false
	var reply: BridgeReplies.PointsReply = bridge.peek_points_of_interest()
	if not reply.result.ok:
		push_error("InteractionView.setup: pontos de interesse indisponíveis (%s): %s" % [reply.result.code, reply.result.message])
		return false
	_bridge = bridge
	_player = player
	_terrain = terrain
	_texts = texts
	_prompt_label = prompt_label
	_result_label = result_label
	_points = reply.points
	for point: BridgeReplies.PointReply in _points:
		_add_marker(point)
	_prompt_label.visible = false
	_result_label.visible = false
	set_process(true)
	return true


## Quantos marcadores existem (um por ponto, criados uma vez em `setup`).
func marker_count() -> int:
	return _markers.size()


## O marcador do ponto, ou nulo se o ponto não existe.
func marker_of(point_id: String) -> MeshInstance3D:
	return _markers.get(point_id) as MeshInstance3D


## Id do ponto mais próximo dentro do alcance, ou "" se não há nenhum (valor do último `refresh`).
func nearest_point_id() -> String:
	return _nearest_id


func _process(delta: float) -> void:
	refresh()
	tick(delta)


## Reavalia o ponto próximo, o aviso na tela e quais marcadores têm chão.
func refresh() -> void:
	if _bridge == null:
		return
	_nearest_id = _nearest_point_in_reach()
	_prompt_label.visible = not _nearest_id.is_empty()
	if _prompt_label.visible:
		_prompt_label.text = _texts.get_text(KEY_PROMPT, {"key": _interact_key_label()})
	for point_id: String in _markers:
		var marker: MeshInstance3D = _markers[point_id]
		marker.visible = _terrain.has_collision_at(marker.global_position)


## Passa o tempo do texto do resultado: depois de RESULT_TEXT_SECONDS ele some.
func tick(delta_seconds: float) -> void:
	if _result_left_s <= 0.0:
		return
	_result_left_s -= delta_seconds
	if _result_left_s <= 0.0:
		_result_label.visible = false


## Pede a interação ao ponto ao alcance (ou, se nenhum está ao alcance, ao mais próximo de todos: a simulação recusa e a tela mostra
## o texto de "chegue mais perto"). Sucesso: o texto do ponto; falha: o texto da chave de erro do código. Devolve se a interação valeu.
## Com o relógio da simulação pausado nada é enviado nem mostrado (LW-051, decisão D1 de Arthur: a pausa congela o personagem).
func interact() -> bool:
	if _bridge == null or _is_game_paused():
		return false
	var target_id: String = _nearest_id if not _nearest_id.is_empty() else _nearest_point_overall()
	if target_id.is_empty():
		_show_result(_texts.get_text(KEY_FAILED))
		return false
	var reply: BridgeReplies.InteractReply = _bridge.request_interact(_player.get_actor_id(), target_id)
	if reply.result.ok:
		_show_result(_texts.get_text(reply.text_key))
		return true
	_show_result(_texts.get_text(_failure_key(reply.result.code)))
	return false


## Pausa do relógio, lida pela ponte; hora indisponível conta como não pausado.
func _is_game_paused() -> bool:
	var time: BridgeReplies.TimeSnapshot = _bridge.peek_time()
	return time.result.ok and time.is_paused


func _unhandled_input(event: InputEvent) -> void:
	if _bridge != null and event.is_action_pressed(InputActions.INTERACT):
		interact()
		get_viewport().set_input_as_handled()


func _failure_key(code: String) -> String:
	if code == CODE_TOO_FAR:
		return KEY_TOO_FAR
	if code == CODE_UNKNOWN_POI:
		return KEY_UNKNOWN
	return KEY_FAILED


func _show_result(text: String) -> void:
	_result_label.text = text
	_result_label.visible = true
	_result_left_s = RESULT_TEXT_SECONDS


## Distância horizontal (x, z) do jogador ao ponto, a mesma regra do mundo (a altura não conta).
func _horizontal_distance_m(point: BridgeReplies.PointReply) -> float:
	return Vector2(_player.global_position.x - point.x, _player.global_position.z - point.z).length()


func _nearest_point_in_reach() -> String:
	var best_id: String = ""
	var best_m: float = INF
	for point: BridgeReplies.PointReply in _points:
		var distance_m: float = _horizontal_distance_m(point)
		if distance_m <= point.reach_m and distance_m < best_m:
			best_id = point.id
			best_m = distance_m
	return best_id


func _nearest_point_overall() -> String:
	var best_id: String = ""
	var best_m: float = INF
	for point: BridgeReplies.PointReply in _points:
		var distance_m: float = _horizontal_distance_m(point)
		if distance_m < best_m:
			best_id = point.id
			best_m = distance_m
	return best_id


## Tecla da ação `interact` para o aviso, lida do InputMap (primeira palavra do texto do evento, ex.: "E"), como o GameApp faz com a pausa.
func _interact_key_label() -> String:
	var events: Array[InputEvent] = InputMap.action_get_events(InputActions.INTERACT)
	return events[0].as_text().get_slice(" ", 0) if not events.is_empty() else "?"


func _add_marker(point: BridgeReplies.PointReply) -> void:
	var mesh: CylinderMesh = CylinderMesh.new()
	mesh.top_radius = MARKER_RADIUS_M
	mesh.bottom_radius = MARKER_RADIUS_M
	mesh.height = MARKER_HEIGHT_M
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = MARKER_COLOR
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh.material = material
	var marker: MeshInstance3D = MeshInstance3D.new()
	marker.name = MARKER_NAME_PREFIX + point.id
	marker.mesh = mesh
	marker.visible = false
	add_child(marker)
	marker.global_position = Vector3(point.x, point.y + MARKER_HEIGHT_M * HALF, point.z)
	_markers[point.id] = marker


func _clear() -> void:
	set_process(false)
	for marker: MeshInstance3D in _markers.values():
		remove_child(marker)
		marker.queue_free()
	_markers.clear()
	_points = []
	_nearest_id = ""
	_result_left_s = 0.0
	_bridge = null
