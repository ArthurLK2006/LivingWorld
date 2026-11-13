class_name InteractionView
extends Node3D
## Interação na tela (LW-050): desenha um MARCADOR provisório por ponto de interesse (um cilindro de cor própria, sem modelo importado,
## sobre a altura do terreno e só enquanto o chão dele existe), acha o ponto mais próximo dentro do alcance, mostra o aviso
## "[tecla] Interagir" enquanto houver um e, ao apertar a ação `interact`, pede a interação pela ponte e mostra o texto devolvido por
## alguns segundos. A detecção do ponto próximo é só DICA VISUAL (distância horizontal, a mesma regra do mundo): quem decide é a
## simulação, que confere a distância pela posição guardada no personagem. Todo texto vem de data/text/pt_br.json (UiText); o código
## só conhece chaves. Sem regra de jogo. LW-083e: a mesma tecla também conversa com o NPC a até 3 m (`InteractionTarget` escolhe; o mais perto vence e o NPC ganha o
## empate); o texto é o da chave da resposta da ponte. LW-106e: o mercado é o TERCEIRO alvo da tecla, SÓ sem ponto nem NPC ao alcance e se a ponte (`peek_market_in_reach`) diz que há um
## ao alcance: aviso `ui.market.prompt` e o sinal `market_requested`; a regra e a distância são do `world`. Contrato: docs/modules/presentation.md.

## Valores [HIP]: quanto tempo o texto do resultado fica na tela (s), de quanto em quanto tempo se pergunta pelo mercado ao alcance (s; só para o aviso) e o desenho do marcador (m).
const RESULT_TEXT_SECONDS: float = 5.0
const MARKET_QUERY_INTERVAL_S: float = 0.25
const MARKER_RADIUS_M: float = 0.4
const MARKER_HEIGHT_M: float = 2.5
## Cor provisória do marcador [HIP]: ciano vivo, para não se confundir com o terreno nem com a cápsula laranja.
const MARKER_COLOR: Color = Color(0.1, 0.85, 1.0)
const MARKER_NAME_PREFIX: String = "Marker_"
const HALF: float = 0.5
## Chaves de texto usadas aqui (as frases moram em data/text/pt_br.json).
const KEY_PROMPT: String = "ui.interact_prompt"
const KEY_MARKET_PROMPT: String = "ui.market.prompt"
const KEY_TOO_FAR: String = "ui.interact_too_far"
const KEY_UNKNOWN: String = "ui.interact_unknown"
const KEY_FAILED: String = "ui.interact_failed"
## Códigos de falha da simulação que viram texto próprio. São os mesmos de InteractionService, que a apresentação não pode citar
## (regra B do check_architecture); tests/unit/test_interaction_view.gd confere que continuam iguais.
const CODE_TOO_FAR: String = "INTERACTION_TOO_FAR"
const CODE_UNKNOWN_POI: String = "INTERACTION_UNKNOWN_POI"

## Pede abrir a tela do mercado `market_id` (LW-106e): sai quando a tecla é apertada sem ponto nem NPC ao alcance e com um mercado ao alcance; a cena principal o liga à `MarketView`.
signal market_requested(market_id: int)

var _bridge: SimBridge
var _player: PlayerBody
var _terrain: TerrainView
var _texts: UiText
var _prompt_label: Label
var _result_label: Label
var _points: Array[BridgeReplies.PointReply] = []
var _markers: Dictionary[String, MeshInstance3D] = {}
var _nearest_id: String = ""
## Os corpos dos NPCs (LW-083e), opcional: sem eles a tecla só alcança pontos de interesse, como antes. `_target` é o alvo do último `refresh`.
var _bodies: NpcBodiesView
var _target: InteractionTarget = InteractionTarget.new()
var _result_left_s: float = 0.0
## LW-106e: bloqueada pela cena enquanto a tela de mercado está aberta; o último mercado ao alcance que a ponte disse (só para o aviso) e quanto falta para perguntar de novo.
var _is_blocked: bool = false
var _market_id: int = IdGenerator.NO_ID
var _market_wait_s: float = 0.0


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


## Liga a view aos corpos dos NPCs (LW-083e): a mesma tecla `interact` passa a alcançar também o NPC a até 3 m. Opcional e independente do `setup`.
func set_npc_bodies(bodies: NpcBodiesView) -> void:
	_bodies = bodies


