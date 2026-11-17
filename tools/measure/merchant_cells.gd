class_name MerchantCells
extends RefCounted
## As colunas de comerciantes do `tools/measure_economy` (LW-098h4; docs/modules/economy.md, 9.15.5). Só LÊ: não cria comerciante, não muda estado.
## Comerciante é o NPC VIVO com o ofício `merchant` (o de `data/occupations.json` cujo `owner_kind` é `merchant`, LW-098f1). As seis células, na ordem de `COLUMNS`:
## `merchants_alive` (vivos); `merchants_travelling` e `merchants_held` (os vivos cuja caravana está em `travelling` ou em `held`, a parada por rota fechada; contas
## SEPARADAS: quem está `held` não entra em viagem); `merchants_trips` (viagens concluídas desde que a classe nasceu: um `CaravanArrived` cada; quem morre na estrada
## não conta); `merchants_profit` (a soma do lucro realizado, `max(0, revenue - cost_paid)` de cada chegada, a mesma conta do `npc`, `MerchantArrival`); `merchants_hunger_max`
## (a maior fome, de 0 a 100, entre os vivos: o valor do último pensamento, com no máximo `think_interval_min` minutos de idade). Sem comerciante todas valem 0.
## Viagens e lucro são ACUMULADOS pela assinatura do `CaravanArrived`: a classe tem de nascer antes do primeiro passo do jogo para ouvir tudo.

const OCCUPATION_ID: String = "merchant"
const HUNGER_ID: String = "hunger"
## Os nomes das colunas, na ordem de `row()`: o `measure_economy` os põe no FIM do cabeçalho.
const COLUMNS: Array[String] = ["merchants_alive", "merchants_travelling", "merchants_held", "merchants_trips", "merchants_profit", "merchants_hunger_max"]

var _npc: NpcModule
var _economy: EconomyModule
var _hunger_index: int
var _trips: int = 0
var _profit: int = 0


## `events`: o barramento do mundo (`world.context.events`), onde a classe assina o `CaravanArrived`.
func _init(npc: NpcModule, economy: EconomyModule, events: EventBus) -> void:
	_npc = npc
	_economy = economy
	_hunger_index = npc.peek_need_ids().find(HUNGER_ID)
	events.subscribe(NpcModule.CARAVAN_ARRIVED_EVENT_TYPE, _on_caravan_arrived)


## As seis células de agora, na ordem de `COLUMNS`.
func row() -> PackedStringArray:
	var alive: int = 0
	var travelling: int = 0
	var held: int = 0
	var hunger_max: int = 0
	for npc_id: int in _npc.peek_npc_ids():
		var query: NpcModule.NpcQuery = _npc.peek_npc(npc_id)
		if not query.is_alive or query.occupation_id != OCCUPATION_ID:
			continue
		alive += 1
		var caravan_state: String = _economy.peek_caravan(npc_id).state
		travelling += int(caravan_state == Caravan.STATE_TRAVELLING)
		held += int(caravan_state == Caravan.STATE_HELD)
		if _hunger_index >= 0:
			hunger_max = maxi(hunger_max, query.need_values[_hunger_index])
	return PackedStringArray([str(alive), str(travelling), str(held), str(_trips), str(_profit), str(hunger_max)])


func _on_caravan_arrived(event: SimEvent) -> void:
	var arrived: CaravanArrived = event as CaravanArrived
	if arrived == null:
		return
	_trips += 1
	_profit += maxi(0, arrived.revenue - arrived.cost_paid)
