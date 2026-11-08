class_name NpcActionResult
extends RefCounted
## Resultado que a apresentação devolve de uma intenção (LW-070; contrato em docs/modules/npc.md, seção 6). `ARRIVED` vale para
## `MOVE_TO_PLACE` e `DONE` para `ACT_AT_PLACE` (os dois são o sucesso); `BLOCKED` (o corpo não conseguiu) e `CANCELLED` (a
## apresentação desistiu) valem para os dois e NÃO aplicam efeito. `action_serial` é o da intenção: resultado de ação velha é descartado.
## A posição final vem do corpo, em METROS (como todo relato do corpo); a simulação a confere e a converte.

enum Outcome { ARRIVED, DONE, BLOCKED, CANCELLED }

var npc_id: int
var action_serial: int
var outcome: Outcome
var final_position_m: Vector3


func _init(result_npc_id: int, result_action_serial: int, result_outcome: Outcome, result_final_position_m: Vector3) -> void:
	npc_id = result_npc_id
	action_serial = result_action_serial
	outcome = result_outcome
	final_position_m = result_final_position_m


## Os dois desfechos de sucesso, os únicos que fazem os efeitos da ação entrarem.
func is_success() -> bool:
	return outcome == Outcome.ARRIVED or outcome == Outcome.DONE
