class_name NpcModule
extends SimModule
## Módulo `npc` (camada 3; contrato em docs/modules/npc.md). LW-057: tabela de NPCs indexada por npc_id (um NpcState por NPC), criar e
## remover com IDs de ctx.ids que nunca voltam, salvar e carregar, validate e debug_summary. O módulo entra no World e, pelo
## serialize(), no state_hash. LW-058: as definições das necessidades (NeedDef, lidas de data/needs.json por quem monta o módulo)
## entram pelo CONSTRUTOR, sem global nem autoload; sem elas (padrão) os NPCs nascem com tudo em zero e sem urgência. Ainda NÃO
## decide, anda, tem rotina nem LOD: isso é das tarefas seguintes. Dependências: só core e a própria pasta; não importa o `character`.

const CODE_NOT_READY: String = "NPC_NOT_READY"
const CODE_UNKNOWN: String = "NPC_UNKNOWN"
const CODE_INVALID_SPEC: String = "NPC_INVALID_SPEC"
const CODE_INVALID_SAVE: String = "NPC_INVALID_SAVE"
const CODE_NO_ID: String = "NPC_NO_ID"
const CODE_DUPLICATE_ID: String = "NPC_DUPLICATE_ID"
const KEY_NPCS: String = "npcs"
## Chaves de peek_counts().
const COUNT_TOTAL: String = "total"
const COUNT_ALIVE: String = "alive"
const COUNT_DEAD: String = "dead"
const COUNT_TIER_NORMAL: String = "tier_1"
const COUNT_TIER_NOTABLE: String = "tier_2"
## Rótulo, no resumo de depuração, de quem não tem ofício.
const NO_OCCUPATION_LABEL: String = "none"

var _ctx: SimContext
var _need_defs: Array[NeedDef] = []
## Motivo de as definições não servirem (vazio = servem, ou não foram dadas). Conferido uma vez, no construtor.
var _defs_problem: String = ""
var _npcs: Dictionary[int, NpcState] = {}


## `need_defs`: uma definição por posição, na ordem de `order` (como NeedLoader as entrega). Vazio = sem necessidades configuradas.
func _init(need_defs: Array[NeedDef] = []) -> void:
	_need_defs = need_defs
	_defs_problem = "" if need_defs.is_empty() else NeedMath.definitions_problem(need_defs)


func setup(ctx: SimContext) -> void:
	_ctx = ctx


## Cria um NPC (ID novo de ctx.ids). Confere o pedido inteiro ANTES de gastar um ID: pedido recusado não altera nada.
func request_create_npc(spec: NpcSpec) -> CreateResult:
	if _ctx == null:
		return CreateResult.new(Result.failure(CODE_NOT_READY, "NpcModule.request_create_npc: módulo sem setup() (sem relógio nem IDs); esperado um módulo registrado no World."), IdGenerator.NO_ID)
	if not _defs_problem.is_empty():
		return CreateResult.new(Result.failure(CODE_NOT_READY, "NpcModule.request_create_npc: definições de necessidades inválidas: %s." % _defs_problem), IdGenerator.NO_ID)
	var problem: String = _spec_problem(spec)
	if not problem.is_empty():
		return CreateResult.new(Result.failure(CODE_INVALID_SPEC, "NpcModule.request_create_npc: pedido inválido: %s." % problem), IdGenerator.NO_ID)
	var npc_id: int = _ctx.ids.next_id()
	if npc_id == IdGenerator.NO_ID:
		return CreateResult.new(Result.failure(CODE_NO_ID, "NpcModule.request_create_npc: o contador de IDs esgotou; não há ID novo."), IdGenerator.NO_ID)
	if _npcs.has(npc_id):
		return CreateResult.new(Result.failure(CODE_DUPLICATE_ID, "NpcModule.request_create_npc: o ID novo %d já pertence a um NPC (save inconsistente); nada foi sobrescrito." % npc_id), IdGenerator.NO_ID)
	_npcs[npc_id] = NpcState.from_spec(npc_id, spec, _ctx.clock.total_minutes(), _start_needs())
	return CreateResult.new(Result.success(), npc_id)


## Remove o NPC da tabela. O ID não volta: o contador do core só sobe.
func request_remove_npc(npc_id: int) -> Result:
	if not _npcs.has(npc_id):
		return _unknown("request_remove_npc", npc_id)
	_npcs.erase(npc_id)
	return Result.success()


