class_name ScriptedCaravanBridge
extends SimBridge
## Ponte de teste da vista das caravanas (LW-099b2b): `peek_caravan_bodies` devolve as linhas que o teste pôs em `rows` (ou falha, com `is_failing`), e a altura do terreno pode ser uma RAMPA (`slope_x`); o resto (formato do terreno,
## locais e mercados) é da ponte real, sobre os dados reais. Sem jogo nem host: a ponte real do jogo é montada em `tests/integration/test_caravan_bodies_in_game.gd`.

var rows: Array[BridgeReplies.CaravanBodyReply] = []
var is_failing: bool = false
## Subida do terreno em x (m de altura por m), somada aos 10 m do chão real; zero deixa o chão como está.
var slope_x: float = 0.0
## Com ele ligado a altura do terreno não pode ser lida (a resposta falha).
var is_blind: bool = false


## Uma linha de `peek_caravan_bodies` de um trecho (de `from_id` para `to_id`, no sentido da marcha) com uma carga de grão de 400 milésimos.
static func row_of(trader_id: int, u: float, route_id: String, from_id: String, to_id: String, state: String = BridgeReplies.CaravanBodyReply.STATE_TRAVELLING) -> BridgeReplies.CaravanBodyReply:
	var row: BridgeReplies.CaravanBodyReply = BridgeReplies.CaravanBodyReply.new()
	row.trader_id = trader_id
	row.route_id = route_id
	row.from_settlement_id = from_id
	row.to_settlement_id = to_id
	row.state = state
	row.u = u
	row.good_id = "grain"
	row.quantity = 12
	row.load_permille = 400
	return row


func peek_caravan_bodies() -> BridgeReplies.CaravanBodiesReply:
	if is_failing:
		return BridgeReplies.CaravanBodiesReply.new(Result.failure("TEST_BRIDGE_DOWN", "ponte de teste fora do ar."), [])
	return BridgeReplies.CaravanBodiesReply.new(Result.success(), rows)


func peek_height(x: float, z: float) -> BridgeReplies.HeightReply:
	if is_blind:
		return BridgeReplies.HeightReply.new(Result.failure("TEST_NO_GROUND", "ponte de teste sem terreno."), 0.0)
	var ground: BridgeReplies.HeightReply = super(x, z)
	if ground.result.ok:
		ground.height_m += slope_x * x
	return ground
