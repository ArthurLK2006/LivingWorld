class_name NeedDef
extends RefCounted
## Definição de uma necessidade (LW-058; conteúdo de data/needs.json, somente leitura depois de montado; contrato em
## docs/modules/npc.md, seção 2). Todas guardam PRESSÃO de 0 a 100: 0 = satisfeita, 100 = no limite. Taxa positiva faz a pressão
## subir com o tempo (fome, cansaço, solidão); negativa a faz cair (segurança). O NpcState guarda o valor por POSIÇÃO (`order`).
## Os números dos dados são [HIP] de trabalho: ficam só em data/needs.json. Nada aqui é salvo.

var id: String
## Posição da necessidade no estado do NPC, de 0 a NpcState.NEED_COUNT - 1.
var order: int
## Valor de um NPC recém-criado.
var start_value: int
## Pontos por hora de simulação; inteiro, pode ser negativo.
var rate_per_hour: int
## Limiares de urgência, estritamente crescentes: a partir de `attention` o nível é 1, de `urgent` é 2 e de `critical` é 3.
var attention: int
var urgent: int
var critical: int
## Consequências de ficar em nível CRÍTICO (LW-081, docs/modules/npc.md, seção 8). `lethal_after_hours` maior que 0 faz da necessidade uma
## necessidade LETAL (só `hunger` na Fase 2): crítica há `weaken_after_hours` o NPC fica enfraquecido (o `work` rende `weak_effect_percent`
## por cento) e crítica há `lethal_after_hours` ele morre. 0 nos dois = a necessidade não tem consequência.
var weaken_after_hours: int
var lethal_after_hours: int
var weak_effect_percent: int


func _init(need_id: String, need_order: int, need_start_value: int, need_rate_per_hour: int, need_attention: int, need_urgent: int, need_critical: int, need_weaken_after_hours: int = 0, need_lethal_after_hours: int = 0, need_weak_effect_percent: int = 100) -> void:
	id = need_id
	order = need_order
	start_value = need_start_value
	rate_per_hour = need_rate_per_hour
	attention = need_attention
	urgent = need_urgent
	critical = need_critical
	weaken_after_hours = need_weaken_after_hours
	lethal_after_hours = need_lethal_after_hours
	weak_effect_percent = need_weak_effect_percent
