class_name BridgeInspectReplies
extends RefCounted
## Tipos de resposta da INSPEÇÃO de NPC da ponte (LW-082c; contrato em docs/modules/bridge.md, "Inspeção de NPC", e em docs/modules/tools.md). Como em
## `BridgeReplies`, cada resposta traz um `Result` e CÓPIAS dos valores, para quem consome (o painel de depuração, em `src/tools/`) nunca precisar citar
## tipo de `sim/`. Não tem estado nem método: é só o lugar dos tipos. Vivem à parte do `BridgeReplies` porque ele já tem perto de 270 linhas.

## Nível de simulação do NPC (arquitetura 5): S0 = com corpo, S1 = só dados. Vem de `peek_level_of` do `npc`.
enum NpcLevel { S0, S1 }

## Camadas do NPC, copiadas de `NpcState.TIER_NORMAL` e `NpcState.TIER_NOTABLE` (quem consome não pode citar `NpcState`);
## tests/unit/test_sim_bridge_npc_inspect.gd confere que continuam iguais.
const TIER_NORMAL: int = 1
const TIER_NOTABLE: int = 2


## Uma linha da lista de NPCs (`peek_npc_roster`).
class NpcRosterEntry:
	extends RefCounted

	var npc_id: int = 0
	var name_key: String = ""
	var name_number: int = 0
	var tier: int = 0
	var is_alive: bool = false
	var level: BridgeInspectReplies.NpcLevel = BridgeInspectReplies.NpcLevel.S1
	var occupation_id: String = ""
	## Vazio se o NPC está parado.
	var action_id: String = ""


## Resposta de `peek_npc_roster`: `entries` só vale se `result.ok`; em ordem crescente de NPC, inclusive os mortos e os sem corpo.
class NpcRosterReply:
	extends RefCounted

	var result: Result
	var entries: Array[NpcRosterEntry] = []

	func _init(reply_result: Result, listed: Array[NpcRosterEntry] = []) -> void:
		result = reply_result
		entries = listed


## Resposta de `peek_npc_detail`: os campos só valem se `result.ok`. As posições estão em metros (x e z do `npc`, em centímetros, divididos por 100).
class NpcDetailReply:
	extends RefCounted

	var result: Result
	var npc_id: int = 0
	var name_key: String = ""
	var name_number: int = 0
	var tier: int = 0
	var is_alive: bool = false
	var death_cause: String = ""
	var level: BridgeInspectReplies.NpcLevel = BridgeInspectReplies.NpcLevel.S1
	## Os quatro traços de personalidade, na ordem dos dados.
	var traits: PackedInt64Array = PackedInt64Array()
	## Os ids das necessidades, na ordem dos dados; `need_values` e `need_urgencies` (0 a 3) vêm na mesma ordem.
	var need_ids: Array[String] = []
	var need_values: PackedInt64Array = PackedInt64Array()
	var need_urgencies: PackedInt64Array = PackedInt64Array()
	var needs_updated_at: int = 0
	var position_m: Vector2 = Vector2.ZERO
	var settlement_id: String = ""
	var place_id: String = ""
	var occupation_id: String = ""
	var home_place_id: String = ""
	var work_place_id: String = ""
	var action_id: String = ""
	var action_target_place_id: String = ""
	var action_started_at: int = 0
	var action_ends_at: int = 0
	var action_serial: int = 0
	var next_think_time: int = 0
	## A ação que a rotina do ofício manda para a hora de agora; vazio sem ofício ou sem agenda.
	var routine_action_id: String = ""

	func _init(reply_result: Result) -> void:
		result = reply_result


## Resposta de `peek_simulation_summary`: os campos só valem se `result.ok`. `npc_s1` são os vivos que não estão em S0.
class SimSummaryReply:
	extends RefCounted

	var result: Result
	var time: BridgeReplies.TimeSnapshot
	var npc_total: int = 0
	var npc_alive: int = 0
	var npc_dead: int = 0
	var npc_tier_normal: int = 0
	var npc_tier_notable: int = 0
	var npc_s0: int = 0
	var npc_s1: int = 0
	var pending_intents: int = 0
	## O `validate()` do mundo inteiro: vazio quando está tudo certo.
	var problems: Array[String] = []

	func _init(reply_result: Result) -> void:
		result = reply_result


## Uma candidata de um pensamento do rastro: as parcelas da pontuação (`total` é a soma delas) e de onde ela veio (`source`).
class NpcTraceCandidate:
	extends RefCounted

	var action_id: String = ""
	var place_id: String = ""
	var benefit: int = 0
	var personality: int = 0
	var time_cost: int = 0
	var distance_cost: int = 0
	var risk_cost: int = 0
	var inertia_bonus: int = 0
	var routine_bonus: int = 0
	var total: int = 0
	## Era a ação em andamento do NPC?
	var is_current: bool = false
	var source: String = ""


## Um pensamento do NPC marcado: as necessidades naquele minuto, todas as candidatas, a ação escolhida (vazia se não fez nada) e o motivo.
class NpcTraceRecord:
	extends RefCounted

	var minute: int = 0
	var need_values: PackedInt64Array = PackedInt64Array()
	var candidates: Array[NpcTraceCandidate] = []
	var chosen_action_id: String = ""
	var chosen_place_id: String = ""
	var reason: String = ""


## Resposta de `peek_npc_trace`: `records` só vale se `result.ok`, do mais antigo ao mais novo. NPC não marcado: `result` falha com `NPC_NOT_TRACED`.
class NpcTraceReply:
	extends RefCounted

	var result: Result
	var records: Array[NpcTraceRecord] = []

	func _init(reply_result: Result, listed: Array[NpcTraceRecord] = []) -> void:
		result = reply_result
		records = listed


## Um registro de memória do NPC notável (T2).
class NpcMemoryEntry:
	extends RefCounted

	var kind: String = ""
	var actors: PackedInt64Array = PackedInt64Array()
	var place_id: String = ""
	var time: int = 0
	var valence: int = 0
	var salience: int = 0
	var source: String = ""
	var confidence: int = 0


## Um traço permanente de memória: o que o NPC sente por uma pessoa e desde quando (minuto).
class NpcTraitEntry:
	extends RefCounted

	var actor_id: int = 0
	var valence: int = 0
	var since: int = 0


## Resposta de `peek_npc_memories`: os campos só valem se `result.ok`; os registros, na ordem em que entraram.
class NpcMemoriesReply:
	extends RefCounted

	var result: Result
	var records: Array[NpcMemoryEntry] = []
	var traits: Array[NpcTraitEntry] = []

	func _init(reply_result: Result) -> void:
		result = reply_result


## Uma relação do NPC com `other_id`: as cinco dimensões de hoje (afeição, confiança, respeito, medo, dívida), o rótulo, quando se conheceram e se a outra
## pessoa está viva.
class NpcRelationEntry:
	extends RefCounted

	var other_id: int = 0
	var values: PackedInt64Array = PackedInt64Array()
	var label: String = ""
	var met_at: int = 0
	var other_is_alive: bool = true


## Resposta de `peek_npc_relations`: `entries` só vale se `result.ok`; em ordem crescente do id da outra pessoa.
class NpcRelationsReply:
	extends RefCounted

	var result: Result
	var entries: Array[NpcRelationEntry] = []

	func _init(reply_result: Result) -> void:
		result = reply_result
