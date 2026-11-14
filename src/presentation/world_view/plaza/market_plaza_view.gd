class_name MarketPlazaView
extends Node3D
## Praça de mercado artística no jogo (ART-2b): em volta de cada local `market`, a praça procedural facetada (5 barracas com seus adereços, postes de lampião com bandeirolas, tochas, o poço e uma mancha de terra batida) no lugar da caixa branca provisória. Só apresentação: sem colisão, texto nem regra de jogo
## (o alcance de 3 m do centro, a tecla E e a compra seguem na simulação). Cada praça é um `Node3D` `MarketPlaza_<id do local>` no x e no z do local, com a origem na altura do terreno do centro; cada peça fica na altura do terreno do ponto dela (`peek_height` da ponte), sem chão, vegetação nem casas
## (o terreno do jogo é o chão). A praça é montada no `setup` (cerca de 3,5 ms por praça sem janela, medido na ART-2b) e fica escondida até o terreno do chunk do centro dela existir (`set_chunk_visible`, ligado a `chunk_loaded` e `chunk_unloaded` pela cena). A view fica na origem do mundo.
## Os mercados ficam nos povoados a 14 m dos vizinhos e a praça cheia (cerca de 24 x 18 m) tocaria as caixas deles: ela leva uma escala uniforme, a maior que a deixa a NEIGHBOR_MARGIN_M de cada caixa vizinha.
## ART-5a: as 7 luzes pequenas de cada praça (lampiões e tochas) acendem e apagam com a hora, pelo fator de `set_lamp_factor`. Contrato: docs/modules/presentation.md.

const PLAZA_NAME_PREFIX: String = "MarketPlaza_"
const HALF: float = 0.5
## O retângulo (x e z, em metros, no quadro local e na escala 1) que as peças da praça ocupam, medido na ART-2b nos vértices de estruturas e mancha: o canto do toldo das barracas de fora (x), os lampiões do fundo (z positivo) e a mancha de 9 m (z negativo) [HIP].
## O teste confere que ele cobre as peças com folga de poucos centímetros: se a praça mudar, ele muda junto.
const FOOTPRINT_M: Rect2 = Rect2(-11.85, -9.0, 23.7, 18.28)
## A menor escala da praça, mesmo que algum vizinho ainda a toque [HIP].
const MIN_SCALE: float = 0.6
## Folga entre a praça e a caixa de cada local vizinho [HIP].
const NEIGHBOR_MARGIN_M: float = 0.5
## Com o fator de luz (0 a 1) neste valor ou abaixo, a luz do lampião ou da tocha fica escondida: luz invisível não custa nada no Compatibility e com tão pouca energia não se enxergaria [HIP].
const LAMP_ON_THRESHOLD: float = 0.01

var _plazas: Dictionary[String, Node3D] = {}
var _plazas_by_chunk: Dictionary[Vector2i, Array] = {}
## As luzes dos lampiões e das tochas de todas as praças (as escondidas também), cada uma com a energia base que a montagem lhe deu.
var _lights: Dictionary[OmniLight3D, float] = {}
## O fator de luz (0 a 1) em vigor; as praças montadas depois já nascem com ele. Nasce apagado (0, o dia): quem acompanha a hora o liga por `set_lamp_factor`.
var _lamp_factor: float = 0.0


## Cria e monta uma praça por mercado. Ponte nula, ponte sem terreno ou consulta que falha: push_error e nada é criado (devolve falso).
func setup(bridge: SimBridge) -> bool:
	_clear()
	if bridge == null:
		push_error("MarketPlazaView.setup: ponte nula; esperado uma SimBridge.")
		return false
	var layout: BridgeReplies.TerrainLayoutReply = bridge.peek_terrain_layout()
	if not layout.result.ok:
		return _fail(layout.result)
	var reply: BridgeReplies.PlacesReply = bridge.peek_places()
	if not reply.result.ok:
		return _fail(reply.result)
	var chunk_size_m: float = float(layout.chunk_cells) * layout.cell_size_m
	for place: BridgeReplies.PlaceReply in reply.places:
		if place.kind == PlacePalette.KIND_MARKET:
			var chunk: Vector2i = Vector2i(clampi(floori(place.x / chunk_size_m), 0, layout.chunk_count.x - 1), clampi(floori(place.z / chunk_size_m), 0, layout.chunk_count.y - 1))
			_add_plaza(bridge, place, _fit_scale(place, reply.places), chunk)
	return true


## Mostra ou esconde as praças do chunk; chunk sem praça não faz nada.
func set_chunk_visible(chunk: Vector2i, shown: bool) -> void:
	for plaza: Node3D in _plazas_by_chunk.get(chunk, []):
		plaza.visible = shown


