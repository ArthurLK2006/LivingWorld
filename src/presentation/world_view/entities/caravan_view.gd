class_name CaravanView
extends Node3D
## LW-099b2a (viagem visível dos comerciantes; só apresentação): o CORPO de UMA caravana na tela, todo de primitivas (sem arte nova), no espírito do mercado
## provisório da LW-105e. Três partes, filhas deste nó: o COMERCIANTE à frente (um `NpcView` próprio, a mesma cápsula provisória, que NÃO sai do `NpcViewPool`
## nem recebe figura; se um dia houver figura, ela entra por `merchant()`), o CARRINHO atrás (leito, duas varas e duas rodas, cada roda com PIVÔ próprio) e a
## CARGA (0 a 3 volumes de um bem, na cor e na forma da tabela do `CaravanRoutesReader`, escolhidos só pela FAIXA de `load_permille`: nunca a contagem exata,
## que está no painel econômico). SÓ VISUAL: sem colisão, física, interação, ponte nem simulação; guarda só o `trader_id` da caravana a que está ligado.
## A origem fica nos PÉS do comerciante e a frente é -Z local (como no `NpcView` e em `NpcRoute.facing_yaw`); o carrinho vem atrás (+Z).
## Quem o usa (a 099b2b) calcula a pose com `CaravanPath` e a entrega a `apply_pose`. As rodas e a pisada seguem só o deslocamento REAL entre duas poses
## seguidas (roda: distância ÷ raio; pisada: a do `NpcView` na velocidade em que foi calibrada) e só com a caravana andando: parada, ou em pausa (a mesma
## pose), nada anima. O corpo nasce ESCONDIDO e só aparece na primeira pose depois de `bind`; esconder por falta de terreno é com quem o usa (`visible`).
## RODAS POR RODA (LW-099f, EXPERIMENTAL, só apresentação; o interruptor `set_wheel_differential` nasce DESLIGADO e, desligado, nada muda): ligado, cada roda gira pelo deslocamento do PRÓPRIO
## centro entre as duas poses, projetado na frente do corpo na pose média; em reta as duas giram como sempre e em curva a roda de fora gira mais que a de dentro (cinemática do corpo rígido).
## Os números são [HIP] PROVISÓRIOS, a afinar na janela de Arthur. Contrato: docs/economia/contrato-lw-099-viagem-visivel.md, seção 2.

## Nomes dos nós.
const MERCHANT_NAME: String = "Merchant"
const CART_NAME: String = "Cart"
const CARGO_NAME: String = "Cargo"
const BED_NAME: String = "Bed"
const SHAFT_NAMES: PackedStringArray = ["ShaftLeft", "ShaftRight"]
const WHEEL_NAMES: PackedStringArray = ["WheelLeft", "WheelRight"]
const TIRE_NAME: String = "Tire"
const SPOKE_NAME: String = "Spoke"
const VOLUME_PREFIX: String = "Volume"
## Lado de cada peça par (esquerda, direita), em x local: a direita de quem anda para -Z é +X.
const SIDES: PackedFloat32Array = [-1.0, 1.0]

## Carrinho [HIP] (m): o leito fica CART_BACK_M atrás dos pés do comerciante; as rodas tocam o chão (centro à altura do raio) e giram em torno do eixo X;
## as varas saem da frente do leito e param ao lado do comerciante.
const CART_BACK_M: float = 2.1
const BED_SIZE_M: Vector3 = Vector3(1.0, 0.14, 1.6)
const BED_CENTER_HEIGHT_M: float = 0.49
const SHAFT_SIZE_M: Vector3 = Vector3(0.06, 0.06, 1.0)
const SHAFT_SIDE_M: float = 0.3
const SHAFT_HEIGHT_M: float = 0.62
const WHEEL_RADIUS_M: float = 0.38
const WHEEL_THICKNESS_M: float = 0.09
const WHEEL_SIDE_M: float = 0.56
const WHEEL_SEGMENTS: int = 10
## O raio (a barra que cruza a roda) existe para a volta aparecer: um cilindro liso girando não se distingue de um parado.
const SPOKE_SIZE_M: Vector3 = Vector3(0.13, 0.7, 0.06)
const BED_COLOR: Color = Color(0.52, 0.38, 0.24)
const SHAFT_COLOR: Color = Color(0.40, 0.29, 0.18)
const TIRE_COLOR: Color = Color(0.24, 0.20, 0.16)
const SPOKE_COLOR: Color = Color(0.66, 0.54, 0.38)
const QUARTER_TURN: float = PI / 2.0
const HALF: float = 0.5

