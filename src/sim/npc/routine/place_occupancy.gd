class_name PlaceOccupancy
extends RefCounted
## Ocupação dos locais (LW-061; contrato em docs/modules/npc.md, seções 4 e 11): quantos NPCs VIVOS estão em cada local agora. É
## DERIVADA do estado dos NPCs (o `place_id` de cada um) a cada pergunta: não tem estado próprio, não é salva e não entra no
## state_hash, então nunca fica desatualizada nem precisa ser refeita ao carregar um save. A capacidade (estática) é dado do `world`.
## [LIM] Conta quem JÁ ESTÁ no local: dois NPCs a caminho do último lugar podem os dois chegar; o que chegar depois é recusado pela
## condição `place_has_room` ao começar a ação e decide de novo.
## [HIP] Uma varredura da tabela inteira por pergunta (centenas de NPCs): sem índice incremental até uma medição pedir (AGENTS 4.18).

var _states: Dictionary[int, NpcState]


## `states`: a tabela de NPCs do módulo dono (a mesma, por referência; esta classe só a lê).
func _init(states: Dictionary[int, NpcState]) -> void:
	_states = states


## Local -> quantos NPCs vivos estão nele agora. NPC sem local (em trânsito, `place_id` vazio) não conta em nenhum.
func counts() -> Dictionary[String, int]:
	var found: Dictionary[String, int] = {}
	for state: NpcState in _states.values():
		if not state.is_alive or state.place_id.is_empty():
			continue
		found[state.place_id] = int(found.get(state.place_id, 0)) + 1
	return found


## Quantos NPCs vivos estão no local agora.
func count_at(place_id: String) -> int:
	return int(counts().get(place_id, 0))
