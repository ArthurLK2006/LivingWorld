class_name InteractionTarget
extends RefCounted
## Quem a tecla `interact` alcança (LW-083e; decisão de Arthur, P4): o ponto de interesse OU o NPC mais perto, só entre os que estão DENTRO do alcance; o NPC
## ganha o empate exato. É só dica visual, como a detecção de pontos da `InteractionView`: quem decide é a simulação, que confere a distância pela posição
## guardada no personagem. Sem regra de jogo e sem Node: a escolha é uma função pura, testável sem cena.

enum Kind { NONE, POINT, NPC }

## Alcance para conversar com um NPC [HIP]: o mesmo de `NpcPlayerTalk.TALK_REACH_M` (a apresentação não pode citar `sim/`; o teste confere que continuam iguais).
const NPC_REACH_M: float = 3.0

var kind: Kind = Kind.NONE
## O NPC mais perto dentro do alcance (vale se `kind` é NPC).
var npc_id: int = 0
## O ponto de interesse mais perto dentro do alcance, ou "" (vale mesmo quando um NPC está mais perto).
var point_id: String = ""


## `player_xz`: x e z do jogador. `npcs`: npc_id -> posição do corpo (a ordem de inserção desempata dois NPCs à mesma distância: vence o primeiro).
static func choose(player_xz: Vector2, points: Array[BridgeReplies.PointReply], npcs: Dictionary[int, Vector3]) -> InteractionTarget:
	var target: InteractionTarget = InteractionTarget.new()
	var point_m: float = INF
	for point: BridgeReplies.PointReply in points:
		var distance_m: float = player_xz.distance_to(Vector2(point.x, point.z))
		if distance_m <= point.reach_m and distance_m < point_m:
			target.point_id = point.id
			point_m = distance_m
	var npc_m: float = INF
	for candidate_id: int in npcs:
		var distance_m: float = player_xz.distance_to(Vector2(npcs[candidate_id].x, npcs[candidate_id].z))
		if distance_m <= NPC_REACH_M and distance_m < npc_m:
			target.npc_id = candidate_id
			npc_m = distance_m
	if npc_m < INF and npc_m <= point_m:
		target.kind = Kind.NPC
	elif point_m < INF:
		target.kind = Kind.POINT
	return target