## Carga [HIP]: até 3 volumes lado a lado no leito, escolhidos pela faixa do peso do lote (a contagem exata não se vê).
const MAX_VOLUMES: int = 3
const ONE_VOLUME_MAX_PERMILLE: int = 333
const TWO_VOLUMES_MAX_PERMILLE: int = 666
const VOLUME_SPACING_M: float = 0.5
const VOLUME_SEGMENTS: int = 8
## Bem sem entrada na tabela (id desconhecido): um volume NEUTRO, caixa cinza. A caravana ESTÁ carregada; sumir com o volume mostraria um carrinho vazio.
const NEUTRAL_SHAPE: String = "box"
const NEUTRAL_COLOR: Color = Color(0.5, 0.5, 0.5)
const SHAPE_BOX: String = "box"
const SHAPE_SACK: String = "sack"
const SHAPE_BARREL: String = "barrel"
const SHAPE_BUNDLE: String = "bundle"
const BOX_SIZE_M: Vector3 = Vector3(0.7, 0.4, 0.45)
## Saco: tronco de cone (raio do topo, raio da base) e altura; barril: cilindro; feixe (tora, tábuas ou rolo de pano): cilindro DEITADO sobre a largura do leito.
const SACK_RADII_M: Vector2 = Vector2(0.12, 0.24)
const SACK_HEIGHT_M: float = 0.5
const BARREL_RADIUS_M: float = 0.24
const BARREL_HEIGHT_M: float = 0.55
const BUNDLE_RADIUS_M: float = 0.17
const BUNDLE_LENGTH_M: float = 0.9

## Comerciante (caravana) a que o corpo está ligado (IdGenerator.NO_ID = livre, esperando na reserva).
var trader_id: int = IdGenerator.NO_ID

var _routes: CaravanRoutesReader
var _merchant: NpcView
var _wheels: Array[Node3D] = []
var _volumes: Array[MeshInstance3D] = []
var _cargo_material: StandardMaterial3D
var _shapes: Dictionary[String, VolumeShape] = {}
var _travelling: bool = false
var _volume_count: int = 0
var _good_id: String = ""
var _has_pose: bool = false
var _last_position: Vector3 = Vector3.ZERO
var _last_yaw: float = 0.0
var _last_pitch: float = 0.0
## Interruptor RODAS POR RODA (LW-099f, experimental; ver `set_wheel_differential`): falso (o padrão), as duas rodas giram juntas, a distância da origem ÷ raio; verdadeiro, cada uma pelo deslocamento do próprio centro.
var _wheel_differential: bool = false
## Ângulo de CADA roda (na ordem de `WHEEL_NAMES`) em torno de X (rad, de 0 a TAU): rolar para a frente (-Z) gira no sentido negativo de X, então o ângulo diminui com o deslocamento.
## O estado é por roda nos dois modos (desligado, as duas recebem o mesmo passo: a conta de sempre), então trocar de modo no meio da viagem não dá salto.
var _wheel_angles: PackedFloat64Array = PackedFloat64Array()