## Resumo do NPC, em CÓPIA. ID inexistente devolve falha tratada, nunca derruba o jogo.
func peek_npc(npc_id: int) -> NpcQuery:
	if not _npcs.has(npc_id):
		return NpcQuery.new(_unknown("peek_npc", npc_id), null)
	var state: NpcState = _npcs[npc_id]
	var query: NpcQuery = NpcQuery.new(Result.success(), state)
	query.need_urgencies = _urgencies_of(state)
	return query


## IDs dos NPCs em ordem crescente.
func peek_npc_ids() -> Array[int]:
	return _sorted_ids()


## Contagens (chaves COUNT_*): total, vivos, mortos e por tier.
func peek_counts() -> Dictionary:
	var counts: Dictionary = {COUNT_TOTAL: _npcs.size(), COUNT_ALIVE: 0, COUNT_DEAD: 0, COUNT_TIER_NORMAL: 0, COUNT_TIER_NOTABLE: 0}
	for npc_id: int in _sorted_ids():
		var state: NpcState = _npcs[npc_id]
		counts[COUNT_ALIVE if state.is_alive else COUNT_DEAD] += 1
		if state.tier == NpcState.TIER_NORMAL:
			counts[COUNT_TIER_NORMAL] += 1
		elif state.tier == NpcState.TIER_NOTABLE:
			counts[COUNT_TIER_NOTABLE] += 1
	return counts


## LOD lógico (LW-069; docs/modules/npc.md, seção 6). Quem monta o módulo o liga com `lod.configure(LodParams)`; sem isso ele fica
## desligado (o pedido de foco falha com NPC_LOD_NOT_CONFIGURED e nada muda). O nível dos NPCs não é salvo nem entra no hash.
var lod: NpcLod = NpcLod.new()


## Põe ou move o foco do LOD (ID do ator e posição em metros). Quem entrega a posição é a ponte: o `npc` não importa o `character`.
func request_set_focus(focus_id: int, position_m: Vector3) -> Result:
	return lod.set_focus(focus_id, position_m)


## Tira o foco do LOD. Foco desconhecido: falha tratada.
func request_clear_focus(focus_id: int) -> Result:
	return lod.clear_focus(focus_id)


## A cada passo: reclassifica os NPCs (S1 e S0) e publica LodChanged só nas trocas. As outras tarefas do módulo acrescentam aqui o resto do passo.
func tick(_elapsed_minutes: int) -> void:
	if _ctx == null:
		return
	for change: NpcLod.Change in lod.update(_npcs, _ctx.clock.total_minutes()):
		_ctx.events.publish(LodChanged.new(change.npc_id, change.from_level, change.to_level))


## IDs viram texto (assim o JSON guarda chaves) e entram em ordem crescente do número.
func serialize() -> Dictionary:
	var saved: Dictionary = {}
	for npc_id: int in _sorted_ids():
		saved[str(npc_id)] = _npcs[npc_id].to_dict()
	return {KEY_NPCS: saved}


## Confere tudo antes de alterar o estado: se algo for inválido, o estado fica como estava. Só recusa o que não dá para converter
## (estrutura, tipos, chave de ID); faixas e coerência ficam com validate() (mesmo critério do `character`).
func on_load(data: Dictionary) -> Result:
	# Variant: valor cru do save (JSON); o tipo é conferido na linha seguinte.
	var raw_npcs: Variant = data.get(KEY_NPCS)
	if typeof(raw_npcs) != TYPE_DICTIONARY:
		return _invalid_save("campo '%s' ausente ou não é um objeto (veio %s)" % [KEY_NPCS, type_string(typeof(raw_npcs))])
	var entries: Dictionary = raw_npcs
	var keys: Array = entries.keys()
	keys.sort()
	var loaded: Dictionary[int, NpcState] = {}
	for key: Variant in keys:
		var npc_id: int = _read_npc_id(str(key))
		if npc_id == IdGenerator.NO_ID:
			return _invalid_save("chave de NPC '%s' inválida; esperado um inteiro de %d a %d" % [str(key), IdGenerator.FIRST_ID, IdGenerator.MAX_ID])
		if loaded.has(npc_id):
			return _invalid_save("o NPC %d aparece duas vezes (chave '%s')" % [npc_id, str(key)])
		var parsed: NpcState.ParseResult = NpcState.parse(npc_id, entries[key])
		if parsed.state == null:
			return _invalid_save("NPC %d: %s" % [npc_id, parsed.error])
		loaded[npc_id] = parsed.state
	_npcs = loaded
	return Result.success()


