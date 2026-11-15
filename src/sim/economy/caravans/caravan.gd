class_name Caravan
extends RefCounted
## O registro de um comerciante em viagem (LW-098c; docs/modules/economy.md, 9.3 e 9.4): UM por comerciante, chave = `trader_id` (o `owner_id` do dono do tipo `merchant`; sem ID novo), sem registro = parado. Guarda só o que a viagem tem de seu: o estado
## (`travelling` ou `held`), os mercados de origem e de destino, as rotas do caminho e o trecho atual (`leg_index`, `leg_started_at`, `leg_minutes`, `elapsed_at_hold`), o bem e o lote planejados (`good_id`, `quantity`), o que o lote custou (`cost_paid`: informação, fora
## da soma) e a saída (`departed_at`). A CARGA é o inventário do próprio comerciante (não é copiada para cá) e a posição é DERIVADA do relógio (não é salva). Tempo em minutos de simulação. Os campos são só dado: as regras (partida, chegada, parada, retomada e desvio) estão no
## `CaravanRunner` (LW-098d e LW-098e; a parada num povoado é `held` com `elapsed_at_hold` 0 e `leg_index` no trecho ainda não andado), e as invariantes estão em `CaravanBook.validate`.

const STATE_TRAVELLING: String = "travelling"
const STATE_HELD: String = "held"
const STATES: Array[String] = [STATE_TRAVELLING, STATE_HELD]
const KEY_TRADER: String = "trader_id"
const KEY_STATE: String = "state"
const KEY_ORIGIN: String = "origin_market_id"
const KEY_DESTINATION: String = "destination_market_id"
const KEY_ROUTES: String = "route_ids"
const KEY_LEG: String = "leg_index"
const KEY_LEG_STARTED: String = "leg_started_at"
const KEY_LEG_MINUTES: String = "leg_minutes"
const KEY_ELAPSED: String = "elapsed_at_hold"
const KEY_GOOD: String = "good_id"
const KEY_QUANTITY: String = "quantity"
const KEY_COST: String = "cost_paid"
const KEY_DEPARTED: String = "departed_at"
## Os campos inteiros e os de texto do registro salvo (`route_ids` é uma lista de textos): o livro confere os tipos com eles ao carregar.
const INT_KEYS: Array[String] = [KEY_TRADER, KEY_ORIGIN, KEY_DESTINATION, KEY_LEG, KEY_LEG_STARTED, KEY_LEG_MINUTES, KEY_ELAPSED, KEY_QUANTITY, KEY_COST, KEY_DEPARTED]
const TEXT_KEYS: Array[String] = [KEY_STATE, KEY_GOOD]

var trader_id: int = IdGenerator.NO_ID
var state: String = STATE_TRAVELLING
var origin_market_id: int = IdGenerator.NO_ID
var destination_market_id: int = IdGenerator.NO_ID
var route_ids: Array[String] = []
var leg_index: int = 0
var leg_started_at: int = 0
var leg_minutes: int = 0
var elapsed_at_hold: int = 0
var good_id: String = ""
var quantity: int = 0
var cost_paid: int = 0
var departed_at: int = 0


## O registro no formato do save (os campos de 9.3); a lista de rotas é uma cópia.
func serialize() -> Dictionary:
	return {KEY_TRADER: trader_id, KEY_STATE: state, KEY_ORIGIN: origin_market_id, KEY_DESTINATION: destination_market_id, KEY_ROUTES: route_ids.duplicate(), KEY_LEG: leg_index, KEY_LEG_STARTED: leg_started_at, KEY_LEG_MINUTES: leg_minutes, KEY_ELAPSED: elapsed_at_hold, KEY_GOOD: good_id, KEY_QUANTITY: quantity, KEY_COST: cost_paid, KEY_DEPARTED: departed_at}


## Monta o registro de um `record` com os tipos já conferidos (o livro os confere ao carregar): número de JSON (decimal sem fração) vira inteiro.
static func from_record(record: Dictionary) -> Caravan:
	var caravan: Caravan = Caravan.new()
	caravan.trader_id = EconomyJson.to_int(record[KEY_TRADER])
	caravan.state = str(record[KEY_STATE])
	caravan.origin_market_id = EconomyJson.to_int(record[KEY_ORIGIN])
	caravan.destination_market_id = EconomyJson.to_int(record[KEY_DESTINATION])
	caravan.route_ids.assign(record[KEY_ROUTES])
	caravan.leg_index = EconomyJson.to_int(record[KEY_LEG])
	caravan.leg_started_at = EconomyJson.to_int(record[KEY_LEG_STARTED])
	caravan.leg_minutes = EconomyJson.to_int(record[KEY_LEG_MINUTES])
	caravan.elapsed_at_hold = EconomyJson.to_int(record[KEY_ELAPSED])
	caravan.good_id = str(record[KEY_GOOD])
	caravan.quantity = EconomyJson.to_int(record[KEY_QUANTITY])
	caravan.cost_paid = EconomyJson.to_int(record[KEY_COST])
	caravan.departed_at = EconomyJson.to_int(record[KEY_DEPARTED])
	return caravan


func copy() -> Caravan:
	return Caravan.from_record(serialize())


## A rota do trecho atual (texto vazio se `leg_index` não aponta para nenhuma rota da lista).
func current_route_id() -> String:
	return route_ids[leg_index] if leg_index >= 0 and leg_index < route_ids.size() else ""


## Na estrada: andando, ou parada no MEIO do trecho (`held` com `elapsed_at_hold` maior que 0); a parada num povoado (`elapsed_at_hold` 0) não está na estrada (9.8).
func is_on_road() -> bool:
	return state == STATE_TRAVELLING or elapsed_at_hold > 0