## `routes` é o dado de apresentação (a tabela de cor e forma da carga); este corpo só o lê.
func _init(routes: CaravanRoutesReader) -> void:
	# Sem dado (nulo) a tabela é a vazia: todo bem vira o volume neutro, sem quebrar.
	_routes = routes if routes != null else CaravanRoutesReader.new()
	visible = false
	_merchant = NpcView.new()
	_merchant.name = MERCHANT_NAME
	add_child(_merchant)
	_build_cart()
	_build_cargo()
	_refresh_cargo()


## O `NpcView` religa o próprio `_process` (tempo real) ao entrar na árvore já andando; aqui a pisada só anda com o deslocamento. Os filhos entram antes do pai,
## então este desligar vem depois do dele.
func _ready() -> void:
	_merchant.set_process(false)


## Quantos volumes a faixa do peso do lote mostra: 0 = nenhum; até 333 um; até 666 dois; acima, três. Fora de 0 a 1000 vale o extremo mais próximo.
static func volumes_for(load_permille: int) -> int:
	if load_permille <= 0:
		return 0
	if load_permille <= ONE_VOLUME_MAX_PERMILLE:
		return 1
	if load_permille <= TWO_VOLUMES_MAX_PERMILLE:
		return 2
	return MAX_VOLUMES


## Liga o corpo à caravana do comerciante `new_trader_id`, do zero (sem pose, parado, sem carga) e ainda escondido até a primeira pose. ID inválido: erro visível e nada muda.
func bind(new_trader_id: int) -> void:
	if new_trader_id <= IdGenerator.NO_ID:
		push_error("CaravanView.bind: comerciante %d inválido; esperado um ID maior que %d." % [new_trader_id, IdGenerator.NO_ID])
		return
	release()
	trader_id = new_trader_id


## Solta a caravana: o corpo some e volta ao estado de novo (nada é apagado), pronto para a reserva. O corpo reciclado não herda pose, rodas, carga nem pisada. O interruptor RODAS POR RODA é configuração (não estado): fica como está.
func release() -> void:
	trader_id = IdGenerator.NO_ID
	visible = false
	position = Vector3.ZERO
	rotation = Vector3.ZERO
	_has_pose = false
	_travelling = false
	_set_merchant_walking(false)
	_wheel_angles.fill(0.0)
	for wheel: Node3D in _wheels:
		wheel.rotation = Vector3.ZERO
	_good_id = ""
	_volume_count = 0
	_refresh_cargo()


func is_bound() -> bool:
	return trader_id != IdGenerator.NO_ID


## O corpo do comerciante (o `NpcView` filho, que não é da reserva de NPCs): é por onde uma figura entraria, e os testes o inspecionam.
func merchant() -> NpcView:
	return _merchant


## Quantos volumes de carga estão à mostra agora (0 a MAX_VOLUMES).
func volume_count() -> int:
	return _volume_count


## Liga ou desliga o modo RODAS POR RODA (LW-099f, EXPERIMENTAL; nasce DESLIGADO): ligado, cada roda gira pelo deslocamento do PRÓPRIO centro, projetado na frente do corpo na pose média (em reta é igual ao
## desligado; em curva a roda de fora gira mais que a de dentro); desligado, as duas giram juntas pela distância da origem, como sempre. Trocar o modo não gira nada por si e não precisa de pose: vale da próxima
## pose em diante, e cada roda continua do ângulo em que está (sem salto). O `release` não o desliga: é configuração do corpo, não estado da caravana.
func set_wheel_differential(enabled: bool) -> void:
	_wheel_differential = enabled


## Se o modo RODAS POR RODA está ligado (padrão: falso).
func wheel_differential() -> bool:
	return _wheel_differential


