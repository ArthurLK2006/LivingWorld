class_name AlarmRaised
extends SimEvent
## Fato: soou um alarme num ponto do mundo (LW-076). Hoje só o comando de depuração do `npc` o publica (`NpcModule.request_raise_alarm`, só em
## build de desenvolvimento): não há módulo dono de perigo na Fase 2 (Q14, proposta). Carga pequena: o ponto em centímetros e a gravidade, que
## vai no campo `severity` que todo evento já tem (1 ou mais; multiplica a pressão de `safety` que o alarme põe em quem está no raio).
## `cause_id` é preenchido pelo EventBus. Catalogado em docs/events.md.

var x_cm: int
var z_cm: int


func _init(alarm_x_cm: int, alarm_z_cm: int, alarm_severity: int) -> void:
	super("AlarmRaised")
	x_cm = alarm_x_cm
	z_cm = alarm_z_cm
	severity = alarm_severity
