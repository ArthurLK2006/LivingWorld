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
# Fluxo de decisão e fila de pensamento (LW-063).
## Minutos entre dois pensamentos de um NPC; a fase de cada um é 1 + `npc_id` mod este valor, para não pensarem todos no mesmo passo.
var think_interval_min: int = 1
## Teto de NPCs que pensam num mesmo passo; o excedente espera o passo seguinte (o mais antigo primeiro).
var max_thinks_per_step: int = 1
## Quantas das melhores candidatas entram no sorteio, e a que distância (em pontos) da melhor elas ainda entram.
var decision_top_k: int = 1
var decision_margin: int = 0
# Alarme (LW-076).
## Raio, em metros, em que o NPC reage a um alarme; 0 = o alarme não alcança ninguém.
var alarm_radius_m: int = 0
## Pontos de pressão de `safety` que o alarme põe em quem está no raio (multiplicados pela gravidade do alarme).
var alarm_safety_pressure: int = 0
## Por quantos minutos depois do alarme o NPC no raio continua pesando as reações (fugir demora: andar até casa e ficar lá); 0 = só no pensamento do alarme.
var alarm_window_min: int = 0
# Camadas (LW-077).
## Teto de NPCs VIVOS notáveis (T2) ao mesmo tempo; 0 = sem teto configurado (o padrão dos testes). Com o teto cheio promover é recusado, e ninguém é expulso.
var max_t2: int = 0
# Memória (LW-078).
## Quantos registros de memória cabem por NPC notável; 0 = memória não configurada (o padrão dos testes): nenhum registro é aceito.
var memory_capacity: int = 0
## Saliência ACIMA da qual um registro vira traço permanente antes de sair da memória; 100 = nenhum registro vira traço (a saliência máxima é 100).
var trait_threshold: int = 100
## Quantos traços permanentes cabem por NPC; 0 = nenhum.
var trait_slots: int = 0
# Relações (LW-079).
## Quantas relações cabem por NPC; 0 = relações não configuradas (o padrão dos testes): nenhuma relação é aceita.
var relations_capacity: int = 0
## Pontos que cada dimensão de uma relação perde por dia, rumo a 0.
var relation_decay_per_day: int = 0
## Afeição a partir da qual a relação é de amizade; 0 = o rótulo "amigo" nunca aparece.
var relation_friend_threshold: int = 0
## Afeição negativa (em módulo) a partir da qual a relação é de rivalidade; 0 = o rótulo "rival" nunca aparece.
var relation_rival_threshold: int = 0


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