## Põe o corpo na pose pedida: pés do comerciante em `ground_position` (metros, mundo), giro `yaw` (rad, em torno de Y; a frente é -Z local) e inclinação `pitch`
## (rad, em torno de X; positiva = frente mais alta). A primeira pose depois de `bind` mostra o corpo e não anima (não há "quadro anterior"); as seguintes giram as
## rodas e movem a pisada pela distância andada, mas só com a caravana andando (`apply_state`). A mesma pose de novo não faz nada. Valor não finito, ou corpo livre: ignorado.
## Com o modo RODAS POR RODA ligado, cada roda gira pelo deslocamento do próprio centro (`_roll_by_wheel`); a pisada segue a distância da origem nos dois modos.
func apply_pose(ground_position: Vector3, yaw: float, pitch: float) -> void:
	if not is_bound() or not ground_position.is_finite() or not is_finite(yaw) or not is_finite(pitch):
		return
	if _has_pose and ground_position == _last_position and yaw == _last_yaw and pitch == _last_pitch:
		return
	if _has_pose and _travelling:
		if _wheel_differential:
			_roll_by_wheel(ground_position, yaw, pitch)
		else:
			_roll(_last_position.distance_to(ground_position))
	_last_position = ground_position
	_last_yaw = yaw
	_last_pitch = pitch
	position = ground_position
	rotation = Vector3(pitch, yaw, 0.0)
	if not _has_pose:
		_has_pose = true
		visible = true


## Põe o corpo no estado da caravana: `travelling` falso (rota fechada, parada no meio do trecho) para o comerciante e as rodas; `good_id` e `load_permille` (0 a 1000, o
## peso do lote sobre a capacidade) escolhem a cor, a forma e quantos volumes se veem. O mesmo estado de novo não faz nada. Corpo livre: ignorado.
func apply_state(travelling: bool, good_id: String, load_permille: int) -> void:
	if not is_bound():
		return
	if travelling != _travelling:
		_travelling = travelling
		_set_merchant_walking(travelling)
	var count: int = volumes_for(load_permille)
	if count == _volume_count and (count == 0 or good_id == _good_id):
		return
	_good_id = good_id
	_volume_count = count
	_refresh_cargo()


## Gira as duas rodas juntas (distância ÷ raio, para a frente) e adianta a pisada do comerciante pelo tempo que o NPC levaria para andar essa distância (a cadência do `NpcView` é a de 4 m/s).
func _roll(step_m: float) -> void:
	if step_m <= 0.0:
		return
	for index: int in _wheels.size():
		_turn_wheel(index, step_m / WHEEL_RADIUS_M)
	_merchant.advance_animation(step_m / NpcRoute.WALK_SPEED_MPS)


## RODAS POR RODA: gira cada roda pelo deslocamento do PRÓPRIO centro entre a pose anterior e a nova (no mundo, em 3D), projetado na frente do corpo na pose MÉDIA (a média dos giros por `angle_difference`
## e a das inclinações; a ordem de Euler é a do `rotation` do nó). O centro da roda no referencial do corpo é (lado × WHEEL_SIDE_M, WHEEL_RADIUS_M, CART_BACK_M). O deslocamento é o da origem mais o quanto o
## centro se moveu por causa do giro do corpo (a diferença das duas bases: não se subtraem duas posições grandes do mundo, onde o float de 32 bits perderia precisão). Em reta, com giro e inclinação constantes,
## dá a distância da origem, como `_roll`; em curva a roda de fora anda mais que a de dentro. A origem no mesmo lugar (mesmo que o giro mude) não rola nem pisa; a pisada é a de `_roll` (distância da ORIGEM).
func _roll_by_wheel(to_position: Vector3, to_yaw: float, to_pitch: float) -> void:
	var step_m: float = _last_position.distance_to(to_position)
	if step_m <= 0.0:
		return
	var from_basis: Basis = Basis.from_euler(Vector3(_last_pitch, _last_yaw, 0.0))
	var to_basis: Basis = Basis.from_euler(Vector3(to_pitch, to_yaw, 0.0))
	var mean_yaw: float = _last_yaw + angle_difference(_last_yaw, to_yaw) * HALF
	var front: Vector3 = Basis.from_euler(Vector3((_last_pitch + to_pitch) * HALF, mean_yaw, 0.0)) * Vector3.FORWARD
	var travel: Vector3 = to_position - _last_position
	for index: int in _wheels.size():
		var centre: Vector3 = Vector3(SIDES[index] * WHEEL_SIDE_M, WHEEL_RADIUS_M, CART_BACK_M)
		_turn_wheel(index, (travel + (to_basis * centre - from_basis * centre)).dot(front) / WHEEL_RADIUS_M)
	_merchant.advance_animation(step_m / NpcRoute.WALK_SPEED_MPS)