## Acende os lampiões e as tochas de TODAS as praças, também das escondidas (ao aparecerem já estão certas): energia = a base x `factor` (0 a 1, limitado) e a luz fica escondida se o fator não passa de LAMP_ON_THRESHOLD.
## O mesmo fator de antes não faz nada: a rig repete o estado a cada quadro e, de dia e de noite, o fator não muda.
func set_lamp_factor(factor: float) -> void:
	var clamped: float = clampf(factor, 0.0, 1.0)
	if is_equal_approx(clamped, _lamp_factor):
		return
	_lamp_factor = clamped
	for light: OmniLight3D in _lights:
		_light_up(light)


func plaza_count() -> int:
	return _plazas.size()


## A praça do local, ou nulo se o local não tem praça.
func plaza_of(place_id: String) -> Node3D:
	return _plazas.get(place_id) as Node3D


func _add_plaza(bridge: SimBridge, place: BridgeReplies.PlaceReply, plaza_scale: float, chunk: Vector2i) -> void:
	var plaza: Node3D = Node3D.new()
	plaza.name = PLAZA_NAME_PREFIX + place.id
	plaza.position = Vector3(place.x, place.y, place.z)
	plaza.scale = Vector3.ONE * plaza_scale
	plaza.visible = false
	var options: PlazaBuilder.Options = PlazaBuilder.Options.new()
	options.has_ground = false
	options.has_vegetation = false
	options.has_houses = false
	options.height_provider = _local_height.bind(bridge, plaza)
	var built: PlazaBuilder.Built = PlazaBuilder.new().build(plaza, options)
	PlazaGround.new(plaza, built.materials, options.height_provider).add_patch(PlazaData.PLAZA_RADIUS_M)
	for light: OmniLight3D in built.lamp_lights + built.torch_lights:
		_lights[light] = light.light_energy
		_light_up(light)
	add_child(plaza)
	_plazas[place.id] = plaza
	if not _plazas_by_chunk.has(chunk):
		_plazas_by_chunk[chunk] = []
	_plazas_by_chunk[chunk].append(plaza)


func _light_up(light: OmniLight3D) -> void:
	light.light_energy = _lights[light] * _lamp_factor
	light.visible = _lamp_factor > LAMP_ON_THRESHOLD


## Altura do terreno no ponto (x, z) do quadro local da praça, no quadro local (a escala da praça vale para a altura também); fora do mapa a peça fica na altura da origem da praça.
func _local_height(x: float, z: float, bridge: SimBridge, plaza: Node3D) -> float:
	var world: Vector3 = plaza.transform * Vector3(x, 0.0, z)
	var reply: BridgeReplies.HeightReply = bridge.peek_height(world.x, world.z)
	return (reply.height_m - plaza.position.y) / plaza.scale.y if reply.result.ok else 0.0


## A maior escala (até 1, no mínimo MIN_SCALE) com que o retângulo da praça fica a NEIGHBOR_MARGIN_M da caixa de todo local desenhado que não é mercado (a caixa do mercado fica escondida). Os dois retângulos são alinhados aos eixos e ficam separados se um dos eixos os separa.
func _fit_scale(market: BridgeReplies.PlaceReply, places: Array[BridgeReplies.PlaceReply]) -> float:
	var fit: float = 1.0
	for place: BridgeReplies.PlaceReply in places:
		if place.kind == PlacePalette.KIND_MARKET or not PlacePalette.is_drawn(place.kind):
			continue
		var size: Vector3 = PlacePalette.SIZES[place.kind]
		var half: Vector2 = Vector2(size.x, size.z) * HALF + Vector2.ONE * NEIGHBOR_MARGIN_M
		var along_x: float = _separating_scale(place.x - market.x, half.x, FOOTPRINT_M.position.x, FOOTPRINT_M.end.x)
		var along_z: float = _separating_scale(place.z - market.z, half.y, FOOTPRINT_M.position.y, FOOTPRINT_M.end.y)
		fit = minf(fit, maxf(along_x, along_z))
	return maxf(fit, MIN_SCALE)


## A maior escala com que o intervalo da praça [escala x low, escala x high] (low < 0 < high) não toca o da caixa [center - half, center + half] (center relativo ao mercado). Caixa que cobre o mercado nesse eixo não se separa em escala nenhuma (zero).
func _separating_scale(center: float, half: float, low: float, high: float) -> float:
	if center - half > 0.0:
		return (center - half) / high
	if center + half < 0.0:
		return (center + half) / low
	return 0.0


func _fail(failure: Result) -> bool:
	push_error("MarketPlazaView.setup: %s (%s)" % [failure.message, failure.code])
	return false


func _clear() -> void:
	for plaza: Node3D in _plazas.values():
		remove_child(plaza)
		plaza.free()
	_plazas.clear()
	_plazas_by_chunk.clear()
	_lights.clear()
