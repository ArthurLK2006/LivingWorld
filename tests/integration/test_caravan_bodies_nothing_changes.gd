extends GutTest
## LW-099b1: NADA MUDA (contrato da LW-099, seções 5 e 6; AGENTS 9): as consultas novas (`peek_caravans`, os campos `leg_minutes` e `leg_walked_min`, `peek_caravan_bodies` e a fração de passo do relógio) só LEEM. Com elas chamadas a cada quadro, a viagem de dois trechos (A-B fechada: A-C e C-B, 220 minutos) com a economia
## conferida a cada 1, 7, 60 e 180 minutos dá o MESMO `state_hash` e o mesmo save de uma execução sem chamá-las; salvar e carregar no meio da viagem (andando e parada) devolve as mesmas caravanas e o mesmo `u` (a fração de passo volta a 0 e o corpo reaparece até 1 passo atrás, nunca à frente); o save não ganha chave.
## O jogo anda por QUADROS de 100 ms (`advance_frame`), então a fração de passo assume muitos valores. Economia e `world` REAIS pelo `CaravanRig`.

const TRADER: int = 100
const START: int = CaravanRig.START_MINUTE
const END: int = START + 300
const FRAME_MS: int = 100
const CADENCES: Array[int] = [1, 7, 60, 180]
## As 13 chaves do registro salvo da caravana (docs/modules/economy.md, 9.3), em ordem alfabética: nenhuma a mais por causa das consultas novas.
const SAVED_KEYS: Array[String] = ["cost_paid", "departed_at", "destination_market_id", "elapsed_at_hold", "good_id", "leg_index", "leg_minutes", "leg_started_at", "origin_market_id", "quantity", "route_ids", "state", "trader_id"]

var _routes: RouteService
var _rigs: Array[CaravanRig] = []


func before_all() -> void:
	_routes = CaravanRig.load_routes()


func after_each() -> void:
	for rig: CaravanRig in _rigs:
		rig.release()
	_rigs.clear()


func _rig(cadence: int = 1) -> CaravanRig:
	var rig: CaravanRig = CaravanRig.build(_routes, cadence)
	rig.start_new_game([TRADER] as Array[int])
	_rigs.append(rig)
	return rig


## O comerciante parte do A ao B com a A-B fechada (A-C e C-B).
func _depart(rig: CaravanRig) -> void:
	rig.set_route(CaravanRig.A_B, false)
	assert_true(rig.depart(TRADER, rig.market_a, rig.market_b).result.ok)


## Todas as consultas novas de uma vez; devolve quantos corpos a ponte listou.
func _query(rig: CaravanRig) -> int:
	rig.module.peek_caravans()
	rig.module.peek_caravan(TRADER)
	rig.clock().step_fraction()
	return rig.bridge.peek_caravan_bodies().bodies.size()


## A viagem até o minuto `END`, em quadros de 100 ms; `watch`: com as consultas a cada quadro. Devolve o hash do estado, o save da economia e quantos corpos as consultas viram.
func _trip(cadence: int, watch: bool) -> Array:
	var rig: CaravanRig = _rig(cadence)
	_depart(rig)
	var seen: int = 0
	while rig.clock().total_minutes() < END:
		rig.runner.advance_frame(FRAME_MS)
		if watch:
			seen += _query(rig)
	return [rig.runner.world.state_hash(), JSON.stringify(rig.module.serialize(), "", true, true), seen]


func test_the_queries_change_neither_the_state_hash_nor_the_save_whatever_the_step() -> void:
	var finals: Array = []
	for cadence: int in CADENCES:
		var silent: Array = _trip(cadence, false)
		var watched: Array = _trip(cadence, true)
		assert_eq(watched.slice(0, 2), silent.slice(0, 2), "Passo de %d minutos: o mesmo hash e o mesmo save com e sem as consultas." % cadence)
		assert_gt(watched[2], 0, "Passo de %d minutos: as consultas viram a caravana andando (não rodaram no vazio)." % cadence)
		finals.append(silent[0])
	assert_eq([finals[1], finals[2], finals[3]], [finals[0], finals[0], finals[0]], "Passos de 1, 7, 60 e 180 minutos: o mesmo hash do estado (a propriedade do `test_economy_caravan_trip.gd`, agora com o jogo andando por quadros).")


func test_saving_and_loading_mid_trip_returns_the_same_caravans_and_u_with_the_step_fraction_back_at_zero() -> void:
	for held: bool in [false, true]:
		for frame_ms: int in [0, 500]:
			var rig: CaravanRig = _rig()
			_depart(rig)
			rig.until(START + 60)
			if held:
				rig.set_route(CaravanRig.A_C, false)
			rig.runner.advance_frame(frame_ms)
			var label: String = "%s, fração de passo de %d ms" % ["parada" if held else "andando", frame_ms]
			var before_rows: Array = rig.module.peek_caravans().caravans.map(CaravanRig.fields_of)
			var before_u: float = rig.bridge.peek_caravan_bodies().bodies[0].u
			var loaded: CaravanRig = rig.reload()
			_rigs.append(loaded)
			assert_eq(loaded.runner.world.state_hash(), rig.runner.world.state_hash(), "%s: o estado carregado é idêntico (o mesmo hash)." % label)
			assert_eq(loaded.module.peek_caravans().caravans.map(CaravanRig.fields_of), before_rows, "%s: as mesmas caravanas, campo a campo (inclusive `leg_minutes` e `leg_walked_min`)." % label)
			assert_eq(loaded.clock().step_fraction(), 0.0, "%s: depois de carregar a fração de passo é 0." % label)
			var after_u: float = loaded.bridge.peek_caravan_bodies().bodies[0].u
			var lost: float = 0.0 if held else frame_ms / 1250.0 / 124.0
			assert_almost_eq(before_u - after_u, lost, 0.000000001, "%s: o corpo reaparece só sem a fração de passo (nunca à frente, e a menos de 1 passo atrás); parada, u é igual." % label)
			assert_eq(after_u, 60.0 / 124.0, "%s: u carregado = minutos andados ÷ duração do trecho, com f = 0." % label)


func test_the_save_gains_no_key_and_a_save_without_travellers_loads_with_no_bodies() -> void:
	var idle: CaravanRig = _rig()
	idle.until(START + 60)
	var loaded_idle: CaravanRig = idle.reload()
	_rigs.append(loaded_idle)
	assert_eq([loaded_idle.module.peek_caravans().caravans.size(), loaded_idle.bridge.peek_caravan_bodies().bodies.size()], [0, 0], "Um save sem ninguém em viagem (o formato de antes) carrega e não lista corpo.")
	var rig: CaravanRig = _rig()
	_depart(rig)
	rig.until(START + 60)
	var saved: Dictionary = rig.module.serialize()
	var added: Array = saved.keys().filter(func(key: String) -> bool: return not idle.module.serialize().has(key))
	assert_eq(added, ["caravans"], "Com a mesma hora e a viagem, a única chave a mais é a `caravans` de antes (LW-098c).")
	var record: Dictionary = saved["caravans"][0]
	var keys: Array = record.keys()
	keys.sort()
	assert_eq(keys, SAVED_KEYS, "O registro salvo da caravana tem as mesmas 13 chaves: os campos novos das consultas são derivados e não vão para o save.")
	assert_eq(rig.module.validate(), [] as Array[String])