## Problemas do estado (lista vazia se estiver tudo certo). Referências a ofício, local e ação ficam como texto: cada tarefa futura
## acrescenta a sua conferência (LW-056, LW-059, LW-061).
func validate() -> Array[String]:
	var problems: Array[String] = []
	if not _defs_problem.is_empty():
		problems.append("Definições de necessidades inválidas: %s." % _defs_problem)
	var next_id: int = _next_issued_id()
	for npc_id: int in _sorted_ids():
		var state: NpcState = _npcs[npc_id]
		if npc_id < IdGenerator.FIRST_ID or npc_id > IdGenerator.MAX_ID:
			problems.append("NPC %d: ID fora da faixa [%d, %d]." % [npc_id, IdGenerator.FIRST_ID, IdGenerator.MAX_ID])
		elif _ctx != null and npc_id >= next_id:
			problems.append("NPC %d: ID acima do contador do core (o próximo ID a sair é %d); esse ID nunca foi emitido." % [npc_id, next_id])
		if state.tier != NpcState.TIER_NORMAL and state.tier != NpcState.TIER_NOTABLE:
			problems.append("NPC %d: tier %d inválido; esperado %d ou %d." % [npc_id, state.tier, NpcState.TIER_NORMAL, NpcState.TIER_NOTABLE])
		_append_range_problems(problems, npc_id, "necessidade", state.need_values, NpcState.VALUE_MIN, NpcState.VALUE_MAX)
		_append_range_problems(problems, npc_id, "resto de necessidade", state.need_remainders, 0, NeedMath.MAX_REMAINDER)
		_append_range_problems(problems, npc_id, "traço", state.traits, NpcState.VALUE_MIN, NpcState.VALUE_MAX)
		if not state.is_alive and not state.action_id.is_empty():
			problems.append("NPC %d: morto, mas com ação atual '%s'; esperado nenhuma." % [npc_id, state.action_id])
	return problems


## Contagens por tier, vivos e mortos, ofícios e o tamanho em bytes do serialize() (backlog I4). Só para depuração.
func debug_summary() -> Dictionary:
	var summary: Dictionary = peek_counts()
	var by_occupation: Dictionary = {}
	for npc_id: int in _sorted_ids():
		var occupation: String = _npcs[npc_id].occupation_id
		var label: String = occupation if not occupation.is_empty() else NO_OCCUPATION_LABEL
		by_occupation[label] = int(by_occupation.get(label, 0)) + 1
	var sorted_labels: Array = by_occupation.keys()
	sorted_labels.sort()
	var ordered: Dictionary = {}
	for label: Variant in sorted_labels:
		ordered[label] = by_occupation[label]
	summary["by_occupation"] = ordered
	summary["serialize_bytes"] = JSON.stringify(serialize()).to_utf8_buffer().size()
	return summary


## Nunca visitar o Dictionary pela ordem natural (muda depois de carregar um save).
func _sorted_ids() -> Array[int]:
	var ids: Array[int] = []
	ids.assign(_npcs.keys())
	ids.sort()
	return ids


## Valor inicial das necessidades: o `start_value` de cada definição; sem definições, tudo zero.
func _start_needs() -> PackedInt64Array:
	var needs: PackedInt64Array = PackedInt64Array()
	needs.resize(NpcState.NEED_COUNT)
	if not _need_defs.is_empty():
		for def: NeedDef in _need_defs:
			needs[def.order] = def.start_value
	return needs


## Nível de urgência de cada necessidade do NPC, pelos limiares dos dados. Sem definições, tudo 0 (não há limiares para comparar).
func _urgencies_of(state: NpcState) -> PackedInt64Array:
	var urgencies: PackedInt64Array = PackedInt64Array()
	urgencies.resize(NpcState.NEED_COUNT)
	if _need_defs.is_empty() or not _defs_problem.is_empty():
		return urgencies
	for def: NeedDef in _need_defs:
		urgencies[def.order] = NeedMath.urgency(state.need_values[def.order], def)
	return urgencies


