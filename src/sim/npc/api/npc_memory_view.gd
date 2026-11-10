class_name NpcMemoryView
extends RefCounted
## Visão das memórias para quem está FORA do módulo `npc` (LW-085a; contrato em docs/modules/npc.md, "A porta `api/` e a fronteira com a ponte"): cópias de dados puros do que
## `NpcModule.peek_memories` devolve, para a ponte nunca citar `MemoryRecord` nem `NpcMemory.Trait`. `result.ok` diz se deu certo; só então as listas valem, na ordem em que
## entraram. Só lê: não guarda estado, não é salvo e não entra no hash. Os campos têm os mesmos nomes e valores dos registros do módulo.

var result: Result
var records: Array[Entry] = []
var traits: Array[TraitEntry] = []


func _init(query_result: Result) -> void:
	result = query_result


## Copia o retorno de `peek_memories`. Falha (NPC inexistente, tipo inexistente): o mesmo `result`, sem registros nem traços.
static func of(query: NpcModule.MemoriesQuery) -> NpcMemoryView:
	var view: NpcMemoryView = NpcMemoryView.new(query.result)
	if not query.result.ok:
		return view
	for source: MemoryRecord in query.records:
		var entry: Entry = Entry.new()
		entry.kind = source.kind
		entry.actors = source.actors.duplicate()
		entry.place_id = source.place_id
		entry.time = source.time
		entry.valence = source.valence
		entry.salience = source.salience
		entry.source = source.source
		entry.confidence = source.confidence
		view.records.append(entry)
	for source: NpcMemory.Trait in query.traits:
		var memory_trait: TraitEntry = TraitEntry.new()
		memory_trait.actor_id = source.actor_id
		memory_trait.valence = source.valence
		memory_trait.since = source.since
		view.traits.append(memory_trait)
	return view


## Um episódio guardado: tipo, pessoas envolvidas, local, minuto, valência, saliência, fonte e confiança.
class Entry:
	extends RefCounted

	var kind: String = ""
	var actors: PackedInt64Array = PackedInt64Array()
	var place_id: String = ""
	var time: int = 0
	var valence: int = 0
	var salience: int = 0
	var source: String = ""
	var confidence: int = 0


## Um traço permanente: o que o NPC guardou de uma pessoa ao ser rebaixado.
class TraitEntry:
	extends RefCounted

	var actor_id: int = 0
	var valence: int = 0
	var since: int = 0
