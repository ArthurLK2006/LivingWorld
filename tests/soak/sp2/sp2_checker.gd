class_name Sp2Checker
extends RefCounted
## LW-071 (SP2, DESCARTÁVEL): invariantes e detector de teleporte (pergunta P-a). Invariantes: (i) nenhum NPC com dois corpos; (ii) nenhum
## corpo sem NPC em S0 (órfão); (iii) corpos ativos == NPCs em S0 (NpcLod.s0_ids()); (iv) nascimento na posição lógica; (v) posição
## lógica na saída == último relato do corpo. Teleporte: salto entre dois quadros de física maior que velocidade máxima x delta x 1,5 +
## 5 cm, salvo o nascimento e a devolução declarados. Toda violação é contada e impressa com o instante (minuto de jogo) e o ID.

var duplicates: int = 0
var orphans: int = 0
var count_mismatches: int = 0
var spawn_mismatches: int = 0
var exit_mismatches: int = 0
var teleports: int = 0
var checks_run: int = 0
## Se false, não imprime (os testes contam sem poluir a saída).
var is_verbose: bool = true

var _last_seen: Dictionary[int, Vector3] = {}


func total_violations() -> int:
	return duplicates + orphans + count_mismatches + spawn_mismatches + exit_mismatches + teleports


## Nascimento declarado: confere (iv) e zera o detector de teleporte deste NPC.
func on_spawn(npc_id: int, body_at: Vector3, logical_cm: Vector2i, now: int) -> void:
	var logical_m: Vector2 = Vector2(logical_cm) / TerrainData.CM_PER_METER
	if Vector2(body_at.x, body_at.z).distance_to(logical_m) > Sp2Constants.POSITION_TOLERANCE_M:
		spawn_mismatches += 1
		_report(now, npc_id, "nasceu em %s, longe da posição lógica %s" % [str(body_at), str(logical_m)])
	_last_seen[npc_id] = body_at


## Devolução declarada: confere (v) e esquece o NPC no detector de teleporte.
func on_return(npc_id: int, body: Sp2Body, logical_cm: Vector2i, now: int) -> void:
	_last_seen.erase(npc_id)
	if not body.has_reported:
		return
	var logical_m: Vector2 = Vector2(logical_cm) / TerrainData.CM_PER_METER
	if Vector2(body.last_reported.x, body.last_reported.z).distance_to(logical_m) > Sp2Constants.POSITION_TOLERANCE_M:
		exit_mismatches += 1
		_report(now, npc_id, "saiu de S0 com posição lógica %s, diferente do último relato %s" % [str(logical_m), str(body.last_reported)])


## Corpo devolvido sem conferência (troca de mundo no ensaio de carga).
func forget(npc_id: int) -> void:
	_last_seen.erase(npc_id)


## Um quadro de física do corpo: acusa o salto acima do limite.
func on_moved(npc_id: int, at: Vector3, delta: float, max_speed_mps: float, now: int) -> void:
	if _last_seen.has(npc_id):
		var jump: float = Vector2(at.x, at.z).distance_to(Vector2(_last_seen[npc_id].x, _last_seen[npc_id].z))
		var limit: float = max_speed_mps * delta * Sp2Constants.TELEPORT_FACTOR + Sp2Constants.TELEPORT_SLACK_M
		if jump > limit:
			teleports += 1
			_report(now, npc_id, "teleporte de %.2f m num quadro (limite %.2f m)" % [jump, limit])
	_last_seen[npc_id] = at


## Invariantes (i) a (iii) contra o LOD do mundo e o pool. `bodies`: todos os corpos filhos do pai do pool.
func check(s0_ids: Array[int], pool: Sp2BodyPool, bodies: Array[Sp2Body], now: int) -> void:
	checks_run += 1
	var owners: Dictionary[int, int] = {}
	for body: Sp2Body in bodies:
		if body.npc_id != 0:
			owners[body.npc_id] = owners.get(body.npc_id, 0) + 1
	for npc_id: int in owners:
		if owners[npc_id] > 1:
			duplicates += 1
			_report(now, npc_id, "%d corpos ativos" % owners[npc_id])
	var in_s0: Dictionary[int, bool] = {}
	for npc_id: int in s0_ids:
		in_s0[npc_id] = true
	for npc_id: int in pool.active_ids():
		if not in_s0.has(npc_id):
			orphans += 1
			_report(now, npc_id, "corpo órfão (o NPC não está em S0)")
	if pool.active_count() != s0_ids.size():
		count_mismatches += 1
		_report(now, 0, "%d corpos ativos para %d NPCs em S0" % [pool.active_count(), s0_ids.size()])


func summary() -> String:
	return "duplicados %d, órfãos %d, contagem diferente %d, nascimento fora %d, saída fora %d, teleportes %d (conferências %d)" % [duplicates, orphans, count_mismatches, spawn_mismatches, exit_mismatches, teleports, checks_run]


func _report(now: int, npc_id: int, what: String) -> void:
	if is_verbose:
		print("SP2 VIOLAÇÃO minuto %d, NPC %d: %s" % [now, npc_id, what])
