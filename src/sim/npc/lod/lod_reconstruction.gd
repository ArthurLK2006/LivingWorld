class_name LodReconstruction
extends RefCounted
## Reconstrução da posição de um NPC ao entrar em S0 (LW-069; contrato em docs/modules/npc.md, seção 6): o corpo nasce COERENTE com a
## ação e a hora: parado no local, ou em trânsito interpolado entre a origem do trecho e o destino. Função pura, só inteiros (centímetros
## e minutos de simulação): mesma entrada, mesma posição. Não conhece o `world`: quem chama entrega o destino já em centímetros.

## Destino desconhecido (coordenadas válidas nunca são negativas).
const NO_POSITION: Vector2i = Vector2i(-1, -1)
## Teto [HIP] de um trecho em minutos: com o desvio máximo de 10.000.000 cm, a conta fica abaixo de 2^53 e continua exata.
const MAX_LEG_MINUTES: int = 100000000


## Em trânsito: tem ação com local de destino e ainda não está nele (o local atual é vazio ou outro). O estado só guarda a origem do
## trecho (a posição lógica) e o destino (`action_target_place_id`); a posição no meio do caminho é sempre derivada da hora.
static func is_in_transit(state: NpcState) -> bool:
	return not state.action_id.is_empty() and not state.action_target_place_id.is_empty() and state.place_id != state.action_target_place_id


## Posição (cm) do NPC em `now_minutes`. Parado (sem ação, ou já no local da ação): a posição lógica. Em trânsito: interpola entre a
## posição lógica (origem) e `destination_cm`, de `leg_start_minute` até o fim da ação; antes do começo vale a origem, a partir do fim
## vale o destino. Destino desconhecido (`NO_POSITION`) ou trecho absurdo: a posição lógica, sem inventar caminho.
static func position_at(state: NpcState, now_minutes: int, destination_cm: Vector2i, leg_start_minute: int) -> Vector2i:
	var origin: Vector2i = Vector2i(state.x_cm, state.z_cm)
	if not is_in_transit(state) or destination_cm == NO_POSITION:
		return origin
	var total: int = state.action_ends_at - leg_start_minute
	if total > MAX_LEG_MINUTES:
		return origin
	if total <= 0 or now_minutes >= state.action_ends_at:
		return destination_cm
	var elapsed: int = clampi(now_minutes - leg_start_minute, 0, total)
	return Vector2i(origin.x + IntMath.floor_div((destination_cm.x - origin.x) * elapsed, total), origin.y + IntMath.floor_div((destination_cm.y - origin.y) * elapsed, total))