## Bloqueia ou libera a view (LW-106e); a cena a bloqueia enquanto a tela de mercado está aberta. Bloqueada, o aviso some (o do ponto e o do mercado), o mercado não é consultado e `interact()` não faz
## nada; liberada, volta ao normal no próximo `refresh`.
func set_blocked(blocked: bool) -> void:
	_is_blocked = blocked
	if blocked and _prompt_label != null:
		_prompt_label.visible = false


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
	_target = _choose_target()
	_nearest_id = _target.point_id
	var prompt_key: String = _prompt_key()
	_prompt_label.visible = not prompt_key.is_empty()
	if _prompt_label.visible:
		_prompt_label.text = _texts.get_text(prompt_key, {"key": _interact_key_label()})
	for point_id: String in _markers:
		var marker: MeshInstance3D = _markers[point_id]
		marker.visible = _terrain.has_collision_at(marker.global_position)


## Passa o tempo do texto do resultado (depois de RESULT_TEXT_SECONDS ele some) e o da próxima pergunta pelo mercado ao alcance (MARKET_QUERY_INTERVAL_S).
func tick(delta_seconds: float) -> void:
	_market_wait_s = maxf(_market_wait_s - delta_seconds, 0.0)
	if _result_left_s <= 0.0:
		return
	_result_left_s -= delta_seconds
	if _result_left_s <= 0.0:
		_result_label.visible = false


## Pede a interação ao ponto ao alcance (ou, se nenhum está ao alcance, ao mais próximo de todos: a simulação recusa e a tela mostra
## o texto de "chegue mais perto"). Sucesso: o texto do ponto; falha: o texto da chave de erro do código. Devolve se a interação valeu.
## Com o relógio da simulação pausado nada é enviado nem mostrado (LW-051, decisão D1 de Arthur: a pausa congela o personagem). LW-106e: bloqueada, não faz nada; e SÓ sem ponto nem NPC ao alcance
## ela pergunta de novo, na hora (sem usar o último resultado), pelo mercado ao alcance: havendo um, emite `market_requested` e devolve verdadeiro; senão segue como acima.
func interact() -> bool:
	if _bridge == null or _is_blocked or _is_game_paused():
		return false
	if _target.kind == InteractionTarget.Kind.NPC:
		return _talk_to(_target.npc_id)
	if _target.kind == InteractionTarget.Kind.NONE:
		var market_id: int = _market_in_reach()
		if market_id != IdGenerator.NO_ID:
			market_requested.emit(market_id)
			return true
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


## Conversa com o NPC (LW-083e): o texto mostrado é o da chave da resposta da ponte (a da conversa ou a da recusa). Devolve se a conversa começou.
func _talk_to(npc_id: int) -> bool:
	var reply: BridgeReplies.ConverseReply = _bridge.request_converse(_player.get_actor_id(), npc_id)
	_show_result(_texts.get_text(reply.text_key))
	return reply.result.ok


## Pausa do relógio, lida pela ponte; hora indisponível conta como não pausado.
func _is_game_paused() -> bool:
	var time: BridgeReplies.TimeSnapshot = _bridge.peek_time()
	return time.result.ok and time.is_paused


## A chave do aviso agora, ou "" se não há aviso (LW-106e): bloqueada, nenhum; com ponto ou NPC ao alcance, o de sempre; SÓ sem eles, o do mercado, se a ponte disse que há um ao alcance
## (a pergunta se repete no máximo a cada MARKET_QUERY_INTERVAL_S; entre elas vale o último resultado).
func _prompt_key() -> String:
	if _is_blocked:
		return ""
	if _target.kind != InteractionTarget.Kind.NONE:
		return KEY_PROMPT
	if _market_wait_s <= 0.0:
		_market_wait_s = MARKET_QUERY_INTERVAL_S
		_market_id = _market_in_reach()
	return KEY_MARKET_PROMPT if _market_id != IdGenerator.NO_ID else ""


## O mercado ao alcance do jogador segundo a ponte (a regra e a distância são do `world`; a posição é a guardada na simulação), ou IdGenerator.NO_ID se nenhum.
func _market_in_reach() -> int:
	var reply: BridgePlayerEconomyReplies.MarketInReachReply = _bridge.peek_market_in_reach(_player.get_actor_id())
	return reply.market_id if reply.result.ok else IdGenerator.NO_ID


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


## O alvo da tecla agora: o ponto ou o NPC mais perto dentro do alcance (o NPC ganha o empate). Só entram corpos visíveis (com terreno desenhado).
func _choose_target() -> InteractionTarget:
	var bodies: Dictionary[int, Vector3] = {}
	if _bodies != null:
		for npc_id: int in _bodies.active_ids():
			var view: NpcView = _bodies.pool().body_of(npc_id)
			if view.visible:
				bodies[npc_id] = view.global_position
	return InteractionTarget.choose(Vector2(_player.global_position.x, _player.global_position.z), _points, bodies)


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
	_target = InteractionTarget.new()
	_result_left_s = 0.0
	_market_id = IdGenerator.NO_ID
	_market_wait_s = 0.0
	_bridge = null