## Primeiro problema do pedido de criação (texto vazio se estiver certo).
func _spec_problem(spec: NpcSpec) -> String:
	if spec == null:
		return "pedido nulo; esperado um NpcSpec"
	if spec.name_key.strip_edges().is_empty():
		return "name_key vazia; esperado a chave de texto do nome"
	if spec.name_number < 0:
		return "name_number %d negativo; esperado 0 ou mais" % spec.name_number
	if spec.tier != NpcState.TIER_NORMAL and spec.tier != NpcState.TIER_NOTABLE:
		return "tier %d inválido; esperado %d ou %d" % [spec.tier, NpcState.TIER_NORMAL, NpcState.TIER_NOTABLE]
	if spec.traits.size() != NpcState.TRAIT_COUNT:
		return "traits com %d valores; esperado %d (um por traço)" % [spec.traits.size(), NpcState.TRAIT_COUNT]
	for index: int in spec.traits.size():
		if spec.traits[index] < NpcState.VALUE_MIN or spec.traits[index] > NpcState.VALUE_MAX:
			return "traço na posição %d com valor %d; esperado de %d a %d" % [index, spec.traits[index], NpcState.VALUE_MIN, NpcState.VALUE_MAX]
	if spec.x_cm < 0 or spec.x_cm > NpcState.MAX_COORDINATE_CM or spec.z_cm < 0 or spec.z_cm > NpcState.MAX_COORDINATE_CM:
		return "posição (x_cm %d, z_cm %d) fora da faixa; esperado de 0 a %d" % [spec.x_cm, spec.z_cm, NpcState.MAX_COORDINATE_CM]
	return ""


func _append_range_problems(problems: Array[String], npc_id: int, what: String, values: PackedInt64Array, lowest: int, highest: int) -> void:
	for index: int in values.size():
		if values[index] < lowest or values[index] > highest:
			problems.append("NPC %d: %s na posição %d fora de %d a %d (valor %d)." % [npc_id, what, index, lowest, highest, values[index]])


## Próximo ID que o contador do core entregaria (0 se o módulo ainda não passou por setup()).
func _next_issued_id() -> int:
	if _ctx == null:
		return IdGenerator.NO_ID
	# Variant: o contador sai do serialize() do core, que é dado simples.
	var raw_next: Variant = _ctx.ids.serialize()[IdGenerator.KEY_NEXT_ID]
	var next_id: int = raw_next
	return next_id


func _unknown(caller: String, npc_id: int) -> Result:
	return Result.failure(CODE_UNKNOWN, "NpcModule.%s: o NPC %d não existe; esperado um ID devolvido por request_create_npc (há %d NPC(s))." % [caller, npc_id, _npcs.size()])


func _invalid_save(detail: String) -> Result:
	return Result.failure(CODE_INVALID_SAVE, "NpcModule.on_load: %s." % detail)


## ID de NPC a partir do texto da chave; NO_ID se não for um inteiro na faixa válida.
func _read_npc_id(key_text: String) -> int:
	if not key_text.is_valid_int():
		return IdGenerator.NO_ID
	var value: int = key_text.to_int()
	return value if value >= IdGenerator.FIRST_ID and value <= IdGenerator.MAX_ID else IdGenerator.NO_ID


## Resultado de `request_create_npc`: `npc_id` só vale se `result.ok` (mesmo padrão do SpawnResult do `character`).
class CreateResult:
	extends RefCounted

	var result: Result
	var npc_id: int

	func _init(create_result: Result, new_npc_id: int) -> void:
		result = create_result
		npc_id = new_npc_id


## Resumo devolvido por `peek_npc`: `result.ok` diz se deu certo; só então os campos valem. São CÓPIAS dos valores do estado.
class NpcQuery:
	extends RefCounted

	var result: Result
	var npc_id: int = 0
	var name_key: String = ""
	var name_number: int = 0
	var tier: int = 0
	var is_alive: bool = false
	var death_cause: String = ""
	var traits: PackedInt64Array = PackedInt64Array()
	var need_values: PackedInt64Array = PackedInt64Array()
	## Urgência (0 a 3) de cada necessidade pelos limiares dos dados; tudo 0 se o módulo não tem definições.
	var need_urgencies: PackedInt64Array = PackedInt64Array()
	var needs_updated_at: int = 0
	var x_cm: int = 0
	var z_cm: int = 0
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

	func _init(query_result: Result, state: NpcState) -> void:
		result = query_result
		if state == null:
			return
		npc_id = state.npc_id
		name_key = state.name_key
		name_number = state.name_number
		tier = state.tier
		is_alive = state.is_alive
		death_cause = state.death_cause
		traits = state.traits.duplicate()
		need_values = state.need_values.duplicate()
		needs_updated_at = state.needs_updated_at
		x_cm = state.x_cm
		z_cm = state.z_cm
		settlement_id = state.settlement_id
		place_id = state.place_id
		occupation_id = state.occupation_id
		home_place_id = state.home_place_id
		work_place_id = state.work_place_id
		action_id = state.action_id
		action_target_place_id = state.action_target_place_id
		action_started_at = state.action_started_at
		action_ends_at = state.action_ends_at
		action_serial = state.action_serial
