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


func _init(need_id: String, need_order: int, need_start_value: int, need_rate_per_hour: int, need_attention: int, need_urgent: int, need_critical: int) -> void:
	id = need_id
	order = need_order
	start_value = need_start_value
	rate_per_hour = need_rate_per_hour
	attention = need_attention
	urgent = need_urgent
	critical = need_critical