## Gira a roda `index` por `turn_rad` para a frente (o ângulo diminui, sempre dentro de uma volta), no estado e no pivô.
func _turn_wheel(index: int, turn_rad: float) -> void:
	_wheel_angles[index] = fposmod(_wheel_angles[index] - turn_rad, TAU)
	_wheels[index].rotation.x = _wheel_angles[index]


## Liga ou desliga o andar do comerciante sem o `_process` do `NpcView` (que andaria em tempo real, e em pausa também): `set_walking` o religa ao começar a andar.
func _set_merchant_walking(walking: bool) -> void:
	_merchant.set_walking(walking)
	_merchant.set_process(false)


## Mostra os `_volume_count` primeiros volumes do bem `_good_id`, repartidos de modo equilibrado ao longo do leito.
func _refresh_cargo() -> void:
	var shape: String = _routes.cargo_shape(_good_id)
	var known: bool = not shape.is_empty()
	_cargo_material.albedo_color = _routes.cargo_color(_good_id) if known else NEUTRAL_COLOR
	var look: VolumeShape = _shapes.get(shape if known else NEUTRAL_SHAPE, _shapes[NEUTRAL_SHAPE]) as VolumeShape
	for index: int in MAX_VOLUMES:
		var volume: MeshInstance3D = _volumes[index]
		volume.visible = index < _volume_count
		volume.mesh = look.mesh
		volume.position = Vector3(0.0, look.lift_m, (float(index) - float(_volume_count - 1) * HALF) * VOLUME_SPACING_M)
		volume.rotation = Vector3(0.0, 0.0, look.roll_rad)


func _build_cart() -> void:
	var cart: Node3D = Node3D.new()
	cart.name = CART_NAME
	cart.position = Vector3(0.0, 0.0, CART_BACK_M)
	add_child(cart)
	var bed: BoxMesh = BoxMesh.new()
	bed.size = BED_SIZE_M
	cart.add_child(_new_part(BED_NAME, bed, _new_material(BED_COLOR), Vector3(0.0, BED_CENTER_HEIGHT_M, 0.0)))
	var shaft_z_m: float = -(BED_SIZE_M.z + SHAFT_SIZE_M.z) * HALF
	for side: int in SIDES.size():
		var shaft: BoxMesh = BoxMesh.new()
		shaft.size = SHAFT_SIZE_M
		cart.add_child(_new_part(SHAFT_NAMES[side], shaft, _new_material(SHAFT_COLOR), Vector3(SIDES[side] * SHAFT_SIDE_M, SHAFT_HEIGHT_M, shaft_z_m)))
		var wheel: Node3D = _new_wheel(WHEEL_NAMES[side], Vector3(SIDES[side] * WHEEL_SIDE_M, WHEEL_RADIUS_M, 0.0))
		cart.add_child(wheel)
		_wheels.append(wheel)
		_wheel_angles.append(0.0)


## A roda: o pivô (que gira em X) com o pneu (cilindro deitado, eixo X) e o raio (a barra que mostra a volta).
func _new_wheel(wheel_name: String, at: Vector3) -> Node3D:
	var pivot: Node3D = Node3D.new()
	pivot.name = wheel_name
	pivot.position = at
	var tire: CylinderMesh = CylinderMesh.new()
	tire.top_radius = WHEEL_RADIUS_M
	tire.bottom_radius = WHEEL_RADIUS_M
	tire.height = WHEEL_THICKNESS_M
	tire.radial_segments = WHEEL_SEGMENTS
	tire.rings = 1
	var tire_part: MeshInstance3D = _new_part(TIRE_NAME, tire, _new_material(TIRE_COLOR), Vector3.ZERO)
	tire_part.rotation = Vector3(0.0, 0.0, QUARTER_TURN)
	pivot.add_child(tire_part)
	var spoke: BoxMesh = BoxMesh.new()
	spoke.size = SPOKE_SIZE_M
	pivot.add_child(_new_part(SPOKE_NAME, spoke, _new_material(SPOKE_COLOR), Vector3.ZERO))
	return pivot


