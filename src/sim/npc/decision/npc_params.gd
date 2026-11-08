class_name NpcParams
extends RefCounted
## Parâmetros do `npc` (LW-062; conteúdo de data/npc_params.json, UMA linha, todos [HIP]: números de trabalho, não requisitos; somente
## leitura depois de montado; nada é salvo). Esta tarefa traz os da pontuação de utilidade (docs/modules/npc.md, seção 5); cada tarefa
## seguinte acrescenta os seus (fila de pensamento, alarme, limite de T2...). Valor 0 em todos = pontuação neutra, o padrão dos testes.

## Peso de cada NÍVEL de urgência (0 confortável, 1 atenção, 2 urgente, 3 crítica) no benefício de aliviar uma necessidade.
var urgency_weight_comfortable: int = 0
var urgency_weight_attention: int = 0
var urgency_weight_urgent: int = 0
var urgency_weight_critical: int = 0
## Pontos descontados por hora de duração da ação.
var time_cost_per_hour: int = 0
## Pontos descontados a cada 100 m de caminhada até o local.
var distance_cost_per_100m: int = 0
## Percentual do `risk` da ação (0 a 100) que vira desconto: 100 = um ponto por ponto de risco.
var risk_cost_percent: int = 0
## Bônus de quem já está fazendo a ação (inércia: evita trocar de ideia a cada pensamento).
var inertia_bonus: int = 0
## Bônus da ação que a rotina do ofício manda fazer na hora.
var routine_bonus: int = 0


## Peso do nível de urgência (0 a 3); nível fora disso usa o do crítico.
func urgency_weight(level: int) -> int:
	match level:
		NeedMath.URGENCY_COMFORTABLE:
			return urgency_weight_comfortable
		NeedMath.URGENCY_ATTENTION:
			return urgency_weight_attention
		NeedMath.URGENCY_URGENT:
			return urgency_weight_urgent
	return urgency_weight_critical