## A carga: um material só (o carrinho leva UM bem), as quatro formas prontas e três lugares no leito; trocar de bem ou de faixa só troca malha, cor e visibilidade.
func _build_cargo() -> void:
	var cargo: Node3D = Node3D.new()
	cargo.name = CARGO_NAME
	cargo.position = Vector3(0.0, BED_CENTER_HEIGHT_M + BED_SIZE_M.y * HALF, CART_BACK_M)
	add_child(cargo)
	_cargo_material = _new_material(NEUTRAL_COLOR)
	for shape: String in CaravanRoutesReader.SHAPES:
		_shapes[shape] = VolumeShape.build(shape, _cargo_material)
	if not _shapes.has(NEUTRAL_SHAPE):
		_shapes[NEUTRAL_SHAPE] = VolumeShape.build(NEUTRAL_SHAPE, _cargo_material)
	for index: int in MAX_VOLUMES:
		var volume: MeshInstance3D = MeshInstance3D.new()
		volume.name = "%s%d" % [VOLUME_PREFIX, index]
		volume.visible = false
		cargo.add_child(volume)
		_volumes.append(volume)


static func _new_material(color: Color) -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = color
	return material


static func _new_part(part_name: String, mesh: PrimitiveMesh, material: Material, at: Vector3) -> MeshInstance3D:
	mesh.material = material
	var part: MeshInstance3D = MeshInstance3D.new()
	part.name = part_name
	part.mesh = mesh
	part.position = at
	return part


## Uma forma de volume: a malha (com o material da carga), metade da altura (o volume apoia no leito) e o giro em Z (o cilindro do feixe nasce em pé e é deitado).
class VolumeShape:
	extends RefCounted

	var mesh: PrimitiveMesh
	var lift_m: float = 0.0
	var roll_rad: float = 0.0

	## A forma `shape` (uma de `CaravanRoutesReader.SHAPES`); qualquer outra sai como caixa.
	static func build(shape: String, material: Material) -> VolumeShape:
		var built: VolumeShape = VolumeShape.new()
		match shape:
			SHAPE_SACK:
				built.mesh = _cylinder(SACK_RADII_M.x, SACK_RADII_M.y, SACK_HEIGHT_M)
				built.lift_m = SACK_HEIGHT_M * HALF
			SHAPE_BARREL:
				built.mesh = _cylinder(BARREL_RADIUS_M, BARREL_RADIUS_M, BARREL_HEIGHT_M)
				built.lift_m = BARREL_HEIGHT_M * HALF
			SHAPE_BUNDLE:
				built.mesh = _cylinder(BUNDLE_RADIUS_M, BUNDLE_RADIUS_M, BUNDLE_LENGTH_M)
				built.lift_m = BUNDLE_RADIUS_M
				built.roll_rad = QUARTER_TURN
			_:
				var box: BoxMesh = BoxMesh.new()
				box.size = BOX_SIZE_M
				built.mesh = box
				built.lift_m = BOX_SIZE_M.y * HALF
		built.mesh.material = material
		return built

	static func _cylinder(top_radius: float, bottom_radius: float, height: float) -> CylinderMesh:
		var cylinder: CylinderMesh = CylinderMesh.new()
		cylinder.top_radius = top_radius
		cylinder.bottom_radius = bottom_radius
		cylinder.height = height
		cylinder.radial_segments = VOLUME_SEGMENTS
		cylinder.rings = 1
		return cylinder
